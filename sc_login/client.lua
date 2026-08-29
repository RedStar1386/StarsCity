-- =========================================================
-- STARS CITY - LOGIN / REGISTER UI
-- sc_login/client.lua
-- =========================================================

local screenW, screenH = guiGetScreenSize()

local BASE_W, BASE_H = 1920, 1080
local scale = math.min(screenW / BASE_W, screenH / BASE_H)
local offsetX = (screenW - BASE_W * scale) / 2
local offsetY = (screenH - BASE_H * scale) / 2

local function X(value)
    return offsetX + value * scale
end

local function Y(value)
    return offsetY + value * scale
end

local function S(value)
    return value * scale
end


-- =========================================================
-- CONFIG
-- =========================================================

local SPLASH_TIME = 4000

local BACKGROUND_FILE = "assets/background.png"
local MUSIC_FILE = "assets/login_music.mp3"


-- =========================================================
-- FONT FILES
-- =========================================================

local FONT_LOGO        = "assets/fonts/logo.ttf"
local FONT_TITLE       = "assets/fonts/title.ttf"
local FONT_NORMAL      = "assets/fonts/normal.ttf"
local FONT_BUTTON      = "assets/fonts/button.ttf"

local FONT_INPUT_LABEL = "assets/fonts/input_label.ttf"
local FONT_INPUT_TEXT  = "assets/fonts/input_text.ttf"

local FONT_TAB_TEXT    = "assets/fonts/button.ttf"

local FONT_STATUS      = "assets/fonts/normal.ttf"
local FONT_SUBTITLE    = "assets/fonts/subtitle.ttf"
local FONT_FOOTER      = "assets/fonts/footer.ttf"


-- =========================================================
-- FONT SIZES
-- =========================================================

local SIZE_LOGO        = 2.0
local SIZE_TITLE       = 0.9
local SIZE_RIGHT_SIDE  = 0.7

local SIZE_TAB_TEXT    = 0.5
local SIZE_INPUT_TEXT  = 0.7
local SIZE_BUTTON      = 0.9

local SIZE_STATUS      = 0.5
local SIZE_NORMAL      = 0.6
local SIZE_SUBTITLE    = 1.0
local SIZE_FOOTER      = 0.7


-- =========================================================
-- TEXT COLORS
-- =========================================================

local COLOR_LOGO = {255, 255, 255}

local COLOR_TITLE = {245, 245, 248}

local COLOR_NORMAL = {215, 215, 225}

local COLOR_BUTTON = {255, 255, 255}

local COLOR_INPUT_LABEL = {170, 170, 180}

local COLOR_INPUT_TEXT = {245, 245, 248}

local COLOR_INPUT_PLACEHOLDER = {115, 116, 130}

local COLOR_TAB_SELECTED = {255, 255, 255}

local COLOR_TAB_UNSELECTED = {170, 170, 180}

local COLOR_STATUS = {190, 190, 205}

local COLOR_SUBTITLE = {220, 20, 60}

local COLOR_FOOTER = {125, 126, 140}


-- =========================================================
-- SPECIAL TEXT COLORS
-- =========================================================

local COLOR_STATUS_SUCCESS = {80, 220, 130}
local COLOR_STATUS_ERROR   = {255, 90, 105}

local COLOR_SPLASH_SUBTITLE = {245, 245, 245}

local COLOR_RIGHT_TITLE = {255, 255, 255}

local COLOR_RIGHT_NORMAL = {215, 215, 225}


-- =========================================================
-- INPUT ICON FILES
-- =========================================================

local INPUT_ICON_FILES = {

    user = "assets/icons/user.png",

    password = "assets/icons/password.png",

    phone = "assets/icons/phone.png"
}


-- =========================================================
-- INPUT ICON SETTINGS
-- =========================================================

local INPUT_ICON_SIZE = {

    user = 35,
    password = 35,
    phone = 35
}


local INPUT_ICON_X = 18

local INPUT_ICON_TEXT_GAP = 20


-- =========================================================
-- INPUT ICON COLORS
-- =========================================================

local COLOR_INPUT_ICON = {

    user = {170, 170, 180},

    password = {170, 170, 180},

    phone = {170, 170, 180}
}


-- =========================================================
-- OTHER ICON FILES
-- =========================================================

local ICON_FILES = {

    register = "assets/icons/register.png",

    login = "assets/icons/login.png",

    serial = "assets/icons/serial.png",

    male = "assets/icons/male.png",

    female = "assets/icons/female.png",

    speaker = "assets/icons/speaker.png",

    mute = "assets/icons/mute.png"
}


-- =========================================================
-- MUSIC ICON SETTINGS
-- =========================================================

local MUSIC_ICON_SIZE = 38

local MUSIC_ICON_X = 290

local MUSIC_ICON_Y = 900

local MUSIC_ICON_COLOR = {220, 220, 230}

local MUSIC_ICON_HOVER_COLOR = {255, 255, 255}

local MUSIC_ICON_ALPHA = 220


-- =========================================================
-- PRIVATE PRE-LOGIN CAMERA
-- =========================================================

local PRELOGIN_CAMERA = {

    x = 0.0,
    y = -4.5,
    z = 1003.0,

    lookX = 0.0,
    lookY = 0.0,
    lookZ = 1000.0
}


-- =========================================================
-- HUD COMPONENTS
-- =========================================================

local HUD_COMPONENTS = {

    "ammo",
    "area_name",
    "armour",
    "breath",
    "clock",
    "health",
    "money",
    "radar",
    "vehicle_name",
    "weapon",
    "radio",
    "wanted",
    "crosshair",
    "radar_names",
    "radio_wheel"
}


-- =========================================================
-- STATE
-- =========================================================

local loginVisible = false
local splashVisible = false

local splashStartedAt = 0

local currentTab = "login"

local statusText = ""
local statusType = "info"
local statusUntil = 0

local loginBusy = false

local sound = nil

local activeEdit = nil
local edits = {}

local backgroundTexture = nil

local fontTextures = {}

local iconTextures = {}

local inputIconTextures = {}


-- =========================================================
-- AUTO-FILL STATE
-- =========================================================

local autoFillAvailable = false
local autoFillChecking = false
local autoFillUsername = ""


-- =========================================================
-- MUSIC STATE
-- =========================================================

local musicMuted = false


-- =========================================================
-- DRAW HELPERS
-- =========================================================

local function rgba(c, a)

    return tocolor(
        c[1],
        c[2],
        c[3],
        a or 255
    )
end


local function isMouseIn(x, y, w, h)

    if not isCursorShowing() then
        return false
    end

    local mx, my = getCursorPosition()

    if not mx or not my then
        return false
    end

    mx = mx * screenW
    my = my * screenH

    return mx >= X(x)
       and mx <= X(x + w)
       and my >= Y(y)
       and my <= Y(y + h)
end


-- =========================================================
-- ROUNDED BOX
-- =========================================================

local function drawRoundedBox(x, y, w, h, color, radius)

    radius = math.min(
        radius or 12,
        math.min(w, h) / 2
    )

    dxDrawRectangle(
        X(x + radius),
        Y(y),
        S(w - radius * 2),
        S(h),
        color
    )

    dxDrawRectangle(
        X(x),
        Y(y + radius),
        S(w),
        S(h - radius * 2),
        color
    )

    dxDrawCircle(
        X(x + radius),
        Y(y + radius),
        S(radius),
        180,
        270,
        color,
        color,
        12
    )

    dxDrawCircle(
        X(x + w - radius),
        Y(y + radius),
        S(radius),
        270,
        360,
        color,
        color,
        12
    )

    dxDrawCircle(
        X(x + radius),
        Y(y + h - radius),
        S(radius),
        90,
        180,
        color,
        color,
        12
    )

    dxDrawCircle(
        X(x + w - radius),
        Y(y + h - radius),
        S(radius),
        0,
        90,
        color,
        color,
        12
    )
end


-- =========================================================
-- GRADIENT BACKGROUND
-- =========================================================

local function drawGradientBackground()

    local steps = 36
    local stepH = BASE_H / steps

    for i = 0, steps - 1 do

        local t = i / (steps - 1)

        local r, g, b

        if t < 0.48 then

            local p = t / 0.48

            r = 220 * (1 - p) + 255 * p
            g = 20 * (1 - p) + 45 * p
            b = 60 * (1 - p) + 120 * p

        else

            local p = (t - 0.48) / 0.52

            r = 255 * (1 - p) + 8 * p
            g = 45 * (1 - p) + 8 * p
            b = 120 * (1 - p) + 13 * p

        end

        dxDrawRectangle(
            X(0),
            Y(i * stepH),
            S(BASE_W),
            S(stepH + 2),
            tocolor(r, g, b, 255)
        )
    end
end


-- =========================================================
-- BACKGROUND
-- =========================================================

local function drawBackground()

    if backgroundTexture then

        dxDrawImage(
            0,
            0,
            screenW,
            screenH,
            backgroundTexture,
            0,
            0,
            0,
            tocolor(255, 255, 255, 255)
        )

    else

        drawGradientBackground()

    end
end


-- =========================================================
-- GENERIC TEXT
-- =========================================================

local function drawText(
    text,
    x,
    y,
    w,
    h,
    color,
    scaleValue,
    font,
    ax,
    ay
)

    dxDrawText(
        text,
        X(x),
        Y(y),
        X(x + w),
        Y(y + h),
        color,
        S(scaleValue or 1),
        font or "default",
        ax or "left",
        ay or "center",
        false,
        false,
        false,
        true
    )
end


-- =========================================================
-- GUI EDITS
-- =========================================================

local function createHiddenEdit(name, masked)

    local edit = guiCreateEdit(
        -1000,
        -1000,
        1,
        1,
        "",
        false
    )

    guiSetAlpha(edit, 0)

    guiSetVisible(edit, true)

    if masked then

        guiEditSetMasked(
            edit,
            true
        )

    end

    edits[name] = edit

    return edit
end


local function destroyEdits()

    for _, edit in pairs(edits) do

        if isElement(edit) then
            destroyElement(edit)
        end

    end

    edits = {}

    activeEdit = nil
end


local function clearActiveEdit()

    activeEdit = nil

    guiSetInputEnabled(false)

    guiSetInputMode(
        "allow_binds"
    )
end


local function focusEdit(edit)

    if not isElement(edit) then
        return
    end

    activeEdit = edit

    guiSetInputEnabled(true)

    guiSetInputMode(
        "no_binds_when_editing"
    )

    guiBringToFront(edit)

    guiFocus(edit)

    guiEditSetCaretIndex(
        edit,
        #guiGetText(edit)
    )
end


local function getEditText(name)

    local edit = edits[name]

    if not edit
    or not isElement(edit) then

        return ""

    end

    return guiGetText(edit) or ""
end


local function setEditText(name, value)

    local edit = edits[name]

    if edit
    and isElement(edit) then

        guiSetText(
            edit,
            value or ""
        )

    end
end


local function createEdits()

    destroyEdits()

    createHiddenEdit(
        "loginUsername",
        false
    )

    createHiddenEdit(
        "loginPassword",
        true
    )

    createHiddenEdit(
        "registerUsername",
        false
    )

    createHiddenEdit(
        "registerPassword",
        false
    )

    createHiddenEdit(
        "registerPhone",
        false
    )

    createHiddenEdit(
        "serialUsername",
        false
    )

    createHiddenEdit(
        "serialPassword",
        false
    )

    createHiddenEdit(
        "serialPhone",
        false
    )
end


-- =========================================================
-- GUI INPUT FILTER
-- =========================================================

addEventHandler(
    "onClientGUIChanged",
    root,
    function()

        if source == edits.registerPhone
        or source == edits.serialPhone then

            local text =
                guiGetText(source) or ""

            local clean =
                text:gsub(
                    "[^0-9]",
                    ""
                )

            if clean ~= text then

                guiSetText(
                    source,
                    clean
                )

            end

        elseif source == edits.loginUsername
        or source == edits.registerUsername
        or source == edits.serialUsername then

            local text =
                guiGetText(source) or ""

            local clean =
                text:gsub(
                    "[^A-Za-z0-9_]",
                    ""
                )

            if clean ~= text then

                guiSetText(
                    source,
                    clean
                )

            end
        end
    end
)


-- =========================================================
-- STATUS
-- =========================================================

local function setStatus(text, newStatusType)

    statusText = text or ""

    statusType = newStatusType or "info"

    statusUntil =
        getTickCount() + 6000
end


local function statusColor()

    if statusType == "success" then

        return rgba(
            COLOR_STATUS_SUCCESS
        )

    elseif statusType == "error" then

        return rgba(
            COLOR_STATUS_ERROR
        )

    end

    return rgba(
        COLOR_STATUS
    )
end


-- =========================================================
-- FONT LOADING
-- =========================================================

local function destroyFonts()

    for key, font in pairs(fontTextures) do

        if font
        and isElement(font) then

            destroyElement(font)

        end

        fontTextures[key] = nil
    end
end


local function loadFonts()

    destroyFonts()

    local fontFiles = {

        logo = FONT_LOGO,

        title = FONT_TITLE,

        normal = FONT_NORMAL,

        button = FONT_BUTTON,

        inputLabel = FONT_INPUT_LABEL,

        inputText = FONT_INPUT_TEXT,

        tab = FONT_TAB_TEXT,

        tabText = FONT_TAB_TEXT,

        status = FONT_STATUS,

        subtitle = FONT_SUBTITLE,

        footer = FONT_FOOTER
    }


    for key, path in pairs(fontFiles) do

        if path and fileExists(path) then

            local font = dxCreateFont(
                path,
                24,
                false,
                "antialiased"
            )

            if font then
                fontTextures[key] = font
            end
        end
    end
end


-- =========================================================
-- FONT GETTERS
-- =========================================================

local function getFont(name)

    if fontTextures[name]
    and isElement(fontTextures[name]) then

        return fontTextures[name]

    end

    return "default"
end


-- =========================================================
-- MUSIC / BACKGROUND
-- =========================================================

local function loadAssets()

    if backgroundTexture
    and isElement(backgroundTexture) then

        destroyElement(
            backgroundTexture
        )

    end

    backgroundTexture = nil


    if fileExists(BACKGROUND_FILE) then

        backgroundTexture =
            dxCreateTexture(
                BACKGROUND_FILE,
                "argb",
                true,
                "clamp"
            )

    end


    loadFonts()


    for key, texture in pairs(iconTextures) do

        if texture
        and isElement(texture) then

            destroyElement(texture)

        end

        iconTextures[key] = nil
    end


    for key, path in pairs(ICON_FILES) do

        if fileExists(path) then

            iconTextures[key] =
                dxCreateTexture(
                    path,
                    "argb",
                    true,
                    "clamp"
                )

        end
    end


    for key, texture in pairs(inputIconTextures) do

        if texture
        and isElement(texture) then

            destroyElement(texture)

        end

        inputIconTextures[key] = nil
    end


    for key, path in pairs(INPUT_ICON_FILES) do

        if fileExists(path) then

            inputIconTextures[key] =
                dxCreateTexture(
                    path,
                    "argb",
                    true,
                    "clamp"
                )

        end
    end
end


-- =========================================================
-- START MUSIC
-- =========================================================

local function startMusic()

    if sound
    and isElement(sound) then

        stopSound(sound)

        destroyElement(sound)

        sound = nil

    end


    if musicMuted then
        return
    end


    if fileExists(MUSIC_FILE) then

        sound = playSound(
            MUSIC_FILE,
            true
        )

        if sound then

            setSoundVolume(
                sound,
                0.45
            )

        end
    end
end


-- =========================================================
-- STOP MUSIC
-- =========================================================

local function stopMusic()

    if sound
    and isElement(sound) then

        stopSound(sound)

        destroyElement(sound)

    end

    sound = nil
end


-- =========================================================
-- MUSIC TOGGLE
-- =========================================================

local function toggleMusic()

    if musicMuted then

        musicMuted = false

        startMusic()

    else

        musicMuted = true

        stopMusic()

    end
end


-- =========================================================
-- MUSIC BUTTON
-- =========================================================

local function drawMusicButton()

    local iconKey =
        musicMuted
        and "mute"
        or "speaker"


    local icon =
        iconTextures[iconKey]


    if not icon
    or not isElement(icon) then

        return
    end


    local hovered =
        isMouseIn(
            MUSIC_ICON_X,
            MUSIC_ICON_Y,
            MUSIC_ICON_SIZE,
            MUSIC_ICON_SIZE
        )


    local color =
        hovered
        and MUSIC_ICON_HOVER_COLOR
        or MUSIC_ICON_COLOR


    local alpha =
        hovered
        and 255
        or MUSIC_ICON_ALPHA


    dxDrawImage(

        X(MUSIC_ICON_X),
        Y(MUSIC_ICON_Y),

        S(MUSIC_ICON_SIZE),
        S(MUSIC_ICON_SIZE),

        icon,

        0,
        0,
        0,

        tocolor(
            color[1],
            color[2],
            color[3],
            alpha
        ),

        true
    )
end


-- =========================================================
-- PRE-LOGIN CLIENT LOCK
-- =========================================================

local function hideGameHud()

    for _, component in ipairs(HUD_COMPONENTS) do

        setPlayerHudComponentVisible(
            component,
            false
        )

    end
end


local function showGameHud()

    for _, component in ipairs(HUD_COMPONENTS) do

        setPlayerHudComponentVisible(
            component,
            true
        )

    end
end


local function lockClientWorld()

    toggleAllControls(
        false,
        true,
        false
    )

    setCameraMatrix(
        PRELOGIN_CAMERA.x,
        PRELOGIN_CAMERA.y,
        PRELOGIN_CAMERA.z,
        PRELOGIN_CAMERA.lookX,
        PRELOGIN_CAMERA.lookY,
        PRELOGIN_CAMERA.lookZ
    )

    hideGameHud()

    showChat(false)
end


local function restoreClientWorld()

    toggleAllControls(
        true,
        true,
        false
    )

    showGameHud()

    fadeCamera(
        true,
        0
    )

    setCameraTarget(
        localPlayer
    )

    showChat(true)
end


-- =========================================================
-- SPLASH
-- =========================================================

local function openSplash()

    if getElementData(
        localPlayer,
        "account:loggedIn"
    ) then

        return
    end


    lockClientWorld()

    loginVisible = false

    splashVisible = true

    splashStartedAt =
        getTickCount()

    currentTab = "login"

    loginBusy = false

    autoFillAvailable = false
    autoFillChecking = true
    autoFillUsername = ""

    createEdits()

    loadAssets()

    showCursor(false)

    showChat(false)

    guiSetInputEnabled(false)

    guiSetInputMode(
        "allow_binds"
    )


    -- Ask the server whether this system serial
    -- already belongs to an account.
    --
    -- IMPORTANT:
    -- This is ONLY for filling the username field.
    -- It does NOT authenticate or log the player in.

    triggerServerEvent(
        "scAccounts:autoLoginRequest",
        localPlayer
    )
end


local function closeLogin()

    loginVisible = false

    splashVisible = false

    loginBusy = false

    autoFillAvailable = false
    autoFillChecking = false
    autoFillUsername = ""

    clearActiveEdit()

    destroyEdits()

    stopMusic()


    if backgroundTexture
    and isElement(backgroundTexture) then

        destroyElement(
            backgroundTexture
        )

    end

    backgroundTexture = nil

    destroyFonts()


    for key, texture in pairs(iconTextures) do

        if texture
        and isElement(texture) then

            destroyElement(texture)

        end

        iconTextures[key] = nil
    end


    for key, texture in pairs(inputIconTextures) do

        if texture
        and isElement(texture) then

            destroyElement(texture)

        end

        inputIconTextures[key] = nil
    end


    showCursor(false)

    restoreClientWorld()

    guiSetInputEnabled(false)

    guiSetInputMode(
        "allow_binds"
    )
end


local function openLoginScreen()

    splashVisible = false

    loginVisible = true

    currentTab = "login"

    loginBusy = false

    setStatus(
        "Please enter your username and password.",
        "info"
    )

    startMusic()

    showCursor(true)

    showChat(false)

    guiSetInputEnabled(false)

    guiSetInputMode(
        "allow_binds"
    )
end


-- =========================================================
-- SPLASH DRAW
-- =========================================================

local function drawSplash()

    local elapsed =
        getTickCount() - splashStartedAt

    local progress =
        math.min(
            elapsed / SPLASH_TIME,
            1
        )


    drawGradientBackground()


    dxDrawRectangle(
        0,
        0,
        screenW,
        screenH,
        tocolor(
            0,
            0,
            0,
            55
        )
    )


    local fadeIn =
        math.min(
            elapsed / 650,
            1
        )


    local fadeOut =
        progress > 0.80
        and math.max(
            0,
            (1 - progress) / 0.20
        )
        or 1


    local alpha =
        255 * math.min(
            fadeIn,
            fadeOut
        )


    -- =====================================================
    -- LOGO GLOW
    -- =====================================================

    for radius = 10, 1, -2 do

        local glowAlpha =
            alpha * (0.012 * radius)


        drawText(
            "StarsCity",

            0 - radius,
            425 - radius,

            BASE_W + radius * 2,
            150 + radius * 2,

            tocolor(
                220,
                20,
                60,
                glowAlpha
            ),

            SIZE_LOGO + radius * 0.025,

            getFont("logo"),

            "center",
            "center"
        )
    end


    -- =====================================================
    -- LOGO
    -- =====================================================

    drawText(
        "StarsCity",

        0,
        430,

        BASE_W,
        140,

        tocolor(
            COLOR_LOGO[1],
            COLOR_LOGO[2],
            COLOR_LOGO[3],
            alpha
        ),

        SIZE_LOGO,

        getFont("logo"),

        "center",
        "center"
    )


    -- =====================================================
    -- SPLASH TITLE
    -- =====================================================

    drawText(
        "WELCOME TO STARS CITY",

        0,
        570,

        BASE_W,
        40,

        tocolor(
            COLOR_SPLASH_SUBTITLE[1],
            COLOR_SPLASH_SUBTITLE[2],
            COLOR_SPLASH_SUBTITLE[3],
            alpha * 0.78
        ),

        SIZE_SUBTITLE,

        getFont("subtitle"),

        "center",
        "center"
    )


    if progress >= 1 then

        openLoginScreen()

    end
end


-- =========================================================
-- TAB SETTINGS
-- =========================================================

local TAB_WIDTH = 220
local TAB_HEIGHT = 65

local TAB_GAP = 15

local TAB_ICON_BOX_SIZE = 30

local TAB_ICON_SIZE = 50

local TAB_ICON_X = 21

local TAB_ICON_TEXT_GAP = 10

local COLOR_TAB_ICON_SELECTED = {255, 255, 255, 38}
local COLOR_TAB_ICON_UNSELECTED = {255, 255, 255, 38}

local COLOR_TAB_ICON_SELECTED_IMAGE = {255, 255, 255, 255}
local COLOR_TAB_ICON_UNSELECTED_IMAGE = {190, 190, 200, 235}


-- =========================================================
-- TAB
-- =========================================================

local function drawTab(
    x,
    label,
    iconKey,
    selected
)

    local color =
        selected
        and tocolor(
            220,
            20,
            60,
            245
        )
        or tocolor(
            20,
            21,
            31,
            225
        )


    drawRoundedBox(
        x,
        180,
        TAB_WIDTH,
        TAB_HEIGHT,
        color,
        12
    )


    local icon =
        iconTextures[iconKey]


    if icon
    and isElement(icon) then

        local iconY =
            180 + (TAB_HEIGHT - TAB_ICON_SIZE) / 2

        local iconX =
            x + TAB_ICON_X
            + (TAB_ICON_BOX_SIZE - TAB_ICON_SIZE) / 2


        dxDrawImage(
            X(iconX),
            Y(iconY),
            S(TAB_ICON_SIZE),
            S(TAB_ICON_SIZE),

            icon,

            0,
            0,
            0,

            selected
            and rgba(COLOR_TAB_ICON_SELECTED_IMAGE)
            or rgba(COLOR_TAB_ICON_UNSELECTED_IMAGE),

            true
        )

    else

        drawText(

            iconKey == "register"
            and "R"
            or iconKey == "login"
            and "L"
            or "S",

            x + TAB_ICON_X,
            180,
            TAB_ICON_BOX_SIZE,
            TAB_HEIGHT,

            selected
            and rgba(COLOR_TAB_SELECTED)
            or rgba(COLOR_TAB_UNSELECTED),

            1,

            getFont("tab"),

            "center",
            "center"
        )
    end


    local textX =
        x
        + TAB_ICON_X
        + TAB_ICON_BOX_SIZE
        + TAB_ICON_TEXT_GAP


    local textWidth =
        TAB_WIDTH
        - (
            TAB_ICON_X
            + TAB_ICON_BOX_SIZE
            + TAB_ICON_TEXT_GAP
            + 10
        )


    drawText(
        label,

        textX,
        180,
        textWidth,
        TAB_HEIGHT,

        selected
        and rgba(COLOR_TAB_SELECTED)
        or rgba(COLOR_TAB_UNSELECTED),

        SIZE_TAB_TEXT,

        getFont("tabText"),

        "center",
        "center"
    )
end


-- =========================================================
-- INPUT
-- =========================================================

local function drawInput(
    x,
    y,
    w,
    h,
    label,
    name,
    password,
    iconKey
)

    local edit = edits[name]

    local value =
        getEditText(name)

    local focused =
        activeEdit == edit


    drawRoundedBox(

        x,
        y,
        w,
        h,

        focused
        and tocolor(
            36,
            37,
            54,
            245
        )
        or tocolor(
            25,
            26,
            38,
            235
        ),

        10
    )


    if focused then

        dxDrawRectangle(

            X(x),
            Y(y + h - 2),
            S(w),
            S(2),

            tocolor(
                220,
                20,
                60,
                255
            )
        )

    end


    local icon =
        inputIconTextures[iconKey]


    local iconSize =
        INPUT_ICON_SIZE[iconKey]
        or 30


    if icon
    and isElement(icon) then

        local iconY =
            y + (h - iconSize) / 2


        local iconColor =
            COLOR_INPUT_ICON[iconKey]
            or {170, 170, 180}


        dxDrawImage(

            X(x + INPUT_ICON_X),
            Y(iconY),

            S(iconSize),
            S(iconSize),

            icon,

            0,
            0,
            0,

            tocolor(
                iconColor[1],
                iconColor[2],
                iconColor[3],
                focused and 255 or 220
            ),

            true
        )

    end


    local display = value

    if password
    and #display > 0 then

        display =
            string.rep(
                "•",
                #display
            )

    end


    local textLeft =
        x
        + INPUT_ICON_X
        + iconSize
        + INPUT_ICON_TEXT_GAP


    local textWidth =
        w
        - (
            INPUT_ICON_X
            + iconSize
            + INPUT_ICON_TEXT_GAP
            + 18
        )


    if display == "" then

        display =
            label


        drawText(

            display,

            textLeft,
            y,
            textWidth,
            h,

            rgba(
                COLOR_INPUT_PLACEHOLDER
            ),

            SIZE_INPUT_TEXT,

            getFont("inputText"),

            "left",
            "center"
        )

    else

        drawText(

            display,

            textLeft,
            y,
            textWidth,
            h,

            rgba(
                COLOR_INPUT_TEXT
            ),

            SIZE_INPUT_TEXT,

            getFont("inputText"),

            "left",
            "center"
        )

    end
end


-- =========================================================
-- GENDER BUTTON
-- =========================================================

local function drawGenderButton(
    x,
    y,
    w,
    h,
    label,
    iconKey,
    selected
)

    local color =
        selected
        and tocolor(
            220,
            20,
            60,
            235
        )
        or tocolor(
            25,
            26,
            38,
            235
        )


    drawRoundedBox(
        x,
        y,
        w,
        h,
        color,
        10
    )


    local icon =
        iconTextures[iconKey]


    if icon
    and isElement(icon) then

        dxDrawImage(

            X(x + 14),
            Y(y + 11),
            S(36),
            S(36),

            icon,

            0,
            0,
            0,

            tocolor(
                255,
                255,
                255,
                255
            ),

            true
        )

    else

        drawText(

            iconKey == "male"
            and "M"
            or "F",

            x + 10,
            y,
            40,
            h,

            rgba(
                COLOR_BUTTON
            ),

            SIZE_INPUT_TEXT,

            getFont("inputText"),

            "center",
            "center"
        )
    end


    drawText(

        label,

        x + 58,
        y,
        w - 70,
        h,

        rgba(
            COLOR_BUTTON
        ),

        SIZE_INPUT_TEXT,

        getFont("inputText"),

        "left",
        "center"
    )
end


-- =========================================================
-- REGISTER GENDER
-- =========================================================

local function getRegisterGender()

    return getElementData(
        localPlayer,
        "scLogin:registerGender"
    )
    or "Male"
end


local function setRegisterGender(gender)

    setElementData(
        localPlayer,
        "scLogin:registerGender",
        gender,
        false
    )
end


-- =========================================================
-- MAIN PANEL
-- =========================================================

local function drawMainPanel()

    drawBackground()


    dxDrawRectangle(
        0,
        0,
        screenW,
        screenH,
        tocolor(
            5,
            6,
            12,
            125
        )
    )


    dxDrawCircle(
        X(1510),
        Y(530),
        S(420),
        0,
        360,

        tocolor(
            220,
            20,
            60,
            22
        ),

        tocolor(
            220,
            20,
            60,
            0
        ),

        32
    )


    local panelX = 220
    local panelY = 105

    local panelW = 820
    local panelH = 870


    drawRoundedBox(
        panelX + 12,
        panelY + 14,
        panelW,
        panelH,
        tocolor(
            0,
            0,
            0,
            130
        ),
        22
    )


    drawRoundedBox(
        panelX,
        panelY,
        panelW,
        panelH,
        tocolor(
            9,
            10,
            17,
            50
        ),
        22
    )


    drawTab(
        panelX + 55,
        "Register",
        "register",
        currentTab == "register"
    )


    drawTab(
        panelX + 55 + TAB_WIDTH + TAB_GAP,
        "Login",
        "login",
        currentTab == "login"
    )


    drawTab(
        panelX + 55 + (TAB_WIDTH + TAB_GAP) * 2,
        "Change Serial",
        "serial",
        currentTab == "serial"
    )


    if currentTab == "login" then

        drawLoginPanel(
            panelX,
            panelY
        )

    elseif currentTab == "register" then

        drawRegisterPanel(
            panelX,
            panelY
        )

    else

        drawSerialPanel(
            panelX,
            panelY
        )

    end


    drawMusicButton()


    local rightX = 1180


    drawText(
        "STARS CITY",

        rightX,
        280,
        650,
        90,

        tocolor(
            COLOR_RIGHT_TITLE[1],
            COLOR_RIGHT_TITLE[2],
            COLOR_RIGHT_TITLE[3],
            235
        ),

        SIZE_LOGO * 0.62,

        getFont("logo"),

        "center",
        "center"
    )


    drawText(
        "ROLEPLAY • COMMUNITY • EXPERIENCE",

        rightX,
        365,
        650,
        35,

        rgba(
            COLOR_SUBTITLE,
            230
        ),

        SIZE_RIGHT_SIDE,

        getFont("subtitle"),

        "center",
        "center"
    )


    drawText(

        "System Serial Activated",

        panelX + 530,
        panelY + panelH - 52,

        235,
        30,

        tocolor(
            80,
            220,
            130,
            210
        ),

        SIZE_FOOTER,

        getFont("footer"),

        "right",
        "center"
    )
end


-- =========================================================
-- LOGIN PANEL
-- =========================================================

function drawLoginPanel(
    panelX,
    panelY
)

    local x =
        panelX + 55

    local y =
        panelY + 275

    local w = 710


    drawInput(
        x,
        y,
        w,
        68,
        "Username",
        "loginUsername",
        false,
        "user"
    )


    drawInput(
        x,
        y + 105,
        w,
        68,
        "Password",
        "loginPassword",
        true,
        "password"
    )


    local buttonY =
        y + 220


    local hovered =
        isMouseIn(
            x,
            buttonY,
            w,
            68
        )


    drawRoundedBox(

        x,
        buttonY,
        w,
        68,

        hovered
        and tocolor(
            240,
            35,
            75,
            255
        )
        or tocolor(
            220,
            20,
            60,
            245
        ),

        12
    )


    drawText(

        loginBusy
        and "Logging in..."
        or "CONFIRM",

        x,
        buttonY,
        w,
        68,

        rgba(
            COLOR_BUTTON
        ),

        SIZE_BUTTON,

        getFont("button"),

        "center",
        "center"
    )


    if statusText ~= ""
    and getTickCount() < statusUntil then

        drawText(

            statusText,

            x,
            buttonY + 85,
            w,
            55,

            statusColor(),

            SIZE_STATUS,

            getFont("status"),

            "center",
            "center"
        )
    end


    drawText(

        "Don't have an account? Select Register.",

        x,
        buttonY + 155,
        w,
        35,

        rgba(
            COLOR_NORMAL
        ),

        SIZE_NORMAL,

        getFont("normal"),

        "center",
        "center"
    )
end


-- =========================================================
-- REGISTER PANEL
-- =========================================================

function drawRegisterPanel(
    panelX,
    panelY
)

    local x =
        panelX + 55

    local y =
        panelY + 260

    local w = 710


    drawInput(
        x,
        y,
        w,
        58,
        "Username",
        "registerUsername",
        false,
        "user"
    )


    drawInput(
        x,
        y + 91,
        w,
        58,
        "Password",
        "registerPassword",
        false,
        "password"
    )


    drawInput(
        x,
        y + 182,
        w,
        58,
        "Mobile Number",
        "registerPhone",
        false,
        "phone"
    )


    local gender =
        getRegisterGender()


    drawGenderButton(

        x,
        y + 292,
        335,
        58,

        "Male",
        "male",

        gender == "Male"
    )


    drawGenderButton(

        x + 375,
        y + 292,
        335,
        58,

        "Female",
        "female",

        gender == "Female"
    )


    local buttonY =
        y + 380


    local hovered =
        isMouseIn(
            x,
            buttonY,
            w,
            62
        )


    drawRoundedBox(

        x,
        buttonY,
        w,
        62,

        hovered
        and tocolor(
            50,
            210,
            120,
            255
        )
        or tocolor(
            35,
            190,
            105,
            245
        ),

        11
    )


    drawText(

        "Create Account",

        x,
        buttonY,
        w,
        62,

        rgba(
            COLOR_BUTTON
        ),

        SIZE_BUTTON,

        getFont("button"),

        "center",
        "center"
    )


    if statusText ~= ""
    and getTickCount() < statusUntil then

        drawText(

            statusText,

            x,
            buttonY + 72,
            w,
            52,

            statusColor(),

            SIZE_STATUS,

            getFont("status"),

            "center",
            "center"
        )
    end
end


-- =========================================================
-- SERIAL PANEL
-- =========================================================

function drawSerialPanel(
    panelX,
    panelY
)

    local x =
        panelX + 55

    local y =
        panelY + 270

    local w = 710


    drawText(

        "Change Serial",

        x,
        y - 60,
        w,
        40,

        rgba(
            COLOR_TITLE
        ),

        SIZE_TITLE,

        getFont("title"),

        "left",
        "center"
    )


    drawText(

        "Enter your username, password and mobile number.",

        x,
        y - 20,
        w,
        40,

        rgba(
            COLOR_NORMAL
        ),

        SIZE_NORMAL,

        getFont("normal"),

        "left",
        "center"
    )


    drawInput(

        x,
        y + 45,
        w,
        62,

        "Username",

        "serialUsername",

        false,

        "user"
    )


    drawInput(

        x,
        y + 140,
        w,
        62,

        "Password",

        "serialPassword",

        false,

        "password"
    )


    drawInput(

        x,
        y + 235,
        w,
        62,

        "Mobile Number",

        "serialPhone",

        false,

        "phone"
    )


    local buttonY =
        y + 345


    local hovered =
        isMouseIn(
            x,
            buttonY,
            w,
            62
        )


    drawRoundedBox(

        x,
        buttonY,
        w,
        62,

        hovered
        and tocolor(
            70,
            125,
            255,
            255
        )
        or tocolor(
            55,
            95,
            220,
            245
        ),

        11
    )


    drawText(

        "Change Serial",

        x,
        buttonY,
        w,
        62,

        rgba(
            COLOR_BUTTON
        ),

        SIZE_BUTTON,

        getFont("button"),

        "center",
        "center"
    )


    if statusText ~= ""
    and getTickCount() < statusUntil then

        drawText(

            statusText,

            x,
            buttonY + 72,
            w,
            52,

            statusColor(),

            SIZE_STATUS,

            getFont("status"),

            "center",
            "center"
        )
    end
end


-- =========================================================
-- RENDER
-- =========================================================

addEventHandler(
    "onClientRender",
    root,
    function()

        if splashVisible then

            drawSplash()

            return
        end


        if loginVisible then

            drawMainPanel()

        end
    end
)


-- =========================================================
-- CLICK HANDLER
-- =========================================================

addEventHandler(
    "onClientClick",
    root,
    function(button, state)

        if button ~= "left"
        or state ~= "down"
        or not loginVisible then

            return
        end


        local panelX = 220
        local panelY = 105

        local x =
            panelX + 55


        -- =================================================
        -- MUSIC BUTTON
        -- =================================================

        if isMouseIn(
            MUSIC_ICON_X,
            MUSIC_ICON_Y,
            MUSIC_ICON_SIZE,
            MUSIC_ICON_SIZE
        ) then

            toggleMusic()

            return
        end


        -- =================================================
        -- TABS
        -- =================================================

        if isMouseIn(
            panelX + 55,
            180,
            TAB_WIDTH,
            TAB_HEIGHT
        ) then

            currentTab = "register"

            setStatus(
                "Please enter your account information.",
                "info"
            )

            clearActiveEdit()

            return
        end


        if isMouseIn(
            panelX + 55 + TAB_WIDTH + TAB_GAP,
            180,
            TAB_WIDTH,
            TAB_HEIGHT
        ) then

            currentTab = "login"

            setStatus(
                "Please enter your username and password.",
                "info"
            )

            clearActiveEdit()

            return
        end


        if isMouseIn(
            panelX + 55 + (TAB_WIDTH + TAB_GAP) * 2,
            180,
            TAB_WIDTH,
            TAB_HEIGHT
        ) then

            currentTab = "serial"

            setStatus(
                "Please enter your account information.",
                "info"
            )

            clearActiveEdit()

            return
        end


        -- =================================================
        -- LOGIN
        -- =================================================

        if currentTab == "login" then

            local y =
                panelY + 275


            if isMouseIn(
                x,
                y,
                710,
                68
            ) then

                focusEdit(
                    edits.loginUsername
                )

                return
            end


            if isMouseIn(
                x,
                y + 105,
                710,
                68
            ) then

                focusEdit(
                    edits.loginPassword
                )

                return
            end


            if isMouseIn(
                x,
                y + 220,
                710,
                68
            ) then

                if loginBusy then
                    return
                end


                local username =
                    getEditText(
                        "loginUsername"
                    )

                local password =
                    getEditText(
                        "loginPassword"
                    )


                if username == ""
                or password == "" then

                    setStatus(
                        "Please complete your username and password.",
                        "error"
                    )

                    return
                end


                loginBusy = true


                setStatus(
                    "Checking account...",
                    "info"
                )


                triggerServerEvent(

                    "scAccounts:loginRequest",

                    localPlayer,

                    username,

                    password
                )


                return
            end


        -- =================================================
        -- REGISTER
        -- =================================================

        elseif currentTab == "register" then

            local y =
                panelY + 260


            if isMouseIn(
                x,
                y,
                710,
                58
            ) then

                focusEdit(
                    edits.registerUsername
                )

                return
            end


            if isMouseIn(
                x,
                y + 91,
                710,
                58
            ) then

                focusEdit(
                    edits.registerPassword
                )

                return
            end


            if isMouseIn(
                x,
                y + 182,
                710,
                58
            ) then

                focusEdit(
                    edits.registerPhone
                )

                return
            end


            if isMouseIn(
                x,
                y + 292,
                335,
                58
            ) then

                setRegisterGender(
                    "Male"
                )

                return
            end


            if isMouseIn(
                x + 375,
                y + 292,
                335,
                58
            ) then

                setRegisterGender(
                    "Female"
                )

                return
            end


            if isMouseIn(
                x,
                y + 380,
                710,
                62
            ) then

                if loginBusy then
                    return
                end


                local username =
                    getEditText(
                        "registerUsername"
                    )

                local password =
                    getEditText(
                        "registerPassword"
                    )

                local phone =
                    getEditText(
                        "registerPhone"
                    )

                local gender =
                    getRegisterGender()


                if username == ""
                or password == ""
                or phone == "" then

                    setStatus(
                        "Please complete all fields.",
                        "error"
                    )

                    return
                end


                loginBusy = true


                setStatus(
                    "Creating account...",
                    "info"
                )


                triggerServerEvent(

                    "scAccounts:registerRequest",

                    localPlayer,

                    username,
                    password,
                    phone,
                    gender
                )


                return
            end


        -- =================================================
        -- SERIAL
        -- =================================================

        else

            local y =
                panelY + 270


            if isMouseIn(
                x,
                y + 45,
                710,
                62
            ) then

                focusEdit(
                    edits.serialUsername
                )

                return
            end


            if isMouseIn(
                x,
                y + 140,
                710,
                62
            ) then

                focusEdit(
                    edits.serialPassword
                )

                return
            end


            if isMouseIn(
                x,
                y + 235,
                710,
                62
            ) then

                focusEdit(
                    edits.serialPhone
                )

                return
            end


            if isMouseIn(
                x,
                y + 345,
                710,
                62
            ) then

                if loginBusy then
                    return
                end


                local username =
                    getEditText(
                        "serialUsername"
                    )

                local password =
                    getEditText(
                        "serialPassword"
                    )

                local phone =
                    getEditText(
                        "serialPhone"
                    )


                if username == ""
                or password == ""
                or phone == "" then

                    setStatus(
                        "Please complete your account information.",
                        "error"
                    )

                    return
                end


                loginBusy = true


                setStatus(
                    "Changing serial...",
                    "info"
                )


                triggerServerEvent(

                    "scAccounts:changeSerialRequest",

                    localPlayer,

                    username,
                    password,
                    phone
                )


                return
            end
        end
    end
)


-- =========================================================
-- SERVER RESULT
-- =========================================================

addEvent(
    "scLogin:serverResult",
    true
)

addEventHandler(
    "scLogin:serverResult",
    root,
    function(
        success,
        message,
        data
    )

        loginBusy = false


        if success then

            setStatus(
                message
                or "Operation completed successfully.",
                "success"
            )


            if data
            and data.action == "registered" then

                currentTab = "login"


                setEditText(
                    "loginUsername",
                    data.username
                    or getEditText(
                        "registerUsername"
                    )
                )


                setEditText(
                    "loginPassword",
                    ""
                )


                setStatus(

                    "Account created successfully. Please enter your password to login.",

                    "success"
                )


                clearActiveEdit()


            elseif data
            and data.action == "serialChanged" then

                currentTab = "login"


                setEditText(
                    "loginUsername",
                    getEditText(
                        "serialUsername"
                    )
                )


                setEditText(
                    "loginPassword",
                    ""
                )


                setStatus(

                    "Serial changed successfully. Please login.",

                    "success"
                )


                clearActiveEdit()
            end


        else

            setStatus(

                message
                or "An error occurred.",

                "error"
            )
        end
    end
)


-- =========================================================
-- AUTO-FILL RESULT
-- =========================================================

addEvent(
    "scLogin:autoLoginResult",
    true
)

addEventHandler(
    "scLogin:autoLoginResult",
    root,
    function(
        available,
        username
    )

        autoFillChecking = false


        if not loginVisible
        and not splashVisible then
            return
        end


        if available
        and type(username) == "string"
        and username ~= "" then

            autoFillAvailable = true
            autoFillUsername = username


            -- =================================================
            -- IMPORTANT:
            -- Only fill the username field.
            --
            -- No password is received.
            -- No login is performed.
            -- No timer is started.
            -- loginBusy remains FALSE.
            -- The player MUST press CONFIRM.
            -- =================================================

            setEditText(
                "loginUsername",
                username
            )


            setEditText(
                "loginPassword",
                ""
            )


            setStatus(
                "Account found on this computer. Please enter your password.",
                "info"
            )

        else

            autoFillAvailable = false
            autoFillUsername = ""

        end
    end
)


-- =========================================================
-- LOGIN COMPLETED
-- =========================================================

addEvent(
    "scLogin:loginCompleted",
    true
)

addEventHandler(
    "scLogin:loginCompleted",
    root,
    function()

        closeLogin()

    end
)


-- =========================================================
-- ESC
-- =========================================================

bindKey(
    "escape",
    "down",
    function()

        if splashVisible
        or loginVisible then

            return
        end
    end
)


-- =========================================================
-- RESOURCE START
-- =========================================================

addEventHandler(
    "onClientResourceStart",
    resourceRoot,
    function()

        if not getElementData(
            localPlayer,
            "account:loggedIn"
        ) then

            openSplash()

        end
    end
)


-- =========================================================
-- RESOURCE STOP CLEANUP
-- =========================================================

addEventHandler(
    "onClientResourceStop",
    resourceRoot,
    function()

        stopMusic()


        if backgroundTexture
        and isElement(backgroundTexture) then

            destroyElement(
                backgroundTexture
            )

        end


        destroyFonts()

        destroyEdits()


        showCursor(false)

        restoreClientWorld()


        guiSetInputEnabled(false)

        guiSetInputMode(
            "allow_binds"
        )
    end
)
