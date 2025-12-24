local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local InputDialogScreen = require "screens/redux/inputdialog"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"
local WIKIRESOURCE = require "widgets/atbook_wikiwidget_resource"
local CONTENT = require "widgets/atbook_wikiwidget_defs"

local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end

local CONTENTPATH = "images/ui/atbook_wiki/content/"

local BTNINDEX = {
    "ISLAND",
    "CREATURE",
    "PLANT",
    "STRUCTURE",
    "INVENTORY",
    "FOOD",
}

local SKINCOLOUR = {
    GREEN  = { 0 / 255, 200 / 255, 0 / 255, 1 },
    BLUE   = { 0 / 255, 128 / 255, 255 / 255, 1 },
    PINK   = { 255 / 255, 0 / 255, 127 / 255, 1 },
    PURPLE = { 153 / 255, 51 / 255, 255 / 255, 1 },
    RED    = { 204 / 255, 0 / 255, 0 / 255, 1 },
    GOLD   = { 255 / 255, 215 / 255, 0 / 255, 1 }
}

local Wiki = Class(Widget, function(self)
    Widget._ctor(self, "Wiki")
    self.root = self:AddChild(Widget("root"))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)

    self.tab = 0

    self.main = self.root:AddChild(Widget("main"))

    local backdrop_head = self.main:AddChild(Image(WIKIRESOURCE.BG_HEAD[1], WIKIRESOURCE.BG_HEAD[2]))
    backdrop_head:SetScale(0.65)
    backdrop_head:SetPosition(0, 220)

    local backdrop = self.main:AddChild(Image(WIKIRESOURCE.BG[1], WIKIRESOURCE.BG[2]))
    backdrop:SetScale(0.65)

    for i = 1, 6 do
        self["btn_" .. i] = self.main:AddChild(ImageButton(WIKIRESOURCE["TAB_" .. i][1], WIKIRESOURCE["TAB_" .. i][2]))
        self["btn_" .. i]:SetScale(0.6)
        self["btn_" .. i]:SetFocusScale(1.03, 1.03)
        self["btn_" .. i]:SetPosition(-390 + i * 110, 260)
        self["btn_" .. i]:SetOnClick(function()
            self:ChangeTab(i)
        end)
    end

    local backdrop_up = self.main:AddChild(Image(WIKIRESOURCE.BG_UP[1], WIKIRESOURCE.BG_UP[2]))
    backdrop_up:SetScale(0.65)
    backdrop_up:SetPosition(0, -20)

    self.detail = self.main:AddChild(Widget("detail"))

    local backdrop_right = self.main:AddChild(ImageButton(WIKIRESOURCE.BG_RIGHT[1], WIKIRESOURCE.BG_RIGHT[2]))
    backdrop_right:SetScale(0.60)
    backdrop_right:SetFocusScale(1.03, 1.03)
    backdrop_right:SetPosition(370, -160)

    local closebutton = self.main:AddChild(ImageButton(WIKIRESOURCE.CLOSE[1], WIKIRESOURCE.CLOSE[2]))
    closebutton:SetPosition(400, 240)
    closebutton:SetScale(0.6)
    closebutton:SetFocusScale(1.03, 1.03)
    closebutton:SetHoverText(STRINGS.UI.HELP.CLOSE)
    closebutton:SetOnClick(function() self:PreHide() end)

    local btn_zb = self.main:AddChild(ImageButton(WIKIRESOURCE.BTN_ZB[1], WIKIRESOURCE.BTN_ZB[2]))
    btn_zb:SetPosition(-360, -210)
    btn_zb:SetScale(0.6)
    btn_zb:SetFocusScale(1.03, 1.03)
    btn_zb:SetOnClick(function()
        self:SkinButton()
    end)

    local btn_gs = self.main:AddChild(ImageButton(WIKIRESOURCE.BTN_GS[1], WIKIRESOURCE.BTN_GS[2]))
    btn_gs:SetPosition(415, 100)
    btn_gs:SetScale(0.6)
    btn_gs:SetFocusScale(1.03, 1.03)
    btn_gs:SetOnClick(function()
        self:NoticeButton()
    end)

    self.btn_1.onclick()

    --------------------------------------------------------------
    --- pushevent
    local old_Hide = self.Hide
    self.Hide = function(self, ...)
        old_Hide(self, ...)
        if ThePlayer then
            ThePlayer:PushEvent("tbat_event.wiki_close")
        end
    end
    local old_Show = self.Show
    self.Show = function(self, ...)
        old_Show(self, ...)
        if ThePlayer then
            ThePlayer:PushEvent("tbat_event.wiki_open")
        end
    end
    self.root.inst:DoTaskInTime(3, function()
        if ThePlayer then
            ThePlayer:PushEvent("tbat_event.wiki_created")
        end
    end)
    --------------------------------------------------------------
end)

function Wiki:GetContentResources(category, type, index, getpage, getimg)
    local prefab = CONTENT[BTNINDEX[category]][type][index].prefab
    local path = string.lower(BTNINDEX[category] or "ISLAND")
    if getpage then
        return CONTENTPATH .. path .. "/page/" .. prefab .. ".xml", prefab .. ".tex"
    end
    if getimg then
        return CONTENTPATH .. path .. "/img/" .. prefab .. ".xml", prefab .. ".tex"
    end
    return CONTENTPATH .. path .. "/" .. prefab .. ".xml", prefab .. ".tex"
end

function Wiki:NoticeButton()
    if self.scrollinggrid then
        self.main:RemoveChild(self.scrollinggrid)
        self.scrollinggrid:Kill()
        self.scrollinggrid = nil
    end
    if self.tabwidget then
        self.main:RemoveChild(self.tabwidget)
        self.tabwidget:Kill()
        self.tabwidget = nil
    end
    if self.detailwidget then
        self.detail:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end

    self.tabwidget = self.main:AddChild(Widget("tabwidget"))
    self.detailwidget = self.detail:AddChild(Widget("detailwidget"))

    local top = self.tabwidget:AddChild(Image(WIKIRESOURCE.NOTICE_TOP[1], WIKIRESOURCE.NOTICE_TOP[2]))
    top:SetScale(0.65)
    top:SetPosition(-185, 210)

    local bg = self.tabwidget:AddChild(Image(WIKIRESOURCE.NOTICE_BG[1], WIKIRESOURCE.NOTICE_BG[2]))
    bg:SetScale(0.65)
    bg:SetPosition(-185, 50)

    local bottom = self.tabwidget:AddChild(Image(WIKIRESOURCE.NOTICE_BOTTOM[1], WIKIRESOURCE.NOTICE_BOTTOM[2]))
    bottom:SetScale(0.65)
    bottom:SetPosition(-185, -110)

    local butterfly = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.BUTTERFLY[1], WIKIRESOURCE.BUTTERFLY[2]))
    butterfly:SetHoverText("点击跳转到介绍页")
    butterfly:SetScale(0.65)
    butterfly:SetFocusScale(1.05, 1.05)
    butterfly:SetPosition(-100, 130)
    butterfly:SetOnClick(function()
        VisitURL(CONTENT.NOTICE.url, false)
    end)

    local title_left = self.tabwidget:AddChild(Text(DEFAULTFONT, 34, CONTENT.NOTICE.title_left, RGB(118, 89, 49)))
    title_left:SetPosition(-180, 140)

    local content_left = self.tabwidget:AddChild(Text(HEADERFONT, 24, CONTENT.NOTICE.content_left, RGB(118, 89, 49)))
    content_left:SetPosition(-180, -140)
    content_left:SetHAlign(ANCHOR_LEFT)
    content_left:SetVAlign(ANCHOR_TOP)
    content_left:SetRegionSize(230, 500)
    content_left:EnableWordWrap(true)

    local bg_right = self.detailwidget:AddChild(Image(WIKIRESOURCE.NOTICE_RIGHT[1], WIKIRESOURCE.NOTICE_RIGHT[2]))
    bg_right:SetScale(0.65)
    bg_right:SetPosition(215, 40)

    local title_right = self.detailwidget:AddChild(Text(DEFAULTFONT, 32, CONTENT.NOTICE.title_right, RGB(118, 89, 49)))
    title_right:SetPosition(190, 190)
    title_right:SetRotation(3)

    local content_right = self.detailwidget:AddChild(Text(HEADERFONT, 22, CONTENT.NOTICE.content_right, RGB(118, 89, 49)))
    content_right:SetPosition(220, -90)
    content_right:SetHAlign(ANCHOR_LEFT)
    content_right:SetVAlign(ANCHOR_TOP)
    content_right:SetRegionSize(230, 500)
    content_right:EnableWordWrap(true)
    content_right:SetRotation(3)
end

function Wiki:SkinButton()
    if self.scrollinggrid then
        self.main:RemoveChild(self.scrollinggrid)
        self.scrollinggrid:Kill()
        self.scrollinggrid = nil
    end
    if self.tabwidget then
        self.main:RemoveChild(self.tabwidget)
        self.tabwidget:Kill()
        self.tabwidget = nil
    end
    if self.detailwidget then
        self.detail:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end

    self.tabwidget = self.main:AddChild(Widget("tabwidget"))

    self.typelist = {}
    self.btn_cat = {}
    self.typecheck = 1

    local title = self.tabwidget:AddChild(Image(WIKIRESOURCE.SKIN_TITLE[1], WIKIRESOURCE.SKIN_TITLE[2]))
    title:SetScale(0.65)
    title:SetPosition(-170, 220)

    local cdk = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.SKIN_CDK[1], WIKIRESOURCE.SKIN_CDK[2]))
    cdk:SetScale(0.65)
    cdk:SetFocusScale(1.05, 1.05)
    cdk:SetPosition(-380, 170)
    cdk:SetOnClick(function()
        local use_cdk_screen = InputDialogScreen("请输入CDK",
            {
                {
                    text = "验证",
                    cb = function()
                        SendModRPCToServer(MOD_RPC["ATBOOK"]["atbook_brcverify"], InputDialogScreen:GetText(), true)
                        TheFrontEnd:PopScreen()
                    end
                },
                {
                    text = STRINGS.UI.SERVERLISTINGSCREEN.CANCEL,
                    cb = function()
                        TheFrontEnd:PopScreen()
                    end
                }
            }, true)
        TheFrontEnd:PushScreen(use_cdk_screen)
    end)

    local bar = self.tabwidget:AddChild(Image(WIKIRESOURCE.SKIN_TYPE_BG[1], WIKIRESOURCE.SKIN_TYPE_BG[2]))
    bar:SetScale(0.65)
    bar:SetPosition(-180, 170)

    for i = 1, 6 do
        self.btn_cat[i] = self.tabwidget:AddChild(Image(WIKIRESOURCE.SKIN_CAT[1], WIKIRESOURCE.SKIN_CAT[2]))
        self.btn_cat[i]:SetScale(0.65)
        self.btn_cat[i]:SetPosition(-317 + i * 39, 172)
        if i == 1 then
            self.typelist[i] = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE["SKIN_TYPE_" .. i][1],
                WIKIRESOURCE["SKIN_TYPE_" .. i][2]))
        else
            self.typelist[i] = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE["SKIN_TYPE_" .. i .. "_DARK"][1],
                WIKIRESOURCE["SKIN_TYPE_" .. i .. "_DARK"][2]))
            self.btn_cat[i]:Hide()
        end

        self.typelist[i]:SetScale(0.65)
        self.typelist[i]:SetFocusScale(1.05, 1.05)
        self.typelist[i]:SetPosition(-317 + i * 39, 170)
        self.typelist[i]:SetOnClick(function()
            for j = 1, 6 do
                if j == i then
                    self.typelist[j]:SetTextures(WIKIRESOURCE["SKIN_TYPE_" .. j][1], WIKIRESOURCE["SKIN_TYPE_" .. j][2])
                    self.btn_cat[j]:Show()
                else
                    self.typelist[j]:SetTextures(WIKIRESOURCE["SKIN_TYPE_" .. j .. "_DARK"][1],
                        WIKIRESOURCE["SKIN_TYPE_" .. j .. "_DARK"][2])
                    self.btn_cat[j]:Hide()
                end
            end
            self.typecheck = i
            self:ChangeSkinType()
        end)
    end

    self:ChangeSkinType()
end

function Wiki:ChangeSkinType()
    if self.scrollinggrid then
        self.main:RemoveChild(self.scrollinggrid)
        self.scrollinggrid:Kill()
        self.scrollinggrid = nil
    end
    if self.detailwidget then
        self.detail:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end

    local info = {}

    if CONTENT.SKIN[self.typecheck] then
        for key, value in pairs(CONTENT.SKIN[self.typecheck]) do
            local t = deepcopy(value)
            t.index = key
            t.atlas = TBAT.SKIN.SKINS_DATA_SKINS[t.skincode].atlas
            t.image = TBAT.SKIN.SKINS_DATA_SKINS[t.skincode].image
            t.bank = TBAT.SKIN.SKINS_DATA_SKINS[t.skincode].bank
            t.build = TBAT.SKIN.SKINS_DATA_SKINS[t.skincode].build
            t.prefabname = TBAT.SKIN.SKINS_DATA_SKINS[t.skincode].prefab_name and
            STRINGS.NAMES[string.upper(TBAT.SKIN.SKINS_DATA_SKINS[t.skincode].prefab_name)] or ""
            t.have = ThePlayer.replica and ThePlayer.replica.tbat_com_skins_controller and
                ThePlayer.replica.tbat_com_skins_controller:HasSkin(t.skincode)
            print(">>>", t.skincode, t.have)
            if t.atlas and t.image then
                table.insert(info, t)
            end
        end
    end

    self.scrollinggrid = self.main:AddChild(self:BuildSkinScrollingGrid(info))
    self.scrollinggrid:SetPosition(-175, 0)
end

function Wiki:ChangeTab(tab)
    if self.scrollinggrid then
        self.main:RemoveChild(self.scrollinggrid)
        self.scrollinggrid:Kill()
        self.scrollinggrid = nil
    end

    if self.tabwidget then
        self.main:RemoveChild(self.tabwidget)
        self.tabwidget:Kill()
        self.tabwidget = nil
    end

    if self.tab ~= tab then
        if self["btn_" .. self.tab] then
            local startpos = self["btn_" .. self.tab]:GetPosition()
            local endpos = Vector3(startpos.x, startpos.y - 25, 0)
            self["btn_" .. self.tab]:MoveTo(startpos, endpos, 0.2)
        end

        self.tab = tab

        if self["btn_" .. self.tab] then
            local startpos = self["btn_" .. self.tab]:GetPosition()
            local endpos = Vector3(startpos.x, startpos.y + 25, 0)
            self["btn_" .. self.tab]:MoveTo(startpos, endpos, 0.2)
        end
    end

    -----------------------------------------------------------------------------------------

    self.tabwidget = self.main:AddChild(Widget("tabwidget"))

    self.typelist = {}
    self.btn_cat = {}
    self.typecheck = "A"

    local appearance = false

    if self.tab == 1 then
        -- ISLAND
        local name = self.tabwidget:AddChild(Text(DEFAULTFONT, 34, "万物书・序言", RGB(118, 89, 49)))
        name:SetPosition(-180, 200)

        local text1 =
        "    睁开眼时，再次来到永恒大陆 —— 熟悉的风裹着草木清香，脚下的土地仍带着旧年冒险的余温，却又藏着几分陌生的悸动。\n    海平面上，一座幻想织就的岛屿正缓缓浮现：紫色的云朵环绕着岛岸，神秘的「万物之树」从晨雾中苏醒，耸立的枝干间漏下细碎的光斑，翠羽鸟在林间穿梭，鸣声清脆如铃，仿佛在等待某种预言的应验。\n    幻想与现实的边界，在此刻悄然消融。那些只存在于梦境中的生物，正伴着霞光踏上这片大陆；那些令人忌惮的强大敌人们似乎也在讲述一个被时光遗忘的故事。"

        local info1 = self.tabwidget:AddChild(Text(HEADERFONT, 24, text1, RGB(118, 89, 49)))
        info1:SetPosition(-180, -140)
        info1:SetHAlign(ANCHOR_LEFT)
        info1:SetVAlign(ANCHOR_TOP)
        info1:SetRegionSize(250, 600)
        info1:EnableWordWrap(true)

        local text2 =
        "    冒险家们，你们的行囊是否早已备好？\n    在这片既熟悉又陌生的永恒领域里，新的世界正待探寻 —— 收集前辈留下的笔记，拼凑破碎的线索，揭开幻想与现实交织的帷幕；是沉醉于万物共生的奇幻盛景，还是执着于追寻真相的尽头？\n    一场交织着温柔幻想与神秘真相的冒险，即将启航。\n    「岛屿篇」将在第三期正式开放，敬请期待 —— 更多未知的惊喜与挑战，正藏在迷雾之后，等候与你相遇。"

        local info2 = self.tabwidget:AddChild(Text(HEADERFONT, 24, text2, RGB(118, 89, 49)))
        info2:SetPosition(220, -100)
        info2:SetHAlign(ANCHOR_LEFT)
        info2:SetVAlign(ANCHOR_TOP)
        info2:SetRegionSize(250, 600)
        info2:EnableWordWrap(true)
    elseif self.tab == 2 then
        -- CREATURE
        appearance = true
        local title = self.tabwidget:AddChild(Image(WIKIRESOURCE.CREATURE_TITLE[1], WIKIRESOURCE.CREATURE_TITLE[2]))
        title:SetScale(0.65)
        title:SetPosition(-190, 210)

        self.typelist.a = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.CREATURE_TYPE1[1],
            WIKIRESOURCE.CREATURE_TYPE1[2]))
        self.typelist.a:SetScale(0.65)
        self.typelist.a:SetFocusScale(1.05, 1.05)
        self.typelist.a:SetPosition(-110, 230)
        self.typelist.a:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.CREATURE_TYPE1[1], WIKIRESOURCE.CREATURE_TYPE1[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.CREATURE_TYPE2_DARK[1], WIKIRESOURCE.CREATURE_TYPE2_DARK[2])
            self.typecheck = "A"
            self:ChangeType(appearance)
        end)

        self.typelist.b = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.CREATURE_TYPE2_DARK[1],
            WIKIRESOURCE.CREATURE_TYPE2_DARK[2]))
        self.typelist.b:SetScale(0.65)
        self.typelist.b:SetFocusScale(1.05, 1.05)
        self.typelist.b:SetPosition(-110, 180)
        self.typelist.b:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.CREATURE_TYPE1_DARK[1], WIKIRESOURCE.CREATURE_TYPE1_DARK[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.CREATURE_TYPE2[1], WIKIRESOURCE.CREATURE_TYPE2[2])
            self.typecheck = "B"
            self:ChangeType(appearance)
        end)
    elseif self.tab == 3 then
        -- PLANT
        appearance = true
        local title = self.tabwidget:AddChild(Image(WIKIRESOURCE.PLANT_TITLE[1], WIKIRESOURCE.PLANT_TITLE[2]))
        title:SetScale(0.65)
        title:SetPosition(-190, 210)

        self.typelist.a = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.PLANT_TYPE1[1], WIKIRESOURCE.PLANT_TYPE1[2]))
        self.typelist.a:SetScale(0.65)
        self.typelist.a:SetFocusScale(1.05, 1.05)
        self.typelist.a:SetPosition(-110, 230)
        self.typelist.a:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.PLANT_TYPE1[1], WIKIRESOURCE.PLANT_TYPE1[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.PLANT_TYPE2_DARK[1], WIKIRESOURCE.PLANT_TYPE2_DARK[2])
            self.typecheck = "A"
            self:ChangeType(appearance)
        end)

        self.typelist.b = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.PLANT_TYPE2_DARK[1],
            WIKIRESOURCE.PLANT_TYPE2_DARK[2]))
        self.typelist.b:SetScale(0.65)
        self.typelist.b:SetFocusScale(1.05, 1.05)
        self.typelist.b:SetPosition(-110, 180)
        self.typelist.b:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.PLANT_TYPE1_DARK[1], WIKIRESOURCE.PLANT_TYPE1_DARK[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.PLANT_TYPE2[1], WIKIRESOURCE.PLANT_TYPE2[2])
            self.typecheck = "B"
            self:ChangeType(appearance)
        end)
    elseif self.tab == 4 then
        -- STRUCTURE
        local title = self.tabwidget:AddChild(Image(WIKIRESOURCE.BASE_TITLE[1], WIKIRESOURCE.BASE_TITLE[2]))
        title:SetScale(0.65)
        title:SetPosition(-190, 210)

        self.btn_cat.a = self.tabwidget:AddChild(Image(WIKIRESOURCE.BTN_CAT[1], WIKIRESOURCE.BTN_CAT[2]))
        self.btn_cat.a:SetScale(0.65)
        self.btn_cat.a:SetPosition(-273, 197)

        self.typelist.a = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.STRUCTURE_TYPE1[1],
            WIKIRESOURCE.STRUCTURE_TYPE1[2]))
        self.typelist.a:SetScale(0.65)
        self.typelist.a:SetFocusScale(1.05, 1.05)
        self.typelist.a:SetPosition(-273, 195)
        self.typelist.a:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE1[1], WIKIRESOURCE.STRUCTURE_TYPE1[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE2_DARK[1], WIKIRESOURCE.STRUCTURE_TYPE2_DARK[2])
            self.typelist.c:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE3_DARK[1], WIKIRESOURCE.STRUCTURE_TYPE3_DARK[2])
            self.btn_cat.a:Show()
            self.btn_cat.b:Hide()
            self.btn_cat.c:Hide()
            self.typecheck = "A"
            self:ChangeType(appearance)
        end)

        self.btn_cat.b = self.tabwidget:AddChild(Image(WIKIRESOURCE.BTN_CAT[1], WIKIRESOURCE.BTN_CAT[2]))
        self.btn_cat.b:SetScale(0.65)
        self.btn_cat.b:SetPosition(-189, 197)
        self.btn_cat.b:Hide()

        self.typelist.b = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.STRUCTURE_TYPE2_DARK[1],
            WIKIRESOURCE.STRUCTURE_TYPE2_DARK[2]))
        self.typelist.b:SetScale(0.65)
        self.typelist.b:SetFocusScale(1.05, 1.05)
        self.typelist.b:SetPosition(-189, 195)
        self.typelist.b:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE1_DARK[1], WIKIRESOURCE.STRUCTURE_TYPE1_DARK[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE2[1], WIKIRESOURCE.STRUCTURE_TYPE2[2])
            self.typelist.c:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE3_DARK[1], WIKIRESOURCE.STRUCTURE_TYPE3_DARK[2])
            self.btn_cat.a:Hide()
            self.btn_cat.b:Show()
            self.btn_cat.c:Hide()
            self.typecheck = "B"
            self:ChangeType(appearance)
        end)

        self.btn_cat.c = self.tabwidget:AddChild(Image(WIKIRESOURCE.BTN_CAT[1], WIKIRESOURCE.BTN_CAT[2]))
        self.btn_cat.c:SetScale(0.65)
        self.btn_cat.c:SetPosition(-105, 197)
        self.btn_cat.c:Hide()

        self.typelist.c = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.STRUCTURE_TYPE3_DARK[1],
            WIKIRESOURCE.STRUCTURE_TYPE3_DARK[2]))
        self.typelist.c:SetScale(0.65)
        self.typelist.c:SetFocusScale(1.05, 1.05)
        self.typelist.c:SetPosition(-105, 195)
        self.typelist.c:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE1_DARK[1], WIKIRESOURCE.STRUCTURE_TYPE1_DARK[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE2_DARK[1], WIKIRESOURCE.STRUCTURE_TYPE2_DARK[2])
            self.typelist.c:SetTextures(WIKIRESOURCE.STRUCTURE_TYPE3[1], WIKIRESOURCE.STRUCTURE_TYPE3[2])
            self.btn_cat.a:Hide()
            self.btn_cat.b:Hide()
            self.btn_cat.c:Show()
            self.typecheck = "C"
            self:ChangeType(appearance)
        end)
    elseif self.tab == 5 then
        -- INVENTORY
        local title = self.tabwidget:AddChild(Image(WIKIRESOURCE.BASE_TITLE[1], WIKIRESOURCE.BASE_TITLE[2]))
        title:SetScale(0.65)
        title:SetPosition(-190, 210)

        self.btn_cat.a = self.tabwidget:AddChild(Image(WIKIRESOURCE.BTN_CAT_LONG[1], WIKIRESOURCE.BTN_CAT_LONG[2]))
        self.btn_cat.a:SetScale(0.65)
        self.btn_cat.a:SetPosition(-243, 197)

        self.typelist.a = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.INVENTORY_TYPE1[1],
            WIKIRESOURCE.INVENTORY_TYPE1[2]))
        self.typelist.a:SetScale(0.65)
        self.typelist.a:SetFocusScale(1.05, 1.05)
        self.typelist.a:SetPosition(-243, 195)
        self.typelist.a:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.INVENTORY_TYPE1[1], WIKIRESOURCE.INVENTORY_TYPE1[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.INVENTORY_TYPE2_DARK[1], WIKIRESOURCE.INVENTORY_TYPE2_DARK[2])
            self.btn_cat.a:Show()
            self.btn_cat.b:Hide()
            self.typecheck = "A"
            self:ChangeType(appearance)
        end)

        self.btn_cat.b = self.tabwidget:AddChild(Image(WIKIRESOURCE.BTN_CAT_LONG[1], WIKIRESOURCE.BTN_CAT_LONG[2]))
        self.btn_cat.b:SetScale(0.65)
        self.btn_cat.b:SetPosition(-135, 197)
        self.btn_cat.b:Hide()

        self.typelist.b = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.INVENTORY_TYPE2_DARK[1],
            WIKIRESOURCE.INVENTORY_TYPE2_DARK[2]))
        self.typelist.b:SetScale(0.65)
        self.typelist.b:SetFocusScale(1.05, 1.05)
        self.typelist.b:SetPosition(-135, 195)
        self.typelist.b:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.INVENTORY_TYPE1_DARK[1], WIKIRESOURCE.INVENTORY_TYPE1_DARK[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.INVENTORY_TYPE2[1], WIKIRESOURCE.INVENTORY_TYPE2[2])
            self.btn_cat.a:Hide()
            self.btn_cat.b:Show()
            self.typecheck = "B"
            self:ChangeType(appearance)
        end)
    elseif self.tab == 6 then
        -- FOOD
        local title = self.tabwidget:AddChild(Image(WIKIRESOURCE.BASE_TITLE[1], WIKIRESOURCE.BASE_TITLE[2]))
        title:SetScale(0.65)
        title:SetPosition(-190, 210)

        self.btn_cat.a = self.tabwidget:AddChild(Image(WIKIRESOURCE.BTN_CAT_LONG[1], WIKIRESOURCE.BTN_CAT_LONG[2]))
        self.btn_cat.a:SetScale(0.65)
        self.btn_cat.a:SetPosition(-243, 197)

        self.typelist.a = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.FOOD_TYPE1[1], WIKIRESOURCE.FOOD_TYPE1[2]))
        self.typelist.a:SetScale(0.65)
        self.typelist.a:SetFocusScale(1.05, 1.05)
        self.typelist.a:SetPosition(-243, 195)
        self.typelist.a:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.FOOD_TYPE1[1], WIKIRESOURCE.FOOD_TYPE1[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.FOOD_TYPE2_DARK[1], WIKIRESOURCE.FOOD_TYPE2_DARK[2])
            self.btn_cat.a:Show()
            self.btn_cat.b:Hide()
            self.typecheck = "A"
            self:ChangeType(appearance)
        end)

        self.btn_cat.b = self.tabwidget:AddChild(Image(WIKIRESOURCE.BTN_CAT_LONG[1], WIKIRESOURCE.BTN_CAT_LONG[2]))
        self.btn_cat.b:SetScale(0.65)
        self.btn_cat.b:SetPosition(-135, 197)
        self.btn_cat.b:Hide()

        self.typelist.b = self.tabwidget:AddChild(ImageButton(WIKIRESOURCE.FOOD_TYPE2_DARK[1],
            WIKIRESOURCE.FOOD_TYPE2_DARK[2]))
        self.typelist.b:SetScale(0.65)
        self.typelist.b:SetFocusScale(1.05, 1.05)
        self.typelist.b:SetPosition(-135, 195)
        self.typelist.b:SetOnClick(function()
            self.typelist.a:SetTextures(WIKIRESOURCE.FOOD_TYPE1_DARK[1], WIKIRESOURCE.FOOD_TYPE1_DARK[2])
            self.typelist.b:SetTextures(WIKIRESOURCE.FOOD_TYPE2[1], WIKIRESOURCE.FOOD_TYPE2[2])
            self.btn_cat.a:Hide()
            self.btn_cat.b:Show()
            self.typecheck = "B"
            self:ChangeType(appearance)
        end)
    end

    self:ChangeType(appearance)
end

function Wiki:ChangeType(appearance)
    if self.scrollinggrid then
        self.main:RemoveChild(self.scrollinggrid)
        self.scrollinggrid:Kill()
        self.scrollinggrid = nil
    end
    if self.detailwidget then
        self.detail:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end

    local info = {}

    if BTNINDEX[self.tab] and CONTENT[BTNINDEX[self.tab]] and CONTENT[BTNINDEX[self.tab]][self.typecheck] then
        for key, value in pairs(CONTENT[BTNINDEX[self.tab]][self.typecheck]) do
            local t = deepcopy(value)
            t.index = key
            table.insert(info, t)
        end
    end

    self.scrollinggrid = self.main:AddChild(self:BuildScrollingGrid(info, appearance))
    self.scrollinggrid:SetPosition(-182, -5)
    if appearance then
        self.scrollinggrid:SetPosition(-175, -10)
    end
end

function Wiki:LoadSkinDetail(data)
    if self.detailwidget then
        self.detail:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end

    self.detailwidget = self.detail:AddChild(Widget("detailwidget"))

    local bg = self.detailwidget:AddChild(Image(WIKIRESOURCE.SKIN_BG[1], WIKIRESOURCE.SKIN_BG[2]))
    bg:SetScale(0.65)
    bg:SetPosition(210, 45)

    local name = self.detailwidget:AddChild(Text(DEFAULTFONT, 28, data.name, SKINCOLOUR[data.quality or "BLUE"]))
    name:SetPosition(215, 212)

    local anim = self.detailwidget:AddChild(UIAnim())
    anim:GetAnimState():SetBank(data.bank)
    anim:GetAnimState():SetBuild(data.build)
    anim:GetAnimState():PushAnimation(data.anim or "idle", false)
    anim:GetAnimState():HideSymbol("slot")
    anim:SetPosition(215, data.height or 30)
    anim:SetScale(data.scale or 0.3)

    local info = self.detailwidget:AddChild(Text(HEADERFONT, 18, data.desc, RGB(118, 89, 49)))
    info:SetPosition(215, -65)
    info:SetHAlign(ANCHOR_LEFT)
    info:SetVAlign(ANCHOR_TOP)
    info:SetRegionSize(200, 80)
    info:EnableWordWrap(true)

    local prefabname = self.detailwidget:AddChild(Text(DEFAULTFONT, 28, string.format("*%s*", data.prefabname), RGB(118, 89, 49)))
    prefabname:SetPosition(215, -120)
end

-- 右侧详情页
function Wiki:LoadDetail(data, type)
    if self.detailwidget then
        self.detail:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end

    self.detailwidget = self.detail:AddChild(Widget("detailwidget"))

    -- 有单独整页介绍的物品
    if data.haspage then
        local bg = self.detailwidget:AddChild(Image(self:GetContentResources(self.tab, self.typecheck, data.index, true)))
        bg:SetScale(0.65)
        bg:SetPosition(220, 50)
        return
    end

    -- 有大图介绍的物品
    if data.hasimg then
        local bg = self.detailwidget:AddChild(Image(WIKIRESOURCE.FOOD_BG[1], WIKIRESOURCE.FOOD_BG[2]))
        bg:SetScale(0.65)
        bg:SetPosition(210, 50)

        local img = self.detailwidget:AddChild(Image(self:GetContentResources(self.tab, self.typecheck, data.index, false,
            true)))
        img:SetScale(0.45)
        img:SetPosition(210, 160)

        local name = self.detailwidget:AddChild(Text(DEFAULTFONT, 32, data.name, RGB(118, 89, 49)))
        name:SetPosition(215, 95)

        if data.recipe then
            for index, value in ipairs(data.recipe) do
                local img1 = self.detailwidget:AddChild(Image(GetInventoryItemAtlas(value[1] .. ".tex"),
                    value[1] .. ".tex"))
                img1:SetScale(0.65)
                img1:SetPosition(index * 67 + 53, 20)
                img1:SetHoverText(STRINGS.NAMES[string.upper(value[1])])

                local neednum = self.detailwidget:AddChild(Text(DEFAULTFONT, 20, value[2], RGB(255, 255, 255)))
                neednum:SetPosition(index * 67 + 54, -20)
            end
        end

        local info = self.detailwidget:AddChild(Text(HEADERFONT, 18, data.sd, RGB(118, 89, 49)))
        info:SetPosition(210, -120)
        info:SetHAlign(ANCHOR_LEFT)
        info:SetVAlign(ANCHOR_TOP)
        info:SetRegionSize(200, 80)
        info:EnableWordWrap(true)
        return
    end

    local bg = self.detailwidget:AddChild(Image(WIKIRESOURCE.DETAILBG_BASE[1], WIKIRESOURCE.DETAILBG_BASE[2]))
    bg:SetScale(0.65)
    bg:SetPosition(210, 55)

    local name = self.detailwidget:AddChild(Text(DEFAULTFONT, 37, data.name, RGB(118, 89, 49)))
    name:SetPosition(218, 204)

    local name_small = self.detailwidget:AddChild(Text(DEFAULTFONT, 28, data.type, RGB(118, 89, 49)))
    name_small:SetPosition(218, 162)

    self.infowidget = self.detailwidget:AddChild(Widget("infowidget"))

    local detail

    if type == 1 then
        if data.ys then
            -- 野生
            detail = data.ys
            local btn = self.infowidget:AddChild(ImageButton(WIKIRESOURCE.BTN_TYPE[1], WIKIRESOURCE.BTN_TYPE[2]))
            btn:SetPosition(295, 140)
            btn:SetScale(0.6, 0.6)
            btn:SetFocusScale(1.03, 1.03)
            btn:SetOnClick(function()
                self:LoadDetail(data, 1)
            end)
            local btn_text = btn:AddChild(Image(WIKIRESOURCE.TYPE_YS[1], WIKIRESOURCE.TYPE_YS[2]))
            btn_text:SetPosition(0, -15)

            local btn2 = self.infowidget:AddChild(ImageButton(WIKIRESOURCE.BTN_TYPE_DARK[1],
                WIKIRESOURCE.BTN_TYPE_DARK[2]))
            btn2:SetPosition(345, 140)
            btn2:SetScale(0.6, 0.6)
            btn2:SetFocusScale(1.03, 1.03)
            btn2:SetOnClick(function()
                self:LoadDetail(data, 2)
            end)
            if data.jy then
                local btn2_text = btn2:AddChild(Image(WIKIRESOURCE.TYPE_JY_DARK[1], WIKIRESOURCE.TYPE_JY_DARK[2]))
                btn2_text:SetPosition(0, -15)
            elseif data.yz then
                local btn2_text = btn2:AddChild(Image(WIKIRESOURCE.TYPE_YZ_DARK[1], WIKIRESOURCE.TYPE_YZ_DARK[2]))
                btn2_text:SetPosition(0, -15)
            elseif data.zj then
                local btn2_text = btn2:AddChild(Image(WIKIRESOURCE.TYPE_ZJ_DARK[1], WIKIRESOURCE.TYPE_ZJ_DARK[2]))
                btn2_text:SetPosition(0, -15)
            end
        elseif data.base then
            detail = data.base
        end
    elseif type == 2 then
        if data.jy then
            -- 家养
            detail = data.jy
            local btn = self.infowidget:AddChild(ImageButton(WIKIRESOURCE.BTN_TYPE_DARK[1], WIKIRESOURCE.BTN_TYPE_DARK
                [2]))
            btn:SetPosition(295, 140)
            btn:SetScale(0.6, 0.6)
            btn:SetFocusScale(1.03, 1.03)
            btn:SetOnClick(function()
                self:LoadDetail(data, 1)
            end)
            local btn_text = btn:AddChild(Image(WIKIRESOURCE.TYPE_YS_DARK[1], WIKIRESOURCE.TYPE_YS_DARK[2]))
            btn_text:SetPosition(0, -15)

            local btn2 = self.infowidget:AddChild(ImageButton(WIKIRESOURCE.BTN_TYPE[1], WIKIRESOURCE.BTN_TYPE[2]))
            btn2:SetPosition(345, 140)
            btn2:SetScale(0.6, 0.6)
            btn2:SetFocusScale(1.03, 1.03)
            btn2:SetOnClick(function()
                self:LoadDetail(data, 2)
            end)
            local btn2_text = btn2:AddChild(Image(WIKIRESOURCE.TYPE_JY[1], WIKIRESOURCE.TYPE_JY[2]))
            btn2_text:SetPosition(0, -15)
        elseif data.yz then
            -- 移植
            detail = data.yz
            local btn = self.infowidget:AddChild(ImageButton(WIKIRESOURCE.BTN_TYPE_DARK[1], WIKIRESOURCE.BTN_TYPE_DARK
                [2]))
            btn:SetPosition(295, 140)
            btn:SetScale(0.6, 0.6)
            btn:SetFocusScale(1.03, 1.03)
            btn:SetOnClick(function()
                self:LoadDetail(data, 1)
            end)
            local btn_text = btn:AddChild(Image(WIKIRESOURCE.TYPE_YS_DARK[1], WIKIRESOURCE.TYPE_YS_DARK[2]))
            btn_text:SetPosition(0, -15)

            local btn2 = self.infowidget:AddChild(ImageButton(WIKIRESOURCE.BTN_TYPE[1], WIKIRESOURCE.BTN_TYPE[2]))
            btn2:SetPosition(345, 140)
            btn2:SetScale(0.6, 0.6)
            btn2:SetFocusScale(1.03, 1.03)
            btn2:SetOnClick(function()
                self:LoadDetail(data, 2)
            end)
            local btn2_text = btn2:AddChild(Image(WIKIRESOURCE.TYPE_YZ[1], WIKIRESOURCE.TYPE_YZ[2]))
            btn2_text:SetPosition(0, -15)
        elseif data.zj then
            -- 自建
            detail = data.zj
            local btn = self.infowidget:AddChild(ImageButton(WIKIRESOURCE.BTN_TYPE_DARK[1], WIKIRESOURCE.BTN_TYPE_DARK
                [2]))
            btn:SetPosition(295, 140)
            btn:SetScale(0.6, 0.6)
            btn:SetFocusScale(1.03, 1.03)
            btn:SetOnClick(function()
                self:LoadDetail(data, 1)
            end)
            local btn_text = btn:AddChild(Image(WIKIRESOURCE.TYPE_YS_DARK[1], WIKIRESOURCE.TYPE_YS_DARK[2]))
            btn_text:SetPosition(0, -15)

            local btn2 = self.infowidget:AddChild(ImageButton(WIKIRESOURCE.BTN_TYPE[1], WIKIRESOURCE.BTN_TYPE[2]))
            btn2:SetPosition(345, 140)
            btn2:SetScale(0.6, 0.6)
            btn2:SetFocusScale(1.03, 1.03)
            btn2:SetOnClick(function()
                self:LoadDetail(data, 2)
            end)
            local btn2_text = btn2:AddChild(Image(WIKIRESOURCE.TYPE_ZJ[1], WIKIRESOURCE.TYPE_ZJ[2]))
            btn2_text:SetPosition(0, -15)
        end
    end

    if detail then
        local img_1_atlas, img_1_tex = WIKIRESOURCE.INFO_SC[1], WIKIRESOURCE.INFO_SC[2]
        local info_1_text = detail.sc
        if detail.kj then
            img_1_atlas, img_1_tex = WIKIRESOURCE.INFO_KJ[1], WIKIRESOURCE.INFO_KJ[2]
            info_1_text = detail.kj
        end
        local img_1 = self.infowidget:AddChild(Image(img_1_atlas, img_1_tex))
        img_1:SetScale(0.65, 0.65)
        img_1:SetPosition(110, 104)

        local info_1 = self.infowidget:AddChild(Text(HEADERFONT, 18, info_1_text, RGB(118, 89, 49)))
        info_1:SetPosition(213, 57)
        info_1:SetHAlign(ANCHOR_LEFT)
        info_1:SetVAlign(ANCHOR_TOP)
        info_1:SetRegionSize(200, 70)
        info_1:EnableWordWrap(true)


        local img_2_atlas, img_2_tex = WIKIRESOURCE.INFO_SD[1], WIKIRESOURCE.INFO_SD[2]
        local info_2_text = detail.sd
        if detail.pf then
            img_2_atlas, img_2_tex = WIKIRESOURCE.INFO_PF[1], WIKIRESOURCE.INFO_PF[2]
            info_2_text = detail.pf
        end

        local img_2 = self.infowidget:AddChild(Image(img_2_atlas, img_2_tex))
        img_2:SetScale(0.65, 0.65)
        img_2:SetPosition(110, 40)

        local info_2 = self.infowidget:AddChild(Text(HEADERFONT, 18, info_2_text, RGB(118, 89, 49)))
        info_2:SetPosition(213, -6)
        info_2:SetHAlign(ANCHOR_LEFT)
        info_2:SetVAlign(ANCHOR_TOP)
        info_2:SetRegionSize(200, 70)
        info_2:EnableWordWrap(true)

        local img_3_atlas, img_3_tex = WIKIRESOURCE.INFO_TX[1], WIKIRESOURCE.INFO_TX[2]
        local info_3_text = detail.tx
        if detail.gn then
            img_3_atlas, img_3_tex = WIKIRESOURCE.INFO_GN[1], WIKIRESOURCE.INFO_GN[2]
            info_3_text = detail.gn
        end
        local img_3 = self.infowidget:AddChild(Image(img_3_atlas, img_3_tex))
        img_3:SetScale(0.65, 0.65)
        img_3:SetPosition(110, -34)

        local info_3 = self.infowidget:AddChild(Text(HEADERFONT, 18, info_3_text, RGB(118, 89, 49)))
        info_3:SetPosition(213, -89)
        info_3:SetHAlign(ANCHOR_LEFT)
        info_3:SetVAlign(ANCHOR_TOP)
        info_3:SetRegionSize(200, 90)
        info_3:EnableWordWrap(true)
    end



    -- if self.tab ~= 7 then
    --     local img = self.detailwidget:AddChild(Image(self:GetContentResources(self.tab, data.index)))
    --     img:SetPosition(285, 175)
    -- end
end

function Wiki:BuildSkinScrollingGrid(info)
    local function MakeProductWidget(context, index)
        local w = Widget("product")

        w.item = w:AddChild(ImageButton(WIKIRESOURCE.SKIN_SLOT[1], WIKIRESOURCE.SKIN_SLOT[2]))
        w.item:SetPosition(0, 0, 0)
        w.item:SetScale(0.62, 0.62)
        w.item:SetFocusScale(1.03, 1.03)
        w.item_image = w.item:AddChild(Image())
        w.item_image:SetPosition(0, -8)
        -- w.item_image:SetScale(0.35, 0.35, 0.35)
        -- w.item_image:SetTint(1, 1, 1, 0.3)

        w:Hide()

        return w
    end

    local function ApplyDataToWidget(context, widget, data, index)
        widget.data = data
        if data ~= nil then
            widget:Show()
            if data.atlas and data.image then
                widget.item_image:SetTexture(data.atlas, data.image .. ".tex")
            end
            if data.have then
                widget.item_image:SetTint(1, 1, 1, 1)
                widget:SetHoverText(data.name)
            else
                widget.item_image:SetTint(1, 1, 1, 0.5)
                widget:SetHoverText(data.name .. "（未解锁）")
            end
            widget.item:SetOnClick(function()
                self:LoadSkinDetail(data)
            end)
        else
            widget:Hide()
        end
    end

    local grid = TEMPLATES.ScrollingGrid({}, {
        context                 = {},
        widget_width            = 75,
        widget_height           = 96,
        num_visible_rows        = 3,
        num_columns             = 3,
        item_ctor_fn            = MakeProductWidget,
        apply_fn                = ApplyDataToWidget,
        scrollbar_offset        = 20,
        scrollbar_height_offset = 0,
        allow_bottom_empty_row  = true,
        force_peek              = true
    })

    grid.up_button:SetTextures(WIKIRESOURCE.ARROW[1], WIKIRESOURCE.ARROW[2])
    grid.up_button:SetScale(0.65)
    grid.up_button:SetPosition(grid.up_button:GetPosition().x - 275, grid.up_button:GetPosition().y - 10, 0)

    grid.down_button:SetTextures(WIKIRESOURCE.ARROW[1], WIKIRESOURCE.ARROW[2])
    grid.down_button:SetScale(-0.65)
    grid.down_button:SetPosition(grid.down_button:GetPosition().x - 275, grid.down_button:GetPosition().y + 10, 0)

    grid.scroll_bar_line:SetTexture(WIKIRESOURCE.SCROLL_BAR[1], WIKIRESOURCE.SCROLL_BAR[2])
    grid.scroll_bar_line:SetScale(0.65)
    grid.scroll_bar_line:SetPosition(grid.scroll_bar_line:GetPosition().x - 275, grid.scroll_bar_line:GetPosition().y, 0)


    grid.position_marker:SetTextures(WIKIRESOURCE.POSITION_MARKER[1], WIKIRESOURCE.POSITION_MARKER[2])
    grid.position_marker:SetScale(.65)
    -- grid.position_marker:SetPosition(grid.position_marker:GetPosition().x - 260, grid.position_marker:GetPosition().y, 0)

    local OldSetPosition = grid.position_marker.SetPosition
    if OldSetPosition then
        grid.position_marker.SetPosition = function(self, pos, y, z)
            if type(pos) == "number" then
                pos = grid.scroll_bar_line:GetPosition().x
                OldSetPosition(self, pos, y, z or 0)
            else
                pos.x = grid.scroll_bar_line:GetPosition().x
                OldSetPosition(self, pos)
            end
        end
    end

    grid:SetItemsData(info)

    return grid
end

-- 构建料理列表滚动区域
function Wiki:BuildScrollingGrid(info, appearance)
    local function MakeProductWidget(context, index)
        local w = Widget("product")

        w.item = w:AddChild(ImageButton(WIKIRESOURCE.SLOT[1], WIKIRESOURCE.SLOT[2]))
        if appearance then
            if self.tab == 2 then
                w.item:SetTextures(WIKIRESOURCE.SLOT2[1], WIKIRESOURCE.SLOT2[2])
            elseif self.tab == 3 then
                w.item:SetTextures(WIKIRESOURCE.SLOT3[1], WIKIRESOURCE.SLOT3[2])
            end
        end
        w.item:SetPosition(0, 0, 0)
        w.item:SetScale(0.62, 0.62)
        w.item:SetFocusScale(1.03, 1.03)
        w.item_image = w.item:AddChild(Image())
        if appearance then
            w.item_image:SetPosition(0, -5)
        end
        -- w.item_image:SetScale(0.35, 0.35, 0.35)
        -- w.item_image:SetTint(1, 1, 1, 0.3)

        w:Hide()

        return w
    end

    local function ApplyDataToWidget(context, widget, data, index)
        widget.data = data
        if data ~= nil then
            widget:Show()
            if data.index ~= nil then
                local atlas, img = self:GetContentResources(self.tab, self.typecheck, data.index)
                widget:SetHoverText(data.name)
                if atlas and img then
                    widget.item_image:SetTexture(atlas, img)
                end
            end
            widget.item:SetOnClick(function()
                self:LoadDetail(data, 1)
            end)
        else
            widget:Hide()
        end
    end

    local grid = TEMPLATES.ScrollingGrid({}, {
        context                 = {},
        widget_width            = appearance and 75 or 60,
        widget_height           = appearance and 96 or 65,
        num_visible_rows        = appearance and 3 or 5,
        num_columns             = appearance and 3 or 4,
        item_ctor_fn            = MakeProductWidget,
        apply_fn                = ApplyDataToWidget,
        scrollbar_offset        = 20,
        scrollbar_height_offset = 0,
        allow_bottom_empty_row  = true,
        force_peek              = true
    })

    grid.up_button:SetTextures(WIKIRESOURCE.ARROW[1], WIKIRESOURCE.ARROW[2])
    grid.up_button:SetScale(0.65)
    grid.up_button:SetPosition(grid.up_button:GetPosition().x - 275, grid.up_button:GetPosition().y - 10, 0)

    grid.down_button:SetTextures(WIKIRESOURCE.ARROW[1], WIKIRESOURCE.ARROW[2])
    grid.down_button:SetScale(-0.65)
    grid.down_button:SetPosition(grid.down_button:GetPosition().x - 275, grid.down_button:GetPosition().y + 10, 0)

    grid.scroll_bar_line:SetTexture(WIKIRESOURCE.SCROLL_BAR[1], WIKIRESOURCE.SCROLL_BAR[2])
    grid.scroll_bar_line:SetScale(0.65)
    grid.scroll_bar_line:SetPosition(grid.scroll_bar_line:GetPosition().x - 275, grid.scroll_bar_line:GetPosition().y, 0)


    grid.position_marker:SetTextures(WIKIRESOURCE.POSITION_MARKER[1], WIKIRESOURCE.POSITION_MARKER[2])
    grid.position_marker:SetScale(.65)
    -- grid.position_marker:SetPosition(grid.position_marker:GetPosition().x - 260, grid.position_marker:GetPosition().y, 0)

    local OldSetPosition = grid.position_marker.SetPosition
    if OldSetPosition then
        grid.position_marker.SetPosition = function(self, pos, y, z)
            if type(pos) == "number" then
                pos = grid.scroll_bar_line:GetPosition().x
                OldSetPosition(self, pos, y, z or 0)
            else
                pos.x = grid.scroll_bar_line:GetPosition().x
                OldSetPosition(self, pos)
            end
        end
    end

    grid:SetItemsData(info)

    return grid
end

function Wiki:PreShow()
    self:ChangeTab(1)
    self:Show()
end

function Wiki:PreHide()
    if self.scrollinggrid then
        self.main:RemoveChild(self.scrollinggrid)
        self.scrollinggrid:Kill()
        self.scrollinggrid = nil
    end
    if self.detailwidget then
        self.detail:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end
    self:Hide()
end

-- function Wiki:OnGainFocus()
--     -- self.camera_controllable_reset = TheCamera:IsControllable()
--     -- TheCamera:SetControllable(false)

--     Wiki._base.OnLoseFocus(self)
--     TheCamera:SetControllable(false)
-- end

-- function Wiki:OnLoseFocus()
--     -- TheCamera:SetControllable(self.camera_controllable_reset)

--     Wiki._base.OnLoseFocus(self)
--     TheCamera:SetControllable(true)
-- end

function Wiki:OnControl(control, down)
    if self._base.OnControl(self, control, down) then
        return true
    end
    if not down then
        if control == CONTROL_PAUSE or control == CONTROL_CANCEL then
            self:PreHide()
        end
    end
    return true
end

return Wiki
