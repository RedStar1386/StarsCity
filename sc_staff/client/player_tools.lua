-- =========================================================
-- STARS CITY - PLAYER TOOLS UI
-- Contextual left-pane tools for Admin Control Panel
-- =========================================================

SC_ADMIN_PLAYER_TOOLS = SC_ADMIN_PLAYER_TOOLS or {}
local P = SC_ADMIN_PLAYER_TOOLS
local A = SC_ADMIN_CLIENT

P.mode = "home"
P.section = nil
P.animStart = 0
P.scroll = 0
P.visibleRows = 0
P.tableRect = nil
P.actionRects = {}
P.rowRects = {}
P.backRect = nil
P.filtered = {}
P.data = { weapons = {}, vehicles = {}, skills = {}, licenses = {}, inventory = {}, stats = {} }
P.pendingStandardAction = nil
P.spectatingID = nil
P.localHardFreeze = false
P.localGodMode = false
P.sanitizeGuard = false
P.elements = { search = nil, sort = nil, value1 = nil, value2 = nil, skillEdits = {} }
P.inputRects = {}
P.freezeControlStates = {}

-- Controls managed by the admin hard-freeze. We snapshot the enabled state of
-- each control before freezing and restore only that state afterwards instead
-- of blindly enabling every GTA control.
local HARD_FREEZE_CONTROLS = {
    "fire", "next_weapon", "previous_weapon", "forwards", "backwards", "left", "right",
    "zoom_in", "zoom_out", "enter_exit", "change_camera", "jump", "sprint", "look_behind",
    "crouch", "action", "walk", "aim_weapon", "conversation_yes", "conversation_no",
    "group_control_forwards", "group_control_back", "vehicle_fire", "vehicle_secondary_fire",
    "vehicle_left", "vehicle_right", "steer_forward", "steer_back", "accelerate", "brake_reverse",
    "radio_next", "radio_previous", "radio_user_track_skip", "horn", "sub_mission", "handbrake",
    "vehicle_look_left", "vehicle_look_right", "vehicle_look_behind", "vehicle_mouse_look",
    "special_control_left", "special_control_right", "special_control_down", "special_control_up"
}

local HARD_FREEZE_CONTROL_SET = {}
for _, control in ipairs(HARD_FREEZE_CONTROLS) do
    HARD_FREEZE_CONTROL_SET[control] = true
end

function P.isHardFreezeActive()
    return P.localHardFreeze == true
end

function P.setControlRespectingHardFreeze(control, enabled)
    if enabled == true and P.localHardFreeze and HARD_FREEZE_CONTROL_SET[control] then
        pcall(toggleControl, control, false)
        if type(setControlState) == "function" then
            pcall(setControlState, control, false)
        end
        return false
    end
    pcall(toggleControl, control, enabled == true)
    return true
end

local function getControlEnabledSafe(control)
    if type(isControlEnabled) == "function" then
        local ok, enabled = pcall(isControlEnabled, control)
        if ok then return enabled == true end
    end
    return true
end

local function setControlEnabledSafe(control, enabled)
    pcall(toggleControl, control, enabled == true)
end

local function applyHardFreezeControls(enabled)
    enabled = enabled == true
    if enabled then
        if not P.localHardFreeze then
            P.freezeControlStates = {}
            for _, control in ipairs(HARD_FREEZE_CONTROLS) do
                local wasEnabled = getControlEnabledSafe(control)
                P.freezeControlStates[control] = wasEnabled
            end
        end

        P.localHardFreeze = true

        -- Stop any custom dashboard movement mode immediately. Native GTA
        -- controls alone are not enough because Flight moves the player with
        -- setElementPosition and could otherwise bypass setElementFrozen.
        if SC_ADMIN_DASHBOARD then
            SC_ADMIN_DASHBOARD.flightActive = false
            SC_ADMIN_DASHBOARD.lastSpaceTick = 0
        end

        for _, control in ipairs(HARD_FREEZE_CONTROLS) do
            setControlEnabledSafe(control, false)
            if type(setControlState) == "function" then
                pcall(setControlState, control, false)
            end
        end
        setElementVelocity(localPlayer, 0, 0, 0)
        return
    end

    if P.localHardFreeze then
        P.localHardFreeze = false
        for _, control in ipairs(HARD_FREEZE_CONTROLS) do
            if P.freezeControlStates[control] == true then
                setControlEnabledSafe(control, true)
            end
        end
    else
        P.localHardFreeze = false
    end
    P.freezeControlStates = {}
end

-- Keep the hard freeze authoritative every frame. This prevents another part
-- of this resource (or a dashboard state change) from re-enabling Jump, Fire,
-- movement, vehicle controls, etc. while the admin freeze is active.
addEventHandler("onClientPreRender", root, function()
    if not P.localHardFreeze then return end

    for _, control in ipairs(HARD_FREEZE_CONTROLS) do
        if getControlEnabledSafe(control) then
            setControlEnabledSafe(control, false)
        end
        if type(setControlState) == "function" then
            pcall(setControlState, control, false)
        end
    end

    if SC_ADMIN_DASHBOARD and SC_ADMIN_DASHBOARD.flightActive then
        SC_ADMIN_DASHBOARD.flightActive = false
        SC_ADMIN_DASHBOARD.lastSpaceTick = 0
    end
    setElementVelocity(localPlayer, 0, 0, 0)
end)

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

local SORTS = {
    { id = "name_asc", label = "Name (A-Z)" },
    { id = "name_desc", label = "Name (Z-A)" },
    { id = "id_asc", label = "ID (Low-High)" },
    { id = "id_desc", label = "ID (High-Low)" }
}

local BUTTON_ROWS = {
    { { label = "GoTo Player", standard = "player.goto" }, { label = "Get Here", standard = "player.gethere" } },
    { { label = "Spectate / Stop Spectate", special = "spectate" }, { label = "Freeze / Unfreeze", standard = "player.freeze" } },
    { { label = "Respawn", advanced = "player.respawn" }, { label = "Full Heal / Armor", advanced = "player.full_heal_armor" } },
    { { label = "Kill", standard = "player.kill", danger = true }, { label = "Revive", standard = "player.revive" } },
    { { label = "Give Weapon / Take Weapon", mode = "weapons", permission = "player.weapon_toggle" }, { label = "Give Cartridge / Take Cartridge", mode = "cartridge", permission = "player.give_cartridge" } },
    { { label = "Set Skin", mode = "skins", permission = "player.set_skin" }, { label = "Give Vehicle", mode = "vehicles", permission = "player.give_vehicle" } },
    { { label = "Give Money / Take Money", mode = "money", permission = "player.give_money" }, { label = "Give Gold / Take Gold", mode = "gold", permission = "player.give_gold" } },
    { { label = "Give Respect / Take Respect", mode = "respect", permission = "player.give_respect" }, { label = "Set Level", mode = "level", permission = "player.set_level" } },
    { { label = "Set Heal", mode = "health", permission = "player.set_health" }, { label = "Set Armor", mode = "armor", permission = "player.set_armor" } },
    { { label = "Set Skills / License", mode = "skills", permission = "player.skill_set" }, { label = "GM / Normal", advanced = "player.godmode" } },
    { { label = "Fix Damage", standard = "vehicle.fix" }, { label = "Eject From Vehicle", standard = "player.remove_vehicle" } }
}

local function px(value, l) return value * l.scale end
local function trim(value) local result = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""); return result end
local function pointInRect(x, y, rect) return rect and x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h end

local function drawText(text, x, y, w, h, color, size, font, ax, ay, clip)
    dxDrawText(tostring(text or ""), x, y, x + w, y + h, color or COLORS.text, size or 1, font or "default", ax or "left", ay or "center", clip == true, false, false, false)
end

local function selectedPlayer()
    if not A or not A.snapshot or type(A.snapshot.players) ~= "table" then return nil end
    for _, row in ipairs(A.snapshot.players) do
        if tonumber(row.id) == tonumber(A.selectedID) then return row end
    end
    return nil
end

local function hasPermission(permission)
    return permission and A.permissions and A.permissions[permission] == true
end

function P.createUI()
    local e = P.elements
    if isElement(e.search) then return end

    e.search = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.search, 40)

    e.sort = guiCreateComboBox(0, 0, 1, 1, "Name (A-Z)", false)
    for _, option in ipairs(SORTS) do guiComboBoxAddItem(e.sort, option.label) end
    guiComboBoxSetSelected(e.sort, 0)

    e.value1 = guiCreateEdit(0, 0, 1, 1, "", false)
    e.value2 = guiCreateEdit(0, 0, 1, 1, "", false)
    guiEditSetMaxLength(e.value1, 12)
    guiEditSetMaxLength(e.value2, 12)

    for index = 1, #(SC_STAFF.ADMIN_SHOOTING_SKILLS or {}) do
        local edit = guiCreateEdit(0, 0, 1, 1, "", false)
        guiEditSetMaxLength(edit, 6)
        guiSetVisible(edit, false)
        e.skillEdits[index] = edit
    end

    P.hideUI()
end

function P.hideUI()
    local e = P.elements
    for _, key in ipairs({ "search", "sort", "value1", "value2" }) do
        if isElement(e[key]) then guiSetVisible(e[key], false) end
    end
    for _, edit in ipairs(e.skillEdits or {}) do
        if isElement(edit) then guiSetVisible(edit, false) end
    end
end

function P.closeUI()
    P.hideUI()
    if P.spectatingID then
        triggerServerEvent("scAdminExecuteAction", resourceRoot, "player.spectate_stop", nil, {})
        P.spectatingID = nil
    end
end

function P.reset()
    P.createUI()
    P.mode = "home"
    P.section = nil
    P.animStart = 0
    P.scroll = 0
    P.actionRects = {}
    P.rowRects = {}
    P.tableRect = nil
    P.pendingStandardAction = nil
    guiSetText(P.elements.search, "")
    guiSetText(P.elements.value1, "")
    guiSetText(P.elements.value2, "")
    guiComboBoxSetSelected(P.elements.sort, 0)
    P.hideUI()
end

function P.isContextMode()
    return P.mode ~= "home"
end

function P.back()
    P.mode = "home"
    P.section = nil
    P.scroll = 0
    P.rowRects = {}
    P.tableRect = nil
    P.hideUI()
end

local function buildSkinCatalog()
    local rows, models = {}, {}
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
        if id then rows[#rows + 1] = { id = id, name = "Skin " .. id, preview = "None" } end
    end
    return rows
end

local function buildVehicleCatalog()
    local rows = {}
    for id = 400, 611 do
        local valid = type(isValidVehicleModel) ~= "function" or isValidVehicleModel(id)
        if valid then
            local name = getVehicleNameFromModel(id)
            if name and tostring(name) ~= "" then rows[#rows + 1] = { id = id, name = tostring(name), preview = "None" } end
        end
    end
    return rows
end

local function buildWeaponCatalog()
    local rows = {}
    for _, rawID in ipairs(SC_STAFF.ADMIN_WEAPON_IDS or {}) do
        local id = tonumber(rawID)
        if id then
            local name = type(getWeaponNameFromID) == "function" and getWeaponNameFromID(id) or nil
            rows[#rows + 1] = { id = id, name = name and tostring(name) or ("Weapon " .. id), preview = "None" }
        end
    end
    return rows
end

local CATALOG_CACHE = {}
local function sourceRows(mode)
    if mode == "skins" then CATALOG_CACHE.skins = CATALOG_CACHE.skins or buildSkinCatalog(); return CATALOG_CACHE.skins end
    if mode == "vehicles" then CATALOG_CACHE.vehicles = CATALOG_CACHE.vehicles or buildVehicleCatalog(); return CATALOG_CACHE.vehicles end
    if mode == "weapons" then CATALOG_CACHE.weapons = CATALOG_CACHE.weapons or buildWeaponCatalog(); return CATALOG_CACHE.weapons end
    if mode == "locations" then
        local rows = {}
        for _, loc in ipairs(SC_STAFF.ADMIN_TELEPORT_LOCATIONS or {}) do rows[#rows + 1] = { id = tonumber(loc.id) or 0, name = tostring(loc.name or "Location"), raw = loc } end
        return rows
    end
    if mode == "inventory" then
        local rows = {}
        for _, item in ipairs((P.data.inventory and P.data.inventory.items) or {}) do rows[#rows + 1] = { id = item.key, name = item.name, amount = item.amount, demo = item.demo } end
        return rows
    end
    return {}
end

local function currentSort()
    local selected = guiComboBoxGetSelected(P.elements.sort)
    local option = SORTS[(selected or -1) + 1]
    return option and option.id or "name_asc"
end

function P.filterRows()
    local needle = string.lower(trim(isElement(P.elements.search) and guiGetText(P.elements.search) or ""))
    local rows = {}
    for _, row in ipairs(sourceRows(P.mode)) do
        local hay = string.lower(tostring(row.name or "") .. " " .. tostring(row.id or ""))
        if needle == "" or string.find(hay, needle, 1, true) then rows[#rows + 1] = row end
    end

    local sort = currentSort()
    table.sort(rows, function(a, b)
        local an, bn = string.lower(tostring(a.name or "")), string.lower(tostring(b.name or ""))
        local ai, bi = tonumber(a.id), tonumber(b.id)
        if sort == "name_desc" and an ~= bn then return an > bn end
        if sort == "id_asc" and ai and bi and ai ~= bi then return ai < bi end
        if sort == "id_desc" and ai and bi and ai ~= bi then return ai > bi end
        if an ~= bn then return an < bn end
        return tostring(a.id or "") < tostring(b.id or "")
    end)
    P.filtered = rows
    P.scroll = math.max(0, math.min(P.scroll or 0, math.max(0, #rows - math.max(P.visibleRows, 1))))
end

local function requestData(mode)
    if not A.selectedID then return end
    triggerServerEvent("scAdminRequestPlayerToolData", resourceRoot, A.selectedID, mode)
end

local function setMode(mode)
    P.createUI()
    if not A.selectedID then
        outputChatBox("[StarsCity] Aval Yek Player Entekhab Konid.", 255, 90, 90)
        return
    end
    P.mode = mode
    P.section = nil
    P.animStart = 0
    P.scroll = 0
    P.rowRects = {}
    guiSetText(P.elements.search, "")
    guiSetText(P.elements.value1, "")
    guiSetText(P.elements.value2, "")
    guiComboBoxSetSelected(P.elements.sort, 0)

    if mode == "weapons" then requestData("weapons")
    elseif mode == "vehicles" then P.data.vehicles = {}; requestData("vehicles")
    elseif mode == "skills" then requestData("skills"); requestData("licenses")
    elseif mode == "inventory" then requestData("inventory")
    elseif mode == "cartridge" or mode == "money" or mode == "gold" or mode == "respect" or mode == "level" then requestData("stats") end
    P.filterRows()
end

local function sendStandard(actionName)
    if A.pending or not hasPermission(actionName) then return end
    if not A.selectedID and actionName ~= "player.spectate_stop" then return end
    P.pendingStandardAction = actionName
    A.lastSubmittedAction = actionName
    A.setPending(true)
    triggerServerEvent("scAdminExecuteAction", resourceRoot, actionName, A.selectedID, {})
end

local function sendStandardValue(actionName, value)
    if A.pending or not hasPermission(actionName) then return end
    if not A.selectedID then return end
    if trim(value) == "" then outputChatBox("[StarsCity] Meghdar Ra Vared Konid.", 255, 90, 90); return end
    P.pendingStandardAction = actionName
    A.lastSubmittedAction = actionName
    A.setPending(true)
    triggerServerEvent("scAdminExecuteAction", resourceRoot, actionName, A.selectedID, { value = trim(value) })
end

local function sendAdvanced(actionName, data)
    if A.pending or not hasPermission(actionName) or not A.selectedID then return end
    A.setPending(true)
    triggerServerEvent("scAdminExecutePlayerTool", resourceRoot, actionName, A.selectedID, data or {})
end

function P.onStandardActionResult(success, message)
    local action = P.pendingStandardAction
    if success and action == "player.spectate" then
        P.spectatingID = tonumber(A.selectedID)
    elseif success and action == "player.spectate_stop" then
        P.spectatingID = nil
    elseif success and P.spectatingID and string.find(string.lower(tostring(message or "")), "spectate stop", 1, true) then
        P.spectatingID = nil
    end
    P.pendingStandardAction = nil
end

local function drawBackHeader(x, y, w, l, mx, my, title)
    P.backRect = { x = x, y = y, w = px(38,l), h = px(34,l) }
    dxDrawRectangle(P.backRect.x, P.backRect.y, P.backRect.w, P.backRect.h, mx and pointInRect(mx,my,P.backRect) and COLORS.cardHover or COLORS.header)
    drawText("<", P.backRect.x, P.backRect.y, P.backRect.w, P.backRect.h, COLORS.text, 1.0*l.scale, "default-bold", "center")
    drawText(title, x + px(48,l), y, w - px(48,l), px(34,l), COLORS.text, 0.96*l.scale, "default-bold", "left", "center", true)
    local target = selectedPlayer()
    drawText(target and ("Target: " .. tostring(target.username) .. " [" .. tostring(target.id) .. "]") or "Target unavailable", x + px(48,l), y + px(28,l), w-px(48,l), px(22,l), target and COLORS.good or COLORS.warning, 0.72*l.scale, "default-bold", "left", "center", true)
end

local function setSearchSortVisible(search, sort)
    P.createUI()
    guiSetVisible(P.elements.search, search == true)
    guiSetVisible(P.elements.sort, sort == true)
end

local function drawCatalog(x,y,w,h,l,mx,my)
    local titles = { skins="Skin List", vehicles="Vehicle List", weapons="Weapon List" }
    local actions = { skins="Set", vehicles="Give / Destroy", weapons="Give" }
    drawBackHeader(x,y,w,l,mx,my,titles[P.mode] or "List")
    setSearchSortVisible(true,true)
    guiSetVisible(P.elements.value1,false); guiSetVisible(P.elements.value2,false)

    local sy = y + px(58,l)
    local sortW, gap = px(160,l), px(8,l)
    local searchW = w - sortW - gap
    guiSetPosition(P.elements.search,x,sy,false); guiSetSize(P.elements.search,searchW,px(34,l),false)
    guiSetPosition(P.elements.sort,x+searchW+gap,sy,false); guiSetSize(P.elements.sort,sortW,px(110,l),false)

    local tableY = sy + px(46,l)
    local tableH = h - (tableY-y)
    local headerH, rowH = px(34,l), px(42,l)
    P.tableRect={x=x,y=tableY,w=w,h=tableH}; P.rowRects={}
    dxDrawRectangle(x,tableY,w,tableH,tocolor(10,12,17,245)); dxDrawRectangle(x,tableY,w,headerH,COLORS.header)

    -- Keep this layout identical to the Dashboard catalogs so preview images can
    -- be dropped into the same column later without another UI redesign.
    local columns = {
        { label="Preview", ratio=0.21, align="center" },
        { label="Name", ratio=0.39, align="left" },
        { label="ID", ratio=0.14, align="center" },
        { label=actions[P.mode] or "Action", ratio=0.26, align="center" }
    }
    local cx=x
    for i,col in ipairs(columns) do
        local cw=w*col.ratio
        drawText(col.label,cx+(col.align=="left" and px(8,l) or 0),tableY,cw-px(4,l),headerH,COLORS.text,0.72*l.scale,"default-bold",col.align,"center",true)
        if i<#columns then dxDrawRectangle(cx+cw-px(1,l),tableY,px(1,l),tableH,COLORS.line) end
        cx=cx+cw
    end

    P.filterRows()
    local rows=P.filtered or {}; local usable=tableH-headerH; P.visibleRows=math.max(1,math.floor(usable/rowH)); local maxOff=math.max(0,#rows-P.visibleRows); P.scroll=math.max(0,math.min(P.scroll,maxOff))
    if #rows==0 then drawText("No items found.",x,tableY+headerH,w,usable,COLORS.muted,0.82*l.scale,"default","center"); return end
    local first=P.scroll+1; local last=math.min(#rows,first+P.visibleRows-1); local ry=tableY+headerH

    for idx=first,last do
        local row=rows[idx]
        if (idx-first)%2==1 then dxDrawRectangle(x,ry,w,rowH,tocolor(255,255,255,7)) end

        local cellX=x
        local previewW=w*columns[1].ratio
        local square=math.min(px(30,l),rowH-px(8,l))
        local sx=cellX+(previewW-square)/2
        local spy=ry+(rowH-square)/2
        dxDrawRectangle(sx,spy,square,square,tocolor(255,255,255,9))
        local preview=tostring(row.preview or "None")
        if preview~="" and preview~="None" and type(fileExists)=="function" and fileExists(preview) then
            dxDrawImage(sx,spy,square,square,preview,0,0,0,tocolor(255,255,255,255))
        else
            drawText("None",sx,spy,square,square,COLORS.muted,0.60*l.scale,"default","center","center",true)
        end
        cellX=cellX+previewW

        local nameW=w*columns[2].ratio
        drawText(row.name,cellX+px(8,l),ry,nameW-px(12,l),rowH,COLORS.text,0.72*l.scale,"default","left","center",true)
        cellX=cellX+nameW

        local idW=w*columns[3].ratio
        drawText(row.id,cellX,ry,idW,rowH,COLORS.text,0.72*l.scale,"default","center")
        cellX=cellX+idW

        local actionW=w*columns[4].ratio
        local owned=P.mode=="weapons" and P.data.weapons and P.data.weapons.owned and P.data.weapons.owned[tonumber(row.id)]
        local vehicleState=P.data.vehicles or {}
        local activeVehicle=P.mode=="vehicles" and vehicleState.active==true
        local activeModel=tonumber(vehicleState.model)
        local isActiveVehicle=activeVehicle and activeModel==tonumber(row.id)
        local label=owned and "Take" or (actions[P.mode] or "Set")
        local enabled=true
        local danger=false
        if P.mode=="vehicles" then
            if isActiveVehicle then
                label="Destroy"
                enabled=hasPermission("player.destroy_vehicle")
                danger=true
            elseif activeVehicle then
                label="Active"
                enabled=false
            else
                label="Give"
                enabled=hasPermission("player.give_vehicle")
            end
        end

        local bx=cellX+px(7,l); local bw=actionW-px(14,l)
        local rect={x=bx,y=ry+px(5,l),w=bw,h=rowH-px(10,l),kind="catalog",item=row,enabled=enabled,destroyVehicle=isActiveVehicle}
        local buttonColor
        if not enabled then
            buttonColor=tocolor(24,28,36,190)
        elseif danger then
            buttonColor=mx and pointInRect(mx,my,rect) and tocolor(115,42,50,255) or tocolor(82,35,42,255)
        else
            buttonColor=mx and pointInRect(mx,my,rect) and COLORS.cardHover or COLORS.accentSoft
        end
        dxDrawRectangle(rect.x,rect.y,rect.w,rect.h,buttonColor)
        drawText(label,rect.x,rect.y,rect.w,rect.h,enabled and COLORS.text or COLORS.muted,0.70*l.scale,"default-bold","center")
        P.rowRects[#P.rowRects+1]=rect
        dxDrawRectangle(x,ry+rowH-px(1,l),w,px(1,l),COLORS.line)
        ry=ry+rowH
    end
end

local function positionValue(edit,x,y,w,l,maxLen)
    guiSetVisible(edit,true)
    guiSetEnabled(edit,true)
    guiSetPosition(edit,x,y,false)
    guiSetSize(edit,w,px(36,l),false)
    if maxLen then guiEditSetMaxLength(edit,maxLen) end
    P.inputRects[#P.inputRects+1] = { x=x, y=y, w=w, h=px(36,l), edit=edit }
end

local function drawFormButton(id,label,x,y,w,h,l,mx,my,danger)
    local rect={x=x,y=y,w=w,h=h,id=id}; dxDrawRectangle(x,y,w,h,mx and pointInRect(mx,my,rect) and COLORS.cardHover or (danger and tocolor(82,35,42,255) or COLORS.accentSoft)); drawText(label,x,y,w,h,COLORS.text,0.78*l.scale,"default-bold","center"); P.rowRects[#P.rowRects+1]=rect
end

local function drawNumericForm(x,y,w,h,l,mx,my)
    local cfg = {
        cartridge={title="Give Cartridge / Take Cartridge",hint="Give: 5,000 - 100,000 | Take: 1 - 100,000",two=true,one={label="Give",id="give_cartridge"},second={label="Take",id="take_cartridge"}},
        money={title="Give Money / Take Money",hint="Give: 10,000 - 500,000,000 | Take uses Pocket first, then Bank",two=true,one={label="Give",id="give_money"},second={label="Take",id="take_money"}},
        gold={title="Give Gold / Take Gold",hint="Give: 1,000 - 500,000 | Take: 1 - 500,000",two=true,one={label="Give",id="give_gold"},second={label="Take",id="take_gold"}},
        respect={title="Give Respect / Take Respect",hint="Give/Take: 1 - 1,000",two=true,one={label="Give",id="give_respect"},second={label="Take",id="take_respect"}},
        level={title="Set Level",hint="Numeric only: 1 - 100",one={label="Set",id="set_level"}},
        health={title="Set Heal",hint="Numeric only: 1 - 100",one={label="Set",id="set_health"}},
        armor={title="Set Armor",hint="Numeric only: 0 - 100",one={label="Set",id="set_armor"}}
    }
    local c=cfg[P.mode]; if not c then return end
    drawBackHeader(x,y,w,l,mx,my,c.title); setSearchSortVisible(false,false)
    drawText(c.hint,x,y+px(62,l),w,px(42,l),COLORS.muted,0.76*l.scale,"default","left","top",true)
    local inputY=y+px(116,l); local buttonW=px(112,l); positionValue(P.elements.value1,x,inputY,w-buttonW-px(8,l),l,12)
    drawFormButton(c.one.id,c.one.label,x+w-buttonW,inputY,buttonW,px(36,l),l,mx,my,false)
    if c.two then
        local y2=inputY+px(58,l); positionValue(P.elements.value2,x,y2,w-buttonW-px(8,l),l,12); drawFormButton(c.second.id,c.second.label,x+w-buttonW,y2,buttonW,px(36,l),l,mx,my,true)
    else
        guiSetVisible(P.elements.value2,false)
    end
    local stats=P.data.stats or {}; local infoY=inputY+(c.two and px(122,l) or px(64,l))
    if P.mode=="money" then drawText("Pocket: $"..tostring(stats.pocket or "-"),x,infoY,w,px(24,l),COLORS.muted,0.76*l.scale,"default-bold")
    elseif P.mode=="gold" then drawText("Current Gold: "..tostring(stats.gold or "-"),x,infoY,w,px(24,l),COLORS.muted,0.76*l.scale,"default-bold")
    elseif P.mode=="respect" then drawText("Current Respect: "..tostring(stats.respect or "-"),x,infoY,w,px(24,l),COLORS.muted,0.76*l.scale,"default-bold")
    elseif P.mode=="level" then drawText("Current Level: "..tostring(stats.level or selectedPlayer() and selectedPlayer().level or "-"),x,infoY,w,px(24,l),COLORS.muted,0.76*l.scale,"default-bold")
    elseif P.mode=="cartridge" then drawText("Current Cartridge: "..tostring(stats.cartridge or 0),x,infoY,w,px(24,l),COLORS.muted,0.76*l.scale,"default-bold") end
end

local function formatRemaining(expiry, now)
    local seconds=(tonumber(expiry) or 0)-(tonumber(now) or 0); if seconds<=0 then return "Expired" end
    local day=86400; local days=math.floor(seconds/day)
    if days>=60 then return ("%d mo %d d"):format(math.floor(days/30),days%30) end
    if days>=14 then return ("%d w %d d"):format(math.floor(days/7),days%7) end
    if days>=1 then return ("%d d %d h"):format(days,math.floor((seconds%day)/3600)) end
    return ("%d h"):format(math.max(1,math.floor(seconds/3600)))
end

local function drawSkills(x,y,w,h,l,mx,my)
    drawBackHeader(x,y,w,l,mx,my,"Set Skills / License")
    guiSetVisible(P.elements.value1,false); guiSetVisible(P.elements.value2,false); guiSetVisible(P.elements.sort,false)
    local secY=y+px(62,l); local secH=px(38,l); P.rowRects={}
    local shoot={x=x,y=secY,w=w,h=secH,id="section_shooting"}; local lic={x=x,y=secY+secH+px(6,l),w=w,h=secH,id="section_license"}
    for _,r in ipairs({shoot,lic}) do dxDrawRectangle(r.x,r.y,r.w,r.h,mx and pointInRect(mx,my,r) and COLORS.cardHover or COLORS.card); dxDrawRectangle(r.x,r.y,px(4,l),r.h,COLORS.accent); P.rowRects[#P.rowRects+1]=r end
    drawText("Shooting Skills "..(P.section=="shooting" and "▲" or "▼"),shoot.x+px(12,l),shoot.y,shoot.w-px(24,l),shoot.h,COLORS.text,0.78*l.scale,"default-bold")
    drawText("License "..(P.section=="license" and "▲" or "▼"),lic.x+px(12,l),lic.y,lic.w-px(24,l),lic.h,COLORS.text,0.78*l.scale,"default-bold")

    if not P.section then
        guiSetVisible(P.elements.search,false)
        P.tableRect=nil
        for _,edit in ipairs(P.elements.skillEdits) do if isElement(edit) then guiSetVisible(edit,false) end end
        return
    end

    local progress=math.min(1,math.max(0,(getTickCount()-(P.animStart or 0))/180)); local tableY=lic.y+lic.h+px(10,l)+(1-progress)*px(10,l)
    guiSetVisible(P.elements.search,true); guiSetPosition(P.elements.search,x,tableY,false); guiSetSize(P.elements.search,w,px(32,l),false)
    tableY=tableY+px(42,l); local tableH=y+h-tableY; local headerH=px(32,l); local rowH=px(36,l); P.tableRect={x=x,y=tableY,w=w,h=tableH}
    dxDrawRectangle(x,tableY,w,tableH,tocolor(10,12,17,245)); dxDrawRectangle(x,tableY,w,headerH,COLORS.header)

    if P.section=="license" then
        for _,edit in ipairs(P.elements.skillEdits) do if isElement(edit) then guiSetVisible(edit,false) end end
        local labels={"License","Time","Renewal"}; local ratios={0.30,0.38,0.32}; local cx=x
        for i,r in ipairs(ratios) do drawText(labels[i],cx,tableY,w*r,headerH,COLORS.text,0.70*l.scale,"default-bold","center"); cx=cx+w*r end
        local needle=string.lower(trim(guiGetText(P.elements.search))); local rows={}; for _,license in ipairs(SC_STAFF.ADMIN_LICENSES or {}) do if needle=="" or string.find(string.lower(license.name),needle,1,true) then rows[#rows+1]=license end end
        local ry=tableY+headerH; local now=(P.data.licenses and P.data.licenses.now) or 0; local expiry=(P.data.licenses and P.data.licenses.expiry) or {}
        for _,license in ipairs(rows) do
            drawText(license.name,x,ry,w*ratios[1],rowH,COLORS.text,0.72*l.scale,"default","center")
            local remaining=(P.data.licenses and P.data.licenses.remaining) or {}; drawText(tostring(remaining[license.key] or formatRemaining(expiry[license.key],now)),x+w*ratios[1],ry,w*ratios[2],rowH,COLORS.muted,0.70*l.scale,"default","center")
            local bx=x+w*(ratios[1]+ratios[2])+px(6,l); local bw=w*ratios[3]-px(12,l); local r={x=bx,y=ry+px(4,l),w=bw,h=rowH-px(8,l),id="renew_license",license=license}
            dxDrawRectangle(r.x,r.y,r.w,r.h,mx and pointInRect(mx,my,r) and COLORS.cardHover or COLORS.accentSoft); drawText("Set 6 Months",r.x,r.y,r.w,r.h,COLORS.text,0.66*l.scale,"default-bold","center"); P.rowRects[#P.rowRects+1]=r; ry=ry+rowH
        end
    else
        local labels={"ID","Name","Skill Level","Set Level"}; local ratios={0.09,0.27,0.24,0.40}; local cx=x
        for i,r in ipairs(ratios) do
            drawText(labels[i],cx,tableY,w*r,headerH,COLORS.text,0.66*l.scale,"default-bold",i==2 and "left" or "center")
            if i<#ratios then dxDrawRectangle(cx+w*r-px(1,l),tableY,px(1,l),tableH,COLORS.line) end
            cx=cx+w*r
        end

        -- Prefer authoritative metadata returned by the server. This keeps names and
        -- max values visible even if the client config/cache is stale.
        local sourceSkills=(P.data.skills and P.data.skills.rows) or SC_STAFF.ADMIN_SHOOTING_SKILLS or {}
        local needle=string.lower(trim(guiGetText(P.elements.search)))
        local skills={}
        for idx,skill in ipairs(sourceSkills) do
            local name=tostring(skill.name or skill.key or ("Skill "..tostring(skill.id or idx)))
            local haystack=string.lower(name.." "..tostring(skill.id or "").." "..tostring(skill.key or ""))
            if needle=="" or string.find(haystack,needle,1,true) then
                skills[#skills+1]={skill=skill,sourceIndex=idx}
            end
        end

        P.visibleRows=math.max(1,math.floor((tableH-headerH)/rowH)); local maxOff=math.max(0,#skills-P.visibleRows); P.scroll=math.max(0,math.min(P.scroll,maxOff)); local first=P.scroll+1; local last=math.min(#skills,first+P.visibleRows-1); local ry=tableY+headerH
        local visibleSkillEdits={}
        for i=first,last do
            local entry=skills[i]; local skill=entry.skill; local values=(P.data.skills and P.data.skills.values) or {}
            local current=tonumber(skill.value) or tonumber(values[tostring(skill.key)]) or 0
            local maximum=math.max(1,tonumber(skill.max) or 1)
            local name=tostring(skill.name or skill.key or ("Skill "..tostring(skill.id or entry.sourceIndex)))
            drawText(skill.id or entry.sourceIndex,x,ry,w*ratios[1],rowH,COLORS.text,0.68*l.scale,"default","center")
            drawText(name,x+w*ratios[1]+px(7,l),ry,w*ratios[2]-px(12,l),rowH,COLORS.text,0.68*l.scale,"default-bold","left","center",true)
            drawText(("%d / %d"):format(current,maximum),x+w*(ratios[1]+ratios[2]),ry,w*ratios[3],rowH,COLORS.muted,0.66*l.scale,"default-bold","center")

            local lastX=x+w*(ratios[1]+ratios[2]+ratios[3]); local lastW=w*ratios[4]; local setW=px(58,l); local edit=P.elements.skillEdits[entry.sourceIndex]
            if progress>=0.7 and isElement(edit) then
                visibleSkillEdits[entry.sourceIndex]=true
                guiSetVisible(edit,true)
                guiSetEnabled(edit,true)
                guiSetPosition(edit,lastX+px(5,l),ry+px(4,l),false)
                guiSetSize(edit,lastW-setW-px(12,l),rowH-px(8,l),false)
                guiEditSetMaxLength(edit,6)
                P.inputRects[#P.inputRects+1]={x=lastX+px(5,l),y=ry+px(4,l),w=lastW-setW-px(12,l),h=rowH-px(8,l),edit=edit}
            end
            local r={x=lastX+lastW-setW-px(4,l),y=ry+px(4,l),w=setW,h=rowH-px(8,l),id="set_skill",skill=skill,edit=edit}
            dxDrawRectangle(r.x,r.y,r.w,r.h,mx and pointInRect(mx,my,r) and COLORS.cardHover or COLORS.accentSoft); drawText("Set",r.x,r.y,r.w,r.h,COLORS.text,0.66*l.scale,"default-bold","center"); P.rowRects[#P.rowRects+1]=r
            dxDrawRectangle(x,ry+rowH-px(1,l),w,px(1,l),COLORS.line)
            ry=ry+rowH
        end
        for index,edit in ipairs(P.elements.skillEdits) do
            if isElement(edit) and not visibleSkillEdits[index] then guiSetVisible(edit,false) end
        end
    end
end

local function drawLocations(x,y,w,h,l,mx,my)
    drawBackHeader(x,y,w,l,mx,my,"Teleport Player To Locations"); setSearchSortVisible(true,false); guiSetVisible(P.elements.value1,false); guiSetVisible(P.elements.value2,false)
    local sy=y+px(60,l); guiSetPosition(P.elements.search,x,sy,false); guiSetSize(P.elements.search,w,px(34,l),false); local tableY=sy+px(46,l); local tableH=h-(tableY-y); local headerH=px(34,l); local rowH=px(40,l); P.tableRect={x=x,y=tableY,w=w,h=tableH}; P.rowRects={}
    dxDrawRectangle(x,tableY,w,tableH,tocolor(10,12,17,245)); dxDrawRectangle(x,tableY,w,headerH,COLORS.header); drawText("ID",x,tableY,w*0.15,headerH,COLORS.text,0.72*l.scale,"default-bold","center"); drawText("Location",x+w*0.15,tableY,w*0.55,headerH,COLORS.text,0.72*l.scale,"default-bold","center"); drawText("Send",x+w*0.70,tableY,w*0.30,headerH,COLORS.text,0.72*l.scale,"default-bold","center")
    P.filterRows(); local rows=P.filtered; P.visibleRows=math.max(1,math.floor((tableH-headerH)/rowH)); local maxOff=math.max(0,#rows-P.visibleRows); P.scroll=math.max(0,math.min(P.scroll,maxOff)); local first=P.scroll+1; local last=math.min(#rows,first+P.visibleRows-1); local ry=tableY+headerH
    for i=first,last do local row=rows[i]; drawText(row.id,x,ry,w*0.15,rowH,COLORS.text,0.70*l.scale,"default","center"); drawText(row.name,x+w*0.15,ry,w*0.55,rowH,COLORS.text,0.70*l.scale,"default","center",true); local configured=tonumber(row.raw and row.raw.x) and tonumber(row.raw and row.raw.y) and tonumber(row.raw and row.raw.z); local r={x=x+w*0.72,y=ry+px(5,l),w=w*0.26,h=rowH-px(10,l),id="send_location",item=row,enabled=configured and true or false}; dxDrawRectangle(r.x,r.y,r.w,r.h,r.enabled and (mx and pointInRect(mx,my,r) and COLORS.cardHover or COLORS.accentSoft) or tocolor(24,28,36,190)); drawText(r.enabled and "Send" or "Not Set",r.x,r.y,r.w,r.h,r.enabled and COLORS.text or COLORS.muted,0.66*l.scale,"default-bold","center"); P.rowRects[#P.rowRects+1]=r; ry=ry+rowH end
end

local function drawInventory(x,y,w,h,l,mx,my)
    drawBackHeader(x,y,w,l,mx,my,"Player Inventory"); setSearchSortVisible(true,false); guiSetVisible(P.elements.value1,false); guiSetVisible(P.elements.value2,false)
    local sy=y+px(60,l); guiSetPosition(P.elements.search,x,sy,false); guiSetSize(P.elements.search,w,px(34,l),false); local tableY=sy+px(46,l); local tableH=h-(tableY-y)-px(28,l); local headerH=px(34,l); local rowH=px(40,l); P.tableRect={x=x,y=tableY,w=w,h=tableH}; P.rowRects={}
    dxDrawRectangle(x,tableY,w,tableH,tocolor(10,12,17,245)); dxDrawRectangle(x,tableY,w,headerH,COLORS.header); drawText("Item",x,tableY,w*0.48,headerH,COLORS.text,0.72*l.scale,"default-bold","center"); drawText("Amount",x+w*0.48,tableY,w*0.20,headerH,COLORS.text,0.72*l.scale,"default-bold","center"); drawText("Add or Del",x+w*0.68,tableY,w*0.32,headerH,COLORS.text,0.72*l.scale,"default-bold","center")
    P.filterRows(); local rows=P.filtered; P.visibleRows=math.max(1,math.floor((tableH-headerH)/rowH)); local maxOff=math.max(0,#rows-P.visibleRows); P.scroll=math.max(0,math.min(P.scroll,maxOff)); local first=P.scroll+1; local last=math.min(#rows,first+P.visibleRows-1); local ry=tableY+headerH
    for i=first,last do local row=rows[i]; drawText(row.name,x,ry,w*0.48,rowH,COLORS.text,0.70*l.scale,"default","center",true); drawText(row.amount,x+w*0.48,ry,w*0.20,rowH,COLORS.muted,0.72*l.scale,"default-bold","center"); local bx=x+w*0.70; local bw=w*0.12; local minus={x=bx,y=ry+px(5,l),w=bw,h=rowH-px(10,l),id="inventory_minus",item=row,enabled=not row.demo}; local plus={x=bx+bw+px(8,l),y=minus.y,w=bw,h=minus.h,id="inventory_plus",item=row,enabled=not row.demo}; for _,r in ipairs({minus,plus}) do dxDrawRectangle(r.x,r.y,r.w,r.h,r.enabled and (mx and pointInRect(mx,my,r) and COLORS.cardHover or COLORS.accentSoft) or tocolor(24,28,36,190)); drawText(r.id=="inventory_plus" and "+" or "-",r.x,r.y,r.w,r.h,r.enabled and COLORS.text or COLORS.muted,0.84*l.scale,"default-bold","center"); P.rowRects[#P.rowRects+1]=r end; ry=ry+rowH end
    if P.data.inventory and P.data.inventory.demo then drawText("Demo rows only - Inventory core items are not defined yet.",x,tableY+tableH+px(3,l),w,px(22,l),COLORS.warning,0.68*l.scale,"default-bold","center") end
end

function P.renderLeft(x,y,w,h,l,mx,my)
    P.createUI()
    P.inputRects = {}
    if not A.selectedID then P.back(); return end
    if P.mode=="skins" or P.mode=="vehicles" or P.mode=="weapons" then drawCatalog(x,y,w,h,l,mx,my)
    elseif P.mode=="cartridge" or P.mode=="money" or P.mode=="gold" or P.mode=="respect" or P.mode=="level" or P.mode=="health" or P.mode=="armor" then drawNumericForm(x,y,w,h,l,mx,my)
    elseif P.mode=="skills" then drawSkills(x,y,w,h,l,mx,my)
    elseif P.mode=="locations" then drawLocations(x,y,w,h,l,mx,my)
    elseif P.mode=="inventory" then drawInventory(x,y,w,h,l,mx,my)
    else P.back() end
end

local function buttonPermission(item)
    if item.permission then return item.permission end
    if item.standard then return item.standard end
    if item.advanced then return item.advanced end
    if item.special=="spectate" then return P.spectatingID and "player.spectate_stop" or "player.spectate" end
end

function P.renderActions(x,y,w,h,l,mx,my)
    P.actionRects={}
    local target=selectedPlayer(); drawText("Player Actions",x,y,w,px(30,l),COLORS.text,1.02*l.scale,"default-bold")
    drawText(target and ("Target: "..tostring(target.username).." ["..tostring(target.id).."]") or "Target: No player selected",x,y+px(29,l),w,px(24,l),target and COLORS.good or COLORS.warning,0.80*l.scale,"default-bold", "left","center",true)
    local startY=y+px(58,l); local gap=px(6,l); local bh=px(34,l); local bw=(w-gap)/2
    for ri,row in ipairs(BUTTON_ROWS) do
        for ci,item in ipairs(row) do
            local rect={x=x+(ci-1)*(bw+gap),y=startY+(ri-1)*(bh+gap),w=bw,h=bh,item=item}; local permission=buttonPermission(item); rect.enabled=(target~=nil or (item.special=="spectate" and P.spectatingID~=nil)) and not A.pending and hasPermission(permission)
            local label=item.label
            if item.special=="spectate" and P.spectatingID then label="Stop Spectate" end
            if item.standard=="player.freeze" and target then label=target.frozen and "Unfreeze" or "Freeze" end
            if item.advanced=="player.godmode" and target then label=target.adminGodMode and "GM / Normal [ON]" or "GM / Normal" end
            local hover=rect.enabled and mx and pointInRect(mx,my,rect); local color=rect.enabled and (hover and COLORS.cardHover or COLORS.card) or tocolor(24,28,36,185); if item.danger and rect.enabled then color=hover and tocolor(115,42,50,255) or tocolor(82,35,42,255) end
            dxDrawRectangle(rect.x,rect.y,rect.w,rect.h,color); dxDrawRectangle(rect.x,rect.y,px(4,l),rect.h,rect.enabled and COLORS.accent or COLORS.muted); drawText(label,rect.x+px(10,l),rect.y,rect.w-px(16,l),rect.h,rect.enabled and COLORS.text or COLORS.muted,0.69*l.scale,"default-bold","left","center",true); P.actionRects[#P.actionRects+1]=rect
        end
    end
    local fy=startY+#BUTTON_ROWS*(bh+gap); local fullH=px(36,l)
    for _,item in ipairs({ {label="Teleport Player To Locations",mode="locations",permission="player.teleport_location"}, {label="Player Inventory",mode="inventory",permission="player.inventory_add"} }) do
        local rect={x=x,y=fy,w=w,h=fullH,item=item,enabled=target~=nil and not A.pending and hasPermission(item.permission)}; local hover=rect.enabled and mx and pointInRect(mx,my,rect); dxDrawRectangle(rect.x,rect.y,rect.w,rect.h,rect.enabled and (hover and COLORS.cardHover or COLORS.card) or tocolor(24,28,36,185)); dxDrawRectangle(rect.x,rect.y,px(4,l),rect.h,rect.enabled and COLORS.accent or COLORS.muted); drawText(item.label,rect.x+px(10,l),rect.y,rect.w-px(20,l),rect.h,rect.enabled and COLORS.text or COLORS.muted,0.72*l.scale,"default-bold","left"); P.actionRects[#P.actionRects+1]=rect; fy=fy+fullH+gap
    end
end

local function numericText(edit)
    return trim(isElement(edit) and guiGetText(edit) or "")
end

function P.handleClick(x,y)
    if not A.visible or A.category~="player" then return false end
    if P.isContextMode() and pointInRect(x,y,P.backRect) then P.back(); return true end

    for _,input in ipairs(P.inputRects or {}) do
        if pointInRect(x,y,input) and isElement(input.edit) then
            guiSetEnabled(input.edit,true)
            guiBringToFront(input.edit)
            if type(guiSetInputMode) == "function" then guiSetInputMode("no_binds_when_editing") end
            if type(guiEditSetCaretIndex) == "function" then guiEditSetCaretIndex(input.edit,#(guiGetText(input.edit) or "")) end
            return true
        end
    end

    for _,rect in ipairs(P.actionRects or {}) do
        if pointInRect(x,y,rect) then
            if not rect.enabled then return true end
            local item=rect.item
            if item.mode then setMode(item.mode)
            elseif item.special=="spectate" then sendStandard(P.spectatingID and "player.spectate_stop" or "player.spectate")
            elseif item.standard then sendStandard(item.standard)
            elseif item.advanced then sendAdvanced(item.advanced,{}) end
            return true
        end
    end

    if not P.isContextMode() then return false end
    for _,rect in ipairs(P.rowRects or {}) do
        if pointInRect(x,y,rect) then
            if rect.kind=="catalog" then
                if rect.enabled==false then return true end
                if P.mode=="skins" then sendStandardValue("player.set_skin",tostring(rect.item.id))
                elseif P.mode=="vehicles" then
                    if rect.destroyVehicle then sendAdvanced("player.destroy_vehicle",{})
                    else sendAdvanced("player.give_vehicle",{model=rect.item.id}) end
                elseif P.mode=="weapons" then sendAdvanced("player.weapon_toggle",{weaponID=rect.item.id}) end
            elseif rect.id=="give_cartridge" then sendAdvanced("player.give_cartridge",{value=numericText(P.elements.value1)})
            elseif rect.id=="take_cartridge" then sendAdvanced("player.take_cartridge",{value=numericText(P.elements.value2)})
            elseif rect.id=="give_money" then sendAdvanced("player.give_money",{value=numericText(P.elements.value1)})
            elseif rect.id=="take_money" then sendAdvanced("player.take_money",{value=numericText(P.elements.value2)})
            elseif rect.id=="give_gold" then sendAdvanced("player.give_gold",{value=numericText(P.elements.value1)})
            elseif rect.id=="take_gold" then sendAdvanced("player.take_gold",{value=numericText(P.elements.value2)})
            elseif rect.id=="give_respect" then sendAdvanced("player.give_respect",{value=numericText(P.elements.value1)})
            elseif rect.id=="take_respect" then sendAdvanced("player.take_respect",{value=numericText(P.elements.value2)})
            elseif rect.id=="set_level" then sendAdvanced("player.set_level",{value=numericText(P.elements.value1)})
            elseif rect.id=="set_health" then sendStandardValue("player.set_health",numericText(P.elements.value1))
            elseif rect.id=="set_armor" then sendStandardValue("player.set_armor",numericText(P.elements.value1))
            elseif rect.id=="section_shooting" then P.section=P.section=="shooting" and nil or "shooting"; P.scroll=0; P.animStart=getTickCount(); if P.section then requestData("skills") end
            elseif rect.id=="section_license" then P.section=P.section=="license" and nil or "license"; P.scroll=0; P.animStart=getTickCount(); if P.section then requestData("licenses") end
            elseif rect.id=="set_skill" then sendAdvanced("player.skill_set",{skillKey=rect.skill.key,value=numericText(rect.edit)})
            elseif rect.id=="renew_license" then sendAdvanced("player.license_renew",{licenseKey=rect.license.key})
            elseif rect.id=="send_location" and rect.enabled then sendAdvanced("player.teleport_location",{locationID=rect.item.id})
            elseif rect.id=="inventory_plus" and rect.enabled then sendAdvanced("player.inventory_add",{itemKey=rect.item.id})
            elseif rect.id=="inventory_minus" and rect.enabled then sendAdvanced("player.inventory_remove",{itemKey=rect.item.id}) end
            return true
        end
    end
    return false
end

function P.handleWheel(button,mx,my)
    if not P.isContextMode() or not pointInRect(mx,my,P.tableRect) then return false end
    local maxOffset=math.max(0,#(P.filtered or {})-math.max(P.visibleRows,1))
    if P.mode=="skills" and P.section=="shooting" then
        local needle=string.lower(trim(guiGetText(P.elements.search))); local count=0; local sourceSkills=(P.data.skills and P.data.skills.rows) or SC_STAFF.ADMIN_SHOOTING_SKILLS or {}
        for _,skill in ipairs(sourceSkills) do local haystack=string.lower(tostring(skill.name or skill.key or "").." "..tostring(skill.id or "")); if needle=="" or string.find(haystack,needle,1,true) then count=count+1 end end; maxOffset=math.max(0,count-math.max(P.visibleRows,1))
    end
    if button=="mouse_wheel_up" then P.scroll=math.max(0,P.scroll-1) else P.scroll=math.min(maxOffset,P.scroll+1) end
    return true
end

addEvent("scAdminPlayerToolData",true)
addEventHandler("scAdminPlayerToolData",resourceRoot,function(mode,success,message,data)
    if not success then if message and message~="" then outputChatBox("[StarsCity] Khata: "..tostring(message),255,80,80) end return end
    if mode=="weapons" then P.data.weapons=data or {}
    elseif mode=="vehicles" then P.data.vehicles=data or {}
    elseif mode=="skills" then
        P.data.skills=data or {}
        local values=P.data.skills.values or {}
        local rows=P.data.skills.rows or SC_STAFF.ADMIN_SHOOTING_SKILLS or {}
        for index,skill in ipairs(rows) do
            local edit=P.elements.skillEdits[index]
            if isElement(edit) then guiSetText(edit,tostring(tonumber(skill.value) or tonumber(values[tostring(skill.key)]) or 0)) end
        end
    elseif mode=="licenses" then P.data.licenses=data or {}
    elseif mode=="inventory" then P.data.inventory=data or {}; P.filterRows()
    elseif mode=="stats" or mode=="cartridge" then P.data.stats=data or {} end
end)

addEvent("scAdminPlayerToolResult",true)
addEventHandler("scAdminPlayerToolResult",resourceRoot,function(success,message,refreshMode)
    A.setPending(false)
    if success then outputChatBox("[StarsCity] "..tostring(message),80,220,120) else outputChatBox("[StarsCity] Khata: "..tostring(message),255,80,80) end
    if success and A.visible then triggerServerEvent("scAdminRequestSnapshot",resourceRoot) end
    if success and refreshMode and refreshMode~="" and A.selectedID then requestData(refreshMode) end
    if success and (P.mode=="money" or P.mode=="gold" or P.mode=="respect" or P.mode=="level" or P.mode=="cartridge") then requestData("stats") end
end)

addEvent("scAdminSetHardFreeze",true)
addEventHandler("scAdminSetHardFreeze",resourceRoot,function(enabled)
    applyHardFreezeControls(enabled==true)
    if A and A.snapshot and type(A.snapshot.adminState)=="table" then
        A.snapshot.adminState.frozen=P.localHardFreeze
    end
end)

addEvent("scAdminSetTargetGodMode",true)
addEventHandler("scAdminSetTargetGodMode",resourceRoot,function(enabled)
    P.localGodMode=enabled==true
    if A and A.snapshot and type(A.snapshot.adminState)=="table" then
        A.snapshot.adminState.godMode=P.localGodMode
    end
end)

addEventHandler("onClientPlayerDamage",root,function()
    if source==localPlayer and P.localGodMode then cancelEvent() end
end)

addEventHandler("onClientVehicleDamage",root,function()
    if P.localGodMode and getPedOccupiedVehicle(localPlayer)==source then cancelEvent() end
end)

addEventHandler("onClientGUIChanged",root,function()
    if not A or not A.visible or A.category~="player" or P.sanitizeGuard then return end
    if source==P.elements.search then P.filterRows(); P.scroll=0; return end
    local numeric=false
    if source==P.elements.value1 or source==P.elements.value2 then numeric=true end
    for _,edit in ipairs(P.elements.skillEdits or {}) do if source==edit then numeric=true break end end
    if numeric then
        local current=guiGetText(source) or ""; local digits=current:gsub("%D","")
        if current~=digits then P.sanitizeGuard=true; guiSetText(source,digits); guiEditSetCaretIndex(source,#digits); P.sanitizeGuard=false end
    end
end)

addEventHandler("onClientGUIComboBoxAccepted",root,function()
    if source==P.elements.sort then P.filterRows(); P.scroll=0 end
end)

addEventHandler("onClientResourceStop",resourceRoot,function()
    if P.localHardFreeze then applyHardFreezeControls(false) end
end)
