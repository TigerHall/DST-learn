-- 不要设置默认的PlayAnimation
-- 不要设置equippable

local KIT_BUFF_TYPE_LIST = require("hmrmain/hmr_lists").KIT_BUFF_TYPE_LIST
local REPAIR_GROWTH_THRESHOLD = {
    -- min:最小倍率, max:最大倍率, mult:每次增加的倍率
    HONOR = {
        armor_absorb =      {min = 0.01,    max = 1,        mult = 0.01,      amount = 0.01 },
        effectiveness =     {min = 1,       max = 10,       mult = 0.06,      amount = 0.06 },
        armor_condition =   {min = 1,       max = 5000,     mult = 0.05,      amount = 10   },
        finiteuses =        {min = 1,       max = 2000,     mult = 0.1,       amount = 10   },
        fuel =              {min = 1,       max = 2000,     mult = 0.15,      amount = 40   },
        perishable =        {min = 1,       max = 14400,    mult = 0.10,      amount = 100  },
    },

    TERROR = {
        damage =            {min = 1,       max = 100,      mult = 0.01,      amount = 1.5  },
        speed =             {min = 1,       max = 3,        mult = 0.02,      amount = 0.02 },
    }
}

local function DefaultOnDisableEquipableFn(inst)
    inst:RemoveComponent("equippable")
end

local Repairable = Class(function(self, inst)
	self.inst = inst

    self.isbroken = false
    self.normaldata = nil
    self.brokendata = nil
    self.onrepairedfn = nil
    self.ondisableequipablefn = DefaultOnDisableEquipableFn
    self.onenableequipablefn = nil

    self.repairtag = nil

    self.skin_name = ""
    self.skin_get_fn = nil
end)

---------------------------------------------------------------------------
---[[可从损坏状态转换为正常状态的装备函数]]
---------------------------------------------------------------------------
function Repairable:Toggle()
    if self.isbroken then
        self:Unequip()
        self:SetData(self.brokendata)
        self.inst:AddTag("broken")
        if self.ondisableequipablefn ~= nil then
            self.ondisableequipablefn(self.inst)
        end
    else
        self:SetData(self.normaldata)
        self.inst:RemoveTag("broken")
        if self.onenableequipablefn ~= nil then
            self.onenableequipablefn(self.inst)
        end
    end
end

function Repairable:SetSkin(skin_name, get_tex_fn)
    if skin_name ~= nil then
        self.skin_name = skin_name
        self.skin_get_fn = get_tex_fn
    else
        self.skin_name = ""
        self.skin_get_fn = nil
    end

    self:Toggle()
end

function Repairable:SetIsBroken(isbroken)
    self.isbroken = isbroken
    self:Toggle()
end

function Repairable:GetIsBroken()
    return self.isbroken
end

function Repairable:SetNormalData(normaldata)
    -- {name = ,atlasname = ,imagename = ,anim = }
    self.normaldata = normaldata
end

function Repairable:SetBrokenData(brokendata)
    -- {name = ,atlasname = ,imagename = ,anim = }
    self.brokendata = brokendata
    self.inst:AddTag("show_broken_ui")
end

function Repairable:SetData(data)
    if data == nil then
        return
    end

    if data.name ~= nil and self.inst.components.inspectable ~= nil then
        self.inst.components.inspectable.nameoverride = data.name
    end

    if data.atlasname ~= nil and data.imagename ~= nil and self.inst.components.inventoryitem ~= nil then
        local atlas, tex
        if self.skin_get_fn ~= nil then
            atlas, tex = self.skin_get_fn()
        elseif self.skin_name ~= "" then
            atlas, tex = string.gsub(data.atlasname, "%.xml$", "_"..self.skin_name..".xml"), data.imagename.."_"..self.skin_name
        else
            atlas, tex = data.atlasname, data.imagename
        end
        self.inst.components.inventoryitem.atlasname = atlas
        self.inst.components.inventoryitem.imagename = tex
    end

    if data.anim ~= nil then
        self.inst.AnimState:PlayAnimation(data.anim)
    end
end

function Repairable:Unequip()
    if self.inst.components.equippable ~= nil and self.inst.components.equippable:IsEquipped() then
        local owner = self.inst.components.inventoryitem.owner
        if owner ~= nil and owner.components.inventory ~= nil then
            local item = owner.components.inventory:Unequip(self.inst.components.equippable.equipslot)
            if item ~= nil and item == self.inst then
                owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
            end
        end
    end
end

function Repairable:SetOnRepairedFn(fn)
    self.onrepairedfn = fn
end

function Repairable:OnRepaired(kit, doer)
    if self.isbroken then
        self:SetIsBroken(false)
    end

    if self.onrepairedfn ~= nil then
        self.onrepairedfn(self.inst)
    end

    -- 处理原版修复损坏的套装
    if self.inst.components.forgerepairable ~= nil and self.inst.components.forgerepairable.onrepaired ~= nil then
        self.inst.components.forgerepairable.onrepaired(self.inst, doer)
    end
end

function Repairable:SetOnDisableEquipableFn(fn)
    self.ondisableequipablefn = fn
end

function Repairable:SetOnEnableEquipableFn(fn)
    self.onenableequipablefn = fn
end

---------------------------------------------------------------------------
---[[通用修补函数]]
---------------------------------------------------------------------------
function Repairable:SetRepairTag(tag)
    self.repairtag = tag
end

function Repairable:CanBeRepaired(kit)
    print("self.repairtag", self.repairtag, "kit.components.hmrrepairer.repairtag", kit.components.hmrrepairer.repairtag)
    if self.repairtag == nil or kit.components.hmrrepairer.repairtag == self.repairtag then
        return true
    end
    return false
end

local function ChooseBuffType(inst)
    local tag = inst.components.hmrrepairable.repairtag
    local types = deepcopy(KIT_BUFF_TYPE_LIST[tag])
    if types == nil then
        return nil
    end

    if tag == "HONOR" then
        -- 防御度
        if inst.components.armor == nil then
            types.armor = nil
        end

        -- 工作效率
        local eff_valid = false
        local tool = inst.components.tool
        if tool ~= nil then
            for action, eff in pairs(tool.actions) do
                if eff < 5 then
                    eff_valid = true
                    break
                end
            end
        end
        if not eff_valid then
            types.effectiveness = nil
        end
    elseif tag == "TERROR" then
        -- 伤害
        if inst.components.weapon == nil then
            types.damage = nil
        end
    end

    local total_weight = 0
    for type, weight in pairs(types) do
        total_weight = total_weight + weight
    end

    local rand = math.random() * total_weight
    local sum = 0
    for type, weight in pairs(types) do
        sum = sum + weight
        if rand <= sum then
            return type
        end
    end

    return nil
end

local function GetBuffAmount(orig_amount, bufftype)
    local perc_amount = orig_amount * bufftype.mult
    local amount = bufftype.amount
    return math.min(perc_amount, amount)
end

function Repairable:Repair(kit, doer, repairability)
    local success = false       -- 是否修补成功
    local conditiontype         -- 耐久度类型
    local mult = 1              -- 修补倍率
    -- 增益属性对等才可修补
    print("修补", self:CanBeRepaired(kit))
    if self:CanBeRepaired(kit) then
        -- 确定修补倍率
        if self.inst:HasTag("honor_repairable") or self.inst:HasTag("terror_repairable") then
            if self.inst:HasTag("honor_repairable") and not kit:HasTag("honor_kit") or
                    self.inst:HasTag("terror_repairable") and not kit:HasTag("terror_kit") then
                mult = 0.7
            end
        elseif not self.inst:HasTag("honor_repairable") and not self.inst:HasTag("terror_repairable") then
            mult = 100
        end

        -- 修补
        if self.inst.components.armor ~= nil then
            if self.inst.components.armor:IsDamaged() then
                success = true
                conditiontype = "armor"
            end
        elseif self.inst.components.finiteuses ~= nil then
            if self.inst.components.finiteuses:GetPercent() < 1 then
                success = true
                conditiontype = "finiteuses"
                print("可以修补")
            end
        elseif self.inst.components.fueled ~= nil then
            if self.inst.components.fueled:GetPercent() < 1 then
                success = true
                conditiontype = "fueled"
            end
        elseif self.inst.components.perishable ~= nil then
            if self.inst.components.perishable:GetPercent() < 1 then
                success = true
                conditiontype = "perishable"
            end
        end
    end

    if success then
        -- 添加对应属性增益
        if self.repairtag == nil then
            self:SetRepairTag(kit.components.hmrrepairer.repairtag)
        end

        -- 损坏不消失的物品恢复正常状态，为了能让物品拥有equippable
        self:OnRepaired(kit, doer)

        local bufftype = ChooseBuffType(self.inst)
        if bufftype ~= nil then
            if self.repairtag == "HONOR" then
                if bufftype == "armor" then
                    local buff_data = REPAIR_GROWTH_THRESHOLD[self.repairtag].armor_absorb
                    local orig = self.inst.components.hmrstatusmodifier:GetOriginalArmorAbsorbPercent()
                    local buff_amount = GetBuffAmount(orig, buff_data)
                    self.inst.components.hmrstatusmodifier:AddArmorAbsorbPercent(buff_amount, buff_data.min, buff_data.max)
                elseif bufftype == "condition" then
                    if conditiontype == "armor" then
                        local buff_data = REPAIR_GROWTH_THRESHOLD[self.repairtag].armor_condition
                        local orig = self.inst.components.hmrstatusmodifier:GetOriginalArmorMaxCondition()
                        local buff_amount = GetBuffAmount(orig, buff_data)
                        self.inst.components.hmrstatusmodifier:AddArmorMaxCondition(buff_amount, buff_data.min, buff_data.max)
                    elseif conditiontype == "finiteuses" then
                        local buff_data = REPAIR_GROWTH_THRESHOLD[self.repairtag].finiteuses
                        local orig = self.inst.components.hmrstatusmodifier:GetOriginalFiniteUsesMaxUses()
                        local buff_amount = GetBuffAmount(orig, buff_data)
                        self.inst.components.hmrstatusmodifier:AddFiniteUsesMaxUses(buff_amount, buff_data.min, buff_data.max)
                    elseif conditiontype == "fueled" then
                        local buff_data = REPAIR_GROWTH_THRESHOLD[self.repairtag].fuel
                        local orig = self.inst.components.hmrstatusmodifier:GetOriginalFueledMaxFuel()
                        local buff_amount = GetBuffAmount(orig, buff_data)
                        self.inst.components.hmrstatusmodifier:AddFueledMaxFuel(buff_amount, buff_data.min, buff_data.max)
                    elseif conditiontype == "perishable" then
                        local buff_data = REPAIR_GROWTH_THRESHOLD[self.repairtag].perishable
                        local orig = self.inst.components.hmrstatusmodifier:GetOriginalPerishableMaxTime()
                        local buff_amount = GetBuffAmount(orig, buff_data)
                        self.inst.components.hmrstatusmodifier:AddPerishableMaxTime(buff_amount, buff_data.min, buff_data.max)
                    end
                elseif bufftype == "effectiveness" then
                    local valid_actions = {}
                    local actions_data = self.inst.components.tool.actions
                    for action, eff in pairs(actions_data) do
                        if eff < 10 then
                            valid_actions[action] = eff
                        end
                    end

                    if GetTableSize(valid_actions) > 0 then
                        local target_action = GetRandomItemWithIndex(valid_actions)

                        local buff_data = REPAIR_GROWTH_THRESHOLD[self.repairtag].effectiveness
                        local orig_eff = self.inst.components.hmrstatusmodifier:GetOriginalToolEffectiveness(target_action) or 0
                        local buff_amount = GetBuffAmount(orig_eff, buff_data)
                        self.inst.components.hmrstatusmodifier:AddToolEffectiveness(target_action, buff_amount, buff_data.min, buff_data.max)
                    end
                end
            elseif self.repairtag == "TERROR" then
                if bufftype == "damage" then
                    local buff_data = REPAIR_GROWTH_THRESHOLD[self.repairtag].damage
                    local dmg = self.inst.components.weapon.damage
                    local orig = type(dmg) == "number" and dmg or 10
                    local buff_amount = GetBuffAmount(orig, buff_data)
                    self.inst.components.hmrstatusmodifier:AddWeaponDamage(buff_amount, buff_data.min, buff_data.max)
                elseif bufftype == "speed" and self.inst.components.equippable ~= nil then
                    local buff_data = REPAIR_GROWTH_THRESHOLD[self.repairtag].speed
                    local orig = self.inst.components.hmrstatusmodifier:GetOriginalEquippableWalkSpeed()
                    local buff_amount = GetBuffAmount(orig, buff_data)
                    self.inst.components.hmrstatusmodifier:AddEquippableWalkSpeed(buff_amount, buff_data.min, buff_data.max)
                end
            end
        end

        -- 最后再进行修补，避免无休止刷
        --[[平均数值：
            armor:1000
            finiteuses:1000
            fueled:9days
            perishtime:10days
        ]]
        if conditiontype == "armor" then
            self.inst.components.armor:Repair(repairability * mult * 1)
        elseif conditiontype == "finiteuses" then
            self.inst.components.finiteuses:Repair(repairability * mult * 3)
        elseif conditiontype == "fueled" then
            self.inst.components.fueled:DoDelta(repairability * mult * 4)
        elseif conditiontype == "perishable" then
            self.inst.components.perishable:AddTime(repairability * mult * 3)
        end

        if kit.components.stackable ~= nil and kit.components.stackable:IsStack() then
            kit.components.stackable:Get():Remove()
        else
            kit:Remove()
        end

        return true
    end

    return false
end

function Repairable:OnSave()
    local data =
    {
        isbroken = self.isbroken,
        repairtag = self.repairtag,
    }
    return next(data) ~= nil and data or nil
end

function Repairable:OnLoad(data)
    self.isbroken = data.isbroken
    self.repairtag = data.repairtag

    self:Toggle()
end

return Repairable