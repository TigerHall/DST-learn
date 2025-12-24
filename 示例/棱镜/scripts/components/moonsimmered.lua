local cooking = require("cooking")
local skinchecks = { --要是有新的，烹饪组件里也得改！！！
	dish_tomahawksteak = "dish_tomahawksteak"
}

local function GetFoodSkin(name, item, chefid)
	local va
	if item ~= nil then
		va = item.components.skinedlegion
		if va ~= nil and va.skin ~= nil then
			return { skin = va.skin, userid = va.userid, prefab = va.prefab }
		end
	elseif chefid ~= nil then
		for k, v in pairs(skinchecks) do
			if string.match(name, k) ~= nil then
				va = v
				break
			end
		end
		if va ~= nil then
			local lastskin = LS_LastChosenSkin(va, chefid)
			if lastskin ~= nil then
				return { skin = lastskin, userid = chefid, prefab = va }
			end
		end
	end
end
local function _TaskCook(inst, self)
	self.time_pass = (self.time_pass or 0) + 5*self.time_mult
	self.time_start = GetTime()
	self:DoCooking()
end
local function _TaskRoast(inst, self)
	self.time_pass = (self.time_pass or 0) + 5*self.time_mult
	self.time_start = GetTime()
	self:DoRoasting()
end

local MoonSimmered = Class(function(self, inst)
    self.inst = inst

	-- self.todos = nil --处理中的数据
	-- self.todokey = nil --处理类型。1烹饪与调味、2烤制
	-- self.time_start = nil --开始烹饪时的时间点
	-- self.time_pass = nil --已经经过的时间
	-- self.task_simmer = nil
	-- self.cooking = nil

	-- self.opener = nil --当前正在打开容器的玩家。如果为空就代表容器未被打开
	-- self.lastslot = nil --最近一次操作的行数，用来确定该预测哪一行的食物

	self.show = {
		-- name = "", --对应recipe里的 name，用来判断是否发生改变
		-- build_dish = "", symbol_dish = "", prefab_dish = "", potlevel = "low",
		-- build_spice = "", symbol_spice = "", prefab_spice = ""
		-- skin = ""
	}
	-- self.spiceanims = nil

	-- self.chef_id = nil --玩家id
	-- self.chef = nil --玩家
	self.time_mult = 1 --加速系数
	self.perishpercent = 0 --对烹饪产物的新鲜度比例的加成，区间0-0.5

	self.fn_itemcg = function(myself, data)
		if not self.cooking and data and data.slot then --无视烹饪时对物品的操作
			self:SlotFix(data.slot)
		end
	end
	inst:ListenForEvent("itemget", self.fn_itemcg) --只有空格子放上物品时才触发，已有物品叠加数变化时不会触发的
	inst:ListenForEvent("itemlose", self.fn_itemcg) --只有格子失去整个物品时才触发，已有物品叠加数变化时不会触发的
end)

function MoonSimmered:SetChef(doer)
	local id = (doer ~= nil and doer.player_classified ~= nil) and doer.userid or nil --是个真的玩家才行
	if id ~= nil and id ~= "" then
		self.chef_id = id
		self.chef = doer
	else
		self.chef_id = nil
		self.chef = nil
	end
end
function MoonSimmered:SetCookData(idx, lines)
	local dd = lines[idx]
	if dd == nil then return end
	if dd.spice ~= nil then
		if dd.spice[1] ~= nil and dd.items[1] ~= nil then --料理和调料缺一不可
			dd.names = { dd.items[1].prefab, dd.spice[1].prefab }
			dd.product = cooking.CalculateRecipe("portablespicer", dd.names)
			if dd.product ~= nil then
				dd.recipe = cooking.GetRecipe("portablespicer", dd.product)
			end
		end
	else
		dd.product = cooking.CalculateRecipe("portablecookpot", dd.names)
		if dd.product ~= nil then
			dd.recipe = cooking.GetRecipe("portablecookpot", dd.product)
		end
	end
	if dd.recipe ~= nil then
		dd.time = TUNING.BASE_COOK_TIME * (dd.recipe.cooktime or 1) --确定烹饪时间
		local perishtime = dd.recipe.perishtime or 0
		if perishtime > 0 then --确定产物的基础新鲜度
			local spoilage_total = 0
			local spoilage_n = 0
			local items
			if dd.spice ~= nil then
				items = { dd.items[1], dd.spice[1] }
			else
				items = dd.items
			end
			for _, v in pairs(items) do
				if v.components.perishable ~= nil then
					spoilage_n = spoilage_n + 1
					spoilage_total = spoilage_total + v.components.perishable:GetPercent()
				end
			end
			if spoilage_n <= 0 then --都没有新鲜度时，就是100%新鲜度
				dd.perishpercent = 1
			elseif dd.spice ~= nil then --调味时，保持已有的平均新鲜度
				dd.perishpercent = spoilage_total / spoilage_n
			else --烹饪时，减少50%损失的平均新鲜度。这样烹饪产物新鲜度必定在50%以上
				dd.perishpercent = 1 - (1 - spoilage_total/spoilage_n) * 0.5
			end
			if dd.perishpercent >= 1 then --如果基础新鲜度是100%，那就没必要记录了
				dd.perishpercent = nil
			end
		end
		if dd.spice ~= nil then
			dd.skins = GetFoodSkin(nil, dd.items[1], nil)
		else
			dd.skins = GetFoodSkin(dd.product, nil, self.chef_id)
		end
	else
		lines[idx] = nil
	end
end
function MoonSimmered:TryCooking(doer) --尝试开始 烹饪、调味
	if doer ~= nil then self:SetChef(doer) end
	local cpt = self.inst.components.container
	if cpt == nil then return end
	local lines = {}
	local idx = 1
	local item, dd, hastodo
	for i = 1, cpt.numslots do
		if i > 5 then --确认分组
			if i <= 10 then
				idx = 2
			elseif i <= 15 then
				idx = 3
			elseif i <= 20 then
				idx = 4
			end
		end
		dd = lines[idx]
		if dd == nil then
			dd = {
				items = {}, --物品
				names = {}, --物品prefab名
				-- skins = { skin = "", userid = "", prefab = "" }
				-- spice = {}, --香料。不为空时说明是 调味 动作
				-- product = nil, --产物prefab
				-- recipe = nil, --食谱数据
				-- time = nil, --单个的所需时间。单位秒
				-- perishpercent = nil --基础新鲜度
			}
			lines[idx] = dd
		end
		if i%5 == 0 then --说明是第五列。开始做总结
			self:SetCookData(idx, lines)
			if not hastodo and lines[idx] ~= nil then
				hastodo = true
				dd = lines[idx]
				self:ShowOn(dd.recipe, dd.skins)
			end
		else --前四列就只收集信息
			item = cpt.slots[i]
			if item == nil then --烹饪的话，不能有空的
				if dd.spice == nil then --那就只能视为是 调味
					dd.spice = {}
					dd.items = {}
					dd.names = {}
				end
			else
				if item:HasTag("preparedfood") then --是料理，归为调味动作
					if dd.spice == nil then
						dd.spice = {}
						dd.items = {}
						dd.names = {}
					end
					if not item:HasTag("spicedfood") then --排除掉已经调料过的料理
						table.insert(dd.items, item)
					end
				elseif item:HasTag("spice") then --是香料，归为调味动作
					if dd.spice == nil then
						dd.spice = {}
						dd.items = {}
						dd.names = {}
					end
					table.insert(dd.spice, item)
				elseif dd.spice == nil then --没有调味动作时，就归为烹饪
					if cooking.IsCookingIngredient(item.prefab) then
						table.insert(dd.items, item)
						table.insert(dd.names, item.prefab)
					else --一旦有物品不是烹饪食材，就归为调味动作
						dd.spice = {}
						dd.items = {}
						dd.names = {}
					end
				end
			end
		end
	end
	if hastodo then
		self.todos = lines
		self.todokey = 1
		self:StartSimmering()
	else
		self:ShowOff()
	end
	self:SetFx(hastodo)
end
function MoonSimmered:TryRoasting(doer) --尝试开始 烤制
	if doer ~= nil then self:SetChef(doer) end
	self:ShowOff()
	local cpt = self.inst.components.container
	if cpt == nil then return end
	local lines = {}
	local item
	for i = 1, cpt.numslots do
		item = cpt.slots[i]
		if item ~= nil and item.components.cookable ~= nil and item.components.cookable.product ~= nil then
			table.insert(lines, item)
		end
	end
	if lines[1] ~= nil then
		self.todos = lines
		self.todokey = 2
		self:StartSimmering()
		self:SetFx(true)
	else
		self:SetFx(false)
	end
end
function MoonSimmered:BtnCook(doer)
	self:StopSimmering() --暂停烹饪
	if self.inst.components.container ~= nil then
		self.inst.components.container:Close() --关闭容器
		self:TryCooking(doer) --开始！
	end
end
function MoonSimmered:BtnRoast(doer)
	self:StopSimmering() --暂停烹饪
	if self.inst.components.container ~= nil then
		self.inst.components.container:Close() --关闭容器
		self:TryRoasting(doer) --开始！
	end
end

local function DilutePerishTime(perishcpt, oldpercent, num, numadd)
	if perishcpt.perishremainingtime and perishcpt.perishtime and perishcpt.perishtime > 0 then
		local p = math.min(1, oldpercent) --最高为100%
		p = (num * perishcpt.perishremainingtime/perishcpt.perishtime) + numadd * p
		perishcpt:SetPercent( p/(num+numadd) ) --SetPercent()自带限制数值大小的效果，所以这里不再重复操作
	end
end
local function PutItemsTogether(self, olditems, newstack)
	local newperish = newstack.inst.components.perishable
	local n_newleft = newstack:RoomLeft()
	local n_add, n_oldnow, cpt, n_newnow
	for slot, oldstack in pairs(olditems.items) do
		n_newnow = newstack:StackSize() --新物品的当前叠加数
		n_oldnow = oldstack:StackSize() --旧物品的当前叠加数
		if n_oldnow >= n_newleft then
			newstack:SetStackSize(newstack.maxsize)
			n_add = n_newleft --记录新增的数量
			n_newleft = 0
			n_oldnow = n_oldnow - n_add
		else
			newstack:SetStackSize(n_newnow + n_oldnow)
			n_add = n_oldnow
			n_newleft = n_newleft - n_oldnow
			n_oldnow = 0
		end
		olditems.num = olditems.num - n_add --更新旧物品的总数量
		if newperish ~= nil then --平均两个物品的新鲜度
			cpt = oldstack.inst.components.perishable
			DilutePerishTime(newperish, cpt ~= nil and cpt:GetPercent() or 1, n_newnow, n_add)
		end
		if n_oldnow <= 0 then --全部叠加好了，从容器里移除
			self.inst.components.container.slots[slot] = nil
			self.inst:PushEvent("itemlose", { slot = slot, prev_item = oldstack.inst })
			oldstack.inst:Remove()
		else
			oldstack:SetStackSize(n_oldnow)
		end
		if n_newleft <= 0 then --新物品已加满，不能继续了
			break
		end
	end
end
local function DealBoxes(self, boxes, emptyslots, items)
	local item
	for ent, cpt in pairs(boxes) do
		for i = 1, cpt.numslots do
			item = cpt.slots[i]
			if item == nil then
				table.insert(emptyslots, { box = ent, slot = i })
			elseif item:IsValid() and items[item.prefab] ~= nil and
				item.components.stackable ~= nil and not item.components.stackable:IsFull()
			then
				PutItemsTogether(self, items[item.prefab], item.components.stackable)
				if items[item.prefab].num <= 0 then
					items[item.prefab] = nil
				end
			end
		end
	end
end
local function PutItemsInslots(cpt, emptyslots, oldslot, oldstack)
	local ocpt, item
	for k, slotdd in pairs(emptyslots) do
		ocpt = slotdd.box.components.container
		if ocpt:CanTakeItemInSlot(oldstack.inst, slotdd.slot) then
			emptyslots[k] = nil
			if ocpt.infinitestacksize or not oldstack:IsOverStacked() then --如果容器是无限叠加的，或者物品没有超过上限，就直接全挪
				cpt.ignoreoverstacked = true
				item = cpt:RemoveItem_Internal(oldstack.inst, oldslot, true, false)
				cpt.ignoreoverstacked = false
				ocpt:GiveItem(item, slotdd.slot, nil, true)
				return true
			else --否则就得一组一组挪了
				item = cpt:RemoveItem_Internal(oldstack.inst, oldslot, true, true)
				ocpt:GiveItem(item, slotdd.slot, nil, true)
				return PutItemsInslots(cpt, emptyslots, oldslot, oldstack)
			end
		end
	end
end
local function TryClearSlots(self, doer)
	local cmd = self.inst.legion_cleardd
	local cpt = self.inst.components.container
	if cmd == nil or cpt == nil then return end
	self.cooking = true

	local items = {} --可叠加的物品合集
	local oneitems = {} --不能叠加的物品合集
	local item, name, val
	if cmd.idx1 ~= nil then
		local newcmd = {}
		for i = cmd.idx1, cmd.idx2, 1 do
			table.insert(newcmd, i)
		end
		cmd = newcmd
	end
	for _, i in ipairs(cmd) do
		item = cpt.slots[i]
		if item ~= nil and item:IsValid() then
			name = item.prefab
			if item.components.stackable ~= nil then
				if items[name] == nil then
					items[name] = { items = {}, num = 0 }
				end
				items[name].items[i] = item.components.stackable
				items[name].num = items[name].num + item.components.stackable:StackSize()
			else
				oneitems[i] = item
			end
			if self.todokey ~= nil then
				if self.todokey == 1 then --烹饪时不能清除1至4列的物品
					if i%5 ~= 0 then
						val = true
						self:ShowOff()
					end
				elseif self.todokey == 2 then --烤制时任何物品都不能清除
					val = true
				end
				if val then
					self.time_pass = nil
					self:StopSimmering()
					self:SetFx(false)
				end
			end
		end
	end
	if next(items) == nil and next(oneitems) == nil then return end --没有物品。结束！

	------查询并分类周围的保鲜容器
	local noboxtype = { cooker = true, pack = true, backpack = true, top_rack = true, hand_inv = true, side_inv_behind = true }
	local boxes = {}
	local weakboxes = {}
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local ocpt, ocpt2, val2
    local ents = TheSim:FindEntities(x, y, z, 8, { "_container" }, { "NOCLICK", "FX", "INLIMBO" }) --检测周围箱子
	for _, ent in ipairs(ents) do
		ocpt = ent.components.container
		if ent ~= self.inst and ocpt ~= nil and not ent.legiontag_notfoodbox and ocpt.canbeopened and
			ocpt.acceptsstacks and ocpt.type ~= nil and not noboxtype[ocpt.type] and
			ent.components.stewer == nil and ent.components.moonsimmered == nil
		then
			ocpt2 = ent.components.medal_immortal
			if ocpt2 ~= nil and ocpt2.GetLevel ~= nil and (ocpt2:GetLevel() or 0) > 0 then --不朽容器，那就是永久保鲜的
				val2 = true
			elseif ent.prefab == "hiddenmoonlight" or ent.prefab == "hiddenmoonlight_inf" then --棱镜保鲜箱
				val2 = true
			elseif ent.components.preserver ~= nil then
				val = ent.components.preserver:GetPerishRateMultiplier(ent) or 1
				if val < 1 then --如果连起码的保鲜效果都没有，那就不算是保鲜容器
					val2 = val < 0.5
				end
			elseif ent:HasAnyTag("fridge", "foodpreserver") then --能靠标签提高保鲜能力的
				val2 = false
			end
			if val2 ~= nil then
				if val2 or ocpt.infinitestacksize or ent.legiontag_goodfoodbox then --能无限叠加的保鲜容器优先度高
					boxes[ent] = ocpt
				else
					weakboxes[ent] = ocpt
				end
				val2 = nil
			end
		end
	end
	if next(boxes) == nil and next(weakboxes) == nil then return end --没有合适的箱子。结束！

	------先把能叠加的物品都叠加到各个容器里去
	local emptyslots = {}
	val = next(oneitems) == nil
	if next(boxes) ~= nil then
		DealBoxes(self, boxes, emptyslots, items)
		if next(items) == nil and val then return end --物品已经完成迁移，结束！
	end
	if next(weakboxes) ~= nil then
		DealBoxes(self, weakboxes, emptyslots, items)
		if next(items) == nil and val then return end --物品已经完成迁移，结束！
	end
	if next(emptyslots) == nil then return end --没有多余的格子了，结束！

	------再把剩余的物品放入空格子里
	if next(items) ~= nil then
		for prefab, tbitems in pairs(items) do
			val2 = {}
			ocpt2 = nil
			for oldslot, oldstack in pairs(tbitems.items) do --将所有同类物品尽量叠加到一起
				if oldstack:IsFull() then
					val2[oldslot] = oldstack
				elseif ocpt2 == nil then
					val2[oldslot] = oldstack
					ocpt2 = oldstack
				else
					local oldsize = ocpt2:StackSize()
					local roomleft = ocpt2:RoomLeft()
					local num = oldstack:StackSize()
					if num >= roomleft then
						ocpt2:SetStackSize(ocpt2.maxsize)
						num = num - roomleft
					else
						ocpt2:SetStackSize(oldsize + num)
						roomleft = num --这个是为了记录新增的数量
						num = 0
					end
					if ocpt2.inst.components.perishable ~= nil then
						DilutePerishTime(ocpt2.inst.components.perishable,
							oldstack.inst.components.perishable and oldstack.inst.components.perishable:GetPercent() or 1,
							oldsize, roomleft)
					end
					if num <= 0 then
						cpt.slots[oldslot] = nil
						self.inst:PushEvent("itemlose", { slot = oldslot, prev_item = oldstack.inst })
						oldstack.inst:Remove()
						if ocpt2:IsFull() then --这组满了，得开始下一组了
							ocpt2 = nil
						end
					else
						oldstack:SetStackSize(num)
						val2[oldslot] = oldstack --有剩余，说明之前的ocpt2已经叠满了
						ocpt2 = oldstack
					end
				end
			end
			for oldslot, oldstack in pairs(val2) do
				PutItemsInslots(cpt, emptyslots, oldslot, oldstack) --结果如何不用管
				if next(emptyslots) == nil then return end
			end
		end
	end
	if not val then
		for oldslot, it in pairs(oneitems) do
			for k, slotdd in pairs(emptyslots) do
				ocpt = slotdd.box.components.container
				if ocpt:CanTakeItemInSlot(it, slotdd.slot) then
					emptyslots[k] = nil
					item = cpt:RemoveItem_Internal(it, oldslot, true, false)
					ocpt:GiveItem(item, slotdd.slot, nil, true)
					if next(emptyslots) == nil then return end
				end
			end
		end
	end
end
function MoonSimmered:BtnClear(doer)
	TryClearSlots(self, doer)
	self.cooking = nil
end

function MoonSimmered:SpawnProduct(product, perishpercent, num, slot, skins)
	local container = self.inst.components.container
	local cpt
	if slot ~= nil and container ~= nil and slot <= container.numslots then --优先叠加到对应格子
		local oitem = container.slots[slot]
		if oitem ~= nil then
			if oitem.prefab == product then --如果格子上有同类物品
				cpt = oitem.components.stackable
				if cpt ~= nil and not cpt:IsFull() then
					local oldsize = cpt:StackSize()
					local roomleft = cpt:RoomLeft()
					if num >= roomleft then
						cpt:SetStackSize(cpt.maxsize)
						num = num - roomleft
						slot = nil --如果已经满了，就不该继续查询了
					else
						cpt:SetStackSize(oldsize + num)
						roomleft = num --这个是为了记录新增的数量
						num = 0
					end
					if oitem.components.perishable ~= nil then
						DilutePerishTime(oitem.components.perishable, (perishpercent or 1)+self.perishpercent, oldsize, roomleft)
					end
					if skins ~= nil then
						cpt = oitem.components.skinedlegion
						if cpt ~= nil and cpt.prefab == skins.prefab then
							cpt:SetSkin(skins.skin, skins.userid)
						end
					end
					if num < 1 then
						return true
					end
				else
					slot = nil --无法叠加或者已经满了，就不该继续查询了
				end
			else
				slot = nil --格子上是别的物品，就不能继续查询了
			end
		end
	end
	local item = SpawnPrefab(product) --如果还有剩余，那就生成新的往容器里放
	if item == nil then return end
	cpt = item.components.stackable
	if num > 1 and cpt ~= nil then
		local maxsize = cpt.maxsize
		if num <= maxsize then
			cpt:SetStackSize(num)
			num = 0
		else
			cpt:SetStackSize(maxsize)
			num = num - maxsize
		end
	else
		num = num - 1
	end
	if perishpercent ~= nil and (perishpercent+self.perishpercent) < 1 then --最终新鲜度100%时没必要再操作
		if item.components.perishable ~= nil then --SetPercent()自带限制数值大小的效果，所以这里不再重复操作
			item.components.perishable:SetPercent(perishpercent + self.perishpercent)
		end
	end
	if skins ~= nil then
		cpt = item.components.skinedlegion
		if cpt ~= nil and cpt.prefab == skins.prefab then
			cpt:SetSkin(skins.skin, skins.userid)
		end
	end
	item.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
	if item.components.inventoryitem ~= nil then
		if container ~= nil then
			container:GiveItem(item, slot)
		else
			item.components.inventoryitem:OnDropped(true)
			item:PushEvent("l_autostack")
		end
	end
	if num >= 1 then
		return self:SpawnProduct(product, perishpercent, num, slot, skins)
	end
	return true
end
function MoonSimmered:ComputAndCost(times, items, idx)
	local itemminnum, num
	local itemmap = {}
	self.fixidx = nil
	for _, v in pairs(items) do
		if v:IsValid() then
			num = v.components.stackable ~= nil and v.components.stackable:StackSize() or 1
			itemmap[v] = num
			if itemminnum == nil or itemminnum > num then --记录最小的那个数量
				itemminnum = num
			end
		else --有物品是无效的了，说明本行数据该清理了，不再继续烹饪
			self.fixidx = idx
			return times
		end
	end
	if itemminnum ~= nil and itemminnum > 0 then
		if times > itemminnum then
			times = times - itemminnum
		else
			itemminnum = times
			times = 0
		end
		for item, n in pairs(itemmap) do --先移除材料
			if n > itemminnum then
				item.components.stackable:SetStackSize(n - itemminnum)
			else
				item:Remove()
				self.fixidx = idx --有物品被删除，就说明数量不够了，需要调整
			end
		end
		local dd = self.todos[idx]
		if dd.product ~= nil then --再生成产物
			num = dd.recipe and dd.recipe.stacksize or 1
			if num > 1 then
				itemminnum = math.max(1, math.floor(itemminnum*num) ) --主要是怕乘法出问题，所以这里用math.floor加以限制
			end
			num = nil
			if idx == 1 then --产物优先放入第五列。不想用乘法
				num = 5
			elseif idx == 2 then
				num = 10
			elseif idx == 3 then
				num = 15
			elseif idx == 4 then
				num = 20
			end
			local success = self:SpawnProduct(dd.product, dd.perishpercent, itemminnum, num, dd.skins)
			if success then --兼容食谱
				if self.chef ~= nil and self.chef:IsValid() and self.chef_id ~= nil and dd.recipe ~= nil and
					dd.recipe.cookbook_category ~= nil and
					cooking.cookbook_recipes[dd.recipe.cookbook_category] ~= nil and
					cooking.cookbook_recipes[dd.recipe.cookbook_category][dd.product] ~= nil
				then
					self.chef:PushEvent("learncookbookrecipe", { product = dd.product, ingredients = dd.names })
				end
			end
		end
	end
	return times
end
function MoonSimmered:DoCooking()
	if self.todos == nil or self.time_pass == nil or self.time_pass <= 0 then
		return
	end
	self.cooking = true
	local times, times2, lastrecipe, lastskin
	for idx, v in pairs(self.todos) do
		if v.time ~= nil then
			if self.time_pass < v.time then --从上到下，按顺序来！所以只判断一次
				break
			end
			times = math.floor(self.time_pass/v.time)
			if v.spice ~= nil then --调味
				times2 = self:ComputAndCost(times, { v.items[1], v.spice[1] }, idx)
			else --烹饪
				times2 = self:ComputAndCost(times, v.items, idx)
			end
			if times > times2 then --说明有消耗
				self.time_pass = self.time_pass - (times-times2)*v.time
			end
			if self.fixidx == idx then --说明有物品无效或者被消耗完了，需要调整数据
				self.fixidx = nil
				lastrecipe = v.recipe
				lastskin = v.skins
				if v.spice ~= nil then --调味时缺材料了，就判断还有没有别的料理或香料
					local newtb = { items = {}, names = {}, spice = {} }
					for _, vv in pairs(v.spice) do
						if vv:IsValid() then
							table.insert(newtb.spice, vv)
						end
					end
					for _, vv in pairs(v.items) do
						if vv:IsValid() then
							table.insert(newtb.items, vv)
						end
					end
					self.todos[idx] = newtb
					self:SetCookData(idx, self.todos) --判定下一个能组合的
				else --烹饪时缺食材了，就该结束了
					self.todos[idx] = nil
				end
			else --如果没有物品被消耗掉，那就说明还可以继续，那就不能往下判断了，因为得从上往下按顺序来
				break
			end
		end
	end
	self.cooking = nil
	for _, v in pairs(self.todos) do
		if v.time ~= nil then
			self:ShowOn(v.recipe, v.skins)
			return
		end
	end
	self.time_pass = nil
	self:StopSimmering()
	self:ShowOn(lastrecipe, lastskin) --留下最后一个烹饪料理的贴图
end
function MoonSimmered:DoRoasting()
	local timecost = 2
	if self.todos == nil or self.time_pass == nil or self.time_pass < timecost then
		return
	end
	self.cooking = true
	local times, num, prod, cpt, percent, hasitem
	for idx, v in pairs(self.todos) do
		cpt = v.components.cookable
		if v:IsValid() and cpt ~= nil and cpt.product ~= nil then
			if self.time_pass >= timecost then
				prod = type(cpt.product) == "function" and cpt.product(v, self.inst, self.chef) or cpt.product
				if prod ~= nil then
					times = math.floor(self.time_pass/timecost)
					num = v.components.stackable ~= nil and v.components.stackable:StackSize() or 1
					if v.components.perishable ~= nil and not v:HasTag("smallcreature") then
						percent = 1 - (1 - v.components.perishable:GetPercent()) * 0.5
					else
						percent = nil
					end
					if cpt.oncooked ~= nil then
						cpt.oncooked(v, self.inst, self.chef)
					end
					if times >= num then --先移除材料
						times = num
						v:Remove()
						self.todos[idx] = nil
					else --能消耗的值都小于叠加数，说明必定是能叠加的
						v.components.stackable:SetStackSize(num - times)
						hasitem = true
					end
					self:SpawnProduct(prod, percent, times, nil, nil) --再生成产物
					self.time_pass = self.time_pass - timecost*times
				else
					self.todos[idx] = nil
				end
			else
				hasitem = true
				break --这一个的时间都不够，那就直接结束吧
			end
		else
			self.todos[idx] = nil
		end
	end
	self.cooking = nil
	if not hasitem then
		self.time_pass = nil
		self:StopSimmering()
	end
end
function MoonSimmered:LongUpdate(dt)
	if self.todokey ~= nil then --在烹饪中
		local timenow = GetTime()
		if self.time_start ~= nil then
			if timenow > self.time_start then
				local dtt = timenow - self.time_start
				if dtt >= dt then --从洞穴上地面，地面对象可能就是触发这个情况。别把时间算多了
					dt = dtt
				else --这种应该是单纯的跳时间，比如用t键模组跳时间。需要把已经过去的时间给补上
					dt = dt + dtt
				end
			end
			self.time_start = timenow
		end
		self.time_pass = (self.time_pass or 0) + dt*self.time_mult --只加时间量就行，逻辑会在下次周期函数时处理的
	end
end

function MoonSimmered:StartSimmering()
	if self.task_simmer ~= nil then
		self.task_simmer:Cancel()
	end
	if self.todokey == nil then
		self.task_simmer = nil
	elseif self.todokey == 1 then
		self.task_simmer = self.inst:DoPeriodicTask(5, _TaskCook, 5, self)
	else
		self.task_simmer = self.inst:DoPeriodicTask(2.5, _TaskRoast, 2.5, self)
	end
	if self.task_simmer ~= nil then
		self.time_start = GetTime()
	end
end
function MoonSimmered:PauseSimmering() --暂停
	if self.task_simmer ~= nil then
		self.task_simmer:Cancel()
		self.task_simmer = nil
	end
	if self.time_start ~= nil and self.todokey ~= nil then --暂停时需要保存已经过时间
		self.time_pass = (self.time_pass or 0) + (GetTime()-self.time_start)*self.time_mult
	end
	self.time_start = nil
end
function MoonSimmered:StopSimmering()
	if self.task_simmer ~= nil then
		self.task_simmer:Cancel()
		self.task_simmer = nil
	end
	self.todos = nil
	self.todokey = nil
	-- self.time_pass = nil
	self.time_start = nil
end

function MoonSimmered:SetFx(isadd)
	if isadd then
		if self.fx ~= nil then
			return
		end
		local fx = SpawnPrefab("simmerfire_l_fx")
		if fx ~= nil then
			self.fx = fx
			fx.entity:SetParent(self.inst.entity)
			fx.Follower:FollowSymbol(self.inst.GUID, "swap_cooked", 0, -80, 0)
			fx.components.highlightchild:SetOwner(self.inst)
		end
		self.inst.perishrate_l = 0 --特效存在时，永久保鲜
	else
		if self.fx == nil then
			return
		end
		if self.fx:IsValid() then
			self.fx:Remove()
		end
		self.fx = nil
		self.inst.perishrate_l = 0.75
	end
end
function MoonSimmered:ShowOn(recipe, skins)
	if recipe == nil then return end
	if recipe.name == self.show.name then
		if (skins and skins.skin or nil) == self.show.skin then --说明是相同的，没必要重复操作了
			return
		end
	end
	local realname = recipe.basename or recipe.name
	local dd = { name = recipe.name }
	--料理部分
	dd.build_dish = recipe.overridebuild
	if dd.build_dish == nil then
		dd.build_dish = IsModCookingProduct("portablecookpot", realname) and realname or "cook_pot_food"
	end
	dd.prefab_dish = realname
	dd.symbol_dish = recipe.overridesymbolname or realname
	dd.potlevel = recipe.potlevel
	--香料部分
	if recipe.spice ~= nil then
		dd.prefab_spice = string.lower(recipe.spice)
		if recipe.build_spice ~= nil then --其他模组要兼容，可在recipe里添加 build_spice 和 symbol_spice 属性
			dd.build_spice = recipe.build_spice
			dd.symbol_spice = recipe.symbol_spice or dd.prefab_spice
		elseif self.spiceanims ~= nil and self.spiceanims[dd.prefab_spice] ~= nil then
			dd.build_spice = self.spiceanims[dd.prefab_spice].build or "spices"
			dd.symbol_spice = self.spiceanims[dd.prefab_spice].symbol or dd.prefab_spice
		else
			dd.build_spice = "spices"
			dd.symbol_spice = dd.prefab_spice
		end
	end
	--料理贴图切换
	local inst = self.inst
	if dd.prefab_dish ~= self.show.prefab_dish then
		if dd.potlevel == "high" then
			inst.AnimState:Show("swap_high")
			inst.AnimState:Hide("swap_mid")
			inst.AnimState:Hide("swap_low")
		elseif dd.potlevel == "low" then
			inst.AnimState:Hide("swap_high")
			inst.AnimState:Hide("swap_mid")
			inst.AnimState:Show("swap_low")
		else
			inst.AnimState:Hide("swap_high")
			inst.AnimState:Show("swap_mid")
			inst.AnimState:Hide("swap_low")
		end
	end
	inst.AnimState:OverrideSymbol("swap_cooked", dd.build_dish, dd.symbol_dish)
	--香料贴图切换
	if dd.prefab_spice ~= self.show.prefab_spice then
		if dd.build_spice ~= nil then
			-- inst.AnimState:OverrideSymbol("swap_plate", "plate_food", "plate")
			inst.AnimState:OverrideSymbol("swap_garnish", dd.build_spice, dd.symbol_spice)
		else
			-- inst.AnimState:ClearOverrideSymbol("swap_plate")
			inst.AnimState:ClearOverrideSymbol("swap_garnish")
		end
	end
	--料理皮肤兼容
	if inst.legion_dishfofx ~= nil then
        inst.legion_dishfofx:Remove()
        inst.legion_dishfofx = nil
    end
	if skins ~= nil then
		local skindd = ls_skineddata[skins.skin]
		if skindd ~= nil and skindd.fn_stewer ~= nil then
			skindd.fn_stewer(inst, self)
		end
		dd.skin = skins.skin
	end
	self.show = dd
end
function MoonSimmered:ShowOff()
	if self.show.name == nil then
		return
	end
	self.inst.AnimState:ClearOverrideSymbol("swap_cooked")
	-- self.inst.AnimState:ClearOverrideSymbol("swap_plate")
	self.inst.AnimState:ClearOverrideSymbol("swap_garnish")
	self.show = {}
	if self.inst.legion_dishfofx ~= nil then
        self.inst.legion_dishfofx:Remove()
        self.inst.legion_dishfofx = nil
    end
end

function MoonSimmered:OnSave()
    local data = {}
	if self.todokey ~= nil then --说明还在烹饪中。反正要重新判定，所以不需要保存fx和贴图
		data.todokey = self.todokey
		data.time_pass = self.time_pass
		data.chef_id = self.chef_id
	elseif self.fx ~= nil then --说明已完成，但是还没被打开过
		data.fx = true
		if self.show.name ~= nil then
			data.product = self.show.name
			data.spiced = self.show.prefab_spice ~= nil
			data.skin_l = self.show.skin
		end
	end
    return data
end
function MoonSimmered:OnLoad(data)
    if data == nil then
        return
    end
	if data.fx or data.todokey ~= nil then
		if data.time_pass ~= nil then
			self.time_pass = (self.time_pass or 0) + data.time_pass
		end
		if self.task_init == nil then
			local todokey = data.todokey
			local chef_id = data.chef_id
			local fx = data.fx
			local product = data.product
			local spiced = data.spiced
			local skins = data.skin_l and { skin = data.skin_l } or nil
			self.inst.candismantle = function() return false end --没加载好之前，不可以被“收回”
			self.task_init = self.inst:DoTaskInTime(0.3, function() --延迟执行，因为此时容器内物品可能还没准备好
				self.task_init = nil
				self.inst.candismantle = nil --可以被收回了
				if self.todokey == nil and self.opener == nil then --说明没开始烹饪，也没被打开。就得重新判定，或者加载fx和贴图
					if todokey == 1 then
						self.chef_id = chef_id
						self:TryCooking()
					elseif todokey == 2 then
						self.chef_id = chef_id
						self:TryRoasting()
					elseif fx then
						self:SetFx(true)
						if product ~= nil then --恢复料理贴图
							local recipe = cooking.GetRecipe(spiced and "portablespicer" or "portablecookpot", product)
							self:ShowOn(recipe, skins)
						end
					end
				end
			end)
		end
	end
end

function MoonSimmered:OnBoxOpen(doer)
	self.opener = doer
	if self.todokey ~= nil then --如果正在烹饪，就暂停吧
		self:PauseSimmering()
	else --没有烹饪，那就该清理贴图了
		self:ShowOff()
	end
end
function MoonSimmered:OnBoxClose()
	self.opener = nil
	if self.todokey ~= nil then --如果还能烹饪，就继续吧
		if self.task_simmer == nil then
			self:StartSimmering()
		end
	else --没有烹饪，那就该清理贴图了（这里主要是清理预测的贴图）
		self:ShowOff()
		self:SetFx(false) --打开一次，就不能永久保鲜了
	end
	if self.task_slotfix ~= nil then --停止预测
		self.task_slotfix:Cancel()
		self.task_slotfix = nil
		self.lastslot = nil
	end
end
function MoonSimmered:SlotFix(slot)
	if self.todokey ~= nil and slot%5 ~= 0 then --物品发生变动(除了第五列)，停止烹饪。玩家拿取第五列的料理不会导致烹饪中断
		self.time_pass = nil
		self:StopSimmering()
		self:SetFx(false)
	end
	if self.opener == nil or self.todokey ~= nil then --未打开或烹饪时是不会进行预测的
		return
	end
	self.lastslot = slot
	if self.task_slotfix == nil then --被打开着，且下一帧才执行预测操作，这样能防止不必要的触发
		self.task_slotfix = self.inst:DoTaskInTime(0, function()
			self.task_slotfix = nil
			if self.todokey ~= nil or self.opener == nil then --已经开始烹饪，或者没有打开了，就不该预测了
				return
			end
			local cpt = self.inst.components.container
			if cpt == nil then return end
			local id = 1
			if self.lastslot ~= nil then
				id = self.lastslot
				self.lastslot = nil
				if id <= 5 then
					id = 1
				elseif id <= 10 then
					id = 6
				elseif id <= 15 then
					id = 11
				elseif id <= 20 then
					id = 16
				else
					id = 1
				end
			end
			local names = {}
			local item, spice, dish
			for i = 0, 3, 1 do
				item = cpt.slots[id + i]
				if item ~= nil and item:IsValid() then
					if item:HasTag("preparedfood") then
						names = nil
						if dish == nil and not item:HasTag("spicedfood") then
							dish = item
						end
					elseif item:HasTag("spice") then
						names = nil
						if spice == nil then
							spice = item
						end
					elseif names ~= nil then
						if cooking.IsCookingIngredient(item.prefab) then
							table.insert(names, item.prefab)
						else
							names = nil
						end
					end
				else --一旦有空的格子，就肯定不是烹饪了
					names = nil
				end
			end
			if spice ~= nil and dish ~= nil then
				names = { dish.prefab, spice.prefab }
			end
			if names ~= nil then
				local product = cooking.CalculateRecipe(spice ~= nil and "portablespicer" or "portablecookpot", names)
				if product ~= nil then
					local skins
					if dish ~= nil then
						skins = GetFoodSkin(nil, dish, nil)
					else
						skins = GetFoodSkin(product, nil, self.opener.userid)
					end
					local recipe = cooking.GetRecipe(spice ~= nil and "portablespicer" or "portablecookpot", product)
					if recipe ~= nil then
						self:ShowOn(recipe, skins)
						return
					end
				end
			end
			self:ShowOff() --预测失败，清理贴图
		end)
	end
end

return MoonSimmered
