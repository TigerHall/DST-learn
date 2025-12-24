local CONTAINER_NO_TEST = GetModConfigData("container_no_test")

local function TrueFn() return true end

local params = require("containers").params
params.icebox.itemtestfn = TrueFn
params.saltbox.itemtestfn = TrueFn


if CONTAINER_NO_TEST < 2 then return end

--常见容器，希望不要和其他mod冲突

-- 极地熊獾桶
params.beargerfur_sack.itemtestfn = TrueFn

-- 钓具箱
params.tacklecontainer.itemtestfn = TrueFn
params.supertacklecontainer.itemtestfn = TrueFn
