-- ZenAlign FadeManager Module
-- Multi-State Alpha & Combat Fade Manager
-- Handles per-frame dynamic opacity based on combat state and mouseover with zero-allocation OnUpdate interpolation

local addonName, ZenAlign = ...
local FadeManager = {}
ZenAlign:RegisterModule("FadeManager", FadeManager)

-- Pre-allocated static data structures to prevent GC memory allocations inside OnUpdate
FadeManager.registeredFrames = {}  -- HashMap: keyName -> record
FadeManager.registeredList = {}    -- Contiguous array of records for GC-free numerical iteration
FadeManager.numRegistered = 0

FadeManager.activeAnimations = {}  -- Contiguous array of active fading records
FadeManager.numActive = 0

FadeManager.inCombat = false

function FadeManager:OnInitialize()
    self.inCombat = (InCombatLockdown and InCombatLockdown()) or false
    self:CreateEventFrame()
end

function FadeManager:CreateEventFrame()
    if self.eventFrame then return end

    local f = CreateFrame("Frame", "ZenAlignFadeManagerFrame", UIParent)
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")

    f:SetScript("OnEvent", function(frameSelf, event)
        if event == "PLAYER_REGEN_DISABLED" then
            FadeManager.inCombat = true
            FadeManager:UpdateAllFrames()
        elseif event == "PLAYER_REGEN_ENABLED" then
            FadeManager.inCombat = false
            FadeManager:UpdateAllFrames()
        elseif event == "PLAYER_ENTERING_WORLD" then
            FadeManager.inCombat = (InCombatLockdown and InCombatLockdown()) or false
            FadeManager:UpdateAllFrames()
        end
    end)

    f:SetScript("OnUpdate", function(frameSelf, elapsed)
        FadeManager:OnUpdate(elapsed)
    end)

    self.eventFrame = f
end

function FadeManager:RegisterFrame(frameName, alphaOOC, alphaCombat, alphaHover, fadeDuration)
    local frame = nil
    local keyName = nil

    if type(frameName) == "string" then
        keyName = frameName
        frame = _G[frameName]
    elseif type(frameName) == "table" and frameName.GetObjectType then
        frame = frameName
        keyName = frame:GetName() or tostring(frame)
    else
        return nil
    end

    local record = self.registeredFrames[keyName]
    if not record then
        record = {
            frame = frame,
            frameName = keyName,
            currentAlpha = frame and frame:GetAlpha() or 1.0,
            targetAlpha = 1.0,
            startAlpha = 1.0,
            alphaOOC = alphaOOC or 1.0,
            alphaCombat = alphaCombat or 1.0,
            alphaHover = alphaHover or 1.0,
            fadeDuration = fadeDuration or 0.2,
            elapsedTime = 0.0,
            isFading = false,
            activeIdx = 0,
            registeredIdx = 0,
        }
        self.registeredFrames[keyName] = record
        self.numRegistered = self.numRegistered + 1
        self.registeredList[self.numRegistered] = record
        record.registeredIdx = self.numRegistered
    else
        if frame then record.frame = frame end
        record.alphaOOC = alphaOOC or record.alphaOOC
        record.alphaCombat = alphaCombat or record.alphaCombat
        record.alphaHover = alphaHover or record.alphaHover
        if fadeDuration then record.fadeDuration = fadeDuration end
    end

    self:UpdateFrameTargetState(record)
    return record
end

function FadeManager:UnregisterFrame(frameName)
    local keyName = type(frameName) == "string" and frameName or (type(frameName) == "table" and frameName.GetName and frameName:GetName())
    if not keyName then return end

    local record = self.registeredFrames[keyName]
    if not record then return end

    if record.isFading and record.activeIdx > 0 then
        local idx = record.activeIdx
        local lastRec = self.activeAnimations[self.numActive]
        self.activeAnimations[idx] = lastRec
        if lastRec then lastRec.activeIdx = idx end
        self.activeAnimations[self.numActive] = nil
        self.numActive = self.numActive - 1
        record.isFading = false
        record.activeIdx = 0
    end

    local rIdx = record.registeredIdx
    if rIdx > 0 and rIdx <= self.numRegistered then
        local lastReg = self.registeredList[self.numRegistered]
        self.registeredList[rIdx] = lastReg
        if lastReg then lastReg.registeredIdx = rIdx end
        self.registeredList[self.numRegistered] = nil
        self.numRegistered = self.numRegistered - 1
        record.registeredIdx = 0
    end

    self.registeredFrames[keyName] = nil
end

function FadeManager:SetFrameAlphas(frameName, alphaOOC, alphaCombat, alphaHover)
    local keyName = type(frameName) == "string" and frameName or (type(frameName) == "table" and frameName.GetName and frameName:GetName())
    if not keyName then return end

    local record = self.registeredFrames[keyName]
    if record then
        if alphaOOC then record.alphaOOC = alphaOOC end
        if alphaCombat then record.alphaCombat = alphaCombat end
        if alphaHover then record.alphaHover = alphaHover end
        self:UpdateFrameTargetState(record)
    end
end

function FadeManager:GetFrameRecord(frameName)
    local keyName = type(frameName) == "string" and frameName or (type(frameName) == "table" and frameName.GetName and frameName:GetName())
    return keyName and self.registeredFrames[keyName] or nil
end

function FadeManager:UpdateFrameTargetState(record)
    if not record then return end

    if not record.frame and record.frameName then
        record.frame = _G[record.frameName]
    end

    local frame = record.frame
    local targetAlpha

    -- State Priority Hierarchy:
    -- 1. If MouseIsOver(frame) then target = alphaHover
    -- 2. Else if inCombat then target = alphaCombat
    -- 3. Else target = alphaOOC
    local isHover = false
    if frame and frame:IsShown() then
        if MouseIsOver then
            isHover = MouseIsOver(frame)
        elseif frame.IsMouseOver then
            isHover = frame:IsMouseOver()
        end
    end

    if isHover then
        targetAlpha = record.alphaHover
    elseif self.inCombat then
        targetAlpha = record.alphaCombat
    else
        targetAlpha = record.alphaOOC
    end

    if record.targetAlpha ~= targetAlpha or (not record.isFading and frame and math.abs(record.currentAlpha - targetAlpha) > 0.001) then
        record.targetAlpha = targetAlpha
        record.startAlpha = frame and frame:GetAlpha() or record.currentAlpha
        record.elapsedTime = 0.0

        if record.fadeDuration <= 0 or math.abs(record.startAlpha - targetAlpha) < 0.001 then
            record.currentAlpha = targetAlpha
            if frame then frame:SetAlpha(targetAlpha) end
            if record.isFading and record.activeIdx > 0 then
                local idx = record.activeIdx
                local lastRec = self.activeAnimations[self.numActive]
                self.activeAnimations[idx] = lastRec
                if lastRec then lastRec.activeIdx = idx end
                self.activeAnimations[self.numActive] = nil
                self.numActive = self.numActive - 1
                record.isFading = false
                record.activeIdx = 0
            end
        else
            if not record.isFading then
                record.isFading = true
                self.numActive = self.numActive + 1
                self.activeAnimations[self.numActive] = record
                record.activeIdx = self.numActive
            end
        end
    end
end

function FadeManager:UpdateAllFrames()
    for i = 1, self.numRegistered do
        self:UpdateFrameTargetState(self.registeredList[i])
    end
end

function FadeManager:OnUpdate(elapsed)
    -- Step 1: Evaluate target alpha state changes for all registered frames (GC-free loop)
    for i = 1, self.numRegistered do
        self:UpdateFrameTargetState(self.registeredList[i])
    end

    -- Step 2: Smooth linear interpolation for active fading records (GC-free loop with O(1) swap-removal)
    local i = 1
    while i <= self.numActive do
        local rec = self.activeAnimations[i]
        rec.elapsedTime = rec.elapsedTime + elapsed
        local duration = rec.fadeDuration > 0 and rec.fadeDuration or 0.001
        local progress = rec.elapsedTime / duration

        if progress >= 1.0 then
            rec.currentAlpha = rec.targetAlpha
            if rec.frame then rec.frame:SetAlpha(rec.targetAlpha) end
            rec.isFading = false
            rec.activeIdx = 0

            local lastRec = self.activeAnimations[self.numActive]
            self.activeAnimations[i] = lastRec
            if lastRec then lastRec.activeIdx = i end
            self.activeAnimations[self.numActive] = nil
            self.numActive = self.numActive - 1
        else
            rec.currentAlpha = rec.startAlpha + (rec.targetAlpha - rec.startAlpha) * progress
            if rec.frame then rec.frame:SetAlpha(rec.currentAlpha) end
            i = i + 1
        end
    end
end
