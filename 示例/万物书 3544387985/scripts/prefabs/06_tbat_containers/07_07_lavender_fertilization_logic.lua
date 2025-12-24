--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local this_prefab = "tbat_container_lavender_kitty"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 密语
    local function WhisperTo(player_or_userid,str)
        TBAT.FNS:Whisper(player_or_userid,{
            icondata = "tbat_container_lavender_kitty" ,
            sender_name = TBAT:GetString2("tbat_container_lavender_kitty","name"),
            s_colour = {150/255,87/255,164/255},
            message = str,
            m_colour = {254/255,234/255,221/255},
        })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local function acceptable_test_fn(inst,item,doer,right_click)
        if item.prefab == "tbat_material_lavender_laundry_detergent" then
            return true
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 
            item.components.stackable:Get():Remove()
        --------------------------------------------------
        --- 台词
            local str_table = TBAT:GetString2(this_prefab,"acceptted_announce")
            local str = str_table[math.random(#str_table)]
            WhisperTo(doer,str)
        --------------------------------------------------
        --- evet
            inst:PushEvent("start_fertilization")
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,TBAT:GetString2(this_prefab,"fertilization"))
        replica_com:SetSGAction("doshortaction")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 执行施肥+浇水
    local function start_fertilization_fn(inst)
        local flag,all_center_points = inst:GetAllTileCenters()
        if not flag then
            return
        end
        for k, pt in pairs(all_center_points) do
            if TheWorld.Map:IsFarmableSoilAtPoint(pt.x, 0, pt.z) and TheWorld.components.farming_manager then
                TheWorld.components.farming_manager:AddSoilMoistureAtPoint(pt.x, 0, pt.z, 100)
                local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(pt:Get())
                TheWorld.components.farming_manager:AddTileNutrients(tile_x, tile_z, 100,100,100)
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    return function(inst)
        -------------------------------------------------------------------------------
        --- 
            acceptable_com_install(inst)
        -------------------------------------------------------------------------------
        ---
            if not TheWorld.ismastersim then
                return
            end
        -------------------------------------------------------------------------------
        ---
            inst:ListenForEvent("start_fertilization",start_fertilization_fn)
        -------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------