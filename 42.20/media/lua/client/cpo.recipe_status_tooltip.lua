require "Entity/ISUI/Controls/ISWidgetTitleHeader"
require "Entity/ISUI/CraftRecipe/ISCraftRecipePanel"
require "ISUI/Crafting/ISHandcraftWindow"
require "Entity/ISUI/Windows/ISEntityWindow"
require "ISUI/ISToolTip"

local TITLE_TEXT_MAX_WIDTH = 145
local TITLE_ICON_SCALE = 0.75
local STATUS_TOOLTIP_MAX_LINE_WIDTH = 280
local STATUS_ICON_FIELDS = {
    "timeIcon",
    "isCanWalkIcon",
    "canBeDoneInDarkIcon",
    "needToBeLearnIcon",
    "requiresSurfaceIcon",
}
local STATUS_LABEL_FIELDS = {
    "tooltipLabel",
    "timeLabel",
    "specificWorkstationLabel",
    "recipeBenefitLabel",
    "errorLabel",
}

local function compactTitleHeader(titleWidget)
    if not titleWidget then
        return
    end

    local titleLabel = titleWidget.titleLabel
    if titleLabel then
        local title = titleLabel.origTitleStr or titleLabel.name
        titleLabel:setName(getTextManager():WrapText(titleLabel.font, title, TITLE_TEXT_MAX_WIDTH))
        titleLabel:setHeightToName(0)
    end

    if titleWidget.icon then
        local iconSize = math.max(32, math.floor(titleWidget.icon:getWidth() * TITLE_ICON_SCALE + 0.5))
        titleWidget.icon:setWidth(iconSize)
        titleWidget.icon:setHeight(iconSize)
        titleWidget.iconSize = iconSize
    end

    titleWidget.propertyIconSize = math.max(
        12,
        math.floor((titleWidget.propertyIconSize or 16) * TITLE_ICON_SCALE + 0.5)
    )
    for _, field in ipairs(STATUS_ICON_FIELDS) do
        local icon = titleWidget[field]
        if icon then
            icon:setWidth(titleWidget.propertyIconSize)
            icon:setHeight(titleWidget.propertyIconSize)
        end
    end
end

local function appendTooltipLine(lines, text, color)
    if not text or text == "" then
        return
    end

    color = color or { r = 1, g = 1, b = 1 }
    table.insert(lines, string.format(
        "<RGB:%.2f,%.2f,%.2f> %s <RGB:1,1,1>",
        color.r or 1,
        color.g or 1,
        color.b or 1,
        text
    ))
end

local function updateRecipeStatusText(titleWidget)
    local lines = {}

    local recipeDescription = titleWidget.tooltipLabel
    if recipeDescription then
        appendTooltipLine(lines, recipeDescription:getName(), { r = 1, g = 1, b = 1 })
        recipeDescription:setVisible(false)
    end

    for _, label in ipairs(titleWidget.requiredSkillList or {}) do
        appendTooltipLine(lines, label.origTitleStr or label.name, label)
        label:setVisible(false)
    end

    local workstation = titleWidget.specificWorkstationLabel

    if workstation and workstation:isVisible() then
        appendTooltipLine(lines, workstation.text, workstation)
        workstation:setVisible(false)
    end

    local benefit = titleWidget.recipeBenefitLabel

    if benefit and benefit:isVisible() then
        appendTooltipLine(lines, benefit.text, benefit)
        benefit:setVisible(false)
    end

    local errorLabel = titleWidget.errorLabel

    if errorLabel and errorLabel:isVisible() then
        appendTooltipLine(lines, errorLabel.errorText, titleWidget.colBad)
        errorLabel:setVisible(false)
    end

    titleWidget.cpoStatusTooltipText = #lines > 0 and table.concat(lines, " <LINE> ") or nil
end

local function isInside(element, mouseX, mouseY)
    if not element or not element:isVisible() then
        return false
    end

    local x = element:getAbsoluteX()
    local y = element:getAbsoluteY()

    return mouseX >= x and mouseX <= x + element:getWidth()
        and mouseY >= y and mouseY <= y + element:getHeight()
end

local function isOverStatusIcon(titleWidget, mouseX, mouseY)
    for _, field in ipairs(STATUS_ICON_FIELDS) do
        local icon = titleWidget[field]
        if isInside(icon, mouseX, mouseY) then
            return true
        end
    end
    return false
end

local function updateStatusTooltip(titleWidget)
    local text = titleWidget.cpoStatusTooltipText
    local mouseX = getMouseX()
    local mouseY = getMouseY()
    local x = titleWidget:getAbsoluteX()
    local y = titleWidget:getAbsoluteY()
    local tooltip = titleWidget.cpoStatusTooltip
    local overHeader = mouseX >= x and mouseX <= x + titleWidget:getWidth() and mouseY >= y and mouseY <= y + titleWidget:getHeight()
    local overTooltip = tooltip and tooltip:getIsVisible() and isInside(tooltip, mouseX, mouseY)

    if not text or (not overHeader and not overTooltip)
        or (overHeader and isOverStatusIcon(titleWidget, mouseX, mouseY)) then
        if tooltip and tooltip:getIsVisible() then
            tooltip:setVisible(false)
            tooltip:removeFromUIManager()
        end
        return
    end

    if not tooltip then
        tooltip = ISToolTip:new()
        tooltip:setOwner(titleWidget)
        tooltip:setVisible(false)
        tooltip:setAlwaysOnTop(true)
        titleWidget.cpoStatusTooltip = tooltip
    end

    local layoutChanged = not tooltip.cpoStatusLayoutConfigured

    if layoutChanged then
        tooltip.maxLineWidth = STATUS_TOOLTIP_MAX_LINE_WIDTH
        tooltip.descriptionPanel.marginTop = 2
        tooltip.descriptionPanel.marginBottom = getTextManager():getFontHeight(ISToolTip.GetFont())
        tooltip.descriptionPanel.marginLeft = 6
        tooltip.descriptionPanel.marginRight = 6
        tooltip.cpoStatusLayoutConfigured = true
    end

    if layoutChanged or tooltip.description ~= text then
        tooltip.description = text
        tooltip:doLayout()
    end

    if not tooltip:getIsVisible() then
        tooltip:addToUIManager()
        tooltip:setVisible(true)
    end

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local tooltipX = x + titleWidget:getWidth() + 4

    if tooltipX + tooltip:getWidth() > screenWidth then
        tooltipX = x - tooltip:getWidth() - 4
    end

    tooltipX = math.max(0, math.min(tooltipX, screenWidth - tooltip:getWidth()))

    local tooltipY = y + (titleWidget:getHeight() - tooltip:getHeight()) / 2

    tooltipY = math.max(0, math.min(tooltipY, screenHeight - tooltip:getHeight()))
    tooltip:setDesiredPosition(tooltipX, tooltipY)
end

local originalTitleUpdateLabels = ISWidgetTitleHeader.updateLabels

ISWidgetTitleHeader.updateLabels = function(self, ...)
    local result = originalTitleUpdateLabels(self, ...)
    if CraftPanelOverhaul.isHandCraftWidget(self) then
        updateRecipeStatusText(self)
    end
    return result
end

local originalTitleUpdate = ISWidgetTitleHeader.update

ISWidgetTitleHeader.update = function(self, ...)
    local result = originalTitleUpdate(self, ...)
    if CraftPanelOverhaul.isHandCraftWidget(self) then
        updateStatusTooltip(self)
    end
    return result
end

local originalTitleCalculateLayout = ISWidgetTitleHeader.calculateLayout

ISWidgetTitleHeader.calculateLayout = function(self, ...)
    if not CraftPanelOverhaul.isHandCraftWidget(self) then
        return originalTitleCalculateLayout(self, ...)
    end

    local iconCount = 0
    for _, field in ipairs(STATUS_ICON_FIELDS) do
        local icon = self[field]
        if icon then
            iconCount = iconCount + 1
            icon:setWidth(0)
        end
    end

    local result = originalTitleCalculateLayout(self, ...)
    local iconSize = self.propertyIconSize or 0
    local iconX = self.titleLabel and self.titleLabel:getX() or self.paddingLeft
    local iconY = self.titleLabel and self.titleLabel:getBottom() or 0

    for _, field in ipairs(STATUS_LABEL_FIELDS) do
        local label = self[field]
        if label and label:isVisible() then
            iconY = math.max(iconY, label:getBottom())
        end
    end

    for _, label in ipairs(self.requiredSkillList or {}) do
        if label:isVisible() then
            iconY = math.max(iconY, label:getBottom())
        end
    end

    iconY = iconY + 3
    for _, field in ipairs(STATUS_ICON_FIELDS) do
        local icon = self[field]
        if icon then
            icon:setWidth(iconSize)
            icon:setHeight(iconSize)
            icon:setX(iconX)
            icon:setY(iconY)
            iconX = iconX + iconSize + 3
        end
    end

    if iconCount > 0 then
        local bottom = iconY + iconSize + (self.paddingBottom or 0) + (self.marginBottom or 0)
        self:setHeight(math.max(self:getHeight(), bottom))
    end

    self:updatePropertyIcons()
    return result
end

local originalRecipeCreateDynamicChildren = ISCraftRecipePanel.createDynamicChildren

local function removeStatusTooltip(titleWidget)
    local tooltip = titleWidget and titleWidget.cpoStatusTooltip
    if tooltip then
        tooltip:setVisible(false)
        tooltip:removeFromUIManager()
        titleWidget.cpoStatusTooltip = nil
    end
end

ISCraftRecipePanel.createDynamicChildren = function(self, ...)
    if not CraftPanelOverhaul.isHandCraftWidget(self) then
        return originalRecipeCreateDynamicChildren(self, ...)
    end

    removeStatusTooltip(self.titleWidget)
    local result = originalRecipeCreateDynamicChildren(self, ...)
    compactTitleHeader(self.titleWidget)
    self:xuiRecalculateLayout()
    return result
end

local originalWindowClose = ISHandcraftWindow.close
ISHandcraftWindow.close = function(self, ...)
    local recipePanel = self.handCraftPanel and self.handCraftPanel.recipePanel
    removeStatusTooltip(recipePanel and recipePanel.titleWidget)
    return originalWindowClose(self, ...)
end

local originalEntityWindowClose = ISEntityWindow.close
ISEntityWindow.close = function(self, ...)
    local componentPanels = self.componentsPanel and self.componentsPanel.panels or {}
    for _, panelInfo in ipairs(componentPanels) do
        local handCraftPanel = panelInfo.panel and panelInfo.panel.handCraftPanel
        local recipePanel = handCraftPanel and handCraftPanel.recipePanel
        removeStatusTooltip(recipePanel and recipePanel.titleWidget)
    end
    return originalEntityWindowClose(self, ...)
end

