PLUGIN.Title = "Contraband"
PLUGIN.Version = "0.2.1"
PLUGIN.Description = "Removes all contraband from a player's inventory and hotbar."
PLUGIN.Author = "Luke Spragg - Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/resources/130/"

local localization;

function PLUGIN:Init()
    -- Log that plugin is loading
    print(self.Title .. " v" .. self.Version .. " loading...")

    -- Load configuration file
    self:LoadConfiguration()

    -- Setup command permissions
    self:SetupPermissions()

    -- Setup chat commands
    self:SetupChatCommands()

    -- Setup language localization
    localization = plugins.Find("localization")
    if (localization ~= nil) then
        self:DefaultLocalization()
    end

    -- Log tha plugin has loaded
    print(self.Title .. " v" .. self.Version .. " loaded!")
end

function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
    -- Check if removal on connect is enabled
    if (self.Config.removeonconnect == true) then
        -- Trigger removal check on user connect
        timer.Once(1, function() self:ContrabandProcess(playerclient.netUser, "remove") end)
    end
end

function PLUGIN:PermissionsCheck(netuser, action)
    local hasPermission = false

    -- Set flags based on given action
    if (action == "check") then
        actionFlag = "contrabandcheck"
    elseif (action == "remove") then
        actionFlag = "contrabandremove"
    end

    -- Check if user is admin, or has flag assigned
    if (netuser:CanAdmin()) then
        hasPermission = true
    elseif ((self.oxminPlugin ~= nil) and (self.oxminPlugin:HasFlag(netuser, actionFlag))) then
        hasPermission = true
    elseif ((self.flagsPlugin ~= nil) and (self.flagsPlugin:HasFlag(netuser, actionFlag))) then
        hasPermission = true

    -- Notify user of lack of permission
    else
        hasPermission = false
    end

    return hasPermission
end

function PLUGIN:OnDatablocksLoaded()
    -- Preload the datablocks
    self.DataBlocks = {}
    for i=1, #self.Config.contraband do
        local BlockName = self.Config.contraband[i]
        self.DataBlocks[BlockName] = rust.GetDatablockByName(BlockName)
    end
end

function PLUGIN:ContrabandProcess(targetuser, action)
    local inv = rust.GetInventory(targetuser)
    local detected = false

    -- Check inventory against contraband list
    for i=1, #self.Config.contraband do
        datablock = self.DataBlocks[self.Config.contraband[i]]
        item = inv:FindItem(datablock)

        -- Check if items exist
        if (item) then
            detected = true

            -- Check if remove action is called
            if (action == "remove") then
                -- Remove all instances of item
                while (item) do
                    inv:RemoveItem(item)
                    item = inv:FindItem(datablock)
                end
            end
        end
    end
    return detected
end

function PLUGIN:ContrabandCommand(netuser, cmd, args)
    -- Only allow two arguments
    if (#args ~= 2) then
        -- Check for localized strings
        if (localization == nil) then
            rust.Notice(netuser, 'Syntax: /contraband "name" "action"')
        else
            rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "invalid_syntax"))
        end
        return
    end

    -- We have the correct amount of arguments
    local targetuser = args[1]
    local action = tostring(args[2])
    local hasPermission = self:PermissionsCheck(netuser, action)

    -- Catch all action fails
    if ((action == nil) or (action ~= "check" and action ~= "remove")) then
        -- Check for localized strings
        if (localization == nil) then
            rust.Notice(netuser, "Unknown contraband action!")
        else
            rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "unknown_action") .. "!")
        end

        return
    end

    -- User has no permissions
    if (hasPermission == false) then
        -- Check for localized strings
        if (localization == nil) then
            rust.Notice(netuser, "You do not have permission to use this command!")
        else
            rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "no_permission") .. "!")
        end
        return
    end

    -- Check for valid target name
    if (not(targetuser) or (targetuser == nil)) then
        -- Check for localized strings
        if (localization == nil) then
            rust.Notice(netuser, "You must enter a valid target name!")
        else
            rust.Notice(netuser, localization:GetUserString(targetuser, "contraband", "invalid_player_name") .. "!")
        end
        return
    end

    -- Get the target user
    local b, targetuser = rust.FindNetUsersByName(targetuser)
    if (not b) then
        -- Check if player name exists
        if (targetuser == 0) then
            -- Check for localized strings
            if (localization == nil) then
                rust.Notice(netuser, "No players found with that name!")
            else
                rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "no_players_found") .. "!")
            end
        -- Check for multiple name matches
        elseif (targetuser > 1) then
            -- Check for localized strings
            if (localization == nil) then
                rust.Notice(netuser, "Multiple players found with that name!")
            else
                rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "multiple_players_found") .. "!")
            end
        end
        return
    end

    -- Check action
    if (action == "check") then
        -- Run item detection/removal
        local detected = self:ContrabandProcess(targetuser, action)
        if (detected) then
            -- Check for localized strings
            if (localization == nil) then
                -- Check if chat messages are enabled
                if (self.Config.chatenabled == true) then
                    -- Notify admin of detection
                    rust.SendChatToUser(netuser, self.Config.chatname, "Detected contraband on " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
                -- Check if logging is enabled
                if (self.Config.loggingenabled == true) then
                    -- Write detection to server log
                    print("Contraband detected on " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
            else
                -- Check if chat messages are enabled
                if (self.Config.chatenabled == true) then
                    -- Notify admin of detection (localized)
                    rust.SendChatToUser(netuser, self.Config.chatname, localization:GetUserString(netuser, "contraband", "detected_on") .. " " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
                -- Check if logging enabled
                if (self.Config.loggingenabled == true) then
                    -- Write detection to server log (localized)
                    print(localization:GetUserString(netuser, "contraband", "detected_on") .. " " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
            end
        else
            -- No contraband detected
            self:NoneDetected(netuser, targetuser)
        end

    -- Remove action
    elseif (action == "remove") then
        -- Run item detection/removal
        local detected = self:ContrabandProcess(targetuser, action)
        if (detected) then
            -- Check for localized strings
            if (localization == nil) then
                -- Check if chat messages are enabled
                if (self.Config.chatenabled == true) then
                    -- Notify user of removal
                    rust.SendChatToUser(netuser, self.Config.chatname, "Found and removed contraband from " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
                -- Check if notices are enabled
                if (self.Config.noticesenabled == true) then
                    -- Notify user of removal
                    rust.Notice(netuser, "Contraband found and removed from " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
                -- Check if logging is enabled
                if (self.Config.loggingenabled == true) then
                    -- Write removal to server log
                    print("Contraband found and removed from " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
            else
                -- Check if chat messages are enabled
                if (self.Config.chatenabled == true) then
                    -- Notify user of removal (localized)
                    rust.SendChatToUser(netuser, self.Config.chatname, localization:GetUserString(netuser, "contraband", "removed_from") .. " " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
                -- Check if notices are enabled
                if (self.Config.noticesenabled == true) then
                    rust.Notice(netuser, localization:GetUserString(netuser, "contraband", "removed_from") .. " " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
                -- Check if logging is enabled
                if (self.Config.loggingenabled == true) then
                    -- Write removal to server log (localized)
                    print(localization:GetUserString(netuser, "contraband", "removed_from") .. " " .. util.QuoteSafe(targetuser.displayName) .. "!")
                end
            end
        else
            -- No contraband detected
            self:NoneDetected(netuser, targetuser)
        end
    end
end

function PLUGIN:NoneDetected(netuser, targetuser)
    -- Check if chat messages are enabled
    if (self.Config.chatenabled == true) then
        -- Check for localized strings
        if (localization == nil) then
            -- Notify admin of no detection
            rust.SendChatToUser(netuser, self.Config.chatname, "No contraband detected on " .. util.QuoteSafe(netuser.displayName))
        else
            -- Notify admin of no detection (localized)
            rust.SendChatToUser(netuser, self.Config.chatname, localization:GetUserString(netuser, "contraband", "not_detected_on") .. " " .. util.QuoteSafe(netuser.displayName) .. "!")
        end
    end
end

function PLUGIN:SendHelpText(netuser)
    -- Oxmin help commands
    if (hasPermission) then
        if (localization == nil) then
            rust.SendChatToUser(netuser, 'Use /contraband "name" "check" to check a player for contraband.')
        else
            rust.SendChatToUser(netuser, localization:GetUserString(netuser, "contraband", "help_text_check"))
        end
    end
    if (hasPermission) then
        if (localization == nil) then
            rust.SendChatToUser(netuser, 'Use /contraband "name" "remove" to remove a contraband from player.')
        else
            rust.SendChatToUser(netuser, localization:GetUserString(netuser, "contraband", "help_text_remove"))
        end
    end
end

function PLUGIN:LoadConfiguration()
    -- Load the configuration file
    local b, res = config.Read("contraband")
    self.Config = res or {}

    -- If no configuration file exists, create it
    if (not b) then
        self:DefaultConfiguration()
        if (res) then
            config.Save("contraband")
        end

        -- Log that the default configuration has loaded
        print(self.Title .. " default configuration loaded!")
    end
end

function PLUGIN:DefaultConfiguration()
    -- Set default configuration settings
    self.Config.chatname = "Contraband"
    self.Config.chatenabled = true
    self.Config.noticesenabled = true
    self.Config.loggingenabled = true
    self.Config.removeonconnect = true
    self.Config.contraband = { "Explosive Charge", "Explosives", "F1 Grenade" }
end

function PLUGIN:SetupPermissions()
    -- Find optional Oxmin plugin
    self.oxminPlugin = plugins.Find("oxmin")
    if (self.oxminPlugin) then
        -- Add Oxmin plugin command flags
        self.FLAG_CONTRABANDCHECK = oxmin.AddFlag("contrabandcheck")
        self.FLAG_CONTRABANREMOVE = oxmin.AddFlag("contrabandremove")
        self.oxminPlugin:AddExternalOxminChatCommand(self, "contrabandcheck", { FLAG_CONTRABANDCHECK }, self.cmdContraband)
        self.oxminPlugin:AddExternalOxminChatCommand(self, "contrabandcheck", { FLAG_CONTRABANREMOVE }, self.cmdContraband)
    end

    -- Find optional Flags plugin
    self.flagsPlugin = plugins.Find("flags")
    if (self.flagsPlugin) then
        -- Add Flags plugin command flags
        self.flagsPlugin:AddFlagsChatCommand(self, "contraband", { "contrabandcheck" }, self.cmdContraband)
        self.flagsPlugin:AddFlagsChatCommand(self, "contraband", { "contrabandremove" }, self.cmdContraband)
    end
end

function PLUGIN:SetupChatCommands()
    -- Localized chat commands
    self:AddChatCommand("contraband", self.cmdContraband) -- English
    --self:AddChatCommand("contrabande", self.cmdContraband) -- Dutch
    --self:AddChatCommand("contrebande", self.cmdContraband) -- French
    --self:AddChatCommand("schmuggelware", self.cmdContraband) -- German
    --self:AddChatCommand("kontrabanda", self.cmdContraband) -- Polish
    --self:AddChatCommand("контрабанда", self.cmdContraband) -- Russian
    --self:AddChatCommand("contrabando", self.cmdContraband) -- Spanish
    --self:AddChatCommand("smuggelgods", self.cmdContraband) -- Swedish
end

function PLUGIN:DefaultLocalization()
    ---- Default localizations. Edit the data/cfg_localization.txt file if you'd like to change these.
    -- English
    localization:AddString("contraband", "en", "detected", "Contraband detected")
    localization:AddString("contraband", "en", "detected_on", "Detected contraband on")
    localization:AddString("contraband", "en", "help_text_check", 'Use /contraband "name" "check" to check a player for contraband')
    localization:AddString("contraband", "en", "help_text_remove", 'Use /contraband "name" "remove" to remove a contraband from player')
    localization:AddString("contraband", "en", "invalid_player_name", "You must enter a valid player name")
    localization:AddString("contraband", "en", "invalid_syntax", 'Syntax: /contraband "name" "action"')
    localization:AddString("contraband", "en", "multiple_players_found", "Multiple players found with that name")
    localization:AddString("contraband", "en", "no_permission", 'You do not have permission to use this command')
    localization:AddString("contraband", "en", "no_players_found", "No players found with that name")
    localization:AddString("contraband", "en", "not_detected_on", "No contraband detected on")
    localization:AddString("contraband", "en", "removed", "Contraband found and removed")
    localization:AddString("contraband", "en", "removed_from", "Found and removed contraband from")
    localization:AddString("contraband", "en", "unknown_action", "Unknown contraband action")
    -- Dutch
    localization:AddString("contraband", "nl", "detected", "Contrabande gedetecteerd")
    localization:AddString("contraband", "nl", "detected_on", "Gedetecteerde smokkelwaar op")
    --localization:AddString("contraband", "nl", "help_text_check", '/contrabande "naam" "controleren" gebruiken om te controleren van een speler voor contrabande')
    --localization:AddString("contraband", "nl", "help_text_remove", '')
    localization:AddString("contraband", "nl", "invalid_player_name", "U moet een geldige spelersnaam invoeren")
    --localization:AddString("contraband", "nl", "invalid_syntax", '')
    localization:AddString("contraband", "nl", "multiple_players_found", "Meerdere spelers gevonden met die naam")
    localization:AddString("contraband", "nl", "not_detected_on", "Geen contrabande gedetecteerd op")
    localization:AddString("contraband", "nl", "no_players_found", "Geen spelers gevonden met die naam")
    localization:AddString("contraband", "nl", "removed", "Contrabande gevonden en verwijderd")
    localization:AddString("contraband", "nl", "removed_from", "Gevonden en verwijderd smokkel van")
    localization:AddString("contraband", "nl", "unknown_action", "Onbekende gesmokkelde actie")
    -- French
    localization:AddString("contraband", "fr", "detected", "Contrebande détecté")
    localization:AddString("contraband", "fr", "detected_on", "Contrebande détectée sur")
    --localization:AddString("contraband", "fr", "help_text_check", 'Utilisez /contrebande "nom" "check" pour vérifier un joueur pour contrebande')
    --localization:AddString("contraband", "fr", "help_text_remove", '')
    localization:AddString("contraband", "fr", "invalid_player_name", "Vous devez entrer un nom de joueur valide")
    --localization:AddString("contraband", "fr", "invalid_syntax", '')
    localization:AddString("contraband", "fr", "multiple_players_found", "Plusieurs joueurs trouvés portant ce nom")
    localization:AddString("contraband", "fr", "not_detected_on", "Aucune contrebande détectée sur")
    localization:AddString("contraband", "fr", "no_players_found", "Pas trouvés avec ce nom de joueurs")
    localization:AddString("contraband", "fr", "removed", "Contrebande trouvé et enlevé")
    localization:AddString("contraband", "fr", "removed_from", "Trouvé et enlevé de contrebande de")
    localization:AddString("contraband", "fr", "unknown_action", "Action de contrebande inconnue")
    -- German
    localization:AddString("contraband", "de", "detected", "Schmuggelware erkannt")
    localization:AddString("contraband", "de", "detected_on", "Entdeckte Schmuggelware auf")
    --localization:AddString("contraband", "de", "help_text_check", 'Verwenden Sie /schmuggelware "Name" "suchen", um ein Spieler für Schmuggelware zu überprüfen')
    --localization:AddString("contraband", "de", "help_text_remove", '')
    localization:AddString("contraband", "de", "invalid_player_name", "Sie müssen einen gültigen Spielernamen eingeben.")
    --localization:AddString("contraband", "de", "invalid_syntax", '')
    localization:AddString("contraband", "de", "multiple_players_found", "Mehrere Spieler, die mit diesem Namen gefunden")
    localization:AddString("contraband", "de", "not_detected_on", "Keine Schmuggelware auf erkannt")
    localization:AddString("contraband", "de", "no_players_found", "Keine Spieler, die mit diesem Namen gefunden")
    localization:AddString("contraband", "de", "removed", "Schmuggelware gefunden und entfernt")
    localization:AddString("contraband", "de", "removed_from", "Gefunden und entfernt Schmuggelware aus")
    localization:AddString("contraband", "de", "unknown_action", "Unbekannte geschmuggelten Aktion")
    -- Polish
    localization:AddString("contraband", "pl", "detected", "Kontrabanda wykryte")
    localization:AddString("contraband", "pl", "detected_on", "Wykrytego przemytu na")
    --localization:AddString("contraband", "pl", "help_text_check", '')
    --localization:AddString("contraband", "pl", "help_text_remove", '')
    localization:AddString("contraband", "pl", "invalid_player_name", "Należy wprowadzić nazwę gracza")
    --localization:AddString("contraband", "pl", "invalid_syntax", '')
    localization:AddString("contraband", "pl", "multiple_players_found", "Wielu graczy z tą nazwą")
    localization:AddString("contraband", "pl", "not_detected_on", "Nie kontrabandy wykryte na")
    localization:AddString("contraband", "pl", "no_players_found", "Żaden z graczy nie znaleziono o tej nazwie")
    localization:AddString("contraband", "pl", "removed", "Kontrabanda znaleźć i usunąć")
    localization:AddString("contraband", "pl", "removed_from", "Znaleziono i usunięto kontrabandy z")
    localization:AddString("contraband", "pl", "unknown_action", "Nieznane działania kontrabandy")
    -- Russian
    localization:AddString("contraband", "ru", "detected", "Обнаружена контрабанда")
    localization:AddString("contraband", "ru", "detected_on", "Обнаруженные контрабандные товары на")
    --localization:AddString("contraband", "ru", "help_text_check", '')
    --localization:AddString("contraband", "ru", "help_text_remove", '')
    localization:AddString("contraband", "ru", "invalid_player_name", "Вам необходимо ввести действительный игрок имя")
    --localization:AddString("contraband", "ru", "invalid_syntax", '')
    localization:AddString("contraband", "ru", "multiple_players_found", "Несколько игроков с таким именем")
    localization:AddString("contraband", "ru", "not_detected_on", "Без контрабанды, обнаруженных на")
    localization:AddString("contraband", "ru", "no_players_found", "Игроки не найден с этим именем")
    localization:AddString("contraband", "ru", "removed", "Контрабанда найден и удален")
    localization:AddString("contraband", "ru", "removed_from", "Найдены и удалены контрабанды из")
    localization:AddString("contraband", "ru", "unknown_action", "Неизвестный контрабандных действий")
    -- Spanish
    localization:AddString("contraband", "es", "detected", "Contrabando detectado")
    localization:AddString("contraband", "es", "detected_on", "Contrabando detectado en")
    --localization:AddString("contraband", "es", "help_text_check", '')
    --localization:AddString("contraband", "es", "help_text_remove", '')
    localization:AddString("contraband", "es", "invalid_player_name", "Debe introducir un nombre de jugador válida")
    --localization:AddString("contraband", "es", "invalid_syntax", '')
    localization:AddString("contraband", "es", "multiple_players_found", "Varios jugadores se encontraron con ese nombre")
    localization:AddString("contraband", "es", "not_detected_on", "No hay contrabando detectado en")
    localization:AddString("contraband", "es", "no_players_found", "No hay jugadores con ese nombre")
    localization:AddString("contraband", "es", "removed", "Contrabando encontrado y eliminado")
    localization:AddString("contraband", "es", "removed_from", "Contrabando encontrado y eliminado de")
    localization:AddString("contraband", "es", "unknown_action", "Acción contrabando desconocido")
    -- Swedish
    localization:AddString("contraband", "sv", "detected", "Smuggelgods upptäckt")
    localization:AddString("contraband", "sv", "detected_on", "Upptäckta smuggelgods på")
    --localization:AddString("contraband", "sv", "help_text_check", '')
    --localization:AddString("contraband", "sv", "help_text_remove", '')
    localization:AddString("contraband", "sv", "invalid_player_name", "Du måste ange en giltig spelarnamn")
    --localization:AddString("contraband", "sv", "invalid_syntax", '')
    localization:AddString("contraband", "sv", "multiple_players_found", "Flera spelare hittade med det namnet")
    localization:AddString("contraband", "sv", "not_detected_on", "Ingen smuggling som upptäckts på")
    localization:AddString("contraband", "sv", "no_players_found", "Inga spelare hittade med det namnet")
    localization:AddString("contraband", "sv", "removed", "Smuggelgods hittas och tas bort")
    localization:AddString("contraband", "sv", "removed_from", "Hittade och tog bort smuggelgods från")
    localization:AddString("contraband", "sv", "unknown_action", "Okänd contraband åtgärder")
end
