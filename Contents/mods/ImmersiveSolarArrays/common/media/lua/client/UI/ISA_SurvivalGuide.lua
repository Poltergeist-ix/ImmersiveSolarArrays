
require "SurvivalGuide/ISTutorialPanel"

local Guide = {}

function Guide.onUrlClick(panel,button)
    ---FIXME getText
    ---FIXME font size
    local modal = ISModalDialog:new(getCore():getScreenWidth()-200,getCore():getScreenHeight()/2-40, 400, 80,
                                    getText("Confirm open link\n%1",button.url), true, button, Guide.onConfirmUrlClick)
    modal:initialise()
    modal:addToUIManager()
end

function Guide.onConfirmUrlClick(target,button)
    if button.internal == "YES" then
		openUrl(target.url)
	end
end

function Guide.addButton(self,num)
    ---FIXME text size
    local button = ISButton:new(5,self.height-25*(num+1),self.width-10,20,"",self,Guide.onUrlClick,nil,nil)
    ---anchors?
    self:addChild(button)
    self.urlButtons[num] = button
    return button
end

local setPage = ISTutorialPanel.setPage
function ISTutorialPanel:setPage(pageNum)
    local panel = self.rightPanel
    panel.urlButtons = panel.urlButtons or {}
    panel.urlButtonsVisible = panel.urlButtonsVisible or 0

    setPage(self,pageNum)

    page = SurvivalGuideEntries.list:get(pageNum-1)
    local lSize = page.urls ~= nil and #page.urls or 0
    for i = 1, lSize do
        local button = panel.urlButtons[i] or Guide.addButton(panel,i)
        button.title = page.urls[i][1]
        button.url = page.urls[i][2]
        button:setVisible(true)
        zxtest = button
    end
    for i = lSize + 1, panel.urlButtonsVisible do
        panel.urlButtons[i]:setVisible(false)
    end
    ---resize rich text not scrolled height
    panel.urlButtonsVisible = lSize
end

------------------------------------------------------------------------------------------------------------------------

require "SurvivalGuide/SurvivalGuideEntries"

---FIXME TEXTS
SurvivalGuideEntries.list:add{
    -- title = getText("SurvivalGuide_entrie"..index.."title"),
    -- text = getText("SurvivalGuide_entrie"..index.."txt"),
    -- moreInfo = getText("SurvivalGuide_entrie"..index.."moreinfo"),
    title = "#Mod - Immersive Solar Arrays",
    text = "# Immersive Solar Arrays <br> Add Image",
    moreInfo = "The Solar Power Survival Guide <br> Connect the generator.",
    urls = {
        {"view wiki", "https://github.com/radx5Blue/ImmersiveSolarArrays/wiki"},
        {"buy me a coffee", "https://github.com/radx5Blue/ImmersiveSolarArrays/wiki"},
    }
}

--[[
local doShow

---if doShow show guide
---read magazine

Events.OnPlayerDeath.Add(function (player)
    getFileWriter("ImmersiveSolarArrays.txt",true,false):close()
    doShow = true
end)
--]]