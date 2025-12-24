-----------------------------------------------------------------------------------------------------------------------------------------
--[[

    和皮肤相关的两个官方table，index 转置而已。
        index 转置了
        （client）recipepopup.lua 制作栏相关的 列表调用 api ： GetSkinsList   GetSkinOptions   
        重要函数 ：（ client 端） TheInventory:CheckOwnershipGetLatest(item_type)  
        TheInventory 是个 userdata
        PREFAB_SKINS PREFAB_SKINS_IDS 里面只会列出已拥有的，未解锁的不会进入这两个列表里

    制作栏里的相关文本和贴图
        RecipePopup:GetSkinOptions()  可以改制作栏 里显示的 贴图/文本/文本颜色等 
        local colour = GetColorForItem(item)    ，文本颜色相关的预设 在 skinsutils.lua， 格式{R/255,G/255,B/255,A/255}
        local text_name = GetSkinName(item)
        local image_name = GetSkinInvIconName(item)
        贴图需要使用 函数 RegisterInventoryItemAtlas("images/inventoryimages/"..tex_name.. ".xml", tex_name..".tex") 注册过


    建筑类准备放置的时候，皮肤切换需要hook  PlayerController:StartBuildPlacementMode ，在 client 上
        server 上监听(builder 里 push 出来的) 
                    player:PushEvent("buildstructure", { item = ptbat, recipe = recipe, skin = skin })
                    ptbat:PushEvent("onbuilt", { builder = self.inst, pos = pt })
        非建筑类制作的时候 builder 里 push 出来  (server)
                    player:PushEvent("builditem", { item = ptbat, recipe = recipe, skin = skin, prototyper = self.current_prototyper })


    扫描得到的log：
        -- print("PREFAB_SKINS",PREFAB_SKINS["researchlab"])
        -- for k, v in pairs(PREFAB_SKINS["researchlab"]) do
        --     print(k,v)
        --     -- [01:10:44]: 1	researchlab_gothic	
        --     -- [01:10:44]: 2	researchlab_green	
        --     -- [01:10:44]: 3	researchlab_party	
        --     -- [01:10:44]: 4	researchlab_retro
        -- end
        -- print("PREFAB_SKINS_IDS",PREFAB_SKINS_IDS["researchlab"])
        -- for k, v in pairs(PREFAB_SKINS_IDS["researchlab"]) do
        --     print(k,v)
        --     -- [01:12:19]: researchlab_gothic	1	
        --     -- [01:12:19]: researchlab_retro	4	
        --     -- [01:12:19]: researchlab_green	2	
        --     -- [01:12:19]: researchlab_party	3	
        -- end
    
]]--
-----------------------------------------------------------------------------------------------------------------------------------------
-- 核心组件replica声明
    AddReplicableComponent("tbat_com_skins_controller")  -- 玩家身上的皮肤控制系统。
    AddReplicableComponent("tbat_com_skin_data")         -- 非玩家身上的皮肤控制系统
-----------------------------------------------------------------------------------------------------------------------------------------
-- 基础库封装
    TBAT.SKIN = Class()
    TBAT.SKIN.SKINS_DATA_SKINS = {}                --- index 为 skin_name
    TBAT.SKIN.SKINS_DATA_PREFABS = {}        --- index 为 prefab_name
        -- FWD_IN_PDT_MOD_SKIN.Add_Skin_Data_For_HUD = function(cmd_table)   ---- 【废弃函数】留在这做笔记
        --     -- cmd_table = {
        --     --     prefab_name = "",
        --     --     skin_name = "skin_name",
        --     --     bank = "bank",
        --     --     build = "build",
        --     --     atlas = "images/inventoryimages/npng_item_no_discounts_amulet.xml",
        --     --     image = "npng_item_no_discounts_amulet",    -- 不需要 .tex
        --     --     name = "XXX",        --- 切名字用的
        --     --     description = "XXX",        --- 皮肤的介绍
        --     --     name_color = {r/255,g/255,b/255,a/255},   --- fn 的返回值,或者string-index
        --     --     OverrideSymbol = {   --- 给武器类手持切换用的
        --     --         tar_layer = "",
        --     --         build = "",
        --     --         src_layer = "",
        --     --     },
        --     --     skin_link = "",    ---连携解锁用的,一起解锁这个皮肤。
        --     --     server_fn = function(inst)end, -- 切换到这个skin调用 。服务端
        --     --     client_fn = function(inst)end, -- 切换到这个skin调用 。客户端
        --     --     server_switch_out_fn = function(inst)end,  --- 切换离开这个skin调用 。服务端。用来解除某些特效、机制。
        --     --     placed_skin_name = "",        -- 给 inst.components.deployable.ondeploy  里生成切换用的
        --     --     placer_fn = function(inst)end, -- placer 里调用的
        --     --     unlock_announce_skip = nil,   -- 跳过解锁提示
        --     --     unlock_announce_data = {      -- 解锁提示,如果没有这个，则可直接显示 atlas + image
        --     --         bank = "tbat_eq_universal_baton_3",
        --     --         build = "tbat_eq_universal_baton_3",
        --     --         anim = "in_hand",
        --     --         scale = 0.5,
        --     --         offset = Vector3(0, 0, 0),
        --     --         fn = function(icon_anim,slot)end,
        --     --     }
        --     -- }    
        -- end
    function TBAT.SKIN:GET_ALL_SKINS_DATA()
        return self.SKINS_DATA_SKINS,self.SKINS_DATA_PREFABS
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- skin name colors
    TBAT.SKIN.SKIN_NAME_COLORS = {
        ["green"]   =       {0/255,200/255,0/255,1},
        ["blue"]    =       {0/255,128/255,255/255,1},
        ["pink"]    =       {255/255,0/255,127/255,1},
        ["pink2"]    =       {255/255,0/255,255/255,1},
        ["purple"] =        {153/255,51/255,255/255,1},
        ["red"]     =       {204/255,0/255,0/255,1},
    }
-----------------------------------------------------------------------------------------------------------------------------------------
--- IsItemId API HOOK : 处理log大量出现"Unknown skin"   【笔记】使用这个会造成往官方API写入非法数据，造成引擎级别的崩溃。
    -- local old_IsItemId = rawget(_G,"IsItemId")
    -- rawset(_G,"IsItemId",function(name,...)
    --     if TBAT.SKIN.SKINS_DATA_SKINS[name] then
    --         return true
    --     end
    --     return old_IsItemId(name,...)
    -- end)
-----------------------------------------------------------------------------------------------------------------------------------------
--- 新方案，hook 进 SpawnPrefab 里 , 处理log大量出现"Unknown skin"
    local TMP_SKINS_DATA_SKINS = TBAT.SKIN.SKINS_DATA_SKINS
    local old_SpawnPrefab = rawget(_G,"SpawnPrefab")
    rawset(_G,"SpawnPrefab",function(name,skin,...)
        if skin and TMP_SKINS_DATA_SKINS[skin] then
            skin = nil
        end
        return old_SpawnPrefab(name,skin,...)
    end)
-----------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤包，用于批量注册、解锁皮肤。
    TBAT.SKIN.SKIN_PACK = Class()
    TBAT.SKIN.SKIN_PACK._pack_data = {}
    function TBAT.SKIN.SKIN_PACK:Pack(pack_name,skins_list_or_skin_name)
        if self.__tempInst == nil then
            self.__tempInst = CreateEntity()
            self.__tempInst:DoTaskInTime(3,self.__tempInst.Remove)
        end
        self.__tempInst:DoTaskInTime(0,function()
            if TBAT.SKIN.SKINS_DATA_SKINS[pack_name] then
                --- 打包的索引名字不允许和皮肤名字一致。
                print("TBAT PCAK SKINS ERROR: pack_name:",pack_name)
                print("TBAT PCAK SKINS ERROR: pack_name:",pack_name)
                print("TBAT PCAK SKINS ERROR: pack_name:",pack_name)
                print("TBAT PCAK SKINS ERROR: pack_name:",pack_name)                
                print("TBAT PCAK SKINS ERROR: pack_name:",pack_name)                
                print("TBAT PCAK SKINS ERROR: pack_name:",pack_name)                
            else
                if TBAT.DEBUGGING then
                    print("[info][TBAT][pack skin]",pack_name,json.encode(skins_list_or_skin_name))
                end
                self:Pack_Internal(pack_name,skins_list_or_skin_name)
            end
        end)
    end
    function TBAT.SKIN.SKIN_PACK:Pack_Internal(pack_name,skins_list_or_skin_name)
        --- 做两种注册方式：批量注册，逐个注册。
        if type(skins_list_or_skin_name) == "table" and #skins_list_or_skin_name > 0 then
            if self._pack_data[pack_name] == nil then
                self._pack_data[pack_name] = skins_list_or_skin_name
            else
                for i,v in ipairs(skins_list_or_skin_name) do
                    table.insert(self._pack_data[pack_name],v)
                end
            end
        elseif type(skins_list_or_skin_name) == "string" then
            self._pack_data[pack_name] = self._pack_data[pack_name] or {}
            table.insert(self._pack_data[pack_name],skins_list_or_skin_name)
        end
    end
    function TBAT.SKIN.SKIN_PACK:GetPacked(pack_name)
        local ret_table = {}
        local temp_idx_list = {} -- 临时索引表，防止重复
        if self._pack_data[pack_name] then
            for i,skin_name in ipairs(self._pack_data[pack_name]) do
                if (TBAT.SKIN.SKINS_DATA_SKINS[skin_name] or PrefabExists(skin_name)) and not temp_idx_list[skin_name] then
                    table.insert(ret_table,skin_name)
                    temp_idx_list[skin_name] = true
                end
            end
        end
        return ret_table
    end
    function TBAT.SKIN.SKIN_PACK:IsPack(pack_name)
        if self._pack_data[pack_name] then
            return true,self:GetPacked(pack_name)
        end
        return false
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤赠送数据
    TBAT.SKIN.__default_unlock_list = {}
    TBAT.SKIN.__default_unlock_list_idx = {}
    function TBAT.SKIN:AddForDefaultUnlock(skin_name)
        table.insert(self.__default_unlock_list,skin_name)
        self.__default_unlock_list_idx[skin_name] = true
    end
    function TBAT.SKIN:GetDefaultUnlockList()
        return self.__default_unlock_list
    end
    TBAT.SKIN.__vip_unlock_list = {}
    function TBAT.SKIN:AddForVIPUnlock(skin_name)
        table.insert(self.__vip_unlock_list,skin_name)
    end
    function TBAT.SKIN:GetVIPUnlockList()
        return self.__vip_unlock_list
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- 添加皮肤数,SERVER-CLIENT都需要。
    function TBAT.SKIN:DATA_INIT(skins_data,prefab_name) ---- 用来初始化所有皮肤数据,不管有没有解锁
        ------------------------------------------
        ---- 转置一下参数表，避免重复添加
        if tostring(prefab_name) == "nil" or type(skins_data) ~= "table" then
            print("TBAT.SKIN:DATA_INIT  Error",prefab_name,skins_data)
            return
        end
        if TBAT.DEBUGGING then
            print("info TBAT.SKIN:DATA_INIT",prefab_name,skins_data)
        end
        for skin_name, cmd_table in pairs(skins_data) do
            skins_data[skin_name].prefab_name = prefab_name
            skins_data[skin_name].skin_name = skin_name
            self.SKINS_DATA_SKINS[tostring(cmd_table.skin_name)] = cmd_table
        end
        -- self.SKINS_DATA_PREFABS[tostring(prefab_name)] = skins_data
        -- 【笔记】更新API，让皮肤AI为添加型，而不是覆盖型
        self.SKINS_DATA_PREFABS[tostring(prefab_name)] = self.SKINS_DATA_PREFABS[tostring(prefab_name)] or {}
         for skin_name, cmd_table in pairs(skins_data) do
            self.SKINS_DATA_PREFABS[tostring(prefab_name)][tostring(cmd_table.skin_name)] = cmd_table
         end
        ----------------------------------------------------------------------
        --- 往 PREFAB_SKINS 和 PREFAB_SKINS_IDS 里添加表，避免UI在极端情况下（PlayerController:RemoteMakeRecipeFromMenu）
            PREFAB_SKINS[prefab_name] = PREFAB_SKINS[prefab_name] or {}
            PREFAB_SKINS_IDS[prefab_name] = PREFAB_SKINS_IDS[prefab_name] or {}
        ----------------------------------------------------------------------
    end
    function TBAT.SKIN:SetDefaultBankBuild(inst,bank,build)
        inst.__tbat_skin_default_data = {
            bank = bank,
            build = build,
        }
        if inst.AnimState == nil then
            inst.entity:AddAnimState()
        end
        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- 检查并警告名字过长
    if TBAT.DEBUGGING then
        AddPrefabPostInit("world",function(inst)
            if not TheWorld.ismastersim then
                return
            end
            inst:DoTaskInTime(5,function()
                local function is_linked_skin(skin_name)
                    for _,skin_data in pairs(TBAT.SKIN.SKINS_DATA_SKINS) do
                        if skin_data.skin_link == skin_name or skin_data.placed_skin_name == skin_name then
                            return true
                        end
                    end
                    return false
                end
                for skin_name,skin_data in pairs(TBAT.SKIN.SKINS_DATA_SKINS) do
                    if TBAT.SKIN.__default_unlock_list_idx[skin_name] == nil 
                        and #skin_name > 35 
                        and not is_linked_skin(skin_name)
                         then
                            local prefab = skin_data.prefab_name
                            local display_name = STRINGS.NAMES[string.upper(prefab)]
                            TheNet:Announce("【 ".. display_name .." 】 的皮肤名字过长: " .. skin_name)
                            print("[ERROR][SKIN_NAME_LEN_OVERSIZE] "..display_name.." , ".. prefab .." , " .. skin_name)
                    end
                    if PrefabExists(skin_name) then
                        print("[ERROR][TBAT-SKIN] Same Name about skin name and prefab name",skin_name)
                        TheNet:Announce("【 TBAT警告 】 存在皮肤名字和prefab名字相同: " .. skin_name)
                    end
                end
            end)
        end)
    end
-----------------------------------------------------------------------------------------------------------------------------------------
--- hook api 方便名字，贴图切换
    --- 获取 text 的颜色
    require("skinsutils")
    --- 【注意事项】科雷个哈比，重定义了 _G 的index ，只能用 rawget / rawset 来修改 全局函数
    local _tbat_old_GetColorForItem = rawget(_G,"GetColorForItem")
    rawset(_G,"GetColorForItem", function(item,...)
        -- print("GetColorForItem55555",item,type(item))
        local data = TBAT.SKIN.SKINS_DATA_SKINS[tostring(item)]
        if data then
            ------------------------------------------------------------------------------------
            --- 颜色函数
                if type(data.name_color) == "function" then
                    return data.name_color(item,...) or _tbat_old_GetColorForItem(item,...)
                end
            ------------------------------------------------------------------------------------
            --- 预设颜色索引
                if type(data.name_color) == "string" then
                    return TBAT.SKIN.SKIN_NAME_COLORS[data.name_color] or _tbat_old_GetColorForItem(item,...)
                end
            ------------------------------------------------------------------------------------
            return data.name_color or _tbat_old_GetColorForItem(item,...)
        else
            return _tbat_old_GetColorForItem(item,...)
        end
    end)
    ---- 获取 text
    local _tbat_old_GetSkinName = rawget(_G,"GetSkinName")
    rawset(_G,"GetSkinName", function(item,...)
        -- print("GetSkinName",item,type(item))
        local data = TBAT.SKIN.SKINS_DATA_SKINS[tostring(item)]
        if data then
            local ret_name = data.name or _tbat_old_GetSkinName(item,...)
            return ret_name
        else
            return  _tbat_old_GetSkinName(item,...)
        end
    end)
    ---- 获取贴图，贴图只能放 inventoryimages ，而且必须使用函数 RegisterInventoryItemAtlas("images/inventoryimages/"..tex_name.. ".xml", tex_name..".tex") 注册过
    local _tbat_old_GetSkinInvIconName = rawget(_G,"GetSkinInvIconName")
    rawset(_G,"GetSkinInvIconName", function(item,...)
        local data = TBAT.SKIN.SKINS_DATA_SKINS[tostring(item)]
        if data then
            return data.image or _tbat_old_GetSkinInvIconName(item,...)
        else
            return  _tbat_old_GetSkinInvIconName(item,...)
        end
    end)
    ---- 获取描述
    local _tbat_old_GetSkinDescription = rawget(_G,"GetSkinDescription")
    rawset(_G,"GetSkinDescription", function(item,...)
        local data = TBAT.SKIN.SKINS_DATA_SKINS[tostring(item)]
        if data then
            return data.description or data.name or _tbat_old_GetSkinDescription(item,...)
        end
        return  _tbat_old_GetSkinDescription(item,...)
    end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ValidateRecipeSkinRequest func 在 Builder:MakeRecipeFromMenu 影响参数 。返回 skin_name
    local ValidateRecipeSkinRequest__tbat_old = rawget(_G,"ValidateRecipeSkinRequest")
    rawset(_G,"ValidateRecipeSkinRequest",function(user_id, prefab_name, skin)
        local playerInst = UserToPlayer(user_id)
        if playerInst and playerInst.replica.tbat_com_skins_controller and playerInst.replica.tbat_com_skins_controller:HasSkin(skin,prefab_name) then
            return skin
        else
            return ValidateRecipeSkinRequest__tbat_old(user_id, prefab_name, skin)
        end
    end)
-----------------------------------------------------------------------------------------------------------------------------------------
--- 这里是检查皮肤拥有权的官方接口。貌似只在 client 端执行，UI上检查
    if TheInventory then
        if type(TheInventory) == "userdata" then

                        local temp_TheInventory = getmetatable(TheInventory).__index
                        -- CheckOwnershipGetLatest
                        local old_CheckOwnershipGetLatest = temp_TheInventory.CheckOwnershipGetLatest
                        temp_TheInventory.CheckOwnershipGetLatest = function(self,skin_name,...)
                            -- print("info TheInventory.CheckOwnershipGetLatest",skin_name)
                            if skin_name and ThePlayer and ThePlayer.replica.tbat_com_skins_controller and ThePlayer.replica.tbat_com_skins_controller:HasSkin(skin_name) then
                                return true ,0
                            end
                            return old_CheckOwnershipGetLatest(self,skin_name,...)
                        end

                        temp_TheInventory.HasSupportForOfflineSkins = function()
                            return true
                        end

        elseif type(TheInventory) == "table" then


                        local temp_TheInventory = TheInventory
                        -- CheckOwnershipGetLatest
                        local old_CheckOwnershipGetLatest = temp_TheInventory.CheckOwnershipGetLatest
                        temp_TheInventory.CheckOwnershipGetLatest = function(self,skin_name,...)
                            if skin_name and ThePlayer and ThePlayer.replica.tbat_com_skins_controller and ThePlayer.replica.tbat_com_skins_controller:HasSkin(skin_name) then
                                return true ,0
                            end
                            return old_CheckOwnershipGetLatest(self,skin_name,...)
                        end


                        temp_TheInventory.HasSupportForOfflineSkins = function()
                            return true
                        end
            

        end

    end
-----------------------------------------------------------------------------------------------------------------------------------------