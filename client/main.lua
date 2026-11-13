-- notbad-save-health-armour
-- Tells the server when the player is in the world, then applies what the server sends back.

local framework = ResolveFramework()
local asked = false

local function askServer(delay)
    if asked then return end
    asked = true
    CreateThread(function()
        Wait(delay or 0)
        asked = false
        TriggerServerEvent(EVT .. ':ready')
    end)
end

local function apply(data)
    local ped = PlayerPedId()

    if data.Health then
        if data.Health <= DEAD_HEALTH then
            if Config.DeadPlayers == 'kill' then SetEntityHealth(ped, 0) end
        else
            SetEntityHealth(ped, math.min(math.floor(data.Health), GetEntityMaxHealth(ped)))
        end
    end

    if data.Armour then
        SetPedArmour(ped, math.max(0, math.min(math.floor(data.Armour), 100)))
    end

    return ped
end

RegisterNetEvent(EVT .. ':apply', function(data)
    if type(data) == 'table' then
        local ped = apply(data)

        -- a model change (clothing, character select) gives a new ped with full health: put the values back
        local deadline = GetGameTimer() + (Config.ReapplySeconds * 1000)
        while GetGameTimer() < deadline do
            Wait(500)
            if PlayerPedId() ~= ped then
                ped = apply(data)
            end
        end
    end

    -- from now on the server keeps track of the real values
    TriggerServerEvent(EVT .. ':applied')
end)

-- ---------------------------------------------------------------------------
-- When is the player ready?
-- ---------------------------------------------------------------------------

if framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded', function()
        askServer(2000)
    end)

    -- resource restarted while the player was already in
    CreateThread(function()
        local ok, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and ESX and ESX.IsPlayerLoaded and ESX.IsPlayerLoaded() then askServer(0) end
    end)

elseif framework == 'qb' or framework == 'qbx' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        askServer(2000)
    end)

    CreateThread(function()
        if LocalPlayer.state.isLoggedIn then askServer(0) end
    end)

else
    -- standalone: wait for the first spawn, or a few seconds after the session is active
    AddEventHandler('playerSpawned', function()
        askServer(1000)
    end)

    CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
        askServer(8000)
    end)
end
