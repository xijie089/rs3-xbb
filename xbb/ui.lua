--[[
XBB / Native component helpers
Constructs layers, rectangles, text, and buttons beneath a supplied parent.
Applies shared fonts, alignment, input defaults, and pointer coordinate conversion.
Callers supply button callbacks and manage component destruction.
]]

local M = {}

function M.pointerPosition(parent)
    local pointer = Mouse.GetPosition()
    if not pointer then return nil end
    local scale = game.options.InterfaceScale.setting / 100
    local origin = parent.xyGlobal
    return { x = pointer.x / scale - origin.x, y = pointer.y / scale - origin.y }
end

function M.layer(parent, x, y, width, height)
    local result = ui.Layer.new(parent)
    result:SetPos(x, y)
    result:SetSize(width, height)
    result.clickthrough = true
    result.enabled = true
    return result
end

function M.rectangle(parent, x, y, width, height, rgba)
    local result = ui.Rectangle.new(parent)
    result:SetPos(x, y)
    result:SetSize(width, height)
    result.fill, result.rgba, result.clickthrough = true, rgba, true
    return result
end

function M.text(parent, x, y, width, height, content, align)
    local result = ui.Text.new(parent)
    result:SetPos(x, y)
    result:SetSize(width, height)
    result.font = id.Font.NOTO_SANS_11PT_BOLD_OUTLINE
    result.alignHorizontal = align or ui.AlignMode.TOPLEFT
    result.alignVertical = ui.AlignMode.CENTRE
    result.maxLines, result.isShadowed, result.clickthrough = 1, true, true
    result.content = content
    return result
end

function M.button(parent, x, y, width, label, callback)
    local result = ui.Button.new(parent)
    result:SetPos(x, y)
    result:SetSize(width, 28)
    result.label = label
    result.enabled = true
    result.mode = ui.TriggerMode.ONPRESS
    result.text.font = id.Font.NOTO_SANS_11PT_BOLD_OUTLINE
    result:Subscribe(ui.Hook.ONBUTTONPRESSED, callback)
    return result
end

return M
