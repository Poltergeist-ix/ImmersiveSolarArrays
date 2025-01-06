require "TimedActions/ISBaseTimedAction"
---@class ImmersiveSolarArrays
local ISA = require "ImmersiveSolarArrays/Utilities"

local ActivatePowerBank = ISBaseTimedAction:derive("ISA_ActivatePowerBank")

function ActivatePowerBank:new(character, powerbank, activate)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.activate = activate
    o.isoPb = powerbank
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end

function ActivatePowerBank:isValid()
    return self.isoPb:getObjectIndex() ~= -1
end

function ActivatePowerBank:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 40 - 3 * self.character:getPerkLevel(Perks.Electricity)
end

function ActivatePowerBank:complete()
    local pb = ISA.PBSystem_Server:getLuaObjectAt(self.isoPb:getX(), self.isoPb:getY(), self.isoPb:getZ())
    if self.activate then
        local level = self.character:getPerkLevel(Perks.Electricity)
        if level < 3 and ZombRand(6-2*level) ~= 0 then
            self.isoPb:getSquare():playSound("GeneratorFailedToStart")
            self.activate = false
        end
    end
    if self.activate and pb.charge > 0 then
        self.isoPb:getSquare():playSound("GeneratorStarting")
    elseif self.activate then
        self.isoPb:getSquare():playSound("GeneratorFailedToStart")
    else
        self.isoPb:getSquare():playSound("GeneratorStopping")
    end

    pb.on = self.activate
    pb.switchchanged = true
    pb:updateDrain()
    pb:updateGenerator()
    pb:saveData(true)
end

ISA.ActivatePowerbank = ActivatePowerBank
