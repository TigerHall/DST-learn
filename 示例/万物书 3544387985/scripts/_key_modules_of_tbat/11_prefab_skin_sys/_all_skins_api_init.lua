-----------------------------------------------------------------------------------------------------------------------------------------
--[[
    利用部分官方API ，创建一套自己的API封装，暂时不做角色用的皮肤切换弹窗。
    建筑类利用  player:PushEvent("buildstructure", { item = ptbat, recipe = recipe, skin = skin })
    物品则利用  player:PushEvent("builditem", { item = ptbat, recipe = recipe, skin = skin, prototyper = self.current_prototyper }) 
    其中的 skin 参数为 string  ，来自 HUD 的选择
    bank build 全换掉，方便做更多不同的奇怪动画


    官方API数据流转路径 ：

        1、没placer ：
            PlayerController:RemoteMakeRecipeFromMenu -> builder:MakeRecipeFromMenu -> builder:MakeRecipe()
            -> self.inst:PushEvent("makerecipe", { recipe = recipe })  ->  action buffer 
            ->  playerinst.components.locomotor:PushAction -> builder:Dobuild
            -> SpawnPrefab - >    playerinst:PushEvent("builditem", 

        2、有placer （建筑类）: 
            预览的时候：
                PlayerController:StartBuildPlacementMode(recipe, skin)  ->
                SpawnPrefab(XXX_placer)  -> placer:SetBuilder(...)
            执行的时候：
                PlayerController:StartBuildPlacementMode(recipe, skin) with PREFAB_SKINS 和 PREFAB_SKINS_IDS ->
                -> PlayerController:DoActionButton()  -> player.replica.builder:MakeRecipeAtPoint -> rpc or client 使用 PREFAB_SKINS 和 PREFAB_SKINS_IDS 的index
                -> server side 服务端 ->
                ->  Builder:MakeRecipeAtPoint(recipe,  -> builder:MakeRecipe()
                -> self.inst:PushEvent("makerecipe", { recipe = recipe })  ->  action buffer 
                ->  playerinst.components.locomotor:PushAction -> builder:Dobuild
                -> SpawnPrefab - >   playerinst:PushEvent("buildstructure", { item

        3、deployable 物品有点特殊 ，需要单独处理部分相关函数。 可以考虑使用 replica 或者 net_string 传递参数


]]--
-----------------------------------------------------------------------------------------------------------------------------------------


modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/01_item_prefab_skins_api.lua") 
-- 封装皮肤系统

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/02_hook_player_prefab.lua") 
-- hook player 身上的各种API

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/03_placer_com_hook.lua") 
-- hook placer  的API

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/04_inventoryitem_com_hook.lua") 
-- hook inventoryitem  的API

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/05_named_com_hook.lua") 
-- hook named  的API

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/06_stackable_com_hook.lua") 
-- hook stackable  的API

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/07_reskin_tool_action.lua") 
-- hook 扫把更新 交互
modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/08_reskin_tool_upgrade.lua") 
-- hook 扫把更新 交互

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/09_default_skin_name_replacer.lua") 
-- 默认名字 替换模块

modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/100_recipe_and_unlock_debug.lua") 
-- debug
modimport("scripts/_key_modules_of_tbat/11_prefab_skin_sys/101_cdkey_input_debug.lua") 
-- debug input cdkey