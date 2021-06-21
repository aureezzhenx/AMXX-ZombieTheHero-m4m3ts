#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <xs>
#include <fun>
#include <engine>
#include <zombieplague>
#include <dhudmessage>
#include <m4m3tsunlock>
#include <hamsandwich>

#define PLUGIN	"[ZP] CSO Addon : The Hero"
#define VERSION	"1.3"
#define AUTHOR	"ShuriK"

new menu1
new g_hero[33] , g_iMaxClients ;
new spr_current[33] = {0,...}
new time_show_set[33] = {0,...}
new iconstatus, time_show = 3
new index_hero,index_heroine, hero_sprr, cvar_minpeople

new timer_sidekick, timer_weapon_hero
new g_pilih_senjata[33]

new g_sidekick[33]
new Float:g_fDelay[33]
	

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_PlayerPreThink,"check_spr")
	
	register_clcmd("drop", "BlockDrop")
	register_touch("weaponbox", "player", "BlockPickup");
	register_touch("armoury_entity", "player", "BlockPickup");
	register_touch("weapon_shield", "player", "BlockPickup");
	RegisterHam(Ham_Spawn, "player", "fw_Playerspawn", 1)
	
	cvar_minpeople = register_cvar("zp_hero_minimal_player", "6")
	iconstatus = get_user_msgid("StatusIcon")
	g_iMaxClients = get_maxplayers( );
}

public plugin_precache()
{
	index_hero = precache_model("models/player/komplit_hero/komplit_hero.mdl")
	index_heroine = precache_model("models/player/komplit_heroine/komplit_heroine.mdl")
	hero_sprr = precache_model("sprites/zb_hero.spr")
}

public plugin_natives()
{
	register_native("revo_get_user_hero", "native_revo_get_user_hero", 1)
	register_native("revo_get_user_sidekick", "native_revo_get_user_sidekick", 1)	

	register_native("make_hero", "native_hero", 1)
}

public BlockDrop(id)
{
	if(g_hero[id] || g_sidekick[id])
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE
}

public BlockPickup(weapon, id)
{
	if(g_hero[id] || g_sidekick[id])
		return PLUGIN_HANDLED;
 
	return PLUGIN_CONTINUE;
}

public fw_Playerspawn(id)
{
	if(!zp_get_user_zombie(id))
	{
		g_pilih_senjata[id] = false
		g_sidekick[id] = false
		g_hero[id] = false
	}
}

public native_revo_get_user_sidekick(id)
{
	return g_sidekick[id];
}

public native_revo_get_user_hero(id)
{
	return g_hero[id];
}

public native_hero(id)
{
	make_hero(id)
}

public zp_round_started(round, id)
{
	if (zp_get_human_count() < get_pcvar_num(cvar_minpeople))
		return;
			
	if(round == MODE_MULTI || round == MODE_INFECTION)
	{
		set_task(0.5,"make_hero")
		set_task(0.6,"make_sidekick")
	}
}

public zp_user_infected_post(id)
{
	g_hero[id] = false
	g_sidekick[id] = false
}


public make_sidekick(id)
{		   	
	new id
	static iPlayersNum
	iPlayersNum = gAlive()

	id = gRandomAlive(random_num(1, iPlayersNum))
		
	g_sidekick[id] = true
	destroy_menu(id)
	
	timer_sidekick = 6
	set_task(0.2, "sidekickweapon", id)
	set_task(0.5, "sidekickinfo", id)
	
	zp_override_user_model(id, "komplit_heroine")
	set_pdata_int(id, 491, index_heroine, 5)
	
	if(is_user_bot(id))
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("CV-47 60R"), 1)
	}
	
	emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"))
	ewrite_byte(id) // id
	ewrite_byte(4) // attrib
	emessage_end()
	
	return PLUGIN_CONTINUE
}

public make_hero(id)
{			
	new id
	static iPlayersNum
	iPlayersNum = gAlive()
	
	id = gRandomAlive(random_num(1, iPlayersNum))
		
	g_hero[id] = true
	destroy_menu(id)
	
	timer_weapon_hero = 8
	set_task(0.2, "heroweapon", id)
	set_task(0.5, "hero_weapon_timer", id)
	
	if(is_user_bot(id))
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("svdex"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Dual Deagle"), 1)
	}
	
	zp_override_user_model(id, "komplit_hero")
	set_pdata_int(id, 491, index_hero, 5)
	
	set_task(0.101, "hero_sprites", id)
	
	client_cmd(1, "spk zombie_plague/cso/becoming_hero")
	
	emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"))
	ewrite_byte(id) // id
	ewrite_byte(4) // attrib
	emessage_end()
	
	return PLUGIN_CONTINUE
}

public heroweapon(id)   
{   	
	new buffer[512]
	
	if(!is_user_alive(id) && zp_get_user_zombie(id))
		return PLUGIN_HANDLED;
	
	menu1 = menu_create("\r[ YOU ARE HERO! ] \ySelect Your Weapon!", "primary_weapon")  
	
	formatex(buffer, charsmax(buffer), "\wSVDEX Launcher")
	menu_additem(menu1, buffer, "1")
	
	formatex(buffer, charsmax(buffer), "\wDual Kriss Special")
	menu_additem(menu1, buffer, "2")
	
	formatex(buffer, charsmax(buffer), "\wM134 Vulcan")
	menu_additem(menu1, buffer, "3")
	
	formatex(buffer, charsmax(buffer), "\wQuad Barrel")
	menu_additem(menu1, buffer, "4")
	
 
	menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu1, 0) 
	return PLUGIN_HANDLED   
}   

public primary_weapon(id, menu1, item)   
{   
	if(item == MENU_EXIT)   
	{   
		menu_destroy(menu1)   
		return PLUGIN_HANDLED;   
	}  
	
	new data[15], iName[64]    
	new access, callback   
	menu_item_getinfo(menu1, item, access, data,15, iName, 64, callback);
	
	new key = str_to_num(data)   
	switch(key)   
	{   
		case 1:
		{
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("svdex"), 1)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("Dual Deagle"), 1)
		}   
		case 2:
		{
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("Dual Kriss Hero"), 1)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("Dual Deagle"), 1)
		}   
		case 3:
		{
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("M134 Vulcan"), 1)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("Dual Deagle"), 1)
		}   
		case 4:
		{
			drop_weapons(id, 1)
			drop_weapons(id, 2)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("Quad Barrel"), 1)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("Dual Deagle"), 1)
		}   
	}   
	
	menu_destroy(menu1)   
	return PLUGIN_HANDLED;   
}   

public sidekickweapon(id)   
{   	
	new buffer[512]
	
	if(!is_user_alive(id) && zp_get_user_zombie(id))
		return PLUGIN_HANDLED;

	menu1 = menu_create("\r[ YOU ARE SIDEKICK! ] \ySelect Your Weapon!", "sidekick_weapon")  
	
	formatex(buffer, charsmax(buffer), "\wCV47 - 60R")
	menu_additem(menu1, buffer, "1")
	
	formatex(buffer, charsmax(buffer), "\wDual MP7 A1")
	menu_additem(menu1, buffer, "2")
	
	formatex(buffer, charsmax(buffer), "\wDual Deagle")
	menu_additem(menu1, buffer, "3")

	menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
	
	menu_display(id, menu1, 0) 
	return PLUGIN_HANDLED   
}   

public sidekick_weapon(id, menu1, item)   
{   
	if(item == MENU_EXIT)   
	{   
		menu_destroy(menu1)   
		return PLUGIN_HANDLED;   
	}  
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	new data[15], iName[64]    
	new access, callback   
	menu_item_getinfo(menu1, item, access, data,15, iName, 64, callback);
	
	new key = str_to_num(data)   
	switch(key)   
	{   
		case 1:
		{
			drop_weapons(id, 1)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("CV-47 60R"), 1)
			
		}
		case 2:
		{
			drop_weapons(id, 1)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("Dual MP7"), 1)
		}   
		case 3:
		{
			drop_weapons(id, 2)
			zp_force_buy_extra_item( id, zp_get_extra_item_id("Dual Deagle"), 1)
		}
	}
	
	menu_destroy(menu1)
	return PLUGIN_HANDLED;   
}   

public zp_round_ended()
{
	static id;

	for( id = 1; id <= g_iMaxClients; id++ )
	{
		if( !is_user_connected( id ) || !g_hero[ id ] )
			continue;

		g_hero[id] = false
		g_sidekick[id] = false
	}
}

public hero_sprites(id) show_spr(id, 1)
public show_spr(id, idsprs)
{
	new sec_c = get_systime()
	time_show_set[id] = sec_c

	hide_spr(id, spr_current[id])
	spr_current[id] = idsprs
	
	new spr_names[33]
	if (idsprs==1) spr_names = "hero"

	message_begin(MSG_ONE,iconstatus,{0,0,0},id);
	write_byte(1); // status (0=hide, 1=show, 2=flash)
	write_string(spr_names); // sprite name
	message_end();
} 

public hide_spr(id, idsprs)
{
	new spr_names[33]
	if (idsprs==1) spr_names = "hero"
	   
	message_begin(MSG_ONE,iconstatus,{0,0,0},id);
	write_byte(0); // status (0=hide, 1=show, 2=flash)
	write_string(spr_names); // sprite name
	message_end();
	spr_current[id] = 0
}  

public check_spr(id)
{
	new idsprs = spr_current[id]
	if (idsprs > 0)
	{
		new sec_c = get_systime()
		new time_check = sec_c - time_show_set[id]
		if (time_check>time_show) hide_spr(id, idsprs)
	}

	return PLUGIN_CONTINUE
}

public sidekickinfo(id)
{
	if(timer_sidekick > 0 && !g_pilih_senjata[id])
	{
		client_print(id, print_center, "Remaining Time For Choose Weapons: %i Second(s)", timer_sidekick)
		
		timer_sidekick-- 
		set_task(1.0, "sidekickinfo", id)
	}
	else if(timer_sidekick < 1)
	{
		destroy_menu(id)
	}
}

public hero_weapon_timer(id)
{
	if(timer_weapon_hero > 0 && !g_pilih_senjata[id])
	{
		client_print(id, print_center, "Remaining Time For Choose Weapons: %i Second(s)", timer_weapon_hero)

		timer_weapon_hero--
		set_task(1.0, "hero_weapon_timer", id)
	}
	else if(timer_weapon_hero < 1)
	{
		destroy_menu(id)
	}
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
		
	if(g_fDelay[id] + 0.01 > get_gametime())
		return PLUGIN_CONTINUE;
	
	g_fDelay[id] = get_gametime()
	
	new Float:fMyOrigin[3]
	entity_get_vector(id, EV_VEC_origin, fMyOrigin)
	
	static Players[32], iNum
	get_players(Players, iNum, "a")
	for(new i = 0; i < iNum; ++i)
	{
		if(id != Players[i])
		{
			new target = Players[i]
			
			if(!g_hero[target]) 
				continue
				
			new Float:fTargetOrigin[3]
			entity_get_vector(target, EV_VEC_origin, fTargetOrigin)
			
			if(get_distance_f(fMyOrigin, fTargetOrigin) > 6000 || !is_in_viewcone(id, fTargetOrigin))
				continue
	
			new Float:fMiddle[3], Float:fHitPoint[3]
			xs_vec_sub(fTargetOrigin, fMyOrigin, fMiddle)
			trace_line(-1, fMyOrigin, fTargetOrigin, fHitPoint)
									
			new Float:fWallOffset[3], Float:fDistanceToWall
			fDistanceToWall = vector_distance(fMyOrigin, fHitPoint) - 10.0
			normalize(fMiddle, fWallOffset, fDistanceToWall)
			
			new Float:fSpriteOffset[3]
			xs_vec_add(fWallOffset, fMyOrigin, fSpriteOffset)
			new Float:fScale, Float:fDistanceToTarget = vector_distance(fMyOrigin, fTargetOrigin)
			if(fDistanceToWall > 100.0)
			{
				fScale = 5.0 * (fDistanceToWall / fDistanceToTarget)
			}
			else
			{
			fScale = 1.0
			}
			
			te_sprite(id, fSpriteOffset, hero_sprr, floatround(fScale), 100)
			
		}
	}
	return PLUGIN_CONTINUE
}
	
gRandomAlive(n)
{
	static Alive, id
	Alive = 0
	
	for (id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_alive(id) && !zp_get_user_zombie(id) && !g_hero[id])
			Alive++
		
		if (Alive == n)
			return id;
	}
	
	return -1;
}

gAlive()
{
	static Alive, id
	Alive = 0
	
	for (id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_alive(id) && !zp_get_user_zombie(id) && !g_hero[id])
			Alive++
	}
	
	return Alive;
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	 
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		  
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
		
		if (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			
			engclient_cmd(id, "drop", wname)
		}
	}
}
stock te_sprite(id, Float:origin[3], sprite, scale, brightness)
{
	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]+40))
	write_short(sprite)
	write_byte(scale) 
	write_byte(brightness)
	message_end()
}

stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul) 
{ 
    new Float:fLen = xs_vec_len(fIn) 
    xs_vec_copy(fIn, fOut) 

    fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen 
    fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul 
}
