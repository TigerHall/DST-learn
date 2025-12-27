local INITIAL_AGE = 12

local function RemoveShawuAgeTags(inst)
    for i = 12, 17 do
        if inst:HasTag("shawu_year"..i) then
            inst:RemoveTag("shawu_year"..i)
        end
    end
end

local function OnExtraAgeChanged(self, extra_age)
    RemoveShawuAgeTags(self.inst)
    for i = 0, extra_age do
        self.inst:AddTag("shawu_year"..(INITIAL_AGE + i))
    end
end

local ShawuAge = Class(function(self, inst)
    self.inst = inst

    self.extra_age = 0

    inst:WatchWorldState("cycles", function()
        if inst.components.age:GetAgeInDays() == 350 and self.extra_age > 0 then
            inst.components.health:Kill()
        end
    end)
end, nil, {
    extra_age = OnExtraAgeChanged
})

function ShawuAge:GetAge()
    return self.inst.components.age:GetAgeInDays() + INITIAL_AGE + self.extra_age
end

function ShawuAge:AddAge(age)
    self.extra_age = self.extra_age + age
end

function ShawuAge:OnSave()
    return
    {
        extra_age = self.extra_age
	}
end

function ShawuAge:OnLoad(data)
	if data ~= nil then
		self.extra_age = data.extra_age
	end
end

return ShawuAge
