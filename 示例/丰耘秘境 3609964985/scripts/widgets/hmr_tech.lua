local Screen = require "widgets/screen"
local Subscreener = require "screens/redux/subscreener"
local TextButton = require "widgets/textbutton"
local ImageButton = require "widgets/imagebutton"
local Menu = require "widgets/menu"
local Grid = require "widgets/grid"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local ScrollableList = require "widgets/scrollablelist"
local PopupDialogScreen = require "screens/redux/popupdialog"
local OnlineStatus = require "widgets/onlinestatus"
local TEMPLATES = require "widgets/redux/templates"
local TrueScrollArea = require "widgets/truescrollarea"
local UIAnim = require "widgets/uianim"

local HMR_TECH_LIST = require("hmrmain/hmr_lists").HMR_TECH_LIST

local OPEN_BUTTON_POS_OFFSET = {-550 + 70, -630 + 50}

local SCREEN_OFFSET = .22 * RESOLUTION_X

local ATLAS = "images/skilltree.xml"  -- 技能树图集
local IMAGE_SELECTED = "selected.tex"  -- 选中状态图像
local IMAGE_SELECTED_OVER = "selected_over.tex"  -- 选中状态悬停图像

local IMAGE_UNSELECTED = "unselected.tex"  -- 未选中状态图像
local IMAGE_UNSELECTED_OVER = "unselected_over.tex"  -- 未选中状态悬停图像

local IMAGE_SELECTABLE = "selectable.tex"  -- 可选中状态图像
local IMAGE_SELECTABLE_OVER = "selectable_over.tex"  -- 可选中状态悬停图像
local SKILL_BUTTON_SIZE = 64

local IMAGE_FRAME = "frame.tex"  -- 框架图像
local TILESIZE_FRAME = 80  -- 框架的大小



local HMRTech = Class(Widget, function(self, owner, pos)
    Widget._ctor(self, "HMRTech")

    self.owner = owner

    self.skillbuttons = {}  -- 定义技能按钮列表

    --------------------------------------------------------------------------
    -- 背景
    --------------------------------------------------------------------------
    -- 根
    self.root = self:AddChild(Widget("root"))
    -- 全屏背景，关闭界面
    self.root.global_close = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.root.global_close:SetVRegPoint(ANCHOR_MIDDLE)
    self.root.global_close:SetHRegPoint(ANCHOR_MIDDLE)
    self.root.global_close:SetVAnchor(ANCHOR_MIDDLE)
    self.root.global_close:SetHAnchor(ANCHOR_MIDDLE)
    self.root.global_close:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.root.global_close:SetTint(0, 0, 0, 0)
    self.root.global_close.OnMouseButton = function() self:Close() end
    -- 标题背景
    local TITLE_POS = {0, 600}
    self.root.titlebg = self.root:AddChild(Image("images/skilltree.xml", "playerinfo_bg.tex"))
    self.root.titlebg:SetPosition(TITLE_POS[1], TITLE_POS[2])
    self.root.titlebg:ScaleToSize(1200, 300)
    -- 主背景
    self.root.bg = self.root:AddChild(Image("images/skilltree2.xml", "background.tex"))
    self.root.bg:SetPosition(0, 0)
    self.root.bg:ScaleToSize(1400, 1000)
    -- 主背景装饰
    self.root.bgdeco = self.root:AddChild(Image("images/skilltree.xml", "background_scratches.tex"))
    self.root.bgdeco:SetPosition(0, 0)
    self.root.bgdeco:ScaleToSize(1350, 1000)

    --------------------------------------------------------------------------
    -- 解锁部分
    --------------------------------------------------------------------------
    -- 科技描述
    self.root.infopanel = self.root:AddChild(Widget("infopanel"))
    self.root.infopanel:SetPosition(0, 0)
    local INFO_POS = {0, -380}
    -- 描述背景
    self.root.infopanel.bg = self.root.infopanel:AddChild(Image("images/skilltree.xml", "wilson_background_text.tex"))
    self.root.infopanel.bg:ScaleToSize(900, 250)
    self.root.infopanel.bg:SetPosition(INFO_POS[1], INFO_POS[2] + 70)
    -- 描述文字
    self.root.infopanel.desc = self.root.infopanel:AddChild(Text(CHATFONT, 35, STRINGS.HMR.HMR_TECHTREE.UI.DEFAULT_DESCRIBE, UICOLOURS.BROWN_DARK))
    self.root.infopanel.desc:SetPosition(INFO_POS[1], INFO_POS[2] + 80)
    self.root.infopanel.desc:SetHAlign(ANCHOR_LEFT)
    self.root.infopanel.desc:SetVAlign(ANCHOR_TOP)
    self.root.infopanel.desc:SetMultilineTruncatedString(STRINGS.HMR.HMR_TECHTREE.UI.DEFAULT_DESCRIBE, 5, 800, nil, nil, true, 6)

    -- 已解锁背景
    self.root.infopanel.activatedbg = self.root.infopanel:AddChild(Image("images/skilltree.xml", "skilltree_backgroundart.tex"))
    self.root.infopanel.activatedbg:ScaleToSize(220, 80)
    self.root.infopanel.activatedbg:SetPosition(INFO_POS[1], INFO_POS[2] - 30)
    -- 已解锁文本
    self.root.infopanel.activatedtext = self.root.infopanel:AddChild(Text(HEADERFONT, 18, STRINGS.SKILLTREE.ACTIVATED, UICOLOURS.BLACK))
    self.root.infopanel.activatedtext:SetPosition(INFO_POS[1], INFO_POS[2] - 30)
    self.root.infopanel.activatedtext:SetSize(30)
    -- 解锁按钮
    self.root.infopanel.activatebutton = self.root.infopanel:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.root.infopanel.activatebutton.image:SetScale(1.5)  -- 设置按钮图像比例
    self.root.infopanel.activatebutton:SetFont(CHATFONT)  -- 设置按钮字体
    self.root.infopanel.activatebutton:SetPosition(INFO_POS[1], INFO_POS[2] - 30)  -- 设置按钮位置
    self.root.infopanel.activatebutton.text:SetColour(0, 0, 0, 1)  -- 设置按钮文本颜色
    self.root.infopanel.activatebutton:SetScale(0.5)  -- 设置按钮大小
    self.root.infopanel.activatebutton:SetText(STRINGS.SKILLTREE.ACTIVATE)  -- 设置按钮文本
    self.root.infopanel.activatebutton.onclick = function()
        if self.selectedskill ~= nil then
            self:LearnSkill()
            self:RefreshTree()
        end
    end
    -- 刷新
    self.owner:ListenForEvent("HMR_techtree_refresh", function(_, data)
        self:RefreshTree()
        self:SpawnFx(data.techname)
    end)
    self.owner:ListenForEvent("hmr_techtree_success_learn", function(_, data)
        self:RefreshTree()
    end)

    --------------------------------------------------------------------------
    -- 标题
    --------------------------------------------------------------------------
    -- 标题
    self.root.infopanel.title = self.root.infopanel:AddChild(Text(HEADERFONT, 70, STRINGS.HMR.HMR_TECHTREE.UI.DEFAULT_TITLE, UICOLOURS.GOLD_CLICKABLE))
    self.root.infopanel.title:SetPosition(TITLE_POS[1], TITLE_POS[2] - 10)
    self.root.infopanel.title:SetVAlign(ANCHOR_TOP)
    -- 副标题
    self.root.infopanel.subtitle = self.root.infopanel:AddChild(Text(HEADERFONT, 50, STRINGS.HMR.HMR_TECHTREE.UI.DEFAULT_SUBTITLE, UICOLOURS.GOLD))
    self.root.infopanel.subtitle:SetPosition(TITLE_POS[1], TITLE_POS[2] - 60)
    self.root.infopanel.subtitle:SetVAlign(ANCHOR_TOP)

    --------------------------------------------------------------------------
    -- 打开按钮
    --------------------------------------------------------------------------
    if pos then
        self.openbutton = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_square_normal.tex", "button_carny_square_hover.tex", nil, "button_carny_square_down.tex", "button_carny_square_down.tex"))
        self.openbutton:SetPosition(pos.x + OPEN_BUTTON_POS_OFFSET[1], pos.y + OPEN_BUTTON_POS_OFFSET[2])
        self.openbutton:MoveToFront()
        self.openbutton:ForceImageSize(120, 80)
        self.openbutton.text = self:AddChild(Text(BUTTONFONT, 35, "丰耘科技", {0.3, 0.26, 0.15, 1}))
        self.openbutton.text:SetPosition(pos.x + OPEN_BUTTON_POS_OFFSET[1], pos.y + OPEN_BUTTON_POS_OFFSET[2])
        self.isopen = false
        self.openbutton.onclick = function()
            if self.isopen then
                self:Close()
            else
                self:Open()
            end
        end
    end

    --------------------------------------------------------------------------
    -- 初始化
    --------------------------------------------------------------------------
    self:MakeSkillTree()
    self.root:Hide()
end)

function HMRTech:MakeSkillTree()
    for skill, data in pairs(HMR_TECH_LIST) do
        local skillbutton = nil
        local skillicon = nil
        local skillimage = nil

        -- 创建技能按钮，并使用相应的图像
		skillbutton = self.root:AddChild(ImageButton(ATLAS, IMAGE_SELECTED, IMAGE_SELECTED_OVER, IMAGE_SELECTED, IMAGE_SELECTED, IMAGE_SELECTED))
		skillbutton:ForceImageSize(SKILL_BUTTON_SIZE, SKILL_BUTTON_SIZE)
		skillbutton:SetOnGainFocus(function()
			if TheInput:ControllerAttached() then
				self.selectedskill = skill
				self:RefreshTree()
			end
		end)
        skillbutton:SetOnClick(function()
			if not TheInput:ControllerAttached() then
				self.selectedskill = skill
				self:RefreshTree()
			end
		end)
        skillbutton:SetPosition(data.pos[1], data.pos[2])
        skillbutton.clickoffset = Vector3(0, -1, 0)

        -- 创建技能图标
		if data.icon then
			local tex = data.icon
            local atlas = data.atlas or data.icon
			skillicon = skillbutton:AddChild(Image(atlas, tex))
			skillicon:ScaleToSize(SKILL_BUTTON_SIZE - 4, SKILL_BUTTON_SIZE - 4)
			skillicon:MoveToFront()
            skillbutton.skillicon = skillicon
		end

        -- 创建选中高光
        skillimage = skillbutton:AddChild(Image(ATLAS, IMAGE_FRAME))
		skillimage:ScaleToSize(TILESIZE_FRAME, TILESIZE_FRAME)
		skillimage:Hide()
        skillbutton.skillimage = skillimage

        self.skillbuttons[skill] = skillbutton  -- 将技能按钮添加到技能按钮列表中
    end
end

function HMRTech:RefreshTree()
    local canactivate = {}  -- 记录可激活的技能
    if self.skillbuttons == nil then
        return
    end
    for name, info in pairs(HMR_TECH_LIST) do
        -- 判断技能可激活
        canactivate[name] = true
        if info.connects ~= nil then
            for _, skill in pairs(info.connects) do
                if not self:IsTechLearned(skill) then
                    canactivate[name] = false
                    break
                end
            end
        end

        -- 暗淡没有激活的技能
        if not self:IsTechLearned(name) then
            if canactivate[name] == false then
                -- 未激活且不能激活
                self.skillbuttons[name]:SetTextures(ATLAS, IMAGE_UNSELECTED, IMAGE_UNSELECTED_OVER, IMAGE_UNSELECTED, IMAGE_UNSELECTED, IMAGE_UNSELECTED)
            else
                -- 未激活但当前可激活
                self.skillbuttons[name]:SetTextures(ATLAS, IMAGE_SELECTABLE, IMAGE_SELECTABLE_OVER, IMAGE_SELECTABLE, IMAGE_SELECTABLE, IMAGE_SELECTABLE)
            end
        else
            -- 已激活
            self.skillbuttons[name]:SetTextures(ATLAS, IMAGE_SELECTED, IMAGE_SELECTED_OVER, IMAGE_SELECTED, IMAGE_SELECTED, IMAGE_SELECTED)
        end

        -- 高亮显示已选中的技能
        if self.selectedskill == name then
            self.skillbuttons[name].skillimage:Show()
        else
            self.skillbuttons[name].skillimage:Hide()
        end
    end

    if self.selectedskill == nil then
        -- 没有选择技能
        self.root.infopanel.activatebutton:Hide()
        self.root.infopanel.activatedbg:Show()
        self.root.infopanel.activatedtext:Show()
        self.root.infopanel.activatedtext:SetString(STRINGS.HMR.HMR_TECHTREE.UI.INFOPANEL_UNSELECTED)
        return
    end

    local skillinfo = HMR_TECH_LIST[self.selectedskill]
    if skillinfo ~= nil then
        self.root.infopanel.title:SetString(skillinfo.title or "")
        self.root.infopanel.subtitle:SetString(skillinfo.subtitle or "")
        self.root.infopanel.subtitle:SetColour(unpack(skillinfo.subtitlecolour))
        self.root.infopanel.desc:SetMultilineTruncatedString(skillinfo.desc, 5, 800, nil, nil, true, 6)

        if not self:IsTechLearned(self.selectedskill) then
            -- 当前技能没有激活
            if canactivate[self.selectedskill] == true then
                -- 可以激活
                self.root.infopanel.activatebutton:Show()
                self.root.infopanel.activatebutton:SetText(STRINGS.HMR.HMR_TECHTREE.UI.UNLOCK..skillinfo.title)
                self.root.infopanel.activatedbg:Hide()
                self.root.infopanel.activatedtext:Hide()
            else
                -- 不可激活
                self.root.infopanel.activatebutton:Hide()
                self.root.infopanel.activatedbg:Show()
                self.root.infopanel.activatedtext:Show()
                self.root.infopanel.activatedtext:SetString(STRINGS.HMR.HMR_TECHTREE.UI.INFOPANEL_DISACTIVATABLE)
            end
        else
            -- 当前技能已激活
            self.root.infopanel.activatebutton:Hide()
            self.root.infopanel.activatedbg:Show()
            self.root.infopanel.activatedtext:Show()
            self.root.infopanel.activatedtext:SetString(STRINGS.HMR.HMR_TECHTREE.UI.UNLOCKED)
        end
    end
end

function HMRTech:IsTechLearned(skill)
    return TheWorld.components.hmrtechtree:GetTechStatus(skill)
end

function HMRTech:LearnSkill()
    TheWorld.components.hmrtechtree:LearnTech(self.selectedskill)
end

function HMRTech:SpawnFx(skill)
    if skill == nil then
        skill = self.selectedskill
    end

    local skillbutton = self.skillbuttons[self.selectedskill]
    local pos = skillbutton:GetPosition()
    local clickfx = self:AddChild(UIAnim())
    clickfx:GetAnimState():SetBuild("skills_activate")
    clickfx:GetAnimState():SetBank("skills_activate")
    clickfx:GetAnimState():PushAnimation("idle")
    clickfx.inst:ListenForEvent("animover", function() clickfx:Kill() end)
    clickfx:SetPosition(pos.x, pos.y + 15)

    TheFrontEnd:GetSound():PlaySound("wilson_rework/ui/skill_mastered")
end

function HMRTech:Open()
    self.root:Show()
    TheCamera:PushScreenHOffset(self, SCREEN_OFFSET)
    SetAutopaused(true)
    self.isopen = true

    self:RefreshTree()
end

function HMRTech:Close()
    self.root:Hide()
    TheCamera:PopScreenHOffset(self)
    SetAutopaused(false)
    self.isopen = false
end

-- fronted.lua中调用了，不写会报错
function HMRTech:OnUpdate()
end

return HMRTech