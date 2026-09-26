-- =========================================================
-- STARS CITY - PUNISHMENTS UI
-- Context panels for Warn / Kick / Mute / Admin Jail / Ban.
-- =========================================================

SC_ADMIN_PUNISHMENTS = SC_ADMIN_PUNISHMENTS or {}
local P = SC_ADMIN_PUNISHMENTS
local A = SC_ADMIN_CLIENT

P.mode = "home"
P.target = nil
P.data = {}
P.actionRects = {}
P.backRect = nil
P.tableRects = {}
P.historyScroll = 0
P.stateScroll = 0
P.historyPage = 1
P.tempHistoryPage = 1
P.permHistoryPage = 1
P.hoverReason = nil
P.banSection = "temporary"
P.banAnimStart = 0
P.timeOptions = {}
P.warnAmount = 1
P.elements = { reason = nil, warnAmount = nil, timeCombo = nil }
P.lastTargetsRequest = 0

local function px(v, l) return v * l.scale end
local function pointInRect(x, y, r) return r and x >= r.x and x <= r.x+r.w and y >= r.y and y <= r.y+r.h end
local function C(name) return A.COLORS[name] end
local function drawText(...) return A.drawText(...) end

local function selectedPlayer()
    if not A then return nil end
    if A.findPlayerData then
        return A.findPlayerData(A.selectedID)
    end
    local rows = type(A.punishmentPlayers) == "table" and A.punishmentPlayers or {}
    for _, row in ipairs(rows) do
        if tonumber(row.id) == tonumber(A.selectedID) then return row end
    end
    return nil
end

local function hasPermission(permission)
    return A.permissions and A.permissions[permission] == true
end

local function setVisible(element, visible)
    if isElement(element) then guiSetVisible(element, visible == true) end
end

function P.createUI()
    if isElement(P.elements.reason) then return end
    P.elements.reason = guiCreateEdit(0,0,1,1,"",false)
    guiEditSetMaxLength(P.elements.reason, math.max(120, tonumber(SC_STAFF.PUNISHMENT_REASON_MAX_LENGTH) or 1024))
    P.elements.warnAmount = guiCreateEdit(0,0,1,1,"1",false)
    guiEditSetMaxLength(P.elements.warnAmount, 2)
    P.elements.timeCombo = guiCreateComboBox(0,0,1,1,"Select Time",false)
    P.hideUI()
end

function P.hideUI()
    setVisible(P.elements.reason, false)
    setVisible(P.elements.warnAmount, false)
    setVisible(P.elements.timeCombo, false)
end

function P.reset()
    P.createUI()
    P.mode = "home"
    P.target = nil
    P.data = {}
    P.actionRects = {}
    P.backRect = nil
    P.tableRects = {}
    P.historyScroll = 0
    P.stateScroll = 0
    P.historyPage = 1
    P.tempHistoryPage = 1
    P.permHistoryPage = 1
    P.hoverReason = nil
    P.banSection = "temporary"
    P.banAnimStart = 0
    P.timeOptions = {}
    P.warnAmount = 1
    guiSetText(P.elements.reason, "")
    guiSetText(P.elements.warnAmount, "1")
    P.hideUI()
end

function P.closeUI()
    P.hideUI()
end

function P.refreshTargets(force)
    local now = getTickCount()
    local interval = math.max(1500, tonumber(SC_STAFF.PUNISHMENT_TARGET_REFRESH_MS) or 15000)
    if not force and now - (P.lastTargetsRequest or 0) < interval then return end
    P.lastTargetsRequest = now
    triggerServerEvent("scPunishmentRequestTargets", resourceRoot, force == true)
end

function P.enter()
    P.refreshTargets(true)
end

function P.isContextMode()
    return P.mode ~= "home"
end

function P.back()
    P.mode = "home"
    P.target = nil
    P.data = {}
    P.historyScroll = 0
    P.stateScroll = 0
    P.historyPage = 1
    P.tempHistoryPage = 1
    P.permHistoryPage = 1
    P.hoverReason = nil
    P.actionRects = {}
    P.tableRects = {}
    P.hideUI()
    P.refreshTargets(true)
end

local function setComboItems(options)
    options = options or {}
    P.timeOptions = options
    if type(guiComboBoxClear) == "function" then guiComboBoxClear(P.elements.timeCombo) end
    for _, option in ipairs(options) do guiComboBoxAddItem(P.elements.timeCombo, tostring(option.label)) end
    if #options > 0 then guiComboBoxSetSelected(P.elements.timeCombo, 0) end
end

local function requestData()
    if P.mode == "home" or not P.target then return end
    triggerServerEvent("scPunishmentRequestData", resourceRoot, P.mode, P.target.id, {
        page = P.historyPage or 1,
        tempPage = P.tempHistoryPage or 1,
        permPage = P.permHistoryPage or 1
    })
end

local function openMode(mode)
    local target = selectedPlayer()
    if not target then
        outputChatBox("[StarsCity] Aval Yek Player Entekhab Konid.",255,90,90)
        return
    end
    P.createUI()
    P.mode = mode
    P.target = { id = tonumber(target.id), username = tostring(target.username or "Unknown"), staffRank = tonumber(target.staffRank) or 0 }
    P.data = {}
    P.historyScroll = 0
    P.stateScroll = 0
    P.historyPage = 1
    P.tempHistoryPage = 1
    P.permHistoryPage = 1
    P.hoverReason = nil
    P.banSection = "temporary"
    P.banAnimStart = getTickCount()
    P.warnAmount = 1
    guiSetText(P.elements.warnAmount, "1")
    guiSetText(P.elements.reason, "")
    if mode == "mute" then setComboItems(SC_STAFF.PUNISHMENT_MUTE_TIMES)
    elseif mode == "jail" then setComboItems(SC_STAFF.PUNISHMENT_JAIL_TIMES)
    elseif mode == "ban" then setComboItems(SC_STAFF.PUNISHMENT_BAN_TIMES)
    else setComboItems({}) end
    requestData()
end

local function currentTimeKey()
    local selected = guiComboBoxGetSelected(P.elements.timeCombo)
    local option = P.timeOptions[(selected or -1)+1]
    return option and option.key or nil
end

local function reasonText()
    local text = isElement(P.elements.reason) and guiGetText(P.elements.reason) or ""
    text = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function sendAction(action, payload)
    if A.pending or not P.target then return end
    payload = type(payload)=="table" and payload or {}
    A.setPending(true)
    triggerServerEvent("scPunishmentAction", resourceRoot, action, P.target.id, payload)
end

local ACTIONS = {
    { mode="warn", label="Warn", permission="punishment.warn" },
    { mode="kick", label="Kick", permission="punishment.kick", danger=true },
    { mode="mute", label="Mute / Unmute", permission="punishment.mute" },
    { mode="jail", label="Admin Jail / Unjail", permission="punishment.jail" },
    { mode="ban", label="Ban", permission="punishment.temp_ban", danger=true }
}

function P.renderActions(x,y,w,h,l,mx,my)
    P.hideUI()
    P.actionRects = {}
    drawText("Punishments",x,y,w,px(34,l),C("text"),1.05*l.scale,"default-bold")
    local target=selectedPlayer()
    drawText(target and ("Target: "..tostring(target.username).." ["..tostring(target.id).."] - "..tostring(target.accountStatus or (target.online and "Online" or "Offline"))) or "Target: No player selected",
        x,y+px(32,l),w,px(28,l),target and (target.online and C("good") or C("muted")) or C("warning"),0.86*l.scale,"default-bold")

    local by=y+px(78,l)
    local gap=px(10,l)
    local bh=px(50,l)
    for _,item in ipairs(ACTIONS) do
        local enabled=target~=nil and hasPermission(item.permission) and not A.pending
        if enabled and item.mode == "kick" and not target.online then
            enabled = false
        end
        local r={x=x,y=by,w=w,h=bh,item=item,enabled=enabled}
        local hover=enabled and mx and pointInRect(mx,my,r)
        local base=item.danger and tocolor(82,35,42,255) or C("card")
        local hoverColor=item.danger and tocolor(115,42,50,255) or C("cardHover")
        dxDrawRectangle(r.x,r.y,r.w,r.h,enabled and (hover and hoverColor or base) or tocolor(24,28,36,190))
        dxDrawRectangle(r.x,r.y,px(4,l),r.h,enabled and (item.danger and C("danger") or C("accent")) or C("muted"))
        drawText(item.label,r.x+px(14,l),r.y,r.w-px(24,l),r.h,enabled and C("text") or C("muted"),0.82*l.scale,"default-bold")
        P.actionRects[#P.actionRects+1]=r
        by=by+bh+gap
    end
end

local function renderContextHeader(x,y,w,l,mx,my,title)
    P.backRect={x=x,y=y,w=px(36,l),h=px(34,l)}
    local hover=mx and pointInRect(mx,my,P.backRect)
    dxDrawRectangle(P.backRect.x,P.backRect.y,P.backRect.w,P.backRect.h,hover and C("cardHover") or C("card"))
    drawText("<",P.backRect.x,P.backRect.y,P.backRect.w,P.backRect.h,C("text"),1.0*l.scale,"default-bold","center")
    drawText(title,x+px(48,l),y,w-px(48,l),px(26,l),C("text"),1.02*l.scale,"default-bold")
    drawText(P.target and ("Target: "..P.target.username.." ["..tostring(P.target.id).."]") or "Target unavailable",
        x+px(48,l),y+px(25,l),w-px(48,l),px(22,l),C("good"),0.72*l.scale,"default-bold")
end

local function setEditLayout(edit,x,y,w,h,visible)
    if not isElement(edit) then return end
    guiSetPosition(edit,x,y,false)
    guiSetSize(edit,w,h,false)
    guiSetVisible(edit,visible==true)
end

local function tableRows(title, columns, rows, x,y,w,h,l,mx,my,scrollKey, actionBuilder)
    rows=rows or {}
    local headerH=px(30,l); local rowH=px(34,l); local titleH=px(24,l)
    drawText(title,x,y,w,titleH,C("muted"),0.78*l.scale,"default-bold")
    local ty=y+titleH
    dxDrawRectangle(x,ty,w,h-titleH,tocolor(10,12,17,245))
    dxDrawRectangle(x,ty,w,headerH,C("header"))
    local cx=x
    for i,col in ipairs(columns) do
        local cw=w*col.ratio
        drawText(col.label,cx+px(5,l),ty,cw-px(10,l),headerH,C("text"),0.68*l.scale,"default-bold",col.align or "left","center",true)
        if i<#columns then dxDrawRectangle(cx+cw-px(1,l),ty,px(1,l),h-titleH,C("line")) end
        cx=cx+cw
    end
    local visible=math.max(1,math.floor((h-titleH-headerH)/rowH))
    local offset=P[scrollKey] or 0
    local maxOffset=math.max(0,#rows-visible); offset=math.max(0,math.min(offset,maxOffset)); P[scrollKey]=offset
    P.tableRects[scrollKey]={x=x,y=ty+headerH,w=w,h=h-titleH-headerH,maxOffset=maxOffset}
    if #rows==0 then drawText("No records.",x,ty+headerH,w,h-titleH-headerH,C("muted"),0.80*l.scale,"default","center"); return end
    local ry=ty+headerH
    for idx=offset+1,math.min(#rows,offset+visible) do
        local row=rows[idx]
        if mx and my and pointInRect(mx,my,{x=x,y=ry,w=w,h=rowH}) and tostring(row.reason or "") ~= "" then
            P.hoverReason = tostring(row.reason)
        end
        if (idx-offset)%2==0 then dxDrawRectangle(x,ry,w,rowH,tocolor(255,255,255,7)) end
        local cellx=x
        for ci,col in ipairs(columns) do
            local cw=w*col.ratio
            local value=col.value and col.value(row) or tostring(row[col.key] or "")
            drawText(value,cellx+px(5,l),ry,cw-px(10,l),rowH,col.color and col.color(row) or C("text"),0.63*l.scale,"default",col.align or "left","center",true)
            cellx=cellx+cw
        end
        if actionBuilder then actionBuilder(row,ry,rowH,x,w,l,mx,my) end
        dxDrawRectangle(x,ry+rowH-px(1,l),w,px(1,l),C("line"))
        ry=ry+rowH
    end
end

local function pagedTable(title, columns, rows, meta, pageKey, x,y,w,h,l,mx,my,scrollKey, actionBuilder)
    meta = type(meta) == "table" and meta or { page=1, pages=1, total=#(rows or {}) }
    local footerH = px(28,l)
    tableRows(title, columns, rows, x,y,w,math.max(px(80,l),h-footerH),l,mx,my,scrollKey,actionBuilder)
    local fy = y + h - footerH
    local page = math.max(1, tonumber(meta.page) or 1)
    local pages = math.max(1, tonumber(meta.pages) or 1)
    local total = math.max(0, tonumber(meta.total) or 0)
    drawText(("Page %d / %d   |   Total: %d"):format(page,pages,total),x+px(86,l),fy,w-px(172,l),footerH,C("muted"),0.62*l.scale,"default-bold","center")
    local prev={x=x,y=fy+px(2,l),w=px(78,l),h=footerH-px(4,l),id="history_prev",pageKey=pageKey,page=page,pages=pages,enabled=page>1}
    local nextR={x=x+w-px(78,l),y=fy+px(2,l),w=px(78,l),h=footerH-px(4,l),id="history_next",pageKey=pageKey,page=page,pages=pages,enabled=page<pages}
    for _,r in ipairs({prev,nextR}) do
        local hover=r.enabled and mx and pointInRect(mx,my,r)
        dxDrawRectangle(r.x,r.y,r.w,r.h,r.enabled and (hover and C("cardHover") or C("card")) or tocolor(24,28,36,190))
        drawText(r.id=="history_prev" and "< Prev" or "Next >",r.x,r.y,r.w,r.h,r.enabled and C("text") or C("muted"),0.58*l.scale,"default-bold","center")
        P.actionRects[#P.actionRects+1]=r
    end
end

local function renderReasonTooltip(mx,my,l)
    local reason=tostring(P.hoverReason or "")
    if reason=="" or not mx or not my then return end
    local sw,sh=guiGetScreenSize()
    local w=math.min(px(520,l),sw-px(30,l))
    local lines=math.max(2,math.ceil(#reason/72))
    local h=math.min(px(300,l),px(34 + lines*16,l))
    local x=math.min(mx+px(14,l),sw-w-px(10,l))
    local y=math.min(my+px(14,l),sh-h-px(10,l))
    x=math.max(px(10,l),x); y=math.max(px(10,l),y)
    dxDrawRectangle(x,y,w,h,tocolor(8,10,14,248))
    dxDrawRectangle(x,y,w,px(2,l),C("accent"))
    dxDrawText("Reason: "..reason,x+px(10,l),y+px(8,l),x+w-px(10,l),y+h-px(8,l),C("text"),0.68*l.scale,"default","left","top",false,true,false,false)
end

local function renderWarn(x,y,w,h,l,mx,my)
    renderContextHeader(x,y,w,l,mx,my,"WARN")
    local formY=y+px(62,l)
    drawText("WARN",x,formY,w,px(22,l),C("muted"),0.76*l.scale,"default-bold")
    local minus={x=x,y=formY+px(28,l),w=px(34,l),h=px(34,l),id="warn_minus"}
    local amountX=x+px(40,l); local amountW=px(58,l)
    local plus={x=amountX+amountW+px(6,l),y=minus.y,w=px(34,l),h=px(34,l),id="warn_plus"}
    setEditLayout(P.elements.warnAmount,amountX,minus.y,amountW,minus.h,true)
    local saveX=x+w-px(108,l)
    local reasonX=plus.x+plus.w+px(12,l)
    local reasonW=math.max(px(140,l),saveX-px(10,l)-reasonX)
    setEditLayout(P.elements.reason,reasonX,minus.y,reasonW,minus.h,true)
    setVisible(P.elements.timeCombo,false)
    for _,r in ipairs({minus,plus}) do
        local hover=mx and pointInRect(mx,my,r); dxDrawRectangle(r.x,r.y,r.w,r.h,hover and C("cardHover") or C("card")); drawText(r.id=="warn_minus" and "-" or "+",r.x,r.y,r.w,r.h,C("text"),1.0*l.scale,"default-bold","center"); P.actionRects[#P.actionRects+1]=r
    end
    local save={x=saveX,y=minus.y,w=px(108,l),h=minus.h,id="warn_save",enabled=not A.pending}
    dxDrawRectangle(save.x,save.y,save.w,save.h,C("accentSoft")); drawText("Save Warn",save.x,save.y,save.w,save.h,C("text"),0.72*l.scale,"default-bold","center"); P.actionRects[#P.actionRects+1]=save
    local active=tonumber(P.data.activeCount) or 0; local maximum=tonumber(P.data.maximum) or 10
    drawText(("Current State: Warnings [%d/%d] | Each Warn issuance expires after 7 days."):format(active,maximum),x,minus.y+px(40,l),w,px(20,l),C("warning"),0.68*l.scale,"default-bold")

    local stateY=minus.y+px(68,l); local stateH=px(150,l)
    local stateCols={
        {label="Warn",ratio=.08,align="center",value=function(r)return tostring(r.amount or 0) end},
        {label="Date",ratio=.18,value=function(r)return tostring(r.jalali_date or "-") end},
        {label="Expires",ratio=.15,value=function(r)return tostring(r.remaining or "-") end},
        {label="Reason",ratio=.29,value=function(r)return tostring(r.reason or "-") end},
        {label="Performer",ratio=.17,value=function(r)return tostring(r.performer_name or "-") end},
        {label="Action",ratio=.13,align="center",value=function()return "" end}
    }
    tableRows("WARN STATE",stateCols,P.data.state,x,stateY,w,stateH,l,mx,my,"stateScroll",function(row,ry,rowH,tx,tw,ll,mmx,mmy)
        local bx=tx+tw*(.08+.18+.15+.29+.17)+px(4,ll); local bw=tw*.13-px(8,ll)
        local r={x=bx,y=ry+px(4,ll),w=bw,h=rowH-px(8,ll),id="warn_remove",warnID=row.id,enabled=hasPermission("punishment.remove_warn")}
        local hover=r.enabled and mmx and pointInRect(mmx,mmy,r); dxDrawRectangle(r.x,r.y,r.w,r.h,r.enabled and (hover and C("cardHover") or tocolor(82,35,42,255)) or tocolor(24,28,36,190)); drawText("Remove",r.x,r.y,r.w,r.h,r.enabled and C("danger") or C("muted"),0.60*ll.scale,"default-bold","center"); P.actionRects[#P.actionRects+1]=r
    end)

    local histY=stateY+stateH+px(8,l); local histH=y+h-histY
    local histCols={
        {label="Name",ratio=.16,value=function(rw)return tostring((rw and rw.username) or (P.target and P.target.username) or "-") end},
        {label="ID",ratio=.08,align="center",value=function()return tostring(P.target and P.target.id or "-") end},
        {label="Warn",ratio=.08,align="center",value=function(r)return tostring(r.amount or 0) end},
        {label="Date",ratio=.18,value=function(r)return tostring(r.jalali_date or "-") end},
        {label="Reason",ratio=.30,value=function(r)return tostring(r.reason or "-") end},
        {label="Performer",ratio=.20,value=function(r)return tostring(r.performer_name or "-") end}
    }
    pagedTable("HISTORY",histCols,P.data.history,P.data.historyMeta,"historyPage",x,histY,w,histH,l,mx,my,"historyScroll")
end

local function renderKick(x,y,w,h,l,mx,my)
    renderContextHeader(x,y,w,l,mx,my,"KICK")
    local formY=y+px(70,l)
    drawText("Reason",x,formY,w,px(20,l),C("muted"),0.74*l.scale,"default-bold")
    local btnW=px(100,l); setEditLayout(P.elements.reason,x,formY+px(24,l),w-btnW-px(10,l),px(36,l),true); setVisible(P.elements.warnAmount,false); setVisible(P.elements.timeCombo,false)
    local r={x=x+w-btnW,y=formY+px(24,l),w=btnW,h=px(36,l),id="kick",enabled=not A.pending and hasPermission("punishment.kick")}; dxDrawRectangle(r.x,r.y,r.w,r.h,tocolor(82,35,42,255)); drawText("Kick",r.x,r.y,r.w,r.h,C("danger"),0.76*l.scale,"default-bold","center"); P.actionRects[#P.actionRects+1]=r
    local hy=formY+px(82,l)
    local cols={
        {label="Name",ratio=.16,value=function(rw)return tostring((rw and rw.username) or (P.target and P.target.username) or "-") end},
        {label="ID",ratio=.09,align="center",value=function()return tostring(P.target and P.target.id or "-") end},
        {label="Date",ratio=.20,value=function(rw)return tostring(rw.jalali_date or "-") end},
        {label="Reason",ratio=.35,value=function(rw)return tostring(rw.reason or "-") end},
        {label="Performer",ratio=.20,value=function(rw)return tostring(rw.performer_name or "-") end}
    }
    pagedTable("KICK HISTORY",cols,P.data.history,P.data.historyMeta,"historyPage",x,hy,w,y+h-hy,l,mx,my,"historyScroll")
end

local function renderTimed(mode,title,actionLabel,x,y,w,h,l,mx,my)
    renderContextHeader(x,y,w,l,mx,my,title)
    local formY=y+px(68,l)
    local btnW=px(105,l); local comboW=px(170,l); local gap=px(10,l)
    drawText("Reason",x,formY,w,px(20,l),C("muted"),0.72*l.scale,"default-bold")
    setEditLayout(P.elements.reason,x,formY+px(24,l),w-comboW-btnW-gap*2,px(36,l),true)
    setEditLayout(P.elements.timeCombo,x+w-comboW-btnW-gap,formY+px(24,l),comboW,px(330,l),true)
    setVisible(P.elements.warnAmount,false)
    local actionId=mode=="mute" and "mute" or "jail"
    local r={x=x+w-btnW,y=formY+px(24,l),w=btnW,h=px(36,l),id=actionId,enabled=not A.pending}; dxDrawRectangle(r.x,r.y,r.w,r.h,C("accentSoft")); drawText(actionLabel,r.x,r.y,r.w,r.h,C("text"),0.72*l.scale,"default-bold","center"); P.actionRects[#P.actionRects+1]=r
    local stateY=formY+px(78,l); local stateH=px(130,l)
    local cols={
        {label="Name",ratio=.14,value=function(rw)return tostring((rw and rw.username) or (P.target and P.target.username) or "-") end},
        {label="ID",ratio=.08,align="center",value=function()return tostring(P.target and P.target.id or "-") end},
        {label="Date",ratio=.18,value=function(rw)return tostring(rw.jalali_date or "-") end},
        {label="For Time",ratio=.13,value=function(rw)local d=tostring(rw.duration_label or "-"); local rem=tostring(rw.remaining or "-"); return d.." / "..rem end},
        {label="Reason",ratio=.24,value=function(rw)return tostring(rw.reason or "-") end},
        {label="Performer",ratio=.14,value=function(rw)return tostring(rw.performer_name or "-") end},
        {label="Action",ratio=.09,align="center",value=function()return "" end}
    }
    tableRows(title.." STATE",cols,P.data.state,x,stateY,w,stateH,l,mx,my,"stateScroll",function(row,ry,rowH,tx,tw,ll,mmx,mmy)
        local start=.14+.08+.18+.13+.24+.14; local bx=tx+tw*start+px(3,ll); local bw=tw*.09-px(6,ll)
        local id=mode=="mute" and "unmute" or "unjail"; local label=mode=="mute" and "Unmute" or "Unjail"
        local rr={x=bx,y=ry+px(4,ll),w=bw,h=rowH-px(8,ll),id=id,enabled=true}; local hover=mmx and pointInRect(mmx,mmy,rr); dxDrawRectangle(rr.x,rr.y,rr.w,rr.h,hover and C("cardHover") or C("card")); drawText(label,rr.x,rr.y,rr.w,rr.h,C("good"),0.56*ll.scale,"default-bold","center"); P.actionRects[#P.actionRects+1]=rr
    end)
    local histY=stateY+stateH+px(8,l)
    local hcols={
        {label="Name",ratio=.14,value=function(rw)return tostring((rw and rw.username) or (P.target and P.target.username) or "-") end},
        {label="ID",ratio=.08,align="center",value=function()return tostring(P.target and P.target.id or "-") end},
        {label="Date",ratio=.19,value=function(rw)return tostring(rw.jalali_date or "-") end},
        {label="For Time",ratio=.14,value=function(rw)return tostring(rw.duration_label or "-") end},
        {label="Reason",ratio=.29,value=function(rw)return tostring(rw.reason or "-") end},
        {label="Performer",ratio=.16,value=function(rw)return tostring(rw.performer_name or "-") end}
    }
    pagedTable(title.." HISTORY",hcols,P.data.history,P.data.historyMeta,"historyPage",x,histY,w,y+h-histY,l,mx,my,"historyScroll")
end

local function renderBan(x,y,w,h,l,mx,my)
    renderContextHeader(x,y,w,l,mx,my,"BAN")
    local sideW=px(210,l); local gap=px(14,l); local sx=x; local sy=y+px(68,l)
    local sections={ {id="temporary",label="Temporary Ban"},{id="permanent",label="Permanent Ban"} }
    for _,sec in ipairs(sections) do
        local active=P.banSection==sec.id; local r={x=sx,y=sy,w=sideW,h=px(46,l),id="ban_section",section=sec.id}; local hover=mx and pointInRect(mx,my,r)
        dxDrawRectangle(r.x,r.y,r.w,r.h,active and C("accentSoft") or (hover and C("cardHover") or C("card"))); dxDrawRectangle(r.x,r.y,px(4,l),r.h,active and C("accent") or C("muted")); drawText(sec.label.."  v",r.x+px(12,l),r.y,r.w-px(20,l),r.h,active and C("text") or C("muted"),0.72*l.scale,"default-bold"); P.actionRects[#P.actionRects+1]=r; sy=sy+px(54,l)
    end
    if P.banSection=="permanent" and not hasPermission("punishment.perm_ban") then
        drawText("Permanent Ban is available only for Founder / Owner / Manager.",sx,sy+px(4,l),sideW,px(90,l),C("warning"),0.68*l.scale,"default","left","top",true)
    end

    local progress=math.min(1,(getTickCount()-(P.banAnimStart or 0))/180)
    local cx=x+sideW+gap; local cw=w-sideW-gap; local cy=y+px(68,l)+px(12,l)*(1-progress)
    local permanent=P.banSection=="permanent"
    local title=permanent and "Permanent BAN" or "Temporary BAN"
    drawText(title,cx,cy,cw,px(24,l),C("muted"),0.78*l.scale,"default-bold")
    local btnW=px(90,l); local comboW=px(150,l); local gy=cy+px(28,l)
    if permanent then
        setEditLayout(P.elements.reason,cx,gy,cw-btnW-px(10,l),px(36,l),true); setVisible(P.elements.timeCombo,false)
    else
        setEditLayout(P.elements.reason,cx,gy,cw-btnW-comboW-px(20,l),px(36,l),true); setEditLayout(P.elements.timeCombo,cx+cw-btnW-comboW-px(10,l),gy,comboW,px(300,l),true)
    end
    setVisible(P.elements.warnAmount,false)
    local canBan=not A.pending and (not permanent or hasPermission("punishment.perm_ban"))
    local br={x=cx+cw-btnW,y=gy,w=btnW,h=px(36,l),id=permanent and "perm_ban" or "temp_ban",enabled=canBan}; dxDrawRectangle(br.x,br.y,br.w,br.h,canBan and tocolor(82,35,42,255) or tocolor(24,28,36,190)); drawText("Ban",br.x,br.y,br.w,br.h,canBan and C("danger") or C("muted"),0.72*l.scale,"default-bold","center"); P.actionRects[#P.actionRects+1]=br

    local stateY=gy+px(54,l); local stateH=px(124,l)
    local stateRows={}
    for _,rw in ipairs(P.data.state or {}) do if (permanent and rw.ban_type=="permanent") or ((not permanent) and rw.ban_type=="temporary") then stateRows[#stateRows+1]=rw end end
    local scols={
        {label="Name",ratio=.14,value=function(rw)return tostring((rw and rw.username) or (P.target and P.target.username) or "-") end},
        {label="ID",ratio=.08,align="center",value=function()return tostring(P.target and P.target.id or "-") end},
        {label="Date",ratio=.18,value=function(rw)return tostring(rw.jalali_date or "-") end},
        {label=permanent and "Type" or "For Time",ratio=.14,value=function(rw)if permanent then return "Permanent" end local d=tostring(rw.duration_label or "-"); local rem=tostring(rw.remaining or "-"); return d.." / "..rem end},
        {label="Reason",ratio=.25,value=function(rw)return tostring(rw.reason or "-") end},
        {label="Performer",ratio=.13,value=function(rw)return tostring(rw.performer_name or "-") end},
        {label="Action",ratio=.08,value=function()return "" end}
    }
    tableRows("BAN STATE",scols,stateRows,cx,stateY,cw,stateH,l,mx,my,"stateScroll",function(row,ry,rowH,tx,tw,ll,mmx,mmy)
        local bx=tx+tw*.92+px(2,ll); local rr={x=bx,y=ry+px(4,ll),w=tw*.08-px(4,ll),h=rowH-px(8,ll),id="unban",enabled=(row.ban_type~="permanent" or hasPermission("punishment.perm_ban"))}; local hover=rr.enabled and mmx and pointInRect(mmx,mmy,rr); dxDrawRectangle(rr.x,rr.y,rr.w,rr.h,rr.enabled and (hover and C("cardHover") or C("card")) or tocolor(24,28,36,190)); drawText("Unban",rr.x,rr.y,rr.w,rr.h,rr.enabled and C("good") or C("muted"),0.52*ll.scale,"default-bold","center"); P.actionRects[#P.actionRects+1]=rr
    end)
    local histY=stateY+stateH+px(8,l); local history=permanent and (P.data.permHistory or {}) or (P.data.tempHistory or {})
    local hcols={
        {label="Name",ratio=.14,value=function(rw)return tostring((rw and rw.username) or (P.target and P.target.username) or "-") end},
        {label="ID",ratio=.08,align="center",value=function()return tostring(P.target and P.target.id or "-") end},
        {label="Date",ratio=.19,value=function(rw)return tostring(rw.jalali_date or "-") end},
        {label=permanent and "Type" or "For Time",ratio=.14,value=function(rw)return permanent and "Permanent" or tostring(rw.duration_label or "-") end},
        {label="Reason",ratio=.29,value=function(rw)return tostring(rw.reason or "-") end},
        {label="Performer",ratio=.16,value=function(rw)return tostring(rw.performer_name or "-") end}
    }
    pagedTable("BAN HISTORY",hcols,history,permanent and P.data.permHistoryMeta or P.data.tempHistoryMeta,permanent and "permHistoryPage" or "tempHistoryPage",cx,histY,cw,y+h-histY,l,mx,my,"historyScroll")
end

function P.renderContext(x,y,w,h,l,mx,my)
    P.createUI(); P.actionRects={}; P.tableRects={}; P.hoverReason=nil
    if P.mode=="warn" then renderWarn(x,y,w,h,l,mx,my)
    elseif P.mode=="kick" then renderKick(x,y,w,h,l,mx,my)
    elseif P.mode=="mute" then renderTimed("mute","MUTE","Mute",x,y,w,h,l,mx,my)
    elseif P.mode=="jail" then renderTimed("jail","JAIL","Jail",x,y,w,h,l,mx,my)
    elseif P.mode=="ban" then renderBan(x,y,w,h,l,mx,my)
    else P.back() end
    renderReasonTooltip(mx,my,l)
end

function P.handleClick(x,y)
    if not A.visible or A.category~="punishment" then return false end
    if P.isContextMode() and pointInRect(x,y,P.backRect) then P.back(); return true end

    for _,r in ipairs(P.actionRects or {}) do
        if pointInRect(x,y,r) then
            if r.enabled==false then return true end
            if r.item and r.item.mode then openMode(r.item.mode)
            elseif r.id=="warn_minus" then P.warnAmount=math.max(1,(tonumber(guiGetText(P.elements.warnAmount)) or P.warnAmount or 1)-1); guiSetText(P.elements.warnAmount,tostring(P.warnAmount))
            elseif r.id=="warn_plus" then P.warnAmount=math.min(10,(tonumber(guiGetText(P.elements.warnAmount)) or P.warnAmount or 1)+1); guiSetText(P.elements.warnAmount,tostring(P.warnAmount))
            elseif r.id=="warn_save" then sendAction("warn",{amount=guiGetText(P.elements.warnAmount),reason=reasonText()})
            elseif r.id=="warn_remove" then sendAction("remove_warn",{warnID=r.warnID})
            elseif r.id=="kick" then sendAction("kick",{reason=reasonText()})
            elseif r.id=="mute" then sendAction("mute",{reason=reasonText(),timeKey=currentTimeKey()})
            elseif r.id=="unmute" then sendAction("unmute",{})
            elseif r.id=="jail" then sendAction("jail",{reason=reasonText(),timeKey=currentTimeKey()})
            elseif r.id=="unjail" then sendAction("unjail",{})
            elseif r.id=="ban_section" then
                if P.banSection~=r.section then P.banSection=r.section; P.banAnimStart=getTickCount(); P.historyScroll=0; P.stateScroll=0; guiSetText(P.elements.reason,""); if r.section=="temporary" then setComboItems(SC_STAFF.PUNISHMENT_BAN_TIMES) end end
            elseif r.id=="temp_ban" then sendAction("temp_ban",{reason=reasonText(),timeKey=currentTimeKey()})
            elseif r.id=="perm_ban" then sendAction("perm_ban",{reason=reasonText()})
            elseif r.id=="unban" then sendAction("unban",{})
            elseif r.id=="history_prev" or r.id=="history_next" then
                local key=tostring(r.pageKey or "historyPage")
                local current=math.max(1,tonumber(P[key]) or tonumber(r.page) or 1)
                local pages=math.max(1,tonumber(r.pages) or 1)
                if r.id=="history_prev" then current=math.max(1,current-1) else current=math.min(pages,current+1) end
                P[key]=current; P.historyScroll=0; requestData()
            end
            return true
        end
    end
    return false
end

function P.handleWheel(button,mx,my)
    if not P.isContextMode() then return false end
    for key,r in pairs(P.tableRects or {}) do
        if pointInRect(mx,my,r) then
            local field=key; local current=P[field] or 0
            if button=="mouse_wheel_up" then P[field]=math.max(0,current-1) else P[field]=math.min(r.maxOffset or 0,current+1) end
            return true
        end
    end
    return false
end

addEvent("scPunishmentTargets", true)
addEventHandler("scPunishmentTargets", resourceRoot, function(rows)
    if type(rows) ~= "table" then rows = {} end
    A.punishmentPlayers = rows
    if A.category == "punishment" and A.filterPlayers then
        A.filterPlayers()
    end
end)

addEvent("scPunishmentData",true)
addEventHandler("scPunishmentData",resourceRoot,function(mode,success,message,data)
    if not success then outputChatBox("[StarsCity] Khata: "..tostring(message),255,80,80); return end
    if P.mode==mode then
        P.data=type(data)=="table" and data or {}
        if type(P.data.historyMeta)=="table" then P.historyPage=math.max(1,tonumber(P.data.historyMeta.page) or P.historyPage or 1) end
        if type(P.data.tempHistoryMeta)=="table" then P.tempHistoryPage=math.max(1,tonumber(P.data.tempHistoryMeta.page) or P.tempHistoryPage or 1) end
        if type(P.data.permHistoryMeta)=="table" then P.permHistoryPage=math.max(1,tonumber(P.data.permHistoryMeta.page) or P.permHistoryPage or 1) end
    end
end)

addEvent("scPunishmentActionResult",true)
addEventHandler("scPunishmentActionResult",resourceRoot,function(success,message,mode,refreshSnapshot)
    A.setPending(false)
    if success then
        outputChatBox("[StarsCity] "..tostring(message),80,220,120)
        guiSetText(P.elements.reason,"")
        requestData()
    else
        outputChatBox("[StarsCity] Khata: "..tostring(message),255,80,80)
    end
    if refreshSnapshot and A.visible then
        triggerServerEvent("scAdminRequestSnapshot",resourceRoot)
        P.refreshTargets(true)
    end
end)

addEventHandler("onClientGUIChanged",root,function()
    if not A or not A.visible or A.category~="punishment" then return end
    if source==P.elements.warnAmount then
        local text=guiGetText(source) or ""; local digits=text:gsub("%D","")
        if text~=digits then guiSetText(source,digits); guiEditSetCaretIndex(source,#digits) end
        local n=tonumber(digits)
        if n then P.warnAmount=math.max(1,math.min(10,n)) end
    end
end)
