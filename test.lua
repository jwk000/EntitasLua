require("entitas.entitas")

local test_context = function()
    --创建context
    local ctx = Context:New("Test1")
    ctx:MakeComponent("Position")
    ctx:MakeComponent("Role", {primaryindex = "ID"})
    ctx:MakeComponent("Moving", {flag = true})
    ctx:MakeComponent("RoundTurn", {unique = true})
    --唯一组件
    local turn = ctx.unique:RoundTurn()
    turn.state = 2
    ctx.unique:ReplaceRoundTurn(turn)
    assert(ctx.unique:RoundTurn().state == 2)

    --创建entity
    local e = ctx:CreateEntity()
    local mt = getmetatable(e)
    assert(mt == ctx._entityProto, "metatable not the same ----------")
    --添加组件
    e:AddPosition({x = 101, y = 200})
    print("e.Position.x = " .. e:Position().x)
    assert(e:HasPosition() == true)
    e:RemovePosition()

    --索引
    e:AddRole({ID = 123, name = "jwk"})
    assert(e:HasRole() == true, "add role failed")
    print("e.Role.name = " .. e:Role().name)

    local entity = ctx:GetEntityByID(123)
    assert(entity == e)

    --flag
    print("[nil] e.ismoving = ", e:IsMoving())
    e:IsMoving(true)
    print("[true] e.ismoving = ", e:IsMoving())
    e:IsMoving(false)
    print("[false] e.ismoving  = ", e:IsMoving())

    --group
    local g = ctx:GetGroup(Matcher:New({ctx.Role}, {ctx.Position}, {}))
    --collector
    local c1 = Collector:New({g}, {"Added"})
    -- role added or position removed
    local c2 = ctx:CreateCollector(Test1Matcher.Role:Added(), Test1Matcher.Position:Removed())
end

test_context()

---------------------------------------------------
--- 测试2 systems
---------------------------------------------------
---Time组件是全局唯一组件，负责更新每帧delta时间
---Entity具有ID Timer和Timeout组件，timer检测是否timeout
---TimeSystem 提供计时器，每帧修改delta
---TimerSystem 检查timeout
---TimeOutSystem 响应Timeout
---
_class("TimeSystem")

function TimeSystem:Constructor(context)
    self._entity = context.unique
end

function TimeSystem:Execute()
    local e = self._entity
    local time = e:Time()
    time.delta = os.clock() - time.last
    time.last = os.clock()
    e:ReplaceTime(time)
end

_class("TimerSystem")
function TimerSystem:Constructor(context)
    self._time = context.unique:Time()
    self._group = context:GetGroup(Test2Matcher.Timer)
end

function TimerSystem:Execute()
    for e, _ in pairs(self._group:Entities()) do
        local timer = e:Timer()
        timer.acc = timer.acc + self._time.delta
        if timer.acc >= timer.timeout then
            timer.acc = timer.acc - timer.timeout
            e:IsTimeout(true)
            e:ReplaceTimer(timer)
        end
    end
end

_class("TimeOutSystem", ReactiveSystem)

function TimeOutSystem:Constructor(context)
    self._collector = Collector:New({context:GetGroup(Test2Matcher.Timeout)}, {"Added"})
end

function TimeOutSystem:GetTrigger(context)
    return self._collector
end

function TimeOutSystem:Filter(e)
    return e:HasID() and e:IsTimeout()
end

function TimeOutSystem:ExecuteEntities(entities)
    for i, e in ipairs(entities) do
        print(e:ID().id, "timeout!")
        e:IsTimeout(false)
    end
end

function test_systems()
    local ctx = Context:New("Test2")
    ctx:MakeComponent("ID")
    ctx:MakeComponent("Time", {unique = true})
    ctx:MakeComponent("Timer")
    ctx:MakeComponent("Timeout", {flag = true})

    local e1 = ctx:CreateEntity()
    local e2 = ctx:CreateEntity()

    --e1:AddTimer({last = os.clock(), delta = 0})
    ctx.unique:Time().delta = 0
    ctx.unique:Time().last = os.clock()

    e1:AddID({id = 1})
    e1:AddTimer({timeout = 2, acc = 0}) --e1每2秒timeout一次

    e2:AddID({id = 2})
    e2:AddTimer({timeout = 5, acc = 0}) --e2每5秒timeout一次

    local systems = Systems:New()
    --add systems
    systems:Add(TimeSystem:New(ctx))
    systems:Add(TimerSystem:New(ctx))
    systems:Add(TimeOutSystem:New(ctx))

    systems:ActivateReactiveSystems()
    systems:Initialize()

    for i = 0, 10 do
        print("update ..........", i)
        systems:Execute()
        systems:Cleanup()
        os.execute("ping -n 2 localhost > NUL")
    end

    systems:DeactivateReactiveSystems()
    systems:TearDown()
end

test_systems()
