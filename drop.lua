--[[
	Mod MacroLoja para Minetest
	Copyright (C) 2017 BrunoMine (https://github.com/BrunoMine)
	
	Recebeste uma cópia da GNU Lesser General
	Public License junto com esse software,
	se não, veja em <http://www.gnu.org/licenses/>. 
	
	Drop de itens
  ]]


-- Arredondar coordenada
local arredondar = function(pos)
	local r = {}
	if pos.x > (math.floor(pos.x)+0.5) then
		r.x = math.ceil(pos.x)
	else
		r.x = math.floor(pos.x)
	end
	if pos.y > (math.floor(pos.y)+0.5) then
		r.y = math.ceil(pos.y)
	else
		r.y = math.floor(pos.y)
	end
	if pos.z > (math.floor(pos.z)+0.5) then
		r.z = math.ceil(pos.z)
	else
		r.z = math.floor(pos.z)
	end
	return r
end

-- Puxar item para o centro
local puxar_centro = function(pos)
	local cp = arredondar(pos)
	local r = {x=pos.x, y=pos.y, z=pos.z}
	
	if pos.x > cp.x + 0.25 then
		r.x = cp.x + 0.25
	elseif pos.x < cp.x - 0.25 then
		r.x = cp.x - 0.25
	end
	if pos.z > cp.z + 0.25 then
		r.z = cp.z + 0.25
	elseif pos.z < cp.z - 0.25 then
		r.z = cp.z - 0.25
	end
	
	return r
end

-- Dropar itens de um inventario
macroloja.drop_inventory = function(pos, inv, name)
	if not inv or not pos or not name then return false end
	
	local size = inv:get_size(name)
	
	for i = 1, size, 1 do
		local item = inv:get_stack(name, i)
		
		if item ~= nil then
			local pd = {x = pos.x + (math.random(1, 60)/100)*2-0.6, y = pos.y+0.5, z = pos.z + (math.random(1, 60)/100)*2-0.6}
			if minetest.get_node(pd).name ~= "air" then
				pd = {x = pos.x + (math.random(1, 30)/100)*2-0.3, y = pos.y+0.5, z = pos.z + (math.random(1, 30)/100)*2-0.3}
			end
			
			minetest.add_item(puxar_centro(pd), item)
			inv:set_stack(name, i, "")
		end
	end
		
end
