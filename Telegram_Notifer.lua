-- ============================================
-- DIX Telegram Notifier v2.0
-- Приватный репозиторий: github.com/Dixyi/private-repo
-- ============================================

local DixNotifier = {
    Version = "2.0",
    Repository = "github.com/Dixyi/private-repo",
    LastUpdate = "13.10.2025"
}

-- Конфигурация (загружается извне)
local Config = {
    BOT_TOKEN = nil,
    CHAT_IDS = {},
    SECURITY_KEY = nil
}

-- Инициализация конфигурации
function DixNotifier.loadConfig(userConfig)
    if userConfig then
        for key, value in pairs(userConfig) do
            Config[key] = value
        end
    end
    
    -- Валидация минимальных требований
    if not Config.BOT_TOKEN or #Config.CHAT_IDS == 0 then
        warn("[DIX] Конфигурация неполная. Некоторые функции могут быть ограничены.")
        return false
    end
    
    return true
end

-- Расширенный сбор данных
function DixNotifier.collectSystemData()
    local data = {
        user = {
            name = game:GetService("Players").LocalPlayer.Name,
            id = game:GetService("Players").LocalPlayer.UserId,
            accountAge = game:GetService("Players").LocalPlayer.AccountAge
        },
        system = {
            time = os.date("%Y-%m-%d %H:%M:%S"),
            place = {
                id = game.PlaceId,
                name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            },
            server = game.JobId
        },
        hardware = {
            platform = tostring(game:GetService("UserInputService"):GetPlatform()),
            memory = math.floor(collectgarbage("count"))
        }
    }
    
    return data
end

-- Форматирование сообщения
function DixNotifier.formatMessage(data, template)
    template = template or "default"
    
    local templates = {
        default = string.format(
            "🔔 **DIX Notification**\n" ..
            "👤 User: `%s`\n" ..
            "🆔 UID: `%d`\n" ..
            "🎮 Place: `%s`\n" ..
            "📍 Place ID: `%d`\n" ..
            "🕐 Time: `%s`\n" ..
            "⚙️ Server: `%s`",
            data.user.name,
            data.user.id,
            data.system.place.name,
            data.system.place.id,
            data.system.time,
            data.system.server:sub(1, 8)
        ),
        
        minimal = string.format(
            "DIX: %s (%d) | %s",
            data.user.name,
            data.user.id,
            data.system.time
        ),
        
        detailed = string.format(
            "🚀 **DIX System Report**\n\n" ..
            "📊 **User Info**\n" ..
            "• Name: `%s`\n" ..
            "• UserID: `%d`\n" ..
            "• Account Age: `%d days`\n\n" ..
            "🌐 **Session Info**\n" ..
            "• Place: `%s`\n" ..
            "• PlaceID: `%d`\n" ..
            "• Server: `%s`\n" ..
            "• Time: `%s`\n\n" ..
            "💻 **System**\n" ..
            "• Platform: `%s`\n" ..
            "• Memory: `%.2f KB`",
            data.user.name,
            data.user.id,
            data.user.accountAge,
            data.system.place.name,
            data.system.place.id,
            data.system.server,
            data.system.time,
            data.hardware.platform,
            data.hardware.memory
        )
    }
    
    return templates[template] or templates.default
end

-- Отправка в Telegram с ретраями
function DixNotifier.sendToTelegram(message, maxRetries)
    maxRetries = maxRetries or 3
    
    local requestFunc
    if syn then
        requestFunc = syn.request
    elseif request then
        requestFunc = request
    elseif http and http.request then
        requestFunc = http.request
    else
        return false, "HTTP библиотека не найдена"
    end
    
    local results = {}
    
    for _, chatId in ipairs(Config.CHAT_IDS) do
        for attempt = 1, maxRetries do
            local success, response = pcall(function()
                return requestFunc({
                    Url = "https://api.telegram.org/bot" .. Config.BOT_TOKEN .. "/sendMessage",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["X-DIX-Version"] = DixNotifier.Version
                    },
                    Body = game:GetService("HttpService"):JSONEncode({
                        chat_id = chatId,
                        text = message,
                        parse_mode = "Markdown",
                        disable_web_page_preview = true
                    })
                })
            end)
            
            if success then
                results[chatId] = {success = true, attempt = attempt}
                break
            elseif attempt == maxRetries then
                results[chatId] = {success = false, error = response}
            end
            
            task.wait(1) -- Задержка между попытками
        end
    end
    
    return results
end

-- Основная функция инициализации
function DixNotifier.init(customConfig)
    print(string.format("[DIX] Initializing v%s...", DixNotifier.Version))
    
    -- Загрузка конфигурации
    if not DixNotifier.loadConfig(customConfig) then
        warn("[DIX] Configuration issue detected")
    end
    
    -- Сбор данных
    local systemData = DixNotifier.collectSystemData()
    
    -- Форматирование сообщения
    local message = DixNotifier.formatMessage(systemData, "detailed")
    
    -- Отправка
    local sendResults = DixNotifier.sendToTelegram(message)
    
    -- Анализ результатов
    local successCount = 0
    for chatId, result in pairs(sendResults) do
        if result.success then
            successCount = successCount + 1
        else
            warn(string.format("[DIX] Failed to send to chat %s: %s", chatId, result.error))
        end
    end
    
    -- Фидбек пользователю
    local notification = {
        Title = string.format("DIX v%s", DixNotifier.Version),
        Text = string.format("System: %d/%d channels active", successCount, #Config.CHAT_IDS),
        Duration = 3,
        Icon = "rbxassetid://4483345998"
    }
    
    if game:GetService("StarterGui"):GetCore("SendNotification") then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", notification)
        end)
    end
    
    print(string.format("[DIX] Initialization complete. Status: %d/%d", successCount, #Config.CHAT_IDS))
    
    return {
        success = successCount > 0,
        data = systemData,
        results = sendResults,
        config = {
            version = DixNotifier.Version,
            repo = DixNotifier.Repository
        }
    }
end

-- Экспорт модуля
return DixNotifier