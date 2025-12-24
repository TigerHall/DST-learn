---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    玩家身上挂的 通用 classified 。


]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 01_replica_register.lua 里有说明。
    --- classified 里的 net 注册函数，在 replica lua 那边，方便统一管理。
    local replica_com = TBAT.CLASSIFIED_DATA
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- init API
    local function init_event(inst,_player)
        if inst.owner then
            return
        end
        local player = _player or inst.__init:value()
        -- print("666666666666666666",player)
        if TheWorld.ismastersim then
            inst.entity:SetParent(player.entity)
            inst.Transform:SetPosition(0,0,0)
            -- inst:DoTaskInTime(10,function()
            --     --- 不能一开始就设置这个参数，会直接导致客户端这边无法初始化
            --     inst.Network:SetClassifiedTarget(player)
            -- end)
        end
        inst.owner = player
        -------------------------------------------------------
        --- 修正带洞穴的情况下，客户端初始化的问题
            if not TheNet:IsDedicated() and player == nil then
                local temp_player = inst.entity:GetParent()
                print("warning : tbat_classified init error",temp_player)
                player = temp_player
            end
        -------------------------------------------------------
        --- 注册去replica  AttachClassified
            inst.__attached_replica = inst.__attached_replica or {}            
            for com_name, classified_api_install_fn in pairs(replica_com) do
                if type(classified_api_install_fn) == "function" then
                    classified_api_install_fn(inst)
                end
                if not TheWorld.ismastersim and (player.replica[com_name] or player.replica._[com_name]) then
                    local com = player.replica[com_name] or player.replica._[com_name]
                    if com.AttachClassified and not inst.__attached_replica[com_name] then
                        com:AttachClassified(inst)
                        print("tbat_classified attach",player,com_name)
                        inst.__attached_replica[com_name] = true
                    end
                else
                    -- print("tbat_classified replica attach error",com_name,player.replica[com_name] , player.replica._[com_name])
                end
            end
        -------------------------------------------------------
        --- inited event
            local function push_inited_event()
                inst:PushEvent("inited")
                print("info tbat_classified inited for",player)
                player.tbat_classified = inst
                player:PushEvent("tbat_classified_inited") --- 通知玩家。可用来触发 界面安装。
            end
        -------------------------------------------------------
        --- 服务端的replica的函数有奇怪的丢失问题，注册这个监听重新绑定。
            if TheWorld.ismastersim then
                inst:ListenForEvent("playerentered",function(_,player)
                    if player == inst.owner then
                        for com_name, v in pairs(replica_com) do
                            if player.replica[com_name] and player.replica[com_name].AttachClassified then
                                player.replica[com_name]:AttachClassified(inst)
                            end
                        end
                        push_inited_event()
                    end
                end,TheWorld)
            else
                push_inited_event()
            end
        -------------------------------------------------------
        ---
        -------------------------------------------------------
    end
    local function init_api_install(inst)
        inst.__init = net_entity(inst.GUID,"tbat_classified_init","tbat_classified_init")
        inst:ListenForEvent("tbat_classified_init",init_event)
        inst.Init = function(inst,player)
            if TheWorld.ismastersim then
                inst.__init:set(player)
                init_event(inst,player)
            end
            -- print("fake error tbat classified init for",player)
        end
        --- 用来处理某些极端情况下，无法在客户端初始化绑定classified，或者服务端这边，重复多次创建classified，导致无法唯一化绑定
        inst.__init_task = inst:DoPeriodicTask(1,function(inst)
            -- print("warning : tbat_classified init task",inst,inst.owner)
            if TheWorld.ismastersim and inst.owner == nil then
                inst:Remove()
                -- print("error : tbat_classified init task remove",inst)
                return
            end
            if inst.owner then
                inst.__init_task:Cancel()
                -- print("warning : tbat_classified has inited")
                return
            end
            local player = inst.entity:GetParent()
            if player and player:IsValid() then
                init_event(inst,player)
            end
        end)
    end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 不通过replica挂载函数。
    local function other_api_install(inst)
        for k, fn in pairs(TBAT.CLASSIFIED_INSTALL_FNS or {}) do
            if type(fn) == "function" then
                fn(inst)
            end
        end
    end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    -- inst.entity:Hide()
    inst:AddTag("CLASSIFIED")
    inst.entity:SetPristine()
    -------------------------------------------------------
    ---

    -------------------------------------------------------
    ---
        init_api_install(inst)
        other_api_install(inst)
    -------------------------------------------------------
    if not TheWorld.ismastersim then
        -- inst.OnEntityReplicated = init_event
        return inst
    end

    return inst
end
return Prefab("tbat_classified", fn)
