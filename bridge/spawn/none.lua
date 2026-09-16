if Config.SpawnSystem ~= 'none' then return end

SpawnBridge = SpawnBridge or {}

function SpawnBridge.Open(fallbackCoord, cData, isNew)
	TriggerEvent('renzu_multicharacter:spawnRequested', {new = isNew, position = fallbackCoord})
	DoScreenFadeIn(1000)
end
