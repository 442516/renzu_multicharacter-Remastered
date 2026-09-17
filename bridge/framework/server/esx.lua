if Config.Framework ~= 'ESX' then return end

ESX = nil
do
	local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
	if not ok or not obj then
		print('^1[renzu_multicharacter] ERROR: Config.Framework is ESX but es_extended:getSharedObject() failed. Is es_extended actually running?^7')
	end
	ESX = obj
end

local function usingRcore() return ServerAppearance.ManagesOwnPersistence() end

function GetPlayerFromId(src)
	return ESX.GetPlayerFromId(src)
end

GetCharacters = function(source, data, slots)
	local characters = {}
	local license = ESX.GetIdentifier(source)
	local idlike = Config.Prefix..'%:'..license
	local rows = MySQL.query.await('SELECT * FROM users WHERE identifier LIKE ?', {'%'..idlike..'%'})
	if rows then
		for _, v in pairs(rows) do
			local job, grade = v.job or 'unemployed', tostring(v.job_grade)
			if ESX.Jobs[job] and ESX.Jobs[job].grades then
				if job ~= 'unemployed' then
					grade = (ESX.Jobs[job].grades[grade] and ESX.Jobs[job].grades[grade].label)
						or (ESX.Jobs[job].grades[tonumber(grade)] and ESX.Jobs[job].grades[tonumber(grade)].label) or ''
				else
					grade = ''
				end
				job = ESX.Jobs[job].label
			end
			local accounts = json.decode(v.accounts or '{}') or {}
			local id = tonumber(string.sub(v.identifier, #Config.Prefix + 1, string.find(v.identifier, ':') - 1))
			if id and not characters[id] then
				local skin
				if usingRcore() then
					skin = ServerAppearance.GetStoredSkin(v.identifier) or {}
				else
					skin = v.skin and json.decode(v.skin or '[]') or {}
				end
				characters[id] = {
					slot = id,
					identifier = v.identifier,
					name = (v.firstname or 'No name')..' '..(v.lastname or 'No Lastname'),
					job = job or 'Unemployed',
					grade = grade or 'No grade',
					dateofbirth = v.dateofbirth or '',
					bank = accounts.bank,
					money = accounts.money,
					skin = skin,
					sex = v.sex,
					position = v.position and v.position ~= '' and json.decode(v.position) or vec3(280.03, -584.29, 43.29),
					extras = GetExtras(v.identifier, v.group),
				}
			end
		end
	end
	return {characters = characters, slots = slots}
end

DeleteCharacter = function(source, slot)
	local idlike = Config.Prefix..'%:'..ESX.GetIdentifier(source)
	local rows = MySQL.query.await('SELECT * FROM users WHERE identifier LIKE ?', {'%'..idlike..'%'})
	for _, v in pairs(rows or {}) do
		local id = tonumber(string.sub(v.identifier, #Config.Prefix + 1, string.find(v.identifier, ':') - 1))
		if id == slot then
			MySQL.query.await('DELETE FROM `users` WHERE `identifier` = ?', {v.identifier})
			break
		end
	end
	return true
end

LoadPlayer = function(source)
	local ts = 0
	while not GetPlayerFromId(source) and ts < 1000 do ts = ts + 1 Wait(0) end
	local ply = Player(source).state
	local xPlayer = GetPlayerFromId(source)
	if xPlayer then ply:set('identifier', xPlayer.identifier, true) end
	return true
end

Login = function(source, data, new)
	TriggerEvent('esx:onPlayerJoined', source, Config.Prefix..data, new or nil)
	LoadPlayer(source)
	if new then
		CreateThread(function()
			Wait(1000)
			local xPlayer = ESX.GetPlayerFromId(source)
			if xPlayer then
				for _, v in ipairs(Config.ESXStarterMoney) do
					if v.account == 'money' then
						xPlayer.addMoney(v.amount)
					else
						xPlayer.addAccountMoney(v.account, v.amount)
					end
				end
			end
		end)
		GiveStarterItems(source)
	end
	return true
end

SaveSkin = function(source, skinData)
	if usingRcore() then return true end
	local xPlayer = GetPlayerFromId(source)
	MySQL.query.await('UPDATE users SET skin = ? WHERE identifier = ?', {json.encode(skinData), xPlayer.identifier})
	return true
end

Command = function(command)
	ESX.RegisterCommand(command, 'admin', function(xPlayer, args)
		UpdateSlot(xPlayer.source, args[1], args[2])
	end, false)
end

GiveStarterItems = function(source)
	local starter = json.decode(GetResourceKvpString('starteritems') or '[]') or {}
	CreateThread(function()
		local xPlayer = ESX.GetPlayerFromId(source)
		if not xPlayer or starter[xPlayer.identifier] then return end
		for _, v in ipairs(Config.ESXStarterItem) do
			xPlayer.addInventoryItem(v.item, v.amount)
		end
		starter[xPlayer.identifier] = true
		SetResourceKvp('starteritems', json.encode(starter))
	end)
	Wait(2000)
end

SavePosition = function(source)
	local ply = Player(source).state
	local identifier = ply.identifier
	if not identifier then return end
	local ped = GetPlayerPed(source)
	if not ped or ped == 0 then return end
	local coords = GetEntityCoords(ped)
	local heading = GetEntityHeading(ped)
	local posData = json.encode({x = coords.x, y = coords.y, z = coords.z, heading = heading})
	MySQL.query('UPDATE users SET position = ? WHERE identifier = ?', {posData, identifier})
end
