local selected = nil;
local VehicleJournalier = {}
Citizen.CreateThread(function()
    while (true) do
        Citizen.Wait(1000)
        local weapon = GetSelectedPedWeapon(PlayerPedId());
        if (weapon ~= GetHashKey("weapon_unarmed")) and (weapon ~= 966099553) and (weapon ~= 0) then
            if (selected ~= nil) and (weapon == GetHashKey("weapon_unarmed")) and (weapon == 966099553) and (weapon == 0) then
                selected = nil;
            end
            for i, v in pairs(ESX.GetWeaponList()) do
                if (GetHashKey(v.name) == weapon) then
                    selected = v
                end
            end
        else
            selected = nil;
        end

    end
end)

RegisterCommand("menuboutique", function()
    if not PlayerIsDead then 
        OpenMenuMain()
    end
end, false)
RegisterKeyMapping('menuboutique', 'Menu Boutique', 'keyboard', 'f1')

local SeaCoins = 0
local LastVeh = nil
local InVehicle = false
local lastPos = nil
local rot = nil
local index = {
    list = 1
}

local history = {}

local Button = 1

local Action = {
   'Visualiser',
   'Acheter'
}

Citizen.CreateThread(function()
    Wait(2500)
    TriggerServerEvent('ewen:getFivemID')
end)


function onRetrieveHistory()
    ESX.TriggerServerCallback('tebex:retrieve-history', function(result)
        history = result;
    end)
end

RegisterNetEvent('ewen:ReceiveFivemId', function(ReceiveInfo)
    fivemid = ReceiveInfo
end)

local VehicleSpawned = {}
function OpenMenuMain()
    local menu = RageUI.CreateMenu("", "Bienvenue sur notre boutique")
    local historyMenu = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local vehicles = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local voitures = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local avionhelico = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local bateaux = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local PacksMenu = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local ArmesMenu = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local CustomMenu = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local ArmesShopMenu = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    local CaseMenu = RageUI.CreateSubMenu(menu, "", "Bienvenue sur notre boutique")
    CustomMenu.onIndexChange = function(index)
        if (selected ~= nil) then
            GiveWeaponComponentToPed(PlayerPedId(), GetHashKey(selected.name), selected.components[index].hash)
            if (selected.components[index - 1] ~= nil) and (selected.components[index - 1].hash ~= nil) then
                RemoveWeaponComponentFromPed(PlayerPedId(), GetHashKey(selected.name), selected.components[index - 1].hash)
            end
            if (index == 1) then
                RemoveWeaponComponentFromPed(PlayerPedId(), GetHashKey(selected.name), selected.components[#selected.components].hash)
            end
        end
    end
    CustomMenu.Closed = function() 
        TriggerEvent('esx:restoreLoadout')
    end
    voitures.Closed = function() 
        DeleteEntity(LastVeh)
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, 0)
        SetEntityCoords(PlayerPedId(), lastPos)
        SetFollowPedCamViewMode(1)
        for k,v in pairs(VehicleSpawned) do 
            if DoesEntityExist(v.model) then
                Wait(150)
                DeleteEntity(v.model)
                table.remove(VehicleSpawned, k)
            end
        end
        TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', false)
    end
    avionhelico.Closed = function() 
        DeleteEntity(LastVeh)
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, 0)
        SetEntityCoords(PlayerPedId(), lastPos)
        SetFollowPedCamViewMode(1)
        for k,v in pairs(VehicleSpawned) do 
            if DoesEntityExist(v.model) then
                Wait(150)
                DeleteEntity(v.model)
                table.remove(VehicleSpawned, k)
            end
        end
        TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', false)
    end
    bateaux.Closed = function() 
        DeleteEntity(LastVeh)
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, 0)
        SetEntityCoords(PlayerPedId(), lastPos)
        SetFollowPedCamViewMode(1)
        for k,v in pairs(VehicleSpawned) do 
            if DoesEntityExist(v.model) then
                Wait(150)
                DeleteEntity(v.model)
                table.remove(VehicleSpawned, k)
            end
        end
        TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', false)
    end
    ESX.TriggerServerCallback('ewen:getPoints', function(result)
        SeaCoins = result
    end)
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu ~= nil do
        RageUI.IsVisible(menu, function()
            RageUI.Separator('~y~↓ Vos Informations ↓')
            if fivemid == nil then 
                fivemid = "Vous n'etes pas connecté"
            end
            RageUI.Separator('Code Boutique : ~q~'..fivemid)
            RageUI.Separator('Vos ~q~Sova~w~Coins : ~q~'..SeaCoins)
            local viptext = GetVIP() == 1 or GetVIP() == true and '~o~Premium' or 'Aucun'
            RageUI.Separator('VIP : '..viptext)
            
            RageUI.Separator('~y~↓ Nos catégories ↓')
            
            RageUI.Button('Historique', nil, {}, true, {
                onSelected = function()
                    onRetrieveHistory()
                end
            }, historyMenu)
            if GetSafeZone() then
                RageUI.Button('Voitures', nil, {}, true, {
                    onSelected = function()

                    end
                }, vehicles)
            else
                RageUI.Button('Voitures', 'Vous devez être en Zone Safe pour acceder à cette catégorie', {RightBadge = RageUI.BadgeStyle.Lock}, true, {
                    onSelected = function()
                        ESX.ShowNotification(' Vous devez être en Zone Safe pour acceder à cette catégorie')
                    end
                })
            end
            RageUI.Button('Packs', nil, {}, true, {
                onSelected = function()
                    
                end
            }, PacksMenu)
            RageUI.Button('Armes', nil, {}, true, {
                onSelected = function()
                    
                end
            }, ArmesMenu)
            RageUI.Button('Caisse Mystère', nil, {}, true, {
                onSelected = function()
                    
                end
            }, CaseMenu)
        end)
        RageUI.IsVisible(historyMenu, function()
            if (#history > 0) then
                for i, v in pairs(history) do
                    local label;
                    if (tonumber(v.price) == 0) then
                        label = string.format("%s", v.points)
                    else
                        label = string.format("%s (%s%s)", v.points, v.price, v.currency);
                    end
                    RageUI.Button(v.transaction, nil, { RightLabel = label }, true, {
                        onSelected = function()

                        end,
                    });

                end
            else
                RageUI.Separator("")
                RageUI.Separator("Aucune transactions effectues.");
                RageUI.Separator("")
            end
        end)
        RageUI.IsVisible(vehicles, function()
            RageUI.Button('Voitures', nil, {}, true, {
                onSelected = function()
                    lastPos = GetEntityCoords(PlayerPedId())
                    rot = 1.0
                    SetEntityCoords(PlayerPedId(), vector3(-74.9472, -812.6113, 325.1751))
                    SetEntityHeading(PlayerPedId(), 184.531)
                    TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', true)
                end
            }, voitures)
            RageUI.Button('Avion/Hélicoptère', nil, {}, true, {
                onSelected = function()
                    lastPos = GetEntityCoords(PlayerPedId())
                    rot = 1.0
                    SetEntityCoords(PlayerPedId(), vector3(-964.772, -2988.266, 13.945))
                    SetEntityHeading(PlayerPedId(), 150.864)
                    TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', true)
                end
            }, avionhelico)
            RageUI.Button('Bateaux', nil, {}, true, {
                onSelected = function()
                    lastPos = GetEntityCoords(PlayerPedId())
                    rot = 1.0
                    SetEntityCoords(PlayerPedId(), vector3(530.6523, -3371.662, 5.361))
                    SetEntityHeading(PlayerPedId(), 282.959)
                    TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', true)
                end
            },bateaux)
        end)
        RageUI.IsVisible(voitures, function()
            for k,v in pairs(BoutiqueVehicles) do
                RageUI.List(v.label..' | Prix : ~r~'..v.price, Action, index.list, nil, {}, true, {
                    onActive = function()
                        FreezeEntityPosition(PlayerPedId(), true)
                        SetEntityVisible(PlayerPedId(), false, 0)
                        SetWeatherTypeNow('EXTRASUNNY')
                        SetFollowPedCamViewMode(4)
                        if LastVeh ~= nil then
                            rot = rot + 0.10
                            SetEntityHeading(LastVeh, rot)
                        end
                    end,
                    onListChange = function(Index, Item)
                        index.list = Index;
                        Button = Index;
                    end,
                    onSelected = function()
                        if Button == 1 then
                            if ESX.Game.IsSpawnPointClear(vector3(-75.16219, -819.2629, 325.1755), 100) then
                                ESX.Game.SpawnLocalVehicle(v.model, vector3(-75.16219, -819.2629, 325.1755), 355.858, function(vehicle)
                                    LastVeh = vehicle
                                    FreezeEntityPosition(vehicle, true)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDirtLevel(vehicle, 0.0)
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    SetVehicleLights(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                    table.insert(VehicleSpawned, {model = vehicle})
                                end)
                            else
                                DeleteEntity(LastVeh)
                                ESX.Game.SpawnLocalVehicle(v.model, vector3(-75.16219, -819.2629, 325.1755), 355.858, function(vehicle)
                                    LastVeh = vehicle
                                    FreezeEntityPosition(vehicle, true)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDirtLevel(vehicle, 0.0)
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    SetVehicleLights(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                    table.insert(VehicleSpawned, {model = vehicle})
                                end)
                            end
                        elseif Button == 2 then
                            TriggerServerEvent('aBoutique:BuyVehicle', v.model, v.price, v.label)
                            DeleteEntity(LastVeh)
                            FreezeEntityPosition(PlayerPedId(), false)
                            SetEntityVisible(PlayerPedId(), true, 0)
                            SetEntityCoords(PlayerPedId(), lastPos)
                            SetFollowPedCamViewMode(1)
                            for k,v in pairs(VehicleSpawned) do 
                                if DoesEntityExist(v.model) then
                                    Wait(150)
                                    DeleteEntity(v.model)
                                    table.remove(VehicleSpawned, k)
                                end
                            end
                            TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', false)
                            RageUI.CloseAll()                          
                        end
                    end
                })
            end
        end)
        RageUI.IsVisible(avionhelico, function()
            for k,v in pairs(BoutiqueAirPlaines) do 
                RageUI.List(GetLabelText(v.model)..' | Prix : ~r~'..v.price, Action, index.list, nil, {}, true, {
                    onActive = function()
                        FreezeEntityPosition(PlayerPedId(), true)
                        SetEntityVisible(PlayerPedId(), false, 0)
                        SetWeatherTypeNow('EXTRASUNNY')
                        SetFollowPedCamViewMode(4)
                        if LastVeh ~= nil then
                            rot = rot + 0.10
                            SetEntityHeading(LastVeh, rot)
                        end
                    end,
                    onListChange = function(Index, Item)
                        index.list = Index;
                        Button = Index;
                    end,
                    onSelected = function()
                        if Button == 1 then
                            if ESX.Game.IsSpawnPointClear(vector3(-970.8639, -2999.831, 13.945), 100) then
                                ESX.Game.SpawnLocalVehicle(v.model, vector3(-970.8639, -2999.831, 13.945), 337.120, function(vehicle)
                                    LastVeh = vehicle
                                    FreezeEntityPosition(vehicle, true)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDirtLevel(vehicle, 0.0)
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    SetVehicleLights(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                    table.insert(VehicleSpawned, {model = vehicle})
                                end)
                            else
                                DeleteEntity(LastVeh)
                                ESX.Game.SpawnLocalVehicle(v.model, vector3(-970.8639, -2999.831, 13.945), 337.120, function(vehicle)
                                    LastVeh = vehicle
                                    FreezeEntityPosition(vehicle, true)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDirtLevel(vehicle, 0.0)
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    SetVehicleLights(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                    table.insert(VehicleSpawned, {model = vehicle})
                                end)
                            end
                        elseif Button == 2 then
                            TriggerServerEvent('aBoutique:BuyVehiclePlane', v.model, GetLabelText(v.model))
                            DeleteEntity(LastVeh)
                            FreezeEntityPosition(PlayerPedId(), false)
                            SetEntityVisible(PlayerPedId(), true, 0)
                            SetEntityCoords(PlayerPedId(), lastPos)
                            SetFollowPedCamViewMode(1)
                            for k,v in pairs(VehicleSpawned) do 
                                if DoesEntityExist(v.model) then
                                    Wait(150)
                                    DeleteEntity(v.model)
                                    table.remove(VehicleSpawned, k)
                                end
                            end
                            TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', false)
                            RageUI.CloseAll()     
                        end
                    end
                })
            end
		end)

        RageUI.IsVisible(bateaux, function()
            for k,v in pairs(BoutiqueBoat) do 
                RageUI.List(GetLabelText(v.model)..' | Prix : ~r~'..v.price, Action, index.list, nil, {}, true, {
                    onActive = function()
                        FreezeEntityPosition(PlayerPedId(), true)
                        SetEntityVisible(PlayerPedId(), false, 0)
                        SetWeatherTypeNow('EXTRASUNNY')
                        SetFollowPedCamViewMode(4)
                        if LastVeh ~= nil then
                            rot = rot + 0.10
                            SetEntityHeading(LastVeh, rot)
                        end
                    end,
                    onListChange = function(Index, Item)
                        index.list = Index;
                        Button = Index;
                    end,
                    onSelected = function()
                        if Button == 1 then
                            if ESX.Game.IsSpawnPointClear(vector3(550.243, -3378.061, 5.843), 100) then
                                ESX.Game.SpawnLocalVehicle(v.model, vector3(550.243, -3378.061, 5.843), 282.959, function(vehicle)
                                    LastVeh = vehicle
                                    FreezeEntityPosition(vehicle, true)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDirtLevel(vehicle, 0.0)
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    SetVehicleLights(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                    table.insert(VehicleSpawned, {model = vehicle})
                                end)
                            else
                                DeleteEntity(LastVeh)
                                ESX.Game.SpawnLocalVehicle(v.model, vector3(550.243, -3378.061, 5.843), 282.959, function(vehicle)
                                    LastVeh = vehicle
                                    FreezeEntityPosition(vehicle, true)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDirtLevel(vehicle, 0.0)
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    SetVehicleLights(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                    table.insert(VehicleSpawned, {model = vehicle})
                                end)
                            end
                        elseif Button == 2 then
                            TriggerServerEvent('aBoutique:BuyVehicleBoat', v.model, GetLabelText(v.model))
                            DeleteEntity(LastVeh)
                            FreezeEntityPosition(PlayerPedId(), false)
                            SetEntityVisible(PlayerPedId(), true, 0)
                            SetEntityCoords(PlayerPedId(), lastPos)
                            SetFollowPedCamViewMode(1)
                            for k,v in pairs(VehicleSpawned) do 
                                if DoesEntityExist(v.model) then
                                    Wait(150)
                                    DeleteEntity(v.model)
                                    table.remove(VehicleSpawned, k)
                                end
                            end
                            TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', false)
                            RageUI.CloseAll() 
                        end
                    end
                })
            end
		end)
        RageUI.IsVisible(PacksMenu, function() 
            RageUI.Button('Crée ton Entreprise/organisation', 'Créer un(e) Entreprise/Organisation\nGere tes membres', {RightLabel = 2500}, true, {
                onSelected = function()
                    TriggerServerEvent('aBoutique:Illegal')
                    RageUI.CloseAll()
                end
            })
            RageUI.Button('Customise ta voiture ( Performance )', 'Selectionne ta voiture\nCustomise la a fond\nBas tes adversaires en vitesse !', {RightLabel = 1000}, true, {
                onSelected = function()
                    if IsPedSittingInAnyVehicle(PlayerPedId()) then
                        local vehicle = GetVehiclePedIsUsing(PlayerPedId())
                        TriggerServerEvent('aBoutique:BuyCustomMax', vehicle)
                        RageUI.CloseAll()
                    else
                        ESX.ShowNotification('Vous devez être a l\'intérieur d\'un véhicule.')
                    end
                end
            })
        end)

        RageUI.IsVisible(ArmesMenu, function() 
         --   RageUI.Button('Armes', nil, {}, true, {
               -- onSelected = function()

              --  end
         --   }, ArmesShopMenu)
            RageUI.Button('Customisation d\'armes', nil, {}, true, {
                onSelected = function()

                end
            }, CustomMenu)
        end)
        RageUI.IsVisible(ArmesShopMenu, function()
            for k,v in pairs(WeaponBoutique) do
                RageUI.Button(v.label, v.description, {RightLabel = 'Prix : '.. v.price}, true, {
                    onActive = function()
                        RageUI.RenderWeapons("vehicles", v.name)
                    end,
                    onSelected = function()
                        TriggerServerEvent('ewen:buyweapon', v.name, v.price, v.label)
                        RageUI.CloseAll()
                    end
                })
             end
        end)
        RageUI.IsVisible(CustomMenu, function() 
            if (selected) then
                if (ESX.Table.SizeOf(selected) > 0) then
                    for i, v in pairs(selected.components) do
                        RageUI.Button(v.label, nil, { RightLabel = "~r~Acheter ~w~→250" }, true, {
                            onSelected = function()
                                TriggerServerEvent('tebex:on-process-checkout-weapon-custom', selected.name, v.hash)
                                ESX.ShowNotification('Vous avez acheter '..v.label.. ' pour 250 ~q~SovaLifeCoins')
                            end,
                        })
                    end
                else
                    RageUI.Separator("Aucune personnalisation disponible")
                end
            else
                RageUI.Separator("Vous n'avez pas d'arme dans vos main")
            end
        end)
        RageUI.IsVisible(CaseMenu, function() 
            for k,v in pairs(BoutiqueMysteryBox) do
                if v.model ~= 'caisse_fidelite' then
                    RageUI.List(v.label..' | Prix : ~r~'..v.price, Action, index.list, nil, {}, true, {
                        onActive = function()
                            RageUI.RenderCaisse("caisse", v.model)
                        end,
                        onListChange = function(Index, Item)
                            index.list = Index;
                            Button = Index;
                        end,
                        onSelected = function()
                            if Button == 1 then
                                OpenMenuPreviewCaisse(v.model, v.label)
                            elseif Button == 2 then
                                RageUI.CloseAll()
                                TriggerServerEvent('SovaLife:process_checkout_case', v.model)
                            end
                        end
                    })
                else
                    RageUI.List(v.label..' | Bonus Fidélité', Action, index.list, nil, {}, true, {
                        onActive = function()
                            RageUI.RenderCaisse("caisse", v.model)
                        end,
                        onListChange = function(Index, Item)
                            index.list = Index;
                            Button = Index;
                        end,
                        onSelected = function()
                            if Button == 1 then
                                OpenMenuPreviewCaisse(v.model, v.label)
                            elseif Button == 2 then
                                ESX.ShowNotification('Vous ne povuez pas acheter cette Caisse')
                            end
                        end
                    })
                end
            end
        end)
        if not RageUI.Visible(menu) 
        and not RageUI.Visible(historyMenu)
        and not RageUI.Visible(vehicles) 
        and not RageUI.Visible(voitures) 
        and not RageUI.Visible(avionhelico) 
        and not RageUI.Visible(bateaux) 
        and not RageUI.Visible(PacksMenu) 
        and not RageUI.Visible(ArmesMenu) 
        and not RageUI.Visible(ArmesShopMenu) 
        and not RageUI.Visible(CustomMenu)
        and not RageUI.Visible(CaseMenu)
        then
            menu = RMenu:DeleteType('menu', true)
		end
		Citizen.Wait(0)
    end
end

RegisterNetEvent('aBoutique:BuyCustomMaxClient', function()
    local vehicle = GetVehiclePedIsUsing(PlayerPedId())
    FullCustom(vehicle)
end)

function FullCustom(veh)
	SetVehicleModKit(veh, 0)
	ToggleVehicleMod(veh, 18, true)
	ToggleVehicleMod(veh, 22, true)
	SetVehicleMod(veh, 16, 5, false)
	SetVehicleMod(veh, 12, 2, false)
	SetVehicleMod(veh, 11, 3, false)
	SetVehicleMod(veh, 14, 14, false)
	SetVehicleMod(veh, 15, 3, false)
	SetVehicleMod(veh, 13, 2, false)
	SetVehicleMod(veh, 23, 21, true)
	SetVehicleMod(veh, 0, 1, false)
	SetVehicleMod(veh, 1, 1, false)
	SetVehicleMod(veh, 2, 1, false)
	SetVehicleMod(veh, 3, 1, false)
	SetVehicleMod(veh, 4, 1, false)
	SetVehicleMod(veh, 5, 1, false)
	SetVehicleMod(veh, 6, 1, false)
	SetVehicleMod(veh, 7, 1, false)
	SetVehicleMod(veh, 8, 1, false)
	SetVehicleMod(veh, 9, 1, false)
	SetVehicleMod(veh, 10, 1, false)
	SetVehicleModKit(veh, 0)
	ToggleVehicleMod(veh, 20, true)
	SetVehicleModKit(veh, 0)
	SetVehicleNumberPlateTextIndex(veh, true)
    myCar = ESX.Game.GetVehicleProperties(GetVehiclePedIsIn(PlayerPedId(), false))
	TriggerServerEvent('esx_lscustom:refreshOwnedVehicle', myCar)
end

function OpenMenuPreviewCaisse(model, label)
    local CaissePreview = RageUI.CreateMenu('', "Bienvenue sur notre boutique")
    RageUI.Visible(CaissePreview, not RageUI.Visible(CaissePreview))
    while CaissePreview do
        Citizen.Wait(0)
        RageUI.IsVisible(CaissePreview, function()
            RageUI.Separator(label)
            RageUI.Separator('~r~ARME NON PERMA~s~')
            for k,v in pairs(VisualitionCaisse[model]) do
                if v.rarity == 4 then
                    RageUI.Button(v.label, nil, {RightLabel = '~r~Ultime'}, true, {
                        onActive = function()
                            RageUI.RenderCaissePreview('caissemystere', v.model)
                        end,
                        onSelected = function()
        
                        end
                    })
                end
            end
            for k,v in pairs(VisualitionCaisse[model]) do
                if v.rarity == 3 then
                    RageUI.Button(v.label, nil, {RightLabel = '~g~Légendaire'}, true, {
                        onActive = function()
                            RageUI.RenderCaissePreview('caissemystere', v.model)
                        end,
                        onSelected = function()
        
                        end
                    })
                end
            end
            for k,v in pairs(VisualitionCaisse[model]) do
                if v.rarity == 2 then
                    RageUI.Button(v.label, nil, {RightLabel = '~y~Rare'}, true, {
                        onActive = function()
                            RageUI.RenderCaissePreview('caissemystere', v.model)
                        end,
                        onSelected = function()
        
                        end
                    })
                end
            end
            for k,v in pairs(VisualitionCaisse[model]) do
                if v.rarity == 1 then
                    RageUI.Button(v.label, nil, {RightLabel = '~w~Commun'}, true, {
                        onActive = function()
                            RageUI.RenderCaissePreview('caissemystere', v.model)
                        end,
                        onSelected = function()
        
                        end
                    })
                end
            end
        end, function()
        end)

        if not RageUI.Visible(CaissePreview) then
            CaissePreview = RMenu:DeleteType('BoutiqueSub', true)
            Wait(100)
            OpenMenuMain()
        end
    end
end

-- OPENING CASE

local picture;

local mysterybox = RageUI.CreateMenu("", "Bonne chance !")

RegisterNetEvent('ewen:caisseopenclientside')
AddEventHandler('ewen:caisseopenclientside', function(animations, name, message)
    RageUI.Visible(mysterybox, not RageUI.Visible(mysterybox))
    Citizen.CreateThread(function()
        Citizen.Wait(250)
        for k, v in pairs(animations) do
            picture = v.name
            RageUI.PlaySound("HUD_FREEMODE_SOUNDSET", "NAV_UP_DOWN")
            if v.time == 5000 then
                RageUI.PlaySound("HUD_AWARDS", "FLIGHT_SCHOOL_LESSON_PASSED")
                ESX.ShowAdvancedNotification('Boutique', 'Informations', message, 'CHAR_SovaLife', 6, 2)
                Wait(4000)
            end
            Citizen.Wait(v.time)
        end
    end)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1)
            RageUI.IsVisible(mysterybox, function()
            end, function()
                if (picture) then
                    RageUI.CaissePreviewOpen("caissemystere", picture)
                end
            end)
        end
    end)
end)

RegisterNetEvent('aBoutique:SendJournaliereBoutique')
AddEventHandler('aBoutique:SendJournaliereBoutique', function(vehicle)
    VehicleJournalier = vehicle
end)

Citizen.CreateThread(function()
    Wait(1500)
    TriggerServerEvent('aBoutique:RetrieveJournaliereBoutique')
end)

Citizen.CreateThread(function()
	Wait(2000)
	TriggerServerEvent('ewen:boutiquecashout')
end)