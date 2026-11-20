require "Entity/ISUI/CraftRecipe/ISHandCraftPanel"
require "Entity/ISUI/CraftRecipe/ISCraftRecipePanel"

if ISHandCraftPanel._cpoCompactLayoutHookInstalled then
    return
end

local function reduceCellPadding(tableLayout, elements, padding)
    for _, element in ipairs(elements) do
        local cell = tableLayout:cellFor(element)
        if cell then
            cell.padding = padding
        end
    end
end

local originalHandCraftPanelCreateChildren = ISHandCraftPanel.createChildren

ISHandCraftPanel.createChildren = function(self, ...)
    local result = originalHandCraftPanelCreateChildren(self, ...)

    reduceCellPadding(self.rootTable, {
        self.inventoryPanel,
        self.recipePanel,
        self.recipesPanel,
        self.recipeCategories,
    }, 2)

    if self.recipePanel then
        self.recipePanel.minimumWidth = math.min(self.recipePanel.minimumWidth or 220, 220)
    end

    return result
end

local originalHandCraftPanelOnRecipeChanged = ISHandCraftPanel.onRecipeChanged
ISHandCraftPanel.onRecipeChanged = function(self, ...)
    local result = originalHandCraftPanelOnRecipeChanged(self, ...)
    local window = self.parent

    if window then
        window:xuiRecalculateLayout(nil, 0, true)
    end

    return result
end

local originalRecipeCreateDynamicChildren = ISCraftRecipePanel.createDynamicChildren

ISCraftRecipePanel.createDynamicChildren = function(self, ...)
    local result = originalRecipeCreateDynamicChildren(self, ...)

    reduceCellPadding(self.rootTable, {
        self.titleWidget,
        self.inputs,
        self.craftControl,
        self.outputs,
    }, 1)

    for _, row in ipairs(self.rootTable.rows) do
        row.isAutoFill = false
    end

    self:xuiRecalculateLayout()
    return result
end

ISHandCraftPanel._cpoCompactLayoutHookInstalled = true
