fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'notbad-save-health-armour'
author 'NotBad'
description 'Saves health and armour when a player leaves and restores them when they come back. https://discord.gg/JG49fzm2zF'
version '2.0.0'

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/config.lua',
    'server/storage.lua',
    'server/main.lua'
}
