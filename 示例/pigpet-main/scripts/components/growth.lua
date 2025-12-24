require "class"
--每秒中1点经验值
Pigpet.growth.time_exp = 1
--每次收集增加2点经验
Pigpet.growth.collect_exp = 1
--每次攻击增加2点经验
Pigpet.growth.attack_exp = 2
--砍树经验
Pigpet.growth.chop_exp = 1


--每次升级增加的攻击力
Pigpet.growth.attack = 1
--每次升级增加的生命值
Pigpet.growth.health = 10

local Growth = Class(function(self, inst)
    self.inst = inst
    self.level = 1
    self.maxlevel = 999
    --当前等级经验值
    self.currentexp = 0
    --当前升级所需经验值
    self.currentmaxexp = 100
    --启动一个循环定时任务
    self.checkTask = self.inst:DoPeriodicTask(5, function() 
        self:CheckHealth()
        self:AddExp(Pigpet.growth.time_exp)
     end)
     local player = GetPlayer()
     --监听player死亡事件
    player:ListenForEvent("death", function() 
        --停止定时任务
        self.checkTask:Cancel()
        self.checkTask = nil
    end)
end)

function Growth:CheckHealth()
    --获取当前生命值
    local currenthealth = self.inst.components.health.currenthealth
    --如果当前生命值小于最大生命值的一半
    if currenthealth < self.inst.components.health.maxhealth / 2 then
        --判断玩家物品栏和背包中是否有宠物食物
        local player = GetPlayer()
        local food
        local mybackpack = player.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
        if mybackpack and mybackpack.prefab == "mybackpack" then
            --判断背包中是否有宠物食物
            food = mybackpack.components.container:FindItem(function(item) 
                if item.prefab == "pigpetfood" then
                    return true
                end
            end)
        end
  
        if not food then
            food = player.components.inventory:FindItem(function(item) return item.prefab == "pigpetfood" end)
        end
        if food then
            --如果有宠物食物，吃掉宠物食物，增加宠物生命值
            self.inst.components.health.currenthealth = self.inst.components.health.currenthealth + food.components.edible.healthvalue
            --获取当前堆叠的个数
            local size = food.components.stackable:StackSize()
            if size > 1 then
                --如果堆叠的个数大于1，减少一个堆叠
                food.components.stackable:SetStackSize(size - 1)
            else
             --吃掉宠物食物
             food:Remove()
            end
        else
            --随机一个概率，说一句话
            local rand = math.random(1, 100)
            if rand <= 10 then
                self.inst.components.talker:Say("我饿了，我要吃东西")
            end
        end
        
    end
end

function Growth:GetLevel()
    return self.level
end

function Growth:GetMaxLevel()
    return self.maxlevel
end

function Growth:GetCurrentExp()
    return self.currentexp
end

function Growth:GetCurrentMaxExp()
    return self.currentmaxexp
end

function Growth:HandleUpgrade()
    --每次升级增加1点攻击力
    self.inst.components.combat.defaultdamage = self.inst.components.combat.defaultdamage + Pigpet.growth.attack
    --增加10点 最大生命值
    self.inst.components.health.maxhealth = self.inst.components.health.maxhealth + Pigpet.growth.health
    --增加10点当前生命值
    self.inst.components.health.currenthealth = self.inst.components.health.currenthealth + Pigpet.growth.health
end

function Growth:AddExp(exp)
    if self.level >= self.maxlevel then
        return
    end
    self.currentexp = self.currentexp + exp
    if self.currentexp >= self.currentmaxexp then
        self.currentexp = self.currentexp - self.currentmaxexp
        self.level = self.level + 1
        self:HandleUpgrade()
    end
end


function Growth:OnSave()
    local data = {}
    data.level = self.level
    data.currentexp = self.currentexp
    data.currentmaxexp = self.currentmaxexp
    return data
end   

function Growth:OnLoad(data)
    if data then
        self.level = data.level
        self.currentexp = data.currentexp
        self.currentmaxexp = data.currentmaxexp
    end
end


return Growth

