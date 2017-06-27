--
-- Mod macroloja
--
-- Inicializador
--

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
dofile(modpath.."/shop.lua")
dofile(modpath.."/drop.lua")
notificar("OK")




