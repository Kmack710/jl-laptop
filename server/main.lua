local QBCore = {}
local Framework = exports['710-lib']:GetFrameworkObject()
local GConfig = Framework.Config()

if GConfig.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

Framework.CreateUseableItem(Config.LaptopDevice, function(source)
    local source = source
    local Player = Framework.PlayerDataS(source)
    if GConfig.Framework == 'qbcore' then
        if Player.HasItem(Config.LaptopDevice, 1) then
            TriggerClientEvent('jl-laptop:client:openlaptop', source)
        end
    else
        local ItemInfo = Player.HasItem(Config.LaptopDevice)
        if ItemInfo.count >= 1 then
            TriggerClientEvent('jl-laptop:client:openlaptop', source)
        end
    end
end)

local function haveItem(source, item)
    local source = source
    local Player = Framework.PlayerDataS(source)
    if GConfig.Framework == 'qbcore' then
        if Player.HasItem(item, 1) then
            return true
        else
            return false
        end
    else
        local ItemInfo = Player.HasItem(item)
        if ItemInfo.count >= 1 then
            return true
        else
            return false
        end
    end
end

function HasAppAccess(source, app)
    local source = source
    local Player = Framework.PlayerDataS(source)
    if not app or not source then return false end

    local v = Config.Apps[app]

    if not v then return false end

    if not haveItem(source, Config.LaptopDevice) then return false end

    if v.default then return true end
    local gangInfo = nil
    if GConfig.Framework == 'qbcore' then
        gangInfo = Player.Gang
    else
        gangInfo = {
            name = "none"
        }
    end

    local playerJob, playerGang = Player.Job.name, gangInfo.name
    local searches = 0
    if (#v.job > #v.gang and #v.job > #v.bannedJobs) then
        searches = #v.job
    elseif (#v.gang > #v.bannedJobs) then
        searches = #v.gang
    else
        searches = #v.bannedJobs
    end
    local count = #v.item
    if count == 0 then count = 1 end
    for i = 1, count do
        if not v.item[i] or haveItem(source, v.item[i]) then
            if searches > 0 then
                for k = 1, searches do
                    if v.bannedJobs[k] == playerJob then
                        return false
                    elseif (v.job[k] and v.job[k] == playerJob) or (v.gang[k] and v.gang[k] == playerGang) then
                        return true
                    elseif (not v.job[k] and not v.gang[k]) then
                        return true
                    else
                        return false
                    end
                end
            else
                return true
            end
        else
            return false
        end
    end
end

RegisterNetEvent('jl-laptop:server:LostAccess', function(app)
    local src = source
    if app == "boosting" then
        TriggerEvent("jl-laptop:server:QuitQueue", src)
    end
end)


RegisterNetEvent('jl-laptop:server:settings:set', function(setting)
    local src = source
    if not setting then return end
    local Player = Framework.PlayerDataS(src)

    if not Player then return end

    if not HasAppAccess(src, "setting") then return end
    --Player.Functions.SetMetaData("laptop", setting)
end)

RegisterNetEvent('jl-laptop:server:RemoveItem', function(item)
    local src = source
    local Player = Framework.PlayerDataS(src)
    if Player and item then
        --TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item], "remove")
        Player.RemoveItem(item, 1)
    end
end)



-- TriggerServerEvent('jl-laptop:server:createStashes', CID)

RegisterNetEvent('jl-laptop:server:createStashes', function(CID)
    local source = source
    local Player = Framework.PlayerDataS(source)
    local Pid = Player.Pid
    if CID == Pid then
        local stash = {
            id = "BennyShop",
            label = "BennyShop",
            slots = 25,
            weight = 100000,
            owner = Pid,
        }
        --print('Registered Stash JL LAPTOP')
        --print(json.encode(stash))
        Framework.RegisterStash(stash.id, stash.label, stash.slots, stash.weight, stash.owner)
    end
end)

Framework.RegisterServerCallback('jl-laptop:server:haveItem', function(source, cb, item)
    local source = source
    local Player = Framework.PlayerDataS(source)
    if GConfig.Framework == "qbcore" then
        if Player.HasItem(item, 1) then
            cb(true)
        else
            cb(false)
        end
    else
        local hasItem = Player.HasItem(item)
        if hasItem.count >= 1 then
            cb(true)
        else
            cb(false)
        end
    end
end)