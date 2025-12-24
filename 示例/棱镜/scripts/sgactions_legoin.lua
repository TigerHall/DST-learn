local _G = GLOBAL
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()
local TOOLS_L = require("tools_legion")
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas1 = {} --专门放独特的变量
local newaction

fns.TriggerPhysics = function(inst, ison)
    if ison then
        if inst.legiontag_physicsoff then
            inst.legiontag_physicsoff = nil
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.Physics:CollidesWith(COLLISION.OBSTACLES)
            inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
            inst.Physics:CollidesWith(COLLISION.CHARACTERS)
            inst.Physics:CollidesWith(COLLISION.GIANTS)
        end
    else
        if not inst.legiontag_physicsoff then
            inst.legiontag_physicsoff = true
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.GROUND)
        end
    end
end

--------------------------------------------------------------------------
--[[ 统一化的修复组件 ]]
--------------------------------------------------------------------------

if not _G.rawget(_G, "REPAIRERS_L") then
    _G.REPAIRERS_L = {}
end

local function Fn_sg_short(doer, action)
    return "doshortaction"
end
local function Fn_sg_long(doer, action)
    return "dolongaction"
end
local function Fn_sg_handy(doer, action)
    if doer:HasAnyTag("fastbuilder", "fastrepairer", "handyperson") then
        return "doshortaction"
    end
    return "dolongaction"
end
local function Fn_sg_robot_handy(doer, action) --机器人对电能、电子更加了解
    if doer:HasTag("upgrademoduleowner") then
        return "doshortaction"
    end
    return Fn_sg_handy(doer, action)
end

local function CheckForeverEquip(inst, item, doer, now)
    if now > 0 and inst.foreverequip_l ~= nil and inst.foreverequip_l.fn_repaired ~= nil then
        inst.foreverequip_l.fn_repaired(inst, item, doer, now)
    end
end
local function CommonDoerCheck(doer, target)
    if doer.replica.rider ~= nil and doer.replica.rider:IsRiding() then --骑牛时只能修复自己的携带物品
        if not (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer)) then
            return false
        end
    elseif doer.replica.inventory ~= nil and doer.replica.inventory:IsHeavyLifting() then --不能背重物
        return false
    end
    return true
end
local function DoUpgrade(doer, item, target, itemvalue, ismax, defaultreason)
    if item and target and target.components.upgradeable ~= nil then
        local can, reason = target.components.upgradeable:CanUpgrade()
        if not can then
            return false, (reason or defaultreason)
        end

        local cpt = target.components.upgradeable
        local old_stage = cpt.stage
        local numcost = 0
        local num = 1
        local param = cpt.numupgrades
        if ismax and item.components.stackable ~= nil then
            num = item.components.stackable:StackSize()
        end
        for i = 1, num, 1 do
            param = param + itemvalue
            numcost = numcost + 1
            if param >= cpt.upgradesperstage then --数值足够进入下一个阶段了
                local cant = false
                while param >= cpt.upgradesperstage do
                    cpt.stage = cpt.stage + 1
                    if cpt:CanUpgrade() then --如果还能升级，需要保存多出来的数据
                        param = param - cpt.upgradesperstage
                        cant = false
                    else
                        cant = true
                        param = 0
                        break
                    end
                end
                if cant then
                    param = 0
                    break
                end
            end
        end
        cpt.numupgrades = param

        --把过程总结为一次，防止多次重复执行。不过可能会有一些顺序上的小问题，暂时应该不会出现
        if cpt.onupgradefn then
            cpt.onupgradefn(cpt.inst, doer, item)
        end
        if old_stage ~= cpt.stage and cpt.onstageadvancefn then --说明升级了
            cpt.onstageadvancefn(cpt.inst)
        end

        if item.components.stackable ~= nil then
            item.components.stackable:Get(numcost):Remove()
        else
            item:Remove()
        end
        return true
    end
    return false
end
local function DoArmorRepair(doer, item, target, value)
    if
        target ~= nil and
        target.components.armor ~= nil and target.components.armor:GetPercent() < 1
    then
        value = value*(doer.mult_repair_l or 1)
        local cpt = target.components.armor
        local need = TOOLS_L.ComputCost(cpt.condition, cpt.maxcondition, value, item)
        cpt:Repair(value*need)
        CheckForeverEquip(target, item, doer, cpt.condition)
        return true
    end
    return false, "GUITAR"
end
local function DoFiniteusesRepair(doer, item, target, value)
    if target ~= nil and
        target.components.finiteuses ~= nil and target.components.finiteuses:GetPercent() < 1
    then
        value = value*(doer.mult_repair_l or 1)
        local cpt = target.components.finiteuses
        local need = TOOLS_L.ComputCost(cpt.current, cpt.total, value, item)
        cpt:Repair(value*need)
        CheckForeverEquip(target, item, doer, cpt.current)
        return true
    end
    return false, "GUITAR"
end
local function DoFueledRepair(doer, item, target, value, reason)
    if
        target ~= nil and
        target.components.fueled ~= nil and target.components.fueled.accepting and
        target.components.fueled:GetPercent() < 1
    then
        local cpt = target.components.fueled
        local need = TOOLS_L.ComputCost(cpt.currentfuel, cpt.maxfuel, value, item)
        cpt:DoDelta(value*need, doer)
        if cpt.ontakefuelfn ~= nil then
            cpt.ontakefuelfn(target, value)
        end
        target:PushEvent("takefuel", { fuelvalue = value })
        CheckForeverEquip(target, item, doer, cpt.currentfuel)
        return true
    end
    return false, reason
end

--素白蘑菇帽

local function Fn_try_fungus(inst, doer, target, actions, right)
    if target:HasTag("rp_fungus_l") then
        if CommonDoerCheck(doer, target) then
            return true
        end
    end
    return false
end
local function Fn_do_fungus(doer, item, target, value)
    if
        item ~= nil and target ~= nil and
        target.components.perishable ~= nil and target.components.perishable.perishremainingtime ~= nil and
        target.components.perishable.perishremainingtime < target.components.perishable.perishtime
    then
        local useditem = doer.components.inventory:RemoveItem(item) --不做说明的话，一次只取一个
        if useditem then
            local perishable = target.components.perishable
            perishable:SetPercent(perishable:GetPercent() + value)

            useditem:Remove()

            return true
        end
    end
    return false, "FUNGUS"
end

local fungus_needchange = {
    red_cap = 0.05,
    green_cap = 0.05,
    blue_cap = 0.05,
    albicans_cap = 0.15, --素白菇
    spore_small = 0.15,  --绿蘑菇孢子
    spore_medium = 0.15, --红蘑菇孢子
    spore_tall = 0.15,   --蓝蘑菇孢子
    moon_cap = 0.2,      --月亮蘑菇
    shroom_skin = 1
}
for k,v in pairs(fungus_needchange) do
    _G.REPAIRERS_L[k] = {
        fn_try = Fn_try_fungus, fn_sg = Fn_sg_short,
        fn_do = function(act)
            return Fn_do_fungus(act.doer, act.invobject, act.target, v)
        end
    }
end
_G.REPAIRERS_L.albicans_cap.noapiset = true
fungus_needchange = nil

--白木吉他、白木地片

_G.FUELTYPE.GUITAR = "GUITAR"
_G.UPGRADETYPES.MAT_L = "mat_l"

local function Fn_try_guitar(inst, doer, target, actions, right)
    if target:HasTag(FUELTYPE.GUITAR.."_fueled") then
        if CommonDoerCheck(doer, target) then
            return true
        end
    end
    return false
end

_G.REPAIRERS_L["silk"] = {
    fn_try = Fn_try_guitar, --【客户端】
    fn_sg = Fn_sg_handy, --【服务器、客户端】
    fn_do = function(act) --【服务器】
        local value = TUNING.TOTAL_DAY_TIME*0.1*(act.doer.mult_repair_l or 1)
        return DoFueledRepair(act.doer, act.invobject, act.target, value, "GUITAR")
    end
}
_G.REPAIRERS_L["steelwool"] = {
    fn_try = Fn_try_guitar, fn_sg = Fn_sg_handy,
    fn_do = function(act)
        local value = TUNING.TOTAL_DAY_TIME*0.9*(act.doer.mult_repair_l or 1)
        return DoFueledRepair(act.doer, act.invobject, act.target, value, "GUITAR")
    end
}
_G.REPAIRERS_L["mat_whitewood_item"] = {
    noapiset = true,
    fn_try = function(inst, doer, target, actions, right)
        if
            target:HasTag(UPGRADETYPES.MAT_L.."_upgradeable") and
            (doer.replica.rider == nil or not doer.replica.rider:IsRiding()) and
            (doer.replica.inventory == nil or not doer.replica.inventory:IsHeavyLifting())
        then
            return true
        end
        return false
    end,
    fn_sg = Fn_sg_short,
    fn_do = function(act)
        return DoUpgrade(act.doer, act.invobject, act.target, 1, false, "MAT")
    end
}

--砂之抵御

local function Fn_try_sand(inst, doer, target, actions, right)
    if target:HasTag("rp_sand_l") then
        if CommonDoerCheck(doer, target) then
            return true
        end
    end
    return false
end

local rock_needchange = {
    townportaltalisman = 315,
    turf_desertdirt = 105,
    cutstone = 157.5,
    rocks = 52.5,
    flint = 52.5
}
for k,v in pairs(rock_needchange) do
    _G.REPAIRERS_L[k] = {
        fn_try = Fn_try_sand, fn_sg = Fn_sg_handy,
        fn_do = function(act)
            return DoArmorRepair(act.doer, act.invobject, act.target, v)
        end
    }
end
rock_needchange = nil

--犀金胄甲、犀金护甲

local function Fn_try_bugshell(inst, doer, target, actions, right)
    if target:HasTag("rp_bugshell_l") then
        if CommonDoerCheck(doer, target) then
            return true
        end
    end
    return false
end
_G.REPAIRERS_L["insectshell_l"] = {
    noapiset = true, fn_try = Fn_try_bugshell, fn_sg = Fn_sg_handy,
    fn_do = function(act)
        return DoArmorRepair(act.doer, act.invobject, act.target, 105)
    end
}

--月藏宝匣、月轮宝盘、月折宝剑、月炆宝炊

_G.UPGRADETYPES.REVOLVED_L = "revolved_l"
_G.UPGRADETYPES.HIDDEN_L = "hidden_l"
_G.UPGRADETYPES.REFRACTED_L = "refracted_l"
_G.UPGRADETYPES.SIMMER_L = "simmer_l"

local function Fn_try_gem(doer, target, tag)
    if target:HasTag(tag) then
        if CommonDoerCheck(doer, target) then
            return true
        end
    end
    return false
end
local function Fn_do_gem(act)
    return DoUpgrade(act.doer, act.invobject, act.target, 1, true, "YELLOWGEM")
end

_G.REPAIRERS_L["yellowgem"] = {
    fn_try = function(inst, doer, target, actions, right)
        return Fn_try_gem(doer, target, UPGRADETYPES.REVOLVED_L.."_upgradeable")
    end,
    fn_sg = Fn_sg_short, fn_do = Fn_do_gem
}
_G.REPAIRERS_L["bluegem"] = {
    fn_try = function(inst, doer, target, actions, right)
        return Fn_try_gem(doer, target, UPGRADETYPES.HIDDEN_L.."_upgradeable")
    end,
    fn_sg = Fn_sg_short, fn_do = Fn_do_gem
}
_G.REPAIRERS_L["opalpreciousgem"] = {
    fn_try = function(inst, doer, target, actions, right)
        return Fn_try_gem(doer, target, UPGRADETYPES.REFRACTED_L.."_upgradeable")
    end,
    fn_sg = Fn_sg_short, fn_do = Fn_do_gem
}

--胡萝卜长枪

local function Fn_try_carrot(inst, doer, target, actions, right)
    if target:HasTag("rp_carrot_l") then
        if CommonDoerCheck(doer, target) then
            return true
        end
    end
    return false
end
_G.REPAIRERS_L["carrot"] = {
    fn_try = Fn_try_carrot, fn_sg = Fn_sg_handy,
    fn_do = function(act)
        return DoFiniteusesRepair(act.doer, act.invobject, act.target, 25)
    end
}
_G.REPAIRERS_L["carrot_cooked"] = {
    fn_try = Fn_try_carrot, fn_sg = Fn_sg_handy,
    fn_do = function(act)
        return DoFiniteusesRepair(act.doer, act.invobject, act.target, 15)
    end
}

--电气石

_G.FUELTYPE.ELEC_L = "ELEC_L"

local function Fn_try_elec(inst, doer, target, actions, right)
    if target:HasTag(FUELTYPE.ELEC_L.."_fueled") then
        if CommonDoerCheck(doer, target) then
            return true
        end
    end
    return false
end

local elec_needchange = {
    tourmalineshard = 150,
    moonstorm_spark = 70,
    lightninggoathorn = 70,
    goatmilk = 20,
    voltgoatjelly = 50,
    purplegem = 60,
    feather_canary = 15,
    blowdart_yellow = 10,
    oceanfishingbobber_canary = 10
}
for k,v in pairs(elec_needchange) do
    _G.REPAIRERS_L[k] = {
        noapiset = nil, fn_try = Fn_try_elec, fn_sg = Fn_sg_robot_handy,
        fn_do = function(act)
            return DoFueledRepair(act.doer, act.invobject, act.target, v, "ELEC")
        end
    }
end
_G.REPAIRERS_L.tourmalineshard.noapiset = true
elec_needchange = nil

_G.REPAIRERS_L["redgem"] = {
    fn_try = function(inst, doer, target, actions, right)
        if target:HasAnyTag(FUELTYPE.ELEC_L.."_fueled", UPGRADETYPES.SIMMER_L.."_upgradeable") then
            if CommonDoerCheck(doer, target) then
                return true
            end
        end
        return false
    end,
    fn_sg = function(doer, action)
        if action.target ~= nil then
            if action.target:HasTag(FUELTYPE.ELEC_L.."_fueled") then
                return Fn_sg_robot_handy(doer, action)
            end
            return Fn_sg_short(doer, action)
        end
    end,
    fn_do = function(act)
        if act.target ~= nil then
            if act.target:HasTag(FUELTYPE.ELEC_L.."_fueled") then
                return DoFueledRepair(act.doer, act.invobject, act.target, 70, "ELEC")
            end
            return Fn_do_gem(act)
        end
    end
}

--灵魂契约

-- _G.UPGRADETYPES.CONTRACTS_L = "CONTRACTS_L"

-- local function Fn_try_soul(inst, doer, target, actions, right)
--     if target:HasTag(UPGRADETYPES.CONTRACTS_L.."_upgradeable") then
--         if CommonDoerCheck(doer, target) then
--             return true
--         end
--     end
--     return false
-- end

-- local soul_needchange = {
--     ghostflower = 1,
--     genesis_dark_crystal = 4 --【创世纪】黑暗水晶
-- }
-- for k, v in pairs(soul_needchange) do
--     _G.REPAIRERS_L[k] = {
--         noapiset = nil, fn_try = Fn_try_soul, fn_sg = Fn_sg_long,
--         fn_do = function(act)
--             return DoUpgrade(act.doer, act.invobject, act.target, v, true, "YELLOWGEM")
--         end
--     }
-- end
-- soul_needchange = nil

--捉影之镜

local function Fn_try_shadow(inst, doer, target, actions, right)
    if target:HasTag("rp_shadow_l") then
        if CommonDoerCheck(doer, target) then
            return true
        end
    end
    return false
end
_G.REPAIRERS_L["horrorfuel"] = {
    fn_try = function(inst, doer, target, actions, right)
        if target:HasTag("rp_shadow_l") then
            if CommonDoerCheck(doer, target) then
                return true
            end
        end
        return false
    end,
    fn_sg = Fn_sg_handy,
    fn_do = function(act)
        if act.target == nil then return end
        if act.target:HasTag("rp_shadow_l") then
            return DoFiniteusesRepair(act.doer, act.invobject, act.target, 100)
        -- else
        --     return DoUpgrade(act.doer, act.invobject, act.target, 2, true, "YELLOWGEM")
        end
    end
}
_G.REPAIRERS_L["nightmarefuel"] = {
    fn_try = Fn_try_shadow, fn_sg = Fn_sg_handy,
    fn_do = function(act)
        return DoFiniteusesRepair(act.doer, act.invobject, act.target, 50)
    end
}
_G.REPAIRERS_L["petals_evil"] = {
    fn_try = Fn_try_shadow, fn_sg = Fn_sg_handy,
    fn_do = function(act)
        return DoFiniteusesRepair(act.doer, act.invobject, act.target, 10)
    end
}
_G.REPAIRERS_L["petals_nightrose"] = {
    noapiset = true, fn_try = Fn_try_shadow, fn_sg = Fn_sg_handy,
    fn_do = function(act)
        return DoFiniteusesRepair(act.doer, act.invobject, act.target, 25)
    end
}

------

if IsServer then
    for k,v in pairs(_G.REPAIRERS_L) do
        if not v.noapiset then
            AddPrefabPostInit(k, function(inst)
                inst:AddComponent("z_repairerlegion")
            end)
        end
    end
end

--------------------------------------------------------------------------
--[[ 组件动作响应的全局化 ]]
--------------------------------------------------------------------------

------
--ComponentAction_USEITEM_inventoryitem_legion
------

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
    if not right then return end
    if doer.replica.inventory ~= nil then
        if target:HasTag("genetrans") then --物品右键放入子圭·育
            if not doer.replica.inventory:IsHeavyLifting() and
                not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())
            then
                table.insert(actions, ACTIONS.GENETRANS)
            end
        elseif target:HasTag("swordscabbard") then --物品右键尝试入鞘剑鞘
            if not doer.replica.inventory:IsHeavyLifting() then
                if target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer) then
                    table.insert(actions, ACTIONS.ITEMINTOSHEATH_L2)
                else
                    table.insert(actions, ACTIONS.ITEMINTOSHEATH_L)
                end
            end
        end
    end
end)

------
--ComponentAction_SCENE_INSPECTABLE_legion
------

AddComponentAction("SCENE", "inspectable", function(inst, doer, actions, right)
    if not right then return end
    if inst.components.spellbook == nil and doer.replica.inventory ~= nil and
        (doer.HUD == nil or not doer.HUD:IsSpellWheelOpen()) --不要影响按钮轮盘
    then
        local item = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) --优先手部动作
        if item ~= nil then
            if item:HasTag("canshieldatk") then --举盾
                if not doer.legiontag_noshieldatk then
                    table.insert(actions, ACTIONS.ATTACK_SHIELD_L)
                    return
                end
            elseif item:HasTag("s_l_pull") then --羽刃合收
                if not item:HasTag("noskill_l") then
                    table.insert(actions, ACTIONS.RC_SKILL_L)
                end
                return
            elseif item:HasTag("s_l_throw") then --羽刃分掷
                if doer ~= inst then --不应该以自己为目标
                    table.insert(actions, ACTIONS.RC_SKILL_L)
                end
                return
            end
        end
        if doer ~= inst and not doer.replica.inventory:IsHeavyLifting() then
            item = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if item ~= nil then
                if not doer.legiontag_nosivmaskskill and item:HasTag("siv_mask2") then --子圭·歃的技能
                    if inst.prefab == "flower_withered" or inst.prefab == "mandrake" or --枯萎花、死掉的曼德拉草
                        inst:HasAnyTag("playerghost", "ghost") --玩家鬼魂、幽灵
                    then
                        table.insert(actions, ACTIONS.LIFEBEND)
                        return
                    elseif inst:HasTag("_health") then --有生命组件的对象
                        if not inst:HasAnyTag("shadow", "wall", "structure", "balloon") then
                            table.insert(actions, ACTIONS.LIFEBEND)
                            return
                        end
                    elseif inst:HasAllTags("farm_plant", "pickable_harvest_str") or --已枯萎作物
                        inst:HasAnyTag("withered", "barren", --枯萎的植物
                            "weed", --杂草
                            "crop_legion", "crop2_legion", --子圭垄植物、异种植物
                            "lifebox_l" --生命容器
                        )
                    then
                        table.insert(actions, ACTIONS.LIFEBEND)
                        return
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------
--[[ 统一化的修复动作 ]]
--------------------------------------------------------------------------

local REPAIR_LEGION = Action({ priority = 1, mount_valid = true })
REPAIR_LEGION.id = "REPAIR_LEGION"
REPAIR_LEGION.str = STRINGS.ACTIONS.REPAIR_LEGION
REPAIR_LEGION.strfn = function(act)
    if act.target ~= nil then
        if act.target:HasTag("moontreasure_l") then
            return "EMBED"
        elseif act.target:HasTag("eleccore_l") then
            return "CHARGE"
        elseif act.target.prefab == "mat_whitewood" then
            return "MERGE"
        -- elseif act.target.prefab == "soul_contracts" then
        --     return "CONTRACTS"
        end
    end
    return "GENERIC"
end
REPAIR_LEGION.fn = function(act)
    if act.invobject ~= nil and REPAIRERS_L[act.invobject.prefab] then
        return REPAIRERS_L[act.invobject.prefab].fn_do(act)
    end
end
AddAction(REPAIR_LEGION)

AddComponentAction("USEITEM", "z_repairerlegion", function(inst, doer, target, actions, right)
    if right and REPAIRERS_L[inst.prefab] and REPAIRERS_L[inst.prefab].fn_try(inst, doer, target, actions, right) then
        table.insert(actions, ACTIONS.REPAIR_LEGION)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.REPAIR_LEGION, function(inst, action)
    if action.invobject ~= nil and REPAIRERS_L[action.invobject.prefab] then
        return REPAIRERS_L[action.invobject.prefab].fn_sg(inst, action)
    end
end))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.REPAIR_LEGION, function(inst, action)
    if action.invobject ~= nil and REPAIRERS_L[action.invobject.prefab] then
        return REPAIRERS_L[action.invobject.prefab].fn_sg(inst, action)
    end
end))

--------------------------------------------------------------------------
--[[ 一个没有前置时间需求的action的sg ]]
--------------------------------------------------------------------------

local function SayActionFailString(inst, actionname, reason)
    if inst.components.talker ~= nil and reason ~= nil then
        inst.components.talker:Say(GetActionFailString(inst, actionname, reason))
    end
end

AddStategraphState("wilson", State{ name = "doskipaction_l",
    tags = { "idle", "nodangle", "keepchannelcasting" },
    onenter = function(inst)
        inst.components.locomotor:StopMoving()
        if inst:HasTag("beaver") then
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        else
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_pst", false)
        end
        -- inst:PerformBufferedAction()
    end,
    events = {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    }
})

AddStategraphEvent("wilson", EventHandler("noaction_l", function(inst, data)
    if inst.sg:HasStateTag("acting") then
        return
    end
    if inst.sg:HasStateTag("idle") or inst.sg:HasStateTag("channeling") then
        inst.sg:GoToState("doskipaction_l")
    end
end))

--------------------------------------------------------------------------
--[[ 人物StateGraph修改 ]]
--------------------------------------------------------------------------

-- local SGWilson = require "stategraphs/SGwilson" --会使这个文件不再加载，后面新增的动作sg绑定也不会再更新到这里了
-- package.loaded["stategraphs/SGwilson"] = nil --恢复这个文件的加载状态，以便后面的更新

local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/hurt", nil, inst.hurtsoundvolume)
    end
end
local function EquipSpeedItem(inst)
    local backpack = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK or EQUIPSLOTS.BODY) or nil

    if backpack ~= nil and backpack.components.container ~= nil then
        local item1 = backpack.components.container:FindItem(function(item)
            return item.components.equippable ~= nil and item.components.equippable.walkspeedmult ~= nil and item.components.equippable.walkspeedmult > 1
        end)

        if item1 ~= nil then
            inst.components.inventory:Equip(item1)
        end
    end
end
local function EquipFightItem(inst)
    local backpack = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK or EQUIPSLOTS.BODY) or nil

    if backpack ~= nil and backpack.components.container ~= nil then
        local item1 = backpack.components.container:FindItem(function(item)
            if item.components.weapon ~= nil and not item:HasTag("projectile") then
                local dmg = item.components.weapon:GetDamage(inst, nil) or 0
                if dmg > 17 or dmg <= 0 then
                    return true
                end
            end
            return false
        end)

        if item1 ~= nil then
            inst.components.inventory:Equip(item1)
        end
    end
end

AddStategraphPostInit("wilson", function(sg)
    --受击无硬直
    local eve1 = sg.events["attacked"]
    if eve1 then
        local event_fn_attacked = eve1.fn
        eve1.fn = function(inst, data, ...)
            if inst.legiontag_stable then
                if not inst.components.health:IsDead() and
                    not inst.sg:HasStateTag("drowning") and not inst.sg:HasStateTag("falling")
                then
                    if not inst.sg:HasStateTag("sleeping") then --睡袋貌似有自己的特殊机制
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                        DoHurtSound(inst)
                        return
                    end
                end
            end
            return event_fn_attacked(inst, data, ...)
        end
    end

    --防击退
    local eve2 = sg.events["knockback"]
    if eve2 then
        local event_fn_knockback = eve2.fn
        eve2.fn = function(inst, data, ...)
            if --盾反+厚重=防击退
                inst.shield_l_success and inst.components.inventory ~= nil and
                (inst.components.inventory:EquipHasTag("heavyarmor") or inst:HasTag("heavybody"))
            then
                return
            end
            if inst:HasTag("firmbody_l") then --特殊标签防击退
                return
            end
            return event_fn_knockback(inst, data, ...)
        end
    end

    --移动时自动切换加速装备
    local eve3 = sg.events["locomote"]
    if eve3 then
        local event_fn_locomote = eve3.fn
        eve3.fn = function(inst, data, ...)
            if inst.needrun then
                if inst.sg:HasStateTag("busy") then
                    return
                end
                local is_moving = inst.sg:HasStateTag("moving")
                local should_move = inst.components.locomotor:WantsToMoveForward()

                if not (inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("tent") or inst.sg:HasStateTag("waking"))
                    and not (is_moving and not should_move)
                    and (not is_moving and should_move)
                then
                    EquipSpeedItem(inst) --行走之前先换加速装备
                end
            end
            return event_fn_locomote(inst, data, ...)
        end
    end

    --修复子圭护甲与死亡不掉落的兼容问题，这个事件会在角色刚死时后一帧触发，但本身没做死亡判定，导致离开死亡状态而让游戏崩溃
    --但因为游戏本身是死亡会掉落的，装备也会掉落，所以这个概率事件本不该触发到玩家上的
    local eve4 = sg.events["armorbroke"]
    if eve4 then
        local event_fn_armorbroke = eve4.fn
        eve4.fn = function(inst, data, ...)
            if inst.sg:HasStateTag("dead") then
                return
            end
            if data and data.armor and data.armor:HasTag("nobrokesg_l") then --某些护甲损坏时不应该发出声音
                return
            end
            return event_fn_armorbroke(inst, data, ...)
        end
    end

    --攻击时自动切换武器
    local ach2 = sg.actionhandlers[ACTIONS.ATTACK]
    if ach2 then
        local ach_fn_ATTACK = ach2.deststate
        ach2.deststate = function(inst, action, ...)
            if inst.needcombat then
                inst.sg.mem.localchainattack = not action.forced or nil
                if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or inst.components.health:IsDead()) then
                    EquipFightItem(inst) --攻击之前先换攻击装备
                end
            end
            return ach_fn_ATTACK(inst, action, ...)
        end
    end

    -- for k, v in pairs(sg.actionhandlers) do
    --     if v["action"]["id"] == "GIVE" then
    --         local give_handler_fn = v.deststate
    --         v.deststate = function(inst, action)
    --         end
    --         break
    --     end
    -- end
end)

--------------------------------------------------------------------------
--[[ 弹吉他相关 ]]
--------------------------------------------------------------------------

local function ResumeHands(inst)
    local hands = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if hands ~= nil and not hands:HasTag("book") then
        inst.AnimState:Show("ARM_carry")
        inst.AnimState:Hide("ARM_normal")
    end
end

AddStategraphState("wilson", State{ name = "playguitar_pre",
    tags = { "doing", "playguitar" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("soothingplay_pre", false)
        TOOLS_L.hand_off(nil, inst)

        local guitar = inst.bufferedaction ~= nil and (inst.bufferedaction.invobject or inst.bufferedaction.target) or nil
        inst.components.inventory:ReturnActiveActionItem(guitar)

        if guitar ~= nil and guitar.PlayStart ~= nil then --动作的执行处
            guitar:AddTag("busyguitar")
            inst.sg.statemem.instrument = guitar
            guitar.PlayStart(guitar, inst)
            inst:PerformBufferedAction()
        else
            inst:PushEvent("actionfailed", { action = inst.bufferedaction, reason = nil })
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
            return
        end

        inst.sg.statemem.playdoing = false
    end,
    events = {
        EventHandler("equip", function(inst)    --防止装备时改变手的显示状态
            TOOLS_L.hand_off(nil, inst)
        end),
        EventHandler("unequip", function(inst)  --防止卸下时改变手的显示状态
            TOOLS_L.hand_off(nil, inst)
        end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg.statemem.playdoing = true
                inst.sg:GoToState("playguitar_loop", inst.sg.statemem.instrument)
            end
        end)
    },
    onexit = function(inst)
        if not inst.sg.statemem.playdoing then
            ResumeHands(inst)

            if inst.sg.statemem.instrument ~= nil then
                inst.sg.statemem.instrument:RemoveTag("busyguitar")
            end
        end
    end
})
AddStategraphState("wilson", State{ name = "playguitar_loop",
    tags = { "doing", "playguitar" },
    onenter = function(inst, instrument)
        inst.components.locomotor:Stop()
        TOOLS_L.hand_off(nil, inst)

        if instrument ~= nil and instrument.PlayDoing ~= nil then
            instrument.PlayDoing(instrument, inst)
        end

        inst.sg.statemem.instrument = instrument
        inst.sg.statemem.playdoing = false
    end,
    events = {
        EventHandler("equip", function(inst)    --防止装备时改变手的显示状态
            TOOLS_L.hand_off(nil, inst)
        end),
        EventHandler("unequip", function(inst)  --防止卸下时改变手的显示状态
            TOOLS_L.hand_off(nil, inst)
        end),
        EventHandler("playenough", function(inst)
            inst.sg.statemem.playdoing = true
            inst.sg:GoToState("playguitar_pst")
        end)
    },
    onexit = function(inst)
        if not inst.sg.statemem.playdoing then
            ResumeHands(inst)
        end

        if inst.sg.statemem.instrument ~= nil then
            if inst.sg.statemem.instrument.PlayEnd ~= nil then
                inst.sg.statemem.instrument.PlayEnd(inst.sg.statemem.instrument, inst)
            end
            inst.sg.statemem.instrument:RemoveTag("busyguitar")
        end
    end
})
AddStategraphState("wilson", State{ name = "playguitar_pst",
    tags = { "doing", "playguitar" },
    onenter = function(inst)
        inst.components.locomotor:Stop()

        inst.AnimState:PlayAnimation("soothingplay_pst", false)
        TOOLS_L.hand_off(nil, inst)
    end,
    events = {
        EventHandler("equip", function(inst)    --防止装备时改变手的显示状态
            TOOLS_L.hand_off(nil, inst)
        end),
        EventHandler("unequip", function(inst)  --防止卸下时改变手的显示状态
            TOOLS_L.hand_off(nil, inst)
        end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    },
    onexit = function(inst)
        ResumeHands(inst)
    end
})
AddStategraphState("wilson_client", State{ name = "playguitar_client",
    tags = { "doing", "playguitar" },
    onenter = function(inst)
        inst.components.locomotor:Stop()

        inst.AnimState:PlayAnimation("soothingplay_pre", false)
        -- TOOLS_L.hand_off(nil, inst)

        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
        if inst:HasTag("doing") then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,
    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end
})

local PLAYGUITAR = Action({ priority = 5, mount_valid = false })
PLAYGUITAR.id = "PLAYGUITAR"
PLAYGUITAR.str = STRINGS.ACTIONS_LEGION.PLAYGUITAR
PLAYGUITAR.fn = function(act)
    return true --我把具体操作加进sg中了，不再在动作这里执行
end
AddAction(PLAYGUITAR)

AddComponentAction("INVENTORY", "instrument", function(inst, doer, actions, right)
    if inst and inst:HasTag("guitar") and doer ~= nil and doer:HasTag("player") then
        table.insert(actions, ACTIONS.PLAYGUITAR) --这里为动作的id
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.PLAYGUITAR, function(inst, action)
    if
        (inst.sg and inst.sg:HasStateTag("busy"))
        or (action.invobject ~= nil and action.invobject:HasTag("busyguitar"))
        or (inst.components.rider ~= nil and inst.components.rider:IsRiding())
    then
        return
    end
    return "playguitar_pre"
end))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.PLAYGUITAR, function(inst, action)
    if
        (inst.sg and inst.sg:HasStateTag("busy"))
        or (action.invobject ~= nil and action.invobject:HasTag("busyguitar"))
        or (inst.replica.rider ~= nil and inst.replica.rider:IsRiding())
    then
        return
    end
    return "playguitar_client"
end))

--------------------------------------------------------------------------
--[[ 添加触电相关的sg ]]
--------------------------------------------------------------------------

local function ClearStatusAilments(inst)
    if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
        inst.components.freezable:Unfreeze()
    end
    if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
        inst.components.pinnable:Unstick()
    end
end

AddStategraphState("wilson", State{ name = "shocked_enter",
    tags = { "busy", "nopredict", "nodangle", "shocked_l" },
    onenter = function(inst)
        ClearStatusAilments(inst)
        TOOLS_L.ForceStopHeavyLifting(inst)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        inst.components.inventory:Hide()    --物品栏与科技栏消失
        inst:PushEvent("ms_closepopups")    --关掉打开着的箱子、冰箱等
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(false)   --不能打开地图
            inst.components.playercontroller:Enable(false)  --玩家不能操控
            -- inst.components.playercontroller:RemotePausePrediction()
        end

        inst.AnimState:PlayAnimation("shock", true)
    end,
    events = {
        EventHandler("unshocked", function(inst)
            inst.sg:GoToState("shocked_exit")
        end),
        EventHandler("attacked", function(inst)
            inst.sg:GoToState("shocked_exit")
        end)
    },
    onexit = function(inst)
        inst.components.inventory:Show()
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(true)
            inst.components.playercontroller:Enable(true)
        end

        if inst.components.shockable ~= nil then
            inst.components.shockable:Unshock()
        end
    end
})
AddStategraphState("wilson", State{ name = "shocked_exit",
    tags = { "idle", "canrotate", "nodangle" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        inst.AnimState:PlayAnimation("shock_pst")

        inst.sg:SetTimeout(6 * FRAMES)
    end,
    ontimeout = function(inst)
        inst.sg:GoToState("idle", true)
    end
})

--通过api添加触电响应函数
AddStategraphEvent("wilson", EventHandler("beshocked", function(inst)
    if inst.components.health ~= nil and not inst.components.health:IsDead() then
        --防止重复进入sg导致触发 onexit 中的 Unshock() 而导致连续麻痹时会失效
        if not inst.sg:HasAnyStateTag("shocked_l", "nointerrupt") then
            inst.sg:GoToState("shocked_enter")
        end
    end
end))

--------------------------------------------------------------------------
--[[ 盾反动作 ]]
--------------------------------------------------------------------------

AddStategraphState("wilson", State{ name = "atk_shield_l",
    tags = { "atk_shield", "busy", "notalking", "autopredict" },
    onenter = function(inst)
        -- if inst.components.combat:InCooldown() then
        --     inst:ClearBufferedAction()
        --     inst.sg:GoToState("idle", true)
        --     return
        -- end

        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if
            equip == nil or equip.components.shieldlegion == nil or
            not equip.components.shieldlegion:CanAttack(inst)
        then
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end
        inst.sg.statemem.shield = equip

        inst.components.locomotor:Stop()
        if inst.components.rider:IsRiding() then
            inst.AnimState:PlayAnimation("player_atk_pre")
            inst.AnimState:PushAnimation("player_atk", false)
        else
            inst.AnimState:PlayAnimation("toolpunch")
        end
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, inst.sg.statemem.attackvol, true)
        inst.sg:SetTimeout(13 * FRAMES)

        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            if buffaction.target ~= nil then
                inst:ForceFacePoint(buffaction.target.Transform:GetWorldPosition())
            elseif buffaction.pos ~= nil then
                inst:ForceFacePoint(buffaction:GetActionPoint():Get())
            end
        end

        equip.components.shieldlegion:StartAttack(inst)
        inst.components.combat:ResetCooldown() --(服务器)重置攻击冷却
    end,
    timeline = {
        TimeEvent(8 * FRAMES, function(inst)
            inst:PerformBufferedAction()
        end)
    },
    ontimeout = function(inst)
        -- inst.sg:RemoveStateTag("atk_shield")
        inst.sg:RemoveStateTag("busy")
        inst.sg:AddStateTag("idle")
    end,
    events = {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    },
    onexit = function(inst)
        if inst.sg.statemem.shield then
            inst.sg.statemem.shield.components.shieldlegion:FinishAttack(inst, true)
        end
    end
})
AddStategraphState("wilson_client", State{ name = "atk_shield_l",
    tags = { "atk_shield", "notalking", "abouttoattack" },
    onenter = function(inst)
        -- if inst.replica.combat ~= nil then
        --     if inst.replica.combat:InCooldown() then
        --         inst.sg:RemoveStateTag("abouttoattack")
        --         inst:ClearBufferedAction()
        --         inst.sg:GoToState("idle", true)
        --         return
        --     end
        -- end

        local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equip == nil or not equip:HasTag("canshieldatk") then
            inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end

        inst.components.locomotor:Stop()
        local rider = inst.replica.rider
        if rider ~= nil and rider:IsRiding() then
            inst.AnimState:PlayAnimation("player_atk_pre")
            inst.AnimState:PushAnimation("player_atk", false)
        else
            inst.AnimState:PlayAnimation("toolpunch")
        end
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
        inst.sg:SetTimeout(13 * FRAMES)

        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()

            if buffaction.target ~= nil then
                inst:ForceFacePoint(buffaction.target.Transform:GetWorldPosition())
            elseif buffaction.pos ~= nil then
                inst:ForceFacePoint(buffaction:GetActionPoint():Get())
            end
        end
        inst.replica.combat:CancelAttack() --(客户端)重置攻击冷却
    end,
    timeline ={
        TimeEvent(8 * FRAMES, function(inst)
            inst:ClearBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
        end)
    },
    ontimeout = function(inst)
        -- inst.sg:RemoveStateTag("atk_shield")
        inst.sg:AddStateTag("idle")
    end,
    events = {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    },
    -- onexit = nil
})

local ATTACK_SHIELD_L = Action({ priority=12, rmb=true, mount_valid=true, distance=36 })
ATTACK_SHIELD_L.id = "ATTACK_SHIELD_L"
ATTACK_SHIELD_L.str = STRINGS.ACTIONS_LEGION.ATTACK_SHIELD_L
ATTACK_SHIELD_L.fn = function(act) return true end
AddAction(ATTACK_SHIELD_L)

AddComponentAction("POINT", "shieldlegion", function(inst, doer, pos, actions, right)
    if right and not doer.legiontag_noshieldatk and inst:HasTag("canshieldatk") and
        not TheWorld.Map:IsGroundTargetBlocked(pos) and
        not doer:HasAnyTag("steeringboat", "rotatingboat")
    then
        table.insert(actions, ACTIONS.ATTACK_SHIELD_L)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ATTACK_SHIELD_L, function(inst, action)
    if
        inst.sg:HasStateTag("atk_shield") or inst.sg:HasStateTag("busy") or inst:HasTag("busy") or
        (action.invobject == nil and action.target == nil)
        -- or action.invobject.components.shieldlegion == nil or
        -- not action.invobject.components.shieldlegion:CanAttack(inst)
    then
        return
    end
    return "atk_shield_l"
end))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ATTACK_SHIELD_L, function(inst, action)
    if
        inst.sg:HasStateTag("atk_shield") or inst.sg:HasStateTag("busy") or inst:HasTag("busy") or
        (action.invobject == nil and action.target == nil)
        -- or not action.invobject:HasTag("canshieldatk")
    then
        return
    end
    return "atk_shield_l"
end))

--------------------------------------------------------------------------
--[[ 惊恐sg ]]
--------------------------------------------------------------------------

local function WakePlayerUp(inst)
    if inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("tent") or inst.sg:HasStateTag("waking") then
        if inst.sleepingbag ~= nil and inst.sg:HasStateTag("sleeping") then
            inst.sleepingbag.components.sleepingbag:DoWakeUp()
            inst.sleepingbag = nil
        end
        return false
    else
        return true
    end
end

AddStategraphState("wilson", State{ name = "volcanopaniced",
    tags = { "busy", "nopredict", "nodangle", "canrotate" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        local it = math.random()
        if it < 0.25 then
            inst.AnimState:PlayAnimation("idle_lunacy_pre")
            inst.AnimState:PushAnimation("idle_lunacy_loop", false)
        elseif it < 0.5 then
            inst.AnimState:PlayAnimation("idle_lunacy_pre")
            inst.AnimState:PushAnimation("idle_lunacy_loop", false)
        elseif it < 0.75 then
            inst.AnimState:PlayAnimation("idle_inaction_sanity")
        else
            inst.AnimState:PlayAnimation("idle_inaction_lunacy")
        end

        inst.sg:SetTimeout(16 * FRAMES) --约半秒
    end,
    events = {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    },
    ontimeout = function(inst)
        inst.sg:RemoveStateTag("busy")
    end
})

AddStategraphEvent("wilson", EventHandler("bevolcanopaniced", function(inst)
    if inst.components.health ~= nil and not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
        if WakePlayerUp(inst) then
            inst.sg:GoToState("volcanopaniced")
        end
    end
end))

--------------------------------------------------------------------------
--[[ 拉粑粑推进sg ]]
--------------------------------------------------------------------------

AddStategraphState("wilson", State{ name = "awkwardpropeller",
    tags = { "pausepredict" },
    onenter = function(inst, data)
        TOOLS_L.ForceStopHeavyLifting(inst)
        -- inst.components.locomotor:Stop()
        -- inst:ClearBufferedAction()

        inst.AnimState:PlayAnimation("hit")

        -- inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")

        if data ~= nil and data.angle ~= nil then
            inst.Transform:SetRotation(data.angle)
        end
        inst.Physics:SetMotorVel(3, 0, 0)

        inst.sg:SetTimeout(0.2)
    end,
    ontimeout = function(inst)
        inst.Physics:Stop()
        inst.sg.statemem.speedfinish = true
    end,
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    },
    onexit = function(inst)
        if not inst.sg.statemem.speedfinish then
            inst.Physics:Stop()
        end
    end
})

AddStategraphEvent("wilson", EventHandler("awkwardpropeller", function(inst, data)
    if
        not inst.sg:HasStateTag("busy") and
        not inst.sg:HasStateTag("overridelocomote") and
        inst.components.health ~= nil and not inst.components.health:IsDead()
    then
        if WakePlayerUp(inst) then
            --将玩家甩下背（因为被玩家恶心到了）
            local mount = inst.components.rider ~= nil and inst.components.rider:GetMount() or nil
            if mount ~= nil and mount.components.rideable ~= nil then
                if mount._bucktask ~= nil then --rideable:Buck()里应该已经触发这个task取消了，先留着吧
                    mount._bucktask:Cancel()
                    mount._bucktask = nil
                end
                mount.components.rideable:Buck()
            else
                inst.sg:GoToState("awkwardpropeller", data)
            end
        end
    end
end))

--------------------------------------------------------------------------
--[[ 青枝绿叶相关 ]]
--------------------------------------------------------------------------

------出鞘

local PULLOUTSWORD = Action({ priority = 2, mount_valid = true, encumbered_valid = true })
PULLOUTSWORD.id = "PULLOUTSWORD"
PULLOUTSWORD.str = STRINGS.ACTIONS_LEGION.PULLOUTSWORD
PULLOUTSWORD.fn = function(act)
    if act.target ~= nil and act.target.components.swordscabbard ~= nil and act.doer ~= nil then
        act.target.components.swordscabbard:BreakUp(act.doer)
        return true
    end
end
AddAction(PULLOUTSWORD)

--Tip: 如果 instant 为 true，表示这个动作不管距离和动画立即执行，此时最好不要给该动作设置 ActionHandler
--一般用于物品栏动作。这种方式在失败时，需要主动写失败台词的触发
local PULLOUTSWORD2 = Action({ priority = 2, mount_valid = true, encumbered_valid = true, instant = true })
PULLOUTSWORD2.id = "PULLOUTSWORD2"
PULLOUTSWORD2.str = STRINGS.ACTIONS_LEGION.PULLOUTSWORD
PULLOUTSWORD2.fn = function(act)
    if act.invobject ~= nil and act.invobject.components.swordscabbard ~= nil and act.doer ~= nil then
        act.invobject.components.swordscabbard:BreakUp(act.doer)
        act.doer:PushEvent("noaction_l")
        return true
    end
end
AddAction(PULLOUTSWORD2)

--往具有某组件的物品添加动作的检测函数，如果满足条件，就向人物的动作可执行表中加入某个动作。right表示是否是右键动作
AddComponentAction("INVENTORY", "swordscabbard", function(inst, doer, actions, right)
    table.insert(actions, ACTIONS.PULLOUTSWORD2)
end)
AddComponentAction("SCENE", "swordscabbard", function(inst, doer, actions, right)
    if right then
        table.insert(actions, ACTIONS.PULLOUTSWORD)
    end
end)

--将一个动作与state绑定
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.PULLOUTSWORD, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.PULLOUTSWORD, "doshortaction"))

------右键剑鞘尝试将手持物入鞘

local function TryIntoSheath(doer, scabbard, sword)
    if scabbard ~= nil and scabbard.components.emptyscabbardlegion ~= nil then
        return scabbard.components.emptyscabbardlegion:PutInto(doer, sword, nil)
    end
end

local INTOSHEATH_L = Action({ priority = 2, mount_valid = true })
INTOSHEATH_L.id = "INTOSHEATH_L"
INTOSHEATH_L.str = STRINGS.ACTIONS_LEGION.SCABBARD
INTOSHEATH_L.fn = function(act)
    if act.doer ~= nil and act.doer.components.inventory ~= nil then
        local sword = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        return TryIntoSheath(act.doer, act.target, sword)
    end
end
AddAction(INTOSHEATH_L)

local INTOSHEATH_L2 = Action({ priority = 2, mount_valid = true, instant = true })
INTOSHEATH_L2.id = "INTOSHEATH_L2"
INTOSHEATH_L2.str = STRINGS.ACTIONS_LEGION.SCABBARD
INTOSHEATH_L2.fn = function(act)
    if act.doer ~= nil and act.doer.components.inventory ~= nil then
        local sword = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        local able, reason = TryIntoSheath(act.doer, act.invobject, sword)
        if able then
            act.doer:PushEvent("noaction_l")
            return true
        else
            SayActionFailString(act.doer, "INTOSHEATH_L2", reason)
            return false, reason
        end
    end
end
AddAction(INTOSHEATH_L2)

AddComponentAction("INVENTORY", "emptyscabbardlegion", function(inst, doer, actions, right)
    table.insert(actions, ACTIONS.INTOSHEATH_L2)
end)
AddComponentAction("SCENE", "emptyscabbardlegion", function(inst, doer, actions, right)
    if right then
        table.insert(actions, ACTIONS.INTOSHEATH_L)
    end
end)

--Tip：有的sg动画需要"wilson"和"wilson_client"都有才行，否则就会出现动作执行了，但没有任何人物动画的情况
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.INTOSHEATH_L, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.INTOSHEATH_L, "give"))

------鼠标物品右键剑鞘尝试将其入鞘

local ITEMINTOSHEATH_L = Action({ priority = 2, mount_valid = true })
ITEMINTOSHEATH_L.id = "ITEMINTOSHEATH_L"
ITEMINTOSHEATH_L.str = STRINGS.ACTIONS_LEGION.SCABBARD
ITEMINTOSHEATH_L.fn = function(act)
    return TryIntoSheath(act.doer, act.target, act.invobject)
end
AddAction(ITEMINTOSHEATH_L)

local ITEMINTOSHEATH_L2 = Action({ priority = 2, mount_valid = true, instant = true })
ITEMINTOSHEATH_L2.id = "ITEMINTOSHEATH_L2"
ITEMINTOSHEATH_L2.str = STRINGS.ACTIONS_LEGION.SCABBARD
ITEMINTOSHEATH_L2.fn = function(act)
    if act.doer ~= nil then
        local able, reason = TryIntoSheath(act.doer, act.target, act.invobject)
        if able then
            act.doer:PushEvent("noaction_l")
            return true
        else
            SayActionFailString(act.doer, "ITEMINTOSHEATH_L2", reason)
            return false, reason
        end
    end
end
AddAction(ITEMINTOSHEATH_L2)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ITEMINTOSHEATH_L, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ITEMINTOSHEATH_L, "give"))

--------------------------------------------------------------------------
--[[ 模式切换相关 ]]
--------------------------------------------------------------------------

local SETMODE_L = Action({ priority = 2, mount_valid = true })
SETMODE_L.id = "SETMODE_L"
SETMODE_L.str = STRINGS.ACTIONS.SETMODE_L
SETMODE_L.strfn = function(act)
    local obj = act.target or act.invobject
    if obj ~= nil then
        if obj:HasTag("modemystery_l") then
            return "MYSTERY"
        elseif obj:HasTag("vaseherb") then
            return "TOUCH"
        end
    end
    return "GENERIC"
end
SETMODE_L.fn = function(act)
    if act.doer ~= nil and act.target ~= nil and act.target.components.modelegion ~= nil then
        local able, reason = act.target.components.modelegion:SetMode(nil, act.doer, false)
        if not able then
            return false, reason
        end
        return true
    end
end
AddAction(SETMODE_L)

local SETMODE_L2 = Action({ priority = 2, mount_valid = true, instant = true })
SETMODE_L2.id = "SETMODE_L2"
SETMODE_L2.str = STRINGS.ACTIONS.SETMODE_L
SETMODE_L2.strfn = SETMODE_L.strfn
SETMODE_L2.fn = function(act)
    if act.doer ~= nil and act.invobject ~= nil and act.invobject.components.modelegion ~= nil then
        local able, reason = act.invobject.components.modelegion:SetMode(nil, act.doer, false)
        if able then
            act.doer:PushEvent("noaction_l")
            return true
        else
            -- SayActionFailString(act.doer, "SETMODE_L2", reason)
            return false, reason
        end
    end
end
AddAction(SETMODE_L2)

AddComponentAction("INVENTORY", "modelegion", function(inst, doer, actions, right)
    if inst:HasTag("cansetmode_l") then
        table.insert(actions, ACTIONS.SETMODE_L2)
    end
end)
AddComponentAction("SCENE", "modelegion", function(inst, doer, actions, right)
    if right and inst:HasTag("cansetmode_l") then
        table.insert(actions, ACTIONS.SETMODE_L)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SETMODE_L, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SETMODE_L, "give"))

--------------------------------------------------------------------------
--[[ 月折宝剑相关 ]]
--------------------------------------------------------------------------

AddStategraphState("wilson", State{ name = "moonsurge_l",
    tags = { "doing", "busy", "canrotate" },
    onenter = function(inst)
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equip == nil or not equip:HasAnyTag("canmoonsurge_l", "cansurge_l") then
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end

        -- inst.AnimState:PlayAnimation("staff_pre")
        -- inst.AnimState:PushAnimation("staff", false)
        inst.AnimState:PlayAnimation("staff") --太拖沓了，直接不要staff_pre那部分的
        inst.components.locomotor:Stop()
        inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam", "lightstart", 0.3)

        local fx_skylight = SpawnPrefab(equip:HasTag("canmoonsurge_l") and "refracted_l_skylight_fx" or "refracted_l_light_fx")
        if fx_skylight ~= nil then
            fx_skylight.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end,
    timeline = {
        TimeEvent(21 * FRAMES, function(inst)
            inst.AnimState:SetFrame(47) --施法动画太长了，直接跳过拖沓的部分
        end),
        TimeEvent(25 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/beam_stop", nil, 0.4)
            inst.SoundEmitter:KillSound("lightstart")
        end),
        TimeEvent(29 * FRAMES, function(inst)
            inst:PerformBufferedAction()
            inst.sg:RemoveStateTag("busy")
            inst.sg:AddStateTag("idle")
            local fx = SpawnPrefab("refracted_l_wave_fx")
            if fx ~= nil then
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        end)
    },
    events = {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    },
    onexit = function(inst)
        inst.SoundEmitter:KillSound("lightstart")
    end
})
AddStategraphState("wilson_client", State{ name = "moonsurge_l",
    tags = { "doing", "busy", "canrotate" },
    server_states = { "moonsurge_l" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        -- inst.AnimState:PlayAnimation("staff_pre")
        -- inst.AnimState:PushAnimation("staff_lag", false)
        inst.AnimState:PlayAnimation("staff") --太拖沓了，直接不要staff_pre那部分的

        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,
    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end,
    timeline = {
        TimeEvent(21 * FRAMES, function(inst)
            inst.AnimState:SetFrame(47) --施法动画太长了，直接跳过拖沓的部分
        end),
        TimeEvent(29 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
            inst.sg:AddStateTag("idle")
        end)
    }
})

local MOONSURGE_L = Action({ priority = 5, mount_valid = true })
MOONSURGE_L.id = "MOONSURGE_L"
MOONSURGE_L.str = STRINGS.ACTIONS.MOONSURGE_L
MOONSURGE_L.strfn = function(act)
    if act.invobject ~= nil and act.invobject:HasTag("canmoonsurge_l") then
        return "GENERIC"
    end
    return "LACK"
end
MOONSURGE_L.fn = function(act)
    if act.invobject ~= nil and act.invobject.fn_tryRevolt ~= nil then
        act.invobject.fn_tryRevolt(act.invobject, act.doer)
    end
    return true
end
AddAction(MOONSURGE_L)

AddComponentAction("EQUIPPED", "z_refractedmoonlight", function(inst, doer, target, actions, right)
    if
        right and
        doer == target and --对自己使用
        inst:HasAnyTag("canmoonsurge_l", "cansurge_l")
    then
        table.insert(actions, ACTIONS.MOONSURGE_L)
    end
end)
AddComponentAction("INVENTORY", "z_refractedmoonlight", function(inst, doer, actions, right)
    if
        inst:HasAnyTag("canmoonsurge_l", "cansurge_l") and
        inst.replica.equippable ~= nil and inst.replica.equippable:IsEquipped() and
        doer.replica.inventory ~= nil and doer.replica.inventory:IsOpenedBy(doer)
    then
        table.insert(actions, ACTIONS.MOONSURGE_L)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MOONSURGE_L, "moonsurge_l"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MOONSURGE_L, "moonsurge_l"))

--------------------------------------------------------------------------
--[[ 素白蘑菇帽相关 ]]
--------------------------------------------------------------------------

AddStategraphState("wilson", State{ name = "release_spores",
    tags = { "busy", "doing", "canrotate" },
    onenter = function(inst, hat)
        if hat == nil then
            inst.sg:GoToState("idle")
            return
        end
        inst.sg.statemem.hat = hat
        inst.sg.statemem.fxcolour = hat.fxcolour or { 1, 1, 1 }
        inst.sg.statemem.castsound = hat.castsound

        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:Enable(false)
        end
        inst.AnimState:PlayAnimation("cointoss_pre")
        inst.AnimState:PushAnimation("cointoss", false)
        inst.components.locomotor:Stop()
    end,
    events = {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },
    timeline = {
        TimeEvent(7 * FRAMES, function(inst)
            inst.sg.statemem.stafffx = SpawnPrefab((inst.components.rider ~= nil and inst.components.rider:IsRiding()) and "cointosscastfx_mount" or "cointosscastfx")
            inst.sg.statemem.stafffx.AnimState:OverrideSymbol("coin01", "albicansspore_fx", "coin01")
            inst.sg.statemem.stafffx.entity:SetParent(inst.entity)
            inst.sg.statemem.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.sg.statemem.stafffx:SetUp(inst.sg.statemem.fxcolour)
        end),
        TimeEvent(15 * FRAMES, function(inst)
            inst.sg.statemem.stafflight = SpawnPrefab("staff_castinglight")
            inst.sg.statemem.stafflight.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.sg.statemem.stafflight:SetUp(inst.sg.statemem.fxcolour, 1.2, .33)
        end),
        TimeEvent(13 * FRAMES, function(inst)
            if inst.sg.statemem.castsound then
                inst.SoundEmitter:PlaySound(inst.sg.statemem.castsound)
            end
        end),
        TimeEvent(43*FRAMES, function(inst)
            SpawnPrefab("albicanscloud_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end),
        TimeEvent(53 * FRAMES, function(inst)
            inst.sg.statemem.stafffx = nil --Can't be cancelled anymore
            inst.sg.statemem.stafflight = nil --Can't be cancelled anymore
            if inst.sg.statemem.hat.releasedfn ~= nil then
                inst.sg.statemem.hat:releasedfn(inst)
            end
        end),
    },
    onexit = function(inst)
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:Enable(true)
        end
        if inst.sg.statemem.stafffx ~= nil and inst.sg.statemem.stafffx:IsValid() then
            inst.sg.statemem.stafffx:Remove()
        end
        if inst.sg.statemem.stafflight ~= nil and inst.sg.statemem.stafflight:IsValid() then
            inst.sg.statemem.stafflight:Remove()
        end
        if inst.sg.statemem.hat.components.useableitem ~= nil then
            inst.sg.statemem.hat.components.useableitem:StopUsingItem()
        end
    end
})

--------------------------------------------------------------------------
--[[ 让种子能种在 子圭·垄 和 异种植物 里 ]]
--------------------------------------------------------------------------

local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local WEIGHTED_SEED_TABLE = require("prefabs/weed_defs").weighted_seed_table

local function PickFarmPlant()
	if math.random() < TUNING.FARM_PLANT_RANDOMSEED_WEED_CHANCE then
		return weighted_random_choice(WEIGHTED_SEED_TABLE)
	else
		local weights = {}
		for k, v in pairs(VEGGIES) do
			weights[k] = v.seed_weight * (
                (PLANT_DEFS[k] and PLANT_DEFS[k].good_seasons[TheWorld.state.season]) and TUNING.SEED_WEIGHT_SEASON_MOD or 1
            )
		end

		return "farm_plant_"..weighted_random_choice(weights)
	end
    return "weed_forgetmelots"
end
local function OnPlant(seed, doer, soilorcrop)
    if seed.components.farmplantable ~= nil and seed.components.farmplantable.plant ~= nil then
        local pt = soilorcrop:GetPosition()

        local plant_prefab = nil
        if seed.prefab == "medal_weed_seeds" then --【能力勋章】杂草种子
            local weedtable = { --勋章里的权重和官方设置不一样，不然我就直接用 weighted_seed_table 了
                weed_forgetmelots = 2, --必忘我
                weed_tillweed = 1, --犁地草
                weed_firenettle = 1, --火荨麻
                weed_ivy = 1 --刺针旋花
            }
            plant_prefab = weighted_random_choice(weedtable)
        else
            plant_prefab = FunctionOrValue(seed.components.farmplantable.plant, seed)
            if plant_prefab == "farm_plant_randomseed" then
                plant_prefab = PickFarmPlant()
            end
        end

        if --【能力勋章】能否种植其中作物
            not _G.CONFIGS_LEGION.SIVSOLTOMEDAL and (
                seed.prefab == "immortal_fruit_seed" or
                seed.prefab == "medal_gift_fruit_seed" or
                plant_prefab == "farm_plant_immortal_fruit" or
                plant_prefab == "farm_plant_medal_gift_fruit"
            )
        then
            return false
        end

        local plant = SpawnPrefab(plant_prefab.."_legion")
        if plant ~= nil then
            plant.Transform:SetPosition(pt:Get())
            -- plant:PushEvent("on_planted", { doer = doer, seed = seed, in_soil = true })
            if plant.SoundEmitter ~= nil then
				plant.SoundEmitter:PlaySound("dontstarve/common/plant")
			end
            TheWorld:PushEvent("itemplanted", { doer = doer, pos = pt })

            --继承皮肤
            local skin = soilorcrop.components.skinedlegion and soilorcrop.components.skinedlegion:GetSkin() or nil
            if skin ~= nil then
                plant.components.skinedlegion:SetSkin(skin, LS_C_UserID(soilorcrop, doer))
            end

            --替换原本的作物
            if soilorcrop.components.perennialcrop ~= nil then
                plant.components.perennialcrop:DisplayCrop(soilorcrop, doer)
            end

            soilorcrop:Remove()
            seed:Remove()

            if plant.fn_planted ~= nil then
                plant.fn_planted(plant, pt)
            end

            return true
        end
    end
    return false
end

local PLANTSOIL_LEGION = Action({ theme_music = "farming", priority = 3 })
PLANTSOIL_LEGION.id = "PLANTSOIL_LEGION"
PLANTSOIL_LEGION.str = STRINGS.ACTIONS.PLANTSOIL_LEGION
PLANTSOIL_LEGION.strfn = function(act)
    if act.target ~= nil then
        if act.target:HasTag("crop_legion") then
            return "DISPLAY"
        elseif act.target:HasTag("crop2_legion") then
            return "CLUSTERED"
        end
    end
    return "GENERIC"
end
PLANTSOIL_LEGION.fn = function(act)
    if
        act.invobject ~= nil and
        act.doer.components.inventory ~= nil and
        act.target ~= nil and act.target:IsValid()
    then
        if act.target:HasTag("soil_legion") or act.target.components.perennialcrop ~= nil then
            local seed = act.doer.components.inventory:RemoveItem(act.invobject)
            if seed ~= nil then
                if OnPlant(seed, act.doer, act.target) then
                    return true
                end
                act.doer.components.inventory:GiveItem(seed)
            end
        elseif act.target.components.perennialcrop2 ~= nil then
            return act.target.components.perennialcrop2:ClusteredPlant(act.invobject, act.doer)
        end
    end
end
AddAction(PLANTSOIL_LEGION)

AddComponentAction("USEITEM", "farmplantable", function(inst, doer, target, actions, right)
    if (target:HasTag("soil_legion") or target:HasTag("crop_legion")) and not target:HasTag("NOCLICK") then
        table.insert(actions, ACTIONS.PLANTSOIL_LEGION)
    end
end)
AddComponentAction("USEITEM", "plantablelegion", function(inst, doer, target, actions, right)
    if right and target:HasTag("crop2_legion") and not target:HasTag("NOCLICK") then
        table.insert(actions, ACTIONS.PLANTSOIL_LEGION)
    end
end)

local function FnSgPlantLegion(inst, action)
    if
        inst:HasTag("fastbuilder") or inst:HasTag("fastpicker")
        or ( --八戒要不饥饿时空手采摘才会加快
            inst:HasTag("pigsy")
            and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == nil
            and inst.replica.hunger:GetCurrent() >= 50
        )
    then
        return "domediumaction"
    else
        return "dolongaction"
    end
end
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.PLANTSOIL_LEGION, FnSgPlantLegion))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.PLANTSOIL_LEGION, FnSgPlantLegion))

--------------------------------------------------------------------------
--[[ 让肥料能给 子圭·垄植物、异种植物、颤栗树之心等特殊对象 施肥 ]]
--------------------------------------------------------------------------

local FERTILIZE_LEGION = Action({ priority = 1 })
FERTILIZE_LEGION.id = "FERTILIZE_LEGION"
FERTILIZE_LEGION.str = STRINGS.ACTIONS.FERTILIZE
FERTILIZE_LEGION.fn = function(act)
    if
        act.invobject ~= nil and act.invobject.components.fertilizer ~= nil
        and act.target ~= nil
    then
        if act.target.components.perennialcrop ~= nil then
            return act.target.components.perennialcrop:Fertilize(act.invobject, act.doer, nil, nil)
        elseif act.target.components.perennialcrop2 ~= nil then
            if act.target.components.perennialcrop2:Fertilize(act.invobject, act.doer) then
                act.invobject.components.fertilizer:OnApplied(act.doer, act.target)
                return true
            else
                return false
            end
        elseif act.target.components.shyerrygrow ~= nil then
            return act.target.components.shyerrygrow:Fertilize(act.invobject, act.doer, nil, nil)
        end
    end
    return false
end
AddAction(FERTILIZE_LEGION)

AddComponentAction("USEITEM", "fertilizer", function(inst, doer, target, actions, right)
    if
        target:HasTag("fertableall_l") or
        (inst:HasTag("fert1_l") and target:HasTag("fertable1_l")) or
        (inst:HasTag("fert2_l") and target:HasTag("fertable2_l")) or
        (inst:HasTag("fert3_l") and target:HasTag("fertable3_l"))
    then
        table.insert(actions, ACTIONS.FERTILIZE_LEGION)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.FERTILIZE_LEGION, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.FERTILIZE_LEGION, "doshortaction"))

--------------------------------------------------------------------------
--[[ 照顾相关的与多年生作物兼容 ]]
--------------------------------------------------------------------------

--修正照顾作物的动作名字
local strfn_INTERACT_WITH = ACTIONS.INTERACT_WITH.strfn
ACTIONS.INTERACT_WITH.strfn = function(act)
    if act.target ~= nil and act.target:HasTag("tendable_farmplant") then
        return "FARM_PLANT"
    end
    return strfn_INTERACT_WITH(act)
end

------让果蝇能影响多年生作物照顾
local ATTACKPLANT_old = ACTIONS.ATTACKPLANT.fn
ACTIONS.ATTACKPLANT.fn = function(act)
    if act.target ~= nil then
        if act.target.components.perennialcrop ~= nil then
            return act.target.components.perennialcrop:TendTo(act.doer, false)
        elseif act.target.components.perennialcrop2 ~= nil then
            return act.target.components.perennialcrop2:TendTo(act.doer, false)
        end
    end
    return ATTACKPLANT_old(act)
end

------让 寻找作物照顾机制 能兼容多年生作物（两种果蝇、土地爷用到了）
require "behaviours/findfarmplant"
if FindFarmPlant then
    local function IsNearFollowPos(self, plant)
        local followpos = self.getfollowposfn(self.inst)
        local plantpos = plant:GetPosition()
        return distsq(followpos.x, followpos.z, plantpos.x, plantpos.z) < 400
    end

    local Visit_old = FindFarmPlant.Visit
    FindFarmPlant.Visit = function(self, ...)
        if self.status == READY then
            --找可照顾的多年生作物
            self.inst.planttarget = FindEntity(self.inst, 20, function(plant)
                if
                    ( (
                        plant.components.perennialcrop ~= nil and
                        plant.components.perennialcrop:Tendable(self.inst, self.wantsstressed)
                    ) or (
                        plant.components.perennialcrop2 ~= nil and
                        plant.components.perennialcrop2:Tendable(self.inst, self.wantsstressed)
                    ) ) and
                    IsNearFollowPos(self, plant) and
                    (self.validplantfn == nil or self.validplantfn(self.inst, plant))
                then
                    return true
                end
            end, nil, { "INLIMBO", "NOCLICK" }, { "crop_legion", "crop2_legion" })

            if self.inst.planttarget then
                local action = BufferedAction(self.inst, self.inst.planttarget, self.action, nil, nil, nil, 0.1)
                self.inst.components.locomotor:PushAction(action, self.shouldrun)
                self.status = RUNNING
            end
        end
        if
            self.inst.planttarget and (
                self.inst.planttarget.components.perennialcrop ~= nil or
                self.inst.planttarget.components.perennialcrop2 ~= nil
            )
        then
            if self.status == RUNNING then
                local plant = self.inst.planttarget
                local cropcpt = plant.components.perennialcrop or plant.components.perennialcrop2
                if
                    not plant or not plant:IsValid() or not IsNearFollowPos(self, plant) or
                    not (self.validplantfn == nil or self.validplantfn(self.inst, plant))
                then
                    self.inst.planttarget = nil
                    self.status = FAILED
                elseif not cropcpt:Tendable(self.inst, self.wantsstressed) then
                    self.inst.planttarget = nil
                    self.status = SUCCESS
                end
            else
                self.inst.planttarget = nil
                self.status = FAILED
            end
            return
        end
        Visit_old(self, ...)
    end
end

--------------------------------------------------------------------------
--[[ 脱壳之翅相关 ]]
--------------------------------------------------------------------------

AddStategraphState("wilson", State{ name = "boltout",
    tags = { "busy", "doing", "nointerrupt", "canrotate", "boltout" },
    onenter = function(inst, data)
        if data == nil or data.escapepos == nil then
            inst.sg:GoToState("idle", true)
            return
        end

        TOOLS_L.ForceStopHeavyLifting(inst) --虽然目前的触发条件并不可能有背着重物的情况，因为本身就是背包的功能，但是为了兼容性...
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        -- inst.components.inventory:Hide()    --物品栏与科技栏消失
        -- inst:PushEvent("ms_closepopups")    --关掉打开着的箱子、冰箱等
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(false)   --不能打开地图
            inst.components.playercontroller:Enable(false)  --玩家不能操控
            inst.components.playercontroller:RemotePausePrediction()
        end

        inst.AnimState:PlayAnimation("slide_pre")
        inst.AnimState:PushAnimation("slide_loop")
        inst.SoundEmitter:PlaySound("legion/common/slide_boltout")

        local x,y,z = inst.Transform:GetWorldPosition()
        if inst.bolt_skin_l ~= nil then
            SpawnPrefab(inst.bolt_skin_l.fx or "boltwingout_fx").Transform:SetPosition(x, y, z)
            local shuck = SpawnPrefab("boltwingout_shuck")
            if shuck ~= nil then
                if inst.bolt_skin_l.build ~= nil then
                    shuck.AnimState:SetBuild(inst.bolt_skin_l.build)
                end
                shuck.Transform:SetPosition(x, y, z)
            end
        else
            SpawnPrefab("boltwingout_fx").Transform:SetPosition(x, y, z)
            SpawnPrefab("boltwingout_shuck").Transform:SetPosition(x, y, z)
        end

        local angle = inst:GetAngleToPoint(data.escapepos) + 180 + 45 * (1 - 2 * math.random())
        if angle > 360 then
            angle = angle - 360
        end
        inst.Transform:SetRotation(angle)
        inst.Physics:SetMotorVel(20, 0, 0)
        -- inst.components.locomotor:EnableGroundSpeedMultiplier(false) --为了神话书说的腾云

        inst.sg:SetTimeout(0.3)
    end,
    onupdate = function(inst, dt) --每帧刷新加速度，不这样写的话，若玩家在进入该sg前在左右横跳会导致加速度停止
        inst.Physics:SetMotorVel(21, 0, 0)
    end,
    ontimeout = function(inst)
        inst.sg:GoToState("boltout_pst")
    end,
    onexit = function(inst)
        inst.Physics:Stop()
        -- inst.components.locomotor:EnableGroundSpeedMultiplier(true)

        -- inst.components.inventory:Show()
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(true)
            inst.components.playercontroller:Enable(true)
        end
    end
})
AddStategraphState("wilson", State{ name = "boltout_pst",
    -- tags = {"evade","no_stun"},
    onenter = function(inst)
        inst.AnimState:PlayAnimation("slide_pst")
    end,
    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end )
    }
})

AddStategraphEvent("wilson", EventHandler("boltout", function(inst, data)
    if not inst.sg:HasStateTag("busy") and inst.components.health ~= nil and not inst.components.health:IsDead() then
        inst.sg:GoToState("boltout", data)
    end
end))

--------------------------------------------------------------------------
--[[ 子圭·育相关 ]]
--------------------------------------------------------------------------

------放入与充能的动作

local GENETRANS = Action({ mount_valid=false, encumbered_valid=true })
GENETRANS.id = "GENETRANS"
GENETRANS.str = STRINGS.ACTIONS.GENETRANS
GENETRANS.strfn = function(act)
    if act.invobject ~= nil then
        if act.invobject.prefab == "siving_rocks" or act.invobject.sivturnenergy ~= nil then
            return "CHARGE"
        end
    end
    return "GENERIC"
end
GENETRANS.fn = function(act)
    if act.target ~= nil and act.target.components.genetrans ~= nil and act.doer ~= nil then
        local material = act.invobject
        if
            material == nil and
            -- act.doer.components.inventory ~= nil and act.doer.components.inventory:IsHeavyLifting() and
            act.doer.components.inventory ~= nil and --inventory:IsHeavyLifting() 不能判定，因为神话书说里改了
            not (act.doer.components.rider ~= nil and act.doer.components.rider:IsRiding())
        then
            material = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        end

        if material ~= nil then
            if material.prefab == "siving_rocks" or material.sivturnenergy ~= nil then
                return act.target.components.genetrans:Charge(material, act.doer)
            else
                local res, reason = act.target.components.genetrans:UnlockGene(material, act.doer)
                if not res then --说明基因池解锁失败了
                    if reason == "HASKEY" then --说明这是种活性组织
                        return false, reason
                    else
                        return act.target.components.genetrans:SetUp(material, act.doer)
                    end
                else
                    return true
                end
            end
        end
    end
end
AddAction(GENETRANS)

AddComponentAction("SCENE", "genetrans", function(inst, doer, actions, right)
    if right and
        -- (doer.replica.inventory ~= nil and doer.replica.inventory:IsHeavyLifting()) and
        doer.replica.inventory ~= nil and --inventory:IsHeavyLifting() 不能判定，因为神话书说里改了
        not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())
    then
        local item = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        if item ~= nil then
            if TRANS_DATA_LEGION[item.prefab] ~= nil then
                table.insert(actions, ACTIONS.GENETRANS)
            end
        end
    end
end)

-- GENETRANS 组件动作响应已移到 AddComponentAction("USEITEM", "inventoryitem" 中

local function FnSgGeneTrans(inst, action)
    if inst.replica.inventory ~= nil and inst.replica.inventory:IsHeavyLifting() then
        return "domediumaction"
    else
        return "give"
    end
end
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.GENETRANS, FnSgGeneTrans))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GENETRANS, FnSgGeneTrans))

--------------------------------------------------------------------------
--[[ 让地毯类建筑能摆更远 ]]
--------------------------------------------------------------------------

local build_dist_old = ACTIONS.BUILD.extra_arrive_dist
ACTIONS.BUILD.extra_arrive_dist = function(doer, dest, bufferedaction)
    if bufferedaction and bufferedaction.recipe then
        if
            string.len(bufferedaction.recipe) > 7 and
            string.sub(bufferedaction.recipe, 1, 7) == "carpet_"
        then
            return 4
        end
    end
    return build_dist_old and build_dist_old(doer, dest, bufferedaction) or 0
end

--------------------------------------------------------------------------
--[[ 修改采集动作的名称 ]]
--------------------------------------------------------------------------

local pick_strfn_old = ACTIONS.PICK.strfn
ACTIONS.PICK.strfn = function(act)
    if act.target ~= nil and act.target:HasTag("genetrans") then
        return "GENETRANS"
    end
    return pick_strfn_old(act)
end

--------------------------------------------------------------------------
--[[ 给予动作的完善 ]]
--------------------------------------------------------------------------

local give_strfn_old = ACTIONS.GIVE.strfn
ACTIONS.GIVE.strfn = function(act)
    if act.target ~= nil then
        if act.target:HasTag("genetrans") then
            if act.invobject and act.invobject.prefab == "siving_rocks" then
                return "NEEDENERGY"
            end
        end
    end
    return give_strfn_old(act)
end

--------------------------------------------------------------------------
--[[ 栅栏击剑旋转一些对象时，旋转180度而不是45度 ]]
--------------------------------------------------------------------------

local ROTATE_FENCE_fn_old = ACTIONS.ROTATE_FENCE.fn
ACTIONS.ROTATE_FENCE.fn = function(act)
    if
        act.invobject ~= nil and
        act.target ~= nil and act.target:HasTag("flatrotated_l")
    then
        local fencerotator = act.invobject.components.fencerotator
        if fencerotator then
            fencerotator:Rotate(act.target, 180)
            return true
        end
    end
    return ROTATE_FENCE_fn_old(act)
end

--------------------------------------------------------------------------
--[[ 让牛仔尝试骑上坐骑时能忽略其服从度和战斗仇恨的影响 ]]
--------------------------------------------------------------------------

local MOUNT_fn_old = ACTIONS.MOUNT.fn
ACTIONS.MOUNT.fn = function(act)
    if act.doer:HasTag("cowboy_l") then
        if
            act.target.components.domesticatable ~= nil and
            act.target.components.domesticatable:GetObedience() < act.target.components.domesticatable.maxobedience
        then
            act.target.components.domesticatable:DeltaObedience(1) --其实就是加满服从度，这样就可以骑上去了
        end
        if act.target.components.combat ~= nil then --清除仇恨，这样不影响骑行
            act.target.components.combat:DropTarget()
        end
    end
    return MOUNT_fn_old(act)
end

--------------------------------------------------------------------------
--[[ 修改官方升级组件的动作，来兼容 弹性空间制造器、月石角撑 的升级 ]]
--------------------------------------------------------------------------

local UPGRADE_fn_old = ACTIONS.UPGRADE.fn
ACTIONS.UPGRADE.fn = function(act)
    if act.invobject ~= nil and act.target ~= nil and
        act.invobject.components.upgrader ~= nil and
        act.invobject.components.upgrader.upgradetype == UPGRADETYPES.CHEST
    then
        if act.target.legionfn_chestupgrade ~= nil then --棱镜容器
            act.target.legionfn_chestupgrade(act.target, act.invobject, act.doer)
            return true
        elseif act.invobject:HasTag("chestupgrader_l") then --角撑 兼容别的模组容器
            if act.target:HasTag("chestupgradeable_l") then
                return UPGRADE_fn_old(act)
            else --角撑 只能升级特定的容器，没法升级的就算是失败。千万不能升级官方箱子，否则能用来刷启迪碎片
                return false
            end
        end
    end
    return UPGRADE_fn_old(act)
end

--------------------------------------------------------------------------
--[[ 子圭面具相关 ]]
--------------------------------------------------------------------------

------御血神通的动作

local LIFEBEND = Action({ mount_valid=true, priority=1.3 })
LIFEBEND.id = "LIFEBEND"
LIFEBEND.str = STRINGS.ACTIONS.LIFEBEND
LIFEBEND.strfn = function(act)
    local target = act.target
    if target.prefab == "flower_withered" or target.prefab == "mandrake" then --枯萎花、死掉的曼德拉草
        return "GENERIC"
    elseif target:HasAnyTag("playerghost", "ghost") then --玩家鬼魂、幽灵
        return "REVIVE"
    elseif target:HasTag("_health") then --有生命组件的对象
        return "CURE"
    elseif target:HasTag("lifebox_l") then --生命容器
        return "GIVE"
    end
    return "GENERIC"
end
LIFEBEND.fn = function(act)
    if act.doer ~= nil and act.doer.components.inventory ~= nil then
        local item = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if item ~= nil and item.components.lifebender ~= nil then
            return item.components.lifebender:Do(act.doer, act.target)
        end
    end
end
AddAction(LIFEBEND)

--Tip："EQUIPPED"类型只识别手持道具，其他装备栏位置的不识别
-- AddComponentAction("EQUIPPED", "lifebender", function(inst, doer, target, actions, right) end)
-- LIFEBEND 组件动作响应已移到 AddComponentAction("SCENE", "inspectable" 中

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.LIFEBEND, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.LIFEBEND, "give"))

--------------------------------------------------------------------------
--[[ 组装升级的动作 ]]
--------------------------------------------------------------------------

local USE_UPGRADEKIT = Action({ priority = 5, mount_valid = false })
USE_UPGRADEKIT.id = "USE_UPGRADEKIT"
USE_UPGRADEKIT.str = STRINGS.ACTIONS_LEGION.USE_UPGRADEKIT
USE_UPGRADEKIT.fn = function(act)
    if act.doer.components.inventory ~= nil then
        local kit = act.doer.components.inventory:RemoveItem(act.invobject)
        if kit ~= nil and kit.components.upgradekit ~= nil and act.target ~= nil then
            local result = kit.components.upgradekit:Upgrade(act.doer, act.target)
            if result then
                return true
            else
                act.doer.components.inventory:GiveItem(kit)
            end
        end
    end
end
AddAction(USE_UPGRADEKIT)

AddComponentAction("USEITEM", "upgradekit", function(inst, doer, target, actions, right)
    if target.prefab ~= nil --居然要判断这个，无语
        and inst:HasTag(target.prefab.."_upkit")
        and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) --不能骑牛
        and not (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsHeld()) --当前没有被装进容器
        and right
    then
        table.insert(actions, ACTIONS.USE_UPGRADEKIT)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.USE_UPGRADEKIT, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.USE_UPGRADEKIT, "dolongaction"))

--------------------------------------------------------------------------
--[[ 武器技能 ]]
--------------------------------------------------------------------------

local RC_SKILL_L = Action({ priority=11, rmb=true, mount_valid=true, distance=36 }) --原本优先级是1.5
RC_SKILL_L.id = "RC_SKILL_L" --rightclick_skillspell_legion
RC_SKILL_L.str = STRINGS.ACTIONS.RC_SKILL_L
RC_SKILL_L.strfn = function(act)
    if act.doer ~= nil then
        local item = act.doer.replica.inventory and act.doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
        if item ~= nil then
            if item:HasTag("s_l_throw") then
                return "FEATHERTHROW"
            elseif item:HasTag("s_l_pull") then
                return "FEATHERPULL"
            end
        end
    end
    return "GENERIC"
end
RC_SKILL_L.fn = function(act)
    local weapon = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if weapon and weapon.components.skillspelllegion ~= nil then
        local pos = act.target and act.target:GetPosition() or act:GetActionPoint()
        if weapon.components.skillspelllegion:CanCast(act.doer, pos) then
            weapon.components.skillspelllegion:CastSpell(act.doer, pos)
            return true
        end
    end
end
AddAction(RC_SKILL_L)

AddComponentAction("POINT", "skillspelllegion", function(inst, doer, pos, actions, right)
    if right and (doer.HUD == nil or not doer.HUD:IsSpellWheelOpen()) and --不要影响按钮轮盘
        not inst:HasTag("noskill_l") and not TheWorld.Map:IsGroundTargetBlocked(pos)
    then
        table.insert(actions, ACTIONS.RC_SKILL_L)
    end
end)
-- RC_SKILL_L 组件动作响应已移到 AddComponentAction("SCENE", "inspectable" 中

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.RC_SKILL_L, function(inst, action)
    if inst.sg:HasStateTag("busy") or inst:HasTag("busy") then
        return
    end
    local item = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    if item ~= nil then
        if item:HasTag("s_l_throw") then
            return "s_l_throw"
        elseif item:HasTag("s_l_pull") then
            return "s_l_pull"
        end
    end
end))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.RC_SKILL_L, function(inst, action)
    if inst.sg:HasStateTag("busy") or inst:HasTag("busy") then
        return
    end
    local item = inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    if item ~= nil then
        if item:HasTag("s_l_throw") then
            return "s_l_throw"
        elseif item:HasTag("s_l_pull") then
            return "s_l_pull"
        end
    end
end))

------发射羽毛的动作sg
AddStategraphState("wilson", State{ name = "s_l_throw",
    tags = { "doing", "busy", "nointerrupt" },
    onenter = function(inst)
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        inst.components.locomotor:Stop()
        -- if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
        --     inst.AnimState:PlayAnimation("player_atk_pre")
        -- else
        --     inst.AnimState:PlayAnimation("atk_pre")
        -- end
        inst.AnimState:PlayAnimation("throw")

        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            if buffaction.target ~= nil then
                inst:ForceFacePoint(buffaction.target.Transform:GetWorldPosition())
            elseif buffaction.pos ~= nil then
                inst:ForceFacePoint(buffaction:GetActionPoint():Get())
            end
        end

        if (equip ~= nil and equip.projectiledelay or 0) > 0 then
            --V2C: Projectiles don't show in the initial delayed frames so that
            --     when they do appear, they're already in front of the player.
            --     Start the attack early to keep animation in sync.
            inst.sg.statemem.projectiledelay = 7 * FRAMES - equip.projectiledelay
            if inst.sg.statemem.projectiledelay <= 0 then
                inst.sg.statemem.projectiledelay = nil
            end
        end

        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
    end,
    onupdate = function(inst, dt)
        if (inst.sg.statemem.projectiledelay or 0) > 0 then
            inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
            if inst.sg.statemem.projectiledelay <= 0 then
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("nointerrupt")
                inst.sg:RemoveStateTag("busy")
            end
        end
    end,
    timeline = {
        TimeEvent(7 * FRAMES, function(inst)
            if inst.sg.statemem.projectiledelay == nil then
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("nointerrupt")
                inst.sg:RemoveStateTag("busy")
            end
        end),
        TimeEvent(18 * FRAMES, function(inst)
            inst.sg:GoToState("idle", true)
        end),
    },
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                -- if
                --     inst.AnimState:IsCurrentAnimation("atk_pre") or
                --     inst.AnimState:IsCurrentAnimation("player_atk_pre")
                -- then
                --     inst.AnimState:PlayAnimation("throw")
                --     inst.AnimState:SetTime(6 * FRAMES)
                -- else
                    inst.sg:GoToState("idle")
                -- end
            end
        end),
    },
    -- onexit = function(inst) end
})
AddStategraphState("wilson_client", State{ name = "s_l_throw",
    tags = { "doing", "busy", "nointerrupt" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        -- if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
        --     inst.AnimState:PlayAnimation("player_atk_pre")
        --     inst.AnimState:PushAnimation("player_atk_lag", false)
        -- else
        --     inst.AnimState:PlayAnimation("atk_pre")
        --     inst.AnimState:PushAnimation("atk_lag", false)
        -- end
        inst.AnimState:PlayAnimation("throw")

        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()

            if buffaction.target ~= nil then
                inst:ForceFacePoint(buffaction.target.Transform:GetWorldPosition())
            elseif buffaction.pos ~= nil then
                inst:ForceFacePoint(buffaction:GetActionPoint():Get())
            end
        end

        inst.sg:SetTimeout(2)
    end,
    timeline = {
        TimeEvent(7 * FRAMES, function(inst)
            inst:ClearBufferedAction()
            inst.sg:RemoveStateTag("nointerrupt")
            inst.sg:RemoveStateTag("busy")
        end)
    },
    ontimeout = function(inst)
        inst.sg:GoToState("idle")
    end,
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    }
})
------拉回羽毛的动作sg
AddStategraphState("wilson", State{ name = "s_l_pull",
    tags = { "doing", "busy", "nointerrupt" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("catch_pre")
        inst.AnimState:PushAnimation("catch", false)

        if inst.sivfeathers_l ~= nil then
            for _,v in ipairs(inst.sivfeathers_l) do
                if v and v:IsValid() then
                    inst:ForceFacePoint(v.Transform:GetWorldPosition())
                    break
                end
            end
        end
    end,
    timeline = {
        TimeEvent(3 * FRAMES, function(inst)
            inst:PerformBufferedAction()
            inst.sg:RemoveStateTag("nointerrupt")
            inst.sg:RemoveStateTag("busy")
        end),
        -- TimeEvent(6 * FRAMES, function(inst)
        --     inst.sg:RemoveStateTag("busy")
        -- end),
    },
    events = {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    }
})
AddStategraphState("wilson_client", State{ name = "s_l_pull",
    tags = { "doing", "busy", "nointerrupt" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("catch_pre")
        inst.AnimState:PushAnimation("catch", false)
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
        if inst:HasTag("doing") then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,
    timeline = {
        TimeEvent(3 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("nointerrupt")
            inst.sg:RemoveStateTag("busy")
        end),
        -- TimeEvent(6 * FRAMES, function(inst)
        --     inst.sg:RemoveStateTag("busy")
        -- end),
    },
    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end
})

--------------------------------------------------------------------------
--[[ 让浇水组件能作用于多年生作物、雨竹块茎 ]]
--------------------------------------------------------------------------

local function ExtraPourWaterDist(doer, dest, bufferedaction)
    return 1.5
end

local POUR_WATER_LEGION = Action({ rmb=true, extra_arrive_dist=ExtraPourWaterDist })
POUR_WATER_LEGION.id = "POUR_WATER_LEGION"
-- POUR_WATER_LEGION.str = STRINGS.ACTIONS.POUR_WATER
POUR_WATER_LEGION.stroverridefn = function(act)
    return (act.target:HasTag("fire") or act.target:HasTag("smolder"))
        and STRINGS.ACTIONS.POUR_WATER.EXTINGUISH or STRINGS.ACTIONS.POUR_WATER.GENERIC
end
POUR_WATER_LEGION.fn = ACTIONS.POUR_WATER.fn
AddAction(POUR_WATER_LEGION)

AddComponentAction("EQUIPPED", "wateryprotection", function(inst, doer, target, actions, right)
    if right and (target:HasTag("moisable_l") or target:HasTag("ctlmoi_l")) then
        table.insert(actions, ACTIONS.POUR_WATER_LEGION)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.POUR_WATER_LEGION, function(inst, action)
    return action.invobject ~= nil
        and (action.invobject:HasTag("wateringcan") and "pour")
        or "dolongaction"
end))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.POUR_WATER_LEGION, "pour"))

--------------------------------------------------------------------------
--[[ 叉起地毯的动作 ]]
--------------------------------------------------------------------------

newaction = Action({
    priority = 3, --优先级得比铲地皮动作高
    extra_arrive_dist = function(doer, dest, bufferedaction) --地毯可能会在被阻挡位置，所以最好触发半径大一些
        return 3
    end
})
newaction.id = "REMOVE_CARPET_L"
newaction.str = STRINGS.ACTIONS_LEGION.REMOVE_CARPET_L
newaction.fn = function(act)
    local pos = act:GetActionPoint()
	local ent = TheSim:FindEntities(pos.x, pos.y, pos.z, 2, { "carpet_l" }, { "INLIMBO" }, nil)
    if ent[1] ~= nil then
        ent = ent[1] --离得最近的那一个是最直观的
        if ent.legionfn_onremove ~= nil then
            ent.legionfn_onremove(ent, act.doer)
        end
        ent:Remove()
    end
    return true
end
AddAction(newaction)
newaction = nil

AddComponentAction("POINT", "terraformer", function(inst, doer, pos, actions, right, target)
    if right then
        local x, y, z = pos:Get()
        if #TheSim:FindEntities(x, y, z, 2, { "carpet_l" }, { "INLIMBO" }, nil) > 0 then
            table.insert(actions, ACTIONS.REMOVE_CARPET_L)
        end
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.REMOVE_CARPET_L, "terraform"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.REMOVE_CARPET_L, "terraform"))

--------------------------------------------------------------------------
--[[ 扫把切换地毯皮肤的动作 ]]
--------------------------------------------------------------------------

newaction = Action({ priority=8, rmb=true, distance=20, mount_valid=true })
newaction.id = "RESKIN_CARPET_L"
newaction.str = STRINGS.ACTIONS.CASTSPELL.RESKIN
newaction.fn = function(act)
    local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if staff ~= nil and staff.components.spellcaster ~= nil then
        local pos = act:GetActionPoint()
	    local ent = TheSim:FindEntities(pos.x, pos.y, pos.z, 2, { "carpet_l" }, { "INLIMBO" }, nil)
        if ent[1] ~= nil then
            ent = ent[1] --离得最近的那一个是最直观的
            staff = staff.components.spellcaster
            local can_cast, cant_cast_reason = staff:CanCast(act.doer, ent, pos)
            if can_cast then
                staff:CastSpell(ent, pos, act.doer)
            end
        end
    end
    return true
end
AddAction(newaction)
newaction = nil

AddComponentAction("POINT", "z_reskintool", function(inst, doer, pos, actions, right, target)
    if right then
        local x, y, z = pos:Get()
        if #TheSim:FindEntities(x, y, z, 2, { "carpet_l" }, { "INLIMBO" }, nil) > 0 then
            table.insert(actions, ACTIONS.RESKIN_CARPET_L)
        end
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.RESKIN_CARPET_L, "veryquickcastspell"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.RESKIN_CARPET_L, "veryquickcastspell"))

--------------------------------------------------------------------------
--[[ 电气石的动作 ]]
--------------------------------------------------------------------------

newaction = Action({ priority = 5, mount_valid = true })
newaction.id = "RUB_L"
newaction.str = STRINGS.ACTIONS_LEGION.RUB_L
newaction.fn = function(act)
    local battery = nil
    local target = nil
    --先要找到主体和客体
    if act.invobject ~= nil and act.invobject.components.batterylegion ~= nil then
        battery = act.invobject
        target = act.target or act.doer
    elseif act.target ~= nil and act.target.components.batterylegion ~= nil then
        battery = act.target
        target = act.invobject or act.doer
    else
        return false, "NOUSE"
    end
    return battery.components.batterylegion:Do(act.doer, target)
end
AddAction(newaction)
newaction = nil

--玩家对地上的物品进行操作
AddComponentAction("SCENE", "batterylegion", function(inst, doer, actions, right)
    if right then
        table.insert(actions, ACTIONS.RUB_L)
    end
end)
--玩家对物品栏的物品进行操作
AddComponentAction("INVENTORY", "batterylegion", function(inst, doer, actions, right)
    -- if right then --INVENTORY 模式，不能用right
        table.insert(actions, ACTIONS.RUB_L)
    -- end
end)
--用物品对其他对象进行操作
AddComponentAction("USEITEM", "batterylegion", function(inst, doer, target, actions, right)
    if
        right and not target:HasAnyTag("battery_l", "playerghost") and --不能对其他电池使用
        target.components.container_proxy == nil and --不能对世界容器使用
        (target.replica.combat ~= nil or target.replica.container == nil) --不能对无战斗组件的容器使用
    then
        table.insert(actions, ACTIONS.RUB_L)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.RUB_L, Fn_sg_robot_handy))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.RUB_L, Fn_sg_robot_handy))

--------------------------------------------------------------------------
--[[ 涂抹道具的动作 ]]
--------------------------------------------------------------------------

newaction = Action({ priority = 5, mount_valid = true })
newaction.id = "SMEAR_L"
newaction.str = STRINGS.ACTIONS_LEGION.SMEAR_L
newaction.fn = function(act)
    if act.invobject ~= nil and act.invobject.components.ointmentlegion ~= nil and
        act.doer ~= nil
    then
        local target = act.target or act.doer --在物品栏直接使用时，act.target 是空的
        local res, reason = act.invobject.components.ointmentlegion:Check(act.doer, target)
        if res then
            act.invobject.components.ointmentlegion:Smear(act.doer, target)
            return true
        end
        return res, reason
    end
end
AddAction(newaction)
newaction = nil

AddComponentAction("INVENTORY", "ointmentlegion", function(inst, doer, actions, right)
    if not doer:HasTag("burnt") then --INVENTORY 模式，不能用right
        table.insert(actions, ACTIONS.SMEAR_L)
    end
end)
AddComponentAction("USEITEM", "ointmentlegion", function(inst, doer, target, actions, right)
    if right and not target:HasAnyTag("burnt", "playerghost") then
        table.insert(actions, ACTIONS.SMEAR_L)
    end
end)

AddStategraphState("wilson", State{ name = "smear_l",
    tags = { "doing", "busy" },
    onenter = function(inst)
        local dd = inst:GetBufferedAction()
        if dd ~= nil and dd.invobject ~= nil and dd.invobject.dd_l_smear ~= nil then
            dd = dd.invobject.dd_l_smear
            inst.AnimState:OverrideSymbol("prop_poop", dd.build, "prop_poop")
        end
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("fertilize_pre")
        if
            inst:HasTag("fastbuilder") or inst:HasTag("fastrepairer") or inst:HasTag("handyperson") or
            (inst.components.skilltreeupdater ~= nil and
                inst.components.skilltreeupdater:IsActivated("wormwood_quick_selffertilizer"))
        then
            inst.sg.statemem.fast = true
            inst.AnimState:PushAnimation("shortest_fertilize", false)
        else
            inst.AnimState:PushAnimation("fertilize", false)
        end
    end,
    timeline = {
        FrameEvent(27, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/characters/wormwood/fertalize_LP", "rub")
            inst.SoundEmitter:SetParameter("rub", "start", math.random())
        end),
        FrameEvent(45, function(inst)
            if inst.sg.statemem.fast then
                inst:PerformBufferedAction()
            end
        end),
        FrameEvent(50, function(inst)
            if inst.sg.statemem.fast then
                inst.SoundEmitter:KillSound("rub")
            end
        end),
        FrameEvent(52, function(inst)
            if inst.sg.statemem.fast then
                inst.sg:RemoveStateTag("busy")
            end
        end),
        FrameEvent(82, function(inst)
            if not inst.sg.statemem.fast then
                inst.SoundEmitter:KillSound("rub")
            end
        end),
        FrameEvent(88, function(inst)
            if not inst.sg.statemem.fast then
                inst:PerformBufferedAction()
            end
        end),
        FrameEvent(90, function(inst)
            if not inst.sg.statemem.fast then
                inst.sg:RemoveStateTag("busy")
            end
        end)
    },
    events = {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    },
    onexit = function(inst)
        inst.AnimState:OverrideSymbol("prop_poop", "player_wormwood_fertilizer", "prop_poop")
        inst.SoundEmitter:KillSound("rub")
    end
})
AddStategraphState("wilson_client", State{ name = "smear_l",
    tags = { "doing", "busy" },
    server_states = { "smear_l" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("fertilize_pre")
        inst.AnimState:PushAnimation("fertilize_lag", false)
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.AnimState:PlayAnimation("item_hat")
            inst.sg:GoToState("idle", true)
        end
    end,
    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.AnimState:PlayAnimation("item_hat")
        inst.sg:GoToState("idle", true)
    end
})

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SMEAR_L, function(inst, action)
    if action.target == nil or action.target == inst then --在物品栏直接使用时，act.target 是空的
        return "smear_l"
    else
        return Fn_sg_handy(inst, action)
    end
end))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SMEAR_L, function(inst, action)
    if action.target == nil or action.target == inst then
        return "smear_l"
    else
        return Fn_sg_handy(inst, action)
    end
end))

--------------------------------------------------------------------------
--[[ 云容器打开器的动作 ]]
--------------------------------------------------------------------------

--ACTIONS.RUMMAGE 的优先级太低了，为了能在物品栏里被打开，只能新写一个动作

newaction = Action({ priority = 10, mount_valid = true })
newaction.id = "BOXOPENER_L"
newaction.str = STRINGS.ACTIONS.RUMMAGE
newaction.strfn = ACTIONS.RUMMAGE.strfn
newaction.fn = ACTIONS.RUMMAGE.fn
AddAction(newaction)
newaction = nil

AddComponentAction("INVENTORY", "container_proxy", function(inst, doer, actions, right)
    if --INVENTORY 模式，不能用right
        inst:HasTag("boxopener_l") and
        inst.components.container_proxy:CanBeOpened() and
        doer.replica.inventory ~= nil
    then
        table.insert(actions, ACTIONS.BOXOPENER_L)
    end
end)
AddComponentAction("SCENE", "container_proxy", function(inst, doer, actions, right)
    if
        right and inst:HasTag("boxopener_l") and
        inst.components.container_proxy:CanBeOpened() and
        doer.replica.inventory ~= nil and
        not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())
    then
        table.insert(actions, ACTIONS.BOXOPENER_L)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BOXOPENER_L, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BOXOPENER_L, "doshortaction"))

--------------------------------------------------------------------------
--[[ 织影(打蜡)动作 ]]
--------------------------------------------------------------------------

local function ActFn_wax(act, right)
    if
        act.doer ~= nil and act.target ~= nil and
        act.invobject ~= nil and act.invobject.components.waxlegion ~= nil
    then
        return act.invobject.components.waxlegion:Wax(act.doer, act.target, right)
    end
end

newaction = Action({ priority = 3, encumbered_valid = true, mindistance = 1.5 })
newaction.id = "WAX_LEGION"
newaction.str = STRINGS.ACTIONS_LEGION.WAX_L
newaction.fn = function(act) --复制出一个打蜡后的可种植物
    return ActFn_wax(act)
end
AddAction(newaction)
newaction = nil

newaction = Action({ priority = 3, encumbered_valid = true, mindistance = 1.5 })
newaction.id = "WAX_RIGHT_LEGION"
newaction.str = STRINGS.ACTIONS_LEGION.WAX_RIGHT_L
newaction.fn = function(act) --复制出打蜡后的实体，并替换原本的，原本的会被自动挖起来
    return ActFn_wax(act, true)
end
AddAction(newaction)
newaction = nil

local function CA_USEITEM_waxlegion(inst, doer, target, actions, right) --USEITEM 和 EQUIPPED 参数一样，所以能统一写
    if right then
        if target:HasTag("waxable_l2") or target:HasTag("needswaxspray") then
            --不能给物品栏里的东西打蜡
            if target.replica.inventoryitem == nil or not target.replica.inventoryitem:IsHeld() then
                table.insert(actions, ACTIONS.WAX_RIGHT_LEGION)
            end
        end
    else
        if target:HasTag("waxable_l") or target:HasTag("waxedplant") then
            --不能给物品栏里的东西打蜡
            if target.replica.inventoryitem == nil or not target.replica.inventoryitem:IsHeld() then
                table.insert(actions, ACTIONS.WAX_LEGION)
            end
        end
    end
end
AddComponentAction("USEITEM", "waxlegion", CA_USEITEM_waxlegion)
AddComponentAction("EQUIPPED", "waxlegion", CA_USEITEM_waxlegion)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WAX_LEGION, "spray_wax"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WAX_LEGION, "spray_wax"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WAX_RIGHT_LEGION, "spray_wax"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WAX_RIGHT_LEGION, "spray_wax"))

--------------------------------------------------------------------------
--[[ 影织异种的簇栽动作 ]]
--------------------------------------------------------------------------

local WAXCLUSTER_LEGION = Action({ priority = 2 })
WAXCLUSTER_LEGION.id = "WAXCLUSTER_LEGION"
WAXCLUSTER_LEGION.str = STRINGS.ACTIONS_LEGION.WAXCLUSTER_L
WAXCLUSTER_LEGION.fn = function(act)
    if
        act.doer ~= nil and act.target ~= nil and
        act.invobject ~= nil and act.invobject.components.waxclusterlegion ~= nil
    then
        return act.invobject.components.waxclusterlegion:Cluster(act.doer, act.target)
    end
end
AddAction(WAXCLUSTER_LEGION)

AddComponentAction("USEITEM", "waxclusterlegion", function(inst, doer, target, actions, right)
    if right and target:HasTag("waxclusterable_l") then
        table.insert(actions, ACTIONS.WAXCLUSTER_LEGION)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WAXCLUSTER_LEGION, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WAXCLUSTER_LEGION, "doshortaction"))

--------------------------------------------------------------------------
--[[ 按键响应 ]]
--------------------------------------------------------------------------

if not TheNet:IsDedicated() then
    local pressed_shieldkey
    local function IsScreen_HUD()
        local active_screen = TheFrontEnd:GetActiveScreen()
        if active_screen ~= nil and active_screen.name == "HUD" then
            return true
        end
    end
    local opt = _G.CONFIGS_LEGION
    TheInput:AddKeyHandler(function(key, down)
        if key ~= opt.SHIELDKEY or key == 1 then return end
        if down then --按下时
            --监听按键按下时就触发，这样触发更快一点
            if pressed_shieldkey then --这个监听只要按着就会不断触发，不想这样设定
                return
            end
            pressed_shieldkey = true
            if IsScreen_HUD() and --在主hud，没在打字或者有弹窗在最上面之类的
                ThePlayer and not ThePlayer:HasTag("playerghost") and not ThePlayer:HasTag("busy") and
                -- ThePlayer.sg and not (ThePlayer.sg:HasStateTag("atk_shield") or ThePlayer.sg:HasStateTag("busy")) and
                ThePlayer.HUD and ThePlayer.HUD.writeablescreen == nil and --是指小木牌写字这种？
                ThePlayer.components.playercontroller and ThePlayer.components.playercontroller:IsEnabled()
                and ThePlayer.replica.inventory
            then
                local item = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if item ~= nil and item:HasTag("canshieldatk") then
                    local x, y, z = ThePlayer.Transform:GetWorldPosition()
                    local facing_angle = ThePlayer.Transform:GetRotation() * DEGREES
                    x, y, z = TOOLS_L.GetCalculatedPos(x, y, z, 1, facing_angle)
                    local act = BufferedAction(ThePlayer, nil, ACTIONS.ATTACK_SHIELD_L, item, Vector3(x, y, z))
                    local controller = ThePlayer.components.playercontroller
                    --以下逻辑原理参考 components\playercontroller.lua 的 OnRightClick()
                    if not controller.ismastersim then --这里本来就是客户端才会触发，ismastersim 只是为了判断是否为单纯的客户端
                        if controller.locomotor == nil then
                            if act.action.pre_action_cb ~= nil then
                                act.action.pre_action_cb(act)
                            end
                            SendRPCToServer(RPC.RightClick, act.action.code, x, z, nil,
                                act.rotation, true, nil, act.action.canforce, act.action.mod_name)
                        elseif controller:CanLocomote() then
                            act.preview_cb = function()
                                SendRPCToServer(RPC.RightClick, act.action.code, x, z, nil,
                                    act.rotation, true, nil, act.action.canforce, act.action.mod_name)
                            end
                        end
                    end
                    controller:DoAction(act)
                end
            end
        else --松开时
            pressed_shieldkey = nil
        end
    end)
end

--------------------------------------------------------------------------
--[[ 让沃比能挖出棱镜植物的产物 ]]
--------------------------------------------------------------------------

pas1.IsFoodSourcePickable = _G.IsFoodSourcePickable
_G.IsFoodSourcePickable = function(plant, ...)
    if plant and (
            plant:HasAnyTag("crop2_legion", "bush_l_f") or
            plant.prefab == "monstrain"
        )
    then
        return true
    end
    return pas1.IsFoodSourcePickable(plant, ...)
end

pas1.action_fn_WOBY_PICK = ACTIONS.WOBY_PICK.fn
ACTIONS.WOBY_PICK.fn = function(act)
    local plant = act.target
    if plant == nil then
        return pas1.action_fn_WOBY_PICK(act)
    elseif not plant:IsValid() then
        return true
    end
    local food
    local foodnum = 1
    local islegion
    if plant:HasTag("bush_l_f") then --棱镜花丛
        islegion = true
        if plant.components.pickable ~= nil then
            local rand = math.random()
            if plant.prefab == "rosebush" then
                if rand < 0.5 then
                    food = "twigs"
                elseif rand < 0.525 then
                    food = "cutted_rosebush"
                end
            elseif plant.prefab == "lilybush" then
                if rand < 0.5 then
                    food = "petals"
                    foodnum = 2
                elseif rand < 0.525 then
                    food = "cutted_lilybush"
                end
            elseif plant.prefab == "orchidbush" then
                if rand < 0.5 then
                    food = "cutgrass"
                elseif rand < 0.525 then
                    food = "cutted_orchidbush"
                end
            elseif plant.prefab == "nightrosebush" then
                if rand < 0.4 then
                    food = "nightmarefuel"
                elseif rand < 0.425 then
                    food = "cutted_nightrosebush"
                end
            end
            if food == nil then
                food = plant.components.pickable.product
            end
        end
    elseif plant:HasTag("crop2_legion") then --异种
        islegion = true
        local crop = plant.components.perennialcrop2
        if crop ~= nil then
            food = crop.cropprefab
            if crop.cluster > 0 then
                local rand = math.ceil(crop.cluster/20)
                foodnum = math.ceil(crop.cluster/10)
                if foodnum > rand then
                    foodnum = math.random(rand, foodnum)
                else
                    foodnum = 1
                end
            end
        end
    elseif plant.prefab == "monstrain" then --雨竹
        islegion = true
        food = math.random() < 0.2 and "squamousfruit" or "monstrain_leaf"
    end
    if islegion then
        local item = SpawnPrefab(food or "spoiledfood")
        if item ~= nil then
            if item.components.stackable ~= nil then
                if foodnum > 1 then
                    item.components.stackable:SetStackSize(foodnum)
                end
                item:PushEvent("l_autostack")
            end
            item.Transform:SetPosition(plant.Transform:GetWorldPosition())
            LaunchAt(item, plant, act.doer, nil, nil, plant:GetPhysicsRadius(0) + .25)
        end
        return true
    end
    return pas1.action_fn_WOBY_PICK(act)
end

--------------------------------------------------------------------------
--[[ 灵魂契约相关 ]]
--------------------------------------------------------------------------

------灵魂契约的按钮轮盘打开动作的名字

_G.STRINGS.ACTIONS.USESPELLBOOK.CONTROL_L = STRINGS.ACTIONS_LEGION.SOULBOOK_CONTROL

pas1.action_strfn_USESPELLBOOK = ACTIONS.USESPELLBOOK.strfn
ACTIONS.USESPELLBOOK.strfn = function(act)
    if act.target and act.target:HasTag("soulcontracts") then
        return "CONTROL_L"
    end
    return pas1.action_strfn_USESPELLBOOK(act)
end

------灵魂契约的按钮轮盘关闭动作的名字

_G.STRINGS.ACTIONS.CLOSESPELLBOOK.STOPCONTROL_L = STRINGS.ACTIONS_LEGION.SOULBOOK_STOPCONTROL

pas1.action_strfn_CLOSESPELLBOOK = ACTIONS.CLOSESPELLBOOK.strfn
ACTIONS.CLOSESPELLBOOK.strfn = function(act)
    if act.target and act.target:HasTag("soulcontracts") then
        return "STOPCONTROL_L"
    end
    return pas1.action_strfn_CLOSESPELLBOOK(act)
end

------灵魂契约的专属sg。其实别的动作也可以复用

AddStategraphState("wilson", State{ name = "channel_l",
    tags = { "doing", "nodangle" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make1")
        else
            inst.AnimState:PlayAnimation("channel_pre")
            inst.AnimState:PushAnimation("channel_loop", true)
        end
        inst.sg:SetTimeout(3)
    end,
    ontimeout = function(inst)
        inst:PerformBufferedAction()
        if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
            inst.AnimState:PlayAnimation("build_pst")
        else
            inst.AnimState:PlayAnimation("channel_pst")
        end
        inst.SoundEmitter:KillSound("make1")
    end,
    events = {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then --循环动画不会触发这里，只有不带PushAnimation的单次播放动画能触发
                inst.sg:GoToState("idle")
            end
        end)
    },
    onexit = function(inst)
        inst.SoundEmitter:KillSound("make1")
    end
})
AddStategraphState("wilson_client", State{ name = "channel_l",
    tags = { "doing" },
    server_states = { "channel_l" }, --貌似是对应的服务器上的所有相关sg
    onenter = function(inst)
        inst.components.locomotor:Stop()
        if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make1_preview")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        else
            inst.AnimState:PlayAnimation("channel_pre")
            inst.AnimState:PushAnimation("channel_loop", true)
        end
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
                inst.AnimState:PlayAnimation("build_pst")
            else
                inst.AnimState:PlayAnimation("channel_pst")
            end
            inst.sg:GoToState("idle", true)
        end
    end,
    ontimeout = function(inst)
        inst:ClearBufferedAction()
        if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
            inst.AnimState:PlayAnimation("build_pst")
        else
            inst.AnimState:PlayAnimation("channel_pst")
        end
        inst.sg:GoToState("idle", true)
    end,
    onexit = function(inst)
        inst.SoundEmitter:KillSound("make1_preview")
    end
})

------签订/解除契约 动作

pas1.ActionDist_soulbook = function(doer, dest, bufferedaction)
    if doer and doer.legion_soul_actdist ~= nil then
        return doer.legion_soul_actdist
    end
    return 4
end
pas1.ActionDist2_soulbook = function(doer, dest, bufferedaction) --契约可能会飞到被阻挡位置去，所以最好触发半径大一些
    return 4
end

newaction = Action({ priority = 1, mount_valid = true, extra_arrive_dist = pas1.ActionDist2_soulbook })
newaction.id = "SOULBOOK_SIGN"
newaction.str = STRINGS.ACTIONS_LEGION.SOULBOOK_SIGN
newaction.fn = function(act)
    if act.target ~= nil and act.doer ~= nil and act.doer.components.soulbookowner ~= nil then
        act.doer.components.soulbookowner:TrySign(act.target)
        return true
    end
end
AddAction(newaction)
newaction = nil
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SOULBOOK_SIGN, "channel_l"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SOULBOOK_SIGN, "channel_l"))

------提取灵魂 动作

newaction = Action({ priority = 1, mount_valid = true, extra_arrive_dist = pas1.ActionDist_soulbook })
newaction.id = "SOULBOOK_EXTRACT_SOULS"
newaction.str = STRINGS.ACTIONS_LEGION.SOULBOOK_EXTRACT_SOULS
newaction.fn = function(act)
    if act.target ~= nil and act.doer ~= nil and act.doer.components.soulbookowner ~= nil then
        act.doer.legion_soul_actdist = nil --用完数据就清理掉
        act.doer.components.soulbookowner:Souls2Player(act.target)
        return true
    end
end
AddAction(newaction)
newaction = nil
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SOULBOOK_EXTRACT_SOULS, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SOULBOOK_EXTRACT_SOULS, "give"))

------存储灵魂 动作

newaction = Action({ priority = 1, mount_valid = true, extra_arrive_dist = pas1.ActionDist_soulbook })
newaction.id = "SOULBOOK_STORE_SOULS"
newaction.str = STRINGS.ACTIONS_LEGION.SOULBOOK_STORE_SOULS
newaction.fn = function(act)
    if act.target ~= nil and act.doer ~= nil and act.doer.components.soulbookowner ~= nil then
        act.doer.legion_soul_actdist = nil --用完数据就清理掉
        act.doer.components.soulbookowner:Souls2Book(act.target)
        return true
    end
end
AddAction(newaction)
newaction = nil
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SOULBOOK_STORE_SOULS, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SOULBOOK_STORE_SOULS, "give"))

------分享灵魂 动作

newaction = Action({ priority = 1, mount_valid = true, extra_arrive_dist = pas1.ActionDist2_soulbook })
newaction.id = "SOULBOOK_SHARE_SOULS"
newaction.str = STRINGS.ACTIONS_LEGION.SOULBOOK_SHARE_SOULS
newaction.fn = function(act)
    if act.target ~= nil and act.doer ~= nil and act.doer.components.soulbookowner ~= nil then
        act.doer.components.soulbookowner:ShareSouls(act.target)
        return true
    end
end
AddAction(newaction)
newaction = nil
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SOULBOOK_SHARE_SOULS, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SOULBOOK_SHARE_SOULS, "dolongaction"))

------分享等级 动作

newaction = Action({ priority = 1, mount_valid = true, extra_arrive_dist = pas1.ActionDist2_soulbook })
newaction.id = "SOULBOOK_SHARE_LEVEL"
newaction.str = STRINGS.ACTIONS_LEGION.SOULBOOK_SHARE_LEVEL
newaction.fn = function(act)
    if act.target ~= nil and act.doer ~= nil and act.doer.components.soulbookowner ~= nil then
        act.doer.components.soulbookowner:ShareLevel(act.target)
        return true
    end
end
AddAction(newaction)
newaction = nil
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SOULBOOK_SHARE_LEVEL, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SOULBOOK_SHARE_LEVEL, "dolongaction"))

--------------------------------------------------------------------------
--[[ 浸泡的动作 ]]
--------------------------------------------------------------------------

fns.ProhibitAnything = function(inst)
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(false) --不能打开地图
        inst.components.playercontroller:Enable(false) --不能移动、做操作
    end
    inst.components.inventory:Hide() --物品栏隐藏
    inst:PushEvent("ms_closepopups") --关闭打开的容器
    inst:ShowActions(false) --不能做动作
end
fns.CanDoAnything = function(inst)
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(true)
        inst.components.playercontroller:Enable(true)
    end
    inst.components.inventory:Show()
    inst:ShowActions(true)
end

AddStategraphState("wilson", State{ name = "soak_l_pre",
    tags = { "doing", "busy", "canrotate", "noattack" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("jump_pre", false)
    end,
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.bufferedaction ~= nil then
                    inst:PerformBufferedAction()
                else
                    inst.sg:GoToState("idle")
                end
            end
        end)
    }
})
AddStategraphState("wilson_client", State{ name = "soak_l_pre",
    tags = { "doing", "busy", "canrotate", "noattack" },
    server_states = { "soak_l_pre","soak_l_jumpin", "soak_l" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        local buffaction = inst:GetBufferedAction()
        local chair = buffaction ~= nil and buffaction.target or nil
        if chair ~= nil and chair:IsValid() then
            inst.Transform:SetRotation(chair.Transform:GetRotation())
        end
        inst.AnimState:PlayAnimation("jump_pre")
        inst.AnimState:PushAnimation("jump_lag", false)
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("soak_l") --可能是服务器的 soak_l_jumpin 有 nopredict 标签，所以会导致很快离开 soak_l
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,
    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end
})
AddStategraphState("wilson_client", State{ name = "soak_l",
    tags = { "canrotate", "nomorph", "nointerrupt", "overridelocomote" },
    server_states = { "soak_l_pre","soak_l_jumpin", "soak_l" },
    onenter = function(inst)
        inst.entity:SetIsPredictingMovement(false)
    end,
    onupdate = function(inst)
        local v = inst.components.soakerlegion._animtype:value()
        if v <= 0 then --可能是刚开始还没跳入时，也可能是已经被打断了
            if inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        elseif v == 2 then --在跳出来了(多半是被打断了)
            inst.sg:GoToState("soak_l_jumpout")
        end
    end,
    events = {
        EventHandler("locomote", function(inst)
            if inst.components.locomotor:WantsToMoveForward() and inst.components.soakerlegion._animtype:value() >= 3 then
                inst.sg:GoToState("soak_l_stop")
            end
            return true
        end)
    },
    onexit = function(inst)
        inst.entity:SetIsPredictingMovement(true)
    end
})
AddStategraphState("wilson_client", State{ name = "soak_l_stop",
    tags = { "busy", "canrotate", "noattack", "overridelocomote" },
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.playercontroller:RemotePredictOverrideLocomote() --通知服务器，我要移动了，准备结束浸泡
        local buffaction = inst:GetBufferedAction()
        if buffaction == nil or buffaction.action == ACTIONS.WALKTO then
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()
        end
        inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
        local v = inst.components.soakerlegion._animtype:value()
        if v == 2 then --在跳出来了
            inst.sg:GoToState("soak_l_jumpout")
        elseif v >= 3 then --服务器没有反应，继续呼叫！
            inst.components.playercontroller:RemotePredictOverrideLocomote()
        else
            inst.sg:GoToState("idle")
        end
    end,
    ontimeout = function(inst)
        inst.components.locomotor:Clear()
    end
})
AddStategraphState("wilson_client", State{ name = "soak_l_jumpout",
    tags = { "busy", "canrotate", "noattack" },
    server_states = { "soak_l_jumpout" },
    onenter = function(inst)
        inst.entity:SetIsPredictingMovement(false)
        inst.components.locomotor:StopMoving()
    end,
    onupdate = function(inst)
        if inst.components.soakerlegion._animtype:value() <= 0 then
            inst.sg:GoToState("idle")
        end
    end,
    onexit = function(inst)
        inst.entity:SetIsPredictingMovement(true)
    end
})
AddStategraphState("wilson", State{ name = "soak_l_jumpin",
    tags = { "doing", "busy", "canrotate", "nopredict", "nomorph", "noattack", "nointerrupt" },
    onenter = function(inst)
        local pos = inst.components.soakerlegion.pos
        inst:ForceFacePoint(pos:Get())
        inst.components.locomotor:Stop()
        fns.TriggerPhysics(inst, false)
        fns.ProhibitAnything(inst)
        inst.components.health:SetInvincible(true)
        inst.AnimState:PlayAnimation("jump")
        local dist = inst:GetDistanceSqToPoint(pos:Get())
        inst.sg.statemem.soak_distsq = dist
        inst.sg.statemem.soak_pos = pos
        dist = math.sqrt(dist) --算出跳跃距离
        -- dist = dist*30*1.5 / inst.AnimState:GetCurrentAnimationNumFrames() --距离除以动画总时间，就是直线速度
        dist = dist*30*1.1 / 21
        inst.Physics:SetMotorVel(dist, 0, 0)
        inst.sg.statemem.speed = dist
    end,
    onupdate = function(inst)
        if inst.sg.statemem.soak_pos ~= nil then
            local newdist = inst:GetDistanceSqToPoint(inst.sg.statemem.soak_pos:Get())
            if newdist <= 0.09 or newdist > inst.sg.statemem.soak_distsq then --相对于上一个距离是变大的，说明跳过了，该停止了
                inst.sg.statemem.speed = nil
                inst.sg.statemem.soak_pos = nil
                inst.sg.statemem.soak_distsq = nil
                inst.Physics:Stop()
            else
                inst.sg.statemem.soak_distsq = newdist
                if inst.sg.statemem.speed ~= nil then
                    inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0) --保持速度
                end
            end
        end
    end,
    timeline = {
        TimeEvent(1 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("wanda1/wanda/jump_whoosh")
        end),
        TimeEvent(18 * FRAMES, function(inst)
            inst.DynamicShadow:Enable(false)
        end),
        TimeEvent(20 * FRAMES, function(inst) --这个时候头部位置刚好契合泡澡中的动画头部位置
            inst.components.soakerlegion:SetSplash()
            if inst.components.soakerlegion.toy == nil then
                local target = inst.components.soakerlegion.target
                if target ~= nil and target:IsValid() then
                    inst.sg.statemem.staysoak_l = true
                    inst.sg:GoToState("soak_l")
                else
                    inst.sg:GoToState("idle")
                end
            end
        end),
        TimeEvent(23 * FRAMES, function(inst) --有漂浮装置的话，才会运行到这时候
            local target = inst.components.soakerlegion.target
            if target ~= nil and target:IsValid() then
                inst.sg.statemem.staysoak_l = true
                inst.sg:GoToState("soak_l")
            else
                inst.sg:GoToState("idle")
            end
        end)
    },
    onexit = function(inst)
        inst.Physics:Stop()
        inst.components.health:SetInvincible(false)
        inst.sg.statemem.speed = nil
        inst.sg.statemem.soak_pos = nil
        inst.sg.statemem.soak_distsq = nil
        if not inst.sg.statemem.staysoak_l then --说明是被中断了
            fns.TriggerPhysics(inst, true)
            fns.CanDoAnything(inst)
            inst.DynamicShadow:Enable(true)
            inst.components.soakerlegion:ResetSoaking()
        else
            inst.sg.statemem.staysoak_l = nil
        end
    end
})
AddStategraphState("wilson", State{ name = "soak_l",
    tags = { "busy", "canrotate", "nomorph", "noattack", "nointerrupt", "overridelocomote" },
    onenter = function(inst)
        inst.components.locomotor:StopMoving()
        fns.TriggerPhysics(inst, false)
        fns.ProhibitAnything(inst)
        inst.DynamicShadow:Enable(false)
        inst.components.soakerlegion:StartSoaking()
    end,
    timeline = {
        TimeEvent(6*FRAMES, function(inst) --此时玩家可以选择停止泡澡了
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("noattack") --可被索敌了
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
        end)
    },
    events = {
        EventHandler("locomote", function(inst, data) --想移动了，说明玩家想停止浸泡
            if data ~= nil and data.remoteoverridelocomote or inst.components.locomotor:WantsToMoveForward() then
                inst.sg.statemem.staysoak_l = true
                inst.sg:GoToState("soak_l_jumpout")
            end
            return true
        end),
        EventHandler("attacked", function(inst) --受到攻击时，马上停止浸泡
            if not inst.components.health:IsDead() and not inst:HasTag("playerghost") then
                inst.sg.statemem.staysoak_l = true
                inst.sg:GoToState("soak_l_jumpout")
            end
            return true
        end)
    },
    onexit = function(inst)
        inst.components.soakerlegion:StopSoaking()
        if not inst.sg.statemem.staysoak_l then --说明是被中断了
            fns.TriggerPhysics(inst, true)
            fns.CanDoAnything(inst)
            inst.DynamicShadow:Enable(true)
            inst.components.soakerlegion:ResetSoaking()
        else
            inst.sg.statemem.staysoak_l = nil
        end
    end
})
AddStategraphState("wilson", State{ name = "soak_l_jumpout",
    tags = { "doing", "busy", "canrotate", "nopredict", "nomorph", "noattack", "nointerrupt" },
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Stop()
        fns.TriggerPhysics(inst, false)
        fns.ProhibitAnything(inst)
        inst.components.health:SetInvincible(true)
        inst.AnimState:PlayAnimation("jumpout")

        local rad = inst.components.soakerlegion.targetrad-- + inst:GetPhysicsRadius(0) --池塘半径+玩家半径
        local radsq = rad*rad
        local radstep = rad*2/10 --最远可能要跨过整个池塘直径
        local rotation = inst.Transform:GetRotation() --玩家当前朝向角度。单位度。比如45
        rotation = rotation * DEGREES
        local dist, x1, z1, step
        local x, y, z = inst.Transform:GetWorldPosition()
        local targetpos = inst.components.soakerlegion.targetpos
        for i = 1, 10, 1 do --逐步找到最合适的点位
            step = radstep * i --跳跃距离
            x1 = x + step*math.cos(rotation)
            z1 = z - step*math.sin(rotation)
            dist = distsq(targetpos.x, targetpos.z, x1, z1) --每一点位与池塘中心的距离
            if dist >= radsq then --这个点位刚好离开池塘
                break
            end
        end
        inst.sg.statemem.soak_distsq = step * step
        inst.sg.statemem.soak_pos = Vector3(x1, y, z1)
        step = step*30*1.1 / 19 --算出速度
        inst.Physics:SetMotorVel(step, 0, 0)
        inst.sg.statemem.speed = step
        inst.sg.statemem.soak_safepos = inst.components.soakerlegion.startpos

        inst.components.soakerlegion:SetSplash(true)
    end,
    onupdate = function(inst)
        if inst.sg.statemem.soak_pos ~= nil then
            local newdist = inst:GetDistanceSqToPoint(inst.sg.statemem.soak_pos:Get())
            if newdist <= 0.09 or newdist > inst.sg.statemem.soak_distsq then --相对于上一个距离是变大的，说明跳过了，该停止了
                inst.sg.statemem.speed = nil
                inst.sg.statemem.soak_pos = nil
                inst.sg.statemem.soak_distsq = nil
                inst.Physics:Stop()
            else
                inst.sg.statemem.soak_distsq = newdist
                if inst.sg.statemem.speed ~= nil then
                    inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0) --保持速度
                end
            end
        end
    end,
    timeline = {
        TimeEvent(1 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("wanda1/wanda/jump_whoosh")
            inst.DynamicShadow:Enable(true)
        end),
        TimeEvent(15.2*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end),
        TimeEvent(18*FRAMES, function(inst)
            inst.sg.statemem.staysoak_l = true
            inst.sg.statemem.speed = nil
            inst.sg.statemem.soak_pos = nil
            inst.sg.statemem.soak_distsq = nil
            inst.Physics:Stop()
            if not inst:IsOnPassablePoint() then --当前不在陆地或船上，不安全，就回到安全落点去
                inst.Physics:Teleport(inst.sg.statemem.soak_safepos:Get())
            end
            inst.sg.statemem.soak_safepos = nil
            fns.TriggerPhysics(inst, true)
            fns.CanDoAnything(inst)
            inst.components.soakerlegion:ResetSoaking()
            inst.components.health:SetInvincible(false)
        end)
    },
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end)
    },
    onexit = function(inst)
        if not inst.sg.statemem.staysoak_l then
            inst.sg.statemem.speed = nil
            inst.sg.statemem.soak_pos = nil
            inst.sg.statemem.soak_distsq = nil
            inst.sg.statemem.soak_safepos = nil
            inst.Physics:Stop()
            fns.TriggerPhysics(inst, true)
            fns.CanDoAnything(inst)
            inst.components.soakerlegion:ResetSoaking()
            inst.components.health:SetInvincible(false)
        else
            inst.sg.statemem.staysoak_l = nil
        end
        inst.DynamicShadow:Enable(true)
    end
})

newaction = Action({ priority = 1 }) --distance = 2
newaction.id = "SOAK_LEGION"
newaction.str = STRINGS.ACTIONS_LEGION.SOAK_L
newaction.fn = function(act)
    if act.target ~= nil and act.doer ~= nil and act.doer.components.soakerlegion ~= nil then
        act.doer.components.soakerlegion:JumpIn(act.target)
    end
    return true
end
AddAction(newaction)
newaction = nil

AddComponentAction("SCENE", "soakablelegion", function(inst, doer, actions, right)
    if right and not inst:HasTag("nosoak_l") then
        table.insert(actions, ACTIONS.SOAK_LEGION)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SOAK_LEGION, "soak_l_pre"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SOAK_LEGION, "soak_l_pre"))

--------------------------------------------------------------------------
--[[ 月炆宝炊相关 ]]
--------------------------------------------------------------------------

------修改便携组件的 收回 动作，以兼容月炆宝炊

pas1.action_fn_DISMANTLE = ACTIONS.DISMANTLE.fn
ACTIONS.DISMANTLE.fn = function(act)
    local success, reason = pas1.action_fn_DISMANTLE(act)
    if reason == "NOTEMPTY" and act.target ~= nil and act.target:HasTag("moontreasure_l") then
        act.target.components.portablestructure:Dismantle(act.doer)
        return true
    end
    return success, reason
end

------烹饪与调味 动作

pas1.ActionFn_simmer = function(act, fnname)
    local cpt = act.target.components.moonsimmered
    if act.doer ~= nil and act.target ~= nil and cpt ~= nil and
        act.target.components.container ~= nil and act.target.components.container:IsOpenedBy(act.doer)
    then
        cpt[fnname](cpt, act.doer)
        return true
    end
end

newaction = Action({ priority = 1, mount_valid = true })
newaction.id = "SIMMER_L_COOK"
newaction.str = STRINGS.ACTIONS.COOK
newaction.fn = function(act)
    return pas1.ActionFn_simmer(act, "BtnCook")
end
AddAction(newaction)
newaction = nil

------烤制 动作

newaction = Action({ priority = 1, mount_valid = true })
newaction.id = "SIMMER_L_ROAST"
newaction.str = STRINGS.ACTIONS_LEGION.ROAST
newaction.fn = function(act)
    return pas1.ActionFn_simmer(act, "BtnRoast")
end
AddAction(newaction)
newaction = nil

------清空物品 动作

newaction = Action({ priority = 1, mount_valid = true })
newaction.id = "SIMMER_L_CLEAR"
newaction.str = STRINGS.ACTIONS_LEGION.CLEARALL
newaction.fn = function(act)
    return pas1.ActionFn_simmer(act, "BtnClear")
end
AddAction(newaction)
newaction = nil

--------------------------------------------------------------------------
--[[ 细微之触切换实体的贴图细节的动作 ]]
--------------------------------------------------------------------------

newaction = Action({ priority=8, rmb=true, distance=20, mount_valid=true })
newaction.id = "REDETAIL_L"
newaction.str = STRINGS.ACTIONS_LEGION.REDETAIL_L
newaction.fn = function(act)
    local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if staff ~= nil and staff.fn_redetail ~= nil and act.target ~= nil and ( act.target.legionfn_redetailed ~= nil or
        (staff.redetailables ~= nil and staff.redetailables[act.target.prefab]) )
    then
        staff.fn_redetail(staff, act.target, act.doer)
        return true
    end
end
AddAction(newaction)
newaction = nil

AddComponentAction("EQUIPPED", "z_shadowbrush", function(inst, doer, target, actions, right)
    if right and ( target.legiontag_redetailable or
        (inst.redetailables ~= nil and inst.redetailables[target.prefab]) )
    then
        table.insert(actions, ACTIONS.REDETAIL_L)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.REDETAIL_L, "veryquickcastspell"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.REDETAIL_L, "veryquickcastspell"))
