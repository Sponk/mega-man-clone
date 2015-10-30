local menu = {}
menu.scrollSpeed = 25

local neo2d = NeoLua.Neo2DEngine.getInstance()

function menu:init(menusystem)
  -- menu.canvasId = neo2d:getNumCanvase()
  menu.menusystem = menusystem
  menu.oldState = menusystem.state
  
  local res = NeoLua.system:getScreenSize()  
  local canvas = NeoLua.Canvas()
  neo2d:addCanvas(canvas)
    
  local backButton = NeoLua.Button(10, 10, 200, 50, "Back")
  menu.content = NeoLua.Label(res.x/2, res.y, 0, 0, NeoLua.readTextFile("assets/credits.txt"))
  
  canvas:addWidget(neo2d:addWidget(menu.content))
  canvas:addWidget(neo2d:addWidget(backButton))
  
  menu.content:setColor(NeoLua.Vector4(1,1,1,1))
  menu.content:setFontSize(20)
  menu.content:setAlignment(NeoLua.TEXT_ALIGN_CENTER)
  
  backButton:setScriptCallback("CreditsBack")  
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

function CreditsBack()
  menu.menusystem:changeState(menu.oldState)
end

return menu