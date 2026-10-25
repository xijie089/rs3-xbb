--[[
XBB / Released PrettyUI integration
Runs settings against an external PrettyUI release, using native API doubles.
Usage: lua tests/prettyui_contract.lua /path/to/extracted/prettyui
]]

local dependency = assert(arg[1], "provide the extracted PrettyUI release directory")
local Mock = require("tests/mock")
local app = Mock.install()
local parent = app.components.TOPLEVEL_V2__GAME_AREA
local Node = getmetatable(parent)
local setSize, setPos, subscribe = Node.SetSize, Node.SetPos, Node.Subscribe
local node = Mock.node

function Mock.node(owner, kind)
    local value = node(owner, kind)
    value.cursorConfig = {}
    value.opConfig = { ClearOpCursors = function() end, SetOpCursor = function() end }
    return value
end
function Node:SetSize(width, height, widthAnchor, heightAnchor)
    self.layoutSize = { width, height, widthAnchor or 0, heightAnchor or 0 }
    setSize(self, width + math.floor((self.parent and self.parent.width or 0) * (widthAnchor or 0)),
        height + math.floor((self.parent and self.parent.height or 0) * (heightAnchor or 0)))
    for _, child in ipairs(self.children) do
        if not child.destroyed then
            if child.layoutSize then child:SetSize(table.unpack(child.layoutSize)) end
            if child.layoutPos then child:SetPos(table.unpack(child.layoutPos)) end
        end
    end
end
function Node:SetPos(x, y, xAnchor, yAnchor)
    self.layoutPos = { x, y, xAnchor or 0, yAnchor or 0 }
    setPos(self, x + math.floor((self.parent and self.parent.width or 0) * (xAnchor or 0)),
        y + math.floor((self.parent and self.parent.height or 0) * (yAnchor or 0)))
end
function Node:SetHeight(height) self:SetSize(self.width, height) end
function Node:SetWidth(width) self:SetSize(width, self.height) end
function Node:SetX(x) self:SetPos(x, self.y) end
function Node:SetY(y) self:SetPos(self.x, y) end
function Node:MoveToFront() end
function Node:Subscribe(hook, key, callback)
    if callback then
        self.namedHooks = self.namedHooks or {}
        self.namedHooks[hook] = self.namedHooks[hook] or {}
        self.namedHooks[hook][key] = callback
    else subscribe(self, hook, key) end
end
function Node:Unsubscribe(hook, key)
    if self.namedHooks and self.namedHooks[hook] then self.namedHooks[hook][key] = nil end
end
local loaded = true
ui.Interfaces.GetInterface = function(_, interfaceID)
    assert(interfaceID == 1, "PrettyUI must cache the native interface ID")
    if loaded then return {} end
end
local nextSprite = 0
id.Sprite = setmetatable({}, { __index = function(values, key)
    nextSprite = nextSprite + 1
    values[key] = nextSprite
    return nextSprite
end })
id.Font.MUSEO_SANS_15PT_REGULAR, id.Font.CINZEL_13PT_BOLD = 2, 3
config.Cursor = setmetatable({}, { __index = function() return { id = 1 } end })
local font = { baseline = 18 }
function font:GetStringWidth(text) return #text * 7 end
function font:GetStringLineCount(text, width) return math.max(1, math.ceil(#text * 7 / width)) end
function font:GetStringHeightAndLineCount(text, width, spacing)
    local lines = self:GetStringLineCount(text, width)
    return lines * spacing, lines
end
config.Font.FromID = function() return font end
config.Font.MUSEO_SANS_15PT_REGULAR, config.Font.CINZEL_13PT_BOLD = font, font
for _, name in ipairs({ "ONMOUSEOVER", "ONMOUSELEAVE", "ONRESIZE" }) do ui.Hook[name] = name end
ui.Sprite = { new = function(owner) return Mock.node(owner, ui.ComponentType.SPRITE) end }
ui.Canvas = { new = function(owner)
    local canvas = Mock.node(owner)
    function canvas:Clear() self.commands = {} end
    for _, method in ipairs({ "AddGradientV", "AddGradientH", "AddRectangle" }) do
        canvas[method] = function(self, ...)
            self.commands[#self.commands + 1] = { method, ... }
        end
    end
    return canvas
end }
package.path = dependency .. "/?.lua;" .. package.path
prettyui = { Window = require("src/window"), SimpleView = require("src/simple_view"), Tabs = require("src/tabs") }

local Settings = require("xbb/settings")
local View = require("xbb/settings_ui")
local settings = Settings.new(app.db, warn)
local view = View.new(parent, settings)
assert(view.window.titleDrag, "the real PrettyUI window must own title dragging")
local root, title = view.root, view.window.titleDrag
game.options.InterfaceScale.setting = 150
app.input.position = { x = 210, y = 201 }
title.hooks[ui.Hook.ONCLICK](title, 20, 14)
title.hooks[ui.Hook.ONHOLD](title, 20, 14)
app.input.position = { x = 300, y = 336 }
title.hooks[ui.Hook.ONHOLD](title, 80, 104)
assert(root.x == 180 and root.y == 210, "real PrettyUI title dragging must move the whole frame")
settings:remember({ { key = "buff:test", name = "Test", kind = "buff" } })
view:refresh()
assert(view.root == root and view.window.titleDrag == title, "refresh must preserve the active frame and drag source")
title.hooks[ui.Hook.ONRELEASE](title, 0, 0)
view.window:Close()
assert(settings.data.settingsWindowPosition.x == 180 and settings.data.settingsWindowPosition.y == 210)
view:show()
view.group:SetActive(5)
Mock.click(view.root, "Pin")
assert(settings:findPin("buff:test"))
Mock.click(view.root, "Hide")
assert(settings.data.hidden["buff:test"])
Mock.click(view.root, "Warn when missing")
assert(settings.data.rules["buff:test"])
view.group:SetActive(3)
Mock.click(view.root, "Collapsing")
assert(settings:findPin("buff:test").reserve)
Mock.click(view.root, "+")
assert(settings:findPin("buff:test").slot == 2)
view.group:SetActive(2)
Mock.click(view.root, "Restore")
assert(not settings.data.hidden["buff:test"])

view.group:SetActive(5)
local colorButton = assert(Mock.find(view.root, "Custom color"))
while not colorButton.hooks[ui.Hook.ONCLICK] do colorButton = colorButton.parent end
local warningButton = assert(Mock.find(view.root, "Remove warning"))
while not warningButton.hooks[ui.Hook.ONCLICK] do warningButton = warningButton.parent end
assert(colorButton.y == warningButton.y, "Observed color action must share the other actions' row")
assert(colorButton.x + colorButton.width <= colorButton.parent.width, "Observed actions must fit within their page")
Mock.click(view.root, "Custom color")
assert(view.tab == "Observed" and #view.colorPickers == 1)
local picker = view.colorPickers[1]
assert(picker:Open() and picker.alphaHit, "real picker must include opacity")
assert(#picker.fieldCanvas.commands == 128 and #picker.hueCanvas.commands == 6)
picker.fieldHit.hooks[ui.Hook.ONCLICK](picker.fieldHit, 96, 32)
picker.fieldHit.hooks[ui.Hook.ONRELEASE](picker.fieldHit, 96, 32)
picker.hueHit.hooks[ui.Hook.ONCLICK](picker.hueHit, 8, 80)
picker.hueHit.hooks[ui.Hook.ONRELEASE](picker.hueHit, 8, 80)
picker.alphaHit.hooks[ui.Hook.ONCLICK](picker.alphaHit, 32, 12)
picker.alphaHit.hooks[ui.Hook.ONRELEASE](picker.alphaHit, 32, 12)
local chosen, group = picker.pendingColour, view.group
assert(chosen % 256 == 64, "real alpha dragging must retain the selected byte")
assert(not settings.data.colors["buff:test"], "editing must not save before Accept")
settings:set("gap", 6)
view:refresh()
assert(view.group == group and picker.pickerWindow, "refresh must preserve the real picker draft")
Mock.click(picker.pickerWindow.root, "Accept")
assert(not picker.pickerWindow, "Accept must close the real picker")
assert(settings:colorFor({ key = "buff:test", kind = "buff" }) == chosen)
assert(settings.data.gap == 6, "committing a color must retain concurrent settings updates")
assert(Settings.new(app.db, error):colorFor({ key = "buff:test", kind = "buff" }) == chosen)
view:refresh()
assert(Mock.find(view.root, "Reset color"), "accepting must toggle the action without leaving Observed")
view.group:SetActive(6)
assert(#view.colorPickers == 4, "Colors must include the newly assigned override")
picker = view.colorPickers[4]
picker:Open()
picker.alphaHit.hooks[ui.Hook.ONCLICK](picker.alphaHit, 0, 12)
picker.alphaHit.hooks[ui.Hook.ONRELEASE](picker.alphaHit, 0, 12)
assert(picker.pendingColour % 256 == 0, "the real picker must support fully transparent colors")
picker:Close()
assert(settings:colorFor({ key = "buff:test", kind = "buff" }) == chosen, "closing must cancel a draft")
picker:Open()
local popup = picker.pickerWindow.root
view:finishDrag()
assert(not picker.pickerWindow and popup.destroyed, "focus loss must cancel external picker windows")
picker:Open()
popup = picker.pickerWindow.root
view.group:SetActive(1)
assert(popup.destroyed and not picker.pickerWindow, "changing tabs must destroy the real popup")

parent:SetSize(1000, 360)
view:refresh()
view.group:SetActive(1)
view.group:GetPage(1):SetScrollPosition(30)
assert(view.group:GetPage(1).scrollY == 30, "short windows must scroll their Display controls")
settings:set("gap", 5)
view:refresh()
assert(view.group:GetPage(1).scrollY == 30, "settings refresh must retain the real scroll position")
parent:SetSize(1000, 800)
view:refresh()
view.root:SetPos(180, 210)
view.window:SetSize(view.root.width, view.root.height)
view:refresh()

local host = Mock.node()
local launcher = View.launcher(host, settings, function() view:show() end)
Mock.click(host, "Separate buff/debuff stacks")
assert(settings.data.separate)
local writes = app.db.writes
launcher:refresh()
assert(app.db.writes == writes, "synchronizing PrettyUI controls must not write settings")
app.db.Set = function() return false end
Mock.click(host, "Replace original bars")
assert(settings.data.replaceNative and launcher.controls:IsSelected("replaceNative"))
assert(#app.warnings == 1, "rejected changes must be reported")
view:destroy()
launcher:destroy()
assert(not host.destroyed, "destroying a launcher must not destroy the client's managed layer")

view = View.new(parent, settings)
view.group:SetActive(6)
picker = view.colorPickers[1]
picker:Open()
picker.alphaHit.hooks[ui.Hook.ONCLICK](picker.alphaHit, 32, 12)
picker.alphaHit.hooks[ui.Hook.ONRELEASE](picker.alphaHit, 32, 12)
Mock.click(picker.pickerWindow.root, "Accept")
assert(picker:GetValue() == 0x357E89DD and not picker.pickerWindow, "rejected real picker saves must roll back and close")
assert(#app.warnings == 2)
picker:Open()
view.root:SetPos(190, 220)
view:refresh()
loaded = false
view:destroy()
assert(not picker.pickerWindow, "unloading must clear the real picker without accessing dead interfaces")
assert(#app.warnings == 3, "failed position persistence must be reported even after interface unload")
print("Released PrettyUI integration passed")
