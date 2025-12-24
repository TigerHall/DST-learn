local prefs = {}
local birdbrain = require("brains/siving_phoenixbrain")
local TOOLS_L = require("tools_legion")

--------------------------------------------------------------------------
--[[ 通用 ]]
--------------------------------------------------------------------------

local LineMap = {
    silk = 2,
    beardhair = 4,
    steelwool = 20,
    cattenball = 15
}

local BossSounds = {
    step = "dontstarve_DLC001/creatures/buzzard/hurt",
    death = "dontstarve_DLC001/creatures/buzzard/death",
    flyaway = "dontstarve_DLC001/creatures/buzzard/flyout",
    flap = "dontstarve_DLC001/creatures/buzzard/flap",
    atk = "dontstarve_DLC001/creatures/buzzard/attack",
    taunt = "dontstarve_DLC001/creatures/buzzard/taunt",
    caw = "dontstarve_DLC001/creatures/buzzard/squack",
    hurt = "dontstarve_DLC001/creatures/buzzard/hurt"
}

local DIST_MATE = 15 --离伴侣的最远距离
local DIST_REMOTE = 25 --最大活动范围
local DIST_ATK = 3.5 --普通攻击范围
local DIST_SPAWN = DIST_REMOTE + DIST_ATK --距离神木的最大距离
local DIST_FLAP = 8 --羽乱舞射程
local DIST_FEA_EXPLODE = 2.5 --精致子圭翎羽的爆炸半径
local DIST_ROOT_ATK = 1.5 --子圭突触的攻击半径

local TIME_BUFF_WARBLE = 6 --魔音绕耳debuff 持续时间
local TIME_FLAP = 40 --羽乱舞 冷却时间
local TIME_FEA_EXPLODE = 30 --精致子圭翎羽爆炸时间
local TIME_TAUNT = 50 --魔音绕梁 冷却时间 50
local TIME_CAW = 50 --花寄语 冷却时间 50

local ATK_NORMAL = 15 --啄击攻击力
local ATK_GRIEF = 10 --悲愤状态额外攻击力
local ATK_FEA = 45 --子圭翎羽攻击力
local ATK_FEA_REAL = 75 --精致子圭翎羽攻击力
local ATK_FEA_EXPLODE = 100 --精致子圭翎羽的爆炸伤害
local ATK_ROOT = 80 --子圭突触攻击力
local ATK_HUTR = 130 --反伤上限

local COUNT_FLAP = 3 --羽乱舞次数
local COUNT_FLAP_GRIEF = 4 --羽乱舞次数（悲愤状态）
local COUNT_FLAP_DT = 4 --每次羽乱舞的间隔攻击次数

local TIME_EYE_DT = 1.5
local TIME_EYE_DT_GRIEF = 0.6
local COUNT_EYE = 8 --8
local COUNT_EYE_GRIEF = 11 --11

local TAGS_CANT = TOOLS_L.TagsSiving({ "siving" })
local TAGS_CANT_BOSSFEA = TOOLS_L.TagsCombat1({ "siving" })
local TAGS_ONE_DESTROY = TOOLS_L.TagsWorkable2()

if CONFIGS_LEGION.PHOENIXBATTLEDIFFICULTY == 1 then
    DIST_FLAP = 7
    TIME_BUFF_WARBLE = 0
    TIME_FLAP = 45
    TIME_TAUNT = 70
    TIME_CAW = 70
    ATK_NORMAL = 10
    ATK_GRIEF = 8
    ATK_FEA = 30
    ATK_FEA_REAL = 60
    ATK_FEA_EXPLODE = 80
    ATK_ROOT = 50
    ATK_HUTR = 0
    COUNT_FLAP = 2
    COUNT_FLAP_GRIEF = 3
    COUNT_FLAP_DT = 5
    TIME_EYE_DT = 1.8
    TIME_EYE_DT_GRIEF = 0.9
    COUNT_EYE = 6
    COUNT_EYE_GRIEF = 9
elseif CONFIGS_LEGION.PHOENIXBATTLEDIFFICULTY == 3 then
    DIST_FLAP = 10
    TIME_BUFF_WARBLE = 10
    TIME_FLAP = 35
    TIME_TAUNT = 30
    TIME_CAW = 30
    ATK_NORMAL = 25
    ATK_GRIEF = 15
    ATK_FEA = 50
    ATK_FEA_REAL = 80
    ATK_FEA_EXPLODE = 150
    ATK_ROOT = 100
    ATK_HUTR = 80
    COUNT_FLAP = 4
    COUNT_FLAP_GRIEF = 5
    COUNT_FLAP_DT = 3
    TIME_EYE_DT = 1.3
    TIME_EYE_DT_GRIEF = 0.5
    COUNT_EYE = 10
    COUNT_EYE_GRIEF = 13
end

local function IsValid(one)
    return one:IsValid() and
        one.components.health ~= nil and not one.components.health:IsDead()
end
local function CheckMate(inst)
    if inst.mate ~= nil then
        if not IsValid(inst.mate) then
            inst.mate = nil
        end
    end
end
local function GetDamage(inst, target, basedamage)
    if inst.isgrief then
        basedamage = basedamage + ATK_GRIEF
    end
    if target:HasTag("player") then
        return basedamage
    else
        return basedamage*3
    end
end
local function GetDamage2(target, basedamage)
    if target:HasTag("player") then
        return basedamage
    else
        return basedamage*3
    end
end
local function SpawnFlower(inst, target)
    local flower = SpawnPrefab("siving_boss_flowerfx")
    if flower ~= nil then
        flower.Transform:SetPosition(target.Transform:GetWorldPosition())
        flower:fn_onBind(inst, target)
    end
end
local function SpawnRoot(bird, x, z, delaytime)
    if TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) then
        local root = SpawnPrefab("siving_boss_root")
        if root ~= nil then
            root.Transform:SetPosition(x, 0, z)
            root.OnTreeLive(root, bird.tree and bird.tree.treeState or 0)
            root.fn_onAttack(root, bird, delaytime or 0.3)
        end
    end
end
local function SetTreeBuff(inst, value)
    if value == 0 then
        return
    end
    local count = value + (inst.legion_numtreehalo or 0)
    if count <= 0 then --层数没了，说明要清除buff了
        inst.count_toolatk = 0
        if not inst.components.debuffable:HasDebuff("buff_l_treehalo") then --既然还没有buff，那就不用再加buff
            inst.legion_numtreehalo = nil
            return
        end
    end
    inst:AddDebuff("buff_l_treehalo", "buff_l_treehalo", { value = value })
end
local function SetBehaviorTree(inst, done)
    if done == "atk" then
        inst._count_atk = inst._count_atk + 1
        if inst._count_atk >= COUNT_FLAP_DT then --每啄击几下，进行一次羽乱舞
            inst.components.timer:StopTimer("flap")
            inst.sg.mem.to_flap = true --不用事件，回到idle时自己检查吧
        end
    elseif done == "flap" then
        inst._count_atk = 0
        inst.components.timer:StopTimer("flap")
        inst.components.timer:StartTimer("flap", TIME_FLAP)
    elseif done == "taunt" then
        inst._count_atk = 0
        inst.components.timer:StopTimer("taunt")
        inst.components.timer:StartTimer("taunt", TIME_TAUNT)
    elseif done == "caw" then
        inst._count_atk = 0
        inst.components.timer:StopTimer("caw")
        inst.components.timer:StartTimer("caw", TIME_CAW)
    end
end

local SOUNDBLOCKINGHATS = {
    earmuffshat = true, --兔耳罩
    slurtlehat = true, --背壳头盔
    slurper = true, --啜食者
    eyemaskhat = true, --眼面具
    nightcaphat = true, --睡帽
    lunarplanthat = true, --亮茄头盔
    voidclothhat = true, --虚空风帽
    hat_elepheetle = true --犀金胄甲
}
local function MagicWarble(inst) --魔音绕梁
    local sets
    local isgrief = inst.isgrief
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, DIST_REMOTE,
        { "_combat" }, TOOLS_L.TagsCombat1({ "siving", "noears_l" }) --"_inventory"
    )
    for _, v in ipairs(ents) do
        if
            v.entity:IsVisible() and v.legion_boxopener == nil and
            (v.components.locomotor ~= nil or v.components.inventory ~= nil) and
            (v.components.health == nil or not v.components.health:IsDead())
        then
            local inv = v.components.inventory
            local hasprotect = false
            if inv ~= nil then
                if isgrief then --悲愤状态：必定脱装备
                    for slot, item in pairs(inv.equipslots) do
                        if slot ~= EQUIPSLOTS.BEARD then --可不能把威尔逊的“胡子”给吼下来了
                            if SOUNDBLOCKINGHATS[item.prefab] or item.legiontag_ban_magicwarble then
                                hasprotect = true
                            else
                                inv:DropItem(item, true, true)
                            end
                        end
                    end
                else
                    for slot, item in pairs(inv.equipslots) do
                        if slot ~= EQUIPSLOTS.BEARD then
                            if SOUNDBLOCKINGHATS[item.prefab] or item.legiontag_ban_magicwarble then
                                hasprotect = true
                                break
                            end
                        end
                    end
                    if not hasprotect then
                        for slot, item in pairs(inv.equipslots) do
                            if slot ~= EQUIPSLOTS.BEARD then --可不能把威尔逊的“胡子”给吼下来了
                                inv:DropItem(item, true, true)
                            end
                        end
                    end
                end
            end
            if not hasprotect and TIME_BUFF_WARBLE > 0 then --后续的debuff
                if v:HasTag("player") then
                    sets = { value = TIME_BUFF_WARBLE, kind = 3, dogroggy = isgrief }
                else
                    sets = { value = TIME_BUFF_WARBLE, kind = 3, dogroggy = true } --非玩家对象必定会减速
                end
                v:AddDebuff("buff_l_magicwarble", "buff_l_magicwarble", sets)
            end
        end
    end
    SetBehaviorTree(inst, "taunt")
end
local function DiscerningPeck(inst, target) --啄击
    if target == nil then
        target = inst.components.combat.target
    end
    if target ~= nil then
        if inst.components.combat:CanHitTarget(target, nil) then
            --能命中时，才会开始破防改造
            TOOLS_L.UndefendedATK(inst, { target = target })
        end
        inst.components.combat:DoAttack(target)
    end
    SetBehaviorTree(inst, "atk")
end
local function ReleaseFlowers(inst) --花寄语
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, DIST_REMOTE, { "_combat", "_health" }, TAGS_CANT)
    for _, v in ipairs(ents) do
        if
            not v.hassivflower and --防止重复寄生
            v.entity:IsVisible() and
            v.components.health ~= nil and not v.components.health:IsDead() and
            not v:HasTag("PreventSivFlower") and
            (inst.isgrief or math.random() < 0.33)
        then
            SpawnFlower(inst, v)
        end
    end
    SetBehaviorTree(inst, "caw")
end
local function BeTreeEye(inst) --同目同心
    if inst:fn_canBeEye() then
        local eye = SpawnPrefab("siving_boss_eye")
        if eye ~= nil then
            eye:fn_onBind(inst.tree, inst)
            return true
        end
    end
    return false
end
local function Fn_validhit_bossfea(self, ent)
    return TOOLS_L.MaybeEnemy_me(self.owner, ent, false)
end
local function FeathersFlap(inst) --羽乱舞
    local x, y, z = inst.Transform:GetWorldPosition()
    local ctl = SpawnPrefab("siving_feather_ctl")
    local ctlcpt = ctl.components.sivfeatherctl
    ctlcpt.shootrange = DIST_FLAP
    -- ctlcpt.speed = 45
    if math.random() < 0.2 then
        ctlcpt.name_base = "siving_bossfea_real_block"
        ctlcpt.name_fly = "siving_bossfea_real"
    else
        ctlcpt.name_base = "siving_bossfea_fake_block"
        ctlcpt.name_fly = "siving_bossfea_fake"
    end
    ctlcpt.fn_validhit = Fn_validhit_bossfea
    ctlcpt.exclude_tags = TAGS_CANT_BOSSFEA
    ctlcpt:Throw(nil, inst, Vector3(TOOLS_L.GetCalculatedPos(x, 0, z, 2)), math.random(2, 3), nil, 3*FRAMES)
    SetBehaviorTree(inst, "flap")
end
local function IsTreeHaloCrusher(attacker, weapon)
    if attacker ~= nil then
        if attacker.prefab == "tornado" or attacker.treehalo_crusher_l then
            return true
        end
    end
    if weapon ~= nil then
        if weapon.treehalo_crusher_l then
            return true
        elseif weapon.components.tool ~= nil and weapon.components.tool:CanDoAction(ACTIONS.MINE) then
            return true
        end
    end
    return false
end

local function MakeBoss(data)
    table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

        inst.DynamicShadow:SetSize(2.5, 1.5)
        inst.Transform:SetScale(2.1, 2.1, 2.1)
        inst.Transform:SetFourFaced()

        MakeGhostPhysics(inst, 1500, 1.2) --鬼魂类物理，主要是为了不对子圭羽毛产生碰撞

        inst:AddTag("epic")
        -- inst:AddTag("noepicmusic")
        inst:AddTag("scarytoprey")
        inst:AddTag("hostile")
        inst:AddTag("largecreature")
        inst:AddTag("siving")
        inst:AddTag("siving_boss")
        -- inst:AddTag("flying")
        inst:AddTag("ignorewalkableplatformdrowning")

        --trader (from trader component) added to pristine state for optimization
        inst:AddTag("trader")

        inst.Light:Enable(true)
        inst.Light:SetRadius(2)
        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(.5)
        inst.Light:SetColour(15/255, 180/255, 132/255)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

        inst.AnimState:SetBank("buzzard")
        inst.AnimState:SetBuild(data.name)
        inst.AnimState:PlayAnimation("idle", true)

        inst:SetPrefabNameOverride("siving_phoenix")

        -- if data.fn_common ~= nil then
        --     data.fn_common(inst)
        -- end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst._count_atk = 0 --啄击次数
        inst._count_rock = 0 --喂食后需要掉落的子圭石数量
        TOOLS_L.AddEntValue(inst, "siv_blood_l_reducer", data.name, 1, 0.75) --窃血抵抗

        inst.sounds = BossSounds
        -- inst.legion_numtreehalo = 0
        inst.count_toolatk = 0 --被镐子类工具攻击次数
        inst.tree = nil
        inst.mate = nil --另一个伴侣
        inst.isgrief = false --是否处于悲愤状态
        inst.iseye = false --是否是木之眼状态
        inst.eyefx = nil --木之眼实体
        inst.fn_onGrief = function(inst, tree, dotaunt)
            inst.isgrief = true
            inst.AnimState:OverrideSymbol("buzzard_eye", data.name, "buzzard_angryeye")
            inst.Light:SetColour(255/255, 127/255, 82/255)
            inst.components.combat:SetDefaultDamage(ATK_NORMAL+ATK_GRIEF)
            TOOLS_L.AddEntValue(inst, "siv_blood_l_reducer", data.name, 1, 1)
            if tree and tree.rebirthed then --对于重生的玄鸟需要改一下掉落物
                inst.components.lootdropper:SetChanceLootTable(data.name.."_rebirth")
            end
            if dotaunt then
                inst:PushEvent("dotaunt")
            end
        end
        inst.fn_leave = function(inst)
            inst.tree = nil
            inst.mate = nil
            if inst.eyefx ~= nil and inst.eyefx:IsValid() then
                inst.eyefx:Remove()
            end
            if inst:IsAsleep() or inst.iseye then
                inst:Remove()
            else
                inst:PushEvent("dotakeoff")
            end
        end
        inst.fn_canBeEye = function(inst)
            if inst.tree ~= nil and inst.tree:IsValid() then
                if inst.tree.myEye == nil then
                    return true
                end
                if inst.tree.myEye == inst then --因为提前占用了，所以是自己很正常
                    return true
                end
                if not IsValid(inst.tree.myEye) then
                    inst.tree.myEye = nil
                    return true
                end
                if not inst.tree.myEye.iseye then --木眼对象没有木眼标志(猜测可能正在进入木眼状态)
                    if not inst.tree.myEye.sg:HasStateTag("flyaway") then --然而并没有在进入木眼状态
                        inst.tree.myEye = nil
                        return true
                    end
                end
            end
            return false
        end
        inst.fn_onFly = function(inst, params)
            if params ~= nil then
                if params.x and params.z then
                    inst.Transform:SetPosition(params.x, params.y or 30, params.z)
                    inst.sg:GoToState("glide")
                    return
                elseif params.beeye then --同目同心
                    if not inst:fn_beTreeEye() then
                        if inst.tree then
                            inst.tree.myEye = nil
                        end
                        local x, y, z = inst.Transform:GetWorldPosition()
                        inst.Transform:SetPosition(x, 30, z)
                        inst.sg:GoToState("glide")
                    end
                    return
                end
            end
            inst:Remove() --飞上天就消失啦
        end

        inst.COUNT_FLAP = COUNT_FLAP
        inst.COUNT_FLAP_GRIEF = COUNT_FLAP_GRIEF
        inst.DIST_FLAP = DIST_FLAP
        inst.DIST_REMOTE = DIST_REMOTE
        inst.DIST_MATE = DIST_MATE
        inst.DIST_ATK = DIST_ATK
        inst.DIST_SPAWN = DIST_SPAWN
        inst.TIME_FLAP = TIME_FLAP

        inst.fn_magicWarble = MagicWarble
        inst.fn_discerningPeck = DiscerningPeck
        inst.fn_releaseFlowers = ReleaseFlowers
        inst.fn_beTreeEye = BeTreeEye
        inst.fn_feathersFlap = FeathersFlap

        inst:AddComponent("locomotor") --locomotor must be constructed before the stategraph
        inst.components.locomotor.walkspeed = 4
        inst.components.locomotor.runspeed = 5
        inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        inst.components.locomotor:SetTriggersCreep(true)
        inst.components.locomotor.pathcaps = { ignorewalls = true, allowocean = true }

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(9000)
        inst.components.health.destroytime = 3

        inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(ATK_NORMAL)
        -- inst.components.combat.playerdamagepercent = 0.5
        inst.components.combat.hiteffectsymbol = "buzzard_body"
        inst.components.combat.battlecryenabled = false
        inst.components.combat:SetRange(DIST_ATK)
        inst.components.combat:SetAttackPeriod(3)
        inst.components.combat:SetRetargetFunction(1.5, function(inst)
            CheckMate(inst)
            return FindEntity(inst.tree or inst, DIST_SPAWN,
                    inst.mate == nil and function(guy) --对自己有仇恨就行
                        return (inst.isgrief or guy.components.combat.target == inst)
                            and inst.components.combat:CanTarget(guy)
                    end or function(guy) --对自己有仇恨并且不能和伴侣的目标相同
                        return (inst.isgrief or guy.components.combat.target == inst)
                            and inst.components.combat:CanTarget(guy)
                            and inst.mate.components.combat.target ~= guy
                    end,
                    { "_combat" },
                    TAGS_CANT_BOSSFEA
                )
        end)
        inst.components.combat:SetKeepTargetFunction(function(inst, target)
            CheckMate(inst)
            if inst.components.combat:CanTarget(target) then
                if inst.mate == nil then --只需要不跑出神木范围就行
                    return target:GetDistanceSqToPoint(
                            inst.components.knownlocations:GetLocation("tree") or
                            inst.components.knownlocations:GetLocation("spawnpoint")
                        ) < DIST_SPAWN^2
                else --不跑得离伴侣以及神木范围太远就行
                    return (
                            target:GetDistanceSqToPoint(
                                inst.components.knownlocations:GetLocation("tree") or
                                inst.components.knownlocations:GetLocation("spawnpoint")
                            ) < DIST_SPAWN^2
                        ) and (
                            inst.mate.iseye or
                            inst:GetDistanceSqToPoint(inst.mate:GetPosition()) < (DIST_MATE+DIST_ATK)^2
                        )
                end
            end
        end)
        inst.components.combat:SetHurtSound(BossSounds.hurt) --undo

        --攻击时针对于被攻击对象的额外伤害值
        inst.components.combat.bonusdamagefn = function(inst, target, damage, weapon)
            if not target:HasTag("player") then
                return inst.components.combat.defaultdamage*2 --加上已有的伤害，就是3倍伤害啦
            end
            return 0
        end

        inst:AddComponent("trader")
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(function(inst, item, giver)
            if inst.components.combat.target ~= nil or inst.sg:HasStateTag("busy") then
                return false
            end
            local loveditems = {
                myth_lotus_flower = 2, aip_veggie_sunflower = 2, genesis_flower_rose = 1,
                cutted_rosebush = 3, cutted_lilybush = 3, cutted_orchidbush = 3, cutted_nightrosebush = 3
            }
            if loveditems[item.prefab] ~= nil or item.legion_sivbirdfood ~= nil then
                --由于一次只给一个太慢了，这里手动从玩家身上全部拿下来
                local num = item.components.stackable ~= nil and item.components.stackable.stacksize or 1
                if num > 1 then
                    --拿走只剩1个，以供剩下的逻辑调用
                    local itemlast = item.components.stackable:Get(num - 1)
                    itemlast:Remove()
                end
                inst._count_rock = inst._count_rock + num*(loveditems[item.prefab] or item.legion_sivbirdfood)
                return true
            else
                return false
            end
        end)
        inst.components.trader.onaccept = function(inst, giver, item)
            inst:PushEvent("dofeeded")
        end
        inst.components.trader.onrefuse = function(inst, giver, item)
            inst:PushEvent("dorefuse")
        end

        inst:AddComponent("debuffable")
        inst.components.debuffable:SetFollowSymbol("buzzard_body", 0, -200, 0)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = function(inst)
            return inst.isgrief and "GRIEF" or "GENERIC"
        end

        inst:AddComponent("explosiveresist")

        inst:AddComponent("sleeper")
        inst.components.sleeper:SetResistance(4)
        inst.components.sleeper:SetSleepTest(function(inst)
            return false
        end)
        inst.components.sleeper:SetWakeTest(function(inst)
            return true
        end)

        inst:AddComponent("knownlocations")

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("flap", TIME_FLAP)
        inst.components.timer:StartTimer("taunt", TIME_TAUNT)
        inst.components.timer:StartTimer("caw", TIME_CAW)

        inst:AddComponent("lootdropper")

        MakeMediumFreezableCharacter(inst, "buzzard_body")

        inst:AddComponent("hauntable")

        inst:SetStateGraph("SGsiving_phoenix") --这个应该是指文件的名字，而不是数据的名字
        inst:SetBrain(birdbrain)

        inst:ListenForEvent("attacked", function(inst, data)
            local atker = data.attacker
            if atker and IsValid(atker) and not atker:HasTag("playerghost") then
                if ATK_HUTR > 0 and data.damage and atker.components.combat ~= nil then
                    --将单次伤害超过伤害上限的部分反弹给攻击者
                    if data.damage > ATK_HUTR then
                        --为了不受到盾反伤害，不设定玄鸟为攻击者
                        atker.components.combat:GetAttacked(nil, data.damage-ATK_HUTR)
                        local fx = SpawnPrefab("siving_boss_thorns_fx")
                        if fx ~= nil then
                            local x, y, z = inst.Transform:GetWorldPosition()
                            fx.Transform:SetPosition(x, y+1.5, z)
                        end
                        if not IsValid(atker) or atker:HasTag("playerghost") then --攻击者死亡，就结束
                            return
                        end
                    end

                    --受到远程攻击，神木会帮忙做出惩罚
                    if --远程武器分为两类，一类是有projectile组件、一类是weapon组件中有projectile属性
                        atker:HasTag("structure") or --针对建筑型攻击者
                        (data.weapon ~= nil and (
                            data.weapon.components.projectile ~= nil or
                            data.weapon:HasTag("rangedweapon") or
                            (data.weapon.components.weapon ~= nil and data.weapon.components.weapon.projectile ~= nil)
                        ))
                    then
                        local x, y, z = atker.Transform:GetWorldPosition()
                        SpawnRoot(inst, x, z)
                    end
                end

                CheckMate(inst)
                if inst.components.health:IsDead() then
                    if inst.mate ~= nil then --自己被打死，伴侣仇恨攻击者
                        inst.mate.components.combat:SetTarget(atker)
                    end
                    return
                end

                --现在是雌雄双打
                local lasttarget = inst.components.combat.target
                --谁离得近打谁
                if lasttarget ~= nil and lasttarget ~= atker and IsValid(lasttarget) then
                    if inst:GetDistanceSqToPoint(lasttarget:GetPosition())
                        > inst:GetDistanceSqToPoint(atker:GetPosition())
                    then
                        inst.components.combat:SetTarget(atker)
                    end
                else
                    inst.components.combat:SetTarget(atker)
                end
                lasttarget = inst.components.combat.target
                if lasttarget and inst.mate ~= nil and inst.mate.components.combat.target == nil then
                    inst.mate.components.combat:SetTarget(lasttarget)
                end
            end
            if inst.legion_numtreehalo ~= nil and inst.legion_numtreehalo > 0 and
                IsTreeHaloCrusher(atker, data.weapon)
            then
                inst.count_toolatk = inst.count_toolatk + 1
                if inst.count_toolatk >= 4 then --达到4次就减少一层buff
                    SetTreeBuff(inst, -1)
                    inst.count_toolatk = 0
                end
            end
        end)
        inst:ListenForEvent("timerdone", function(inst, data)
            if data.name == "flap" then
                inst:PushEvent("doflap")
            elseif data.name == "taunt" then
                inst:PushEvent("dotaunt")
            elseif data.name == "caw" then
                inst:PushEvent("docaw")
            end
        end)

        inst.OnPreLoad = function(inst, data) --防止保存时正在飞起或降落导致重载时位置不对
            local x, y, z = inst.Transform:GetWorldPosition()
            if y > 0 then
                inst.Transform:SetPosition(x, 0, z)
            end
        end
        inst.OnEntitySleep = function(inst)
            inst.components.combat:SetTarget(nil)
        end
        -- inst.OnRemoveEntity = function(inst)end

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, {
        Asset("ANIM", "anim/buzzard_basic.zip"), --官方秃鹫动画模板
        Asset("ANIM", "anim/"..data.name..".zip"),
    }, {
        "buff_l_magicwarble",
        "siving_boss_flowerfx",
        "siving_boss_eye",
        "siving_bossfea_real",
        "siving_bossfea_fake",
        "siving_boss_taunt_fx",
        "siving_boss_caw_fx",
        "siving_boss_root",
        "buff_l_treehalo"
    }))
end

------
------

local function OnThrown_bossfea(inst, owner, targetpos, attacker)
    inst.AnimState:PlayAnimation("shoot3", false)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe", nil, 0.2)
end
local function OnCollide_bossfea(inst, data)
    local boat_physics = data.other.components.boatphysics
    if boat_physics ~= nil then
        inst.components.workable:WorkedBy(data.other, 1)
    end
end
local function MakeBossWeapon(data)
    local scale = 1.2
    table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeProjectilePhysics(inst)

        inst.Transform:SetScale(scale, scale, scale)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

        inst:AddTag("sharp")
        inst:AddTag("weapon")
        inst:AddTag("rangedweapon")
        inst:AddTag("NOCLICK")
        -- inst:AddTag("moistureimmunity") --禁止潮湿：EntityScript:GetIsWet()

        if data.fn_common ~= nil then
            data.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.persists = false
        inst.isflyobj = true
        -- inst.feaidx = 1
        inst.fn_onthrown = OnThrown_bossfea

        inst:AddComponent("weapon")

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, data.assets, data.prefabs))
    table.insert(prefs, Prefab(data.name.."_block", function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:SetPhysicsRadiusOverride(0.15)
        MakeWaterObstaclePhysics(inst, 0.15, 2, 0.75)

        inst:AddTag("siv_boss_block") --用来被清场
        inst:AddTag("ignorewalkableplatforms")

        inst.Transform:SetScale(scale, scale, scale)
        inst.Transform:SetEightFaced()

        inst:SetPrefabNameOverride(data.name)

        MakeInventoryFloatable(inst, "small", 0.2, 0.5)

        if data.fn_common2 ~= nil then
            data.fn_common2(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        --加载水面特效
        inst:DoTaskInTime(POPULATING and math.random()*5*FRAMES or 0, function(inst)
            inst.components.floater:OnLandedServer()
        end)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(1)

        inst:AddComponent("savedrotation") --保存旋转角度的组件

        MakeHauntableWork(inst)

        inst:ListenForEvent("on_collide", OnCollide_bossfea) --被船撞时

        if data.fn_server2 ~= nil then
            data.fn_server2(inst)
        end

        return inst
    end, data.assets, nil))
end

--------------------------------------------------------------------------
--[[ 子圭玄鸟（雌） ]]
--------------------------------------------------------------------------

SetSharedLootTable('siving_foenix', {
    {'siving_rocks', 0.50},
    {'siving_rocks', 0.50},
    {'siving_rocks', 0.50},
    {'siving_derivant_item', 1.00},
    {'siving_derivant_item', 1.00},
    {'siving_mask_blueprint', 1.00}
})
SetSharedLootTable('siving_foenix_rebirth', {
    {'siving_rocks', 0.50},
    {'siving_rocks', 0.50},
    {'siving_rocks', 0.50},
    {'siving_derivant_item', 1.00},
    {'siving_derivant_item', 1.00},
    {'siving_feather_real_blueprint', 1.00}
})

MakeBoss({
    name = "siving_foenix",
    -- fn_common = function(inst)end,
    fn_server = function(inst)
        inst.components.lootdropper:SetChanceLootTable('siving_foenix')
    end
})

--------------------------------------------------------------------------
--[[ 子圭玄鸟（雄） ]]
--------------------------------------------------------------------------

SetSharedLootTable('siving_moenix', {
    {'siving_rocks', 0.50},
    {'siving_rocks', 0.50},
    {'siving_rocks', 0.50},
    {'siving_feather_fake', 1.00},
    {'siving_feather_fake', 1.00},
    {'siving_feather_fake', 1.00},
    {'siving_feather_fake', 1.00},
    {'siving_feather_fake', 0.50},
    {'siving_feather_fake', 0.50},
    {'siving_feather_fake', 0.50},
    {'siving_feather_fake', 0.50},
    {'siving_suit_blueprint', 1.00}
})
SetSharedLootTable('siving_moenix_rebirth', {
    {'siving_rocks', 0.50},
    {'siving_rocks', 0.50},
    {'siving_rocks', 0.50},
    {'siving_feather_fake', 1.00},
    {'siving_feather_fake', 1.00},
    {'siving_feather_fake', 1.00},
    {'siving_feather_fake', 1.00},
    {'siving_feather_fake', 0.50},
    {'siving_feather_fake', 0.50},
    {'siving_feather_fake', 0.50},
    {'siving_feather_fake', 0.50},
    {'siving_feather_real_blueprint', 1.00}
})

MakeBoss({
    name = "siving_moenix",
    -- fn_common = function(inst)end,
    fn_server = function(inst)
        inst.ismale = true
        inst.components.lootdropper:SetChanceLootTable('siving_moenix')
    end
})

--------------------------------------------------------------------------
--[[ 子圭石子 ]]
--------------------------------------------------------------------------

local TIME_EGG = 30 --孵化时间

local function SetEggState(inst, state)
    inst.state = state
    if state == 2 then
        inst.AnimState:OverrideSymbol("eggbase", "siving_egg", "egg2")
        inst.AnimState:PushAnimation("idle2", true)
    elseif state == 3 then
        inst.AnimState:OverrideSymbol("eggbase", "siving_egg", "egg3")
        inst.AnimState:PushAnimation("idle3", true)
    elseif state == 4 then
        inst.AnimState:OverrideSymbol("eggbase", "siving_egg", "egg4")
        inst.AnimState:PushAnimation("idle4", true)
    else
        inst.AnimState:ClearOverrideSymbol("eggbase")
        inst.AnimState:PushAnimation("idle1", true)
    end
end
local function OnTimerDone_egg(inst, data)
    if data.name == "state1" then
        SetEggState(inst, 2)
        inst.components.timer:StartTimer("state2", TIME_EGG*0.35)
        inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hatch_crack")
    elseif data.name == "state2" then
        SetEggState(inst, 3)
        inst.components.timer:StartTimer("state3", TIME_EGG*0.35)
        inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hatch_crack")
    elseif data.name == "state3" then
        SetEggState(inst, 4)
        inst.components.timer:StartTimer("birth", 2.5)
        inst.task_sound = inst:DoPeriodicTask(0.2, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hatch_crack")
        end, 0)
    elseif data.name == "birth" then
        if inst.tree == nil or not inst.tree:IsValid() then --生成一个非BOSS战的玄鸟
            local bird = SpawnPrefab(inst.ismale and "siving_moenix" or "siving_foenix")
            if bird ~= nil then
                bird.Transform:SetPosition(inst.Transform:GetWorldPosition())
                bird.components.knownlocations:RememberLocation("spawnpoint", inst:GetPosition(), false)
            end
        else --BOSS战的玄鸟由神木在管理
            inst.ishatched = true
        end
        if inst.task_sound ~= nil then
            inst.task_sound:Cancel()
            inst.task_sound = nil
        end
        local fx = SpawnPrefab("siving_egg_hatched_fx")
        if fx ~= nil then
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        inst:Remove()
    end
end
local function OnAttacked_egg(inst, data)
    if not inst.components.health:IsDead() then
        inst.AnimState:PlayAnimation("hit")
        SetEggState(inst, inst.state)
    end
end
local function OnDeath_egg(inst, data)
    inst:RemoveEventCallback("timerdone", OnTimerDone_egg)
    inst.components.lootdropper:DropLoot()
    inst.AnimState:PlayAnimation("break", false)
end
local function OnLoad_egg(inst, data)
    if inst.components.timer:TimerExists("state2") then
        inst.components.timer:StopTimer("state1")
        SetEggState(inst, 2)
    elseif inst.components.timer:TimerExists("state3") then
        inst.components.timer:StopTimer("state1")
        SetEggState(inst, 3)
    elseif inst.components.timer:TimerExists("birth") then
        inst.components.timer:StopTimer("state1")
        SetEggState(inst, 4)
    end
end
local function NoDebrisDmg_egg(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    return afflicter ~= nil and afflicter:HasTag("quakedebris")
end

table.insert(prefs, Prefab("siving_egg", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.4)

    inst:AddTag("hostile")
    inst:AddTag("siving")

    inst.AnimState:SetBank("siving_egg")
    inst.AnimState:SetBuild("siving_egg")
    inst.AnimState:PlayAnimation("idle1", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.ismale = false
    inst.ishatched = nil --是否正常孵化
    inst.tree = nil
    inst.state = 1

    inst.DIST_SPAWN = DIST_SPAWN

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(300)
    inst.components.health:SetInvincible(true)
    inst.components.health.redirect = NoDebrisDmg_egg

    inst:AddComponent("combat")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "siving_rocks", "siving_rocks", "siving_rocks",
        "siving_rocks", "siving_rocks", "siving_rocks" })

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("state1", TIME_EGG*0.3)

    inst:ListenForEvent("timerdone", OnTimerDone_egg)
    inst:ListenForEvent("attacked", OnAttacked_egg)
    inst:ListenForEvent("death", OnDeath_egg)

    inst.OnLoad = OnLoad_egg

    inst:DoTaskInTime(2, function(inst) --防止产生瞬间暴毙
        inst.components.health:SetInvincible(false)
    end)

    return inst
end, { Asset("ANIM", "anim/siving_egg.zip") }, {
    "siving_foenix",
    "siving_moenix",
    "siving_egg_hatched_fx"
}))

--------------------------------------------------------------------------
--[[ 子圭寄生花 ]]
--------------------------------------------------------------------------

local HEALTH_FLOWER = 480
local TIME_FLOWER = 11 --治疗玄鸟的延迟时间

local function SetFlowerState(inst, value, pushanim)
    local name = nil
    if value <= HEALTH_FLOWER*0.33 then
        if inst.state ~= 1 then
            inst.state = 1
            name = "idle1"
            pushanim = false --没有to_idle1这个动画
        end
    elseif value <= HEALTH_FLOWER*0.66 then
        if inst.state ~= 2 then
            inst.state = 2
            name = "idle2"
        end
    else
        if inst.state ~= 3 then
            inst.state = 3
            name = "idle3"
        end
    end
    if name ~= nil then
        if pushanim then
            inst.AnimState:PlayAnimation("to_"..name)
            inst.AnimState:PushAnimation(name, true)
        else
            inst.AnimState:PlayAnimation(name, true)
        end
    end
end
local function GiveLife(target, value)
    local health = target.components.health
    if health:IsHurt() then
        local need = health.maxhealth - health.currenthealth
        if need >= value then
            health:DoDelta(value)
            return 0
        else
            health:DoDelta(need)
            return value-need
        end
    end
    return value
end
local function StealLife_flower(inst)
    if IsValid(inst.target) and not inst.target:HasTag("playerghost") then
        local reducer = inst.target.siv_blood_l_reducer_v or 0
        inst.countTry = inst.countTry + 1
        if reducer < 1 then
            reducer = 1 - reducer
            inst.target.components.health:DoDelta(-4*reducer, true, "siving_boss_flower", false, inst, true)
            inst.countHealth = inst.countHealth + 40*reducer
        end

        --宿主还没死，并且也没有达到吸血上限，就更新自己的动画
        if not inst.target.components.health:IsDead() and not inst.target:HasTag("playerghost") and
            inst.countTry < 12 and inst.countHealth < HEALTH_FLOWER
        then
            SetFlowerState(inst, inst.countHealth, true)
            return
        end
    end
    inst.fn_onUnbind(inst.target)
end
local function Fn_onBind_flower(inst, bird, target)
    inst.tree = bird.tree
    inst.bird = bird
    inst.target = target
    target.hassivflower = true
    inst.entity:SetParent(target.entity)

    --获取能跟随的symbol
    local symbol = target.components.debuffable and target.components.debuffable.followsymbol or nil
    if symbol == nil or symbol == "" then
        if target.components.combat ~= nil then
            symbol = target.components.combat.hiteffectsymbol
        end
    end
    if symbol == nil or symbol == "" then
        if target.components.freezable ~= nil then
            for _, v in pairs(target.components.freezable.fxdata) do
                if v.follow ~= nil then
                    symbol = v.follow
                    break
                end
            end
        end
        if symbol == nil or symbol == "" then
            if target.components.burnable ~= nil then
                for _, v in pairs(target.components.burnable.fxdata) do
                    if v.follow ~= nil then
                        symbol = v.follow
                        break
                    end
                end
            end
        end
    end
    if symbol ~= nil then
        local ox, oy, oz = 0, 0, 0
        if target.components.debuffable ~= nil then
            local debuffable = target.components.debuffable
            ox = debuffable.followoffset.x
            oy = debuffable.followoffset.y
            oz = debuffable.followoffset.z
        end
        if oy == 0 then
            oy = -140
        end
        inst.Follower:FollowSymbol(target.GUID, symbol, ox, oy, oz)
    end

    inst:ListenForEvent("death", inst.fn_onUnbind, target)
    inst:ListenForEvent("onremove", inst.fn_onUnbind, target)

    if inst._task_re ~= nil then
        inst._task_re:Cancel()
        inst._task_re = nil
    end
    inst.task_bind = inst:DoPeriodicTask(2, StealLife_flower, 2)
end
local function OnAttacked_flower(inst, data)
    if not inst.components.health:IsDead() then
        inst.AnimState:PlayAnimation("hit"..tostring(inst.state))
        inst.AnimState:PushAnimation("idle"..tostring(inst.state), true)
    end
end
local function OnDeath_flower(inst, data)
    if inst._task_health ~= nil then
        inst._task_health:Cancel()
        inst._task_health = nil
    end
    inst.Light:Enable(false)
    inst.AnimState:ClearBloomEffectHandle()
    inst.AnimState:PlayAnimation("dead"..tostring(inst.state), false)
end
local function Init_flower(inst)
    if inst.tree ~= nil and inst.tree:IsValid() then
        local value = inst.components.health.currenthealth
        local valuelast = 0
        if inst.tree.bossBirds ~= nil then --优先直接给玄鸟加血(我嫌给神木再转给玄鸟的话太慢了)
            local female = inst.tree.bossBirds.female
            local male = inst.tree.bossBirds.male
            if female ~= nil and not IsValid(female) then
                female = nil
            end
            if male ~= nil and not IsValid(male) then
                male = nil
            end
            if female ~= nil or male ~= nil then
                if female ~= nil and male ~= nil then
                    value = value/2
                end
                if female ~= nil then
                    valuelast = valuelast + GiveLife(female, value)
                end
                if male ~= nil then
                    valuelast = valuelast + GiveLife(male, value)
                end
            else
                valuelast = value
            end
        else
            valuelast = value
        end

        if valuelast > 0 then --然后才是给神木增加生命计数器
            inst.tree.countHealth = inst.tree.countHealth + valuelast
        end
    elseif inst.bird ~= nil and IsValid(inst.bird) then
        GiveLife(inst.bird, inst.components.health.currenthealth)
    end

    local fx = SpawnPrefab("siving_boss_flower_fx")
    if fx ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        fx.Transform:SetPosition(x, 0, z)
    end

    inst._task_health = nil
    inst:Remove()
end

table.insert(prefs, Prefab("siving_boss_flowerfx", function() ------特效
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddFollower()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.AnimState:SetBank("siving_boss_flower")
    inst.AnimState:SetBuild("siving_boss_flower")
    inst.AnimState:PlayAnimation("idle1", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(3)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false
    inst.tree = nil
    inst.bird = nil
    inst.target = nil
    inst.countHealth = 0
    inst.countTry = 0
    inst.state = 1

    inst.fn_onUnbind = function(target) --落地
        if not inst:IsValid() then
            return
        end

        inst:RemoveEventCallback("death", inst.fn_onUnbind, target)
        inst:RemoveEventCallback("onremove", inst.fn_onUnbind, target)
        target.hassivflower = nil

        if inst.task_bind ~= nil then
            inst.task_bind:Cancel()
            inst.task_bind = nil
        end
        if inst.countHealth > 0 then
            local flower = SpawnPrefab("siving_boss_flower")
            if flower ~= nil then
                flower.tree = inst.tree
                flower.bird = inst.bird
                if inst.countHealth < HEALTH_FLOWER then
                    flower.components.health:SetCurrentHealth(inst.countHealth)
                end
                SetFlowerState(flower, inst.countHealth, false)
                flower.Transform:SetRotation(target.Transform:GetRotation())

                local x, y, z = target.Transform:GetWorldPosition()
                flower.Transform:SetPosition(x, 0.5, z)
            end
        end
        inst:Remove()
    end
    inst.fn_onBind = Fn_onBind_flower --寄生
    inst._task_re = inst:DoTaskInTime(1, inst.Remove)

    return inst
end, { Asset("ANIM", "anim/siving_boss_flower.zip") }, { "siving_boss_flower" }))
table.insert(prefs, Prefab("siving_boss_flower", function() ------实体
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst:AddTag("hostile")
    inst:AddTag("siving")
    inst:AddTag("soulless") --没有灵魂

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("siving_boss_flower")
    inst.AnimState:SetBuild("siving_boss_flower")
    inst.AnimState:PlayAnimation("idle3", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Light:Enable(true)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(15/255, 180/255, 132/255)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false
    inst.tree = nil
    inst.bird = nil
    inst.state = 3

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH_FLOWER)

    inst:AddComponent("combat")

    inst:ListenForEvent("attacked", OnAttacked_flower)
    inst:ListenForEvent("death", OnDeath_flower)

    inst._task_health = inst:DoTaskInTime(TIME_FLOWER, Init_flower)

    return inst
end, { Asset("ANIM", "anim/siving_boss_flower.zip") }, { "siving_boss_flower_fx" }))

--------------------------------------------------------------------------
--[[ 子圭之眼 ]]
--------------------------------------------------------------------------

local function UnbindBird(inst, landpos)
    inst.bird.iseye = false
    inst.bird.eyefx = nil
    if IsValid(inst.bird) then
        if landpos == nil then
            landpos = inst.bird.components.knownlocations:GetLocation("spawnpoint") or inst.tree:GetPosition()
        end
        inst.bird.Transform:SetPosition(landpos.x, 30, landpos.z)
        inst.bird:ReturnToScene()
        inst.bird.sg:GoToState("glide")
        inst.bird._count_atk = 0
        inst.bird.components.health:SetInvincible(false) --不再无敌
    end
end
local function EyeATK1(inst)
    if inst.task_eye2 ~= nil then
        return
    end
    inst.task_eye2 = inst:DoPeriodicTask(1.5, function(inst)
        if inst:IsAsleep() or inst.target == nil or not IsValid(inst.target) then
            return
        end
        local xx, yy, zz = inst.target.Transform:GetWorldPosition()
        local numpot = inst.bird.isgrief and 7 or 5
        local the = math.random()*2*PI
        local the_dt = 2*PI/numpot
        local emptykey = math.random(numpot)
        local x2, y2, z2
        for i = 1, numpot, 1 do
            if emptykey ~= i then
                x2, y2, z2 = TOOLS_L.GetCalculatedPos(xx, 0, zz, 3.5, the+the_dt*(i-1))
                SpawnRoot(inst.bird, x2, z2, 0.4)
            end
        end
    end, 0.5)
end
local function EyeAttack(inst, dt, countnow, countmax, x, z, counthalo)
    inst.task_eye = inst:DoTaskInTime(dt, function(inst)
        --确定攻击者
        local tar = nil
        if inst.bird.mate ~= nil and inst.bird.mate.components.combat.target ~= nil then
            tar = inst.bird.mate.components.combat.target
        else
            local ents = TheSim:FindEntities(x, 0, z, DIST_SPAWN, { "_combat", "_health" }, TAGS_CANT)
            for _, v in ipairs(ents) do
                if v.entity:IsVisible() and v.components.health ~= nil and not v.components.health:IsDead() then
                    if v:HasTag("player") then
                        tar = v
                        break
                    elseif tar == nil then
                        tar = v
                    end
                end
            end
        end

        --判定是否结束
        if countnow >= countmax then
            inst.task_eye = nil
            inst:fn_onUnbind(tar and tar:GetPosition() or nil)
            return
        end

        --预备施法
        inst.AnimState:PlayAnimation("spell", true)
        countnow = countnow + 1
        inst.target = tar

        --玩家逃避
        if tar == nil then
            counthalo = counthalo + 1
        end

        ------攻击方式1
        EyeATK1(inst)

        ------加护盾
        if countnow == 1 then --第一次循环，给伴侣加1层buff
            if inst.bird.mate ~= nil and IsValid(inst.bird.mate) then
                inst.task_eye = inst:DoTaskInTime(1, function(inst)
                    if inst.bird.mate ~= nil and IsValid(inst.bird.mate) then
                        SetTreeBuff(inst.bird.mate, 1)
                    end
                    if not inst.bird.isgrief then
                        inst.target = nil
                    end
                    inst.task_eye = nil
                    inst.AnimState:PlayAnimation("idle", true)
                    EyeAttack(inst, dt, countnow, countmax, x, z, counthalo)
                end)
                return
            end
        elseif countnow >= countmax and counthalo > 0 then ----最后一次循环，给伴侣和自己加buff
            inst.task_eye = inst:DoTaskInTime(1, function(inst)
                if IsValid(inst.bird) then
                    SetTreeBuff(inst.bird, counthalo)
                    counthalo = counthalo - 3
                end
                if counthalo > 0 and inst.bird.mate ~= nil and IsValid(inst.bird.mate) then
                    SetTreeBuff(inst.bird.mate, counthalo)
                end
                if not inst.bird.isgrief then
                    inst.target = nil
                end
                inst.task_eye = nil
                inst.AnimState:PlayAnimation("idle", true)
                EyeAttack(inst, dt, countnow, countmax, x, z, counthalo)
            end)
            return
        end

        ------攻击方式2
        local theta = nil
        local xx, yy, zz
        if tar ~= nil then
            xx, yy, zz = tar.Transform:GetWorldPosition()
            theta = math.atan2(z - zz, xx - x)
        else
            theta = math.random()*2*PI
        end
        --开始突袭！
        local num = 0
        local nummax = math.random(15, 19)
        local the = theta
        inst.task_eye = inst:DoPeriodicTask(0.12, function(inst)
            num = num + 1
            if not inst:IsAsleep() then
                if inst.bird.isgrief then
                    if num%2 == 1 then
                        the = theta + 2*DEGREES
                    else
                        the = theta - 2*DEGREES
                    end
                end
                xx, yy, zz = TOOLS_L.GetCalculatedPos(x, 0, z, 3+num*1.2, the)
                SpawnRoot(inst.bird, xx, zz, 0.3)
            end
            if num >= nummax then
                if inst.task_eye ~= nil then
                    inst.task_eye:Cancel()
                    inst.task_eye = nil
                end
                if not inst.bird.isgrief then
                    inst.target = nil
                end
                inst.AnimState:PlayAnimation("idle", true)
                EyeAttack(inst, dt, countnow, countmax, x, z, counthalo)
            end
        end, 1)
    end)
end
local function Fn_onUnbind_eye(inst, landpos)
    if inst.task_eye ~= nil then
        inst.task_eye:Cancel()
        inst.task_eye = nil
    end
    if inst.task_eye2 ~= nil then
        inst.task_eye2:Cancel()
        inst.task_eye2 = nil
    end

    if inst.tree:IsValid() then
        inst.tree.components.timer:StopTimer("eye")
        inst.tree.components.timer:StartTimer("eye", inst.tree.TIME_EYE)
        if inst:IsAsleep() then
            UnbindBird(inst, landpos)
            inst.tree.myEye = nil
            inst:Remove()
        else
            inst.AnimState:PlayAnimation("unbind")
            inst:ListenForEvent("animover", function(inst) --如果离玩家太远，动画会暂停
                UnbindBird(inst, landpos)
                inst.tree.myEye = nil
                inst:Remove()
            end)
        end
    else
        UnbindBird(inst, landpos)
        inst.tree.myEye = nil
        inst:Remove()
    end
end
local function Fn_onBind_eye(inst, tree, bird)
    if inst._task_re ~= nil then
        inst._task_re:Cancel()
        inst._task_re = nil
    end

    if bird.components.combat.target ~= nil then --把仇恨对象交给伴侣，不然仇恨就断了
        CheckMate(bird)
        if bird.mate ~= nil and bird.mate.components.combat.target == nil then
            bird.mate.components.combat:SetTarget(bird.components.combat.target)
        end
        bird.components.combat:SetTarget(nil)
    end

    bird:RemoveFromScene()
    bird.iseye = true
    bird.eyefx = inst
    tree.myEye = bird
    inst.tree = tree
    inst.bird = bird

    if bird.components.health ~= nil and not bird.components.health:IsDead() then
        bird.components.health:SetInvincible(true) --设置为无敌状态，以避免因持续性的伤害致死而产生一些奇怪问题
    end

    local x, y, z = tree.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, y, z)
    bird.Transform:SetPosition(x, 0, z)

    inst.entity:SetParent(tree.entity)
    inst.Follower:FollowSymbol(tree.GUID, "trunk", 0, -760, 0)

    inst.AnimState:PlayAnimation("bind")
    inst.AnimState:PushAnimation("idle", true)

    if bird.isgrief then
        inst.AnimState:OverrideSymbol("eye", "siving_boss_eye", "griefeye")
        EyeAttack(inst, TIME_EYE_DT_GRIEF, 0, COUNT_EYE_GRIEF, x, z, 0)
    else
        EyeAttack(inst, TIME_EYE_DT, 0, COUNT_EYE, x, z, 0)
    end
end

table.insert(prefs, Prefab("siving_boss_eye", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddFollower()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.AnimState:SetBank("siving_boss_eye")
    inst.AnimState:SetBuild("siving_boss_eye")
    inst.AnimState:PlayAnimation("bind")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetScale(1.3, 1.3)
    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false
    inst.tree = nil
    inst.bird = nil
    inst.target = nil

    inst.fn_onUnbind = Fn_onUnbind_eye --解除
    inst.fn_onBind = Fn_onBind_eye --化作
    inst._task_re = inst:DoTaskInTime(1, inst.Remove)

    return inst
end, { Asset("ANIM", "anim/siving_boss_eye.zip") }, { "siving_boss_root" }))

--------------------------------------------------------------------------
--[[ 子圭突触 ]]
--------------------------------------------------------------------------

local function SetClosedPhysics(inst)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end
local function SetOpenedPhysics(inst)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
end
local function OnTreeLive_root1(inst, state)
    inst.treeState = state
    if state == 2 then
        inst.AnimState:SetBuild("siving_boss_root2")
        inst.components.bloomer:PushBloom("activetree", "shaders/anim.ksh", 1)
        inst.Light:SetRadius(1.5)
        inst.Light:Enable(true)
    elseif state == 1 then
        inst.AnimState:SetBuild("siving_boss_root")
        inst.components.bloomer:PushBloom("activetree", "shaders/anim.ksh", 1)
        inst.Light:SetRadius(0.8)
        inst.Light:Enable(true)
    else
        inst.AnimState:SetBuild("siving_boss_root")
        inst.components.bloomer:PopBloom("activetree")
        inst.Light:Enable(false)
    end
end
local function OnTreeLive_root2(inst, state)
    inst.treeState = state
    if state == 2 then
        inst.components.bloomer:PushBloom("activetree", "shaders/anim.ksh", 1)
        inst.Light:SetRadius(1.5)
        inst.Light:Enable(true)
    elseif state == 1 then
        inst.components.bloomer:PushBloom("activetree", "shaders/anim.ksh", 1)
        inst.Light:SetRadius(0.8)
        inst.Light:Enable(true)
    else
        inst.components.bloomer:PopBloom("activetree")
        inst.Light:Enable(false)
    end
end
local function Fn_onAttack_root(inst, bird, delaytime)
    inst.AnimState:PlayAnimation("grow"..tostring(inst.fenceid))
    inst.AnimState:PushAnimation("idle"..tostring(inst.fenceid), false)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/atrium/gate_spike")
    inst.components.workable:SetWorkable(false)
    inst._task_atk = inst:DoTaskInTime(delaytime, function(inst)
        inst._task_atk = nil
        --攻击！破坏！
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, DIST_ROOT_ATK, nil, TAGS_CANT_BOSSFEA, TAGS_ONE_DESTROY)
        for _, v in ipairs(ents) do
            if v ~= inst and v.entity:IsVisible() then
                if v.components.combat ~= nil then
                    if v.components.health ~= nil and not v.components.health:IsDead() then
                        if v.components.combat:CanBeAttacked() then
                            v.components.combat:GetAttacked(inst, GetDamage(bird or inst, v, ATK_ROOT))
                        end
                    end
                elseif v.components.workable ~= nil then
                    if v.components.workable:CanBeWorked() then
                        v.components.workable:WorkedBy(inst, 3)
                    end
                end
            end
        end
        SetClosedPhysics(inst)
    end)
    inst._task_work = inst:DoTaskInTime(delaytime+3, function(inst)
        inst._task_work = nil
        inst.components.workable:SetWorkable(true)
    end)
end
local function FnClear_root(inst)
    if inst._task_atk ~= nil then
        inst._task_atk:Cancel()
        inst._task_atk = nil
    end
    if inst._task_work ~= nil then
        inst._task_work:Cancel()
        inst._task_work = nil
    end

    inst.persists = false
    if inst:IsAsleep() then
        inst:Remove()
        return
    end

    inst:AddTag("NOCLICK")
    inst.components.bloomer:PopBloom("activetree")
    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation("shrink"..tostring(inst.fenceid))
    inst:DoTaskInTime(0.6, inst.Remove) --我嫌动画末尾太拖了，提前结束！
    inst.SoundEmitter:PlaySound("dontstarve/common/together/atrium/retract")
end
local function OnFinished_root(inst, worker)
    SetOpenedPhysics(inst)
    inst.components.lootdropper:DropLoot()
    inst:fn_clear()
end
local function OnSave_root(inst, data)
    data.fenceid = inst.fenceid
end
local function OnLoad_root(inst, data)
    if data ~= nil and data.fenceid ~= nil then
        inst.fenceid = data.fenceid
    end
    inst.AnimState:PushAnimation("idle"..tostring(inst.fenceid), false)
    SetClosedPhysics(inst)
end

table.insert(prefs, Prefab("siving_boss_root", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst:AddTag("siv_boss_block") --用来被清场
    inst:AddTag("siving_derivant")
    inst:AddTag("trapdamage") --让骨甲能生效

    inst.AnimState:SetBank("atrium_fence")
    if CONFIGS_LEGION.SIVINGROOTTEX == 1 then
        inst.AnimState:SetBuild("siving_boss_root")
    else
        inst.AnimState:SetBuild("atrium_fence")
        inst.AnimState:SetMultColour(80/255, 147/255, 150/255, 1)
    end
    inst.AnimState:PlayAnimation("shrunk")
    -- inst.AnimState:SetScale(1.3, 1.3)

    inst.Light:Enable(false)
    inst.Light:SetRadius(1.5)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.6)
    inst.Light:SetColour(15/255, 180/255, 132/255)

    MakeObstaclePhysics(inst, 0.15)
    SetOpenedPhysics(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.fenceid = math.random(5)
    inst.treeState = 0

    if CONFIGS_LEGION.SIVINGROOTTEX == 1 then
        inst.OnTreeLive = OnTreeLive_root1
    else
        inst.OnTreeLive = OnTreeLive_root2
    end

    inst.fn_onAttack = Fn_onAttack_root
    inst.fn_clear = FnClear_root

    inst:AddComponent("inspectable")

    inst:AddComponent("bloomer")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnFinished_root)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddChanceLoot("siving_rocks", 0.001)

    MakeHauntableWork(inst)

    inst.OnSave = OnSave_root
    inst.OnLoad = OnLoad_root

    return inst
end, {
    Asset("ANIM", "anim/siving_boss_root.zip"),
    Asset("ANIM", "anim/siving_boss_root2.zip"),
    Asset("ANIM", "anim/atrium_fence.zip")
}, nil))

--------------------------------------------------------------------------
--[[ 精致子圭翎羽 ]]
--------------------------------------------------------------------------

local function AddWeaponLight(inst)
    inst.entity:AddLight()
    inst.Light:Enable(true)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(15/255, 180/255, 132/255)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
end
local function ExplodeFeather(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, DIST_FEA_EXPLODE, nil, TAGS_CANT_BOSSFEA, TAGS_ONE_DESTROY)
    for _, v in ipairs(ents) do
        if v ~= inst and v.entity:IsVisible() then
            if v.components.combat ~= nil then
                if v.components.health ~= nil and not v.components.health:IsDead() then
                    if v.components.combat:CanBeAttacked() then --Tip：范围性伤害还是加个判断！防止打到不该打的对象
                        v.components.combat:GetAttacked(inst, GetDamage2(v, ATK_FEA_EXPLODE), nil)
                    end
                end
            elseif v.components.workable ~= nil then
                if v.components.workable:CanBeWorked() then
                    if v:HasTag("siv_boss_block") then
                        v.explode_chain_l = true --连锁爆炸
                    end
                    v.components.workable:WorkedBy(inst, 3)
                end
            end
            v:PushEvent("explosion", { explosive = inst })
        end
    end

    --爆炸特效(声音也在里面)
    SpawnPrefab("explode_small_slurtle").Transform:SetPosition(x, y, z)

    inst.components.lootdropper:DropLoot()
    inst:Remove()
end
local function OnFinished_bossfea(inst, worker)
    if inst.task_explode ~= nil then
        inst.task_explode:Cancel()
        inst.task_explode = nil
    end
    ExplodeFeather(inst)
end
local function TryExplode_bossfea(inst)
    inst.task_explode = nil
    ExplodeFeather(inst)
end
local function FnClear_bossfea(inst)
    if inst.task_explode ~= nil then
        inst.task_explode:Cancel()
        inst.task_explode = nil
    end

    inst.persists = false
    if inst:IsAsleep() then
        inst:Remove()
        return
    end

    inst:AddTag("NOCLICK")
    inst.Light:Enable(false)
    inst.AnimState:ClearBloomEffectHandle()
    ErodeAway(inst)
end

MakeBossWeapon({
    name = "siving_bossfea_real",
    assets = {
        Asset("ANIM", "anim/siving_feather_real.zip")
    },
    prefabs = { "siving_bossfea_real_block" },
    fn_common = function(inst)
        AddWeaponLight(inst)
        inst.AnimState:SetBank("siving_feather_real")
        inst.AnimState:SetBuild("siving_feather_real")
    end,
    fn_server = function(inst)
        inst.components.weapon:SetDamage(ATK_FEA_REAL)
    end,
    fn_common2 = function(inst)
        AddWeaponLight(inst)
        inst.AnimState:SetBank("siving_feather_real")
        inst.AnimState:SetBuild("siving_feather_real")
        inst.AnimState:PlayAnimation("idle", false)
    end,
    fn_server2 = function(inst)
        inst.components.lootdropper:AddChanceLoot("siving_rocks", 0.1)
        inst.components.workable:SetOnFinishCallback(OnFinished_bossfea)

        inst.task_explode = inst:DoTaskInTime(TIME_FEA_EXPLODE, TryExplode_bossfea)
        inst.fn_clear = FnClear_bossfea
    end
})

--------------------------------------------------------------------------
--[[ 子圭翎羽 ]]
--------------------------------------------------------------------------

local function OnFinished_bossfea2(inst, worker)
    if inst.explode_chain_l then --被连锁爆炸
        ExplodeFeather(inst)
        return
    end
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end
local function FnClear_bossfea2(inst)
    inst.persists = false
    if inst:IsAsleep() then
        inst:Remove()
        return
    end

    inst:AddTag("NOCLICK")
    ErodeAway(inst)
end

MakeBossWeapon({
    name = "siving_bossfea_fake",
    assets = {
        Asset("ANIM", "anim/siving_feather_fake.zip")
    },
    prefabs = { "siving_bossfea_fake_block" },
    fn_common = function(inst)
        inst.AnimState:SetBank("siving_feather_fake")
        inst.AnimState:SetBuild("siving_feather_fake")
    end,
    fn_server = function(inst)
        inst.components.weapon:SetDamage(ATK_FEA)
    end,
    fn_common2 = function(inst)
        inst.AnimState:SetBank("siving_feather_fake")
        inst.AnimState:SetBuild("siving_feather_fake")
        inst.AnimState:PlayAnimation("idle", false)
    end,
    fn_server2 = function(inst)
        inst.components.lootdropper:AddChanceLoot("siving_rocks", 0.02)
        inst.components.workable:SetOnFinishCallback(OnFinished_bossfea2)

        inst.fn_clear = FnClear_bossfea2
    end
})

--------------------
--------------------

return unpack(prefs)
