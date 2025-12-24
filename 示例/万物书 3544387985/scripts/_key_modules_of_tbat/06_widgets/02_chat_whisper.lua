------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    --- hook chathistory 模块，实现系统悄悄话。  chathistory.lua
    --- function ChatHistoryManager:GenerateChatMessage(type, sender_userid, sender_netid, sender_name, message, colour, icondata, whisper, localonly, text_filter_context)
    --- 改掉其中一个参数
    --- 客户端用 ChatHistory:AddToHistory 执行显示语句，该函数内部会调用 ChatHistory.GenerateChatMessage


    -- icondata : "profileflair_treasurechest_monster" ,"default"  在文件 misc_items.lua 里，部分需要玩家解锁。
    -- icon 的尺寸为90x90像素，具体参数前往 profileflair.tex 和 profileflair.xml 查看。如果是自己制作，推荐使用 autocompiler.exe 自动编译 png 成 tex + xml (png放文件夹里会自动进行)
    -- ChatHistory:AddToHistory({flag = "tbat" , ChatType = ChatTypes.Message , m_colour = {0,0,255} , s_colour = {255,255,0}},nil,nil,"NPC","656565",{0,255,0})
    -- m_colour 文本颜色，  s_colour 名字颜色
    -- colour 参数 和官方的有出入，  需要除以255才能成任意色。
    -- ChatType 在 chatline.lua 里有执行逻辑

    ThePlayer:PushEvent("tbat_event.client_whisper",{
        icondata = "profileflair_treasurechest_monster" ,
        sender_name = "NPC",
        s_colour = {255/255,0/255,0/255},
        message = "656565",
        m_colour = {0/255,255/255,0/255}
    })
        
    TBAT.FNS:Whisper(player_or_userid,{
        icondata = "profileflair_treasurechest_monster" ,
        sender_name = "NPC",
        s_colour = {255/255,0/255,0/255},
        message = "656565",
        m_colour = {0/255,255/255,0/255}
    })


]]--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 深层复制函数
    local function deepcopy(orig, copies)
        if type(orig) ~= "table" then
            return orig
        end

        -- 防止循环引用
        copies = copies or {}
        if copies[orig] then
            return copies[orig]
        end

        local new_table = {}
        copies[orig] = new_table

        for k, v in next, orig, nil do
            k = deepcopy(k, copies)
            v = deepcopy(v, copies)
            new_table[k] = v
        end

        -- 复制元表
        local mt = getmetatable(orig)
        if mt then
            mt = deepcopy(mt, copies)
            setmetatable(new_table, mt)
        end

        return new_table
    end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



ChatHistory.GenerateChatMessage_old_tbat = ChatHistory.GenerateChatMessage
ChatHistory.GenerateChatMessage = function(self,Chat_type, sender_userid, sender_netid, sender_name, message, colour, icondata, whisper, localonly, text_filter_context)
    local tbat_cmd_table = {}
    if Chat_type and type(Chat_type) == "table" and Chat_type.flag == "tbat" then
        tbat_cmd_table = deepcopy(Chat_type)
        Chat_type = tbat_cmd_table.ChatType or ChatTypes.Message                        ---- 文本类型
        localonly = true                                                                ---- 只在本地
        icondata = tbat_cmd_table.icondata or icondata -- or "default"                     ---- 图标
        sender_name = tbat_cmd_table.sender_name or sender_name                         ---- 发送者名字
        message = tbat_cmd_table.message or message                                     ---- 文字内容
        colour = tbat_cmd_table.s_colour or tbat_cmd_table.m_colour or {255/255,255/255,255/255}    ---- 颜色初始化。
    end

    local ret_chat_message = self:GenerateChatMessage_old_tbat(Chat_type, sender_userid, sender_netid, sender_name, message, colour, icondata, whisper, localonly, text_filter_context)
    
    if tbat_cmd_table.flag == "tbat" then
        if tbat_cmd_table.m_colour then            
            ret_chat_message.m_colour = tbat_cmd_table.m_colour --- 文本颜色
        end
        if tbat_cmd_table.s_colour then
            ret_chat_message.s_colour = tbat_cmd_table.s_colour --- 文本颜色
        end
    end

    return ret_chat_message
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 在 client 端 给玩家添加 event
AddPlayerPostInit(function(inst)
    
    if TheNet:IsDedicated() then    -- 是服务器加载到这就返回。 事件添加到 客户端足够了，用 RPC EVENT 下发
        return
    end

    inst:ListenForEvent("tbat_event.client_whisper",function(_,_table)
        if _table and _table.message then
            _table.flag = "tbat"
            ChatHistory:AddToHistory(_table)
        end
    end)

end)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 注册调用 API
    function TBAT.FNS:Whisper(player_or_userid,cmd)
        if player_or_userid == nil then

            if TheWorld.ismastersim then
                for k, v in pairs(AllPlayers) do
                    v.components.tbat_com_rpc_event:PushEvent("tbat_event.client_whisper",cmd)
                end
                return
            elseif not TheNet:IsDedicated() and ThePlayer then
                ThePlayer:PushEvent("tbat_event.client_whisper",cmd)
            end

        else
            local player = player_or_userid
            if type(player_or_userid) == "string" then
                player = LookupPlayerInstByUserID(player_or_userid)
            end
            if player == nil then
                return
            end
            if TheWorld.ismastersim then
                player.components.tbat_com_rpc_event:PushEvent("tbat_event.client_whisper",cmd)
            elseif player == ThePlayer then
                ThePlayer:PushEvent("tbat_event.client_whisper",cmd)
            end

        end
    end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    widgets/text   偶发性的崩溃：  [string "scripts/widgets/text.lua"]:58: bad argument #3 to 'SetColour' (number expected, got no value)
    widgets/text SetColour

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 兼容 SetColour 
    -- AddClassPostConstruct("widgets/text",function(self)
    --     local old_fn = self.SetColour
    --     self.SetColour = function(self,r,g,b,a)
    --         local colour = type(r) == "number" and { r, g, b, a } or r
    --         r,g,b,a = unpack(colour)
    --         old_fn(self,r or 1,g or 1,b or 1 ,a or 1)
    --     end
    -- end)

    --- 通过通义灵码AI优化
    AddClassPostConstruct("widgets/text", function(self)
        if self.__tbat_hooked then
            return
        end
        self.__tbat_hooked = true
        local old_fn = self.SetColour
        self.SetColour = function(self, ...)
            local args = {...}
            local num_args = select("#", ...)
            
            -- 兼容两种调用方式：SetColour(r, g, b, a) 或 SetColour({r, g, b, a})
            local r, g, b, a
            
            if type(args[1]) == "table" then
                -- 表参数模式
                r, g, b, a = unpack(args[1], 1, 4)
            else
                -- 数字参数模式
                r = args[1] or 1
                g = args[2] or 1
                b = args[3] or 1
                a = args[4] or 1
            end
            
            -- 确保所有参数都是数字类型
            r = tonumber(r) or 1
            g = tonumber(g) or 1
            b = tonumber(b) or 1
            a = tonumber(a) or 1
            
            old_fn(self, r, g, b, a)
        end
    end)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------