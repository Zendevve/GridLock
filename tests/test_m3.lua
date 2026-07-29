-- test_m3.lua
-- Unit & Integration Tests for ZenAlign Milestone 3 (R3)

-- 1. Mock WoW 3.3.5a API Environment
local mockFrames = {}
local mockScreen = { width = 1920, height = 1080 }
local mouseFocus = nil

_G.GetScreenWidth = function() return mockScreen.width end
_G.GetScreenHeight = function() return mockScreen.height end
_G.GetMouseFocus = function() return mouseFocus end
_G.InCombatLockdown = function() return false end

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg)
        -- print("[MOCK CHAT] " .. tostring(msg))
    end
}
_G.SlashCmdList = {}

local FrameMT = {}
FrameMT.__index = FrameMT

function FrameMT:SetSize(w, h) self.width = w; self.height = h end
function FrameMT:SetWidth(w) self.width = w end
function FrameMT:SetHeight(h) self.height = h end
function FrameMT:GetWidth() return self.width or 100 end
function FrameMT:GetHeight() return self.height or 50 end
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
function FrameMT:SetMovable(flag) self.movable = flag end
function FrameMT:SetClampedToScreen(flag) self.clamped = flag end
function FrameMT:Show() self.shown = true end
function FrameMT:Hide() self.shown = false end
function FrameMT:IsShown() return self.shown end
function FrameMT:GetName() return self.name end
function FrameMT:GetObjectType() return self.objectType or "Frame" end
function FrameMT:GetEffectiveScale() return self.scale or 1.0 end
function FrameMT:GetScale() return self.scale or 1.0 end
function FrameMT:SetScale(s) self.scale = s end
function FrameMT:GetAlpha() return self.alpha or 1.0 end
function FrameMT:SetAlpha(a) self.alpha = a end
function FrameMT:GetCenter() return self.x or 500, self.y or 400 end
function FrameMT:GetLeft() return (self.x or 500) - (self:GetWidth()/2) end
function FrameMT:GetRight() return (self.x or 500) + (self:GetWidth()/2) end
function FrameMT:GetTop() return (self.y or 400) + (self:GetHeight()/2) end
function FrameMT:GetBottom() return (self.y or 400) - (self:GetHeight()/2) end
function FrameMT:GetNumPoints() return self.point and 1 or 0 end
function FrameMT:GetParent() return self.parent end
function FrameMT:SetParent(p) self.parent = p end
function FrameMT:RegisterForClicks(...) self.registeredClicks = {...} end
function FrameMT:SetScript(event, fn) self.scripts = self.scripts or {}; self.scripts[event] = fn end
function FrameMT:GetScript(event) return self.scripts and self.scripts[event] end
function FrameMT:StartMoving() end
function FrameMT:StopMovingOrSizing() end
function FrameMT:EnableKeyboard(flag) self.keyboardEnabled = flag end
function FrameMT:EnableMouseWheel(flag) self.wheelEnabled = flag end
function FrameMT:RegisterEvent(evt) self.events = self.events or {}; self.events[evt] = true end
function FrameMT:UnregisterEvent(evt) if self.events then self.events[evt] = nil end end
function FrameMT:SetText(txt) self.text = txt end
function FrameMT:GetText() return self.text end
function FrameMT:RegisterForDrag(...) self.registeredDrag = {...} end
function FrameMT:SetPropagateKeyboardInput(flag) self.propagateKeyboard = flag end
function FrameMT:SetAutoFocus(flag) self.autoFocus = flag end
function FrameMT:SetNumeric(flag) self.numeric = flag end
function FrameMT:SetMaxLetters(n) self.maxLetters = n end
function FrameMT:SetCursorPosition(n) self.cursorPos = n end
function FrameMT:ClearFocus() end
function FrameMT:SetScrollChild(child) self.scrollChild = child end
function FrameMT:SetMinMaxValues(min, max) self.minVal = min; self.maxVal = max end
function FrameMT:SetValueStep(step) self.valStep = step end
function FrameMT:SetValue(v) self.val = v end
function FrameMT:GetValue() return self.val or 0 end
function FrameMT:GetFontString()
    if not self.fontString then
        self.fontString = self:CreateFontString(nil, "OVERLAY")
    end
    return self.fontString
end
function FrameMT:SetVerticalScroll(val) self.vScroll = val end
function FrameMT:SetHighlightTexture(...) end
function FrameMT:GetHighlightTexture()
    if not self.highlightTexture then
        self.highlightTexture = self:CreateTexture(nil, "HIGHLIGHT")
    end
    return self.highlightTexture
end
function FrameMT:SetNormalTexture(...) end
function FrameMT:SetPushedTexture(...) end
function FrameMT:SetDisabledTexture(...) end

function FrameMT:SetBackdrop(bd) self.backdrop = bd end
function FrameMT:SetBackdropColor(r, g, b, a) self.backdropColor = {r=r, g=g, b=b, a=a} end
function FrameMT:SetBackdropBorderColor(r, g, b, a) self.backdropBorderColor = {r=r, g=g, b=b, a=a} end

function FrameMT:CreateTexture(name, layer)
    local tex = {
        name = name,
        layer = layer,
        SetTexture = function(s, path)
            if type(path) == "number" then
                error("Numeric SetTexture call is illegal in 3.3.5a texture safety check!")
            end
            s.texturePath = path
        end,
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
        SetTextColor = function(s, r, g, b, a) s.color = {r=r, g=g, b=b, a=a} end,
        SetFont = function(s, font, size, flags) s.font = {font=font, size=size, flags=flags} end,
        SetJustifyH = function(s, align) s.justifyH = align end,
        SetJustifyV = function(s, align) s.justifyV = align end,
        SetWidth = function(s, w) s.width = w end,
        SetHeight = function(s, h) s.height = h end,
    }
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

_G.wipe = function(t)
    for k in pairs(t) do t[k] = nil end
    return t
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
loadScript("ZenAlign/Modules/Grid.lua")
loadScript("ZenAlign/Modules/Snap.lua")
loadScript("ZenAlign/Modules/Picker.lua")
loadScript("ZenAlign/Modules/Mover.lua")
loadScript("ZenAlign/Modules/Position.lua")
loadScript("ZenAlign/UI/HUD.lua")
loadScript("ZenAlign/UI/Dashboard.lua")

ZenAlign:Initialize()

-- Unit Tests
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

print("=== Running ZenAlign Milestone 3 (R3) Integration Tests ===")

-- 1. Test Grid Engine & Grid Size Cycling
print("\n--- Test Suite 1: Grid Engine & Grid Size Cycling ---")
local Grid = ZenAlign:GetModule("Grid")
assert_true(Grid ~= nil, "Grid module loaded")

Grid:CreateGrid()
assert_true(Grid.frame ~= nil, "Grid frame created")
assert_eq(Grid.frame:GetName(), "ZenAlignGrid", "Grid frame name is ZenAlignGrid")

ZenAlign.db.gridSize = 32
Grid:Show()
assert_true(Grid.shown, "Grid is shown")
assert_true(#Grid.frame.lines > 0, "Grid lines created")

-- Verify line textures use WHITE8X8 string
for _, line in ipairs(Grid.frame.lines) do
    if line:IsShown() then
        assert_eq(line.texturePath, "Interface\\Buttons\\WHITE8X8", "Line texture is WHITE8X8")
    end
end

-- Test Grid:CycleSize()
local size1 = Grid:CycleSize()
assert_eq(size1, 64, "CycleSize 32 -> 64")
assert_eq(ZenAlign.db.gridSize, 64, "ZenAlign.db.gridSize updated to 64")

local size2 = Grid:CycleSize()
assert_eq(size2, 8, "CycleSize 64 -> 8")
assert_eq(ZenAlign.db.gridSize, 8, "ZenAlign.db.gridSize updated to 8")

local size3 = Grid:CycleSize()
assert_eq(size3, 16, "CycleSize 8 -> 16")

local size4 = Grid:CycleSize()
assert_eq(size4, 32, "CycleSize 16 -> 32")

-- 2. Test Snap System Coordinates
print("\n--- Test Suite 2: Snap Engine ---")
local Snap = ZenAlign:GetModule("Snap")
assert_true(Snap ~= nil, "Snap module loaded")

ZenAlign.db.snapEnabled = true
ZenAlign.db.gridSize = 32

local sx, sy = Snap:CalculateSnappedPosition(100, 200, 32)
assert_eq(sx, 96, "100 snapped to 32px step -> 96")
assert_eq(sy, 192, "200 snapped to 32px step -> 192")

local sx8, sy8 = Snap:CalculateSnappedPosition(100, 200, 8)
assert_eq(sx8, 104, "100 snapped to 8px step -> 104")

local sx16, sy16 = Snap:CalculateSnappedPosition(100, 200, 16)
assert_eq(sx16, 96, "100 snapped to 16px step -> 96")

local sx64, sy64 = Snap:CalculateSnappedPosition(100, 200, 64)
assert_eq(sx64, 128, "100 snapped to 64px step -> 128")

-- 3. Test Top Screen HUD Banner (ZenAlignHUD)
print("\n--- Test Suite 3: HUD Banner ---")
local HUD = ZenAlign:GetModule("HUD")
assert_true(HUD ~= nil, "HUD module loaded")

HUD:Show()
local hudFrame = _G.ZenAlignHUD
assert_true(hudFrame ~= nil, "ZenAlignHUD frame exists")
assert_true(hudFrame:IsShown(), "ZenAlignHUD frame is shown")
assert_eq(hudFrame:GetFrameLevel(), 100, "ZenAlignHUD level is 100")

-- Verify all 5 buttons exist and have elevated SetFrameLevel
assert_true(hudFrame.gridBtn ~= nil, "HUD Grid button exists")
assert_true(hudFrame.snapBtn ~= nil, "HUD Snap button exists")
assert_true(hudFrame.pickBtn ~= nil, "HUD Picker button exists")
assert_true(hudFrame.dashBtn ~= nil, "HUD Dashboard button exists")
assert_true(hudFrame.doneBtn ~= nil, "HUD Save/Exit button exists")

assert_true(hudFrame.gridBtn:GetFrameLevel() > hudFrame:GetFrameLevel(), "gridBtn level elevated > 100")
assert_true(hudFrame.snapBtn:GetFrameLevel() > hudFrame:GetFrameLevel(), "snapBtn level elevated > 100")
assert_true(hudFrame.pickBtn:GetFrameLevel() > hudFrame:GetFrameLevel(), "pickBtn level elevated > 100")
assert_true(hudFrame.dashBtn:GetFrameLevel() > hudFrame:GetFrameLevel(), "dashBtn level elevated > 100")
assert_true(hudFrame.doneBtn:GetFrameLevel() > hudFrame:GetFrameLevel(), "doneBtn level elevated > 100")

-- Test HUD buttons OnClick handlers
ZenAlign.db.gridSize = 32
hudFrame.gridBtn:GetScript("OnClick")(hudFrame.gridBtn)
assert_eq(ZenAlign.db.gridSize, 64, "HUD gridBtn click cycled size to 64")
assert_eq(hudFrame.gridBtn:GetText(), "Grid: 64px", "HUD gridBtn text updated to Grid: 64px")

assert_eq(ZenAlign.db.snapEnabled, true, "Snap initially enabled")
hudFrame.snapBtn:GetScript("OnClick")(hudFrame.snapBtn)
assert_eq(ZenAlign.db.snapEnabled, false, "HUD snapBtn toggled snap to OFF")
assert_eq(hudFrame.snapBtn:GetText(), "Snap: OFF", "HUD snapBtn text updated to Snap: OFF")

-- Test Save/Exit button
ZenAlign.editMode = true
hudFrame.doneBtn:GetScript("OnClick")(hudFrame.doneBtn)
assert_eq(ZenAlign.editMode, false, "HUD Save/Exit button exited edit mode")
assert_eq(hudFrame:IsShown(), false, "HUD hidden after Save/Exit")
assert_eq(Grid.shown, false, "Grid hidden after Save/Exit")

-- 4. Test Mouseover Picker & ZenAlignPickerCatcher Focus Trace Fix
print("\n--- Test Suite 4: Mouseover Picker & Focus Trace Fix ---")
local Picker = ZenAlign:GetModule("Picker")
assert_true(Picker ~= nil, "Picker module loaded")

Picker:Start()
assert_true(Picker.active, "Picker is active")
local catcher = _G.ZenAlignPickerCatcher
assert_true(catcher ~= nil, "ZenAlignPickerCatcher exists")
assert_true(catcher:IsShown(), "ZenAlignPickerCatcher is shown")

-- Create target mock frames
local playerFrame = _G.CreateFrame("Frame", "PlayerFrame", UIParent)
playerFrame.x, playerFrame.y = 200, 300
playerFrame.width, playerFrame.height = 120, 40

-- Simulate GetMouseFocus returning ZenAlignPickerCatcher when mouseover catcher
mouseFocus = catcher
assert_eq(catcher:GetName(), "ZenAlignPickerCatcher", "mouseFocus is ZenAlignPickerCatcher")

-- Run Picker:OnUpdate()
-- It temporarily disables mouse on catcher, calls GetMouseFocus(), and restores mouse on catcher
mouseFocus = playerFrame -- When catcher mouse disabled, GetMouseFocus returns playerFrame
Picker:OnUpdate()

assert_true(Picker.currentFocus == playerFrame, "Picker correctly focused PlayerFrame ignoring ZenAlignPickerCatcher")
assert_true(Picker.highlightFrame:IsShown(), "Golden highlight frame is shown")
assert_eq(Picker.highlightFrame.backdropBorderColor.r, 1.0, "Golden border red channel = 1.0")
assert_eq(Picker.highlightFrame.backdropBorderColor.g, 0.82, "Golden border green channel = 0.82")
assert_eq(Picker.highlightFrame.backdropBorderColor.b, 0.0, "Golden border blue channel = 0.0")
assert_eq(Picker.highlightFrame.backdropBorderColor.a, 1.0, "Golden border alpha channel = 1.0")

-- Test left-click selection
catcher:GetScript("OnClick")(catcher, "LeftButton")
assert_eq(Picker.active, false, "Picker stopped after left-click selection")

local Mover = ZenAlign:GetModule("Mover")
assert_true(Mover.movers["PlayerFrame"] ~= nil, "Mover handle attached to PlayerFrame upon picker click")

-- 5. Test Slash Commands
print("\n--- Test Suite 5: Slash Commands ---")
ZenAlign:HandleSlashCommand("grid 16")
assert_eq(ZenAlign.db.gridSize, 16, "/za grid 16 set gridSize to 16")
assert_true(Grid.shown, "/za grid 16 showed grid")

ZenAlign:HandleSlashCommand("snap")
assert_eq(ZenAlign.db.snapEnabled, true, "/za snap toggled snap back to ON")

ZenAlign:HandleSlashCommand("pick")
assert_true(Picker.active, "/za pick activated Picker")

ZenAlign:HandleSlashCommand("done")
assert_eq(ZenAlign.editMode, false, "/za done exited edit mode")

print("\n=== Test Results ===")
print(string.format("Passed: %d, Failed: %d", passCount, failCount))
if failCount > 0 then
    os.exit(1)
end
