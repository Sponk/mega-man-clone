local menu = {}
menu.scrollSpeed = 25

local neo2d = NeoLua.Neo2DEngine.getInstance()

function menu:init(menusystem)
  -- menu.canvasId = neo2d:getNumCanvase()
  menu.menusystem = menusystem
  
  local res = NeoLua.system:getScreenSize()  
  local canvas = NeoLua.Canvas()
  neo2d:addCanvas(canvas)
    
  local backButton = NeoLua.Button(10, 10, 200, 50, "Main Menu")
  
  canvas:addWidget(neo2d:addWidget(backButton))  
  backButton:setScriptCallback("GameoverBack")  
end

function menu:update(dt)
  menu.content:setPosition(menu.content:getPosition() + NeoLua.Vector2(0, -menu.scrollSpeed * dt))
  
  if NeoLua.input:onKeyDown("ENTER") or NeoLua.input:onKeyDown("SPACE") or NeoLua.input:onKeyDown("JOY1_BUTTON_START") then
    menu.menusystem:changeState(menu.oldState)
  end  
end

function menu:destroy()
  neo2d:scheduleClear()
end

function GameoverBack()
  menu.menusystem:changeState(menu.mainmenu)
  infoLog("LALA BACK")
end

return menu