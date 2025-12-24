local STACK_MAX = GetModConfigData("stack_max")

TUNING.STACK_SIZE_LARGEITEM = STACK_MAX
TUNING.STACK_SIZE_MEDITEM = STACK_MAX
TUNING.STACK_SIZE_SMALLITEM = STACK_MAX
TUNING.STACK_SIZE_TINYITEM = STACK_MAX
TUNING.WORTOX_MAX_SOULS = STACK_MAX

----------------------------------------------------------------------------------------------------

-- 直接修改TUNING常量，也就不用hook了，如果修改全局的常量对游戏有问题，再使用这个办法
-- local Stackable = require("components/stackable_replica")
-- local STACK_SIZE_CODES = Utils.ChainFindUpvalue(Stackable.SetMaxSize, "STACK_SIZE_CODES")
-- if not STACK_SIZE_CODES then
--     print("拿不到stackable_replica的表STACK_SIZE_CODES，堆叠上限功能失效。")
--     return
-- end
-- table.insert(STACK_SIZE_CODES, STACK_MAX)

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    --以防万一，不考虑中途修改maxsize的预制件
    if inst.components.Stackable and inst.components.Stackable.maxsize ~= STACK_MAX then
        inst.components.stackable.maxsize = STACK_MAX
    end
end)
