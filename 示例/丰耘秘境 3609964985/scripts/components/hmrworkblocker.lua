local WorkBlocker = Class(function(self, inst)
    self.inst = inst

    self.actions = {}

    self.inst:AddTag("workblocker")
end)

function WorkBlocker:OnRemoveFromEntity()
    self.inst:RemoveTag("workblocker")
end

function WorkBlocker:SetBlockAction(block_action, range, test)
    self.actions[block_action] = {range = range, test = test}
end

function WorkBlocker:CanBlock(target, worker)
    if target.components.workable == nil then
        return false
    end

    local action = target.components.workable:GetWorkAction()
    if action == nil or self.actions[action] == nil then
        return false
    end

    local range = self.actions[action].range
    local test = self.actions[action].test
    local can_block
    if test ~= nil then
        if type(test) == "function" then
            can_block = test(self.inst, target, worker)
        else
            can_block = test
        end
    else
        can_block = true
    end

    if self.inst:GetDistanceSqToInst(target) <= range*range and can_block then
        return true
    end

    return false
end

return WorkBlocker