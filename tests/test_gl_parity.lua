-- tests/test_gl_parity.lua
-- Unit & Integration Test Suite for GridLock Dominos & Bartender4 Feature Parity

local unpack = unpack or table.unpack

local passCount = 0
local failCount = 0

local function assert_eq(actual, expected, msg)
    if actual == expected then
        passCount = passCount + 1
    else
        failCount = failCount + 1
        print("FAIL: " .. tostring(msg))
        print("  Expected: " .. tostring(expected))
        print("  Actual:   " .. tostring(actual))
        error("Test failed: " .. tostring(msg))
    end
end

local function assert_true(cond, msg)
    assert_eq(not not cond, true, msg)
end

-- Mock WoW API Environment
_G.UIParent = {
    GetEffectiveScale = function() return 1.0 end,
    GetWidth = function() return 1920 end,
    GetHeight = function() return 1080 end,
    GetLeft = function() return 0 end,
    GetBottom = function() return 0 end,
    GetRight = function() return 1920 end,
    GetTop = function() return 1080 end,
}
_G.WorldFrame = {}
_G.DEFAULT_CHAT_FRAME = { AddMessage = function(self, msg) end }

_G.GetTime = function() return 1000.0 end
_G.InCombatLockdown = function() return false end
_G.GetActiveTalentGroup = function() return 1 end

local bindingsDB = {}
_G.SetBinding = function(key, cmd)
    bindingsDB[key] = cmd
end
_G.GetBindingKey = function(cmd)
    for k, v in pairs(bindingsDB) do
        if v == cmd then return k end
    end
    return nil
end
_G.SaveBindings = function(set) end

local mockFrames = {}
_G.CreateFrame = function(frameType, name, parent, template)
    local f = {
        name = name,
        parent = parent,
        shown = true,
        points = {},
        scale = 1.0,
        alpha = 1.0,
        movable = false,
        userPlaced = false,
        mouseEnabled = true,
        scripts = {},
        attributes = {},
    }
    f.GetName = function(self) return self.name end
    f.GetParent = function(self) return self.parent end
    f.IsShown = function(self) return self.shown end
    f.Show = function(self) self.shown = true end
    f.Hide = function(self) self.shown = false end
    f.SetMovable = function(self, mov) self.movable = mov end
    f.SetUserPlaced = function(self, up) self.userPlaced = up end
    f.EnableMouse = function(self, enable) self.mouseEnabled = enable end
    f.EnableKeyboard = function(self, enable) end
    f.EnableMouseWheel = function(self, enable) end
    f.RegisterForClicks = function(self, ...) end
    f.RegisterForDrag = function(self, ...) end
    f.SetClampedToScreen = function(self, clamp) end
    f.SetAllPoints = function(self, rel) end
    f.SetFrameStrata = function(self, strata) end
    f.SetFrameLevel = function(self, level) self.level = level end
    f.GetFrameLevel = function(self) return self.level or 1 end
    f.GetEffectiveScale = function(self) return self.scale end
    f.GetScale = function(self) return self.scale end
    f.SetScale = function(self, sc) self.scale = sc end
    f.GetAlpha = function(self) return self.alpha end
    f.SetAlpha = function(self, a) self.alpha = a end
    f.GetWidth = function(self) return 36 end
    f.GetHeight = function(self) return 36 end
    f.SetWidth = function(self, w) end
    f.SetHeight = function(self, h) end
    f.SetSize = function(self, w, h) end
    f.SetText = function(self, t) self.text = t end
    f.GetText = function(self) return self.text end
    f.GetCenter = function(self) return 500, 500 end
    f.GetLeft = function(self) return 482 end
    f.GetRight = function(self) return 518 end
    f.GetBottom = function(self) return 482 end
    f.GetTop = function(self) return 518 end
    f.GetNumPoints = function(self) return #self.points end
    f.GetPoint = function(self, idx) return "CENTER", _G.UIParent, "CENTER", 0, 0 end
    f.SetPoint = function(self, p, rel, rp, x, y)
        table.insert(self.points, { p, rel, rp, x, y })
    end
    f.ClearAllPoints = function(self) self.points = {} end
    f.SetBackdrop = function(self, bd) end
    f.SetBackdropColor = function(self, r, g, b, a) end
    f.SetBackdropBorderColor = function(self, r, g, b, a) end
    f.CreateTexture = function(self)
        return {
            SetTexture = function() end,
            SetVertexColor = function() end,
            SetWidth = function() end,
            SetHeight = function() end,
            SetPoint = function() end,
            ClearAllPoints = function() end,
            Hide = function() end,
            Show = function() end,
            SetTexCoord = function(s, a, b, c, d) self.texCoords = { a, b, c, d } end,
        }
    end
    f.CreateFontString = function(self)
        return {
            SetPoint = function() end,
            SetTextColor = function() end,
            SetText = function(s, txt) self.text = txt end,
            GetText = function(s) return self.text end,
            Hide = function() end,
            Show = function() end,
        }
    end
    f.SetScript = function(self, script, fn) self.scripts[script] = fn end
    f.GetScript = function(self, script) return self.scripts[script] end
    f.SetAttribute = function(self, k, v) self.attributes[k] = v end

    if name then _G[name] = f end
    table.insert(mockFrames, f)
    return f
end

_G.GetMouseFocus = function() return nil end
_G.MouseIsOver = function(f) return true end

-- 1. Initialize GridLock Core & Modules
dofile("GridLock/Localization/enUS.lua")
dofile("GridLock/Core/Init.lua")
dofile("GridLock/Core/Utils.lua")
dofile("GridLock/Core/Config.lua")
dofile("GridLock/Data/Frames.lua")
dofile("GridLock/Data/Position.lua")
dofile("GridLock/Modules/Position.lua")
dofile("GridLock/Modules/Mover.lua")
dofile("GridLock/Modules/BarLayout.lua")
dofile("GridLock/Modules/Keybind.lua")
dofile("GridLock/Modules/Profile.lua")

print("=========================================")
print("Running GridLock Parity & Feature Tests")
print("=========================================")

-- Test Group 1: Universal Frame Catalog & Mover Mobility
print("[Test Group 1] Universal Frame Mobility Across Catalog")
local FD = GridLock.FrameData
local allFrames = FD:GetAllFrames()
assert_true(#allFrames >= 50, "Frame catalog contains 50+ frames")

local Mover = GridLock:GetModule("Mover")
local testTarget = _G.CreateFrame("Frame", "BuffFrame")
local mover = Mover:AttachToFrame("BuffFrame")
assert_true(mover ~= nil, "Mover successfully attached to BuffFrame")
assert_true(testTarget.movable == true, "BuffFrame set to movable")
assert_true(testTarget.userPlaced == true, "BuffFrame set to userPlaced")

-- Test Group 2: Quick Keybind Engine (/kb)
print("[Test Group 2] Quick Keybind Engine")
local Keybind = GridLock:GetModule("Keybind")
assert_true(Keybind ~= nil, "Keybind module loaded")
Keybind:Activate()
assert_true(Keybind.active == true, "Keybind mode active")

local mockBtn = _G.CreateFrame("Button", "ActionButton1")
Keybind:BindKeyToButton(mockBtn, "CTRL-1")
assert_eq(_G.GetBindingKey("ACTIONBUTTON1"), "CTRL-1", "Bound CTRL-1 to ActionButton1")

Keybind:Deactivate()
assert_true(Keybind.active == false, "Keybind mode deactivated")

-- Test Group 3: Clean Icon Zoom & Click-Through
print("[Test Group 3] Icon Zooming & Click-Through Controls")
local mockBar = _G.CreateFrame("Frame", "MultiBarRight")
local btn1 = _G.CreateFrame("Button", "MultiBarRightButton1")
btn1.Icon = btn1:CreateTexture()

GridLock:SetBarIconZoom(mockBar, true)
assert_true(mockBar.iconZoomed == true, "Icon zoom enabled on bar")

GridLock:SetBarClickThrough(mockBar, true)
assert_eq(btn1.mouseEnabled, false, "Click-through disabled mouse input on buttons")

-- Test Group 4: Dual-Spec Profile Management
print("[Test Group 4] Dual-Spec Profile Auto-Switching")
local Profile = GridLock:GetModule("Profile")
assert_true(Profile ~= nil, "Profile module loaded")

Profile:CreateProfile("Primary Spec")
Profile:CreateProfile("Secondary Spec")

_G.GetActiveTalentGroup = function() return 2 end
Profile:OnSpecChanged()
assert_eq(Profile.currentProfile, "Secondary Spec", "Auto-switched to Secondary Spec profile on spec 2")

_G.GetActiveTalentGroup = function() return 1 end
Profile:OnSpecChanged()
assert_eq(Profile.currentProfile, "Primary Spec", "Auto-switched to Primary Spec profile on spec 1")

print("=========================================")
print(string.format("All Parity Tests PASSED! (Passed: %d, Failed: 0)", passCount))
print("=========================================")
