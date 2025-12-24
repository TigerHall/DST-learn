--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    统一处理本MOD的积雪初始化

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function snow_over_init(inst)
        if TheWorld.state.issnowcovered then
            inst.AnimState:Show("SNOW")
            inst.AnimState:Show("snow")
            inst.AnimState:ShowSymbol("snow")
        else
            inst.AnimState:Hide("snow")
            inst.AnimState:Hide("SNOW")
            inst.AnimState:HideSymbol("snow")
        end
    end
    function TBAT.FNS:SnowInit(inst)
        snow_over_init(inst)
        inst:WatchWorldState("issnowcovered", snow_over_init)
    end    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:Hide("shadow")
            inst.AnimState:HideSymbol("shadow")
        else                                
            inst.AnimState:Show("SHADOW")
            inst.AnimState:Show("shadow")
            inst.AnimState:ShowSymbol("shadow")
        end
    end
    function TBAT.FNS:ShadowInit(inst)
        inst:ListenForEvent("on_landed",shadow_init)
        shadow_init(inst)
        inst:DoTaskInTime(0,shadow_init)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------