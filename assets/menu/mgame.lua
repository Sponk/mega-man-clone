local state = {}
local neo2d = NeoLua.Neo2DEngine.getInstance()
local Tiled = dofile("tiled.lua")
local Collision = dofile("../physics/Collision.lua")

state.playerAnimations = {}
state.playerAnimations.standing = { start = 0, length = 1, delay = 300}
state.playerAnimations.running = { start = 2, length = 3, delay = 100}
state.playerAnimations.jumping = { start = 5, length = 1, delay = 100}
state.playerAnimations.dying = { start = 6, length = 1, delay = 100}
state.playerAnimations.time = 0
state.playerAnimations.frame = 0

state.playerAnimations.current = state.playerAnimations.standing
state.player = {}
state.player.velocity = NeoLua.Vector2()
state.player.lives = 5
state.player.health = 100

function state:updatePlayerAnimation(dt)

  if state.playerAnimations.current == nil 
      then return end

  state.playerAnimations.time = state.playerAnimations.time + dt * 1000
  
  if state.playerAnimations.time >= state.playerAnimations.current.delay then
    state.playerAnimations.time = 0
    state.playerAnimations.frame = ((state.playerAnimations.frame + 1) % state.playerAnimations.current.length)
    state.playertile:setOffset(NeoLua.Vector2(state.playerAnimations.frame + state.playerAnimations.current.start, 0))
  end
end

local function isColliding(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

local function collisionDirection(x1, y1, w1, h1, x2, y2, w2, h2)

end

local function isCollidingWithLevel(player, level, playerOffset)
  -- printTable(level)
  local pos = player:getPosition()
  local size = player:getSize()
  
  --[[for k,v in ipairs(level.objects) do
    -- TODO: Culling!
    local levelPos = v:getPosition()
    local levelSize = v:getSize()
    
    if isColliding(pos.x, pos.y, size.x, size.y, levelPos.x, levelPos.y, levelSize.x, levelSize.y) then
      infoLog("TRUE")
      return true
    end
  end]]
  
  for i = 1, #level.objects, 1 do
    -- TODO: Culling!
    local v = level.objects[i]
    local levelPos = v:getPosition()
    local levelSize = v:getSize()
    
    if isColliding(pos.x, pos.y, size.x, size.y, levelPos.x, levelPos.y, levelSize.x, levelSize.y) then
      return true, v
    end
  end
  
  return false
end

function state:init(menusystem)
  state.menusystem = menusystem

  state.playertile = NeoLua.Tile(100,100,32,32,"",0,0)
  state.playertile:rotate(180)
  state.playersprites = NeoLua.TileSheet()
  
  state.playersprites:loadImage("assets/tilesheets/hero.png", 32, 32, 0)  
  state.playertile:setTileSheet(state.playersprites)
  
  local sbatch = NeoLua.SpriteBatch()
  sbatch:addSprite(state.playertile)

  local res = NeoLua.system:getScreenSize()
  local canvas = NeoLua.Canvas()
  neo2d:addCanvas(canvas)
   
  state.tiles = TiledLevel()
  state.tiles:loadTiledFile("levels/level1.lua", canvas)
  
  -- Add player after loading the level so he is always
  -- drawn on top
  canvas:addSpriteBatch(sbatch)
    
  -- Set up physics
  local playerpos = state.playertile:getPosition()
  local playersize = state.playertile:getSize()
  
  state.player.collision = false
  
  -- The player
  state.player.shape = Collision.addDynamic("circle", 'player', playerpos.x, playerpos.y, playersize.x*0.5, playersize.y*0.5)
  function state.player.shape:onCollide(b)
    --infoLog("Player Collision: " .. b.tag) 
    state.player.collision = true    
    return true
  end
  
  -- The level
  state.level = {physics = {}}
  
  -- Static level
  for k,v in ipairs(state.tiles.layers[1].objects) do
    local pos = v:getPosition()
    local size = v:getSize()    
    table.insert(state.level.physics, Collision.addStatic("rect", 'level', pos.x - size.y * 0.5, pos.y - size.y * 0.5, size.x * 0.5, size.y * 0.5))
  end
  
  -- Death Triggers
  for k,v in ipairs(state.tiles.layers[3].objects) do
    local pos = v:getPosition()
    local size = v:getSize()   
    local shape = Collision.addStatic("rect", 'trigger', pos.x - size.y * 0.5, pos.y - size.y * 0.5, size.x * 0.5, size.y * 0.5)
    
    function shape:onCollide(b)    
      --infoLog("TRIGGER!")
      return false
    end
     
    table.insert(state.level.physics, shape)
  end
  
  -- Trigger objects
  for k,v in ipairs(state.tiles.layers[4].objects) do
    local pos = v:getPosition()
    local size = v:getSize()   
    local shape = Collision.addStatic("rect", v:getLabel(), pos.x - size.y * 0.5, pos.y - size.y * 0.5, size.x * 0.5, size.y * 0.5)
    
    v:setLabel("")
    
    function shape:onCollide(b)    
      --infoLog("Object Collision: " .. b.tag)
      return false
    end
     
    table.insert(state.level.physics, shape)
  end
  
  Collision.setGravity(0, 1000)
end

function state:update(dt)

  if dt * 1000 >= 100 then return end 

  self:updatePlayerAnimation(dt)
  
  --[[local collision, object = isCollidingWithLevel(self.playertile, self.tiles.layers[1])
  local objectPos = NeoLua.Vector2()
  local objectCenter = NeoLua.Vector2()
  local objectSize = NeoLua.Vector2()
  if object ~= nil then
    objectPos = object:getPosition()
    objectSize = object:getSize()
    objectCenter = objectPos + object:getSize() * 0.5
  end
  
  local playerPos = self.playertile:getPosition()
  local playerSize = self.playertile:getSize()
  
  local playerCenter = playerPos + playerSize * 0.5
    
  --- FIXME: Real physics?
  if not collision then
    self.player.velocity.y = self.player.velocity.y + 1000 * dt -- FIXME: Define gravity as variable!
  else
  
    -- infoLog("objectX: " .. objectPos.x .. " playerX: " .. playerPos.x)
    local oppositePoint = playerPos + playerSize
    if oppositePoint.y >= objectPos.y 
      and (objectPos.x + objectSize.x) < oppositePoint.x - 3
      and (objectPos.x + objectSize.x) > playerPos.x + 3 then
      
      local diff = math.floor(objectPos.y - playerSize.y + 2)
      infoLog(objectPos.y - diff)
      
      --if math.abs(objectPos.y - diff) < 30 then
        playerPos.y = diff
        self.playertile:setPosition(playerPos) -- -(self.player.velocity.y - (playerCenter.y - objectCenter.y)) * 0.25
      --end
      
      self.player.velocity.y = 0
      
        if oppositePoint.x >= objectPos.x - 3
        and (oppositePoint.y > objectPos.y + 3)
          then
                
          --if math.abs(objectPos.y - diff) < 30 then
            playerPos.x = objectPos.x
            self.playertile:setPosition(playerPos) -- -(self.player.velocity.y - (playerCenter.y - objectCenter.y)) * 0.25
          --end
          
          self.player.velocity.y = 0
        end
    end
    
    --[[if oppositePoint.x >= objectPos.x
      and (oppositePoint.y > objectPos.y + 3)
      then
            
      --if math.abs(objectPos.y - diff) < 30 then
        playerPos.x = objectPos.x
        self.playertile:setPosition(playerPos) -- -(self.player.velocity.y - (playerCenter.y - objectCenter.y)) * 0.25
      --end
      
      self.player.velocity.y = 0
    end
    
    --self.player.velocity.x = 0
  --else
    --self.player.velocity.y = 0
  end]]
  
  if NeoLua.input:isKeyPressed("RIGHT") then
      
    self.playertile:setFlip(NeoLua.Vector2(0, 180))
    --self.playertile:translate(NeoLua.Vector2(math.floor(80*dt), 0))
    self.player.shape.xv = 80
    self.playerAnimations.current = self.playerAnimations.running
    
  elseif NeoLua.input:isKeyPressed("LEFT") then
          
      self.playertile:setFlip(NeoLua.Vector2(0, 0))
      --self.playertile:translate(NeoLua.Vector2(-math.floor(80*dt), 0))
      self.player.shape.xv = -80
      self.playerAnimations.current = self.playerAnimations.running
  else
      self.playerAnimations.time = self.playerAnimations.standing.delay
      self.playerAnimations.current = self.playerAnimations.standing
  end
  
  if NeoLua.input:onKeyDown("SPACE") and state.player.collision then
  
      self.playerAnimations.time = self.playerAnimations.jumping.delay
      self.playerAnimations.current = self.playerAnimations.jumping
      self.player.shape.yv = self.player.shape.yv - 1000 -- FIXME: JUMP HEIGHT!
      
  elseif not state.player.collision then
      self.playerAnimations.time = self.playerAnimations.jumping.delay
      self.playerAnimations.current = self.playerAnimations.jumping
  end
  
  --local vel = self.player.velocity * dt
  --vel.x = math.floor(vel.x * 100)/100
  --vel.y = math.floor(vel.y * 100)/100
  
  -- self.playertile:translate(vel)
  
  -- Reset collision flag. Will be set to true when the
  -- collision callback is executed in Collision.update somewhere
  state.player.collision = false
  
  Collision.update(dt)
  self.playertile:setPosition(NeoLua.Vector2(math.floor(self.player.shape.x), math.floor(self.player.shape.y)))  
end

function state:destroy()
  neo2d:scheduleClear()
end

return state