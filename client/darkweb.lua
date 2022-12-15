local Framework = exports['710-lib']:GetFrameworkObject()
local GConfig = Framework.Config()
local QBCore = {}
if GConfig.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end
local crates = {}
local crateBlip = nil

local function openCrate(crate)
    local crateID = NetworkGetNetworkIdFromEntity(crate)
    local data = Framework.TriggerServerCallback('jl-laptop:server:getCrateStatus', crateID, crate)
    if data.isOpened then
        openCrate(data.crate)
    else
        Framework.OpenStash("DarkWebCrate_" .. data.crateID, {maxweight = 100000, slots = 25})
    end
end

RegisterNetEvent('jl-laptop:OpenCrate', function(dataS)
    local crateID = NetworkGetNetworkIdFromEntity(dataS.entity)
    local crate = dataS.entity
    local data = Framework.TriggerServerCallback('jl-laptop:server:getCrateStatus', crateID, crate)
    if data.isOpened then
        openCrate(data.crate)
    else
        Framework.OpenStash("DarkWebCrate_" .. data.crateID, {maxweight = 100000, slots = 25})
    end
end)

RegisterNUICallback('darkweb/items', function(_, cb)
    local translated = {}
    local itemInfo = {}
    if Config.Inventory == "ox_inventory" then
        itemInfo = GetAllItemInfo()
    end
    for _, v in pairs(Config.DarkWeb.Items) do
        if Config.Inventory == "ox_inventory" then
            translated[#translated + 1] = {
                name = v.name,
                label = itemInfo[v.name].label,
                image = Config.Inventory .. "/web/images/" .. v.name..".png",
                price = v.price,
                stock = v.stock,
                category = v.category,
            }
        else
            translated[#translated + 1] = {
                name = v.name,
                label = QBCore.Shared.Items[v.name].label,
                image = Config.Inventory .. "/html/images/" .. QBCore.Shared.Items[v.name].image,
                price = v.price,
                stock = v.stock,
                category = v.category,
            }
        end
    end
    cb(translated)
end)



-- Prolly a better minigame for this and needs a drilling anim
local function breakCrate(entity)
    local Player = Framework.PlayerDataC()
    if haveItem('drill') then
        exports['ps-ui']:Thermite(function(success)
            if success then
                TriggerServerEvent('jl-laptop:server:crateOpened', NetworkGetNetworkIdFromEntity(entity))
                if crateBlip then RemoveBlip(crateBlip) end
            end
        end, 10, 3, 3) -- Time, Gridsize (5, 6, 7, 8, 9, 10), IncorrectBlocks
    else
        Player.Notify(Locales.darkweb.need_drill)
    end
end

RegisterNetEvent('jl-laptop:BreakOpenCrate', function(data)
    local entity = data.entity
    local Player = Framework.PlayerDataC()
    if haveItem('drill') then
        exports['ps-ui']:Thermite(function(success)
            if success then
                TriggerServerEvent('jl-laptop:server:crateOpened', NetworkGetNetworkIdFromEntity(entity))
                if crateBlip then RemoveBlip(crateBlip) end
            end
        end, 10, 3, 3) -- Time, Gridsize (5, 6, 7, 8, 9, 10), IncorrectBlocks
    else
        Player.Notify(Locales.darkweb.need_drill)
    end

end)

-- Creates the crates interactable for players who just joined
AddEventHandler('710-lib:PlayerLoaded', function()
    local crateInfo = Framework.TriggerServerCallback('jl-laptop:server:getAllCrates')
    crates = crateInfo

    for netID, _ in pairs(crates) do
        local obj = NetworkGetEntityFromNetworkId(netID)
        exports[GConfig.InputTarget]:AddTargetEntity(obj, {
            options = {
                {
                    label = Locales.darkweb.target.breakcrateopen,
                    icon = "fas fa-box-open",
                    action = function(entity)
                        breakCrate(entity)
                    end,
                    canInteract = function(entity)
                        local netID = NetworkGetNetworkIdFromEntity(entity)
                        if crates[netID].isOpened then return false end
                        return true
                    end,
                },
                {
                    label = Locales.darkweb.target.opencrate,
                    icon = "fas fa-box-open",
                    action = function(entity)
                        openCrate(entity)
                    end,
                    canInteract = function(entity)
                        local netID = NetworkGetNetworkIdFromEntity(entity)
                        if not crates[netID].isOpened then return false end
                        return true
                    end,
                }
            },
            distance = 2.0
        })
    end
end)

RegisterNetEvent('darkweb:client:cratedrop', function(netID)
    local obj = NetworkGetEntityFromNetworkId(netID)
    PlaceObjectOnGroundProperly(obj)

    if PZone then PZone:destroy() PZone = nil end

    if crateBlip then RemoveBlip(crateBlip) end

    local crateCoords = GetEntityCoords(obj)

    if Config.Boosting.Debug then SetNewWaypoint(crateCoords.x, crateCoords.y) end

    if Config.DarkWeb.CrateBlip then
        crateBlip = AddBlipForRadius(crateCoords.x + math.random(-100, 100), crateCoords.y + math.random(-100, 100), crateCoords.z, 250.0)
        SetBlipAlpha(crateBlip, 150)
        SetBlipHighDetail(crateBlip, true)
        SetBlipColour(crateBlip, 1)
        SetBlipAsShortRange(crateBlip, true)
    end
    if GConfig.InputTarget ~= 'ox_target' then
        exports[GConfig.InputTarget]:AddTargetEntity(obj, {
            options = {
                {
                    label = Locales.darkweb.target.breakcrateopen,
                    icon = "fas fa-box-open",
                    action = function(entity)
                        breakCrate(entity)
                    end,
                    canInteract = function(entity)
                        local netID = NetworkGetNetworkIdFromEntity(entity)
                        if crates[netID].isOpened then return false end
                        return true
                    end,
                },
                {
                    label = Locales.darkweb.target.opencrate,
                    icon = "fas fa-box-open",
                    action = function(entity)
                        openCrate(entity)
                    end,
                    canInteract = function(entity)
                        local netID = NetworkGetNetworkIdFromEntity(entity)
                        if not crates[netID].isOpened then return false end
                        return true
                    end,
                }
            },
            distance = 2.0
        })
    else
        local netId = NetworkGetNetworkIdFromEntity(obj)
        local options = {
            {
                name = 'ox:DarkwebCrate1',
                label = Locales.darkweb.target.breakcrateopen,
                icon = "fas fa-box-open",
                event = 'jl-laptop:BreakOpenCrate',
                crate = crates[netID],
                entity = obj,
                canInteract = function(entity)
                    local netID = NetworkGetNetworkIdFromEntity(entity)
                    if crates[netID].isOpened then return false end
                    return true
                end,
            },
            {
                name = 'ox:DarkwebCrate2',
                label = Locales.darkweb.target.opencrate,
                icon = "fas fa-box-open",
                event = 'jl-laptop:OpenCrate',
                crate = crates[netID],
                entity = obj,
                canInteract = function(entity)
                    local netID = NetworkGetNetworkIdFromEntity(entity)
                    if not crates[netID].isOpened then return false end
                    return true
                end,
            }
        }
        exports.ox_target:addEntity(netId, options)
    end
end)

-- Just so the client knows the info about the boxes
RegisterNetEvent('jl-laptop:client:updateCrates', function(crateInfo)
    crates = crateInfo
end)
