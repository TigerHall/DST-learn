--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_fantasy_shop"
    local ANIM_SCALE = 1
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_fantasy_shop.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function npc_creater(inst)
        local npc_prefab = { {"tbat_npc_ty",Vector3(7.266,0,0.63)},{"tbat_npc_xmm",Vector3(-3.142,0,0.355)}}
        local x,y,z = inst.Transform:GetWorldPosition()
        for i, data in ipairs(npc_prefab) do
            local prefab = data[1]
            local pos = data[2]
            local npc = SpawnPrefab(prefab)
            -- npc.entity:SetParent(inst.entity)
            -- npc.Transform:SetPosition(x+pos.x,0,z+pos.z)
            -- npc.Transform:SetPosition(x+pos.x,0,z+pos.z)
            npc.entity:AddFollower()
            npc.Follower:FollowSymbol(inst.GUID, "slot_"..i, 0,0,1)
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
        inst.AnimState:SetBank("tbat_building_fantasy_shop")
        inst.AnimState:SetBuild("tbat_building_fantasy_shop")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetScale(ANIM_SCALE, ANIM_SCALE,ANIM_SCALE)
        inst.AnimState:SetFinalOffset(-3)
        inst:AddTag("structure")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst:DoTaskInTime(0,npc_creater)
        MakeHauntableLaunch(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
