if Config.Framework ~= 'QBCORE' then return end

FrameworkClient = FrameworkClient or {}

function FrameworkClient.OnPlayerLoaded()
	local core = exports['qb-core']:GetCoreObject()
	local PlayerData = core.Functions.GetPlayerData()
	TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
	TriggerEvent('QBCore:Client:OnPlayerLoaded')
	local insideMeta = PlayerData.metadata and PlayerData.metadata['inside']
	if insideMeta then
		if insideMeta.house ~= nil then
			TriggerEvent('qb-houses:client:LastLocationHouse', insideMeta.house)
		elseif insideMeta.apartment and (insideMeta.apartment.apartmentType ~= nil or insideMeta.apartment.apartmentId ~= nil) then
			if Config.ApartmentSystem == 'qb-apartments' then
				TriggerEvent('qb-apartments:client:LastLocationHouse', insideMeta.apartment.apartmentType, insideMeta.apartment.apartmentId)
			end
		end
	end
end
