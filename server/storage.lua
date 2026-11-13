-- Storage for the saved values. Both backends keep the same JSON: {"Health":200,"Armour":50}

Storage = {}

local TABLE = 'notbad_health_armour'
local useSql = Config.Storage == 'oxmysql'

if useSql and GetResourceState('oxmysql') ~= 'started' then
    print(('^3[%s]^7 Config.Storage is "oxmysql" but oxmysql is not running. Using kvp instead.'):format(GetCurrentResourceName()))
    useSql = false
end

local function decode(raw)
    if type(raw) ~= 'string' or raw == '' then return nil end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' and (data.Health or data.Armour) then return data end
    return nil
end

if useSql then
    exports.oxmysql:query(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `identifier` VARCHAR(255) NOT NULL,
            `status` VARCHAR(255) NULL DEFAULT NULL,
            PRIMARY KEY (`identifier`)
        )
    ]]):format(TABLE), {}, function() end)

    function Storage.get(identifier, cb)
        exports.oxmysql:scalar(('SELECT `status` FROM `%s` WHERE `identifier` = ? LIMIT 1'):format(TABLE), { identifier }, function(raw)
            cb(decode(raw))
        end)
    end

    function Storage.set(identifier, data)
        exports.oxmysql:query(
            ('INSERT INTO `%s` (`identifier`, `status`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `status` = VALUES(`status`)'):format(TABLE),
            { identifier, json.encode(data) }, function() end)
    end
else
    function Storage.get(identifier, cb)
        cb(decode(GetResourceKvpString('status:' .. identifier)))
    end

    function Storage.set(identifier, data)
        SetResourceKvp('status:' .. identifier, json.encode(data))
    end
end

Storage.name = useSql and 'oxmysql' or 'kvp'
