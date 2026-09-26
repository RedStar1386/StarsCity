-- =========================================================
-- STARS CITY - ADMIN CONTROL PANEL
-- Responsive DX interface / interaction layer
-- =========================================================

SC_ADMIN_CLIENT = SC_ADMIN_CLIENT or {}
local A = SC_ADMIN_CLIENT

A.visible = false
A.savedCategory = A.category
A.savedSelectedID = nil
A.snapshot = nil
A.permissions = {}
A.category = "dashboard"
A.selectedID = nil
A.pending = false
A.sortMode = "name"
A.lastRefreshTick = 0
A.cursorWasShowing = false
A.actionRects = {}
A.navRects = {}
A.closeRect = nil
A.refreshRect = nil
A.tableRect = nil
A.playerRowRects = {}
A.filteredPlayers = {}
A.punishmentPlayers = {}
A.scrollOffset = 0
A.visibleRows = 0
A.inputAction = nil
A.inputApplyRect = nil
A.inputCancelRect = nil
A.lastSubmittedAction = nil
A.vehicleColorMenu = false
A.vehicleColorRects = {}
A.vehicleColorTarget = nil
A.vehicleColorType = nil
A.vehicleColorContext = nil
A.vehicleDoorMenu = false
A.vehicleDoorRects = {}
A.vehicleDoorBackRect = nil
A.vehicleDoorTarget = nil
A.vehicleDoorContext = nil
A.vehicleTuningMenu = false
A.vehicleTuningRects = {}
A.vehicleTuningBackRect = nil
A.vehicleTuningTarget = nil
A.vehicleTuningType = nil
A.elements = {
    searchEdit = nil,
    sortCombo = nil,
    reasonEdit = nil,
    valueEdit = nil
}

local NAV_ITEMS = {
    { id = "dashboard", label = "Dashboard" },
    { id = "info", label = "Player Info" },
    { id = "player", label = "Player Tools" },
    { id = "punishment", label = "Punishments" },
    { id = "vehicle", label = "Vehicle Tools" },
    { id = "staff", label = "Staff Management", managerOnly = true }
}

local SORT_OPTIONS = {
    { id = "name", label = "Name (A-Z)" },
    { id = "level", label = "Level (High-Low)" },
    { id = "id", label = "ID (Low-High)" },
    { id = "rank", label = "Rank (High-Low)" }
}

local COLORS = {
    overlay = tocolor(0, 0, 0, 165),
    panel = tocolor(17, 20, 27, 248),
    header = tocolor(22, 26, 35, 255),
    sidebar = tocolor(13, 16, 22, 255),
    card = tocolor(27, 32, 42, 255),
    cardHover = tocolor(35, 42, 55, 255),
    accent = tocolor(225, 64, 84, 255),
    accentSoft = tocolor(225, 64, 84, 45),
    text = tocolor(245, 247, 250, 255),
    muted = tocolor(155, 165, 182, 255),
    good = tocolor(82, 210, 126, 255),
    warning = tocolor(245, 191, 66, 255),
    danger = tocolor(235, 78, 78, 255),
    line = tocolor(255, 255, 255, 20)
}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function pointInRect(mx, my, rect)
    return rect and mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h
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

local function canShowNavItem(item)
    if not item.managerOnly then
        return true
    end

    local actorRank = A.snapshot and tonumber(A.snapshot.actorRank) or 0
    return SC_STAFF.hasManagerAccess(actorRank)
end

local function formatNumber(value)
    local number = math.floor(tonumber(value) or 0)
    local formatted = tostring(math.abs(number))

    while true do
        local result, count = formatted:gsub("^(%d+)(%d%d%d)", "%1,%2")
        formatted = result
        if count == 0 then
            break
        end
    end

    if number < 0 then
        formatted = "-" .. formatted
    end

    return formatted
end

local function levelSortValue(value)
    local number = tonumber(value)
    if number then
        return number
    end

    local text = string.lower(tostring(value or ""))
    if text == "max" or text == "maximum" then
        return 1000000000
    end

    return 0
end

function A.getLayout()
    local sw, sh = guiGetScreenSize()
    local scale = clamp(math.min(sw / 1920, sh / 1080), 0.78, 1.18)
    local w, h = 1180 * scale, 700 * scale

    return {
        sw = sw,
        sh = sh,
        scale = scale,
        x = (sw - w) / 2,
        y = (sh - h) / 2,
        w = w,
        h = h,
        headerH = 72 * scale,
        sidebarW = 205 * scale
    }
end

local function px(value, l)
    return value * l.scale
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

A.COLORS = COLORS
A.px = px
A.drawText = drawText
A.pointInRect = pointInRect
A.getCursorPixel = getCursorPixel

local function getListSource()
    if A.category == "punishment" and type(A.punishmentPlayers) == "table" then
        return A.punishmentPlayers
    end
    if A.snapshot and type(A.snapshot.players) == "table" then
        return A.snapshot.players
    end
    return {}
end

local function findPlayerData(id)
    id = tonumber(id)
    for _, row in ipairs(getListSource()) do
        if tonumber(row.id) == id then
            return row
        end
    end
    return nil
end

A.findPlayerData = findPlayerData
A.getListSource = getListSource

function A.createUI()
    local e = A.elements
    if isElement(e.searchEdit) then
        return
    end

    e.searchEdit = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.searchEdit, 32)

    e.sortCombo = guiCreateComboBox(0, 0, 1, 1, "Sort: Name (A-Z)", false)
    for _, option in ipairs(SORT_OPTIONS) do
        guiComboBoxAddItem(e.sortCombo, option.label)
    end
    guiComboBoxSetSelected(e.sortCombo, 0)

    e.reasonEdit = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.reasonEdit, 80)

    e.valueEdit = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.valueEdit, 96)

    guiSetVisible(e.searchEdit, false)
    guiSetVisible(e.sortCombo, false)
    guiSetVisible(e.reasonEdit, false)
    guiSetVisible(e.valueEdit, false)
end

function A.updateLayout()
    if not A.visible then
        return
    end

    local l = A.getLayout()
    local e = A.elements
    local contentX = l.x + l.sidebarW + px(24, l)
    local contentY = l.y + l.headerH + px(24, l)
    local leftW = px(510, l)

    local sortW = px(190, l)
    local controlGap = px(10, l)
    local searchW = leftW - sortW - controlGap

    guiSetPosition(e.searchEdit, contentX, contentY, false)
    guiSetSize(e.searchEdit, searchW, px(38, l), false)

    guiSetPosition(e.sortCombo, contentX + searchW + controlGap, contentY, false)
    guiSetSize(e.sortCombo, sortW, px(120, l), false)

    local rightX = contentX + leftW + px(24, l)
    local rightW = l.x + l.w - px(24, l) - rightX

    guiSetPosition(e.reasonEdit, rightX, l.y + l.h - px(72, l), false)
    guiSetSize(e.reasonEdit, rightW, px(36, l), false)

    guiSetPosition(e.valueEdit, rightX, l.y + l.h - px(82, l), false)
    guiSetSize(e.valueEdit, rightW, px(34, l), false)
end

function A.setPending(state)
    A.pending = state == true
    A.pendingSince = A.pending and getTickCount() or nil
end

function A.clearInputAction()
    A.inputAction = nil
    A.inputApplyRect = nil
    A.inputCancelRect = nil

    if isElement(A.elements.valueEdit) then
        guiSetText(A.elements.valueEdit, "")
        guiSetVisible(A.elements.valueEdit, false)
    end
end

function A.setInputAction(actionName)
    local definition = SC_STAFF.ADMIN_ACTIONS[actionName]
    if not definition or not definition.needsValue then
        A.clearInputAction()
        return
    end

    A.inputAction = actionName
    guiSetText(A.elements.valueEdit, "")
    guiSetVisible(A.elements.valueEdit, true)
    guiBringToFront(A.elements.valueEdit)
end

function A.filterPlayers()
    local selectedID = A.selectedID
    local needle = string.lower(guiGetText(A.elements.searchEdit) or "")

    local sourcePlayers = getListSource()
    if type(sourcePlayers) ~= "table" then
        A.filteredPlayers = {}
        A.scrollOffset = 0
        return
    end

    local players = {}
    for _, data in ipairs(sourcePlayers) do
        local haystack = string.lower(
            tostring(data.username or "") .. " " ..
            tostring(data.level or 0) .. " " ..
            tostring(data.id or "") .. " " ..
            tostring(data.staffRankName or "") .. " " ..
            tostring(data.accountStatus or "") .. " " ..
            tostring(data.ping or 0)
        )

        if needle == "" or string.find(haystack, needle, 1, true) then
            players[#players + 1] = data
        end
    end

    local function usernameOf(data)
        return string.lower(tostring(data.username or "Unknown"))
    end

    table.sort(players, function(a, b)
        if A.sortMode == "level" then
            local av, bv = levelSortValue(a.level), levelSortValue(b.level)
            if av ~= bv then
                return av > bv
            end
        elseif A.sortMode == "id" then
            local av, bv = tonumber(a.id) or 0, tonumber(b.id) or 0
            if av ~= bv then
                return av < bv
            end
        elseif A.sortMode == "rank" then
            local ar = tonumber(a.staffRank) or 0
            local br = tonumber(b.staffRank) or 0
            local av = ar == 0 and 999 or ar
            local bv = br == 0 and 999 or br
            if av ~= bv then
                return av < bv
            end
        else
            local av, bv = usernameOf(a), usernameOf(b)
            if av ~= bv then
                return av < bv
            end
        end

        local an, bn = usernameOf(a), usernameOf(b)
        if an ~= bn then
            return an < bn
        end

        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)

    A.filteredPlayers = players

    local stillVisible = false
    if selectedID then
        for _, data in ipairs(players) do
            if tonumber(data.id) == tonumber(selectedID) then
                stillVisible = true
                break
            end
        end
    end

    if selectedID and not stillVisible then
        A.selectedID = nil
        A.clearInputAction()
    end

    local maxOffset = math.max(0, #players - math.max(A.visibleRows, 1))
    A.scrollOffset = math.max(0, math.min(A.scrollOffset or 0, maxOffset))
end

function A.applySnapshot(snapshot)
    if type(snapshot) ~= "table" then
        return
    end

    A.snapshot = snapshot
    A.permissions = type(snapshot.permissions) == "table" and snapshot.permissions or {}
    if A.category == "staff" and not SC_STAFF.hasManagerAccess(tonumber(snapshot.actorRank) or 0) then
        A.category = "dashboard"
        if SC_ADMIN_STAFF_MANAGEMENT and SC_ADMIN_STAFF_MANAGEMENT.closeUI then
            SC_ADMIN_STAFF_MANAGEMENT.closeUI()
        end
    end
    if SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.onSnapshot then
        SC_ADMIN_DASHBOARD.onSnapshot(snapshot)
    end
    A.filterPlayers()
    A.lastRefreshTick = getTickCount()
end

function A.open(snapshot, initialCategory)
    A.createUI()
    A.cursorWasShowing = isCursorShowing()
    A.visible = true
    A.category = A.savedCategory or ((initialCategory == "staff" and SC_STAFF.hasManagerAccess(tonumber(snapshot and snapshot.actorRank) or 0)) and "staff" or "dashboard")
    A.selectedID = A.savedSelectedID
    A.sortMode = "name"
    A.scrollOffset = 0
    A.filteredPlayers = {}
    A.playerRowRects = {}
    A.lastSubmittedAction = nil
A.vehicleColorMenu = false
A.vehicleColorRects = {}
A.vehicleColorTarget = nil
A.vehicleColorType = nil
A.vehicleColorContext = nil
A.vehicleDoorMenu = false
A.vehicleDoorRects = {}
A.vehicleDoorBackRect = nil
A.vehicleDoorTarget = nil
A.vehicleDoorContext = nil
A.vehicleTuningMenu = false
A.vehicleTuningRects = {}
A.vehicleTuningBackRect = nil
A.vehicleTuningTarget = nil
A.vehicleTuningType = nil
    A.setPending(false)
    A.clearInputAction()
    if SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.reset then
        SC_ADMIN_DASHBOARD.createUI()
        SC_ADMIN_DASHBOARD.reset()
    end
    if SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.reset then
        SC_ADMIN_PLAYER_TOOLS.reset()
    end
    if SC_ADMIN_STAFF_MANAGEMENT and SC_ADMIN_STAFF_MANAGEMENT.createUI then
        SC_ADMIN_STAFF_MANAGEMENT.createUI()
        SC_ADMIN_STAFF_MANAGEMENT.reset()
        if A.category == "staff" then
            SC_ADMIN_STAFF_MANAGEMENT.enter()
        end
    end
    if SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.createUI then
        SC_ADMIN_PUNISHMENTS.createUI()
        SC_ADMIN_PUNISHMENTS.reset()
    end

    guiSetText(A.elements.searchEdit, "")
    guiComboBoxSetSelected(A.elements.sortCombo, 0)
    guiSetText(A.elements.reasonEdit, "")
    guiSetVisible(A.elements.searchEdit, false)
    guiSetVisible(A.elements.sortCombo, false)
    guiSetVisible(A.elements.reasonEdit, false)

    A.applySnapshot(snapshot)
    A.updateLayout()
    showCursor(true)
end

function A.close()
    A.savedCategory = A.category
    A.savedSelectedID = A.selectedID
    if not A.visible then
        return
    end

    A.visible = false
    A.setPending(false)
    A.actionRects = {}
    A.navRects = {}
    A.clearInputAction()
    if SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.closeUI then
        SC_ADMIN_DASHBOARD.closeUI()
    end
    if SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.closeUI then
        SC_ADMIN_PLAYER_TOOLS.closeUI()
    end
    if SC_ADMIN_STAFF_MANAGEMENT and SC_ADMIN_STAFF_MANAGEMENT.closeUI then
        SC_ADMIN_STAFF_MANAGEMENT.closeUI()
    end
    if SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.closeUI then
        SC_ADMIN_PUNISHMENTS.closeUI()
    end

    for _, element in pairs(A.elements) do
        if isElement(element) then
            guiSetVisible(element, false)
        end
    end

    if not A.cursorWasShowing then
        showCursor(false)
    end
end

local function drawCard(x, y, w, h, title, value, l)
    dxDrawRectangle(x, y, w, h, COLORS.card)
    drawText(title, x + px(16, l), y + px(10, l), w - px(32, l), px(24, l), COLORS.muted, 0.86 * l.scale, "default-bold")
    drawText(value, x + px(16, l), y + px(34, l), w - px(32, l), h - px(44, l), COLORS.text, 1.35 * l.scale, "default-bold")
end

local function drawPlayerTable(contentX, contentY, leftW, l, mx, my)
    local tableY = contentY + px(50, l)
    local tableH = l.h - l.headerH - px(98, l)
    local headerH = px(38, l)
    local rowH = px(36, l)

    A.tableRect = { x = contentX, y = tableY, w = leftW, h = tableH }
    A.playerRowRects = {}

    dxDrawRectangle(contentX, tableY, leftW, tableH, tocolor(10, 12, 17, 245))
    dxDrawRectangle(contentX, tableY, leftW, headerH, COLORS.header)

    local columns
    if A.category == "punishment" then
        columns = {
            { key = "username", label = "Name", ratio = 0.31, align = "left" },
            { key = "level", label = "Level", ratio = 0.12, align = "center" },
            { key = "id", label = "ID", ratio = 0.11, align = "center" },
            { key = "staffRankName", label = "Rank", ratio = 0.26, align = "left" },
            { key = "accountStatus", label = "Status", ratio = 0.20, align = "center" }
        }
    elseif A.category == "vehicle" then
        columns = {
            { key = "username", label = "Name", ratio = 0.32, align = "left" },
            { key = "level", label = "Level", ratio = 0.13, align = "center" },
            { key = "id", label = "ID", ratio = 0.11, align = "center" },
            { key = "staffRankName", label = "Rank", ratio = 0.24, align = "left" },
            { key = "vehicleType", label = "Vehicle Type", ratio = 0.20, align = "center" }
        }
    else
        columns = {
            { key = "username", label = "Name", ratio = 0.32, align = "left" },
            { key = "level", label = "Level", ratio = 0.13, align = "center" },
            { key = "id", label = "ID", ratio = 0.11, align = "center" },
            { key = "staffRankName", label = "Rank", ratio = 0.28, align = "left" },
            { key = "ping", label = "Ping", ratio = 0.16, align = "center" }
        }
    end

    local columnX = contentX
    for index, column in ipairs(columns) do
        local columnW = leftW * column.ratio
        local textPad = column.align == "left" and px(10, l) or 0
        drawText(
            column.label,
            columnX + textPad,
            tableY,
            columnW - textPad - (column.align == "left" and px(6, l) or 0),
            headerH,
            COLORS.text,
            0.80 * l.scale,
            "default-bold",
            column.align,
            "center",
            true
        )

        if index < #columns then
            dxDrawRectangle(columnX + columnW - px(1, l), tableY, px(1, l), tableH, COLORS.line)
        end
        columnX = columnX + columnW
    end

    dxDrawRectangle(contentX, tableY + headerH - px(1, l), leftW, px(1, l), COLORS.line)

    local usableH = tableH - headerH
    A.visibleRows = math.max(1, math.floor(usableH / rowH))
    local players = A.filteredPlayers or {}
    local maxOffset = math.max(0, #players - A.visibleRows)
    A.scrollOffset = math.max(0, math.min(A.scrollOffset or 0, maxOffset))

    if #players == 0 then
        drawText("No players found.", contentX, tableY + headerH, leftW, usableH, COLORS.muted, 0.90 * l.scale, "default", "center", "center")
        return
    end

    local startIndex = A.scrollOffset + 1
    local endIndex = math.min(#players, A.scrollOffset + A.visibleRows)
    local rowY = tableY + headerH

    for i = startIndex, endIndex do
        local data = players[i]
        local rowRect = { x = contentX, y = rowY, w = leftW, h = rowH, id = tonumber(data.id) }
        local selected = tonumber(A.selectedID) == tonumber(data.id)
        local hovered = mx and pointInRect(mx, my, rowRect)

        if selected then
            dxDrawRectangle(rowRect.x, rowRect.y, rowRect.w, rowRect.h, COLORS.accentSoft)
            dxDrawRectangle(rowRect.x, rowRect.y, px(3, l), rowRect.h, COLORS.accent)
        elseif hovered then
            dxDrawRectangle(rowRect.x, rowRect.y, rowRect.w, rowRect.h, COLORS.cardHover)
        elseif (i - startIndex) % 2 == 1 then
            dxDrawRectangle(rowRect.x, rowRect.y, rowRect.w, rowRect.h, tocolor(255, 255, 255, 7))
        end

        local values
        if A.category == "punishment" then
            values = {
                tostring(data.username or "Unknown"),
                tostring(data.level or 0),
                tostring(data.id or "-"),
                tostring(data.staffRankName or "Citizen"),
                tostring(data.accountStatus or (data.online and "Online" or "Offline"))
            }
        elseif A.category == "vehicle" then
            local vehicleType = "On Foot"
            if data.inVehicle then
                local typeName = tostring(data.vehicleType or "Vehicle")
                local displayType = ({
                    Automobile = "Car",
                    Bike = "Motorcycle",
                    Bicycle = "Bicycle",
                    Boat = "Boat",
                    Plane = "Plane",
                    Helicopter = "Helicopter",
                    Train = "Train"
                })[typeName] or typeName
                vehicleType = displayType .. ": " .. tostring(data.vehicleName or "Vehicle")
            end

            values = {
                tostring(data.username or "Unknown"),
                tostring(data.level or 0),
                tostring(data.id or "-"),
                tostring(data.staffRankName or "Citizen"),
                vehicleType
            }
        else
            values = {
                tostring(data.username or "Unknown"),
                tostring(data.level or 0),
                tostring(data.id or "-"),
                tostring(data.staffRankName or "Citizen"),
                ("%s ms"):format(tostring(tonumber(data.ping) or 0))
            }
        end

        local cellX = contentX
        for columnIndex, column in ipairs(columns) do
            local cellW = leftW * column.ratio
            local textPad = column.align == "left" and px(10, l) or 0
            drawText(
                values[columnIndex],
                cellX + textPad,
                rowY,
                cellW - textPad - (column.align == "left" and px(6, l) or 0),
                rowH,
                (A.category == "punishment" and column.key == "accountStatus" and not selected)
                    and (data.online and COLORS.good or COLORS.muted)
                    or (selected and COLORS.text or tocolor(220, 225, 233, 255)),
                0.80 * l.scale,
                selected and "default-bold" or "default",
                column.align,
                "center",
                true
            )
            cellX = cellX + cellW
        end

        dxDrawRectangle(contentX, rowY + rowH - px(1, l), leftW, px(1, l), COLORS.line)
        A.playerRowRects[#A.playerRowRects + 1] = rowRect
        rowY = rowY + rowH
    end

    if #players > A.visibleRows then
        local trackW = px(4, l)
        local trackX = contentX + leftW - trackW - px(2, l)
        local trackY = tableY + headerH + px(3, l)
        local trackH = usableH - px(6, l)
        local thumbH = math.max(px(26, l), trackH * (A.visibleRows / #players))
        local progress = maxOffset > 0 and (A.scrollOffset / maxOffset) or 0
        local thumbY = trackY + (trackH - thumbH) * progress
        dxDrawRectangle(trackX, trackY, trackW, trackH, tocolor(255, 255, 255, 12))
        dxDrawRectangle(trackX, thumbY, trackW, thumbH, COLORS.muted)
    end
end

local function drawDashboard(rightX, topY, rightW, l)
    local cardGap = px(12, l)
    local cardW = (rightW - cardGap) / 2
    local cardH = px(90, l)
    local playerCount = A.snapshot and A.snapshot.playerCount or 0
    local staffCount = A.snapshot and A.snapshot.onlineStaff or 0

    drawText("Server Overview", rightX, topY, rightW, px(34, l), COLORS.text, 1.05 * l.scale, "default-bold")
    drawCard(rightX, topY + px(42, l), cardW, cardH, "ONLINE PLAYERS", tostring(playerCount), l)
    drawCard(rightX + cardW + cardGap, topY + px(42, l), cardW, cardH, "ONLINE STAFF", tostring(staffCount), l)

    local selected = findPlayerData(A.selectedID)
    local infoY = topY + px(155, l)
    dxDrawRectangle(rightX, infoY, rightW, px(250, l), COLORS.card)
    drawText("Selected Player", rightX + px(18, l), infoY + px(12, l), rightW - px(36, l), px(30, l), COLORS.text, 1.0 * l.scale, "default-bold")

    if not selected then
        drawText("Select a player from the list to see live information.", rightX + px(18, l), infoY + px(58, l), rightW - px(36, l), px(80, l), COLORS.muted, 0.9 * l.scale, "default", "left", "top", true)
        return
    end

    local lifeState = selected.dead and "Dead" or "Alive"
    local vehicleState = selected.inVehicle and tostring(selected.vehicleName or "Vehicle") or "On Foot"
    local lines = {
        ("Name: %s"):format(tostring(selected.username or "Unknown")),
        ("Level: %s"):format(tostring(selected.level or 0)),
        ("ID: %s"):format(tostring(selected.id or "-")),
        ("Rank: %s"):format(tostring(selected.staffRankName or "Citizen")),
        ("Ping: %d ms"):format(tonumber(selected.ping) or 0),
        ("Health / Armor: %d / %d"):format(tonumber(selected.health) or 0, tonumber(selected.armor) or 0),
        ("State: %s | %s"):format(lifeState, vehicleState),
        ("Flags: %s | %s"):format(selected.frozen and "Frozen" or "Active", selected.muted and "Muted" or "Not Muted")
    }

    local y = infoY + px(50, l)
    for _, line in ipairs(lines) do
        drawText(line, rightX + px(18, l), y, rightW - px(36, l), px(23, l), COLORS.muted, 0.84 * l.scale, "default", "left", "center", true)
        y = y + px(24, l)
    end
end

local function drawInfoRow(label, value, x, y, w, l, valueColor)
    local labelW = px(120, l)
    drawText(label, x, y, labelW, px(22, l), COLORS.muted, 0.78 * l.scale, "default-bold", "left", "center", true)
    drawText(value, x + labelW, y, w - labelW, px(22, l), valueColor or COLORS.text, 0.80 * l.scale, "default", "left", "center", true)
end

local function drawPlayerInfo(rightX, topY, rightW, l)
    drawText("Player Information", rightX, topY, rightW, px(34, l), COLORS.text, 1.05 * l.scale, "default-bold")

    local selected = findPlayerData(A.selectedID)
    if not selected then
        dxDrawRectangle(rightX, topY + px(48, l), rightW, px(220, l), COLORS.card)
        drawText("Select a player from the table to inspect complete live information.", rightX + px(18, l), topY + px(70, l), rightW - px(36, l), px(100, l), COLORS.muted, 0.9 * l.scale, "default", "left", "top", true)
        return
    end

    local cardY = topY + px(44, l)
    local cardH = l.y + l.h - px(24, l) - cardY
    dxDrawRectangle(rightX, cardY, rightW, cardH, COLORS.card)

    drawText(
        ("%s  [%s]"):format(tostring(selected.username or "Unknown"), tostring(selected.id or "-")),
        rightX + px(16, l), cardY + px(10, l), rightW - px(32, l), px(30, l), COLORS.text, 1.02 * l.scale, "default-bold", "left", "center", true
    )

    local vehicleText = "None"
    if selected.inVehicle then
        vehicleText = ("%s [%s] Seat %s"):format(
            tostring(selected.vehicleName or "Vehicle"),
            tostring(selected.vehicleModel or "-"),
            tostring(selected.vehicleSeat or "-")
        )
    end

    local stateText = selected.dead and "Dead" or "Alive"
    local positionText = ("%.2f, %.2f, %.2f"):format(tonumber(selected.x) or 0, tonumber(selected.y) or 0, tonumber(selected.z) or 0)
    local sensitiveAllowed = A.permissions["player.info_sensitive"] == true

    local rows = {
        { "Username", tostring(selected.username or "Unknown") },
        { "Account ID", tostring(selected.id or "-") },
        { "Level", tostring(selected.level or 0) },
        { "Staff Rank", tostring(selected.staffRankName or "Citizen") },
        { "Ping", ("%d ms"):format(tonumber(selected.ping) or 0) },
        { "Life State", stateText, selected.dead and COLORS.danger or COLORS.good },
        { "Health", tostring(tonumber(selected.health) or 0) },
        { "Armor", tostring(tonumber(selected.armor) or 0) },
        { "Money", "$" .. formatNumber(selected.money) },
        { "Dimension", tostring(tonumber(selected.dimension) or 0) },
        { "Interior", tostring(tonumber(selected.interior) or 0) },
        { "Position", positionText },
        { "Skin", tostring(tonumber(selected.skin) or 0) },
        { "Weapon ID", tostring(tonumber(selected.weapon) or 0) },
        { "Team", tostring(selected.team or "None") },
        { "Vehicle", vehicleText },
        { "Frozen", selected.frozen and "Yes" or "No", selected.frozen and COLORS.warning or COLORS.good },
        { "Muted", selected.muted and "Yes" or "No", selected.muted and COLORS.warning or COLORS.good },
        { "Account", tostring(selected.accountStatus or "Online"), COLORS.good }
    }

    if sensitiveAllowed then
        rows[#rows + 1] = { "IP", tostring(selected.ip or "Unknown") }
        rows[#rows + 1] = { "Serial", tostring(selected.serial or "Unknown") }
    else
        rows[#rows + 1] = { "IP / Serial", "Hidden by permission", COLORS.muted }
    end

    local rowY = cardY + px(47, l)
    local rowH = px(22, l)
    for _, row in ipairs(rows) do
        drawInfoRow(row[1], row[2], rightX + px(16, l), rowY, rightW - px(32, l), l, row[3])
        rowY = rowY + rowH
    end
end

local function getActionsForCategory(category)
    local result = {}
    for _, actionName in ipairs(SC_STAFF.ADMIN_ACTION_ORDER or {}) do
        local definition = SC_STAFF.ADMIN_ACTIONS[actionName]
        local hiddenVehicleActions = (category == "vehicle" and (actionName == "vehicle.fix" or actionName == "vehicle.flip"))
        if definition and definition.category == category and A.permissions[actionName] and not hiddenVehicleActions then
            result[#result + 1] = actionName
        end
    end
    return result
end

local function drawInputPanel(rightX, rightW, l, mx, my)
    A.inputApplyRect = nil
    A.inputCancelRect = nil

    if not A.inputAction then
        guiSetVisible(A.elements.valueEdit, false)
        return
    end

    local definition = SC_STAFF.ADMIN_ACTIONS[A.inputAction]
    if not definition then
        A.clearInputAction()
        return
    end

    guiSetVisible(A.elements.valueEdit, true)

    local panelY = l.y + l.h - px(126, l)
    local panelH = px(108, l)
    dxDrawRectangle(rightX, panelY, rightW, panelH, COLORS.card)
    dxDrawRectangle(rightX, panelY, px(4, l), panelH, COLORS.accent)

    local title = ("%s: %s"):format(tostring(definition.label or "Input"), tostring(definition.valueLabel or "Value"))
    drawText(title, rightX + px(14, l), panelY + px(4, l), rightW - px(28, l), px(22, l), COLORS.text, 0.80 * l.scale, "default-bold", "left", "center", true)
    drawText(tostring(definition.valueHint or "Enter a value"), rightX + px(14, l), panelY + px(25, l), rightW - px(28, l), px(18, l), COLORS.muted, 0.72 * l.scale, "default", "left", "center", true)

    local gap = px(8, l)
    local buttonY = l.y + l.h - px(42, l)
    local buttonW = (rightW - gap) / 2
    A.inputApplyRect = { x = rightX, y = buttonY, w = buttonW, h = px(30, l) }
    A.inputCancelRect = { x = rightX + buttonW + gap, y = buttonY, w = buttonW, h = px(30, l) }

    local applyHover = mx and pointInRect(mx, my, A.inputApplyRect)
    local cancelHover = mx and pointInRect(mx, my, A.inputCancelRect)

    dxDrawRectangle(A.inputApplyRect.x, A.inputApplyRect.y, A.inputApplyRect.w, A.inputApplyRect.h, applyHover and COLORS.cardHover or COLORS.accentSoft)
    drawText("APPLY", A.inputApplyRect.x, A.inputApplyRect.y, A.inputApplyRect.w, A.inputApplyRect.h, COLORS.text, 0.76 * l.scale, "default-bold", "center")

    dxDrawRectangle(A.inputCancelRect.x, A.inputCancelRect.y, A.inputCancelRect.w, A.inputCancelRect.h, cancelHover and COLORS.cardHover or COLORS.header)
    drawText("CANCEL", A.inputCancelRect.x, A.inputCancelRect.y, A.inputCancelRect.w, A.inputCancelRect.h, COLORS.muted, 0.76 * l.scale, "default-bold", "center")
end


local function findSelectedVehicleTargetPlayer()
    if not A.selectedID then
        return nil
    end

    local selectedID = tonumber(A.selectedID)
    local selected = getListSource()
    for _, row in ipairs(selected) do
        if tonumber(row.id) == selectedID and isElement(row.player) then
            return row.player
        end
    end

    for _, player in ipairs(getElementsByType("player")) do
        if tonumber(getElementData(player, "account:id")) == selectedID then
            return player
        end
    end

    return nil
end

local function getVehicleActionTarget()
    -- Priority 1: if a player is selected, ONLY that player's occupied vehicle is valid.
    -- Do not silently fall back to the admin/nearby vehicle because that can apply an
    -- action to the wrong vehicle while the admin believes the selected player is targeted.
    if A.selectedID then
        local targetPlayer = findSelectedVehicleTargetPlayer()
        local context = { mode = "selected", targetID = tonumber(A.selectedID) }

        if not targetPlayer then
            return nil, context, "Selected player is no longer online."
        end

        local vehicle = getPedOccupiedVehicle(targetPlayer)
        if not vehicle or not isElement(vehicle) then
            return nil, context, "Selected player is not inside a vehicle."
        end

        return vehicle, context
    end

    -- Priority 2: no player is selected and the admin is currently in a vehicle.
    if isPedInVehicle(localPlayer) then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if vehicle and isElement(vehicle) then
            return vehicle, { mode = "self" }
        end
    end

    -- Priority 3: no player is selected, admin is on foot, use only a genuinely nearby
    -- vehicle in the same dimension/interior and with a clear line of sight.
    local pxPos, pyPos, pzPos = getElementPosition(localPlayer)
    local playerDimension = getElementDimension(localPlayer)
    local playerInterior = getElementInterior(localPlayer)
    local best, bestDistance = nil, 2.5

    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        if getElementDimension(vehicle) == playerDimension and getElementInterior(vehicle) == playerInterior then
            local vx, vy, vz = getElementPosition(vehicle)
            local distance = getDistanceBetweenPoints3D(pxPos, pyPos, pzPos, vx, vy, vz)
            if distance <= bestDistance then
                local clear = true
                if type(isLineOfSightClear) == "function" then
                    clear = isLineOfSightClear(
                        pxPos, pyPos, pzPos + 1.0,
                        vx, vy, vz + 0.5,
                        true, false, false, true, false, false, false,
                        localPlayer
                    )
                end

                if clear then
                    best = vehicle
                    bestDistance = distance
                end
            end
        end
    end

    if best then
        return best, { mode = "nearby" }
    end

    return nil, { mode = "nearby" }, "No vehicle nearby (maximum distance: 2.5m)."
end

local function drawVehicleInformationCard(x, y, w, l)
    local veh = getVehicleActionTarget()
    local h = px(118, l)
    dxDrawRectangle(x, y, w, h, COLORS.card)
    dxDrawRectangle(x, y, px(4, l), h, COLORS.accent)

    drawText("Vehicle Information", x + px(14,l), y + px(6,l), w-px(28,l), px(22,l), COLORS.text, 1.00*l.scale, "default-bold")

    local driver = "None"
    local occupants = {}
    local vehicleName = "None"
    local vehicleID = "-"
    local owner = "Unknown"

    if veh and isElement(veh) then
        vehicleName = getVehicleNameFromModel(getElementModel(veh)) or "Vehicle"
        vehicleID = tostring(getElementModel(veh))

        local max = getVehicleMaxPassengers(veh) or 0
        for seat = 0, max do
            local p = getVehicleOccupant(veh, seat)
            if p then
                local name = tostring(getElementData(p, "account:username") or "Unknown")
                local accountID = tostring(getElementData(p, "account:id") or "-")
                local text = name .. " [" .. accountID .. "]"
                if seat == 0 then
                    driver = text
                else
                    occupants[#occupants+1] = text
                end
            end
        end
    end

    local crew = driver
    if #occupants > 0 then
        crew = crew .. " | " .. table.concat(occupants, " | ")
    end

    drawText("Driver / Passengers: " .. crew, x + px(14,l), y + px(32,l), w-px(28,l), px(24,l), COLORS.good, 1.02*l.scale, "default-bold", "left", "center", true)

    drawText("Vehicle: " .. vehicleName .. "  |  ID: " .. vehicleID,
        x + px(14,l), y + px(62,l), w-px(28,l), px(24,l), COLORS.muted, 0.98*l.scale, "default-bold", "left", "center", true)
end



local function openVehicleColorMenu()
    -- Vehicle sub-pages share the middle content area, so only one can be active.
    A.vehicleDoorMenu = false
    A.vehicleDoorRects = {}
    A.vehicleDoorBackRect = nil
    A.vehicleDoorTarget = nil
    A.vehicleDoorContext = nil
A.vehicleTuningMenu = false
A.vehicleTuningRects = {}
A.vehicleTuningBackRect = nil
A.vehicleTuningTarget = nil
A.vehicleTuningType = nil

    local veh, context, targetError = getVehicleActionTarget()
    if not veh or not isElement(veh) then
        outputChatBox("[Vehicle Tools] ERROR: " .. tostring(targetError or "No target vehicle found."), 255, 80, 80)
        return
    end
    A.vehicleColorTarget = veh
    A.vehicleColorContext = context
    A.vehicleColorMenu = true
    A.vehicleColorRects = {}
    A.colorBackCategory = A.category
end

local function getCurrentVehicleColorForPicker(veh, colorType)
    if not veh or not isElement(veh) then
        return 255, 255, 255, 255
    end

    if colorType == "light" and type(getVehicleHeadLightColor) == "function" then
        local r, g, b = getVehicleHeadLightColor(veh)
        if r and g and b then
            return r, g, b, 255
        end
    end

    local r1, g1, b1, r2, g2, b2 = getVehicleColor(veh, true)
    if colorType == "secondary" then
        return r2 or r1 or 255, g2 or g1 or 255, b2 or b1 or 255, 255
    end

    return r1 or 255, g1 or 255, b1 or 255, 255
end

local function callSharedColorPicker(callbackEvent, r, g, b, a)
    -- sc_color is the single shared color-picker resource for the server.
    -- Do not fall back to legacy picker resources because running an old picker by
    -- mistake could route callbacks to the wrong implementation.
    local resource = getResourceFromName("sc_color")
    if not resource or getResourceState(resource) ~= "running" then
        return false, "resource_not_running"
    end

    local ok, result = pcall(function()
        return exports.sc_color:openColorPicker(callbackEvent, r, g, b, a)
    end)

    if ok and result ~= false then
        return true, "sc_color"
    end

    return false, result
end

local function openScColorPicker(colorType)
    local veh = A.vehicleColorTarget
    local context = A.vehicleColorContext

    if not veh or not isElement(veh) then
        local targetError
        veh, context, targetError = getVehicleActionTarget()
        A.vehicleColorTarget = veh
        A.vehicleColorContext = context
        if not veh or not isElement(veh) then
            outputChatBox("[Vehicle Color] ERROR: " .. tostring(targetError or "No target vehicle found."), 255, 80, 80)
            return
        end
    end

    A.vehicleColorType = colorType
    local r, g, b, a = getCurrentVehicleColorForPicker(veh, colorType)

    -- sc_color is a separate DX window, so close the admin panel while keeping
    -- the saved category/player selection and the captured vehicle target/session.
    A.close()

    local ok, resourceNameOrError = callSharedColorPicker("scStaffVehicleColorApplied", r, g, b, a)
    if not ok then
        outputChatBox("[Vehicle Color] ERROR: sc_color is not running or its openColorPicker export is unavailable.", 255, 80, 80)
        outputDebugString("[sc_staff] Color picker open failed: " .. tostring(resourceNameOrError), 1)
        A.vehicleColorTarget = nil
        A.vehicleColorType = nil
        A.vehicleColorContext = nil
        triggerServerEvent("scAdminRequestOpen", resourceRoot)
        return
    end

    outputChatBox("[Vehicle Color] " .. tostring(colorType) .. " picker opened.", 80, 220, 120)
end

addEvent("scStaffVehicleColorApplied", true)
addEventHandler("scStaffVehicleColorApplied", root, function(r, g, b, a)
    local veh = A.vehicleColorTarget
    local colorType = A.vehicleColorType
    local context = A.vehicleColorContext

    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not veh or not isElement(veh) then
        outputChatBox("[Vehicle Color] ERROR: Target vehicle is no longer available.", 255, 80, 80)
        A.vehicleColorTarget = nil
        A.vehicleColorType = nil
        A.vehicleColorContext = nil
        return
    end
    if colorType ~= "primary" and colorType ~= "secondary" and colorType ~= "light" then
        outputChatBox("[Vehicle Color] ERROR: Invalid color target.", 255, 80, 80)
        A.vehicleColorTarget = nil
        A.vehicleColorType = nil
        A.vehicleColorContext = nil
        return
    end
    if not r or not g or not b then
        outputChatBox("[Vehicle Color] ERROR: Invalid RGB value returned by sc_color.", 255, 80, 80)
        return
    end

    r = math.max(0, math.min(255, math.floor(r + 0.5)))
    g = math.max(0, math.min(255, math.floor(g + 0.5)))
    b = math.max(0, math.min(255, math.floor(b + 0.5)))

    -- Keep the selected vehicle and color channel while sc_color stays open.
    -- This allows Apply to be pressed repeatedly for live color testing. The next
    -- picker session will overwrite these values as needed.
    triggerServerEvent("scStaff:applyVehicleColor", resourceRoot, veh, colorType, r, g, b, context)
end)

local function drawVehicleColorMenu(contentX, contentY, l, mx, my)
    local x = contentX
    local w,h = 390,260
    local y = contentY

    dxDrawRectangle(x,y,w,h,tocolor(17,20,27,245))
    dxDrawText("Vehicle Color",x,y+8,x+w,y+32,tocolor(255,255,255),1,"default-bold","center","center")

    A.vehicleColorRects={}
    local items={{"Primary Color","primary"},{"Secondary Color","secondary"},{"Light Color","light"}}

    for i,it in ipairs(items) do
        local r={x=x+25,y=y+45+(i-1)*48,w=w-50,h=34,action=it[2]}
        table.insert(A.vehicleColorRects,r)
        dxDrawRectangle(r.x,r.y,r.w,r.h,tocolor(35,42,55,255))
        dxDrawText(it[1],r.x,r.y,r.x+r.w,r.y+r.h,tocolor(245,245,245),0.9,"default-bold","center","center")
    end

    local back={x=x+25,y=y+h-38,w=w-50,h=28,action="back"}
    A.vehicleColorBackRect=back
    dxDrawRectangle(back.x,back.y,back.w,back.h,tocolor(50,55,70,255))
    dxDrawText("Back",back.x,back.y,back.x+back.w,back.y+back.h,tocolor(255,255,255),0.85,"default-bold","center","center")
end

local VEHICLE_DOOR_DEFINITIONS = {
    { id = 0, key = "hood",  label = "Hood",   component = "bonnet_dummy" },
    { id = 1, key = "door1", label = "Door 1", component = "door_lf_dummy" },
    { id = 2, key = "door2", label = "Door 2", component = "door_rf_dummy" },
    { id = 3, key = "door3", label = "Door 3", component = "door_lr_dummy" },
    { id = 4, key = "door4", label = "Door 4", component = "door_rr_dummy" },
    { id = 5, key = "trunk", label = "Trunk",  component = "boot_dummy" }
}

local function clearVehicleDoorMenu()
    A.vehicleDoorMenu = false
    A.vehicleDoorRects = {}
    A.vehicleDoorBackRect = nil
    A.vehicleDoorTarget = nil
    A.vehicleDoorContext = nil
A.vehicleTuningMenu = false
A.vehicleTuningRects = {}
A.vehicleTuningBackRect = nil
A.vehicleTuningTarget = nil
A.vehicleTuningType = nil
end

local function clearVehicleColorMenu()
    A.vehicleColorMenu = false
    A.vehicleColorRects = {}
    A.vehicleColorBackRect = nil
    A.vehicleColorTarget = nil
    A.vehicleColorType = nil
    A.vehicleColorContext = nil
end

local function hasVehicleComponent(veh, componentName)
    if not veh or not isElement(veh) or not componentName then
        return false
    end

    -- Prefer the component table when the vehicle is streamed in. This correctly
    -- distinguishes two-door/four-door models and vehicles without hood/trunk.
    if type(getVehicleComponents) == "function" and isElementStreamedIn(veh) then
        local components = getVehicleComponents(veh)
        if type(components) == "table" then
            if components[componentName] ~= nil then
                return true
            end
            for key, value in pairs(components) do
                if tostring(key) == componentName or tostring(value) == componentName then
                    return true
                end
            end
            return false
        end
    end

    -- Older builds may not expose getVehicleComponents. Component position is a
    -- useful fallback for streamed vehicles.
    if type(getVehicleComponentPosition) == "function" and isElementStreamedIn(veh) then
        local x = getVehicleComponentPosition(veh, componentName)
        if x ~= nil and x ~= false then
            return true
        end
    end

    -- If a remote selected player's vehicle is outside the client's streaming
    -- range, the model components cannot be inspected client-side. Keep the
    -- controls available and let the authoritative server reject unsupported
    -- doors rather than falsely disabling a valid door.
    return not isElementStreamedIn(veh)
end

local function getVehicleDoorUiState(veh, definition)
    local available = hasVehicleComponent(veh, definition.component)
    if not available then
        return false, "N/A", false
    end

    if type(getVehicleDoorState) == "function" then
        local state = getVehicleDoorState(veh, definition.id)
        if tonumber(state) == 4 then
            return false, "Missing", false
        end
    end

    local ratio = 0
    if type(getVehicleDoorOpenRatio) == "function" then
        ratio = tonumber(getVehicleDoorOpenRatio(veh, definition.id)) or 0
    end
    local isOpen = ratio >= 0.5
    return true, isOpen and "Close" or "Open", isOpen
end

local function openVehicleDoorMenu()
    local veh, context, targetError = getVehicleActionTarget()
    if not veh or not isElement(veh) then
        outputChatBox("[Vehicle Tools] ERROR: " .. tostring(targetError or "No target vehicle found."), 255, 80, 80)
        return
    end

    -- Only the middle content area changes. Vehicle Actions on the right remains
    -- visible and interactive, matching the Vehicle Color flow.
    clearVehicleColorMenu()
    A.vehicleDoorTarget = veh
    A.vehicleDoorContext = context
    A.vehicleDoorMenu = true
    A.vehicleDoorRects = {}
    A.vehicleDoorBackRect = nil
end

local function drawVehicleDoorMenu(contentX, contentY, leftW, l, mx, my)
    local veh = A.vehicleDoorTarget
    local panelW = px(390, l)
    local panelH = px(318, l)
    local x = contentX + math.max(0, (leftW - panelW) / 2)
    local y = contentY + px(12, l)

    dxDrawRectangle(x, y, panelW, panelH, tocolor(17, 20, 27, 245))
    dxDrawRectangle(x, y, px(4, l), panelH, COLORS.accent)
    drawText("Vehicle Door", x, y + px(8, l), panelW, px(30, l), COLORS.text, 1.00 * l.scale, "default-bold", "center", "center")
    drawText("Toggle the available doors for the target vehicle", x + px(18,l), y + px(36,l), panelW - px(36,l), px(20,l), COLORS.muted, 0.70 * l.scale, "default", "center", "center", true)

    A.vehicleDoorRects = {}

    local byId = {}
    for _, definition in ipairs(VEHICLE_DOOR_DEFINITIONS) do
        byId[definition.id] = definition
    end

    local gap = px(10, l)
    local innerX = x + px(24, l)
    local innerW = panelW - px(48, l)
    local halfW = (innerW - gap) / 2
    local buttonH = px(38, l)

    local layout = {
        { door = 0, x = innerX,               y = y + px(66,l),  w = innerW },
        { door = 1, x = innerX,               y = y + px(114,l), w = halfW },
        { door = 2, x = innerX + halfW + gap, y = y + px(114,l), w = halfW },
        { door = 3, x = innerX,               y = y + px(162,l), w = halfW },
        { door = 4, x = innerX + halfW + gap, y = y + px(162,l), w = halfW },
        { door = 5, x = innerX,               y = y + px(210,l), w = innerW }
    }

    for _, item in ipairs(layout) do
        local definition = byId[item.door]
        local enabled, actionLabel = getVehicleDoorUiState(veh, definition)
        local rect = { x = item.x, y = item.y, w = item.w, h = buttonH, door = item.door }
        local hovered = enabled and mx and pointInRect(mx, my, rect)
        local bg = enabled and (hovered and COLORS.cardHover or COLORS.card) or tocolor(24, 28, 36, 190)
        local accent = enabled and COLORS.accent or COLORS.muted
        local textColor = enabled and COLORS.text or COLORS.muted

        dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, bg)
        dxDrawRectangle(rect.x, rect.y, px(4, l), rect.h, accent)
        drawText(definition.label .. "  •  " .. actionLabel, rect.x + px(10,l), rect.y, rect.w - px(18,l), rect.h, textColor, 0.76 * l.scale, "default-bold", "center", "center", true)

        if enabled then
            A.vehicleDoorRects[#A.vehicleDoorRects + 1] = rect
        end
    end

    local back = { x = innerX, y = y + px(270,l), w = innerW, h = px(30,l) }
    A.vehicleDoorBackRect = back
    local backHover = mx and pointInRect(mx, my, back)
    dxDrawRectangle(back.x, back.y, back.w, back.h, backHover and COLORS.cardHover or tocolor(50,55,70,255))
    drawText("Back", back.x, back.y, back.w, back.h, COLORS.text, 0.78 * l.scale, "default-bold", "center", "center")
end


local function getVehicleTuningType(veh)
    if not isElement(veh) then return nil end
    local t = getVehicleType(veh)
    if t == "Automobile" or t == "Monster Truck" or t == "Quad" then return "Car" end
    if t == "Bike" then return "Bike" end
    if t == "BMX" then return "Bicycle" end
    if t == "Boat" then return "Boat" end
    if t == "Plane" then return "Plane" end
    if t == "Helicopter" then return "Helicopter" end
    if t == "Train" then return "Train" end
    return t
end

local TUNING_OPTIONS = {
    Car = {"Kit","Spoiler","Hood","Side Skirt","Exhaust","Wheels","Paintjob","Neon","Nitro","Hydraulics","Cruise Control","Steering Sensitivity","Acceleration","Brake Power","Vehicle Weight","Vehicle Height","Vehicle Durability","Engine Sound","Remove Upgrade"},
    Bike = {"Cruise Control","Neon","Steering Sensitivity","Acceleration","Brake Power","Vehicle Durability","Remove Upgrade"},
    Bicycle = {"Steering Sensitivity","Acceleration","Remove Upgrade"},
    Boat = {"Teleport To Water","Acceleration","Remove Upgrade"},
    Plane = {"Acceleration","Remove Upgrade"},
    Helicopter = {"Rotor Speed","Acceleration","Remove Upgrade"},
    Train = {"Direction","Derailable"}
}

local function openVehicleTuningMenu()
    local veh, context, err = getVehicleActionTarget()
    if not veh then
        outputChatBox("[Vehicle Tools] ERROR: "..tostring(err or "No target vehicle found."),255,80,80)
        return
    end
    clearVehicleColorMenu()
    A.vehicleDoorMenu = false
    A.vehicleTuningMenu = true
    A.vehicleTuningTarget = veh
    A.vehicleTuningType = getVehicleTuningType(veh)
    A.vehicleTuningRects = {}
    A.vehicleTuningBackRect = nil
end

local function drawVehicleTuningMenu(contentX, contentY, leftW, l, mx, my)
    local veh = A.vehicleTuningTarget
    local typ = A.vehicleTuningType or getVehicleTuningType(veh) or "Unknown"

    local panelW = px(430,l)
    local x = contentX + math.max(0,(leftW-panelW)/2)
    local y = contentY + px(10,l)

    dxDrawRectangle(x,y,panelW,px(430,l),COLORS.panel)

    drawText("🔧 Tuning Tools",x,y+px(8,l),panelW,px(24,l),COLORS.text,.9*l.scale,"default-bold","center","center")

    local model = veh and getElementModel(veh) or 0
    drawText("Vehicle ID: "..tostring(model).."   Type: "..tostring(typ),
        x,y+px(34,l),panelW,px(18,l),COLORS.subtext,.55*l.scale,"default","center","center")

    A.vehicleTuningRects={}

    local opts=TUNING_OPTIONS[typ] or {}
    local startY=y+px(62,l)
    local cols=2
    local bw=px(180,l)
    local bh=px(32,l)

    for i,name in ipairs(opts) do
        local col=(i-1)%cols
        local row=math.floor((i-1)/cols)

        local r={
            x=x+px(25,l)+col*px(190,l),
            y=startY+row*px(38,l),
            w=bw,
            h=bh,
            id=name
        }

        local hov=mx and pointInRect(mx,my,r)

        dxDrawRectangle(
            r.x,r.y,r.w,r.h,
            hov and COLORS.cardHover or COLORS.card
        )

        drawText(
            name,
            r.x,r.y,r.w,r.h,
            COLORS.text,
            .65*l.scale,
            "default-bold",
            "center",
            "center"
        )

        A.vehicleTuningRects[#A.vehicleTuningRects+1]=r
    end

    A.vehicleTuningBackRect={
        x=x+px(25,l),
        y=y+px(385,l),
        w=panelW-px(50,l),
        h=px(28,l)
    }

    dxDrawRectangle(
        A.vehicleTuningBackRect.x,
        A.vehicleTuningBackRect.y,
        A.vehicleTuningBackRect.w,
        A.vehicleTuningBackRect.h,
        COLORS.card
    )

    drawText(
        "← Back",
        A.vehicleTuningBackRect.x,
        A.vehicleTuningBackRect.y,
        A.vehicleTuningBackRect.w,
        A.vehicleTuningBackRect.h,
        COLORS.text,
        .75*l.scale,
        "default-bold",
        "center",
        "center"
    )
end

local function executeVehicleAction(action)
    local placeholders = {
        plate = "Set Plate is not implemented yet.",
        respawn = "Respawn is not implemented yet.",
        tuning = "Tuning Tools opened."
    }

    if action == "tuning" then
        openVehicleTuningMenu()
        return true
    end

    if placeholders[action] then
        outputChatBox("[Vehicle Tools] " .. placeholders[action], 245, 191, 66)
        return true
    end

    if action == "color" then
        openVehicleColorMenu()
        return true
    end

    if action == "door" then
        openVehicleDoorMenu()
        return true
    end

    local veh, context, targetError = getVehicleActionTarget()
    if not veh or not isElement(veh) then
        outputChatBox("[Vehicle Tools] ERROR: " .. tostring(targetError or "No target vehicle found."), 255, 80, 80)
        return true
    end

    local serverActions = {
        fix = true,
        gm = true,
        lock = true,
        freeze = true,
        engine = true,
        lights = true,
        ejectDriver = true,
        ejectAll = true
    }

    if not serverActions[action] then
        outputChatBox("[Vehicle Tools] ERROR: Unknown vehicle action: " .. tostring(action), 255, 80, 80)
        return true
    end

    triggerServerEvent("scStaff:vehicleAction", resourceRoot, veh, action, context)
    return true
end

local function drawActions(category, rightX, topY, rightW, l, mx, my)
    A.actionRects = {}

    local titleMap = {
        player = "Player Actions",
        punishment = "Punishment Actions",
        vehicle = "Vehicle Actions"
    }

    drawText(titleMap[category] or "Actions", rightX, topY, rightW, px(34, l), COLORS.text, 1.05 * l.scale, "default-bold")

    local selected = findPlayerData(A.selectedID)
    local actions = getActionsForCategory(category)

    if category ~= "vehicle" then
        local targetText = selected and (("Target: %s [%s]"):format(tostring(selected.username or "Unknown"), tostring(selected.id or "-"))) or "Target: No player selected"
        drawText(targetText, rightX, topY + px(32, l), rightW, px(28, l), selected and COLORS.good or COLORS.warning, 0.86 * l.scale, "default-bold", "left", "center", true)
    end
    local actionOffset = px(0,l)
    if category == "vehicle" then
        drawVehicleInformationCard(rightX, topY + px(34,l), rightW, l)
        actionOffset = px(126,l)
    end

    -- Vehicle Tools buttons
    if category == "vehicle" then
        local targetVehicle = getVehicleActionTarget()
        local gmEnabled = targetVehicle and isElement(targetVehicle) and getElementData(targetVehicle, "sc_staff:vehicleGM") == true
        local locked = targetVehicle and isElement(targetVehicle) and isVehicleLocked(targetVehicle) == true
        local frozen = targetVehicle and isElement(targetVehicle) and isElementFrozen(targetVehicle) == true
        local engineOn = targetVehicle and isElement(targetVehicle) and getVehicleEngineState(targetVehicle) == true
        local lightsOn = targetVehicle and isElement(targetVehicle) and getVehicleOverrideLights(targetVehicle) == 2

        local vehicleButtons = {
            {id="fix", label="Fix Vehicle"},
            {id="gm", label="GM: Normal", toggle="GM"},
            {id="lock", label="Lock", toggle="Unlock"},
            {id="freeze", label="Freeze", toggle="Unfreeze"},
            {id="engine", label="Engine On", toggle="Engine Off"},
            {id="lights", label="Lights On", toggle="Lights Off"},
            {id="color", label="Set Color"},
            {id="plate", label="Set Plate"},
            {id="ejectDriver", label="Eject Driver"},
            {id="ejectAll", label="Eject Occupants"},
            {id="respawn", label="Respawn"},
            {id="door", label="Vehicle Door"},
            {id="tuning", label="Tuning Tools"}
        }

        local gap = px(8, l)
        local buttonH = px(38, l)
        local buttonW = (rightW - gap) / 2
        local startY = topY + px(168, l)

        for index, item in ipairs(vehicleButtons) do
            local row = math.floor((index - 1) / 2)
            local column = (index - 1) % 2
            local rect = {
                x = rightX + column * (buttonW + gap),
                y = startY + row * (buttonH + gap),
                w = (index == #vehicleButtons and column == 0) and rightW or buttonW,
                h = buttonH,
                action = item.id
            }
            local label = item.label
            if item.id == "gm" then label = gmEnabled and "Normal" or "GM" end
            if item.id == "lock" then label = locked and "Unlock" or "Lock" end
            if item.id == "freeze" then label = frozen and "Unfreeze" or "Freeze" end
            if item.id == "engine" then label = engineOn and "Engine Off" or "Engine On" end
            if item.id == "lights" then label = lightsOn and "Lights Off" or "Lights On" end
            local hovered = mx and pointInRect(mx, my, rect)
            dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, hovered and COLORS.cardHover or COLORS.card)
            dxDrawRectangle(rect.x, rect.y, px(4, l), rect.h, COLORS.accent)
            drawText(label, rect.x + px(12, l), rect.y, rect.w - px(20, l), rect.h, COLORS.text, 0.74 * l.scale, "default-bold", "left", "center", true)
            A.actionRects[#A.actionRects + 1] = rect
        end

        return
    end

    if #actions == 0 then
        return
    end

    local twoColumns = #actions > 8
    local columns = twoColumns and 2 or 1
    local gap = px(8, l)
    local buttonH = twoColumns and px(38, l) or px(46, l)
    local buttonW = (rightW - gap * (columns - 1)) / columns
    local startY = topY + (category == "vehicle" and px(42, l) + actionOffset or px(72, l))

    for index, actionName in ipairs(actions) do
        local definition = SC_STAFF.ADMIN_ACTIONS[actionName]
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local rect = {
            x = rightX + column * (buttonW + gap),
            y = startY + row * (buttonH + gap),
            w = buttonW,
            h = buttonH,
            action = actionName
        }

        local hovered = mx and pointInRect(mx, my, rect)
        local disabled = A.pending or (definition.needsTarget and not selected)
        local activeInput = A.inputAction == actionName
        local color = hovered and COLORS.cardHover or COLORS.card

        if disabled then
            color = tocolor(24, 28, 36, 190)
        elseif definition.danger then
            color = hovered and tocolor(115, 42, 50, 255) or tocolor(82, 35, 42, 255)
        elseif activeInput then
            color = COLORS.accentSoft
        end

        dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, color)
        dxDrawRectangle(rect.x, rect.y, px(4, l), rect.h, disabled and COLORS.muted or COLORS.accent)
        drawText(definition.label or actionName, rect.x + px(12, l), rect.y, rect.w - px(20, l), rect.h, disabled and COLORS.muted or COLORS.text, 0.76 * l.scale, "default-bold", "left", "center", true)

        if not disabled then
            A.actionRects[#A.actionRects + 1] = rect
        end
    end

    if category == "punishment" then
        drawText("Kick Reason", rightX, l.y + l.h - px(103, l), rightW, px(25, l), COLORS.muted, 0.82 * l.scale, "default-bold")
    elseif category == "player" then
        drawInputPanel(rightX, rightW, l, mx, my)
    end
end

function A.render()
    if not A.visible then
        return
    end

    if SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.isMapMode and SC_ADMIN_DASHBOARD.isMapMode() then
        return
    end

    A.updateLayout()

    local l = A.getLayout()
    local mx, my = getCursorPixel()
    local contentX = l.x + l.sidebarW + px(24, l)
    local contentY = l.y + l.headerH + px(24, l)
    local leftW = px(510, l)
    local rightX = contentX + leftW + px(24, l)
    local rightW = l.x + l.w - px(24, l) - rightX

    -- Vehicle Color mode hides player list area
    if A.vehicleColorMenu or A.vehicleDoorMenu or A.vehicleTuningMenu then
        guiSetVisible(A.elements.searchEdit, false)
        guiSetVisible(A.elements.sortCombo, false)
        A.refreshRect = nil
        A.tableRect = nil
        A.playerRowRects = {}
    end

    dxDrawRectangle(0, 0, l.sw, l.sh, COLORS.overlay)
    dxDrawRectangle(l.x, l.y, l.w, l.h, COLORS.panel)
    dxDrawRectangle(l.x, l.y, l.w, l.headerH, COLORS.header)
    dxDrawRectangle(l.x, l.y + l.headerH, l.sidebarW, l.h - l.headerH, COLORS.sidebar)
    dxDrawRectangle(l.x + l.sidebarW, l.y + l.headerH, px(1, l), l.h - l.headerH, COLORS.line)

    drawText("STARS CITY", l.x + px(22, l), l.y, px(180, l), l.headerH, COLORS.accent, 1.04 * l.scale, "default-bold")
    drawText("Admin Control Panel", l.x + l.sidebarW + px(24, l), l.y, px(420, l), l.headerH, COLORS.text, 1.18 * l.scale, "default-bold")

    local rankText = A.snapshot and (tostring(A.snapshot.actorRankName or "Staff") .. "  •  F2") or "Staff"
    drawText(rankText, l.x + l.w - px(300, l), l.y, px(235, l), l.headerH, COLORS.muted, 0.86 * l.scale, "default-bold", "right")

    A.closeRect = { x = l.x + l.w - px(52, l), y = l.y + px(18, l), w = px(32, l), h = px(32, l) }
    local closeHover = mx and pointInRect(mx, my, A.closeRect)
    dxDrawRectangle(A.closeRect.x, A.closeRect.y, A.closeRect.w, A.closeRect.h, closeHover and COLORS.danger or COLORS.card)
    drawText("X", A.closeRect.x, A.closeRect.y, A.closeRect.w, A.closeRect.h, COLORS.text, 0.9 * l.scale, "default-bold", "center")

    A.navRects = {}
    local navY = l.y + l.headerH + px(24, l)
    for _, item in ipairs(NAV_ITEMS) do
        if canShowNavItem(item) then
        local rect = { x = l.x + px(12, l), y = navY, w = l.sidebarW - px(24, l), h = px(46, l), id = item.id }
        local active = A.category == item.id
        local hover = mx and pointInRect(mx, my, rect)

        if active then
            dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, COLORS.accentSoft)
            dxDrawRectangle(rect.x, rect.y, px(4, l), rect.h, COLORS.accent)
        elseif hover then
            dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, COLORS.card)
        end

        drawText(item.label, rect.x + px(16, l), rect.y, rect.w - px(24, l), rect.h, active and COLORS.text or COLORS.muted, 0.9 * l.scale, "default-bold")
        A.navRects[#A.navRects + 1] = rect
        navY = navY + px(54, l)
        end
    end

    if A.vehicleColorMenu or A.vehicleDoorMenu or A.vehicleTuningMenu then
        guiSetVisible(A.elements.searchEdit, false)
        guiSetVisible(A.elements.sortCombo, false)
        A.refreshRect = nil
        A.tableRect = nil
        A.playerRowRects = {}
    elseif A.category == "staff" then
        guiSetVisible(A.elements.searchEdit, false)
        guiSetVisible(A.elements.sortCombo, false)
        A.refreshRect = nil
        A.tableRect = nil
        A.playerRowRects = {}
    elseif A.category ~= "dashboard" then
        local playerContext = A.category == "player" and SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.isContextMode and SC_ADMIN_PLAYER_TOOLS.isContextMode()
        local punishmentContext = A.category == "punishment" and SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.isContextMode and SC_ADMIN_PUNISHMENTS.isContextMode()
        if playerContext or punishmentContext then
            guiSetVisible(A.elements.searchEdit, false)
            guiSetVisible(A.elements.sortCombo, false)
            A.refreshRect = nil
            A.tableRect = nil
            A.playerRowRects = {}
            local paneH = l.h - l.headerH - px(48, l)
            if playerContext then
                SC_ADMIN_PLAYER_TOOLS.renderLeft(contentX, contentY, leftW, paneH, l, mx, my)
            end
        else
            guiSetVisible(A.elements.searchEdit, true)
            guiSetVisible(A.elements.sortCombo, true)
            drawText(A.category == "punishment" and "ALL PLAYERS" or "PLAYERS", contentX, contentY - px(23, l), leftW, px(20, l), COLORS.muted, 0.74 * l.scale, "default-bold")

            A.refreshRect = { x = contentX + leftW - px(90, l), y = contentY - px(27, l), w = px(90, l), h = px(22, l) }
            local refreshHover = mx and pointInRect(mx, my, A.refreshRect)
            drawText("Refresh", A.refreshRect.x, A.refreshRect.y, A.refreshRect.w, A.refreshRect.h, refreshHover and COLORS.text or COLORS.muted, 0.78 * l.scale, "default-bold", "right")
            drawPlayerTable(contentX, contentY, leftW, l, mx, my)
        end
    else
        guiSetVisible(A.elements.searchEdit, false)
        guiSetVisible(A.elements.sortCombo, false)
        A.refreshRect = nil
        A.tableRect = nil
        A.playerRowRects = {}
    end

    guiSetVisible(A.elements.reasonEdit, false)
    guiSetVisible(A.elements.valueEdit, false)

    if A.vehicleColorMenu or A.vehicleDoorMenu or A.vehicleTuningMenu then
        -- Only replace the middle player list area. Keep Vehicle Actions visible.
        A.actionRects = {}
        drawActions(A.category, rightX, contentY - px(6, l), rightW, l, mx, my)
        if A.vehicleColorMenu then
            drawVehicleColorMenu(contentX, contentY, l, mx, my)
        elseif A.vehicleDoorMenu then
            drawVehicleDoorMenu(contentX, contentY, leftW, l, mx, my)
        else
            drawVehicleTuningMenu(contentX, contentY, leftW, l, mx, my)
        end
    elseif A.category == "staff" then
        A.actionRects = {}
        A.clearInputAction()
        local contentW = l.x + l.w - px(24, l) - contentX
        local paneH = l.h - l.headerH - px(48, l)
        if SC_ADMIN_STAFF_MANAGEMENT and SC_ADMIN_STAFF_MANAGEMENT.render then
            SC_ADMIN_STAFF_MANAGEMENT.render(contentX, contentY, contentW, paneH, l, mx, my)
        end
    elseif A.category == "dashboard" then
        A.actionRects = {}
        A.clearInputAction()
        local contentW = l.x + l.w - px(24, l) - contentX
        if SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.render then
            SC_ADMIN_DASHBOARD.render(contentX, contentY, contentW, l, mx, my)
        end
    elseif A.category == "info" then
        A.actionRects = {}
        A.clearInputAction()
        drawPlayerInfo(rightX, contentY - px(6, l), rightW, l)
    elseif A.category == "player" then
        A.actionRects = {}
        A.clearInputAction()
        local paneH = l.h - l.headerH - px(48, l)
        if SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.renderActions then
            SC_ADMIN_PLAYER_TOOLS.renderActions(rightX, contentY - px(6, l), rightW, paneH, l, mx, my)
        end
    elseif A.category == "punishment" then
        A.actionRects = {}
        A.clearInputAction()
        local paneH = l.h - l.headerH - px(48, l)
        if SC_ADMIN_PUNISHMENTS then
            if SC_ADMIN_PUNISHMENTS.isContextMode and SC_ADMIN_PUNISHMENTS.isContextMode() then
                local contentW = l.x + l.w - px(24, l) - contentX
                SC_ADMIN_PUNISHMENTS.renderContext(contentX, contentY - px(6, l), contentW, paneH, l, mx, my)
            elseif SC_ADMIN_PUNISHMENTS.renderActions then
                SC_ADMIN_PUNISHMENTS.renderActions(rightX, contentY - px(6, l), rightW, paneH, l, mx, my)
            end
        end
    elseif A.category == "vehicle_management" then
        A.actionRects = {}
        A.clearInputAction()
        if SC_ADMIN_VEHICLE_MANAGEMENT and SC_ADMIN_VEHICLE_MANAGEMENT.render then
            local contentW = l.x + l.w - px(24, l) - contentX
            SC_ADMIN_VEHICLE_MANAGEMENT.render(contentX, contentY - px(6,l), contentW, l.h, l, mx, my)
        end
    else
        A.clearInputAction()
        drawActions(A.category, rightX, contentY - px(6, l), rightW, l, mx, my)
    end

    if A.pending then
        drawText("Processing admin action...", rightX, l.y + l.h - px(18, l), rightW, px(16, l), COLORS.warning, 0.75 * l.scale, "default-bold", "right")
    end

    local interval = SC_STAFF.ADMIN_PANEL.refreshInterval or 5000
    if getTickCount() - A.lastRefreshTick >= interval then
        A.lastRefreshTick = getTickCount()
        triggerServerEvent("scAdminRequestSnapshot", resourceRoot)
        if A.category == "punishment" and SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.refreshTargets then
            SC_ADMIN_PUNISHMENTS.refreshTargets(false)
        end
    end
end

local function sendAction(actionName, forceSubmit)
    if A.pending or not A.permissions[actionName] then
        return
    end

    local definition = SC_STAFF.ADMIN_ACTIONS[actionName]
    if not definition then
        return
    end

    if definition.needsTarget and not A.selectedID then
        outputChatBox("[StarsCity] Aval Yek Player Entekhab Konid.", 255, 90, 90)
        return
    end

    if definition.needsValue and not forceSubmit then
        A.setInputAction(actionName)
        return
    end

    local data = {}

    if definition.needsValue then
        data.value = guiGetText(A.elements.valueEdit) or ""
        if data.value:gsub("%s+", "") == "" then
            outputChatBox("[StarsCity] Meghdar Action Ra Vared Konid.", 255, 90, 90)
            return
        end
    end

    if definition.needsReason then
        data.reason = guiGetText(A.elements.reasonEdit) or ""
        if #data.reason < 3 then
            outputChatBox("[StarsCity] Baraye Kick Reason Vared Konid.", 255, 90, 90)
            return
        end
    end

    A.lastSubmittedAction = actionName
    A.setPending(true)
    triggerServerEvent("scAdminExecuteAction", resourceRoot, actionName, A.selectedID, data)
end

local function submitInputAction()
    if not A.inputAction then
        return
    end

    sendAction(A.inputAction, true)
end

addEvent("scAdminOpenPanel", true)
addEventHandler("scAdminOpenPanel", resourceRoot, function(snapshot, initialCategory)
    if SC_STAFF_CLIENT and SC_STAFF_CLIENT.visible and SC_STAFF_CLIENT.close then
        SC_STAFF_CLIENT.close()
    end

    if A.visible then
        A.applySnapshot(snapshot)
        if initialCategory == "staff" and SC_STAFF.hasManagerAccess(tonumber(snapshot and snapshot.actorRank) or 0) then
            A.category = "staff"
            if SC_ADMIN_STAFF_MANAGEMENT and SC_ADMIN_STAFF_MANAGEMENT.enter then
                SC_ADMIN_STAFF_MANAGEMENT.enter()
            end
        end
        return
    end
    A.open(snapshot, initialCategory)
end)

addEvent("scAdminSnapshot", true)
addEventHandler("scAdminSnapshot", resourceRoot, function(snapshot)
    if A.visible then
        A.applySnapshot(snapshot)
    end
end)

addEvent("scAdminActionResult", true)
addEventHandler("scAdminActionResult", resourceRoot, function(success, message, refresh)
    A.setPending(false)
    if SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.onStandardActionResult then
        SC_ADMIN_PLAYER_TOOLS.onStandardActionResult(success == true, message)
    end

    if success then
        outputChatBox("[StarsCity] " .. tostring(message), 80, 220, 120)
        if A.lastSubmittedAction and SC_STAFF.ADMIN_ACTIONS[A.lastSubmittedAction] and SC_STAFF.ADMIN_ACTIONS[A.lastSubmittedAction].needsValue then
            A.clearInputAction()
        end
    else
        outputChatBox("[StarsCity] Khata: " .. tostring(message), 255, 80, 80)
    end

    A.lastSubmittedAction = nil

    -- Do NOT clear vehicleColorTarget / vehicleColorType here.
    -- scAdminActionResult is also fired after every successful color Apply.
    -- The shared sc_color picker intentionally stays open, so these values
    -- must survive repeated Apply presses and keep targeting the same vehicle
    -- and the same color channel until the picker session is explicitly changed.

    if refresh and A.visible then
        triggerServerEvent("scAdminRequestSnapshot", resourceRoot)
    end
end)

addEvent("scAdminForceClose", true)
addEventHandler("scAdminForceClose", resourceRoot, function(message)
    if message and message ~= "" then
        outputChatBox("[StarsCity] " .. tostring(message), 255, 80, 80)
    end
    A.close()
end)

addEventHandler("onClientGUIChanged", root, function()
    if source == A.elements.searchEdit and A.visible then
        A.filterPlayers()
    end
end)

addEventHandler("onClientGUIComboBoxAccepted", root, function()
    if not A.visible or source ~= A.elements.sortCombo then
        return
    end

    local selected = guiComboBoxGetSelected(A.elements.sortCombo)
    local option = SORT_OPTIONS[(selected or -1) + 1]
    if option then
        A.sortMode = option.id
        A.filterPlayers()
    end
end)

addEventHandler("onClientGUIAccepted", root, function()
    if not A.visible then
        return
    end

    if source == A.elements.valueEdit and A.inputAction then
        submitInputAction()
    end
    if A.vehicleColorMenu then
        drawVehicleColorMenu(contentX, contentY, l, mx, my)
    end

end)

addEventHandler("onClientClick", root, function(button, state, x, y)
    if not A.visible or button ~= "left" or state ~= "up" then
        return
    end

    if SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.isMapMode and SC_ADMIN_DASHBOARD.isMapMode() then
        return
    end

    if pointInRect(x, y, A.closeRect) then
        A.close()
        return
    end

    if A.refreshRect and pointInRect(x, y, A.refreshRect) then
        A.lastRefreshTick = getTickCount()
        triggerServerEvent("scAdminRequestSnapshot", resourceRoot)
        if A.category == "punishment" and SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.refreshTargets then
            SC_ADMIN_PUNISHMENTS.refreshTargets(true)
        end
        return
    end

    if A.category == "dashboard" and SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.handleClick then
        if SC_ADMIN_DASHBOARD.handleClick(x, y) then
            return
        end
    end

    if A.category == "player" and SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.handleClick then
        if SC_ADMIN_PLAYER_TOOLS.handleClick(x, y) then
            return
        end
    end

    if A.category == "staff" and SC_ADMIN_STAFF_MANAGEMENT and SC_ADMIN_STAFF_MANAGEMENT.handleClick then
        if SC_ADMIN_STAFF_MANAGEMENT.handleClick(x, y) then
            return
        end
    end

    if A.category == "punishment" and SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.handleClick then
        if SC_ADMIN_PUNISHMENTS.handleClick(x, y) then
            return
        end
    end

    if A.category == "vehicle_management" and SC_ADMIN_VEHICLE_MANAGEMENT and SC_ADMIN_VEHICLE_MANAGEMENT.handleClick then
        if SC_ADMIN_VEHICLE_MANAGEMENT.handleClick(x,y) then
            return
        end
    end

    if A.inputAction and pointInRect(x, y, A.inputApplyRect) then
        submitInputAction()
        return
    end

    if A.inputAction and pointInRect(x, y, A.inputCancelRect) then
        A.clearInputAction()
        return
    end

    for _, rect in ipairs(A.playerRowRects or {}) do
        if pointInRect(x, y, rect) then
            if tonumber(A.selectedID) ~= tonumber(rect.id) then
                A.clearInputAction()
            end
            A.selectedID = tonumber(rect.id)
            return
        end
    end

    for _, rect in ipairs(A.navRects) do
        if pointInRect(x, y, rect) then
            if A.category ~= rect.id then
                A.clearInputAction()
            end
            local previousCategory = A.category
            if A.vehicleColorMenu then
                clearVehicleColorMenu()
            end
            if A.vehicleDoorMenu then
                clearVehicleDoorMenu()
            end
            A.category = rect.id
            if SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.reset then
                SC_ADMIN_PLAYER_TOOLS.reset()
            end
            if SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.reset then
                SC_ADMIN_PUNISHMENTS.reset()
            end
            if A.category == "punishment" and SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.enter then
                SC_ADMIN_PUNISHMENTS.enter()
            end
            if SC_ADMIN_STAFF_MANAGEMENT then
                if A.category == "staff" and SC_ADMIN_STAFF_MANAGEMENT.enter then
                    SC_ADMIN_STAFF_MANAGEMENT.enter()
                elseif previousCategory == "staff" and SC_ADMIN_STAFF_MANAGEMENT.closeUI then
                    SC_ADMIN_STAFF_MANAGEMENT.closeUI()
                end
            end
            if A.category == "dashboard" and SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.reset then
                SC_ADMIN_DASHBOARD.reset()
            elseif SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.elements then
                for _, element in pairs(SC_ADMIN_DASHBOARD.elements) do
                    if isElement(element) then guiSetVisible(element, false) end
                end
            end
            A.scrollOffset = 0
            A.filterPlayers()
            guiSetVisible(A.elements.reasonEdit, false)
            return
        end
    end

    if A.vehicleColorMenu then
        if A.vehicleColorBackRect and pointInRect(x,y,A.vehicleColorBackRect) then
            clearVehicleColorMenu()
            return
        end
        for _, rect in ipairs(A.vehicleColorRects or {}) do
            if pointInRect(x,y,rect) then
                openScColorPicker(rect.action)
                return
            end
        end
        -- Do not return here: Vehicle Actions on the right must remain clickable.
    end

    if A.vehicleDoorMenu then
        if A.vehicleDoorBackRect and pointInRect(x, y, A.vehicleDoorBackRect) then
            clearVehicleDoorMenu()
            return
        end
        for _, rect in ipairs(A.vehicleDoorRects or {}) do
            if pointInRect(x, y, rect) then
                local veh = A.vehicleDoorTarget
                if not veh or not isElement(veh) then
                    outputChatBox("[Vehicle Door] ERROR: Target vehicle is no longer available.", 255, 80, 80)
                    clearVehicleDoorMenu()
                    return
                end
                triggerServerEvent("scStaff:vehicleDoorAction", resourceRoot, veh, rect.door, A.vehicleDoorContext)
                return
            end
        end
        -- As with Vehicle Color, clicks in the right Vehicle Actions area continue.
    end

    if A.vehicleTuningMenu then
        if A.vehicleTuningBackRect and pointInRect(x,y,A.vehicleTuningBackRect) then
            A.vehicleTuningMenu = false
            A.vehicleTuningTarget = nil
            A.vehicleTuningRects = {}
            return
        end
        for _, rect in ipairs(A.vehicleTuningRects or {}) do
            if pointInRect(x,y,rect) then
                outputChatBox("[Tuning Tools] Selected: "..tostring(rect.id).." (system setup pending)",245,191,66)
                return
            end
        end
    end

    for _, rect in ipairs(A.actionRects) do
        if pointInRect(x, y, rect) then
            if A.category == "vehicle" and rect.action then
                executeVehicleAction(rect.action)
                return
            end
            sendAction(rect.action, false)
            return
        end
    end
end)

addEventHandler("onClientKey", root, function(button, press)
    if not press then
        return
    end

    if A.visible and (button == "mouse_wheel_up" or button == "mouse_wheel_down") then
        local mx, my = getCursorPixel()
        if mx and A.category == "player" and SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.handleWheel and SC_ADMIN_PLAYER_TOOLS.handleWheel(button, mx, my) then
            cancelEvent()
            return
        end
        if mx and A.category == "punishment" and SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.handleWheel and SC_ADMIN_PUNISHMENTS.handleWheel(button, mx, my) then
            cancelEvent()
            return
        end
        if mx and A.category == "staff" and SC_ADMIN_STAFF_MANAGEMENT and SC_ADMIN_STAFF_MANAGEMENT.handleWheel and SC_ADMIN_STAFF_MANAGEMENT.handleWheel(button, mx, my) then
            cancelEvent()
            return
        end
        if mx and pointInRect(mx, my, A.tableRect) then
            local maxOffset = math.max(0, #(A.filteredPlayers or {}) - math.max(A.visibleRows, 1))
            if button == "mouse_wheel_up" then
                A.scrollOffset = math.max(0, (A.scrollOffset or 0) - 1)
            else
                A.scrollOffset = math.min(maxOffset, (A.scrollOffset or 0) + 1)
            end
            cancelEvent()
            return
        end
    end

    if button == "escape" and A.visible then
        if SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.isMapMode and SC_ADMIN_DASHBOARD.isMapMode() then
            cancelEvent()
            SC_ADMIN_DASHBOARD.cancelMapMode()
            return
        end
        cancelEvent()
        if A.vehicleTuningMenu then
            A.vehicleTuningMenu = false
            A.vehicleTuningTarget = nil
            A.vehicleTuningRects = {}
        elseif A.vehicleDoorMenu then
            clearVehicleDoorMenu()
        elseif A.vehicleColorMenu then
            clearVehicleColorMenu()
        elseif A.category == "player" and SC_ADMIN_PLAYER_TOOLS and SC_ADMIN_PLAYER_TOOLS.isContextMode and SC_ADMIN_PLAYER_TOOLS.isContextMode() then
            SC_ADMIN_PLAYER_TOOLS.back()
        elseif A.category == "punishment" and SC_ADMIN_PUNISHMENTS and SC_ADMIN_PUNISHMENTS.isContextMode and SC_ADMIN_PUNISHMENTS.isContextMode() then
            SC_ADMIN_PUNISHMENTS.back()
        elseif A.inputAction then
            A.clearInputAction()
        else
            A.close()
        end
    end
end)

bindKey(SC_STAFF.ADMIN_PANEL.key or "F2", "down", function()
    if A.visible then
        A.close()
    else
        triggerServerEvent("scAdminRequestOpen", resourceRoot)
    end
end)

addEventHandler("onClientRender", root, function()
    if A.pending and A.pendingSince and getTickCount() - A.pendingSince > 10000 then
        A.setPending(false)
        A.lastSubmittedAction = nil
A.vehicleColorMenu = false
A.vehicleColorRects = {}
A.vehicleColorTarget = nil
A.vehicleColorType = nil
A.vehicleColorContext = nil
        outputChatBox("[StarsCity] Khata: Pasokh Admin Action Daryaft Nashod; Dobare Talash Konid Va Console Server Ra Check Konid.", 255, 80, 80)
    end
    A.render()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    A.vehicleColorTarget = nil
    A.vehicleColorType = nil
    A.vehicleColorContext = nil
    A.vehicleDoorMenu = false
    A.vehicleDoorRects = {}
    A.vehicleDoorBackRect = nil
    A.vehicleDoorTarget = nil
    A.vehicleDoorContext = nil
A.vehicleTuningMenu = false
A.vehicleTuningRects = {}
A.vehicleTuningBackRect = nil
A.vehicleTuningTarget = nil
A.vehicleTuningType = nil
    if A.visible and not A.cursorWasShowing then
        showCursor(false)
    end
end)
