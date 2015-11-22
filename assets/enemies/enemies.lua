--- enemies.lua - Contains primitives to manage and update enemies and their behaviors.
local enemies = {
  types = {},
  enemies = {}
}

function enemies:update(dt, collision)
  for i = #self.enemies, -1, 1 do
    local enemy = self.enemies[i]
    enemy:update(dt)
  end
end

function enemies:addEnemy(type, sprite, shape)
 
  shape.onCollide = self.types[type] or function()
    infoLog("Unknown enemy!")
  end
  
  shape.sprite = sprite
  table.insert(enemies, shape)
end

return enemies