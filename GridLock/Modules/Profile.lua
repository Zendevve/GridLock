-- GridLock Profile Module
-- Handles Profile Management, Dual-Spec Auto-Switching, and Layout Import/Export

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

local Profile = {}
if type(GridLock.RegisterModule) == "function" then
    GridLock:RegisterModule("Profile", Profile)
else
    GridLock.modules = GridLock.modules or {}
    GridLock.modules["Profile"] = Profile
end

Profile.currentProfile = "Default"

function Profile:OnInitialize()
    self:InitDatabase()

    -- Register Dual-Spec talent spec switching events
    local f = CreateFrame("Frame", "GridLockProfileFrame", UIParent)
    f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(selfFrame, event, ...)
        if event == "ACTIVE_TALENT_GROUP_CHANGED" then
            Profile:OnSpecChanged()
        elseif event == "PLAYER_ENTERING_WORLD" then
            Profile:OnSpecChanged()
        end
    end)
end

-- Initialize Profile database structure in GridLockDB
function Profile:InitDatabase()
    GridLockDB = GridLockDB or {}
    GridLockDB.profiles = GridLockDB.profiles or {}
    GridLockDB.profileOptions = GridLockDB.profileOptions or {
        autoSwitchSpec = true,
        primaryProfile = "Primary Spec",
        secondaryProfile = "Secondary Spec",
        currentProfile = "Default",
    }

    if not GridLockDB.profiles["Default"] then
        GridLockDB.profiles["Default"] = {
            frames = {},
            hiddenFrames = {},
            barLayouts = {},
            artSettings = {},
        }
    end

    self.currentProfile = GridLockDB.profileOptions.currentProfile or "Default"
end

-- Get current active spec index (1 = Primary, 2 = Secondary)
function Profile:GetActiveSpec()
    if _G.GetActiveTalentGroup then
        return _G.GetActiveTalentGroup() or 1
    end
    return 1
end

-- Dual-Spec change event listener
function Profile:OnSpecChanged()
    local opts = GridLockDB and GridLockDB.profileOptions
    if not opts or not opts.autoSwitchSpec then return end

    local activeSpec = self:GetActiveSpec()
    local targetProfile = (activeSpec == 2) and (opts.secondaryProfile or "Secondary Spec") or (opts.primaryProfile or "Primary Spec")

    if targetProfile ~= self.currentProfile then
        GridLock.Utils.Print("Dual-Spec active: Auto-switching profile to '%s' (Spec %d)", targetProfile, activeSpec)
        self:SelectProfile(targetProfile)
    end
end

-- Select & Apply Profile
function Profile:SelectProfile(profileName)
    if not profileName or profileName == "" then return false end

    self:InitDatabase()
    if not GridLockDB.profiles[profileName] then
        self:CreateProfile(profileName)
    end

    GridLockDB.profileOptions.currentProfile = profileName
    self.currentProfile = profileName

    -- Apply frame positions, layouts, and artwork settings from profile
    local profData = GridLockDB.profiles[profileName]
    if profData then
        GridLock.db = GridLock.db or { frames = {}, hiddenFrames = {} }
        -- Restore frame positions
        local Position = GridLock:GetModule("Position")
        if Position then
            if profData.frames then
                GridLock.db.frames = profData.frames
                Position:ApplyAllSavedPositions()
            end
        end

        -- Restore visibility
        local Visibility = GridLock:GetModule("Visibility")
        if Visibility and profData.hiddenFrames then
            GridLock.db.hiddenFrames = profData.hiddenFrames
        end

        -- Restore bar layouts
        local BarLayout = GridLock:GetModule("BarLayout")
        if BarLayout and profData.barLayouts then
            for barName, cfg in pairs(profData.barLayouts) do
                if BarLayout.SetBarLayout then
                    BarLayout:SetBarLayout(barName, cfg.rows, cfg.cols, cfg.spacing, cfg.padding)
                end
            end
        end

        -- Restore Blizzard artwork settings
        local BlizzardArt = GridLock:GetModule("BlizzardArt")
        if BlizzardArt and profData.artSettings then
            BlizzardArt:ApplyBlizzardArtSettings(profData.artSettings)
        end
    end

    GridLock.Utils.Print("Active profile set to '%s'", profileName)
    return true
end

-- Create New Profile
function Profile:CreateProfile(profileName)
    if not profileName or profileName == "" then return false end
    self:InitDatabase()

    if not GridLockDB.profiles[profileName] then
        GridLockDB.profiles[profileName] = {
            frames = GridLock.Utils.DeepCopy(GridLock.db and GridLock.db.frames or {}),
            hiddenFrames = GridLock.Utils.DeepCopy(GridLock.db and GridLock.db.hiddenFrames or {}),
            barLayouts = {},
            artSettings = {},
        }
        GridLock.Utils.Print("Created new profile '%s'", profileName)
    end
    return true
end

-- Delete Profile
function Profile:DeleteProfile(profileName)
    if not profileName or profileName == "Default" then
        GridLock.Utils.Print("Cannot delete Default profile")
        return false
    end

    self:InitDatabase()
    GridLockDB.profiles[profileName] = nil

    if self.currentProfile == profileName then
        self:SelectProfile("Default")
    end

    GridLock.Utils.Print("Deleted profile '%s'", profileName)
    return true
end

-- Copy Profile
function Profile:CopyProfile(fromName, toName)
    if not fromName or not toName then return false end
    self:InitDatabase()

    local src = GridLockDB.profiles[fromName]
    if not src then return false end

    GridLockDB.profiles[toName] = GridLock.Utils.DeepCopy(src)
    GridLock.Utils.Print("Copied profile '%s' to '%s'", fromName, toName)
    return true
end

-- Get list of all available profile names
function Profile:GetProfiles()
    self:InitDatabase()
    local list = {}
    for name in pairs(GridLockDB.profiles) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end
