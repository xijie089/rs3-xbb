--[[
XBB / PrettyUI settings
Provides native Plugins/settings launchers and a floating PrettyUI window.
Keeps Display, Hidden, Pins, Missing, Observed, and Colors controls synchronized.
Preserves tabs, pagination, scrolling, and locally saved window placement.
]]

local Catalog = require("xbb/catalog")
local Actions = require("xbb/actions")
local View = {}
View.__index = View
local Launcher = {}
Launcher.__index = Launcher
local tabs = { "Display", "Hidden", "Pins", "Missing", "Observed", "Colors" }
local toggles = {
    { "separate", "Separate buff/debuff stacks" },
    { "replaceNative", "Replace original bars" },
    { "dragLocked", "Lock bar dragging" },
}

local function syncToggles(control, settings)
    for _, field in ipairs(toggles) do control:SetSelected(field[1], settings.data[field[1]], false) end
end

local function addToggles(host, settings)
    local choices = {}
    for _, field in ipairs(toggles) do
        choices[#choices + 1] = { value = field[1], text = field[2], selected = settings.data[field[1]] }
    end
    return host:AddCheckboxButton(choices, {
        onChange = function(control, _, field, selected)
            settings:set(field, selected)
            syncToggles(control, settings)
        end,
    })
end

local function sorted(map, known)
    local result = {}
    for _, item in pairs(map) do result[#result + 1] = item end
    table.sort(result, function(a, b)
        return Catalog.entryName(a, known):lower() < Catalog.entryName(b, known):lower()
    end)
    return result
end

function View.launcher(parent, settings, openSettings)
    local self = setmetatable({ parent = parent, settings = settings, interfaceID = parent.interfaceID }, Launcher)
    self.view = prettyui.SimpleView.new(parent, { width = parent.width, height = parent.height })
    self.view:AddTitle("XBB")
    self.button = self.view:AddSimpleButton("Open full settings", openSettings)
    self.view:AddText("Quick options")
    self.controls = addToggles(self.view, settings)
    self:refresh()
    return self
end

function Launcher:refresh()
    if not self.view then return end
    if not ui.Interfaces:GetInterface(self.interfaceID) then self:destroy(); return end
    if self.width ~= self.parent.width or self.height ~= self.parent.height then
        self.width, self.height = self.parent.width, self.parent.height
        self.view:SetSize(self.width, self.height)
    end
    self.button:SetDisabled(not Player.IsAvailable())
    if self.renderedData ~= self.settings.data then
        syncToggles(self.controls, self.settings)
        self.renderedData = self.settings.data
    end
end

function Launcher:destroy()
    if self.view then self.view:Destroy(); self.view = nil end
end

local function dimensions(parent)
    return math.max(0, math.min(760, parent.width - 20)),
        math.max(0, math.min(560, parent.height - 20))
end

function View:clampPosition(x, y)
    return math.max(0, math.min(10000, self.parent.width - self.root.width, math.floor(x))),
        math.max(0, math.min(10000, self.parent.height - self.root.height, math.floor(y)))
end

function View.new(parent, settings)
    local self = setmetatable({ parent = parent, settings = settings, tab = "Display", page = 1,
        scroll = {}, colorPickers = {}, interfaceID = parent.interfaceID }, View)
    local width, height = dimensions(parent)
    local saved = settings.data.settingsWindowPosition
    local x = saved and saved.x or math.max(0, (parent.width - width) // 2)
    local y = saved and saved.y or math.max(0, (parent.height - height) // 2)
    x, y = math.min(x, math.max(0, parent.width - width)), math.min(y, math.max(0, parent.height - height))
    self.x, self.y, self.savedX, self.savedY = x, y, x, y
    self.window = prettyui.Window.new(parent, {
        title = "XBB / Xijie Buff Bars", x = x, y = y, width = width, height = height,
        minWidth = math.min(220, width), minHeight = math.min(140, height), scrollable = false,
        onClose = function() self:closeColorPickers(); self:savePosition() end,
    })
    self.root = self.window.root
    self.parentWidth, self.parentHeight = parent.width, parent.height
    self:render()
    return self
end

function View:savePosition()
    if not self.window then return end
    local loaded = ui.Interfaces:GetInterface(self.interfaceID) ~= nil
    if loaded then self.x, self.y = self:clampPosition(self.root.x, self.root.y) end
    if self.x == self.savedX and self.y == self.savedY then return end
    if self.settings:setWindowPosition(self.x, self.y) then
        self.savedX, self.savedY = self.x, self.y
    else
        self.x, self.y = self.savedX, self.savedY
        if loaded then
            self.x, self.y = self:clampPosition(self.x, self.y)
            self.root:SetPos(self.x, self.y)
            self.window:SetSize(self.root.width, self.root.height)
        end
    end
end

function View:finishDrag()
    if self.window and ui.Interfaces:GetInterface(self.interfaceID) and not self.root.hidden then
        self.window:Close()
        self.window:Show()
    end
end

function View:show()
    self.window:Show()
    self:refresh()
end

function View:closeColorPickers()
    for _, picker in ipairs(self.colorPickers) do picker:Close() end
end

function View:colorPickerOpen()
    for _, picker in ipairs(self.colorPickers) do
        if picker.pickerWindow and picker.pickerWindow.root and not picker.pickerWindow.root.hidden then return true end
    end
    return false
end

function View:addColorPicker(host, label, getColor, save, anchor)
    local options = {
        value = getColor(), inline = true, width = 28, height = 28, columnGap = 6,
        showAlpha = true, windowParent = self.parent, windowTitle = label .. " color", tooltip = label .. " color",
        onChange = function(control, value)
            save(value)
            control:SetValue(getColor(), false)
        end,
    }
    if anchor then options.absolute, options.x, options.y = true, anchor.x, anchor.y end
    local picker = host:AddColourPicker(options)
    if anchor then picker.root.hidden = true end
    self.colorPickers[#self.colorPickers + 1] = picker
    return picker
end

function View:selectColor(entry)
    self.colorKey, self.focusColor = entry.key, true
end

function View:renderColors(host, button)
    local config = self.settings.data
    host:AddTitle("Category defaults")
    for _, field in ipairs({ { "buff", "Buffs" }, { "debuff", "Debuffs" }, { "missing", "Missing warnings" } }) do
        host:AddText({ text = field[2], width = math.max(60, self.window.contentWidth - 180), height = 28 })
        self:addColorPicker(host, field[2],
            function() return tonumber(self.settings.data.colorDefaults[field[1]], 16) end,
            function(value) self.settings:setDefaultColor(field[1], value) end)
        button("Reset", function() self.settings:resetDefaultColor(field[1]) end,
            { inline = true, width = 84, columnGap = 6 })
    end
    host:AddTitle("Individual colors")
    local entries = sorted(config.colors, config.known)
    local size = math.max(1, (self.window.viewport.height - 250) // 40)
    local pages = math.max(1, math.ceil(#entries / size))
    self.page = math.max(1, math.min(self.page, pages))
    for index = (self.page - 1) * size + 1, math.min(#entries, self.page * size) do
        local entry = entries[index]
        host:AddText({ text = Catalog.entryName(entry, config.known) .. (entry.kind == "buff" and " (Buff)" or " (Debuff)"),
            width = math.max(60, self.window.contentWidth - 210), height = 28, maxLines = 1, marginTop = 6 })
        self:addColorPicker(host, Catalog.entryName(entry, config.known),
            function() return self.settings:colorFor(entry) end,
            function(value) self.settings:setColor(entry, value) end)
        button("Reset", function() self.settings:resetColor(entry.key) end,
            { inline = true, width = 84, columnGap = 6 })
    end
    if #entries == 0 then host:AddText("No custom colors yet.") end
    button("Previous", function() self.page = math.max(1, self.page - 1) end)
    host:AddText({ text = self.page .. " / " .. pages, inline = true, width = 80 })
    button("Next", function() self.page = math.min(pages, self.page + 1) end, { inline = true })
end

function View:refresh()
    if not self.window or not ui.Interfaces:GetInterface(self.interfaceID) then return end
    self.x, self.y = math.floor(self.root.x), math.floor(self.root.y)
    local resized = self.parentWidth ~= self.parent.width or self.parentHeight ~= self.parent.height
    if resized then
        self:closeColorPickers()
        self.parentWidth, self.parentHeight = self.parent.width, self.parent.height
        local width, height = dimensions(self.parent)
        self.window:SetSize(width, height)
        self.x, self.y = self:clampPosition(self.x, self.y)
        self.root:SetPos(self.x, self.y)
        self.window:SetSize(width, height)
    end
    if not self.root.hidden and not self:colorPickerOpen()
        and (resized or self.renderedData ~= self.settings.data) then self:render() end
end

function View:render()
    if not self.window then return end
    if self.group then
        for index, name in ipairs(tabs) do
            if name == self.renderedTab then self.scroll[name] = self.group:GetPage(index).scrollY end
        end
        self.group:Destroy()
    end
    self.colorPickers = {}
    local active = 1
    for index, name in ipairs(tabs) do if name == self.tab then active = index end end
    self.group = prettyui.Tabs.new(self.window.content, tabs, {
        width = self.window.contentWidth, height = self.window.viewport.height, activeIndex = active,
        onChange = function(_, index)
            self.tab, self.page = tabs[index], 1
            self:render()
        end,
    })
    local host = self.group:GetPage(active)
    local config = self.settings.data
    self.renderedData, self.renderedTab = config, self.tab
    local function button(label, run, options)
        return host:AddSimpleButton(label, function()
            run()
            self:render()
        end, options)
    end
    local focusedPicker
    if self.tab == "Display" then
        addToggles(host, self.settings)
        for _, field in ipairs({ { "width", "Bar width", 20 }, { "height", "Bar height", 2 },
            { "gap", "Bar gap", 1 } }) do
            host:AddText({ text = field[2] .. ": " .. config[field[1]], width = 180, height = 28 })
            button("-", function() self.settings:set(field[1], config[field[1]] - field[3]) end,
                { inline = true, width = 40 })
            button("+", function() self.settings:set(field[1], config[field[1]] + field[3]) end,
                { inline = true, width = 40 })
        end
        button("Reset positions", function() self.settings:resetPositions() end)
        host:AddText("Ctrl-click a buff header or bar; release Ctrl to save.")
        host:AddText("Open Settings > Gameplay > Interfaces > Buff Bar.")
        host:AddText("Turn on the items you want XBB to track.")
    elseif self.tab == "Colors" then
        self:renderColors(host, button)
    else
        local entries = {}
        if self.tab == "Hidden" then entries = sorted(config.hidden, config.known)
        elseif self.tab == "Pins" then entries = config.pins
        elseif self.tab == "Observed" then entries = sorted(config.known, config.known)
        else
            for _, preset in ipairs(Catalog.presets) do entries[#entries + 1] = preset end
            for _, rule in ipairs(sorted(config.rules, config.known)) do
                if not rule.preset then entries[#entries + 1] = rule end
            end
        end
        local size = math.max(1, (self.window.viewport.height - 100) // 64)
        local pages = math.max(1, math.ceil(#entries / size))
        self.page = math.max(1, math.min(self.page, pages))
        local nameWidth = math.max(100, self.window.contentWidth
            - (self.tab == "Observed" and 510 or (self.tab == "Pins" and 390 or 170)))
        local function action(label, run, width)
            return button(label, run, { inline = true, width = width, columnGap = 6 })
        end
        for index = (self.page - 1) * size + 1, math.min(#entries, self.page * size) do
            local entry = entries[index]
            host:AddText({ text = Catalog.entryName(entry, config.known), width = nameWidth, height = 28,
                maxLines = 1, marginTop = 10 })
            if self.tab == "Hidden" then
                action("Restore", function() self.settings:restore(entry.key) end, 94)
            elseif self.tab == "Pins" then
                host:AddText({ text = "#" .. entry.slot, width = 40, inline = true })
                action("-", function() self.settings:pin(entry, entry.slot - 1, entry.reserve) end, 32)
                action("+", function() self.settings:pin(entry, entry.slot + 1, entry.reserve) end, 32)
                action(entry.reserve and "Reserved" or "Collapsing",
                    function() self.settings:pin(entry, entry.slot, not entry.reserve) end, 112)
                action("Unpin", function() self.settings:unpin(entry.key) end, 84)
            elseif self.tab == "Observed" then
                if entry.kind == "buff" then
                    local rule = config.rules[entry.key]
                    action(rule and "Remove warning" or "Warn when missing",
                        function() Actions.watch(self.settings, entry, rule == nil) end, 160)
                end
                local pinned, hidden = self.settings:findPin(entry.key), config.hidden[entry.key]
                action(pinned and "Unpin" or "Pin", function()
                    if pinned then self.settings:unpin(entry.key) else self.settings:pin(entry, nil, false) end
                end, 72)
                action(hidden and "Unhide" or "Hide", function()
                    if hidden then self.settings:restore(entry.key) else self.settings:hide(entry) end
                end, 76)
                if config.colors[entry.key] then
                    action("Reset color", function() self.settings:resetColor(entry.key) end, 126)
                else
                    local control = action("Custom color", function() self:selectColor(entry) end, 126)
                    if self.focusColor and entry.key == self.colorKey then
                        focusedPicker = self:addColorPicker(host, Catalog.entryName(entry, config.known),
                            function() return self.settings:colorFor(entry) end,
                            function(value) self.settings:setColor(entry, value) end, control.root)
                    end
                end
                host:AddText({ text = entry.kind == "buff" and "Buff" or "Debuff", height = 20 })
            elseif Catalog.byID[entry.id] then
                local rule = config.rules[entry.id]
                action(rule and rule.enabled and "Enabled" or "Disabled",
                    function() self.settings:enablePreset(entry.id, not (rule and rule.enabled)) end, 94)
            else
                action("Delete", function() self.settings:removeWatch(entry.id) end, 94)
            end
        end
        if #entries == 0 then host:AddText("No items yet.") end
        button("Previous", function() self.page = math.max(1, self.page - 1) end)
        host:AddText({ text = self.page .. " / " .. pages, inline = true, width = 80 })
        button("Next", function() self.page = math.min(pages, self.page + 1) end, { inline = true })
    end
    self.focusColor = false
    host:SetScrollPosition(self.scroll[self.tab] or 0)
    if focusedPicker then focusedPicker:Open() end
end

function View:destroy()
    if not self.window then return end
    self:savePosition()
    if self.group then self.group:Destroy(); self.group = nil end
    self.window:Destroy()
    self.window, self.root = nil, nil
end

return View
