---@class Entity:Object
_class("Entity", Object)

function Entity:Constructor()
    self._creationIndex = 0
    self._isEnabled = false
    self._retainCount = 0
    self._components = {}

    self.Ev_OnComponentAdded = DelegateEvent:New()
    self.Ev_OnComponentRemoved = DelegateEvent:New()
    self.Ev_OnComponentReplaced = DelegateEvent:New()
    self.Ev_OnEntityReleased = DelegateEvent:New()
end

function Entity:Destructor()
    self._components = nil

    self.Ev_OnComponentAdded = nil
    self.Ev_OnComponentRemoved = nil
    self.Ev_OnComponentReplaced = nil
    self.Ev_OnEntityReleased = nil
end

function Entity:isEnabled()
    return self._isEnabled
end

function Entity:Initialize(creationIndex)
    self:Reactivate(creationIndex)
end

function Entity:Destroy()
    self:RemoveAllComponents()
    self._isEnabled = false
    self.Ev_OnComponentAdded:Clear()
    self.Ev_OnComponentReplaced:Clear()
    self.Ev_OnComponentRemoved:Clear()
    self.Ev_OnEntityReleased:Clear()
end

function Entity:RemoveAllOnEntityReleasedHandlers()
    self.Ev_OnEntityReleased:Clear()
end

function Entity:Reactivate(creationIndex)
    self._isEnabled = true
    self._creationIndex = creationIndex
end

function Entity:AddComponent(index, component)
    if not self._isEnabled then
        Log.debug("Entity:AddComponent Error! entity._isEnabled = false")
        return
    end

    if self:HasComponent(index) then
        Log.debug("Entity:AddComponent Error HasComponent Already : " .. index)
        return
    end

    self._components[index] = component
    self.Ev_OnComponentAdded(self, index, component)
end

function Entity:RemoveComponent(index)
    if not self._isEnabled then
        Log.debug("Entity:RemoveComponent Error! entity._isEnabled = false")
        return
    end

    if not self:HasComponent(index) then
        Log.debug("Entity:RemoveComponent Error !HasComponent: " .. index)
        return
    end

    local previousComponent = self._components[index]
    self._components[index] = nil
    self.Ev_OnComponentRemoved(self, index, previousComponent)
    if previousComponent.Dispose then
        previousComponent:Dispose()
    end
end

function Entity:ReplaceComponent(index, component)
    if not self._isEnabled then
        Log.debug("Entity:ReplaceComponent Error! entity._isEnabled = false")
        return
    end

    if not self:HasComponent(index) then
        self:AddComponent(index, component)
        return
    end

    local previousComponent = self._components[index]
    if previousComponent ~= component then
        self._components[index] = component
        if component ~= nil then
            self.Ev_OnComponentReplaced(self, index, previousComponent, component)
        else
            self.Ev_OnComponentRemoved(self, index, previousComponent)
            previousComponent:Dispose()
        end
    else
        self.Ev_OnComponentReplaced(self, index, previousComponent, component)
    end
end

function Entity:GetComponent(index)
    return self._components[index]
end

function Entity:GetComponents()
    return self._components
end

function Entity:GetComponentIndices()
    local indices = {}
    for i, _ in pairs(self._components) do
        table.insert(indices, i)
    end
    return indices
end

function Entity:HasComponent(index)
    return self._components[index] ~= nil
end

function Entity:HasComponents(indices)
    for _, v in pairs(indices) do
        if self._components[v] == nil then
            return false
        end
    end
    return true
end

function Entity:HasAnyComponent(indices)
    for _, v in pairs(indices) do
        if self._components[v] ~= nil then
            return true
        end
    end
    return false
end

function Entity:RemoveAllComponents()
    for i, c in pairs(self._components) do
        self:RemoveComponent(i)
    end
    self._components = {}
end

function Entity:GetCreationIndex()
    return self._creationIndex
end

function Entity:Retain(owner)
    self._retainCount = self._retainCount + 1
end

function Entity:Release(owner)
    self._retainCount = self._retainCount - 1
    if self._retainCount == 0 then
        self.Ev_OnEntityReleased(self)
    end
end

