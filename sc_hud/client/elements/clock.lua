HUD = HUD or {}


HUD:registerElement(
    "clock",
    {

        getValue = function()

            local time = getRealTime()

            return string.format(
                "%02d:%02d",
                time.hour,
                time.minute
            )

        end

    }
)
