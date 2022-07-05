ESX, db_loaded = nil, false
MDT = {}
MDT.Bolos = {}
MDT.Infos = {}
MDT.Vehicles = {}
MDT.Actions = {}
MDT.Wanted = {}
MDT.Dispatches = {}
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand("mdt", function(source)
    local player = ESX.GetPlayerFromId(source)
    if player.job.name == "police" then
        TriggerClientEvent("fizzfau-mdt:client:open", source)
    end
end)

function GetCops()
    local cops = {}
    local players = ESX.GetPlayers()
    for i =1, #players do
        local player = ESX.GetPlayerFromId(players[i])
        if player then
            if player.job.name == "police" then
                cops[i] = {
                    name = player.get("firstName").. ' ' .. player.get("lastName"),
                    rank = player.job.grade_label
                }
            end
        end
    end
    return cops
end

function DiscordLog(data, name, type)
    if Config.Discord then
        local ts = os.time()
        local time = os.date('%Y-%m-%d %H:%M', ts)
        local connect = {
            {
                ["color"] = 1582405,
                ["title"] = "**".. data.title .."**",
                ["description"] = data.text,
                ["thumbnail"] = {
                    ["url"] = data.image or "https://cdn.discordapp.com/attachments/790299717425954858/813151895010017299/lspd-png-7-Transparent-Images.png"
                },
                ["footer"] = {
                    ["text"] = "Officer " ..name.. " • " ..time,
                    ["icon_url"] = "https://cdn.discordapp.com/attachments/790299717425954858/813151895010017299/lspd-png-7-Transparent-Images.png",
                },
            }
        }
        PerformHttpRequest(Config.Webhooks[type], function(err, text, headers) end, 'POST', json.encode({username = data.officer or "fizzfau-mdt", embeds = connect}), { ['Content-Type'] = 'application/json' })
    end
end

exports.ghmattimysql:ready(function()
    local result = exports.ghmattimysql:executeSync("SELECT * FROM mdt_general")
    if result[1] ~= nil then
        MDT.Actions = json.decode(result[1].actions)
        MDT.Wanted = json.decode(result[1].wanted_list)
        db_loaded = true
    end
end)

RegisterServerEvent("fizzfau-mdt:getPolices")
AddEventHandler("fizzfau-mdt:getPolices", function()
    TriggerClientEvent("fizzfau-mdt:client:getPolices", source, GetCops())
end)

RegisterServerEvent("fizzfau-mdt:server:setupMDT")
AddEventHandler("fizzfau-mdt:server:setupMDT", function()
    --while not db_loaded do; Citizen.Wait(100); end
    TriggerClientEvent("fizzfau-mdt:client:setupMDT", source, MDT)
end)

RegisterServerEvent("fizzfau-mdt:server:search-citizen")
AddEventHandler("fizzfau-mdt:server:search-citizen", function(result)
    local data = false
    local src = source
    local result = exports.ghmattimysql:executeSync("SELECT * FROM users WHERE CONCAT(firstname, ' ', lastname) LIKE '%"..result.."%' OR phone_number LIKE '%"..result.."%'")
    if result[1] then
        data = result
    end
    for i =1, #result do
        result[i].accounts = json.decode(result[i].accounts)
        result[i].job = ESX.Jobs[result[i].job].label
        if result[i].sex == "m" then
            result[i].sex = Config.Texts["male"]
        else
            result[i].sex = Config.Texts["female"]
        end
    end
    TriggerClientEvent("fizzfau-mdt:client:search-citizen", src, data)
end)

RegisterServerEvent("fizzfau-mdt:server:search-vehicle")
AddEventHandler("fizzfau-mdt:server:search-vehicle", function(result)
    local data = false
    local src = source
    local results = exports.ghmattimysql:executeSync("SELECT * FROM owned_vehicles WHERE plate LIKE '%"..result:upper().."%' OR modelname LIKE '%"..result.."%'")
    if results[1] ~= nil then
        data = results
        for i =1, #data do
            local result2 = exports.ghmattimysql:executeSync("SELECT * FROM users WHERE identifier LIKE '%"..data[i].owner.."%'")
            data[i].owner_name = result2[1].firstname.. " " ..result2[1].lastname
        end
    end
    TriggerClientEvent("fizzfau-mdt:client:search-vehicle", src, data)
end)

RegisterServerEvent("fizzfau-mdt:server:server:getInfo")
AddEventHandler("fizzfau-mdt:server:server:getInfo", function(identifier)
    local src = source
    local info = {
        info = nil,
        bolos = nil,
        vehicles = nil
    }
    local results = exports.ghmattimysql:executeSync("SELECT info, bolos FROM mdt_warrants WHERE identifier = '" ..identifier.. "'")
    local vehicles = exports.ghmattimysql:executeSync("SELECT plate, modelname FROM owned_vehicles WHERE owner = '" ..identifier.. "'")
    if results[1] ~= nil then
        if results[1].info ~= nil then
            results[1].info = json.decode(results[1].info)
            info.info = results[1].info
        end
        if results[1].bolos ~= nil then
            results[1].bolos = json.decode(results[1].bolos)    
            info.bolos = results[1].bolos
        end
    end
    info.vehicles = vehicles
    MDT.Bolos[identifier] = info.bolos
    MDT.Infos[identifier] = info.info
    MDT.Vehicles[identifier] = info.vehicles
    TriggerClientEvent("fizzfau-mdt:server:client:getInfo", src, info, identifier)
end)

RegisterServerEvent("fizzfau-mdt:server:delete-record")
AddEventHandler("fizzfau-mdt:server:delete-record", function(data, myName)
    local src = source
    local notes_temp
    local bolos_temp
    local ts = os.time()
    local time = os.date('%Y-%m-%d %H:%M', ts)
    local info = {
        info = false,
        bolos = false,
        vehicles = MDT.Vehicles[data.identifier]
    }
    
    if data.type == "notes" then
        for k,v in pairs(MDT.Infos[data.identifier]) do
            local id = tonumber(string.sub(data.id, 7))
            if tonumber(k) == id then
                MDT.Infos[data.identifier][k] = nil
                local notes = nil
                if next(MDT.Infos[data.identifier]) ~= nil then
                    notes = json.encode(MDT.Infos[data.identifier])
                    notes_temp = MDT.Infos[data.identifier]
                end
                local retval = false

                if (MDT.Infos[data.identifier] ~= nil and MDT.Bolos[data.identifier] ~= nil) then
                    if ((next(MDT.Infos[data.identifier])) == nil and next(MDT.Bolos[data.identifier]) == nil) then
                        retval = true
                    end
                end
                
                if (MDT.Infos[data.identifier] == nil and MDT.Bolos[data.identifier] == nil) or retval then
                    MDT.Bolos[data.identifier] = nil
                    MDT.Infos[data.identifier] = nil
                    exports.ghmattimysql:execute("DELETE FROM mdt_warrants WHERE identifier = '" ..data.identifier.. "'")
                else
                    exports.ghmattimysql:execute("UPDATE mdt_warrants SET info = @notes WHERE identifier = '" ..data.identifier.. "'", {
                        ["@notes"] = notes
                    })
                end
                info.info =        notes_temp
                info.bolos = "update"
                Citizen.Wait(500)
                local action = {type = "Deleted Note", time = time, name = myName}
                AddAction(action)
                TriggerClientEvent("fizzfau-mdt:server:client:getInfo", src, info, data.identifier)
                break
            end
        end
    else
        for k,v in pairs(MDT.Bolos[data.identifier]) do
            local id = tonumber(string.sub(data.id, 7))
            if tonumber(k) == id then
                MDT.Bolos[data.identifier][k] = nil
                local bolos = nil
                if next(MDT.Bolos[data.identifier]) ~= nil then
                    bolos = json.encode(MDT.Bolos[data.identifier])
                    bolos_temp = MDT.Bolos[data.identifier]
                end

                local retval = false

                if (MDT.Infos[data.identifier] ~= nil and MDT.Bolos[data.identifier] ~= nil) then
                    if ((next(MDT.Infos[data.identifier])) == nil and next(MDT.Bolos[data.identifier]) == nil) then
                        retval = true
                    end
                end

                if (MDT.Infos[data.identifier] == nil and MDT.Bolos[data.identifier] == nil) or retval then
                    exports.ghmattimysql:execute("DELETE FROM mdt_warrants WHERE identifier = '" ..data.identifier.. "'")
                    MDT.Bolos[data.identifier] = nil
                    MDT.Infos[data.identifier] = nil
                else
                    exports.ghmattimysql:execute("UPDATE mdt_warrants SET bolos = @bolos WHERE identifier = '" ..data.identifier.. "'", {
                        ["@bolos"] = bolos
                    })
                end
                info.bolos =       bolos_temp  
                info.info = "update"
                Citizen.Wait(500)
                local action = {type = "Deleted Bolo", time = time, name = myName}
                AddAction(action)
                TriggerClientEvent("fizzfau-mdt:server:client:getInfo", src, info, data.identifier)
                break
            end
        end
    end
end) 


RegisterServerEvent("fizzfau-mdt:server:add-note")
AddEventHandler("fizzfau-mdt:server:add-note", function(data, myName)
    local id = data.id
    local text = data.value
    local image = data.image
    local src = source
    local ts = os.time()
    local time = os.date('%Y-%m-%d %H:%M', ts)
    local info = {
        info = nil,
        bolos = "update",
        vehicles = MDT.Vehicles[data.identifier]
    }
    if (MDT.Infos[data.identifier]) == nil and (MDT.Bolos[data.identifier]) == nil  then
        MDT.Infos[data.identifier] = {}
        if MDT.Infos[data.identifier][id] == nil then
            MDT.Infos[data.identifier][id] = text
            exports.ghmattimysql:execute("INSERT INTO mdt_warrants (identifier, info) VALUES (@identifier, @info)", {
                ["@identifier"] = data.identifier,
                ["@info"] = json.encode(MDT.Infos[data.identifier])
            })
            local action = {type = "Created Note", time = time, name = myName}
            AddAction(action)
            DiscordLog({title = "Note - " ..data.citizen_name, text = " \n" ..text, image = image}, myName, "note")
            info.info = MDT.Infos[data.identifier]
            TriggerClientEvent("fizzfau-mdt:server:client:getInfo", src, info, data.identifier)
        end
    else
        if  MDT.Infos[data.identifier] == false or MDT.Infos[data.identifier] == nil then 
            MDT.Infos[data.identifier] = {}
        end
        if MDT.Infos[data.identifier][id] == nil then
            MDT.Infos[data.identifier][id] = text
            
            exports.ghmattimysql:execute("UPDATE mdt_warrants SET info = @notes WHERE identifier = '" ..data.identifier.. "'", {
                ["@notes"] = json.encode(MDT.Infos[data.identifier])
            })
            local action = {type = "Created Note", time = time, name = myName}
            AddAction(action)
            DiscordLog({title = "Note - " ..data.citizen_name, text = " \n" ..text, image = image}, myName, "note")
            info.info =        MDT.Infos[data.identifier]
            TriggerClientEvent("fizzfau-mdt:server:client:getInfo", src, info, data.identifier)
        end
    end 
end)

RegisterServerEvent("fizzfau-mdt:server:add-bolo")
AddEventHandler("fizzfau-mdt:server:add-bolo", function(data, myName)
    local id, text, title, image = data.id, data.text, data.title, data.image
    local src = source
    local info = {
        info = "update",
        bolos = nil,
        vehicles = MDT.Vehicles[data.identifier]
    }
    local ts = os.time()
    local time = os.date('%Y-%m-%d %H:%M', ts)
    if (MDT.Infos[data.identifier]) == nil and (MDT.Bolos[data.identifier]) == nil  then
        MDT.Bolos[data.identifier] = {}
        if MDT.Bolos[data.identifier][id] == nil then
            MDT.Bolos[data.identifier][id] = {
                text = text,
                title = title
            } 
            exports.ghmattimysql:execute("INSERT INTO mdt_warrants (`identifier`, `bolos`) VALUES (@identifier, @bolos)", {
                ["@identifier"] = data.identifier,
                ["@bolos"] = json.encode(MDT.Bolos[data.identifier])
            })
            info.bolos = MDT.Bolos[data.identifier]  
            local action = {type = "Created Bolo", time = time, name = myName}
            AddAction(action)
            DiscordLog({title = "Bolo - " ..data.citizen_name, text = "\n \n **Fine** \n" ..title.. "\n \n **Purpose** \n" ..text, image = image}, data.citizen_name, bolo)
        end
    else
        if MDT.Bolos[data.identifier] == false or MDT.Bolos[data.identifier] == nil then 
            MDT.Bolos[data.identifier] = {}
        end
        if MDT.Bolos[data.identifier][id] == nil then
            MDT.Bolos[data.identifier][id] = {
                text = text,
                title = title
            } 
            exports.ghmattimysql:execute("UPDATE mdt_warrants SET bolos = @bolos WHERE identifier = '" ..data.identifier.. "'", {
                ["@bolos"] = json.encode(MDT.Bolos[data.identifier])
            })
            info.bolos = MDT.Bolos[data.identifier]    
            local action = {type = "Created Bolo", time = time, name = myName}
            AddAction(action)
            DiscordLog({title = "Bolo - " ..data.citizen_name, text = "\n \n**Fine** \n" ..title.. "\n \n **Purpose** \n" ..text, image = image}, data.citizen_name, "bolo")
        end
    end
    if image ~= "" then
        exports.ghmattimysql:execute("UPDATE users SET mdt_image = @image WHERE identifier = '" ..data.identifier.. "'", {
            ["@image"] = image
        })
    end
    TriggerClientEvent("fizzfau-mdt:server:client:getInfo", src, info, data.identifier)
end)

RegisterServerEvent("fizzfau-mdt:server:getName")
AddEventHandler("fizzfau-mdt:server:getName", function(identifier)
    local src = source
    local player = ESX.GetPlayerFromId(source)
    if player then
        if player.job.name == "police" then
            TriggerClientEvent("fizzfau-mdt:getName", src, {firstname = player.get("firstName"), lastname = player.get("lastName")})
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == "fizzfau-mdt" then
        if MDT.Actions ~= nil then
            if #MDT.Actions > 0 then
                exports.ghmattimysql:execute("UPDATE mdt_general SET actions = @actions", {
                    ["@actions"] = json.encode(MDT.Actions)
                })
            end
        end
    end
end)

RegisterServerEvent("fizzfau-mdt:server:add-wanted")
AddEventHandler("fizzfau-mdt:server:add-wanted", function(data, myName)
    local ts = os.time()
    local time = os.date('%Y-%m-%d %H:%M', ts)
    data.time, data.name = time, myName
    exports.ghmattimysql:execute("INSERT INTO mdt_wanteds (wanted) VALUES (@wanted)", {
        ["@wanted"] = json.encode(data)
    })
    local action = {type = "Created Wanted", time = time, name = myName}
    AddAction(action)
    DiscordLog({title = "Buscados - " ..data.title, text = " \n" ..data.text, image = image}, myName, "wanted")
    TriggerClientEvent("fizzfau-mdt:client:notify", -1, "Officer " ..myName.. " ha creado un registro buscado! ")
end)    

ESX.RegisterServerCallback("fizzfau-mdt:getWanteds", function(source, cb)
    local wanteds = {}
    local result = exports.ghmattimysql:executeSync("SELECT * FROM mdt_wanteds")
    if result ~= nil then
        for i =1, #result do
            wanteds[result[i].id] = json.decode(result[i].wanted)
        end
        cb(wanteds)
        return
    end
    cb(nil)
end) 

RegisterServerEvent("fizzfau-mdt:server:delete-wanted")
AddEventHandler("fizzfau-mdt:server:delete-wanted", function(data, myName)
    local ts = os.time()
    local time = os.date('%Y-%m-%d %H:%M', ts)
    data.time, data.name = time, myName
    local id = tonumber(data.id)

    exports.ghmattimysql:execute("DELETE FROM mdt_wanteds WHERE id = @id", {
        ["@id"] = id
    })
end)   

RegisterServerEvent("fizzfau-mdt:server:add-dispatch")
AddEventHandler("fizzfau-mdt:server:add-dispatch", function(data, coords)
    local src = source
    local id = #MDT.Dispatches + 1
    MDT.Dispatches[id] = {
        data = data,
        coords = coords
    }
    TriggerClientEvent("fizzfau-mdt:client:addDispatch", src, MDT.Dispatches[id], id)
end)

function AddAction(data)
    local id =  #MDT.Actions + 1
    MDT.Actions[id] = data
    TriggerClientEvent("fizzfau-mdt:client:addAction", -1, data, id)
end

ESX.RegisterServerCallback("fizzfau-mdt:getData", function(source, cb)
    while not db_loaded do; Citizen.Wait(100); end
    cb(MDT)
end)    