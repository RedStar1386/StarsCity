-- STARS CITY - VEHICLE MANAGEMENT v3.0.2
-- UI cloned from Player Tools layout style

SC_ADMIN_VEHICLE_MANAGEMENT = SC_ADMIN_VEHICLE_MANAGEMENT or {}
local V = SC_ADMIN_VEHICLE_MANAGEMENT
local A = SC_ADMIN_CLIENT

V.selectedVehicle=nil
V.rows={}
V.actionRects={}

local function targetVehicle()
    if isElement(V.selectedVehicle) then return V.selectedVehicle end
    if isPedInVehicle(localPlayer) then return getPedOccupiedVehicle(localPlayer) end
    local x,y,z=getElementPosition(localPlayer)
    local best,dist
    for _,veh in ipairs(getElementsByType("vehicle")) do
        local vx,vy,vz=getElementPosition(veh)
        local d=getDistanceBetweenPoints3D(x,y,z,vx,vy,vz)
        if d<8 and (not dist or d<dist) then best=veh dist=d end
    end
    return best
end

function V.render(x,y,w,h,l,mx,my)
    V.rows={}
    V.actionRects={}
    local C=A.COLORS
    local px=A.px
    local dt=A.drawText

    dt("Vehicle Management",x,y,w,px(30,l),C.text,1.02*l.scale,"default-bold")
    dt("Online players currently inside vehicles",x,y+px(28,l),w,px(20,l),C.muted,0.75*l.scale)

    local top=y+px(65,l)
    local gap=px(10,l)
    local left=w*0.34
    local right=w-left-gap

    dxDrawRectangle(x,top,left,h-px(80,l),C.card)
    dxDrawRectangle(x+left+gap,top,right,h-px(80,l),C.card)

    dt("ONLINE VEHICLES",x+px(15,l),top+px(14,l),left,20,C.accent,0.75*l.scale,"default-bold")

    local ry=top+px(45,l)
    for _,p in ipairs(getElementsByType("player")) do
        if isPedInVehicle(p) then
            local veh=getPedOccupiedVehicle(p)
            local id=getElementData(p,"playerid") or getElementData(p,"id") or "?"
            local name=getPlayerName(p):gsub("#%x%x%x%x%x%x","")
            local r={x=x+px(10,l),y=ry,w=left-px(20,l),h=px(38,l),vehicle=veh}
            V.rows[#V.rows+1]=r
            local hover=mx and A.pointInRect(mx,my,r)
            dxDrawRectangle(r.x,r.y,r.w,r.h,hover and C.cardHover or C.sidebar)
            dt(name.." ["..id.."]",r.x+px(8,l),r.y+3,r.w,15,C.text,.7*l.scale,"default-bold")
            dt("Vehicle: "..getVehicleName(veh),r.x+px(8,l),r.y+18,r.w,14,C.muted,.62*l.scale)
            ry=ry+px(44,l)
        end
    end

    local rx=x+left+gap
    dt("Vehicle Information",rx+px(15,l),top+px(14,l),right,20,C.accent,.75*l.scale,"default-bold")

    local veh=targetVehicle()
    if isElement(veh) then
        local driver=getVehicleOccupant(veh,0)
        local dn=driver and getPlayerName(driver):gsub("#%x%x%x%x%x%x","") or "Unknown"
        dt("Driver: "..dn,rx+px(15,l),top+px(50,l),right,20,C.text,.75*l.scale,"default-bold")
        dt("Vehicle: "..getVehicleName(veh).." ["..getElementModel(veh).."]",rx+px(15,l),top+px(75,l),right,20,C.text,.7*l.scale)
    else
        dt("No vehicle selected",rx+px(15,l),top+px(55,l),right,20,C.warning,.75*l.scale)
    end

    local buttons={
        {text="Fix Vehicle | GM/Normal",id="Fix Vehicle"},
        {text="Lock / Unlock | Freeze / Unfreeze",id="Lock / Unlock"},
        {text="Engine ON / OFF | Lights ON / OFF",id="Engine ON / OFF"},
        {text="Set Color | Set Plate",id="Set Color"},
        {text="Eject Driver | Eject Occupants",id="Eject Driver"},
        {text="Respawn | Vehicle Door",id="Respawn"},
        {text="Tuning Tools",id="Tuning Tools"}
    }

    local by=top+px(155,l)
    for i,item in ipairs(buttons) do
        local label=item.text
        local bw=(right-px(40,l))/2
        local r={x=rx+px(15,l)+((i-1)%2)*(bw+px(10,l)),
        y=by+math.floor((i-1)/2)*px(38,l),
        w=bw,h=px(30,l),id=item.id}
        V.actionRects[#V.actionRects+1]=r
        local hover=mx and A.pointInRect(mx,my,r)
        dxDrawRectangle(r.x,r.y,r.w,r.h,hover and C.cardHover or C.sidebar)
        dt(label,r.x,r.y,r.w,r.h,C.text,.65*l.scale,"default-bold","center")
    end
end

function V.handleClick(x,y)
    for _,r in ipairs(V.rows) do
        if A.pointInRect(x,y,r) then
            V.selectedVehicle=r.vehicle
            return true
        end
    end
    for _,r in ipairs(V.actionRects) do
        if A.pointInRect(x,y,r) then
            local veh=targetVehicle()
            if not isElement(veh) then return true end
            if r.id=="Fix Vehicle" then fixVehicle(veh)
            elseif r.id=="Lock / Unlock" then setVehicleLocked(veh,not isVehicleLocked(veh))
            elseif r.id=="Freeze / Unfreeze" then setElementFrozen(veh,not isElementFrozen(veh))
            elseif r.id=="Engine ON / OFF" then setVehicleEngineState(veh,not getVehicleEngineState(veh))
            end
            return true
        end
    end
end
