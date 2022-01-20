--[[----------------------------------
Creation Date:	12/05/2021
]]------------------------------------
fx_version 'cerulean'
game 'gta5'
author 'Leah#0001'
version '1.0.0'
versioncheck 'https://raw.githubusercontent.com/Leah-UK/bixbi_illegalsales/main/fxmanifest.lua'
lua54 'yes'

shared_scripts {
	'@es_extended/imports.lua',
	'config.lua'
}

client_scripts {
	'client/client.lua'
}

server_scripts {
	'server/server.lua'
}

exports {
	"DrugMenu"
}

dependencies {
	'bixbi_core'
}
