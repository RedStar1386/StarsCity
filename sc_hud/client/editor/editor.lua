HUD = HUD or {}

HUD.editor = HUD.editor or {}
HUD.editor.open = false
HUD.editor.positionMode = false

local screenW, screenH = guiGetScreenSize()

-- Image-based editor panel.
-- The panel keeps the old HUD logic/events; only rendering and exact hitboxes changed.
HUD.editor.width = 900
HUD.editor.height = 600
HUD.editor.x = (screenW - HUD.editor.width) / 2
HUD.editor.y = (screenH - HUD.editor.height) / 2


-- ============================================================
-- EASY UI IMAGE POSITION SETTINGS
-- Edit ONLY this section to move/resize images on the panel.
-- All x/y values are relative to the panel top-left corner.
-- ============================================================

HUD.editor.ui = {

    panel = {
        x = 0,
        y = 0,
        size = 100,

        baseWidth = 900,
        baseHeight = 600
    },

    close = {
        x = 800,
        y = 40,
        size = 100,

        baseWidth = 34,
        baseHeight = 34
    },

    components = {
        startX = 45,
        startY = 155,

        boxSize = 100,
        boxBaseWidth = 185,
        boxBaseHeight = 62,

        gapX = 23,
        gapY = 18,

        toggleSize = 100,
        toggleBaseWidth = 54,
        toggleBaseHeight = 25,

        toggleOffsetX = 118,
        toggleOffsetY = 22
    },

    theme = {
        startX = 410,
        y = 348,

        size = 70,
        baseWidth = 28,
        baseHeight = 28,

        gap = 5
    },

    buttons = {
        save = {
            x = 200,
            y = 525,
            size = 80,
            baseWidth = 190,
            baseHeight = 55
        },

        editPosition = {
            x = 380,
            y = 525,
            size = 80,
            baseWidth = 190,
            baseHeight = 55
        },

        reset = {
            x = 560,
            y = 525,
            size = 80,
            baseWidth = 190,
            baseHeight = 55
        }
    }

}

-- ============================================================
-- TEXT SELECTOR POSITION SETTINGS
-- These are text-only controls drawn over panel_bg.png.
-- ============================================================

HUD.editor.textUI = {

    font = {
        x = 150,
        y = 397,
        width = 65,
        height = 38,
        gap = 1
    },

    opacity = {
        x = 590,
        y = 397,
        width = 72,
        height = 38,
        gap = 8
    },

    size = {
        x = 150,
        y = 457,
        width = 65,
        height = 38,
        gap = 1
    },

    radius = {
        x = 590,
        y = 457,
        width = 76,
        height = 38,
        gap = 8
    }

}



-- ============================================================
-- UNIFORM IMAGE SCALE
-- size = 100 means original configured size.
-- size = 150 means 150% (1.5x).
-- size = 75 means 75% (0.75x).
-- Width/height are calculated automatically to preserve aspect ratio.
-- ============================================================

local function scaledSize(baseWidth, baseHeight, percent)
    local scale = (percent or 100) / 100
    return baseWidth * scale, baseHeight * scale
end


-- ============================================================
-- UI TEXTURE CACHE
-- Images are loaded ONCE, not from disk every render frame.
-- This prevents FPS drops while the panel is open.
-- ============================================================

HUD.editor.texturePaths = {
    panel = "assets/ui/panel_bg.png",
    component = "assets/ui/component_box.png",
    toggleOn = "assets/ui/toggle_on.png",
    toggleOff = "assets/ui/toggle_off.png",

    themeDefault = "assets/ui/theme_default.png",
    themeSky = "assets/ui/theme_sky.png",
    themeYallow = "assets/ui/theme_yallow.png",
    themeGreen = "assets/ui/theme_green.png",
    themeRed = "assets/ui/theme_red.png",
    themePink = "assets/ui/theme_pink.png",
    themePurple = "assets/ui/theme_purple.png",

    save = "assets/ui/btn_save.png",
    edit = "assets/ui/btn_edit_position.png",
    savePosition = "assets/ui/btn_save_position.png",
    reset = "assets/ui/btn_reset.png",
    close = "assets/ui/btn_close.png"
}

HUD.editor.textures = {}
HUD.editor.panelFont = nil

function HUD.editor:loadPanelFont()

    if self.panelFont and isElement(self.panelFont) then
        destroyElement(self.panelFont)
        self.panelFont = nil
    end

    local path = self.panelText and self.panelText.fontPath
    local size = self.panelText and self.panelText.fontBaseSize or 14

    if path and fileExists(path) then
        self.panelFont = dxCreateFont(path, size, false, "antialiased")
    end

    return self.panelFont or "default-bold"

end

function HUD.editor:getPanelFont()

    if self.panelFont and isElement(self.panelFont) then
        return self.panelFont
    end

    return "default-bold"

end

function HUD.editor:getPanelTextScale(group)

    local globalScale = ((self.panelText and self.panelText.textSize) or 100) / 100
    local groupScale = 1

    if group == "component" then
        groupScale = ((self.panelText and self.panelText.componentTextSize) or 100) / 100
    elseif group == "selector" then
        groupScale = ((self.panelText and self.panelText.selectorTextSize) or 100) / 100
    end

    return globalScale * groupScale

end

function HUD.editor:loadTextures()

    -- Avoid recreating textures on every F5/open.
    if self.textures.panel and isElement(self.textures.panel) then
        return true
    end

    for key,path in pairs(self.texturePaths) do

        if fileExists(path) then
            self.textures[key] = dxCreateTexture(path, "argb", true, "clamp")
        else
            self.textures[key] = nil
            outputDebugString("[SC HUD] Missing UI image: "..tostring(path), 2)
        end

    end

    self:loadPanelFont()

    return self.textures.panel and isElement(self.textures.panel)

end

function HUD.editor:destroyTextures()

    for key,texture in pairs(self.textures) do

        if isElement(texture) then
            destroyElement(texture)
        end

        self.textures[key] = nil

    end

    if self.panelFont and isElement(self.panelFont) then
        destroyElement(self.panelFont)
    end

    self.panelFont = nil

end

local function drawUIImage(texture, x, y, w, h, fallbackColor)

    if texture and isElement(texture) then
        dxDrawImage(x, y, w, h, texture)
        return
    end

    -- Makes missing files obvious instead of rendering nothing.
    dxDrawRectangle(
        x,
        y,
        w,
        h,
        fallbackColor or tocolor(35, 40, 55, 230)
    )

end


-- ============================================================
-- PANEL TEXT SETTINGS
-- textSize = 100  -> normal size
-- textSize = 150  -> 50% larger
-- textSize = 75   -> 25% smaller
--
-- Put your custom panel font here:
-- assets/fonts/panel.ttf
-- If the file is missing, MTA falls back to default-bold.
-- ============================================================

HUD.editor.panelText = {
    fontPath = "assets/fonts/panel.ttf",
    fontBaseSize = 14,

    -- Global size for all dynamic panel text.
    textSize = 100,

    -- Optional extra size per group.
    componentTextSize = 80,
    selectorTextSize = 75
}

HUD.editor.items = {
    {name="Ping",   key="ping"},
    {name="Clock",  key="clock"},
    {name="Health", key="health"},
    {name="Armor",  key="armor"},
    {name="Money",  key="money"},
    {name="Player", key="player"},
    {name="Date",   key="date"},
    {name="Wanted", key="wanted"}
}

HUD.editor.themeColors = {
    {name="Default", key="default", textureKey="themeDefault"},
    {name="Sky",     key="sky",     textureKey="themeSky"},
    {name="Yallow",  key="yallow",  textureKey="themeYallow"},
    {name="Green",   key="green",   textureKey="themeGreen"},
    {name="Red",     key="red",     textureKey="themeRed"},
    {name="Pink",    key="pink",    textureKey="themePink"},
    {name="Purple",  key="purple",  textureKey="themePurple"}
}

-- Font 4 intentionally removed from the editor UI.
HUD.editor.fonts = {
    {name="Default", key="default"},
    {name="Style 1", key="font1"},
    {name="Style 2", key="font2"},
    {name="Style 3", key="font3"}
}

HUD.editor.textSizes = {
    {name="Small", key="small"},
    {name="Medium", key="medium"},
    {name="Large", key="large"}
}

HUD.editor.opacityOptions = {
    {name="Low", value=100},
    {name="Medium", value=180},
    {name="High", value=240}
}

HUD.editor.radiusOptions = {
    {name="Sharp", value=4},
    {name="Medium", value=12},
    {name="Round", value=20}
}

-- All visual coordinates are centralized here.
-- Click handling reads these exact same values.
HUD.editor.layout = {
    close = {
        x = HUD.editor.ui.close.x,
        y = HUD.editor.ui.close.y,
        w = HUD.editor.ui.close.baseWidth,
        h = HUD.editor.ui.close.baseHeight
    },

    components = {
        startX = HUD.editor.ui.components.startX,
        startY = HUD.editor.ui.components.startY,
        w = HUD.editor.ui.components.boxBaseWidth,
        h = HUD.editor.ui.components.boxBaseHeight,
        gapX = HUD.editor.ui.components.gapX,
        gapY = HUD.editor.ui.components.gapY,
        toggleW = HUD.editor.ui.components.toggleBaseWidth,
        toggleH = HUD.editor.ui.components.toggleBaseHeight,
        toggleRight = 0
    },

    theme = {
        x = HUD.editor.ui.theme.startX,
        y = HUD.editor.ui.theme.y,
        size = HUD.editor.ui.theme.baseWidth,
        gap = HUD.editor.ui.theme.gap
    },

    font = {
        x = HUD.editor.textUI.font.x,
        y = HUD.editor.textUI.font.y,
        w = HUD.editor.textUI.font.width,
        h = HUD.editor.textUI.font.height,
        gap = HUD.editor.textUI.font.gap
    },

    opacity = {
        x = HUD.editor.textUI.opacity.x,
        y = HUD.editor.textUI.opacity.y,
        w = HUD.editor.textUI.opacity.width,
        h = HUD.editor.textUI.opacity.height,
        gap = HUD.editor.textUI.opacity.gap
    },

    size = {
        x = HUD.editor.textUI.size.x,
        y = HUD.editor.textUI.size.y,
        w = HUD.editor.textUI.size.width,
        h = HUD.editor.textUI.size.height,
        gap = HUD.editor.textUI.size.gap
    },

    radius = {
        x = HUD.editor.textUI.radius.x,
        y = HUD.editor.textUI.radius.y,
        w = HUD.editor.textUI.radius.width,
        h = HUD.editor.textUI.radius.height,
        gap = HUD.editor.textUI.radius.gap
    },

    save = {
        x = HUD.editor.ui.buttons.save.x,
        y = HUD.editor.ui.buttons.save.y,
        w = HUD.editor.ui.buttons.save.baseWidth,
        h = HUD.editor.ui.buttons.save.baseHeight
    },

    edit = {
        x = HUD.editor.ui.buttons.editPosition.x,
        y = HUD.editor.ui.buttons.editPosition.y,
        w = HUD.editor.ui.buttons.editPosition.baseWidth,
        h = HUD.editor.ui.buttons.editPosition.baseHeight
    },

    reset = {
        x = HUD.editor.ui.buttons.reset.x,
        y = HUD.editor.ui.buttons.reset.y,
        w = HUD.editor.ui.buttons.reset.baseWidth,
        h = HUD.editor.ui.buttons.reset.baseHeight
    }
}

local function inside(px, py, r, ox, oy)
    return px >= ox+r.x and px <= ox+r.x+r.w
       and py >= oy+r.y and py <= oy+r.y+r.h
end

local function selectedTextColor(selected)
    if selected then
        return tocolor(235, 105, 245, 255)
    end
    return tocolor(235, 235, 235, 235)
end

function HUD.editor:setIconColor(color)
    if HUD.theme and HUD.theme.icon then
        HUD.theme.icon.currentColor = color
    end
    if HUD.assets then
        HUD.assets.currentColor = color
    end
end

function HUD.editor:setTextSize(size)
    if size ~= "small" and size ~= "medium" and size ~= "large" then
        return
    end
    if HUD.theme then
        HUD.theme.currentTextSize = size
    end
    if HUD.setLayout then
        HUD:setLayout(size)
    end
end

function HUD.editor:setFont(font)
    if HUD.theme then
        HUD.theme.currentFont = font
    end
end

function HUD.editor:setOpacity(value)
    if HUD.theme and HUD.theme.background then
        HUD.theme.background.opacity = value
    end
end

function HUD.editor:setRadius(value)
    if HUD.theme then
        HUD.theme.borderRadius = value
    end
end

function HUD.editor:toggle()

    self.open = not self.open

    if self.open then
        self:loadTextures()
        self:loadPanelFont()
    end

    showCursor(self.open)

end

function HUD.editor:getState(key)
    if HUD.settings and HUD.settings.visible and HUD.settings.visible[key] ~= nil then
        return HUD.settings.visible[key]
    end
    return true
end

function HUD.editor:render()
    if not self.open then return end

    local x, y = self.x, self.y
    local L = self.layout

    local panelFont = self:getPanelFont()
    local componentTextScale = self:getPanelTextScale("component")
    local selectorTextScale = self:getPanelTextScale("selector")

    local panelW, panelH = scaledSize(self.ui.panel.baseWidth, self.ui.panel.baseHeight, self.ui.panel.size)
    local closeW, closeH = scaledSize(self.ui.close.baseWidth, self.ui.close.baseHeight, self.ui.close.size)
    local boxW, boxH = scaledSize(self.ui.components.boxBaseWidth, self.ui.components.boxBaseHeight, self.ui.components.boxSize)
    local toggleW, toggleH = scaledSize(self.ui.components.toggleBaseWidth, self.ui.components.toggleBaseHeight, self.ui.components.toggleSize)
    local themeW, themeH = scaledSize(self.ui.theme.baseWidth, self.ui.theme.baseHeight, self.ui.theme.size)
    local saveW, saveH = scaledSize(self.ui.buttons.save.baseWidth, self.ui.buttons.save.baseHeight, self.ui.buttons.save.size)
    local editW, editH = scaledSize(self.ui.buttons.editPosition.baseWidth, self.ui.buttons.editPosition.baseHeight, self.ui.buttons.editPosition.size)
    local resetW, resetH = scaledSize(self.ui.buttons.reset.baseWidth, self.ui.buttons.reset.baseHeight, self.ui.buttons.reset.size)

    -- Complete background artwork.
    drawUIImage(self.textures.panel, x + self.ui.panel.x, y + self.ui.panel.y, panelW, panelH, tocolor(15,18,25,245))

    -- Close image.
    drawUIImage(self.textures.close, x+self.ui.close.x, y+self.ui.close.y, closeW, closeH, tocolor(180,60,80,230))

    -- HUD component cards.
    local C = L.components
    for i,item in ipairs(self.items) do
        local col = (i-1) % 4
        local row = math.floor((i-1) / 4)
        local bx = x + self.ui.components.startX + col*(boxW+self.ui.components.gapX)
        local by = y + self.ui.components.startY + row*(boxH+self.ui.components.gapY)

        drawUIImage(self.textures.component, bx, by, boxW, boxH, tocolor(35,40,55,230))

        dxDrawText(
            item.name,
            bx+15, by,
            bx+boxW-toggleW-24, by+boxH,
            tocolor(245,245,245,255),
            componentTextScale, panelFont, "left", "center"
        )

        local tx = bx + self.ui.components.toggleOffsetX
        local ty = by + self.ui.components.toggleOffsetY
        local toggleTexture = self:getState(item.key)
            and self.textures.toggleOn
            or self.textures.toggleOff

        drawUIImage(toggleTexture, tx, ty, toggleW, toggleH, tocolor(75,75,85,230))
    end

    -- Theme image selectors.
    local selectedColor = "default"
    if HUD.theme and HUD.theme.icon and HUD.theme.icon.currentColor then
        selectedColor = HUD.theme.icon.currentColor
    elseif HUD.assets and HUD.assets.currentColor then
        selectedColor = HUD.assets.currentColor
    end

    local themeX = x + L.theme.x
    for _,c in ipairs(self.themeColors) do
        local szW, szH = themeW, themeH
        if selectedColor == c.key then
            dxDrawRectangle(themeX-3, y+L.theme.y-3, szW+6, szH+6, tocolor(235,105,245,210))
        end
        drawUIImage(self.textures[c.textureKey], themeX, y+L.theme.y, szW, szH, tocolor(80,80,90,230))
        themeX = themeX + szW + L.theme.gap
    end

    -- Text-only selectors: no button rectangles.
    local selectedFont = (HUD.theme and HUD.theme.currentFont) or "default"
    local fx = x + L.font.x
    for _,f in ipairs(self.fonts) do
        dxDrawText(f.name, fx, y+L.font.y, fx+L.font.w, y+L.font.y+L.font.h,
            selectedTextColor(selectedFont == f.key), selectorTextScale, panelFont, "center", "center")
        fx = fx + L.font.w + L.font.gap
    end

    local currentOpacity = (HUD.theme and HUD.theme.background and HUD.theme.background.opacity) or 180
    local ox = x + L.opacity.x
    for _,option in ipairs(self.opacityOptions) do
        dxDrawText(option.name, ox, y+L.opacity.y, ox+L.opacity.w, y+L.opacity.y+L.opacity.h,
            selectedTextColor(currentOpacity == option.value), selectorTextScale, panelFont, "center", "center")
        ox = ox + L.opacity.w + L.opacity.gap
    end

    local selectedSize = (HUD.theme and HUD.theme.currentTextSize) or "small"
    local sx = x + L.size.x
    for _,s in ipairs(self.textSizes) do
        dxDrawText(s.name, sx, y+L.size.y, sx+L.size.w, y+L.size.y+L.size.h,
            selectedTextColor(selectedSize == s.key), selectorTextScale, panelFont, "center", "center")
        sx = sx + L.size.w + L.size.gap
    end

    local currentRadius = (HUD.theme and HUD.theme.borderRadius) or 12
    local rx = x + L.radius.x
    for _,option in ipairs(self.radiusOptions) do
        dxDrawText(option.name, rx, y+L.radius.y, rx+L.radius.w, y+L.radius.y+L.radius.h,
            selectedTextColor(currentRadius == option.value), selectorTextScale, panelFont, "center", "center")
        rx = rx + L.radius.w + L.radius.gap
    end

    -- Bottom image buttons.
    drawUIImage(self.textures.save, x+self.ui.buttons.save.x, y+self.ui.buttons.save.y, saveW, saveH, tocolor(0,170,90,230))
    local editTexture = self.positionMode
        and self.textures.savePosition
        or self.textures.edit

    drawUIImage(
        editTexture,
        x+self.ui.buttons.editPosition.x,
        y+self.ui.buttons.editPosition.y,
        editW,
        editH,
        tocolor(70,100,200,230)
    )
    drawUIImage(self.textures.reset, x+self.ui.buttons.reset.x, y+self.ui.buttons.reset.y, resetW, resetH, tocolor(180,70,70,230))
end

addEventHandler("onClientKey", root,
function(button, press)
    if button == "F5" and press then
        HUD.editor:toggle()
    end
end)

addEventHandler("onClientClick", root,
function(button, state, cx, cy)
    if button ~= "left" or state ~= "down" or not HUD.editor.open then
        return
    end

    local x, y = HUD.editor.x, HUD.editor.y
    local L = HUD.editor.layout

    local closeW, closeH = scaledSize(HUD.editor.ui.close.baseWidth, HUD.editor.ui.close.baseHeight, HUD.editor.ui.close.size)
    local boxW, boxH = scaledSize(HUD.editor.ui.components.boxBaseWidth, HUD.editor.ui.components.boxBaseHeight, HUD.editor.ui.components.boxSize)
    local toggleW, toggleH = scaledSize(HUD.editor.ui.components.toggleBaseWidth, HUD.editor.ui.components.toggleBaseHeight, HUD.editor.ui.components.toggleSize)
    local themeW, themeH = scaledSize(HUD.editor.ui.theme.baseWidth, HUD.editor.ui.theme.baseHeight, HUD.editor.ui.theme.size)
    local saveW, saveH = scaledSize(HUD.editor.ui.buttons.save.baseWidth, HUD.editor.ui.buttons.save.baseHeight, HUD.editor.ui.buttons.save.size)
    local editW, editH = scaledSize(HUD.editor.ui.buttons.editPosition.baseWidth, HUD.editor.ui.buttons.editPosition.baseHeight, HUD.editor.ui.buttons.editPosition.size)
    local resetW, resetH = scaledSize(HUD.editor.ui.buttons.reset.baseWidth, HUD.editor.ui.buttons.reset.baseHeight, HUD.editor.ui.buttons.reset.size)

    -- Close: exact image hitbox.
    if cx >= x+HUD.editor.ui.close.x and cx <= x+HUD.editor.ui.close.x+closeW
    and cy >= y+HUD.editor.ui.close.y and cy <= y+HUD.editor.ui.close.y+closeH then
        HUD.editor:toggle()
        return
    end

    -- Bottom actions: exact image hitboxes.
    if cx >= x+HUD.editor.ui.buttons.editPosition.x and cx <= x+HUD.editor.ui.buttons.editPosition.x+editW
    and cy >= y+HUD.editor.ui.buttons.editPosition.y and cy <= y+HUD.editor.ui.buttons.editPosition.y+editH then
        HUD.editor.positionMode = not HUD.editor.positionMode
        if HUD.positionEditor then
            HUD.positionEditor.active = HUD.editor.positionMode
            HUD.positionEditor.dragging = false
        end
        return
    end

    if cx >= x+HUD.editor.ui.buttons.reset.x and cx <= x+HUD.editor.ui.buttons.reset.x+resetW
    and cy >= y+HUD.editor.ui.buttons.reset.y and cy <= y+HUD.editor.ui.buttons.reset.y+resetH then
        if HUD.positionEditor and HUD.positionEditor.reset then
            HUD.positionEditor:reset()
        end
        return
    end

    if cx >= x+HUD.editor.ui.buttons.save.x and cx <= x+HUD.editor.ui.buttons.save.x+saveW
    and cy >= y+HUD.editor.ui.buttons.save.y and cy <= y+HUD.editor.ui.buttons.save.y+saveH then
        if HUD.storage then
            HUD.storage:save()
        end
        return
    end

    -- Theme image hitboxes.
    if cy >= y+L.theme.y and cy <= y+L.theme.y+themeH then
        local tx = x + L.theme.x
        for _,c in ipairs(HUD.editor.themeColors) do
            if cx >= tx and cx <= tx+themeW then
                HUD.editor:setIconColor(c.key)
                return
            end
            tx = tx + themeW + L.theme.gap
        end
    end

    -- Font text hitboxes.
    if cy >= y+L.font.y and cy <= y+L.font.y+L.font.h then
        local fx = x + L.font.x
        for _,f in ipairs(HUD.editor.fonts) do
            if cx >= fx and cx <= fx+L.font.w then
                HUD.editor:setFont(f.key)
                return
            end
            fx = fx + L.font.w + L.font.gap
        end
    end

    -- Size text hitboxes.
    if cy >= y+L.size.y and cy <= y+L.size.y+L.size.h then
        local sx = x + L.size.x
        for _,s in ipairs(HUD.editor.textSizes) do
            if cx >= sx and cx <= sx+L.size.w then
                HUD.editor:setTextSize(s.key)
                return
            end
            sx = sx + L.size.w + L.size.gap
        end
    end

    -- Opacity text hitboxes.
    if cy >= y+L.opacity.y and cy <= y+L.opacity.y+L.opacity.h then
        local ox = x + L.opacity.x
        for _,option in ipairs(HUD.editor.opacityOptions) do
            if cx >= ox and cx <= ox+L.opacity.w then
                HUD.editor:setOpacity(option.value)
                return
            end
            ox = ox + L.opacity.w + L.opacity.gap
        end
    end

    -- Angle / border-radius text hitboxes.
    if cy >= y+L.radius.y and cy <= y+L.radius.y+L.radius.h then
        local rx = x + L.radius.x
        for _,option in ipairs(HUD.editor.radiusOptions) do
            if cx >= rx and cx <= rx+L.radius.w then
                HUD.editor:setRadius(option.value)
                return
            end
            rx = rx + L.radius.w + L.radius.gap
        end
    end

    if HUD.editor.positionMode then
        return
    end

    -- Component toggles: only the switch image is clickable, not the whole card.
    local C = L.components
    for i,item in ipairs(HUD.editor.items) do
        local col = (i-1) % 4
        local row = math.floor((i-1) / 4)
        local bx = x + HUD.editor.ui.components.startX + col*(boxW+HUD.editor.ui.components.gapX)
        local by = y + HUD.editor.ui.components.startY + row*(boxH+HUD.editor.ui.components.gapY)
        local tx = bx + HUD.editor.ui.components.toggleOffsetX
        local ty = by + HUD.editor.ui.components.toggleOffsetY

        if cx >= tx and cx <= tx+toggleW and cy >= ty and cy <= ty+toggleH then
            if HUD.settings and HUD.settings.visible then
                HUD.settings.visible[item.key] = not HUD.settings.visible[item.key]
            end
            return
        end
    end
end)

addEventHandler("onClientRender", root,
function()
    HUD.editor:render()
end)


addEventHandler("onClientResourceStart", resourceRoot,
function()
    HUD.editor:loadTextures()
end)

addEventHandler("onClientResourceStop", resourceRoot,
function()
    HUD.editor:destroyTextures()
end)
