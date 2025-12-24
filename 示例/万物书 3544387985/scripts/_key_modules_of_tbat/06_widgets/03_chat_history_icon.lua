------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    修改 聊天记录 模块，为自定义动态图标 做准备

    TBAT.FNS:AddChatIconData(name,{
        atlas = "images/profileflair.xml",
        image = "test.tex",                     --- 128x128 pix
        scale = nil,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
        fx = {
            bank = "fx",
            build = "fx",
            anim = "idle",
            color = {255/255,255/255,255/255},
            -- scale = 1,
            -- shader = "shaders/anim.ksh",
            time = 3,   -- 动画时间。用来随机时间轴。
        },    
    })


    【笔记】
        icondata : "profileflair_treasurechest_monster" ,"default"  在文件 misc_items.lua 里，部分需要玩家解锁。
        icon 的尺寸为90x90像素，具体参数前往 profileflair.tex 和 profileflair.xml 查看。如果是自己制作，推荐使用 autocompiler.exe 自动编译 png 成 tex + xml (png放文件夹里会自动进行)
        ChatHistory:AddToHistory({flag = "fwd_in_pdt" , ChatType = ChatTypes.Message , m_colour = {0,0,255} , s_colour = {255,255,0}},nil,nil,"NPC","656565",{0,255,0})
        m_colour 文本颜色，  s_colour 名字颜色
        colour 参数 和官方的有出入，  需要除以255才能成任意色。
        ChatType 在 chatline.lua 里有执行逻辑

]]--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local all_icon_data = {}

function TBAT.FNS:AddChatIconData(name,data)
    all_icon_data[name] = data
end
local function GetIconData(name)
    return all_icon_data[name]
end
function TBAT.FNS:GetChatIconData(name)
    return GetIconData(name)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    -- TBAT.FNS:AddChatIconData("rod_main",{
    --     atlas = "images/widgets/rod_hud_craftingmenu_custom_detail_widget.xml",
    --     image = "main.tex",                     --- 128x128 pix
    --     scale = 0.2,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
    -- })
    -- TBAT.FNS:AddChatIconData("rod_building",{
    --     atlas = "images/widgets/rod_hud_craftingmenu_custom_detail_widget.xml",
    --     image = "building.tex",                     --- 128x128 pix
    --     scale = 0.2,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
    -- })
    -- TBAT.FNS:AddChatIconData("rod_spell",{
    --     atlas = "images/widgets/rod_hud_craftingmenu_custom_detail_widget.xml",
    --     image = "spell.tex",                     --- 128x128 pix
    --     scale = 0.2,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
    -- })
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 修改操作成无背景图标
---- 参考 TEMPLATES.ChatFlairBadge 修改参数和挂载节点。

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
-- TUNING["Forward_In_Predicament.Chat_Message_Icons"] = TUNING["Forward_In_Predicament.Chat_Message_Icons"] or {} --- 在这初始化一下，避免某些潜在的崩溃。
AddClassPostConstruct("widgets/redux/chatline",function(self)  

    self.SetChatData__tbat_old = self.SetChatData
    self.SetChatData = function(self,_type, alpha, message, m_colour, sender, s_colour, icondata,...)
        --------------------------------------------------------------------------------------------------------------------------
        ---
            -- print("+++",_type, alpha, message, m_colour, sender, s_colour, icondata,...)
            if GetIconData(icondata) then
                _type = ChatTypes.Message
            end
        --------------------------------------------------------------------------------------------------------------------------
        --- 旧的API
            if self.flair then
                if self.flair.SetFlair__tbat_old == nil then
                    self.flair.SetFlair__tbat_old = self.flair.SetFlair

                end
                self.flair.SetFlair = function(self,icon_tex_name,...)
                    if GetIconData(icon_tex_name) then
                        return
                    else
                        return self.SetFlair__tbat_old(self,icon_tex_name,...)
                    end
                end                    
            end
        --------------------------------------------------------------------------------------------------------------------------
        --- 
            -- if TBAT.chat_line_debug_front_fn then
            --    TBAT.chat_line_debug_front_fn(self,_type, alpha, message, m_colour, sender, s_colour, icondata,...)
            -- end

            self:SetChatData__tbat_old(_type, alpha, message, m_colour, sender, s_colour, icondata,...)

            -- if TBAT.chat_line_debug_fn then
            --     TBAT.chat_line_debug_fn(self, _type, alpha, message, m_colour, sender, s_colour, icondata,...)
            --     return
            -- end
        --------------------------------------------------------------------------------------------------------------------------
        --- 
        --------------------------------------------------------------------------------------------------------------------------
        -- 清除旧栏目内的内容。
            if icondata ~= nil and GetIconData(icondata) == nil then
                if self.___tbat_image then
                    self.___tbat_image:Kill()
                    self.___tbat_image = nil
                end
                if self.flair.flair_img then
                    self.flair.flair_img:Show()
                end
                if self.flair.bg then
                    self.flair.bg:Show()
                end
                return
            end
        --------------------------------------------------------------------------------------------------------------------------
        -- 隐藏原有的 图标和背景，添加新的图标和FX图层。
            local icondata = GetIconData(icondata)
            if type(icondata) == "table" then
                            local atlas = icondata.atlas
                            local image = icondata.image
                            local image_scale = icondata.scale
                            local fx = icondata.fx
                        
                            if self.flair.flair_img then
                                self.flair.flair_img:Hide()
                            end
                            if self.flair.bg then
                                self.flair.bg:Hide()
                            end
                            if self.___tbat_image then
                                self.___tbat_image:Kill()
                            end

                            self.___tbat_image = self.root:AddChild(Image())
                            self.___tbat_image:SetPosition(-315, 0)
                            self.___tbat_image:SetScale(image_scale or 0.25)
                            self.___tbat_image:SetTexture(atlas,image)
                            self.___tbat_image:SetClickable(false)

                            self.flair.___tbat_image = self.___tbat_image   --- 方便 SetAlpha 操作渐变

                            if type(fx) == "table" and fx.bank and fx.build and fx.anim then
                                    self.__tbat_fx = self.__tbat_fx and self.__tbat_fx.inst:IsValid() and self.__tbat_fx or self.___tbat_image:AddChild(UIAnim())
                                    self.__tbat_fx:GetAnimState():SetBank(fx.bank)
                                    self.__tbat_fx:GetAnimState():SetBuild(fx.build)
                                    self.__tbat_fx:GetAnimState():PlayAnimation(fx.anim,true)
                                    local color = fx.color or fx.colour
                                    if color then
                                        local r = color[1]
                                        local g = color[2]
                                        local b = color[3]
                                        local a = color[4] or 1
                                        self.__tbat_fx:GetAnimState():SetMultColour(r,g,b,a)
                                    end
                                    if type(fx.scale) == "number" then
                                        self.__tbat_fx:SetScale(fx.scale)
                                    end
                                    if type(fx.shader) == "string" then
                                        self.__tbat_fx:GetAnimState():SetBloomEffectHandle(fx.shader)
                                    end
                                    if type(fx.time) == "number" then
                                        self.__tbat_fx:GetAnimState():SetTime(fx.time*math.random())
                                    end
                            elseif fx == nil and self.__tbat_fx then
                                    self.__tbat_fx:Kill()
                            end

                            ------------- 让图标和动画特效也跟着 渐隐,逻辑照抄。
                            if self.flair.SetAlpha___tbat_old == nil then
                                self.flair.SetAlpha___tbat_old = self.flair.SetAlpha
                                self.flair.SetAlpha = function(self,a)
                                    self:SetAlpha___tbat_old(a)
                                    if self.___tbat_image and a > 0.01 then
                                        self.___tbat_image:Show()
                                        self.___tbat_image:SetTint(1,1,1,a)      
                                    else
                                        self.___tbat_image:Hide()                              
                                    end
                                end

                            end
            
            
            end
        --------------------------------------------------------------------------------------------------------------------------
    end


end)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

