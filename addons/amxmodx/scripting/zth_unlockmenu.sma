/// Main Header ///

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <amxmisc>
#include <zombieplague>
#include <zth_money>

/// ZB Header ///
#include <zth_tank>
#include <zth_pc>
#include <zth_zbgrenade>
#include <zth_deimos>
#include <zth_banshee>
#include <zth_speed>
#include <zth_venom>
#include <zth_sting>
#include <zth_stamper>
#include <zth_znoidzombie> // METRATRONIC & LILITH CLASS

/// HM Header ///
#include <zth_refol>
#include <zth_humanskill>
#include <zth_plasma>
#include <zth_nata>
#include <zth_sk4>
#include <zth_dif>
#include <zth_thanatos9>
#include <zth_skull9>
#include <zth_dragonsword>
#include <zth_balrog1>
#include <zth_buffweapon>
#include <zth_lightsaber>
#include <zth_balrog11>
#include <zth_cannon>
#include <zth_coilgun>
#include <zth_janus5>
#include <zth_skull5>
#include <zth_brickv2>
#include <zth_drill>
#include <zth_vandita>
#include <zth_thunderbolt>
#include <zth_thanatos5>
#include <zth_speargun>
#include <zth_balrog9>
#include <zth_janus1>

/////////// WEAPON LIMIT CUSTOMIZE /////////
#define STOK_THANATOSS9 3
#define STOK_BALROG11 3
#define STOK_BLOCKAR 3
#define STOK_DRILL 3
////////////////////////////////////////////
#define PLUGIN "Unlockzthaureezz"
#define VERSION "1.0"
#define AUTHOR "m4m3ts"
 
#define TASK_NOL 2085

const PDATA_SAFE = 2
const OFFSET_CSTEAMS = 114
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds

enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}

new menu1 
new can_choose[33]

new g_zombie_class[33]
new g_ZB_class[33]
new timer, p_grav

new iWeapprim[ 33 ]
new iWeapsec[ 33 ]
new iWeapmelee[ 33 ]

new zbcanbuys[33]
new havegravity[33]

new p_dmg_multiplier

// Vars cost Weapon HM
new p_plasma, p_hmgrnd, p_nghtvsion, p_deadly, p_jump, p_bloody, p_sprint, p_dam,
p_ammo, p_nata, p_sk4, p_dif, p_tn9, p_sk9, p_drgswrd, p_bl11, p_coil, p_janus5,
p_sk5, p_brickv2, p_drill, p_vandita, p_thunderbolt, p_tn5, p_spear, p_bl9,
p_janus1

// Vars Weapon HM Unlocked
new plasmaunlocked[33]
new jumpunlocked[33]
new grnadehmunlocked[33]
new nghtvisionunlocked[33]
new deadlyunlocked[33]
new bloodyunlocked[33]
new sprintunlocked[33]
new damunlocked[33]
new dam[33]
new ammounlocked[33]
new nataunlocked[33]
new tn9unlocked[33]
new sk4unlocked[33]
new difunlocked[33]
new sk9unlocked[33]
new drgswrdunlocked[33]
new paladinunlocked[33]
new dkunlocked[33]
new bl11unlocked[33]
new cannonunlocked[33]
new coilunlocked[33]
new janus5unlocked[33]
new sk5unlocked[33]
new brickv2unlocked[33]
new drillunlocked[33]
new vanditaunlocked[33]
new thunderboltunlocked[33]
new tn5unlocked[33]
new spearunlocked[33]
new bl9unlocked[33]
new janus1unlocked[33]

// Vars Limit Weapon (Prim,Sec,Melee) Human 
new stok_thanatos9, stok_balrog11, stok_blockar, stok_drill

// ExtraItems Zombie
new zbgrnadeunlocked[33]
new incrshpunlocked[33]

// Vars cost extraitemb zb
new p_zbgr, p_incrshp

// Vars zombie class cost
new p_deimos, p_vodo, p_light, p_banshe, p_stamper, p_sting, p_lilith, p_meta

// Vars zombie class unlocked
new deimosunlocked[33]
new vodounlocked[33]
new lightunlocked[33]
new bansheunlocked[33]
new stamperunlocked[33]
new stingunlocked[33]
new lilithunlocked[33]
new metaunlocked[33]

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

new const sound_cash[] = "zombie_plague/cash.wav"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
		
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack")
	
	register_clcmd("chooseteam", "clcmd_changeteam")
	register_clcmd("jointeam", "clcmd_changeteam")
	
	p_grav = register_cvar("gravity", "0.75")
	p_dmg_multiplier = register_cvar("dmg_multiplier", "1.3")
	
	// COST HM TO UNLOCKED
	p_plasma = register_cvar("unlock_plasma", "6500")
	p_hmgrnd = register_cvar("unlock_grnade", "3500")
	p_nghtvsion = register_cvar("unlock_nghtvsion", "1000")
	p_deadly = register_cvar("unlock_deadly", "8500")
	p_jump = register_cvar("unlock_jump", "1500")
	p_bloody = register_cvar("unlock_bloody", "4500")
	p_sprint = register_cvar("unlock_sprint", "3000")
	p_dam = register_cvar("unlock_dam", "3000")
	p_ammo = register_cvar("unlock_ammo", "5000")
	p_nata = register_cvar("unlock_nata", "2000")
	p_sk4 = register_cvar("unlock_skull4", "10000")
	p_dif = register_cvar("unlock_dif", "3000")
	p_tn9 = register_cvar("unlock_tn9", "16000")
	p_sk9 = register_cvar("unlock_sk9", "9000")
	p_drgswrd = register_cvar("unlock_dragonsword", "11000")
	p_bl11 = register_cvar("unlock_balrog11blue", "13000")
	p_coil = register_cvar("unlock_coil", "14000")
	p_janus5 = register_cvar("unlock_janus5", "7000")
	p_sk5 = register_cvar("unlock_sk5", "8000")
	p_brickv2 =  register_cvar("unlock_brickpeacev2", "13000")
	p_drill = register_cvar("unlock_magnumdrill", "16000")
	p_vandita = register_cvar("unlock_vandita", "8000")
	p_thunderbolt = register_cvar("unlock_thunderbolt", "8000")
	p_tn5 = register_cvar("unlock_thanatos5", "13000")
	p_spear = register_cvar("unlock_speargun", "11000")
	p_bl9 = register_cvar("unlock_balrog9blue", "5000")
	p_janus1 = register_cvar("unlock_janus1", "3000")
	p_lilith = register_cvar("unlock_lilith", "7000")
	p_meta = register_cvar("unlock_meta", "8500")
	
	// COST ZM TO UNLOCKED
	p_zbgr = register_cvar("unlock_zbgr", "5000")
	p_deimos = register_cvar("unlock_deimos", "2000")
	p_vodo = register_cvar("unlock_venom", "8000")
	p_light = register_cvar("unlock_light", "2500")
	p_deimos = register_cvar("unlock_deimos", "2000")
	p_banshe = register_cvar("unlock_banshe", "13000")
	p_stamper = register_cvar("unlock_sting", "7000")
	p_sting = register_cvar("unlock_stamper", "4500")
	p_incrshp = register_cvar("unlock_incrshp", "4000")
}

public plugin_precache()
{
	precache_sound(sound_cash)
	stok_thanatos9 = STOK_THANATOSS9
	stok_balrog11 = STOK_BALROG11
	stok_blockar = STOK_BLOCKAR
	stok_drill = STOK_DRILL
}

public plugin_natives()
{
	register_native("darahkebuka", "native_get_user_start_health", 1)
	register_native("destroy_menu", "native_destroy_menu", 1)
	register_native("zth_get_zombie_class", "native_zth_get_zombie_class", 1)
	register_native("guns_menu", "native_guns_menu", 1)
	register_native("DisplayMenu", "native_DisplayMenu", 1)
}

public native_get_user_start_health(id)
{
	darahkebuka(id)
}

public native_destroy_menu(id)
{
	destroy_menu(id)
}

public native_zth_get_zombie_class(id)
{
	return g_zombie_class[id];
}

public native_guns_menu(id)
{
	guns_menu(id)
}

public native_DisplayMenu(id)
{
	DisplayMenu(id)
}

public client_connect(id)
{
	iWeapprim[ id ] = 0
	iWeapsec[ id ] = 0
	iWeapmelee[ id ] = 0
	can_choose[id] = 1
	zbcanbuys[id] = true
	
	
	// HM UNLOCKED
	plasmaunlocked[id] = false
	jumpunlocked[id] = false
	nghtvisionunlocked[id] = false
	havegravity[id] = false
	grnadehmunlocked[id] = false
	deadlyunlocked[id] = false
	bloodyunlocked[id] = false
	sprintunlocked[id] = false
	damunlocked[id] = false
	dam[id] = false
	ammounlocked[id] = false
	nataunlocked[id] = false
	tn9unlocked[id] = false
	sk4unlocked[id] = false
	difunlocked[id] = false
	sk9unlocked[id] = false
	drgswrdunlocked[id] = false
	paladinunlocked[id] = false
	dkunlocked[id] = false
	cannonunlocked[id] = false
	bl11unlocked[id] = false
	coilunlocked[id] = false
	janus5unlocked[id] = false
	sk5unlocked[id] = false
	brickv2unlocked[id] = false
	drillunlocked[id] = false
	vanditaunlocked[id] = false
	thunderboltunlocked[id] = false
	tn5unlocked[id] = false
	spearunlocked[id] = false
	bl9unlocked[id] = false
	janus1unlocked[id] = false
	
	// ZB UNLOCKED
	zbgrnadeunlocked[id] = true
	incrshpunlocked[id] = true
	deimosunlocked[id] = false
	vodounlocked[id] = false
	lightunlocked[id] = false
	deimosunlocked[id] = false
	bansheunlocked[id] = false
	stamperunlocked[id] = false
	stingunlocked[id] = false
	lilithunlocked[id] = false
	metaunlocked[id] = false
	
	if(is_user_bot(id)) 
	{
		g_ZB_class[id] = random_num(1,10)
		deadlyunlocked[id] = true
	}
	else 
	{
		g_ZB_class[id] = 1
	}
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, dmgtype)
{
	if(!is_user_connected(attacker) || !is_user_alive(attacker) || !is_user_connected(victim) || !is_user_alive(victim) )
	return
	
	if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker) && dam[attacker])
	{
		new Float: xdmg = get_pcvar_float(p_dmg_multiplier)
		damage *= xdmg
		SetHamParamFloat(4, damage)
	}
}


public fw_PlayerTraceAttack(victim, attacker, Float:Damage, Float:direction[3], tracehandle, damagebits)
{
	if(!is_user_connected(attacker) || !is_user_alive(attacker) || !is_user_connected(victim) || !is_user_alive(victim) )
	return
	
	if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker) && dam[attacker])
	{
		new Float: xdmg = get_pcvar_float(p_dmg_multiplier)
		Damage *= xdmg
		SetHamParamFloat(3, Damage)
	}
}

public fw_Spawn_Post(id)
{
	if(is_user_alive(id) && !zp_get_user_zombie(id)) 
	{	
		remove_task(id)
		strip_user_weapons(id)
		reset_value_zombie(id)
		fm_give_item(id, "weapon_usp")
		fm_give_item(id, "weapon_knife")
		cs_set_user_bpammo( id, CSW_USP, 200 )
		set_task(0.0, "DisplayMenu", id)
		can_choose[id] = 1
		zbcanbuys[id] = true
		remove_task(id+TASK_NOL)
		set_task(30.0, "choose_nol", id+TASK_NOL)
		
		if(codebox1(id)) paladinunlocked[id] = true
		if(codebox2(id)) dkunlocked[id] = true
		if(codebox3(id)) cannonunlocked[id] = true
		
		if(damunlocked[id])
		{
			dam[id] = true
		}
		if(jumpunlocked[id])
		{
			set_user_gravity(id, get_pcvar_float(p_grav))
		}
		if(nghtvisionunlocked[id])
		{
			cs_set_user_nvg(id, 1)
		}
		if(deadlyunlocked[id])
		{
			give_ds(id)
		}
		if(bloodyunlocked[id])
		{
			give_bb(id)
		}
		if(sprintunlocked[id])
		{
			give_sprint(id)
		}
		
	}
}

public darahkebuka(id)
{
	return incrshpunlocked[id];
}

public reset_value_zombie(id)
{
	tank_reset_value_player(id)
	sting_reset_value(id)
	venom_reset_value(id)
	stamper_reset_value(id)
	banchee_reset_value_player(id)
	deimos_reset_value_player(id)
	speed_reset_value(id)
	pc_reset_value_player(id)
	metatronic_reset_value(id)
	lilith_reset_value(id)
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

new const g_PrimaryNames[][] = {
								"M4A1",
								"AK47",
								"Famas",
								"P90",
								"XM1014",
								"Plasma Gun",
								"Skull-4",
								"AK47 Paladin",
								"M4A1 Dark Knight",
								"Balrog-11 Blue",
								"Black Dragon Cannon",
								"Coil Machinegun",
								"Janus-5",
								"Skull-5",
								"Brick Peace V2",
								"Magnum Drill",
								"Vandita",
								"Thunderbolt",
								"Thanatos-5"
								}

new const g_SecondaryNames[][] = {
								"USP",
								"Beretta 92G Elite II",
								"Glock",
								"Deagle",
								"Balrog-1",
								"Dual Infinity Final",
								"Janus-1"
								}

new const g_MeleeNames[][] = {
								"Seal Knife",
								"Light Saber",
								"Nata Knife",
								"Thanatos-9",
								"Skull-9",
								"Dragon Sword",
								"Balrog-9 Blue"
								}
								
//////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Z O M B I E _ N A T I V E /////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

public destroy_menu(id) 
{
	show_menu(id, 0, "^n", 1);
}

public choose_nol(id)
{
	id -= TASK_NOL
	
	if(!is_user_alive(id))
		return
	
	can_choose[id] = 0
}

public zp_user_infected_post(id, infector, nemesis)
{
	reset_value_zombie(id)
	
	//set_task(0.2, "zombie_menu", id)
	set_task(1.5, "coy", id)
}

public coy(id, infector, nemesis)
{
	remove_task(id)
	
	if(g_ZB_class[id] == 1)
	{
		reset_value_zombie(id)
		give_tank(id)
		g_zombie_class[id] = 1
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 2)
	{
		reset_value_zombie(id)
		give_pc(id)
		g_zombie_class[id] = 1
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 3)
	{
		reset_value_zombie(id)
		give_venom(id)
		g_zombie_class[id] = 5
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 4)
	{
		reset_value_zombie(id)
		give_speed(id)
		g_zombie_class[id] = 2
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 5)
	{
		reset_value_zombie(id)
		give_deimos(id)
		g_zombie_class[id] = 1
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 6)
	{
		reset_value_zombie(id)
		give_banchee(id)
		g_zombie_class[id] = 4
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 7)
	{
		reset_value_zombie(id)
		give_sting(id)
		g_zombie_class[id] = 0
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 8)
	{
		reset_value_zombie(id)
		give_stamper(id)
		g_zombie_class[id] = 3
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 9)
	{
		reset_value_zombie(id)
		Give_Lilith(id)
		g_zombie_class[id] = 7
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	if(g_ZB_class[id] == 10)
	{
		reset_value_zombie(id)
		Give_Meta(id)
		g_zombie_class[id] = 6
		if(zbgrnadeunlocked[id]) give_zb(id)
	}
	
	engclient_cmd(id, "weapon_knife")
	havegravity[id] = false
	zbcanbuys[id] = true
	set_task(0.2, "zombie_menu", id)
	set_task(6.0, "destroy_menu", id)
	timer = 5
	set_task(0.2, "countdown", id)
}

public countdown(id)
{
	if( timer > 0)
	{
		client_print(id, print_center, "Remaining Time For Choose Zombie Class: %i Second(s)", timer)
		timer-- 
		set_task(1.0, "countdown", id)
	}		
}

public zombie_menu(id)
{
	
		menu1 = menu_create("\r[ \ySelect Your Zombie Class\r ]\w:", "zombie_Handle")
		
		new temp[201];
		
		menu_additem(menu1, "Regular Zombie" , "1", 0)
		menu_additem(menu1, "Psycho Zombie" , "2", 0)

		if(!vodounlocked[id])
		{
			formatex(temp,200, "\dVenom Guard Zombie\w(\r$%i\w)",get_pcvar_num(p_vodo))
			menu_additem(menu1, temp,"3",0)
		}
		else
		{
			menu_additem(menu1, "Venom Guard Zombie (Unlocked)" , "3", 0)
		}
		
		if(!lightunlocked[id])
		{
			formatex(temp,200, "\dLusty Rose\w(\r$%i\w)",get_pcvar_num(p_light))
			menu_additem(menu1, temp,"4",0)
		}
		else
		{
			menu_additem(menu1, "Lusty Rose (Unlocked)" , "4", 0)
		}
		
		if(!deimosunlocked[id])
		{
			formatex(temp,200, "\dDeimos Zombie\w(\r$%i\w)",get_pcvar_num(p_deimos))
			menu_additem(menu1, temp,"5",0)
		}
		else
		{
			menu_additem(menu1, "Deimos Zombie (Unlocked)" , "5", 0)
		}
		
		if(!bansheunlocked[id])
		{
			formatex(temp,200, "\dBanshee Zombie\w(\r$%i\w)",get_pcvar_num(p_banshe))
			menu_additem(menu1, temp,"6",0)
		}
		else
		{
			menu_additem(menu1, "Banshee Zombie (Unlocked)" , "6", 0)
		}
		
		if(!stamperunlocked[id])
		{
			formatex(temp,200, "\dSting Finger Zombie\w(\r$%i\w)",get_pcvar_num(p_stamper))
			menu_additem(menu1, temp,"7",0)
		}
		else
		{
			menu_additem(menu1, "Sting Finger Zombie (Unlocked)" , "7", 0)
		}
		
		if(!stingunlocked[id])
		{
			formatex(temp,200, "\dStamper Zombie\w(\r$%i\w)",get_pcvar_num(p_sting))
			menu_additem(menu1, temp,"8",0)
		}
		else
		{
			menu_additem(menu1, "Stamper Zombie (Unlocked)" , "8", 0)
		}
		
		if(!lilithunlocked[id])
		{
			formatex(temp,200, "\dLilith Zombie\w(\r$%i\w)",get_pcvar_num(p_lilith))
			menu_additem(menu1, temp,"9",0)
		}
		else
		{
			menu_additem(menu1, "Lilith Zombie (Unlocked)" , "9", 0)
		}
		
		if(!metaunlocked[id])
		{
			formatex(temp,200, "\dMetatronic Zombie\w(\r$%i\w)",get_pcvar_num(p_meta))
			menu_additem(menu1, temp,"10",0)
		}
		else
		{
			menu_additem(menu1, "Metatronic Zombie (Unlocked)" , "10", 0)
		}

		menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
		menu_setprop(menu1, MPROP_PERPAGE, 0)
		
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}

public zombie_Handle(id, menu1, item)
{
	if (item == MENU_EXIT || !is_user_alive(id))
	{
		menu_destroy(menu1)
		remove_task(id)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			if(g_ZB_class[id] == 1)
			{
				menu_destroy(menu1)
				remove_task(id)
			}
			else
			{
				reset_value_zombie(id)
				give_tank(id)
				g_zombie_class[id] = 1
				g_ZB_class[id] = 1
				remove_task(id)
				if(zbgrnadeunlocked[id]) give_zb(id)
				engclient_cmd(id, "weapon_knife")
			}
		}
		case 2:
		{
			if(g_ZB_class[id] == 2)
			{
				menu_destroy(menu1)
				remove_task(id)
			}
			else
			{
				reset_value_zombie(id)
				give_pc(id)
				g_zombie_class[id] = 1
				g_ZB_class[id] = 2
				remove_task(id)
				if(zbgrnadeunlocked[id]) give_zb(id)
				engclient_cmd(id, "weapon_knife")
			}
		}
		case 3:
		{
				if(!vodounlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_vodo))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_vodo))
						vodounlocked[id] = true
						reset_value_zombie(id)
						give_venom(id)
						g_zombie_class[id] = 5
						g_ZB_class[id] = 3
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 3)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_venom(id)
							g_zombie_class[id] = 5
							g_ZB_class[id] = 3
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 4:
		{
				if(!lightunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_light))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_light))
						lightunlocked[id] = true
						reset_value_zombie(id)
						give_speed(id)
						g_zombie_class[id] = 2
						g_ZB_class[id] = 4
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 4)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_speed(id)
							g_zombie_class[id] = 2
							g_ZB_class[id] = 4
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 5:
		{
				if(!deimosunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_deimos))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_deimos))
						deimosunlocked[id] = true
						reset_value_zombie(id)
						give_deimos(id)
						g_zombie_class[id] = 1
						g_ZB_class[id] = 5
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{		
						if(g_ZB_class[id] == 5)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_deimos(id)
							g_zombie_class[id] = 1
							g_ZB_class[id] = 5
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 6:
		{
				if(!bansheunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_banshe))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_banshe))
						bansheunlocked[id] = true
						reset_value_zombie(id)
						give_banchee(id)
						g_zombie_class[id] = 4
						g_ZB_class[id] = 6
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 6)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_banchee(id)
							g_zombie_class[id] = 4
							g_ZB_class[id] = 6
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 7:
		{
				if(!stamperunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_stamper))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_stamper))
						stamperunlocked[id] = true
						reset_value_zombie(id)
						give_sting(id)
						g_zombie_class[id] = 0
						g_ZB_class[id] = 7
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 7)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_sting(id)
							g_zombie_class[id] = 0
							g_ZB_class[id] = 7
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 8:
		{
			if(!stingunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_sting))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_sting))
						stingunlocked[id] = true
						reset_value_zombie(id)
						give_stamper(id)
						g_zombie_class[id] = 3
						g_ZB_class[id] = 8
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 8)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							give_stamper(id)
							g_zombie_class[id] = 3
							g_ZB_class[id] = 8
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 9:
		{
			if(!lilithunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_lilith))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_lilith))
						lilithunlocked[id] = true
						reset_value_zombie(id)
						Give_Lilith(id)
						g_zombie_class[id] = 7
						g_ZB_class[id] = 9
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 9)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							Give_Lilith(id)
							g_zombie_class[id] = 7
							g_ZB_class[id] = 9
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
		case 10:
		{
			if(!metaunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_meta))
					{
						zombie_menu(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_meta))
						metaunlocked[id] = true
						reset_value_zombie(id)
						Give_Meta(id)
						g_zombie_class[id] = 6
						g_ZB_class[id] = 10
						remove_task(id)
						if(zbgrnadeunlocked[id]) give_zb(id)
						engclient_cmd(id, "weapon_knife")
					}
				}
				else
				{
						if(g_ZB_class[id] == 10)
						{
							menu_destroy(menu1)
							remove_task(id)
						}
						else
						{
							reset_value_zombie(id)
							Give_Meta(id)
							g_zombie_class[id] = 6
							g_ZB_class[id] = 10
							remove_task(id)
							if(zbgrnadeunlocked[id]) give_zb(id)
							engclient_cmd(id, "weapon_knife")
						}
				}
		}
	}
	return PLUGIN_HANDLED;
}

public clcmd_changeteam(id)
{
	static team
	team = fm_cs_get_user_team(id)
	
	// Unless it's a spectator joining the game
	if (team == FM_CS_TEAM_SPECTATOR || team == FM_CS_TEAM_UNASSIGNED)
		return PLUGIN_CONTINUE;
	
	// Pressing 'M' (chooseteam) ingame should show the main menu instead
	itemmenu(id)
	return PLUGIN_HANDLED;
}

stock fm_cs_get_user_team(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return FM_CS_TEAM_UNASSIGNED;
	
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}


public itemmenu(id)
{
	if(zp_get_user_zombie(id))
	{
		//ShowMenuZM(id)
	}
	else
	{
		ShowMenuHM(id)
	}  
	
}

//////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// ZOMBIE MENU BUY ////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////

public ShowMenuZM(id)
{
		menu1 = menu_create("\r[ \yZombie Extra Items\r ]\w:", "ShowMenuZM_Handle")

		new temp[101];
		
		if(!zbgrnadeunlocked[id])
		{
			formatex(temp,100, "\dZombie Grenade\w(\r$%i\w)",get_pcvar_num(p_zbgr))
			menu_additem(menu1, temp,"1",0)
		}
		else
		{
			menu_additem(menu1, "Zombie Grenade (Unlocked)" , "1", 0)
		}
		if(!incrshpunlocked[id])
		{
			formatex(temp,100, "\dIncrease HP\w(\r$%i\w)",get_pcvar_num(p_incrshp))
			menu_additem(menu1, temp,"2",0)
		}
		else
		{
			menu_additem(menu1, "Increase HP (Unlocked)" , "2", 0)
		}

		
		menu_setprop(menu1, MPROP_EXIT, MEXIT_ALL);
		
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}

//////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// HUMAN MENU BUY /////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////

public ShowMenuHM(id)
{
	
		menu1 = menu_create("\r[ \yHuman Extra Items\r ]\w:", "ShowMenuHM_Handle")

		new temp[101];
		
		if(!jumpunlocked[id])
		{
			formatex(temp,100, "\dJump Higher\w(\r$%i\w)",get_pcvar_num(p_jump))
			menu_additem(menu1, temp,"1",0)
		}
		else
		{
			menu_additem(menu1, "Jump Higher (Unlocked)" , "1", 0)
		}
		if(!grnadehmunlocked[id])
		{
			formatex(temp,100, "\dx2 Grenade\w(\r$%i\w)",get_pcvar_num(p_hmgrnd))
			menu_additem(menu1, temp,"2",0)
		}
		else
		{
			menu_additem(menu1, "x2 Grenade (Unlocked)" , "2", 0)
		}
		if(!nghtvisionunlocked[id])
		{
			formatex(temp,100, "\dNightvision\w(\r$%i\w)",get_pcvar_num(p_nghtvsion))
			menu_additem(menu1, temp,"3",0)
		}
		else
		{
			menu_additem(menu1, "Nightvision (Unlocked)" , "3", 0)
		}
		if(!deadlyunlocked[id])
		{
			formatex(temp,100, "\dDeadly Shot\w(\r$%i\w)",get_pcvar_num(p_deadly))
			menu_additem(menu1, temp,"4",0)
		}
		else
		{
			menu_additem(menu1, "Deadly Shot (Unlocked)" , "4", 0)
		}
		if(!bloodyunlocked[id])
		{
			formatex(temp,100, "\dBloody Blade\w(\r$%i\w)",get_pcvar_num(p_bloody))
			menu_additem(menu1, temp,"5",0)
		}
		else
		{
			menu_additem(menu1, "Bloody Blade (Unlocked)" , "5", 0)
		}
		if(!sprintunlocked[id])
		{
			formatex(temp,100, "\dSprint\w(\r$%i\w)",get_pcvar_num(p_sprint))
			menu_additem(menu1, temp,"6",0)
		}
		else
		{
			menu_additem(menu1, "Sprint (Unlocked)" , "6", 0)
		}
		if(!damunlocked[id])
		{
			formatex(temp,100, "\d+30% Damage\w(\r$%i\w)",get_pcvar_num(p_dam))
			menu_additem(menu1, temp,"7",0)
		}
		else
		{
			menu_additem(menu1, "+30% Damage (Unlocked)" , "7", 0)
		}
		if(!ammounlocked[id])
		{
			formatex(temp,100, "\dExtra Ammo\w(\r$%i\w)",get_pcvar_num(p_ammo))
			menu_additem(menu1, temp,"8",0)
		}
		else
		{
			menu_additem(menu1, "Extra Ammo (Unlocked)" , "8", 0)
		}

		menu_additem(menu1, "Exit", "MENU_EXIT" )
		menu_setprop(menu1, MPROP_PERPAGE, 0)
		
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}

public ShowMenuHM_Handle(id, menu1, item)
{
	if (item == MENU_EXIT || !is_user_alive(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
				if(!jumpunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_jump))
					{
						ShowMenuHM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_jump))
						set_user_gravity(id, get_pcvar_float(p_grav))
						jumpunlocked[id] = true
						havegravity[id] = true
					}
				}
				else
				{
						ShowMenuHM(id)
				}
		}
		case 2:
		{
				if(!grnadehmunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_hmgrnd))
					{
						ShowMenuHM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_hmgrnd))
						grnadehmunlocked[id] = true
						zp_force_buy_extra_item( id, zp_get_extra_item_id("HE Grenade"), 1)
					}
				}
				else
				{
						ShowMenuHM(id)
				}
		}
		case 3:
		{
				if(!nghtvisionunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_nghtvsion))
					{
						ShowMenuHM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_nghtvsion))
						nghtvisionunlocked[id] = true
						cs_set_user_nvg(id, 1)
					}
				}
				else
				{
						ShowMenuHM(id)
				}
		}
		case 4:
		{
				if(!deadlyunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_deadly))
					{
						ShowMenuHM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_deadly))
						deadlyunlocked[id] = true
						give_ds(id)
					}
				}
				else
				{
						ShowMenuHM(id)
				}
		}
		case 5:
		{
				if(!bloodyunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_bloody))
					{
						ShowMenuHM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_bloody))
						bloodyunlocked[id] = true
						give_bb(id)
					}
				}
				else
				{
						ShowMenuHM(id)
				}
		}
		case 6:
		{
				if(!sprintunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_sprint))
					{
						ShowMenuHM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_sprint))
						sprintunlocked[id] = true
						give_sprint(id)
					}
				}
				else
				{
						ShowMenuHM(id)
				}
		}
		case 7:
		{
				if(!damunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_dam))
					{
						ShowMenuHM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_dam))
						damunlocked[id] = true
						dam[id] = true
					}
				}
				else
				{
						ShowMenuHM(id)
				}
		}
		case 8:
		{
				if(!ammounlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_ammo))
					{
						ShowMenuHM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_ammo))
						ammounlocked[id] = true
						refill2(id)
					}
				}
				else
				{
						ShowMenuHM(id)
				}
		}
	}
	return PLUGIN_HANDLED;
}

public ShowMenuZM_Handle(id, menu1, item)
{
	if (item == MENU_EXIT || !is_user_alive(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
				if(!zbgrnadeunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_zbgr))
					{
						ShowMenuZM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_zbgr))
						zbgrnadeunlocked[id] = true
						give_zb(id)
					}
				}
				else
				{
						ShowMenuZM(id)
				}
		}
		case 2:
		{
				if(!incrshpunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_incrshp))
					{
						ShowMenuZM(id)
					}
					else
					{
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_incrshp))
						incrshpunlocked[id] = true
					}
				}
				else
				{
						ShowMenuZM(id)
				}
		}
	}
	return PLUGIN_HANDLED;
}

//////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// H U M A N _ N A T I V E ///////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

public DisplayMenu( id )
{
	
    if(zp_get_user_zombie(id))
	return FMRES_IGNORED
    
    new menu = menu_create( "\r[ \yWeapon Menu\r ]\w:", "MenuHandler");
    
    new szItem[ 64 ];
    
    
    
    formatex( szItem, charsmax( szItem ), "Primary Weapon \d[ \y%s \d]", g_PrimaryNames[ iWeapprim[ id ] ] );
    menu_additem( menu, szItem, "0" );
    
    formatex( szItem, charsmax( szItem ), "Secondary Weapon \d[ \y%s \d]", g_SecondaryNames[ iWeapsec[ id ] ] );
    menu_additem( menu, szItem, "1" );
    
    formatex( szItem, charsmax( szItem ), "Melee Weapon \d[ \y%s \d]^n", g_MeleeNames[ iWeapmelee[ id ] ] );
    menu_additem( menu, szItem, "2" );
    
    menu_additem( menu, "\d[ \yReceive Weapons\d ]", "3" );
    
    
    menu_setprop( menu, MPROP_EXIT, MEXIT_NEVER );
    
    menu_display( id, menu );
    
    return FMRES_IGNORED
}

public MenuHandler( id, menu, item )
{
    switch( item )
    {
        case 0:
        {
			guns_menu( id )
        }
        case 1:
        {
			pistolmenu( id )
        }
        case 2:
        {
			knifemenu( id )
        }
        case 3:
        {    
			giveweapons(id)
        }
        
    }
}

public guns_menu(id) 
{
	
		menu1 = menu_create("\r[ \yChoose Your Primary\r ]\w:", "gunsmenu_Handle")
 
		new temp[101];
		
		menu_additem(menu1, "M4A1" , "1", 0)
		menu_additem(menu1, "AK47", "2", 0)
		menu_additem(menu1, "Famas", "3", 0)
		menu_additem(menu1, "P90", "4", 0)
		menu_additem(menu1, "XM1014", "5", 0)
		
		if(!plasmaunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_plasma)) formatex(temp,100, "\yPlasma Gun\w(\r$%i\w)",get_pcvar_num(p_plasma))
			else formatex(temp,100, "\dPlasma Gun\w(\r$%i\w)",get_pcvar_num(p_plasma))
			menu_additem(menu1, temp,"6",0)
		}
		else
		{
			menu_additem(menu1, "Plasma Gun" , "6", 0)
		}
		if(!sk4unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_sk4)) formatex(temp,100, "\ySkull-4\w(\r$%i\w)",get_pcvar_num(p_sk4))
			else formatex(temp,100, "\dSkull-4\w(\r$%i\w)",get_pcvar_num(p_sk4))
			menu_additem(menu1, temp,"7",0)
		}
		else
		{
			menu_additem(menu1, "Skull-4" , "7", 0)
		}
		
		if(!paladinunlocked[id])
		{
			if(jumlah_paladin() <= 1) formatex(temp,100, "\dAK47 Paladin\w(\rCode Box\w) %i/1 Max 1 Player", jumlah_paladin())
			else formatex(temp,100, "\dAK47 Paladin\w(\rCode Box\w) 1/1 Max 1 Players")
			menu_additem(menu1, temp,"8",0)
		}
		else
		{
			menu_additem(menu1, "AK47 Paladin [Permanent]" , "8", 0)
		}
		
		if(!dkunlocked[id])
		{
			if(jumlah_dk() <= 1) formatex(temp,100, "\dM4A1 Dark Knight\w(\rCode Box\w) %i/1 Max 1 Player", jumlah_dk())
			else formatex(temp,100, "\dM4A1 Dark Knight\w(\rCode Box\w) 1/1 Max 1 Players")
			menu_additem(menu1, temp,"9",0)
		}
		else
		{
			menu_additem(menu1, "M4A1 Dark Knight [Permanent]" , "9", 0)
		}
		
		if(!bl11unlocked[id])
		{
			if(stok_balrog11 >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_bl11)) formatex(temp,100, "\yBalrog-11 Blue\w(\r$%i\w) %i Limit(s) Remaining",get_pcvar_num(p_bl11), stok_balrog11)
				else formatex(temp,100, "\dBalrog-11 Blue\w(\r$%i\w) %i Limit(s) Remaining",get_pcvar_num(p_bl11), stok_balrog11)
			}
			else formatex(temp,100, "\dBalrog-11 Blue\w(\r$%i\w) Limited !",get_pcvar_num(p_bl11))
			
			menu_additem(menu1, temp,"10",0)
		}
		else
		{
			menu_additem(menu1, "Balrog-11 Blue" , "10", 0)
		}
		
		if(!cannonunlocked[id])
		{
			if(jumlah_cannon() <= 1) formatex(temp,100, "\dBlack Dragon Cannon\w(\rCode Box\w) %i/1 Max 1 Player", jumlah_cannon())
			else formatex(temp,100, "\dBlack Dragon Cannon\w(\rCode Box\w) 1/1 Max 1 Players")
			menu_additem(menu1, temp,"11",0)
		}
		else
		{
			menu_additem(menu1, "Black Dragon Cannon [Permanent]" , "11", 0)
		}
		
		if(!coilunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_coil)) formatex(temp,100, "\yCoil Machinegun\w(\r$%i\w)",get_pcvar_num(p_coil))
			else formatex(temp,100, "\dCoil Machinegun\w(\r$%i\w)",get_pcvar_num(p_coil))
			menu_additem(menu1, temp,"12",0)
		}
		else
		{
			menu_additem(menu1, "Coil Machinegun" , "12", 0)
		}
		
		if(!janus5unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_janus5)) formatex(temp,100, "\yJanus-5\w(\r$%i\w)",get_pcvar_num(p_janus5))
			else formatex(temp,100, "\dJanus-5\w(\r$%i\w)",get_pcvar_num(p_janus5))
			menu_additem(menu1, temp,"13",0)
		}
		else
		{
			menu_additem(menu1, "Janus-5" , "13", 0)
		}
		
		if(!sk5unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_sk5)) formatex(temp,100, "\ySkull-5\w(\r$%i\w)",get_pcvar_num(p_sk5))
			else formatex(temp,100, "\dSkull-5\w(\r$%i\w)",get_pcvar_num(p_sk5))
			menu_additem(menu1, temp,"14",0)
		}
		else
		{
			menu_additem(menu1, "Skull-5" , "14", 0)
		}
		
		if(!brickv2unlocked[id])
		{
			if(stok_blockar >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_brickv2)) formatex(temp,100, "\yBrick Peace V2\w(\r$%i\w) %i Limit(s) Remaining",get_pcvar_num(p_brickv2), stok_blockar)
				else formatex(temp,100, "\dBrick Peace V2\w(\r$%i\w) %i Limit(s) Remaining",get_pcvar_num(p_brickv2), stok_blockar)
			}
			else formatex(temp,100, "\dBrick Peace V2\w(\r$%i\w) Limited !",get_pcvar_num(p_brickv2))
			
			menu_additem(menu1, temp,"15",0)
		}
		else
		{
			menu_additem(menu1, "Brick Peace V2" , "15", 0)
		}
		
		if(!drillunlocked[id])
		{
			if(stok_drill >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_drill)) formatex(temp,100, "\yMagnum Drill\w(\r$%i\w) %i Limit(s) Remaining",get_pcvar_num(p_drill), stok_drill)
				else formatex(temp,100, "\dMagnum Drill\w(\r$%i\w) %i Limit(s) Remaining",get_pcvar_num(p_drill), stok_drill)
			}
			else formatex(temp,100, "\dMagnum Drill\w(\r$%i\w) Limited !",get_pcvar_num(p_drill))
			
			menu_additem(menu1, temp,"16",0)
		}
		else
		{
			menu_additem(menu1, "Magnum Drill" , "16", 0)
		}
		
		if(!vanditaunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_vandita)) formatex(temp,100, "\yVandita\w(\r$%i\w)",get_pcvar_num(p_vandita))
			else formatex(temp,100, "\dVandita\w(\r$%i\w)",get_pcvar_num(p_vandita))
			menu_additem(menu1, temp,"17",0)
		}
		else
		{
			menu_additem(menu1, "Vandita" , "17", 0)
		}
		
		if(!thunderboltunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_thunderbolt)) formatex(temp,100, "\yThunderbolt\w(\r$%i\w)",get_pcvar_num(p_thunderbolt))
			else formatex(temp,100, "\dThunderbolt\w(\r$%i\w)",get_pcvar_num(p_thunderbolt))
			menu_additem(menu1, temp,"18",0)
		}
		else
		{
			menu_additem(menu1, "Thunderbolt" , "18", 0)
		}
		
		if(!tn5unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_tn5)) formatex(temp,100, "\yThanatos-5\w(\r$%i\w)",get_pcvar_num(p_tn5))
			else formatex(temp,100, "\dThanatos-5\w(\r$%i\w)",get_pcvar_num(p_tn5))
			menu_additem(menu1, temp,"19",0)
		}
		else
		{
			menu_additem(menu1, "Thanatos-5" , "19", 0)
		}
		
		if(!spearunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_spear)) formatex(temp,100, "\ySpeargun\w(\r$%i\w)",get_pcvar_num(p_spear))
			else formatex(temp,100, "\dSpeargun\w(\r$%i\w)",get_pcvar_num(p_spear))
			menu_additem(menu1, temp,"20",0)
		}
		else
		{
			menu_additem(menu1, "Speargun" , "20", 0)
		}
		
		menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
	
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
	
		return PLUGIN_HANDLED
}

public gunsmenu_Handle(id, menu1, item)
{
	if (zp_get_user_zombie(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			iWeapprim[ id ] = 0
			DisplayMenu( id )
		}
		case 2:
		{
			iWeapprim[ id ] = 1
			DisplayMenu( id )
		}
		case 3:
		{		
			iWeapprim[ id ] = 2
			DisplayMenu( id )
		}
		case 4:
		{
			iWeapprim[ id ] = 3
			DisplayMenu( id )
		}
		case 5:
		{
			iWeapprim[ id ] = 4
			DisplayMenu( id )
	         }
		case 6:
		{
				if(!plasmaunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_plasma))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 5
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_plasma))
						plasmaunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 5
					DisplayMenu(id)
				}
		}
		case 7:
		{
				if(!sk4unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_sk4))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 6	
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_sk4))
						sk4unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 6
					DisplayMenu(id)
				}
		}
		case 8:
		{
			if(!paladinunlocked[id])
				{
					guns_menu(id)
					if(jumlah_paladin() >= 1) client_print(id, print_center, "Quota sudah penuh, coba lagi di map selanjutnya !")
					else client_print(id, print_center, "Cari Supply Box!, sebelum ada 1 player yang mendapatkannya !")
				}
				else
				{
					iWeapprim[ id ] = 7
					DisplayMenu(id)
				}
		}
		case 9:
		{
			if(!dkunlocked[id])
				{
					guns_menu(id)
					if(jumlah_dk() >= 1) client_print(id, print_center, "Quota sudah penuh, coba lagi di map selanjutnya !")
					else client_print(id, print_center, "Cari Supply Box!, sebelum ada 1 player yang mendapatkannya !")
				}
				else
				{
					iWeapprim[ id ] = 8
					DisplayMenu(id)
				}
		}
		case 10:
		{
			if(!bl11unlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_bl11) || stok_balrog11 <= 0)
				{
					guns_menu(id)
				}
				else
				{
					iWeapprim[ id ] = 9
					DisplayMenu(id)
					stok_balrog11 --
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_bl11))
					bl11unlocked[id] = true
				}
			}
			else
			{
				iWeapprim[ id ] = 9
				DisplayMenu(id)
			}
		}
		case 11:
		{
			if(!cannonunlocked[id])
				{
					guns_menu(id)
					if(jumlah_cannon() >= 1) client_print(id, print_center, "Quota sudah penuh, coba lagi di map selanjutnya !")
					else client_print(id, print_center, "Cari Supply Box!, sebelum ada 1 player yang mendapatkannya !")
				}
				else
				{
					iWeapprim[ id ] = 10
					DisplayMenu(id)
				}
		}
		case 12:
		{
				if(!coilunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_coil))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 11
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_coil))
						coilunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 11
					DisplayMenu(id)
				}
		}
		case 13:
		{
				if(!janus5unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_janus5))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 12
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_janus5))
						janus5unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 12
					DisplayMenu(id)
				}
		}
		case 14:
		{
				if(!sk5unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_sk5))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 13
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_sk5))
						sk5unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 13
					DisplayMenu(id)
				}
		}
		case 15:
		{
			if(!brickv2unlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_brickv2) || stok_blockar <= 0)
				{
					guns_menu(id)
				}
				else
				{
					iWeapprim[ id ] = 14
					DisplayMenu(id)
					stok_blockar --
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_brickv2))
					brickv2unlocked[id] = true
				}
			}
			else
			{
				iWeapprim[ id ] = 14
				DisplayMenu(id)
			}
		}
		case 16:
		{
			if(!drillunlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_drill) || stok_drill <= 0)
				{
					guns_menu(id)
				}
				else
				{
					iWeapprim[ id ] = 15
					DisplayMenu(id)
					stok_drill --
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_drill))
					drillunlocked[id] = true
				}
			}
			else
			{
				iWeapprim[ id ] = 15
				DisplayMenu(id)
			}
		}
		case 17:
		{
				if(!vanditaunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_vandita))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 16
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_vandita))
						vanditaunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 16
					DisplayMenu(id)
				}
		}
		case 18:
		{
				if(!thunderboltunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_thunderbolt))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 17
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_thunderbolt))
						thunderboltunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 17
					DisplayMenu(id)
				}
		}
		case 19:
		{
				if(!tn5unlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_tn5))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 18
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_tn5))
						tn5unlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 18
					DisplayMenu(id)
				}
		}
		case 20:
		{
				if(!spearunlocked[id])
				{
					if(zp_cs_get_user_money(id) < get_pcvar_num(p_spear))
					{
						guns_menu(id)
					}
					else
					{
						iWeapprim[ id ] = 19
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_spear))
						spearunlocked[id] = true
						DisplayMenu(id)
					}
				}
				else
				{
					iWeapprim[ id ] = 19
					DisplayMenu(id)
				}
		}
	
	}
	return PLUGIN_HANDLED;
}

public pistolmenu(id) 
{	
		menu1 = menu_create("\r[ \yChoose Your Secondary\r ]\w:", "pistolmenu_Handle")

		new temp[101];
		
		menu_additem(menu1, "USP" , "1", 0)
		menu_additem(menu1, "Beretta 92G Elite II" , "2", 0)
		menu_additem(menu1, "Glock", "3", 0)
		menu_additem(menu1, "Deagle", "4", 0)
		menu_additem(menu1, "Balrog-1", "5", 0)
		
		if(!difunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_dif)) formatex(temp,100, "\yDual Infinity Final\w(\r$%i\w)",get_pcvar_num(p_dif))
			else formatex(temp,100, "\dDual Infinity Final\w(\r$%i\w)",get_pcvar_num(p_dif))
			menu_additem(menu1, temp,"6",0)
		}
		else
		{
			menu_additem(menu1, "Dual Infinity Final" , "6", 0)
		}
		
		if(!janus1unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_janus1)) formatex(temp,100, "\yJanus-1\w(\r$%i\w)",get_pcvar_num(p_janus1))
			else formatex(temp,100, "\dJanus-1\w(\r$%i\w)",get_pcvar_num(p_janus1))
			menu_additem(menu1, temp,"7",0)
		}
		else
		{
			menu_additem(menu1, "Janus-1" , "7", 0)
		}
		
						
		menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
		
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}

public pistolmenu_Handle(id, menu1, item)
{	
	if (zp_get_user_zombie(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key)
	{	
		case 1:
		{
			iWeapsec[ id ] = 0
			DisplayMenu(id)
		}
		case 2:
		{
			iWeapsec[ id ] = 1
			DisplayMenu(id)
		}
		case 3:
		{
			iWeapsec[ id ] = 2
			DisplayMenu(id)
		}
		case 4:
		{
			iWeapsec[ id ] = 3
			DisplayMenu(id)
		}
		case 5:
		{
			iWeapsec[ id ] = 4
			DisplayMenu(id)
		}
		case 6:
		{
			if(!difunlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_dif))
				{
						pistolmenu(id) 
				}
				else
				{
						iWeapsec[ id ] = 5
						DisplayMenu(id)
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_dif))
						difunlocked[id] = true
				}
			}
			else
			{
					iWeapsec[ id ] = 5
					DisplayMenu(id)
			}
		}	
		case 7:
		{
			if(!janus1unlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_janus1))
				{
						pistolmenu(id) 
				}
				else
				{
						iWeapsec[ id ] = 6
						DisplayMenu(id)
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_janus1))
						janus1unlocked[id] = true
				}
			}
			else
			{
					iWeapsec[ id ] = 6
					DisplayMenu(id)
			}
		}	
	}
	return PLUGIN_HANDLED;
}

public knifemenu(id) 
{
		menu1 = menu_create("\r[ \yChoose Your Melee\r ]\w:", "knifemenu_Handle")
		
		new temp[101];

		menu_additem(menu1, "Seal Knife" , "1", 0)
		menu_additem(menu1, "Light Saber" , "2", 0)
		
		if(!nataunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_nata)) formatex(temp,100, "\yNata Knife\w(\r$%i\w)",get_pcvar_num(p_nata))
			else formatex(temp,100, "\dNata Knife\w(\r$%i\w)",get_pcvar_num(p_nata))
			menu_additem(menu1, temp,"3",0)
		}
		else
		{
			menu_additem(menu1, "Nata Knife" , "3", 0)
		}
		
		if(!tn9unlocked[id])
		{
			if(stok_thanatos9 >= 1)
			{
				if(zp_cs_get_user_money(id) >= get_pcvar_num(p_tn9)) formatex(temp,100, "\yThanatos-9\w(\r$%i\w) %i Limit(s) Remaining",get_pcvar_num(p_tn9), stok_thanatos9)
				else formatex(temp,100, "\dThanatos-9\w(\r$%i\w) %i Limit(s) Remaining",get_pcvar_num(p_tn9), stok_thanatos9)
			}
			else formatex(temp,100, "\dThanatos-9\w(\r$%i\w) Limited !",get_pcvar_num(p_tn9))
			
			menu_additem(menu1, temp,"4",0)
		}
		else
		{
			menu_additem(menu1, "Thanatos-9" , "4", 0)
		}
		
		if(!sk9unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_sk9)) formatex(temp,100, "\ySkull-9\w(\r$%i\w)",get_pcvar_num(p_sk9))
			else formatex(temp,100, "\dSkull-9\w(\r$%i\w)",get_pcvar_num(p_sk9))
			menu_additem(menu1, temp,"5",0)
		}
		else
		{
			menu_additem(menu1, "Skull-9" , "5", 0)
		}
		
		if(!drgswrdunlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_drgswrd)) formatex(temp,100, "\yDragon Sword\w(\r$%i\w)",get_pcvar_num(p_drgswrd))
			else formatex(temp,100, "\dDragon Sword\w(\r$%i\w)",get_pcvar_num(p_drgswrd))
			menu_additem(menu1, temp,"6",0)
		}
		else
		{
			menu_additem(menu1, "Dragon Sword" , "6", 0)
		}
		
		if(!bl9unlocked[id])
		{
			if(zp_cs_get_user_money(id) >= get_pcvar_num(p_bl9)) formatex(temp,100, "\yBalrog-9 Blue\w(\r$%i\w)",get_pcvar_num(p_bl9))
			else formatex(temp,100, "\dBalrog-9 Blue\w(\r$%i\w)",get_pcvar_num(p_bl9))
			menu_additem(menu1, temp,"7",0)
		}
		else
		{
			menu_additem(menu1, "Balrog-9 Blue" , "7", 0)
		}
		
		menu_setprop(menu1, MPROP_EXIT, MEXIT_NEVER);
		
		if (is_user_alive(id)) 
		{
			menu_display(id, menu1, 0)
		}
		
		return PLUGIN_HANDLED
}

public knifemenu_Handle(id, menu1, item)
{
	
	if (zp_get_user_zombie(id))
	{
		menu_destroy(menu1)
		return PLUGIN_HANDLED
	}
		
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			iWeapmelee[ id ] = 0
			DisplayMenu(id)
		}
		case 2:
		{
			iWeapmelee[ id ] = 1
			DisplayMenu(id)
		}
		case 3:
		{
			if(!nataunlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_nata))
				{
						knifemenu(id)
				}
				else
				{
						iWeapmelee[ id ] = 2
						DisplayMenu(id)
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_nata))
						nataunlocked[id] = true
				}
			}
			else
			{
					iWeapmelee[ id ] = 2
					DisplayMenu(id)
			}
		}
		case 4:
		{
			if(!tn9unlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_tn9) || stok_thanatos9 <= 0)
				{
					knifemenu(id)
				}
				else
				{
					iWeapmelee[ id ] = 3
					DisplayMenu(id)
					stok_thanatos9 --
					PlayEmitSound(id, sound_cash)
					zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_tn9))
					tn9unlocked[id] = true
				}
			}
			else
			{
				iWeapmelee[ id ] = 3
				DisplayMenu(id)
			}
		}
		case 5:
		{
			if(!sk9unlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_sk9))
				{
						knifemenu(id)
				}
				else
				{
						iWeapmelee[ id ] = 4
						DisplayMenu(id)
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_sk9))
						sk9unlocked[id] = true
				}
			}
			else
			{
					iWeapmelee[ id ] = 4
					DisplayMenu(id)
			}
		}
		case 6:
		{
			if(!drgswrdunlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_drgswrd))
				{
						knifemenu(id)
				}
				else
				{
						iWeapmelee[ id ] = 5
						DisplayMenu(id)
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_drgswrd))
						drgswrdunlocked[id] = true
				}
			}
			else
			{
					iWeapmelee[ id ] = 5
					DisplayMenu(id)
			}
		}
		case 7:
		{
			if(!bl9unlocked[id])
			{
				if(zp_cs_get_user_money(id) < get_pcvar_num(p_bl9))
				{
						knifemenu(id)
				}
				else
				{
						iWeapmelee[ id ] = 6
						DisplayMenu(id)
						PlayEmitSound(id, sound_cash)
						zp_cs_set_user_money(id, zp_cs_get_user_money(id) - get_pcvar_num(p_bl9))
						bl9unlocked[id] = true
				}
			}
			else
			{
					iWeapmelee[ id ] = 6
					DisplayMenu(id)
			}
		}
		
	}
	return PLUGIN_HANDLED;
}

public give_prims( id, number )
{
    switch( number )
    {
		case 0:
        {
			fm_give_item(id, "weapon_m4a1")
			cs_set_user_bpammo( id, CSW_M4A1, 200 )
        }
		case 1:
        {
			fm_give_item(id, "weapon_ak47")
			cs_set_user_bpammo( id, CSW_AK47, 200 )
        }
		case 2:
        {
			fm_give_item(id, "weapon_famas")
			cs_set_user_bpammo( id, CSW_FAMAS, 200 )
        }
		case 3:
        {
			fm_give_item(id, "weapon_p90")
			cs_set_user_bpammo( id, CSW_P90, 200 )
        }
		case 4:
        {
			fm_give_item(id, "weapon_xm1014")
			cs_set_user_bpammo( id, CSW_XM1014, 64 )
        }
		case 5:
        {
			Get_Plasma(id)
        }
		case 6:
        {
			give_skull4(id)
        }
		case 7:
	{
			get_buffak(id)
	}
		case 8:
	{
			get_buffm4(id)
	}
		case 9:
	{
			Get_Balrog11(id)
	}
		case 10:
	{
			get_dragoncannon(id)
	}
		case 11:
	{
			Get_Coilgun(id)
	}
		case 12:
	{
			Get_Janus5(id)
	}
		case 13:
	{
			Get_Skull5(id)
	}
		case 14:
	{
			Get_BlockAR(id)
	}
		case 15:
	{
			give_drill(id)
	}
		case 16:
	{
			Get_Vandita(id)
	}
		case 17:
	{
			Get_Thunderbolt(id)
	}
		case 18:
	{
			Get_Thanatos5(id)
	}
		case 19:
	{
			get_speargun(id)
	}

      }
}

public give_sec( id, number )

    switch( number )
    {
                  case 0:
        {
			fm_give_item(id, "weapon_usp")
			cs_set_user_bpammo( id, CSW_USP, 200 )
        }
		case 1:
        {
			fm_give_item(id, "weapon_elite")
			cs_set_user_bpammo( id, CSW_ELITE, 300 )
        }
		case 2:
        {
			fm_give_item(id, "weapon_glock18")
			cs_set_user_bpammo( id, CSW_GLOCK18, 300 )
        }
		case 3:
        {
			fm_give_item(id, "weapon_deagle")
			cs_set_user_bpammo( id, CSW_DEAGLE, 40 )
        }
		case 4:
        {
			give_b1(id)
        }
		case 5:
        {
			give_infinity(id)
        }
		case 6:
        {
			get_janus1(id)
        }
    }

public give_melee( id, number )
{
    switch( number )
    {
	case 0:
	{
		fm_give_item(id, "weapon_knife")
	}	
	case 1:
	{
		Get_LightSaber(id)
	}
	case 2:
	{
		give_nata(id)
	}
	case 3:
	{
		Get_Thanatos9(id)
	}
	case 4:
	{
		get_skull9(id)
	}
	case 5:
	{
		get_dragonsword(id)
	}
	case 6:
	{
		get_balrog9(id)
	}
    }
}

public giveweapons(id)
{
	if (!is_user_alive(id)){
		return 1;
	}
	
	give_itemsss(id)
	drop_weapons(id, 1)
	drop_weapons(id, 2)
	give_melee( id, iWeapmelee[ id ] )
	give_sec( id, iWeapsec[ id ] )
	give_prims( id, iWeapprim[ id ] )
	give_itemsss(id)
        
	return 0;
}

public give_itemsss(id)
{
	fm_give_item(id, "weapon_hegrenade")
	if(grnadehmunlocked[id])
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("HE Grenade"), 1)
	}
	
	if(ammounlocked[id])
	{
		refill2(id)
	}
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
