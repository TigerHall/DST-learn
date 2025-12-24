--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    3种地毯

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local all_carpet_data = {
        {
            name = "tbat_turf_carpet_pink_fur",
            assets = require("prefabs/14_tbat_turfs/02_02_carpet_skin_for_pink_fur")
        },
        {
            name = "tbat_turf_carpet_cat_claw",
            assets = require("prefabs/14_tbat_turfs/02_03_carpet_skin_for_claw")
        },
        {
            name = "tbat_turf_carpet_four_leaves_clover",
            assets = {}
        },
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable install
    local function is_digging(inst,doer)
        local weapon = doer.replica.combat:GetWeapon()
        if weapon then
            local has_fork = string.find(weapon.prefab, "fork") ~= nil
            if has_fork then
                return true
            end
        end
        return false
    end
    local function workable_test_fn(inst,doer,right_click)
        return right_click and is_digging(inst,doer)
    end
    local function workable_on_work_fn(inst,doer)
        inst:Remove()
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("tbat_turf_carpet",STRINGS.ACTIONS.DIG)
        replica_com:SetSGAction("tbat_sg_predig")
        replica_com:SetDistance(3)
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
    local ret = {}
    for k, data in pairs(all_carpet_data) do
        ----------------------------------------------------------------------------------------------------
        --- 本体
            local this_prefab = data.name
            local assets = data.assets
            table.insert(assets,Asset("ANIM", "anim/"..data.name..".zip"))
            local function fn()
                local inst = CreateEntity()
                inst.entity:AddTransform()
                inst.entity:AddAnimState()
                inst.entity:AddSoundEmitter()
                inst.entity:AddNetwork()
                inst.entity:AddMiniMapEntity()
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
                TBAT.SKIN:SetDefaultBankBuild(inst,data.name,data.name)
                inst.AnimState:SetBank(data.name)
                inst.AnimState:SetBuild(data.name)
                inst.AnimState:PlayAnimation("idle")
                inst.AnimState:SetLayer(LAYER_BACKGROUND)
                inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
                inst:AddTag("NOBLOCK")
                inst.entity:SetPristine()
                workable_install(inst)
                if not TheWorld.ismastersim then
                    return inst
                end
                inst:AddComponent("tbat_com_skin_data")
                inst:AddComponent("inspectable")
                inst:AddComponent("savedrotation")
                inst:AddComponent("named")
                inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
                return inst
            end
            table.insert(ret,Prefab(this_prefab, fn, assets))
        ----------------------------------------------------------------------------------------------------
        ---
            local function placer_postinit_fn(inst)
                inst.AnimState:SetLayer(LAYER_BACKGROUND)
                inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            end
            table.insert(ret,MakePlacer(this_prefab.."_placer",data.name,data.name,"idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil))
        ----------------------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret)
