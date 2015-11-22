
local MenuSystem = dofile("menu/menusystem.lua")
local Intro = dofile("menu/mmain.lua")
Music = dofile("music.lua")


--local Intro = dofile("menu/mintro.lua")

-- Turn off 3D threads
NeoLua.engine:getRenderer():stopThreads()

MenuSystem:changeState(Intro)

function update(dt)

  if NeoLua.input:onKeyDown("ESCAPE") then
    os.exit(0)
  end

  MenuSystem:update(dt)
end