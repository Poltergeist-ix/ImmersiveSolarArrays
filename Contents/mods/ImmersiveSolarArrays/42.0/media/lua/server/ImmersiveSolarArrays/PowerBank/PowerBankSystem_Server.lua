--[[
    "isa_powerbank" server system
--]]

if isClient() then return end

require "Map/SGlobalObjectSystem"
local ISA = require "ImmersiveSolarArrays/Utilities"
local Powerbank = require "ImmersiveSolarArrays/PowerBank/PowerBankObject_server"

---@class PowerbankSystem_Server : PowerbankSystem, SGlobalObjectSystem
---@field instance PowerbankSystem_Server
local PBSystem = require("ImmersiveSolarArrays/PowerBankSystem_Shared"):new(SGlobalObjectSystem:derive("ISA_PowerBankSystem_Server"))

--called when making the instance, triggered by: Events.OnSGlobalObjectSystemInit
function PBSystem:new()
    return SGlobalObjectSystem.new(self, "isa_powerbank")
end

--called in SGlobalObjectSystem:new(name)
PBSystem.savedObjectModData = { 'on', 'batteries', 'charge', 'maxcapacity', 'drain', 'npanels', 'panels', "lastHour", "conGenerator"}
function PBSystem:initSystem()
    -- set the instance for easy access
    ISA.PBSystem_Server = self

    --SGlobalObjectSystem.initSystem(self) --does nothing
    --set saved fields
    self.system:setObjectModDataKeys(self.savedObjectModData)

    --sandbox options, *Events.Event.Add() doesn't need to be specifically inside a function call
    self.updateEveryTenMinutes = SandboxVars.ISA.ChargeFreq == 1 and true
    if self.updateEveryTenMinutes then
        Events.EveryTenMinutes.Add(PBSystem.updatePowerbanks)
    else
        Events.EveryHours.Add(PBSystem.updatePowerbanks)
    end
    Events.EveryDays.Add(PBSystem.EveryDays)
end

---Create / Load a lua object from java object
function PBSystem:newLuaObject(globalObject)
    return Powerbank:new(self, globalObject)
end

---triggered by: Events.OnObjectAdded (SGlobalObjectSystem)
---@param isoObject IsoObject
function PBSystem:OnObjectAdded(isoObject)
    local isaType = ISA.WorldUtil.getType(isoObject)
    if not isaType then
        return
    elseif isaType == "PowerBank" then
        if not instanceof(isoObject, "IsoGenerator") then
            isoObject = ISA.WorldUtil.replaceIsoObjectWithGenerator(isoObject)
        end
        if self:isValidIsoObject(isoObject) then
            self:loadIsoObject(isoObject)
        end
    elseif isaType == "Panel" then
        local modData = isoObject:getModData()
        modData.pbLinked = nil
        modData.connectDelta = nil
        isoObject:transmitModData()
    end
end

---triggered by: Events.OnObjectAboutToBeRemoved, Events.OnDestroyIsoThumpable  (SGlobalObjectSystem)
---v41.78 object data has already been copied to InventoryItem on pickup
function PBSystem:OnObjectAboutToBeRemoved(isoObject)
    local isaType = ISA.WorldUtil.getType(isoObject)
    if not isaType then
        return
    elseif self:isValidIsoObject(isoObject) then
        local luaObject = self:getLuaObjectOnSquare(isoObject:getSquare())
        if not luaObject then return end
        self:removeLuaObject(luaObject)
        -- self.processRemoveObj:addItem(isoObject)
    elseif isaType == "Panel" then
        self:removePanel(isoObject)
    end
end

function PBSystem:OnClientCommand(command, playerObj, args)
    local fn = self.Commands[command]
    if fn ~= nil then
        fn(playerObj, args)
    end
end

---called when object is about to be removed
function PBSystem:removePanel(panel)
    local pbData = panel:getModData().pbLinked
    if pbData == nil then return end
    local pb = self:getLuaObjectAt(pbData.x, pbData.y, pbData.z)
    pbData.pbLinked = nil
    panel:transmitModData()
    if pb == nil then return end
    local x = panel:getX()
    local y = panel:getY()
    local z = panel:getZ()
    for i = #pb.panels, 1, -1 do
        local _panel = pb.panels[i]
        if _panel.x == x and _panel.y == y and _panel.z == z then
            table.remove(pb.panels, i)
            pb.npanels = pb.npanels - 1
            break
        end
    end
    pb:saveData(true)
end

do
    local o = ISA.delayedProcess:new{maxTimes=999}

    function o.process(tick)
        if not o.data then o:stop() return end

        for i = #o.data, 1, -1 do
            if o.data[i].obj:getObjectIndex() == -1 then
                local square = o.data[i].sq
                local generator = square and square:getGenerator()
                if generator then
                    generator:setActivated(false)
                    generator:remove()
                end
                table.remove(o.data,i)
            end
        end

        if o.data[1] == nil or o.times <= 1 then o:stop() return end
        o.times = o.times - 1
    end

    function o:addItem(isoObject)
        if not self.data then
            self.data = {}
            self.event.Add(self.process)
        end
        self.times = self.maxTimes
        table.insert(self.data, { obj = isoObject, sq = isoObject:getSquare() })
    end

    PBSystem.processRemoveObj = o
end

---@param character IsoPlayer
---@param generator IsoGenerator
function PBSystem:onPlugGenerator(character, generator)
    local area = ISA.WorldUtil.getValidBackupArea(character:getPerkLevel(Perks.Electricity))
    local luaPowerbanks = ISA.WorldUtil.getPowerBanksInArea(generator:getSquare(), area.radius, area.levels, area.distance)
    if luaPowerbanks[1] == nil then return end
    local x, y, z = generator:getX(), generator:getY(), generator:getZ()
    for i = 1, #luaPowerbanks do
        local pb = luaPowerbanks[i]
        local connect = true
        if pb.conGenerator and IsoUtils.DistanceToSquared(pb.x,pb.y,pb.z,pb.conGenerator.x,pb.conGenerator.y,pb.conGenerator.z)
                                <= IsoUtils.DistanceToSquared(pb.x,pb.y,pb.z,x,y,z) then
            connect = false
        end
        if connect then
            pb:connectBackupGenerator(generator)
        end
    end
end

---@param character IsoPlayer
---@param generator IsoGenerator
function PBSystem:onUnPlugGenerator(character, generator)
    local x, y ,z = generator:getX(), generator:getY(), generator:getZ()
    for i = 0, self.system:getObjectCount() - 1 do
        local pb = self.system:getObjectByIndex(i):getModData()
        if pb.conGenerator and pb.conGenerator.x == x and pb.conGenerator.y == y and pb.conGenerator.z == z then
            pb:disconnectBackupGenerator(generator)
        end
    end
end

---@param character IsoPlayer
---@param generator IsoGenerator
---@param activate boolean
function PBSystem:onActivateGenerator(character, generator, activate)
    local x, y, z = generator:getX(), generator:getY(), generator:getZ()
    for i = 1, self:getLuaObjectCount() do
        local pb = self:getLuaObjectByIndex(i)
        if pb.conGenerator and pb.conGenerator.x == x and pb.conGenerator.y == y and pb.conGenerator.z == z then
            pb.conGenerator.ison = activate
        end
    end
end

function PBSystem:onTransferItem(action, character, item, srcContainer, destContainer, dropSquare)
    local maxCapacity = item:getModData().ISA_maxCapacity
    if not maxCapacity then return end

    local src = srcContainer:getParent()
    local dst = destContainer:getParent()
    local remove = src ~= nil and ISA.WorldUtil.objectIsType(src, "PowerBank")
    local add = dst ~= nil and ISA.WorldUtil.objectIsType(dst, "PowerBank")
    if not remove or not add then return end

    local capacity = maxCapacity * (1 - math.pow((1 - (item:getCondition()/100)),6))
    local charge = capacity * item:getCurrentUsesFloat()
    if remove then
        local pb = self:getLuaObjectAt(src:getX(), src:getY(), src:getZ())
        pb.batteries = pb.batteries - 1
        if pb.batteries > 0 then
            pb.charge = pb.charge - charge
            pb.maxcapacity = pb.maxcapacity - capacity
        else
            pb.charge = 0
            pb.maxcapacity = 0
        end
        pb:updateGenerator()
        pb:updateSprite()
        pb:saveData(true)
    end
    if add then
        local pb = self:getLuaObjectAt(dst:getX(), dst:getY(), dst:getZ())
        pb.batteries = pb.batteries + 1
        pb.charge = pb.charge + charge
        pb.maxcapacity = pb.maxcapacity + capacity
        pb:updateGenerator()
        pb:updateSprite()
        pb:saveData(true)
    end

end

function PBSystem.EveryDays()
    local self = PBSystem.instance
    for i = 0, self.system:getObjectCount() - 1 do
        ---@type PowerBankObject_Server
        local pb = self.system:getObjectByIndex(i):getModData()
        local isopb = pb:getIsoObject()
        if isopb then
            local inv = isopb:getContainer()
            pb:degradeBatteries(inv) ---TODO x days passed
            pb:calculateBatteryStats(inv)
            isopb:sendObjectChange("containers")
        end
        pb:checkPanels()
    end
end

function PBSystem.updatePowerbanks()
    local self = PBSystem.instance
    local solaroutput = self:getModifiedSolarOutput(1)
    for i = 0, self.system:getObjectCount() - 1 do
        ---@type PowerBankObject_Server
        local pb = self.system:getObjectByIndex(i):getModData()
        local isopb = pb:getIsoObject()
        local drain = 0
        if pb:shouldDrain(isopb) then
            pb:updateDrain()
            drain = pb.drain
        end

        local dCharge = solaroutput * pb.npanels - drain
        if self.updateEveryTenMinutes then dCharge = dCharge / 6 end
        local charge = pb.charge + dCharge
        if charge < 0 then charge = 0 elseif charge > pb.maxcapacity then charge = pb.maxcapacity end
        local modCharge = pb.maxcapacity > 0 and charge / pb.maxcapacity or 0
        pb.charge = charge
        if isopb then
            pb:updateBatteries(isopb:getContainer(), modCharge)
            pb:updateGenerator(dCharge)
            pb:updateSprite(modCharge)
        end
        pb:updateConGenerator()
        pb:saveData(true)

        if self.wantNoise then self:noise(string.format("/charge: (%d) Battery at: %d %%, charge dif: %.1f, output: %.1f, drain: %.1f",i,modCharge*100,dCharge,pb.npanels*solaroutput,drain)) end
    end
end

SGlobalObjectSystem.RegisterSystemClass(PBSystem)

return PBSystem
