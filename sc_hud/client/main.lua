HUD = HUD or {}


local gtaHudComponents = {
    "ammo",
    "armour",
    "breath",
    "clock",
    "health",
    "money",
    "vehicle_name",
    "weapon",
    "wanted",
    "area_name",
    "radio"
}

local function setGTAHudVisible(state)

    for _, component in ipairs(gtaHudComponents) do
        setPlayerHudComponentVisible(component, state)
    end

end


local function hideGTAHud()

    setGTAHudVisible(false)

end


addEventHandler(
    "onClientResourceStart",
    resourceRoot,

    function()

        hideGTAHud()

        -- GTA/MTA can restore some HUD components during player initialization.
        -- Re-apply once initialization has finished.
        setTimer(hideGTAHud, 1000, 1)
        setTimer(hideGTAHud, 3000, 1)


    end
)


addEventHandler(
    "onClientPlayerSpawn",
    localPlayer,

    function()

        setTimer(hideGTAHud, 500, 1)

    end
)


addEventHandler(
    "onClientElementDataChange",
    localPlayer,

    function(dataName)

        if dataName ~= "account:loggedIn" then
            return
        end

        if getElementData(localPlayer, "account:loggedIn") then
            setTimer(hideGTAHud, 250, 1)
        end

    end
)


addEventHandler(
    "onClientResourceStop",
    resourceRoot,

    function()

        setGTAHudVisible(true)

    end
)



addEventHandler(
    "onClientRender",
    root,

    function()

        if HUD and HUD.render then

            HUD:render()

        end

    end
)

HUD.storage:load()
