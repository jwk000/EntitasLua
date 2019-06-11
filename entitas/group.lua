---@class Group:Object
_class("Group", Object)

function Group:Constructor(matcher)
    self.Ev_OnEntityAdded = DelegateEvent:New()
    self.Ev_OnEntityRemoved = DelegateEvent:New()
    self.Ev_OnEntityUpdated = DelegateEvent:New()

    self._matcher = matcher
    self._entities = {}
end

function Group:Destructor()
    self.Ev_OnEntityAdded = nil
    self.Ev_OnEntityRemoved = nil
    self.Ev_OnEntityUpdated = nil

    self._matcher = nil
    self._entities = nil
end

function Group:Entities()
    return self._entities
end

---@param entity Entity
function Group:UpdateEntity(entity, index, previousComponent, newComponent)
    if self._entities[entity] then
        self.Ev_OnEntityAdded(self, entity, index, newComponent)
        self.Ev_OnEntityRemoved(self, entity, index, previousComponent)
        self.Ev_OnEntityUpdated(self, entity, index, previousComponent, newComponent)
    end
end

function Group:RemoveAllEventHandlers()
    self.Ev_OnEntityAdded:Clear()
    self.Ev_OnEntityRemoved:Clear()
    self.Ev_OnEntityUpdated:Clear()
end

function Group:HandleEntity(entity)
    if self._matcher:Matches(entity) then
        local find = self._entities[entity]
        if not find then
            self._entities[entity] = true
            entity:Retain(self)
            return self.Ev_OnEntityAdded
        else
            return nil
        end
    else
        local find = self._entities[entity]
        if find then
            self._entities[entity] = nil
            entity:Release(self)
            return self.Ev_OnEntityRemoved
        else
            return nil
        end
    end
end

function Group:HandleEntitySilently(entity)
    if self._matcher:Matches(entity) then
        if not self._entities[entity] then
            self._entities[entity] = true
            entity:Retain(self)
        end
    else
        if self._entities[entity] then
            self._entities[entity] = nil
            entity:Release(self)
        end
    end
end

function Group:HandleForeach(handler, handlerFunc)
    local entities = self._entities
    for entity, flag in pairs(entities) do
        handlerFunc(handler, entity)
    end
end

function Group:GetSingleEntity()
    local entity
    local cnt = 0
    for e, _ in pairs(self._entities) do
        if cnt > 1 then
            return nil
        end
        entity = e
        cnt = cnt + 1
    end
    return entity
end
