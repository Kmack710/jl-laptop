local Framework = exports['710-lib']:GetFrameworkObject()
local GConfig = Framework.Config()
local QBCore = nil
if GConfig.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

local currentRuns = {}
local currentContracts = {}
local StringCharset = {}
local NumberCharset = {}

for i = 48, 57 do NumberCharset[#NumberCharset + 1] = string.char(i) end
for i = 65, 90 do StringCharset[#StringCharset + 1] = string.char(i) end
for i = 97, 122 do StringCharset[#StringCharset + 1] = string.char(i) end

function RandomStr(length)
    if length <= 0 then return '' end
    return RandomStr(length - 1) .. StringCharset[math.random(1, #StringCharset)]
end

function RandomInt(length)
    if length <= 0 then return '' end
    return RandomInt(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
end

--- Cool down on accepting boost
local boostCD = {}
local function StartBoostCooldown(source)
    CreateThread(function()
        Wait(5 * 60000)
        boostCD[source] = false
        TriggerEvent('jl-laptop:server:finishBoost', source)
    end)

end

Framework.RegisterServerCallback('jl-laptop:server:CanStartBoosting', function(source, cb, data)
    local source = source
    local Player = Framework.PlayerDataS(source)
   -- print('--------------------------------------------------------------------------')
    --print(json.encode(data))
    if boostCD[source] == nil then boostCD[source] = false end
    if not Player then return cb("error") end
    local level = exports['710-carBoosting']:GetBoostingLevel(source)
    if not boostCD[source] then
        boostCD[source] = true
        local preData = currentContracts[level][data.id].original
        --print(json.encode(currentContracts[level][data.id].original))
        StartBoostCooldown(source, data.id)
        --print('Start Boost event now!')
        local args = {
            vehicle = preData.Model,
            label = preData.Label,
            minPrize = preData.MinPrize,
            maxPrize = preData.MaxPrize
        }
        exports['710-carBoosting']:StartBoosting710(source, args)
        table.remove(currentContracts[level], data.id)
        cb("success")
    else
        Player.Notify('You must wait to start another boost!')
        cb("busy")
    end
end)

RegisterNetEvent('jl-laptop:server:finishBoost', function(source)
    local source = source
    local Player = Framework.PlayerDataS(source)
    local CID = Player.Pid
    local level = exports['710-carBoosting']:GetBoostingLevel(source)
    TriggerClientEvent('jl-laptop:client:finishContract', source, currentContracts[level])
end)

Framework.RegisterServerCallback('jl-laptop:server:GetContracts', function(source, cb)
    local source = source
    local Player = Framework.PlayerDataS(source)
    local CID = Player.Pid
    local level = exports['710-carBoosting']:GetBoostingLevel(source)
    --if not currentContracts[level] then currentContracts[level] = {} end
    cb(currentContracts[level])
end)


function GetHoursFromNow(hours)
    if Config.Linux then
        return os.date("!%Y-%m-%dT%TZ", os.time() + hours * 60 * 60)
    else
        return os.date("!%Y-%m-%dT%SZ", os.time() + hours * 60 * 60)
    end
end

function GetCurrentTime()
    if Config.Linux then
        return os.date("!%Y-%m-%dT%TZ", os.time())
    else
        return os.date("!%Y-%m-%dT%SZ", os.time())
    end

end

Framework.RegisterServerCallback("jl-laptop:server:getCurrentTime", function(cb)
    cb({
        GetCurrentTime()
    })
end)

local function generateName()
    return Config.Boosting.RandomNames[math.random(1, #Config.Boosting.RandomNames)]
end

local boostCount = 0 

local function StartBoostListLoop(waitTime)
    CreateThread(function()
        Wait(30000)
        while true do
            local boostList710 = exports['710-carBoosting']:GetBoostListJL()
            currentContracts[1] = {}
            currentContracts[2] = {}
            currentContracts[3] = {}
            currentContracts[4] = {}
            currentContracts[5] = {}
            currentContracts[6] = {}
            --print(json.encode(boostList710[1]))
            -- C 
            for k , v in pairs(boostList710[1]) do
                currentContracts[1][k] = {
                    id = k,
                    contract = v.ClassName,
                    car = v.Model,
                    carName = v.Label,
                    expire = v,
                    owner = generateName(),
                    type = 'boosting',
                    cost = v.MinPrize.." - "..v.MaxPrize,
                    original = v

                } -- missionType(boostData, contract)
            end
            -- B 
            for k , v in pairs(boostList710[2]) do
                --print(k)
                currentContracts[2][k] = {
                    id = k,
                    contract = v.ClassName,
                    car = v.Model,
                    carName = v.Label,
                    expire = GetHoursFromNow(6),
                    owner = generateName(),
                    type = 'boosting',
                    cost = v.MinPrize.." - "..v.MaxPrize,
                    original = v

                } -- missionType(boostData, contract)
            end
            -- A 
            for k , v in pairs(boostList710[3]) do
                --print(k)
                currentContracts[3][k] = {
                    id = k,
                    contract = v.ClassName,
                    car = v.Model,
                    carName = v.Label,
                    expire = v,
                    owner = generateName(),
                    type = 'boosting',
                    cost = v.MinPrize.." - "..v.MaxPrize,
                    original = v

                } -- missionType(boostData, contract)
            end
            -- A+ 
            for k , v in pairs(boostList710[4]) do
               -- print(k)
                currentContracts[4][k] = {
                    id = k,
                    contract = v.ClassName,
                    car = v.Model,
                    carName = v.Label,
                    expire = v,
                    owner = generateName(),
                    type = 'boosting',
                    cost = v.MinPrize.." - "..v.MaxPrize,
                    original = v

                } -- missionType(boostData, contract)
            end
            -- s 
            for k , v in pairs(boostList710[5]) do
                --print(k)
                currentContracts[5][k] = {
                    id = k,
                    contract = v.ClassName,
                    car = v.Model,
                    carName = v.Label,
                    expire = v,
                    owner = generateName(),
                    type = 'boosting',
                    cost = v.MinPrize.." - "..v.MaxPrize,
                    original = v

                } -- missionType(boostData, contract)
            end
            -- S+ 
            for k , v in pairs(boostList710[6]) do
                --print(k)
                currentContracts[6][k] = {
                    id = k,
                    contract = v.ClassName,
                    car = v.Model,
                    carName = v.Label,
                    expire = v,
                    owner = generateName(),
                    type = 'boosting',
                    cost = v.MinPrize.." - "..v.MaxPrize,
                    original = v

                } -- missionType(boostData, contract)
            end
            --print(json.encode(boostList710))
            --print(json.encode(currentContracts))
            Wait(waitTime * 60000)
        end
    end)
end

exports('StartBoostListLoop', StartBoostListLoop)


Framework.RegisterServerCallback('jl-laptop:server:GetRep710', function(source, cb)
    local source = source
    local Player = Framework.PlayerDataS(source)
    local Pid = Player.Pid
    local repInfo = MySQL.query.await('SELECT * FROM 710_users WHERE pid = @pid', { ['@pid'] = Pid })
    if repInfo[1] then
        cb(repInfo[1].boostrep)
    else
        cb(0)
    end
end)

function GetBoostingRep710(source)
    local source = source
    local Player = Framework.PlayerDataS(source)
    local Pid = Player.Pid
    local repInfo = MySQL.query.await('SELECT * FROM 710_users WHERE pid = @pid', { ['@pid'] = Pid })
    if repInfo[1] then
        return(repInfo[1].boostrep)
    else
        return(0)
    end
end