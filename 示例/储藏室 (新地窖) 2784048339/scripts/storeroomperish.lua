local function storeroomperish(inst, dt)
	local self = inst.components.perishable
    if self ~= nil then
		dt = self.start_dt or dt or (10 + math.random()*FRAMES*8)
		self.start_dt = nil

        local additional_decay = 0
		local modifier = 1
		local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
        if not owner and inst.components.occupier then
            owner = inst.components.occupier:GetOwner()
        end

        local pos = owner ~= nil and owner:GetPosition() or self.inst:GetPosition()

		if owner then
			if owner.components.preserver ~= nil then
				modifier = owner.components.preserver:GetPerishRateMultiplier(inst) or modifier
			elseif owner:HasTag("fridge") then
				if inst:HasTag("frozen") and not owner:HasTag("nocool") and not owner:HasTag("lowcool") then
					modifier = TUNING.PERISH_COLD_FROZEN_MULT
				else
					modifier = TUNING.PERISH_FRIDGE_MULT
				end
            elseif owner:HasTag("foodpreserver") then
                modifier = TUNING.PERISH_FOOD_PRESERVER_MULT
			elseif owner:HasTag("cage") and inst:HasTag("small_livestock") then
                modifier = TUNING.PERISH_CAGE_MULT
            end

			if owner:HasTag("spoiler") then
				modifier = modifier * TUNING.PERISH_GROUND_MULT
			end
		else
			modifier = TUNING.PERISH_GROUND_MULT
		end

		if inst:GetIsWet() and not self.ignorewentness then
			modifier = modifier * TUNING.PERISH_WET_MULT
		end

		if GetTemperatureAtXZ(pos.x, pos.z) < 0 then
			if inst:HasTag("frozen") and not self.frozenfiremult then
				modifier = TUNING.PERISH_COLD_FROZEN_MULT
			else
				modifier = modifier * TUNING.PERISH_WINTER_MULT
			end
		end

		if self.frozenfiremult then
			modifier = modifier * TUNING.PERISH_FROZEN_FIRE_MULT
		end

		if GetTemperatureAtXZ(pos.x, pos.z) > TUNING.OVERHEAT_TEMP then
			modifier = modifier * TUNING.PERISH_SUMMER_MULT
		end

        modifier = modifier * self.localPerishMultiplyer

		modifier = modifier * TUNING.PERISH_GLOBAL_MULT

		local old_val = self.perishremainingtime
		if self.perishremainingtime then
			self.perishremainingtime = self.perishremainingtime - dt * modifier
	        if math.floor(old_val*100) ~= math.floor(self.perishremainingtime*100) then
		        inst:PushEvent("perishchange", {percent = self:GetPercent()})
		    end
		end

        if inst.components.edible ~= nil and inst.components.edible.temperaturedelta ~= nil and inst.components.edible.temperaturedelta > 0 and not (owner ~= nil and owner:HasTag("nocool")) then
            if owner ~= nil and owner:HasTag("fridge") then
                inst.components.edible:AddChill(1)
            elseif GetTemperatureAtXZ(pos.x, pos.z) < TUNING.OVERHEAT_TEMP - 5 then
                inst.components.edible:AddChill(.25)
            end
        end

        if self.perishremainingtime and self.perishremainingtime <= 0 then
			self:Perish()
        end
    end
end

AddComponentPostInit("perishable", function(self)
	self.StartPerishing = function(self)
		if self.updatetask ~= nil then
			self.updatetask:Cancel()
			self.updatetask = nil
		end
		
		local dt = 10 + math.random()*FRAMES*8
		self.start_dt = math.random()*2
		self.updatetask = self.inst:DoPeriodicTask(dt, storeroomperish, self.start_dt, dt)
	end
	-- self.LongUpdate = function(self, dt)
		-- if self.updatetask ~= nil then
			-- NewUpdate(self.inst, dt or 0)
		-- end
	-- end
end)
