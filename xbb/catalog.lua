--[[
XBB / Effect catalog
Provides native name/description fallbacks and shared display-name resolution.
Resolves config, effect-ID, full-text, and heading matches from short_names.lua.
Uses the same compact labels for HUD effects and saved settings entries.
Defines English name-family alternatives for optional missing-buff presets.
]]

local M = {}
-- Known native effects without an ability-name parameter.
M.nativeNames = {
    COMBATV2_CLAN_AVA_BUFF_LEVEL = "Clan avatar boost",
    COMBATV2_GOD_BOOK_TIMER_DUMMY_ABILITY = "Pocket book",
    COMBATV2_BUFF_QUIVER_ACTIVE_AMMO = "Quiver ammo",
}

M.nativeDetails = {
    COMBATV2_BUFF_RANGED_SEARING_WINDS = "Ranged attacks deal an additional 20% bonus damage with each hit.",
    COMBATV2_BUFF_BLOOD_TITHE = "Each stack boosts basic Magic ability base damage by 1% (maximum 12 stacks).",
    COMBATV2_BUFF_GLACIAL_EMBRACE = "Each stack cuts Tsunami's adrenaline cost by 12% (maximum 5 stacks).\n"
        .. "At 5 stacks, Incite Fear attacks can trigger Frost Surge for 10-50% ability damage "
        .. "to the target and up to 8 enemies within 2 tiles (12s cooldown).",
}

local shortNames = require("xbb/short_names")
local keyShortNames, fullTextShortNames, headingShortNames = {}, {}, {}

local function textKey(text)
    return (text or ""):match("^%s*(.-)%s*$"):lower()
end

for _, entry in pairs(shortNames) do
    keyShortNames["buff:" .. entry.id] = entry.name
    keyShortNames["debuff:" .. entry.id] = entry.name
    fullTextShortNames[textKey(entry.text)] = entry.name
    for _, alias in ipairs(entry.aliases or {}) do headingShortNames[textKey(alias)] = entry.name end
end

local function heading(text)
    return textKey((text or ""):match("^[^:\r\n]*"))
end

function M.displayName(name, configName, abilityName, effectKey)
    if shortNames[configName] then return shortNames[configName].name end
    local mapped = keyShortNames[effectKey]
        or fullTextShortNames[textKey(name)] or headingShortNames[heading(name)]
        or fullTextShortNames[textKey(abilityName)] or headingShortNames[heading(abilityName)]
    if mapped then return mapped end
    if abilityName and abilityName ~= "" then return abilityName end
    return name
end

function M.entryName(entry, known)
    local key = entry.key or entry.id
    local missing = key and key:match("^missing:(.+)$")
    key = missing or key
    local saved = known[key]
    local name = missing and entry.name:gsub("^Missing:%s*", "") or entry.name
    local label = M.displayName(saved and saved.name or name, nil,
        saved and saved.displayName or entry.displayName, key)
    return missing and "Missing: " .. label or label
end

M.presets = {
    { id = "overload", name = "Overload", alternatives = { { "overload" } } },
    { id = "pocket", name = "Pocket book", alternatives = {
        { "pocket book" }, { "god book" }, { "scripture of " }, { "grimoire" }, { "book of law" }, { "book of war" },
        { "book of wisdom" }, { "book of chaos" }, { "book of balance" }, { "ancient book" } } },
    { id = "weapon_poison", name = "Weapon poison", alternatives = { { "weapon poison" }, { "poisonous" } } },
    { id = "antifire", name = "Antifire", alternatives = { { "antifire" }, { "anti-fire" } } },
    { id = "antipoison", name = "Antipoison", alternatives = { { "antipoison" }, { "anti-poison" } } },
    { id = "prayer_renewal", name = "Prayer renewal", alternatives = { { "prayer renew" } } },
    { id = "aggression", name = "Aggression potion", alternatives = { { "aggression" }, { "aggroverload" } } },
    { id = "familiar", name = "Familiar", alternatives = { { "familiar" }, { "blood reaver" }, { "ripper demon" }, { "hellhound" }, { "kal'gerion demon" }, { "pack yak" }, { "steel titan" }, { "nihil" }, { "bunyip" }, { "unicorn stallion" }, { "smoke devil" }, { "beast of burden" } } },
    { id = "animate_dead", name = "Animate Dead", alternatives = { { "animate dead" } } },
    { id = "darkness", name = "Darkness", alternatives = { { "darkness" } } },
    { id = "bonfire", name = "Bonfire boost", alternatives = { { "bonfire" } } },
    { id = "kwuarm", name = "Kwuarm incense", alternatives = { { "kwuarm", "incense" } } },
    { id = "lantadyme", name = "Lantadyme incense", alternatives = { { "lantadyme", "incense" } } },
    { id = "fellstalk", name = "Fellstalk incense", alternatives = { { "fellstalk", "incense" } } },
    { id = "dwarf_weed", name = "Dwarf weed incense", alternatives = { { "dwarf weed", "incense" } } },
    { id = "torstol", name = "Torstol incense", alternatives = { { "torstol", "incense" } } },
    { id = "powder_protection", name = "Powder of protection", alternatives = { { "powder of protection" } } },
    { id = "powder_penance", name = "Powder of penance", alternatives = { { "powder of penance" } } },
    { id = "powder_defence", name = "Powder of defence", alternatives = { { "powder of defence" } } },
}
M.byID = {}
for _, preset in ipairs(M.presets) do M.byID[preset.id] = preset end

function M.matches(presetID, effect)
    local preset = M.byID[presetID]
    if not preset then return false end
    local name = effect.name:lower()
    for _, parts in ipairs(preset.alternatives) do
        local found = true
        for _, part in ipairs(parts) do if not name:find(part, 1, true) then found = false; break end end
        if found then return true end
    end
    return false
end

return M
