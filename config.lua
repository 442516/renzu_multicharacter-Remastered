Config = {}

-------------------------------------------------------------------
-- LANGUAGE
-- Available: en, zh-CN, zh-TW, ja, fr, es, pt-BR, de, ru, ko, it, pl, tr, ar, nl, id, vi, th, hi, uk
-------------------------------------------------------------------
Config.Locale = 'en'

-------------------------------------------------------------------
-- FRAMEWORK
-- Available: auto, QBCORE, QBOX, ESX
-------------------------------------------------------------------
Config.Framework = 'auto'

if Config.Framework == 'auto' then
	if GetResourceState('qbx_core') == 'started' then
		Config.Framework = 'QBOX'
	elseif GetResourceState('qb-core') == 'started' then
		Config.Framework = 'QBCORE'
	elseif GetResourceState('es_extended') == 'started' then
		Config.Framework = 'ESX'
	else
		Config.Framework = 'NONE'
	end
end

if Config.Framework == 'NONE' then
	warn('[renzu_multicharacter] No supported framework found.')
end

-------------------------------------------------------------------
-- APPEARANCE
-- Available: auto, rcore_clothing, illenium-appearance,
-- fivem-appearance, qb-clothing, esx_skin, skinchanger
-------------------------------------------------------------------
Config.Appearance = 'auto'

local appearancePriority = {
	'rcore_clothing',
	'illenium-appearance',
	'fivem-appearance',
	'qb-clothing',
	'esx_skin',
	'skinchanger'
}

if Config.Appearance == 'auto' then
	local found = {}

	for _, name in ipairs(appearancePriority) do
		local state = GetResourceState(name)

		if state == 'started' or state == 'starting' then
			found[#found + 1] = name
		end
	end

	if #found > 0 then
		Config.Appearance = found[1]

		if #found > 1 then
			warn('[renzu_multicharacter] Multiple appearance resources found: ' .. table.concat(found, ', ') .. '. Using "' .. Config.Appearance .. '".')
		end
	else
		Config.Appearance = 'NONE'
	end
end

if Config.Appearance == 'NONE' then
	warn('[renzu_multicharacter] No supported appearance system found.')
end

-- rcore_clothing handles its own character appearance data.
-- Skin saving/loading is handled by the appearance bridge.

-------------------------------------------------------------------
-- SPAWN SYSTEM
-- Available: renzu_multicharacter, renzu_spawn, qb-spawn, qbx_spawn, none
-------------------------------------------------------------------
Config.SpawnSystem = 'renzu_multicharacter'

-- Default spawn for new characters.
Config.NewCharacterSpawn = vector4(-1037.75, -2737.61, 20.17, 328.72)

-- Applies Config.NewCharacterSpawn to new characters even when using an
-- external spawn system (qb-spawn, qbx_spawn, renzu_spawn). Set to false
-- to let the external spawn system handle new characters too.
Config.UseNewCharacterSpawn = true

-------------------------------------------------------------------
-- IDENTITY / REGISTRATION
-- Set to false if another resource handles character registration.
-------------------------------------------------------------------
Config.UseDefaultIdentity = true

-------------------------------------------------------------------
-- APARTMENTS
-- Available: auto, qb-apartments, none
-------------------------------------------------------------------
Config.ApartmentSystem = 'auto'

if Config.ApartmentSystem == 'auto' then
	if GetResourceState('qb-apartments') == 'started' then
		Config.ApartmentSystem = 'qb-apartments'
	else
		Config.ApartmentSystem = 'none'
	end
end

-------------------------------------------------------------------
-- CHARACTER SLOTS
-------------------------------------------------------------------
Config.CanDelete = true
Config.Slots = 3
Config.commandslot = 'updatecharslots'
Config.Prefix = 'char' -- ESX only
Config.Relog = true -- controls the /relog command, set false to disable it

-------------------------------------------------------------------
-- CHARACTER SELECT
-------------------------------------------------------------------
Config.PreviewSpawn = vector3(-1037.59, -2736.90, 20.16)

Config.cam = true
Config.ShowLogo = false
Config.PreviewAnimation = true

Config.CameraIntro = {
	[1] = {
		coord = vec3(-378.5999755859, 504.25170898438, 434.6608581543),
		rot = vec3(0.00, 0.00, 151.00)
	},
	[2] = {
		coord = vec3(169.95536804199, -964.54614257813, 64.203475952148),
		rot = vec3(360.00, 0.00, -30.00)
	},
	[3] = {
		coord = vec3(-407.0290222168, 1312.7703857422, 390.61987304),
		rot = vec3(360.00, 0.00, 180.00)
	},
	[4] = {
		coord = vec3(-1040.8935546875, -937.53588867188, 114.1599731445),
		rot = vec3(360.00, 0.00, 169.00)
	},
	[5] = {
		coord = vec3(907.22625732422, 108.29551696777, 137.6200256347),
		rot = vec3(320.00, 5.00, 180.00)
	},
}

-------------------------------------------------------------------
-- INTRO MUSIC
-- Uses a local audio file from web/sound/.
-------------------------------------------------------------------
Config.bgmusic = true
Config.IntroSound = 'sound/bgmusic.mp3'
Config.IntroVolume = 0.3

-------------------------------------------------------------------
-- ANIMATIONS
-------------------------------------------------------------------
Config.Animations = {
	['choose'] = {
		[1] = {dict = 'anim@mp_player_intcelebrationfemale@blow_kiss', anim = 'blow_kiss'},
		[2] = {dict = 'anim@arena@celeb@podium@no_prop@', anim = 'regal_c_1st'},
		[3] = {dict = 'anim@mp_player_intcelebrationfemale@shadow_boxing', anim = 'shadow_boxing'},
		[4] = {dict = 'mini@triathlon', anim = 'want_some_of_this'},
		[5] = {dict = 'random@street_race', anim = 'grid_girl_race_start'},
		[6] = {dict = 'amb@world_human_hang_out_street@male_c@idle_a', anim = 'idle_b'},
		[7] = {dict = 'anim@arena@celeb@flat@solo@no_props@', anim = 'flip_a_player_a'},
		[8] = {dict = 'timetable@reunited@ig_2', anim = 'jimmy_getknocked'},
		[9] = {dict = 'anim@mp_player_intcelebrationmale@karate_chops', anim = 'karate_chops'},
		[10] = {dict = 'anim@mp_player_intupperpeace', anim = 'idle_a_fp'},
	},

	['delete'] = {
		[1] = {dict = 'anim@mp_player_intcelebrationmale@cut_throat', anim = 'cut_throat'},
		[2] = {dict = 'gestures@m@standing@casual', anim = 'gesture_damn'},
		[3] = {dict = 'anim@mp_player_intupperface_palm', anim = 'idle_a'},
		[4] = {dict = 'anim@mp_player_intupperfinger', anim = 'idle_a_fp'},
	}
}

-------------------------------------------------------------------
-- PLAYER STATUS
-------------------------------------------------------------------
Config.Status = {
	['invehicle'] = '<i class="fas fa-car-side"></i>',
	['isdead'] = '<i class="fas fa-skull-crossbones"></i>',
	['premium'] = '<i class="fas fa-star"></i>',
	['injail'] = '<i class="fas fa-drum-steelpan"></i>',
	['iscuffed'] = '<i class="fab fa-fedora"></i>',
	['incommunityservice'] = '<i class="fas fa-broom"></i>',
	['isbanned'] = '<i class="fas fa-user-lock"></i>',
	['inbed'] = '<i class="fas fa-bed"></i>',
	['inhouse'] = '<i class="fas fa-house-user"></i>',
	['inapartment'] = '<i class="fas fa-building"></i>',
	['inmlo'] = '<i class="fas fa-home"></i>',
	['admin'] = '<i class="fas fa-crown"></i>',
}

-------------------------------------------------------------------
-- STARTER ITEMS
-- Framework starter items take priority when configured.
-- These are only used as a fallback.
-------------------------------------------------------------------
Config.FallbackStarterItems = {
	-- QBCore / QBox
	{item = 'water_bottle', amount = 2},
	{item = 'sandwich', amount = 2},
	{item = 'phone', amount = 1},
	{item = 'id_card', amount = 1},
	{item = 'driver_license', amount = 1},
}

Config.ESXStarterItem = {
	{item = 'bread', amount = 5},
	{item = 'water', amount = 5},
	{item = 'phone', amount = 1},
}

Config.ESXStarterMoney = {
	{account = 'money', amount = 500},
	{account = 'bank', amount = 5000},
}
