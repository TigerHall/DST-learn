TUNING.SKILL_THRESHOLDS = { 3, 3, 4, 4, 4 } --每个技能点解锁需要的经验
for i = 1, 95 do
    table.insert(TUNING.SKILL_THRESHOLDS, 5)
end
local need = 18 + 20 * 95
TUNING.FIXME_DO_NOT_USE_FOR_MODS_NEW_MAX_XP_VALUE = math.max(TUNING.FIXME_DO_NOT_USE_FOR_MODS_NEW_MAX_XP_VALUE, need)
TUNING.FIXME_DO_NOT_USE_FOR_MODS_OLD_MAX_XP_VALUE = math.max(TUNING.FIXME_DO_NOT_USE_FOR_MODS_OLD_MAX_XP_VALUE, need)

----------------------------------------------------------------------------------------------------


local skilltreedefs = require "prefabs/skilltree_defs"
-- 修改特定角色的技能树
for _, data in pairs(skilltreedefs.SKILLTREE_DEFS) do
    for k, v in pairs(data) do
        if v.lock_open then
            v.lock_open = function() return true end
        end
    end
end
package.loaded["prefabs.skilltree_defs"] = skilltreedefs
