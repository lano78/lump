--[[

lump v0.1

*** a basic two-way messaging module for local wi-fi 1v1 multiplayer written in Lua for the Corona SDK ***

Copyright (c) 2011 Christopher David YUDICHAK

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]]

module(..., package.seeall)

-- ====================
-- = Required Modules =
-- ====================
require("socket")
require("Json")

-- ====================
-- = Helper Functions =
-- ====================

-- url_encode/url_decode - sanitizing message during HTTP request
local function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end
local function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

-- createTCPServer/runTCPServer - create/run tcp server with Luasocket
local function createTCPServer( port )
  -- Create Socket
  local tcpServerSocket , err = socket.tcp()
  local backlog = 5
  
  -- Check Socket
  if tcpServerSocket == nil then 
    return nil , err
  end
  
  -- Allow Address Reuse
  tcpServerSocket:setoption( "reuseaddr" , true )
  
  -- Bind Socket
  local res, err = tcpServerSocket:bind( "*" , port )
  if res == nil then
    return nil , err
  end
  
  -- Check Connection
  res , err = tcpServerSocket:listen( backlog )
  if res == nil then 
    return nil , err
  end
  
  -- Return Server
  return tcpServerSocket
end
local function runTCPServer(server) 
  local tcpServer = server.server
  -- Set Timeout
  tcpServer:settimeout( 0 )
          
  -- Set Client
  local tcpClient , _ = tcpServer:accept()
  
  if tcpClient then _, port = tcpClient:getsockname() end

  -- Get Message
  if tcpClient ~= nil then

    local tcpClientMessage , _ = tcpClient:receive('*l')

    if ( tcpClientMessage ~= nil ) then
      -- Handshake Server
      if port == 8889 then
        local check_connect = tcpClientMessage:find("connect")
        
        -- If a connect request...
        if check_connect then
          -- Store remote IP
          server.remote_ip = tcpClient:getpeername()
          -- Return our IP
          tcpClient:send("OK-"..tcpClient:getsockname())
          -- Close the handshake server
          tcpServer:close()
          -- Callback to onConnect()
          server.onConnect()
          
          -- Create messaging server
          local tcpServer , _ = createTCPServer( "8890" )
          server.server = tcpServer
        else
          -- Return our IP
          local return_ip = tcpClient:getsockname()
          tcpClient:send( return_ip )
        end
      -- Messaging Server
      elseif port == 8890 then
        if tcpClientMessage:find('message') then
          local capture = {}
          capture[1], capture[2], capture[3] = tcpClientMessage:find("message=(.+)[%s]")
          if server:new_message(capture[3]) then
            -- Callback to onReceive() with incoming message
            server.onReceive(Json.Decode(url_decode(capture[3])))
          end
        end
      end                                                                             
    end

    -- Close Client Connection
    if tcpClient ~= nil then
      tcpClient:close()
    end
          
  else
    -- Error
  end
end

-- new_server_object - prepares server table for use in lump module
local function new_server_object(args)
  local server = {}
  
  server.onConnect = args.onConnect
  server.onReceive = args.onReceive
  server.onTimeout = args.onTimeout
  
  -- :new_message - checks to see if incoming message is a duplicate
  function server.new_message(self, message)
    if not self.last_message then self.last_message = { time = 0, message = '' } end
    if (self.last_message.time <= (os.time() - 2)) or self.last_message.message ~= message then
      self.last_message = { time = os.time(), message = message }
      return true
    end
    return false
  end
  
  -- :scan - scan for device awaiting connection
  function server.scan(self)
    -- timeout_connection - handle timeout during connection attempt
    local function timeout_connection()
      if not server.server then
        server.timer = nil
        server.onTimeout()
      end
    end
    -- complete_connection - complete handshake and start local server
    local function complete_connection(data)
      if data.response:find("OK") then
        self:cancel()
        
        local tcpServer , _ = createTCPServer( "8890" )
        self.server = tcpServer
        self:start()

        self.remote_ip = data.response:sub(4)
        self.onConnect()
      end
    end
    -- attempt_connection - attempt to connect to available device
    local function attempt_connection(event)
      if not event.isError then
        network.request("http://"..event.response..":8889?connect", "GET", complete_connection)
      end
    end

    for i = 1, 255 do
      network.request("http://192.168.1."..i..":8889", "GET", attempt_connection)
    end
    
    local timeout = args.timeout or 5000
    server.timer = timer.performWithDelay(timeout, timeout_connection)
  end
  
  -- :start - start the server
  function server.start(self)
    local server_runner = function() runTCPServer(server) end
    Runtime:addEventListener( "enterFrame" , server_runner )
  end
  
  -- :stop - stop the server
  function server.stop(self)
    if self.server then self.server:close() end
    Runtime:removeEventListener( "enterFrame" , server_runner )
  end
  
  -- :send - send message to remote device
  function server.send(self, message)
    network.request("http://"..self.remote_ip..":8890?message="..url_encode(Json.Encode(message)), "GET", nil)
  end
  
  -- :cancel - cancel connection timer
  function server.cancel(self)
    if server.timer then timer.cancel(server.timer) end
  end
  
  return server
end

-- host_game - open server and await connection
function host_game(args)
  local server = new_server_object(args)
  
  local tcpServer , _ = createTCPServer( "8889" )
  server.server = tcpServer
  
  server:start()
  
  return server
end

-- join_game - searching for waiting device and attempt to connect
function join_game(args)
  local server = new_server_object(args)
  
  server:scan()
  
  return server
end