PLUGIN.Title = "Hardcore GUI"
PLUGIN.Version = "0.2.2"
PLUGIN.Description = "Forcefully hides the player stat bars, inventory, and hotbar slots."
PLUGIN.Author = "Luke Spragg - Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/resources/140/"

function PLUGIN:Init()
    -- Log that plugin is loading
    print(self.Title .. " v" .. self.Version .. " loading...")

    -- Run update check
    self:GetLatestVersion()

    -- Continuously trigger event to hide the GUI
    timer.Repeat(0.1, 0, function() self:TimerEvent() end)

    -- Log that plugin has loaded
    print(self.Title .. " v" .. self.Version .. " loaded!")
end

function PLUGIN:GuiHide(netuser)
    -- Run GUI hide client command
    rust.RunClientCommand(netuser, "gui.hide")
end

function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
    -- Trigger GUI hide function on player spawn
    timer.Once(0.1, function() self:GuiHide(playerclient.netUser) end)
end

function PLUGIN:TimerEvent()
    -- Loop through all online players
    local netusers = rust.GetAllNetUsers()
    for u, netuser in pairs(netusers) do
        if (rust.GetCharacter) then
            local char = rust.GetCharacter(netuser)
            if (char) then
                if (char.alive) then
                    -- Check if player has been online at least 20 seconds
                    if (netuser:SecondsConnected() >= 20) then
                        -- Call GUI hide function
                        self:GuiHide(netuser)
                    end
                end
            end
        end
    end
end

function PLUGIN:GetLatestVersion()
    -- Get latest version from URL
    webrequest.Send("https://raw2.github.com/Wulfspider/OxidePlugins/master/versions/hardcoregui.txt", function(code, response)
        self:UpdateCheck(code, response)
    end)
end

function PLUGIN:UpdateCheck(code, response)
    local pattern = "%d%.%d+" -- Ex. 0.1.0 or 0.2
    local compare = string.find(response, pattern) -- Compare response to version pattern

    -- Check for valid latest version
    if (compare ~= nil) then
        local latest = response
        -- Check if new version is available
        if (self.Version < latest) then
            -- Report update available to server log
            print(self.Title .. " is outdated! Installed version: " .. self.Version .. ", Latest version: " .. latest)
        end
    end
end
