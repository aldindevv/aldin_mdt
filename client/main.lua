ESX = nil
local myName = nil
local opened, notify, mdt = false, false, nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
        Citizen.Wait(250)
    end
    while ESX.GetPlayerData() == nil do
        Citizen.Wait(250)
    end
    PlayerData = ESX.GetPlayerData()
    TriggerServerEvent("fizzfau-mdt:server:getName", ESX.GetPlayerData().identifier)
    ESX.TriggerServerCallback("fizzfau-mdt:getData", function(data)
        mdt = data
    end)
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
    PlayerData.job = job
end)

RegisterNUICallback("close", function()
    stopAnim()
    SetNuiFocus(false, false)
    opened = false
end)

RegisterNUICallback("search-citizen", function(data)
    TriggerServerEvent("fizzfau-mdt:server:search-citizen", data.result)
end)

RegisterNUICallback("search-vehicle", function(data)
    TriggerServerEvent("fizzfau-mdt:server:search-vehicle", data.result)
end)

RegisterNUICallback("getInfo", function(data)
    TriggerServerEvent("fizzfau-mdt:server:server:getInfo", data.identifier)
end)

RegisterNUICallback("delete-record", function(data)
    TriggerServerEvent("fizzfau-mdt:server:delete-record", data, myName)
end)

RegisterNUICallback("add-note", function(data)
    TriggerServerEvent("fizzfau-mdt:server:add-note", data, myName)
end)

RegisterNUICallback("add-bolo", function(data)
    TriggerServerEvent("fizzfau-mdt:server:add-bolo", data, myName)
end)

RegisterNUICallback("add-wanted", function(data)
    TriggerServerEvent("fizzfau-mdt:server:add-wanted", data, myName)
end)

RegisterNUICallback("delete-wanted", function(data)
    TriggerServerEvent("fizzfau-mdt:server:delete-wanted", data, myName)
end)

RegisterNUICallback("waypoint", function(data)
    stopAnim()
    SetNewWaypoint(data.coords.x, data.coords.y)
end)

RegisterNUICallback("getPolices", function()
    TriggerServerEvent("fizzfau-mdt:getPolices")
end)

RegisterNUICallback("getWanteds",function()
    ESX.TriggerServerCallback("fizzfau-mdt:getWanteds", function(wanteds)
        SendNUIMessage({type="wanteds", wanteds=wanteds})
    end)
end)

RegisterNetEvent("fizzfau-mdt:client:notify")
AddEventHandler("fizzfau-mdt:client:notify", function(text)
    if not opened and PlayerData.job.name == "police" then
        notify = true
        SendNUIMessage({type = "notify", text = text})
        Citizen.Wait(10000)
        notify = false
    end
end)

RegisterNetEvent("fizzfau-mdt:client:open")
AddEventHandler("fizzfau-mdt:client:open", function()
    if not notify then
        startAnim()
        TriggerServerEvent("fizzfau-mdt:server:setupMDT")
        SendNUIMessage({type = "open", name = myName})
        SetNuiFocus(true, true)
        opened = true
    end
end)

RegisterNetEvent("fizzfau-mdt:client:search-citizen")
AddEventHandler("fizzfau-mdt:client:search-citizen", function(results)
    SendNUIMessage({type="search", type2="citizen", results = results})
end)

RegisterNetEvent("fizzfau-mdt:client:search-vehicle")
AddEventHandler("fizzfau-mdt:client:search-vehicle", function(results)
    SendNUIMessage({type="search", type2="vehicle", results = results})
end)

RegisterNetEvent("fizzfau-mdt:server:client:getInfo")
AddEventHandler("fizzfau-mdt:server:client:getInfo", function(results, identifier)
    SendNUIMessage({type = "loadinfo", info = results, identifier = identifier})
end)

RegisterNetEvent("fizzfau-mdt:client:addAction")
AddEventHandler("fizzfau-mdt:client:addAction", function(data, id)
    SendNUIMessage({ type = "action", action = data, id = id})
end)

RegisterNetEvent("fizzfau-mdt:client:addWanted")
AddEventHandler("fizzfau-mdt:client:addWanted", function(data, id)
    SendNUIMessage({ type = "wanted", wanted = data, id = id})
end)

RegisterNetEvent("fizzfau-mdt:client:setupMDT")
AddEventHandler("fizzfau-mdt:client:setupMDT", function(mdt)
    SendNUIMessage({ type = "setup", actions = mdt.Actions})
end)

RegisterNetEvent("fizzfau-mdt:client:remove-wanted")
AddEventHandler("fizzfau-mdt:client:remove-wanted", function(id)
    SendNUIMessage({ type = "remove-wanted", id = id})
end)

RegisterNetEvent("fizzfau-mdt:client:addDispatch")
AddEventHandler("fizzfau-mdt:client:addDispatch", function(data, id)
    SendNUIMessage({ type = "dispatch", dispatches = data, id = id})
end)

RegisterNetEvent("fizzfau-mdt:getName")
AddEventHandler("fizzfau-mdt:getName", function(name)
    myName = name.firstname.. " " ..name.lastname
end)

RegisterNetEvent('esx_outlawalert:outlawNotify')
AddEventHandler('esx_outlawalert:outlawNotify', function(type, data, length, coords)
    TriggerServerEvent("fizzfau-mdt:server:add-dispatch", data, coords)
end)

RegisterNetEvent("fizzfau-mdt:client:getPolices")
AddEventHandler("fizzfau-mdt:client:getPolices", function(cops)
    SendNUIMessage({ type = "cops", cops = cops})
end)

function startAnim()
    Citizen.CreateThread(function()
      RequestAnimDict("amb@world_human_seat_wall_tablet@female@base")
      while not HasAnimDictLoaded("amb@world_human_seat_wall_tablet@female@base") do
        Citizen.Wait(0)
      end
        attachObject()
        TaskPlayAnim(GetPlayerPed(-1), "amb@world_human_seat_wall_tablet@female@base", "base" ,8.0, -8.0, -1, 50, 0, false, false, false)
    end)
end
  
function stopAnim()
    StopAnimTask(GetPlayerPed(-1), "amb@world_human_seat_wall_tablet@female@base", "base" ,8.0, -8.0, -1, 50, 0, false, false, false)
    DeleteEntity(tab)
end

function attachObject()
    tab = CreateObject(GetHashKey("prop_cs_tablet"), 0, 0, 0, true, true, true)
    AttachEntityToEntity(tab, GetPlayerPed(-1), GetPedBoneIndex(GetPlayerPed(-1), 57005), 0.17, 0.10, -0.13, 20.0, 180.0, 180.0, true, true, false, true, 1, true)
  end