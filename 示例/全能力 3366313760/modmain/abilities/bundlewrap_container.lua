local Utils = require("aab_utils/utils")

local BUNDLEWRAP_CONTAINER = GetModConfigData("bundlewrap_container")

local params = require("containers").params

local X_GAP = 75
local Y_GAP = 72

params.bundle_container = deepcopy(params.bundle_container) --避免影响到其他容器
params.bundle_container.widget.slotpos = {}
local num = math.sqrt(BUNDLEWRAP_CONTAINER)
for i = 1, num do
    for j = 1, num do
        table.insert(params.bundle_container.widget.slotpos, Vector3(X_GAP * (i - num / 2) - X_GAP / 2, Y_GAP * (j - num / 2) - Y_GAP / 2, 0))
    end
end

params.bundle_container.widget.buttoninfo.position = Vector3(0, Y_GAP * (1 - num / 2) - Y_GAP / 2 - 64, 0)


----------------------------------------------------------------------------------------------------
local function OpenBefore(self, container)
    if not container or container.prefab ~= "bundle_container" then
        return
    end
    local scale = 1 / 2 * num * 0.81
    self.bganim:SetScale(scale, scale)
end

AddClassPostConstruct("widgets/containerwidget", function(self)
    Utils.FnDecorator(self, "Open", OpenBefore)
end)
