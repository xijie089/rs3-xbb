--[[
XBB / Bar configuration actions
Builds menu labels and callbacks for an effect and its current bar slot.
Callbacks hide, pin, reserve, or watch effects through local Settings methods.
Shares missing-warning creation and removal with the Observed settings tab.
Hud attaches the returned actions to the native mini-menu.
]]

local M = {}

function M.watch(settings, effect, enabled)
    if enabled == false then return settings:removeWatch(effect.key) end
    return settings:watch({ id = effect.key, name = effect.name, keys = { effect.key }, enabled = enabled })
end

function M.items(settings, effect, slot)
    local result = { { label = "Hide in XBB", run = function() settings:hide(effect) end } }
    local pin = settings:findPin(effect.key)
    if pin then
        result[#result + 1] = { label = "Unpin", run = function() settings:unpin(effect.key) end }
        result[#result + 1] = { label = pin.reserve and "Collapse when absent" or "Reserve slot when absent",
            run = function() settings:pin(effect, pin.slot, not pin.reserve) end }
    else
        result[#result + 1] = { label = "Pin to slot " .. slot, run = function() settings:pin(effect, slot, false) end }
    end
    if effect.kind == "buff" and not effect.missing then
        local rule = settings.data.rules[effect.key]
        local enabled = rule == nil
        result[#result + 1] = { label = enabled and "Warn when missing" or "Remove missing warning",
            run = function() M.watch(settings, effect, enabled) end }
    end
    return result
end

return M
