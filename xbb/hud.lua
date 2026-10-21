--[[
XBB / Buff bar display
Renders model row groups as native components under the game-area interface.
Manages bars, scrolling, hover details, and Ctrl-click movement.
Routes bar-menu actions and saved positions through local settings.
Reuses bar components for updates and destroys them on teardown.
]]

local UI = require("xbb/ui")
local Actions = require("xbb/actions")
local Model = require("xbb/model")
local Hud = {}
Hud.__index = Hud

local function position(config, kind)
    if kind == "debuff" then return config.debuffX, config.debuffY end
    return config.x, config.y
end

function Hud:bindDrag(component, stack)
    component.clickthrough = false
    component.enabled = true
    component:Subscribe(ui.Hook.ONCLICK, function() self:beginDrag(stack) end)
end

function Hud.new(parent, settings, openSettings)
    local self = setmetatable({ parent = parent, settings = settings, rows = {}, stacks = {} }, Hud)
    for _, kind in ipairs({ "buff", "debuff" }) do
        local stack = { kind = kind, rows = {} }
        self.stacks[kind] = stack
        stack.root = UI.layer(parent, 0, 0, 340, 600)
        stack.heading = UI.text(stack.root, 0, 0, 220, 28, "")
        if kind == "buff" then
            stack.settingsButton = UI.button(stack.root, 230, 0, 100, "Settings", openSettings)
        end
        stack.status = UI.text(stack.root, 0, 30, 340, 24, "")
        stack.body = UI.layer(stack.root, 0, 30, 340, 570)
        stack.scroll = function(_, delta)
            stack.body:SetScrollPos(0, math.max(0, math.min(stack.scrollMaximum or 0,
                stack.body.scrollY + delta * 24)))
            return false
        end
        stack.body:Subscribe(ui.Hook.ONSCROLLWHEEL, stack.scroll)
        self:bindDrag(stack.heading, stack)
        self:bindDrag(stack.status, stack)
    end
    self.root = self.stacks.buff.root
    self.stacks.debuff.root.hidden = true
    return self
end

function Hud:beginDrag(stack)
    local config = self.settings.data
    if self.drag or config.dragLocked or stack.root.hidden or not Keyboard.IsAvailable()
        or not Mouse.IsAvailable() or Keyboard.IsBlocked() or not Keyboard.IsControlDown() then return end
    local pointer = UI.pointerPosition(self.parent)
    if not pointer then return end
    self:hideTooltip()
    self.drag = { stack = stack, separate = config.separate, x = stack.root.x, y = stack.root.y,
        offsetX = pointer.x - stack.root.x, offsetY = pointer.y - stack.root.y }
end

function Hud:hideTooltip()
    if self.tooltip then
        self.tooltip.root.hidden = true
        self.tooltip.key = nil
    end
end

function Hud:updateTooltip()
    if self.drag or not Mouse.IsAvailable() then self:hideTooltip(); return end
    local hovered
    local tooltip = self.tooltip
    for _, row in ipairs(self.rows) do
        if not row.layer.hidden and row.effect.key then
            if row.layer.isMouseOver then hovered = row; break end
            if tooltip and not tooltip.root.hidden and tooltip.root.isMouseOver
                and row.effect.key == tooltip.key then hovered = row end
        end
    end
    if not hovered then self:hideTooltip(); return end
    local effect = hovered.effect
    local details = effect.tooltip or effect.name
    if details == (effect.displayName or effect.name) then self:hideTooltip(); return end
    if not tooltip then
        tooltip = { root = UI.layer(self.parent, 0, 0, 1, 1) }
        tooltip.root.clickthrough = false
        tooltip.background = UI.rectangle(tooltip.root, 0, 0, 1, 1, 0x122028FF)
        tooltip.body = UI.layer(tooltip.root, 10, 10, 1, 1)
        tooltip.text = UI.text(tooltip.body, 0, 0, 1, 1, "")
        local textConfig = tooltip.text:GetConfigCopy()
        textConfig.maxLines, textConfig.lineSpacing = 0, 20
        textConfig.alignVertical = ui.AlignMode.TOPLEFT
        tooltip.text:SetConfig(textConfig)
        tooltip.root:Subscribe(ui.Hook.ONSCROLLWHEEL, function(_, delta)
            tooltip.body:SetScrollPos(0, math.max(0, math.min(tooltip.scrollMaximum,
                tooltip.body.scrollY + delta * 24)))
            return false
        end)
        self.tooltip = tooltip
    end
    local width = math.max(24, math.min(480, self.parent.width - 16))
    local content = details:gsub("\n", "<br>")
    local font = config.Font.FromID(id.Font.NOTO_SANS_11PT_BOLD_OUTLINE)
    local textHeight = font:GetStringHeightAndLineCount(content, width - 20, 20)
    local height = math.max(24, math.min(textHeight + 20, self.parent.height - 16))
    tooltip.root:SetSize(width, height)
    tooltip.background:SetSize(width, height)
    tooltip.body:SetSize(width - 20, height - 20)
    tooltip.body:SetScrollSize(width - 20, textHeight)
    tooltip.text:SetSize(width - 20, textHeight)
    tooltip.text.content = content
    tooltip.scrollMaximum = math.max(0, textHeight - tooltip.body.height)
    local changed = tooltip.key ~= effect.key or tooltip.content ~= content
    tooltip.body:SetScrollPos(0, changed and 0 or math.min(tooltip.body.scrollY, tooltip.scrollMaximum))
    if tooltip.key ~= effect.key or tooltip.root.hidden or not tooltip.root.isMouseOver then
        local stack = hovered.stack
        local x = stack.root.x + hovered.layer.width
        local y = stack.root.y + stack.body.y + hovered.layer.y - stack.body.scrollY
        if x + width > self.parent.width then x = stack.root.x - width end
        tooltip.root:SetPos(math.floor(math.max(0, math.min(x, self.parent.width - width))),
            math.floor(math.max(0, math.min(y, self.parent.height - height))))
    else
        tooltip.root:SetPos(math.max(0, math.min(tooltip.root.x, self.parent.width - width)),
            math.max(0, math.min(tooltip.root.y, self.parent.height - height)))
    end
    tooltip.key, tooltip.content, tooltip.root.hidden = effect.key, content, false
end

function Hud:finishDrag()
    if not self.drag then return end
    local drag = self.drag
    self.drag = nil
    local x, y = position(self.settings.data, drag.stack.kind)
    if drag.x ~= x or drag.y ~= y then
        self.settings:setPosition(drag.x, drag.y, drag.stack.kind)
    end
end

function Hud:updateDrag()
    if not self.drag then return end
    local config = self.settings.data
    if config.dragLocked or config.separate ~= self.drag.separate or not Keyboard.IsAvailable()
        or not Mouse.IsAvailable() or Keyboard.IsBlocked() then
        self:finishDrag()
        return
    end
    local pointer = UI.pointerPosition(self.parent)
    if not pointer then self:finishDrag(); return end
    self.drag.x = math.max(0, math.min(10000, self.parent.width - config.width,
        math.floor(pointer.x - self.drag.offsetX)))
    self.drag.y = math.max(0, math.min(10000, self.parent.height - 80,
        math.floor(pointer.y - self.drag.offsetY)))
    self.drag.stack.root:SetPos(self.drag.x, self.drag.y)
    if not Keyboard.IsControlDown() then self:finishDrag() end
end

function Hud:renderStack(stack, effects, issue)
    local config = self.settings.data
    local x, y = position(config, stack.kind)
    if self.drag and self.drag.stack == stack then x, y = self.drag.x, self.drag.y end
    stack.root:SetPos(math.max(0, math.min(x, self.parent.width - config.width)),
        math.max(0, math.min(y, self.parent.height - 80)))
    stack.root:SetSize(config.width, math.max(80, self.parent.height - stack.root.y))
    if stack.settingsButton then stack.settingsButton:SetPos(math.max(0, config.width - 100), 0) end
    stack.heading:SetSize(math.max(0, config.width - (stack.settingsButton and 105 or 0)), 28)
    stack.heading.content = "XBB / " .. (config.separate
        and (stack.kind == "debuff" and "Debuffs" or "Buffs") or "Buffs / Debuffs")
    stack.status:SetSize(config.width, 24)
    stack.status.content = issue or ""
    if self.drag and self.drag.stack == stack then stack.status.content = "Moving - release Ctrl to save" end
    stack.status.hidden = stack.status.content == ""
    local bodyTop = stack.status.hidden and 30 or 60
    stack.body:SetPos(0, bodyTop)
    stack.body:SetSize(config.width, math.max(1, stack.root.height - bodyTop))
    local contentHeight = #effects * (config.height + config.gap)
    stack.scrollMaximum = math.max(0, contentHeight - stack.body.height)
    stack.body:SetScrollSize(config.width, math.max(stack.body.height, contentHeight))
    stack.body:SetScrollPos(0, math.min(stack.body.scrollY, stack.scrollMaximum))
    for index, effect in ipairs(effects) do
        local row = stack.rows[index]
        if not row then
            row = { layer = UI.layer(stack.body, 0, 0, 1, 1), stack = stack }
            self:bindDrag(row.layer, stack)
            row.layer:Subscribe(ui.Hook.ONSCROLLWHEEL, stack.scroll)
            row.background = UI.rectangle(row.layer, 0, 0, 1, 1, 0x122028F2)
            row.fill = UI.rectangle(row.layer, 0, 0, 1, 1, 0x367D87CC)
            row.name = UI.text(row.layer, 10, 0, 1, 1, "")
            row.timer = UI.text(row.layer, 0, 0, 1, 1, "", ui.AlignMode.BOTTOMRIGHT)
            stack.rows[index] = row
        end
        row.effect = effect
        row.layer.hidden = not effect.key
        row.layer:SetPos(0, (effect.slot - 1) * (config.height + config.gap))
        row.layer:SetSize(config.width, config.height)
        row.layer.alpha = effect.active and 1 or 0.35
        row.background:SetSize(config.width, config.height)
        row.fill:SetSize(math.floor(config.width * effect.fraction), config.height)
        row.fill.rgba = effect.missing and 0xB0485BEE or (effect.kind == "debuff" and 0x965565DD or 0x357E89DD)
        row.name:SetSize(config.width - 108, config.height)
        row.name.content = (effect.stacks and (effect.stacksPercent and effect.stacks .. "% " or effect.stacks .. " ") or "")
            .. (not effect.active and "Reserved: " or "") .. (effect.displayName or effect.name)
        row.timer:SetPos(config.width - 96, 0)
        row.timer:SetSize(86, config.height)
        row.timer.content = effect.timer
        self.rows[#self.rows + 1] = row
    end
    for index = #effects + 1, #stack.rows do stack.rows[index].layer.hidden = true end
end

function Hud:render(groups, issue)
    self:updateDrag()
    self.rows = {}
    local config = self.settings.data
    self.stacks.debuff.root.hidden = not config.separate
    self:renderStack(self.stacks.buff, groups[1] and groups[1].rows or {}, issue)
    if config.separate then self:renderStack(self.stacks.debuff, groups[2] and groups[2].rows or {}, issue) end
    self:updateTooltip()
end

function Hud:updateCountdowns(effects, now)
    for _, row in ipairs(self.rows) do
        local effect = effects[row.effect.key]
        if effect and effect.expiry and row.effect.active and not row.layer.hidden and not row.stack.root.hidden then
            local remaining, fraction, timer = Model.countdown(effect, now)
            local width = math.floor(row.layer.width * fraction)
            if row.fill.width ~= width then row.fill:SetSize(width, row.layer.height) end
            if row.timer.content ~= timer then row.timer.content = timer end
            row.effect.remaining, row.effect.fraction, row.effect.timer = remaining, fraction, timer
        end
    end
end

-- Menu callbacks change local XBB settings only.
function Hud:menu(event)
    if self.drag then return end
    for _, row in ipairs(self.rows) do
        if not row.layer.hidden and row.layer.isMouseOver and row.effect.key then
            local effect, slot = row.effect, row.effect.slot
            for _, item in ipairs(Actions.items(self.settings, effect, slot)) do
                event.miniMenu:Add(item.label, item.run)
            end
            return
        end
    end
end

function Hud:destroy()
    self:finishDrag()
    if self.tooltip then self.tooltip.root:Destroy() end
    for _, stack in pairs(self.stacks) do stack.root:Destroy() end
end
return Hud
