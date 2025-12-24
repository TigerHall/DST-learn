--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    local this_prefab = "tbat_eq_snail_shell_of_mushroom"

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    local accept_data = {
        [1] = {
            --- 给予松鼠牙*1，提升5%移速，最多给予六次
            prefab = "tbat_material_squirrel_incisors",
            max = 6,
        },
        [2] = {
            --- 给予森伞小菇*1，提升5%防御，最多给予六次
            prefab = "tbat_sensangu_item",
            max = 6,
        },
        [3] = {
            --- 给予发光蘑菇*100，护甲变为无耐久型装备
            prefab = "tbat_plant_fluorescent_mushroom_item",
            max = 100,
        },
        [4] = {
            --- 给予荧光苔藓*100，护甲增加小蜗盾能力，每受到伤害会治疗自己20%
            prefab = "tbat_plant_fluorescent_moss_item",
            max = 100,
        },
    }
    local function refresh_name_fn(inst)
        local str = TBAT:GetString2(this_prefab,"name").."\n"
        for k, data in pairs(accept_data) do
            local item_name = STRINGS.NAMES[string.upper(data.prefab)]
            local current_num = inst.components.tbat_data:Add(data.prefab,0)
            str = str..item_name.." :  "..current_num.." / "..data.max.."\n"
        end
        inst.components.named:SetName(str)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- level update
    local function level_sys_update_fn(inst)
        --------------------------------------------------------------
        --- 速度控制
            local speed_cmd_prefab = accept_data[1].prefab
            local speed_max_level = accept_data[1].max
            local speed_current_level = inst.components.tbat_data:Add(speed_cmd_prefab,0,0,speed_max_level)
            inst.components.equippable.walkspeedmult = 1 + (speed_current_level * 0.05)
        --------------------------------------------------------------
        --- 防御控制
            local def_cmd_prefab = accept_data[2].prefab
            local def_max_level = accept_data[2].max
            local def_current_level = inst.components.tbat_data:Add(def_cmd_prefab,0,0,def_max_level)
            local armor_value = 0.6 + (def_current_level * 0.05)
            inst.components.tbat_data:Set("shell_armor",armor_value)
            inst.components.armor:SetAbsorption(armor_value)
        --------------------------------------------------------------
        --- 无耐久+图标更新
            local glow_cmd_prefab = accept_data[3].prefab
            local glow_max_level = accept_data[3].max
            local glow_current_level = inst.components.tbat_data:Add(glow_cmd_prefab,0,0,glow_max_level)
            if glow_current_level >= glow_max_level then
                inst.components.armor.indestructible = true
                inst.components.armor.condition = 1000
                inst.components.armor.maxcondition = 1000
                inst:AddTag("hide_percentage")
                local rpc_fn = function(inst)
                    inst.___item_slot_update:set(not inst.___item_slot_update:value())
                end
                inst:DoTaskInTime(0,rpc_fn)
                inst:DoTaskInTime(5,rpc_fn)
                inst:DoTaskInTime(10,rpc_fn)
            end
        --------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- hook armor component  挨打回血。
    local function hook_armor_component(inst)
        local old_GetAbsorption = inst.components.armor.GetAbsorption
        inst.components.armor.GetAbsorption = function(self,...)
            --------------------------------------------------------------
            --- 回血
                local max_level = accept_data[4].max
                local current_level = inst.components.tbat_data:Add(accept_data[4].prefab,0,0,max_level)
                local owner = inst.components.inventoryitem:GetGrandOwner()
                if owner and owner.components.health and max_level == current_level then
                    -- local owner_max = owner.components.health.maxhealth
                    -- owner.components.health:DoDelta(owner_max*current_percent,true)
                    owner.components.health:DoDelta(5,true)
                end
            --------------------------------------------------------------
            return old_GetAbsorption(self,...)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 用来主动消除制作栏里的图标 显示的 百分比数据。
    local function update_inventory_bar_itemslot_event(inst)
        local inventorybar = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls.inv
        if inventorybar == nil then
            return
        end
        local itemslot = nil
        for k, invslot in pairs(inventorybar.inv) do
            local temp_itemslot = invslot and invslot.tile
            if temp_itemslot and temp_itemslot.item and temp_itemslot.item == inst then
                itemslot = temp_itemslot             
            end
        end
        if itemslot == nil then
            for k, invslot in pairs(inventorybar.equip) do
                if invslot and invslot.tile and invslot.tile.item and invslot.tile.item == inst then
                    itemslot = invslot.tile
                end
            end            
        end
        if itemslot then
            if inst:HasTag("hide_percentage") and itemslot.percent then
                itemslot.percent:Hide()
            end
        end
        -- print("++++ update_inventory_bar_itemslot_event ++++")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    inst.accept_data = accept_data
    ----------------------------------------------------------------------------------------------------------------
    ---
        inst.___item_slot_update = net_bool(inst.GUID, "___item_slot_update","update_inventory_bar_itemslot")
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("update_inventory_bar_itemslot",update_inventory_bar_itemslot_event)
        end
    ----------------------------------------------------------------------------------------------------------------
    if not TheWorld.ismastersim then
        return
    end
    ----------------------------------------------------------------------------------------------------------------
    ---
        inst:ListenForEvent("refresh_name",refresh_name_fn)
        inst:DoTaskInTime(0,refresh_name_fn )
        inst:ListenForEvent("refresh_level",level_sys_update_fn)
        inst:DoTaskInTime(0,level_sys_update_fn )
        inst:DoTaskInTime(0,hook_armor_component )
    ----------------------------------------------------------------------------------------------------------------
end