-- ZenAlign HUD Module
-- Top screen Control Bar displayed during Edit Mode

local ZenAlign = select(2, ...)

local HUD = {}
ZenAlign:RegisterModule("HUD", HUD)

HUD.frame = nil

function HUD:OnInitialize()
    -- Created on demand
end

-- Create top HUD control bar
function HUD:CreateFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "ZenAlignHUD", UIParent)
    f:SetWidth(760)
    f:SetHeight(38)
    f:SetPoint("TOP", UIParent, "TOP", 0, -5)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    -- Styling / Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
    f:SetBackdropBorderColor(0.2, 0.8, 1.0, 0.8)

    -- Drag bar
    f:SetScript("OnMouseDown", function(self) self:StartMoving() end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

    -- Title / Status Badge
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetPoint("LEFT", f, "LEFT", 12, 0)
    status:SetText("ZenAlign Edit Mode")
    status:SetTextColor(0.2, 1.0, 0.6, 1.0)
    f.status = status

    local buttonFrameLevel = f:GetFrameLevel() + 10
    local xOffset = 145

    -- Grid Size Button (Cycles 8px -> 16px -> 32px -> 64px)
    local gridBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    gridBtn:SetWidth(85)
    gridBtn:SetHeight(22)
    gridBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    gridBtn:SetFrameLevel(buttonFrameLevel)
    gridBtn:SetText("Grid: " .. (ZenAlign.db and ZenAlign.db.gridSize or 32) .. "px")
    gridBtn:SetScript("OnClick", function(self)
        local Grid = ZenAlign:GetModule("Grid")
        if Grid then
            local newSize = Grid:CycleSize()
            if not Grid.shown then
                Grid:Show()
            end
            self:SetText("Grid: " .. newSize .. "px")
        end
    end)
    f.gridBtn = gridBtn

    xOffset = xOffset + 90

    -- Snap Button (Toggles ON/OFF)
    local snapBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    snapBtn:SetWidth(75)
    snapBtn:SetHeight(22)
    snapBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    snapBtn:SetFrameLevel(buttonFrameLevel)
    snapBtn:SetText((ZenAlign.db and ZenAlign.db.snapEnabled) and "Snap: ON" or "Snap: OFF")
    snapBtn:SetScript("OnClick", function(self)
        ZenAlign.db.snapEnabled = not ZenAlign.db.snapEnabled
        self:SetText(ZenAlign.db.snapEnabled and "Snap: ON" or "Snap: OFF")
        ZenAlign.Utils.Print(ZenAlign.db.snapEnabled and ZENALIGN.SNAP_ENABLED or ZENALIGN.SNAP_DISABLED)
    end)
    f.snapBtn = snapBtn

    xOffset = xOffset + 80

    -- Mouseover Picker Button
    local pickBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    pickBtn:SetWidth(120)
    pickBtn:SetHeight(22)
    pickBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    pickBtn:SetFrameLevel(buttonFrameLevel)
    pickBtn:SetText("Mouseover Picker")
    pickBtn:SetScript("OnClick", function()
        local Picker = ZenAlign:GetModule("Picker")
        if Picker then Picker:Toggle() end
    end)
    f.pickBtn = pickBtn

    xOffset = xOffset + 125

    -- Dashboard Toggle Button
    local dashBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    dashBtn:SetWidth(85)
    dashBtn:SetHeight(22)
    dashBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    dashBtn:SetFrameLevel(buttonFrameLevel)
    dashBtn:SetText("Dashboard")
    dashBtn:SetScript("OnClick", function()
        local Dashboard = ZenAlign:GetModule("Dashboard")
        if Dashboard then Dashboard:Toggle() end
    end)
    f.dashBtn = dashBtn

    xOffset = xOffset + 90

    -- Reset All Button
    local resetAllBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetAllBtn:SetWidth(80)
    resetAllBtn:SetHeight(22)
    resetAllBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    resetAllBtn:SetFrameLevel(buttonFrameLevel)
    resetAllBtn:SetText("Reset All")
    resetAllBtn:SetScript("OnClick", function()
        ZenAlign:ResetAllFrames()
    end)
    f.resetAllBtn = resetAllBtn

    xOffset = xOffset + 85

    -- Save / Exit Button
    local doneBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    doneBtn:SetWidth(90)
    doneBtn:SetHeight(22)
    doneBtn:SetPoint("LEFT", f, "LEFT", xOffset, 0)
    doneBtn:SetFrameLevel(buttonFrameLevel)
    doneBtn:SetText("Save / Exit")
    doneBtn:SetScript("OnClick", function()
        ZenAlign:ExitEditMode()
    end)
    f.doneBtn = doneBtn

    -- Exit Hint Label
    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    hint:SetText("(ESC to exit)")
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
        local size = ZenAlign.db and ZenAlign.db.gridSize or 32
        self.frame.gridBtn:SetText("Grid: " .. size .. "px")
    end

    if self.frame.snapBtn then
        self.frame.snapBtn:SetText((ZenAlign.db and ZenAlign.db.snapEnabled) and "Snap: ON" or "Snap: OFF")
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

