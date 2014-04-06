hud = {}

-- HUD statbar values
hud.health = {}
hud.hunger = {}
hud.air = {}
hud.armor = {}
hud.hunger_out = {}
hud.armor_out = {}

-- HUD item ids
local health_hud = {}
local hunger_hud = {}
local air_hud = {}
local armor_hud = {}

local SAVE_INTERVAL = 0.5*60--currently useless

--default settings
HUD_ENABLE_HUNGER = minetest.setting_getbool("hud_hunger_enable")
HUD_SHOW_ARMOR = false
if minetest.get_modpath("3d_armor") ~= nil then HUD_SHOW_ARMOR = true end
if HUD_ENABLE_HUNGER == nil then HUD_ENABLE_HUNGER = minetest.setting_getbool("enable_damage") end
HUD_HUNGER_TICK = 300
HUD_HEALTH_POS = {x=0.5,y=0.9}
HUD_HEALTH_OFFSET = {x=-175, y=2}
HUD_HUNGER_POS = {x=0.5,y=0.9}
HUD_HUNGER_OFFSET = {x=15, y=2}
HUD_AIR_POS = {x=0.5,y=0.9}
HUD_AIR_OFFSET = {x=15,y=-15}
HUD_ARMOR_POS = {x=0.5,y=0.9}
HUD_ARMOR_OFFSET = {x=-175, y=-15}

--load costum settings
local set = io.open(minetest.get_modpath("hud").."/hud.conf", "r")
if set then 
	dofile(minetest.get_modpath("hud").."/hud.conf")
	set:close()
else
	if not HUD_ENABLE_HUNGER then
		HUD_AIR_OFFSET = {x=15,y=0}
	end
end

--minetest.after(SAVE_INTERVAL, timer, SAVE_INTERVAL)

local function hide_builtin(player)
	 player:hud_set_flags({crosshair = true, hotbar = true, healthbar = false, wielditem = true, breathbar = false})
end


local function costum_hud(player)

 --fancy hotbar
 player:hud_set_hotbar_image("hud_hotbar.png")
 player:hud_set_hotbar_selected_image("hud_hotbar_selected.png")

 if minetest.setting_getbool("enable_damage") then
 --hunger
	if HUD_ENABLE_HUNGER then
       	 player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_HUNGER_POS,
		scale = {x=1, y=1},
		text = "hud_hunger_bg.png",
		number = 20,
		alignment = {x=-1,y=-1},
		offset = HUD_HUNGER_OFFSET,
	 })

	 hunger_hud[player:get_player_name()] = player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_HUNGER_POS,
		scale = {x=1, y=1},
		text = "hud_hunger_fg.png",
		number = 20,
		alignment = {x=-1,y=-1},
		offset = HUD_HUNGER_OFFSET,
	 })
	end
 --health
        player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_HEALTH_POS,
		scale = {x=1, y=1},
		text = "hud_heart_bg.png",
		number = 20,
		alignment = {x=-1,y=-1},
		offset = HUD_HEALTH_OFFSET,
	})

	health_hud[player:get_player_name()] = player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_HEALTH_POS,
		scale = {x=1, y=1},
		text = "hud_heart_fg.png",
		number = player:get_hp(),
		alignment = {x=-1,y=-1},
		offset = HUD_HEALTH_OFFSET,
	})

 --air
	air_hud[player:get_player_name()] = player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_AIR_POS,
		scale = {x=1, y=1},
		text = "hud_air_fg.png",
		number = 0,
		alignment = {x=-1,y=-1},
		offset = HUD_AIR_OFFSET,
	})

 --armor
 if HUD_SHOW_ARMOR then
       player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_ARMOR_POS,
		scale = {x=1, y=1},
		text = "hud_armor_bg.png",
		number = 20,
		alignment = {x=-1,y=-1},
		offset = HUD_ARMOR_OFFSET,
	})

	armor_hud[player:get_player_name()] = player:hud_add({
		hud_elem_type = "statbar",
		position = HUD_ARMOR_POS,
		scale = {x=1, y=1},
		text = "hud_armor_fg.png",
		number = 0,
		alignment = {x=-1,y=-1},
		offset = HUD_ARMOR_OFFSET,
	})
  end
 end

end

--needs to be defined for older version of 3darmor
function hud.set_armor()
end


if HUD_ENABLE_HUNGER then dofile(minetest.get_modpath("hud").."/hunger.lua") end
if HUD_SHOW_ARMOR then dofile(minetest.get_modpath("hud").."/armor.lua") end

-- update hud elemtens if value has changed
local function update_hud(player)
	local name = player:get_player_name()
 --air
	local air = tonumber(hud.air[name])
	if player:get_breath() ~= air then
		air = player:get_breath()
		hud.air[name] = air
		if air > 10 then air = 0 end
		player:hud_change(air_hud[name], "number", air*2)
	end
 --health
	local hp = tonumber(hud.health[name])
	if player:get_hp() ~= hp then
		hp = player:get_hp()
		hud.health[name] = hp
		player:hud_change(health_hud[name], "number", hp)
	end
 --armor
	local arm_out = tonumber(hud.armor_out[name])
	if not arm_out then arm_out = 0 end
	local arm = tonumber(hud.armor[name])
	if not arm then arm = 0 end
	if arm_out ~= arm then
		hud.armor_out[name] = arm
		player:hud_change(armor_hud[name], "number", arm)
	end
 --hunger
	local h_out = tonumber(hud.hunger_out[name])
	local h = tonumber(hud.hunger[name])
	if h_out ~= h then
		hud.hunger_out[name] = h
		-- bar should not have more than 10 icons
		if h>20 then h=20 end
		player:hud_change(hunger_hud[name], "number", h)
	end
end

local function timer(interval, player)
	if interval > 0 then
		hud.save_hunger(player)
		minetest.after(interval, timer, interval, player)
	end
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	hud.health[name] = player:get_hp()
	local air = player:get_breath()
	hud.air[name] = air
	if HUD_ENABLE_HUNGER then hud.hunger[name] = hud.load_hunger(player) end
	if not hud.hunger[name] then
		hud.hunger[name] = 20
	end
	hud.hunger_out[name] = hud.hunger[name]
	hud.armor[name] = 0
	hud.armor_out[name] = 0
	minetest.after(0.5, function()
		hide_builtin(player)
		costum_hud(player)
		if HUD_ENABLE_HUNGER then hud.save_hunger(player) end
	end)
end)

minetest.register_on_respawnplayer(function(player)
	hud.hunger[player:get_player_name()] = 20
	minetest.after(0.5, function()
		if HUD_ENABLE_HUNGER then hud.save_hunger(player) end
	end)
end)

local timer = 0
local timer2 = 0
minetest.after(2.5, function()
	minetest.register_globalstep(function(dtime)
	 timer = timer + dtime
	 timer2 = timer2 + dtime
		for _,player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()

			-- only proceed if damage is enabled
			if minetest.setting_getbool("enable_damage") then
			 local h = tonumber(hud.hunger[name])
			 local hp = player:get_hp()
			 if HUD_ENABLE_HUNGER and timer > 4 then
				-- heal player by 1 hp if not dead and saturation is > 15 (of 30)
				if h > 15 and hp > 0 then
					player:set_hp(hp+1)
				-- or damage player by 1 hp if saturation is < 2 (of 30) and player would not die
				elseif h <= 1 and minetest.setting_getbool("enable_damage") then
					if hp-1 >= 1 then player:set_hp(hp-1) end
				end
			 end
			 -- lower saturation by 1 point after xx seconds
			 if HUD_ENABLE_HUNGER and timer2 > HUD_HUNGER_TICK then
				if h > 1 then
					h = h-1
					hud.hunger[name] = h
					hud.save_hunger(player)
				end
			 end
			 -- update current armor level
			 if HUD_SHOW_ARMOR then hud.get_armor(player) end

			 -- update all hud elements
			 update_hud(player)
			end
		end
		
		if timer > 4 then timer = 0 end
		if timer2 > HUD_HUNGER_TICK then timer2 = 0 end
	end)
end)
