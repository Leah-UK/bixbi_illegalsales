ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(10)
    end
end)

local enableSale, inSaleAttempt = false, false
local sellingDrug, targetPed, lastTargetPed, locationInfo, locationName = nil, nil, nil, nil, nil
local lastTargetPeds = {}
-- local ped = nil
function LocationCheckLoop()
	Citizen.CreateThread(function()
        while true do
            if (locationName ~= GetNameOfZone(GetEntityCoords(PlayerPedId()))) then
                CancelSelling()
                return
            end

            Citizen.Wait(30000)
        end
    end)
end

function CreateTarget()
	exports.qtarget:Ped({
		options = {
			{
				event = "bixbi_illegalsales:AttemptSale",
				icon = "fas fa-money-bill-wave",
				label = "Sell Items",
				canInteract = function(entity)
                    if IsPedDeadOrDying(entity, true) or IsPedAPlayer(entity) or GetPedType(entity) == 28 then return false end
					return true
                end, 
			},
		},
		distance = 3.0
	})
end
function DeleteTarget()
	exports.qtarget:RemovePed({'Sell Items'})
end

-- RegisterNetEvent('bixbi_illegalsales:AttemptSale')
AddEventHandler('bixbi_illegalsales:AttemptSale', function(data)
	locationInfo = nil
	if (locationName ~= GetNameOfZone(GetEntityCoords(PlayerPedId()))) then
		CancelSelling()
		return
	end

	if lastTargetPeds[data.entity] then
		exports['bixbi_core']:Notify('error', 'You\'ve already sold to this person.')
	else
		SaleAttempt(data.entity)
	end
end)

RegisterNetEvent('bixbi_illegalsales:FailedAttempt')
AddEventHandler('bixbi_illegalsales:FailedAttempt', function(notify)
    local playerPed = PlayerPedId()
	if (notify) then
        exports['bixbi_core']:playAnim(targetPed, 'cellphone@', 'cellphone_text_read_base', -1)

        TriggerServerEvent('bixbi_dispatch:Add', GetPlayerServerId(PlayerId()), 'police', 'drugsale', 'Someone has reported a drug sale.', GetEntityCoords(playerPed))

        Citizen.Wait(4000)
        exports['bixbi_core']:Notify('error', 'Someone has notified the police of your activities.', 5000)
    end

    SetBlockingOfNonTemporaryEvents(targetPed, false)
    ClearPedTasks(playerPed)
    ClearPedTasks(targetPed)

    inSaleAttempt = false
end)

RegisterNetEvent('bixbi_illegalsales:SuccessfulAttempt')
AddEventHandler('bixbi_illegalsales:SuccessfulAttempt', function()
    local playerPed = PlayerPedId()

    TaskTurnPedToFaceEntity(targetPed, playerPed, 2000)
    TaskTurnPedToFaceEntity(playerPed, targetPed, 2000)
    exports['bixbi_core']:playAnim(targetPed, 'mp_common', 'givetake1_a', -1)
    exports['bixbi_core']:playAnim(playerPed, 'mp_common', 'givetake1_a', -1)
    Citizen.Wait(2000)

    SetBlockingOfNonTemporaryEvents(ped, false)
    ClearPedTasks(playerPed)
    ClearPedTasks(targetPed)

    inSaleAttempt = false
end)

function SaleAttempt(ped)
	local playerPed = PlayerPedId()
	targetPed = ped
	lastTargetPeds[ped] = true
	inSaleAttempt = true

	Citizen.CreateThread(function()
		TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_DRUG_DEALER_HARD', 0, true) 
		SetBlockingOfNonTemporaryEvents(ped, true)
		
		TaskTurnPedToFaceEntity(ped, playerPed, Config.AttemptSaleTime * 1000)
		TaskTurnPedToFaceEntity(playerPed, ped, Config.AttemptSaleTime * 1000)
		exports['bixbi_core']:playAnim(playerPed, 'missfbi1ig_1_alt_1', 'conversation1_peda', -1)
		exports['bixbi_core']:Loading(Config.AttemptSaleTime * 1000, 'Attempting to sell items.')
		Citizen.Wait(Config.AttemptSaleTime * 1000)

		ClearPedTasks(playerPed)
		if (inSaleAttempt and PedChecks()) then
            TriggerServerEvent('bixbi_illegalsales:Sale', GetNameOfZone(GetEntityCoords(playerPed)), sellingDrug)
		end
	end)
end

function PedChecks()
    if (targetPed == nil or IsPedDeadOrDying(targetPed, true) or not DoesEntityExist(targetPed)) then
        exports['bixbi_core']:Notify('error', 'The person has died.', 5000)
        return false
    else
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local pedCoords = GetEntityCoords(targetPed)
        local dist = #(playerCoords - pedCoords)
        if (dist > 6.0) then
            exports['bixbi_core']:Notify('error', 'The person cannot hear what you\'re saying. You\'re too far away.', 8000)
            return false
        end
    end
    return true
end

function CancelSelling()
	sellingDrug = nil
	locationName = nil

	if (enableSale) then
		enableSale = false
		exports['bixbi_core']:Notify('error', 'You are no longer attempting to sell illegal items.', 10000)
	end

	DeleteTarget()
end

if (Config.MenuKeybind ~= nil) then RegisterKeyMapping(Config.MenuCommand, 'Illegal Menu', 'keyboard', Config.MenuKeybind) end
RegisterCommand(Config.MenuCommand, function()
    DrugMenu()
end, false)

if (not Config.UseBixbiTerritories) then
    RegisterCommand('territory', function()
        local zoneName = GetNameOfZone(GetEntityCoords(PlayerPedId()))
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"TERRITORY ", 'Territory name: ' .. zoneName}
        })
    end)
end

AddEventHandler('bixbi_illegalsales:DrugMenu', function()
	DrugMenu()
end)
function DrugMenu()
    ESX.TriggerServerCallback('bixbi_core:illegalTaskBlacklist', function(result)
        if (result) then return end
        ESX.UI.Menu.CloseAll()

        if (Config.UseBixbiTerritories) then
            local playerPed = PlayerPedId()
            ESX.TriggerServerCallback('bixbi_territories:locationCheck', function(result)
                while (result == nil) do Citizen.Wait(100) end
                
                if (result == nil or result == false) then
                    exports['bixbi_core']:Notify('error', 'You are not in a contested territory.')
                elseif (string.lower(result.location) ~= string.lower(GetNameOfZone(GetEntityCoords(playerPed)))) then
                    exports['bixbi_core']:Notify('error', 'Your location information hasn\'t updated yet.')
                else
                    CreateMenu(result)
                end
            end, GetNameOfZone(GetEntityCoords(playerPed)))
        else
            CreateMenu(nil)
        end
    end)
end

function CreateMenu(locationInfo)
    local elements = {}
    if (string.lower(Config.MenuType) == 'zf') then
        elements = {
            {
                id = 1,
                header = 'Illegal Menu',
                txt = ' '
            }
        }

        if (Config.UseBixbiTerritories) then table.insert(elements, { id = 2, header = ' ', txt = 'Territory Information', params = { event = 'bixbi_territories:TerritoryInfoMenu' }}) end
        if (not enableSale) then
            table.insert(elements, {id = 3, header = ' ', txt = 'Start Selling', params = { event = 'bixbi_illegalsales:SellingToggle', args = { start = true, locationInfo = locationInfo }}})
        else
            table.insert(elements, {id = 3, header = ' ', txt = 'Stop Selling', params = { event = 'bixbi_illegalsales:SellingToggle', args = { start = false }}})
        end 

    else
        if (Config.UseBixbiTerritories) then table.insert(elements, {label = 'Territory Information', value = 'territory_info'}) end
        if (not enableSale) then
            table.insert(elements, {label = 'Start Selling', value = 'sell'})
        else
            table.insert(elements, {label = 'Stop Selling', value = 'stop_sell'})
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'drugmenu', {
            title    = 'Sale Management',
            align    = 'right',
            elements = elements
        }, function(data, menu)	
            if data.current.value == 'territory_info' then
                exports['bixbi_territories']:TerritoryInfoMenu()
            elseif data.current.value == 'sell' then
                ChooseDrugMenu(locationInfo)
            elseif data.current.value == 'stop_sell' then
                CancelSelling()
            end
        end, function(data, menu)
            menu.close()
        end)
    end
end

AddEventHandler('bixbi_illegalsales:SellingToggle', function(data)
	if (data.start) then
        ChooseDrugMenu(data.locationInfo)
    else
        CancelSelling()
    end
end)

function ChooseDrugMenu(locationInfo)
    local playerPed = PlayerPedId()
	local elements = {}
	if (Config.UseBixbiTerritories) then
		for _,v in pairs(locationInfo.illegalitems) do
			table.insert(elements, {label = string.upper(Config.Items[v].label) .. ' | ' .. Config.CurrencySymbol .. Config.Items[v].price_low  .. '-' .. Config.Items[v].price_high .. 'ea (rrp)', value = v})
		end
	else
        local locationDrugs = Config.Locations[GetNameOfZone(GetEntityCoords(playerPed))]
        if (locationDrugs ~= nil) then
            for k,_ in pairs(locationDrugs) do
                local drug = Config.Items[k]
                table.insert(elements, {label = string.upper(drug.label) .. ' | ' .. Config.CurrencySymbol .. drug.price_low .. '-' .. drug.price_high .. 'ea (rrp)', value = k})
            end
        else
            exports.bixbi_core:Notify('error', 'You cannot sell anything in this area.')
            return
        end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'choosedrug', {
		title    = 'Choose Item',
		align    = 'right',
		elements = elements
	}, function(data, menu)

		sellingDrug = string.lower(data.current.value)
		enableSale = true
		locationName = GetNameOfZone(GetEntityCoords(playerPed))
		LocationCheckLoop()
		CreateTarget()

		exports['bixbi_core']:Notify('', 'You are now selling ' .. data.current.label)
		ESX.UI.Menu.CloseAll()
	end, function(data, menu)
		menu.close()
	end)
end
--[[--------------------------------------------------
Setup
--]]--------------------------------------------------
RegisterNetEvent('esx:playerLoaded')
AddEventHandler("esx:playerLoaded", function(xPlayer)
	while (ESX == nil) do Citizen.Wait(100) end
	ESX.PlayerData = xPlayer
 	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
	ESX.PlayerLoaded = false
	ESX.PlayerData = {}
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	if (keepChecking) then CancelSelling() end
end)
