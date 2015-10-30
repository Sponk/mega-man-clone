local menu = {}
menu.selectedEntry = 1

local neo2d = NeoLua.Neo2DEngine.getInstance()

function menu:init(menusystem)
  -- menu.canvasId = neo2d:getNumCanvase()
  menu.menusystem = menusystem
  menu.oldState = menusystem.state
  
  local res = NeoLua.system:getScreenSize()  
  local canvas = NeoLua.Canvas()
  neo2d:addCanvas(canvas)
    
  local loadGameButton = NeoLua.Button(10, 10, 200, 50, "Load Game")
  canvas:addWidget(neo2d:addWidget(loadGameButton))
  
  local copyGameButton = NeoLua.Button(10, 70, 200, 50, "Copy Game")
  canvas:addWidget(neo2d:addWidget(copyGameButton))
    
  local backButton = NeoLua.Button(10, 130, 200, 50, "Back")
  canvas:addWidget(neo2d:addWidget(backButton))
   
  menu.entries = { loadGameButton, copyGameButton, backButton }   
  backButton:setScriptCallback("LoadGameBack")  
end

function menu:update(dt) 
    self.entries[self.selectedEntry]:setButtonState(NeoLua.BUTTON_HOVER_STATE)
   
  if NeoLua.input:onKeyDown("ENTER") or NeoLua.input:onKeyDown("SPACE") or NeoLua.input:onKeyDown("JOY1_BUTTON_START") then
    self.entries[self.selectedEntry]:doCallback()
  end
  
  if NeoLua.input:onKeyDown("DOWN") or NeoLua.input:onKeyDown("JOY1_BUTTON_DPADDOWN") then
    self.selectedEntry = (self.selectedEntry + 1) % (#self.entries + 1)
  end
    
  if NeoLua.input:onKeyDown("UP") or NeoLua.input:onKeyDown("JOY1_BUTTON_DPADUP") then
    self.selectedEntry = (self.selectedEntry - 1) % (#self.entries + 1)
  end
  
  if self.selectedEntry == 0 then self.selectedEntry = 1 end  
end

function menu:destroy()
  neo2d:scheduleClear()
end

function LoadGameBack()
  menu.menusystem:changeState(menu.oldState)
end

return menu