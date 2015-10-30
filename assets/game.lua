
local MenuSystem = dofile("menu/menusystem.lua")
local MainMenu = dofile("menu/mmain.lua")

MenuSystem:changeState(MainMenu)

function update(dt)
  MenuSystem:update(dt)
end