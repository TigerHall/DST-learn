local TOOLS_P_L = require("tools_plant_legion")
local BotanyController = Class(function(self, inst)
    self.inst = inst

    self.type = 1 --1水、2土、3水土
    self.moisture = 0
    self.nutrients = { 0, 0, 0 }

    -- self.onbarchange = nil
    -- self.cgn1 = nil
    -- self.cgn2 = nil
    -- self.cgn3 = nil
    -- self.cgmo = nil

    self.moisture_max = 2000
    self.nutrient_max = 800
end)

local function IsEmptyNutrients(self)
    return self.nutrients[1] <= 0 and self.nutrients[2] <= 0 and self.nutrients[3] <= 0
end

function BotanyController:SetBars(mo, n1, n2, n3, nodelay)
    self.cg = true --做个标记，bar要变化说明养分值也发生了变化
    if self.onbarchange ~= nil then
        if nodelay then
            if self.task_bar ~= nil then
                self.task_bar:Cancel()
                self.task_bar = nil
            end
            self.onbarchange(self, mo or self.cgmo, n1 or self.cgn1, n2 or self.cgn2, n3 or self.cgn3)
            self.cgn1 = nil
            self.cgn2 = nil
            self.cgn3 = nil
            self.cgmo = nil
        else
            if mo then self.cgmo = true end --由于是延迟生效的，需要记下改动的部分
            if n1 then self.cgn1 = true end
            if n2 then self.cgn2 = true end
            if n3 then self.cgn3 = true end
            if self.task_bar == nil then --延迟生效，好处就是不用每次触发都会去修改一遍，减少没必要的逻辑循环
                self.task_bar = self.inst:DoTaskInTime(0.25, function()
                    self.task_bar = nil
                    if self.onbarchange ~= nil then
                        self.onbarchange(self, self.cgmo, self.cgn1, self.cgn2, self.cgn3)
                        self.cgn1 = nil
                        self.cgn2 = nil
                        self.cgn3 = nil
                        self.cgmo = nil
                    end
                end)
            end
        end
    end
end
function BotanyController:SetValue(moi, nuts, nobar, nosupply)
    local cg = {}
    local needdofn = nosupply
    if moi ~= nil and moi ~= 0 and self.type ~= 2 then
        if moi > 0 then
            if self.moisture < self.moisture_max then
                local zero = self.moisture <= 0
                self.moisture = math.min(self.moisture_max, self.moisture + moi)
                cg[4] = true
                if zero and self.moisture > 0 then
                    needdofn = true
                end
            end
        else
            if self.moisture > 0 then
                self.moisture = self.moisture + moi --可以为负数
                cg[4] = true
            end
        end
    end
    if nuts ~= nil and self.type ~= 1 then
        for i = 1, 3, 1 do
            if nuts[i] ~= nil and nuts[i] ~= 0 then
                if nuts[i] > 0 then
                    if needdofn then --判定好了就不用再判定了
                        if self.nutrients[i] < self.nutrient_max then
                            self.nutrients[i] = math.min(self.nutrient_max, self.nutrients[i] + nuts[i])
                            cg[i] = true
                        end
                    else
                        if self.nutrients[i] < self.nutrient_max then
                            local zero = self.nutrients[i] <= 0
                            self.nutrients[i] = math.min(self.nutrient_max, self.nutrients[i] + nuts[i])
                            cg[i] = true
                            if zero and self.nutrients[i] > 0 then
                                needdofn = true
                            end
                        end
                    end
                else
                    if self.nutrients[i] > 0 then
                        self.nutrients[i] = self.nutrients[i] + nuts[i]
                        cg[i] = true
                    end
                end
            end
        end
    end
    if not nosupply and needdofn then --说明有数值从小于等于0增加到了大于0，那就范围通知那些需要的植物，及时吸收一下养分
        if self.task_timely ~= nil then
            self.task_timely:Cancel()
        end
        self.task_timely = self.inst:DoTaskInTime(0.25, function()
            self.task_timely = nil
            self:TimelySupply()
        end)
    end
    if not nobar and (cg[4] or cg[1] or cg[2] or cg[3]) then
        self:SetBars(cg[4], cg[1], cg[2], cg[3], nil)
    end
end

function BotanyController:FindSivCtlables(gameinit)
    local isempty = IsEmptyNutrients(self) and self.moisture <= 0
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TOOLS_P_L.ctlrange, nil, { "NOCLICK", "INLIMBO" }, nil)
	for _, v in ipairs(ents) do
        if v.legion_sivctlcpt ~= nil then
            local cpt = v.legion_sivctlcpt
            if cpt.sivctltypes == nil or cpt.sivctltypes[self.type] then
                if cpt.sivctls == nil then
                    cpt.sivctls = {}
                end
                cpt.sivctls[self.inst] = self
                if cpt.OnSivCtlChange ~= nil then
                    cpt:OnSivCtlChange(self, nil, gameinit)
                end
                if not isempty and not gameinit and cpt.CostNutrition ~= nil then
                    cpt:CostNutrition(self, false) --参数1代表v只向ctlcpt汲取养料
                    if self.cg then --养分值发生了变化
                        self.cg = nil
                        if IsEmptyNutrients(self) and self.moisture <= 0 then
                            isempty = true --还有别的植物要注册照料机，所以这里不能直接结束
                        end
                    end
                end
            end
        end
	end
end
function BotanyController:ClearSivCtlables()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TOOLS_P_L.ctlrange, nil, { "NOCLICK", "INLIMBO" }, nil)
	for _, v in ipairs(ents) do
        if v.legion_sivctlcpt ~= nil then
            local cpt = v.legion_sivctlcpt
            if cpt.sivctls ~= nil then
                cpt.sivctls[self.inst] = nil
                local hasit
                for j, jj in pairs(cpt.sivctls) do
                    if j:IsValid() then --说明还有别的照料机
                        hasit = true
                        break
                    else
                        cpt.sivctls[j] = nil
                    end
                end
                if not hasit then --彻底清理这个表
                    cpt.sivctls = nil
                end
                if cpt.OnSivCtlChange ~= nil then
                    cpt:OnSivCtlChange(nil, self)
                end
            end
        end
    end
end
function BotanyController:TimelySupply()
    if IsEmptyNutrients(self) and self.moisture <= 0 then
        return
    end
    self.cg = nil
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TOOLS_P_L.ctlrange, nil, { "NOCLICK", "INLIMBO" }, nil)
	for _, v in ipairs(ents) do
        if v.legiontag_sivctl_timely and v.legion_sivctlcpt ~= nil then --只针对需要及时汲取的植物
            local cpt = v.legion_sivctlcpt
            if cpt.sivctltypes == nil or cpt.sivctltypes[self.type] then
                if cpt.CostNutrition ~= nil then
                    cpt:CostNutrition(self, true) --参数1代表v只向ctlcpt汲取养料
                    if self.cg then --养分值发生了变化
                        self.cg = nil
                        if IsEmptyNutrients(self) and self.moisture <= 0 then --没养分了，直接结束
                            return
                        end
                    end
                end
            end
        end
	end
    self:SoilSupply() --先给植物供给完成了再尝试给耕地供养
end
function BotanyController:SoilSupply() --为耕地提供养分
    if IsEmptyNutrients(self) and self.moisture <= 0 then
        return
    end
    local cg = {}
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local newx, newz
    for k1 = -20, 20, 4 do
        newx = x+k1
        for k2 = -20, 20, 4 do
            newz = z+k2
            local tile = TheWorld.Map:GetTileAtPoint(newx, 0, newz)
            if tile == GROUND.FARMING_SOIL then
                local farmmgr = TheWorld.components.farming_manager
                if self.moisture > 0 then --由于没法知道耕地里的具体水分，只能直接加水了
                    farmmgr:AddSoilMoistureAtPoint(newx, 0, newz, 100) --根据地里的水分做优化！没水会扣除更多！
                    self.moisture = self.moisture - 2.5
                    cg[4] = true
                end
                if not IsEmptyNutrients(self) then
                    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(newx, 0, newz)
                    local tn = { farmmgr:GetTileNutrients(tile_x, tile_z) }
                    for i = 1, 3, 1 do
                        --缺肥超过50%才加肥，也许能减少搭配种植时肥料的消耗
                        if self.nutrients[i] > 0 and tn[i] ~= nil and tn[i] <= 50 then
                            local need = 100 - tn[i]
                            if self.nutrients[i] > need then
                                tn[i] = need
                                self.nutrients[i] = self.nutrients[i] - need
                            else
                                tn[i] = self.nutrients[i]
                                self.nutrients[i] = 0
                            end
                            cg[i] = true
                        else
                            tn[i] = 0
                        end
                    end
                    if tn[1] > 0 or tn[2] > 0 or tn[3] > 0 then
                        farmmgr:AddTileNutrients(tile_x, tile_z, tn[1], tn[2], tn[3])
                    end
                end
                if IsEmptyNutrients(self) and self.moisture <= 0 then
                    if cg[4] or cg[3] or cg[2] or cg[1] then
                        self:SetBars(cg[4], cg[1], cg[2], cg[3])
                    end
                    return
                end
            end
        end
    end
    if cg[4] or cg[3] or cg[2] or cg[1] then
        self:SetBars(cg[4], cg[1], cg[2], cg[3])
    end
end
function BotanyController:PeriodicSupply(doit, gameinit) --周期函数，仅给耕地施肥，因为耕地机制没法修改
    if self.task_supply ~= nil then
        self.task_supply:Cancel()
        self.task_supply = nil
    end
    if not doit then
        return
    end
    local time = 290 + math.random()*20 --5分钟！
    self.task_supply = self.inst:DoPeriodicTask(time, function()
        if self.type ~= 2 and (TheWorld.state.israining or TheWorld.state.issnowing) then --下雨时补充水分
            self:SetValue(800, nil)
        end
        self:SoilSupply()
    end, gameinit and time/2 or math.random()*3) --加载时不需要那么快就给耕地施肥
end

function BotanyController:OnSave()
    local data = {}
    if self.type ~= 2 then
        if self.moisture ~= 0 then
            data.mo = self.moisture
        end
    end
    if self.type ~= 1 then
        if self.nutrients[1] ~= 0 then
            data.n1 = self.nutrients[1]
        end
        if self.nutrients[2] ~= 0 then
            data.n2 = self.nutrients[2]
        end
        if self.nutrients[3] ~= 0 then
            data.n3 = self.nutrients[3]
        end
    end
    return data
end
function BotanyController:OnLoad(data)
    if data == nil then
        return
    end
    if data.mo ~= nil and self.type ~= 2 then
        self.moisture = math.min(data.mo, self.moisture_max)
    end
    if self.type ~= 1 then
        if data.n1 ~= nil then
            self.nutrients[1] = math.min(data.n1, self.nutrient_max)
        end
        if data.n2 ~= nil then
            self.nutrients[2] = math.min(data.n2, self.nutrient_max)
        end
        if data.n3 ~= nil then
            self.nutrients[3] = math.min(data.n3, self.nutrient_max)
        end
    end
    --加载时不主动更新bar，因为实体自己会延时更新的
end

return BotanyController
