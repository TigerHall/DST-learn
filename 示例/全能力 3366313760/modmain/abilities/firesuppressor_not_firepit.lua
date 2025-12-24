local Utils = require("aab_utils/utils")
local FireDetector = require("components/firedetector")
local NOTAGS = Utils.ChainFindUpvalue(FireDetector.Activate, "LookForFiresAndFirestarters", "NOTAGS")
    or Utils.ChainFindUpvalue(FireDetector.DetectFire, "LookForFiresAndFirestarters", "NOTAGS")
    or Utils.ChainFindUpvalue(FireDetector.ActivateEmergencyMode, "OnDetectEmergencyTargets", "NOTAGS")
    or Utils.ChainFindUpvalue(FireDetector.RaiseEmergencyLevel, "EmergencyResponse", "DetectFireEmergency", "NOTAGS")
if NOTAGS then
    table.insert(NOTAGS, "campfire")
else
    --这都拿不到的话不太可能吧
    print("拿不到firedetector组件的NOTAGS，灭火器不熄灭火坑功能失效。")
end
