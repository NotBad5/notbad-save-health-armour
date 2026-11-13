Config = {}

-- 'auto' picks ESX, Qbox or QBCore if one is running, otherwise standalone.
-- You can also force one: 'esx', 'qbx', 'qb' or 'standalone'.
-- With a framework, health and armour are saved per character.
Config.Framework = 'auto'

-- Where the values are kept.
-- 'kvp'     : built into FiveM, no database and no setup
-- 'oxmysql' : MySQL table `notbad_health_armour`, created automatically
Config.Storage = 'kvp'

Config.SaveHealth = true
Config.SaveArmour = true

-- What happens to a player who left while dead:
-- 'skip' : their health is left alone when they return (use this with an ambulance job)
-- 'kill' : they return dead, so leaving cannot be used to escape death
Config.DeadPlayers = 'skip'

-- Seconds between health checks on the server, and between writes to storage.
Config.CheckInterval = 10
Config.WriteInterval = 60

-- After joining, clothing and character scripts often swap the player model, which resets
-- health to full. For this many seconds the saved values are put back if that happens.
Config.ReapplySeconds = 10

-- Print what the script is doing to the server console.
Config.Debug = false
