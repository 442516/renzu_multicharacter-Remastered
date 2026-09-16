if Config.SpawnSystem ~= 'renzu_multicharacter' and Config.SpawnSystem ~= 'renzu_spawn' then return end

SpawnBridge = SpawnBridge or {}

if Config.SpawnSystem == 'renzu_multicharacter' then
	function SpawnBridge.Open(fallbackCoord, cData, isNew)
		RunBuiltinSpawnPicker(fallbackCoord)
	end
else
	function SpawnBridge.Open(fallbackCoord, cData, isNew)
		local ok = pcall(function() exports['renzu_spawn']:Selector(fallbackCoord, Config.Spawns) end)
		if not ok then
			warn('[renzu_multicharacter] Config.SpawnSystem is "renzu_spawn" but that resource is not installed/running.')
		end
	end
end
