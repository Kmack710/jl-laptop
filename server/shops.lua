local Framework = exports['710-lib']:GetFrameworkObject()
local GConfig = Framework.Config()
local QBCore = {}
if GConfig.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end
local crateCount = 0
crates = {} -- Table which stores crate netIDs with its contents ( shop items )

local function AddItems(stash, Items, PID)
    if GConfig.Framework == "qbcore" then
        local items = {}
        for k, v in pairs(Items) do
            local itemInfo = QBCore.Shared.Items[k:lower()]
            items[#items + 1] = {
                name = itemInfo["name"],
                amount = tonumber(v),
                info = {}, --Fixed The Weapons Issue
                label = itemInfo["label"],
                description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
                weight = itemInfo["weight"],
                type = itemInfo["type"],
                unique = itemInfo["unique"],
                useable = itemInfo["useable"],
                image = itemInfo["image"],
                slot = #items + 1,
            }
        end
        MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items'
            , {
            ['stash'] = stash,
            ['items'] = json.encode(items)
        })
    else
        for k,v in pairs(Items) do
            if stash == "BennyShop" then
                exports.ox_inventory:GetInventory(stash, PID)
                exports.ox_inventory:AddItem(stash..":"..PID, k, v)
            else
                exports.ox_inventory:GetInventory(stash, false)
                exports.ox_inventory:AddItem(stash, k, v)
            end
        end
    end
end

local function HasStashItems(stashId)
    local stashItems = nil
    if GConfig.Framework == "qbcore" then
        local result = MySQL.Sync.fetchScalar('SELECT items FROM stashitems WHERE stash = ?', { stashId })
        if not result then return end
        stashItems = json.decode(result)
        if not stashItems then return end
    else 
        local result = exports.ox_inventory:GetInventoryItems(stashId, false)
        if not result then return end
        stashItems = json.decode(result)
        if not stashItems then return end
    end
    return true, #stashItems
end

local function GenerateCrateSpawn()
    local count = 0
    for i = 1, #Config.DarkWeb.CrateSpawn do
        if Config.DarkWeb.CrateSpawn[i].isbusy then
            count += 1
        end
    end
    if count >= #Config.DarkWeb.CrateSpawn then
        return false
    end
    local config = Config.DarkWeb.CrateSpawn[math.random(#Config.DarkWeb.CrateSpawn)]
    if config.isbusy then
        return GenerateCrateSpawn()
    end

    return config
end

local function SetCrateCoordsState(coords)
    for i = 1, #Config.DarkWeb.CrateSpawn do
        if Config.DarkWeb.CrateSpawn[i].coords == coords then
            Config.DarkWeb.CrateSpawn[i].isbusy = false
            break
        end
    end
end

local function boxDeletionTimer(netID)
    Wait(60 * 1000 * 60) -- 1 hour ( i think )
    DeleteEntity(NetworkGetEntityFromNetworkId(netID))
    SetCrateCoordsState(crates[netID]['coords'])
    crates[netID] = nil
end



local function createCrate(items, coords)
    local crateObj = CreateObject(`prop_lev_crate_01`, coords.x, coords.y, coords.z - 1.0, true, false)
    while not DoesEntityExist(crateObj) do
        Wait(50)
    end
    if DoesEntityExist(crateObj) then
        local netID = NetworkGetNetworkIdFromEntity(crateObj)
        TriggerClientEvent('darkweb:client:cratedrop', -1, netID)
        AddItems("DarkWebCrate_" .. crateCount + 1, items)
        crates[netID] = {
            ['id'] = crateCount + 1,
            ['isOpened'] = false,
            ['coords'] = coords
        }
        TriggerClientEvent('jl-laptop:client:updateCrates', -1, crates)
        boxDeletionTimer(netID)
    end
end

Framework.RegisterServerCallback('jl-laptop:server:checkout', function(source, cb, data)
    local src = source
    local appLabel = 'Bennys'
    if data.app == 'darkweb' then
        appLabel = 'DarkWeb'
    end
    local Player = Framework.PlayerDataS(src)
    local CID = Player.Pid
    local darkwebCrateSpawn = GenerateCrateSpawn()
    if not HasAppAccess(src, data['app']) then return cb("full") end
    local Saved = data['cart']
    local Shop = {
        totalBank = 0,
        totalGNE = 0,
        totalCrypto = 0,
        items = {}
    }
    if Saved then
        for _, v in pairs(Saved) do
            Shop.items[Config[appLabel].Items[v.name].name] = v.quantity
            if Config[appLabel].Items[v.name].type == "bank" then
                Shop.totalBank = Shop.totalBank + (Config[appLabel].Items[v.name].price * v.quantity)
            elseif Config[appLabel].Items[v.name].type == "crypto" then
                Shop.totalCrypto = Shop.totalCrypto + (Config[appLabel].Items[v.name].price * v.quantity)
            else
                Shop.totalGNE = Shop.totalGNE + (Config[appLabel].Items[v.name].price * v.quantity)
            end
        end
        local hasItem, amount = HasStashItems(appLabel .. "Shop_" .. Player.Pid)
        if hasItem and amount > 0 then return cb("full") end
        local checks = 0
        local bank = false
        local crypto = false
        if Shop.totalBank > 0 then
            checks = checks + 1
            if Player.Bank >= Shop.totalBank then
                checks = checks - 1
                bank = true
            else
                return cb("bank")
            end
        end

        if Shop.totalCrypto > 0 then
            checks = checks + 1
            if Player.CryptoBalance('GNE') >= Shop.totalCrypto then
                checks = checks - 1
                crypto = true
            else
                return cb("crypto")
            end
        end

        if data['app'] == "darkweb" then
            if not darkwebCrateSpawn then
                return cb("spaces")
            else
                darkwebCrateSpawn.isbusy = true
                --print(json.encode(Config.DarkWeb.CrateSpawn))
            end
        end

        if checks == 0 then
            if bank then Player.RemoveBankMoney(Shop.totalBank) end

            if crypto then Player.RemoveCrypto("GNE", Shop.totalCrypto) end

            if data['app'] == 'darkweb' then
                cb("done")
                if darkwebCrateSpawn then
                    createCrate(Shop.items, darkwebCrateSpawn.coords)
                end
            else
                if GConfig.Framework == 'qbcore' then
                    AddItems("BennyShop" .. Player.Pid, Shop.items)
                else
                    AddItems("BennyShop", Shop.items, Player.Pid)
                end
                cb("done")
            end

        end
    end
end)

-- For dev environment
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for box, _ in pairs(crates) do
            DeleteEntity(NetworkGetEntityFromNetworkId(box))
        end
    end
end)
