--[[
XBB / PrettyUI test double
Models the Window, SimpleView, Tabs, and controls used by settings.
Matches the PrettyUI 1.2.1 callback and setter contracts.
]]

return function(Mock)
    local Host = {}
    Host.__index = Host
    function Host.new(parent, options)
        local root = Mock.node(parent)
        root:SetPos(options.x or 0, options.y or 0)
        root:SetSize(options.width, options.height)
        return setmetatable({ root = root, content = root, viewport = root, scrollY = 0, colorPickers = {},
            contentWidth = options.width, interfaceID = parent.interfaceID }, Host)
    end
    function Host:AddText(value)
        local node = Mock.node(self.content, 2)
        node.content = type(value) == "table" and value.text or value
        return node
    end
    Host.AddTitle = Host.AddText
    function Host:AddColourPicker(options)
        local host = self
        local control = { root = Mock.node(self.content), value = options.value, options = options }
        control.root.label = options.tooltip
        function control:GetValue() return self.value end
        function control:SetValue(value, notify)
            if self.value == value then return false end
            self.value = value
            if notify ~= false then options.onChange(self, value) end
            return true
        end
        function control:Open()
            if self.pickerWindow then return true end
            self.pickerWindow = { root = Mock.node(options.windowParent or host.root) }
            self.pendingColour = self.value
            return true
        end
        function control:Close()
            if self.pickerWindow then self.pickerWindow.root:Destroy(); self.pickerWindow = nil end
        end
        function control:Destroy()
            self:Close()
            self.root:Destroy()
            self.root = nil
        end
        control.root:Subscribe(ui.Hook.ONCLICK, function() control:Open() end)
        self.colorPickers[#self.colorPickers + 1] = control
        return control
    end
    function Host:AddSimpleButton(label, callback)
        local node = Mock.node(self.content)
        node.label = label
        local control = { root = node }
        function control:SetDisabled(disabled) node.enabled = not disabled end
        node:Subscribe(ui.Hook.ONCLICK, function()
            if node.enabled ~= false then callback(control) end
        end)
        return control
    end
    function Host:AddCheckboxButton(choices, options)
        local control = { selected = {} }
        function control:SetSelected(value, selected, notify)
            if self.selected[value] == selected then return true end
            self.selected[value] = selected
            if notify ~= false then options.onChange(self, {}, value, selected) end
            return true
        end
        function control:IsSelected(value) return self.selected[value] == true end
        for _, choice in ipairs(choices) do
            control.selected[choice.value] = choice.selected
            self:AddSimpleButton(choice.text, function()
                control:SetSelected(choice.value, not control:IsSelected(choice.value))
            end)
        end
        return control
    end
    function Host:SetSize(width, height)
        self.root:SetSize(width, height)
        self.contentWidth = width
    end
    function Host:SetScrollPosition(y) self.scrollY = y end
    function Host:Destroy()
        for _, control in ipairs(self.colorPickers) do control:Destroy() end
        self.root:Destroy()
        self.root = nil
    end

    local Window = {}
    function Window.new(parent, options)
        local window = Host.new(parent, options)
        window.content = Mock.node(window.root)
        window.content:SetSize(options.width - 16, options.height - 40)
        window.viewport, window.contentWidth = window.content, window.content.width
        window:AddTitle(options.title)
        function window:Close()
            options.onClose(self)
            self.root.hidden = true
        end
        function window:Show() self.root.hidden = false end
        function window:SetSize(width, height)
            self.root:SetSize(width, height)
            self.content:SetSize(width - 16, height - 40)
            self.contentWidth = width - 16
        end
        window:AddSimpleButton("Close", function() window:Close() end)
        return window
    end
    local Tabs = {}
    function Tabs.new(parent, names, options)
        local group = Host.new(parent, options)
        group.pages, group.active = {}, options.activeIndex
        for index, name in ipairs(names) do
            group.pages[index] = Host.new(group.root, options)
            group.pages[index].root.hidden = index ~= group.active
            group:AddSimpleButton(name, function() group:SetActive(index) end)
        end
        function group:GetPage(index) return self.pages[index] end
        function group:GetActiveIndex() return self.active end
        function group:SetActive(index, notify)
            self.active = index
            for i, page in ipairs(self.pages) do page.root.hidden = i ~= index end
            if notify ~= false then options.onChange(self, index, names[index], self.pages[index]) end
        end
        function group:Destroy()
            for _, page in ipairs(self.pages) do page:Destroy() end
            Host.Destroy(self)
        end
        return group
    end
    return { Window = Window, SimpleView = { new = Host.new }, Tabs = Tabs }
end
