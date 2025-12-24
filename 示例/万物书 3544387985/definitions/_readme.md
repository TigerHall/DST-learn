

本文件夹主要用来储存一些白名单、黑名单等列表。方便一起修改。

【笔记部分】
                名字以  definiteion_ 开头的lua文件，作为表格，被外部加载。方便 非专业玩家 添加列表。
                【注意】需要处理 git 同步造成的 额外同步问题。

                modimport 替代部分：

                    print(TBAT.MODROOT)
                    local addr = TBAT.MODROOT.."definitions/test_table.lua"
                    local ret = kleiloadlua(addr)
                    if type(ret) == "function" then
                        ret = ret()
                    end
                    -- print(ret,type(ret))
                    for k, v in pairs(ret) do
                        print(k,v)
                    end

    