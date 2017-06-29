--[[
	Mod MacroLoja para Minetest
	Copyright (C) 2017 BrunoMine (https://github.com/BrunoMine)
	
	Recebeste uma cópia da GNU Lesser General
	Public License junto com esse software,
	se não, veja em <http://www.gnu.org/licenses/>. 
	
	Bau de trocas
  ]]



-- Controle de bau acessado
local acesso_bau = {}
-- Remove valor quando jogador sair
minetest.register_on_leaveplayer(function(player)
	acesso_bau[player:get_player_name()] = nil
end)

-- Tocar som de troca feita
local tocar_som_troca = function(pos)
	minetest.sound_play("macroloja_troca", {
		pos = pos,
		max_hear_distance = 5,
		gain = 1.0,
	})
end


-- Trocar
--[[
	Retorna nil caso os dados sejam invalidos
	Retorna 1 quando tudo deu certo
	Retorna 2 quando o vendedor esta lotado
	Retorna 3 quando o vendedor nao tem mais estoque
	Retorna 4 quando o jogador esta lotado
	Retorna 5 quando o jogador nao consegue pagar
  ]]
local trocar = function(inv_comprador, list_pagante, list_recebedor, inv_vendedor, list_estoque, list_lucro, list_custo, list_oferta)
	
	-- Ajustar tabelas
	local tb_custo = {}
	local tb_oferta = {}
	for i=1, 4, 1 do
		local item = inv_vendedor:get_stack(list_custo, i)
		if item:get_name() ~= "" then
			if not tb_custo[item:get_name()] then
				tb_custo[item:get_name()] = item:get_count()
			else
				tb_custo[item:get_name()] = tb_custo[item:get_name()] + item:get_count()
			end
		end
	end
	for i=1, 4, 1 do
		local item = inv_vendedor:get_stack(list_oferta, i)
		if item:get_name() ~= "" then
			if not tb_oferta[item:get_name()] then
				tb_oferta[item:get_name()] = item:get_count()
			else
				tb_oferta[item:get_name()] = tb_oferta[item:get_name()] + item:get_count()
			end
		end
	end
	
	-- Verificar se vendedor consegue vender
	-- Verifica se vendedor possui estoque
	for item, qtd in pairs(tb_oferta) do
		if inv_vendedor:contains_item(list_estoque, item.." "..qtd) == false then
			return 3
		end
	end
	-- Verifica se vendedor esta lotado
	for item, qtd in pairs(tb_custo) do
		if inv_vendedor:room_for_item(list_lucro, item.." "..qtd) == false then
			return 2
		end
	end
	
	-- Veriica se o comprador consegue comprar
	-- Verifica se comprador consegue pagar
	for item, qtd in pairs(tb_custo) do
		if inv_comprador:contains_item(list_pagante, item.." "..qtd) == false then
			return 5
		end
	end
	-- Verifica se comprador esta lotado
	for item, qtd in pairs(tb_oferta) do
		if inv_comprador:room_for_item(list_recebedor, item.." "..qtd) == false then
			return 4
		end
	end
	
	-- Realiza a troca
	-- Retira itens do comprador e passa para o vendedor
	for item, qtd in pairs(tb_custo) do
		-- Retira itens do comprador
		inv_comprador:remove_item(list_pagante, item.." "..qtd)
		-- Adiciona itens ao vendedor
		inv_vendedor:add_item(list_lucro, item.." "..qtd)
	end
	-- Retira itens do vendedor e passa para o comprador
	for item, qtd in pairs(tb_oferta) do
		-- Retira itens do vendedor
		inv_vendedor:remove_item(list_estoque, item.." "..qtd)
		-- Adiciona itens ao comprador
		inv_comprador:add_item(list_recebedor, item.." "..qtd)
	end
	
	return 1

end

-- Verificar se bau pode estar ativo
local verif_bau_ativo = function(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	
	-- Zerar numero de vendas
	meta:set_float("vendas", 0)
	
	-- Verifica se um dos dois esta vazio
	if inv:is_empty("oferta") == true or inv:is_empty("custo") == true then 
		meta:set_string("status", "inativo")
		return
	end
	
	-- Verifica cada um dos itens de oferta
	for i=1, 4, 1 do
		local item = inv:get_stack("oferta", i)
		if item:get_wear() ~= 0 or item:get_metadata() ~= "" then
			meta:set_string("status", "inativo")
			return
		end
	end
	-- Verifica cada um dos itens de custo
	for i=1, 4, 1 do
		local item = inv:get_stack("custo", i)
		if item:get_wear() ~= 0 or item:get_metadata() ~= "" then
			meta:set_string("status", "inativo")
			return
		end
	end
	
	-- Ativa o bau para vendas
	meta:set_string("status", "ativo")
	
end

-- Bau de venda
minetest.register_node("macroloja:shop", {

	description = "Bau de Venda",
	paramtype2 = "facedir",
	tiles = {
		"default_chest_top.png",
		"default_chest_top.png^macroloja_shop_top.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_front.png",
		"default_chest_inside.png^macroloja_shop_front.png"
	},
	tiles = {
		"default_chest_top.png^macroloja_shop_top.png",
                "default_chest_top.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_front.png^macroloja_shop_front.png"
	},
	groups = {choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	
	
	can_dig = function(pos, player)
		if player:get_player_name() == minetest.get_meta(pos):get_string("dono") 
			or minetest.check_player_privs(player:get_player_name(), {protection_bypass=true})
		then
			return true
		else
			return false
		end
	end,
	
	after_place_node = function(pos, placer, itemstack)
	
		-- Salvar metadados iniciais
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Bau de Venda (Vendedor "..placer:get_player_name()..")")
		meta:set_string("dono", placer:get_player_name())
		meta:set_string("status", "inativo")
		meta:set_float("vendas", 0)
		
		-- Inventarios do bau
		local inv = meta:get_inventory()
		inv:set_size("oferta", 4*1)
		inv:set_size("custo", 4*1)
		inv:set_size("estoque", 2*4)
		inv:set_size("lucro", 2*4)
		
	end,
	
	on_rightclick = function(pos, node, clicker, itemstack)
		
		local name = clicker:get_player_name()
		local meta = minetest.get_meta(pos)
		
		-- Armazena o bau acessado
		acesso_bau[name] = pos
		
		-- Acesso do dono
		if name == minetest.get_meta(pos):get_string("dono") 
			or minetest.check_player_privs(name, {protection_bypass=true})
		then
			
			-- Exibe formspec
			minetest.show_formspec(name, "macroloja:shop_dono", 
				"size[10,9]"
				
				-- Inventario do jogador
				..default.gui_bg
				..default.gui_bg_img
				..default.gui_slots
				.."list[current_player;main;1,4.85;8,1;]"
				.."list[current_player;main;1,6.08;8,3;8]"
				.."listring[current_player;main]"
				..default.get_hotbar_bg(1,4.85)
				
				-- Estoque
				.."label[0,-0.1;Estoque]"
				.."list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";estoque;0,0.3;2,4;]"
				.."listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";estoque]"
				
				-- Lucro
				.."label[8,-0.1;Lucro]"
				.."list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";lucro;8,0.3;2,4;]"
				.."listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";lucro]"
				
				-- Oferta
				.."label[3,0.3;Oferta]"
				.."list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";oferta;3,0.8;4,1;]"
				.."listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";oferta]"
				.."image[2,0.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"
				
				-- Custo
				.."label[3,2.3;Custo]"
				.."list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";custo;3,2.8;4,1;]"
				.."listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";custo]"
				.."image[7,2.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"
				
				-- Seta pra baixo
				.."image[4.5,1.8;1,1;gui_furnace_arrow_bg.png^[transformR180]"
				
				-- Trocas feitas
				.."label[3,3.8;Vendas feitas: "..meta:get_float("vendas").."]"
				
				-- Botoes de troca rapida [CANCELADOS]
				--.."image_button[0,4.3;1,1;macroloja_bt_fast_up.png;reabastecer;]"
				--.."image_button[9,4.3;1,1;macroloja_bt_fast_down.png;receber;]"
				
			)
			
			return
		end
		
		-- Exibe formspec
		minetest.show_formspec(name, "macroloja:shop", 
			"size[8,9]"
			
			-- Inventario do jogador
			..default.gui_bg
			..default.gui_bg_img
			..default.gui_slots
			.."list[current_player;main;0,4.85;8,1;]"
			.."list[current_player;main;0,6.08;8,3;8]"
			.."listring[current_player;main]"
			..default.get_hotbar_bg(0,4.85)
			
			-- Custo
			.."label[2,0.3;Custo]"
			.."list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";custo;2,0.8;4,1;]"
			.."listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";custo]"
			
			-- Oferta
			.."label[2,2.8;Oferta]"
			.."list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";oferta;2,3.3;4,1;]"
			.."listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";oferta]"
			
			-- Seta pra baixo
			.."image[2,1.8;1,1;gui_furnace_arrow_bg.png^[transformR180]"
			
			-- Botão de troca
			.."button[3,1.8;2,1;trocar;Comprar]"
			
			-- Botoes de troca rapida
			.."image_button[5,1.8;1,1;macroloja_bt_fast_down.png;trocar10x;10x]"
			
		)
		
	end,
	
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		
		-- Dropar itens
		macroloja.drop_inventory(pos, inv, "estoque")
		macroloja.drop_inventory(pos, inv, "oferta")
		macroloja.drop_inventory(pos, inv, "custo")
		macroloja.drop_inventory(pos, inv, "lucro")
		
	end,
	
	-- Verificar permissão de acesso ao bau
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if player:get_player_name() == minetest.get_meta(pos):get_string("dono") 
			or minetest.check_player_privs(player:get_player_name(), {protection_bypass=true})
		then return count else return 0 end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if player:get_player_name() == minetest.get_meta(pos):get_string("dono") 
			or minetest.check_player_privs(player:get_player_name(), {protection_bypass=true})
		then return stack:get_count() else return 0 end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if player:get_player_name() == minetest.get_meta(pos):get_string("dono") 
			or minetest.check_player_privs(player:get_player_name(), {protection_bypass=true})
		then return stack:get_count() else return 0 end
	end,
	
	-- Verificar se mudança no inventario permite ativar trocas
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if from_list == "oferta" or from_list == "custo" 
			or to_list == "oferta" or to_list == "custo"
		then verif_bau_ativo(pos) end
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "custo" or listname == "oferta" then verif_bau_ativo(pos) end
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "custo" or listname == "oferta" then verif_bau_ativo(pos) end
	end,
})


minetest.register_on_player_receive_fields(function(player, formname, fields)
	
	-- Clientes
	if formname == "macroloja:shop" then
		local name = player:get_player_name()
		local pos = acesso_bau[name]
		local meta = minetest.get_meta(pos)
		
		
		-- Troca 
		if fields.trocar and meta:get_string("status") == "ativo" then
			
			-- Tentativa de troca
			local troca = trocar(player:get_inventory(), "main", "main", meta:get_inventory(), "estoque", "lucro", "custo", "oferta")
			
			if troca == 2 then
				minetest.chat_send_player(name, "Bau com problemas de estoque. Aguarde o vendedor verificar.")
			elseif troca == 3 then
				minetest.chat_send_player(name, "Bau com problemas de estoque. Aguarde o vendedor verificar.")
			elseif troca == 4 then
				minetest.chat_send_player(name, "Inventario lotado. Esvazie um pouco seu inventario.")
			elseif troca == 5 then
				minetest.chat_send_player(name, "Itens insuficientes para pagar pela compra.")
			end
			
			if troca == 1 then
			
				meta:set_float("vendas", meta:get_float("vendas") + 1)
			
				-- Tocar som de troca feita
				tocar_som_troca(pos)
			
			end
			
			return
			
		elseif fields.trocar10x then
			
			-- Tentativa de primeira troca
			local troca = trocar(player:get_inventory(), "main", "main", meta:get_inventory(), "estoque", "lucro", "custo", "oferta")
						
			if troca == 2 then
				minetest.chat_send_player(name, "Bau com problemas de estoque. Aguarde o vendedor verificar.")
			elseif troca == 3 then
				minetest.chat_send_player(name, "Bau com problemas de estoque. Aguarde o vendedor verificar.")
			elseif troca == 4 then
				minetest.chat_send_player(name, "Inventario lotado. Esvazie um pouco seu inventario.")
			elseif troca == 5 then
				minetest.chat_send_player(name, "Itens insuficientes para pagar pela compra.")
			end
			
			if troca == 1 then
			
				meta:set_float("vendas", meta:get_float("vendas") + 1)
			
				-- Tocar som de troca feita
				tocar_som_troca(pos)
				
				-- Tenta trocar mais 9
				do
					local i = 0
					while i < 9 
						and trocar(player:get_inventory(), "main", "main", meta:get_inventory(), "estoque", "lucro", "custo", "oferta") == 1
					do
						meta:set_float("vendas", meta:get_float("vendas") + 1)
						i = i + 1
					end
				end
			
			end
			
			-- Tocar som de troca feita
			tocar_som_troca(pos)
			
			return
			
		elseif fields.quit then
		
			return
			
		-- Nenhum botao valido ate aqui
		else
			minetest.chat_send_player(name, "Bau de venda inativo")
		end
	end
end)

-- Bau de Venda
minetest.register_craft({
	output = 'macroloja:shop',
	recipe = {
		{'wool:green', 'wool:white', 'wool:green'},
		{'wool:blue', 'default:chest_locked', 'wool:blue'},
		{'default:wood', 'default:wood', 'default:wood'},
	}
})

