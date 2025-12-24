local IMAGES = {
    BG = { "images/ui/atbook_wiki/icon_k.xml", "icon_k.tex" },
    BG_UP = { "images/ui/atbook_wiki/icon_k_b.xml", "icon_k_b.tex" },
    BG_HEAD = { "images/ui/atbook_wiki/icon_yxy.xml", "icon_yxy.tex" },
    BG_RIGHT = { "images/ui/atbook_wiki/icon_che.xml", "icon_che.tex" },
    SLOT = { "images/ui/atbook_wiki/icon_gz.xml", "icon_gz.tex" },
    SLOT2 = { "images/ui/atbook_wiki/sw_gezi.xml", "sw_gezi.tex" },
    SLOT3 = { "images/ui/atbook_wiki/zw_gezi.xml", "zw_gezi.tex" },
    ARROW = { "images/ui/atbook_wiki/icon_gunlun_shang.xml", "icon_gunlun_shang.tex" },
    SCROLL_BAR = { "images/ui/atbook_wiki/icon_gunlun_xian.xml", "icon_gunlun_xian.tex" },
    POSITION_MARKER = { "images/ui/atbook_wiki/icon_gunlun.xml", "icon_gunlun.tex" },
    CLOSE = { "images/ui/atbook_wiki/icon_gb.xml", "icon_gb.tex" },
    TAB_1 = { "images/ui/atbook_wiki/icon_an_hxdy.xml", "icon_an_hxdy.tex" },
    TAB_2 = { "images/ui/atbook_wiki/icon_an_hxsw.xml", "icon_an_hxsw.tex" },
    TAB_3 = { "images/ui/atbook_wiki/icon_an_hxzw.xml", "icon_an_hxzw.tex" },
    TAB_4 = { "images/ui/atbook_wiki/icon_an_hxjz.xml", "icon_an_hxjz.tex" },
    TAB_5 = { "images/ui/atbook_wiki/icon_an_zbdj.xml", "icon_an_zbdj.tex" },
    TAB_6 = { "images/ui/atbook_wiki/icon_an_yjll.xml", "icon_an_yjll.tex" },
    BTN_ZB = { "images/ui/atbook_wiki/icon_zb.xml", "icon_zb.tex" },
    BTN_GS = { "images/ui/atbook_wiki/icon_bj.xml", "icon_bj.tex" },
    BTN_CAT = { "images/ui/atbook_wiki/ty_xz_1.xml", "ty_xz_1.tex" },
    BTN_CAT_LONG = { "images/ui/atbook_wiki/ty_xz_2.xml", "ty_xz_2.tex" },
    BUTTERFLY = { "images/ui/atbook_wiki/xz_hudie.xml", "xz_hudie.tex" },
    BASE_TITLE = { "images/ui/atbook_wiki/ty_xzkuang.xml", "ty_xzkuang.tex" },

    DETAILBG_BASE = { "images/ui/atbook_wiki/ty_kuang.xml", "ty_kuang.tex" },
    BTN_TYPE = { "images/ui/atbook_wiki/ty_an_2.xml", "ty_an_2.tex" },
    BTN_TYPE_DARK = { "images/ui/atbook_wiki/ty_an_1.xml", "ty_an_1.tex" },
    TYPE_JY = { "images/ui/atbook_wiki/ty_an_zi_jiayang_2.xml", "ty_an_zi_jiayang_2.tex" },
    TYPE_JY_DARK = { "images/ui/atbook_wiki/ty_an_zi_jiayang_1.xml", "ty_an_zi_jiayang_1.tex" },
    TYPE_YS = { "images/ui/atbook_wiki/ty_an_zi_yesheng_2.xml", "ty_an_zi_yesheng_2.tex" },
    TYPE_YS_DARK = { "images/ui/atbook_wiki/ty_an_zi_yesheng_1.xml", "ty_an_zi_yesheng_1.tex" },
    TYPE_YZ = { "images/ui/atbook_wiki/ty_an_zi_yizhi_2.xml", "ty_an_zi_yizhi_2.tex" },
    TYPE_YZ_DARK = { "images/ui/atbook_wiki/ty_an_zi_yizhi_1.xml", "ty_an_zi_yizhi_1.tex" },
    TYPE_ZJ = { "images/ui/atbook_wiki/ty_an_zi_zijian_2.xml", "ty_an_zi_zijian_2.tex" },
    TYPE_ZJ_DARK = { "images/ui/atbook_wiki/ty_an_zi_zijian_1.xml", "ty_an_zi_zijian_1.tex" },

    INFO_GN = { "images/ui/atbook_wiki/ty_bt_gongneng.xml", "ty_bt_gongneng.tex" },
    INFO_KJ = { "images/ui/atbook_wiki/ty_bt_keji.xml", "ty_bt_keji.tex" },
    INFO_PF = { "images/ui/atbook_wiki/ty_bt_peifang.xml", "ty_bt_peifang.tex" },
    INFO_SD = { "images/ui/atbook_wiki/ty_bt_sheding.xml", "ty_bt_sheding.tex" },
    INFO_SC = { "images/ui/atbook_wiki/ty_bt_shengcheng.xml", "ty_bt_shengcheng.tex" },
    INFO_TX = { "images/ui/atbook_wiki/ty_bt_texing.xml", "ty_bt_texing.tex" },

    -- ISLAND

    -- CREATURE
    CREATURE_TITLE = { "images/ui/atbook_wiki/partui/creature/sw_biaoti.xml", "sw_biaoti.tex" },
    CREATURE_TYPE1 = { "images/ui/atbook_wiki/partui/creature/sw_hxsw_2.xml", "sw_hxsw_2.tex" },
    CREATURE_TYPE1_DARK = { "images/ui/atbook_wiki/partui/creature/sw_hxsw_1.xml", "sw_hxsw_1.tex" },
    CREATURE_TYPE2 = { "images/ui/atbook_wiki/partui/creature/sw_tssw_2.xml", "sw_tssw_2.tex" },
    CREATURE_TYPE2_DARK = { "images/ui/atbook_wiki/partui/creature/sw_tssw_1.xml", "sw_tssw_1.tex" },

    -- PLANT
    PLANT_TITLE = { "images/ui/atbook_wiki/partui/plant/zw_biaoti.xml", "zw_biaoti.tex" },
    PLANT_TYPE1 = { "images/ui/atbook_wiki/partui/plant/zw_zi_hxzw_2.xml", "zw_zi_hxzw_2.tex" },
    PLANT_TYPE1_DARK = { "images/ui/atbook_wiki/partui/plant/zw_zi_hxzw_1.xml", "zw_zi_hxzw_1.tex" },
    PLANT_TYPE2 = { "images/ui/atbook_wiki/partui/plant/zw_zi_stzy_2.xml", "zw_zi_stzy_2.tex" },
    PLANT_TYPE2_DARK = { "images/ui/atbook_wiki/partui/plant/zw_zi_stzy_1.xml", "zw_zi_stzy_1.tex" },

    -- STRUCTURE
    STRUCTURE_TYPE1 = { "images/ui/atbook_wiki/partui/structure/jz_fwjz_2.xml", "jz_fwjz_2.tex" },
    STRUCTURE_TYPE1_DARK = { "images/ui/atbook_wiki/partui/structure/jz_fwjz_1.xml", "jz_fwjz_1.tex" },
    STRUCTURE_TYPE2 = { "images/ui/atbook_wiki/partui/structure/jz_gnjz_2.xml", "jz_gnjz_2.tex" },
    STRUCTURE_TYPE2_DARK = { "images/ui/atbook_wiki/partui/structure/jz_gnjz_1.xml", "jz_gnjz_1.tex" },
    STRUCTURE_TYPE3 = { "images/ui/atbook_wiki/partui/structure/jz_zsjz_2.xml", "jz_zsjz_2.tex" },
    STRUCTURE_TYPE3_DARK = { "images/ui/atbook_wiki/partui/structure/jz_zsjz_1.xml", "jz_zsjz_1.tex" },

    -- INVENTORY
    INVENTORY_TYPE1 = { "images/ui/atbook_wiki/partui/inventory/zb_hxdj_2.xml", "zb_hxdj_2.tex" },
    INVENTORY_TYPE1_DARK = { "images/ui/atbook_wiki/partui/inventory/zb_hxdj_1.xml", "zb_hxdj_1.tex" },
    INVENTORY_TYPE2 = { "images/ui/atbook_wiki/partui/inventory/zb_hxzb_2.xml", "zb_hxzb_2.tex" },
    INVENTORY_TYPE2_DARK = { "images/ui/atbook_wiki/partui/inventory/zb_hxzb_1.xml", "zb_hxzb_1.tex" },

    -- FOOD
    FOOD_BG = { "images/ui/atbook_wiki/partui/food/yj_kuang.xml", "yj_kuang.tex" },
    FOOD_TYPE1 = { "images/ui/atbook_wiki/partui/food/yj_hxyj_2.xml", "yj_hxyj_2.tex" },
    FOOD_TYPE1_DARK = { "images/ui/atbook_wiki/partui/food/yj_hxyj_1.xml", "yj_hxyj_1.tex" },
    FOOD_TYPE2 = { "images/ui/atbook_wiki/partui/food/yj_hxll_2.xml", "yj_hxll_2.tex" },
    FOOD_TYPE2_DARK = { "images/ui/atbook_wiki/partui/food/yj_hxll_1.xml", "yj_hxll_1.tex" },

    -- SKIN
    SKIN_CDK = { "images/ui/atbook_wiki/skin/icon_duihuan.xml", "icon_duihuan.tex" },
    SKIN_TITLE = { "images/ui/atbook_wiki/skin/icon_pi_logo.xml", "icon_pi_logo.tex" },
    SKIN_SCROLLBG = { "images/ui/atbook_wiki/skin/icon_pi_gz_di.xml", "icon_pi_gz_di.tex" },
    SKIN_SLOT = { "images/ui/atbook_wiki/skin/icon_pi_gz.xml", "icon_pi_gz.tex" },
    SKIN_BG = { "images/ui/atbook_wiki/skin/icon_zs_k.xml", "icon_zs_k.tex" },
    SKIN_CAT = { "images/ui/atbook_wiki/skin/icon_xzk_xz.xml", "icon_xzk_xz.tex" },
    SKIN_TYPE_BG = { "images/ui/atbook_wiki/skin/icon_xzk_di.xml", "icon_xzk_di.tex" },
    SKIN_TYPE_1 = { "images/ui/atbook_wiki/skin/zi_jz_2.xml", "zi_jz_2.tex" },
    SKIN_TYPE_1_DARK = { "images/ui/atbook_wiki/skin/zi_jz_1.xml", "zi_jz_1.tex" },
    SKIN_TYPE_2 = { "images/ui/atbook_wiki/skin/zi_st_2.xml", "zi_st_2.tex" },
    SKIN_TYPE_2_DARK = { "images/ui/atbook_wiki/skin/zi_st_1.xml", "zi_st_1.tex" },
    SKIN_TYPE_3 = { "images/ui/atbook_wiki/skin/zs_2.xml", "zs_2.tex" },
    SKIN_TYPE_3_DARK = { "images/ui/atbook_wiki/skin/zs_1.xml", "zs_1.tex" },
    SKIN_TYPE_4 = { "images/ui/atbook_wiki/skin/zi_zb_2.xml", "zi_zb_2.tex" },
    SKIN_TYPE_4_DARK = { "images/ui/atbook_wiki/skin/zi_zb_1.xml", "zi_zb_1.tex" },
    SKIN_TYPE_5 = { "images/ui/atbook_wiki/skin/zi_dj_2.xml", "zi_dj_2.tex" },
    SKIN_TYPE_5_DARK = { "images/ui/atbook_wiki/skin/zi_dj_1.xml", "zi_dj_1.tex" },
    SKIN_TYPE_6 = { "images/ui/atbook_wiki/skin/zi_qt_2.xml", "zi_qt_2.tex" },
    SKIN_TYPE_6_DARK = { "images/ui/atbook_wiki/skin/zi_qt_1.xml", "zi_qt_1.tex" },
    SKIN_LEFT = { "images/ui/atbook_wiki/skin/icon_xz_l.xml", "icon_xz_l.tex" },
    SKIN_RIGHT = { "images/ui/atbook_wiki/skin/icon_xz_r.xml", "icon_xz_r.tex" },

    -- NOTICE
    NOTICE_TOP = { "images/ui/atbook_wiki/notice/icon_fjx_1.xml", "icon_fjx_1.tex" },
    NOTICE_BOTTOM = { "images/ui/atbook_wiki/notice/icon_fjx_2.xml", "icon_fjx_2.tex" },
    NOTICE_BG = { "images/ui/atbook_wiki/notice/icon_ggl_k_1.xml", "icon_ggl_k_1.tex" },
    NOTICE_RIGHT = { "images/ui/atbook_wiki/notice/icon_ggl_k_2.xml", "icon_ggl_k_2.tex" },
}

return IMAGES