ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function Gethotel(name)
	for i=1, #Config.hotels, 1 do
		if Config.hotels[i].name == name then
			return Config.hotels[i]
		end
	end
end

function SethotelOwned(name, price, rented, owner)
	MySQL.Async.execute('INSERT INTO owned_hotels (name, price, rented, owner) VALUES (@name, @price, @rented, @owner)',
	{
		['@name']   = name,
		['@price']  = price,
		['@rented'] = (rented and 1 or 0),
		['@owner']  = owner
	}, function(rowsChanged)
		local xPlayer = ESX.GetPlayerFromIdentifier(owner)

		if xPlayer then
			TriggerClientEvent('ilyes_hotel:sethotelOwned', xPlayer.source, name, true)

			if rented then
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('rented_for', ESX.Math.GroupDigits(price)))
			else
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('purchased_for', ESX.Math.GroupDigits(price)))
			end
		end
	end)
end

function RemoveOwnedhotel(name, owner)
	MySQL.Async.execute('DELETE FROM owned_hotels WHERE name = @name AND owner = @owner',
	{
		['@name']  = name,
		['@owner'] = owner
	}, function(rowsChanged)
		local xPlayer = ESX.GetPlayerFromIdentifier(owner)

		if xPlayer then
			TriggerClientEvent('ilyes_hotel:sethotelOwned', xPlayer.source, name, false)
			TriggerClientEvent('esx:showNotification', xPlayer.source, _U('made_hotel'))
		end
	end)
end

MySQL.ready(function()
	MySQL.Async.fetchAll('SELECT * FROM hotels', {}, function(hotels)

		for i=1, #hotels, 1 do
			local entering  = nil
			local exit      = nil
			local inside    = nil
			local outside   = nil
			local isSingle  = nil
			local isRoom    = nil
			local isGateway = nil
			local roomMenu  = nil

			if hotels[i].entering ~= nil then
				entering = json.decode(hotels[i].entering)
			end

			if hotels[i].exit ~= nil then
				exit = json.decode(hotels[i].exit)
			end

			if hotels[i].inside ~= nil then
				inside = json.decode(hotels[i].inside)
			end

			if hotels[i].outside ~= nil then
				outside = json.decode(hotels[i].outside)
			end

			if hotels[i].is_single == 0 then
				isSingle = false
			else
				isSingle = true
			end

			if hotels[i].is_room == 0 then
				isRoom = false
			else
				isRoom = true
			end

			if hotels[i].is_gateway == 0 then
				isGateway = false
			else
				isGateway = true
			end

			if hotels[i].room_menu ~= nil then
				roomMenu = json.decode(hotels[i].room_menu)
			end

			table.insert(Config.hotels, {
				name      = hotels[i].name,
				label     = hotels[i].label,
				entering  = entering,
				exit      = exit,
				inside    = inside,
				outside   = outside,
				ipls      = json.decode(hotels[i].ipls),
				gateway   = hotels[i].gateway,
				isSingle  = isSingle,
				isRoom    = isRoom,
				isGateway = isGateway,
				roomMenu  = roomMenu,
				price     = hotels[i].price
			})
		end

		TriggerClientEvent('ilyes_hotel:sendhotels', -1, Config.hotels)
	end)

end)

ESX.RegisterServerCallback('ilyes_hotel:gethotels', function(source, cb)
	cb(Config.hotels)
end)

AddEventHandler('esx_ownedhotel:getOwnedhotels', function(cb)
	MySQL.Async.fetchAll('SELECT * FROM owned_hotels', {}, function(result)
		local hotels = {}

		for i=1, #result, 1 do
			table.insert(hotels, {
				id     = result[i].id,
				name   = result[i].name,
				label  = Gethotel(result[i].name).label,
				price  = result[i].price,
				rented = (result[i].rented == 1 and true or false),
				owner  = result[i].owner
			})
		end

		cb(hotels)
	end)
end)

AddEventHandler('ilyes_hotel:sethotelOwned', function(name, price, rented, owner)
	SethotelOwned(name, price, rented, owner)
end)

AddEventHandler('ilyes_hotel:removeOwnedhotel', function(name, owner)
	RemoveOwnedhotel(name, owner)
end)

RegisterServerEvent('ilyes_hotel:renthotel')
AddEventHandler('ilyes_hotel:renthotel', function(hotelName)
	local xPlayer  = ESX.GetPlayerFromId(source)
	local hotel = Gethotel(hotelName)
	local rent     = ESX.Math.Round(hotel.price / 200)

	SethotelOwned(hotelName, rent, true, xPlayer.identifier)
end)

RegisterServerEvent('ilyes_hotel:buyhotel')
AddEventHandler('ilyes_hotel:buyhotel', function(hotelName)
	local xPlayer  = ESX.GetPlayerFromId(source)
	local hotel = Gethotel(hotelName)

	if hotel.price <= xPlayer.getMoney() then
		xPlayer.removeMoney(hotel.price)
		SethotelOwned(hotelName, hotel.price, false, xPlayer.identifier)
	else
		TriggerClientEvent('esx:showNotification', source, _U('not_enough'))
	end
end)

RegisterServerEvent('ilyes_hotel:removeOwnedhotel')
AddEventHandler('ilyes_hotel:removeOwnedhotel', function(hotelName)
	local xPlayer = ESX.GetPlayerFromId(source)
	RemoveOwnedhotel(hotelName, xPlayer.identifier)
end)

AddEventHandler('ilyes_hotel:removeOwnedhotelIdentifier', function(hotelName, identifier)
	RemoveOwnedhotel(hotelName, identifier)
end)

RegisterServerEvent('ilyes_hotel:saveLasthotel')
AddEventHandler('ilyes_hotel:saveLasthotel', function(hotel)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE users SET last_hotel = @last_hotel WHERE identifier = @identifier',
	{
		['@last_hotel'] = hotel,
		['@identifier']    = xPlayer.identifier
	})
end)

RegisterServerEvent('ilyes_hotel:deleteLasthotel')
AddEventHandler('ilyes_hotel:deleteLasthotel', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE users SET last_hotel = NULL WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	})
end)

RegisterServerEvent('ilyes_hotel:getItem')
AddEventHandler('ilyes_hotel:getItem', function(owner, type, item, count)
	local _source      = source
	local xPlayer      = ESX.GetPlayerFromId(_source)
	local xPlayerOwner = ESX.GetPlayerFromIdentifier(owner)

	if type == 'item_standard' then

		local sourceItem = xPlayer.getInventoryItem(item)

		TriggerEvent('esx_addoninventory:getInventory', 'hotel', xPlayerOwner.identifier, function(inventory)
			local inventoryItem = inventory.getItem(item)

			-- is there enough in the hotel?
			if count > 0 and inventoryItem.count >= count then
			
				-- can the player carry the said amount of x item?
				if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
					TriggerClientEvent('esx:showNotification', _source, _U('player_cannot_hold'))
				else
					inventory.removeItem(item, count)
					xPlayer.addInventoryItem(item, count)
					TriggerClientEvent('esx:showNotification', _source, _U('have_withdrawn', count, inventoryItem.label))
				end
			else
				TriggerClientEvent('esx:showNotification', _source, _U('not_enough_in_hotel'))
			end
		end)

	elseif type == 'item_account' then

		TriggerEvent('esx_addonaccount:getAccount', 'hotel_' .. item, xPlayerOwner.identifier, function(account)
			local roomAccountMoney = account.money

			if roomAccountMoney >= count then
				account.removeMoney(count)
				xPlayer.addAccountMoney(item, count)
			else
				TriggerClientEvent('esx:showNotification', _source, _U('amount_invalid'))
			end
		end)

	elseif type == 'item_weapon' then

		TriggerEvent('esx_datastore:getDataStore', 'hotel', xPlayerOwner.identifier, function(store)
			local storeWeapons = store.get('weapons') or {}
			local weaponName   = nil
			local ammo         = nil

			for i=1, #storeWeapons, 1 do
				if storeWeapons[i].name == item then
					weaponName = storeWeapons[i].name
					ammo       = storeWeapons[i].ammo

					table.remove(storeWeapons, i)
					break
				end
			end

			store.set('weapons', storeWeapons)
			xPlayer.addWeapon(weaponName, ammo)
		end)

	end

end)

RegisterServerEvent('ilyes_hotel:putItem')
AddEventHandler('ilyes_hotel:putItem', function(owner, type, item, count)
	local _source      = source
	local xPlayer      = ESX.GetPlayerFromId(_source)
	local xPlayerOwner = ESX.GetPlayerFromIdentifier(owner)

	if type == 'item_standard' then

		local playerItemCount = xPlayer.getInventoryItem(item).count

		if playerItemCount >= count and count > 0 then
			TriggerEvent('esx_addoninventory:getInventory', 'hotel', xPlayerOwner.identifier, function(inventory)
				xPlayer.removeInventoryItem(item, count)
				inventory.addItem(item, count)
				TriggerClientEvent('esx:showNotification', _source, _U('have_deposited', count, inventory.getItem(item).label))
			end)
		else
			TriggerClientEvent('esx:showNotification', _source, _U('invalid_quantity'))
		end

	elseif type == 'item_account' then

		local playerAccountMoney = xPlayer.getAccount(item).money

		if playerAccountMoney >= count and count > 0 then
			xPlayer.removeAccountMoney(item, count)

			TriggerEvent('esx_addonaccount:getAccount', 'hotel_' .. item, xPlayerOwner.identifier, function(account)
				account.addMoney(count)
			end)
		else
			TriggerClientEvent('esx:showNotification', _source, _U('amount_invalid'))
		end

	elseif type == 'item_weapon' then

		TriggerEvent('esx_datastore:getDataStore', 'hotel', xPlayerOwner.identifier, function(store)
			local storeWeapons = store.get('weapons') or {}

			table.insert(storeWeapons, {
				name = item,
				ammo = count
			})

			store.set('weapons', storeWeapons)
			xPlayer.removeWeapon(item)
		end)

	end

end)

ESX.RegisterServerCallback('ilyes_hotel:getOwnedhotels', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_hotels WHERE owner = @owner', {
	['@owner'] = xPlayer.identifier
	}, function(ownedhotels)
		local hotels = {}

		for i=1, #ownedhotels, 1 do
			table.insert(hotels, ownedhotels[i].name)
		end

		cb(hotels)
	end)
end)

ESX.RegisterServerCallback('ilyes_hotel:getLasthotel', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT last_hotel FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(users)
		cb(users[1].last_hotel)
	end)
end)

ESX.RegisterServerCallback('ilyes_hotel:gethotelInventory', function(source, cb, owner)
	local xPlayer    = ESX.GetPlayerFromIdentifier(owner)
	local blackMoney = 0
	local items      = {}
	local weapons    = {}

	TriggerEvent('esx_addonaccount:getAccount', 'hotel_black_money', xPlayer.identifier, function(account)
		blackMoney = account.money
	end)

	TriggerEvent('esx_addoninventory:getInventory', 'hotel', xPlayer.identifier, function(inventory)
		items = inventory.items
	end)

	TriggerEvent('esx_datastore:getDataStore', 'hotel', xPlayer.identifier, function(store)
		weapons = store.get('weapons') or {}
	end)

	cb({
		blackMoney = blackMoney,
		items      = items,
		weapons    = weapons
	})
end)

ESX.RegisterServerCallback('ilyes_hotel:getPlayerInventory', function(source, cb)
	local xPlayer    = ESX.GetPlayerFromId(source)
	local blackMoney = xPlayer.getAccount('black_money').money
	local items      = xPlayer.inventory

	cb({
		blackMoney = blackMoney,
		items      = items,
		weapons    = xPlayer.getLoadout()
	})
end)

ESX.RegisterServerCallback('ilyes_hotel:getPlayerDressing', function(source, cb)
	local xPlayer  = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'hotel', xPlayer.identifier, function(store)
		local count  = store.count('dressing')
		local labels = {}

		for i=1, count, 1 do
			local entry = store.get('dressing', i)
			table.insert(labels, entry.label)
		end

		cb(labels)
	end)
end)

ESX.RegisterServerCallback('ilyes_hotel:getPlayerOutfit', function(source, cb, num)
	local xPlayer  = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'hotel', xPlayer.identifier, function(store)
		local outfit = store.get('dressing', num)
		cb(outfit.skin)
	end)
end)

RegisterServerEvent('ilyes_hotel:removeOutfit')
AddEventHandler('ilyes_hotel:removeOutfit', function(label)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'hotel', xPlayer.identifier, function(store)
		local dressing = store.get('dressing') or {}

		table.remove(dressing, label)
		store.set('dressing', dressing)
	end)
end)

function PayRent(d, h, m)
	MySQL.Async.fetchAll('SELECT * FROM owned_hotels WHERE rented = 1', {}, function (result)
		for i=1, #result, 1 do
			local xPlayer = ESX.GetPlayerFromIdentifier(result[i].owner)

			-- message player if connected
			if xPlayer then
				xPlayer.removeAccountMoney('bank', result[i].price)
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('paid_rent', ESX.Math.GroupDigits(result[i].price)))
			else -- pay rent either way
				MySQL.Sync.execute('UPDATE users SET bank = bank - @bank WHERE identifier = @identifier',
				{
					['@bank']       = result[i].price,
					['@identifier'] = result[i].owner
				})
			end

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_realestateagent', function(account)
				account.addMoney(result[i].price)
			end)
		end
	end)
end

TriggerEvent('cron:runAt', 22, 0, PayRent)