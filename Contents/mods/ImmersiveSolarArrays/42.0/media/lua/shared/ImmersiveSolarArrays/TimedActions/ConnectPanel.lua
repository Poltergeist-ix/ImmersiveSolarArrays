require "TimedActions/ISBaseTimedAction"
---@class ImmersiveSolarArrays
local ISA = require "ImmersiveSolarArrays/Utilities"

local ConnectPanel = ISBaseTimedAction:derive("ISA_ConnectPanel")

function ConnectPanel:new(character, panel, luaPb)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.panel = panel
    ---FIXME client powerbank
    o.powerbank = luaPb
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = false
    o.maxTime = o:getDuration()
    return o
end

function ConnectPanel:isValid()
    return self.panel:getObjectIndex() ~= -1
end

function ConnectPanel:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    --base time in minutes at level 3, ~1/3 at level 10
    return SandboxVars.ISA.ConnectPanelMin * (1 - 0.095 * (self.character:getPerkLevel(Perks.Electricity) - 3)) * 2 * getGameTime():getMinutesPerDay()
end

function ConnectPanel:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
    self.sound = self.character:playSound("GeneratorConnect")

    local data = self.panel:getModData()
    local prevDelta = data["connectDelta"]
    if not prevDelta then prevDelta = 0 elseif prevDelta > 90 then prevDelta = 90 end
    self:setCurrentTime(self.maxTime * prevDelta / 100)
    if not isClient() then
        data["connectDelta"] = prevDelta
        ISA.PBSystem_Server:removePanel(self.panel)
        self.panel:transmitModData()
    end
end

function ConnectPanel:waitToStart()
    self.character:faceThisObject(self.panel)
    return self.character:shouldBeTurning()
end

function ConnectPanel:update()
    ---TODO add weird texts: oof, why is this taking so long, if I was a better electricial this wouldn't take so long, 
    self.character:faceThisObject(self.panel)
end

function ConnectPanel:stop()
    self.character:stopOrTriggerSound(self.sound)
    local delta = math.floor(self:getJobDelta()*100)
    local data = self.panel:getModData()
    if delta > data.connectDelta and self.panel:getObjectIndex() ~= -1 then
        data.connectDelta = delta
        if isServer() then
            self.panel:transmitModData()
        end
    end

    ISBaseTimedAction.stop(self)
end

function ConnectPanel:perform()
    self.character:stopOrTriggerSound(self.sound)

    ISBaseTimedAction.perform(self)
end

function ConnectPanel:complete()
    local data = self.panel:getModData()
    data.connectDelta = 100
    local pb = ISA.PBSystem_Server:getLuaObjectAt(self.powerbank.x, self.powerbank.y, self.powerbank.z)
    local panel, status = pb:getPanelStatusOnSquare(self.panel:getSquare())
    if status == "not connected" then
        data.pbLinked = { x = pb.x , y = pb.y, z = pb.z }
        table.insert(pb.panels,{x = self.panel:getX(), y = self.panel:getY(), z = self.panel:getZ()})
        pb.npanels = pb.npanels + 1
        pb:saveData(true)
    end
    self.panel:transmitModData()
end

ISA.ConnectPanel = ConnectPanel
