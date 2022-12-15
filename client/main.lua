local Framework = exports['710-lib']:GetFrameworkObject()
local GConfig = Framework.Config()
local QBCore = {}
if GConfig.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end
local onDuty = false
local apps = {}
local fullyLoaded = false




display = false
-- **  LOCALIZED FUNCTIONS WE USE ONLY IN THIS FILE

-- Globalized shits
--PlayerData = QBCore.Functions.GetPlayerData()

local function hadApp(app)
    if not app or not apps then return end

    for k, v in pairs(apps) do
        if v.name == app then
            return true
        end
    end
    return false
end

-- A function which returns the applications that the player should have access to.
local Looping = false -- Makes it so it dosnt get spammed
local function GetPlayerAppPerms()
    local Player = Framework.PlayerDataC()
    if Looping then return end
    Looping = true
    if not Player then return end
    local gangInfo = nil
    if GConfig.Framework == "qbcore" then
        gangInfo = Player.Gang
    else
        gangInfo = {
            name = "none" --- add esx gang system stuff here if you want.
        }
    end
    local playerJob, playerGang = Player.Job.name, gangInfo.name
    local tempApps = {}
    for _, app in pairs(Config.Apps) do
        local converted = {
            name = app.app,
            icon = app.icon,
            text = app.name,
            color = app.color,
            background = app.background,
            useimage = app.useimage
        }

        if app.default then
            tempApps[#tempApps + 1] = converted
            goto skip
        end


        if playerJob and playerGang then
            local searches = 0
            if (#app.job > #app.gang and #app.job > #app.bannedJobs) then
                searches = #app.job
            elseif (#app.gang > #app.bannedJobs) then
                searches = #app.gang
            else
                searches = #app.bannedJobs
            end

            local count = #app.item
            if count == 0 then count = 1 end
            for i = 1, count do
                if haveItem(app.item[i]) or not app.item[i] then
                    if searches > 0 then
                        for k = 1, searches do
                            if app.bannedJobs[k] == playerJob then
                                if hadApp(app.app) then
                                    TriggerServerEvent('jl-laptop:server:LostAccess', app.app)
                                end
                                goto skip
                            elseif (app.job[k] and app.job[k] == playerJob) or
                                (app.gang[k] and app.gang[k] == playerGang) then
                                tempApps[#tempApps + 1] = converted
                                goto skip
                            elseif (not app.job[k] and not app.gang[k]) then
                                tempApps[#tempApps + 1] = converted
                                goto skip
                            else
                                if hadApp(app.app) then
                                    TriggerServerEvent('jl-laptop:server:LostAccess', app.app)
                                end
                                goto skip
                            end
                        end
                    else
                        tempApps[#tempApps + 1] = converted
                        goto skip
                    end
                else
                    if hadApp(app.app) then
                        TriggerServerEvent('jl-laptop:server:LostAccess', app.app)
                        goto skip
                    end
                end
            end
        end
        ::skip::
    end

    apps = tempApps
    Looping = false
end

---- Animation for opening the laptop ----
local function Animation()

    local tabletDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
    local tabletAnim = "base"
    local tabletProp = 'prop_cs_tablet'
    local tabletBone = 60309
    local tabletOffset = vector3(0.03, 0.002, -0.0)
    local tabletRot = vector3(10.0, 160.0, 0.0)

    if not display then return end
    -- Animation
    if not HasAnimDictLoaded(tabletDict) then
        RequestAnimDict(tabletDict)
        while not HasAnimDictLoaded(tabletDict) do Wait(100) end
    end

    -- Model
    if not HasModelLoaded(tabletProp) then
        RequestModel(tabletProp)
        while not HasModelLoaded(tabletProp) do Wait(100) end
    end

    local plyPed = PlayerPedId()

    local tabletObj = CreateObject(tabletProp, 0.0, 0.0, 0.0, true, true, false)

    local tabletBoneIndex = GetPedBoneIndex(plyPed, tabletBone)

    AttachEntityToEntity(tabletObj, plyPed, tabletBoneIndex, tabletOffset.x, tabletOffset.y, tabletOffset.z, tabletRot.x
        , tabletRot.y, tabletRot.z, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(tabletProp)

    CreateThread(function()
        while display do
            Wait(0)
            if not IsEntityPlayingAnim(plyPed, tabletDict, tabletAnim, 3) then
                TaskPlayAnim(plyPed, tabletDict, tabletAnim, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
            end
        end
        ClearPedSecondaryTask(plyPed)
        Wait(250)
        DetachEntity(tabletObj, true, false)
        DeleteEntity(tabletObj)
    end)
end

---- ** Globalized Varaibles if we need them other parts of the client ** ----
CurrentCops = 0


local function SetDisplay(bool)
    local count = 1
    while not fullyLoaded do
        Wait(500)
        count += 1
        if count >= 10 then
            error("The UI is not ready, or it's not build yet")
            break
        end
    end
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = "toggle",
        status = bool,
    })

    Animation()
end

---- ** Globalized functions if we need them other parts of the client ** ----

-- A generic function that checks if a player has a item client side, good for faster queries for non damaging events
function haveItem(item) -- Trigger this like if haveItem("bread") then whatever end
    if not item then return false end
    local hasItem = Framework.TriggerServerCallback('jl-laptop:server:haveItem', item)
    return hasItem
end

function isPolice()
    local Player = Framework.PlayerDataC()
    local job = Player.Job.name
    for i = 1, #Config.PoliceJobs do
        if job == Config.PoliceJobs[i] then -- and onDuty didnt add this cuz testing
            return true
        end
    end

    return false
end

RegisterNetEvent('jl-laptop:client:openlaptop', function()
    if haveItem(Config.LaptopDevice) then
        SetDisplay(true)
    end
end)

RegisterNetEvent('jl-laptop:client:CustomNotification', function(text, icon, color, iconbg, length)
    if haveItem(Config.LaptopDevice) then
        SendNUIMessage({
            action = "custom-notif",
            data = {
                text = text,
                icon = icon,
                color = color,
                background = iconbg,
                length = length
            }
        })
    end
end)

RegisterNUICallback('close', function(_, cb)
    SetDisplay(false)
    cb("ok")
end)

RegisterNUICallback('loadapps', function(data, cb)

end)

RegisterNUICallback("loaded", function(_, cb)
    fullyLoaded = true
    --print("LOADED")
    cb(true)
end)

-- NUI Callback
RegisterNUICallback('getapp', function(_, cb)
    if #apps == 0 then GetPlayerAppPerms() end
    return cb(apps)
end)

-- Handles state if resource is restarted live.
--[[AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        if LocalPlayer.state.isLoggedIn then
            PlayerData = QBCore.Functions.GetPlayerData()
        end
    end
end)]]

function CalculateTimeToDisplay()
    local hour = GetClockHours()
    local minute = GetClockMinutes()

    local data = {}

    data.hour = hour
    data.minute = minute

    return data
end

CreateThread(function()
    while true do
        if display then
            SendNUIMessage({
                action = "time",
                time = CalculateTimeToDisplay()
            })
        end
        Wait(1000)
    end
end)

-- Used for both bennys app and darkweb app
RegisterNUICallback('laptop/checkout', function(data, cb)
    local newData = {
        cart = data['cart'],
        app = data['app']
    }
    local result = Framework.TriggerServerCallback('jl-laptop:server:checkout', newData)
    if result == "bank" then
        cb({
            status = 'error',
            message = Locales.main.checkout.bank
        })
    elseif result == "full" then
        cb({
            status = 'error',
            message = Locales.main.checkout.full
        })
    elseif result == "crypto" then
        cb({
            status = 'error',
            message = Locales.main.checkout.crypto
        })
    elseif result == "spaces" then
        cb({
            status = "error",
            message = Locales.main.checkout.spaces
        })
    elseif result == "done" then
        if newData.app == "darkweb" then
            cb({
                status = 'success',
                message = Locales.main.checkout.done_darkweb
            })
        else
            cb({
                status = 'success',
                message = Locales.main.checkout.done_else
            })
        end

    end
end)


RegisterNUICallback('setting/save', function(data, cb)
    -- prevents spamming metadata and server side settings
    --if data["setting"].darkfont == PlayerData.metadata['laptop'].darkfont and
        --data["setting"].background == PlayerData.metadata['laptop'].background then return end
    cb("ok")
    TriggerServerEvent("jl-laptop:server:settings:set", data["setting"])
end)

RegisterNUICallback("setting/get", function(_, cb)
    cb({
        status = false,
        data = {}
    })

end)


AddEventHandler('710-lib:PlayerLoaded', function()
    CreateThread(function()
        Wait(5000)
        local Player = Framework.PlayerDataC()
        local CID = Player.Pid
        if Config.Inventory == 'ox_inventory' then
            TriggerServerEvent('jl-laptop:server:createStashes', CID)
        end
    end)
end)



-- Everytime a cop goes on or off duty the cop count is updated.
RegisterNetEvent('police:SetCopCount', function(amount)
    CurrentCops = amount
end)

--[[RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
end)]]


function GetAllItemInfo()
    local items = {}
    for item, data in pairs(exports.ox_inventory:Items()) do
        items[item] = {
            label = data.label,
            description = data.description,
        }
    end
    return items
end