fx_version 'cerulean'
game 'gta5'

author 'Monolith Scripts | https://discord.gg/monolith'
description 'Discord Permission Sync for FiveM'
version '1.0.0'
lua54 'yes'

escrow_ignore {
  'config.lua',
}

shared_scripts {
  '@es_extended/imports.lua',
}

server_scripts {
  'config.lua',
  'server.lua'
}

dependencies {
  'es_extended'
}
