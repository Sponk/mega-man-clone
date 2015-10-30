local menusystem = {
  state = nil
}

--- Changes the state to the given argument and calls init.
function menusystem:changeState(nstate)

  if nstate == nil then return end

  if self.state ~= nil then
    self.state:destroy()
  end
  
  self.scheduledAction = function()
    nstate:init(self)
    self.state = nstate
  end
end

function menusystem:update(dt)
  if self.scheduledAction ~= nil then
    self:scheduledAction()
    self.scheduledAction = nil
  end
  
  if self.state ~= nil then
    self.state:update(dt)
  end
end

return menusystem