---@class DelegateEvent
DelegateEvent = {}

function DelegateEvent:New()
    local event = {}
    setmetatable(event, self)
    self.__index = self
    self.__call = self.Call
    event._callees = {}
    return event
end

function DelegateEvent:AddEvent(obj, func)
    table.insert(self._callees, {obj, func})
end

function DelegateEvent:RemoveEvent(obj, func)
    for i,v in ipairs(self._callees) do
        if(v[1]==obj and v[2]==func) then 
            table.remove(self._callees,i) 
            return true;
        end
    end
    return false
end

function DelegateEvent:Clear()
    self._callees = {}
end

--当event被触发调用时, 按序执行响应方法
function DelegateEvent:Call(...)
    for _, t in ipairs(self._callees) do
        t[2](t[1], ...)
    end
end
