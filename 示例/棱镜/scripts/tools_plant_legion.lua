
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --为了不暴露局部变量，单独装一起

fns.ctlrange = 20 --水肥照料机的作用半径

pas.AddTag = function(inst, name)
	if not inst:HasTag(name) then
		inst:AddTag(name)
	end
end
pas.RemoveTag = function(inst, name)
	if inst:HasTag(name) then
		inst:RemoveTag(name)
	end
end

--[ 批量施肥计算，会尽量补满三种肥料并自动消耗 ]--

pas.ComputCost = function(valueneed, value)
    local need = valueneed / value
    value = math.ceil(need)
    if need ~= value then --说明不整除
        need = value
        if need > 1 then --最后一次很可能会比较浪费，所以不主动填满
            need = need - 1
        end
    end
    return need
end
fns.CostFertilizer = function(plant, fert, doer, n, mo, nuts, mois, sound)
    if n[1] <= 0 and n[2] <= 0 and n[3] <= 0 and mo <= 0 then
        return
    end
    local fertcpt = fert.components.fertilizer
    if nuts == nil then
        if fert.legion_nutrients ~= nil then --兼容别的数据
            nuts = fert.legion_nutrients
        elseif fertcpt ~= nil and fertcpt.nutrients ~= nil then
            nuts = fertcpt.nutrients
        elseif mois ~= nil and mois > 0 then --虽然没肥料但是有水分呀，所以后面的逻辑还是得进行
            nuts = {}
        else
            return
        end
    end
    local numfert = 1 --肥料的数量或次数
    if (fertcpt or mois) and fert.components.finiteuses ~= nil then --为了兼容没有fertilizer组件的有耐久道具
        numfert = fert.components.finiteuses:GetUses()
        if numfert <= 0 then --没有耐久就结束吧
            return
        end
    elseif fert.components.stackable ~= nil then
        numfert = fert.components.stackable:StackSize()
    end
    local costnum = 0
    if numfert <= 1 then --就只有一个肥料，那还算什么呢，直接得到结果
        if
            (n[1] > 0 and nuts[1] ~= nil and nuts[1] > 0) or (n[2] > 0 and nuts[2] ~= nil and nuts[2] > 0)
            or (n[3] > 0 and nuts[3] ~= nil and nuts[3] > 0) or (mo > 0 and mois ~= nil and mois > 0)
        then
            costnum = 1
        else --说明肥料和水分都对应不上，直接结束
            return
        end
    else
        local cost = 0
        if mo > 0 and mois ~= nil and mois > 0 then
            cost = pas.ComputCost(mo, mois)
        end
        if cost < numfert then
            for i = 1, 3, 1 do
                if n[i] > 0 and nuts[i] ~= nil and nuts[i] > 0 then
                    costnum = pas.ComputCost(n[i], nuts[i])
                    if costnum > cost then --寻找消耗最大的那一项的数量
                        if costnum >= numfert then --数量已经达到上限，就不用计算了
                            cost = numfert
                            break
                        else
                            cost = costnum
                        end
                    end
                end
            end
            costnum = cost
        else --数量已经达到上限，就不用计算了
            costnum = numfert
        end
    end
    if costnum <= 0 then
        return
    end
    if plant.components.burnable ~= nil then --快着火时能阻止着火
		plant.components.burnable:StopSmoldering()
	end

    --发出声音
    if sound ~= false then
        local sd = sound
        if sd == nil then
            sd = fertcpt and fertcpt.fertilize_sound or nil
            if sd == nil then
                if mois ~= nil then
                    sd = "farming/common/watering_can/use"
                else
                    sd = "dontstarve/common/fertilize"
                end
            end
        end
        if sd ~= nil then
            if plant.SoundEmitter ~= nil then
                plant.SoundEmitter:PlaySound(sd)
            elseif doer ~= nil and doer.SoundEmitter ~= nil then
                doer.SoundEmitter:PlaySound(sd)
            end
        end
    end

    --这一截是补全并优化 fert.components.fertilizer:OnApplied() 的内容
    if (fertcpt or mois) and fert.components.finiteuses ~= nil then --为了兼容没有fertilizer组件的有耐久道具
        --按理来说有耐久组件了，就不会再有叠加组件，所以这里不考虑叠加的情况
        --浇水壶也会进入这个逻辑里，但是不要被删除，不然空水壶就被删了
        --某些物品在finiteuses:Use()后，耐久为0时就会消失了。比如便便桶、多变的云
        fert.components.finiteuses:Use(costnum)
        if fertcpt ~= nil and fertcpt.onappliedfn ~= nil then
            --某些肥料耐久为0不会消失，在onappliedfn()里才会确定是否消失。比如超级催长剂
            fertcpt.onappliedfn(fert, fert.components.finiteuses:GetUses() <= 0, doer, plant)
        end
        --综上所述，不用再做删除操作了
    else
        if fertcpt ~= nil and fertcpt.onappliedfn ~= nil then
            --目前没有耐久组件的肥料都是没有fertcpt.onappliedfn的，这里只是补全一下逻辑，要是以后有了呢
            fertcpt.onappliedfn(fert, true, doer, plant)
        end
        if fert:IsValid() then --fert可能在onappliedfn()里已经被删了
            if fert.components.stackable ~= nil then
                fert.components.stackable:Get(costnum):Remove()
            else
                fert:Remove()
            end
        end
    end

    --总结
    local res = { costnum = costnum }
    if mo > 0 and mois ~= nil and mois > 0 then
        res.mo = mois*costnum
    end
    for i, k in ipairs({ "n1", "n2", "n3" }) do
        if n[i] > 0 and nuts[i] ~= nil and nuts[i] > 0 then
            res[k] = nuts[i]*costnum
        end
    end
    return res
end

--[ 寻找周围的水肥照料机，并记下来 ]--

fns.FindSivCtls = function(inst, cpt, needtype, timely, nofind)
    inst.legion_sivctlcpt = cpt
    inst.legiontag_sivctl_timely = timely --代表养分对它很重要，需要及时获取
    cpt.sivctltypes = needtype

    --加载时，不由这边执行，由水肥照料机自己寻找
    if not nofind then --未加载，延时查找水肥照料机，之所以要延时是因为此时还没有设置位置
        inst:DoTaskInTime(0.5+math.random()*1.5, function()
            local ctls = {}
            local hasctl = false
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, fns.ctlrange, { "siving_ctl" }, { "NOCLICK", "INLIMBO" }, nil)
            for _, v in ipairs(ents) do
                local ctlcpt = v.components.botanycontroller
                if ctlcpt ~= nil and (needtype == nil or needtype[ctlcpt.type]) then
                    ctls[v] = ctlcpt
                    hasctl = true
                end
            end
            if hasctl then
                cpt.sivctls = ctls
            else
                cpt.sivctls = nil
            end
            if cpt.OnSivCtlChange ~= nil then
                cpt:OnSivCtlChange()
            end
            if cpt.CostNutrition ~= nil then --从耕地或者照料机里汲取，具体逻辑自己设定
                cpt:CostNutrition(nil, true)
            end
        end)
    end
end

--[ 从所有水肥照料机或耕地索取养料 ]--

fns.CostNutrition = function(inst, sivctls, actlcpt, n, mo, tend, dosoil, soilmo) --消耗肥料与水分
    if n[1] <= 0 and n[2] <= 0 and n[3] <= 0 and mo <= 0 and tend then
		return
	end
    local ctls
    if actlcpt ~= nil then --actlcpt 参数代表只索取这一个照料机的
        ctls = { [actlcpt.inst] = actlcpt }
    elseif sivctls ~= nil then
        ctls = sivctls
    elseif dosoil then --没有照料机，但得补个空值
        ctls = {}
    else --既没有照料机，也不需要吸收耕地，那就结束吧
        return
    end
    --记下原本需要的值
    local nn = { n[1], n[2], n[3] }
    local nmo = mo
    local cg
    --先消耗照料机
    for ctl, ctlcpt in pairs(ctls) do
        if ctl:IsValid() then
            local change = {}
            if mo > 0 and ctlcpt.moisture > 0 then --水分就不判断型号了，判断了反而多判断几次了
                if mo <= ctlcpt.moisture then
                    ctlcpt.moisture = ctlcpt.moisture - mo
                    mo = 0
                else
                    mo = mo - ctlcpt.moisture
                    ctlcpt.moisture = 0
                end
                change[4] = true
            end
            if ctlcpt.type ~= 1 then
                if not tend and ctlcpt.type == 3 then --照顾是不需要消耗的
                    tend = true
                end
                for i = 1, 3, 1 do
                    if n[i] > 0 and ctlcpt.nutrients[i] > 0 then
                        if n[i] <= ctlcpt.nutrients[i] then
                            ctlcpt.nutrients[i] = ctlcpt.nutrients[i] - n[i]
                            n[i] = 0
                        else
                            n[i] = n[i] - ctlcpt.nutrients[i]
                            ctlcpt.nutrients[i] = 0
                        end
                        change[i] = true
                    end
                end
            end
            if change[1] or change[2] or change[3] or change[4] then
                cg = true
				ctlcpt:SetBars(change[4], change[1], change[2], change[3])
			end
			if n[1] <= 0 and n[2] <= 0 and n[3] <= 0 and mo <= 0 and tend then
				break
			end
        else --清理不需要的照料机
            ctls[ctl] = nil
        end
    end
    --再消耗耕地，如果需要的话
    if dosoil and (not cg or not (n[1] <= 0 and n[2] <= 0 and n[3] <= 0 and mo <= 0)) then
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
        if tile == GROUND.FARMING_SOIL then
            local farmmgr = TheWorld.components.farming_manager
            --水分
            if mo > 0 and farmmgr:IsSoilMoistAtPoint(x, 0, z) then
                if soilmo ~= nil and mo > soilmo then --因为耕地水分数据没法直接获取，所以最好是靠 soilmo 参数来限制只吸收少量
                    farmmgr:AddSoilMoistureAtPoint(x, 0, z, -soilmo)
                    mo = mo - soilmo
                else
                    farmmgr:AddSoilMoistureAtPoint(x, 0, z, -mo)
                    mo = 0
                end
                cg = true
            end
            --肥料
            if n[1] > 0 or n[2] > 0 or n[3] > 0 then
                local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
                local tn = { farmmgr:GetTileNutrients(tile_x, tile_z) }
                for i = 1, 3, 1 do
                    if n[i] > 0 and tn[i] ~= nil and tn[i] > 0 then
                        if n[i] <= tn[i] then
                            tn[i] = -n[i]
                            n[i] = 0
                        else
                            n[i] = n[i] - tn[i]
                            tn[i] = -tn[i]
                        end
                    else
                        tn[i] = 0
                    end
                end
                if tn[1] < 0 or tn[2] < 0 or tn[3] < 0 then
                    cg = true
                    farmmgr:AddTileNutrients(tile_x, tile_z, tn[1], tn[2], tn[3])
                end
            end
        end
    end
    --总结
    if cg then
        local res = {}
        for i, k in ipairs({ "n1", "n2", "n3" }) do
            if nn[i] > n[i] then
                res[k] = nn[i] - n[i]
            end
        end
        if nmo > mo then
            res.mo = nmo - mo
        end
        return res, tend
    else
        return nil, tend
    end
end
fns.CostNutritionAny = function(inst, sivctls, actlcpt, n, mo, tend, dosoil, soilmo) --消耗任意肥料
    if n <= 0 and mo <= 0 and tend then
		return
	end
    local ctls
    if actlcpt ~= nil then --actlcpt 参数代表只索取这一个照料机的
        ctls = { [actlcpt.inst] = actlcpt }
    elseif sivctls ~= nil then
        ctls = sivctls
    elseif dosoil then --没有照料机，但得补个空值
        ctls = {}
    else --既没有照料机，也不需要吸收耕地，那就结束吧
        return
    end
    --记下原本需要的值
    local nn = n
    local nmo = mo
    local cg
    --先消耗照料机
    for ctl, ctlcpt in pairs(ctls) do
        if ctl:IsValid() then
            local change = {}
            if mo > 0 and ctlcpt.moisture > 0 then --水分就不判断型号了，判断了反而多判断几次了
                if mo <= ctlcpt.moisture then
                    ctlcpt.moisture = ctlcpt.moisture - mo
                    mo = 0
                else
                    mo = mo - ctlcpt.moisture
                    ctlcpt.moisture = 0
                end
                change[4] = true
            end
            if ctlcpt.type ~= 1 then
                if not tend and ctlcpt.type == 3 then --照顾是不需要消耗的
                    tend = true
                end
                if n > 0 then
                    for i = 3, 1, -1 do --优先消耗3号肥
                        if ctlcpt.nutrients[i] > 0 then
                            change[i] = true
                            if n <= ctlcpt.nutrients[i] then
                                ctlcpt.nutrients[i] = ctlcpt.nutrients[i] - n
                                n = 0
                                break
                            else
                                n = n - ctlcpt.nutrients[i]
                                ctlcpt.nutrients[i] = 0
                            end
                        end
                    end
                end
            end
            if change[4] or change[3] or change[2] or change[1] then
                cg = true
				ctlcpt:SetBars(change[4], change[1], change[2], change[3])
			end
			if n <= 0 and mo <= 0 and tend then
				break
			end
        else --清理不需要的照料机
            ctls[ctl] = nil
        end
    end
    --再消耗耕地，如果需要的话
    if dosoil and (not cg or not (n <= 0 and mo <= 0)) then
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
        if tile == GROUND.FARMING_SOIL then
            local farmmgr = TheWorld.components.farming_manager
            --水分
            if mo > 0 and farmmgr:IsSoilMoistAtPoint(x, 0, z) then
                if soilmo ~= nil and mo > soilmo then --因为耕地水分数据没法直接获取，所以最好是靠 soilmo 参数来限制只吸收少量
                    farmmgr:AddSoilMoistureAtPoint(x, 0, z, -soilmo)
                    mo = mo - soilmo
                else
                    farmmgr:AddSoilMoistureAtPoint(x, 0, z, -mo)
                    mo = 0
                end
                cg = true
            end
            --肥料
            if n > 0 then
                local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
                local tn = { farmmgr:GetTileNutrients(tile_x, tile_z) }
                for i = 3, 1, -1 do --优先消耗3号肥
                    if n > 0 and tn[i] ~= nil and tn[i] > 0 then
                        if n <= tn[i] then
                            tn[i] = -n
                            n = 0
                        else
                            n = n - tn[i]
                            tn[i] = -tn[i]
                        end
                    else
                        tn[i] = 0
                    end
                end
                if tn[3] < 0 or tn[2] < 0 or tn[1] < 0 then
                    cg = true
                    farmmgr:AddTileNutrients(tile_x, tile_z, tn[1], tn[2], tn[3])
                end
            end
        end
    end
    --总结
    if cg then
        local res = {}
        if nn > n then
            res.n = nn - n
        end
        if nmo > mo then
            res.mo = nmo - mo
        end
        return res, tend
    else
        return nil, tend
    end
end
fns.CostMoisture = function(inst, sivctls, actlcpt, mo, dosoil, soilmo) --只消耗水分
    if mo <= 0 then
		return
	end
    local ctls
    if actlcpt ~= nil then --actlcpt 参数代表只索取这一个照料机的
        ctls = { [actlcpt.inst] = actlcpt }
    elseif sivctls ~= nil then
        ctls = sivctls
    elseif dosoil then --没有照料机，但得补个空值
        ctls = {}
    else --既没有照料机，也不需要吸收耕地，那就结束吧
        return
    end
    --记下原本需要的值
    local nmo = mo
    --先消耗照料机
    for ctl, ctlcpt in pairs(ctls) do
        if ctl:IsValid() then
            if ctlcpt.moisture > 0 then --水分就不判断型号了，判断了反而多判断几次了
                if mo <= ctlcpt.moisture then
                    ctlcpt.moisture = ctlcpt.moisture - mo
                    mo = 0
                else
                    mo = mo - ctlcpt.moisture
                    ctlcpt.moisture = 0
                end
				ctlcpt:SetBars(true)
                if mo <= 0 then
                    break
                end
            end
        else --清理不需要的照料机
            ctls[ctl] = nil
        end
    end
    --再消耗耕地，如果需要的话
    if dosoil and mo > 0 then
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
        if tile == GROUND.FARMING_SOIL then
            local farmmgr = TheWorld.components.farming_manager
            --水分
            if farmmgr:IsSoilMoistAtPoint(x, 0, z) then
                if soilmo ~= nil and mo > soilmo then --因为耕地水分数据没法直接获取，所以最好是靠 soilmo 参数来限制只吸收少量
                    farmmgr:AddSoilMoistureAtPoint(x, 0, z, -soilmo)
                    mo = mo - soilmo
                else
                    farmmgr:AddSoilMoistureAtPoint(x, 0, z, -mo)
                    mo = 0
                end
            end
        end
    end
    --总结
    if nmo > mo then
        return nmo - mo
    end
end

--[ 一些通用函数 ]--

fns.LongUpdate = function(self, dt)
    if self.time_start ~= nil then --没有暂停生长
		local timenow = GetTime()
		if timenow > self.time_start then --间隔时间也要算上来
            local dtt = timenow - self.time_start
            if dtt >= dt then --从洞穴上地面，地面对象可能就是触发这个情况。别把时间算多了
                dt = dtt
            else --这种应该是单纯的跳时间，比如用t键模组跳时间。需要把已经过去的时间给补上
                dt = dt + dtt
            end
		end
		self.time_start = timenow --更新标记时间
		self:TimePassed(dt, self.inst:IsAsleep()) --植株休眠时，只增加 time_grow
	end
end
fns.TriggerMoistureOn = function(inst, OnMoiWater, OnIsRaining)
    if inst.components.moisture == nil then
        inst:AddComponent("moisture") --浇水机制由潮湿度组件控制（能让水壶、水球、神话的玉净瓶等起作用）
    end
    local function EmptyCptFn(self, ...)end
    local cpt = inst.components.moisture
    cpt.OnUpdate = EmptyCptFn --取消下雨时的潮湿度增加
    cpt.LongUpdate = EmptyCptFn
    cpt.ForceDry = EmptyCptFn
    cpt.OnSave = EmptyCptFn
    cpt.OnLoad = EmptyCptFn
    cpt.DoDelta = OnMoiWater or EmptyCptFn
    inst:StopUpdatingComponent(cpt) --该组件会周期刷新，不需要其逻辑，所以得停止该机制
    if OnIsRaining ~= nil then
        inst.legionfn_moi_rain = OnIsRaining
        inst:WatchWorldState("israining", OnIsRaining) --下雨时补充水分
    end
end
fns.TriggerMoistureOff = function(inst)
    if inst.components.moisture ~= nil then
        inst:RemoveComponent("moisture")
    end
    if inst.legionfn_moi_rain ~= nil then
        inst:StopWatchingWorldState("israining", inst.legionfn_moi_rain)
    end
end
fns.SetMoisture = function(self, value, notag) --设置水分
    if value > 0 then
        if self.moisture < self.moisture_max then
            self.moisture = math.min(self.moisture_max, self.moisture+value)
            if not notag then
                self:SetTagMoisture()
            end
        end
    elseif value < 0 then
        if self.moisture > 0 then
            self.moisture = self.moisture + value --可以为负数
            if not notag then
                self:SetTagMoisture()
            end
        end
    end
end
fns.SetTagMoisture = function(self)
    if self.moisture >= self.moisture_max then
		pas.RemoveTag(self.inst, "moisable_l")
	else
		pas.AddTag(self.inst, "moisable_l")
	end
end
fns.SpawnFxTend = function(inst, tended) --照料时的特效
    if inst:IsAsleep() then
        if inst.legiontask_tendfx ~= nil then
            inst.legiontag_tended = tended
        end
        return
    end
    inst.legiontag_tended = tended
    if inst.legiontask_tendfx == nil then
        inst.legiontask_tendfx = inst:DoTaskInTime(0.5 + math.random()*0.5, function()
            local fx = SpawnPrefab(inst.legiontag_tended and "farm_plant_happy" or "farm_plant_unhappy")
            if fx ~= nil then
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst.legiontag_tended = nil
            inst.legiontask_tendfx = nil
        end)
    end
end
fns.SpawnFxNut = function(inst, rightnow) --施肥时的特效
    if inst:IsAsleep() then
        return
    end
    if rightnow then
        local fx = SpawnPrefab("life_trans_fx")
        if fx ~= nil then
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        return
    end
    if inst.legiontask_nutfx == nil then
        inst.legiontask_nutfx = inst:DoTaskInTime(0.2 + math.random()*0.4, function()
            local fx = SpawnPrefab("life_trans_fx")
            if fx ~= nil then
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst.legiontask_nutfx = nil
        end)
    end
end
fns.SpawnFxMoi = function(inst, rightnow) --浇水时的特效
    if inst:IsAsleep() then
        return
    end
    if rightnow then
        local fx = SpawnPrefab("sivctl_moi_fx")
        if fx ~= nil then
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        return
    end
    if inst.legiontask_moifx == nil then
        inst.legiontask_moifx = inst:DoTaskInTime(0.2 + math.random()*0.4, function()
            local fx = SpawnPrefab("sivctl_moi_fx")
            if fx ~= nil then
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst.legiontask_moifx = nil
        end)
    end
end
fns.SetNutrient1 = function(self, value, notag) --设置1号肥
    if value > 0 then
        if self.nutrient1 < self.nutrient_max then
            self.nutrient1 = math.min(self.nutrient_max, self.nutrient1+value)
            if not notag then
                self:SetTagNutrient1()
            end
        end
    elseif value < 0 then
        if self.nutrient1 > 0 then
            self.nutrient1 = self.nutrient1 + value --可以为负数
            if not notag then
                self:SetTagNutrient1()
            end
        end
    end
end
fns.SetTagNutrient1 = function(self)
    if self.nutrient1 >= self.nutrient_max then
		pas.RemoveTag(self.inst, "fertable1_l")
	else
		pas.AddTag(self.inst, "fertable1_l")
	end
end
fns.SetNutrient2 = function(self, value, notag) --设置2号肥
    if value > 0 then
        if self.nutrient2 < self.nutrient_max then
            self.nutrient2 = math.min(self.nutrient_max, self.nutrient2+value)
            if not notag then
                self:SetTagNutrient2()
            end
        end
    elseif value < 0 then
        if self.nutrient2 > 0 then
            self.nutrient2 = self.nutrient2 + value --可以为负数
            if not notag then
                self:SetTagNutrient2()
            end
        end
    end
end
fns.SetTagNutrient2 = function(self)
    if self.nutrient2 >= self.nutrient_max then
		pas.RemoveTag(self.inst, "fertable2_l")
	else
		pas.AddTag(self.inst, "fertable2_l")
	end
end
fns.SetNutrient3 = function(self, value, notag) --设置3号肥
    if value > 0 then
        if self.nutrient3 < self.nutrient_max then
            self.nutrient3 = math.min(self.nutrient_max, self.nutrient3+value)
            if not notag then
                self:SetTagNutrient3()
            end
        end
    elseif value < 0 then
        if self.nutrient3 > 0 then
            self.nutrient3 = self.nutrient3 + value --可以为负数
            if not notag then
                self:SetTagNutrient3()
            end
        end
    end
end
fns.SetTagNutrient3 = function(self)
    if self.nutrient3 >= self.nutrient_max then
		pas.RemoveTag(self.inst, "fertable3_l")
	else
		pas.AddTag(self.inst, "fertable3_l")
	end
end
fns.TriggerGrowableOn = function(inst, DoMagicGrowth)
    if inst.components.growable == nil then
        inst:AddComponent("growable") --没办法，为了能让园林书、农耕书能起作用，只能加这个组件。因为官方的逻辑太不通用了
    end
    local function EmptyCptFn(self, ...)end
    local cpt = inst.components.growable
    cpt.stages = {}
    cpt:StopGrowing()
    cpt.magicgrowable = true --必须要加的标识
    cpt.domagicgrowthfn = DoMagicGrowth
    cpt.GetCurrentStageData = function(self) return { tendable = false } end --要写吗？
    cpt.StartGrowingTask = EmptyCptFn
    cpt.StartGrowing = EmptyCptFn
    cpt.DoGrowth = EmptyCptFn
    cpt.SetStage = EmptyCptFn
    cpt.LongUpdate = EmptyCptFn
    cpt.OnSave = EmptyCptFn
    cpt.OnLoad = EmptyCptFn
    cpt.Resume = EmptyCptFn
    cpt.Pause = EmptyCptFn
    cpt.OnEntitySleep = EmptyCptFn
    cpt.OnEntityWake = EmptyCptFn
end
fns.TriggerPickableOn = function(inst, OnPicked, picksound)
    if inst.components.pickable == nil then
        inst:AddComponent("pickable")
    end
    inst.components.pickable.onpickedfn = OnPicked
    inst.components.pickable:SetUp(nil)
    -- inst.components.pickable.use_lootdropper_for_product = true --有自己的独特收获物机制，不需要沿用官方的逻辑
    inst.components.pickable.picksound = picksound
end

-- local TOOLS_P = require("tools_plant_legion")
return fns
