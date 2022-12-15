local Framework = exports['710-lib']:GetFrameworkObject()
local GConfig = Framework.Config()


RegisterNetEvent('jl-laptop:server:crateOpened', function(crateID)
    local source = source
    local Player = Framework.PlayerDataS(source)
    if GConfig.Framework == "qbcore" then
        if Player.HasItem('drill', 1) then
            Player.RemoveItem('drill', 1)
            crates[crateID].isOpened = true
            TriggerClientEvent('jl-laptop:client:updateCrates', -1, crates)
        else
            Player.Notify("You don't have a drill to open this crate")
        end
    else
        local ItemInfo = Player.HasItem('drill')
        if ItemInfo.count >= 1 then
            Player.RemoveItem('drill', 1)
            crates[crateID].isOpened = true
            TriggerClientEvent('jl-laptop:client:updateCrates', -1, crates)
        else
            Player.Notify("You don't have a drill to open this crate")
        end
    end
end)

Framework.RegisterServerCallback('jl-laptop:server:getCrateStatus', function(source, cb, crateNetID, crateentity)
    crates[crateNetID].isOpened = false

    local data = {
        isOpened = crates[crateNetID].isOpened,
        crateID = crates[crateNetID].id,
        crate = crateentity
    }
	cb(data)
end)

Framework.RegisterServerCallback('jl-laptop:server:getAllCrates', function(source, cb)
    cb(crates)
end)


AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.Inventory == "ox_inventory" then
            local crates = Config.DarkWeb.CrateSpawn
            for k, v in pairs(crates) do
                Framework.RegisterStash("DarkWebCrate_" .. k, "DarkWebCrate_" .. k, 25, 100000)
            end
        end
    end
end)