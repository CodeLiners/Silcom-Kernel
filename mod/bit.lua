on("load",
    function()
        registerHook("bit_tobits", bit.tobits)
        registerHook("bit_lshift", bit.blshift)
        registerHook("bit_rshift", bit.brshift)
        registerHook("bit_xor", bit.bxor)
        registerHook("bit_or", bit.bor)
        registerHook("bit_and", bit.band)
        registerHook("bit_not", bit.bnot)
        registerHook("bit_tonum", bit.tonumb)
    end
)