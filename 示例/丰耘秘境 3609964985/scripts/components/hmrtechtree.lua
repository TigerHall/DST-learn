local HMR_TECH_LIST = require("hmrmain/hmr_lists").HMR_TECH_LIST

local HMRTechTree = Class(function(self, inst)
    self.inst = inst

    self.techstatus = {}

    if TheWorld.ismastersim then
        self.inst:ListenForEvent("ms_playerjoined", function(world, player)
            self:Teach(player)
            self:UpdateCilentTechStatus(player)
        end, TheWorld)
    end
end)

function HMRTechTree:LearnTech(techname, doer)
    if not TheWorld.ismastersim then
        -- 客户端不用传doer
        SendModRPCToServer(GetModRPC("HMR", "HMRTECHTREE_LEARN"), techname)
    else
        local techdata = HMR_TECH_LIST[techname]
        if techdata ~= nil then
            local success
            if techdata.requirefn ~= nil then
                success = techdata.requirefn(doer or AllPlayers[1])
            end

            if success then
                self.techstatus[techname] = true
                if techdata.onlearnfn ~= nil then
                    techdata.onlearnfn(self.inst)
                end

                self:Teach()
            end
        end
        self:UpdateCilentTechStatus()
    end
end

function HMRTechTree:GetTechStatus(techname)
    return self.techstatus[techname] or false
end

function HMRTechTree:UpdateCilentTechStatus(player)
    local success, encoded_techstatus = pcall(json.encode, self.techstatus)
    if success then
        SendModRPCToClient(CLIENT_MOD_RPC["HMR"]["UPDATE_CILENT_TECHTREE"], player, encoded_techstatus)
    end
end

-- 解锁科技为：TECH.HMR_TECH
function HMRTechTree:Teach(player)
    local targets = {}
    if player == nil then
        targets = AllPlayers
    elseif type(player) == "table" then
        if player.userid ~= nil then
            targets = {player}
        else
            targets = player
        end
    end

    for _, target in pairs(targets) do
        for techname, _ in pairs(self.techstatus) do
            if self.techstatus[techname] and target.components.builder ~= nil then
                local unlocktechs = HMR_TECH_LIST[techname].unlocktechs
                for _, unlocktech in pairs(unlocktechs) do
                    target.components.builder:UnlockRecipe(unlocktech)
                end
            end
        end
    end
end

function HMRTechTree:OnSave()
    local data = {
        techstatus = self.techstatus
    }

    return next(data) ~= nil and data or nil
end

function HMRTechTree:OnLoad(data)
    if data ~= nil then
        self.techstatus = data.techstatus
    end
    self.inst:DoTaskInTime(0, function()
        self:UpdateCilentTechStatus()
    end)
end

return HMRTechTree