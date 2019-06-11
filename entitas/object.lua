_G.Classes = {}

function _class(child, base, ...)
    if (Classes[child]) then
        error("duplicate class : " .. child)
    end
    local c = _G[child]
    assert(not c, child)
    c = {}
    _G[child] = c
    --table.append(c, base or {})
    if base then
        setmetatable(c, base)
    end
    if not c then
        Log.sys(child, debug.traceback())
    end
    c.__index = c
    c._className = child
    c.super = base

    c.New = function(self, ...)
        local instance = {}
        setmetatable(instance, c)
        instance._className = c._className
        do
            local create
            create = function(c, ...)
                if c.super then
                    create(c.super, ...)
                end
                if c.Constructor and (not c.super or c.super.Constructor ~= c.Constructor) then
                    c.Constructor(instance, ...)
                end
            end
            create(c, ...)
        end
        return instance
    end
    c.Dispose = function(...)
        do
            local dispose
            dispose = function(c, ...)
                if c.super then
                    dispose(c.super, ...)
                end
                if c.Destructor and (not c.super or c.super.Destructor ~= c.Destructor) then
                    c.Destructor(...)
                end
            end
            dispose(c, ...)
        end
    end
    ---获取实例的类型
    c.GetType = function(self)
        return getmetatable(self)
    end
    ---当前类型是否是child的父类
    ---@param self any 子类型
    c.IsBaseOf = function(self, child)
        local base = self
        repeat
            child = getmetatable(child)
            if child == base then
                return true
            end
        until child == nil
        return false
    end
    ---类型转换
    ---用法：local ta = ClassA(t)
    ---@param self any 类型
    c.__call = function(self, t)
        local typeT = t
        repeat
            typeT = getmetatable(typeT)
            if typeT == self then
                return t
            end
        until typeT == nil
        return nil
    end
    ---t是否是类型self的实例
    ---@param self any 类型
    c.IsInstanceOfType = function(self, t)
        return getmetatable(t) == self
    end

    Classes[child] = c
    if base and (base == RequestMessage or base == ReplyMessage or base == ServerPushMessage or base == InGameMessage) then
        local cname = "CLSID_" .. child
        c.clsid = MessageDef[cname]
        if c.clsid == nil or c.clsid == 0 then
            Log.fatal("can not find " .. cname .. " in MessageDef")
            return
        end
        NetMessageFactory:GetInstance():RegisterMessage(c, base)
    end
end

---@class Object
---@field New any
_class("Object", nil)

function Object:ToObject(obj)
    setmetatable(obj, self)
    return obj
end

function _enum(name, t)
    rawset(_G, name, t)
end

function _autoEnum(name, array)
    local t = {}
    for k, v in ipairs(array) do
        t[v] = k
    end
    rawset(_G, name, t)
end

function GetEnumKey(name, v)
    local nName = name .. "Rev"
    if not _G[nName] then
        rawset(_G, nName, table.reverse(_G[name]))
    end
    return _G[nName][v]
end

-- 静态类
-- 静态部分单独一个静态类，就是一个普通的表，没有New，没有构造函数，不能继承
function _staticClass(name)
    local t = {}
    rawset(_G, name, t)
    return t
end

---根据类名创建类的实例
---@param className string
---@return 对应类的实例对象
function CreateInstance(className)
    local class = _G[className]
    if class then
        return class:New()
    end
    return nil
end

function is_base_of(child, base)
end

---@generic T
---@param type T
---@param t any
---@return T
function dynamic_cast(type, t)
    if getmetatable(t) == type then
        return t
    else
        Log.error("dynamic_cast failed! :")
        return nil
    end
end
