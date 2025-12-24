local function GiveItem(prefabs)
    local x, y, z = ThePlayer.Transform:GetWorldPosition()
    for _, v in ipairs(type(prefabs) == "table" and prefabs or { prefabs }) do
        local item = SpawnPrefab(v)
        item.Transform:SetPosition(x, y, z)
        ThePlayer.components.inventory:GiveItem(item)
    end
end

--- 获取所有指定builder_tag的配方物品
GLOBAL.c_give_items_by_builder_tag = function(tag)
    for name, t in pairs(AllBuilderTaggedRecipes) do
        if t == tag then
            local recipe = AllRecipes[name]
            if recipe then
                GiveItem(recipe.product or name)
            end
        end
    end
end

--- 获取旺达所有的表
GLOBAL.c_give_pocketwatchs = function()
    GLOBAL.c_give_items_by_builder_tag("clockmaker")
end
----------------------------------------------------------------------------------------------------
local dragSkillTreeIcon = false
local function WrapButton(skill, btn, offset)
    local Oldonclick = btn.onclick
    btn.onclick = function()
        if btn._followhandler then
            btn._followhandler:Remove()
            btn._followhandler = nil

            local x, y, z = btn:GetPosition():Get()
            local str = skill .. ": " .. string.format("%.2f", x) .. "," .. string.format("%.2f", y - (offset or 0))
            ChatHistory:OnSystemMessage(str) --客机得用这个
            print(str)
        else
            if dragSkillTreeIcon then
                local mousePos = TheInput:GetScreenPosition()
                local iniPos = btn:GetPosition()
                btn._followhandler = TheInput:AddMoveHandler(function(x, y)
                    btn:SetPosition((Vector3(x, y, 0) - mousePos) / btn:GetScale().x + iniPos) --偏移量需要一个缩放值
                end)
            else
                Oldonclick() --拖拽模式不执行默认事件
            end
        end
    end
end

AddClassPostConstruct("widgets/redux/skilltreebuilder", function(self)
    local Oldbuildbuttons = self.buildbuttons
    self.buildbuttons = function(self, panel, pos, data, offset, ...)
        Oldbuildbuttons(self, panel, pos, data, offset, ...)

        for skill, d in pairs(self.skillgraphics) do
            WrapButton(skill, d.button, offset)
        end
    end
end)

---本地指令，拖拽技能树图标
GLOBAL.c_showskilltreepoint = function()
    dragSkillTreeIcon = not dragSkillTreeIcon
    ChatHistory:OnSystemMessage(dragSkillTreeIcon and "开始拖拽" or "结束拖拽")
end
----------------------------------------------------------------------------------------------------

--- 判断鼠标对象有没有指定标签
GLOBAL.c_hastag = function(tag)
    print(c_select():HasTag(tag))
end

--- 打印鼠标对象的当前状态
GLOBAL.c_ptstate = function()
    local bu = ThePlayer:GetBufferedAction()
    print(ThePlayer.sg.currentstate.name)
    print(bu, bu and bu.action and bu.action.id)
end

local REMOVE_CANT_TAGS = { "antlion_sinkhole_blocker", "CLASSIFIED", "INLIMBO", "player" }
GLOBAL.c_safeemptyworld = function()
    for k, ent in pairs(Ents) do
        if ent.widget == nil
            and ent.entity:GetParent() == nil
            and ent.Network ~= nil
            and not ent:HasOneOfTags(REMOVE_CANT_TAGS)
        then
            ent:Remove()
        end
    end
end

GLOBAL.c_testsound = function(sound)
    ThePlayer.SoundEmitter:PlaySound(sound)
end
