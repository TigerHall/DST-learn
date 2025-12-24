------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function GetHUDLoation()
        local data = TBAT.ClientSideData:PlayerGet("wiki_button_location")
        if data == nil then
            return 0.5,0.5
        else
            return data.x,data.y
        end
    end
    local function SetHUDLoation(x,y)
        TBAT.ClientSideData:PlayerSet("wiki_button_location",{x = x,y = y})
    end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function create_button()
        ------------------------------------------------------------------------------------------
        ---
            local front_root = ThePlayer.HUD.controls
        ------------------------------------------------------------------------------------------
        ---
            local root = front_root:AddChild(Widget())
            root:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            root:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            root:SetPosition(1000,500)
            root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
        ------------------------------------------------------------------------------------------
        -------- 启动坐标跟随缩放循环任务，缩放的时候去到指定位置。官方好像没预留这类API，或者暂时找不到方法
            function root:LocationScaleFix()
                if self.x_percent and not self.__mouse_holding  then
                    local scrnw, scrnh = TheSim:GetScreenSize()
                    if self.____last_scrnh ~= scrnh then
                        local tarX = self.x_percent * scrnw
                        local tarY = self.y_percent * scrnh
                        self:SetPosition(tarX,tarY)
                    end
                    self.____last_scrnh = scrnh
                end
            end
            
            root.x_percent,root.y_percent = GetHUDLoation()
            root:LocationScaleFix()    
            root.inst:DoPeriodicTask(2,function()
                root:LocationScaleFix()
            end)
        ------------------------------------------------------------------------------------------
        ---- 鼠标拖动
            local old_OnMouseButton = root.OnMouseButton
            root.OnMouseButton = function(self,button, down, x, y)
                if down and button == MOUSEBUTTON_RIGHT then

                    if not root.__mouse_holding  then
                        root.__mouse_holding = true      --- 上锁
                            --------- 添加鼠标移动监听任务
                            root.___follow_mouse_event = TheInput:AddMoveHandler(function(x, y)  
                                root:SetPosition(x,y,0)
                            end)
                            --------- 添加鼠标按钮监听
                            root.___mouse_button_up_event = TheInput:AddMouseButtonHandler(function(button, down, x, y) 
                                if button == MOUSEBUTTON_RIGHT and down == false then    ---- 左键被抬起来了
                                    root.___mouse_button_up_event:Remove()       ---- 清掉监听
                                    root.___mouse_button_up_event = nil

                                    root.___follow_mouse_event:Remove()          ---- 清掉监听
                                    root.___follow_mouse_event = nil

                                    root:SetPosition(x,y,0)                      ---- 设置坐标
                                    root.__mouse_holding = false                 ---- 解锁

                                    local scrnw, scrnh = TheSim:GetScreenSize()
                                    root.x_percent = x/scrnw
                                    root.y_percent = y/scrnh

                                    -- owner:PushEvent("loramia_wellness_bars.save_cmd",{    --- 发送储存坐标。
                                    --     pt = {x_percent = root.x_percent,y_percent = root.y_percent},
                                    -- })
                                    SetHUDLoation(root.x_percent,root.y_percent)

                                end
                            end)
                    end

                end
                return old_OnMouseButton(self,button, down, x, y)
            end
        ------------------------------------------------------------------------------------------
        ---
            local box = root:AddChild(Widget())
            local scale = 0.3
            box:SetScale(scale,scale)
        ------------------------------------------------------------------------------------------
        ---
            local button = box:AddChild(ImageButton(
                "images/widgets/tbat_wiki_button.xml",
                "tbat_wiki_button.tex",
                "tbat_wiki_button.tex",
                "tbat_wiki_button.tex",
                "tbat_wiki_button.tex"
            ))
            button:SetPosition(0,0)
            button:SetOnClick(function()
                if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls and ThePlayer.HUD.controls.atbook_wikiwidget then
                    ThePlayer.HUD.controls.atbook_wikiwidget:Show()
                end
            end)
        ------------------------------------------------------------------------------------------
        ---
            root:MoveToBack()
            return root
        ------------------------------------------------------------------------------------------
    end
    -- local function create_wiki_button(inst)
        
    -- end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    AddPlayerPostInit(function(inst)
        if not TBAT.DEBUGGING then
            return
        end
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("tbat_event.wiki_created",create_button)
        end
    end)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------