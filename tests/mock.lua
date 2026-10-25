--[[
XBB / Native client test doubles
Provides in-memory UI trees, input, event hooks, and settings storage.
Checks integer layout coordinates and native Text configuration constraints.
Mouse hooks are invoked explicitly by the integration tests.
install() supplies the client globals used by the native integration tests.
]]

local M = {}
local Node = {}
Node.__index = Node
Node.__newindex = function(self, key, value)
    if self.type == 2 and key == "lineSpacing" then
        error("cannot set lineSpacing directly on native Text")
    end
    rawset(self, key, value)
end
function Node:GetConfigCopy()
    return { font = self.font, maxLines = self.maxLines, lineSpacing = self.lineSpacing,
        alignHorizontal = self.alignHorizontal, alignVertical = self.alignVertical,
        isShadowed = self.isShadowed }
end
function Node:SetConfig(config)
    for key, value in pairs(config) do rawset(self, key, value) end
    self.configWrites = (self.configWrites or 0) + 1
end
local function integer(value)
    assert(type(value) == "number" and value == math.floor(value), "native layout requires integers")
end
function Node:SetPos(x, y)
    integer(x); integer(y)
    self.x, self.y = x, y
end
function Node:SetSize(width, height)
    integer(width); integer(height)
    self.width, self.height = width, height
end
function Node:SetScrollSize(width, height) self.scrollWidth, self.scrollHeight = width, height end
function Node:SetScrollPos(x, y) self.scrollX, self.scrollY = x, y end
function Node:Subscribe(hook, callback) self.hooks[hook] = callback end
function Node:IterateDynamicComponents(callback)
    for _, child in ipairs(self.children) do if not child.destroyed then callback(child, not child.hidden) end end
end
function Node:IterateStaticComponents() end
function Node:Destroy()
    self.destroyed = true
    for _, child in ipairs(self.children) do child:Destroy() end
end
function M.node(parent, kind)
    local node = setmetatable({ children = {}, hooks = {}, hidden = false, visible = true, alpha = 255, type = kind,
        text = {}, parent = parent, interfaceID = parent and parent.interfaceID or 1, scrollX = 0, scrollY = 0,
        width = 1000, height = 800, x = 0, y = 0 }, Node)
    if parent then parent.children[#parent.children + 1] = node end
    return node
end
function M.find(node, label)
    if node.destroyed then return nil end
    if node.label == label or node.content == label then return node end
    for _, child in ipairs(node.children) do
        local found = M.find(child, label)
        if found then return found end
    end
end
function M.click(root, label)
    local node = assert(M.find(root, label), "missing control: " .. label)
    while node do
        local callback = node.hooks[ui.Hook.ONCLICK] or node.hooks[ui.Hook.ONBUTTONPRESSED]
        if callback then return callback(node, 0, 0) end
        node = node.parent
    end
    error("control is not clickable: " .. label)
end
function M.startDrag(component)
    component.hooks[ui.Hook.ONCLICK]()
end
function M.install()
    local available = true
    local input = { control = false, shift = false, blocked = false, available = true,
        position = { x = 0, y = 0 } }
    local components, events, warnings, messages = {}, {}, {}, {}
    _G.ui = { ComponentType = { LAYER = 1, LABEL = 2, RADIAL_PROGRESS_OVERLAY = 3, SPRITE = 4 },
        TriggerMode = { ONPRESS = 1 },
        AlignMode = { TOPLEFT = 0, CENTRE = 1, BOTTOMRIGHT = 2 },
        Hook = { ONBUTTONPRESSED = 1, ONSCROLLWHEEL = 2, ONCLICK = 3, ONRELEASE = 4,
            ONDRAG = 5, ONDRAGCOMPLETE = 6, ONHOLD = 7 } }
    for _, kind in ipairs({ "Layer", "Text", "Rectangle", "Button" }) do
        ui[kind] = { new = function(parent) return M.node(parent, kind == "Text" and 2 or 1) end }
    end
    _G.id = { Component = setmetatable({}, { __index = function(_, key) return key end }),
        Param = setmetatable({}, { __index = function(_, key) return key end }),
        Font = { NOTO_SANS_11PT_BOLD_OUTLINE = 1 } }
    _G.config = { Struct = { FromID = function() return nil end }, Param = {}, Inv = { WORN = 1 },
        Font = { FromID = function()
            return { GetStringHeightAndLineCount = function(_, text, width, spacing)
                return math.ceil(#text * 8 / width) * spacing + 16
            end }
        end } }
    _G.Inventory = { Find = function() return nil end }
    _G.var = { VarClient = {}, VarPlayer = {} }
    components.TOPLEVEL_V2__GAME_AREA = M.node()
    for _, prefix in ipairs({ "BUFF_BAR", "DEBUFF_BAR" }) do
        components[prefix .. "__BUFF_RENDER_LAYER"] = { hidden = false, alpha = 255 }
        for i = 1, 50 do components[prefix .. "__BUFF_" .. i] = { visible = false } end
    end
    ui.Interfaces = { GetComponent = function(_, name) return components[name] end,
        GetInterface = function() return {} end }
    components.TOPLEVEL_V2__GAME_AREA.interfaceID = 1
    _G.Event = {}
    for _, name in ipairs({ "ServerLogic", "Draw", "MiniMenuReady", "SettingsLayerReady", "ContentLayerReady", "WindowFocusChanged" }) do
        events[name] = {}
        Event[name] = {
            Subscribe = function(key, callback) events[name][key] = callback end,
            Unsubscribe = function(key) events[name][key] = nil end,
        }
    end
    local db = { values = {}, writes = 0 }
    function db:Get(key) return self.values[key] end
    function db:Set(key, value) self.writes = self.writes + 1; self.values[key] = value; return true end
    _G.PersistentDB = db
    _G.Player = { IsAvailable = function() return available end }
    _G.Keyboard = {
        IsAvailable = function() return input.available end,
        IsBlocked = function() return input.blocked end,
        IsControlDown = function() return input.control end,
        IsShiftDown = function() return input.shift end,
    }
    _G.Mouse = {
        IsAvailable = function() return input.available end,
        GetPosition = function() return input.position end,
    }
    _G.game = { options = { InterfaceScale = { setting = 100 } } }
    components.TOPLEVEL_V2__GAME_AREA.xyGlobal = { x = 0, y = 0 }
    _G.warn = function(message) warnings[#warnings + 1] = message end
    _G.log = function(message) messages[#messages + 1] = message end
    _G.prettyui = require("tests/prettyui_mock")(M)
    return { components = components, events = events, db = db, warnings = warnings, messages = messages, input = input,
        availability = function(value) available = value end }
end
return M
