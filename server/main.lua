AddEventHandler('mythic_base:shared:ComponentsReady', function()
    Callbacks = exports['mythic_base']:FetchComponent('Callbacks')

    Callbacks:RegisterServerCallback('mythic_hud:server:GetMoneyStuff', function(source, data, cb)
        cData = exports['mythic_base']:FetchComponent('Fetch'):Source(source):GetData('character'):GetData()
        cb({ cash = cData.cash, bank = cData.bank })
    end)
end)