addCommandHandler("setwanted",

function(cmd, amount)

    amount = tonumber(amount) or 0


    setElementData(
        localPlayer,
        "wanted",
        amount
    )


    outputChatBox(
        "Wanted set to: "..amount
    )

end)
