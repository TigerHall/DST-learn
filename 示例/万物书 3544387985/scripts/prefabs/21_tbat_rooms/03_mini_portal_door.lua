--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_room_mini_portal_door"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_room_mini_portal_door.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- get target
    local target_prefabs = {
        ["pigking"] = true,
        ["beequeenhive"] = true,
    }
    local function get_target()
        local inst = TheSim:FindFirstEntityWithTag("multiplayer_portal")
        if inst == nil then
            for k, v in pairs(Ents) do
                if v and target_prefabs[v.prefab] then
                    inst = v
                    break
                end
            end
        end
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable install
    local function workable_test_fn(inst,doer,right_click)
        return right_click
    end
    local function workable_on_work_fn(inst,doer)
        local target = get_target()
        if target == nil then
            return false
        end
        local x,y,z = target.Transform:GetWorldPosition()
        doer.components.playercontroller:RemotePausePrediction(5)
        doer.Transform:SetPosition(x,y,z)
        doer.Physics:Teleport(x,y,z)
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.ACTIVATE.GENERIC)
        replica_com:SetSGAction("give")
        replica_com:SetDistance(1)
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("tbat_room_mini_portal_door")
        inst.AnimState:SetBuild("tbat_room_mini_portal_door")
        inst.AnimState:PlayAnimation("idle",true)

        inst.entity:SetPristine()
        workable_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end


        inst:AddComponent("inspectable")

        MakeHauntableLaunch(inst)
        TBAT.FNS:SnowInit(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
