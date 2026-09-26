HUD = HUD or {}

HUD.storage = {}
HUD.storage.file = "settings.xml"

local layoutNames = {"small", "medium", "large"}

function HUD.storage:save()

    local xml = xmlCreateFile(self.file, "hud")

    if not xml then
        return false
    end

    -- Save all three independent position profiles.
    local positions = xmlCreateChild(xml, "positions")

    for _,size in ipairs(layoutNames) do

        local layoutNode = xmlCreateChild(positions, size)
        local layout = HUD.layouts and HUD.layouts[size]

        if layout then

            for name,pos in pairs(layout) do

                local node = xmlCreateChild(layoutNode, name)
                xmlNodeSetAttribute(node, "x", tostring(pos.x))
                xmlNodeSetAttribute(node, "y", tostring(pos.y))

            end

        end

    end

    -- Visibility
    local visible = xmlCreateChild(xml, "visible")

    for name,state in pairs(HUD.settings.visible) do
        xmlNodeSetAttribute(visible, name, tostring(state))
    end

    -- Theme
    local themeNode = xmlCreateChild(xml, "theme")

    local iconColor = "default"
    if HUD.theme and HUD.theme.icon and HUD.theme.icon.currentColor then
        iconColor = HUD.theme.icon.currentColor
    elseif HUD.assets and HUD.assets.currentColor then
        iconColor = HUD.assets.currentColor
    end
    xmlNodeSetAttribute(themeNode, "iconColor", tostring(iconColor))

    local textSize = "small"
    if HUD.theme and HUD.theme.currentTextSize then
        textSize = HUD.theme.currentTextSize
    end
    xmlNodeSetAttribute(themeNode, "textSize", tostring(textSize))

    local currentFont = "default"
    if HUD.theme and HUD.theme.currentFont then
        currentFont = HUD.theme.currentFont
    end
    xmlNodeSetAttribute(themeNode, "currentFont", tostring(currentFont))

    local opacity = 180
    if HUD.theme and HUD.theme.background and HUD.theme.background.opacity then
        opacity = HUD.theme.background.opacity
    end

    local radius = 12
    if HUD.theme and HUD.theme.borderRadius then
        radius = HUD.theme.borderRadius
    end

    xmlNodeSetAttribute(themeNode, "opacity", tostring(opacity))
    xmlNodeSetAttribute(themeNode, "radius", tostring(radius))

    xmlSaveFile(xml)
    xmlUnloadFile(xml)

    outputChatBox("HUD Saved")

    return true
end


local function loadLayoutNode(layoutNode, layout)

    if not layoutNode or not layout then
        return
    end

    for name,pos in pairs(layout) do

        local node = xmlFindChild(layoutNode, name, 0)

        if node then

            local x = tonumber(xmlNodeGetAttribute(node, "x"))
            local y = tonumber(xmlNodeGetAttribute(node, "y"))

            if x then pos.x = x end
            if y then pos.y = y end

        end

    end

end


function HUD.storage:load()

    -- New player: no personal settings file.
    -- Keep config.lua + theme.lua defaults (SMALL).
    if not fileExists(self.file) then

        if HUD.theme then
            HUD.theme.currentTextSize = "small"
        end

        if HUD.setLayout then
            HUD:setLayout("small")
        end

        return false
    end

    local xml = xmlLoadFile(self.file)

    if not xml then
        return false
    end

    -- Positions
    local positions = xmlFindChild(xml, "positions", 0)

    if positions and HUD.layouts then

        local hasProfileFormat = false

        for _,size in ipairs(layoutNames) do

            local layoutNode = xmlFindChild(positions, size, 0)

            if layoutNode then
                hasProfileFormat = true
                loadLayoutNode(layoutNode, HUD.layouts[size])
            end

        end

        -- Compatibility with old settings.xml:
        -- old <positions><ping .../></positions> becomes SMALL only.
        if not hasProfileFormat then
            loadLayoutNode(positions, HUD.layouts.small)
        end

    end

    -- Visible
    local visible = xmlFindChild(xml, "visible", 0)

    if visible then

        for name,_ in pairs(HUD.settings.visible) do

            local value = xmlNodeGetAttribute(visible, name)

            if value then
                HUD.settings.visible[name] = value == "true"
            end

        end

    end

    -- Theme
    local themeNode = xmlFindChild(xml, "theme", 0)
    local selectedSize = "small"

    if themeNode then

        local iconColor = xmlNodeGetAttribute(themeNode, "iconColor")
        local textSize = xmlNodeGetAttribute(themeNode, "textSize")
        local currentFont = xmlNodeGetAttribute(themeNode, "currentFont")
        local opacity = tonumber(xmlNodeGetAttribute(themeNode, "opacity"))
        local radius = tonumber(xmlNodeGetAttribute(themeNode, "radius"))

        HUD.storage.pendingTheme = HUD.storage.pendingTheme or {}

        if iconColor and iconColor ~= "" then

            HUD.storage.pendingTheme.iconColor = iconColor

            if HUD.theme and HUD.theme.icon then
                HUD.theme.icon.currentColor = iconColor
            end

            if HUD.assets then
                HUD.assets.currentColor = iconColor
            end

        end

        if textSize == "small"
        or textSize == "medium"
        or textSize == "large" then

            selectedSize = textSize
            HUD.storage.pendingTheme.textSize = textSize

            if HUD.theme then
                HUD.theme.currentTextSize = textSize
            end

        end

        if currentFont and currentFont ~= "" then

            HUD.storage.pendingTheme.currentFont = currentFont

            if HUD.theme and HUD.theme.fonts and HUD.theme.fonts[currentFont] then
                HUD.theme.currentFont = currentFont
            end

        end

        if opacity then

            HUD.storage.pendingTheme.opacity = opacity

            if HUD.theme and HUD.theme.background then
                HUD.theme.background.opacity = opacity
            end

        end

        if radius then

            HUD.storage.pendingTheme.radius = radius

            if HUD.theme then
                HUD.theme.borderRadius = radius
            end

        end

    end

    -- IMPORTANT: position profile must always match selected Text Size.
    if HUD.setLayout then
        HUD:setLayout(selectedSize)
    end

    xmlUnloadFile(xml)

    return true
end
