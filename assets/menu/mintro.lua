local menu = {}
menu.scrollSpeed = 25
menu.delay = 5000
menu.time = 0

local neo2d = NeoLua.Neo2DEngine.getInstance()

local mainmenu = dofile("mmain.lua")

function menu:init(menusystem)
  menu.menusystem = menusystem
  
  local canvas = NeoLua.Canvas()
  neo2d:addCanvas(canvas)  
end

function menu:update(dt)
    
    self.time = self.time + dt * 1000
    if self.time >= self.delay then
        self.menusystem:changeState(mainmenu)
    end
end

function menu:destroy()
  neo2d:scheduleClear()
end

return menu