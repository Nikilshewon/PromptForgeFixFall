fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'forge-vehcontrol'
author 'PromptForge'
description 'Vehicle control panel for Qbox'
version '1.0.0'

dependencies { 'ox_lib' }

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts { 'client/main.lua' }

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
