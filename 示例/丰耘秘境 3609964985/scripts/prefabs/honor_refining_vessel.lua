local Gtable = require("Gtable")

local assets =
{
    Asset("ANIM", Gtable.builds.honor_refining_vessel.anim),

    Asset("ATLAS", Gtable.builds.honor_refining_vessel.mapatlas),
    --Asset("IMAGE", Gtable.builds.honor_refining_vessel.mapimage),
    Asset("ATLAS", Gtable.builds.honor_refining_vessel.atlas), --加载物品栏贴图
    --Asset("IMAGE", Gtable.builds.honor_refining_vessel.image),

    Asset( "ANIM", 'anim/ui_zhijiang_4x4.zip'),--辉煌炼化容器界面用到的动画
     
    --辉煌炼化容器界面用到的容器背景图标
     Asset( "IMAGE", "images/slot_pot.tex" ), 
     Asset( "ATLAS", "images/slot_pot.xml" ),

}
local cooking = require("cooking")
local work_range = 12

local function spawnFX_magic(fx, target, x, y, z)
    -- 如果当前不是主服务器，直接返回
    if not TheWorld.ismastersim then return end 

    -- 生成特效对象
    local fx_throw = SpawnPrefab(fx) 

    -- 如果有目标对象，将特效位置设置为目标对象的位置
    if target then
        fx_throw.Transform:SetPosition(target.Transform:GetWorldPosition())
    else
        -- 否则，将特效位置设置为指定的坐标
        fx_throw.Transform:SetPosition(x, y, z)
    end

    -- 在1.5秒后移除特效对象
    fx_throw:DoTaskInTime(1.5, function()
        fx_throw:Remove()
    end)
end

local function SetProductSymbol(inst, product, overridebuild)
    -- 获取烹饪配方
    local recipe = cooking.GetRecipe("portablecookpot", product)
    -- 获取锅的等级
    local potlevel = recipe ~= nil and recipe.potlevel or nil
    -- 获取构建名称
    local build = (recipe ~= nil and recipe.overridebuild) or overridebuild or "cook_pot_food"
    -- 获取覆盖符号名称
    local overridesymbol = (recipe ~= nil and recipe.overridesymbolname) or product

    -- 根据锅的等级显示或隐藏不同的动画符号
    if potlevel == "high" then
        inst.AnimState:Show("swap_high")
        inst.AnimState:Hide("swap_mid")
        inst.AnimState:Hide("swap_low")
    elseif potlevel == "low" then
        inst.AnimState:Hide("swap_high")
        inst.AnimState:Hide("swap_mid")
        inst.AnimState:Show("swap_low")
    else
        inst.AnimState:Hide("swap_high")
        inst.AnimState:Show("swap_mid")
        inst.AnimState:Hide("swap_low")
    end

    -- 覆盖烹饪后的符号
    inst.AnimState:OverrideSymbol("swap_cooked", build, overridesymbol)
    -- 备用符号覆盖代码（已注释）
    -- inst.AnimState:OverrideSymbol("swap_cooked", "zhijiang_food", "zhijiang_veggie_tree")
end


local function onopen(inst)
    -- 检查实体是否没有被烧毁
    if not inst:HasTag("burnt") then
        local item6 = inst.components.container.slots[6]
        local item8 = inst.components.container.slots[8]

        if item6 or item8 then
            inst.AnimState:PlayAnimation("idle_full")
        else
            inst.AnimState:PlayAnimation("idle_empty")
        end
    -- 停止播放当前的声音
        inst.SoundEmitter:KillSound("snd")
        
        -- 播放烹饪锅打开的声音
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
        
    end
end

local function onclose(inst)
    inst.mod_fuel = inst.mod_fuel or 0
    if not inst:HasTag("burnt") then
        -- 如果 can_cook 为 false，表示不能烹饪
        if not inst.cancook  then
            -- 停止播放当前的声音
            inst.SoundEmitter:KillSound("snd")
            
            -- 获取容器的第6槽位的物品
            local first_cook = inst.components.container.slots[6]
            
            -- 如果第6槽位有物品
            if first_cook ~= nil then
                -- 播放“满”的动画
                inst.AnimState:PlayAnimation("idle_full")
                
                -- 设置产品符号
                SetProductSymbol(inst, first_cook.prefab, IsModCookingProduct("portablecookpot", first_cook.prefab) and first_cook.prefab or nil)
            else
                -- 播放“空”的动画
                inst.AnimState:PlayAnimation("idle_empty")
                
                -- 播放烹饪锅关闭的声音
                inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
            end 
        else
            -- 启用光源
            inst.Light:Enable(true)
            
            -- 播放烹饪循环动画
            if not inst.AnimState:IsCurrentAnimation("cooking_loop") then
                inst.AnimState:PlayAnimation("cooking_loop", true)
            end
            
            -- 停止播放当前的声音
            inst.SoundEmitter:KillSound("snd")
            
            -- 播放烹饪锅摇晃的声音
            if not inst.SoundEmitter:PlayingSound("snd") then
                inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
            end
        end
    end

end


local function onclose2(inst)
    inst.mod_fuel = inst.mod_fuel or 0
    if not inst.components.container:IsOpen() then
        if not inst:HasTag("burnt") then
            -- 如果 can_cook 为 false，表示不能烹饪
            if not inst.cancook  then
                -- 停止播放当前的声音
                inst.SoundEmitter:KillSound("snd")
                -- 获取容器的第6槽位的物品
                local first_cook = inst.components.container.slots[6]
                
                -- 如果第6槽位有物品
                if first_cook ~= nil then
                    -- 播放“满”的动画
                    inst.AnimState:PlayAnimation("idle_full")
                    
                    -- 设置产品符号
                    SetProductSymbol(inst, first_cook.prefab, IsModCookingProduct("portablecookpot", first_cook.prefab) and first_cook.prefab or nil)
                else
                    -- 播放“空”的动画
                    inst.AnimState:PlayAnimation("idle_empty")

                end 
            else
                -- 启用光源
                inst.Light:Enable(true)
                
                -- 播放烹饪循环动画
                if not inst.AnimState:IsCurrentAnimation("cooking_loop") then
                    inst.AnimState:PlayAnimation("cooking_loop", true)
                end

                if not inst.SoundEmitter:PlayingSound("snd") then
                    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
                end
            end
        end
    end
end



local function onhammered(inst, worker)
    -- 如果物体正在燃烧，先熄灭火焰
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    -- 掉落物品
    inst.components.lootdropper:DropLoot()
    -- 如果容器存在，丢弃所有物品
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    -- 生成崩塌特效
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    -- 移除物体
    inst:Remove()
end

local function onhit(inst, worker)
    -- 如果物体没有被烧毁
    if not inst:HasTag("burnt") then
        -- 播放受击动画
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        -- 如果容器存在，丢弃所有物品并关闭容器
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function onbuilt(inst)
    -- 播放建造动画
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_empty", false)
    -- 播放建造声音
    inst.SoundEmitter:PlaySound("dontstarve/common/cook_pot_craft")
end



local function onsave(inst, data)
    -- 保存燃烧状态
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
    -- 保存更新状态
    if data then
        data.mod_fuel = inst.mod_fuel 
    end
end

local function onload(inst, data)
    -- 加载燃烧状态
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
    -- 加载更新状态
    if data then
        inst.mod_fuel = data.mod_fuel 
    end
end


local function fn()
    local inst = CreateEntity() -- 创建一个新的实体

    inst.entity:AddTransform() -- 添加变换组件，用于位置、旋转和缩放
    inst.entity:AddAnimState() -- 添加动画状态组件，用于控制动画
    inst.entity:AddSoundEmitter() -- 添加声音发射器组件，用于播放声音
    inst.entity:AddMiniMapEntity() -- 添加小地图实体组件，用于在小地图上显示
    inst.entity:AddNetwork() -- 添加网络组件，用于网络同步
    inst.entity:AddLight() -- 添加光源组件，用于发光

    inst.Transform:SetScale(1, 1, 1) -- 设置实体的缩放比例

    inst:AddTag("structure") -- 添加标签“structure”，表示这是一个结构
    inst:AddTag("chest") -- 添加标签“chest”，表示这是一个箱子，通常用于存储物品
    --inst:AddTag("fridge") -- 添加标签“fridge”，表示这是一个冰箱，通常用于保存食物，减缓食物腐烂速度

    inst.AnimState:SetBank(Gtable.builds.honor_refining_vessel.bank) -- 设置动画集
    inst.AnimState:SetBuild(Gtable.builds.honor_refining_vessel.build) -- 设置动画材质
    inst.AnimState:PlayAnimation(Gtable.builds.honor_refining_vessel.playanim) -- 播放初始动画
    inst.scrapbook_anim = Gtable.builds.honor_refining_vessel.scrapbook_anim -- 设置剪贴簿动画
    inst.MiniMapEntity:SetIcon(Gtable.builds.honor_refining_vessel.minimapicon) -- 设置小地图图标

    MakeSnowCoveredPristine(inst) -- 使实体在雪地中覆盖干净

    inst.Light:Enable(false) -- 禁用光源
    inst.Light:SetRadius(.6) -- 设置光源半径
    inst.Light:SetFalloff(1) -- 设置光源衰减
    inst.Light:SetIntensity(.5) -- 设置光源强度
    inst.Light:SetColour(235/255,62/255,12/255) -- 设置光源颜色

    MakeObstaclePhysics(inst, .5) -- 设置障碍物物理属性，碰撞半径为0.5

    inst.entity:SetPristine() -- 设置实体为原始状态

    if not TheWorld.ismastersim then
        -- 在实体被复制（replicated）时，设置其容器组件的界面
        inst.OnEntityReplicated = function(inst) inst.replica.container:WidgetSetup("honor_refining_vessel_2x4") end
        return inst
    end

    inst.mod_fuel = 0 --初始化燃料



    inst:AddComponent("inspectable") -- 添加可检查组件
    inst:AddComponent("cookpotget") -- 自定义组件，用来触发右键获取
    inst:AddComponent("container") -- 添加容器组件
    inst.components.container:WidgetSetup("honor_refining_vessel_2x4") -- 设置容器界面
    inst.components.container.onopenfn = onopen -- 设置打开容器时的回调函数
    inst.components.container.onclosefn = onclose -- 设置关闭容器时的回调函数
    inst.components.container.skipclosesnd = true -- 跳过关闭声音
    inst.components.container.skipopensnd = true -- 跳过打开声音
    inst.components.container:EnableInfiniteStackSize(true) -- 启用无限堆叠大小

    inst:AddComponent("lootdropper") -- 添加掉落物品组件
    inst:AddComponent("workable") -- 添加可工作组件
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER) -- 设置工作动作为锤击
    inst.components.workable:SetWorkLeft(2) -- 设置工作剩余量
    inst.components.workable:SetOnFinishCallback(onhammered) -- 设置完成工作时的回调函数
    inst.components.workable:SetOnWorkCallback(onhit) -- 设置工作时的回调函数

    inst:AddComponent("hauntable") -- 添加可闹鬼组件
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY) -- 设置闹鬼值

    inst:ListenForEvent("onbuilt", onbuilt) -- 监听建造事件
    MakeSnowCovered(inst) -- 使实体在雪地中覆盖


    inst:DoPeriodicTask(0.1, function()
        onclose2(inst)
    end)

    inst:DoPeriodicTask(0.1, function()
        if not inst.components.container:IsOpen() then
            if inst.mod_fuel<=0 then
                local item2 = inst.components.container.slots[2]
                local item4 = inst.components.container.slots[4]

                if item2~= nil then
                    local items_number = item2.components.stackable and item2.components.stackable:StackSize()
                    local fuel_number = item2.fuelnumber 
                    inst.mod_fuel = inst.mod_fuel + fuel_number
                    if item2.components.stackable and items_number > 1 then
                        item2.components.stackable:SetStackSize(items_number - 1)
                    else
                        item2:Remove()
                    end
                else
                    if item4~= nil then
                        local items_number4 = item4.components.stackable and item4.components.stackable:StackSize()
                        local fuel_number4 = item4.fuelnumber4
                        inst.mod_fuel = inst.mod_fuel + fuel_number4
                        if item4.components.stackable and items_number4 > 1 then
                            item4.components.stackable:SetStackSize(items_number4 - 1)
                        else
                            item4:Remove()
                        end
                    end
                end
            end
        end
    end)

    inst:DoPeriodicTask(0.1, function()
        local can_cook = true -- 初始化 can_cook 变量为 true，表示可以烹饪
        local ingredient_prefabs = {} -- 初始化一个空表，用于存储食材的prefab
        -- 如果容器没有被打开
        if not inst.components.container:IsOpen() and inst.mod_fuel>0   then
            -- 遍历容器的四个槽位，检查是否有物品
            for i = 1, 7,2 do 
                local item = inst.components.container.slots[i]
                if item ~= nil then
                    table.insert(ingredient_prefabs, item.prefab) -- 将物品的 prefab 添加到 ingredient_prefabs 表中
                    can_cook = can_cook -- 如果有物品，保持 can_cook 为 true
                else
                    can_cook = false -- 如果没有物品，将 can_cook 设为 false
                end
            end

            if can_cook == true and inst.mod_fuel>0  then
                inst.cancook = true
            else
                inst.cancook = false
            end
        else
            inst.cancook = nil
        end
    end)



    inst:DoPeriodicTask(5, function()
        local ingredient_prefabs = {} -- 初始化一个空表，用于存储食材的prefab
        local can_cook = true -- 初始化 can_cook 变量为 true，表示可以烹饪

        -- 如果容器没有被打开
        if not inst.components.container:IsOpen() and inst.mod_fuel>0   then
            -- 遍历容器的四个槽位，检查是否有物品
            for i = 1, 7,2 do 
                local item = inst.components.container.slots[i]
                if item ~= nil then
                    table.insert(ingredient_prefabs, item.prefab) -- 将物品的 prefab 添加到 ingredient_prefabs 表中
                    can_cook = can_cook -- 如果有物品，保持 can_cook 为 true
                else
                    can_cook = false -- 如果没有物品，将 can_cook 设为 false
                end
            end


            -- 如果 can_cook 为 true，表示可以烹饪
            if can_cook == true and inst.mod_fuel>0  then
                inst.Light:Enable(true) -- 启用光源
                local product, cooktime = cooking.CalculateRecipe("portablecookpot", ingredient_prefabs) -- 计算烹饪结果和时间
                cooktime = TUNING.BASE_COOK_TIME * cooktime
                local recipe = cooking.GetRecipe("portablecookpot", product) -- 获取烹饪配方
                local stacksize = recipe and recipe.stacksize or 1 -- 获取堆叠大小，默认为1


                if recipe and inst.mod_fuel> cooktime then
                    inst.cancook = true
                    inst.mod_fuel = inst.mod_fuel - cooktime

                    local pdt_get = SpawnPrefab(product) -- 生成烹饪结果物品
                    if pdt_get and pdt_get.components.stackable then
                        pdt_get.components.stackable:SetStackSize(stacksize) -- 设置堆叠大小
                    end

                    if inst.components.container.slots[6] == nil then
                        inst.components.container:GiveItem(pdt_get, 6) -- 将烹饪结果物品放入第6格
                    elseif inst.components.container.slots[6] ~= nil  and inst.components.container.slots[6].prefab == pdt_get.prefab then
                        inst.components.container:GiveItem(pdt_get, 6) 
                    else
                        inst.components.container:GiveItem(pdt_get, 8) -- 将烹饪结果物品放入第8格
                    end -- 将烹饪结果物品放入容器

                    -- 遍历容器的1,3,5,7个槽位，减少物品的堆叠大小或移除物品
                    for i = 1, 7,2 do 
                        local item = inst.components.container.slots[i]
                        if item.components.stackable and item.components.stackable:StackSize() > 1 then
                            item.components.stackable:SetStackSize(item.components.stackable:StackSize() - 1)
                        else
                            item:Remove()
                        end
                    end
                else
                    inst.cancook = false
                    inst.mod_fuel = 0
                    inst.Light:Enable(false) -- 禁用光源
                    local first_cook = inst.components.container.slots[6] -- 获取容器的第6个槽位的物品

                    -- 如果第6个槽位有物品
                    if first_cook ~= nil then
                        inst.AnimState:PlayAnimation("idle_full") -- 播放“满”的动画
                        SetProductSymbol(inst, first_cook.prefab, IsModCookingProduct("portablecookpot", first_cook.prefab) and first_cook.prefab or nil) -- 设置产品符号
                    end
                end
            else
                inst.cancook = nil
                inst.Light:Enable(false) -- 禁用光源
                local first_cook = inst.components.container.slots[6] -- 获取容器的第6个槽位的物品

                -- 如果第6个槽位有物品
                if first_cook ~= nil then
                    inst.AnimState:PlayAnimation("idle_full") -- 播放“满”的动画
                    SetProductSymbol(inst, first_cook.prefab, IsModCookingProduct("portablecookpot", first_cook.prefab) and first_cook.prefab or nil) -- 设置产品符号
                end
            end
        end
    end)

    -- 保存/加载由一些预制变体扩展
    inst.OnSave = onsave -- 设置保存回调函数
    inst.OnLoad = onload -- 设置加载回调函数

    return inst
end

return  Prefab("honor_refining_vessel", fn, assets),
MakePlacer("honor_refining_vessel_placer", "zhijiang_cookpot", "zhijiang_cookpot", "idle_empty")