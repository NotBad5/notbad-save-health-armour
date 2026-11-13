-- notbad-save-health-armour
-- The server reads health and armour itself, so a client can never report its own values.

local framework = ResolveFramework()
local ESX, QBCore

-- fetched on first use, so the start order of resources does not matter
local function core()
    if framework == 'esx' and not ESX then
        ESX = exports['es_extended']:getSharedObject()
    elseif framework == 'qb' and not QBCore then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end

-- [source] = { identifier, health, armour, tracking, dirty }
-- tracking stays false until the client confirms the saved values were applied,
-- so a player who leaves while still loading never overwrites what was saved.
local active = {}

local function debug(msg, ...)
    if Config.Debug then
        print(('[%s] ' .. msg):format(GetCurrentResourceName(), ...))
    end
end

local function getIdentifier(src)
    core()
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier
    elseif framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid
    elseif framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.citizenid
    end

    if GetPlayerIdentifierByType then
        local license = GetPlayerIdentifierByType(src, 'license')
        if license then return license end
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
end

-- reads the current values from the player's ped; false if the ped is already gone
local function read(src, entry)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end

    local health, armour = GetEntityHealth(ped), GetPedArmour(ped)
    if health ~= entry.health or armour ~= entry.armour then
        entry.health, entry.armour, entry.dirty = health, armour, true
    end
    return true
end

local function write(entry)
    if not entry.dirty or not entry.health then return end
    Storage.set(entry.identifier, {
        Health = Config.SaveHealth and entry.health or nil,
        Armour = Config.SaveArmour and entry.armour or nil,
    })
    entry.dirty = false
    debug('saved %s: health %s, armour %s', entry.identifier, entry.health, entry.armour)
end

-- ---------------------------------------------------------------------------
-- Combat log reports to Discord
-- ---------------------------------------------------------------------------

local combatLog = ServerConfig and ServerConfig.CombatLog or {}
local webhookSet = type(combatLog.webhook) == 'string' and combatLog.webhook:find('^https://') ~= nil

local function reportCombatLog(src, entry, reason, switched)
    if not webhookSet or not entry.health then return end
    if switched and not combatLog.logCharacterSwitch then return end

    local dead = entry.health <= DEAD_HEALTH
    local percent = math.max(0, math.min(100, entry.health - DEAD_HEALTH))
    local low = not dead and (combatLog.lowHealth or 0) > 0 and percent < combatLog.lowHealth
    if not (dead and combatLog.logDead) and not low then return end

    local fields = {
        { name = 'Player', value = ('%s (ID %s)'):format(GetPlayerName(src) or 'unknown', src), inline = true },
        { name = 'Health', value = dead and 'Dead' or (percent .. ' %'), inline = true },
        { name = 'Armour', value = tostring(entry.armour or 0), inline = true },
        { name = 'Identifier', value = '`' .. entry.identifier .. '`', inline = false },
        { name = switched and 'What happened' or 'Disconnect reason', value = tostring(reason or 'unknown'):sub(1, 200), inline = false },
    }

    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        local c = GetEntityCoords(ped)
        fields[#fields + 1] = { name = 'Position', value = ('`%.1f, %.1f, %.1f`'):format(c.x, c.y, c.z), inline = false }
    end

    PerformHttpRequest(combatLog.webhook, function(status)
        if status and status >= 400 then
            print(('^3[%s]^7 Discord rejected the combat log message (HTTP %s). Check the webhook URL.'):format(GetCurrentResourceName(), status))
        end
    end, 'POST', json.encode({
        username = combatLog.botName or 'Combat log',
        allowed_mentions = { parse = {} },   -- a player name can never ping anyone
        embeds = { {
            title = dead and 'Left while dead' or 'Left with low health',
            color = dead and 15548997 or 16755200,
            fields = fields,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }), { ['Content-Type'] = 'application/json' })
end

-- the player left or switched character: take a last reading and save it
local function finish(src, reason, switched)
    local entry = active[src]
    if not entry then return end
    active[src] = nil

    if entry.tracking then
        read(src, entry)   -- if the ped is gone, the last check (at most CheckInterval old) is used
        write(entry)
        reportCombatLog(src, entry, reason, switched)
    end
end

RegisterNetEvent(EVT .. ':ready', function()
    local src = source
    local identifier = getIdentifier(src)
    if not identifier then return end

    local current = active[src]
    if current then
        -- already restored this session: asking again must not hand back old health
        if current.identifier == identifier then return end
        finish(src)
    end

    local entry = { identifier = identifier, tracking = false, dirty = false }
    active[src] = entry

    Storage.get(identifier, function(data)
        if active[src] ~= entry then return end   -- left or switched in the meantime
        debug('loaded %s: %s', identifier, data and json.encode(data) or 'nothing saved')
        TriggerClientEvent(EVT .. ':apply', src, data and {
            Health = Config.SaveHealth and tonumber(data.Health) or nil,
            Armour = Config.SaveArmour and tonumber(data.Armour) or nil,
        } or nil)
    end)
end)

RegisterNetEvent(EVT .. ':applied', function()
    local entry = active[source]
    if entry then entry.tracking = true end
end)

AddEventHandler('playerDropped', function(reason)
    finish(source, reason)
end)

-- character switching
AddEventHandler('esx:playerLogout', function(playerId)
    finish(tonumber(playerId) or source, 'Switched character', true)
end)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(playerId)
    finish(tonumber(playerId) or source, 'Switched character', true)
end)
AddEventHandler('qbx_core:server:playerLoggedOut', function(playerId)
    finish(tonumber(playerId) or source, 'Switched character', true)
end)

CreateThread(function()
    local sinceWrite = 0
    while true do
        Wait(Config.CheckInterval * 1000)
        sinceWrite = sinceWrite + Config.CheckInterval

        local flush = sinceWrite >= Config.WriteInterval
        if flush then sinceWrite = 0 end

        for src, entry in pairs(active) do
            if entry.tracking then
                read(src, entry)
                if flush then write(entry) end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for src, entry in pairs(active) do
        if entry.tracking then
            read(src, entry)
            write(entry)
        end
    end
end)

print(('^2[%s]^7 framework: %s, storage: %s, combat log: %s'):format(GetCurrentResourceName(), framework, Storage.name, webhookSet and 'on' or 'off'))
