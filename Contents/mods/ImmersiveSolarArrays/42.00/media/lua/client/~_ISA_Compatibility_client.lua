local ISA = require "ImmersiveSolarArrays/Utilities"
require "UI/ISAUI"

ISA.patchClassMetaMethod(zombie.inventory.types.DrainableComboItem.class,"DoTooltip",ISA.UI.DoTooltip_patch)

require "ISUI/ISInventoryPane"
ISInventoryPane.drawItemDetails = ISA.UI.ISInventoryPane_drawItemDetails_patch(ISInventoryPane.drawItemDetails)
