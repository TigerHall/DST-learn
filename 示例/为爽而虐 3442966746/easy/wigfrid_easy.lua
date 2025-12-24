local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 薇格弗德激励值脱战不掉落
if GetModConfigData("Wigfrid Inspiration Not Drop") then
    TUNING.WATHGRITHR_SANITY = 150
    TUNING.INSPIRATION_DRAIN_RATE = 0
    -- 激励值会受到非战斗行为的影响
    local EXCLUDED_TARGETS = {
        "hutch",            
        "chester",          
        "punchingbag",
        "punchingbag_lunar",
        "punchingbag_shadow"
    }

    local function IsExcludedTarget(target)
        return target and target.prefab and table.contains(EXCLUDED_TARGETS, target.prefab)
    end    
    AddPrefabPostInit("wathgrithr", function(inst)
        inst:ListenForEvent("onattackother", function(attacker, data)
            if data and data.target and IsExcludedTarget(data.target) then
                if inst.components.singinginspiration then
                    inst.components.singinginspiration:DoDelta(-5)
                end
            end
        end)
    end)
end

-- 薇格弗德骑乘冲刺
if GetModConfigData("Wigfrid Ride Right Dodge") then
    local cd = GetModConfigData("Wigfrid Ride Right Dodge")
    cd = (cd == true or cd == false) and 1.5 or cd
    AddPrefabPostInit("wathgrithr", function(inst)
        AddDodgeAbility(inst)
        inst.rightaction2hm_cooldown = cd
        inst.rightaction2hm_beefalo = true
    end)
end

-- 女武神右键自己战士重奏，重奏粗鲁插曲加头盔,重奏惊心独白加长矛
local wigfrid_rightself = GetModConfigData("Wigfrid Right Self Reprise")
local wigfrid_hat = GetModConfigData("Rude Interlude Provide Battle Helm")
local wigfrid_spear = GetModConfigData("Startling Soliloquy Provide Battle Spear")
local reprisesongfns = {}
local reprisesongtypes = {}
if wigfrid_rightself or wigfrid_hat or wigfrid_spear then
    local song_defs = require("prefabs/battlesongdefs").song_defs
    -- 没有生效的直接战歌不再有任何消耗了;支持覆盖效果
    local needconsume
    local function canceloverridesongfntask(inst)
        inst.canceloverridesongfntask2hm = nil
        if inst.overridesongfn2hm then inst.overridesongfn2hm = nil end
        if inst.rightselftype2hm then inst.rightselftype2hm:set(0) end
    end
    AddComponentPostInit("singinginspiration", function(self)
        if wigfrid_rightself then
            local CanAddSong = self.CanAddSong
            self.CanAddSong = function(self, songdata, inst, ...)
                if inst and inst.overridesongfn2hm and self.current >= 100 / 3 then return true end
                return CanAddSong(self, songdata, inst, ...)
            end
        end
        local OnAddInstantSong = self.OnAddInstantSong
        self.OnAddInstantSong = function(self, songdata, inst, ...)
            if wigfrid_rightself and inst then
                if inst.overridesongfn2hm then
                    -- 重复操作确认修理武器或护甲
                    inst.overridesongfn2hm(self, self.inst)
                    self.inst.overridesongfn2hm = inst.overridesongfn2hm
                    if self.inst.canceloverridesongfntask2hm then self.inst.canceloverridesongfntask2hm:Cancel() end
                    self.inst.canceloverridesongfntask2hm = self.inst:DoTaskInTime(12, canceloverridesongfntask)
                    return
                elseif reprisesongfns[inst.prefab] and reprisesongfns[inst.prefab].fn then
                    -- 角色进入可以修理武器或护甲的状态
                    self.inst.overridesongfn2hm = reprisesongfns[inst.prefab].fn
                    local type = reprisesongfns[inst.prefab].type
                    if self.inst.rightselftype2hm and type and reprisesongtypes[type] then self.inst.rightselftype2hm:set(type) end
                    if self.inst.canceloverridesongfntask2hm then self.inst.canceloverridesongfntask2hm:Cancel() end
                    self.inst.canceloverridesongfntask2hm = self.inst:DoTaskInTime(12, canceloverridesongfntask)
                end
            end
            needconsume = nil
            if songdata and songdata.ONINSTANT and not songdata.help2hm then
                songdata.help2hm = true
                local old = songdata.ONINSTANT
                songdata.ONINSTANT = function(...)
                    old(...)
                    needconsume = true
                end
            end
            self:InstantInspire(songdata)
            if needconsume then
                local old = self.InstantInspire
                self.InstantInspire = nilfn
                OnAddInstantSong(self, songdata, inst, ...)
                self.InstantInspire = old
                return true
            end
        end
    end)
    -- 重复吟唱BUFF(失败)会取消此BUFF
    ACTIONS.SING_FAIL.fn = function(act)
        local self = act.doer and act.doer.components.singinginspiration
        if act.invobject and self ~= nil then
            local songdata = act.invobject.songdata
            if songdata and songdata.NAME and not songdata.INSTANT then
                if #self.active_songs == 1 and self.active_songs[1].NAME == songdata.NAME then
                    self:PopSong()
                elseif self:IsSongActive(songdata) then
                    local active_songs = {}
                    for i = #self.active_songs, 1, -1 do
                        if self.active_songs[i].NAME ~= songdata.NAME then table.insert(active_songs, self.active_songs[i].ITEM_NAME) end
                        self:PopSong()
                    end
                    for i = #active_songs, 1, -1 do
                        local songdata = song_defs[active_songs[i]]
                        if songdata ~= nil then self:AddSong(songdata, true) end
                    end
                end
            end
        end
        return true
    end
    -- 吟唱新BUFF(成功)无BUFF栏会取消最旧的BUFF
    AddStategraphPostInit("wilson", function(sg)
        local sing_pre = sg.states.sing_pre.onenter
        sg.states.sing_pre.onenter = function(inst, ...)
            sing_pre(inst, ...)
            inst.sg:AddStateTag("temp_invincible")
            local buffaction = inst:GetBufferedAction()
            local songdata = buffaction and buffaction.invobject and buffaction.invobject.songdata or nil
            local self = inst.components.singinginspiration
            if self and songdata and not songdata.INSTANT and not self:IsSongActive(songdata) then
                self.available_slots = self.CalcAvailableSlotsForInspirationFn(self.inst, self:GetPercent())
                if self.available_slots > 0 and #self.active_songs >= self.available_slots then
                    local active_songs = {}
                    for i = #self.active_songs, 1, -1 do
                        table.insert(active_songs, self.active_songs[i].ITEM_NAME)
                        self:PopSong()
                    end
                    for i = #active_songs - 1, 1, -1 do
                        local songdata = song_defs[active_songs[i]]
                        if songdata ~= nil then self:AddSong(songdata, true) end
                    end
                end
            end
        end
        -- local sing_fail = sg.states.sing_fail.onenter
        -- sg.states.sing_fail.onenter = function(inst, ...)
        --     sing_fail(inst, ...)
        --     inst.sg:AddStateTag("temp_invincible")
        -- end
        local sing = sg.states.sing.onenter
        sg.states.sing.onenter = function(inst, ...)
            sing(inst, ...)
            inst.sg:AddStateTag("temp_invincible")
        end
        -- local cantsing = sg.states.cantsing.onenter
        -- sg.states.cantsing.onenter = function(inst, ...)
        --     cantsing(inst, ...)
        --     inst.sg:AddStateTag("temp_invincible")
        -- end
    end)

    -- 修复使用粗鲁插曲导致的崩溃
    local function IsHoldingPocketRummageActionItem2hm(holder, item)
        local owner = item.components.inventoryitem and item.components.inventoryitem.owner or nil
        return owner and -- 加判空
        (owner == holder or (owner.components.inventoryitem == nil and owner.entity:GetParent() == holder))
    end
    AddStategraphPostInit("wilson", function(sg)
        local UpvalueHacker = require "tools/upvaluehacker"
        local _onexit = sg.states.start_pocket_rummage.onexit
        if type(_onexit) == "function" then
            if UpvalueHacker.GetUpvalue(_onexit, "CheckPocketRummageMem") then
                local fn, i, prv = UpvalueHacker.GetUpvalue(_onexit, "CheckPocketRummageMem")
                if UpvalueHacker.GetUpvalue(fn, "IsHoldingPocketRummageActionItem") then
                    UpvalueHacker.SetUpvalue(fn, IsHoldingPocketRummageActionItem2hm, "IsHoldingPocketRummageActionItem")
                end
            end
        end
    end)
    
    -- 谱子服务器不处理图标，客户端处理图标
    local function itemtilefn(inst, self)
        local text
        if inst.songdata and inst.replica.inventoryitem and ThePlayer and ThePlayer:IsValid() and ThePlayer:HasTag("battlesinger") and ThePlayer.GetInspiration and
            ThePlayer.GetInspirationSong and ThePlayer.CalcAvailableSlotsForInspiration then
            local cansongbuffs = ThePlayer:CalcAvailableSlotsForInspiration()
            local canuse = (inst.songdata.RESTRICTED_TAG == nil or ThePlayer:HasTag(inst.songdata.RESTRICTED_TAG)) and
                               (inst.songdata.INSTANT and (ThePlayer:GetInspiration() >= inst.songdata.DELTA) or (cansongbuffs > 0))
            local newimage = canuse and inst.prefab or (inst.prefab .. "_unavaliable")
            if inst.replica.inventoryitem.overrideimage ~= (newimage .. ".tex") then inst.replica.inventoryitem:OverrideImage(newimage) end
            if not inst.songdata.INSTANT then
                local songs = {}
                for i = 1, cansongbuffs, 1 do
                    local songdata = ThePlayer:GetInspirationSong(i)
                    if songdata and songdata.ITEM_NAME then table.insert(songs, songdata.ITEM_NAME) end
                end
                if not canuse then
                    text = ""
                elseif table.contains(songs, inst.prefab) then
                    local idx = 0
                    for i, v in ipairs(songs) do if v == inst.prefab then idx = i end end
                    text = tostring(idx)
                elseif cansongbuffs > #songs then
                    text = "+"
                elseif cansongbuffs > 0 then
                    text = "0"
                else
                    text = ""
                end
            end
            if not self.imglisten2hm then
                self.imglisten2hm = true
                self.inst:ListenForEvent("inspirationdelta", function() if self.refreshitemtile2hm then self.refreshitemtile2hm(self) end end, ThePlayer)
                self.inst:ListenForEvent("inspirationsongchanged", function() if self.refreshitemtile2hm then self.refreshitemtile2hm(self) end end, ThePlayer)
            end
        end
        return nil, text
    end
    local function processsong(inst)
        inst.itemtilefn2hm = itemtilefn
        if not TheWorld.ismastersim then return end
        if inst.components.inventoryitem then
            local ChangeImageName = inst.components.inventoryitem.ChangeImageName
            inst.components.inventoryitem.ChangeImageName = function(self, prefab, ...)
                if prefab == (self.inst.prefab .. "_unavaliable") then return ChangeImageName(self, self.inst.prefab, ...) end
                return ChangeImageName(self, prefab, ...)
            end
        end
        inst:RemoveEventCallback("ondropped", inst.UpdateInvImage)
        inst.updateinvimage = nilfn
    end
    for k, v in pairs(song_defs) do AddPrefabPostInit(k, processsong) end
end
if wigfrid_rightself then
    -- 女武神右键自己战士重奏，最近嘲讽或恐惧过则重奏嘲讽或恐惧
    AddRightSelfAction("wathgrithr", 3, "sing_pre", function(inst, act)
        if TheWorld.ismastersim and act.doer and act.doer:IsValid() then
            local song = SpawnPrefab("battlesong_instant_revive")
            if song ~= nil then
                song.persists = false
                song:RemoveFromScene()
                song:DoTaskInTime(6, song.Remove)
                -- 支持覆盖效果
                if act.doer.overridesongfn2hm then
                    song.overridesongfn2hm = act.doer.overridesongfn2hm
                elseif song.components.rechargeable and act.doer.components.timer and act.doer.components.timer:TimerExists("instantrevive2hm") then
                    song.components.rechargeable:Discharge(act.doer.components.timer:GetTimeLeft("instantrevive2hm"))
                end
                act.invobject = song
                inst.rightselfaction2hm_handler = "sing_pre"
            else
                inst.rightselfaction2hm_handler = "sing_fail"
            end
        else
            inst.rightselfaction2hm_handler = "sing_fail"
        end
    end, function(act)
        if act.invobject and act.invobject.prefab == "battlesong_instant_revive" then
            local result, reason = ACTIONS.SING.fn(act)
            if result and act.invobject and not act.invobject.overridesongfn2hm and act.invobject.components.rechargeable and
                not act.invobject.components.rechargeable:IsCharged() and act.doer and act.doer.components.timer then
                act.doer.components.timer:StopTimer("instantrevive2hm")
                act.doer.components.timer:StartTimer("instantrevive2hm", TUNING.SKILLS.WATHGRITHR.BATTLESONG_INSTANT_COOLDOWN_HIGH)
            end
            return result, reason
        end
    end, STRINGS.NAMES.BATTLESONG_INSTANT_REVIVE)
    local function rightselfstrfn2hm(act)
        if act.doer and act.doer.rightselftype2hm then
            local type = act.doer.rightselftype2hm:value()
            if reprisesongtypes[type] then return reprisesongtypes[type] end
        end
    end
    AddPrefabPostInit("wathgrithr", function(inst)
        inst.rightselfstrfn2hm = rightselfstrfn2hm
        inst.rightselftype2hm = net_byte(inst.GUID, "rightself.type2hm")
        if not TheWorld.ismastersim then return end
        inst.rightselftype2hm:set(0)
    end)
end
if wigfrid_rightself and (wigfrid_hat or wigfrid_spear) then
    -- 特效
    local function addfx(target, fxname)
        if target and target:IsValid() then
            local x, y, z = target.Transform:GetWorldPosition()
            local fx = SpawnPrefab(fxname)
            if fx then fx.Transform:SetPosition(x, y, z) end
        end
    end
    local function AddEnemyDebuffFx(fx, target) target:DoTaskInTime(math.random() * 0.25, addfx, fx) end
    -- 某些友军可以给予武器
    local weaponprefabs = {}
    if hardmode and GetModConfigData("monster_change") and GetModConfigData("pigman") then
        table.insert(weaponprefabs, "pigman")
        table.insert(weaponprefabs, "bunnyman")
    end
    if GetModConfigData("Trade Fish with Merm") then table.insert(weaponprefabs, "merm") end
    -- 武神专属装备列表
    local wigfrid_helmets = {
        "wathgrithrhat",            -- 战斗头盔
        "wathgrithr_improvedhat",   -- 统帅头盔
    }

    local wigfrid_weapons = {
        "spear_wathgrithr",                    -- 战斗长矛
        "spear_wathgrithr_lightning",          -- 奔雷矛
        "spear_wathgrithr_lightning_charged",  -- 充能奔雷矛
        "wathgrithr_shield",                   -- 战斗圆盾
    }
    
    -- 检查是否为武神专属头盔
    local function IsWigfridHelmet(prefab)
        return table.contains(wigfrid_helmets, prefab)
    end
    
    -- 检查是否为武神专属武器
    local function IsWigfridWeapon(prefab)
        return table.contains(wigfrid_weapons, prefab)
    end
    
    local function repairarmorequip(self, equip, target)
        if equip.components.armor and not equip.components.armor:IsIndestructible() and IsWigfridHelmet(equip.prefab) then
            local oldpercent = equip.components.armor:GetPercent()
            if oldpercent < 1 then
                equip.components.armor:SetPercent(math.max(oldpercent, math.min(1, oldpercent + (target == self.inst and 0.5 or 0.25))))
                local newpercent = equip.components.armor:GetPercent()
                if newpercent > oldpercent then
                    -- 统一消耗33%激励值
                    self:DoDelta(-100 / 3)
                    AddEnemyDebuffFx("battlesong_instant_panic_fx", target)
                    -- 移除临时耐久设定
                    -- makebackpercent(equip, target, oldpercent)
                    return true
                end
            end
        end
    end
    -- 重奏嘲讽可以修理护甲
    local function dohelparmor(self, inst)
        local dohelp
        local persistentdata = self.inst.components.persistent2hm.data
        if persistentdata.instantrepairgoodtime then persistentdata.instantrepairgoodtime = nil end
        local headequip = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        -- 记录皮肤
        local hatdata = persistentdata.hat
        if headequip and headequip.prefab == "wathgrithrhat" then
            hatdata = {skinname = headequip.skinname, skin_id = headequip.skin_id, alt_skin_ids = headequip.alt_skin_ids}
            persistentdata.hat = hatdata
        end
        local oldPVP2hm = TUNING.oldPVP2hm
        TUNING.oldPVP2hm = true
        local targets = self:FindFriendlyTargetsToInspire()
        TUNING.oldPVP2hm = oldPVP2hm
        local oldcurrent = self.current
        for _, target in ipairs(targets) do
            if target.components.inventory and not target:IsInLimbo() then
                local equip = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if equip ~= nil then
                    if repairarmorequip(self, equip, target) then
                        if self.current <= 0 then break end
                        dohelp = true
                    end
                else
                    local hat
                    if hatdata then
                        hat = SpawnPrefab("wathgrithrhat", hatdata.skinname, hatdata.skin_id, self.inst.userid)
                        if hatdata.alt_skin_ids then hat.alt_skin_ids = hatdata.alt_skin_ids end
                    else
                        hat = SpawnPrefab("wathgrithrhat")
                    end
                    hat.Transform:SetPosition(target.Transform:GetWorldPosition())
                    hat.components.armor:SetPercent(target == self.inst and 0.5 or 0.25)
                    if not target.components.inventory:Equip(hat) then
                        hat:Remove()
                    else
                        -- 统一消耗33%激励值
                        self:DoDelta(-100 / 3)
                        AddEnemyDebuffFx("battlesong_instant_panic_fx", target)
                        if self.current <= 0 then break end
                    end
                    dohelp = true
                end
                -- 检查手部的盾牌装备
                local handequip = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if handequip ~= nil and IsWigfridHelmet(handequip.prefab) and repairarmorequip(self, handequip, target) then
                    if self.current <= 0 then break end
                    dohelp = true
                end
            end
        end
        if dohelp then
            -- 确保每次修复至少消耗33%激励值
            if oldcurrent - self.current < 100 / 3 then 
                self.current = math.max(0, oldcurrent - 100 / 3) 
            end
        end
    end
    -- -- 护甲持续可修理特效
    -- local function armorcanhelpfx(self, inst) 
    --     if inst.wigfridhelpfx2hm ~= nil then inst.wigfridhelpfx2hm:Remove() end
    --     inst.wigfridhelpfx2hm = SpawnPrefab("tophat_shadow_fx")
    --     inst.wigfridhelpfx2hm.entity:SetParent(inst.entity)
    --     inst.wigfridhelpfx2hm.Follower:FollowSymbol(inst.GUID, "swap_object", 50, -25, 0)
    -- end
    -- 重奏恐惧可以修理武器
    local function dohelpweapon(self, inst)
        local dohelp
        local persistentdata = self.inst.components.persistent2hm.data
        if persistentdata.instantrepairgoodtime then persistentdata.instantrepairgoodtime = nil end
        local handequip = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        local weapondata = persistentdata.spear
        if handequip and handequip.prefab == "spear_wathgrithr" then
            weapondata = {skinname = handequip.skinname, skin_id = handequip.skin_id, alt_skin_ids = handequip.alt_skin_ids}
            persistentdata.spear = weapondata
        end
        local oldPVP2hm = TUNING.oldPVP2hm
        TUNING.oldPVP2hm = true
        local targets = self:FindFriendlyTargetsToInspire()
        TUNING.oldPVP2hm = oldPVP2hm
        local oldcurrent = self.current
        for _, target in ipairs(targets) do
            if target.components.inventory and
                ((target:HasTag("player") and target.components.inventory.isvisible) or table.contains(weaponprefabs, target.prefab)) and not target:IsInLimbo() then
                local equip = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equip ~= nil then
                    -- 限定修复武神专属武器
                    if equip.components.finiteuses and IsWigfridWeapon(equip.prefab) then
                        local oldpercent = equip.components.finiteuses:GetPercent()
                        if oldpercent < 1 then
                            equip.components.finiteuses:SetPercent(math.max(oldpercent, math.min(1, oldpercent + (target == self.inst and 0.5 or 0.25))))
                            local newpercent = equip.components.finiteuses:GetPercent()
                            if newpercent > oldpercent then
                                -- 统一消耗33%激励值
                                self:DoDelta(-100 / 3)
                                AddEnemyDebuffFx("battlesong_instant_taunt_fx", target)
                                -- 移除临时耐久设定
                                -- makebackpercent(equip, target, oldpercent)
                                if self.current <= 0 then break end
                                dohelp = true
                            end
                        end
                    end
                else
                    local spear
                    if weapondata then
                        spear = SpawnPrefab("spear_wathgrithr", weapondata.skinname, weapondata.skin_id, self.inst.userid)
                        if weapondata.alt_skin_ids then spear.alt_skin_ids = weapondata.alt_skin_ids end
                    else
                        spear = SpawnPrefab("spear_wathgrithr")
                    end
                    spear.Transform:SetPosition(target.Transform:GetWorldPosition())
                    spear.components.finiteuses:SetPercent(target == self.inst and 0.5 or 0.25)
                    if not target.components.inventory:Equip(spear) then
                        spear:Remove()
                    else
                        -- 统一消耗33%激励值
                        self:DoDelta(-100 / 3)
                        AddEnemyDebuffFx("battlesong_instant_taunt_fx", target)
                        if self.current <= 0 then break end
                    end
                    dohelp = true
                end
            end
        end
        if dohelp then
            -- 确保每次修复至少消耗33%激励值
            if oldcurrent - self.current < 100 / 3 then 
                self.current = math.max(0, oldcurrent - 100 / 3) 
            end
        end
    end
    -- -- 武器持续可修理特效
    -- local function weaponcanhelpfx(self, inst)
    --     if inst.wigfridhelpfx2hm ~= nil then inst.wigfridhelpfx2hm:Remove() end
    --     inst.wigfridhelpfx2hm = SpawnPrefab("tophat_shadow_fx")
    --     inst.wigfridhelpfx2hm.entity:SetParent(inst.entity)
    --     inst.wigfridhelpfx2hm.Follower:FollowSymbol(inst.GUID, "swap_hat", 0, -100, 0)
    -- end
    if wigfrid_hat then
        reprisesongfns.battlesong_instant_taunt = {fn = dohelparmor, type = 1}
        reprisesongtypes[1] = "BATTLESONG_INSTANT_TAUNT"
        STRINGS.ACTIONS.RIGHTSELFACTION2HM.BATTLESONG_INSTANT_TAUNT = STRINGS.NAMES.BATTLESONG_INSTANT_REVIVE .. " " .. STRINGS.NAMES.BATTLESONG_INSTANT_TAUNT
    end
    if wigfrid_spear then
        reprisesongfns.battlesong_instant_panic = {fn = dohelpweapon, type = 2}
        reprisesongtypes[2] = "BATTLESONG_INSTANT_PANIC"
        STRINGS.ACTIONS.RIGHTSELFACTION2HM.BATTLESONG_INSTANT_PANIC = STRINGS.NAMES.BATTLESONG_INSTANT_REVIVE .. " " .. STRINGS.NAMES.BATTLESONG_INSTANT_PANIC
    end
end

-- 女武神直接右键矛盾
if GetModConfigData("aoespell change") then
    local function disableStatus(inst)
        inst.components.spellcaster.canuseontargets = false
        inst.components.spellcaster.canuseondead = false
        inst.components.spellcaster.canuseonpoint = false
        inst.components.spellcaster.canuseonpoint_water = false
        inst.components.spellcaster.spell = nil
        inst.components.spellcaster.spellfn = nil
        inst.reticule2hm:set(false)
    end
    local function enableStatus(inst)
        inst.components.spellcaster.spell = nilfn
        inst.components.spellcaster.spellfn = nilfn
        inst.components.spellcaster.canuseontargets = true
        inst.components.spellcaster.canuseondead = true
        inst.components.spellcaster.canuseonpoint = true
        inst.components.spellcaster.canuseonpoint_water = inst.components.aoetargeting and inst.components.aoetargeting.allowwater or false
        inst.reticule2hm:set(true)
    end
    local function UpdateStatus(inst)
        if not inst:IsValid() then return end
        local owner = inst.components.inventoryitem.owner
        -- 非常奇怪，莫名其妙会aoetargeting被禁用
        -- inst.components.rechargeable and inst.components.rechargeable:IsCharged()
        if inst.components.aoetargeting and inst.components.aoetargeting:IsEnabled() and inst.components.equippable and inst.components.equippable:IsEquipped() and
            owner and owner:IsValid() and owner:HasTag("player") and not owner:HasTag("playerghost") and
            (inst.components.aoetargeting.allowriding or not (owner.components.rider and owner.components.rider:IsRiding())) then
            enableStatus(inst)
        else
            disableStatus(inst)
        end
    end
    local function onequip(inst, data)
        if data.owner and data.owner:HasTag("player") then
            if not (inst.components.aoetargeting and inst.components.aoetargeting.allowriding) then
                inst:ListenForEvent("mounted", inst._updatestatus, data.owner)
                inst:ListenForEvent("dismounted", inst._updatestatus, data.owner)
            end
            inst:ListenForEvent("death", inst._updatestatus, data.owner)
        end
        UpdateStatus(inst)
    end
    local function onunequip(inst, data)
        if data.owner and data.owner:HasTag("player") then
            inst:RemoveEventCallback("mounted", inst._updatestatus, data.owner)
            inst:RemoveEventCallback("dismounted", inst._updatestatus, data.owner)
            inst:RemoveEventCallback("death", inst._updatestatus, data.owner)
        end
        UpdateStatus(inst)
    end
    local function EnableReticule(inst, enable)
        if inst.components.aoetargeting then
            if enable then
                if inst.components.reticule == nil then
                    inst:AddComponent("reticule")
                    for k, v in pairs(inst.components.aoetargeting.reticule) do inst.components.reticule[k] = v end
                    inst.components.reticule.ispassableatallpoints = inst.components.aoetargeting.alwaysvalid
                    if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.replica and ThePlayer.replica.inventory and
                        ThePlayer.replica.inventory:IsHolding(inst) then ThePlayer.components.playercontroller:RefreshReticule() end
                end
            else
                if inst.components.reticule ~= nil then
                    inst:RemoveComponent("reticule")
                    if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.replica and ThePlayer.replica.inventory and
                        ThePlayer.replica.inventory:IsHolding(inst) then ThePlayer.components.playercontroller:RefreshReticule() end
                end
            end
        end
    end
    local function actfn(act, inst)
        if act.action == ACTIONS.CASTSPELL then
            act.distance = math.huge
            if not act.pos and act.target then
                act.pos = DynamicPosition(not TheNet:IsDedicated() and TheInput:GetWorldPosition() or act.target:GetPosition())
            end
        end
    end
    local function OnreticuleDirty(inst) EnableReticule(inst, inst.reticule2hm:value()) end
    local function processaoetargeting(inst)
        if inst.components.aoetargeting == nil then return end
        inst.components.aoetargeting.StopTargeting = nilfn
        inst.components.aoetargeting.StartTargeting = nilfn
        inst.actfn2hm = actfn
        inst.spellaoe2hm = true
        inst.spelltype = string.upper(inst.prefab)
        if STRINGS.ACTIONS.CASTSPELL[inst.spelltype] == nil then STRINGS.ACTIONS.CASTSPELL[inst.spelltype] = STRINGS.ACTIONS.CASTAOE[inst.spelltype] end
        inst.reticule2hm = net_bool(inst.GUID, "spell.reticule2hm", "spellreticule2hmdirty")
        if not TheNet:IsDedicated() then inst:ListenForEvent("spellreticule2hmdirty", OnreticuleDirty) end
        if not TheWorld.ismastersim then return end
        if not inst.components.spellcaster and inst.components.aoespell then
            inst:AddComponent("spellcaster")
            inst.components.spellcaster.spell = nilfn
            inst.components.spellcaster.spellfn = nilfn
            inst.components.spellcaster.canuseontargets = true
            inst.components.spellcaster.canuseondead = true
            inst.components.spellcaster.canuseonpoint = true
            inst.components.spellcaster.canuseonpoint_water = inst.components.aoetargeting.allowwater
            inst.components.spellcaster.canusefrominventory = false
            inst.components.spellcaster.can_cast_fn = truefn
            local range = inst.components.aoetargeting.range
            inst.components.spellcaster.CanCast = function(self, doer, target, pos)
                if pos and doer and doer:IsValid() and not inst:HasTag("shield") then
                    local x, y, z = pos:Get()
                    local x1, y1, z1 = doer.Transform:GetWorldPosition()
                    local rangesq = distsq(x, z, x1, z1)
                    if rangesq == 0 then
                        local rot = doer.Transform:GetRotation() * DEGREES
                        pos.x = x1 + math.cos(rot) * range
                        pos.z = z1 - math.sin(rot) * range
                    else
                        local rate = range / math.sqrt(rangesq)
                        pos.x = x1 + (x - x1) * rate
                        pos.z = z1 + (z - z1) * rate
                    end
                end
                local alwayspassable, allowwater, deployradius, allowriding
                local aoetargeting = self.inst.components.aoetargeting
                if aoetargeting then
                    if not aoetargeting:IsEnabled() then return false end
                    alwayspassable = aoetargeting.alwaysvalid
                    allowwater = aoetargeting.allowwater
                    deployradius = aoetargeting.deployradius
                    allowriding = aoetargeting.allowriding
                end
                if not allowriding and doer.components.rider ~= nil and doer.components.rider:IsRiding() then return false end
                return TheWorld.Map:CanCastAtPoint(pos, alwayspassable, allowwater, deployradius)
            end
            local aoespellfn = inst.components.aoespell.spellfn
            inst.components.spellcaster.CastSpell = function(self, target, pos, doer)
                local success, reason = true, nil
                if aoespellfn then
                    success, reason = aoespellfn(self.inst, doer, pos)
                    if success == nil and reason == nil then success = true end
                end
                return success, reason
            end
            inst:RemoveComponent("aoespell")
            inst:ListenForEvent("enableddirty", UpdateStatus)
            inst:ListenForEvent("equipped", onequip)
            inst:ListenForEvent("unequipped", onunequip)
            inst._updatestatus = function() UpdateStatus(inst) end
        end
    end
    AddPrefabPostInit("spear_wathgrithr_lightning", processaoetargeting)
    AddPrefabPostInit("spear_wathgrithr_lightning_charged", processaoetargeting)
    AddPrefabPostInit("wathgrithr_shield", processaoetargeting)
    -- local fn = ACTIONS.CASTSPELL.fn
    -- ACTIONS.CASTSPELL.fn = function(act)
    --     if act and act.invobject and act.invobject.spellaoe2hm then return ACTIONS.CASTAOE.fn(act) end
    --     return fn(act)
    -- end
    AddStategraphPostInit("wilson", function(sg)
        local _OldCASTSPELL = sg.actionhandlers[ACTIONS.CASTSPELL].deststate
        local _OldCASTAOE = sg.actionhandlers[ACTIONS.CASTAOE].deststate
        sg.actionhandlers[ACTIONS.CASTSPELL].deststate = function(inst, action, ...)
            if action.invobject and action.invobject.spellaoe2hm then
                return _OldCASTAOE(inst, action, ...)
            else
                return _OldCASTSPELL(inst, action, ...)
            end
        end
        local onenter = sg.states.combat_lunge.onenter
        sg.states.combat_lunge.onenter = function(inst, data, ...) onenter(inst, data, ...) end
    end)
    AddStategraphPostInit("wilson_client", function(sg)
        local _OldCASTSPELL = sg.actionhandlers[ACTIONS.CASTSPELL].deststate
        local _OldCASTAOE = sg.actionhandlers[ACTIONS.CASTAOE].deststate
        sg.actionhandlers[ACTIONS.CASTSPELL].deststate = function(inst, action, ...)
            if action.invobject and action.invobject.spellaoe2hm then
                return _OldCASTAOE(inst, action, ...)
            else
                return _OldCASTSPELL(inst, action, ...)
            end
        end
    end)
    AddComponentPostInit("playercontroller", function(self)
        local IsAOETargeting = self.IsAOETargeting
        self.IsAOETargeting = function(self, ...) return IsAOETargeting(self, ...) and self.reticule ~= nil and self.reticule.inst.spellaoe2hm == nil end
    end)
end
