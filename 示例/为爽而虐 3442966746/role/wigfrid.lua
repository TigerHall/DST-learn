-- TUNING.INSPIRATION_DRAIN_BUFFER_TIME = TUNING.INSPIRATION_DRAIN_BUFFER_TIME * 2
TUNING.INSPIRATION_RIDING_GAIN_RATE = TUNING.INSPIRATION_RIDING_GAIN_RATE / 3
TUNING.INSPIRATION_RIDING_GAIN_MAX = TUNING.BATTLESONG_THRESHOLDS[1]
TUNING.WATHGRITHR_HEALTH = 180
TUNING.SPEAR_WATHGRITHR_LIGHTNING_DAMAGE = 34 * 1.5         -- 51
TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_DAMAGE = 34 * 1.5 -- 51
AddComponentPostInit("singinginspiration", function(self)
    local oldUpdate = self.OnUpdate
    self.OnUpdate = function(self, ...)
        oldUpdate(self, ...)
        if self.is_draining then
            if self.active2hm then
                self.active2hm = nil
                if self.inspire_refresh_task ~= nil then
                    self.inspire_refresh_task:Cancel()
                    self.inspire_refresh_task = nil
                end
                if self.display_fx_task ~= nil then
                    self.display_fx_task:Cancel()
                    self.display_fx_task = nil
                    self.display_fx_count = nil
                end
            end
        elseif not self.active2hm then
            self.active2hm = true
            if #self.active_songs > 0 then
                self:Inspire()
                self:DisplayFx()
                if self.inspire_refresh_task == nil then
                    self.inspire_refresh_task = self.inst:DoPeriodicTask(TUNING.SONG_REAPPLY_PERIOD, function() self:Inspire() end)
                end
            end
        end
    end
    local AddSong = self.AddSong
    self.AddSong = function(self, ...)
        AddSong(self, ...)
        if not self.active2hm then
            if self.inspire_refresh_task ~= nil then
                self.inspire_refresh_task:Cancel()
                self.inspire_refresh_task = nil
            end
            if self.display_fx_task ~= nil then
                self.display_fx_task:Cancel()
                self.display_fx_task = nil
                self.display_fx_count = nil
            end
        end
    end
    -- local Inspire = self.Inspire
    -- self.Inspire = function(self, ...)
    --     return Inspire(self, ...)
    -- end
    local DisplayFx = self.DisplayFx
    self.DisplayFx = function(self, ...)
        if #self.active_songs == 0 and not self.display_fx_task then
            self.display_fx_count = 1
            return
        end
        return DisplayFx(self, ...)
    end
end)

AddRecipePostInit("battlesong_instant_revive", function(inst) table.insert(inst.ingredients, Ingredient("greengem", 1)) end)
TUNING.SKILLS.WATHGRITHR.BATTLESONG_INSTANT_COOLDOWN_HIGH = TUNING.SKILLS.WATHGRITHR.BATTLESONG_INSTANT_COOLDOWN_HIGH * 16

-- 限制谱子只能攻击敌人回复
local function IsValidVictim(victim)
    return victim ~= nil and
               not ((victim:HasTag("prey") and not victim:HasTag("hostile")) or victim:HasTag("veggie") or victim:HasTag("structure") or victim:HasTag("wall") or
                   victim:HasTag("balloon") or victim:HasTag("groundspike") or victim:HasTag("smashable") or victim:HasTag("companion")) and
               victim.components.health ~= nil and victim.components.combat ~= nil
end
local function processsongapply(inst)
    if not TheWorld.ismastersim then return end
    if inst.songdata and not inst.songdata.gainpro2hm and inst.songdata.ONAPPLY then
        inst.songdata.gainpro2hm = true
        local old = inst.songdata.ONAPPLY
        inst.songdata.ONAPPLY = function(inst, target, ...)
            local num = 0
            if target.components.health and target.event_listeners and target.event_listeners.onattackother and target.event_listeners.onattackother[inst] then
                num = #target.event_listeners.onattackother[inst]
            end
            old(inst, target, ...)
            if target.components.health and target.event_listeners and target.event_listeners.onattackother and target.event_listeners.onattackother[inst] then
                local fns = target.event_listeners.onattackother[inst]
                if #fns > num then
                    local fn = fns[#fns]
                    fns[#fns] = function(attacker, data, ...)
                        if data and data.target and data.target:IsValid() and IsValidVictim(data.target) then fn(attacker, data, ...) end
                    end
                end
            end
        end
    end
end
AddPrefabPostInit("battlesong_healthgain", processsongapply)
AddPrefabPostInit("battlesong_sanitygain", processsongapply)

-- Recipe("battlesong_durability",	{_G.Ingredient("papyrus", 3), _G.Ingredient("featherpencil", 3), _G.Ingredient("minotaurhorn", 1)},		_G.CUSTOM_RECIPETABS.BATTLESONGS, _G.TECH.NONE, nil, nil, nil, nil, "battlesinger")
-- Recipe("battlesong_sanitygain",	{_G.Ingredient("papyrus", 3), _G.Ingredient("featherpencil", 3), _G.Ingredient("glasscutter", 1)},		_G.CUSTOM_RECIPETABS.BATTLESONGS, _G.TECH.NONE, nil, nil, nil, nil, "battlesinger")
-- Recipe("battlesong_sanityaura",	{_G.Ingredient("papyrus", 3), _G.Ingredient("featherpencil", 3), _G.Ingredient("orangestaff", 1)},		_G.CUSTOM_RECIPETABS.BATTLESONGS, _G.TECH.NONE, nil, nil, nil, nil, "battlesinger")
-- Recipe("battlesong_healthgain",	{_G.Ingredient("papyrus", 3), _G.Ingredient("featherpencil", 3), _G.Ingredient("batbat", 1)},	_G.CUSTOM_RECIPETABS.BATTLESONGS, _G.TECH.NONE, nil, nil, nil, nil, "battlesinger")
-- Recipe("battlesong_fireresistance",	{_G.Ingredient("papyrus", 3), _G.Ingredient("featherpencil", 3), _G.Ingredient("dragon_scales", 1)},		_G.CUSTOM_RECIPETABS.BATTLESONGS, _G.TECH.NONE, nil, nil, nil, nil, "battlesinger")
-- Recipe("battlesong_instant_taunt",	{_G.Ingredient("papyrus", 3), _G.Ingredient("featherpencil", 3), _G.Ingredient("greenamulet", 1)},		_G.CUSTOM_RECIPETABS.BATTLESONGS, _G.TECH.NONE, nil, nil, nil, nil, "battlesinger")
-- Recipe("battlesong_instant_panic",	{_G.Ingredient("papyrus", 3), _G.Ingredient("featherpencil", 3), _G.Ingredient("greenamulet", 1)},		_G.CUSTOM_RECIPETABS.BATTLESONGS, _G.TECH.NONE, nil, nil, nil, nil, "battlesinger")


