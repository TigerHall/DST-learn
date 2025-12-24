local M = {}

M.keys = {
    ["1"] = "F3dHus5U01yPHK3g5PzKr1cXcnd97e5o",
    ["2"] = "hYBiIjohyDl1B5fu7VrS77Ul6Kzq1gaG",
    ["3"] = "1jf9DBGSu5xsCdzmZPNT9DhTuEs8fKHn",
    ["4"] = "ENKCDfxnCVSlMftvSU4YLIhHjrqluAsm",
    ["5"] = "ptkJsz2JOYn6180Ro9BVsR4B0hcffiSq",
    ["6"] = "keSiKkZF45iOfGHiQ3Y8kxHmV15laVUj",
    ["7"] = "DAWRXWBPPD7wCyVtxhz5xxP6XiyVAPoq",
    ["8"] = "fWm9HblPYl2u6Yi7TBD7HfnqAeH7eQxD",
    ["9"] = "N3pArHbzKevd22yCzmzuQLx3f9DWx2gx"
}

M.limit = {
    "1",
    "7",
    "8",
    "9",
    "10",
    "11",
    "12",
    "13",
    "14",
    "15",
    "16",
    "61",
}

M.skin = {
    ["1"] = "tbat_eq_fantasy_tool_freya_s_wand",
    ["2"] = "tbat_eq_fantasy_tool_cheese_fork",
    ["3"] = "tbat_eq_universal_baton_2",
    ["4"] = "tbat_eq_universal_baton_3",
    ["5"] = "tbat_eq_universal_baton_pack",
    ["6"] = "tbat_baton_rabbit_ice_cream",
    ["7"] = "tbat_baton_bunny_scepter",
    ["8"] = "tbat_baton_jade_sword_immortal",
    ["9"] = "tbat_building_kitty_wooden_sign_9",
    ["10"] = "tbat_building_kitty_wooden_sign_10",
    ["11"] = "tbat_building_kitty_wooden_sign_11",
    ["12"] = "tbat_building_kitty_wooden_sign_12",
    ["13"] = "tbat_building_kitty_wooden_sign_13",
    ["14"] = "tbat_building_cloud_wooden_sign_7",
    ["15"] = "tbat_building_bunny_wooden_sign_6",
    ["16"] = "tbat_building_bunny_wooden_sign_7",
    ["17"] = "tbat_wreath_strawberry_bunny",
    ["18"] = "tbat_rayfish_hat_sweet_cocoa",
    ["19"] = "cb_rabbit_mini_icecream",
    ["20"] = "cbr_mini_labubu_colourful_feather",
    ["21"] = "cbr_mini_labubu_skyblue",
    ["22"] = "cbr_mini_labubu_pink_strawberry",
    ["23"] = "cbr_mini_labubu_flower_bud",
    ["24"] = "cbr_mini_labubu_orange",
    ["25"] = "cbr_mini_labubu_white_cherry",
    ["26"] = "cbr_mini_labubu_lemon_yellow",
    ["27"] = "cbr_mini_labubu_dream_blue",
    ["28"] = "cbr_mini_labubu_moon_white",
    ["29"] = "cbr_mini_labubu_purple_wind",
    ["30"] = "tbat_pc_strawberry_jam",
    ["31"] = "tbat_pc_pudding",
    ["32"] = "tbat_carpet_cream_puff_bread",
    ["33"] = "tbat_carpet_taro_bread",
    ["34"] = "tbat_carpet_taro_bread_with_bell",
    ["35"] = "tbat_carpet_hello_kitty",
    ["36"] = "carpet_claw_dreamweave_rug",
    ["37"] = "carpet_claw_petglyph_platform",
    ["38"] = "tbat_pb_bush_dreambloom",
    ["39"] = "tbat_pb_bush_mistbloom",
    ["40"] = "tbat_pb_bush_mosswhisper",
    ["41"] = "tbat_pb_bush_warm_rose",
    ["42"] = "tbat_pb_bush_spark_rose",
    ["43"] = "tbat_pb_bush_luminmist_rose",
    ["44"] = "tbat_pb_bush_frostberry_rose",
    ["45"] = "tbat_pb_bush_stellar_rose",
    ["46"] = "tbat_pot_verdant_grove",
    ["47"] = "tbat_pot_bunny_cart",
    ["48"] = "tbat_pot_dreambloom_vase",
    ["49"] = "tbat_pot_lavendream",
    ["50"] = "tbat_pot_cloudlamb_vase",
    ["51"] = "tbat_lamp_starwish",
    ["52"] = "tbat_lamp_moon_starwish",
    ["53"] = "tbat_lamp_moon_sleeping_kitty",
    ["54"] = "tbat_wood_sofa_magic_broom",
    ["55"] = "tbat_wood_sofa_sunbloom",
    ["56"] = "tbat_wood_sofa_lemon_cookie",
    ["57"] = "tbat_sunbloom_side_table",
    ["58"] = "tbat_whisper_tome_spellwisp_desk",
    ["59"] = "tbat_whisper_tome_chirpwell",
    ["60"] = "tbat_whisper_tome_purr_oven",
    ["61"] = "tbat_whisper_tome_swirl_vanity",
    ["62"] = "tbat_mpc_tree_ring_counter",
    ["63"] = "tbat_mpc_ferris_wheel",
    ["64"] = "tbat_mpc_gift_display_rack",
    ["65"] = "tbat_mpc_accordion",
    ["66"] = "tbat_mpc_dreampkin_hut",
    ["67"] = "tbat_mpc_grid_cabinet",
    ["68"] = "tbat_mpc_puffcap_stand",
    ["69"] = "tbat_pbt_sweetwhim_stand",
    ["70"] = "tbat_pbh_abysshell_stand",
    ["71"] = "tbat_wall_strawberry_cream_cake",
    ["72"] = "tbat_wall_coral_reef",
    ["73"] = "tbat_hamster_gumball_machine",
}

M.vipfn = function(info)
    for uid, skincode in pairs(M.skin) do
        if not table.contains(M.limit, uid) and not table.contains(info, skincode) then
            table.insert(info, skincode)
        end
    end
end

M.simplefn = function(info, num)
    for uid, skincode in pairs(M.skin) do
        local newuid = string.sub(uid, 0, string.len(uid) - 1)
        if not table.contains(info, skincode) and newuid == num then
            table.insert(info, skincode)
        end
    end
end

local function hexToIndexArray(hexString)
    local hexToBinMap = {
        ["0"] = "0000",
        ["1"] = "0001",
        ["2"] = "0010",
        ["3"] = "0011",
        ["4"] = "0100",
        ["5"] = "0101",
        ["6"] = "0110",
        ["7"] = "0111",
        ["8"] = "1000",
        ["9"] = "1001",
        ["a"] = "1010",
        ["b"] = "1011",
        ["c"] = "1100",
        ["d"] = "1101",
        ["e"] = "1110",
        ["f"] = "1111",
        ["A"] = "1010",
        ["B"] = "1011",
        ["C"] = "1100",
        ["D"] = "1101",
        ["E"] = "1110",
        ["F"] = "1111"
    }

    local binaryString = ""
    for i = 1, #hexString do
        local char = hexString:sub(i, i)
        local binary = hexToBinMap[char]
        if binary then
            binaryString = binaryString .. binary
        else
            return {}
        end
    end

    local startPos = binaryString:find("1")
    binaryString = binaryString:sub(startPos + 1)

    if binaryString then
        local result = {}
        for i = 1, #binaryString do
            table.insert(result, binaryString:sub(i, i))
        end
        return result
    else
        return {}
    end
end

M.hexfn = function(info, hexValue)
    local result = hexToIndexArray(hexValue) or {}
    for index, flag in ipairs(result) do
        if flag == '1' and M.skin[tostring(index)] then
            table.insert(info, M.skin[tostring(index)])
        end
    end
end

return M
