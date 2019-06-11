_class("AbstractEntityIndex")

---@param name 索引名称
---@param group 索引监听的组
---@param getkey 获取entity的key或keys
---@param ismultikey 指定true则getkey返回多个key
---
function AbstractEntityIndex:Constructor(name, group, getkey, ismultikey)
    self.name = name
    self.group = group
    self.getkey = getkey
    self.ismultikey = ismultikey
end

function AbstractEntityIndex:Destructor()
    self:deactivate()
end

function AbstractEntityIndex:activate()
    self.group.Ev_OnEntityAdded:AddEvent(self,self.onEntityAdded)
    self.group.Ev_OnEntityRemoved:AddEvent(self,self.onEntityRemoved)
end

function AbstractEntityIndex:deactivate()
    self.group.Ev_OnEntityAdded:RemoveEvent(self,self.onEntityAdded)
    self.group.Ev_OnEntityRemoved:RemoveEvent(self,self.onEntityRemoved)
    self:clear()
end

function AbstractEntityIndex:indexEntities(group)
    for e, _ in pairs(group._entities) do
        if not self.ismultikey then
            self:addEntity(self.getkey(e), e)
        else
            local keys = self.getkey(e)
            for _, k in pairs(keys) do
                self:addEntity(k, e)
            end
        end
    end
end

function AbstractEntityIndex:onEntityAdded(group, entity, index, component)
    if not self.ismultikey then
        self:addEntity(self.getkey(entity, component), entity)
    else
        local keys = self.getkey(entity, component)
        for _, k in pairs(keys) do
            self:addEntity(k, entity)
        end
    end
end

function AbstractEntityIndex:onEntityRemoved(group, entity, index, component)
    if not self.ismultikey then
        self:removeEntity(self.getkey(entity, component), entity)
    else
        local keys = self.getkey(entity, component)
        for _, k in pairs(keys) do
            self:removeEntity(k, entity)
        end
    end
end

function AbstractEntityIndex:addEntity(key, entity)
    error("AbstractEntityIndex:addEntity not implemented")
end

function AbstractEntityIndex:removeEntity(key, entity)
    error("AbstractEntityIndex:removeEntity not implemented")
end

function AbstractEntityIndex:clear()
    error("AbstractEntityIndex:clear not implemented")
end

_class("EntityIndex", AbstractEntityIndex)

function EntityIndex:Constructor(name, group, getkey)
    self.indexes = {}
    self:Activate()
end

function EntityIndex:Activate()
    self:activate()
    self:indexEntities(self.group)
end

function EntityIndex:GetEntities(key)
    local entities = self.indexes[key]
    if not entities then
        entities = {}
        self.indexes[key] = entities
    end
    return entities
end

function EntityIndex:addEntity(key, entity)
    local entities = self:GetEntities(key)
    entities[entity] = true
    entity:Retain(self)
end

function EntityIndex:removeEntity(key, entity)
    local entities = self:GetEntities(key)
    entities[entity] = nil
    entity:Release(self)
end

function EntityIndex:clear()
    for _, v in pairs(self.indexes) do
        for e, _ in pairs(v) do
            e:Release(self)
        end
    end
    self.indexes = nil
end

_class("PrimaryEntityIndex", AbstractEntityIndex)

function PrimaryEntityIndex:Constructor()
    self.index = {}
    self:Activate()
end

function PrimaryEntityIndex:Activate()
    self:activate()
    self:indexEntities(self.group)
end

function PrimaryEntityIndex:GetEntity(key)
    return self.index[key]
end

function PrimaryEntityIndex:clear()
    for e, _ in pairs(self.index) do
        e:Release(self)
    end
end

function PrimaryEntityIndex:addEntity(key, entity)
    if self.index[key] then
        error("entity for key" .. key .. "already exists!")
        return
    end

    self.index[key] = entity
    entity:Retain(self)
end

function PrimaryEntityIndex:removeEntity(key, entity)
    self.index[key] = nil
    entity:Release(self)
end
