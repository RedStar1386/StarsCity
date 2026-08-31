addEvent(
    "SC_START_CINEMATIC",
    true
)


addEventHandler(
    "SC_START_CINEMATIC",
    root,

    function()

        outputChatBox(
            "EVENT RECEIVED"
        )


        fadeCamera(
            true,
            2
        )


        setCameraMatrix(
            0,
            -20,
            310,
            0,
            0,
            300
        )

    end
)
