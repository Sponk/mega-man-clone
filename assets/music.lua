-- music.lua - Contains logic to load, manage and play sounds and music.

local music = {
  titles = {},
  types = {},
  typeVolumes = {},
  playing = {}
}

function music:load(path, name, looping, type)
  local sound = NeoLua.level:getCurrentScene():addNewSound(NeoLua.level:loadSound(path))
  self.titles[name] = sound
  --self.titles[name]:update()
  sound:setRelative(true)
  sound:setGain(self.typeVolumes[type] or 1)
  sound:setLooping(looping)
  
  if self.types[type] == nil then
    self.types[type] = { sound } 
  else
    table.insert(self.types[type], sound)
  end
end

function music:play(name)
  local snd = self.titles[name]
  if self.playing[name] == nil then
    snd:play()
    self.playing[name] = true
  end
end

function music:pause(name)
  self.titles[name]:pause()
  self.playing[name] = nil
end

function music:stop(name)
  self.titles[name]:stop()
  self.playing[name] = nil
end

function music:setVolume(type, vol)
  self.typeVolumes[type] = vol
  for k,v in ipairs(self.types[type]) do
    v:setGain(vol)
  end
end

return music