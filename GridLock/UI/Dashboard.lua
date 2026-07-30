-- GridLock Dashboard Module
-- Master 2-column UI combining Category Frame Registry and Active Frame Inspector

local GridLock = select(2, ...)

local Dashboard = {}
GridLock:RegisterModule("Dashboard", Dashboard)

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

-- Create a clean, reliable slider using OptionsSliderTemplate (3.3.5a compliant)
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

-- Helper for custom glass panel container
local function CreateGlassPanel(name, parent, width, height)
    local panel = CreateFrame("Frame", name, parent)
    panel:SetWidth(width)
    panel:SetHeight(height)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    panel:SetBackdropColor(0.06, 0.08, 0.12, 0.90)
    panel:SetBackdropBorderColor(0.12, 0.18, 0.28, 0.80)
    return panel
end

-- Helper for custom flat styled button
local function CreateCustomButton(name, parent, width, height, text, r, g, b)
    r, g, b = r or 0.0, g or 0.8, b or 1.0
    local btn = CreateFrame("Button", name, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.10, 0.13, 0.20, 0.95)
    btn.bg = bg

    local border = btn:CreateTexture(nil, "BORDER")
    border:SetAllPoints(btn)
    border:SetTexture("Interface\\Buttons\\WHITE8X8")
    border:SetVertexColor(r * 0.4, g * 0.4, b * 0.4, 0.6)
    btn.border = border

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetText(text)
    label:SetTextColor(r, g, b, 1.0)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(0.16, 0.22, 0.32, 1.0)
        self.border:SetVertexColor(r, g, b, 1.0)
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(0.10, 0.13, 0.20, 0.95)
        self.border:SetVertexColor(r * 0.4, g * 0.4, b * 0.4, 0.6)
    end)

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

-- Create master dashboard frame
function Dashboard:CreateFrame()
    if self.frame then return self.frame end

    -- Container Frame
    local f = CreateFrame("Frame", "GridLockDashboard", UIParent)
    f:SetWidth(620)
    f:SetHeight(450)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(50)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)

    -- Glassmorphic Dark Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    f:SetBackdropColor(0.04, 0.05, 0.08, 0.96)
    f:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.7)

    -- Header Drag Bar
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    header:SetHeight(32)
    header:EnableMouse(true)
    header:SetScript("OnMouseDown", function() f:StartMoving() end)
    header:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    title:SetPoint("LEFT", header, "LEFT", 12, 0)
    title:SetText("GRIDLOCK  |cFF00CCFFMaster Dashboard|r")
    title:SetTextColor(1, 1, 1, 1)

    local closeBtn = CreateCustomButton("GridLockDashboardCloseBtn", header, 22, 22, "X", 1, 0.4, 0.4)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Left Box: Frame Registry (Width: 320px)
    local leftBox = CreateGlassPanel("GridLockDashboardLeftBox", f, 320, 400)
    leftBox:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -38)
    f.leftBox = leftBox

    -- Registry Header & Search
    local searchBox = CreateFrame("EditBox", "GridLockDashboardSearch", leftBox, "InputBoxTemplate")
    searchBox:SetWidth(200)
    searchBox:SetHeight(20)
    searchBox:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 12, -10)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        Dashboard.searchText = self:GetText()
        Dashboard:UpdateList()
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Search Placeholder Text
    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 5, 0)
    placeholder:SetText("Search frames...")
    searchBox:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function()
        if searchBox:GetText() == "" then placeholder:Show() end
    end)

    -- Header Reset All Button
    local resetAllBtn = CreateCustomButton("GridLockDashHeaderResetAll", leftBox, 75, 20, "Reset All", 1.0, 0.4, 0.4)
    resetAllBtn:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
    resetAllBtn:SetScript("OnClick", function()
        GridLock:ResetAllFrames()
    end)

    -- Category Tabs Subpanel
    local categories = GridLock.FrameData and GridLock.FrameData.categories or {
        { name = "All", key = "all" }, { name = "Unit", key = "unit" }, { name = "Bars", key = "bars" },
        { name = "Map", key = "map" }, { name = "Raid", key = "raid" }, { name = "Bags", key = "bags" }, { name = "Misc", key = "misc" }
    }

    local catFrame = CreateFrame("Frame", nil, leftBox)
    catFrame:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 10, -36)
    catFrame:SetPoint("TOPRIGHT", leftBox, "TOPRIGHT", -10, -36)
    catFrame:SetHeight(24)

    local catX = 0
    for i, cat in ipairs(categories) do
        local btn = CreateCustomButton(nil, catFrame, 40, 20, cat.name, 0.7, 0.8, 0.9)
        btn:SetPoint("LEFT", catFrame, "LEFT", catX, 0)
        btn.catKey = cat.key

        btn:SetScript("OnClick", function()
            Dashboard.selectedCategory = cat.key
            for _, b in ipairs(Dashboard.catButtons) do
                if b.catKey == cat.key then
                    b.bg:SetVertexColor(0.0, 0.5, 0.4, 1.0)
                    b.label:SetTextColor(0.0, 1.0, 0.6, 1.0)
                else
                    b.bg:SetVertexColor(0.10, 0.13, 0.20, 0.95)
                    b.label:SetTextColor(0.7, 0.8, 0.9, 1.0)
                end
            end
            Dashboard:UpdateList()
        end)

        if cat.key == "all" then
            btn.bg:SetVertexColor(0.0, 0.5, 0.4, 1.0)
            btn.label:SetTextColor(0.0, 1.0, 0.6, 1.0)
        end

        Dashboard.catButtons[i] = btn
        catX = catX + 43
    end

    -- Scroll Frame for Frame Registry List
    local scrollFrame = CreateFrame("ScrollFrame", "GridLockDashboardScrollFrame", leftBox, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 10, -66)
    scrollFrame:SetPoint("BOTTOMRIGHT", leftBox, "BOTTOMRIGHT", -26, 10)
    leftBox.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", "GridLockDashboardScrollChild", scrollFrame)
    scrollChild:SetWidth(280)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    leftBox.scrollChild = scrollChild

    -- Right Box: Active Frame Inspector (Width: 270px)
    local rightBox = CreateGlassPanel("GridLockDashboardRightBox", f, 270, 400)
    rightBox:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -38)
    f.rightBox = rightBox

    -- Inspector Header Title
    local inspectorTitle = rightBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    inspectorTitle:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, -12)
    inspectorTitle:SetText("Select a frame to edit")
    inspectorTitle:SetTextColor(0.0, 1.0, 0.6, 1.0)
    rightBox.inspectorTitle = inspectorTitle

    local yPos = -40

    -- X Position Row
    local xLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    xLabel:SetText("X Center Offset:")

    local xEdit = CreateFrame("EditBox", "GridLockDashXEdit", rightBox, "InputBoxTemplate")
    xEdit:SetWidth(50)
    xEdit:SetHeight(18)
    xEdit:SetPoint("TOPRIGHT", rightBox, "TOPRIGHT", -12, yPos + 2)
    xEdit:SetAutoFocus(false)
    xEdit:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val and Dashboard.currentFrame then
            rightBox.xSlider:SetValue(val)
            Dashboard:OnPositionChanged()
        end
        self:ClearFocus()
    end)
    rightBox.xEdit = xEdit

    yPos = yPos - 22
    local xSlider = CreateCleanSlider("GridLockDashXSlider", rightBox, 240, 16, -1500, 1500, 1)
    xSlider:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    xSlider:SetScript("OnValueChanged", function(self, value)
        if not Dashboard.updating then
            rightBox.xEdit:SetText(GridLock.Utils.Round(value, 0))
            Dashboard:OnPositionChanged()
        end
    end)
    rightBox.xSlider = xSlider

    yPos = yPos - 30

    -- Y Position Row
    local yLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    yLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    yLabel:SetText("Y Center Offset:")

    local yEdit = CreateFrame("EditBox", "GridLockDashYEdit", rightBox, "InputBoxTemplate")
    yEdit:SetWidth(50)
    yEdit:SetHeight(18)
    yEdit:SetPoint("TOPRIGHT", rightBox, "TOPRIGHT", -12, yPos + 2)
    yEdit:SetAutoFocus(false)
    yEdit:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val and Dashboard.currentFrame then
            rightBox.ySlider:SetValue(val)
            Dashboard:OnPositionChanged()
        end
        self:ClearFocus()
    end)
    rightBox.yEdit = yEdit

    yPos = yPos - 22
    local ySlider = CreateCleanSlider("GridLockDashYSlider", rightBox, 240, 16, -1200, 1200, 1)
    ySlider:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    ySlider:SetScript("OnValueChanged", function(self, value)
        if not Dashboard.updating then
            rightBox.yEdit:SetText(GridLock.Utils.Round(value, 0))
            Dashboard:OnPositionChanged()
        end
    end)
    rightBox.ySlider = ySlider

    yPos = yPos - 32

    -- 3x3 Ergonomic Cross Nudge Keypad
    local nudgeLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nudgeLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    nudgeLabel:SetText("Nudge Controls:")

    yPos = yPos - 18
    local keypadFrame = CreateFrame("Frame", nil, rightBox)
    keypadFrame:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    keypadFrame:SetWidth(240)
    keypadFrame:SetHeight(65)

    -- Top: Up
    local upBtn = CreateCustomButton("GridLockNudgeUp", keypadFrame, 42, 18, "^", 0.0, 0.8, 1.0)
    upBtn:SetPoint("TOP", keypadFrame, "TOP", 0, 0)
    upBtn:SetScript("OnClick", function() Dashboard:Nudge(0, 1) end)

    -- Center Row: Left, Reset, Right
    local leftBtn = CreateCustomButton("GridLockNudgeLeft", keypadFrame, 42, 18, "<", 0.0, 0.8, 1.0)
    leftBtn:SetPoint("RIGHT", upBtn, "LEFT", -6, -20)
    leftBtn:SetScript("OnClick", function() Dashboard:Nudge(-1, 0) end)

    local resetPosBtn = CreateCustomButton("GridLockNudgeReset", keypadFrame, 50, 18, "Reset", 1.0, 0.8, 0.2)
    resetPosBtn:SetPoint("CENTER", keypadFrame, "CENTER", 0, -2)
    resetPosBtn:SetScript("OnClick", function() Dashboard:ResetCurrentFrame() end)

    local rightBtn = CreateCustomButton("GridLockNudgeRight", keypadFrame, 42, 18, ">", 0.0, 0.8, 1.0)
    rightBtn:SetPoint("LEFT", upBtn, "RIGHT", 6, -20)
    rightBtn:SetScript("OnClick", function() Dashboard:Nudge(1, 0) end)

    -- Bottom: Down
    local downBtn = CreateCustomButton("GridLockNudgeDown", keypadFrame, 42, 18, "v", 0.0, 0.8, 1.0)
    downBtn:SetPoint("TOP", resetPosBtn, "BOTTOM", 0, -2)
    downBtn:SetScript("OnClick", function() Dashboard:Nudge(0, -1) end)

    yPos = yPos - 72

    -- Scale Row
    local scaleLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    scaleLabel:SetText("Scale:")

    local scaleEdit = CreateFrame("EditBox", "GridLockDashScaleEdit", rightBox, "InputBoxTemplate")
    scaleEdit:SetWidth(50)
    scaleEdit:SetHeight(18)
    scaleEdit:SetPoint("TOPRIGHT", rightBox, "TOPRIGHT", -12, yPos + 2)
    scaleEdit:SetAutoFocus(false)
    scaleEdit:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val and Dashboard.currentFrame then
            val = val > 2 and (val / 100) or val
            rightBox.scaleSlider:SetValue(val)
            Dashboard:OnScaleChanged(val)
        end
        self:ClearFocus()
    end)
    rightBox.scaleEdit = scaleEdit

    yPos = yPos - 20
    local scaleSlider = CreateCleanSlider("GridLockDashScaleSlider", rightBox, 240, 16, 0.50, 2.00, 0.05)
    scaleSlider:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        if not Dashboard.updating then
            rightBox.scaleEdit:SetText(math.floor(value * 100 + 0.5) .. "%")
            Dashboard:OnScaleChanged(value)
        end
    end)
    rightBox.scaleSlider = scaleSlider

    yPos = yPos - 30

    -- Alpha Row
    local alphaLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    alphaLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    alphaLabel:SetText("Opacity / Alpha:")

    local alphaEdit = CreateFrame("EditBox", "GridLockDashAlphaEdit", rightBox, "InputBoxTemplate")
    alphaEdit:SetWidth(50)
    alphaEdit:SetHeight(18)
    alphaEdit:SetPoint("TOPRIGHT", rightBox, "TOPRIGHT", -12, yPos + 2)
    alphaEdit:SetAutoFocus(false)
    alphaEdit:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val and Dashboard.currentFrame then
            val = val > 1 and (val / 100) or val
            rightBox.alphaSlider:SetValue(val)
            Dashboard:OnAlphaChanged(val)
        end
        self:ClearFocus()
    end)
    rightBox.alphaEdit = alphaEdit

    yPos = yPos - 20
    local alphaSlider = CreateCleanSlider("GridLockDashAlphaSlider", rightBox, 240, 16, 0.10, 1.00, 0.05)
    alphaSlider:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    alphaSlider:SetScript("OnValueChanged", function(self, value)
        if not Dashboard.updating then
            rightBox.alphaEdit:SetText(math.floor(value * 100 + 0.5) .. "%")
            Dashboard:OnAlphaChanged(value)
        end
    end)
    rightBox.alphaSlider = alphaSlider

    yPos = yPos - 36

    -- Action Buttons Row
    local pickBtn = CreateCustomButton("GridLockDashPickBtn", rightBox, 75, 22, "Pick", 1.0, 0.8, 0.2)
    pickBtn:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    pickBtn:SetScript("OnClick", function()
        local Picker = GridLock:GetModule("Picker")
        if Picker then Picker:Toggle() end
    end)

    local hideBtn = CreateCustomButton("GridLockDashHideBtn", rightBox, 75, 22, "Hide", 1.0, 0.4, 0.4)
    hideBtn:SetPoint("LEFT", pickBtn, "RIGHT", 6, 0)
    hideBtn:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local Visibility = GridLock:GetModule("Visibility")
            if Visibility then
                Visibility:ToggleFrame(Dashboard.currentFrameName)
                Dashboard:UpdateInspector()
                Dashboard:UpdateList()
            end
        end
    end)
    rightBox.hideBtn = hideBtn

    local detachBtn = CreateCustomButton("GridLockDashDetachBtn", rightBox, 75, 22, "Detach", 0.0, 0.8, 1.0)
    detachBtn:SetPoint("LEFT", hideBtn, "RIGHT", 6, 0)
    detachBtn:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local Mover = GridLock:GetModule("Mover")
            if Mover then
                if Mover:GetMoverForFrame(Dashboard.currentFrameName) then
                    Mover:DetachFromFrame(Dashboard.currentFrameName)
                else
                    local f = _G[Dashboard.currentFrameName]
                    if f then Mover:AttachToFrame(f) end
                end
                Dashboard:UpdateInspector()
            end
        end
    end)
    rightBox.detachBtn = detachBtn

    f:Hide()
    self.frame = f
    return f
end

-- Create entry item in left box list
function Dashboard:CreateButton(parent, id)
    local btn = CreateFrame("Button", "GridLockDashboardItem" .. id, parent)
    btn:SetWidth(270)
    btn:SetHeight(22)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.08, 0.10, 0.15, 0.6)
    btn.bg = bg

    -- Status Pill Badge ([MOD], [HID], [VIS])
    local badge = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badge:SetPoint("LEFT", btn, "LEFT", 6, 0)
    badge:SetText("[VIS]")
    badge:SetTextColor(0.5, 0.6, 0.7, 1.0)
    btn.badge = badge

    -- Name Label
    local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", badge, "RIGHT", 6, 0)
    nameText:SetPoint("RIGHT", btn, "RIGHT", -55, 0)
    nameText:SetJustifyH("LEFT")
    btn.nameText = nameText

    -- Inline Quick Action Button
    local hideBtn = CreateCustomButton(nil, btn, 45, 16, "Hide", 0.7, 0.8, 0.9)
    hideBtn:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    hideBtn:SetScript("OnClick", function()
        if btn.frameName then
            local Visibility = GridLock:GetModule("Visibility")
            if Visibility then
                Visibility:ToggleFrame(btn.frameName)
                Dashboard:UpdateList()
                if Dashboard.currentFrameName == btn.frameName then
                    Dashboard:UpdateInspector()
                end
            end
        end
    end)
    btn.hideBtn = hideBtn

    btn:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(0.15, 0.22, 0.32, 0.9)
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(0.08, 0.10, 0.15, 0.6)
    end)

    btn:SetScript("OnClick", function()
        if btn.frameName then
            Dashboard:SelectFrame(btn.frameName)
        end
    end)

    return btn
end

-- Update frame registry list
function Dashboard:UpdateList()
    if not self.frame then return end

    local scrollChild = self.frame.leftBox.scrollChild
    local scrollFrame = self.frame.leftBox.scrollFrame
    local search = string.lower(self.searchText or "")

    local frames = {}
    if GridLock.FrameData then
        frames = GridLock.FrameData:GetFramesByCategory(self.selectedCategory)
    end

    local displayFrames = {}
    for _, frameInfo in ipairs(frames) do
        local matches = true

        if search ~= "" then
            local nMatch = string.find(string.lower(frameInfo.name), search, 1, true)
            local dMatch = string.find(string.lower(frameInfo.displayName), search, 1, true)
            matches = nMatch or dMatch
        end

        if matches then
            table.insert(displayFrames, frameInfo)
        end
    end

    local itemHeight = 24
    local yOffset = 0
    local Position = GridLock:GetModule("Position")
    local Visibility = GridLock:GetModule("Visibility")

    for i, frameInfo in ipairs(displayFrames) do
        local btn = self.buttons[i]
        if not btn then
            btn = self:CreateButton(scrollChild, i)
            self.buttons[i] = btn
        end

        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        btn:Show()

        btn.frameName = frameInfo.name
        btn.nameText:SetText(frameInfo.displayName)

        if Visibility and Visibility:IsHidden(frameInfo.name) then
            btn.badge:SetText("[HID]")
            btn.badge:SetTextColor(1.0, 0.3, 0.3, 1.0)
            btn.hideBtn:SetButtonText("Show")
        elseif Position and Position:IsModified(frameInfo.name) then
            btn.badge:SetText("[MOD]")
            btn.badge:SetTextColor(0.0, 1.0, 0.6, 1.0)
            btn.hideBtn:SetButtonText("Hide")
        else
            btn.badge:SetText("[VIS]")
            btn.badge:SetTextColor(0.5, 0.6, 0.7, 1.0)
            btn.hideBtn:SetButtonText("Hide")
        end

        yOffset = yOffset + itemHeight
    end

    for i = #displayFrames + 1, #self.buttons do
        self.buttons[i]:Hide()
    end

    if scrollChild then
        scrollChild:SetHeight(math.max(yOffset, 1))
    end
    if scrollFrame and scrollFrame.UpdateScrollChildRect then
        scrollFrame:UpdateScrollChildRect()
    end
end

-- Select and inspect frame
function Dashboard:SelectFrame(frameName)
    local frame = _G[frameName]
    if not frame then return end

    if not self.frame then
        self:CreateFrame()
    end

    local Mover = GridLock:GetModule("Mover")
    if Mover then
        Mover:DetachAll()
        self.currentMover = Mover:AttachToFrame(frame)
    end

    self.currentFrame = frame
    self.currentFrameName = frameName

    local frameInfo = GridLock.FrameData and GridLock.FrameData:GetFrameInfo(frameName)
    local catName = frameInfo and GridLock.FrameData:GetCategoryName(frameInfo.category) or "Misc"
    local displayName = frameInfo and frameInfo.displayName or frameName
    self.frame.rightBox.inspectorTitle:SetText(displayName .. " [" .. catName .. "]")

    self:UpdateInspector()
    self.frame:Show()
end

-- Update Inspector inputs and sliders
function Dashboard:UpdateInspector()
    if not self.currentFrame or not self.frame then return end

    self.updating = true
    local rb = self.frame.rightBox

    local x, y = GridLock.Utils.GetFrameCenter(self.currentFrame)
    if x and y then
        local roundedX = GridLock.Utils.Round(x, 0)
        local roundedY = GridLock.Utils.Round(y, 0)
        rb.xSlider:SetValue(roundedX)
        rb.ySlider:SetValue(roundedY)
        rb.xEdit:SetText(roundedX)
        rb.yEdit:SetText(roundedY)
    end

    local scaleVal = self.currentFrame:GetScale() or 1.0
    rb.scaleSlider:SetValue(GridLock.Utils.Round(scaleVal, 2))
    rb.scaleEdit:SetText(math.floor(scaleVal * 100 + 0.5) .. "%")

    local alphaVal = self.currentFrame:GetAlpha() or 1.0
    rb.alphaSlider:SetValue(GridLock.Utils.Round(alphaVal, 2))
    rb.alphaEdit:SetText(math.floor(alphaVal * 100 + 0.5) .. "%")

    if self.currentFrameName then
        local Visibility = GridLock:GetModule("Visibility")
        if Visibility and Visibility:IsHidden(self.currentFrameName) then
            rb.hideBtn:SetButtonText("Show")
        else
            rb.hideBtn:SetButtonText("Hide")
        end

        local Mover = GridLock:GetModule("Mover")
        if Mover and Mover:GetMoverForFrame(self.currentFrameName) then
            rb.detachBtn:SetButtonText("Detach")
        else
            rb.detachBtn:SetButtonText("Attach")
        end
    end

    self.updating = false
end

-- Handle position change from sliders/edits
function Dashboard:OnPositionChanged()
    if not self.currentFrame or not self.frame then return end

    local rb = self.frame.rightBox
    local x = rb.xSlider:GetValue()
    local y = rb.ySlider:GetValue()

    if GridLock.db and GridLock.db.snapEnabled then
        local Snap = GridLock:GetModule("Snap")
        if Snap then
            x, y = Snap:CalculateSnappedPosition(x, y, GridLock.db.gridSize)
        end
    end

    rb.xEdit:SetText(GridLock.Utils.Round(x, 0))
    rb.yEdit:SetText(GridLock.Utils.Round(y, 0))

    local scale = self.currentFrame:GetEffectiveScale()
    local clearFunc = self.currentFrame.GridLockOriginalClearAllPoints or self.currentFrame.ClearAllPoints
    local setFunc = self.currentFrame.GridLockOriginalSetPoint or self.currentFrame.SetPoint

    clearFunc(self.currentFrame)
    setFunc(self.currentFrame, "CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

    if self.currentMover then
        local Mover = GridLock:GetModule("Mover")
        if Mover then Mover:UpdateMoverPosition(self.currentMover) end
    end
end

-- Handle scale change
function Dashboard:OnScaleChanged(val)
    if not self.currentFrame or not self.frame then return end

    val = math.min(2.0, math.max(0.5, val))
    self.currentFrame:SetScale(val)

    GridLock:SaveFrameScale(self.currentFrameName, val)

    if self.currentMover then
        local Mover = GridLock:GetModule("Mover")
        if Mover then Mover:UpdateMoverPosition(self.currentMover) end
    end
end

-- Handle alpha change
function Dashboard:OnAlphaChanged(val)
    if not self.currentFrame or not self.frame then return end

    val = math.min(1.0, math.max(0.0, val))
    self.currentFrame:SetAlpha(val)

    GridLock:SaveFrameAlpha(self.currentFrameName, val)
end

-- Nudge position by dx, dy
function Dashboard:Nudge(dx, dy)
    if not self.currentFrameName then return end

    local Mover = GridLock:GetModule("Mover")
    if Mover then
        Mover:NudgeFrame(self.currentFrameName, dx, dy)
        self:UpdateInspector()
    end
end

-- Reset selected frame
function Dashboard:ResetCurrentFrame()
    if not self.currentFrameName then return end

    local Position = GridLock:GetModule("Position")
    if Position then
        Position:ResetPosition(self.currentFrameName)
    end

    local Mover = GridLock:GetModule("Mover")
    if Mover then
        Mover:DetachFromFrame(self.currentFrameName)
    end

    self:UpdateInspector()
    self:UpdateList()
end

-- Show Dashboard
function Dashboard:Show()
    if not self.frame then
        self:CreateFrame()
    end
    self.frame:Show()
    self:UpdateList()
end

-- Hide Dashboard
function Dashboard:Hide()
    if self.frame then
        self.frame:Hide()
    end

    if self.currentFrameName and self.currentFrame then
        local Position = GridLock:GetModule("Position")
        if Position then
            Position:SavePosition(self.currentFrameName, self.currentFrame)
        end
    end
end

-- Toggle Dashboard
function Dashboard:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
