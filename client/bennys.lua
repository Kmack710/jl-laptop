local Framework = exports['710-lib']:GetFrameworkObject()
local GConfig = Framework.Config()
local QBCore = nil
if GConfig.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

RegisterNUICallback('bennys/getitems', function(_, cb)
    local translated = {}
    local itemInfo = {}
    if Config.Inventory == "ox_inventory" then
        itemInfo = GetAllItemInfo()
    end
    for _, v in pairs(Config.Bennys.Items) do
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
    --print(json.encode(translated))
    cb(translated)
end)



local function openStash()
    local Player = Framework.PlayerDataC()
    local CID = Player.Pid
    if GConfig.Framework == 'esx' then 
        --Framework.OpenStash("BennyShop", {maxweight = 100000, slots = 25})
        Framework.OpenStash({id = "BennyShop", owner = CID}, {maxweight = 100000, slots = 25})
    else
        Framework.OpenStash("BennyShop"..CID, {maxweight = 100000, slots = 25})
    end
end

RegisterNetEvent('jl-laptop:OpenBennysShopStash', function()
    local Player = Framework.PlayerDataC()
    local CID = Player.Pid
    if GConfig.Framework == 'esx' then 
        Framework.OpenStash({id = "BennyShop", owner = CID}, {maxweight = 100000, slots = 25})
    else
        Framework.OpenStash("BennyShop"..CID, {maxweight = 100000, slots = 25})
    end
end)

exports('openStash', openStash)

local ped = nil
local blip = nil
CreateThread(function()

    local v = Config.Bennys.Location

    RequestModel(v.ped)

    while not HasModelLoaded(v.ped) do
        Wait(0)
    end

    ped = CreatePed(0, joaat(v.ped), v.coords.x, v.coords.y, v.coords.z - 1, v.coords.w, false, false)
    TaskStartScenarioInPlace(ped, v.scenario, 0, true)
    PlaceObjectOnGroundProperly(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if GConfig.InputTarget == 'ox_target' then
        exports.ox_target:addBoxZone({
            coords = vec3(v.coords.x, v.coords.y, v.coords.z),
            size = vec3(1, 1, 2),
            rotation = v.coords.w,
            debug = false,
            options = {
                {
                    name = 'ox:bennywarehouseped',
                    label = Locales.bennys.warehouse,
                    icon = "fa-solid fa-warehouse",
                    event = 'jl-laptop:OpenBennysShopStash'
                }
            }
        })
    else
            exports[GConfig.InputTarget]:AddTargetEntity(ped, {
            options = {
                {
                    label = Locales.bennys.warehouse,
                    icon = "fa-solid fa-warehouse",
                    action = function()
                        openStash()
                    end,
                }
            },
            distance = 2.0
        })
    end



    blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
    SetBlipSprite(blip, v.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, v.colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(v.text)
    EndTextCommandSetBlipName(blip)
end)
