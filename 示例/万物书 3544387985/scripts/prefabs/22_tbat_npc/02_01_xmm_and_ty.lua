--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_npc_ty.zip"),
        Asset("ANIM", "anim/tbat_npc_xmm.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function workable_test_fn(inst,doer,right_click)        
        return true
    end
    local function workable_on_work_fn(inst,doer)
        if inst.on_work_fn then
            inst.on_work_fn(inst,doer)
        end
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("tbat_npc_ty_and_xmm"," ")
        replica_com:SetSGAction("tbat_sg_empty_active")
        replica_com:SetDistance(10)
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
    local function GetTalkerOffset(inst)
        return TBAT.test_offset or Vector3(0, -700, 0)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品

    local npc_data = {
        ["tbat_npc_ty"] = {
            bank = "tbat_npc_ty",
            build = "tbat_npc_ty",
            anim = "idle",
            anim_speed = 1.0,
            on_work_fn = function(inst,doer)
                inst.components.talker:Say(TBAT:GetString2("tbat_npc_ty","onwork"))
            end,
        },
        ["tbat_npc_xmm"] = {
            bank = "tbat_npc_xmm",
            build = "tbat_npc_xmm",
            anim = "idle",
            anim_speed = 1.0,
            on_work_fn = function(inst,doer)
                inst.components.talker:Say(TBAT:GetString2("tbat_npc_xmm","onwork"))
            end,
        },
    }

    local ret = {}

    for this_prefab, data in pairs(npc_data) do
        local function fn()
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddSoundEmitter()
            inst.entity:AddNetwork()
            -- MakeInventoryPhysics(inst)

            inst.AnimState:SetBank(data.bank)
            inst.AnimState:SetBuild(data.build)
            inst.AnimState:PlayAnimation(data.anim or "idle",true)
            inst.AnimState:SetDeltaTimeMultiplier(data.anim_speed or 0.8)
            inst.AnimState:SetFinalOffset(3)
            inst.entity:SetPristine()
            ----------------------------------------------------------
            ---
                inst:AddComponent("talker")
                inst.components.talker:SetOffsetFn(GetTalkerOffset)
            ----------------------------------------------------------
            ---
                workable_install(inst)
                inst.on_work_fn = data.on_work_fn
            ----------------------------------------------------------
                inst.persists = false   --- 是否留存到下次存档加载。
            ----------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("inspectable")
            return inst
        end

        table.insert(ret,Prefab(this_prefab, fn, assets))
    end    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret)