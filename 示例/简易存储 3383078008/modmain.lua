GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

Assets = {
    Asset("ATLAS","images/inventoryimages/wirelessterminal.xml"),
    Asset("ATLAS","images/inventoryimages/terminalconnector.xml"),
}

PrefabFiles =  {
    "terminalconnector",
}

local locale = LOC.GetLocaleCode()
TUNING.SS_CHINESE = locale == "zh" or locale == "zhr"
TUNING.SS_WIRELESS = GetModConfigData("wirelessterminal") or false
TUNING.SS_LINKRADIUS = GetModConfigData("linkradius") or 15
TUNING.SS_TECH2 = GetModConfigData("tech2") or false

modimport("main/hook")
modimport("main/preview")
modimport("main/rpc")
modimport("main/actions")
modimport("main/ui")
modimport("main/controller")

if TUNING.SS_CHINESE then

    STRINGS.NAMES.WIRELESSTERMINAL = "无线存储终端"
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.WIRELESSTERMINAL = "这是科技还是魔法？"
    STRINGS.RECIPE_DESC.WIRELESSTERMINAL = "让你从遥远的地方访问终端！"

    STRINGS.NAMES.TERMINALCONNECTOR = "存储终端"
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.TERMINALCONNECTOR = "这是科技还是魔法？"
    STRINGS.RECIPE_DESC.TERMINALCONNECTOR = "把你的容器链接在一起！"

    STRINGS.UNKNOWACTION = "操作"

    STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.REMOTEOPENTERMINAL = {
        NOCONTAINER = "绑定的终端附近没有可用的容器！",
        NOLINK = "无线终端还没有在当前世界绑定过！",
        LINKINVALID = "绑定的终端已经不在这个世界了！"
    }

    STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.OPENTERMINAL = {
        NOCONTAINER = "这个终端附近没有可用的容器！",
    }

    STRINGS.SS_JSONERROR_POPUP = {
        NOTICE = ":提示",
        CAUSE = "部分容器数据解析失败，可能是因为单个容器内物品过多！",
        CONFIRM = "我已知悉，后续不再提醒",
    }
else

    STRINGS.NAMES.WIRELESSTERMINAL = "Wireless Storage Terminal"
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.WIRELESSTERMINAL = "Is this technology or magic?"
    STRINGS.RECIPE_DESC.WIRELESSTERMINAL = "Allow you to access the terminal from a distant place!"

    STRINGS.NAMES.TERMINALCONNECTOR = "Storage Terminal"
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.TERMINALCONNECTOR = "Is this technology or magic?"
    STRINGS.RECIPE_DESC.TERMINALCONNECTOR = "Link your chests together!"

    STRINGS.UNKNOWACTION = "Execute"

    STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.REMOTEOPENTERMINAL = {
        NOCONTAINER = "There are no available chests near the bound terminal!",
        NOLINK = "Wireless terminals have not been bound in the current world yet!",
        LINKINVALID = "The bound terminal is no longer in this world!"
    }

    STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.OPENTERMINAL = {
        NOCONTAINER = "There are no available chests near this terminal!",
    }

    STRINGS.SS_JSONERROR_POPUP = {
        NOTICE = ":Notice",
        CAUSE = "Partial container data parsing failed, possibly because too many items in a single container!",
        CONFIRM = "OK, I know",
    }
end

AddRecipe2(
    "terminalconnector",
    {
        Ingredient("cutstone", 4),
        Ingredient("transistor", 4),
        Ingredient("goldnugget", 4),
    },
    TECH.SCIENCE_TWO,
    {
    atlas = "images/inventoryimages/terminalconnector.xml",
    image = "terminalconnector.tex",
    nounlock = false,
    placer = "terminalconnector_placer",
    min_spacing = 2,
    },
    {
    "PROTOTYPERS",
    "CONTAINERS",
    }
)

AddPrototyperDef("terminalconnector",
    {
        icon_atlas = CRAFTING_ICONS_ATLAS,
        icon_image = "filter_none.tex",
        is_crafting_station = true,
        filter_text = TUNING.SS_CHINESE and "制作站整合" or "Crafting Station Integration",
    }
)

if TUNING.SS_WIRELESS then

    table.insert(env.PrefabFiles, "wirelessterminal")

    AddRecipe2(
        "wirelessterminal",
        {
            Ingredient("moonstorm_static_item", 1),
            Ingredient("wagpunk_bits", 4),
            Ingredient("purebrilliance", 4),
        },
        TECH.SCIENCE_TWO,
        {
        atlas = "images/inventoryimages/wirelessterminal.xml",
        image = "wirelessterminal.tex",
        nounlock = false,
        },
        {
        "CONTAINERS",
        }
    )

end


-- modimport("debug")