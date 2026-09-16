ServerAppearanceImpl = ServerAppearanceImpl or {
	managesOwnPersistence = false,
	getStoredSkin = function() return nil end,
}

ServerAppearance = {}

function ServerAppearance.ManagesOwnPersistence()
	return ServerAppearanceImpl.managesOwnPersistence == true
end

function ServerAppearance.GetStoredSkin(identifier)
	return ServerAppearanceImpl.getStoredSkin(identifier)
end
