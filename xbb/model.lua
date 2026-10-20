--[[
XBB / Effect model
Transforms reader snapshots and settings into ordered HUD row groups.
Tracks expiry, blends rounded timer corrections, and formats countdowns.
Applies hiding, pin reservations, and opt-in missing-buff rules.
Uses caller-supplied time without native UI access or persistent writes.
]]

local Model = {}
Model.__index = Model
local Catalog = require("xbb/catalog")
local roundingTolerance, correctionDuration = 1, 2

local function expiryAt(effect, now)
    if not effect.targetExpiry then return effect.expiry end
    local progress = math.max(0, math.min(1, (now - effect.correctionStart) / correctionDuration))
    return effect.expiry + (effect.targetExpiry - effect.expiry) * progress
end

function Model.new()
    return setmetatable({ effects = {}, available = false }, Model)
end

function Model.formatTime(seconds)
    if seconds < 10 then return string.format("%.1fs", seconds) end
    local value = math.ceil(seconds)
    if value < 60 then return value .. "s" end
    if value < 3600 then return string.format("%d:%02d", math.floor(value / 60), value % 60) end
    return string.format("%d:%02d:%02d", math.floor(value / 3600), math.floor(value / 60) % 60, value % 60)
end

function Model.countdown(effect, now)
    local remaining = effect.expiry and math.max(0, expiryAt(effect, now) - now) or nil
    local fraction = remaining and (effect.duration > 0 and remaining / effect.duration or 0) or 1
    local timer
    if remaining then timer = Model.formatTime(remaining)
    elseif effect.timing == "untimed" then timer = "Active"
    else timer = effect.hadTiming and "?" or "" end
    return remaining, fraction, timer
end

function Model:update(snapshot, now)
    local nextEffects = {}
    for _, effect in ipairs(snapshot) do
        assert(type(effect.key) == "string" and type(effect.name) == "string", "effect requires identity and name")
        assert(effect.kind == "buff" or effect.kind == "debuff", "invalid effect kind")
        assert(effect.timing == "timed" or effect.timing == "untimed" or effect.timing == "unknown", "invalid timing")
        assert(not nextEffects[effect.key], "duplicate effect: " .. effect.key)
        local previous = self.effects[effect.key]
        local item = {}
        for key, value in pairs(effect) do item[key] = value end
        item.hadTiming = effect.timing ~= "unknown" or (previous and previous.hadTiming) or false
        if effect.timing == "timed" then
            assert(type(effect.remaining) == "number" and effect.remaining >= 0
                and effect.remaining < math.huge, "invalid remaining duration")
            item.expiry = now + effect.remaining
            if previous and previous.expiry and effect.remaining > 0 then
                local currentExpiry = expiryAt(previous, now)
                -- Repeated samples retain expiry; small downward corrections blend.
                if previous.observed == effect.remaining then
                    item.expiry, item.targetExpiry = previous.expiry, previous.targetExpiry
                    item.correctionStart = previous.correctionStart
                elseif effect.remaining < previous.observed
                    and math.abs(item.expiry - currentExpiry) <= roundingTolerance then
                    item.targetExpiry, item.expiry = item.expiry, currentExpiry
                    item.correctionStart = now
                end
            end
            item.duration = math.max(effect.remaining, effect.total or 0, previous and previous.duration or 0)
            item.observed = effect.remaining
        end
        nextEffects[item.key] = item
    end
    self.effects, self.available = nextEffects, true
end

function Model:unavailable()
    self.effects, self.available = {}, false
end

local function matches(rule, effect)
    if effect.kind ~= "buff" or effect.isCooldown then return false end
    local name = effect.name:lower()
    if name:find("cooldown", 1, true) then return false end
    if rule.preset then return Catalog.matches(rule.preset, effect) end
    for _, key in ipairs(rule.keys) do if effect.key == key then return true end end
    return false
end

local function activeRow(effect, now)
    local remaining, fraction, timer = Model.countdown(effect, now)
    return { key = effect.key, name = effect.name, kind = effect.kind, timing = effect.timing,
        displayName = effect.displayName or Catalog.displayName(effect.name, nil, nil, effect.key),
        tooltip = effect.tooltip or effect.name,
        remaining = remaining, fraction = fraction, timer = timer,
        stacks = effect.stacks, stacksPercent = effect.stacksPercent,
        active = true, missing = false, pinned = false, reserved = false }
end

local function arrange(effects, config, kind)
    local byKey, automatic, pinned, slots = {}, {}, {}, {}
    for _, effect in ipairs(effects) do
        if not config.hidden[effect.key] and (kind == "combined" or effect.kind == kind) then
            byKey[effect.key] = effect
        end
    end
    local collapsed = 0
    local pins = {}
    for _, pin in ipairs(config.pins) do
        if kind == "combined" or pin.kind == kind then pins[#pins + 1] = pin end
    end
    table.sort(pins, function(a, b) return a.slot < b.slot end)
    local maximum = 0
    for _, pin in ipairs(pins) do
        local effect = byKey[pin.key]
        if config.hidden[pin.key] or (not effect and not pin.reserve) then
            -- Hidden and absent non-reserved pins each collapse one slot.
            collapsed = collapsed + 1
        else
            local slot = math.max(1, pin.slot - collapsed)
            local item = effect or { key = pin.key, name = pin.name, kind = pin.kind,
                displayName = Catalog.entryName(pin, config.known), tooltip = pin.name,
                active = false, missing = false, fraction = 0, timer = "--" }
            item.pinned, item.reserved = true, pin.reserve
            slots[slot], pinned[pin.key] = item, true
            maximum = math.max(maximum, slot)
        end
    end
    for key, effect in pairs(byKey) do if not pinned[key] then automatic[#automatic + 1] = effect end end
    local rank = { untimed = 1, timed = 2, unknown = 3 }
    table.sort(automatic, function(a, b)
        local ar, br = rank[a.timing], rank[b.timing]
        if ar ~= br then return ar < br end
        if a.remaining ~= b.remaining then return (a.remaining or 0) > (b.remaining or 0) end
        if a.name:lower() ~= b.name:lower() then return a.name:lower() < b.name:lower() end
        return a.key < b.key
    end)
    local slot = 1
    for _, effect in ipairs(automatic) do
        while slots[slot] do slot = slot + 1 end
        slots[slot], maximum = effect, math.max(maximum, slot)
        slot = slot + 1
    end
    local result = {}
    for index = 1, maximum do
        local item = slots[index] or { active = false, fraction = 0, timer = "", name = "", kind = kind }
        item.slot = index
        result[index] = item
    end
    return { kind = kind, rows = result }
end

function Model:view(config, now)
    if not self.available then
        return config.separate and { { kind = "buff", rows = {} }, { kind = "debuff", rows = {} } }
            or { { kind = "combined", rows = {} } }
    end
    local effects, unnamedBuff = {}, false
    for _, effect in pairs(self.effects) do
        effects[#effects + 1] = activeRow(effect, now)
        if effect.kind == "buff" and effect.nameUnavailable and not effect.isCooldown then unnamedBuff = true end
    end
    -- Presence checks include effects hidden from the rendered bars.
    for _, rule in pairs(config.rules) do
        -- An unnamed buff may satisfy any name-based family.
        if rule.enabled and not (rule.preset and unnamedBuff) then
            local found = false
            for _, effect in pairs(self.effects) do if matches(rule, effect) then found = true; break end end
            if not found then
                effects[#effects + 1] = { key = "missing:" .. rule.id, name = "Missing: " .. rule.name,
                    displayName = "Missing: " .. Catalog.entryName(rule, config.known),
                    kind = "debuff", timing = "untimed", fraction = 1, timer = "Missing",
                    active = true, missing = true, pinned = false, reserved = false }
            end
        end
    end
    if config.separate then return { arrange(effects, config, "buff"), arrange(effects, config, "debuff") } end
    return { arrange(effects, config, "combined") }
end

return Model
