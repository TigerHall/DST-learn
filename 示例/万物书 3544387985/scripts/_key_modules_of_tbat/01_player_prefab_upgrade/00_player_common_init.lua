-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    所有玩家都拥有的模块

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end
    ------------------------------------------------------
    --- 通用数据库
        if inst.components.tbat_data == nil then
            inst:AddComponent("tbat_data")
        end
        if inst.components.tbat_data_to_world == nil then
            inst:AddComponent("tbat_data_to_world")
        end
    ------------------------------------------------------
    --- 独立RPC信道
        inst:AddComponent("tbat_com_rpc_event")
    ------------------------------------------------------
    --- 服务端获取客户端的数据
        inst:AddComponent("tbat_com_client_side_data")
    ------------------------------------------------------
    --- 交互失败话语组件
        inst:AddComponent("tbat_com_action_fail_reason")
    ------------------------------------------------------
    --- 蘑菇小蜗埚 配方解锁控制器
        inst:AddComponent("tbat_com_mushroom_snail_cauldron__for_player")
    ------------------------------------------------------
    --- 复制官方同款deuff 控制器，稍微有点改动
        inst:AddComponent("tbat_com_debuffable")
    ------------------------------------------------------
end)
