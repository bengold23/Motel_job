ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_phone:registerNumber', 'maitrehotel', _U('client'), false, false)
TriggerEvent('esx_society:registerSociety', 'maitrehotel', _U('realtors'), 'society_maitrehotel', 'society_maitrehotel', 'society_maitrehotel', {type = 'private'})

RegisterServerEvent('maitre_d_hoteljob:revoke')
AddEventHandler('maitre_d_hoteljob:revoke', function(hotel, owner)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'maitrehotel' then
		TriggerEvent('ilyes_hotel:removeOwnedhotelIdentifier', hotel, owner)
	else
		print(('maitre_d_hoteljob: %s attempted to revoke a hotel!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('maitre_d_hoteljob:sell')
AddEventHandler('maitre_d_hoteljob:sell', function(target, hotel, price)
	local xPlayer, xTarget = ESX.GetPlayerFromId(source), ESX.GetPlayerFromId(target)

	if xPlayer.job.name ~= 'maitrehotel' then
		print(('maitre_d_hoteljob: %s attempted to sell a hotel!'):format(xPlayer.identifier))
		return
	end

	if xTarget.getMoney() >= price then
		xTarget.removeMoney(price)

		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_maitrehotel', function(account)
			account.addMoney(price)
		end)
	
		TriggerEvent('ilyes_hotel:sethotelOwned', hotel, price, false, xTarget.identifier)
	else
		TriggerClientEvent('esx:showNotification', xPlayer.source, _U('client_poor'))
	end
end)

RegisterServerEvent('maitre_d_hoteljob:rent')
AddEventHandler('maitre_d_hoteljob:rent', function(target, hotel, price)
	local xPlayer = ESX.GetPlayerFromId(target)

	TriggerEvent('ilyes_hotel:sethotelOwned', hotel, price, true, xPlayer.identifier)
end)

ESX.RegisterServerCallback('maitre_d_hoteljob:getCustomers', function(source, cb)
	TriggerEvent('esx_ownedhotel:getOwnedhotels', function(hotels)
		local xPlayers  = ESX.GetPlayers()
		local customers = {}

		for i=1, #hotels, 1 do
			for j=1, #xPlayers, 1 do
				local xPlayer = ESX.GetPlayerFromId(xPlayers[j])

				if xPlayer.identifier == hotels[i].owner then
					table.insert(customers, {
						name           = xPlayer.name,
						hotelOwner  = hotels[i].owner,
						hotelRented = hotels[i].rented,
						hotelId     = hotels[i].id,
						hotelPrice  = hotels[i].price,
						hotelName   = hotels[i].name,
						hotelLabel  = hotels[i].label
					})
				end
			end
		end

		cb(customers)
	end)
end)
