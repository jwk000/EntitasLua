# EntitasLua
entitas lua version
## Context

创建Context

Context:New('Game') 可以创建一个名字为Game的context

创建GameContext的同时也会创建 GameEntity 和 GameMatcher

由于MakeComponent()函数对entity和matcher做了很多扩展，所以这里创建新的entity和matcher原型减少组件污染。


## Component

创建Component

context:MakeComponent('componentName', options) 

创建一个组件，并注册到context中。一个组件是不能同时出现在两个context里的。

options是一个talbe，有如下可选字段：

flag=true 标记此component是个flag，可以通过entity的IsXXX()判断flag状态，并用IsXXX(true/false)设置flag状态。

unique=true 标记此component是unique组件，可以通过context:UniqueEntity()访问。注意uniqueEntity没有Add Remove组件的功能。

entityindex=key 标记此component的key字段需要建立索引，可通过context:GetEntitiesByComponentKey(value)查询索引的entity集合

primaryindex=key 标记此component的key字段建立唯一索引，可通过context:GetEntityByComponentKey(value)查询entity



注意，组件实际上分为data component/ flag component /unique component/ uniqueflag component 4种情况。

如果options里没有unique和flag选项，组件就是data component，MakeComponent('xxx')会自动给entity添加以下方法：

Addxxx(data) 添加组件，组件的真实数据在这里用一个table传入

Removexxx() 删除组件

Replacexxx(data)替换组件数据

Hasxxx()查询组件

xxx() 获得组件

如果options里设置了flag=true，组件就是flag component，MakeComponent('xxx')自动给entity添加一个方法：

Isxxx() 判断flag状态

Isxxx(true/false) 设置flag状态

如果options里设置unique=true，组件就是unique component， MakeComponent('xxx')自动给context._uniqueEntity添加方法：

xxx() 获得组件

Replacexxx(data)替换组件数据

如果options里设置flag=true并且unique=true，组件就是uniqueflag component，MakeComponent('xxx')自动给context._uniqueEntity添加方法：

Isxxx()

Isxxx(true/false)



## Matcher

创建Matcher：

Matcher:New(allof, anyof, noneof)

创建comA组件也会给GameMatcher添加对象：

GameMatcher.comA

等价于

GameMatcher:New({ctx.comA}) 



## Group

创建Group

context:GetGroup(matcher)



## Collector

创建collector

Collector:New({group1, group2},{"Added","Removed"})

创建collector，关注group1的added事件或group2的removed事件

还可以通过context创建：

Context:CreateCollector(Matcher.Role:Added(), Matcher.Position:Removed())

创建collector，收集role的added事件或position的removed事件



## EntityIndex PrimaryEntityIndex

创建index

通过MakeComponent()函数的options指定key即可创建Index


