-- 设置环境元表以访问全局变量
GLOBAL.setmetatable(env, {__index=function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

Assets = {}

-- 功能1：催熟疙瘩树果（oceantreenut）
local function FertilizeOceanTreeNut(inst)
    local tree = SpawnPrefab("oceantree_short")
    local x, _, z = inst.Transform:GetWorldPosition()
    if x and z then
        tree.Transform:SetPosition(x, 0, z)
        tree:sproutfn()
        inst:Remove()
        return true
    else
        print("错误！无法获取种子位置。Mistake! Unable to obtain seed location.")
        return false
    end
end

-- 功能2：催熟疙瘩树干（oceantree_pillar）使其垂下枝条
local function FertilizeOceanTreePillar(inst)
    local num_vines = math.random(2, 4)
    for i = 1, num_vines do
        inst:DoTaskInTime(math.random() * 0.5, function()
            local x, _, z = inst.Transform:GetWorldPosition()
            local radius_variance = TUNING.SHADE_CANOPY_RANGE_SMALL + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER - 6
            local vine = SpawnPrefab("oceanvine")
            vine.components.pickable:MakeEmpty()
            local theta = math.random() * 2 * math.pi
            local offset = 6 + radius_variance * math.random()
            vine.Transform:SetPosition(x + math.cos(theta) * offset, 0, z + math.sin(theta) * offset)
            vine:fall_down_fn()
            vine.SoundEmitter:PlaySound("dontstarve/movement/foley/hidebush")
        end)
    end
    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, 0.2, inst, 6)
    return true
end

-- 功能3：催熟古代树幼苗（ancienttree_<name>_sapling）
local function FertilizeAncientSapling(inst)
    if inst.components.growable then
        if inst.components.growable:IsGrowing() then
            inst.components.growable:DoGrowth()
            return true
        else
            return false
        end
    end
    return false
end

-- 功能4：催熟古代树果实（ancienttree_<name>）
local function FertilizeAncientTree(inst)
    if inst.components.pickable and not inst.components.pickable:CanBePicked() then
        inst.components.pickable:Regen()
        inst.SoundEmitter:PlaySound("dontstarve/common/fertilize")
        return true
    end
    return false
end

-- 功能5：催熟大理石豆(marbleshrub)成为marbleshrub_short
local function FertilizeMarbleBean(inst)
    local shrub = SpawnPrefab("marbleshrub_short")
    local x, _, z = inst.Transform:GetWorldPosition()
    if x and z then
        shrub.Transform:SetPosition(x, 0, z)
        -- 检查是否是sapling，如果是则直接开始生长，否则调用growfromseed
        if inst.prefab == "marblebean_sapling" and inst.components.growable then
            shrub.components.growable:StartGrowing()
        else
            shrub:growfromseed()
        end
        inst:Remove()
        return true
    else
        print("错误！无法获取大理石豆位置。Mistake! Unable to obtain marblebean location.")
        return false
    end
end

-- 功能6：催熟大理石灌木至下一阶段
local function FertilizeMarbleShrub(inst)
    if inst.components.growable and inst.components.growable.stage < 3 then
        inst.components.growable:DoGrowth()
        return true
    end
    return false
end

-- 定义统一的施肥动作
AddAction("FERTILIZE_TREE", "施肥", function(act)
    local target = act.target
    local item = act.invobject
    local doer = act.doer

    if not (target and item and item.prefab == "treegrowthsolution" and doer) then
        return false
    end

    if target.prefab == "oceantreenut" then
        if item.components.stackable then
            item.components.stackable:Get(1):Remove()
        else
            item:Remove()
        end
        return FertilizeOceanTreeNut(target)
    elseif target.prefab == "oceantree_pillar" then
        if item.components.stackable then
            item.components.stackable:Get(1):Remove()
        else
            item:Remove()
        end
        return FertilizeOceanTreePillar(target)
    elseif target:HasTag("silviculture") and target.prefab:find("ancienttree_") and target.prefab:find("_sapling") then
        if item.components.stackable and item.components.stackable:StackSize() >= 10 then
            item.components.stackable:Get(10):Remove()
            if FertilizeAncientSapling(target) then
                return true
            else
                local return_item = SpawnPrefab("treegrowthsolution")
                return_item.components.stackable:SetStackSize(10)
                doer.components.inventory:GiveItem(return_item, nil, doer:GetPosition())
                return false
            end
        else
            return false
        end
    elseif target:HasTag("ancienttree") and not target:HasTag("stump") then
        if FertilizeAncientTree(target) then
            if item.components.stackable then
                item.components.stackable:Get(1):Remove()
            else
                item:Remove()
            end
            return true
        else
            return false
        end
    elseif target.prefab == "marblebean_sapling" then
        if item.components.stackable then
            item.components.stackable:Get(1):Remove()
        else
            item:Remove()
        end
        return FertilizeMarbleBean(target)
    elseif target.prefab:find("marbleshrub") and target.prefab ~= "marbleshrub_tall" then
        if FertilizeMarbleShrub(target) then
            if item.components.stackable then
                item.components.stackable:Get(1):Remove()
            else
                item:Remove()
            end
            return true
        else
            return false
        end
    end

    return false
end)

-- 绑定动作到物品使用
AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
    if inst.prefab == "treegrowthsolution" and doer:HasTag("player") then
        if target.prefab == "oceantreenut" then
            table.insert(actions, ACTIONS.FERTILIZE_TREE)
        elseif target.prefab == "oceantree_pillar" then
            table.insert(actions, ACTIONS.FERTILIZE_TREE)
        elseif target:HasTag("silviculture") and target.prefab:find("ancienttree_") and target.prefab:find("_sapling") then
            table.insert(actions, ACTIONS.FERTILIZE_TREE)
        elseif target:HasTag("ancienttree") and not target:HasTag("stump") then
            table.insert(actions, ACTIONS.FERTILIZE_TREE)
        elseif target.prefab == "marblebean_sapling" then  -- 新增大理石豆判断
            table.insert(actions, ACTIONS.FERTILIZE_TREE)
        elseif target.prefab:find("marbleshrub") and target.prefab ~= "marbleshrub_tall" then  -- 新增大理石灌木判断
            table.insert(actions, ACTIONS.FERTILIZE_TREE)
        end
    end
end)

-- 设置状态图
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.FERTILIZE_TREE, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.FERTILIZE_TREE, "dolongaction"))

-- 修改 oceantree_pillar 以支持新功能
AddPrefabPostInit("oceantree_pillar", function(inst)
    if TheWorld.ismastersim then
        if not inst.dropcanopystuff then
            print("初始化警告：oceantree_pillar 缺少 dropcanopystuff 函数")
        end
        if not inst.SpawnMissingVines then
            print("初始化警告：oceantree_pillar 缺少 SpawnMissingVines 函数")
        end
    end
end)

-- 修改 glommer 以支持交易功能
AddPrefabPostInit("glommer", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    if not inst.components.trader then
        inst:AddComponent("trader")
    end

    inst.components.trader:SetAcceptTest(function(inst, item)
        return item.prefab == "wetgoop" or 
               item.prefab == "figkabab" or
               item.prefab == "frognewton" or
               item.prefab == "figatoni" or
               item.prefab == "koalefig_trunk"
    end)

    inst.components.trader.onaccept = function(inst, giver, item)
        local fuel_count = 1  -- 默认1个粘液
        if item.prefab == "koalefig_trunk" then
            fuel_count = 3  -- 无花果酿象鼻给3个
        end
        
        for i = 1, fuel_count do
            local fuel = SpawnPrefab("glommerfuel")
            if inst.sg then
                inst.sg:GoToState("goo", fuel)
            end
            fuel.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end

        if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

    inst.components.trader.onrefuse = function(inst, item)
        if inst.sg then
            inst.sg:GoToState("idle")
        end
        if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

    inst.components.trader.deleteitemonaccept = true
end)

-- 牛零食效果（增加3%驯化度）
AddPrefabPostInit("beefalotreat", function(inst)
    if not TheWorld.ismastersim then return inst end
    
    if inst.components.edible then
        inst.components.edible:SetOnEatenFn(function(inst, eater)
            if eater:HasTag("beefalo") and eater.components.domesticatable then
                local dom = eater.components.domesticatable
                dom:DeltaDomestication(0.03) -- 增加3%驯化度
                
                -- 调试信息（可选）
                print(string.format("[BeefaloTreat] 驯化度增加3%%, 当前: %.1f%%", 
                    dom:GetDomestication() * 100))
            end
        end)
    end
    
    return inst
end)

-- 无花果意面效果（增加5%驯化度）
AddPrefabPostInit("figatoni", function(inst)
    if not TheWorld.ismastersim then return inst end
    
    if inst.components.edible then
        inst.components.edible:SetOnEatenFn(function(inst, eater)
            if eater:HasTag("beefalo") and eater.components.domesticatable then
                local dom = eater.components.domesticatable
                dom:DeltaDomestication(0.05) -- 增加5%驯化度
                
                -- 调试信息（可选）
                print(string.format("[Figatoni] 驯化度增加5%%, 当前: %.1f%%", 
                    dom:GetDomestication() * 100))
            end
        end)
    end
    
    return inst
end)