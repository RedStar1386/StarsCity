--------------------------------------------------
-- StarsCity Automatic Custom Skins
-- SERVER
--------------------------------------------------

local activeAssets = {}

local VALID_EXTENSIONS = {
    dff = true,
    txd = true,
    col = true,
}

local function getFolders(settings)
    if type(settings.folders) == "table" then
        return settings.folders
    end

    if type(settings.folder) == "string" then
        return { settings.folder }
    end

    return {}
end

local function scanFolder(category, settings, folder, discovered)
    local entries = pathListDir(folder) or {}

    for _, entry in ipairs(entries) do
        local fullPath = folder .. "/" .. entry

        if pathIsFile(fullPath) then
            local lowerEntry = string.lower(entry)
            local modelText, extension = string.match(lowerEntry, "^(%d+)%.([%a%d]+)$")
            local modelID = tonumber(modelText)

            if modelID and VALID_EXTENSIONS[extension] then
                if extension == "col" and settings.allowCOL == false then
                    outputDebugString(
                        "[sc_skins] Ignored unsupported COL for " .. category .. ": " .. fullPath,
                        2
                    )
                else
                    local asset = discovered[modelID]

                    if not asset then
                        asset = {
                            category = category,
                            modelID = modelID,
                            folder = folder,
                            dff = false,
                            txd = false,
                            col = false,
                        }
                        discovered[modelID] = asset
                    elseif asset.folder ~= folder then
                        outputDebugString(
                            "[sc_skins] Duplicate " .. category .. " model ID " .. modelID ..
                            " found in both '" .. asset.folder .. "' and '" .. folder ..
                            "'. Using '" .. asset.folder .. "'.",
                            2
                        )
                    end

                    if asset.folder == folder then
                        asset[extension] = true
                    end
                end
            elseif string.match(lowerEntry, "%.dff$")
                or string.match(lowerEntry, "%.txd$")
                or string.match(lowerEntry, "%.col$") then
                outputDebugString(
                    "[sc_skins] Ignored '" .. fullPath ..
                    "'. File name must be a numeric GTA/MTA model ID, e.g. 411.dff",
                    2
                )
            end
        end
    end
end

local function scanCategory(category, settings, manifest, seenModelIDs)
    local discovered = {}
    local folders = getFolders(settings)

    for _, folder in ipairs(folders) do
        scanFolder(category, settings, folder, discovered)
    end

    for modelID, data in pairs(discovered) do
        if seenModelIDs[modelID] then
            outputDebugString(
                "[sc_skins] Duplicate model ID " .. modelID ..
                " found in both '" .. seenModelIDs[modelID] ..
                "' and '" .. category .. "'. Only the first one will be used.",
                2
            )
        else
            seenModelIDs[modelID] = category
            manifest[#manifest + 1] = data
        end
    end
end

--------------------------------------------------
-- Scan all configured skin folders
--------------------------------------------------

local function scanAssets()
    local manifest = {}
    local seenModelIDs = {}
    local counts = {}

    for category, settings in pairs(SC_SKIN_CATEGORIES) do
        counts[category] = 0
        scanCategory(category, settings, manifest, seenModelIDs)
    end

    table.sort(manifest, function(a, b)
        if a.category == b.category then
            return a.modelID < b.modelID
        end

        return a.category < b.category
    end)

    activeAssets = manifest

    for _, asset in ipairs(activeAssets) do
        counts[asset.category] = (counts[asset.category] or 0) + 1

        local parts = {}
        if asset.col then parts[#parts + 1] = "COL" end
        if asset.txd then parts[#parts + 1] = "TXD" end
        if asset.dff then parts[#parts + 1] = "DFF" end

        outputDebugString(
            "[sc_skins] " .. asset.category ..
            " model " .. asset.modelID ..
            " detected in '" .. asset.folder ..
            "' [" .. table.concat(parts, ", ") .. "]"
        )
    end

    outputDebugString(
        "[sc_skins] Scan complete | Ped=" .. tostring(counts.ped or 0) ..
        " | Vehicle=" .. tostring(counts.vehicle or 0) ..
        " | Weapon=" .. tostring(counts.weapon or 0) ..
        " | Total=" .. tostring(#activeAssets)
    )
end

--------------------------------------------------
-- Send current manifest to one client
--------------------------------------------------

local function sendManifest(player)
    if not isElement(player) then
        return
    end

    triggerClientEvent(
        player,
        "sc_skins:receiveManifest",
        resourceRoot,
        activeAssets
    )
end

--------------------------------------------------
-- Client requests manifest
--------------------------------------------------

addEvent("sc_skins:requestManifest", true)
addEventHandler("sc_skins:requestManifest", resourceRoot, function()
    if not client then
        return
    end

    sendManifest(client)
end)

--------------------------------------------------
-- Player starts this resource
--------------------------------------------------

addEventHandler("onPlayerResourceStart", root, function(resource)
    if resource == getThisResource() then
        sendManifest(source)
    end
end)

--------------------------------------------------
-- Resource start
--------------------------------------------------

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[sc_skins] Server resource started.")
    scanAssets()
end)
