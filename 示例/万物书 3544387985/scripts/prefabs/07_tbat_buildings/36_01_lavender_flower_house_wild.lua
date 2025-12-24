--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    野外的薰衣草花房

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_lavender_flower_house_wild"
    local cat_prefab = "tbat_pet_lavender_kitty"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_lavender_flower_house.zip"),
        Asset("ANIM", "anim/tbat_chat_icon_building_lavender_flower_house.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 密语相关
    --- 密语图标
    TBAT.FNS:AddChatIconData("tbat_building_lavender_flower_house",{
        atlas = "images/chat_icon/empty.xml",
        image = "empty.tex",                     --- 128x128 pix
        scale = nil,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
        fx = {
            bank = "tbat_chat_icon_building_lavender_flower_house",
            build = "tbat_chat_icon_building_lavender_flower_house",
            anim = "idle",
            time = 3,
        },  
    })
    --- 密语API 193,163,213
    local function WhisperTo(inst,player_or_userid,str)
        TBAT.FNS:Whisper(player_or_userid,{
            icondata = "tbat_building_lavender_flower_house" ,
            sender_name = TBAT:GetString2(this_prefab,"name.pet"),
            s_colour = {193/255,163/255,213/255},
            message = str,
            m_colour = {208/255,228/255,255/255},
        })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建花丛
    local function CreateFlowerBush(inst)
        local test_butterfly = SpawnPrefab("butterfly")
        local test_fn = function(pt)
            if TheWorld.Map:CanDeployPlantAtPoint(pt,test_butterfly) then
                return true
            end
            return false
        end
        local pt , all_points = TBAT.FNS:GetRandomSurroundPoint({
            target = inst,
            max_radius = 8,
            min_raidus = 2,
            delta_raidus = 0.3,
            test = test_fn,
            num_mult = 3,
        })
        test_butterfly:Remove()
        if type(all_points) == "table" and #all_points > 2 then
            local points = TBAT.FNS:GetRandomDiffrenceValuesFromTable(all_points, 2)
            for k, pt in pairs(points) do
                SpawnPrefab("tbat_plant_lavender_bush").Transform:SetPosition(pt:Get())
                SpawnPrefab("round_puff_fx_lg").Transform:SetPosition(pt:Get())
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 给奖励
    local function GiveReward(new_inst,doer,old_level,new_level)
        --- 小屋会掉落薰衣草花房蓝图*1，薰衣草小猫蓝图*1.
        if new_level == 1 then
            doer.components.inventory:GiveItem(SpawnPrefab("tbat_container_lavender_kitty_blueprint2"))
            doer.components.inventory:GiveItem(SpawnPrefab("tbat_building_lavender_flower_house_blueprint2"))
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 提交函数
    local function OnConstructed(inst, doer)
    local concluded = true
    for _, v in ipairs(CONSTRUCTION_PLANS[inst.prefab] or {}) do
        if inst.components.constructionsite:GetMaterialCount(v.type) < v.amount then
            concluded = false
            break
        end
    end
	if concluded then
        -- print("fake error ++++++++++ 666")
        local current_level = inst.level
        local x,y,z = inst.Transform:GetWorldPosition()
        ---------------------------------------------------------
        --- 解绑宠物
            local pet = nil
            for cat, flag in pairs(inst.components.leader.followers) do
                if cat and cat:IsValid() then
                    pet = cat
                    inst.components.leader:RemoveFollower(cat)
                end
            end
        ---------------------------------------------------------
        --- 创建新建筑
            local next_level = current_level + 1
            if next_level > 5 then
                next_level = 1
            end
            local new_prefab = this_prefab.."_lv"..next_level
            inst:Remove()
            local new_inst = SpawnPrefab(new_prefab)
            new_inst.Transform:SetPosition(x,y,z)
            new_inst:PushEvent("level_up_switched")
        ---------------------------------------------------------
        --- 重新绑定宠物
            if pet and pet:IsValid() then
                new_inst.components.leader:AddFollower(pet)
                pet.house = new_inst
            end
        ---------------------------------------------------------
        --- 密语
            -- local str = TBAT:GetString2(this_prefab,"mission_finished_announce")
            -- str = TBAT.FNS:ReplaceString(str,"{XXXX}",tostring(next_level).." / 5")
            local str = TBAT:GetString2(this_prefab,"mission_finished_announce."..current_level)
            inst:WhisperTo(doer,str)
        ---------------------------------------------------------
        ---
            -- CreateFlowerBush(new_inst)
            new_inst:PushEvent("CreateFlowerBush")
        ---------------------------------------------------------
        --- 给奖励
            GiveReward(new_inst,doer,current_level,next_level)
        ---------------------------------------------------------
    end
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 宠物相关
    ------------------------------------------------------------------------
    --- 宠物
        local function add_cat_events(inst,cat)
            if cat:HasTag("house_event_inited_finish") then
                return
            end
            cat.house = inst
            cat:AddTag("house_event_inited_finish")
            cat:DoPeriodicTask(1,function()
                if cat.components.follower:GetLeader() ~= cat.house then
                    -- cat.components.health:Kill()
                    local x,y,z = cat.Transform:GetWorldPosition()
                    SpawnPrefab("spawn_fx_tiny").Transform:SetPosition(x,y,z)
                    cat:Remove()
                end
            end)
            local function restar_timer()
                cat.house.components.timer:StartTimer("respawn_cat",TBAT.DEBUGGING and 480 or 3*480)            
            end
            cat:ListenForEvent("death",restar_timer)
        end
        local function spawn_cat(inst)
            if inst.components.leader:IsBeingFollowedBy(cat_prefab) or inst.components.timer:TimerExists("respawn_cat") then
                return nil
            end
            local cat = nil
            local cat_record = inst.components.tbat_data:Get("cat_record")
            if cat_record then
                cat = SpawnSaveRecord(cat_record)
                inst.components.tbat_data:Set("cat_record",nil)
            else
                cat = SpawnPrefab(cat_prefab)
            end
            cat.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.components.leader:AddFollower(cat)
            add_cat_events(inst,cat)
            inst.components.timer:StopTimer("respawn_cat")
            return cat
        end
        local function force_spawn_cat(inst)
            inst.components.timer:StopTimer("respawn_cat")
            spawn_cat(inst)
        end
        local function cat_onload_checker(inst)
            for cat, v in pairs(inst.components.leader.followers) do
                if cat and cat:IsValid() then
                    add_cat_events(inst,cat)
                end
            end
        end
    ------------------------------------------------------------------------
    --- 计时器到时间
        local function respawn_timer_event(inst,data)
            if data and data.name == "respawn_cat" then
                spawn_cat(inst)
            end
        end
    ------------------------------------------------------------------------
    --- 被陷阱抓
        local function follower_trapped(inst)
            inst.components.timer:StartTimer("respawn_cat",TBAT.DEBUGGING and 480 or 3*480)
        end
    ------------------------------------------------------------------------
    --- 回家后触发
        local function onwenthome(inst,data) --- 回家后储存数据，并清除实体。
            local doer = data and data.doer
            if doer then
                local save_record = doer:GetSaveRecord()
                inst.components.tbat_data:Set("cat_record",save_record)
            end
        end
    ------------------------------------------------------------------------
    local function Pet_Com_install(inst)
        inst:AddComponent("tbat_data")
        inst:AddComponent("leader")
        inst:DoTaskInTime(1,spawn_cat)
        inst:DoTaskInTime(1,cat_onload_checker)
        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone",respawn_timer_event)
        inst:ListenForEvent("follower_trapped",follower_trapped)        --- 来自 动物 那边。
        inst:ListenForEvent("onwenthome",onwenthome)                    --- 触发回家。
        inst:WatchWorldState("cycles",spawn_cat)
        inst:ListenForEvent("force_spawn_cat",force_spawn_cat)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function common_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_building_lavender_flower_house.tex")
        MakeObstaclePhysics(inst, 1.2)
        inst.AnimState:SetBank("tbat_building_lavender_flower_house")
        inst.AnimState:SetBuild("tbat_building_lavender_flower_house")
        inst.AnimState:PlayAnimation("idle")
        inst:AddTag("structure")
        inst:AddTag(this_prefab)
        inst:AddTag("constructionsite")
        inst.entity:SetPristine()
        inst.WhisperTo = WhisperTo
        if not TheWorld.ismastersim then
            return inst
        end
        --------------------------------------------------------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
        --------------------------------------------------------------------------------------------------------
        --- 建造
            inst:AddComponent("constructionsite")
            -- inst.components.constructionsite:SetConstructionPrefab("construction_container")
            inst.components.constructionsite:SetConstructionPrefab("tbat_building_lavender_flower_house_wild_container")
            inst.components.constructionsite:SetOnConstructedFn(OnConstructed)
        --------------------------------------------------------------------------------------------------------
        --- 作祟
            MakeHauntableLaunch(inst)
        --------------------------------------------------------------------------------------------------------
        --- 创建花丛
            inst:ListenForEvent("CreateFlowerBush",CreateFlowerBush)
        --------------------------------------------------------------------------------------------------------
        --- 宠物相关
            Pet_Com_install(inst)
        --------------------------------------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 数据
    local all_data = {
        ----------------------------------------------------
        --- 等级
            [1] = {
                recipes = {
                    {"carrot_seeds", 6},
                    {"corn_seeds", 6},
                    {"eggplant_seeds", 6},
                    {"dug_berrybush", 2},
                    {"tbat_plant_crimson_maple_tree_kit", 1}
                },
            },
        ----------------------------------------------------
        --- 等级
            [2] = {
                recipes = {
                    {"pumpkin_seeds", 6},
                    {"asparagus_seeds", 6},
                    {"garlic_seeds", 6},
                    {"dug_monkeytail", 2},
                    {"tbat_plant_valorbush_kit", 1}
                },
            },
        ----------------------------------------------------
        --- 等级
            [3] = {
                recipes = {
                    {"onion_seeds", 6},
                    {"durian_seeds", 6},
                    {"pomegranate_seeds", 6},
                    {"dug_sapling", 2},
                    {"tbat_plant_pear_blossom_tree_kit", 1}
                },
            },
        ----------------------------------------------------
        --- 等级
            [4] = {
                recipes = {
                    {"dragonfruit_seeds", 6},
                    {"pepper_seeds", 6},
                    {"watermelon_seeds", 6},
                    {"dug_grass", 2},
                    {"tbat_plant_cherry_blossom_tree_kit", 1}
                },
            },
        ----------------------------------------------------
        --- 等级
            [5] = {
                recipes = {
                    {"tomato_seeds", 6},
                    {"potato_seeds", 6},
                    {"dug_rock_avocado_bush", 2},
                    {"dug_bananabush", 2},
                    {"tbat_plant_crimson_bramblefruit_kit", 1}
                },
            },
        ----------------------------------------------------
        -- --- 等级
        --     [5] = {
        --         recipes = {{"redgem", 1},{"orangegem", 1},{"yellowgem", 1},{"greengem", 1},{"bluegem", 1}},
        --     },
        -- ----------------------------------------------------

    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 各个等级
    local ret_table = {}
    for index, data in pairs(all_data) do
        ------------------------------------------------------------------
        --- 名字规则
            local new_prefab = this_prefab.."_lv"..index
        ------------------------------------------------------------------
        --- prefab 函数
            local fn = function()
                local inst = common_fn()
                inst.level = index
                if not TheWorld.ismastersim then
                    return inst
                end


                return inst
            end
        ------------------------------------------------------------------
        --- 配置物品
            local recipes = {}
            local debug_recipe = {{"redgem", 1},{"orangegem", 1},{"yellowgem", 1},{"greengem", 1},{"bluegem", 1}}
            if TBAT.DEBUGGING then
                for k, IngredientData in pairs(debug_recipe) do
                    table.insert(recipes,Ingredient(IngredientData[1],IngredientData[2]*index))
                end
            else            
                for k, IngredientData in pairs(data.recipes) do
                    table.insert(recipes,Ingredient(IngredientData[1],IngredientData[2]))
                end
            end
            CONSTRUCTION_PLANS[new_prefab] = recipes
            -- CONSTRUCTION_PLANS[new_prefab] = CONSTRUCTION_PLANS["mermthrone_construction"]
        ------------------------------------------------------------------
        table.insert(ret_table,Prefab(new_prefab, fn, assets))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret_table)
