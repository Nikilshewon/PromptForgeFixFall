fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'PromptForgeFixFall'
description 'Auto-rescue when falling under the map, with /fixfall manual backup. ESX / QBCore / QBox / standalone.'
author 'PromptForge'
version '2.0.0'

shared_script 'config.lua'

client_scripts {
    'client/bridge.lua',
    'client/main.lua',
}
