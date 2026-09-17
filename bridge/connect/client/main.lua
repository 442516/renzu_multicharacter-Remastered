models = {['m'] = `mp_m_freemode_01`, ['f'] = `mp_f_freemode_01`}

function requestModel(model)
	RequestModel(model)
	local timeout = GetGameTimer() + 5000
	while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
	return HasModelLoaded(model)
end

function baseModel(sex, overrideModel)
	return overrideModel or models[sex] or models['m']
end

function switchModelIfNeeded(model)
	if model and model ~= 0 then
		local current = PlayerPedId()
		if GetEntityModel(current) ~= model then
			requestModel(model)
			SetPlayerModel(PlayerId(), model)
			SetModelAsNoLongerNeeded(model)
		end
	end
	return PlayerPedId()
end

AppearanceImpl = AppearanceImpl or {
	getModel = function(sex) return sex == 'm' and models['m'] or models['f'] end,
	setAppearance = function() end,
	openCreator = function(ped, sex, onDone) onDone({}) end,
	isValidSkin = function() return true end,
	managesOwnPersistence = false,
}

Appearance = {}

function Appearance.GetSystem()
	return Config.Appearance
end

function Appearance.ManagesOwnPersistence()
	return AppearanceImpl.managesOwnPersistence == true
end

function Appearance.GetModel(sex, overrideModel)
	return AppearanceImpl.getModel(sex, overrideModel)
end

function Appearance.SetAppearance(ped, skinData, sex)
	return AppearanceImpl.setAppearance(ped, skinData, sex)
end

function Appearance.OpenCreator(ped, sex, onDone)
	return AppearanceImpl.openCreator(ped, sex, onDone)
end

function Appearance.IsValidSkin(skinData)
	return AppearanceImpl.isValidSkin(skinData)
end
