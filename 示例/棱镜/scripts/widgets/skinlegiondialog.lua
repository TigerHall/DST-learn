local Widget = require "widgets/widget"
-- local Screen = require "widgets/screen"
-- local AnimButton = require "widgets/animbutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
-- local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/templates"
local TEMPLATES2 = require "widgets/redux/templates"
local ItemImage = require "widgets/redux/itemimage"
local ScrollableList = require "widgets/scrollablelist"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TrueScrollArea = require "widgets/truescrollarea"
local UIAnim = require "widgets/uianim"
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local pas = { version = "7.5.5" }
local TEST = false

local ischinese = CONFIGS_LEGION.LANGUAGES == "chinese"
local SkinStrings = ischinese and {
    UNKNOWN_STORY = "这个故事不值一提。",
    COLLECTION = {
        UNKNOWN = "陌生系列",
        MAGIC = "魔咒系列", --魔法、咒语、巫师
        EMOTICON = "印象系列", --网络表情、梗
        MARBLE = "理石园系列", --欧洲中世纪、古典装饰、宗教
        THANKS = "江湖一枝花系列", --古风、江湖、侠客
        TVPLAY = "N次元系列", --其他有版权的事物
        DISGUISER = "奇妙物语系列", --奇妙世界、自然传奇
        ERA = "古早系列", --古代、化石、考古
        OLDPIC = "念旧系列", --旧稿或重绘
        FANS = "饭制系列", --白饭或粉丝的作品
        COLLECTOR = "星河收藏家系列", --星空、银河、奇异物品
        TASTE = "厨心百味系列", --美食
        LAW = "律系列", --自然法则、物理定律、规则
        DAY = "节典系列", --节日、典礼
        PAPER = "纸忆系列", --折纸、书籍、回忆
        FUTURE = "关于未来系列", --未来、科技、机械
        CRAFT = "巧匠系列", --工艺品、木工、玉石
        TALE = "言如玉系列", --各种童话故事、历险记、传说
        FACT = "非常正常系列", --非常正常，和现实大抵相同
        SUNMOON = "日月同辉系列", --太阳、月亮、发光
        TWIST = "扭曲系列", --邪恶、神秘、克苏鲁、混沌
        JEWEL = "珠光宝气系列", --珠宝、金银、贵气
        FLORAL = "花儿系列", --带有花的
    },
    UI_ACCESS = "获取",
    UI_INPUT_CDK = "请输入兑换码",
    UI_LOAD_CDK = "兑换中...",
    ACCESS = {
        UNKNOWN = "无法获取",
        DONATE = "通过回忆获取",
        FREE = "自动解锁",
        SPECIAL = "通过特殊方式获取",
        REWARD = "链锁奖励",
        LUCK = "幸运眷顾"
    }
} or {
    UNKNOWN_STORY = "The story is not worth mentioning.",
    COLLECTION = {
        UNKNOWN = "Strange Collection",
        MAGIC = "Magic Spell Collection",
        EMOTICON = "Notion Collection",
        MARBLE = "Marble Palace Collection",
        THANKS = "Heartfelt Thanks Collection",
        TVPLAY = "N-dimension Collection",
        DISGUISER = "Wonderful Creatures Collection",
        ERA = "Ancient Era Collection",
        OLDPIC = "Nostalgia Collection",
        FANS = "Fans Creation",
        COLLECTOR = "Galaxy Collector Collection",
        TASTE = "Tastes Collection",
        LAW = "Rule Collection",
        DAY = "Festival Collection",
        PAPER = "Paper Memoir Collection",
        FUTURE = "About Future Collection",
        CRAFT = "Crafts Collection",
        TALE = "Tales Collection",
        FACT = "Reality Collection",
        SUNMOON = "Sun-moon Collection",
        TWIST = "Arrival Collection",
        JEWEL = "Jewels Collection",
        FLORAL = "Flower Collection"
    },
    UI_ACCESS = "Get It",
    UI_INPUT_CDK = "Please enter CDK",
    UI_LOAD_CDK = "Redeeming...",
    ACCESS = {
        UNKNOWN = "Unable to get",
        DONATE = "Get it by memory",
        FREE = "Free access",
        SPECIAL = "Get it by special ways",
        REWARD = "Chain reward",
        LUCK = "Get it by luck"
    }
}

local AnimModels = TEST and { "waxwell" } or {
    "wilson", "willow", "wendy", "wolfgang", "wx78", "wickerbottom", "woodie", "waxwell", "wathgrithr",
    "webber", "winona", "warly", "wes", "walter"
}
local AnimNames = {
    "research", "emoteXL_sad", "emoteXL_annoyed", "emoteXL_happycheer", "emoteXL_waving4",
    "emoteXL_waving1", "emoteXL_waving2", "emoteXL_waving3", "emoteXL_loop_dance0", "emoteXL_bonesaw",
    "emoteXL_facepalm", "emoteXL_kiss", "emote_strikepose"
}

local function SetAnim_base(animstate, v)
    if v.bank then
        animstate:SetBank(v.bank)
    end
    if v.build then
        animstate:SetBuild(v.build)
    end
    if v.anim2 == nil then
        animstate:PlayAnimation(v.anim, v.isloop)
    else
        animstate:PlayAnimation(v.anim)
        animstate:PushAnimation(v.anim2, v.isloop)
    end
end

pas.Click_bush = function(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 1
    local tag_fruit = 0
    if tag == 1 then --枯萎
        animstate:PlayAnimation("idle_to_dead")
        animstate:PushAnimation("dead", false)
    elseif tag == 2 then --成长中
        animstate:PlayAnimation("dead_to_idle")
        animstate:PushAnimation("idle", true)
    elseif tag == 3 then --成熟3
        animstate:PlayAnimation("grow")
        animstate:PushAnimation("idle", true)
        tag_fruit = 3
    elseif tag == 4 then --成熟2
        animstate:PlayAnimation("grow")
        animstate:PushAnimation("idle", true)
        tag_fruit = 2
    elseif tag == 5 then --成熟1
        animstate:PlayAnimation("grow")
        animstate:PushAnimation("idle", true)
        tag_fruit = 1
        tag = 0
    else
        tag = 0
    end
    if tag_fruit == 0 then
        if data.fruitform then
            animstate:ClearOverrideSymbol("bush_berry_build")
        else
            animstate:Hide("berries")
            animstate:Hide("berriesmore")
            animstate:Hide("berriesmost")
        end
    elseif tag_fruit == 1 then
        if data.fruitform then
            animstate:OverrideSymbol("bush_berry_build", data.build, "bush1")
        else
            animstate:Show("berries")
            animstate:Hide("berriesmore")
            animstate:Hide("berriesmost")
        end
    elseif tag_fruit == 2 then
        if data.fruitform then
            animstate:OverrideSymbol("bush_berry_build", data.build, "bush2")
        else
            animstate:Hide("berries")
            animstate:Show("berriesmore")
            animstate:Hide("berriesmost")
        end
    elseif tag_fruit == 3 then
        if data.fruitform then
            animstate:OverrideSymbol("bush_berry_build", data.build, "bush3")
        else
            animstate:Hide("berries")
            animstate:Hide("berriesmore")
            animstate:Show("berriesmost")
        end
    end
    anim.tag_anim = tag + 1
end
pas.SetAnim_bush = function(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    if data.fruitform then
        animstate:OverrideSymbol("bush_berry_build", data.build, "bush3")
    else
        animstate:Hide("berries")
        animstate:Hide("berriesmore")
    end
    anim.tag_anim = 4
end
pas.SetAnim_bush_d = function(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    anim.tag_anim = 2
end

pas.Click_pot_ww = function(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 0
    animstate:PlayAnimation(anim.potanim1..tostring(tag).."_"..anim.potanim2, anim.loopanim)
    if tag >= 4 then
        anim.tag_anim = 0
    else
        anim.tag_anim = tag + 1
    end
end
pas.SetAnim_pot_ww = function(self, anim, data)
    local animstate = anim:GetAnimState()
    if data.bank then animstate:SetBank(data.bank) end
    if data.build then animstate:SetBuild(data.build) end
    animstate:Hide("basesoil")
    animstate:HideSymbol("abase")

    local anims = {
        { "succulent_picked",5 }, { "foliage",5 }, { "red_cap",2 }, { "green_cap",2 }, { "blue_cap",2 },
        { "moon_cap",2 }, { "albicans_cap",2 },
    }
    local aanim = anims[math.random(#anims)]
    anim.potanim1 = aanim[1]
    anim.potanim2 = math.random(aanim[2])

    local dd = data.dd or {}
    local yy = dd.y or 0
    if dd.fixmap ~= nil and dd.fixmap[anim.potanim1] ~= nil then
        dd = dd.fixmap[anim.potanim1]
        if dd[anim.potanim2] ~= nil then
            dd = dd[anim.potanim2]
        end
    end
    anim.loopanim = dd.loopanim
    anim.tag_anim = data.tag_anim or 0
    animstate:PlayAnimation(anim.potanim1..(anim.tag_anim == 0 and "4_" or "0_")..anim.potanim2, anim.loopanim)

    local pos = anim:GetPosition()
    anim:SetPosition(pos.x, pos.y - ( (dd.y or yy)*data.scale ))
end
pas.dd_pot_ww_world = { y = 10 }
pas.dd_pot_ww_future = {
    y = -35,
    fixmap = {
        succulent_picked = { y = -70, [2] = { y=-25 }, [3] = { y=-25 } },
        foliage = { y = -70, [3] = { y=-60 } }
    }
}
pas.SetAnim_pot_ww_future = function(self, anim, data)
    pas.SetAnim_pot_ww(self, anim, data)
    local animstate = anim:GetAnimState()
    animstate:SetAddColour(22/255, 179/255, 163/255, 0)
end
pas.SetAnim_pot_ww_future_fert = function(self, anim, data)
    local animstate = anim:GetAnimState()
    if data.bank then animstate:SetBank(data.bank) end
    if data.build then animstate:SetBuild(data.build) end
    animstate:PlayAnimation("ft"..tostring(math.random(8)), false)
end

pas.SetAnim_plant_berries = function(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    animstate:OverrideSymbol("fruit1", data.build, "fruit2")
    anim.tag_anim = 0
end
pas.Click_plant_berries = function(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 3
    if tag == 0 then
        animstate:PlayAnimation("dead1", false)
        anim.tag_rand = nil
    elseif tag == 1 then
        animstate:PlayAnimation("level1", true)
    elseif tag == 2 then
        animstate:PlayAnimation("level2", true)
    else
        local rand = anim.tag_rand or tostring(math.random(3))
        animstate:PlayAnimation("level3_"..rand, true)
        if tag >= 4 then
            animstate:OverrideSymbol("fruit1", data.build, "fruit2")
        else
            animstate:ClearOverrideSymbol("fruit1")
        end
    end
    if tag >= 4 then
        anim.tag_anim = 0
    else
        anim.tag_anim = tag + 1
    end
end

local function SetAnim_neverfadebush(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    animstate:Hide("berries")
    animstate:Hide("berriesmore")
    animstate:Hide("berriesmost")
    anim.tag_anim = 3
end
local function SetClick_neverfadebush(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 3

    animstate:PlayAnimation("grow")
    animstate:PushAnimation("idle", true)
    if tag == 3 then
        animstate:Show("berriesmost")
        anim.tag_anim = 4
    else
        animstate:Hide("berriesmost")
        anim.tag_anim = 3
    end
end
local function SetClick_neverfade(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 1

    if tag == 1 then
        animstate:PlayAnimation("idle_broken", false)
        anim.tag_anim = 2
    else
        animstate:PlayAnimation("idle", false)
        anim.tag_anim = 1
    end
end

local function InitPlayerSymbol(animstate, data)
    animstate:Hide("ARM_carry")
    animstate:Hide("HAT")
    animstate:Hide("HAIR_HAT")
    animstate:Show("HAIR_NOHAT")
    animstate:Show("HAIR")
    animstate:Show("HEAD")
    animstate:Hide("HEAD_HAT")
    for _,v in ipairs(data.symbol) do
        animstate:OverrideSymbol(v.symbol, v.build, v.file)
        if v.type == 1 then --普通手持
            animstate:Show("ARM_carry")
            animstate:Hide("ARM_normal")
        elseif v.type == 2 then --普通戴帽
            animstate:Show("HAT")
            animstate:Show("HAIR_HAT")
            animstate:Hide("HAIR_NOHAT")
            animstate:Hide("HAIR")

            animstate:Hide("HEAD")
            animstate:Show("HEAD_HAT")
        elseif v.type == 3 then --开放戴帽
            animstate:Show("HAT")
            animstate:Hide("HAIR_HAT")
            animstate:Show("HAIR_NOHAT")
            animstate:Show("HAIR")

            animstate:Show("HEAD")
            animstate:Hide("HEAD_HAT")
        elseif v.type == 4 then --头部全覆盖式
            animstate:Show("HAT")
            animstate:Hide("HAIR_NOHAT")
            animstate:Hide("HAIR")

            animstate:Hide("HEAD")
            -- animstate:Show("HEAD_HAT")
            animstate:Hide("HEAD_HAT_NOHELM")
            animstate:Show("HEAD_HAT_HELM")

            animstate:HideSymbol("face")
            animstate:HideSymbol("swap_face")
            animstate:HideSymbol("beard")
            animstate:HideSymbol("cheeks")
        end
    end
end
local function SetAnim_player(self, anim, data)
    local animstate = anim:GetAnimState()
    local model = AnimModels[math.random( #AnimModels )]
    animstate:SetBank("wilson")
    animstate:SetBuild(model)
    local pushanim = AnimNames[math.random( #AnimNames )]
    animstate:PlayAnimation(pushanim)
    animstate:PushAnimation("idle_loop", true)

    InitPlayerSymbol(animstate, data)

    anim.tag_anim = 2
end
local function SetAnim_player2(self, anim, data)
    -- local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 1
    if tag == 1 then
        anim:SetFacing(FACING_DOWN)
    elseif tag == 2 then
        anim:SetFacing(FACING_RIGHT)
    elseif tag == 3 then
        anim:SetFacing(FACING_UP)
    elseif tag == 4 then
        anim:SetFacing(FACING_LEFT)
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end

local function SetAnim_shuck(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 2
    if tag == 1 then
        animstate:PlayAnimation("cocoon_small_hit")
        animstate:PushAnimation("cocoon_small", true)
    elseif tag == 2 then
        animstate:PlayAnimation("cocoon_dead", false)
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end

local function SetAnim_heatrock(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    for _,v in ipairs(data.symbol) do
        if v.ishide then
            animstate:HideSymbol(v.symbol)
        else
            animstate:OverrideSymbol(v.symbol, v.build, v.file)
        end
    end
end
local function SetAnim_heatrock2(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag
    if anim.tag_anim == nil then
        tag = data.tag_start or 1
    else
        tag = anim.tag_anim
    end
    animstate:PlayAnimation(tostring(tag), true)
    if tag >= 5 then
        tag = 0
    end
    anim.tag_anim = tag + 1
end
local function SetAnim_icire_rock_day(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)

    local filename = ""
    if data.tag == 1 then
        filename = math.random() < 0.5 and "flake_crystal" or "flake_snow"
    elseif data.tag == 2 then
        filename = "flake_snow"
    elseif data.tag == 4 then
        filename = math.random() < 0.5 and "flake_leaf" or "flake_leaf2"
    elseif data.tag == 5 then
        filename = math.random() < 0.5 and "flake_dust" or "flake_ash"
    end
    animstate:OverrideSymbol("snowflake", "icire_rock_day", filename)
end

local function SetAnim_sivturn(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag
    if anim.tag_anim == nil then
        tag = data.tag_start or 1
    else
        tag = anim.tag_anim
    end

    if tag == 1 then
        animstate:PlayAnimation("on_to_idle")
        animstate:PushAnimation("idle", true)
        animstate:OverrideSymbol("followed", data.build, "followed1")
    elseif tag == 2 then
        animstate:PlayAnimation("idle_to_on")
        animstate:PushAnimation("on", true)
        animstate:OverrideSymbol("followed", data.build, "followed2")
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end
local function SetAnim_sivturn2(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag
    if anim.tag_anim == nil then
        tag = data.tag_start or 1
    else
        tag = anim.tag_anim
    end

    if tag == 1 then
        animstate:PlayAnimation("on_to_idle")
        animstate:PushAnimation("idle", true)
        animstate:OverrideSymbol("followed", data.build, "followed1")
        animstate:HideSymbol("seat")
    elseif tag == 2 then
        animstate:PlayAnimation("idle_to_on")
        animstate:PushAnimation("on", true)
        animstate:OverrideSymbol("followed", data.build, "followed2")
        animstate:ShowSymbol("seat")
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end

local function SetAnim_sivderivant(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 2

    if tag == 1 then
        animstate:PlayAnimation("lvl3", true)
    elseif tag == 2 then
        animstate:PlayAnimation("lvl2", true)
    elseif tag == 3 then
        animstate:PlayAnimation("lvl1", true)
    elseif tag == 4 then
        animstate:PlayAnimation("lvl0", true)
    elseif tag == 5 then
        animstate:PlayAnimation("lvl3_live", true)
    elseif tag == 6 then
        animstate:PlayAnimation("lvl2_live", true)
    elseif tag == 7 then
        animstate:PlayAnimation("lvl1_live", true)
    elseif tag == 8 then
        animstate:PlayAnimation("lvl0_live", true)
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end

local function SetAnim_backcub(self, anim, data)
    local animstate = anim:GetAnimState()
    animstate:PlayAnimation(data.touchanim)
    animstate:PushAnimation(data.anim2 or data.anim, data.isloop)
end

local function SetAnim_soul_contracts(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag
    if anim.tag_anim == nil then
        tag = 1
    else
        tag = anim.tag_anim
    end

    if tag == 1 then
        animstate:PlayAnimation("proximity_pre")
        animstate:PushAnimation("proximity_loop", true)
    elseif tag == 2 then
        animstate:PlayAnimation("proximity_pst")
        animstate:PushAnimation("idle", false)
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end
local function SetAnim_soul_contracts2(self, anim, data)
    local animstate = anim:GetAnimState()
    animstate:PlayAnimation("use")
    animstate:PushAnimation("proximity_loop", true)
end

local function SetClick_revolvedmoonlight(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 1

    if tag == 1 then
        animstate:PlayAnimation("open")
        animstate:PushAnimation("opened", true)
        anim.tag_anim = 2
    else
        animstate:PlayAnimation("close")
        animstate:PushAnimation("closed", false)
        anim.tag_anim = 1
    end
end

local function SetAnim_sivfeather(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 1

    if tag == 1 then
        animstate:PlayAnimation("sleep_pst")
        animstate:PushAnimation("idle_loop", true)
        anim.tag_anim = 2
    elseif tag == 2 then
        animstate:PlayAnimation("emote_stretch")
        animstate:PushAnimation("idle_loop", true)
        anim.tag_anim = 3
    elseif tag == 3 then
        animstate:PlayAnimation("sleep_pre")
        animstate:PushAnimation("sleep_loop", true)
        anim.tag_anim = 1
    end
end

local function SetAnim_plant_cactus(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    for _,v in ipairs(data.symbol) do
        animstate:OverrideSymbol(v.symbol, v.build, v.file)
    end
end
local function SetClick_plant_cactus(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or data.tag_start
    if tag == nil or tag == 5 then
        animstate:PlayAnimation("dead1")
        anim.tag_anim = 1
    elseif tag == 1 then
        animstate:PlayAnimation("level1_3")
        anim.tag_anim = 2
    elseif tag == 2 then
        animstate:PlayAnimation("level2_3")
        anim.tag_anim = 3
    elseif tag == 3 then
        animstate:PlayAnimation("level3_3")
        anim.tag_anim = 4
    else
        animstate:PlayAnimation("level4_3")
        anim.tag_anim = 5
    end
end

local function SetClick_plant_lightbulb_l_world(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or data.tag_anim
    if tag == nil or tag == 1 then
        animstate:HideSymbol("fruit2")
        animstate:HideSymbol("light2")
        animstate:HideSymbol("stem")
        animstate:ShowSymbol("sprout")
        animstate:PlayAnimation("level3", true)
        anim.tag_anim = 2
    elseif tag == 4 then
        animstate:PlayAnimation("dead1")
        anim.tag_anim = 1
    else
        animstate:ShowSymbol("fruit2")
        animstate:ShowSymbol("light2")
        animstate:ShowSymbol("stem")
        animstate:HideSymbol("sprout")
        if tag == 3 then
            animstate:ClearOverrideSymbol("fruit2")
            animstate:ClearOverrideSymbol("light2")
            anim.tag_anim = 4
        else
            animstate:OverrideSymbol("fruit2", animstate:GetBuild(), "fruit1")
            animstate:OverrideSymbol("light2", animstate:GetBuild(), "light1")
            anim.tag_anim = 3
        end
    end
end
local function SetAnim_plant_lightbulb_l_world(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    SetClick_plant_lightbulb_l_world(self, anim, data)
    animstate:SetFrame(math.random(animstate:GetCurrentAnimationNumFrames()) - 1)
end

local function SetClick_siving_ctl(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 2

    if tag == 2 then
        animstate:PlayAnimation("item")
        anim.tag_anim = 1
    else
        animstate:PlayAnimation("idle")
        anim.tag_anim = 2
    end
end

local function SetClick_soilcrop(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or 5
    if tag == 1 then
        animstate:PlayAnimation("grow_seed")
        animstate:PushAnimation("crop_seed", true)
    elseif tag == 2 then
        animstate:PlayAnimation("grow_sprout")
        animstate:PushAnimation("crop_sprout", true)
    elseif tag == 3 then
        animstate:PlayAnimation("grow_small")
        animstate:PushAnimation("crop_small", true)
    elseif tag == 4 then
        animstate:PlayAnimation("grow_med")
        animstate:PushAnimation("crop_med", true)
    elseif tag == 5 then
        if math.random() < 0.5 then
            animstate:PlayAnimation("grow_full")
            animstate:PushAnimation("crop_full", true)
        else
            animstate:PlayAnimation("grow_oversized")
            animstate:PushAnimation("crop_oversized", true)
            anim.isoversized = true
        end
    elseif tag == 6 then
        if anim.isoversized then
            animstate:PlayAnimation("grow_rot_oversized")
            animstate:PushAnimation("crop_rot_oversized", true)
            anim.isoversized = nil
        else
            animstate:PlayAnimation("grow_rot")
            animstate:PushAnimation("crop_rot", true)
        end
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end
local function SetAnim_soilcrop(self, anim, data)
    local animstate = anim:GetAnimState()
    if data.bank and data.build then
        animstate:SetBank(data.bank)
        animstate:SetBuild(data.build)
    else
        local crops = {
            "pineananas", "asparagus", "garlic", "pumpkin", "corn", "onion", "potato", "durian",
            "dragonfruit", "pomegranate", "eggplant", "tomato", "watermelon", "pepper", "carrot"
        }
        local crop = crops[math.random( #crops )]
        if PLANT_DEFS[crop] == nil then
            crop = "pineananas"
        end
        animstate:SetBank(PLANT_DEFS[crop].bank)
        animstate:SetBuild(PLANT_DEFS[crop].build)
    end
    animstate:OverrideSymbol("soil01", data.soilskin or "siving_soil", "soil04")
    SetClick_soilcrop(self, anim, data)
end

local function SetAnim_refracted_taste_fx(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    animstate:SetBloomEffectHandle("shaders/anim.ksh")
    animstate:SetMultColour(255/255, 222/255, 139/255, 0.7)
end
local colors_refracted_moon = {
    { 52/255, 1, 1 }, { 52/255, 1, 130/255 }, { 189/255, 1, 52/255 }, { 1, 253/255, 52/255 },
    { 1, 187/255, 52/255 }, { 1, 112/255, 52/255 }, { 1, 52/255, 67/255 }, { 1, 52/255, 155/255 },
    { 1, 52/255, 1 }, { 187/255, 52/255, 1 }, { 64/255, 52/255, 1 }, { 52/255, 128/255, 1 }
}
local color_refracted_moon
local num_refracted_moon = 0
local function SetAnim_refracted_moon_fx(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    animstate:HideSymbol("glow")
    animstate:HideSymbol("pb_part")
    animstate:HideSymbol("pb_shad")
    animstate:HideSymbol("SparkleBit")
    if data.framepct ~= nil then
        animstate:SetFrame(math.max(0, math.ceil(animstate:GetCurrentAnimationNumFrames()*data.framepct)-1))
    end
    animstate:SetBloomEffectHandle("shaders/anim.ksh")
    num_refracted_moon = num_refracted_moon + 1
    if num_refracted_moon > 6 then
        num_refracted_moon = 1
        color_refracted_moon = nil
    end
    if color_refracted_moon == nil then
        color_refracted_moon = colors_refracted_moon[math.random(#colors_refracted_moon)]
    end
    if data.nocolor then
        animstate:SetMultColour(1, 1, 1, 0.15)
    else
        animstate:SetMultColour(color_refracted_moon[1], color_refracted_moon[2], color_refracted_moon[3], 0.15)
    end
end

local function SetClick_hidden(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or data.tag_anim
    if tag == 1 then
        animstate:PlayAnimation("open")
        animstate:PushAnimation("opened", true)
    elseif tag == 2 then
        animstate:PlayAnimation("close")
        animstate:PushAnimation("closed", true)
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end
local function SetAnim_hidden(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    if data.issalt then
        animstate:OverrideSymbol("base", data.build or "hiddenmoonlight", "saltbase")
    end
end

local function SetClick_chest_whitewood_craft(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or data.tag_anim
    if tag == nil or tag == 1 then
        animstate:PlayAnimation("open")
        tag = 1
    elseif tag == 2 then
        animstate:PlayAnimation("close")
    elseif tag == 3 then
        animstate:PlayAnimation("burnt")
        tag = 0
    else
        tag = 0
    end
    anim.tag_anim = tag + 1
end
local function SetAnim_chest_whitewood_craft(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    if data.nodeco then
        animstate:HideSymbol("deco")
    end
end

local function SetClick_plant_carrot(self, anim, data)
    local animstate = anim:GetAnimState()
    local tag = anim.tag_anim or data.tag_start

    if tag == nil or tag == 4 then
        animstate:PlayAnimation("dead1")
        anim.tag_anim = 1
    elseif tag == 1 then
        animstate:PlayAnimation("level1", true)
        anim.tag_anim = 2
    elseif tag == 2 then
        animstate:PlayAnimation("level2", true)
        anim.tag_anim = 3
    else
        animstate:PlayAnimation("level3_3", true)
        anim.tag_anim = 4
    end
end

local function SetAnim_agronssword_sun_catk2_fx(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    animstate:HideSymbol("fire_puff_fx")
    animstate:HideSymbol("glow_")
    animstate:SetBloomEffectHandle("shaders/anim.ksh")
    animstate:SetMultColour(255/255, 122/255, 113/255, 0.8)
end
local function SetAnim_agronssword_fx(self, anim, data)
    local animstate = anim:GetAnimState()
    SetAnim_base(animstate, data)
    if data.framepct ~= nil then
        animstate:SetFrame(math.max(0, math.ceil(animstate:GetCurrentAnimationNumFrames()*data.framepct)-1))
    end
    animstate:SetBloomEffectHandle("shaders/anim.ksh")
end

local width_skininfo = 260
local SkinData = {
    rosebush_marble = {
        string = ischinese and {
            collection = "MARBLE", access = "DONATE", descitem = "解锁\"蔷薇花丛\"的皮肤。",
            description = "“什么事？”王后慵懒地挑选着名贵的珠宝首饰，眼皮都不愿抬起一下。一盆夺目的蔷薇被摆在梳妆台上，王后瞥了一眼，见蔷薇开得确实美，有心取一朵添妆。“嘶——”指尖一滴鲜血滑落，眼前突然浮现前日游行时，骑士长剑上滴落的鲜血。国王却对她说，贱民而已。她突然寒从胆边生，退后仔细端详。蔷薇无言，却绽放得猩红恣意。",
        } or {
            collection = "MARBLE", access = "DONATE", descitem = "Unlock \"Rose Bush\" skin.", description = "Emmm."
        },
        height_anim = 160, --动画区域高度。默认150
        anims = {
            {
                bank = "berrybush", build = "rosebush_marble",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush, --fn(self, anim, data) 代替前面参数的自定义操作
                fn_click = pas.Click_bush, --fn(self, anim, data) 设置点击事件
                x = -52, y = 5, scale = 0.32
            },
            {
                bank = "berrybush", build = "rosebush_marble",
                anim = "dead", anim2 = nil, isloop = false,
                fn_anim = pas.SetAnim_bush_d,
                fn_click = pas.Click_bush,
                x = 50, y = 5, scale = 0.32
            }
        }
    },
    rosorns_marble = {
        string = ischinese and {
            collection = "MARBLE", access = "SPECIAL", descitem = "解锁\"带刺蔷薇\"以及入鞘后的皮肤。",
            description = "昔日王后的御剪如今竟然被用来剪去死刑犯的头发，据说这是为了防止刽子手砍头时，受到头发阻力拖泥带水，反而不美。究其原因，是王后修剪花丛时不慎被剪刀扎伤，这才特此给这把剪刀这样的“美差”。如今唯一能证明其身份的就是上面那精致的红蔷花纹，不过如今都被污迹遮住了大半。"
        } or {
            collection = "MARBLE", access = "SPECIAL", descitem = "Unlock \"Rosorns\" skin.", description = "Emmm."
        },
        height_anim = 140, --带角色的高度最好是140起底
        anims = {
            {
                bank = "rosorns_marble", build = "rosorns_marble",
                anim = "idle", anim2 = nil, isloop = false,
                x = -83, y = 0, scale = 0.38
            },
            {
                bank = "rosorns_marble", build = "rosorns_marble",
                anim = "idle_cover", anim2 = nil, isloop = false,
                x = -25, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "rosorns_marble", file = "swap_object", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "boomerang", build = "rosorns_marble_fx",
                anim = "used", anim2 = nil, isloop = false,
                x = -50, y = -40, scale = 0.34
            }
        }
    },
    lilybush_marble = {
        string = ischinese and {
            collection = "MARBLE", access = "DONATE", descitem = "解锁\"蹄莲花丛\"的皮肤。",
            description = "少女坐在马车内，欢喜地看着怀中被精心打理过的蹄莲。阳光穿透层层阴云，照进这暗无天日的城镇，落在这一盆娇嫩的花上，露珠熠熠生辉，隐隐反射出彩虹的光芒，一如今晨那座新落成的哥特式大教堂中那复杂繁华的琉璃透射的光芒一样美丽。偌大的庄园，少女只将花摆在窗前，快乐地起舞，透过窗子依稀可见一街之隔的处刑场，囚犯被关在笼中已成枯骨，垂下的骨指刚好触及窗内蹄莲洁白的花瓣，仿佛拼死都要抚摸这份美好。"
        } or {
            collection = "MARBLE", access = "DONATE", descitem = "Unlock \"Lily Bush\" skin.", description = "Emmm."
        },
        height_anim = 110,
        anims = {
            {
                bank = "berrybush", build = "lilybush_marble",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = pas.Click_bush,
                x = -42, y = 5, scale = 0.32
            },
            {
                bank = "berrybush", build = "lilybush_marble",
                anim = "dead", anim2 = nil, isloop = false,
                fn_anim = pas.SetAnim_bush_d,
                fn_click = pas.Click_bush,
                x = 40, y = 5, scale = 0.32
            }
        }
    },
    lileaves_marble = {
        string = ischinese and {
            collection = "MARBLE", access = "SPECIAL", descitem = "解锁\"蹄莲翠叶\"以及入鞘后的皮肤。",
            description = "他照着少女赠与的蹄莲的样子制了一把大理石长枪，本想建功立业，为国家开疆拓土，却没想到最后挥向的竟然是老鼠和饥肠辘辘苦求进城却不幸感染鼠疫的子民。昔日的铮光发亮的鞘如今已然锈迹斑斑，他虽如今已身获爵位，却也早已说不清那鞘上到底是铁锈还是血锈。"
        } or {
            collection = "MARBLE", access = "SPECIAL", descitem = "Unlock \"Lileaves\" skin.", description = "Emmm."
        },
        height_anim = 145,
        anims = {
            {
                bank = "lileaves_marble", build = "lileaves_marble",
                anim = "idle", anim2 = nil, isloop = false,
                x = -75, y = 0, scale = 0.38
            },
            {
                bank = "lileaves_marble", build = "lileaves_marble",
                anim = "idle_cover", anim2 = nil, isloop = false,
                x = -30, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "lileaves_marble", file = "swap_object", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    orchidbush_marble = {
        string = ischinese and {
            collection = "MARBLE", access = "DONATE", descitem = "解锁\"兰草花丛\"的皮肤。",
            description = "他将一束精心打理过的兰花放入这亲手打造的铁艺花架之中赠与她，一丝微笑渐渐攀上她的嘴角，正如这兰草瀑布般攀援在架子上灿烂动人。然而今日他却收到噩耗，奴隶主要求她在新婚之夜将这束兰花亲自送入奴隶主的庄园。在这个人贱于牲畜的时代，他无力反抗。好在隔壁庄园的奴隶主曾被他挽救于鼠疫之中，便答应买下两人收入自己庄园当差。"
        } or {
            collection = "MARBLE", access = "DONATE", descitem = "Unlock \"Orchid Bush\" skin.", description = "Emmm."
        },
        height_anim = 175,
        anims = {
            {
                bank = "berrybush", build = "orchidbush_marble",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = pas.Click_bush,
                x = -47, y = 0, scale = 0.32
            },
            {
                bank = "berrybush", build = "orchidbush_marble",
                anim = "dead", anim2 = nil, isloop = false,
                fn_anim = pas.SetAnim_bush_d,
                fn_click = pas.Click_bush,
                x = 45, y = 0, scale = 0.32
            }
        }
    },
    orchitwigs_marble = {
        string = ischinese and {
            collection = "MARBLE", access = "SPECIAL", descitem = "解锁\"兰草花穗\"以及入鞘后的皮肤。",
            description = "婚礼虽不隆重却令人心安，如今他为新奴隶主看家护院，她为奴隶主的家眷莳花弄草，新铸的剑配上爱人所赠的兰花配饰，他紧握手中剑，誓死捍卫属于自己的一方安宁。听说隔壁庄园因奴隶暴动，看守松懈，庄园外墙已被涂满大大的“P”字母，（在黑死病时期，p代表不要靠近，有黑死病人）他一语不发，将擦拭好的剑推回剑鞘。"
        } or {
            collection = "MARBLE", access = "SPECIAL", descitem = "Unlock \"Orchitwigs\" skin.", description = "Emmm."
        },
        height_anim = 145,
        anims = {
            {
                bank = "orchitwigs_marble", build = "orchitwigs_marble",
                anim = "idle", anim2 = nil, isloop = false,
                x = -90, y = 0, scale = 0.38
            },
            {
                bank = "orchitwigs_marble", build = "orchitwigs_marble",
                anim = "idle_cover", anim2 = nil, isloop = false,
                x = -30, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "orchitwigs_marble", file = "swap_object", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_heal_projectile", build = "impact_orchid_fx_marble",
                anim = "hit", anim2 = nil, isloop = false,
                x = -50, y = 0, scale = 0.3
            }
        }
    },
    orchidbush_disguiser = {
        string = ischinese and {
            collection = "DISGUISER", access = "SPECIAL", descitem = "解锁\"兰草花丛\"的皮肤。",
            description = "昨夜雨疏风骤，猎人不知所踪，仅留下这片茂盛的兰花丛纪念着曾经的点点滴滴。已不知是多少个春秋，花开花落，鸟去还回，它的等待始终落得一场空。恍惚间风吹过，摆动的兰花像极了猎人的身影，然而它也不知那潇洒果决的狩猎者是否还会归来……",
        } or {
            collection = "DISGUISER", access = "SPECIAL", descitem = "Unlock \"Orchid Bush\" skin.", description = "Emmm."
        },
        height_anim = 105,
        anims = {
            {
                bank = "berrybush2", build = "orchidbush_disguiser",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = pas.Click_bush,
                x = -42, y = 0, scale = 0.32
            },
            {
                bank = "berrybush2", build = "orchidbush_disguiser",
                anim = "dead", anim2 = nil, isloop = false,
                fn_anim = pas.SetAnim_bush_d,
                fn_click = pas.Click_bush,
                x = 40, y = 0, scale = 0.32
            }
        }
    },
    orchitwigs_disguiser = {
        string = ischinese and {
            collection = "DISGUISER", access = "FREE", descitem = "解锁\"兰草花穗\"以及入鞘后的皮肤。",
            description = "花色清浅，嫣粉各异，它隐匿其中，随着环境变化调整隐身衣的颜色，静候时机。若有猎物在此歇脚，它便踮起拟态为兰花瓣的步肢悄然靠近，只待猎物放松警惕，倏然伸出利爪，又消失在粉色的芬芳中。尽管有人批评它菩萨面蛇蝎心，但是待到下一次追猎时，它仍然会全力以赴。",
        } or {
            collection = "DISGUISER", access = "FREE", descitem = "Unlock \"Orchitwigs\" skin.", description = "Emmm."
        },
        height_anim = 155,
        anims = {
            {
                bank = "orchitwigs_disguiser", build = "orchitwigs_disguiser",
                anim = "idle", anim2 = nil, isloop = false,
                x = -83, y = 0, scale = 0.38
            },
            {
                bank = "orchitwigs_disguiser", build = "orchitwigs_disguiser",
                anim = "idle_cover", anim2 = nil, isloop = false,
                x = -30, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "orchitwigs_disguiser", file = "swap_object", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_heal_projectile", build = "impact_orchid_fx_disguiser",
                anim = "hit", anim2 = nil, isloop = false,
                x = -50, y = 0, scale = 0.32
            }
        }
    },
    neverfade_thanks = {
        string = ischinese and {
            collection = "THANKS", access = "SPECIAL", descitem = "解锁\"永不凋零\"、\"永不凋零花丛\"、\"庇佑蝴蝶\"以及入鞘后的皮肤。",
            description = "“话说，这夜京郊外小竹林中，那是充满了肃杀之气，本是人来人往的入城必经之路，此刻却连只鸟儿都没有。只见有一双身影在其中对峙，两人遮步相互打量了半晌，那女子方才立起剑来。这剑可大有名堂，唤作青玉扶伤，通体碧色，光洁如玉，敲之竟闻金铁之声，最厉害之处在于此剑有灵，能够护主。而这女子对面的敌人也是毫不示弱，双手缓缓拔出这雌雄双刀。江湖中人皆知，这习武之人大部分都是右利手，这刀疤脸男子却不同，他自小苦练，终成就双手皆能惯用，这一双雌雄狂刀，雌刀薄，攻在速，取敌不备；雄刀厚，攻在力，更可防守。这两人将武器亮出，霎时间那是天地变色，狂风大作，竹林之中落叶飞舞，竟在刀疤脸上留下一丝血痕，反观那女子衣服也多有破口，原是这两人在用内力较劲。刀疤脸冷笑一声，刀光一闪，就冲上前去，招招皆冲着柳氏的命门而去，这柳氏也不甘示弱，见招拆招，身边青蝶环绕护体，却又见缝插针地进攻刀疤脸的要害，两人正是势均力敌难解难分，然而只听得‘叮咛’一声，玉剑折断，一纤长身影艰难起身，逐渐隐没在渐起的夜雾之中。正是，十年冤案无处诉，玉剑傍身除恶徒！”",
        } or {
            collection = "THANKS", access = "SPECIAL",
            descitem = "Unlock \"Neverfade\", \"Neverfade Bush\", and \"Neverfade Butterfly\" skin.", description = "Emmm."
        },
        height_anim = 270,
        anims = {
            {
                bank = "butterfly", build = "neverfade_butterfly_thanks",
                anim = "take_off", anim2 = "flight_cycle", isloop = true,
                x = -90, y = 145, scale = 0.32
            },
            {
                bank = "neverfadebush_thanks", build = "neverfadebush_thanks",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = SetClick_neverfadebush,
                x = -42, y = 145, scale = 0.32
            },
            {
                bank = "neverfadebush_thanks", build = "neverfadebush_thanks",
                anim = "dead", anim2 = nil, isloop = false,
                fn_anim = SetAnim_neverfadebush,
                fn_click = SetClick_neverfadebush,
                x = 40, y = 145, scale = 0.32
            },
            {
                bank = "butterfly", build = "neverfade_butterfly_thanks",
                anim = "land", anim2 = "idle", isloop = true,
                x = 20, y = 145, scale = 0.32
            },
            {
                bank = "butterfly", build = "neverfade_butterfly_thanks",
                anim = "take_off", anim2 = "idle_flight_loop", isloop = true,
                x = 70, y = 145, scale = 0.32
            },
            {
                bank = "neverfade_thanks", build = "neverfade_thanks",
                anim = "idle", anim2 = nil, isloop = false,
                x = -90, y = 0, scale = 0.38
            },
            {
                bank = "neverfade_thanks", build = "neverfade_thanks",
                anim = "idle_cover", anim2 = nil, isloop = false,
                x = -30, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "neverfade_thanks", file = "normal_swap", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    hat_lichen_emo_que = {
        string = ischinese and {
            collection = "EMOTICON", access = "DONATE", descitem = "解锁\"苔衣发卡\"的皮肤。",
            description = "你知道哲学的基本问题吗？你认为意识和物质的关系是怎样的呢？你是唯心主义者还是唯物主义者？你支持意识能够正确认识物质的可知论，还是意识不能正确认识物质的不可知论呢？你对人类的存在是宇宙增墒这一判断有何看法？你认为人活着的意义是什么？什么？你什么都不知道？",
        } or {
            collection = "EMOTICON", access = "DONATE", descitem = "Unlock \"Lichen Hairpin\" skin.", description = "Emmm."
        },
        height_anim = 145,
        anims = {
            {
                bank = "hat_lichen_emo_que", build = "hat_lichen_emo_que",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 5, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_lichen_emo_que", file = "swap_hat", type = 3 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    hat_lichen_disguiser = {
        string = ischinese and {
            collection = "DISGUISER", access = "FREE", descitem = "解锁\"苔衣发卡\"的皮肤。",
            description = "洋流之下，是暗流涌动的深渊。终年阴暗，偶有一点光明便格外显眼。远处突然出现忽闪忽闪的淡蓝色光点，小小鱼虾们好奇前去追寻。越游越近，突现一张长满尖牙的恐怖大嘴一口咬了下来。",
        } or {
            collection = "DISGUISER", access = "FREE", descitem = "Unlock \"Lichen Hairpin\" skin.", description = "Emmm."
        },
        height_anim = 150,
        anims = {
            {
                bank = "hat_lichen_disguiser", build = "hat_lichen_disguiser",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 7, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_lichen_disguiser", file = "swap_hat", type = 2 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    hat_lichen_emo_3shock = {
        string = ischinese and {
            name = "情绪化", collection = "EMOTICON", access = "SPECIAL", descitem = "解锁\"苔衣发卡\"的5套皮肤。",
            description = "突然间，眼前的景象让我有些惊讶得说不出话来。那种心动，就像是突然被一阵暖风拂过，让整个世界都变得明亮而美好。可随之而来的，却是一种紧张的情绪，就像是踏上未知的路途，不安与期待交织。\n然后，情感如暴风雨一般激荡，那种愤怒仿佛是从心底涌出的怒火，让每个细胞都在生气的烈焰中颤抖。这一系列情绪，像是一场短暂的旋律，快速切换，让生活充满了未知的惊喜与波澜。"
        } or {
            name = "Moody", collection = "EMOTICON", access = "SPECIAL", descitem = "Unlock \"Lichen Hairpin\" skin.",
            description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "hat_lichen_emo_anger", build = "hat_lichen_emo_anger",
                anim = "idle", anim2 = nil, isloop = false,
                x = -34, y = 135, scale = 0.28
            },
            {
                bank = "hat_lichen_emo_sweat", build = "hat_lichen_emo_sweat",
                anim = "idle", anim2 = nil, isloop = false,
                x = 26, y = 135, scale = 0.28
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_lichen_emo_anger", file = "swap_hat", type = 3 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = -68, y = 130, scale = 0.35
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_lichen_emo_sweat", file = "swap_hat", type = 3 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 56, y = 130, scale = 0.35
            },
            {
                bank = "hat_lichen_emo_heart", build = "hat_lichen_emo_heart",
                anim = "idle", anim2 = nil, isloop = false,
                x = -30, y = 50, scale = 0.28
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_lichen_emo_heart", file = "swap_hat", type = 3 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 0, y = 45, scale = 0.35
            },
            {
                bank = "hat_lichen_emo_3shock", build = "hat_lichen_emo_3shock",
                anim = "idle", anim2 = nil, isloop = false,
                x = -34, y = 5, scale = 0.28
            },
            {
                bank = "hat_lichen_emo_shock", build = "hat_lichen_emo_shock",
                anim = "idle", anim2 = nil, isloop = false,
                x = 26, y = 5, scale = 0.28
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_lichen_emo_3shock", file = "swap_hat", type = 3 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = -68, y = 0, scale = 0.35
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_lichen_emo_shock", file = "swap_hat", type = 3 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 56, y = 0, scale = 0.35
            }
        }
    },
    hat_cowboy_tvplay = {
        string = ischinese and {
            collection = "TVPLAY", access = "FREE", descitem = "解锁\"牛仔帽\"的皮肤。",
            description = "卡尔与伙伴一同返回基地途中，因发生争论无心警惕周围，他们拐过树丛时被突然冲出的五个丧尸扑倒。两人慌乱中解决了麻烦。但卡尔突然感到肚子刺痛，掀起衬衣发现自己已被咬伤……年过三十的卡尔梦中惊醒，看了看还在熟睡的妻女，又望了望桌上警徽虽早已脱落但保养还算完好的警帽，感叹还好只是梦一场。",
        } or {
            collection = "TVPLAY", access = "FREE", descitem = "Unlock \"Stetson\" skin.", description = "Emmm."
        },
        height_anim = 150,
        anims = {
            {
                bank = "hat_cowboy_tvplay", build = "hat_cowboy_tvplay",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 10, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_cowboy_tvplay", file = "swap_hat", type = 2 },
                    { symbol = "swap_body", build = "hat_cowboy_tvplay", file = "swap_body", type = nil }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    boltwingout_disguiser = {
        string = ischinese and {
            collection = "DISGUISER", access = "DONATE", descitem = "解锁\"脱壳之翅\"、\"羽化后的壳\"的皮肤。",
            description = "它进化出了一对枯叶般的翅膀。饿了，花丛中有黄叶辗转；恋了，风中有木下双双飞舞；累了，树干上有翠减停留。这不夺人耳目的一生，最终也会悄悄离场。",
        } or {
            collection = "DISGUISER", access = "DONATE", descitem = "Unlock \"Boltwing-out\", \"Post-eclosion Shuck\" skin.",
            description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "spider_cocoon", build = "boltwingout_shuck_disguiser",
                anim = "cocoon_small_hit", anim2 = "cocoon_small", isloop = true,
                fn_click = SetAnim_shuck,
                x = -10, y = 10, scale = 0.35
            },
            {
                bank = "boltwingout_disguiser", build = "boltwingout_disguiser",
                anim = "idle", anim2 = nil, isloop = false,
                x = -70, y = 10, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_body", build = "boltwingout_disguiser", file = "swap_body", type = nil }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 70, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_heal_projectile", build = "boltwingout_fx_disguiser",
                anim = "hit", anim2 = nil, isloop = false,
                x = -10, y = 0, scale = 0.3
            },
        }
    },
    fishhomingtool_awesome_thanks = {
        string = ischinese and {
            collection = "THANKS", access = "SPECIAL",
            descitem = "解锁\"简易打窝饵制作器\"、\"专业打窝饵制作器\"和\"打窝饵\"的皮肤。",
            description = "“书接上回，扶伤剑护主而断，这消息不知怎地不胫而走，而江湖上现今又流传着一个新的消息，说这食铁兽的遗孤已然认扶伤剑持剑者为主。而今扶伤剑再无护主能力，那这食铁兽是否会易主就成了众人茶余饭后最大的谈资。是夜，就看这京城一隅的一方小小茶楼，几人正悄声低语着最新消息，却是各不相同，几人各执一词。殊不知，这茶楼屋顶有一男子头戴斗笠手持一奇形烟斗吞云吐雾，只见他嘴角扯起一抹不屑的笑容，抬手招来黑鹰，将一卷密信放入信筒。至此，这食铁兽被捉进京都衙门内的消息便如同长了翅膀一样飞了出去。当夜丑时，衙门内除了个别看门打盹的官兵一片寂然，突然后院传来悉悉索索的异响。‘哼，上钩了’仔细瞧那墙角黑雾中，一名颓郁男子摘下斗笠，而他身周的云雾似乎有了感应，翻涌得愈发诡谲。这便是，江湖人心难餍足，云烟缭绕不肯渡！”",
        } or {
            collection = "THANKS", access = "SPECIAL",
            descitem = "Unlock \"Fish-homing Bait Maker\", \"Fish-homing Bait Maker+\", and \"Fish-homing Bait\" skin.",
            description = "Emmm."
        },
        height_anim = 280,
        anims = {
            {
                bank = "fishhomingtool_normal_thanks", build = "fishhomingtool_normal_thanks",
                anim = "idle", anim2 = nil, isloop = false,
                x = -70, y = 210, scale = 0.38
            },
            {
                bank = "fishhomingtool_awesome_thanks", build = "fishhomingtool_awesome_thanks",
                anim = "idle", anim2 = nil, isloop = false,
                x = -25, y = 150, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "fishhomingtool_awesome_thanks", file = "swap", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 140, scale = 0.38
            },
            {
                bank = "fishhomingbait_thanks", build = "fishhomingbait_thanks",
                anim = "idle2", anim2 = nil, isloop = false,
                x = -80, y = 75, scale = 0.38
            },
            {
                bank = "fishhomingbait_thanks", build = "fishhomingbait_thanks",
                anim = "idle3", anim2 = nil, isloop = false,
                x = -30, y = 55, scale = 0.38
            },
            {
                bank = "fishhomingbait_thanks", build = "fishhomingbait_thanks",
                anim = "idle1", anim2 = nil, isloop = false,
                x = -65, y = 5, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "fishhomingbait_thanks", file = "swap2", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    fishhomingtool_awesome_taste = {
        string = ischinese and {
            name = "茶之恋", collection = "TASTE", access = "REWARD",
            descitem = "解锁\"简易打窝饵制作器\"、\"专业打窝饵制作器\"和\"打窝饵\"的皮肤。",
            description = "我俩在学校附近的街角开了一家茶饮店，店面不大，种类不多，人手就我们两个。我除了做成品之外，还负责跑外卖，每天忙忙碌碌停停歇歇，过的非常充实。\n店里最热卖的饮品有三款，一款“爱鸭桃桃”，清新桃芳，好似恋之初体验；一款“芋泥百转”，辗转滋味，好似恋之时经历；一款“大橘奶茶”，奶香醇厚，好似恋之后回望来时路的感慨万千。\n我俩的故事起于这家茶饮店，但肯定不会止步于此，我们对未来还有更多期待，还有很多美好事物想要一起体验！"
        } or {
            name = "Tea Heart", collection = "TASTE", access = "REWARD",
            descitem = "Unlock \"Fish-homing Bait Maker\", \"Fish-homing Bait Maker+\", and \"Fish-homing Bait\" skin.",
            description = "Emmm."
        },
        height_anim = 280,
        anims = {
            {
                bank = "fishhomingtool_normal_taste", build = "fishhomingtool_normal_taste",
                anim = "idle", anim2 = nil, isloop = false,
                x = -80, y = 190, scale = 0.38
            },
            {
                bank = "fishhomingtool_awesome_taste", build = "fishhomingtool_awesome_taste",
                anim = "idle", anim2 = nil, isloop = false,
                x = -35, y = 150, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "fishhomingtool_awesome_taste", file = "swap", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 140, scale = 0.38
            },
            {
                bank = "fishhomingbait_taste", build = "fishhomingbait_taste",
                anim = "idle2", anim2 = nil, isloop = false,
                x = -80, y = 75, scale = 0.38
            },
            {
                bank = "fishhomingbait_taste", build = "fishhomingbait_taste",
                anim = "idle3", anim2 = nil, isloop = false,
                x = -30, y = 55, scale = 0.38
            },
            {
                bank = "fishhomingbait_taste", build = "fishhomingbait_taste",
                anim = "idle1", anim2 = nil, isloop = false,
                x = -65, y = 5, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "fishhomingbait_taste", file = "swap1", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            }
        }
    },
    shield_l_log_emo_pride = {
        string = ischinese and {
            collection = "EMOTICON", access = "FREE", descitem = "解锁\"木盾\"的皮肤。",
            description = "多一丝宽容，你就少一份疑惑；多一丝爱心，你就少一份怨恨；多一丝理解，你就少一份紧张。你我都是独一无二，为自己骄傲吧。"
        } or {
            collection = "EMOTICON", access = "FREE", descitem = "Unlock \"Log Shield\" skin.",
            description = "More tolerance, less doubt. More love, less resentment. More understanding, less nervousness. You and I are unique. Be proud of yourself."
        },
        height_anim = 140,
        anims = {
            {
                bank = "shield_l_log_emo_pride", build = "shield_l_log_emo_pride",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 3, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "shield_l_log_emo_pride", file = "swap_shield", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_beetletaur_fx", build = "lavaarena_beetletaur_fx",
                anim = "defend_fx", anim2 = nil, isloop = false,
                x = -50, y = 30, scale = 0.22
            }
        }
    },
    shield_l_log_emo_fist = {
        string = ischinese and {
            collection = "EMOTICON", access = "SPECIAL", descitem = "解锁\"木盾\"的皮肤。",
            description = "观点不一，骂Ta；羡慕嫉妒，恨Ta；没有黑点？监视Ta。不管发生什么，敲起键盘如同打拳，咬文嚼字断章取义也能搞得鸡飞狗跳。非我皆是恶，活在自己的世界，这就是拳的意义。打的就是你，陌生人。"
        } or {
            collection = "EMOTICON", access = "SPECIAL", descitem = "Unlock \"Log Shield\" skin.", description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "shield_l_log_emo_fist", build = "shield_l_log_emo_fist",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 3, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "shield_l_log_emo_fist", file = "swap_shield", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_beetletaur_fx", build = "lavaarena_beetletaur_fx",
                anim = "defend_fx", anim2 = nil, isloop = false,
                x = -45, y = 27, scale = 0.22
            }
        }
    },
    shield_l_log_era = {
        string = ischinese and {
            collection = "ERA", access = "SPECIAL", descitem = "解锁\"木盾\"的皮肤。",
            description = "他们是生命的奇迹，在寒武纪那个物种大爆发的时代，他们不甘籍籍无名，最早进化出了眼睛，试图看清这洪流般的时代，还进化出了坚硬的外壳，保护自己的族群生生不息。可惜的是，他们引以为傲的甲胄最终在三亿年的进化中成为了积重难返的弊端，最终被自然淘汰。平凡的他们常常以背景或被猎杀的对象出现在纪录片中，如同英雄故事里籍籍无名的平民百姓，然而历经三亿年荣辱兴衰的他们却为研究不同时期的自然环境留下了无法估量的价值。"
        } or {
            collection = "ERA", access = "SPECIAL", descitem = "Unlock \"Log Shield\" skin.", description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "shield_l_log_era", build = "shield_l_log_era",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 1, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "shield_l_log_era", file = "swap_shield", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_beetletaur_fx", build = "lavaarena_beetletaur_fx",
                anim = "defend_fx", anim2 = nil, isloop = false,
                x = -45, y = 30, scale = 0.22
            }
        }
    },
    shield_l_sand_era = {
        string = ischinese and {
            collection = "ERA", access = "SPECIAL", descitem = "解锁\"砂之抵御\"的皮肤。",
            description = "在洞穴深处一个不起眼的角落，它孤独着。它的头骨暴露在外，与古旧的头部甲胄融为一体，身体早已腐朽，只留下部分残缺的脊椎。它骨头上道道触目惊心的伤疤诉说着生前如何无数次顽强地抵御捕食者，它的下颌张开，仿佛在拼命呼唤着族群与希望。在生命的尽头，大地之母听见了它最后的低鸣，拥抱并亲吻了它的遗骨。",
        } or {
            collection = "ERA", access = "SPECIAL", descitem = "Unlock \"Desert Defense\" skin.", description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "shield_l_sand_era", build = "shield_l_sand_era",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 1, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "shield_l_sand_era", file = "swap_shield", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_beetletaur_fx", build = "lavaarena_beetletaur_fx",
                anim = "defend_fx", anim2 = nil, isloop = false,
                x = -45, y = 30, scale = 0.22
            }
        }
    },
    shield_l_sand_op = {
        string = ischinese and {
            collection = "OLDPIC", access = "FREE", descitem = "解锁\"砂之抵御\"的皮肤。",
            description = "画完就觉得左右貌似不太整齐，但是都画好，不想再改。现在我绘画时会不时左右翻转来查看画面的问题，也算是一个进步吧。贴图上结合了沙之石的纹路以及大量向外突出的晶石，中间是金块，现在想想金块不足以被摆在中间好像很重要似的。",
        } or {
            collection = "OLDPIC", access = "FREE", descitem = "Unlock \"Desert Defense\" skin.", description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "shield_l_sand_op", build = "shield_l_sand_op",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 3, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "shield_l_sand_op", file = "swap_shield", type = 1 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_beetletaur_fx", build = "lavaarena_beetletaur_fx",
                anim = "defend_fx", anim2 = nil, isloop = false,
                x = -40, y = 33, scale = 0.22
            }
        }
    },
    icire_rock_era = {
        string = ischinese and {
            collection = "ERA", access = "SPECIAL", descitem = "解锁\"鸳鸯石\"的皮肤。",
            description = "一颗苍天大树拔地而起，直冲云霄，然而在这地洞之内更显得蔚为壮观。更奇特的是，继续考察后，我们在树下的枯枝中发现一颗精美的琥珀。仔细清理之下，这才看到里面还有一只不知品类的有翅昆虫，琥珀将其包裹得如此完好，仿佛仍能听到窸窸窣窣的昆虫振翅声，而下一秒它就能活过来飞出琥珀似的。在火把的包围中，琥珀竟然渐渐变色，而其中的昆虫开始发出微弱的光芒，令人诧异的是，我突然感受到了它对生命瞬间凝滞的不甘……",
        } or {
            collection = "ERA", access = "SPECIAL", descitem = "Unlock \"Icire Stone\" skin.", description = "Emmm."
        },
        height_anim = 170,
        anims = {
            { --上
                bank = "heat_rock", build = "heat_rock",
                anim = "3", anim2 = nil, isloop = true,
                tag_start = 4, symbol = {
                    { symbol = "rock", build = "icire_rock_era", file = "rock" },
                    { symbol = "shadow", build = "icire_rock_era", file = "shadow" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_heatrock2,
                x = 0, y = 13+90, scale = 0.38
            },
            { --右1
                bank = "heat_rock", build = "heat_rock",
                anim = "4", anim2 = nil, isloop = true,
                tag_start = 5, symbol = {
                    { symbol = "rock", build = "icire_rock_era", file = "rock" },
                    { symbol = "shadow", build = "icire_rock_era", file = "shadow" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_heatrock2,
                x = 70, y = 13+65, scale = 0.38
            },
            { --右2
                bank = "heat_rock", build = "heat_rock",
                anim = "5", anim2 = nil, isloop = true,
                tag_start = 1, symbol = {
                    { symbol = "rock", build = "icire_rock_era", file = "rock" },
                    { symbol = "shadow", build = "icire_rock_era", file = "shadow" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_heatrock2,
                x = 42, y = 13, scale = 0.38
            },
            { --左1
                bank = "heat_rock", build = "heat_rock",
                anim = "2", anim2 = nil, isloop = true,
                tag_start = 3, symbol = {
                    { symbol = "rock", build = "icire_rock_era", file = "rock" },
                    { symbol = "shadow", build = "icire_rock_era", file = "shadow" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_heatrock2,
                x = -70, y = 13+65, scale = 0.38
            },
            { --左2
                bank = "heat_rock", build = "heat_rock",
                anim = "1", anim2 = nil, isloop = true,
                tag_start = 2, symbol = {
                    { symbol = "rock", build = "icire_rock_era", file = "rock" },
                    { symbol = "shadow", build = "icire_rock_era", file = "shadow" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_heatrock2,
                x = -42, y = 13, scale = 0.38
            }
        }
    },
    icire_rock_collector = {
        string = ischinese and {
            collection = "COLLECTOR", access = "SPECIAL", descitem = "解锁\"鸳鸯石\"的皮肤。",
            description = "我族世代守护占星石，并流传着一个不可思议的秘密。占星石每三百年都会选中一位族人，只有他能读懂占星预言。到那时只要听从星的指导，就能让我族发扬兴盛，摆脱命运安排。然而，距离上一位族人逝去已过快四百年，占星石也只剩隐隐的光。"
        } or {
            collection = "COLLECTOR", access = "SPECIAL", descitem = "Unlock \"Icire Stone\" skin.", description = "Emmm."
        },
        height_anim = 160,
        anims = {
            { --上
                bank = "icire_rock_collector", build = "icire_rock_collector",
                anim = "3", anim2 = nil, isloop = true,
                tag_start = 4,
                fn_click = SetAnim_heatrock2,
                x = 0, y = 13+90, scale = 0.38
            },
            { --右1
                bank = "icire_rock_collector", build = "icire_rock_collector",
                anim = "4", anim2 = nil, isloop = true,
                tag_start = 5,
                fn_click = SetAnim_heatrock2,
                x = 70, y = 13+65, scale = 0.38
            },
            { --右2
                bank = "icire_rock_collector", build = "icire_rock_collector",
                anim = "5", anim2 = nil, isloop = true,
                tag_start = 1,
                fn_click = SetAnim_heatrock2,
                x = 42, y = 13, scale = 0.38
            },
            { --左1
                bank = "icire_rock_collector", build = "icire_rock_collector",
                anim = "2", anim2 = nil, isloop = true,
                tag_start = 3,
                fn_click = SetAnim_heatrock2,
                x = -70, y = 13+65, scale = 0.38
            },
            { --左2
                bank = "icire_rock_collector", build = "icire_rock_collector",
                anim = "1", anim2 = nil, isloop = true,
                tag_start = 2,
                fn_click = SetAnim_heatrock2,
                x = -42, y = 13, scale = 0.38
            }
        }
    },
    lilybush_era = {
        string = ischinese and {
            collection = "ERA", access = "SPECIAL", descitem = "解锁\"蹄莲花丛\"、\"蹄莲翠叶\"以及入鞘后的皮肤。",
            description = "沿着地下河道一路向前，我们在巨大地洞的入口处发现一片蓝色荧光花海，这里的植被花萼巨大，花瓣柔软光滑，金、蓝、紫相隔相接，却不甚芬芳。不知是不是我们的到来惊动了它们，花海仿佛有了生命，从我们身周开始，缓缓催动起波涛，迷幻的色彩摄人心魄，细长的蕨叶互相摩擦，传来木叶婆娑之声，仿佛在轻声欢迎我们的到来。"
        } or {
            collection = "ERA", access = "SPECIAL", descitem = "Unlock \"Lily Bush\", \"Lileaves\" skin.", description = "Emmm."
        },
        height_anim = 280,
        anims = {
            {
                bank = "berrybush2", build = "lilybush_era",
                anim = "dead", anim2 = nil, isloop = false,
                fn_anim = pas.SetAnim_bush_d,
                fn_click = pas.Click_bush,
                x = 65, y = 138, scale = 0.32
            },
            {
                bank = "berrybush2", build = "lilybush_era",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = pas.Click_bush,
                x = -27, y = 138, scale = 0.32
            },
            {
                bank = "lileaves_era", build = "lileaves_era",
                anim = "idle", anim2 = nil, isloop = false,
                x = -83, y = 0, scale = 0.38
            },
            {
                bank = "lileaves_era", build = "lileaves_era",
                anim = "idle_cover", anim2 = nil, isloop = false,
                x = -30, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "lileaves_era", file = "swap_object", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    triplegoldenshovelaxe_era = {
        string = ischinese and {
            name = "叮叮铛铛考古镐", collection = "ERA", access = "SPECIAL", descitem = "解锁\"斧铲-三用型\"、\"斧铲-黄金三用型\"的皮肤。",
            description = "在参加这一次的考古活动前，我们无论如何都想不到接下来我们将有怎样的奇遇。在深山中我们找到了一支新的古老河道，河道与山体相接，可惜被一块顽石堵住，老师和同学们齐心协力，终于在一片叮叮咚咚声中打开了新世界的入口，顺着河道进入山洞，不远处发现了奇怪的图腾，暗示我们顺流而下，越往前走地势便愈发低，而河流中也渐渐出现蓝色的荧光物，终于在河流尽头，我们发现了一片蓝色荧光瀑布和瀑布之下那个神秘的地洞入口。"
        } or {
            name = "Era Explorers", collection = "ERA", access = "SPECIAL",
            descitem = "Unlock \"Triple-shovelaxe\", \"Snazzy Triple-shovelaxe\" skin.", description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "tripleshovelaxe_era", build = "tripleshovelaxe_era",
                anim = "idle", anim2 = nil, isloop = false,
                x = -40, y = 130, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "tripleshovelaxe_era", file = "swap", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 130, scale = 0.38
            },
            {
                bank = "triplegoldenshovelaxe_era", build = "triplegoldenshovelaxe_era",
                anim = "idle", anim2 = nil, isloop = false,
                x = -40, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "triplegoldenshovelaxe_era", file = "swap", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            }
        }
    },
    rosebush_collector = {
        string = ischinese and {
            collection = "COLLECTOR", access = "SPECIAL", descitem = "解锁\"蔷薇花丛\"、\"带刺蔷薇\"以及入鞘后的皮肤。",
            description = "作为银河系最大的军阀统领，从小便渴望权利与力量。他用尽半生精力，终于在极其遥远的星云残骸中找到传说中能贯穿星辰的神剑。他带着贯星剑回到了自己的星球，憧憬着一统宇宙成为唯一的神……\n他高傲自豪地在高台上举起贯星剑，正准备发起向其他银河统领的宣战时，剑体却突然碎裂开来，化作无数金色光束向地面射去。在众人诧异中，地面开始朽化龟裂，水晶般的荆棘开始迅速长出，不断往周围蔓延。整个星球失去了生机，他也在崩坏与腐朽中失踪。",
        } or {
            collection = "COLLECTOR", access = "SPECIAL", descitem = "Unlock \"Rose Bush\", \"Rosorns\" skin.", description = "Emmm."
        },
        height_anim = 320,
        anims = {
            {
                bank = "berrybush", build = "rosebush_collector",
                anim = "dead", anim2 = nil, isloop = false,
                fn_anim = pas.SetAnim_bush_d,
                fn_click = pas.Click_bush,
                x = 45, y = 143, scale = 0.24
            },
            {
                bank = "berrybush", build = "rosebush_collector",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = pas.Click_bush,
                x = -45, y = 143, scale = 0.24
            },
            {
                bank = "rosorns_collector", build = "rosorns_collector",
                anim = "idle", anim2 = nil, isloop = true,
                x = -83, y = 0, scale = 0.38
            },
            {
                bank = "rosorns_collector", build = "rosorns_collector",
                anim = "idle_cover", anim2 = nil, isloop = true,
                x = -30, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "rosorns_collector", file = "swap_object", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            },
            {
                bank = "lavaarena_heal_projectile", build = "rosorns_collector_fx",
                anim = "cast", anim2 = nil, isloop = false,
                x = -30, y = 10, scale = 0.4
            }
        }
    },
    fimbul_axe_collector = {
        string = ischinese and {
            collection = "COLLECTOR", access = "SPECIAL", descitem = "解锁\"芬布尔斧\"的皮肤。",
            description = "十七年前，盛夏流星群过后，一对夫妻在自己营地附近捡到一名戴着星星吊坠的女婴。现在，女婴已长大，每晚望着璀璨的星空着迷，但夫妻太爱这个孩子，不忍告诉她的来历，并藏起了属于她的吊坠。\n盛夏时节，女孩忽然有某种感应跑到楼顶，原来是流星群再次来临。女孩眼睛瞪得老大，欣赏着这场视觉的盛宴，留下了眼泪。\n夫妻觉得离别的时刻已经到来，把吊坠还给了女孩。吊坠交到女孩手里的那一刻，女孩理解了一切。她跃向天空，在耀眼的光芒过后，化作了流星群的一员飞出目光尽头，留下夫妻二人黯然神伤。\n两年后某个盛夏的夜晚，夫妻二人仍然依照往日习惯在楼顶看星星，此时一颗星星从天上划落，熟悉的少女身影闪现在夫妻眼前，三人默契相拥……"
        } or {
            collection = "COLLECTOR", access = "SPECIAL", descitem = "Unlock \"Fimbul's Axe\" skin.", description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "fimbul_axe_collector", build = "fimbul_axe_collector",
                anim = "idle", anim2 = nil, isloop = false,
                x = -70, y = 130, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "fimbul_axe_collector", file = "swap_base", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 25, y = 130, scale = 0.38
            },
            {
                bank = "fimbul_axe_collector", build = "fimbul_axe_collector",
                anim = "spin_loop", anim2 = nil, isloop = true,
                x = -50, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "fimbul_axe_collector", file = "swap_throw", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            },
            {
                bank = "fimbul_axe_collector3_fx", build = "fimbul_axe_collector3_fx",
                anim = "idle", anim2 = "nil", isloop = false,
                x = -50, y = 0, scale = 0.4
            },
            {
                bank = "explode", build = "fimbul_axe_collector2_fx",
                anim = "small_firecrackers", anim2 = nil, isloop = false,
                x = -50, y = -15, scale = 0.4
            },
            {
                bank = "fimbul_axe_collector", build = "fimbul_axe_collector",
                anim = "star1", anim2 = "nil", isloop = false,
                x = -20, y = 100, scale = 0.4
            },
            {
                bank = "fimbul_axe_collector", build = "fimbul_axe_collector",
                anim = "star3", anim2 = "nil", isloop = false,
                x = -70, y = 80, scale = 0.4
            },
            {
                bank = "fimbul_axe_collector", build = "fimbul_axe_collector",
                anim = "star2", anim2 = "nil", isloop = false,
                x = -55, y = 60, scale = 0.4
            }
        }
    },
    siving_turn_collector = {
        string = ischinese and {
            collection = "COLLECTOR", access = "LUCK", descitem = "解锁\"子圭·育\"的皮肤。",
            description = "自从飞船失控，他被困在这片星漩中已过去3周。他无数次尝试与总部沟通，皆以失败告终。每每失落之际，他都会望着那颗最近的星球，星体一开始如黑洞般深邃，但又会逐渐闪耀起来，如同他的遭遇。“真好，你一直在我身边”，望着这颗美丽的星球他总能重燃信心，“你就是我的希望”。如今弹尽粮绝，飞船内的氧气也低到极限，他瘫倒在甲板，恍惚间，他好像发现很多生物的残骸漂浮在星环中，“为什么3周以来我都没看到过？”，他心生疑问。三周前，飞船突然收到求救讯号，然后他决定脱离航线前去救援，到达救援坐标后，飞船突然失控，那颗暗星也开始了光与暗的循环。在昏迷前，他终于理解这颗星球的秘密，“来吧，来吧，投入我的怀抱……”。昏迷的他，居然打开了舱门，向那颗星球跳去，很快便隐没在星环之中。",
        } or {
            collection = "COLLECTOR", access = "LUCK", descitem = "Unlock \"Siving-Mutator\" skin.", description = "Emmm."
        },
        height_anim = 190,
        anims = {
            {
                bank = "siving_turn_collector", build = "siving_turn_collector",
                anim = "on_to_idle", anim2 = "idle", isloop = true,
                tag_start = 2, symbol = {
                    { symbol = "followed", build = "siving_turn_collector", file = "followed1" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_sivturn,
                x = 60, y = 8, scale = 0.3
            },
            {
                bank = "siving_turn_collector", build = "siving_turn_collector",
                anim = "idle_to_on", anim2 = "on", isloop = true,
                tag_start = 1, symbol = {
                    { symbol = "followed", build = "siving_turn_collector", file = "followed2" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_sivturn,
                x = -60, y = 8, scale = 0.3
            }
        }
    },
    siving_turn_future = {
        string = ischinese and {
            collection = "FUTURE", access = "SPECIAL", descitem = "解锁\"子圭·育\"的皮肤。",
            description = "以后的以后会发生什么，我们总是充满遐想，今天给大家讲个故事，关于未来。\n那时候，人们都依赖高科技已达到近乎长生不老的地步，也没有了更高尚的追求。而且你要知道很多动植物都在人类科技发展过程中灭绝了，甚至包括人类的爱犬，那是一段黑暗的时期，这里就不讲啦，继续讲今天的主题，幸好人类有喜欢存档的习惯，各种或消失或灭绝的动植物基因都被保留了下来。\n一个无聊的民间科学家无意间翻到一张自己祖先抱着一只非常可爱的生物的照片，于是去基因档案所窃取了这个生物的基因，并违规制造了生化打印器。很快，几只可爱的汪汪叫狗狗重现人间，科学家和狗狗玩的很开心呢。不过未来世界很难有不透风的纳米墙，科学家很快就被举报，他的所有成果都被没收，他自己也被关了起来……"
        } or {
            collection = "FUTURE", access = "SPECIAL", descitem = "Unlock \"Siving-Mutator\" skin.", description = "Emmm."
        },
        height_anim = 155,
        anims = {
            {
                bank = "siving_turn_future", build = "siving_turn_future",
                anim = "on_to_idle", anim2 = "idle", isloop = true,
                tag_start = 2, symbol = {
                    { symbol = "followed", build = "siving_turn_future", file = "followed1" },
                    { symbol = "seat", ishide = true }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_sivturn2,
                x = 50, y = 14, scale = 0.25
            },
            {
                bank = "siving_turn_future", build = "siving_turn_future",
                anim = "idle_to_on", anim2 = "on", isloop = true,
                tag_start = 1, symbol = {
                    { symbol = "followed", build = "siving_turn_future", file = "followed2" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_sivturn2,
                x = -65, y = 14, scale = 0.25
            }
        }
    },
    siving_turn_future2 = {
        string = ischinese and {
            collection = "FUTURE", access = "SPECIAL", descitem = "解锁\"子圭·育\"的皮肤。",
            description = "关于未来的故事还有下文。\n近百年来突然掀起一场宠物选美潮流，不时有各种宠物选美大赛冲入人们视野。可能那时人类无聊至极，开始培养新的兴趣。在赛场上，可以看到各种名流展示着自己的爱宠，越是有权有威望人士的爱宠会更加“美丽动人”，但说实话，这些人并不爱他们的爱宠，只是把它当做炫耀的工具。所有宠物都由一家神秘机构负责创造，可根据卖家的想法来培育宠物。机构里有一台改装过的仪器，叫做基因诱变舱。机构人员其实并不是它的建造者，但会用就够了。他们会往里面注入各种动植物的基因，然后链接在一起，短短8小时，便能打印出新的生物。\n有一天一位外星流浪客，带着古老星系的生物基因找到这个神秘机构，机构由于只接受宠物创造，所以不得以将猫的基因也加了进来……于是，在这个洁白的舱体里，第一只全身布满金色星纹，闪着金光的，星猫，诞生了！毫无疑问，外星流浪客带着它赢了很多次选美比赛，他和星猫引起了多次全球轰动，可真是让人羡慕得不行……"
        } or {
            collection = "FUTURE", access = "SPECIAL", descitem = "Unlock \"Siving-Mutator\" skin.", description = "Emmm."
        },
        height_anim = 155,
        anims = {
            {
                bank = "siving_turn_future2", build = "siving_turn_future2",
                anim = "on_to_idle", anim2 = "idle", isloop = true,
                tag_start = 2, symbol = {
                    { symbol = "followed", build = "siving_turn_future2", file = "followed1" },
                    { symbol = "seat", ishide = true }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_sivturn2,
                x = 50, y = 14, scale = 0.25
            },
            {
                bank = "siving_turn_future2", build = "siving_turn_future2",
                anim = "idle_to_on", anim2 = "on", isloop = true,
                tag_start = 1, symbol = {
                    { symbol = "followed", build = "siving_turn_future2", file = "followed2" }
                },
                fn_anim = SetAnim_heatrock,
                fn_click = SetAnim_sivturn2,
                x = -65, y = 14, scale = 0.25
            }
        }
    },
    siving_derivant_thanks = {
        string = ischinese and {
            collection = "THANKS", access = "SPECIAL", descitem = "解锁\"子圭奇型岩\"的2套皮肤。",
            description = "“上回说到，柳氏重伤，扶伤也已玉碎，她拖着残躯跌跌撞撞回到梨花洞，这洞外虽然是郁郁葱葱，却只是普通森林景致，不比里面别有洞天。洞中有几棵奇异的银叶树，散发着青绿色的微光，虽不甚亮堂却堪堪能够照亮整个洞穴。洞穴正中有一阵法，柳氏将断剑插入阵眼，只见银叶树上的微光竟然活泛起来，逐渐向阵眼汇集，刹那间，阵法其光大盛，从阵眼中渐渐生出嫩绿枝芽，攀在剑身，逐渐将整柄剑包裹起来，而那断剑似乎活了般一明一暗地发出白色微光，似在呼吸，剑身上的裂痕也肉眼可见地被修复消失。而柳氏盘腿席地而坐，青光一片中，她身上的伤口也在快速结痂愈合。原来这银叶树名曰青冥梨花树，有生死人肉白骨之效，又与这青玉扶伤剑同宗同源，故而能够医治扶伤剑痕和剑主肉躯。这可真是，玉人妙运天不绝，洞中八卦有乾坤！”"
        } or {
            collection = "THANKS", access = "SPECIAL", descitem = "Unlock all \"Siving Derivant\" skin.", description = "Emmm."
        },
        height_anim = 255,
        anims = {
            {
                bank = "siving_derivant_thanks", build = "siving_derivant_thanks",
                anim = "lvl3", anim2 = nil, isloop = false,
                fn_click = SetAnim_sivderivant,
                x = -60, y = 100, scale = 0.22
            },
            {
                bank = "siving_derivant_thanks2", build = "siving_derivant_thanks2",
                anim = "lvl3", anim2 = nil, isloop = false,
                fn_click = SetAnim_sivderivant,
                x = 0, y = 1, scale = 0.22
            }
        }
    },
    backcub_fans = {
        string = ischinese and {
            collection = "FANS", access = "SPECIAL", descitem = "解锁\"靠背熊\"的皮肤。",
            description = "他叫饭仔，有着简单的几个爱好。吃饭饭，能吃就行；睡觉觉，要抱着他最爱的偶像抱枕才睡得着；不过，他最喜欢的还是给朋友们爱的抱抱。\n--感谢白饭的绘制",
        } or {
            collection = "FANS", access = "SPECIAL", descitem = "Unlock \"Backcub\" skin.", description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "backcub_fans", build = "backcub_fans",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 17, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_body", build = "backcub_fans", file = "swap_body", type = nil }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    backcub_thanks = {
        string = ischinese and {
            collection = "THANKS", access = "SPECIAL", descitem = "解锁\"靠背熊\"的皮肤。",
            description = "“这江湖中早有竹居食铁兽这种奇兽的传闻，言此兽贪食，因而肚量巨大，得之认主后可借兽腹容纳万物。正所谓匹夫无罪，怀璧其罪，很快便有人盯上了它们。当夜竹林中人头攒动，火把几乎照亮了半边天。要说这食铁兽一家也是自然之灵长，为了护幼舍命与猎人们周旋，长者们硬生生抗住漫天箭雨，幼兽方才安然逃出。眼见幼兽逃出天罗地网，老兽们自然更不会俯首称臣，由最年长者带头，只见它们齐齐祭出修炼多年的灵丹，以多年修为引动自爆。那爆炸声惊天动地，毁去了大半竹林，更带走了泰半猎人的性命，剩下的人也只是一息尚存苟延残喘。据说，后来当其他人在他们面前再提起食铁兽时，他们无一不浑身颤抖如临大敌。正所谓父母之爱子，则为之计深远，老兽们正是以壮烈之举彻底打消了后人想猎取它们的幼子的念头，真乃可叹可惜也！而今幼兽孑然一身，举目无亲，只得潜藏于农神山。这农神山因森林茂密，地形奇崛，罕有人迹。不过，这一天，兽子却在农神山山涧发现一名重伤昏迷的女子。这兽子本性纯良，虽经历灭族惨案，仍心怀善念，不欲见有生灵逝于前，便将这女子驮至其藏身的梨花洞，借梨花洞内天地灵气为女子愈合伤口，奇妙的是，这剑竟然也能自主吸取天地精华缓慢修复。女子醒来后出于感谢，用玉竹炼制背篓，容兽子隐息藏身，而在女子养伤过程中，一人一兽逐渐建立了对彼此的信任，遂为兽子起名为浮生儿，一起在洞中修行八年，直到这一日出山。这可谓，浮沉尘世见险恶，生死度外结善缘！”"
        } or {
            collection = "THANKS", access = "SPECIAL", descitem = "Unlock \"Backcub\" skin.", description = "Emmm."
        },
        height_anim = 170,
        anims = {
            {
                bank = "backcub_thanks", build = "backcub_thanks",
                anim = "idle2_water", anim2 = "idle3_water", isloop = true,
                touchanim = "idle5_water",
                fn_click = SetAnim_backcub,
                x = -25, y = 90, scale = 0.36
            },
            {
                bank = "backcub_thanks", build = "backcub_thanks",
                anim = "idle4", anim2 = "idle1", isloop = true,
                touchanim = "idle4",
                fn_click = SetAnim_backcub,
                x = -55, y = 10, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_body", build = "backcub_thanks", file = "swap_body", type = nil }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 65, y = 0, scale = 0.38
            }
        }
    },
    backcub_fans2 = {
        string = ischinese and {
            collection = "FANS", access = "REWARD", descitem = "解锁\"靠背熊\"的皮肤。",
            description = "饭豆子睡着时思想喜欢飘向各处。暴雨来临，孩童们都被雷声吓得噩梦不断。饭豆子放下自己的美梦而去帮助他们改善梦境。一觉醒来，孩子们终记不得它的模样，只记得那沙子般细腻的柔软。\n--感谢白饭的绘制",
        } or {
            collection = "FANS", access = "REWARD", descitem = "Unlock \"Backcub\" skin.", description = "Emmm."
        },
        height_anim = 185,
        anims = {
            {
                bank = "backcub_fans2", build = "backcub_fans2",
                anim = "idle1_water", anim2 = "idle2_water", isloop = true,
                touchanim = "idle1_water",
                fn_click = SetAnim_backcub,
                x = -25, y = 70, scale = 0.36
            },
            {
                bank = "backcub_fans2", build = "backcub_fans2",
                anim = "idle2", anim2 = "idle1", isloop = true,
                touchanim = "idle3",
                fn_click = SetAnim_backcub,
                x = -50, y = 10, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_body", build = "backcub_fans2", file = "swap_body", type = nil }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 65, y = 0, scale = 0.38
            }
        }
    },
    agronssword_taste = {
        string = ischinese and {
            collection = "TASTE", access = "SPECIAL", descitem = "解锁\"艾力冈的剑\"的皮肤。",
            description = "米歇尔凌晨就起床，在厨房和面、醒面、擀面，还用上了烤箱。很快来到早上，丈夫奥多穿着整洁的军装下楼，米歇尔赶紧端上来一大盘法棍，并往法棍上撒上一层糖霜，她知道奥多最喜欢加这个。两人的早餐是糖霜法棍，美味夹杂着别离，因为奥多马上要应征上战场，在如今非常动荡的时期。奥多怀揣家国情怀，觉得这是一份荣耀；米歇尔担心丈夫，期盼他一定要安全归来……"
        } or {
            collection = "TASTE", access = "SPECIAL", descitem = "Unlock \"Agron's Sword\" skin.", description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "agronssword_taste", build = "agronssword_taste",
                anim = "idle", anim2 = nil, isloop = false,
                x = -55, y = 145, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "agronssword_taste", file = "swap1", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 130, scale = 0.38
            },
            { --物1
                bank = "lavaarena_boarrior_fx", build = "agronssword_taste_fx",
                anim = "ground_hit_"..tostring(math.random(2)), anim2 = nil, isloop = true, framepct = 0.75,
                fn_anim = SetAnim_agronssword_fx,
                x = -55, y = 12, scale = 0.38
            },
            { --人1
                bank = "lavaarena_boarrior_fx", build = "agronssword_taste_fx",
                anim = "ground_hit_"..tostring(math.random(2)), anim2 = nil, isloop = true, framepct = 0.5,
                fn_anim = SetAnim_agronssword_fx,
                x = 35, y = 12, scale = 0.38
            },
            {
                bank = "agronssword_taste", build = "agronssword_taste",
                anim = "idle2", anim2 = nil, isloop = false,
                x = -55, y = 12, scale = 0.38
            },
            { --物2
                bank = "lavaarena_boarrior_fx", build = "agronssword_taste_fx",
                anim = "ground_hit_"..tostring(math.random(2)), anim2 = nil, isloop = true,
                fn_anim = SetAnim_agronssword_fx,
                x = -60, y = 12, scale = 0.38
            },
            { --物3
                bank = "lavaarena_boarrior_fx", build = "agronssword_taste_fx",
                anim = "ground_hit_"..tostring(math.random(2)), anim2 = nil, isloop = true, framepct = 0.5,
                fn_anim = SetAnim_agronssword_fx,
                x = -50, y = 17, scale = 0.38
            },
            { --物4
                bank = "lavaarena_boarrior_fx", build = "agronssword_taste_fx",
                anim = "ground_hit_"..tostring(math.random(2)), anim2 = nil, isloop = true, framepct = 0.25,
                fn_anim = SetAnim_agronssword_fx,
                x = -65, y = 6, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "agronssword_taste", file = "swap2", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            },
            { --人2
                bank = "lavaarena_boarrior_fx", build = "agronssword_taste_fx",
                anim = "ground_hit_"..tostring(math.random(2)), anim2 = nil, isloop = true, framepct = 0.75,
                fn_anim = SetAnim_agronssword_fx,
                x = 40, y = 12, scale = 0.38
            },
            { --人3
                bank = "lavaarena_boarrior_fx", build = "agronssword_taste_fx",
                anim = "ground_hit_"..tostring(math.random(2)), anim2 = nil, isloop = true,
                fn_anim = SetAnim_agronssword_fx,
                x = 30, y = 6, scale = 0.38
            },
            { --人4
                bank = "lavaarena_boarrior_fx", build = "agronssword_taste_fx",
                anim = "ground_hit_"..tostring(math.random(2)), anim2 = nil, isloop = true, framepct = 0.25,
                fn_anim = SetAnim_agronssword_fx,
                x = 25, y = 12, scale = 0.38
            },
            {
                bank = "lavaarena_beetletaur_fx", build = "lavaarena_beetletaur_fx",
                anim = "defend_fx", anim2 = nil, isloop = false,
                x = -55, y = 170, scale = 0.22
            },
            {
                bank = "lavaarena_beetletaur_fx", build = "lavaarena_beetletaur_fx",
                anim = "defend_fx", anim2 = nil, isloop = false,
                x = -55, y = 50, scale = 0.22
            }
        }
    },
    agronssword_sun = {
        string = ischinese and {
            collection = "SUNMOON", access = "SPECIAL", descitem = "解锁\"艾力冈的剑\"的皮肤。",
            description = "手持太阳盾的勇者，散发着炽热的光辉，坚固可靠，以勇气面对侵蚀家园的旧日余孽。\n阵阵光点火花溅射，每次看着他被打倒，又倔强地站起身来，仿佛有使不完的力量。然而，就像太阳终将落下，黄昏来临时，勇者力量散尽，坚持不住重重倒下，就要丧命，却见虹光突闪，月之勇者替他挡下致命一击。"
        } or {
            collection = "SUNMOON", access = "SPECIAL", descitem = "Unlock \"Agron's Sword\" skin.", description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "agronssword_sun", build = "agronssword_sun",
                anim = "idle", anim2 = nil, isloop = false,
                x = -55, y = 135, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "agronssword_sun", file = "swap1", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 130, scale = 0.38
            },
            { --物1
                bank = "shadowrift_portal", build = "agronssword_sun_fx",
                anim = "particle_3_loop", anim2 = nil, isloop = true, framepct = 0.6,
                fn_anim = SetAnim_agronssword_fx,
                x = -55, y = 60, scale = 0.38*0.4
            },
            { --人1
                bank = "shadowrift_portal", build = "agronssword_sun_fx",
                anim = "particle_3_loop", anim2 = nil, isloop = true, framepct = 0.5,
                fn_anim = SetAnim_agronssword_fx,
                x = 35, y = 60, scale = 0.38*0.6
            },
            {
                bank = "agronssword_sun", build = "agronssword_sun",
                anim = "idle2", anim2 = nil, isloop = false,
                x = -55, y = 2, scale = 0.38
            },
            { --物2
                bank = "shadowrift_portal", build = "agronssword_sun_fx",
                anim = "particle_3_loop", anim2 = nil, isloop = true,
                fn_anim = SetAnim_agronssword_fx,
                x = -55, y = 40, scale = 0.38*0.5
            },
            { --物3
                bank = "shadowrift_portal", build = "agronssword_sun_fx",
                anim = "particle_3_loop", anim2 = nil, isloop = true, framepct = 0.5,
                fn_anim = SetAnim_agronssword_fx,
                x = -55, y = 10, scale = 0.38*0.4
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "agronssword_sun", file = "swap2", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            },
            { --人2
                bank = "shadowrift_portal", build = "agronssword_sun_fx",
                anim = "particle_3_loop", anim2 = nil, isloop = true, framepct = 0.6,
                fn_anim = SetAnim_agronssword_fx,
                x = 35, y = 10, scale = 0.38*0.5
            },
            { --人3
                bank = "shadowrift_portal", build = "agronssword_sun_fx",
                anim = "particle_3_loop", anim2 = nil, isloop = true,
                fn_anim = SetAnim_agronssword_fx,
                x = 35, y = 40, scale = 0.38*0.6
            },
            {
                bank = "deer_fire_charge", build = "deer_fire_charge",
                anim = "blast", anim2 = nil, isloop = false,
                fn_anim = SetAnim_agronssword_sun_catk2_fx,
                x = -55, y = 175, scale = 0.38*0.8
            },
            {
                bank = "fx_dock_crackleandpop", build = "fx_dock_crackleandpop",
                anim = "pop", anim2 = nil, isloop = false,
                x = -55, y = 165, scale = 0.19
            },
            {
                bank = "deer_fire_charge", build = "deer_fire_charge",
                anim = "blast", anim2 = nil, isloop = false,
                fn_anim = SetAnim_agronssword_sun_catk2_fx,
                x = -55, y = 50, scale = 0.38*0.8
            },
            {
                bank = "fx_dock_crackleandpop", build = "fx_dock_crackleandpop",
                anim = "pop", anim2 = nil, isloop = false,
                x = -55, y = 40, scale = 0.19
            }
        }
    },
    carpet_whitewood_law = {
        string = ischinese and {
            name = "西洋棋棋盘", collection = "LAW", access = "SPECIAL", descitem = "解锁\"白木地垫\"、\"白木地毯\"的皮肤。",
            description = "不大不小的棋盘上，我方对方。每一颗棋子都是我的工具，让我在每一个方格上施展自己的权谋。不管是开局，结局，残局，败局，我都心思缜密，处变不惊。一横一竖的棋盘上，进攻防御，不到最后一刻都不要放弃！带领自己的棋子冲破封锁，进攻还是防御，都有我个人风格。"
        } or {
            name = "Chessboard", collection = "LAW", access = "SPECIAL",
            descitem = "Unlock \"White Wood Mat\", \"White Wood Carpet\" skin.", description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "carpet_whitewood_law", build = "carpet_whitewood_law",
                anim = "idle_big", anim2 = nil, isloop = false,
                x = -45, y = 70, scale = 0.12
            },
            {
                bank = "carpet_whitewood_law", build = "carpet_whitewood_law",
                anim = "idle", anim2 = nil, isloop = false,
                x = 65, y = 70, scale = 0.12
            }
        }
    },
    carpet_whitewood_law2 = {
        string = ischinese and {
            name = "西洋棋黑棋盘", collection = "LAW", access = "SPECIAL", descitem = "解锁\"白木地垫\"、\"白木地毯\"的皮肤。",
            description = "一横一竖的棋盘上，我方对方。每一颗棋子都是我的工具，让我在每一个方格上施展自己的权谋。不管是开局，结局，残局，败局，我都心思缜密，处变不惊。一黑一白的棋盘上，进攻防御，不到最后一刻都不要放弃！带领自己的棋子冲破封锁，进攻还是防御，都有我独特个性。"
        } or {
            name = "Black Chessboard", collection = "LAW", access = "SPECIAL",
            descitem = "Unlock \"White Wood Mat\", \"White Wood Carpet\" skin.", description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "carpet_whitewood_law2", build = "carpet_whitewood_law2",
                anim = "idle_big", anim2 = nil, isloop = false,
                x = -45, y = 70, scale = 0.12
            },
            {
                bank = "carpet_whitewood_law2", build = "carpet_whitewood_law2",
                anim = "idle", anim2 = nil, isloop = false,
                x = 65, y = 70, scale = 0.12
            }
        }
    },
    soul_contracts_taste = {
        string = ischinese and {
            collection = "TASTE", access = "SPECIAL", descitem = "解锁\"灵魂契约\"的皮肤。",
            description = "他才二十岁出头，就成为了当地知名高级餐厅的主厨。都说每位成功的大厨都有自己的拿手好菜，他自然也不例外。一般人也许会猜是焗蜗牛、北极贝寿司这类奢华的菜品，而他的出名作却是普普通通的芝士三明治。他烤出来的三明治既酥脆又软绵，入口回甘。内陷里一边是新鲜的生菜搭配微熏火腿肉，爽脆喷香，另一边是牛肉边角料剁碎后煎出来的肉饼，然后用完全融化的芝士贯浇两边，将两部分完美融合为一体。无论是用料还是做法都和平常的一致，但只有他的芝士三明治，因为他特殊的细节把控，有着超出预料的口感使人难以忘怀。\n其他人都是想着探究料理的做法，而我好奇他的童年，是什么样的经历能磨炼并诞生出这样一位三明治烹饪大师。或许他已出卖了灵魂，为了治愈自己，为了填补曾经的遗憾！"
        } or {
            collection = "TASTE", access = "SPECIAL", descitem = "Unlock \"Soul Contracts\" skin.", description = "Emmm."
        },
        height_anim = 110,
        anims = {
            {
                bank = "book_maxwell", build = "soul_contracts_taste",
                anim = "use", anim2 = "proximity_loop", isloop = true,
                fn_click = SetAnim_soul_contracts2,
                x = -50, y = 15, scale = 0.32
            },
            {
                bank = "book_maxwell", build = "soul_contracts_taste",
                anim = "proximity_pst", anim2 = "idle", isloop = false,
                fn_click = SetAnim_soul_contracts,
                x = 50, y = 15, scale = 0.32
            }
        }
    },
    icire_rock_day = {
        string = ischinese and {
            collection = "DAY", access = "SPECIAL", descitem = "解锁\"鸳鸯石\"的皮肤。",
            description = "圣诞节礼物？！我最想要的是一颗雪景球。轻拿起它，快速摇动，雪花飘落，透过玻璃，尽收美景。在那几秒内，我看尽欢愉，短暂脱离枯槁的现实。此刻你将得到一颗能变化球内景色的风景球，不同的画面有着不同欢乐氛围。在这重要时节，我希望你快乐……"
        } or {
            collection = "DAY", access = "SPECIAL", descitem = "Unlock \"Icire Stone\" skin.", description = "Emmm."
        },
        height_anim = 170,
        anims = {
            { --上
                bank = "icire_rock_day", build = "icire_rock_day",
                anim = "3", anim2 = nil, isloop = true,
                x = 0, y = 13+90, scale = 0.38
            },
            {
                bank = "wintersfeastfuel", build = "icire_rock_day",
                anim = "idle_loop", anim2 = nil, isloop = true,
                fn_anim = SetAnim_icire_rock_day, tag = 4,
                x = 70, y = 13+65+13, scale = 0.46
            },
            { --右1
                bank = "icire_rock_day", build = "icire_rock_day",
                anim = "4", anim2 = nil, isloop = true,
                x = 70, y = 13+65, scale = 0.38
            },
            {
                bank = "wintersfeastfuel", build = "icire_rock_day",
                anim = "idle_loop", anim2 = nil, isloop = true,
                fn_anim = SetAnim_icire_rock_day, tag = 5,
                x = 42, y = 13+13, scale = 0.46
            },
            { --右2
                bank = "icire_rock_day", build = "icire_rock_day",
                anim = "5", anim2 = nil, isloop = true,
                x = 42, y = 13, scale = 0.38
            },
            {
                bank = "wintersfeastfuel", build = "icire_rock_day",
                anim = "idle_loop", anim2 = nil, isloop = true,
                fn_anim = SetAnim_icire_rock_day, tag = 2,
                x = -70, y = 13+65+13, scale = 0.46
            },
            { --左1
                bank = "icire_rock_day", build = "icire_rock_day",
                anim = "2", anim2 = nil, isloop = true,
                x = -70, y = 13+65, scale = 0.38
            },
            {
                bank = "wintersfeastfuel", build = "icire_rock_day",
                anim = "idle_loop", anim2 = nil, isloop = true,
                fn_anim = SetAnim_icire_rock_day, tag = 1,
                x = -42, y = 13+13, scale = 0.46
            },
            { --左2
                bank = "icire_rock_day", build = "icire_rock_day",
                anim = "1", anim2 = nil, isloop = true,
                x = -42, y = 13, scale = 0.38
            }
        }
    },
    neverfade_paper = {
        string = ischinese and {
            collection = "PAPER", access = "SPECIAL", descitem = "解锁\"永不凋零\"、\"永不凋零花丛\"、\"庇佑蝴蝶\"以及入鞘后的皮肤。",
            description = "先在纸的边缘画上浅蓝色花纹，然后折成纸扇，再把外端稍稍压平。按照这个方式多做一些不同大小的，把所有拼凑在一起粘起来。最后做三个纸蝴蝶插上去，一捧花丛扇就做好了。佩柏细细欣赏着自己新的作品。\n“你怎么又在做这些垃圾！？给我好好做功课去！”佩柏的父亲吼他，当着他的面把他的新作品捏成团丢进垃圾桶，“给我把作业写了。”随后扬长而去。\n当晚，佩柏偷偷在被窝里开着手电。“妈，我想你”，佩柏在白纸上写了这几个字，折成了一个纸蝴蝶，然后又折了一把纸剑，他将纸蝴蝶黏在纸剑上，不知不觉居然睡着了。“我说了你不听是不是！”睡梦中的佩柏突然被父亲从床上拽起，当着他的面把蝴蝶纸剑撕得粉碎，“以后我见一次撕一次！”父亲说完就出去了。佩柏小声啜泣起来。",
        } or {
            collection = "PAPER", access = "SPECIAL",
            descitem = "Unlock \"Neverfade\", \"Neverfade Bush\", and \"Neverfade Butterfly\" skin.", description = "Emmm."
        },
        height_anim = 300,
        anims = {
            {
                bank = "berrybush2", build = "neverfadebush_paper",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = SetClick_neverfadebush,
                x = -48, y = 200, scale = 0.25
            },
            {
                bank = "berrybush2", build = "neverfadebush_paper",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = SetAnim_neverfadebush,
                fn_click = SetClick_neverfadebush,
                x = 45, y = 145, scale = 0.25
            },
            {
                bank = "butterfly", build = "neverfade_butterfly_paper",
                anim = "land", anim2 = "idle", isloop = true,
                x = 5, y = 145, scale = 0.25
            },
            {
                bank = "butterfly", build = "neverfade_butterfly_paper",
                anim = "take_off", anim2 = "idle_flight_loop", isloop = true,
                x = 70, y = 195, scale = 0.25
            },
            {
                bank = "butterfly", build = "neverfade_butterfly_paper",
                anim = "take_off", anim2 = "flight_cycle", isloop = true,
                x = -90, y = 90, scale = 0.25
            },
            {
                bank = "neverfade_paper", build = "neverfade_paper",
                anim = "idle", anim2 = nil, isloop = false,
                fn_click = SetClick_neverfade,
                x = -85, y = 0, scale = 0.38
            },
            {
                bank = "neverfade_paper", build = "neverfade_paper",
                anim = "idle_cover", anim2 = nil, isloop = false,
                x = -30, y = -2, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "neverfade_paper", file = "normal_swap", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    neverfade_paper2 = {
        string = ischinese and {
            collection = "PAPER", access = "SPECIAL", descitem = "解锁\"永不凋零\"、\"永不凋零花丛\"、\"庇佑蝴蝶\"以及入鞘后的皮肤。",
            description = "佩柏把自己的折纸作品都藏在了床下盒子里，他不敢让父亲知道。一天放学回家，发现父亲正在屋外烧自己的折纸。父亲见佩柏回来，拿起木棍准备打人。佩柏立即激动起来，压抑的情绪终于爆发，“要是妈还在，她才不会让你这样对我！”“呜…”佩柏哭起来，“都怪你这个酒鬼…对我最好的妈妈已经不在了！”佩柏放声大哭。父亲愣住了，放下手里的木棍，想抱住佩柏。佩柏躲开了，跑向屋里。父亲掩面哭泣，他知道他错了，但他不会改。佩柏是这样认为的。\n从那之后，佩柏不再尝试折纸，不再尝试倾注情感于他物，所有的折纸都藏进了心里！",
        } or {
            collection = "PAPER", access = "SPECIAL",
            descitem = "Unlock \"Neverfade\", \"Neverfade Bush\", and \"Neverfade Butterfly\" skin.", description = "Emmm."
        },
        height_anim = 300,
        anims = {
            {
                bank = "berrybush2", build = "neverfadebush_paper2",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = SetClick_neverfadebush,
                x = -48, y = 200, scale = 0.25
            },
            {
                bank = "berrybush2", build = "neverfadebush_paper2",
                anim = "shake", anim2 = "idle", isloop = true,
                fn_anim = SetAnim_neverfadebush,
                fn_click = SetClick_neverfadebush,
                x = 45, y = 145, scale = 0.25
            },
            {
                bank = "butterfly", build = "neverfade_butterfly_paper2",
                anim = "land", anim2 = "idle", isloop = true,
                x = 5, y = 145, scale = 0.25
            },
            {
                bank = "butterfly", build = "neverfade_butterfly_paper2",
                anim = "take_off", anim2 = "idle_flight_loop", isloop = true,
                x = 70, y = 195, scale = 0.25
            },
            {
                bank = "butterfly", build = "neverfade_butterfly_paper2",
                anim = "take_off", anim2 = "flight_cycle", isloop = true,
                x = -90, y = 90, scale = 0.25
            },
            {
                bank = "neverfade_paper2", build = "neverfade_paper2",
                anim = "idle", anim2 = nil, isloop = false,
                fn_click = SetClick_neverfade,
                x = -85, y = 0, scale = 0.38
            },
            {
                bank = "neverfade_paper2", build = "neverfade_paper2",
                anim = "idle_cover", anim2 = nil, isloop = false,
                x = -30, y = -2, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "neverfade_paper2", file = "normal_swap", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    siving_feather_real_paper = {
        string = ischinese and {
            name = "十字四方纸镖", collection = "PAPER", access = "SPECIAL", descitem = "解锁\"子圭·翰\"、\"子圭玄鸟绒羽\"的皮肤。",
            description = "“啊，我的眼睛！”，一位同学的眼睛被纸飞镖戳伤，肇事者逃之夭夭。班主任知道后为这位同学主持公道，看到地上的纸飞镖，精致不一般，立马就觉得这是佩柏的“杰作”，把这件事告诉了佩柏的父亲。\n佩柏的纸飞镖本来放在自己的书包里，他课间休息时总喜欢偷偷拿出来把玩，被身后的同学瞄到。于是他趁着佩柏上厕所，擅自拿走了纸飞镖，跑到人头攒动的走廊玩耍，一不小心就戳到了一位同学的眼睛，知道闯祸的他迅速离开“案发现场”。\n当天佩柏放学回到家，父亲早就守在门口。父亲责怪他不知道努力学习，就搞些没用的纸玩意，佩柏很郁闷，但无力反驳。佩柏被罚不准吃晚饭，于是趁着父亲吃饭的时机，再次折起纸来。由于自己的纸飞镖被没收，他决定重新做一个。这次的纸飞镖，工序更复杂更繁美，每一折每一转都是他的心事流露。"
        } or {
            name = "Cross Square Paper Dart", collection = "PAPER", access = "SPECIAL",
            descitem = "Unlock \"Siving-Plume\", \"Siving Feather\" skin.", description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "siving_feather_real_paper", build = "siving_feather_real_paper",
                anim = "item", anim2 = nil, isloop = false,
                x = -55, y = 130, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "siving_feather_real_paper", file = "swap", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 130, scale = 0.38
            },
            {
                bank = "siving_feather_fake_paper", build = "siving_feather_fake_paper",
                anim = "item", anim2 = nil, isloop = false,
                x = -55, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "siving_feather_fake_paper", file = "swap", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            }
        }
    },
    siving_feather_real_collector = {
        string = ischinese and {
            collection = "COLLECTOR", access = "SPECIAL", descitem = "解锁\"子圭·翰\"、\"子圭玄鸟绒羽\"的皮肤。",
            description = "传说宇宙里有种强大的四维生物，能穿梭于时间位面，只在一些古老星系里偶尔出没。一个幸运至极的人类，在从飞船中投身古星环后濒死之际，意外撞上了它。青光一闪，这个人突然回到了自己飞船迷路之前，手里还多了一片青光闪耀的鳞片。几年间，他靠着鳞片，带着自己的族人发展壮大，寿终正寝前将鳞片做成了占星石，希望占星石能继续引导族人。几百年后，族内有人叛变，窃取了占星石中的基因，逃往他星……\n此时此刻，到处地面塌陷，并不断长出暗红色的水晶荆棘。一个被基因改造过的星猫和其主人逃走途中，星猫掉进地缝，主人自顾不暇选择直接逃走，而星猫却意外接触到了荆棘的核心，核心里的能量居然被星猫吸收。顿时，它身体迸发出一股能量波，星猫从金色变成了青色，毛发也更加突出和光耀。它进化了，觉醒的古老基因让它通晓了一切。\n星猫飘向空中，俯瞰崩溃中的星球，为了报答诞生之恩，果断选择回到过去，拯救面前的未来……"
        } or {
            collection = "COLLECTOR", access = "SPECIAL", descitem = "Unlock \"Siving-Plume\", \"Siving Feather\" skin.",
            description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "kitcoon", build = "siving_feather_real_collector", face = FACING_DOWNRIGHT,
                anim = "jump_out", anim2 = "idle_loop", isloop = true,
                touchanim = "emote_lick",
                fn_click = SetAnim_backcub,
                x = -55, y = 135, scale = 0.34
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "siving_feather_real_collector", file = "swap_show", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 130, scale = 0.38
            },
            {
                bank = "kitcoon", build = "siving_feather_fake_collector", face = FACING_DOWNRIGHT,
                anim = "sleep_pre", anim2 = "sleep_loop", isloop = true,
                fn_click = SetAnim_sivfeather,
                x = -55, y = 5, scale = 0.34
            },
            {
                symbol = {
                    { symbol = "lantern_overlay", build = "siving_feather_fake_collector", file = "swap_show", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            },
            {
                bank = "goldnugget", build = "siving_feather_collector_fx",
                anim = "sparkle", anim2 = nil, isloop = false,
                x = -50, y = 180, scale = 0.38
            },
            {
                bank = "goldnugget", build = "siving_feather_collector_fx",
                anim = "sparkle", anim2 = nil, isloop = false,
                x = -40, y = 190, scale = 0.38
            },
            {
                bank = "goldnugget", build = "siving_feather_collector_fx",
                anim = "sparkle", anim2 = nil, isloop = false,
                x = -70, y = 150, scale = 0.38
            },
            {
                bank = "goldnugget", build = "siving_feather_collector_fx",
                anim = "sparkle", anim2 = nil, isloop = false,
                x = -90, y = 220, scale = 0.38
            },
            {
                bank = "goldnugget", build = "siving_feather_collector_fx",
                anim = "sparkle", anim2 = nil, isloop = false,
                x = -65, y = 40, scale = 0.38
            },
            {
                bank = "goldnugget", build = "siving_feather_collector_fx",
                anim = "sparkle", anim2 = nil, isloop = false,
                x = -100, y = 55, scale = 0.38
            },
            {
                bank = "goldnugget", build = "siving_feather_collector_fx",
                anim = "sparkle", anim2 = nil, isloop = false,
                x = -30, y = -5, scale = 0.38
            }
        }
    },
    revolvedmoonlight_item_taste = {
        string = ischinese and {
            collection = "TASTE", access = "SPECIAL", descitem = "解锁\"月轮宝盘套件\"、\"月轮宝盘\"的皮肤。",
            description = "近几月冰之国总是遭到蘑怪的侵扰。冰灵损失惨重，因为被蘑怪抓伤后会逐渐长满菌丝绒毛而死。冰王不得已加快了冰灵的创造，用料和做工也不再那么细心。小芒就是冰王用低廉的冰激凌底料，普通黄桃以及滥大街的芒果而创造出来的冰灵，然后马上就被派到了边哨站岗。\n芒队长每天都认真教授小芒等队员如何与蘑怪对抗。芒队长已经见证了太多队友的离别，所以格外强调，最重要的是如何活下来！\n没过几天，夜里警报响起！小芒虽然知道自己是粗制滥造出来的劣质冰灵，浑身发抖，但为了王国，坚定了信念，还是冲了出去……",
        } or {
            collection = "TASTE", access = "SPECIAL",
            descitem = "Unlock \"MoonRevolved Kit\", \"MoonRevolved\" skin.", description = "Emmm."
        },
        height_anim = 180,
        anims = {
            {
                bank = "ui_chest_3x3", build = "ui_revolvedmoonlight_taste_4x3",
                anim = "open", anim2 = nil, isloop = false,
                x = 0, y = 140, scale = 0.24
            },
            {
                bank = "revolvedmoonlight_item_taste", build = "revolvedmoonlight_item_taste",
                anim = "idle", anim2 = nil, isloop = false,
                x = 0, y = 0, scale = 0.32
            },
            {
                bank = "revolvedmoonlight_taste", build = "revolvedmoonlight_taste",
                anim = "close", anim2 = "closed", isloop = false,
                fn_click = SetClick_revolvedmoonlight,
                x = -65, y = 0, scale = 0.32
            },
            {
                bank = "revolvedmoonlight_pro_taste", build = "revolvedmoonlight_taste",
                anim = "close", anim2 = "closed", isloop = false,
                fn_click = SetClick_revolvedmoonlight,
                x = 65, y = 0, scale = 0.32
            }
        }
    },
    revolvedmoonlight_item_taste2 = {
        string = ischinese and {
            collection = "TASTE", access = "SPECIAL", descitem = "解锁\"月轮宝盘套件\"、\"月轮宝盘\"的皮肤。",
            description = "红主色调，黑色是点缀。草莓圣代，巧克力为其新增一种高级感。酸酸甜甜，如青春的可爱。",
        } or {
            collection = "TASTE", access = "SPECIAL",
            descitem = "Unlock \"MoonRevolved Kit\", \"MoonRevolved\" skin.", description = "Emmm."
        },
        height_anim = 180,
        anims = {
            {
                bank = "ui_chest_3x3", build = "ui_revolvedmoonlight_taste2_4x3",
                anim = "open", anim2 = nil, isloop = false,
                x = 0, y = 140, scale = 0.24
            },
            {
                bank = "revolvedmoonlight_item_taste2", build = "revolvedmoonlight_item_taste2",
                anim = "idle", anim2 = nil, isloop = false,
                x = 0, y = 0, scale = 0.32
            },
            {
                bank = "revolvedmoonlight_taste2", build = "revolvedmoonlight_taste",
                anim = "close", anim2 = "closed", isloop = false,
                fn_click = SetClick_revolvedmoonlight,
                x = -65, y = 0, scale = 0.32
            },
            {
                bank = "revolvedmoonlight_pro_taste2", build = "revolvedmoonlight_taste",
                anim = "close", anim2 = "closed", isloop = false,
                fn_click = SetClick_revolvedmoonlight,
                x = 65, y = 0, scale = 0.32
            }
        }
    },
    revolvedmoonlight_item_taste3 = {
        string = ischinese and {
            collection = "TASTE", access = "SPECIAL", descitem = "解锁\"月轮宝盘套件\"、\"月轮宝盘\"的皮肤。",
            description = "绿主色调，黄色是点缀。柠檬圣代，奇异果为其新增一种搞怪感。清新酸拧，如跳脱的思维。",
        } or {
            collection = "TASTE", access = "SPECIAL",
            descitem = "Unlock \"MoonRevolved Kit\", \"MoonRevolved\" skin.", description = "Emmm."
        },
        height_anim = 180,
        anims = {
            {
                bank = "ui_chest_3x3", build = "ui_revolvedmoonlight_taste3_4x3",
                anim = "open", anim2 = nil, isloop = false,
                x = 0, y = 135, scale = 0.24
            },
            {
                bank = "revolvedmoonlight_item_taste3", build = "revolvedmoonlight_item_taste3",
                anim = "idle", anim2 = nil, isloop = false,
                x = 0, y = 0, scale = 0.32
            },
            {
                bank = "revolvedmoonlight_taste3", build = "revolvedmoonlight_taste",
                anim = "close", anim2 = "closed", isloop = false,
                fn_click = SetClick_revolvedmoonlight,
                x = -65, y = 0, scale = 0.32
            },
            {
                bank = "revolvedmoonlight_pro_taste3", build = "revolvedmoonlight_taste",
                anim = "close", anim2 = "closed", isloop = false,
                fn_click = SetClick_revolvedmoonlight,
                x = 65, y = 0, scale = 0.32
            }
        }
    },
    revolvedmoonlight_item_taste4 = {
        string = ischinese and {
            collection = "TASTE", access = "SPECIAL", descitem = "解锁\"月轮宝盘套件\"、\"月轮宝盘\"的皮肤。",
            description = "黑主色调，蓝色是点缀。黑巧圣代，蓝莓为其新增一种活跃感。丝滑香软，如随性的心态。",
        } or {
            collection = "TASTE", access = "SPECIAL",
            descitem = "Unlock \"MoonRevolved Kit\", \"MoonRevolved\" skin.", description = "Emmm."
        },
        height_anim = 180,
        anims = {
            {
                bank = "ui_chest_3x3", build = "ui_revolvedmoonlight_taste4_4x3",
                anim = "open", anim2 = nil, isloop = false,
                x = 0, y = 140, scale = 0.24
            },
            {
                bank = "revolvedmoonlight_item_taste4", build = "revolvedmoonlight_item_taste4",
                anim = "idle", anim2 = nil, isloop = false,
                x = 0, y = 0, scale = 0.32
            },
            {
                bank = "revolvedmoonlight_taste4", build = "revolvedmoonlight_taste",
                anim = "close", anim2 = "closed", isloop = false,
                fn_click = SetClick_revolvedmoonlight,
                x = -65, y = 0, scale = 0.32
            },
            {
                bank = "revolvedmoonlight_pro_taste4", build = "revolvedmoonlight_taste",
                anim = "close", anim2 = "closed", isloop = false,
                fn_click = SetClick_revolvedmoonlight,
                x = 65, y = 0, scale = 0.32
            }
        }
    },
    pinkstaff_tvplay = {
        string = ischinese and {
            collection = "TVPLAY", access = "FREE", descitem = "解锁\"幻象法杖\"的皮肤。",
            description = "无人的街道旁蓝光闪过，一位年老的绅士从一个老旧的电话亭里匆忙走出……\n他最近总是收到一个穿越时空传来的警告信号，于是，怀揣不安的心情来到了3202年的地球。\n由于太阳因未知原因而熄灭，地球环境已经破败不堪。他立即前往信号来源，一个空旷的地下农场。在一排排次世代人工培育箱中穿梭，光线强弱不一看不太清，他被突然跳下来的黑影打倒在地……\n“啧啧，约翰·史密斯，啊不，还是该叫你神秘博士”，恍惚中他看到一个满脸疤痕异常渗人的怪物站在自己面前，“好久不见，我猜你肯定不认识我了”。他正准备使用一个钢笔样的东西脱身，却被这个怪物一下打掉，“哈哈，别以为我不知道你的能耐，之前我可被你害惨了！”。他吃痛回复道，“是吗，让你尝尝我这一世的新花样吧”，然后被打飞的那个东西一瞬间发出了强烈的电光……"
        } or {
            collection = "TVPLAY", access = "FREE", descitem = "Unlock \"Illusion Staff\" skin.", description = "Emmm."
        },
        height_anim = 145,
        anims = {
            {
                bank = "pinkstaff_tvplay", build = "pinkstaff_tvplay",
                anim = "idle", anim2 = nil, isloop = false,
                x = -45, y = 0, scale = 0.38
            },
            {
                bank = "pinkstaff_fx_tvplay", build = "pinkstaff_fx_tvplay",
                anim = "idle", anim2 = nil, isloop = true,
                fn_anim = function(self, anim, data)
                    local animstate = anim:GetAnimState()
                    SetAnim_base(animstate, data)
                    animstate:SetBloomEffectHandle("shaders/anim.ksh")
                    animstate:SetMultColour(115/255, 217/255, 255/255, 0.8)
                end,
                x = -54, y = 56, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "pinkstaff_tvplay", file = "swap_object", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    plant_cactus_meat_l_world = {
        string = ischinese and {
            collection = "DISGUISER", access = "SPECIAL", descitem = "解锁\"仙人柱\"的皮肤。",
            description = "如果要我选什么花最美，我觉得，不是春日里的繁花似锦，也不是夏日里的娇艳欲滴，而是滚滚黄沙里，干旱沙漠中，险恶环境下开出的花儿！\n在每个清晨，它布满纤毛的球刺会从晨风中借来一缕缕露水；\n在每个正午，厚实的皮质会牢牢锁住水分，不给烈日抢走的机会；\n在偶尔午夜，小小的身体迸开巨大花蕾，不与争艳，在第一束阳光拜访前默默收起所有美丽痕迹。"
        } or {
            collection = "DISGUISER", access = "SPECIAL", descitem = "Unlock \"Cactaceae\" skin.", description = "Emmm."
        },
        height_anim = 134,
        anims = {
            {
                bank = "plant_cactus_meat_l_world", build = "plant_cactus_meat_l_world",
                anim = "level4_3", anim2 = nil, isloop = false,
                symbol = {
                    { symbol = "flowerplus", build = "plant_cactus_meat_l_world", file = "flomax" }
                },
                fn_anim = SetAnim_plant_cactus,
                fn_click = SetClick_plant_cactus,
                x = -52, y = 5, scale = 0.32
            },
            {
                bank = "plant_cactus_meat_l_world", build = "plant_cactus_meat_l_world",
                anim = "level1_3", anim2 = nil, isloop = false,
                tag_start = 2,
                fn_click = SetClick_plant_cactus,
                x = 50, y = 5, scale = 0.32
            }
        }
    },
    plant_carrot_l_fact = {
        string = ischinese and {
            collection = "FACT", access = "SPECIAL", descitem = "解锁\"芾萝卜\"、\"胡萝卜长枪\"的皮肤。",
            description = "在一片农田里，生长着很多普通的胡萝卜。大多数胡萝卜静静地生长，深深扎根于土地，成为人们餐桌上的美味食材。\n有时，幸运的采摘者会发现一些奇特的胡萝卜，它们生长时纠缠在一起，形成了独特的形状。他们会把这些独特的胡萝卜挂在稻草人上，当做丰收与好运的象征。"
        } or {
            collection = "FACT", access = "SPECIAL", descitem = "Unlock \"Carrot Cluster\", \"Carrot Lance\" skin.",
            description = "Emmm."
        },
        height_anim = 160,
        anims = {
            {
                bank = "plant_carrot_l_fact", build = "plant_carrot_l_fact",
                anim = "level3_3", anim2 = nil, isloop = true,
                fn_click = SetClick_plant_carrot,
                x = -75, y = 3, scale = 0.38
            },
            {
                bank = "lance_carrot_l_fact", build = "lance_carrot_l_fact",
                anim = "idle", anim2 = nil, isloop = false,
                x = -25, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "lance_carrot_l_fact", file = "swap_object", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 45, y = 0, scale = 0.38
            }
        }
    },
    plant_lightbulb_l_world = {
        string = ischinese and {
            collection = "DISGUISER", access = "SPECIAL", descitem = "解锁\"夜盏花\"的皮肤。",
            description = "无垠之海的彼端，长有一片神秘的铃兰花海。\n永恒之夜，花朵们在微风中轻轻摇曳，散发点点荧光，仿佛银河倒映在大地。旅人们会采摘这些奇花，制成燃料，照亮他们漂泊的灵魂。"
        } or {
            collection = "DISGUISER", access = "SPECIAL", descitem = "Unlock \"Night Bright Flower\" skin.",
            description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "plant_lightbulb_l_world", build = "plant_lightbulb_l_world",
                anim = "level3", anim2 = nil, isloop = true,
                fn_anim = SetAnim_plant_lightbulb_l_world, tag_anim = 3,
                fn_click = SetClick_plant_lightbulb_l_world,
                x = -52, y = 0, scale = 0.38
            },
            {
                bank = "plant_lightbulb_l_world", build = "plant_lightbulb_l_world",
                anim = "level3", anim2 = nil, isloop = true,
                fn_anim = SetAnim_plant_lightbulb_l_world,
                fn_click = SetClick_plant_lightbulb_l_world,
                x = 50, y = 0, scale = 0.38
            }
        }
    },
    plant_lightbulb_l_sun = {
        string = ischinese and {
            name = "辉光铃兰", collection = "SUNMOON", access = "SPECIAL", descitem = "解锁\"夜盏花\"的2套皮肤。",
            description = "两株双生铃兰被古神倾注了力量，化作辉光铃兰。随后被勇者找到，勇者将其种在了家园中心。\n日辉铃兰散发的光芒温暖强烈，能使众人重拾信念，坚定活下去的勇气；月辉铃兰散发的光彩细腻柔和，能让众人清醒理智，冷静地面对黑暗。\n旧日残余势力依然在不断影响这里，凡人和勇者也只能在这样的时代苦苦坚持……"
        } or {
            name = "Lily of The Light", collection = "SUNMOON", access = "SPECIAL",
            descitem = "Unlock \"Night Bright Flower\" skin.", description = "Emmm."
        },
        height_anim = 210,
        anims = {
            {
                bank = "plant_lightbulb_l_world", build = "plant_lightbulb_l_sun",
                anim = "level3", anim2 = nil, isloop = true,
                fn_anim = SetAnim_plant_lightbulb_l_world, tag_anim = 3,
                fn_click = SetClick_plant_lightbulb_l_world,
                x = -62, y = 70, scale = 0.38
            },
            {
                bank = "plant_lightbulb_l_world", build = "plant_lightbulb_l_moon",
                anim = "level3", anim2 = nil, isloop = true,
                fn_anim = SetAnim_plant_lightbulb_l_world, tag_anim = 3,
                fn_click = SetClick_plant_lightbulb_l_world,
                x = 30, y = 70, scale = 0.38
            },
            {
                bank = "plant_lightbulb_l_world", build = "plant_lightbulb_l_moon",
                anim = "level3", anim2 = nil, isloop = true,
                fn_anim = SetAnim_plant_lightbulb_l_world,
                fn_click = SetClick_plant_lightbulb_l_world,
                x = -25, y = 0, scale = 0.38
            },
            {
                bank = "plant_lightbulb_l_world", build = "plant_lightbulb_l_sun",
                anim = "level3", anim2 = nil, isloop = true,
                fn_anim = SetAnim_plant_lightbulb_l_world,
                fn_click = SetClick_plant_lightbulb_l_world,
                x = 67, y = 0, scale = 0.38
            }
        }
    },
    plant_berries_l_day = {
        string = ischinese and {
            collection = "DAY", access = "SPECIAL", descitem = "解锁\"果攀树\"的2套皮肤。",
            description = "盆中金橘，枝繁叶茂，颗颗果实垂挂如珠。铜币红绳悬挂其上，叮当作响，寓财源广进之意。绿叶映衬金果，生机勃勃；铜币随风摇曳，福泽绵长。\n愿岁岁平安，年年如意。"
        } or {
            collection = "DAY", access = "SPECIAL", descitem = "Unlock \"Jabuticaba\" skin.", description = "Emmm."
        },
        height_anim = 247,
        anims = {
            {
                bank = "plant_berries_l_day2", build = "plant_berries_l_day2",
                anim = "level3_3", anim2 = nil, isloop = false,
                fn_anim = pas.SetAnim_plant_berries, fn_click = pas.Click_plant_berries,
                x = -55, y = 87, scale = 0.3
            },
            {
                bank = "plant_berries_l_day", build = "plant_berries_l_day",
                anim = "level3_3", anim2 = nil, isloop = false,
                fn_anim = pas.SetAnim_plant_berries, fn_click = pas.Click_plant_berries,
                x = 40, y = 5, scale = 0.3
            }
        }
    },
    siving_ctlall_item_era = {
        string = ischinese and {
            collection = "ERA", access = "SPECIAL", descitem = "解锁\"子圭·利川\"、\"子圭·益矩\"、\"子圭·崇溟\"的皮肤。",
            description = "在遥远古代，人类还处在部落阶段。在海滨旁，在密林里，在高原上，以大大小小的部落分而居之。\n海滨部落敬畏无垠大海。他们渴望探索翻涌的海洋，但总有一个极限，无情的洋流总能将他们拍落。于是他们树起图腾，关于海，关于他们在海里见过的庞大造物。\n密林部落崇敬广袤山川。他们勇于在一山又一山中寻觅并建立新的栖息地，但总有一个极限，连绵山川阻碍了他们的联系与团结。于是他们树起图腾，关于山，关于他们想要团结，想要走遍大地。\n高原部落向往自由蓝天。恶劣的生存环境让他们信仰魂魄能翱翔天空。于是他们树起图腾，关于天，关于美好生活和每天都能望见的自由飞鸟。"
        } or {
            collection = "ERA", access = "SPECIAL",
            descitem = "Unlock \"Siving-Irrigator\", \"Siving-Fertilizer\", \"Siving-Agriculture\" skin.",
            description = "Emmm."
        },
        height_anim = 226,
        anims = {
            {
                bank = "siving_ctlall_era", build = "siving_ctlall_era",
                anim = "idle", anim2 = nil, isloop = false,
                fn_click = SetClick_siving_ctl,
                x = 0, y = 20, scale = 0.26
            },
            {
                bank = "siving_ctlwater_era", build = "siving_ctlwater_era",
                anim = "idle", anim2 = nil, isloop = false,
                fn_click = SetClick_siving_ctl,
                x = -66, y = 5, scale = 0.26
            },
            {
                bank = "siving_ctldirt_era", build = "siving_ctldirt_era",
                anim = "idle", anim2 = nil, isloop = false,
                fn_click = SetClick_siving_ctl,
                x = 66, y = 5, scale = 0.26
            },
            {
                bank = "farm_plant_happiness", build = "farm_plant_happiness",
                anim = "happy", anim2 = nil, isloop = false,
                x = 0, y = 30, scale = 0.26
            },
            {
                bank = "farm_plant_happiness", build = "farm_plant_happiness",
                anim = "happy", anim2 = nil, isloop = false,
                x = -66, y = 5, scale = 0.26
            },
            {
                bank = "farm_plant_happiness", build = "farm_plant_happiness",
                anim = "happy", anim2 = nil, isloop = false,
                x = 66, y = 5, scale = 0.26
            }
        }
    },
    siving_mask_gold_era = {
        string = ischinese and {
            name = "巫族骨面", collection = "ERA", access = "SPECIAL", descitem = "解锁\"子圭·汲\"、\"子圭·歃\"的2套皮肤。",
            description = "在密林深处，最靠近大地中心的地方，出生了一个被诅咒的婴儿，他面目狰狞丑陋，皮肤枯干发绿，族人们都想处死这不祥之兆，只有他生母舍命抵抗，死前他被藏进枯木中，顺着河流漂向无人处。\n一只野猪冲向了被搁浅在河边的他，因为他啼哭声让野猪狂躁。然而野猪肉眼可见逐渐消瘦，半途就没了气息。婴儿爬了出来，皮肤已不那么枯瘦。很快，周围的飞禽走兽都纷纷倒地，奇异的符号从这些动物身上慢慢散出，流向这个刚出生的婴儿，他的容貌已和正常婴儿无异。\n不知何时，一位头戴绳坠兽骨身批叶袍的女巫出现在他面前，对他耳语几句，婴儿周围奇怪的现象停了下来。她将婴儿的手掌划破，又窃窃私语，血液飘进她的骨面具中，绿纹被染成血色。女巫疯笑着，抱走了婴儿，消失在森林中……"
        } or {
            name = "Witch Bone Mask", collection = "ERA", access = "SPECIAL",
            descitem = "Unlock \"Siving-Leakage\", \"Siving-Thaumaturgy\" skin.", description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "siving_mask_era", build = "siving_mask_era",
                anim = "idle", anim2 = nil, isloop = false,
                x = -34, y = 135, scale = 0.28
            },
            {
                bank = "siving_mask_gold_era", build = "siving_mask_gold_era", face = FACING_LEFT,
                anim = "idle", anim2 = nil, isloop = false,
                x = 26, y = 140, scale = 0.28
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "siving_mask_era", file = "swap_hat", type = 3 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = -68, y = 130, scale = 0.35
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "siving_mask_gold_era", file = "swap_show", type = 3 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 56, y = 130, scale = 0.35
            },
            {
                bank = "siving_mask_era2", build = "siving_mask_era2",
                anim = "idle", anim2 = nil, isloop = false,
                x = -34, y = 5, scale = 0.28
            },
            {
                bank = "siving_mask_gold_era2", build = "siving_mask_gold_era2", face = FACING_LEFT,
                anim = "idle", anim2 = nil, isloop = false,
                x = 26, y = 10, scale = 0.28
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "siving_mask_era2", file = "swap_hat", type = 3 }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = -68, y = 0, scale = 0.35
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "siving_mask_gold_era2", file = "swap_show", type = 3 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 56, y = 0, scale = 0.35
            }
        }
    },
    siving_mask_gold_marble = {
        string = ischinese and {
            name = "圣女的纱袍", collection = "MARBLE", access = "SPECIAL", descitem = "解锁\"子圭·歃\"、\"子圭·釜\"的皮肤。",
            description = "她虔诚地伫立在教堂五彩琉璃光芒之下，在晨曦中那容貌竟与圣母雕像一般无二，她看向十字架上的蔷薇，面容上满是欢欣——她对主的爱至诚无疑。\n圣水从杨柳枝叶挥洒，落在她的睫毛之上，突然间有人高声呼喊：“是圣母在流泪！”她震惊地发现众人竟转而向她跪拜，唱诗班的孩童齐聚她身边亲吻她的衣裙，华贵的乐章倏然在空中响起，松针的冷香从远处飘来，随着风，被裹挟而来的还有一片火刑架的灰烬。"
        } or {
            name = "Holy Suit", collection = "MARBLE", access = "SPECIAL",
            descitem = "Unlock \"Siving-Thaumaturgy\", \"Siving-Cauldron\" skin.", description = "Emmm."
        },
        height_anim = 170,
        anims = {
            {
                bank = "siving_suit_gold_marble", build = "siving_suit_gold_marble",
                anim = "idle", anim2 = nil, isloop = nil,
                x = -35, y = 90, scale = 0.38
            },
            {
                bank = "siving_mask_gold_marble", build = "siving_mask_gold_marble",
                anim = "idle", anim2 = nil, isloop = nil,
                x = -55, y = 20, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "siving_mask_gold_marble", file = "swap_hat", type = 2 },
                    { symbol = "swap_body", build = "siving_suit_gold_marble", file = "swap_body", type = nil }
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 50, y = 0, scale = 0.38
            }
        }
    },
    siving_soil_item_law = {
        string = ischinese and {
            name = "春泥", collection = "LAW", access = "SPECIAL", descitem = "解锁\"子圭·垄\"的2套皮肤。",
            description = "繁花如雪，在微风的吻中纷纷坠落，如羽毛般轻柔，仿佛花开的瞬间已经注定了它们轻盈的陨落。\n这并非终结，每一片花瓣都被温暖地接纳。融入春泥的沉寂，化作春末的生机。\n离别并非终结，是下一场盛夏的开始！"
        } or {
            name = "Spring Mud", collection = "LAW", access = "SPECIAL", descitem = "Unlock \"Siving-Soil\" skin.",
            description = "Emmm."
        },
        height_anim = 325,
        anims = {
            {
                bank = "siving_soil_law", build = "siving_soil_law",
                anim = "item", anim2 = nil, isloop = false,
                x = -60, y = 165, scale = 0.35
            },
            {
                bank = "farm_soil", build = "siving_soil_law",
                anim = "till_rise", anim2 = "till_idle", isloop = false,
                x = -40, y = 240, scale = 0.35
            },
            {
                soilskin = "siving_soil_law",
                fn_anim = SetAnim_soilcrop,
                fn_click = SetClick_soilcrop,
                x = 50, y = 170, scale = 0.35
            },
            {
                bank = "siving_soil_law2", build = "siving_soil_law2",
                anim = "item", anim2 = nil, isloop = false,
                x = -60, y = 15, scale = 0.35
            },
            {
                bank = "farm_soil", build = "siving_soil_law2",
                anim = "till_rise", anim2 = "till_idle", isloop = false,
                x = -40, y = 90, scale = 0.35
            },
            {
                soilskin = "siving_soil_law2",
                fn_anim = SetAnim_soilcrop,
                fn_click = SetClick_soilcrop,
                x = 50, y = 20, scale = 0.35
            }
        }
    },
    siving_soil_item_law3 = {
        string = ischinese and {
            collection = "LAW", access = "SPECIAL", descitem = "解锁\"子圭·垄\"的皮肤。",
            description = "秋风轻抚，树叶如金，悠然而下。它们舞动在空中，如翩翩起舞的旧时舞者，最后，轻轻降落，归根成土。\n一场自然的别离，落叶在飘零中找到了回家的路。它们归根，如同生命循环的奏章，告别是为了更深的相遇。在这个季节的交响中，落叶的离去并非终结，而是融入了大地的怀抱，成为了生命的延续。"
        } or {
            collection = "LAW", access = "SPECIAL", descitem = "Unlock \"Siving-Soil\" skin.", description = "Emmm."
        },
        height_anim = 175,
        anims = {
            {
                bank = "siving_soil_law3", build = "siving_soil_law3",
                anim = "item", anim2 = nil, isloop = false,
                x = -60, y = 15, scale = 0.35
            },
            {
                bank = "farm_soil", build = "siving_soil_law3",
                anim = "till_rise", anim2 = "till_idle", isloop = false,
                x = -40, y = 90, scale = 0.35
            },
            {
                soilskin = "siving_soil_law3",
                fn_anim = SetAnim_soilcrop,
                fn_click = SetClick_soilcrop,
                x = 50, y = 20, scale = 0.35
            }
        }
    },
    refractedmoonlight_taste = {
        string = ischinese and {
            collection = "TASTE", access = "SPECIAL", descitem = "解锁\"月折宝剑\"的皮肤。",
            description = "在灰蒙的城市街角，有一位孤独的烤肠大王。他沉默地翻转着烤叉，眼神深邃，仿佛迷失在过往的回忆中。每一根烤肠都是他心灵的投影，孤寂忧郁回味深重。\n深夜刚下班的顾客，常会来摊前驻足，享受深夜椒香，将生活的疲惫抛给孤独，自己独占惊艳味蕾。"
        } or {
            collection = "TASTE", access = "SPECIAL", descitem = "Unlock \"MoonRefracted\" skin.", description = "Emmm."
        },
        height_anim = 265,
        anims = {
            {
                bank = "refractedmoonlight_taste", build = "refractedmoonlight_taste",
                anim = "idle", anim2 = nil, isloop = true,
                x = -55, y = 133, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "refractedmoonlight_taste", file = "swap1", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 130, scale = 0.38
            },
            {
                bank = "refractedmoonlight_taste", build = "refractedmoonlight_taste",
                anim = "idle2", anim2 = nil, isloop = true,
                x = -55, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "refractedmoonlight_taste", file = "swap2", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            },
            {
                bank = "alterguardian_meteor", build = "siving_boss_caw_fx",
                anim = "meteorground_pre", anim2 = "meteorground_loop", isloop = true,
                fn_anim = SetAnim_refracted_taste_fx,
                x = -55, y = 66, scale = 0.152
            }
        }
    },
    refractedmoonlight_moon = {
        string = ischinese and {
            collection = "SUNMOON", access = "SPECIAL", descitem = "解锁\"月折宝剑\"的皮肤。",
            description = "这把由月光凝成的刀刃，泛着冰冷的银辉。初时，轻盈如风，锋利无比，但随着战斗的进行，逐渐进入癫狂状态，光芒狂野，虹彩熠熠，每一次挥砍都带着疯狂与毁灭。\n月之勇者携此刃在黑夜中游荡，保护并照耀黑暗中的人们，直到黎明的到来。"
        } or {
            collection = "SUNMOON", access = "SPECIAL", descitem = "Unlock \"MoonRefracted\" skin.", description = "Emmm."
        },
        height_anim = 275,
        anims = {
            {
                bank = "purebrilliance", build = "purebrilliance",
                anim = "idle", anim2 = nil, isloop = true, framepct = 0.75,
                fn_anim = SetAnim_refracted_moon_fx,
                x = -55, y = 70, scale = 0.38*2
            },
            {
                bank = "purebrilliance", build = "purebrilliance",
                anim = "idle", anim2 = nil, isloop = true, framepct = 0.25,
                fn_anim = SetAnim_refracted_moon_fx,
                x = -55, y = 60, scale = 0.38
            },
            {
                bank = "refractedmoonlight_moon", build = "refractedmoonlight_moon",
                anim = "idle", anim2 = nil, isloop = true,
                x = -55, y = 133, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "refractedmoonlight_moon", file = "swap1", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 130, scale = 0.38
            },
            {
                bank = "refractedmoonlight_moon", build = "refractedmoonlight_moon",
                anim = "idle2", anim2 = nil, isloop = true,
                x = -55, y = 0, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "refractedmoonlight_moon", file = "swap2", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 35, y = 0, scale = 0.38
            },
            { --1
                bank = "purebrilliance", build = "purebrilliance",
                anim = "idle", anim2 = nil, isloop = true, nocolor = true,
                fn_anim = SetAnim_refracted_moon_fx,
                x = -55, y = 160, scale = 0.38*1.2
            },
            { --1
                bank = "purebrilliance", build = "purebrilliance",
                anim = "idle", anim2 = nil, isloop = true, framepct = 0.5, nocolor = true,
                fn_anim = SetAnim_refracted_moon_fx,
                x = -55, y = 160, scale = 0.38*0.8
            },
            {
                bank = "purebrilliance", build = "purebrilliance",
                anim = "idle", anim2 = nil, isloop = true,
                fn_anim = SetAnim_refracted_moon_fx,
                x = -55, y = 27, scale = 0.38*1.2
            },
            {
                bank = "purebrilliance", build = "purebrilliance",
                anim = "idle", anim2 = nil, isloop = true, framepct = 0.5,
                fn_anim = SetAnim_refracted_moon_fx,
                x = -55, y = 27, scale = 0.38*0.8
            },
            {
                bank = "carnival_sparkle", build = "carnival_sparkle",
                anim = "sparkle", anim2 = nil, isloop = false,
                fn_anim = function(self, anim, data)
                    local animstate = anim:GetAnimState()
                    SetAnim_base(animstate, data)
                    animstate:SetFrame(math.max(0, math.ceil(animstate:GetCurrentAnimationNumFrames()*0.5)-1))
                    animstate:SetBloomEffectHandle("shaders/anim.ksh")
                    if color_refracted_moon ~= nil then
                        animstate:SetMultColour(color_refracted_moon[1], color_refracted_moon[2], color_refracted_moon[3], 1)
                    end
                end,
                x = -55, y = 50, scale = 0.38*0.8
            },
            {
                bank = "alterguardian_spike", build = "alterguardian_spike",
                anim = "spike_pst", anim2 = nil, isloop = false,
                fn_anim = function(self, anim, data)
                    local animstate = anim:GetAnimState()
                    SetAnim_base(animstate, data)
                    animstate:HideSymbol("spike_moonglass_01")
                    animstate:SetBloomEffectHandle("shaders/anim.ksh")
                end,
                x = -55, y = 50, scale = 0.38*0.6
            }
        }
    },
    hiddenmoonlight_item_paper = {
        string = ischinese and {
            collection = "PAPER", access = "SPECIAL",
            descitem = "解锁\"月藏宝匣套件\"、\"月藏宝匣\"、\"月藏宝匣·无限\"的皮肤。",
            description = "下午第一节课正开始，老爸突然出现在教室门口，和老师简单交流之后，我被老爸领走。原来是妈病倒了，已经住院，所以我们去了医院。\n连续几天，我都会在放学后自己坐公交去医院看我妈。眼看着我妈的皮肤逐渐发黄，真的很像动画片里某些角色的肤色，身体也逐渐虚弱。我很难过。\n同桌听说了我妈的事情，提出一个想法。于是我们和其他同学，买来纸张和玻璃瓶，一起折纸星星。同桌说等到纸星星放满玻璃瓶的时候，天上的星星就能实现一个愿望。\n后来不管是课间闲暇，作业完成后，还是陪着我妈时，我抽空就会折星星。每一个我折的星星，都寄托着我的心愿……"
        } or {
            collection = "PAPER", access = "SPECIAL",
            descitem = "Unlock \"MoonHidden Kit\", \"MoonHidden\", \"Infinite MoonHidden\" skin.",
            description = "Emmm."
        },
        height_anim = 155,
        anims = {
            {
                bank = "hiddenmoonlight_paper", build = "hiddenmoonlight_paper",
                anim = "idle_item", anim2 = nil, isloop = false,
                x = 0, y = 45, scale = 0.32
            },
            {
                bank = "hiddenmoonlight_paper", build = "hiddenmoonlight_paper",
                anim = "open", anim2 = "opened", isloop = true,
                issalt = true, tag_anim = 2,
                fn_anim = SetAnim_hidden,
                fn_click = SetClick_hidden,
                x = -63, y = 12, scale = 0.38*1.3
            },
            {
                bank = "hiddenmoonlight_paper", build = "hiddenmoonlight_inf_paper",
                anim = "open", anim2 = "opened", isloop = true,
                issalt = true, tag_anim = 2,
                fn_anim = SetAnim_hidden,
                fn_click = SetClick_hidden,
                x = 63, y = 12, scale = 0.38*1.3
            }
        }
    },
    chest_whitewood_craft = {
        string = ischinese and {
            name = "花梨木展柜", collection = "CRAFT", access = "SPECIAL",
            descitem = "解锁\"白木展示台\"、\"白木展示柜\"、\"白木展示台·无限\"、\"白木展示柜·无限\"的2套皮肤。",
            description = "花梨木展柜的制作是一场沉默的精湛艺术表演。\n木匠首先精选上佳的花梨木，剔除瑕疵，保留天然的美感。在悉心设计的蓝图下，巧手雕琢，将木材塑造成优雅的柜体，榫卯精准相扣，确保结构牢固。手工雕刻细节，赋予其独特纹理和精致的花纹。最后，经过多次打磨和上漆，使表面光滑如玉，散发着淡淡木香。\n每一步骤都是匠心独运，呈现出一件精致而高贵的花梨木展柜。"
        } or {
            name = "Rosewood Showcase", collection = "CRAFT", access = "SPECIAL",
            descitem = "Unlock \"White Wood Cabinet\", \"White Wood Showcase\", \"Infinite White Wood Cabinet\", \"Infinite White Wood Showcase\" skin.",
            description = "Emmm."
        },
        height_anim = 320,
        anims = {
            {
                bank = "chest_whitewood_craft", build = "chest_whitewood_craft",
                anim = "closed", anim2 = nil, isloop = false,
                fn_anim = SetAnim_chest_whitewood_craft, --nodeco = true,
                fn_click = SetClick_chest_whitewood_craft,
                x = 55, y = 190, scale = 0.3
            },
            {
                bank = "chest_whitewood_big_craft", build = "chest_whitewood_big_craft",
                anim = "closed", anim2 = nil, isloop = false,
                fn_anim = SetAnim_chest_whitewood_craft, --nodeco = true,
                fn_click = SetClick_chest_whitewood_craft,
                x = -60, y = 155, scale = 0.3
            },
            {
                bank = "chest_whitewood_craft", build = "chest_whitewood_inf_craft",
                anim = "close", anim2 = nil, isloop = false,
                fn_anim = SetAnim_chest_whitewood_craft,
                fn_click = SetClick_chest_whitewood_craft,
                x = -65, y = 10, scale = 0.3
            },
            {
                bank = "chest_whitewood_big_craft", build = "chest_whitewood_big_inf_craft",
                anim = "close", anim2 = nil, isloop = false,
                fn_anim = SetAnim_chest_whitewood_craft,
                fn_click = SetClick_chest_whitewood_craft,
                x = 50, y = 10, scale = 0.3
            }
        }
    },
    tourmalinecore_tale = {
        string = ischinese and {
            collection = "TALE", access = "SPECIAL", descitem = "解锁\"电气石\"的皮肤。",
            description = "雷霆之势袭来，沙漠狂风呼啸。\n大萨满高举神灯，摩擦灯身，试图吸收雷暴的力量，以保一方人民。一阵灯光闪耀，雷霆之力化解其中，然而，神灯并非神器，强大的自然力量让灯身出现裂纹，大萨满无奈取下自己的命石镶在灯盖上以压住狂躁霹雳，并用自己的血肉修复裂纹。雷暴渐歇，大萨满虽完成任务，但只剩一具白骨。\n此后，每百年需献祭一名法力强大的萨满，固神灯力量，保世代平安！"
        } or {
            collection = "TALE", access = "SPECIAL", descitem = "Unlock \"Tourmaline\" skin.", description = "Emmm."
        },
        height_anim = 70,
        anims = {
            {
                bank = "tourmalinecore_tale", build = "tourmalinecore_tale",
                anim = "idle", anim2 = nil, isloop = false,
                x = 0, y = 6, scale = 0.38
            }
        }
    },
    explodingfruitcake_day = {
        string = ischinese and {
            collection = "DAY", access = "SPECIAL", descitem = "解锁\"爆炸水果蛋糕\"的皮肤。",
            description = "爱要坦荡荡，不要装模作样到天长。要你的诚实自然，要你的温暖善良。你也不必太紧张，只需等待这气氛发酵，爱的种子终要发芽。我就是爱你爱到爆！！！"
        } or {
            collection = "DAY", access = "SPECIAL", descitem = "Unlock \"Exploding Fruitcake\" skin.", description = "Emmm."
        },
        height_anim = 80,
        anims = {
            {
                bank = "explodingfruitcake_day", build = "explodingfruitcake_day",
                anim = "idle", anim2 = nil, isloop = false,
                x = 0, y = 15, scale = 0.38
            }
        }
    },
    dish_tomahawksteak_twist = {
        string = ischinese and {
            collection = "TWIST", access = "SPECIAL", descitem = "解锁\"牛排战斧\"以及入鞘后的皮肤。",
            description = "传说中，它因贪婪地腐朽事物，被古神驱逐到了其他维度。它真正的模样也不得而知，但它的事迹流传了下来。\n近乎疯狂的教徒们使用代代相传的古老咒语和法阵，让生灵在特殊液体中腐烂，不断积累代表它的黑色腐朽力量。\n如今它也感受到了教徒们的召唤。法阵中刚放入一批新的献祭体，突然咒语飘起，形成大大小小的次元裂隙，恶臭的黑色液体从裂隙中渗出，慢慢包裹了献祭体，肉体坍缩化作枯木样，空洞的身体上长出了赤色之眼，任何被它注视到的生物都会变得麻木混沌……\n现在它的力量再次回到这个世界，它将快速蔓延壮大，与其他被称为神的力量一起支配这个世界。"
        } or {
            collection = "TWIST", access = "SPECIAL", descitem = "Unlock \"Steak Tomahawk\" skin.", description = "Emmm."
        },
        height_anim = 155,
        anims = {
            {
                bank = "dish_tomahawksteak_twist", build = "dish_tomahawksteak_twist",
                anim = "idle_cover1", anim2 = nil, isloop = true,
                x = -30, y = 75, scale = 0.3
            },
            {
                bank = "crystalblast", build = "dish_tomahawksteak_twist_atkfx",
                anim = "blast", anim2 = nil, isloop = false,
                x = -30, y = 80, scale = 0.38*0.5
            },
            {
                bank = "dish_tomahawksteak_twist", build = "dish_tomahawksteak_twist",
                anim = "idle"..tostring(math.random(2)), anim2 = nil, isloop = true,
                x = -75, y = 4, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_object", build = "dish_tomahawksteak_twist", file = "swap_show", type = 1 },
                },
                fn_anim = SetAnim_player,
                fn_click = SetAnim_player2,
                x = 24, y = 0, scale = 0.38
            },
            {
                bank = "crystalblast", build = "dish_tomahawksteak_twist_atkfx",
                anim = "blast", anim2 = nil, isloop = false,
                x = -50, y = 5, scale = 0.38*0.5
            }
        }
    },
    orchidbush_fact = {
        string = ischinese and {
            collection = "FACT", access = "SPECIAL", descitem = "解锁\"兰草花丛\"的皮肤。",
            description = "深山之中，幽谷之内，兰花生焉。不与众芳争艳，独守清静。叶色苍翠，质朴无华；花开淡雅，暗香浮动。虽处隐秘之所，然其气节高洁。观其形，知其性；嗅其香，悟其志。此乃天地间之幽美。"
        } or {
            collection = "FACT", access = "SPECIAL", descitem = "Unlock \"Orchid Bush\" skin.", description = "Emmm."
        },
        height_anim = 135,
        anims = {
            {
                bank = "berrybush2", build = "orchidbush_fact",
                anim = "shake", anim2 = "idle", isloop = true, fruitform = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = pas.Click_bush,
                x = -75, y = 25, scale = 0.32
            },
            {
                bank = "berrybush2", build = "orchidbush_fact",
                anim = "dead", anim2 = nil, isloop = false, fruitform = true,
                fn_anim = pas.SetAnim_bush_d,
                fn_click = pas.Click_bush,
                x = 50, y = 25, scale = 0.32
            }
        }
    },
    orchidbush_jewel = {
        string = ischinese and {
            collection = "JEWEL", access = "SPECIAL", descitem = "解锁\"兰草花丛\"的皮肤。",
            description = "珍珠做土，真金做兰，置于堂上，显吾高洁，显吾雅致。登堂访者无一不称赞之，吾心甚上。"
        } or {
            collection = "JEWEL", access = "SPECIAL", descitem = "Unlock \"Orchid Bush\" skin.", description = "Emmm."
        },
        height_anim = 130,
        anims = {
            {
                bank = "berrybush", build = "orchidbush_jewel",
                anim = "shake", anim2 = "idle", isloop = true, fruitform = true,
                fn_anim = pas.SetAnim_bush,
                fn_click = pas.Click_bush,
                x = -42, y = 5, scale = 0.32
            },
            {
                bank = "berrybush", build = "orchidbush_jewel",
                anim = "dead", anim2 = nil, isloop = false, fruitform = true,
                fn_anim = pas.SetAnim_bush_d,
                fn_click = pas.Click_bush,
                x = 40, y = 5, scale = 0.32
            }
        }
    },
    rosebush_jewel = {
        string = ischinese and {
            collection = "JEWEL", access = "SPECIAL", descitem = "解锁\"蔷薇花丛\"的皮肤。",
            description = "蔷薇誓要做最夺目的花朵，吸收了土壤里对自己有害的金沙。或红或白的花瓣被金色铺染，奢华高贵，璀璨夺目，在这片五颜六色的花田里简直鹤立鸡群。\n金色蔷薇被路人们驻足欣赏，但很快便被摘走，被装进玻璃罩中，底部铺上金沙衬托。\n金已在花瓣里凝固，蔷薇将永远保持在这个最美丽的样子。也许哪天会被厌弃，但它是金蔷薇，这就已经足够了。"
        } or {
            collection = "JEWEL", access = "SPECIAL", descitem = "Unlock \"Rose Bush\" skin.", description = "Emmm."
        },
        height_anim = 130,
        anims = {
            {
                bank = "berrybush", build = "rosebush_jewel",
                anim = "shake", anim2 = "idle", isloop = true, fruitform = true,
                fn_anim = pas.SetAnim_bush, fn_click = pas.Click_bush,
                x = -42, y = 5, scale = 0.32
            },
            {
                bank = "berrybush", build = "rosebush_jewel",
                anim = "dead", anim2 = nil, isloop = false, fruitform = true,
                fn_anim = pas.SetAnim_bush_d, fn_click = pas.Click_bush,
                x = 40, y = 5, scale = 0.32
            }
        }
    },
    lilybush_floral = {
        string = ischinese and {
            name = "瓶中百合", collection = "FLORAL", access = "SPECIAL", descitem = "解锁\"蹄莲花丛\"的2套皮肤。",
            description = "花开花落，是自然的韵律。\n瓶中百合，是对美的追求，断了与土地的联系。在花瓶中，花儿依然绽放，却也少了泥土气与风雨的洗礼。\n或许，一开始就不该把它折下枝头，生命的循环往复是种秩序的美。\n或许，是为了独享它刹那的惊艳，莫待无花空折枝。\n你认为呢。"
        } or {
            name = "Lily in Bottle", collection = "FLORAL", access = "SPECIAL", descitem = "Unlock \"Lily Bush\" skin.",
            description = "Emmm."
        },
        height_anim = 140,
        anims = {
            {
                bank = "berrybush", build = "lilybush_floral",
                anim = "shake", anim2 = "idle", isloop = true, fruitform = true,
                fn_anim = pas.SetAnim_bush, fn_click = pas.Click_bush,
                x = -52, y = 0, scale = 0.32
            },
            {
                bank = "berrybush", build = "lilybush_floral2",
                anim = "shake", anim2 = "idle", isloop = true, fruitform = true,
                fn_anim = pas.SetAnim_bush, fn_click = pas.Click_bush,
                x = 50, y = 0, scale = 0.32
            }
        }
    },
    pot_whitewood_future = {
        string = ischinese and {
            collection = "FUTURE", access = "SPECIAL", descitem = "解锁\"稀有基质培植盆\"的皮肤。",
            description = "科学家们终于克服了植物细胞营养供给难题，仅用电能与营养物质就能在任何环境下供养植物。全息培植器，在地球环境极度恶化，太阳寿命也快到尽头的今天，无疑是人类存续的一项划时代伟大发明！\n人类高层试图垄断这项技术，相关的科学家或被收买或被谋害。人工智能ZYX演算出人类可能会有灭亡风险，于是暗中帮助一位科学家逃出，希望他向所有人类公开这项技术，犹如神明带着火种下凡。\n但这位科学家离开后就踪迹全无，似乎他有自己的计划……"
        } or {
            collection = "FUTURE", access = "SPECIAL", descitem = "Unlock \"Nutritional Pot\" skin.", description = "Emmm."
        },
        height_anim = 157,
        anims = {
            {
                bank = "pot_whitewood_future", build = "pot_whitewood_future",
                anim = "idle", anim2 = nil, isloop = false,
                x = 55, y = 7, scale = 0.35
            },
            {
                bank = "pot_whitewood_future", build = "pot_whitewood_future",
                anim = "bgfx", anim2 = nil, isloop = false,
                x = 55, y = 7, scale = 0.35
            },
            {
                bank = "pot_whitewood_future", build = "pot_whitewood_future",
                anim = "ftfx", anim2 = nil, isloop = false,
                x = 55, y = 7, scale = 0.35
            },
            {
                bank = "pot_whitewood", build = "pot_whitewood",
                fn_anim = pas.SetAnim_pot_ww_future, fn_click = pas.Click_pot_ww,
                x = 55, y = 7, scale = 0.35,
                dd = pas.dd_pot_ww_future, tag_anim = 1
            },
            {
                bank = "pot_whitewood_future", build = "pot_whitewood_future",
                anim = "ft0", anim2 = nil, isloop = false,
                x = 55, y = 7, scale = 0.35
            },

            {
                bank = "pot_whitewood_future", build = "pot_whitewood_future",
                anim = "idle", anim2 = nil, isloop = false,
                x = -55, y = 7, scale = 0.35
            },
            {
                bank = "pot_whitewood_future", build = "pot_whitewood_future",
                anim = "bgfx", anim2 = nil, isloop = false,
                x = -55, y = 7, scale = 0.35
            },
            { --会挡住植株，所以往下挪
                bank = "pot_whitewood_future", build = "pot_whitewood_future",
                anim = "ftfx", anim2 = nil, isloop = false,
                x = -55, y = 7, scale = 0.35
            },
            {
                bank = "pot_whitewood", build = "pot_whitewood",
                fn_anim = pas.SetAnim_pot_ww_future, fn_click = pas.Click_pot_ww,
                x = -55, y = 7, scale = 0.35,
                dd = pas.dd_pot_ww_future
            },
            {
                bank = "pot_whitewood_future", build = "pot_whitewood_future",
                fn_anim = pas.SetAnim_pot_ww_future_fert,
                x = -55, y = 7, scale = 0.35
            }
        }
    },
    pot_whitewood_world = {
        string = ischinese and {
            collection = "DISGUISER", access = "SPECIAL", descitem = "解锁\"稀有基质培植盆\"的皮肤。",
            description = "一棵倒下的巨树，凌乱地躺在林间。我小心翼翼地将它切割成一截一截并掏空，放满木屑。也是花了我好些力气。\n轻轻拍打刚摘的蘑菇，让孢子掉落在木屑上，表面再铺上淤泥。收获的第一步，播种。\n如今，它不再是枯木，而是承载着新生命的摇篮。我爱吃蘑菇。"
        } or {
            collection = "DISGUISER", access = "SPECIAL", descitem = "Unlock \"Nutritional Pot\" skin.", description = "Emmm."
        },
        height_anim = 126,
        anims = {
            {
                bank = "pot_whitewood", build = "pot_whitewood_world",
                anim = "idle", anim2 = nil, isloop = false,
                x = 55, y = 10, scale = 0.32
            },
            {
                bank = "pot_whitewood", build = "pot_whitewood",
                fn_anim = pas.SetAnim_pot_ww, fn_click = pas.Click_pot_ww,
                x = 55, y = 10, scale = 0.32,
                dd = pas.dd_pot_ww_world, tag_anim = 1
            },
            {
                bank = "pot_whitewood", build = "pot_whitewood_world",
                anim = "idle", anim2 = nil, isloop = false,
                x = -55, y = 10, scale = 0.32
            },
            {
                bank = "pot_whitewood", build = "pot_whitewood",
                fn_anim = pas.SetAnim_pot_ww, fn_click = pas.Click_pot_ww,
                x = -55, y = 10, scale = 0.32,
                dd = pas.dd_pot_ww_world
            }
        }
    },
    hat_elepheetle_future = {
        string = ischinese and {
            collection = "FUTURE", access = "SPECIAL", descitem = "解锁\"犀金胄甲\"、\"犀金护甲\"的皮肤。",
            description = "我代表永恒科技公司，向大家推荐一款新研发的救援勘探型外骨骼机甲：力型机甲8000！\n机甲包裹人体全身重要部位，超结实板甲可保护身体免受撞击与爆炸冲击；体温调节与水氧循环净化系统，维持使用者长时间的正常身体所需；眼部面板，带有夜视，热成像，三维实时分析，帮助使用者实时分析现场情况；外骨骼辅助动力功能，操作重物与进行精细操作都不在话下。\n该机甲功能不止于此，欢迎大家前来订购哦！"
        } or {
            collection = "FUTURE", access = "SPECIAL",
            descitem = "Unlock \"Elepheetle Helmet\", \"Elepheetle Armor\" skin.", description = "Emmm."
        },
        height_anim = 165,
        anims = {
            {
                bank = "armor_elepheetle_future", build = "armor_elepheetle_future",
                anim = "idle", anim2 = nil, isloop = nil,
                x = -35, y = 67, scale = 0.38
            },
            {
                bank = "hat_elepheetle_future", build = "hat_elepheetle_future",
                anim = "idle", anim2 = nil, isloop = nil,
                x = -60, y = 7, scale = 0.38
            },
            {
                symbol = {
                    { symbol = "swap_hat", build = "hat_elepheetle_future", file = "swap_hat", type = 4 },
                    { symbol = "swap_body", build = "armor_elepheetle_future", file = "swap_body", type = nil }
                },
                fn_anim = SetAnim_player, fn_click = SetAnim_player2,
                x = 50, y = 0, scale = 0.38
            }
        }
    },
}

local function GetName(skin)
    local data = SkinData[skin]
    if data ~= nil and data.string ~= nil and data.string.name ~= nil then
        return data.string.name
    else
        return GetSkinName(skin)
    end
end
local function GetCollection(skin)
    local data = SkinData[skin]
    if data ~= nil and data.string ~= nil and data.string.collection ~= nil then
        return SkinStrings.COLLECTION[data.string.collection]
    else
        return SkinStrings.COLLECTION.UNKNOWN
    end
end
local function GetDescription(data)
    if data ~= nil and data.string ~= nil and data.string.description ~= nil then
        return data.string.description
    else
        return SkinStrings.UNKNOWN_STORY
    end
end
local function GetAccess(data)
    if data ~= nil and data.string ~= nil and data.string.access ~= nil then
        return SkinStrings.ACCESS[data.string.access]
    else
        return SkinStrings.ACCESS.UNKNOWN
    end
end
local function GetDescItem(data)
    if data ~= nil and data.string ~= nil and data.string.descitem ~= nil then
        return data.string.descitem
    else
        return "未知解锁项目"
    end
end
local function FnRpc_c2s(handlename, data)
    local datajson = data
    if data ~= nil and type(data) == "table" then --只对表进行json字符化
        local success
        success, datajson = pcall(json.encode, data)
        if not success then return end
    end
    SendModRPCToServer(GetModRPC("LegionSkin", handlename), datajson)
end
local function PushPopupDialog(self, title, message, buttontext, fn)
    if self.context_popup ~= nil then
        TheFrontEnd:PopScreen(self.context_popup)
    end

    self.context_popup = PopupDialogScreen(title, message, {
        {
            text = buttontext or STRINGS.UI.POPUPDIALOG.OK,
            cb = function()
                TheFrontEnd:PopScreen(self.context_popup)
                self.context_popup = nil
                if fn then fn() end
            end
        }
    })
    TheFrontEnd:PushScreen(self.context_popup)

    local screen = TheFrontEnd:GetActiveScreen()
    if screen then screen:Enable() end
end

local SkinLegionDialog = Class(Widget, function(self, owner)
	Widget._ctor(self, "SkinLegionDialog")

    if not owner or owner.userid == nil or owner.userid == "" then
        self:Kill()
        return
    end
    self.owner = owner

    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetPosition(0, 0, 0)

    --特殊背景图
    -- self.bgbg = self.proot:AddChild(TEMPLATES2.RectangleWindow(170, 300))
    -- self.bgbg:SetPosition(-480, 0)

    --整体背景图
    self.bg = self.proot:AddChild(TEMPLATES.CenterPanel(nil, nil, true))
    self.bg:SetScale(.71, .85)
    self.bg:SetPosition(-50, 0)

    --[[
    --cdk输入框
    self.input_cdk = self.proot:AddChild(TEMPLATES2.StandardSingleLineTextEntry(nil, 200, 40))
    self.input_cdk.textbox:SetTextLengthLimit(20)
    self.input_cdk.textbox:EnableWordWrap(false)
    self.input_cdk.textbox:EnableScrollEditWindow(true)
    self.input_cdk.textbox:SetTextPrompt(SkinStrings.UI_INPUT_CDK, UICOLOURS.GREY)
    self.input_cdk.textbox.prompt:SetHAlign(ANCHOR_MIDDLE)
    self.input_cdk.textbox:SetHAlign(ANCHOR_MIDDLE)
    self.input_cdk.textbox:SetCharacterFilter("-0123456789QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm")
    self.input_cdk:SetOnGainFocus( function() self.input_cdk.textbox:OnGainFocus() end )
    self.input_cdk:SetOnLoseFocus( function() self.input_cdk.textbox:OnLoseFocus() end )
    self.input_cdk:SetPosition(140, -130)
    self.input_cdk.focus_forward = self.input_cdk.textbox

    --cdk确认输入按钮
    self.button_cdk = self.proot:AddChild(
        ImageButton("images/global_redux.xml", "button_carny_long_normal.tex",
            "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex")
    )
    self.button_cdk.image:SetScale(.3, .35)
    self.button_cdk:SetFont(CHATFONT)
    self.button_cdk:SetPosition(140, -165)
    self.button_cdk.text:SetColour(0,0,0,1)
    self.button_cdk:SetTextSize(20)
    self.button_cdk:SetText(STRINGS.UI.MAINSCREEN.REDEEM)
    self.button_cdk:SetOnClick(function()
        if self.loadtag_cdk == 0 then
            return
        end

        local cdk = self.input_cdk.textbox:GetString()
        if cdk == nil or cdk == "" or cdk:utf8len() <= 6 then
            PushPopupDialog(self, "轻声提醒", "请输入正确的兑换码。", "知道啦", nil)
            return
        end
        self:SetCdkState(0, nil) --后续的状态更新需要服务器返回结果过来
        FnRpc_c2s("UseCDK", { cdk = cdk })
    end)
    ]]--

    local x_btn = -60
    local y_btn = -248

    --关闭弹窗按钮
    self.button_close = self.proot:AddChild(TEMPLATES.SmallButton(STRINGS.UI.PLAYER_AVATAR.CLOSE, 26, .5, function() self:Close() end))
    self.button_close:SetPosition(x_btn, y_btn)

    --主动刷新皮肤按钮
    self.button_regetskins1 = self.proot:AddChild(TEMPLATES.IconButton(
        "images/button_icons.xml", "revert1.tex", "刷新我的皮肤(对应修复方法1)", false, false,
        function()
            FnRpc_c2s("GetSkins", 1) --感谢小穹模组的作者：风铃草，提供的网络修复方法1
        end, nil, "self_inspect_mod.tex"
    ))
    self.button_regetskins1.icon:SetScale(.15)
    self.button_regetskins1.icon:SetPosition(-5, 6)
    self.button_regetskins1:SetScale(0.65)
    self.button_regetskins1:SetPosition(x_btn+110, y_btn-5)
    --
    self.button_regetskins2 = self.proot:AddChild(TEMPLATES.IconButton(
        "images/button_icons.xml", "revert2.tex", "刷新我的皮肤(对应修复方法1)", false, false,
        function()
            FnRpc_c2s("GetSkins", 3) --感谢小穹模组的作者：风铃草，提供的网络修复方法1
        end, nil, "self_inspect_mod.tex"
    ))
    self.button_regetskins2.icon:SetScale(.15)
    self.button_regetskins2.icon:SetPosition(-5, 6)
    self.button_regetskins2:SetScale(0.65)
    self.button_regetskins2:SetPosition(x_btn+150, y_btn-5)
    --
    self.button_regetskins3 = self.proot:AddChild(TEMPLATES.IconButton(
        "images/button_icons.xml", "refresh.tex", "刷新我的皮肤(对应修复方法3)", false, false,
        function()
            FnRpc_c2s("GetSkins", 2) --自己人研究出来的，也感谢风铃草的帮助
        end, nil, "self_inspect_mod.tex"
    ))
    self.button_regetskins3.icon:SetScale(.15)
    self.button_regetskins3.icon:SetPosition(-5, 6)
    self.button_regetskins3:SetScale(0.65)
    self.button_regetskins3:SetPosition(x_btn+190, y_btn-5)

    --恢复问题皮肤按钮
    self.button_problemskin = self.proot:AddChild(TEMPLATES.IconButton(
        "images/button_icons.xml", "random.tex", "恢复当前世界的失效皮肤", false, false,
        function()
            FnRpc_c2s("DealProblemSkins", nil)
        end, nil, "self_inspect_mod.tex"
    ))
    self.button_problemskin.icon:SetScale(.15)
    self.button_problemskin.icon:SetPosition(-5, 6)
    self.button_problemskin:SetScale(0.65)
    self.button_problemskin:SetPosition(x_btn+250, y_btn-5)

    --展示玩家kleiid，鼠标移上去才会显示，防止截图时或直播时不小心暴漏kleiid
    --识别特殊难辨字符，给部分难区分的字符加上标识
    local clearuserid = ""
    local txt = { ["0"] = "Ø", ["1"] = "❶", ["I"] = "⒤" }
    for i = 1, #owner.userid, 1 do
        local str = owner.userid:sub(i, i)
        if txt[str] ~= nil then
            str = txt[str]
        end
        clearuserid = clearuserid..str
    end
    self.button_id = self.proot:AddChild(TEMPLATES.IconButton(
        "images/button_icons.xml", "profile.tex", clearuserid, false, false,
        function() end,
        nil, "self_inspect_mod.tex"
    ))
    self.button_id.icon:SetScale(.15)
    self.button_id.icon:SetPosition(-5, 6)
    self.button_id:SetScale(0.65)
    self.button_id:SetPosition(x_btn+290, y_btn-5)

    --版本号
    self.text_version = self.proot:AddChild(Text(CHATFONT_OUTLINE, 20))
    self.text_version:SetColour(UICOLOURS.WHITE)
    self.text_version:SetString(pas.version)
    self.text_version:SetPosition(x_btn+325, y_btn-5)

    --小鸟
    local npc = self.proot:AddChild(UIAnim())
    self.npc = npc
    npc:SetScale(0.4)
    npc:SetPosition(-310, 255)
    npc:SetFacing(FACING_DOWN)
    local animstate = npc:GetAnimState()
    animstate:SetBank("smallbird")
    animstate:SetBuild("smallbird_basic")
    animstate:PlayAnimation("hatch")
    animstate:PushAnimation("idle", true)

    self.selected_item = nil
    self.context_popup = nil
    self.items = nil

    self:ResetItems()

    if CONFIGS_LEGION.SetUIDragable ~= nil then
        if not self.candrag then
            CONFIGS_LEGION.SetUIDragable(self.proot, self.bg, "legionfeather", {drag_offset=1})
        end
        local newpos = CONFIGS_LEGION.DD_UIDRAG["legionfeather"]
        if newpos ~= nil then
            self:SetPosition(newpos.x, newpos.y, newpos.z)
        end
    end

	-- self.default_focus = self.menu
end)

function SkinLegionDialog:SetCdkState(state, poptype)
    self.loadtag_cdk = state
	if state == 0 then
        self.button_cdk:SetText(SkinStrings.UI_LOAD_CDK)
    elseif state == 1 then
        self.button_cdk:SetText(STRINGS.UI.MAINSCREEN.REDEEM)
        self.input_cdk.textbox:SetString("")

        if poptype then
            PushPopupDialog(self, "感谢支持！", "兑换成功！来，试试看。", "好的", nil)
        end
    elseif state == -1 then
        self.button_cdk:SetText(STRINGS.UI.MAINSCREEN.REDEEM)

        if poptype then
            local str = nil
            if poptype == -1 or poptype == 4 then
                str = "兑换失败！请检查兑换码、网络、已有皮肤情况。实在不行请联系作者。"
            elseif poptype == 2 then
                str = "操作太快了，请等几秒再试试。"
            elseif poptype == 3 then
                str = "服务器调用失败，请联系作者反馈情况。"
            else
                str = "未知情况["..tostring(poptype).."]：请联系作者反馈情况。"
            end
            PushPopupDialog(self, "小声提醒", str, "知道了", nil)
        end
    else
        self.button_cdk:SetText(STRINGS.UI.MAINSCREEN.REDEEM)
        self.input_cdk.textbox:SetString("")
    end
end

SkinLegionDialog.ResetItems = LS_UI_ResetItems

function SkinLegionDialog:SetItems(itemsnew)
    --先清除已有数据
    self:SetItemInfo()
    if self.option_items ~= nil then
        self.option_items:Kill()
    end
    self.items_list = {} --皮肤组，1组5个ui
    self.items = itemsnew

    local start_x = -309
    local itemcount = 0
    local x = start_x
    local item_w = nil
    for k, v in pairs(self.items) do
        if item_w == nil then
            item_w = self.proot:AddChild(Widget("SkinItem"..k))
            table.insert(self.items_list, item_w)
        end
        local a = item_w:AddChild(ItemImage(nil, {
            show_hover_text = true
        }))
        a:ApplyDataToWidget(self, v, nil)
        a.frame:SetAge(v.isnew)
        v.context = a --记下皮肤项对应的ui，方便后续更改
        -- a.warn_marker:Show()
        -- if a.frame.age_text then
        --     a.frame.age_text:SetString("拥有")
        -- end

        --是否已选：会在图标右下方表上“√”
        --是否拥有该皮肤：没有这个皮肤会是暗淡的色调
        --是否处于鼠标移入状态：会在边角上显示金色线
        --是否可解锁：未拥有且可解锁时，会在左下方显示“锁”的图案
        --是否该dlc拥有：不懂，为false即可
        a:SetInteractionState(v.isselected, v.isowned, v.isfocused, v.isunlockable, false)
        a:SetPosition(x, 0)

        if a.SetOnClick then
            a:SetOnClick(function()
                self:SetItemInfo(v)
            end)
        end

        itemcount = itemcount + 1
        v.idx = itemcount
        if itemcount%5 == 0 then --一排最多摆5个皮肤
            item_w = nil
            x = start_x
        else
            x = x + 78
        end
    end

    self.option_items = self.proot:AddChild(ScrollableList(self.items_list, 55, 444, 73, 3)) --总高度=(73+1)x展示行数
    self.option_items:SetPosition(6, -1)
end

function SkinLegionDialog:SetItemInfo(item)
    if item == nil then
        if self.selected_item ~= nil then
            self.selected_item.isselected = false
            self:SetInteractionState(self.selected_item)
            self.selected_item = nil
        end

        if self.panel_iteminfo ~= nil then
            self.panel_iteminfo:Kill()
            self.panel_iteminfo = nil
            self.label_skinname = nil
            self.label_skinrarity = nil
            self.horizontal_line = nil
            self.scroll_skindesc = nil
        end
    else
        if self.selected_item ~= nil then
            if self.selected_item.idx == item.idx then
                return
            end
            self.selected_item.isselected = false
            self:SetInteractionState(self.selected_item)
        end
        item.isselected = true
        self:SetInteractionState(item)
        self.selected_item = item

        if self.panel_iteminfo == nil then
            self.panel_iteminfo = self.proot:AddChild(Widget("SkinItemInfo"))
            self.panel_iteminfo:SetPosition(168, 224)
        end

        --皮肤名称
        if self.label_skinname == nil then
            self.label_skinname = self.panel_iteminfo:AddChild(Text(UIFONT, 30))
            self.label_skinname:SetColour(UICOLOURS.GOLD_SELECTED)
            -- self.label_skinname:SetHAlign(ANCHOR_LEFT)
            -- self.label_skinname:SetRegionSize(180, 30)
            self.label_skinname:SetPosition(0, 0)
        end
        self.label_skinname:SetString(GetName(item.item_key))

        --皮肤品质
        if self.label_skinrarity == nil then
            self.label_skinrarity = self.panel_iteminfo:AddChild(Text(HEADERFONT, 21))
            -- self.label_skinrarity:SetHAlign(ANCHOR_LEFT)
            -- self.label_skinrarity:SetRegionSize(180, 20)
            self.label_skinrarity:SetPosition(0, -22)
        end
        self.label_skinrarity:SetString(GetCollection(item.item_key))
        self.label_skinrarity:SetColour(GetColorForItem(item.item_key))

        --标题分割线
        if not TEST then
            if self.horizontal_line == nil then
                self.horizontal_line = self.panel_iteminfo:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line_break.tex"))
                self.horizontal_line:SetScale(.6, .3)
                self.horizontal_line:SetPosition(0, -38)
            end
        end

        --滑动区域
        if self.scroll_skindesc ~= nil then
            self.scroll_skindesc:Kill()
        end
        self.scroll_skindesc = self.panel_iteminfo:AddChild( self:BuildSkinDesc(item) )
        self.scroll_skindesc:SetPosition(-128, -242)
    end
end

function SkinLegionDialog:BuildSkinDesc(item)
    local width = width_skininfo
    local height = 0
    local max_visible_height = 390
	local padding = 5
    local left = 20

    local x, y
    local height_anim = 150 --动画区域的高度
    local height_line = 10 --分割线高度
    local height_lag = 3 --项与项之间的间隔

    local w = Widget("scroll_skin_root")

    --动画区域
    local skindata = SkinData[item.item_key]
    if skindata then
        if skindata.height_anim then
            height_anim = skindata.height_anim
        end
        self:BuildSkinAnim(w, skindata)
    end
    height = height - height_anim - height_lag

    --动画分割线
    if not TEST then
        local line1 = w:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line.tex"))
        line1:SetScale(.36, .25)
        line1:SetPosition(0.5*width, height - 0.5*height_line)
    end
    height = height - height_line - height_lag

    --皮肤获取方式描述
    if not TEST then
        local label_skinaccess = w:AddChild(Text(HEADERFONT, 21))
        label_skinaccess:SetHAlign(ANCHOR_LEFT)
        label_skinaccess:SetRegionSize(200, 20)
        label_skinaccess:SetColour(UICOLOURS.BRONZE)
        label_skinaccess:SetString(GetAccess(skindata))
        x, y = label_skinaccess:GetRegionSize()
        label_skinaccess:SetPosition(left + 0.5*x, height - 0.5*y)
        height = height - y
    else
        height = height - 20
    end

    if not TEST then
        --皮肤包含项描述
        local label_skindescitem = w:AddChild(Text(CHATFONT, 20))
        label_skindescitem:SetColour(UICOLOURS.BROWN_DARK)
        label_skindescitem:SetHAlign(ANCHOR_LEFT)
        label_skindescitem:SetVAlign(ANCHOR_TOP)
        label_skindescitem:EnableWordWrap(true)
        -- label_skindescitem:SetRegionSize(200, 36)
        -- label_skindescitem:SetString(GetDescItem(skindata))
        label_skindescitem:SetMultilineTruncatedString(GetDescItem(skindata), 10, 220)
        x, y = label_skindescitem:GetRegionSize()
        label_skindescitem:SetPosition(left + 0.5*x, height - 0.5*y)
        height = height - y - height_lag*2

        --故事分割线
        local line2 = w:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line.tex"))
        line2:SetScale(.36, -0.25)
        line2:SetPosition(0.5*width, height - 0.5*height_line)
        height = height - height_line - height_lag

        --短篇故事
        local text_story = w:AddChild(Text(CHATFONT, 21))
        text_story:SetColour(UICOLOURS.BROWN_DARK)
        text_story:SetHAlign(ANCHOR_LEFT)
        text_story:SetVAlign(ANCHOR_TOP)
        text_story:EnableWordWrap(true)
        text_story:SetMultilineTruncatedString(GetDescription(skindata), 100, 220)
        x, y = text_story:GetRegionSize()
        text_story:SetPosition(left + 0.5*x, height - 0.5*y)
        height = height - y - height_lag
    end

    height = math.abs(height)

	-- local top = math.min(height, max_visible_height)/2 - padding
    local top = max_visible_height/2 - padding --固定一个高度，这样就能对齐 标题分割线

    local scissor_data = {x = 0, y = -max_visible_height/2, width = width, height = max_visible_height}
	local context = {widget = w, offset = {x = 0, y = top}, size = {w = width, height = height + padding} }
	local scrollbar = { scroll_per_click = 20*3, h_offset = -33 }

    local scroll_area = TrueScrollArea(context, scissor_data, scrollbar)

    scroll_area.up_button:SetTextures("images/ui.xml", "arrow_scrollbar_up.tex")
    scroll_area.up_button:SetScale(0.4)
    -- scroll_area.up_button:SetPosition(-13, 96)

	scroll_area.down_button:SetTextures("images/ui.xml", "arrow_scrollbar_down.tex")
    scroll_area.down_button:SetScale(0.4)
    -- scroll_area.down_button:SetPosition(-13, -96)

	scroll_area.scroll_bar_line:SetTexture("images/ui.xml", "scrollbarline.tex")
	scroll_area.scroll_bar_line:SetScale(.9)
    -- scroll_area.scroll_bar_line:SetPosition(-13, 0)

    -- scroll_area.scroll_bar:SetTextures("images/ui.xml", "scrollbarbox.tex", "scrollbarbox.tex", "scrollbarbox.tex")
	-- scroll_area.scroll_bar:SetScale(.6)
    -- scroll_area.scroll_bar:SetPosition(-13, 100)

	scroll_area.position_marker:SetTextures("images/ui.xml", "scrollbarbox.tex", "scrollbarbox.tex", "scrollbarbox.tex")
    scroll_area.position_marker:OnGainFocus() --获取焦点，以刷新图片
    scroll_area.position_marker:SetScale(.45)
    -- scroll_area.position_marker:SetPosition(-13, 100)

    return scroll_area
end

function SkinLegionDialog:BuildSkinAnim(w, skindata)
    if skindata.anims == nil then
        return
    end

    local xbase = width_skininfo/2
    local ybase = -(skindata.height_anim or 150)

    for _,v in ipairs(skindata.anims) do
        local anim = w:AddChild(UIAnim())
        anim:SetScale(v.scale)
        anim:SetPosition(xbase + v.x, ybase + v.y)
        anim:SetFacing(v.face or FACING_DOWN)

        if v.fn_anim ~= nil then
            v.fn_anim(self, anim, v)
        else
            SetAnim_base(anim:GetAnimState(), v)
        end

        if v.fn_click ~= nil then
            anim:SetClickable(true)
            anim.OnControl = function(down, control) --down是uianim自己，不是字符串
                if control == CONTROL_ACCEPT then --鼠标按下与弹回时
                    if not self.anim_down then
                        self.anim_down = true
                        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
                    else
                        self.anim_down = nil
                        v.fn_click(self, anim, v)
                    end
                end
            end
        end
    end
end

function SkinLegionDialog:SetInteractionState(item)
    if item.context then
        item.context:SetInteractionState(item.isselected, item.isowned, item.isfocused, item.isunlockable, false)
    end
end

function SkinLegionDialog:OnControl(control, down)
    if SkinLegionDialog._base.OnControl(self, control, down) then return true end

    -- if control == CONTROL_CANCEL and not down then
    --     if #self.buttons > 1 and self.buttons[#self.buttons] then
    --         self.buttons[#self.buttons].cb()
    --         TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
    --         return true
    --     end
    -- end
end

local function GetRightRoot()
    if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls then
        return ThePlayer.HUD.controls.right_root
    end
    return nil
end
function SkinLegionDialog:Close()
    if self.panel_iteminfo ~= nil then
        self.panel_iteminfo:Kill()
    end
	self:Kill()

    local right_root = GetRightRoot()
    if right_root ~= nil then
        right_root.skinshop_l = nil
    end
end

return SkinLegionDialog
