--------------------------------------------------------------------------------------------------------------------------------------------
--[[
            给物品组件添加个 方便自用的 API
            切皮肤重置图标就方便很多，添加图片参数也很方便
 ]]--
--------------------------------------------------------------------------------------------------------------------------------------------
AddComponentPostInit("inventoryitem", function(self)

    function self:TBATInit(image,atlas)
        --- image : 没 .tex 的后缀
        self.tbat_icon_data_image = image
        self.tbat_icon_data_atlas = atlas
        if atlas then
            self.imagename = image 
            self.atlasname = atlas
        else
            self:ChangeImageName(image)
        end
    end

    function self:TBATRest()
        if self.tbat_icon_data_image == nil then
            return
        end
        if self.tbat_icon_data_atlas then
            self.imagename = self.tbat_icon_data_image 
            self.atlasname = self.tbat_icon_data_atlas
        else
            self.atlasname = nil
            self.imagename = nil
            self:ChangeImageName(self.tbat_icon_data_image)
        end
    end

    function self:tbat_set_empty_icon()
        -- self:tbat_icon_init("tbat_empty_icon", "images/inventoryimages/tbat_empty_icon.xml")
        self:ChangeImageName("cane")
    end

end)