--- weapons.lua - Contains primitives for managing weapon types and behaviors.

local weapons = {
  types = {},
  current = 1
}

function weapons.update(dt, scale, camera)
  weapons.current:update(dt, scale, camera)
end

function weapons.addWeapon(n, t)
  weapons.types[n] = t
  weapons.current = t
end

return weapons