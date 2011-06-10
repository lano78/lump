module(..., package.seeall)

function button(text)
  local button = display.newGroup()
  local button_bkg = display.newRect(0, 0, 250, 50)
  button_bkg.strokeWidth = 3; button_bkg:setFillColor(0, 0, 0); button_bkg.x = display.contentCenterX
  local button_text = display.newText(text, 0, 0, native.systemFont, 30)
  button_text.x = display.contentCenterX; button_text.y = 25
  button:insert(button_bkg); button:insert(button_text)
  return button
end

local function dialog_handler(self, event)
  if event.phase == "ended" then
    event.target.dialog:removeSelf()
    event.target.handler({ index = event.target.index })
  end
end
function dialog_box(args)
  args = args or {}
  local dialog = display.newGroup()
  
  local dialog_bkg = display.newRect(0, 0, 250, 300)
  dialog_bkg.strokeWidth = 3; dialog_bkg:setFillColor(0, 0, 0); dialog_bkg.x = display.contentCenterX; dialog_bkg.y = display.contentCenterY
  dialog:insert(dialog_bkg)
  
  if args.title then
    local dialog_title = display.newText(args.title, 0, 0, native.systemFont, 27)
    dialog_title.x = display.contentCenterX; dialog_title.y = display.contentCenterY - 30
    dialog:insert(dialog_title); dialog.title = dialog_title
  end
  local handler
  if args.handler then
    handler = args.handler
  else
    handler = function() return end
  end
  
  local button_1 = display.newGroup()
  local button_1_bkg = display.newRect(0, 0, 100, 50)
  button_1_bkg.strokeWidth = 3; button_1_bkg:setFillColor(0, 0, 0)
  button_1_bkg.x = display.contentCenterX; button_1_bkg.y = display.contentCenterY
  button_1_bkg:setReferencePoint(display.CenterReferencePoint)
  button_1:insert(button_1_bkg)
  local button_1_text = display.newText(args.buttons[1], 0, 0, native.systemFont, 20)
  button_1_text.x = display.contentCenterX; button_1_text.y = display.contentCenterY
  button_1:insert(button_1_text)
  button_1:setReferencePoint(display.CenterReferencePoint)
  if args.type == "single" then
    button_1.x = display.contentCenterX
  else
    button_1.x = display.contentCenterX - dialog_bkg.width / 4 + 5
  end
  button_1.y = display.contentCenterY + dialog_bkg.height / 4
  button_1.touch = dialog_handler; button_1.handler = handler; button_1.index = 1; button_1.dialog = dialog
  button_1:addEventListener("touch", button_1)
  dialog:insert(button_1); dialog.button_1 = button_1
  
  if args.type ~= "single" then
    local button_2 = display.newGroup()
    local button_2_bkg = display.newRect(0, 0, 100, 50)
    button_2_bkg.strokeWidth = 3; button_2_bkg:setFillColor(0, 0, 0)
    button_2_bkg.x = display.contentCenterX; button_2_bkg.y = display.contentCenterY
    button_2_bkg:setReferencePoint(display.CenterReferencePoint)
    button_2:insert(button_2_bkg)
    local button_2_text = display.newText(args.buttons[2], 0, 0, native.systemFont, 20)
    button_2_text.x = display.contentCenterX; button_2_text.y = display.contentCenterY
    button_2:insert(button_2_text)
    button_2:setReferencePoint(display.CenterReferencePoint)
    button_2.x = display.contentCenterX + dialog_bkg.width / 4 - 5; button_2.y = display.contentCenterY + dialog_bkg.height / 4
    button_2.touch = dialog_handler; button_2.handler = handler; button_2.index = 2; button_2.dialog = dialog
    button_2:addEventListener("touch", button_2)
    dialog:insert(button_2); dialog.button_2 = button_2
  end
  
  dialog:setReferencePoint(display.CenterReferencePoint)
  dialog.x = display.contentCenterX; dialog.y = display.contentCenterY
  
  return dialog
end

function message(text)
  local message = display.newText(text, 0, 0, native.systemFont, 30)
  message:setReferencePoint(display.CenterReferencePoint)
  message.x = display.contentCenterX; message.y = display.contentCenterY + 40
  
  local function remove()
    message:removeSelf()
  end
  local function fade_out()
    transition.to(message, { alpha = 0, time = 500, onComplete = remove })
  end
  timer.performWithDelay(1000, fade_out)
end