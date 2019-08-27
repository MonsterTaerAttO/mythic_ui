local x = 1.000
local y = 1.000

local hunger = -1
local thrist = -1
local inCar = false
local isLoggedIn = false
local showUi = true
local prevSpeed = 0
local currSpeed = 0.0
local cruiseSpeed = 999.0
local prevVelocity = {x = 0.0, y = 0.0, z = 0.0}

local cruiseIsOn = false
local seatbeltEjectSpeed = 45               -- Speed threshold to eject player (MPH)
local seatbeltEjectAccel = 100              -- Acceleration threshold to eject player (G's)
local voice = {default = 7.0, shout = 16.0, whisper = 1.0, current = 0, level = nil}

--[[ =========================================================================================================================== ]]--
--[[ =========================================================================================================================== ]]--
--[[ =========================================================================================================================== ]]--
--[[ =========================================================================================================================== ]]--
--[[ =========================================================================================================================== ]]--

function CalculateTimeToDisplay()
	hour = GetClockHours()
    minute = GetClockMinutes()
    
    local obj = {}

    if hour <= 12 then
        obj.ampm = 'AM'
    elseif hour >= 13 then
        obj.ampm = 'PM'
        hour = hour - 12
    end
    
	if minute <= 9 then
		minute = "0" .. minute
    end
    
    obj.hour = hour
    obj.minute = minute

    return obj
end

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function getCardinalDirectionFromHeading(heading)
    if ((heading >= 0 and heading < 45) or (heading >= 315 and heading < 360)) then
        return "Northbound" -- North
    elseif (heading >= 45 and heading < 135) then
        return "Eastbound" -- East
    elseif (heading >=135 and heading < 225) then
        return "Southbound" -- South
    elseif (heading >= 225 and heading < 315) then
        return "Westbound" -- West
    end
end

function ToggleUI()
    showUi = not showUi

    if showUi then       
        SendNUIMessage({
            action = 'showui'
        })

        if IsPedInAnyVehicle(PlayerPedId()) then 
            SendNUIMessage({
                action = 'showcar'
            })
        end
    else
        SendNUIMessage({
            action = 'hideui'
        })
        SendNUIMessage({
            action = 'hidecar'
        })
    end
end

function UIStuff()
    Citizen.CreateThread(function()
        while isLoggedIn do
            local player = PlayerPedId()
            if showUi then
                prevSpeed = currSpeed
                currSpeed = GetEntitySpeed(GetVehiclePedIsIn(player))
                local speed = currSpeed * 2.237

                local time = CalculateTimeToDisplay()
                local heading = getCardinalDirectionFromHeading(GetEntityHeading(player))
                local pos = GetEntityCoords(player)
                local var1, var2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
                local current_zone = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))

                SendNUIMessage({
                    action = 'tick',
                    show = IsPauseMenuActive(),
                    health = (GetEntityHealth(player) - 100),
                    armor = GetPedArmour(player),
                    stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId()),
                    time = time.hour .. ':' .. time.minute,
                    ampm = time.ampm,
                    direction = heading,
                    street1 = GetStreetNameFromHashKey(var1),
                    street2 = GetStreetNameFromHashKey(var2),
                    area = current_zone,
                    speed = math.ceil(speed),
                })
                
                Citizen.Wait(100)

                if NetworkIsPlayerTalking(PlayerId(-1)) then
                    SendNUIMessage({
                        action = 'voice-color',
                        isTalking = true
                    })
                else
                    SendNUIMessage({
                        action = 'voice-color',
                        isTalking = false
                    })
                end
                Citizen.Wait(100)
            else
                Citizen.Wait(200)
            end
        end
    end)
    
    Citizen.CreateThread(function()
        while isLoggedIn do
            Citizen.Wait(1)
            SetPedHelmet(PlayerPedId(), false)
            
            if IsControlJustPressed(1, 74) and IsControlPressed(1, 21) then
                voice.current = (voice.current + 1) % 3
                if voice.current == 0 then
                    NetworkSetTalkerProximity(voice.default)
                    SendNUIMessage({
                        action = 'set-voice',
                        value = 66
                    })
                elseif voice.current == 1 then
                    NetworkSetTalkerProximity(voice.shout)
                    SendNUIMessage({
                        action = 'set-voice',
                        value = 100
                    })
                elseif voice.current == 2 then
                    NetworkSetTalkerProximity(voice.whisper)
                    SendNUIMessage({
                        action = 'set-voice',
                        value = 33
                    })
                end
            end
        end
    end)
    
    Citizen.CreateThread(function()
        while isLoggedIn do
            local player = PlayerPedId()
            Citizen.Wait(1)
            if showUi then
                if DecorExistOn(player, 'player_hunger') and DecorExistOn(player, 'player_thirst') then
                    if hunger ~= DecorGetInt(player, 'player_hunger') or thirst ~= DecorGetInt(player, 'player_thirst') then
                        hunger = DecorGetInt(player, 'player_hunger')
                        thirst = DecorGetInt(player, 'player_thirst')
                        updateStatus(hunger, thirst)
                        Citizen.Wait(50000)
                    else
                        Citizen.Wait(30000)
                    end
                end
            end
        end
    end)
end

AddEventHandler('onClientMapStart', function()
    if voice.current == 0 then
      NetworkSetTalkerProximity(voice.default)
    elseif voice.current == 1 then
      NetworkSetTalkerProximity(voice.shout)
    elseif voice.current == 2 then
      NetworkSetTalkerProximity(voice.whisper)
    end  
end)

RegisterNetEvent('mythic_engine:client:StartEngineListen')
AddEventHandler('mythic_engine:client:StartEngineListen', function()
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player)

    local prevHp = GetEntityHealth(veh)

    Citizen.CreateThread(function()
        if showUi then
            SendNUIMessage({
                action = 'showcar'
            })
        end
    
        while IsPedInAnyVehicle(player) do
            Citizen.Wait(1)
            if showUi then
                if IsControlJustReleased(0, 311) then
                    local vehClass = GetVehicleClass(veh)
                    if vehClass ~= 8 and vehClass ~= 13 and vehClass ~= 14 then
                        if seatbeltIsOn then
                            TriggerServerEvent('mythic_sounds:server:PlayOnSource', 'seatbelt_off', 0.15)
                            exports['mythic_notify']:SendAlert('inform', 'Seatbelt Off')
                        else
                            TriggerServerEvent('mythic_sounds:server:PlayOnSource', 'seatbelt_on', 0.1)
                            exports['mythic_notify']:SendAlert('inform', 'Seatbelt On')
                        end
                        seatbeltIsOn = not seatbeltIsOn
                        SendNUIMessage({
                            action = 'toggle-seatbelt'
                        })
                    end
                end
                
                if not seatbeltIsOn then
                    -- Eject PED when moving forward, vehicle was going over 45 MPH and acceleration over 100 G's
                    local vehIsMovingFwd = GetEntitySpeedVector(veh, true).y > 1.0
                    local vehAcc = (prevSpeed - currSpeed) / GetFrameTime()
                    local position = GetEntityCoords(player)
                    if (prevHp ~= GetEntityHealth(veh)) then
                        if (vehIsMovingFwd and (prevSpeed > (seatbeltEjectSpeed / 2.237)) and (vehAcc > (seatbeltEjectAccel * 9.81))) then
                            SetEntityCoords(player, position.x, position.y, position.z - 0.47, true, true, true)
                            SetEntityVelocity(player, prevVelocity.x, prevVelocity.y, prevVelocity.z)
                            Citizen.Wait(1)
                            SetPedToRagdoll(player, 1000, 1000, 0, 0, 0, 0)
                        else
                            -- Update previous velocity for ejecting player
                            prevVelocity = GetEntityVelocity(veh)
                        end
                    end
                end
    
                -- When player in driver seat, handle cruise control
                if (GetPedInVehicleSeat(veh, -1) == player) then
                    -- Check if cruise control button pressed, toggle state and set maximum speed appropriately
                    if IsControlJustReleased(0, 137) then
                        if cruiseIsOn then
                            exports['mythic_notify']:SendAlert('inform', 'Cruise Disabled')
                        else
                            exports['mythic_notify']:SendAlert('inform', 'Cruise Activated')
                        end
    
                        cruiseIsOn = not cruiseIsOn
                        SendNUIMessage({
                            action = 'toggle-cruise'
                        })
                        cruiseSpeed = currSpeed
                    end
                    local maxSpeed = cruiseIsOn and cruiseSpeed or GetVehicleHandlingFloat(veh,"CHandlingData","fInitialDriveMaxFlatVel")
                    SetEntityMaxSpeed(veh, maxSpeed)
                end
            end
        end
    
        seatbeltIsOn = false
        cruiseIsOn = false
        SendNUIMessage({
            action = 'hidecar'
        })
    end)
    
    Citizen.CreateThread(function()
        while isLoggedIn do
            Citizen.Wait(1)
            if showUi then
                if DecorExistOn(veh, 'VEH_FUEL') then
                    SendNUIMessage({
                        action = 'update-fuel',
                        fuel = math.ceil(round(exports['mythic_fuel']:GetFuel(veh)))
                    })
                    Citizen.Wait(60000)
                end
            end
        end
    end)
end)

RegisterNetEvent('mythic_ui:client:UpdateStatus')
AddEventHandler('mythic_ui:client:UpdateStatus', function(hunger, thirst)
    updateStatus(hunger, thirst)
end)

RegisterNetEvent('mythic_ui:client:UpdateFuel')
AddEventHandler('mythic_ui:client:UpdateFuel', function(veh)
    if DecorExistOn(veh, 'VEH_FUEL') then
        SendNUIMessage({
            action = 'update-fuel',
            fuel = math.ceil(round(exports['mythic_fuel']:GetFuel(veh)))
        })
    end
end)

function updateStatus(hunger, thirst)
    SendNUIMessage({
        action = "updateStatus",
        hunger = hunger,
        thirst = thirst
    })
end

RegisterNetEvent('mythic_engine:client:PlayerEnteringVeh')
AddEventHandler('mythic_engine:client:PlayerEnteringVeh', function(veh)
    seatbeltIsOn = false
    cruiseIsOn = false
    SendNUIMessage({
        action = "set-seatbelt",
        seatbelt = false
    })
    SendNUIMessage({
        action = "set-cruise",
        cruise = false
    })
end)

RegisterNetEvent('mythic_characters:client:CharacterSpawned')
AddEventHandler('mythic_characters:client:CharacterSpawned', function()
    TriggerServerEvent('mythic_hud:server:GetMoneyStuff')
end)

RegisterNetEvent('mythic_ui:client:ToggleUI')
AddEventHandler('mythic_ui:client:ToggleUI', function()
    ToggleUI()
end)

RegisterNetEvent('mythic_hud:client:DisplayMoneyStuff')
AddEventHandler('mythic_hud:client:DisplayMoneyStuff', function(cash, bank)
    SendNUIMessage({
        action = 'display',
        cash = cash,
        bank = bank
    })
    SendNUIMessage({
        action = 'showui'
    })
    UIStuff()
    isLoggedIn = true
end)

RegisterNetEvent('mythic_characters:client:Logout')
AddEventHandler('mythic_characters:client:Logout', function()
    SendNUIMessage({
        action = 'hideui'
    })
    isLoggedIn = false
end)

RegisterNetEvent('mythic_hud:client:DisplayMoneyChange')
AddEventHandler('mythic_hud:client:DisplayMoneyChange', function(account, amount)
    local type = nil

    if amount < 0 then
        type = 'negative'
    else
        type = 'positive'
    end

    SendNUIMessage({
        action = 'change',
        type = type,
        account = account,
        amount = amount
    })
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        HideHudComponentThisFrame( 7 ) -- Area Name
        HideHudComponentThisFrame( 9 ) -- Street Name
        HideHudComponentThisFrame( 3 ) -- SP Cash display 
        HideHudComponentThisFrame( 4 )  -- MP Cash display
        HideHudComponentThisFrame( 13 ) -- Cash changesSetPedHelmet(PlayerPedId(), false)

        if IsPedInAnyVehicle(PlayerPedId()) and showUi then
            DisplayRadar(true)
        else
            DisplayRadar(false)
        end

        if IsControlJustReleased(0, 344) then
            ToggleUI()
        end
    end
end)