--[[
XBB / Settings window
Builds the Display, Hidden, Pins, Missing, and Observed settings tabs.
Uses remembered effect metadata to configure effects even while absent.
Sends edits through Settings and Actions; refreshes when settings data changes.
Preserves the selected tab and clamps pagination as entries change.
Uses title-bar press/release events and persists the completed window position.
]]

local UI = require("xbb/ui")
local Catalog = require("xbb/catalog")
local Actions = require("xbb/actions")
local View = {}
View.__index = View

local function sorted(map, known)
    local result = {}
    for _, item in pairs(map) do result[#result + 1] = item end
    table.sort(result, function(a, b)
        local first, second = Catalog.entryName(a, known), Catalog.entryName(b, known)
        return first:lower() < second:lower()
    end)
    return result
end

function View.new(parent, settings)
    local self = setmetatable({ parent = parent, settings = settings, tab = "Display", page = 1 }, View)
    self:render()
    return self
end

function View:clampPosition(x, y)
    return math.max(0, math.min(10000, self.parent.width - self.root.width, math.floor(x))),
        math.max(0, math.min(10000, self.parent.height - self.root.height, math.floor(y)))
end

function View:beginDrag()
    if self.drag or not Mouse.IsAvailable() then return end
    local pointer = UI.pointerPosition(self.parent)
    if not pointer then return end
    self.drag = { x = self.x, y = self.y, startX = self.x, startY = self.y,
        offsetX = pointer.x - self.x, offsetY = pointer.y - self.y, active = false }
end

function View:updateDrag()
    if not self.drag then return end
    if not Mouse.IsAvailable() then self:finishDrag(); return end
    local pointer = UI.pointerPosition(self.parent)
    if not pointer then self:finishDrag(); return end
    local x, y = self:clampPosition(pointer.x - self.drag.offsetX, pointer.y - self.drag.offsetY)
    if not self.drag.active and math.abs(x - self.drag.startX) < 3 and math.abs(y - self.drag.startY) < 3 then return end
    self.drag.active = true
    self.drag.x, self.drag.y = x, y
    self.root:SetPos(self.drag.x, self.drag.y)
end

function View:finishDrag(closing)
    local drag = self.drag
    if not drag then return end
    self.drag = nil
    if drag.active then
        self.x, self.y = self:clampPosition(drag.x, drag.y)
        if (self.x ~= drag.startX or self.y ~= drag.startY)
            and not self.settings:setWindowPosition(self.x, self.y) then
            local saved = self.settings.data.settingsWindowPosition
            self.x, self.y = self:clampPosition(saved and saved.x or drag.startX, saved and saved.y or drag.startY)
        end
    end
    if not closing and (drag.active or self.pendingRender or self.renderedData ~= self.settings.data) then
        self:render()
    end
end

function View:refresh()
    if not self.root then return end
    self:updateDrag()
    if self.parent.width ~= self.parentWidth or self.parent.height ~= self.parentHeight then
        self:finishDrag(true)
        self:render()
    elseif self.renderedData ~= self.settings.data then self:render() end
end

function View:render()
    if self.drag then self.pendingRender = true; return end
    self.pendingRender = nil
    if self.root then self.root:Destroy() end
    local width = math.max(0, math.min(760, self.parent.width - 20))
    local height = math.max(0, math.min(560, self.parent.height - 20))
    self.parentWidth, self.parentHeight = self.parent.width, self.parent.height
    local saved = self.settings.data.settingsWindowPosition
    self.x = self.x or (saved and saved.x) or math.max(0, (self.parent.width - width) // 2)
    self.y = self.y or (saved and saved.y) or math.max(0, (self.parent.height - height) // 2)
    -- Native absolute layout coordinates and sizes are integers.
    self.root = UI.layer(self.parent, 0, 0, width, height)
    self.x, self.y = self:clampPosition(self.x, self.y)
    self.root:SetPos(self.x, self.y)
    self.root.clickthrough = false
    UI.rectangle(self.root, 0, 0, width, height, 0x101C25FF)
    local title = UI.text(self.root, 16, 8, width - 110, 30, "XBB / Xijie Buff Bars / " .. self.tab)
    self.title = title
    title.clickthrough, title.enabled = false, true
    title:Subscribe(ui.Hook.ONCLICK, function()
        if self.title == title then self:beginDrag() end
    end)
    title:Subscribe(ui.Hook.ONHOLD, function()
        if self.title == title then self:updateDrag() end
    end)
    title:Subscribe(ui.Hook.ONRELEASE, function()
        if self.title == title then
            self:updateDrag()
            self:finishDrag()
        end
    end)
    UI.button(self.root, width - 80, 10, 64, "Close", function() self:destroy() end)
    local tabs = { "Display", "Hidden", "Pins", "Missing", "Observed" }
    for i, tab in ipairs(tabs) do
        UI.button(self.root, 16 + (i - 1) * (width - 32) // 5, 48, (width - 42) // 5, tab, function()
            self.tab, self.page = tab, 1; self:render()
        end)
    end
    local function change(run)
        return function() run(); self:render() end
    end
    local config = self.settings.data
    self.renderedData = config
    if self.tab == "Display" then
        UI.button(self.root, 16, 96, width - 32, config.separate and "Stacks: separate buffs / debuffs" or "Stacks: combined",
            change(function() self.settings:set("separate", not config.separate) end))
        UI.button(self.root, 16, 134, width - 32, config.replaceNative and "Replace original bars: on" or "Replace original bars: off",
            change(function() self.settings:set("replaceNative", not config.replaceNative) end))
        UI.button(self.root, 16, 172, width - 32, config.dragLocked and "Lock dragging: on" or "Lock dragging: off",
            change(function() self.settings:set("dragLocked", not config.dragLocked) end))
        UI.button(self.root, 16, 314, width - 32, "Reset positions",
            change(function() self.settings:resetPositions() end))
        for i, field in ipairs({ { "width", "Bar width", 20 }, { "height", "Bar height", 2 },
            { "gap", "Bar gap", 1 } }) do
            local y = 220 + (i - 1) * 38
            UI.text(self.root, 16, y, width - 160, 28, field[2] .. ": " .. config[field[1]])
            UI.button(self.root, width - 130, y, 48, "-", change(function()
                self.settings:set(field[1], config[field[1]] - field[3])
            end))
            UI.button(self.root, width - 70, y, 48, "+", change(function()
                self.settings:set(field[1], config[field[1]] + field[3])
            end))
        end
        UI.text(self.root, 16, 354, width - 32, 28, "Ctrl-click a buff header or bar; release Ctrl to save.")
        UI.text(self.root, 16, 382, width - 32, 28, "Drag this window by its title bar; release to save.")
        UI.text(self.root, 16, 424, width - 32, 28, "Open Settings > Gameplay > Interfaces > Buff Bar.")
        UI.text(self.root, 16, 452, width - 32, 28, "Turn on the items you want XBB to track.")
        return
    end
    local entries = {}
    if self.tab == "Hidden" then entries = sorted(config.hidden, config.known)
    elseif self.tab == "Pins" then entries = config.pins
    elseif self.tab == "Observed" then entries = sorted(config.known, config.known)
    else
        for _, preset in ipairs(Catalog.presets) do entries[#entries + 1] = preset end
        for _, rule in ipairs(sorted(config.rules, config.known)) do if not rule.preset then entries[#entries + 1] = rule end end
    end
    local size = math.max(1, math.floor((height - 180) / 48))
    local pages = math.max(1, math.ceil(#entries / size))
    self.page = math.min(self.page, pages)
    for index = (self.page - 1) * size + 1, math.min(#entries, self.page * size) do
        local entry = entries[index]
        local y = 94 + ((index - 1) % size) * 48
        local nameWidth = (self.tab == "Pins" or self.tab == "Observed") and width - 360 or width - 240
        local observed = self.tab == "Observed"
        UI.text(self.root, 16, y, nameWidth, observed and 24 or 30, Catalog.entryName(entry, config.known))
        if observed then
            UI.text(self.root, 16, y + 24, nameWidth, 20,
                entry.kind == "buff" and "Buff" or "Debuff")
        end
        if self.tab == "Hidden" then
            UI.button(self.root, width - 110, y, 94, "Restore", change(function() self.settings:restore(entry.key) end))
        elseif self.tab == "Pins" then
            UI.text(self.root, width - 342, y, 48, 28, "#" .. entry.slot)
            UI.button(self.root, width - 296, y, 32, "-", change(function()
                self.settings:pin(entry, entry.slot - 1, entry.reserve)
            end))
            UI.button(self.root, width - 258, y, 32, "+", change(function()
                self.settings:pin(entry, entry.slot + 1, entry.reserve)
            end))
            UI.button(self.root, width - 220, y, 112, entry.reserve and "Reserved" or "Collapsing",
                change(function() self.settings:pin(entry, entry.slot, not entry.reserve) end))
            UI.button(self.root, width - 100, y, 84, "Unpin", change(function() self.settings:unpin(entry.key) end))
        elseif self.tab == "Observed" then
            if entry.kind == "buff" then
                local rule = config.rules[entry.key]
                UI.button(self.root, width - 340, y, 160, rule and "Remove warning" or "Warn when missing",
                    change(function() Actions.watch(self.settings, entry, rule == nil) end))
            end
            local pinned, hidden = self.settings:findPin(entry.key), config.hidden[entry.key]
            UI.button(self.root, width - 172, y, 72, pinned and "Unpin" or "Pin", change(function()
                if pinned then self.settings:unpin(entry.key)
                else self.settings:pin(entry, nil, false) end
            end))
            UI.button(self.root, width - 92, y, 76, hidden and "Unhide" or "Hide", change(function()
                if hidden then self.settings:restore(entry.key)
                else self.settings:hide(entry) end
            end))
        else
            if Catalog.byID[entry.id] then
                local rule = config.rules[entry.id]
                local enabled = rule and rule.enabled or false
                UI.button(self.root, width - 110, y, 94, enabled and "Enabled" or "Disabled",
                    change(function() self.settings:enablePreset(entry.id, not enabled) end))
            else
                UI.button(self.root, width - 110, y, 94, "Delete",
                    change(function() self.settings:removeWatch(entry.id) end))
            end
        end
    end
    if #entries == 0 then UI.text(self.root, 16, 100, width - 32, 30, "No items yet.") end
    UI.button(self.root, 16, height - 48, 90, "Previous", function()
        self.page = math.max(1, self.page - 1); self:render()
    end)
    UI.text(self.root, 120, height - 48, width - 240, 28, self.page .. " / " .. pages, ui.AlignMode.CENTRE)
    UI.button(self.root, width - 106, height - 48, 90, "Next", function()
        self.page = math.min(pages, self.page + 1); self:render()
    end)
end

function View:destroy()
    self:finishDrag(true)
    if self.root then self.root:Destroy(); self.root = nil end
    self.title = nil
end
return View
