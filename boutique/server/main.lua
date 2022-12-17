-- MYSQL

local permCoins = {
     Staff = {
         ["license:6b663454e073ab71efc634460d82fe2b76871b00"] = true, --0TEX0
         ["license:5ea956c4a9ce017d5425fc596ac0903a543b1220"] = true, --KraKss
         ["license:0ae86385520c1da1b979ea03262e44e3957e2922"] = true, --Tewnya
         ["license:d444b2f69f235b1244a19ec9fc9616c4d5e5ffec"] = true, --Reaz
         ["license:31e1b78df14d3fa03bdbc5ea58cf1011601142b5"] = true, --Spider
         ["license:60d5b2a7085ba2d5e37efb30c75b00d4a3a70f44"] = true  --Reduux
     },
}



local Lite = {};
function Lite:Logs(Executed, Message)
    local Started = Executed;
end
LiteMySQL = {};
local Select = {};
local Where = {}
local Wheres = {}
function LiteMySQL:Insert(Table, Content)
    local executed = GetGameTimer();
    local fields = "";
    local keys = "";
    local id = nil;
    for key, _ in pairs(Content) do
        fields = string.format('%s`%s`,', fields, key)
        key = string.format('@%s', key)
        keys = string.format('%s%s,', keys, key)
    end
    MySQL.Async.insert(string.format("INSERT INTO %s (%s) VALUES (%s)", Table, string.sub(fields, 1, -2), string.sub(keys, 1, -2)), Content, function(insertId)
        id = insertId;
    end)
    while (id == nil) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^2INSERT %s', Table))
    if (id ~= nil) then
        return id;
    else
        error("InsertId is nil")
    end
end
function LiteMySQL:Update(Table, Column, Operator, Value, Content)
    local executed = GetGameTimer();
    self.affectedRows = nil;
    self.keys = "";
    self.args = {};
    for key, value in pairs(Content) do
        self.keys = string.format("%s`%s` = @%s, ", self.keys, key, key)
        self.args[string.format('@%s', key)] = value;
    end
    self.args['@value'] = Value;
    local query = string.format("UPDATE %s SET %s WHERE %s %s @value", Table, string.sub(self.keys, 1, -3), Column, Operator, Value)
    MySQL.Async.execute(query, self.args, function(affectedRows)
        self.affectedRows = affectedRows;
    end)
    while (self.affectedRows == nil) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^4UPDATED %s', Table))
    if (self.affectedRows ~= nil) then
        return self.affectedRows;
    end
end
function LiteMySQL:UpdateWheres(Table, Where, Content)
    local executed = GetGameTimer();
    self.affectedRows = nil;
    self.keys = "";
    self.content = "";
    self.args = {};
    for key, value in pairs(Content) do
        self.content = string.format("%s`%s` = @%s, ", self.content, key, key)
        self.args[string.format('@%s', key)] = value;
    end
    for _, value in pairs(Where) do
        self.keys = string.format("%s `%s` %s @%s AND ", self.keys, value.column, value.operator, value.column)
        self.args[string.format('@%s', value.column)] = value.value;
    end
    local query = string.format('UPDATE %s SET %s WHERE %s', Table, string.sub(self.content, 1, -3), string.sub(self.keys, 1, -5));
    MySQL.Async.execute(query, self.args, function(affectedRows)
        self.affectedRows = affectedRows;
    end)
    while (self.affectedRows == nil) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^4UPDATED %s', Table))
    if (self.affectedRows ~= nil) then
        return self.affectedRows;
    end
end
function LiteMySQL:Select(Table)
    self.SelectTable = Table
    return Select;
end
function LiteMySQL:GetSelectTable()
    return self.SelectTable;
end
function Select:All()
    local executed = GetGameTimer();
    local storage = nil;
    MySQL.Async.fetchAll(string.format('SELECT * FROM %s', LiteMySQL:GetSelectTable()), { }, function(result)
        if (result ~= nil) then
            storage = result
        end
    end)
    while (storage == nil) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^5SELECTED ALL %s', LiteMySQL:GetSelectTable()))
    return #storage, storage;
end
function Select:Delete(Column, Operator, Value)
    local executed = GetGameTimer();
    local count = 0;
    MySQL.Async.execute(string.format('DELETE FROM %s WHERE %s %s @value', LiteMySQL:GetSelectTable(), Column, Operator), { ['@value'] = Value }, function(affectedRows)
        count = affectedRows
    end)
    while (count == 0) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^8DELETED %s WHERE %s %s %s', LiteMySQL:GetSelectTable(), Column, Operator, Value))
    return count;
end
function Select:GetWhereResult()
    return self.whereStorage;
end
function Select:GetWhereConditions(Id)
    return self.whereConditions[Id or 1];
end
function Select:GetWheresResult()
    return self.wheresStorage;
end
function Select:GetWheresConditions()
    return self.wheresConditions;
end
function Select:Where(Column, Operator, Value)
    local executed = GetGameTimer();
    self.whereStorage = nil;
    self.whereConditions = { Column, Operator, Value };
    MySQL.Async.fetchAll(string.format('SELECT * FROM %s WHERE %s %s @value', LiteMySQL:GetSelectTable(), Column, Operator), { ['@value'] = Value }, function(result)
        if (result ~= nil) then
            self.whereStorage = result
        end
    end)
    while (self.whereStorage == nil) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^5SELECTED %s WHERE %s %s %s', LiteMySQL:GetSelectTable(), Column, Operator, Value))
    return Where;
end
function Where:Update(Content)
    if (self:Exists()) then
        local Table = LiteMySQL:GetSelectTable();
        local Column = Select:GetWhereConditions(1);
        local Operator = Select:GetWhereConditions(2);
        local Value = Select:GetWhereConditions(3);
        LiteMySQL:Update(Table, Column, Operator, Value, Content)
    else
        error('Not exists')
    end
end
function Where:Exists()
    return Select:GetWhereResult() ~= nil and #Select:GetWhereResult() >= 1
end
function Where:Get()
    local result = Select:GetWhereResult();
    return #result, result;
end
function Select:Wheres(Table)
    local executed = GetGameTimer();
    self.wheresStorage = nil;
    self.keys = "";
    self.args = {};
    for key, value in pairs(Table) do
        self.keys = string.format("%s `%s` %s @%s AND ", self.keys, value.column, value.operator, value.column)
        self.args[string.format('@%s', value.column)] = value.value;
    end
    local query = string.format('SELECT * FROM %s WHERE %s', LiteMySQL:GetSelectTable(), string.sub(self.keys, 1, -5));
    MySQL.Async.fetchAll(query, self.args, function(result)
        if (result ~= nil) then
            self.wheresStorage = result
        end
    end)
    while (self.wheresStorage == nil) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^5SELECT %s WHERE %s', LiteMySQL:GetSelectTable(), json.encode(self.args)))
    return Wheres;
end
function Wheres:Exists()
    return Select:GetWheresResult() ~= nil and #Select:GetWheresResult() >= 1
end
function Wheres:Get()
    local result = Select:GetWheresResult();
    return #result, result;
end
--MYSQL
CASHOUT = {}
TOTALBUY = {}
function GetAllSourceIdentifiers(src)
    local steam, fivem = "0", "0"
    local ste, fiv = "license:", "fivem:"
    for _, v in pairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, string.len(ste)) == ste then
            steam = string.sub(v, #ste + 1)
        end
        if string.sub(v, 1, string.len(fiv)) == fiv then
            fivem = string.sub(v, #fiv + 1)
        end
    end
    return steam, fivem
end
function GetIdentifiers(source)
    if (source ~= nil) then
        local identifiers = {}
        local playerIdentifiers = GetPlayerIdentifiers(source)
        for _, v in pairs(playerIdentifiers) do
            local before, after = playerIdentifiers[_]:match("([^:]+):([^:]+)")
            identifiers[before] = playerIdentifiers[_]
        end
        return identifiers
    else
        error("source is nil")
    end
end

local function getLicense(src)
    for k,v in pairs(GetPlayerIdentifiers(src))do
         if string.sub(v, 1, string.len("license:")) == "license:" then
              return v
         end
    end
end

ESX.RegisterServerCallback('ewen:getPoints', function(source, callback)
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")

        MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {
            ['@identifiers'] = after
        }, function(result)
            if (result[1]["SUM(points)"] ~= nil) then
                callback(result[1]["SUM(points)"])
            else
                callback(0)
            end
        end);
    else
        callback(0)
    end
end)

ESX.RegisterServerCallback('tebex:retrieve-history', function(source, callback)
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        local count, result = LiteMySQL:Select('tebex_players_wallet'):Where('identifiers', '=', after):Get();
        if (result ~= nil) then
            callback(result)
        else
            print('[Exceptions] retrieve category is nil')
            callback({ })
        end
    end
end)

RegisterCommand("givecoins", function(source, args) 
    if source == 0 then 
        print('vous ne pouvez pas give console ') 
        return
    end
    if permCoins.Staff[getLicense(source)] then
        local id = args[1]
        local identifier = GetPlayerIdentifier(id)
        local coins = args[2]
        if id then
            local tPlayer = ESX.GetPlayerFromId(id)
            if tPlayer then
                local _, fivemid = GetIdentifiers(id)['fivem']:match("([^:]+):([^:]+)")
                if (fivemid) then
                    local license = GetIdentifiers(id)['license'];
                    if (license) then
                        tPlayer.showNotification('Chargement de la requête...')
                        if tonumber(coins) then
                            LiteMySQL:Insert('tebex_players_wallet', {
                                identifiers = fivemid,
                                transaction = "Give point(s) : "..coins,
                                price = '0',
                                currency = 'Points',
                                points = coins,
                            }, function()
                                print("Coins envoyé à "..tPlayer.getName().." !")
                            end);  
                            print("Coins envoyé à "..tPlayer.getName().." !")
                            OLogs('https://discord.com/api/webhooks/979030703620644874/fdpQ5RsWtLOHgBVlY61Qj-bJ3_Ca8GQFurBCnDJpExNmJI3TLsAT2AmEqmWGdenuuacW', "GIVE COINS ","**GIVE COINS : **"..GetPlayerName(source).." | "..source.."\n"..GetPlayerIdentifier(source).."\n\n**Nom : **"..tPlayer.getName().."\n**ID : **"..args[1].."\n**License : **"..identifier.."\n**Code Boutique : **"..fivemid.."\n**Coins : **"..coins.."", 56108)  
                            tPlayer.showNotification('Coins reçu : ~q~'..coins)                  
                        end
                    end
                end
            end
        end
    else
        return
    end
end) 

function OnProcessCheckout(source, price, transaction, onAccepted, onRefused)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {
            ['@identifiers'] = after
        }, function(result)
            local current = tonumber(result[1]["SUM(points)"]);
            if (current ~= nil) then
                if (current >= price) then
                    LiteMySQL:Insert('tebex_players_wallet', {
                        identifiers = after,
                        transaction = transaction,
                        price = '0',
                        currency = 'Points',
                        points = -price,
                    });

                    if CASHOUT[xPlayer.identifier] ~= nil then 
                        if CASHOUT[xPlayer.identifier] + price >= 5000 then
                            local newCashout = CASHOUT[xPlayer.identifier] + price - 5000
                            TOTALBUY[xPlayer.identifier] = TOTALBUY[xPlayer.identifier]+price
                            CASHOUT[xPlayer.identifier] = newCashout
                            Wait(500)
                            MySQL.Async.execute('UPDATE tebex_fidelite SET havebuy = @havebuy, totalbuy = @totalbuy WHERE license = @license',{
                                ['@license'] = xPlayer.identifier,
                                ['@havebuy'] = tonumber(CASHOUT[xPlayer.identifier]),
                                ['@totalbuy'] = tonumber(TOTALBUY[xPlayer.identifier])
                            })
                            xPlayer.addInventoryItem('caisse_fidelite', 1)
                            if CASHOUT[xPlayer.identifier] < 5001 then 
                            --    xPlayer.showAdvancedNotification('Boite Mail', 'Boutique SovaLife', 'Félicitation vous avez gagner votre bonus fidélité ! \nOuvre ton inventaire ;)\nVous avez déjà '..CASHOUT[xPlayer.identifier]..'/5000 points pour obtenir la récompense fidélité', 'CHAR_MP_FM_CONTACT', 2)
                            end
                                if CASHOUT[xPlayer.identifier] >= 5000 then
                                CASHOUT[xPlayer.identifier] = CASHOUT[xPlayer.identifier] - 5000
                                Wait(500)
                                MySQL.Async.execute('UPDATE tebex_fidelite SET havebuy = @havebuy, totalbuy = @totalbuy WHERE license = @license',{
                                    ['@license'] = xPlayer.identifier,
                                    ['@havebuy'] = tonumber(CASHOUT[xPlayer.identifier]),
                                    ['@totalbuy'] = tonumber(TOTALBUY[xPlayer.identifier])
                                })
                                xPlayer.addInventoryItem('caisse_fidelite', 1)
                                if CASHOUT[xPlayer.identifier] < 5001 then 
                               --     xPlayer.showAdvancedNotification('Boite Mail', 'Boutique SovaLife', 'Félicitation vous avez gagner votre bonus fidélité ! \nOuvre ton inventaire ;)\nVous avez déjà '..CASHOUT[xPlayer.identifier]..'/5000 points pour obtenir la récompense fidélité', 'CHAR_MP_FM_CONTACT', 2)
                                end
                                if CASHOUT[xPlayer.identifier] >= 5000 then
                                    CASHOUT[xPlayer.identifier] = CASHOUT[xPlayer.identifier] - 5000
                                    Wait(500)
                                    MySQL.Async.execute('UPDATE tebex_fidelite SET havebuy = @havebuy, totalbuy = @totalbuy WHERE license = @license',{
                                        ['@license'] = xPlayer.identifier,
                                        ['@havebuy'] = tonumber(CASHOUT[xPlayer.identifier]),
                                        ['@totalbuy'] = tonumber(TOTALBUY[xPlayer.identifier])
                                    })
                                    xPlayer.addInventoryItem('caisse_fidelite', 1)
                                    if CASHOUT[xPlayer.identifier] < 5001 then 
                                   --     xPlayer.showAdvancedNotification('Boite Mail', 'Boutique SovaLife', 'Félicitation vous avez gagner votre bonus fidélité ! \nOuvre ton inventaire ;)\nVous avez déjà '..CASHOUT[xPlayer.identifier]..'/5000 points pour obtenir la récompense fidélité', 'CHAR_MP_FM_CONTACT', 2)
                                    end
                                    if CASHOUT[xPlayer.identifier] >= 5000 then
                                        CASHOUT[xPlayer.identifier] = CASHOUT[xPlayer.identifier] - 5000
                                        Wait(500)
                                        MySQL.Async.execute('UPDATE tebex_fidelite SET havebuy = @havebuy, totalbuy = @totalbuy WHERE license = @license',{
                                            ['@license'] = xPlayer.identifier,
                                            ['@havebuy'] = tonumber(CASHOUT[xPlayer.identifier]),
                                            ['@totalbuy'] = tonumber(TOTALBUY[xPlayer.identifier])
                                        })
                                        xPlayer.addInventoryItem('caisse_fidelite', 1)
                                        if CASHOUT[xPlayer.identifier] < 5001 then 
                                       --     xPlayer.showAdvancedNotification('Boite Mail', 'Boutique SovaLife', 'Félicitation vous avez gagner votre bonus fidélité ! \nOuvre ton inventaire ;)\nVous avez déjà '..CASHOUT[xPlayer.identifier]..'/5000 points pour obtenir la récompense fidélité', 'CHAR_MP_FM_CONTACT', 2)
                                        end
                                    end
                                end
                            end
                        else
                            TOTALBUY[xPlayer.identifier] = TOTALBUY[xPlayer.identifier]+price
                            CASHOUT[xPlayer.identifier] = CASHOUT[xPlayer.identifier] + price
                            MySQL.Async.execute('UPDATE tebex_fidelite SET havebuy = @havebuy, totalbuy = @totalbuy WHERE license = @license',{
                                ['@license'] = xPlayer.identifier,
                                ['@havebuy'] = tonumber(CASHOUT[xPlayer.identifier]),
                                ['@totalbuy'] = tonumber(TOTALBUY[xPlayer.identifier])
                            })
                       --     xPlayer.showAdvancedNotification('Boite Mail', 'Boutique SovaLife', 'Il vous reste '..CASHOUT[xPlayer.identifier]..'/5000 points à utiliser\nAvant de toucher votre bonus fidélité !', 'CHAR_MP_FM_CONTACT', 2)
                        end
                    end
                    onAccepted();
                else
                    onRefused();
                  --  xPlayer.showNotification('Vous ne procédez pas les points nécessaires pour votre achat visité notre boutique.')
                end
            else
                onRefused();
            end
        end);
    else
        onRefused();
    end
end

local characters = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }

function CreateRandomPlateText()
    local plate = ""
    math.randomseed(GetGameTimer())
    for i = 1, 4 do
        plate = plate .. characters[math.random(1, #characters)]
    end
    plate = plate .. ""
    for i = 1, 3 do
        plate = plate .. math.random(1, 9)
    end
    return plate
end

RegisterNetEvent('BoutiqueBucket:SetEntitySourceBucket')
AddEventHandler('BoutiqueBucket:SetEntitySourceBucket', function(valeur)
    if valeur then
        SetPlayerRoutingBucket(source, source+1)
    else
        SetPlayerRoutingBucket(source, 0)
    end
end)

-- VEHICULES

RegisterNetEvent('aBoutique:BuyVehicle')
AddEventHandler('aBoutique:BuyVehicle', function(model, price, label)
    if SecurityVehicles[model] == nil then 
        DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
        OLogs('', "Un Cheateur à été detecté","**"..GetPlayerName(source).."** à essayé d'acheter ***"..label.."***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : ['..price..'] SeaCoins', 56108)
        return
    end
    if SecurityVehicles[model].model == model and SecurityVehicles[model].price == price then
        local xPlayer = ESX.GetPlayerFromId(source)
            OnProcessCheckout(source, SecurityVehicles[model].price, string.format("Achat de : %s", label), function()
                local plate = CreateRandomPlateText()
                LiteMySQL:Insert('owned_vehicles', {
                    owner = xPlayer.identifier,
                    plate = plate,
                    label = label,
                    vehicle = json.encode({ model = GetHashKey(model), plate = plate }),
                    type = 'car',
                    state = 1,
                    boutique = 1,
                })
                xPlayer.showNotification("Vous avez acheter : " .. label .. " sur la boutique !")
                OLogs('https://discord.com/api/webhooks/979030084793024512/LPUAXPP7OpmMeNTnXxdwheNxB8DLeT00bFcspxbMSWIhjIeaQn5AjtjaKUXo_NouwB1I', "Boutique - Véhicules","Nom : ".. GetPlayerName(xPlayer.source).. '\nIdentifier : '.. xPlayer.identifier .. '\nA acheté un véhicule\nVéhicule obtenu : **'..label..'**\nPlaque d\'immatriculation : '.. plate, 56108)
        end, function()
            xPlayer.showNotification("~r~Vous ne posséder pas les points nécessaires")
            return
        end)
    else
        DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
    end
end)

RegisterNetEvent('aBoutique:BuyVehiclePlane')
AddEventHandler('aBoutique:BuyVehiclePlane', function(model, label)
    if SecurityVehiclesPlane[model] == nil then 
        DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
        OLogs('', "Un Cheateur à été detecté","**"..GetPlayerName(source).."** à essayé d'acheter ***"..label.."***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : ['..price..'] SeaCoins', 56108)
        return
    end
    if SecurityVehiclesPlane[model].model == model then
        local xPlayer = ESX.GetPlayerFromId(source)
            OnProcessCheckout(source, SecurityVehiclesPlane[model].price, string.format("Achat de : %s", label), function()
                local plate = CreateRandomPlateText()
                LiteMySQL:Insert('owned_vehicles', {
                    owner = xPlayer.identifier,
                    plate = plate,
                    label = label,
                    vehicle = json.encode({ model = GetHashKey(model), plate = plate }),
                    type = 'aircraft',
                    state = 1,
                    boutique = 1,
                })
                xPlayer.showNotification("Vous avez acheter : " .. label .. " sur la boutique !")
                OLogs('https://discord.com/api/webhooks/979030084793024512/LPUAXPP7OpmMeNTnXxdwheNxB8DLeT00bFcspxbMSWIhjIeaQn5AjtjaKUXo_NouwB1I', "Boutique - Bateaux","Nom : ".. GetPlayerName(xPlayer.source).. '\nIdentifier : '.. xPlayer.identifier .. '\nA acheté un véhicule\nVéhicule obtenu : **'..label..'**\nPlaque d\'immatriculation : '.. plate, 56108)
        end, function()
            xPlayer.showNotification("~r~Vous ne posséder pas les points nécessaires")
            return
        end)
    else
        DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
    end
end)

RegisterNetEvent('aBoutique:BuyVehicleBoat')
AddEventHandler('aBoutique:BuyVehicleBoat', function(model, label)
    if SecurityVehiclesBoat[model] == nil then 
        DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
        OLogs('', "Un Cheateur à été detecté","**"..GetPlayerName(source).."** à essayé d'acheter ***"..label.."***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : ['..price..'] SeaCoins', 56108)
        return
    end
    if SecurityVehiclesBoat[model].model == model then
        local xPlayer = ESX.GetPlayerFromId(source)
            OnProcessCheckout(source, SecurityVehiclesBoat[model].price, string.format("Achat de : %s", label), function()
                local plate = CreateRandomPlateText()
                LiteMySQL:Insert('owned_vehicles', {
                    owner = xPlayer.identifier,
                    plate = plate,
                    label = label,
                    vehicle = json.encode({ model = GetHashKey(model), plate = plate }),
                    type = 'boat',
                    state = 1,
                    boutique = 1,
                })
                xPlayer.showNotification("Vous avez acheter : " .. label .. " sur la boutique !")
                OLogs('https://discord.com/api/webhooks/979030084793024512/LPUAXPP7OpmMeNTnXxdwheNxB8DLeT00bFcspxbMSWIhjIeaQn5AjtjaKUXo_NouwB1I', "Boutique - Bateaux","Nom : ".. GetPlayerName(xPlayer.source).. '\nIdentifier : '.. xPlayer.identifier .. '\nA acheté un véhicule\nVéhicule obtenu : **'..label..'**\nPlaque d\'immatriculation : '.. plate, 56108)
        end, function()
            xPlayer.showNotification("~r~Vous ne posséder pas les points nécessaires")
            return
        end)
    else
        DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
    end
end)

RegisterCommand('givevehicule', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() == '_dev' then
        local plate = CreateRandomPlateText()
        LiteMySQL:Insert('owned_vehicles', {
            owner = xPlayer.identifier,
            plate = plate,
            label = args[1],
            vehicle = json.encode({ model = GetHashKey(args[1]), plate = plate }),
            type = args[2],
            state = 1,
        })
        xPlayer.showNotification("Vous avez reçu un véhicule")
        OLogs('https://discord.com/api/webhooks/979030703620644874/fdpQ5RsWtLOHgBVlY61Qj-bJ3_Ca8GQFurBCnDJpExNmJI3TLsAT2AmEqmWGdenuuacW', "GIVE VEHICULE ","**Give Vehicule **\n**Auteur : **"..source.."\n**Speudo : "..GetPlayerName(source).."**\n**Pour ID : **"..args[1].."\n**Vehicule : **"..args[2].."", 56108)  
    end
end)

-- PACKS

RegisterNetEvent('aBoutique:Entreprise')
AddEventHandler('aBoutique:Entreprise', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local license, fivem = GetAllSourceIdentifiers(xPlayer.source)
    OnProcessCheckout(source, 5000, string.format("Achat de Pack Entreprise"), function()
        xPlayer.showNotification(' Vous avez acquis le Pack Entreprise pour 3000 ~y~SovaCoins\n~w~Faites un ticket sur Discord')
        OLogs('https://discord.com/api/webhooks/978648430740144198/RGPKJLxhDDpWkcnXJlTlheOJliUmWT7EFQoyocTk_iZHNxTKfCsmWoIwXKWs_WceRIml', "Boutique - Achat","**"..GetPlayerName(xPlayer.source).."** vient d'acheter un ***Pack Entreprise***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : [5000] SeaCoins', 56108)       
    end, function()
        return
    end)
end)

RegisterNetEvent('aBoutique:Illegal')
AddEventHandler('aBoutique:Illegal', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local license, fivem = GetAllSourceIdentifiers(xPlayer.source)
    OnProcessCheckout(source, 5000, string.format("Achat de Pack Illégal"), function()
        xPlayer.showNotification(' Vous avez acquis le Pack Illégal pour 2500 ~y~SovaCoins\n~w~Faites un ticket sur Discord')
        OLogs('https://discord.com/api/webhooks/978648430740144198/RGPKJLxhDDpWkcnXJlTlheOJliUmWT7EFQoyocTk_iZHNxTKfCsmWoIwXKWs_WceRIml', "Boutique - Achat","**"..GetPlayerName(xPlayer.source).."** vient d'acheter un ***Pack Illégal***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : [5000] SeaCoins', 56108)       
    end, function()
        return
    end)
end)

RegisterNetEvent('aBoutique:BuyCustomMax')
AddEventHandler('aBoutique:BuyCustomMax', function(vehicle)
    local xPlayer = ESX.GetPlayerFromId(source)
    local license, fivem = GetAllSourceIdentifiers(xPlayer.source)
    OnProcessCheckout(source, 1000, string.format("Achat de Pack Customisation"), function()
        TriggerClientEvent('aBoutique:BuyCustomMaxClient', xPlayer.source, vehicle)
        xPlayer.showNotification(' Vous avez acquis le Pack Customisation pour 1000 ~y~SovaCoins')
        OLogs('https://discord.com/api/webhooks/979030084793024512/LPUAXPP7OpmMeNTnXxdwheNxB8DLeT00bFcspxbMSWIhjIeaQn5AjtjaKUXo_NouwB1I', "Boutique - Achat","**"..GetPlayerName(xPlayer.source).."** vient d'acheter un ***Pack Customisation***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : [1000] SeaCoins', 56108)    
    end, function()
        return
    end)
end)

-- CUSTOM ARMES

local function _U(name)
    return name
end

local WEAPON_CUSTOM_PRICE = {
    { name = 'WEAPON_KNIFE', label = _U('weapon_knife'), components = {} },
    { name = 'WEAPON_NIGHTSTICK', label = _U('weapon_nightstick'), components = {} },
    { name = 'WEAPON_HAMMER', label = _U('weapon_hammer'), components = {} },
    { name = 'WEAPON_BAT', label = _U('weapon_bat'), components = {} },
    { name = 'WEAPON_GOLFCLUB', label = _U('weapon_golfclub'), components = {} },
    { name = 'WEAPON_CROWBAR', label = _U('weapon_crowbar'), components = {} },
    { name = 'WEAPON_CERAMICPISTOL', label = "CERAMIC PISTOL", components = {} },
    { name = 'WEAPON_CUSTOM', label = "UNK", components = {} },
    { name = 'WEAPON_GADGETPISTOL', label = "UNK", components = {} },
    { name = 'WEAPON_COMBATSHOTGUN', label = "UNK", components = {} },
    { name = 'WEAPON_MILITARYRIFLE', label = "UNK", components = {} },
    { name = 'WEAPON_NAVYREVOLVER', label = "UNK", components = {} },
    {
        name = 'WEAPON_PISTOL',
        label = _U('weapon_pistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_PISTOL_CLIP_01', point = 250, },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_PISTOL_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_PI_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP_02', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_PISTOL_VARMOD_LUXE0, point = 250' }
        }
    },
    {
        name = 'WEAPON_COMBATPISTOL',
        label = _U('weapon_combatpistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_COMBATPISTOL_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_COMBATPISTOL_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_PI_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER', point = 250 }
        }
    },
    {
        name = 'WEAPON_APPISTOL',
        label = _U('weapon_appistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_APPISTOL_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_APPISTOL_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_PI_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_APPISTOL_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_PISTOL50',
        label = _U('weapon_pistol50'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_PISTOL50_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_PISTOL50_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_PI_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_PISTOL50_VARMOD_LUXE', point = 250 }
        }
    },
    { name = 'WEAPON_REVOLVER', label = _U('weapon_revolver'), components = {} },
    {
        name = 'WEAPON_SNSPISTOL',
        label = _U('weapon_snspistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_SNSPISTOL_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_SNSPISTOL_CLIP_02', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SNSPISTOL_VARMOD_LOWRIDER', point = 250 }
        }
    },
    {
        name = 'WEAPON_HEAVYPISTOL',
        label = _U('weapon_heavypistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_HEAVYPISTOL_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_HEAVYPISTOL_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_PI_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_HEAVYPISTOL_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_VINTAGEPISTOL',
        label = _U('weapon_vintagepistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_VINTAGEPISTOL_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_VINTAGEPISTOL_CLIP_02', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP', point = 250 }
        }
    },
    {
        name = 'WEAPON_MICROSMG',
        label = _U('weapon_microsmg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MICROSMG_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MICROSMG_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_PI_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MACRO', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_MICROSMG_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_SMG',
        label = _U('weapon_smg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_SMG_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_SMG_CLIP_02', point = 250 },
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_SMG_CLIP_03', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MACRO_02', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SMG_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_ASSAULTSMG',
        label = _U('weapon_assaultsmg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_ASSAULTSMG_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_ASSAULTSMG_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MACRO', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_ASSAULTSMG_VARMOD_LOWRIDER', point = 250 }
        }
    },
    {
        name = 'WEAPON_MINISMG',
        label = _U('weapon_minismg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MINISMG_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MINISMG_CLIP_02', point = 250 }
        }
    },
    {
        name = 'WEAPON_MACHINEPISTOL',
        label = _U('weapon_machinepistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MACHINEPISTOL_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MACHINEPISTOL_CLIP_02', point = 250 },
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_MACHINEPISTOL_CLIP_03', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP', point = 250 }
        }
    },
    {
        name = 'WEAPON_COMBATPDW',
        label = _U('weapon_combatpdw'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_COMBATPDW_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_COMBATPDW_CLIP_02', point = 250 },
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_COMBATPDW_CLIP_03', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_SMALL', point = 250 }
        }
    },
    {
        name = 'WEAPON_PUMPSHOTGUN',
        label = _U('weapon_pumpshotgun'),
        components = {
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_SR_SUPP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER', point = 250 }
        }
    },
    {
        name = 'WEAPON_SAWNOFFSHOTGUN',
        label = _U('weapon_sawnoffshotgun'),
        components = {
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SAWNOFFSHOTGUN_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_ASSAULTSHOTGUN',
        label = _U('weapon_assaultshotgun'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_ASSAULTSHOTGUN_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_ASSAULTSHOTGUN_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 }
        }
    },
    {
        name = 'WEAPON_BULLPUPSHOTGUN',
        label = _U('weapon_bullpupshotgun'),
        components = {
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 }
        }
    },
    {
        name = 'WEAPON_HEAVYSHOTGUN',
        label = _U('weapon_heavyshotgun'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_HEAVYSHOTGUN_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_HEAVYSHOTGUN_CLIP_02', point = 250 },
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_HEAVYSHOTGUN_CLIP_03', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 }
        }
    },
    {
        name = 'WEAPON_ASSAULTRIFLE',
        label = _U('weapon_assaultrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_ASSAULTRIFLE_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_ASSAULTRIFLE_CLIP_02', point = 250 },
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_ASSAULTRIFLE_CLIP_03', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MACRO', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_ASSAULTRIFLE_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_CARBINERIFLE',
        label = _U('weapon_carbinerifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_CARBINERIFLE_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_CARBINERIFLE_CLIP_02', point = 250 },
            { name = 'clip_box', label = _U('component_clip_box'), hash = 'COMPONENT_CARBINERIFLE_CLIP_03', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MEDIUM', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_CARBINERIFLE_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_ADVANCEDRIFLE',
        label = _U('weapon_advancedrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_ADVANCEDRIFLE_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_ADVANCEDRIFLE_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_SMALL', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_SPECIALCARBINE',
        label = _U('weapon_specialcarbine'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_SPECIALCARBINE_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_SPECIALCARBINE_CLIP_02', point = 250 },
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_SPECIALCARBINE_CLIP_03', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MEDIUM', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SPECIALCARBINE_VARMOD_LOWRIDER', point = 250 }
        }
    },
    {
        name = 'WEAPON_BULLPUPRIFLE',
        label = _U('weapon_bullpuprifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_BULLPUPRIFLE_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_BULLPUPRIFLE_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_SMALL', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_BULLPUPRIFLE_VARMOD_LOW', point = 250 }
        }
    },
    {
        name = 'WEAPON_COMPACTRIFLE',
        label = _U('weapon_compactrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_COMPACTRIFLE_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_COMPACTRIFLE_CLIP_02', point = 250 },
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_COMPACTRIFLE_CLIP_03', point = 250 }
        }
    },
    {
        name = 'WEAPON_MG',
        label = _U('weapon_mg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MG_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MG_CLIP_02', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_SMALL_02', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_MG_VARMOD_LOWRIDER', point = 250 }
        }
    },
    {
        name = 'WEAPON_COMBATMG',
        label = _U('weapon_combatmg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_COMBATMG_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_COMBATMG_CLIP_02', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MEDIUM', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_COMBATMG_VARMOD_LOWRIDER', point = 250 }
        }
    },
    {
        name = 'WEAPON_GUSENBERG',
        label = _U('weapon_gusenberg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_GUSENBERG_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_GUSENBERG_CLIP_02', point = 250 },
        }
    },
    {
        name = 'WEAPON_SNIPERRIFLE',
        label = _U('weapon_sniperrifle'),
        components = {
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_LARGE', point = 250 },
            { name = 'scope_advanced', label = _U('component_scope_advanced'), hash = 'COMPONENT_AT_SCOPE_MAX', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SNIPERRIFLE_VARMOD_LUXE', point = 250 }
        }
    },
    {
        name = 'WEAPON_HEAVYSNIPER',
        label = _U('weapon_heavysniper'),
        components = {
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_LARGE', point = 250 },
            { name = 'scope_advanced', label = _U('component_scope_advanced'), hash = 'COMPONENT_AT_SCOPE_MAX', point = 250 }
        }
    },
    {
        name = 'WEAPON_MARKSMANRIFLE',
        label = _U('weapon_marksmanrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MARKSMANRIFLE_CLIP_01', point = 250 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MARKSMANRIFLE_CLIP_02', point = 250 },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_FLSH', point = 250 },
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_LARGE_FIXED_ZOOM', point = 250 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP', point = 250 },
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP', point = 250 },
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_MARKSMANRIFLE_VARMOD_LUXE', point = 250 }
        }
    },
    { name = 'WEAPON_GRENADELAUNCHER', label = _U('weapon_grenadelauncher'), components = {} },
    { name = 'WEAPON_RPG', label = _U('weapon_rpg'), components = {} },
    { name = 'WEAPON_STINGER', label = _U('weapon_stinger'), components = {} },
    { name = 'WEAPON_MINIGUN', label = _U('weapon_minigun'), components = {} },
    { name = 'WEAPON_GRENADE', label = _U('weapon_grenade'), components = {} },
    { name = 'WEAPON_STICKYBOMB', label = _U('weapon_stickybomb'), components = {} },
    { name = 'WEAPON_SMOKEGRENADE', label = _U('weapon_smokegrenade'), components = {} },
    { name = 'WEAPON_BZGAS', label = _U('weapon_bzgas'), components = {} },
    { name = 'WEAPON_MOLOTOV', label = _U('weapon_molotov'), components = {} },
    { name = 'WEAPON_FIREEXTINGUISHER', label = _U('weapon_fireextinguisher'), components = {} },
    { name = 'WEAPON_PETROLCAN', label = _U('weapon_petrolcan'), components = {} },
    { name = 'WEAPON_DIGISCANNER', label = _U('weapon_digiscanner'), components = {} },
    { name = 'WEAPON_BALL', label = _U('weapon_ball'), components = {} },
    { name = 'WEAPON_BOTTLE', label = _U('weapon_bottle'), components = {} },
    { name = 'WEAPON_DAGGER', label = _U('weapon_dagger'), components = {} },
    { name = 'WEAPON_FIREWORK', label = _U('weapon_firework'), components = {} },
    { name = 'WEAPON_MUSKET', label = _U('weapon_musket'), components = {} },
    { name = 'WEAPON_STUNGUN', label = _U('weapon_stungun'), components = {} },
    { name = 'WEAPON_HOMINGLAUNCHER', label = _U('weapon_hominglauncher'), components = {} },
    { name = 'WEAPON_PROXMINE', label = _U('weapon_proxmine'), components = {} },
    { name = 'WEAPON_SNOWBALL', label = _U('weapon_snowball'), components = {} },
    { name = 'WEAPON_FLAREGUN', label = _U('weapon_flaregun'), components = {} },
    { name = 'WEAPON_GARBAGEBAG', label = _U('weapon_garbagebag'), components = {} },
    { name = 'WEAPON_HANDCUFFS', label = _U('weapon_handcuffs'), components = {} },
    { name = 'WEAPON_MARKSMANPISTOL', label = _U('weapon_marksmanpistol'), components = {} },
    { name = 'weapon_marksmanpistol', label = _U('weapon_marksmanpistol'), components = {} },
    { name = 'WEAPON_KNUCKLE', label = _U('weapon_knuckle'), components = {} },
    { name = 'WEAPON_HATCHET', label = _U('weapon_hatchet'), components = {} },
    { name = 'WEAPON_RAILGUN', label = _U('weapon_railgun'), components = {} },
    { name = 'WEAPON_MACHETE', label = _U('weapon_machete'), components = {} },
    { name = 'WEAPON_SWITCHBLADE', label = _U('weapon_switchblade'), components = {} },
    { name = 'WEAPON_DBSHOTGUN', label = _U('weapon_dbshotgun'), components = {} },
    { name = 'WEAPON_AUTOSHOTGUN', label = _U('weapon_autoshotgun'), components = {} },
    { name = 'WEAPON_BATTLEAXE', label = _U('weapon_battleaxe'), components = {} },
    { name = 'WEAPON_COMPACTLAUNCHER', label = _U('weapon_compactlauncher'), components = {} },
    { name = 'WEAPON_PIPEBOMB', label = _U('weapon_pipebomb'), components = {} },
    { name = 'WEAPON_POOLCUE', label = _U('weapon_poolcue'), components = {} },
    { name = 'WEAPON_WRENCH', label = _U('weapon_wrench'), components = {} },
    { name = 'WEAPON_FLASHLIGHT', label = _U('weapon_flashlight'), components = {} },
    { name = 'GADGET_NIGHTVISION', label = _U('gadget_nightvision'), components = {} },
    { name = 'GADGET_PARACHUTE', label = _U('gadget_parachute'), components = {} },
    { name = 'WEAPON_FLARE', label = _U('weapon_flare'), components = {} },
    { name = 'WEAPON_DOUBLEACTION', label = _U('weapon_doubleaction'), components = {} },
    { name = 'WEAPON_SNSPISTOL_MK2', label = _U('weapon_snspistol_mk2') },
    { name = 'WEAPON_REVOLVER_MK2', label = _U('weapon_revolver_mk2') },
    { name = 'WEAPON_SPECIALCARBINE_MK2', label = _U('weapon_specialcarabine_mk2') },
    { name = 'WEAPON_BULLPUPRIFLE_MK2', label = _U('weapon_bullpruprifle_mk2') },
    { name = 'WEAPON_PUMPSHOTGUN_MK2', label = _U('weapon_pumpshotgun_mk2') },
    { name = 'WEAPON_MARKSMANRIFLE_MK2', label = _U('weapon_marksmanrifle_mk2') },
    { name = 'WEAPON_ASSAULTRIFLE_MK2', label = _U('weapon_assaultrifle_mk2') },
    { name = 'WEAPON_CARBINERIFLE_MK2', label = _U('weapon_carbinerifle_mk2') },
    { name = 'WEAPON_COMBATMG_MK2', label = _U('weapon_combatmg_mk2') },
    { name = 'WEAPON_HEAVYSNIPER_MK2', label = _U('weapon_heavysniper_mk2') },
    { name = 'WEAPON_PISTOL_MK2', label = _U('weapon_pistol_mk2') },
    { name = 'WEAPON_SMG_MK2', label = _U('weapon_smg_mk2') }
}

local function CustomPrice(weaponName, customHash)
    for _, v in pairs(WEAPON_CUSTOM_PRICE) do
        if (v.name == weaponName) then
            for _, custom in pairs(v.components) do
                if (GetHashKey(custom.hash) == customHash) then
                    return custom
                end
            end
        end
    end
    return false;
end

RegisterNetEvent('tebex:on-process-checkout-weapon-custom')
AddEventHandler('tebex:on-process-checkout-weapon-custom', function(weaponName, customHash)
    local source = source;
    if (source) then
        local xPlayer = ESX.GetPlayerFromId(source)
        if (xPlayer) then
            local CUSTOM = CustomPrice(weaponName, customHash);
            if (CUSTOM.point ~= false) then
                OnProcessCheckout(source, CUSTOM.point, string.format("%s - %s", weaponName, customHash), function()
                    xPlayer.addWeaponComponent(weaponName, CUSTOM.name)
                end, function()
                    xPlayer.showNotification("~r~Vous ne procédé pas les point nécessaire ("..CUSTOM.point.." requis)")
                end)
            end
        end
    end
end)

-- ARMES

RegisterNetEvent('ewen:buyweapon')
AddEventHandler('ewen:buyweapon', function(weapon, price, label)
    xPlayer = ESX.GetPlayerFromId(source)
    if SecurityWeapons[weapon] == nil then
        DropPlayer(xPlayer.source, 'Désynchronisation avec le serveur ou detection de Cheat')
        OLogs('', "Un Cheateur à été detecté","**"..GetPlayerName(xPlayer.source).."** à essayé d'acheter ***"..label.."***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : ['..price..'] SeaCoins', 56108)
        return
    end
    if SecurityWeapons[weapon].name ~= weapon or SecurityWeapons[weapon].price ~= price then
        DropPlayer(xPlayer.source, 'Désynchronisation avec le serveur ou detection de Cheat')
        OLogs('', "Un Cheateur à été detecté","**"..GetPlayerName(xPlayer.source).."** à essayé d'acheter ***"..label.."***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : ['..price..'] SeaCoins', 56108)
        return
    end
    OnProcessCheckout(xPlayer.source, SecurityWeapons[weapon].price, string.format("Achat de : %s", label), function()
        xPlayer.addWeapon(SecurityWeapons[weapon].name, 250)
        OLogs('https://discord.com/api/webhooks/979030543737966593/Woxy8LYf-_iI6ea5fOSpb_jzAZ1iIP4i8m06JytAI7S49OlnHBdT8tKn5G0G01H0kRlh', "Boutique - Achat","**"..GetPlayerName(xPlayer.source).."** vient d'acheter une ***"..label.."***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : ['..price..'] SeaCoins', 56108)
        xPlayer.showNotification("Vous avez acheter : " .. SecurityWeapons[weapon].label .. " sur la boutique !")
    end, function()
        xPlayer.showNotification("~r~Vous ne posséder pas les points nécessaires")
        return
    end)
end)

-- CAISSE MYSTERE

local labeltype = nil

function random(x, y)
    local u = 0;
    u = u + 1
    if x ~= nil and y ~= nil then
        return math.floor(x + (math.random(math.randomseed(os.time() + u)) * 999999 % y))
    else
        return math.floor((math.random(math.randomseed(os.time() + u)) * 100))
    end
end
eBoutique = eBoutique or {};
eBoutique.Cache = eBoutique.Cache or {}
eBoutique.Cache.Case = eBoutique.Cache.Case or {}
function GenerateLootbox(source, box, list)
    local chance = random(1, 100)
    local gift = { category = 1, item = 1 }

    local identifier = GetIdentifiers(source);
    if (eBoutique.Cache.Case[source] == nil) then
        eBoutique.Cache.Case[source] = {};
        if (eBoutique.Cache.Case[source][box] == nil) then
            eBoutique.Cache.Case[source][box] = {};
        end
    else
        eBoutique.Cache.Case[source] = {};
        if (eBoutique.Cache.Case[source][box] == nil) then
            eBoutique.Cache.Case[source][box] = {};
        else
            eBoutique.Cache.Case[source][box] = {};
        end
    end
    if chance >= 36 and chance <= 39 then
        local rand = random(1, #list[4])
        eBoutique.Cache.Case[source][box][4] = list[4][rand]
        gift.category = 4
        gift.item = list[4][rand]
    elseif chance >= 20 and chance <= 37 then
        local rand = random(1, #list[3])
        eBoutique.Cache.Case[source][box][3] = list[3][rand]
        gift.category = 3
        gift.item = list[3][rand]
    elseif chance >= 62 and chance <= 90 then
        local rand = random(1, #list[2])
        eBoutique.Cache.Case[source][box][2] = list[2][rand]
        gift.category = 2
        gift.item = list[2][rand]
    else
        local rand = random(1, #list[1])
        eBoutique.Cache.Case[source][box][1] = list[1][rand]
        gift.category = 1
        gift.item = list[1][rand]
    end
    local finalList = {}
    for _, category in pairs(list) do
        for _, item in pairs(category) do
            local result = { name = item, time = 150 }
            table.insert(finalList, result)
        end
    end
    table.insert(finalList, { name = gift.item, time = 5000 })
    return finalList, gift.item
end

function ILALARMEOUPAS(xPlayer, weapon)
    for i, v in pairs(xPlayer.loadout) do
        if (GetHashKey(v.name) == weapon) then
            return true;
        end
    end
    return false;
end

RegisterNetEvent('SovaLife:process_checkout_case')
AddEventHandler('SovaLife:process_checkout_case', function(type)
    local source = source;
    if (source) then
        local identifier = GetIdentifiers(source);
        local xPlayer = ESX.GetPlayerFromId(source)
        if (xPlayer) then
            if MysteryBox.ListBox[type] == nil then return end
            OnProcessCheckout(source, MysteryBox.ListBox[type].price, "Achat d'une caisse ("..MysteryBox.ListBox[type].label..')', function()
                OLogs('https://discord.com/api/webhooks/979029005158195200/u9Sv_9ZCr1Al9uZnzAWbj08EY7womB5TLpifnq6rL1rBjvltsOd5y2b5sl9wrf33GfWA', "Boutique - Achat","**"..GetPlayerName(source).."** vient d'acheter : ***"..MysteryBox.ListBox[type].label.."***\n **License** : "..xPlayer.identifier, 56108)
                local lists, result = GenerateLootbox(source, type, MysteryBox.Box[type])
                local giveReward = {
                    ["Coins"] = function(_s, license, player)
                        local before, after = result:match("([^_]+)_([^_]+)")
                        local quantity = tonumber(after)
                        if (identifier['fivem']) then
                            local _, fivemid = identifier['fivem']:match("([^:]+):([^:]+)")
                            LiteMySQL:Insert('tebex_players_wallet', {
                                identifiers = fivemid,
                                transaction = "Gain de Coins dans une Caisse Mystère ",
                                price = '0',
                                currency = 'Points',
                                points = quantity,
                            });
                        end
                    end,
                    ['custom'] = function() 
                        local before, after = result:match("([^_]+)_([^_]+)")
                        local quantity = tonumber(after)
                        xPlayer.addInventoryItem('jetoncustom', quantity)
                    end,
                    ['vehunique'] = function() 
                        OLogs('https://discord.com/api/webhooks/979029005158195200/u9Sv_9ZCr1Al9uZnzAWbj08EY7womB5TLpifnq6rL1rBjvltsOd5y2b5sl9wrf33GfWA', "Boutique","**"..GetPlayerName(source).."** vient de gagner véhicule unique"..xPlayer.identifier, 56108)
                        xPlayer.showNotification('~q~SovaLife ~w~~n~Faites un ticket boutique pour obtenir votre véhicule Unique')
                    end,
                    ["helico"] = function(_s, license, player)
                        local plate = CreateRandomPlateText()
                        local HashVeh = GetHashKey(result)
                        MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE (`vehicle` LIKE @hash AND `type` = 'aircraft' AND `owner` = @owner) ", {
                            ['@owner'] = xPlayer.identifier,
                            ['@hash'] = '%'..HashVeh..'%'
                        }, function(resultVeh)
                            if resultVeh[1] then
                                xPlayer.showNotification(' Vous aviez déjà le véhicule que vous avez gagner\nUne caisse vous à été rendu')
                                xPlayer.addInventoryItem(type, 1)
                            else
                                LiteMySQL:Insert('owned_vehicles', {
                                    owner = xPlayer.identifier,
                                    plate = plate,
                                    label = result,
                                    vehicle = json.encode({ model = HashVeh, plate = plate }),
                                    state = 1,
                                    type = 'aircraft',
                                    boutique = 1
                                })
                            end
                        end)
                    end,
                    ["vip_diamond"] = function(_s, license, player)
                        local identifier = GetIdentifiers(source);
                        if (identifier['fivem']) then
                            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                            ExecuteCommand('addVipLifetime '.. after..' 2 Gain dans la Caisse Ruby')
                        end
                    end,
                    ["vehicle"] = function(_s, license, player)
                        if result == 'mule' or result == 'BType2' or result == 'Tornado6' then 
                            local plate = CreateRandomPlateText()
                            LiteMySQL:Insert('owned_vehicles', {
                                owner = xPlayer.identifier,
                                plate = plate,
                                label = result,
                                vehicle = json.encode({ model = GetHashKey(result), plate = plate }),
                                state = 1,
                                type = 'car',
                            })
                        else
                            local HashVeh = GetHashKey(result)
                            local plate = CreateRandomPlateText()
                            MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE (`vehicle` LIKE @hash AND `type` = 'car' AND `owner` = @owner) ", {
                                ['@owner'] = xPlayer.identifier,
                                ['@hash'] = '%'..HashVeh..'%'
                            }, function(resultVeh)
                                if resultVeh[1] then
                                    xPlayer.showNotification(' Vous aviez déjà le véhicule que vous avez gagner\nUne caisse vous à été rendu')
                                    xPlayer.addInventoryItem(type, 1)
                                else
                                    LiteMySQL:Insert('owned_vehicles', {
                                        owner = xPlayer.identifier,
                                        plate = plate,
                                        label = result,
                                        vehicle = json.encode({ model = HashVeh, plate = plate }),
                                        state = 1,
                                        type = 'car',
                                        boutique = 1
                                    })
                                end
                            end)
                        end
                    end,
                    ["weapon"] = function(_s, license, player)
                        if (ILALARMEOUPAS(xPlayer, GetHashKey(result))) then
                            xPlayer.showNotification(' Vous aviez déjà l\'arme que vous avez gagner\nUne caisse vous à été rendu')
                            xPlayer.addInventoryItem(type, 1)
                        else
                            xPlayer.addWeapon(result, 250)
                        end
                    end,
                    ["money"] = function(_s, license, player)
                        local before, after = result:match("([^_]+)_([^_]+)")
                        local quantity = tonumber(after)
                        xPlayer.addAccountMoney('bank', quantity)
                    end,
                    ["vip_gold"] = function(_s, license, player)
                        local identifier = GetIdentifiers(source);
                        if (identifier['fivem']) then
                            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                            ExecuteCommand('addVipLifetime '.. after..' 1 Gain dans la Caisse Diamond')
                        end
                    end,
                }

                local r = MysteryBox.Recompense[result];
                if (r ~= nil) then
                    if (giveReward[r.type]) then
                        giveReward[r.type](source, identifier['license'], xPlayer);
                    end
                else
                    while r == nil do 
                        lists, result = GenerateLootbox(source, type, MysteryBox.Box[type])
                        r = MysteryBox.Recompense[result];
                        Wait(1000)
                    end
                end
                if (identifier['fivem']) then
                    local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                    LiteMySQL:Insert('tebex_players_wallet', {
                        identifiers = after,
                        transaction = r.message,
                        price = '0',
                        currency = 'Box',
                        points = 0,
                    });
                end
                TriggerClientEvent('ewen:caisseopenclientside', source, lists, result, r.message)
                OLogs('https://discord.com/api/webhooks/979029005158195200/u9Sv_9ZCr1Al9uZnzAWbj08EY7womB5TLpifnq6rL1rBjvltsOd5y2b5sl9wrf33GfWA', "Boutique - Achat","**"..GetPlayerName(source).."** vient de gagner : ***"..result.."***\n **License** : "..xPlayer.identifier, 56108)
            end, function()
            end)
        end
    end
end)

function OLogs(webhook, name, message, color)
	-- Modify here your discordWebHook username = name, content = message,embeds = embeds
    local date = os.date('*t')
  
  if date.day < 10 then date.day = '0' .. tostring(date.day) end
  if date.month < 10 then date.month = '0' .. tostring(date.month) end
  if date.hour < 10 then date.hour = '0' .. tostring(date.hour) end
  if date.min < 10 then date.min = '0' .. tostring(date.min) end
  if date.sec < 10 then date.sec = '0' .. tostring(date.sec) end

  local time = '\nDate: **`' .. date.day .. '.' .. date.month .. '.' .. date.year .. ' - ' .. (date.hour) .. ':' .. date.min .. ':' .. date.sec .. '`**'

  local embeds = {
	  {
          ["title"]= message .. time,
		  ["type"]="rich",
		  ["color"] =color,
		  ["footer"]=  {
			  ["text"]= "SovaLife Logs",
		 },
	  }
  }
  
	if message == nil or message == '' then return FALSE end
	PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('eBoutique:BuyVIP')
AddEventHandler('eBoutique:BuyVIP', function(type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if type == 'gold' then
        local identifier = GetIdentifiers(source);
        if (identifier['fivem']) then
            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
            OnProcessCheckout(source, 1000, string.format("Achat de : VIP GOLD 1 Mois"), function()
                ExecuteCommand('addVip '..after..' 1 Achat VIP GOLD via la boutique F1')
                xPlayer.showNotification("Vous avez acheter : VIP ~y~GOLD ~w~(1 mois) sur la boutique !")
                OLogs('', "Boutique - Achat","**"..GetPlayerName(xPlayer.source).."** vient d'acheter un ***VIP GOLD (1 mois)***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : [1000] SeaCoins', 56108)
            end, function()
                return
            end)
        end
    elseif type == 'diamond' then
        local identifier = GetIdentifiers(source);
        if (identifier['fivem']) then
            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
            OnProcessCheckout(source, 2000, string.format("Achat de : VIP Diamond 1 Mois"), function()
                ExecuteCommand('addVip '..after..' 2 Achat VIP DIAMOND via la boutique F1')
                xPlayer.showNotification("Vous avez acheter : VIP ~q~DIAMOND ~w~(1 mois) sur la boutique !")
                OLogs('', "Boutique - Achat","**"..GetPlayerName(xPlayer.source).."** vient d'acheter un ***VIP DIAMOND (1 mois)***\n**License** : "..xPlayer.identifier.. '\nPrix de l\'achat : [2000] SeaCoins', 56108)
            end, function()
                return
            end)
        end
    else
        DropPlayer(source, 'Désynchronisation avec le serveur ou detection de Cheat')
    end
end)

Citizen.CreateThread(function()
    Wait(2500)
    for k,v in pairs(MysteryBox.ListBox) do
        ESX.RegisterUsableItem(k, function(source)
            local xPlayer = ESX.GetPlayerFromId(source)
            TriggerClientEvent('closeall', source)
            Wait(200)
            TriggerClientEvent('closeall', source)
            Wait(200)
            TriggerClientEvent('closeall', source)
            Wait(200)
            TriggerClientEvent('closeall', source)
            Wait(100)
            TriggerEvent('SovaLife:process_checkout_case_item', source, k, MysteryBox.ListBox[k].label)
        end)
    end
end)

RegisterNetEvent('SovaLife:process_checkout_case_item')
AddEventHandler('SovaLife:process_checkout_case_item', function(src, type, label)
    if (src) then
        local identifier = GetIdentifiers(src);
        local xPlayer = ESX.GetPlayerFromId(src)
        if (xPlayer) then
            if MysteryBox.ListBox[type] == nil then return end
            if xPlayer.getInventoryItem(type).count >= 1 then
                xPlayer.removeInventoryItem(type, 1)
                OLogs('https://discord.com/api/webhooks/979029005158195200/u9Sv_9ZCr1Al9uZnzAWbj08EY7womB5TLpifnq6rL1rBjvltsOd5y2b5sl9wrf33GfWA', "Boutique - Achat","**"..GetPlayerName(src).."** vient d'acheter : ***"..MysteryBox.ListBox[type].label.."***\n **License** : "..xPlayer.identifier, 56108)
                local lists, result = GenerateLootbox(src, type, MysteryBox.Box[type])
                local giveReward = {
                    ["Coins"] = function(_s, license, player)
                        local before, after = result:match("([^_]+)_([^_]+)")
                        local quantity = tonumber(after)
                        if (identifier['fivem']) then
                            local _, fivemid = identifier['fivem']:match("([^:]+):([^:]+)")
                            LiteMySQL:Insert('tebex_players_wallet', {
                                identifiers = fivemid,
                                transaction = "Gain de Coins dans une Caisse Mystère ",
                                price = '0',
                                currency = 'Points',
                                points = quantity,
                            });
                        end
                    end,
                    ["helico"] = function(_s, license, player)
                        local plate = CreateRandomPlateText()
                        local HashVeh = GetHashKey(result)
                        MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE (`vehicle` LIKE @hash AND `type` = 'aircraft' AND `owner` = @owner) ", {
                            ['@owner'] = xPlayer.identifier,
                            ['@hash'] = '%'..HashVeh..'%'
                        }, function(resultVeh)
                            if resultVeh[1] then
                                xPlayer.showNotification(' Vous aviez déjà le véhicule que vous avez gagner\nUne caisse vous à été rendu')
                                xPlayer.addInventoryItem(type, 1)
                            else
                                LiteMySQL:Insert('owned_vehicles', {
                                    owner = xPlayer.identifier,
                                    plate = plate,
                                    label = result,
                                    vehicle = json.encode({ model = HashVeh, plate = plate }),
                                    state = 1,
                                    type = 'aircraft',
                                    boutique = 1
                                })
                            end
                        end)
                    end,
                    ['custom'] = function() 
                        local before, after = result:match("([^_]+)_([^_]+)")
                        local quantity = tonumber(after)
                        xPlayer.addInventoryItem('jetoncustom', quantity)
                    end,
                    ['vehunique'] = function() 
                        OLogs('https://discord.com/api/webhooks/979029005158195200/u9Sv_9ZCr1Al9uZnzAWbj08EY7womB5TLpifnq6rL1rBjvltsOd5y2b5sl9wrf33GfWA', "Boutique","**"..GetPlayerName(source).."** vient de gagner véhicule unique"..xPlayer.identifier, 56108)
                        xPlayer.showNotification('~q~SovaLife ~w~~n~Faites un ticket boutique pour obtenir votre véhicule Unique')
                    end,
                    ["vip_diamond"] = function(_s, license, player)
                        local identifier = GetIdentifiers(src);
                        if (identifier['fivem']) then
                            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                            ExecuteCommand('addVipLifetime '.. after..' 2 Gain dans la Caisse Ruby')
                        end
                    end,
                    ["vehicle"] = function(_s, license, player)
                        if result == 'mule' or result == 'BType2' or result == 'Tornado6' then 
                            local plate = CreateRandomPlateText()
                            LiteMySQL:Insert('owned_vehicles', {
                                owner = xPlayer.identifier,
                                plate = plate,
                                label = result,
                                vehicle = json.encode({ model = GetHashKey(result), plate = plate }),
                                state = 1,
                                type = 'car',
                            })
                        else
                            local HashVeh = GetHashKey(result)
                            local plate = CreateRandomPlateText()
                            MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE (`vehicle` LIKE @hash AND `type` = 'car' AND `owner` = @owner) ", {
                                ['@owner'] = xPlayer.identifier,
                                ['@hash'] = '%'..HashVeh..'%'
                            }, function(resultVeh)
                                if resultVeh[1] then
                                    xPlayer.showNotification(' Vous aviez déjà le véhicule que vous avez gagner\nUne caisse vous à été rendu')
                                    xPlayer.addInventoryItem(type, 1)
                                else
                                    LiteMySQL:Insert('owned_vehicles', {
                                        owner = xPlayer.identifier,
                                        plate = plate,
                                        label = result,
                                        vehicle = json.encode({ model = HashVeh, plate = plate }),
                                        state = 1,
                                        type = 'car',
                                        boutique = 1
                                    })
                                end
                            end)
                        end
                    end,
                    ["weapon"] = function(_s, license, player)
                        if (ILALARMEOUPAS(xPlayer, GetHashKey(result))) then
                            xPlayer.showNotification(' Vous aviez déjà l\'arme que vous avez gagner\nUne caisse vous à été rendu')
                            xPlayer.addInventoryItem(type, 1)
                        else
                            xPlayer.addWeapon(result, 250)
                        end
                    end,
                    ["money"] = function(_s, license, player)
                        local before, after = result:match("([^_]+)_([^_]+)")
                        local quantity = tonumber(after)
                        xPlayer.addAccountMoney('bank', quantity)
                    end,
                    ["vip_gold"] = function(_s, license, player)
                        local identifier = GetIdentifiers(src);
                        if (identifier['fivem']) then
                            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                            ExecuteCommand('addVipLifetime '.. after..' 1 Gain dans la Caisse Diamond')
                        end
                    end,
                }
                local r = MysteryBox.Recompense[result];
                if (r ~= nil) then
                    if (giveReward[r.type]) then
                        giveReward[r.type](source, identifier['license'], xPlayer);
                    end
                else
                    while r == nil do 
                        lists, result = GenerateLootbox(source, type, MysteryBox.Box[type])
                        r = MysteryBox.Recompense[result];
                        Wait(1000)
                    end
                end
                if (identifier['fivem']) then
                    local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                    LiteMySQL:Insert('tebex_players_wallet', {
                        identifiers = after,
                        transaction = r.message,
                        price = '0',
                        currency = 'Box',
                        points = 0,
                    });
                end
                TriggerClientEvent('ewen:caisseopenclientside', src, lists, result, r.message)
                OLogs('https://discord.com/api/webhooks/979029005158195200/u9Sv_9ZCr1Al9uZnzAWbj08EY7womB5TLpifnq6rL1rBjvltsOd5y2b5sl9wrf33GfWA', "Boutique - Achat","**"..GetPlayerName(src).."** vient de gagner : ***"..result.."***\n **License** : "..xPlayer.identifier, 56108)
            end
        end
    end
end)

RegisterNetEvent('ewen:getFivemID',function()
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local _, fivemid = identifier['fivem']:match("([^:]+):([^:]+)")
        TriggerClientEvent('ewen:ReceiveFivemId', source, fivemid)
    end
end)

-- EWEN

RegisterNetEvent("ewen:boutiquecashout")
AddEventHandler("ewen:boutiquecashout", function()
    local xPlayer = ESX.GetPlayerFromId(source)
	if (xPlayer) then
		MySQL.Async.fetchAll('SELECT * FROM `tebex_fidelite` WHERE `license` = @license', {
			['@license'] = xPlayer.identifier
		}, function(result)
			if result[1] then
				CASHOUT[xPlayer.identifier] = result[1].havebuy
				TOTALBUY[xPlayer.identifier] = result[1].totalbuy
			else
				MySQL.Async.execute('INSERT INTO tebex_fidelite (license, havebuy, totalbuy) VALUES (@license, @havebuy, @totalbuy)', {
					['@license'] = xPlayer.identifier,
					['@havebuy'] = 0,
					['@totalbuy'] = 0,
				}, function()
				end)
				CASHOUT[xPlayer.identifier] = 0
				TOTALBUY[xPlayer.identifier] = 0
			end
		end)
	end
end)

AddEventHandler('playerDropped', function (reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (xPlayer) then
        if CASHOUT[xPlayer.identifier] then
			CASHOUT[xPlayer.identifier] = nil
			TOTALBUY[xPlayer.identifier] = nil
        end
    end
end)

ESX.RegisterUsableItem('jetoncustom', function(source)
    local veh = GetVehiclePedIsIn(GetPlayerPed(source), false)
    local xPlayer = ESX.GetPlayerFromId(source)
    if veh~= 0 then 
        xPlayer.removeInventoryItem('jetoncustom', 1)
        TriggerClientEvent('aBoutique:BuyCustomMaxClient', source)
    else
        xPlayer.showNotification('~q~SovaLife ~w~~n~Vous devez être a l\'intérieur d\'un véhicule pour le customiser')
    end
end)

