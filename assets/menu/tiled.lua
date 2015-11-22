--- The Tiled Loader
-- This file contains primitives to load and process Tiled maps.
-- Loading them currently allows only one layer and sprite sheet
-- for simplicity reasons.

dofile("class.lua")

TiledLayer = class(
   function(obj, t)
	  obj.type = t
	  obj.objects = {}
	  obj.shapes =  {}
   end
)

TiledLevel = class(
   function(obj)
	  obj.path = ""
	  obj.layers = {}
   end
)

TiledObject = class(
  function(obj, name, tag, type, properties, tile)
    obj.name = name
    obj.tag = tag
    obj.properties = properties
    obj.tile = tile
    obj.type = type
  end
)

local FLIPPED_HORIZONTALLY_FLAG = 0x80000000
local FLIPPED_VERTICALLY_FLAG   = 0x40000000
local FLIPPED_DIAGONALLY_FLAG   = 0x20000000
--local bit = require("bit")

function testflag(set, flag)
  return set % (2*flag) >= flag
end

function setflag(set, flag)
  if set % (2*flag) >= flag then
    return set
  end
  return set + flag
end

function clrflag(set, flag) -- clear flag
  if set % (2*flag) >= flag then
    return set - flag
  end
  return set
end


--- Converts a Tiled GID to a x/y position on the TileSheet.
-- @param gid The GID to convert
-- @param width The TileSheet width
-- @param height The TileSheet height
-- @return A vec2 containing the 2D coordinates.
function TiledLevel:getTilePosition(gid, width, height)

   local pos = {x = 0, y = 0}
   if gid < 0 then return {x = 0, y = -1} end

   local ogid = gid
   gid = clrflag(gid, FLIPPED_HORIZONTALLY_FLAG) --bit.band(gid, bit.bnot(bit.bor(FLIPPED_HORIZONTALLY_FLAG, FLIPPED_VERTICALLY_FLAG, FLIPPED_DIAGONALLY_FLAG)))
   gid = clrflag(gid, FLIPPED_VERTICALLY_FLAG)
   gid = clrflag(gid, FLIPPED_DIAGONALLY_FLAG)

   --infoLog("ogid: " .. ogid .. " gid: " .. gid .. " width: " .. width .. " height: " .. height)

   --width = width + 1
   --pos.x = math.ceil(gid / width) - 1
   --pos.y = math.ceil(gid % height)
   
   pos.x = gid % width;
   pos.y = math.floor(gid / width);
   
   --infoLog("pos.x: " .. pos.x .. " pos.y " .. pos.y)
   return pos
end


--- Loads a Lua file exported by the Tiled 2D map editor
-- and returns a table of Tiles containing all loaded tiles.
-- 
-- @param imagepath The directory the level file resides in relative to the NeoPlayer executable
-- @param canvas The canvas that will display the tiles
-- @param path The Lua file to load
function TiledLevel:loadTiledFile(imagepath, path, canvas)
   
   local imagepath = string.match(imagepath, "(.-)([^\\/]-%.?([^%.\\/]*))$")
   --path = path:gsub("/", ".")

   -- FIXME: Deletes every ".lua", not just the file ending!
   --path = path:gsub(".lua", "")

   local tiledLevel = dofile(path)
   
   infoLog("Found level version: " .. tiledLevel.version)
      
   local resolution = NeoLua.system:getScreenSize()
   local tiledSpriteSheet = tiledLevel.tilesets[1]
   local tilesets = {}
   
   local i = 1
   for k,v in ipairs(tiledLevel.tilesets) do
     
      tilesets[i] = {
        spritesheetSize = { x = math.floor(v.imagewidth / v.tilewidth), 
                            y = math.floor(v.imageheight / v.tileheight) },
                            
        sheet = NeoLua.TileSheet(),
        tileset = v        
      }
      
      tilesets[i].sheet:loadImage(imagepath .. v.image, 
                                  v.tilewidth, 
                                  v.tileheight,
                                  v.spacing)
                               
      infoLog("Loading sprite sheet: " .. v.image .. " width: " .. tilesets[i].spritesheetSize.x .. " height: " .. tilesets[i].spritesheetSize.y)
         
      i = i + 1
    end
   
   local function findTileset(gid)
   
    -- It does not matter since the tile is going to get ignored
    if gid == 0 then
      return tilesets[1]
    end
   
    for k,v in ipairs(tilesets) do
      if gid <= (v.tileset.firstgid + v.tileset.tilecount) then
        --infoLog("Got gid = " .. gid .. " and firstgid = " .. v.tileset.firstgid)
        return v
      end
      
      prev = v
    end
    
    return nil
   end
   
   --local spritesheetSize = { x = math.ceil(tiledSpriteSheet.imagewidth / tiledSpriteSheet.tilewidth), 
   --                          y = math.ceil(tiledSpriteSheet.imageheight / tiledSpriteSheet.tileheight) }
   
   --local spriteSheet = NeoLua.TileSheet()
   
   --spriteSheet:loadImage(tiledSpriteSheet.image, 
   --   								   tiledSpriteSheet.tilewidth, 
   --   								   tiledSpriteSheet.tileheight,
   --   								   tiledSpriteSheet.spacing)

   for n,l in pairs(tiledLevel.layers) do
	  local layer = TiledLayer(l.type)
	  table.insert(self.layers, layer)

	  local x = 0
	  local y = 0
	  local tpos = {}

	  if l.type == "tilelayer" then
		 for i = 1, #l.data, 1 do
			
			x = x + 1
			if x >= l.width then
			   x = 0
			   y = y+1
			end
			
			local sheet = findTileset(l.data[i])
			local spritesheetSize = sheet.spritesheetSize
			local tiledSpriteSheet = sheet.tileset
			local spriteSheet = sheet.sheet
			
			tpos = self:getTilePosition(l.data[i] - tiledSpriteSheet.firstgid, spritesheetSize.x, spritesheetSize.y)
			
			local spriteBatch = NeoLua.SpriteBatch()
			canvas:addSpriteBatch(spriteBatch)
			
			if tpos.x >= 0  and tpos.y >= 0 then
			
			   --infoLog("tpos.x: " .. tpos.x .. " tpos.y " .. tpos.y)
			   --tpos = {x = 0, y = 0}
			
			   local tile = NeoLua.Tile(x * tiledSpriteSheet.tilewidth, 
                                  y * tiledSpriteSheet.tileheight, 
                                  tiledSpriteSheet.tilewidth, 
                                  tiledSpriteSheet.tileheight,
                                  "", tpos.x, tpos.y)
        
         --tile:setOffset(NeoLua.Vector2(tpos.x, tpos.y))
         tile:rotate(180)
         tile:setTileSheet(spriteSheet)
			   table.insert(layer.objects, tile)		
			   
			   spriteBatch:addSprite(tile)
			end
		 end
			
	  elseif l.type == "objectgroup" then
	  
	    local spriteBatch = NeoLua.SpriteBatch()
      canvas:addSpriteBatch(spriteBatch) 
	  
	   infoLog("Loading objects")
		 for n,o in pairs(l.objects) do	
			
			if o.shape == "polyline" then
       table.insert(layer.shapes, o)
			 infoLog("Found polyline.");
			else			
  			local sheet = findTileset(o.gid)
        local spritesheetSize = sheet.spritesheetSize
        local tiledSpriteSheet = sheet.tileset
        local spriteSheet = sheet.sheet
  			local tpos = self:getTilePosition(o.gid - tiledSpriteSheet.firstgid, spritesheetSize.x, spritesheetSize.y)
  			
  			 local tile = NeoLua.Tile(o.x + o.width, o.y - o.height, o.width, o.height, o.name, tpos.x, tpos.y)
  			
  			 tile:rotate(180 + o.rotation)
  			
  			 table.insert(layer.objects, TiledObject(o.name, o.tag, o.type, o.properties, tile))
  			 tile:setTileSheet(spriteSheet)  			
  			 spriteBatch:addSprite(tile)
			 end	 
		 end
	  end
   end
end
