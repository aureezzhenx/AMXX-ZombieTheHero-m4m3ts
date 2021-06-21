/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Includes ]
*------------------------------------------------------------------------------------------*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <fun>
#include <xs>
#include <zombieplague>
#include <dhudmessage>
#include <m4m3tsunlock>

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Information ]
*------------------------------------------------------------------------------------------*/

#define MIN_HEALTH_ZOMBIE 2000
#define MIN_ARMOR_ZOMBIE 100
#define ZB_LV2_HEALTH 8000
#define ZB_LV2_ARMOR 500
#define ZB_LV3_HEALTH 14000
#define ZB_LV3_ARMOR 500
#define RESTORE_HEALTH_TIME 3
#define RESTORE_HEALTH_DMG_LV1 200
#define RESTORE_HEALTH_DMG_LV2 500

/*---------------------------------------------*
 [ ZP CSO Plugin Name ]
*---------------------------------------------*/

new const ZP_CSO_PLUGIN_NAME[] = "[ZP] CSO In-Game Theme"

/*---------------------------------------------*
 [ ZP CSO Plugin Version ]
*---------------------------------------------*/

new const ZP_CSO_PLUGIN_VERSION[] = "5.5"

/*---------------------------------------------*
 [ ZP CSO Plugin Author ]
*---------------------------------------------*/

new const ZP_CSO_PLUGIN_AUTHOR[] = "jc980"

/*---------------------------------------------*
 [ ZP CSO Plugin CFG File ]
*---------------------------------------------*/

new const ZP_CSO_PLUGIN_CFGFILE[] = "zp_cso_theme.cfg"

/*---------------------------------------------*
 [ ZP CSO Plugin INC File ]
*---------------------------------------------*/

new const ZP_CSO_PLUGIN_INCFILE[] = "zp_cso_theme"

/*---------------------------------------------*
 [ ZP CSO Plugin LANG File ]
*---------------------------------------------*/

new const ZP_CSO_PLUGIN_LANGFILE[] = "zp_cso_theme.txt"

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Game Variables ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Variables Needed ]
*---------------------------------------------*/

new zp_cso_round, zp_cso_czbot, zp_cso_humanswins, zp_cso_zombieswins, zp_cso_roundstarted,
zp_cso_evohp_forward, zp_cso_evo_armor_forward, zp_cso_forward_dummyresult

/*---------------------------------------------*
 [ ZP CSO Plugin Points System ]
*---------------------------------------------*/

new zp_cso_authid[33][35], zp_cso_vault, zp_cso_points[33], zp_cso_point_multiplier[33]

/*---------------------------------------------*
 [ ZP CSO Plugin HUD ]
*---------------------------------------------*/

new zp_center_textmsg, zp_cso_hud_sync1, zp_cso_hud_sync2
new g_Hud_Notice
new g_TipTime, g_Cvar_Tip, g_Countdown, g_Cvar_Transcript, g_Transcript

/*---------------------------------------------*
 [ ZP CSO Plugin HM & ZB Level Up System ]
*---------------------------------------------*/

new zp_cso_hmlvl, zp_cso_lvlmax, zp_cso_zblvl[33], zp_cso_evokill[33], zp_cso_wpnnames[32], Float: zp_cso_clpushangle[33][3]

/*---------------------------------------------*
 [ ZP CSO Plugin KILL! System ]
*---------------------------------------------*/

new zp_cso_kill_lvl[33], zp_cso_kill_total[33], zp_cso_kill_time[33], zp_cso_kill_time_end, zp_cso_maxkills

/*---------------------------------------------*
 [ ZP CSO Plugin Respawn System ]
*---------------------------------------------*/

new zp_cso_total_spawn = 0, bool:zp_cso_first_spawn[33], Float: zp_cso_spawn_vec[60][3],
Float: zp_cso_spawn_angle[60][3], Float: zp_cso_spawn_v_angle[60][3], zp_cso_respawnspr,
zp_cso_respawnwait[33], zp_cso_lvlspr

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin CVARs ]
*------------------------------------------------------------------------------------------*/

new zp_cso_cvar_savetype, zp_cso_cvar_enablerespawn, zp_cso_cvar_delayrespawn

new g_MaxPlayers
new g_zombie_die[33]
new g_Ham_Bot
new g_start_health[33]
new g_star_armor[33]
new first_zombi[33]
new g_level[33]
new KillCount[33]
new zombiedeath2[33]
new g_iMaxClients
new g_restore_health[33]
new g_heal

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Sounds ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Round Start MP3 ]
*---------------------------------------------*/

new const zp_cso_roundstart[][] = 
{
	"sound/zombie_plague/cso/zombi_start.mp3"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Zombie Ambience ]
*---------------------------------------------*/

new const zp_cso_roundambience[][] = 
{
	"sound/zombie_plague/cso/bgm_tdmending.mp3"
}

/*---------------------------------------------*
 [ ZP CSO Plugin 20 Second(s) Warning ]
*---------------------------------------------*/

new const zp_cso_warning[][] = 
{
	"zombie_plague/cso/20secs.wav"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Come Back Chant ]
*---------------------------------------------*/

new const zp_cso_zombierespawn[][] = 
{
	"zombie_plague/cso/zombi_comeback.wav"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Human Level Up ]
*---------------------------------------------*/

new const zp_cso_human_lvlup[][] = 
{
	"zombie_plague/cso/human_dmglvlup.wav"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Zombie Level Up ]
*---------------------------------------------*/

new const zp_cso_zombie_lvlup[][] = 
{
	"zombie_plague/cso/zombi_evolvlup.wav"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Infect Chant ]
*---------------------------------------------*/

new zombie_infect[2][] =
{
	"zombie_plague/cso/zombi_coming_korea_1.wav",
	"zombie_plague/cso/zombi_coming_korea_2.wav"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Normal KILL! Sounds ]
*---------------------------------------------*/

new zp_cso_kill_sounds1[14][] =
{
	"zombie_plague/cso/kill1.wav",
	"zombie_plague/cso/kill2.wav",
	"zombie_plague/cso/kill3.wav",
	"zombie_plague/cso/kill4.wav",
	"zombie_plague/cso/kill5.wav",
	"zombie_plague/cso/kill6.wav",
	"zombie_plague/cso/kill7.wav",
	"zombie_plague/cso/kill8.wav",
	"zombie_plague/cso/kill9.wav",
	"zombie_plague/cso/kill10.wav",
	"zombie_plague/cso/kill11.wav",
	"zombie_plague/cso/kill12.wav",
	"zombie_plague/cso/kill13.wav",
	"zombie_plague/cso/kill14.wav"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Special KILL! Sounds ]
*---------------------------------------------*/

new zp_cso_kill_sounds2[3][] =
{
	"zombie_plague/cso/kill_knife.wav",
	"zombie_plague/cso/kill_grenade.wav",
	"zombie_plague/cso/kill_headshot.wav"
}

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Kill System HUD ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin KILL! HUD Red ]
*---------------------------------------------*/

new const zp_cso_kill_r[14] =
{
	250,
	50,
	250,
	250,
	250,
	250,
	250,
	50,
	250,
	250,
	250,
	250,
	250,
	250
}

/*---------------------------------------------*
 [ ZP CSO Plugin KILL! HUD Green ]
*---------------------------------------------*/

new const zp_cso_kill_g[14] =
{
	250,
	150,
	250,
	150,
	0,
	250,
	50,
	150,
	150,
	0,
	150,
	250,
	150,
	0
}

/*---------------------------------------------*
 [ ZP CSO Plugin KILL! HUD Blue ]
*---------------------------------------------*/

new const zp_cso_kill_b[14] =
{
	250,
	250,
	50,
	50,
	0,
	50,
	250,
	250,
	50,
	0,
	250,
	50,
	50,
	0
}

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin HM & ZB Level Up System ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Human Level Damage Multiplier ]
*---------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Human Level Recoil Multiplier ]
*---------------------------------------------*/

new const zp_cso_recoil_lvl[11][] = 
{
	"1.0",
	"0.9",
	"0.8",
	"0.7",
	"0.6",
	"0.5",
	"0.4",
	"0.3",
	"0.2",
	"0.1",
	"0.0"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Zombie Level Additional HP ]
*---------------------------------------------*/

new const zp_cso_evo_hp_lvl[4][] =
{
	"0",
	"3000",
	"7000",
	"14000"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Zombie Level Additional Armor ]
*---------------------------------------------*/

new const zp_cso_evo_armor_lvl[4][] =
{
	"0",
	"100",
	"500",
	"1000"
}

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin HM & ZB Level Up System HUD  ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Human Fire Power Percent ]
*---------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Human Level HUD Red ]
*---------------------------------------------*/

new const zp_cso_hmlvl_r[11] =
{
	0,
	0,
	0,
	0,
	255,
	255,
	255,
	255,
	255,
	255,
	255
}

/*---------------------------------------------*
 [ ZP CSO Plugin Human Level HUD Green ]
*---------------------------------------------*/

new const zp_cso_hmlvl_g[11] =
{
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	155,
	155,
	155,
	0
}

/*---------------------------------------------*
 [ ZP CSO Plugin Human Level HUD Blue ]
*---------------------------------------------*/

new const zp_cso_hmlvl_b[11] =
{
	0,
	0,
	0,
	0,
	55,
	55,
	55,
	55,
	55,
	55,
	0
}

/*---------------------------------------------*
 [ ZP CSO Plugin Zombie Evolution Percent ]
*---------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Zombie Level HUD Red ]
*---------------------------------------------*/

new const zp_cso_zblvl_r[4] =
{
	255,
	255,
	255,
	255
}

/*---------------------------------------------*
 [ ZP CSO Plugin Zombie Level HUD Green ]
*---------------------------------------------*/

new const zp_cso_zblvl_g[4] =
{
	255,
	255,
	155,
	0
}

/*---------------------------------------------*
 [ ZP CSO Plugin Zombie Level HUD Blue ]
*---------------------------------------------*/

new const zp_cso_zblvl_b[4] =
{
	55,
	55,
	55,
	0
}

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Constants ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Non-Weapon Bitsum ]
*---------------------------------------------*/

new const ZP_CSO_NONWPN_BITSUM = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

/*---------------------------------------------*
 [ ZP CSO Plugin Damage HE Grenade Bitsum ]
*---------------------------------------------*/

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Sprites ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Respawn Sprite ]
*---------------------------------------------*/

new zp_cso_respawnsprite[][] = 
{
	"sprites/zombie_plague/cso/zp_zbrespawn.spr"
}

/*---------------------------------------------*
 [ ZP CSO Plugin Human Level Up Sprite ]
*---------------------------------------------*/

new zp_cso_levelsprite[][] = 
{
	"sprites/zombie_plague/cso/zp_hmlvlup.spr"
}

new const health_sound_male[] = "zombie_plague/zombie_heal.wav"
new const health_sound_female[] = "zombie_plague/zombi_heal_female.wav"
new const health_sound_meta[] = "zombie_plague/metatronic_heal.wav"
new const health_sound_lilith[] = "zombie_plague/lilith_heal_skill3.wav"


new const zombie_jerit_male[][] =
{
	"zombie_plague/male_infection1.wav",
	"zombie_plague/male_infection2.wav"
}

new const zombie_jerit_female[][] =
{
	"zombie_plague/female_infection1.wav",
	"zombie_plague/female_infection2.wav"
}

new const zombie_evolution[] = "zombie_plague/evolution.wav"

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Code ]
*------------------------------------------------------------------------------------------*/

#define TASK_COUNTDOWN 18701

/*---------------------------------------------*
 [ ZP CSO Plugin Natives ]
*---------------------------------------------*/

public plugin_natives()
{
	register_library(ZP_CSO_PLUGIN_INCFILE)
	
	register_native("zth_get_user_start_health", "native_get_user_start_health", 1)
	register_native("zp_cso_theme_evohp", "zp_cso_native_evohp", 1)
	register_native("zp_cso_theme_evo_armor", "zp_cso_native_evo_armor", 1)
}

public native_get_user_start_health(id)
{
	return g_start_health[id];
}

/*---------------------------------------------*
 [ ZP CSO Plugin Init ]
*---------------------------------------------*/

public plugin_init() 
{
	register_plugin(ZP_CSO_PLUGIN_NAME, ZP_CSO_PLUGIN_VERSION, ZP_CSO_PLUGIN_AUTHOR)
	
	register_event("HLTV", "zp_cso_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "zp_cso_death", "a", "1>0")
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	new iWpn
	
	for(iWpn = 1; iWpn <= CSW_P90; iWpn++)
	{
		if( !(ZP_CSO_NONWPN_BITSUM & (1 << iWpn)) && get_weaponname(iWpn, zp_cso_wpnnames, charsmax(zp_cso_wpnnames)))
		{
			RegisterHam(Ham_Weapon_PrimaryAttack, zp_cso_wpnnames, "zp_cso_primary_attack")
			RegisterHam(Ham_Weapon_PrimaryAttack, zp_cso_wpnnames, "zp_cso_primary_attack_post",1) 
		}
	}
	
	zp_cso_cvar_savetype = register_cvar("zp_csotheme_savetype", "1")
	zp_cso_cvar_enablerespawn = register_cvar("zp_csotheme_enable_respawn", "1")
	zp_cso_cvar_delayrespawn = register_cvar("zp_csotheme_delay_respawn", "5.0")
	
	g_Cvar_Tip = register_cvar("zp_cso_tiptime", "180")
	g_Cvar_Transcript = register_cvar("zevo_transcript", "1")
	
	g_MaxPlayers = get_maxplayers()
	
	zp_center_textmsg = get_user_msgid("TextMsg")
	zp_cso_vault = nvault_open("zp_cso_theme")
	zp_cso_hud_sync1 = CreateHudSyncObj()
	zp_cso_hud_sync2 = CreateHudSyncObj()
	
	zp_cso_evohp_forward = CreateMultiForward("zp_cso_theme_evohp_lvlup", ET_IGNORE, FP_CELL, FP_CELL)
	zp_cso_evo_armor_forward = CreateMultiForward("zp_cso_theme_evo_armor_lvlup", ET_IGNORE, FP_CELL, FP_CELL)
	
	server_cmd("exec addons/amxmodx/configs/zp_cso_theme.cfg")
	
	csdm_respawn()
	g_Hud_Notice = CreateHudSyncObj(1)
	g_iMaxClients = get_maxplayers( )
}

/*---------------------------------------------*
 [ ZP CSO Plugin End ]
*---------------------------------------------*/

public plugin_end()
{
	nvault_close(zp_cso_vault)
}

public reset_valuee(id)
{
	zombiedeath2[id] = false
	g_zombie_die[id] = 0
	g_start_health[id] = 0
	g_restore_health[id] = 0
	g_star_armor[id] = 0
	g_level[id] = 0
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Register CZBots ]
*---------------------------------------------*/

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled")
	RegisterHamFromEntity(Ham_Killed, id, "fw_Spawn_Post")
}

public ResetKills(id)
{
	new players[32] , inum
	get_players(players, inum)
	for(new a = 0; a < inum; ++a)
		KillCount[a] = 0
}

/*---------------------------------------------*
 [ ZP CSO Plugin End ]
*---------------------------------------------*/

public plugin_cfg()
{
	new zp_configsdir[32]
	
	get_configsdir(zp_configsdir, charsmax(zp_configsdir))
	
	server_cmd("exec %s/%s", zp_configsdir, ZP_CSO_PLUGIN_CFGFILE)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Precache ]
*---------------------------------------------*/

public plugin_precache()
{
	register_dictionary(ZP_CSO_PLUGIN_LANGFILE)
	
	for(new i = 0; i < sizeof(zombie_infect); i++)
		precache_sound(zombie_infect[i])
	
	precache_sound("zombie_plague/cso/countdowns.wav")
	precache_sound("zombie_plague/cso/message.wav")
	
	g_heal = precache_model("sprites/cso_heal.spr")
	
	new i
	
	for(i = 0; i < sizeof zp_cso_roundstart; i++) 
		engfunc(EngFunc_PrecacheGeneric, zp_cso_roundstart[i])
		
	for(i = 0; i < sizeof zp_cso_roundambience; i++) 
		engfunc(EngFunc_PrecacheGeneric, zp_cso_roundambience[i])
		
	for(i = 0; i < sizeof zp_cso_warning; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_warning[i])
		
	for(i = 0; i < sizeof zp_cso_kill_sounds1; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_kill_sounds1[i])
		
	for(i = 0; i < sizeof zp_cso_kill_sounds2; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_kill_sounds2[i])
		
	for(i = 0; i < sizeof zp_cso_zombierespawn; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_zombierespawn[i])
		
	for(i = 0; i < sizeof zp_cso_human_lvlup; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_human_lvlup[i])
	
	for(i = 0; i < sizeof zp_cso_zombie_lvlup; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_zombie_lvlup[i])

	for(i = 0; i < sizeof zp_cso_respawnsprite; i++) 
		zp_cso_respawnspr = engfunc(EngFunc_PrecacheModel, zp_cso_respawnsprite[i])
	
	for(i = 0; i < sizeof zp_cso_levelsprite; i++) 
		zp_cso_lvlspr = engfunc(EngFunc_PrecacheModel, zp_cso_levelsprite[i])
		
	for(new i = 0; i < sizeof(zombie_jerit_male); i++)
		precache_sound(zombie_jerit_male[i])
	for(new i = 0; i < sizeof(zombie_jerit_female); i++)
		precache_sound(zombie_jerit_female[i])
	
	precache_sound(health_sound_male)
	precache_sound(health_sound_female)
	precache_sound(health_sound_meta)
	precache_sound(health_sound_lilith)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Round Start ( CS ) ]
*---------------------------------------------*/

public zp_cso_round_start()
{
	new iSound, iMP3, MP3[64], iSpeak[64], iPlayers[32], iPlayer, iPlayerNum
	
	iSound = random_num(0, charsmax(zp_cso_warning))
	iMP3 = random_num(0, charsmax(zp_cso_roundstart))
	copy(MP3, charsmax(MP3), zp_cso_roundstart[iMP3])
	copy(iSpeak, charsmax(iSpeak), zp_cso_warning[iSound])
	
	client_cmd(0,"speak ^"%s^"", iSpeak)
	client_cmd(0,"mp3 play ^"%s^"", MP3)
		
	get_players(iPlayers, iPlayerNum)
	
	for(new iNum; iNum < iPlayerNum; iNum++)
	{
		iPlayer = iPlayers[iNum]
		
		zp_cso_zblvl[iPlayer] = 0
		zp_cso_evokill[iPlayer] = 0
		
		zp_cso_damage_plus(iPlayer, 0)
		
		if(zp_get_user_zombie(iPlayer))
		{
			zp_cso_evolution(iPlayer, 0)
		}
	}
	zp_cso_hmlvl = 0
	zp_cso_lvlmax = 10
	zp_cso_round += 1
	zp_cso_kill_time_end = 10
	zp_cso_maxkills = 14
	
	g_Transcript = get_pcvar_num(g_Cvar_Transcript)
	
	g_Countdown = 0
	
	remove_task(TASK_COUNTDOWN)
	
	set_task(20.0,"zp_cso_ambience")
	zp_cso_countdown()
	
	Start_MunculTip()
}

public Event_RoundStart()
{
	g_Countdown = 1
	
	// Reset Countingdown
	remove_task(TASK_COUNTDOWN)
	
	g_TipTime--
	MunculTip()
}

/*---------------------------------------------*
 [ ZP CSO Plugin CSDM Respawn Method ]
*---------------------------------------------*/

csdm_respawn()
{   
	new zp_map[32], zp_config[32],  zp_mapfile[64]
	
	get_mapname(zp_map, 31)
	get_configsdir(zp_config, 31)
	
	format(zp_mapfile, 63, "%s\csdm\%s.spawns.cfg", zp_config, zp_map)
	
	zp_cso_total_spawn = 0
	
	if (file_exists(zp_mapfile)) 
	{
		new zp_new_data[124], zp_len
		new zp_line = 0
		new zp_pos[12][8]
		
		while(zp_cso_total_spawn < 60 && (zp_line = read_file(zp_mapfile , zp_line, zp_new_data, 123, zp_len)) != 0) 
		{
			if (strlen(zp_new_data) < 2 || zp_new_data[0] == '[')
				continue
				
			parse(zp_new_data, zp_pos[1], 7, zp_pos[2], 7, zp_pos[3], 7, zp_pos[4], 7, zp_pos[5], 7, zp_pos[6], 7, zp_pos[7], 7, zp_pos[8], 7, zp_pos[9], 7, zp_pos[10], 7)	
			
			zp_cso_spawn_vec[zp_cso_total_spawn][0] = str_to_float(zp_pos[1])
			zp_cso_spawn_vec[zp_cso_total_spawn][1] = str_to_float(zp_pos[2])
			zp_cso_spawn_vec[zp_cso_total_spawn][2] = str_to_float(zp_pos[3])	
			
			zp_cso_spawn_angle[zp_cso_total_spawn][0] = str_to_float(zp_pos[4])
			zp_cso_spawn_angle[zp_cso_total_spawn][1] = str_to_float(zp_pos[5])
			zp_cso_spawn_angle[zp_cso_total_spawn][2] = str_to_float(zp_pos[6])	
			
			zp_cso_spawn_v_angle[zp_cso_total_spawn][0] = str_to_float(zp_pos[8])
			zp_cso_spawn_v_angle[zp_cso_total_spawn][1] = str_to_float(zp_pos[9])
			zp_cso_spawn_v_angle[zp_cso_total_spawn][2] = str_to_float(zp_pos[10])
			
			zp_cso_total_spawn += 1
		}	
		
		if (zp_cso_total_spawn >= 2 && get_pcvar_num(zp_cso_cvar_enablerespawn) == 1)
		{
			RegisterHam(Ham_Spawn, "player", "zp_cso_zombie_spawn", 1)
		}
	}
	
	return 1
}

/*---------------------------------------------*
 [ ZP CSO Plugin CVARs Zombie Spawn Location ]
*---------------------------------------------*/

public zp_cso_zombie_spawn(id)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	if (zp_cso_first_spawn[id])
	{
		zp_cso_first_spawn[id] = false
		
		return PLUGIN_CONTINUE
	}
	
	new zp_list[60]
	new zp_num = 0
	new zp_final = -1
	new zp_total = 0
	new zp_players[32], zp_no, zp_xo = 0
	new Float:zp_location[32][3], zp_locnum
	
	get_players(zp_players,zp_num)
	
	for (new i=0; i < zp_num; i++)
	{
		if (is_user_alive(zp_players[i]) && zp_players[i] != id)
		{
			pev(zp_players[i], pev_origin, zp_location[zp_locnum])
			zp_locnum++
		}
	}
	
	zp_num = 0
	
	while (zp_num <= zp_cso_total_spawn)
	{
		if (zp_num == zp_cso_total_spawn)
			break
			
		zp_no = random_num(0, zp_cso_total_spawn - 1)
		
		if (!zp_list[zp_no])
		{
			zp_list[zp_no] = 1
			zp_num += 1
		} 
		else 
		{
			zp_total += 1
			if (zp_total > 100)
				break
				
			continue  
		}
		
		if (zp_locnum < 1)
		{
			zp_final = zp_no
			break
		}
		
		zp_final = zp_no
		
		for (zp_xo = 0; zp_xo < zp_locnum; zp_xo++)
		{
			new Float: zp_distance = get_distance_f(zp_cso_spawn_vec[zp_no], zp_location[zp_xo])
			
			if (zp_distance < 250.0)
			{
				zp_final = -1
				break
			}
		}
		
		if (zp_final != -1)
			break
	}
	
	if (zp_final != -1)
	{
		new Float:mins[3], Float:maxs[3]
		
		pev(id, pev_mins, mins)
		pev(id, pev_maxs, maxs)
		
		engfunc(EngFunc_SetSize, id, mins, maxs)
		engfunc(EngFunc_SetOrigin, id, zp_cso_spawn_vec[zp_final])
		
		set_pev(id, pev_fixangle, 1)
		set_pev(id, pev_angles, zp_cso_spawn_angle[zp_final])
		set_pev(id, pev_v_angle, zp_cso_spawn_v_angle[zp_final])
		set_pev(id, pev_fixangle, 1)
	}
	
	return PLUGIN_CONTINUE
} 

/*---------------------------------------------*
 [ ZP CSO Plugin Death Event ]
*---------------------------------------------*/

public zp_cso_death()
{
	new iKiller = read_data(1)
	new iVictim = read_data(2)
	new iHeadshot = read_data(3)
	new iClip, iAmmo, iWeapon = get_user_weapon(iKiller, iClip, iAmmo)
	new iReward = 100
	new iKills[32], iType[32], Float: iDelay
	new iDmglvl, iHumans[32], iHuman, iHumanNum
	
	zp_cso_kill_lvl[iVictim] = 0
	zp_cso_kill_time[iVictim] = 0
	zp_cso_kill_time[iKiller] = 0
	zp_cso_kill_total[iKiller] += 1
	
	if(!zp_get_user_zombie(iKiller))
	{
		if(zp_cso_hmlvl < zp_cso_lvlmax)
		{
			zp_cso_hmlvl += 1
			iDmglvl = zp_cso_hmlvl
			
			get_players(iHumans, iHumanNum)
			
			for(new iNum ; iNum < iHumanNum; iNum++)
			{
				iHuman = iHumans[iNum]
				
				zp_cso_damage_plus(iHuman, iDmglvl)
			}
		}
	}
	
	if(iKiller == iVictim)
		return PLUGIN_CONTINUE
		
	if(zp_get_user_zombie(iVictim))
	{
		zp_cso_kill_lvl[iVictim] = 0
		zp_cso_kill_time[iVictim] = 0
		
		if(!iHeadshot)
		{
			iDelay = get_pcvar_float(zp_cso_cvar_delayrespawn)
			set_task(iDelay,"zp_cso_zombie_respawner", iVictim)
			
			zp_cso_respawnwait[iVictim] = get_pcvar_num(zp_cso_cvar_delayrespawn)
			
			zp_zbrespawn(iVictim)
			zp_zbrespawn_msg(iVictim)
		}
		else
		{
			zp_zbrespawn_msg2(iVictim)
		}
	}
	
	if(zp_cso_kill_lvl[iKiller] < zp_cso_maxkills)
	{
		zp_cso_kill_lvl[iKiller] += 1
		iKills[iKiller] = zp_cso_kill_lvl[iKiller]
		zp_cso_point_multiplier[iKiller] = iKills[iKiller]
		
		if(zp_get_user_zombie(iKiller))
		{
			if(iHeadshot)
			{
				iType[iKiller] = 3
			}
			else
			{
				iType[iKiller] = 0
			}
		}
		else if(iWeapon == CSW_KNIFE)
		{
			iType[iKiller] = 1
		}
		else if(iWeapon == CSW_HEGRENADE)
		{
			iType[iKiller] = 2
		}
		else if(iHeadshot)
		{
			iType[iKiller] = 3
		}
		else
		{
			iType[iKiller] = 0
		}
		
		zp_cso_announce_kill(iKiller, iKills[iKiller], iType[iKiller])
	}
	
	zp_cso_points[iKiller] += iReward * zp_cso_point_multiplier[iKiller]
	
	if(zp_cso_kill_lvl[iKiller] == zp_cso_maxkills)
	{
		zp_cso_kill_lvl[iKiller] = 0
	}
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Take Damage Event ]
*---------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Primary Attack Event ]
*---------------------------------------------*/

public zp_cso_primary_attack(ent)
{
	new iPlayer = pev(ent,pev_owner)
	
	pev(iPlayer, pev_punchangle, zp_cso_clpushangle[iPlayer])
	
	return HAM_IGNORED
}

/*---------------------------------------------*
 [ ZP CSO Plugin CVARs Primary Attack Post ]
*---------------------------------------------*/

public zp_cso_primary_attack_post(ent)
{
	new iPlayer = pev(ent, pev_owner)
	
	if (!zp_get_user_zombie(iPlayer))
	{
		new Float: zp_recoil_lvl = str_to_float(zp_cso_recoil_lvl[zp_cso_hmlvl])
		new Float: zp_push[3]
		
		pev(iPlayer, pev_punchangle, zp_push)
		
		xs_vec_sub(zp_push, zp_cso_clpushangle[iPlayer], zp_push)
		
		xs_vec_mul_scalar(zp_push, zp_recoil_lvl, zp_push)
		
		xs_vec_add(zp_push, zp_cso_clpushangle[iPlayer], zp_push)
		
		set_pev(iPlayer, pev_punchangle, zp_push)
	}
	
	return HAM_IGNORED
}

/*---------------------------------------------*
 [ ZP CSO Plugin Round Start ( ZP ) ]
*---------------------------------------------*/

public zp_round_started(id)
{
	client_cmd(0, "spk ^"%s^"", zombie_infect[random( sizeof(zombie_infect))])
	
	zp_cso_roundstarted = 1
	
	new iText[64]
	
	format(iText, charsmax(iText), "%L", LANG_PLAYER, "ZP_CSO_INFECTION_NOTICE")
	zp_clientcenter_text(0, iText)	
	
	set_dhudmessage(85, 255, 85, -1.0, 0.70, 2, 4.0, 4.0, 0.05, 1.0)
	show_dhudmessage(1, "ZOMBIES ARE COMING!")
	
	static Transcript[64]
	formatex(Transcript, 23, "TRANSCRIPT_%i", random_num(1, 3))
	
	set_hudmessage(255, 42, 42, -1.0, 0.25, 0, 4.0, 4.0, 0.05, 1.0)
	ShowSyncHudMsg(1, g_Hud_Notice, "%L", LANG_PLAYER, Transcript)
	
	static total
	total = total_player()
	
	if (total >= 8 && total <= 20)
	{
		set_task(0.2, "make_zombie", id)
	}
	
	if (total >= 21 && total <= 25)
	{
		set_task(0.2, "make_zombie", id)
		set_task(0.3, "make_zombie2", id)
	}
	
	if (total >= 26)
	{
		set_task(0.2, "make_zombie", id)
		set_task(0.3, "make_zombie2", id)
		set_task(0.4, "make_zombie3", id)
	}
}

public make_zombie(id)
{		
	new id
	static iPlayersNum
	iPlayersNum = gAlive()

	id = gRandomAlive(random_num(1, iPlayersNum))
	first_zombi[id] = 1
	zp_infect_user(id)
}

public make_zombie2(id)
{		
	new id
	static iPlayersNum
	iPlayersNum = gAlive()

	id = gRandomAlive(random_num(1, iPlayersNum))
	first_zombi[id] = 1
	zp_infect_user(id)
}

public make_zombie3(id)
{		
	new id
	static iPlayersNum
	iPlayersNum = gAlive()

	id = gRandomAlive(random_num(1, iPlayersNum))
	first_zombi[id] = 1
	zp_infect_user(id)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Round End ( ZP ) ]
*---------------------------------------------*/

public zp_round_ended()
{
	if(zp_get_human_count() == 0)
	{
		zp_cso_zombieswins += 1
	}
	else
	{
		zp_cso_humanswins += 1
	}
	
	zp_cso_roundstarted = 0
	remove_task(TASK_COUNTDOWN)
}

/*---------------------------------------------*
 [ ZP CSO Plugin User Infected Post ]
*---------------------------------------------*/

public fw_CmdStart(id, uc_handle, seed)
{			
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED
	}

	// restore health
	zombie_restore_health(id)

	return FMRES_IGNORED
}

zombie_restore_health(id)
{
	if (!zp_get_user_zombie(id)) return;
	
	static Float:velocity[3]
	pev(id, pev_velocity, velocity)
	
	if (!velocity[0] && !velocity[1] && !velocity[2])
	{
		if (!g_restore_health[id]) g_restore_health[id] = get_systime()
	}
	else g_restore_health[id] = 0
	
	if (g_restore_health[id])
	{
		new rh_time = get_systime() - g_restore_health[id]
		if (rh_time == RESTORE_HEALTH_TIME+1 && get_user_health(id) < g_start_health[id])
		{
			// get health add
			new health_add
			if (g_level[id]==1) health_add = RESTORE_HEALTH_DMG_LV1
			else health_add = RESTORE_HEALTH_DMG_LV2
			
			// get health new
			new health_new = get_user_health(id)+health_add
			health_new = min(health_new, g_start_health[id])
			
			// set health
			set_user_health(id, health_new)
			g_restore_health[id] += 1
			
			if(zth_get_zombie_class(id) == 1 || zth_get_zombie_class(id) == 3 || zth_get_zombie_class(id) == 5)
			{
				client_cmd(id, "spk ^"%s^"", health_sound_male)
			}
			else if(zth_get_zombie_class(id) == 6)
			{
				client_cmd(id, "spk ^"%s^"", health_sound_meta)
			}
			else if(zth_get_zombie_class(id) == 7)
			{
				client_cmd(id, "spk ^"%s^"", health_sound_lilith)
			}
			else client_cmd(id, "spk ^"%s^"", health_sound_female)
			
			new origin[3] 
			get_user_origin(id,origin) 

			message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte(TE_SPRITE) 
			write_coord(origin[0]) 
			write_coord(origin[1]) 
			write_coord(origin[2]+=30) 
			write_short(g_heal) 
			write_byte(8) 
			write_byte(255) 
			message_end() 
		}
	}
}
	
public zp_user_infected_post(id, iInfector, nemesis)
{	
	//client_cmd(0, "spk ^"%s^"", zombie_infect[random( sizeof(zombie_infect))])
	
	new iKills[32], iType[32]
	new iReward = 100
	
	zp_cso_kill_time[iInfector] = 0
	zp_cso_kill_total[iInfector] += 1
	zp_cso_evokill[iInfector] += 1

	evolution(id, iInfector)
	sound_zombie(id)
	UpdateHealthZombie(id, iInfector)
	
	if(zp_cso_kill_lvl[iInfector] < zp_cso_maxkills)
	{
		zp_cso_kill_lvl[iInfector] += 1
		iKills[iInfector] = zp_cso_kill_lvl[iInfector]
		zp_cso_point_multiplier[iInfector] = iKills[iInfector]
		iType[iInfector] = 0
		
		zp_cso_announce_kill(iInfector, iKills[iInfector], iType[iInfector])
	}
	
	zp_cso_points[iInfector] += iReward * zp_cso_point_multiplier[iInfector]
	
	if(zp_cso_kill_lvl[iInfector] == zp_cso_maxkills)
	{
		zp_cso_kill_lvl[iInfector] = 0
	}
	
	return PLUGIN_CONTINUE
}

public evolution(id, iInfector)
{
	if(!is_user_alive(iInfector))
		return
		
	if(!g_level[id]) g_level[id] = 1
	KillCount[iInfector]++
	if(KillCount[iInfector] == 3 && !zombiedeath2[id])
	{
		g_level[iInfector] = 2
		if(get_user_health(iInfector) < ZB_LV2_HEALTH)
		{
			set_user_health(iInfector, ZB_LV2_HEALTH)
			g_start_health[iInfector] = ZB_LV2_HEALTH
			set_user_armor(iInfector, ZB_LV2_ARMOR)
		}
		g_zombie_die[iInfector] = 0
		client_printc(iInfector, "!g[Zombie: The Hero] !tYou are Evolved to !gZombie Origin")
		
		client_cmd(0, "spk ^"%s^"", zombie_evolution)
		
		set_dhudmessage(85, 255, 85, -1.0, 0.70, 2, 4.0, 4.0, 0.05, 1.0)
		show_dhudmessage(iInfector, "%L", LANG_PLAYER, "NOTICE_EVOLVED", g_level[iInfector] = 2)
	}
	else if(KillCount[iInfector] == 6 && !zombiedeath2[id])
	{
		g_level[iInfector] = 3
		if(get_user_health(iInfector) < ZB_LV3_HEALTH)
		{
			set_user_health(iInfector, ZB_LV3_HEALTH)
			g_start_health[iInfector] = ZB_LV3_HEALTH
			set_user_armor(iInfector, ZB_LV3_ARMOR)
		}
		g_zombie_die[iInfector] = 0
		client_printc(iInfector, "!g[Zombie: The Hero] !tYou are Evolved to !gSuper Zombie")
		
		client_cmd(0, "spk ^"%s^"", zombie_evolution)
		
		set_dhudmessage(85, 255, 85, -1.0, 0.70, 2, 4.0, 4.0, 0.05, 1.0)
		show_dhudmessage(iInfector, "%L", LANG_PLAYER, "NOTICE_EVOLVED", g_level[iInfector] = 3)
	}
}

UpdateHealthZombie(id, iInfector)
{
	if(!zp_get_user_zombie(id)) return;
		
	new health, armor
	if(g_zombie_die[id])
	{
		health = g_start_health[id]
		if(darahkebuka(id)) health = health + 2450
		else health = health + 2000

		g_start_health[id] = health
		g_star_armor[id] = armor
		
		health = max(MIN_HEALTH_ZOMBIE, health)
		armor = max(MIN_ARMOR_ZOMBIE, armor)
		
		g_start_health[id] = health
		
		set_user_health(id, health)
		set_user_armor(id, armor)
	}
	else
	{
		if(zp_get_user_first_zombie(id) || first_zombi[id])
		{
			set_user_health(id, ZB_LV2_HEALTH)
			g_start_health[id] = ZB_LV2_HEALTH
			set_user_armor(id, ZB_LV2_ARMOR)
			g_level[id] = 2
			KillCount[id] = 3
		}
		else
		{
			if(darahkebuka(id)) g_start_health[id] = get_user_health(iInfector) + 1000
			else g_start_health[id] = get_user_health(iInfector)*4/5
			
			health = g_start_health[id]
			armor = g_star_armor[id]
			
			health = max(MIN_HEALTH_ZOMBIE, health)
			armor = max(MIN_ARMOR_ZOMBIE, armor)
			
			g_start_health[id] = health
			
			set_user_health(id, health)
			set_user_armor(id, armor)
		}
	}
}

public fw_Spawn_Post(id)
{
	if (is_user_alive(id) && !zp_get_user_zombie(id)) 
	{
		reset_valuee(id)
		ResetKills(id)
		first_zombi[id] = 0
	}
}

public fw_PlayerKilled(id)
{	
	if(zp_get_user_last_human(id) || zp_get_user_last_zombie(id))
	return
	
	g_zombie_die[id] ++
	zombiedeath2[id] = true
	first_zombi[id] = 0
}

public sound_zombie(id)
{
	if(zp_get_user_first_zombie(id) || first_zombi[id]) return;

	else if(!g_zombie_die[id])
	{
		client_cmd(0, "spk ^"%s^"", zombie_infect[random( sizeof(zombie_infect))])
		
		if(zth_get_zombie_class(id) == 1 || zth_get_zombie_class(id) == 3 || zth_get_zombie_class(id) == 5)
		{
			PlayEmitSound(id, zombie_jerit_male[random( sizeof(zombie_jerit_male))])
		}

		if(zth_get_zombie_class(id) == 0 || zth_get_zombie_class(id) == 2 || zth_get_zombie_class(id) == 4)
		{
			PlayEmitSound(id, zombie_jerit_female[random( sizeof(zombie_jerit_female))])
		}
	}
}
/*---------------------------------------------*
 [ ZP CSO Plugin Client Authorization Forward ]
*---------------------------------------------*/

public client_authorized(id) 
{
	if(get_pcvar_num(zp_cso_cvar_savetype) == 0)
	{
		get_user_ip( id, zp_cso_authid[id], charsmax( zp_cso_authid[]))
	}
	if(get_pcvar_num(zp_cso_cvar_savetype) == 1)
	{
		get_user_name( id, zp_cso_authid[id], charsmax( zp_cso_authid[]))
	}
	if(get_pcvar_num(zp_cso_cvar_savetype) == 2)
	{
		get_user_authid( id, zp_cso_authid[id], charsmax( zp_cso_authid[]))
	}
}

/*---------------------------------------------*
 [ ZP CSO Plugin Client Put In Server Forward ]
*---------------------------------------------*/
	
public client_putinserver(id) 
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
	
	zp_cso_auto_on(id)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Client Connected Forward ]
*---------------------------------------------*/

public client_connect(id) 
{
	zp_cso_points[id] = 0
	zp_cso_kill_total[id] = 0
	
	zp_cso_load(id)
	reset_valuee(id)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Client Disconnected Forward ]
*---------------------------------------------*/

public client_disconnect(id) 
{
	zp_cso_save(id)
	
	zp_cso_points[id] = 0
	zp_cso_kill_total[id] = 0
}

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Public Functions ]
*------------------------------------------------------------------------------------------*/


/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Zombie Respawn Effect ]
*---------------------------------------------*/

public zp_zbrespawn(iVictim)
{		
	if (zp_cso_roundstarted == 0 || !is_user_connected(iVictim) || is_user_alive(iVictim))
		return PLUGIN_CONTINUE

	zp_effect_respawn(iVictim)
	set_task(2.0, "zp_zbrespawn", iVictim)
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Zombie Respawn Message ]
*---------------------------------------------*/

public zp_zbrespawn_msg(iVictim)
{
	if (zp_cso_roundstarted == 0 || !is_user_connected(iVictim))
		return PLUGIN_CONTINUE
		
	new iText[64]

	format(iText, charsmax(iText), "%L", LANG_PLAYER, "ZP_CSO_ZOMBIERESPAWN_MSG", zp_cso_respawnwait[iVictim])
	zp_clientcenter_text(iVictim, iText)
	
	zp_cso_respawnwait[iVictim] -= 1
	
	if(zp_cso_respawnwait[iVictim] >= 1)
	{
		set_task(1.0, "zp_zbrespawn_msg", iVictim)
	}
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Zombie Respawner ]
*---------------------------------------------*/

public zp_cso_zombie_respawner(iInfector)
{
	if(get_pcvar_num(zp_cso_cvar_enablerespawn) == 1)
	{
		new iSound, iSpeak[64]
		
		ExecuteHamB(Ham_CS_RoundRespawn, iInfector)
		
		iSound = random_num(0, charsmax(zp_cso_zombierespawn))
		copy(iSpeak, charsmax(iSpeak), zp_cso_zombierespawn[iSound])
		client_cmd(0, "speak ^"%s^"", iSpeak)
		
		zp_infect_user(iInfector)
		zp_cso_evolution(iInfector, g_level[iInfector])
	}
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Zombie Ambience ]
*---------------------------------------------*/

public zp_cso_ambience()
{
	new iMP3, MP3[64]
	
	iMP3 = random_num(0,charsmax(zp_cso_roundambience))
	copy(MP3, charsmax(MP3), zp_cso_roundambience[iMP3])
	
	client_cmd(0,"mp3 play ^"%s^"", MP3)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Zombie Countdown ]
*---------------------------------------------*/

public zp_cso_countdown()
{   	
	new iText[64]
	
	
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 20 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : I feel something is coming...")
	client_cmd(0, "spk zombie_plague/cso/message")
	
	
	set_task(1.0, "j")
	set_task(2.0, "k")
	set_task(3.0, "l")
	set_task(4.0, "m")
	set_task(5.0, "n")
	set_task(6.0, "o")
	set_task(7.0, "p")
	set_task(8.0, "q")
	set_task(9.0, "r")
	set_task(10.0, "countstart")
	set_task(11.0, "a")
	set_task(12.0, "b")
	set_task(13.0, "c")
	set_task(14.0, "d")
	set_task(15.0, "e")
	set_task(16.0, "f")
	set_task(17.0, "g")
	set_task(18.0, "h")
	set_task(19.0, "i")
}  

public j()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 19 Second(s)")
	zp_clientcenter_text(0, iText)
}

public k()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 18 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : Becareful, I see something in my radar...")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public l()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 17 Second(s)")
	zp_clientcenter_text(0, iText)
}

public m()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 16 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : Wait... What is this blood from?")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public n()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 15 Second(s)")
	zp_clientcenter_text(0, iText)
}

public o()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 14 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : Ain't seen anything like this before..")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public p()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 13 Second(s)")
	zp_clientcenter_text(0, iText)
}

public q()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 12 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : Oh, this is gonna get bad...")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public r()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 11 Second(s)")
	zp_clientcenter_text(0, iText)
}

public countstart()
{
	new iText[64]
	client_cmd(0, "speak zombie_plague/cso/countdowns")
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 10 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : OH SHIT... GET BACK!")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public a()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 9 Second(s)")
	zp_clientcenter_text(0, iText)
}

public b()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 8 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : HERE THEY COME!")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public c()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 7 Second(s)")
	zp_clientcenter_text(0, iText)
}

public d()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 6 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : GET READY!")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public e()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 5 Second(s)")
	zp_clientcenter_text(0, iText)
}

public f()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 4 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(42, 255, 127, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : HEY! DON'T TOUCH THAT BLOOD!")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public g()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 3 Second(s)")
	zp_clientcenter_text(0, iText)
}

public h()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 2 Second(s)")
	zp_clientcenter_text(0, iText)
	
	set_dhudmessage(255, 42, 0, -1.0, 0.25, 0, 2.0, 2.0, 0.05, 0.05)
	show_dhudmessage(1, "CAPTAIN : DAMN IT! THEY ARE COMING!")
	client_cmd(0, "spk zombie_plague/cso/message")
}

public i()
{
	new iText[64]
	format(iText, charsmax(iText), "Remaining Time For Zombie Infection: 1 Second(s)")
	zp_clientcenter_text(0, iText)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Auto On Tasks ]
*---------------------------------------------*/

public zp_cso_auto_on(id)
{
	set_task(1.0,"zp_cso_hud_info", id, _, _, "b")
	set_task(1.0,"zp_check_kill_time", id, _, _, "b")
	
	if(!zp_cso_czbot)
	{
		set_task(0.1, "zp_cso_register_czbot", id)
	}
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: HUD Informer ]
*---------------------------------------------*/

public zp_cso_hud_info(id)
{
	new iMsg[600], zp_username[32][31], zp_dmg_lvl, zp_evo_lvl[32], zp_r, zp_g, zp_b
	
	zp_dmg_lvl = zp_cso_hmlvl
	zp_evo_lvl[id] = g_level[id]
	
	if (!is_user_alive(id)) 
	{
		zp_r = 0
		zp_g = 255
		zp_b = 0
	}
	else if(zp_get_user_zombie(id))
	{
		zp_r = zp_cso_zblvl_r[zp_evo_lvl[id]]
		zp_g = zp_cso_zblvl_g[zp_evo_lvl[id]]
		zp_b = zp_cso_zblvl_b[zp_evo_lvl[id]]
	}
	else
	{
		zp_r = zp_cso_hmlvl_r[zp_dmg_lvl]
		zp_g = zp_cso_hmlvl_g[zp_dmg_lvl]
		zp_b = zp_cso_hmlvl_b[zp_dmg_lvl]
	}
	
	get_user_name(id, zp_username[id], charsmax(zp_username))
	
	if(zp_get_user_zombie(id))
	{
		set_hudmessage( zp_r, zp_g, zp_b, -1.0, 0.82, 0, 6.0, 1.1, 0.0, 0.0, -1)
		format(iMsg, charsmax(iMsg), "EVOLUTION : LEVEL 1%%^n[--------------------]")
		if(g_level[id] == 2)
		{
			format(iMsg, charsmax(iMsg), "EVOLUTION : LEVEL 2%%^n[||||||||||----------]")
		} 
		if(g_level[id] == 3)
		{
			format(iMsg, charsmax(iMsg), "EVOLUTION : LEVEL 3%%^n[||||||||||||||||||||]")
		} 
	}
	else
	{
		set_hudmessage( zp_r, zp_g, zp_b, -1.0, 0.82, 0, 6.0, 1.1, 0.0, 0.0, -1)
		if(zp_cso_hmlvl == 0)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 0%%^n[--------------------]")
		} 
		if(zp_cso_hmlvl == 1)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 1%%^n[||------------------]")
		} 
		if(zp_cso_hmlvl == 2)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 2%%^n[||||----------------]")
		} 
		if(zp_cso_hmlvl == 3)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 3%%^n[||||||--------------]")
		} 
		if(zp_cso_hmlvl == 4)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 4%%^n[||||||||------------]")
		} 
		if(zp_cso_hmlvl == 5)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 5%%^n[||||||||||----------]")
		} 
		if(zp_cso_hmlvl == 6)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 6%%^n[||||||||||||--------]")
		} 
		if(zp_cso_hmlvl == 7)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 7%%^n[||||||||||||||------]")
		} 
		if(zp_cso_hmlvl == 8)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 8%%^n[||||||||||||||||----]")
		} 
		if(zp_cso_hmlvl == 9)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 9%%^n[||||||||||||||||||--]")
		} 
		if(zp_cso_hmlvl == 10)
		{
			format(iMsg, charsmax(iMsg), "MORALE BOOST : LEVEL 10%%^n[||||||||||||||||||||]")
		} 
	}
	ShowSyncHudMsg(id, zp_cso_hud_sync2, iMsg)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: KILL! Time Check ]
*---------------------------------------------*/

public zp_check_kill_time(id)
{
	if(zp_cso_kill_time[id] == zp_cso_kill_time_end)
	{
		zp_cso_kill_lvl[id] = 0
		
		return PLUGIN_CONTINUE
	}
	
	zp_cso_kill_time[id] += 1
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Stats Loader ]
*---------------------------------------------*/

public zp_cso_load(id)
{
	zp_cso_load_stats(id)
}

/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Stats Saver ]
*---------------------------------------------*/

public zp_cso_save(id)
{
	zp_cso_save_stats(id)
}

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Internal Functions ]
*------------------------------------------------------------------------------------------*/
/*---------------------------------------------*
 [ ZP CSO Plugin Public Functions: Register CZBots ]
*---------------------------------------------*/

public zp_cso_register_czbot(id)
{
	if (zp_cso_czbot || !is_user_connected(id) || !is_user_bot(id))
		return PLUGIN_CONTINUE
	
	zp_cso_czbot = true
	
	return PLUGIN_CONTINUE
}
/*---------------------------------------------*
 [ ZP CSO Plugin Internal Functions: HM Level Up Effect ]
*---------------------------------------------*/

zp_cso_damage_plus(Human, Damage_Plus)
{
	if (!is_user_alive(Human) || zp_get_user_zombie(Human)) 
		return PLUGIN_CONTINUE
		
	if(zp_cso_hmlvl == 0)
		return PLUGIN_CONTINUE
	
	new Float: zp_origin[3], zp_r, zp_g, zp_b, iSound, iSpeak[64]
	
	zp_r = zp_cso_hmlvl_r[Damage_Plus]
	zp_g = zp_cso_hmlvl_g[Damage_Plus]
	zp_b = zp_cso_hmlvl_b[Damage_Plus]
		
	pev(Human, pev_origin, zp_origin)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, zp_origin, 0)
	
	write_byte(TE_BEAMCYLINDER)
	
	engfunc(EngFunc_WriteCoord, zp_origin[0])
	engfunc(EngFunc_WriteCoord, zp_origin[1])
	engfunc(EngFunc_WriteCoord, zp_origin[2])
	engfunc(EngFunc_WriteCoord, zp_origin[0]) 
	engfunc(EngFunc_WriteCoord, zp_origin[1])
	engfunc(EngFunc_WriteCoord, zp_origin[2] + 100.0)
	
	write_short(zp_cso_lvlspr)
	
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(60)
	write_byte(0)
	write_byte(zp_r) 
	write_byte(zp_g) 
	write_byte(zp_b) 
	write_byte(200)
	write_byte(0) 
	
	message_end()
	
	iSound = random_num(0, charsmax(zp_cso_human_lvlup))
	copy(iSpeak, charsmax(iSpeak), zp_cso_human_lvlup[iSound])
	client_cmd(Human,"speak ^"%s^"", iSpeak)
	
	set_dhudmessage(255, 170, 0, -1.0, 0.25, 2, 3.0, 3.0, 0.0, 1.0)
	show_dhudmessage(Human, "%L", LANG_PLAYER, "ZP_CSO_DMG_LVLUP_NOTICE", Damage_Plus)
	
	zp_cso_setrendering(Human)
	zp_cso_setrendering(Human, kRenderFxGlowShell, zp_r, zp_g, zp_b, kRenderNormal, 0)
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Internal Functions: Respawn Effect ]
*---------------------------------------------*/

zp_effect_respawn(iVictim)
{
	static Float: zp_origin[3]
	
	pev(iVictim, pev_origin, zp_origin)
    
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	
	write_byte(TE_EXPLOSION)
	
	write_coord(floatround(zp_origin[0]))
	write_coord(floatround(zp_origin[1]))
	write_coord(floatround(zp_origin[2]))
	
	write_short(zp_cso_respawnspr)
	
	write_byte(10)
	write_byte(20)
	write_byte(14)
	
	message_end()
}

/*---------------------------------------------*
 [ ZP CSO Plugin Internal Functions: No Respawn Message ]
*---------------------------------------------*/

zp_zbrespawn_msg2(iVictim)
{
	if (zp_cso_roundstarted == 0 || !is_user_connected(iVictim) || is_user_alive(iVictim))
		return PLUGIN_CONTINUE
		
	new iText[64]

	format(iText, charsmax(iText), "%L", LANG_PLAYER, "ZP_CSO_ZOMBIERESPAWN_MSG2")
	zp_clientcenter_text(iVictim, iText)
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Internal Functions: KILL! Announcer ]
*---------------------------------------------*/

zp_cso_announce_kill(id, zp_kill_lvl, zp_kill_type)
{
	if (!is_user_alive(id)) 
		return PLUGIN_CONTINUE
		
	new iSpeak[64], iSound, iMsg[600], zp_r, zp_g, zp_b
		
	if(zp_kill_type == 0)
	{
		iSound = zp_kill_lvl - 1
		copy(iSpeak, charsmax(iSpeak), zp_cso_kill_sounds1[iSound])
		format(iMsg, 63,"%i %L", zp_kill_lvl, LANG_PLAYER, "ZP_CSO_KILL")
	}
	else if(zp_kill_type == 1)
	{
		iSound = zp_kill_type - 1
		copy(iSpeak, charsmax(iSpeak), zp_cso_kill_sounds2[iSound])
		format(iMsg, 63,"%i %L %L", zp_kill_lvl, LANG_PLAYER, "ZP_CSO_KILL", LANG_PLAYER, "ZP_CSO_KNIFE")
	}
	else if(zp_kill_type == 2)
	{
		iSound = zp_kill_type - 1
		copy(iSpeak, charsmax(iSpeak), zp_cso_kill_sounds2[iSound])
		format(iMsg, 63,"%i %L %L", zp_kill_lvl, LANG_PLAYER, "ZP_CSO_KILL", LANG_PLAYER, "ZP_CSO_GRENADE")
	}
	else if(zp_kill_type == 3)
	{
		iSound = zp_kill_type - 1
		copy(iSpeak, charsmax(iSpeak), zp_cso_kill_sounds2[iSound])
		format(iMsg, 63,"%i %L %L", zp_kill_lvl, LANG_PLAYER, "ZP_CSO_KILL", LANG_PLAYER, "ZP_CSO_HEADSHOT")
	}
	
	zp_r = zp_cso_kill_r[zp_kill_lvl]
	zp_g = zp_cso_kill_g[zp_kill_lvl]
	zp_b = zp_cso_kill_b[zp_kill_lvl]
	
	set_hudmessage(zp_r, zp_g, zp_b, -1.0, 0.30, 0, 6.0, 6.0, 0.1, 0.2, -1)
	ShowSyncHudMsg(id, zp_cso_hud_sync1, iMsg)
	client_cmd(id,"speak ^"%s^"", iSpeak)
	
	if(zp_cso_kill_lvl[id] == zp_cso_maxkills)
	{
		zp_cso_kill_lvl[id] = 0
	}
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Internal Functions: Zombie Evolution ]
*---------------------------------------------*/

zp_cso_evolution(iInfector, Evolution)
{
	if (!is_user_alive(iInfector) || !zp_get_user_zombie(iInfector)) 
		return PLUGIN_CONTINUE
		
	new zp_evo_hp, zp_evo_armor, iSound, iSpeak[64]
	
	zp_evo_hp = zp_get_zombie_maxhealth(iInfector) + str_to_num(zp_cso_evo_hp_lvl[Evolution])
	zp_evo_armor = str_to_num(zp_cso_evo_armor_lvl[Evolution])
	
	set_user_health(iInfector, zp_evo_hp)
	ExecuteForward(zp_cso_evohp_forward, zp_cso_forward_dummyresult, iInfector, zp_evo_hp)
	 
	set_user_armor(iInfector, zp_evo_armor)
	ExecuteForward(zp_cso_evo_armor_forward, zp_cso_forward_dummyresult, iInfector, zp_evo_armor)
	
	iSound = random_num(0, charsmax(zp_cso_zombie_lvlup))
		
	if(zp_cso_zblvl[iInfector] == 0)
		return PLUGIN_CONTINUE
		
	copy(iSpeak, charsmax(iSpeak), zp_cso_zombie_lvlup[iSound])
	client_cmd(iInfector, "speak ^"%s^"", iSpeak)
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Internal Functions: Load Stats ]
*---------------------------------------------*/

zp_cso_load_stats(id)
{
	new iKey[64], iData[256], iPlayerTotalPoints[32], iPlayerTotalKills[32]
	
	format(iKey, 63, "%s-zp40-csotheme", zp_cso_authid[id])
	nvault_get(zp_cso_vault, iKey, iData, 255)
	
	replace_all(iData, 255, "#", " ")
	parse(iData, iPlayerTotalPoints, 31, iPlayerTotalKills, 31)
	zp_cso_points[id] = str_to_num(iPlayerTotalPoints)
	zp_cso_kill_total[id] = str_to_num(iPlayerTotalKills)
	
	return PLUGIN_CONTINUE
}

/*---------------------------------------------*
 [ ZP CSO Plugin Internal Functions: Save Stats ]
*---------------------------------------------*/

zp_cso_save_stats(id)
{
	new iKey[64], iData[256]
	
	format(iKey, 63, "%s-zp40-csotheme", zp_cso_authid[id])
	format(iData,255,"%i#%i#",zp_cso_points[id], zp_cso_kill_total[id])
	nvault_set(zp_cso_vault, iKey, iData)
	
	return PLUGIN_CONTINUE
}

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Stocks ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Stocks: Center Text ]
*---------------------------------------------*/ 

stock zp_clientcenter_text(id, zp_message[])
{
	new dest
	if (id) dest = MSG_ONE
	else dest = MSG_ALL
	
	message_begin(dest, zp_center_textmsg, {0,0,0}, id)
	write_byte(4)
	write_string(zp_message)
	message_end()
}

/*---------------------------------------------*
 [ ZP CSO Plugin Stocks: Client Set Render ]
*---------------------------------------------*/

stock zp_cso_setrendering(Human, zp_fx = kRenderFxNone, zp_r = 255, zp_g = 255, zp_b = 255, zp_render = kRenderNormal, zp_amount = 16)
{
	static Float: zp_color[3]
	
	zp_color[0] = float(zp_r)
	zp_color[1] = float(zp_g)
	zp_color[2] = float(zp_b)
	
	set_pev(Human, pev_renderfx, zp_fx)
	set_pev(Human, pev_rendercolor, zp_color)
	set_pev(Human, pev_rendermode, zp_render)
	set_pev(Human, pev_renderamt, float(zp_amount))
}

/*------------------------------------------------------------------------------------------*
 [ ZP CSO Plugin Natives ]
*------------------------------------------------------------------------------------------*/

/*---------------------------------------------*
 [ ZP CSO Plugin Natives: Get Evo Health ]
*---------------------------------------------*/ 

public zp_cso_native_evohp(iInfector)
{
	new zp_evohp
	
	zp_evohp = zp_get_zombie_maxhealth(iInfector) + str_to_num(zp_cso_evo_hp_lvl[zp_cso_zblvl[iInfector]])
	
	return zp_evohp
}

/*---------------------------------------------*
 [ ZP CSO Plugin Natives: Get Evo Armor ]
*---------------------------------------------*/ 

public zp_cso_native_evo_armor(id)
{
	new zp_evo_armor
	
	zp_evo_armor = str_to_num(zp_cso_evo_armor_lvl[zp_cso_zblvl[id]])
	
	return zp_evo_armor
}


// tipp

public Start_MunculTip()
{
	g_TipTime = get_pcvar_num(g_Cvar_Tip)
	
	remove_task(TASK_COUNTDOWN)
	MunculTip()
}

public MunculTip()
{
	//if(zp_cso_roundstarted == 0)
	//	return
	
	static Transcript[24]
	switch(g_TipTime)
	{
		case 110: 
		{
			if(g_Transcript) 
			{
				formatex(Transcript, 23, "TRANSCRIPT_%i", 3, random_num(1, 3))
				Send_Transcript(3.0, {42, 255, 127}, 0, "%L", LANG_PLAYER, Transcript)
			}
		}
		case 70: 
		{
			if(g_Transcript) 
			{
				formatex(Transcript, 23, "TRANSCRIPT_%i", 3, random_num(1, 3))
				Send_Transcript(3.0, {42, 255, 127}, 0, "%L", LANG_PLAYER, Transcript)
			}
		}
		case 45: 
		{
			if(g_Transcript) 
			{
				formatex(Transcript, 23, "TRANSCRIPT_%i", 3, random_num(1, 3))
				Send_Transcript(3.0, {42, 255, 127}, 0, "%L", LANG_PLAYER, Transcript)
			}
		}
		case 15: 
		{
			if(g_Transcript) 
			{
				formatex(Transcript, 23, "TRANSCRIPT_%i", 4, random_num(1, 5))
				Send_Transcript(3.0, {255, 212, 42}, 0, "%L", LANG_PLAYER, Transcript)
			}
		}
	}	
	
	if(g_Countdown) g_TipTime--
	set_task(1.0, "MunculTip", TASK_COUNTDOWN)
}

public Send_Transcript(Float:Time, Colour[3], Emergency, const Text[], any:...)
{
	static szMsg[128]; vformat(szMsg, sizeof(szMsg) - 1, Text, 5)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue

		set_hudmessage(255, 42, 42, -1.0, 0.25, 0, 4.0, 4.0, 0.05, 1.0)
		ShowSyncHudMsg(i, g_Hud_Notice, szMsg)
		
		client_cmd(0, "spk zombie_plague/cso/message")
	}
}

stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	if(index == 0)
	{
		for(new i = 0; i < g_iMaxClients; i++)
		{
			if(!is_user_connected(i))
				continue
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i)
			write_byte(i)
			write_string(szMsg)
			message_end()
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, dmgtype)
{
	if(!is_user_connected(attacker) || !is_user_alive(attacker) || !is_user_connected(victim) || !is_user_alive(victim) )
	return
	
	if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker))
	{
		g_restore_health[victim] = 0
	}
}


public fw_PlayerTraceAttack(victim, attacker, Float:Damage, Float:direction[3], tracehandle, damagebits)
{
	if(!is_user_connected(attacker) || !is_user_alive(attacker) || !is_user_connected(victim) || !is_user_alive(victim) )
	return
	
	if(zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker))
	{
		g_restore_health[victim] = 0
	}
}

gRandomAlive(n)
{
	static Alive, id
	Alive = 0
	
	for (id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_alive(id) && !zp_get_user_zombie(id))
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
		if (is_user_connected(id) && is_user_alive(id) && !zp_get_user_zombie(id))
			Alive++
	}
	
	return Alive;
}

total_player()
{
	static Alive, id
	Alive = 0
	
	for (id = 1; id <= g_iMaxClients; id++)
	{
		if (is_user_connected(id) && is_user_alive(id))
			Alive++
	}
	
	return Alive;
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
