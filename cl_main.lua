local PoleModels      = {
    [`prop_traffic_01`] = true,
    [`prop_traffic_01a`] = true,
    [`prop_traffic_01b`] = true,
    [`prop_traffic_01d`] = true,
    [`prop_traffic_02a`] = true,
    [`prop_traffic_02b`] = true,
    [`prop_traffic_03a`] = true,
    [`prop_traffic_03b`] = true,
    [`prop_traffic_03c`] = true,
    [`prop_traffic_lightset_01`] = true,

    [`prop_streetlight_01`] = true,
    [`prop_streetlight_01b`] = true,
    [`prop_streetlight_02`] = true,
    [`prop_streetlight_03`] = true,
    [`prop_streetlight_03b`] = true,
    [`prop_streetlight_04`] = true,
    [`prop_streetlight_05`] = true,
    [`prop_streetlight_06`] = true,
    [`prop_streetlight_07a`] = true,
    [`prop_streetlight_07b`] = true,
    [`prop_streetlight_09`] = true,
    [`prop_streetlight_11a`] = true,
    [`prop_streetlight_11b`] = true,
    [`prop_streetlight_14a`] = true,
    [`prop_streetlight_15a`] = true,
    [`prop_streetlight_16a`] = true,

    [`prop_fire_hydrant_1`] = true,
    [`prop_fire_hydrant_2`] = true,
    [`prop_fire_hydrant_2_l1`] = true,
    [`prop_fire_hydrant_4`] = true,
}

local CHECK_RADIUS    = 80.0
local SCAN_INTERVAL   = 400
local DELETE_DELAY_MS = 1200
local UPRIGHT_ANGLE   = 60.0
local pendingDelete   = {}

local function TryDeleteEntity(entity)
    if not DoesEntityExist(entity) then return end

    if not NetworkHasControlOfEntity(entity) then
        NetworkRequestControlOfEntity(entity)
        local timeout = 0
        while not NetworkHasControlOfEntity(entity) and timeout < 25 do
            Wait(0)
            timeout = timeout + 1
        end
    end

    if NetworkHasControlOfEntity(entity) then
        SetEntityAsMissionEntity(entity, false, true)
        DeleteEntity(entity)
    end
end

local function IsPoleFalling(ent)
    if IsEntityInAir(ent) then
        return true
    end

    if not IsEntityUpright(ent, UPRIGHT_ANGLE) then
        return true
    end

    return false
end

CreateThread(function()
    while true do
        local now = GetGameTimer()
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        local objects = GetGamePool('CObject')

        for _, obj in ipairs(objects) do
            if DoesEntityExist(obj) then
                local model = GetEntityModel(obj)

                if PoleModels[model] then
                    local oCoords = GetEntityCoords(obj)
                    local dist = #(pCoords - oCoords)

                    if dist <= CHECK_RADIUS then
                        local deleteAt = pendingDelete[obj]

                        if deleteAt then
                            if now >= deleteAt then
                                if IsPoleFalling(obj) then
                                    TryDeleteEntity(obj)
                                end
                                pendingDelete[obj] = nil
                            end
                        else
                            local damaged = HasEntityBeenDamagedByAnyVehicle(obj) or IsEntityInAir(obj)

                            if damaged and IsPoleFalling(obj) then
                                pendingDelete[obj] = now + DELETE_DELAY_MS
                            end
                        end
                    else
                        pendingDelete[obj] = nil
                    end
                end
            end
        end

        for ent, _ in pairs(pendingDelete) do
            if not DoesEntityExist(ent) then
                pendingDelete[ent] = nil
            end
        end

        Wait(SCAN_INTERVAL)
    end
end)
