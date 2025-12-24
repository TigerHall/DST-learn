-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --[[

--     预制的prefab模板

-- ]]--
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- 前置准备
--     if not TBAT.CONFIG.EQ_WORLD_SKIPPER then
--         return
--     end
--     local this_prefab = "tbat_eq_world_skipper"
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- Assets素材资源
--     local assets =
--     {
--         Asset("ANIM", "anim/tbat_eq_world_skipper.zip"),
--     }
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- 
--     local function onequip(inst, owner)
--         if not (owner and owner.components.playercontroller) then
--             return
--         end
--         inst.__on_equip_task = inst:DoTaskInTime(0.5,function()
--             TBAT.FNS:RPC_PushEvent(owner,"tbat_event.ToggleMap")            
--         end)
--     end
--     local function onunequip(inst, owner)
        
--     end
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- MAP JUMPPER
--     local function map_jump_test_fn(inst,doer,pos)
--         -- print("map_jump_test_fn",pos)
--         return true
--     end
--     local function map_jumper_spell(inst,doer,pos)
--         local test = 100
--         local pt = nil
--         while test > 0 do
--             local x = pos.x + math.random(-40,40)/10
--             local z = pos.z + math.random(-40,40)/10
--             if TheWorld.Map:IsPassableAtPoint(x,0,z,false,false) then
--                 pt = Vector3(x,0,z)
--                 break
--             end
--             test = test - 1
--         end
--         if pt then
--             doer.components.playercontroller:RemotePausePrediction(5)
--             doer.Transform:SetPosition(pt.x,0,pt.z)
--             doer.Physics:Teleport(pt.x,0,pt.z)
--         end
--         TBAT.FNS:RPC_PushEvent(doer,"tbat_event.ToggleMap")
--         doer.components.inventory:GiveItem(SpawnPrefab(inst.prefab))
--         inst:Remove()
--         return true
--     end
--     local function map_jumper_replica_init(inst,replica_com)
--         replica_com:SetTestFn(map_jump_test_fn)
--         replica_com:SetText(TBAT:GetString2(this_prefab,"action_str"))
--     end
--     local function map_jumper_install(inst)
--         inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_map_jumper",map_jumper_replica_init)
--         if not TheWorld.ismastersim then
--             return
--         end
--         inst:AddComponent("tbat_com_map_jumper")
--         inst.components.tbat_com_map_jumper:SetSpellFn(map_jumper_spell)
--     end
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- 右键使用。
--     local function workable_test_fn(inst,doer,right_click)        
--         return inst.replica.inventoryitem:IsGrandOwner(doer)
--     end
--     local function workable_on_work_fn(inst,doer)
--         inst:AddComponent("equippable")
--         inst.components.equippable:SetOnEquip(onequip)
--         inst.components.equippable:SetOnUnequip(onunequip)
--         inst.components.equippable.equipslot = EQUIPSLOTS.TBAT_MAP_JUMPER
--         doer.components.inventory:Equip(inst)
--         return true
--     end

--     local function workable_replica_init(inst,replica_com)
--         replica_com:SetTestFn(workable_test_fn)
--         replica_com:SetText(this_prefab,STRINGS.ACTIONS.ACTIVATE.GENERIC)
--         replica_com:SetSGAction("tbat_sg_empty_active")
--     end
--     local function workable_install(inst)
--         inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
--         if not TheWorld.ismastersim then
--             return
--         end
--         inst:AddComponent("tbat_com_workable")
--         inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
--     end
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- 影子+落水
--     local function shadow_init(inst)
--         if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
--             inst.AnimState:PlayAnimation("item_water")
--         else                                
--             inst.AnimState:PlayAnimation("item")
--         end
--     end
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- init
--     local function init(inst)
--         if not TBAT.CONFIG.EQ_WORLD_SKIPPER then
--             inst:Remove()
--         end
--     end
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --- 创建物品
--     local function fn()
--         local inst = CreateEntity()
--         inst.entity:AddTransform()
--         inst.entity:AddAnimState()
--         inst.entity:AddSoundEmitter()
--         inst.entity:AddNetwork()
--         MakeInventoryPhysics(inst)
--         inst.AnimState:SetBank("tbat_eq_world_skipper")
--         inst.AnimState:SetBuild("tbat_eq_world_skipper")
--         inst.AnimState:PlayAnimation("item")
--         MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
--         inst.entity:SetPristine()
--         ----------------------------------------------------------
--         ---
--             map_jumper_install(inst)
--             workable_install(inst)
--         ----------------------------------------------------------
--         if not TheWorld.ismastersim then
--             return inst
--         end
--         ----------------------------------------------------------
--         ---
--             inst:AddComponent("inspectable")
--             inst:AddComponent("inventoryitem")
--             inst.components.inventoryitem:TBATInit("tbat_eq_world_skipper","images/inventoryimages/tbat_eq_world_skipper.xml")
--         ----------------------------------------------------------
--         ---
--             inst:ListenForEvent("on_landed",shadow_init)
--         ----------------------------------------------------------
--         ---
--             MakeHauntableLaunch(inst)
--         ----------------------------------------------------------
--         ---
--             inst:DoTaskInTime(0,init)
--         ----------------------------------------------------------
--         return inst
--     end
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- return Prefab(this_prefab, fn, assets)


if not TBAT.CONFIG.EQ_WORLD_SKIPPER then
    return
end
local assets ={
    Asset("ANIM", "anim/tbat_eq_world_skipper.zip"),
}
local function shadow_init(inst)
    if inst:IsOnOcean(false) then     --- 如果在海里（不包括船）
        inst.AnimState:PlayAnimation("item_water")
    else
        inst.AnimState:PlayAnimation("item")
    end
end
--- init
local function init(inst)
    if not TBAT.CONFIG.EQ_WORLD_SKIPPER then
        inst:Remove()
    end
end
-- 使用
local function onuse(inst)
    if inst then
        if inst:HasTag("tbat_map_blinker") then
            inst:RemoveTag("tbat_map_blinker")
            inst.components.named:SetName("万物穿梭")
        else
            inst:AddTag("tbat_map_blinker")
            inst.components.named:SetName("万物穿梭（激活）")
        end
    end
end
--保存数据
local function OnSave(inst, data)
    data.map_blinker_onactive = inst.map_blinker_onactive
end

--加载数据
local function OnLoad(inst, data)
    inst.map_blinker_onactive = data and data.map_blinker_onactive or false
    if inst.map_blinker_onactive then
        inst:AddTag("tbat_map_blinker")
        inst.components.named:SetName("万物穿梭（激活）")
    else
        inst:RemoveTag("tbat_map_blinker")
        inst.components.named:SetName("万物穿梭")
    end
end
--- 创建物品
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("tbat_eq_world_skipper")
    inst.AnimState:SetBuild("tbat_eq_world_skipper")
    inst.AnimState:PlayAnimation("item")
    MakeInventoryFloatable(inst, "med", 0.05, { 0.85, 0.45, 0.85 })
    inst.entity:SetPristine()


    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:TBATInit("tbat_eq_world_skipper", "images/inventoryimages/tbat_eq_world_skipper.xml")

    inst:AddComponent("useableitem")
    inst.components.useableitem:SetOnUseFn(onuse)
    inst:AddComponent("named")

    inst:ListenForEvent("on_landed", shadow_init)

    MakeHauntableLaunch(inst)

    inst:DoTaskInTime(0, init)

    inst.map_blinker_onactive = false

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end
return Prefab("tbat_eq_world_skipper", fn, assets)