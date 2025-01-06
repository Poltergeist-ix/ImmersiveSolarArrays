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

        if result ~= nil then
            ISA.PBSystem_Server:onTransferItem(self, character, item, srcContainer, destContainer, dropSquare)
        end

        return result
    end
end

ISA.queueFunction("OnTick", function (tick)
    for _, patch in pairs(ISA.Patches) do
        patch()
    end
    ISA.Patches = nil
end)
