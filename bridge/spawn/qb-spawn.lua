if Config.SpawnSystem ~= 'qb-spawn' then return end

SpawnBridge = SpawnBridge or {}

function SpawnBridge.Open(fallbackCoord, cData, isNew)
	if GetResourceState('qb-spawn') ~= 'started' then
		warn('[renzu_multicharacter] Config.SpawnSystem is "qb-spawn" but that resource is not installed/running.')
	end
	
	TriggerEvent('qb-spawn:client:setupSpawns', cData or {}, isNew or false, nil)
	TriggerEvent('qb-spawn:client:openUI', true)
end
