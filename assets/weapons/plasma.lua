--- plasma.lua - Implements the plasma weapon

local gun = {
  bullets = {},
  range = 700,
  damage = 100,
  velocity = 200,
  image = "assets/tilesheets/bullet1.png"
}

function gun:update(dt, scale, camera)
  self.canvas:setScale(scale)
  self.canvas:setCameraOffset(camera)
  
  if NeoLua.input:onKeyDown("LCONTROL") or NeoLua.input:onKeyDown("JOY1_BUTTON_X") then
    local sprite = NeoLua.Sprite(self.player.x, self.player.y, 0, 0, self.image, "")
    local sz = sprite:getSize()
    local shape = self.collision.addKinematic("rect", "plasma", self.player.x + self.player.direction * self.player.r,
                                                self.player.y + self.player.r*0.75, sz.x/2, sz.y/2)
    shape.sprite = sprite
    shape.sid = self.batch:getNumSprites() - 1
    shape.damage = self.damage
    
    if self.player.direction == 1 then
      shape.sprite:setRotation(180)    
      shape.xv = self.velocity
    else
      shape.xv = -self.velocity
    end
    
    shape.collision = false
    function shape:onCollide(b)
      
      if b.tag ~= "player" then
        shape.collision = true
      end
      return false
    end
    
    sprite:setFilter(NeoLua.TEX_FILTER_NEAREST)
    
    table.insert(self.bullets, shape)
    self.batch:addSprite(sprite)
  end
  
  local playerpos = NeoLua.Vector2(self.player.x, self.player.y)
  for i = #self.bullets, 1, -1 do
    local bullet = self.bullets[i]
    local bulletpos = NeoLua.Vector2(bullet.x, bullet.y)
    
    if (playerpos - bulletpos):getLength() > self.range or bullet.collision then
      self.batch:deleteSprite(i-1)
      self.collision.removeShape(bullet)
      table.remove(self.bullets, i)
    else
      bullet.sprite:setPosition(bulletpos)
    end
  end
end

function gun:load(collision, playershape)
  self.collision = collision
  -- self.sprite = NeoLua.Sprite()
  self.player = playershape
  self.canvas = NeoLua.Canvas()
  self.batch = NeoLua.SpriteBatch()
  self.canvas:addSpriteBatch(self.batch)
  
  NeoLua.Neo2DEngine.getInstance():addCanvas(self.canvas)
end

return gun