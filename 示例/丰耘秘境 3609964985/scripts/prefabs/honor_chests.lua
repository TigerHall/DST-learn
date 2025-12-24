require "prefabutil"  -- 引入 prefabutil 模块

-- 定义声音文件
local SOUNDS = {
    open  = "dontstarve/wilson/chest_open",  -- 打开宝箱的声音
    close = "dontstarve/wilson/chest_close",  -- 关闭宝箱的声音
    built = "dontstarve/common/chest_craft",  -- 建造宝箱的声音
}

-- 打开宝箱的函数
local function onopen(inst)
    if not inst:HasTag("burnt") then  -- 检查是否被烧毁
        inst.AnimState:PlayAnimation("open")  -- 播放打开动画

        if inst.skin_open_sound then  -- 如果有自定义打开声音
            inst.SoundEmitter:PlaySound(inst.skin_open_sound)  -- 播放自定义声音
        else
            inst.SoundEmitter:PlaySound(inst.sounds.open)  -- 播放默认打开声音
        end
    end
end

-- 关闭宝箱的函数
local function onclose(inst)
    if not inst:HasTag("burnt") then  -- 检查是否被烧毁
        inst.AnimState:PlayAnimation("close")  -- 播放关闭动画
        inst.AnimState:PushAnimation("closed", false)  -- 播放关闭后动画，保持在关闭状态

        if inst.skin_close_sound then  -- 如果有自定义关闭声音
            inst.SoundEmitter:PlaySound(inst.skin_close_sound)  -- 播放自定义声音
        else
            inst.SoundEmitter:PlaySound(inst.sounds.close)  -- 播放默认关闭声音
        end
    end
end

-- 被锤击后的处理函数
local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()  -- 如果正在燃烧，熄灭
    end
    inst.components.lootdropper:DropLoot()  -- 掉落物品
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()  -- 丢弃所有容器内物品
    end
    local fx = SpawnPrefab("collapse_small")  -- 生成崩溃效果
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())  -- 设置效果位置
    fx:SetMaterial("wood")  -- 设置效果材质
    inst:Remove()  -- 移除宝箱实例
end

-- 被攻击的处理函数
local function onhit(inst, worker)
    if not inst:HasTag("burnt") then  -- 检查是否被烧毁
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()  -- 丢弃所有容器内物品
            inst.components.container:Close()  -- 关闭容器
        end
        inst.AnimState:PlayAnimation("hit")  -- 播放被击中动画
        inst.AnimState:PushAnimation("closed", false)  -- 播放关闭动画
    end
end

-- 建造宝箱时的处理函数
local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")  -- 播放放置动画
    inst.AnimState:PushAnimation("closed", false)  -- 播放关闭动画
    if inst.skin_place_sound then  -- 如果有自定义放置声音
        inst.SoundEmitter:PlaySound(inst.skin_place_sound)  -- 播放自定义声音
    else
        inst.SoundEmitter:PlaySound(inst.sounds.built)  -- 播放默认放置声音
    end
end

-- 将宝箱转换为崩溃状态的函数
local function ConvertToCollapsed(inst, droploot, burnt)
	if inst.components.burnable and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()  -- 如果正在燃烧，熄灭
	end

	local x, y, z = inst.Transform:GetWorldPosition()  -- 获取当前世界位置
	if droploot then
		local fx = SpawnPrefab("collapse_small")  -- 生成崩溃效果
		fx.Transform:SetPosition(x, y, z)  -- 设置效果位置
		fx:SetMaterial("wood")  -- 设置材质为木材
		inst.components.lootdropper.min_speed = 2.25  -- 设置掉落物品速度
		inst.components.lootdropper.max_speed = 2.75  -- 设置最大掉落物品速度
		if burnt then
			inst:AddTag("burnt")  -- 添加烧毁标签
			inst.components.lootdropper:DropLoot()  -- 丢弃物品
			inst:RemoveTag("burnt")  -- 移除烧毁标签
		else
			inst.components.lootdropper:DropLoot()  -- 丢弃物品
		end
		inst.components.lootdropper.min_speed = nil  -- 重置最小速度
		inst.components.lootdropper.max_speed = nil  -- 重置最大速度
	end

	inst.components.container:Close()  -- 关闭容器
	inst.components.workable:SetWorkLeft(2)  -- 设置剩余工作次数

	local pile = SpawnPrefab("collapsed_treasurechest")  -- 生成崩溃宝箱实例
	pile.Transform:SetPosition(x, y, z)  -- 设置位置
	pile:SetChest(inst, burnt)  -- 关联当前宝箱状态
end

-- 检查是否应该崩溃的函数
local function ShouldCollapse(inst)
	if inst.components.container and inst.components.container.infinitestacksize then
		-- 如果已经调用了 DropEverything(nil, true)
		local overstacks = 0  -- 初始化超过堆叠数量
		for k, v in pairs(inst.components.container.slots) do  -- 遍历容器的槽
			local stackable = v.components.stackable  -- 获取可堆叠组件
			if stackable then
				overstacks = overstacks + math.ceil(stackable:StackSize() / (stackable.originalmaxsize or stackable.maxsize))  -- 计算超出堆叠数量
				if overstacks >= TUNING.COLLAPSED_CHEST_EXCESS_STACKS_THRESHOLD then  -- 如果超出阈值
					return true  -- 返回 true 表示应崩溃
				end
			end
		end
	end
	return false  -- 返回 false 表示不应崩溃
end

-- 宝箱被烧毁时的处理函数
local function OnBurnt(inst)
	if inst.components.container then
		inst.components.container:DropEverything(nil, true)  -- 丢弃所有物品
	end

	if ShouldCollapse(inst) then  -- 检查是否应该崩溃
		inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_MAX_EXCESS_STACKS_DROPS)  -- 丢弃多余物品
		if not inst.components.container:IsEmpty() then  -- 如果容器不为空
			ConvertToCollapsed(inst, true, true)  -- 转换为崩溃状态
			return
		end
	end

	-- 如果没有处理重置为默认的烧毁行为
	DefaultBurntStructureFn(inst)
end


-- 拆解结构时的处理函数
local function OnDecontructStructure(inst, caster)
    if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
        if inst.components.lootdropper ~= nil then
            inst.components.lootdropper:SpawnLootPrefab("alterguardianhatshard")  -- 生成物品碎片
        end
    end

	if ShouldCollapse(inst) then  -- 检查是否应该崩溃
		inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_MAX_EXCESS_STACKS_DROPS)  -- 丢弃多余物品
		if not inst.components.container:IsEmpty() then  -- 如果容器不为空
			ConvertToCollapsed(inst, false, false)  -- 转换为崩溃状态
			inst.no_delete_on_deconstruct = true  -- 设置为不在拆解时删除
			return
		end
	end

	-- 否则重置为默认的拆解处理
	inst.no_delete_on_deconstruct = nil  -- 重置不删除标志
end

-- 保存状态的函数
local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true  -- 如果被烧毁，保存烧毁状态
    end
end

-- 加载状态的函数
local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)  -- 如果被烧毁，执行烧毁逻辑
    end
end

-- 创建宝箱的函数
local function MakeChest(name, common_postinit, master_postinit)
    local assets =
    {
        Asset("ANIM", "anim/treasure_chest.zip"),  -- 默认动画资源
        Asset("ANIM", "anim/ui_chest_3x3.zip"),  -- 用户界面动画资源
        Asset("ANIM", "anim/ui_chest_upgraded_3x3.zip"),  -- 升级用户界面动画资源
    }

    local function fn()  -- 宝箱的具体实现
        local inst = CreateEntity()  -- 创建实体

        inst.entity:AddTransform()  -- 添加变换组件
        inst.entity:AddAnimState()  -- 添加动画状态组件
        inst.entity:AddSoundEmitter()  -- 添加声音发射器组件
        inst.entity:AddMiniMapEntity()  -- 添加小地图实体组件
        inst.entity:AddNetwork()  -- 添加网络组件

        inst.MiniMapEntity:SetIcon("treasurechest.png")  -- 设置小地图图标

        inst:AddTag("structure")  -- 添加结构标签
        inst:AddTag("chest")  -- 添加宝箱标签

        inst:AddTag("honor_chest")

        inst.AnimState:SetBank("chest")  -- 设置动画银行
        inst.AnimState:SetBuild("treasure_chest")  -- 设置动画构建
        inst.AnimState:PlayAnimation("closed")  -- 播放关闭动画
        inst.scrapbook_anim="closed"  -- 设置剪贴簿动画状态为关闭

        inst:SetDeploySmartRadius(0.5)  -- 设置部署的智能半径
		MakeSnowCoveredPristine(inst)  -- 创建雪覆盖效果

        if common_postinit ~= nil then
            common_postinit(inst)  -- 调用通用后处理函数
        end

        inst.entity:SetPristine()  -- 将实例标记为原始，在网络客户端上不可用

        if not TheWorld.ismastersim then  -- 判断是否在主模拟下
            return inst  -- 如果不是主模拟，返回实例
        end

        inst.sounds = SOUNDS  -- 设置声音

        inst:AddComponent("inspectable")  -- 添加可检查组件
        inst:AddComponent("container")  -- 添加容器组件
        inst.components.container:WidgetSetup(name)  -- 设置容器小部件
        inst.components.container.onopenfn = onopen  -- 设置打开时的回调函数
        inst.components.container.onclosefn = onclose  -- 设置关闭时的回调函数
        inst.components.container.skipclosesnd = true  -- 跳过关闭声音
        inst.components.container.skipopensnd = true  -- 跳过打开声音

        inst:AddComponent("lootdropper")  -- 添加掉落物品组件
        inst:AddComponent("workable")  -- 添加可工作组件
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)  -- 设置工作动作为锤击
        inst.components.workable:SetWorkLeft(2)  -- 设置剩余工作次数
        inst.components.workable:SetOnFinishCallback(onhammered)  -- 设置完成工作时的回调
        inst.components.workable:SetOnWorkCallback(onhit)  -- 设置进行工作时的回调

        MakeSmallBurnable(inst, nil, nil, true)  -- 使其可燃烧
        MakeMediumPropagator(inst)  -- 设置传播效果

        inst:AddComponent("hauntable")  -- 添加可恐吓组件
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)  -- 设置恐吓值

        inst.components.burnable:SetOnBurntFn(OnBurnt)  -- 设置烧毁处理函数
        inst:ListenForEvent("ondeconstructstructure", OnDecontructStructure)  -- 监听拆解结构事件

        inst:ListenForEvent("onbuilt", onbuilt)  -- 监听建造事件
        MakeSnowCovered(inst)  -- 创建雪覆盖效果

		-- 扩展宝箱的保存/加载逻辑
        inst.OnSave = onsave  -- 设置保存回调
        inst.OnLoad = onload  -- 设置加载回调

        if master_postinit ~= nil then
            master_postinit(inst)  -- 调用主处理后处理函数
        end

        return inst  -- 返回创建的实例
    end

    return Prefab(name, fn, assets),  -- 返回预制件
            MakePlacer(name.."_placer", "chest", "treasure_chest", "closed")  -- 创建放置器
end

--------------------------------------------------------------------------
--[[ 大容量箱子 ]]
--------------------------------------------------------------------------

-- 常规初始化设置
local function space_common_postinit(inst)
    inst:AddTag("honor_chest_space")
end

-- 常规的主初始化设置
local function space_master_postinit(inst)
    inst.components.container:EnableInfiniteStackSize(true)
end

--------------------------------------------------------------------------
--[[ 传送箱子 ]]
--------------------------------------------------------------------------

local function transmit_common_postinit(inst)
    inst:AddTag("honor_chest_transmit")
end

local function transmit_master_postinit(inst)
    TheWorld:ListenForEvent("honor_backpack_giveitem", function(_, data)
        local succeed = false
        local container = inst.components.container
        for _, item in pairs(container.slots) do
            if item.prefab == data.prefab or item.name == data.prefab and data.player then
                local prefab = item.prefab
                local playerfx = SpawnPrefab("dr_warm_loop_1")
                local px, py, pz = data.player.Transform:GetWorldPosition()
                playerfx.Transform:SetPosition(px, py, pz)

                local chestfx = SpawnPrefab("lightning_rod_fx")
                local cx, cy, cz = inst.Transform:GetWorldPosition()
                chestfx.Transform:SetPosition(cx, cy, cz)

                local distance = math.sqrt((px - cx)^2 + (py - cy)^2 + (pz - cz)^2)
                local speed = 100
                local time = string.format("%.2f", distance / speed)
                if data.player.components.talker then
                    data.player.components.talker:Say(item.name.."还有".. tostring(time).. "秒才能送过来")
                end
                data.player:DoTaskInTime(time, function()
                    local fx = SpawnPrefab("halloween_firepuff_cold_"..math.random(1, 3))
                    local px2, py2, pz2 = data.player.Transform:GetWorldPosition()
                    fx.Transform:SetPosition(px2, py2, pz2)

                    if data.player and data.player.components and data.player.components.inventory then
                        data.player.components.inventory:GiveItem(SpawnPrefab(prefab))
                    end
                end)
                succeed = true

                if item.components.stackable and item.components.stackable.stacksize > 1 then
                    item.components.stackable:Get()
                else
                    item:Remove()
                end

                break
            end
        end
        if not succeed and data.player and data.player.components and data.player.components.talker and data.player.components.sanity then
            data.player.components.talker:Say("你没有这个物品")
            data.player.components.sanity:DoDelta(-5)
        end
    end)
end

--------------------------------------------------------------------------
--[[ 整理箱子 ]]
--------------------------------------------------------------------------

-- 本段代码来自loot_pump
local range = 10
local item_blacklist = {
	["lantern"]=true,
	["chester_eyebone"]=true,
	["hutch_fishbowl"]=true,
	["heatrock"]=true,
	["tallbirdegg"]=true,
	["trap"]=true,
	["birdtrap"]=true,
	["glommerflower"]=true,
	["redlantern"]=true,
	["trap_teeth"]=true,
	["beemine"]=true,
	["trap_bramble"]=true,
	["moonrockseed"]=true,
	["amulet"]=true,
    ["pumpkin_lantern"]=true,
}

-- 判断箱子是否真的装不下了
local function isreallyfull(inst, item)
    if inst.components.container:IsEmpty() or not inst.components.container:IsFull() then
        return false
    else
        for k, v in pairs(inst.components.container.slots) do
            if v.prefab == item.prefab and ((v.components.stackable and v.components.stackable.stacksize < v.components.stackable.maxsize) or (v.replica.stackable._ignoremaxsize == true)) then
                return false
            end
        end
    end
    return true
end


-- 寻找最佳的保存容器
local function findchest(item, chests)

    -- 第一轮检查是否已有容器包含该物品
    for k, v in ipairs(chests) do
        if v.components.container:Has(item.prefab, 1) then  -- 检查容器内是否已有该物品
            for ii = 1, v.components.container.numslots do
                local slot_item = v.components.container.slots[ii]  -- 获取槽位中的物品
                if not slot_item or  -- 如果槽位为空
                ( slot_item.components.stackable ~= nil  -- 如果槽位中的物品可堆叠
                    and v.components.container.acceptsstacks  -- 容器允许堆叠
                    and slot_item.prefab == item.prefab  -- 与目标物品相同
                    and slot_item.skinname == item.skinname  -- 皮肤相同
                    and not slot_item.components.stackable:IsFull()  -- 槽位未满
                    ) then
                    return v  -- 返回找到的有效容器
                end
            end
        end
    end

    -- 为易腐烂物品寻找最佳的保存容器
    if item.components.perishable then
        local perish_rate = 1  -- 初始腐坏速率
        local best_preserver
        local aux
        for k, v in ipairs(chests) do
            if not v.components.container:IsFull() and
                item.prefab ~= "spoiled_food" and 
                item.prefab ~= "rottenegg" and 
                item.prefab ~= "spoiled_fish" then
                aux = 10  -- 设定一个较大的腐坏速率
                if v.components.preserver then
                    aux = v.components.preserver:GetPerishRateMultiplier(item)
                end
                if v:HasTag("fridge") then
                    aux = TUNING.PERISH_FRIDGE_MULT
                end
                if aux < perish_rate then
                    perish_rate = aux
                    best_preserver = v
                end
            end
        end
        if best_preserver ~= nil then
            return best_preserver
        end
    end

    -- 非满的容器
    for k, v in ipairs(chests) do
        if not v.components.container:IsFull() then  -- 如果容器未满
            return v  -- 返回该容器
        end
    end
end

-- 收纳阶段,总耗时6~7秒
local function Store(inst)
    local ox, oy, oz = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(ox, oy, oz, range,{},{"fx", "decor","inlimbo","lootpump_onflight","player"})
    local begin = false
    -- 遍历周围实体，如果存在则开始任务
    for k, v in ipairs(ents) do
        if not item_blacklist[v.prefab] and v.components.inventoryitem and v.components.inventoryitem.owner == nil and v.components.inventoryitem.canbepickedup then
            begin = true
            break
        end
    end

    if not begin then
        return
    end
    -- 扫描特效
    for i = 1, 3 do
        inst:DoTaskInTime(3 - i * i *0.4, function()
            local scan_fx = SpawnPrefab("shadow_teleport_in") -- winters_feast_depletefood
            scan_fx.Transform:SetPosition(ox, oy, oz)
            scan_fx.Transform:SetScale(2.5, 2.5, 2.5)
        end)
    end
    -- 开始整理
    inst:DoTaskInTime(4, function()

        local organize_items = {}
        local chests = {}
        local real_ents = TheSim:FindEntities(ox, oy, oz, range,{},{"fx", "decor","inlimbo","lootpump_onflight","player"})
        for k, v in ipairs(real_ents) do
            if not item_blacklist[v.prefab] and v.components.inventoryitem and v.components.inventoryitem.owner == nil and v.components.inventoryitem.canbepickedup and not v:HasTag("honor_chest_organizing") then
                v:AddTag("honor_chest_organizing")
                table.insert(organize_items, v)
            end
        end

        if #organize_items == 0 then
            return
        end

        local start_fx = SpawnPrefab("charlie_snap_solid")
        start_fx.Transform:SetPosition(ox, oy, oz)

        local store_items = {}
        for i, item in ipairs(organize_items) do
            -- 判断整理箱子是否有空位
            if isreallyfull(inst, item) then
                item:RemoveTag("honor_chest_organizing")
                break
            end

            -- 如果有空位则开始收纳
            item:DoTaskInTime(math.random(), function()
                local beginstore_fx = SpawnPrefab("shadow_puff_solid")
                local ix, iy, iz = item.Transform:GetWorldPosition()
                beginstore_fx.Transform:SetPosition(ix, iy, iz)

                if item.components.stackable and item.components.stackable and item.components.stackable.stacksize > 1 then
                    item.components.stackable:Get(1)
                else
                    item:Remove()
                end
                table.insert(store_items, item.prefab)
            end)
        end

        inst:DoTaskInTime(2, function()
            local give_fx1 = SpawnPrefab("shadow_puff_large_front")
            give_fx1.Transform:SetPosition(ox, oy, oz)
            local give_fx2 = SpawnPrefab("shadow_puff_large_back")
            give_fx2.Transform:SetPosition(ox, oy, oz)

            for i, item in ipairs(store_items) do
                inst.components.container:GiveItem(SpawnPrefab(item))
            end
        end)
    end)
end

-- 清空阶段，总耗时2~3秒
local function Give(inst)

    if inst.components.container:IsEmpty() then
        return
    end

    local ox, oy, oz = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(ox, oy, oz, range,{},{"fx", "decor","inlimbo","lootpump_onflight","player"})
    local chests = {}
    for k, v in ipairs(ents) do
        if v:HasTag("honor_chest") and not v:HasTag("honor_chest_organize") and not v:HasTag("honor_chest_transmit") then
            table.insert(chests, v)
        end
    end
    if #chests == 0 then
        return
    end

    local give_fx1 = SpawnPrefab("shadow_puff_large_front")
    give_fx1.Transform:SetPosition(ox, oy, oz)
    local give_fx2 = SpawnPrefab("shadow_puff_large_back")
    give_fx2.Transform:SetPosition(ox, oy, oz)

    local isdone = false
    for num = 1, inst.components.container.numslots do
        local item = inst.components.container.slots[num]
        if item then
            for i = 1, item.components.stackable and item.components.stackable.stacksize or 1 do
                local chest = findchest(item, chests)
                if chest then
                    isdone = true
                    chest.components.container:GiveItem(SpawnPrefab(item.prefab))
                    if item.components.stackable and item.components.stackable.stacksize > 1 then
                        item.components.stackable:Get(1)
                    else
                        item:Remove()
                    end
                    chest:DoTaskInTime(2 + math.random(), function()
                        local gived_fx = SpawnPrefab("shadow_puff_solid")
                        local cx, cy, cz = chest.Transform:GetWorldPosition()
                        gived_fx.Transform:SetPosition(cx, cy, cz)
                    end)
                end
            end
        end
    end

    if isdone then
        local give_fx = SpawnPrefab("shadow_teleport_out")
        give_fx.Transform:SetPosition(ox, oy, oz)
        give_fx.Transform:SetScale(2.5, 2.5, 2.5)
    end
end

-- 整理阶段
local function Organize(inst)
    local ox, oy, oz = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(ox, oy, oz, range,{},{"fx", "decor","inlimbo","lootpump_onflight","player"})
    local chests = {}
    for k, v in ipairs(ents) do
        if v:HasTag("honor_chest") and not v:HasTag("honor_chest_organize") and not v:HasTag("honor_chest_transmit") then
            table.insert(chests, v)
        end
    end
    if #chests == 0 then
        return
    end

    -- 获取所有物品
    local allitems = {}
    for i, chest in ipairs(chests) do
        chest:AddTag("honor_chest_organizing")
        for ii, slot in pairs(chest.components.container.slots) do
            allitems[slot.prefab] = {num = (allitems[slot.prefab] and allitems[slot.prefab].num or 0) + (slot.components.stackable and slot.components.stackable.stacksize or 1), chest = chest.prefab}
        end
    end

    -- 将所有物品归纳后放入箱子
    for i, item in ipairs(allitems) do
        for ii = 1, allitems[item].num do
            for iii, chest in ipairs(chests) do
                if chest.prefab == allitems[item].chest and not isreallyfull(chest, item) then
                    chests.components.container:GiveItem(SpawnPrefab(item))
                    allitems[item].alreadygivenum = allitems[item].alreadygivenum + 1
                    if isreallyfull(chest, item) then
                        break
                    end
                end
            end
        end
        -- 如果没有放完，则随机找一个箱子爆装备
        if not allitems[item].alreadygivenum == allitems[item].num then
            for ii = 1, allitems[item].num - allitems[item].alreadygivenum do
                chests[math.random(1, #chests)].components.container:GiveItem(SpawnPrefab(item))
            end
        end
    end
end


local function organize_common_postinit(inst)
    inst:AddTag("honor_chest_organize")
end

local function organize_master_postinit(inst)
    inst.components.container:EnableInfiniteStackSize(true)

    inst:DoPeriodicTask(1, function()
        if inst.organize_task == nil then
            inst.organize_task = inst:DoTaskInTime(math.random(), function()

                -- 如果箱子已经满了则直接返回
                local itemsnum = 0
                for k, v in pairs(inst.components.container.slots) do
                    if v.components.stackable and v.components.stackable.stacksize == v.components.stackable.maxsize then
                        itemsnum = itemsnum + 1
                    else
                        itemsnum = itemsnum + 1
                    end
                end

                -- 收纳阶段
                if itemsnum < inst.components.container.numslots then
                    Store(inst)
                end


                -- 给出阶段
                inst:DoTaskInTime(4.5, function() Give(inst) end)

                -- 整理阶段
                inst:DoTaskInTime(5, function() Organize(inst) end)

                inst:DoTaskInTime(10, function()
                    inst.organize_task:Cancel()
                    inst.organize_task = nil
                end)
            end)
        end
    end)
end



-- 返回创建的宝箱和放置器
return MakeChest("honor_chest_space", space_common_postinit, space_master_postinit),
    MakeChest("honor_chest_transmit", transmit_common_postinit, transmit_master_postinit),
    MakeChest("honor_chest_organize", organize_common_postinit, organize_master_postinit)