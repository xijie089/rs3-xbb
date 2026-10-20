--[[
XBB / Persistent settings
Validates and migrates local configuration and remembered effect metadata.
Stores layout, hidden effects, pins, missing rules, and known effects via the
injected PersistentDB adapter. Changes use copies of the current settings.
Replaces the current data table only after a successful persistent write.
Reports invalid values and rejected writes through the supplied callback.
]]

local Settings = {}
Settings.__index = Settings
local Catalog = require("xbb/catalog")

local defaults = { separate = false, replaceNative = true, dragLocked = false, width = 340, height = 28,
    gap = 4, x = 32, y = 80, debuffX = 396, debuffY = 80, hidden = {}, pins = {}, rules = {}, known = {} }
local ranges = { width = { 240, 640 }, height = { 24, 48 }, gap = { 0, 16 },
    x = { 0, 10000 }, y = { 0, 10000 }, debuffX = { 0, 10000 }, debuffY = { 0, 10000 } }

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function integer(value, minimum, maximum)
    return type(value) == "number" and value == math.floor(value)
        and value >= minimum and value <= maximum
end

local function identity(value)
    return type(value) == "table" and type(value.key) == "string" and value.key ~= ""
        and type(value.name) == "string" and (value.kind == "buff" or value.kind == "debuff")
        and (value.displayName == nil or type(value.displayName) == "string")
        and (value.tooltip == nil or type(value.tooltip) == "string")
end

local function validRule(rule)
    if type(rule) ~= "table" or type(rule.id) ~= "string" or rule.id == ""
        or type(rule.name) ~= "string" or rule.name == "" or type(rule.enabled) ~= "boolean" then return false end
    if rule.preset then return Catalog.byID[rule.preset] ~= nil end
    if type(rule.keys) ~= "table" or #rule.keys == 0 then return false end
    for _, key in ipairs(rule.keys) do if type(key) ~= "string" or key == "" then return false end end
    return true
end

local function removeRule(data, key)
    data.rules[key] = nil
    local missingKey = "missing:" .. tostring(key)
    for _, field in ipairs({ "hidden", "known" }) do
        if type(data[field]) == "table" then data[field][missingKey] = nil end
    end
    if type(data.pins) == "table" then
        for i = #data.pins, 1, -1 do
            local pin = data.pins[i]
            if type(pin) == "table" and pin.key == missingKey then table.remove(data.pins, i) end
        end
    end
end

function Settings.new(db, report)
    local self = setmetatable({ db = db, report = report, data = copy(defaults) }, Settings)
    local stored = db:Get("settings")
    if stored ~= nil and type(stored) ~= "table" then
        report("XBB: invalid saved settings; using defaults")
        return self
    end
    -- Retired aura presets also remove their saved warning placeholders.
    local migrated = false
    if stored and type(stored.rules) == "table" then
        stored = copy(stored)
        for key, rule in pairs(stored.rules) do
            if type(rule) == "table" and rule.preset == "aura" then
                removeRule(stored, key)
                migrated = true
            end
        end
    end
    for key, value in pairs(stored or {}) do
        local valid
        if ranges[key] then valid = integer(value, ranges[key][1], ranges[key][2])
        elseif key == "separate" or key == "replaceNative" or key == "dragLocked" then valid = type(value) == "boolean"
        elseif key == "hidden" or key == "pins" or key == "rules" or key == "known" then
            valid = type(value) == "table"
            local used, slots, entryCount = {}, {}, 0
            if valid then
                for entryKey, item in pairs(value) do
                    entryCount = entryCount + 1
                    local ok
                    if key == "rules" then
                        ok = validRule(item) and entryKey == item.id
                    elseif key == "hidden" or key == "known" then
                        ok = identity(item) and entryKey == item.key
                    else
                        ok = integer(entryKey, 1, #value) and identity(item)
                            and integer(item.slot, 1, 100) and type(item.reserve) == "boolean"
                            and not used[item.key]
                            and not slots[(stored.separate == true and item.kind or "") .. item.slot]
                        if ok then
                            used[item.key] = true
                            slots[(stored.separate == true and item.kind or "") .. item.slot] = true
                        end
                    end
                    if not ok then valid = false; break end
                end
                if key == "pins" and entryCount ~= #value then valid = false end
            end
        end
        if valid then self.data[key] = copy(value)
        elseif defaults[key] ~= nil then report("XBB: invalid saved " .. key .. "; using default") end
    end
    -- Older layouts placed debuffs beside the buff stack.
    if stored and stored.debuffX == nil then self.data.debuffX = math.min(10000, self.data.x + self.data.width + 24) end
    if stored and stored.debuffY == nil then self.data.debuffY = self.data.y end
    if migrated then self:save(self.data) end
    return self
end

function Settings:save(nextData)
    if self.db:Set("settings", copy(nextData)) == false then
        self.report("XBB: settings could not be saved; change not applied")
        return false
    end
    -- Apply configuration only after a successful persistent write.
    self.data = nextData
    return true
end

function Settings:resetPositions()
    local data = copy(self.data)
    data.x, data.y = defaults.x, defaults.y
    data.debuffX, data.debuffY = defaults.x + data.width + 24, defaults.y
    return self:save(data)
end

function Settings:setPosition(x, y, kind)
    if (kind ~= nil and kind ~= "buff" and kind ~= "combined" and kind ~= "debuff")
        or not integer(x, ranges.x[1], ranges.x[2]) or not integer(y, ranges.y[1], ranges.y[2]) then
        self.report("XBB: invalid HUD position")
        return false
    end
    local data = copy(self.data)
    if kind == "debuff" then data.debuffX, data.debuffY = x, y
    else data.x, data.y = x, y end
    return self:save(data)
end

function Settings:set(key, value)
    local range = ranges[key]
    if not ((range and integer(value, range[1], range[2]))
        or ((key == "separate" or key == "replaceNative" or key == "dragLocked") and type(value) == "boolean")) then
        self.report("XBB: invalid setting " .. tostring(key))
        return false
    end
    local data = copy(self.data)
    data[key] = value
    if key == "separate" and not value then
        local occupied = {}
        table.sort(data.pins, function(a, b)
            if a.slot ~= b.slot then return a.slot < b.slot end
            return a.key < b.key
        end)
        for _, pin in ipairs(data.pins) do
            while occupied[pin.slot] do pin.slot = pin.slot + 1 end
            if pin.slot > 100 then
                self.report("XBB: combined pins exceed 100 slots; unpin items before combining")
                return false
            end
            occupied[pin.slot] = true
        end
    end
    return self:save(data)
end

function Settings:hide(effect)
    assert(identity(effect), "invalid effect identity")
    local data = copy(self.data)
    data.hidden[effect.key] = { key = effect.key, name = effect.name, kind = effect.kind }
    return self:save(data)
end

function Settings:restore(key)
    local data = copy(self.data)
    data.hidden[key] = nil
    return self:save(data)
end

function Settings:findPin(key)
    for _, item in ipairs(self.data.pins) do if item.key == key then return copy(item) end end
end

-- An omitted slot preserves an existing pin or selects the first free slot.
function Settings:pin(effect, slot, reserve)
    if not identity(effect) or (slot ~= nil and not integer(slot, 1, 100)) or type(reserve) ~= "boolean" then
        self.report("XBB: pin slot must be an integer from 1 to 100")
        return false
    end
    local data, previous = copy(self.data), self:findPin(effect.key)
    if previous and slot == nil then return true end
    local free = previous and previous.slot or 1
    local occupied = {}
    for _, item in ipairs(data.pins) do
        if not data.separate or item.kind == effect.kind then occupied[item.slot] = true end
    end
    if not previous then while occupied[free] do free = free + 1 end end
    if free > 100 then self.report("XBB: all 100 pin slots are occupied"); return false end
    slot = slot or free
    local result = {}
    for _, item in ipairs(data.pins) do
        if item.key ~= effect.key then
            -- Explicit moves swap an occupied pin into the previous or first free slot.
            if item.slot == slot and (not data.separate or item.kind == effect.kind) then item.slot = free end
            result[#result + 1] = item
        end
    end
    result[#result + 1] = { key = effect.key, name = effect.name, kind = effect.kind,
        slot = slot, reserve = reserve }
    table.sort(result, function(a, b)
        if a.slot ~= b.slot then return a.slot < b.slot end
        return a.key < b.key
    end)
    data.pins = result
    return self:save(data)
end

function Settings:unpin(key)
    local data, result = copy(self.data), {}
    for _, item in ipairs(data.pins) do if item.key ~= key then result[#result + 1] = item end end
    data.pins = result
    return self:save(data)
end

function Settings:watch(rule)
    if not validRule(rule) then self.report("XBB: invalid missing-buff rule"); return false end
    local data = copy(self.data)
    data.rules[rule.id] = copy(rule)
    return self:save(data)
end

function Settings:enablePreset(preset, enabled)
    local entry = Catalog.byID[preset]
    if not entry then self.report("XBB: unknown missing-buff preset"); return false end
    return self:watch({ id = preset, name = entry.name,
        preset = preset, enabled = enabled })
end

function Settings:remember(snapshot)
    local data
    for _, item in ipairs(snapshot) do
        local previous = (data or self.data).known[item.key]
        if not previous or previous.name ~= item.name or previous.kind ~= item.kind
            or previous.displayName ~= item.displayName or previous.tooltip ~= item.tooltip then
            data = data or copy(self.data)
            data.known[item.key] = { key = item.key, name = item.name, kind = item.kind,
                displayName = item.displayName, tooltip = item.tooltip }
        end
    end
    if data then return self:save(data) end
    return true
end

function Settings:removeWatch(key)
    local data = copy(self.data)
    removeRule(data, key)
    return self:save(data)
end

return Settings
