---@class Matcher:Object
_class("Matcher", Object)

function Matcher:Constructor(allOfIndices, anyOfIndices, noneOfIndices)
    if allOfIndices == nil then
        allOfIndices = {}
    end
    if anyOfIndices == nil then
        anyOfIndices = {}
    end
    if noneOfIndices == nil then
        noneOfIndices = {}
    end
    self.indices={}
    self._allOfIndices = {}
    self._anyOfIndices = {}
    self._noneOfIndices = {}

    for _, v in ipairs(allOfIndices) do
        self.indices[v._index] = true
        table.insert(self._allOfIndices, v._index)
    end
    for _, v in ipairs(anyOfIndices) do
        self.indices[v._index] = true
        table.insert(self._anyOfIndices, v._index)
    end
    for _, v in ipairs(noneOfIndices) do
        self.indices[v._index] = true
        table.insert(self._noneOfIndices, v._index)
    end
end

function Matcher:Destructor()
    self.indices = nil
    self._allOfIndices = nil
    self._anyOfIndices = nil
    self._noneOfIndices = nil
end

function Matcher:Matches(entity)
    local indices = self.indices
    local allOfIndices = self._allOfIndices
    local anyOfIndices = self._anyOfIndices
    local noneOfIndices = self._noneOfIndices

    return (allOfIndices == nil or entity:HasComponents(allOfIndices)) and
        (anyOfIndices == nil or #anyOfIndices == 0 or entity:HasAnyComponent(anyOfIndices)) and
        (noneOfIndices == nil or #anyOfIndices == 0 or not entity:HasAnyComponent(noneOfIndices))
end


function Matcher:Added()
    return {self,"Added"}
end

function Matcher:Removed()
    return {self, "Removed"}
end

function Matcher:AddedOrRemoved()
    return {self, "AddedOrRemoved"}
end

