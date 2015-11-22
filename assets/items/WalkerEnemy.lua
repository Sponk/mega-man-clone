--- WalkerEnemy.lua

local item = {
  damage = 10,
  health = 5
}

function item:setUp(shape)
  shape.health = self.health
end

function item:onPlayerCollision(obj, state)
  state:applyDamage(self.damage)
end

function item:update(dt, state)
  self.dt = dt
  if self.health <= 0 then
    infoLog("I'M DEAD YOU FUCKING MORON!")
    state:removeItem(self)
  end
end

function item:onCollide(b)
  if b.damage ~= nil then
    self.health = self.health - b.damage * self.dt
  end
  
  if self.health > 0 then
    return true
  else
    return false
  end
end

return item