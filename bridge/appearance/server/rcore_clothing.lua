if Config.Appearance ~= 'rcore_clothing' then return end

ServerAppearanceImpl = {
	managesOwnPersistence = true,
	getStoredSkin = function(identifier)
		local ok, rcoreSkin = pcall(function()
			return exports['rcore_clothing']:getSkinByIdentifier(identifier)
		end)
		if ok and rcoreSkin then
			return {model = rcoreSkin.ped_model, skin = rcoreSkin.skin}
		end
		return {}
	end,
}
