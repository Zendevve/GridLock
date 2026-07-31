-- GridLock Dashboard Module
-- Ergonomic Dark-Glassmorphic Master Control Panel for WoW 3.3.5a

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

local Dashboard = {}
if type(GridLock.RegisterModule) == "function" then
    GridLock:RegisterModule("Dashboard", Dashboard)
else
    GridLock.modules = GridLock.modules or {}
    GridLock.modules["Dashboard"] = Dashboard
end

Dashboard.frame = nil
Dashboard.currentFrame = nil
Dashboard.currentFrameName = nil
Dashboard.currentMover = nil
Dashboard.searchText = ""
Dashboard.selectedCategory = "all"
Dashboard.buttons = {}
Dashboard.catButtons = {}
Dashboard.updating = false

function Dashboard:OnInitialize()
    -- Created on demand
end

-- Create a sleek, modern slider using WHITE8X8 backdrop (3.3.5a compliant)
local function CreateCleanSlider(name, parent, width, height, minVal, maxVal, step)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetWidth(width)
    slider:SetHeight(height)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)

    local low = name and _G[name .. "Low"]
    local high = name and _G[name .. "High"]
    local text = name and _G[name .. "Text"]
    if low then low:Hide() end
    if high then high:Hide() end
    if text then text:Hide() end

    return slider
end

-- Create master dashboard frame
function Dashboard:CreateFrame()
    if self.frame then return self.frame end

    -- Container Frame (Dark Glassmorphic #040508 with 1px #00CCFF Glowing Cyan Border)
    local f = CreateFrame("Frame", "GridLockDashboard", UIParent)
    f:SetWidth(640)
    f:SetHeight(460)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    f:SetBackdropColor(0.03, 0.04, 0.06, 0.95)
    f:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.8)

    -- Header Bar
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    header:SetHeight(36)
    header:EnableMouse(true)
    header:SetScript("OnMouseDown", function() f:StartMoving() end)
    header:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(header)
    headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    headerBg:SetVertexColor(0.06, 0.08, 0.12, 0.9)

    -- Brand Icon & Title
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    title:SetPoint("LEFT", header, "LEFT", 12, 0)
    title:SetText("|cFF00CCFFGRIDLOCK|r Dashboard")

    -- Top Action Buttons: Keybind Mode [KB] & Mouseover Picker [PICK]
    local btnKB = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    btnKB:SetWidth(45)
    btnKB:SetHeight(22)
    btnKB:SetPoint("RIGHT", header, "RIGHT", -38, 0)
    btnKB:SetText("[KB]")
    btnKB:SetScript("OnClick", function()
        local Keybind = GridLock:GetModule("Keybind")
        if Keybind then Keybind:Toggle() end
    end)

    local btnPick = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    btnPick:SetWidth(50)
    btnPick:SetHeight(22)
    btnPick:SetPoint("RIGHT", btnKB, "LEFT", -4, 0)
    btnPick:SetText("[PICK]")
    btnPick:SetScript("OnClick", function()
        local Picker = GridLock:GetModule("Picker")
        if Picker then Picker:Toggle() end
    end)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -5, 0)
    closeBtn:SetScript("OnClick", function() Dashboard:Hide() end)

    ---------------------------------------------------------------------------
    -- LEFT COLUMN: Category Registry & Search (Width: 250px)
    ---------------------------------------------------------------------------
    local leftBox = CreateFrame("Frame", nil, f)
    leftBox:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -44)
    leftBox:SetWidth(250)
    leftBox:SetHeight(404)
    leftBox:SetFrameLevel(f:GetFrameLevel() + 5)

    -- Search Bar
    local searchBox = CreateFrame("EditBox", "GridLockDashboardSearch", leftBox, "InputBoxTemplate")
    searchBox:SetWidth(165)
    searchBox:SetHeight(22)
    searchBox:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 5, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("")
    searchBox:SetScript("OnTextChanged", function(selfEdit)
        Dashboard.searchText = selfEdit:GetText()
        if leftBox.scrollFrame then leftBox.scrollFrame:SetVerticalScroll(0) end
        Dashboard:UpdateList()
    end)
    searchBox:SetScript("OnEscapePressed", function(selfEdit) selfEdit:ClearFocus() end)
    leftBox.searchBox = searchBox

    -- Reset All Button
    local resetAllBtn = CreateFrame("Button", nil, leftBox, "UIPanelButtonTemplate")
    resetAllBtn:SetWidth(70)
    resetAllBtn:SetHeight(22)
    resetAllBtn:SetPoint("LEFT", searchBox, "RIGHT", 4, 0)
    resetAllBtn:SetText("Reset All")
    resetAllBtn:SetScript("OnClick", function()
        GridLock:ResetAllFrames()
    end)

    -- Category Pill Tabs (Single clean row of 5 consolidated categories)
    local catFrame = CreateFrame("Frame", nil, leftBox)
    catFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -5, -6)
    catFrame:SetWidth(245)
    catFrame:SetHeight(24)

    local categories = {
        { name = "All", key = "all" },
        { name = "Bars", key = "bars" },
        { name = "Unit", key = "unit" },
        { name = "Map", key = "map" },
        { name = "Misc", key = "misc" },
    }

    self.catButtons = {}
    for i, cat in ipairs(categories) do
        local btn = CreateFrame("Button", nil, catFrame, "UIPanelButtonTemplate")
        btn:SetWidth(47)
        btn:SetHeight(22)
        btn:SetPoint("LEFT", catFrame, "LEFT", (i - 1) * 49, 0)
        btn:SetText(cat.name)
        btn.catKey = cat.key

        btn:SetScript("OnClick", function(selfBtn)
            Dashboard.selectedCategory = selfBtn.catKey
            Dashboard:UpdateCatButtons()
            if leftBox.scrollFrame then leftBox.scrollFrame:SetVerticalScroll(0) end
            Dashboard:UpdateList()
        end)
        self.catButtons[cat.key] = btn
    end

    -- ScrollFrame & Item List Panel
    local scrollFrame = CreateFrame("ScrollFrame", "GridLockDashboardScroll", leftBox, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", catFrame, "BOTTOMLEFT", 0, -6)
    scrollFrame:SetWidth(222)
    scrollFrame:SetHeight(344)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(222)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    leftBox.scrollFrame = scrollFrame
    leftBox.scrollChild = scrollChild

    ---------------------------------------------------------------------------
    -- RIGHT COLUMN: Active Frame Inspector & Guided Empty State (Width: 354px)
    ---------------------------------------------------------------------------
    local rightBox = CreateFrame("Frame", nil, f)
    rightBox:SetPoint("TOPLEFT", leftBox, "TOPRIGHT", 12, 0)
    rightBox:SetWidth(354)
    rightBox:SetHeight(404)
    rightBox:SetFrameLevel(f:GetFrameLevel() + 5)
    f.rightBox = rightBox

    rightBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    rightBox:SetBackdropColor(0.05, 0.07, 0.10, 0.8)
    rightBox:SetBackdropBorderColor(0.15, 0.20, 0.28, 0.8)

    -- 1. GUIDED EMPTY STATE PANEL (Displayed when no frame is selected)
    local emptyPanel = CreateFrame("Frame", nil, rightBox)
    emptyPanel:SetAllPoints(rightBox)

    local emptyIcon = emptyPanel:CreateTexture(nil, "ARTWORK")
    emptyIcon:SetTexture("Interface\\Icons\\ABILITY_SEAL")
    emptyIcon:SetWidth(40)
    emptyIcon:SetHeight(40)
    emptyIcon:SetPoint("TOP", emptyPanel, "TOP", 0, -60)
    emptyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local emptyTitle = emptyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    emptyTitle:SetPoint("TOP", emptyIcon, "BOTTOM", 0, -12)
    emptyTitle:SetText("|cFF00CCFFNo Frame Selected|r")

    local emptyDesc = emptyPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyDesc:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -8)
    emptyDesc:SetWidth(300)
    emptyDesc:SetText("Select any UI frame from the list on the left, or click |cFF00FF99[Pick Frame]|r to hover and click any element on your screen.")

    -- Quick Action Buttons in Empty State
    local btnEmptyPick = CreateFrame("Button", nil, emptyPanel, "UIPanelButtonTemplate")
    btnEmptyPick:SetWidth(140)
    btnEmptyPick:SetHeight(26)
    btnEmptyPick:SetPoint("TOP", emptyDesc, "BOTTOM", 0, -30)
    btnEmptyPick:SetText("Pick Frame [Mouseover]")
    btnEmptyPick:SetScript("OnClick", function()
        local Picker = GridLock:GetModule("Picker")
        if Picker then Picker:Start() end
    end)

    local btnEmptyKB = CreateFrame("Button", nil, emptyPanel, "UIPanelButtonTemplate")
    btnEmptyKB:SetWidth(140)
    btnEmptyKB:SetHeight(26)
    btnEmptyKB:SetPoint("TOP", btnEmptyPick, "BOTTOM", 0, -10)
    btnEmptyKB:SetText("Quick Keybind [/kb]")
    btnEmptyKB:SetScript("OnClick", function()
        local Keybind = GridLock:GetModule("Keybind")
        if Keybind then Keybind:Toggle() end
    end)

    rightBox.emptyPanel = emptyPanel

    -- 2. ACTIVE INSPECTOR PANEL (Displayed when a frame is selected)
    local inspectorPanel = CreateFrame("Frame", nil, rightBox)
    inspectorPanel:SetAllPoints(rightBox)
    inspectorPanel:Hide()

    -- Title & Status Badge
    local frameTitle = inspectorPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    frameTitle:SetPoint("TOPLEFT", inspectorPanel, "TOPLEFT", 12, -12)
    frameTitle:SetText("Frame Inspector")
    inspectorPanel.frameTitle = frameTitle

    local statusBadge = inspectorPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusBadge:SetPoint("LEFT", frameTitle, "RIGHT", 10, 0)
    inspectorPanel.statusBadge = statusBadge

    -- Top Toolbar: Detach, Hide/Show, Reset
    local toolbar = CreateFrame("Frame", nil, inspectorPanel)
    toolbar:SetPoint("TOPLEFT", frameTitle, "BOTTOMLEFT", 0, -8)
    toolbar:SetWidth(330)
    toolbar:SetHeight(24)

    local btnDetach = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    btnDetach:SetWidth(95)
    btnDetach:SetHeight(22)
    btnDetach:SetPoint("LEFT", toolbar, "LEFT", 0, 0)
    btnDetach:SetText("Detach Mover")
    btnDetach:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local Mover = GridLock:GetModule("Mover")
            if Mover then Mover:DetachFromFrame(Dashboard.currentFrameName) end
            Dashboard:SelectFrame(nil)
        end
    end)

    local btnVis = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    btnVis:SetWidth(95)
    btnVis:SetHeight(22)
    btnVis:SetPoint("LEFT", btnDetach, "RIGHT", 8, 0)
    btnVis:SetText("Toggle Hide")
    btnVis:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local Visibility = GridLock:GetModule("Visibility")
            if Visibility then Visibility:ToggleFrame(Dashboard.currentFrameName) end
            Dashboard:UpdateInspector()
            Dashboard:UpdateList()
        end
    end)
    inspectorPanel.btnVis = btnVis

    local btnReset = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    btnReset:SetWidth(85)
    btnReset:SetHeight(22)
    btnReset:SetPoint("LEFT", btnVis, "RIGHT", 8, 0)
    btnReset:SetText("Reset Frame")
    btnReset:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local Position = GridLock:GetModule("Position")
            if Position then Position:ResetPosition(Dashboard.currentFrameName) end
            Dashboard:UpdateInspector()
            Dashboard:UpdateList()
        end
    end)

    -- POSITION & NUDGE CONTROLS CARD
    local posBox = CreateFrame("Frame", nil, inspectorPanel)
    posBox:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -10)
    posBox:SetWidth(330)
    posBox:SetHeight(130)

    posBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    posBox:SetBackdropColor(0.04, 0.05, 0.08, 0.9)
    posBox:SetBackdropBorderColor(0.12, 0.16, 0.22, 0.8)

    local posTitle = posBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    posTitle:SetPoint("TOPLEFT", posBox, "TOPLEFT", 8, -6)
    posTitle:SetText("|cFF00CCFFPOSITION & NUDGE|r")

    -- X EditBox
    local labelX = posBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelX:SetPoint("TOPLEFT", posTitle, "BOTTOMLEFT", 0, -12)
    labelX:SetText("X Pos:")

    local editX = CreateFrame("EditBox", nil, posBox, "InputBoxTemplate")
    editX:SetWidth(60)
    editX:SetHeight(20)
    editX:SetPoint("LEFT", labelX, "RIGHT", 8, 0)
    editX:SetAutoFocus(false)
    editX:SetScript("OnEnterPressed", function(selfEdit)
        selfEdit:ClearFocus()
        local val = tonumber(selfEdit:GetText())
        if val and Dashboard.currentFrameName then
            local Mover = GridLock:GetModule("Mover")
            if Mover then Mover:NudgeFrame(Dashboard.currentFrameName, 0, 0) end
        end
    end)
    inspectorPanel.editX = editX

    -- Y EditBox
    local labelY = posBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelY:SetPoint("TOPLEFT", labelX, "BOTTOMLEFT", 0, -12)
    labelY:SetText("Y Pos:")

    local editY = CreateFrame("EditBox", nil, posBox, "InputBoxTemplate")
    editY:SetWidth(60)
    editY:SetHeight(20)
    editY:SetPoint("LEFT", labelY, "RIGHT", 8, 0)
    editY:SetAutoFocus(false)
    editY:SetScript("OnEnterPressed", function(selfEdit)
        selfEdit:ClearFocus()
        local val = tonumber(selfEdit:GetText())
        if val and Dashboard.currentFrameName then
            local Mover = GridLock:GetModule("Mover")
            if Mover then Mover:NudgeFrame(Dashboard.currentFrameName, 0, 0) end
        end
    end)
    inspectorPanel.editY = editY

    -- 3x3 Cross Nudge Keypad
    local nudgeFrame = CreateFrame("Frame", nil, posBox)
    nudgeFrame:SetPoint("RIGHT", posBox, "RIGHT", -15, -10)
    nudgeFrame:SetWidth(80)
    nudgeFrame:SetHeight(80)

    local nudgeLabel = posBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nudgeLabel:SetPoint("BOTTOM", nudgeFrame, "TOP", 0, 2)
    nudgeLabel:SetText("Shift=10px")

    local function CreateNudgeBtn(text, px, py, dx, dy)
        local btn = CreateFrame("Button", nil, nudgeFrame, "UIPanelButtonTemplate")
        btn:SetWidth(24)
        btn:SetHeight(24)
        btn:SetPoint("CENTER", nudgeFrame, "CENTER", px, py)
        btn:SetText(text)
        btn:SetScript("OnClick", function()
            if Dashboard.currentFrameName then
                local step = IsShiftKeyDown() and 10 or 1
                local Mover = GridLock:GetModule("Mover")
                if Mover then Mover:NudgeFrame(Dashboard.currentFrameName, dx * step, dy * step) end
                Dashboard:UpdateInspector()
            end
        end)
        return btn
    end

    CreateNudgeBtn("^", 0, 24, 0, 1)
    CreateNudgeBtn("<", -24, 0, -1, 0)
    CreateNudgeBtn(">", 24, 0, 1, 0)
    CreateNudgeBtn("v", 0, -24, 0, -1)

    -- SCALE & ALPHA SLIDERS CARD
    local sliderBox = CreateFrame("Frame", nil, inspectorPanel)
    sliderBox:SetPoint("TOPLEFT", posBox, "BOTTOMLEFT", 0, -8)
    sliderBox:SetWidth(330)
    sliderBox:SetHeight(90)

    sliderBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    sliderBox:SetBackdropColor(0.04, 0.05, 0.08, 0.9)
    sliderBox:SetBackdropBorderColor(0.12, 0.16, 0.22, 0.8)

    -- Scale Slider
    local labelScale = sliderBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelScale:SetPoint("TOPLEFT", sliderBox, "TOPLEFT", 8, -8)
    labelScale:SetText("Scale: 100%")
    inspectorPanel.labelScale = labelScale

    local sliderScale = CreateCleanSlider("GridLockScaleSlider", sliderBox, 180, 16, 0.5, 2.0, 0.05)
    sliderScale:SetPoint("LEFT", labelScale, "RIGHT", 12, 0)
    sliderScale:SetScript("OnValueChanged", function(selfSlider, val)
        if Dashboard.updating then return end
        if Dashboard.currentFrameName then
            val = GridLock.Utils.Round(val, 2)
            local frame = _G[Dashboard.currentFrameName]
            if frame and frame.SetScale then frame:SetScale(val) end
            GridLock:SaveFrameScale(Dashboard.currentFrameName, val)
            labelScale:SetText(string.format("Scale: %d%%", math.floor(val * 100 + 0.5)))
        end
    end)
    inspectorPanel.sliderScale = sliderScale

    -- Alpha Slider
    local labelAlpha = sliderBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelAlpha:SetPoint("TOPLEFT", labelScale, "BOTTOMLEFT", 0, -18)
    labelAlpha:SetText("Alpha: 100%")
    inspectorPanel.labelAlpha = labelAlpha

    local sliderAlpha = CreateCleanSlider("GridLockAlphaSlider", sliderBox, 180, 16, 0.1, 1.0, 0.05)
    sliderAlpha:SetPoint("LEFT", labelAlpha, "RIGHT", 12, 0)
    sliderAlpha:SetScript("OnValueChanged", function(selfSlider, val)
        if Dashboard.updating then return end
        if Dashboard.currentFrameName then
            val = GridLock.Utils.Round(val, 2)
            local frame = _G[Dashboard.currentFrameName]
            if frame and frame.SetAlpha then frame:SetAlpha(val) end
            GridLock:SaveFrameAlpha(Dashboard.currentFrameName, val)
            labelAlpha:SetText(string.format("Alpha: %d%%", math.floor(val * 100 + 0.5)))
        end
    end)
    inspectorPanel.sliderAlpha = sliderAlpha

    -- ACTION BAR CUSTOMIZER CARD (Shown when selected frame is an Action Bar)
    local barBox = CreateFrame("Frame", nil, inspectorPanel)
    barBox:SetPoint("TOPLEFT", sliderBox, "BOTTOMLEFT", 0, -8)
    barBox:SetWidth(330)
    barBox:SetHeight(130)
    barBox:Hide()

    barBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    barBox:SetBackdropColor(0.04, 0.05, 0.08, 0.9)
    barBox:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.8)

    local barTitle = barBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    barTitle:SetPoint("TOPLEFT", barBox, "TOPLEFT", 8, -6)
    barTitle:SetText("|cFF00CCFFACTION BAR CUSTOMIZER|r")

    -- Rows & Cols Steppers
    local labelRows = barBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelRows:SetPoint("TOPLEFT", barTitle, "BOTTOMLEFT", 0, -10)
    labelRows:SetText("Rows: 1")
    inspectorPanel.labelRows = labelRows

    local btnRowDec = CreateFrame("Button", nil, barBox, "UIPanelButtonTemplate")
    btnRowDec:SetWidth(20) btnRowDec:SetHeight(20)
    btnRowDec:SetPoint("LEFT", labelRows, "RIGHT", 6, 0)
    btnRowDec:SetText("<")
    btnRowDec:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local BarLayout = GridLock:GetModule("BarLayout")
            local f = _G[Dashboard.currentFrameName]
            local r = math.max(1, (f and f.rows or 1) - 1)
            local c = (f and f.cols or 12)
            if BarLayout then BarLayout:SetBarLayout(f, r, c, f and f.spacing or 2, f and f.padding or 2) end
            Dashboard:UpdateInspector()
        end
    end)

    local btnRowInc = CreateFrame("Button", nil, barBox, "UIPanelButtonTemplate")
    btnRowInc:SetWidth(20) btnRowInc:SetHeight(20)
    btnRowInc:SetPoint("LEFT", btnRowDec, "RIGHT", 2, 0)
    btnRowInc:SetText(">")
    btnRowInc:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local BarLayout = GridLock:GetModule("BarLayout")
            local f = _G[Dashboard.currentFrameName]
            local r = math.min(12, (f and f.rows or 1) + 1)
            local c = (f and f.cols or 12)
            if BarLayout then BarLayout:SetBarLayout(f, r, c, f and f.spacing or 2, f and f.padding or 2) end
            Dashboard:UpdateInspector()
        end
    end)

    -- Checkbutton: Icon Zoom
    local cbZoom = CreateFrame("CheckButton", "GridLockCBZoom", barBox, "UICheckButtonTemplate")
    cbZoom:SetWidth(20) cbZoom:SetHeight(20)
    cbZoom:SetPoint("LEFT", btnRowInc, "RIGHT", 14, 0)
    local cbZoomText = cbZoom:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbZoomText:SetPoint("LEFT", cbZoom, "RIGHT", 2, 0)
    cbZoomText:SetText("Icon Zoom")
    cbZoom:SetScript("OnClick", function(selfCB)
        if Dashboard.currentFrameName then
            GridLock:SetBarIconZoom(_G[Dashboard.currentFrameName], selfCB:GetChecked())
        end
    end)
    inspectorPanel.cbZoom = cbZoom

    -- Checkbutton: Click-Through
    local cbClick = CreateFrame("CheckButton", "GridLockCBClick", barBox, "UICheckButtonTemplate")
    cbClick:SetWidth(20) cbClick:SetHeight(20)
    cbClick:SetPoint("LEFT", cbZoomText, "RIGHT", 10, 0)
    local cbClickText = cbClick:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbClickText:SetPoint("LEFT", cbClick, "RIGHT", 2, 0)
    cbClickText:SetText("Click-Thru")
    cbClick:SetScript("OnClick", function(selfCB)
        if Dashboard.currentFrameName then
            GridLock:SetBarClickThrough(_G[Dashboard.currentFrameName], selfCB:GetChecked())
        end
    end)
    inspectorPanel.cbClick = cbClick

    -- Custom Paging Driver EditBox
    local labelDriver = barBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelDriver:SetPoint("TOPLEFT", labelRows, "BOTTOMLEFT", 0, -14)
    labelDriver:SetText("Paging Driver:")

    local editDriver = CreateFrame("EditBox", nil, barBox, "InputBoxTemplate")
    editDriver:SetWidth(180) editDriver:SetHeight(20)
    editDriver:SetPoint("LEFT", labelDriver, "RIGHT", 6, 0)
    editDriver:SetAutoFocus(false)
    editDriver:SetScript("OnEnterPressed", function(selfEdit)
        selfEdit:ClearFocus()
        if Dashboard.currentFrameName then
            GridLock:SetCustomStateDriver(Dashboard.currentFrameName, selfEdit:GetText())
        end
    end)
    inspectorPanel.editDriver = editDriver

    -- Presets Label & Quick Buttons
    local btnPresetWr = CreateFrame("Button", nil, barBox, "UIPanelButtonTemplate")
    btnPresetWr:SetWidth(50) btnPresetWr:SetHeight(18)
    btnPresetWr:SetPoint("TOPLEFT", labelDriver, "BOTTOMLEFT", 0, -8)
    btnPresetWr:SetText("Warrior")
    btnPresetWr:SetScript("OnClick", function()
        local d = GridLock:GetClassStanceDriver("WARRIOR")
        editDriver:SetText(d)
        if Dashboard.currentFrameName then GridLock:SetCustomStateDriver(Dashboard.currentFrameName, d) end
    end)

    local btnPresetDr = CreateFrame("Button", nil, barBox, "UIPanelButtonTemplate")
    btnPresetDr:SetWidth(50) btnPresetDr:SetHeight(18)
    btnPresetDr:SetPoint("LEFT", btnPresetWr, "RIGHT", 4, 0)
    btnPresetDr:SetText("Druid")
    btnPresetDr:SetScript("OnClick", function()
        local d = GridLock:GetClassStanceDriver("DRUID")
        editDriver:SetText(d)
        if Dashboard.currentFrameName then GridLock:SetCustomStateDriver(Dashboard.currentFrameName, d) end
    end)

    local btnPresetRg = CreateFrame("Button", nil, barBox, "UIPanelButtonTemplate")
    btnPresetRg:SetWidth(50) btnPresetRg:SetHeight(18)
    btnPresetRg:SetPoint("LEFT", btnPresetDr, "RIGHT", 4, 0)
    btnPresetRg:SetText("Rogue")
    btnPresetRg:SetScript("OnClick", function()
        local d = GridLock:GetClassStanceDriver("ROGUE")
        editDriver:SetText(d)
        if Dashboard.currentFrameName then GridLock:SetCustomStateDriver(Dashboard.currentFrameName, d) end
    end)

    inspectorPanel.barBox = barBox
    rightBox.inspectorPanel = inspectorPanel

    self.frame = f
    self:UpdateCatButtons()
    self:UpdateList()
    self:UpdateInspector()

    return f
end

-- Show Master Dashboard
function Dashboard:Show()
    local f = self:CreateFrame()
    f:Show()
    self:UpdateList()
    self:UpdateInspector()
end

-- Hide Master Dashboard
function Dashboard:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Toggle Master Dashboard
function Dashboard:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Update Category Tab Highlights
function Dashboard:UpdateCatButtons()
    for key, btn in pairs(self.catButtons) do
        if key == self.selectedCategory then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end
end

-- Select a Frame in Inspector
function Dashboard:SelectFrame(frameName)
    self.currentFrameName = frameName
    self.currentFrame = frameName and _G[frameName]
    self:UpdateInspector()
    self:UpdateList()
end

-- Update Inspector Pane Controls
function Dashboard:UpdateInspector()
    if not self.frame then return end

    self.updating = true
    local rightBox = self.frame.rightBox or self.frame
    local inspector = rightBox.inspectorPanel
    local empty = rightBox.emptyPanel

    if not self.currentFrameName or not self.currentFrame then
        if inspector then inspector:Hide() end
        if empty then empty:Show() end
        self.updating = false
        return
    end

    if empty then empty:Hide() end
    if inspector then inspector:Show() end

    local frameName = self.currentFrameName
    local frame = self.currentFrame

    -- Display Title
    local displayName = frameName
    local frameInfo = GridLock.FrameData and GridLock.FrameData:GetFrameInfo(frameName)
    if frameInfo then displayName = frameInfo.displayName end
    inspector.frameTitle:SetText("|cFF00CCFF" .. displayName .. "|r")

    -- Status Badges
    local Visibility = GridLock:GetModule("Visibility")
    local isHidden = Visibility and Visibility:IsHidden(frameName)
    local isSaved = GridLock:GetFramePosition(frameName) ~= nil

    if isHidden then
        inspector.statusBadge:SetText("|cFFFF4444[HIDDEN]|r")
        inspector.btnVis:SetText("Show Frame")
    elseif isSaved then
        inspector.statusBadge:SetText("|cFF00FF99[MODIFIED]|r")
        inspector.btnVis:SetText("Toggle Hide")
    else
        inspector.statusBadge:SetText("|cFF888888[DEFAULT]|r")
        inspector.btnVis:SetText("Toggle Hide")
    end

    -- X and Y Positions
    local x, y = GridLock.Utils.GetFrameCenter(frame)
    if x and y then
        inspector.editX:SetText(tostring(math.floor(x + 0.5)))
        inspector.editY:SetText(tostring(math.floor(y + 0.5)))
    else
        inspector.editX:SetText("")
        inspector.editY:SetText("")
    end

    -- Scale & Alpha
    local scale = frame.GetScale and frame:GetScale() or 1.0
    local alpha = frame.GetAlpha and frame:GetAlpha() or 1.0

    inspector.sliderScale:SetValue(scale)
    inspector.labelScale:SetText(string.format("Scale: %d%%", math.floor(scale * 100 + 0.5)))

    inspector.sliderAlpha:SetValue(alpha)
    inspector.labelAlpha:SetText(string.format("Alpha: %d%%", math.floor(alpha * 100 + 0.5)))

    -- Action Bar Customizer Card Visibility & Controls
    local isActionBar = (frameInfo and frameInfo.category == "bars") or frameName:find("ActionBar") or frameName:find("MainMenuBar") or frameName:find("MultiBar")
    if isActionBar and inspector.barBox then
        inspector.barBox:Show()
        local rows = frame.rows or 1
        inspector.labelRows:SetText(string.format("Rows: %d", rows))
        if inspector.cbZoom then inspector.cbZoom:SetChecked(not not frame.iconZoomed) end
        if inspector.cbClick then inspector.cbClick:SetChecked(not not frame.clickThrough) end
        if inspector.editDriver then inspector.editDriver:SetText(frame.customStateDriver or "") end
    elseif inspector.barBox then
        inspector.barBox:Hide()
    end

    self.updating = false
end

-- Update Left Scrollable Frame List
function Dashboard:UpdateList()
    if not self.frame then return end

    local scrollChild = self.frame.leftBox and self.frame.leftBox.scrollChild
    if not scrollChild then return end

    -- Hide existing item buttons
    for _, btn in ipairs(self.buttons) do
        btn:Hide()
    end

    -- Fetch frames by category
    local frames = GridLock.FrameData and GridLock.FrameData:GetFramesByCategory(self.selectedCategory) or {}
    local filtered = {}

    local filterText = (self.searchText or ""):lower():gsub("%s+", "")
    for _, info in ipairs(frames) do
        local nameMatch = info.name:lower():find(filterText, 1, true)
        local displayMatch = info.displayName:lower():find(filterText, 1, true)
        if filterText == "" or nameMatch or displayMatch then
            table.insert(filtered, info)
        end
    end

    local Visibility = GridLock:GetModule("Visibility")
    local rowHeight = 24
    local itemIndex = 0

    for _, info in ipairs(filtered) do
        itemIndex = itemIndex + 1
        local btn = self.buttons[itemIndex]

        if not btn then
            btn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
            btn:SetWidth(215)
            btn:SetHeight(rowHeight)

            local statusTxt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            statusTxt:SetPoint("LEFT", btn, "LEFT", 6, 0)
            btn.statusTxt = statusTxt

            local nameTxt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameTxt:SetPoint("LEFT", statusTxt, "RIGHT", 6, 0)
            btn.nameTxt = nameTxt

            btn:SetScript("OnClick", function(selfBtn)
                if selfBtn.frameName then
                    Dashboard:SelectFrame(selfBtn.frameName)
                end
            end)

            self.buttons[itemIndex] = btn
        end

        btn.frameName = info.name
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(itemIndex - 1) * rowHeight)

        -- Status Indicator
        local isHidden = Visibility and Visibility:IsHidden(info.name)
        local isSaved = GridLock:GetFramePosition(info.name) ~= nil

        if isHidden then
            btn.statusTxt:SetText("|cFFFF4444[HID]|r")
        elseif isSaved then
            btn.statusTxt:SetText("|cFF00FF99[MOD]|r")
        else
            btn.statusTxt:SetText("|cFF666666[VIS]|r")
        end

        btn.nameTxt:SetText(info.displayName)

        -- Selection highlight
        if Dashboard.currentFrameName == info.name then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end

        btn:Show()
    end

    scrollChild:SetHeight(math.max(itemIndex * rowHeight, 1))
end
