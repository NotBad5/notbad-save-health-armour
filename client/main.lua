if Config.ESX then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(playerData)
        TriggerServerEvent("notbad-save-health-armour:loadData")
    end)
end

if Config.QBCORE then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Citizen.Wait(2000)
        TriggerServerEvent("notbad-save-health-armour:loadData")
    end)
end

if Config.Standalone then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local playerPed = PlayerPedId()
            if playerPed and playerPed ~= -1 then
                if NetworkIsPlayerActive(PlayerId()) then
                    Citizen.Wait(5000)
                    TriggerServerEvent("notbad-save-health-armour:loadData")
                    break
                end
            end
        end
    end)
end

RegisterNetEvent('notbad-save-health-armour:setData')
AddEventHandler('notbad-save-health-armour:setData', function(data)
    local playerPed = GetPlayerPed(-1)
    local health = SetEntityHealth(playerPed, data.Health)
    local armour = SetPedArmour(playerPed, data.Armour)
end)