fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'renzu_multicharacter'
author 'renzu (original) | Reset by Asheville'
description 'Clean multicharacter for ESX / QBCore / QBox. Original UI & core flow preserved, with modern bridge support for frameworks, appearance and spawn systems.'
version '1.1.0'

ui_page 'web/index.html'

shared_scripts {
    'shared/locale.lua',
    'config.lua',
    'config_spawns.lua',
    'default_skin.lua',
}

client_scripts {
    'bridge/connect/client/main.lua',
    'bridge/appearance/client/*.lua',
    'bridge/framework/client/*.lua',
    'bridge/spawn/*.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/connect/server/main.lua',
    'bridge/appearance/server/*.lua',
    'bridge/framework/server/*.lua',
    'server/main.lua',
}

files {
    'web/index.html',
    'web/script.js',
    'web/style.css',
    'web/logo.png',
    'web/loading.gif',
    'web/ped.jpg',
    'web/images/*.png',
    'web/sound/*.mp3',
    'web/sound/*.ogg',
    'shared/nationalities.json',
}

dependencies {
    '/server:5848',
    '/onesync',
    'oxmysql',
}