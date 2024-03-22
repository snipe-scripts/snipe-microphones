-----------------For support, scripts, and more----------------
--------------- https://discord.gg/AeCVP2F8h7  -------------
---------------------------------------------------------------

local PolyZoneMode = exports['polyZoneCreator']:PolyZoneMode()
local polyzones = {}
local points = {}
local MicrophoneZones = {}
local inZone

local isMicrophoneEnabled = false

local function onEnterMicrophone(self)
    lib.showTextUI("You are speaking in a microphone | [G] to toggle")
    exports["pma-voice"]:overrideProximityRange(self.range or 50.0, true)
    isMicrophoneEnabled = true
    inZone = self.uuid
end

local function onExitMicrophone(self)
    lib.hideTextUI()
    exports["pma-voice"]:clearProximityOverride()
    isMicrophoneEnabled = false
    inZone = false
end

local function insideZone(self)
    if IsControlJustPressed(0, 47) then
        if isMicrophoneEnabled then
            exports["pma-voice"]:clearProximityOverride()
            isMicrophoneEnabled = false
            lib.showTextUI("You are not speaking in a microphone | [G] to toggle")
        else
            exports["pma-voice"]:overrideProximityRange(self.range or 50.0, true)
            isMicrophoneEnabled = true
            lib.showTextUI("You are speaking in a microphone | [G] to toggle")
        end
    end
end

local function GenerateZones(zones)
    for k,v in pairs(zones) do
        if v.type == "object" then
            points[v.uuid] = lib.points.new({
                coords = v.coords,
                distance = 2.0,
                onEnter = onEnterMicrophone,
                onExit = onExitMicrophone,
                nearby = insideZone,
                uuid = v.uuid,
                range = v.range or 50.0,

            })
        else
            polyzones[v.uuid] = lib.zones.poly({
                name = v.name,
                points = v.points,
                thickness = v.thickness,
                debug = Config.Debug,
                onEnter = onEnterMicrophone,
                onExit = onExitMicrophone,
                inside = insideZone,
                uuid = v.uuid,
                range = v.range or 50.0,
            })
        end
    end
end

local function createZone()
    local input = lib.inputDialog("Enter Model", {
        { type = 'number', label = "Enter Range", default = 50.0}
    })
    if input and input[1] then
        range = input[1]
    else
        lib.notify({type = "error", description = "No Range Specified"})
        return
    end
    local options = {
        name = nil,
        placeholder = "Enter the name of the zone",
        buttontext = "Submit"
    }
    local p = promise.new()
    PolyZoneMode.start(function(data)
        p:resolve(data)
    end , options) -- (optional) )
    local data = Citizen.Await(p)
    data.type = "zone"
    data.range = range
    TriggerServerEvent("snipe-microphones:server:createMicrophone", data)
end

local function createObject()
    local input = lib.inputDialog("Enter Model", {
        { type = 'input', label = "Enter the Name of The location" },
        { type = 'input', label = "Enter the model name to spawn", default = "v_club_roc_micstd" },
        { type = 'number', label = "Enter Range", default = 50.0}
    })
    if input and input[1] and input[2] and IsModelValid(input[2]) then
        obj = input[2]
    else
        lib.notify({type = "error", description = "Invalid Model"})
        return
    end
    lib.requestModel(obj)
    placingObj = CreateObject(obj, 1.0, 1.0, 1.0, false, true, true)
    SetModelAsNoLongerNeeded(obj)
    SetEntityAlpha(placingObj, 150)
    SetEntityCollision(placingObj, false, false)
    SetEntityInvincible(placingObj, true)
    FreezeEntityPosition(placingObj, true)
    lib.showTextUI("Press E to place the object, Press X to cancel, Scroll rotate the object")
    local heading = 0.0
    while placingObj do
        local hit, _, coords, _, materialHash = lib.raycast.cam(1, 4)
        if hit then
            SetEntityCoords(placingObj, coords.x, coords.y, coords.z)
            local objCoords = GetEntityCoords(placingObj)
            SetEntityHeading(placingObj, heading)


            if outLine then
                outLine = false
                SetEntityDrawOutline(placingObj, false)
            end


            if IsControlJustReleased(0, 38) then
                lib.hideTextUI()
                DeleteEntity(placingObj)
                local data = {type = "object", coords = objCoords, heading = heading, model = obj, name = input[1], range = input[3] or 50.0}
                TriggerServerEvent("snipe-microphones:server:createMicrophone", data)
                placingObj = nil
                lib.hideTextUI()
                return
            end

            if IsControlJustReleased(0, 73) then
                DeleteEntity(placingObj)
                placingObj = nil
                lib.hideTextUI()
                return
            end

            if IsControlJustReleased(0, 14) then
                heading = heading + 5
                if heading > 360 then heading = 0.0 end
            end

            if IsControlJustReleased(0, 15) then
                heading = heading - 5
                if heading < 0 then heading = 360.0 end
            end
        end
    end
end

RegisterNetEvent("snipe-microphones:client:createMicrophone", function()
    local options = {}
    options[#options+1] = {
        title = "Create Zone",
        description = "This will create a zone with no prop",
        onSelect = function()
            createZone()
        end
    }
    options[#options+1] = {
        title = "Create Object",
        description = "This will create a zone with prop",
        onSelect = function()
            createObject()
        end
    }

    lib.registerContext({
        id = 'snipe-microphone-context',
        title = "Create Microphone Zone",
        options = options,
    })
    lib.showContext('snipe-microphone-context')
end)


RegisterNetEvent("snipe-microphones:client:createNewMicrophone", function(data)
    if data.type == "zone" then
        polyzones[data.uuid] = lib.zones.poly({
            name = data.name,
            points = data.points,
            thickness = data.thickness,
            debug = Config.Debug,
            onEnter = onEnterMicrophone,
            onExit = onExitMicrophone,
            inside = insideZone,
            uuid = data.uuid,
            range = data.range or 50.0,
        })
    else
        points[data.uuid] = lib.points.new({
            coords = data.coords,
            distance = 2.0,
            onEnter = onEnterMicrophone,
            onExit = onExitMicrophone,
            inside = insideZone,
            uuid = data.uuid,
            range = data.range or 50.0,

        })
    end
    MicrophoneZones[#MicrophoneZones + 1] = data
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for k,v in pairs(MicrophoneZones) do
            if v.obj then
                DeleteEntity(v.obj)
            end
        end
    end
end)

RegisterNetEvent("snipe-microphones:client:checkMicrophones", function()
    local options = {}
    local otherMenuOptions = {}
    for k,v in pairs(MicrophoneZones) do
        options[#options+1] = {
            title = v.name or "Microphone Object",
            description = "Delete Microphone",
            menu = "snipe-microphone-context-"..k,
        }
        otherMenuOptions[k] = {}
        otherMenuOptions[k][#otherMenuOptions[k]+1 or 1] = {
            title = "Delete Microphone",
            description = "This will delete the microphone",
            onSelect = function()
                TriggerServerEvent("snipe-microphones:server:deleteMicrophone", v.uuid)
            end
        }
        otherMenuOptions[k][#otherMenuOptions[k]+1 or 1] = {
            title = "Go To Microphone",
            description = "This will teleport you to the microphone",
            onSelect = function()
                if v.type == "zone" then
                    local coords = v.points[1]
                    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
                else
                    local coords = v.coords
                    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
                end
                lib.showContext('snipe-microphone-context')
            end
        }
    end
    lib.registerContext({
        id = 'snipe-microphone-context',
        title = "Microphone Zones",
        options = options,
    })

    for k,v in pairs(otherMenuOptions) do
        lib.registerContext({
            id = 'snipe-microphone-context-'..k,
            title = "Microphone Zones",
            options = v,
        })
    end

    lib.showContext('snipe-microphone-context')
end)

RegisterNetEvent("snipe-microphones:client:deleteMicrophone", function(uuid)
    for k,v in pairs(MicrophoneZones) do
        if v.uuid == uuid then
            if v.obj then
                DeleteEntity(v.obj)
            end
            if v.type == "zone" then
                polyzones[v.uuid]:remove()
                polyzones[v.uuid] = nil
            else
                points[v.uuid]:remove()
                points[v.uuid] = nil
            end
            if inZone == v.uuid then
                lib.hideTextUI()
                exports["pma-voice"]:clearProximityOverride()
                inZone = false
            end
            table.remove(MicrophoneZones, k)
            break
        end
    end
end)

CreateThread(function()
    Wait(2000)
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            MicrophoneZones = lib.callback.await("snipe-microphones:server:getAllZones", false)
            GenerateZones(MicrophoneZones)
            break
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1500)
        for k,v in pairs(MicrophoneZones) do
            if v.type == "object" then
                local dist = #(GetEntityCoords(PlayerPedId()) - vec3(v.coords.x, v.coords.y, v.coords.z))
                if dist < 50.0 then
                    if not v.obj then
                        local obj = v.model or "v_club_roc_micstd"
                        lib.requestModel(obj)
                        v.obj = CreateObject(obj, v.coords.x, v.coords.y, v.coords.z, false, true, true)
                        SetEntityHeading(v.obj, v.heading)
                        SetModelAsNoLongerNeeded(obj)
                        FreezeEntityPosition(v.obj, true)
                    end
                else
                    if v.obj then
                        DeleteEntity(v.obj)
                        v.obj = nil
                    end
                end
            end
        end
    end
end)
