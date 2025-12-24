local WaxClusterLegion = Class(function(self, inst)
    self.inst = inst
end)

function WaxClusterLegion:Cluster(doer, target)
    local dd1 = self.inst._dd_wax
    local dd2 = target._dd_wax
    if dd1 == nil or dd2 == nil then
        return
    end
    local newc = dd1.lvl
    if newc == nil or newc <= 0 then --如果是0级，则应该还是+1级才行，不然就没变化了
        newc = 1
    end
    newc = newc + (dd2.lvl or 0)
    if newc >= 100 then
        newc = newc - 100
    end
    dd2.lvl = newc
    if target._lvl_l ~= nil then
        target._lvl_l:set(newc)
    end
    if doer.components.talker ~= nil then
        doer.components.talker:Say(tostring(newc))
    end
    if target.fn_waxcluster ~= nil then
        target.fn_waxcluster(target, newc)
    end

    local pos
    if target.components.inventoryitem == nil or target.components.inventoryitem.owner == nil then
        pos = target:GetPosition()
    else
        pos = doer:GetPosition()
    end
    local fx = SpawnPrefab("waxcluster_l_fx")
    if fx ~= nil then
        fx.Transform:SetPosition(pos.x, pos.y, pos.z)
    end

    return true
end

return WaxClusterLegion
