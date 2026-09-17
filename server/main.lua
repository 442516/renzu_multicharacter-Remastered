local callbacks = {}
local logout = {}
local registered = {}

local function registercallback(name, cb)
	callbacks[name] = cb
end

RegisterNetEvent('servercallback', function(name, ...)
	local src = source
	local cb = callbacks[name]
	if not cb then
		print(('^1[renzu_multicharacter] ERROR: no server callback registered for "%s"^7'):format(name))
		TriggerClientEvent('servercallback', src, name, nil)
		return
	end
	local ok, result = pcall(cb, src, ...)
	if not ok then
		print(('^1[renzu_multicharacter] ERROR in callback "%s": %s^7'):format(name, tostring(result)))
		TriggerClientEvent('servercallback', src, name, nil)
		return
	end
	TriggerClientEvent('servercallback', src, name, result)
end)

registercallback('renzu_multicharacter:choosecharacter', function(src, slot)
	Login(src, slot, nil)
	SetPlayerRoutingBucket(src, 0)
	logout[src] = false
	return LoadPlayer(src)
end)

registercallback('renzu_multicharacter:createcharacter', function(src, data)
	if Config.UseDefaultIdentity then
		Login(src, data.slot, data.info)
		SetPlayerRoutingBucket(src, 0)
		logout[src] = false
	else
		registered[src] = data
	end
	return true
end)

registercallback('renzu_multicharacter:deletecharacter', function(src, slot)
	return Config.CanDelete and DeleteCharacter(src, slot)
end)

registercallback('renzu_multicharacter:saveappearance', function(src, skinData)
	SaveSkin(src, skinData)
	return true
end)

registercallback('getcharacters', function(src, data)
	SetPlayerRoutingBucket(src, math.random(99, 999))
	local slotsKvp = json.decode(GetResourceKvpString('char_slots') or '[]') or {}
	local availableslots = slotsKvp[GetIdentifiers(src)] or Config.Slots
	return GetCharacters(src, data, availableslots)
end)

RegisterNetEvent('renzu_multicharacter:relog', function()
	local src = source
	SavePosition(src)
	if Config.Framework == 'ESX' then
	
		TriggerEvent('esx:playerLogout', src)
	else
		if Config.Framework == 'QBOX' then
			exports['qbx_core']:Logout(src)
		elseif Config.Framework == 'QBCORE' and QBCore then
			QBCore.Player.Logout(src)
		end
		TriggerClientEvent('renzu_multicharacter:relogComplete', src)
	end
	logout[src] = true
end)

local function completeIdentity(src, data)
	if not registered[src] then return false end
	local slot = registered[src].slot
	Login(src, slot, data)
	SetPlayerRoutingBucket(src, 0)
	logout[src] = false
	registered[src] = nil
	if Config.Framework == 'QBCORE' or Config.Framework == 'QBOX' then
		TriggerClientEvent('renzu_multicharacter:identityComplete', src)
	end
	return true
end

RegisterNetEvent('esx_identity:completedRegistration', function(src, data)
	completeIdentity(src, data)
end)

exports('RegisterComplete', function(src, data)
	completeIdentity(src, data)
end)

AddEventHandler('playerDropped', function()
	SavePosition(source)
	logout[source] = true
end)

function GetIdentifiers(id)
	local license = 'licensed'
	local numIdentifiers = GetNumPlayerIdentifiers(id)
	for i = 0, numIdentifiers do
		local identifier = GetPlayerIdentifier(id, i)
		if string.find(tostring(identifier), 'license') then
			license = identifier
			break
		end
	end
	return license
end

for name in pairs(Config.Status) do
	AddStateBagChangeHandler(name, nil, function(bagName, _, value)
		Wait(1500)
		if value == nil then return end
		local status = GlobalState.PlayerStates or {}
		local net = tonumber(bagName:gsub('player:', ''), 10)
		if (net and logout[net]) or not net then return end
		local ply = Player(net).state
		if not ply.identifier then return end
		status[ply.identifier] = status[ply.identifier] or {}
		status[ply.identifier][name] = value
		SetResourceKvp('char_status', json.encode(status))
		GlobalState.PlayerStates = status
	end)
end

registercallback('setplayertolastvehicle', function(src, net, preview)
	local vehicle = NetworkGetEntityFromNetworkId(net)
	if DoesEntityExist(vehicle) then
		local ped = GetPlayerPed(src)
		local coord = GetEntityCoords(vehicle)
		SetEntityCoords(ped, coord.x, coord.y, coord.z)
		SetPlayerRoutingBucket(src, 0)
		for i = -1, 7 do
			local pedinseat = GetPedInVehicleSeat(vehicle, i)
			if pedinseat == ped then
				SetPedIntoVehicle(ped, vehicle, i)
				break
			end
			if pedinseat == 0 then
				local timeout = GetGameTimer() + 3000
				while GetPedInVehicleSeat(vehicle, i) ~= ped and GetGameTimer() < timeout do
					SetPedIntoVehicle(ped, vehicle, i)
					Wait(111)
				end
				break
			end
		end
	end
	if preview then return end
	local ply = Player(src).state
	ply:set('invehicle', false, true)
	return false
end)

GetExtras = function(id, group)
	local status = GlobalState.PlayerStates or {}
	local admin = group ~= nil and group ~= 'user'
	if admin then
		status[id] = status[id] or {}
		status[id]['admin'] = true
	end
	return status[id] or {}
end

UpdateSlot = function(src, id, slotAmount)
	local slotsKvp = json.decode(GetResourceKvpString('char_slots') or '[]') or {}
	local license = GetIdentifiers(id)
	if license == nil then return end
	slotsKvp[license] = tonumber(slotAmount) or Config.Slots
	SetResourceKvp('char_slots', json.encode(slotsKvp))
	return true
end

GlobalState.PlayerStates = json.decode(GetResourceKvpString('char_status') or '[]') or {}

Command(Config.commandslot)
