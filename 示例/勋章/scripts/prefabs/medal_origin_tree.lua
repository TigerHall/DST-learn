local assets =
{
    Asset("ANIM", "anim/oceantree_pillar_build1.zip"),
    Asset("ANIM", "anim/oceantree_pillar_build2.zip"),
    Asset("ANIM", "anim/oceantree_pillar.zip"),
    Asset("ANIM", "anim/oceantree_pillar_small.zip"),
    Asset("ANIM", "anim/medal_origin_tree_small_build1.zip"),
    Asset("ANIM", "anim/medal_origin_tree_build1.zip"),
    Asset("ANIM", "anim/medal_origin_tree_build2.zip"),
    Asset("SOUND", "sound/tentacle.fsb"),
    Asset("ATLAS", "minimap/medal_origin_tree.xml" ),
    Asset("SCRIPT", "scripts/prefabs/canopyshadows.lua")
}

local prefabs = 
{
    "oceantreenut",
    "oceanvine_cocoon",
    "medal_origin_tree_leaf_fx",
}
--小型掉落物列表
local small_ram_products =
{
    -- "twigs",
    -- "cutgrass",
    "medal_origin_tree_leaf_fx",
}

for _, v in ipairs(small_ram_products) do
    table.insert(prefabs, v)
end

local LEAF_FALL_FX_OFFSET_MIN = 3.5--落叶生成位置偏移
local LEAF_FALL_FX_OFFSET_VARIANCE = 2--落叶生成偏移值方差

local DROP_ITEMS_DIST_MIN = 8--掉落物最小生成距离
local DROP_ITEMS_DIST_VARIANCE = 12--距离方差

local NUM_DROP_SMALL_ITEMS_MIN = 10--小型掉落物数量最小值
local NUM_DROP_SMALL_ITEMS_MAX = 14--小型掉落物数量最大值

local DROPPED_ITEMS_SPAWN_HEIGHT = 10--掉落物生成高度

local PLANT_MAX_NUM = 50--本源植物最大数量


------------------------------------------------本源植物---------------------------------------------------
local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end
--判断坐标是否可以生成植物(不能离本源之树太近了)
local function isPosCanSpawnPlant(x,z)
    if TheWorld and TheWorld.medal_origin_tree ~= nil then
        return TheWorld.medal_origin_tree:GetDistanceSqToPoint(x,0,z) > 16
    end
end

--根据ID计算本源植物的位置,x是圈数,y是排序
local function CalPlantPos(idx)
    idx = math.clamp(idx,1,PLANT_MAX_NUM)
	local x = math.ceil((math.sqrt(25 + 4 * idx) - 5) *.5)
    local y = idx - (x-1)*(x * 2 +8)*.5
    return x, y
end

--记录本源植物
local function AddOriginPlant(inst,plant,idx)
    if idx ~= nil and inst.origin_plants[idx] == nil then
        inst.origin_plants[idx] = plant
        plant.origin_plant_idx = idx
    end
end

--移除本源植物
local function RemoveOriginPlant(inst,plant,idx)
    idx = idx or plant.origin_plant_idx
    if idx ~= nil and inst.origin_plants[idx] == plant then
        inst.origin_plants[idx] = nil
    else
        plant.origin_plant_idx = nil
    end
end

--更新本源植物
local function UpdateOriginPlant(inst,old,new)
    if old.origin_plant_idx ~= nil then
        inst.origin_plants[old.origin_plant_idx] = new
        new.origin_plant_idx = old.origin_plant_idx
        old.origin_plant_idx = nil
    end
end

--催熟本源植物
local function DoPlantGrowth(inst,num,isguard)
    if num and num > 0 and inst.origin_plants then
        for i = 1, PLANT_MAX_NUM do
            local plant = inst.origin_plants[i]
            if plant ~= nil then
                --成长为本源守卫
                if isguard and plant.prefab ~= "medal_origin_tree_guard" then
                    local guard = SpawnPrefab("medal_origin_tree_guard")
                    if guard ~= nil then
                        guard.Transform:SetPosition(plant.Transform:GetWorldPosition())
                        if guard.playSpawnAnimation ~= nil then
                            guard:playSpawnAnimation()
                        end
                        if plant.origin_plant_idx ~= nil and inst.UpdateOriginPlant ~= nil then
                            inst:UpdateOriginPlant(plant,guard)--更新本源之树绑定的目标
                        end
                        num = num - 1
                    end
                --催熟
                elseif plant.DoOriginGrowth and plant:DoOriginGrowth() then
                    num = num - 1
                end
                if num <= 0 then break end
            end
        end
    end
end

--生成本源之花(本源之树,生成数量,是否是守卫)
local function SpawnFlowers(inst,num,isguard)
	num = num or TUNING_MEDAL.MEDAL_ORIGIN_FLOWER_SPAWN_NUM[inst.phase or 1]--生成数量
    local x,y,z = inst.Transform:GetWorldPosition()
    for i = 1, PLANT_MAX_NUM do
        --有空位则生成,无空位就催熟
        if inst.origin_plants[i] == nil then
            local circle_idx, circle_idy = CalPlantPos(i)
            local angle = (circle_idy - 1+math.random(0,circle_idx)*.1) * 2 * PI / (circle_idx*2 + 4)--根据圈数和序号来计算角度
            local radius = 4 * (circle_idx + 1)--半径
            local flower = SpawnPrefab(isguard and "medal_origin_tree_guard" or math.random() < TUNING_MEDAL.MEDAL_ORIGIN_FLOWER_MUTATION_PROB[inst.phase or 1] and "medal_origin_cactus" or "medal_origin_flower")
            flower.Transform:SetPosition(x + radius*math.cos(angle), 0, z + radius*math.sin(angle))
            if flower.playSpawnAnimation then
				flower:playSpawnAnimation()--有生成动画就播放生成动画
			end
            AddOriginPlant(inst,flower,i)--登记
            num = num - 1
        end
        if num <= 0 then break end
    end
    DoPlantGrowth(inst,num,isguard)--催熟
end

------------------------------------------------本源昆虫---------------------------------------------------
--移除小虫子数据
local function OnInsectRemove(insect)
    local inst = TheWorld and TheWorld.medal_origin_tree
    if inst and inst.origin_insects then
        for k, v in ipairs(inst.origin_insects) do
            if v == insect then
                table.remove(inst.origin_insects,k)
                if inst.origin_insect_num and inst.origin_insect_num>0 then
                    inst.origin_insect_num = inst.origin_insect_num - 1
                end
            end
        end
    end
    insect:RemoveEventCallback("onremove", OnInsectRemove)
end

--登记小虫子数据
local function RegisterOriginInsect(inst,insect)
    if insect.is_origin_insect then return end--登记过的就别登记了
    table.insert(inst.origin_insects,insect)
    inst.origin_insect_num = inst.origin_insect_num + 1
    insect.is_origin_insect = true
    insect:ListenForEvent("onremove",OnInsectRemove)
end

--小虫子权重表
local insect_loot = {
    {medal_origin_glowfly=10,},
    {medal_origin_glowfly=8,medal_origin_fruitfly=2,},
    {medal_origin_glowfly=6,medal_origin_fruitfly=2,medal_origin_mosquito=2,},
    {medal_origin_glowfly=4,medal_origin_fruitfly=3,medal_origin_mosquito=3,},
}
--根据当前阶段获取随机小虫子
local function GetRandomInsect(inst)
    return weighted_random_choice(insect_loot[inst.phase or 1])
end

--生成小虫子
local function SpawnInsect(player,inst,taskfn)
    --虫子数量不能超过上限
    if inst.origin_insect_num < TUNING_MEDAL.MEDAL_ORIGIN_TREE_INSECT_NUM_MAX then
		local plants = {}
		local plantnum = 0
		--获取可以生成小虫子的植物
        for i,v in pairs(inst.origin_plants) do
			if v:HasTag("origin_flower") then
				table.insert(plants,v)
				plantnum = plantnum + 1
			end
		end
		if plantnum > 0 then
            local insectnum = math.floor(plantnum * .1) + 1--单次生成昆虫数量(花越多单次生成越多)
            for i = 1, insectnum do
                local plant = table.remove(plants,math.random(plantnum))--多只昆虫应该从不同的花上生成
                if plant ~= nil then
                    local insect = SpawnPrefab(GetRandomInsect(inst))
                    if insect ~= nil then
                        insect.Transform:SetPosition(plant.Transform:GetWorldPosition())
                        RegisterOriginInsect(inst,insect)--登记
                    end
                    plantnum = plantnum - 1
                end
            end
		end
	end
    inst.insect_spawn_tasks[player] = nil
    taskfn(inst,player)
end

--小虫子生成周期
local function InsectSpawnTime(idx)
    return math.random(TUNING_MEDAL.MEDAL_ORIGIN_TREE_INSECT_SPAWNTIME_MIN[idx or 5],TUNING_MEDAL.MEDAL_ORIGIN_TREE_INSECT_SPAWNTIME_MAX[idx or 5])
end

--开始生成小虫子
local function StartSpawnInsect(inst,player)
    if inst == nil or not inst:IsValid() or not inst.is_monster then return end
	if player == nil then--无指定对象，则遍历玩家列表(只有刚魔化的时候会这样)
		for player in pairs(inst.players) do
			if player:IsValid() and inst.insect_spawn_tasks[player] == nil then
				inst.insect_spawn_tasks[player] = player:DoTaskInTime(InsectSpawnTime(),SpawnInsect,inst,StartSpawnInsect)
			end
		end
	elseif inst.insect_spawn_tasks[player] == nil then
		inst.insect_spawn_tasks[player] = player:DoTaskInTime(InsectSpawnTime(inst.phase or 1),SpawnInsect,inst,StartSpawnInsect)
	end
end

--取消生成小虫子
local function CancelSpawnInsect(inst,player)
	if inst.insect_spawn_tasks[player] ~= nil then
		inst.insect_spawn_tasks[player]:Cancel()
		inst.insect_spawn_tasks[player] = nil
	end
end

--生成甲虫
local function SpawnSoldier(inst,target)
    local passdrake = SpawnPrefab("medal_origin_beetle")
    local pos = inst:GetPosition()
    local passoffset = FindWalkableOffset(pos, math.random() * TWOPI, GetRandomMinMax(5, TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE/2), 30, false, false, NoHoles)
    if passoffset ~= nil then
        passdrake.Transform:SetPosition(pos.x + passoffset.x, 0, pos.z + passoffset.z)
    else
        passdrake.Transform:SetPosition(pos:Get())
    end
    if passdrake.components.combat ~= nil and target ~= nil then
        passdrake.components.combat:SuggestTarget(target)
    end
    if inst.components.commander then
        inst.components.commander:AddSoldier(passdrake)
    end
end

--尝试生成甲虫
local function TrySpawnSoldier(inst)
    local per_capita_num = TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_MAX_NUM[inst.phase or 1]--人均甲虫数
    -- print("甲虫数量",inst.components.commander:GetNumSoldiers())
    --甲虫数量不能超过 人均甲虫数量*人数
    if inst.is_monster and inst.components.commander and inst.components.commander:GetNumSoldiers() < inst.player_num * per_capita_num then
        local playerTargetLoot = {}--每个玩家的敌对甲虫数量
        local soldiers = inst.components.commander:GetAllSoldiers()
        for i, v in pairs(soldiers) do
            local target = v.components.combat and v.components.combat.target
            if target then
                playerTargetLoot[target] = (playerTargetLoot[target] or 0) + 1
            end
        end
        --对于敌对甲虫数量不多的玩家，生成甲虫
        for player in pairs(inst.players) do
			local spawnnum = math.min(per_capita_num - (playerTargetLoot[player] or 0), TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_SPAWN_NUM[inst.phase or 1])--单次不能生成太多
            if player:IsValid() and spawnnum > 0 then
				for i = 1, spawnnum do
                    SpawnSoldier(inst,player)
                end
			end
		end
    end
    --生成周期发生变化
    if inst.soldier_task_change then
        inst.soldier_task_change = nil
        if inst.soldier_task then
            inst.soldier_task:Cancel()
            inst.soldier_task = nil
        end
        inst.soldier_task = inst:DoPeriodicTask(TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_SPAWN_TIME[inst.phase or 1],TrySpawnSoldier)
    end
end

------------------------------------------------掉落相关---------------------------------------------------
--掉落单个道具
local function DropItem(inst)
    if inst.items_to_drop and #inst.items_to_drop > 0 then
        local ind = math.random(1, #inst.items_to_drop)
        local item_to_spawn = inst.items_to_drop[ind]

        local x, _, z = inst.Transform:GetWorldPosition()

        local item = SpawnPrefab(item_to_spawn)

        local dist = DROP_ITEMS_DIST_MIN + DROP_ITEMS_DIST_VARIANCE * math.random()
        local theta = math.random() * TWOPI

        local spawn_x, spawn_z

        spawn_x, spawn_z = x + math.cos(theta) * dist, z + math.sin(theta) * dist

        item.Transform:SetPosition(spawn_x, DROPPED_ITEMS_SPAWN_HEIGHT, spawn_z)
        table.remove(inst.items_to_drop, ind)
    end
end

--产生掉落物
local function DropItems(inst)
    DropItem(inst)
    DropItem(inst)

    if #inst.items_to_drop <= 1 then
        inst.items_to_drop = nil
        if inst.drop_items_task then
            inst.drop_items_task:Cancel()
        end
        inst.drop_items_task = nil
        if inst.removeme then
            inst.itemsdone = true  
            if inst.falldone then
                inst:Remove() 
            end                        
        end
    else
        -- inst:DoTaskInTime(0.1, DropItems)
        inst.drop_items_task = inst:DoTaskInTime(0.1, function() DropItems(inst) end)
    end
end
--生成掉落物列表
local function generate_items_to_drop(inst)
    inst.items_to_drop = {}
    local num_small_items = math.random(NUM_DROP_SMALL_ITEMS_MIN, NUM_DROP_SMALL_ITEMS_MAX)
    for i = 1, num_small_items do
        table.insert(inst.items_to_drop, small_ram_products[math.random(1, #small_ram_products)])
    end
end
--掉落木头(单块)
local function DropLog(inst)
    if inst.logs > 0 then
        local x, _, z = inst.Transform:GetWorldPosition()

        local item = SpawnPrefab("log")

        local dist = 0 + (math.random()*6)
        local theta = math.random() * TWOPI

        local spawn_x, spawn_z

        spawn_x, spawn_z = x + math.cos(theta) * dist, z + math.sin(theta) * dist

        item.Transform:SetPosition(spawn_x, DROPPED_ITEMS_SPAWN_HEIGHT, spawn_z)
        inst.logs = inst.logs -1
    end
end
--掉落木头
local function DropLogs(inst)
    DropLog(inst)
    DropLog(inst)
    if inst.logs < 1 then
        inst.logs = nil
        inst.drop_logs_task:Cancel()
        inst.drop_logs_task = nil
    else
        inst.drop_logs_task = inst:DoTaskInTime(0.05, function() DropLogs(inst) end)
    end
end

--生成波浪
-- local function spawnwaves(inst, numWaves, totalAngle, waveSpeed, wavePrefab, initialOffset, idleTime, instantActivate, random_angle)
--     SpawnAttackWaves(
--         inst:GetPosition(),
--         (not random_angle and inst.Transform:GetRotation()) or nil,
--         initialOffset or (inst.Physics and inst.Physics:GetRadius()) or nil,
--         numWaves,
--         totalAngle,
--         waveSpeed,
--         wavePrefab,
--         idleTime,
--         instantActivate
--     )
-- end
--生成落叶实体
local function Dropleafitems(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    local item = SpawnPrefab("medal_origin_tree_leaves")
    local dist = DROP_ITEMS_DIST_MIN + DROP_ITEMS_DIST_VARIANCE * math.random()
    local theta = math.random() * TWOPI
    local spawn_x, spawn_z
    spawn_x, spawn_z = x + math.cos(theta) * dist, z + math.sin(theta) * dist
    item.Transform:SetPosition(spawn_x, 0, spawn_z)
end
--落叶
local function Dropleaves(inst)
    if not inst.leafcounter then
        inst.leafcounter = 0
    end
    Dropleafitems(inst)
    Dropleafitems(inst)
    Dropleafitems(inst)
    inst.leafcounter = inst.leafcounter + 0.05

    if inst.leafcounter > 1 then
        inst.dropleaftask:Cancel()
        inst.dropleaftask = nil
    end
end
--掉落树冠
local function dropcanopy(inst, dropleaves)    
    DropItems(inst)--生成掉落物
    if dropleaves then 
        inst.dropleaftask = inst:DoPeriodicTask(0.05, function() Dropleaves(inst)  end)--生成落叶
    end
end
--掉落树冠及掉落物
local function dropcanopystuff(inst,num, dropleaves)
    if not inst.items_to_drop or num > #inst.items_to_drop then
        inst.items_to_drop = {}
        generate_items_to_drop(inst, num)
    end
    dropcanopy(inst,dropleaves)
end

------------------------------------------------状态变更---------------------------------------------------
local phase_map={2000,5000,8000,10000}--阶段map(逆序)
--计算当前阶段
local function CalcPhase(inst,health)
    if not inst.is_monster then return 1 end
    health = health or (inst.components.workable and inst.components.workable:GetWorkLeft()) or TUNING_MEDAL.MEDAL_ORIGIN_TREE_HEALTH
    for i, v in ipairs(phase_map) do
        if health <= v then
            return 5 - i
        end
    end
    return 1
    -- return math.clamp(5 - math.ceil(health/3000), 1, 4)
end
--尝试换阶段
local function TryChangePhase(inst,health)
    local new_phase = CalcPhase(inst,health)
    if new_phase == inst.phase then return end
    --阶段上升
    -- if new_phase > inst.phase then
    --     SpawnFlowers(inst)--立即生成一波本源之花
    -- end
    inst.phase = new_phase
    inst.soldier_task_change = true--阶段变化意味着甲虫生成周期需要发生变化
end
--取消移除标签定时器
local function CancleRemoveTagTask(inst)
    if inst.removetag_task then
        inst.removetag_task:Cancel()
        inst.removetag_task = nil
    end
end
--玩家远离
local function OnFar(inst, player)
    CancelSpawnInsect(inst,player)
    inst.player_num = inst.player_num - 1
    if player.canopytrees then   
        player.canopytrees = player.canopytrees - 1
        player:PushEvent("onchangecanopyzone", player.canopytrees > 0)
    end
    
    --需要算下本源树荫的数量,只有真正离开树荫了才移除标签
    if player.medal_canopytrees then
        player.medal_canopytrees = player.medal_canopytrees - 1
        if player.medal_canopytrees <=0 then
            CancleRemoveTagTask(inst)
            inst.removetag_task = inst:DoTaskInTime(1,function(inst)
                player:RemoveTag("under_origin_tree")
                inst.removetag_task = nil
            end)
        end
    end
    
    player:RemoveDebuff("buff_medal_origin_energy")--移除本源能量
    inst.players[player] = nil
    --所有玩家离开本源之树范围一段时间后，再进来才会生成本源之花
	if inst.player_num <= 0 then
		if inst.components.timer:TimerExists("near_spawn_cd") then
			inst.components.timer:SetTimeLeft("near_spawn_cd", TUNING_MEDAL.MEDAL_ORIGIN_TREE_NEAR_SPAWN_CD)
		else
			inst.components.timer:StartTimer("near_spawn_cd", TUNING_MEDAL.MEDAL_ORIGIN_TREE_NEAR_SPAWN_CD)
		end
    end
end
--玩家靠近
local function OnNear(inst,player)
    inst.player_num = inst.player_num + 1--统计范围内玩家数量
    inst.players[player] = true
    CancleRemoveTagTask(inst)
    player:AddTag("under_origin_tree")--处于本源之树下
    --温度重置为初始温度
    -- if player.components.temperature then
    --     player.components.temperature:SetTemperature(TUNING.STARTING_TEMP)
    -- end

    player.canopytrees = (player.canopytrees or 0) + 1--树荫统计
    player.medal_canopytrees = (player.medal_canopytrees or 0) + 1--本源树荫统计(防止在两棵树之间走的时候出现树荫变化的问题)
    player:PushEvent("onchangecanopyzone", player.canopytrees > 0)--推送树荫变化事件，树荫数量为0则表示玩家离开树荫了
    
    --以下为仅魔化的本源之树设定
    if inst.is_monster then
        --从无人状态变成有人状态的时候，生成一次本源之花
        if inst.player_num == 1 then
			--确保不在cd中
            if not inst.components.timer:TimerExists("near_spawn_cd") then
				SpawnFlowers(inst)
			end
        end
        StartSpawnInsect(inst,player)--开始生成小虫子
    end
end

--是否可魔化
local function CanBecomeMonster(inst)
    if true then return false end--线上版本暂时先屏蔽魔化
    local x,y,z = inst.Transform:GetWorldPosition()
    for i = 1, PLANT_MAX_NUM do
        local circle_idx, circle_idy = CalPlantPos(i)
        --遍历植物生成点,确保每个生成点都可以正常生成植物,若不满足则判定不通过
        if inst.origin_plants[i] == nil then
            local circle_idx, circle_idy = CalPlantPos(i)
            local angle = (circle_idy - 1) * 2 * PI / (circle_idx*2 + 4)--根据圈数和序号来计算角度
            local radius = 4 * (circle_idx + 1)--半径
            if not TheWorld.Map:IsPassableAtPoint(x + radius*math.cos(angle), 0, z + radius*math.sin(angle)) then
                return false
            end
        end
    end
    return true
end

--魔化
local function BecomeMonster(inst,health)
    if TheWorld == nil or TheWorld.medal_origin_tree ~= nil then return end--世界上只能有一棵魔化本源之树
    TheWorld.medal_origin_tree = inst
    inst.is_monster = true
    inst:AddTag("monster_origin_tree")
    inst.components.workable:SetMaxWork(TUNING_MEDAL.MEDAL_ORIGIN_TREE_HEALTH)
    inst.components.workable:SetWorkLeft(health or TUNING_MEDAL.MEDAL_ORIGIN_TREE_HEALTH)
    inst.components.workable:SetRequiresToughWork(true)--需要高强度工作
    inst.components.health:SetMaxHealth(TUNING_MEDAL.MEDAL_ORIGIN_TREE_HEALTH)
    if health ~= nil then
        inst.components.health:SetCurrentHealth(health)
    else--刚魔化的时候触发,加载时的魔化就没必要再走一遍这些逻辑了
		SpawnFlowers(inst)--生成本源之花
		StartSpawnInsect(inst)--开始生成小虫子
        TrySpawnSoldier(inst)--生成甲虫
	end
    inst.phase = CalcPhase(inst)--计算当前所处阶段
    inst.soldier_task = inst:DoPeriodicTask(TUNING_MEDAL.MEDAL_ORIGIN_BEETLE_SPAWN_TIME[inst.phase or 1],TrySpawnSoldier)--开始生成甲虫
    --切换贴图
end

--回血
local function DoRecovery(inst,value)
	if inst.components.workable == nil or not inst.is_monster then return end--非魔化状态不能回血
    local health = math.min(inst.components.workable:GetWorkLeft() + (value or 5), TUNING_MEDAL.MEDAL_ORIGIN_TREE_HEALTH)
    inst.components.workable:SetWorkLeft(health)
    if inst.components.health ~= nil then
        inst.components.health:SetCurrentHealth(health)
		inst:PushEvent("healthdelta")
    end
    TryChangePhase(inst,health)--阶段变化
end

--移除实体
local function OnRemoveEntity(inst)
    -- if inst.roots then
    --     inst.roots:Remove()
    -- end

    -- if inst._ripples then
    --     inst._ripples:Remove()
    -- end

    for player in pairs(inst.players) do
        if player:IsValid() then
            if player.canopytrees then
                player.canopytrees = player.canopytrees - 1
                player:PushEvent("onchangecanopyzone", player.canopytrees > 0)
            end
        end
    end
    --取消本源之树登记
    if inst.is_monster and TheWorld and TheWorld.medal_origin_tree == inst  then
        TheWorld.medal_origin_tree = nil
    end
end

------------------------------------------------技能触发---------------------------------------------------
--召唤物列表
local skill_loot = {
	flower_trap = {--恶臭花
		{item="medal_origin_flowertrap_projectile",num=4,radius=10},
	},
	mushgnome = {--地精
		{item="medal_origin_mushgnome",num=2,radius=3,offset=3,itemfn=function(inst,player)
			inst:PushEvent("spawn")
			if inst.components.combat then
				inst.components.combat:SetTarget(player)
			end
		end},
	},
	spider = {--蜘蛛
		{item="medal_origin_spider",num=2,radius=3,offset=3,itemfn=function(inst,player)
			inst.sg:GoToState("dropper_enter")
			if inst.components.combat then
				inst.components.combat:SetTarget(player)
			end
		end},
	},
}

--获取特殊数字组(从1~n的数字中取m个不重复随机数)
local function getRandomList(n, m)
    local src, res = {}, {}
    for i=1,n do src[i] = i end
    for i=1,m do
        local r = math.random(1, #src)
        res[table.remove(src, r)] = true
    end
    return res
end
--生成召唤物
local function SpawnChild(inst,num_loot,key)
	if num_loot == nil or key == nil or skill_loot[key] == nil then return end
	local total = num_loot[inst.phase or 1] + (inst.player_num > 1 and inst.player_num or 0)--总数量
    local avg_num = math.floor(total / inst.player_num)--人均数量
    local sp_num = total - avg_num * inst.player_num--多余的数量(随机分给玩家)
    local spnums = sp_num > 0 and getRandomList(inst.player_num,sp_num) or {}
    local count = 1
    for player in pairs(inst.players) do
        local spawn_num = avg_num
        if spnums[count] then
            spawn_num = spawn_num + 1
        end
		if player:IsValid() and not IsEntityDeadOrGhost(player) then
			local loot = deepcopy(skill_loot[key])--深拷贝一份数据表用于生成对应数量的召唤物
            loot[1].num = spawn_num
            MedalSpawnCircleItem(player,loot)
		end
	end
end

local guard_loot = {}--守卫列表(1守卫、2地精、3蜘蛛)
--守卫
guard_loot[1] = function(inst)
    SpawnFlowers(inst,TUNING_MEDAL.MEDAL_ORIGIN_TREE_SPAWN_CHILD_NUM.GUARD[inst.phase or 1],true)--生成守卫
end
--地精
guard_loot[2] = function(inst)
	SpawnChild(inst,TUNING_MEDAL.MEDAL_ORIGIN_TREE_SPAWN_CHILD_NUM.MUSHGNOME,"mushgnome")
end
--蜘蛛
guard_loot[3] = function(inst)
	SpawnChild(inst,TUNING_MEDAL.MEDAL_ORIGIN_TREE_SPAWN_CHILD_NUM.SPIDER,"spider")
end

--根据累计伤害释放技能
local function TryReleaseSkills(inst,damage)
    inst.total_damage = inst.total_damage + damage--统计累计收到的伤害
    --恶臭花
    if inst.total_damage >= inst.skill_times[3]*1000 + 500 then
        inst.skill_times[3] = inst.skill_times[3] + 1
        local loot = deepcopy(skill_loot.flower_trap)--深拷贝一份数据表用于生成对应数量的召唤物
        loot[1].num = TUNING_MEDAL.MEDAL_ORIGIN_TREE_SPAWN_CHILD_NUM.TRAP[inst.phase or 1]--生成数量
        MedalSpawnCircleItem(inst,loot)
    --守卫
    -- elseif inst.total_damage >= inst.skill_times[2]*10 + 10 then
    elseif inst.total_damage >= inst.skill_times[2]*1000 + 1000 then
        if inst.skill_times[2] % 3 == 0 then--每召唤3次重置权重
            for i, v in ipairs(inst.skill_guard_weight) do
                inst.skill_guard_weight[i]=1
            end
        end
        inst.skill_times[2] = inst.skill_times[2] + 1
		--随机召唤一种守卫，三种进行循环
        local idx = weighted_random_choice(inst.skill_guard_weight)
        inst.skill_guard_weight[idx] = 0
        if guard_loot[idx] then
            guard_loot[idx](inst)
        end
    --本源之花
    elseif inst.total_damage >= inst.skill_times[1]*50 + 50 then
        inst.skill_times[1] = inst.skill_times[1] + 1
        SpawnFlowers(inst)--生成本源之花
    end
end

------------------------------------------------砍树---------------------------------------------------
--砍树
local function chop_tree(inst, chopper, chopsleft, numchops)
    --声音表现
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper ~= nil and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            chopper ~= nil and chopper:HasTag("boat") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end
    if not inst.is_monster then
        --非魔化状态快砍倒时播放断裂的声音
        if inst.components.workable.workleft / inst.components.workable.maxwork == 0.2 then 
            inst.SoundEmitter:PlaySound("waterlogged2/common/watertree_pillar/cracking")
        elseif inst.components.workable.workleft / inst.components.workable.maxwork == 0.12 then 
            inst.SoundEmitter:PlaySound("waterlogged2/common/watertree_pillar/cracking")
        end
    end
    --动画表现
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
    ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, 0.2, inst, 6)--摇晃镜头
    --每次砍伐概率掉落叶
    if math.random() < 0.58 then
        local theta = math.random() * TWOPI
        local offset = LEAF_FALL_FX_OFFSET_MIN + math.random() * LEAF_FALL_FX_OFFSET_VARIANCE
        local x, _, z = inst.Transform:GetWorldPosition()
        SpawnPrefab("medal_origin_tree_leaf_fx").Transform:SetPosition(x + math.cos(theta) * offset, 10, z + math.sin(theta) * offset)
    end
    
    --魔化状态
    if inst.is_monster and chopper ~= nil and chopsleft > 0 then
		if inst.components.combat then
            inst.components.combat:SetTarget(chopper)
        end
        --阶段变化
        TryChangePhase(inst,chopsleft)
        --释放技能
        TryReleaseSkills(inst,numchops)
        --生成根鞭
        local x,y,z = chopper.Transform:GetWorldPosition()
		local root = SpawnPrefab("medal_origin_tree_root")
		if root then
			root.target = chopper
            root.Transform:SetPosition(x,y,z)
		end
        -- local root = SpawnPrefab("medal_origin_tree_root")
        -- if root ~= nil then
        --     local targdist = TUNING.DECID_MONSTER_TARGET_DIST
        --     local x, y, z = inst.Transform:GetWorldPosition()
        --     local mx, my, mz = chopper.Transform:GetWorldPosition()
        --     local mdistsq = distsq(x, z, mx, mz)
        --     local targdistsq = targdist * targdist
        --     local rootpos = Vector3(mx, 0, mz)
        --     local angle = inst:GetAngleToPoint(rootpos) * DEGREES
        --     if mdistsq > targdistsq then
        --         rootpos.x = x + math.cos(angle) * targdist
        --         rootpos.z = z - math.sin(angle) * targdist
        --     end

        --     root.Transform:SetPosition(x + 1.75 * math.cos(angle), 0, z - 1.75 * math.sin(angle))
        --     root:PushEvent("givetarget", { target = chopper, targetpos = rootpos, targetangle = angle, owner = inst })
        -- end
	end
    --同步血量显示
    if inst.is_monster and chopsleft ~= nil and inst.components.health then
        inst.components.health:SetVal(chopsleft, nil, chopper)
        inst:PushEvent("healthdelta")
        -- inst.components.health:DoDelta(-numchops)
    end
end

--砍伐收益倍率
local function chop_multiplierfn(inst, worker, numworks)
    if inst.is_monster then return 1 end--没魔化不需要降低倍率
    local value = 0
    --植物倍率
    for k, v in pairs(inst.origin_plants) do
        value = value + (v.origin_chop_absorb or 0)
    end
    return 1 - math.clamp(value, 0, .9)
end

--成功砍倒
local function chop_down_tree(inst, chopper)
    -- inst:OnRemoveEntity()
    --移除阴影
    if inst.components.canopyshadows ~= nil then
        inst:RemoveComponent("canopyshadows")
    end
    --声音
    inst.SoundEmitter:PlaySound("waterlogged2/common/watertree_pillar/fall")
    --动画结束后移除
    inst:ListenForEvent("animover", function() 
        inst.falldone = true  
        if inst.itemsdone then
            inst:Remove() 
        end
    end)
    --切换动画
    inst.AnimState:SetBank("oceantree_pillar_small")
    inst.AnimState:SetBuild("medal_origin_tree_small_build1")
    inst.AnimState:PlayAnimation("fall")

    -- inst:DoTaskInTime(7*FRAMES,function() inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")  end)
    -- inst:DoTaskInTime(28*FRAMES,function() 
    --     inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/large")  
    --     spawnwaves(inst, 6, 360, 4, nil, 2, 2, nil, true)
    -- end)
    -- inst:DoTaskInTime(38*FRAMES,function() inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")  end)
    -- inst:DoTaskInTime(51*FRAMES,function() inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")  end)
    -- inst:DoTaskInTime(56*FRAMES,function() inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")  end)
    -- inst:DoTaskInTime(60*FRAMES,function() inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")  end)
    -- inst:DoTaskInTime(63*FRAMES,function() inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")  end)
    -- inst:DoTaskInTime(68*FRAMES,function() inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")  end)
    -- inst:DoTaskInTime(75*FRAMES,function() inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")  end)
    -- inst:DoTaskInTime(94*FRAMES,function() 
    --     inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/large")
    --     spawnwaves(inst, 6, 360, 4, nil, 2, 2, nil, true)
    -- end)

    -- local pt = inst:GetPosition()
    -- inst.components.lootdropper:DropLoot(pt)
    inst.removeme = true
    inst.persists = false
    dropcanopystuff(inst, math.random(NUM_DROP_SMALL_ITEMS_MIN,NUM_DROP_SMALL_ITEMS_MAX), true )--树冠掉落,生成掉落物
    inst.logs = 20
    DropLogs(inst)

    inst:DoTaskInTime(.5, function() ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, 0.6, inst, 6) end)

    --统计死亡次数
    if inst.is_monster and TheWorld and TheWorld.components.medal_infosave then
        TheWorld.components.medal_infosave:CountChaosCreatureDeathTimes(inst)
    end
end

------------------------------------------------雷劈---------------------------------------------------
--掉落雷劈掉落物
local function DropLightningItems(inst, items)
    local x, _, z = inst.Transform:GetWorldPosition()
    local num_items = #items

    for i, item_prefab in ipairs(items) do
        local dist = DROP_ITEMS_DIST_MIN + DROP_ITEMS_DIST_VARIANCE * math.random()
        local theta = TWOPI * math.random()

        inst:DoTaskInTime(i * 5 * FRAMES, function(inst2)
            local item = SpawnPrefab(item_prefab)
            item.Transform:SetPosition(x + dist * math.cos(theta), 20, z + dist * math.sin(theta))

            if i == num_items then
                inst._lightning_drop_task:Cancel()
                inst._lightning_drop_task = nil
            end 
        end)
    end
end
--遭雷劈
local function OnLightningStrike(inst)
    if inst._lightning_drop_task ~= nil then
        return
    end

    local num_small_items = math.random(NUM_DROP_SMALL_ITEMS_MIN, NUM_DROP_SMALL_ITEMS_MAX)
    local items_to_drop = {}

    for i = 1, num_small_items do
        table.insert(items_to_drop, small_ram_products[math.random(1, #small_ram_products)])
    end

    inst._lightning_drop_task = inst:DoTaskInTime(20*FRAMES, DropLightningItems, items_to_drop)
end

------------------------------------------------数据存取---------------------------------------------------
--存储
local function OnSave(inst, data)
    data.is_monster = inst.is_monster--魔化状态
    if inst.components.workable ~= nil then
        data.current_health = inst.components.workable:GetWorkLeft()--记录剩余血量(伐木次数)
    end
    data.skill_times = shallowcopy(inst.skill_times)
    data.skill_guard_weight = shallowcopy(inst.skill_guard_weight)
    data.total_damage = inst.total_damage
end
--读取
local function OnLoad(inst, data)
    if data then
        if data.is_monster then
            inst.is_monster = true
            BecomeMonster(inst,data.current_health)
        end
        if data.skill_times then
            inst.skill_times = shallowcopy(data.skill_times)
        end
        if data.skill_guard_weight then
            inst.skill_guard_weight = shallowcopy(data.skill_guard_weight)
        end
        inst.total_damage = data.total_damage or 0
    end
    inst.components.timer:StartTimer("near_spawn_cd", 1)--加个cd防止加载时因为有玩家在范围内触发生成本源之花的逻辑
end

------------------------------------------------动画---------------------------------------------------
--成长动画
local function OnSprout(inst)
    inst.AnimState:SetBank("oceantree_pillar_small")
    inst.AnimState:SetBuild("medal_origin_tree_small_build1")
    inst.AnimState:SetScale(1.3, 1.3)
    -- inst.AnimState:AddOverrideBuild("oceantree_pillar_small_build2")

    inst.AnimState:PlayAnimation("grow_tall_to_pillar")
    
    -- inst.AnimState:PushAnimation("idle", true)
end
--播完成长动画切回当前贴图
local function ChangeToNormalBuild(inst)
    if inst.AnimState:IsCurrentAnimation("grow_tall_to_pillar") then
        inst.AnimState:SetBank("oceantree_pillar")
        inst.AnimState:SetBuild("medal_origin_tree_build1")
        inst.AnimState:SetScale(1, 1)
        inst.AnimState:PlayAnimation("idle", true)

        inst.AnimState:AddOverrideBuild("medal_origin_tree_build2")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeWaterObstaclePhysics(inst, 4, 2, 0.75)

    inst:SetDeployExtraSpacing(4)

    -- HACK: this should really be in the c side checking the maximum size of the anim or the _current_ size of the anim instead
    -- of frame 0
    inst.entity:SetAABB(60, 20)

    -- inst:AddTag("cocoon_home")
    inst:AddTag("shadecanopy")
    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("cantdestroy")--不可破坏
    -- inst:AddTag("noattack")--不可被攻击
    inst:AddTag("notarget")--不可被当成攻击目标
    -- inst:AddTag("soulless")--砍倒了不应该爆魂
    inst:AddTag("epic")
    inst:AddTag("lunarthrall_plant")--亮茄寄生植物(主要是防止亮茄在其范围内生成)

    inst.MiniMapEntity:SetIcon("medal_origin_tree.tex")

    inst.AnimState:SetBank("oceantree_pillar")
    inst.AnimState:SetBuild("medal_origin_tree_build1")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:AddOverrideBuild("medal_origin_tree_build2")
    -- inst.AnimState:AddOverrideBuild("oceantree_pillar_build2")

    if not TheNet:IsDedicated() then
        inst:AddComponent("distancefade")
        inst.components.distancefade:Setup(15,25)

        inst:AddComponent("canopyshadows")--树冠阴影
        inst.components.canopyshadows.range = math.floor(TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE/4)
    end

    inst:AddComponent("temperatureoverrider")

    -- inst.scrapbook_specialinfo = "WATERTREEPILLAR"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sproutfn = OnSprout--成长动画
    inst:ListenForEvent("animover", ChangeToNormalBuild)

    -- inst.scrapbook_adddeps = { "oceanvine" }

    inst.phase = 1--当前阶段
    inst.items_to_drop = nil
    inst.drop_items_task = nil
    inst.origin_plants = {}--本源植物
    inst.origin_insects = {}--本源昆虫
    inst.origin_insect_num = 0--本源昆虫数量
    inst.insect_spawn_tasks = {}--生虫定时器
    inst.skill_times = {0,0,0}--技能释放次数(1召唤植物,2召唤守卫,3恶臭花)
    inst.skill_guard_weight = {1,1,1}--召唤守卫的权重(1守卫,2地精,3蜘蛛)
    inst.total_damage = 0--累计收到的伤害

    -------------------
    --光照
    inst:AddComponent("canopylightrays")
    inst.components.canopylightrays.range = math.floor(TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE/4)

    -------------------
    inst:AddComponent("combat")
    --血量上限(仅显示用)
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING_MEDAL.MEDAL_ORIGIN_TREE_WORKLEFT)
    inst.components.health.invincible = true
    inst.components.health.nofadeout = true
    
    -------------------

    --玩家靠近
    inst.players = {}
    inst.player_num = 0
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetDist(TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE, TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE + 1)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetOnPlayerNear(OnNear)

    -------------------

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.CHOP)
    inst.components.workable:SetMaxWork(TUNING_MEDAL.MEDAL_ORIGIN_TREE_WORKLEFT)
    inst.components.workable:SetWorkLeft(TUNING_MEDAL.MEDAL_ORIGIN_TREE_WORKLEFT)
    inst.components.workable:SetOnWorkCallback(chop_tree)
    inst.components.workable:SetOnFinishCallback(chop_down_tree)
    inst.components.workable:SetWorkMultiplierFn(chop_multiplierfn)
    inst.components.workable.medal_work_limit = TUNING_MEDAL.MEDAL_ORIGIN_TREE_WORK_LIMIT--单次工作上限,防秒杀

    inst:AddComponent("commander")--指挥官
    inst.components.commander:SetTrackingDistance(TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE*1.5)--指挥距离=树冠范围*1.5

    --------------------
    inst:AddComponent("inspectable")

    --------------------
    inst:AddComponent("timer")

    --------------------
    inst:AddComponent("lightningblocker")--闪电防护
    inst.components.lightningblocker:SetBlockRange(TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE)
    inst.components.lightningblocker:SetOnLightningStrike(OnLightningStrike)

    inst.CanBecomeMonster = CanBecomeMonster--是否可变成怪物
    inst.BecomeMonster = BecomeMonster--变成怪物
	inst.DoRecovery = DoRecovery--回血

    inst.AddOriginPlant = AddOriginPlant--记录本源植物
    inst.RemoveOriginPlant = RemoveOriginPlant--移除本源植物
    inst.UpdateOriginPlant = UpdateOriginPlant--更新本源植物
    inst.RegisterOriginInsect = RegisterOriginInsect--登记小虫子数据
    inst.GetRandomInsect = GetRandomInsect--根据当前阶段获取随机小虫子

    inst.components.temperatureoverrider:SetRadius(TUNING_MEDAL.MEDAL_ORIGIN_TREE_SHADE_CANOPY_RANGE)
    inst.components.temperatureoverrider:SetTemperature(TUNING.STARTING_TEMP)
    inst.components.temperatureoverrider:Enable()

    inst.OnSave = OnSave
    -- inst.OnPreLoad = OnPreLoad
    inst.OnLoad = OnLoad
    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end
--落叶
local function leaves_fn(data)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("oceantree_pillar_small")
    inst.AnimState:SetBuild("medal_origin_tree_small_build1")
    inst.AnimState:PlayAnimation("leaf_fall_ground", false)
    
    inst:ListenForEvent("animover", function() inst:Remove() end)

    inst:DoTaskInTime(0, function()  
            local point = Vector3(inst.Transform:GetWorldPosition())
            if not TheWorld.Map:IsVisualGroundAtPoint(point.x,point.y,point.z) then
                inst.AnimState:PlayAnimation("leaf_fall_water", false)     
                -- inst:DoTaskInTime(11*FRAMES, function() 
                --     inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")
                -- end)
            end

        end)
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("medal_origin_tree", fn, assets, prefabs),
    Prefab("medal_origin_tree_leaves", leaves_fn, assets)
