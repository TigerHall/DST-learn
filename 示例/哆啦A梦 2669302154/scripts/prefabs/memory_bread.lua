--------------------------------
--[[ 记忆面包]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-03-13]]
--[[ @updateTime: 2022-03-13]]
--[[ @email: x7430657@163.com]]
--------------------------------

local assets =
{
    -- 这里动画文件需要注意下通道名称必须和prefab名称一致,才能再烹饪锅中显示
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB..".zip"),
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB..".tex"),
}
local prefabs =
{
}
--[[-- 名称方法
local function displayNameFn(inst)
    -- 默认名称
    local name = STRINGS.NAMES[string.upper(TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB)]
    --
    return name
end]]

local function onTeach(inst, learner)
    learner:PushEvent("learnrecipe", { teacher = inst, recipe = inst.memory_bread_teacher_recipe })
end

--[[是否可以在物品栏中使用]]
local function canuse(inst, doer, target, actions, right)
    if inst and not inst:HasTag("blueprinted") and target and target.prefab == "blueprint" then
        return true
    end
    return false
end
--[[物品栏右键记忆]]
local function onuse(act)
    local valid = false
    local inst = act.invobject
    local target = act.target
    if inst and not inst:HasTag("blueprinted") and target and target.prefab == "blueprint"
        and target.components.teacher and target.components.teacher.recipe
    then
        -- 不能直接添加teacher组件,会覆盖吃的动作
        --inst:AddComponent("teacher")
        --inst.components.teacher.onteach = onTeach
        --inst.components.teacher:SetRecipe(target.components.teacher.recipe)
        inst.memory_bread_teacher_recipe = target.components.teacher.recipe
        inst.components.named:SetName(STRINGS.NAMES[string.upper(target.components.teacher.recipe)].." "..STRINGS.NAMES[string.upper(TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB)])
        inst:AddTag("blueprinted")
        valid = true
    end
    return valid
end

local function teach(inst,target)
    if inst.memory_bread_teacher_recipe == nil then
        return false
    elseif target.components.builder == nil then
        return false
    elseif target.components.builder:KnowsRecipe(inst.memory_bread_teacher_recipe) then
        return false, "KNOWN"
    elseif not target.components.builder:CanLearn(inst.memory_bread_teacher_recipe) then
        return false, "CANTLEARN"
    else
        target.components.builder:UnlockRecipe(inst.memory_bread_teacher_recipe)
        onTeach(inst,target)
        return true
    end
end

--local function onEatenFn(inst,eater)
local function onEatenFn(inst,data)
    local eater = data.eater
    --if inst and eater and inst.components.teacher and inst.components.teacher.recipe then
    if inst and eater and inst.memory_bread_teacher_recipe then
        teach(inst,eater)
    end
end




local function fn()

    local inst = CreateEntity() -- 创建实体
    inst.entity:AddTransform() -- 添加xyz形变对象
    inst.entity:AddAnimState() -- 添加动画状态
    inst.entity:AddNetwork() -- 添加这一行才能让所有客户端都能看到这个实体

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB) -- 地上动画
    inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB) -- 材质包，就是anim里的zip包
    inst.AnimState:PlayAnimation("idle") -- 默认播放哪个动画

    MakeInventoryFloatable(inst)

    inst:AddTag("preparedfood")

    -- inst.displaynamefn = displayNameFn

    inst:AddComponent("doraemon_click_useitem")
    inst.components.doraemon_click_useitem.canuse = canuse
    inst.components.doraemon_click_useitem.onuse = onuse

    --------------------------------------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    --------------------------------------------------------------------------

    --preparedfood
    inst:AddComponent("inspectable") -- 可检查组件
    inst:AddComponent("inventoryitem") -- 物品组件

    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB..".xml" -- 在背包里的贴图

    inst:AddComponent("edible") -- 可食物组件
    inst.components.edible.foodtype = FOODTYPE.GOODIES -- 废弃素食,避免有些人物吃不了
    --inst.components.edible:SetOnEatenFn(onEatenFn)


    inst:AddComponent("perishable") -- 可腐烂的组件
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food" -- 腐烂后变成腐烂食物

    inst.components.edible.hungervalue = TUNING.CALORIES_MED
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.sanityvalue = TUNING.SANITY_TINY
    -- 去除堆叠
    --inst:AddComponent("stackable") -- 可堆叠
    --inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst:AddComponent("named")
    inst.components.named:SetName(STRINGS.NAMES[string.upper(TUNING.DORAEMON_TECH.MEMORY_BREAD_UNMEMORY)].." "..STRINGS.NAMES[string.upper(TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB)])


    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    inst:AddComponent("bait")
    inst:AddComponent("tradable")
    inst:ListenForEvent("oneaten",onEatenFn)
    return inst
end

return Prefab(TUNING.DORAEMON_TECH.MEMORY_BREAD_PREFAB, fn, assets, prefabs)