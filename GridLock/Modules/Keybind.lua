-- GridLock Keybind Module
-- Interactive Hover Keybinding Engine for WoW 3.3.5a

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock

local Keybind = {}
if type(GridLock.RegisterModule) == "function" then
    GridLock:RegisterModule("Keybind", Keybind)
else
    GridLock.modules = GridLock.modules or {}
    GridLock.modules["Keybind"] = Keybind
end

Keybind.active = false
Keybind.catcher = nil
Keybind.highlightFrame = nil
Keybind.hoveredButton = nil

function Keybind:OnInitialize()
    self:CreateHighlightFrame()
end

-- Create Golden Highlight Frame
function Keybind:CreateHighlightFrame()
    if self.highlightFrame then return self.highlightFrame end

    local f = CreateFrame("Frame", "GridLockKeybindHighlight", UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(501)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    f:SetBackdropColor(1.0, 0.82, 0.0, 0.2)
    f:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.8)

    self.highlightFrame = f
    return f
end

-- Create Fullscreen Intercept Catcher
function Keybind:CreateCatcher()
    if self.catcher then return self.catcher end

    local catcher = CreateFrame("Button", "GridLockKeybindCatcher", UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(500)
    catcher:EnableMouse(true)
    catcher:EnableKeyboard(true)
    catcher:EnableMouseWheel(true)
    catcher:RegisterForClicks("AnyDown")

    catcher:SetScript("OnKeyDown", function(selfFrame, key)
        Keybind:OnKeyDown(key)
    end)

    catcher:SetScript("OnMouseDown", function(selfFrame, button)
        Keybind:OnMouseDown(button)
    end)

    catcher:SetScript("OnMouseWheel", function(selfFrame, delta)
        Keybind:OnMouseWheel(delta)
    end)

    catcher:SetScript("OnUpdate", function(selfFrame, elapsed)
        Keybind:OnUpdate(elapsed)
    end)

    self.catcher = catcher
    return catcher
end

-- Toggle Keybind Mode
function Keybind:Toggle()
    if self.active then
        self:Deactivate()
    else
        self:Activate()
    end
end

-- Activate Keybind Mode
function Keybind:Activate()
    if self.active then return end
    self.active = true

    if not self.highlightFrame then
        self:CreateHighlightFrame()
    end

    local catcher = self:CreateCatcher()
    catcher:Show()
    catcher:EnableKeyboard(true)

    if GridLock.Utils and GridLock.Utils.Print then
        GridLock.Utils.Print("Keybind mode activated. Hover over action buttons and press keys to bind. Press ESC to exit.")
    end
end

-- Deactivate Keybind Mode
function Keybind:Deactivate()
    if not self.active then return end
    self.active = false

    if self.catcher then
        self.catcher:Hide()
        self.catcher:EnableKeyboard(false)
    end

    if self.highlightFrame then
        self.highlightFrame:Hide()
    end

    if GameTooltip then
        GameTooltip:Hide()
    end

    self.hoveredButton = nil

    if GridLock.Utils and GridLock.Utils.Print then
        GridLock.Utils.Print("Keybind mode deactivated.")
    end
end

-- Candidate Button Scanning and Focus Detection
function Keybind:FindCandidateButton(focus)
    if not focus then return nil end
    local curr = focus
    while curr and curr ~= UIParent and curr ~= WorldFrame do
        local name = curr:GetName()
        if name then
            if name:match("^ActionButton%d+$")
               or name:match("^MultiBarBottomLeftButton%d+$")
               or name:match("^MultiBarBottomRightButton%d+$")
               or name:match("^MultiBarRightButton%d+$")
               or name:match("^MultiBarLeftButton%d+$")
               or name:match("^PetActionButton%d+$")
               or name:match("^ShapeshiftButton%d+$")
               or name:match("^StanceButton%d+$")
               or curr.action or curr.command then
                return curr
            end
        end
        if curr.GetParent then
            curr = curr:GetParent()
        else
            break
        end
    end
    return nil
end

function Keybind:GetHoveredActionButton()
    return self.hoveredButton
end

-- OnUpdate loop to detect hovered button and update tooltip/highlight
function Keybind:OnUpdate(elapsed)
    if not self.active then return end

    local focus = GetMouseFocus()
    local button = self:FindCandidateButton(focus)

    if not button then
        -- Fallback: check MouseIsOver across all registered bar buttons
        local barNames = {
            "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight",
            "MultiBarRight", "MultiBarLeft", "PetActionBarFrame",
            "ShapeshiftBarFrame", "ActionBar6", "ActionBar7", "ActionBar8", "ActionBar9", "ActionBar10"
        }
        local BarLayout = GridLock:GetModule("BarLayout") or GridLock.BarLayout
        if BarLayout and BarLayout.GetBarButtons then
            for _, barName in ipairs(barNames) do
                local buttons = BarLayout:GetBarButtons(barName)
                for _, btn in ipairs(buttons or {}) do
                    if btn and btn.IsShown and btn:IsShown() and MouseIsOver and MouseIsOver(btn) then
                        button = btn
                        break
                    end
                end
                if button then break end
            end
        end
    end

    if button then
        self.hoveredButton = button
        if self.highlightFrame then
            self.highlightFrame:ClearAllPoints()
            self.highlightFrame:SetAllPoints(button)
            self.highlightFrame:Show()
        end
        self:UpdateTooltip(button)
    else
        self.hoveredButton = nil
        if self.highlightFrame then
            self.highlightFrame:Hide()
        end
        if GameTooltip then
            GameTooltip:Hide()
        end
    end
end

-- Map button to binding command
function Keybind:GetButtonActionCommand(button)
    if not button then return nil end
    if button.command then return button.command end
    if button.binding then return button.binding end

    local name = button:GetName()
    if not name then return nil end

    local idx = name:match("^ActionButton(%d+)$")
    if idx then return "ACTIONBUTTON" .. idx end

    idx = name:match("^MultiBarBottomLeftButton(%d+)$")
    if idx then return "MULTIACTIONBAR1BUTTON" .. idx end

    idx = name:match("^MultiBarBottomRightButton(%d+)$")
    if idx then return "MULTIACTIONBAR2BUTTON" .. idx end

    idx = name:match("^MultiBarRightButton(%d+)$")
    if idx then return "MULTIACTIONBAR3BUTTON" .. idx end

    idx = name:match("^MultiBarLeftButton(%d+)$")
    if idx then return "MULTIACTIONBAR4BUTTON" .. idx end

    idx = name:match("^PetActionButton(%d+)$")
    if idx then return "BONUSACTIONBUTTON" .. idx end

    idx = name:match("^ShapeshiftButton(%d+)$") or name:match("^StanceButton(%d+)$")
    if idx then return "SHAPESHIFTBUTTON" .. idx end

    return "CLICK " .. name .. ":LeftButton"
end

-- Get action / spell display name
function Keybind:GetButtonActionName(button)
    if not button then return "Unknown Action" end

    if button.action and type(button.action) == "number" and _G.GetActionInfo then
        local actionType, id = _G.GetActionInfo(button.action)
        if actionType == "spell" and id and _G.GetSpellInfo then
            local name = _G.GetSpellInfo(id)
            if name then return name end
        elseif actionType == "item" and id and _G.GetItemInfo then
            local name = _G.GetItemInfo(id)
            if name then return name end
        elseif actionType == "macro" and id and _G.GetMacroInfo then
            local name = _G.GetMacroInfo(id)
            if name then return name end
        end
    end

    if button.GetText and button:GetText() and button:GetText() ~= "" then
        return button:GetText()
    end
    if button.name then return button.name end

    return button:GetName() or "Action Button"
end

-- Update GameTooltip
function Keybind:UpdateTooltip(button)
    if not GameTooltip then return end

    local command = self:GetButtonActionCommand(button) or "UNBOUND"
    local actionName = self:GetButtonActionName(button)

    local keysStr = ""
    if _G.GetBindingKey then
        local k1, k2 = _G.GetBindingKey(command)
        if k1 and k2 then
            keysStr = k1 .. ", " .. k2
        elseif k1 then
            keysStr = k1
        else
            keysStr = "Unbound"
        end
    else
        keysStr = "Unbound"
    end

    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(actionName, 1, 1, 1)
    GameTooltip:AddLine("Command: " .. command, 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Binding: " .. keysStr, 1, 0.82, 0)
    GameTooltip:AddLine("Hover button & press key | ESC to exit | DELETE to unbind", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

-- Format Key String with Modifiers
function Keybind:FormatKey(rawKey)
    if not rawKey then return nil end
    local upperKey = string.upper(rawKey)

    -- Ignore standalone modifier keys
    if upperKey == "LSHIFT" or upperKey == "RSHIFT" or upperKey == "SHIFT"
       or upperKey == "LCTRL" or upperKey == "RCTRL" or upperKey == "CTRL"
       or upperKey == "LALT" or upperKey == "RALT" or upperKey == "ALT" then
        return nil
    end

    local mod = ""
    if _G.IsShiftKeyDown and _G.IsShiftKeyDown() then mod = mod .. "SHIFT-" end
    if _G.IsControlKeyDown and _G.IsControlKeyDown() then mod = mod .. "CTRL-" end
    if _G.IsAltKeyDown and _G.IsAltKeyDown() then mod = mod .. "ALT-" end

    return mod .. upperKey
end

-- Key Down Event Listener
function Keybind:OnKeyDown(key)
    if not self.active then return end

    local upperKey = string.upper(key or "")

    if upperKey == "ESCAPE" then
        self:Deactivate()
        return
    end

    if upperKey == "DELETE" or upperKey == "BACKSPACE" then
        if self.hoveredButton then
            self:ClearButtonBindings(self.hoveredButton)
        else
            self:Deactivate()
        end
        return
    end

    local keyString = self:FormatKey(key)
    if keyString and self.hoveredButton then
        self:BindKeyToButton(self.hoveredButton, keyString)
    end
end

-- Mouse Down Event Listener
function Keybind:OnMouseDown(button)
    if not self.active then return end

    local mouseMap = {
        LeftButton = "BUTTON1",
        RightButton = "BUTTON2",
        MiddleButton = "BUTTON3",
        Button4 = "BUTTON4",
        Button5 = "BUTTON5",
    }
    local rawKey = mouseMap[button] or string.upper(button or "")

    if self.hoveredButton then
        local keyString = self:FormatKey(rawKey)
        if keyString then
            self:BindKeyToButton(self.hoveredButton, keyString)
        end
    else
        if button == "RightButton" then
            self:Deactivate()
        end
    end
end

-- Mouse Wheel Event Listener
function Keybind:OnMouseWheel(delta)
    if not self.active then return end

    local rawKey = (delta > 0) and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"

    if self.hoveredButton then
        local keyString = self:FormatKey(rawKey)
        if keyString then
            self:BindKeyToButton(self.hoveredButton, keyString)
        end
    end
end

-- Bind Key to Button
function Keybind:BindKeyToButton(button, keyString)
    local command = self:GetButtonActionCommand(button)
    if not command or not keyString then return end

    if _G.SetBinding then
        _G.SetBinding(keyString, command)
    end
    if _G.SaveBindings then
        _G.SaveBindings(2)
    end

    self:UpdateHotkeyText(button)
    self:UpdateTooltip(button)

    if GridLock.Utils and GridLock.Utils.Print then
        GridLock.Utils.Print("Bound %s to %s (%s)", keyString, self:GetButtonActionName(button), command)
    end
end

-- Clear Button Bindings
function Keybind:ClearButtonBindings(button)
    local command = self:GetButtonActionCommand(button)
    if not command then return end

    if _G.GetBindingKey and _G.SetBinding then
        local keys = { _G.GetBindingKey(command) }
        for _, k in ipairs(keys) do
            _G.SetBinding(k, nil)
        end
    end

    if _G.SaveBindings then
        _G.SaveBindings(2)
    end

    self:UpdateHotkeyText(button)
    self:UpdateTooltip(button)

    if GridLock.Utils and GridLock.Utils.Print then
        GridLock.Utils.Print("Cleared bindings for %s (%s)", self:GetButtonActionName(button), command)
    end
end

-- Shorten key text for button display
function Keybind:ShortenKeyText(key)
    if not key or key == "" then return "" end
    if GridLock and GridLock.FormatHotkeyText then
        return GridLock:FormatHotkeyText(key)
    end
    local text = key
    text = text:gsub("SHIFT%-", "s")
    text = text:gsub("CTRL%-", "c")
    text = text:gsub("ALT%-", "a")
    text = text:gsub("BUTTON1", "M1")
    text = text:gsub("BUTTON2", "M2")
    text = text:gsub("BUTTON3", "M3")
    text = text:gsub("BUTTON4", "M4")
    text = text:gsub("BUTTON5", "M5")
    text = text:gsub("MOUSEWHEELUP", "MwU")
    text = text:gsub("MOUSEWHEELDOWN", "MwD")
    text = text:gsub("NUMPAD", "N")
    text = text:gsub("DELETE", "Del")
    text = text:gsub("BACKSPACE", "BS")
    text = text:gsub("SPACE", "Spc")
    return text
end

-- Dynamically update hotkey text on button
function Keybind:UpdateHotkeyText(button)
    if not button then return end
    local name = button:GetName()
    local hotKey = (name and _G[name .. "HotKey"]) or button.hotKey or button.HotKey

    local command = self:GetButtonActionCommand(button)
    local key = command and _G.GetBindingKey and _G.GetBindingKey(command)

    if hotKey and hotKey.SetText then
        if key then
            local shortText = self:ShortenKeyText(key)
            hotKey:SetText(shortText)
            if hotKey.Show then hotKey:Show() end
        else
            hotKey:SetText("")
        end
    end
end
