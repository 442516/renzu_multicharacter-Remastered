local loaded = false
local stateactive = false
local defaultspawn = Config.PreviewSpawn
local useSkinMenu = false
local slots = Config.Slots
local states = {}
local logout = false
local New = false
local finished = false
local chosen = false
local cam = nil
local pedshots = {}
local peds = {}
local chosenslot = 1
local characters = {}
local pendingSex = 'm'
local identityInFlight = false

local function pushStaticData()
	SendNUIMessage({
		i18n = GetActiveLocaleTable(Config.Locale),
		locale = Config.Locale,
	})
	local raw = LoadResourceFile(GetCurrentResourceName(), 'shared/nationalities.json')
	if raw then
		local ok, decoded = pcall(json.decode, raw)
		if ok then
			SendNUIMessage({nationalities = decoded.nationalities or {}})
		end
	end
	if Config.bgmusic then
		SendNUIMessage({bgmusic = true, sound = Config.IntroSound, volume = Config.IntroVolume})
	end
end

local callbacks = {}
local function callback(name, ...)
	callbacks[name] = promise:new()
	TriggerServerEvent('servercallback', name, ...)
	return Citizen.Await(callbacks[name])
end

RegisterNetEvent('servercallback', function(name, data)
	if callbacks[name] then
		callbacks[name]:resolve(data)
	end
end)

Citizen.CreateThreadNow(function()
	DoScreenFadeOut(0)
	Wait(1500)
	SendNUIMessage({fade = true})
	pushStaticData()
	while true do
		Wait(100)
		if NetworkIsSessionActive() or NetworkIsPlayerActive(PlayerId()) then
			exports['spawnmanager']:setAutoSpawn(false)
			Wait(1001)
			SendNUIMessage({fade = true})
			CharacterSelect()
			break
		end
	end
end)

WeatherTransition = function()
	if GetResourceState('qb-weathersync') == 'started' then
		TriggerEvent('qb-weathersync:client:DisableSync')
	end
	CreateThread(function()
		local time, count, ts = 1, 0, 0
		while not loaded and not chosen do
			NetworkOverrideClockTime(time, 1, 0)
			ThefeedHideThisFrame()
			HideHudComponentThisFrame(11)
			HideHudComponentThisFrame(12)
			HideHudComponentThisFrame(21)
			HideHudAndRadarThisFrame()
			SetWeatherTypeTransition(`THUNDER`, `CLEAR`, 0.7)
			ts = ts + 1
			count = count + 1
			if count > 10 then
				count = 0
				time = time + 1
				if time >= 24 and ts < 500 then time = 0 end
				if time >= 23 and ts > 500 then time = 23 end
			end
			Wait(0)
			if not chosen and not IsEntityPositionFrozen(PlayerPedId()) then
				FreezeEntityPosition(PlayerPedId(), true)
			end
		end
		SetWeatherTypeNowPersist('CLEAR')
		SetWeatherTypeTransition(`NEUTRAL`, `CLEAR`, 0.7)
	end)
end

local function setModel(model, force)
	if not force and GetEntityModel(PlayerPedId()) == model then return end
	RequestModel(model)
	while not HasModelLoaded(model) do Wait(0) end
	SetPlayerModel(PlayerId(), model)
	SetModelAsNoLongerNeeded(model)
end

GetPedShot = function(ped)
	Wait(0)
	local tempHandle = RegisterPedheadshotTransparent(ped)
	local headshotTxd = nil
	local timer = 1100
	while (not IsPedheadshotReady(tempHandle) or not IsPedheadshotValid(tempHandle)) and timer > 0 do
		Wait(1)
		timer = timer - 10
	end
	headshotTxd = GetPedheadshotTxdString(tempHandle)
	if headshotTxd == nil or headshotTxd == 0 or tempHandle == 0 or not IsPedheadshotValid(tempHandle) then
		tempHandle = RegisterPedheadshot(ped)
		timer = 1100
		while (not IsPedheadshotReady(tempHandle) or not IsPedheadshotValid(tempHandle)) and timer > 0 do
			Wait(1)
			timer = timer - 10
		end
		headshotTxd = GetPedheadshotTxdString(tempHandle)
	end
	return headshotTxd, tempHandle
end

ClearPedHeadshots = function(handle)
	UnregisterPedheadshot(handle)
end

CreatePedHeadShots = function(chars)
	for i = 1, slots do
		local chardata = chars[i]
		local slot = i - 1
		if chardata and not pedshots[slot] then
			local sex = chardata.sex == 'm' and 'm' or 'f'
			local model = (chardata.skin and chardata.skin.model) or Appearance.GetModel(sex)
			setModel(model)
			SetEntityCoords(PlayerPedId(), defaultspawn.x, defaultspawn.y, defaultspawn.z)
			Appearance.SetAppearance(PlayerPedId(), chardata.skin, sex)
			SetEntityVisible(PlayerPedId(), false)
			FreezeEntityPosition(PlayerPedId(), true)
			local pedshot, handle = GetPedShot(PlayerPedId())
			pedshots[slot] = pedshot
			SendNUIMessage({pedshots = pedshot, slot = slot})
			SetTimeout(1000, function() ClearPedHeadshots(handle) end)
		elseif not pedshots then
			SendNUIMessage({pedshots = 'default', slot = slot, default = true})
		end
	end
end

IntroCam = function()
	chosen = false
	loaded = false
	SendNUIMessage({fade = true})
	SendNUIMessage({showui = true, delete = Config.CanDelete})
	local data = callback('getcharacters') or {slots = Config.Slots}
	slots = data.slots or Config.Slots
	characters = data.characters or {}
	DoScreenFadeIn(1000)
	SetEntityVisible(PlayerPedId(), false)
	SetEntityCoords(PlayerPedId(), 0.0, 0.0, 677.0)
	CreatePedHeadShots(characters)
	WeatherTransition()
	cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 1609.638, -2272.897, 483.33, 0.00, 0.00, -10.00, 100.00, false, 0)
	Wait(3000)
	DoScreenFadeIn(1000)
	SetCamActive(cam, true)
	RenderScriptCams(true, true, 6000, true, true)
	SendNUIMessage({fade = false})
	if Config.ShowLogo then SendNUIMessage({showlogo = true}) end
	while #(GetFinalRenderedCamCoord() - vec3(1609.638, -2272.897, 483.33)) > 10 do Wait(111) end
	SendNUIMessage({data = {characters = characters, slots = slots, extras = Config.Status}})
	if not Config.cam then
		if Config.ShowLogo then SendNUIMessage({showlogo = false}) end
		SendNUIMessage({show = true})
		SetNuiFocus(true, true)
	end
	while not chosen and Config.cam do
		for _, v in ipairs(Config.CameraIntro) do
			if not chosen then
				SetCamParams(cam, v.coord, v.rot, 50.0, 8000, 0, 0, 2)
				if Config.ShowLogo then SendNUIMessage({showlogo = false}) end
				SendNUIMessage({show = true})
				SetNuiFocus(true, true)
			else
				break
			end
			while #(GetFinalRenderedCamCoord() - v.coord) > 10 and not chosen do
				local camcoord = GetFinalRenderedCamCoord()
				SetFocusPosAndVel(camcoord.x, camcoord.y, camcoord.z)
				Wait(111)
			end
			Wait(2000)
		end
		Wait(10)
	end
end

CharacterSelect = function()
	TriggerEvent('esx:loadingScreenOff')
	ShutdownLoadingScreen()
	ShutdownLoadingScreenNui()
	ShutdownLoadingScreenNui(true)
	RequestCollisionAtCoord(0.0, 0.0, 777.0)
	FreezeEntityPosition(PlayerPedId(), true)
	DoScreenFadeOut(300)
	IntroCam()
	DoScreenFadeIn(300)
	Wait(2000)
	ClearFocus()
	SetFocusEntity(PlayerPedId())
end

Cleanups = function()
	if DoesCamExist(cam) then
		SetCamActive(cam, false)
		DestroyCam(cam, true)
		RenderScriptCams(false, false, 0, true, true)
	end
	SetNuiFocus(false, false)
	SetEntityVisible(PlayerPedId(), true)
	ClearFocus()
	SetFocusEntity(PlayerPedId())
	for _, v in pairs(peds) do
		if DoesEntityExist(v) then DeleteEntity(v) end
	end
end

PlayAnim = function(ped, dict, anim)
	RequestAnimDict(dict)
	repeat Wait(1) until HasAnimDictLoaded(dict)
	TaskPlayAnim(ped, dict, anim, 1.0, 1.0, -1, 0, 0, 0, 0, 0)
end

ShowCharacter = function(slot)
	chosenslot = slot
	chosen = true
	Wait(10)
	local chardata = characters[tonumber(slot)]
	SetEntityVisible(PlayerPedId(), 1, 0)
	SetPedAoBlobRendering(PlayerPedId(), true)
	ResetEntityAlpha(PlayerPedId())
	FreezeEntityPosition(PlayerPedId(), false)

	if chardata and not chardata.new then
		SendNUIMessage({showcharacter = {showoptions = 'existing', slot = slot}})
	else
		SendNUIMessage({showcharacter = {showoptions = 'new', slot = slot, customregister = not Config.UseDefaultIdentity}})
		local model = Appearance.GetModel('m')
		setModel(model, true)
		SetEntityCoordsNoOffset(PlayerPedId(), defaultspawn.x, defaultspawn.y, defaultspawn.z)
		SetEntityHeading(PlayerPedId(), 0.0)
		Appearance.SetAppearance(PlayerPedId(), nil, 'm')
		characters[tonumber(slot)] = {position = {x = defaultspawn.x, y = defaultspawn.y + 10, z = defaultspawn.z}, new = true}
		SetBlockingOfNonTemporaryEvents(PlayerPedId(), true)
		SetCamParams(cam, defaultspawn.x, defaultspawn.y + 10, defaultspawn.z, 0.0, 0.0, 0.0, 20.0, 1, 0, 0, 2)
		PointCamAtEntity(cam, PlayerPedId(), 0.0, 0.0, 0.0, true)
		SetFocusPosAndVel(defaultspawn.x, defaultspawn.y + 10, defaultspawn.z)
		if Config.PreviewAnimation then
			local gestures = Config.Animations['choose'][math.random(1, #Config.Animations['choose'])]
			PlayAnim(PlayerPedId(), gestures.dict, gestures.anim)
		end
		New = true
		return
	end

	New = false
	local sex = chardata.sex == 'm' and 'm' or 'f'
	if not IsCamActive(cam) then SetCamActive(cam, true) end
	local model = Appearance.GetModel(sex, chardata.skin and chardata.skin.model)
	setModel(model)
	SetEntityCoordsNoOffset(PlayerPedId(), chardata.position.x, chardata.position.y, chardata.position.z)
	SetEntityHeading(PlayerPedId(), 0.0)
	SetFocusPosAndVel(chardata.position.x + 2, chardata.position.y + 2, chardata.position.z + 0.5)
	SetCamParams(cam, chardata.position.x, chardata.position.y + 2, chardata.position.z + 0.3, 0.0, 0.0, 0.0, 75.0, 1, 0, 0, 2)
	PointCamAtEntity(cam, PlayerPedId(), 0.0, 0.0, 0.0, true)
	RenderScriptCams(true, true, 0, true, true)
	Appearance.SetAppearance(PlayerPedId(), chardata.skin, sex)
	useSkinMenu = false
	if chardata.skin and not Appearance.IsValidSkin(chardata.skin) then
		warn('this character does not have a valid saved skin for "'..Appearance.GetSystem()..'" - using default')
		useSkinMenu = true
		pendingSex = sex
	end
	SetFocusEntity(PlayerPedId())
	if Config.PreviewAnimation then
		local gestures = Config.Animations['choose'][math.random(1, #Config.Animations['choose'])]
		Wait(100)
		if not CheckStates(true) then
			PlayAnim(PlayerPedId(), gestures.dict, gestures.anim)
		end
	end
end

SetupPlayer = function()
	local coord = vec3(characters[chosenslot].position.x, characters[chosenslot].position.y, characters[chosenslot].position.z - 0.7)
	SetFocusPosAndVel(coord.x, coord.y, coord.z)
	RequestCollisionAtCoord(coord.x, coord.y, coord.z)
	SetEntityCoords(PlayerPedId(), coord.x, coord.y, coord.z)
	FreezeEntityPosition(PlayerPedId(), true)
	while not HasCollisionLoadedAroundEntity(PlayerPedId()) do Wait(1) end
	FreezeEntityPosition(PlayerPedId(), false)
end

ChooseCharacter = function(slot)
	chosenslot = slot
	if Config.Framework == 'QBCORE' or Config.Framework == 'QBOX' then
		slot = characters[slot].citizenid
	end
	callback('renzu_multicharacter:choosecharacter', slot)
	ClearPedTasks(PlayerPedId())
	SetTimeout(0, CheckStates)
end

local spawnPromise = nil

local function openSpawnSelector(coord)
	spawnPromise = promise:new()
	local spawns = Config.Spawns
	local p = GetEntityCoords(PlayerPedId())
	if DoesCamExist(cam) then
		SetCamActive(cam, false)
		DestroyCam(cam, true)
	end
	cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', p.x, p.y, p.z + 800.0, -85.0, 0.0, 0.0, 100.0, false, 0)
	SetCamActive(cam, true)
	RenderScriptCams(true, false, 1, true, true)
	SendNUIMessage({showspawns = spawns, lastloc = coord and {x = coord.x, y = coord.y, z = coord.z, w = coord.w} or nil})
	SetNuiFocus(true, true)
	local result = Citizen.Await(spawnPromise)
	SetNuiFocus(false, false)
	return result
end

local function previewSpawn(name, coord)
	local target = nil
	if name == 'lastloc' and coord then
		target = coord
	else
		for _, v in ipairs(Config.Spawns) do
			if v.name == name then target = v.coord break end
		end
	end
	if not target then return end
	SetCamParams(cam, target.x, target.y, target.z + 800.0, -85.0, 0.0, 0.0, 100.0, 1000, 0, 0, 2)
	SetFocusPosAndVel(target.x, target.y, target.z)
	while #(GetFinalRenderedCamCoord() - vec3(target.x, target.y, target.z + 800.0)) > 10 do Wait(111) end
	SetCamParams(cam, target.x, target.y, target.z + 50.0, -85.0, 0.0, 0.0, 100.0, 2000, 0, 0, 2)
end

local function resolveSpawn(name, fallbackCoord)
	if name == 'lastloc' and fallbackCoord then return fallbackCoord end
	for _, v in ipairs(Config.Spawns) do
		if v.name == name then return v.coord end
	end
	return fallbackCoord or Config.NewCharacterSpawn
end

local function teleportToSpawn(coord)
	SendNUIMessage({showspawns = false})
	SetNuiFocus(false, false)
	local ped = PlayerPedId()
	FreezeEntityPosition(ped, true)
	SetCamParams(cam, coord.x, coord.y, coord.z + 4.2, -85.0, 0.0, 0.0, 50.0, 2000, 0, 0, 2)
	Wait(2000)
	SetFocusPosAndVel(coord.x, coord.y, coord.z)
	RequestCollisionAtCoord(coord.x, coord.y, coord.z)
	SetEntityCoords(ped, coord.x, coord.y, coord.z - 0.9)
	SetEntityHeading(ped, coord.w or 0.0)
	SetFocusEntity(ped)
	SetCamParams(cam, coord.x + 0.5, coord.y - 7, coord.z, 0.0, 0.0, 0.0, 20.0, 1000, 0, 0, 2)
	Wait(2000)
	RenderScriptCams(false, true, 3000, true, true)
	local timeout = GetGameTimer() + 3000
	while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do Wait(1) end
	FreezeEntityPosition(ped, false)
	Wait(3000)
	if DoesCamExist(cam) then
		SetCamActive(cam, false)
	end
end

function RunBuiltinSpawnPicker(fallbackCoord)
	local showPicker = Config.SpawnSelector and (
		Config.SpawnSelectorMode == 'always'
		or (Config.SpawnSelectorMode == 'existing_only' and not New)
		or (Config.SpawnSelectorMode == 'new_only' and New)
	)

	if showPicker then
		local chosenName = openSpawnSelector(fallbackCoord)
		local coord = resolveSpawn(chosenName, fallbackCoord)
		teleportToSpawn(coord)
	elseif New then
		teleportToSpawn(Config.NewCharacterSpawn)
	else
		teleportToSpawn(fallbackCoord or Config.NewCharacterSpawn)
	end
end

SpawnSelect = function(fallbackCoord)
	if FrameworkClient and FrameworkClient.OnPlayerLoaded then
		FrameworkClient.OnPlayerLoaded()
	end
	loaded = true

	if stateactive then
		Wait(2000)
		stateactive = false
		DoScreenFadeIn(1000)
		return
	end

	if SpawnBridge and SpawnBridge.Open then
		SpawnBridge.Open(fallbackCoord, characters[chosenslot], New)
	end
	New = false
	if useSkinMenu then
		Appearance.OpenCreator(PlayerPedId(), pendingSex, function() end)
		useSkinMenu = false
	end

	Wait(500)
	stateactive = false
	DoScreenFadeIn(1000)
end

enterWorldAsNewCharacter = function(sex)
	if Config.Framework == 'QBCORE' or Config.Framework == 'QBOX' then
		SpawnSelect(vec4(defaultspawn.x, defaultspawn.y + 10, defaultspawn.z, 0.0))
		Appearance.OpenCreator(PlayerPedId(), sex, function(finalSkin)
			if not Appearance.ManagesOwnPersistence() then
				callback('renzu_multicharacter:saveappearance', finalSkin)
			end
		end)
	end
end

RegisterNetEvent('renzu_multicharacter:identityComplete', function()
	identityInFlight = false
	enterWorldAsNewCharacter(pendingSex)
end)

local function onPlayerLoaded(playerData, isNew, savedSkin)
	loaded = true
	logout = false
	local sex = 'm'
	if playerData and playerData.sex then
		if tostring(playerData.sex):lower():find('mal') then sex = 'm'
		elseif tostring(playerData.sex):lower():find('fem') then sex = 'f' end
	end

	if isNew or not savedSkin or (type(savedSkin) == 'table' and not next(savedSkin)) then
		New = true
		Cleanups()
		SpawnSelect(vec4(defaultspawn.x, defaultspawn.y + 10, defaultspawn.z, 0.0))
		finished = false
		local model = Appearance.GetModel(sex)
		setModel(model, true)
		Appearance.SetAppearance(PlayerPedId(), nil, sex)
		Appearance.OpenCreator(PlayerPedId(), sex, function(finalSkin)
			if not Appearance.ManagesOwnPersistence() then
				callback('renzu_multicharacter:saveappearance', finalSkin)
			end
			finished = true
		end)
	else
		if Appearance.IsValidSkin(savedSkin) then
			Appearance.SetAppearance(PlayerPedId(), savedSkin, sex)
		end
	end

	Wait(400)
	repeat Wait(200) until not IsScreenFadedOut()
	TriggerServerEvent('esx:onPlayerSpawn')
	TriggerEvent('esx:onPlayerSpawn')
	TriggerEvent('playerSpawned')
	TriggerEvent('esx:restoreLoadout')
	FreezeEntityPosition(PlayerPedId(), false)
	ClearPedTasks(PlayerPedId())
	stateactive = false
end

RegisterNetEvent('esx:playerLoaded', function(playerData, isNew, skinData)
	if Config.Framework ~= 'ESX' then return end
	onPlayerLoaded(playerData, isNew, skinData)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
	DoScreenFadeOut(500)
	Wait(1000)
	CharacterSelect()
	TriggerEvent('esx_skin:resetFirstSpawn')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
	DoScreenFadeOut(500)
	Wait(1000)
	CharacterSelect()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
	DoScreenFadeOut(500)
	Wait(1000)
	CharacterSelect()
end)

RegisterNetEvent('renzu_multicharacter:relogComplete', function()
	DoScreenFadeOut(500)
	Wait(1000)
	CharacterSelect()
end)

RegisterCommand('relog', function()
	if Config.Relog and not LocalPlayer.state.isdead then
		TriggerServerEvent('renzu_multicharacter:relog')
		logout = true
	end
end)

RegisterNUICallback('nuicb', function(data, cb)
	if data.msg == 'showchar' then
		ShowCharacter(data.slot)
	elseif data.msg == 'chooseslot' then
		ChooseCharacter(data.slot)
		Cleanups()
		local pos = characters[chosenslot].position
		SpawnSelect(vec4(pos.x, pos.y, pos.z, pos.heading or 0.0))
	elseif data.msg == 'create' then
		if not data.info.sex then data.info.sex = 'm' end
		data.info.height = 100
		chosenslot = data.slot
		pendingSex = data.info.sex
		local model = Appearance.GetModel(data.info.sex)
		setModel(model, true)
		callback('renzu_multicharacter:createcharacter', {info = data.info, slot = data.slot})
		Cleanups()
		Appearance.SetAppearance(PlayerPedId(), nil, data.info.sex)
		New = true
		if not Config.UseDefaultIdentity then
			if not identityInFlight then
				identityInFlight = true
				TriggerEvent('renzu_multicharacter:identityRequested', data.slot)
			end
		else
			enterWorldAsNewCharacter(data.info.sex)
		end
	elseif data.msg == 'deletechar' then
		if Config.Framework == 'QBCORE' or Config.Framework == 'QBOX' then
			data.slot = characters[chosenslot].citizenid
		end
		callback('renzu_multicharacter:deletecharacter', data.slot)
		characters[chosenslot] = nil
		CharacterSelect()
		pedshots[chosenslot] = nil
	elseif data.msg == 'deleteattempt' then
		local gestures = Config.Animations['delete'][math.random(1, #Config.Animations['delete'])]
		PlayAnim(PlayerPedId(), gestures.dict, gestures.anim)
	elseif data.msg == 'spawnpreview' then
		previewSpawn(data.name, data.coord)
	elseif data.msg == 'spawnselect' then
		if spawnPromise then
			spawnPromise:resolve(data.name)
			spawnPromise = nil
		end
	end
	if cb then cb('ok') end
end)

CheckStates = function(preview)
	if not (characters[chosenslot] and characters[chosenslot].extras) then return false end
	local extra = characters[chosenslot].extras
	for name, data in pairs(extra) do
		HandleStates(name, data, preview)
		if preview and name == 'invehicle' then return true end
	end
	return false
end

RegisterStates = function(name, cb, spawnselector)
	states[name] = {spawn = spawnselector, cb = cb}
	AddStateBagChangeHandler(name, nil, function(bagName, _, value, _, _)
		Wait(0)
		if value == nil or logout then return end
		states[name].value = value
	end)
	return states[name].cb()
end
exports('RegisterStates', RegisterStates)

HandleStates = function(name, data, preview)
	if name == 'invehicle' and data and type(data) == 'table' then
		DoScreenFadeOut(0)
		local lastvehicle = callback('setplayertolastvehicle', data.net, preview)
		Wait(1000)
		DoScreenFadeIn(1000)
		if IsCamActive(cam) then
			local vehicle = NetworkGetEntityFromNetworkId(data.net)
			if not DoesEntityExist(vehicle) then return end
			local coord = GetEntityCoords(vehicle)
			SetCamParams(cam, coord.x, coord.y + 4, coord.z + 0.8, 0.0, 0.0, 0.0, 55.0, 1, 0, 0, 2)
			PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
			stateactive = true
		end
		return data
	end
end

function TryOxLib(file)
	local fcall = function()
		local content = LoadResourceFile('ox_lib', ('%s.lua'):format(file))
		local f = load(content)
		return f()
	end
	local _, ret = pcall(fcall, false)
	return ret
end

TryOxLib('init')
exports.renzu_multicharacter:RegisterStates('invehicle', function()
	if not lib then return end
	lib.onCache('vehicle', function(value)
		if not loaded then return end
		LocalPlayer.state:set('invehicle', value and {net = NetworkGetNetworkIdFromEntity(value)} or false, true)
	end)
end, false)
