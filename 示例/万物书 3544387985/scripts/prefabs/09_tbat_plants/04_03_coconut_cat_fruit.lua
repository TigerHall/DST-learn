--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_coconut_cat_fruit"
    local CHECKING_UPDATE_TIME = 5                                      --- 检测间隔
    local CHECKING_REAIDUS = 4                                          --- 检测范围
    local GROW_TIME = TBAT.DEBUGGING and 30 or TBAT.PARAM.ONE_DAY       --- 烤火时间
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_coconut_cat.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 扫描task
    local function fire_pit_checking_task(inst)
        if inst.components.inventoryitem.owner then
            TheWorld.components.tbat_com_special_timer_for_theworld:RemoveTimer(inst)
            inst.components.tbat_data:Set("time",0)
            return
        end
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,0,z, CHECKING_REAIDUS,nil,nil,{"blueflame","tbat_item_snow_plum_wolf","HASHEATER"})
        ----------------------------------------------------------------------------------
        --- 燃烧状态才算数
            local is_near_low_temperature = false
            for k, target in pairs(ents) do
                if target.components.burnable == nil then
                    is_near_low_temperature = true
                elseif target.components.burnable:IsBurning() then
                    is_near_low_temperature = true
                end
                if target.components.heater and target.components.heater:IsEndothermic() then
                    is_near_low_temperature = true
                end
            end
        ----------------------------------------------------------------------------------
        if is_near_low_temperature then
            local time = inst.components.tbat_data:Add("time",CHECKING_UPDATE_TIME)
            -- print("time:",inst,time)
            if time >= GROW_TIME then
                inst:PushEvent("type_switch")
                TheWorld.components.tbat_com_special_timer_for_theworld:RemoveTimer(inst)
                -- print("fake error :cat type swtich",inst)
            end
        else
            inst.components.tbat_data:Set("time",0)
        end
    end
    local function on_land_event(inst)
        TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(inst,CHECKING_UPDATE_TIME,fire_pit_checking_task)
    end
    local function fire_pit_init(inst)
        if inst.components.inventoryitem.owner then
            TheWorld.components.tbat_com_special_timer_for_theworld:RemoveTimer(inst)
        else
            TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(inst,CHECKING_UPDATE_TIME,fire_pit_checking_task)
        end
    end
    local function print_error_info()
        for i = 1, 10, 1 do
            print("[TBAT]ERROR for tbat_com_special_timer_for_theworld missing")            
        end
    end
    local function fire_pit_logic_install(inst)
        if TheWorld.components.tbat_com_special_timer_for_theworld == nil then
            TheWorld:DoPeriodicTask(2,function()
                local str = '【万物书】清甜椰子：有奇怪的MOD造成了严重的兼容性冲突。可能是某些强大的自动辅助MOD。注意哦！我准备死给你看。'
                TheNet:Announce(str)
                Networking_SystemMessage(str)
                local temp_table = {}
                local temp = temp_table[str] + 1
            end)
            TheWorld:DoTaskInTime(10,function()
                TheWorld.Map = {}
                print_error_info()
            end)
            print_error_info()
            return
        end
        TheWorld.components.tbat_com_special_timer_for_theworld:AddOneTimeTimer(fire_pit_init,inst)
        inst:ListenForEvent("on_landed",on_land_event)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function grow_animover_event(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        inst:Remove()
        SpawnPrefab("tbat_plant_coconut_cat_kit").Transform:SetPosition(x,y,z)
    end
    local function grow_event(inst)
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")
        inst:RemoveComponent("inventoryitem")
        inst.AnimState:PlayAnimation("stage_1_to_2",false)
        inst:ListenForEvent("animover",grow_animover_event)
    end
    local function grow_event_install(inst)
        inst:ListenForEvent("type_switch",grow_event)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_plant_coconut_cat")
        inst.AnimState:SetBuild("tbat_plant_coconut_cat")
        inst.AnimState:PlayAnimation("stage_1",true)

        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        -----------------------------------------
        ---
            inst:AddComponent("tbat_data")
        -----------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_plant_coconut_cat_fruit","images/inventoryimages/tbat_plant_coconut_cat_fruit.xml")
            MakeHauntableLaunch(inst)
        -----------------------------------------
        ---
            TBAT.FNS:ShadowInit(inst)
        -----------------------------------------
        ---
            fire_pit_logic_install(inst)
            grow_event_install(inst)
        -----------------------------------------
        ---
            inst:AddComponent("repairer")
            inst.components.repairer.repairmaterial = MATERIALS.WOOD
            inst.components.repairer.healthrepairvalue = TUNING.REPAIR_LOGS_HEALTH
        -----------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)

