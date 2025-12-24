--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

sentryward

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_material_dandelion_umbrella"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local assets =
    {
        Asset("ANIM", "anim/tbat_material_dandelion_umbrella.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local target_prefab = {
        "pigking",      -- 猪王
        "dragonfly",    -- 龙蝇
        "moonbase",    -- 月台
        "oasislake",    -- 绿洲
        "antlion_spawner",    -- 蚁狮
        "mandrake_planted",    -- 曼德拉
        "walrus_camp",    -- 海象巢
        "chester_eyebone",    -- 骨眼
        "terrariumchest",    -- 盒中泰拉
        "moose_nesting_ground",    -- 卤鸭
        "statueglommer",    -- 卤鸭
        "sculpture_rooknose",    -- 可疑的雕像
        "sculpture_rookbody",    -- 大理石雕像
        "moon_altar_rock_glass",    -- 吸引人的雕像
        "hermitcrab",    -- 寄居蟹房子
        "monkeyqueen",    -- 猴子女王
        "icefishing_hole",    -- 鲨鱼BOSS
        "beequeenhive",    -- 蜂王
    }
    local target_prefab_cave = {
        "atrium_gate",      --- 远古大门
        "archive_lockbox_dispencer",      --- 知识饮水机
        "ancient_altar",      --- 远古科技
        "hutch_fishbowl",      --- 哈奇
        "minotaur",      --- 远古守护者
        "toadstool_cap",      --- 蟾蜍
        "daywalker",      --- 疯猪
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable
    local function workable_test_fn(inst,doer,right_click)
        return inst.replica.inventoryitem:IsGrandOwner(doer)
    end
    local function workable_on_work_fn(inst,doer)
        -- if true then
        --     return false,"no_target"
        -- end
        --------------------------------------------------------------------
        ---
            local ret_prefab = nil
            local test_num = 100
            local target_inst = nil
            local pt = nil
            while test_num > 0 do
                if not TheWorld:HasTag("cave") then
                    ret_prefab = target_prefab[math.random(#target_prefab)] or "pigking"
                else
                    ret_prefab = target_prefab_cave[math.random(#target_prefab_cave)] or "cave_exit"
                end
                target_inst = c_findnext(ret_prefab)
                if target_inst and target_inst:IsValid() and target_inst.Transform then
                    pt = Vector3(target_inst.Transform:GetWorldPosition())
                    break
                end
                test_num = test_num - 1
            end
        --------------------------------------------------------------------
        ---
            if pt == nil then
                inst.components.stackable:Get():Remove()
                return false,"no_target"
            end
            local mark = SpawnPrefab("sentryward")
            mark.Transform:SetPosition(pt.x,0,pt.z)
            mark.MiniMapEntity:SetEnabled(false)

            local tempInst = CreateEntity()
            tempInst:AddComponent("mapspotrevealer")
            tempInst.components.mapspotrevealer:SetGetTargetFn(function(inst,doer)
                return pt
            end)
            tempInst:DoTaskInTime(0.5,function()
                mark:Remove()
                tempInst.components.mapspotrevealer:RevealMap(doer)
                tempInst:Remove()
            end)
        --------------------------------------------------------------------
        inst.components.stackable:Get():Remove()

        --------------------------------------------------------------------
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("tbat_material_dandelion_umbrella",STRINGS.ACTIONS.ACTIVATE.GENERIC)
        replica_com:SetSGAction("doshortaction")
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
---
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:PlayAnimation("item_water")
        else                                
            inst.AnimState:PlayAnimation("item")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_material_dandelion_umbrella")
        inst.AnimState:SetBuild("tbat_material_dandelion_umbrella")
        inst.AnimState:PlayAnimation("item")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        -------------------------------------------------
        ---
            workable_install(inst)
        -------------------------------------------------
        ---
            if not TheWorld.ismastersim then
                return inst
            end
        -------------------------------------------------
        ---
            inst:AddComponent("fuel")
            inst.components.fuel.fuelvalue = TUNING.TINY_FUEL
            MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
            MakeSmallPropagator(inst)
        -------------------------------------------------
        ---
            inst:AddComponent("inspectable")
        -------------------------------------------------
        ---
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_material_dandelion_umbrella","images/inventoryimages/tbat_material_dandelion_umbrella.xml")
        -------------------------------------------------
        ---
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_TINYITEM
        -------------------------------------------------
        ---
            inst:ListenForEvent("on_landed",shadow_init)
        -------------------------------------------------
        --- 交互失败
            inst:AddComponent("tbat_com_action_fail_reason")
            inst.components.tbat_com_action_fail_reason:Add_Reason("no_target",TBAT:GetString2(this_prefab,"no_target"))
        -------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
