local ISA = require "ImmersiveSolarArrays/ISAUtilities"
require "UI/ISAUI"
local PbSystem = require "ImmersiveSolarArrays/Powerbank/ISAPowerbankSystem_client"

ISA.patchClassMetaMethod(zombie.inventory.types.DrainableComboItem.class,"DoTooltip",ISA.UI.DoTooltip_patch)

require "ISUI/ISInventoryPane"
ISInventoryPane.drawItemDetails = ISA.UI.ISInventoryPane_drawItemDetails_patch(ISInventoryPane.drawItemDetails)

require "TimedActions/ISActivateGenerator"
ISActivateGenerator.perform = PbSystem.ISActivateGenerator_perform(ISActivateGenerator.perform)

require "TimedActions/ISInventoryTransferAction"
ISInventoryTransferAction.transferItem = PbSystem.ISInventoryTransferAction_transferItem(ISInventoryTransferAction.transferItem)

require "TimedActions/ISPlugGenerator"
ISPlugGenerator.perform = PbSystem.ISPlugGenerator_perform(ISPlugGenerator.perform)
