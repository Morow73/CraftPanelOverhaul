require "ISUI/Crafting/ISHandcraftWindow"
require "Entity/ISUI/CraftRecipe/ISHandCraftPanel"
require "Entity/ISUI/CraftRecipe/ISCraftRecipePanel"
require "Entity/ISUI/CraftRecipe/ISWidgetIngredientsInputs"
require "Entity/ISUI/CraftRecipe/ISWidgetIngredientsOutputs"
require "Entity/ISUI/CraftRecipe/ISWidgetInput"
require "Entity/ISUI/CraftRecipe/ISWidgetOutput"

if ISHandcraftWindow._cpoThemeHookInstalled then
    return
end

local COLORS = {
    panel = { r = 0.08, g = 0.075, b = 0.068 },
    surface = { r = 0.11, g = 0.10, b = 0.09 },
    card = { r = 0.14, g = 0.12, b = 0.10, a = 0.32 },
    border = { r = 0.34, g = 0.31, b = 0.27 },
    cardBorder = { r = 0.40, g = 0.36, b = 0.30, a = 1 },
    accent = { r = 0.92, g = 0.55, b = 0.28, a = 1 },
    text = { r = 0.91, g = 0.89, b = 0.84, a = 1 },
    selection = { r = 0.48, g = 0.25, b = 0.12, a = 0.48 },
    hover = { r = 0.72, g = 0.43, b = 0.22, a = 0.16 },
}
local MINIMUM_CRAFT_WINDOW_HEIGHT = 300

local function setPanelColors(panel, background, border)
    if not panel then
        return
    end

    if background and panel.backgroundColor then
        panel.backgroundColor.r = background.r
        panel.backgroundColor.g = background.g
        panel.backgroundColor.b = background.b
    end

    if border and panel.borderColor then
        panel.borderColor.r = border.r
        panel.borderColor.g = border.g
        panel.borderColor.b = border.b
    end
end

local function setItemLabelFonts(widget)
    if not widget or widget.cpoThemeItemFontsApplied then
        return
    end

    local function setSmallFont(label)
        if label then
            label.font = UIFont.NewSmall
            label:setHeightToName(0)
            label:setWidthToName(0)
        end
    end

    local primary = widget.primary
    if primary then
        setSmallFont(primary.label)
        setSmallFont(primary.itemNameLabel)
    end

    local secondary = widget.secondary
    if secondary then
        setSmallFont(secondary.label)
        setSmallFont(secondary.itemNameLabel)
    end
    widget.cpoThemeItemFontsApplied = true
end

local function setLabelStyle(label, color, font)
    if not label then
        return
    end

    local alpha = color.a or 1
    label.r = color.r
    label.g = color.g
    label.b = color.b
    label.a = alpha
    label.textColor = { r = color.r, g = color.g, b = color.b, a = alpha }

    if font then
        label.font = font
        label:setWidthToName(0)
        label:setHeightToName(0)
    end
end

local function setListStyle(list)
    if not list then
        return
    end

    setPanelColors(list, COLORS.surface, COLORS.border)
    list.selectionColor = {
        r = COLORS.selection.r,
        g = COLORS.selection.g,
        b = COLORS.selection.b,
        a = COLORS.selection.a,
    }
    list.mouseOverHighlightColor = {
        r = COLORS.hover.r,
        g = COLORS.hover.g,
        b = COLORS.hover.b,
        a = COLORS.hover.a,
    }
    list.textColor = { r = COLORS.text.r, g = COLORS.text.g, b = COLORS.text.b, a = COLORS.text.a }
    list.selectedTextColor = { r = COLORS.text.r, g = COLORS.text.g, b = COLORS.text.b, a = COLORS.text.a }
end

local function setItemStyle(widget)
    if not widget then
        return widget
    end

    widget.background = true
    widget.backgroundColor = { r = COLORS.card.r, g = COLORS.card.g, b = COLORS.card.b, a = COLORS.card.a }
    widget.borderColor = {
        r = COLORS.cardBorder.r,
        g = COLORS.cardBorder.g,
        b = COLORS.cardBorder.b,
        a = COLORS.cardBorder.a,
    }
    widget.normalBorderColor = {
        r = COLORS.cardBorder.r,
        g = COLORS.cardBorder.g,
        b = COLORS.cardBorder.b,
        a = COLORS.cardBorder.a,
    }
    widget.textColor = { r = COLORS.text.r, g = COLORS.text.g, b = COLORS.text.b, a = COLORS.text.a }
    return widget
end

local originalInputNew = ISWidgetInput.new
ISWidgetInput.new = function(self, ...)
    return setItemStyle(originalInputNew(self, ...))
end

local originalOutputNew = ISWidgetOutput.new
ISWidgetOutput.new = function(self, ...)
    return setItemStyle(originalOutputNew(self, ...))
end

local originalInputCalculateLayout = ISWidgetInput.calculateLayout
ISWidgetInput.calculateLayout = function(self, ...)
    setItemLabelFonts(self)
    return originalInputCalculateLayout(self, ...)
end

local originalOutputCalculateLayout = ISWidgetOutput.calculateLayout
ISWidgetOutput.calculateLayout = function(self, ...)
    setItemLabelFonts(self)
    return originalOutputCalculateLayout(self, ...)
end

local originalInputsCreateChildren = ISWidgetIngredientsInputs.createChildren
ISWidgetIngredientsInputs.createChildren = function(self, ...)
    local result = originalInputsCreateChildren(self, ...)
    setLabelStyle(self.inputsLabel, COLORS.accent, UIFont.Small)
    setPanelColors(self, nil, COLORS.border)
    return result
end

local originalOutputsCreateChildren = ISWidgetIngredientsOutputs.createChildren
ISWidgetIngredientsOutputs.createChildren = function(self, ...)
    local result = originalOutputsCreateChildren(self, ...)
    setLabelStyle(self.outputsLabel, COLORS.accent, UIFont.Small)
    setPanelColors(self, nil, COLORS.border)
    return result
end

local function applyRecipeTheme(recipePanel)
    if not recipePanel then
        return
    end

    local titleWidget = recipePanel.titleWidget
    local craftControl = recipePanel.craftControl

    setPanelColors(recipePanel, COLORS.panel, COLORS.border)
    setPanelColors(titleWidget, COLORS.surface, COLORS.border)
    if titleWidget then
        setLabelStyle(titleWidget.titleLabel, COLORS.text)
    end

    setPanelColors(recipePanel.inputs, COLORS.panel, COLORS.border)
    setPanelColors(recipePanel.outputs, COLORS.panel, COLORS.border)
    setPanelColors(craftControl, COLORS.surface, COLORS.border)

    if craftControl then
        setLabelStyle(craftControl.durationLabel, COLORS.text)
        for _, entry in ipairs(craftControl.xpLabels or {}) do
            setLabelStyle(entry.label, COLORS.text)
        end
    end
end

local originalRecipeCreateDynamicChildren = ISCraftRecipePanel.createDynamicChildren
ISCraftRecipePanel.createDynamicChildren = function(self, ...)
    local result = originalRecipeCreateDynamicChildren(self, ...)
    applyRecipeTheme(self)
    return result
end

local function applyHandCraftTheme(handCraftPanel)
    if not handCraftPanel then
        return
    end

    local categories = handCraftPanel.recipeCategories
    local categoryList = categories and categories.recipeCategoryPanel
    local recipes = handCraftPanel.recipesPanel
    local recipeListPanel = recipes and recipes.recipeListPanel

    setPanelColors(handCraftPanel, COLORS.panel, COLORS.border)
    setPanelColors(categories, COLORS.panel, COLORS.border)
    setPanelColors(categoryList, COLORS.surface, COLORS.border)
    setPanelColors(recipes, COLORS.panel, COLORS.border)
    setPanelColors(recipes and recipes.recipeFilterPanel, COLORS.surface, COLORS.border)
    setPanelColors(recipeListPanel, COLORS.panel, COLORS.border)
    setPanelColors(recipes and recipes.recipeIconPanel, COLORS.panel, COLORS.border)
    setPanelColors(handCraftPanel.inventoryPanel, COLORS.surface, COLORS.border)

    setListStyle(recipeListPanel and recipeListPanel.recipeListPanel)
    setListStyle(categoryList)

    applyRecipeTheme(handCraftPanel.recipePanel)
end

local originalHandCraftPanelCreateChildren = ISHandCraftPanel.createChildren
ISHandCraftPanel.createChildren = function(self, ...)
    local result = originalHandCraftPanelCreateChildren(self, ...)
    applyHandCraftTheme(self)
    return result
end

local function resizeFromMouse(widget)
    if not widget.resizing then
        return
    end

    local width = widget.resizeStartWidth + getMouseX() - widget.resizeStartMouseX
    local height = widget.resizeStartHeight + getMouseY() - widget.resizeStartMouseY
    if widget.yonly then
        width = widget.resizeStartWidth
    end

    widget:resize(width - widget.target.width, height - widget.target.height)
end

local function installStableResize(widget)
    if not widget or widget._cpoStableResize then
        return
    end

    widget._cpoStableResize = true
    widget.onMouseDown = function(self)
        if not self:getIsVisible() then
            return
        end

        self.resizeStartMouseX = getMouseX()
        self.resizeStartMouseY = getMouseY()
        self.resizeStartWidth = self.target:getWidth()
        self.resizeStartHeight = self.target:getHeight()
        self.resizing = true
        self:setCapture(true)
        return true
    end
    widget.onMouseMove = function(self)
        self.mouseOver = true
        resizeFromMouse(self)
    end
    widget.onMouseMoveOutside = function(self)
        self.mouseOver = false
        resizeFromMouse(self)
    end
    local function stopResize(self)
        self.resizing = false
        self:setCapture(false)
        return true
    end
    widget.onMouseUp = stopResize
    widget.onMouseUpOutside = stopResize
end

local originalWindowCalculateLayout = ISHandcraftWindow.calculateLayout
ISHandcraftWindow.calculateLayout = function(self, preferredWidth, preferredHeight)
    if self.cpoFitInitialHeight then
        preferredHeight = 0
        self.cpoFitInitialHeight = false
    end

    local result = originalWindowCalculateLayout(self, preferredWidth, preferredHeight)
    local resizeHandleSize = self:resizeWidgetHeight()

    if self.resizeWidget then
        self.resizeWidget:setX(self:getWidth() - resizeHandleSize)
        self.resizeWidget:setY(self:getHeight() - resizeHandleSize)
        self.resizeWidget:setWidth(resizeHandleSize)
        self.resizeWidget:setHeight(resizeHandleSize)
    end
    if self.resizeWidget2 then
        self.resizeWidget2:setX(0)
        self.resizeWidget2:setY(self:getHeight() - resizeHandleSize)
        self.resizeWidget2:setWidth(math.max(0, self:getWidth() - resizeHandleSize))
        self.resizeWidget2:setHeight(resizeHandleSize)
    end

    return result
end

local originalWindowCreateChildren = ISHandcraftWindow.createChildren
ISHandcraftWindow.createChildren = function(self, ...)
    local result = originalWindowCreateChildren(self, ...)
    installStableResize(self.resizeWidget)
    installStableResize(self.resizeWidget2)
    setPanelColors(self, COLORS.panel, COLORS.border)
    setPanelColors(self.windowHeader, COLORS.surface, COLORS.border)
    setLabelStyle(self.windowHeader and self.windowHeader.transparencyLabel, COLORS.text)
    applyHandCraftTheme(self.handCraftPanel)
    self.minimumHeight = MINIMUM_CRAFT_WINDOW_HEIGHT
    self.cpoFitInitialHeight = true
    self:xuiRecalculateLayout(nil, 0, true)
    return result
end

ISHandcraftWindow._cpoThemeHookInstalled = true
