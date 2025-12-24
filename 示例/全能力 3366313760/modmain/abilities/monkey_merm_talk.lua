AddPlayerPostInit(function(inst)
    inst:AddTag("mermfluent") --听懂鱼人的话

    if not TheWorld.ismastersim then return end
end)

----------------------------------------------------------------------------------------------------
-- 听懂猴子
local function speech_override_fn(inst, speech)
    return speech
end

AddPrefabPostInitAny(function(inst)
    if inst.speech_override_fn then
        inst.speech_override_fn = speech_override_fn
    end
end)
