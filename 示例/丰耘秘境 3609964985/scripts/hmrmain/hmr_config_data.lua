local LANGUAGE = true

return {
    client = {
        {
            name = "HONOR_ARMOR_SKILL",
            label = "辉煌护甲技能按键绑定",
            hover = "辉煌护甲技能按键绑定",
            options = {"binding_common"},
            default = KEY_LALT,
        },
        {
            name = "HONOR_MULTITOOL_MODE",
            label = "辉煌多用工具模式按键绑定",
            hover = "辉煌多用工具模式按键绑定",
            options = {"binding_common"},
            default = KEY_R,
        },
        {
            name = "MOISTURE_CONTROL_UP",
            label = "潮湿度控制（增加）按键绑定",
            hover = "潮湿度控制（增加）按键绑定",
            options = {"binding_common"},
            default = KEY_UP,
        },
        {
            name = "MOISTURE_CONTROL_DOWN",
            label = "潮湿度控制（减少）按键绑定",
            hover = "潮湿度控制（减少）按键绑定",
            options = {"binding_common"},
            default = KEY_DOWN,
        },
        {
            name = "CDK_PANEL_POPUP",
            label = "CDK兑换界面按键绑定",
            hover = "CDK兑换界面按键绑定",
            options = {"binding_common"},
            default = KEY_F12,
        },
        {
            name = "RESET_UI_POS",
            label = "重置UI位置",
            hover = LANGUAGE and "重置UI位置" or "Reset UI Position",
            options = {{
                description = LANGUAGE and "重置" or "Reset",
                hover = LANGUAGE and "重置UI位置" or "Reset UI Position",
                data = true
            }, {
                description = LANGUAGE and "不改变" or "Keep",
                hover = LANGUAGE and "不改变UI位置" or "Keep UI Position",
                data = false
            }},
            default = false,
            type = "event"
        },
        {
            name = "SHOW_BUFF_PANEL",
            label = "显示buff面板",
            hover = LANGUAGE and "显示buff面板" or "Show Buff Panel",
            options = {{
                description = LANGUAGE and "显示" or "Show",
                hover = LANGUAGE and "显示buff面板" or "Show Buff Panel",
                data = true
            }, {
                description = LANGUAGE and "隐藏" or "Hode",
                hover = LANGUAGE and "隐藏buff面板" or "Hide Buff Panel",
                data = false
            }},
            default = true
        },
        {
            name = "BUFF_PANEL_SKIN",
            label = "buff面板皮肤",
            hover = LANGUAGE and "buff面板皮肤" or "Buff Panel Skin",
            options = {{
                description = LANGUAGE and "未解谜团" or "Default",
                hover = LANGUAGE and "未解谜团" or "Default Buff Panel Skin",
                data = ""
            }, {
                description = LANGUAGE and "绿野仙踪" or "The Wizard of Oz",
                hover = LANGUAGE and "绿野仙踪" or "The Wizard of Oz Buff Panel Skin",
                data = "_forest"
            }},
            default = ""
        }
    },
    server = {
        -- {
        --     name = "BATCH_TRADE",
        --     label = "批量交易",
        --     hover = LANGUAGE and "批量交易" or "Batch Trade",
        --     options = {{
        --         description = LANGUAGE and "开启" or "Enable",
        --         hover = LANGUAGE and "开启批量交易" or "Enable batch trade",
        --         data = true
        --     }, {
        --         description = LANGUAGE and "关闭" or "Disable",
        --         hover = LANGUAGE and "关闭批量交易" or "Disable batch trade",
        --         data = false
        --     }},
        --     default = true
        -- },
    },
}