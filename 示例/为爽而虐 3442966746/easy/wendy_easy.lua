local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 温蒂伤害正常倍率，困难模式不生效
if GetModConfigData("Wendy Normal Attack Damage") and not hardmode then
    AddPrefabPostInit("wendy", function(inst)
        if not TheWorld.ismastersim then return end
        inst.components.combat.damagemultiplier = 1
    end)
end

-- 阿比盖尔等级保护,阿比盖尔死亡只降低1级且损失全部经验；温蒂死亡时不会减少增益，但会持续降级
if GetModConfigData("Abigail Level Protect") then
    local function newondeath(inst)
        local self = inst.components.ghostlybond
        if self then
            self:Recall()
            if hardmode then
                if not self.death2hm then
                    self.death2hm = true
                    if self.bondlevel == self.maxbondlevel then self:SetBondLevel(self.maxbondlevel - 1, self.bondlevelmaxtime) end
                end
            else
                self:PauseBonding()
            end
        end
    end
    local function newrespawnedfromghost(inst)
        local self = inst.components.ghostlybond
        if self then
            if hardmode then
                if self.death2hm then
                    self.death2hm = nil
                    if self.bondlevel == 1 then
                        self.bondleveltimer = self.bondleveltimer or 0
                        inst:StartUpdatingComponent(self)
                    end
                end
            else
                self:ResumeBonding()
            end
        end
    end
    AddPrefabPostInit("wendy", function(inst)
        if not TheWorld.ismastersim then return end
        local src = "scripts/prefabs/wendy.lua"
        for i, func in ipairs(inst.event_listeners.death[inst]) do
            if debug.getinfo(func, "S").source == src then
                inst.event_listeners.death[inst][i] = newondeath
                break
            end
        end
        for i, func in ipairs(inst.event_listeners.ms_becameghost[inst]) do
            if debug.getinfo(func, "S").source == src then
                inst.event_listeners.ms_becameghost[inst][i] = newondeath
                break
            end
        end
        for i, func in ipairs(inst.event_listeners.ms_respawnedfromghost[inst]) do
            if debug.getinfo(func, "S").source == src then
                inst.event_listeners.ms_respawnedfromghost[inst][i] = newrespawnedfromghost
                break
            end
        end
    end)

    AddComponentPostInit("ghostlybond", function(self, ...)        
        local function _ghost_death(self)
            if self.bondlevel > 1 then
                self:SetBondLevel(self.bondlevel - 1, self.bondleveltimer)
            else
                self.bondleveltimer = (self.bondleveltimer or 0) - self.bondlevelmaxtime
            end
            self:Recall(true)
        end
        self._ghost_death = function(ghost) _ghost_death(self, ghost) end
        if hardmode then
            local Onupdate = self.Onupdate
            self.Onupdate = function(self, dt, ...)
                if self.death2hm then
                    if self.bondlevel == 1 and (self.bondleveltimer or 0) <= 0 then
                        self.inst:StopUpdatingComponent(self)
                        return
                    end
                    self.bondleveltimer = (self.bondleveltimer or 0) - dt * 4
                    if self.bondleveltimer <= 0 and self.bondlevel > 1 then
                        self:SetBondLevel(self.bondlevel - 1, self.bondlevelmaxtime + self.bondleveltimer)
                    end
                else
                    Onupdate(self, ...)
                end
            end
            self.PauseBonding = nilfn
            self.ResumeBonding = nilfn
        end
    end)
end
-- 温蒂共享阿比盖尔攻击BUFF和移速BUFF,阿比盖尔所有药剂同时生效
if GetModConfigData("Wendy Share Debuff From Abigail") then
    -- 万金油给予温蒂伤害buff
    local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
        return mount == nil and inst:HasDebuff("ghostlyelixir_attack_buff") and
                (TUNING.DSTU and TUNING.DSTU.WENDY_NERF or not target:HasDebuff("abigail_vex_debuff")) and 1.25 or 1
    end

    AddPrefabPostInit("wendy", function(inst)
        if not TheWorld.ismastersim or not inst.components.ghostlybond then return end
        -- inst:ListenForEvent("onhitother", onhitother)
        if not inst.components.combat.customdamagemultfn then
            inst.components.combat.customdamagemultfn = CustomCombatDamage
        else
            local old = inst.components.combat.customdamagemultfn
            inst.components.combat.customdamagemultfn = function(...) return (old(...) or 1) * CustomCombatDamage(...) end
        end
    end)
    
    -- 强健精油给予温蒂移速buff
    AddPrefabPostInit("ghostlyelixir_speed_buff", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.potion_tunings and not inst.potion_tunings.speedprocess2hm then 
            inst.potion_tunings.speedprocess2hm = true
            local original_apply_player = inst.potion_tunings.ONAPPLY_PLAYER
            local original_detach_player = inst.potion_tunings.ONDETACH_PLAYER
        
            inst.potion_tunings.ONAPPLY_PLAYER = function(inst, target, ...)
                if original_apply_player then
                    original_apply_player(inst, target, ...)
                end
                if target:HasTag("player") and target:HasTag("elixirbrewer") then
                    local function OnMounted()
                        target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "ghostlyelixir2hm")
                    end
                    local function OnDismounted()
                        if not (target.components.rider and target.components.rider:IsRiding()) then
                            target.components.locomotor:SetExternalSpeedMultiplier(inst, "ghostlyelixir2hm", 1.15)
                        end
                    end
                    -- 绑定监听器（仅首次生效时绑定）
                    if not target._elixir_listeners then
                        target._elixir_listeners = {
                            mounted = OnMounted,
                            dismounted = OnDismounted
                        }
                        target:ListenForEvent("mounted", OnMounted)
                        target:ListenForEvent("dismounted", OnDismounted)
                    end

                    -- 初始应用速度加成
                    OnDismounted()
                end
            end

            inst.potion_tunings.ONDETACH_PLAYER = function(inst, target, ...)
                if original_detach_player then
                    original_detach_player(inst, target, ...)
                end
                if target:HasTag("player") and target:HasTag("elixirbrewer") then
                    if target._elixir_listeners then
                        target:RemoveEventCallback("mounted", target._elixir_listeners.mounted)
                        target:RemoveEventCallback("dismounted", target._elixir_listeners.dismounted)
                        target._elixir_listeners = nil
                        target.components.locomotor:RemoveExternalSpeedMultiplier(inst, "ghostlyelixir2hm")
                    end
                end
            end
        end
    end)


    local ghostlyelixirsbuffs = {
        ghostlyelixir_attack_buff = true,
        ghostlyelixir_speed_buff = true,
        ghostlyelixir_slowregen_buff = true,
        ghostlyelixir_fastregen_buff = true,
        ghostlyelixir_retaliation_buff = false,
        ghostlyelixir_shield_buff = false,
        ghostlyelixir_lunar_buff = false,
        ghostlyelixir_shadow_buff = false,
        ghostlyelixir_revive_buff = false
    }
    
    -- 多个BUFF需要修改循环显示特效
    TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY = 10
    local function processbufffxtime(inst)
        inst.processbufffxtimetask2hm = nil
        if inst.components.debuffable then
            local buffs = {}
            for name, buff in pairs(inst.components.debuffable.debuffs) do
                if buff and buff.inst and buff.inst:IsValid() and ghostlyelixirsbuffs[buff.inst.prefab] ~= nil and buff.inst.driptask and
                    buff.inst.potion_tunings and buff.inst.driptask.period == TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY then
                    table.insert(buffs, buff.inst)
                end
            end
            if #buffs > 0 then
                for i = 1, #buffs do
                    local fn = buffs[i].driptask.fn
                    buffs[i].driptask:Cancel()
                    buffs[i].driptask = buffs[i]:DoPeriodicTask(TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY, fn, TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY * (i - 0.5) / #buffs,
                                                                inst)
                end
            end
        end
    end
    local function processghostlyelixirbuff(inst)
        if not TheWorld.ismastersim then return end
        if inst.potion_tunings and not inst.potion_tunings.fxprocess2hm then
            inst.potion_tunings.fxprocess2hm = true
            local ONAPPLY = inst.potion_tunings.ONAPPLY
            inst.potion_tunings.ONAPPLY = function(inst, target, ...)
                if ONAPPLY then ONAPPLY(inst, target, ...) end
                if target and target:IsValid() and not target.processbufffxtimetask2hm then
                    target.processbufffxtimetask2hm = target:DoTaskInTime(0, processbufffxtime)
                end
            end
            local ONDETACH = inst.potion_tunings.ONDETACH
            inst.potion_tunings.ONDETACH = function(inst, target, ...)
                if ONDETACH then ONDETACH(inst, target, ...) end
                if target and target:IsValid() and not target.processbufffxtimetask2hm then
                    target.processbufffxtimetask2hm = target:DoTaskInTime(0, processbufffxtime)
                end
            end
        end
    end
    for ghostlyelixirbuff, buffstatus in pairs(ghostlyelixirsbuffs) do AddPrefabPostInit(ghostlyelixirbuff, processghostlyelixirbuff) end
    local playerghostlyelixirs = {"ghostlyelixir_speed", "ghostlyelixir_attack"}
    local function processghostlyelixir(inst)
        if not TheWorld.ismastersim or not inst.components.ghostlyelixir then return end
        local DoApplyElixir = inst.components.ghostlyelixir.doapplyelixerfn

        inst.components.ghostlyelixir.doapplyelixerfn = function(inst, giver, target, ...)
            -- 装备时幽魂花冠不叠加
            local isWearingGhostflower = target.components.inventory and 
                                        target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and 
                                        target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "ghostflowerhat"
            if isWearingGhostflower then
                local cur_buff = target:GetDebuff("elixir_buff")
                if cur_buff ~= nil then
                target:RemoveDebuff("elixir_buff")
                end
            end
            -- 攻击和移速药剂对姐姐和温蒂同时生效
            if table.contains(playerghostlyelixirs, inst.prefab) and target._playerlink and target._playerlink:IsValid() then
                local duration_mult = 1
                if giver.components.skilltreeupdater and 
                    giver.components.skilltreeupdater:IsActivated("wendy_potion_duration") then
                    duration_mult = 2 -- 技能树使持续时间加倍
                end
                -- 添加buff并设置持续时间
                local buff = target._playerlink.components.debuffable:AddDebuff(inst.buff_prefab, inst.buff_prefab)
                if buff and buff.components.timer then
                    local default_duration = TUNING["GHOSTLYELIXIR_PLAYER_"..(inst.prefab == "ghostlyelixir_attack" and "DAMAGE" or "SPEED").."_DURATION"]                
                    buff.components.timer:StopTimer("decay")
                    buff.components.timer:StartTimer("decay", default_duration * duration_mult)
                end
            end
            -- 姐姐全部药剂叠加生效
            local cur_buff = target:GetDebuff("elixir_buff")
            -- 已有正在生效BUFF
            if cur_buff ~= nil and cur_buff.prefab ~= inst.buff_prefab then
                if ghostlyelixirsbuffs[cur_buff.prefab] then
                    -- 已有非防御BUFF则转移非防御BUFF
                    local oldbuffprefab = cur_buff.prefab
                    local oldbufftimeleft = cur_buff.components.timer and cur_buff.components.timer:GetTimeLeft("decay") or 30
                    target:RemoveDebuff("elixir_buff")
                    if target:AddDebuff(oldbuffprefab, oldbuffprefab) then
                        local now_buff = target:GetDebuff(oldbuffprefab)
                        if now_buff and now_buff.components.timer then
                            now_buff.components.timer:StopTimer("decay")
                            now_buff.components.timer:StartTimer("decay", oldbufftimeleft)
                        end
                    end
                    return target:AddDebuff("elixir_buff", inst.buff_prefab)
                elseif ghostlyelixirsbuffs[inst.buff_prefab] then
                    -- 已有防御BUFF,施加非防御BUFF则转移非防御BUFF
                    return target:AddDebuff(inst.buff_prefab, inst.buff_prefab)
                elseif cur_buff.prefab == "ghostlyelixir_retaliation_buff" and inst.buff_prefab == "ghostlyelixir_shield_buff" then
                    -- 已有高级防御BUFF施加低级防御BUFF则
                    return false
                end
            end
            -- 已有转移的此BUFF则移除转移的该BUFF
            if target:GetDebuff(inst.buff_prefab) then target:RemoveDebuff(inst.buff_prefab) end
            return DoApplyElixir(inst, giver, target, ...)
        end
        
    end
    local ghostlyelixirs = {
        "ghostlyelixir_attack",
        "ghostlyelixir_speed",
        "ghostlyelixir_slowregen",
        "ghostlyelixir_fastregen",
        "ghostlyelixir_retaliation",
        "ghostlyelixir_shield",
        "ghostlyelixir_lunar", 
        "ghostlyelixir_shadow",
        "ghostlyelixir_revive", 
    }
    for _, ghostlyelixir in ipairs(ghostlyelixirs) do AddPrefabPostInit(ghostlyelixir, processghostlyelixir) end
    

    -- 万金油buff被转移到elixir_buff以外的键了，原版会读取不到，导致伤害计算错误
    local function UpdateDamage(inst, ...)
        local oldphase = TheWorld.state.phase
        -- 临时修改TheWorld.state.phase以纠正伤害计算
        TheWorld.state.phase = inst:HasDebuff("ghostlyelixir_attack_buff") and "night" or oldphase

        inst.oldUpdateDamage2hm(inst, ...)

        TheWorld.state.phase = oldphase
    end
    
    local function delayprocessbuff(inst, name, set)
        if not inst:HasTag("swc2hm") and inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil and
            inst._playerlink.components.pethealthbar.SetSymbol2hm then
            if set then
                if inst:HasDebuff(name) or (inst:GetDebuff("elixir_buff") and inst:GetDebuff("elixir_buff").prefab == name) then
                    inst._playerlink.components.pethealthbar:SetSymbol2hm(name)
                end
            elseif not (inst:HasDebuff(name) or (inst:GetDebuff("elixir_buff") and inst:GetDebuff("elixir_buff").prefab == name)) then
                inst._playerlink.components.pethealthbar:RemoveSymbol2hm(name)
            end
        end
    end

    -- 修复虚影形态伤害计算
    AddStategraphPostInit("abigail", function(sg)
        -- 修复普通虚影攻击
        if sg.states.gestalt_loop_attack and sg.states.gestalt_loop_attack.onenter then
            local onenter = sg.states.gestalt_loop_attack.onenter
            sg.states.gestalt_loop_attack.onenter = function(inst, ...)
                local attack_buff = inst:GetDebuff("ghostlyelixir_attack_buff")
                local oldphase = TheWorld.state.phase

                if attack_buff ~= nil then
                    TheWorld.state.phase = "night"
                end

                onenter(inst, ...)
              
                TheWorld.state.phase = oldphase
            end
        end
        
        -- 修复虚影技能攻击
        if sg.states.gestalt_loop_homing_attack and sg.states.gestalt_loop_homing_attack.onenter then
            local onenter = sg.states.gestalt_loop_homing_attack.onenter
            sg.states.gestalt_loop_homing_attack.onenter = function(inst, data, ...)
                local attack_buff = inst:GetDebuff("ghostlyelixir_attack_buff")
                local oldphase = TheWorld.state.phase

                if attack_buff ~= nil then
                    TheWorld.state.phase = "night"
                end

                onenter(inst, data, ...)
  
                TheWorld.state.phase = oldphase
            end
        end
    end)
    
    AddPrefabPostInit("abigail", function(inst)
        if not TheWorld.ismastersim then return end
        
        inst.oldUpdateDamage2hm = inst.UpdateDamage
        inst.UpdateDamage = UpdateDamage
        inst:WatchWorldState("phase", UpdateDamage)
        UpdateDamage(inst)

        -- 使用elixir_buff(防御buff)和ghostlyelixirsbuffs[debuff.prefab]（其他）来实现多BUFF系统
        if inst.components.debuffable then
            local OnDebuffAdded = inst.components.debuffable.ondebuffadded
            inst.components.debuffable.ondebuffadded = function(inst, name, debuff, ...)
                if ghostlyelixirsbuffs[debuff.prefab] ~= nil then inst:DoTaskInTime(0, delayprocessbuff, debuff.prefab, true) end
                OnDebuffAdded(inst, name, debuff, ...)
            end
            local OnDebuffRemoved = inst.components.debuffable.ondebuffremoved
            inst.components.debuffable.ondebuffremoved = function(inst, name, debuff, ...)
                if ghostlyelixirsbuffs[debuff.prefab] ~= nil then inst:DoTaskInTime(0, delayprocessbuff, debuff.prefab) end
                OnDebuffRemoved(inst, name, debuff, ...)
            end
        end
    end)

    -- 姐姐的UI只够显示4个UI，其中一个是原版的，所以只能这3个用来显示非防御BUFF了，且快速回血BUFF因此不显示
    local UIAnim = require "widgets/uianim"
    local function checkabigailbuff(inst)
        if inst and inst == ThePlayer and inst.HUD and inst.HUD.controls and inst.HUD.controls and inst.HUD.controls.status and
            inst.HUD.controls.status.pethealthbadge and inst.components.pethealthbar then
            local badge = inst.HUD.controls.status.pethealthbadge
            local self = inst.components.pethealthbar
            for buff, buffstatus in pairs(ghostlyelixirsbuffs) do
                if buff and self[buff .. "2hm"] then
                    local name = buff .. "icon2hm"
                    if badge[name] then
                        local status = self[buff .. "2hm"]:value()
                        if buff == "ghostlyelixir_shield_buff" and self.ghostlyelixir_retaliation_buff2hm:value() then status = true end
                        if status then
                            if not badge[name].enable2hm then
                                badge[name].enable2hm = true
                                badge[name]:GetAnimState():PlayAnimation("buff_activate")
                                badge[name]:GetAnimState():PushAnimation("buff_idle", false)
                            end
                        elseif badge[name] and badge[name].enable2hm then
                            badge[name].enable2hm = false
                            badge[name]:GetAnimState():PlayAnimation("buff_deactivate")
                            badge[name]:GetAnimState():PushAnimation("buff_none", false)
                        end
                    end
                end
            end
        end
    end

    AddComponentPostInit("pethealthbar", function(self)
        for buff, buffstatus in pairs(ghostlyelixirsbuffs) do
            if buff then self[buff .. "2hm"] = net_bool(self.inst.GUID, buff .. "2hm.is", "abigailbuff2hmdirty") end
        end
        if not self.ismastersim then self.inst:ListenForEvent("abigailbuff2hmdirty", checkabigailbuff) end
        self.SetSymbol2hm = function(self, buff) if self.ismastersim and buff and self[buff .. "2hm"] then self[buff .. "2hm"]:set(true) end end
        self.RemoveSymbol2hm = function(self, buff) if self.ismastersim and buff and self[buff .. "2hm"] then self[buff .. "2hm"]:set(false) end end
    end)

    AddClassPostConstruct("widgets/pethealthbadge", function(self, owner)
        for buff, buffstatus in pairs(ghostlyelixirsbuffs) do
            if buff then
                local name = buff .. "icon2hm"
                self[name] = self.underNumber:AddChild(UIAnim())
                local anim = self[name]:GetAnimState()
                anim:SetBank("status_abigail")
                anim:SetBuild("status_abigail")
                anim:OverrideSymbol("buff_icon", self.OVERRIDE_SYMBOL_BUILD[buff] or self.default_symbol_build, buff)
                anim:PlayAnimation("buff_none")
                anim:AnimateWhilePaused(false)
                self[name]:SetClickable(false)
                -- ghostlyelixir_shield_buff = false,
                -- ghostlyelixir_retaliation_buff = false       
                if buff == "ghostlyelixir_attack_buff" or buff == "ghostlyelixir_lunar _buff" or buff == "ghostlyelixir_shadow _buff" then
                    -- 攻击BUFF,左上角
                    self[name]:SetScale(1, -1, 1)
                elseif buff == "ghostlyelixir_speed_buff" then
                    -- 速度BUFF，右下角
                    self[name]:SetScale(-1, 1, 1)
                elseif buff == "ghostlyelixir_slowregen_buff" or buff == "ghostlyelixir_fastregen_buff" then
                    -- 慢速和快速回血BUFF，右上角
                    self[name]:SetScale(-1, -1, 1)
                    -- 防御BUFF，左下角
                end
                self[name]:MoveToFront()
            end
        end
        local ShowBuff = self.ShowBuff
        self.ShowBuff = function(self, symbol, ...)
            if symbol ~= 0 and not self.OVERRIDE_SYMBOL_BUILD[symbol] then return end
            ShowBuff(self, symbol, ...)
        end
        if owner and owner:IsValid() then owner:DoTaskInTime(3, checkabigailbuff) end
    end)

    local function OnAttacked(inst, data)
        local ghost = inst.components.ghostlybond and inst.components.ghostlybond.ghost
        local level = inst.components.ghostlybond and inst.components.ghostlybond.bondlevel
        if ghost and ghost:IsValid() and not ghost:IsInLimbo() and level > 1 then --改为召唤时生效
            if inst:HasDebuff("forcefield") then
                if data.attacker ~= nil and data.attacker ~= inst and data.attacker.components.combat ~= nil then
                    local elixir_buff = ghost:GetDebuff("elixir_buff")
                    if elixir_buff ~= nil and elixir_buff.prefab == "ghostlyelixir_retaliation_buff" then
                        local retaliation = SpawnPrefab("abigail_retaliation")
                        retaliation:SetRetaliationTarget(data.attacker)
                        inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")
                    else
                        inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")
                    end
                end
            elseif (inst.components.health == nil or not inst.components.health:IsDead()) then
                local elixir_buff = ghost:GetDebuff("elixir_buff")
                -- if hardmode then consumeghostlybondtime(inst.components.ghostlybond, 3) end
                inst:AddDebuff("forcefield", elixir_buff ~= nil and elixir_buff.potion_tunings.shield_prefab or "abigailforcefield")
            end
        end
    end
    local function on_ghostlybond_level_change(inst)
        if inst.components.ghostlybond and not (inst:HasTag("playerghost") or inst.sg:HasStateTag("ghostbuild")) then
            local light_vals = TUNING.ABIGAIL_LIGHTING[inst.components.ghostlybond.bondlevel] or TUNING.ABIGAIL_LIGHTING[1]
            if light_vals.r ~= 0 and inst.components.ghostlybond.summoned == true and inst.components.ghostlybond.notsummoned == false then
                if not (inst._abigaillight2hm and inst._abigaillight2hm:IsValid()) then inst._abigaillight2hm = SpawnPrefab("deathcurselight2hm") end
                inst._abigaillight2hm.entity:SetParent(inst.entity)
                inst._abigaillight2hm.Light:Enable(true)
                inst._abigaillight2hm.Light:SetRadius(light_vals.r)
                inst._abigaillight2hm.Light:SetIntensity(light_vals.i)
                inst._abigaillight2hm.Light:SetFalloff(light_vals.f)
                inst._abigaillight2hm.Light:SetColour(180 / 255, 195 / 255, 225 / 255)
            elseif inst._abigaillight2hm and inst._abigaillight2hm:IsValid() then
                inst._abigaillight2hm:Remove()
                inst._abigaillight2hm = nil
            end
        end
    end
    -- 温蒂共享阿比盖尔光源和防护BUFF
    AddPrefabPostInit("wendy", function(inst)
        if not TheWorld.ismastersim or not inst.components.ghostlybond then return inst end
        inst:ListenForEvent("attacked", OnAttacked)
        inst:DoTaskInTime(0, on_ghostlybond_level_change)
        inst:ListenForEvent("ghostlybond_level_change", on_ghostlybond_level_change)
        local oldonsummoncompletefn = inst.components.ghostlybond.onsummoncompletefn
        local oldonrecallcompletefn = inst.components.ghostlybond.onrecallcompletefn
        inst.components.ghostlybond.onsummoncompletefn = function(inst, ...)
            if oldonsummoncompletefn then oldonsummoncompletefn(inst, ...) end
            on_ghostlybond_level_change(inst)
        end
        inst.components.ghostlybond.onrecallcompletefn = function(inst, ...)
            if oldonrecallcompletefn then oldonrecallcompletefn(inst, ...) end
            on_ghostlybond_level_change(inst)
        end
    end)
    local containers = require("containers")
    if containers.params.sisturn.itemtestfn then
        local olditemtestfn = containers.params.sisturn.itemtestfn
        containers.params.sisturn.itemtestfn = function(container, item, slot)
            return olditemtestfn(container, item, slot) or item.prefab == "ghostflower"
        end
    end
end