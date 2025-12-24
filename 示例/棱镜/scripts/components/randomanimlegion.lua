local RandomAnimLegion = Class(function(self, inst)
    self.inst = inst
    -- self.type1 = nil
    -- self.type2 = nil
    -- self.multcolour = nil
    -- self.str = nil
    -- self.loop = nil
end)

function RandomAnimLegion:SetAnim(type1, type2) --设置随机动画
    local res = self.str or "idle"
    if type1 ~= nil then
        self.type1 = math.random(type1)
    end
    if type2 ~= nil then
        self.type2 = math.random(type2)
    end
    if self.type1 ~= nil then
        res = res..tostring(self.type1).."_"..tostring(self.type2 or 1)
    else
        res = res..tostring(self.type2 or 1)
    end
    self.inst.AnimState:PlayAnimation(res, self.loop)
end

function RandomAnimLegion:SetMultColour(mult) --设置随机变色
    if mult == nil then
        mult = 0.5
    end
    if 0 <= mult and mult < 1 then
        self.multcolour = mult + math.random()*(1.0-mult)
        mult = self.multcolour
        self.inst.AnimState:SetMultColour(mult, mult, mult, 1)
    end
end

function RandomAnimLegion:OnSave()
    local data = {
        type1 = self.type1,
        type2 = self.type2,
        multcolour = self.multcolour
    }
    return data
end
function RandomAnimLegion:OnLoad(data, newents)
    if data ~= nil then
        if data.type1 ~= nil then self.type1 = data.type1 end
        if data.type2 ~= nil then self.type2 = data.type2 end
        self:SetAnim(nil, nil)
        if data.multcolour ~= nil then
            self.multcolour = data.multcolour
            self.inst.AnimState:SetMultColour(self.multcolour, self.multcolour, self.multcolour, 1)
        end
    end
end

return RandomAnimLegion
