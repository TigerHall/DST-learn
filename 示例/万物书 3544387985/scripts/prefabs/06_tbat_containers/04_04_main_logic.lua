--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_container_emerald_feathered_bird_collection_chest"

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- button_collect
    local function button_collect_onclick(inst)
        ------------------------------------------------------------------
        ---
            local x,y,z = inst.Transform:GetWorldPosition()
        ------------------------------------------------------------------
        ---
            local list = {}
        ------------------------------------------------------------------
        ---
            -- inst.components.container:ForEachItem(function(item)
            --     if item then
            --         list[item.prefab] = true
            --     end
            -- end)
        ------------------------------------------------------------------
        ---
            local com_black_list = {"container","trap","mine"}
            local function has_black_list_com(tempInst)
                for _, com_name in pairs(com_black_list) do
                    if tempInst.components[com_name] then
                        return true
                    end
                end
                return false
            end 
            local new_ent_table = {}
            local test_fn = function(tempInst)
                if tempInst.prefab 
                    and tempInst.entity:GetParent() == nil
                    and tempInst.components.inventoryitem
                    and not tempInst:HasOneOfTags({ "nonpotatable", "irreplaceable" ,"INLIMBO" ,"NOCLICK"})
                    and tempInst.components.inventoryitem.owner == nil
                    and tempInst.components.inventoryitem.cangoincontainer
                    and tempInst.components.inventoryitem.canbepickedup
                    and tempInst.brainfn == nil
                    and tempInst.sg == nil
                    and not has_black_list_com(tempInst)
                    then
                        return true
                    end
                return false
            end
            local cmd = {
                callback = new_ent_table,
                fn = test_fn
            }
            TheWorld:PushEvent("tbat_event.get_all_items",cmd)
            for k, tempInst in pairs(new_ent_table) do
                if  not inst.components.container:IsFull() then
                    -- local save_record = tempInst:GetSaveRecord()
                    -- tempInst:Remove()
                    -- inst.components.container:GiveItem(SpawnSaveRecord(save_record))
                    OnEntityWake(tempInst.GUID)
                    inst.components.container:GiveItem(tempInst)
                end
            end
        ------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- item remove
    local function item_remove_logic(inst)
        local exp_delta = 0
        local exp_mult = 1
        if TBAT.DEBUGGING then
            exp_mult = 100
        end
        inst.components.container:ForEachItem(function(item)
            if item == nil then
                return
            end
            if item.components.stackable == nil then
                exp_delta = exp_delta + 1
            else
                exp_delta = exp_delta + item.components.stackable:StackSize()
            end
            item:Remove()
        end)
        if inst:HasTag("lv2") then
            inst:SetExp(0)
        else
            inst:ExpDelta(exp_delta*exp_mult)        
            if inst:GetExp() >= (inst.max_exp or 10000) then
                inst.components.container:Close()
                inst:PushEvent("level_up")
                inst.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/active")
            end
        end

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- item deconstruct
    local function item_deconstruct_logic(inst)
        ------------------------------------------------------------------
        --
            local green_staff = SpawnPrefab("greenstaff")
            green_staff.components.finiteuses.Use = function()                    
            end
            -- green_staff.components.inventoryitem.owner = inst.opener or inst:GetNearestPlayer(true)
            local destroystructure_fn = green_staff.components.spellcaster.spell
            local function deconstruct_item(item)
                pcall(destroystructure_fn,green_staff,item)
            end
        ------------------------------------------------------------------
        --
            local x,y,z = inst.Transform:GetWorldPosition()
            inst.components.container:ForEachItem(function(item)
                if item then
                    local can_deconstruct = true
                    local recipe = AllRecipes[item.prefab]
                    if recipe == nil or FunctionOrValue(recipe.no_deconstruction, item) then
                        can_deconstruct = false
                    end
                    if can_deconstruct then
                            if item.components.stackable == nil or item.components.stackable:StackSize() == 1 then
                                deconstruct_item(item)
                            else
                                local num = item.components.stackable:StackSize()
                                local prefab = item.prefab
                                item.components.stackable:SetStackSize(1)
                                local record = item:GetSaveRecord()
                                item:Remove()
                                for i = 1, num, 1 do
                                    local temp_item = SpawnSaveRecord(record)
                                    temp_item.Transform:SetPosition(x,y,z)
                                    deconstruct_item(temp_item)
                                end
                            end
                    end
                end
            end)
        ------------------------------------------------------------------
        --
            green_staff:Remove()
        ------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- button_2
    local ALLOW_DECONSTRUC = true
    local function button_2_onclick(inst)
        local container_type = inst.GetType and inst:GetType() or 1
        if container_type == 1 then
            item_remove_logic(inst)
        else
            item_deconstruct_logic(inst)
            item_remove_logic(inst)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- level up
    local function level_up(inst)
        inst:AddTag("lv2")
        inst.components.tbat_data:Set("lv2",true)
    end
    local function level_init(com)
        if com:Get("lv2") then
            com.inst:AddTag("lv2")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("button_collect",button_collect_onclick)
    inst:ListenForEvent("button_2",button_2_onclick)

    inst:ListenForEvent("level_up",level_up)
    inst.components.tbat_data:AddOnLoadFn(level_init)

end