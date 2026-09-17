if Config.Appearance ~= 'rcore_clothing' then return end

AppearanceImpl = {
	getModel = function(sex, overrideModel)
		return baseModel(sex, overrideModel)
	end,
	setAppearance = function(ped, skinData, sex)
		if not skinData or not skinData.skin then return end
		local freshPed = switchModelIfNeeded(skinData.model)
		exports['rcore_clothing']:setPedSkin(freshPed, skinData.skin)
	end,
	openCreator = function(ped, sex, onDone)
		local freshPed = PlayerPedId()
		SetEntityVisible(freshPed, true)
		local ev = (Config.Framework == 'ESX') and 'rcore_clothing:esx:charcreator' or 'rcore_clothing:qb:charcreator'
		TriggerEvent(ev)
		RegisterNetEvent('rcore_clothing:charcreator:done')
		local handler
		handler = AddEventHandler('rcore_clothing:charcreator:done', function()
			RemoveEventHandler(handler)
			local ok, current = pcall(function() return exports['rcore_clothing']:getPlayerClothing() end)
			onDone(ok and current or nil)
		end)
	end,
	isValidSkin = function(skinData)
		return type(skinData) == 'table'
	end,
	managesOwnPersistence = true,
}
