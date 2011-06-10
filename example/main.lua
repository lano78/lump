require('lump')
require('setup')

local conn
local main_group = display.newGroup()

local function cancel_connection()
  conn:cancel(); conn:stop()
  main()
end
local function timeout_connection()
  cancel_box:removeSelf()
  cancel_connection()
end
local function complete_connection()
  cancel_box:removeSelf()
  prepare_send()
end
local function receive(data)
  local message = setup.message(data.message)
  
end
local function send_message()
  conn:send{message = "HELLO"}
end

local function host_join(event)
  if event.phase == 'ended' then
    if event.target.id == 'host' then
      conn = lump.host_game{onReceive = receive, onConnect = complete_connection}
    else
      conn = lump.join_game{onReceive = receive, onConnect = complete_connection, onTimeout = timeout_connection}
    end
    main_group:removeSelf(); main_group = display.newGroup()
    cancel_box = setup.dialog_box{title = "WAITING...", type = "single", buttons = {'CANCEL'}, handler = cancel_connection}
  end
end

function main()
  local host_button = setup.button('HOST GAME')
  host_button.y = 40; host_button.id = 'host'
  host_button:addEventListener('touch', host_join)
  main_group:insert(host_button); main_group.host = host_button

  local join_button = setup.button('JOIN GAME')
  join_button.y = 110; join_button.id = 'join'
  join_button:addEventListener('touch', host_join)
  main_group:insert(join_button); main_group.join = join_button
end

function prepare_send()
  local send_button = setup.button("SEND MESSAGE")
  send_button.y = 80
  send_button:addEventListener('touch', send_message)
  main_group:insert(send_button)
end

main()