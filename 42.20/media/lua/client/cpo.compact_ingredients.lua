require "Entity/ISUI/CraftRecipe/ISWidgetInput"
require "Entity/ISUI/CraftRecipe/ISWidgetOutput"
require "Entity/ISUI/CraftRecipe/ISWidgetIngredientsInputs"
require "Entity/ISUI/CraftRecipe/ISWidgetIngredientsOutputs"

if ISWidgetIngredientsInputs._cpoCompactHookInstalled then
    return
end

local UI_BORDER_SPACING = 3
local ITEM_BORDER_SPACING = 4
local OUTPUT_CARD_INSET = 2
local MAX_GRID_COLUMNS = 4
local MAX_INPUT_COLUMNS = 2
local ITEM_ICON_SCALE = 0.55
local ITEM_CARD_WIDTH_SCALE = 1.05

local function getGridColumns(itemCount, maxColumns)
    return math.max(1, math.min(maxColumns or MAX_GRID_COLUMNS, itemCount))
end

local function compactItemWidget(widget)
    widget.iconSize = math.max(24, math.floor(widget.iconSize * ITEM_ICON_SCALE + 0.5))
    widget.labelIconSize = math.max(12, math.floor(widget.labelIconSize * 0.8 + 0.5))

    if widget.selectInputButtonSize then
        widget.selectInputButtonSize = math.max(10, math.floor(widget.selectInputButtonSize * 0.50 + 0.5))
    end

    widget.iconBorderSizeX = ITEM_BORDER_SPACING * 2 + widget.iconSize * ITEM_CARD_WIDTH_SCALE
    widget.cpoBaseIconBorderSizeX = widget.iconBorderSizeX
    widget.iconBorderSizeY = ITEM_BORDER_SPACING * 2 + widget.iconSize

    return widget
end

local function getMinimumItemSize(items)
    local minWidth = 0
    local minHeight = 0

    for _, item in ipairs(items) do
        item.iconBorderSizeX = item.cpoBaseIconBorderSizeX or item.iconBorderSizeX
        item:calculateLayout(0, 0)
        minWidth = math.max(minWidth, item:getWidth())
        minHeight = math.max(minHeight, item:getHeight())
    end

    return minWidth, minHeight
end

local function centerInputIcons(widget)
    local primary = widget.primary
    if primary and primary.icon then
        primary.icon:setX(math.floor((widget.iconBorderSizeX - primary.icon:getWidth()) / 2))
    end

    local secondary = widget.secondary
    if secondary and secondary.icon then
        secondary.icon:setX(math.floor((widget.iconBorderSizeX - secondary.icon:getWidth()) / 2))
    end
end

local function layoutCompactInputCard(widget, preferredHeight)
    local primary = widget.primary
    local itemNameLabel = primary and primary.itemNameLabel

    if not itemNameLabel then
        return
    end

    local secondary = widget.secondary
    local itemName = secondary and secondary.iconText or primary.iconText or ""

    if primary.isItemCount and secondary and secondary.iconText then
        itemName = getText("IGUI_CraftingWindow_InputWithContents", primary.iconText, secondary.iconText)
    end

    local cursorX = ITEM_BORDER_SPACING + widget.iconSize + ITEM_BORDER_SPACING
    local arrow = widget.arrow

    if arrow then
        arrow:setX(cursorX)
        cursorX = cursorX + arrow:getWidth() + ITEM_BORDER_SPACING
    end

    local statusIcon = widget.iconTool:isVisible() and widget.iconTool

    if statusIcon then
        statusIcon:setX(cursorX)
        cursorX = cursorX + statusIcon:getWidth() + ITEM_BORDER_SPACING
    end

    local button = primary.selectInputButton
    local buttonWidth = button and button:isVisible() and button:getWidth() + ITEM_BORDER_SPACING or 0
    local labelWidth = math.max(1, widget.width - cursorX - ITEM_BORDER_SPACING - buttonWidth)
    local text = getTextManager():WrapText(itemNameLabel.font, itemName, labelWidth, 2, "...")
    local textHeight = getTextManager():MeasureStringY(itemNameLabel.font, text)
    local cardHeight = math.max(widget.iconSize, textHeight) + ITEM_BORDER_SPACING * 2
    cardHeight = math.max(cardHeight, preferredHeight or 0)

    widget.iconBorderSizeY = cardHeight
    widget:setHeight(cardHeight)
    primary.icon:setX(ITEM_BORDER_SPACING)
    primary.icon:setY(math.floor((cardHeight - primary.icon:getHeight()) / 2))

    if secondary and secondary.icon then
        secondary.icon:setX(ITEM_BORDER_SPACING)
        secondary.icon:setY(math.floor((cardHeight - secondary.icon:getHeight()) / 2))
    end

    local amountLabel = secondary and secondary.label or primary.label
    amountLabel:setX(math.max(ITEM_BORDER_SPACING, ITEM_BORDER_SPACING + widget.iconSize - amountLabel:getWidth()))
    amountLabel:setY(cardHeight - ITEM_BORDER_SPACING - amountLabel:getHeight())

    if arrow then
        arrow:setY(math.floor((cardHeight - arrow:getHeight()) / 2))
    end

    if statusIcon then
        statusIcon:setY(math.floor((cardHeight - statusIcon:getHeight()) / 2))
    end

    itemNameLabel:setX(cursorX)
    itemNameLabel.originalX = cursorX
    itemNameLabel:setY(math.floor((cardHeight - textHeight) / 2))
    itemNameLabel:setHeight(textHeight)
    itemNameLabel:setName(text)
end

local function getResultItemName(widget)
    if not widget.primary then
        return ""
    end

    local itemName = widget.secondary and widget.secondary.iconText or widget.primary.iconText or ""

    if widget.displayAsOutput
        and widget.primary.isItemCount
        and widget.primary.iconText
        and widget.secondary
        and widget.secondary.iconText then
        itemName = getText("IGUI_CraftingWindow_InputWithContents", widget.primary.iconText, widget.secondary.iconText)
    end

    return itemName
end

local function getMinimumOutputWidth(outputs)
    local minWidth = 0

    for _, output in ipairs(outputs) do
        local itemNameLabel = output.primary and output.primary.itemNameLabel
        if itemNameLabel then
            output.cpoResultLabelWidth = getTextManager():MeasureStringX(
                itemNameLabel.font,
                getResultItemName(output)
            )
        end

        output:calculateLayout(0, 0)
        minWidth = math.max(minWidth, output:getWidth())
        output.cpoResultLabelWidth = nil
    end

    return minWidth
end

local function applyFullResultLabel(widget, availableWidth)
    local itemNameLabel = widget.primary and widget.primary.itemNameLabel
    local itemName = getResultItemName(widget)

    if not itemNameLabel or itemName == "" then
        return
    end

    local labelX = widget.labelIconSize + ITEM_BORDER_SPACING
    local labelWidth = math.max(1, availableWidth - ITEM_BORDER_SPACING * 2)
    local wrappedText = getTextManager():WrapText(
        itemNameLabel.font,
        itemName,
        labelWidth,
        1,
        "..."
    )

    itemNameLabel:setX(labelX)
    itemNameLabel.originalX = labelX
    itemNameLabel.tooltip = itemName
    itemNameLabel:setName(wrappedText)
    itemNameLabel:setWidth(labelWidth)
    itemNameLabel:setHeight(getTextManager():getFontHeight(itemNameLabel.font))
end

local originalInputNew = ISWidgetInput.new

ISWidgetInput.new = function(self, ...)
    return compactItemWidget(originalInputNew(self, ...))
end

local originalOutputNew = ISWidgetOutput.new

ISWidgetOutput.new = function(self, ...)
    return compactItemWidget(originalOutputNew(self, ...))
end

local originalInputCalculateLayout = ISWidgetInput.calculateLayout

ISWidgetInput.calculateLayout = function(self, preferredWidth, preferredHeight)
    if self.displayAsOutput then
        local result = originalInputCalculateLayout(self, preferredWidth, preferredHeight)
        centerInputIcons(self)

        if self.cpoResultLabelWidth then
            applyFullResultLabel(self, self.cpoResultLabelWidth)
        end

        return result
    end

    self.iconBorderSizeY = ITEM_BORDER_SPACING * 2 + self.iconSize

    local result = originalInputCalculateLayout(self, preferredWidth, preferredHeight)
    layoutCompactInputCard(self, preferredHeight)
    return result
end

local originalInputUpdateValues = ISWidgetInput.updateValues
ISWidgetInput.updateValues = function(self, ...)
    local result = originalInputUpdateValues(self, ...)

    if not self.displayAsOutput and self.primary and self.primary.icon then
        self.iconConsumed:setVisible(false)
        self.iconReturned:setVisible(false)

        local statusText = self.primary.isKeep
            and getText("IGUI_CraftingWindow_WillBeKept")
            or self.iconConsumed.mouseovertext
        local tooltip = self.primary.icon.mouseovertext
        if statusText and tooltip then
            self.primary.icon:setMouseOverText(tooltip .. " <BR> " .. statusText)
        end
    end

    return result
end

local originalOutputCalculateLayout = ISWidgetOutput.calculateLayout

ISWidgetOutput.calculateLayout = function(self, preferredWidth, preferredHeight)
    local result = originalOutputCalculateLayout(self, preferredWidth, preferredHeight)
    local labelWidth = self.cpoResultLabelWidth
        or (self.width - self.labelIconSize - UI_BORDER_SPACING)
    applyFullResultLabel(self, labelWidth)

    local itemNameLabel = self.primary and self.primary.itemNameLabel
    if itemNameLabel then
        self:setHeight(math.max(
            self.minimumHeight or 0,
            itemNameLabel:getBottom()
        ))
    end

    return result
end

ISWidgetIngredientsInputs.calculateLayout = function(self, preferredWidth, preferredHeight)
    local width = math.max(self.minimumWidth or 0, preferredWidth or 0)
    local height = math.max(self.minimumHeight or 0, preferredHeight or 0)

    local minWidth = UI_BORDER_SPACING * 2
    local minHeight = UI_BORDER_SPACING
    minWidth = math.max(minWidth, minWidth + self.inputsLabel:getWidth())
    minHeight = minHeight + self.inputsLabel:getHeight() + UI_BORDER_SPACING

    local minInputWidth, minInputHeight = getMinimumItemSize(self.inputs)

    local inputCount = #self.inputs
    local columns = getGridColumns(inputCount, MAX_INPUT_COLUMNS)
    local rows = math.max(1, math.ceil(inputCount / columns))
    local contentHeight = minInputHeight * rows + UI_BORDER_SPACING * rows
    local visibleRows = math.min(2, rows)
    local panelHeight = minInputHeight * visibleRows + UI_BORDER_SPACING * visibleRows

    minHeight = minHeight + panelHeight
    minWidth = math.max(
        minWidth,
        UI_BORDER_SPACING * (columns + 1) + minInputWidth * columns + 2
    )
    if rows > visibleRows then
        minWidth = minWidth + UI_BORDER_SPACING
    end

    width = math.max(width, minWidth)
    height = math.max(height, minHeight)

    if self.panel.vscroll then
        self.panel.vscroll:setX(width - self.panel.vscroll.width)
        self.panel.vscroll:setY(0)
        self.panel.vscroll:setHeight(panelHeight)
    end

    self.panel:setScrollHeight(contentHeight)
    self.panel:setWidth(width)
    self.panel:setHeight(panelHeight)

    local x = UI_BORDER_SPACING + 1
    local y = x
    local inputCellWidth = math.max(
        minInputWidth,
        math.floor((width - UI_BORDER_SPACING * (columns + 1) - 2) / columns)
    )

    self.inputsLabel:setX(x)
    self.inputsLabel.originalX = x
    self.inputsLabel:setY(y)

    local joypadState = self:recordJoypadState()
    self.joypadButtons = {}
    self.joypadButtonsY = {}

    local column = 0
    local row = 0

    for _, input in ipairs(self.inputs) do
        input.iconBorderSizeX = inputCellWidth
        input:calculateLayout(inputCellWidth, minInputHeight)
        input:setX(UI_BORDER_SPACING + column * (inputCellWidth + UI_BORDER_SPACING))
        input:setY(UI_BORDER_SPACING + row * (minInputHeight + UI_BORDER_SPACING))

        table.insert(self.joypadButtons, input)
        column = column + 1
        if column >= columns then
            column = 0
            row = row + 1
            table.insert(self.joypadButtonsY, self.joypadButtons)
            self.joypadButtons = {}
        end
    end

    if #self.joypadButtons > 0 then
        table.insert(self.joypadButtonsY, self.joypadButtons)
    end

    self:restoreJoypadState(joypadState)
    self:setWidth(width)
    self:setHeight(height)
end

ISWidgetIngredientsOutputs.calculateLayout = function(self, preferredWidth, preferredHeight)
    local width = math.max(self.minimumWidth or 0, preferredWidth or 0)

    local minWidth = UI_BORDER_SPACING * 2
    minWidth = math.max(minWidth, minWidth + self.outputsLabel:getWidth())

    local minOutputWidth = getMinimumOutputWidth(self.outputs)

    local outputCount = #self.outputs
    local columns = getGridColumns(outputCount)
    local rows = math.max(1, math.ceil(outputCount / columns))

    minWidth = math.max(
        minWidth,
        UI_BORDER_SPACING * (columns + 1)
            + OUTPUT_CARD_INSET
            + minOutputWidth * columns
            + 2
    )

    width = math.max(width, minWidth)

    local labelX = UI_BORDER_SPACING + 1
    self.outputsLabel:setX(labelX)
    self.outputsLabel.originalX = labelX
    self.outputsLabel:setY(labelX)

    local outputTop = self.outputsLabel:getY()
        + self.outputsLabel:getHeight()
        + UI_BORDER_SPACING
        - 4
    local outputCellWidth = math.max(
        minOutputWidth,
        math.floor((
            width
                - UI_BORDER_SPACING * (columns + 1)
                - OUTPUT_CARD_INSET
                - 2
        ) / columns)
    )
    local measureOnly = (preferredWidth or 0) <= 0
    local outputHeight = 0

    for _, output in ipairs(self.outputs) do
        output.iconBorderSizeX = outputCellWidth
        local itemNameLabel = output.primary and output.primary.itemNameLabel
        local labelWidth = math.max(
            1,
            outputCellWidth - output.labelIconSize - ITEM_BORDER_SPACING
        )
        if measureOnly and itemNameLabel then
            labelWidth = getTextManager():MeasureStringX(
                itemNameLabel.font,
                getResultItemName(output)
            )
        end
        output.cpoResultLabelWidth = labelWidth
        output:calculateLayout(outputCellWidth, 0)
        outputHeight = math.max(outputHeight, output:getHeight())
    end

    local column = 0
    local row = 0
    for _, output in ipairs(self.outputs) do
        local x = UI_BORDER_SPACING + OUTPUT_CARD_INSET
            + column * (outputCellWidth + UI_BORDER_SPACING)
        output:setX(x)
        output:setY(outputTop + row * (outputHeight + UI_BORDER_SPACING))

        column = column + 1
        if column >= columns then
            column = 0
            row = row + 1
        end
    end

    local height = math.max(
        self.minimumHeight or 0,
        UI_BORDER_SPACING + self.outputsLabel:getHeight() + UI_BORDER_SPACING
            + outputHeight * rows + UI_BORDER_SPACING * (rows - 1)
    )
    self:setWidth(width)
    self:setHeight(height)
end

ISWidgetIngredientsInputs._cpoCompactHookInstalled = true
