-- ============================================
-- DIX DISCORD NOTIFIER v2.0
-- Для Discord Webhook
-- ============================================

local DIX = {
    _VERSION = "2.1.0",
    _AUTHOR = "Stalker-2033",
    _TYPE = "Discord"
}

-- Discord Webhook конфигурация
DIX.Config = {
    WEBHOOK_URL = "ВАШ_DISCORD_WEBHOOK_URL",  -- ЗАМЕНИТЕ НА ВАШ WEBHOOK!
    USERNAME = "DIX System",                    -- Имя бота в Discord
    AVATAR_URL = "https://i.imgur.com/LZfAyO8.png", -- Аватар (опционально)
    ENABLE_EMBEDS = true,                       -- Использовать Embed сообщения
    ENABLE_LOGGING = true
}

-- Проверка HTTP функций
function DIX.checkEnvironment()
    if not (syn or request or http and http.request) then
        warn("[DIX] ❌ HTTP функции недоступны")
        return false
    end
    return true
end

-- Получение HTTP функции
function DIX.getHttpFunction()
    if syn and syn.request then
        return syn.request
    elseif request then
        return request
    elseif http and http.request then
        return http.request
    end
    return nil
end

-- Сбор системной информации
function DIX.collectSystemInfo()
    local player = game:GetService("Players").LocalPlayer
    local success, placeInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    
    local data = {
        user = {
            name = player.Name,
            id = player.UserId,
            displayName = player.DisplayName,
            accountAge = player.AccountAge
        },
        game = {
            placeId = game.PlaceId,
            jobId = game.JobId,
            name = success and placeInfo.Name or "Unknown",
            creator = success and placeInfo.Creator.Name or "Unknown"
        },
        system = {
            time = os.date("%Y-%m-%d %H:%M:%S"),
            timestamp = os.time(),
            platform = tostring(game:GetService("UserInputService"):GetPlatform()),
            memory = math.floor(collectgarbage("count"))
        }
    }
    
    -- Получаем скриншот (если возможно)
    if DIX.Config.ENABLE_SCREENSHOT and game:GetService("CoreGui") then
        pcall(function()
            -- Код для скриншота может быть здесь
        end)
    end
    
    return data
end

-- Создание Embed сообщения для Discord
function DIX.createEmbed(info, color)
    color = color or 3447003  -- Синий цвет по умолчанию
    
    local embed = {
        {
            title = "🚀 DIX System Report",
            color = color,
            fields = {
                {
                    name = "👤 User Information",
                    value = string.format(
                        "**Name:** %s\n" ..
                        "**UserID:** `%d`\n" ..
                        "**Display:** %s\n" ..
                        "**Account Age:** %d days",
                        info.user.name,
                        info.user.id,
                        info.user.displayName,
                        info.user.accountAge
                    ),
                    inline = true
                },
                {
                    name = "🎮 Game Information",
                    value = string.format(
                        "**Game:** %s\n" ..
                        "**Creator:** %s\n" ..
                        "**PlaceID:** `%d`\n" ..
                        "**Server:** `%s`",
                        info.game.name,
                        info.game.creator,
                        info.game.placeId,
                        info.game.jobId:sub(1, 8)
                    ),
                    inline = true
                },
                {
                    name = "📊 System Information",
                    value = string.format(
                        "**Time:** %s\n" ..
                        "**Platform:** %s\n" ..
                        "**Memory:** %.2f KB\n" ..
                        "**Version:** %s",
                        info.system.time,
                        info.system.platform,
                        info.system.memory,
                        DIX._VERSION
                    ),
                    inline = false
                }
            },
            footer = {
                text = string.format("DIX System v%s | %s", DIX._VERSION, DIX._TYPE)
            },
            timestamp = info.system.time
        }
    }
    
    return embed
end

-- Отправка сообщения в Discord
function DIX.sendDiscordMessage(content, options)
    options = options or {}
    
    local httpFunc = DIX.getHttpFunction()
    if not httpFunc then
        return false, "HTTP функция недоступна"
    end
    
    if not DIX.Config.WEBHOOK_URL or DIX.Config.WEBHOOK_URL == "ВАШ_DISCORD_WEBHOOK_URL" then
        return false, "WEBHOOK_URL не настроен"
    end
    
    local payload = {
        username = options.username or DIX.Config.USERNAME,
        avatar_url = options.avatar_url or DIX.Config.AVATAR_URL,
        content = content
    }
    
    if DIX.Config.ENABLE_EMBEDS and options.embeds then
        payload.embeds = options.embeds
    end
    
    local success, response = pcall(function()
        return httpFunc({
            Url = DIX.Config.WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode(payload)
        })
    end)
    
    if success then
        return true, response
    else
        return false, response
    end
end

-- Основная функция инициализации
function DIX.init(customConfig)
    print(string.format("[DIX] 🔧 Initializing Discord v%s", DIX._VERSION))
    
    -- Обновление конфигурации
    if customConfig then
        for key, value in pairs(customConfig) do
            DIX.Config[key] = value
        end
    end
    
    -- Проверка окружения
    if not DIX.checkEnvironment() then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "❌ DIX Error",
            Text = "HTTP functions not available",
            Duration = 5
        })
        return false
    end
    
    -- Сбор информации
    local systemInfo = DIX.collectSystemInfo()
    
    -- Создание Embed
    local embed = DIX.createEmbed(systemInfo, 5763719)  -- Зеленый цвет
    
    -- Отправка в Discord
    local success, response = DIX.sendDiscordMessage(nil, {
        embeds = embed,
        username = DIX.Config.USERNAME
    })
    
    -- Логирование
    if DIX.Config.ENABLE_LOGGING then
        if success then
            print("[DIX] ✅ Discord message sent successfully")
        else
            warn("[DIX] ❌ Failed to send Discord message:", response)
        end
    end
    
    -- Уведомление в Roblox
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = success and "✅ DIX Discord" or "⚠️ DIX Discord",
        Text = success and "Message sent to Discord" or "Failed to send",
        Duration = 3,
        Icon = "rbxassetid://4483345998"
    })
    
    -- Возврат результатов
    return {
        version = DIX._VERSION,
        config = DIX.Config,
        systemInfo = systemInfo,
        success = success,
        response = response,
        timestamp = os.time()
    }
end

-- Функция для отправки кастомных сообщений
function DIX.sendCustomMessage(text, options)
    options = options or {}
    
    local embed = {
        {
            title = options.title or "💬 Custom Message",
            description = text,
            color = options.color or 15105570,  -- Оранжевый
            timestamp = os.date("%Y-%m-%dT%H:%M:%SZ"),
            footer = {
                text = string.format("Sent via DIX v%s", DIX._VERSION)
            }
        }
    }
    
    return DIX.sendDiscordMessage(nil, {
        embeds = embed,
        username = options.username or DIX.Config.USERNAME
    })
end

-- Функция для отправки ошибок
function DIX.sendError(errorMsg, context)
    local embed = {
        {
            title = "⚠️ Error Report",
            description = string.format("**Error:** ```%s```\n**Context:** %s", 
                tostring(errorMsg):sub(1, 1000), 
                context or "No context"),
            color = 15548997,  -- Красный
            fields = {
                {
                    name = "System Info",
                    value = string.format("User: %s\nPlace: %d\nTime: %s",
                        game:GetService("Players").LocalPlayer.Name,
                        game.PlaceId,
                        os.date()
                    )
                }
            },
            timestamp = os.date("%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    return DIX.sendDiscordMessage(nil, {
        embeds = embed,
        username = DIX.Config.USERNAME .. " | Error"
    })
end

-- Функция для отправки простого текста
function DIX.sendText(text)
    return DIX.sendDiscordMessage(text, {
        username = DIX.Config.USERNAME
    })
end

-- Функция для отправки с вложением (файлом)
function DIX.sendWithAttachment(content, filename, filecontent)
    -- Discord webhook с файлами сложнее, но можно отправить как текст
    local message = string.format("**File:** %s\n```\n%s\n```\n%s", 
        filename, 
        filecontent:sub(1, 1500), 
        content or "")
    
    return DIX.sendText(message)
end

-- Автоматическая инициализация
local autoInitSuccess, autoInitError = pcall(function()
    if DIX.Config.WEBHOOK_URL and DIX.Config.WEBHOOK_URL ~= "ВАШ_DISCORD_WEBHOOK_URL" then
        DIX.init()
    else
        warn("[DIX] ⚠️ WEBHOOK_URL не настроен. Пропускаю авто-инициализацию.")
    end
end)

if not autoInitSuccess and DIX.Config.ENABLE_LOGGING then
    warn("[DIX] Auto-init error:", autoInitError)
end

-- Экспорт API
return DIX