SC_ADMIN_VEHICLE = SC_ADMIN_VEHICLE or {}
local V = SC_ADMIN_VEHICLE
V.actionRects = {}
V.rowRects = {}

local function txt(text,x,y,w,h,size)
    if type(drawText)=="function" then
        drawText(text,x,y,w,h,COLORS.text,size or 0.7,"default-bold","left","center",true)
    else
        dxDrawText(text,x,y,x+w,y+h,tocolor(245,247,250,255),size or 0.8,"default-bold","left","center")
    end
end

local function button(text,x,y,w,h)
    local hover = false
    local color = (type(COLORS)=="table" and COLORS.card) or tocolor(27,32,42,255)
    dxDrawRectangle(x,y,w,h,color)
    dxDrawRectangle(x,y,4,h,(type(COLORS)=="table" and COLORS.accent) or tocolor(200,40,70,255))
    txt(text,x+10,y,w-15,h,0.69)
    V.actionRects[#V.actionRects+1]={x=x,y=y,w=w,h=h,id=text}
end

function V.render(x,y,w,h,l,mx,my)
    V.actionRects={}
    V.rowRects={}

    txt("Vehicle Tools",x,y,w,30,1.02)
    txt("Target Vehicle Information",x,y+30,w,24,0.8)

    local infoY=y+58
    dxDrawRectangle(x,infoY,w,110,(type(COLORS)=="table" and COLORS.card) or tocolor(24,28,36,255))
    txt("Driver: -",x+12,infoY+10,w-20,22,0.75)
    txt("Preview | Vehicle Name | ID",x+12,infoY+40,w-20,22,0.75)

    local startY=infoY+125
    local gap=6
    local bh=34
    local bw=(w-gap)/2

    local rows={
        {"Fix Vehicle","GM / Normal"},
        {"Lock / Unlock","Freeze / Unfreeze"},
        {"Engine On / Off","Lights On / Off"},
        {"Set Color","Set Plate"},
        {"Eject Driver","Eject Occupants"},
        {"Respawn","Vehicle Door"}
    }

    for r,row in ipairs(rows) do
        for c,name in ipairs(row) do
            button(name,x+(c-1)*(bw+gap),startY+(r-1)*(bh+gap),bw,bh)
        end
    end

    local ty=startY+#rows*(bh+gap)
    button("Tuning Tools",x+w/2-90,ty,180,bh)
end

function V.handleClick(mx,my)
    for _,r in ipairs(V.actionRects) do
        if mx>=r.x and mx<=r.x+r.w and my>=r.y and my<=r.y+r.h then
            triggerServerEvent("scStaffVehicleAction",resourceRoot,r.id)
            return true
        end
    end
    return false
end
