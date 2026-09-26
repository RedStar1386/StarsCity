-- =========================================================
-- STARS CITY - ADMIN DASHBOARD
-- Dashboard-only self tools and contextual left panel
-- =========================================================

SC_ADMIN_DASHBOARD = SC_ADMIN_DASHBOARD or {}
local D = SC_ADMIN_DASHBOARD
local A = SC_ADMIN_CLIENT

local function isAdminHardFrozen()
    return SC_ADMIN_PLAYER_TOOLS
        and type(SC_ADMIN_PLAYER_TOOLS.isHardFreezeActive) == "function"
        and SC_ADMIN_PLAYER_TOOLS.isHardFreezeActive()
end

local function setDashboardControl(control, enabled)
    if SC_ADMIN_PLAYER_TOOLS and type(SC_ADMIN_PLAYER_TOOLS.setControlRespectingHardFreeze) == "function" then
        return SC_ADMIN_PLAYER_TOOLS.setControlRespectingHardFreeze(control, enabled)
    end
    toggleControl(control, enabled == true)
    return true
end

D.mode = "home"
D.buttonRects = {}
D.toolRects = {}
D.catalogRows = {}
D.catalogRect = nil
D.catalogScroll = 0
D.catalogVisibleRows = 0
D.catalogType = nil
D.catalogSort = "name_asc"
D.catalogData = {}
D.filteredCatalog = {}
D.mapMode = false
D.mapLastClickTick = 0
D.mapLastX = 0
D.mapLastY = 0
D.godModeEnabled = false
D.flightEnabled = false
D.flightActive = false
D.lastSpaceTick = 0
D.flightSpeed = 0.006
D.sanitizeGuard = false
D.virtualWeaponActive = false
D.virtualWeapons = {}
D.virtualWeaponIndex = 1
D.virtualWeaponLastSwitch = 0
D.elements = {
    toolSearch = nil,
    toolSort = nil,
    toolValue = nil,
    giveAllCash = nil,
    giveAllGold = nil,
    giveAllRespect = nil
}

local COLORS = {
    card = tocolor(27, 32, 42, 255),
    cardHover = tocolor(35, 42, 55, 255),
    header = tocolor(22, 26, 35, 255),
    accent = tocolor(225, 64, 84, 255),
    accentSoft = tocolor(225, 64, 84, 45),
    text = tocolor(245, 247, 250, 255),
    muted = tocolor(155, 165, 182, 255),
    good = tocolor(82, 210, 126, 255),
    warning = tocolor(245, 191, 66, 255),
    danger = tocolor(235, 78, 78, 255),
    line = tocolor(255, 255, 255, 20)
}

local CATALOG_SORTS = {
    { id = "name_asc", label = "Name (A-Z)" },
    { id = "name_desc", label = "Name (Z-A)" },
    { id = "id_asc", label = "ID (Low-High)" },
    { id = "id_desc", label = "ID (High-Low)" }
}

local function px(value, l)
    return value * l.scale
end

local function pointInRect(x, y, rect)
    return rect and x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function drawText(text, x, y, w, h, color, size, font, alignX, alignY, clip)
    dxDrawText(
        tostring(text or ""),
        x, y, x + w, y + h,
        color or COLORS.text,
        size or 1,
        font or "default",
        alignX or "left",
        alignY or "center",
        clip == true,
        false,
        false,
        false
    )
end

local function trim(value)
    local result = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return result
end

local function getCursorPixel()
    if not isCursorShowing() then
        return nil, nil
    end
    local cx, cy = getCursorPosition()
    if not cx or not cy then
        return nil, nil
    end
    local sw, sh = guiGetScreenSize()
    return cx * sw, cy * sh
end

function D.createUI()
    local e = D.elements
    if isElement(e.toolSearch) then
        return
    end

    e.toolSearch = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.toolSearch, 40)

    e.toolSort = guiCreateComboBox(0, 0, 1, 1, "Name (A-Z)", false)
    for _, option in ipairs(CATALOG_SORTS) do
        guiComboBoxAddItem(e.toolSort, option.label)
    end
    guiComboBoxSetSelected(e.toolSort, 0)

    e.toolValue = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.toolValue, 48)

    e.giveAllCash = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.giveAllCash, 9)
    e.giveAllGold = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.giveAllGold, 6)
    e.giveAllRespect = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.giveAllRespect, 4)

    guiSetVisible(e.toolSearch, false)
    guiSetVisible(e.toolSort, false)
    guiSetVisible(e.toolValue, false)
    guiSetVisible(e.giveAllCash, false)
    guiSetVisible(e.giveAllGold, false)
    guiSetVisible(e.giveAllRespect, false)
end

local function setToolGUIVisible(searchVisible, sortVisible, valueVisible)
    D.createUI()
    guiSetVisible(D.elements.toolSearch, searchVisible == true)
    guiSetVisible(D.elements.toolSort, sortVisible == true)
    guiSetVisible(D.elements.toolValue, valueVisible == true)
    guiSetVisible(D.elements.giveAllCash, false)
    guiSetVisible(D.elements.giveAllGold, false)
    guiSetVisible(D.elements.giveAllRespect, false)
end

local function setGiveAllVisible(visible)
    D.createUI()
    guiSetVisible(D.elements.toolSearch, false)
    guiSetVisible(D.elements.toolSort, false)
    guiSetVisible(D.elements.toolValue, false)
    guiSetVisible(D.elements.giveAllCash, visible == true)
    guiSetVisible(D.elements.giveAllGold, visible == true)
    guiSetVisible(D.elements.giveAllRespect, visible == true)
end

local function setVirtualWeaponControls(enabled)
    -- Disable GTA's native slot-only cycling while the admin virtual inventory
    -- is active. The virtual cycler below takes over these controls.
    setDashboardControl("next_weapon", not enabled)
    setDashboardControl("previous_weapon", not enabled)
end

local function findVirtualWeaponIndex(weaponID)
    weaponID = tonumber(weaponID)
    for index, id in ipairs(D.virtualWeapons or {}) do
        if tonumber(id) == weaponID then
            return index
        end
    end
    return nil
end

local function setVirtualWeaponInventory(enabled, weapons, currentWeapon)
    D.virtualWeaponActive = enabled == true
    D.virtualWeapons = {}
    D.virtualWeaponIndex = 1

    if D.virtualWeaponActive and type(weapons) == "table" then
        local allowed = {}
        for _, rawID in ipairs(SC_STAFF.ADMIN_WEAPON_IDS or {}) do
            allowed[tonumber(rawID)] = true
        end
        local seen = {}
        for _, rawID in ipairs(weapons) do
            local id = tonumber(rawID)
            if id and allowed[id] and not seen[id] then
                seen[id] = true
                D.virtualWeapons[#D.virtualWeapons + 1] = id
            end
        end
        if #D.virtualWeapons == 0 then
            D.virtualWeaponActive = false
        end
    end

    local selectedIndex = findVirtualWeaponIndex(currentWeapon)
    if selectedIndex then
        D.virtualWeaponIndex = selectedIndex
    end
    setVirtualWeaponControls(D.virtualWeaponActive)
end

local function isKeyBoundToControl(key, controlName)
    if type(getBoundKeys) ~= "function" then
        return false
    end
    local bound = getBoundKeys(controlName)
    return type(bound) == "table" and bound[key] ~= nil
end

local function cycleVirtualWeapon(direction)
    if not D.virtualWeaponActive or #D.virtualWeapons == 0 then
        return false
    end

    local now = getTickCount()
    if now - (D.virtualWeaponLastSwitch or 0) < 90 then
        return true
    end
    D.virtualWeaponLastSwitch = now

    local currentID = tonumber(getPedWeapon(localPlayer)) or 0
    local currentIndex = findVirtualWeaponIndex(currentID) or D.virtualWeaponIndex or 1
    local count = #D.virtualWeapons
    local nextIndex = ((currentIndex - 1 + direction) % count) + 1
    local weaponID = D.virtualWeapons[nextIndex]

    D.virtualWeaponIndex = nextIndex
    triggerServerEvent("scAdminEquipVirtualWeapon", resourceRoot, weaponID)
    return true
end

function D.closeUI()
    if D.mapMode then
        forcePlayerMap(false)
    end
    D.mapMode = false
    D.flightActive = false
    setDashboardControl("jump", true)
    for _, element in pairs(D.elements) do
        if isElement(element) then
            guiSetVisible(element, false)
        end
    end
end

function D.reset()
    D.mode = "home"
    D.catalogType = nil
    D.catalogScroll = 0
    D.catalogSort = "name_asc"
    D.buttonRects = {}
    D.toolRects = {}
    D.catalogRows = {}
    if isElement(D.elements.toolSearch) then
        guiSetText(D.elements.toolSearch, "")
        guiComboBoxSetSelected(D.elements.toolSort, 0)
        guiSetText(D.elements.toolValue, "")
        guiSetText(D.elements.giveAllCash, "")
        guiSetText(D.elements.giveAllGold, "")
        guiSetText(D.elements.giveAllRespect, "")
    end
end

function D.isMapMode()
    return D.mapMode == true
end

function D.cancelMapMode()
    if not D.mapMode then
        return false
    end
    D.mapMode = false
    forcePlayerMap(false)
    showCursor(true)
    return true
end

local function buildSkinCatalog()
    local result = {}
    local models = {}

    if type(getValidPedModels) == "function" then
        models = getValidPedModels() or {}
    else
        for id = 0, 312 do
            if type(isValidPedModel) ~= "function" or isValidPedModel(id) then
                models[#models + 1] = id
            end
        end
    end

    for _, id in ipairs(models) do
        id = tonumber(id)
        if id then
            result[#result + 1] = { id = id, name = "Skin " .. tostring(id), preview = "None" }
        end
    end

    return result
end

local function buildVehicleCatalog()
    local result = {}
    for id = 400, 611 do
        local valid = type(isValidVehicleModel) ~= "function" or isValidVehicleModel(id)
        if valid then
            local name = getVehicleNameFromModel(id)
            if name and tostring(name) ~= "" then
                result[#result + 1] = { id = id, name = tostring(name), preview = "None" }
            end
        end
    end
    return result
end

local function buildWeaponCatalog()
    local result = {}
    for _, id in ipairs(SC_STAFF.ADMIN_WEAPON_IDS or {}) do
        id = tonumber(id)
        if id then
            local name = nil
            if type(getWeaponNameFromID) == "function" then
                name = getWeaponNameFromID(id)
            end
            if not name or tostring(name) == "" then
                name = "Weapon " .. tostring(id)
            end
            result[#result + 1] = {
                id = id,
                name = tostring(name),
                preview = "None"
            }
        end
    end
    return result
end

local function getCatalogData(catalogType)
    if D.catalogData[catalogType] then
        return D.catalogData[catalogType]
    end

    local data = {}
    if catalogType == "skins" then
        data = buildSkinCatalog()
    elseif catalogType == "vehicles" then
        data = buildVehicleCatalog()
    elseif catalogType == "weapons" then
        data = buildWeaponCatalog()
    end

    D.catalogData[catalogType] = data
    return data
end

function D.filterCatalog()
    local sourceData = getCatalogData(D.catalogType)
    local needle = ""
    if isElement(D.elements.toolSearch) then
        needle = string.lower(trim(guiGetText(D.elements.toolSearch)))
    end

    local rows = {}
    for _, row in ipairs(sourceData or {}) do
        local haystack = string.lower(tostring(row.name or "") .. " " .. tostring(row.id or ""))
        if needle == "" or string.find(haystack, needle, 1, true) then
            rows[#rows + 1] = row
        end
    end

    table.sort(rows, function(a, b)
        if D.catalogSort == "name_desc" then
            local an, bn = string.lower(a.name), string.lower(b.name)
            if an ~= bn then return an > bn end
        elseif D.catalogSort == "id_asc" then
            if a.id ~= b.id then return a.id < b.id end
        elseif D.catalogSort == "id_desc" then
            if a.id ~= b.id then return a.id > b.id end
        else
            local an, bn = string.lower(a.name), string.lower(b.name)
            if an ~= bn then return an < bn end
        end
        return a.id < b.id
    end)

    D.filteredCatalog = rows
    D.catalogScroll = math.max(0, math.min(D.catalogScroll or 0, math.max(0, #rows - math.max(D.catalogVisibleRows, 1))))
end

local function setMode(mode)
    D.mode = mode or "home"
    D.toolRects = {}
    D.catalogRows = {}
    D.catalogScroll = 0

    if mode == "skins" then
        D.catalogType = "skins"
        guiSetText(D.elements.toolSearch, "")
        guiComboBoxSetSelected(D.elements.toolSort, 0)
        D.catalogSort = "name_asc"
        D.filterCatalog()
    elseif mode == "vehicles" then
        D.catalogType = "vehicles"
        guiSetText(D.elements.toolSearch, "")
        guiComboBoxSetSelected(D.elements.toolSort, 0)
        D.catalogSort = "name_asc"
        D.filterCatalog()
    elseif mode == "weapons" then
        D.catalogType = "weapons"
        guiSetText(D.elements.toolSearch, "")
        guiComboBoxSetSelected(D.elements.toolSort, 0)
        D.catalogSort = "name_asc"
        D.filterCatalog()
    else
        D.catalogType = nil
    end

    if mode == "goto_player" or mode == "gethere" or mode == "setarmor" or mode == "sethealth" then
        guiSetText(D.elements.toolValue, "")
        guiBringToFront(D.elements.toolValue)
    elseif mode == "give_all" then
        guiSetText(D.elements.giveAllCash, "")
        guiSetText(D.elements.giveAllGold, "")
        guiSetText(D.elements.giveAllRespect, "")
    end
end

local function getAdminState()
    local state = A.snapshot and A.snapshot.adminState
    return type(state) == "table" and state or {}
end

local function hasPermission(permission)
    return A.permissions and A.permissions[permission] == true
end

local function sendDashboardAction(actionName, data)
    if A.pending then
        return
    end
    if not hasPermission(actionName) then
        outputChatBox("[StarsCity] Shoma Dastresi Be In Action Nadarid.", 255, 90, 90)
        return
    end

    A.setPending(true)
    triggerServerEvent("scAdminExecuteDashboardAction", resourceRoot, actionName, data or {})
end

local function resolvePlayerQuery(query)
    query = trim(query)
    if query == "" or not A.snapshot or type(A.snapshot.players) ~= "table" then
        return nil
    end

    local numericID = tonumber(query)
    local lowered = string.lower(query)
    for _, player in ipairs(A.snapshot.players) do
        if numericID and tonumber(player.id) == numericID then
            return tonumber(player.id)
        end
        if string.lower(tostring(player.username or "")) == lowered then
            return tonumber(player.id)
        end
    end

    return nil
end

local function sendTargetAction(actionName)
    local query = guiGetText(D.elements.toolValue) or ""
    local targetID = resolvePlayerQuery(query)
    if not targetID then
        outputChatBox("[StarsCity] Player Ba In ID Ya Username Peyda Nashod.", 255, 90, 90)
        return
    end

    if not hasPermission(actionName) then
        outputChatBox("[StarsCity] Shoma Dastresi Be In Action Nadarid.", 255, 90, 90)
        return
    end

    A.setPending(true)
    A.lastSubmittedAction = actionName
    triggerServerEvent("scAdminExecuteAction", resourceRoot, actionName, targetID, {})
end

local function startMapMode()
    if not hasPermission("dashboard.goto_map") then
        outputChatBox("[StarsCity] Shoma Dastresi Be Map Teleport Nadarid.", 255, 90, 90)
        return
    end

    setToolGUIVisible(false, false, false)
    D.mapMode = true
    D.mapLastClickTick = 0
    forcePlayerMap(true)
    showCursor(true)
    outputChatBox("[StarsCity] Baraye Teleport, Roye Map Double Click Konid. ESC = Cancel", 245, 191, 66)
end

local function drawSmallCard(x, y, w, h, title, value, l)
    dxDrawRectangle(x, y, w, h, COLORS.card)
    drawText(title, x + px(12, l), y + px(6, l), w - px(24, l), px(20, l), COLORS.muted, 0.72 * l.scale, "default-bold")
    drawText(value, x + px(12, l), y + px(24, l), w - px(24, l), h - px(28, l), COLORS.text, 1.15 * l.scale, "default-bold")
end

local function drawToolHome(x, y, w, h, l)
    setToolGUIVisible(false, false, false)
    dxDrawRectangle(x, y, w, h, COLORS.card)
    drawText("Dashboard Tools", x + px(18, l), y + px(14, l), w - px(36, l), px(32, l), COLORS.text, 1.0 * l.scale, "default-bold")
    drawText(
        "Select one of the admin capabilities on the right. Contextual controls will open here without showing the player table.",
        x + px(18, l), y + px(58, l), w - px(36, l), px(100, l), COLORS.muted, 0.88 * l.scale, "default", "left", "top", true
    )
end

local function drawChoiceRow(label, x, y, w, h, l, mx, my, id, enabled)
    local rect = { x = x, y = y, w = w, h = h, id = id, enabled = enabled ~= false }
    local hover = rect.enabled and mx and pointInRect(mx, my, rect)
    dxDrawRectangle(x, y, w, h, hover and COLORS.cardHover or COLORS.card)
    dxDrawRectangle(x, y, px(4, l), h, rect.enabled and COLORS.accent or COLORS.muted)
    drawText(label, x + px(15, l), y, w - px(30, l), h, rect.enabled and COLORS.text or COLORS.muted, 0.84 * l.scale, "default-bold")
    D.toolRects[#D.toolRects + 1] = rect
end

local function positionValueEdit(x, y, w, l, numeric)
    setToolGUIVisible(false, false, true)
    guiSetPosition(D.elements.toolValue, x, y, false)
    guiSetSize(D.elements.toolValue, w, px(38, l), false)
    if numeric then
        guiEditSetMaxLength(D.elements.toolValue, 3)
    else
        guiEditSetMaxLength(D.elements.toolValue, 48)
    end
end

local function drawInputMode(x, y, w, h, l, mx, my, title, hint, submitLabel, mode)
    dxDrawRectangle(x, y, w, h, COLORS.card)
    drawText(title, x + px(18, l), y + px(14, l), w - px(36, l), px(30, l), COLORS.text, 1.0 * l.scale, "default-bold")
    drawText(hint, x + px(18, l), y + px(51, l), w - px(36, l), px(36, l), COLORS.muted, 0.80 * l.scale, "default", "left", "center", true)

    local inputY = y + px(92, l)
    positionValueEdit(x + px(18, l), inputY, w - px(36, l), l, mode == "setarmor" or mode == "sethealth")

    local gap = px(10, l)
    local buttonW = (w - px(36, l) - gap) / 2
    local buttonY = inputY + px(50, l)
    local submitRect = { x = x + px(18, l), y = buttonY, w = buttonW, h = px(40, l), id = "submit_input", enabled = true }
    local cancelRect = { x = submitRect.x + buttonW + gap, y = buttonY, w = buttonW, h = px(40, l), id = "cancel_input", enabled = true }

    dxDrawRectangle(submitRect.x, submitRect.y, submitRect.w, submitRect.h, mx and pointInRect(mx, my, submitRect) and COLORS.cardHover or COLORS.accentSoft)
    drawText(submitLabel, submitRect.x, submitRect.y, submitRect.w, submitRect.h, COLORS.text, 0.86 * l.scale, "default-bold", "center")
    dxDrawRectangle(cancelRect.x, cancelRect.y, cancelRect.w, cancelRect.h, mx and pointInRect(mx, my, cancelRect) and COLORS.cardHover or tocolor(255,255,255,10))
    drawText("Cancel", cancelRect.x, cancelRect.y, cancelRect.w, cancelRect.h, COLORS.muted, 0.86 * l.scale, "default-bold", "center")

    D.toolRects[#D.toolRects + 1] = submitRect
    D.toolRects[#D.toolRects + 1] = cancelRect
end

local function drawGotoMenu(x, y, w, h, l, mx, my)
    setToolGUIVisible(false, false, false)
    dxDrawRectangle(x, y, w, h, COLORS.card)
    drawText("Go To Tools", x + px(18, l), y + px(14, l), w - px(36, l), px(32, l), COLORS.text, 1.0 * l.scale, "default-bold", "center")
    local rowY = y + px(58, l)
    drawChoiceRow("GoTo: Player ID / Username", x + px(18, l), rowY, w - px(36, l), px(48, l), l, mx, my, "goto_player", hasPermission("player.goto"))
    rowY = rowY + px(58, l)
    drawChoiceRow("GoTo: Map", x + px(18, l), rowY, w - px(36, l), px(48, l), l, mx, my, "goto_map", hasPermission("dashboard.goto_map"))
    rowY = rowY + px(58, l)
    drawChoiceRow("More GoTo tools can be added here later", x + px(18, l), rowY, w - px(36, l), px(48, l), l, mx, my, "noop", false)
end

local function drawCatalog(x, y, w, h, l, mx, my)
    local isSkin = D.catalogType == "skins"
    local isVehicle = D.catalogType == "vehicles"
    local isWeapon = D.catalogType == "weapons"
    local title = isSkin and "Skin List" or (isVehicle and "Vehicle List" or "Weapon List")
    local actionLabel = isSkin and "Set" or (isVehicle and "Spawn" or "Get")

    dxDrawRectangle(x, y, w, h, COLORS.card)
    drawText(title, x + px(16, l), y + px(10, l), w - px(32, l), px(28, l), COLORS.text, 1.0 * l.scale, "default-bold", "center")

    setToolGUIVisible(true, true, false)
    local searchY = y + px(44, l)
    local sortW = px(164, l)
    local gap = px(8, l)
    local searchW = w - px(32, l) - sortW - gap
    guiSetPosition(D.elements.toolSearch, x + px(16, l), searchY, false)
    guiSetSize(D.elements.toolSearch, searchW, px(36, l), false)
    guiSetPosition(D.elements.toolSort, x + px(16, l) + searchW + gap, searchY, false)
    guiSetSize(D.elements.toolSort, sortW, px(120, l), false)

    local tableY = searchY + px(50, l)
    if isWeapon then
        local allRowH = px(42, l)
        local allRect = {
            x = x + px(16, l),
            y = tableY,
            w = w - px(32, l),
            h = allRowH,
            id = "weapon_get_all",
            enabled = hasPermission("dashboard.get_all_weapons") and not A.pending
        }
        local allHover = allRect.enabled and mx and pointInRect(mx, my, allRect)
        dxDrawRectangle(allRect.x, allRect.y, allRect.w, allRect.h, allHover and COLORS.cardHover or COLORS.accentSoft)
        dxDrawRectangle(allRect.x, allRect.y, px(4,l), allRect.h, allRect.enabled and COLORS.accent or COLORS.muted)
        drawText("Get All Weapon", allRect.x, allRect.y, allRect.w, allRect.h, allRect.enabled and COLORS.text or COLORS.muted, 0.80 * l.scale, "default-bold", "center")
        D.toolRects[#D.toolRects + 1] = allRect
        tableY = tableY + allRowH + px(8, l)
    end
    local tableH = h - (tableY - y) - px(14, l)
    local headerH = px(36, l)
    local rowH = px(42, l)
    D.catalogRect = { x = x + px(12, l), y = tableY, w = w - px(24, l), h = tableH }
    D.catalogRows = {}

    local tx, tw = D.catalogRect.x, D.catalogRect.w
    dxDrawRectangle(tx, tableY, tw, tableH, tocolor(10, 12, 17, 245))
    dxDrawRectangle(tx, tableY, tw, headerH, COLORS.header)

    local columns = {
        { label = "Preview", ratio = 0.21, align = "center" },
        { label = "Name", ratio = 0.39, align = "left" },
        { label = "ID", ratio = 0.14, align = "center" },
        { label = actionLabel, ratio = 0.26, align = "center" }
    }

    local cx = tx
    for i, col in ipairs(columns) do
        local cw = tw * col.ratio
        drawText(col.label, cx + (col.align == "left" and px(8,l) or 0), tableY, cw - px(4,l), headerH, COLORS.text, 0.75 * l.scale, "default-bold", col.align, "center", true)
        if i < #columns then
            dxDrawRectangle(cx + cw - px(1,l), tableY, px(1,l), tableH, COLORS.line)
        end
        cx = cx + cw
    end

    local usableH = tableH - headerH
    D.catalogVisibleRows = math.max(1, math.floor(usableH / rowH))
    local rows = D.filteredCatalog or {}
    local maxOffset = math.max(0, #rows - D.catalogVisibleRows)
    D.catalogScroll = math.max(0, math.min(D.catalogScroll or 0, maxOffset))

    if #rows == 0 then
        drawText("No items found.", tx, tableY + headerH, tw, usableH, COLORS.muted, 0.85 * l.scale, "default", "center", "center")
        return
    end

    local first = D.catalogScroll + 1
    local last = math.min(#rows, first + D.catalogVisibleRows - 1)
    local rowY = tableY + headerH

    for index = first, last do
        local row = rows[index]
        if (index - first) % 2 == 1 then
            dxDrawRectangle(tx, rowY, tw, rowH, tocolor(255,255,255,7))
        end
        local cellX = tx
        local previewW = tw * columns[1].ratio
        local square = math.min(px(30,l), rowH - px(8,l))
        local sx = cellX + (previewW - square) / 2
        local sy = rowY + (rowH - square) / 2
        dxDrawRectangle(sx, sy, square, square, tocolor(255,255,255,9))
        drawText("None", sx, sy, square, square, COLORS.muted, 0.60 * l.scale, "default", "center", "center", true)
        cellX = cellX + previewW

        local nameW = tw * columns[2].ratio
        drawText(row.name, cellX + px(8,l), rowY, nameW - px(12,l), rowH, COLORS.text, 0.74 * l.scale, "default", "left", "center", true)
        cellX = cellX + nameW

        local idW = tw * columns[3].ratio
        drawText(row.id, cellX, rowY, idW, rowH, COLORS.text, 0.76 * l.scale, "default", "center", "center", true)
        cellX = cellX + idW

        local actionW = tw * columns[4].ratio
        local bw = actionW - px(18,l)
        local bh = rowH - px(10,l)
        local rowActionLabel = actionLabel
        local rowEnabled = true
        local destroyVehicle = false
        if isVehicle then
            local state = (A.snapshot and type(A.snapshot.adminState) == "table") and A.snapshot.adminState or {}
            local activeModel = tonumber(state.spawnedVehicleModel)
            if activeModel then
                if activeModel == tonumber(row.id) then
                    rowActionLabel = "Destroy"
                    destroyVehicle = true
                else
                    rowActionLabel = "Active"
                    rowEnabled = false
                end
            end
        end
        local br = { x = cellX + px(9,l), y = rowY + px(5,l), w = bw, h = bh, id = "catalog_action", item = row, enabled = rowEnabled, destroyVehicle = destroyVehicle }
        local hover = rowEnabled and mx and pointInRect(mx, my, br)
        dxDrawRectangle(br.x, br.y, br.w, br.h, rowEnabled and (hover and COLORS.cardHover or COLORS.accentSoft) or tocolor(24,28,36,190))
        drawText(rowActionLabel, br.x, br.y, br.w, br.h, rowEnabled and COLORS.text or COLORS.muted, 0.72 * l.scale, "default-bold", "center")
        D.catalogRows[#D.catalogRows + 1] = br

        dxDrawRectangle(tx, rowY + rowH - px(1,l), tw, px(1,l), COLORS.line)
        rowY = rowY + rowH
    end
end

local function drawGiveAll(x, y, w, h, l, mx, my)
    setGiveAllVisible(true)
    dxDrawRectangle(x, y, w, h, COLORS.card)
    drawText("Give All", x + px(18, l), y + px(14, l), w - px(36, l), px(30, l), COLORS.text, 1.0 * l.scale, "default-bold")
    drawText("Give a value to every currently online logged-in player.", x + px(18, l), y + px(48, l), w - px(36, l), px(34, l), COLORS.muted, 0.78 * l.scale, "default", "left", "center", true)

    local rows = {
        { label = "Give All Cash", edit = D.elements.giveAllCash, action = "dashboard.give_all_money", hint = "10000 - 500000000" },
        { label = "Give All Gold", edit = D.elements.giveAllGold, action = "dashboard.give_all_gold", hint = "1000 - 500000" },
        { label = "Give All Respect", edit = D.elements.giveAllRespect, action = "dashboard.give_all_respect", hint = "1 - 1000" }
    }

    local rowY = y + px(96, l)
    for i, row in ipairs(rows) do
        drawText(row.label, x + px(18, l), rowY, px(150, l), px(24, l), COLORS.text, 0.80 * l.scale, "default-bold")
        drawText(row.hint, x + px(18, l), rowY + px(24, l), px(150, l), px(20, l), COLORS.muted, 0.66 * l.scale, "default")

        guiSetPosition(row.edit, x + px(176, l), rowY + px(3, l), false)
        guiSetSize(row.edit, px(184, l), px(38, l), false)

        local rect = {
            x = x + w - px(132, l),
            y = rowY + px(2, l),
            w = px(112, l),
            h = px(40, l),
            id = "give_all_submit",
            action = row.action,
            edit = row.edit,
            enabled = hasPermission(row.action) and not A.pending
        }
        local hover = rect.enabled and mx and pointInRect(mx, my, rect)
        dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, rect.enabled and (hover and COLORS.cardHover or COLORS.accentSoft) or tocolor(24,28,36,190))
        drawText("Give", rect.x, rect.y, rect.w, rect.h, rect.enabled and COLORS.text or COLORS.muted, 0.80 * l.scale, "default-bold", "center")
        D.toolRects[#D.toolRects + 1] = rect

        rowY = rowY + px(74, l)
    end

    local backRect = { x = x + px(18, l), y = y + h - px(58, l), w = w - px(36, l), h = px(40, l), id = "cancel_input", enabled = true }
    dxDrawRectangle(backRect.x, backRect.y, backRect.w, backRect.h, mx and pointInRect(mx, my, backRect) and COLORS.cardHover or tocolor(255,255,255,10))
    drawText("Back", backRect.x, backRect.y, backRect.w, backRect.h, COLORS.muted, 0.82 * l.scale, "default-bold", "center")
    D.toolRects[#D.toolRects + 1] = backRect
end

local function drawLeftPane(x, y, w, h, l, mx, my)
    D.toolRects = {}
    D.catalogRows = {}
    D.catalogRect = nil

    if D.mode == "goto" then
        drawGotoMenu(x, y, w, h, l, mx, my)
    elseif D.mode == "goto_player" then
        drawInputMode(x, y, w, h, l, mx, my, "GoTo: Player", "Enter exact Player ID or server Username.", "Go", "goto_player")
    elseif D.mode == "gethere" then
        drawInputMode(x, y, w, h, l, mx, my, "Get Here", "Enter exact Player ID or server Username.", "Get", "gethere")
    elseif D.mode == "setarmor" then
        drawInputMode(x, y, w, h, l, mx, my, "Set Armor", "Only numbers from 1 to 100 are accepted.", "Set", "setarmor")
    elseif D.mode == "sethealth" then
        drawInputMode(x, y, w, h, l, mx, my, "Set Health", "Only numbers from 1 to 100 are accepted.", "Set", "sethealth")
    elseif D.mode == "skins" or D.mode == "vehicles" or D.mode == "weapons" then
        drawCatalog(x, y, w, h, l, mx, my)
    elseif D.mode == "give_all" then
        drawGiveAll(x, y, w, h, l, mx, my)
    else
        drawToolHome(x, y, w, h, l)
    end
end

local DASHBOARD_BUTTONS = {
    { mode = "goto", label = "GoTo", permission = "player.goto" },
    { mode = "gethere", label = "Get Here", permission = "player.gethere" },
    { action = "dashboard.freeze_self", label = "Freeze / Unfreeze" },
    { action = "dashboard.heal_armor", label = "Heal / Armor Full" },
    { action = "dashboard.respawn", label = "Respawn" },
    { action = "dashboard.kill_self", label = "Kill" },
    { mode = "skins", label = "Set Skin", permission = "dashboard.set_skin" },
    { mode = "vehicles", label = "Spawn Vehicle", permission = "dashboard.spawn_vehicle" },
    { action = "dashboard.fix_damage", label = "Fix Damage" },
    { action = "dashboard.jetpack", label = "Jetpack" },
    { mode = "weapons", label = "Get Weapon", permission = "dashboard.get_weapon" },
    { action = "dashboard.infinite_ammo", label = "Infinite Ammo" },
    { mode = "setarmor", label = "Set Armor", permission = "dashboard.set_armor" },
    { mode = "sethealth", label = "Set Health", permission = "dashboard.set_health" },
    { action = "dashboard.godmode", label = "GM / Normal" },
    { action = "dashboard.flight", label = "Flight / Normal" },
    { mode = "give_all", label = "Give All", permission = "dashboard.give_all_money" }
}

local function drawRightDashboard(x, y, w, h, l, mx, my)
    D.buttonRects = {}
    local state = getAdminState()

    drawText("Server Overview", x, y, w, px(28,l), COLORS.text, 1.0 * l.scale, "default-bold")
    local gap = px(10,l)
    local cardW = (w - gap) / 2
    local cardH = px(66,l)
    drawSmallCard(x, y + px(34,l), cardW, cardH, "ONLINE PLAYERS", tostring(A.snapshot and A.snapshot.playerCount or 0), l)
    drawSmallCard(x + cardW + gap, y + px(34,l), cardW, cardH, "ONLINE STAFF", tostring(A.snapshot and A.snapshot.onlineStaff or 0), l)

    local startY = y + px(116,l)
    drawText("Admin Capabilities", x, startY, w, px(26,l), COLORS.text, 0.96 * l.scale, "default-bold")
    startY = startY + px(34,l)

    local buttonGap = px(8,l)
    local buttonW = (w - buttonGap) / 2
    local buttonH = px(42,l)

    for index, item in ipairs(DASHBOARD_BUTTONS) do
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        local rect = {
            x = x + column * (buttonW + buttonGap),
            y = startY + row * (buttonH + buttonGap),
            w = buttonW,
            h = buttonH,
            item = item
        }

        local label = item.label
        if item.action == "dashboard.freeze_self" then
            label = state.frozen and "Unfreeze" or "Freeze"
        elseif item.action == "dashboard.godmode" then
            label = state.godMode and "GM / Normal" or "GM / Normal"
        elseif item.action == "dashboard.flight" then
            label = state.flightEnabled and "Flight / Normal" or "Flight / Normal"
        elseif item.action == "dashboard.infinite_ammo" then
            label = state.infiniteAmmo and "Infinite Ammo [ON]" or "Infinite Ammo"
        elseif item.action == "dashboard.jetpack" then
            label = state.jetpack and "Remove Jetpack" or "Jetpack"
        end

        local permission = item.permission or item.action
        local enabled = not item.disabled and (not permission or hasPermission(permission)) and not A.pending
        rect.enabled = enabled
        local hover = enabled and mx and pointInRect(mx, my, rect)
        local color = enabled and (hover and COLORS.cardHover or COLORS.card) or tocolor(24,28,36,175)
        if (item.action == "dashboard.godmode" and state.godMode)
            or (item.action == "dashboard.flight" and state.flightEnabled)
            or (item.action == "dashboard.freeze_self" and state.frozen)
            or (item.action == "dashboard.infinite_ammo" and state.infiniteAmmo)
            or (item.action == "dashboard.jetpack" and state.jetpack) then
            color = enabled and COLORS.accentSoft or color
        end

        dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, color)
        dxDrawRectangle(rect.x, rect.y, px(4,l), rect.h, enabled and COLORS.accent or COLORS.muted)
        drawText(label, rect.x + px(12,l), rect.y, rect.w - px(20,l), rect.h, enabled and COLORS.text or COLORS.muted, 0.75 * l.scale, "default-bold", "left", "center", true)
        D.buttonRects[#D.buttonRects + 1] = rect
    end
end

function D.render(contentX, contentY, contentW, l, mx, my)
    D.createUI()
    local leftW = px(510,l)
    local gap = px(24,l)
    local rightX = contentX + leftW + gap
    local rightW = contentW - leftW - gap
    local paneH = l.h - l.headerH - px(48,l)

    drawLeftPane(contentX, contentY, leftW, paneH, l, mx, my)
    drawRightDashboard(rightX, contentY - px(6,l), rightW, paneH, l, mx, my)
end

local function submitCurrentInput()
    local value = trim(guiGetText(D.elements.toolValue))
    if value == "" then
        outputChatBox("[StarsCity] Meghdar Ra Vared Konid.", 255, 90, 90)
        return
    end

    if D.mode == "goto_player" then
        sendTargetAction("player.goto")
    elseif D.mode == "gethere" then
        sendTargetAction("player.gethere")
    elseif D.mode == "setarmor" then
        sendDashboardAction("dashboard.set_armor", { value = value })
    elseif D.mode == "sethealth" then
        sendDashboardAction("dashboard.set_health", { value = value })
    end
end

function D.handleClick(x, y)
    if not A.visible or A.category ~= "dashboard" or D.mapMode then
        return false
    end

    for _, rect in ipairs(D.buttonRects or {}) do
        if pointInRect(x, y, rect) then
            if not rect.enabled then
                return true
            end
            local item = rect.item
            if item.mode then
                setMode(item.mode)
            elseif item.action then
                sendDashboardAction(item.action, {})
            end
            return true
        end
    end

    for _, rect in ipairs(D.toolRects or {}) do
        if pointInRect(x, y, rect) then
            if rect.id == "goto_player" and rect.enabled then
                setMode("goto_player")
            elseif rect.id == "goto_map" and rect.enabled then
                startMapMode()
            elseif rect.id == "submit_input" then
                submitCurrentInput()
            elseif rect.id == "cancel_input" then
                setMode("home")
            elseif rect.id == "weapon_get_all" and rect.enabled then
                sendDashboardAction("dashboard.get_all_weapons", {})
            elseif rect.id == "give_all_submit" and rect.enabled then
                local value = trim(guiGetText(rect.edit) or "")
                if value == "" then
                    outputChatBox("[StarsCity] Meghdar Ra Vared Konid.", 255, 90, 90)
                else
                    sendDashboardAction(rect.action, { value = value })
                end
            end
            return true
        end
    end

    for _, rect in ipairs(D.catalogRows or {}) do
        if pointInRect(x, y, rect) then
            local item = rect.item
            if rect.enabled == false then
                return true
            end
            if D.mode == "skins" then
                sendDashboardAction("dashboard.set_skin", { value = tostring(item.id) })
            elseif D.mode == "vehicles" then
                if rect.destroyVehicle then
                    sendDashboardAction("dashboard.destroy_vehicle", {})
                else
                    sendDashboardAction("dashboard.spawn_vehicle", { value = tostring(item.id) })
                end
            elseif D.mode == "weapons" then
                sendDashboardAction("dashboard.get_weapon", { value = tostring(item.id) })
            end
            return true
        end
    end

    return false
end

addEventHandler("onClientGUIChanged", root, function()
    if not A or not A.visible or A.category ~= "dashboard" then
        return
    end

    if source == D.elements.toolSearch then
        D.filterCatalog()
    elseif source == D.elements.toolValue and not D.sanitizeGuard and (D.mode == "setarmor" or D.mode == "sethealth") then
        local current = guiGetText(source) or ""
        local digits = current:gsub("%D", ""):sub(1, 3)
        if current ~= digits then
            D.sanitizeGuard = true
            guiSetText(source, digits)
            guiEditSetCaretIndex(source, #digits)
            D.sanitizeGuard = false
        end
    elseif not D.sanitizeGuard and (source == D.elements.giveAllCash or source == D.elements.giveAllGold or source == D.elements.giveAllRespect) then
        local current = guiGetText(source) or ""
        local maxLen = source == D.elements.giveAllCash and 9 or (source == D.elements.giveAllGold and 6 or 4)
        local digits = current:gsub("%D", ""):sub(1, maxLen)
        if current ~= digits then
            D.sanitizeGuard = true
            guiSetText(source, digits)
            guiEditSetCaretIndex(source, #digits)
            D.sanitizeGuard = false
        end
    end
end)

addEventHandler("onClientGUIComboBoxAccepted", root, function()
    if source ~= D.elements.toolSort then
        return
    end
    local selected = guiComboBoxGetSelected(D.elements.toolSort)
    local option = CATALOG_SORTS[(selected or -1) + 1]
    if option then
        D.catalogSort = option.id
        D.filterCatalog()
    end
end)

addEventHandler("onClientGUIAccepted", root, function()
    if A and A.visible and A.category == "dashboard" and source == D.elements.toolValue then
        submitCurrentInput()
    end
end)

addEventHandler("onClientClick", root, function(button, state, x, y)
    if not D.mapMode or button ~= "left" or state ~= "up" then
        return
    end

    local minX, minY, maxX, maxY = getPlayerMapBoundingBox()
    if not minX or x < minX or x > maxX or y < minY or y > maxY then
        return
    end

    local now = getTickCount()
    local isDouble = now - D.mapLastClickTick <= 380 and math.abs(x - D.mapLastX) <= 12 and math.abs(y - D.mapLastY) <= 12
    D.mapLastClickTick = now
    D.mapLastX, D.mapLastY = x, y

    if not isDouble then
        return
    end

    local relX = (x - minX) / math.max(1, maxX - minX)
    local relY = (y - minY) / math.max(1, maxY - minY)
    local worldX = -3000 + relX * 6000
    local worldY = 3000 - relY * 6000

    D.mapMode = false
    forcePlayerMap(false)
    showCursor(true)
    sendDashboardAction("dashboard.goto_map", { x = worldX, y = worldY })
end)

addEventHandler("onClientKey", root, function(button, press)
    if not press then
        return
    end

    if D.virtualWeaponActive and not (A and A.visible) and not D.mapMode
        and not isChatBoxInputActive() and not isConsoleActive() and not isMainMenuActive() then
        local nextBound = isKeyBoundToControl(button, "next_weapon")
        local previousBound = isKeyBoundToControl(button, "previous_weapon")
        if nextBound or previousBound then
            if cycleVirtualWeapon(nextBound and 1 or -1) then
                cancelEvent()
                return
            end
        end
    end

    if D.mapMode and button == "escape" then
        cancelEvent()
        D.cancelMapMode()
        return
    end

    if A and A.visible and A.category == "dashboard" and (button == "mouse_wheel_up" or button == "mouse_wheel_down") then
        local mx, my = getCursorPixel()
        if mx and pointInRect(mx, my, D.catalogRect) then
            local maxOffset = math.max(0, #(D.filteredCatalog or {}) - math.max(D.catalogVisibleRows, 1))
            if button == "mouse_wheel_up" then
                D.catalogScroll = math.max(0, D.catalogScroll - 1)
            else
                D.catalogScroll = math.min(maxOffset, D.catalogScroll + 1)
            end
            cancelEvent()
            return
        end
    end

    if button == "space" and D.flightEnabled and not isAdminHardFrozen() and not (A and A.visible) and not D.mapMode then
        local now = getTickCount()
        if now - D.lastSpaceTick <= 360 then
            D.flightActive = not D.flightActive
            D.lastSpaceTick = 0
            setDashboardControl("jump", not D.flightActive)
            if not D.flightActive then
                setElementVelocity(localPlayer, 0, 0, 0)
            end
            cancelEvent()
        else
            D.lastSpaceTick = now
        end
    end
end)

addEvent("scAdminSetVirtualWeaponInventory", true)
addEventHandler("scAdminSetVirtualWeaponInventory", resourceRoot, function(enabled, weapons, currentWeapon)
    setVirtualWeaponInventory(enabled, weapons, currentWeapon)
end)

addEvent("scAdminVirtualWeaponEquipped", true)
addEventHandler("scAdminVirtualWeaponEquipped", resourceRoot, function(weaponID)
    local index = findVirtualWeaponIndex(weaponID)
    if index then
        D.virtualWeaponIndex = index
    end
end)

addEvent("scAdminSetGodModeState", true)
addEventHandler("scAdminSetGodModeState", resourceRoot, function(enabled)
    D.godModeEnabled = enabled == true
    if A and A.snapshot and type(A.snapshot.adminState) == "table" then
        A.snapshot.adminState.godMode = D.godModeEnabled
    end
end)

addEvent("scAdminSetFlightState", true)
addEventHandler("scAdminSetFlightState", resourceRoot, function(enabled)
    D.flightEnabled = enabled == true
    if not D.flightEnabled then
        D.flightActive = false
        setDashboardControl("jump", true)
        setElementVelocity(localPlayer, 0, 0, 0)
    end
end)

addEvent("scAdminResolveMapGround", true)
addEventHandler("scAdminResolveMapGround", resourceRoot, function(x, y)
    x, y = tonumber(x), tonumber(y)
    if not x or not y then
        return
    end

    local attempts = 0
    local timer
    timer = setTimer(function()
        attempts = attempts + 1
        local ground = getGroundPosition(x, y, 1000)
        if ground and ground > -100 then
            if isTimer(timer) then killTimer(timer) end
            triggerServerEvent("scAdminMapGroundResolved", resourceRoot, x, y, ground)
        elseif attempts >= 18 then
            if isTimer(timer) then killTimer(timer) end
        end
    end, 250, 18)
end)

addEventHandler("onClientPlayerDamage", localPlayer, function()
    if D.godModeEnabled then
        cancelEvent()
    end
end)

addEventHandler("onClientPreRender", root, function(delta)
    if isAdminHardFrozen() then
        if D.flightActive then
            D.flightActive = false
            D.lastSpaceTick = 0
            setElementVelocity(localPlayer, 0, 0, 0)
        end
        return
    end
    if not D.flightEnabled or not D.flightActive then
        return
    end
    if isPedDead(localPlayer) or isPedInVehicle(localPlayer) then
        D.flightActive = false
        setDashboardControl("jump", true)
        return
    end

    local x, y, z = getElementPosition(localPlayer)
    local cx, cy, cz, tx, ty, tz = getCameraMatrix()
    local fx, fy, fz = tx - cx, ty - cy, tz - cz
    local fl = math.sqrt(fx * fx + fy * fy + fz * fz)
    if fl < 0.001 then return end
    fx, fy, fz = fx / fl, fy / fl, fz / fl

    local horizontal = math.sqrt(fx * fx + fy * fy)
    local rx, ry = 0, 0
    if horizontal > 0.001 then
        rx, ry = fy / horizontal, -fx / horizontal
    end

    local dx, dy, dz = 0, 0, 0
    if getKeyState("w") then dx, dy, dz = dx + fx, dy + fy, dz + fz end
    if getKeyState("s") then dx, dy, dz = dx - fx, dy - fy, dz - fz end
    if getKeyState("a") then dx, dy = dx - rx, dy - ry end
    if getKeyState("d") then dx, dy = dx + rx, dy + ry end

    local length = math.sqrt(dx * dx + dy * dy + dz * dz)
    if length > 0.001 then
        dx, dy, dz = dx / length, dy / length, dz / length
        local step = D.flightSpeed * math.min(delta or 16, 50)
        local nx, ny, nz = x + dx * step, y + dy * step, z + dz * step

        local ground = getGroundPosition(nx, ny, nz + 4)
        if dz < -0.05 and ground and nz <= ground + 1.05 then
            setElementPosition(localPlayer, nx, ny, ground + 1.0)
            setElementVelocity(localPlayer, 0, 0, 0)
            D.flightActive = false
            setDashboardControl("jump", true)
            return
        end

        setElementPosition(localPlayer, nx, ny, nz)
        if horizontal > 0.001 then
            local rz = math.deg(math.atan2(-fx, fy))
            setElementRotation(localPlayer, 0, 0, rz)
        end
    end

    setElementVelocity(localPlayer, 0, 0, 0)
end)

function D.onSnapshot(snapshot)
    local state = snapshot and snapshot.adminState or {}
    if state.virtualWeapons == false and D.virtualWeaponActive then
        setVirtualWeaponInventory(false, {}, 0)
    end
    D.godModeEnabled = state.godMode == true
    D.flightEnabled = state.flightEnabled == true
    if not D.flightEnabled and D.flightActive then
        D.flightActive = false
        setDashboardControl("jump", true)
    end
end


addEventHandler("onClientResourceStop", resourceRoot, function()
    if D.virtualWeaponActive then
        setVirtualWeaponInventory(false, {}, 0)
    else
        setVirtualWeaponControls(false)
    end
end)
