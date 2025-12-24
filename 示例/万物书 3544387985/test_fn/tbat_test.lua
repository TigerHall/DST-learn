
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------ 界面调试
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
    local Menu = require "widgets/menu"
    local TEMPLATES = require "widgets/redux/templates"
    local ScrollableList = require "widgets/scrollablelist"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local flg,error_code = pcall(function()
    print("WARNING:PCALL START +++++++++++++++++++++++++++++++++++++++++++++++++")
    local x,y,z = ThePlayer.Transform:GetWorldPosition()
    require("debugcommands")
    ----------------------------------------------------------------------------------------------------------------
    --- sg 捕捉
        -- if ThePlayer.__sg_event == nil then
        --     ThePlayer.__sg_event = true
        --     ThePlayer:ListenForEvent("newstate",function(_,_table)
        --         print("sg:",_table and _table.statename)
        --     end)
        -- end
    ----------------------------------------------------------------------------------------------------------------
    --- 地皮调试
        -- local x, y, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
        -- local tile_x,tile_y = TBAT.MAP:GetTileXYByWorldPoint(x,y,z)
        -- TheWorld.Map:SetTile(tile_x,tile_y,WORLD_TILES[string.upper("tbat_turf_water_lily_cat")])
        -- TheWorld.Map:SetTile(tile_x,tile_y,WORLD_TILES[string.upper("OCEAN_COASTAL")])
        -- TBAT.MAP:SetTileWithIndexAtPoint(x,y,z,"OCEAN_COASTAL")
        -- SpawnPrefab("tbat_turf_water_lily_cat_ground_fx").Transform:SetPosition(x,y,z)
        -- TheWorld.Map:SetTile(tile_x,tile_y,WORLD_TILES[string.upper("CHARLIE_VINE")])
        -- print(TBAT.MAP:GetTileAtPoint(x,y,z))
        -- for k, v in pairs(WORLD_TILES) do
        --     if v == TBAT.MAP:GetTileAtPoint(x,y,z) then
        --         print(k)
        --     end
        -- end
        -- print(x,y,z)
        -- print(TBAT.MAP:GetTileAtPoint(x,0,z) == WORLD_TILES[string.upper("deciduous")])

    ----------------------------------------------------------------------------------------------------------------
    ----
        -- local backpack = ThePlayer:TBAT_Get_Pet_Eyebone_Backpack()
       
    ----------------------------------------------------------------------------------------------------------------
    --- 雷击
        -- local inst = ThePlayer
        -- for i = 1, 30, 1 do
        --     inst:DoTaskInTime(i*0.3,function(inst)
        --         TheWorld:PushEvent("ms_sendlightningstrike", Vector3(inst.Transform:GetWorldPosition()))                
        --     end)
        -- end
    ----------------------------------------------------------------------------------------------------------------
    ---
        -- local inst = TheSim:FindFirstEntityWithTag("tbat_building_twin_goslings")
        
    ----------------------------------------------------------------------------------------------------------------
    ----
        -- local inst = TheSim:FindFirstEntityWithTag("tbat_eq_fantasy_apple_oversized_waxed")
        -- local bank,build,anim = TBAT.FNS:GetBankBuildAnim(inst)
        -- print(bank,build,anim)
        -- inst.AnimState:PlayAnimation("wax_oversized",true)
        -- ThePlayer.SoundEmitter:PlayingSound("farming/common/farm/grow_full")
    ----------------------------------------------------------------------------------------------------------------
    ----  密语模块调试 158,187, 98
        -- local this_prefab = "tbat_building_four_leaves_clover_crane_lv2"            
        -- local function WhisperTo(inst,player_or_userid,str)
        --     TBAT.FNS:Whisper(player_or_userid,{
        --         icondata = this_prefab ,
        --         sender_name = TBAT:GetString2(this_prefab,"name"),
        --         s_colour = {158/255,187/255,98/255},
        --         message = str,
        --         m_colour = {252/255,246/255,231/255},
        --     })
        -- end
        -- WhisperTo(ThePlayer,ThePlayer,"愿四叶草祝福你")
    ----------------------------------------------------------------------------------------------------------------
    --- 
        -- local inst = TheSim:FindFirstEntityWithTag("oceantrawler")
        -- local inst = TheSim:FindEntities(x, 0, z, 10, {"tbat_pet_lavender_kitty"})[1]

        -- -- inst.sg:GoToState("playful1")
        -- -- inst.sg:GoToState("playful2")
        -- -- inst.sg:GoToState("playful3")
        -- inst.sg:GoToState("playful4")
        -- print(inst.sg:HasStateTag("busy"))
    ----------------------------------------------------------------------------------------------------------------
    --- 
        
        -- TBAT.create_skin_ui_announce = create_skin_ui_announce
    ----------------------------------------------------------------------------------------------------------------
    ----
        -- local skin_data = {
        --     -- skin_name = "tbat_eq_universal_baton_3",
        --     skin_name = "tbat_building_cloud_wooden_sign_7",
        --     -- is_pack = true,
        -- }
        -- -- -- local skin_data = {
        -- -- --     skin_name = "tbat_eq_universal_baton_pack",
        -- -- --     is_pack = true,
        -- -- --     list = {
        -- -- --         "tbat_eq_universal_baton_2",
        -- -- --         "tbat_eq_universal_baton_3",
        -- -- --     }
        -- -- -- }
        -- -- -- -- create_skin_ui_announce(skin_data)

        -- local skin_data = {
        --     skin_name = "tbat_building_bunny_wooden_sign_owners",
        --     is_pack = true,
        --     list = TBAT.SKIN.SKIN_PACK:GetPacked("tbat_building_bunny_wooden_sign_owners")
        -- }
        -- ThePlayer.components.tbat_com_rpc_event:PushEvent("tbat_event.skin_unlock_announce",skin_data)

    ----------------------------------------------------------------------------------------------------------------
    --- 
        
        -- TheWorld:DoTaskInTime(1,function()
        
        --     VisitURL("https://forums.kleientertainment.com/klei-bug-tracker/dont-starve-together/")
        
        -- end)
    ----------------------------------------------------------------------------------------------------------------
    ---
        -- -- ----------------------------------------------------------------------------------------------------------------
        -- -- --- 解锁全部图鉴的方法
        --     local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
        --     local plant_prefab = "tbat_farm_plant_fantasy_peach_mutated"
        --     -- -- local plant_prefab = "tbat_food_fantasy_peach"
        --     local plant_def = PLANT_DEFS[plant_prefab]
        --     local plantregistryinfo = plant_def.plantregistryinfo
        --     for i = 1, #plantregistryinfo, 1 do
        --         local crash_flag = pcall(function()
        --             ThePlantRegistry:LearnPlantStage("tbat_farm_plant_fantasy_apple_mutated",i)
        --         end)
        --         if not crash_flag then
        --             pcall(function()
        --                 ThePlantRegistry:LearnPlantStage("tbat_farm_plant_fantasy_apple_mutated",plant_def.plant_type_tag)
        --             end)
        --         end
        --     end
        -- -- ----------------------------------------------------------------------------------------------------------------



    ----------------------------------------------------------------------------------------------------------------
    ---
        -- TBAT.DisplayedSummarySlot = function(root,plant_prefab,plant_def)
        --     --------------------------------------------------------
        --     --- 隐藏不需要的元素
        --         for k, v in pairs(root.children) do
        --             for k1, v1 in pairs(v.children) do
        --                 local check_str = tostring(v1)
        --                 if string.find(check_str, "Image") == nil
        --                     or string.find(check_str, "locked.tex")
        --                     then
        --                     v1:Hide()
        --                 else
        --                     print(check_str)
        --                 end

        --             end
        --         end
        --     --------------------------------------------------------
        --         local text_info = root:AddChild(Text(CODEFONT,26,"水母知道些什么",{ 255/255 , 255/255 ,255/255 , 1}))
        --     --------------------------------------------------------
        -- end
        -- TBAT.DisplayedUnknownPage = function(root,plant_prefab)
        --     local text_info = root:AddChild(Text(CODEFONT,30,"水母知道些什么",{ 255/255 , 255/255 ,255/255 , 1}))
        -- end
        -- TBAT.DisplayFarmPlantPage = function(root,plant_prefab)
        --     --------------------------------------------------------
        --     ---
        --         print("info DisplayFarmPlantPage",plant_prefab)
        --     --------------------------------------------------------
        --     --- 隐藏不需要的元素
        --         -- print(root.root)
        --         for k, v in pairs(root.root.children) do
        --             local check_str = tostring(v)
        --             print(check_str,k,v)
        --             if v ~= root.back_button then
        --                 v:Hide()
        --             end
        --         end
        --     --------------------------------------------------------
        --         local text_info = root.root:AddChild(Text(CODEFONT,30,"水母知道些什么",{ 255/255 , 255/255 ,255/255 , 1}))
        --     --------------------------------------------------------
        -- end
    ----------------------------------------------------------------------------------------------------------------
    ---
        -- ThePlayer.components.tbat_com_client_side_data:SheetSet("tbat_test_sheet","test_key",666)
        -- ThePlayer.components.tbat_com_client_side_data:SheetGetByCallback("plantregistry","plants",function(inst,data)
        --     print(data)
        -- end)

        local test_plant_prefab = "tbat_farm_plant_fantasy_apple_mutated"

        -- ThePlayer.components.plantregistryupdater:LearnPlantStage("tbat_farm_plant_fantasy_apple_mutated",1)

            local plants = nil
        	TheSim:GetPersistentString("plantregistry", function(load_success, data)
                if load_success and data ~= nil then
                    local success, plant_registry = RunInSandboxSafeCatchInfiniteLoops(data)
                    if success then
                        plants = plant_registry.plants
                    end
                end
            end)
            for k,v in pairs(plants[test_plant_prefab]) do
                print(k,v)
            end
    ----------------------------------------------------------------------------------------------------------------
    print("WARNING:PCALL END   +++++++++++++++++++++++++++++++++++++++++++++++++")
end)

if flg == false then
    print("Error : ",error_code)
end

-- dofile(resolvefilepath("test_fn/tbat_test.lua"))
-- TBAT:Test()