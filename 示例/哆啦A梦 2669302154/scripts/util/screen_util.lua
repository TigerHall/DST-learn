--------------------------------
--[[ ScreenUtil: 屏幕工具方法]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-04]]
--[[ @updateTime: 2022-01-04]]
--[[ @email: x7430657@163.com]]
--------------------------------
local ScreenUtil = {}

--[[判断该屏幕是否为该名称]]
--[[@param screen 屏幕]]
--[[@param name 屏幕名称]]
--[[@return boolean]]
function ScreenUtil:Is(screen,name)
    return screen and screen.name == name or false
end

--[[判断当前屏幕无其它特殊窗口]]
--[[@return boolean]]
function ScreenUtil:IsHudFront()
    local screen = TheFrontEnd:GetActiveScreen()
    return self:Is(screen,"HUD") or not screen
end

--[[获取当前屏幕]]
--[[@return screen]]
function ScreenUtil:GetActiveScreen()
    return TheFrontEnd:GetActiveScreen()
end



return ScreenUtil