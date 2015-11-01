
local MenuSystem = dofile("menu/menusystem.lua")
local Intro = dofile("menu/mmain.lua")
--local Intro = dofile("menu/mintro.lua")

MenuSystem:changeState(Intro)

function update(dt)
  MenuSystem:update(dt)
end