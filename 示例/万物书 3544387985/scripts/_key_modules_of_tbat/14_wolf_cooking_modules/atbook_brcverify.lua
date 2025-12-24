AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then return end

    local function GetVerifyByPlayer(_, player)
        if player and player.userid then
            SendModRPCToClient(CLIENT_MOD_RPC["ATBOOK"]["read_atbook_brcverify"], player.userid)
        end
    end

    inst:ListenForEvent("ms_playerjoined", GetVerifyByPlayer)
end)

AddClientModRPCHandler("ATBOOK", "read_atbook_brcverify", function()
    local file = io.open("unsafedata/atbookdata.json")
    if file then
        local str = file:read('*a')
        file:close()
        if str then
            SendModRPCToServer(MOD_RPC["ATBOOK"]["atbook_brcverify"], str)
        end
    end
end)

AddClientModRPCHandler("ATBOOK", "record_atbook_brcverify", function(str)
    local file = io.open("unsafedata/atbookdata.json", "w")
    if file then
        file:write(str)
        file:close()
    end
end)

AddModRPCHandler("ATBOOK", "atbook_brcverify", function(player, str, first)
    local crypto = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_brcverifyutil")
    local const = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_brcverifyconst")

    if not player.components.tbat_com_skins_controller then
        return
    end
    for key, value in pairs(const.skin) do
        player.components.tbat_com_skins_controller:RemoveSkinFromPlayer(value)
    end

    local flag = false

    local function fail()
        if player.components.talker then
            player.components.talker:Say("CDK验证失败，请仔细核对CDK后重试！")
        end
    end

    if player and type(str) == "string" and string.len(str) > 2 then
        local key = const.keys[string.sub(str, 0, 1)]
        if key then
            local state, result = pcall(crypto.decrypt, string.sub(str, 2), key)
            if state then
                if type(result) == "string" then
                    if string.sub(result, 0, 1) ~= "#" or string.sub(result, string.len(result)) ~= "#" then
                        fail()
                        return
                    end
                    if not string.find(result, "@atbook") then
                        fail()
                        return
                    end
                    result = string.gsub(result, "#", "")
                    result = result .. ","
                    local info = {}
                    local delimiter = ","
                    for match in (result):gmatch("(.-)" .. delimiter) do
                        if match == player.userid then
                            flag = true
                        elseif match == "VIP" then
                            const.vipfn(info)
                        elseif string.find(match, "&") then
                            match = string.gsub(match, "&", "")
                            const.hexfn(info, match)
                        elseif const.skin[match] and not table.contains(info, const.skin[match]) then
                            table.insert(info, const.skin[match])
                        end
                    end
                    if flag then
                        SendModRPCToClient(CLIENT_MOD_RPC["ATBOOK"]["record_atbook_brcverify"], player.userid, str)
                        for _, skincode in ipairs(info) do
                            player.components.tbat_com_skins_controller:UnlockSkin(skincode)
                        end
                        if player.components.talker and first then
                            player.components.talker:Say("CDK验证成功，本次成功兑换" .. #info .. "个皮肤，感谢支持万物书~")
                        end
                    end
                end
            end
        end
    end

    if not flag then
        fail()
    end
end)
