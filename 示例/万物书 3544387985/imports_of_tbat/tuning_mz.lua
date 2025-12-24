TUNING.TBAT_BUFF_SHOW_NUM = false
TUNING.TBAT_BUFF_SWITCH = true
TUNING.TBAT_BUFF_SETTING = 1
TUNING.TbatModEnable = require("utils/tbatmodenable")



TUNING.TBAT_SHOW_BUFFS = GetModConfigData("TBAT_BUFF_DISPLAY") and not TUNING.TbatModEnable:MedalEnable() --是否显示buff时间
