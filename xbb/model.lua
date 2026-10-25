--[[
XBB / Effect model
Transforms reader snapshots and settings into ordered HUD row groups.
Tracks expiry, blends rounded timer corrections, and formats countdowns.
Normalizes duration from first appearance and precision-aware timer readings.
Retains measured durations for pending timers on later appearances.
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

local function copyExpiry(item, previous)
    item.expiry, item.targetExpiry = previous.expiry, previous.targetExpiry
    item.correctionStart = previous.correctionStart
end

local function fitsBucket(remaining, lower, precision)
    return remaining >= lower - roundingTolerance and remaining <= lower + precision + roundingTolerance
end

function Model.new(known)
    local durations = {}
    for key, item in pairs(known or {}) do
        if item.duration ~= nil then
            assert(type(item.duration) == "number" and item.duration > 0
                and item.duration < math.huge, "invalid learned duration")
            durations[key] = item.duration
        end
    end
    return setmetatable({ effects = {}, durations = durations, available = false }, Model)
end

function Model.formatTime(seconds)
    if seconds < 10 then return string.format("%.1fs", seconds) end
    local value = math.ceil(seconds - 0.000000001)
    if value < 60 then return value .. "s" end
    if value < 3600 then return string.format("%d:%02d", math.floor(value / 60), value % 60) end
    return string.format("%d:%02d:%02d", math.floor(value / 3600), math.floor(value / 60) % 60, value % 60)
end

function Model.countdown(effect, now)
    local remaining = effect.expiry and math.max(0, expiryAt(effect, now) - now) or nil
    local fraction = remaining and (effect.duration > 0 and remaining / effect.duration or 0) or 1
    local timer
    if remaining then timer = (effect.estimated and "~" or "") .. Model.formatTime(remaining)
    elseif effect.timing == "timed" and effect.timerPrecision and effect.timerPrecision > 1 then
        timer = "~" .. (effect.timerText or Model.formatTime(effect.remaining))
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
        item.firstSeen = previous and previous.firstSeen or now
        item.duration = previous and previous.duration
        item.estimated = previous and previous.estimated
        item.calibrated = previous and previous.calibrated or false
        item.hadTiming = effect.timing ~= "unknown" or (previous and previous.hadTiming) or false
        if effect.timing == "timed" then
            assert(type(effect.remaining) == "number" and effect.remaining >= 0
                and effect.remaining < math.huge, "invalid remaining duration")
            local precision = effect.timerPrecision or 1
            assert(type(precision) == "number" and precision > 0 and precision < math.huge,
                "invalid timer precision")
            local coarse = precision > 1
            local boundary = coarse and previous and previous.timerPrecision == precision
                and previous.observed and previous.observed - effect.remaining == precision
                and previous.sampledAt and now >= previous.sampledAt
                and now - previous.sampledAt <= roundingTolerance
            if coarse and not boundary then
                item.estimated = true
                if previous and previous.expiry
                    and fitsBucket(math.max(0, expiryAt(previous, now) - now), effect.remaining, precision) then
                    copyExpiry(item, previous)
                    item.estimated = previous.estimated
                else
                    local refreshed = previous and previous.observed
                        and previous.timerPrecision == precision and effect.remaining > previous.observed
                    if previous and previous.expiry then
                        item.duration, item.calibrated = nil, false
                    end
                    if refreshed then
                        item.firstSeen, item.duration, item.calibrated = now, nil, false
                    end
                    local learned = self.durations[item.key]
                    if learned and (not previous or not previous.hadTiming or refreshed)
                        and fitsBucket(learned - math.max(0, now - item.firstSeen), effect.remaining, precision) then
                        item.duration, item.expiry = learned, item.firstSeen + learned
                    end
                end
            else
                -- A downward unit transition crosses the next bucket's upper edge.
                local remaining = coarse and effect.remaining + precision or effect.remaining
                item.expiry = now + remaining
                if not item.duration or (not item.calibrated
                    and not (previous and previous.expiry and previous.observed)) then
                    item.duration = remaining + math.max(0, now - item.firstSeen)
                end
                if previous and previous.expiry and remaining > 0 then
                    local currentExpiry = expiryAt(previous, now)
                    local correction = item.expiry - currentExpiry
                    local repeated = not coarse and previous.observed == effect.remaining
                        and (previous.timerPrecision or 1) == precision and math.abs(correction) <= roundingTolerance
                    if repeated or (boundary and math.abs(correction) <= roundingTolerance) then
                        copyExpiry(item, previous)
                    elseif previous.observed then
                        if boundary or (not coarse and (previous.timerPrecision or 1) > 1)
                            or correction < -roundingTolerance then
                            item.duration = math.max(remaining, item.duration + correction)
                        elseif effect.remaining < previous.observed and math.abs(correction) <= roundingTolerance then
                            item.targetExpiry, item.expiry = item.expiry, currentExpiry
                            item.correctionStart = now
                        end
                    end
                end
                item.duration = math.max(item.duration, math.max(0, expiryAt(item, now) - now))
                item.estimated, item.calibrated = false, true
                if remaining > 0 then self.durations[item.key] = item.duration end
            end
            item.observed = effect.remaining
            item.sampledAt = now
        elseif effect.timing == "unknown" and not item.hadTiming and self.durations[item.key] then
            item.duration = self.durations[item.key]
            item.expiry = previous and previous.expiry or now + item.duration
            item.estimated = true
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
        remaining = remaining, sortRemaining = remaining or effect.remaining, fraction = fraction, timer = timer,
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
        if a.sortRemaining ~= b.sortRemaining then return (a.sortRemaining or 0) > (b.sortRemaining or 0) end
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
