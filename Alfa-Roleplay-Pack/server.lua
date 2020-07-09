RegisterCommand("bk", function(source, args, rawCommand)
    local s = source
    local bkLvl = args[1]
    local playerName = GetPlayerName(s)
    if not bkLvl then
        TriggerClientEvent("Fax:ShowInfo", source, "~y~Please specify a code level ~n~~s~1, 2, 3")
    elseif bkLvl == "1" then
        TriggerClientEvent("Fax:BackupReq", -1, bkLvl, s, playerName)
    elseif bkLvl == "2" then
        TriggerClientEvent("Fax:BackupReq", -1, bkLvl, s, playerName)
    elseif bkLvl == "3" then
        TriggerClientEvent("Fax:BackupReq", -1, bkLvl, s, playerName)
    elseif bkLvl == "5" then
        TriggerClientEvent("Fax:BackupReq", -1, bkLvl, s, playerName)
    elseif bkLvl == "99" then
        TriggerClientEvent("Fax:BackupReq", -1, bkLvl, s, playerName)
    elseif bkLvl == "100" then
        TriggerClientEvent("Fax:BackupReq", -1, bkLvl, s, playerName)
    elseif bkLvl ~= "1" or bkLvl ~= "2" or bkLvl ~= "3" or bkLvl ~= "5" or bkLvl ~= "99" or bkLvl ~= "100" then
        TriggerClientEvent("Fax:ShowInfo", source, "~y~Invalid code level")
    end
end)

RegisterCommand("mechanic", function(source, args, rawCommand)
    local s = source
    local playerName = GetPlayerName(s)
    TriggerClientEvent("Alfa:CallMechanic", -1, s, playerName)
end)

RegisterCommand("taxi", function(source, args, rawCommand)
    local s = source
    local playerName = GetPlayerName(s)
    TriggerClientEvent("Alfa:CallTaxi", -1, s, playerName)
end)