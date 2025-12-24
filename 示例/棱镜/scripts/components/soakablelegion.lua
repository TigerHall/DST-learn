local ZIP_L = require("zip_soak_legion")
local TOOLS_L = require("tools_legion") -- test

local SoakableLegion = Class(function(self, inst)
    self.inst = inst
    self.points = 1 --可以浸泡的位置数量
    self.soakers = {} --当前浸泡着的玩家
    self.radius = { 1, 1 } --浸泡半径。[1]最近距离，[2]可增加距离
    -- self.radiuscenter = 0.5 --浸泡半径的可增加距离。如果有这个数据代表可以在中心位置进行浸泡

    -- self.fn_value = function(pondcpt)end --设置泉池的初始数值的函数
    self.fn_tick = ZIP_L.fn_tick --function(pondcpt, soakercpt, costs)end --泉池的浸泡周期额外逻辑的函数
    -- self.fn_mixtickspst = function(pondcpt)end

    self.tick = 2 --效果触发周期
    self.tick_health = 2
    self.tick_sanity = 1
    self.tick_temperature = { 2, 10, 60 }
    self.tick_moisture = 2.5
    self.tick_formula = 0 --催长剂。能让植物人开花。320点催长剂能使其开花维持5天(=5*8*60/(30/4))
    self.tick_buffs = {}
    self.tick_spicefns = {}
    self.bonus_goodbuff = 0 --对好buff的时间系数的额外数值
    self.bonus_badbuff = 0 --对坏buff的时间系数的额外数值
    self.buffcaches = {}
    self.ticks_spice = {} --保存泉池与添料的属性总和数据

    self.fish_health = 0
    self.fish_sanity = 0
    self.fish_temperature = { 0, 0, 0 }
    self.fish_moisture = 0
    self.fish_formula = 0
    self.ticks_fish = { nums = {} }

    self.datainfos = {} --鼠标信息展示用的

    self.bldgs = {} --泉池建筑
    self.bldgcounts = {}
    -- self.bldg_soak = nil --单独存储，方便索引
    self.spices = {} --单独存储添料，方便管理
    self.spicecosts = {} --每种添料的已消耗次数，永久保存
    self.costmaxmult = 2 --消耗总次数的系数。便于调整平衡性
end)

local function GetCalculatedPos(x, y, z, radius, theta)
    local rad = radius or math.random() * 3
    local the = theta or math.random() * 2 * PI
    return x + rad * math.cos(the), y, z - rad * math.sin(the)
end
local function TriggerTag(inst, has, tagname)
    if has then
        inst:AddTag(tagname)
    else
        inst:RemoveTag(tagname)
    end
end

function SoakableLegion:WetSoaker(doer, value) --增加潮湿度。不用官方的加潮湿度逻辑，因为需要削弱防水机制
    local moisture = doer.components.moisture
    if moisture ~= nil then
        local waterproofness = moisture:GetWaterproofness()
        if waterproofness > 0 then --玩家自身的防水效果最多只能抵抗20%
            value = value * (1 - waterproofness*0.2)
        end
        moisture:DoDelta(value, true) --浸泡时不说关于潮湿度变化的话
    end
end
function SoakableLegion:OccupySpace(doer, idx) --占位置
    local x, y, z = self.inst.Transform:GetWorldPosition()
    self.soakers[idx] = doer
    if idx >= self.points and self.radiuscenter ~= nil then --最后一个位置就是中心位置
        x, y, z = GetCalculatedPos(x, y, z, self.radiuscenter*math.random(), nil)
    else
        local num, v
        if self.radiuscenter ~= nil then
            num = self.points - 1
        else
            num = self.points
        end
        if num >= 2 then
            v = 2*PI/num --分成等份
            v = v*(idx-1+math.random())
        end
        x, y, z = GetCalculatedPos(x, y, z, self.radius[1] + self.radius[2]*math.random(), v)
    end
    return Point(x, y, z)
end
function SoakableLegion:LeaveSpace(idx, doer) --离开位置
    ------清理自己的数据
    local soaker
    if idx ~= nil then
        soaker = self.soakers[idx]
        if soaker ~= nil and soaker == doer then
            self.soakers[idx] = nil
        end
    end
    ------检查是否还有人在浸泡
    local hasit
    for i = 1, self.points, 1 do
        soaker = self.soakers[i]
        if soaker ~= nil and soaker:IsValid() then
            hasit = true
            break
        end
    end
    if not hasit then --没人了就结束浸泡
        if self.task_soak ~= nil then
            self.task_soak:Cancel()
            self.task_soak = nil
        end
        self.soakers = {}
        self:TriggerBldgBoxes(true) --浸泡结束，可以打开了
    end
    ------把buff时间和催长剂补充给玩家，得兑现之前已有的消耗
    local cpt = doer.components.soakerlegion
    if not doer:HasTag("playerghost") and doer.components.health ~= nil and not doer.components.health:IsDead() then
        if cpt ~= nil and cpt.times.count ~= nil and cpt.times.count > 0 then --至少得浸泡过才行
            self:ForceSoakPst(doer, cpt)
        end
    else --如果死亡，就得把骨架和掉落物都挪出泉池范围，不然所有物品都会卡在泉池里
        self:MoveOut(nil, cpt and cpt.startpos or nil)
    end
end
function SoakableLegion:StartSoak(doer) --开始浸泡效果
    if self.task_soak == nil then
        self.task_soak = self.inst:DoPeriodicTask(self.tick, function()
            self:DoSoak()
        end, self.tick)
    end
    self:TriggerBldgBoxes(false)
    self:WetSoaker(doer, 25) --刚开始浸泡时，会直接增加潮湿度，算是副作用吧

    --[[
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local x2, y2, z2, val, name, cpt, animtype
    local num = 0
    local ents = TheSim:FindEntities(x, y, z, 10, nil, { "INLIMBO", "NOCLICK" })
    for _, v in ipairs(ents) do
        if v ~= self.inst and not v.checked_l and (v.prefab == "fern_l" or v.prefab == "pebble_l_nitre") then
            v.checked_l = true
            num = num + 1
            x2, y2, z2 = v.Transform:GetWorldPosition()
            name = v.prefab
            cpt = v.components.randomanimlegion
            animtype = nil
            if name == "pebble_l_nitre" and cpt ~= nil then
                if cpt.type1 == 4 then
                    name = "rock_l_nitre"
                else
                    animtype = cpt.type1
                end
            end
            val = " { prefab = \""..tostring(name).."\", x = "
                ..tostring(TOOLS_L.ODPoint(x2-x, 1000000))..", z = "..tostring(TOOLS_L.ODPoint(z2-z, 1000000))
            if animtype ~= nil then
                val = val..", animtype = "..tostring(animtype).." },"
            else
                val = val.." },"
            end
            print(val)
            if num >= 8 then
                return
            end
        end
    end
    ]]--
end
function SoakableLegion:DoSoak() --浸泡效果
    local soakers = {}
    ------录入当前的浸泡者
    for i = 1, self.points, 1 do
        local soaker = self.soakers[i]
        if soaker ~= nil then
            if soaker:IsValid() and not soaker:HasTag("playerghost") and
                soaker.components.health ~= nil and not soaker.components.health:IsDead() and
                soaker.components.soakerlegion ~= nil
            then
                table.insert(soakers, soaker)
            else
                self.soakers[i] = nil
            end
        end
    end
    ------没人了就结束浸泡
    if soakers[1] == nil then
        if self.task_soak ~= nil then
            self.task_soak:Cancel()
            self.task_soak = nil
        end
        return
    end
    ------开始应用浸泡效果
    local cpt, value, va
    local costs = {} --用于统计添料总的消耗情况
    for idx, soaker in ipairs(soakers) do
        local soakercpt = soaker.components.soakerlegion
        ------生命值
        if self.tick_health ~= 0 then
            cpt = soaker.components.health
            if soakercpt.mult_health ~= nil then
                va = self.tick_health * soakercpt.mult_health
            else
                va = self.tick_health
            end
            if va > 0 then
                if cpt:IsHurt() then
                    cpt:DoDelta(va, true, "debug_key", true) --旺达需要特定的key才能回血
                    costs.health = (costs.health or 0) + self.tick --每 self.tick 秒触发的，而回复是按秒算的
                end
            elseif va < 0 then --能进行到这里，肯定是没死亡的
                cpt:DoDelta(va, true, self.inst.prefab, true)
                costs.health = (costs.health or 0) + self.tick
                if cpt:IsDead() then
                    soaker = nil
                    soakers[idx] = nil
                end
            end
        end
        if soaker ~= nil then
            ------潮湿度
            if self.tick_moisture ~= 0 then
                cpt = soaker.components.moisture
                if cpt ~= nil then
                    if soakercpt.mult_moisture ~= nil then
                        va = self.tick_moisture * soakercpt.mult_moisture
                    else
                        va = self.tick_moisture
                    end
                    if va > 0 then
                        if (cpt:GetMoisture()+va) <= cpt:GetMaxMoisture() then
                            local waterproofness = cpt:GetWaterproofness()
                            if waterproofness > 0 then --玩家自身的防水效果最多只能抵抗20%
                                va = va * (1 - waterproofness*0.2)
                            end
                            cpt:DoDelta(va, true) --浸泡时不说关于潮湿度变化的话
                            costs.moisture = (costs.moisture or 0) + self.tick
                        end
                    elseif va < 0 then
                        if (cpt:GetMoisture()+va) >= 0 then
                            cpt:DoDelta(va, true)
                            costs.moisture = (costs.moisture or 0) + self.tick
                        end
                    end
                end
            end
            ------精神值
            if self.tick_sanity ~= 0 then
                cpt = soaker.components.sanity
                if cpt ~= nil then
                    if soakercpt.mult_sanity ~= nil then
                        va = self.tick_sanity * soakercpt.mult_sanity
                    else
                        va = self.tick_sanity
                    end
                    if va > 0 then
                        if (cpt.current+va) <= cpt:GetMaxWithPenalty() then
                            cpt:DoDelta(va, true)
                            costs.sanity = (costs.sanity or 0) + self.tick
                        end
                    elseif va < 0 then
                        if (cpt.current+va) >= 0 then
                            cpt:DoDelta(va, true)
                            costs.sanity = (costs.sanity or 0) + self.tick
                        end
                    end
                end
            end
            ------温度
            if self.tick_temperature[1] ~= 0 then
                cpt = soaker.components.temperature
                if cpt ~= nil then
                    value = cpt:GetCurrent() + self.tick_temperature[1]
                    if self.tick_temperature[1] > 0 then --升温
                        if value <= self.tick_temperature[3] then
                            cpt:SetTemperature(value)
                            costs.temperature = (costs.temperature or 0) + self.tick
                        end
                    else --降温
                        if value >= self.tick_temperature[2] then
                            cpt:SetTemperature(value)
                            costs.temperature = (costs.temperature or 0) + self.tick
                        end
                    end
                end
            end
            ------催长剂
            if self.tick_formula > 0 and soaker.OnFertilizedWithFormula ~= nil then
                value = (soakercpt.times["formula"] or 0) + self.tick
                if value >= 10 then --10秒一次主动施肥，太频繁了没必要
                    soaker:OnFertilizedWithFormula(self.tick_formula * value)
                    value = 0
                end
                soakercpt.times["formula"] = value
                costs.formula = (costs.formula or 0) + self.tick
            end
            ------加buff时间到！
            va = soakercpt.cg_buffs
            for buffkey, buffdd in pairs(self.tick_buffs) do
                value = soakercpt.times[buffkey]
                if buffdd.can or value ~= nil or soaker:HasDebuff(buffkey) then
                    if buffdd.time == nil then --说明该buff被抑制了
                        if value == nil then --被抑制后就不再计时，但也不清除之前已有的
                            soakercpt.times[buffkey] = 0
                        end
                    else
                        value = (value or 0) + self.tick
                        if value >= (buffdd.cycle + (va[buffkey] and va[buffkey]*self.tick or 0)) then
                            if not buffdd.isbad or soaker:HasDebuff(buffkey) then
                                value = buffdd.time*value + value --额外 +value，是为了补上浸泡时玩家禁止不动而损失的时间
                            else
                                value = buffdd.time*value
                            end
                            soaker:AddDebuff(buffkey, buffkey, { value = value, bath = true })
                            value = 0
                        end
                        soakercpt.times[buffkey] = value
                    end
                    costs[buffkey] = (costs[buffkey] or 0) + self.tick
                end
            end
            ------添料的特殊效果
            for item, fn in pairs(self.tick_spicefns) do
                if item:IsValid() then
                    fn(self, soakercpt, costs, item)
                else
                    self.tick_spicefns[item] = nil
                end
            end
            ------额外逻辑
            if self.fn_tick ~= nil then
                self.fn_tick(self, soakercpt, costs)
            end
        end
    end
    ------该消耗添料了
    for name, dd in pairs(self.spices) do
        if dd.item:IsValid() then
            va = self.spicecosts[name] or 0
            if dd.costs ~= nil then
                for costkey, costval in pairs(dd.costs) do
                    if costs[costkey] ~= nil then
                        va = va + costs[costkey] * costval
                    end
                end
            end
            if dd.fn_cost ~= nil then
                dd.fn_cost(self, dd, va, costs)
            elseif dd.costmax ~= nil then --偷懒了，每次只删除一个吧，反正几秒就要判定一次
                if va >= dd.costmax then
                    cpt = dd.item.components.stackable
                    if cpt == nil or cpt:StackSize() <= 1 then
                        dd.item:Remove()
                        self.spices[name] = nil
                        self.needupdatetick = true
                    else
                        cpt:SetStackSize(cpt:StackSize() - 1)
                    end
                    va = va - dd.costmax
                end
                self.spicecosts[name] = va --记录余下的，留着下次用
            else --说明不会被消耗，那就不用记录数据了。清理掉！不然会成僵尸数据
                self.spicecosts[name] = nil
            end
        else
            self.spices[name] = nil
            self.needupdatetick = true
        end
    end
    ------确定是否需要更新数据
    local needupdate = self.needupdatetick
    if needupdate then --有材料消耗完了，重新更新浸泡数据
        --需要把buff时间和催长剂补充给玩家。因为即将更新浸泡数据，buff数据可能会有所改变，之前的消耗就得先兑现了
        for _, soaker in pairs(soakers) do
            if soaker:IsValid() and not soaker:HasTag("playerghost") and
                soaker.components.health ~= nil and not soaker.components.health:IsDead()
            then
                self:ForceSoakPst(soaker, soaker.components.soakerlegion)
            end
        end
        self:UpdateTick(true)
    end
    if self.needupdatefishtick then
        self:UpdateFishTick()
    elseif needupdate then
        self:MixAllTicks()
    end
end
function SoakableLegion:ForceSoakPst(soaker, cpt)
    local value
    for buffkey, buffdd in pairs(self.tick_buffs) do
        if buffdd.time ~= nil then
            value = cpt.times[buffkey] --有这个时间数据就代表能被增加buff
            if value ~= nil and value >= self.tick then
                if soaker:HasDebuff(buffkey) then --额外 + value，是为了补上浸泡时玩家禁止不动而损失的时间
                    soaker:AddDebuff(buffkey, buffkey, { value = buffdd.time*value + value, bath = true })
                    cpt.times[buffkey] = 0
                elseif not buffdd.noforce then
                    soaker:AddDebuff(buffkey, buffkey, { value = buffdd.time*value, bath = true })
                    cpt.times[buffkey] = 0
                end
            end
        end
    end
    if self.tick_formula > 0 then
        value = cpt.times["formula"]
        if value ~= nil and value >= self.tick and soaker.OnFertilizedWithFormula ~= nil then
            soaker:OnFertilizedWithFormula(self.tick_formula * value) --该数值与开花时间不是1比1的，所以不能补充损失时间
            cpt.times["formula"] = 0
        end
    end
end

function SoakableLegion:TriggerBldgBoxes(canopen) --设置所有建筑的容器是否能打开，顺便检查建筑有效性
    local key
    for ent, _ in pairs(self.bldgs) do
        if ent:IsValid() then
            if canopen ~= nil and ent.components.container ~= nil then
                if canopen then
                    ent.components.container.canbeopened = true
                else
                    ent.components.container:Close()
                    ent.components.container.canbeopened = false
                end
            end
        else
            key = ent.prefab
            local num = self.bldgcounts[key]
            self.bldgs[ent] = nil
            if num ~= nil then
                if num >= 2 then
                    self.bldgcounts[key] = num - 1
                else
                    self.bldgcounts[key] = nil
                end
            end
        end
    end
    if key ~= nil then
        self:UpdateBldgTags()
    end
end
function SoakableLegion:OnCloseBldg(bldg) --泉池建筑的容器关闭时，检查是否需要更新泡澡数据
    if bldg.prefab == "pondbldg_soak" then
        if self.needupdatetick then
            self:UpdateTick()
            return
        end
        local spices = {}
        local num = 0
        local item
        ----先检查已有添料是否还在容器内
        for name, spicedd in pairs(self.spices) do
            item = spicedd.item
            if item:IsValid() then
                if item.components.inventoryitem ~= nil and item.components.inventoryitem.owner == bldg then
                    spices[item] = true
                    num = num + 1
                else
                    self.needupdatetick = true
                    break
                end
            else
                self.needupdatetick = true
                break
            end
        end
        ----再检查容器内物品与已有添料是否一致
        if not self.needupdatetick then
            local box = bldg.components.container
            if box ~= nil then
                local names = {}
                for i = 1, 6 do --不管别的模组把容器改得多大，这里还是只识别前6格的物品
                    item = box.slots[i]
                    if item ~= nil then
                        if spices[item] then
                            num = num - 1
                            names[item.prefab] = true
                        elseif not names[item.prefab] then --因为一种添料只算一次，所以还得判断名字。新名字意味着有新物品
                            self.needupdatetick = true
                            break
                        end
                    end
                end
                if num > 0 then --说明有添料被挪走了
                    self.needupdatetick = true
                end
            else
                self.needupdatetick = true
            end
        end
        ----确定是否更新
        if self.needupdatetick then
            self:UpdateTick()
        end
    elseif bldg.prefab == "pondbldg_fish" then
        if self.needupdatefishtick then
            self:UpdateFishTick()
            return
        end
        if not self.checkfishtick then
            return
        end
        self.checkfishtick = nil
        local fish = {}
        local allnum = 0
        ------先统计当前容器里物品数量
        if bldg.components.container ~= nil then
           for _, v in pairs(bldg.components.container.slots) do
                if v:IsValid() then
                    fish[v.prefab] = (fish[v.prefab] or 0) + 1
                end
            end
            for fishkey, num in pairs(fish) do
                if ZIP_L.fish[fishkey] == nil then --在这里把无效数据清理掉
                    fish[fishkey] = nil
                else
                    allnum = allnum + num
                end
            end
        end
        ------再比对数量
        local dd = self.ticks_fish[bldg]
        if dd == nil then
            self.needupdatefishtick = true
        else
            for fishkey, num in pairs(dd) do
                if fish[fishkey] == nil or fish[fishkey] ~= num then --鱼的数量对应不上，需要刷新
                    self.needupdatefishtick = true
                    break
                else
                    allnum = allnum - num
                end
            end
            if allnum > 0 then --说明目前多了鱼类，需要更新
                self.needupdatefishtick = true
            end
        end
        ----确定是否更新
        if self.needupdatefishtick then
            self:UpdateFishTick()
        end
    end
end
function SoakableLegion:UpdateBldgTags() --更新可摆放建筑标签
    local dd = self.bldgcounts["pondbldg_soak"] or 0
    TriggerTag(self.inst, dd <= 0, "pondbldg_soak")
    dd = self.bldgcounts["pondbldg_fish"] or 0
    TriggerTag(self.inst, dd < (self.inst.legiontag_bigpond and 3 or 1), "pondbldg_fish")
end
function SoakableLegion:BindBldg(bldg, x, z, isoffset) --绑定泉池建筑
    local key = bldg.prefab
    local dd = self.bldgcounts[key] or 0
    local res
    if key == "pondbldg_soak" then --澡花壳：只能放一个
        if dd <= 0 then
            self.bldg_soak = bldg
            dd = 1
            res = true
        end
    elseif key == "pondbldg_fish" then --鱼栖壳：大池塘3个、小池塘1个
        if dd < (self.inst.legiontag_bigpond and 3 or 1) then
            dd = dd + 1
            self.ticks_fish[bldg] = {} --刚注册时不会有鱼，但为了避免重复刷新数据
            res = true
        end
    end
    if res then
        local x2, y2, z2 = self.inst.Transform:GetWorldPosition()
        self.bldgs[bldg] = isoffset and { x = x, z = z } or { x = x - x2, z = z - z2 } --记录位置的偏移量
        self.bldgcounts[key] = dd
        bldg.persists = false --现在保存与加载由泉池接管，建筑本身不再主动触发
        bldg.pondcpt_l = self --建立关系
        if self.task_soak ~= nil and bldg.components.container ~= nil then --浸泡期间不可以被打开
            bldg.components.container.canbeopened = false
        end
        return true
    end
end
function SoakableLegion:UnboundBldg(bldg) --解绑泉池建筑。一般也就被破坏时解绑，所以不需要恢复什么
    if self.bldgs[bldg] ~= nil then
        local key = bldg.prefab
        local dd = self.bldgcounts[key]
        if dd ~= nil then
            if dd >= 2 then
                dd = dd - 1
            else
                dd = nil
            end
            self.bldgcounts[key] = dd
        end
        self.bldgs[bldg] = nil
        self:UpdateBldgTags()
        if key == "pondbldg_soak" then --澡花壳：清理添料数据
            self.bldg_soak = nil
            self:UpdateTick(nil, true)
        elseif key == "pondbldg_fish" then --鱼栖壳：应该把掉落物都挪到泉池边上，不然会卡在池塘里
            self:UpdateFishTick(nil, true)
            self:MoveOut(0.5, nil)
        end
    end
end

function SoakableLegion:UpdateTick(nomix, delay) --更新浸泡的各项恢复数值
    if delay or self.task_tick ~= nil then
        if not nomix then
            self._mix = true
        end
        if self.task_tick == nil then
            self.task_tick = self.inst:DoTaskInTime(0.2, function()
                self.task_tick = nil
                self:UpdateTick(not self._mix)
                self._mix = nil
            end)
        end
        return
    end
    ------泉池的初始数值
    local newbuffs = {}
    local dd, selfv
    self.spices = {}
    self.tick_spicefns = {}
    self.ticks_spice = {}
    self.buffcaches = {}
    self.bonus_goodbuff = 0
    self.bonus_badbuff = 0
    if self.fn_value ~= nil then
        self.fn_value(self)
    else
        ZIP_L.fn_value_hot(self)
    end
    ------添料对数值的改动
    if self.bldg_soak ~= nil then
        local box = self.bldg_soak.components.container
        if not self.bldg_soak:IsValid() or box == nil then
            self.bldgs[self.bldg_soak] = nil
            self.bldgcounts["pondbldg_soak"] = nil
            self.bldg_soak = nil
            self:UpdateBldgTags()
        else
            local item
            for i = 1, 6 do --不管别的模组把容器改得多大，这里还是只识别前6格的物品
                item = box.slots[i]
                if item ~= nil and item:IsValid() and
                    self.spices[item.prefab] == nil and --一种添料只算一次
                    ZIP_L.spices[item.prefab] ~= nil --数据校验
                then
                    dd = ZIP_L.spices[item.prefab]
                    selfv = { item=item, costs=dd.costs, fn_cost=dd.fn_cost }
                    if dd.costmax ~= nil then
                        if self.costmaxmult ~= 1 then --方便我调整数据
                            selfv.costmax = dd.costmax * self.costmaxmult
                        else
                            selfv.costmax = dd.costmax
                        end
                    end
                    self.spices[item.prefab] = selfv
                    ----基础数值改动
                    if dd.values ~= nil then
                        for tikey, tiv in pairs(dd.values) do
                            selfv = self["tick_"..tikey]
                            if selfv ~= nil then
                                if tikey == "temperature" then --温度比较特殊
                                    selfv[1] = selfv[1] + tiv[1]
                                    selfv[2] = selfv[2] + tiv[2]
                                    selfv[3] = selfv[3] + tiv[2]
                                else
                                    self["tick_"..tikey] = selfv + tiv --为了便于管理与计算，各项变化都是加法运算
                                end
                            end
                        end
                    end
                    ----buff改动
                    if dd.buffs ~= nil then
                        for buffkey, buffdd in pairs(dd.buffs) do
                            selfv = newbuffs[buffkey]
                            if selfv == nil then
                                selfv = {}
                                newbuffs[buffkey] = selfv
                            end
                            if buffdd[1] ~= nil then
                                selfv[1] = (selfv[1] or 0) + buffdd[1]
                            end
                            if buffdd[2] then
                                selfv[2] = true
                            end
                            if buffdd[3] ~= nil then
                                selfv[3] = (selfv[3] or 0) + buffdd[3]
                            end
                        end
                    end
                    ----自定义改动
                    if dd.fn_value ~= nil then
                        dd.fn_value(self, dd, item.prefab, newbuffs)
                    end
                    if dd.fn_tick ~= nil then
                       self.tick_spicefns[item] = dd.fn_tick
                    end
                end
            end
        end
    end
    ------数据的后置处理
    if self.spices["hermit_cracked_pearl"] ~= nil then --珍珠的珍珠(碎)的总体提升
        self.bonus_goodbuff = self.bonus_goodbuff + ZIP_L.values[2]
    end
    ------数据已加载完成，完善buff数据（这截逻辑写在外面，因为以后可能会有别的修改属性机制，不只是添料）
    for buffkey, buffdd in pairs(newbuffs) do
        selfv = self.tick_buffs[buffkey]
        if selfv == nil then --说明这不是泉池本身带有的buff
            selfv = ZIP_L.GetBuffTick(buffkey)
            self.tick_buffs[buffkey] = selfv
        end
        if selfv ~= nil then
            if buffdd[2] then --说明可以主动提供该buff
                selfv.can = true
            end
            if selfv.time ~= nil and buffdd[1] ~= nil then
                if selfv.isbad then
                    if self.bonus_badbuff ~= 0 then
                        buffdd[1] = buffdd[1] + self.bonus_badbuff
                    end
                else
                    if self.bonus_goodbuff ~= 0 then
                        buffdd[1] = buffdd[1] + self.bonus_goodbuff
                    end
                end
                if buffdd[1] > 0 then --大于0时，代表对时间的增加，数值需要乘以10
                    selfv.time = selfv.time * (1 + buffdd[1] * 10)
                elseif buffdd[1] <= -0.9 then --小于等于-0.9时，说明不会积累时间了，直接设为空值
                    selfv.time = nil
                elseif buffdd[1] < 0 then --小于0时，代表对时间的削减
                    selfv.time = selfv.time * (1 + buffdd[1])
                end
            end
            if buffdd[3] ~= nil then
                selfv.cycle = selfv.cycle + buffdd[3]
            end
        end
    end
    ------保存泉池与添料的数据
    self.buffcaches.buff_l_warm = self.tick_buffs.buff_l_warm
    self.buffcaches.buff_l_cool = self.tick_buffs.buff_l_cool
    self.ticks_spice.tick_health = self.tick_health
    self.ticks_spice.tick_sanity = self.tick_sanity
    self.ticks_spice.tick_temperature = { self.tick_temperature[1], self.tick_temperature[2], self.tick_temperature[3] }
    self.ticks_spice.tick_moisture = self.tick_moisture
    self.ticks_spice.tick_formula = self.tick_formula
    self.needupdatetick = nil
    if not nomix then
        self:MixAllTicks()
    end
end
function SoakableLegion:UpdateFishTick(nomix, delay) --更新鱼的各项恢复数据
    if delay or self.task_fishtick ~= nil then
        if not nomix then
            self._fishmix = true
        end
        if self.task_fishtick == nil then
            self.task_fishtick = self.inst:DoTaskInTime(0.2, function()
                self.task_fishtick = nil
                self:UpdateFishTick(not self._fishmix)
                self._fishmix = nil
            end)
        end
        return
    end
    ------初始化数据
    self.fish_health = 0
    self.fish_sanity = 0
    self.fish_temperature = { 0, 0, 0 }
    self.fish_moisture = 0
    self.fish_formula = 0
    self.ticks_fish = { nums = {} }
    ------先统计所有的鱼
    local tag, dd, val
    for ent, _ in pairs(self.bldgs) do
        if ent:IsValid() then
            if ent.prefab == "pondbldg_fish" and ent.components.container ~= nil then
                dd = self.ticks_fish[ent]
                if dd == nil then
                    dd = {}
                    self.ticks_fish[ent] = dd
                end
                --先统计容器里的数量
                for _, v in pairs(ent.components.container.slots) do
                    if v:IsValid() then
                       dd[v.prefab] = (dd[v.prefab] or 0) + 1
                    end
                end
                --再把数量加到总和里去
                val = self.ticks_fish.nums
                for fishkey, num in pairs(dd) do
                    if ZIP_L.fish[fishkey] == nil then --在这里把无效数据清理掉
                        dd[fishkey] = nil
                    else
                        val[fishkey] = (val[fishkey] or 0) + num
                    end
                end
            end
        else
            tag = true
        end
    end
    ------计算鱼的总数值
    for fishkey, num in pairs(self.ticks_fish.nums) do
        dd = ZIP_L.fish[fishkey]
        if dd ~= nil and dd.values ~= nil then
            for tikey, tiv in pairs(dd.values) do
                val = self["fish_"..tikey]
                if val ~= nil then
                    if tikey == "temperature" then --温度比较特殊
                        val[1] = val[1] + tiv[1]*num
                        val[2] = val[2] + tiv[2]*num
                        val[3] = val[3] + tiv[2]*num
                    else
                        self["fish_"..tikey] = val + tiv*num --为了便于管理与计算，各项变化都是加法运算
                    end
                end
            end
        end
    end
    ------有无效建筑，更新建筑数据
    if tag then
        self:TriggerBldgBoxes()
    end
    self.needupdatefishtick = nil
    if not nomix then
        self:MixAllTicks()
    end
end
function SoakableLegion:MixAllTicks() --混合泉池、添料、鱼的数据，并做最后处理
    ------初始化数据
    -- self.tick_health = 0 --貌似不需要
    -- self.tick_sanity = 0
    -- self.tick_temperature[1] = 0
    -- self.tick_temperature[2] = 0
    -- self.tick_temperature[3] = 0
    -- self.tick_moisture = 0
    -- self.tick_formula = 0
    self.datainfos = {}
    ------合并泉池、添料与鱼的数据
    self.tick_health = (self.ticks_spice.tick_health or 0) + self.fish_health
    self.tick_sanity = (self.ticks_spice.tick_sanity or 0) + self.fish_sanity
    if self.ticks_spice.tick_temperature ~= nil then
        self.tick_temperature[1] = self.ticks_spice.tick_temperature[1] + self.fish_temperature[1]
        self.tick_temperature[2] = self.ticks_spice.tick_temperature[2] + self.fish_temperature[2]
        self.tick_temperature[3] = self.ticks_spice.tick_temperature[3] + self.fish_temperature[3]
    else
        self.tick_temperature[1] = self.fish_temperature[1]
        self.tick_temperature[2] = self.fish_temperature[2]
        self.tick_temperature[3] = self.fish_temperature[3]
    end
    self.tick_moisture = (self.ticks_spice.tick_moisture or 0) + self.fish_moisture
    self.tick_formula = (self.ticks_spice.tick_formula or 0) + self.fish_formula
    ------加入时间系数，并记录信息展示所需数据
    if self.tick_health ~= 0 then
        self.datainfos.tick_health = self.tick_health
        self.tick_health = self.tick_health * self.tick
    end
    if self.tick_sanity ~= 0 then
        self.datainfos.tick_sanity = self.tick_sanity
        self.tick_sanity = self.tick_sanity * self.tick
    end
    self.datainfos.tick_temperature = { self.tick_temperature[1], self.tick_temperature[2], self.tick_temperature[3] }
    if self.tick_temperature[1] ~= 0 then
        self.tick_temperature[1] = self.tick_temperature[1] * self.tick
    end
    if self.tick_moisture ~= 0 then
        self.datainfos.tick_moisture = self.tick_moisture
        self.tick_moisture = self.tick_moisture * self.tick
    end
    if self.tick_formula ~= 0 then
        self.datainfos.tick_formula = self.tick_formula
        self.tick_formula = self.tick_formula * self.tick
    end
    ------后置处理
    if self.spices["purpleamulet"] ~= nil or self.spices["purplegem"] ~= nil then --紫宝石及其护符的特殊作用
        local dd = self.spices["purpleamulet"] ~= nil and 20 or 15
        if self.tick_temperature[1] > 0 then
            self.tick_temperature[2] = math.min(64.9, self.tick_temperature[2] + dd)
            self.tick_temperature[3] = math.min(64.9, self.tick_temperature[3] + dd)
        elseif self.tick_temperature[1] < 0 then
            self.tick_temperature[2] = math.max(5.1, self.tick_temperature[2] - dd)
            self.tick_temperature[3] = math.max(5.1, self.tick_temperature[3] - dd)
        end
    end
    ------温度对温暖buff和凉爽buff的影响
    if self.tick_temperature[1] > 0 then --能升温时，温暖buff加强，凉爽buff减弱
        if self.tick_buffs.buff_l_warm == nil then
            self.tick_buffs.buff_l_warm = self.buffcaches.buff_l_warm or ZIP_L.GetBuffTick("buff_l_warm", true)
        end
        self.tick_buffs.buff_l_warm.can = true
        self.tick_buffs.buff_l_cool = nil
    elseif self.tick_temperature[1] < 0 then --能降温时，凉爽buff加强，温暖buff减弱
        if self.tick_buffs.buff_l_cool == nil then
            self.tick_buffs.buff_l_cool = self.buffcaches.buff_l_cool or ZIP_L.GetBuffTick("buff_l_cool", true)
        end
        self.tick_buffs.buff_l_cool.can = true
        self.tick_buffs.buff_l_warm = nil
    else --无温度影响时，两个buff都减弱
        self.tick_buffs.buff_l_warm = nil
        self.tick_buffs.buff_l_cool = nil
    end
    ------外部处理
    if self.fn_mixtickspst ~= nil then
        self.fn_mixtickspst(self)
    end
end
function SoakableLegion:MoveOut(timedelay, startpos) --把泉池范围里的不合理对象都挪到外面去
    local x, y, z
    local pos = self.inst:GetPosition()
    if startpos ~= nil and --不能在海上或船上
        TheWorld.Map:IsPassableAtPoint(startpos.x, startpos.y, startpos.z, false, true)
    then
        x = startpos.x
        y = startpos.y
        z = startpos.z
        self.moveoutpos = { x = x, y = y, z = z }
    elseif self.moveoutpos ~= nil then --历史记录
        x = self.moveoutpos.x
        y = self.moveoutpos.y
        z = self.moveoutpos.z
    else --否则就随机位置
        x, y, z = GetCalculatedPos(pos.x, pos.y, pos.z, self.inst._dd_rad.base, nil)
        if not TheWorld.Map:IsPassableAtPoint(x, y, z, false, true) then --再给一次机会！
            x, y, z = GetCalculatedPos(pos.x, pos.y, pos.z, self.inst._dd_rad.base, nil)
        end
        self.moveoutpos = { x = x, y = y, z = z }
    end
    if self.task_moveout ~= nil then
        self.task_moveout:Cancel()
    end
    self.task_moveout = self.inst:DoTaskInTime(timedelay or 2.5, function() --延迟一下，得等玩家产生骨架
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, self.inst._dd_rad.clear,
            nil, { "NOCLICK", "FX", "INLIMBO" }, { "skeleton", "_inventoryitem" })
        for _, v in ipairs(ents) do
            if v.entity:IsVisible() and
                (v.components.inventoryitem == nil or v.components.inventoryitem.canbepickedup)
            then
                v.Transform:SetPosition(x, y, z)
            end
        end
        self.moveoutpos = nil
        self.task_moveout = nil
    end)
end

function SoakableLegion:OnSave()
    local data = { bldgs = {}, spicecosts = {} }
    local dd
    for ent, v in pairs(self.bldgs) do
        if ent:IsValid() then
            dd = { saved = ent:GetSaveRecord(), x = v.x, z = v.z }
            table.insert(data.bldgs, dd)
        end
    end
    for name, v in pairs(self.spicecosts) do
        data.spicecosts[name] = v
    end
    return data
end
function SoakableLegion:OnLoad(data, newents)
    if data == nil then return end
    if data.bldgs ~= nil then
        local ent
        local x, y, z = self.inst.Transform:GetWorldPosition()
        for _, v in pairs(data.bldgs) do
            if v.saved ~= nil then
                ent = SpawnPrefab(v.saved.prefab, v.saved.skinname, v.saved.skin_id)
                if ent ~= nil then
                    if v.pos ~= nil then --兼容旧版数据
                        v.x = v.pos.x
                        v.z = v.pos.z
                    end
                    ent.Transform:SetPosition(x + v.x, 0, z + v.z) --应用位置偏移量
                    ent:SetPersistData(v.saved.data)
                    self:BindBldg(ent, v.x, v.z, true)
                end
            end
        end
        -- self:UpdateBldgTags() --实体里会刷新的
    end
    if data.spicecosts ~= nil then
        for name, v in pairs(data.spicecosts) do
            self.spicecosts[name] = v
        end
    end
end
function SoakableLegion:BeRemoved()
    ------移除所有建筑
    for ent, _ in pairs(self.bldgs) do
        if ent:IsValid() then
            ent:Remove()
        end
    end
    self.bldgs = {}
    self.bldgcounts = {}
    ------移除所有装饰
end

return SoakableLegion
