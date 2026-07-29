-- ZenAlign Frame Data
-- Common Blizzard frames organized by category for WoW 3.3.5a

local ZenAlign = select(2, ...)

ZenAlign.FrameData = {}
local FD = ZenAlign.FrameData

-- Frame categories
FD.categories = {
    { name = "All", key = "all" },
    { name = "Unit", key = "unit" },
    { name = "Bars", key = "bars" },
    { name = "Map", key = "map" },
    { name = "Raid", key = "raid" },
    { name = "PvP", key = "pvp" },
    { name = "Bags", key = "bags" },
    { name = "Misc", key = "misc" },
}

-- Frame definitions by category
FD.frames = {
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
        { name = "Boss1TargetFrame", displayName = "Boss 1" },
        { name = "Boss2TargetFrame", displayName = "Boss 2" },
        { name = "Boss3TargetFrame", displayName = "Boss 3" },
        { name = "Boss4TargetFrame", displayName = "Boss 4" },
        { name = "ArenaEnemyFrame1", displayName = "Arena Enemy 1" },
        { name = "ArenaEnemyFrame2", displayName = "Arena Enemy 2" },
        { name = "ArenaEnemyFrame3", displayName = "Arena Enemy 3" },
        { name = "ArenaEnemyFrame4", displayName = "Arena Enemy 4" },
        { name = "ArenaEnemyFrame5", displayName = "Arena Enemy 5" },
    },

    bars = {
        { name = "MainMenuBar", displayName = "Main Action Bar" },
        { name = "MultiBarBottomLeft", displayName = "Bottom Left Bar" },
        { name = "MultiBarBottomRight", displayName = "Bottom Right Bar" },
        { name = "MultiBarRight", displayName = "Right Bar" },
        { name = "MultiBarLeft", displayName = "Right Bar 2" },
        { name = "PetActionBarFrame", displayName = "Pet Action Bar" },
        { name = "ShapeshiftBarFrame", displayName = "Stance Bar" },
        { name = "MainMenuBarLeftEndCap", displayName = "Left Gryphon" },
        { name = "MainMenuBarRightEndCap", displayName = "Right Gryphon" },
        { name = "VehicleMenuBar", displayName = "Vehicle Bar" },
    },

    map = {
        { name = "MinimapCluster", displayName = "Minimap Cluster" },
        { name = "Minimap", displayName = "Minimap" },
        { name = "MinimapBorderTop", displayName = "Minimap Border Top" },
        { name = "MinimapZoneTextButton", displayName = "Zone Text" },
        { name = "GameTimeFrame", displayName = "Calendar Button" },
        { name = "TimeManagerClockButton", displayName = "Clock Button" },
        { name = "MiniMapTracking", displayName = "Tracking Button" },
        { name = "MiniMapMailFrame", displayName = "Mail Indicator" },
        { name = "MiniMapBattlefieldFrame", displayName = "Battleground Button" },
        { name = "MiniMapInstanceDifficulty", displayName = "Dungeon Difficulty" },
        { name = "WorldMapFrame", displayName = "World Map" },
    },

    raid = {
        { name = "RaidFrame", displayName = "Raid Frame" },
        { name = "RaidPullout1", displayName = "Raid Pullout 1" },
        { name = "RaidPullout2", displayName = "Raid Pullout 2" },
        { name = "RaidPullout3", displayName = "Raid Pullout 3" },
        { name = "RaidPullout4", displayName = "Raid Pullout 4" },
        { name = "RaidPullout5", displayName = "Raid Pullout 5" },
        { name = "RaidPullout6", displayName = "Raid Pullout 6" },
        { name = "RaidPullout7", displayName = "Raid Pullout 7" },
        { name = "RaidPullout8", displayName = "Raid Pullout 8" },
        { name = "CompactRaidFrameManager", displayName = "Raid Frame Manager" },
        { name = "CompactRaidFrameContainer", displayName = "Raid Frame Container" },
    },

    pvp = {
        { name = "PVPFrame", displayName = "PvP Frame" },
        { name = "PVPBattlegroundFrame", displayName = "Battleground Frame" },
        { name = "PVPColorFrame", displayName = "PvP Color Frame" },
        { name = "WorldStateAlwaysUpFrame", displayName = "PvP Objectives" },
    },

    bags = {
        { name = "MainMenuBarBackpackButton", displayName = "Backpack Button" },
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
        { name = "ContainerFrame6", displayName = "Container Bag 6" },
        { name = "ContainerFrame7", displayName = "Container Bag 7" },
        { name = "ContainerFrame8", displayName = "Container Bag 8" },
        { name = "ContainerFrame9", displayName = "Container Bag 9" },
        { name = "ContainerFrame10", displayName = "Container Bag 10" },
        { name = "ContainerFrame11", displayName = "Container Bag 11" },
        { name = "ContainerFrame12", displayName = "Container Bag 12" },
        { name = "ContainerFrame13", displayName = "Container Bag 13" },
    },

    misc = {
        { name = "ChatFrame1", displayName = "Chat Frame 1" },
        { name = "ChatFrame2", displayName = "Chat Frame 2" },
        { name = "GeneralDockManager", displayName = "Chat Tabs" },
        { name = "BuffFrame", displayName = "Buffs" },
        { name = "TemporaryEnchantFrame", displayName = "Temporary Enchants" },
        { name = "ConsolidatedBuffs", displayName = "Consolidated Buffs" },
        { name = "CastingBarFrame", displayName = "Player Cast Bar" },
        { name = "TargetFrameSpellBar", displayName = "Target Cast Bar" },
        { name = "FocusFrameSpellBar", displayName = "Focus Cast Bar" },
        { name = "MirrorTimer1", displayName = "Breath/Fatigue Bar" },
        { name = "DurabilityFrame", displayName = "Durability" },
        { name = "WatchFrame", displayName = "Quest Tracker" },
        { name = "VehicleSeatIndicator", displayName = "Vehicle Seats" },
        { name = "TotemFrame", displayName = "Totem Timers" },
        { name = "RuneFrame", displayName = "DK Runes" },
        { name = "ComboFrame", displayName = "Combo Points" },
        { name = "GhostFrame", displayName = "Ghost Release" },
        { name = "UIErrorsFrame", displayName = "Error Text" },
        { name = "RaidWarningFrame", displayName = "Raid Warning" },
        { name = "ZoneTextFrame", displayName = "Zone Text" },
        { name = "SubZoneTextFrame", displayName = "Subzone Text" },
        { name = "GameTooltip", displayName = "Tooltip" },
        { name = "LootFrame", displayName = "Loot Frame" },
        { name = "GroupLootFrame1", displayName = "Roll Frame 1" },
        { name = "GroupLootFrame2", displayName = "Roll Frame 2" },
        { name = "GroupLootFrame3", displayName = "Roll Frame 3" },
        { name = "GroupLootFrame4", displayName = "Roll Frame 4" },
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
