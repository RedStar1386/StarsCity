addEvent(
    "SC_START_CINEMATIC",
    true
)


addEventHandler(
    "SC_START_CINEMATIC",
    root,

    function(plane)


        outputChatBox(
            "EVENT RECEIVED"
        )


        fadeCamera(
            true,
            2
        )


        setCameraMatrix(
            20,
            -25,
            310,
            0,
            0,
            300
        )


    end

)
