-- --   薇洛技能树优化   --
-- ====================================================================
-- 可控燃烧优化：伤害范围缩小，减少队友被波及
AddComponentPostInit("propagator", function(self)
    local oldOnUpdate = self.OnUpdate
    self.OnUpdate = function(self, dt)
        -- 检查是否为可控燃烧
        local is_controlled_burn = false
        if self.source and self.source:IsValid() and 
           self.source.components.burnable and 
           self.source.components.burnable:IsControlledBurn() then
            is_controlled_burn = true
        end
        
        -- 如果是可控燃烧，临时缩小伤害范围
        local original_damagerange = self.damagerange
        if is_controlled_burn then
            -- 将伤害范围缩小为30%
            self.damagerange = self.damagerange * 0.3
        end
        
        -- 调用原始更新逻辑
        oldOnUpdate(self, dt)
        
        -- 恢复原始伤害范围
        self.damagerange = original_damagerange
    end
end)

-- ====================================================================
-- 月焰纵火犯：逆转火球属性
local function ConvertFireballToLunar(entity)
    if entity.is_cold_fireball then
        return 
    end
    
    entity.is_cold_fireball = true
    
    -- 升温变为降温
    if entity.components.heater then
        entity.components.heater.heat = -entity.components.heater.heat
        entity.components.heater:SetThermics(false, true)
    end
    
    -- 移除点燃
    if entity.components.propagator then
        entity.components.propagator:StopUpdating()
        entity:RemoveComponent("propagator")
    end

    if entity.Light then
        entity.Light:SetColour(64 / 255, 64 / 255, 208 / 255)
    end

    if entity.AnimState then
        entity.AnimState:SetMultColour(5 / 255, 87 / 255, 255 / 255, 0.8)
        entity.AnimState:SetAddColour(5 / 255, 87 / 255, 255 / 255, 0.4)
    end

    if entity.prefab == "emberlight" then
        entity:SetPrefabNameOverride(TUNING.isCh2hm and "月火球" or "Lunar Fire Ball")
        if entity.components.inspectable then
            entity.components.inspectable:SetDescription(
                TUNING.isCh2hm and "被月焰转换的月火球，散发着寒冷的蓝光。" or 
                "A lunar fire ball transformed by lunar flame, emitting cold blue light."
            )
        end
    elseif entity.prefab == "stafflight" then
        entity:SetPrefabNameOverride(TUNING.isCh2hm and "白矮星" or "White Dwarf Star")
        if entity.components.inspectable then
            entity.components.inspectable:SetDescription(
                TUNING.isCh2hm and "被月焰转换的白矮星，提供冷光和降温。" or 
                "A white dwarf star transformed by lunar flame, providing cool light and temperature reduction."
            )
        end
    end
    
    -- 农田地裂消除
    entity:AddTag("farmdockfix2hm")
    
    -- 消除周围的农田地裂
    local function clearfarmdock(inst, radius)
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, 0, z, radius or TUNING.DAYLIGHT_SEARCH_RANGE, {"farmdock2hm"})) do 
            if v and v:IsValid() then 
                v:Remove() 
            end 
        end
    end

    entity:DoTaskInTime(0, clearfarmdock, TUNING.DAYLIGHT_SEARCH_RANGE)
end

-- 修改月焰火焰粒子，让它能转换火球
AddPrefabPostInit("warg_mutated_breath_fx", function(inst)
    if not TheWorld.ismastersim then return end

    local originalRestartFX = inst.RestartFX
    inst.RestartFX = function(inst, scale, fadeoption, targets)

        originalRestartFX(inst, scale, fadeoption, targets)

        if inst.owner ~= nil then
            local function FireballConversionUpdate(inst)
                local tick = GetTick()
                local x, y, z = inst.Transform:GetWorldPosition()
                local radius = 0.9 * inst.scale
                local fire_entities = TheSim:FindEntities(x, 0, z, radius + 3, nil, {"INLIMBO"})
                
                for _, entity in ipairs(fire_entities) do
                    if entity:IsValid() and not entity:IsInLimbo() and 
                       (entity.prefab == "emberlight" or entity.prefab == "stafflight") then
                        
                        local range = radius + entity:GetPhysicsRadius(0)
                        if entity:GetDistanceSqToPoint(x, 0, z) < range * range then

                            if not entity.lunar_conversion_data then
                                entity.lunar_conversion_data = {
                                    hit_count = 0,
                                    last_hit_tick = 0
                                }
                            end
                            
                            -- 检查是否增加命中计数（每10帧，约0.33秒）
                            if entity.lunar_conversion_data.last_hit_tick + 10 < tick then
                                entity.lunar_conversion_data.hit_count = entity.lunar_conversion_data.hit_count + 1
                                entity.lunar_conversion_data.last_hit_tick = tick
                                
                                -- 9次命中后转换（连续3秒）
                                if entity.lunar_conversion_data.hit_count >= 9 and not entity.is_cold_fireball then
                                    ConvertFireballToLunar(entity)
                                end
                            end
                        end
                    end
                end
            end
            
            inst.components.updatelooper:AddOnUpdateFn(FireballConversionUpdate)
        end
    end
end)


local function AddLunarConversionSaveLoad(prefab_name)
    AddPrefabPostInit(prefab_name, function(inst)
        if not TheWorld.ismastersim then return end

        SetOnSave(inst, function(inst, data)
            if inst.is_cold_fireball then
                data.is_cold_fireball = true
            end
        end)
        
        SetOnLoad(inst, function(inst, data)
            if data and data.is_cold_fireball then

                inst:DoTaskInTime(0, function()
                    ConvertFireballToLunar(inst)
                end)
            end
        end)
    end)
end

AddLunarConversionSaveLoad("emberlight")
AddLunarConversionSaveLoad("stafflight")

-- ====================================================================
-- 狂热焚烧：时间延长到240秒，需要5余烬
TUNING.WILLOW_FIREFRENZY_DURATION = 240
TUNING.WILLOW_EMBER_FRENZY = 5

-- 再次释放该技能可提前结束（不消耗余烬）
AddComponentPostInit("aoespell", function(self)
    local old_CastSpell = self.CastSpell
    
    self.CastSpell = function(self, doer, pos)

        if self.inst.prefab == "willow_ember" and self.inst.components.spellbook then
            local selected_spell_id = self.inst.components.spellbook.spell_id
            local spells = self.inst.components.spellbook.items
            

            if selected_spell_id and spells and spells[selected_spell_id] then
                local spell_label = spells[selected_spell_id].label
                if spell_label and (string.find(spell_label, "狂热") or 
                                   string.find(spell_label, "Frenzy") or 
                                   string.find(spell_label, "FIRE_FRENZY")) then
                    
                    if doer:HasTag("firefrenzy") then
                        -- 已有buff，结束狂热，不消耗余烬
                        if doer.components.debuffable then
                            doer.components.debuffable:RemoveDebuff("buff_firefrenzy")
                        end
                        
                        return true, nil
                    else
                        -- 没有buff，检查余烬并正常施法
                        if doer.replica.inventory and doer.replica.inventory:Has("willow_ember", TUNING.WILLOW_EMBER_FRENZY) then
                            -- 添加buff
                            doer:AddDebuff("buff_firefrenzy", "buff_firefrenzy")
                            
                            -- 消耗余烬
                            local inventory = doer.components.inventory
                            if inventory then
                                local amount = TUNING.WILLOW_EMBER_FRENZY
                                for i = 1, inventory:GetNumSlots() do
                                    local item = inventory:GetItemInSlot(i)
                                    if item and item.prefab == "willow_ember" then
                                        if item.components.stackable:StackSize() > amount then
                                            item.components.stackable:SetStackSize(item.components.stackable:StackSize() - amount)
                                            break
                                        else
                                            inventory:RemoveItem(item, true):Remove()
                                            break
                                        end
                                    end
                                end
                            end
                            
                            return true, nil
                        else
                            return false, "NOT_ENOUGH_EMBERS"
                        end
                    end
                end
            end
        end
        
        -- 非火焰狂热技能，使用原版逻辑
        return old_CastSpell(self, doer, pos)
    end
end)

STRINGS.PYROMANCY.FIRE_FRENZY = TUNING.isCh2hm and "狂热焚烧（5余烬）" or "Fire Frenzy (5 Embers)"

-- 更新技能显示文本使其对应正确的功能及余烬消耗
AddComponentPostInit("spellbook", function(self)
    local old_OpenSpellBook = self.OpenSpellBook
    
    self.OpenSpellBook = function(self, user)
        if self.inst.prefab == "willow_ember" and user and user.prefab == "willow" then
            if self.items then
                for i, spell in ipairs(self.items) do
                    if spell.label and (string.find(spell.label, "Frenzy") or string.find(spell.label, "狂热")) then
                        if user:HasTag("firefrenzy") then
                            spell.label = TUNING.isCh2hm and "结束狂热（0余烬）" or "End Frenzy (0 Embers)"
                        else
                            spell.label = TUNING.isCh2hm and "狂热焚烧（5余烬）" or "Fire Frenzy (5 Embers)"
                        end
                        break
                    end
                end
            end
        end
        
        -- 调用原版逻辑
        old_OpenSpellBook(self, user)
    end
end)

-- 自身获得持续升温，高于62度时失效
AddPrefabPostInit("buff_firefrenzy", function(inst)
    if not TheWorld.ismastersim then return end
    
    local original_OnAttached = inst.components.debuff.onattachedfn
    inst.components.debuff.onattachedfn = function(inst, target)
        -- 先调用原版逻辑
        if original_OnAttached then
            original_OnAttached(inst, target)
        end
        
        if target and target:IsValid() and target.components.temperature then
            target.components.temperature:SetTemperatureInBelly(TUNING.HOT_FOOD_BONUS_TEMP, TUNING.WILLOW_FIREFRENZY_DURATION)
        end
    end
    
    -- 兼容式修改OnDetached函数
    local original_OnDetached = inst.components.debuff.ondetachedfn
    inst.components.debuff.ondetachedfn = function(inst, target)        
        -- 清理升温效果（如果buff提前结束）
        if target and target:IsValid() and target.components.temperature then
            if target.components.temperature.bellytemperaturedelta == TUNING.HOT_FOOD_BONUS_TEMP then
                target.components.temperature.bellytemperaturedelta = nil
                target.components.temperature.bellytime = nil
                if target.components.temperature.bellytask then
                    target.components.temperature.bellytask:Cancel()
                    target.components.temperature.bellytask = nil
                end
            end
        end
        
        -- 调用原版逻辑
        if original_OnDetached then
            original_OnDetached(inst, target)
        end
    end
end)

-- ====================================================================
-- 妥协开启时，燃烧周期和可控燃烧技能移除冬季燃烧时间缩短影响

AddComponentPostInit("burnable", function(self)
    local old_ExtendBurning = self.ExtendBurning
    
    self.ExtendBurning = function(self)
        -- 检查是否为冬季且妥协模组启用
        if TheWorld.state.season == "winter" and TUNING.DSTU and TUNING.DSTU.WINTER_BURNING then
            -- 检查是否为可控燃烧且周围有学会燃烧周期的薇洛
            local should_bypass_winter_nerf = false
            
            if self.controlled_burn then
                local x, y, z = self.inst.Transform:GetWorldPosition()
                local nearby_players = TheSim:FindEntities(x, 0, z, 20, {"player"})
                
                for _, player in ipairs(nearby_players) do
                    if player.prefab == "willow" and 
                       player.components.skilltreeupdater and 
                       player.components.skilltreeupdater:IsActivated("willow_controlled_burn_2") then
                        should_bypass_winter_nerf = true
                        break
                    end
                end
            end
            
            -- 如果应该绕过冬季限制，使用正常的燃烧时间
            if should_bypass_winter_nerf then
                -- 使用正常的ExtendBurning逻辑（不应用冬季0.24倍率）
                if self.task ~= nil then
                    self.task:Cancel()
                end
                
                local function DoneBurning(inst, burnable_component)
                    local isplant = inst:HasTag("plant") and not (inst.components.diseaseable ~= nil and inst.components.diseaseable:IsDiseased())
                    local pos = isplant and inst:GetPosition() or nil

                    inst:PushEvent("onburnt")

                    if burnable_component.onburnt ~= nil then
                        burnable_component.onburnt(inst)
                    end

                    if burnable_component.inst:IsValid() then
                        if inst.components.explosive ~= nil then
                            inst.components.explosive:OnBurnt()
                        end

                        if burnable_component.extinguishimmediately then
                            burnable_component:Extinguish()
                        end
                    end

                    if isplant then
                        TheWorld:PushEvent("plantkilled", { pos = pos })
                    end
                end
                
                -- 使用正常倍率而不是冬季的0.24倍率
                self.task = self.burntime ~= nil and 
                           self.inst:DoTaskInTime(
                               self.burntime * (self.controlled_burn and self:CalculateControlledBurnDuration() or 1), 
                               DoneBurning, 
                               self
                           ) or nil
            else
                return old_ExtendBurning(self)
            end
        else
            -- 非冬季或妥协未启用
            return old_ExtendBurning(self)
        end
    end
end)



