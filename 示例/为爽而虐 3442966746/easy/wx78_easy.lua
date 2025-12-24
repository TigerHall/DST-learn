local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")


if TUNING.DSTU and TUNING.DSTU.WXLESS then     
    TUNING.WX78_HEALTH = 125
    TUNING.WX78_HUNGER = 125
    TUNING.WX78_SANITY = 125
    
    -- 修复妥协模组热能电路的问题
    local wx78_moduledefs = require("um_wx78_moduledefs")
    if wx78_moduledefs and wx78_moduledefs.module_definitions then
        for _, def in ipairs(wx78_moduledefs.module_definitions) do
            if def.name == "heat" then
                local old_activate = def.activatefn
                local old_deactivate = def.deactivatefn
                
                def.activatefn = function(inst, wx, isloading)
                    if wx.components.expertsailor == nil then
                        wx:AddComponent('expertsailor')     -- 划船增强
                    end
                    
                    -- 通过检查_heat_chips来判断是否是第一次激活
                    local is_first_activation = (wx._heat_chips or 0) == 0
                    
                    if is_first_activation then
                        -- 只在第一次激活时创建和注册事件监听器
                        if wx._ontempmodulechange_2hm == nil then
                            wx._ontempmodulechange_2hm = function(owner, data)
                                local deltatemp = data.new - data.last
                                local cur = owner.components.temperature.current
                                local workmult = 1
                                local extraheat_bonus = (owner._heat_chips or 1) - 1
                                
                                if deltatemp > 0 and not owner._heatcdtask_2hm then
                                    owner._heatcdtask_2hm = true
                                    owner:DoTaskInTime(0.05, function() owner._heatcdtask_2hm = nil end)
                                    -- 限制单次温度提升不超过5度
                                    local temp_boost = math.min(deltatemp * 4, 5)
                                    local new_temp = math.min(cur + temp_boost, 90)
                                    owner.components.temperature:SetTemperature(new_temp)
                                end
                                
                                -- 计算工作效率
                                local easing = require("easing")
                                workmult = (cur > 60 and 2.5 + extraheat_bonus) or
                                          (cur > 20 and easing.linear(cur - 20, 1, 2.5 + extraheat_bonus - 1, 40)) or 1
                                
                                if owner._cherriftchips and owner._cherriftchips > 0 then 
                                    workmult = workmult * (1.15 ^ owner._cherriftchips) 
                                end
                                
                                -- 使用固定的标记"wx78_heat_module_2hm"而不是inst，这样无论多少次激活，都只用一个倍率标记
                                local affected_actions = {ACTIONS.CHOP, ACTIONS.MINE, ACTIONS.HAMMER}
                                for _, act in ipairs(affected_actions) do
                                    owner.components.efficientuser:AddMultiplier(act, workmult, "wx78_heat_module_2hm")
                                    owner.components.workmultiplier:AddMultiplier(act, workmult, "wx78_heat_module_2hm")
                                end
                                
                                if workmult > 1 then
                                    owner.components.expertsailor:SetRowForceMultiplier(1 + workmult / 8)
                                    owner.components.expertsailor:SetRowExtraMaxVelocity(workmult / 6)
                                else
                                    owner.components.expertsailor:SetRowForceMultiplier(1)
                                    owner.components.expertsailor:SetRowExtraMaxVelocity(0)
                                end
                            end
                        end
                        
                        if wx._onworktemp_2hm == nil then
                            wx._onworktemp_2hm = function(owner, data)
                                local cur = owner.components.temperature.current
                                local tempmult = (cur >= 60 and 0.15) or (cur >= 50 and 0.25) or 0.3
                                local new_temp = math.min(cur + tempmult, 90)
                                owner.components.temperature:SetTemperature(new_temp)
                            end
                        end
                        
                        if wx._onattacktemp_2hm == nil then
                            wx._onattacktemp_2hm = function(owner, data)
                                local cur = owner.components.temperature.current
                                local tempmult = (cur >= 60 and 0.05) or (cur >= 50 and 0.1) or 0.15
                                local new_temp = math.min(cur + tempmult, 90)
                                owner.components.temperature:SetTemperature(new_temp)
                            end
                        end
                        
                        -- 只在第一次激活时注册监听器
                        wx:ListenForEvent("temperaturedelta", wx._ontempmodulechange_2hm)
                        wx:ListenForEvent("working", wx._onworktemp_2hm)
                        wx:ListenForEvent("onattackother", wx._onattacktemp_2hm)
                    end
                    
                    -- 每次激活累加计数
                    wx._heat_chips = (wx._heat_chips or 0) + 1
                    
                    -- 每次激活都添加干燥率和保温值
                    wx.components.moisture.maxDryingRate = wx.components.moisture.maxDryingRate + 0.1
                    wx.components.moisture.baseDryingRate = wx.components.moisture.baseDryingRate + 0.1
                    wx.components.temperature.inherentinsulation = wx.components.temperature.inherentinsulation + TUNING.INSULATION_MED
                    
                    if wx.AddTemperatureModuleLeaning ~= nil then
                        wx:AddTemperatureModuleLeaning(1)
                    end
                end
                
                def.deactivatefn = function(inst, wx)
                    -- 每次卸载都递减计数
                    wx._heat_chips = math.max(0, (wx._heat_chips or 0) - 1)
                    
                    -- 只在最后一次卸载时移除事件监听器
                    if wx._heat_chips == 0 then
                        wx:RemoveEventCallback("temperaturedelta", wx._ontempmodulechange_2hm)
                        wx:RemoveEventCallback("working", wx._onworktemp_2hm)
                        wx:RemoveEventCallback("onattackother", wx._onattacktemp_2hm)
                        
                        -- 立即清除工作倍率，妥协是延迟的
                        local affected_actions = {ACTIONS.CHOP, ACTIONS.MINE, ACTIONS.HAMMER}
                        for _, act in ipairs(affected_actions) do
                            if wx.components.efficientuser then
                                wx.components.efficientuser:RemoveMultiplier(act, "wx78_heat_module_2hm")
                            end
                            if wx.components.workmultiplier then
                                wx.components.workmultiplier:RemoveMultiplier(act, "wx78_heat_module_2hm")
                            end
                        end
                        
                        if wx.components.expertsailor then wx:RemoveComponent('expertsailor') end
                    end
                    

                    wx.components.moisture.maxDryingRate = wx.components.moisture.maxDryingRate - 0.1
                    wx.components.moisture.baseDryingRate = wx.components.moisture.baseDryingRate - 0.1
                    wx.components.temperature.inherentinsulation = wx.components.temperature.inherentinsulation - TUNING.INSULATION_MED
                    
                    if wx.AddTemperatureModuleLeaning ~= nil then
                        wx:AddTemperatureModuleLeaning(-1)
                    end
                end
                
                break
            end
        end
    end
end

-- WX-78拆电路板不消耗耐久不掉电力
if GetModConfigData("WX-78 Safe Remove Module") then
    local module_definitions = require("wx78_moduledefs").module_definitions
    for _, def in ipairs(module_definitions) do
        AddPrefabPostInit("wx78module_" .. def.name, function(inst)
            if not TheWorld.ismastersim then return end
            if inst.components.upgrademodule and inst.components.upgrademodule.onremovedfromownerfn then
                local oldfn = inst.components.upgrademodule.onremovedfromownerfn
                inst.components.upgrademodule.onremovedfromownerfn = function(inst, ...)
                    if TUNING.saferemoveupgrademodule2hm and inst.components.finiteuses then return end
                    oldfn(inst, ...)
                end
            end
        end)
    end
    ACTIONS.REMOVEMODULES.fn = function(act)
        if (act.invobject ~= nil and act.invobject.components.upgrademoduleremover ~= nil) and
            (act.doer ~= nil and act.doer.components.upgrademoduleowner ~= nil) then
            if act.doer.components.upgrademoduleowner:NumModules() > 0 then
                TUNING.saferemoveupgrademodule2hm = true
                act.doer.components.upgrademoduleowner:PopOneModule()
                TUNING.saferemoveupgrademodule2hm = nil
                return true
            else
                return false, "NO_MODULES"
            end
        end
        return false
    end
end

-- WX-78同种电路板融合升级
if GetModConfigData("WX-78 Integrated Upgrade Module Level") then
    -- 移速数值扩展
    local index = #TUNING.WX78_MOVESPEED_CHIPBOOSTS
    local diff = TUNING.WX78_MOVESPEED_CHIPBOOSTS[index] - TUNING.WX78_MOVESPEED_CHIPBOOSTS[index - 1]
    for i = index + 1, TUNING.WX78_MAXELECTRICCHARGE, 1 do
        TUNING.WX78_MOVESPEED_CHIPBOOSTS[i] = math.clamp(TUNING.WX78_MOVESPEED_CHIPBOOSTS[i - 1] + diff, 0, 10)
    end
    local function DisplayNameFn(inst)
        if inst.level2hm:value() ~= 1 then
            return inst.name .. " Lv" .. inst.level2hm:value()
        else
            return inst.name
        end
    end
    local function OnSave(inst, data)
        if inst.level2hm ~= nil then
            data.level = inst.level2hm:value()
        else
            data.level = 1
        end
    end
    local function OnLoad(inst, data) 
        if data ~= nil then 
            if data.level ~= nil then 
                -- 旧存档兼容：将高于3级的电路等级调整为3级
                local level = math.min(data.level, 3)
                inst.level2hm:set(level) 
            end 
        end 
    end
    local module_definitions = require("wx78_moduledefs").module_definitions
    local function itemtilefn(inst)
        local leveltext
        if inst.level2hm and inst.level2hm:value() >= 2 then leveltext = "Lv" .. inst.level2hm:value() end
        return "level2hmdirty", leveltext
    end
    for _, def in ipairs(module_definitions) do
        AddPrefabPostInit("wx78module_" .. def.name, function(inst)
            inst.repairmaterials2hm = {scandata = 1}
            inst.level2hm = net_smallbyte(inst.GUID, "module.level2hm", "level2hmdirty")
            inst.itemtilefn2hm = itemtilefn
            inst.displaynamefn = DisplayNameFn
            if not TheWorld.ismastersim then return end
            inst:DoTaskInTime(0.1, function(inst)
                if TUNING.DSTU and not inst.components.finiteuses and inst.components.fueled then
                    inst.repairmaterials2hm.scandata = 480 * 5
                end
            end)
            inst.level2hm:set(1)
            inst.OnSave = OnSave
            inst.OnLoad = OnLoad
            -- if not TUNING.DSTU then 
            inst:AddComponent("repairable2hm")
            -- end
            -- inst.components.repairable2hm.customrepair = onrepair
        end)
    end

    AddComponentPostInit("upgrademodule", function(self)
        local TryActivate = self.TryActivate
        self.TryActivate = function(self, isloading, ...)
            if not self.activated and self.inst.level2hm then
                self.activated = true
                local level = self.inst.level2hm:value()
                if self.onactivatedfn ~= nil then
                    for index = 1, level or 1 do
                        if index == 1 then
                            self.onactivatedfn(self.inst, self.target, isloading)
                        else
                            self.tmp2hm = self.tmp2hm or {}
                            local tmpinst = self.tmp2hm[index - 1] or SpawnPrefab(self.inst.prefab)
                            if tmpinst and tmpinst:IsValid() then
                                tmpinst.components.upgrademodule:SetTarget(self.target)
                                self.tmp2hm[index - 1] = tmpinst
                                self.onactivatedfn(tmpinst, self.target, isloading)
                                tmpinst.persists = false
                                self.inst:AddChild(tmpinst)
                                tmpinst:RemoveFromScene()
                                tmpinst.Transform:SetPosition(0, 0, 0)
                            end
                        end
                    end
                end
            else
                TryActivate(self, isloading, ...)
            end
        end
        local TryDeactivate = self.TryDeactivate
        self.TryDeactivate = function(self, ...)
            if self.activated and self.inst.level2hm then
                self.activated = false
                local level = self.inst.level2hm:value()
                if self.ondeactivatedfn ~= nil then
                    for index = level or 1, 1, -1 do
                        if index == 1 then
                            self.ondeactivatedfn(self.inst, self.target)
                        else
                            self.tmp2hm = self.tmp2hm or {}
                            local tmpinst = self.tmp2hm[index - 1]
                            if tmpinst and tmpinst:IsValid() then
                                self.ondeactivatedfn(tmpinst, self.target)
                                self.tmp2hm[index - 1] = nil
                                tmpinst:Remove()
                            end
                        end
                    end
                end
            else
                TryDeactivate(self, ...)
            end
        end
    end)
    AddComponentPostInit("upgrademoduleowner", function(self)
        self.CanUpgrade = function(self, module_instance)
            if self._last_upgrade_time ~= nil then if (self._last_upgrade_time + self.upgrade_cooldown) > GetTime() then return false, "COOLDOWN" end end
            local slots = module_instance.components.upgrademodule.slots
            if module_instance.level2hm then
                local count = 0
                count = count + module_instance.level2hm:value()
                for _, module in ipairs(self.modules) do
                    if module.prefab == module_instance.prefab and module.level2hm then count = count + module.level2hm:value() end
                end
                -- 保留原有的槽位限制
                if TUNING.WX78_MAXELECTRICCHARGE / slots < count then 
                    return false, "NOTENOUGHSLOTS" 
                end
                -- 额外添加电路等级不能大于3的限制
                if count > 3 then
                    return false, "MAXLEVEL"
                end
            end
            if self.canupgradefn ~= nil then
                return self.canupgradefn(self.inst, module_instance)
            else
                return true
            end
        end
    end)
    AddComponentAction("USEITEM", "upgrademodule", function(inst, doer, target, actions)
        if inst.prefab == target.prefab and doer:HasTag("upgrademoduleowner") then table.insert(actions, ACTIONS.UPGRADE) end
    end)
    local oldUPGRADEfn = ACTIONS.UPGRADE.fn
    ACTIONS.UPGRADE.fn = function(act)
        if oldUPGRADEfn(act) then return true end
        if act.invobject and act.target and act.invobject.prefab == act.target.prefab and act.invobject.components.upgrademodule and
            act.target.components.upgrademodule and act.invobject.level2hm and act.target.level2hm then
            local combined_level = act.invobject.level2hm:value() + act.target.level2hm:value()
            -- 保留原有的槽位限制检查
            if combined_level <= (TUNING.WX78_MAXELECTRICCHARGE / act.invobject.components.upgrademodule.slots) and 
               -- 额外添加电路等级不能大于3的限制
               combined_level <= 3 then
                act.target.level2hm:set(combined_level)
                if act.doer then
                    local shinefx = SpawnPrefab("pocketwatch_warpback_fx")
                    shinefx.AnimState:SetTime(10 * FRAMES)
                    shinefx.entity:SetParent(act.doer.entity)
                end
                if act.target.components.finiteuses then act.target.components.finiteuses:SetUses(TUNING.WX78_MODULE_USES) end
                act.invobject:Remove()
                return true
            end
        end
    end
end

-- WX-78吃齿轮升级
if GetModConfigData("WX-78 Eat Gears InCrease Data") then
    local function OnLoad(inst, data)
        if data ~= nil then
            inst.gearslevel2hm = math.min(inst._gears_eaten or 0, 15)
            inst.components.health.maxhealth = inst.components.health.maxhealth + inst.gearslevel2hm * 5
            inst.components.sanity.max = inst.components.sanity.max + inst.gearslevel2hm * 5
            inst.components.hunger.max = inst.components.hunger.max + inst.gearslevel2hm * 5
            if data._wx78_health then inst.components.health:SetCurrentHealth(data._wx78_health) end
            if data._wx78_sanity then inst.components.sanity.current = data._wx78_sanity end
            if data._wx78_hunger then inst.components.hunger.current = data._wx78_hunger end
        end
    end
    local function OnEat(inst, data)
        if data.food ~= nil and data.food.components.edible ~= nil and data.food.components.edible.foodtype == FOODTYPE.GEARS and inst.gearslevel2hm < 15 then
            inst.gearslevel2hm = (inst.gearslevel2hm or 0) + 1
            inst.components.health.maxhealth = inst.components.health.maxhealth + 5
            inst.components.sanity.max = inst.components.sanity.max + 5
            inst.components.hunger.max = inst.components.hunger.max + 5
            inst.components.health:DoDelta(5)
            inst.components.sanity:DoDelta(5)
            inst.components.hunger:DoDelta(5)
        end
    end
    local function OnDeath(inst)
        inst.components.health.maxhealth = inst.components.health.maxhealth - inst.gearslevel2hm * 5
        inst.components.sanity.max = inst.components.sanity.max - inst.gearslevel2hm * 5
        inst.components.hunger.max = inst.components.hunger.max - inst.gearslevel2hm * 5
        inst.gearslevel2hm = 0
    end
    AddPrefabPostInit("wx78", function(inst)
        if not TheWorld.ismastersim then return end
        inst.gearslevel2hm = 0
        SetOnLoad(inst, OnLoad)
        inst:ListenForEvent("oneat", OnEat)
        inst:ListenForEvent("death", OnDeath)
    end)
end

-- wx-78电路增强
if GetModConfigData("WX-78 Circuit Enhancement") then
    -- 豆增压电路增强
    if TUNING.DSTU and TUNING.DSTU.WXLESS then
        -- ===== 妥协环境 =====
        -- 血量回复：5秒回复1血 -> 5秒回复2血（24血/分钟）
        TUNING.WX78_BEE_HEALTHPERTICK = 2
        
        -- +75理智 -> +30理智+30血量
        TUNING.WX78_MAXSANITY_BOOST = 30  -- 75->30
        
        local module_definitions = require("um_wx78_moduledefs").module_definitions
        for _, def in ipairs(module_definitions) do
            if def.name == "bee" then
                local old_activate = def.activatefn
                local old_deactivate = def.deactivatefn
                
                def.activatefn = function(inst, wx, isloading)
                    if old_activate then old_activate(inst, wx, isloading) end
                    
                    -- 添加血量上限加成：+30，融合升级系统会多次调用此函数，每次都正确加30
                    if wx.components.health ~= nil then
                        wx.components.health.maxhealth = wx.components.health.maxhealth + 30
                    end
                end
                
                def.deactivatefn = function(inst, wx)
                    -- 移除血量上限加成
                    if wx.components.health ~= nil then
                        wx.components.health.maxhealth = wx.components.health.maxhealth - 30
                        -- 确保当前血量不超过新的血量上限
                        if wx.components.health.currenthealth > wx.components.health.maxhealth then
                            wx.components.health:SetCurrentHealth(wx.components.health.maxhealth)
                        end
                    end
                    
                    if old_deactivate then old_deactivate(inst, wx) end
                end
                break
            end
        end
    else
        -- ===== 原版环境 =====
        -- 血量回复：30秒回复5血 -> 30秒回复10血（20血/分钟）
        TUNING.WX78_BEE_HEALTHPERTICK = 10
        
        -- +100理智 -> 改为+50理智+50血量
        TUNING.WX78_MAXSANITY_BOOST = 50  -- 100->50
    
        AddPrefabPostInit("wx78", function(inst)
            if not TheWorld.ismastersim then return end
            
            inst._bee_health_bonus = 0
            
            inst:ListenForEvent("upgrademodulesdirty", function(inst)
                if inst.components.upgrademoduleowner then
                    -- 统计所有豆增压电路的等级总和
                    local total_bee_level = 0
                    for _, module in ipairs(inst.components.upgrademoduleowner.modules) do
                        if module.prefab == "wx78module_bee" then
                            local level = (module.level2hm and module.level2hm:value()) or 1
                            total_bee_level = total_bee_level + level
                        end
                    end
                    
                    -- 每级+50血
                    local target_bonus = total_bee_level * 50
                    local diff = target_bonus - inst._bee_health_bonus
                    
                    if diff ~= 0 and inst.components.health then
                        inst.components.health.maxhealth = inst.components.health.maxhealth + diff
                        inst._bee_health_bonus = target_bonus
                    end
                end
            end)
        end)
    end
    -- ========================================
    -- 电气化电路，装备后被闪电击中可触发系统过载
    -- 移速+30%，发光，不会过冷，攻击带电
    AddPrefabPostInit("wx78", function(inst)
        if not TheWorld.ismastersim then return end
        
        -- 自然闪电击中触发
        inst:ListenForEvent("lightningdamageavoided", function(inst)
            -- 装备电气化电路
            local has_taser = false
            if inst.components.upgrademoduleowner then
                for _, module in ipairs(inst.components.upgrademoduleowner.modules) do
                    if module.prefab == "wx78module_taser" then
                        has_taser = true
                        break
                    end
                end
            end
            
            if has_taser and inst.components.debuffable then
                inst:AddDebuff("wx78_overload_buff2hm", "wx78_overload_buff2hm")
                
                local fx = SpawnPrefab("wx78_big_spark")
                if fx then
                    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
                inst.SoundEmitter:PlaySound("dontstarve/common/lightninghit")
            end
        end)
        
        -- 传送魔杖的闪电特殊，监听被传送状态直接触发
        inst:ListenForEvent("newstate", function(inst, data)
            if data and data.statename == "forcetele" then
                local has_taser = false
                if inst.components.upgrademoduleowner then
                    for _, module in ipairs(inst.components.upgrademoduleowner.modules) do
                        if module.prefab == "wx78module_taser" then
                            has_taser = true
                            break
                        end
                    end
                end
                
                if has_taser and inst.components.debuffable then
                    inst:AddDebuff("wx78_overload_buff2hm", "wx78_overload_buff2hm")
                    
                    local fx = SpawnPrefab("wx78_big_spark")
                    if fx then
                        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    end
                    inst.SoundEmitter:PlaySound("dontstarve/common/lightninghit")
                end
            end
        end)
    end)

    -- 卸载时移除过载buff
    local module_definitions_path = TUNING.DSTU and "um_wx78_moduledefs" or "wx78_moduledefs"
    local wx78_moduledefs = require(module_definitions_path)
    
    if wx78_moduledefs and wx78_moduledefs.module_definitions then
        for _, def in ipairs(wx78_moduledefs.module_definitions) do
            if def.name == "taser" then
                local old_deactivate = def.deactivatefn
                
                def.deactivatefn = function(inst, wx)
                    if wx.components.debuffable and wx:HasDebuff("wx78_overload_buff2hm") then
                        wx.components.debuffable:RemoveDebuff("wx78_overload_buff2hm")
                    end
                    
                    if old_deactivate then old_deactivate(inst, wx) end
                end
                
                break
            end
        end
        
        -- 照明电路兼容，在装备/卸载时需要考虑过载buff的光源加成
        for _, def in ipairs(wx78_moduledefs.module_definitions) do
            if def.name == "light" then
                local old_light_activate = def.activatefn
                local old_light_deactivate = def.deactivatefn
                
                def.activatefn = function(inst, wx, isloading)

                    if old_light_activate then
                        old_light_activate(inst, wx, isloading)
                    end
                    
                    -- 如果有过载buff，需要在原版逻辑基础上再加上过载的3半径
                    if wx._overload_light_bonus and wx.Light then
                        local current_radius = wx.Light:GetRadius()
                        wx.Light:SetRadius(current_radius + 3)
                    end
                end
                
                def.deactivatefn = function(inst, wx)
                    
                    if old_light_deactivate then old_light_deactivate(inst, wx) end
                    
                    -- 如果有过载buff但卸载所有照明电路后光源被关闭了，需要重新开启过载光源
                    if wx._overload_light_bonus and wx.Light and not wx.Light:IsEnabled() then
                        wx.Light:Enable(true)
                        wx.Light:SetRadius(3)
                        wx.Light:SetFalloff(0.75)
                        wx.Light:SetIntensity(0.9)
                        wx.Light:SetColour(235/255, 121/255, 12/255)
                    end
                end
                
                break
            end
        end
    end
    -- ========================================
    -- 修复卸载血量电路时血量超出上限的问题
    AddComponentPostInit("upgrademodule", function(self)
        local old_TryDeactivate = self.TryDeactivate
        self.TryDeactivate = function(self, ...)
            local result = old_TryDeactivate(self, ...)
            
            -- 卸载电路后，检查并修正血量
            if self.target and self.target.components.health then
                local health = self.target.components.health
                if health.currenthealth > health.maxhealth then
                    health:SetCurrentHealth(health.maxhealth)
                end
            end
            
            return result
        end
    end)
end

