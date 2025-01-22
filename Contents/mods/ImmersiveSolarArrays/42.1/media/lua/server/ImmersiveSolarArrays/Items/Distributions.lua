-- fixme SandboxVars are sometimes the default values at this stage - MP server values are loaded OnPreDistributionMerge???, SP are loaded when creating a character

require 'Items/Distributions'
require 'Items/ProceduralDistributions'
---@class ImmersiveSolarArrays
local ISA = require "ImmersiveSolarArrays/Utilities"

----------------------------------------------------------------------------------------------------------------------
local subDist = SuburbsDistributions
local pdList = ProceduralDistributions.list
local vehDist = VehicleDistributions

----------------------------------------------------------------------------------------------------------------------
---

ISA.Distributions = {}

local function insertRecursive(insertKey,insertInto,insertFrom,default)
    for key,value in pairs(insertFrom) do
        local _insertInto = insertInto[key]
        if not _insertInto and default then
            _insertInto = copyTable(default)
            insertInto[key] = _insertInto
        end
        if type(_insertInto) == "table" then
            if key == insertKey then
                for _,i in ipairs(value) do
                    table.insert(_insertInto,i)
                end
            else
                insertRecursive(insertKey,_insertInto,value,default)
            end
        end
    end
end

----------------------------------------------------------------------------------------------------------------------
--- add custom tables to ProceduralDistributions

pdList.ISABatteries = {
    rolls = 4,
    items = {
        "ISA.DeepCycleBattery", 36,
        "ISA.SuperBattery", 8,
        "ISA.DIYBattery", 8,
        "ISA.WiredCarBattery", 8,
    }
}
pdList.ISABatteriesCache = {
    rolls = 4,
    items = {
        "ISA.DeepCycleBattery", 64,
        "ISA.SuperBattery", 32,
        "ISA.DIYBattery", 32,
        "ISA.WiredCarBattery", 32,
    }
}
pdList.ISASolarBox = {
    rolls = 4,
    items = {
        "ISA.SolarPanel", 48,
        "ISA.DeepCycleBattery", 48,
        "ISA.SuperBattery", 24,
    },
    junk = {
        rolls = 1,
        items = {
            "ISA.ISAMag1", 64,
            "ISA.ISAInverter", 64,
            "ISA.SolarPanel", 16,
            "ISA.DeepCycleBattery", 16,
            "ISA.SuperBattery", 16,
            "ISA.SolarFailsafe", 0.1,
            "Base.ElectronicsScrap", 20,
            "Base.MetalBar", 10,
            "Base.SmallSheetMetal", 10,
            "Base.Screws", 5,
            "Base.ElectricWire", 20,
            "Base.RemoteCraftedV3", 0.1,
        }
    }
}

----------------------------------------------------------------------------------------------------------------------
---edit procList tables for room / cache house types

subDist.all.BatteryBank = {
    procedural = true,
    procList = {
        {name="ISABatteries", min=0, max=99},
    },
}
subDist.all.SolarBox = {
    procedural = true,
    procList = {
        { name = "ISASolarBox", min = 0, max = 99, weightChance = 80 },
        { name = "ISABatteries", min = 0, max = 99, weightChance = 20 },
        { name = "ISABatteriesCache", min = 0, max = 99, weightChance = 10 },
    },
}

subDist.ISASolarBoxCache = copyTable(subDist.electronicsstorage)
subDist.ISASolarBoxCache.isStore = nil
subDist.ISASolarBoxCache.SolarBox = copyTable(pdList.ISASolarBox)
subDist.ISASolarBoxCache.SolarBox.rolls = 32

insertRecursive("procList", subDist, {
    electronicsstorage = {
        metal_shelves = {
            procList = {
                { name = "ISASolarBox", min = 0, max = 1, weightChance = 10 },
            },
        },
        crate = {
            proclist = {
                { name = "ISASolarBox", min = 0, max = 1, weightChance = 20 },
                { name = "ISABatteries", min = 0, max = 1, weightChance = 5 },
                { name = "ISABatteriesCache", min = 0, max = 1, weightChance = 5 },
            },
        },
    },
    garagestorage = {
        crate = {
            procList = {
                { name = "ISASolarBox", min = 0, max = 1, weightChance = 3 },
            },
        },
    },
    storageunit = {
        crate = {
            procList = {
                { name = "ISASolarBox", min = 0, max = 1, weightChance = 5 },
            },
        },
        metal_shelves = {
            proclist = {
                { name = "ISASolarBox", min = 0, max = 1, weightChance = 3 },
            }
        }
    },
    warehouse = {
        crate = {
            procList = {
                { name = "ISASolarBox", min = 0, max = 1, weightChance = 5 },
                { name = "ISABatteries", min = 0, max = 1, weightChance = 5 },
            },
        },
    },
    --Cache
    SafehouseLoot = {
        metal_shelves = {
            procList = {
                { name = "ISASolarBox", min = 0, max = 1, weightChance = 5 },
            },
        },
    },
    ISASolarBoxCache = {
        crate = {
            procList = {
                { name = "ISASolarBox", min = 0, max = 3, weightChance = 25 },
                { name = "ISABatteries", min = 0, max = 1, weightChance = 10 },
            },
        },
        metal_shelves = {
            procList = {
                { name = "ISASolarBox", min = 0, max = 3, weightChance = 20 },
            },
        },
    }
})

----------------------------------------------------------------------------------------------------------------------
--- Insert items to item lists

function ISA.Distributions.distributeItem(info)
    local multiplier = SandboxVars.ISA[info.LRM]
    for i = 1, #info.entries do
        local entry = info.entries[i]
        table.insert(entry[2], info.fullType)
        table.insert(entry[2], entry[1] * multiplier)
    end
end

function ISA.Distributions.insertItemsToMultipleLists(distTable, targetNames, items)
    local itemsSize = #items
    for i = 1, #targetNames do
        local target = distTable[targetNames[i]]
        target = target ~= nil and target.items or nil
        if target ~= nil then
            for ii = 1, itemsSize do
                table.insert(target, items[ii])
            end
        end
    end
end

function ISA.Distributions.insertDistributions()

    ISA.Distributions.distributeItem({
        fullType = "ISA.ISAMag1",
        LRM = "LRMMisc",
        entries = {
            { 1.0, pdList["BookstoreBooks"].items },
            { 0.5, pdList["BookstoreMisc"].items },
            { 1.0, pdList["CrateMagazines"].items },
            { 2.0, pdList["ElectronicStoreMagazines"].items },
            { 0.2, pdList["EngineerTools"].items },
            { 0.8, pdList["LibraryBooks"].items },
            { 0.5, pdList["LivingRoomShelf"].items },
            { 0.5, pdList["LivingRoomShelfNoTapes"].items },
            { 0.6, pdList["MagazineRackMixed"].items },
            { 0.5, pdList["PostOfficeBooks"].items },
            { 0.8, pdList["PostOfficeMagazines"].items },
            { 0.2, pdList["ShelfGeneric"].items },
            { 1.0, vehDist["ElectricianTruckBed"].items }
        },
    })

    ISA.Distributions.distributeItem({
        fulltype = "ISA.SolarPanel",
        LRM = "LRMSolarPanels",
        entries = {
            { 0.05, pdList["ArmyHangarTools"].items },
            { 0.10, pdList["ArmyStorageElectronics"].items },
            { 0.05, pdList["CrateCarpentry"].items },
            { 0.10, pdList["CrateElectronics"].items },
            { 0.05, pdList["CrateFarming"].items },
            { 0.10, pdList["CrateMechanics"].items },
            { 0.05, pdList["CrateMetalwork"].items },
            { 0.10, pdList["CrateRandomJunk"].items },
            { 0.05, pdList["CrateTools"].items },
            { 0.10, pdList["ElectronicStoreAppliances"].items },
            { 0.15, pdList["ElectronicStoreMisc"].items },
            { 0.10, pdList["EngineerTools"].items },
            { 0.10, pdList["GarageMechanics"].items },
            { 0.05, pdList["GarageMetalwork"].items },
            { 0.05, pdList["GarageTools"].items },
            { 0.10, pdList["GigamartHouseElectronics"].items },
            { 0.05, pdList["GigamartFarming"].items },
            { 0.05, pdList["LoggingFactoryTools"].items },
            { 0.05, pdList["MechanicShelfElectric"].items },
            { 0.05, pdList["MechanicShelfMisc"].items },
            { 0.05, pdList["MetalShopTools"].items },
            { 0.20, pdList["StoreShelfElectronics"].items },
            { 0.10, pdList["ToolStoreFarming"].items },
            { 0.10, pdList["ToolStoreMetalwork"].items },
            { 0.15, pdList["ToolStoreMisc"].items },
            { 0.10, pdList["ToolStoreTools"].items },
            { 0.10, pdList["OtherGeneric"].items },
            { 0.01, subDist.all.metal_shelves.items },
            { 1.00, vehDist["ElectricianTruckBed"].items }
        },
    })

    ISA.Distributions.distributeItem({
        fulltype = "ISA.DeepCycleBattery",
        LRM = "LRMBatteries",
        entries = {
            { 0.15, pdList["JanitorMisc"].items },
            { 0.15, pdList["StoreShelfElectronics"].items },
            { 0.15, pdList["MechanicShelfElectric"].items },
            { 0.20, pdList["StoreShelfMechanics"].items },
            { 0.15, pdList["CrateElectronics"].items },
            { 0.15, pdList["CrateMechanics"].items },
            { 0.15, pdList["ToolStoreTools"].items },
            { 0.20, pdList["ToolStoreMisc"].items },
            { 0.15, pdList["ArmyStorageElectronics"].items },
            { 0.15, pdList["ElectronicStoreMisc"].items },
            { 0.15, pdList["CrateRandomJunk"].items },
            { 0.15, pdList["CrateTools"].items },
            { 0.15, pdList["OtherGeneric"].items },
            { 0.15, pdList["GarageMechanics"].items },
            { 0.15, pdList["ToolStoreFarming"].items },
            { 0.03, pdList["CrateFarming"].items },
            { 0.03, pdList["CrateMetalwork"].items },
            { 0.01, subDist.all.metal_shelves.items },
            { 1.00, vehDist["ElectricianTruckBed"].items }
        },
    })

    ISA.Distributions.distributeItem({
        fulltype = "ISA.SuperBattery",
        LRM = "LRMBatteries",
        entries = {
            { 0.05, pdList["JanitorMisc"].items },
            { 0.05, pdList["StoreShelfElectronics"].items },
            { 0.05, pdList["MechanicShelfElectric"].items },
            { 0.10, pdList["StoreShelfMechanics"].items },
            { 0.05, pdList["CrateElectronics"].items },
            { 0.05, pdList["CrateMechanics"].items },
            { 0.05, pdList["ToolStoreTools"].items },
            { 0.10, pdList["ToolStoreMisc"].items },
            { 0.20, pdList["ArmyStorageElectronics"].items },
            { 0.05, pdList["ElectronicStoreMisc"].items },
            { 0.05, pdList["CrateRandomJunk"].items },
            { 0.05, pdList["CrateTools"].items },
            { 0.05, pdList["OtherGeneric"].items },
            { 0.05, pdList["GarageMechanics"].items },
            { 0.05, pdList["ToolStoreFarming"].items },
            { 0.05, pdList["CrateFarming"].items },
            { 0.05, pdList["CrateMetalwork"].items },
            { 0.01, subDist.all.metal_shelves.items },
            { 0.40, vehDist["ElectricianTruckBed"].items }
        },
    })

    ISA.Distributions.distributeItem({
        fulltype = "ISA.ISAInverter",
        LRM = "LRMMisc",
        entries = {
            { 0.10, pdList["StoreShelfElectronics"].items },
            { 0.10, pdList["StoreShelfMechanics"].items },
            { 0.10, pdList["CrateElectronics"].items },
            { 0.10, pdList["CrateMechanics"].items },
            { 0.10, pdList["MechanicShelfMisc"].items },
            { 0.10, pdList["MechanicShelfElectric"].items },
            { 0.10, pdList["ToolStoreMisc"].items },
            { 0.10, pdList["ToolStoreTools"].items },
            { 0.10, pdList["GigamartHouseElectronics"].items },
            { 0.10, pdList["ArmyStorageElectronics"].items },
            { 0.10, pdList["ElectronicStoreMisc"].items },
            { 0.10, pdList["CrateRandomJunk"].items },
            { 0.10, pdList["CrateTools"].items },
            { 0.10, pdList["OtherGeneric"].items },
            { 0.10, pdList["GarageMechanics"].items },
            { 0.10, pdList["ElectronicStoreAppliances"].items },
            { 0.10, pdList["ToolStoreFarming"].items },
            { 0.03, pdList["CrateFarming"].items },
            { 0.03, pdList["CrateMetalwork"].items },
            { 0.01, subDist.all.metal_shelves.items },
            { 0.60, vehDist["ElectricianTruckBed"].items }
        },
    })

    ISA.Distributions.distributeItem({
        fulltype = "ISA.SolarFailsafe",
        LRM = "LRMMisc",
        entries = {
            { 0.01, pdList["CrateElectronics"].junk.items },
            { 0.01, pdList["GigamartHouseElectronics"].junk.items },
            { 0.01, pdList["ArmyStorageElectronics"].junk.items },
            { 0.01, pdList["ElectronicStoreMisc"].junk.items },
            { 0.01, vehDist["ElectricianTruckBed"].items }
        },
    })

    ---TODO after debugging sandbox options load
    -- ISA.Distributions = nil
end

--- remake distributions based on sandbox, used by stash items
local function OnLoadedMapZones()
    if ItemPickerJava.doParse then
        ItemPickerJava.doParse = nil
        ItemPickerJava.Parse()
    end
    ISA.distributions = nil
    ISA.Distributions = nil
end

ISA.Distributions.insertDistributions()
Events.OnLoadedMapZones.Add(OnLoadedMapZones)
