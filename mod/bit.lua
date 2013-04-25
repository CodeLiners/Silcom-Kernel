on("load",
    function()
        registerUHook("bit_tobits", bit.tobits)
        registerUHook("bit_lshift", bit.blshift)
        registerUHook("bit_rshift", bit.brshift)
        registerUHook("bit_xor", bit.bxor)
        registerUHook("bit_or", bit.bor)
        registerUHook("bit_and", bit.band)
        registerUHook("bit_not", bit.bnot)
        registerUHook("bit_tonum", bit.tonumb)
    end
)