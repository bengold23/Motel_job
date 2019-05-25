local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX                           = nil
local Ownedhotels         = {}
local Blips                   = {}
local Currenthotel         = nil
local CurrenthotelOwner    = nil
local Lasthotel            = nil
local LastPart                = nil
local HasAlreadyEnteredMarker = false
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local FirstSpawn              = true
local HasChest                = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.TriggerServerCallback('ilyes_hotel:gethotels', function(hotels)
		Config.hotels = hotels
		CreateBlips()
	end)

	ESX.TriggerServerCallback('ilyes_hotel:getOwnedhotels', function(ownedhotels)
		for i=1, #ownedhotels, 1 do
			SethotelOwned(ownedhotels[i], true)
		end
	end)
end)

-- only used when script is restarting mid-session
RegisterNetEvent('ilyes_hotel:sendhotels')
AddEventHandler('ilyes_hotel:sendhotels', function(hotels)
	Config.hotels = hotels
	CreateBlips()

	ESX.TriggerServerCallback('ilyes_hotel:getOwnedhotels', function(ownedhotels)
		for i=1, #ownedhotels, 1 do
			SethotelOwned(ownedhotels[i], true)
		end
	end)
end)

function DrawSub(text, time)
	ClearPrints()
	SetTextEntry_2('STRING')
	AddTextComponentString(text)
	DrawSubtitleTimed(time, 1)
end


function Gethotels()
	return Config.hotels
end

function Gethotel(name)
	for i=1, #Config.hotels, 1 do
		if Config.hotels[i].name == name then
			return Config.hotels[i]
		end
	end
end

function GetGateway(hotel)
	for i=1, #Config.hotels, 1 do
		local hotel2 = Config.hotels[i]

		if hotel2.isGateway and hotel2.name == hotel.gateway then
			return hotel2
		end
	end
end

function GetGatewayhotels(hotel)
	local hotels = {}

	for i=1, #Config.hotels, 1 do
		if Config.hotels[i].gateway == hotel.name then
			table.insert(hotels, Config.hotels[i])
		end
	end

	return hotels
end

function Enterhotel(name, owner)
	local hotel       = Gethotel(name)
	local playerPed      = PlayerPedId()
	Currenthotel      = hotel
	CurrenthotelOwner = owner

	for i=1, #Config.hotels, 1 do
		if Config.hotels[i].name ~= name then
			Config.hotels[i].disabled = true
		end
	end

	TriggerServerEvent('ilyes_hotel:saveLasthotel', name)

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(0)
		end

		for i=1, #hotel.ipls, 1 do
			RequestIpl(hotel.ipls[i])

			while not IsIplActive(hotel.ipls[i]) do
				Citizen.Wait(0)
			end
		end

		SetEntityCoords(playerPed, hotel.inside.x, hotel.inside.y, hotel.inside.z)
		DoScreenFadeIn(800)
		DrawSub(hotel.label, 5000)
	end)

end

function Exithotel(name)
	local hotel  = Gethotel(name)
	local playerPed = PlayerPedId()
	local outside   = nil
	Currenthotel = nil

	if hotel.isSingle then
		outside = hotel.outside
	else
		outside = GetGateway(hotel).outside
	end

	TriggerServerEvent('ilyes_hotel:deleteLasthotel')

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(0)
		end

		SetEntityCoords(playerPed, outside.x, outside.y, outside.z)

		for i=1, #hotel.ipls, 1 do
			RemoveIpl(hotel.ipls[i])
		end

		for i=1, #Config.hotels, 1 do
			Config.hotels[i].disabled = false
		end

		DoScreenFadeIn(800)
	end)
end

function SethotelOwned(name, owned)
	local hotel     = Gethotel(name)
	local entering     = nil
	local enteringName = nil

	if hotel.isSingle then
		entering     = hotel.entering
		enteringName = hotel.name
	else
		local gateway = GetGateway(hotel)
		entering      = gateway.entering
		enteringName  = gateway.name
	end

	if owned then
		RemoveBlip(Blips[enteringName])

		Blips[enteringName] = AddBlipForCoord(entering.x, entering.y, entering.z)
		SetBlipAsShortRange(Blips[enteringName], true)

		BeginTextCommandSetBlipName("STRING")
		EndTextCommandSetBlipName(Blips[enteringName])

	else

		Ownedhotels[name] = nil
		local found = false

		for k,v in pairs(Ownedhotels) do
			local _hotel = Gethotel(k)
			local _gateway  = GetGateway(_hotel)

			if _gateway then
				if _gateway.name == enteringName then
					found = true
					break
				end
			end
		end

		if not found then
			RemoveBlip(Blips[enteringName])

			Blips[enteringName] = AddBlipForCoord(entering.x, entering.y, entering.z)
			SetBlipAsShortRange(Blips[enteringName], true)

			BeginTextCommandSetBlipName("STRING")
			EndTextCommandSetBlipName(Blips[enteringName])
		end

	end

end

function hotelIsOwned(hotel)
	return Ownedhotels[hotel.name] == true
end

function OpenhotelMenu(hotel)
	local elements = {}

	if hotelIsOwned(hotel) then
		table.insert(elements, {label = _U('enter'), value = 'enter'})

		if not Config.EnablePlayerManagement then
			table.insert(elements, {label = _U('leave'), value = 'leave'})
		end
	else

		table.insert(elements, {label = _U('visit'), value = 'visit'})
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'hotel',
	{
		title    = hotel.label,
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		menu.close()

		if data.current.value == 'enter' then
			TriggerEvent('instance:create', 'hotel', {hotel = hotel.name, owner = ESX.GetPlayerData().identifier})
		elseif data.current.value == 'leave' then
			TriggerServerEvent('ilyes_hotel:removeOwnedhotel', hotel.name)
		elseif data.current.value == 'buy' then
			TriggerServerEvent('ilyes_hotel:buyhotel', hotel.name)
		elseif data.current.value == 'rent' then
			TriggerServerEvent('ilyes_hotel:renthotel', hotel.name)
		elseif data.current.value == 'visit' then
			TriggerEvent('instance:create', 'hotel', {hotel = hotel.name, owner = ESX.GetPlayerData().identifier})
		end
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'hotel_menu'
		CurrentActionMsg  = _U('press_to_menu')
		CurrentActionData = {hotel = hotel}
	end)
end

function OpenGatewayMenu(hotel)
	if Config.EnablePlayerManagement then
		OpenGatewayOwnedhotelsMenu(gatewayhotels)
	else

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gateway',
		{
			title    = hotel.name,
			align    = 'top-left',
			elements = {
				{label = _U('owned_hotels'),    value = 'owned_hotels'},
				{label = _U('available_hotels'), value = 'available_hotels'}
			}
		}, function(data, menu)
			if data.current.value == 'owned_hotels' then
				OpenGatewayOwnedhotelsMenu(hotel)
			elseif data.current.value == 'available_hotels' then
				OpenGatewayAvailablehotelsMenu(hotel)
			end
		end, function(data, menu)
			menu.close()

			CurrentAction     = 'gateway_menu'
			CurrentActionMsg  = _U('press_to_menu')
			CurrentActionData = {hotel = hotel}
		end)

	end
end

function OpenGatewayOwnedhotelsMenu(hotel)
	local gatewayhotels = GetGatewayhotels(hotel)
	local elements          = {}

	for i=1, #gatewayhotels, 1 do
		if hotelIsOwned(gatewayhotels[i]) then
			table.insert(elements, {
				label = gatewayhotels[i].label,
				value = gatewayhotels[i].name
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gateway_owned_hotels',
	{
		title    = hotel.name .. ' - ' .. _U('owned_hotels'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		menu.close()

		local elements = {
			{label = _U('enter'), value = 'enter'}
		}

		if not Config.EnablePlayerManagement then
			table.insert(elements, {label = _U('leave'), value = 'leave'})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gateway_owned_hotels_actions',
		{
			title    = data.current.label,
			align    = 'top-left',
			elements = elements
		}, function(data2, menu2)
			menu2.close()

			if data2.current.value == 'enter' then
				TriggerEvent('instance:create', 'hotel', {hotel = data.current.value, owner = ESX.GetPlayerData().identifier})
				ESX.UI.Menu.CloseAll()
			elseif data2.current.value == 'leave' then
				TriggerServerEvent('ilyes_hotel:removeOwnedhotel', data.current.value)
			end
		end, function(data2, menu2)
			menu2.close()
		end)

	end, function(data, menu)
		menu.close()
	end)
end

function OpenGatewayAvailablehotelsMenu(hotel)
	local gatewayhotels = GetGatewayhotels(hotel)
	local elements          = {}

	for i=1, #gatewayhotels, 1 do
		if not hotelIsOwned(gatewayhotels[i]) then
			table.insert(elements, {
				label = gatewayhotels[i].label .. ' $' .. ESX.Math.GroupDigits(gatewayhotels[i].price),
				value = gatewayhotels[i].name,
				price = gatewayhotels[i].price
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gateway_available_hotels',
	{
		title    = hotel.name .. ' - ' .. _U('available_hotels'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		menu.close()

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gateway_available_hotels_actions',
		{
			title    = hotel.label .. ' - ' .. _U('available_hotels'),
			align    = 'top-left',
			elements = {
				{label = _U('buy'), value = 'buy'},
				{label = _U('rent'), value = 'rent'},
				{label = _U('visit'), value = 'visit'}
			}
		}, function(data2, menu2)
			menu2.close()

			if data2.current.value == 'buy' then
				TriggerServerEvent('ilyes_hotel:buyhotel', data.current.value)
			elseif data2.current.value == 'rent' then
				TriggerServerEvent('ilyes_hotel:renthotel', data.current.value)
			elseif data2.current.value == 'visit' then
				TriggerEvent('instance:create', 'hotel', {hotel = data.current.value, owner = ESX.GetPlayerData().identifier})
			end
		end, function(data2, menu2)
			menu2.close()
		end)

	end, function(data, menu)
		menu.close()
	end)
end

function OpenRoomMenu(hotel, owner)
	local entering = nil
	local elements = {}

	if hotel.isSingle then
		entering = hotel.entering
	else
		entering = GetGateway(hotel).entering
	end

	table.insert(elements, {label = _U('invite_player'),  value = 'invite_player'})

	if CurrenthotelOwner == owner then
		table.insert(elements, {label = _U('player_clothes'), value = 'player_dressing'})
		table.insert(elements, {label = _U('remove_cloth'), value = 'remove_cloth'})
	end

	table.insert(elements, {label = _U('remove_object'),  value = 'room_inventory'})
	table.insert(elements, {label = _U('deposit_object'), value = 'player_inventory'})

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'room',
	{
		title    = hotel.label,
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'invite_player' then

			local playersInArea = ESX.Game.GetPlayersInArea(entering, 10.0)
			local elements      = {}

			for i=1, #playersInArea, 1 do
				if playersInArea[i] ~= PlayerId() then
					table.insert(elements, {label = GetPlayerName(playersInArea[i]), value = playersInArea[i]})
				end
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'room_invite',
			{
				title    = hotel.label .. ' - ' .. _U('invite'),
				align    = 'top-left',
				elements = elements,
			}, function(data2, menu2)
				TriggerEvent('instance:invite', 'hotel', GetPlayerServerId(data2.current.value), {hotel = hotel.name, owner = owner})
				ESX.ShowNotification(_U('you_invited', GetPlayerName(data2.current.value)))
			end, function(data2, menu2)
				menu2.close()
			end)

		elseif data.current.value == 'player_dressing' then

			ESX.TriggerServerCallback('ilyes_hotel:getPlayerDressing', function(dressing)
				local elements = {}

				for i=1, #dressing, 1 do
					table.insert(elements, {
						label = dressing[i],
						value = i
					})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_dressing',
				{
					title    = hotel.label .. ' - ' .. _U('player_clothes'),
					align    = 'top-left',
					elements = elements
				}, function(data2, menu2)

					TriggerEvent('skinchanger:getSkin', function(skin)
						ESX.TriggerServerCallback('ilyes_hotel:getPlayerOutfit', function(clothes)
							TriggerEvent('skinchanger:loadClothes', skin, clothes)
							TriggerEvent('esx_skin:setLastSkin', skin)

							TriggerEvent('skinchanger:getSkin', function(skin)
								TriggerServerEvent('esx_skin:save', skin)
							end)
						end, data2.current.value)
					end)

				end, function(data2, menu2)
					menu2.close()
				end)
			end)

		elseif data.current.value == 'remove_cloth' then

			ESX.TriggerServerCallback('ilyes_hotel:getPlayerDressing', function(dressing)
				local elements = {}

				for i=1, #dressing, 1 do
					table.insert(elements, {
						label = dressing[i],
						value = i
					})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'remove_cloth', {
					title    = hotel.label .. ' - ' .. _U('remove_cloth'),
					align    = 'top-left',
					elements = elements
				}, function(data2, menu2)
					menu2.close()
					TriggerServerEvent('ilyes_hotel:removeOutfit', data2.current.value)
					ESX.ShowNotification(_U('removed_cloth'))
				end, function(data2, menu2)
					menu2.close()
				end)
			end)

		elseif data.current.value == 'room_inventory' then
			OpenRoomInventoryMenu(hotel, owner)
		elseif data.current.value == 'player_inventory' then
			OpenPlayerInventoryMenu(hotel, owner)
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'room_menu'
		CurrentActionMsg  = _U('press_to_menu')
		CurrentActionData = {hotel = hotel, owner = owner}
	end)
end

function OpenRoomInventoryMenu(hotel, owner)

	ESX.TriggerServerCallback('ilyes_hotel:gethotelInventory', function(inventory)

		local elements = {}

		if inventory.blackMoney > 0 then
			table.insert(elements, {
				label = _U('dirty_money', ESX.Math.GroupDigits(inventory.blackMoney)),
				type = 'item_account',
				value = 'black_money'
			})
		end

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type = 'item_standard',
					value = item.name
				})
			end
		end

		for i=1, #inventory.weapons, 1 do
			local weapon = inventory.weapons[i]

			table.insert(elements, {
				label = ESX.GetWeaponLabel(weapon.name) .. ' [' .. weapon.ammo .. ']',
				type  = 'item_weapon',
				value = weapon.name,
				ammo  = weapon.ammo
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'room_inventory',
		{
			title    = hotel.label .. ' - ' .. _U('inventory'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)

			if data.current.type == 'item_weapon' then

				menu.close()

				TriggerServerEvent('ilyes_hotel:getItem', owner, data.current.type, data.current.value, data.current.ammo)
				ESX.SetTimeout(300, function()
					OpenRoomInventoryMenu(hotel, owner)
				end)

			else

				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'get_item_count', {
					title = _U('amount')
				}, function(data2, menu)

					local quantity = tonumber(data2.value)
					if quantity == nil then
						ESX.ShowNotification(_U('amount_invalid'))
					else
						menu.close()

						TriggerServerEvent('ilyes_hotel:getItem', owner, data.current.type, data.current.value, quantity)
						ESX.SetTimeout(300, function()
							OpenRoomInventoryMenu(hotel, owner)
						end)
					end

				end, function(data2,menu)
					menu.close()
				end)

			end

		end, function(data, menu)
			menu.close()
		end)

	end, owner)

end

function OpenPlayerInventoryMenu(hotel, owner)

	ESX.TriggerServerCallback('ilyes_hotel:getPlayerInventory', function(inventory)

		local elements = {}

		if inventory.blackMoney > 0 then
			table.insert(elements, {
				label = _U('dirty_money', ESX.Math.GroupDigits(inventory.blackMoney)),
				type  = 'item_account',
				value = 'black_money'
			})
		end

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type  = 'item_standard',
					value = item.name
				})
			end
		end

		for i=1, #inventory.weapons, 1 do
			local weapon = inventory.weapons[i]

			table.insert(elements, {
				label = weapon.label .. ' [' .. weapon.ammo .. ']',
				type  = 'item_weapon',
				value = weapon.name,
				ammo  = weapon.ammo
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_inventory',
		{
			title    = hotel.label .. ' - ' .. _U('inventory'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)

			if data.current.type == 'item_weapon' then

				menu.close()
				TriggerServerEvent('ilyes_hotel:putItem', owner, data.current.type, data.current.value, data.current.ammo)

				ESX.SetTimeout(300, function()
					OpenPlayerInventoryMenu(hotel, owner)
				end)

			else

				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
					title = _U('amount')
				}, function(data2, menu2)

					local quantity = tonumber(data2.value)

					if quantity == nil then
						ESX.ShowNotification(_U('amount_invalid'))
					else

						menu2.close()

						TriggerServerEvent('ilyes_hotel:putItem', owner, data.current.type, data.current.value, tonumber(data2.value))
						ESX.SetTimeout(300, function()
							OpenPlayerInventoryMenu(hotel, owner)
						end)
					end

				end, function(data2, menu2)
					menu2.close()
				end)

			end

		end, function(data, menu)
			menu.close()
		end)

	end)

end

AddEventHandler('instance:loaded', function()
	TriggerEvent('instance:registerType', 'hotel', function(instance)
		Enterhotel(instance.data.hotel, instance.data.owner)
	end, function(instance)
		Exithotel(instance.data.hotel)
	end)
end)

AddEventHandler('playerSpawned', function()
	if FirstSpawn then

		Citizen.CreateThread(function()

			while not ESX.IsPlayerLoaded() do
				Citizen.Wait(0)
			end

			ESX.TriggerServerCallback('ilyes_hotel:getLasthotel', function(hotelName)
				if hotelName then
					if hotelName ~= '' then
						local hotel = Gethotel(hotelName)

						for i=1, #hotel.ipls, 1 do
							RequestIpl(hotel.ipls[i])
				
							while not IsIplActive(hotel.ipls[i]) do
								Citizen.Wait(0)
							end
						end

						TriggerEvent('instance:create', 'hotel', {hotel = hotelName, owner = ESX.GetPlayerData().identifier})
					end
				end
			end)
		end)

		FirstSpawn = false
	end
end)

AddEventHandler('ilyes_hotel:gethotels', function(cb)
	cb(Gethotels())
end)

AddEventHandler('ilyes_hotel:gethotel', function(name, cb)
	cb(Gethotel(name))
end)

AddEventHandler('ilyes_hotel:getGateway', function(hotel, cb)
	cb(GetGateway(hotel))
end)

RegisterNetEvent('ilyes_hotel:sethotelOwned')
AddEventHandler('ilyes_hotel:sethotelOwned', function(name, owned)
	SethotelOwned(name, owned)
end)

RegisterNetEvent('instance:onCreate')
AddEventHandler('instance:onCreate', function(instance)
	if instance.type == 'hotel' then
		TriggerEvent('instance:enter', instance)
	end
end)

RegisterNetEvent('instance:onEnter')
AddEventHandler('instance:onEnter', function(instance)
	if instance.type == 'hotel' then
		local hotel = Gethotel(instance.data.hotel)
		local isHost   = GetPlayerFromServerId(instance.host) == PlayerId()
		local isOwned  = false

		if hotelIsOwned(hotel) == true then
			isOwned = true
		end

		if isOwned or not isHost then
			HasChest = true
		else
			HasChest = false
		end
	end
end)

RegisterNetEvent('instance:onPlayerLeft')
AddEventHandler('instance:onPlayerLeft', function(instance, player)
	if player == instance.host then
		TriggerEvent('instance:leave')
	end
end)

AddEventHandler('ilyes_hotel:hasEnteredMarker', function(name, part)
	local hotel = Gethotel(name)

	if part == 'entering' then
		if hotel.isSingle then
			CurrentAction     = 'hotel_menu'
			CurrentActionMsg  = _U('press_to_menu')
			CurrentActionData = {hotel = hotel}
		else
			CurrentAction     = 'gateway_menu'
			CurrentActionMsg  = _U('press_to_menu')
			CurrentActionData = {hotel = hotel}
		end
	elseif part == 'exit' then
		CurrentAction     = 'room_exit'
		CurrentActionMsg  = _U('press_to_exit')
		CurrentActionData = {hotelName = name}
	elseif part == 'roomMenu' then
		CurrentAction     = 'room_menu'
		CurrentActionMsg  = _U('press_to_menu')
		CurrentActionData = {hotel = hotel, owner = CurrenthotelOwner}
	end
end)

AddEventHandler('ilyes_hotel:hasExitedMarker', function(name, part)
	ESX.UI.Menu.CloseAll()
	CurrentAction = nil
end)

-- Enter / Exit marker events & Draw markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local coords = GetEntityCoords(PlayerPedId())
		local isInMarker, letSleep = false, true
		local currenthotel, currentPart

		for i=1, #Config.hotels, 1 do
			local hotel = Config.hotels[i]

			-- Entering
			if hotel.entering and not hotel.disabled then
				local distance = GetDistanceBetweenCoords(coords, hotel.entering.x, hotel.entering.y, hotel.entering.z, true)

				if distance < Config.DrawDistance then
					DrawMarker(Config.MarkerType, hotel.entering.x, hotel.entering.y, hotel.entering.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
					letSleep = false
				end

				if distance < Config.MarkerSize.x then
					isInMarker      = true
					currenthotel = hotel.name
					currentPart     = 'entering'
				end
			end

			-- Exit
			if hotel.exit and not hotel.disabled then
				local distance = GetDistanceBetweenCoords(coords, hotel.exit.x, hotel.exit.y, hotel.exit.z, true)

				if distance < Config.DrawDistance then
					DrawMarker(Config.MarkerType, hotel.exit.x, hotel.exit.y, hotel.exit.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
					letSleep = false
				end

				if distance < Config.MarkerSize.x then
					isInMarker      = true
					currenthotel = hotel.name
					currentPart     = 'exit'
				end
			end

			-- Room menu
			if hotel.roomMenu and HasChest and not hotel.disabled then
				local distance = GetDistanceBetweenCoords(coords, hotel.roomMenu.x, hotel.roomMenu.y, hotel.roomMenu.z, true)

				if distance < Config.DrawDistance then
					DrawMarker(Config.MarkerType, hotel.roomMenu.x, hotel.roomMenu.y, hotel.roomMenu.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.RoomMenuMarkerColor.r, Config.RoomMenuMarkerColor.g, Config.RoomMenuMarkerColor.b, 100, false, true, 2, false, nil, nil, false)
					letSleep = false
				end

				if distance < Config.MarkerSize.x then
					isInMarker      = true
					currenthotel = hotel.name
					currentPart     = 'roomMenu'
				end
			end
		end

		if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (Lasthotel ~= currenthotel or LastPart ~= currentPart) ) then
			HasAlreadyEnteredMarker = true
			Lasthotel            = currenthotel
			LastPart                = currentPart

			TriggerEvent('ilyes_hotel:hasEnteredMarker', currenthotel, currentPart)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('ilyes_hotel:hasExitedMarker', Lasthotel, LastPart)
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end
end)

-- Key controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, Keys['E']) then

				if CurrentAction == 'hotel_menu' then
					OpenhotelMenu(CurrentActionData.hotel)
				elseif CurrentAction == 'gateway_menu' then
					if Config.EnablePlayerManagement then
						OpenGatewayOwnedhotelsMenu(CurrentActionData.hotel)
					else
						OpenGatewayMenu(CurrentActionData.hotel)
					end
				elseif CurrentAction == 'room_menu' then
					OpenRoomMenu(CurrentActionData.hotel, CurrentActionData.owner)
				elseif CurrentAction == 'room_exit' then
					TriggerEvent('instance:leave')
				end

				CurrentAction = nil

			end
		else
			Citizen.Wait(500)
		end
	end
end)