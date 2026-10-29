-- етат чит сдэлан @zenithee

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Aliases = {
    BloxStrike = {
        PlaceIds = {
            114234929420007,
        },
        Url = "https://flowauth.net/v1/loaders/0e9ca766ae3be81d27c2263d3de86de5.lua",
    },

    MM2 = {
        PlaceIds = {
            142823291,
        },
        Url = "https://flowauth.net/v1/loaders/9c34e5e225f5d08c50886f3020acf1c8.lua",
    },
}

local function FindGame(PlaceId)
    for _, Data in pairs(Aliases) do
        for _, Id in ipairs(Data.PlaceIds) do
            if PlaceId == Id then
                return Data
            end
        end
    end
end

local Data = FindGame(game.PlaceId)

if not Data then
    Player:Kick("place not found")
    return
end

pcall(function()
    loadstring(game:HttpGet(Data.Url))()
end)
