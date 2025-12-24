-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

        local skin_data = {
            skin_name = "tbat_eq_universal_baton_3",
            -- is_pack = true,
        }
        -- local skin_data = {
        --     skin_name = "tbat_eq_universal_baton_pack",
        --     is_pack = true,
        --     list = {
        --         "tbat_eq_universal_baton_2",
        --         "tbat_eq_universal_baton_3",
        --     }
        -- }
        create_skin_ui_announce(skin_data)

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 界面控件
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function create_skin_ui_announce(annouce_cmd_data)
        ---------------------------------------------------------
        -- print(json.encode(annouce_cmd_data))
        ---------------------------------------------------------
        --- 前置根节点
            local front_root = ThePlayer.HUD:AddChild(Screen())
            front_root:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            front_root:SetVAnchor(0) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            front_root:SetPosition(0,0)
            front_root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
            TheFrontEnd:PushScreen(front_root)
        ---------------------------------------------------------
        --- 点击事件
            local OLD_OnMouseButton = front_root.OnMouseButton
            front_root.OnMouseButton = function(self,button,down,x,y)
                if not down then
                    front_root.inst:PushEvent("click")
                end
                return OLD_OnMouseButton(self,button,down,x,y)
            end
            local key_handler = TheInput:AddKeyHandler(function(key,down)
                if not down then
                    front_root.inst:PushEvent("click")
                end
            end)
            front_root.inst:ListenForEvent("onremove",function()
                key_handler:Remove()
            end)
        ---------------------------------------------------------
        --- 数据转换
            -- skin_name = skin_name,   -- 单个皮肤名字或者包体名字
            -- is_pack = true,
            -- list = cdkey_unlock_result,  -- index 为skin_name
            local cmd_display_data = {}
            if not annouce_cmd_data.is_pack then
                local temp_skin_data = TBAT.SKIN.SKINS_DATA_SKINS[annouce_cmd_data.skin_name]
                if not temp_skin_data.unlock_announce_skip then
                    cmd_display_data[1] = {
                        skin_name = annouce_cmd_data.skin_name,
                        skin_data = TBAT.SKIN.SKINS_DATA_SKINS[annouce_cmd_data.skin_name]
                    }
                end
            elseif TBAT.SKIN.SKIN_PACK:IsPack(annouce_cmd_data.skin_name) then
                local list = TBAT.SKIN.SKIN_PACK:GetPacked(annouce_cmd_data.skin_name)
                for k, skin_name in pairs(list) do
                    local temp_skin_data = TBAT.SKIN.SKINS_DATA_SKINS[skin_name]
                    if not temp_skin_data.unlock_announce_skip then
                        table.insert(cmd_display_data,{
                            skin_name = skin_name,
                            skin_data = TBAT.SKIN.SKINS_DATA_SKINS[skin_name]
                        })
                    end
                end
            end
        ---------------------------------------------------------
        --- 点击事件监听
            -- local clicked_num = 0
            -- local max_click_num = 3 + #cmd_display_data
            -- front_root.inst:ListenForEvent("click",function()
            --     clicked_num = clicked_num + 1
            --     if clicked_num >= max_click_num then
            --         front_root.inst:PushEvent("close")
            --     end
            -- end)
            front_root.inst:ListenForEvent("close",function()
                TheFrontEnd:PopScreen(front_root)
                front_root:Kill()
            end)
        ---------------------------------------------------------
        --- root
            local root = front_root:AddChild(Widget())
            root:SetScale(1,1,1)
        ---------------------------------------------------------
        --- 创建盒子
            local function create_box(cmd_display_data)
                -------------------------------------------------
                --- 根节点
                    local box = root:AddChild(Widget())
                -------------------------------------------------
                --- 遮挡背景
                    local bg = box:AddChild(Image("images/scrapbook.xml","scrap_square.tex"))
                    bg:Hide()
                -------------------------------------------------
                --- 文字背景
                    -- local display_text_bg = box:AddChild(Image("images/tradescreen.xml","textbubble.tex"))
                    -- display_text_bg:SetPosition(0,-215,0)
                    -- local display_text_bg_scale = 0.4
                    -- display_text_bg:SetScale(display_text_bg_scale*2.5,display_text_bg_scale,display_text_bg_scale)
                    -- display_text_bg:Hide()
                    local display_text_bg = box:AddChild(UIAnim())
                    local display_text_bg_scale = 0.4
                    display_text_bg:GetAnimState():SetBank("tbat_skin_unlock_info_bg")
                    display_text_bg:GetAnimState():SetBuild("tbat_skin_unlock_info_bg")
                    display_text_bg:GetAnimState():PlayAnimation("idle")
                    display_text_bg:SetScale(display_text_bg_scale,display_text_bg_scale,display_text_bg_scale)
                    display_text_bg:SetPosition(0,-215,0)
                    display_text_bg:Hide()
                -------------------------------------------------
                --- 书本特效
                    local book_anim = box:AddChild(UIAnim())
                    local book_anim_state = book_anim:GetAnimState()
                    book_anim_state:SetBank("atbook_wiki")
                    book_anim_state:SetBuild("atbook_wiki")
                    book_anim_state:PlayAnimation("idle",true)
                    book_anim_state:HideSymbol("shadow")
                    book_anim:SetScale(0.7,0.7)
                    book_anim:SetPosition(0,-200,0)
                -------------------------------------------------
                --- 圈圈特效
                    local slot_bg = box:AddChild(UIAnim())
                    -- anim_bg.inst.entity:AddFollower()
                    -- anim_bg.inst.Follower:FollowSymbol(book_anim.inst.GUID, "mao", nil, nil, nil, true, nil, 3) 
                    local slot_anim_state = slot_bg:GetAnimState()
                    slot_anim_state:SetBank("gift_popup")
                    slot_anim_state:SetBuild("skingift_popup")
                    slot_anim_state:PlayAnimation("skin_loop",true)
                    local need2hide = {"BG","dropshadow","bow","box","banner","ribbon","SWAP_ICON"}
                    for k, v in pairs(need2hide) do
                        slot_anim_state:HideSymbol(v)
                    end
                    slot_bg:Hide()
                    slot_bg:SetScale(1,1)
                    slot_bg:SetPosition(0,100,0)
                -------------------------------------------------
                --- 文字
                    local display_text = box:AddChild(Text(CODEFONT,26,"XXXXXX",{ 255/255 , 255/255 ,255/255 , 1}))
                    display_text:SetPosition(0,-195,0)
                    display_text:Hide()
                    local display_skin_text = box:AddChild(Text(CODEFONT,40,"XXXXXX",{ 255/255 , 255/255 ,255/255 , 1}))
                    display_skin_text:SetPosition(0,-230,0)
                    display_skin_text:Hide()
                    function display_text:ShowSkinName(prefab,skin_name,skin_display_name)
                        local name = tostring(TBAT:GetString2(prefab,"name"))
                        -- local ret = name .. "\n" .. tostring(skin_name)
                        display_text:SetString(name)
                        display_text:Show()
                        display_skin_text:Show()
                        display_skin_text:SetString(skin_display_name)
                        local skin_name_color = GetColorForItem(skin_name)
                        display_skin_text:SetColour(unpack(skin_name_color))
                    end
                -------------------------------------------------
                --- 切换
                    local current_index = 0
                    local block_click = false
                    box.inst:ListenForEvent("click",function()
                        if block_click then
                            return
                        end
                        if current_index == 0 then
                            book_anim_state:PlayAnimation("open",false)
                            block_click = true
                            book_anim.inst:ListenForEvent("animover",function()
                                book_anim_state:PlayAnimation("idle_open",true)
                                slot_bg:Show()
                                book_anim.inst:RemoveAllEventCallbacks()
                                current_index = current_index + 1
                                box.inst:PushEvent("display_info_by_index",current_index)
                                block_click = false
                            end)
                            book_anim:SetPosition(0,-200,0)
                        else
                            current_index = current_index + 1                                
                            box.inst:PushEvent("display_info_by_index",current_index)
                        end
                    end,front_root.inst)
                -------------------------------------------------
                --- 显示信息
                    box.inst:ListenForEvent("display_info_by_index",function(_,index)
                        -----------------------------------------------------
                        --- 前置检查及退出
                            if box._slot then
                                box._slot:Kill()                                    
                            end
                            local single_cmd = cmd_display_data[index]
                            if single_cmd == nil then
                                -- front_root.inst:PushEvent("close")
                                book_anim_state:PlayAnimation("close",false)
                                book_anim.inst:ListenForEvent("animover",function()
                                    front_root.inst:PushEvent("close")
                                end)
                                slot_bg:Hide()
                                display_text:Hide()
                                display_skin_text:Hide()
                                bg:Hide()
                                display_text_bg:Hide()
                                front_root:SetClickable(false)
                                return
                            end
                        -----------------------------------------------------
                            local single_skin_data = single_cmd.skin_data
                            -- print("index",index,single_skin_data and single_skin_data.prefab_name)
                            box._slot = box:AddChild(Widget())
                            local slot = box._slot
                        -----------------------------------------------------
                        ---

                        -----------------------------------------------------
                        --- 显示名称
                            local prefab = single_skin_data.prefab_name
                            local skin_display_name = single_skin_data.name
                            display_text:ShowSkinName(prefab,single_cmd.skin_name,skin_display_name)
                            display_text_bg:Show()
                        -----------------------------------------------------
                        --- 制作栏图标
                            local image_atlas = single_skin_data.atlas
                            local image_tex = single_skin_data.image .. ".tex"
                            local icon_64 = slot:AddChild(Image(image_atlas,image_tex))
                            local icon_64_scale = 2
                            icon_64:SetScale(icon_64_scale,icon_64_scale,icon_64_scale)
                            icon_64:SetPosition(0,100,0)
                        -----------------------------------------------------
                        --- 如果有 unlock_announce_data ,则覆盖
                            local unlock_announce_data = single_skin_data.unlock_announce_data
                            if unlock_announce_data then
                                icon_64:Hide()
                                local icon_anim = slot:AddChild(UIAnim())
                                local scale = unlock_announce_data.scale
                                icon_anim:SetScale(scale,scale,scale)
                                local pt = unlock_announce_data.offset or Vector3(0,0,0)
                                icon_anim:SetPosition(pt.x,pt.y,pt.z)
                                icon_anim:GetAnimState():SetBank(unlock_announce_data.bank)
                                icon_anim:GetAnimState():SetBuild(unlock_announce_data.build)
                                icon_anim:GetAnimState():PlayAnimation(unlock_announce_data.anim,true)
                                if unlock_announce_data.fn then
                                    unlock_announce_data.fn(icon_anim,slot)
                                end
                            end
                        -----------------------------------------------------
                        --- 切换特效
                            local fx = slot:AddChild(UIAnim())
                            local fx_state = fx:GetAnimState()
                            fx_state:SetBank("die_fx")
                            fx_state:SetBuild("die")
                            fx_state:PlayAnimation("small",false)
                            local fx_color = { 255/255, 255/255, 100/255, 180/255 }
                            fx_state:SetMultColour(unpack(fx_color))
                            TheFrontEnd:GetSound():PlaySound("dontstarve/common/deathpoof")
                        -----------------------------------------------------
                    end)
                -------------------------------------------------
            end
        ---------------------------------------------------------
        --- 创建盒子
            create_box(cmd_display_data)
        ---------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPlayerPostInit(function(inst)
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(1,function()
            if inst == ThePlayer and inst.HUD then
                inst:ListenForEvent("tbat_event.skin_unlock_announce",function(_,data_str_zipped)
                    local data = {}
                    if type(data_str_zipped) == "string" then
                        data = json.decode(TBAT.FNS:UnzipJsonStr(data_str_zipped))
                    else
                        data = data_str_zipped
                    end
                    if TBAT.create_skin_ui_announce and TBAT.DEBUGGING then
                        TBAT.create_skin_ui_announce(data)
                        return
                    end
                    create_skin_ui_announce(data)
                end)
            end
        end)
    end
end)
