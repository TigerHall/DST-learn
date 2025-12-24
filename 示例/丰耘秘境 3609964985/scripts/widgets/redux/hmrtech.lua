local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

local HMR_TECH_LIST = require("hmrmain/hmr_lists").HMR_TECH_LIST

local ATLAS = "images/skilltree.xml"  -- 技能树图集
local IMAGE_SELECTED = "selected.tex"  -- 选中状态图像
local IMAGE_SELECTED_OVER = "selected_over.tex"  -- 选中状态悬停图像

local IMAGE_UNSELECTED = "unselected.tex"  -- 未选中状态图像
local IMAGE_UNSELECTED_OVER = "unselected_over.tex"  -- 未选中状态悬停图像

local IMAGE_SELECTABLE = "selectable.tex"  -- 可选中状态图像
local IMAGE_SELECTABLE_OVER = "selectable_over.tex"  -- 可选中状态悬停图像

local SKILL_BUTTON_SIZE = 35

local IMAGE_FRAME = "frame.tex"  -- 框架图像
local TILESIZE_FRAME = 40  -- 框架的大小



local HMRTech = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "HMRTech")

    self.skillbuttons = {}  -- 定义技能按钮列表

    --------------------------------------------------------------------------
    -- 背景
    --------------------------------------------------------------------------
    self.root = self:AddChild(Widget("HMRTechRoot"))

    self.bg = self.root:AddChild(Image("images/widgetimages/hmr_tech_bg.xml", "hmr_tech_bg.tex"))
    -- self.bg:SetScale(0.7)
    self.bg:SetPosition(0, 0)

    --------------------------------------------------------------------------
    -- 解锁部分
    --------------------------------------------------------------------------
    -- 科技描述
    self.root.infopanel = self.root:AddChild(Widget("infopanel"))
    self.root.infopanel:SetPosition(0, 0)
    local INFO_POS = {0, -280}
    -- 描述背景
    self.root.infopanel.bg = self.root.infopanel:AddChild(Image("images/skilltree.xml", "wilson_background_text.tex"))
    self.root.infopanel.bg:ScaleToSize(650, 160)
    self.root.infopanel.bg:SetPosition(INFO_POS[1], INFO_POS[2] + 35)
    -- 描述文字
    self.root.infopanel.desc = self.root.infopanel:AddChild(Text(CHATFONT, 25, STRINGS.HMR.HMR_TECHTREE.UI.DEFAULT_DESCRIBE, UICOLOURS.BROWN_DARK))
    self.root.infopanel.desc:SetPosition(INFO_POS[1], INFO_POS[2] + 35)
    self.root.infopanel.desc:SetHAlign(ANCHOR_LEFT)
    self.root.infopanel.desc:SetVAlign(ANCHOR_TOP)
    self.root.infopanel.desc:SetMultilineTruncatedString(STRINGS.HMR.HMR_TECHTREE.UI.DEFAULT_DESCRIBE, 5, 600, nil, nil, true, 6)

    -- 已解锁背景
    self.root.infopanel.activatedbg = self.root.infopanel:AddChild(Image("images/skilltree.xml", "skilltree_backgroundart.tex"))
    self.root.infopanel.activatedbg:ScaleToSize(140, 50)
    self.root.infopanel.activatedbg:SetPosition(INFO_POS[1], INFO_POS[2] - 30)
    -- 已解锁文本
    self.root.infopanel.activatedtext = self.root.infopanel:AddChild(Text(HEADERFONT, 15, STRINGS.SKILLTREE.ACTIVATED, UICOLOURS.BLACK))
    self.root.infopanel.activatedtext:SetPosition(INFO_POS[1], INFO_POS[2] - 30)
    self.root.infopanel.activatedtext:SetSize(20)
    -- 解锁按钮
    self.root.infopanel.activatebutton = self.root.infopanel:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.root.infopanel.activatebutton.image:SetScale(1)  -- 设置按钮图像比例
    self.root.infopanel.activatebutton:SetFont(CHATFONT)  -- 设置按钮字体
    self.root.infopanel.activatebutton:SetPosition(INFO_POS[1], INFO_POS[2] - 30)  -- 设置按钮位置
    self.root.infopanel.activatebutton.text:SetColour(0, 0, 0, 1)  -- 设置按钮文本颜色
    self.root.infopanel.activatebutton:SetScale(0.4)  -- 设置按钮大小
    self.root.infopanel.activatebutton:SetText(STRINGS.SKILLTREE.ACTIVATE)  -- 设置按钮文本
    self.root.infopanel.activatebutton.onclick = function()
        if self.selectedskill ~= nil then
            self:TryLearnSkill()
        end
    end

    --------------------------------------------------------------------------
    -- 标题
    --------------------------------------------------------------------------
    -- -- 标题下装饰
    -- self.root.infopanel.decoration = self.root.infopanel:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line_break2.tex"))
    -- self.root.infopanel.decoration:SetPosition(0, 250)
    -- self.root.infopanel.decoration:ScaleToSize(300, 20)
    -- 标题
    local TITLE_POS = {0, 200}
    self.root.infopanel.title = self.root.infopanel:AddChild(Text(HEADERFONT, 40, STRINGS.HMR.HMR_TECHTREE.UI.DEFAULT_TITLE, UICOLOURS.GOLD_CLICKABLE))
    self.root.infopanel.title:SetPosition(TITLE_POS[1], TITLE_POS[2] - 10)
    self.root.infopanel.title:SetVAlign(ANCHOR_TOP)
    -- 副标题
    self.root.infopanel.subtitle = self.root.infopanel:AddChild(Text(HEADERFONT, 30, STRINGS.HMR.HMR_TECHTREE.UI.DEFAULT_SUBTITLE, UICOLOURS.GOLD))
    self.root.infopanel.subtitle:SetPosition(TITLE_POS[1], TITLE_POS[2] - 40)
    self.root.infopanel.subtitle:SetVAlign(ANCHOR_TOP)

    --------------------------------------------------------------------------
    -- 初始化
    --------------------------------------------------------------------------
    self:MakeSkillTree()

    ThePlayer.HMRTech = self
end)

function HMRTech:KillAllSkillButtons()
    if self.skillbuttons ~= nil then
        for _, skillbutton in pairs(self.skillbuttons) do
            skillbutton:Kill()
        end
    end
    self.skillbuttons = {}
end

function HMRTech:MakeSkillTree()
    self:KillAllSkillButtons()
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
				self:MakeSkillTree()
			end
		end)
        skillbutton:SetOnClick(function()
			if not TheInput:ControllerAttached() then
				self.selectedskill = skill
				self:MakeSkillTree()
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

    self:RefreshTree(true)
end

function HMRTech:RefreshTree(force)
    print("刷新", os.clock(), self.last_refresh_time)
    if self.last_refresh_time ~= nil and os.clock() - self.last_refresh_time < 0.1 then
        return
    end
    self.last_refresh_time = os.clock()

    local canactivate = {}  -- 记录可激活的技能
    if self.skillbuttons == nil then
        return
    end
    if self.isopen ~= true and force ~= true then
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

        if self.skillbuttons[name] ~= nil then
            print("刷新技能", name)
            -- 暗淡没有激活的技能
            if not self:IsTechLearned(name) then
                if canactivate[name] == false then
                    -- 未激活且不能激活
                    print("技能不可激活", name)
                    self.skillbuttons[name]:SetTextures(ATLAS, IMAGE_UNSELECTED, IMAGE_UNSELECTED_OVER, IMAGE_UNSELECTED, IMAGE_UNSELECTED, IMAGE_UNSELECTED)
                else
                    -- 未激活但当前可激活
                    print("技能可激活", name)
                    self.skillbuttons[name]:SetTextures(ATLAS, IMAGE_SELECTABLE, IMAGE_SELECTABLE_OVER, IMAGE_SELECTABLE, IMAGE_SELECTABLE, IMAGE_SELECTABLE)
                end
            else
                -- 已激活
                print("技能已激活", name)
                self.skillbuttons[name]:SetTextures(ATLAS, IMAGE_SELECTED, IMAGE_SELECTED_OVER, IMAGE_SELECTED, IMAGE_SELECTED, IMAGE_SELECTED)
            end

            -- 高亮显示已选中的技能
            if self.selectedskill == name then
                self.skillbuttons[name].skillimage:Show()
            else
                self.skillbuttons[name].skillimage:Hide()
            end
            print("刷新技能完毕", name)
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
        self.root.infopanel.desc:SetMultilineTruncatedString(skillinfo.desc, 5, 600, nil, nil, true, 6)

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

function HMRTech:TryLearnSkill()
    TheWorld.components.hmrtechtree:LearnTech(self.selectedskill)
end

function HMRTech:LearnSkill(skills)
    self:MakeSkillTree()
    if skills ~= nil and type(skills) == "table" then
        for _, tech in pairs(skills) do
            self:SpawnFx(tech)
        end
    end
end

function HMRTech:SpawnFx(skill)
    if skill == nil then
        skill = self.selectedskill
    end

    local skillbutton = self.skillbuttons[skill]
    if skillbutton ~= nil then
        local pos = skillbutton:GetPosition()
        local clickfx = self:AddChild(UIAnim())
        clickfx:GetAnimState():SetBuild("skills_activate")
        clickfx:GetAnimState():SetBank("skills_activate")
        clickfx:GetAnimState():PushAnimation("idle")
        clickfx.inst:ListenForEvent("animover", function() clickfx:Kill() end)
        clickfx:SetPosition(pos.x, pos.y + 15)
    end

    TheFrontEnd:GetSound():PlaySound("wilson_rework/ui/skill_mastered")
end

-- fronted.lua中调用了，不写会报错
function HMRTech:OnUpdate()
end

return HMRTech