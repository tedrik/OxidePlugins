PLUGIN.Title = "Force Hide GUI"
PLUGIN.Version = "0.1.0"
PLUGIN.Description = "Forcefully hides the player's entire GUI, good for hardcore servers."
PLUGIN.Author = "Luke Spragg - Wulfspider"

function PLUGIN:Init()
    print("Force Hide UI plugin loaded!")
    self.Clients = {}
    timer.Repeat(1, 0, function() self:timerEvent() end)
end

function PLUGIN:GuiHide(netuser)
    rust.RunClientCommand(netuser, "gui.hide")
end

function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
    timer.Once(5, function() self:GuiHide(playerclient.netUser) end)
end

function PLUGIN:timerEvent()
    local netusers = rust.GetAllNetUsers()
    for u, netuser in pairs(netusers) do
        if (netuser.playerClient.rootControllable) then
            local char = netuser.playerClient.rootControllable.idMain:GetComponent("Character")
            if (char) then
                if (char.alive) then
                    if (netuser:SecondsConnected() >= 20) then
                        self:GuiHide(netuser)
                    end
                end
            end
        end
    end
end
