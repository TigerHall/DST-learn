local SkinTravelable = Class(function(self, inst)
    self.inst = inst

    self._infos = net_string(inst.GUID, "skintravelable._infos")

    self.screen = nil
    self.opentask = nil

    if TheWorld.ismastersim then
        self.classified = SpawnPrefab("skintravelable_classified")
        self.classified.entity:SetParent(inst.entity)
    else
        if self.classified == nil and inst.skintravelable_classified ~= nil then
            self.classified = inst.skintravelable_classified
            inst.skintravelable_classified.OnRemoveEntity = nil
            inst.skintravelable_classified = nil
            self:AttachClassified(self.classified)
        end
    end
end)

--------------------------------------------------------------------------

function SkinTravelable:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified:Remove()
            self.classified = nil
        else
            self.classified._parent = nil
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified,
                                          self.classified)
            self:DetachClassified()
        end
    end
end

SkinTravelable.OnRemoveEntity = SkinTravelable.OnRemoveFromEntity

--------------------------------------------------------------------------
-- Client triggers writing based on receiving access to classified data
--------------------------------------------------------------------------

local function BeginSkinTravel(inst, self)
    self.opentask = nil
    self:BeginSkinTravel(ThePlayer)
end

function SkinTravelable:AttachClassified(classified)
    self.classified = classified

    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    self.opentask = self.inst:DoTaskInTime(0, BeginSkinTravel, self)
end

function SkinTravelable:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
    self:EndSkinTravel()
end

--------------------------------------------------------------------------
-- Common interface
--------------------------------------------------------------------------

function SkinTravelable:BeginSkinTravel(skintraveller)
    if self.inst.components.skintravelable ~= nil then
        if self.opentask ~= nil then
            self.opentask:Cancel()
            self.opentask = nil
        end
        self.inst.components.skintravelable:BeginSkinTravel(skintraveller)
    elseif self.classified ~= nil and self.opentask == nil and skintraveller ~= nil and
        skintraveller == ThePlayer then
        if skintraveller.HUD == nil then
            -- abort
        else -- if not busy...
            self.screen = skintraveller.HUD:ShowSkinTravelScreen(self.inst)
        end
    end
end

function SkinTravelable:SkinTravel(skintraveller, index)
    if self.inst.components.skintravelable ~= nil then
        self.inst.components.skintravelable:SkinTravel(skintraveller, index)
    elseif self.classified ~= nil and skintraveller == ThePlayer then
        SendModRPCToServer(MOD_RPC.FastSkinTravel.SkinTravel, self.inst, index)
    end
end

function SkinTravelable:EndSkinTravel()
    if self.opentask ~= nil then
        self.opentask:Cancel()
        self.opentask = nil
    end
    if self.inst.components.skintravelable ~= nil then
        self.inst.components.skintravelable:EndSkinTravel()
    elseif self.screen ~= nil then
        if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
            ThePlayer.HUD:CloseSkinTravelScreen()
        elseif self.screen.inst:IsValid() then
            -- Should not have screen and no skintraveller, but just in case...
            self.screen:Kill()
        end
        self.screen = nil
    end
end

function SkinTravelable:SetSkinTraveller(skintraveller)
    self.classified.Network:SetClassifiedTarget(skintraveller or self.inst)
    if self.inst.components.skintravelable == nil then
        -- Should only reach here during skintravelable construction
        assert(skintraveller == nil)
    end
end

function SkinTravelable:SetDestInfos(infos) self._infos:set(infos) end

function SkinTravelable:GetDestInfos() return self._infos:value() end

return SkinTravelable
