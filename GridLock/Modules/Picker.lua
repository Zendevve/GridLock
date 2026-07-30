-- GridLock Picker Module
-- Interactive mouseover frame inspector and selection tool

local GridLock = select(2, ...)

local Picker = {}
GridLock:RegisterModule("Picker", Picker)

Picker.active = false
Picker.highlightFrame = nil
Picker.currentFocus = nil

function Picker:OnInitialize()
    self:CreateHighlightFrame()
end

-- Create highlight frame for targeted UI elements
function Picker:CreateHighlightFrame()
    if self.highlightFrame then return self.highlightFrame end

    local f = CreateFrame("Frame", "GridLockPickerHighlight", UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(999)
    f:Hide()

    -- Border lines using WHITE8X8 for clean 3.3.5a rendering
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    f:SetBackdropColor(1.0, 0.82, 0.0, 0.2)
    f:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)

    -- Info label
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("BOTTOM", f, "TOP", 0, 4)
    label:SetTextColor(1, 1, 1, 1)
    f.label = label

    self.highlightFrame = f
    return f
end

-- Check if frame is a GridLock internal frame that should be ignored
function Picker:IsGridLockFrame(frame)
    if not frame then return true end
    local name = frame:GetName() or ""
    if name:find("^GridLock") then
        return true
    end
    return false
end

-- Start picking mode
function Picker:Start()
    if self.active then return end
    self.active = true

    if not self.highlightFrame then
        self:CreateHighlightFrame()
    end

    -- Create invisible full screen intercept frame to capture clicks
    if not self.clickCatcher then
        local catcher = CreateFrame("Button", "GridLockPickerCatcher", UIParent)
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("TOOLTIP")
        catcher:SetFrameLevel(998)
        catcher:EnableMouse(true)
        catcher:RegisterForClicks("LeftButtonDown", "RightButtonDown")

        catcher:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                Picker:Stop()
            else
                local target = Picker.currentFocus
                Picker:Stop()
                if target and target:GetName() then
                    local frameName = target:GetName()
                    local Mover = GridLock:GetModule("Mover")
                    if Mover then
                        Mover:AttachToFrame(target)
                    end
                    local Dashboard = GridLock:GetModule("Dashboard")
                    if Dashboard then
                        Dashboard:SelectFrame(frameName)
                    end
                end
            end
        end)

        catcher:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
                Picker:Stop()
            else
                if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end
            end
        end)

        self.clickCatcher = catcher
    end

    self.clickCatcher:Show()
    self.clickCatcher:EnableKeyboard(true)

    -- Update loop to trace mouse cursor focus
    self.clickCatcher:SetScript("OnUpdate", function()
        Picker:OnUpdate()
    end)

    GridLock.Utils.Print(GRIDLOCK.PICKER_STARTED or "Frame picker active. Click any UI element to edit (Right-click or ESC to cancel).")
end

-- Stop picking mode
function Picker:Stop()
    if not self.active then return end
    self.active = false

    if self.clickCatcher then
        self.clickCatcher:SetScript("OnUpdate", nil)
        self.clickCatcher:EnableKeyboard(false)
        self.clickCatcher:Hide()
    end

    if self.highlightFrame then
        self.highlightFrame:Hide()
    end

    self.currentFocus = nil
    GridLock.Utils.Print(GRIDLOCK.PICKER_STOPPED or "Frame picker stopped.")
end

-- Toggle picking mode
function Picker:Toggle()
    if self.active then
        self:Stop()
    else
        self:Start()
    end
end

-- Mouse trace update loop (bypasses GridLockPickerCatcher to find target frame)
function Picker:OnUpdate()
    if self.clickCatcher then
        self.clickCatcher:EnableMouse(false)
    end

    local focus = GetMouseFocus()

    if self.clickCatcher then
        self.clickCatcher:EnableMouse(true)
    end

    if focus and focus ~= UIParent and focus ~= WorldFrame then
        local name = focus:GetName()

        -- Trace parent frames if unnamed or to resolve child elements to known main frames
        local curr = focus
        while curr and curr ~= UIParent and curr ~= WorldFrame do
            local currName = curr:GetName()
            if currName and GridLock.FrameData and GridLock.FrameData:IsKnownFrame(currName) then
                focus = curr
                name = currName
                break
            end
            if currName and not name then
                name = currName
            end
            if curr:GetParent() and curr:GetParent() ~= UIParent then
                curr = curr:GetParent()
            else
                break
            end
        end

        if name and not self:IsGridLockFrame(focus) then
            self.currentFocus = focus

            local scale = focus:GetEffectiveScale()
            local w = focus:GetWidth() * scale
            local h = focus:GetHeight() * scale
            local x, y = GridLock.Utils.GetFrameCenter(focus)

            if x and y then
                self.highlightFrame:SetWidth(math.max(w, 20))
                self.highlightFrame:SetHeight(math.max(h, 20))
                self.highlightFrame:ClearAllPoints()
                self.highlightFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

                local displayName = name
                local frameInfo = GridLock.FrameData and GridLock.FrameData:GetFrameInfo(name)
                if frameInfo then
                    displayName = frameInfo.displayName .. " (" .. name .. ")"
                end

                self.highlightFrame.label:SetText(displayName)
                self.highlightFrame:Show()
                return
            end
        end
    end

    self.currentFocus = nil
    self.highlightFrame:Hide()
end

