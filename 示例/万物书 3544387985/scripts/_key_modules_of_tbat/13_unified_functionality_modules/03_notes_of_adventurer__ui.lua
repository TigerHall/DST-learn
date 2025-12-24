--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    这里集中冒险家笔记的一些东西。方便 其他 语言 hook  和调试。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local notes_data = {
        --------------------------------------------------------------------------------------------------------------------------------------------------------
        --- 示例
            -- [1] = {
            --     atlas = "",
            --     image = "",

            --     build = "",
            --     bank = "",
            --     anim = "",

            --     scale = 1,
            --     x = 0,
            --     y = 0,
            -- }
        --------------------------------------------------------------------------------------------------------------------------------------------------------
        ---
            [1] = {
                build = "tbat_ui_notes_of_adventurer_text_1",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [2] = {
                build = "tbat_ui_notes_of_adventurer_text_2",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [3] = {
                build = "tbat_ui_notes_of_adventurer_text_3",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [4] = {
                build = "tbat_ui_notes_of_adventurer_text_4",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [5] = {
                build = "tbat_ui_notes_of_adventurer_text_5",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [6] = {
                build = "tbat_ui_notes_of_adventurer_text_6",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [7] = {
                build = "tbat_ui_notes_of_adventurer_text_7",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,                
            },
            [8] = {
                build = "tbat_ui_notes_of_adventurer_text_8",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [9] = {
                build = "tbat_ui_notes_of_adventurer_text_9",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [10] = {
                build = "tbat_ui_notes_of_adventurer_text_10",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [11] = {
                build = "tbat_ui_notes_of_adventurer_text_11",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [12] = {
                build = "tbat_ui_notes_of_adventurer_text_12",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [13] = {
                build = "tbat_ui_notes_of_adventurer_text_13",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [14] = {
                build = "tbat_ui_notes_of_adventurer_text_14",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [15] = {
                build = "tbat_ui_notes_of_adventurer_text_15",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [16] = {
                build = "tbat_ui_notes_of_adventurer_text_16",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [17] = {
                build = "tbat_ui_notes_of_adventurer_text_17",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [18] = {
                build = "tbat_ui_notes_of_adventurer_text_18",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [19] = {
                build = "tbat_ui_notes_of_adventurer_text_19",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [20] = {
                build = "tbat_ui_notes_of_adventurer_text_20",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [21] = {
                build = "tbat_ui_notes_of_adventurer_text_21",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [22] = {
                build = "tbat_ui_notes_of_adventurer_text_22",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
            [23] = {
                build = "tbat_ui_notes_of_adventurer_text_23",bank = "tbat_ui_notes_of_adventurer",
                anim = "idle",scale = 1,x = 0,y = 0,
            },
        --------------------------------------------------------------------------------------------------------------------------------------------------------
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 注册贴图
    if Assets == nil then
        Assets = {}
    end
    for index, temp_data in pairs(notes_data) do
        -- Asset("IMAGE", "images/widgets/tbat_ui_notes_of_adventurer.tex"),
        -- Asset("ATLAS", "images/widgets/tbat_ui_notes_of_adventurer.xml"),
        -- Asset("ANIM", "anim/tbat_eq_world_skipper.zip"),
        if temp_data.image and temp_data.atlas then
            table.insert(Assets, Asset("IMAGE", temp_data.image) )
            table.insert(Assets, Asset("ATLAS", temp_data.atlas) )
        end
        if temp_data.build and temp_data.bank then
            table.insert(Assets, Asset("ANIM", "anim/"..temp_data.build..".zip") )
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 笔记
    function TBAT.MODULES:GetNotesOfAdventurerUI(index)
        if notes_data[index] then
            return notes_data[index]
        end
        return nil
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------