-- =========================================================
-- STARS CITY - STAFF DUTY CLIENT GUARD
-- Defensive rule: OnDuty staff cannot directly damage players/vehicles.
-- =========================================================

local DUTY_KEY = (SC_STAFF.DUTY and SC_STAFF.DUTY.dataKey) or "staff:onDuty"

local function isOnDutyStaff(element)
    return isElement(element)
        and getElementType(element) == "player"
        and (tonumber(getElementData(element, "staff:level")) or 0) > 0
        and getElementData(element, DUTY_KEY) == true
end

addEventHandler("onClientPlayerDamage", root, function(attacker)
    if isOnDutyStaff(attacker) then
        cancelEvent()
    end
end)

addEventHandler("onClientVehicleDamage", root, function(attacker)
    if isOnDutyStaff(attacker) then
        cancelEvent()
    end
end)
