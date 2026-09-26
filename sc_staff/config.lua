-- =========================================================
-- STARS CITY - STAFF SYSTEM
-- Shared configuration
-- =========================================================

SC_STAFF = SC_STAFF or {}

SC_STAFF.RANKS = {
    [0] = "Citizen",
    [1] = "Founder",
    [2] = "Owner",
    [3] = "Manager",
    [4] = "Assistant",
    [5] = "Server Director",
    [6] = "Server Advisor",
    [7] = "Faction Warden",
    [8] = "Support",
    [9] = "Helper"
}

-- Lower positive number = higher authority. Citizen is always 0.
SC_STAFF.MANAGER_MAX_RANK = 4
SC_STAFF.FOUNDER_RANK = 1

-- Display order in the Staff Manager.
SC_STAFF.MANAGEABLE_RANK_ORDER = { 2, 3, 4, 5, 6, 7, 8, 9, 0 }

SC_STAFF.EVENT_COOLDOWNS = {
    lookup = 250,
    setStaff = 1200
}

SC_STAFF.UI = {
    baseWidth = 620,
    baseHeight = 430,
    referenceWidth = 1920,
    referenceHeight = 1080,
    minScale = 0.82,
    maxScale = 1.25
}

-- Player identity shown in staff/admin interfaces must always come from the
-- Stars City account system, never from the native MTA nickname.
SC_STAFF.PLAYER_LEVEL_DB_FIELDS = { "level", "player_level", "account_level" }
SC_STAFF.PLAYER_LEVEL_DATA_KEYS = { "account:level", "player:level", "level" }

function SC_STAFF.getRankName(rank)
    rank = tonumber(rank) or 0
    return SC_STAFF.RANKS[rank] or "Citizen"
end

function SC_STAFF.isValidRank(rank)
    rank = tonumber(rank)
    return rank ~= nil and SC_STAFF.RANKS[rank] ~= nil
end

function SC_STAFF.getRankLevelByName(rankName)
    if type(rankName) ~= "string" then
        return nil
    end

    local needle = string.lower(rankName)

    for level, name in pairs(SC_STAFF.RANKS) do
        if string.lower(name) == needle then
            return level
        end
    end

    return nil
end

function SC_STAFF.hasManagerAccess(rank)
    rank = tonumber(rank) or 0
    return rank > 0 and rank <= SC_STAFF.MANAGER_MAX_RANK
end

function SC_STAFF.canAssignRank(actorRank, newRank)
    actorRank = tonumber(actorRank) or 0
    newRank = tonumber(newRank)

    if not SC_STAFF.hasManagerAccess(actorRank) or not SC_STAFF.isValidRank(newRank) then
        return false
    end

    if newRank == SC_STAFF.FOUNDER_RANK then
        return false
    end

    if newRank == 0 then
        return true
    end

    return newRank > actorRank
end

-- =========================================================
-- ADMIN CONTROL PANEL
-- Permission matrix is intentionally centralized here so it can be
-- replaced later without changing any client/server business logic.
-- =========================================================

SC_STAFF.ADMIN_PANEL = {
    command = "adminpanel",
    key = "F2",
    snapshotCooldown = 800,
    actionCooldown = 450,
    refreshInterval = 5000,
    minRank = 9
}

-- Staff duty is session-only. It is intentionally not persisted in the account DB.
SC_STAFF.DUTY = {
    command = "duty",
    dataKey = "staff:onDuty"
}

-- Optional faction metadata candidates used only for Staff Management ordering.
-- The current account schema does not require these columns; if a future faction/core
-- system adds one of them to players, sc_staff will pick it up automatically.
SC_STAFF.FACTION_DB_FIELDS = {
    id = { "faction_id", "faction", "team_id" },
    name = { "faction_name", "team_name" },
    rank = { "faction_rank", "faction_level", "member_rank" },
    rankName = { "faction_rank_name", "faction_role", "member_rank_name" },
    leader = { "faction_leader", "is_faction_leader", "leader" },
    subLeader = { "faction_subleader", "is_faction_subleader", "subleader" }
}


-- Dashboard self-tool integration. Respawn is delegated to sc_accounts so the
-- account resource remains authoritative for spawn placement (currently House -> Default Spawn).
SC_STAFF.ADMIN_RESPAWN_HOOK = {
    resource = "sc_accounts",
    export = "respawnPlayerFromAccount",
    command = ""
}

-- Native GTA:SA weapon IDs exposed in the admin weapon catalog.
-- IDs 10-13 are intentionally not exposed in this staff UI.
SC_STAFF.ADMIN_WEAPON_IDS = {
    1, 2, 3, 4, 5, 6, 7, 8, 9,
    14, 15, 16, 17, 18,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
    35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46
}

-- Infinite Ammo is implemented server-side by continuously restoring ammo
-- for every occupied weapon slot that consumes a quantity.
SC_STAFF.ADMIN_INFINITE_AMMO_AMOUNT = 9999

-- Player Tools configuration. Persistent ownership/state is stored by
-- sc_accounts; sc_staff only calls the account persistence API.
SC_STAFF.ADMIN_PLAYER_WEAPON_AMMO = 500
SC_STAFF.ADMIN_REVIVE_HOOK = { resource = "", export = "", command = "" }
SC_STAFF.ADMIN_TELEPORT_LOCATIONS = {
    { id = 1, name = "Medic LV", x = nil, y = nil, z = nil, interior = 0, dimension = 0 },
    { id = 2, name = "Spray 4", x = nil, y = nil, z = nil, interior = 0, dimension = 0 }
}

SC_STAFF.ADMIN_SHOOTING_SKILLS = {
    { id = 1,  key = "colt45",  name = "Colt45",  max = 5000,  stat = 69 },
    { id = 2,  key = "silenced",name = "Silenced", max = 10000, stat = 70 },
    { id = 3,  key = "deagle",  name = "Deagle",  max = 6000,  stat = 71 },
    { id = 4,  key = "sawnoff", name = "Sawnoff", max = 4000,  stat = 73 },
    { id = 5,  key = "shotgun", name = "Shotgun", max = 8000,  stat = 72 },
    { id = 6,  key = "shotgspa",name = "Shotgspa",max = 10000, stat = 74 },
    { id = 8,  key = "uzi",     name = "UZI",     max = 15000, stat = 75 },
    { id = 9,  key = "tec9",    name = "Tec9",    max = 15000, stat = 75 },
    { id = 10, key = "mp5",     name = "MP5",     max = 15000, stat = 76 },
    { id = 11, key = "ak47",    name = "AK47",    max = 20000, stat = 77 },
    { id = 12, key = "m4",      name = "M4",      max = 20000, stat = 78 },
    { id = 13, key = "cuntgun", name = "Cuntgun", max = 3000,  stat = 79 },
    { id = 14, key = "sniper",  name = "Sniper",  max = 3000,  stat = 79 }
}

SC_STAFF.ADMIN_LICENSES = {
    { key = "car", name = "Car" },
    { key = "bike", name = "Bike" },
    { key = "boat", name = "Boat" },
    { key = "plane", name = "Plane" },
    { key = "gun", name = "Gun" }
}


-- =========================================================
-- PUNISHMENT SYSTEM
-- =========================================================
-- Default Admin Jail uses the LSPD jail-cell interior. Change only this
-- configuration later if StarsCity gets a custom Admin Jail map.
SC_STAFF.ADMIN_JAIL_LOCATION = {
    x = 265.070129,
    y = 77.518280,
    z = 1001.039062,
    rotation = 270,
    interior = 6,
    dimension = 0,
    maxDistance = 28
}

SC_STAFF.PUNISHMENT_WARN_EXPIRE_SECONDS = 7 * 24 * 60 * 60
SC_STAFF.PUNISHMENT_MAX_WARNS = 10
SC_STAFF.PUNISHMENT_REASON_MAX_LENGTH = 1024
SC_STAFF.PUNISHMENT_HISTORY_PAGE_SIZE = 50
SC_STAFF.PUNISHMENT_TARGET_CACHE_MS = 15000
SC_STAFF.PUNISHMENT_TARGET_REFRESH_MS = 15000
-- Iran Standard Time (UTC+03:30). Stored Unix timestamps stay UTC; only display dates use this offset.
SC_STAFF.PUNISHMENT_TIMEZONE_OFFSET_MINUTES = 210

SC_STAFF.PUNISHMENT_MUTE_TIMES = {
    { key = "10m", label = "10 Minutes", seconds = 10 * 60, chat = "10 Daghighe" },
    { key = "15m", label = "15 Minutes", seconds = 15 * 60, chat = "15 Daghighe" },
    { key = "30m", label = "30 Minutes", seconds = 30 * 60, chat = "30 Daghighe" },
    { key = "45m", label = "45 Minutes", seconds = 45 * 60, chat = "45 Daghighe" },
    { key = "1h", label = "1 Hours", seconds = 60 * 60, chat = "1 Saat" },
    { key = "3h", label = "3 Hours", seconds = 3 * 60 * 60, chat = "3 Saat" },
    { key = "5h", label = "5 Hours", seconds = 5 * 60 * 60, chat = "5 Saat" },
    { key = "8h", label = "8 Hours", seconds = 8 * 60 * 60, chat = "8 Saat" },
    { key = "10h", label = "10 Hours", seconds = 10 * 60 * 60, chat = "10 Saat" },
    { key = "1d", label = "1 Days", seconds = 24 * 60 * 60, chat = "1 Rooz" },
    { key = "3d", label = "3 Days", seconds = 3 * 24 * 60 * 60, chat = "3 Rooz" },
    { key = "1w", label = "1 Week", seconds = 7 * 24 * 60 * 60, chat = "1 Hafteh" },
    { key = "3w", label = "3 Week", seconds = 21 * 24 * 60 * 60, chat = "3 Hafteh" },
    { key = "1mo", label = "1 Months", seconds = 30 * 24 * 60 * 60, chat = "1 Mah" },
    { key = "2mo", label = "2 Months", seconds = 60 * 24 * 60 * 60, chat = "2 Mah" },
    { key = "3mo", label = "3 Months", seconds = 90 * 24 * 60 * 60, chat = "3 Mah" }
}

SC_STAFF.PUNISHMENT_JAIL_TIMES = {
    { key = "10m", label = "10 Minutes", seconds = 10 * 60, chat = "10 Daghighe" },
    { key = "15m", label = "15 Minutes", seconds = 15 * 60, chat = "15 Daghighe" },
    { key = "30m", label = "30 Minutes", seconds = 30 * 60, chat = "30 Daghighe" },
    { key = "45m", label = "45 Minutes", seconds = 45 * 60, chat = "45 Daghighe" },
    { key = "1h", label = "1 Hours", seconds = 60 * 60, chat = "1 Saat" },
    { key = "3h", label = "3 Hours", seconds = 3 * 60 * 60, chat = "3 Saat" },
    { key = "5h", label = "5 Hours", seconds = 5 * 60 * 60, chat = "5 Saat" },
    { key = "8h", label = "8 Hours", seconds = 8 * 60 * 60, chat = "8 Saat" },
    { key = "10h", label = "10 Hours", seconds = 10 * 60 * 60, chat = "10 Saat" },
    { key = "15h", label = "15 Hours", seconds = 15 * 60 * 60, chat = "15 Saat" },
    { key = "1d", label = "1 Days", seconds = 24 * 60 * 60, chat = "1 Rooz" },
    { key = "2d", label = "2 Days", seconds = 2 * 24 * 60 * 60, chat = "2 Rooz" },
    { key = "3d", label = "3 Days", seconds = 3 * 24 * 60 * 60, chat = "3 Rooz" },
    { key = "1w", label = "1 Week", seconds = 7 * 24 * 60 * 60, chat = "1 Hafteh" },
    { key = "3w", label = "3 Week", seconds = 21 * 24 * 60 * 60, chat = "3 Hafteh" },
    { key = "6w", label = "6 Week", seconds = 42 * 24 * 60 * 60, chat = "6 Hafteh" }
}

SC_STAFF.PUNISHMENT_BAN_TIMES = {
    { key = "5h", label = "5 Hours", seconds = 5 * 60 * 60, chat = "5 Saat" },
    { key = "10h", label = "10 Hours", seconds = 10 * 60 * 60, chat = "10 Saat" },
    { key = "15h", label = "15 Hours", seconds = 15 * 60 * 60, chat = "15 Saat" },
    { key = "1d", label = "1 Days", seconds = 24 * 60 * 60, chat = "1 Rooz" },
    { key = "3d", label = "3 Days", seconds = 3 * 24 * 60 * 60, chat = "3 Rooz" },
    { key = "1w", label = "1 Week", seconds = 7 * 24 * 60 * 60, chat = "1 Hafteh" },
    { key = "3w", label = "3 Week", seconds = 21 * 24 * 60 * 60, chat = "3 Hafteh" },
    { key = "6w", label = "6 Week", seconds = 42 * 24 * 60 * 60, chat = "6 Hafteh" },
    { key = "1mo", label = "1 Month", seconds = 30 * 24 * 60 * 60, chat = "1 Mah" },
    { key = "3mo", label = "3 Month", seconds = 90 * 24 * 60 * 60, chat = "3 Mah" }
}

SC_STAFF.ADMIN_ACTIONS = {
    ["player.goto"] = {
        label = "Go To",
        category = "player",
        needsTarget = true,
        targetRule = "any"
    },
    ["player.gethere"] = {
        label = "Get Here",
        category = "player",
        needsTarget = true,
        targetRule = "lower"
    },
    ["player.spectate"] = {
        label = "Spectate",
        category = "player",
        needsTarget = true,
        targetRule = "any"
    },
    ["player.spectate_stop"] = {
        label = "Stop Spectate",
        category = "player",
        needsTarget = false,
        targetRule = "any"
    },
    ["player.freeze"] = {
        label = "Freeze / Unfreeze",
        category = "player",
        needsTarget = true,
        targetRule = "lower"
    },
    ["player.heal"] = {
        label = "Heal",
        category = "player",
        needsTarget = true,
        targetRule = "selfOrLower"
    },
    ["player.armor"] = {
        label = "Give Armor",
        category = "player",
        needsTarget = true,
        targetRule = "selfOrLower"
    },
    ["player.slap"] = {
        label = "Slap (-20 HP)",
        category = "player",
        needsTarget = true,
        targetRule = "lower"
    },
    ["player.kill"] = {
        label = "Kill",
        category = "player",
        needsTarget = true,
        targetRule = "lower",
        danger = true
    },
    ["player.revive"] = {
        label = "Revive",
        category = "player",
        needsTarget = true,
        targetRule = "selfOrLower"
    },
    ["player.set_health"] = {
        label = "Set Health",
        category = "player",
        needsTarget = true,
        needsValue = true,
        valueLabel = "Health",
        valueHint = "1 - 100",
        targetRule = "selfOrLower"
    },
    ["player.set_armor"] = {
        label = "Set Armor",
        category = "player",
        needsTarget = true,
        needsValue = true,
        valueLabel = "Armor",
        valueHint = "0 - 100",
        targetRule = "selfOrLower"
    },
    ["player.set_dimension"] = {
        label = "Set Dimension",
        category = "player",
        needsTarget = true,
        needsValue = true,
        valueLabel = "Dimension",
        valueHint = "0 - 65535",
        targetRule = "selfOrLower"
    },
    ["player.set_interior"] = {
        label = "Set Interior",
        category = "player",
        needsTarget = true,
        needsValue = true,
        valueLabel = "Interior",
        valueHint = "0 - 255",
        targetRule = "selfOrLower"
    },
    ["player.set_position"] = {
        label = "Set Position",
        category = "player",
        needsTarget = true,
        needsValue = true,
        valueLabel = "Position X, Y, Z",
        valueHint = "Example: 1481.2, -1768.4, 18.8",
        targetRule = "selfOrLower"
    },
    ["player.set_skin"] = {
        label = "Set Skin",
        category = "player",
        needsTarget = true,
        needsValue = true,
        valueLabel = "Skin Model",
        valueHint = "0 - 312",
        targetRule = "selfOrLower"
    },
    ["player.remove_vehicle"] = {
        label = "Remove From Vehicle",
        category = "player",
        needsTarget = true,
        targetRule = "selfOrLower"
    },
    ["punishment.warn"] = { label = "Warn", category = "punishment", needsTarget = true, targetRule = "lower" },
    ["punishment.kick"] = { label = "Kick", category = "punishment", needsTarget = true, targetRule = "lower", danger = true },
    ["punishment.mute"] = { label = "Mute", category = "punishment", needsTarget = true, targetRule = "lower" },
    ["punishment.unmute"] = { label = "Unmute", category = "punishment", needsTarget = true, targetRule = "lower" },
    ["punishment.jail"] = { label = "Admin Jail", category = "punishment", needsTarget = true, targetRule = "lower" },
    ["punishment.unjail"] = { label = "Unjail", category = "punishment", needsTarget = true, targetRule = "lower" },
    ["punishment.temp_ban"] = { label = "Temporary Ban", category = "punishment", needsTarget = true, targetRule = "lower", danger = true },
    ["punishment.perm_ban"] = { label = "Permanent Ban", category = "punishment", needsTarget = true, targetRule = "lower", danger = true },
    ["punishment.unban"] = { label = "Unban", category = "punishment", needsTarget = true, targetRule = "lower" },
    ["punishment.remove_warn"] = { label = "Remove Warn", category = "punishment", needsTarget = true, targetRule = "lower" },
    ["vehicle.fix"] = {
        label = "Fix Vehicle",
        category = "vehicle",
        needsTarget = true,
        targetRule = "selfOrLower"
    },
    ["vehicle.flip"] = {
        label = "Flip Vehicle",
        category = "vehicle",
        needsTarget = true,
        targetRule = "selfOrLower"
    },

    -- Advanced Player Tools. The dedicated Player Tools UI controls their
    -- presentation; these definitions keep permission/target validation centralized.
    ["player.respawn"] = { label = "Respawn", category = "player", needsTarget = true, targetRule = "selfOrLower" },
    ["player.full_heal_armor"] = { label = "Full Heal / Armor", category = "player", needsTarget = true, targetRule = "selfOrLower" },
    ["player.weapon_toggle"] = { label = "Give Weapon / Take Weapon", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.give_cartridge"] = { label = "Give Cartridge", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.take_cartridge"] = { label = "Take Cartridge", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.give_vehicle"] = { label = "Give Temporary Vehicle", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.destroy_vehicle"] = { label = "Destroy Temporary Vehicle", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.give_money"] = { label = "Give Money", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.take_money"] = { label = "Take Money", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.give_gold"] = { label = "Give Gold", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.take_gold"] = { label = "Take Gold", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.give_respect"] = { label = "Give Respect", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.take_respect"] = { label = "Take Respect", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.set_level"] = { label = "Set Level", category = "player", needsTarget = true, targetRule = "selfOrLower" },
    ["player.skill_set"] = { label = "Set Shooting Skill", category = "player", needsTarget = true, targetRule = "selfOrLower" },
    ["player.license_renew"] = { label = "Renew License", category = "player", needsTarget = true, targetRule = "selfOrLower" },
    ["player.godmode"] = { label = "GM / Normal", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.teleport_location"] = { label = "Teleport Player To Locations", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.inventory_add"] = { label = "Inventory Add", category = "player", needsTarget = true, targetRule = "lower" },
    ["player.inventory_remove"] = { label = "Inventory Remove", category = "player", needsTarget = true, targetRule = "lower" },

    -- Dashboard/self tools. These actions never trust client-side rank state.
    ["dashboard.freeze_self"] = { label = "Freeze / Unfreeze", category = "dashboard", needsTarget = false },
    ["dashboard.heal_armor"] = { label = "Heal / Armor Full", category = "dashboard", needsTarget = false },
    ["dashboard.respawn"] = { label = "Respawn", category = "dashboard", needsTarget = false },
    ["dashboard.kill_self"] = { label = "Kill", category = "dashboard", needsTarget = false, danger = true },
    ["dashboard.get_weapon"] = { label = "Get Weapon", category = "dashboard", needsTarget = false, needsValue = true },
    ["dashboard.get_all_weapons"] = { label = "Get All Weapon", category = "dashboard", needsTarget = false },
    ["dashboard.infinite_ammo"] = { label = "Infinite Ammo", category = "dashboard", needsTarget = false },
    ["dashboard.set_skin"] = { label = "Set Skin", category = "dashboard", needsTarget = false, needsValue = true },
    ["dashboard.spawn_vehicle"] = { label = "Spawn Vehicle", category = "dashboard", needsTarget = false, needsValue = true },
    ["dashboard.destroy_vehicle"] = { label = "Destroy Spawned Vehicle", category = "dashboard", needsTarget = false },
    ["dashboard.fix_damage"] = { label = "Fix Damage", category = "dashboard", needsTarget = false },
    ["dashboard.jetpack"] = { label = "Jetpack / Remove", category = "dashboard", needsTarget = false },
    ["dashboard.set_armor"] = { label = "Set Armor", category = "dashboard", needsTarget = false, needsValue = true },
    ["dashboard.set_health"] = { label = "Set Health", category = "dashboard", needsTarget = false, needsValue = true },
    ["dashboard.godmode"] = { label = "GM / Normal", category = "dashboard", needsTarget = false },
    ["dashboard.flight"] = { label = "Flight / Normal", category = "dashboard", needsTarget = false },
    ["dashboard.goto_map"] = { label = "Go To Map", category = "dashboard", needsTarget = false },
    ["dashboard.give_all_money"] = { label = "Give All Cash", category = "dashboard", needsTarget = false, needsValue = true },
    ["dashboard.give_all_gold"] = { label = "Give All Gold", category = "dashboard", needsTarget = false, needsValue = true },
    ["dashboard.give_all_respect"] = { label = "Give All Respect", category = "dashboard", needsTarget = false, needsValue = true }
}

SC_STAFF.ADMIN_ACTION_ORDER = {
    "player.goto",
    "player.gethere",
    "player.spectate",
    "player.spectate_stop",
    "player.freeze",
    "player.heal",
    "player.armor",
    "player.slap",
    "player.kill",
    "player.revive",
    "player.set_health",
    "player.set_armor",
    "player.set_dimension",
    "player.set_interior",
    "player.set_position",
    "player.set_skin",
    "player.remove_vehicle",
    "punishment.warn",
    "punishment.kick",
    "punishment.mute",
    "punishment.unmute",
    "punishment.jail",
    "punishment.unjail",
    "punishment.temp_ban",
    "punishment.perm_ban",
    "punishment.unban",
    "punishment.remove_warn",
    "player.respawn",
    "player.full_heal_armor",
    "player.weapon_toggle",
    "player.give_cartridge",
    "player.take_cartridge",
    "player.give_vehicle",
    "player.destroy_vehicle",
    "player.give_money",
    "player.take_money",
    "player.give_gold",
    "player.take_gold",
    "player.give_respect",
    "player.take_respect",
    "player.set_level",
    "player.skill_set",
    "player.license_renew",
    "player.godmode",
    "player.teleport_location",
    "player.inventory_add",
    "player.inventory_remove",
    "vehicle.fix",
    "vehicle.flip",
    "dashboard.freeze_self",
    "dashboard.heal_armor",
    "dashboard.respawn",
    "dashboard.kill_self",
    "dashboard.get_weapon",
    "dashboard.get_all_weapons",
    "dashboard.infinite_ammo",
    "dashboard.set_skin",
    "dashboard.spawn_vehicle",
    "dashboard.destroy_vehicle",
    "dashboard.fix_damage",
    "dashboard.jetpack",
    "dashboard.set_armor",
    "dashboard.set_health",
    "dashboard.godmode",
    "dashboard.flight",
    "dashboard.goto_map",
    "dashboard.give_all_money",
    "dashboard.give_all_gold",
    "dashboard.give_all_respect"
}

-- Non-action feature permissions can also be controlled by rank.
SC_STAFF.ADMIN_FEATURE_PERMISSIONS = {
    "player.info_sensitive"
}

-- Temporary baseline permissions. Final rank limits can be replaced later.
SC_STAFF.ADMIN_PERMISSIONS = {
    [1] = { ["*"] = true }, -- Founder

    [2] = { -- Owner
        ["player.info_sensitive"] = true,
        ["player.goto"] = true,
        ["player.gethere"] = true,
        ["player.spectate"] = true,
        ["player.spectate_stop"] = true,
        ["player.freeze"] = true,
        ["player.heal"] = true,
        ["player.armor"] = true,
        ["player.slap"] = true,
        ["player.kill"] = true,
        ["player.revive"] = true,
        ["player.set_health"] = true,
        ["player.set_armor"] = true,
        ["player.set_dimension"] = true,
        ["player.set_interior"] = true,
        ["player.set_position"] = true,
        ["player.set_skin"] = true,
        ["player.remove_vehicle"] = true,
        ["vehicle.fix"] = true,
        ["vehicle.flip"] = true,
        ["dashboard.freeze_self"] = true,
        ["dashboard.heal_armor"] = true,
        ["dashboard.respawn"] = true,
        ["dashboard.kill_self"] = true,
        ["dashboard.get_weapon"] = true,
        ["dashboard.get_all_weapons"] = true,
        ["dashboard.infinite_ammo"] = true,
        ["dashboard.set_skin"] = true,
        ["dashboard.spawn_vehicle"] = true,
        ["dashboard.set_armor"] = true,
        ["dashboard.set_health"] = true,
        ["dashboard.godmode"] = true,
        ["dashboard.flight"] = true,
        ["dashboard.goto_map"] = true
    },

    [3] = { -- Manager
        ["player.goto"] = true,
        ["player.gethere"] = true,
        ["player.spectate"] = true,
        ["player.spectate_stop"] = true,
        ["player.freeze"] = true,
        ["player.heal"] = true,
        ["player.armor"] = true,
        ["player.slap"] = true,
        ["player.kill"] = true,
        ["player.revive"] = true,
        ["player.set_health"] = true,
        ["player.set_armor"] = true,
        ["player.set_dimension"] = true,
        ["player.set_interior"] = true,
        ["player.set_position"] = true,
        ["player.set_skin"] = true,
        ["player.remove_vehicle"] = true,
        ["vehicle.fix"] = true,
        ["vehicle.flip"] = true,
        ["dashboard.freeze_self"] = true,
        ["dashboard.heal_armor"] = true,
        ["dashboard.respawn"] = true,
        ["dashboard.kill_self"] = true,
        ["dashboard.get_weapon"] = true,
        ["dashboard.get_all_weapons"] = true,
        ["dashboard.infinite_ammo"] = true,
        ["dashboard.set_skin"] = true,
        ["dashboard.spawn_vehicle"] = true,
        ["dashboard.set_armor"] = true,
        ["dashboard.set_health"] = true,
        ["dashboard.godmode"] = true,
        ["dashboard.flight"] = true,
        ["dashboard.goto_map"] = true
    },

    [4] = { -- Assistant
        ["player.goto"] = true,
        ["player.gethere"] = true,
        ["player.spectate"] = true,
        ["player.spectate_stop"] = true,
        ["player.freeze"] = true,
        ["player.heal"] = true,
        ["player.armor"] = true,
        ["player.slap"] = true,
        ["player.revive"] = true,
        ["player.set_health"] = true,
        ["player.set_armor"] = true,
        ["player.remove_vehicle"] = true,
        ["vehicle.fix"] = true,
        ["vehicle.flip"] = true,
        ["dashboard.freeze_self"] = true,
        ["dashboard.heal_armor"] = true,
        ["dashboard.respawn"] = true,
        ["dashboard.kill_self"] = true,
        ["dashboard.get_weapon"] = true,
        ["dashboard.get_all_weapons"] = true,
        ["dashboard.infinite_ammo"] = true,
        ["dashboard.set_skin"] = true,
        ["dashboard.spawn_vehicle"] = true,
        ["dashboard.set_armor"] = true,
        ["dashboard.set_health"] = true,
        ["dashboard.godmode"] = true,
        ["dashboard.flight"] = true,
        ["dashboard.goto_map"] = true
    },

    [5] = { -- Server Director (temporary baseline)
        ["player.goto"] = true,
        ["player.gethere"] = true,
        ["player.spectate"] = true,
        ["player.spectate_stop"] = true,
        ["player.freeze"] = true,
        ["player.heal"] = true,
        ["player.armor"] = true,
        ["player.revive"] = true,
        ["player.remove_vehicle"] = true,
        ["vehicle.fix"] = true,
        ["dashboard.freeze_self"] = true,
        ["dashboard.heal_armor"] = true,
        ["dashboard.respawn"] = true,
        ["dashboard.kill_self"] = true,
        ["dashboard.get_weapon"] = true,
        ["dashboard.get_all_weapons"] = true,
        ["dashboard.infinite_ammo"] = true,
        ["dashboard.set_skin"] = true,
        ["dashboard.set_armor"] = true,
        ["dashboard.set_health"] = true,
        ["dashboard.flight"] = true,
        ["dashboard.goto_map"] = true
    },

    [6] = { -- Server Advisor (temporary baseline)
        ["player.goto"] = true,
        ["player.spectate"] = true,
        ["player.spectate_stop"] = true,
        ["player.heal"] = true,
        ["dashboard.freeze_self"] = true,
        ["dashboard.heal_armor"] = true,
        ["dashboard.respawn"] = true,
        ["dashboard.kill_self"] = true,
        ["dashboard.get_weapon"] = true,
        ["dashboard.get_all_weapons"] = true,
        ["dashboard.infinite_ammo"] = true,
        ["dashboard.set_armor"] = true,
        ["dashboard.set_health"] = true,
        ["dashboard.flight"] = true,
        ["dashboard.goto_map"] = true
    },

    -- Temporary baseline only. Final per-rank permissions will be configured later.
    [7] = { -- Faction Warden
        ["player.goto"] = true,
        ["player.spectate"] = true,
        ["player.spectate_stop"] = true,
        ["player.heal"] = true,
        ["dashboard.freeze_self"] = true,
        ["dashboard.heal_armor"] = true,
        ["dashboard.respawn"] = true,
        ["dashboard.kill_self"] = true,
        ["dashboard.get_weapon"] = true,
        ["dashboard.get_all_weapons"] = true,
        ["dashboard.infinite_ammo"] = true,
        ["dashboard.set_armor"] = true,
        ["dashboard.set_health"] = true,
        ["dashboard.flight"] = true,
        ["dashboard.goto_map"] = true
    },

    [8] = { -- Support
        ["player.goto"] = true,
        ["player.spectate"] = true,
        ["player.spectate_stop"] = true,
        ["player.heal"] = true,
        ["dashboard.freeze_self"] = true,
        ["dashboard.heal_armor"] = true,
        ["dashboard.respawn"] = true,
        ["dashboard.kill_self"] = true,
        ["dashboard.get_weapon"] = true,
        ["dashboard.get_all_weapons"] = true,
        ["dashboard.infinite_ammo"] = true,
        ["dashboard.set_armor"] = true,
        ["dashboard.set_health"] = true,
        ["dashboard.flight"] = true,
        ["dashboard.goto_map"] = true
    },

    [9] = { -- Helper
        ["player.goto"] = true,
        ["player.spectate"] = true,
        ["player.spectate_stop"] = true,
        ["player.heal"] = true,
        ["dashboard.freeze_self"] = true,
        ["dashboard.heal_armor"] = true,
        ["dashboard.respawn"] = true,
        ["dashboard.kill_self"] = true,
        ["dashboard.get_weapon"] = true,
        ["dashboard.get_all_weapons"] = true,
        ["dashboard.infinite_ammo"] = true,
        ["dashboard.set_armor"] = true,
        ["dashboard.set_health"] = true,
        ["dashboard.flight"] = true,
        ["dashboard.goto_map"] = true
    }
}

-- Punishment permissions are temporary during panel development. Fine-grained
-- rank restrictions will be finalized later. Permanent Ban is intentionally
-- restricted now to Founder / Owner / Manager as requested.
for rank, permissions in pairs(SC_STAFF.ADMIN_PERMISSIONS) do
    if type(permissions) == "table" then
        local full = permissions["*"] == true
        if full or (tonumber(rank) or 99) >= 1 then
            permissions["punishment.warn"] = true
            permissions["punishment.kick"] = true
            permissions["punishment.mute"] = true
            permissions["punishment.unmute"] = true
            permissions["punishment.jail"] = true
            permissions["punishment.unjail"] = true
            permissions["punishment.temp_ban"] = true
            permissions["punishment.unban"] = true
            permissions["punishment.remove_warn"] = true
            if (tonumber(rank) or 99) <= 3 then
                permissions["punishment.perm_ban"] = true
            end
        end
    end
end

-- Inherit the existing temporary rank matrix for the new Player Tools.
-- Fine-grained limits can be changed here later without touching UI/server code.
local PLAYER_TOOL_PERMISSION_BASE = {
    ["player.respawn"] = "player.revive",
    ["player.full_heal_armor"] = "player.heal",
    ["player.weapon_toggle"] = "player.set_health",
    ["player.give_cartridge"] = "player.set_health",
    ["player.take_cartridge"] = "player.set_health",
    ["player.give_vehicle"] = "player.set_health",
    ["player.destroy_vehicle"] = "player.set_health",
    ["player.give_money"] = "player.set_health",
    ["player.take_money"] = "player.set_health",
    ["player.give_gold"] = "player.set_health",
    ["player.take_gold"] = "player.set_health",
    ["player.give_respect"] = "player.set_health",
    ["player.take_respect"] = "player.set_health",
    ["player.set_level"] = "player.set_health",
    ["player.skill_set"] = "player.set_health",
    ["player.license_renew"] = "player.set_health",
    ["player.godmode"] = "player.set_health",
    ["player.teleport_location"] = "player.gethere",
    ["player.inventory_add"] = "player.set_health",
    ["player.inventory_remove"] = "player.set_health"
}

for rank, permissions in pairs(SC_STAFF.ADMIN_PERMISSIONS) do
    if type(permissions) == "table" and permissions["*"] ~= true then
        for permission, basePermission in pairs(PLAYER_TOOL_PERMISSION_BASE) do
            if permissions[basePermission] == true then
                permissions[permission] = true
            end
        end
    end
end

-- Dashboard additions inherit existing temporary dashboard permissions until the final rank matrix is designed.
local DASHBOARD_PERMISSION_BASE = {
    ["dashboard.destroy_vehicle"] = "dashboard.spawn_vehicle",
    ["dashboard.fix_damage"] = "dashboard.spawn_vehicle",
    ["dashboard.jetpack"] = "dashboard.flight",
    ["dashboard.give_all_money"] = "dashboard.heal_armor",
    ["dashboard.give_all_gold"] = "dashboard.heal_armor",
    ["dashboard.give_all_respect"] = "dashboard.heal_armor"
}

for rank, permissions in pairs(SC_STAFF.ADMIN_PERMISSIONS) do
    if type(permissions) == "table" and permissions["*"] ~= true then
        for permission, basePermission in pairs(DASHBOARD_PERMISSION_BASE) do
            if permissions[basePermission] == true then
                permissions[permission] = true
            end
        end
    end
end

function SC_STAFF.hasAdminPanelAccess(rank)
    rank = tonumber(rank) or 0
    return rank > 0 and rank <= (SC_STAFF.ADMIN_PANEL.minRank or 6)
end

function SC_STAFF.hasAdminPermission(rank, permission)
    rank = tonumber(rank) or 0

    if not SC_STAFF.hasAdminPanelAccess(rank) then
        return false
    end

    local permissions = SC_STAFF.ADMIN_PERMISSIONS[rank]
    if type(permissions) ~= "table" then
        return false
    end

    return permissions["*"] == true or permissions[permission] == true
end

function SC_STAFF.getAdminPermissionsForRank(rank)
    local result = {}

    for _, permission in ipairs(SC_STAFF.ADMIN_ACTION_ORDER or {}) do
        if SC_STAFF.hasAdminPermission(rank, permission) then
            result[permission] = true
        end
    end

    for _, permission in ipairs(SC_STAFF.ADMIN_FEATURE_PERMISSIONS or {}) do
        if SC_STAFF.hasAdminPermission(rank, permission) then
            result[permission] = true
        end
    end

    return result
end
