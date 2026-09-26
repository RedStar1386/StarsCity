HUD = HUD or {}


HUD:registerElement(
    "date",
    {

        getValue = function()


            local time = getRealTime()


            local jy, jm, jd = HUD:gregorianToJalali(

                time.year + 1900,

                time.month + 1,

                time.monthday

            )


            return string.format(

                "%04d/%02d/%02d",

                jy,

                jm,

                jd

            )


        end

    }
)
