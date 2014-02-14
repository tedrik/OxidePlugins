PLUGIN.Title = "Hardcore GUI"
PLUGIN.Version = "0.2.0"
PLUGIN.Description = "Forcefully hides the player stat bars, inventory, and hotbar slots."
PLUGIN.Author = "Luke Spragg - Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/resources/140/"

-- Let the server owner know the plugin has loaded
print(PLUGIN.Title .. " v" .. PLUGIN.Version .. " loaded")

function PLUGIN:Init()
    -- Continuously trigger the event to hide the GUI
    timer.Repeat(1, 0, function() self:timerEvent() end)
end

function PLUGIN:GuiHide(netuser)
    -- Run GUI hide client command
    rust.RunClientCommand(netuser, "gui.hide")
end

function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
    -- Trigger GUI hide function on player spawn
    timer.Once(5, function() self:GuiHide(playerclient.netUser) end)
end

function PLUGIN:timerEvent(playerclient)
    local netusers = rust.GetAllNetUsers()

    -- Loop through all online players
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
