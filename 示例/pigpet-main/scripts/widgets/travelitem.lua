-- TravelItem：旅行点列表项 UI
-- 说明：
--   - 显示 homesign（旅行点）的名称
--   - 提供“编辑”按钮以修改名称（当前使用 TextEdit）
--   - 非当前点显示“传送”按钮以触发传送
-- 注意：
--   - TextEdit 在某些客户端/输入法下对中文/IME 的支持和退格行为可能不稳定，
--     如遇问题可考虑改用 Text + TheInput:AddTextInputHandler 自行处理输入（见注释）。
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit" -- 用于内置单行编辑（注意 IME/退格兼容性）
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

-- TravelItem 类构造函数
-- 参数：
--   homesign  - 对应的 travel point 实体（应包含 components.travelable）
--   isCurrent - 布尔，是否为当前所在点（当前点不显示“传送”）
--   traveller - 触发传送时的 traveller 实体（通常为玩家）
--   screen    - 父界面引用（用于在传送后关闭界面）
local TravelItem = Class(Widget, function(self, homesign, isCurrent, traveller, screen)
    Widget._ctor(self, "TravelItem")
    self.homesign = homesign
    self.traveller = traveller
    self.screen = screen

    -- 背景动画（使用现有 UIAnim 资源以和存档/列表风格一致）
    self.bg = self:AddChild(UIAnim())
    self.bg:GetAnimState():SetBuild("savetile")
    self.bg:GetAnimState():SetBank("savetile")
    self.bg:GetAnimState():PlayAnimation("anim")
    -- 缩放以适配行高
    self.bg:SetScale(1, 0.8, 1)

    -- 名称编辑控件（TextEdit：内置单行编辑）
    -- 注意：部分平台/输入法下 TextEdit 对中文与退格支持不稳定，
    -- 如发现问题请替换为 Text + TheInput:AddTextInputHandler 的实现。
    self.name = self.bg:AddChild(TextEdit(BODYTEXTFONT, 35))
    self.name:SetVAlign(ANCHOR_MIDDLE)
    self.name:SetHAlign(ANCHOR_LEFT)
    self.name:SetPosition(0, 10, 0)
    self.name:SetAllowClipboardPaste(true)
    -- 指定显示区域以限制文本换行
    self.name:SetRegionSize(300, 40)

    self.name.OnRawKey = function(_, key, down)
           if not down and key == KEY_BACKSPACE then
            local te = _

            -- 尝试读取编辑缓冲（优先 GetLineEditString，再退回 GetString）
            local ok, s = pcall(function() return te.GetLineEditString and te:GetLineEditString() end)
            if not ok or type(s) ~= "string" then
                ok, s = pcall(function() return te.GetString and te:GetString() end)
            end

            if type(s) == "string" and #s > 0 then
                -- 删除最后一个字符并写回
                local new_s = string.sub(s, 1, #s - 1)
                pcall(function()
                    if type(te.SetLineEditString) == "function" then
                        te:SetLineEditString(new_s)
                    elseif type(te.SetString) == "function" then
                        te:SetString(new_s)
                    end
                end)
            end

            -- 已处理，阻止后续默认行为（避免重复或 IME 干扰）
            return true
        end
        return TextEdit.OnRawKey(_, key, down)
    end

    -- 初始化文本为 homesign 的当前名字（components.travelable.name）
    local init_name = ""
    if homesign and homesign.components and homesign.components.travelable then
        init_name = homesign.components.travelable.name or ""
    end
    self.name:SetString(init_name)

    -- 如果是当前点则用绿色提示，并且不显示传送按钮
    if isCurrent then
        self.name:SetColour(0, 1, 0, 0.4)
    else
        -- 非当前点：显示“传送”按钮
        self.go = self.bg:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex"))
        self.go:SetPosition(220, 0)
        self.go:SetText("传送")
        self.go:SetFont(BUTTONFONT)
        -- 点击触发传送行为（调用下面的 Go 方法）
        self.go:SetOnClick(function()
            self:Go()
        end)
    end

    -- 编辑按钮（点击后把编辑框的文本写回 homesign）
    -- 说明：当前实现 Edit() 会直接读取 TextEdit 的行编辑结果并保存；
    -- 若使用自定义输入处理，请在 Edit/Finish 编辑流程中做相应修改。
    self.button = self.bg:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex"))
    self.button:SetPosition(-220, 0)
    self.button:SetText("编辑")
    self.button:SetFont(BUTTONFONT)
    self.button:SetOnClick(function()
        self:Edit()
    end)
end)

-- Edit：将编辑框当前内容提交到 homesign（同步保存）
-- 行为说明：
--   - 读取 TextEdit 提供的 GetLineEditString（内置编辑控件 API）
--   - 若文本与原名不同则更新 homesign.components.travelable.name
-- 注意：
--   - 若你的 TextEdit 在某些输入法下无法正确删除字符，请改为自管理输入（TheInput 回调）
function TravelItem:Edit()
    if not self.name then return end
    -- TextEdit 的 API：GetLineEditString 返回当前编辑缓冲（行为依实现可能略有差异）
    local ok, text = pcall(function() return self.name:GetLineEditString() end)
    if not ok then
        -- 若 TextEdit 没有此方法或出错，作为降级直接读取显示字符串
        text = tostring(self.name:GetString() or "")
    end

    -- 如果名字发生变化则写回 homesign（触发游戏保存/网络同步由组件处理）
    if self.homesign and self.homesign.components and self.homesign.components.travelable then
        local oldname = tostring(self.homesign.components.travelable.name or "")
        text = tostring(text or "")
        if text ~= oldname then
            self.homesign.components.travelable.name = text
        end
    end
end

-- Go：触发传送并关闭所在界面
-- 说明：
--   - 调用 homesign.components.travelable:DoTravel(traveller)
--   - 若提供了 screen，则调用 screen:OnCancel() 关闭界面
function TravelItem:Go()
    if self.homesign and self.homesign.components and self.homesign.components.travelable then
        -- 如果未指定 traveller，默认使用本地玩家
        local tr = self.traveller or GetPlayer()
        -- 执行传送（组件内部负责权限/消耗/动画等）
        self.homesign.components.travelable:DoTravel(tr)
    end
    -- 关闭上层界面（如果存在并提供 OnCancel）
    if self.screen and self.screen.OnCancel then
        self.screen:OnCancel()
    end
end

return TravelItem