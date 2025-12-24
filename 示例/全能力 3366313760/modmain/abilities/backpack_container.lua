local Utils = require("aab_utils/utils")
local params = require("containers").params

local BACKPACK_CONTAINER = GetModConfigData("backpack_container")
local col = BACKPACK_CONTAINER > 18 and 3 or 2
local row = BACKPACK_CONTAINER / col

local GAP = 75
params.backpack.widget.animbank = "ui_krampusbag_2x8"
params.backpack.widget.animbuild = "ui_krampusbag_2x8"
params.backpack.widget.slotpos = {}
params.backpack.widget.pos = Vector3(-5, -130, 0)

-- y: 240->-210
local start_y = GAP * row / 2 - 100 - GAP * (row - 8)
for y = 7 - row, 6 do
    for x = (col == 3 and -1 or 0), 1 do
        table.insert(params.backpack.widget.slotpos, Vector3(-162 + GAP * x, -GAP * y + start_y, 0))
    end
end

----------------------------------------------------------------------------------------------------
local function OpenBefore(self, container)
    if not container or not (container.prefab == "backpack" or container.prefab == "icepack") then --如果其他mod也用了这个容器，背景就盖不住了
        return
    end

    self.bganim:SetScale(1 / 2 * col * (col == 3 and 0.9 or 1), 1 / 7 * row)
end

AddClassPostConstruct("widgets/containerwidget", function(self)
    Utils.FnDecorator(self, "Open", OpenBefore)
end)

----------------------------------------------------------------------------------------------------

GLOBAL.c_set_container_y = function(y_offset)
    if y_offset then
        params.backpack.widget.slotpos = {}
        for y = 7 - row, 6 do
            for x = (col == 3 and -1 or 0), 1 do
                table.insert(params.backpack.widget.slotpos, Vector3(-162 + GAP * x, -GAP * y + y_offset, 0))
            end
        end
    end
end
