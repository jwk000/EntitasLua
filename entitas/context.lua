---@class Context:Object
_class("Context", Object)

function Context:Constructor(ctxname)
    _class(ctxname .. "Entity", Entity)
    _class(ctxname .. "Matcher", Matcher)
    local ctxEntity = _G[ctxname .. "Entity"]
    local ctxMatcher = _G[ctxname .. "Matcher"]

    self._entityCreationIndex = 0
    self._componentIndex = 0
    self._entityProto = ctxEntity
    self._matcher = ctxMatcher

    --entity数组，按entity index有序
    self._entities = {}
    --key: Matcher, value: group
    self._groups = {}
    --key: component index value:group
    self._groupsForIndex = {}
    --key:name value:entityindex
    self._entityIndices = {}
    --unique entity
    self._uniqueEntity = self:CreateEntity()

    self.Ev_OnEntityCreated = DelegateEvent:New()
    self.Ev_OnEntityWillBeDestroyed = DelegateEvent:New()
    self.Ev_OnEntityDestroyed = DelegateEvent:New()
    self.Ev_OnGroupCreated = DelegateEvent:New()
    self.Ev_OnGroupCleared = DelegateEvent:New()
end

function Context:Destructor()
    self.Ev_OnEntityCreated:Clear()
    self.Ev_OnEntityWillBeDestroyed:Clear()
    self.Ev_OnEntityDestroyed:Clear()
    self.Ev_OnGroupCreated:Clear()
    self.Ev_OnGroupCleared:Clear()
end

function Context:TotalComponents()
    return self._componentIndex
end

function Context:UniqueEntity()
    return self._uniqueEntity
end

function Context:insertEntity(entity)
    local e_index = entity:GetCreationIndex()
    for i, e in ipairs(self._entities) do
        local _idx = e:GetCreationIndex()
        if (_idx == e_index) then
            return false
        end
        if _idx > e_index then
            table.insert(self._entities, i, entity)
            return true
        end
    end
    table.insert(self._entities, entity)
    return true
end

function Context:removeEntity(entity)
    local e_index = entity:GetCreationIndex()
    for i, e in ipairs(self._entities) do
        if (e:GetEntityIndex() == e_index) then
            table.remove(self._entities, i)
            return true
        end
    end
    return false
end

---@return Entity
function Context:CreateEntity()
    local entity = self._entityProto:New()

    local creationIndex = self._entityCreationIndex
    self._entityCreationIndex = creationIndex + 1
    entity:Initialize(creationIndex)

    self:insertEntity(entity)

    entity:Retain(self)
    entity.Ev_OnComponentAdded:AddEvent(self, self.updateGroupsComponentAddedOrRemoved)
    entity.Ev_OnComponentRemoved:AddEvent(self, self.updateGroupsComponentAddedOrRemoved)
    entity.Ev_OnComponentReplaced:AddEvent(self, self.updateGroupsComponentReplaced)
    entity.Ev_OnEntityReleased:AddEvent(self, self.onEntityReleased)

    if self.Ev_OnEntityCreated then
        self.Ev_OnEntityCreated(self, entity)
    end

    return entity
end

--Destroys the entity, removes all its components
---@param entity Entity
function Context:DestroyEntity(entity)
    self._entities:Remove(entity:GetCreationIndex())

    if self.Ev_OnEntityWillBeDestroyed ~= nil then
        self.Ev_OnEntityWillBeDestroyed(self, entity)
    end

    entity:Destroy()

    if self.Ev_OnEntityDestroyed ~= nil then
        self.Ev_OnEntityDestroyed(self, entity)
    end

    if entity._retainCount == 1 then
        entity.Ev_OnEntityReleased:RemoveEvent(self, self.onEntityReleased)
        entity:Release(self)
        entity:RemoveAllOnEntityReleasedHandlers()
    else
        entity:Release(self)
    end
end

---@param matcher Matcher
---@return Group
function Context:GetGroup(matcher)
    local group = self._groups[matcher]
    if not group then
        group = Group:New(matcher)
        --group:Constructor(matcher)

        for i, e in ipairs(self._entities) do
            group:HandleEntitySilently(e)
        end

        self._groups[matcher] = group

        local indices = matcher.indices
        for index, _ in pairs(indices) do
            if not self._groupsForIndex[index] then
                self._groupsForIndex[index] = {}
            end
            table.insert(self._groupsForIndex[index], group)
        end

        if self.Ev_OnGroupCreated then
            self.Ev_OnGroupCreated(self, group)
        end
    end

    return group
end

function Context:updateGroupsComponentAddedOrRemoved(entity, index, component)
    local groups = self._groupsForIndex[index]
    if groups then
        --后面Cache一下？
        local events = {}
        --收集Component变化后，受影响相关Group的Event
        for i, g in ipairs(groups) do
            events[#events + 1] = g:HandleEntity(entity)
        end

        --Event通知
        for i = 1, #events do
            local groupChangedEvent = events[i]
            if groupChangedEvent then
                groupChangedEvent(groups[i], entity, index, component)
            end
        end
    end
end

function Context:updateGroupsComponentReplaced(entity, index, previousComponent, newComponent)
    local groups = self._groupsForIndex[index]
    if groups then
        for i, g in ipairs(groups) do
            g:UpdateEntity(entity, index, previousComponent, newComponent)
        end
    end
end

function Context:onEntityReleased(entity)
    entity.RemoveAllOnEntityReleasedHandlers()

    --回收销毁entity
    self:Dispose()
end

function Context:AddEntityIndex(entityIndex)
    if self._entityIndices[entityIndex.name] then
        error("Context already has entity index " .. entityIndex.name)
        return
    end

    self._entityIndices[entityIndex.name] = entityIndex
end

function Context:GetEntityIndex(name)
    local idx = self._entityIndices[name]
    if not idx then
        error("entity index " .. name .. " does not exist")
    end
    return idx
end

function Context:ExtendMatcher(name)
    local t = self[name]
    local m = self._matcher
    m[name] = m:New({t}) 
end

function Context:ExtendDataComponent(name)
    local t = self[name]
    local e = self._entityProto

    --拓展matcher
    self:ExtendMatcher(name)

    e[name] = function(entity)
        return entity:GetComponent(t._index)
    end
    e["Has" .. name] = function(entity)
        return entity:HasComponent(t._index)
    end
    e["Add" .. name] = function(entity, component)
        return entity:ReplaceComponent(t._index, component)
    end
    e["Replace" .. name] = function(entity, component)
        return entity:ReplaceComponent(t._index, component)
    end
    e["Remove" .. name] = function(entity)
        return entity:RemoveComponent(t._index)
    end
end

function Context:ExtendFlagComponent(name)
    local t = self[name]
    local e = self._entityProto

    --拓展matcher
    self:ExtendMatcher(name)

    e["Is" .. name] = function(entity, flag)
        if flag == nil then
            return entity:GetComponent(t._index) ~= nil
        else
            if flag == false then
                entity:RemoveComponent(t._index)
            else
                entity:ReplaceComponent(t._index, {})
            end
        end
    end
end

function Context:ExtendUniqueComponent(name)
    local c = self[name]
    local e = self._uniqueEntity
   
    if e:HasComponent(c._index) then
        error('unique component '..name ..'already exsited')
        return
    end

     --拓展matcher
    self:ExtendMatcher(name)

    e:AddComponent(c._index,{})
    --为了保持调用方式一致，保留entity参数
    e[name] = function(entity)
        return entity:GetComponent(c._index)
    end
    e["Replace" .. name] = function(entity, component)
        return entity:ReplaceComponent(c._index, component)
    end

end

function Context:ExtendUniqueFlagComponent(name)
    local c = self[name]
    local e = self._uniqueEntity
   
    if e:HasComponent(c._index) then
        error('unique component '..name ..'already exsited')
        return
    end
    --拓展matcher
    self:ExtendMatcher(name)

    e["Is" .. name] = function(entity,flag)
        if flag == nil then
            return entity:GetComponent(c._index) ~= nil
        else
            if flag == false then
                entity:RemoveComponent(c._index)
            else
                entity:ReplaceComponent(c._index, {})
            end
        end
    end
end

function Context:ExtendPrimaryIndex(name, key)
    local ei =
        PrimaryEntityIndex:New(
        name .. key,
        self:GetGroup(self._matcher[name]),
        function(e, c)
            return c[key]
        end
    )
    self:AddEntityIndex(ei)

    self["GetEntityBy" .. key] = function(self, value)
        return self:GetEntityIndex(name .. key):GetEntity(value)
    end
end

function Context:ExtendEntityIndex(name, key)
    local ei =
        EntityIndex:New(
        name .. key,
        self:GetGroup(self._matcher[name]),
        function(e, c)
            return c[key]
        end
    )
    self:AddEntityIndex(ei)

    self["GetEntitiesBy" .. key] = function(self, value)
        return self:GetEntityIndex(name .. key):GetEntities(value)
    end
end

---@param name 组件名称
---@param options 选项 flag=true，unique=true，entityindex=key, primaryindex=key
function Context:MakeComponent(name, options)
    self._componentIndex = self._componentIndex + 1
    local t = {}
    t._name = name
    t._index = self._componentIndex
    self[name] = t

    --拓展entity
    if options and options.flag and options.unique then
        self:ExtendUniqueFlagComponent(name)
    end
    --拓展entity
    if options and options.flag and not options.unique then
        self:ExtendFlagComponent(name)
    end
    --拓展context
    if options and options.unique and not options.flag then
        self:ExtendUniqueComponent(name)
    end
    --拓展entity
    if not options or (not options.flag and not options.unique) then
        self:ExtendDataComponent(name)
    end
    --唯一索引
    if options and options.primaryindex then
        self:ExtendPrimaryIndex(name, options.primaryindex)
    end

    --索引
    if options and options.entityindex then
        self:ExtendEntityIndex(name, options.entityindex)
    end
end
