PLUGIN.Title = "Explosives Removal"
PLUGIN.Version = "0.1.0"
PLUGIN.Description = "Removes any explosives from a player's inventory and hotbar."
PLUGIN.Author = "Luke Spragg - Wulfspider"

function PLUGIN:Init()
    print("Explosives removal team dispatched!")
end

function PLUGIN:ERT(netuser)
    local inv = netuser.playerClient.rootControllable.idMain:GetComponent("Inventory")
    items = { "Explosive Charge", "Explosives", "F1 Grenade" }
    for i, contraban in ipairs(items) do
        local datablock = rust.GetDatablockByName(contraban)
        local item = inv:FindItem(datablock)
        if (item) then
            while (item) do
                inv:RemoveItem(item)
                item = inv:FindItem(datablock)
                if (not item) then
                    break
                end
            end
            rust.Notice(netuser, "Explosives found and removed!")
            print(contraban .. " detected on " .. netuser.displayName .. "! ERT dispatched!")
        end
    end
end

function PLUGIN:OnUserConnect(netuser, args)
    timer.Once(0, function() self:ERT(netuser) end)
end
