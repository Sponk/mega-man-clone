
local MenuSystem = dofile("menu/menusystem.lua")
local Intro = dofile("menu/mmain.lua")
--local Intro = dofile("menu/mintro.lua")

-- Turn off 3D threads
NeoLua.engine:getRenderer():stopThreads()

MenuSystem:changeState(Intro)

function update(dt)
  MenuSystem:update(dt)
end