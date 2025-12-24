--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_resources_memory_crystal_ore_3"
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
        {"tbat_material_memory_crystal",2},
        {"rocks",6},
        {"moonrocknugget",1},
    }
    local function onhammered(inst, worker)
        replace_inst(inst,"tbat_resources_memory_crystal_ore_2")
        for k, data in pairs(loots) do
            for i = 1, data[2], 1 do
                inst.components.lootdropper:SpawnLootPrefab(data[1])
            end
        end
        inst:Remove()
    end
    local function onhit(inst, worker)
        inst.AnimState:PlayAnimation("stage_3_hit")
        inst.AnimState:PushAnimation("stage_3",true)
        SpawnPrefab("tbat_resources_memory_crystal_ore_fx_for_mine").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建特效
    local function fx_create(inst)
        local fx = inst:SpawnChild("tbat_resources_memory_crystal_ore_fx")
        fx:PushEvent("Set",{type = 3,parent = inst})
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
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
        inst.AnimState:PlayAnimation("stage_3",true)
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
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
