--------------------------------------------------
-- StarsCity Automatic Custom Skins
-- CLIENT
--------------------------------------------------

local loadedSkins = {}

--------------------------------------------------
-- Restore one skin
--------------------------------------------------

local function restoreSkin(skinID)

    --------------------------------------------------
    -- Restore original GTA model
    --------------------------------------------------

    local result = engineRestoreModel(skinID)

    --------------------------------------------------
    -- Destroy loaded DFF/TXD
    --------------------------------------------------

    if loadedSkins[skinID] then

        local data = loadedSkins[skinID]

        if data.dff and isElement(data.dff) then
            destroyElement(data.dff)
        end

        if data.txd and isElement(data.txd) then
            destroyElement(data.txd)
        end

    end

    loadedSkins[skinID] = nil

    outputDebugString(
        "[CustomSkins] Restored original Skin ID "
        .. skinID
        .. " | result="
        .. tostring(result)
    )

end

--------------------------------------------------
-- Restore all skins managed by this resource
--------------------------------------------------

local function restoreAllLoadedSkins()

    for skinID in pairs(loadedSkins) do

        restoreSkin(skinID)

    end

end

--------------------------------------------------
-- Load custom skin
--------------------------------------------------

local function loadCustomSkin(skinID)

    --------------------------------------------------
    -- Don't load twice
    --------------------------------------------------

    if loadedSkins[skinID] then
        return true
    end

    local dffPath = "skins/" .. skinID .. ".dff"
    local txdPath = "skins/" .. skinID .. ".txd"

    --------------------------------------------------
    -- Check files
    --------------------------------------------------

    if not fileExists(dffPath) then

        outputDebugString(
            "[CustomSkins] Missing DFF for ID "
            .. skinID,
            2
        )

        return false

    end

    if not fileExists(txdPath) then

        outputDebugString(
            "[CustomSkins] Missing TXD for ID "
            .. skinID,
            2
        )

        return false

    end

    --------------------------------------------------
    -- Load TXD
    --------------------------------------------------

    local txd = engineLoadTXD(
        txdPath,
        true
    )

    if not txd then

        outputDebugString(
            "[CustomSkins] ERROR loading TXD for ID "
            .. skinID,
            1
        )

        return false

    end

    --------------------------------------------------
    -- Import TXD
    --------------------------------------------------

    if not engineImportTXD(
        txd,
        skinID
    ) then

        outputDebugString(
            "[CustomSkins] ERROR importing TXD for ID "
            .. skinID,
            1
        )

        destroyElement(txd)

        return false

    end

    --------------------------------------------------
    -- Load DFF
    --------------------------------------------------

    local dff = engineLoadDFF(
        dffPath
    )

    if not dff then

        outputDebugString(
            "[CustomSkins] ERROR loading DFF for ID "
            .. skinID,
            1
        )

        destroyElement(txd)

        return false

    end

    --------------------------------------------------
    -- Replace model
    --------------------------------------------------

    if not engineReplaceModel(
        dff,
        skinID
    ) then

        outputDebugString(
            "[CustomSkins] ERROR replacing model for ID "
            .. skinID,
            1
        )

        destroyElement(dff)
        destroyElement(txd)

        return false

    end

    --------------------------------------------------
    -- Save
    --------------------------------------------------

    loadedSkins[skinID] = {

        dff = dff,
        txd = txd

    }

    outputDebugString(
        "[CustomSkins] Custom Skin ID "
        .. skinID
        .. " loaded successfully."
    )

    return true

end

--------------------------------------------------
-- Receive active skins from server
--------------------------------------------------

addEvent(
    "sc_skin:receiveActiveSkins",
    true
)

addEventHandler(
    "sc_skin:receiveActiveSkins",
    resourceRoot,

    function(activeSkinList)

        if type(activeSkinList) ~= "table" then
            return
        end

        --------------------------------------------------
        -- Convert list to lookup table
        --------------------------------------------------

        local activeSkins = {}

        for _, skinID in ipairs(activeSkinList) do

            skinID = tonumber(skinID)

            if skinID then

                activeSkins[skinID] = true

            end

        end

        --------------------------------------------------
        -- RESTORE skins that are no longer active
        --------------------------------------------------

        for skinID in pairs(loadedSkins) do

            if not activeSkins[skinID] then

                outputDebugString(
                    "[CustomSkins] Skin ID "
                    .. skinID
                    .. " is no longer active. Restoring original."
                )

                restoreSkin(skinID)

            end

        end

        --------------------------------------------------
        -- LOAD currently active skins
        --------------------------------------------------

        local loadedCount = 0

        for skinID in pairs(activeSkins) do

            if loadCustomSkin(skinID) then

                loadedCount = loadedCount + 1

            end

        end

        outputDebugString(
            "[CustomSkins] Active skins received: "
            .. tostring(#activeSkinList)
        )

        outputDebugString(
            "[CustomSkins] Custom skins loaded: "
            .. tostring(loadedCount)
        )

    end
)

--------------------------------------------------
-- Resource Start
--------------------------------------------------

addEventHandler(
    "onClientResourceStart",
    resourceRoot,

    function()

        outputDebugString(
            "[CustomSkins] Client resource started."
        )

        --------------------------------------------------
        -- Ask server for active skins
        --------------------------------------------------

        triggerServerEvent(
            "sc_skin:requestActiveSkins",
            resourceRoot
        )

    end
)

--------------------------------------------------
-- Resource Stop
--------------------------------------------------

addEventHandler(
    "onClientResourceStop",
    resourceRoot,

    function()

        outputDebugString(
            "[CustomSkins] Restoring original GTA models..."
        )

        restoreAllLoadedSkins()

        outputDebugString(
            "[CustomSkins] All custom skins restored."
        )

    end
)