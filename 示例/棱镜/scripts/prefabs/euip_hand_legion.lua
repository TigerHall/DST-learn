local TOOLS_L = require("tools_legion")
local prefs = {}
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --专门放各个prefab独特的变量

fns.GetAssets = function(name, other)
    local sets = {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end

fns.CommonFn = function(inst, bank, build, anim, isloop)
    inst.entity:AddTransform() --添加坐标系机制
    inst.entity:AddAnimState() --添加动画机制
    inst.entity:AddNetwork() --添加网络机制

    MakeInventoryPhysics(inst) --设置物理机制

    inst.AnimState:SetBank(bank) --动画的bank：骨架+运动轨迹
    inst.AnimState:SetBuild(build or bank) --动画的build：贴图+贴图通道
    inst.AnimState:PlayAnimation(anim or "idle", isloop) --播放的动画

    inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制
end
fns.ServerFn = function(inst, img, OnEquip, OnUnequip)
    inst:AddComponent("inspectable") --可检查组件

    -- inst:AddComponent("tradable")

    inst:AddComponent("inventoryitem") --物品栏物品组件，有了这个组件，你才能把这个物品捡起放到物品栏里
    inst.components.inventoryitem.imagename = img
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..img..".xml"

    inst:AddComponent("equippable") --可装备组件，有了这个组件，它才能被装备
    -- inst.components.equippable.equipslot = EQUIPSLOTS.HANDS --默认就是手部
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
end

fns.SetWeapon = function(inst, damage, OnAttack)
    inst:AddComponent("weapon") --武器组件，能设置攻击力
    inst.components.weapon:SetDamage(damage)
    if OnAttack ~= nil then
        inst.components.weapon:SetOnAttack(OnAttack)
    end
end
fns.SetFiniteUses = function(inst, uses, OnFinished)
    inst:AddComponent("finiteuses") --耐久次数组件
    inst.components.finiteuses:SetMaxUses(uses)
    inst.components.finiteuses:SetUses(uses)
    inst.components.finiteuses:SetOnFinished(OnFinished or inst.Remove)
end
fns.SetPerishable = function(inst, time, replacement, onperish) --新鲜度组件
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(time)
    if replacement ~= nil then
        inst.components.perishable.onperishreplacement = replacement
    end
    if onperish ~= nil then
        inst.components.perishable:SetOnPerishFn(onperish)
    end
    inst.components.perishable:StartPerishing()
end
fns.SetFuel = function(inst, value)
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = value or TUNING.MED_FUEL
end
fns.SetDeployable = function(inst, ondeploy, mode, spacing) --摆放组件
    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    if mode ~= nil then
        inst.components.deployable:SetDeployMode(mode)
    end
    inst.components.deployable:SetDeploySpacing(spacing or DEPLOYSPACING.LESS)
end

fns.OnLandedClient_new = function(self, ...)
    if self.OnLandedClient_legion ~= nil then
        self.OnLandedClient_legion(self, ...)
    end
    if self.floatparam_l ~= nil then
        self.inst.AnimState:SetFloatParams(self.floatparam_l, 1, self.bob_percent)
    end
end
fns.SetFloatable = function(inst, float) --漂浮组件
    MakeInventoryFloatable(inst, float[2], float[3], float[4])
    if float[1] ~= nil then
        local floater = inst.components.floater
        if floater.OnLandedClient_legion == nil then
            floater.OnLandedClient_legion = floater.OnLandedClient
            floater.OnLandedClient = fns.OnLandedClient_new
        end
        floater.floatparam_l = float[1]
    end
end

fns.Decor_owner = function(inst, furniture)
    if inst._onownerchange ~= nil then
        inst._onownerchange(inst)
    end
end
fns.SetFurnitureDecor_comm = function(inst) --装饰组件前置
    inst.entity:AddFollower() --能当装饰品需要这个
    inst:AddTag("furnituredecor") --能当装饰品
end
fns.SetFurnitureDecor_serv = function(inst, ondecor) --装饰组件
    inst:AddComponent("furnituredecor")
    if ondecor ~= nil then
        inst.components.furnituredecor.onputonfurniture = ondecor
    end
end

--------------------------------------------------------------------------
--[[ 永不凋零 ]]
--------------------------------------------------------------------------

local uses_never = 250
local atk_never = 59.5

local function ChangeSymbol_never(inst, owner)
    if inst._dd ~= nil then
        if inst.isbroken_l then
            TOOLS_L.hand_on(owner, inst._dd.build2, inst._dd.file2)
        else
            TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
        end
    else
        if inst.isbroken_l then
            TOOLS_L.hand_on(owner, "swap_neverfade_broken", "swap_neverfade_broken")
        else
            TOOLS_L.hand_on(owner, "swap_neverfade", "swap_neverfade")
        end
    end
end
local function UpdateImg_never(inst)
    if inst._dd == nil then
        if inst.isbroken_l then
            --改变物品栏图片，先改atlasname，再改贴图
            inst.components.inventoryitem.atlasname = "images/inventoryimages/neverfade_broken.xml"
            inst.components.inventoryitem:ChangeImageName("neverfade_broken")
        else
            inst.components.inventoryitem.atlasname = "images/inventoryimages/neverfade.xml"
            inst.components.inventoryitem:ChangeImageName("neverfade")
        end
    else
        if inst.isbroken_l then
            inst.components.inventoryitem.atlasname = inst._dd.img_atlas2
            inst.components.inventoryitem:ChangeImageName(inst._dd.img_tex2)
            if inst._dd.doanim then
                inst.AnimState:PlayAnimation("idle_broken")
            end
        else
            inst.components.inventoryitem.atlasname = inst._dd.img_atlas
            inst.components.inventoryitem:ChangeImageName(inst._dd.img_tex)
            if inst._dd.doanim then
                inst.AnimState:PlayAnimation("idle")
            end
        end
    end
end
local function OnEquip_never(inst, owner) --装备武器时
    ChangeSymbol_never(inst, owner)
    inst.components.deployable:SetDeployMode(DEPLOYMODE.NONE) --装备时去除可栽种功能
    -- if owner:HasTag("equipmentmodel") then return end --假人
end
local function OnUnequip_never(inst, owner) --放下武器时
    TOOLS_L.hand_off(inst, owner)
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT) --卸下时恢复可摆栽种功能
end
local function OnAttack_never(inst, owner, target) --攻击时
    if target == nil or not target:IsValid() then
        return
    end
    inst.atkcounter_l = inst.atkcounter_l + 1
    if inst.atkcounter_l < 9 then
        return
    else --如果达到9次，尝试添加buff
        inst.atkcounter_l = 0
    end

    local skin = inst._dd and inst._dd.butterfly or nil
    if owner.legion_numblessing == nil or owner.legion_numblessing < 3 then --装备者最多3只庇佑蝴蝶
        owner:AddDebuff("buff_l_butterflybless", "buff_l_butterflybless", { max = 3, skin = skin })
    else
        local x, y, z = owner.Transform:GetWorldPosition()
        local distsq = 625 --25半径
        local players = {}
        local num = 0
        for _, v in ipairs(AllPlayers) do
            if v ~= owner and v.entity:IsVisible() and
                not (v.components.health:IsDead() or v:HasTag("playerghost")) and
                (v.legion_numblessing == nil or v.legion_numblessing < 2) and --其他人最多2只庇佑蝴蝶
                v:GetDistanceSqToPoint(x, y, z) < distsq
            then
                table.insert(players, v)
                num = num + 1
            end
        end
        if num <= 0 then --无人可加时，增加武器耐久
            if inst.components.finiteuses:GetPercent() < 1 then
                inst.components.finiteuses:Repair(7)
            end
            return
        end
        local theone = players[math.random(num)]
        theone:AddDebuff("buff_l_butterflybless", "buff_l_butterflybless", { max = 2, skin = skin })
    end
end
local function OnFinished_never(inst)
    if not inst.isbroken_l then
        inst.isbroken_l = true
        -- inst.atkcounter_l = 0 --损坏时不清除攻击次数
        inst.components.weapon:SetDamage(17)
        inst.components.weapon:SetOnAttack(nil)
        UpdateImg_never(inst)
        if inst.components.equippable:IsEquipped() then
            local owner = inst.components.inventoryitem.owner
            if owner ~= nil then
                ChangeSymbol_never(inst, owner)
                if owner.SoundEmitter ~= nil then --发出破碎的声音
                    owner.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/repair")
                end
            end
        end
        inst:AddTag("broken") --这个标签会让名称显示加入“损坏”前缀
        inst:PushEvent("percentusedchange", { percent = 0 }) --界面需要更新百分比
    end
end
local function OnDeploy_never(inst, pt, deployer, rot) --这里是右键种植时的函数
    local tree = SpawnPrefab("neverfadebush")
    if tree ~= nil then
        inst.components.skinedlegion:SetLinkedSkin(tree, "bush", deployer)
        tree.Transform:SetPosition(pt:Get())

        local percent = inst.components.finiteuses:GetPercent()
        inst:Remove()
        tree.components.pickable:OnTransplant()
        if percent > 0 then
            tree.components.pickable:LongUpdate(
                math.min(TUNING.TOTAL_DAY_TIME*2, TUNING.TOTAL_DAY_TIME*3*percent)
            )
        end
        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
        end
    end
end
local function OnSave_never(inst, data)
	if inst.atkcounter_l > 0 then
		data.atkcounter_l = inst.atkcounter_l
	end
end
local function OnLoad_never(inst, data)
	if data ~= nil then
		if data.atkcounter_l ~= nil then
			inst.atkcounter_l = data.atkcounter_l
		end
	end
end

local foliageath_data_never = {
    image = "foliageath_neverfade", atlas = "images/inventoryimages/foliageath_neverfade.xml",
    bank = nil, build = nil, anim = "neverfade", isloop = nil,
    fn_recovercheck = function(inst, tag)
        return inst.components.finiteuses:GetPercent() < 1
    end,
    fn_recover = function(inst, dt, player, tag)
        if not inst.foliageath_data.fn_recovercheck(inst, tag) then
            return
        end
        local value = dt * uses_never/(TUNING.TOTAL_DAY_TIME*3)
        if value < 0.001 then
            return
        end
        inst.components.finiteuses:Repair(value)
        if inst.isbroken_l and inst.components.finiteuses:GetUses() >= 1 then
            inst.isbroken_l = nil
            inst:RemoveTag("broken")
            inst.components.weapon:SetDamage(atk_never)
            inst.components.weapon:SetOnAttack(OnAttack_never)
            UpdateImg_never(inst)
        end
    end
}

table.insert(prefs, Prefab("neverfade", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "neverfade", nil, nil, nil)
    inst:AddTag("sharp") --该标签跟攻击音效有关
    inst:AddTag("pointy") --该标签跟攻击音效有关
    -- inst:AddTag("hide_percentage") --该标签能让耐久比例不显示出来
    inst:AddTag("deployedplant")
    inst:AddTag("show_broken_ui") --装备损坏后展示特殊物品栏ui
    inst:AddTag("weapon")
    LS_C_Init(inst, "neverfade", true)

    inst.entity:SetPristine()
    --此处截断：往下的代码是仅服务器运行，往上的代码是服务器和客户端都会运行的
    if not TheWorld.ismastersim then return inst end

    -- inst.isbroken_l = false
    inst.atkcounter_l = 0
    inst.foliageath_data = foliageath_data_never

    fns.ServerFn(inst, "neverfade", OnEquip_never, OnUnequip_never)
    fns.SetWeapon(inst, atk_never, OnAttack_never)
    fns.SetFiniteUses(inst, uses_never, OnFinished_never)
    fns.SetDeployable(inst, OnDeploy_never, DEPLOYMODE.PLANT, nil)
    MakeHauntableLaunch(inst) --作祟相关函数

    inst:ListenForEvent("ls_update", UpdateImg_never)

    inst.OnSave = OnSave_never
    inst.OnLoad = OnLoad_never

    return inst
end, fns.GetAssets("neverfade", {
    Asset("ANIM", "anim/swap_neverfade.zip"),
    Asset("ANIM", "anim/swap_neverfade_broken.zip"),
    Asset("ATLAS", "images/inventoryimages/neverfade_broken.xml"),
    Asset("IMAGE", "images/inventoryimages/neverfade_broken.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/neverfade_broken.xml", 256)
}), {
    "neverfadebush", "buff_l_butterflybless"
}))

--------------------------------------------------------------------------
--[[ 带刺蔷薇 ]]
--------------------------------------------------------------------------

local foliageath_data_rose = {
    image = "foliageath_rosorns", atlas = "images/inventoryimages/foliageath_rosorns.xml",
    bank = nil, build = nil, anim = "rosorns", isloop = nil
}

local function OnEquip_rose(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on(owner, "swap_rosorns", "swap_rosorns")
    end
    if owner:HasTag("equipmentmodel") then return end --假人

    --TIP: "onattackother"事件在 targ.components.combat:GetAttacked 之前，所以能提前改攻击配置
    owner:ListenForEvent("onattackother", TOOLS_L.UndefendedATK)
end
local function OnUnequip_rose(inst, owner)
    TOOLS_L.hand_off(inst, owner)
    owner:RemoveEventCallback("onattackother", TOOLS_L.UndefendedATK)
end
local function OnAttack_rose(inst, owner, target)
    if inst._dd ~= nil and inst._dd.atkfn ~= nil and target ~= nil and target:IsValid() then
        inst._dd.atkfn(inst, owner, target)
    end
end

table.insert(prefs, Prefab("rosorns", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "rosorns", nil, nil, nil)
    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("show_spoilage") --显示新鲜度
    inst:AddTag("icebox_valid") --能装进冰箱
    inst:AddTag("weapon")
    LS_C_Init(inst, "rosorns", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.foliageath_data = foliageath_data_rose

    fns.ServerFn(inst, "rosorns", OnEquip_rose, OnUnequip_rose)
    fns.SetWeapon(inst, 51, OnAttack_rose)
    fns.SetPerishable(inst, TUNING.TOTAL_DAY_TIME*8, nil, inst.Remove)
    MakeHauntableLaunchAndPerish(inst)

    return inst
end, fns.GetAssets("rosorns", { Asset("ANIM", "anim/swap_rosorns.zip") }), nil))

--------------------------------------------------------------------------
--[[ 蹄莲翠叶 ]]
--------------------------------------------------------------------------

local foliageath_data_lily = {
    image = "foliageath_lileaves", atlas = "images/inventoryimages/foliageath_lileaves.xml",
    bank = nil, build = nil, anim = "lileaves", isloop = nil
}

local function OnEquip_lily(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on(owner, "swap_lileaves", "swap_lileaves")
    end
end
local function OnAttack_lily(inst, owner, target)
    if
        target ~= nil and target:IsValid() and
        (target.components.health == nil or not target.components.health:IsDead()) and
        not target:HasAnyTag("wall", "structure", "balloon")
    then
        target:AddDebuff("buff_l_merciful", "buff_l_merciful", { max = TUNING.SEG_TIME*6 }) --这种方式最多只加3分钟
    end
end

table.insert(prefs, Prefab("lileaves", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "lileaves", nil, nil, nil)
    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
    inst:AddTag("weapon")
    LS_C_Init(inst, "lileaves", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.foliageath_data = foliageath_data_lily

    fns.ServerFn(inst, "lileaves", OnEquip_lily, TOOLS_L.hand_off)
    fns.SetWeapon(inst, 51, OnAttack_lily)
    fns.SetPerishable(inst, TUNING.TOTAL_DAY_TIME*8, nil, inst.Remove)
    MakeHauntableLaunchAndPerish(inst)

    return inst
end, fns.GetAssets("lileaves", { Asset("ANIM", "anim/swap_lileaves.zip") }), { "buff_l_merciful" }))

--------------------------------------------------------------------------
--[[ 兰草花穗 ]]
--------------------------------------------------------------------------

local atk_orchid_area = TUNING.BASE_SURVIVOR_ATTACK*0.7
local foliageath_data_orchid = {
    image = "foliageath_orchitwigs", atlas = "images/inventoryimages/foliageath_orchitwigs.xml",
    bank = nil, build = nil, anim = "orchitwigs", isloop = nil
}

local function OnEquip_orchid(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on(owner, "swap_orchitwigs", "swap_orchitwigs")
    end
end
local function OnAttack_orchid(inst, owner, target)
    if target ~= nil and target:IsValid() then
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local snap = SpawnPrefab(inst._dd and inst._dd.atkfx or "impact_orchid_fx")
        if snap ~= nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            local angle = -math.atan2(z1 - z, x1 - x)
            snap.Transform:SetPosition(x1, y1, z1)
            snap.Transform:SetRotation(angle * RADIANS)
        end

        local tags_cant
        local validfn
        if TheNet:GetPVPEnabled() then
            tags_cant = TOOLS_L.TagsCombat3()
            validfn = TOOLS_L.MaybeEnemy_me
        else
            tags_cant = TOOLS_L.TagsCombat3({ "player" })
            validfn = TOOLS_L.MaybeEnemy_player
        end

        local dmg, spdmg, stimuli
        local ents = TheSim:FindEntities(x1, y1, z1, 6.5, { "_combat" }, tags_cant)
        for _, ent in ipairs(ents) do
            if ent ~= target and ent ~= owner and ent:IsValid() and ent.entity:IsVisible() then
                --为啥官方要这样写，难道是 owner 会因为那些受击者的反伤导致自身失效？
                if owner ~= nil and (not owner:IsValid() or owner.components.combat == nil) then
                    owner = nil
                end
                tags_cant = 3.5 + ent:GetPhysicsRadius(0)
                if
                    ent:GetDistanceSqToPoint(x1, y1, z1) < tags_cant * tags_cant --这里的距离算上了生物的体积半径
                    and validfn(owner, ent, true)
                then
                    --Tip：范围性伤害还是加个判断！防止打到不该打的对象
                    if owner ~= nil then
                        if owner.components.combat:IsValidTarget(ent) then
                            dmg, spdmg, stimuli = TOOLS_L.CalcDamage(owner, ent, inst, nil, nil, atk_orchid_area, nil, true)
                            ent.components.combat:GetAttacked(owner, dmg, inst, stimuli, spdmg)
                        end
                    elseif ent.components.combat:CanBeAttacked() then
                        ent.components.combat:GetAttacked(inst, atk_orchid_area, nil, nil, nil)
                    end
                end
            end
        end
    end
end

table.insert(prefs, Prefab("orchitwigs", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "orchitwigs", nil, nil, nil)
    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
    inst:AddTag("weapon")
    LS_C_Init(inst, "orchitwigs", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.foliageath_data = foliageath_data_orchid

    fns.ServerFn(inst, "orchitwigs", OnEquip_orchid, TOOLS_L.hand_off)
    fns.SetWeapon(inst, TUNING.BASE_SURVIVOR_ATTACK*0.9, OnAttack_orchid)
    fns.SetPerishable(inst, TUNING.TOTAL_DAY_TIME*8, nil, inst.Remove)
    MakeHauntableLaunchAndPerish(inst)

    return inst
end, fns.GetAssets("orchitwigs", { Asset("ANIM", "anim/swap_orchitwigs.zip") }), { "impact_orchid_fx" }))

--------------------------------------------------------------------------
--[[ 多变的云 ]]
--------------------------------------------------------------------------

local function FixSymbol_bookweather(owner, data) --因为书籍的攻击贴图会因为读书而被替换，所以这里重新覆盖一次
    if data and data.statename == "attack" then
        -- owner.AnimState:OverrideSymbol("book_open", "book_weather", "book_open")
        owner.AnimState:OverrideSymbol("book_closed", "book_weather", "book_closed") --书籍攻击贴图在这里面
    end
end
local function OnEquip_bookweather(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object") --清除上一把武器的贴图效果，因为一般武器卸下时都不清除贴图
    owner.AnimState:OverrideSymbol("book_open", "book_weather", "book_open")
    owner.AnimState:OverrideSymbol("book_closed", "book_weather", "book_closed")
    -- owner.AnimState:OverrideSymbol("book_open_pages", "book_weather", "book_open_pages")

    if owner:HasTag("equipmentmodel") then return end --假人

    TOOLS_L.AddTag(owner, "ignorewet", inst.prefab)
    inst:ListenForEvent("newstate", FixSymbol_bookweather, owner)
end
local function OnUnequip_bookweather(inst, owner)
    TOOLS_L.hand_off(inst, owner)

    --还原书的贴图
    owner.AnimState:OverrideSymbol("book_open", "player_actions_uniqueitem", "book_open")
    owner.AnimState:OverrideSymbol("book_closed", "player_actions_uniqueitem", "book_closed")
    -- owner.AnimState:OverrideSymbol("book_open_pages", "player_actions_uniqueitem", "book_open_pages")

    TOOLS_L.RemoveTag(owner, "ignorewet", inst.prefab)
    inst:RemoveEventCallback("newstate", FixSymbol_bookweather, owner)
end
local function OnAttack_bookweather(inst, owner, target)
    if target ~= nil and target:IsValid() then
        SpawnPrefab("waterballoon_splash").Transform:SetPosition(target.Transform:GetWorldPosition())
        inst.components.wateryprotection:SpreadProtection(target) --潮湿度组件增加潮湿

        if target.components.health ~= nil and not target.components.health:IsDead() and
            not target:HasTag("likewateroffducksback")
        then
            if target.components.inventoryitem ~= nil then --物品组件增加潮湿
                target.components.inventoryitem:AddMoisture(TUNING.OCEAN_WETNESS)
                return
            end

            if target.task_l_iswet == nil then
                if target:HasTag("wet") then
                    return
                end
                target:AddTag("wet") --标签方式增加潮湿
            else
                target.task_l_iswet:Cancel()
            end
            target.task_l_iswet = target:DoTaskInTime(15, function()
                target:RemoveTag("wet")
                target.task_l_iswet = nil
            end)
        end
    end
end
local function OnWateryProtection_bookweather(inst, x, y, z)
    inst.components.finiteuses:Use(1)
end
local function ConsumeUse_bookweather(self)
    self.inst.components.finiteuses:Use(20) --可以使用15次
end

local function OnRead_bookweather(inst, reader)
    -- if TheWorld.state.israining or TheWorld.state.issnowing then
    --     TheWorld:PushEvent("ms_forceprecipitation", false)
    -- else
    --     TheWorld:PushEvent("ms_forceprecipitation", true)
    -- end
    if TheWorld.state.precipitation ~= "none" then
        TheWorld:PushEvent("ms_forceprecipitation", false)
    else
        TheWorld:PushEvent("ms_forceprecipitation", true)
    end

    local x, y, z = reader.Transform:GetWorldPosition()
    local size = TILE_SCALE

    for i = x-size, x+size do
        for j = z-size, z+size do
            if TheWorld.Map:GetTileAtPoint(i, 0, j) == WORLD_TILES.FARMING_SOIL then
                TheWorld.components.farming_manager:AddSoilMoistureAtPoint(i, y, j, 100)
            end
        end
    end

    return true
end
local function OnPeruse_bookweather(inst, reader)
    if reader.prefab == "wurt" then
        if TheWorld.state.israining or TheWorld.state.issnowing then --雨雪天时，书中全是关于放晴的字眼，沃特不喜欢
            inst.components.book:SetPeruseSanity(-TUNING.SANITY_LARGE)
            reader.components.talker:Say(GetString(reader, "ANNOUNCE_READ_BOOK","BOOK_WEATHER_SUNNY"))
        else --晴天时，书中全是关于下雨的字眼，沃特好喜欢
            inst.components.book:SetPeruseSanity(TUNING.SANITY_LARGE)
            reader.components.talker:Say(GetString(reader, "ANNOUNCE_READ_BOOK","BOOK_WEATHER_RAINY"))
        end
    else
        if reader.peruse_weather ~= nil then
            reader.peruse_weather(reader)
        end
        if reader.components.talker ~= nil then
            reader.components.talker:Say(GetString(reader, "ANNOUNCE_READ_BOOK","BOOK_WEATHER"))
        end
    end

    return true
end

table.insert(prefs, Prefab("book_weather", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "book_weather", nil, nil, nil)
    inst:AddTag("book") --加入book标签就能使攻击时使用人物的书本攻击的动画
    inst:AddTag("bookcabinet_item") --能放入书柜的标签
    inst:AddTag("weapon")
    MakeInventoryFloatable(inst, "med", 0.1, 0.75)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.swap_build = "book_weather"
    inst.swap_prefix = "book"

    fns.ServerFn(inst, "book_weather", OnEquip_bookweather, OnUnequip_bookweather)
    fns.SetWeapon(inst, 50, OnAttack_bookweather)
    fns.SetFiniteUses(inst, 300, nil)
    fns.SetFuel(inst, nil)

    inst:AddComponent("wateryprotection")
    inst.components.wateryprotection.extinguishheatpercent = TUNING.WATERBALLOON_EXTINGUISH_HEAT_PERCENT
    inst.components.wateryprotection.temperaturereduction = TUNING.WATERBALLOON_TEMP_REDUCTION
    inst.components.wateryprotection.witherprotectiontime = TUNING.WATERBALLOON_PROTECTION_TIME
    inst.components.wateryprotection.addwetness = TUNING.WATERBALLOON_ADD_WETNESS
    inst.components.wateryprotection.onspreadprotectionfn = OnWateryProtection_bookweather
    if TheNet:GetPVPEnabled() then
        inst.components.wateryprotection:AddIgnoreTag("ignorewet") --PVP，防止使用者被打湿
    else
        inst.components.wateryprotection:AddIgnoreTag("player") --PVE，防止所有玩家被打湿
    end

    inst:AddComponent("book")
    inst.components.book:SetOnRead(OnRead_bookweather)
    inst.components.book:SetOnPeruse(OnPeruse_bookweather)
    inst.components.book:SetReadSanity(-TUNING.SANITY_LARGE) --读书的精神消耗
    -- inst.components.book:SetPeruseSanity() --阅读的精神消耗/增益
    inst.components.book:SetFx("fx_book_rain", "fx_book_rain_mount")
    inst.components.book.ConsumeUse = ConsumeUse_bookweather

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("book_weather"), { "waterballoon_splash", "fx_book_rain", "fx_book_rain_mount" }))

--------------------------------------------------------------------------
--[[ 幻象法杖 ]]
--------------------------------------------------------------------------

if CONFIGS_LEGION.DRESSUP then
    local function OnFinished_staffpink(inst)
        if inst._dd ~= nil and inst._dd.endfn ~= nil then
            inst._dd.endfn(inst, nil)
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
        inst:Remove()
    end
    local function OnEquip_staffpink(inst, owner)
        if inst._dd ~= nil then
            TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
            if inst._dd.startfn ~= nil then
                inst._dd.startfn(inst, owner)
            end
        else
            TOOLS_L.hand_on(owner, "swap_pinkstaff", "swap_pinkstaff")
        end
    end
    local function OnUnequip_staffpink(inst, owner)
        if inst._dd ~= nil and inst._dd.endfn ~= nil then
            inst._dd.endfn(inst, owner)
        end
        TOOLS_L.hand_off(inst, owner)
    end
    local function DressUpItem(staff, target)
        local caster = staff.components.inventoryitem.owner
        if caster ~= nil and caster.components.dressup ~= nil then
            if target == nil then --解除幻化（右键装备栏的法杖）
                caster.components.dressup:TakeOffAll()
            elseif target == caster then --解除幻化（右键玩家自己）
                caster.components.dressup:TakeOffAll()
            else                  --添加幻化
                local didit = caster.components.dressup:PutOn(target)
                if didit then
                    caster.SoundEmitter:PlaySound("dontstarve/common/staff_dissassemble")
                    if caster.components.sanity ~= nil then
                        caster.components.sanity:DoDelta(-10)
                    end
                    staff.components.finiteuses:Use(1)
                end
            end
        end
    end
    local function DressUpTest(doer, target, pos)
        if target == nil then --解除幻化，也是可以生效的
            return true
        elseif target == doer then --对自己施法：解除幻化
            return true
        elseif not target.legiontag_nodress and DRESSUP_DATA_LEGION[target.prefab] ~= nil then
            return true
        end
        return false
    end

    table.insert(prefs, Prefab("pinkstaff", function()
        local inst = CreateEntity()
        inst.entity:AddSoundEmitter()
        fns.CommonFn(inst, "pinkstaff", nil, "anim", nil)
        LS_C_Init(inst, "pinkstaff", true)
        inst:AddTag("nopunch") --这个标签的作用应该是让本身没有武器组件的道具用武器攻击的动作，而不是用拳头攻击的动作

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.fxcolour = { 255/255, 80/255, 173/255 }

        fns.ServerFn(inst, "pinkstaff", OnEquip_staffpink, OnUnequip_staffpink)
        fns.SetFiniteUses(inst, 30, OnFinished_staffpink)

        inst:AddComponent("spellcaster")
        inst.components.spellcaster.canuseontargets = true
        inst.components.spellcaster.canusefrominventory = true
        inst.components.spellcaster:SetSpellFn(DressUpItem)
        inst.components.spellcaster:SetCanCastFn(DressUpTest)

        MakeHauntableLaunch(inst)

        return inst
    end, fns.GetAssets("pinkstaff", { Asset("ANIM", "anim/swap_pinkstaff.zip") }), nil))
end

--------------------------------------------------------------------------
--[[ 芬布尔斧 ]]
--------------------------------------------------------------------------

local atk_fimbulaxe = TUNING.BASE_SURVIVOR_ATTACK*0.4 --13.6

local function OnFinished_fimbulaxe(inst)
    inst.AnimState:PlayAnimation("used")
    inst:ListenForEvent("animover", inst.Remove)
    if inst._dd ~= nil and inst._dd.thrownendfn ~= nil then
        inst._dd.thrownendfn(inst)
    end
    if inst.returntask ~= nil then
        inst.returntask:Cancel()
        inst.returntask = nil
    end
end
local function OnEquip_fimbulaxe(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on(owner, "fimbul_axe", "swap_base")
    end
end
local function OnDropped_fimbulaxe(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.components.inventoryitem.pushlandedevents = true
    inst.components.inventoryitem.canbepickedup = true
    inst:PushEvent("on_landed")
    if inst._dd ~= nil and inst._dd.thrownendfn ~= nil then
        inst._dd.thrownendfn(inst)
    end
end
local function OnThrown_fimbulaxe(inst, owner, target)
    if owner and owner.SoundEmitter ~= nil then
        owner.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_throw")
    end
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.components.inventoryitem.pushlandedevents = false
    inst.components.inventoryitem.canbepickedup = false
    if inst._dd ~= nil and inst._dd.thrownfn ~= nil then
        inst._dd.thrownfn(inst, owner, target)
    end
end
local function ReturnToOwner_fimbulaxe(inst, owner)
    OnDropped_fimbulaxe(inst)
    if owner ~= nil and owner:IsValid() and not owner:HasTag("playerghost") and
        owner.components.health ~= nil and not owner.components.health:IsDead() --玩家还活着，自动接住
    then
        --如果使用者已装备手持武器，就放进物品栏，没有的话就直接装备上
        if not owner.components.inventory:GetEquippedItem(inst.components.equippable.equipslot) then
            owner.components.inventory:Equip(inst)
        else
            owner.components.inventory:GiveItem(inst)
        end
    end
end
local function GiveSomeShock(inst, owner, target, doshock, hittarget) --击中时的特殊效果
    local givelightning = false
    local tags_cant
    local tags_one
    local validfn
    if TheNet:GetPVPEnabled() then
        tags_cant = TOOLS_L.TagsCombat3({ "lightningblocker" }) --排除了水中木
        validfn = TOOLS_L.MaybeEnemy_me
    else
        tags_cant = TOOLS_L.TagsCombat3({ "lightningblocker", "player" })
        validfn = TOOLS_L.MaybeEnemy_player
    end
    if doshock then
        tags_one = { "_combat", "shockable", "CHOP_workable" }
    else
        tags_one = { "_combat", "CHOP_workable" }
    end

    local x, y, z
    if target ~= nil and target:IsValid() then
        x, y, z = target.Transform:GetWorldPosition()
    else
        target = nil
        x, y, z = inst.Transform:GetWorldPosition()
    end
    if owner ~= nil and not owner:IsValid() then
        owner = nil
    end

    local dmg, spdmg, stimuli
    local ents = TheSim:FindEntities(x, y, z, 6.5, nil, tags_cant, tags_one)
    for _, v in ipairs(ents) do
        if v ~= owner and v:IsValid() and v.entity:IsVisible() then
            --为啥官方要这样写，难道是 owner 会因为那些受击者的反伤导致自身失效？
            if owner ~= nil and (not owner:IsValid() or owner.components.combat == nil) then
                owner = nil
            end
            if v.components.combat ~= nil then
                if (hittarget or v ~= target) or doshock then
                    tags_cant = 3.5 + v:GetPhysicsRadius(0)
                    if
                        v:GetDistanceSqToPoint(x, y, z) < tags_cant * tags_cant --这里的距离算上了生物的体积半径
                        and validfn(owner, v, true)
                    then
                        if (hittarget or v ~= target) and v.components.combat:CanBeAttacked(owner) then
                            if owner ~= nil then
                                dmg, spdmg, stimuli = TOOLS_L.CalcDamage(owner, v, inst, inst, nil, nil, nil, true)
                                v.components.combat:GetAttacked(owner, dmg, inst, stimuli, spdmg)
                            else
                                v.components.combat:GetAttacked(inst, atk_fimbulaxe, nil, "electric", nil)
                            end
                        end
                        if doshock and v.components.shockable ~= nil and math.random() < 0.3 then
                            givelightning = true
                            v.components.shockable:Shock(6)
                        end
                    end
                end
            elseif v.components.workable ~= nil and v.components.lightningblocker == nil then --直接破坏可以砍的物体
                if v.components.workable:CanBeWorked() and v.components.workable:GetWorkAction() == ACTIONS.CHOP then
                    local numworks = 5
                    local recoil
                    if owner ~= nil and owner.components.workmultiplier ~= nil then
                        numworks = numworks * (owner.components.workmultiplier:GetMultiplier(ACTIONS.CHOP) or 1)
                    end
		            recoil, numworks = v.components.workable:ShouldRecoil(owner, inst, numworks)
                    v.components.workable:WorkedBy_Internal(owner or inst, numworks)
                end
            end
        end
    end

    if givelightning then
        if inst._dd ~= nil and inst._dd.lightningfn ~= nil then
            inst._dd.lightningfn(inst, owner, target)
            return
        end
        if not TheWorld:HasTag("cave") then
            local lightning = SpawnPrefab("fimbul_lightning")
            lightning.Transform:SetPosition(x, y, z)
        end
        local cracklebase = SpawnPrefab("fimbul_cracklebase_fx")
        cracklebase.Transform:SetPosition(x, y, z)
    end
end
local function DelayReturnToOwner(inst, owner, target)
    inst.returntask = inst:DoTaskInTime(0.6, function(inst)
        inst.returntask = inst:DoTaskInTime(0.4, function(inst)
            ReturnToOwner_fimbulaxe(inst, owner)
            inst.returntask = nil
        end)
        GiveSomeShock(inst, owner, target, false, true)
    end)
end
local function OnPreHit_fimbulaxe(inst, owner, target) --击中前
    GiveSomeShock(inst, owner, target, true, false)
end
local function OnHit_fimbulaxe(inst, owner, target) --击中后
    if inst:IsValid() and inst.components.finiteuses:GetUses() > 0 then --耐久可能是用完了
        DelayReturnToOwner(inst, owner, target)
    end
end
local function OnMiss_fimbulaxe(inst, owner, target)
    if owner == target then
        ReturnToOwner_fimbulaxe(inst, owner)
    else
        DelayReturnToOwner(inst, owner, target)
    end
end
local function OnLightning_fimbulaxe(inst) --因为拿在手上会有"INLIMBO"标签，所以装备时并不会吸引闪电，只有放在地上时才会
    GiveSomeShock(inst, nil, nil, true, true)
    if inst.components.finiteuses:GetPercent() < 1 then
        inst.components.finiteuses:Repair(10)
    end
end

table.insert(prefs, Prefab("fimbul_axe", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "boomerang", "fimbul_axe", nil, nil)
    RemovePhysicsColliders(inst)
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("thrown")
    inst:AddTag("lightningrod") --避雷针标签，会吸引闪电
    inst:AddTag("weapon")
    inst:AddTag("projectile")
    LS_C_Init(inst, "fimbul_axe", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst.returntask = nil

    fns.ServerFn(inst, "fimbul_axe", OnEquip_fimbulaxe, TOOLS_L.hand_off)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped_fimbulaxe)

    fns.SetWeapon(inst, atk_fimbulaxe, nil)
    inst.components.weapon:SetRange(TUNING.BOOMERANG_DISTANCE, TUNING.BOOMERANG_DISTANCE + 2)
    inst.components.weapon:SetElectric() --设置为带电的武器，带电武器自带攻击加成

    fns.SetFiniteUses(inst, 250, OnFinished_fimbulaxe)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(15)
    --inst.components.projectile:SetCanCatch(true) --默认，不能被主动抓住
    inst.components.projectile:SetOnThrownFn(OnThrown_fimbulaxe)  --扔出时
    inst.components.projectile:SetOnPreHitFn(OnPreHit_fimbulaxe)  --敌方或者自己被击中前
    inst.components.projectile:SetOnHitFn(OnHit_fimbulaxe)        --敌方或者自己被击中后
    inst.components.projectile:SetOnMissFn(OnMiss_fimbulaxe)      --丢失目标时
    --inst.components.projectile:SetOnCaughtFn(OnCaught)--被抓住时

    inst:ListenForEvent("lightningstrike", OnLightning_fimbulaxe)

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("fimbul_axe", {
    Asset("ANIM", "anim/boomerang.zip") --官方回旋镖动画模板
}), { "fimbul_lightning", "fimbul_cracklebase_fx" }))

--------------------------------------------------------------------------
--[[ 扳手-双用型 ]]
--------------------------------------------------------------------------

local function OnEquip_2wrench(inst, owner)
    TOOLS_L.hand_on(owner, "swap_dualwrench", "swap_dualwrench")
end

table.insert(prefs, Prefab("dualwrench", function()
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    fns.CommonFn(inst, "dualwrench", nil, nil, nil)
    inst:AddTag("hammer")
    inst:AddTag("weapon")
    inst:AddTag("tool")

    MakeInventoryFloatable(inst, "med", 0.1, {1.1, 0.5, 1.1}, true, -9, {
        sym_build = "swap_dualwrench",
        sym_name = "swap_dualwrench",
        bank = "dualwrench",
        anim = "idle"
    })

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "dualwrench", OnEquip_2wrench, TOOLS_L.hand_off)
    fns.SetWeapon(inst, TUNING.HAMMER_DAMAGE, nil)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.HAMMER) --添加锤子功能

    --添加草叉功能
    inst:AddInherentAction(ACTIONS.TERRAFORM) --不是很懂官方这行代码的意义
    inst:AddComponent("terraformer")

    fns.SetFiniteUses(inst, TUNING.HAMMER_USES, nil) --总共75次，可攻击75次
    --设置每种功能的消耗量
    inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, 0.3) --可以使用75/0.3=250次
    inst.components.finiteuses:SetConsumption(ACTIONS.TERRAFORM, 0.3)

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("dualwrench", { Asset("ANIM", "anim/swap_dualwrench.zip") }), nil))

--------------------------------------------------------------------------
--[[ 斧铲-三用型 ]]
--------------------------------------------------------------------------

local function OnEquip_3axe(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on(owner, "tripleshovelaxe", "swap")
    end
end

table.insert(prefs, Prefab("tripleshovelaxe", function()
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    fns.CommonFn(inst, "tripleshovelaxe", nil, nil, nil)
    inst:AddTag("sharp")
    inst:AddTag("tool")
    inst:AddTag("weapon")
    LS_C_Init(inst, "tripleshovelaxe", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "tripleshovelaxe", OnEquip_3axe, TOOLS_L.hand_off)
    fns.SetWeapon(inst, TUNING.AXE_DAMAGE, nil)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, 1)
    inst.components.tool:SetAction(ACTIONS.MINE, 1)
    inst.components.tool:SetAction(ACTIONS.DIG,  1)

    fns.SetFiniteUses(inst, 108, nil) --总共108次，可攻击108次
    --设置每种功能的消耗量
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 0.6) --可以使用108/0.6=180次
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 0.6)
    inst.components.finiteuses:SetConsumption(ACTIONS.DIG,  0.6)

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("tripleshovelaxe"), nil))

--------------------------------------------------------------------------
--[[ 斧铲-黄金三用型 ]]
--------------------------------------------------------------------------

local function OnEquip_3axegold(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on(owner, "triplegoldenshovelaxe", "swap")
    end
end

table.insert(prefs, Prefab("triplegoldenshovelaxe", function()
    local inst = CreateEntity()
    inst.entity:AddSoundEmitter()
    fns.CommonFn(inst, "triplegoldenshovelaxe", nil, nil, nil)
    inst:AddTag("sharp")
    inst:AddTag("tool")
    inst:AddTag("weapon")
    LS_C_Init(inst, "triplegoldenshovelaxe", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "triplegoldenshovelaxe", OnEquip_3axegold, TOOLS_L.hand_off)
    fns.SetWeapon(inst, TUNING.AXE_DAMAGE, nil)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, 1.25)
    inst.components.tool:SetAction(ACTIONS.MINE, 1.25)
    inst.components.tool:SetAction(ACTIONS.DIG,  1.25)
    inst.components.tool:EnableToughWork(true) --可以开凿更坚硬的对象

    fns.SetFiniteUses(inst, 180, nil)
    --设置每种功能的消耗量
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 0.1) --可以使用180/0.1=1800次
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 0.1)
    inst.components.finiteuses:SetConsumption(ACTIONS.DIG,  0.1)
    inst.components.weapon.attackwear = 0.1

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("triplegoldenshovelaxe"), nil))

--------------------------------------------------------------------------
--[[ 胡萝卜长枪 ]]
--------------------------------------------------------------------------

local atk_min_carl = 10

local function UpdateCarrot(inst, force)
	local num = 0
	local num2 = 0
	for k,v in pairs(inst.components.container.slots) do
		if v then
			if v.prefab == "carrot" or v.prefab == "carrot_cooked" then
				if v.components.stackable ~= nil then
					num = num + v.components.stackable:StackSize()
				else
					num = num + 1
				end
			elseif v.prefab == "carrat" then
				num2 = num2 + 1
			end
		end
	end

	if not force and inst.num_carrot_l == num and inst.num_carrat_l == num2 then --防止一直计算
		return
	end

	inst.num_carrot_l = num
	inst.num_carrat_l = num2
    if num2 == 1 then --防止用加堆叠上限的mod来做骚操作
        if num > 40 then
            num = 40
        end
    elseif num2 == 0 then
        if num > 80 then
            num = 80
        end
    else
        num2 = 2
        num = 0
    end
    inst.components.weapon:SetDamage(atk_min_carl + num*0.85) --0.85=68/80
    num = 0.0275*num --0.0275=2.2/80
    if num2 > 0 then
        inst.components.planardamage:SetBaseDamage(num2*34)
        inst.components.damagetypebonus:AddBonus("shadow_aligned", inst, 1+( 0.05*num2 ), "carrat")
        num = num + 1.1*num2
    else
        inst.components.planardamage:SetBaseDamage(0)
        inst.components.damagetypebonus:RemoveBonus("shadow_aligned", inst, "carrat")
    end
	num = TOOLS_L.ODPoint(num, 10) --仅保留小数点后1位
	inst.components.weapon:SetRange(num)
end
local function OnOwnerItemChange_carl(owner, data)
	local hands = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if hands ~= nil and hands.prefab == "lance_carrot_l" then
		if hands.task_carrot_l ~= nil then
			hands.task_carrot_l:Cancel()
		end
		hands.task_carrot_l = hands:DoTaskInTime(0, function(hands)
			if hands.components.container ~= nil then
				UpdateCarrot(hands)
			end
			hands.task_carrot_l = nil
		end)
	end
end
local function OnEquip_carl(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on(owner, "lance_carrot_l", "swap_object")
    end
	if owner:HasTag("equipmentmodel") then return end --假人

	if inst.components.container ~= nil then
        inst.components.container:Open(owner)

		inst:ListenForEvent("gotnewitem", OnOwnerItemChange_carl, owner)
		inst:ListenForEvent("itemget", OnOwnerItemChange_carl, owner)
		inst:ListenForEvent("itemlose", OnOwnerItemChange_carl, owner)
		UpdateCarrot(inst, true)
    end
end
local function OnUnequip_carl(inst, owner)
    TOOLS_L.hand_off(inst, owner)
	if owner:HasTag("equipmentmodel") then return end --假人

	if inst.components.container ~= nil then
        inst.components.container:Close()
    end
	inst:RemoveEventCallback("gotnewitem", OnOwnerItemChange_carl, owner)
	inst:RemoveEventCallback("itemget", OnOwnerItemChange_carl, owner)
	inst:RemoveEventCallback("itemlose", OnOwnerItemChange_carl, owner)
end
local function OnFinished_carl(inst)
	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
	end
	inst:Remove()
end
local function OnEntityReplicated_carl(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("lance_carrot_l")
    end
end

table.insert(prefs, Prefab("lance_carrot_l", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "lance_carrot_l", nil, nil, nil)
    inst:AddTag("jab") --使用捅击的动作进行攻击
    inst:AddTag("rp_carrot_l")
    inst:AddTag("weapon")
    LS_C_Init(inst, "lance_carrot_l", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated_carl
        return inst
    end

    inst.num_carrot_l = 0
    inst.num_carrat_l = 0

    fns.ServerFn(inst, "lance_carrot_l", OnEquip_carl, OnUnequip_carl)
    fns.SetWeapon(inst, atk_min_carl, nil)
    -- inst.components.weapon:SetRange(-1, -1) --人物默认攻击距离为3、3
    fns.SetFiniteUses(inst, 200, OnFinished_carl)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(0)

    inst:AddComponent("damagetypebonus")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("lance_carrot_l")
    inst.components.container.canbeopened = false

    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(0.3)

    MakeHauntableLaunch(inst)

    if TUNING.FUNCTIONAL_MEDAL_IS_OPEN then
        SetImmortalable(inst, 2, nil)
    end

    return inst
end, fns.GetAssets("lance_carrot_l"), nil))

--------------------------------------------------------------------------
--[[ 牛排战斧 ]]
--------------------------------------------------------------------------

local foliageath_data_steak = {
    image = "foliageath_dish_tomahawksteak", atlas = "images/inventoryimages/foliageath_dish_tomahawksteak.xml",
    bank = nil, build = nil, anim = "dish_tomahawksteak", isloop = nil
}

local function UpdateAxe(inst)
    local value
    if inst._damage then
        value = inst.components.perishable:GetPercent()
        value = Remap(value, 0, 1, inst._damage[1], inst._damage[2])
        inst.components.weapon:SetDamage(value)
    end
    if inst._chopvalue then
        value = inst.components.perishable:GetPercent()
        value = Remap(value, 0, 1, inst._chopvalue[1], inst._chopvalue[2])
        inst.components.tool.actions[ACTIONS.CHOP] = value
    end
end
local function AfterWorking(inst, data)
    if
        data.target and
        data.target.components.workable ~= nil and
        data.target.components.workable:CanBeWorked() and
        data.target.components.workable:GetWorkAction() == ACTIONS.CHOP and
        math.random() < (inst.steak_l_chop or 0.05)
    then
        --TIP：事件机制会在发送者那边逻辑当前帧就处理完的。所以这里只需要设置关键变量 workleft=0 即可
        data.target.components.workable.workleft = 0
        if inst.components.talker ~= nil then
            inst.components.talker:Say(GetString(inst, "DESCRIBE", { "DISH_TOMAHAWKSTEAK", "CHOP" }))
        end
    end
end
local function SingleFight(owner)
    -- if owner.singlefight_target == nil then
    --     return
    -- end
    local hasenemy = false
    local x, y, z = owner.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 24,
        { "_combat" }, { "INLIMBO", "NOCLICK", "player", "notarget", "nosinglefight_l" }, nil
    )
    for _,v in ipairs(ents) do
        if
            v ~= owner.singlefight_target and
            v.entity:IsVisible() and
            (v.components.health == nil or not v.components.health:IsDead()) and
            v.components.combat ~= nil and v.components.combat.target == owner
        then
            v.components.combat:DropTarget(false)
            hasenemy = true
        end
    end
    if owner.singlefight_count == nil or owner.singlefight_count <= 1 then
        owner.singlefight_count = nil
        owner.singlefight_target = nil
        if owner.singlefight_task ~= nil then
            owner.singlefight_task:Cancel()
            owner.singlefight_task = nil
        end
    else
        owner.singlefight_count = owner.singlefight_count - 1
        if hasenemy and owner.components.talker ~= nil and math.random() < 0.1 then
            owner.components.talker:Say(GetString(owner, "DESCRIBE", { "DISH_TOMAHAWKSTEAK", "ATK" }))
        end
    end
end
local function TrySingleFight(inst, owner, target)
    if target ~= nil and owner ~= nil and owner:IsValid() then
        owner.singlefight_target = target
        owner.singlefight_count = 7
        if owner.singlefight_task == nil then
            owner.singlefight_task = owner:DoPeriodicTask(0.5, SingleFight, 0)
        else
            SingleFight(owner) --每次攻击立即触发一下，免得 task 的效果跟不上
        end
    end
end

local function OnEquip_steak_pre(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
        if inst._dd.startfn ~= nil then
            inst._dd.startfn(inst, owner)
        end
    else
        TOOLS_L.hand_on(owner, "dish_tomahawksteak", "swap")
    end
end
local function OnEquip_steak_pst(inst, owner)
    if inst._UpdateAxe then
        inst._UpdateAxe(inst)
    end
    owner:PushEvent("learncookbookstats", inst.food_basename or inst.prefab) --解锁烹饪书数据
    owner:ListenForEvent("working", AfterWorking)
    owner.steak_l_chop = inst._chopchance
end
local function OnEquip_steak(inst, owner)
    OnEquip_steak_pre(inst, owner)
    if owner:HasTag("equipmentmodel") then return end --假人
    OnEquip_steak_pst(inst, owner)
end
local function OnUnequip_steak(inst, owner)
    TOOLS_L.hand_off(inst, owner)
    if inst._dd ~= nil then
        if inst._dd.endfn ~= nil then
            inst._dd.endfn(inst, owner)
        end
    end
    if inst._UpdateAxe then
        inst._UpdateAxe(inst)
    end
    owner:RemoveEventCallback("working", AfterWorking)
    owner.steak_l_chop = nil
end
local function OnAttack_steak(inst, owner, target)
    if inst._UpdateAxe then
        inst._UpdateAxe(inst)
    end
    TrySingleFight(inst, owner, target)
    if inst._dd ~= nil and inst._dd.atkfn ~= nil and target ~= nil and target:IsValid() then
        inst._dd.atkfn(inst, owner, target)
    end
end
local function OnLoad_steak(inst, data)
    if inst._UpdateAxe then
        inst._UpdateAxe(inst)
    end
end
local function InitSteak(inst)
    inst._damage = { 47.6, 61.2 } --34x1.8
    inst._chopvalue = { 1.2, 1.66 }
    inst._chopchance = 0.05
    inst._UpdateAxe = UpdateAxe

    inst.components.tool:SetAction(ACTIONS.CHOP, inst._chopvalue[2])

    inst.components.weapon:SetDamage(inst._damage[2])
end

local function MakeSteak(data)
    local assets = fns.GetAssets("dish_tomahawksteak")
    local basename = "dish_tomahawksteak"
    local prefabname = "dish_tomahawksteak"

    if data.spicename ~= nil then
        if data.spicebuild ~= nil then
            table.insert(assets, Asset("ANIM", "anim/"..data.spicebuild..".zip"))
        else
            table.insert(assets, Asset("ANIM", "anim/spices.zip"))
        end
        if data.spiceatlas ~= nil then
            table.insert(assets, Asset("ATLAS", data.spiceatlas))
        else
            table.insert(assets, Asset("INV_IMAGE", data.spicename.."_over"))
        end
        table.insert(assets, Asset("ANIM", "anim/plate_food.zip"))
        prefabname = prefabname.."_"..data.spicename
    end

    local function DisplayName_steak(inst)
        return subfmt(
                STRINGS.NAMES[string.upper(data.spicename).."_FOOD"],
                { food = STRINGS.NAMES[string.upper(basename)] }
            )
    end

    table.insert(prefs, Prefab(prefabname, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        if data.spicename ~= nil then
            inst.AnimState:SetBuild("plate_food")
            inst.AnimState:SetBank("plate_food")
            inst.AnimState:OverrideSymbol("swap_garnish", data.spicebuild or "spices", data.spicename)
            inst.AnimState:OverrideSymbol("swap_food", basename, "base")

            inst:AddTag("spicedfood")

            --设置作为背景的料理图
            inst.inv_image_bg = { atlas = "images/inventoryimages/"..basename..".xml", image = basename..".tex" }

            inst:SetPrefabNameOverride(basename)
            inst.displaynamefn = DisplayName_steak
        else
            inst.AnimState:SetBank(basename)
            inst.AnimState:SetBuild(basename)
        end
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("show_spoilage")
        inst:AddTag("icebox_valid")
        inst:AddTag("preparedfood") --这个标签能使其被放入香料站
        inst:AddTag("sharp")
        inst:AddTag("tool")
        inst:AddTag("weapon")
        inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制

        if data.spicename ~= nil then
            LS_C_Init(inst, basename, true, "data_spice", "xx")
        else
            LS_C_Init(inst, basename, true)
        end
        if data.fn_common ~= nil then
            data.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.food_symbol_build = basename
        inst.food_basename = data.spicename ~= nil and basename or nil

        inst.foliageath_data = foliageath_data_steak

        -- inst._damage = nil --基础攻击力
        -- inst._chopvalue = nil --基础砍伐效率
        -- inst._chopchance = nil --直接砍倒树的几率
        -- inst._UpdateAxe = nil

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = basename
        if data.spicename ~= nil then
            if data.spiceatlas ~= nil then
                inst.components.inventoryitem.atlasname = data.spiceatlas
            end
            inst.components.inventoryitem:ChangeImageName(data.spicename.."_over")
        else
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..basename..".xml"
        end

        fns.SetPerishable(inst, data.perishtime or TUNING.PERISH_MED, "boneshard", nil)

        inst:AddComponent("tool")

        inst:AddComponent("weapon")
        inst.components.weapon:SetOnAttack(OnAttack_steak)

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(OnEquip_steak)
        inst.components.equippable:SetOnUnequip(OnUnequip_steak)

        inst.OnLoad = OnLoad_steak

        MakeHauntableLaunchAndPerish(inst)

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, assets, nil))
end

MakeSteak({ --普通
    -- spicename = nil, perishtime = nil,
    fn_server = InitSteak
})
MakeSteak({ --大蒜香料：加护甲
    spicename = "spice_garlic", --perishtime = nil,
    fn_common = function(inst)
        inst:AddTag("hide_percentage") --这个标签和物品栏新鲜度状态背景的展示有冲突，看来之后得去掉armor组件，用别的方式
    end,
    fn_server = function(inst)
        InitSteak(inst)

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(100, 0.4)
        inst.components.armor.indestructible = true --无敌的护甲
    end
})
MakeSteak({ --蜂蜜香料：加工作效率
    spicename = "spice_sugar", --perishtime = nil,
    fn_server = function(inst)
        inst._damage = { 47.6, 61.2 } --34x1.8
        inst._chopvalue = { 1.8, 2.5 }
        inst._chopchance = 0.15
        inst._UpdateAxe = UpdateAxe

        inst.components.tool:SetAction(ACTIONS.CHOP, inst._chopvalue[2])

        inst.components.weapon:SetDamage(inst._damage[2])
    end
})
MakeSteak({ --辣椒香料：加攻击
    spicename = "spice_chili", --perishtime = nil,
    fn_server = function(inst)
        inst._damage = { 64.26, 82.62 } --34x1.8x1.35
        inst._chopvalue = { 1.2, 1.66 }
        inst._chopchance = 0.05
        inst._UpdateAxe = UpdateAxe

        inst.components.tool:SetAction(ACTIONS.CHOP, inst._chopvalue[2])

        inst.components.weapon:SetDamage(inst._damage[2])
    end
})
MakeSteak({ --盐香料：加新鲜度
    spicename = "spice_salt", perishtime = TUNING.TOTAL_DAY_TIME * 14.5,
    fn_server = function(inst)
        inst.components.tool:SetAction(ACTIONS.CHOP, 1.66)

        inst.components.weapon:SetDamage(61.2)

        inst.OnLoad = nil
    end
})

if TUNING.FUNCTIONAL_MEDAL_IS_OPEN then --能力勋章兼容
    local function OnAttack_steak_voltjelly(inst, owner, target)
        OnAttack_steak(inst, owner, target)
        if target ~= nil and target:IsValid() and owner ~= nil and owner:IsValid() then
            SpawnPrefab("electrichitsparks"):AlignToTarget(target, owner, true)
        end
    end
    MakeSteak({ --带电果冻粉：武器带电
        spicename = "spice_voltjelly", --perishtime = nil,
        spicebuild = "medal_spices", spiceatlas = "images/spice_voltjelly_over.xml",
        fn_server = function(inst)
            InitSteak(inst)
            inst.components.weapon:SetElectric()
            inst.components.weapon:SetOnAttack(OnAttack_steak_voltjelly)
        end
    })

    local function onremovefire(fire)
        fire.nightstick.fire = nil
    end
    local function OnEquip_steak_phosphor(inst, owner)
        OnEquip_steak_pre(inst, owner)
        if inst.fire == nil then
            inst.fire = SpawnPrefab("lichenhatlight")
            inst.fire.nightstick = inst
            inst:ListenForEvent("onremove", onremovefire, inst.fire)
        end
        inst.fire.entity:SetParent(owner.entity)
        if owner:HasTag("equipmentmodel") then return end --假人
        OnEquip_steak_pst(inst, owner)
    end
    local function OnUnequip_steak_phosphor(inst, owner)
        OnUnequip_steak(inst, owner)
        if inst.fire ~= nil then
            inst.fire:Remove()
        end
    end
    MakeSteak({ --荧光粉：武器发光
        spicename = "spice_phosphor", --perishtime = nil,
        spicebuild = "medal_spices", spiceatlas = "images/spice_phosphor_over.xml",
        fn_common = function(inst)
            inst:AddTag("wildfireprotected")
        end,
        fn_server = function(inst)
            InitSteak(inst)
            inst.components.equippable:SetOnEquip(OnEquip_steak_phosphor)
            inst.components.equippable:SetOnUnequip(OnUnequip_steak_phosphor)
        end
    })

    MakeSteak({ --仙人掌花粉：加移速
        spicename = "spice_cactus_flower", --perishtime = nil,
        spicebuild = "medal_spices", spiceatlas = "images/spice_cactus_flower_over.xml",
        fn_server = function(inst)
            InitSteak(inst)
            inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT
        end
    })

    local function BattleBornAttack(inst, data)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst.components.health:DoDelta(0.6, false, inst.food_basename)
        end
    end
    local function OnEquip_steak_rage_blood(inst, owner)
        OnEquip_steak_pre(inst, owner)
        if owner:HasTag("equipmentmodel") then return end --假人
        OnEquip_steak_pst(inst, owner)
        owner:ListenForEvent("onattackother", BattleBornAttack)
    end
    local function OnUnequip_steak_rage_blood(inst, owner)
        OnUnequip_steak(inst, owner)
        owner:RemoveEventCallback("onattackother", BattleBornAttack)
    end
    MakeSteak({ --黑暗血糖：攻击回血
        spicename = "spice_rage_blood_sugar", --perishtime = nil,
        spicebuild = "medal_spices", spiceatlas = "images/spice_rage_blood_sugar_over.xml",
        fn_server = function(inst)
            InitSteak(inst)
            inst.components.equippable:SetOnEquip(OnEquip_steak_rage_blood)
            inst.components.equippable:SetOnUnequip(OnUnequip_steak_rage_blood)
        end
    })

    local function OnEquip_steak_potato_starch(inst, owner)
        OnEquip_steak_pre(inst, owner)
        if owner:HasTag("equipmentmodel") then return end --假人
        OnEquip_steak_pst(inst, owner)
        if owner.components.hunger ~= nil then
            owner.components.hunger.burnratemodifiers:SetModifier(inst, 0.2)
        end
    end
    local function OnUnequip_steak_potato_starch(inst, owner)
        OnUnequip_steak(inst, owner)
        if owner.components.hunger ~= nil then
            owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
        end
    end
    MakeSteak({ --土豆淀粉：耐饿
        spicename = "spice_potato_starch", --perishtime = nil,
        spicebuild = "medal_spices", spiceatlas = "images/spice_potato_starch_over.xml",
        fn_server = function(inst)
            InitSteak(inst)
            inst.components.equippable:SetOnEquip(OnEquip_steak_potato_starch)
            inst.components.equippable:SetOnUnequip(OnUnequip_steak_potato_starch)
        end
    })
end

--------------------------------------------------------------------------
--[[ 子圭羽毛 ]]
--------------------------------------------------------------------------

local LineMap = {
    silk = 2,
    beardhair = 4,
    steelwool = 20,
    cattenball = 15
}
local throwednum = CONFIGS_LEGION.SIVFEATHROWEDNUM or 5

local function OnEquip_fea(inst, owner)
    local dd = inst._dd
    if dd ~= nil then
        if dd.isshield then
            TOOLS_L.hand_on_shield(owner, dd.build, dd.file)
        else
            TOOLS_L.hand_on(owner, dd.build, dd.file)
        end
        if dd.startfn ~= nil then
            dd.startfn(inst, owner)
        end
    else
        TOOLS_L.hand_on(owner, inst.prefab, "swap")
    end
    -- if owner:HasTag("equipmentmodel") then return end --假人
end
local function OnUnequip_fea(inst, owner)
    if inst._dd ~= nil then
        if inst._dd.isshield then
            TOOLS_L.hand_off_shield(inst, owner)
        else
            TOOLS_L.hand_off(inst, owner)
        end
        if inst._dd.endfn ~= nil then
            inst._dd.endfn(inst, owner)
        end
    else
        TOOLS_L.hand_off(inst, owner)
    end
end
local function OnPickedUp_fea(inst, pickupguy, src_pos)
    if pickupguy and pickupguy.Transform then
        inst.Transform:SetRotation(pickupguy.Transform:GetRotation())
    end
end
local function OnHit_fly_fake(cpt, ent, flyobj, weapon)
    if math.random() < 0.05 then
        flyobj:Remove()
    end
end
local function Fn_validhit_fea_pvp(self, ent) --PVP模式下，只关注自己
    return TOOLS_L.MaybeEnemy_me(self.owner, ent, true)
end
local function Fn_validhit_fea(self, ent) --非PVP，就要关注所有玩家
    return TOOLS_L.MaybeEnemy_player(self.owner, ent, true)
end
local function FnSpell_fea(inst, caster, pos, options)
    if caster.components.inventory == nil then
        return
    end
    local ctl = SpawnPrefab("siving_feather_ctl")
    local ctlcpt = ctl.components.sivfeatherctl
    local costt = inst.fea_hpcost or 3
    ctlcpt.shootrange = inst.fea_range or 10
    -- ctlcpt.speed = 45
    ctlcpt.name_base = inst.prefab
    ctlcpt.name_fly = (inst.skinname or inst.prefab).."_fly"
    ctlcpt.name_blk = (inst.skinname or inst.prefab).."_blk"
    if not inst.isreal then
        ctlcpt.fn_hit = OnHit_fly_fake
    end
    if TheNet:GetPVPEnabled() then
        ctlcpt.fn_validhit = Fn_validhit_fea_pvp
        ctlcpt.exclude_tags = TOOLS_L.TagsCombat1({
            "wall", "structure", "companion", "glommer", "friendlyfruitfly", "shadowminion"
        })
    else
        ctlcpt.fn_validhit = Fn_validhit_fea
        ctlcpt.exclude_tags = TOOLS_L.TagsCombat1({
            "wall", "structure", "companion", "glommer", "friendlyfruitfly", "shadowminion",
            "player", "abigail"
        })
    end

    local items --需要丢出去的羽毛
    local num = inst.components.stackable:StackSize()
    if num <= throwednum then
        items = caster.components.inventory:RemoveItem(inst, true)
    else
        items = inst.components.stackable:Get(throwednum)
        items.components.inventoryitem:OnRemoved() --由于此时还处于物品栏状态，需要恢复为非物品栏状态
        num = throwednum
    end

    local line
    if not caster:HasTag("playerghost") and caster.components.health ~= nil and not caster.components.health:IsDead() then
        if costt > 0 and caster.siv_blood_l_reducer_v ~= nil then
            if caster.siv_blood_l_reducer_v >= 1 then
                costt = 0
            else
                costt = costt * (1-caster.siv_blood_l_reducer_v)
            end
        end
        if costt > 0 then
            caster.components.health:DoDelta(-costt*num, true, inst.prefab, false, nil, true)
        end
        if not caster.components.health:IsDead() and not caster:HasTag("playerghost") then
            local lines = caster.components.inventory:FindItems(function(i) --查询是否有能拉回的材料
                if i.legion_sivfea_line ~= nil or LineMap[i.prefab] then
                    return true
                end
            end)
            if #lines > 0 then
                line = SpawnPrefab("siving_feather_line")
                if caster.components.inventory:Equip(line) then
                    line.sivfeatherctl = ctl
                else
                    line:Remove()
                    line = nil
                end
            end
        end
    end

    ctlcpt:Throw(items, caster, pos, num, line, inst.projectiledelay)
end

local function OnThrown_fly(inst, owner, angle, pos)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe", nil, 0.2)
end

local function SetAnim_fly_collector(inst)
    if math.random() < 0.4 then
        inst.AnimState:PlayAnimation("jump_loop")
        inst.AnimState:PushAnimation("jump_pst", false)
    else
        inst.AnimState:PlayAnimation("jump_out")
        inst.AnimState:PushAnimation("idle_loop", true)
    end
end
local function SetAnim_blk_collector(inst)
    local ran = math.random()
    if ran < 0.25 then
        inst.AnimState:PlayAnimation("emote_lick")
        inst.AnimState:PushAnimation("idle_loop", true)
    elseif ran < 0.5 then
        inst.AnimState:PlayAnimation("emote_stretch")
        inst.AnimState:PushAnimation("idle_loop", true)
    else
        inst.AnimState:PlayAnimation("idle_loop", true)
    end
end
local function OnThrown_fly_collector(inst, owner, angle, pos)
    local rand = math.random()
    if rand < 0.33 then
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/hiss_pre", nil, 0.5)
    elseif rand < 0.66 then
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/attack", nil, 0.5)
    else
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/pounce", nil, 0.5)
    end
end
local function SpawnFx_collector(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i = 1, math.random(2), 1 do
        local fx = SpawnPrefab(inst.skinfx)
        if fx ~= nil then
            local x1, y1, z1 = TOOLS_L.GetCalculatedPos(x, y, z, math.random()*2, nil)
            fx.Transform:SetPosition(x1, y1, z1)
        end
    end
end

local function MakeSivFeather_replace(data)
    table.insert(prefs, Prefab(data.name.."_fly", function() ------飞行体
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeProjectilePhysics(inst)

        inst.AnimState:SetBank(data.name)
        inst.AnimState:SetBuild(data.name)

        inst:AddTag("NOCLICK")

        if data.fn_common_fly ~= nil then
            data.fn_common_fly(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.persists = false
        inst.isflyobj = true
        -- inst.feaidx = 1
        inst.fn_onthrown = OnThrown_fly

        if data.fn_server_fly ~= nil then
            data.fn_server_fly(inst)
        end

        return inst
    end, nil, nil))
    table.insert(prefs, Prefab(data.name.."_blk", function() ------滞留体
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        RemovePhysicsColliders(inst)
        -- MakeProjectilePhysics(inst)

        inst.AnimState:SetBank(data.name)
        inst.AnimState:SetBuild(data.name)
        inst.Transform:SetEightFaced()

        inst:AddTag("NOCLICK")

        if data.fn_common_blk ~= nil then
            data.fn_common_blk(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.persists = false
        -- inst.feaidx = 1

        if data.fn_server_blk ~= nil then
            data.fn_server_blk(inst)
        end

        return inst
    end, nil, nil))
end
local function MakeSivFeather(data)
    local fea_damage
    local fea_range
    local fea_hpcost
    if data.isreal then
        fea_damage = CONFIGS_LEGION.SIVFEADAMAGE or 26
        fea_range = 13
        fea_hpcost = CONFIGS_LEGION.SIVFEAHEALTHCOST or 1.5
    else
        fea_damage = 30.6 --34*0.9
        fea_range = 10
        fea_hpcost = 3
    end

    table.insert(prefs, Prefab(data.name, function() ------手持物品
        local inst = CreateEntity()
        fns.CommonFn(inst, data.name, nil, nil, nil)
        inst.Transform:SetEightFaced()
        inst:AddTag("sharp")
        inst:AddTag("s_l_throw") --skill_legion_throw
        inst:AddTag("allow_action_on_impassable")
        inst:AddTag("moistureimmunity") --禁止潮湿：EntityScript:GetIsWet()
        inst:AddTag("weapon")
        LS_C_Init(inst, data.name, true)

        inst.projectiledelay = 2 * FRAMES --不能大于7帧

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.isreal = data.isreal
        inst.fea_range = fea_range
        inst.fea_hpcost = fea_hpcost

        fns.ServerFn(inst, data.name, OnEquip_fea, OnUnequip_fea)
        inst.components.equippable.equipstack = true --装备时可以叠加装备

        inst.components.inventoryitem.TryToSink = function(self, ...)end --防止在虚空里消失
        inst.components.inventoryitem:EnableMoisture(false) --禁止潮湿：官方的代码有问题，会导致潮湿攻击滑落时叠加数变为1
        inst.components.inventoryitem:SetOnPickupFn(OnPickedUp_fea) --被捡起时，修改自己的旋转角度

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

        inst:AddComponent("savedrotation") --保存旋转角度的组件

        fns.SetWeapon(inst, fea_damage, nil)
        inst.components.weapon:SetRange(-1, -1) --人物默认攻击距离为3、3

        inst:AddComponent("skillspelllegion") --右键技能
        inst.components.skillspelllegion.fn_spell = FnSpell_fea

        MakeHauntableLaunch(inst)

        return inst
    end, {
        Asset("ANIM", "anim/"..data.name..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..data.name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..data.name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..data.name..".xml", 256)
    }, {
        data.name.."_fly",
        data.name.."_blk",
        "siving_feather_line", "siving_feather_ctl"
    }))

    MakeSivFeather_replace({
        name = data.name,
        fn_common_fly = function(inst)
            inst.AnimState:PlayAnimation("shoot", false)
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        end,
        -- fn_server_fly = function(inst)end,
        fn_common_blk = function(inst)
            inst.AnimState:PlayAnimation("idle", false)
            fns.SetFloatable(inst, { 0.04, "small", 0.2, 0.5 })
        end,
        -- fn_server_blk = function(inst)end
    })

    MakeSivFeather_replace({
        name = data.name.."_paper",
        fn_common_fly = function(inst)
            inst.Transform:SetFourFaced()
            inst.AnimState:PlayAnimation("shoot", true)
        end,
        -- fn_server_fly = function(inst)end,
        fn_common_blk = function(inst)
            inst.AnimState:PlayAnimation("idle", false)
            fns.SetFloatable(inst, { 0.04, "small", 0.2, 0.5 })
        end,
        -- fn_server_blk = function(inst)end
    })

    MakeSivFeather_replace({
        name = data.name.."_collector",
        fn_common_fly = function(inst)
            inst.AnimState:SetBank("kitcoon")
            inst.Transform:SetSixFaced()
            inst.AnimState:SetScale(0.9, 0.9)
            SetAnim_fly_collector(inst)
        end,
        fn_server_fly = function(inst)
            inst.fn_onthrown = OnThrown_fly_collector
            inst.skinfx = data.name.."_collector_flyfx"
            inst.task_skinfx = inst:DoPeriodicTask(0.1, SpawnFx_collector, 0)
        end,
        fn_common_blk = function(inst)
            inst.AnimState:SetBank("kitcoon")
            inst.Transform:SetSixFaced()
            inst.AnimState:SetScale(0.9, 0.9)
            SetAnim_blk_collector(inst)
            fns.SetFloatable(inst, { nil, "med", 0.1, 0.5 })
        end,
        -- fn_server_blk = function(inst)end
    })
end

MakeSivFeather({ name = "siving_feather_real", isreal = true }) --子圭·翰
MakeSivFeather({ name = "siving_feather_fake" }) --子圭玄鸟绒羽

------

table.insert(prefs, Prefab("siving_feather_ctl", function() --子圭羽毛发射管理器
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("sivfeatherctl")

    return inst
end, nil, nil))

------

local function Remove_sivline(inst)
    if inst.task_doremove ~= nil then
        return
    end
    if inst.sivfeatherctl ~= nil and inst.sivfeatherctl:IsValid() then
        local ctlcpt = inst.sivfeatherctl.components.sivfeatherctl
        ctlcpt.line = nil
        if ctlcpt.tempfeas ~= nil then
            for _, fe in pairs(ctlcpt.tempfeas) do
                if fe:IsValid() and not fe.isflyobj then --飞行体不管，让它继续飞，得把滞留体变回真实羽毛
                    if ctlcpt.num > 0 then
                        ctlcpt:BeRealFeather(fe)
                    end
                    fe:Remove()
                end
            end
        end
        if ctlcpt.num <= 0 then
            ctlcpt:Finish()
            inst.sivfeatherctl:Remove()
        end
    end
    inst.sivfeatherctl = nil
    if inst.task_remove ~= nil then
        inst.task_remove:Cancel()
        inst.task_remove = nil
    end
    --从装备栏拿下来后的下一帧才执行移除，因为官方代码默认一个装备卸下时不会被移除，会继续做操作，如果不延迟移除会触发崩溃
    inst.task_doremove = inst:DoTaskInTime(0, function()
        inst:Remove()
    end)
end
local function OnEquip_sivline(inst, owner)
end
local function OnUnequip_sivline(inst, owner)
    Remove_sivline(inst)
end
local function FnSpell_sivline(inst, doer, pos, options)
    if inst.sivfeatherctl == nil or not inst.sivfeatherctl:IsValid() or --防止重复触发
        doer.components.inventory == nil
    then
        return
    end

    if inst.sivfeatherctl.components.sivfeatherctl:ThrowBack() then --先拉回羽毛
        --找到所有拉回羽毛会消耗的材料
        local lines = doer.components.inventory:FindItems(function(i)
            if i.legion_sivfea_line ~= nil or LineMap[i.prefab] then
                return true
            end
        end)
        --消耗材料
        local cost = (doer.legion_sivfea_line or 0) + 1
        for _, v in ipairs(lines) do
            local value = v.legion_sivfea_line or LineMap[v.prefab]
            if cost < value then --还未到消耗之时
                break
            end
            if v.components.stackable == nil then
                local costitem = doer.components.inventory:RemoveItem(v, nil, true)
                if costitem then
                    costitem:Remove()
                end
                cost = cost - value
            else
                local num = v.components.stackable:StackSize()
                for i = 1, num, 1 do
                    local costitem = doer.components.inventory:RemoveItem(v, nil, true)
                    if costitem then
                        costitem:Remove()
                    end
                    cost = cost - value
                    if cost < value then
                        break
                    end
                end
            end
            if cost < value then
                break
            end
        end
        if cost <= 0 then
            doer.legion_sivfea_line = nil
        else
            doer.legion_sivfea_line = cost
        end
    end
    inst.sivfeatherctl = nil
    -- Remove_sivline(inst) --不移除。只删除相关代码。为了能一直待在装备栏，阻止小恶魔灵魂跳跃
    inst:AddTag("noskill_l")
    if inst.task_remove ~= nil then
        inst.task_remove:Cancel()
        inst.task_remove = nil
    end
end

table.insert(prefs, Prefab("siving_feather_line", function() --临时的羽刃拉回器
    local inst = CreateEntity()
    inst.entity:AddTransform() --Tip：AddAnimState 组件 必需在该组件之后，否则会崩溃

    --这个prefab我本来不准备加动画机制的，但是【Super Wall】mod 里会因此崩溃：它的机制默认装备物品是有这个组件的
    inst.entity:AddAnimState()

    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("s_l_pull") --skill_legion_pull
    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("nosoulhop_l") --棱镜标签。阻止小恶魔能灵魂跳跃

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false
    -- inst.sivfeatherctl = nil

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "siving_feather_line"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/siving_feather_line.xml"
    inst.components.inventoryitem:SetOnDroppedFn(Remove_sivline)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip_sivline)
    inst.components.equippable:SetOnUnequip(OnUnequip_sivline)

    inst:AddComponent("skillspelllegion")
    inst.components.skillspelllegion.fn_spell = FnSpell_sivline

    inst.task_remove = inst:DoTaskInTime(3.5, function()
        inst.task_remove = nil
        Remove_sivline(inst)
    end)

    return inst
end, {
    Asset("ATLAS", "images/inventoryimages/siving_feather_line.xml"),
    Asset("IMAGE", "images/inventoryimages/siving_feather_line.tex"),
    -- Asset("ATLAS_BUILD", "images/inventoryimages/siving_feather_line.xml", 256) --不需要这个
}, nil))

--------------------------------------------------------------------------
--[[ 捉影之镜 ]]
--------------------------------------------------------------------------

local function OnEquip_mirror_shadow(inst, owner)
    TOOLS_L.hand_on_shield(owner, "acc_l_shadowmirror", "swap_shield")
end
local function NoWax_mirror_shadow(inst)
    if inst.components.wax ~= nil then
        inst:RemoveComponent("wax")
        -- inst:RemoveTag("waxspray") --不需要
    end
    if inst.components.waxlegion ~= nil then
        inst:RemoveComponent("waxlegion")
    end
end
local function OnPercentChange_mirror_shadow(inst, data)
    if data == nil or data.percent == nil then
        return
    end
    if inst.task_nowax ~= nil then
        inst.task_nowax:Cancel()
        inst.task_nowax = nil
    end
    if POPULATING then
        if data.percent <= 0 then --加载过程时，只关注为0的情况
            inst.task_nowax = inst:DoTaskInTime(math.random(), function(inst)
                inst.task_nowax = nil
                NoWax_mirror_shadow(inst)
            end)
        end
    else
        if data.percent <= 0 then
            NoWax_mirror_shadow(inst)
        else
            if inst.components.wax == nil then
                inst:AddComponent("wax")
            end
            if inst.components.waxlegion == nil then
                inst:AddComponent("waxlegion")
            end
        end
    end
end

table.insert(prefs, Prefab("acc_l_shadowmirror", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "acc_l_shadowmirror", nil, nil, nil)
    fns.SetFurnitureDecor_comm(inst)
    fns.SetFloatable(inst, { 0.04, "small", 0.2, 0.5 })
    inst:AddTag("nopunch")
    inst:AddTag("rp_shadow_l")
    inst:AddTag("shadowlevel")
    inst:AddTag("shadow_item")
    inst:AddTag("shadowdominance")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    --池塘钓鱼钓起时sg里需要的数据
    --动画文件里需要有个叫"fish01"的通道，存放钓起过程中的贴图，编号得至少到“fish01-1”
    inst.build = "acc_l_shadowmirror"

    fns.ServerFn(inst, "acc_l_shadowmirror", OnEquip_mirror_shadow, TOOLS_L.hand_off_shield)
    fns.SetFurnitureDecor_serv(inst, nil)

    inst:AddComponent("wax") --可以给巨型作物果实打蜡
    inst:AddComponent("waxlegion")

    fns.SetFiniteUses(inst, 100, nil)
    inst.components.finiteuses:SetOnFinished() --耐久为0也不会消失
    inst:ListenForEvent("percentusedchange", OnPercentChange_mirror_shadow)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.SKELETONHAT_SHADOW_LEVEL) --3

    inst:AddComponent("shadowdominance") --不会被影怪主动攻击

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("acc_l_shadowmirror"), nil))

--------------------------------------------------------------------------
--[[ 细微之触 ]]
--------------------------------------------------------------------------

pas.redetailables = {
    ------官方的
    -- xxx = function(inst, brush, mode, doer)end,
    cave_fern = function(inst, brush, mode, doer) --蕨类植物
        local strs = { "f1","f2","f3","f4","f5","f6","f7","f8","f9","f10" }
        if mode == 1 then
            inst.animname = TOOLS_L.GetExceptRandomString(strs, inst.animname)
        else
            inst.animname = TOOLS_L.GetNextCycleString(strs, inst.animname)
        end
        inst.AnimState:PlayAnimation(inst.animname)
        return false, { scale = 0.7 }
    end,
    pottedfern = function(inst, brush, mode, doer) --蕨类盆栽
        if not inst.skinname then --有皮肤时，底层会强制改动画的，所以如果有皮肤就没必要继续了
            local strs = { "f1","f2","f3","f4","f5","f6","f7","f8","f9","f10" }
            if mode == 1 then
                inst.animname = TOOLS_L.GetExceptRandomString(strs, inst.animname)
            else
                inst.animname = TOOLS_L.GetNextCycleString(strs, inst.animname)
            end
            inst.AnimState:PlayAnimation(inst.animname)
            return false
        end
        return true
    end,
    succulent_potted = function(inst, brush, mode, doer) --多肉盆栽
        if inst.SetupPlant ~= nil then
            if mode == 1 then
                inst.plantid = TOOLS_L.GetExceptRandomNumber(1, 5, inst.plantid or 1)
            else
                inst.plantid = TOOLS_L.GetNextCycleNumber(1, 5, inst.plantid or 1)
            end
            inst:SetupPlant(inst.plantid)
            return false
        end
        return true
    end,
    flower = function(inst, brush, mode, doer) --花
        local strs = { "f1","f2","f3","f4","f5","f6","f7","f8","f9","f10", "rose" }
        local lastname = inst.animname
        if mode == 1 then
            inst.animname = TOOLS_L.GetExceptRandomString(strs, lastname)
        else
            inst.animname = TOOLS_L.GetNextCycleString(strs, lastname)
        end
        if inst.animname == "rose" then
            inst:AddTag("thorny")
            inst._isrose:set(true)
            inst:OnIsRoseDirty()
        elseif lastname == "rose" then
            inst:RemoveTag("thorny")
            inst._isrose:set(false)
            inst:OnIsRoseDirty()
        end
        inst.AnimState:PlayAnimation(inst.animname)
        return false, { scale = 0.7 }
    end,
    flower_withered = function(inst, brush, mode, doer) --枯萎的花
        local strs = { "wf1","wf2","wf3" }
        if mode == 1 then
            inst.animname = TOOLS_L.GetExceptRandomString(strs, inst.animname)
        else
            inst.animname = TOOLS_L.GetNextCycleString(strs, inst.animname)
        end
        inst.AnimState:PlayAnimation(inst.animname)
        return false, { scale = 0.7 }
    end,
    flower_evil = function(inst, brush, mode, doer) --邪恶花
        local strs = { "f1","f2","f3","f4","f5","f6","f7","f8" }
        if mode == 1 then
            inst.animname = TOOLS_L.GetExceptRandomString(strs, inst.animname)
        else
            inst.animname = TOOLS_L.GetNextCycleString(strs, inst.animname)
        end
        inst.AnimState:PlayAnimation(inst.animname)
        return false, { scale = 0.7 }
    end,
    ------棱镜的
    pebble_l_nitre = true, fern_l = true, icelegume_l = true
}
pas.DO_shadowbrush = function(inst, target, doer)
    local mode = inst.components.modelegion.now
    local failed = true
    local fxset
    if target.legionfn_redetailed ~= nil then
        failed, fxset = target.legionfn_redetailed(target, inst, mode, doer)
    else
        local fn = pas.redetailables[target.prefab]
        if type(fn) == "function" then
            failed, fxset = fn(target, inst, mode, doer)
        end
    end
    if not failed then --没有失败的话，消耗次数以及生成特效
        inst.components.finiteuses:Use(0.1)
        local fx = SpawnPrefab("explode_reskin")
        if fx ~= nil then
            local x, y, z = target.Transform:GetWorldPosition()
            if fxset ~= nil then
                if fxset.scale ~= nil then
                    fx.Transform:SetScale(fxset.scale, fxset.scale, fxset.scale)
                end
                if fxset.y ~= nil then
                    y = y + fxset.y
                end
            end
            fx.Transform:SetPosition(x, y, z)
        end
    end
end

pas.OnEquip_shadowbrush = function(inst, owner)
    if inst._dd ~= nil then
        TOOLS_L.hand_on(owner, inst._dd.build, inst._dd.file)
    else
        TOOLS_L.hand_on(owner, "shadowbrush_l", "swap_object")
    end
    if owner:HasTag("equipmentmodel") then return end --假人
    inst:AddTag("cansetmode_l") --模式切换必需，没有就代表无法切换
end
pas.OnUnequip_shadowbrush = function(inst, owner)
    TOOLS_L.hand_off(inst, owner)
    inst:RemoveTag("cansetmode_l")
end
pas.SetMode_shadowbrush = function(inst, newmode, doer)
    if inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner then
        if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
            if doer ~= nil then
                if doer.SoundEmitter ~= nil then
                    doer.SoundEmitter:PlaySound("meta5/snowman/place_snow")
                end
                TOOLS_L.SendMouseInfoRPC(doer, inst, { mo = newmode }, true, false)
            end
        end
    end
end
pas.DealData_shadowbrush = function(inst, data)
    return STRINGS.NAMEDETAIL_L.SHADOWBRUSH_MODE[data.mo or 1]
end
pas.GetData_shadowbrush = function(inst)
    return { mo = inst.components.modelegion.now }
end

table.insert(prefs, Prefab("shadowbrush_l", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "shadowbrush_l", nil, nil, nil)
    fns.SetFurnitureDecor_comm(inst)
    fns.SetFloatable(inst, { 0.04, "small", 0.2, 0.5 })
    inst:AddTag("nopunch")
    inst:AddTag("rp_shadow_l")
    inst:AddTag("shadowlevel")
    inst:AddTag("shadow_item")
    TOOLS_L.InitMouseInfo(inst, pas.DealData_shadowbrush, pas.GetData_shadowbrush)
    inst.redetailables = pas.redetailables --直接放这里吧，反正客户端也有这个数据，已经占用了内存

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    fns.ServerFn(inst, "shadowbrush_l", pas.OnEquip_shadowbrush, pas.OnUnequip_shadowbrush)
    fns.SetFurnitureDecor_serv(inst, nil)
    fns.SetFiniteUses(inst, 100, nil)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.RUINS_BAT_SHADOW_LEVEL) --2

    --1：完全随机 2：阶段顺序 3：当前顺序
    inst:AddComponent("modelegion")
    inst.components.modelegion:Init(1, 3, nil, pas.SetMode_shadowbrush)

    inst:AddComponent("z_shadowbrush")
    inst.fn_redetail = pas.DO_shadowbrush

    MakeHauntableLaunch(inst)

    return inst
end, fns.GetAssets("shadowbrush_l"), nil))

--------------------
--------------------

return unpack(prefs)
