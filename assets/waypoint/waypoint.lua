--- waypoint.lua - Contains "classes" to handle movement along a given path

WayPath = class(
  function(obj, points)
    obj.points = points
  end
)

WayInterpolator = class(
  function(obj, x, y, tile, physshape, waypath, interpolation)
  
    if interpolation == nil then
      function obj:update(dt)
      
        local p = self.waypath[self.current]
        local target = NeoLua.Vector2(self.x + p.x, self.y + p.y)
        local pos = self.tile:getPosition()
        
        local way = target - pos
        way = way:getNormalized() * self.speed
        
        self.shape.xv = way.x
        self.shape.yv = way.y
        
        self.tile:setPosition(NeoLua.Vector2(self.shape.x, self.shape.y))
        
        --infoLog("Moving object: From x " .. self.shape.x .. " y " .. self.shape.y .. " to x " .. p.x + self.x .. " y " .. p.y + self.y)
        
        -- If we reached the waypoint continue with the next one!
        if pos.x < target.x + self.threshold and pos.x > target.x - self.threshold
          and pos.y < target.y + self.threshold and pos.y > target.y - self.threshold then
          
          self.current = (self.current + 1)
          if self.current >= #self.waypath then
            self.current = 1
          end
          --infoLog("Next point: " .. self.current);
        end        
      end
    else
      obj.update = interpolation
    end
  
    obj.speed = 100
    obj.threshold = obj.speed * 0.2
    obj.x = x
    obj.y = y
    obj.tile = tile
    obj.shape = physshape
    obj.waypath = waypath
    obj.current = 1
    
    obj.tile:setPosition(NeoLua.Vector2(obj.waypath[1].x + x, obj.waypath[1].y + y))
  end
)