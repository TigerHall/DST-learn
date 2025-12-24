-----------------------------------------------------------------------------------------------------------------------------------------
--[[

    hook 进 playercontroller 的 StartBuildPlacementMode ，让 皮肤参数进入 placer.SetBuilder 里面

    playercontroller.StartBuildPlacementMode 是放置建筑的时候SpawnPrefab( XXX_placer ) 的 官方API

]]--
-----------------------------------------------------------------------------------------------------------------------------------------

AddComponentPostInit("playercontroller", function(self)
    ----------------------------------------------------------------------------------------------------------------------------------
    --- client only
        local old_StartBuildPlacementMode = self.StartBuildPlacementMode
        self.StartBuildPlacementMode = function(self,recipe,skin,...)       --- client
            --- skin 参数来自 HUD那边，是个 string
            if TBAT.DEBUGGING then
                print("03_placer_com_hook  playercontroller",recipe and recipe.product,skin)
            end
            if recipe and type(recipe) == "table"  then
                if skin and TBAT.SKIN.SKINS_DATA_SKINS[skin] then
                    recipe.tbat_skin_name = skin
                else
                    recipe.tbat_skin_name = nil
                end
            end
            return old_StartBuildPlacementMode(self,recipe,skin,...)
        end
    ----------------------------------------------------------------------------------------------------------------------------------
    --- 客户端 回传 RPC数据
        local old_RemoteMakeRecipeFromMenu = self.RemoteMakeRecipeFromMenu
        self.RemoteMakeRecipeFromMenu = function(self,recipe, skin,...) --- client 那边，进入这个 func 的时候参数正常，RPC上传没数据
            if TBAT.DEBUGGING then
                print("03_placer_com_hook RemoteMakeRecipeFromMenu",recipe.product,skin)            
            end
            if self.inst.replica.tbat_com_skins_controller then
                self.inst.replica.tbat_com_skins_controller:SetSelecting(recipe.product,skin)
            end
            return old_RemoteMakeRecipeFromMenu(self,recipe, skin,...)
        end
    ----------------------------------------------------------------------------------------------------------------------------------
end)

AddComponentPostInit("placer",function(self)
    local old_SetBuilder = self.SetBuilder
    self.SetBuilder = function(self,builder,recipe,deployable_item,...)                ---- client

        ------------------------------------------------------------------------------------------------------------------
        --- 普通的从制作栏生成的 placer
            if type(recipe) == "table"  and builder and builder.replica.tbat_com_skins_controller then   
                    -- print("TBAT placer SetBuilder",recipe.tbat_skin_name)
                    ---------------------------------------------------------
                    --- 修改placer_inst的皮肤。
                    if recipe.tbat_skin_name then
                            local skin_name = recipe.tbat_skin_name
                            -- print("info SetBuilder ++ ",recipe)

                                if self.inst.AnimState and builder.replica.tbat_com_skins_controller:HasSkin(skin_name,recipe.product) then
                                    local skin_data = TBAT.SKIN.SKINS_DATA_SKINS[tostring(skin_name)] or {}
                                    if skin_data.bank and skin_data.build then
                                        self.inst.AnimState:SetBank(skin_data.bank)
                                        self.inst.AnimState:SetBuild(skin_data.build)
                                    end
                                    if skin_data.placer_fn then
                                        skin_data.placer_fn(self.inst)
                                    end
                                    if TBAT.DEBUGGING then
                                        print("placer.SetBuilder",skin_data.prefab_name,skin_name) 
                                    end                        
                                    builder.replica.tbat_com_skins_controller:SetSelecting(skin_data.prefab_name,skin_name)
                                end
                    else

                        -- print("fake error ",recipe)
                        -- for k, v in pairs(recipe) do
                        --     print(k,v)
                        -- end
                        --- 清掉服务端的数据。
                        local temp_prefab = recipe.product
                        builder.replica.tbat_com_skins_controller:SetSelecting(temp_prefab.prefab_name,nil)

                        
                    end
            end
        ------------------------------------------------------------------------------------------------------------------
        ---- 如果是放置物品类放置出来的
        ----  deployable_item.components.deployable.ondeploy = function(inst, pt, deployer, rot )
        ---- 如果是放置物放出来的，没法在这里进行皮肤切换，用放置物里的放置函数（上面这条）做相关处理
            if type(deployable_item) == "table" and deployable_item.replica.tbat_com_skin_data then
                local skin_name = deployable_item.replica.tbat_com_skin_data:GetCurrent()
                if TBAT.DEBUGGING then
                    print("TBAT SKIN deployable_item",deployable_item,skin_name)
                end
                if skin_name and self.inst.AnimState then
                    local skin_data = TBAT.SKIN.SKINS_DATA_SKINS[tostring(skin_name)] or {}
                    if skin_data.bank and skin_data.build then
                        self.inst.AnimState:SetBank(skin_data.bank)
                        self.inst.AnimState:SetBuild(skin_data.build)
                    end
                    if skin_data.placer_fn then
                        skin_data.placer_fn(self.inst)
                    end
                end
            end
        ------------------------------------------------------------------------------------------------------------------
        -- recipe = nil
        return old_SetBuilder(self,builder,recipe,deployable_item,...)
    end

end)

--------------------------------------------------------------------------------------------------------------
-- 处理 没洞穴的时候物品切换皮肤不成功的问题
    AddComponentPostInit("builder",function(self)
        if TheWorld.ismastersim and not TheNet:IsDedicated() then

            local remember_prefab = nil
            local remember_skin = nil
            
            local old_MakeRecipe = self.MakeRecipe
            self.MakeRecipe = function(self,recipe, pt, rot, skin, onsuccess,...)
                if skin and TBAT.SKIN.SKINS_DATA_SKINS[skin] and type(recipe) == "table" and recipe.product then
                    remember_prefab = recipe.product
                    remember_skin = skin
                end
                return old_MakeRecipe(self,recipe, pt, rot, skin, onsuccess,...)
            end

            local old_DoBuild = self.DoBuild
            self.DoBuild = function(self,recname, pt, rotation, skin,...)
                local recipe = GetValidRecipe(recname)
                if type(recipe) == "table" and recipe.product and recipe.product == remember_prefab then
                    skin = skin or remember_skin
                end
                remember_prefab = nil
                remember_skin = nil
                return old_DoBuild(self,recname,pt, rotation, skin,...)
            end


        end
    end)
--------------------------------------------------------------------------------------------------------------
---- 以下为调试追踪数据用的代码
if true then
    return
end
AddComponentPostInit("builder",function(self)
    if TBAT.DEBUGGING ~= true then
        return
    end
    -------------------------------------------------------------------------------------------
        local old_DoBuild = self.DoBuild
        self.DoBuild = function(self,recname, pt, rotation, skin,...)
            print("03_placer_com_hook builder DoBuild",recname,skin)   --- skin 得到nil ，往前hook func MakeRecipe 
            return old_DoBuild(self,recname,pt, rotation, skin,...)
        end
    -------------------------------------------------------------------------------------------

        local old_MakeRecipe = self.MakeRecipe
        self.MakeRecipe = function(self,recipe, pt, rot, skin, onsuccess,...)
            print("03_placer_com_hook builder MakeRecipe",recipe and recipe.product,skin) --- skin 还是得到nil ，继续往前 hook func MakeRecipeFromMenu/MakeRecipeAtPoint
            return old_MakeRecipe(self,recipe, pt, rot, skin, onsuccess,...)
        end
    -------------------------------------------------------------------------------------------
    ---- 【警告】疑似MakeRecipeFromMenu 函数被官方废弃，placer 的建筑 放置后不执行。在2023.07.17 发现官方改掉了API
        local old_MakeRecipeFromMenu = self.MakeRecipeFromMenu
        self.MakeRecipeFromMenu = function(self,recipe,skin,...)
            print("03_placer_com_hook builder MakeRecipeFromMenu",recipe and recipe.product,skin)    --- 确认有 skin 参数，  ValidateRecipeSkinRequest 函数造成问题
            return old_MakeRecipeFromMenu(self,recipe,skin,...)
        end
    -------------------------------------------------------------------------------------------
        local old_MakeRecipeAtPoint = self.MakeRecipeAtPoint    
        self.MakeRecipeAtPoint = function(self,recipe, pt, rot, skin,...)   
            print("03_placer_com_hook builder MakeRecipeAtPoint",recipe and recipe.product,skin)         ---- 没有得到参数，往上追踪到 networkclientrpc.lua 的 MakeRecipeAtPoint
            return old_MakeRecipeAtPoint(self,recipe, pt, rot, skin,...)
        end
    -------------------------------------------------------------------------------------------
end)

----------------- 用这个api 修改 replica 单纯是为了兼容其他MOD 
AddClassPostConstruct("components/builder_replica", function(self)
    if TBAT.DEBUGGING ~= true then
        return
    end

    local old_MakeRecipeAtPoint = self.MakeRecipeAtPoint
    self.MakeRecipeAtPoint = function(self,recipe, pt, rot, skin,...)
        print("03_placer_com_hook  MakeRecipeAtPoint replica",recipe and recipe.product,skin)
        return old_MakeRecipeAtPoint(self,recipe, pt, rot, skin,...)
    end

end)

