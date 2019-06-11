---@class Collector:Object
_class("Collector", Object)

function Collector:Constructor(groups, groupEvents)
    ---@type Group
    self._groups = groups
    self._groupEvents = groupEvents
    self.collectedEntities = {}

    if #groups ~= #groupEvents then
        error("groups.Length != groupEvents.Length")
    end
end

function Collector:Destructor()
    self._groups = nil
    self._groupEvents = nil
    self.collectedEntities = nil
end

function Collector:Activate()
    --两个长度一致
    for i = 1, #self._groups do
        local group = self._groups[i]
        local groupEvent = self._groupEvents[i]
        local addEntityFunc = self.addEntity
        if groupEvent == "Added" then
            group.Ev_OnEntityAdded:RemoveEvent(self, addEntityFunc)
            group.Ev_OnEntityAdded:AddEvent(self, addEntityFunc)
        elseif groupEvent == "Removed" then
            group.Ev_OnEntityRemoved:RemoveEvent(self, addEntityFunc)
            group.Ev_OnEntityRemoved:AddEvent(self, addEntityFunc)
        elseif groupEvent == "AddedOrRemoved" then
            group.Ev_OnEntityAdded:RemoveEvent(self, addEntityFunc)
            group.Ev_OnEntityAdded:AddEvent(self, addEntityFunc)
            group.Ev_OnEntityRemoved:RemoveEvent(self, addEntityFunc)
            group.Ev_OnEntityRemoved:AddEvent(self, addEntityFunc)
        else
            error("invalid groupEvent")
        end
    end
end

function Collector:Deactivate()
    local groups = self._groups
    for i = 1, #groups do
        local group = groups[i]
        local addEntityFunc = self.addEntity
        group.Ev_OnEntityAdded:RemoveEvent(self, addEntityFunc)
        group.Ev_OnEntityRemoved:RemoveEvent(self, addEntityFunc)
    end
    self:ClearCollectedEntities()
end

function Collector:ClearCollectedEntities()
    for _,v in ipairs(self.collectedEntities) do
        v:Release(self)
    end
    self.collectedEntities={}
end

function Collector:insertCollectedEntities(entity)
    local e_index = entity:GetCreationIndex()
    for i,v in ipairs(self.collectedEntities) do
        if(v:GetCreationIndex() == e_index) then
            return false
        end
        --保持按 entity index 有序
        if(v:GetCreationIndex() > e_index) then
            table.insert(self.collectedEntities, i, entity)
            return true
        end
    end
    table.insert(self.collectedEntities, entity)
    return true;
end

function Collector:addEntity(group, entity, index, component)
    self:insertCollectedEntities(entity)
    if entity.Retain then
        entity:Retain(self)
    end
end

function Collector:ToString()
end
