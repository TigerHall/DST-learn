local prefs = {}
local TOOLS_L = require("tools_legion")
local ZIP_SOAK_L = require("zip_soak_legion")
local pas = {}

--------------------------------------------------------------------------
--[[ 通用函数 ]]
--------------------------------------------------------------------------

local TIME_DEFAULT = TUNING.SEG_TIME*8
local TIME_MAX = TUNING.SEG_TIME*30 --15分钟
local TIME_MAX_HALF = TUNING.SEG_TIME*15 --7.5分钟
local TIME_MAX2 = TUNING.SEG_TIME*80 --40分钟=5天
local oppositeBuffs = {
    buff_l_hungerretarder = { buff_l_oilflow = true },
    buff_l_holdbackpoop = { buff_l_oilflow = true },
    buff_l_oilflow = { buff_l_hungerretarder = true, buff_l_holdbackpoop = true },
    buff_l_lunarresist = { buff_l_shadowresist = true },
    buff_l_shadowresist = { buff_l_lunarresist = true },
    buff_l_dissipateshadow = { buff_l_dimmoonlight = true },
    buff_l_dimmoonlight = { buff_l_dissipateshadow = true },
    buff_l_warm = { buff_l_cool = true },
    buff_l_cool = { buff_l_warm = true },
}

local function BuffTalkOn(target, key, sets)
    if not target:HasTag("player") or (sets ~= nil and sets.notalk) then
        return
    end
    target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_"..string.upper(key), priority = 3 })
end
local function BuffTalkOff(target, key)
    if not target:HasTag("player") or target.legiontag_nobufftalk then
        return
    end
    target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_"..string.upper(key), priority = 3 })
end
local function PondBuffTalkOn(target, key, sets)
    if not target:HasTag("player") or (sets ~= nil and (sets.bath or sets.notalk)) then
        return
    end
    target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_"..string.upper(key), priority = 3 })
end

local function IsAlive(inst)
    return inst.components.health ~= nil and not inst.components.health:IsDead() and not inst:HasTag("playerghost")
end
local function CheckOppositeBuff(buff, target) --去除相克的buff，不让某些buff同时存在
    local nobuffs = oppositeBuffs[buff.prefab]
    if nobuffs == nil then
        return
    end
    local abuff
    for k, _ in pairs(nobuffs) do
        abuff = target:GetDebuff(k)
        if abuff ~= nil then
            if abuff.legionfn_oppositebuff ~= nil then --buff被抵消时，可能会有特殊逻辑要触发
                abuff.legionfn_oppositebuff(abuff, buff, target)
            end
            target:RemoveDebuff(k)
        end
    end
end
local function EndBuffSafely(buff, delaytime)
    if buff.task_l_end ~= nil then --该buff已经在移除中了，就不管了
        return
    end
    buff.task_l_end = buff:DoTaskInTime(delaytime or 0, function(fx) --至少下一帧再执行，不然加buff的函数里移除buff可能会崩
        fx.task_l_end = nil
        fx.components.debuff:Stop()
    end)
end

local function ComputValue(buff, target, sets, now, istwo)
    local k_kind, k_value, k_max
    if istwo then
        k_kind = "kind2"
        k_value = "value2"
        k_max = "max2"
    else
        k_kind = "kind"
        k_value = "value"
        k_max = "max"
    end
    local setsbase = buff._dd.sets
    local kind = setsbase[k_kind] or 1
    local value = setsbase[k_value] or 1
    local valuemax
    if sets ~= nil then
        if sets[k_kind] ~= nil then kind = sets[k_kind] end
        if sets[k_value] ~= nil then value = sets[k_value] end
    end
    if kind == 1 then --增加型：在已有数值上增加，可设置最大数值限制
        valuemax = sets and sets[k_max] or 0 --自定义的最大值
        if valuemax > 0 then
            --当前值小于自定义最大值，可以尝试相加
            --如果当前值本来就不小于自定义最大值了，那就什么都不改，不能影响已有的数值
            if now < valuemax then
                now = math.min(now + value, valuemax)
            end
        else
            now = now + value
        end
    elseif kind == 2 then --覆盖型：不管已有数值，直接覆盖
        now = value
    elseif kind == 3 then --变大替换型：若 已有数值<设定数值 时才设置新数值
        if now < value then
            now = value
        end
    elseif kind == 4 then --变小替换型：若 已有数值>设定数值 时才设置新数值
        if now > value then
            now = value
        end
    end
    if setsbase[k_max] ~= nil then
        valuemax = setsbase[k_max]
        if kind == 4 then --就算是自定义的也得大于默认的最小值
            if now < valuemax then
                now = valuemax
            end
        else --就算是自定义的也得小于默认的最大值
            if now > valuemax then
                now = valuemax
            end
        end
    end
    return now
end
local function UpdateCount(buff, target, sets)
    if buff._count_load_l ~= nil then --onsave比这里先加载
        buff._count_l = buff._count_load_l
        buff._count_load_l = nil
        if buff._count_l <= 0 then
            EndBuffSafely(buff)
        end
        return
    end
    local newvalue = ComputValue(buff, target, sets, buff._count_l or 0)
    buff._count_l = newvalue
    if newvalue <= 0 then
        EndBuffSafely(buff)
    end
end
local function OnSave_count(buff, data)
    if buff._count_l ~= nil then
        data._count_l = buff._count_l
    end
end
local function OnLoad_count(buff, data, newents)
    if data ~= nil then
        if data._count_l ~= nil then
            buff._count_load_l = data._count_l
        end
    end
end
local function FnServer_count3(buff) --变大替换型
    buff._count_l = 0
    buff.OnSave = OnSave_count
    buff.OnLoad = OnLoad_count
end
local function FnServer_count4(buff) --变小替换型
    buff._count_l = 1
    buff.OnSave = OnSave_count
    buff.OnLoad = OnLoad_count
end
local function UpdateCount2(buff, target, sets, iskind4) --单纯的进行数值更新
    if buff._count_load_l ~= nil then --onsave比这里先加载
        buff._count_l = buff._count_load_l
        buff._count_load_l = nil
        return
    end
    buff._count_l = ComputValue(buff, target, sets, buff._count_l or (iskind4 and 1 or 0), true)
end

local function TimerAttach(buff, target, sets)
    if buff.components.timer:TimerExists("buffover") then --因为onsave比这里先加载，所以不能替换先加载的
        return
    end
    local newvalue = ComputValue(buff, target, sets, 0)
    if newvalue <= 0 then
        EndBuffSafely(buff)
    else
        buff.components.timer:StartTimer("buffover", newvalue)
    end
end
local function TimerExtend(buff, target, sets)
    local newvalue = ComputValue(buff, target, sets, buff.components.timer:GetTimeLeft("buffover") or 0)
    if newvalue <= 0 then
        EndBuffSafely(buff)
    else
        buff.components.timer:StopTimer("buffover")
        buff.components.timer:StartTimer("buffover", newvalue)
    end
end
local function Fn_attached(inst, target, followsymbol, followoffset, sets, ...)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0) --in case of loading
    inst:ListenForEvent("death", function(owner, data)
        inst.components.debuff:Stop()
    end, target)

    if not inst._dd.notimer then
        TimerAttach(inst, target, sets)
    end
    if inst._dd.fn_start ~= nil then
        inst._dd.fn_start(inst, target, followsymbol, followoffset, sets, ...)
    end
end
local function Fn_detached(inst, target, ...)
    if inst._dd.fn_end ~= nil then
        inst._dd.fn_end(inst, target, ...)
    end
    inst:Remove()
end
local function Fn_extended(inst, target, followsymbol, followoffset, sets, ...)
    if not inst._dd.notimer then
        TimerExtend(inst, target, sets)
    end
    if inst._dd.fn_again ~= nil then
        inst._dd.fn_again(inst, target, followsymbol, followoffset, sets, ...)
    end
end
local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
        return
    end
    if inst._dd.fn_timerdone ~= nil then
        inst._dd.fn_timerdone(inst, data)
    end
end

local function MakeBuff(data)
	table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()

        if data.addnetwork then --带有网络组件
            inst.entity:AddTransform()
            inst.entity:AddNetwork()
            -- inst.entity:Hide()
            inst.persists = false

            -- inst:AddTag("CLASSIFIED")
            inst:AddTag("NOCLICK")
            inst:AddTag("NOBLOCK")

            if data.fn_common ~= nil then
                data.fn_common(inst)
            end

            inst.entity:SetPristine()
            if not TheWorld.ismastersim then return inst end
        else --无网络组件
            if not TheWorld.ismastersim then
                --Not meant for client!
                inst:DoTaskInTime(0, inst.Remove)
                return inst
            end
            inst.entity:AddTransform()
            --Non-networked entity
            inst.entity:Hide()
            inst.persists = false
            inst:AddTag("CLASSIFIED")
        end

        inst._dd = data

        if not data.notimer then
            inst:AddComponent("timer")
            inst:ListenForEvent("timerdone", OnTimerDone)
        end

        inst:AddComponent("debuff")
        inst.components.debuff.keepondespawn = true
        inst.components.debuff:SetAttachedFn(Fn_attached)
        inst.components.debuff:SetDetachedFn(Fn_detached)
        inst.components.debuff:SetExtendedFn(Fn_extended)

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, data.assets, data.prefabs))
end

--------------------------------------------------------------------------
--[[ 蝙蝠伪装：不会被蝙蝠主动攻击 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_batdisguise",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TIME_DEFAULT, max = TIME_MAX },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, buff.prefab, sets)
        if target.prefab ~= "bat" and target.prefab ~= "molebat" then
            target:AddTag("bat") --添加蝙蝠标签，蝙蝠不会攻击有该标签的生物
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, buff.prefab, sets)
        if target.prefab ~= "bat" and target.prefab ~= "molebat" then
            target:AddTag("bat")
        end
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        if target.prefab ~= "bat" and target.prefab ~= "molebat" then
            target:RemoveTag("bat")
        end
    end
})

--------------------------------------------------------------------------
--[[ 好胃口：能够吃自己不喜欢的食物，但仍然无法吃生理上无法食用的食物 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_bestappetite",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*2, max = TIME_MAX_HALF },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, buff.prefab, sets)
        target.legiontag_bestappetite = true --做标记。此处并没有别的操作，因为已经修改全局食性组件了，有这个buff就会启用
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, buff.prefab, sets)
        target.legiontag_bestappetite = true
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        target.legiontag_bestappetite = nil
    end
})

--------------------------------------------------------------------------
--[[ 蝴蝶庇佑：100%抵挡一次任何攻击 ]]
--------------------------------------------------------------------------

local function AddButterfly(buff, target, num, sets)
    local nummax = buff._dd.sets.max
    for i = 1, nummax, 1 do
        local fly = buff.flies[i]
        if fly == nil or not fly:IsValid() then
            fly = SpawnPrefab("neverfade_butterfly")
            buff.flies[i] = fly
            if fly ~= nil then
                local skin
                if sets ~= nil and sets.skin ~= nil then
                    skin = sets.skin
                else
                    skin = buff.flyskins[i]
                end
                if skin ~= nil then
                    if skin.bank ~= nil then
                        fly.AnimState:SetBank(skin.bank)
                    end
                    if skin.build ~= nil then
                        fly.AnimState:SetBuild(skin.build)
                    end
                    fly.skin_l = skin
                end
                buff.flyskins[i] = skin

                local x, y, z = target.Transform:GetWorldPosition()
                local x2, y2, z2 = TOOLS_L.GetCalculatedPos(x, y, z, 1+math.random()*2, nil)
                fly.Transform:SetPosition(x2, y2, z2)

                if target.components.leader ~= nil then
                    target.components.leader:AddFollower(fly)
                end
            end
            num = num - 1
            if num <= 0 then
                return
            end
        end
    end
end
local function DeleteButterfly(buff, target, num, doit)
    local nummax = buff._dd.sets.max
    for i = 1, nummax, 1 do
        local fly = buff.flies[i]
        if fly ~= nil then
            buff.flies[i] = nil
            buff.flyskins[i] = nil
            if fly:IsValid() then
                if fly:IsAsleep() then
                    fly:Remove()
                else
                    fly.legiontag_dead = doit and 2 or 1
                end
            end
            if num ~= nil then
                num = num - 1
                if num <= 0 then
                    return
                end
            end
        end
    end
end
local function OnButterflyBlessed(doer)
    local x, y, z = doer.Transform:GetWorldPosition()
    local fx1 = SpawnPrefab("buff_l_butterflybless_fx")
    local fx2 = SpawnPrefab("buff_l_butterflybless_fx2")
    if fx1 ~= nil then
        fx1.Transform:SetPosition(x, y, z)
    end
    if fx2 ~= nil then
        fx2.Transform:SetPosition(x, y-1, z) --高度居然可以是负数
    end

    local buff = doer.components.debuffable:GetDebuff("buff_l_butterflybless")
    if buff ~= nil then
        if buff._count_l > 0 then
            buff._count_l = buff._count_l - 1
            DeleteButterfly(buff, doer, 1, true)
            if buff._count_l > 0 then
                doer.legion_numblessing = buff._count_l
                return
            end
        end
        buff.components.debuff:Stop()
    else
        doer.legion_numblessing = nil
        doer.legionfn_butterflyblessed = nil
    end
end
local function OnSave_butterflybless(buff, data)
    data.flyskins = buff.flyskins
    OnSave_count(buff, data)
end
local function OnLoad_butterflybless(buff, data, newents)
    if data ~= nil then
        if data.flyskins ~= nil then
            buff.flyskins = data.flyskins
        end
    end
    OnLoad_count(buff, data, newents)
end

MakeBuff({
    name = "buff_l_butterflybless",
    -- assets = nil,
    prefabs = { "buff_l_butterflybless_fx", "buff_l_butterflybless_fx2" },
    notimer = true,
    sets = { value = 1, max = 5 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount(buff, target, sets)
        if buff._count_l <= 0 then
            return
        end
        target.legion_numblessing = buff._count_l
        target.legionfn_butterflyblessed = OnButterflyBlessed
        AddButterfly(buff, target, buff._count_l, sets)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        local oldv = buff._count_l
        UpdateCount(buff, target, sets)
        if buff._count_l <= 0 then
            return
        end
        target.legion_numblessing = buff._count_l
        target.legionfn_butterflyblessed = OnButterflyBlessed
        oldv = buff._count_l - oldv
        if oldv < 0 then
            DeleteButterfly(buff, target, -oldv)
        elseif oldv > 0 then
            AddButterfly(buff, target, oldv, sets)
        end
    end,
    fn_end = function(buff, target)
        buff._count_l = 0
        target.legion_numblessing = nil
        target.legionfn_butterflyblessed = nil
        DeleteButterfly(buff, target, nil)
    end,
    fn_server = function(buff)
        buff._count_l = 0
        buff.flies = {}
        buff.flyskins = {}
        buff.OnSave = OnSave_butterflybless
        buff.OnLoad = OnLoad_butterflybless
    end
})

--------------------------------------------------------------------------
--[[ 血库：按需提供生命值恢复 ]]
--------------------------------------------------------------------------

local function Heal_healthstorage(inst, target)
    inst.task_l_heal = nil
    if IsAlive(target) and inst._count_l > 0 then
        local need = target.components.health:GetMaxWithPenalty() - target.components.health.currenthealth
        if need >= 5 then
            if inst._count_l > need then
                inst._count_l = inst._count_l - need
            else
                need = inst._count_l
                inst._count_l = 0
            end
            target.components.health:DoDelta(need, true, "shyerry", true, nil, true)
            if inst._count_l <= 0 then
                EndBuffSafely(inst)
            end
        end
    else
        EndBuffSafely(inst)
    end
end
local function TryHeal_healthstorage(buff, target)
    if IsAlive(target) and buff._count_l > 0 then
        if
            buff.task_l_heal == nil and
            (target.components.health:GetMaxWithPenalty() - target.components.health.currenthealth) >= 5
        then
            buff.task_l_heal = buff:DoTaskInTime(0, Heal_healthstorage, target)
        end
    else
        EndBuffSafely(buff)
    end
end

MakeBuff({
    name = "buff_l_healthstorage",
    -- assets = nil, prefabs = nil,
    notimer = true,
    sets = { value = 100 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        if target.components.oldager ~= nil then --物理回血效果，无法对旺达起作用
            EndBuffSafely(buff)
            return
        end
        UpdateCount(buff, target, sets)
        if buff._count_l <= 0 then
            return
        end
        TryHeal_healthstorage(buff, target)
        buff:ListenForEvent("healthdelta", buff.fn_l_healthdelta, target)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        if target.components.oldager ~= nil then
            EndBuffSafely(buff)
            return
        end
        UpdateCount(buff, target, sets)
        if buff._count_l <= 0 then
            return
        end
        TryHeal_healthstorage(buff, target)
    end,
    fn_end = function(buff, target)
        if buff.task_l_heal ~= nil then
            buff.task_l_heal:Cancel()
            buff.task_l_heal = nil
        end
        buff._count_l = 0
        buff:RemoveEventCallback("healthdelta", buff.fn_l_healthdelta, target)
    end,
    fn_server = function(buff)
        FnServer_count3(buff)
        buff.fn_l_healthdelta = function(target, data)
            TryHeal_healthstorage(buff, target)
        end
    end
})

--------------------------------------------------------------------------
--[[ 孢子抵抗力：减少25%受到的伤害(进行防具抵扣之后的值) ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_sporeresistance",
    -- assets = nil, notimer = nil,
    prefabs = { "buff_l_sporeresistance_fx" },
    sets = { value = TUNING.SEG_TIME*6, max = TIME_MAX },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        if buff.task_l_fx == nil then
            buff.task_l_fx = buff:DoPeriodicTask(0.7, function()
                buff:DoTaskInTime(math.random()*0.6, function()
                    if target:IsValid() then
                        SpawnPrefab("buff_l_sporeresistance_fx").Transform:SetPosition(target.Transform:GetWorldPosition())
                    end
                end)
            end, 0.5+3*math.random())
        end
        if target.components.health ~= nil then
            target.components.health.externalabsorbmodifiers:SetModifier(buff, 0.25) --生命组件里的这个机制是a+b的
        end
    end,
    -- fn_again = nil,
    fn_end = function(buff, target)
        if target.components.health ~= nil then
            target.components.health.externalabsorbmodifiers:RemoveModifier(buff)
        end
        if buff.task_l_fx ~= nil then
            buff.task_l_fx:Cancel()
            buff.task_l_fx = nil
        end
    end
})

--------------------------------------------------------------------------
--[[ 蛮力：增加50%普通攻击力 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_strengthenhancer",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*16, max = TIME_MAX },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        --因为触发一般是喝药酒，吃的时候已经说话提示了，所以这里就不用再说
        if target.components.combat ~= nil then
            target.components.combat.externaldamagemultipliers:SetModifier(buff, 1.5) --普通攻击系数x1.5倍
        end
    end,
    -- fn_again = nil,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        if target.components.combat ~= nil then
            target.components.combat.externaldamagemultipliers:RemoveModifier(buff)
        end
    end
})

--------------------------------------------------------------------------
--[[ 怜悯：降低30%全能攻击力 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_merciful",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*2, max = TIME_MAX_HALF },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        -- if target.components.damagetypebonus == nil then --通过这个组件能使得弱化效果能同时应用给普攻和特攻
        --     target:AddComponent("damagetypebonus")
        -- end
        -- target.components.damagetypebonus:AddBonus("_health", target, 0.7, "buff_l_merciful")
        --"inspectable"标签覆盖范围比"_health"标签广
        -- target.components.damagetypebonus:AddBonus("inspectable", target, 0.7, "buff_l_merciful")
        BuffTalkOn(target, buff.prefab, sets)
        TOOLS_L.AddBonusAll(target, "buff_l_merciful", 0.7)
        target.AnimState:SetMultColour(165/255, 188/255, 47/255, 1)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        -- BuffTalkOn(target, buff.prefab, sets)
        target.AnimState:SetMultColour(165/255, 188/255, 47/255, 1)
    end,
    fn_end = function(buff, target)
        -- if target.components.damagetypebonus ~= nil then
            -- target.components.damagetypebonus:RemoveBonus("_health", target, "buff_l_merciful")
            -- target.components.damagetypebonus:RemoveBonus("inspectable", target, "buff_l_merciful")
        -- end
        BuffTalkOff(target, buff.prefab)
        TOOLS_L.RemoveBonusAll(target, "buff_l_merciful")
        target.AnimState:SetMultColour(1, 1, 1, 1)
    end
})

--------------------------------------------------------------------------
--[[ 捣蛋鬼惊吓：进入被惊吓sg ]]
--------------------------------------------------------------------------

local function AlignToTarget(inst, target)
    inst.Transform:SetRotation(target.Transform:GetRotation())
end
local function OnChangeFollowSymbol(inst, target, followsymbol, followoffset)
    if followsymbol ~= nil and followoffset ~= nil then
        inst.Follower:FollowSymbol(target.GUID, followsymbol, followoffset.x, followoffset.y, followoffset.z)
    end
end

MakeBuff({ --这个buff的代码借鉴的毒菌蟾蜍的孢子技能
    name = "buff_l_panicvolcano",
    assets = {
        Asset("ANIM", "anim/debuff_panicvolcano.zip")
    },
    notimer = true, addnetwork = true,
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        buff.entity:SetParent(target.entity)
        OnChangeFollowSymbol(buff, target, followsymbol, followoffset)
        if buff.task_l_follow ~= nil then
            buff.task_l_follow:Cancel()
        end
        buff.task_l_follow = buff:DoPeriodicTask(0, AlignToTarget, nil, target)
        AlignToTarget(buff, target)

        target:PushEvent("bevolcanopaniced")
    end,
    -- fn_again = nil,
    fn_end = function(buff, target)
        local player = buff.entity:GetParent()
        if player ~= nil and player.components.talker ~= nil and player:HasTag("player") then
            player.components.talker:Say(GetString(player, "DESCRIBE", { "DISH_SUGARLESSTRICKMAKERCUPCAKES", "TRICKED" }))
        end
        if buff.task_l_follow ~= nil then
            buff.task_l_follow:Cancel()
            buff.task_l_follow = nil
        end
    end,
    fn_common = function(buff)
        buff.entity:AddFollower()
        buff.entity:AddAnimState()

        buff:AddTag("FX")

        buff.Transform:SetFourFaced()

        buff.AnimState:SetBank("debuff_panicvolcano")
        buff.AnimState:SetBuild("debuff_panicvolcano")
        buff.AnimState:PlayAnimation("anim")
        buff.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        buff.AnimState:SetFinalOffset(3)
        buff.AnimState:SetLightOverride(0.2)
    end,
    fn_server = function(buff)
        buff.components.debuff:SetChangeFollowSymbolFn(OnChangeFollowSymbol)
        buff:ListenForEvent("animover", function(fx)
            fx.components.debuff:Stop()
        end)
    end
})

--------------------------------------------------------------------------
--[[ 腹得流油：不断拉粑粑（主要是鱼的油脂） ]]
--------------------------------------------------------------------------

local function StartOilFlowing(buff, inst)
    if buff.task_l ~= nil then
        buff.task_l:Cancel()
    end
    buff.task_l = inst:DoPeriodicTask(2, function(inst)
        if not IsAlive(inst) then
            buff.components.debuff:Stop()
            return
        end
        if math.random() >= 0.6 then
            return
        end
        local poopname = "poop"
        if math.random() < 0.005 then
            poopname = "beeswax"
        elseif inst:HasTag("spider") then
            poopname = "silk"
        elseif inst:HasTag("bat") then
            poopname = "guano"
        -- else --将来要是还有合适的生物，也可以拉一些特殊的排泄物
        end
        local poop = SpawnPrefab(poopname)
        if poop ~= nil then
            ------让粑粑飞
            local x1, y1, z1 = inst.Transform:GetWorldPosition()
            local angle = inst.Transform:GetRotation() + 20 - math.random()*40
            local theta = (angle+180)*DEGREES
            poop.Transform:SetPosition(x1, y1+0.5, z1)
            --Tip：SetMotorVel()会一直给加速度，SetVel()则会受到摩擦阻力和重力影响
            poop.Physics:SetVel(2.5*math.cos(theta), 2, -2.5*math.sin(theta))
            poop:PushEvent("l_autostack") --为了能自动叠加

            if inst:HasTag("player") then
                ------说尴尬的话
                if inst.components.talker ~= nil and not inst:HasTag("mime") and math.random() < 0.4 then
                    local words = STRINGS.CHARACTERS[string.upper(inst.prefab)]
                    if words ~= nil and words.BUFF_L_OILFLOW ~= nil then
                        words = words.BUFF_L_OILFLOW
                    else
                        words = STRINGS.CHARACTERS.GENERIC.BUFF_L_OILFLOW
                    end
                    inst.components.talker:Say(GetRandomItem(words))
                end

                ------让玩家向前推进
                inst:PushEvent("awkwardpropeller", { angle = angle })
            else
                ------让对象向前推进
                if inst.sg == nil or not inst.sg:HasStateTag("busy") then
                    inst:PushEvent("attacked", { damage = 0 })
                    if inst.Physics ~= nil then
                        inst.Transform:SetRotation(angle)
                        inst.Physics:SetVel(5, 0, 0)
                    end
                end
            end

            ------增加潮湿度
            if inst.components.moisture ~= nil then
                inst.components.moisture:DoDelta(0.5)
            end

            ------饥饿值消耗
            if inst.components.hunger ~= nil and not inst.components.hunger:IsStarving() then
                inst.components.hunger:DoDelta(-3.5)
            else
                inst.components.health:DoDelta(-5, false, buff.prefab)
            end

            inst:PushEvent("on_poop", { doer = buff, hungerdelta = -3.5, item = poop })
        end
    end, 3+5*math.random())
end

MakeBuff({
    name = "buff_l_oilflow",
    sets = { value = TUNING.SEG_TIME*3, max = TIME_MAX_HALF },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        StartOilFlowing(buff, target)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        StartOilFlowing(buff, target)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        if buff.task_l ~= nil then
            buff.task_l:Cancel()
            buff.task_l = nil
        end
    end
})

--------------------------------------------------------------------------
--[[ 饱腹感：饱食度下降速度降低90% ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_hungerretarder",
    sets = { value = TUNING.SEG_TIME*10, max = TUNING.SEG_TIME*50 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.hunger ~= nil then
            target.components.hunger.burnratemodifiers:SetModifier(buff, 0.1) --饱食度下降速度降为0.1倍
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        if target.components.hunger ~= nil then
            target.components.hunger.burnratemodifiers:RemoveModifier(buff)
        end
    end
})

--------------------------------------------------------------------------
--[[ 憋住：憋住粑粑，结束时一次性拉出 ]]
--------------------------------------------------------------------------

local function Task_holdbackpoop(buff)
    buff.count_held_l = buff.count_held_l + 1
end
local function OnSave_holdbackpoop(inst, data)
    if inst.count_held_l > 0 then
        data.count_held_l = inst.count_held_l
    end
end
local function OnLoad_holdbackpoop(inst, data)
    if data ~= nil then
        inst.count_held_l = data.count_held_l or 0
    end
end

MakeBuff({
    name = "buff_l_holdbackpoop",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.TOTAL_DAY_TIME*5, max = TUNING.TOTAL_DAY_TIME*50 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        if buff.task_l_hold ~= nil then
            buff.task_l_hold:Cancel()
            buff.task_l_hold = nil
        end
        if target.components.periodicspawner ~= nil then
            local cpt = target.components.periodicspawner
            local t = cpt.basetime + 0.5*cpt.randtime
            buff.task_l_hold = buff:DoPeriodicTask(t, Task_holdbackpoop, 1+9*math.random())
            cpt:Stop() --憋住！
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        if target.components.periodicspawner ~= nil then
            target.components.periodicspawner:Stop()
        end
    end,
    fn_end = function(buff, target)
        if buff.task_l_hold ~= nil then
            buff.task_l_hold:Cancel()
            buff.task_l_hold = nil
        end
        local poopname = "poop"
        if target.components.periodicspawner ~= nil then
            target.components.periodicspawner:Start()
            poopname = target.components.periodicspawner.prefab
            if type(poopname) == "function" then
                poopname = poopname(target)
            end
        end
        if buff.count_held_l > 0 then
            local pos = target:GetPosition()
            local rot = target.Transform:GetRotation()
            local poops = {}
            TOOLS_L.SpawnStackDrop(poopname or "poop", buff.count_held_l, pos, nil, poops, { dropper = target })
            for _, v in ipairs(poops) do
                local theta = (rot + 20 - math.random()*40 + 180)*DEGREES
                v.Transform:SetPosition(pos.x, pos.y+0.5, pos.z)
                v.Physics:SetVel(2.5*math.cos(theta), 2, -2.5*math.sin(theta))
            end
        end
    end,
    fn_server = function(buff)
        buff.count_held_l = 0
        buff.OnSave = OnSave_holdbackpoop
        buff.OnLoad = OnLoad_holdbackpoop
    end
})

--------------------------------------------------------------------------
--[[ 魔音绕耳：不断卸下装备 ]]
--------------------------------------------------------------------------

local function DropEquipment_magicwarble(v)
    if v.components.inventory ~= nil then
        if v.components.health == nil or not (v.components.health:IsDead() or v:HasTag("playerghost")) then
            -- v.components.inventory:DropEquipped(false)
            local inv = v.components.inventory
            for slot, item in pairs(inv.equipslots) do
                if slot ~= EQUIPSLOTS.BEARD then --可不能把威尔逊的“胡子”给吼下来了
                    inv:DropItem(item, true, true)
                end
            end
        end
    end
end

MakeBuff({
    name = "buff_l_magicwarble",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = 6, max = TUNING.SEG_TIME },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        if target.legiontask_magicwarble ~= nil then
            target.legiontask_magicwarble:Cancel()
            target.legiontask_magicwarble = nil
        end
        if target.components.inventory ~= nil then
            target.legiontask_magicwarble = target:DoPeriodicTask(0.9, DropEquipment_magicwarble, 1)
        end
        if sets ~= nil and sets.dogroggy and target.components.locomotor ~= nil then
            if target.components.grogginess ~= nil then --一般这个组件只有玩家才有
                --不想用 Grogginess:AddGrogginess 的官方逻辑，字太多，不想看
                target:AddTag("groggy") --添加标签，走路会摇摇晃晃
            end
            target.components.locomotor:SetExternalSpeedMultiplier(target, "buff_l_magicwarble", 0.4)
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        if sets ~= nil and not sets.dogroggy then
            target:RemoveTag("groggy")
            if target.components.locomotor ~= nil then
                target.components.locomotor:RemoveExternalSpeedMultiplier(target, "buff_l_magicwarble")
            end
        end
    end,
    fn_end = function(buff, target)
        if target.legiontask_magicwarble ~= nil then
            target.legiontask_magicwarble:Cancel()
            target.legiontask_magicwarble = nil
        end
        target:RemoveTag("groggy") --不想用 Grogginess组件 的官方逻辑，出问题就出吧，问题不大，影响播放的动画而已
        if target.components.locomotor ~= nil then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "buff_l_magicwarble")
        end
    end
})

--------------------------------------------------------------------------
--[[ 神木光辉：增加全能防御力 ]]
--------------------------------------------------------------------------

local function OnChangeFollowSymbol_tree(inst, target, followsymbol, followoffset)
    if target:HasTag("siving_boss") then --这个buff特效我想让它的位置在玄鸟头部
        followsymbol = "buzzard_head"
        followoffset = { x = 0, y = -20, z = 0 }
    end
    if followsymbol ~= nil and followoffset ~= nil then
        inst.Follower:FollowSymbol(target.GUID, followsymbol, followoffset.x, followoffset.y, followoffset.z)
    end
end
local function SetStateSymbol(buff, state)
    if state == 1 then
        buff.AnimState:OverrideSymbol("insidetooth2", "siving_treehalo_fx", "insidetooth2")
    elseif state == 2 then
        buff.AnimState:OverrideSymbol("insidetooth2", "siving_treehalo_fx", "base2")
    else
        buff.AnimState:OverrideSymbol("insidetooth2", "siving_treehalo_fx", "base3")
    end
end
local function BuffSet_tree(buff, target, dt)
    if buff._count_load_l ~= nil then
        dt = buff._count_load_l
        buff._count_load_l = nil
    end
    dt = math.min(buff._count_l + dt, 3)
    if dt <= 0 then --新的层数为0，结束buff
        buff._count_l = 0
        target.legion_numtreehalo = nil
        if buff:IsAsleep() then
            EndBuffSafely(buff)
        else
            if buff.task_l_end == nil then
                buff.AnimState:PlayAnimation("pst")
                EndBuffSafely(buff, buff.AnimState:GetCurrentAnimationLength()) --动画播放结束再删除buff
            end
        end
        return
    end
    if buff._count_l == dt then --层数没变化，就不继续执行了
        return
    end
    if buff._count_l > 0 then --当前有层数，所以动画为“变化”
        buff.AnimState:PlayAnimation("exchange")
        if buff.task_l_animex ~= nil then
            buff.task_l_animex:Cancel()
        end
        buff.task_l_animex = buff:DoTaskInTime(0.3, function(fx)
            fx.task_l_animex = nil
            SetStateSymbol(fx, fx._count_l)
        end)
    else --当前无层数，说明是一开始产生buff的，动画为“开始”
        SetStateSymbol(buff, dt)
        buff.AnimState:PlayAnimation("pre")
    end
    buff.AnimState:PushAnimation("loop", true)
    buff._count_l = dt
    target.legion_numtreehalo = dt
    if dt >= 3 then
        TOOLS_L.AddResistAll(target, "buff_l_treehalo", 0.01)
    elseif dt >= 2 then
        TOOLS_L.AddResistAll(target, "buff_l_treehalo", 0.34)
    else
        TOOLS_L.AddResistAll(target, "buff_l_treehalo", 0.67)
    end
end

MakeBuff({
    name = "buff_l_treehalo",
    assets = {
        Asset("ANIM", "anim/siving_treehalo_fx.zip")
    },
    notimer = true, addnetwork = true,
    -- sets = { value = 1, max = 3 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        buff.entity:SetParent(target.entity)
        OnChangeFollowSymbol_tree(buff, target, followsymbol, followoffset)
        BuffSet_tree(buff, target, sets and sets.value or 1)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        local dt = sets and sets.value or 1
        if buff.task_l_end ~= nil then --buff在准备删除中
            if dt > 0 then --如果是增加层数，则可以取消删除
                buff.task_l_end:Cancel()
                buff.task_l_end = nil
            else
                return
            end
        end
        BuffSet_tree(buff, target, dt)
    end,
    fn_end = function(buff, target)
        if buff.task_l_animex ~= nil then
            buff.task_l_animex:Cancel()
            buff.task_l_animex = nil
        end
        buff._count_l = 0
        target.legion_numtreehalo = nil
        if target:IsValid() then
            TOOLS_L.RemoveResistAll(target, "buff_l_treehalo")
        end
    end,
    fn_common = function(buff)
        buff.entity:AddFollower()
        buff.entity:AddAnimState()

        buff:AddTag("FX")

        buff.AnimState:SetBank("siving_treehalo_fx")
        buff.AnimState:SetBuild("siving_treehalo_fx")
        buff.AnimState:PlayAnimation("loop", true)
        buff.AnimState:SetScale(0.35, 0.35)
        buff.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        buff.AnimState:SetLightOverride(0.6)
        buff.AnimState:SetFinalOffset(-3) --让这个动画位于父体层级底部
    end,
    fn_server = function(buff)
        FnServer_count3(buff)
        buff.components.debuff:SetChangeFollowSymbolFn(OnChangeFollowSymbol_tree)
    end
})

--------------------------------------------------------------------------
--[[ 闪亮皮肤：身体发光 ]]
--------------------------------------------------------------------------

local time_radiant = 20
local step_radiant = FRAMES*2
local radius_radiant = 3
local steprad_radiant = radius_radiant/time_radiant
local function LightFading_radiant(buff)
    buff.time_fade_l = buff.time_fade_l - step_radiant
    if buff.time_fade_l > 0 then
        buff.Light:SetRadius(steprad_radiant*buff.time_fade_l)
    else
        buff.Light:Enable(false)
        if buff.task_l_fade ~= nil then
            buff.task_l_fade:Cancel()
            buff.task_l_fade = nil
        end
    end
end
local function BuffSet_radiant(buff, target, followsymbol, followoffset, sets)
    if buff.task_l_fade ~= nil then
        buff.task_l_fade:Cancel()
        buff.task_l_fade = nil
    end

    local timeleft = buff.components.timer:GetTimeLeft("buffover") or 0
    if timeleft <= 0 then --按理来说，这里不该发生
        EndBuffSafely(buff)
        return
    end
    if timeleft > time_radiant then
        buff.time_fade_l = time_radiant
        timeleft = timeleft - time_radiant
    else
        buff.time_fade_l = timeleft
        timeleft = 0
    end
    buff.Light:SetRadius(steprad_radiant*buff.time_fade_l)
    buff.Light:Enable(true)
    buff.task_l_fade = buff:DoPeriodicTask(step_radiant, LightFading_radiant, timeleft)
end

MakeBuff({
    name = "buff_l_radiantskin",
    addnetwork = true,
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffSet_radiant(buff, target, followsymbol, followoffset, sets)
        if target.components.bloomer ~= nil then
            target.components.bloomer:PushBloom(buff, "shaders/anim.ksh", 0.33)
        else
            target.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end
    end,
    fn_again = BuffSet_radiant,
    fn_end = function(buff, target)
        if buff.task_l_fade ~= nil then
            buff.task_l_fade:Cancel()
            buff.task_l_fade = nil
        end
        if target.components.bloomer ~= nil then
            target.components.bloomer:PopBloom(buff)
        else
            target.AnimState:ClearBloomEffectHandle()
        end
    end,
    fn_common = function(buff)
        buff.entity:AddLight()
        buff.Light:SetRadius(radius_radiant)
        buff.Light:SetIntensity(0.8)
        buff.Light:SetFalloff(0.5)
        buff.Light:SetColour(169/255, 231/255, 245/255) --光源配置和发光浆果一致
        buff.Light:Enable(true)
        -- buff.Light:EnableClientModulation(true)
    end
})

--------------------------------------------------------------------------
--[[ 隔火皮肤：自身完全防火 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_fireproof",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.health ~= nil then --免疫火焰伤
            target.components.health.externalfiredamagemultipliers:SetModifier(buff, 0)
        end
        TOOLS_L.AddEntValue(target, "legiontag_fireproof", buff.prefab, nil, 1)
        if not target:HasTag("player") then --为了方便玩家观察
            TOOLS_L.AddTag(target, "fireproof_legion", "fireproof_buff")
        end
        if target.components.burnable ~= nil and
            (target.components.burnable:IsBurning() or target.components.burnable:IsSmoldering())
        then
            target.components.burnable:Extinguish() --顺便灭火
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        PondBuffTalkOn(target, buff.prefab, sets)
        if target.components.burnable ~= nil and
            (target.components.burnable:IsBurning() or target.components.burnable:IsSmoldering())
        then
            target.components.burnable:Extinguish() --顺便灭火
        end
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        if target.components.health ~= nil then
            target.components.health.externalfiredamagemultipliers:RemoveModifier(buff)
        end
        TOOLS_L.RemoveEntValue(target, "legiontag_fireproof", buff.prefab, nil)
        TOOLS_L.RemoveTag(target, "fireproof_legion", "fireproof_buff")
    end
})

--------------------------------------------------------------------------
--[[ 假弱皮肤：增加50%窃血抵抗 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_sivbloodreduce",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, buff.prefab, sets)
        TOOLS_L.AddEntValue(target, "siv_blood_l_reducer", "buff_l_sivbloodreduce", 1, 0.5)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        PondBuffTalkOn(target, buff.prefab, sets)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        TOOLS_L.RemoveEntValue(target, "siv_blood_l_reducer", "buff_l_sivbloodreduce", 1)
    end
})

--------------------------------------------------------------------------
--[[ 好事多蘑：额外判定某些掉落物是否掉落并且有保底次数 ]]
--------------------------------------------------------------------------

local function BuffTalk_effortluck(buff, target, key)
    if target.components.talker ~= nil then
        local str = GetString(target, "ANNOUNCE_BUFF_L_EFFORTLUCK", key)
        if str ~= nil then
            if key ~= "DETACH" then
                str = subfmt(str, { luck = tostring(buff._count_l) })
            end
            target.components.talker:Say(str)
        end
    end
end
local function DropLoot_effortluck(itemname, dropper, v, doer)
    local items = {}
    local num = 1
    local noinf
    if v ~= nil then
        if v.fn_spawn ~= nil then
            itemname = v.fn_spawn(dropper, doer, items)
        end
        if v.num ~= nil then
            num = v.num
        elseif v.num_random ~= nil then
            num = math.random(v.num_random[1], v.num_random[2])
        end
        noinf = v.noinf
    end
    if itemname ~= nil then
        TOOLS_L.SpawnStackDrop(itemname, num, dropper:GetPosition(), nil, items, nil)
    end
    for _, item in pairs(items) do
        if noinf or item.components.equippable ~= nil then
            item:AddDebuff("buff_l_goldenloot", "buff_l_goldenloot")
        else
            item:AddDebuff("buff_l_goldenloot_inf", "buff_l_goldenloot_inf")
        end
    end
end
local function OnEntityDropLoot_effortluck(buff, target, data) --entity_droploot 一般是死亡或者被破坏时触发
    if data == nil then
        return
    end
    local victim = data.inst
    local luckpoint = buff._count_l or 0
    if victim == nil or not victim:IsValid() or luckpoint <= 0 then
        return
    end
    local luckkey
    if victim.legiontag_moonprotector then
        luckkey = "moonprotector_l"
    else
        luckkey = data.luckkey or victim.prefab
    end
    if not victim.legiontag_luckdone and
        (victim.legion_luckdoers == nil or not victim.legion_luckdoers[target]) and
        LUCK_DATA_LEGION[luckkey] ~= nil and target:IsNear(victim, 28)
    then
        local doit = false
        local checkedall = true
        local itemcheck = victim.legion_luckcheck or {}
        local ddbase = LUCK_DATA_LEGION[luckkey]
        local dddoer = target.legion_luckdata or {}
        for itemname, v in pairs(ddbase) do
            if itemcheck[itemname] == nil then --说明该项物品还没判定过
                if (v.cost or 1) <= luckpoint then --剩余幸运值需要足够才行
                    local count = dddoer[itemname] or 0
                    if math.random() < v.chance then
                        count = 0
                        DropLoot_effortluck(itemname, victim, v, target)
                        luckpoint = luckpoint - (v.cost or 1)
                    else
                        count = count + v.chance
                        if count >= 1 then --达到保底要求
                            count = count - 1
                            DropLoot_effortluck(itemname, victim, v, target)
                            luckpoint = luckpoint - (v.cost or 1)
                        end
                    end
                    dddoer[itemname] = count > 0 and count or nil
                    itemcheck[itemname] = true
                    doit = true
                else
                    checkedall = false
                end
            end
        end
        if doit then
            target.legion_luckdata = dddoer
            victim.legion_luckcheck = itemcheck
            if luckpoint ~= buff._count_l then
                buff._count_l = luckpoint
                target.legion_numeffortluck = luckpoint
                if luckpoint > 0 then
                    BuffTalk_effortluck(buff, target, "COST")
                end
            end
        end
        if checkedall then
            victim.legiontag_luckdone = true
        else --可不能一个玩家触发多次
            if victim.legion_luckdoers == nil then
                victim.legion_luckdoers = {}
            end
            victim.legion_luckdoers[target] = true
        end
        if luckpoint <= 0 then
            EndBuffSafely(buff)
        end
    end
end
local function OnEntityDeath_effortluck(buff, target, data)
    --貌似也没啥好改的
    OnEntityDropLoot_effortluck(buff, target, data)
end

MakeBuff({
    name = "buff_l_effortluck",
    -- assets = nil, prefabs = nil,
    notimer = true,
    sets = { value = 1, max = 20 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount(buff, target, sets)
        target.legion_numeffortluck = buff._count_l
        if buff._count_l <= 0 then
            return
        end
        BuffTalk_effortluck(buff, target, "ATTACH")
        if target.legionfn_luck_entityloot == nil then
            target.legionfn_luck_entityloot = function(src, data) OnEntityDropLoot_effortluck(buff, target, data) end
            target:ListenForEvent("entity_droploot", target.legionfn_luck_entityloot, TheWorld)
        end
        if target.legionfn_luck_entitydeath == nil then
            target.legionfn_luck_entitydeath = function(src, data) OnEntityDeath_effortluck(buff, target, data) end
            target:ListenForEvent("entity_death", target.legionfn_luck_entitydeath, TheWorld)
        end
        if target.legionfn_luck_do == nil then --自定义的监听
            target.legionfn_luck_do = function(src, data) OnEntityDropLoot_effortluck(buff, target, data) end
            target:ListenForEvent("legion_luckydo", target.legionfn_luck_do, TheWorld)
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount(buff, target, sets)
        target.legion_numeffortluck = buff._count_l
        if buff._count_l <= 0 then
            return
        end
        BuffTalk_effortluck(buff, target, "ATTACH")
    end,
    fn_end = function(buff, target)
        BuffTalk_effortluck(buff, target, "DETACH")
        target.legion_numeffortluck = nil
        if target.legionfn_luck_entityloot ~= nil then
            target:RemoveEventCallback("entity_droploot", target.legionfn_luck_entityloot, TheWorld)
            target.legionfn_luck_entityloot = nil
        end
        if target.legionfn_luck_entitydeath ~= nil then
            target:RemoveEventCallback("entity_death", target.legionfn_luck_entitydeath, TheWorld)
            target.legionfn_luck_entitydeath = nil
        end
        if target.legionfn_luck_do ~= nil then
            target:RemoveEventCallback("legion_luckydo", target.legionfn_luck_do, TheWorld)
            target.legionfn_luck_do = nil
        end
    end,
    fn_server = FnServer_count3
})

--------------------------------------------------------------------------
--[[ 金色传说：金色并且有光子特效 ]]
--------------------------------------------------------------------------

local assets_goldenloot = {
    Asset("ANIM", "anim/lavaarena_item_pickup_fx.zip") --官方的动画模板
}
local function BuffSet_goldenloot(buff, target, followsymbol, followoffset, sets)
    if target.components.bloomer ~= nil then
        target.components.bloomer:PushBloom(buff, "shaders/anim.ksh", 0.33)
    else
        target.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
    target.AnimState:SetAddColour(166/255, 119/255, 32/255, 0) --第四个参数不知道什么意思
    target.legiontag_goldenloot = true
    -- buff.AnimState:PlayAnimation("pre")
    -- buff.AnimState:PushAnimation("loop", true)
    buff.AnimState:PlayAnimation("loop", true)
    TOOLS_L.RandomAnimFrame(buff)
    --因为buff是target的子实体，所以target被删除时，buff也会被直接删除，所以不用再考虑buff的删除残留
end
local function BuffEnd_goldenloot(buff, target)
    if target.components.bloomer ~= nil then
        target.components.bloomer:PopBloom(buff)
    else
        target.AnimState:ClearBloomEffectHandle()
    end
    target.AnimState:SetAddColour(0, 0, 0, 0) --设为纯黑色rbg就是清除颜色滤镜
    target.legiontag_goldenloot = nil
    if not target:IsAsleep() then
        local fx = SpawnPrefab("buff_l_goldenloot_fx")
        if fx ~= nil then
            fx.Transform:SetPosition(target.Transform:GetWorldPosition())
        end
    end
end
local function BuffCommon_goldenloot(buff)
    buff.entity:AddAnimState()
    buff.AnimState:SetBank("lavaarena_item_pickup_fx")
    buff.AnimState:SetBuild("lavaarena_item_pickup_fx")
    -- buff.AnimState:PlayAnimation("pre")
    -- buff.AnimState:PushAnimation("loop", true)
    buff.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    buff.AnimState:SetLightOverride(.4)
    buff.AnimState:SetFinalOffset(1)
    buff.AnimState:SetMultColour(255/255, 211/255, 66/255, 1)
    buff.AnimState:SetScale(0.6, 0.6, 0.6)
end

MakeBuff({
    name = "buff_l_goldenloot",
    assets = assets_goldenloot,
    prefabs = { "buff_l_goldenloot_fx" },
    -- notimer = nil,
    addnetwork = true,
    sets = { value = TUNING.TOTAL_DAY_TIME, max = TUNING.TOTAL_DAY_TIME },
    fn_start = BuffSet_goldenloot,
    -- fn_again = nil,
    fn_end = BuffEnd_goldenloot,
    fn_common = BuffCommon_goldenloot
})
MakeBuff({
    name = "buff_l_goldenloot_inf",
    assets = assets_goldenloot,
    prefabs = { "buff_l_goldenloot_fx" },
    notimer = true, addnetwork = true,
    fn_start = BuffSet_goldenloot,
    -- fn_again = nil,
    fn_end = BuffEnd_goldenloot,
    fn_common = BuffCommon_goldenloot
})

--------------------------------------------------------------------------
--[[ 位面稳固：提供位面防御 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_planardefense",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*12, max = TIME_MAX, kind2 = 3, value2 = 5 }, --目前怪物的位面攻击普遍是30
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets)
        if buff._count_l <= 0 then
            return
        end
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.planardefense == nil then
            target:AddComponent("planardefense")
        end
        target.components.planardefense:AddBonus(buff, buff._count_l)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets)
        if target.components.planardefense == nil then
            target:AddComponent("planardefense")
        end
        target.components.planardefense:AddBonus(buff, buff._count_l)
    end,
    fn_end = function(buff, target)
        buff._count_l = 0
        BuffTalkOff(target, buff.prefab)
        if target.components.planardefense ~= nil then --buff结束，保留位面防御组件，希望不要有什么影响
            target.components.planardefense:RemoveBonus(buff, nil)
        end
    end,
    fn_server = FnServer_count3
})

--------------------------------------------------------------------------
--[[ 位面激进：提供位面伤害 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_planarattack",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*12, max = TIME_MAX, kind2 = 3, value2 = 8 }, --目前武器的位面攻击最高也就35
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets)
        if buff._count_l <= 0 then
            return
        end
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.planardamage == nil then
            target:AddComponent("planardamage")
        end
        target.components.planardamage:AddBonus(buff, buff._count_l)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets)
        if target.components.planardamage == nil then
            target:AddComponent("planardamage")
        end
        target.components.planardamage:AddBonus(buff, buff._count_l)
    end,
    fn_end = function(buff, target)
        buff._count_l = 0
        BuffTalkOff(target, buff.prefab)
        if target.components.planardamage ~= nil then --buff结束，保留位面伤害组件，希望不要有什么影响
            target.components.planardamage:RemoveBonus(buff, nil)
        end
    end,
    fn_server = FnServer_count3
})

--------------------------------------------------------------------------
--[[ 月光防御：减免属于月亮阵营的伤害 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_lunarresist",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*12, max = TIME_MAX, kind2 = 4, value2 = 0.9 }, --目前装备的月亮减伤普遍是0.75(减伤25%)
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets, true)
        if buff._count_l >= 1 then
            return
        end
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.damagetyperesist == nil then
            target:AddComponent("damagetyperesist")
        end
        target.components.damagetyperesist:AddResist("lunar_aligned", buff, buff._count_l)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets, true)
        CheckOppositeBuff(buff, target)
        if target.components.damagetyperesist == nil then
            target:AddComponent("damagetyperesist")
        end
        target.components.damagetyperesist:AddResist("lunar_aligned", buff, buff._count_l)
    end,
    fn_end = function(buff, target)
        buff._count_l = 0
        BuffTalkOff(target, buff.prefab)
        if target.components.damagetyperesist ~= nil then --buff结束，保留标签减伤组件，希望不要有什么影响
            target.components.damagetyperesist:RemoveResist("lunar_aligned", buff, nil)
        end
    end,
    fn_server = FnServer_count4
})

--------------------------------------------------------------------------
--[[ 影子防御：减免属于暗影阵营的伤害 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_shadowresist",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*12, max = TIME_MAX, kind2 = 4, value2 = 0.9 }, --目前装备的暗影减伤普遍是0.75(减伤25%)
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets, true)
        if buff._count_l >= 1 then
            return
        end
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.damagetyperesist == nil then
            target:AddComponent("damagetyperesist")
        end
        target.components.damagetyperesist:AddResist("shadow_aligned", buff, buff._count_l)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets, true)
        CheckOppositeBuff(buff, target)
        if target.components.damagetyperesist == nil then
            target:AddComponent("damagetyperesist")
        end
        target.components.damagetyperesist:AddResist("shadow_aligned", buff, buff._count_l)
    end,
    fn_end = function(buff, target)
        buff._count_l = 0
        BuffTalkOff(target, buff.prefab)
        if target.components.damagetyperesist ~= nil then --buff结束，保留标签减伤组件，希望不要有什么影响
            target.components.damagetyperesist:RemoveResist("shadow_aligned", buff, nil)
        end
    end,
    fn_server = FnServer_count4
})

--------------------------------------------------------------------------
--[[ 破影：增加对暗影生物的伤害 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_dissipateshadow",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*12, max = TIME_MAX, kind2 = 3, value2 = 1.1 }, --目前装备的暗影增伤普遍是1.1(增伤10%)
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets)
        if buff._count_l <= 1 then
            return
        end
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.damagetypebonus == nil then
            target:AddComponent("damagetypebonus")
        end
        target.components.damagetypebonus:AddBonus("shadow_aligned", buff, buff._count_l)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets)
        CheckOppositeBuff(buff, target)
        if target.components.damagetypebonus == nil then
            target:AddComponent("damagetypebonus")
        end
        target.components.damagetypebonus:AddBonus("shadow_aligned", buff, buff._count_l)
    end,
    fn_end = function(buff, target)
        buff._count_l = 0
        BuffTalkOff(target, buff.prefab)
        if target.components.damagetypebonus ~= nil then --buff结束，保留标签增伤组件，希望不要有什么影响
            target.components.damagetypebonus:RemoveBonus("shadow_aligned", buff, nil)
        end
    end,
    fn_server = FnServer_count3
})

--------------------------------------------------------------------------
--[[ 闭月：增加对月亮生物的伤害 ]]
--------------------------------------------------------------------------

MakeBuff({
    name = "buff_l_dimmoonlight",
    -- assets = nil, prefabs = nil, notimer = nil,
    sets = { value = TUNING.SEG_TIME*12, max = TIME_MAX, kind2 = 3, value2 = 1.1 }, --目前装备的月亮增伤普遍是1.1(增伤10%)
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets)
        if buff._count_l <= 1 then
            return
        end
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.damagetypebonus == nil then
            target:AddComponent("damagetypebonus")
        end
        target.components.damagetypebonus:AddBonus("lunar_aligned", buff, buff._count_l)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        UpdateCount2(buff, target, sets)
        CheckOppositeBuff(buff, target)
        if target.components.damagetypebonus == nil then
            target:AddComponent("damagetypebonus")
        end
        target.components.damagetypebonus:AddBonus("lunar_aligned", buff, buff._count_l)
    end,
    fn_end = function(buff, target)
        buff._count_l = 0
        BuffTalkOff(target, buff.prefab)
        if target.components.damagetypebonus ~= nil then --buff结束，保留标签增伤组件，希望不要有什么影响
            target.components.damagetypebonus:RemoveBonus("lunar_aligned", buff, nil)
        end
    end,
    fn_server = FnServer_count3
})

--------------------------------------------------------------------------
--[[ 温暖：自身体温不会低于5.1度 ]]
--------------------------------------------------------------------------

MakeBuff({ name = "buff_l_warm",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.temperature ~= nil then
            target.components.temperature.buff_l_warm = true
            --因为温度是每帧都在计算的，所以这里也不用设置温度了，就算此时过冷，下一帧就会恢复了
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        PondBuffTalkOn(target, buff.prefab, sets)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        if target.components.temperature ~= nil then
            target.components.temperature.buff_l_warm = nil
        end
    end
})

--------------------------------------------------------------------------
--[[ 凉爽：自身体温不会高于64.9度 ]]
--------------------------------------------------------------------------

MakeBuff({ name = "buff_l_cool",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.temperature ~= nil then
            target.components.temperature.buff_l_cool = true
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        CheckOppositeBuff(buff, target)
        PondBuffTalkOn(target, buff.prefab, sets)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        if target.components.temperature ~= nil then
            target.components.temperature.buff_l_cool = nil
        end
    end
})

--------------------------------------------------------------------------
--[[ 出浴：在非泡澡状态得到泉池好buff时，为好buff额外增加持续时间 ]]
--------------------------------------------------------------------------

pas.OnAddBuff_bath = function(self, name, prefab, data)
    if name == "buff_l_bath" then
        return data
    end
    if data == nil or (type(data) == "table" and not data.bath) then --只判定非泡澡期间得到的buff
        local dd = ZIP_SOAK_L.buffs[name]
        if dd ~= nil and not dd.isbad then --仅限泉池好buff
            local bath = self:GetDebuff("buff_l_bath")
            if bath ~= nil then
                local time = bath.components.timer:GetTimeLeft("buffover") or 0
                if time > 0 then
                    if data == nil then data = {} end
                    data.max = nil --出浴buff能解除时间限制
                    data.value = (data.value or 0) + time*20/3 -- =(time/6分钟) * 40分钟
                    self.inst.legiontag_nobufftalk = true
                    self:RemoveDebuff("buff_l_bath")
                    self.inst.legiontag_nobufftalk = nil
                end
            end
        end
    end
    return data
end

MakeBuff({ name = "buff_l_bath",
    sets = { value = TUNING.SEG_TIME, max = TUNING.SEG_TIME*12 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        target.legionfn_bathbuffbonus = pas.OnAddBuff_bath
    end,
    fn_end = function(buff, target)
        target.legionfn_bathbuffbonus = nil
        BuffTalkOff(target, buff.prefab)
    end
})

--------------------------------------------------------------------------
--[[ 柔软皮肤：受到的普通伤害增加40% ]]
--------------------------------------------------------------------------

MakeBuff({ name = "buff_l_softskin",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, buff.prefab, sets)
        if target.components.combat ~= nil then
            target.components.combat.externaldamagetakenmultipliers:SetModifier(buff, 1.4)
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        PondBuffTalkOn(target, buff.prefab, sets)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, buff.prefab)
        if target.components.combat ~= nil then
            target.components.combat.externaldamagetakenmultipliers:RemoveModifier(buff)
        end
    end
})

--------------------------------------------------------------------------
--[[ 晕乎乎：减少60%移速 ]]
--------------------------------------------------------------------------

MakeBuff({ name = "buff_l_dizzy",
    sets = { value = 15, max = TUNING.SEG_TIME*12 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        target:AddTag("groggy") --添加标签，走路会摇摇晃晃
        if target.components.locomotor ~= nil then
            target.components.locomotor:SetExternalSpeedMultiplier(target, "buff_l_dizzy", 0.4)
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        target:AddTag("groggy") --靠这个标签兼容性不好，但是没关系。这个只影响走路动画，移速降低的兼容性很好
    end,
    fn_end = function(buff, target)
        target:RemoveTag("groggy")
        if target.components.locomotor ~= nil then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "buff_l_dizzy")
        end
    end
})

--------------------------------------------------------------------------
--[[ 高效工作：砍、凿、锤效率提高100% ]]
--------------------------------------------------------------------------

MakeBuff({ name = "buff_l_workup",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, "buff_workeffectiveness", sets)
        if target.components.workmultiplier == nil then
            target:AddComponent("workmultiplier")
        end
        target.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, 2, buff)
        target.components.workmultiplier:AddMultiplier(ACTIONS.MINE, 2, buff)
        target.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, 2, buff)
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        PondBuffTalkOn(target, "buff_workeffectiveness", sets)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, "buff_workeffectiveness")
        if target.components.workmultiplier ~= nil then
            target.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP, buff)
            target.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE, buff)
            target.components.workmultiplier:RemoveMultiplier(ACTIONS.HAMMER, buff)
        end
    end
})

--------------------------------------------------------------------------
--[[ 有劲：增加20%普通攻击力 ]]
--------------------------------------------------------------------------

MakeBuff({ name = "buff_l_attack",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, "buff_attack", sets)
        if target.components.combat ~= nil then
            target.components.combat.externaldamagemultipliers:SetModifier(buff, 1.2)
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        PondBuffTalkOn(target, "buff_attack", sets)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, "buff_attack")
        if target.components.combat ~= nil then
            target.components.combat.externaldamagemultipliers:RemoveModifier(buff)
        end
    end
})

--------------------------------------------------------------------------
--[[ 健康抵抗力：每次受伤时，生命值的损失量减少33.4% ]]
--------------------------------------------------------------------------

MakeBuff({ name = "buff_l_defense",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        BuffTalkOn(target, "buff_playerabsorption", sets)
        if target.components.health ~= nil then
            target.components.health.externalabsorbmodifiers:SetModifier(buff, 0.334)
        end
    end,
    fn_again = function(buff, target, followsymbol, followoffset, sets)
        PondBuffTalkOn(target, "buff_playerabsorption", sets)
    end,
    fn_end = function(buff, target)
        BuffTalkOff(target, "buff_playerabsorption")
        if target.components.health ~= nil then
            target.components.health.externalabsorbmodifiers:RemoveModifier(buff)
        end
    end
})

--------------------------------------------------------------------------
--[[ 抗酸：自身不受酸雨伤害(防水装备还是会被腐蚀) ]]
--------------------------------------------------------------------------

MakeBuff({ name = "buff_l_antiacid",
    sets = { value = TIME_DEFAULT, max = TIME_MAX2 },
    fn_start = function(buff, target, followsymbol, followoffset, sets)
        target.legiontag_antiacid = true
        target:AddTag("acidrainimmune") --由于替换了官方buff，所以这个只是为了让其他模组能识别用的
    end,
    -- fn_again = function(buff, target, followsymbol, followoffset, sets)end,
    fn_end = function(buff, target)
        if target:HasTag("player") and target.components.talker ~= nil and
            (target.components.health == nil or not target.components.health:IsDead())
        then
            target.components.talker:Say(GetString(target, "ANNOUNCE_HEALINGSALVE_ACIDBUFF_DONE"))
        end
        target.legiontag_antiacid = nil
        target:RemoveTag("acidrainimmune")
    end
})

--------------------
--------------------

return unpack(prefs)
