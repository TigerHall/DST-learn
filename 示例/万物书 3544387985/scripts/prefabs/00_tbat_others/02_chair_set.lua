--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

        local inst = TheSim:FindEntities(x, 0, z, 10, {"tbat_debug_swing"})[1]
        if inst.chair_set and inst.chair_set:IsValid() then
            inst.chair_set:Remove()
        end
        local chair_set = SpawnPrefab("tbat_other_chair_set")
        chair_set.AnimState:OverrideSymbol("slot","tbat_other_chair_set","empty")
        chair_set.entity:SetParent(inst.entity)
        chair_set.entity:AddFollower()
        chair_set.Follower:FollowSymbol(inst.GUID, "slot",0,0,0,true)
        inst.chair_set = chair_set

        local doer = ThePlayer
        doer.components.playercontroller:DoAction(BufferedAction(doer,chair_set, ACTIONS.SITON))
        local sit_on_sg = {
            ["start_sitting"] = true,
            ["sit_jumpon"] = true,
            ["sitting"] = true,
        }
        local sit_off_sg = {
            ["stop_sitting"] = true,
            ["sit_jumpoff"] = true,
            ["stop_sitting_pst"] = true,
        }
        chair_set:ListenForEvent("newstate",function(_,_table)
            local current_state = _table and _table.statename
            if sit_on_sg[current_state] then
                if doer.Follower == nil then
                    doer.entity:AddFollower()
                end
                doer.Follower:FollowSymbol(chair_set.GUID, "slot",-30,-50,0,true)
            elseif sit_off_sg[current_state] then
                doer.Follower:FollowSymbol(chair_set.GUID, "slot",0,0,0,true)
                doer.Follower:StopFollowing()
                chair_set:Remove()
            end
        end,doer)

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_other_chair_set"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_other_chair_set.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- client player sit on event
    local function client_player_on_set_event(inst)
        local parent = inst.entity:GetParent()
        if parent then
            parent:PushEvent("player_sit_on_chair_be_sure.client",inst)
        else
            print("error in tbat_other_chair_set : parent is nil")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        -- inst.AnimState:SetBank("ruins_chair")
        -- inst.AnimState:SetBuild("ruins_chair")
        inst.AnimState:SetBank("tbat_other_chair_set")
        inst.AnimState:SetBuild("tbat_other_chair_set")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetFinalOffset(-1)
        inst:AddTag("structure")
        inst:AddTag("limited_chair")
        inst:AddTag("uncomfortable_chair")
        inst.entity:SetPristine()
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("player_sit_on.client",client_player_on_set_event)
        end
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst:AddComponent("sittable")
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
