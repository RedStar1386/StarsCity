--------------------------------------------------
-- StarsCity Automatic Custom Skins
-- CLIENT
--------------------------------------------------

local loadedAssets = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function getAssetKey(category, modelID)
    return tostring(category) .. ":" .. tostring(modelID)
end

local function destroyLoadedElement(element)
    if element and isElement(element) then
        destroyElement(element)
    end
end

local function isAllowedFolder(settings, folder)
    if type(folder) ~= "string" then
        return false
    end

    if type(settings.folders) == "table" then
        for _, allowedFolder in ipairs(settings.folders) do
            if folder == allowedFolder then
                return true
            end
        end
        return false
    end

    return folder == settings.folder
end

--------------------------------------------------
-- Restore one replaced model
--------------------------------------------------

local function restoreAsset(key)
    local data = loadedAssets[key]

    if not data then
        return
    end

    if data.usedDFF or data.usedTXD then
        engineRestoreModel(data.modelID)
    end

    if data.usedCOL then
        engineRestoreCOL(data.modelID)
    end

    destroyLoadedElement(data.dff)
    destroyLoadedElement(data.txd)
    destroyLoadedElement(data.col)

    loadedAssets[key] = nil

    outputDebugString(
        "[sc_skins] Restored " .. data.category ..
        " model " .. tostring(data.modelID)
    )
end

local function restoreAllAssets()
    local keys = {}

    for key in pairs(loadedAssets) do
        keys[#keys + 1] = key
    end

    for _, key in ipairs(keys) do
        restoreAsset(key)
    end
end

local function rollbackState(state)
    if state.usedDFF or state.usedTXD then
        engineRestoreModel(state.modelID)
    end

    if state.usedCOL then
        engineRestoreCOL(state.modelID)
    end

    destroyLoadedElement(state.dff)
    destroyLoadedElement(state.txd)
    destroyLoadedElement(state.col)
end

--------------------------------------------------
-- Load / replace one model
--------------------------------------------------

local function loadAsset(asset)
    if type(asset) ~= "table" then
        return false
    end

    local category = tostring(asset.category or "")
    local modelID = tonumber(asset.modelID)
    local folder = tostring(asset.folder or "")
    local settings = SC_SKIN_CATEGORIES[category]

    if not settings or not modelID or not isAllowedFolder(settings, folder) then
        return false
    end

    local key = getAssetKey(category, modelID)

    if loadedAssets[key] then
        return true
    end

    local state = {
        category = category,
        modelID = modelID,
        folder = folder,
        col = nil,
        txd = nil,
        dff = nil,
        usedCOL = false,
        usedTXD = false,
        usedDFF = false,
    }

    --------------------------------------------------
    -- 1) COL (optional; disabled for weapon category)
    --------------------------------------------------

    if asset.col and settings.allowCOL ~= false then
        local colPath = folder .. "/" .. modelID .. ".col"

        if not fileExists(colPath) then
            outputDebugString("[sc_skins] Missing COL: " .. colPath, 1)
            return false
        end

        state.col = engineLoadCOL(colPath)

        if not state.col then
            outputDebugString("[sc_skins] Failed to load COL: " .. colPath, 1)
            return false
        end

        if not engineReplaceCOL(state.col, modelID) then
            outputDebugString(
                "[sc_skins] Failed to replace COL for model " .. modelID,
                1
            )
            destroyLoadedElement(state.col)
            return false
        end

        state.usedCOL = true
    end

    --------------------------------------------------
    -- 2) TXD (optional)
    --------------------------------------------------

    if asset.txd then
        local txdPath = folder .. "/" .. modelID .. ".txd"

        if not fileExists(txdPath) then
            outputDebugString("[sc_skins] Missing TXD: " .. txdPath, 1)
            rollbackState(state)
            return false
        end

        state.txd = engineLoadTXD(txdPath, true)

        if not state.txd then
            outputDebugString("[sc_skins] Failed to load TXD: " .. txdPath, 1)
            rollbackState(state)
            return false
        end

        if not engineImportTXD(state.txd, modelID) then
            outputDebugString(
                "[sc_skins] Failed to import TXD for model " .. modelID,
                1
            )
            rollbackState(state)
            return false
        end

        state.usedTXD = true
    end

    --------------------------------------------------
    -- 3) DFF (optional)
    --------------------------------------------------

    if asset.dff then
        local dffPath = folder .. "/" .. modelID .. ".dff"

        if not fileExists(dffPath) then
            outputDebugString("[sc_skins] Missing DFF: " .. dffPath, 1)
            rollbackState(state)
            return false
        end

        state.dff = engineLoadDFF(dffPath)

        if not state.dff then
            outputDebugString("[sc_skins] Failed to load DFF: " .. dffPath, 1)
            rollbackState(state)
            return false
        end

        if not engineReplaceModel(
            state.dff,
            modelID,
            settings.alphaTransparency == true
        ) then
            outputDebugString(
                "[sc_skins] Failed to replace DFF/model " .. modelID ..
                " from " .. dffPath,
                1
            )
            rollbackState(state)
            return false
        end

        state.usedDFF = true
    end

    if not state.usedCOL and not state.usedTXD and not state.usedDFF then
        rollbackState(state)
        return false
    end

    loadedAssets[key] = state

    local parts = {}
    if state.usedCOL then parts[#parts + 1] = "COL" end
    if state.usedTXD then parts[#parts + 1] = "TXD" end
    if state.usedDFF then parts[#parts + 1] = "DFF" end

    outputDebugString(
        "[sc_skins] Loaded " .. category ..
        " model " .. modelID ..
        " from '" .. folder ..
        "' [" .. table.concat(parts, ", ") .. "]"
    )

    return true
end

--------------------------------------------------
-- Sync manifest from server
--------------------------------------------------

addEvent("sc_skins:receiveManifest", true)
addEventHandler("sc_skins:receiveManifest", resourceRoot, function(manifest)
    if type(manifest) ~= "table" then
        return
    end

    local wanted = {}

    for _, asset in ipairs(manifest) do
        local category = tostring(asset.category or "")
        local modelID = tonumber(asset.modelID)
        local settings = SC_SKIN_CATEGORIES[category]

        if settings and modelID and isAllowedFolder(settings, tostring(asset.folder or "")) then
            wanted[getAssetKey(category, modelID)] = true
        end
    end

    local restoreKeys = {}

    for key in pairs(loadedAssets) do
        if not wanted[key] then
            restoreKeys[#restoreKeys + 1] = key
        end
    end

    for _, key in ipairs(restoreKeys) do
        restoreAsset(key)
    end

    local successCount = 0

    for _, asset in ipairs(manifest) do
        if loadAsset(asset) then
            successCount = successCount + 1
        end
    end

    outputDebugString(
        "[sc_skins] Manifest synced | Loaded=" .. successCount ..
        "/" .. tostring(#manifest)
    )
end)

--------------------------------------------------
-- Resource lifecycle
--------------------------------------------------

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[sc_skins] Client resource started. Requesting manifest...")
    triggerServerEvent("sc_skins:requestManifest", resourceRoot)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    outputDebugString("[sc_skins] Restoring original GTA models...")
    restoreAllAssets()
    outputDebugString("[sc_skins] All managed models restored.")
end)
