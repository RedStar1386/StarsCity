--------------------------------------------------
-- StarsCity Automatic Custom Skins
-- SHARED CONFIG
--------------------------------------------------

SC_SKIN_CATEGORIES = {
    ped = {
        folders = { "ped_skins" },
        label = "Ped",
        alphaTransparency = false,
        allowCOL = true,
    },

    vehicle = {
        folders = { "vehicle_skins" },
        label = "Vehicle",
        -- Vehicle models often contain transparent windows.
        alphaTransparency = true,
        allowCOL = true,
    },

    weapon = {
        -- weapon_skins is the preferred folder name.
        -- gun_skins is also supported for backwards compatibility.
        folders = { "weapon_skins", "gun_skins" },
        label = "Weapon",
        alphaTransparency = false,
        allowCOL = false,
    },
}
