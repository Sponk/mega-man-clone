local state = {}
local neo2d = NeoLua.Neo2DEngine.getInstance()
local Tiled = dofile("tiled.lua")
local Collision = dofile("../physics/Collision.lua")
local Items = dofile("../items/items.lua")
local Weapons = dofile("../weapons/weapons.lua")
local Enemies = dofile("../enemies/enemies.lua")

local PlasmaWeapon = dofile("../weapons/plasma.lua")
Weapons.addWeapon("plasma", PlasmaWeapon)

dofile("../waypoint/waypoint.lua")

local gameoverScreen = dofile("mgameover.lua")

state.playerAnimations = {}
state.playerAnimations.standing = { start = 0, length = 1, delay = 300}
state.playerAnimations.running = { start = 2, length = 3, delay = 100}
state.playerAnimations.jumping = { start = 5, length = 1, delay = 100}
state.playerAnimations.dying = { start = 6, length = 1, delay = 100}
state.playerAnimations.time = 0
state.playerAnimations.frame = 0

state.persistent = {
    lives = 0,
    levelId = 1,
    currentlevel = "levels/level1.lua"
}

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

--- Finds an entry of the given table that has the name attribute set to the given name.
function findShape(l, n)
  for k,v in ipairs(l) do
    if v.name == n then return v end
  end
end

function state:init(menusystem)
  
  state.playerAnimations.current = state.playerAnimations.standing
  state.player = {}
  state.player.velocity = NeoLua.Vector2()
  
  -- Contains all objects that follow a polyline
  state.platforms = {}
  
  if state.persistent.lives == 0 then
    state.persistent.lives = 5
  end
  
  state.gameover = false
  state.player.health = 100

  state.menusystem = menusystem
  state.oldState = menusystem.state

  state.playertile = NeoLua.Tile(100,100,32,32,"",0,0)
  state.playertile:rotate(180)
  state.playersprites = NeoLua.TileSheet()
  
  state.playersprites:loadImage("assets/tilesheets/hero.png", 32, 32, 0)  
  state.playertile:setTileSheet(state.playersprites)
  
  local sbatch = NeoLua.SpriteBatch()
  sbatch:addSprite(state.playertile)
  
  local res = NeoLua.system:getScreenSize()
  state.canvas = NeoLua.Canvas()
  state.hudCanvas = NeoLua.Canvas()
  
  neo2d:addCanvas(state.canvas)
  neo2d:addCanvas(state.hudCanvas)
  
  state.realWidth = 500
  state.realHeight = 400
  
  state.canvas:setScale(res.x/state.realWidth)
  state.camera = NeoLua.Vector2(0,0)
  state.canvas:setCameraOffset(state.camera)
  
  state.tiles = TiledLevel()
  state.tiles:loadTiledFile("assets/levels", state.persistent.currentlevel, state.canvas)
  
  infoLog("Level has " .. #state.tiles.layers[1].objects .. " tiles")
  
  -- Add player after loading the level so he is always
  -- drawn on top
  state.canvas:addSpriteBatch(sbatch)
  
  state.lifebar = {}
  state.lifebar.lifeBatch = NeoLua.SpriteBatch()
  state.lifebar.segments = {}
  
  state.hudCanvas:addSpriteBatch(state.lifebar.lifeBatch)
    
  local segmentCount = math.floor(state.player.health / 10)
  for i = 1, segmentCount, 1 do
    local s = NeoLua.Sprite(i*9 + 10, 10, 9, 16, "assets/tilesheets/HealthSegment.png", "")
    s:setFilter(NeoLua.TEX_FILTER_NEAREST)
    state.lifebar.lifeBatch:addSprite(s)
    
    table.insert(state.lifebar.segments, s)
  end 
    
  -- Set up HUD elements
  state.livesLabel = NeoLua.Label(segmentCount * 9 + 30, 5, 0, 16, "Lives: " .. self.persistent.lives)
  state.livesLabel:setColor(NeoLua.Vector4(1,0,0,1))
  state.livesLabel:setFontSize(16)
  
  state.hudBatch = NeoLua.SpriteBatch()
  state.hudBatch:addSprite(state.livesLabel)
  state.hudCanvas:addSpriteBatch(state.hudBatch)
    
  -- Set up physics
  local playerpos = state.playertile:getPosition()
  local playersize = state.playertile:getSize()
  
  state.player.collision = false
  
  -- The player
  state.player.shape = Collision.addDynamic("circle", 'player', playerpos.x, playerpos.y, playersize.x*0.5, playersize.y*0.5)
  state.player.shape.direction = 1
  function state.player.shape:onCollide(b, nx, ny)
  
    local item = Items[b.tag]
    
    if item ~= nil then
      item:onPlayerCollision(b.sprite, state)
    end   
    
    --if b.type == "platform" then
    --  state.player.shape.gravity = 0
    --end
    
    if (b.tag == "level" or b.type == "platform") and ny < -0.5 then
      state.player.collision = true
    end
    
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
  
  state.level.items = {}
  -- Trigger objects
  for k,v in ipairs(state.tiles.layers[4].objects) do
    local tile = v.tile
    local pos = tile:getPosition()
    local size = tile:getSize()
    local shapeType = Collision.addStatic
    
    if v.properties["Path"] ~= nil or v.properties["Dynamic"] == "true" then
      shapeType = Collision.addDynamic
    end
        
    local shape = shapeType("rect", tile:getLabel(), pos.x - size.y * 0.5, pos.y - size.y * 0.5, size.x * 0.5, size.y * 0.5)
    shape.gravity = v.properties["Gravity"] or 0
    shape.colliding = (v.properties["Colliding"] == "true") or false
    shape.type = v.type
    shape.speed = v.properties["Speed"] or 100
        
    shape.sprite = tile
    tile:setLabel("")
    
    if v.properties["Path"] ~= nil then
      local polyline = findShape(state.tiles.layers[4].shapes, v.properties["Path"])
      table.insert(state.platforms, WayInterpolator(polyline.x, polyline.y, tile, shape, polyline.polyline))
    end
    
    local item = Items[shape.tag]
    
    if item ~= nil then
      if item.onCollide ~= nil then
        shape.onCollide = Items[shape.tag].onCollide
      end
    
      if item.update ~= nil then
        shape.update = item.update    
      end
      
      if item.setUp ~= nil then
        item:setUp(shape)
      end      
    else    
      function shape:onCollide(b)    
        --infoLog("Object Collision: " .. b.tag .. " " .. tostring(self.colliding))
        return self.colliding
      end
    end
     
    table.insert(state.level.physics, shape)
    table.insert(state.level.items, shape)
  end
  
  -- Load weapons
  PlasmaWeapon:load(Collision, state.player.shape)
  
  Collision.printStats()
  Collision.setGravity(0, 1000)
end

function state:showGameOver(x, y)
  local label = NeoLua.Label(x,y,0,0,"GAME OVER")
  label:setFontSize(42)
  label:setColor(NeoLua.Vector4(1,1,1,1))
  label:setAlignment(NeoLua.TEXT_ALIGN_CENTER)
  
  local continueHint = NeoLua.Label(x,y + 50, 0, 0, "Press <START> or <SPACE> to continue...")
  continueHint:setFontSize(16)
  continueHint:setColor(NeoLua.Vector4(1,1,1,1))
  continueHint:setAlignment(NeoLua.TEXT_ALIGN_CENTER)
  
  self.hudBatch:addSprite(label)
  self.hudBatch:addSprite(continueHint)
  
  self.hudCanvas:setClearColor(NeoLua.Vector4(0,0,0,0.8))
end

--- FIXME: Do that in C++, in a seperate thread and use a QuadTree or Kd tree for that!
function state:cullTiles(scale)
  local topleft = self.canvas:getCameraOffset()
  local res = NeoLua.system:getScreenSize() / scale
  
  local m, v, pos, size
  for j = 1, #self.tiles.layers-1, 1 do
    local obj = self.tiles.layers[j].objects
    for i = 1, #obj, 1 do
      local v = obj[i]
      local pos = v:getPosition()
      local size = v:getSize()
      
      if not isColliding(-topleft.x, -topleft.y, res.x, res.y, pos.x, pos.y, size.x, size.y) then
         v:setVisible(false)
      else
         v:setVisible(true) 
      end
    end
  end
end

function state:update(dt)

  self.dt = dt

  if self.gameover then
  
    if NeoLua.input:onKeyDown("SPACE") or NeoLua.input:onKeyDown("JOY1_BUTTON_START") then
      self.menusystem:changeState(self.mainmenu)
    end
  
    return
  end

  if dt * 1000 >= 100 then return end 
  local scriptProfiler = NeoLua.system:getSystemTick()

  self:updatePlayerAnimation(dt)
  
  if NeoLua.input:isKeyPressed("RIGHT") or NeoLua.input:getAxis("JOY1_AXIS_LEFTX") > 0.2 then
      
    self.playertile:setFlip(NeoLua.Vector2(0, 180))
    --self.playertile:translate(NeoLua.Vector2(math.floor(80*dt), 0))
    self.player.shape.direction = 1
    self.player.shape.xv = 120
    self.playerAnimations.current = self.playerAnimations.running
    
  elseif NeoLua.input:isKeyPressed("LEFT") or NeoLua.input:getAxis("JOY1_AXIS_LEFTX") < -0.2 then
          
      self.playertile:setFlip(NeoLua.Vector2(0, 0))
      --self.playertile:translate(NeoLua.Vector2(-math.floor(80*dt), 0))
      self.player.shape.xv = -120
      self.player.shape.direction = 0
      self.playerAnimations.current = self.playerAnimations.running
  else
      self.playerAnimations.time = self.playerAnimations.standing.delay
      self.playerAnimations.current = self.playerAnimations.standing
  end
  
  if (NeoLua.input:isKeyPressed("SPACE") or NeoLua.input:isKeyPressed("JOY1_BUTTON_A")) and state.player.collision then
  
      self.playerAnimations.time = self.playerAnimations.jumping.delay
      self.playerAnimations.current = self.playerAnimations.jumping
      self.player.shape.yv = self.player.shape.yv - 1000 -- FIXME: JUMP HEIGHT!
      
  elseif not state.player.collision then
      self.playerAnimations.time = self.playerAnimations.jumping.delay
      self.playerAnimations.current = self.playerAnimations.jumping
  end 
  
  -- Reset collision flag. Will be set to true when the
  -- collision callback is executed in Collision.update somewhere
  state.player.collision = false
  
  Collision.update(dt)
  self.playertile:setPosition(NeoLua.Vector2(math.floor(self.player.shape.x), math.floor(self.player.shape.y)))
  
  local res = NeoLua.system:getScreenSize()
  local offset = (self.playertile:getPosition() + self.camera)
  local scale = math.min(res.x/state.realWidth, res.y/state.realHeight)
  local scaled = res / scale
  
  if offset.x > 0.75*scaled.x then
    self.camera.x = math.floor(self.camera.x - 100 * dt)
  elseif offset.x < 0.25*scaled.x then
    self.camera.x = math.floor(self.camera.x + 130 * dt)
  end
  
  if offset.y > 0.75*scaled.y then
    self.camera.y = math.floor(self.camera.y - 100 * dt)
  elseif offset.y < 0.25*scaled.y then
    self.camera.y = math.floor(self.camera.y + 100 * dt)
  end
  
  self.canvas:setScale(scale)
  self.hudCanvas:setScale(scale)
  self.canvas:setCameraOffset(self.camera)
  
  -- Update HUD and health bar by turning off segments that should not exist
  for k,v in ipairs(self.lifebar.segments) do
    if k <= math.ceil(self.player.health/10) then
      v:setVisible(true)
    else
      v:setVisible(false)
    end
  end
    
  -- Update platforms
  for k,v in ipairs(self.platforms) do
    v:update(dt)
  end 
  
  -- Update weapons and bullets
  Weapons.update(dt, scale, self.camera)
  
  -- Update items
  for i = 1, #self.level.items, 1 do
    local item = self.level.items[i]
    if item.update then
      item:update(dt, self)
    end
  end
  
  -- Update enemies
  Enemies:update(dt, Collision)
  
  self:cullTiles(scale)
  scriptProfiler = NeoLua.system:getSystemTick() - scriptProfiler
  
    -- For debugging!
  if NeoLua.input:onKeyDown("D") then
    self:applyDamage(100)
  end
  
  if self.player.health <= 0 then
    self.persistent.lives = self.persistent.lives - 1
    
    if self.persistent.lives == 0 then
      -- Show game over
      self.gameover = true
      self:showGameOver(self.realWidth/2, self.realHeight*0.25)
    else
      -- Restart the level
      self.menusystem:changeState(self)
    end    
    return
  end

  -- print("Framerate: dt = " .. dt * 1000 .. "ms fps: " .. 1/dt .. " script performance: " .. scriptProfiler .. "ms fps: " .. 1/(scriptProfiler*0.001) .. " Number of collision checks: " .. Collision.getCollisionCount())
end

function state:applyDamage(amount)
  self.player.health = math.max(0, self.player.health - amount * self.dt)
end

function state:removeItem(shape)
  
  -- printTable(shape)
  Collision.removeShape(shape)
  
  for i = 1, #self.level.items, 1 do
    if self.level.items[i] == shape then
      table.remove(self.level.items, i)
      i = #self.level.items + 1
    end
  end
  
  for i = 1, #self.level.physics, 1 do
    if self.level.physics[i] == shape then
      table.remove(self.level.physics, i)
      i = #self.level.physics + 1
    end
  end
  
  for i = 1, #self.platforms, 1 do
    if self.platforms[i].shape == shape then
      table.remove(self.platforms, i)
    end
  end 
  
  shape.sprite:setVisible(false)
end

function state:destroy()
  neo2d:scheduleClear()
  --[[for k,v in ipairs(self.level.physics) do
    infoLog("Removing " .. k)
    Collision.removeShape(v)
  end]]
  
  Collision.clear()  
  self.level.physics = {}
end

return state