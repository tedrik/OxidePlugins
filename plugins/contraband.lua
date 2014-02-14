PLUGIN.Title = "Contraband"
PLUGIN.Version = "0.2.0"
PLUGIN.Description = "Removes all contraband from a player's inventory and hotbar."
PLUGIN.Author = "Luke Spragg - Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/resources/130/"

-- Let the server owner know the plugin has loaded
print(PLUGIN.Title .. " v" .. PLUGIN.Version .. " loaded")

local localization;
function PLUGIN:Init()
    -- Load the config file
    local b, res = config.Read("contraband")
    self.Config = res or {}
    -- If no config file exists, create it
    if (not b) then
        self:LoadDefaultConfig()
        if (res) then config.Save("contraband") end
    end

    -- Add chat command
    self:AddChatCommand("contraband", self.cmdContraband) -- English
    self:AddChatCommand("contrabande", self.cmdContraband) -- Dutch
    self:AddChatCommand("contrebande", self.cmdContraband) -- French
    self:AddChatCommand("schmuggelware", self.cmdContraband) -- German
    self:AddChatCommand("kontrabanda", self.cmdContraband) -- Polish
    self:AddChatCommand("контрабанда", self.cmdContraband) -- Russian
    self:AddChatCommand("contrabando", self.cmdContraband) -- Spanish
    self:AddChatCommand("smuggelgods", self.cmdContraband) -- Swedish

    -- Find optional Oxmin plugin
    oxminPlugin = plugins.Find("oxmin")
    if oxminPlugin then
        -- Add Oxmin flag
        self.FLAG_CONTRABANDCHECK = oxmin.AddFlag("contrabandcheck")
        self.FLAG_CONTRABANREMOVE = oxmin.AddFlag("contrabandremove")
    end

    -- Find optional Flags plugin
    flagsPlugin = plugins.Find("flags")
    if flagsPlugin then
        -- Add Flags plugin command
        flagsPlugin:AddFlagsChatCommand(self, "contraband", {"contraband"}, self.cmdContraband)
    end

    -- Find Localization plugin
    localization = plugins.Find("localization")
    if (localization ~= nil) then
        self:DefaultLocalization()
    end
end

function PLUGIN:OnUserConnect(netuser)
    -- Check if removal on connect is enabled
    if (self.Config.removeonconnect == true) then
        -- Trigger removal check on user connect
        timer.Once(10, function() self:ContrabandRemove(netuser) end)
    end
end

function PLUGIN:ContrabandCheck(netuser)
    local inv = rust.GetInventory(netuser)
    local detected = false

    for i=1, #self.Config.contraband do
        local datablock = rust.GetDatablockByName(self.Config.contraband[i])
        local item = inv:FindItem(datablock)
        if (item) then
            detected = true
        end
    end

    -- Item detected, send messages
    if (detected == true) then
        -- Check for localized strings
        if (localization == nil) then
            -- Notify admin of detection
            rust.SendChatToUser(netuser, self.Config.chatname, "Detected contraband on " .. util.QuoteSafe(netuser.displayName) .. "!")
            -- Write detection to server log
            print("Contraband detected on " .. util.QuoteSafe(netuser.displayName) .. "!")
        else
            -- Notify admin of detection (localized)
            rust.SendChatToUser(netuser, self.Config.chatname, localization:GetUserString(netuser, "contraband", "detectedon") .. " " .. util.QuoteSafe(netuser.displayName) .. "!")
            -- Write detection to server log (localized)
            print(localization:GetUserString(netuser, "contraband", "detectedon") .. " " .. util.QuoteSafe(netuser.displayName) .. "!")
        end
    else
        -- Check for localized strings
            if (localization == nil) then
            -- Notify admin of no detection
            rust.SendChatToUser(netuser, self.Config.chatname, "No contraband detected on " .. util.QuoteSafe(netuser.displayName))
        else
            -- Notify admin of no detection (localized)
            rust.SendChatToUser(netuser, self.Config.chatname, localization:GetUserString(netuser, "contraband", "notdetectedon") .. " " .. util.QuoteSafe(netuser.displayName) .. "!")
        end
    end
end

function PLUGIN:ContrabandRemove(netuser)
    local inv = rust.GetInventory(netuser)
    local detected = false

    for i=1, #self.Config.contraband do
        local datablock = rust.GetDatablockByName(self.Config.contraband[i])
        local item = inv:FindItem(datablock)
        -- Check if item is in inventory
        if (item) then
            detected = true
            -- Remove all instances of item
            while (item) do
                inv:RemoveItem(item)
                item = inv:FindItem(datablock)
                if (not item) then
                    break
                end
            end
        end
    end

    -- Item detected, send messages
    if (detected == true) then
        -- Check for localized strings
        if (localization == nil) then
            -- Notify user of removal
            rust.SendChatToUser(netuser, self.Config.chatname, "Found and removed contraband from " .. util.QuoteSafe(netuser.displayName) .. "!")
            rust.Notice(netuser, "Contraband found and removed!")
            -- Write removal to server log
            print("Contraband found and removed from " .. util.QuoteSafe(netuser.displayName) .. "!")
        else
            -- Notify user of removal (localized)
            rust.SendChatToUser(netuser, self.Config.chatname, localization:GetUserString(netuser, "contraband", "removedfrom") .. " " .. util.QuoteSafe(netuser.displayName) .. "!")
            rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "removed") .. "!")
            -- Write removal to server log (localized)
            print(localization:GetUserString(netuser, "contraband", "removedfrom") .. " " .. util.QuoteSafe(netuser.displayName) .. "!")
        end
    else
        -- Check for localized strings
        if (localization == nil) then
            -- Notify admin of no detection
            rust.SendChatToUser(netuser, self.Config.chatname, "No contraband detected on " .. util.QuoteSafe(netuser.displayName))
        else
            -- Notify admin of no detection (localized)
            rust.SendChatToUser(netuser, self.Config.chatname, localization:GetUserString(netuser, "contraband", "notdetectedon") .. " " .. util.QuoteSafe(netuser.displayName) .. "!")
        end
    end
end

function PLUGIN:cmdContraband(netuser, cmd, args)
    -- Check for no target name
    if (not args[1] or (args[1] == nil)) then
        -- Check for localized strings
        if (localization == nil) then
            rust.Notice(netuser, "You must enter a valid target name!")
        else
            rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "invalidplayername") .. "!")
        end
        return
    end

    -- Check for valid target name
    local b, targetuser = rust.FindNetUsersByName(args[1])
    if (not b) then
        if (targetuser == 0) then
            -- Check for localized strings
            if (localization == nil) then
                rust.Notice(netuser, "No players found with that name!")
            else
                rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "noplayersfound") .. "!")
            end
        elseif (targetuser > 1) then
            -- Check for localized strings
            if (localization == nil) then
                rust.Notice(netuser, "Multiple players found with that name!")
            else
                rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "multipleplayersfound") .. "!")
            end
        end
        return
    end

    -- Check action
    if (args[2] == "check") then
        -- Check if user is admin, or has flag assigned
        if ((netuser:CanAdmin()) or (oxminPlugin:HasFlag(netuser, self.FLAG_CONTRABANDCHECK)) or (flagsPlugin:HasFlag(netuser, "contrabandcheck"))) then
            -- Call check function
            self:ContrabandCheck(netuser)
        end

    -- Remove action
    elseif (args[2] == "remove") then
        -- Check if user is admin, or has flag assigned
        if ((netuser:CanAdmin()) or (oxminPlugin:HasFlag(netuser, self.FLAG_CONTRABANDREMOVE)) or (flagsPlugin:HasFlag(netuser, "contrabandcheck"))) then
            -- Call remove function
            self:ContrabandRemove(netuser)
        end
    -- Catch all action fails
    else
        -- Check for localized strings
        if (localization == nil) then
            rust.Notice(netuser, "Unknown contraband action!")
        else
            rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "unknownaction") .. "!")
        end
        return
    end
end

function PLUGIN:SendHelpText(netuser)
    -- Oxmin help command
    if ((netuser:CanAdmin()) or (oxminPlugin:HasFlag(netuser, self.FLAG_CONTRABANDREMOVE)) or (flagsPlugin:HasFlag(netuser, "contrabandcheck"))) then
        rust.SendChatToUser(netuser, '' )
    end
    if ((netuser:CanAdmin()) or (oxminPlugin:HasFlag(netuser, self.FLAG_CONTRABANDREMOVE)) or (flagsPlugin:HasFlag(netuser, "contrabandremove"))) then
        rust.SendChatToUser(netuser, '' )
    end
end

function PLUGIN:LoadDefaultConfig()
    -- Set default configuration settings
    self.Config.chatname = "Contraband"
    self.Config.removeonconnect = true
    self.Config.contraband = { "Explosive Charge", "Explosives", "F1 Grenade" }
end

function PLUGIN:DefaultLocalization()
    ---- Default localizations. Edit the data/cfg_localization.txt file if you'd like to change these.
    -- English
    localization:AddString("contraband", "en", "detected", "Contraband detected")
    localization:AddString("contraband", "en", "detectedon", "Detected contraband on")
    localization:AddString("contraband", "en", "notdetectedon", "No contraband detected on")
    localization:AddString("contraband", "en", "removed", "Contraband found and removed")
    localization:AddString("contraband", "en", "removedfrom", "Found and removed contraband from")
    localization:AddString("contraband", "en", "invalidplayername", "You must enter a valid player name")
    localization:AddString("contraband", "en", "noplayersfound", "No players found with that name")
    localization:AddString("contraband", "en", "multipleplayersfound", "Multiple players found with that name")
    localization:AddString("contraband", "en", "unknownaction", "Unknown contraband action")
    localization:AddString("contraband", "en", "checkhelptext", 'Use /contraband "name" "check" to check a player for contraband.')
    localization:AddString("contraband", "en", "removehelptext", 'Use /contraband "name" "remove" to remove a contraband from player.')
    -- Dutch
    localization:AddString("contraband", "nl", "detected", "Contrabande gedetecteerd")
    localization:AddString("contraband", "nl", "detectedon", "Gedetecteerde smokkelwaar op")
    localization:AddString("contraband", "nl", "notdetectedon", "Geen contrabande gedetecteerd op")
    localization:AddString("contraband", "nl", "removed", "Contrabande gevonden en verwijderd")
    localization:AddString("contraband", "nl", "removedfrom", "Gevonden en verwijderd smokkel van")
    localization:AddString("contraband", "nl", "invalidplayername", "U moet een geldige spelersnaam invoeren")
    localization:AddString("contraband", "nl", "noplayersfound", "Geen spelers gevonden met die naam")
    localization:AddString("contraband", "nl", "multipleplayersfound", "Meerdere spelers gevonden met die naam")
    localization:AddString("contraband", "nl", "unknownaction", "Onbekende gesmokkelde actie")
    localization:AddString("contraband", "nl", "checkhelptext", '/contrabande "naam" "controleren" gebruiken om te controleren van een speler voor contrabande')
    localization:AddString("contraband", "nl", "removehelptext", '')
    -- French
    localization:AddString("contraband", "fr", "detected", "Contrebande détecté")
    localization:AddString("contraband", "fr", "detectedon", "Contrebande détectée sur")
    localization:AddString("contraband", "fr", "notdetectedon", "Aucune contrebande détectée sur")
    localization:AddString("contraband", "fr", "removed", "Contrebande trouvé et enlevé")
    localization:AddString("contraband", "fr", "removedfrom", "Trouvé et enlevé de contrebande de")
    localization:AddString("contraband", "fr", "invalidplayername", "Vous devez entrer un nom de joueur valide")
    localization:AddString("contraband", "fr", "noplayersfound", "Pas trouvés avec ce nom de joueurs")
    localization:AddString("contraband", "fr", "multipleplayersfound", "Plusieurs joueurs trouvés portant ce nom")
    localization:AddString("contraband", "fr", "unknownaction", "Action de contrebande inconnue")
    localization:AddString("contraband", "fr", "checkhelptext", 'Utilisez /contrebande "nom" "check" pour vérifier un joueur pour contrebande')
    localization:AddString("contraband", "fr", "removehelptext", '')
    -- German
    localization:AddString("contraband", "de", "detected", "Schmuggelware erkannt")
    localization:AddString("contraband", "de", "detectedon", "Entdeckte Schmuggelware auf")
    localization:AddString("contraband", "de", "notdetectedon", "Keine Schmuggelware auf erkannt")
    localization:AddString("contraband", "de", "removed", "Schmuggelware gefunden und entfernt")
    localization:AddString("contraband", "de", "removedfrom", "Gefunden und entfernt Schmuggelware aus")
    localization:AddString("contraband", "de", "invalidplayername", "Sie müssen einen gültigen Spielernamen eingeben.")
    localization:AddString("contraband", "de", "noplayersfound", "Keine Spieler, die mit diesem Namen gefunden")
    localization:AddString("contraband", "de", "multipleplayersfound", "Mehrere Spieler, die mit diesem Namen gefunden")
    localization:AddString("contraband", "de", "unknownaction", "Unbekannte geschmuggelten Aktion")
    localization:AddString("contraband", "de", "checkhelptext", 'Verwenden Sie /schmuggelware "Name" "suchen", um ein Spieler für Schmuggelware zu überprüfen')
    localization:AddString("contraband", "de", "removehelptext", '')
    -- Polish
    localization:AddString("contraband", "pl", "detected", "Kontrabanda wykryte")
    localization:AddString("contraband", "pl", "detectedon", "Wykrytego przemytu na")
    localization:AddString("contraband", "pl", "notdetectedon", "Nie kontrabandy wykryte na")
    localization:AddString("contraband", "pl", "removed", "Kontrabanda znaleźć i usunąć")
    localization:AddString("contraband", "pl", "removedfrom", "Znaleziono i usunięto kontrabandy z")
    localization:AddString("contraband", "pl", "invalidplayername", "Należy wprowadzić nazwę gracza")
    localization:AddString("contraband", "pl", "noplayersfound", "Żaden z graczy nie znaleziono o tej nazwie")
    localization:AddString("contraband", "pl", "multipleplayersfound", "Wielu graczy z tą nazwą")
    localization:AddString("contraband", "pl", "unknownaction", "Nieznane działania kontrabandy")
    localization:AddString("contraband", "pl", "checkhelptext", '')
    localization:AddString("contraband", "pl", "removehelptext", '')
    -- Russian
    localization:AddString("contraband", "ru", "detected", "Обнаружена контрабанда")
    localization:AddString("contraband", "ru", "detectedon", "Обнаруженные контрабандные товары на")
    localization:AddString("contraband", "ru", "notdetectedon", "Без контрабанды, обнаруженных на")
    localization:AddString("contraband", "ru", "removed", "Контрабанда найден и удален")
    localization:AddString("contraband", "ru", "removedfrom", "Найдены и удалены контрабанды из")
    localization:AddString("contraband", "ru", "invalidplayername", "Вам необходимо ввести действительный игрок имя")
    localization:AddString("contraband", "ru", "noplayersfound", "Игроки не найден с этим именем")
    localization:AddString("contraband", "ru", "multipleplayersfound", "Несколько игроков с таким именем")
    localization:AddString("contraband", "ru", "unknownaction", "Неизвестный контрабандных действий")
    localization:AddString("contraband", "ru", "checkhelptext", '')
    localization:AddString("contraband", "ru", "removehelptext", '')
    -- Spanish
    localization:AddString("contraband", "es", "detected", "Contrabando detectado")
    localization:AddString("contraband", "es", "detectedon", "Contrabando detectado en")
    localization:AddString("contraband", "es", "notdetectedon", "No hay contrabando detectado en")
    localization:AddString("contraband", "es", "removed", "Contrabando encontrado y eliminado")
    localization:AddString("contraband", "es", "removedfrom", "Contrabando encontrado y eliminado de")
    localization:AddString("contraband", "es", "invalidplayername", "Debe introducir un nombre de jugador válida")
    localization:AddString("contraband", "es", "noplayersfound", "No hay jugadores con ese nombre")
    localization:AddString("contraband", "es", "multipleplayersfound", "Varios jugadores se encontraron con ese nombre")
    localization:AddString("contraband", "es", "unknownaction", "Acción contrabando desconocido")
    localization:AddString("contraband", "es", "checkhelptext", '')
    localization:AddString("contraband", "es", "removehelptext", '')
    -- Swedish
    localization:AddString("contraband", "sv", "detected", "Smuggelgods upptäckt")
    localization:AddString("contraband", "sv", "detectedon", "Upptäckta smuggelgods på")
    localization:AddString("contraband", "sv", "notdetectedon", "Ingen smuggling som upptäckts på")
    localization:AddString("contraband", "sv", "removed", "Smuggelgods hittas och tas bort")
    localization:AddString("contraband", "sv", "removedfrom", "Hittade och tog bort smuggelgods från")
    localization:AddString("contraband", "sv", "invalidplayername", "Du måste ange en giltig spelarnamn")
    localization:AddString("contraband", "sv", "noplayersfound", "Inga spelare hittade med det namnet")
    localization:AddString("contraband", "sv", "multipleplayersfound", "Flera spelare hittade med det namnet")
    localization:AddString("contraband", "sv", "unknownaction", "Okänd contraband åtgärder")
    localization:AddString("contraband", "sv", "checkhelptext", '')
    localization:AddString("contraband", "sv", "removehelptext", '')
end
