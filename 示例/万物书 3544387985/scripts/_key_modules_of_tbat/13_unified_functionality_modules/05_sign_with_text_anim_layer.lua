--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    使用图层锚定偏移。方便任何尺寸的 文本 数据偏移。
    用于各种木牌做 动画贴图文本显示

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    local function Set_Event(inst,_table)
        inst._info_inst:PushEvent("Set",_table)
    end
    local function Reset_Event(inst)
        inst._info_inst:PushEvent("Set",inst.default_data)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    function TBAT.MODULES:SignWithTextAnimLayerInstall(inst,default_data,follow_layer)
        if type(default_data) == nil then
            print("error in TBAT.MODULES:SignWithTextAnimLayerInstall")
            return
        end
        inst._info_inst = inst:SpawnChild("tbat_building_info_slot")
        inst:ListenForEvent("InfoSet",Set_Event)
        inst:ListenForEvent("InfoReset",Reset_Event)
        inst.default_data = default_data
        inst:PushEvent("InfoSet",default_data)
        --------------------------------------------------------------------
        --- 某些特殊情况下，需要文字跟着整体做动画。
            if type(follow_layer) == "string" then
                inst._info_inst.entity:AddFollower()
                inst._info_inst.Follower:FollowSymbol(inst.GUID,follow_layer,0,0,0)
            end
        --------------------------------------------------------------------
    end