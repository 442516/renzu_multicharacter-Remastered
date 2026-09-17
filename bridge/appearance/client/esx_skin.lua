if Config.Appearance ~= 'esx_skin' then return end

AppearanceImpl = {
	getModel = function(sex, overrideModel)
		return baseModel(sex, overrideModel)
	end,
	setAppearance = function(ped, skinData, sex)
		if not skinData or not next(skinData) then
			skinData = Config.Default['skinchanger'] and Config.Default['skinchanger'][sex]
		end
		if not skinData then return end
		TriggerEvent('skinchanger:loadSkin', skinData)
	end,
	openCreator = function(ped, sex, onDone)
		TriggerEvent('esx_skin:openSaveableMenu',
			function() onDone(Config.Default['skinchanger'] and Config.Default['skinchanger'][sex] or {}) end,
			function() onDone(Config.Default['skinchanger'] and Config.Default['skinchanger'][sex] or {}) end
		)
	end,
	isValidSkin = function(skinData)
		return type(skinData) == 'table' and next(skinData) ~= nil
	end,
	managesOwnPersistence = false,
}
