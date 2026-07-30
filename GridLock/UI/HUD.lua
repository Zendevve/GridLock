-- GridLock HUD Module
-- Top screen Control Bar displayed during Edit Mode

local GridLock = select(2, ...)

local HUD = {}
GridLock:RegisterModule("HUD", HUD)

HUD.frame = nil

function HUD:OnInitialize()
    -- Created on demand
end

-- Helper to create ultra-clean modern styled buttons
local function CreateStyledButton(name, parent, width, height, text, r, g, b)
    r, g, b = r or 0.0, g or 0.8, b or 1.0
    local btn = CreateFrame("Button", name, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)

    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.10, 0.12, 0.18, 0.95)
    btn.bg = bg

    -- 1px Border
    local border = btn:CreateTexture(nil, "BORDER")
    border:SetAllPoints(btn)
    border:SetTexture("Interface\\Buttons\\WHITE8X8")
    border:SetVertexColor(r * 0.5, g * 0.5, b * 0.5, 0.6)
    btn.border = border

    -- Label
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetText(text)
    label:SetTextColor(r, g, b, 1.0)
    btn.label = label

    -- Hover effect
    btn:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(0.18, 0.24, 0.35, 1.0)
        self.border:SetVertexColor(r, g, b, 1.0)
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(0.10, 0.12, 0.18, 0.95)
        self.border:SetVertexColor(r * 0.5, g * 0.5, b * 0.5, 0.6)
    end)

    -- Click tactile feedback
    btn:SetScript("OnMouseDown", function(self)
        self.label:SetPoint("CENTER", self, "CENTER", 1, -1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self.label:SetPoint("CENTER", self, "CENTER", 0, 0)
    end)

    function btn:SetButtonText(t)
        self.label:SetText(t)
    end

    return btn
end

-- Create top HUD control bar
function HUD:CreateFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "GridLockHUD", UIParent)
    f:SetWidth(780)
    f:SetHeight(38)
    f:SetPoint("TOP", UIParent, "TOP", 0, -6)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    -- Glassmorphic Dark Capsule Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    f:SetBackdropColor(0.04, 0.05, 0.08, 0.94)
    f:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.7)

    -- Drag handle
    f:SetScript("OnMouseDown", function(self) self:StartMoving() end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

    -- Pulsing Status Indicator Dot
    local dot = f:CreateTexture(nil, "OVERLAY")
    dot:SetWidth(8)
    dot:SetHeight(8)
    dot:SetPoint("LEFT", f, "LEFT", 12, 0)
    dot:SetTexture("Interface\\Buttons\\WHITE8X8")
    dot:SetVertexColor(0.0, 1.0, 0.6, 1.0)
    f.dot = dot

    -- Brand & Status Title
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("LEFT", dot, "RIGHT", 8, 0)
    status:SetText("GRIDLOCK EDIT MODE")
    status:SetTextColor(0.9, 0.95, 1.0, 1.0)
    f.status = status

    local buttonFrameLevel = f:GetFrameLevel() + 10
    local xOffset = 180

    -- 1. Grid Size Button (Cycles 8px -> 16px -> 32px -> 64px)
    local gridBtn = CreateStyledButton("GridLockHUDGridBtn", f, 85, 24, "Grid: " .. (GridLock.db and GridLock.db.gridSize or 32) .. "px", 0.0, 0.8, 1.0)
    gridBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    gridBtn:SetFrameLevel(buttonFrameLevel)
    gridBtn:SetScript("OnClick", function(self)
        local Grid = GridLock:GetModule("Grid")
        if Grid then
            local newSize = Grid:CycleSize()
            if not Grid.shown then Grid:Show() end
            self:SetButtonText("Grid: " .. newSize .. "px")
        end
    end)
    f.gridBtn = gridBtn

    xOffset = xOffset + 92

    -- 2. Snap Button (Toggles ON/OFF)
    local snapEnabled = GridLock.db and GridLock.db.snapEnabled
    local snapBtn = CreateStyledButton("GridLockHUDSnapBtn", f, 80, 24, snapEnabled and "Snap: ON" or "Snap: OFF", snapEnabled and 0.0 or 1.0, snapEnabled and 1.0 or 0.4, snapEnabled and 0.6 or 0.4)
    snapBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    snapBtn:SetFrameLevel(buttonFrameLevel)
    snapBtn:SetScript("OnClick", function(self)
        GridLock.db.snapEnabled = not GridLock.db.snapEnabled
        local active = GridLock.db.snapEnabled
        self:SetButtonText(active and "Snap: ON" or "Snap: OFF")
        self.label:SetTextColor(active and 0.0 or 1.0, active and 1.0 or 0.4, active and 0.6 or 0.4, 1.0)
        GridLock.Utils.Print(active and GRIDLOCK.SNAP_ENABLED or GRIDLOCK.SNAP_DISABLED)
    end)
    f.snapBtn = snapBtn

    xOffset = xOffset + 87

    -- 3. Mouseover Picker Button
    local pickBtn = CreateStyledButton("GridLockHUDPickBtn", f, 110, 24, "Pick Frame", 1.0, 0.8, 0.2)
    pickBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    pickBtn:SetFrameLevel(buttonFrameLevel)
    pickBtn:SetScript("OnClick", function()
        local Picker = GridLock:GetModule("Picker")
        if Picker then Picker:Toggle() end
    end)
    f.pickBtn = pickBtn

    xOffset = xOffset + 117

    -- 4. Dashboard Toggle Button
    local dashBtn = CreateStyledButton("GridLockHUDDashBtn", f, 90, 24, "Dashboard", 0.0, 0.8, 1.0)
    dashBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    dashBtn:SetFrameLevel(buttonFrameLevel)
    dashBtn:SetScript("OnClick", function()
        local Dashboard = GridLock:GetModule("Dashboard")
        if Dashboard then Dashboard:Toggle() end
    end)
    f.dashBtn = dashBtn

    xOffset = xOffset + 97

    -- 5. Reset All Button
    local resetAllBtn = CreateStyledButton("GridLockHUDResetAllBtn", f, 80, 24, "Reset All", 1.0, 0.4, 0.4)
    resetAllBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    resetAllBtn:SetFrameLevel(buttonFrameLevel)
    resetAllBtn:SetScript("OnClick", function()
        GridLock:ResetAllFrames()
    end)
    f.resetAllBtn = resetAllBtn

    xOffset = xOffset + 87

    -- 6. Save / Exit Button
    local doneBtn = CreateStyledButton("GridLockHUDDoneBtn", f, 90, 24, "Save & Exit", 0.0, 1.0, 0.6)
    doneBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    doneBtn:SetFrameLevel(buttonFrameLevel)
    doneBtn:SetScript("OnClick", function()
        GridLock:ExitEditMode()
    end)
    f.doneBtn = doneBtn

    -- Exit Hint Label
    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    hint:SetText("[ESC]")
    hint:SetTextColor(0.5, 0.6, 0.7, 1.0)
    f.hint = hint

    f:Hide()
    self.frame = f
    return f
end

-- Show HUD
function HUD:Show()
    if not self.frame then
        self:CreateFrame()
    end

    if self.frame.gridBtn then
        local size = GridLock.db and GridLock.db.gridSize or 32
        self.frame.gridBtn:SetButtonText("Grid: " .. size .. "px")
    end

    if self.frame.snapBtn then
        local active = GridLock.db and GridLock.db.snapEnabled
        self.frame.snapBtn:SetButtonText(active and "Snap: ON" or "Snap: OFF")
    end

    self.frame:Show()
end

-- Hide HUD
function HUD:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Toggle HUD
function HUD:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
