local Framework = exports['710-lib']:GetFrameworkObject()
local GConfig = Framework.Config()
local QBCore = {}
if GConfig.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end
local Contracts = {}
local PZone = nil
local PZone2 = nil
local NetID = nil
local missionBlip = nil
local inZone = false
local inVin = false
local dropoffBlip = nil

local inQueue = false

local currentCops = 0


-- MISSION STARTER --

-- Sends information from server to client that it will start now

RegisterNetEvent('jl-laptop:client:MissionStarted',
    function(netID, coords, plate) -- Pretty much just resets every boolean to make sure no issues will occour.
        NetID = netID
        carCoords = coords
        AntiSpam = false
        inZone = false
        local result = Framework.TriggerServerCallback('jl-laptop:server:GetContracts')
        Contracts = result
        -- send plate number
        SendNUIMessage({
            action = "boosting/horseboosting",
            data = {
                plate = plate or "Unknown?"
            }
        })
end)

RegisterNUICallback('boosting/start', function(data, cb)
    local result = Framework.TriggerServerCallback('jl-laptop:server:CanStartBoosting', data)
    --print(result)
    if result == "success" then
        TriggerServerEvent('jl-laptop:server:StartBoosting', data.id, currentCops)
        -- data.expire
        cb({
            status = 'success',
            message = Locales.boosting.laptop.boosting.success
        })
    elseif result == "cops" then
        cb({
            status = 'error',
            message = Locales.boosting.laptop.boosting.cops
        })
    elseif result == "running" then
        cb({
            status = 'error',
            message = Locales.boosting.laptop.boosting.running
        })
    elseif result == "notfound" then
        cb({
            status = 'error',
            message = Locales.boosting.laptop.boosting.notfound
        })
    elseif result == "notenough" then
        cb({
            status = 'error',
            message = Locales.boosting.laptop.boosting.notenough
        })
    elseif result == "busy" then
        cb({
            status = 'error',
            message = Locales.boosting.laptop.boosting.busy
        })
    elseif result == "error" then
        cb({
            status = 'error',
            message = Locales.boosting.laptop.boosting.error
        })
    end
end)



-- Gets all the reps --
-- Getters for when you open the boost app --
RegisterNUICallback("boosting/getrep", function(_, cb)
    local data = {
        rep = PlayerData.metadata['carboostrep'] or 0,
        repconfig = Config.Boosting.TiersPerRep
    }
    cb(data)
end)

-- Just a netevent that retracts all the booleans and properly resets the client --
RegisterNetEvent('jl-laptop:client:finishContract', function(table)
    if PZone then PZone:destroy() PZone = nil end
    if PZone2 then PZone2:destroy() PZone2 = nil end
    NetID = nil
    if missionBlip then RemoveBlip(missionBlip) missionBlip = nil end
    if dropoffBlip then RemoveBlip(dropoffBlip) dropoffBlip = nil end
    inZone = false

    Contracts = table
    local result = Framework.TriggerServerCallback('jl-laptop:server:GetContracts')
    Contracts = result
    SendNUIMessage({ action = 'booting/delivered' })
end)




-- ** CONTRACT HANDLER ** --

-- Sends the information to client when their contracts update
RegisterNetEvent('jl-laptop:client:ContractHandler', function(table, currentdate)
    if not table then return end
    Contracts = table
    if not display then return end
    SendNUIMessage({
        action = 'receivecontracts',
        contracts = table,
        serverdate = currentdate
    })
end)

-- Handles state right when the player selects their character and location.
AddEventHandler('710-lib:PlayerLoaded', function()
    Wait(10000)
    local result = Framework.TriggerServerCallback('jl-laptop:server:GetContracts')
    Contracts = result
    --print(json.encode(Contracts))
    if Contracts and #Contracts > 0 then
        SendNUIMessage({
            action = 'receivecontracts',
            contracts = result
        })
    end
end)

RegisterNUICallback('boosting/getcontract', function(_, cb)
    local result = Framework.TriggerServerCallback('jl-laptop:server:GetContracts')
    Contracts = result
    --print(json.encode(Contracts))
    cb({
        contracts = Contracts,
    })
end)


-- Gets all the reps --
-- Getters for when you open the boost app --
RegisterNUICallback("boosting/getrep", function(_, cb)
    local boostingRep = Framework.TriggerServerCallback('jl-laptop:server:GetRep710')
    local result = Framework.TriggerServerCallback('jl-laptop:server:GetContracts')
    Contracts = result
    local data = {
        rep = boostingRep,
        repconfig = Config.Boosting.TiersPerRep
    }
    cb(data)
end)



RegisterNUICallback("boosting/expire", function(data, cb)
    --print(data["id"])
    cb("ok")
end)

