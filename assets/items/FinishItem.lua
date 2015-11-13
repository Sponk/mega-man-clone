--- FinishItem.lua - Implements an item that loads a new level.

local item = {}

function item:onCollision(obj, state)
  state.persistent.levelId = state.persistent.levelId + 1
  state.persistent.currentlevel = "levels/level" .. state.persistent.levelId .. ".lua"
  state.menusystem:changeState(state)
end

return item