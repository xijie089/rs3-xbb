--[[
XBB / Plugin lifecycle
Connects native game data, PersistentDB settings, the effect model, and UI.
Supplies local-player equipment and quiver data through Reader adapters.
Scans after server updates; updates layout at 10 Hz and countdowns at 50 Hz.
Reapplies native opacity replacement each frame through Reader.
Restores native bars and destroys plugin UI on logout or shutdown.
]]

local Settings = require("xbb/settings")
local Model = require("xbb/model")
local Reader = require("xbb/reader")
local Hud = require("xbb/hud")
local SettingsUI = require("xbb/settings_ui")

local settings = Settings.new(PersistentDB, warn)
local model = Model.new()
local now, lastRender, issue, logged = 0, -5, nil, nil
local function objectName(value)
    if type(value) == "number" then
        value = value > 0 and config.Obj.FromID(value) or nil
    end
    if value and (type(value) == "userdata" or type(value) == "table")
        and value.typeName == "Obj" and value.id > 0 then return value.name end
end

local reader = Reader.new({
    types = ui.ComponentType,
    component = function(name)
        local componentID = id.Component[name]
        return componentID and ui.Interfaces:GetComponent(componentID) or nil
    end,
    paramID = function(name) return id.Param[name] end,
    -- Inventory and variable reads below belong to the local player.
    pocketBook = function()
        local result = {}
        local worn = Inventory.Find(config.Inv.WORN)
        if worn and worn.isValid then
            local slot = worn:GetSlot(18)
            if slot and slot.obj then result.name = slot.obj.name end
        end
        local timer = var.VarClient.COMBATV2_COOLDOWN_GOD_BOOK_TIMER_END_EFFECT_CLIENT
        if timer and type(timer.value) == "number" and timer.value > 0 then
            -- Client-clock units are 50 Hz logic ticks.
            result.remaining = math.max(0, timer.value / 50 - now)
        end
        return result
    end,
    quiverAmmo = function()
        local ammo = var.VarPlayer.QUIVER_ACTIVE_AMMO
        if ammo then return objectName(ammo.value) end
    end,
    objectName = objectName,
    struct = function(structID)
        local value = config.Struct.FromID(structID)
        if not value then return nil end
        return { id = value.id, configName = value.configName, params = value.params, GetParamValue = function(_, name)
            local param = config.Param[name]
            if not param then return nil end
            return value:GetParamValue(param)
        end }
    end,
})
local hud, parent, settingsView
local visibilityIssue

local function replace(enabled)
    local ok, result, message = pcall(function() return reader:replace(enabled) end)
    local problem = not ok and tostring(result) or (not result and message or nil)
    if problem ~= visibilityIssue then
        visibilityIssue = problem
        if problem then warn("XBB: native bar visibility update failed: " .. problem) end
    end
end

local function openSettings()
    if not parent then return end
    if settingsView then settingsView:destroy() end
    settingsView = SettingsUI.new(parent, settings)
end

local function scan()
    if not Player.IsAvailable() then return end
    local ok, snapshot, problem, details = pcall(function() return reader:scan() end)
    if not ok then problem, snapshot = "Native buff API error: " .. tostring(snapshot), nil end
    if snapshot then
        model:update(snapshot, now)
        settings:remember(snapshot)
        replace(settings.data.replaceNative)
    else
        -- Unavailable source data suppresses missing warnings and restores native bars.
        model:unavailable()
        replace(false)
    end
    issue = problem
    -- Log each source warning once until it changes or clears.
    if problem and logged ~= problem then
        warn("XBB: " .. problem)
        if details then log("XBB diagnostic: " .. details) end
    end
    logged = problem
end

local function clear()
    replace(false)
    if hud then hud:destroy(); hud = nil end
    if settingsView then settingsView:destroy(); settingsView = nil end
    model:unavailable()
    parent = nil
end

-- Sample after server updates; animate countdowns at 50 Hz.
Event.ServerLogic.Subscribe("xbb", scan)
Event.Draw.Subscribe("xbb", function()
    if hud then replace(model.available and settings.data.replaceNative and Player.IsAvailable()) end
end)
Event.MiniMenuReady.Subscribe("xbb", function(event) if hud then hud:menu(event) end end)
Event.SettingsLayerReady.Subscribe("xbb", function(event)
    if settingsView then settingsView:destroy() end
    settingsView = SettingsUI.new(event.component, settings)
end)
Event.WindowFocusChanged.Subscribe("xbb", function(event)
    if not event.hasFocus then
        if hud then hud:finishDrag() end
        if settingsView then settingsView:finishDrag() end
    end
end)

function PluginLogic(event)
    now = event.logicTick / 50
    if not Player.IsAvailable() then
        if hud or model.available then clear() end
        return
    end
    local gameArea = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
    if not gameArea then
        clear()
        if logged ~= "game-area" then warn("XBB: waiting for the game-area interface"); logged = "game-area" end
        return
    end
    if parent ~= gameArea then
        clear()
        parent = gameArea
        hud = Hud.new(parent, settings, openSettings)
        scan()
        lastRender = event.logicTick - 5
    end
    hud:updateDrag()
    if event.logicTick < lastRender or event.logicTick - lastRender >= 5 then
        lastRender = event.logicTick
        hud:render(model:view(settings.data, now), issue or (visibilityIssue and "Native bar replacement failed - see plugin log"))
    end
    hud:updateCountdowns(model.effects, now)
    if settingsView then settingsView:refresh() end
end

function PluginShutdown()
    Event.ServerLogic.Unsubscribe("xbb")
    Event.Draw.Unsubscribe("xbb")
    Event.MiniMenuReady.Unsubscribe("xbb")
    Event.SettingsLayerReady.Unsubscribe("xbb")
    Event.WindowFocusChanged.Unsubscribe("xbb")
    clear()
end

log("XBB loaded. Right-click bars or open XBB settings to configure.")
