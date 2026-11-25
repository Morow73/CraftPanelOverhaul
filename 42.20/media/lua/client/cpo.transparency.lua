require "ISUI/ISLabel"
require "RadioCom/ISUIRadio/ISSliderPanel"
require "ISUI/Crafting/ISHandcraftWindow"
require "ISUI/Crafting/ISHandcraftWindowHeader"
require "Entity/ISUI/Controls/ISWidgetEntityHeader"
require "Entity/ISUI/CraftRecipe/ISCraftRecipePanel"
require "Entity/ISUI/Windows/ISEntityWindow"

local defaultTransparency = CraftPanelOverhaul.getBackgroundTransparency
    and CraftPanelOverhaul.getBackgroundTransparency()
    or 20
local windows = setmetatable({}, { __mode = "k" })
local originalAlphas = setmetatable({}, { __mode = "k" })

local function getEntityCraftBenchPanel(window)
    local componentPanels = window and window.componentsPanel and window.componentsPanel.panels
    for _, panelInfo in ipairs(componentPanels or {}) do
        local componentPanel = panelInfo.panel
        if componentPanel and componentPanel.handCraftPanel then
            return componentPanel
        end
    end
end

local function getCraftPanel(window)
    if not window then
        return nil
    end

    local componentPanel = getEntityCraftBenchPanel(window)
    return window.handCraftPanel or (componentPanel and componentPanel.handCraftPanel)
end

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
    if not recipePanel then
        return
    end

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

    local componentPanel = getEntityCraftBenchPanel(window)
    local craftPanel = window.handCraftPanel or (componentPanel and componentPanel.handCraftPanel)

    applyPanelTransparency(window)
    applyPanelTransparency(window.windowHeader)
    applyPanelTransparency(window.entityHeader)
    applyPanelTransparency(window.componentsPanel)
    applyPanelTransparency(craftPanel)

    applyPanelTransparency(componentPanel)
    if not craftPanel then
        return
    end

    local categories = craftPanel.recipeCategories
    local recipes = craftPanel.recipesPanel
    local recipeList = recipes and recipes.recipeListPanel

    applyPanelTransparency(categories)
    applyPanelTransparency(categories and categories.recipeCategoryPanel)
    applyPanelTransparency(recipes)
    applyPanelTransparency(recipes and recipes.recipeFilterPanel)
    applyPanelTransparency(recipeList)
    applyPanelTransparency(recipeList and recipeList.recipeListPanel)
    applyPanelTransparency(recipes and recipes.recipeIconPanel)
    applyPanelTransparency(craftPanel.inventoryPanel)

    applyRecipeTransparency(craftPanel.recipePanel)
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

local function getRecipeFilterPanel(window)
    local craftPanel = window and getCraftPanel(window)
    local recipesPanel = craftPanel and craftPanel.recipesPanel
    return recipesPanel and recipesPanel.recipeFilterPanel
end

local function getRecipeFilterMinimumWidth(filterPanel)
    local gap = 5
    local inset = gap + 1
    local viewModeWidth = filterPanel.viewModeButton:getWidth()
    local filterTypeWidth = filterPanel.filterTypeCombo and filterPanel.filterTypeCombo:getWidth() or 0
    local sortWidth = filterPanel.sortCombo and filterPanel.sortCombo:getWidth() or 0

    if filterTypeWidth > 0 and sortWidth > 0 then
        filterTypeWidth = math.max(filterTypeWidth, sortWidth - viewModeWidth - gap)
    end

    local width = inset * 2 + 130 + viewModeWidth + gap
    if filterTypeWidth > 0 then
        width = width + filterTypeWidth + gap
    end

    local tickBox = filterPanel.showAllRecipeTickBox
    if tickBox and filterPanel.sortComboLabel and filterPanel.sortCombo then
        local secondRowWidth = inset * 2
            + tickBox:getWidth()
            + filterPanel.sortComboLabel:getWidth()
            + gap * 2
            + viewModeWidth
            + filterTypeWidth
        width = math.max(width, secondRowWidth)
    end

    return math.max(filterPanel.minimumWidth or 0, width)
end

local function moveRecipeFilterToHeader(window, header)
    local craftPanel = getCraftPanel(window)
    local recipesPanel = craftPanel and craftPanel.recipesPanel
    local filterPanel = recipesPanel and recipesPanel.recipeFilterPanel

    if not filterPanel or filterPanel._cpoMovedToHeader or not header then
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

    header:addChild(filterPanel)
    filterPanel._cpoMovedToHeader = true

    if header.title then
        header.cpoWindowTitle = header.title.origTitleStr or header.title.name
        header.title:setVisible(false)
        header.title:setWidth(0)
    end
    if header.icon then
        header:removeChild(header.icon)
        header.icon = nil
        header.iconSize = 0
    end
    header.borderColor.a = 0
    filterPanel.borderColor.a = 0

    if filterPanel.showAllRecipeTickBox then
        filterPanel.showAllRecipeTickBox.changeOptionTarget = filterPanel.callbackTarget
        filterPanel.showAllRecipeTickBox.changeOptionMethod = function(target, _, enabled)
            target:setSeeAllRecipe(enabled)
        end
    end

    filterPanel.filter = function(panel, textFilter, selectedCombo)
        panel.searchEntryBox:setText(textFilter)
        if panel.filterTypeCombo then
            panel.filterTypeCombo:selectOptionFromText(selectedCombo)
        end
        if panel.showAllRecipeTickBox then
            panel.showAllRecipeTickBox:setSelected(1, true)
            panel.callbackTarget:setSeeAllRecipe(true)
        end
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

local function createHeaderCalculateLayout(originalCalculateLayout)
    return function(header, preferredWidth, preferredHeight)
        local window = header.parent
        local isHandcraftWindow = window and window.windowHeader == header
        local isEntityCraftWindow = window
            and window.entityHeader == header
            and getEntityCraftBenchPanel(window)
        local filterPanel = (isHandcraftWindow or isEntityCraftWindow) and getRecipeFilterPanel(window) or nil

        if isHandcraftWindow or isEntityCraftWindow then
            if not header.transparencySlider then
                addTransparencySlider(header)
            end

            if isEntityCraftWindow and isEntityCraftWindow.componentHeader then
                isEntityCraftWindow:removeComponentHeader()
            end

            if filterPanel and not filterPanel._cpoMovedToHeader then
                moveRecipeFilterToHeader(window, header)
            end

            if not windows[window] then
                windows[window] = true
                if isEntityCraftWindow then
                    CraftPanelOverhaul.applyEntityWindowTheme(window, isEntityCraftWindow)
                end
                applyWindowTransparency(window)
            end
        end

        local label = header.transparencyLabel
        local slider = header.transparencySlider

        if not label or not slider then
            originalCalculateLayout(header, preferredWidth, preferredHeight)
            return
        end

        local gap = 8
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
        originalCalculateLayout(header, preferredWidth, requiredHeight)

        local infoWidth = header.buttonInfo and header.buttonInfo:getWidth() + gap or 0
        local titleWidth = header.title and header.title:isVisible() and header.title:getRight() or 0
        local requiredWidth = (filterMinimumWidth > 0 and filterMinimumWidth + gap or 0)
            + (titleWidth > 0 and titleWidth + gap or 0)
            + gap + label:getWidth()
            + gap + slider:getWidth()
            + infoWidth
            + header.paddingRight + header.marginRight + gap

        if header:getWidth() < requiredWidth then
            originalCalculateLayout(header, requiredWidth, requiredHeight)
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
end

ISHandcraftWindowHeader.calculateLayout = createHeaderCalculateLayout(
    ISHandcraftWindowHeader.calculateLayout
)

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

ISWidgetEntityHeader.calculateLayout = createHeaderCalculateLayout(
    ISWidgetEntityHeader.calculateLayout
)

local originalEntityWindowPrerender = ISEntityWindow.prerender
ISEntityWindow.prerender = function(self, ...)
    local result = originalEntityWindowPrerender(self, ...)
    local header = self.entityHeader
    local title = header and header.cpoWindowTitle

    if title and title ~= "" and getEntityCraftBenchPanel(self) then
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
