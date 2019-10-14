RegisterServerEvent('mythic_hud:server:GetMoneyStuff')
AddEventHandler('mythic_hud:server:GetMoneyStuff', function()
    local cData = {}
    while exports['mythic_base']:FetchComponent('Fetch'):Source(source) == nil do
        Citizen.Wait(0)
    end
    while exports['mythic_base']:FetchComponent('Fetch'):Source(source):GetData('character') == nil do
        Citizen.Wait(0)
    end
    cData = exports['mythic_base']:FetchComponent('Fetch'):Source(source):GetData('character'):GetData()
    TriggerClientEvent('mythic_hud:client:DisplayMoneyStuff', source, cData.cash, cData.bank)
end)