local moddir = KnownModIndex:GetModsToLoad(true)
local enablemods = {}

for k, dir in pairs(moddir) do  --遍历mod的加载列表
    local info = KnownModIndex:GetModInfo(dir)  
    local name = info and info.name or "unknow"
    enablemods[dir] = name   --把mod名字存在表里
end

-- MOD是否开启
local function modenable(name)
    for k, v in pairs(enablemods) do
        if v and (k:match(name) or v:match(name)) then return true end
    end
    return false
end
local ModEnable = Class(function()
    
end)

function ModEnable:MythEnable() --神话
    if modenable("Myth Words") then
        return true
    elseif modenable("%[DST%] 神话书说") then
        return true
    elseif modenable("workshop%-1991746508") then
        return true
    elseif modenable("workshop%-2199027653598524334") then
        return true
    end
    return false
end

function ModEnable:LegionEnable() --棱镜
    if modenable("[DST] Legion") then
        return true
    elseif modenable("[DST] 棱镜") then
        return true
    elseif modenable("workshop%-1392778117") then
        return true
    elseif modenable("workshop%-2199027653598545818") then
        return true
    end
    return false
end

function ModEnable:MedalEnable() --勋章
    if modenable("Functional Medal") then
        return true
    elseif modenable("能力勋章") then
        return true
    elseif modenable("workshop%-1909182187") then
        return true
    elseif modenable("workshop%-2199027653598522135") then
        return true
    end
    return false
end

function ModEnable:MiniSignEnable() --小木牌
    if modenable("Smart Minisign") then
        return true
    elseif modenable("workshop%-1595631294") then
        return true
    end
    return false
end


function ModEnable:CcsEnable() --小樱
    if modenable("魔卡少女小樱（百变小樱）") then
        return true
    elseif modenable("workshop%-3043439883") then
        return true
    elseif modenable("workshop%-2199027653598543454") then
        return true
    end
    return false
end

return ModEnable