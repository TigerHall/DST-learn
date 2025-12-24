ALL_TRAVELABLES = {}

local function onskintraveller(self, skintraveller)
    self.inst.replica.skintravelable:SetSkinTraveller(skintraveller)
end

local default_dist_cost = 50
local max_hunger_cost = 75
local min_hunger_cost = 5
local sanity_cost_ratio = 0.1

local ownershiptag = "uid_private"

local SkinTravelable = Class(function(self, inst)
    self.inst = inst
    self.inst:AddTag("skintravelable")

    self.skintraveller = nil
    self.destinations = {}
    self.skintravellers = {}

    self.onclosepopups = function(skintraveller) -- yay closures ~gj -- yay ~v2c
        if skintraveller == self.skintraveller then self:EndSkinTravel() end
    end

    self.generatorfn = nil
    table.insert(ALL_TRAVELABLES, self)
end, nil, { skintraveller = onskintraveller })

local function IsNearDanger(skintraveller)
    local hounded = TheWorld.components.hounded
    if hounded ~= nil and (hounded:GetWarning() or hounded:GetAttacking()) then
        return true
    end
    local burnable = skintraveller.components.burnable
    if burnable ~= nil and (burnable:IsBurning() or burnable:IsSmoldering()) then
        return true
    end
    return FindEntity(skintraveller, 10, function(target)
            return target.components.combat ~= nil and
                target.components.combat.target == skintraveller
        end,
        { "_combat", "_health" },
        { "INLIMBO", "player" },
        nil
    ) ~= nil
end

local function DistToCost(dist)
    local cost_hunger = min_hunger_cost + dist / default_dist_cost
    cost_hunger = math.min(cost_hunger, max_hunger_cost)
    local cost_sanity = cost_hunger * sanity_cost_ratio
    if TheWorld.state.season == "winter" then
        cost_sanity = cost_sanity * 1.25
    elseif TheWorld.state.season == "summer" then
        cost_sanity = cost_sanity * 0.75
    end

    cost_hunger = math.ceil(cost_hunger * TRAVEL_HUNGER_COST)
    cost_sanity = math.ceil(cost_sanity * TRAVEL_SANITY_COST)
    return cost_hunger, cost_sanity
end

function SkinTravelable:ListDestination(skintraveller)
    self.destinations = {}

    for i, v in ipairs(ALL_TRAVELABLES) do
        if not (v.ownership and v.inst:HasTag(ownershiptag) and
                skintraveller.userid ~= nil and
                not v.inst:HasTag("uid_" .. skintraveller.userid)) then
            table.insert(self.destinations, v.inst)
        end
    end

    table.sort(self.destinations, function(destA, destB)
        local writeA = destA.components.writeable
        local writeB = destB.components.writeable
        if writeA == nil or writeA:GetText() == nil or writeA:GetText() == "" then
            return false
        end
        if writeB == nil or writeB:GetText() == nil or writeB:GetText() == "" then
            return true
        end
        return string.lower(writeA:GetText()) < string.lower(writeB:GetText())
    end)

    self.totalsites = #self.destinations
    self.site = self.totalsites
end

function SkinTravelable:MakeInfos()
    local infos = ""
    for i, destination in ipairs(self.destinations) do
        local name = destination.components.writeable and
            destination.components.writeable:GetText() or "~nil"
        local cost_hunger, cost_sanity = 0, 0
        if destination == self.inst then
            cost_hunger = -1
            cost_sanity = -1
        else
            local xi, yi, zi = self.inst.Transform:GetWorldPosition()
            local xf, yf, zf = destination.Transform:GetWorldPosition()
            -- entity may be removed
            if xi ~= nil and zi ~= nil and xf ~= nil and zf ~= nil then
                local dist = math.sqrt((xi - xf) ^ 2 + (zi - zf) ^ 2)
                cost_hunger, cost_sanity = DistToCost(dist)
            end
        end

        infos = infos .. (infos == "" and "" or "\n") .. i .. "\t" .. name ..
            "\t" .. cost_hunger .. "\t" .. cost_sanity
    end
    self.inst.replica.skintravelable:SetDestInfos(infos)
end

function SkinTravelable:BeginSkinTravel(skintraveller)
    local comment = self.inst.components.talker
    if not skintraveller then
        if comment then comment:Say(STRINGS.NANA_TELEPORT_WHO_TOUCHED_ME) end
        return
    end
    local talk = skintraveller.components.talker

    if self.ownership and self.inst:HasTag(ownershiptag) and skintraveller.userid ~=
        nil and not self.inst:HasTag("uid_" .. skintraveller.userid) then
        if comment then
            comment:Say(STRINGS.NANA_TELEPORT_UNDER_OWNERSHIP)
        elseif talk then
            talk:Say(STRINGS.NANA_TELEPORT_TEMPORARILY_WITHOUT_AUTHORITY)
        end
        return
    elseif self.skintraveller then
        if comment then
            comment:Say(STRINGS.NANA_TELEPORT_NOT_YOUR_TURN_YET)
        elseif talk then
            talk:Say(STRINGS.NANA_TELEPORT_NOT_MY_TURN_YET)
        end
        return
    elseif IsNearDanger(skintraveller) then
        if talk then
            talk:Say(STRINGS.NANA_TELEPORT_NOT_SAFE_NEARBY)
        elseif comment then
            comment:Say(STRINGS.NANA_TELEPORT_NOT_SAFE_NEARBY)
        end
        return
    end

    local isintask = false
    for k, v in pairs(self.skintravellers) do
        if v == skintraveller then isintask = true end
    end

    if not self.skintraveltask or isintask then
        self.inst:StartUpdatingComponent(self)

        self:ListDestination(skintraveller)
        self:MakeInfos()
        self:CancelSkinTravel(skintraveller)
        self.skintravellers = {}

        self.skintraveller = skintraveller
        self.inst:ListenForEvent("ms_closepopups", self.onclosepopups, skintraveller)
        self.inst:ListenForEvent("onremove", self.onclosepopups, skintraveller)

        if skintraveller.HUD ~= nil then
            self.screen = skintraveller.HUD:ShowSkinTravelScreen(self.inst)
        end
    else
        self:CancelSkinTravel(skintraveller)
        self:SkinTravel(skintraveller, self.site)
    end
end

function SkinTravelable:SkinTravel(skintraveller, index)
    local destination = self.destinations[index]

    if skintraveller and destination then
        self.site = index
        local comment = self.inst.components.talker
        local talk = skintraveller.components.talker

        -- Site information
        local desc = destination.components.writeable and
            destination.components.writeable:GetText()
        local description = desc and string.format('"%s"', desc) or
            STRINGS.NANA_TELEPORT_UNKNOWN
        local information = ""
        local cost_hunger = min_hunger_cost
        local cost_sanity = 0
        local xi, yi, zi = self.inst.Transform:GetWorldPosition()
        local xf, yf, zf = destination.Transform:GetWorldPosition()
        -- entity may be removed
        if xi ~= nil and zi ~= nil and xf ~= nil and zf ~= nil then
            local dist = math.sqrt((xi - xf) ^ 2 + (zi - zf) ^ 2)
            cost_hunger, cost_sanity = DistToCost(dist)
        end

        if destination.components.skintravelable then
            table.insert(self.skintravellers, skintraveller)

            information = string.format(
                STRINGS.NANA_TELEPORT_TELEPORTING_TO,
                description, self.site, self.totalsites,
                cost_hunger, cost_sanity)
            if comment then
                comment:Say(string.format(information), 3)
            elseif talk then
                talk:Say(string.format(information), 3)
            end
--延时传送开始
            local skintravel_delay
            if TRAVEL_COUNTDOWN_ENABLE then
                skintravel_delay = 5
            else
                skintravel_delay = 0
            end
			
			
			
--结束

            self.skintraveltask = self.inst:DoTaskInTime(skintravel_delay, function()
                self.skintraveltask = nil
                local dest_pos_valid = xf ~= nil and zf ~= nil and
                    TheWorld.Map:IsPassableAtPoint(xf, 0, zf)
                for k, who in pairs(self.skintravellers) do
                    if not destination:IsValid() or not dest_pos_valid then
                        if comment then
                            comment:Say(STRINGS.NANA_TELEPORT_DESTINATION_UNAVAILABLE)
                        elseif talk then
                            talk:Say(STRINGS.NANA_TELEPORT_DESTINATION_UNAVAILABLE)
                        end
                    elseif who == nil or
                        (who.components.health and
                            who.components.health:IsDead()) then
                        if comment then
                            comment:Say(STRINGS.NANA_TELEPORT_UNABLE_TO_TELEPORT_BODY)
                        end
                    elseif not (who:IsValid() and self.inst:IsValid() and
                            who:IsNear(self.inst, 10)) then
                        print(STRINGS.NANA_TELEPORT_DESTINATION_INVALID)
                    elseif IsNearDanger(who) then
                        if talk then
                            talk:Say(STRINGS.NANA_TELEPORT_NOT_SAFE_NEARBY)
                        elseif comment then
                            comment:Say(STRINGS.NANA_TELEPORT_NOT_SAFE_NEARBY)
                        end
                    elseif destination.components.skintravelable.ownership and
                        destination:HasTag(ownershiptag) and who.userid ~= nil and
                        not destination:HasTag("uid_" .. who.userid) then
                        if comment then
                            comment:Say(STRINGS.NANA_TELEPORT_THE_DESTINATION_IS_CONTROLLED_BY_OWNERSHIP)
                        elseif talk then
                            talk:Say(STRINGS.NANA_TELEPORT_THE_DESTINATION_IS_CONTROLLED_BY_OWNERSHIP)
                        end
                    elseif who.components.hunger and who.components.sanity then
                        who.components.hunger:DoDelta(-cost_hunger)
                        who.components.sanity:DoDelta(-cost_sanity)
                        if who.Physics ~= nil then
                            who.Physics:Teleport(xf - 1, 0, zf)
                        else
                            who.Transform:SetPosition(xf - 1, 0, zf)
                        end

                        -- follow
                        if who.components.leader and
                            who.components.leader.followers then
                            for kf, vf in pairs(who.components.leader.followers) do
                                if kf.Physics ~= nil then
                                    kf.Physics:Teleport(xf + 1, 0, zf)
                                else
                                    kf.Transform:SetPosition(xf + 1, 0, zf)
                                end
                            end
                        end

                        local inventory = who.components.inventory
                        if inventory then
                            for ki, vi in pairs(inventory.itemslots) do
                                if vi.components.leader and
                                    vi.components.leader.followers then
                                    for kif, vif in pairs(vi.components.leader.followers) do
                                        if kif.Physics ~= nil then
                                            kif.Physics:Teleport(xf, 0, zf + 1)
                                        else
                                            kif.Transform:SetPosition(xf, 0, zf + 1)
                                        end
                                    end
                                end
                            end
                        end

                        local container = inventory:GetOverflowContainer()
                        if container then
                            for kb, vb in pairs(container.slots) do
                                if vb.components.leader and
                                    vb.components.leader.followers then
                                    for kbf, vbf in pairs(vb.components.leader.followers) do
                                        if kbf.Physics ~= nil then
                                            kbf.Physics:Teleport(xf, 0, zf - 1)
                                        else
                                            kbf.Transform:SetPosition(xf, 0, zf - 1)
                                        end
                                    end
                                end
                            end
                        end

						--使用未写木牌传送时，删除之
                        -- if self.inst.components.writeable and
                            -- not self.inst.components.writeable:IsWritten() then
                            -- self.inst:Remove()
                        -- end
                    else
                        if talk then
                            talk:Say(STRINGS.NANA_TELEPORT_UNABLE_TO_TRANSMIT)
                        elseif comment then
                            comment:Say(STRINGS.NANA_TELEPORT_UNABLE_TO_TRANSMIT)
                        end
                    end
                end
                self.skintravellers = {}
            end)
			--延时传送时候人物头顶有倒计时
			for i = 0, 5 do
				self.inst:DoTaskInTime(i, function()
					local talker = comment or talk 
					if talker then
						talker:Say(STRINGS["NANA_TELEPORT_COUNT_"..tostring(i)])
					end
				end)
			end
		elseif comment then
            comment:Say(STRINGS.NANA_TELEPORT_DESTINATION_UNAVAILABLE)
        elseif talk then
            talk:Say(STRINGS.NANA_TELEPORT_DESTINATION_UNAVAILABLE)
        end
    end
    self:EndSkinTravel()
end

function SkinTravelable:CancelSkinTravel(skintraveller)
    if self.skintraveltask ~= nil then
        self.skintraveltask:Cancel()
        self.skintraveltask = nil
    end
    if self.skintraveltask1 ~= nil then
        self.skintraveltask1:Cancel()
        self.skintraveltask1 = nil
    end
    if self.skintraveltask2 ~= nil then
        self.skintraveltask2:Cancel()
        self.skintraveltask2 = nil
    end
    if self.skintraveltask3 ~= nil then
        self.skintraveltask3:Cancel()
        self.skintraveltask3 = nil
    end
    if self.skintraveltask4 ~= nil then
        self.skintraveltask4:Cancel()
        self.skintraveltask4 = nil
    end
    if self.skintraveltask5 ~= nil then
        self.skintraveltask5:Cancel()
        self.skintraveltask5 = nil
    end
end

function SkinTravelable:EndSkinTravel()
    if self.skintraveller ~= nil then
        self.inst:StopUpdatingComponent(self)

        if self.screen ~= nil then
            self.skintraveller.HUD:CloseSkinTravelScreen()
            self.screen = nil
        end

        self.inst:RemoveEventCallback("ms_closepopups", self.onclosepopups, self.skintraveller)
        self.inst:RemoveEventCallback("onremove", self.onclosepopups, self.skintraveller)

        if IsXB1() then
            if self.skintraveller:HasTag("player") and
                self.skintraveller:GetDisplayName() then
                local ClientObjs = TheNet:GetClientTable()
                if ClientObjs ~= nil and #ClientObjs > 0 then
                    for i, v in ipairs(ClientObjs) do
                        if self.skintraveller:GetDisplayName() == v.name then
                            self.netid = v.netid
                            break
                        end
                    end
                end
            end
        end

        self.skintraveller = nil
    elseif self.screen ~= nil then
        -- Should not have screen and no skintraveller, but just in case...
        if self.screen.inst:IsValid() then self.screen:Kill() end
        self.screen = nil
    end
end

--------------------------------------------------------------------------
-- Check for auto-closing conditions
--------------------------------------------------------------------------

function SkinTravelable:OnUpdate(dt)
    if self.skintraveller == nil then
        self.inst:StopUpdatingComponent(self)
    elseif (self.skintraveller.components.rider ~= nil and
            self.skintraveller.components.rider:IsRiding()) or
        not (self.skintraveller:IsNear(self.inst, 3) and
            CanEntitySeeTarget(self.skintraveller, self.inst)) then
        self:EndSkinTravel()
    end
end

--------------------------------------------------------------------------

function SkinTravelable:OnRemoveFromEntity()
    SkinTravelable:OnRemoveEntity()
    self.inst:RemoveTag("skintravelable")
end

function SkinTravelable:OnRemoveEntity()
    self:EndSkinTravel()
    for i, v in ipairs(ALL_TRAVELABLES) do
        if v == self then
            table.remove(ALL_TRAVELABLES, i)
            break
        end
    end
end

return SkinTravelable
