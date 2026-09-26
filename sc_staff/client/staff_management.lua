-- =========================================================
-- STARS CITY - ADMIN PANEL / STAFF MANAGEMENT
-- Integrated staff rank management UI
-- =========================================================

SC_ADMIN_STAFF_MANAGEMENT = SC_ADMIN_STAFF_MANAGEMENT or {}
local M = SC_ADMIN_STAFF_MANAGEMENT
local A = SC_ADMIN_CLIENT

M.elements = M.elements or {
    searchEdit = nil,
    rankCombo = nil
}
M.rows = {}
M.selectedID = nil
M.selectedRow = nil
M.rowRects = {}
M.setRect = nil
M.removeRect = nil
M.refreshRect = nil
M.tableRect = nil
M.scrollOffset = 0
M.visibleRows = 0
M.rankMap = {}
M.searchTimer = nil
M.lastRequestTick = 0
M.lastAutoRefreshTick = 0
M.loading = false
M.message = ""
M.messageGood = false
M.rankSelectionGuardUntil = 0

local function colors()
    return A.COLORS
end

local function px(v, l)
    return A.px(v, l)
end

local function drawText(...)
    return A.drawText(...)
end

local function pointInRect(x, y, rect)
    return A.pointInRect(x, y, rect)
end

local function trim(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function findSelected()
    local id = tonumber(M.selectedID)
    if not id then
        return nil
    end

    for _, row in ipairs(M.rows or {}) do
        if tonumber(row.id) == id then
            return row
        end
    end

    return M.selectedRow and tonumber(M.selectedRow.id) == id and M.selectedRow or nil
end

function M.createUI()
    if isElement(M.elements.searchEdit) then
        return
    end

    M.elements.searchEdit = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(M.elements.searchEdit, 32)

    M.elements.rankCombo = guiCreateComboBox(0, 0, 1, 1, "Select Rank", false)

    guiSetVisible(M.elements.searchEdit, false)
    guiSetVisible(M.elements.rankCombo, false)
end

function M.populateRanks()
    if not isElement(M.elements.rankCombo) then
        return
    end

    local actorRank = A.snapshot and tonumber(A.snapshot.actorRank) or 0
    guiComboBoxClear(M.elements.rankCombo)
    M.rankMap = {}

    for _, rank in ipairs(SC_STAFF.MANAGEABLE_RANK_ORDER or {}) do
        if rank ~= 0 and SC_STAFF.canAssignRank(actorRank, rank) then
            local index = guiComboBoxAddItem(M.elements.rankCombo, ("[%d] %s"):format(rank, SC_STAFF.getRankName(rank)))
            M.rankMap[index] = rank
        end
    end

    guiComboBoxSetSelected(M.elements.rankCombo, -1)
end

function M.reset()
    M.createUI()
    M.rows = {}
    M.selectedID = nil
    M.selectedRow = nil
    M.rowRects = {}
    M.setRect = nil
    M.removeRect = nil
    M.refreshRect = nil
    M.tableRect = nil
    M.scrollOffset = 0
    M.visibleRows = 0
    M.loading = false
    M.message = ""
    M.messageGood = false
    M.rankSelectionGuardUntil = 0

    if isTimer(M.searchTimer) then
        killTimer(M.searchTimer)
    end
    M.searchTimer = nil

    guiSetText(M.elements.searchEdit, "")
    M.populateRanks()
end

function M.closeUI()
    if isTimer(M.searchTimer) then
        killTimer(M.searchTimer)
    end
    M.searchTimer = nil

    if isElement(M.elements.searchEdit) then
        guiSetVisible(M.elements.searchEdit, false)
    end
    if isElement(M.elements.rankCombo) then
        guiSetVisible(M.elements.rankCombo, false)
    end
end

function M.requestData(force)
    if not A.visible or A.category ~= "staff" then
        return
    end

    local now = getTickCount()
    if not force and now - (M.lastRequestTick or 0) < 220 then
        return
    end

    M.lastRequestTick = now
    M.loading = true
    local search = trim(guiGetText(M.elements.searchEdit) or "")
    triggerServerEvent("scAdminRequestStaffManagementData", resourceRoot, search)
end

function M.enter()
    M.createUI()
    M.populateRanks()
    guiSetVisible(M.elements.searchEdit, true)
    guiSetVisible(M.elements.rankCombo, M.selectedID ~= nil)
    M.requestData(true)
end

local function setSelected(row)
    M.selectedID = row and tonumber(row.id) or nil
    M.selectedRow = row
    guiComboBoxSetSelected(M.elements.rankCombo, -1)
    guiSetVisible(M.elements.rankCombo, row ~= nil)
end

local function updateLayout(contentX, contentY, contentW, l)
    local leftW = contentW * 0.58
    local gap = px(18, l)
    local rightX = contentX + leftW + gap
    local rightW = contentW - leftW - gap

    guiSetPosition(M.elements.searchEdit, contentX, contentY + px(27, l), false)
    guiSetSize(M.elements.searchEdit, leftW - px(96, l), px(36, l), false)

    guiSetPosition(M.elements.rankCombo, rightX + px(16, l), contentY + px(197, l), false)
    guiSetSize(M.elements.rankCombo, rightW - px(32, l), px(260, l), false)

    return leftW, rightX, rightW
end

function M.render(contentX, contentY, contentW, paneH, l, mx, my)
    M.createUI()
    local C = colors()
    local leftW, rightX, rightW = updateLayout(contentX, contentY, contentW, l)

    guiSetVisible(M.elements.searchEdit, true)

    drawText("STAFF MANAGEMENT", contentX, contentY - px(22, l), leftW, px(20, l), C.muted, 0.74 * l.scale, "default-bold")
    drawText("Search by Account ID or Username. Empty search shows all registered accounts.", contentX, contentY + px(2, l), leftW, px(20, l), C.muted, 0.72 * l.scale, "default")

    M.refreshRect = { x = contentX + leftW - px(86, l), y = contentY + px(31, l), w = px(86, l), h = px(28, l) }
    local refreshHover = mx and pointInRect(mx, my, M.refreshRect)
    drawText(M.loading and "Loading..." or "Refresh", M.refreshRect.x, M.refreshRect.y, M.refreshRect.w, M.refreshRect.h, refreshHover and C.text or C.muted, 0.76 * l.scale, "default-bold", "right")

    local tableY = contentY + px(76, l)
    local tableH = paneH - px(76, l)
    local headerH = px(38, l)
    local rowH = px(38, l)
    M.tableRect = { x = contentX, y = tableY, w = leftW, h = tableH }
    M.rowRects = {}

    dxDrawRectangle(contentX, tableY, leftW, tableH, tocolor(10, 12, 17, 245))
    dxDrawRectangle(contentX, tableY, leftW, headerH, C.header)

    local columns = {
        { label = "Name", ratio = 0.36, align = "left" },
        { label = "ID", ratio = 0.14, align = "center" },
        { label = "Rank", ratio = 0.30, align = "left" },
        { label = "Status", ratio = 0.20, align = "center" }
    }

    local colX = contentX
    for i, col in ipairs(columns) do
        local colW = leftW * col.ratio
        local pad = col.align == "left" and px(10, l) or 0
        drawText(col.label, colX + pad, tableY, colW - pad, headerH, C.text, 0.78 * l.scale, "default-bold", col.align, "center", true)
        if i < #columns then
            dxDrawRectangle(colX + colW - px(1, l), tableY, px(1, l), tableH, C.line)
        end
        colX = colX + colW
    end

    local usableH = tableH - headerH
    M.visibleRows = math.max(1, math.floor(usableH / rowH))
    local maxOffset = math.max(0, #(M.rows or {}) - M.visibleRows)
    M.scrollOffset = math.max(0, math.min(M.scrollOffset or 0, maxOffset))

    if #M.rows == 0 then
        local emptyText = M.loading and "Loading staff accounts..." or "No staff/account found."
        drawText(emptyText, contentX, tableY + headerH, leftW, usableH, C.muted, 0.88 * l.scale, "default", "center", "center")
    else
        local startIndex = M.scrollOffset + 1
        local endIndex = math.min(#M.rows, M.scrollOffset + M.visibleRows)
        local rowY = tableY + headerH

        for i = startIndex, endIndex do
            local row = M.rows[i]
            local rect = { x = contentX, y = rowY, w = leftW, h = rowH, id = tonumber(row.id) }
            local selected = tonumber(M.selectedID) == tonumber(row.id)
            local hovered = mx and pointInRect(mx, my, rect)

            if selected then
                dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, C.accentSoft)
                dxDrawRectangle(rect.x, rect.y, px(3, l), rect.h, C.accent)
            elseif hovered then
                dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, C.cardHover)
            elseif (i - startIndex) % 2 == 1 then
                dxDrawRectangle(rect.x, rect.y, rect.w, rect.h, tocolor(255, 255, 255, 7))
            end

            local status = row.online and "Online" or "Offline"
            local values = {
                tostring(row.username or "Unknown"),
                tostring(row.id or "-"),
                tostring(row.displayRank or row.rankName or SC_STAFF.getRankName(row.rank)),
                status
            }

            local cellX = contentX
            for ci, col in ipairs(columns) do
                local cellW = leftW * col.ratio
                local pad = col.align == "left" and px(10, l) or 0
                local color = C.text
                if ci == 4 then
                    color = row.online and C.good or C.muted
                elseif tonumber(row.rank) == 0 and ci == 3 then
                    color = C.warning
                end
                drawText(values[ci], cellX + pad, rowY, cellW - pad, rowH, color, 0.78 * l.scale, selected and "default-bold" or "default", col.align, "center", true)
                cellX = cellX + cellW
            end

            dxDrawRectangle(contentX, rowY + rowH - px(1, l), leftW, px(1, l), C.line)
            M.rowRects[#M.rowRects + 1] = rect
            rowY = rowY + rowH
        end
    end

    -- Right-side account management card.
    dxDrawRectangle(rightX, contentY, rightW, paneH, C.card)
    drawText("Manage Staff Rank", rightX + px(16, l), contentY + px(12, l), rightW - px(32, l), px(28, l), C.text, 0.98 * l.scale, "default-bold")

    local selected = findSelected()
    if not selected then
        guiSetVisible(M.elements.rankCombo, false)
        drawText("Select any registered account. Staff are listed first, then faction roles, then Citizens.", rightX + px(18, l), contentY + px(58, l), rightW - px(36, l), px(120, l), C.muted, 0.82 * l.scale, "default", "left", "top", true)
        M.setRect = nil
        M.removeRect = nil
    else
        guiSetVisible(M.elements.rankCombo, true)
        drawText(tostring(selected.username or "Unknown"), rightX + px(16, l), contentY + px(54, l), rightW - px(32, l), px(30, l), C.text, 1.10 * l.scale, "default-bold")
        drawText(("Account ID: %s"):format(tostring(selected.id or "-")), rightX + px(16, l), contentY + px(86, l), rightW - px(32, l), px(24, l), C.muted, 0.78 * l.scale, "default")
        drawText(("Current Rank: %s"):format(tostring(selected.displayRank or selected.rankName or SC_STAFF.getRankName(selected.rank))), rightX + px(16, l), contentY + px(114, l), rightW - px(32, l), px(24, l), C.text, 0.82 * l.scale, "default-bold")
        drawText(("Status: %s"):format(selected.online and "Online" or "Offline"), rightX + px(16, l), contentY + px(142, l), rightW - px(32, l), px(24, l), selected.online and C.good or C.muted, 0.80 * l.scale, "default-bold")
        drawText("New Rank", rightX + px(16, l), contentY + px(174, l), rightW - px(32, l), px(20, l), C.muted, 0.75 * l.scale, "default-bold")

        M.setRect = { x = rightX + px(16, l), y = contentY + px(247, l), w = rightW - px(32, l), h = px(42, l) }
        M.removeRect = { x = rightX + px(16, l), y = contentY + px(301, l), w = rightW - px(32, l), h = px(42, l) }

        local canManage = selected.canManage == true
        local setHover = canManage and mx and pointInRect(mx, my, M.setRect)
        dxDrawRectangle(M.setRect.x, M.setRect.y, M.setRect.w, M.setRect.h, canManage and (setHover and C.cardHover or tocolor(43, 52, 68, 255)) or tocolor(24, 28, 36, 190))
        dxDrawRectangle(M.setRect.x, M.setRect.y, px(4, l), M.setRect.h, canManage and C.accent or C.muted)
        drawText("Set Rank", M.setRect.x + px(12, l), M.setRect.y, M.setRect.w - px(20, l), M.setRect.h, canManage and C.text or C.muted, 0.82 * l.scale, "default-bold", "center")

        local canRemove = canManage and (tonumber(selected.rank) or 0) > 0
        local removeHover = canRemove and mx and pointInRect(mx, my, M.removeRect)
        dxDrawRectangle(M.removeRect.x, M.removeRect.y, M.removeRect.w, M.removeRect.h, canRemove and (removeHover and tocolor(115, 42, 50, 255) or tocolor(82, 35, 42, 255)) or tocolor(24, 28, 36, 190))
        dxDrawRectangle(M.removeRect.x, M.removeRect.y, px(4, l), M.removeRect.h, canRemove and C.danger or C.muted)
        drawText("Remove Staff (Citizen)", M.removeRect.x + px(12, l), M.removeRect.y, M.removeRect.w - px(20, l), M.removeRect.h, canRemove and C.text or C.muted, 0.80 * l.scale, "default-bold", "center")

        local actorRank = A.snapshot and tonumber(A.snapshot.actorRank) or 0
        local targetRank = tonumber(selected.rank) or 0
        if tonumber(selected.id) == tonumber(getElementData(localPlayer, "account:id")) then
            drawText("Your own rank cannot be changed here.", rightX + px(16, l), contentY + px(360, l), rightW - px(32, l), px(44, l), C.warning, 0.76 * l.scale, "default", "left", "top", true)
        elseif targetRank > 0 and targetRank <= actorRank then
            drawText("This staff rank is equal to or higher than yours and is protected.", rightX + px(16, l), contentY + px(360, l), rightW - px(32, l), px(54, l), C.warning, 0.76 * l.scale, "default", "left", "top", true)
        end
    end

    if M.message ~= "" then
        drawText(M.message, rightX + px(16, l), contentY + paneH - px(54, l), rightW - px(32, l), px(42, l), M.messageGood and C.good or C.danger, 0.74 * l.scale, "default-bold", "left", "center", true)
    end

    if getTickCount() - (M.lastAutoRefreshTick or 0) > 5000 and not A.pending then
        M.lastAutoRefreshTick = getTickCount()
        M.requestData(false)
    end
end

function M.handleClick(x, y)
    if getTickCount() < (M.rankSelectionGuardUntil or 0) then
        return true
    end

    if M.refreshRect and pointInRect(x, y, M.refreshRect) then
        M.requestData(true)
        return true
    end

    for _, rect in ipairs(M.rowRects or {}) do
        if pointInRect(x, y, rect) then
            for _, row in ipairs(M.rows or {}) do
                if tonumber(row.id) == tonumber(rect.id) then
                    setSelected(row)
                    return true
                end
            end
        end
    end

    local selected = findSelected()
    if not selected or A.pending then
        return false
    end

    if selected.canManage ~= true then
        return false
    end

    if M.setRect and pointInRect(x, y, M.setRect) then
        local comboIndex = guiComboBoxGetSelected(M.elements.rankCombo)
        local rank = M.rankMap[comboIndex]
        if rank == nil then
            M.message = "Select a new rank first."
            M.messageGood = false
            return true
        end

        A.setPending(true)
        M.message = ""
        triggerServerEvent("scAdminSetStaffRank", resourceRoot, tonumber(selected.id), tonumber(rank))
        return true
    end

    if M.removeRect and pointInRect(x, y, M.removeRect) and (tonumber(selected.rank) or 0) > 0 then
        A.setPending(true)
        M.message = ""
        triggerServerEvent("scAdminSetStaffRank", resourceRoot, tonumber(selected.id), 0)
        return true
    end

    return false
end

function M.handleWheel(button, mx, my)
    if not M.tableRect or not pointInRect(mx, my, M.tableRect) then
        return false
    end

    local maxOffset = math.max(0, #(M.rows or {}) - math.max(M.visibleRows, 1))
    if button == "mouse_wheel_up" then
        M.scrollOffset = math.max(0, (M.scrollOffset or 0) - 1)
    else
        M.scrollOffset = math.min(maxOffset, (M.scrollOffset or 0) + 1)
    end
    return true
end

addEvent("scAdminStaffManagementData", true)
addEventHandler("scAdminStaffManagementData", resourceRoot, function(success, message, rows)
    if not A.visible or A.category ~= "staff" then
        return
    end

    M.loading = false
    if not success then
        M.message = tostring(message or "Failed to load staff data.")
        M.messageGood = false
        return
    end

    M.rows = type(rows) == "table" and rows or {}
    M.scrollOffset = 0

    if M.selectedID then
        local found = nil
        for _, row in ipairs(M.rows) do
            if tonumber(row.id) == tonumber(M.selectedID) then
                found = row
                break
            end
        end
        if found then
            M.selectedRow = found
        else
            setSelected(nil)
        end
    end
end)

addEvent("scAdminStaffRankResult", true)
addEventHandler("scAdminStaffRankResult", resourceRoot, function(success, message)
    A.setPending(false)
    M.message = tostring(message or "")
    M.messageGood = success == true

    if success then
        guiComboBoxSetSelected(M.elements.rankCombo, -1)
        M.requestData(true)
        triggerServerEvent("scAdminRequestSnapshot", resourceRoot)
    end
end)

addEventHandler("onClientGUIComboBoxAccepted", root, function()
    if source ~= M.elements.rankCombo or not A.visible or A.category ~= "staff" then
        return
    end

    -- The native combo list can visually overlap the DX Set Rank button.
    -- Consume the same mouse release so selecting a rank never also submits it.
    M.rankSelectionGuardUntil = getTickCount() + 350
end)

addEventHandler("onClientGUIChanged", root, function()
    if source ~= M.elements.searchEdit or not A.visible or A.category ~= "staff" then
        return
    end

    if isTimer(M.searchTimer) then
        killTimer(M.searchTimer)
    end

    M.searchTimer = setTimer(function()
        M.searchTimer = nil
        M.scrollOffset = 0
        setSelected(nil)
        M.requestData(true)
    end, 320, 1)
end)
