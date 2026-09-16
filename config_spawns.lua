--[[
    renzu_multicharacter - Spawn points
    Spawn points used by the character spawn selector.
    New characters use Config.NewCharacterSpawn from config.lua.
]]

-------------------------------------------------------------------
-- SPAWN SELECTOR
-------------------------------------------------------------------
-- existing_only = Show the spawn selector for existing characters only.
-- always        = Show the spawn selector for all characters.
-- never         = Skip the spawn selector and use the last known position.
--
-- New characters use Config.NewCharacterSpawn when using existing_only.
Config.SpawnSelectorMode = 'existing_only'

-- Enable or disable the spawn selector.
Config.SpawnSelector = true

-------------------------------------------------------------------
-- SPAWN POINTS
-------------------------------------------------------------------
-- name  = Image name in web/images/<name>.png
-- label = Name shown in the spawn selector
-- coord = Spawn position and heading (vector4)
-- info  = Description shown in the spawn selector
-------------------------------------------------------------------
Config.Spawns = {
    {name = 'pillbox', label = 'Pillbox Hospital', coord = vector4(246.86, -567.63, 43.28, 242.27), info = 'Pillbox Hill borders Strawberry and Chamberlain Hills to the south.'},
    {name = 'mrpd', label = 'MRPD Police Station', coord = vector4(411.63, -966.19, 29.47, 226.55), info = 'A modern three-story building, demarcated by Sinner Street and Vespucci Boulevard.'},
    {name = 'bennys', label = "Benny's Garage", coord = vector4(-184.34, -1295.03, 31.3, 127.36), info = "Benny's Original Motor Works, home of specialized car customization."},
    {name = 'legion', label = 'Legion Square', coord = vector4(223.5, -867.02, 30.49, 11.52), info = 'Legion Square, located in a commercial district.'},
    {name = 'jobcenter', label = 'Job Center', coord = vector4(-257.46, -981.22, 31.22, 26.14), info = 'A place to find your dream job.'},
    {name = 'cityhall', label = 'City Hall', coord = vector4(-537.59, -217.2, 37.65, 20.88), info = 'The Mayor\'s office and various local government agencies.'},
    {name = 'paleto', label = 'Paleto Garage', coord = vector4(126.39, 6625.41, 31.79, 232.79), info = 'Paleto Bay, on the lush northern coast of Blaine County.'},
    {name = 'sandyshore', label = 'Sandy Airstrip', coord = vector4(1747.18, 3274.98, 41.12, 65.92), info = 'A private airfield southwest of Sandy Shores.'},
}