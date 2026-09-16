if Config.Appearance ~= 'illenium-appearance' then return end

local resourceName = 'illenium-appearance'

local menuConfig = {
	ped = true, headBlend = true, faceFeatures = true, headOverlays = true, components = true,
	componentConfig = {
		masks = true, upperBody = true, lowerBody = true, bags = true, shoes = true,
		scarfAndChains = true, bodyArmor = true, shirts = true, decals = true, jackets = true
	},
	props = true,
	propConfig = {hats = true, glasses = true, ear = true, watches = true, bracelets = true},
	tattoos = true,
	enableExit = true,
}

AppearanceImpl = {
	getModel = function(sex, overrideModel)
		return baseModel(sex, overrideModel)
	end,
	setAppearance = function(ped, skinData, sex)
		if not skinData or not next(skinData) then return end
		local modelHash = nil
		if skinData.model then
			modelHash = type(skinData.model) == 'string' and joaat(skinData.model) or skinData.model
		end
		local freshPed = switchModelIfNeeded(modelHash)
		exports[resourceName]:setPedAppearance(freshPed, skinData)
	end,
	openCreator = function(ped, sex, onDone)
		local freshPed = PlayerPedId()
		SetPedAoBlobRendering(freshPed, true)
		ResetEntityAlpha(freshPed)
		SetEntityVisible(freshPed, true)
		exports[resourceName]:startPlayerCustomization(function(appearance)
			if appearance then
				onDone(appearance)
			else
				local current = exports[resourceName]:getPedAppearance(PlayerPedId())
				onDone(current)
			end
		end, menuConfig)
	end,
	isValidSkin = function(skinData)
		return type(skinData) == 'table' and skinData.headBlend ~= nil
	end,
	managesOwnPersistence = false,
}
