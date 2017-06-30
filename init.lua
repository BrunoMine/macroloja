--[[
	Mod MacroLoja para Minetest
	Copyright (C) 2017 BrunoMine (https://github.com/BrunoMine)
	
	Recebeste uma cópia da GNU Lesser General
	Public License junto com esse software,
	se não, veja em <http://www.gnu.org/licenses/>. 
	
	Inicialização de scripts
  ]]

-- Notificador de Inicializador
local notificar = function(msg)
	if minetest.setting_get("log_mods") then
		minetest.debug("[Macroloja] "..msg)
	end
end

local modpath = minetest.get_modpath("macroloja")

-- Variavel global
macroloja = {}

-- Carregar scripts
notificar("Carregando...")
dofile(modpath.."/drop.lua")
dofile(modpath.."/shop.lua")
dofile(modpath.."/shop_admin.lua")
notificar("OK")




