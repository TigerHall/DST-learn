---------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    空的执行SG。

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------
AddStategraphState("wilson",State{
    name = "tbat_sg_empty_active",
    tags = {  },

    onenter = function(inst)
        inst:PerformBufferedAction()
        return
    end,

    timeline =
    {

    },

    events =
    {
        -- EventHandler("firedamage", function(inst)

        -- end),
        -- EventHandler("animqueueover", function(inst)

        -- end),
    },

    onexit = function(inst)

    end,
})

AddStategraphState('wilson_client', State{
    name = "tbat_sg_empty_active",
        tags = {},
		server_states = { "tbat_sg_empty_active" },
        onenter = function(inst)
            inst:PerformPreviewBufferedAction()
            return
        end,

        onupdate = function(inst)

        end,

        ontimeout = function(inst)

        end,
})