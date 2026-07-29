-- ZenAlign Dashboard Module
-- Master 2-column UI combining Category Frame Registry and Active Frame Inspector

local ZenAlign = select(2, ...)

local Dashboard = {}
ZenAlign:RegisterModule("Dashboard", Dashboard)

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

-- Create master dashboard frame
function Dashboard:CreateFrame()
    if self.frame then return self.frame end

    -- Container Frame
    local f = CreateFrame("Frame", "ZenAlignDashboard", UIParent)
    f:SetWidth(600)
    f:SetHeight(440)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(50)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)

    -- Backdrop styling
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Title Header Texture
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetPoint("TOP", f, "TOP", 0, 12)
    titleBg:SetWidth(320)
    titleBg:SetHeight(64)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -4)
    title:SetText("ZenAlign Dashboard")

    -- Drag Header Region (stops before close button, frame level 50)
    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    drag:SetPoint("TOPRIGHT", f, "TOPRIGHT", -35, 0)
    drag:SetHeight(32)
    drag:EnableMouse(true)
    drag:SetFrameLevel(f:GetFrameLevel())
    drag:SetScript("OnMouseDown", function() f:StartMoving() end)
    drag:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    -- Close Button (elevated above drag header)
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeBtn:SetFrameLevel(f:GetFrameLevel() + 20)
    closeBtn:SetScript("OnClick", function() Dashboard:Hide() end)

    ---------------------------------------------------------------------------
    -- LEFT COLUMN: Category Registry & Filter (Width: 265px)
    ---------------------------------------------------------------------------
    local leftBox = CreateFrame("Frame", nil, f)
    leftBox:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -35)
    leftBox:SetWidth(265)
    leftBox:SetHeight(385)
    leftBox:SetFrameLevel(f:GetFrameLevel() + 5)

    -- Search EditBox
    local searchBox = CreateFrame("EditBox", "ZenAlignDashboardSearch", leftBox, "InputBoxTemplate")
    searchBox:SetWidth(170)
    searchBox:SetHeight(20)
    searchBox:SetPoint("TOPLEFT", leftBox, "TOPLEFT", 5, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("")
    searchBox:SetScript("OnTextChanged", function(self)
        Dashboard.searchText = self:GetText()
        if leftBox.scrollFrame then
            leftBox.scrollFrame:SetVerticalScroll(0)
        end
        Dashboard:UpdateList()
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    leftBox.searchBox = searchBox

    -- Reset All Button
    local resetAllBtn = CreateFrame("Button", nil, leftBox, "UIPanelButtonTemplate")
    resetAllBtn:SetWidth(72)
    resetAllBtn:SetHeight(20)
    resetAllBtn:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
    resetAllBtn:SetText("Reset All")
    resetAllBtn:SetFrameLevel(leftBox:GetFrameLevel() + 2)
    resetAllBtn:SetScript("OnClick", function()
        ZenAlign:ResetAllFrames()
    end)
    leftBox.resetAllBtn = resetAllBtn

    -- Category Filters Container (2 rows of 4 buttons)
    local catFrame = CreateFrame("Frame", nil, leftBox)
    catFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -5, -4)
    catFrame:SetWidth(255)
    catFrame:SetHeight(44)
    catFrame:SetFrameLevel(leftBox:GetFrameLevel() + 2)

    local categories = ZenAlign.FrameData and ZenAlign.FrameData.categories or {
        { name = "All", key = "all" },
        { name = "Unit", key = "unit" },
        { name = "Bars", key = "bars" },
        { name = "Map", key = "map" },
        { name = "Raid", key = "raid" },
        { name = "PvP", key = "pvp" },
        { name = "Bags", key = "bags" },
        { name = "Misc", key = "misc" },
    }

    self.catButtons = {}
    for i, cat in ipairs(categories) do
        local btn = CreateFrame("Button", nil, catFrame, "UIPanelButtonTemplate")
        btn:SetWidth(60)
        btn:SetHeight(20)

        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        btn:SetPoint("TOPLEFT", catFrame, "TOPLEFT", col * 63, -row * 22)
        btn:SetText(cat.name)
        btn.categoryKey = cat.key
        btn:SetFrameLevel(catFrame:GetFrameLevel() + 2)

        btn:SetScript("OnClick", function()
            Dashboard:SelectCategory(cat.key)
        end)

        table.insert(self.catButtons, btn)
    end

    -- Scroll Frame for Registered WoW Frames List
    local scrollFrame = CreateFrame("ScrollFrame", "ZenAlignDashboardScrollFrame", leftBox, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", catFrame, "BOTTOMLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", leftBox, "BOTTOMRIGHT", -22, 5)
    scrollFrame:SetFrameLevel(leftBox:GetFrameLevel() + 5)

    local scrollChild = CreateFrame("Frame", "ZenAlignDashboardScrollChild", scrollFrame)
    scrollChild:SetWidth(235)
    scrollChild:SetHeight(300)
    scrollFrame:SetScrollChild(scrollChild)
    leftBox.scrollChild = scrollChild
    leftBox.scrollFrame = scrollFrame
    f.leftBox = leftBox

    ---------------------------------------------------------------------------
    -- RIGHT COLUMN: Active Frame Inspector (Width: 290px)
    ---------------------------------------------------------------------------
    local rightBox = CreateFrame("Frame", nil, f)
    rightBox:SetPoint("TOPRIGHT", f, "TOPRIGHT", -15, -35)
    rightBox:SetWidth(290)
    rightBox:SetHeight(385)
    rightBox:SetFrameLevel(f:GetFrameLevel() + 5)

    -- Right Panel Dark Glass Backdrop
    rightBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    rightBox:SetBackdropColor(0.1, 0.1, 0.12, 0.7)

    -- Active Frame Header Label (Name and Category)
    local inspectorTitle = rightBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    inspectorTitle:SetPoint("TOP", rightBox, "TOP", 0, -10)
    inspectorTitle:SetText("No Frame Selected")
    rightBox.inspectorTitle = inspectorTitle

    local yPos = -35

    -- X POSITION: Label, EditBox, Slider
    local xLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    xLabel:SetText("X Pos:")

    local xEdit = CreateFrame("EditBox", "ZenAlignDashXEdit", rightBox, "InputBoxTemplate")
    xEdit:SetWidth(50)
    xEdit:SetHeight(18)
    xEdit:SetPoint("LEFT", xLabel, "RIGHT", 10, 0)
    xEdit:SetAutoFocus(false)

    local function CommitXEdit(self)
        local val = tonumber(self:GetText())
        if val and Dashboard.currentFrame then
            rightBox.xSlider:SetValue(val)
            Dashboard:OnPositionChanged()
        elseif Dashboard.currentFrame then
            local x, _ = ZenAlign.Utils.GetFrameCenter(Dashboard.currentFrame)
            if x then self:SetText(ZenAlign.Utils.Round(x, 0)) end
        end
    end
    xEdit:SetScript("OnEnterPressed", function(self) CommitXEdit(self); self:ClearFocus() end)
    xEdit:SetScript("OnTabPressed", function(self) CommitXEdit(self); self:ClearFocus() end)
    xEdit:SetScript("OnEditFocusLost", function(self) CommitXEdit(self) end)
    rightBox.xEdit = xEdit

    local xSlider = CreateCleanSlider("ZenAlignDashXSlider", rightBox, 135, 17, -2000, 2000, 1)
    xSlider:SetPoint("LEFT", xEdit, "RIGHT", 8, 0)
    xSlider:SetScript("OnValueChanged", function(self, value)
        if Dashboard.updating then return end
        rightBox.xEdit:SetText(ZenAlign.Utils.Round(value, 0))
        Dashboard:OnPositionChanged()
    end)
    rightBox.xSlider = xSlider

    yPos = yPos - 28

    -- Y POSITION: Label, EditBox, Slider
    local yLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    yLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    yLabel:SetText("Y Pos:")

    local yEdit = CreateFrame("EditBox", "ZenAlignDashYEdit", rightBox, "InputBoxTemplate")
    yEdit:SetWidth(50)
    yEdit:SetHeight(18)
    yEdit:SetPoint("LEFT", yLabel, "RIGHT", 10, 0)
    yEdit:SetAutoFocus(false)

    local function CommitYEdit(self)
        local val = tonumber(self:GetText())
        if val and Dashboard.currentFrame then
            rightBox.ySlider:SetValue(val)
            Dashboard:OnPositionChanged()
        elseif Dashboard.currentFrame then
            local _, y = ZenAlign.Utils.GetFrameCenter(Dashboard.currentFrame)
            if y then self:SetText(ZenAlign.Utils.Round(y, 0)) end
        end
    end
    yEdit:SetScript("OnEnterPressed", function(self) CommitYEdit(self); self:ClearFocus() end)
    yEdit:SetScript("OnTabPressed", function(self) CommitYEdit(self); self:ClearFocus() end)
    yEdit:SetScript("OnEditFocusLost", function(self) CommitYEdit(self) end)
    rightBox.yEdit = yEdit

    local ySlider = CreateCleanSlider("ZenAlignDashYSlider", rightBox, 135, 17, -2000, 2000, 1)
    ySlider:SetPoint("LEFT", yEdit, "RIGHT", 8, 0)
    ySlider:SetScript("OnValueChanged", function(self, value)
        if Dashboard.updating then return end
        rightBox.yEdit:SetText(ZenAlign.Utils.Round(value, 0))
        Dashboard:OnPositionChanged()
    end)
    rightBox.ySlider = ySlider

    yPos = yPos - 30

    -- SCALE %: Label, EditBox, Slider (50% - 200%)
    local scaleLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    scaleLabel:SetText("Scale %:")

    local scaleEdit = CreateFrame("EditBox", "ZenAlignDashScaleEdit", rightBox, "InputBoxTemplate")
    scaleEdit:SetWidth(45)
    scaleEdit:SetHeight(18)
    scaleEdit:SetPoint("LEFT", scaleLabel, "RIGHT", 5, 0)
    scaleEdit:SetAutoFocus(false)

    local function CommitScaleEdit(self)
        local text = self:GetText():gsub("%%", "")
        local val = tonumber(text)
        if val and Dashboard.currentFrame then
            local scaleVal = val / 100
            rightBox.scaleSlider:SetValue(scaleVal)
            Dashboard:OnScaleChanged(scaleVal)
        elseif Dashboard.currentFrame then
            local scaleVal = Dashboard.currentFrame:GetScale() or 1.0
            self:SetText(math.floor(scaleVal * 100 + 0.5) .. "%")
        end
    end
    scaleEdit:SetScript("OnEnterPressed", function(self) CommitScaleEdit(self); self:ClearFocus() end)
    scaleEdit:SetScript("OnTabPressed", function(self) CommitScaleEdit(self); self:ClearFocus() end)
    scaleEdit:SetScript("OnEditFocusLost", function(self) CommitScaleEdit(self) end)
    rightBox.scaleEdit = scaleEdit

    local scaleSlider = CreateCleanSlider("ZenAlignDashScaleSlider", rightBox, 135, 17, 0.50, 2.00, 0.05)
    scaleSlider:SetPoint("LEFT", scaleEdit, "RIGHT", 8, 0)
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        if Dashboard.updating then return end
        rightBox.scaleEdit:SetText(math.floor(value * 100 + 0.5) .. "%")
        Dashboard:OnScaleChanged(value)
    end)
    rightBox.scaleSlider = scaleSlider

    yPos = yPos - 28

    -- ALPHA %: Label, EditBox, Slider (0% - 100%)
    local alphaLabel = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    alphaLabel:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    alphaLabel:SetText("Alpha %:")

    local alphaEdit = CreateFrame("EditBox", "ZenAlignDashAlphaEdit", rightBox, "InputBoxTemplate")
    alphaEdit:SetWidth(45)
    alphaEdit:SetHeight(18)
    alphaEdit:SetPoint("LEFT", alphaLabel, "RIGHT", 5, 0)
    alphaEdit:SetAutoFocus(false)

    local function CommitAlphaEdit(self)
        local text = self:GetText():gsub("%%", "")
        local val = tonumber(text)
        if val and Dashboard.currentFrame then
            local alphaVal = math.min(1.0, math.max(0.10, val / 100))
            rightBox.alphaSlider:SetValue(alphaVal)
            Dashboard:OnAlphaChanged(alphaVal)
            self:SetText(math.floor(alphaVal * 100 + 0.5) .. "%")
        elseif Dashboard.currentFrame then
            local alphaVal = Dashboard.currentFrame:GetAlpha() or 1.0
            if alphaVal < 0.10 then alphaVal = 1.0 end
            self:SetText(math.floor(alphaVal * 100 + 0.5) .. "%")
        end
    end
    alphaEdit:SetScript("OnEnterPressed", function(self) CommitAlphaEdit(self); self:ClearFocus() end)
    alphaEdit:SetScript("OnTabPressed", function(self) CommitAlphaEdit(self); self:ClearFocus() end)
    alphaEdit:SetScript("OnEditFocusLost", function(self) CommitAlphaEdit(self) end)
    rightBox.alphaEdit = alphaEdit

    local alphaSlider = CreateCleanSlider("ZenAlignDashAlphaSlider", rightBox, 135, 17, 0.10, 1.00, 0.05)
    alphaSlider:SetPoint("LEFT", alphaEdit, "RIGHT", 8, 0)
    alphaSlider:SetScript("OnValueChanged", function(self, value)
        if Dashboard.updating then return end
        rightBox.alphaEdit:SetText(math.floor(value * 100 + 0.5) .. "%")
        Dashboard:OnAlphaChanged(value)
    end)
    rightBox.alphaSlider = alphaSlider

    yPos = yPos - 35

    -- 4-WAY ASCII PIXEL NUDGE PAD
    local nudgeTitle = rightBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nudgeTitle:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 12, yPos)
    nudgeTitle:SetText("Pixel Nudge (Shift = 10px):")

    local nudgePad = CreateFrame("Frame", nil, rightBox)
    nudgePad:SetWidth(90)
    nudgePad:SetHeight(55)
    nudgePad:SetPoint("TOPLEFT", rightBox, "TOPLEFT", 175, yPos + 10)

    local btnUp = CreateFrame("Button", nil, nudgePad, "UIPanelButtonTemplate")
    btnUp:SetWidth(24)
    btnUp:SetHeight(20)
    btnUp:SetPoint("TOP", nudgePad, "TOP", 0, 0)
    btnUp:SetText("^")
    btnUp:SetFrameLevel(rightBox:GetFrameLevel() + 10)
    btnUp:SetScript("OnClick", function()
        local step = IsShiftKeyDown() and 10 or 1
        Dashboard:Nudge(0, step)
    end)

    local btnDown = CreateFrame("Button", nil, nudgePad, "UIPanelButtonTemplate")
    btnDown:SetWidth(24)
    btnDown:SetHeight(20)
    btnDown:SetPoint("BOTTOM", nudgePad, "BOTTOM", 0, 0)
    btnDown:SetText("v")
    btnDown:SetFrameLevel(rightBox:GetFrameLevel() + 10)
    btnDown:SetScript("OnClick", function()
        local step = IsShiftKeyDown() and 10 or 1
        Dashboard:Nudge(0, -step)
    end)

    local btnLeft = CreateFrame("Button", nil, nudgePad, "UIPanelButtonTemplate")
    btnLeft:SetWidth(24)
    btnLeft:SetHeight(20)
    btnLeft:SetPoint("LEFT", nudgePad, "LEFT", 0, 0)
    btnLeft:SetText("<")
    btnLeft:SetFrameLevel(rightBox:GetFrameLevel() + 10)
    btnLeft:SetScript("OnClick", function()
        local step = IsShiftKeyDown() and 10 or 1
        Dashboard:Nudge(-step, 0)
    end)

    local btnRight = CreateFrame("Button", nil, nudgePad, "UIPanelButtonTemplate")
    btnRight:SetWidth(24)
    btnRight:SetHeight(20)
    btnRight:SetPoint("RIGHT", nudgePad, "RIGHT", 0, 0)
    btnRight:SetText(">")
    btnRight:SetFrameLevel(rightBox:GetFrameLevel() + 10)
    btnRight:SetScript("OnClick", function()
        local step = IsShiftKeyDown() and 10 or 1
        Dashboard:Nudge(step, 0)
    end)

    -- Bottom Action Buttons (Elevated frame level)
    local pickBtn = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    pickBtn:SetWidth(64)
    pickBtn:SetHeight(22)
    pickBtn:SetPoint("BOTTOMLEFT", rightBox, "BOTTOMLEFT", 8, 10)
    pickBtn:SetText("Pick Frame")
    pickBtn:SetFrameLevel(rightBox:GetFrameLevel() + 10)
    pickBtn:SetScript("OnClick", function()
        local Picker = ZenAlign:GetModule("Picker")
        if Picker then Picker:Start() end
    end)

    local resetBtn = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    resetBtn:SetWidth(64)
    resetBtn:SetHeight(22)
    resetBtn:SetPoint("LEFT", pickBtn, "RIGHT", 4, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetFrameLevel(rightBox:GetFrameLevel() + 10)
    resetBtn:SetScript("OnClick", function()
        Dashboard:ResetCurrentFrame()
    end)

    local detachBtn = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    detachBtn:SetWidth(64)
    detachBtn:SetHeight(22)
    detachBtn:SetPoint("LEFT", resetBtn, "RIGHT", 4, 0)
    detachBtn:SetText("Detach")
    detachBtn:SetFrameLevel(rightBox:GetFrameLevel() + 10)
    detachBtn:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local Mover = ZenAlign:GetModule("Mover")
            if Mover then
                if Mover:GetMoverForFrame(Dashboard.currentFrameName) then
                    Mover:DetachFromFrame(Dashboard.currentFrameName)
                else
                    local target = _G[Dashboard.currentFrameName]
                    if target then Mover:AttachToFrame(target) end
                end
                Dashboard:UpdateInspector()
            end
        end
    end)
    rightBox.detachBtn = detachBtn

    local hideBtn = CreateFrame("Button", nil, rightBox, "UIPanelButtonTemplate")
    hideBtn:SetWidth(64)
    hideBtn:SetHeight(22)
    hideBtn:SetPoint("LEFT", detachBtn, "RIGHT", 4, 0)
    hideBtn:SetText("Hide")
    hideBtn:SetFrameLevel(rightBox:GetFrameLevel() + 10)
    hideBtn:SetScript("OnClick", function()
        if Dashboard.currentFrameName then
            local Visibility = ZenAlign:GetModule("Visibility")
            if Visibility then
                Visibility:ToggleFrame(Dashboard.currentFrameName)
                Dashboard:UpdateInspector()
                Dashboard:UpdateList()
            end
        end
    end)
    rightBox.hideBtn = hideBtn

    f.rightBox = rightBox
    f:Hide()
    self.frame = f

    self:SelectCategory("all")
    return f
end

-- Select category and update active pill highlight
function Dashboard:SelectCategory(categoryKey)
    self.selectedCategory = categoryKey or "all"

    -- Highlight active category pill
    for _, btn in ipairs(self.catButtons) do
        local fontString = btn:GetFontString()
        if btn.categoryKey == self.selectedCategory then
            if fontString then
                fontString:SetTextColor(1, 0.82, 0, 1) -- Gold highlight for active pill
            end
        else
            if fontString then
                fontString:SetTextColor(1, 1, 1, 1)
            end
        end
    end

    -- Reset scroll position whenever category pill changes
    if self.frame and self.frame.leftBox and self.frame.leftBox.scrollFrame then
        self.frame.leftBox.scrollFrame:SetVerticalScroll(0)
    end

    self:UpdateList()
end

-- Create list item button for left panel registry
function Dashboard:CreateButton(parent, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(225)
    btn:SetHeight(22)
    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.12, 0.12, 0.15, 0.6)
    btn.bg = bg

    -- Status indicator badge
    local badge = btn:CreateTexture(nil, "OVERLAY")
    badge:SetWidth(10)
    badge:SetHeight(10)
    badge:SetPoint("LEFT", btn, "LEFT", 4, 0)
    badge:SetTexture("Interface\\Buttons\\WHITE8X8")
    btn.badge = badge

    -- Name label
    local name = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", badge, "RIGHT", 4, 0)
    name:SetJustifyH("LEFT")
    name:SetWidth(110)
    btn.nameText = name

    -- Inline action edit button
    local editBtn = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
    editBtn:SetWidth(34)
    editBtn:SetHeight(18)
    editBtn:SetPoint("RIGHT", btn, "RIGHT", -38, 0)
    editBtn:SetText("Edit")
    editBtn:SetScript("OnClick", function()
        if btn.frameName then
            Dashboard:SelectFrame(btn.frameName)
        end
    end)
    btn.editBtn = editBtn

    -- Inline action hide/show button
    local hideBtn = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
    hideBtn:SetWidth(34)
    hideBtn:SetHeight(18)
    hideBtn:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
    hideBtn:SetText("Hide")
    hideBtn:SetScript("OnClick", function()
        if btn.frameName then
            local Visibility = ZenAlign:GetModule("Visibility")
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
    if ZenAlign.FrameData then
        frames = ZenAlign.FrameData:GetFramesByCategory(self.selectedCategory)
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
    local Position = ZenAlign:GetModule("Position")
    local Visibility = ZenAlign:GetModule("Visibility")

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

        -- Status Badges:
        -- Red badge: Frame hidden
        -- Green badge: Frame position modified
        -- Neutral badge: Default visible frame
        if Visibility and Visibility:IsHidden(frameInfo.name) then
            btn.badge:SetVertexColor(1, 0.2, 0.2, 1) -- Red badge
            btn.hideBtn:SetText("Show")
        elseif Position and Position:IsModified(frameInfo.name) then
            btn.badge:SetVertexColor(0, 1, 0.5, 1) -- Green badge
            btn.hideBtn:SetText("Hide")
        else
            btn.badge:SetVertexColor(0.5, 0.5, 0.5, 0.5) -- Neutral badge
            btn.hideBtn:SetText("Hide")
        end

        yOffset = yOffset + itemHeight
    end

    for i = #displayFrames + 1, #self.buttons do
        self.buttons[i]:Hide()
    end

    -- Calculate scrollChild height correctly so all items are visible without clipping
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

    local Mover = ZenAlign:GetModule("Mover")
    if Mover then
        Mover:DetachAll()
        self.currentMover = Mover:AttachToFrame(frame)
    end

    self.currentFrame = frame
    self.currentFrameName = frameName

    local frameInfo = ZenAlign.FrameData and ZenAlign.FrameData:GetFrameInfo(frameName)
    local catName = frameInfo and ZenAlign.FrameData:GetCategoryName(frameInfo.category) or "Misc"
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

    local x, y = ZenAlign.Utils.GetFrameCenter(self.currentFrame)
    if x and y then
        local roundedX = ZenAlign.Utils.Round(x, 0)
        local roundedY = ZenAlign.Utils.Round(y, 0)
        rb.xSlider:SetValue(roundedX)
        rb.ySlider:SetValue(roundedY)
        rb.xEdit:SetText(roundedX)
        rb.yEdit:SetText(roundedY)
    end

    local scaleVal = self.currentFrame:GetScale() or 1.0
    rb.scaleSlider:SetValue(ZenAlign.Utils.Round(scaleVal, 2))
    rb.scaleEdit:SetText(math.floor(scaleVal * 100 + 0.5) .. "%")

    local alphaVal = self.currentFrame:GetAlpha() or 1.0
    rb.alphaSlider:SetValue(ZenAlign.Utils.Round(alphaVal, 2))
    rb.alphaEdit:SetText(math.floor(alphaVal * 100 + 0.5) .. "%")

    if self.currentFrameName then
        local Visibility = ZenAlign:GetModule("Visibility")
        if Visibility and Visibility:IsHidden(self.currentFrameName) then
            rb.hideBtn:SetText("Show")
        else
            rb.hideBtn:SetText("Hide")
        end

        local Mover = ZenAlign:GetModule("Mover")
        if Mover and Mover:GetMoverForFrame(self.currentFrameName) then
            rb.detachBtn:SetText("Detach")
        else
            rb.detachBtn:SetText("Attach")
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

    if ZenAlign.db and ZenAlign.db.snapEnabled then
        local Snap = ZenAlign:GetModule("Snap")
        if Snap then
            x, y = Snap:CalculateSnappedPosition(x, y, ZenAlign.db.gridSize)
        end
    end

    rb.xEdit:SetText(ZenAlign.Utils.Round(x, 0))
    rb.yEdit:SetText(ZenAlign.Utils.Round(y, 0))

    local scale = self.currentFrame:GetEffectiveScale()
    local clearFunc = self.currentFrame.ZenAlignOriginalClearAllPoints or self.currentFrame.ClearAllPoints
    local setFunc = self.currentFrame.ZenAlignOriginalSetPoint or self.currentFrame.SetPoint

    clearFunc(self.currentFrame)
    setFunc(self.currentFrame, "CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

    if self.currentMover then
        local Mover = ZenAlign:GetModule("Mover")
        if Mover then Mover:UpdateMoverPosition(self.currentMover) end
    end
end

-- Handle scale change
function Dashboard:OnScaleChanged(val)
    if not self.currentFrame or not self.frame then return end

    val = math.min(2.0, math.max(0.5, val))
    self.currentFrame:SetScale(val)

    ZenAlign:SaveFrameScale(self.currentFrameName, val)

    if self.currentMover then
        local Mover = ZenAlign:GetModule("Mover")
        if Mover then Mover:UpdateMoverPosition(self.currentMover) end
    end
end

-- Handle alpha change
function Dashboard:OnAlphaChanged(val)
    if not self.currentFrame or not self.frame then return end

    val = math.min(1.0, math.max(0.0, val))
    self.currentFrame:SetAlpha(val)

    ZenAlign:SaveFrameAlpha(self.currentFrameName, val)
end

-- Nudge position by dx, dy
function Dashboard:Nudge(dx, dy)
    if not self.currentFrameName then return end

    local Mover = ZenAlign:GetModule("Mover")
    if Mover then
        Mover:NudgeFrame(self.currentFrameName, dx, dy)
        self:UpdateInspector()
    end
end

-- Reset selected frame
function Dashboard:ResetCurrentFrame()
    if not self.currentFrameName then return end

    local Position = ZenAlign:GetModule("Position")
    if Position then
        Position:ResetPosition(self.currentFrameName)
    end

    local Mover = ZenAlign:GetModule("Mover")
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
        local Position = ZenAlign:GetModule("Position")
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
