--[[
    如何让其他模组的装备也能被棱镜的幻化机制所应用呢？本文件将会解答这个问题。
    如果阅读者不懂lua代码，建议不用继续看下去了。
]]--

local dressup_dd_mod = { --写入模组中需要进行幻化兼容的装备的对应幻化数据
    ------幻化数据格式的介绍
    --[[
    某个幻化道具的prefab名 = {
        dressslot = EQUIPSLOTS.HANDS,
        【幻化位置】
            ▷如果是非装备类的幻化道具，就必须写明这个数据
            ▷如果幻化道具是可以装备的，那就不用写这个数据，会自动识别的
            ▷位置有以下几种：
                1、EQUIPSLOTS.HANDS --手持
                2、EQUIPSLOTS.HEAD --头部
                3、EQUIPSLOTS.BODY、EQUIPSLOTS.BACK、EQUIPSLOTS.NECK --身体（该项三种类型均占用同一个幻化位置）
                4、"body_t" --高位身体，与身体位置不冲突，但会显示在身体的更外层。与 istallbody 项搭配使用的，不要手动写成这个位置
                5、"head_t" --目前只有启迪之冠这个有特殊幻化逻辑的装备在用这个位置
                6、"head_t2" --主要是各种非装备且有特殊幻化逻辑的道具在用这个位置
            ▷"head_t"、"head_t2"这两个自定义位置是用来防止覆盖常规帽子装备的幻化效果被替换的，
              这样就可以实现两种不同幻化逻辑的头部幻化道具都能在头部同时显示，互不冲突
        isnoskin = true, 【是否没有官方皮肤机制】若幻化道具没有官方的皮肤机制，则建议写成true。对于模组道具，最好写成true
        isopentop = true, 【是否为暴露式的头部幻化道具】若头部幻化道具的着装效果需要露出顶部头发贴图，则必须写成true，反之则不写
        isfullhead = true,
        【是否为全覆盖式的头部幻化道具】
            ▷若头部幻化道具的着装效果需要隐藏整个头部，则必须写成true，反之则不写
            ▷isopentop 项与 isfullhead 项的对应逻辑冲突，最好不要都写成true。isopentop 的优先级比 isfullhead 高
        istallbody = true,
        【是否为高位的身体幻化道具】
            ▷若身体幻化道具的着装效果需要显示在普通衣服贴图更外层，则写成true，反之则不写
            ▷istallbody 项为true时，不建议再写 dressslot 项，因为此时 dressslot 必定会被覆盖为 "body_t"
            ▷高位身体的幻化效果不会覆盖掉非高位身体的幻化效果
            ▷判定该项是否需要写为true的一般方法是看装备时人物贴图切换代码中是否用的 xx:OverrideSymbol("swap_body_tall", "xx", "xx")
            ▷一般情况下，背包、护甲、衣服、项链的贴图数量、贴图格式、在人物动画中的配置，都是一样的。所以高位与否全看你要不要让它显示在最外层
        isbackpack = true,
        【是否为背包式的身体幻化道具】
            ▷若装备时人物贴图切换代码中用了 xx:OverrideSymbol("backpack", "xx", "xx")，则必须写成true，反之则不写
            ▷isbackpack 项与 istallbody 项的对应逻辑冲突，最好不要都写成true。istallbody 的优先级比 isbackpack 高
        isshield = true,
        【是否为盾牌式的手持幻化道具】
            ▷若装备时人物贴图切换代码中用了 xx:OverrideSymbol("swap_shield", "xx", "xx")、xx:OverrideSymbol("lantern_overlay", "xx", "xx")
              这两个中的任意一个，则可以写成true，反之则不写
        iswhip = true,
        【是否为鞭子式的手持幻化道具】
            ▷若装备时人物贴图切换代码中用了 xx:OverrideSymbol("whipline", "xx", "xx")，则必须写成true，反之则不写
            ▷iswhip 项与 isshield 项的对应逻辑冲突，最好不要都写成true。isshield 的优先级比 iswhip 高
        buildfile = "swap_spear", 【切换贴图时所用的动画文件名】
        buildsymbol = "swap_spear", 【切换贴图时所用的动画文件中的对应文件夹名】

        ------本行之前的数据项均为通用逻辑所需的，如果通用逻辑无法满足你的要求，则使用以下数据项

        buildfn = function(self, item, buildskin)
            local itemswap = {}
            ......
            return itemswap
        end,
        【幻化数据自定义函数】
            ▷道具被幻化时触发。通用幻化逻辑无法满足效果时，使用该函数，能替换默认的幻化数据获取逻辑
            ▷传入参数说明：
                1、self 玩家的幻化组件自身
                2、item 被幻化的道具
                3、buildskin 道具拥有的官方皮肤的代码名。模组道具如果没用官方皮肤机制，那就不用管这个参数
            ▷返回参数：需要返回自定义的幻化数据
            ▷该函数会覆盖 buildfile、buildsymbol、isopentop、isbackpack、isshield 等项对应的原本逻辑，使其不再生效
            ▷该函数逻辑触发后，item 会被删除，若有延时函数之类的逻辑，请以玩家自身为主来设计逻辑

        unbuildfn = function(self, item)end,
        【幻化效果自定义清理函数】
            ▷道具被解除幻化时触发。用来清除该道具对应的幻化数据带来的所有贴图效果
            ▷传入参数说明：
                1、self 玩家的幻化组件自身
                2、item 被解除幻化的道具
            ▷该函数会覆盖原本的贴图效果清理逻辑，注意补全原本的清理逻辑
        
        equipfn = function(inst, item, cpt)end,
        【幻化时额外函数】
            ▷道具被幻化时触发。比 buildfn 要晚触发。用作其他效果
            ▷传入参数说明：
                1、inst 玩家自身
                2、item 被幻化的道具
                3、cpt 玩家的幻化组件自身
            ▷该函数逻辑触发后，item 会被删除，若有延时函数之类的逻辑，请以玩家自身为主来设计逻辑

        unequipfn = function(inst, item, cpt)end,
        【幻化时额外函数】
            ▷道具被解除幻化时触发。比 unbuildfn 要晚触发。用作和 equipfn 对应的其他效果
            ▷传入参数说明：
                1、inst 玩家自身
                2、item 被解除幻化的道具
                3、cpt 玩家的幻化组件自身
            ▷该函数逻辑触发后，item 会被删除，若有延时函数之类的逻辑，请以玩家自身为主来设计逻辑

        onequipfn = function(inst, item)end,
        【装备时额外函数】
            ▷玩家装备某道具时触发。常用于清除该道具的特殊装备后动画，防止头上、身体上、手上出现两个装备的动画效果，不然会很奇怪
            ▷传入参数说明：
                1、inst 玩家自身
                2、item 刚装备上的某个道具
    }
    ]]--
}
--将以上的幻化数据插入全局变量 DRESSUP_DATA_LEGION，来实现兼容化
if GLOBAL.rawget(GLOBAL, "DRESSUP_DATA_LEGION") then --已有变量了(多半是别的模组加的)，那就逐一添加数据
    for k, v in pairs(dressup_dd_mod) do
        GLOBAL.DRESSUP_DATA_LEGION[k] = v
    end
else --没有变量，那就直接赋值即可
    GLOBAL.DRESSUP_DATA_LEGION = dressup_dd_mod
end
dressup_dd_mod = nil --这么大个临时变量，用完就主动清理了吧

-------------------------------
--以下为举例，外部格式也不是正确的，也不是默认数据，只是为了演示幻化参数如何填写
-------------------------------

------暴露式的头部
local ruinshat = { isopentop = true, buildfile = "hat_ruins", buildsymbol = "swap_hat" } --铥矿皇冠

------全覆盖式的头部
local lunarplanthat = { --亮茄头盔
    isfullhead = true, buildfile = "hat_lunarplant", buildsymbol = "swap_hat",
    equipfn = function(owner, item)
        -- Fn_setFollowFx(owner, "fx_d_lunarplanthat", "lunarplanthat_fx")
    end,
    unequipfn = function(owner, item)
        -- Fn_removeFollowFx(owner, "fx_d_lunarplanthat")
    end,
    onequipfn = function(owner, item)
        -- Fn_removeFollowFx(item, "fx")
    end
}

------高位的身体
local corn_oversized_waxed = { --打蜡后的巨型玉米
    isnoskin = true, istallbody = true,
    buildfn = function(self, item, buildskin)
        local itemswap = {}
        if item.components.symbolswapdata ~= nil then
            local swap = item.components.symbolswapdata
            itemswap["swap_body_tall"] = self:GetDressData(
                buildskin, swap.build, swap.symbol, item.GUID, "swap"
            )
        end
        return itemswap
    end
}

------背包式的身体
local spicepack = { isbackpack = true, buildfile = "swap_chefpack" } --厨师袋

------盾牌式的手持
local shield_l_sand = { isnoskin = true, isshield = true, buildfile = "shield_l_sand", buildsymbol = "swap_shield" } --砂之抵御
local wathgrithr_shield = { isshield = true, buildfile = "swap_wathgrithr_shield", buildsymbol = "swap_shield" } --战斗圆盾

------鞭子式的手持
local whip = { iswhip = true, buildfile = "swap_whip", buildsymbol = "swap_whip" } --三尾猫鞭

------非装备类的幻化道具
local messagebottle = { --瓶中信
    isnoskin = true, dressslot = EQUIPSLOTS.HANDS, buildfile = "swap_bottle", buildsymbol = "swap_bottle"
}

------多状态贴图的装备
local minerhat = { --矿灯帽
    buildfn = function(self, item, buildskin)
        local itemswap = {}
        --由于矿灯帽有燃料时和没有燃料时的装备贴图不一样，所以这里要判段是否有燃料
        if item.components.fueled:IsEmpty() then
            itemswap["swap_hat"] = self:GetDressData(
                buildskin, "hat_miner", "swap_hat_off", item.GUID, "swap"
            )
        else
            itemswap["swap_hat"] = self:GetDressData(
                buildskin, "hat_miner", "swap_hat", item.GUID, "swap"
            )
        end
        self:SetDressTop(itemswap) --因为矿灯帽为非暴露式的头部装备，所以没有用 self:SetDressOpenTop()
        return itemswap
    end
}

------修正贴图
local amulet = { --重生护符
    buildfn = function(self, item, buildskin)
        local itemswap = {}
        --由于带有皮肤的重生护符的动画文件数据与原皮不同，为了能继续幻化，只能专门写个 buildfn 来修正
        if buildskin ~= nil then
            itemswap["swap_body"] = self:GetDressData(
                buildskin, "torso_amulets", "swap_body", item.GUID, "swap"
            )
        else
            itemswap["swap_body"] = self:GetDressData(
                buildskin, "torso_amulets", "redamulet", item.GUID, "swap"
            )
        end
        itemswap["backpack"] = self:GetDressData(nil, nil, nil, nil, "clear") --补全身体位置上原本幻化逻辑中的其他数据
        return itemswap
    end
}

------综合举例
local tallbirdegg = { --高脚鸟蛋
    isnoskin = true, --目前看来，高脚鸟蛋肯定不会有皮肤
    dressslot = "head_t2", --为了与头部位置的帽子贴图不冲突，所以用了自定义位置名
    buildfn = function(cpt, item, buildskin)
        local state = cpt.itemdd.tallbirdegg_state
        local itemswap = {}
        itemswap["HAT"] = cpt:GetDressData(nil, nil, nil, nil, "show") --为了鸟蛋动画能一直显示，帽子贴图只能clear不能hide
        if state == nil then
            state = tostring(math.random(3))
            cpt.itemdd.tallbirdegg_state = state
        end
        -- Fn_setFollowFx(cpt.inst, "fx_d_tallbirdegg", "tallbirdegg_l_fofx"..state) --给玩家绑定一个动画通道跟随式实体，具体逻辑不讲
        return itemswap
    end,
    unbuildfn = function(cpt, item)
        Fn_removeFollowFx(cpt.inst, "fx_d_tallbirdegg") --移除动画通道跟随式的实体
        cpt:InitHide("HAT") --补全解除幻化时的贴图还原逻辑：手动让帽子贴图隐藏。因为默认就是隐藏的
        cpt.itemdd.tallbirdegg_state = nil
    end
}
local sword_lunarplant = { --亮茄剑
    buildfile = "sword_lunarplant", buildsymbol = "swap_sword_lunarplant", --这一行信息本身没用，是为了占用手部位置
    equipfn = function(owner, item)
        -- Fn_setFollowSymbolFx(owner, "fx_d_sword_lunarplant", { --给玩家绑定一个动画通道跟随式实体，具体逻辑不讲
        --     { name = "sword_lunarplant_blade_fx", anim = nil, symbol = "swap_object", idx = 0, idx2 = 3 },
        --     { name = "sword_lunarplant_blade_fx", anim = "swap_loop2", symbol = "swap_object", idx = 5, idx2 = 8 }
        -- }, true)
    end,
    unequipfn = function(owner, item)
        -- Fn_removeFollowSymbolFx(owner, "fx_d_sword_lunarplant") --移除动画通道跟随式的实体
    end,
    onequipfn = function(owner, item) --玩家装备亮茄剑时，如果已经幻化了同为手持位置的任何道具，则会触发这个函数的逻辑
        --通过设置这个亮茄剑本身的 动画通道跟随式的实体，使其隐藏或删除，就不会影响幻化展示了
        item.blade1.entity:SetParent(item.entity)
        item.blade2.entity:SetParent(item.entity)
        item.blade1.Follower:FollowSymbol(item.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 3)
        item.blade2.Follower:FollowSymbol(item.GUID, "swap_spear", nil, nil, nil, true, nil, 5, 8)
        item.blade1.components.highlightchild:SetOwner(item)
        item.blade2.components.highlightchild:SetOwner(item)
    end
}


--幻化组件还支持幻化后的特殊数据的保存与读取
--幻化时，将要保存的数据存入 cpt.itemdd 这个表中；解除幻化时得删除之前存入的数据
--举例：
local rabbithat = { --洞穴花环
    buildfile = "hat_rabbit", buildsymbol = "swap_hat",
    equipfn = function(owner, item, cpt)
        local state = cpt.itemdd.rabbithat_state
        if state == nil then
            if owner.components.sanity ~= nil and owner.components.sanity:IsInsane() then
                state = "3"
            elseif TheWorld.state.iswinter then
                state = "2"
            else
                state = "1"
            end
            ------！！！记录洞穴花环当前状态，不然从非冬天、或者精神值较高时重新进入世界时，它的贴图就变回默认的样子了
            cpt.itemdd.rabbithat_state = state
        end
        -- Fn_setFollowFx(owner, "fx_d_rabbithat", "rabbithat_l_fofx"..state)
    end,
    unequipfn = function(owner, item, cpt)
        -- Fn_removeFollowFx(owner, "fx_d_rabbithat")
        cpt.itemdd.rabbithat_state = nil ------！！！解除幻化时记得清理之前的数据
    end
}
