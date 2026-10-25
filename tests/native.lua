--[[
XBB / Native integration regression tests
Exercises Reader, the HUD, the settings window, and main.lua lifecycle.
Runs outside RuneScape using synthetic slot trees and mocked client globals.
Covers metadata, native opacity, menus, dragging, and settings synchronization.
Run from the repository root with: lua tests/native.lua
]]

local Reader = require("xbb/reader")
local count = 0
local function test(name, fn) fn(); count = count + 1; print("PASS " .. name) end
local function equal(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end

test("native manifest uses object dependencies and omits unused permissions", function()
    local file = assert(io.open("plugin.json", "r"))
    local metadata = file:read("*a")
    file:close()
    assert(metadata:match('"name"%s*:%s*"Xijie Buff Bars"'), "use the full three-word plugin name")
    assert(metadata:match('"requiredDependencies"%s*:%s*{'), "native dependencies must be an object")
    assert(metadata:match('"prettyui"%s*:%s*6398181'), "PrettyUI must be a required dependency")
    assert(metadata:match('"hasRibbonIcon"%s*:%s*true'), "XBB must appear in the native Plugins window")
    assert(not metadata:match('"requiredPermissions"%s*:'), "XBB does not request permissions")
end)

test("the native Plugins tab launches one floating settings window without a HUD link", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    equal(Mock.find(parent, "Settings"), nil)
    local host = Mock.node()
    app.events.ContentLayerReady.xbb({ component = host })
    assert(Mock.find(host, "XBB"))
    assert(Mock.find(host, "Quick options"))
    equal(Mock.find(host, "Quick display options. Use full settings to manage effects, pins, and missing warnings."), nil)
    assert(not Mock.find(parent, "Open full settings"))
    Mock.click(host, "Open full settings")
    local title = assert(Mock.find(parent, "XBB / Xijie Buff Bars"))
    Mock.click(host, "Open full settings")
    equal(Mock.find(parent, "XBB / Xijie Buff Bars"), title)
    PluginShutdown()
    equal(host.destroyed, nil)
    equal(next(app.events.ContentLayerReady), nil)
end)

test("opening settings before the first logic tick does not destroy the new window", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    dofile("main.lua")
    local host = Mock.node()
    app.events.SettingsLayerReady.xbb({ component = host })
    Mock.click(host, "Open full settings")
    local title = assert(Mock.find(app.components.TOPLEVEL_V2__GAME_AREA, "XBB / Xijie Buff Bars"))
    PluginLogic({ logicTick = 0 })
    equal(title.destroyed, nil)
    PluginShutdown()
end)

test("Plugins and settings launchers synchronize quick controls and reject failed changes", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    local content, settingsHost = Mock.node(), Mock.node()
    app.events.ContentLayerReady.xbb({ component = content })
    app.events.SettingsLayerReady.xbb({ component = settingsHost })
    Mock.click(content, "Separate buff/debuff stacks")
    equal(app.db.values.settings.separate, true)
    local writes = app.db.writes
    PluginLogic({ logicTick = 1 })
    equal(app.db.writes, writes)
    Mock.click(settingsHost, "Separate buff/debuff stacks")
    equal(app.db.values.settings.separate, false)
    Mock.click(content, "Replace original bars")
    app.events.Draw.xbb({})
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 255)
    Mock.click(content, "Lock bar dragging")
    equal(app.db.values.settings.dragLocked, true)
    local save = app.db.Set
    app.db.Set = function() return false end
    Mock.click(content, "Lock bar dragging")
    equal(app.db.values.settings.dragLocked, true)
    equal(#app.warnings, 1)
    app.db.Set = save
    Mock.click(content, "Lock bar dragging")
    equal(app.db.values.settings.dragLocked, false)
    content:SetSize(320, 240)
    PluginLogic({ logicTick = 2 })
    equal(content.children[1].width, 320)
    equal(content.children[1].height, 240)
    app.availability(false)
    PluginLogic({ logicTick = 3 })
    equal(Mock.find(content, "Open full settings").enabled, false)
    PluginShutdown()
    equal(content.destroyed, nil)
    equal(settingsHost.destroyed, nil)
end)

local function fixture()
    local types = { LAYER = 1, LABEL = 2, RADIAL_PROGRESS_OVERLAY = 3 }
    local components = {}
    for _, prefix in ipairs({ "BUFF_BAR", "DEBUFF_BAR" }) do
        components[prefix .. "__BUFF_RENDER_LAYER"] = { hidden = false, alpha = 255 }
        for i = 1, 50 do components[prefix .. "__BUFF_" .. i] = { visible = false } end
    end
    local api = {
        types = types,
        component = function(name) return components[name] end,
        struct = function() return nil end,
        paramID = function() return nil end,
    }
    local function slot(prefix, index, name, children)
        local node = { visible = true, type = types.LAYER, alpha = 255, opConfig = { opBaseName = name },
            children = children or {} }
        function node:IterateDynamicComponents(fn) for _, child in ipairs(self.children) do fn(child, child.visible) end end
        function node:IterateStaticComponents() end
        components[prefix .. "__BUFF_" .. index] = node
        return node
    end
    return Reader.new(api), components, slot, types, api
end

test("HUD colors follow category defaults and stable overrides in either layout", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local settings = require("xbb/settings").new(app.db, error)
    local model = require("xbb/model").new()
    local hud = require("xbb/hud").new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    local buff = { key = "buff:test", name = "Test", kind = "buff", timing = "timed", remaining = 20 }
    local debuff = { key = "debuff:test", name = "Test CD", kind = "debuff", timing = "timed", remaining = 10 }
    settings:setDefaultColor("buff", 0x00AAFFFF)
    settings:setDefaultColor("debuff", 0xFFAA00CC)
    settings:setDefaultColor("missing", 0xAA00FFDD)
    settings:setColor(buff, 0x12345678)
    settings:enablePreset("overload", true)
    settings:pin(buff, 4, true)
    local function color(key)
        for _, row in ipairs(hud.rows) do if row.effect.key == key then return row.fill.rgba end end
        error("missing HUD row: " .. key)
    end
    for _, separate in ipairs({ false, true }) do
        settings:set("separate", separate)
        model:update({ buff, debuff }, 0)
        hud:render(model:view(settings.data, 0))
        equal(color(buff.key), 0x12345678)
        equal(color(debuff.key), 0xFFAA00CC)
        equal(color("missing:overload"), 0xAA00FFDD)
        hud:updateCountdowns(model.effects, 1)
        equal(color(buff.key), 0x12345678)
        model:update({ debuff }, 2)
        hud:render(model:view(settings.data, 2))
        equal(color(buff.key), 0x12345678)
        settings:resetColor(buff.key)
        hud:render(model:view(settings.data, 2))
        equal(color(buff.key), 0x00AAFFFF)
        settings:setColor(buff, 0x12345678)
    end
    hud:destroy()
end)

test("Colors and Observed edit buff or debuff colors and retain picker drafts during refresh", function()
    for _, kind in ipairs({ "buff", "debuff" }) do
        local Mock = require("tests/mock")
        local app = Mock.install()
        local settings = require("xbb/settings").new(app.db, error)
        local View = require("xbb/settings_ui")
        local entry = { key = kind .. ":test", name = "Test effect", kind = kind }
        settings:remember({ entry })
        local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
        local root = view.root
        view.group:SetActive(5)
        Mock.click(root, "Custom color")
        equal(view.tab, "Observed")
        equal(view.group:GetActiveIndex(), 5)
        equal(view.colorKey, entry.key)
        equal(view.root, root)
        equal(#view.colorPickers, 1)
        local picker = view.colorPickers[1]
        equal(picker.options.showAlpha, true)
        picker:Open()
        picker.pendingColour = 0xABCDEF01
        local group = view.group
        entry.tooltip = "Updated native details"
        settings:remember({ entry })
        view:refresh()
        equal(view.group, group)
        equal(picker.root.destroyed, nil)
        picker:Close()
        view:refresh()
        equal(settings.data.colors[entry.key], nil)
        Mock.click(root, "Custom color")
        picker = view.colorPickers[1]
        picker:Open()
        picker:SetValue(0xABCDEF01)
        picker:Close()
        view:refresh()
        equal(settings:colorFor(entry), 0xABCDEF01)
        equal(view.tab, "Observed")
        equal(view.colorKey, entry.key)
        local loaded = require("xbb/settings").new(app.db, error)
        equal(loaded:colorFor(entry), 0xABCDEF01)
        view.group:SetActive(5)
        Mock.click(root, "Reset color")
        equal(view.tab, "Observed")
        equal(settings.data.colors[entry.key], nil)
        equal(settings:colorFor(entry), kind == "buff" and 0x357E89DD or 0x965565DD)
        view.group:SetActive(6)
        local defaultPicker = view.colorPickers[1]
        defaultPicker:SetValue(0xFF000055)
        view:refresh()
        equal(settings:colorFor({ kind = "buff" }), 0xFF000055)
        Mock.click(root, "Reset")
        equal(settings:colorFor({ kind = "buff" }), 0x357E89DD)
        view:destroy()
    end
end)

test("failed color saves restore picker values and settings teardown closes popups", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local settings = require("xbb/settings").new(app.db, warn)
    local View = require("xbb/settings_ui")
    local entry = { key = "buff:test", name = "Test", kind = "buff" }
    settings:remember({ entry })
    local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    view.group:SetActive(5)
    Mock.click(view.root, "Custom color")
    local data, picker = settings.data, view.colorPickers[1]
    app.db.Set = function() return false end
    picker:Open()
    picker:SetValue(0x123456FF)
    equal(picker:GetValue(), 0x357E89DD)
    equal(settings.data, data)
    equal(#app.warnings, 1)
    local popup = picker.pickerWindow.root
    view.window:Close()
    equal(popup.destroyed, true)
    equal(picker.pickerWindow, nil)
    view:show()
    picker:Open()
    popup = picker.pickerWindow.root
    view.group:SetActive(1)
    equal(popup.destroyed, true)
    view.group:SetActive(6)
    picker = view.colorPickers[1]
    picker:Open()
    popup = picker.pickerWindow.root
    app.components.TOPLEVEL_V2__GAME_AREA:SetSize(900, 700)
    view:refresh()
    equal(popup.destroyed, true)
    view.colorPickers[1]:Open()
    popup = view.colorPickers[1].pickerWindow.root
    view:destroy()
    equal(popup.destroyed, true)
end)

test("Colors lists only assigned overrides and Reset removes the row and restores its default", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local settings = require("xbb/settings").new(app.db, error)
    local entries = {}
    for index = 1, 18 do
        entries[index] = { key = "buff:" .. index, name = string.format("Effect %02d", index), kind = "buff" }
    end
    settings:remember(entries)
    settings:setColor(entries[1], 0x12345678)
    local view = require("xbb/settings_ui").new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    view.group:SetActive(6)
    equal(Mock.find(view.root, "Edit"), nil)
    equal(Mock.find(view.root, "Use default"), nil)
    equal(Mock.find(view.root, "Default"), nil)
    equal(Mock.find(view.root, "Custom"), nil)
    equal(Mock.find(view.root, "Effect 02 (Buff)"), nil)
    equal(#view.colorPickers, 4)
    equal(view.colorPickers[4]:GetValue(), 0x12345678)
    view.group:SetActive(5)
    Mock.click(view.root, "Custom color")
    equal(view.tab, "Observed")
    equal(view.colorKey, entries[2].key)
    view.colorPickers[1]:SetValue(0xAABBCCDD)
    view.colorPickers[1]:Close()
    view:refresh()
    equal(settings:colorFor(entries[1]), 0x12345678)
    equal(settings:colorFor(entries[2]), 0xAABBCCDD)
    view.group:SetActive(6)
    equal(#view.colorPickers, 5)
    local resets = {}
    for _, child in ipairs(view.group:GetPage(6).content.children) do
        if child.label == "Reset" then resets[#resets + 1] = child end
    end
    resets[5].hooks[ui.Hook.ONCLICK]()
    equal(settings.data.colors[entries[2].key], nil)
    equal(settings:colorFor(entries[1]), 0x12345678)
    equal(Mock.find(view.root, "Effect 02 (Buff)"), nil)
    equal(#view.colorPickers, 4)
    settings:resetColor(entries[1].key)
    view:refresh()
    equal(#view.colorPickers, 3)
    assert(Mock.find(view.root, "No custom colors yet."))
    for index = 1, 13 do settings:setColor(entries[index], 0xAABBCCDD) end
    view:refresh()
    Mock.click(view.root, "Next")
    Mock.click(view.root, "Next")
    equal(view.page, 3)
    resets = {}
    for _, child in ipairs(view.group:GetPage(6).content.children) do
        if child.label == "Reset" then resets[#resets + 1] = child end
    end
    resets[4].hooks[ui.Hook.ONCLICK]()
    equal(view.page, 2)
    equal(settings.data.colors[entries[13].key], nil)
    view.group:SetActive(5)
    while not Mock.find(view.root, "Effect 18") do Mock.click(view.root, "Next") end
    local buttons = {}
    for _, child in ipairs(view.group:GetPage(5).content.children) do
        if child.label == "Custom color" then buttons[#buttons + 1] = child end
    end
    buttons[#buttons].hooks[ui.Hook.ONCLICK]()
    equal(view.tab, "Observed")
    equal(view.colorKey, entries[18].key)
    assert(view.page > 1, "opening a picker must retain the selected Observed page")
    assert(view.colorPickers[1].pickerWindow)
    view.colorPickers[1]:Close()
    view.group:SetActive(6)
    equal(Mock.find(view.root, "Effect 18 (Buff)"), nil)
    view:destroy()
end)

test("native source reads both bars and stable names without icon matching", function()
    local reader, _, slot, types = fixture()
    slot("BUFF_BAR", 1, "<col=ffffff>Overload</col>", {
        { visible = true, type = types.LABEL, content = "5:42" } })
    slot("DEBUFF_BAR", 1, "Poison", {
        { visible = true, type = types.LABEL, content = "8s" } })
    local data, issue = reader:scan()
    equal(issue, nil)
    equal(#data, 2)
    equal(data[1].name, "Overload")
    equal(data[1].remaining, 342)
    equal(data[2].kind, "debuff")
    equal(data[2].remaining, 8)
end)

test("typed native progress preserves exact remaining and total seconds", function()
    local reader, _, slot, types = fixture()
    slot("BUFF_BAR", 1, "Overload", {
        { visible = true, type = types.RADIAL_PROGRESS_OVERLAY, initialValue = 0, curValue = 18, endValue = 360 } })
    local data = assert(reader:scan())
    equal(data[1].remaining, 342)
    equal(data[1].total, 360)
end)

test("timer parsing retains the precision of the displayed units", function()
    for _, sample in ipairs({
        { "2m", 120, 60 }, { "1m", 60, 60 }, { "1h", 3600, 3600 },
        { "1h 2m", 3720, 60 }, { "1h 2m 3s", 3723, 1 },
        { "1:02:03", 3723, 1 }, { "1:02", 62, 1 },
        { "59s", 59, 1 }, { "12.6s", 12.6, 0.1 }, { "12.6", 12.6, 0.1 },
    }) do
        local duration, precision = Reader.parseTime(sample[1], true)
        equal(duration, sample[2])
        equal(precision, sample[3])
    end
end)

test("minute-rounded potion labels preserve fill until precise seconds reconcile timing", function()
    for _, fullDuration in ipairs({ 120, 180 }) do
        local Mock = require("tests/mock")
        local app = Mock.install()
        local Settings, Model, Hud = require("xbb/settings"), require("xbb/model"), require("xbb/hud")
        local reader, _, slot, types, api = fixture()
        api.paramID = function(name) return name end
        local node = slot("DEBUFF_BAR", 1, "Adrenaline potion cooldown", {})
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_USES_ABILITY_END" then return 1 end
        end }
        local settings, model = Settings.new(app.db, error), Model.new()
        local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
        local function sample(now)
            local snapshot = assert(reader:scan())
            model:update(snapshot, now)
            settings:remember(snapshot, model.durations)
            hud:render(model:view(settings.data, now))
            hud:updateCountdowns(model.effects, now)
            return snapshot[1]
        end
        sample(100)
        local label = { visible = true, type = types.LABEL, content = (fullDuration // 60) .. "m" }
        node.children = { label }
        local first = sample(100.6)
        equal(first.timerPrecision, 60)
        equal(first.total, nil)
        sample(101.2)
        label.content = (fullDuration // 60 - 1) .. "m"
        sample(101.8)
        assert(hud.rows[1].fill.width > settings.data.width * 0.97)
        equal(hud.rows[1].timer.content, Model.formatTime(fullDuration))
        assert(math.abs(settings.data.known[first.key].duration - (fullDuration + 1.8)) < 0.000001)
        if fullDuration == 180 then
            sample(161.2)
            label.content = "1m"
            sample(161.8)
            equal(hud.rows[1].timer.content, "2:00")
        end
        local preciseAt = fullDuration + 42.4
        label.content = "59s"
        sample(preciseAt)
        local duration = preciseAt - 100 + 59
        equal(hud.rows[1].timer.content, "59s")
        equal(hud.rows[1].fill.width, math.floor(settings.data.width * 59 / duration))
        assert(math.abs(settings.data.known[first.key].duration - duration) < 0.000001)
        label.content = "0s"
        sample(preciseAt + 59)
        equal(hud.rows[1].fill.width, 0)
        equal(hud.rows[1].timer.content, "0.0s")
        hud:destroy()
    end
end)

test("a first minute label uses saved duration and calibration clears the HUD estimate marker", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings, Model, Hud = require("xbb/settings"), require("xbb/model"), require("xbb/hud")
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    local label = { visible = true, type = types.LABEL, content = "2m" }
    local node = slot("DEBUFF_BAR", 1, "Adrenaline potion cooldown", { label })
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 11599 end
    end }
    local settings = Settings.new(app.db, error)
    settings:remember({ { key = "debuff:11599", kind = "debuff", name = "Adrenaline potion cooldown" } },
        { ["debuff:11599"] = 120 })
    settings = Settings.new(app.db, error)
    local model = Model.new(settings.data.known)
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    local function sample(now)
        model:update(assert(reader:scan()), now)
        hud:render(model:view(settings.data, now))
        hud:updateCountdowns(model.effects, now)
    end
    sample(100)
    equal(hud.rows[1].timer.content, "~2:00")
    equal(hud.rows[1].fill.width, settings.data.width)
    label.content = "1m"
    sample(100.6)
    equal(hud.rows[1].timer.content, "2:00")
    sample(101.2)
    equal(hud.rows[1].timer.content:sub(1, 1) == "~", false)
    node.paramsConfig.Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 11599 end
        if name == "COMBATV2_BUFF_USES_STACKS" then return 0 end
    end
    label.content = "60"
    sample(160.6)
    equal(hud.rows[1].timer.content, "1:00")
    label.content = "59"
    sample(161.8)
    equal(hud.rows[1].timer.content, "59s")
    hud:destroy()
end)

test("precise native sources take precedence over rounded minute labels", function()
    for _, source in ipairs({ "radial", "book" }) do
        local reader, _, slot, types, api = fixture()
        api.paramID = function(name) return name end
        local node = slot("BUFF_BAR", 1, "Pocket book", {
            { visible = true, type = types.LABEL, content = "2m" },
        })
        if source == "radial" then
            node.children[#node.children + 1] = { visible = true, type = types.RADIAL_PROGRESS_OVERLAY,
                initialValue = 0, curValue = 61, endValue = 120 }
        else
            node.paramsConfig = { valid = true, Get = function(_, name)
                if name == "COMBATV2_BUFF_STRUCT" then return 21215 end
            end }
            api.struct = function() return { configName = "COMBATV2_GOD_BOOK_TIMER_DUMMY_ABILITY",
                GetParamValue = function() return nil end } end
            api.pocketBook = function() return { remaining = 59 } end
        end
        local item = assert(reader:scan())[1]
        equal(item.remaining, 59)
        equal(item.timerPrecision, nil)
    end
end)

test("the most precise timer label wins regardless of component order", function()
    for _, labels in ipairs({ { "2m", "1:03" }, { "1:03", "2m" } }) do
        local reader, _, slot, types = fixture()
        local children = {}
        for _, label in ipairs(labels) do
            children[#children + 1] = { visible = true, type = types.LABEL, content = label }
        end
        slot("BUFF_BAR", 1, "Timed buff", children)
        local item = assert(reader:scan())[1]
        equal(item.remaining, 63)
        equal(item.timerPrecision, 1)
    end
end)

test("the plugin persists learned durations and uses them for pending timers after reload", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    local node = Mock.node(nil, ui.ComponentType.LAYER)
    node.opConfig = { opBaseName = "Channeled Might" }
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 123 end
        if name == "COMBATV2_BUFF_USES_ABILITY_END" then return 1 end
    end }
    app.components.BUFF_BAR__BUFF_1 = node
    local label = Mock.node(node, ui.ComponentType.LABEL)
    label.content = "10s"
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    equal(app.db.values.settings.known["buff:123"].duration, 10)
    PluginShutdown()
    label.visible = false
    dofile("main.lua")
    PluginLogic({ logicTick = 1000 })
    assert(Mock.find(parent, "~10s"))
    local writes = app.db.writes
    PluginLogic({ logicTick = 1010 })
    app.events.ServerLogic.xbb()
    equal(app.db.writes, writes)
    label.content, label.visible = "8s", true
    PluginLogic({ logicTick = 1030 })
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 1035 })
    assert(Mock.find(parent, "7.9s"))
    assert(math.abs(app.db.values.settings.known["buff:123"].duration - 8.6) < 0.000001)
    PluginShutdown()
end)

test("a late potion cooldown fills from observed time rather than a longer native range", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Model = require("xbb/model")
    local Hud = require("xbb/hud")
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    local node = slot("DEBUFF_BAR", 1, "Adrenaline potion cooldown", {})
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_USES_ABILITY_END" then return 1 end
    end }
    local settings, model = Settings.new(app.db, error), Model.new()
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings, function() end)
    model:update(assert(reader:scan()), 100)
    hud:render(model:view(settings.data, 100))
    equal(hud.rows[1].timer.content, "")
    equal(hud.rows[1].fill.width, settings.data.width)
    node.children = { { visible = true, type = types.RADIAL_PROGRESS_OVERLAY,
        initialValue = 0, curValue = 60, endValue = 120 } }
    local snapshot = assert(reader:scan())
    equal(snapshot[1].remaining, 60)
    equal(snapshot[1].total, 120)
    model:update(snapshot, 100.6)
    hud:render(model:view(settings.data, 100.6))
    hud:updateCountdowns(model.effects, 100.6)
    equal(hud.rows[1].timer.content, "1:00")
    equal(hud.rows[1].fill.width, math.floor(settings.data.width * 60 / 60.6))
    hud:destroy()
end)

test("stack counters are not interpreted as seconds", function()
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function() return { id = 123,
        GetParamValue = function(_, name) return name == "COMBATV2_BUFF_USES_STACKS" and 1 or 0 end } end
    local node = slot("BUFF_BAR", 1, "Necrosis", { { visible = true, type = types.LABEL, content = "12" } })
    node.paramsConfig = { valid = true, Get = function(_, name)
        return name == "COMBATV2_BUFF_STRUCT" and 123 or nil
    end }
    local data = assert(reader:scan())
    equal(data[1].timing, "untimed")
    equal(data[1].stacks, 12)
end)

test("timer and stack labels are independent of component order", function()
    for _, labels in ipairs({
        { "5s", "12" }, { "12", "5s" }, { "12", "Stacks", "5s" },
        { "5s", "Stacks", "12" }, { "12", "Stacks" }, { "Stacks", "12" },
    }) do
        local reader, _, slot, types, api = fixture()
        api.paramID = function(name) return name end
        local children = {}
        for _, label in ipairs(labels) do
            children[#children + 1] = { visible = true, type = types.LABEL, content = label }
        end
        local node = slot("BUFF_BAR", 1, "Stacked buff", children)
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_USES_STACKS" then return 1 end
        end }
        local item = assert(reader:scan())[1]
        equal(item.stacks, 12)
        local timed = table.concat(labels, " "):find("5s", 1, true) ~= nil
        equal(item.timing, timed and "timed" or "untimed")
        equal(item.remaining, timed and 5 or nil)
    end
end)

test("combined native timer and parenthesized stack labels retain both values", function()
    for _, sample in ipairs({
        { "20<br>(12)", 20, 12, 1, false },
        { "19<BR />(5)", 19, 5, 1, false },
        { "<col=ffffff>9.6</col><br>(0)", 9.6, 0, 0.1, false },
        { "0<br>(0)", 0, 0, 1, false },
        { "1m<br>(12%)", 60, 12, 60, true },
    }) do
        local reader, _, slot, types, api = fixture()
        api.paramID = function(name) return name end
        api.struct = function()
            return { GetParamValue = function(_, name)
                if name == "COMBATV2_BUFF_USES_STACKS" or name == "COMBATV2_BUFF_USES_ABILITY_END" then return true end
            end }
        end
        local node = slot("BUFF_BAR", 1, "Stacked buff", {
            { visible = true, type = types.LABEL, content = sample[1] },
        })
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_STRUCT" then return 123 end
        end }
        local item = assert(reader:scan())[1]
        equal(item.timing, "timed")
        equal(item.remaining, sample[2])
        equal(item.stacks, sample[3])
        equal(item.timerPrecision, sample[4])
        equal(item.stacksPercent, sample[5])
    end
end)

test("stack effects with an end flag remain pending until timing is readable", function()
    for _, flag in ipairs({ true, 1 }) do
        local reader, _, slot, types, api = fixture()
        api.paramID = function(name) return name end
        local node = slot("BUFF_BAR", 1, "Stacked buff")
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_USES_STACKS" or name == "COMBATV2_BUFF_USES_ABILITY_END" then return flag end
        end }
        for _, text in ipairs({ "", "12", "(12)" }) do
            node.children = { { visible = true, type = types.LABEL, content = text } }
            local item = assert(reader:scan())[1]
            equal(item.timing, "unknown")
            equal(item.remaining, nil)
            equal(item.stacks, text ~= "" and 12 or nil)
        end
    end
end)

test("combined bare timers require stack and end metadata", function()
    for _, sample in ipairs({
        { stacks = true, ends = false, count = 12, timing = "untimed" },
        { stacks = false, ends = true, timing = "unknown" },
        { ends = true, timing = "unknown" },
    }) do
        local reader, _, slot, types, api = fixture()
        api.paramID = function(name) return name end
        local node = slot("BUFF_BAR", 1, "Native effect", {
            { visible = true, type = types.LABEL, content = "20<br>(12)" },
        })
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_USES_STACKS" then return sample.stacks end
            if name == "COMBATV2_BUFF_USES_ABILITY_END" then return sample.ends end
        end }
        local item = assert(reader:scan())[1]
        equal(item.timing, sample.timing)
        equal(item.remaining, nil)
        equal(item.stacks, sample.count)
    end
end)

test("live Blood Tithe and Glacial Embrace labels reach HUD counts timers and refreshes", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings, Model, Hud = require("xbb/settings"), require("xbb/model"), require("xbb/hud")
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function(structID)
        return { configName = structID == 44820 and "COMBATV2_BUFF_BLOOD_TITHE" or "COMBATV2_BUFF_GLACIAL_EMBRACE",
            GetParamValue = function(_, name)
                if name == "COMBATV2_BUFF_USES_STACKS" or name == "COMBATV2_BUFF_USES_ABILITY_END" then return true end
            end }
    end
    local nodes = {}
    for index, entry in ipairs({ { 44820, "Blood Tithe" }, { 44066, "Glacial Embrace" } }) do
        local node = slot("BUFF_BAR", index, entry[2])
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_STRUCT" then return entry[1] end
        end }
        nodes[index] = node
    end
    local settings, model = Settings.new(app.db, error), Model.new()
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    model:update(assert(reader:scan()), 100)
    hud:render(model:view(settings.data, 100))
    equal(hud.rows[1].timer.content, "")
    equal(hud.rows[2].timer.content, "")
    nodes[1].children = { { visible = true, type = types.LABEL, content = "20<br>(12)" } }
    nodes[2].children = { { visible = true, type = types.LABEL, content = "20<br>(1)" } }
    model:update(assert(reader:scan()), 100.6)
    hud:render(model:view(settings.data, 100.6))
    equal(hud.rows[1].name.content, "12 Blood Tithe")
    equal(hud.rows[2].name.content, "1 Glacial Embrace")
    equal(hud.rows[1].timer.content, "20s")
    equal(hud.rows[2].timer.content, "20s")
    equal(hud.rows[1].fill.width, math.floor(settings.data.width * 20 / 20.6))
    nodes[1].children[1].content = "18<br>(12)"
    nodes[2].children[1].content = "20<br>(3)"
    model:update(assert(reader:scan()), 103)
    hud:render(model:view(settings.data, 103))
    equal(hud.rows[1].name.content, "3 Glacial Embrace")
    equal(hud.rows[1].timer.content, "20s")
    equal(model.effects["buff:44066"].remaining, 20)
    equal(select(1, Model.countdown(model.effects["buff:44066"], 103)), 20)
    hud:destroy()
end)

test("stack radial values remain counts rather than seconds", function()
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    local node = slot("BUFF_BAR", 1, "Stacked buff", {
        { visible = true, type = types.RADIAL_PROGRESS_OVERLAY, initialValue = 0, curValue = 3, endValue = 12 },
        { visible = true, type = types.LABEL, content = "3" },
        { visible = true, type = types.LABEL, content = "Stacks" },
    })
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_USES_STACKS" then return true end
    end }
    local item = assert(reader:scan())[1]
    equal(item.timing, "untimed")
    equal(item.remaining, nil)
    equal(item.stacks, 3)
end)

test("percentage metadata and visible percent labels retain their display unit", function()
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    local node = slot("BUFF_BAR", 1, "Clan avatar boost", {
        { visible = true, type = types.LABEL, content = "6" },
    })
    for _, flag in ipairs({ true, 1 }) do
        api.struct = function()
            return { id = 40797, GetParamValue = function(_, name)
                if name == "COMBATV2_BUFF_USES_STACKS_PERCENT" then return flag end
            end }
        end
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_STRUCT" then return 40797 end
        end }
        local item = assert(reader:scan())[1]
        equal(item.stacks, 6)
        equal(item.stacksPercent, true)
        equal(item.remaining, nil)
    end
    api.struct = function()
        return { id = 40797, GetParamValue = function(_, name)
            if name == "COMBATV2_BUFF_USES_STACKS" then return true end
        end }
    end
    node.children[1].content = "6%"
    equal(assert(reader:scan())[1].stacksPercent, true)
    node.children[1].content = "6"
    equal(assert(reader:scan())[1].stacksPercent, false)
end)

test("false struct metadata permits explicitly non-stack numeric timers", function()
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function() return { id = 123, GetParamValue = function(_, name)
        if name == "COMBATV2_BUFF_USES_STACKS" then return false end
    end } end
    local node = slot("BUFF_BAR", 1, "Timed buff", {
        { visible = true, type = types.LABEL, content = "30" },
    })
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    local item = assert(reader:scan())[1]
    equal(item.timing, "timed")
    equal(item.remaining, 30)
end)

test("clan avatar buff resolves its name without an ability-name parameter", function()
    local reader, _, slot, _, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function(structID)
        equal(structID, 40797)
        return { id = structID, configName = "COMBATV2_CLAN_AVA_BUFF_LEVEL",
            GetParamValue = function(_, name)
                if name == "COMBATV2_BUFF_USES_STACKS"
                    or name == "COMBATV2_BUFF_USES_STACKS_PERCENT" then return true end
            end }
    end
    local node = slot("BUFF_BAR", 2, "")
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 40797 end
    end }
    local data, issue = reader:scan()
    equal(issue, nil)
    equal(#data, 1)
    equal(data[1].name, "Clan avatar boost")
    equal(data[1].key, "buff:40797")
    equal(data[1].timing, "untimed")
    equal(data[1].stacks, nil)
    node.opConfig.opBaseName = "Client-provided clan boost name"
    equal(assert(reader:scan())[1].name, "Client-provided clan boost name")
end)

test("unnamed buffs retain stable identities and timers with explicit fallback names", function()
    local reader, components, slot, types, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function(structID)
        return { id = structID, configName = "UNKNOWN_BUFF",
            GetParamValue = function() return nil end }
    end
    local node = slot("BUFF_BAR", 2, "", {
        { visible = true, type = types.LABEL, content = "12s" },
    })
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    local data, issue, details = reader:scan()
    equal(data[1].name, "Unknown buff #123")
    equal(data[1].nameUnavailable, true)
    equal(data[1].key, "buff:123")
    equal(data[1].remaining, 12)
    assert(issue:find("family checks paused", 1, true))
    assert(details:find("UNKNOWN_BUFF", 1, true))
    components.BUFF_BAR__BUFF_2 = { visible = false }
    components.BUFF_BAR__BUFF_5 = node
    equal(assert(reader:scan())[1].key, "buff:123")
    components.BUFF_BAR__BUFF_5 = { visible = false }
    components.DEBUFF_BAR__BUFF_1 = node
    data, issue = reader:scan()
    equal(data[1].name, "Unknown debuff #123")
    equal(data[1].key, "debuff:123")
    assert(not issue:find("family checks paused", 1, true))
    node.opConfig.opBaseName = "Recovered name"
    data, issue, details = reader:scan()
    equal(data[1].name, "Recovered name")
    equal(data[1].nameUnavailable, nil)
    equal(data[1].key, "debuff:123")
    equal(issue, nil)
    equal(details, nil)
    node.opConfig.opBaseName = ""
    api.struct = function() return nil end
    equal(assert(reader:scan())[1].key, "debuff:123")
end)

test("item-backed buffs resolve names from typed or component object references", function()
    local reader, _, slot, _, api = fixture()
    local object = { typeName = "Obj", id = 456, name = "Scripture of Ful" }
    local itemID, override
    api.paramID = function(name) return name end
    api.objectName = function(value)
        if value == object then return value.name end
        if value == 456 then return "<col=ffffff>Scripture of Jas</col>" end
    end
    api.struct = function(structID)
        return { id = structID, configName = "COMBATV2_GOD_BOOK_TIMER_DUMMY_ABILITY",
            GetParamValue = function(_, name)
                if name == "COMBATV2_ABILITY_NAME" then return "" end
                if name == "COMBATV2_ABILITY_OBJECT" then return object end
                if name == "COMBATV2_BUFF_OBJ_OVERRIDE" then return override end
            end }
    end
    local node = slot("BUFF_BAR", 1, "")
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 21215 end
        if name == "COMBATV2_ABILITY_OBJECT" then return itemID end
    end }
    local data, issue = reader:scan()
    equal(issue, nil)
    equal(data[1].name, "Scripture of Ful")
    equal(data[1].nameUnavailable, nil)
    equal(data[1].key, "buff:21215")
    itemID = 456
    equal(assert(reader:scan())[1].name, "Scripture of Jas")
    node.opConfig.opBaseName = "Client name"
    equal(assert(reader:scan())[1].name, "Client name")
    node.opConfig.opBaseName = ""
    itemID = -1
    equal(assert(reader:scan())[1].name, "Pocket book")
    itemID, override = nil, true
    data, issue = reader:scan()
    equal(issue, nil)
    equal(data[1].name, "Pocket book")
    itemID = 456
    equal(assert(reader:scan())[1].name, "Scripture of Jas")
end)

test("pocket activation uses the equipped book and actual remaining charge", function()
    local reader, _, slot, _, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function(structID)
        return { id = structID, configName = "COMBATV2_GOD_BOOK_TIMER_DUMMY_ABILITY",
            GetParamValue = function(_, name)
                if name == "COMBATV2_BUFF_USES_ABILITY_END" then return true end
            end }
    end
    local remaining = 36000
    api.pocketBook = function() return { name = "Scripture of Ful", remaining = remaining } end
    local node = slot("BUFF_BAR", 1, "")
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 21215 end
    end }
    local data = assert(reader:scan())
    equal(data[1].name, "Scripture of Ful")
    equal(data[1].remaining, 36000)
    equal(data[1].timing, "timed")
    remaining = 35999.4
    equal(assert(reader:scan())[1].remaining, 35999.4)
    api.pocketBook = function() return { name = "Scripture of Jas" } end
    data = assert(reader:scan())
    equal(data[1].name, "Scripture of Jas")
    equal(data[1].timing, "unknown")
    equal(data[1].remaining, nil)
end)

test("verbose Aftershock names retain full text and stable identity behind a short label", function()
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function(structID)
        return { id = structID, configName = "COMBATV2_AFTERSHOCK_TRACKER",
            GetParamValue = function(_, name)
                if name == "COMBATV2_BUFF_USES_STACKS_PERCENT" then return true end
            end }
    end
    local text = "Damage stored for Aftershock: charge increases as you deal damage."
    local node = slot("BUFF_BAR", 1, text, {
        { visible = true, type = types.LABEL, content = "47%" },
    })
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    local item = assert(reader:scan())[1]
    equal(item.name, text)
    equal(item.displayName, "Aftershock")
    equal(item.key, "buff:123")
    equal(item.stacks, 47)
    equal(item.stacksPercent, true)
    node.opConfig.opBaseName = text .. " Updated charge."
    equal(assert(reader:scan())[1].key, "buff:123")
end)

test("native ability titles provide compact labels without replacing full text", function()
    local reader, _, slot, _, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function(structID)
        return { id = structID, GetParamValue = function(_, name)
            if name == "COMBATV2_ABILITY_NAME" then return "Animate Dead" end
        end }
    end
    local text = "Animate Dead:<br>your armour reduces incoming damage."
    local node = slot("BUFF_BAR", 1, text)
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    local item = assert(reader:scan())[1]
    equal(item.name, "Animate Dead:your armour reduces incoming damage.")
    equal(item.tooltip, "Animate Dead:\nyour armour reduces incoming damage.")
    equal(item.displayName, "Animate Dead")
end)

test("mapped native effects retain descriptions timers counts and identity", function()
    for _, entry in ipairs({
        { "COMBATV2_CRACKLING_PERK_COOLDOWN", "Crackling CD", "debuff" },
        { "INVENT_PERK_RELENTLESS_COOLDOWN_DUMMY_ABILITY", "Relentless CD", "debuff" },
        { "INVENT_PERK_EQUILIBRIUM_COOLDOWN_DUMMY_ABILITY", "Equilibrium CD", "debuff" },
        { "COMBATV2_EXCALIBUR_ACTIVE", "Excalibur CD", "debuff" },
        { "COMBATV2_ADRENALINE_POTION_DUMMY_ABILITY", "Adrenaline potion CD", "debuff" },
        { "COMBATV2_DEBUFF_POWERBURST_COOLDOWN", "Powerburst CD", "debuff" },
        { "COMBATV2_VENGEANCE_COOLDOWN", "Vengeance CD", "debuff" },
        { "COMBATV2_INVENT_PERK_RUTHLESS_DUMMY_ABILITY", "Ruthless", "buff", 3 },
        { "COMBATV2_CRACKLING_PERK_ACTIVE", "Crackling", "buff" },
        { "COMBATV2_NATURE_BOSS_PRAYER_RESTORER_ACTIVE", "Ritual shard CD", "debuff" },
        { "COMBATV2_CALORIE_BOMB_RECIEVED_HEAL", "Calorie bomb heal CD", "debuff" },
        { "COMBATV2_BUFF_REXKINGS_MAGIC_SHOCKED", "Overcharged", "buff" },
        { "COMBATV2_BUFF_EGWD_JAS_BOSS_TIME_WARP", "Warp Time", "buff" },
        { "UNKNOWN_RENAMED_CONFIG", "Ritual shard CD", "debuff", nil, 40899 },
    }) do
        local reader, _, slot, types, api = fixture()
        api.paramID = function(name) return name end
        api.struct = function(structID)
            return { id = structID, configName = entry[1], GetParamValue = function(_, name)
                if name == "COMBATV2_ABILITY_NAME" then return "Verbose native title" end
                if name == "COMBATV2_BUFF_USES_STACKS" then return entry[4] ~= nil end
            end }
        end
        local children = { { visible = true, type = types.LABEL, content = "30s" } }
        if entry[4] then children[#children + 1] = { visible = true, type = types.LABEL, content = tostring(entry[4]) } end
        local full = "Full native description for " .. entry[1]
        local node = slot(entry[3] == "buff" and "BUFF_BAR" or "DEBUFF_BAR", 1, full, children)
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_STRUCT" then return entry[5] or 123 end
        end }
        local item = assert(reader:scan())[1]
        equal(item.displayName, entry[2])
        equal(item.name, full)
        equal(item.tooltip, full)
        equal(item.key, entry[3] .. ":" .. (entry[5] or 123))
        equal(item.kind, entry[3])
        equal(item.remaining, 30)
        equal(item.stacks, entry[4])
    end
end)

test("short native titles expose ability-info and scripted hover descriptions", function()
    for _, entry in ipairs({
        { 48340, "COMBATV2_BUFF_NECROMANCY_BONE_SHIELD", "Bone Shield",
            "- Allows the use of <col=ffffff>non-offensive</col> abilities that require a shield, at the cost of necromancy runes.",
            "- Allows the use of non-offensive abilities that require a shield, at the cost of necromancy runes." },
        { 45797, "COMBATV2_EGWD_FUL_GOD_BOOK_EFFECT", "Gladiator's Rage",
            "<col=0x00ffff>6.6% chance</col> to increase damage dealt by <col=0x00ffff>20%</col> and damage taken by <col=0x00ffff>10%</col> for <col=0x00ffff>15 seconds</col>.",
            "6.6% chance to increase damage dealt by 20% and damage taken by 10% for 15 seconds." },
        { 52801, "COMBATV2_BUFF_RANGED_SEARING_WINDS", "Searing Winds", nil,
            "Ranged attacks deal an additional 20% bonus damage with each hit." },
        { 44820, "COMBATV2_BUFF_BLOOD_TITHE", "Blood Tithe", nil,
            "Each stack boosts basic Magic ability base damage by 1% (maximum 12 stacks)." },
        { 44066, "COMBATV2_BUFF_GLACIAL_EMBRACE", "Glacial Embrace", nil,
            "Each stack cuts Tsunami's adrenaline cost by 12% (maximum 5 stacks).\n"
                .. "At 5 stacks, Incite Fear attacks can trigger Frost Surge for 10-50% ability damage "
                .. "to the target and up to 8 enemies within 2 tiles (12s cooldown)." },
    }) do
        local Mock = require("tests/mock")
        local app = Mock.install()
        local reader, _, slot, _, api = fixture()
        api.paramID = function(name) return name end
        api.struct = function(structID)
            return { id = structID, configName = entry[2], GetParamValue = function(_, name)
                if name == "COMBATV2_ABILITY_NAME" then return entry[3] end
                if name == "COMBATV2_ABILITY_INFO" then return entry[4] end
            end }
        end
        local node = slot("BUFF_BAR", 1, entry[3])
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_STRUCT" then return entry[1] end
        end }
        local item = assert(reader:scan())[1]
        equal(item.name, entry[3])
        equal(item.displayName, entry[3])
        equal(item.tooltip, entry[3] .. "\n" .. entry[5])
        equal(item.key, "buff:" .. entry[1])
        local model = require("xbb/model").new()
        model:update({ item }, 0)
        local settings = require("xbb/settings").new(app.db, error)
        local hud = require("xbb/hud").new(app.components.TOPLEVEL_V2__GAME_AREA, settings, function() end)
        hud:render(model:view(settings.data, 0))
        hud.rows[1].layer.isMouseOver = true
        hud:updateTooltip()
        equal(hud.tooltip.text.content, (item.tooltip:gsub("\n", "<br>")))
        hud:destroy()
    end
end)

test("scripted stack descriptions never replace supplied native hover or ability info", function()
    for _, entry in ipairs({
        { 44820, "COMBATV2_BUFF_BLOOD_TITHE", "Blood Tithe" },
        { 44066, "COMBATV2_BUFF_GLACIAL_EMBRACE", "Glacial Embrace" },
    }) do
        local reader, _, slot, _, api = fixture()
        api.paramID = function(name) return name end
        local info = "Current native ability details."
        api.struct = function()
            return { configName = entry[2], GetParamValue = function(_, name)
                if name == "COMBATV2_ABILITY_NAME" then return entry[3] end
                if name == "COMBATV2_ABILITY_INFO" then return info end
            end }
        end
        local node = slot("BUFF_BAR", 1, entry[3])
        node.paramsConfig = { valid = true, Get = function(_, name)
            if name == "COMBATV2_BUFF_STRUCT" then return entry[1] end
        end }
        equal(assert(reader:scan())[1].tooltip, entry[3] .. "\n" .. info)
        node.opConfig.opBaseName = entry[3] .. ":<br>Current native hover details."
        equal(assert(reader:scan())[1].tooltip, entry[3] .. ":\nCurrent native hover details.")
        info = nil
        equal(assert(reader:scan())[1].tooltip, entry[3] .. ":\nCurrent native hover details.")
    end
end)

test("ability-info paragraphs retain breaks without duplicating native full hover text", function()
    local reader, _, slot, _, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function(structID)
        return { id = structID, GetParamValue = function(_, name)
            if name == "COMBATV2_ABILITY_NAME" then return "Example" end
            if name == "COMBATV2_ABILITY_INFO" then return "First line.<br>Second line." end
            if name == "COMBATV2_ABILITY_INFO_2" then return "Additional details." end
        end }
    end
    local node = slot("BUFF_BAR", 1, "Example")
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    equal(assert(reader:scan())[1].tooltip, "Example\nFirst line.\nSecond line.\nAdditional details.")
    node.opConfig.opBaseName = "Example:<br>More specific live details."
    equal(assert(reader:scan())[1].tooltip, "Example:\nMore specific live details.")
    node.opConfig.opBaseName = ""
    equal(assert(reader:scan())[1].tooltip, "Example\nFirst line.\nSecond line.\nAdditional details.")
end)

test("quiver labels follow selected ammo while retaining their buff identity", function()
    local reader, _, slot, _, api = fixture()
    api.paramID = function(name) return name end
    api.struct = function(structID)
        return { id = structID, configName = "COMBATV2_BUFF_QUIVER_ACTIVE_AMMO",
            GetParamValue = function() end }
    end
    local ammo = "Bik arrows"
    api.quiverAmmo = function() return ammo end
    local node = slot("BUFF_BAR", 1, "Quiver ammo")
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    local item = assert(reader:scan())[1]
    equal(item.key, "buff:123")
    equal(item.name, "Quiver ammo")
    equal(item.displayName, "Quiver: Bik arrows")
    equal(item.tooltip, "Quiver ammo\nSelected ammo: Bik arrows")
    ammo = "<col=ffffff>Ful arrows</col>"
    item = assert(reader:scan())[1]
    equal(item.key, "buff:123")
    equal(item.displayName, "Quiver: Ful arrows")
    equal(item.tooltip, "Quiver ammo\nSelected ammo: Ful arrows")
    ammo = nil
    item = assert(reader:scan())[1]
    equal(item.displayName, "Quiver ammo (unavailable)")
    equal(item.tooltip, "Quiver ammo\nSelected ammo: unavailable")
    api.quiverAmmo = nil
    equal(assert(reader:scan())[1].displayName, "Quiver ammo (unavailable)")
end)

test("unavailable and ambiguous sources are not empty successful snapshots", function()
    local reader, components, slot, types = fixture()
    components.BUFF_BAR__BUFF_RENDER_LAYER = nil
    local data, issue = reader:scan()
    equal(data, nil)
    assert(issue:find("BUFF_BAR", 1, true))
    components.BUFF_BAR__BUFF_RENDER_LAYER = { hidden = false, alpha = 255 }
    slot("BUFF_BAR", 1, "", { { visible = true, type = types.LABEL, content = "30" } })
    data, issue = reader:scan()
    equal(data, nil)
    assert(issue:find("name", 1, true))
end)

test("visible empty layout slots are not active buffs", function()
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    slot("BUFF_BAR", 1, "Soul Split")
    slot("BUFF_BAR", 3, "")
    slot("BUFF_BAR", 4, "", { slot("DEBUFF_BAR", 2, "") })
    local data, issue = reader:scan()
    equal(issue, nil)
    equal(#data, 1)
    equal(data[1].name, "Soul Split")
    slot("BUFF_BAR", 1, "")
    data, issue = reader:scan()
    equal(issue, nil)
    equal(#data, 0)
    slot("BUFF_BAR", 3, "", {
        { visible = false, type = types.LABEL, content = "Stale label" },
    })
    equal(#assert(reader:scan()), 0)
    slot("BUFF_BAR", 4, "", { { visible = true, type = 99 } })
    data, issue = reader:scan()
    equal(data, nil)
    assert(issue:find("effect name unavailable", 1, true))
    slot("BUFF_BAR", 4, "")
    local node = slot("BUFF_BAR", 3, "")
    node.paramsConfig = { valid = true, Get = function() return nil end }
    data, issue = reader:scan()
    equal(issue, nil)
    equal(#data, 0)
    node.paramsConfig.Get = function(_, name)
        if name == "COMBATV2_BUFF_USES_STACKS" then return 1 end
    end
    data, issue = reader:scan()
    equal(data, nil)
    assert(issue:find("effect name unavailable", 1, true))
    node.paramsConfig = nil
    node.opConfig.numOpNames = 1
    equal(reader:scan(), nil)
end)

test("local child visibility remains readable below a hidden native render parent", function()
    local reader, components, slot, types = fixture()
    local node = slot("BUFF_BAR", 1, "Overload", {
        { visible = true, type = types.LABEL, content = "5:42" },
        { visible = false, type = types.LABEL, content = "9:59" },
    })
    function node:IterateDynamicComponents(callback)
        for _, child in ipairs(self.children) do callback(child, false) end
    end
    equal(assert(reader:scan())[1].remaining, 342)
    components.BUFF_BAR__BUFF_RENDER_LAYER.hidden = true
    equal(assert(reader:scan())[1].remaining, 342)
end)

test("non-time labels stay unknown rather than becoming permanent", function()
    local reader, _, slot, types = fixture()
    slot("BUFF_BAR", 1, "Unknown effect", { { visible = true, type = types.LABEL, content = "75%" } })
    local data = assert(reader:scan())
    equal(data[1].timing, "unknown")
end)

test("unreadable slots report visible structure and metadata without changing identity", function()
    local reader, _, slot, types, api = fixture()
    api.paramID = function(name) return name end
    local node = slot("BUFF_BAR", 2, "", {
        { visible = true, type = types.LABEL, content = "12s" },
        { visible = false, type = types.LABEL, content = "Hidden content" },
    })
    node.visibleGlobal = true
    node.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_USES_STACKS" then return 0 end
    end }
    local snapshot, issue, details = reader:scan()
    equal(snapshot, nil)
    equal(issue, "BUFF_BAR slot 2: effect name unavailable")
    assert(details:find("type=1", 1, true))
    assert(details:find("global=true", 1, true))
    assert(details:find("12s", 1, true))
    assert(details:find("COMBATV2_BUFF_USES_STACKS", 1, true))
    assert(not details:find("Hidden content", 1, true))
end)

test("unreadable slot diagnostics are logged once until source recovery", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local node = Mock.node(nil, ui.ComponentType.LAYER)
    node.opConfig = { opBaseName = "" }
    Mock.node(node, 99)
    app.components.BUFF_BAR__BUFF_2 = node
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    app.events.ServerLogic.xbb()
    equal(#app.warnings, 1)
    equal(#app.messages, 2)
    assert(app.messages[2]:find("XBB diagnostic:", 1, true))
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 255)
    node.opConfig.opBaseName = "Soul Split"
    app.events.ServerLogic.xbb()
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    node.opConfig.opBaseName = ""
    app.events.ServerLogic.xbb()
    equal(#app.messages, 3)
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 255)
    PluginShutdown()
end)

test("replacement keeps native timer data available for existing and newly active effects", function()
    local reader, components, slot, types, api = fixture()
    api.paramID = function(name) return name end
    local root = components.BUFF_BAR__BUFF_RENDER_LAYER
    local remaining = 30
    local function label()
        return setmetatable({ visible = true, type = types.LABEL, alpha = 173 }, {
            __index = function(_, key)
                if key == "content" then return root.hidden and "" or remaining .. "s" end
            end,
        })
    end
    local timer = label()
    local first = slot("BUFF_BAR", 1, "Existing buff", { timer })
    local icon = { visible = true, type = 99, alpha = 255 }
    local nested = slot("BUFF_BAR", 2, "", { icon })
    nested.visible = false
    first.paramsConfig = { valid = true, Get = function(_, name)
        if name == "COMBATV2_BUFF_USES_ABILITY_END" then return true end
    end }
    equal(assert(reader:scan())[1].remaining, 30)
    equal(reader:replace(true), true)
    equal(timer.alpha, 0)
    equal(timer.visible, true)
    equal(first.alpha, 0)
    equal(icon.alpha, 255)
    remaining = 29
    equal(assert(reader:scan())[1].remaining, 29)
    local newTimer = label()
    slot("BUFF_BAR", 2, "New buff", { newTimer }).paramsConfig = first.paramsConfig
    local snapshot = assert(reader:scan())
    equal(snapshot[2].remaining, 29)
    equal(reader:replace(true), true)
    equal(newTimer.alpha, 0)
    timer.alpha = 128
    equal(reader:replace(true), true)
    equal(timer.alpha, 0)
    equal(assert(reader:scan())[1].remaining, 29)
    local model = require("xbb/model").new()
    model:update(snapshot, 1)
    local rows = model:view({ hidden = {}, pins = {}, rules = {} }, 1)[1].rows
    equal(rows[1].timer, "29s")
    equal(rows[2].timer, "29s")
    equal(root.hidden, false)
    equal(root.alpha, 0)
    equal(reader:replace(false), true)
    equal(timer.alpha, 173)
    equal(newTimer.alpha, 173)
    equal(first.alpha, 255)
end)

test("replacement suppresses drawable descendants without relying on inherited opacity", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local reader = Reader.new({
        types = ui.ComponentType,
        component = function(name) return app.components[name] end,
        paramID = function() end,
    })
    local slot = Mock.node(nil, ui.ComponentType.LAYER)
    slot.opConfig = { opBaseName = "Timed buff" }
    local nested = Mock.node(slot, ui.ComponentType.LAYER)
    local sprite = Mock.node(nested, ui.ComponentType.SPRITE)
    local timer = Mock.node(slot, ui.ComponentType.LABEL)
    timer.content = "30s"
    local radial = Mock.node(slot, ui.ComponentType.RADIAL_PROGRESS_OVERLAY)
    radial.initialValue, radial.curValue, radial.endValue = 0, 30, 60
    timer.alpha, radial.alpha = 173, 0
    app.components.BUFF_BAR__BUFF_1 = slot
    local function rendered()
        local result = 0
        for _, node in ipairs({ sprite, timer, radial }) do
            if not node.hidden and node.alpha > 0 then result = result + 1 end
        end
        return result
    end
    equal(rendered(), 2)
    equal(assert(reader:scan())[1].remaining, 30)
    equal(reader:replace(true), true)
    equal(rendered(), 0)
    for _, node in ipairs({ slot, nested, sprite, timer, radial }) do
        equal(node.hidden, false)
        equal(node.visible, true)
    end
    timer.content, radial.curValue = "29s", 31
    equal(assert(reader:scan())[1].remaining, 29)
    equal(reader:replace(true), true)
    app.components.BUFF_BAR__BUFF_1 = { visible = false }
    assert(reader:scan())
    equal(reader:replace(true), true)
    equal(sprite.alpha, 255)
    equal(timer.alpha, 173)
    equal(radial.alpha, 0)
    equal(reader:replace(false), true)
end)

test("native replacement restores prior opacity without changing visibility", function()
    local reader, components = fixture()
    components.BUFF_BAR__BUFF_RENDER_LAYER.alpha = 173
    components.DEBUFF_BAR__BUFF_RENDER_LAYER.hidden = true
    components.DEBUFF_BAR__BUFF_RENDER_LAYER.alpha = 0
    assert(reader:scan())
    reader:replace(true)
    equal(components.BUFF_BAR__BUFF_RENDER_LAYER.hidden, false)
    equal(components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    reader:replace(true)
    reader:replace(false)
    equal(components.BUFF_BAR__BUFF_RENDER_LAYER.hidden, false)
    equal(components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 173)
    equal(components.DEBUFF_BAR__BUFF_RENDER_LAYER.hidden, true)
    equal(components.DEBUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
end)

test("unnamed effect warnings do not block rendering and clear after name recovery", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    config.Struct.FromID = function(structID)
        return { id = structID, configName = "UNKNOWN_BUFF",
            GetParamValue = function() return nil end }
    end
    local node = Mock.node(nil, ui.ComponentType.LAYER)
    node.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    Mock.node(node, ui.ComponentType.LABEL).content = "12s"
    app.components.BUFF_BAR__BUFF_2 = node
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    assert(Mock.find(parent, "Unknown buff #123"))
    assert(Mock.find(parent, "12s"))
    assert(Mock.find(parent, "Effect names unavailable (1) - family checks paused"))
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    equal(#app.warnings, 1)
    equal(#app.messages, 2)
    app.events.ServerLogic.xbb()
    equal(#app.warnings, 1)
    equal(#app.messages, 2)
    node.opConfig = { opBaseName = "Recovered name" }
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 5 })
    assert(Mock.find(parent, "Recovered name"))
    assert(not Mock.find(parent, "Effect names unavailable (1) - family checks paused"))
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    node.opConfig.opBaseName = ""
    app.events.ServerLogic.xbb()
    equal(#app.warnings, 2)
    equal(#app.messages, 3)
    PluginShutdown()
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 255)
end)

test("moving native slots does not change effect identity", function()
    local reader, components, slot = fixture()
    local node = slot("BUFF_BAR", 1, "Soul Split")
    local key = assert(reader:scan())[1].key
    components.BUFF_BAR__BUFF_1 = { visible = false }
    components.BUFF_BAR__BUFF_4 = node
    equal(assert(reader:scan())[1].key, key)
end)

test("unloaded native components cannot block replacement of new interfaces", function()
    local reader, components = fixture()
    assert(reader:scan())
    reader:replace(true)
    local old = components.BUFF_BAR__BUFF_RENDER_LAYER
    old.alpha = nil
    setmetatable(old, { __newindex = function() error("component unloaded") end })
    components.BUFF_BAR__BUFF_RENDER_LAYER = { hidden = false, alpha = 255 }
    assert(reader:scan())
    local ok, issue = reader:replace(true)
    equal(ok, false)
    assert(issue:find("component unloaded", 1, true))
    equal(components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    equal(reader:replace(true), true)
    reader:replace(false)
    equal(components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 255)
end)

test("native timer parser does not mistake percentages or stacks for time", function()
    equal(Reader.parseTime("1:02:03"), 3723)
    equal(Reader.parseTime("1h 2m 3s"), 3723)
    equal(Reader.parseTime("12.6s"), 12.6)
    equal(Reader.parseTime("42%"), nil)
    equal(Reader.parseTime("x12"), nil)
    equal(Reader.parseTime("12"), nil)
    equal(Reader.parseTime("12", true), 12)
end)

test("native HUD puts bare counts and levels before effect names", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, Settings.new(app.db), function() end)
    hud:render({ { rows = {
        { key = "buff:incite", name = "Incite Fear", kind = "buff", stacks = 5,
            active = true, fraction = 1, slot = 1, timer = "Active" },
        { key = "buff:sunshine", name = "Sunshine", kind = "buff",
            active = true, fraction = 1, slot = 2, timer = "30s" },
        { key = "buff:clan", name = "Clan avatar boost", kind = "buff", stacks = 6, stacksPercent = true,
            active = true, fraction = 1, slot = 3, timer = "Active" },
        { key = "buff:48340", name = "Bone Shield", kind = "buff", stacks = 30,
            active = true, fraction = 1, slot = 4, timer = "Active" },
        { key = "buff:empty", name = "Empty charge", kind = "buff", stacks = 0,
            active = true, fraction = 1, slot = 5, timer = "Active" },
    } } })
    equal(hud.rows[1].name.content, "5 Incite Fear")
    equal(hud.rows[2].name.content, "Sunshine")
    equal(hud.rows[3].name.content, "6% Clan avatar boost")
    equal(hud.rows[4].name.content, "30 Bone Shield")
    equal(hud.rows[5].name.content, "0 Empty charge")
    hud.settings:set("width", 500)
    hud.settings:set("separate", true)
    hud:render({})
    equal(hud.stacks.debuff.status.width, 500)
    hud:destroy()
end)

test("Ctrl click movement requires neither native drag events nor a held mouse button", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local settings = Settings.new(app.db, error)
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings, function() end)
    hud:render({})
    local source = hud.stacks.buff.heading
    app.input.control = true
    app.input.position = { x = 50, y = 90 }
    source.hooks[ui.Hook.ONCLICK]()
    assert(hud.drag)
    equal(source.hooks[ui.Hook.ONDRAG], nil)
    equal(source.hooks[ui.Hook.ONRELEASE], nil)
    equal(source.hooks[ui.Hook.ONDRAGCOMPLETE], nil)
    app.input.position = { x = 53, y = 93 }
    hud:render({})
    equal(hud.root.x, 35)
    equal(hud.root.y, 83)
    app.input.position = { x = 450, y = 390 }
    hud:render({})
    equal(hud.root.x, 432)
    equal(hud.root.y, 380)
    equal(settings.data.x, 32)
    app.input.position = { x = 500, y = 420 }
    app.input.control = false
    hud:render({})
    equal(hud.drag, nil)
    equal(settings.data.x, 482)
    equal(settings.data.y, 410)
    hud:destroy()
end)

test("native hover only appears when details differ from the displayed name", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, Settings.new(app.db, error), function() end)
    local effect = { key = "buff:incite", name = "Incite Fear", displayName = "Incite Fear",
        tooltip = "Incite Fear", kind = "buff", stacks = 5, active = true,
        fraction = 1, slot = 1, timer = "Active" }
    local groups = { { rows = { effect } } }
    hud:render(groups)
    hud.rows[1].layer.isMouseOver = true
    hud:render(groups)
    equal(hud.tooltip, nil)
    effect.tooltip = "Incite Fear reduces the adrenaline cost of Tsunami."
    hud:render(groups)
    equal(hud.tooltip.root.hidden, false)
    equal(hud.tooltip.text.content, effect.tooltip)
    effect.tooltip = effect.displayName
    hud:render(groups)
    equal(hud.tooltip.root.hidden, true)
    effect.tooltip, effect.displayName = nil, nil
    hud:render(groups)
    equal(hud.tooltip.root.hidden, true)
    hud:destroy()
end)

test("short native labels show the full text on hover and clear stale tooltips", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, Settings.new(app.db, error), function() end)
    local full = "Aftershock: damage you deal builds charge toward an area attack."
    hud.settings:setPosition(900, 740, "buff")
    local groups = { { rows = {
        { key = "buff:aftershock", name = full, displayName = "Aftershock",
            kind = "buff", stacks = 47, stacksPercent = true, active = true,
            fraction = 1, slot = 1, timer = "Active" },
    } } }
    hud:render(groups)
    equal(hud.rows[1].name.content, "47% Aftershock")
    hud.rows[1].layer.isMouseOver = true
    app.input.position = { x = 990, y = 790 }
    hud:render(groups)
    equal(hud.tooltip.text.content, full)
    equal(hud.tooltip.text.configWrites, 1)
    equal(hud.tooltip.text.lineSpacing, 20)
    equal(hud.tooltip.text.maxLines, 0)
    equal(hud.tooltip.text.alignVertical, ui.AlignMode.TOPLEFT)
    equal(hud.tooltip.root.hidden, false)
    assert(hud.tooltip.root.x + hud.tooltip.root.width <= 1000)
    assert(hud.tooltip.root.y + hud.tooltip.root.height <= 800)
    hud.rows[1].layer.isMouseOver = false
    hud:render(groups)
    equal(hud.tooltip.root.hidden, true)
    hud.rows[1].layer.isMouseOver = true
    hud:render(groups)
    app.input.control = true
    Mock.startDrag(hud.rows[1].layer)
    equal(hud.tooltip.root.hidden, true)
    app.input.control = false
    hud:render({})
    equal(hud.tooltip.root.hidden, true)
    hud:destroy()
    equal(hud.tooltip.root.destroyed, true)
end)

test("long hover details scroll without moving the panel or retaining removed effects", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, Settings.new(app.db, error), function() end)
    local effect = { key = "buff:long", name = "Long buff", tooltip = string.rep("Full description. ", 300),
        kind = "buff", active = true, fraction = 1, slot = 1, timer = "Active" }
    local groups = { { rows = { effect } } }
    hud:render(groups)
    hud.rows[1].layer.isMouseOver = true
    hud:render(groups)
    assert(hud.tooltip.scrollMaximum > 0)
    local x, y = hud.tooltip.root.x, hud.tooltip.root.y
    hud.rows[1].layer.isMouseOver = false
    hud.tooltip.root.isMouseOver = true
    hud.tooltip.root.hooks[ui.Hook.ONSCROLLWHEEL](nil, 1)
    hud:render(groups)
    equal(hud.tooltip.body.scrollY, 24)
    equal(hud.tooltip.root.x, x)
    equal(hud.tooltip.root.y, y)
    effect.tooltip = "Shorter updated description."
    hud:render(groups)
    equal(hud.tooltip.text.content, effect.tooltip)
    equal(hud.tooltip.body.scrollY, 0)
    hud:render({})
    equal(hud.tooltip.root.hidden, true)
    hud:destroy()
end)

test("Ctrl click starts movement without jumping and saves only on Ctrl release", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local settings = Settings.new(app.db, error)
    local writes = 0
    local save = app.db.Set
    app.db.Set = function(...)
        writes = writes + 1
        return save(...)
    end
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings, function() end)
    app.input.position = { x = 200, y = 150 }
    app.input.control = true
    hud:render({})
    equal(hud.root.x, 32)
    app.input.shift = true
    hud:render({})
    equal(hud.root.x, 32)
    Mock.startDrag(hud.stacks.buff.heading)
    hud:render({})
    equal(hud.root.x, 32)
    equal(hud.root.y, 80)
    equal(settings.data.x, 32)
    equal(writes, 0)
    app.input.position = { x = 250, y = 175 }
    hud:render({})
    equal(hud.root.x, 82)
    app.input.control = false
    hud:render({})
    equal(settings.data.x, 82)
    equal(settings.data.y, 105)
    equal(writes, 1)
    hud:render({})
    equal(writes, 1)
    equal(Settings.new(app.db, error).data.x, 82)
    app.input.control = false
    Mock.startDrag(hud.stacks.buff.heading)
    equal(hud.drag, nil)
    hud:destroy()
end)

test("the default Ctrl-click bar action starts pointer polling without component drag events", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local settings = Settings.new(app.db, error)
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings, function() end)
    hud:render({ { rows = {
        { key = "buff:test", name = "Test buff", kind = "buff",
            active = true, fraction = 1, slot = 1, timer = "Active" },
    } } })
    hud.rows[1].layer.isMouseOver = true
    local menu = { entries = {} }
    function menu:Add(name, run) self.entries[#self.entries + 1] = { name = name, run = run } end
    hud:menu({ miniMenu = menu })
    equal(#menu.entries, 3)
    equal(menu.entries[3].name, "Warn when missing")
    app.input.control = true
    app.input.position = { x = 50, y = 150 }
    Mock.startDrag(hud.rows[1].layer)
    assert(hud.drag)
    app.input.position = { x = 250, y = 350 }
    hud:updateDrag()
    equal(hud.root.x, 232)
    equal(hud.root.y, 280)
    app.input.control = false
    hud:updateDrag()
    equal(settings.data.x, 232)
    equal(settings.data.y, 280)
    hud:destroy()
end)

test("HUD dragging respects scale bounds blocked input and shutdown", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local settings = Settings.new(app.db, function(message) app.warnings[#app.warnings + 1] = message end)
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    parent.xyGlobal = { x = 20, y = 30 }
    game.options.InterfaceScale.setting = 150
    local hud = Hud.new(parent, settings, function() end)
    app.input.control = true
    app.input.position = { x = 330, y = 270 }
    hud:render({})
    Mock.startDrag(hud.stacks.buff.heading)
    app.input.position = { x = 582, y = 375 }
    hud:render({})
    equal(hud.root.x, 200)
    equal(hud.root.y, 150)
    app.input.blocked = true
    app.input.position = { x = 900, y = 900 }
    hud:render({})
    equal(settings.data.x, 200)
    equal(hud.root.y, 150)
    app.input.blocked = false
    settings:set("separate", true)
    hud:render({})
    Mock.startDrag(hud.stacks.buff.heading)
    app.input.position = { x = 9999, y = 9999 }
    hud:render({})
    equal(hud.root.x, 660)
    equal(hud.root.y, 720)
    app.input.position = { x = -10, y = -10 }
    hud:render({})
    equal(hud.root.x, 0)
    equal(hud.root.y, 0)
    hud:destroy()
    equal(settings.data.x, 0)
    equal(settings.data.y, 0)
    local second = Hud.new(parent, settings, function() end)
    app.input.position = { x = 330, y = 270 }
    second:render({})
    Mock.startDrag(second.stacks.buff.heading)
    app.input.position = { x = 480, y = 420 }
    second:render({})
    app.db.Set = function() return false end
    app.input.available = false
    second:render({})
    equal(settings.data.x, 0)
    equal(settings.data.y, 0)
    equal(second.root.x, 0)
    equal(#app.warnings, 1)
    second:destroy()
end)

test("stack headers combine the plugin name and categories without a second label line", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local settings = Settings.new(app.db, error)
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings, function() end)
    hud:render({})
    equal(hud.stacks.buff.heading.content, "XBB / Buffs / Debuffs")
    equal(hud.stacks.buff.status.content, "")
    equal(hud.stacks.buff.status.hidden, true)
    equal(hud.stacks.buff.body.y, 30)
    equal(hud.stacks.buff.body.height, hud.stacks.buff.root.height - 30)
    settings:set("separate", true)
    hud:render({})
    equal(hud.stacks.buff.heading.content, "XBB / Buffs")
    equal(hud.stacks.debuff.heading.content, "XBB / Debuffs")
    equal(Mock.find(hud.stacks.buff.root, "Settings"), nil)
    equal(Mock.find(hud.stacks.debuff.root, "Settings"), nil)
    equal(hud.stacks.debuff.settingsButton, nil)
    equal(hud.stacks.debuff.heading.width, settings.data.width)
    equal(hud.stacks.buff.heading.width, settings.data.width)
    for _, stack in pairs(hud.stacks) do
        equal(stack.status.hidden, true)
        equal(stack.body.y, 30)
    end
    hud:render({}, "Effect source unavailable")
    for _, stack in pairs(hud.stacks) do
        equal(stack.status.content, "Effect source unavailable")
        equal(stack.status.hidden, false)
        equal(stack.body.y, 60)
        equal(stack.body.height, stack.root.height - 60)
    end
    settings:set("separate", false)
    hud:render({})
    equal(hud.stacks.buff.heading.content, "XBB / Buffs / Debuffs")
    equal(hud.stacks.debuff.root.hidden, true)
    equal(hud.stacks.buff.status.hidden, true)
    equal(hud.stacks.buff.body.y, 30)
    hud:destroy()
end)

test("separate stacks retain independent positions and dragging can be locked", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local Hud = require("xbb/hud")
    local settings = Settings.new(app.db, error)
    settings:set("separate", true)
    local hud = Hud.new(app.components.TOPLEVEL_V2__GAME_AREA, settings, function() end)
    hud:render({})
    app.input.control = true
    app.input.position = { x = 400, y = 90 }
    Mock.startDrag(hud.stacks.debuff.heading)
    app.input.position = { x = 500, y = 190 }
    hud:render({})
    app.input.control = false
    hud:render({})
    equal(settings.data.x, 32)
    equal(settings.data.y, 80)
    equal(settings.data.debuffX, 496)
    equal(settings.data.debuffY, 180)
    equal(hud.stacks.debuff.root.x, 496)
    settings:set("separate", false)
    hud:render({})
    equal(hud.stacks.debuff.root.hidden, true)
    settings:set("separate", true)
    settings:set("dragLocked", true)
    app.input.control = true
    hud:render({})
    equal(hud.stacks.debuff.root.x, 496)
    Mock.startDrag(hud.stacks.buff.heading)
    equal(hud.drag, nil)
    settings:set("dragLocked", false)
    Mock.startDrag(hud.stacks.buff.heading)
    app.input.position = { x = 520, y = 210 }
    hud:render({})
    settings:set("dragLocked", true)
    hud:render({})
    equal(hud.drag, nil)
    equal(settings.data.debuffX, 496)
    local reloaded = Settings.new(app.db, error)
    equal(reloaded.data.dragLocked, true)
    equal(reloaded.data.debuffY, 180)
    hud:destroy()
    equal(hud.stacks.debuff.root.destroyed, true)
end)

test("PrettyUI settings use integer placement and retain every settings tab", function()
    local Mock = require("tests/mock")
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    for _, size in ipairs({ { 1000, 800 }, { 1001, 801 }, { 777, 577 } }) do
        local app = Mock.install()
        local parent = app.components.TOPLEVEL_V2__GAME_AREA
        parent:SetSize(size[1], size[2])
        local view = View.new(parent, Settings.new(app.db, error))
        for _, tab in ipairs({ "Hidden", "Pins", "Missing", "Observed", "Display" }) do
            view.tab = tab
            view:render()
            assert(Mock.find(view.root, "XBB / Xijie Buff Bars"))
            equal(view.group:GetActiveIndex(), ({ Hidden = 2, Pins = 3, Missing = 4, Observed = 5, Display = 1 })[tab])
        end
        view:destroy()
    end
end)

test("PrettyUI placement survives redraw close and reload independently of bar lock", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    local settings = Settings.new(app.db, error)
    settings:set("dragLocked", true)
    local view = View.new(parent, settings)
    equal(view.root.x, 120)
    equal(view.root.y, 120)
    local writes = app.db.writes
    view.window:Close()
    equal(app.db.writes, writes)
    equal(settings.data.settingsWindowPosition, nil)
    view:show()
    local root, window = view.root, view.window
    view.root:SetPos(180, 210)
    view:refresh()
    equal(app.db.writes, writes)
    Mock.click(view.root, "Pins")
    equal(view.root, root)
    equal(view.window, window)
    equal(view.root.x, 180)
    equal(view.root.y, 210)
    equal(settings.data.x, 32)
    equal(settings.data.dragLocked, true)
    view.window:Close()
    equal(app.db.writes, writes + 1)
    view:show()
    equal(view.root.x, 180)
    view:destroy()
    local reopened = View.new(parent, Settings.new(app.db, error))
    equal(reopened.root.x, 180)
    equal(reopened.root.y, 210)
    reopened:destroy()
end)

test("saved PrettyUI placement is clamped when the game area shrinks", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    parent:SetSize(1001, 801)
    parent.xyGlobal = { x = 50, y = 30 }
    game.options.InterfaceScale.setting = 150
    local settings = Settings.new(app.db, error)
    settings:setWindowPosition(9999, 9999)
    local view = View.new(parent, settings)
    equal(view.root.x, 241)
    equal(view.root.y, 241)
    local writes = app.db.writes
    parent:SetSize(777, 577)
    view:refresh()
    equal(view.root.x, 20)
    equal(view.root.y, 20)
    equal(view.root.width, 757)
    equal(view.root.height, 557)
    equal(app.db.writes, writes)
    equal(settings.data.settingsWindowPosition.x, 9999)
    view:destroy()
end)

test("settings refresh preserves the PrettyUI frame tab pagination and scroll", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    local settings = Settings.new(app.db, error)
    local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    view.tab, view.page = "Missing", 2
    view:render()
    local root = view.root
    root:SetPos(180, 210)
    view.group:GetPage(4):SetScrollPosition(20)
    settings:remember({ { key = "buff:test", name = "Test", kind = "buff" } })
    view:refresh()
    equal(view.root, root)
    equal(root.destroyed, nil)
    equal(view.tab, "Missing")
    equal(view.page, 2)
    equal(view.root.x, 180)
    equal(view.root.y, 210)
    equal(view.group:GetPage(4).scrollY, 20)
    local refreshed = view.root
    view:refresh()
    equal(view.root, refreshed)
    view:destroy()
end)

test("rejected PrettyUI placement writes restore saved or centred placement and report", function()
    local Mock = require("tests/mock")
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    for _, saved in ipairs({ false, { x = 60, y = 70 } }) do
        local app = Mock.install()
        if saved then app.db.values.settings = { settingsWindowPosition = saved } end
        local settings = Settings.new(app.db, warn)
        local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
        local x, y, stored = view.root.x, view.root.y, app.db.values.settings
        view.root:SetPos(180, 210)
        view:refresh()
        app.db.Set = function() return false end
        view.window:Close()
        equal(view.root.x, x)
        equal(view.root.y, y)
        equal(app.db.values.settings, stored)
        equal(#app.warnings, 1)
        view:destroy()
    end
end)

test("settings close focus loss and teardown avoid duplicate position saves", function()
    local Mock = require("tests/mock")
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    for _, finish in ipairs({ "close", "focus", "destroy" }) do
        local app = Mock.install()
        local settings = Settings.new(app.db, error)
        local parent = app.components.TOPLEVEL_V2__GAME_AREA
        local view = View.new(parent, settings)
        view.root:SetPos(180, 210)
        view:refresh()
        if finish == "close" then view.window:Close()
        elseif finish == "focus" then view:finishDrag()
        else view:destroy() end
        view:refresh()
        equal(app.db.writes, 1)
        view:destroy()
        equal(app.db.writes, 1)
    end
end)

test("native launchers retain floating settings across remounts focus reload and logout", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    local host = Mock.node()
    app.events.ContentLayerReady.xbb({ component = host })
    Mock.click(host, "Open full settings")
    local function opened()
        for _, child in ipairs(parent.children) do
            if Mock.find(child, "XBB / Xijie Buff Bars") then return child end
        end
        error("floating settings window missing")
    end
    local root = opened()
    root:SetPos(180, 210)
    PluginLogic({ logicTick = 1 })
    app.events.WindowFocusChanged.xbb({ hasFocus = false })
    equal(app.db.values.settings.settingsWindowPosition.x, 180)
    equal(root.destroyed, nil)
    local settingsHost = Mock.node()
    app.events.SettingsLayerReady.xbb({ component = settingsHost })
    Mock.click(settingsHost, "Open full settings")
    equal(opened(), root)
    local replacement = Mock.node()
    app.events.ContentLayerReady.xbb({ component = replacement })
    equal(Mock.find(host, "Open full settings"), nil)
    equal(host.destroyed, nil)
    equal(opened(), root)
    root:SetPos(80, 90)
    PluginLogic({ logicTick = 2 })
    PluginShutdown()
    equal(root.destroyed, true)
    equal(app.db.values.settings.settingsWindowPosition.y, 90)
    local writes = app.db.writes
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    app.events.ContentLayerReady.xbb({ component = replacement })
    Mock.click(replacement, "Open full settings")
    root = opened()
    equal(root.x, 80)
    equal(root.y, 90)
    equal(app.db.writes, writes)
    root:SetPos(100, 110)
    PluginLogic({ logicTick = 1 })
    app.availability(false)
    PluginLogic({ logicTick = 2 })
    equal(root.destroyed, true)
    equal(app.db.values.settings.settingsWindowPosition.x, 100)
    equal(Mock.find(replacement, "Open full settings").enabled, false)
    PluginShutdown()
end)

test("Display exposes drag lock and reset instead of coordinate buttons", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    local settings = Settings.new(app.db, error)
    settings:setPosition(9999, 9999, "buff")
    settings:setPosition(9999, 9999, "debuff")
    local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    assert(Mock.find(view.root, "Open Settings > Gameplay > Interfaces > Buff Bar."))
    assert(Mock.find(view.root, "Turn on the items you want XBB to track."))
    assert(not Mock.find(view.root, "Horizontal position: 9999"))
    assert(not Mock.find(view.root, "Vertical position: 9999"))
    Mock.click(view.root, "Lock bar dragging")
    equal(settings.data.dragLocked, true)
    Mock.click(view.root, "Reset positions")
    equal(settings.data.x, 32)
    equal(settings.data.y, 80)
    equal(settings.data.debuffX, 396)
    equal(settings.data.debuffY, 80)
    equal(settings.data.dragLocked, true)
    view:destroy()
end)

test("Observed actions can undo pins hiding and custom watches without leaving the tab", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    local settings = Settings.new(app.db, error)
    settings:set("separate", true)
    for slot = 1, 100 do
        settings:pin({ key = "debuff:" .. slot, name = "Debuff", kind = "debuff" }, slot, true)
    end
    settings:pin({ key = "buff:other", name = "Other buff", kind = "buff" }, 2, true)
    local target = { key = "buff:target", name = "Target buff", kind = "buff" }
    settings:remember({ target })
    local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    view.tab = "Observed"
    view:render()
    Mock.click(view.root, "Pin")
    equal(settings:findPin(target.key).slot, 1)
    equal(settings:findPin("buff:other").slot, 2)
    equal(settings:findPin("debuff:1").slot, 1)
    settings:pin(target, 4, true)
    Mock.click(view.root, "Unpin")
    equal(settings:findPin(target.key), nil)
    equal(settings:findPin("buff:other").slot, 2)
    Mock.click(view.root, "Hide")
    assert(settings.data.hidden[target.key])
    Mock.click(view.root, "Unhide")
    equal(settings.data.hidden[target.key], nil)
    Mock.click(view.root, "Warn when missing")
    equal(settings.data.rules[target.key].enabled, true)
    Mock.click(view.root, "Remove warning")
    equal(settings.data.rules[target.key], nil)
    settings:watch({ id = target.key, name = target.name, keys = { target.key }, enabled = false })
    view:render()
    Mock.click(view.root, "Remove warning")
    equal(settings.data.rules[target.key], nil)
    equal(view.tab, "Observed")
    local loaded = Settings.new(app.db, error)
    equal(loaded:findPin(target.key), nil)
    equal(loaded.data.hidden[target.key], nil)
    equal(loaded.data.rules[target.key], nil)
    view:destroy()
end)

test("Observed uses short names and identifies buffs and non-watchable debuffs", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    local settings = Settings.new(app.db, error)
    local original = "Ancient elven ritual shard - Currently on cooldown."
    settings:remember({
        { key = "debuff:40899", name = original, kind = "debuff" },
        { key = "buff:example", name = "Long native description.", displayName = "Example buff", kind = "buff" },
    })
    local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    view.tab = "Observed"
    view:render()
    assert(Mock.find(view.root, "Ritual shard CD"))
    assert(Mock.find(view.root, "Example buff"))
    assert(Mock.find(view.root, "Buff"))
    assert(Mock.find(view.root, "Debuff"))
    equal(Mock.find(view.root, original), nil)
    local watchButtons = 0
    local function countButtons(node)
        if node.destroyed then return end
        if node.label == "Warn when missing" then watchButtons = watchButtons + 1 end
        for _, child in ipairs(node.children) do countButtons(child) end
    end
    countButtons(view.root)
    equal(watchButtons, 1)
    view:destroy()
end)

test("Missing deletes manually added rules while presets remain toggles", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    local settings = Settings.new(app.db, error)
    settings:enablePreset("overload", true)
    settings:watch({ id = "buff:legacy", name = "Legacy buff", keys = { "buff:legacy" }, enabled = false })
    local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    view.tab, view.page = "Missing", 99
    view:render()
    Mock.click(view.root, "Delete")
    equal(settings.data.rules["buff:legacy"], nil)
    equal(settings.data.rules.overload.enabled, true)
    view.page = 1
    view:render()
    Mock.click(view.root, "Enabled")
    equal(settings.data.rules.overload.enabled, false)
    equal(settings.data.rules.overload.preset, "overload")
    equal(Mock.find(view.root, "Delete"), nil)
    view:destroy()
end)

test("all settings lists use compact labels for saved effects and custom missing rules", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Settings = require("xbb/settings")
    local View = require("xbb/settings_ui")
    local settings = Settings.new(app.db, error)
    local aftershock = { key = "buff:aftershock", name = "Aftershock: full native details.", kind = "buff" }
    local cached = { key = "buff:example", name = "Full scripted description.", displayName = "Example", kind = "buff" }
    local shard = { key = "debuff:40899", name = "Old full shard text.", kind = "debuff" }
    settings:remember({ cached })
    for _, effect in ipairs({ aftershock, cached, shard }) do
        settings:pin(effect, nil, true)
        settings:hide(effect)
        if effect.kind == "buff" then
            settings:watch({ id = effect.key, name = effect.name, keys = { effect.key }, enabled = true })
        end
    end
    settings = Settings.new(app.db, error)
    local view = View.new(app.components.TOPLEVEL_V2__GAME_AREA, settings)
    for _, tab in ipairs({ "Pins", "Hidden", "Missing" }) do
        view.tab, view.page = tab, tab == "Missing" and 99 or 1
        view:render()
        assert(Mock.find(view.root, "Aftershock"))
        assert(Mock.find(view.root, "Example"))
        if tab ~= "Missing" then assert(Mock.find(view.root, "Ritual shard CD")) end
        equal(Mock.find(view.root, aftershock.name), nil)
        equal(Mock.find(view.root, cached.name), nil)
    end
    equal(settings.data.pins[1].name, aftershock.name)
    equal(settings.data.rules[aftershock.key].name, aftershock.name)
    view:destroy()
end)

test("new native bars leave the timer blank until native timer text arrives", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    config.Param.COMBATV2_BUFF_USES_ABILITY_END = "usesEnd"
    config.Struct.FromID = function(structID)
        return { id = structID, GetParamValue = function(_, param)
            if param == "usesEnd" then return true end
        end }
    end
    local source = Mock.node(nil, ui.ComponentType.LAYER)
    source.opConfig = { opBaseName = "New timed buff" }
    source.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    local timer = Mock.node(source, ui.ComponentType.LABEL)
    timer.content = ""
    app.components.BUFF_BAR__BUFF_1 = source
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    local row = assert(Mock.find(app.components.TOPLEVEL_V2__GAME_AREA, "New timed buff")).parent
    local displayedTimer = row.children[#row.children]
    equal(displayedTimer.content, "")
    timer.content = "30s"
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 5 })
    equal(displayedTimer.content, "30s")
    equal(#app.warnings, 0)
    PluginShutdown()
end)

test("entrypoint preserves false struct metadata", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    config.Param.COMBATV2_BUFF_USES_STACKS = "usesStacks"
    config.Struct.FromID = function(structID)
        equal(structID, 123)
        return { id = 123, GetParamValue = function(_, param)
            equal(param, "usesStacks")
            return false
        end }
    end
    local node = Mock.node(nil, ui.ComponentType.LAYER)
    node.opConfig = { opBaseName = "Timed buff" }
    node.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    Mock.node(node, ui.ComponentType.LABEL).content = "30"
    app.components.BUFF_BAR__BUFF_1 = node
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    assert(Mock.find(app.components.TOPLEVEL_V2__GAME_AREA, "30s"))
    equal(#app.warnings, 0)
    PluginShutdown()
end)

test("entrypoint resolves item config names and persists modifier dragging", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    config.Param.COMBATV2_ABILITY_OBJECT = "item"
    local object = { typeName = "Obj", id = 456, name = "Scripture of Ful" }
    config.Obj = { FromID = function(value)
        equal(value, 456)
        return object
    end }
    config.Struct.FromID = function(structID)
        return { id = structID, GetParamValue = function(_, param)
            if param == "item" then return object end
        end }
    end
    local itemID
    local node = Mock.node(nil, ui.ComponentType.LAYER)
    node.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 21215 end
        if param == "COMBATV2_ABILITY_OBJECT" then return itemID end
    end }
    app.components.BUFF_BAR__BUFF_1 = node
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    assert(Mock.find(app.components.TOPLEVEL_V2__GAME_AREA, "Scripture of Ful"))
    itemID = 456
    app.events.ServerLogic.xbb()
    app.input.control = true
    app.input.position = { x = 300, y = 250 }
    PluginLogic({ logicTick = 5 })
    equal(app.db.values.settings.x, 32)
    local heading = Mock.find(app.components.TOPLEVEL_V2__GAME_AREA, "XBB / Buffs / Debuffs")
    Mock.startDrag(heading)
    app.input.position = { x = 568, y = 420 }
    PluginLogic({ logicTick = 6 })
    equal(heading.parent.x, 300)
    equal(heading.parent.y, 250)
    equal(app.db.values.settings.x, 32)
    app.input.control = false
    PluginLogic({ logicTick = 7 })
    equal(app.db.values.settings.x, 300)
    equal(app.db.values.settings.y, 250)
    equal(#app.warnings, 0)
    app.input.control = true
    Mock.startDrag(heading)
    app.input.position = { x = 588, y = 450 }
    PluginLogic({ logicTick = 20 })
    app.events.WindowFocusChanged.xbb({ hasFocus = false })
    equal(app.db.values.settings.x, 320)
    equal(app.db.values.settings.y, 280)
    PluginShutdown()
    equal(next(app.events.WindowFocusChanged), nil)
end)

test("entrypoint reads the worn pocket slot and native book clock in seconds", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local object = { name = "Scripture of Ful" }
    local valid = true
    Inventory.Find = function(inv)
        equal(inv, config.Inv.WORN)
        return { isValid = valid, GetSlot = function(_, index)
            equal(index, 18)
            return { obj = object }
        end }
    end
    config.Param.COMBATV2_BUFF_USES_ABILITY_END = "usesEnd"
    config.Struct.FromID = function(structID)
        return { id = structID, configName = "COMBATV2_GOD_BOOK_TIMER_DUMMY_ABILITY",
            GetParamValue = function(_, param)
                if param == "usesEnd" then return true end
            end }
    end
    var.VarClient.COMBATV2_COOLDOWN_GOD_BOOK_TIMER_END_EFFECT_CLIENT = { value = 1800500 }
    local node = Mock.node(nil, ui.ComponentType.LAYER)
    node.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 21215 end
    end }
    app.components.BUFF_BAR__BUFF_1 = node
    dofile("main.lua")
    PluginLogic({ logicTick = 500 })
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    assert(Mock.find(parent, "Scripture of Ful"))
    assert(Mock.find(parent, "10:00:00"))
    PluginLogic({ logicTick = 550 })
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 555 })
    assert(Mock.find(parent, "9:59:59"))
    object.name = "Scripture of Jas"
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 560 })
    assert(Mock.find(parent, "Scripture of Jas"))
    valid = false
    var.VarClient.COMBATV2_COOLDOWN_GOD_BOOK_TIMER_END_EFFECT_CLIENT = nil
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 565 })
    assert(Mock.find(parent, "Pocket book"))
    assert(Mock.find(parent, "?"))
    PluginShutdown()
end)

test("entrypoint reads selected quiver ammo from the typed player variable", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local ammo = { typeName = "Obj", id = 1234, name = "Bik arrows" }
    var.VarPlayer.QUIVER_ACTIVE_AMMO = { value = ammo }
    config.Struct.FromID = function(structID)
        return { id = structID, configName = "COMBATV2_BUFF_QUIVER_ACTIVE_AMMO",
            GetParamValue = function() end }
    end
    local node = Mock.node(nil, ui.ComponentType.LAYER)
    node.opConfig = { opBaseName = "Quiver ammo" }
    node.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    app.components.BUFF_BAR__BUFF_1 = node
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    local parent = app.components.TOPLEVEL_V2__GAME_AREA
    local label = assert(Mock.find(parent, "Quiver: Bik arrows"))
    label.parent.isMouseOver = true
    PluginLogic({ logicTick = 5 })
    assert(Mock.find(parent, "Quiver ammo<br>Selected ammo: Bik arrows"))
    ammo.id, ammo.name = 5678, "Ful arrows"
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 10 })
    assert(Mock.find(parent, "Quiver: Ful arrows"))
    assert(Mock.find(parent, "Quiver ammo<br>Selected ammo: Ful arrows"))
    ammo.id, ammo.name = -1, ""
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 15 })
    assert(Mock.find(parent, "Quiver ammo (unavailable)"))
    equal(#app.warnings, 0)
    PluginShutdown()
end)

test("entrypoint renders clan avatar boost and replaces native bars", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    for _, prefix in ipairs({ "BUFF_BAR", "DEBUFF_BAR" }) do
        for index = 1, 50 do
            local empty = Mock.node(nil, ui.ComponentType.LAYER)
            empty.visibleGlobal = true
            empty.paramsConfig = { valid = true, Get = function() return nil end }
            app.components[prefix .. "__BUFF_" .. index] = empty
        end
    end
    config.Param.COMBATV2_BUFF_USES_STACKS = "usesStacks"
    config.Param.COMBATV2_BUFF_USES_STACKS_PERCENT = "usesPercent"
    config.Struct.FromID = function(structID)
        return { id = structID, configName = "COMBATV2_CLAN_AVA_BUFF_LEVEL",
            GetParamValue = function() return true end }
    end
    local node = Mock.node(nil, ui.ComponentType.LAYER)
    node.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 40797 end
    end }
    app.components.BUFF_BAR__BUFF_2 = node
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    assert(Mock.find(app.components.TOPLEVEL_V2__GAME_AREA, "Clan avatar boost"))
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    equal(app.components.DEBUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    equal(#app.warnings, 0)
    PluginShutdown()
end)

test("draw updates discover new visuals and suppress animation resets without metadata scans", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Hud = require("xbb/hud")
    local originalRender, renders, scans = Hud.render, 0, 0
    Hud.render = function(self, ...)
        renders = renders + 1
        return originalRender(self, ...)
    end
    config.Struct.FromID = function(structID)
        scans = scans + 1
        return { id = structID, GetParamValue = function() end }
    end
    local source = Mock.node(nil, ui.ComponentType.LAYER)
    source.opConfig = { opBaseName = "Native animated buff" }
    source.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    local icon = Mock.node(source, ui.ComponentType.SPRITE)
    local timer = Mock.node(source, ui.ComponentType.LABEL)
    timer.content, timer.alpha = "30s", 173
    app.components.BUFF_BAR__BUFF_1 = source
    dofile("main.lua")
    assert(app.events.Draw.xbb, "replacement must run on the frame draw event")
    app.events.Draw.xbb({ timeDeltaSecs = 1 / 144 })
    equal(source.alpha, 255)
    PluginLogic({ logicTick = 0 })
    local addedIcon, addedSlot, addedTimer, staticIcon
    for frame = 1, 20 do
        if frame == 4 then
            addedIcon = Mock.node(source, ui.ComponentType.SPRITE)
            addedSlot = Mock.node(nil, ui.ComponentType.LAYER)
            addedSlot.opConfig = { opBaseName = "New debuff" }
            addedSlot.paramsConfig = { valid = true, Get = function()
                error("draw updates must not read effect metadata")
            end }
            addedTimer = setmetatable({ visible = true, hidden = false,
                type = ui.ComponentType.LABEL, alpha = 61 }, {
                __index = function(_, key)
                    if key == "content" then error("draw updates must not read timer text") end
                end,
            })
            addedSlot.children[#addedSlot.children + 1] = addedTimer
            staticIcon = Mock.node(nil, ui.ComponentType.SPRITE)
            function addedSlot:IterateStaticComponents(callback) callback(staticIcon, true) end
            app.components.DEBUFF_BAR__BUFF_2 = addedSlot
        end
        source.alpha, icon.alpha, timer.alpha = 255, 255, 128
        timer.content = (30 - frame / 100) .. "s"
        app.events.Draw.xbb({ timeDeltaSecs = 1 / 144 })
        equal(source.alpha, 0)
        equal(icon.alpha, 0)
        equal(timer.alpha, 0)
        equal(source.hidden, false)
        equal(timer.visible, true)
        if addedIcon then
            equal(addedIcon.alpha, 0)
            equal(addedSlot.alpha, 0)
            equal(addedTimer.alpha, 0)
            equal(staticIcon.alpha, 0)
            equal(addedTimer.visible, true)
        end
        equal(scans, 1)
        equal(renders, 1)
    end
    addedSlot.paramsConfig = nil
    addedTimer.content = "18s"
    timer.content = "29s"
    PluginLogic({ logicTick = 50 })
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 55 })
    assert(Mock.find(app.components.TOPLEVEL_V2__GAME_AREA, "29s"))
    equal(scans, 2)
    local gameArea = app.components.TOPLEVEL_V2__GAME_AREA
    local host = Mock.node()
    app.events.ContentLayerReady.xbb({ component = host })
    Mock.click(host, "Replace original bars")
    app.events.Draw.xbb({ timeDeltaSecs = 1 / 144 })
    equal(source.alpha, 255)
    equal(timer.alpha, 173)
    equal(addedIcon.alpha, 255)
    equal(addedTimer.alpha, 61)
    equal(staticIcon.alpha, 255)
    Mock.click(host, "Replace original bars")
    app.events.Draw.xbb({ timeDeltaSecs = 1 / 144 })
    equal(icon.alpha, 0)
    app.availability(false)
    app.events.Draw.xbb({ timeDeltaSecs = 1 / 144 })
    equal(icon.alpha, 255)
    PluginLogic({ logicTick = 56 })
    app.events.Draw.xbb({ timeDeltaSecs = 1 / 144 })
    equal(icon.alpha, 255)
    PluginShutdown()
    equal(next(app.events.Draw), nil)
    equal(#app.warnings, 0)
    Hud.render = originalRender
end)

test("visual discovery failures restore native bars without waiting for a source scan", function()
    for _, key in ipairs({ "DEBUFF_BAR__BUFF_RENDER_LAYER", "DEBUFF_BAR__BUFF_50" }) do
        local reader, components = fixture()
        assert(reader:scan())
        equal(reader:replace(true), true)
        local previous = components[key]
        components[key] = nil
        local ok, issue = reader:replace(true)
        equal(ok, false)
        assert(issue:find("unavailable", 1, true))
        equal(components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 255)
        components[key] = previous
        equal(reader:replace(true), true)
        equal(components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
        equal(reader:replace(false), true)
    end
end)

test("entrypoint animates fills at 50 Hz without extra scans or full renders", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local Hud = require("xbb/hud")
    local originalRender, hud, renders, scans = Hud.render, nil, 0, 0
    Hud.render = function(self, ...)
        hud, renders = self, renders + 1
        return originalRender(self, ...)
    end
    config.Struct.FromID = function(structID)
        scans = scans + 1
        return { id = structID, GetParamValue = function() end }
    end
    local source = Mock.node(nil, ui.ComponentType.LAYER)
    source.opConfig = { opBaseName = "Smooth countdown" }
    source.paramsConfig = { valid = true, Get = function(_, param)
        if param == "COMBATV2_BUFF_STRUCT" then return 123 end
    end }
    local timer = Mock.node(source, ui.ComponentType.LABEL)
    timer.content = "5s"
    app.components.BUFF_BAR__BUFF_1 = source
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    local row = hud.rows[1]
    local originalSize, sizeWrites = row.fill.SetSize, 0
    row.fill.SetSize = function(self, ...)
        sizeWrites = sizeWrites + 1
        return originalSize(self, ...)
    end
    local previousWidth = row.fill.width
    for tick = 1, 4 do
        PluginLogic({ logicTick = tick })
        assert(row.fill.width < previousWidth, "fill did not advance on a client tick")
        previousWidth = row.fill.width
        equal(renders, 1)
        equal(scans, 1)
    end
    equal(sizeWrites, 4)
    PluginLogic({ logicTick = 4 })
    equal(sizeWrites, 4)
    PluginLogic({ logicTick = 5 })
    equal(renders, 2)
    equal(scans, 1)
    for tick = 6, 30 do PluginLogic({ logicTick = tick }) end
    timer.content = "4s"
    app.events.ServerLogic.xbb()
    previousWidth = row.fill.width
    PluginLogic({ logicTick = 31 })
    assert(row.fill.width <= previousWidth)
    assert(previousWidth - row.fill.width <= 3, "rounded sample caused a fill jump")
    timer.content = "5s"
    app.events.ServerLogic.xbb()
    previousWidth = row.fill.width
    PluginLogic({ logicTick = 32 })
    assert(row.fill.width > previousWidth, "refresh did not refill on the next client tick")
    equal(scans, 3)
    equal(renders, 7)
    PluginShutdown()
    Hud.render = originalRender
    equal(#app.warnings, 0)
end)

test("entrypoint supports native menus settings replacement and logout cleanup", function()
    local Mock = require("tests/mock")
    local app = Mock.install()
    local gameArea = app.components.TOPLEVEL_V2__GAME_AREA
    dofile("main.lua")
    PluginLogic({ logicTick = 0 })
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    local soulSplit = Mock.node(nil, ui.ComponentType.LAYER)
    soulSplit.opConfig = { opBaseName = "Soul Split" }
    Mock.node(soulSplit, ui.ComponentType.SPRITE)
    app.components.BUFF_BAR__BUFF_1 = soulSplit
    app.events.ServerLogic.xbb()
    PluginLogic({ logicTick = 5 })
    local label = assert(Mock.find(gameArea, "Soul Split"))
    local function findParent(node, child)
        for _, entry in ipairs(node.children) do
            if entry == child then return node end
            local parent = findParent(entry, child)
            if parent then return parent end
        end
    end
    local row = assert(findParent(gameArea, label))
    row.isMouseOver = true
    local menu = { entries = {} }
    function menu:Add(name, run) self.entries[#self.entries + 1] = { label = name, run = run } end
    app.events.MiniMenuReady.xbb({ miniMenu = menu })
    equal(#menu.entries, 3)
    equal(next(app.db.values.settings.hidden), nil)
    local function action(name)
        for _, item in ipairs(menu.entries) do if item.label == name then item.run(); return end end
        error("missing menu action " .. name)
    end
    local host = Mock.node()
    app.events.ContentLayerReady.xbb({ component = host })
    Mock.click(host, "Open full settings")
    Mock.click(gameArea, "Missing")
    for _ = 1, 3 do Mock.click(gameArea, "Next") end
    local tick = 5
    local function refresh()
        tick = tick + 5
        PluginLogic({ logicTick = tick })
        app.events.Draw.xbb({ timeDeltaSecs = 1 / 60 })
    end
    action("Warn when missing")
    refresh()
    assert(Mock.find(gameArea, "Delete"))
    assert(Mock.find(gameArea, "XBB / Xijie Buff Bars"))
    assert(app.db.values.settings.rules["buff:name:soul split"].enabled)
    Mock.click(gameArea, "Pins")
    action("Pin to slot 1")
    refresh()
    assert(Mock.find(gameArea, "Unpin"))
    assert(Mock.find(gameArea, "XBB / Xijie Buff Bars"))
    equal(app.db.values.settings.pins[1].slot, 1)
    menu.entries = {}
    app.events.MiniMenuReady.xbb({ miniMenu = menu })
    action("Unpin")
    refresh()
    equal(Mock.find(gameArea, "Unpin"), nil)
    assert(Mock.find(gameArea, "No items yet."))
    Mock.click(gameArea, "Hidden")
    action("Hide in XBB")
    refresh()
    assert(Mock.find(gameArea, "Restore"))
    assert(app.db.values.settings.hidden["buff:name:soul split"])
    Mock.click(gameArea, "Restore")
    equal(next(app.db.values.settings.hidden), nil)
    Mock.click(gameArea, "Display")
    Mock.click(gameArea, "Separate buff/debuff stacks")
    equal(app.db.values.settings.separate, true)
    refresh()
    Mock.click(gameArea, "Replace original bars")
    refresh()
    equal(soulSplit.alpha, 255)
    equal(soulSplit.children[1].alpha, 255)
    Mock.click(gameArea, "Replace original bars")
    refresh()
    equal(soulSplit.alpha, 0)
    equal(soulSplit.children[1].alpha, 0)
    local settingsRoot = assert(Mock.find(gameArea, "XBB / Xijie Buff Bars")).parent
    refresh()
    equal(settingsRoot.destroyed, nil)
    Mock.click(gameArea, "Close")
    refresh()
    assert(settingsRoot.parent.hidden)
    soulSplit.opConfig.opBaseName = ""
    app.events.ServerLogic.xbb()
    refresh()
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 255)
    equal(soulSplit.children[1].alpha, 255)
    app.events.ServerLogic.xbb()
    equal(#app.warnings, 1)
    soulSplit.opConfig.opBaseName = "Soul Split"
    app.events.ServerLogic.xbb()
    refresh()
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 0)
    equal(soulSplit.children[1].alpha, 0)
    app.availability(false)
    refresh()
    equal(app.components.BUFF_BAR__BUFF_RENDER_LAYER.alpha, 255)
    equal(soulSplit.children[1].alpha, 255)
    PluginShutdown()
    equal(next(app.events.ServerLogic), nil)
    equal(next(app.events.MiniMenuReady), nil)
    equal(next(app.events.SettingsLayerReady), nil)
    equal(next(app.events.ContentLayerReady), nil)
    equal(#app.warnings, 1)
end)

print(count .. " native tests passed")
