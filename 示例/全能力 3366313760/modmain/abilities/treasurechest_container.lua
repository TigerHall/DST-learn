local Utils = require("aab_utils/utils")

local BUNDLEWRAP_CONTAINER = GetModConfigData("treasurechest_container")

local params = require("containers").params

local GAP = 80
params.treasurechest = deepcopy(params.treasurechest) --避免影响到其他容器
params.treasurechest.widget.slotpos = {}
local num = math.sqrt(BUNDLEWRAP_CONTAINER)
for i = 1, num do
    for j = 1, num do
        table.insert(params.treasurechest.widget.slotpos, Vector3(GAP * (i - num / 2) - GAP / 2, GAP * (j - num / 2) - GAP / 2, 0))
    end
end

----------------------------------------------------------------------------------------------------
local function OpenBefore(self, container)
    if not container or container.prefab ~= "treasurechest" then
        return
    end
    local scale = 1 / 3 * num
    self.bganim:SetScale(scale, scale)
end

AddClassPostConstruct("widgets/containerwidget", function(self)
    Utils.FnDecorator(self, "Open", OpenBefore)
end)
