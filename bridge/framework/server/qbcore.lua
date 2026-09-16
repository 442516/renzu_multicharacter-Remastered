if Config.Framework ~= 'QBCORE' then return end

QBCore = nil
do
	local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
	if not ok or not obj then
		print('^1[renzu_multicharacter] ERROR: Config.Framework is QBCORE but exports[\'qb-core\']:GetCoreObject() failed. Is qb-core actually running?^7')
	end
	QBCore = obj
end

local function usingRcore() return ServerAppearance.ManagesOwnPersistence() end

function GetPlayerFromId(src)
	local xPlayer = QBCore.Functions.GetPlayer(src)
	if not xPlayer then return end
	xPlayer.identifier = xPlayer.PlayerData.citizenid
	return xPlayer
end

GetCharacters = function(source, data, slots)
	local characters = {}
	local license = GetIdentifiers(source)
	local result = MySQL.query.await('SELECT * FROM players WHERE license = ?', {license})
	if result and #result > 0 then
		for i = 1, #result do
			local citizenid = result[i].citizenid
			local info = json.decode(result[i].charinfo)
			local money = json.decode(result[i].money)
			local job = json.decode(result[i].job)
			local skinRows = not usingRcore() and MySQL.query.await(
				'SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', {citizenid, 1}
			) or nil
			local playerskin
			if usingRcore() then
				playerskin = ServerAppearance.GetStoredSkin(citizenid) or {}
			else
				playerskin = skinRows and skinRows[1] and json.decode(skinRows[1].skin) or {}
				playerskin.model = skinRows and skinRows[1] and tonumber(skinRows[1].model)
			end
			characters[result[i].cid] = {
				slot = result[i].cid,
				name = (info.firstname or 'No name')..' '..(info.lastname or 'No Lastname'),
				job = job.label or 'Unemployed',
				grade = job.grade and job.grade.name or 'Unranked',
				dateofbirth = info.birthdate or '',
				bank = money.bank,
				money = money.cash,
				citizenid = citizenid,
				identifier = citizenid,
				skin = playerskin,
				sex = info.gender == 0 and 'm' or 'f',
				position = result[i].position and result[i].position ~= '' and json.decode(result[i].position) or vec3(280.03, -584.29, 43.29),
				extras = GetExtras(citizenid),
			}
		end
	end
	return {characters = characters, slots = slots}
end

DeleteCharacter = function(source, slot)
	local license = GetIdentifiers(source)
	local result = MySQL.query.await('SELECT * FROM players WHERE license = ?', {license})
	for i = 1, (#(result or {})) do
		if result[i].citizenid == slot then
			pcall(function() QBCore.Player.DeleteCharacter(source, result[i].citizenid) end)
			MySQL.query.await('DELETE FROM players WHERE citizenid = ?', {result[i].citizenid})
			if not usingRcore() then
				MySQL.query('DELETE FROM playerskins WHERE citizenid = ?', {result[i].citizenid})
			end
			TriggerClientEvent('QBCore:Notify', source, 'Character Deleted', 'success')
			break
		end
	end
	return true
end

LoadPlayer = function(source)
	local ts = 0
	while not GetPlayerFromId(source) and ts < 1000 do ts = ts + 1 Wait(0) end
	local ply = Player(source).state
	local identifier = GetPlayerFromId(source) and GetPlayerFromId(source).identifier
	if identifier then ply:set('identifier', identifier, true) end
	return true
end

Login = function(source, data, new)
	if new then
		new.cid = data
		new.charinfo = {
			firstname = new.firstname,
			lastname = new.lastname,
			birthdate = new.birthdate or new.dateofbirth,
			gender = new.sex == 'm' and 0 or 1,
			nationality = new.nationality,
		}
	end
	QBCore.Player.Login(source, not new and data or false, new or nil)
	QBCore.Commands.Refresh(source)
	print(('^2[renzu_multicharacter]^7 %s (Citizen ID: %s) has successfully loaded!'):format(GetPlayerName(source), data))
	local ply = Player(source).state
	ply:set('identifier', data, true)
	if Config.ApartmentSystem == 'qb-apartments' then
		TriggerClientEvent('apartments:client:setupSpawnUI', source, {citizenid = data})
	end
	if GetResourceState('qb-log') == 'started' then
		TriggerEvent('qb-log:server:CreateLog', 'joinleave', 'Loaded', 'green',
			('**%s** (%s | %s | %s) loaded character %s (source %s)'):format(
				GetPlayerName(source),
				GetPlayerIdentifierByType(source, 'discord') or 'undefined',
				GetPlayerIdentifierByType(source, 'ip') or 'undefined',
				GetPlayerIdentifierByType(source, 'license') or 'undefined',
				data, source))
	end
	if new then GiveStarterItems(source) end
	return true
end

SaveSkin = function(source, skinData)
	if usingRcore() then return true end
	local Player = GetPlayerFromId(source)
	if Player and skinData and skinData.model ~= nil then
		MySQL.query('DELETE FROM playerskins WHERE citizenid = ?', {Player.identifier}, function()
			MySQL.insert('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, ?)', {
				Player.identifier,
				skinData.model,
				json.encode(skinData),
				1,
			})
		end)
	end
	return true
end

Command = function(command)
	QBCore.Commands.Add(command, 'Add Character Slots', {
		{name = 'id', help = 'player server id'},
		{name = 'slots', help = 'total slots, e.g. 1, 5, 7'},
	}, false, function(source, args)
		UpdateSlot(source, args[1], args[2])
	end, 'admin')
end

GiveStarterItems = function(source)
	local starter = json.decode(GetResourceKvpString('starteritems') or '[]') or {}
	CreateThread(function()
		local Player = QBCore.Functions.GetPlayer(source)
		if not Player or starter[Player.PlayerData.citizenid] then return end

		local coreItems = QBCore.Shared and QBCore.Shared.StarterItems
		local itemList = (coreItems and next(coreItems)) and coreItems or Config.FallbackStarterItems

		for _, v in pairs(itemList) do
			local info = {}
			if v.item == 'id_card' then
				info.citizenid = Player.PlayerData.citizenid
				info.firstname = Player.PlayerData.charinfo.firstname
				info.lastname = Player.PlayerData.charinfo.lastname
				info.birthdate = Player.PlayerData.charinfo.birthdate
				info.gender = Player.PlayerData.charinfo.gender
				info.nationality = Player.PlayerData.charinfo.nationality
			elseif v.item == 'driver_license' then
				info.firstname = Player.PlayerData.charinfo.firstname
				info.lastname = Player.PlayerData.charinfo.lastname
				info.birthdate = Player.PlayerData.charinfo.birthdate
				info.type = 'Class C Driver License'
			end
			Player.Functions.AddItem(v.item, v.amount, false, next(info) and info or nil)
		end
		starter[Player.PlayerData.citizenid] = true
		SetResourceKvp('starteritems', json.encode(starter))
	end)
	Wait(2000)
end
