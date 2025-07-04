--[[
    ✨ Auto Farming Bot for Growtopia
    🏦 Features: Harvest, Drop, Buy Pack, Webhook Reports
    🔧 By: KeritingGT (Beautified + Webhook Rich Embed)
--]]

local bot = getBot()
local world = bot:getWorld()
local inventory = bot:getInventory()

------------------------------------------------------------
-- 🔧 CONFIGURATION SECTION
------------------------------------------------------------

local BlockID = 4584 -- ID of the farmable block (e.g., pepper tree)

local FarmWorlds = {""}
local FarmDoorID = ""

local StorageWorld = ""
local StorageDoorSeedID = ""
local StorageDoorBlockID = ""

local PackDropWorld = ""
local PackDropDoorID = ""

local WebhookUrl = ""
local YourDiscordID = ""

local delayHarvest = 130

local packname = "world_lock"
local pricepack = 2000
local PackItemID = 242
local PackDropCount = 2

------------------------------------------------------------
-- ✅ Format & Convert Names to Uppercase
------------------------------------------------------------

StorageWorld = string.upper(StorageWorld)
StorageDoorSeedID = string.upper(StorageDoorSeedID)
StorageDoorBlockID = string.upper(StorageDoorBlockID)
PackDropWorld = string.upper(PackDropWorld)
PackDropDoorID = string.upper(PackDropDoorID)
FarmDoorID = string.upper(FarmDoorID)

------------------------------------------------------------
-- 📢 DISCORD WEBHOOK (RICH EMBED)
------------------------------------------------------------

function sendWebhook(message, statusTitle, colorCode)
    local wh = Webhook.new(WebhookUrl)
    wh.username = "🌾 KeritingGT Bot"
    wh.avatar_url = "https://cdn.discordapp.com/avatars/208654299738144768/bb27c340964dcd6a75ff1883d1341a6e.png?size=1024"

    wh.embed1.use = true
    wh.embed1.title = statusTitle or "📢 Bot Notification"
    wh.embed1.description = message
    wh.embed1.color = colorCode or 65280 -- default green
    wh.embed1.footer.text = "🕐 " .. os.date("%Y-%m-%d %H:%M:%S")
    wh.embed1.timestamp = os.time()

    wh:send()
end

------------------------------------------------------------
-- ⏱️ Time Formatting
------------------------------------------------------------

function formatTime(seconds)
    seconds = tonumber(seconds)
    if seconds <= 0 then return "00:00:00" end
    local h = string.format("%02.f", math.floor(seconds / 3600))
    local m = string.format("%02.f", math.floor(seconds / 60 % 60))
    local s = string.format("%02.f", math.floor(seconds % 60))
    return h .. ":" .. m .. ":" .. s
end

------------------------------------------------------------
-- 🚪 World Join Helper
------------------------------------------------------------

function joinWorld(worldName, doorID)
    sleep(3000)
    bot:warp(worldName, doorID)
    sleep(3000)
end

------------------------------------------------------------
-- 🌳 Tree Scanner
------------------------------------------------------------

function scanTrees(id)
    local count = 0
    for _, tile in pairs(world:getTiles()) do
        if tile.fg == id and tile:canHarvest() then count = count + 1 end
    end
    return count
end

------------------------------------------------------------
-- 🥜 Harvest Function
------------------------------------------------------------

function harvest(worldName)
    bot.auto_collect = true
    for _, tile in pairs(world:getTiles()) do
        if bot.status == 1 and (tile.fg == BlockID + 1 or tile.bg == BlockID + 1) and tile:canHarvest() then
            reconnectIfNeeded(worldName)
            bot:findPath(tile.x, tile.y)
            bot:hit(tile.x, tile.y)
            sleep(delayHarvest)
            bot:hit(tile.x, tile.y)
            sleep(delayHarvest)
        end
        if inventory:getItemCount(BlockID) >= 200 then break end
    end
end

------------------------------------------------------------
-- 🚚 Drop Handler
------------------------------------------------------------

function dropItems(worldName)
    bot.auto_collect = false

    if inventory:getItemCount(BlockID) > 0 then
        reconnectToStorage(worldName)
        joinWorld(StorageWorld, StorageDoorBlockID)
        while inventory:getItemCount(BlockID) > 0 do
            bot:drop(BlockID, inventory:getItemCount(BlockID))
            sleep(500)
            bot:moveRight()
        end
    end

    if inventory:getItemCount(BlockID + 1) > 50 then
        reconnectToStorage(worldName)
        joinWorld(StorageWorld, StorageDoorSeedID)
        while inventory:getItemCount(BlockID + 1) > 0 do
            bot:drop(BlockID + 1, inventory:getItemCount(BlockID + 1))
            sleep(500)
            bot:moveRight()
        end
    end

    while bot.gem_count > pricepack do
        reconnectIfNeeded(worldName)
        bot:sendPacket(2, "action|buy\nitem|" .. packname)
        sleep(3000)
    end

    if inventory:getItemCount(PackItemID) > PackDropCount then
        reconnectToPackWorld(worldName)
        joinWorld(PackDropWorld, PackDropDoorID)
        while inventory:getItemCount(PackItemID) > PackDropCount do
            bot:drop(PackItemID, inventory:getItemCount(PackItemID))
            sleep(500)
            bot:moveLeft()
        end
    end

    sendWebhook(string.format([[
**🤖 Bot Name:** `%s`
**🌍 World:** `%s`
**📦 Block Dropped:** `%d`
**🌱 Seed Dropped:** `%d`
**💰 Packs Dropped:** `%d`
    ]], bot.name, world.name, floats(BlockID).ucanlar or 0, floats(BlockID+1).ucanlar or 0, floats(PackItemID).ucanlar or 0), "📄 Drop Report", 16776960)

    joinWorld(worldName, FarmDoorID)
end

------------------------------------------------------------
-- 💡 Helpers
------------------------------------------------------------

function floats(id)
    local float = 0
    for _, obj in pairs(world:getObjects()) do
        if obj.id == id then float = float + obj.count end
    end
    return { ucanlar = float }
end

function reconnectIfNeeded(worldName)
    if bot.status ~= 1 then
        sendWebhook(string.format([[
<@%s> ⚠️ **Bot Disconnected**
**🤖 Name:** `%s`
**❌ Status:** Offline
**🔄 Attempting Reconnect...**
        ]], YourDiscordID, bot.name), "❌ Disconnected", 16711680)

        while bot.status ~= 1 do
            bot:connect()
            sleep(10000)
        end

        sendWebhook(string.format([[
<@%s> ✅ **Bot Reconnected**
**🤖 Name:** `%s`
**🌍 World:** `%s`
**📶 Status:** Connected
        ]], YourDiscordID, bot.name, world.name), "✅ Online", 255)
        joinWorld(worldName, FarmDoorID)
    end

    if world.name ~= worldName then
        joinWorld(worldName, FarmDoorID)
    end
end

function reconnectToStorage(worldName)
    reconnectIfNeeded(worldName)
    if world.name ~= StorageWorld then
        joinWorld(StorageWorld, StorageDoorSeedID)
    end
end

function reconnectToPackWorld(worldName)
    reconnectIfNeeded(worldName)
    if world.name ~= PackDropWorld then
        joinWorld(PackDropWorld, PackDropDoorID)
    end
end

------------------------------------------------------------
-- 🚀 MAIN
------------------------------------------------------------

for _, farmName in ipairs(FarmWorlds) do
    farmName = string.upper(farmName)
    reconnectIfNeeded(farmName)
    joinWorld(farmName, FarmDoorID)

    local treesReady = scanTrees(BlockID + 1)
    while treesReady > 1 do
        if inventory:getItemCount(BlockID) < 200 then
            reconnectIfNeeded(farmName)
            harvest(farmName)
        end
        dropItems(farmName)
        reconnectIfNeeded(farmName)
        joinWorld(farmName, FarmDoorID)
        treesReady = scanTrees(BlockID + 1)
    end
end

sendWebhook(string.format("✅ **%s** has completed all farm worlds. Leaving...", bot.name), "✅ All Done", 65280)
bot:leaveWorld()
