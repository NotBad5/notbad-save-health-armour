game 'gta5'
fx_version 'cerulean'

author 'NotBad#9927'
description 'https://discord.gg/JG49fzm2zF'

lua54 'yes'
version '1.0.0'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua'
}

shared_scripts {
    'config.lua',
}