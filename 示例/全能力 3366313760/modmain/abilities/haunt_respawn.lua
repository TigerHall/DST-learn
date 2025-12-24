local Utils = require("aab_utils/utils")

local function DelayDestroy(inst, doer)
    if inst.components.workable then
        inst.components.workable:Destroy(doer)
    else
        ReplacePrefab(inst, "collapse_small")
    end
end

local function DoHauntBefore(self, doer)
    if doer then
        doer:PushEvent("respawnfromghost", { source = self.inst })
        self.inst:DoTaskInTime(0, DelayDestroy, doer)
    end
end

for _, v in ipairs({
    "skeleton",
    "skeleton_player",
    "skeleton_notplayer",
    "skeleton_notplayer_1",
    "skeleton_notplayer_2",
    "hauntable"
}) do
    AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end

        if not inst.components.hauntable then
            inst:AddComponent("hauntable")
        end
        Utils.FnDecorator(inst.components.hauntable, "DoHaunt", DoHauntBefore)
    end)
end
