--------------------------------
--[[ 秘密垃圾桶 modmain处理]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-03-15]]
--[[ @updateTime: 2022-03-15]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
-- 增加container
do
    local containers = require "containers"
    local params = containers.params
    -- 注意params的key值必须是prefab名称
    params[TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB] = {
        widget =
        {
            slotpos = {},
            animbank = "ui_largechest_5x5",
            animbuild = "ui_largechest_5x5",
            pos = Vector3(0, 200, 0),
            side_align_tip = 160,
            buttoninfo =
            {
                text = STRINGS.DORAEMON_TECH.DORAEMON_ACTION_GARBAGE_DESTROY,
                position = Vector3(0, -235, 0),
            }
        },
        type = "chest",
        openlimit = 1, -- 只能同时一个人打开
    }
    local myContainer = params[TUNING.DORAEMON_TECH.SECRET_GARBAGE_CAN_PREFAB]

    for y = 3, -1, -1 do
        for x = -1, 3 do
            table.insert(myContainer.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
        end
    end
    -- 放入item校验方法
    myContainer.itemtestfn = function(container, item, slot)
        return true
    end
    --
    myContainer.widget.buttoninfo.fn = function(inst, doer)
        if inst.components.container ~= nil then
            BufferedAction(doer, inst, ACTIONS["DORAEMON_GARBAGE_DESTROY_ACTION"]):Do()
        elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
            SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS["DORAEMON_GARBAGE_DESTROY_ACTION"].code, inst, ACTIONS["DORAEMON_GARBAGE_DESTROY_ACTION"].mod_name)
        end
    end
    -- 更新MAXITEMSLOTS
    for k, v in pairs(params) do
        containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
    end
end
