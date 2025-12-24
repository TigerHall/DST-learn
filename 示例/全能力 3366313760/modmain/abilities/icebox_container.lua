local Utils = require("aab_utils/utils")

local ICEBOX_CONTAINER = GetModConfigData("icebox_container")

local params = require("containers").params

local GAP = 80
params.icebox = deepcopy(params.icebox) --避免影响到其他容器
params.icebox.widget.slotpos = {}
local num = math.sqrt(ICEBOX_CONTAINER)
for i = 1, num do
    for j = 1, num do
        table.insert(params.icebox.widget.slotpos, Vector3(GAP * (i - num / 2) - GAP / 2, GAP * (j - num / 2) - GAP / 2, 0))
    end
end

params.saltbox = params.icebox

----------------------------------------------------------------------------------------------------
local function OpenBefore(self, container)
    if container and (container.prefab == "icebox" or container.prefab == "saltbox") then
        local scale = 1 / 3 * num
        self.bganim:SetScale(scale, scale)
    end
end

AddClassPostConstruct("widgets/containerwidget", function(self)
    Utils.FnDecorator(self, "Open", OpenBefore)
end)
