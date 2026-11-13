EVT = 'notbad-save-health-armour'

-- GTA: 100 health is an empty health bar, at or below that the player is dead
DEAD_HEALTH = 100

local function running(resource)
    return GetResourceState(resource) == 'started' or GetResourceState(resource) == 'starting'
end

function ResolveFramework()
    local choice = Config.Framework
    if choice ~= 'auto' then return choice end

    if running('es_extended') then return 'esx' end
    if running('qbx_core') then return 'qbx' end
    if running('qb-core') then return 'qb' end
    return 'standalone'
end
