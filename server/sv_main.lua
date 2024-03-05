-----------------For support, scripts, and more----------------
--------------- https://discord.gg/AeCVP2F8h7  -------------
---------------------------------------------------------------

local function HasPerms(source)
    local identifiers = GetPlayerIdentifiers(source)
    for k, v in pairs(Config.Permissions) do
        for _, id in pairs(identifiers) do
            if id == k then
                return true
            end
        end
    end
    return false
end

local LocationsTable = {}

CreateThread(function()
    if not LoadResourceFile(GetCurrentResourceName(), "locations.json") then
        SaveResourceFile(GetCurrentResourceName(), "locations.json", json.encode({}), -1)
    end
    LocationsTable = json.decode(LoadResourceFile(GetCurrentResourceName(), "locations.json"))
end)

local function StoreTable()
    SaveResourceFile(GetCurrentResourceName(), "locations.json", json.encode(LocationsTable), -1)
end

local function uuid()
    local random = math.random
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
        return string.format("%x", v)
    end)
end

lib.callback.register("snipe-microphones:server:getAllZones",function()
    return LocationsTable
end)

RegisterNetEvent("snipe-microphones:server:createMicrophone", function(data)
    local locationData = {}
    if data.type == "zone" then
        locationData = {
            uuid = tostring(uuid()),
            points = data.points,
            thickness = data.thickness,
            name = data.name,
            type = data.type,
            range = data.range,
        }
    else
        locationData = {
            uuid = tostring(uuid()),
            coords = data.coords,
            heading = data.heading,
            type = data.type,
            model = data.model,
            name = data.name,
            range = data.range,
        }
    end
    LocationsTable[#LocationsTable + 1] = locationData
    StoreTable()
    TriggerClientEvent("snipe-microphones:client:createNewMicrophone", -1, locationData)
end)
RegisterCommand("createmicrophone", function(source)
    if HasPerms(source) then
        TriggerClientEvent("snipe-microphones:client:createMicrophone", source)
    else
        TriggerClientEvent("ox_lib:notify", source, {type = "error", description = "You don't have perms"})
    end
end)

RegisterCommand("checkZones", function(source)
    if HasPerms(source) then
        TriggerClientEvent("snipe-microphones:client:checkMicrophones", source)
    else
        TriggerClientEvent("ox_lib:notify", source, {type = "error", description = "You don't have perms"})
    end
end)

RegisterNetEvent("snipe-microphones:server:deleteMicrophone", function(uuid)
    for k, v in pairs(LocationsTable) do
        if v.uuid == uuid then
            table.remove(LocationsTable, k)
            StoreTable()
            TriggerClientEvent("snipe-microphones:client:deleteMicrophone", -1, uuid)
            break
        end
    end
end)