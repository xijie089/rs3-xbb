--[[
XBB / Native effect reader
Converts visible buff/debuff slots into snapshots using injected game APIs.
Resolves identities, names, descriptions, counts, timers, and diagnostics.
The separate visual walk discovers components without reading effect metadata.
Replacement saves and restores opacity; visibility flags stay unchanged.
]]

local Reader = {}
Reader.__index = Reader
local Catalog = require("xbb/catalog")
local prefixes = { { "BUFF_BAR", "buff" }, { "DEBUFF_BAR", "debuff" } }
local metadataKeys = { "COMBATV2_BUFF_STRUCT", "BUFF_BAR_STRUCT", "COMBATV2_ABILITY_OBJECT",
    "COMBATV2_BUFF_USES_STACKS", "COMBATV2_BUFF_USES_STACKS_PERCENT",
    "COMBATV2_BUFF_USES_ABILITY_END" }

local function clean(value)
    return type(value) == "string" and value:gsub("<[^>]*>", ""):match("^%s*(.-)%s*$") or ""
end

local function detailText(value)
    return clean(type(value) == "string" and value:gsub("<[bB][rR]%s*/?>", "\n") or "")
end

function Reader.parseTime(value, allowBare)
    value = clean(value):lower()
    local hours, minutes, seconds = value:match("^(%d+):(%d%d):(%d%d)$")
    if hours and tonumber(minutes) < 60 and tonumber(seconds) < 60 then
        return tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds)
    end
    minutes, seconds = value:match("^(%d+):(%d%d)$")
    if minutes and tonumber(seconds) < 60 then return tonumber(minutes) * 60 + tonumber(seconds) end
    local number = value:match("^(%d+%.?%d*)s$")
    if number then return tonumber(number) end
    local total, rest = 0, value
    for _, unit in ipairs({ { "h", 3600 }, { "m", 60 }, { "s", 1 } }) do
        local amount = rest:match("^(%d+)%s*" .. unit[1])
        if amount then
            total = total + tonumber(amount) * unit[2]
            rest = rest:gsub("^%d+%s*" .. unit[1] .. "%s*", "", 1)
        end
    end
    if rest == "" and value ~= "" then return total end
    if allowBare and value:match("^%d+%.?%d*$") then return tonumber(value) end
end

function Reader.new(api)
    local collections = {}
    for _, key in ipairs({ "LAYER", "PANEL", "GRID", "PAGED_LAYER", "PAGED_CAROUSEL", "GROUP_BOX" }) do
        if api.types[key] then collections[api.types[key]] = true end
    end
    return setmetatable({ api = api, collections = collections, replaced = {} }, Reader)
end

local function walk(component, collections, visit, depth)
    -- Local visibility excludes ancestor state.
    if component.visible == false then return end
    visit(component)
    if collections[component.type] then
        assert(depth < 8, "XBB: native buff component tree is deeper than expected")
        local function child(item)
            walk(item, collections, visit, depth + 1)
            return false
        end
        component:IterateStaticComponents(child)
        component:IterateDynamicComponents(child)
    end
end

function Reader:readSlot(node, kind)
    local api, labels, radial = self.api, {}, nil
    local struct, name, tooltip = nil, "", nil
    local values, nodes, hasContent = {}, {}, false
    local collections = self.collections
    local function inspect(component)
        local params, ops = component.paramsConfig, component.opConfig
        if not collections[component.type] or (ops and (ops.numOpNames or 0) > 0) then hasContent = true end
        if #nodes < 16 then
            nodes[#nodes + 1] = string.format("type=%s static=%s dynamic=%s params=%s",
                tostring(component.type), tostring(component.staticID), tostring(component.dynamicID),
                tostring(params and params.valid or false))
        end
        if name == "" and ops then
            name = clean(ops.opBaseName)
            if name ~= "" then tooltip = detailText(ops.opBaseName) end
        end
        if params and params.valid then
            for _, key in ipairs(metadataKeys) do
                local paramID = api.paramID(key)
                if paramID then
                    local value = params:Get(paramID)
                    if value ~= nil then values[key] = value end
                end
            end
        end
        if component.type == api.types.LABEL then
            local content = clean(component.content)
            if content ~= "" then labels[#labels + 1] = content end
        elseif component.type == api.types.RADIAL_PROGRESS_OVERLAY then
            local first, last, current = component.initialValue, component.endValue, component.curValue
            if type(first) == "number" and type(last) == "number" and type(current) == "number"
                and last > first and current >= first and current <= last then
                radial = { remaining = last - current, total = last - first }
            end
        end
    end
    walk(node, collections, inspect, 0)
    local structID = values.COMBATV2_BUFF_STRUCT or values.BUFF_BAR_STRUCT
    if type(structID) == "number" and structID > 0 then
        struct = api.struct(structID)
    else
        structID = nil
    end
    local function metadata(key)
        if values[key] ~= nil then return values[key] end
        if struct then return struct:GetParamValue(key) end
    end
    local abilityText = metadata("COMBATV2_ABILITY_NAME")
    local abilityName = clean(abilityText)
    local book
    if struct and struct.configName == "COMBATV2_GOD_BOOK_TIMER_DUMMY_ABILITY" and api.pocketBook then
        book = api.pocketBook()
        if name == "" and book then name = clean(book.name) end
    end
    if name == "" and struct then
        name = abilityName
        if name ~= "" then tooltip = detailText(abilityText) end
    end
    if name == "" and api.objectName then
        local override = metadata("COMBATV2_BUFF_OBJ_OVERRIDE")
        local object = values.COMBATV2_ABILITY_OBJECT
        -- Override-based effects may have a placeholder object on their struct.
        if object == nil and override ~= true and override ~= 1 then
            object = metadata("COMBATV2_ABILITY_OBJECT")
        end
        if object ~= nil then name = clean(api.objectName(object)) end
    end
    if name == "" and struct then name = Catalog.nativeNames[struct.configName] or "" end
    -- Generic layout parameters do not establish an active effect.
    if name == "" and not hasContent and next(values) == nil then return nil end
    local nameUnavailable, details
    if name == "" then
        local fields = {
            "global=" .. tostring(node.visibleGlobal),
            "layerType=" .. tostring(api.types.LAYER),
            "nodes=[" .. table.concat(nodes, "; ") .. "]",
            "labels=" .. string.format("%q", table.concat(labels, " | "):sub(1, 256)),
        }
        for _, key in ipairs(metadataKeys) do
            fields[#fields + 1] = string.format("%s(id=%s)=%s", key, tostring(api.paramID(key)), tostring(values[key]))
        end
        if struct then
            fields[#fields + 1] = "struct=" .. tostring(struct.configName)
            for index, param in ipairs(struct.params or {}) do
                if index > 16 then break end
                fields[#fields + 1] = param.configName .. "=" .. tostring(metadata(param.configName)):sub(1, 128)
            end
        end
        details = table.concat(fields, "; ")
        if not structID then return nil, "effect name unavailable", details end
        name, nameUnavailable = "Unknown " .. kind .. " #" .. tostring(structID), true
    end
    local usesStacks = metadata("COMBATV2_BUFF_USES_STACKS")
    local percent = metadata("COMBATV2_BUFF_USES_STACKS_PERCENT")
    local usesEnd = metadata("COMBATV2_BUFF_USES_ABILITY_END")
    local stacks = usesStacks == 1 or usesStacks == true or percent == 1 or percent == true
    local key = kind .. ":" .. (structID and tostring(structID) or "name:" .. name:lower())
    local displayName = Catalog.displayName(name, struct and struct.configName, abilityName, key)
    tooltip = tooltip or name
    if tooltip == abilityName or tooltip == displayName then
        local hasInfo = false
        for index = 1, 5 do
            local param = "COMBATV2_ABILITY_INFO" .. (index == 1 and "" or "_" .. index)
            local info = detailText(metadata(param))
            if info ~= "" then
                hasInfo = true
                if not tooltip:find(info, 1, true) then tooltip = tooltip .. "\n" .. info end
            end
        end
        local scripted = struct and Catalog.nativeDetails[struct.configName]
        if not hasInfo and scripted and not tooltip:find(scripted, 1, true) then
            tooltip = tooltip .. "\n" .. scripted
        end
    end
    local effect = { key = key,
        name = name, nameUnavailable = nameUnavailable, kind = kind, timing = "unknown",
        displayName = displayName, tooltip = tooltip,
        stacksPercent = percent == 1 or percent == true }
    if struct and struct.configName == "COMBATV2_BUFF_QUIVER_ACTIVE_AMMO" then
        local ammo = api.quiverAmmo and clean(api.quiverAmmo()) or ""
        effect.displayName = ammo ~= "" and ("Quiver: " .. ammo) or "Quiver ammo (unavailable)"
        effect.tooltip = effect.tooltip .. "\nSelected ammo: " .. (ammo ~= "" and ammo or "unavailable")
    end
    -- Stack radials do not establish a duration.
    if radial and not stacks then
        effect.timing, effect.remaining, effect.total = "timed", radial.remaining, radial.total
    end
    -- Timer and count labels can appear in either order.
    for _, label in ipairs(labels) do
        local duration = Reader.parseTime(label, not stacks and (usesStacks == 0 or usesStacks == false))
        if duration and effect.remaining == nil then
            effect.timing, effect.remaining = "timed", duration
        end
        if stacks then
            local count = tonumber(label:match("^(%d+)%%?$"))
            if count ~= nil then
                effect.stacks = count
                if label:sub(-1) == "%" then effect.stacksPercent = true end
            end
        end
    end
    -- Stack effects or label-free effects without an end flag are untimed.
    if effect.timing == "unknown" and (stacks or (#labels == 0 and usesEnd ~= 1 and usesEnd ~= true)) then
        effect.timing = "untimed"
    end
    if book and type(book.remaining) == "number" and book.remaining >= 0 and book.remaining < math.huge then
        effect.timing, effect.remaining = "timed", book.remaining
    end
    return effect, nameUnavailable and "effect name unavailable" or nil, details
end

function Reader:scan()
    local result, seen = {}, {}
    local unnamed, unnamedBuff, diagnostics = 0, false, nil
    for _, entry in ipairs(prefixes) do
        local prefix, kind = entry[1], entry[2]
        local root = self.api.component(prefix .. "__BUFF_RENDER_LAYER")
        if not root then return nil, prefix .. " interface is unavailable" end
        for index = 1, 50 do
            local node = self.api.component(prefix .. "__BUFF_" .. index)
            if not node then return nil, prefix .. " slot " .. index .. " is unavailable" end
            if node.visible then
                local effect, issue, details = self:readSlot(node, kind)
                if not effect and issue then return nil, prefix .. " slot " .. index .. ": " .. issue, details end
                if effect then
                    if seen[effect.key] then return nil, prefix .. ": ambiguous duplicate identity " .. effect.name end
                    if effect.nameUnavailable then
                        unnamed = unnamed + 1
                        if kind == "buff" then unnamedBuff = true end
                        if not diagnostics then
                            diagnostics = prefix .. " slot " .. index .. ": " .. effect.name .. "; " .. details
                        end
                    end
                    seen[effect.key] = true
                    result[#result + 1] = effect
                end
            end
        end
    end
    local issue
    if unnamed > 0 then
        issue = "Effect names unavailable (" .. unnamed .. ")" .. (unnamedBuff and " - family checks paused" or "")
    end
    return result, issue, diagnostics
end

function Reader:visualComponents()
    local components = {}
    local function collect(component) components[component] = true end
    for _, entry in ipairs(prefixes) do
        local prefix = entry[1]
        local root = assert(self.api.component(prefix .. "__BUFF_RENDER_LAYER"),
            prefix .. " interface is unavailable")
        collect(root)
        for index = 1, 50 do
            local node = assert(self.api.component(prefix .. "__BUFF_" .. index),
                prefix .. " slot " .. index .. " is unavailable")
            walk(node, self.collections, collect, 0)
        end
    end
    return components
end

-- Preserve visibility flags and each component's original opacity.
function Reader:replace(enabled)
    if not enabled and next(self.replaced) == nil then return true end
    local current, issues = {}, {}
    if enabled then
        local ok, components = pcall(function() return self:visualComponents() end)
        if ok then current = components
        else issues[#issues + 1] = tostring(components) end
    end
    for component, alpha in pairs(self.replaced) do
        if not current[component] then
            -- Stale interface handles are restored independently.
            local ok, message = pcall(function() component.alpha = alpha end)
            self.replaced[component] = nil
            if not ok then issues[#issues + 1] = tostring(message) end
        end
    end
    for component in pairs(current) do
        local ok, previous = pcall(function()
            local previous = component.alpha
            assert(type(previous) == "number", "XBB: native component opacity unavailable")
            if previous ~= 0 then component.alpha = 0 end
            return previous
        end)
        if ok then
            if self.replaced[component] == nil then self.replaced[component] = previous end
        else issues[#issues + 1] = tostring(previous) end
    end
    if #issues > 0 then return false, table.concat(issues, "; ") end
    return true
end

return Reader
