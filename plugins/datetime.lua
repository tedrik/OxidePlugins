PLUGIN.Title = "DateTime"
PLUGIN.Version = "0.1.1"
PLUGIN.ConfigVersion = "0.1.0"
PLUGIN.Description = "Shows your server's real date or time with commands."
PLUGIN.Author = "Luke Spragg - Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/resources/272/"

function PLUGIN:Init()
    -- Log that plugin is loading
    print(self.Title .. " v" .. self.Version .. " loading...")

    -- Load configuration file
    self:LoadConfiguration()

    -- Run update check
    self:UpdateCheck()

    -- Add chat commands
    self:AddChatCommand("date", self.cmdDate)
    self:AddChatCommand("time", self.cmdTime)

    -- Log that plugin has loaded
    print(self.Title .. " v" .. self.Version .. " loaded!")
end

function PLUGIN:cmdDate(netuser, cmd)
    local date = System.DateTime.Now:ToString(self.Config.dateformat)
    if (self.Config.chatenabled) then
        rust.SendChatToUser(netuser, self.Config.chatname, date)
    end
    if (self.Config.noticesenabled) then
        rust.Notice(netuser, date)
    end
end

function PLUGIN:cmdTime(netuser, cmd)
    local time = System.DateTime.Now:ToString(self.Config.timeformat)
    if (self.Config.chatenabled) then
        rust.SendChatToUser(netuser, self.Config.chatname, time)
    end
    if (self.Config.noticesenabled) then
        rust.Notice(netuser, time)
    end
end

function PLUGIN:LoadConfiguration()
    -- Load the configuration file
    local b, res = config.Read("datetime")
    self.Config = res or {}

    -- If no configuration file exists, create it
    if (not b) then
        self:DefaultConfiguration()
        if (res) then
            config.Save("datetime")
        end

        -- Log that the default configuration has loaded
        print(self.Title .. " default configuration loaded!")
    end

    -- Check for newer configuration
    if (self.Config.configversion ~= self.ConfigVersion) then
        print(self.Title .. " configuration is outdated! Creating new file; be sure to update the settings!")
        self:DefaultConfiguration()
        config.Save("datetime")
    end
end

function PLUGIN:DefaultConfiguration()
    -- Set default configuration settings
    self.Config.configversion = self.ConfigVersion
    self.Config.chatname = "Server"
    self.Config.chatenabled = true
    self.Config.noticesenabled = true
    self.Config.dateformat = "M/dd/yyyy" -- 2/20/2014
    self.Config.timeformat = "h:mm tt" -- 1:01 PM
end

function PLUGIN:UpdateCheck()
    -- Get latest version from URL
    local url = "https://raw.github.com/Wulfspider/OxidePlugins/master/versions/datetime.txt"
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
