--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    控制刷新的event

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local SEARCH_RADIUS = 40
    local SPAWN_RADIUS = TBAT.PARAM.THE_TREE_OF_ALL_THINGS_RADIUS
    local vines_spawn_data = {
        -- ["宠物房子prefab"] = "对应藤曼prefab",
        ["tbat_building_maple_squirrel_pet_house"] = {
            prefab = "tbat_the_tree_of_all_things_vine_maple_squirrel",
            pt = Vector3(3.748,0,4.367),
        },
        ["tbat_building_snow_plum_pet_house"] = {
            prefab = "tbat_the_tree_of_all_things_vine_snow_plum_chieftain",
            pt = Vector3(-4,0,-3),
        },
        ["tbat_building_osmanthus_cat_pet_house"] = {
            prefab = "tbat_the_tree_of_all_things_vine_osmanthus_cat",
            pt = Vector3(6.613,0,-2.359),
        },
        ["tbat_building_forest_mushroom_cottage"] = {
            prefab = "tbat_the_tree_of_all_things_vine_mushroom_snail",
            -- pt = Vector3(6.613,0,-2.359),
        },
        ["tbat_building_lavender_flower_house"] = {
            prefab = "tbat_the_tree_of_all_things_vine_lavender_kitty",
            -- pt = Vector3(6.613,0,-2.359),
        },
        ["tbat_building_reef_lighthouse"] = {
            prefab = "tbat_the_tree_of_all_things_vine_stinkray",
            -- pt = Vector3(6.613,0,-2.359),
        },
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function GetRandomSpawnPoint(pt)
        local avalable_points = {}
        local temp_radius = math.min(SPAWN_RADIUS,20)
        local delta_radius = 0.5
        local temp_wall_item = SpawnPrefab("wall_stone_item")
        while temp_radius > 9 do
            local temp_points = TBAT.FNS:GetSurroundPoints({
                target = pt,
                range = temp_radius,
                num = 10*temp_radius
            })
            for k, pt in pairs(temp_points) do
                -- if TheWorld.Map:CanPlantAtPoint(pt.x,0,pt.z) and TheWorld.Map:CanDeployWallAtPoint(pt,temp_wall_item) then
                    table.insert(avalable_points,pt)
                -- end
            end
            temp_radius = temp_radius - delta_radius
        end
        temp_wall_item:Remove()
        return avalable_points[math.random(1,#avalable_points)]
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function spawn_single_vine(tree,data)
        -- local pt = GetRandomSpawnPoint(Vector3(0,0,0))
        -- if pt == nil then
        --     return
        -- end
        local x,y,z = tree.Transform:GetWorldPosition()
        local offset_pt = data.pt or GetRandomSpawnPoint(Vector3(0,0,0))
        local vine_prefab = data.prefab
        local record = tree.components.tbat_data:Get(vine_prefab)
        local vine_inst = nil
        if record then
            vine_inst = SpawnSaveRecord(record)
        else
            vine_inst = SpawnPrefab(vine_prefab)
        end
        vine_inst:PushEvent("Set",{
            pt = Vector3( x + offset_pt.x , 0 , z + offset_pt.z ),
            sleeping = tree:IsAsleep(),
        })
        vine_inst:ListenForEvent("onremove",function()
            vine_inst:Remove()
        end,tree)
        print("+++[TBAT] 藤曼生成",vine_inst:GetDisplayName(),vine_inst)
        vine_inst.tree = tree
        return vine_inst
    end
    local function despawn_single_vine(tree,vine_inst)
        tree.components.tbat_data:Set(vine_inst.prefab,nil)
        vine_inst:PushEvent("despawn")
        print("---[TBAT] 藤曼删除",vine_inst:GetDisplayName(),vine_inst)
    end
    local function on_save_fn(com)
        for _, vine_inst in pairs(com.inst.vines or {}) do
            if vine_inst and vine_inst:IsValid() then
                local record = vine_inst:GetSaveRecord()
                com:Set(vine_inst.prefab,record)
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function main_check_and_spawn_fn(inst)
        inst.vines = inst.vines or {}

        local x,y,z = inst.Transform:GetWorldPosition()
        local all_pet_houses = TheSim:FindEntities(x, 0, z, SEARCH_RADIUS, {"tbat_pet_eyebone_box"})
        local need_2_spawn_list = {}
        for i,temp_house in ipairs(all_pet_houses) do
            need_2_spawn_list[temp_house.prefab] = true
        end
        --------------------------------------------------------
        --- 判定需要创建
            for house_prefab, data in pairs(vines_spawn_data) do                
                if need_2_spawn_list[house_prefab] and (inst.vines[house_prefab] == nil or not inst.vines[house_prefab]:IsValid() ) then
                    inst.vines[house_prefab] = spawn_single_vine(inst,data)
                end
            end
        --------------------------------------------------------
        --- 判定需要销毁
            for house_prefab, temp_vine in pairs(inst.vines) do
                if temp_vine and temp_vine:IsValid() then
                    if need_2_spawn_list[house_prefab] then
                        --- 不需要销毁
                    else
                        despawn_single_vine(inst,temp_vine)
                        inst.vines[house_prefab] = nil
                    end
                end
            end
        --------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    main_check_and_spawn_fn(inst)
    inst:DoPeriodicTask(5,main_check_and_spawn_fn)
    inst.components.tbat_data:AddOnSaveFn(on_save_fn)
end