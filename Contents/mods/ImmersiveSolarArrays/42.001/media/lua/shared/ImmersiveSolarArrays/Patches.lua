---@class ImmersiveSolarArrays
local ISA = require "ImmersiveSolarArrays/Utilities"
require "UI/ISAUI"
local PbSystem = require "ImmersiveSolarArrays/Powerbank/PowerBankSystem_Client"

ISA.Patches = {}

ISA.Patches["ISPlugGenerator.complete"] = function ()
    local original = ISPlugGenerator.complete
    ISPlugGenerator.complete = function (self)
        local r = original(self)

        if self.plug then
            ISA.PBSystem_Server:onPlugGenerator(self.character, self.generator)
        else
            ISA.PBSystem_Server:onUnPlugGenerator(self.character, self.generator)
        end

        return r
    end
end

ISA.Patches["ISActivateGenerator.complete"] = function ()
    local original = ISActivateGenerator.complete
    ISActivateGenerator.complete = function (self)
        local result = original(self)

        --check action was successful
        if result and self.activate == self.generator:isActivated() then 
            ISA.PBSystem_Server:onActivateGenerator(self.character, self.generator, self.activate)
        end

        return result
    end
end

ISA.Patches["ISTransferAction.transferItem"] = function ()
    local original = ISTransferAction.transferItem
    ISTransferAction.transferItem = function (self, character, item, srcContainer, destContainer, dropSquare)
        local result = original(self, character, item, srcContainer, destContainer, dropSquare)

        local maxCapacity = item:getModData().ISA_maxCapacity
        if maxCapacity then
            local src = srcContainer:getParent()
            local dest = destContainer:getParent()
            local take = src and ISA.WorldUtil.objectIsType(src, "Powerbank")
            local put = dest and ISA.WorldUtil.objectIsType(dest, "Powerbank")
            if take or put then

                local capacity = maxCapacity * (1 - math.pow((1 - (item:getCondition()/100)),6))
                local charge = capacity * item:getCurrentUsesFloat()
                if take then
                    local pb = ISA.PBSystem_Server:getLuaObjectOnSquare(src:getSquare())
                    pb.batteries = pb.batteries - 1
                    if pb.batteries > 0 then
                        pb.charge = pb.charge - charge
                        pb.maxcapacity = pb.maxcapacity - capacity
                    else
                        pb.charge = 0
                        pb.maxcapacity = 0
                    end
                end
                if put then
                    local pb = ISA.PBSystem_Server:getLuaObjectOnSquare(dest:getSquare())
                    pb.batteries = pb.batteries + 1
                    pb.charge = pb.charge + charge
                    pb.maxcapacity = pb.maxcapacity + capacity
                end
            end
        end

        return result
    end
end

Events.OnTick.Add(function (tick)
    for _, patch in pairs(ISA.Patches) do
        patch()
    end
    ISA.Patches = nil
end)
