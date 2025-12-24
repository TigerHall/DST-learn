-- 掉血多掉20%/33%,制作栏掉血除外
local healthrate = GetModConfigData("role_battle") == -1 and 0.2 or 0.33

-- 制作栏掉血会收到血量上限惩罚
local function DeltaPenalty(inst, self, amount) self:DeltaPenalty(amount) end
AddComponentPostInit("health", function(self)
    if not self.inst:HasTag("player") then return end
    local oldDoDelta = self.DoDelta
    self.DoDelta = function(self, amount, overtime, cause, ...)
        if amount < 0 and cause == "builder" and not self.disable_penalty then
            self.inst:DoTaskInTime(0, DeltaPenalty, self, -amount / self.maxhealth / 2)
        end
        if (self.inst.prefab ~= "wanda" or (self.inst.components.oldager and self.inst.components.oldager._taking_time_damage)) then
            if amount > 0 then
                amount = amount * (1 - healthrate)
            elseif cause ~= "builder" then
                amount = amount * (1 + healthrate)
            end
        end
        return oldDoDelta(self, amount, overtime, cause, ...)
    end
    -- 继承血量惩罚
    local TransferComponent = self.TransferComponent
    self.TransferComponent = function(self, newinst, ...)
        TransferComponent(self, newinst, ...)
        if self.penalty > 0 then newinst.components.health:SetPenalty(self.penalty) end
    end
end)

-- 药膏可以回复血量上限
AddComponentPostInit("healer", function(self)
    local Heal = self.Heal
    self.Heal = function(self, target, doer, ...)
        local health = 0
        local healhealth = self.health
        if self.inst.prefab == "brine_balm" then
            healhealth = 40
        elseif self.inst.prefab == "tillweedsalve" then
            healhealth = 20
        end
        if healhealth > 0 and target:HasTag("player") and target.components.health and target.components.health.penalty > 0 then
            health = (target.components.health.currenthealth + healhealth - target.components.health:GetMaxWithPenalty()) / 2
        end
        -- 确保 doer 不为 nil
        local safe_doer = doer or target
        local result = Heal(self, target, safe_doer, ...)
        if result and health > 0 then target.components.health:DeltaPenalty(-health / 200) end
        return result
    end
end)

-- 强心针需要2个蚊子血囊
AddRecipePostInit("lifeinjector", function(inst) 
    table.insert(inst.ingredients, Ingredient("mosquitosack", 2)) 
end)

-- 鱼干类食物回复血量上限
local fish_dried_food = {
    "fishmeat_dried", "smallfishmeat_dried"
}

-- 含有鱼度的烹饪料理
local fish_cooked_food = {
    "fishsticks", "fishtacos", "ceviche", "californiaroll", "seafoodgumbo", 
    "surfnturf", "lobsterbisque", "lobsterdinner", "barnaclestuffedfishhead",
    "barnaclepita", "barnaclesushi", "barnaclinguine"
}

local function OnEat(inst, data)
    if inst.components.health and inst.components.health.penalty and inst.components.health.penalty > 0 and 
        inst.components.eater and data and data.food and data.food.components.edible and
        data.food.components.edible.healthvalue and data.food.components.edible.healthvalue > 0 then
        
        local health_delta = data.food.components.edible:GetHealth(inst)
        if inst.components.eater.custom_stats_mod_fn ~= nil then
            health_delta = inst.components.eater.custom_stats_mod_fn(inst, data.food.components.edible.healthvalue,
                                                                     data.food.components.edible.hungervalue,
                                                                     data.food.components.edible.sanityvalue, data.food, data.feeder)
        end
        
        local penalty_recovery = 0
        
        -- 鱼干/小鱼干直接回复回血量/2的血量上限
        if table.contains(fish_dried_food, data.food.prefab) then
            penalty_recovery = health_delta / 300
        -- 含有鱼度的料理回复回血量/10的血量上限
        elseif table.contains(fish_cooked_food, data.food.prefab) then
            penalty_recovery = health_delta / 1500
        end
        
        if penalty_recovery > 0 then
            inst.components.health:DeltaPenalty(-penalty_recovery)
        end
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("oneat", OnEat)
end)

-- 妥协开启时
if TUNING.DSTU then 
    -- 强心针红蘑菇数量减少2
    AddRecipePostInit("lifeinjector", function(recipe) 
        for _, ingredient in pairs(recipe.ingredients) do
            if ingredient and ingredient.type == "red_cap" and ingredient.amount then
                ingredient.amount = math.max(1, ingredient.amount - 2)
            end
        end
    end)
    -- 盐晶药膏海带叶数量增加2
    AddRecipePostInit("brine_balm", function(recipe) 
        for _, ingredient in pairs(recipe.ingredients) do
            if ingredient and ingredient.type == "kelp" and ingredient.amount then
                ingredient.amount = math.max(1, ingredient.amount + 2)
            end
        end
    end)
    
    -- 禁用2039模组的盐调味料理生命值上限恢复功能
    local UpvalueHacker = require "tools/upvaluehacker" 
    
end
