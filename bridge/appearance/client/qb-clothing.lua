if Config.Appearance ~= 'qb-clothing' then return end

AppearanceImpl = {
	getModel = function(sex, overrideModel)
		return baseModel(sex, overrideModel)
	end,
	setAppearance = function(ped, skinData, sex)
		if not skinData or not next(skinData) then
			skinData = Config.Default['qb-clothing'] and Config.Default['qb-clothing'][sex]
		end
		if not skinData then return end
		local freshPed = PlayerPedId()
		TriggerEvent('qb-clothing:client:loadPlayerClothing', skinData, freshPed)
	end,
	openCreator = function(ped, sex, onDone)
		TriggerEvent('qb-clothing:client:openMenu')
		onDone(Config.Default['qb-clothing'] and Config.Default['qb-clothing'][sex] or {})
	end,
	isValidSkin = function(skinData)
		return type(skinData) == 'table' and next(skinData) ~= nil
	end,
	managesOwnPersistence = false,
}
