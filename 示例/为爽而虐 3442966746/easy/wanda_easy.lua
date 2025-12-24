local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 旺达不再持续衰老
if GetModConfigData("Wanda Don't Auto Drop Age") then AddComponentPostInit("oldager", function(self) self.base_rate = 0 end) end

-- 旺达不老表回温
if GetModConfigData("Ageless Watch Help Temperature") then
    AddPrefabPostInit("pocketwatch_heal", function(inst)
        if inst.components.pocketwatch then
            local cast = inst.components.pocketwatch.DoCastSpell
            inst.components.pocketwatch.DoCastSpell = function(inst, doer, ...)
                local result = cast(inst, doer, ...)
                if result and doer and doer:IsValid() and doer.components.temperature.current then
                    doer.components.temperature:SetTemperature(math.clamp(doer.components.temperature.current +
                                                                              (TUNING.BOOK_TEMPERATURE_AMOUNT - doer.components.temperature.current) / 3, 11, 59))
                    return true
                end
                return result
            end
        end
    end)
end

--旺达吃花瓣获得恶魔花瓣，解锁噩梦燃料配方
if GetModConfigData("wanda Eat Petals Get Dark Petals") then
    local function OnEat(inst, data)
        if data.food ~= nil and data.food.prefab == "petals" then inst.components.inventory:GiveItem(SpawnPrefab("petals_evil")) end
    end
    local function unlockrecipes(inst)
        if inst.components.builder then
            if not inst.components.builder:KnowsRecipe("nightmarefuel") and inst.components.builder:CanLearn("nightmarefuel") then
                inst.components.builder:UnlockRecipe("nightmarefuel")
            end
        end
    end
    AddPrefabPostInit("wanda", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("oneat", OnEat)
        inst:DoTaskInTime(0, unlockrecipes)
    end)
end

-- 旺达移除不妥协削弱
if GetModConfigData("Wanda removes UM nerf") then
    if not (TUNING.DSTU and TUNING.DSTU.WANDA_NERF) then return end

    -- 去除受到来自暗影生物的额外伤害
    AddComponentPostInit("combat", function(self)
        if not TheWorld.ismastersim then return end
        local _GetAttacked = self.GetAttacked
        function self:GetAttacked(attacker, damage, weapon, stimuli, ...)
            if attacker ~= nil and attacker:HasTag("shadow_aligned") and self.inst.prefab == "wanda" then
                damage = damage / 1.25
                return _GetAttacked(self, attacker, damage, weapon, stimuli, ...)
            else
                return _GetAttacked(self, attacker, damage, weapon, stimuli, ...)
            end
        end
    end)

    -- 去除警告表伤害削弱
    TUNING.POCKETWATCH_SHADOW_DAMAGE = 81.6
    -- 用原版的伤害计算覆盖妥协，改回表的伤害计算
    AddPrefabPostInit("wanda", function(inst)
        if inst.components.combat ~= nil then
            local _customdamagemultfn = inst.components.combat.customdamagemultfn
            inst.components.combat.customdamagemultfn = function(inst, target, weapon, multiplier, mount)
                if mount == nil then
                    if weapon ~= nil and weapon:HasTag("shadow_item") then -- 原本的 只改的这里
                        return inst.age_state == "old" and TUNING.WANDA_SHADOW_DAMAGE_OLD
                                or inst.age_state == "normal" and TUNING.WANDA_SHADOW_DAMAGE_NORMAL
                                or TUNING.WANDA_SHADOW_DAMAGE_YOUNG
                    end
                end
                if _customdamagemultfn ~= nil then return _customdamagemultfn(inst, target, weapon, multiplier, mount) end
            end
        end
    end)

    -- 去除二次机会表的额外配方材料,减少生命上限
    AddRecipePostInit("pocketwatch_revive", function(recipe) 
        for _, ingredient in pairs(recipe.ingredients) do
            if ingredient and ingredient.type == "pocketwatch_parts" and ingredient.amount then
                ingredient.amount = 1
            end
        end
    end)

    AddPrefabPostInit("pocketwatch_revive", function(inst)
        if not TheWorld.ismastersim then return end
        local Revive_DoCastSpell = inst.components.pocketwatch.DoCastSpell
        if inst.components.pocketwatch ~= nil then
            inst.components.pocketwatch.DoCastSpell = function(inst, doer, target)
                local healthpenaltymark = target.components.health and target.components.health:GetPenaltyPercent()
                target:DoTaskInTime(0, function()
                    -- 检测到复活后生命惩罚，减少生命惩罚
                    if target.components.health and healthpenaltymark and healthpenaltymark < target.components.health:GetPenaltyPercent() then
                        target.components.health:DeltaPenalty(-0.25)
                    end
                end)
                return Revive_DoCastSpell(inst, doer, target)
            end
        end
    end)
end

-- 旺达右键倒走
if GetModConfigData("Wanda Right Wrapback") and not GetModConfigData("Wanda Right Wrapfront") then
    AddPrefabPostInit("pocketwatch_warp", function(inst) -- 倒走表
        if not TheWorld.ismastersim then return end
        if inst.components.pocketwatch then
            local oldcast = inst.components.pocketwatch.DoCastSpell
            inst.components.pocketwatch.DoCastSpell = function(inst, doer)
                if doer then  -- 0.3秒无敌
                    doer.allmiss2hm = true
                    doer:DoTaskInTime(0.3, function(inst)
                        if doer.allmiss2hm then inst.allmiss2hm = nil end
                    end)
                end
                return oldcast(inst, doer)
            end
        end
    end)
    AddPrefabPostInit("wanda", function(inst)
        AddWrapAbility(inst)
        inst.rightaction2hm_cooldown = TUNING.POCKETWATCH_WARP_COOLDOWN
    end)
end

-- 旺达右键未来行走
if GetModConfigData("Wanda Right Wrapfront") then
    AddPrefabPostInit("wanda", function(inst)
        AddWrapFrontAbility(inst)
        inst.rightaction2hm_cooldown = GetModConfigData("Wanda Right Wrapfront")
        if inst.rightaction2hm_cooldown == true then inst.rightaction2hm_cooldown = TUNING.POCKETWATCH_WARP_COOLDOWN * 4 end
    end)
end

-- 旺达右键自身定位和溯源，用钟表匠工具自身可以解除定位
if GetModConfigData("Wanda Right Self Backtrek") then
    local NOTENTCHECK_CANT_TAGS = {"FX", "INLIMBO"}
    local function DelayedMarkTalker(player)
        if player.sg == nil or player.sg:HasStateTag("idle") then player.components.talker:Say(GetString(player, "ANNOUNCE_POCKETWATCH_MARK")) end
    end
    local function noentcheckfn(pt)
        return not TheWorld.Map:IsPointNearHole(pt) and #TheSim:FindEntities(pt.x, pt.y, pt.z, 1, nil, NOTENTCHECK_CANT_TAGS) == 0
    end
    local function DoCastSpell(inst, doer, target, pos)
        local recallmark = inst.components.recallmark
        if recallmark:IsMarked() then
            local pt = doer:GetPosition()
            local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 3 + math.random(), 16, false, true, noentcheckfn, true, true) or
                               FindWalkableOffset(pt, math.random() * 2 * PI, 5 + math.random(), 16, false, true, noentcheckfn, true, true) or
                               FindWalkableOffset(pt, math.random() * 2 * PI, 7 + math.random(), 16, false, true, noentcheckfn, true, true)
            if offset ~= nil then pt = pt + offset end
            if not Shard_IsWorldAvailable(recallmark.recall_worldid) then return false, "SHARD_UNAVAILABLE" end
            local portal = SpawnPrefab("pocketwatch_portal_entrance")
            portal.Transform:SetPosition(pt:Get())
            portal:SpawnExit(recallmark.recall_worldid, recallmark.recall_x, recallmark.recall_y, recallmark.recall_z)
            inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")
            inst.owner2hm.components.timer:StopTimer("selfportal2hm")
            inst.owner2hm.components.timer:StartTimer("selfportal2hm", TUNING.POCKETWATCH_RECALL_COOLDOWN * 3)
            inst:Remove()
            return true
        else
            local x, y, z = doer.Transform:GetWorldPosition()
            recallmark:MarkPosition(x, y, z)
            inst.owner2hm.components.persistent2hm.data.recallmark2hm = inst.components.recallmark:OnSave()
            inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/MarkPosition")
            doer:DoTaskInTime(12 * FRAMES, DelayedMarkTalker)
            return true
        end
    end
    AddPrefabPostInit("wanda", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
    end)
    local function delayremove(inst) inst:DoTaskInTime(0, inst.Remove) end
    local function onremove(inst) if inst.owner2hm then inst.owner2hm.selfwatch2hm = nil end end
    local function processwatch(inst, owner)
        inst.persists = false
        inst:AddTag("wandaself2hm")
        inst.owner2hm = owner
        owner.selfwatch2hm = inst
        inst.components.inventoryitem.canonlygoinpocket = true
        inst.components.inventoryitem:SetOnDroppedFn(delayremove)
        inst:ListenForEvent("onputininventory", delayremove)
        inst:ListenForEvent("ondropped", delayremove)
        inst.components.inventoryitem.onactiveitemfn = delayremove
        inst:ListenForEvent("onremove", onremove)
        -- 初始化数据
        if owner.components.persistent2hm.data.recallmark2hm then inst.components.recallmark:OnLoad(owner.components.persistent2hm.data.recallmark2hm) end
        inst.components.rechargeable:SetMaxCharge(TUNING.POCKETWATCH_RECALL_COOLDOWN * 3)
        inst.components.rechargeable:Discharge(owner.components.timer:GetTimeLeft("selfportal2hm") or 0)
        inst.components.pocketwatch.DoCastSpell = DoCastSpell
    end
    AddRightSelfAction("wanda", 3, "dolongaction", nil, function(act)
        if act.doer and act.doer.prefab == "wanda" and act.doer.components.inventory and not act.doer.selfwatch2hm then
            local watch = SpawnPrefab("pocketwatch_portal")
            if watch then
                act.doer.components.inventory:GiveItem(watch)
                processwatch(watch, act.doer)
                return true
            end
        end
        return false
    end, STRINGS.NAMES.POCKETWATCH_PORTAL)
    AddComponentPostInit("pocketwatch_dismantler", function(self)
        local oldDismantle = self.Dismantle
        self.Dismantle = function(self, target, doer, ...)
            if target and target.persists == false and target:HasTag("wandaself2hm") then
                target:Remove()
                -- 移除定位
                if target.owner2hm and target.owner2hm.prefab == "wanda" then target.owner2hm.components.persistent2hm.data.recallmark2hm = nil end
                SpawnPrefab("brokentool").Transform:SetPosition(doer.Transform:GetWorldPosition())
                return
            end
            return oldDismantle(self, target, doer, ...)
        end
    end)
end

-- 旺达复活自己
if GetModConfigData("Wanda Resurrect Self") then
    TUNING.POCKETWATCH_REVIVE_COOLDOWN = 32 * 60
    local enableallroles = GetModConfigData("Wanda Resurrect Self") == -1
    local tex = "pocketwatch_revive.tex"
    local function updateresurrectbuttonstatus(self)
        if self.owner and self.owner.canresurrectself2hm and self.resurrectbutton and self.resurrectbutton.button and self.resurrectbutton.button and
            self.resurrectbutton.text then
            if self.owner.canresurrectself2hm:value() then
                self.resurrectbutton.button:SetTextures(GetInventoryItemAtlas(tex), tex, nil, tex)
                self.resurrectbutton.text:SetString(TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_CONTROLLER_ATTACK) .. " " ..
                                                        STRINGS.NAMES.POCKETWATCH_REVIVE)
                self.resurrectbutton:SetTooltip(STRINGS.NAMES.POCKETWATCH_REVIVE)
            else
                self.resurrectbutton.button:SetTextures("images/hud.xml", "effigy_button_mouseover.tex", nil, "effigy_button.tex")
                self.resurrectbutton.text:SetString(TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_CONTROLLER_ATTACK) .. " " ..
                                                        STRINGS.ACTIONS.REMOTERESURRECT)
                self.resurrectbutton:SetTooltip(STRINGS.UI.HUD.ACTIVATE_RESURRECTION)
            end
        end
    end
    AddClassPostConstruct("widgets/statusdisplays", function(self)
        updateresurrectbuttonstatus(self)
        local EnableResurrect = self.EnableResurrect
        self.EnableResurrect = function(self, ...)
            EnableResurrect(self, ...)
            updateresurrectbuttonstatus(self)
        end
    end)
    local function refreshresurrectself2hmbutton(inst)
        if inst.HUD and inst.HUD.controls and inst.HUD.controls.status and inst.HUD.controls.status.EnableResurrect then
            inst.HUD.controls.status:EnableResurrect(inst.components.attuner and inst.components.attuner:HasAttunement("remoteresurrector"))
        end
    end
    local function ontimedone(inst, data)
        if data and data.name == "resurrectself2hmcd" and inst.canresurrectself2hm then inst.canresurrectself2hm:set(true) end
    end
    local function onwandadeath(inst)
        local reset_time = nil
        TheWorld:PushEvent("ms_setworldsetting", {setting = "reset_time", value = reset_time})
        TheWorld:PushEvent("ms_setworldresettime", reset_time)
    end
    local function onpreload(inst, data)
        if data and data.timer and data.timer.timers and data.timer.timers.resurrectself2hmcd then inst.canresurrectself2hm:set(false) end
    end
    local function hasresurrectbtn(inst)
        inst.canresurrectself2hm = net_bool(inst.GUID, "role.resurrectself2hm", "resurrectself2hmdirty")
        inst.canresurrectself2hm:set(true)
        if not TheNet:IsDedicated() then inst:ListenForEvent("resurrectself2hmdirty", refreshresurrectself2hmbutton) end
        if inst.components.attuner then
            local HasAttunement = inst.components.attuner.HasAttunement
            inst.components.attuner.HasAttunement = function(self, tag, ...)
                if tag == "remoteresurrector" and self.inst.canresurrectself2hm and self.inst.canresurrectself2hm:value() then return true end
                return HasAttunement(self, tag, ...)
            end
        end
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("timerdone", ontimedone)
        inst:ListenForEvent("ms_becameghost", onwandadeath)
        SetOnPreLoad(inst, onpreload)
    end
    if enableallroles then
        AddPlayerPostInit(hasresurrectbtn)
    else
        AddPrefabPostInit("wanda", hasresurrectbtn)
    end
    local fn = ACTIONS.REMOTERESURRECT.fn
    ACTIONS.REMOTERESURRECT.fn = function(act, ...)
        if act.doer and act.doer:IsValid() and act.doer.canresurrectself2hm and act.doer.canresurrectself2hm:value() and act.doer.components.timer and
            act.doer:HasTag("playerghost") and not act.doer:HasTag("reviving") then
            local pocketwatch_revive = SpawnPrefab("pocketwatch_revive")
            if pocketwatch_revive then
                pocketwatch_revive.persists = false
                pocketwatch_revive:RemoveFromScene()
                pocketwatch_revive:DoTaskInTime(30, pocketwatch_revive.Remove)
                local state
                if act.doer.sg and act.doer.sg.currentstate and act.doer.sg.currentstate.name == "remoteresurrect" then
                    state = act.doer.sg.currentstate
                    state.name = "remoteresurrect2hm"
                end
                if pocketwatch_revive.components.pocketwatch and pocketwatch_revive.components.pocketwatch:CastSpell(act.doer, act.doer, act.doer:GetPosition()) then
                    if state then state.name = "remoteresurrect" end
                    act.doer.components.timer:StopTimer("resurrectself2hmcd")
                    act.doer.canresurrectself2hm:set(false)
                    act.doer.components.timer:StartTimer("resurrectself2hmcd", TUNING.POCKETWATCH_REVIVE_COOLDOWN)
                    return true
                end
                if state then state.name = "remoteresurrect" end
            end
        end
        return fn(act, ...)
    end
end