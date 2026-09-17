if Config.Appearance ~= 'skinchanger' then return end

AppearanceImpl = {
	getModel = function(sex)
		return sex == 'm' and models['m'] or models['f']
	end,
	setAppearance = function(ped, skinData, sex)
		if not skinData or not next(skinData) then
			skinData = Config.Default['skinchanger'] and Config.Default['skinchanger'][sex]
		end
		TriggerEvent('skinchanger:loadSkin', skinData)
	end,
	openCreator = function(ped, sex, onDone)
		local default = Config.Default['skinchanger'] and Config.Default['skinchanger'][sex] or {}
		TriggerEvent('skinchanger:loadSkin', default, function()
			local freshPed = PlayerPedId()
			SetPedAoBlobRendering(freshPed, true)
			ResetEntityAlpha(freshPed)
			SetEntityVisible(freshPed, true)
			onDone(default)
		end)
	end,
	isValidSkin = function(skinData)
		return type(skinData) == 'table' and skinData.hair_1 ~= nil
	end,
	managesOwnPersistence = false,
}
