ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Wait(0)
	end
end)


local InSpectatorMode	= false
local TargetSpectate	= nil
local LastPosition		= nil
local polarAngleDeg		= 0;
local azimuthAngleDeg	= 90;
local radius			= -3.5;
local cam 				= nil
local PlayerDate		= {}
local ShowInfos			= false
local group				= 'admin,superadmin'

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.TriggerServerCallback('hrp_spectate:getPlayerGroup', function(g)
		group = g
	end)
end)

function polar3DToWorld3D(entityPosition, radius, polarAngleDeg, azimuthAngleDeg)
	-- convert degrees to radians
	local polarAngleRad   = polarAngleDeg   * math.pi / 180.0
	local azimuthAngleRad = azimuthAngleDeg * math.pi / 180.0
	local pos = {
		x = entityPosition.x + radius * (math.sin(azimuthAngleRad) * math.cos(polarAngleRad)),
		y = entityPosition.y - radius * (math.sin(azimuthAngleRad) * math.sin(polarAngleRad)),
		z = entityPosition.z - radius * math.cos(azimuthAngleRad)
	}
	return pos
end

function spectate(target)
	ESX.TriggerServerCallback('esx:getPlayerData', function(player)
		if player ~= 'user' then
			if not InSpectatorMode then
				LastPosition = GetEntityCoords(GetPlayerPed(-1))
			end
	
			local playerPed = GetPlayerPed(-1)
	
			SetEntityCollision(playerPed, false, false)
			SetEntityVisible(playerPed, false)
	
			PlayerData = player
			if ShowInfos then
				SendNUIMessage({
					type = 'infos',
					data = PlayerData
				})	
			end
	
			InSpectatorMode = true
			TargetSpectate  = target
			CreateSpectateThread()
		end
	end, target)
end

function resetNormalCamera()
	InSpectatorMode = false
	TargetSpectate  = nil
	local playerPed = GetPlayerPed(-1)

	SetCamActive(cam,  false)
	RenderScriptCams(false, false, 0, true, true)

	SetEntityCollision(playerPed, true, true)
	SetEntityVisible(playerPed, true)
	DetachEntity(GetPlayerPed(-1), true, false)
	if LastPosition ~= nil then
		SetEntityCoords(playerPed, LastPosition.x, LastPosition.y, LastPosition.z)
	end
	LastPosition = nil
end

function getPlayersList()
	BeginTextCommandBusyString("STRING")
	local players = nil
	ESX.TriggerServerCallback('hrp_spectate:getAllPlayers', function(data)
		players = data
	end)
	while players == nil do
		Citizen.Wait(0)
	end
	RemoveLoadingPrompt()
	return players
end

function OpenAdminActionMenu(player)
    ESX.TriggerServerCallback('hrp_spectate:getOtherPlayerData', function(data)
		print('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
		print(json.encode(data))
		print('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
		local jobLabel    = nil
		local sexLabel    = nil
		local sex         = nil
		local dobLabel    = nil
		local heightLabel = nil
		local idLabel     = nil
		local Money		= 0
		local Bank		= 0
		local blackMoney	= 0
		local Inventory	= nil
	  
		-- for i=1, #data.accounts, 1 do
		-- 	if data.accounts[i].name == 'black_money' then
		-- 		blackMoney = data.accounts[i].money
		-- 	end
		-- end

		if data.job.grade_label ~= nil and  data.job.grade_label ~= '' then
			jobLabel = 'Job : ' .. data.job.label .. ' - ' .. data.job.grade_label
		else
			jobLabel = 'Job : ' .. data.job.label
		end

		if data.sex ~= nil then
			if (data.sex == 'm') or (data.sex == 'M') then
				sex = 'Male'
			else
				sex = 'Female'
			end
			sexLabel = 'Sex : ' .. sex
		else
			sexLabel = 'Sex : Unknown'
		end

		if data.blackMoney ~= nil then
			blackMoney = data.blackMoney
		else
			blackMoney = 'No Data'
		end
	  
		if data.money ~= nil then
			Money = data.money
		else
			Money = 'No Data'
		end

		if data.bank ~= nil then
			Bank = data.bank
		else
			Bank = 'No Data'
		end
	  
		if data.dob ~= nil then
			dobLabel = 'DOB : ' .. data.dob
		else
			dobLabel = 'DOB : Unknown'
		end

		if data.height ~= nil then
			heightLabel = 'Height : ' .. data.height
		else
			heightLabel = 'Height : Unknown'
		end

		if data.name ~= nil then
			idLabel = 'Steam Name : ' .. data.name
		else
			idLabel = 'Steam Name : Unknown'
		end
	  
		local elements = {
			{label = 'Name: ' .. data.firstname .. " " .. data.lastname, value = nil},
			--{label = 'Money: '.. ESX.Math.GroupDigits(data.money), value = nil},
			{label = 'Money: '.. data.money, value = nil},
			--{label = 'Bank: '.. ESX.Math.GroupDigits(data.bank), value = nil},
			{label = 'Bank: '.. data.bank, value = nil},
			-- {label = 'Black Money: '.. ESX.Math.GroupDigits(blackMoney), value = nil, itemType = 'item_account', amount = blackMoney},
			{label = 'Black Money: '.. blackMoney, value = nil, itemType = 'item_account', amount = blackMoney},
			{label = jobLabel,    value = nil},
			{label = idLabel,     value = nil},
		}
	
    	table.insert(elements, {label = '--- Inventory ---', value = nil})

		for i=1, #data.inventory, 1 do
			if data.inventory[i].count > 0 then
				table.insert(elements, {
				label          = data.inventory[i].label .. ' x ' .. data.inventory[i].count,
				value          = nil,
				itemType       = 'item_standard',
				amount         = data.inventory[i].count,
				})
			end
		end
	
    	table.insert(elements, {label = '--- Weapons ---', value = nil})

		for i=1, #data.weapons, 1 do
			table.insert(elements, {
				label          = ESX.GetWeaponLabel(data.weapons[i].name),
				value          = nil,
				itemType       = 'item_weapon',
				amount         = data.ammo,
			})
		end
		-- if data.licenses ~= nil then
		-- 	table.insert(elements, {label = '--- Licenses ---', value = nil})
		-- 	for i=1, #data.licenses, 1 do
		-- 	table.insert(elements, {label = data.licenses[i].label, value = nil})
		-- 	end
		-- end

		ESX.UI.Menu.Open(
			'default', GetCurrentResourceName(), 'citizen_interaction',
			{
				title    = 'Player Control',
				align    = 'top-left',
				elements = elements,
			},
			function(data, menu)

			end, function(data, menu)
				menu.close()
			end
		)
	end, GetPlayerServerId(player))
end

Citizen.CreateThread(function()
	while true do
		Wait(0)
		if group ~= 'n' and group ~= "user" then
			if IsControlJustReleased(1, 344) then
				TriggerEvent('hrp_spectate:spectate')
			end
		else
			Wait(10000)
		end
	end
end)

RegisterNetEvent('es_admin:setGroup')
AddEventHandler('es_admin:setGroup', function(g)
	group = g
end)

RegisterNetEvent('hrp_spectate:spectate')
AddEventHandler('hrp_spectate:spectate', function()
	if group ~= 'n' and group ~= "user" then
		SetNuiFocus(true, true)
		SendNUIMessage({
			type = 'show',
			data = getPlayersList(),
			player = GetPlayerServerId(PlayerId()),
		})
	else
		while true do end
	end
end)

RegisterNetEvent('hrp_spectate:client_print')
AddEventHandler('hrp_spectate:client_print', function(str)
	print('§00000000000000000000000')
	print(str)
	print('§00000000000000000000000')
end)

RegisterNUICallback('select', function(data, cb)
	print(json.encode(data), group)
	if group ~= 'n' and group ~= "user" then
		InSpectatorMode = false
		spectate(data.id)
		SetNuiFocus(false)
	else
		while true do end
	end
end)

RegisterNUICallback('close', function(data, cb)
	SetNuiFocus(false)
end)

RegisterNUICallback('quit', function(data, cb)
	SetNuiFocus(false)
	resetNormalCamera()
end)

RegisterNUICallback('goto', function(data, cb)
	if group ~= 'n' and group ~= "user" then
		InSpectatorMode = false
		TargetSpectate  = nil
		local targetPlayerId = GetPlayerFromServerId(data.id)
		local coords
		if targetPlayerId == -1 then
			local done = false
			ESX.TriggerServerCallback('hrp_spectate:getPlayerCoords', function(_coords)
				coords, done = _coords, true
			end, data.id)
			
			while not done do
				Citizen.Wait(0)
			end
			
			if coords == nil then
				ESX.ShowNotification('Spectate: Nincs ilyen id')
				resetNormalCamera()
				return
			end
		else
			coords = GetEntityCoords(GetPlayerPed(targetPlayerId))
		end
		
		local playerPed = GetPlayerPed(-1)
		LastPosition = nil
		SetCamActive(cam,  false)
		RenderScriptCams(false, false, 0, true, true)
		SetEntityCollision(playerPed, true, true)
		SetEntityVisible(playerPed, true)
		DetachEntity(playerPed, true, false)
	
		SetEntityCoords(playerPed,  coords.x, coords.y + 0.5, coords.z + 0.5)
	else
		while true do end
	end
end)

RegisterNUICallback('message', function(data, cb)
	if group ~= 'n' and group ~= "user" then
		ESX.ShowNotification(data.msg)
	else
		while true do end
	end
end)



function CreateSpectateThread()
	Citizen.CreateThread(function()
		local attached = false
		while InSpectatorMode do
			HudWeaponWheelIgnoreSelection()
			local targetPlayerId = GetPlayerFromServerId(TargetSpectate)
			local playerPed = GetPlayerPed(-1)

			local targetPed = 0
			local coords = nil
			if targetPlayerId == -1 and TargetSpectate ~= nil then
				local done = false
				ESX.TriggerServerCallback('hrp_spectate:getPlayerCoords', function(_coords)
					coords, done = _coords, true
				end, TargetSpectate)

				while not done do
					Citizen.Wait(0)
				end

				if coords == nil then
					InSpectatorMode = false
					ESX.ShowNotification('Spectate: Nincs ilyen id')
					resetNormalCamera()
					return
				end

				SetEntityCoords(playerPed,  coords.x, coords.y, coords.z + 5.0)
				SetEntityVisible(playerPed, false)
				targetPlayerId = GetPlayerFromServerId(TargetSpectate)

				local time = GetGameTimer()
				while targetPlayerId == -1 and (GetGameTimer() - time) < 5000 do
					SetEntityCoords(playerPed,  coords.x, coords.y, coords.z + 5.0)
					targetPlayerId = GetPlayerFromServerId(TargetSpectate)
					Wait(0)
				end
				if targetPlayerId == -1 then
					InSpectatorMode = false
					ESX.ShowNotification('Spectate: Nincs ilyen id')
					resetNormalCamera()
					return
				end

				time = GetGameTimer()
				targetPed = GetPlayerPed(targetPlayerId)
				while targetPed == 0 and (GetGameTimer() - time) < 5000 do
					SetEntityCoords(playerPed,  coords.x, coords.y, coords.z + 5.0)
					Wait(0)
					targetPed = GetPlayerPed(targetPlayerId)
				end
				if targetPed == 0 then
					InSpectatorMode = false
					ESX.ShowNotification('Spectate: Nincs ilyen id')
					resetNormalCamera()
					return
				end
			else
				targetPed = GetPlayerPed(targetPlayerId)
				coords = GetEntityCoords(targetPed)
			end
			if not attached then
				TriggerServerEvent('hrp_spectate:log', {target = TargetSpectate})
				AttachEntityToEntity(playerPed, targetPed, -1, 
					0.0, 0.0, -5.0,
					0.0, 0.0, 0.0,
					false, false, false, true, 1, true)
				attached = true
				if not DoesCamExist(cam) then
					cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
				end
				SetCamCoord(cam,  coords.x,  coords.y,  coords.z)
				SetCamActive(cam, true)
				RenderScriptCams(true, true, 0, true, true)
				PointCamAtEntity(cam,  targetPed)
			end

			for _,id in ipairs(GetActivePlayers()) do
				if id ~= PlayerId() then
					local otherPlayerPed = GetPlayerPed(id)
					SetEntityNoCollisionEntity(playerPed,  otherPlayerPed,  true)
					SetEntityVisible(playerPed, false)
				end
			end


			if IsControlPressed(2, 241) then
				radius = radius + 2.0;
			elseif IsControlPressed(2, 242) then
				radius = radius - 2.0;
			elseif IsControlJustPressed(0,38) then
				InSpectatorMode = false
			end

			if radius > -1 then
				radius = -1
			end

			local xMagnitude = GetDisabledControlNormal(0, 1);
			local yMagnitude = GetDisabledControlNormal(0, 2);

			polarAngleDeg = polarAngleDeg + xMagnitude * 10;

			if polarAngleDeg >= 360 then
				polarAngleDeg = 0
			end

			azimuthAngleDeg = azimuthAngleDeg + yMagnitude * 10;

			if azimuthAngleDeg >= 360 then
				azimuthAngleDeg = 0;
			end

			local nextCamLocation = polar3DToWorld3D(coords, radius, polarAngleDeg, azimuthAngleDeg)

			SetCamCoord(cam,  nextCamLocation.x,  nextCamLocation.y,  nextCamLocation.z)
			PointCamAtEntity(cam,  targetPed)
			--SetEntityCoords(playerPed,  coords.x, coords.y, coords.z + 5.0)

			if IsControlPressed(2, 47) then
				OpenAdminActionMenu(targetPlayerId)
			end
			
			local text = {}
			local targetGod = GetPlayerInvincible(targetPlayerId)
			table.insert(text,"Játékos név: ~y~"..GetPlayerName(targetPlayerId).."~w~ [~r~"..TargetSpectate.."~w~]")
			table.insert(text,"Játékos sebessége: ~y~"..math.floor(GetEntitySpeed(targetPed) * 3.6 + 0.5).." kmh~w~")
			if targetGod then
				table.insert(text,"Godmode: ~r~Found~w~")
			else
				table.insert(text,"Godmode: ~g~Not Found~w~")
			end
			table.insert(text,"Health"..": "..GetEntityHealth(targetPed).."/"..GetEntityMaxHealth(targetPed))
			table.insert(text,"Armor"..": "..GetPedArmour(targetPed))
			if not CanPedRagdoll(targetPed) and not IsPedInAnyVehicle(targetPed, false) and (GetPedParachuteState(targetPed) == -1 or GetPedParachuteState(targetPed) == 0) and not IsPedInParachuteFreeFall(targetPed) then
				table.insert(text,"~r~Anti-Ragdoll~w~")
			else
				table.insert(text,"")
			end
			table.insert(text,"Spectate menu: ~y~9~w~")
			table.insert(text,"Játékos bövebb info: ~y~G~w~")

			for i,theText in pairs(text) do
				SetTextFont(0)
				SetTextProportional(1)
				SetTextScale(0.0, 0.30)
				SetTextDropshadow(0, 0, 0, 0, 255)
				SetTextEdge(1, 0, 0, 0, 255)
				SetTextDropShadow()
				SetTextOutline()
				SetTextEntry("STRING")
				AddTextComponentString(theText)
				EndTextCommandDisplayText(0.3, 0.7+(i/30))
			end
			Wait(0)
		end
		resetNormalCamera()
	end)
end