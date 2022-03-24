ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj 

   RegisterCommand("recon", function(source, args, user)
        TriggerClientEvent('hrp_spectate:spectate', source, target)
   end)
    
    
    ESX.RegisterServerCallback('hrp_spectate:getPlayerGroup', function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then
            cb('')
            return
        end
        local g = xPlayer.getGroup()
        print(g)
        cb(g)
    end)


    ESX.RegisterServerCallback('hrp_spectate:getAllPlayers', function(source, cb)
        local players = {}
        for _, serverId in pairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(serverId)
        local tbl = {}
        local Players = ESX.GetPlayers()
        local job = xPlayer.getJob()
		local jobText = job.label .. " - " .. job.grade_label
        for _,id in ipairs(Players) do
            table.insert(tbl, {id = id, name = GetPlayerName(id), jobText = jobText, money = xPlayer.getMoney(), bank = xPlayer.getAccount('bank').money,})
        end
        cb(tbl)
    end
    end)


    ESX.RegisterServerCallback('hrp_spectate:getPlayerData', function(source, cb, id)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getGroup() ~= 'user' then
            local targetPlayer = ESX.GetPlayerFromId(id)
            if targetPlayer ~= nil then
                cb(targetPlayer)
            end
        else
            DropPlayer(source, "hrp_spectate: you're not authorized to spectate people dummy.")
            cb('user')
        end
    end)
    
    ESX.RegisterServerCallback('hrp_spectate:getPlayerCoords', function(source, cb, id)
        local targetEntity = GetPlayerPed(id) 
        if DoesEntityExist(targetEntity) then
            cb(GetEntityCoords(targetEntity))
        else
            cb(nil)
        end
    end)
    
    RegisterServerEvent('hrp_spectate:kick')
    AddEventHandler('hrp_spectate:kick', function(target, msg)
        local xPlayer = ESX.GetPlayerFromId(source)
    
        if xPlayer.getGroup() ~= 'user' then
            DropPlayer(target, msg)
        else
            print(('hrp_spectate: %s attempted to kick a player!'):format(xPlayer.identifier))
            DropPlayer(source, "hrp_spectate: you're not authorized to kick people dummy.")
        end
    end)

    RegisterServerEvent('hrp_spectate:log')
    AddEventHandler('hrp_spectate:log', function(data)
        if not GetPlayerPed(data.target) then
            return
        end
        local entPos = GetEntityCoords(GetPlayerPed(data.target))
        -- SendDiscordLog(source, 'spectate', {
        --     author = { name = GetPlayerName(source) .. ' ['..source..']' },
        --     color = 0xffff00,
        --     title = message,
        --     fields = {
        --         { inline = true, name = 'target', value = GetPlayerName(data.target)..' ['..data.target..']' },
        --         { inline = true, name = 'targetPos', value = ('%.2f %.2f %.2f'):format(entPos.x, entPos.y, entPos.z) },
        --     },
        --     timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
        -- })
    end)
    
    ESX.RegisterServerCallback('hrp_spectate:getOtherPlayerData', function(source, cb, target)
        local xPlayer = ESX.GetPlayerFromId(target)
        if xPlayer ~= nil then
            -- local identifier = GetPlayerIdentifiers(target)[1]
            local identifier
            for k,v in ipairs(GetPlayerIdentifiers(target))do
                if string.sub(v, 1, string.len("license:")) == "license:" then
                    identifier = v:sub(9)
                    break
                end
            end
            

            local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {
                ['@identifier'] = identifier
            })
            --print('^3result',json.encode(result),'^0')


            local user = result[1]
            local firstname = user['firstname']
            local lastname = user['lastname']
            local sex = user['sex']
            local dob = user['dateofbirth']
            local height = user['height'] .. " Centimetri"
            local money = json.decode(user['accounts']).money
            -- local money = user['money']
            local bank = json.decode(user['accounts']).bank
            local blackMoney = json.decode(user['accounts']).black_money
            -- local bank = user['bank']
            
            local data = {
                name = GetPlayerName(target),
                job = xPlayer.job,
                inventory = xPlayer.inventory,
                accounts = xPlayer.accounts,
                weapons = xPlayer.loadout,
                firstname = firstname,
                lastname = lastname,
                sex = sex,
                dob = dob,
                height = height,
                money = money,
                bank = bank,
                blackMoney = blackMoney
            }
            cb(data)
            -- TriggerEvent('esx_license:getLicenses', target, function(licenses)
            --     data.licenses = licenses
            --     cb(data)
            -- end)
        end
    end)

end)
    