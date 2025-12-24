--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_resources_memory_crystal_ore_2"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_resources_memory_crystal_ore.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function replace_inst(inst,prefab)
        local x,y,z = inst.Transform:GetWorldPosition()
        local new = SpawnPrefab(prefab)
        new.Transform:SetPosition(x,y,z)
        new.components.tbat_data:CopyDataFromInst(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 掉落
    local loots = {
        {"tbat_material_memory_crystal",1},
        {"rocks",6},
    }
    local function onhammered(inst, worker)
        replace_inst(inst,"tbat_resources_memory_crystal_ore_1")
        for k, data in pairs(loots) do
            for i = 1, data[2], 1 do
                inst.components.lootdropper:SpawnLootPrefab(data[1])
            end
        end
        inst:Remove()
    end
    local function onhit(inst, worker)
        inst.AnimState:PlayAnimation("stage_2_hit")
        inst.AnimState:PushAnimation("stage_2",true)
        SpawnPrefab("tbat_resources_memory_crystal_ore_fx_for_mine").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建特效
    local function fx_create(inst)
        local fx = inst:SpawnChild("tbat_resources_memory_crystal_ore_fx")
        fx:PushEvent("Set",{type = 2,parent = inst})
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 成长
    local next_stage_prefab = "tbat_resources_memory_crystal_ore_3"
    local function start_grow(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if inst:IsAsleep() then
            replace_inst(inst,next_stage_prefab)
            inst:Remove()
        else
            inst:AddTag("NOCLICK")
            inst:AddTag("INLIMBO")
            inst.AnimState:PlayAnimation("stage_2_to_3",false)
            inst:ListenForEvent("animover",function()
                replace_inst(inst,next_stage_prefab)
                inst:Remove()
            end)
        end
    end
    local function grow_logic(inst)
        local days = inst.components.tbat_data:Add("days",1)
        if days >= 3 then
            start_grow(inst)
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
        MakeObstaclePhysics(inst,0.5)
        inst.AnimState:SetBank("tbat_resources_memory_crystal_ore")
        inst.AnimState:SetBuild("tbat_resources_memory_crystal_ore")
        inst.AnimState:PlayAnimation("stage_2",true)
        inst.AnimState:SetTime(2*math.random())
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_resources_memory_crystal_ore_core.tex")
        inst:AddTag("tbat_resources_memory_crystal_ore")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("tbat_data")
        inst:AddComponent("inspectable")
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(3)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)
        MakeHauntableLaunch(inst)
        fx_create(inst)
        inst:WatchWorldState("cycles",grow_logic)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
