---@class ImmersiveSolarArrays
local ISA = require "ImmersiveSolarArrays/ISAUtilities"

local WorldUtil = {}

---@alias ISAType
---| `PowerBank`
---| `Panel`
---| `FailSafe`

WorldUtil.ISATypes = {
    solarmod_tileset_01_0 = "Powerbank",
    solarmod_tileset_01_6 = "Panel",
    solarmod_tileset_01_7 = "Panel",
    solarmod_tileset_01_8 = "Panel",
    solarmod_tileset_01_9 = "Panel",
    solarmod_tileset_01_10 = "Panel",
    solarmod_tileset_01_15 = "Failsafe",
}

---return type of solar object
---@param isoObject IsoObject
---@return ISAType
function WorldUtil.getType(isoObject)
    return WorldUtil.ISATypes[isoObject:getTextureName()]
end

function WorldUtil.objectIsType(isoObject, modType)
    return WorldUtil.ISATypes[isoObject:getTextureName()] == modType
end

function WorldUtil.getValidBackupArea(isoPlayer,level)
    local skillLevel = isoPlayer and isoPlayer:getPerkLevel(Perks.Electricity) or level or 3
    return { radius = skillLevel, levels = skillLevel > 5 and 1 or 0, distance = math.pow(skillLevel, 2) * 1.25 }
end

function WorldUtil.getLuaObjects(square,radius,level,distance)
    local banks = {}
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    for ix = x - radius, x + radius do
        for iy = y - radius, y + radius do
            for iz = z - level, z+level do
                local isquare = IsoUtils.DistanceToSquared(x,y,z,ix,iy,iz) <= distance and getSquare(ix, iy, iz)
                local pb
                if isquare then
                    if not isServer() then
                        pb = ISA.PbSystem_client:getLuaObjectOnSquare(isquare)
                    else
                        pb = ISA.PbSystem_server:getLuaObjectOnSquare(isquare)
                    end
                end
                if pb then
                    table.insert(banks,pb)
                end
            end
        end
    end
    return banks
end

function WorldUtil.findOnSquare(square,sprite)
    local special = square:getSpecialObjects()
    for i = 0, special:size()-1 do
        local obj = special:get(i)
        if obj:getTextureName() == sprite then
            return obj
        end
    end
end

function WorldUtil.findTypeOnSquare(square,type)
    local special = square:getSpecialObjects()
    for i = 0, special:size()-1 do
        local obj = special:get(i)
        if WorldUtil.ISATypes[obj:getTextureName()] == type then
            return obj
        end
    end
    return nil
end

---@param isoObject IsoObject
---@return IsoGenerator
function WorldUtil.replaceIsoObjectWithGenerator(isoObject)
    local square = isoObject:getSquare()
    local index = isoObject:getObjectIndex()
    -- if not square or index == -1 then return IsoGenerator.new(getCell()) end
    square:transmitRemoveItemFromSquare(isoObject)
    local generator = IsoGenerator.new(instanceItem("ISA.PowerBank"), square:getCell(), square)
    -- generator:transmitCompleteItemToClients()
    ---these auto transmit, do after sending object
    ---FIXME check b42
    generator:setCondition(100)
    generator:setFuel(100)
    generator:setConnected(true)
    generator:getCell():addToProcessIsoObjectRemove(generator)
    -- square:AddSpecialObject(generator, index)
    -- if isServer() then
    --     generator:transmitCompleteItemToClients()
    -- end
    generator:createContainersFromSpriteProperties()
    generator:getContainer():setExplored(true)
    triggerEvent("OnObjectAdded", generator)

    return generator
end

ISA.WorldUtil = WorldUtil
