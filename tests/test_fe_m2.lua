-- test_fe_m2.lua
-- Unit & Integration Tests for ZenAlign FE-M2: Interactive Hover Keybinding Engine (/za bind)

-- 1. Mock WoW 3.3.5a API Environment
local mockFrames = {}
local mockScreen = { width = 1920, height = 1080 }
local mouseFocus = nil
local shiftDown, ctrlDown, altDown = false, false, false
local mockBindings = {}
local saveBindingsCalls = {}

_G.GetScreenWidth = function() return mockScreen.width end
_G.GetScreenHeight = function() return mockScreen.height end
_G.GetMouseFocus = function() return mouseFocus end
_G.InCombatLockdown = function() return false end
_G.IsShiftKeyDown = function() return shiftDown end
_G.IsControlKeyDown = function() return ctrlDown end
_G.IsAltKeyDown = function() return altDown end

_G.GetBindingKey = function(command)
    if mockBindings[command] then
        return table.unpack(mockBindings[command])
    end
    return nil
end

_G.SetBinding = function(key, command)
    if command == nil then
        -- Unbind key
        for cmd, keys in pairs(mockBindings) do
            for i = #keys, 1, -1 do
                if keys[i] == key then
                    table.remove(keys, i)
                end
            end
        end
    else
        -- Bind key to command
        mockBindings[command] = mockBindings[command] or {}
        -- Remove if existing to re-insert at front
        for i, k in ipairs(mockBindings[command]) do
            if k == key then
                table.remove(mockBindings[command], i)
                break
            end
        end
        table.insert(mockBindings[command], 1, key)
    end
    return true
end

_G.SaveBindings = function(which)
    table.insert(saveBindingsCalls, which)
    return true
end

_G.GetActionInfo = function(actionSlot)
    if actionSlot == 1 then
        return "spell", 133, "spell" -- Frostbolt
    elseif actionSlot == 2 then
        return "item", 6948, "item" -- Hearthstone
    elseif actionSlot == 3 then
        return "macro", 1, "macro" -- Charge Macro
    end
    return nil
end

_G.GetSpellInfo = function(spellId)
    if spellId == 133 then return "Frostbolt" end
    return "Spell " .. tostring(spellId)
end

_G.GetItemInfo = function(itemId)
    if itemId == 6948 then return "Hearthstone" end
    return "Item " .. tostring(itemId)
end

_G.GetMacroInfo = function(macroId)
    if macroId == 1 then return "AttackMacro" end
    return "Macro " .. tostring(macroId)
end

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg)
        -- mock chat output
    end
}
_G.SlashCmdList = {}

_G.GameTooltip = {
    owner = nil,
    lines = {},
    GetOwner = function(self) return self.owner end,
    SetOwner = function(self, owner, anchor) self.owner = owner; self.anchor = anchor end,
    ClearLines = function(self) self.lines = {} end,
    AddLine = function(self, txt, r, g, b) table.insert(self.lines, { text = txt, r = r, g = g, b = b }) end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
}

local FrameMT = {}
FrameMT.__index = FrameMT

function FrameMT:SetSize(w, h) self.width = w; self.height = h end
function FrameMT:SetWidth(w) self.width = w end
function FrameMT:SetHeight(h) self.height = h end
function FrameMT:GetWidth() return self.width or 36 end
function FrameMT:GetHeight() return self.height or 36 end
function FrameMT:SetPoint(point, rel, relPoint, x, y)
    self.point = { point = point, rel = rel, relPoint = relPoint, x = x or 0, y = y or 0 }
end
function FrameMT:GetPoint(i)
    if self.point then
        return self.point.point, self.point.rel, self.point.relPoint, self.point.x, self.point.y
    end
    return "CENTER", _G.UIParent, "CENTER", 0, 0
end
function FrameMT:ClearAllPoints() self.point = nil end
function FrameMT:SetAllPoints(parent) self.allPoints = parent end
function FrameMT:SetFrameStrata(strata) self.strata = strata end
function FrameMT:GetFrameStrata() return self.strata end
function FrameMT:SetFrameLevel(level) self.level = level end
function FrameMT:GetFrameLevel() return self.level or 0 end
function FrameMT:EnableMouse(flag) self.mouseEnabled = flag end
function FrameMT:IsMouseEnabled() return self.mouseEnabled end
function FrameMT:Show() self.shown = true end
function FrameMT:Hide() self.shown = false end
function FrameMT:IsShown() return self.shown ~= false end
function FrameMT:GetName() return self.name end
function FrameMT:GetObjectType() return self.objectType or "Frame" end
function FrameMT:GetParent() return self.parent end
function FrameMT:SetParent(p) self.parent = p end
function FrameMT:RegisterForClicks(...) self.registeredClicks = {...} end
function FrameMT:RegisterEvent(evt) self.events = self.events or {}; self.events[evt] = true end
function FrameMT:UnregisterEvent(evt) if self.events then self.events[evt] = nil end end
function FrameMT:SetScript(event, fn) self.scripts = self.scripts or {}; self.scripts[event] = fn end
function FrameMT:GetScript(event) return self.scripts and self.scripts[event] end
function FrameMT:EnableKeyboard(flag) self.keyboardEnabled = flag end
function FrameMT:EnableMouseWheel(flag) self.wheelEnabled = flag end
function FrameMT:SetText(txt) self.text = txt end
function FrameMT:GetText() return self.text end

function FrameMT:SetBackdrop(bd) self.backdrop = bd end
function FrameMT:SetBackdropColor(r, g, b, a) self.backdropColor = {r=r, g=g, b=b, a=a} end
function FrameMT:SetBackdropBorderColor(r, g, b, a) self.backdropBorderColor = {r=r, g=g, b=b, a=a} end

function FrameMT:CreateTexture(name, layer)
    local tex = {
        name = name,
        layer = layer,
        SetTexture = function(s, path) s.texturePath = path end,
        SetVertexColor = function(s, r, g, b, a) s.color = {r=r, g=g, b=b, a=a} end,
        SetWidth = function(s, w) s.width = w end,
        SetHeight = function(s, h) s.height = h end,
        SetSize = function(s, w, h) s.width = w; s.height = h end,
        ClearAllPoints = function(s) s.points = nil end,
        SetPoint = function(s, ...) s.points = {...} end,
        SetAllPoints = function(s, parent) s.allPoints = parent end,
        Show = function(s) s.shown = true end,
        Hide = function(s) s.shown = false end,
        IsShown = function(s) return s.shown end,
    }
    self.textures = self.textures or {}
    table.insert(self.textures, tex)
    return tex
end

function FrameMT:CreateFontString(name, layer, template)
    local fs = {
        name = name,
        layer = layer,
        template = template,
        SetPoint = function(s, ...) s.point = {...} end,
        SetText = function(s, txt) s.text = txt end,
        GetText = function(s) return s.text end,
        Show = function(s) s.shown = true end,
        Hide = function(s) s.shown = false end,
        SetTextColor = function(s, r, g, b, a) s.color = {r=r, g=g, b=b, a=a} end,
    }
    if name then
        _G[name] = fs
    end
    return fs
end

_G.CreateFrame = function(frameType, name, parent, template)
    local f = setmetatable({
        objectType = frameType,
        name = name,
        parent = parent or _G.UIParent,
        template = template,
        shown = true,
        level = 0,
    }, FrameMT)
    if name then
        _G[name] = f
    end
    table.insert(mockFrames, f)
    return f
end

_G.UIParent = _G.CreateFrame("Frame", "UIParent", nil)
_G.WorldFrame = _G.CreateFrame("Frame", "WorldFrame", nil)

_G.strsplit = function(delimiter, text)
    local list = {}
    for match in (text .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(list, match)
    end
    return table.unpack(list)
end

-- Load ZenAlign core files
local ZenAlign = {}
_G.ZenAlign = ZenAlign

local function loadScript(file)
    local f, err = loadfile(file)
    if not f then error("Failed to load file " .. file .. ": " .. tostring(err)) end
    f("ZenAlign", ZenAlign)
end

loadScript("ZenAlign/Localization/enUS.lua")
loadScript("ZenAlign/Core/Utils.lua")
loadScript("ZenAlign/Core/Config.lua")
loadScript("ZenAlign/Data/Frames.lua")
loadScript("ZenAlign/Core/Core.lua")
loadScript("ZenAlign/Modules/Keybind.lua")

ZenAlign:Initialize()

-- Test Harness Functions
local passCount = 0
local failCount = 0

local function assert_eq(actual, expected, testName)
    if actual == expected then
        passCount = passCount + 1
        print("  [PASS] " .. testName)
    else
        failCount = failCount + 1
        print(string.format("  [FAIL] %s: Expected %s, got %s", testName, tostring(expected), tostring(actual)))
    end
end

local function assert_true(cond, testName)
    if cond then
        passCount = passCount + 1
        print("  [PASS] " .. testName)
    else
        failCount = failCount + 1
        print("  [FAIL] " .. testName .. ": Condition was false")
    end
end

print("=== Running ZenAlign FE-M2: Keybinding Engine Tests ===")

local Keybind = ZenAlign:GetModule("Keybind")
assert_true(Keybind ~= nil, "Keybind module loaded")

-- 1. Test Suite 1: Activation / Deactivation State Changes & Overlay Creation
print("\n--- Test Suite 1: Activation / Deactivation State Changes ---")
assert_eq(Keybind.active, false, "Keybind initially inactive")

Keybind:Activate()
assert_eq(Keybind.active, true, "Keybind active after Activate()")
local catcher = _G.ZenAlignKeybindCatcher
assert_true(catcher ~= nil, "ZenAlignKeybindCatcher overlay created")
assert_eq(catcher:GetFrameStrata(), "FULLSCREEN_DIALOG", "Catcher strata is FULLSCREEN_DIALOG")
assert_eq(catcher:GetFrameLevel(), 500, "Catcher level is 500")

local highlight = _G.ZenAlignKeybindHighlight
assert_true(highlight ~= nil, "ZenAlignKeybindHighlight overlay created")
assert_eq(highlight:GetFrameStrata(), "FULLSCREEN_DIALOG", "Highlight strata is FULLSCREEN_DIALOG")
assert_eq(highlight:GetFrameLevel(), 501, "Highlight level is 501")
assert_eq(highlight.backdropBorderColor.r, 1.0, "Highlight border Red = 1.0")
assert_eq(highlight.backdropBorderColor.g, 0.82, "Highlight border Green = 0.82")
assert_eq(highlight.backdropBorderColor.b, 0.0, "Highlight border Blue = 0.0")
assert_eq(highlight.backdropBorderColor.a, 0.8, "Highlight border Alpha = 0.8")

Keybind:Deactivate()
assert_eq(Keybind.active, false, "Keybind inactive after Deactivate()")
assert_true(not catcher:IsShown(), "Catcher frame hidden on deactivate")
assert_true(not highlight:IsShown(), "Highlight frame hidden on deactivate")

Keybind:Toggle()
assert_eq(Keybind.active, true, "Toggle() activated keybind mode")
Keybind:Toggle()
assert_eq(Keybind.active, false, "Toggle() deactivated keybind mode")

-- 2. Test Suite 2: Candidate Button Scanning & Hover Detection
print("\n--- Test Suite 2: Candidate Button Hover Detection & Command Mapping ---")
-- Create mock candidate buttons
local actionBtn1 = _G.CreateFrame("CheckButton", "ActionButton1", UIParent)
actionBtn1.action = 1
local actionBtn1HotKey = actionBtn1:CreateFontString("ActionButton1HotKey", "OVERLAY")

local multiBarBL1 = _G.CreateFrame("CheckButton", "MultiBarBottomLeftButton1", UIParent)
multiBarBL1.action = 2
local multiBarBR1 = _G.CreateFrame("CheckButton", "MultiBarBottomRightButton1", UIParent)
local multiBarR1 = _G.CreateFrame("CheckButton", "MultiBarRightButton1", UIParent)
local multiBarL1 = _G.CreateFrame("CheckButton", "MultiBarLeftButton1", UIParent)
local petBtn1 = _G.CreateFrame("CheckButton", "PetActionButton1", UIParent)
local stanceBtn1 = _G.CreateFrame("CheckButton", "StanceButton1", UIParent)

-- Test Command Mapping
assert_eq(Keybind:GetButtonActionCommand(actionBtn1), "ACTIONBUTTON1", "ActionButton1 maps to ACTIONBUTTON1")
assert_eq(Keybind:GetButtonActionCommand(multiBarBL1), "MULTIACTIONBAR1BUTTON1", "MultiBarBottomLeftButton1 maps to MULTIACTIONBAR1BUTTON1")
assert_eq(Keybind:GetButtonActionCommand(multiBarBR1), "MULTIACTIONBAR2BUTTON1", "MultiBarBottomRightButton1 maps to MULTIACTIONBAR2BUTTON1")
assert_eq(Keybind:GetButtonActionCommand(multiBarR1), "MULTIACTIONBAR3BUTTON1", "MultiBarRightButton1 maps to MULTIACTIONBAR3BUTTON1")
assert_eq(Keybind:GetButtonActionCommand(multiBarL1), "MULTIACTIONBAR4BUTTON1", "MultiBarLeftButton1 maps to MULTIACTIONBAR4BUTTON1")
assert_eq(Keybind:GetButtonActionCommand(petBtn1), "BONUSACTIONBUTTON1", "PetActionButton1 maps to BONUSACTIONBUTTON1")
assert_eq(Keybind:GetButtonActionCommand(stanceBtn1), "SHAPESHIFTBUTTON1", "StanceButton1 maps to SHAPESHIFTBUTTON1")

-- Test Action / Spell Name Lookup
assert_eq(Keybind:GetButtonActionName(actionBtn1), "Frostbolt", "ActionButton1 action name is Frostbolt")
assert_eq(Keybind:GetButtonActionName(multiBarBL1), "Hearthstone", "MultiBarBottomLeftButton1 action name is Hearthstone")

-- Test Candidate Button Resolution from Child Focus
local actionBtn1Icon = _G.CreateFrame("Frame", "ActionButton1Icon", actionBtn1)
local resolvedBtn = Keybind:FindCandidateButton(actionBtn1Icon)
assert_eq(resolvedBtn, actionBtn1, "Child icon frame resolves to parent ActionButton1 candidate")

-- Test OnUpdate Focus Trace
Keybind:Activate()
mouseFocus = actionBtn1
Keybind:OnUpdate(0.016)

assert_eq(Keybind:GetHoveredActionButton(), actionBtn1, "Hovered action button resolved to ActionButton1")
assert_true(highlight:IsShown(), "Golden highlight overlay shown over hovered button")
assert_true(_G.GameTooltip.shown, "GameTooltip shown for hovered button")
assert_eq(_G.GameTooltip.lines[1].text, "Frostbolt", "GameTooltip header is Frostbolt")
assert_eq(_G.GameTooltip.lines[2].text, "Command: ACTIONBUTTON1", "GameTooltip line 2 is Command: ACTIONBUTTON1")
assert_eq(_G.GameTooltip.lines[3].text, "Binding: Unbound", "GameTooltip line 3 is Binding: Unbound")

-- 3. Test Suite 3: Key Capture & Modifier Formatting
print("\n--- Test Suite 3: Key Capture & Modifier String Formatting ---")
shiftDown, ctrlDown, altDown = false, false, false

assert_eq(Keybind:FormatKey("f"), "F", "Raw 'f' formats to 'F'")
assert_eq(Keybind:FormatKey("1"), "1", "Raw '1' formats to '1'")
assert_eq(Keybind:FormatKey("space"), "SPACE", "Raw 'space' formats to 'SPACE'")

-- Modifiers
shiftDown = true
assert_eq(Keybind:FormatKey("f"), "SHIFT-F", "Shift+f formats to 'SHIFT-F'")

ctrlDown = true
assert_eq(Keybind:FormatKey("f"), "SHIFT-CTRL-F", "Shift+Ctrl+f formats to 'SHIFT-CTRL-F'")

altDown = true
assert_eq(Keybind:FormatKey("f"), "SHIFT-CTRL-ALT-F", "Shift+Ctrl+Alt+f formats to 'SHIFT-CTRL-ALT-F'")

-- Ignore Standalone Modifiers
assert_eq(Keybind:FormatKey("LSHIFT"), nil, "Standalone LSHIFT ignored")
assert_eq(Keybind:FormatKey("RCTRL"), nil, "Standalone RCTRL ignored")
assert_eq(Keybind:FormatKey("ALT"), nil, "Standalone ALT ignored")

-- Special Keys: NumPad, Mouse Buttons, Mouse Wheel
shiftDown, ctrlDown, altDown = false, false, false
assert_eq(Keybind:FormatKey("NUMPAD1"), "NUMPAD1", "NUMPAD1 formats correctly")
assert_eq(Keybind:FormatKey("NUMPADPLUS"), "NUMPADPLUS", "NUMPADPLUS formats correctly")

-- Mouse Button Mapping via OnMouseDown
mouseFocus = actionBtn1
Keybind:OnUpdate(0.016)

saveBindingsCalls = {}
Keybind:OnMouseDown("MiddleButton")
assert_eq(mockBindings["ACTIONBUTTON1"][1], "BUTTON3", "MiddleButton bound BUTTON3 to ACTIONBUTTON1")
assert_true(#saveBindingsCalls > 0 and saveBindingsCalls[#saveBindingsCalls] == 2, "SaveBindings(2) called on mouse bind")

-- Mouse Wheel Mapping via OnMouseWheel
Keybind:OnMouseWheel(1)
assert_eq(mockBindings["ACTIONBUTTON1"][1], "MOUSEWHEELUP", "Mouse wheel up bound MOUSEWHEELUP to ACTIONBUTTON1")

-- Keyboard Key Binding via OnKeyDown
Keybind:OnKeyDown("1")
assert_eq(mockBindings["ACTIONBUTTON1"][1], "1", "Key 1 bound to ACTIONBUTTON1")

shiftDown = true
Keybind:OnKeyDown("e")
assert_eq(mockBindings["ACTIONBUTTON1"][1], "SHIFT-E", "SHIFT-E bound to ACTIONBUTTON1")
shiftDown = false

-- Test Hotkey Text Shortening & Dynamic Update
assert_eq(actionBtn1HotKey:GetText(), "sE", "ActionButton1 hotkey text updated to shortened 'sE'")

-- 4. Test Suite 4: Unbinding & Escape Handlers
print("\n--- Test Suite 4: Unbinding & ESC / DELETE Handlers ---")
-- DELETE / BACKSPACE keypress on hovered button
saveBindingsCalls = {}
Keybind:OnKeyDown("DELETE")

local currentKeys = { _G.GetBindingKey("ACTIONBUTTON1") }
assert_eq(#currentKeys, 0, "DELETE unbound all keys from ACTIONBUTTON1")
assert_eq(actionBtn1HotKey:GetText(), "", "ActionButton1 hotkey text cleared to empty string")
assert_true(#saveBindingsCalls > 0 and saveBindingsCalls[#saveBindingsCalls] == 2, "SaveBindings(2) called on unbind")

-- ESCAPE keypress deactivates keybind mode
assert_eq(Keybind.active, true, "Keybind active before ESCAPE")
Keybind:OnKeyDown("ESCAPE")
assert_eq(Keybind.active, false, "Keybind deactivated after ESCAPE")

-- 5. Test Suite 5: Slash Command Integration
print("\n--- Test Suite 5: Slash Command Integration ---")
assert_eq(Keybind.active, false, "Keybind initially inactive before slash command")

ZenAlign:HandleSlashCommand("bind")
assert_eq(Keybind.active, true, "/za bind activated Keybind mode")

ZenAlign:HandleSlashCommand("keybind")
assert_eq(Keybind.active, false, "/za keybind toggled off Keybind mode")

print("\n=== Test Results ===")
print(string.format("Passed: %d, Failed: %d", passCount, failCount))
if failCount > 0 then
    os.exit(1)
end
