-----------------For support, scripts, and more----------------
--------------- https://discord.gg/AeCVP2F8h7  -------------
---------------------------------------------------------------

fx_version 'cerulean'
game 'gta5'

description 'Microphone System'
version '1.0'
author 'Snipe'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua', 
	'config.lua'
}

client_scripts{
    'client/*.lua',
} 

server_scripts{
    'server/*.lua',
} 
