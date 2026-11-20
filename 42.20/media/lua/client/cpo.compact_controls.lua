require "Entity/ISUI/CraftRecipe/ISWidgetHandCraftControl"

if ISWidgetHandCraftControl._cpoCompactHookInstalled then
    return
end

local UI_BORDER_SPACING = 3
local PACIFIST_PENALTIES = {
    [Perks.SmallBlade] = true,
    [Perks.LongBlade] = true,
    [Perks.SmallBlunt] = true,
    [Perks.Spear] = true,
    [Perks.Blunt] = true,
    [Perks.Axe] = true,
    [Perks.Aiming] = true,
}

local function getXpAmountPerCraft(player, xpEntry)
    local amount = xpEntry.amount
    local perk = xpEntry.perk
    local perkType = perk:getType()
    local characterTraits = player:getCharacterTraits()
    local isSpeedReductionExcluded = perkType == Perks.Sprinting
        or perkType == Perks.Fitness
        or perkType == Perks.Strength
    local isSpeedIncreaseExcluded = perkType == Perks.Fitness
        or perkType == Perks.Strength
    local xpBoost = player:getXp():getPerkBoost(perkType)

    if xpBoost == 0 then
        if not isSpeedReductionExcluded then
            amount = amount * 0.25
        end
    elseif xpBoost == 1 and perkType == Perks.Sprinting then
        amount = amount * 1.25
    elseif xpBoost == 2 and not isSpeedIncreaseExcluded then
        amount = amount * 1.33
    elseif xpBoost >= 3 and not isSpeedIncreaseExcluded then
        amount = amount * 1.66
    end

    if characterTraits:get(CharacterTrait.FAST_LEARNER)
        and not isSpeedIncreaseExcluded then
        amount = amount * 1.3
    end

    if characterTraits:get(CharacterTrait.SLOW_LEARNER)
        and not isSpeedReductionExcluded then
        amount = amount * 0.7
    end

    if characterTraits:get(CharacterTrait.PACIFIST) and PACIFIST_PENALTIES[perkType] then
        amount = amount * 0.75
    end

    if characterTraits:get(CharacterTrait.CRAFTY)
        and perk:getParent() == Perks.Crafting then
        amount = amount * 1.3
    end

    local perkMultiplier = player:getXp():getMultiplier(perk)

    if perkMultiplier > 1 then
        amount = amount * perkMultiplier
    end

    local sandboxOptions = getSandboxOptions()
    local globalMultiplierEnabled = sandboxOptions
        :getOptionByName("MultiplierConfig.GlobalToggle")
        :getValue()
    local multiplierName = globalMultiplierEnabled
        and "MultiplierConfig.Global"
        or "MultiplierConfig." .. tostring(perkType)
    local multiplierOption = sandboxOptions:getOptionByName(multiplierName)

    return round(amount * multiplierOption:getValue(), 2)
end

local originalHandCraftCreateChildren = ISWidgetHandCraftControl.createChildren

ISWidgetHandCraftControl.createChildren = function(self, ...)
    local result = originalHandCraftCreateChildren(self, ...)
    self.xpLabels = {}

    local recipe = self.logic and self.logic:getRecipe()

    if recipe then
        for index = 0, recipe:getXPAwardCount() - 1 do
            local award = recipe:getXPAward(index)
            local perk = award:getPerk()

            local label = ISXuiSkin.build(
                self.xuiSkin,
                "S_NeedsAStyle",
                ISLabel,
                0,
                0,
                self.buttonCraft:getHeight(),
                "",
                1,
                1,
                1,
                1,
                UIFont.Small,
                true
            )

            label:initialise()
            label:instantiate()
            self:addChild(label)

            table.insert(self.xpLabels, {
                label = label,
                perk = perk,
                perkName = perk:getName(),
                amount = award:getAmount(),
            })
        end
    end

    return result
end

ISWidgetHandCraftControl.calculateLayout = function(self, preferredWidth, preferredHeight)
    local width = math.max(self.minimumWidth or 0, preferredWidth or 0)
    local height = math.max(self.minimumHeight or 0, preferredHeight or 0)
    local buttonHeight = self.buttonCraft:getHeight()
    local x = UI_BORDER_SPACING + 1
    local y = x

    local leftSideWidth = self.buttonLess:getWidth()
        + self.entryBox:getWidth()
        + self.buttonMore:getWidth()
        + self.buttonMax:getWidth()
        + UI_BORDER_SPACING * 3
    local craftButtonMinWidth = math.max(
        buttonHeight * 2,
        getTextManager():MeasureStringX(self.buttonCraft.font, self.buttonCraft.title)
            + UI_BORDER_SPACING * 2
            + 2
    )
    local minWidth = craftButtonMinWidth + x * 2

    if self.allowBatchCraft then
        minWidth = math.max(
            minWidth,
            leftSideWidth + UI_BORDER_SPACING + craftButtonMinWidth + x * 2
        )
    end

    local xpLabels = self.xpLabels or {}
    local rows = 2 + #xpLabels

    if self.buttonForceCraft then
        rows = rows + 1
    end

    if self.buttonKnowAllRecipes then
        rows = rows + 1
    end

    local minHeight = buttonHeight * rows + UI_BORDER_SPACING * (rows + 1) + 2
    width = math.max(width, minWidth)
    height = math.max(height, minHeight)

    self.quantityLabel:setVisible(false)
    self.buttonLess:setVisible(self.allowBatchCraft)
    self.entryBox:setVisible(self.allowBatchCraft)
    self.buttonMore:setVisible(self.allowBatchCraft)
    self.buttonMax:setVisible(self.allowBatchCraft)

    if self.allowBatchCraft then
        self.buttonLess:setX(x)
        self.buttonLess:setY(y)
        self.entryBox:setX(self.buttonLess:getRight() + UI_BORDER_SPACING)
        self.entryBox:setY(y)
        self.buttonMore:setX(self.entryBox:getRight() + UI_BORDER_SPACING)
        self.buttonMore:setY(y)
        self.buttonMax:setX(self.buttonMore:getRight() + UI_BORDER_SPACING)
        self.buttonMax:setY(y)
    end

    self.durationLabel:setVisible(false)
    if self.allowBatchCraft then
        local craftX = x + leftSideWidth + UI_BORDER_SPACING
        self.buttonCraft:setX(craftX)
        self.buttonCraft:setWidth(width - craftX - x)
    else
        self.buttonCraft:setX(x)
        self.buttonCraft:setWidth(width - x * 2)
    end
    self.buttonCraft:setY(y)
    y = y + buttonHeight + UI_BORDER_SPACING

    for _, xpEntry in ipairs(xpLabels) do
        xpEntry.label:setWidthToName(0)
        xpEntry.label:setX(math.floor((width - xpEntry.label:getWidth()) / 2))
        xpEntry.label:setY(y)
        y = y + buttonHeight + UI_BORDER_SPACING
    end

    self.progressBar:setX(x)
    self.progressBar:setWidth(width - x * 2)
    self.progressBar:setY(y)
    y = y + buttonHeight + UI_BORDER_SPACING

    if self.buttonForceCraft then
        self.buttonForceCraft:setX(x)
        self.buttonForceCraft:setWidth(width - x * 2)
        self.buttonForceCraft:setY(y)
        y = self.buttonForceCraft:getBottom() + UI_BORDER_SPACING
    end

    if self.buttonKnowAllRecipes then
        self.buttonKnowAllRecipes:setX(x)
        self.buttonKnowAllRecipes:setWidth(width - x * 2)
        self.buttonKnowAllRecipes:setY(y)
    end

    self.boxHeight = height
    self:setWidth(width)
    self:setHeight(height)

    local joypadState = self:recordJoypadState()
    self.joypadButtonsY = {}
    self.joypadButtons = {}
    self.joypadIndexY = 1
    self.joypadIndex = 1
    if self.buttonLess:isVisible() then
        self:insertNewLineOfButtons(self.buttonLess, self.buttonMore, self.buttonMax, self.buttonCraft)
    else
        self:insertNewLineOfButtons(self.buttonCraft)
    end
    if self.buttonForceCraft then
        self:insertNewLineOfButtons(self.buttonForceCraft)
    end
    self:restoreJoypadState(joypadState)
end

local originalHandCraftPrerender = ISWidgetHandCraftControl.prerender

ISWidgetHandCraftControl.prerender = function(self, ...)
    local result = originalHandCraftPrerender(self, ...)
    local quantity = 1

    if self.allowBatchCraft then
        quantity = tonumber(self.entryBox:getInternalText())
    end

    local xpLabels = self.xpLabels or {}
    for _, xpEntry in ipairs(xpLabels) do
        local amountPerCraft = getXpAmountPerCraft(self.player, xpEntry)
        local text

        if quantity then
            text = string.format(
                "%s: %s x %s = %s XP",
                xpEntry.perkName,
                tostring(amountPerCraft),
                tostring(quantity),
                tostring(round(amountPerCraft * quantity, 2))
            )
        else
            text = string.format("%s: %s XP/craft", xpEntry.perkName, tostring(amountPerCraft))
        end

        if xpEntry.label:getName() ~= text then
            xpEntry.label:setNameWithoutMoving(text)
        end
        xpEntry.label:setX(math.floor((self.width - xpEntry.label:getWidth()) / 2))
    end

    if self.durationLabel then
        local label = self.durationLabel
        local labelText = label:getName()
        local prefix = getText("IGUI_CraftingWindow_TimeRequired")
        local duration = labelText

        if labelText:sub(1, #prefix) == prefix then
            duration = labelText:sub(#prefix + 1):gsub("^%s+", "")
        end

        if labelText ~= duration then
            label:setNameWithoutMoving(duration)
        end

        if self.progressBar and not self.logic:isCraftActionInProgress() then
            self.progressBar:setText(duration)
        end
    end
    return result
end

ISWidgetHandCraftControl._cpoCompactHookInstalled = true
