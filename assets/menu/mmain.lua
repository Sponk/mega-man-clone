local menu = {}
menu.selectedEntry = 1

local creditsMenu = dofile("mcredits.lua")
local loadGameMenu = dofile("mloadgame.lua")

local neo2d = NeoLua.Neo2DEngine.getInstance()

function menu:init(menusystem)
  local canvas = NeoLua.Canvas()
  
  -- menu.canvasId = neo2d:getNumCanvase()
  neo2d:addCanvas(canvas)  
  menu.menusystem = menusystem
  
  local startGameButton = NeoLua.Button(10, 10, 200, 50, "Start New Game")
  canvas:addWidget(neo2d:addWidget(startGameButton))
  
  local loadGameButton = NeoLua.Button(10, 70, 200, 50, "Load Game")
  canvas:addWidget(neo2d:addWidget(loadGameButton))
  
  local creditsButton = NeoLua.Button(10, 130, 200, 50, "Credits")
  canvas:addWidget(neo2d:addWidget(creditsButton))
  
  local exitGameButton = NeoLua.Button(10, 190, 200, 50, "Exit")
  canvas:addWidget(neo2d:addWidget(exitGameButton))
  
  menu.entries = { startGameButton, loadGameButton, creditsButton, exitGameButton }
  
  startGameButton:setScriptCallback("MainMenuStartGame")
  creditsButton:setScriptCallback("MainMenuCredits")
  exitGameButton:setScriptCallback("MainMenuExit")
  loadGameButton:setScriptCallback("MainMenuLoadGame")
end

function menu:destroy()
  neo2d:scheduleClear()
end

function menu:update(dt)

  if not NeoLua.input:isKeyPressed("MOUSE_BUTTON_LEFT") then
    self.entries[self.selectedEntry]:setButtonState(NeoLua.BUTTON_HOVER_STATE)
  elseif not self.entries[self.selectedEntry]:isMouseOver() then
    self.entries[self.selectedEntry]:setButtonState(NeoLua.BUTTON_NORMAL_STATE)
  end
  
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

function MainMenuStartGame()

end

function MainMenuLoadGame()
  menu.menusystem:changeState(loadGameMenu)
end

function MainMenuCredits()
  menu.menusystem:changeState(creditsMenu)
end

function MainMenuExit()
  NeoLua.engine:setActive(false)
end

return menu