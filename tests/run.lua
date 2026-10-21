--[[
XBB / Core regression tests
Exercises Model, Settings, Catalog, and Actions outside the game client.
Uses synthetic effects, caller-controlled time, and in-memory storage.
Covers sorting, timers, pins, missing rules, names, migrations, and save errors.
Run from the repository root with: lua tests/run.lua
]]

package.path = "./?.lua;" .. package.path
local tests = 0
local function test(name, run)
    run()
    tests = tests + 1
    print("PASS " .. name)
end
local function equal(actual, expected)
    assert(actual == expected, string.format("expected %s, got %s", tostring(expected), tostring(actual)))
end
local Settings = require("xbb/settings")
local Model = require("xbb/model")
local Catalog = require("xbb/catalog")
local Actions = require("xbb/actions")
local function settings()
    local db = { values = {} }
    function db:Get(key) return self.values[key] end
    function db:Set(key, value) self.values[key] = value; return true end
    return Settings.new(db, error), db
end
local function effect(key, remaining, kind)
    return { key = key, name = key, kind = kind or "buff",
        timing = remaining == nil and "untimed" or "timed", remaining = remaining }
end
local function rows(model, config, now)
    return model:view(config.data, now or 0)[1].rows
end

test("permanent effects precede timed effects sorted longest first", function()
    local config = settings()
    local model = Model.new()
    model:update({ effect("short", 8), effect("permanent"), effect("long", 360) }, 0)
    local result = rows(model, config)
    equal(result[1].key, "permanent")
    equal(result[2].key, "long")
    equal(result[3].key, "short")
end)

test("stack positions migrate independently and reset without changing other settings", function()
    local db = { values = { settings = { x = 150, y = 200, width = 400 } } }
    function db:Get(key) return self.values[key] end
    function db:Set(key, value) self.values[key] = value; return true end
    local config = Settings.new(db, error)
    equal(config.data.debuffX, 574)
    equal(config.data.debuffY, 200)
    config:setPosition(500, 600, "debuff")
    config:setPosition(300, 400, "buff")
    config:set("dragLocked", true)
    equal(config.data.debuffX, 500)
    local loaded = Settings.new(db, error)
    equal(loaded.data.x, 300)
    equal(loaded.data.debuffY, 600)
    loaded:resetPositions()
    equal(loaded.data.x, 32)
    equal(loaded.data.y, 80)
    equal(loaded.data.debuffX, 456)
    equal(loaded.data.debuffY, 80)
    equal(loaded.data.width, 400)
    equal(loaded.data.dragLocked, true)
    equal(Settings.new(db, error).data.x, 32)
end)

test("position writes and reset failures leave both stacks unchanged", function()
    local config, db = settings()
    config:setPosition(500, 600, "debuff")
    config:setPosition(300, 400, "combined")
    local warnings = {}
    config.report = function(message) warnings[#warnings + 1] = message end
    equal(config:setPosition(100, 200, "invalid"), false)
    equal(config:setPosition(1.5, 200, "buff"), false)
    db.Set = function() return false end
    equal(config:setPosition(100, 200, "debuff"), false)
    equal(config:resetPositions(), false)
    equal(config.data.x, 300)
    equal(config.data.y, 400)
    equal(config.data.debuffX, 500)
    equal(config.data.debuffY, 600)
    equal(#warnings, 4)
end)

test("settings window position is optional persistent and independent of bar positions", function()
    local config, db = settings()
    equal(config.data.settingsWindowPosition, nil)
    equal(db.values.settings, nil)
    equal(config:setWindowPosition(180, 210), true)
    local position = config.data.settingsWindowPosition
    equal(position.x, 180)
    equal(position.y, 210)
    equal(config.data.x, 32)
    equal(config.data.y, 80)
    equal(Settings.new(db, error).data.settingsWindowPosition.y, 210)
    config:resetPositions()
    equal(config.data.settingsWindowPosition.x, 180)
    db.Set = function() error("unchanged window position must not write") end
    local data = config.data
    equal(config:setWindowPosition(180, 210), true)
    equal(config.data, data)
end)

test("invalid and rejected settings window positions report without changing settings", function()
    for _, value in ipairs({ false, "180,210", {}, { x = 10 }, { x = -1, y = 10 },
        { x = 1.5, y = 10 }, { x = 10001, y = 10 }, { x = 10, y = math.huge } }) do
        local warnings = {}
        local db = { Get = function() return { settingsWindowPosition = value, width = 400 } end }
        local config = Settings.new(db, function(message) warnings[#warnings + 1] = message end)
        equal(config.data.settingsWindowPosition, nil)
        equal(config.data.width, 400)
        equal(#warnings, 1)
        assert(warnings[1]:find("settingsWindowPosition", 1, true))
    end
    local config, db = settings()
    config:setWindowPosition(180, 210)
    local data, stored, warnings = config.data, db.values.settings, {}
    config.report = function(message) warnings[#warnings + 1] = message end
    equal(config:setWindowPosition(nil, 10), false)
    equal(config:setWindowPosition(10, -1), false)
    equal(config:setWindowPosition(1.5, 10), false)
    db.Set = function() return false end
    equal(config:setWindowPosition(200, 220), false)
    equal(config.data, data)
    equal(db.values.settings, stored)
    equal(config.data.settingsWindowPosition.x, 180)
    equal(#warnings, 4)
end)

test("percentage count metadata survives the model and pinned rows", function()
    local config = settings()
    local model = Model.new()
    local item = effect("buff:clan")
    item.stacks, item.stacksPercent = 6, true
    config:pin(item, 1, false)
    model:update({ item }, 0)
    equal(rows(model, config)[1].stacks, 6)
    equal(rows(model, config)[1].stacksPercent, true)
end)

test("short labels preserve names and do not shorten unrelated effects", function()
    local config = settings()
    local model = Model.new()
    local item = effect("buff:aftershock")
    item.name = "Aftershock: charged damage is ready to release."
    item.stacks, item.stacksPercent = 47, true
    model:update({ item }, 0)
    equal(rows(model, config)[1].displayName, "Aftershock")
    equal(rows(model, config)[1].name, item.name)
    equal(rows(model, config)[1].key, item.key)
    config:pin(item, 1, true)
    item.displayName, item.tooltip = "Aftershock", "Complete native hover details."
    model:update({ item }, 0)
    equal(rows(model, config)[1].pinned, true)
    equal(rows(model, config)[1].displayName, "Aftershock")
    equal(rows(model, config)[1].tooltip, item.tooltip)
    model:update({}, 0)
    equal(rows(model, config)[1].displayName, "Aftershock")
    equal(rows(model, config)[1].tooltip, item.name)
    item.displayName, item.tooltip = nil, nil
    item.name = "Aftershocking test"
    model:update({ item }, 0)
    equal(rows(model, config)[1].displayName, item.name)
end)

test("short names use mapped headings without loose effect-specific prefix matches", function()
    for _, entry in ipairs({
        { "Aftershock: charged damage is ready.", "Aftershock" },
        { " Crackling cooldown : waiting for the next activation.", "Crackling CD" },
        { "Relentless cooldown\nFull details.", "Relentless CD" },
        { "Equilibrium cooldown: full details.", "Equilibrium CD" },
        { "Enhanced Excalibur cooldown", "Excalibur CD" },
        { "Adrenaline potion cooldown: full details.", "Adrenaline potion CD" },
        { "Powerburst cooldown: full details.", "Powerburst CD" },
        { "Vengeance cooldown: full details.", "Vengeance CD" },
        { "Ruthless: your damage increases after kills.", "Ruthless" },
    }) do
        equal(Catalog.displayName(entry[1]), entry[2])
    end
    equal(Catalog.displayName("Aftershock immunity: unrelated details."), "Aftershock immunity: unrelated details.")
    equal(Catalog.displayName("Crackling active"), "Crackling active")
    equal(Catalog.displayName("Relentless"), "Relentless")
    equal(Catalog.displayName("Equilibrium"), "Equilibrium")
    equal(Catalog.displayName("Unmapped original text", nil, "Crackling cooldown"), "Crackling CD")
    equal(Catalog.displayName("Unmapped original text", nil, "Animate Dead"), "Animate Dead")
end)

test("heading aliases use the canonical entry name rather than separate labels", function()
    local entry = require("xbb/short_names").COMBATV2_AFTERSHOCK_TRACKER
    local original = entry.name
    entry.name = "Renamed display label"
    local catalog = dofile("xbb/catalog.lua")
    entry.name = original
    equal(catalog.displayName("Aftershock: changing details."), "Renamed display label")
    equal(catalog.displayName("Unmapped details", nil, "Aftershock: ability details."), "Renamed display label")
    equal(Catalog.displayName("Aftershock: changing details."), original)
end)

test("all heading aliases are unique and resolve through their canonical entries", function()
    local count, seen = 0, {}
    for _, entry in pairs(require("xbb/short_names")) do
        for _, alias in ipairs(entry.aliases or {}) do
            equal(seen[alias], nil)
            seen[alias], count = true, count + 1
            equal(Catalog.displayName(alias), entry.name)
            equal(Catalog.displayName("  " .. alias:upper() .. "  : Full details."), entry.name)
            equal(Catalog.displayName(alias .. "\nFull details."), entry.name)
            equal(Catalog.displayName("Unmapped details", nil, alias), entry.name)
        end
    end
    equal(count, 13)
end)

test("equal times have a stable deterministic name and identity order", function()
    local config = settings()
    local model = Model.new()
    model:update({ effect("Zebra", 10), effect("alpha", 10), effect("Alpha", 10) }, 0)
    equal(rows(model, config)[1].key, "Alpha")
    equal(rows(model, config)[2].key, "alpha")
end)

test("reviewed short names distinguish cooldowns from active buffs", function()
    for _, entry in ipairs({
        { "COMBATV2_NATURE_BOSS_PRAYER_RESTORER_ACTIVE", "Ritual shard CD" },
        { "COMBATV2_CALORIE_BOMB_DELOYED", "Calorie bomb deploy CD" },
        { "COMBATV2_CALORIE_BOMB_RECIEVED_HEAL", "Calorie bomb heal CD" },
        { "COMBATV2_BUFF_REXKINGS_MAGIC_SHOCKED", "Overcharged" },
        { "COMBATV2_BUFF_EGWD_JAS_BOSS_TIME_WARP", "Warp Time" },
    }) do
        equal(Catalog.displayName("Full native details", entry[1]), entry[2])
    end
    equal(Catalog.displayName("Ancient elven ritual shard - Currently on cooldown."), "Ritual shard CD")
    equal(Catalog.displayName("Legendary Pet Ability: Banking"), "Pet banking CD")
    equal(Catalog.displayName("Legendary Pet Ability: Fertiliser"), "Pet fertiliser CD")
    equal(Catalog.displayName("Legendary Pet Ability: Unknown"), "Legendary Pet Ability: Unknown")
end)

test("native short names survive changing descriptions and absent reserved pins", function()
    local config = settings()
    local model = Model.new()
    local item = effect("debuff:40899", 30, "debuff")
    item.name = "Dynamic ritual shard details."
    config:pin(item, 1, true)
    model:update({ item }, 0)
    local row = rows(model, config)[1]
    equal(row.displayName, "Ritual shard CD")
    equal(row.name, item.name)
    equal(row.tooltip, item.name)
    equal(row.remaining, 30)
    model:update({}, 0)
    row = rows(model, config)[1]
    equal(row.displayName, "Ritual shard CD")
    equal(row.name, item.name)
    equal(row.tooltip, item.name)
    equal(row.key, item.key)
    equal(row.active, false)
    equal(Settings.new(config.db, error).data.pins[1].key, item.key)
end)

test("all reviewed mappings resolve by config identity and complete text without collisions", function()
    local count, ids, texts = 0, {}, {}
    for configName, entry in pairs(require("xbb/short_names")) do
        count = count + 1
        equal(ids[entry.id], nil)
        equal(texts[entry.text:lower()], nil)
        ids[entry.id], texts[entry.text:lower()] = true, true
        equal(Catalog.displayName("Changing native details", configName), entry.name)
        equal(Catalog.displayName(entry.text), entry.name)
        equal(Catalog.displayName("  " .. entry.text:upper() .. "  "), entry.name)
        equal(Catalog.displayName("Unmapped details", nil, entry.text), entry.name)
        for _, kind in ipairs({ "buff", "debuff" }) do
            equal(Catalog.displayName("Changing native details", nil, nil, kind .. ":" .. entry.id), entry.name)
        end
    end
    equal(count, 275)
    equal(Catalog.displayName("Native details", "COMBATV2_NATURE_BOSS_PRAYER_RESTORER_ACTIVE",
        nil, "buff:44999"), "Ritual shard CD")
    equal(Catalog.displayName("Missing: Example", nil, nil, "missing:40899"), "Missing: Example")
end)

test("timers and fills decrease without new snapshots", function()
    local config = settings()
    local model = Model.new()
    model:update({ effect("timed", 20) }, 0)
    equal(rows(model, config, 10)[1].remaining, 10)
    equal(rows(model, config, 10)[1].fraction, 0.5)
    equal(rows(model, config, 25)[1].remaining, 0)
    equal(rows(model, config, 25)[1].fraction, 0)
end)

test("unchanged rounded native timers do not keep extending expiry", function()
    local config = settings()
    local model = Model.new()
    model:update({ effect("timed", 20) }, 0)
    model:update({ effect("timed", 20) }, 0.6)
    equal(rows(model, config, 1)[1].remaining, 19)
end)

test("refreshes refill a bar and missing effects disappear", function()
    local config = settings()
    local model = Model.new()
    model:update({ effect("timed", 20), effect("gone", 5) }, 0)
    model:update({ effect("timed", 30) }, 10)
    equal(#rows(model, config, 10), 1)
    equal(rows(model, config, 10)[1].fraction, 1)
end)

test("rounded server samples do not jump countdowns at sample boundaries", function()
    local config = settings()
    for _, round in ipairs({ math.ceil, math.floor }) do
        local model = Model.new()
        model:update({ effect("timed", 30) }, 0)
        local previous = 30
        for tick = 1, 1449 do
            local now = tick / 50
            if tick % 30 == 0 then
                local before = rows(model, config, now)[1].remaining
                model:update({ effect("timed", round(30 - now)) }, now)
                assert(math.abs(rows(model, config, now)[1].remaining - before) < 0.000001,
                    "rounded sample changed the countdown immediately")
            end
            local row = rows(model, config, now)[1]
            assert(row.remaining <= previous + 0.000001, "countdown moved backwards")
            assert(previous - row.remaining <= 0.031, "countdown stepped instead of animating")
            assert(row.fraction >= 0 and row.fraction <= 1)
            previous = row.remaining
        end
    end
end)

test("repeated rounded readings retain an in-progress correction", function()
    local config = settings()
    local model = Model.new()
    model:update({ effect("timed", 20) }, 0)
    model:update({ effect("timed", 19) }, 0.6)
    assert(math.abs(rows(model, config, 0.6)[1].remaining - 19.4) < 0.000001)
    local before = rows(model, config, 1.2)[1].remaining
    model:update({ effect("timed", 19) }, 1.2)
    equal(rows(model, config, 1.2)[1].remaining, before)
    assert(math.abs(rows(model, config, 2.6)[1].remaining - 17) < 0.000001, "correction was discarded")
end)

test("small refreshes large corrections and native zero are immediate", function()
    local config = settings()
    local model = Model.new()
    model:update({ effect("timed", 5) }, 0)
    model:update({ effect("timed", 4) }, 1)
    model:update({ effect("timed", 4.2) }, 1.2)
    assert(math.abs(rows(model, config, 1.2)[1].remaining - 4.2) < 0.000001)
    model:update({ effect("timed", 1) }, 1.4)
    equal(rows(model, config, 1.4)[1].remaining, 1)
    model:update({ effect("timed", 0) }, 1.6)
    equal(rows(model, config, 1.6)[1].remaining, 0)
    model:update({ effect("timed", 20) }, 2)
    model:update({ effect("timed", 19) }, 10)
    equal(rows(model, config, 10)[1].remaining, 19)
end)

test("hidden effects stay hidden across snapshots and settings reloads", function()
    local config, db = settings()
    local model = Model.new()
    local item = effect("hidden", 20)
    model:update({ item }, 0)
    config:hide(item)
    equal(#rows(model, config), 0)
    local restored = Settings.new(db, error)
    equal(#rows(model, restored), 0)
    restored:restore(item.key)
    equal(#rows(model, restored), 1)
end)

test("pins override automatic sorting at exact slots", function()
    local config = settings()
    local model = Model.new()
    local pinned = effect("short", 2)
    config:pin(pinned, 1, false)
    model:update({ effect("permanent"), effect("long", 100), pinned }, 0)
    equal(rows(model, config)[1].key, "short")
    equal(rows(model, config)[2].key, "permanent")
end)

test("an absent reserved pin leaves a slot and an unreserved pin collapses", function()
    local config = settings()
    local model = Model.new()
    config:pin(effect("reserved"), 2, true)
    config:pin(effect("collapsing"), 3, false)
    config:pin(effect("last"), 4, true)
    model:update({ effect("normal", 40) }, 0)
    local result = rows(model, config)
    equal(#result, 3)
    equal(result[1].key, "normal")
    equal(result[2].key, "reserved")
    equal(result[2].active, false)
    equal(result[3].key, "last")
end)

test("hiding a reserved pin suppresses both its effect and its reservation", function()
    local config = settings()
    local model = Model.new()
    local item = effect("hidden")
    config:pin(item, 1, true)
    config:hide(item)
    model:update({ effect("normal", 40), item }, 0)
    equal(#rows(model, config), 1)
    equal(rows(model, config)[1].key, "normal")
    config:restore(item.key)
    equal(rows(model, config)[1].key, "hidden")
end)

test("moving into an occupied pin slot swaps positions", function()
    local config = settings()
    config:pin(effect("first"), 1, true)
    config:pin(effect("second"), 2, false)
    config:pin(effect("second"), 1, false)
    equal(config:findPin("first").slot, 2)
    equal(config:findPin("second").slot, 1)
    config:unpin("first")
    equal(config:findPin("first"), nil)
end)

test("optional separation retains effects and pins without duplicating rows", function()
    local config = settings()
    local model = Model.new()
    config:set("separate", true)
    config:pin(effect("poison", 30, "debuff"), 1, true)
    model:update({ effect("prayer"), effect("poison", 30, "debuff") }, 0)
    local groups = model:view(config.data, 0)
    equal(#groups, 2)
    equal(groups[1].kind, "buff")
    equal(groups[1].rows[1].key, "prayer")
    equal(groups[2].kind, "debuff")
    equal(groups[2].rows[1].key, "poison")
    config:set("separate", false)
    equal(rows(model, config)[1].key, "poison")
end)

test("automatic pin slots fill gaps and leave existing pin configuration unchanged", function()
    for _, separate in ipairs({ false, true }) do
        local config = settings()
        config:set("separate", separate)
        config:pin(effect("first", nil, "debuff"), 1, true)
        config:pin(effect("second"), 3, true)
        assert(config:pin(effect("new"), nil, false))
        equal(config:findPin("new").slot, separate and 1 or 2)
        equal(config:findPin("first").slot, 1)
        equal(config:findPin("second").slot, 3)
        assert(config:pin(effect("second"), nil, false))
        equal(config:findPin("second").slot, 3)
        equal(config:findPin("second").reserve, true)
    end
end)

test("automatic pinning reports a full stack without changing saved pins", function()
    local config = settings()
    local reports = {}
    config.report = function(message) reports[#reports + 1] = message end
    for slot = 1, 100 do config:pin(effect("buff:" .. slot), slot, true) end
    equal(config:pin(effect("extra"), nil, false), false)
    equal(config:findPin("extra"), nil)
    equal(#config.data.pins, 100)
    equal(#reports, 1)
    assert(reports[1]:find("100 pin slots", 1, true))
end)

test("separate stacks have independent pin slots and combine without collisions", function()
    local config, db = settings()
    config:set("separate", true)
    config:pin(effect("buff", 10), 1, true)
    config:pin(effect("debuff", 10, "debuff"), 1, true)
    equal(config:findPin("buff").slot, 1)
    equal(config:findPin("debuff").slot, 1)
    local restored = Settings.new(db, error)
    equal(#restored.data.pins, 2)
    restored:set("separate", false)
    equal(restored:findPin("buff").slot, 1)
    equal(restored:findPin("debuff").slot, 2)
end)

test("unknown duration is never presented as permanent", function()
    local config = settings()
    local model = Model.new()
    model:update({ { key = "unknown", name = "unknown", kind = "buff", timing = "unknown" },
        effect("permanent"), effect("timed", 10) }, 0)
    equal(rows(model, config)[3].timer, "")
    equal(rows(model, config)[1].timer, "Active")
end)

test("new timers stay blank until resolved and later timing loss remains explicit", function()
    local config = settings()
    local model = Model.new()
    local item = { key = "buff:starting", name = "Starting buff", kind = "buff", timing = "unknown" }
    model:update({ item }, 0)
    local row = rows(model, config)[1]
    equal(row.key, item.key)
    equal(row.active, true)
    equal(row.timer, "")
    model:update({ item }, 0.6)
    equal(rows(model, config, 0.6)[1].timer, "")
    model:update({ effect(item.key, 30) }, 1)
    equal(rows(model, config, 1)[1].timer, "30s")
    model:update({ item }, 1.6)
    equal(rows(model, config, 1.6)[1].timer, "?")
    model:update({}, 2)
    model:update({ item }, 3)
    equal(rows(model, config, 3)[1].timer, "")
    model:update({ effect(item.key) }, 3.6)
    equal(rows(model, config, 3.6)[1].timer, "Active")
end)

test("countdown formatting is readable at second minute and hour boundaries", function()
    equal(Model.formatTime(9.2), "9.2s")
    equal(Model.formatTime(10.1), "11s")
    equal(Model.formatTime(60), "1:00")
    equal(Model.formatTime(3601), "1:00:01")
end)

test("invalid settings and failed writes are visible and never applied", function()
    local reports = {}
    local db = { Get = function() return { width = -1, separate = "bad", pins = "bad" } end,
        Set = function() return false end }
    local config = Settings.new(db, function(message) reports[#reports + 1] = message end)
    equal(config.data.width, 340)
    assert(#reports > 0)
    local ok = config:set("separate", true)
    equal(ok, false)
    equal(config.data.separate, false)
end)

test("effect identities do not collide between buffs and debuffs", function()
    local config = settings()
    local model = Model.new()
    model:update({ effect("buff:123", 10), effect("debuff:123", 8, "debuff") }, 0)
    config:hide(effect("buff:123", 10))
    equal(#rows(model, config), 1)
    equal(rows(model, config)[1].key, "debuff:123")
end)

test("missing combat buffs become optional untimed pseudo-debuffs", function()
    local config = settings()
    local model = Model.new()
    config:watch({ id = "custom", name = "My combat buff", keys = { "buff:123" }, enabled = true })
    model:update({}, 0)
    local item = rows(model, config)[1]
    equal(item.name, "Missing: My combat buff")
    equal(item.kind, "debuff")
    equal(item.missing, true)
    equal(item.timer, "Missing")
    model:update({ effect("buff:123", 10) }, 0)
    equal(#rows(model, config), 1)
    equal(rows(model, config)[1].missing, false)
end)

test("all overload variants satisfy the family but cooldowns and debuffs do not", function()
    local config = settings()
    local model = Model.new()
    config:enablePreset("overload", true)
    for _, name in ipairs({ "Overload", "Elder overload", "Supreme overload salve",
        "Holy overload", "Elder overload salve", "Aggroverload" }) do
        model:update({ effect(name, 300) }, 0)
        equal(#rows(model, config), 1)
    end
    model:update({ effect("Overload cooldown", 30), effect("Overload", 30, "debuff") }, 0)
    equal(#rows(model, config), 3)
end)

test("unnamed buffs pause family warnings but retain identity checks and hidden presence", function()
    local config = settings()
    local model = Model.new()
    config:enablePreset("overload", true)
    config:watch({ id = "observed", name = "Observed", keys = { "buff:123" }, enabled = true })
    config:watch({ id = "absent", name = "Absent", keys = { "buff:456" }, enabled = true })
    local item = effect("buff:123", 10)
    item.name, item.nameUnavailable = "Unknown buff #123", true
    model:update({ item }, 0)
    local result = rows(model, config)
    equal(#result, 2)
    equal(result[1].name, "Missing: Absent")
    equal(result[2].name, "Unknown buff #123")
    config:hide(item)
    equal(#rows(model, config), 1)
    item.nameUnavailable = nil
    model:update({ item }, 0)
    equal(#rows(model, config), 2)
    model:update({}, 0)
    equal(#rows(model, config), 3)
    item.kind, item.key, item.nameUnavailable = "debuff", "debuff:123", true
    model:update({ item }, 0)
    equal(#rows(model, config), 4)
end)

test("pocket book families count activation buffs not equipment or proc effects", function()
    local config = settings()
    local model = Model.new()
    config:enablePreset("pocket", true)
    for _, name in ipairs({ "Pocket book", "God book", "Scripture of Jas", "Erethdor's grimoire",
        "Illuminated Book of Law", "Scripture of Amascut" }) do
        model:update({ effect(name, 300) }, 0)
        equal(#rows(model, config), 1)
    end
    model:update({ effect("Ful's Fury", 10) }, 0)
    equal(#rows(model, config), 2)
end)

test("missing rules use underlying effects even when those effects are hidden", function()
    local config = settings()
    local model = Model.new()
    local item = effect("buff:123", 20)
    config:hide(item)
    config:watch({ id = "required", name = "required", keys = { item.key }, enabled = true })
    model:update({ item }, 0)
    equal(#rows(model, config), 0)
end)

test("unknown source data never generates missing-buff warnings", function()
    local config = settings()
    local model = Model.new()
    config:enablePreset("overload", true)
    equal(#rows(model, config), 0)
    model:update({}, 0)
    equal(#rows(model, config), 1)
    model:unavailable()
    equal(#rows(model, config), 0)
end)

test("removed aura preset is absent from the catalog", function()
    equal(require("xbb/catalog").byID.aura, nil)
end)

test("saved aura checks migrate without losing other rules or leaving reserved warnings", function()
    local _, db = settings()
    db.values.settings = {
        rules = {
            aura = { id = "aura", name = "Aura", preset = "aura", enabled = true },
            weapon_poison = { id = "weapon_poison", name = "Weapon poison",
                preset = "weapon_poison", enabled = true },
        },
        pins = {
            { key = "missing:aura", name = "Missing: Aura", kind = "debuff", slot = 1, reserve = true },
        },
        hidden = { ["missing:aura"] = { key = "missing:aura", name = "Missing: Aura", kind = "debuff" } },
    }
    local config = Settings.new(db, error)
    equal(config.data.rules.aura, nil)
    equal(config.data.rules.weapon_poison.enabled, true)
    equal(#config.data.pins, 0)
    equal(config.data.hidden["missing:aura"], nil)
    equal(db.values.settings.rules.aura, nil)
    local model = Model.new()
    model:update({}, 0)
    equal(rows(model, config)[1].name, "Missing: Weapon poison")
    equal(#rows(model, config), 1)
end)

test("sparse saved pin arrays are rejected rather than silently dropping pins", function()
    local reports = {}
    local first = { key = "first", name = "first", kind = "buff", slot = 1, reserve = true }
    local second = { key = "second", name = "second", kind = "buff", slot = 2, reserve = true }
    local db = { Get = function() return { pins = { first, nil, second } } end }
    local config = Settings.new(db, function(message) reports[#reports + 1] = message end)
    equal(#config.data.pins, 0)
    equal(#reports, 1)
end)

test("missing rules persist and can be disabled restored and pinned", function()
    local config, db = settings()
    local model = Model.new()
    config:enablePreset("overload", true)
    model:update({}, 0)
    local missing = rows(model, config)[1]
    config:pin(missing, 2, true)
    local restored = Settings.new(db, error)
    equal(rows(model, restored)[2].missing, true)
    restored:enablePreset("overload", false)
    equal(rows(model, restored)[2].active, false)
end)

test("removing a custom watch deletes its warning state without changing the buff or presets", function()
    local config, db = settings()
    local model = Model.new()
    local item = effect("buff:custom")
    config:remember({ item })
    config:pin(item, 1, true)
    config:hide(item)
    Actions.watch(config, item, true)
    model:update({}, 0)
    local warning = rows(model, config)[1]
    equal(warning.key, "missing:" .. item.key)
    config:remember({ warning })
    config:pin(warning, 2, true)
    config:hide(warning)
    config:enablePreset("overload", true)
    equal(Actions.watch(config, item, false), true)
    local restored = Settings.new(db, error)
    equal(restored.data.rules[item.key], nil)
    equal(restored.data.hidden[warning.key], nil)
    equal(restored.data.known[warning.key], nil)
    equal(restored:findPin(warning.key), nil)
    assert(restored.data.hidden[item.key])
    assert(restored.data.known[item.key])
    equal(restored:findPin(item.key).slot, 1)
    equal(restored.data.rules.overload.enabled, true)
    restored:enablePreset("overload", false)
    equal(restored.data.rules.overload.enabled, false)
end)

test("failed custom-watch deletion keeps the rule and warning settings intact", function()
    local config, db = settings()
    local item = effect("buff:custom")
    Actions.watch(config, item, true)
    local warning = effect("missing:" .. item.key, nil, "debuff")
    config:pin(warning, 1, true)
    config:hide(warning)
    config:remember({ warning })
    local previous, reports = config.data, {}
    config.report = function(message) reports[#reports + 1] = message end
    db.Set = function() return false end
    equal(Actions.watch(config, item, false), false)
    equal(config.data, previous)
    equal(#reports, 1)
end)

test("observed metadata preserves compact names and hover details across reloads and updates", function()
    local config, db = settings()
    local item = effect("buff:example")
    item.name, item.displayName, item.tooltip = "Full native name.", "Short name", "Full hover details."
    config:remember({ item })
    local loaded = Settings.new(db, error)
    equal(loaded.data.known[item.key].name, item.name)
    equal(loaded.data.known[item.key].displayName, item.displayName)
    equal(loaded.data.known[item.key].tooltip, item.tooltip)
    item.displayName, item.tooltip = "Updated name", "Updated hover details."
    loaded:remember({ item })
    loaded = Settings.new(db, error)
    equal(loaded.data.known[item.key].displayName, item.displayName)
    equal(loaded.data.known[item.key].tooltip, item.tooltip)
end)

test("unchanged observed metadata does not copy or save settings", function()
    local config, db = settings()
    local item = effect("buff:example")
    config:remember({ item })
    local previous, copies, writes = config.data, 0, 0
    setmetatable(previous, { __pairs = function(value)
        copies = copies + 1
        return next, value, nil
    end })
    local save = db.Set
    db.Set = function(...)
        writes = writes + 1
        return save(...)
    end
    equal(config:remember({ item }), true)
    equal(config:remember({}), true)
    equal(copies, 0)
    equal(writes, 0)
    equal(config.data, previous)
    item.displayName = "Updated label"
    equal(config:remember({ item }), true)
    equal(copies, 1)
    equal(writes, 1)
    equal(config.data.known[item.key].displayName, item.displayName)
end)

test("failed observed metadata updates leave the current settings intact", function()
    local config, db = settings()
    local item = effect("buff:example")
    config:remember({ item })
    local previous, reports = config.data, {}
    config.report = function(message) reports[#reports + 1] = message end
    db.Set = function() return false end
    item.displayName = "Changed label"
    equal(config:remember({ item }), false)
    equal(config.data, previous)
    equal(config.data.known[item.key].displayName, nil)
    equal(#reports, 1)
end)

test("saved effect labels resolve compact names without changing identities", function()
    local known = { ["buff:example"] = { name = "Long native description.", displayName = "Example" } }
    equal(Catalog.entryName({ key = "buff:example", name = "Old name" }, known), "Example")
    equal(Catalog.entryName({ id = "buff:example", name = "Old name" }, known), "Example")
    equal(Catalog.entryName({ key = "debuff:40899", name = "Old full text" }, {}), "Ritual shard CD")
    equal(Catalog.entryName({ key = "missing:buff:example", name = "Missing: Old name" }, known), "Missing: Example")
    equal(Catalog.entryName({ key = "missing:overload", name = "Missing: Overload" }, {}), "Missing: Overload")
    equal(Catalog.entryName({ id = "custom", name = "Either buff" }, known), "Either buff")
end)

test("custom missing bars and absent reserved pins keep cached compact names", function()
    local config = settings()
    local item = effect("buff:example")
    item.name, item.displayName = "Long scripted native description.", "Example"
    config:remember({ item })
    config:pin(item, 1, true)
    Actions.watch(config, item, true)
    local model = Model.new()
    model:update({}, 0)
    local result = rows(model, config)
    equal(result[1].displayName, "Example")
    equal(result[1].name, item.name)
    equal(result[2].displayName, "Missing: Example")
    equal(result[2].name, "Missing: " .. item.name)
    equal(config.data.rules[item.key].name, item.name)
end)

test("the buff menu omits the redundant settings shortcut", function()
    local config = settings()
    for _, action in ipairs(Actions.items(config, effect("buff:example"), 1)) do
        assert(action.label ~= "XBB settings")
    end
end)

test("the buff menu deletes disabled custom watches rather than re-enabling them", function()
    local config = settings()
    local item = effect("buff:legacy")
    config:watch({ id = item.key, name = item.name, keys = { item.key }, enabled = false })
    local removed = false
    for _, action in ipairs(Actions.items(config, item, 1)) do
        if action.label == "Remove missing warning" then
            action.run()
            removed = true
        end
    end
    equal(removed, true)
    equal(config.data.rules[item.key], nil)
end)

print(tests .. " core tests passed")
