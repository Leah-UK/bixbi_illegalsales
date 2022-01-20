ESX = nil
TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)

RegisterServerEvent('bixbi_illegalsales:Sale')
AddEventHandler('bixbi_illegalsales:Sale', function(zone, item)
    local random = math.random(1, Config.FailChance)
    if (random == 1) then
        TriggerClientEvent('bixbi_core:Notify', source, 'error', 'The person isn\'t interested in your items.', 5000)
        random = math.random(1, Config.AlertChance)
        local notifyPolice = false
        if (random == 1) then notifyPolice = true end
        TriggerClientEvent('bixbi_illegalsales:FailedAttempt', source, notifyPolice)
    else
        SuccessfulAttempt(source, zone, item)
    end
end)

function SuccessfulAttempt(source, zone, item)
    local configItem = Config.Items[item]
    if (configItem == nil) then return end
    local qtySell = math.random(configItem.low_count, configItem.high_count)

    if (Config.UseBixbiTerritories) then
        TriggerClientEvent('bixbi_illegalsales:SuccessfulAttempt', source)
    else
        if (Config.Locations[zone][item] == nil and Config.RestrictToLocations) then
            TriggerClientEvent('bixbi_core:Notify', source, 'error', 'You cannot sell this here.')
            return
        end

        local itemCount = exports.bixbi_core:sv_itemCount(source, item)
        if (itemCount ~= nil and itemCount < qtySell) then qtySell = itemCount end
        if (qtySell == nil or qtySell == 0 or itemCount == nil) then
            TriggerClientEvent('bixbi_core:Notify', source, 'error', 'Do you even have the items to do this?')
            return 
        end

        TriggerClientEvent('bixbi_illegalsales:SuccessfulAttempt', source)
        local payment = qtySell * (math.random(configItem.price_low, configItem.price_high))
        exports.bixbi_core:removeItem(source, item, qtySell)
        exports.bixbi_core:addItem(source, Config.MoneyItem, payment)
        TriggerClientEvent('bixbi_core:Notify', source, '', 'You have received ' .. Config.CurrencySymbol .. payment, 10000)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
	if (GetResourceState('bixbi_core') ~= 'started' ) then
        print('bixbi_illegalsales - ERROR: Bixbi_Core hasn\'t been found! This could cause errors!')
    end
end)