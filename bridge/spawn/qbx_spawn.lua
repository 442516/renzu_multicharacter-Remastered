if Config.SpawnSystem ~= 'qbx_spawn' then return end

SpawnBridge = SpawnBridge or {}

function SpawnBridge.Open(fallbackCoord, cData, isNew)
	if isNew and Config.UseNewCharacterSpawn then
		TeleportToDefaultSpawn(Config.NewCharacterSpawn)
		return
	end
	warn('[renzu_multicharacter] Config.SpawnSystem is "qbx_spawn" - this integration is a best-effort based on qb-spawn\'s verified event names, NOT confirmed against qbx_spawn\'s own docs. Test it yourself.')
	if GetResourceState('qbx_spawn') ~= 'started' then
		warn('[renzu_multicharacter] Config.SpawnSystem is "qbx_spawn" but that resource is not installed/running.')
	end
	TriggerEvent('qb-spawn:client:setupSpawns', cData or {}, isNew or false, nil)
	TriggerEvent('qb-spawn:client:openUI', true)
end
