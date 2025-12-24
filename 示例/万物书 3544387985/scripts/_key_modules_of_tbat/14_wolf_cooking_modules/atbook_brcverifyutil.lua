local M = {}

--[[
===============
 基础函数
===============
]]

-- 位异或自定义实现
local function bit_xor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        local a_bit = a % 2
        local b_bit = b % 2
        if a_bit ~= b_bit then
            result = result + bitval
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bitval = bitval * 2
    end
    return result
end

--[[
===============
 Base64 编解码
===============
]]

local base64_chars = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
}

local reverse_chars = {}
for i, v in ipairs(base64_chars) do
    reverse_chars[v] = i-1
end
reverse_chars['='] = 0

-- Base64解码
function M.base64_decode(data)
    data = data:gsub('[^%w+/=]', '')
    local result = {}
    local i = 1
    
    while i <= #data do
        if data:sub(i, i) == '=' then break end
        
        local a = reverse_chars[data:sub(i, i)] or 0
        local b = reverse_chars[data:sub(i+1, i+1)] or 0
        local c = reverse_chars[data:sub(i+2, i+2)] or 0
        local d = reverse_chars[data:sub(i+3, i+3)] or 0
        
        local n = a * 0x40000 + b * 0x1000 + c * 0x40 + d
        
        local c1 = math.floor(n / 0x10000) % 0x100
        local c2 = math.floor(n / 0x100) % 0x100
        local c3 = n % 0x100
        
        table.insert(result, string.char(c1))
        if data:sub(i+2, i+2) ~= '=' then
            table.insert(result, string.char(c2))
        end
        if data:sub(i+3, i+3) ~= '=' then
            table.insert(result, string.char(c3))
        end
        
        i = i + 4
    end
    
    return table.concat(result)
end

-- Base64编码
function M.base64_encode(data)
    local result = {}
    local len = #data
    local pad = 0
    
    for i = 1, len, 3 do
        local b1 = data:byte(i) or 0
        local b2 = data:byte(i+1) or 0
        local b3 = data:byte(i+2) or 0
        
        local n = b1 * 0x10000 + b2 * 0x100 + b3
        
        local c1 = math.floor(n / 0x40000) % 0x40
        local c2 = math.floor(n / 0x1000) % 0x40
        local c3 = math.floor(n / 0x40) % 0x40
        local c4 = n % 0x40
        
        if i+1 > len then pad = 2
        elseif i+2 > len then pad = 1
        else pad = 0 end
        
        table.insert(result, base64_chars[c1+1])
        table.insert(result, base64_chars[c2+1])
        table.insert(result, pad >= 2 and '=' or base64_chars[c3+1])
        table.insert(result, pad >= 1 and '=' or base64_chars[c4+1])
    end
    
    return table.concat(result)
end

--[[
===============
 异或加解密
===============
]]

-- 预生成异或查找表（使用自定义异或函数）
local xor_table = {}
for i=0,255 do
    xor_table[i] = {}
    for j=0,255 do
        xor_table[i][j] = bit_xor(i, j)  -- 使用自定义异或函数
    end
end

local function xor_byte(a, b)
    return xor_table[a][b] or 0
end

-- 加解密核心函数
local function crypt_core(input, key)
    if #key == 0 then return input end
    
    local key_bytes = {key:byte(1, #key)}
    local result = {}
    
    for i = 1, #input do
        local k = key_bytes[(i-1) % #key_bytes + 1]
        local c = input:byte(i)
        result[i] = string.char(xor_byte(c, k))
    end
    
    return table.concat(result)
end

--[[
===============
 公开接口
===============
]]

-- 加密（Lua -> Java）
function M.encrypt(plaintext, key)
    if type(plaintext) ~= "string" or type(key) ~= "string" then
        error("参数必须为字符串")
    end
    return M.base64_encode(crypt_core(plaintext, key))
end

-- 解密（Java -> Lua）
function M.decrypt(ciphertext, key)
    if type(ciphertext) ~= "string" or type(key) ~= "string" then
        error("参数必须为字符串")
    end
    return crypt_core(M.base64_decode(ciphertext), key)
end

return M