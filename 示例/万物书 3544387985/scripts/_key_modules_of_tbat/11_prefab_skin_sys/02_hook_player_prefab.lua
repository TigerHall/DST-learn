-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 给玩家安装皮肤控制器

    local function replace_cmd_skin(inst,item,origin_skin_cmd)
        if origin_skin_cmd == nil then                                    
            local rpc_prefab,rpc_skin = inst.components.tbat_com_skins_controller:GetSkinSelecting() 
            if rpc_prefab and rpc_prefab == item.prefab and rpc_skin and inst.components.tbat_com_skins_controller:HasSkin(rpc_skin,rpc_prefab) then
                if TBAT.DEBUGGING then
                    print("TBAT SKIN API evet RPC",rpc_prefab,rpc_skin)
                end
                return rpc_skin
            end
        end
        return origin_skin_cmd
    end
    AddPlayerPostInit(function(inst)
        if not TheWorld.ismastersim then
            return
        end
        
        inst:AddComponent("tbat_com_cdkey_analyzer")
        inst:AddComponent("tbat_com_skins_controller")

        inst:ListenForEvent("builditem",function(_,_table)
            if _table and _table.item then
                if TBAT.DEBUGGING then
                    print("TBAT SKIN API builditem evet",_table.item,_table.skin)
                end
                if  _table.item.components.tbat_com_skin_data then
                    _table.skin = replace_cmd_skin(inst,_table.item,_table.skin)
                    _table.item.components.tbat_com_skin_data:SetCurrent(_table.skin,inst)
                end
                _table.item:PushEvent("tbat_event.player_build",inst)  --- 触发玩家制作事件
            end
        end)
        inst:ListenForEvent("buildstructure",function(_,_table)
            if _table and _table.item then
                if TBAT.DEBUGGING then
                    print("TBAT SKIN API buildstructure event",_table.item,_table.skin)
                end
                if  _table.item.components.tbat_com_skin_data then
                    _table.skin = replace_cmd_skin(inst,_table.item,_table.skin)
                    _table.item.components.tbat_com_skin_data:SetCurrent(_table.skin,inst)
                end
                _table.item:PushEvent("tbat_event.player_build",inst)  --- 触发玩家制作事件
            end
        end)

        inst:DoTaskInTime(1,function()
            local default_unlock_list = TBAT.SKIN:GetDefaultUnlockList()
            if #default_unlock_list == 0 then
                return
            end
            for i,skin_name in ipairs(default_unlock_list) do
                inst.components.tbat_com_skins_controller:UnlockSkin(skin_name)
            end
        end)
        
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
