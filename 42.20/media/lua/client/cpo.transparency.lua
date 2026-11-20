require "ISUI/ISLabel"
require "RadioCom/ISUIRadio/ISSliderPanel"
require "ISUI/Crafting/ISHandcraftWindow"
require "ISUI/Crafting/ISHandcraftWindowHeader"
require "Entity/ISUI/CraftRecipe/ISCraftRecipePanel"

if ISHandcraftWindowHeader._cpoTransparencyHookInstalled then
    return
end

local defaultTransparency = 20
local windows = setmetatable({}, { __mode = "k" })
local originalAlphas = setmetatable({}, { __mode = "k" })

local function applyPanelTransparency(panel)
    if not panel or not panel.backgroundColor then
        return
    end

    if originalAlphas[panel] == nil then
        originalAlphas[panel] = panel.backgroundColor.a
    end

    panel.backgroundColor.a = originalAlphas[panel] * (1 - defaultTransparency / 100)
end

local function applyRecipeTransparency(recipePanel)
    applyPanelTransparency(recipePanel)
    applyPanelTransparency(recipePanel.titleWidget)
    applyPanelTransparency(recipePanel.inputs)
    applyPanelTransparency(recipePanel.outputs)
    applyPanelTransparency(recipePanel.craftControl)
end

local function applyWindowTransparency(window)
    if not window then
        return
    end

    local handCraftPanel = window.handCraftPanel

    applyPanelTransparency(window)
    applyPanelTransparency(window.windowHeader)
    applyPanelTransparency(handCraftPanel)

    if not handCraftPanel then
        return
    end

    applyPanelTransparency(handCraftPanel.recipeCategories)
    applyPanelTransparency(handCraftPanel.recipesPanel)
    applyPanelTransparency(handCraftPanel.inventoryPanel)

    if handCraftPanel.recipeCategories then
        applyPanelTransparency(handCraftPanel.recipeCategories.recipeCategoryPanel)
    end

    if handCraftPanel.recipesPanel then
        applyPanelTransparency(handCraftPanel.recipesPanel.recipeFilterPanel)
        applyPanelTransparency(handCraftPanel.recipesPanel.recipeListPanel)
        applyPanelTransparency(handCraftPanel.recipesPanel.recipeIconPanel)

        local recipeList = handCraftPanel.recipesPanel.recipeListPanel
    
        if recipeList then
            applyPanelTransparency(recipeList.recipeListPanel)
        end
    end

    applyRecipeTransparency(handCraftPanel.recipePanel)
end

function CraftPanelOverhaul.setBackgroundTransparency(value)
    if type(value) ~= "number" or value ~= value or value < 0 or value > 100 then
        error("CraftPanelOverhaul: background transparency must be between 0 and 100")
    end

    defaultTransparency = value
    for window in pairs(windows) do
        applyWindowTransparency(window)
    end
end

function CraftPanelOverhaul.getBackgroundTransparency()
    return defaultTransparency
end

local function onTransparencyChanged(_, value)
    CraftPanelOverhaul.setBackgroundTransparency(value)
end

local function getRecipeFilterPanel(header)
    local window = header.parent
    local handCraftPanel = window and window.handCraftPanel
    local recipesPanel = handCraftPanel and handCraftPanel.recipesPanel
    return recipesPanel and recipesPanel.recipeFilterPanel
end

local function getRecipeFilterMinimumWidth(filterPanel)
    local gap = 5
    local width = 130 + gap + filterPanel.viewModeButton:getWidth() + 2

    if filterPanel.filterTypeCombo then
        width = width + gap + filterPanel.filterTypeCombo:getWidth()
    end

    return math.max(filterPanel.minimumWidth or 0, width)
end

local function moveRecipeFilterToHeader(window)
    local handCraftPanel = window.handCraftPanel
    local recipesPanel = handCraftPanel and handCraftPanel.recipesPanel
    local filterPanel = recipesPanel and recipesPanel.recipeFilterPanel

    if not filterPanel or filterPanel._cpoMovedToHeader then
        return
    end

    local filterRow = recipesPanel.recipeFilterPanelRow

    if filterRow and recipesPanel.recipeTable then
        local filterCell = recipesPanel.recipeTable:cell(0, filterRow:index())
        recipesPanel.recipeTable:setElement(0, filterRow:index(), nil)
        if filterCell then
            filterCell.minimumWidth = 0
            filterCell.minimumHeight = 0
        end
        filterRow:setVisible(false, true)
    elseif filterPanel.parent then
        filterPanel.parent:removeChild(filterPanel)
    end

    window.windowHeader:addChild(filterPanel)
    filterPanel._cpoMovedToHeader = true

    window.windowHeader.borderColor.a = 0
    filterPanel.borderColor.a = 0

    local icon = window.windowHeader.icon

    if icon then
        window.windowHeader:removeChild(icon)
        window.windowHeader.icon = nil
        window.windowHeader.iconSize = 0
    end

    local title = window.windowHeader.title

    if title then
        title:setVisible(false)
        title:setWidth(0)
    end

    if filterPanel.showAllRecipeTickBox then
        filterPanel.showAllRecipeTickBox.changeOptionTarget = filterPanel.callbackTarget
        filterPanel.showAllRecipeTickBox.changeOptionMethod = function(handCraftPanel, _, enabled)
            handCraftPanel:setSeeAllRecipe(enabled)
        end
    end

    filterPanel.filter = function(panel, textFilter, selectedCombo)
        panel.searchEntryBox:setText(textFilter)
        panel.filterTypeCombo:selectOptionFromText(selectedCombo)
        panel.showAllRecipeTickBox:setSelected(1, true)
        panel.callbackTarget:setSeeAllRecipe(true)
        panel.searchEntryBox:onTextChange()
    end
end

local function addTransparencySlider(header)
    if header.transparencySlider then
        return
    end

    local label = ISLabel:new(0, 0, 18, getText("UI_CPO_Transparency"), 1, 1, 1, 1, UIFont.Small, true)

    label:initialise()
    label:instantiate()
    label.tooltip = getText("UI_CPO_TransparencyTooltip")
    header.transparencyLabel = label
    header:addChild(label)

    local slider = ISSliderPanel:new(0, 0, 64, 18, header, onTransparencyChanged)

    slider:initialise()
    slider:instantiate()
    slider:setValues(0, 100, 5, defaultTransparency, true)
    slider:setCurrentValue(defaultTransparency, true)
    slider.tooltip = getText("UI_CPO_TransparencyTooltip")
    header.transparencySlider = slider
    header:addChild(slider)
end

local originalHeaderCalculateLayout = ISHandcraftWindowHeader.calculateLayout

local function calculateHeaderLayout(header, preferredWidth, preferredHeight)
    local label = header.transparencyLabel
    local slider = header.transparencySlider

    if not label or not slider then
        originalHeaderCalculateLayout(header, preferredWidth, preferredHeight)
        return
    end

    local gap = 8
    local filterPanel = getRecipeFilterPanel(header)
    local filterMinimumWidth = 0
    local filterHeight = 0

    if filterPanel and filterPanel._cpoMovedToHeader then
        filterMinimumWidth = getRecipeFilterMinimumWidth(filterPanel)
        filterPanel:calculateLayout(filterMinimumWidth, 0)
        filterMinimumWidth = math.max(filterMinimumWidth, filterPanel.minimumWidth or 0)
        filterPanel:calculateLayout(filterMinimumWidth, 0)
        filterHeight = filterPanel:getHeight()
    end

    local requiredHeight = math.max(
        preferredHeight or 0,
        filterHeight + header.paddingTop + header.paddingBottom + header.marginTop + header.marginBottom
    )
    originalHeaderCalculateLayout(header, preferredWidth, requiredHeight)

    local infoWidth = header.buttonInfo and header.buttonInfo:getWidth() + gap or 0
    local requiredWidth = (filterMinimumWidth > 0 and filterMinimumWidth + gap or 0)
        + gap + label:getWidth()
        + gap + slider:getWidth()
        + infoWidth
        + header.paddingRight + header.marginRight + gap

    if header:getWidth() < requiredWidth then
        originalHeaderCalculateLayout(header, requiredWidth, requiredHeight)
    end

    local controlsRight = header.buttonInfo and header.buttonInfo:getX() - gap or header:getWidth() - header.paddingRight - header.marginRight - gap

    slider:setX(controlsRight - slider:getWidth())
    slider:setY((header:getHeight() - slider:getHeight()) / 2)
    label:setX(slider:getX() - gap - label:getWidth())
    label:setY((header:getHeight() - label:getHeight()) / 2)

    if filterPanel and filterPanel._cpoMovedToHeader then
        local filterX = 0
        local filterRight = label:getX() - gap
        filterPanel:calculateLayout(math.max(filterMinimumWidth, filterRight - filterX), 0)
        filterPanel:setX(filterX)
        filterPanel:setY((header:getHeight() - filterPanel:getHeight()) / 2)
    end
end

ISHandcraftWindowHeader._cpoTransparencyHookInstalled = true

local originalHeaderCreateChildren = ISHandcraftWindowHeader.createChildren

ISHandcraftWindowHeader.createChildren = function(self, ...)
    originalHeaderCreateChildren(self, ...)
    addTransparencySlider(self)
end

ISHandcraftWindowHeader.calculateLayout = calculateHeaderLayout

local originalWindowCreateChildren = ISHandcraftWindow.createChildren

ISHandcraftWindow.createChildren = function(self, ...)
    local result = originalWindowCreateChildren(self, ...)
    windows[self] = true
    moveRecipeFilterToHeader(self)
    applyWindowTransparency(self)
    self:xuiRecalculateLayout(nil, nil, true)
    return result
end

local originalWindowPrerender = ISHandcraftWindow.prerender

ISHandcraftWindow.prerender = function(self, ...)
    local result = originalWindowPrerender(self, ...)

    local title = self.windowHeader and self.windowHeader.title and self.windowHeader.title.name

    if title and title ~= "" then
        local titleX

        if self.infoButton then
            titleX = self.infoButton:getRight() + (5 - getCore():getOptionFontSizeReal()) * 2
        elseif self.closeButton then
            titleX = self.closeButton:getRight() + 8
        else
            titleX = 40
        end

        self:drawText(title, titleX, 0, 1, 1, 1, 1, UIFont.Small)
    end

    return result
end

local originalRecipeCreateDynamicChildren = ISCraftRecipePanel.createDynamicChildren

ISCraftRecipePanel.createDynamicChildren = function(self, ...)
    local result = originalRecipeCreateDynamicChildren(self, ...)
    applyRecipeTransparency(self)
    return result
end