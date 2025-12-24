-- 模组里使用变量时可以直接使用GLOBAL的属性变量了，非常方便
GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

local LOC = require("languages/loc")
local Text = require "widgets/text"
local Image = require "widgets/image"
require "stategraph"

-- 该文件是本模组设定的通用接口或补丁

-- 模式
TUNING.easymode2hm = GetModConfigData("enable easy mode")
TUNING.hardmode2hm = GetModConfigData("enable hard mode")
TUNING.util2hm = {}


-- 语言接口
local lang_id = LOC:GetLanguage()
TUNING.isCh2hm = lang_id == LANGUAGE.CHINESE_T or lang_id == LANGUAGE.CHINESE_S or lang_id == LANGUAGE.CHINESE_S_RAIL
if GetModConfigData("Language In Game") then TUNING.isCh2hm = GetModConfigData("Language In Game") == -1 end
AddComponentPostInit("talker", function(self)
    local Say = self.Say
    self.Say = function(self, script, ...)
        if script and type(script) == "string" and string.find(script, "only_used_by_") then script = "" end
        return Say(self, script, ...)
    end
end)

-- 时间接口
local phaseindexs = {day = 1, dusk = 2, night = 3}
local PHASE_NAMES = {"day", "dusk", "night"}
function CalcTimeOfDay2hm()
    if TheWorld and TheWorld.net and TheWorld.net.components.clock and TheWorld.net.components.clock.OnSave then
        local data = TheWorld.net.components.clock:OnSave()
        if data and data.totaltimeinphase and data.remainingtimeinphase and data.phase and data.segs then
            local time_of_day = data.totaltimeinphase - data.remainingtimeinphase
            for i = 1, phaseindexs[data.phase] - 1 do time_of_day = time_of_day + data.segs[PHASE_NAMES[i] or 1] * TUNING.SEG_TIME end
            return time_of_day
        end
    end
    return 0
end
function GetGameTime2hm()
    if TheWorld and TheWorld.state and TheWorld.state.cycles then
        return TheWorld.state.cycles * TUNING.TOTAL_DAY_TIME + CalcTimeOfDay2hm()
    else
        return 0
    end
end

-- 通用函数
function truefn() return true end
function falsefn() return false end
function nilfn() end
function emptytablefn() return {} end
function delayremove2hm(inst) inst:DoTaskInTime(0, inst.Remove) end
-- 兼容简单经济学，仍然掉落指定道具但该道具1秒后就删除
function nillootdropperSpawnLootPrefab(self, lootprefab, pt, linked_skinname, skin_id, userid)
    if lootprefab ~= nil then
        local loot = SpawnPrefab(lootprefab, linked_skinname, skin_id, userid)
        if loot ~= nil then
            if loot.components.inventoryitem ~= nil then
                if self.inst.components.inventoryitem ~= nil then
                    loot.components.inventoryitem:InheritMoisture(self.inst.components.inventoryitem:GetMoisture(), self.inst.components.inventoryitem:IsWet())
                else
                    loot.components.inventoryitem:InheritWorldWetnessAtTarget(self.inst)
                end
                if loot.components.stackable and loot.skinname == nil then loot.skinname = "none2hm" end
            end
            self:FlingItem(loot, pt)
            loot:Hide()
            loot.persists = false
            loot:DoTaskInTime(1, loot.Remove)
            return loot
        end
    end
end

modimport("common/superutils.lua")

-- 便于索引ID
TUNING.linkids2hm = {}
-- 玩家和世界数据
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
    inst.components.persistent2hm.data.id = inst.GUID
end)
-- 延迟调用掉落物减少API
local loots2hm = {}
function SetSharedLootTable2hm(key, value) loots2hm[key] = value end
AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim then return end
    for key, value in pairs(loots2hm) do
        if LootTables and LootTables[key] then
            local oldloot = LootTables[key]
            local newlootlist = {}
            for index, data in ipairs(value) do if data and data[1] then newlootlist[data[1]] = true end end
            for index, data in ipairs(oldloot) do if data and data[1] and not newlootlist[data[1]] then table.insert(value, data) end end
            LootTables[key] = value
        else
            SetSharedLootTable(key, value)
        end
    end
    loots2hm = nil
    if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
    inst.components.persistent2hm.data.id = "world" .. tostring(TheShard:GetShardId())


    TheSim:GetPersistentString("world_gen_level.data",
    function(load_success, str)
        if load_success == true then
            local success, savedata = RunInSandboxSafe(str)
            if success and string.len(str) > 0 and savedata ~= nil then
                -- print("load hardworldgen", tostring(savedata), savedata.level)
                TUNING.util2hm.world_level = savedata.level
            end
        else
            -- print ("Could not load world_gen_level.data")
            local hardworldgen = GetModConfigData("enable hard mode") and GetModConfigData("other_change") and GetModConfigData("worldgen")
            TUNING.util2hm.world_level = hardworldgen
            -- print("save hardworldgen", hardworldgen)
            TheSim:SetPersistentString("world_gen_level.data", DataDumper({level = hardworldgen}, nil, false), false)
        end
    end)
end)

-- 玩家角色的加载保存数据和其他单位有巨大区别
-- 饥荒会在服务器重载时生成全部玩家的角色,加载其数据再保存其数据,再把角色删除,此时角色的存档数据就被重写了一次
-- 然后等到玩家真正连接到服务器时,再次生成玩家的角色,用角色最新的存档数据加载角色
-- 这一步需要非常小心,加载保存处理不当就会丢失掉玩家角色的很多存档数据
function SetOnSave2hm(inst, fn)
    local OnSave = inst.onsave2hm
    inst.onsave2hm = OnSave and function(...)
        OnSave(...)
        fn(...)
    end or fn
end
function SetOnLoad2hm(inst, fn)
    local OnLoad = inst.onload2hm
    inst.onload2hm = OnLoad and function(...)
        OnLoad(...)
        fn(...)
    end or fn
end
-- 处理保存加载的函数
function SetOnPreLoad(inst, fn)
    local OnPreLoad = inst.OnPreLoad
    inst.OnPreLoad = OnPreLoad and function(...)
        OnPreLoad(...)
        fn(...)
    end or fn
end
function SetOnSave(inst, fn)
    local OnSave = inst.OnSave
    inst.OnSave = OnSave and function(...)
        OnSave(...)
        fn(...)
    end or fn
end
function SetOnLoad(inst, fn)
    local OnLoad = inst.OnLoad
    inst.OnLoad = OnLoad and function(...)
        OnLoad(...)
        fn(...)
    end or fn
end
function SetOnLoadPostPass(inst, fn)
    local OnLoadPostPass = inst.OnLoadPostPass
    inst.OnLoadPostPass = OnLoadPostPass and function(...)
        OnLoadPostPass(...)
        fn(...)
    end or fn
end
function SetNetwork(inst, valname, default, net_fn, eventname, eventname2, fn)
    inst[valname] = net_fn(inst.GUID, eventname or valname, eventname2)
    inst[valname]:set(default)
    if fn and not TheWorld.ismastersim then inst:ListenForEvent(eventname2 or eventname or valname, fn) end
end

function SetComponentSave(component, fn)
    local OnSave = component.OnSave
    component.OnSave = function(self)
        local data = OnSave and OnSave(self) or {}
        fn(self, data)
        return data
    end
end

function SetComponentLoad(component, fn)
    local OnLoad = component.OnLoad
    component.OnLoad = OnLoad and function(...)
        OnLoad(...)
        fn(...)
    end or fn
end

-- 多世界统一季节接口 SendModRPCToShard(GetShardModRPC("MOD_HARDMODE", "ms_setseason_update"), nil, season)
AddShardModRPCHandler("MOD_HARDMODE", "ms_setseason_update", function(shard_id, season) TheWorld:PushEvent("ms_setseason", season) end)

function MakeUnlimitStackSize(inst)
    -- inst:AddTag("maxstacksize2hm")
    -- if inst.replica and inst.replica.stackable then processstackablereplica(inst.replica.stackable) end
    if not TheWorld.ismastersim then return end
    -- inst:ListenForEvent("stacksizechange", stack_size_changed)
    -- if inst.components.stackable then inst.components.stackable.maxsize = maxsize end
    if inst.components.stackable and inst.components.inventoryitem and inst.components.inventoryitem.canonlygoinpocket then
        inst.components.stackable:SetIgnoreMaxSize(true)
        inst.components.stackable.SetIgnoreMaxSize = nilfn
    end
end

-- 道具的格子增加特殊字符或背景 itemtilefn2hm
local function refreshitemtile(self)
    if self.item and self.item.itemtilefn2hm then
        local dirty, text, bgaltas, bgtex, mainatlas, maintex = self.item.itemtilefn2hm(self.item, self)
        self.refreshitemtile2hm = refreshitemtile
        if dirty and not self.dirty2hm then
            self.dirty2hm = true
            self.inst:ListenForEvent(dirty, function(invitem) refreshitemtile(self) end, self.item)
        end
        if text then
            if not self.text2hm then
                self.text2hm = self:AddChild(Text(NUMBERFONT, 42))
                if not self.quantity then
                    self.text2hm:SetPosition(-25, 16, 0)
                elseif not self.percent then
                    self.text2hm:SetPosition(25, -17, 0)
                end
            end
            self.text2hm:SetString(tostring(text))
        elseif self.text2hm then
            self.text2hm = self.text2hm:Kill()
        end
        if bgaltas and bgtex then
            if not self.bg2hm then
                self.bg2hm = self:AddChild(Image(bgaltas, bgtex))
                self.bg2hm:SetScale(0.65, 0.65, 0.65)
                self.bg2hm:SetPosition(-18, 18, 0)
                self.bg2hm:SetClickable(false)
                self.bg2hm:MoveToFront()
            else
                self.bg2hm:SetTexture(bgaltas, bgtex)
            end
        elseif self.bg2hm then
            self.bg2hm = self.bg2hm:Kill()
        end
        if mainatlas and maintex and self.image then
            self.image:SetTexture(mainatlas, maintex)
            if not self.imagechange2hm then
                self.imagechange2hm = true
                self.inst:ListenForEvent("imagechange", function(invitem) refreshitemtile(self) end, self.item)
            end
        end
    else
        if self.text2hm then self.text2hm = self.text2hm:Kill() end
        if self.bg2hm then self.bg2hm = self.bg2hm:Kill() end
    end
end
AddClassPostConstruct("widgets/itemtile", refreshitemtile)

-- 道具通用动作,每个模组只能有一个,所以用表格统一管理,目前仅有制图和修理和打扫动作
TUNING.USEITEMFNS2HM = {}
TUNING.EQUIPPEDFNS2HM = {}
TUNING.INVENTORYFNS2HM = {}
AddComponentAction("USEITEM", "inventoryitem",
                   function(inst, doer, target, actions) for _, fn in ipairs(TUNING.USEITEMFNS2HM) do fn(inst, doer, target, actions) end end)
AddComponentAction("EQUIPPED", "equippable",
                   function(inst, doer, target, actions, right) for _, fn in ipairs(TUNING.EQUIPPEDFNS2HM) do fn(inst, doer, target, actions, right) end end)
AddComponentAction("INVENTORY", "inventoryitem", function(inst, doer, actions) for _, fn in ipairs(TUNING.INVENTORYFNS2HM) do fn(inst, doer, actions) end end)

-- 道具修理动作,需要有组件repairable2hm
local repairaction = Action({mount_valid = true, encumbered_valid = true, priority = 3})
repairaction.id = "REPAIR2HM"
repairaction.strfn = function(act) return act.target ~= nil and act.target.repairtext2hm or nil end
repairaction.fn = function(act)
    if act.target and act.target.components.repairable2hm then 
        local result = act.target.components.repairable2hm:Repair(act.doer, act.invobject)
        if result then return true end 
    end
end
AddAction(repairaction)
local function checkrapairaction(inst, doer, target, actions)
    if target and target.repairmaterials2hm then
        if inst and target.repairmaterials2hm[inst.prefab] then
            table.insert(actions, ACTIONS.REPAIR2HM)
        end
    end
end
table.insert(TUNING.USEITEMFNS2HM, checkrapairaction)
table.insert(TUNING.EQUIPPEDFNS2HM, checkrapairaction)
STRINGS.ACTIONS.REPAIR2HM = {}
STRINGS.ACTIONS.REPAIR2HM.GENERIC = STRINGS.ACTIONS.REPAIR.GENERIC
STRINGS.ACTIONS.REPAIR2HM.ADDFUEL = STRINGS.ACTIONS.ADDFUEL
STRINGS.ACTIONS.REPAIR2HM.UPGRADE = STRINGS.ACTIONS.UPGRADE.GENERIC
STRINGS.ACTIONS.REPAIR2HM.PURIFY = TUNING.isCh2hm and "净化" or "purify"
STRINGS.ACTIONS.REPAIR2HM = STRINGS.ACTIONS.REPAIR
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.REPAIR2HM, function(inst, action)
    return action.target:HasTag("fastrepair2hm") and "doshortaction" or "dolongaction"
end))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.REPAIR2HM, function(inst, action)
    return action.target:HasTag("fastrepair2hm") and "doshortaction" or "dolongaction"
end))

-- 范版动作,需要有组件action2hm
local action2hm = Action({rmb = true, priority = 1})
-- SCENE        using an object in the world
-- USEITEM        using an inventory item on an object in the world
-- POINT        using an inventory item on a point in the world
-- EQUIPPED        using an equiped item on yourself or a target object in the world
-- INVENTORY    using an inventory item
action2hm.id = "ACTION2HM"
action2hm.priority = 1
action2hm.strfn = function(act)
    return act.invobject and (act.invobject.actiontext2hm or string.upper(act.invobject.prefab)) or
               (act.target and (act.target.actiontext2hm or string.upper(act.target.prefab)))
end
action2hm.fn = function(act)
    if act.invobject and act.invobject.components.action2hm then
        return act.invobject.components.action2hm.actionfn(act.invobject, act.doer, act.target, act.pos, act)
    elseif act.target and act.target.components.action2hm then
        return act.target.components.action2hm.actionfn(act.invobject, act.doer, act.target, act.pos, act)
    end
end
local function resetactionconf(inst, doer, actions, right, target, pos) action2hm.distance = inst.action2hmdistance end
AddAction(action2hm)
-- 该单位可被直接动作,该箱子可打开
AddComponentAction("SCENE", "action2hm", function(inst, doer, actions, right)
    if inst.straightactioncondition2hm and inst.straightactioncondition2hm(inst, doer, actions, right) then
        resetactionconf(inst, doer, actions, right)
        table.insert(actions, ACTIONS.ACTION2HM)
    end
end)
-- 该道具可被直接动作,该书可读
AddComponentAction("INVENTORY", "action2hm", function(inst, doer, actions, right)
    if inst.itemstraightactioncondition2hm and inst.itemstraightactioncondition2hm(inst, doer, actions, right) then
        resetactionconf(inst, doer, actions, right)
        table.insert(actions, ACTIONS.ACTION2HM)
    end
end)
-- 该道具可用来动作其他单位或道具,修理
AddComponentAction("USEITEM", "action2hm", function(inst, doer, target, actions, right)
    if inst.actionothercondition2hm and inst.actionothercondition2hm(inst, doer, actions, right, target) then
        resetactionconf(inst, doer, actions, right, target)
        table.insert(actions, ACTIONS.ACTION2HM)
    end
end)
-- 该道具可用来动作地面,种植
AddComponentAction("POINT", "action2hm", function(inst, doer, pos, actions, right, target)
    if inst.actionpointcondition2hm and inst.actionpointcondition2hm(inst, doer, actions, right, target, pos) then
        resetactionconf(inst, doer, actions, right, target, pos)
        table.insert(actions, ACTIONS.ACTION2HM)
    end
end)
-- 该装备道具可用来动作其他单位或道具,武器攻击敌人
AddComponentAction("EQUIPPED", "action2hm", function(inst, doer, target, actions, right)
    if inst.equipactionothercondition2hm and inst.equipactionothercondition2hm(inst, doer, actions, right, target) then
        resetactionconf(inst, doer, actions, right, target)
        table.insert(actions, ACTIONS.ACTION2HM)
    end
end)
STRINGS.ACTIONS.ACTION2HM = {GENERIC = "Action"}
AddStategraphActionHandler("wilson",
                           ActionHandler(ACTIONS.ACTION2HM, function(inst, action) return action.target and action.target.actionstate2hm or "dolongaction" end))
AddStategraphActionHandler("wilson_client",
                           ActionHandler(ACTIONS.ACTION2HM, function(inst, action) return action.target and action.target.actionstate2hm or "dolongaction" end))

-- 模组动态加载，主要用来识别模组UI的widet定义文件
function isModuleAvailable(name)
    if package.loaded[name] then
        return true
    else
        for _, searcher in ipairs(package.searchers or package.loaders) do
            local loader = searcher(name)
            if type(loader) == "function" then
                package.preload[name] = loader
                return true
            end
        end
        return false
    end
end

-- 显血模组补丁之坐骑显血;很奇怪为什么坐骑可以显示血量但其他脱离场景的单位却显示不了
local hasSimpleHealthBar
function ForceShowHealthBar2hm(inst, parent)
    if hasSimpleHealthBar and inst and inst:IsValid() and inst.components.health then
        if inst.dychealthbar and inst.dychealthbar:IsValid() then
            inst.dychealthbar:DYCHBSetTimer(0x0)
        else
            local healthbar = inst:SpawnChild("dyc_healthbar")
            if healthbar == nil then return end
            inst.dychealthbar = healthbar
            healthbar.dychbowner = inst
            healthbar:AddTag("ignoreinlimbo2hm")
            healthbar.dycHbIgnoreFirstDoDelta = true
            if healthbar.dychp_net then
                healthbar.dychp_net:set_local(0x0)
                healthbar.dychp_net:set(inst.components.health.currenthealth)
            end
            if healthbar.dychpmax_net then
                healthbar.dychpmax_net:set_local(0x0)
                healthbar.dychpmax_net:set(inst.components.health.maxhealth)
            end
            if healthbar.InitHB then healthbar:InitHB() end
            if healthbar.dychbtext and healthbar.dychbtext:IsValid() then healthbar.dychbtext:AddTag("ignoreinlimbo2hm") end
        end
    end
end
local function onrideableattacked(inst)
    if hasSimpleHealthBar and inst.components.health and inst.components.rideable and inst.components.rideable:IsBeingRidden() then
        ForceShowHealthBar2hm(inst)
    end
end
AddComponentPostInit("rideable", function(self) if hasSimpleHealthBar then self.inst:ListenForEvent("attacked", onrideableattacked) end end)
local function processinlimbo(inst)
    if inst.dychbtask and inst.dychbtask.fn then
        local fn = inst.dychbtask.fn
        inst.dychbtask.fn = function(inst)
            local ignoreinlimbo2hm
            if inst.dychbowner and inst.dychbowner:IsValid() and inst:HasTag("ignoreinlimbo2hm") then
                if inst.dychbowner.inlimbo then
                    ignoreinlimbo2hm = true
                    inst.dychbowner.inlimbo = false
                    if TheWorld.ismastersim and not inst.initinlimbo2hm then inst.initinlimbo2hm = true end
                elseif inst.initinlimbo2hm and TheWorld.ismastersim then
                    inst:Remove()
                    inst.dychbowner.dychealthbar = nil
                    inst.dychbowner:DoTaskInTime(0, ForceShowHealthBar2hm)
                    return
                end
            end
            fn(inst)
            if ignoreinlimbo2hm and inst.dychbowner then inst.dychbowner.inlimbo = true end
        end
    end
end
AddPrefabPostInit("dyc_healthbar", processinlimbo)
AddPrefabPostInit("world", function()
    if not TheWorld.ismastersim then return end
    local dychealthbar = SpawnPrefab("dyc_healthbar")
    if dychealthbar then
        hasSimpleHealthBar = true
        dychealthbar:Remove()
    end
end)

-- 新加信号监听攻击即将触发的事件以及支持闪避
AddComponentPostInit("combat", function(self)
    local GetAttacked = self.GetAttacked
    self.GetAttacked = function(self, attacker, damage, weapon, stimuli, spdamage, ...)
        -- 无效单位不可被攻击了
        if self.inst and not self.inst:IsValid() then return end
        -- 黑暗攻击无法被闪避
        if self.inst.components.health and not self.inst.components.health:IsDead() and stimuli ~= "darkness" then
            -- 无法对自己发动攻击了
            if TUNING.avoidselfdmg2hm and attacker == self.inst and weapon == nil and attacker:HasTag("player") then damage = 0 end
            -- 即将受击信号，以做各类闪避处理
            self.inst:PushEvent("getattacked2hm", {attacker = attacker, damage = damage, weapon = weapon, stimuli = stimuli, spdamage = spdamage})
            -- 困难模式怪物无来源受伤且并无仇恨，则强行对最近玩家仇恨
            if TUNING.nosrctarget2hm and (attacker == nil or attacker.components.combat == nil) and self.inst:HasTag("hostile") and self.inst.components.combat and
                self.inst.components.combat.target == nil then
                local player = FindClosestPlayerToInst(self.inst, 36, true)
                if player ~= nil and not (self.inst.components.follower and self.inst.components.follower.leader == player) then
                    self.inst.components.combat:SuggestTarget(player)
                end
            end
            -- 闪避实现
            if self.inst.oncemiss2hm or self.inst.allmiss2hm then
                if self.inst.oncemiss2hm then self.inst.oncemiss2hm = nil end
                if self.inst:HasTag("player") then SpawnPrefab("grounddefendfx2hm").entity:SetParent(self.inst.entity) end
                return
            end
        end
        return GetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
    end


end)

-- 仇恨转移机制
AddComponentPostInit("combat", function(Combat)
    if not TUNING.nosrctarget2hm then return end    -- 跟随无端仇恨开启

    local inst = Combat.inst
    inst:ListenForEvent("droppedtarget", function(inst, data)
        if data.target and data.target.components.follower then
            if data.target:HasTag("swc2hm") then return end     -- 仇恨对象是随从的影子时不用转移
            local leader = data.target.components.follower:GetLeader()
            if leader and leader:IsValid() and Combat:CanTarget(leader) then
                Combat:SetTarget(leader)
            end
        end
    end)
end)

-- 限制该单位只能被玩家攻击
local function processcombatreplica(self)
    if not self.onlyplayertarget2hm then
        self.onlyplayertarget2hm = true
        local CanBeAttacked = self.CanBeAttacked
        self.CanBeAttacked = function(self, attacker, ...) return attacker and attacker:HasTag("player") and CanBeAttacked(self, attacker, ...) end
    end
end
AddClassPostConstruct("components/combat_replica", function(self)
    if self and self.inst and self.inst:IsValid() and self.inst:HasTag("onlyplayertarget2hm") then processcombatreplica(self) end
end)
function MakeOnlyPlayerTarget(inst)
    inst:AddTag("onlyplayertarget2hm")
    if inst.replica and inst.replica.combat then processcombatreplica(inst.replica.combat) end
end

-- 怪物召唤接口
function NoHoles2hm(pt) return not TheWorld.Map:IsPointNearHole(pt) end
local function GetSpawnPoint(pt, dist, onocean)
    if TheWorld.has_ocean and onocean ~= false then
        local offset = FindValidPositionByFan(math.random() * 2 * PI, dist or 30, 12, truefn)
        if offset ~= nil then
            offset.x = offset.x + pt.x
            offset.z = offset.z + pt.z
            return offset
        end
    end
    if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then pt = FindNearbyLand(pt, 1) or pt end
    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, dist or 30, 12, true, true, NoHoles2hm)
    if offset ~= nil then
        offset.x = offset.x + pt.x
        offset.z = offset.z + pt.z
        return offset
    end
end
function SpawnMonster2hm(player, prefab, dist, onocean)
    local pt = player:GetPosition()
    local spawn_pt = GetSpawnPoint(pt, dist, onocean) or pt
    if spawn_pt ~= nil then
        local monster = SpawnPrefab(prefab)
        if monster then
            monster.Physics:Teleport(spawn_pt:Get())
            monster:FacePoint(pt)
            -- monster.spawnedforplayer = player
            if monster.components.spawnfader then monster.components.spawnfader:FadeIn() end
            if monster.components.combat and player:HasTag("player") then monster.components.combat:SuggestTarget(player) end
        end
        return monster
    end
end

-- 范围内生成黑雾
function CreateMiasma2hm(inst, initial)
    local miasmamanager = TheWorld.components.miasmamanager
    if miasmamanager then
        local x, y, z = inst.Transform:GetWorldPosition()
        for i = 1, 3, 1 do
            if initial then
                miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z - TILE_SCALE)
                miasmamanager:CreateMiasmaAtPoint(x, 0, z - TILE_SCALE)
                miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z - TILE_SCALE)
                miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z)
                miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z)
                miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z + TILE_SCALE)
                miasmamanager:CreateMiasmaAtPoint(x, 0, z + TILE_SCALE)
                miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z + TILE_SCALE)
            else
                local theta = math.random() * PI2
                local ox, oz = TILE_SCALE * math.cos(theta), TILE_SCALE * math.sin(theta)
                miasmamanager:CreateMiasmaAtPoint(x + ox, 0, z + oz)
            end
        end
    end
end

-- 强制卸下武器
function ForceUnequipWeapon2hm(inst, testfn)
    if inst.components.inventoryitem and inst.components.inventoryitem.owner then
        local owner = inst.components.inventoryitem.owner
        if owner and owner:IsValid() and owner.components.inventory and (testfn == nil or testfn(owner)) then
            if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
                local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
                if item ~= nil then owner.components.inventory:GiveItem(item, nil, owner:GetPosition()) end
            end
        end
    end
end

-- 检测攻击目标
function TestCombatTarget2hm(doer, target, dist)
    return target ~= doer and target:IsValid() and not target:IsInLimbo() and target.components.combat and target.components.health and
               not target.components.health:IsDead() and doer:IsNear(target, dist) and doer.components.combat:CanTarget(target) and
               not doer.components.combat:IsAlly(target)
end

-- 取出某个函数里的局部变量
function getupvalue2hm(func, name, step)
    step = step or 0
    if step > 5 then
        return nil, false
    end
    local i = 1
    while true do
        local n, v = debug.getupvalue(func, i)
        if not n then break end
        if type(v) == "function" then
            local r1, r2 = getupvalue2hm(v, name, step + 1)
            if r1 then
                return r1, r2
            end
        end
        if n == name then return v, true end
        i = i + 1
    end
    return nil, false
end

-- 设置某个函数里的局部变量
function setupvalue2hm(func, name, value, step)
    step = step or 0
    if step > 5 then
        return false
    end
    local i = 1
    while true do
        local n, v = debug.getupvalue(func, i)
        if not n then break end
        if type(v) == "function" then
            if setupvalue2hm(v, name, value, step + 1) then
                return true
            end
        end
        if n == name then
            debug.setupvalue(func, i, value)
            return true
        end
        i = i + 1
    end
    return false
end

-- 取某个单位监听信号的函数
function getlistenforeventfn(inst, event, source, target)
    target = target or inst
    if inst.event_listeners and inst.event_listeners[event] and inst.event_listeners[event][target] then
        for i, func in ipairs(inst.event_listeners[event][target]) do
            if debug.getinfo(func, "S").source == source then return inst.event_listeners[event][target], i, func end
        end
    end
end
-- 增加动画帧
function AddStateTimeEvent2hm(state, time, fn)
    if state then
        state.timeline = state.timeline or {}
        if #state.timeline > 0 then
            local res = 1
            for i = 1, #state.timeline, 1 do
                res = i
                local tevent = state.timeline[i]
                if tevent.time > time then break end
            end
            table.insert(state.timeline, res, TimeEvent(time, fn))
        else
            table.insert(state.timeline, TimeEvent(time, fn))
        end
    end
end

-- 克劳斯鹿的特效
function SpawnSpell2hm(inst, castfx, castduration, worker)
    local spell = SpawnPrefab(castfx or "deer_fire_circle")
    local x, y, z = (worker or inst).Transform:GetWorldPosition()
    spell.Transform:SetPosition(x, y, z)
    if spell.TriggerFX then spell:DoTaskInTime(castduration / 2 or 3, spell.TriggerFX) end
    spell:DoTaskInTime(castduration or 6, spell.KillFX)
    return spell
end

-- 实体染色
local colors = {
    red = {227 / 255, 23 / 255, 13 / 255},
    blue = {30 / 255, 144 / 255, 255 / 255},
    green = {0 / 255, 201 / 255, 87 / 255},
    yellow = {255 / 255, 255 / 255, 0 / 255},
    orange = {255 / 255, 97 / 255, 0 / 255},
    purple = {153 / 255, 51 / 255, 250 / 255}
}
function SetAnimColor2hm(inst, colorname)
    local color = colors[colorname]
    if color then
        local r, g, b, alpha = inst.AnimState:GetMultColour()
        inst.AnimState:SetMultColour(color[1] * r, color[2] * g, color[3] * b, alpha)
    end
end

-- 状态图动画和效果变速,注意一个单位可能加速多个状态图(一般不会有影响)，多个单位可能加速同一个状态
function RemoveSpeedUpState2hm(inst, state, force)
    if (force or inst.sg.currentstate ~= state) and state.rate2hm and state.entities2hm and state.entities2hm[inst] then
        local fn = state.entities2hm[inst]
        state.entities2hm[inst] = nil
        if TheWorld.ismastersim then inst.AnimState:SetDeltaTimeMultiplier(1) end
        -- 没有单位再加速此动画
        if IsTableEmpty(state.entities2hm) then
            if state.timeline then
                for _, timeline in ipairs(state.timeline) do
                    if timeline and timeline.time2hm then
                        timeline.time = timeline.time2hm
                        timeline.time2hm = nil
                    end
                end
            end
            state.rate2hm = nil
        end
        inst:RemoveEventCallback("newstate", fn)
        inst:RemoveEventCallback("onremove", fn)
    end
end
function SpeedUpState2hm(inst, state, rate)
    state.entities2hm = state.entities2hm or {}
    if state.entities2hm[inst] == nil then
        -- 多个单位可能加速同一个状态，使用之前单位的速度
        if state.timeline then rate = state.rate2hm or rate end
        -- 首次加速但是是1倍速不做任何处理
        if rate ~= 1 then
            if TheWorld.ismastersim then inst.AnimState:SetDeltaTimeMultiplier(rate) end
            if inst.sg.timeout then inst.sg.timeout = inst.sg.timeout / rate end
            -- 仅首次加速处理时间线
            if state.timeline and not state.rate2hm then
                for _, timeline in ipairs(state.timeline) do
                    if timeline and timeline.time and not timeline.time2hm then
                        timeline.time2hm = timeline.time
                        timeline.time = timeline.time2hm / rate
                    end
                end
            end
            state.rate2hm = rate
            local fn = function(inst) RemoveSpeedUpState2hm(inst, state) end
            state.entities2hm[inst] = fn
            inst:ListenForEvent("newstate", fn)
            inst:ListenForEvent("onremove", fn)
        end
    end
end

-- 某道具的动作特殊处理动作属性
if BufferedAction then
    local constructor = BufferedAction._ctor
    BufferedAction._ctor = function(self, ...)
        constructor(self, ...)
        if self.invobject and self.invobject.actfn2hm and self.action then self.invobject.actfn2hm(self, self.invobject) end
    end
end

local function OnPlayerJoined(src, player)
    if TUNING.util2hm.classified2hm_list[player.userid] and TUNING.util2hm.classified2hm_list[player.userid]:IsValid() then
        return
    end
    local classified2hm = SpawnPrefab("classified2hm")
    TUNING.util2hm.classified2hm_list[player.userid] = classified2hm
    classified2hm.userid:set(player.userid)
    -- print("add player", player.userid, classified2hm)
end

local function OnPlayerLeft(src, player)
    if not TUNING.util2hm.classified2hm_list[player.userid] then
        return
    end
    -- print("remove player", player.userid, TUNING.util2hm.classified2hm_list[player.userid])
    TUNING.util2hm.classified2hm_list[player.userid]:Remove()
    TUNING.util2hm.classified2hm_list[player.userid] = nil
end

TUNING.util2hm.classified2hm_list = {}

local function ReFindClassified2hm_list()
    -- print("ReFindClassified2hm_list")
    TUNING.util2hm.classified2hm_list = {}
    for _, ent in pairs(Ents) do
        if ent.prefab == "classified2hm" then
            -- print("find", ent, ent.prefab, ent.setuserid)
            if ent.setuserid and ent.setuserid ~= "" then
                TUNING.util2hm.classified2hm_list[ent.setuserid] = ent
            end
        end
    end
end

AddPrefabPostInit("world", function(inst)
    -- print("init world")
    if not inst.ismastersim then
        inst:DoTaskInTime(0, ReFindClassified2hm_list)
        return
    end
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft)
end)

ACTIONS.CASTSPELL.distanceFunc = function(bufferedAction)
    if bufferedAction and bufferedAction.invobject and bufferedAction.invobject.actiondistanceFunc2hm then
        return bufferedAction.invobject:actiondistanceFunc2hm(bufferedAction)
    end
end
AddGlobalClassPostConstruct("bufferedaction", "BufferedAction", function(self)
    if self.action and self.action.distanceFunc then
        self.distance = self.action.distanceFunc(self) or self.distance
    end
end)

TUNING.util2hm.GetClassified2hm = function (userid)
    if not userid then return end
    local prefab = TUNING.util2hm.classified2hm_list and TUNING.util2hm.classified2hm_list[userid]
    if prefab and prefab:IsValid() then
        return prefab
    end
end

TUNING.util2hm.getChrSize = function(char)
    if not char then
        return 0
    elseif char >= 240 then
        return 4
    elseif char >= 224 then
        return 3
    elseif char >= 192 then
        return 2
    elseif char >= 0 then
        return 1
    else
        return 0
    end
end

TUNING.util2hm.utf8len = function(input)
    local len = string.len(input)
    local left = len
    local cnt = 0
    local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

TUNING.util2hm.utf8sub = function(str, startChar, numChars)
    local startIndex = 1
    local len = string.len(str)
    numChars = numChars or TUNING.util2hm.utf8len(str)
    while startChar > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + TUNING.util2hm.getChrSize(char)
        startChar = startChar - 1
    end
    local currentIndex = startIndex
    while numChars > 0 and currentIndex <= len do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + TUNING.util2hm.getChrSize(char)
        numChars = numChars - 1
    end
    return string.sub(str, startIndex, currentIndex - 1), numChars
end

local randomList = {0, 144, 49, 206, 149, 121, 89, 229, 210, 189, 43, 219, 179, 129, 76, 4, 23, 93, 37, 44, 252, 114, 30, 2, 5, 99, 138, 150, 157, 159, 46, 172, 116, 91, 16, 160, 202, 207, 133, 78, 226, 187, 244, 237, 136, 36, 117, 61, 221, 56, 198, 216, 254, 253, 154, 98, 67, 74, 213, 8, 96, 24, 173, 15, 3, 234, 72, 71, 151, 177, 212, 184, 123, 54, 190, 119, 113, 241, 188, 29, 152, 100, 186, 155, 142, 88, 39, 58, 108, 205, 131, 250, 193, 84, 42, 168, 125, 18, 178, 127, 35, 242, 34, 231, 175, 77, 106, 19, 246, 171, 41, 224, 209, 145, 51, 48, 208, 118, 40, 128, 185, 102, 70, 146, 174, 196, 183, 112, 27, 90, 218, 10, 132, 166, 104, 25, 240, 235, 139, 83, 115, 87, 220, 75, 110, 64, 249, 69, 194, 147, 50, 199, 217, 95, 126, 230, 7, 251, 143, 12, 135, 52, 215, 162, 165, 47, 214, 26, 22, 191, 79, 239, 66, 82, 32, 182, 211, 176, 153, 192, 60, 31, 1, 14, 204, 225, 59, 28, 140, 6, 38, 120, 197, 169, 137, 20, 107, 63, 180, 85, 111, 68, 158, 141, 167, 55, 130, 247, 195, 238, 57, 92, 53, 248, 109, 245, 17, 163, 21, 105, 233, 11, 228, 86, 80, 203, 103, 65, 164, 161, 124, 134, 170, 181, 227, 223, 148, 200, 101, 81, 33, 222, 122, 236, 45, 13, 156, 201, 97, 73, 94, 9, 243, 232, 62}
local seedIndex = 1

TUNING.util2hm.setSeed = function(seed)
    seedIndex = seed % 255
end

TUNING.util2hm.getRandom = function()
    seedIndex = seedIndex % 255 + 1
    return randomList[seedIndex] / 255
end

TUNING.util2hm.getRandomInt = function(n)
    return math.ceil(TUNING.util2hm.getRandom() * n)
end

TUNING.util2hm.getRandomIntBetween = function(a, b)
    return TUNING.util2hm.getRandomInt(b - a + 1) + a - 1
end

TUNING.util2hm.GetLanguage = function(ch, en)
    if ch and en then
        return TUNING.isCh2hm and ch or en
    else
        return ch or en or "error_word"
    end
end

TUNING.util2hm.GetName = function(name)
    if name then
        return STRINGS.NAMES[string.upper(name)] or name
    else
        return "none"
    end
end

local getNumWithLength = function(num, length)
    if num <= 0 then
        return string.rep('0', length)
    else
        local num_length = math.ceil(math.log(num + 1) / math.log(10))
        if num_length >= length then
            return num
        else
            return string.rep('0', length - num_length) .. num
        end
    end
end

TUNING.util2hm.GetTime = function(time)
    if not time then
        return ""
    end
    local day, minute, second = math.floor(time / 3600), time % 3600
    minute, second = math.floor(minute / 60), math.floor(minute % 60)
    local timeStr = {}
    if day > 0 then
        table.insert(timeStr, day)
    end
    table.insert(timeStr, getNumWithLength(minute, 2))
    table.insert(timeStr, getNumWithLength(second, 2))
    return table.concat(timeStr, ":")
end

TUNING.util2hm.GenListenFunc = function(inst, event)
    local listenfunc
    local listenfunctarget

    local clearFunc = function()
        if listenfunc and listenfunctarget then
            if listenfunctarget:IsValid() then
                inst:RemoveEventCallback(event, listenfunc, listenfunctarget)
            end
            listenfunc = nil
            listenfunctarget = nil
        end
    end

    local addListenerFunc = function(func, target)
        clearFunc()
        listenfunc = func
        listenfunctarget = target
        inst:ListenForEvent(event, listenfunc, listenfunctarget)
    end

    return clearFunc, addListenerFunc
end

TUNING.util2hm.GenTaskFunc = function(inst)
    local task
    local clearFunc = function()
        if task then
            task:Cancel()
            task = nil
        end
    end

    local doTaskFunc = function(time, func, ...)
        clearFunc()
        task = inst:DoTaskInTime(time, function(...)
            clearFunc()
            func(...)
        end, ...)
    end

    return clearFunc, doTaskFunc
end

TUNING.util2hm.GetStack = function()
    local str = {"track:"}
    local i = 1
    while true do
        i = i + 1
        local info = debug.getinfo(i)
        if not info then break end
        table.insert(str, string.format("   %s[%s]: in function '%s'", info.source or "?", info.currentline or "?", info.name or "?"))
    end
    return table.concat(str, "\n")
end

-- 临时装备禁止被用于制作了
AddComponentPostInit("builder", function(self)
    local _MakeRecipe = self.MakeRecipe
    function self:MakeRecipe(recipe, pt, rot, skin, onsuccess)
        -- 检查是否有临时装备被用于制作
        local recipe_data = type(recipe) == "string" and GetValidRecipe(recipe) or recipe
        if recipe_data and recipe_data.ingredients then
            for _, ingredient in ipairs(recipe_data.ingredients) do
                local amt = math.max(1, RoundBiasedUp(ingredient.amount * self.ingredientmod))
                local items = self.inst.components.inventory:GetCraftingIngredient(ingredient.type, amt)
                if items then
                    for item, count in pairs(items) do
                        if item and item.components.tempequip2hm then
                            -- 播放失败音效和提示消息
                            if self.inst.components.talker then
                                self.inst.components.talker:Say((TUNING.isCh2hm and "临时装备无法用于制作" or "Temporary equipment cannot be used for crafting"))
                            end
                            if self.inst.SoundEmitter then
                                self.inst.SoundEmitter:PlaySound("dontstarve/HUD/click_negative")
                            end
                            return false
                        end
                    end
                end
            end
        end
        return _MakeRecipe(self, recipe, pt, rot, skin, onsuccess)
    end
end)

-- 临时装备禁止被拆解/通过作祟拆解
AddPrefabPostInit("greenstaff", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 处理主动施法
    inst:DoTaskInTime(0, function()
        if inst.components.spellcaster then
            local original_spellfn = inst.components.spellcaster.spell
            local function custom_destroystructure(staff, target)
                -- 检查是否有临时装备组件，如果有则不允许拆解
                if target and target.components.tempequip2hm then 
                    -- 播放失败音效
                    local caster = staff.components.inventoryitem and staff.components.inventoryitem.owner
                    if caster and caster.components.talker then
                        caster.components.talker:Say((TUNING.isCh2hm and "它不让我这么做" or "It won't let me do that"))
                    end
                    return
                end
                if original_spellfn then return original_spellfn(staff, target) end
            end
            inst.components.spellcaster:SetSpellFn(custom_destroystructure)
        end
    end)
    
    -- 处理作祟拆解
    inst:DoTaskInTime(0, function()
        if inst.components.hauntable then
            local original_onhaunt = inst.components.hauntable.onhaunt
            local function custom_onhaunt(inst_haunted, haunter)
                local HasRecipe = function(guy)
                    return guy.prefab ~= nil and AllRecipes[guy.prefab] ~= nil
                end
                local GREENHAUNT_CANT_TAGS = { "INLIMBO" }
                local target = FindEntity(inst_haunted, 20, HasRecipe, nil, GREENHAUNT_CANT_TAGS)
                
                -- 如果找到的目标有临时装备组件，则不允许作祟拆解
                if target and target.components.tempequip2hm then
                    return false
                end
                
                -- 否则调用原始的作祟函数
                if orioriginal_onhaunt then return original_onhaunt(inst_haunted, haunter) end
            end
            inst.components.hauntable:SetOnHauntFn(custom_onhaunt)
        end
    end)
end)

-- ========================================================================================================
-- 温度系统优化：为SetTemperature添加优先级和冷却机制，防止低优先级buff覆盖高优先级buff

AddComponentPostInit("temperature", function(self)
    local old_SetTemperature = self.SetTemperature
    
    self.SetTemperature = function(self, value, priority)
        local inst = self.inst
        local current_time = GetTime()
        
        -- 获取当前buff的优先级（默认为10）
        local new_priority = priority or (inst.temp_priority2hm or 10)
        
        -- 检查是否在冷却时间内
        if inst.temp_last_set_time2hm and inst.temp_last_priority2hm then
            local time_since_last = current_time - inst.temp_last_set_time2hm
            
            if time_since_last < 5 then
                -- 如果新的优先级低于当前优先级，则不执行
                if new_priority > inst.temp_last_priority2hm then
                    return
                end
            end
        end

        inst.temp_last_set_time2hm = current_time
        inst.temp_last_priority2hm = new_priority
        
        return old_SetTemperature(self, value)
    end
end)

-- 食物温度效果改为保留更持久的buff
AddComponentPostInit("temperature", function(self)
    local old_SetTemperatureInBelly = self.SetTemperatureInBelly
    
    self.SetTemperatureInBelly = function(self, delta, duration)
        local inst = self.inst
        
        if self.bellytemperaturedelta ~= nil and self.bellytime ~= nil then
            local remaining_time = self.bellytime - GetTime()
            
            -- 如果剩余时间大于新的持续时间，则不覆盖
            if remaining_time > duration then
                return
            end
        end
        return old_SetTemperatureInBelly(self, delta, duration)
    end
end)

-- ========================================================================================================
-- 随从回巢优化：当随从脱离加载范围时，如果没有领队但有家则传送回家
AddComponentPostInit("follower", function(self)
    local inst = self.inst
    
    local old_StopFollowing = self.StopFollowing
    
    -- 失去忠诚度时标记需要回家
    self.StopFollowing = function(self)
        if self.inst:IsValid() then
            self.inst.shouldgohome2hm = true
        end
        return old_StopFollowing(self)
    end

    local function TryReturnHome(inst)
        if not inst:IsValid() then return end
        
        -- 如果有主人，由原版的TryPorting处理传送到领队逻辑
        if inst.components.follower and inst.components.follower.leader ~= nil then
            return
        end
        
        local home_pos = nil
        
        if inst.components.homeseeker and inst.components.homeseeker.home then
            home_pos = inst.components.homeseeker:GetHomePos()
        end
        
        if not home_pos and inst.components.knownlocations then
            home_pos = inst.components.knownlocations:GetLocation("home")
        end
        
        if home_pos then
            -- 清除仇恨目标
            if inst.components.combat ~= nil then
                inst.components.combat:SetTarget(nil)
                if inst.components.combat.GiveUp then
                    inst.components.combat:GiveUp()
                end
            end
            
            local current_pos = inst:GetPosition()
            local dist_sq = distsq(home_pos, current_pos)
            
            -- 检查距离避免在家附近反复传送
            if dist_sq > 100 or inst:IsAsleep() then
                if inst.Physics ~= nil then
                    inst.Physics:Teleport(home_pos:Get())
                else
                    inst.Transform:SetPosition(home_pos:Get())
                end
                
                inst.shouldgohome2hm = nil
                
                -- 触发回家事件，供其他组件监听
                inst:PushEvent("arrivedathome")
            end
        end
    end

    inst:ListenForEvent("entitysleep", function(inst)
        inst:DoTaskInTime(0, TryReturnHome)
    end)
    
    -- 正常情况下加载外失去忠诚就直接回领队边上了，但以防万一
    inst:ListenForEvent("loseloyalty", function(inst, data)
        inst.shouldgohome2hm = true
        
        if inst:IsAsleep() then
            inst:DoTaskInTime(0, TryReturnHome)
        end
    end)
end)

-- 因为生物巢穴有两种储存方式，我们需要确保其同步以避免一些边缘情况
AddComponentPostInit("homeseeker", function(self)
    local inst = self.inst
    
    local old_SetHome = self.SetHome
    
    self.SetHome = function(self, home)
        old_SetHome(self, home)
        
        if home and inst.components.knownlocations then
            inst.components.knownlocations:RememberLocation("home", home:GetPosition())
        end
    end
end)

-- ========================================================================================================
-- 交易行为优化，蚁狮和鱼人王交易行为模仿猪王

-- 鱼人王交易优化
AddStategraphState("mermking", State{
    name = "trade",
    tags = {"busy"},

    onenter = function(inst)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("give")
    end,

    timeline =
    {
        TimeEvent(22*FRAMES, function(inst) 
            inst:TradeItem() 
        end),
        -- 在交易完成后的下一帧移除busy标签，允许立即接受新的交易
        TimeEvent(23*FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
        end),
        SoundFrameEvent(23, "dontstarve/characters/wurt/merm/king/warcry"),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },
})

-- 蚁狮交易优化
AddStategraphState("antlion", State{
    name = "rocktribute",
    tags = { "busy", "nosleep", "nofreeze" },

    onenter = function(inst, data)
        inst.AnimState:PlayAnimation("eat")
        inst.sg.statemem.tributepercent = data ~= nil and data.tributepercent or 0
    end,

    timeline =
    {
        TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/eat") end),
        TimeEvent(36 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/eat") end),
        TimeEvent(71 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/swallow") end),
        -- 提前移除busy标签，在吞咽音效后立即允许新的交易
        TimeEvent(72 * FRAMES, function(inst)       -- 原版是在85帧才移除
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("nosleep")
            inst.sg:RemoveStateTag("nofreeze")
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState(inst:GetRageLevel() <= 1 and "hightributeresponse" or "idle")
            end
        end),
    },
})

AddStategraphState("antlion", State{
    name = "trinkettribute",
    tags = { "busy", "nosleep", "nofreeze", "noelectrocute" },

    onenter = function(inst)
        inst.AnimState:PlayAnimation("eat_talisman")
        inst.AnimState:PushAnimation("spit_talisman", false)
    end,

    timeline =
    {
        TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/swallow") end),
        TimeEvent(44 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
        TimeEvent(80 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/spit")
            inst:GiveReward()
            inst.sg:RemoveStateTag("noelectrocute")
        end),
        -- 在给予奖励后的下一帧移除busy标签，允许立即进行新的交易
        TimeEvent(81 * FRAMES, function(inst)   -- 原版是在98帧才移除
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("nosleep")
            inst.sg:RemoveStateTag("nofreeze")
        end),
    },

    events =
    {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },
})

AddStategraphState("antlion", State{
    name = "refusetribute",
    tags = { "busy", "nosleep", "nofreeze" },

    onenter = function(inst)
        inst.AnimState:PlayAnimation("unimpressed")
    end,

    timeline =
    {
        -- 拒绝交易也应该更快地允许下次尝试
        TimeEvent(30 * FRAMES, function(inst)   -- 原版是在48帧才移除
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("nosleep")
            inst.sg:RemoveStateTag("nofreeze")
        end),
        TimeEvent(54 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/unimpressed") end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },
})
-- ========================================================================================================
-- 发条生物注册表 (探测杖用)
TUNING.CHESSMONSTER_REGISTRY2HM = {}
for _, name in ipairs({"knight", "knight_nightmare", "bishop", "bishop_nightmare", "rook", "rook_nightmare"}) do
    AddPrefabPostInit(name, function(inst)
        if not TheWorld.ismastersim then return end
        TUNING.CHESSMONSTER_REGISTRY2HM[inst.GUID] = inst
        inst:ListenForEvent("onremove", function() TUNING.CHESSMONSTER_REGISTRY2HM[inst.GUID] = nil end)
    end)
end