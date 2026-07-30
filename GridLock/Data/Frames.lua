-- GridLock Frame Data
-- Comprehensive Blizzard & Addon frame catalog for WoW 3.3.5a

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

GridLock.FrameData = {}
local FD = GridLock.FrameData

-- Frame categories
FD.categories = {
    { name = "All", key = "all" },
    { name = "Bars", key = "bars" },
    { name = "Unit", key = "unit" },
    { name = "Map", key = "map" },
    { name = "Timers", key = "timers" },
    { name = "Raid", key = "raid" },
    { name = "PvP", key = "pvp" },
    { name = "Bags", key = "bags" },
    { name = "Misc", key = "misc" },
}

-- Frame definitions by category
FD.frames = {
    bars = {
        { name = "MainMenuBar", displayName = "Action Bar 1 (Main)" },
        { name = "MultiBarBottomLeft", displayName = "Action Bar 2 (Bottom Left)" },
        { name = "MultiBarBottomRight", displayName = "Action Bar 3 (Bottom Right)" },
        { name = "MultiBarRight", displayName = "Action Bar 4 (Right 1)" },
        { name = "MultiBarLeft", displayName = "Action Bar 5 (Right 2)" },
        { name = "ActionBar6", displayName = "Action Bar 6" },
        { name = "ActionBar7", displayName = "Action Bar 7" },
        { name = "ActionBar8", displayName = "Action Bar 8" },
        { name = "ActionBar9", displayName = "Action Bar 9" },
        { name = "ActionBar10", displayName = "Action Bar 10" },
        { name = "PetActionBarFrame", displayName = "Pet Action Bar" },
        { name = "ShapeshiftBarFrame", displayName = "Stance / Shapeshift Bar" },
        { name = "CharacterMicroButton", displayName = "Micro Menu Bar" },
        { name = "MainMenuBarBackpackButton", displayName = "Bag Bar / Backpack" },
        { name = "VehicleMenuBar", displayName = "Vehicle Action Bar" },
        { name = "MultiCastBar", displayName = "Totem Bar (Shaman)" },
        { name = "MainMenuBarLeftEndCap", displayName = "Left Gryphon Artwork" },
        { name = "MainMenuBarRightEndCap", displayName = "Right Gryphon Artwork" },
    },

    unit = {
        { name = "PlayerFrame", displayName = "Player Frame" },
        { name = "TargetFrame", displayName = "Target Frame" },
        { name = "TargetFrameToT", displayName = "Target of Target" },
        { name = "FocusFrame", displayName = "Focus Frame" },
        { name = "FocusFrameToT", displayName = "Target of Focus" },
        { name = "PetFrame", displayName = "Pet Frame" },
        { name = "PartyMemberFrame1", displayName = "Party Member 1" },
        { name = "PartyMemberFrame2", displayName = "Party Member 2" },
        { name = "PartyMemberFrame3", displayName = "Party Member 3" },
        { name = "PartyMemberFrame4", displayName = "Party Member 4" },
        { name = "Boss1TargetFrame", displayName = "Boss Frame 1" },
        { name = "Boss2TargetFrame", displayName = "Boss Frame 2" },
        { name = "Boss3TargetFrame", displayName = "Boss Frame 3" },
        { name = "Boss4TargetFrame", displayName = "Boss Frame 4" },
        { name = "ArenaEnemyFrame1", displayName = "Arena Enemy 1" },
        { name = "ArenaEnemyFrame2", displayName = "Arena Enemy 2" },
        { name = "ArenaEnemyFrame3", displayName = "Arena Enemy 3" },
        { name = "ArenaEnemyFrame4", displayName = "Arena Enemy 4" },
        { name = "ArenaEnemyFrame5", displayName = "Arena Enemy 5" },
    },

    map = {
        { name = "MinimapCluster", displayName = "Minimap Cluster" },
        { name = "Minimap", displayName = "Minimap" },
        { name = "MinimapBorderTop", displayName = "Minimap Border Top" },
        { name = "MinimapZoneTextButton", displayName = "Zone Text Button" },
        { name = "GameTimeFrame", displayName = "Calendar Button" },
        { name = "TimeManagerClockButton", displayName = "Clock Button" },
        { name = "MiniMapTracking", displayName = "Tracking Button" },
        { name = "MiniMapMailFrame", displayName = "Mail Indicator" },
        { name = "MiniMapBattlefieldFrame", displayName = "Battleground Button" },
        { name = "MiniMapInstanceDifficulty", displayName = "Dungeon Difficulty" },
        { name = "WorldMapFrame", displayName = "World Map Window" },
    },

    timers = {
        { name = "CastingBarFrame", displayName = "Player Cast Bar" },
        { name = "TargetFrameSpellBar", displayName = "Target Cast Bar" },
        { name = "FocusFrameSpellBar", displayName = "Focus Cast Bar" },
        { name = "MirrorTimer1", displayName = "Breath / Fatigue Bar 1" },
        { name = "MirrorTimer2", displayName = "Breath / Fatigue Bar 2" },
        { name = "MirrorTimer3", displayName = "Breath / Fatigue Bar 3" },
        { name = "RuneFrame", displayName = "Death Knight Runes" },
        { name = "ComboFrame", displayName = "Rogue / Druid Combo Points" },
        { name = "TotemFrame", displayName = "Totem Timers" },
        { name = "VehicleSeatIndicator", displayName = "Vehicle Seat Indicator" },
    },

    raid = {
        { name = "RaidFrame", displayName = "Raid Frame Window" },
        { name = "RaidPullout1", displayName = "Raid Group 1" },
        { name = "RaidPullout2", displayName = "Raid Group 2" },
        { name = "RaidPullout3", displayName = "Raid Group 3" },
        { name = "RaidPullout4", displayName = "Raid Group 4" },
        { name = "RaidPullout5", displayName = "Raid Group 5" },
        { name = "RaidPullout6", displayName = "Raid Group 6" },
        { name = "RaidPullout7", displayName = "Raid Group 7" },
        { name = "RaidPullout8", displayName = "Raid Group 8" },
        { name = "CompactRaidFrameManager", displayName = "Raid Frame Manager" },
        { name = "CompactRaidFrameContainer", displayName = "Raid Frame Container" },
    },

    pvp = {
        { name = "PVPFrame", displayName = "PvP Window" },
        { name = "PVPBattlegroundFrame", displayName = "Battleground Window" },
        { name = "WorldStateAlwaysUpFrame", displayName = "PvP Score / Objectives" },
    },

    bags = {
        { name = "CharacterBag0Slot", displayName = "Bag 1 Button" },
        { name = "CharacterBag1Slot", displayName = "Bag 2 Button" },
        { name = "CharacterBag2Slot", displayName = "Bag 3 Button" },
        { name = "CharacterBag3Slot", displayName = "Bag 4 Button" },
        { name = "KeyRingButton", displayName = "Key Ring Button" },
        { name = "ContainerFrame1", displayName = "Container Bag 1" },
        { name = "ContainerFrame2", displayName = "Container Bag 2" },
        { name = "ContainerFrame3", displayName = "Container Bag 3" },
        { name = "ContainerFrame4", displayName = "Container Bag 4" },
        { name = "ContainerFrame5", displayName = "Container Bag 5" },
    },

    misc = {
        { name = "ChatFrame1", displayName = "Chat Frame 1" },
        { name = "ChatFrame2", displayName = "Chat Frame 2" },
        { name = "GeneralDockManager", displayName = "Chat Tabs Bar" },
        { name = "BuffFrame", displayName = "Buffs Cluster" },
        { name = "TemporaryEnchantFrame", displayName = "Weapon Enchants" },
        { name = "ConsolidatedBuffs", displayName = "Consolidated Buffs" },
        { name = "DurabilityFrame", displayName = "Durability Doll" },
        { name = "WatchFrame", displayName = "Quest Tracker Window" },
        { name = "UIErrorsFrame", displayName = "Screen Error Messages" },
        { name = "RaidWarningFrame", displayName = "Raid Warning Banner" },
        { name = "ZoneTextFrame", displayName = "Zone Text Banner" },
        { name = "SubZoneTextFrame", displayName = "Subzone Text Banner" },
        { name = "GameTooltip", displayName = "Game Tooltip" },
        { name = "LootFrame", displayName = "Loot Window" },
        { name = "GroupLootFrame1", displayName = "Roll Window 1" },
        { name = "GroupLootFrame2", displayName = "Roll Window 2" },
        { name = "GroupLootFrame3", displayName = "Roll Window 3" },
        { name = "GroupLootFrame4", displayName = "Roll Window 4" },
        { name = "TicketStatusFrame", displayName = "GM Ticket Status" },
        { name = "BNToastFrame", displayName = "Battle.net Toast" },
    },
}

-- Get all frame definitions as a flat list
function FD:GetAllFrames()
    local all = {}
    for cat, frames in pairs(self.frames) do
        for _, frameInfo in ipairs(frames) do
            local item = {
                name = frameInfo.name,
                displayName = frameInfo.displayName,
                category = cat
            }
            table.insert(all, item)
        end
    end
    table.sort(all, function(a, b)
        return a.displayName < b.displayName
    end)
    return all
end

-- Get frames by category (if category is "all" or nil, returns all frames)
function FD:GetFramesByCategory(category)
    if not category or category == "all" then
        return self:GetAllFrames()
    end
    local list = {}
    local frames = self.frames[category]
    if frames then
        for _, frameInfo in ipairs(frames) do
            local item = {
                name = frameInfo.name,
                displayName = frameInfo.displayName,
                category = category
            }
            table.insert(list, item)
        end
    end
    table.sort(list, function(a, b)
        return a.displayName < b.displayName
    end)
    return list
end

-- Get display name for a category key
function FD:GetCategoryName(catKey)
    for _, cat in ipairs(self.categories) do
        if cat.key == catKey then
            return cat.name
        end
    end
    return catKey and (catKey:sub(1,1):upper() .. catKey:sub(2)) or "Misc"
end

-- Find frame info by name
function FD:GetFrameInfo(frameName)
    for cat, frames in pairs(self.frames) do
        for _, frameInfo in ipairs(frames) do
            if frameInfo.name == frameName then
                return {
                    name = frameInfo.name,
                    displayName = frameInfo.displayName,
                    category = cat
                }
            end
        end
    end
    -- Return basic info for unregistered frames
    return {
        name = frameName,
        displayName = frameName,
        category = "misc",
    }
end

-- Check if frame is in our known list
function FD:IsKnownFrame(frameName)
    for cat, frames in pairs(self.frames) do
        for _, frameInfo in ipairs(frames) do
            if frameInfo.name == frameName then
                return true
            end
        end
    end
    return false
end
