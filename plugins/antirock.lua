PLUGIN.Title = "Anti-Rock"
PLUGIN.Version = "0.1.2"
PLUGIN.ConfigVersion = "0.1.0"
PLUGIN.Description = "Removes the starter rock from player's inventory/hotbar on connect."
PLUGIN.Author = "Luke Spragg - Wulfspider"
PLUGIN.Credits = "Shadowdemonx9 (Rock Removal plugin)"
PLUGIN.Url = "http://forum.rustoxide.com/resources/260/"

function PLUGIN:Init()
    -- Log that plugin is loading
    print(self.Title .. " v" .. self.Version .. " loading...")

    -- Load configuration file
    self:LoadConfiguration()

    -- Run update check
    self:UpdateCheck()

    -- Log that plugin has loaded
    print(self.Title .. " v" .. self.Version .. " loaded!")
end

-- Preload the better item list
function PLUGIN:OnDatablocksLoaded()
    self.datablocks = {}
    for i=1, #self.Config.betteritems do
        local blockname = self.Config.betteritems[i]
        self.datablocks[blockname] = rust.GetDatablockByName(blockname)
    end
end

function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
    -- Run rock removal check
    timer.Once(0.1, function() self:RemoveRock(playerclient.netUser) end)
end

function PLUGIN:RemoveRock(netuser)
    local inv = rust.GetInventory(netuser)
    local rockblock = rust.GetDatablockByName("Rock")
    local rock = inv:FindItem(rockblock)
    local betteritem = false

    -- Check inventory for better items
    for i=1, #self.Config.betteritems do
        local betterblock = self.datablocks[self.Config.betteritems[i]]
        local item = inv:FindItem(betterblock)
        if (item) then
            betteritem = true
        end
    end

    print(betteritem)
    -- Remove rock if better item found
    if (betteritem ~= false) then
        while (rock) do
            inv:RemoveItem(rock)
            rock = inv:FindItem(rockblock)
        end
    end

    -- Give player a starter rock if allowed
    if ((betteritem == nil) and (rock == nil) and (self.Config.starterrock == true)) then
        local pref = rust.InventorySlotPreference(InventorySlotKind.Belt, false, InventorySlotKindFlags.Belt)
        inv:AddItemAmount(rockblock, 1, pref)
    end
end

function PLUGIN:LoadConfiguration()
    -- Load the configuration file
    local b, res = config.Read("antirock")
    self.Config = res or {}

    -- If no configuration file exists, create it
    if (not b) then
        self:DefaultConfiguration()
        if (res) then
            config.Save("antirock")
        end

        -- Log that the default configuration has loaded
        print(self.Title .. " default configuration loaded!")
    end

    -- Check for newer configuration
    if (self.Config.configversion ~= self.ConfigVersion) then
        print(self.Title .. " config is outdated! Creating new file; be sure to update!")
        self:DefaultConfiguration()
        config.Save("antirock")
    end
end

function PLUGIN:DefaultConfiguration()
    -- Set default configuration settings
    self.Config.configversion = self.ConfigVersion
    self.Config.starterrock = true
    self.Config.betteritems = { "Hatchet", "Pick Axe", "Stone Hatchet" }
end

function PLUGIN:UpdateCheck()
    -- Get latest version from URL
    local url = "https://raw.github.com/Wulfspider/OxidePlugins/master/versions/antirock.txt"
    local request = webrequest.Send(url, function(code, response)
        if (code == 200) then
            -- Version pattern match and compare
            local pattern = "%d%.%d+" -- Ex. 0.1.0 or 0.2
            local compare = string.find(response, pattern) -- Compare response to version pattern

            -- Check for valid latest version
            if (compare ~= nil) then
                -- Check if new version is available
                if (self.Version < response) then
                    -- Report update available to server log
                    print(self.Title .. " is outdated! Installed version: " .. self.Version .. ", Latest version: " .. response)
                end
            end
        else
            print(self.Title .. " update check failed!")
        end
    end)
    if (not request) then 
        print(self.Title .. " update check failed!")
    end
end
