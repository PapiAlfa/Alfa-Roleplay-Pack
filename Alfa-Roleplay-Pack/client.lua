-- Script Created by Giant Cheese Wedge (AKA Blü)
-- Script Modified and fixed by Hoopsure

local crouched = false
local proned = false
crouchKey = 36
proneKey = 313
local effectActive = false            -- Blur screen effect active
local blackOutActive = false          -- Blackout effect active
local currAccidentLevel = 0           -- Level of accident player has effect active of
local wasInCar = false
local oldBodyDamage = 0.0
local oldSpeed = 0.0
local currentDamage = 0.0
local currentSpeed = 0.0
local vehicle
local disableControls = false
local mp_pointing = false
local keyPressed = false
local once = true
local oldval = false
local oldvalped = false
local playerMoving = false
local wasmenuopen = false
local tiempo = 4000 -- 1000 ms = 1s
local isTaz = false
local trackedveh = nil
local deployed = false

local function startPointing()
    local ped = GetPlayerPed(-1)
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end

local function stopPointing()
    local ped = GetPlayerPed(-1)
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

Citizen.CreateThread( function()

	local dict = "missminuteman_1ig_2"
    
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(100)
	end
	local handsup = false
	
	while true do 
		Citizen.Wait( 10 )
		local ped = GetPlayerPed( -1 )
		if ( DoesEntityExist( ped ) and not IsEntityDead( ped ) ) then 
			ProneMovement()
			DisableControlAction( 0, proneKey, true ) 
			DisableControlAction( 0, crouchKey, true ) 
			if ( not IsPauseMenuActive() ) then 
				if ( IsDisabledControlJustPressed( 0, crouchKey ) and not proned ) then 
					RequestAnimSet( "move_ped_crouched" )
					RequestAnimSet("MOVE_M@TOUGH_GUY@")
					
					while ( not HasAnimSetLoaded( "move_ped_crouched" ) ) do 
						Citizen.Wait( 100 )
					end 
					while ( not HasAnimSetLoaded( "MOVE_M@TOUGH_GUY@" ) ) do 
						Citizen.Wait( 100 )
					end 		
					if ( crouched and not proned ) then 
						ResetPedMovementClipset( ped )
						ResetPedStrafeClipset(ped)
						SetPedMovementClipset( ped,"MOVE_M@TOUGH_GUY@", 0.5)
						crouched = false 
					elseif ( not crouched and not proned ) then
						SetPedMovementClipset( ped, "move_ped_crouched", 0.55 )
						SetPedStrafeClipset(ped, "move_ped_crouched_strafing")
						crouched = true 
					end 
				elseif ( IsDisabledControlJustPressed(0, proneKey) and not crouched and not IsPedInAnyVehicle(ped, true) and not IsPedFalling(ped) and not IsPedDiving(ped) and not IsPedInCover(ped, false) and not IsPedInParachuteFreeFall(ped) and (GetPedParachuteState(ped) == 0 or GetPedParachuteState(ped) == -1) ) then
					if proned then
						ClearPedTasksImmediately(ped)
						proned = false
					elseif not proned then
						RequestAnimSet( "move_crawl" )
						while ( not HasAnimSetLoaded( "move_crawl" ) ) do 
							Citizen.Wait( 100 )
						end 
						ClearPedTasksImmediately(ped)
						proned = true
						if IsPedSprinting(ped) or IsPedRunning(ped) or GetEntitySpeed(ped) > 5 then
							TaskPlayAnim(ped, "move_jump", "dive_start_run", 8.0, 1.0, -1, 0, 0.0, 0, 0, 0)
							Citizen.Wait(1000)
						end
						SetProned()
					end
				end
			end
		else
			proned = false
			crouched = false
		end
		if IsControlJustReleased(1, 323) then --Start holding X
            if not handsup then
                TaskPlayAnim(GetPlayerPed(-1), dict, "handsup_enter", 8.0, 8.0, -1, 50, 0, false, false, false)
                handsup = true
            else
                handsup = false
                ClearPedTasks(GetPlayerPed(-1))
            end
		end
		if not keyPressed then
            if IsControlPressed(0, 29) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
                Wait(200)
                if not IsControlPressed(0, 29) then
                    keyPressed = true
                    startPointing()
                    mp_pointing = true
                else
                    keyPressed = true
                    while IsControlPressed(0, 29) do
                        Wait(50)
                    end
                end
            elseif (IsControlPressed(0, 29) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                keyPressed = true
                mp_pointing = false
                stopPointing()
            end
        end

        if keyPressed then
            if not IsControlPressed(0, 29) then
                keyPressed = false
            end
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
            if not IsPedOnFoot(PlayerPedId()) then
                stopPointing()
            else
                local ped = GetPlayerPed(-1)
                local camPitch = GetGameplayCamRelativePitch()
                if camPitch < -70.0 then
                    camPitch = -70.0
                elseif camPitch > 42.0 then
                    camPitch = 42.0
                end
                camPitch = (camPitch + 70.0) / 112.0

                local camHeading = GetGameplayCamRelativeHeading()
                local cosCamHeading = Cos(camHeading)
                local sinCamHeading = Sin(camHeading)
                if camHeading < -180.0 then
                    camHeading = -180.0
                elseif camHeading > 180.0 then
                    camHeading = 180.0
                end
                camHeading = (camHeading + 180.0) / 360.0

                local blocked = 0
                local nn = 0

                local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                nn,blocked,coords,coords = GetRaycastResult(ray)

                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)

            end
		end
		if IsPauseMenuActive() and not wasmenuopen then
			SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263, true) -- set unarmed
			TriggerEvent("Map:ToggleMap")
			--TaskStartScenarioInPlace(GetPlayerPed(-1), "WORLD_HUMAN_TOURIST_MAP", 0, false) -- Start the scenario
			wasmenuopen = true
		end
		if not IsPauseMenuActive() and wasmenuopen then
			Wait(500)
			TriggerEvent("Map:ToggleMap")
			wasmenuopen = false
		end
		if IsPedBeingStunned(GetPlayerPed(-1)) then
			
			SetPedToRagdoll(GetPlayerPed(-1), 5000, 5000, 0, 0, 0, 0)
			
		end
		if IsPedBeingStunned(GetPlayerPed(-1)) and not isTaz then
			
			isTaz = true
			SetTimecycleModifier("REDMIST_blend")
			ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 1.0)
			
		elseif not IsPedBeingStunned(GetPlayerPed(-1)) and isTaz then
			isTaz = false
			Wait(5000)
			
			SetTimecycleModifier("hud_def_desat_Trevor")
			
			Wait(10000)
			
			SetTimecycleModifier("")
			SetTransitionTimecycleModifier("")
			StopGameplayCamShaking()
		end
		if not IsPedInAnyVehicle(PlayerPedId(), false) and GetEntitySpeed(PlayerPedId()) >= 0.1 and GetFollowPedCamViewMode() ~= 4 then
			if playerMoving == false then
				ShakeGameplayCam("ROAD_VIBRATION_SHAKE", 0.75)
				playerMoving = true
			end
		else
			if playerMoving == true then
				StopGameplayCamShaking(false)
				playerMoving = false
			end
        end

        vehicle = GetVehiclePedIsIn(PlayerPedId(-1), false)
        if DoesEntityExist(vehicle) and (wasInCar or IsCar(vehicle)) then
            wasInCar = true
            oldSpeed = currentSpeed
            oldBodyDamage = currentDamage
            currentDamage = GetVehicleBodyHealth(vehicle)
            currentSpeed = GetEntitySpeed(vehicle) * 2.23

            if currentDamage ~= oldBodyDamage then
                print("crash")
                if not effect and currentDamage < oldBodyDamage then
                    print("effect")
                    print(oldBodyDamage - currentDamage)
                    if (oldBodyDamage - currentDamage) >= Config.BlackoutDamageRequiredLevel5 or (oldSpeed - currentSpeed)  >= Config.BlackoutSpeedRequiredLevel5 then
                        --[[ note("lv5") ]]
                        oldBodyDamage = currentDamage
                        TriggerEvent("crashEffect", Config.EffectTimeLevel5, 5)
                        --[[ note(oldSpeed - currentSpeed)
                        note(oldBodyDamage - currentDamage) ]]
                            
                    elseif (oldBodyDamage - currentDamage) >= Config.BlackoutDamageRequiredLevel4 or (oldSpeed - currentSpeed)  >= Config.BlackoutSpeedRequiredLevel4 then
                        --[[ note("lv4") ]]
                        TriggerEvent("crashEffect", Config.EffectTimeLevel4, 4)
                        oldBodyDamage = currentDamage
                       --[[  note(oldSpeed - currentSpeed)
                        note(oldBodyDamage - currentDamage) ]]

                    elseif (oldBodyDamage - currentDamage) >= Config.BlackoutDamageRequiredLevel3 or (oldSpeed - currentSpeed)  >= Config.BlackoutSpeedRequiredLevel3 then   
                        --[[ note(oldSpeed - currentSpeed)
                        note(oldBodyDamage - currentDamage)
                        note("lv3") ]]
                        oldBodyDamage = currentDamage
                        TriggerEvent("crashEffect", Config.EffectTimeLevel3, 3)

                    elseif (oldBodyDamage - currentDamage) >= Config.BlackoutDamageRequiredLevel2 or (oldSpeed - currentSpeed)  >= Config.BlackoutSpeedRequiredLevel2 then
                        --[[ note(-(oldSpeed - currentSpeed))
                        note(oldBodyDamage - currentDamage)
                        note("lv2") ]]
                        oldBodyDamage = currentDamage
                        TriggerEvent("crashEffect", Config.EffectTimeLevel2, 2)

                    elseif (oldBodyDamage - currentDamage) >= Config.BlackoutDamageRequiredLevel1 or (oldSpeed - currentSpeed)  >= Config.BlackoutSpeedRequiredLevel1 then
                        --[[ note(-(oldSpeed - currentSpeed))
                        note(oldBodyDamage - currentDamage)
                        note("lv1") ]]
                        oldBodyDamage = currentDamage
                        TriggerEvent("crashEffect", Config.EffectTimeLevel1, 1)
                    end
                end
            end
        elseif wasInCar then
            wasInCar = false
            beltOn = false
            currentDamage = 0
            oldBodyDamage = 0
            currentSpeed = 0
            oldSpeed = 0
        end
        if disableControls and Config.DisableControlsOnBlackout then
            -- Controls to disable while player is on blackout
			DisableControlAction(0,71,true) -- veh forward
			DisableControlAction(0,72,true) -- veh backwards
			DisableControlAction(0,63,true) -- veh turn left
			DisableControlAction(0,64,true) -- veh turn right
			DisableControlAction(0,75,true) -- disable exit vehicle
		end
	end
end

local holdingMap = false
local mapModel = "prop_tourist_map_01"
local animDict = "amb@world_human_tourist_map@male@base"
local animName = "base"
local map_net = nil

-- Toggle Map --

RegisterNetEvent("Map:ToggleMap")
AddEventHandler("Map:ToggleMap", function()
    if not holdingMap then
        RequestModel(GetHashKey(mapModel))
        while not HasModelLoaded(GetHashKey(mapModel)) do
            Citizen.Wait(100)
        end

        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(100)
        end

        local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
        local mapspawned = CreateObject(GetHashKey(mapModel), plyCoords.x, plyCoords.y, plyCoords.z, 1, 1, 1)
        Citizen.Wait(1000)
        local netid = ObjToNet(mapspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)
        AttachEntityToEntity(mapspawned, GetPlayerPed(PlayerId()), GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
        TaskPlayAnim(GetPlayerPed(PlayerId()), 1.0, -1, -1, 50, 0, 0, 0, 0) -- 50 = 32 + 16 + 2
        TaskPlayAnim(GetPlayerPed(PlayerId()), animDict, animName, 1.0, -1, -1, 50, 0, 0, 0, 0)
        map_net = netid
        holdingMap = true
    else
        ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
        DetachEntity(NetToObj(map_net), 1, 1)
        DeleteEntity(NetToObj(map_net))
        map_net = nil
        holdingMap = false
    end
end)

-- Police Vehicle Tracker --

RegisterNetEvent("tracker:trackerremove")
AddEventHandler("tracker:trackerremove", function()
    if deployed then
        deployed = false
        local plycoords = GetEntityCoords(GetPlayerPed(-1))
        SetNewWaypoint(plycoords.x + 2, plycoords.y)
        showNotification("~h~~o~Tracker~h~: ~w~Tracker deactivated!")
    end
end)

RegisterNetEvent("tracker:trackerset")
AddEventHandler("tracker:trackerset", function()
    trackedveh = GetTrackedVeh(GetVehiclePedIsIn(GetPlayerPed(-1)))
    deployed = true
    while deployed do
        Citizen.Wait(0)
        if trackedveh ~= nil then
            if IsEntityAVehicle(trackedveh) then
                local coords = GetEntityCoords(trackedveh)
                showNotification("~o~~h~Tracker:~h~~w~ Deployed!\n~h~Model:~h~ "..GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(trackedveh))).."\n~h~Plate:~h~ "..GetVehicleNumberPlateText(trackedveh))
                SetNewWaypoint(coords.x, coords.y)
            end
        else
            deployed = false
        end
    end
end)

function GetTrackedVeh(e)
	local coord1 = GetOffsetFromEntityInWorldCoords(e, 0.0, 1.0, 1.0)
	local coord2 = GetOffsetFromEntityInWorldCoords(e, 0.0, 25.0, 0.0)
	local rayresult = StartShapeTestCapsule(coord1, coord2, 3.0, 10, e, 7)
    local a, b, c, d, e = GetShapeTestResult(rayresult)
    if DoesEntityExist(e) then
        return e
    else 
        return nil
    end
end

function showNotification(string)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(string)
	DrawNotification(false, false)
end

-- BK Calls --

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

function ShowInfo(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

function playCode99Sound()
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
    Wait(900)
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
    Wait(900)
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
end

RegisterNetEvent('Fax:ShowInfo')
AddEventHandler('Fax:ShowInfo', function(notetext)
	ShowInfo(notetext)
end)

RegisterNetEvent('Fax:BackupReq')
AddEventHandler('Fax:BackupReq', function(bk, s, playerName)
    local src = s
    local bkLvl = bk
    local bkLvlTxt = "N/A"
    local coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(src)))
    local street1 = GetStreetNameAtCoord(coords.x, coords.y, coords.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
    local streetName = (GetStreetNameFromHashKey(street1))

    if PlayerData.job.name == 'police' then
        if bkLvl == "1" then
            bkLvlTxt = "~b~Code 1"
        elseif bkLvl == "2" then
            bkLvlTxt = "~y~Code 2"
        elseif bkLvl == "3" then
            bkLvlTxt = "~r~CODE 3"
            PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
        elseif bkLvl == "5" then
            bkLvlTxt = "~r~CODE 5"
            PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
        elseif bkLvl == "99" then
            bkLvlTxt = "~r~~h~CODE 99"
        elseif bkLvl == "100" then
            bkLvlTxt = "~r~~h~CODE 100"
        end
        ShowInfo("~g~" ..  playerName .. "~w~ is in need of assistance " .. bkLvlTxt .. "~s~. ~o~Location: ~b~" .. streetName .. ".")
        SetNewWaypoint(coords.x, coords.y)
        if bkLvl == "99" then
            playCode99Sound()
        elseif bkLvl == "100" then
            playCode99Sound()
        end
    end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
      if IsControlPressed(0, 21) and IsControlPressed(0, 96) and PlayerData.job.name == 'police' then
        TriggerServerEvent('Fax:BackupReq', '1')
      end
      if IsControlPressed(0, 21) and IsControlPressed(0,  97) and PlayerData.job.name == 'police' then
        TriggerServerEvent('Fax:BackupReq', '2')
      end
      if IsControlPressed(0, 21) and IsControlPressed(1,  82) and PlayerData.job.name == 'police' then
        TriggerServerEvent('Fax:BackupReq', '3')
      end
      if IsControlPressed(0, 21) and IsControlPressed(1,  81) and PlayerData.job.name == 'police' then
        TriggerServerEvent('Fax:BackupReq', '99')
      end
  end
end)

-- Mechanic Calling --

RegisterNetEvent('Alfa:CallMechanic')
AddEventHandler('Alfa:CallMechanic', function(s, playerName)
    local src = s
    local coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(src)))
    local street1 = GetStreetNameAtCoord(coords.x, coords.y, coords.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
    local streetName = (GetStreetNameFromHashKey(street1))

    if PlayerData.job.name == 'mechanic' then
        ShowInfo("~g~" ..  playerName .. "~w~ is in need of a mechanic. ~o~Location: ~b~" .. streetName .. ".")
        PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
        SetNewWaypoint(coords.x, coords.y)
    end
end)

-- Taxi Calling --

RegisterNetEvent('Alfa:CallTaxi')
AddEventHandler('Alfa:CallTaxi', function(s, playerName)
    local src = s
    local coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(src)))
    local street1 = GetStreetNameAtCoord(coords.x, coords.y, coords.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
    local streetName = (GetStreetNameFromHashKey(street1))

    if PlayerData.job.name == 'taxi' then
        ShowInfo("~g~" ..  playerName .. "~w~ is in need of a taxi. ~o~Location: ~b~" .. streetName .. ".")
        PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
        SetNewWaypoint(coords.x, coords.y)
    end
end)

-- Collision Blackout --

IsCar = function(veh)
    local vc = GetVehicleClass(veh)
    return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end 

function note(text)
SetNotificationTextEntry("STRING")
AddTextComponentString(text)
DrawNotification(false, false)
end

RegisterNetEvent("crashEffect")
AddEventHandler("crashEffect", function(countDown, accidentLevel)

    if not effectActive or (accidentLevel > currAccidentLevel) then
        currAccidentLevel = accidentLevel
        disableControls = true
        effectActive = true
        blackOutActive = true
		DoScreenFadeOut(100)
		Wait(Config.BlackoutTime)
        DoScreenFadeIn(250)
        blackOutActive = false

        -- Starts screen effect
        StartScreenEffect('PeyoteEndOut', 0, true)
        StartScreenEffect('Dont_tazeme_bro', 0, true)
        StartScreenEffect('MP_race_crash', 0, true)
    
        while countDown > 0 do

            -- Adds screen moving effect while remaining countdown is 3 times the accident level,
            -- In order to stop screen shaking BEFORE the 'blur' effect finishes
            if countDown > (3.5*accidentLevel)   then 
                ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE", (accidentLevel * Config.ScreenShakeMultiplier))
            end 
            Wait(750)
--[[             TriggerEvent('chatMessage', "countdown: " .. countDown) -- Debug printout ]]
            
            countDown = countDown - 1

            if countDown < Config.TimeLeftToEnableControls and disableControls then
                disableControls = false
            end
            -- Stops screen effect before countdown finishes
            if countDown <= 1 then
                StopScreenEffect('PeyoteEndOut')
                StopScreenEffect('Dont_tazeme_bro')
                StopScreenEffect('MP_race_crash')
            end
        end
        currAccidentLevel = 0
        effectActive = false
    end
end)

----------------------------------

function SetProned()
	ped = PlayerPedId()
	ClearPedTasksImmediately(ped)
	TaskPlayAnimAdvanced(ped, "move_crawl", "onfront_fwd", GetEntityCoords(ped), 0.0, 0.0, GetEntityHeading(ped), 1.0, 1.0, 1.0, 46, 1.0, 0, 0)
end

function ProneMovement()
	if proned then
		ped = PlayerPedId()
		if IsControlPressed(0, 32) or IsControlPressed(0, 33) then
			DisablePlayerFiring(ped, true)
		 elseif IsControlJustReleased(0, 32) or IsControlJustReleased(0, 33) then
		 	DisablePlayerFiring(ped, false)
		 end
		if IsControlJustPressed(0, 32) and not movefwd then
			movefwd = true
		    TaskPlayAnimAdvanced(ped, "move_crawl", "onfront_fwd", GetEntityCoords(ped), 1.0, 0.0, GetEntityHeading(ped), 1.0, 1.0, 1.0, 47, 1.0, 0, 0)
		elseif IsControlJustReleased(0, 32) and movefwd then
		    TaskPlayAnimAdvanced(ped, "move_crawl", "onfront_fwd", GetEntityCoords(ped), 1.0, 0.0, GetEntityHeading(ped), 1.0, 1.0, 1.0, 46, 1.0, 0, 0)
			movefwd = false
		end		
		if IsControlJustPressed(0, 33) and not movebwd then
			movebwd = true
		    TaskPlayAnimAdvanced(ped, "move_crawl", "onfront_bwd", GetEntityCoords(ped), 1.0, 0.0, GetEntityHeading(ped), 1.0, 1.0, 1.0, 47, 1.0, 0, 0)
		elseif IsControlJustReleased(0, 33) and movebwd then 
		    TaskPlayAnimAdvanced(ped, "move_crawl", "onfront_bwd", GetEntityCoords(ped), 1.0, 0.0, GetEntityHeading(ped), 1.0, 1.0, 1.0, 46, 1.0, 0, 0)
		    movebwd = false
		end
		if IsControlPressed(0, 34) then
			SetEntityHeading(ped, GetEntityHeading(ped)+2.0 )
		elseif IsControlPressed(0, 35) then
			SetEntityHeading(ped, GetEntityHeading(ped)-2.0 )
		end
	end
end

RegisterCommand("hood", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= nil and veh ~= 0 and veh ~= 1 then
        if GetVehicleDoorAngleRatio(veh, 4) > 0 then
            SetVehicleDoorShut(veh, 4, false)
        else
            SetVehicleDoorOpen(veh, 4, false, false)
        end
    end
end, false)

RegisterCommand("trunk", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= nil and veh ~= 0 and veh ~= 1 then
        if GetVehicleDoorAngleRatio(veh, 5) > 0 then
            SetVehicleDoorShut(veh, 5, false)
        else
            SetVehicleDoorOpen(veh, 5, false, false)
        end
    end
end, false)

RegisterCommand("trunk2", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= nil and veh ~= 0 and veh ~= 1 then
        if GetVehicleDoorAngleRatio(veh, 6) > 0 then
            SetVehicleDoorShut(veh, 6, false)
        else
            SetVehicleDoorOpen(veh, 6, false, false)
        end
    end
end, false)

RegisterCommand("frontleftdoor", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= nil and veh ~= 0 and veh ~= 1 then
        if GetVehicleDoorAngleRatio(veh, 0) > 0 then
            SetVehicleDoorShut(veh, 0, false)
        else
            SetVehicleDoorOpen(veh, 0, false, false)
        end
    end
end, false)

RegisterCommand("frontrightdoor", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= nil and veh ~= 0 and veh ~= 1 then
        if GetVehicleDoorAngleRatio(veh, 1) > 0 then
            SetVehicleDoorShut(veh, 1, false)
        else
            SetVehicleDoorOpen(veh, 1, false, false)
        end
    end
end, false)

RegisterCommand("backleftdoor", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= nil and veh ~= 0 and veh ~= 1 then
        if GetVehicleDoorAngleRatio(veh, 2) > 0 then
            SetVehicleDoorShut(veh, 2, false)
        else
            SetVehicleDoorOpen(veh, 2, false, false)
        end
    end
end, false)

RegisterCommand("backrightdoor", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= nil and veh ~= 0 and veh ~= 1 then
        if GetVehicleDoorAngleRatio(veh, 3) > 0 then
            SetVehicleDoorShut(veh, 3, false)
        else
            SetVehicleDoorOpen(veh, 3, false, false)
        end
    end
end, false)

RegisterCommand("trackon", function()
    if IsPedInAnyPoliceVehicle(GetPlayerPed(-1)) then
        TriggerEvent("tracker:trackerset")
    end
end, false

RegisterCommand("trackoff", function()
    if IsPedInAnyPoliceVehicle(GetPlayerPed(-1)) then
        TriggerEvent("tracker:trackerremove")
    end
end, false)