#include <amxmodx>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <fakemeta>
#include <nvault>
#include <dhudmessage>

#define PLUGIN "[ZBM]BuyMenu"
#define VERSION "2.0"
#define AUTHOR "Sonic Son'edit/heka/DEN67"

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4)

const PEV_ADDITIONAL_AMMO = pev_iuser1

const OFFSET_AWM_AMMO  = 377 
const OFFSET_SCOUT_AMMO = 378
const OFFSET_PARA_AMMO = 379
const OFFSET_FAMAS_AMMO = 380
const OFFSET_M3_AMMO = 381
const OFFSET_USP_AMMO = 382
const OFFSET_FIVESEVEN_AMMO = 383
const OFFSET_DEAGLE_AMMO = 384
const OFFSET_P228_AMMO = 385
const OFFSET_GLOCK_AMMO = 386
const OFFSET_FLASH_AMMO = 387
const OFFSET_HE_AMMO = 388
const OFFSET_SMOKE_AMMO = 389
const OFFSET_C4_AMMO = 390
const OFFSET_CLIPAMMO = 51
const OFFSET_TEAM = 114
const OFFSET_DEATHS = 444
const OFFSET_MONEY = 115

//wtf is unknown item ???	P228			unknown		he gren		xm1014		bomb		mac10		aug		smogegren		elites		fivesveen		ump45		krieg500			galil		famas		usp		glock			awp		mp5		m249		m3		m4a1		tmp		g3sg1		flashgren		deagle		krieg552	ak47		?	p90
new const AMMOOFFSET[] = { -1, OFFSET_P228_AMMO, -1, OFFSET_SCOUT_AMMO, OFFSET_HE_AMMO, OFFSET_M3_AMMO, OFFSET_C4_AMMO, OFFSET_USP_AMMO, OFFSET_FAMAS_AMMO, OFFSET_SMOKE_AMMO, OFFSET_GLOCK_AMMO, OFFSET_FIVESEVEN_AMMO, OFFSET_USP_AMMO, OFFSET_FAMAS_AMMO, OFFSET_FAMAS_AMMO, OFFSET_FAMAS_AMMO,
 OFFSET_USP_AMMO, OFFSET_GLOCK_AMMO, OFFSET_AWM_AMMO, OFFSET_GLOCK_AMMO, OFFSET_PARA_AMMO, OFFSET_M3_AMMO, OFFSET_FAMAS_AMMO, OFFSET_GLOCK_AMMO, OFFSET_SCOUT_AMMO, OFFSET_FLASH_AMMO, OFFSET_DEAGLE_AMMO, OFFSET_FAMAS_AMMO,  OFFSET_SCOUT_AMMO, -1, OFFSET_FIVESEVEN_AMMO }
			
const OFFSET_LINUX = 5 
const OFFSET_LINUX_WEAPONS = 4 

new const sound_buyammo[] = "items/9mmclip1.wav"

new g_maxplayers

const TASK_BUYTIME_END = 100;
const TASK_RESTORE_MONEY = 200;
const TASK_KILL_ASSIST = 300;

new cvar_zp_cs_h_income_cash_rate;
new cvar_zp_cs_z_income_cash_rate;
new cvar_zp_cs_n_income_cash_rate
new cvar_zp_cs_s_income_cash_rate
new cvar_zp_cs_startmoney;
new cvar_zp_cs_restartround;
new cvar_zp_cs_moneymax;
new cvar_zp_cs_moneymax_vip;
new cvar_zp_cs_money_killbonus
new cvar_zp_cs_infectmoneybonus
new cvar_zp_cs_nemesis_canbuy
new cvar_zp_cs_survivor_canbuy
	
new cvar_zp_cs_zombie_nodeathscore

new Float: zp_cs_h_income_cash_rate;
new Float: zp_cs_z_income_cash_rate;
new Float: zp_cs_n_income_cash_rate
new Float: zp_cs_s_income_cash_rate
new zp_cs_moneymax;
new zp_cs_moneymax_vip;
new zp_cs_player_money[33]
new zp_cs_player_moneybonus[33]
new Float: zp_cs_damage[33][33] //[attacker][victim]

new g_MsgMoney, g_msgMoneyBlink, g_msgScoreInfo
new PlayerOldName[33][32]

new zp_cs_buymenu;	
new zp_cs_submenuid[33];
new zp_cs_buymenu_pistol;
new zp_cs_buymenu_shotgun;
new zp_cs_buymenu_smgun;
new zp_cs_buymenu_rifle;
new zp_cs_buymenu_biggun;
new zp_cs_buymenu_knife;
new zp_cs_buymenu_equiph;
new zp_cs_buymenu_equipz;

new zp_cs_buymenu_ready;

new cvar_zp_cs_buymenu_pistol_name[20]; 
new cvar_zp_cs_buymenu_pistol_cost[20]; 
new cvar_zp_cs_buymenu_pistol_todo[20]; 
new cvar_zp_cs_buymenu_shotgun_name[20];
new cvar_zp_cs_buymenu_shotgun_cost[20]; 
new cvar_zp_cs_buymenu_shotgun_todo[20];
new cvar_zp_cs_buymenu_smgun_name[20]; 
new cvar_zp_cs_buymenu_smgun_cost[20];
new cvar_zp_cs_buymenu_smgun_todo[20];
new cvar_zp_cs_buymenu_rifle_name[20]; 
new cvar_zp_cs_buymenu_rifle_cost[20];
new cvar_zp_cs_buymenu_rifle_todo[20];
new cvar_zp_cs_buymenu_biggun_name[20]; 
new cvar_zp_cs_buymenu_biggun_cost[20];
new cvar_zp_cs_buymenu_biggun_todo[20];
new cvar_zp_cs_buymenu_equiph_name[20]; 
new cvar_zp_cs_buymenu_equiph_cost[20];
new cvar_zp_cs_buymenu_equiph_todo[20];
new cvar_zp_cs_buymenu_equipz_name[20]; 
new cvar_zp_cs_buymenu_equipz_cost[20];
new cvar_zp_cs_buymenu_equipz_todo[20];
new g_Ham_Bot
 
public plugin_precache()
{
	precache_sound(sound_buyammo)
}
 
public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR)
	
	register_dictionary("zbm_buymenu.txt")
	
	g_MsgMoney = get_user_msgid("Money")
	g_msgMoneyBlink = get_user_msgid("BlinkAcct")
	g_msgScoreInfo = get_user_msgid("ScoreInfo")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage")
	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled")
	
	register_forward(FM_ClientConnect, "fw_ClientConnect_Post",1)
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect")

	register_clcmd("xbuy", "clcmd_zp_cs_buymenu") 
	register_clcmd("xbuyequip", "clcmd_zp_cs_buymenu") 
	register_clcmd("xzp_cs_buymenu", "clcmd_zp_cs_buymenu") 
	
	cvar_zp_cs_h_income_cash_rate = register_cvar("zp_cs_human_income_cash_rate", "2.0")
	cvar_zp_cs_z_income_cash_rate = register_cvar("zp_cs_zombie_income_cash_rate", "5.0")
	cvar_zp_cs_n_income_cash_rate = register_cvar("zp_cs_nemesis_income_cash_rate", "0.5")
	cvar_zp_cs_s_income_cash_rate = register_cvar("zp_cs_survivor_income_cash_rate", "0.2")
	cvar_zp_cs_moneymax = register_cvar("zp_cs_moneymax", "16000")
	cvar_zp_cs_moneymax_vip = register_cvar("zp_cs_moneymax_vip", "16000")
	cvar_zp_cs_infectmoneybonus = register_cvar("zp_cs_infectmoneybonus", "1500")
	cvar_zp_cs_money_killbonus = register_cvar("zp_cs_money_killbonus", "1000")
	cvar_zp_cs_startmoney = get_cvar_pointer("mp_startmoney")
	cvar_zp_cs_restartround = get_cvar_pointer("sv_restartround")
	cvar_zp_cs_nemesis_canbuy = register_cvar("zp_cs_nemesis_canbuy", "0")
	cvar_zp_cs_survivor_canbuy = register_cvar("zp_cs_survivor_canbuy", "0")
	
	cvar_zp_cs_zombie_nodeathscore = register_cvar("zp_cs_zombie_nodeathscore", "1");

	g_maxplayers = get_maxplayers()	
	
	for (new id=1;id<=g_maxplayers;id++)
	{
		zp_cs_player_moneybonus[id]=0;
		zp_cs_player_money[id]=get_pcvar_num(cvar_zp_cs_startmoney)
	}
	
	zp_cs_buymenu_ready = false;
	
	new strtemp[2]; 
	new strtemp2[32];
	for(new i=0;i<20;i++)
	{
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_pistol___name";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_pistol_name[i] = register_cvar(strtemp2, "-");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_pistol___cost";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_pistol_cost[i] = register_cvar(strtemp2, "0");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_pistol___todo";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_pistol_todo[i] = register_cvar(strtemp2, "do_nothing");
	}
	for(new i=0;i<20;i++)
	{
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_shotgun___name";
		if (i>8) 
		{
			strtemp2[21]=strtemp[0];
			strtemp2[22]=strtemp[1];
		}
		else
		{
			strtemp2[21]='0';
			strtemp2[22]=strtemp[0];
		}
		cvar_zp_cs_buymenu_shotgun_name[i] = register_cvar(strtemp2, "-");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_shotgun___cost";
		if (i>8) 
		{
			strtemp2[21]=strtemp[0];
			strtemp2[22]=strtemp[1];
		}
		else
		{
			strtemp2[21]='0';
			strtemp2[22]=strtemp[0];
		}
		cvar_zp_cs_buymenu_shotgun_cost[i] = register_cvar(strtemp2, "0");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_shotgun___todo";
		if (i>8) 
		{
			strtemp2[21]=strtemp[0];
			strtemp2[22]=strtemp[1];
		}
		else
		{
			strtemp2[21]='0';
			strtemp2[22]=strtemp[0];
		}
		cvar_zp_cs_buymenu_shotgun_todo[i] = register_cvar(strtemp2, "do_nothing");
	}
	for(new i=0;i<20;i++)
	{
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_smgun___name";
		if (i>8) 
		{
			strtemp2[19]=strtemp[0];
			strtemp2[20]=strtemp[1];
		}
		else
		{
			strtemp2[19]='0';
			strtemp2[20]=strtemp[0];
		}
		cvar_zp_cs_buymenu_smgun_name[i] = register_cvar(strtemp2, "-");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_smgun___cost";
		if (i>8) 
		{
			strtemp2[19]=strtemp[0];
			strtemp2[20]=strtemp[1];
		}
		else
		{
			strtemp2[19]='0';
			strtemp2[20]=strtemp[0];
		}
		cvar_zp_cs_buymenu_smgun_cost[i] = register_cvar(strtemp2, "0");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_smgun___todo";
		if (i>8) 
		{
			strtemp2[19]=strtemp[0];
			strtemp2[20]=strtemp[1];
		}
		else
		{
			strtemp2[19]='0';
			strtemp2[20]=strtemp[0];
		}
		cvar_zp_cs_buymenu_smgun_todo[i] = register_cvar(strtemp2, "do_nothing");
	}
	for(new i=0;i<20;i++)
	{
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_rifle___name";
		if (i>8) 
		{
			strtemp2[19]=strtemp[0];
			strtemp2[20]=strtemp[1];
		}
		else
		{
			strtemp2[19]='0';
			strtemp2[20]=strtemp[0];
		}
		cvar_zp_cs_buymenu_rifle_name[i] = register_cvar(strtemp2, "-");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_rifle___cost";
		if (i>8) 
		{
			strtemp2[19]=strtemp[0];
			strtemp2[20]=strtemp[1];
		}
		else
		{
			strtemp2[19]='0';
			strtemp2[20]=strtemp[0];
		}
		cvar_zp_cs_buymenu_rifle_cost[i] = register_cvar(strtemp2, "0");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_rifle___todo";
		if (i>8) 
		{
			strtemp2[19]=strtemp[0];
			strtemp2[20]=strtemp[1];
		}
		else
		{
			strtemp2[19]='0';
			strtemp2[20]=strtemp[0];
		}
		cvar_zp_cs_buymenu_rifle_todo[i] = register_cvar(strtemp2, "do_nothing");
	}
	for(new i=0;i<20;i++)
	{
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_biggun___name";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_biggun_name[i] = register_cvar(strtemp2, "-");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_biggun___cost";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_biggun_cost[i] = register_cvar(strtemp2, "0");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_biggun___todo";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_biggun_todo[i] = register_cvar(strtemp2, "do_nothing");
	}
	for(new i=0;i<20;i++)
	{
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_equiph___name";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_equiph_name[i] = register_cvar(strtemp2, "-");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_equiph___cost";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_equiph_cost[i] = register_cvar(strtemp2, "0");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_equiph___todo";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_equiph_todo[i] = register_cvar(strtemp2, "do_nothing");
	}
	for(new i=0;i<20;i++)
	{
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_equipz___name";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_equipz_name[i] = register_cvar(strtemp2, "-");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_equipz___cost";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_equipz_cost[i] = register_cvar(strtemp2, "0");
		num_to_str(i+1, strtemp, 2)
		strtemp2 = "zp_cs_buymenu_equipz___todo";
		if (i>8) 
		{
			strtemp2[20]=strtemp[0];
			strtemp2[21]=strtemp[1];
		}
		else
		{
			strtemp2[20]='0';	
			strtemp2[21]=strtemp[0];
		}
		cvar_zp_cs_buymenu_equipz_todo[i] = register_cvar(strtemp2, "do_nothing");
	}
}

public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "ham_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "ham_TakeDamage")
	RegisterHamFromEntity(Ham_Killed, id, "ham_PlayerKilled")
}

public plugin_natives()
{
	register_native("zp_cs_get_user_money", "native_get_user_money", 1)
	register_native("zp_cs_set_user_money", "native_set_user_money", 1)
}

public plugin_cfg()
{
	new cfgdir[32]
	get_localinfo("amxx_configsdir",cfgdir,sizeof cfgdir)
	server_cmd("exec %s/zbm_buymenu.cfg", cfgdir)
	build_menu;
}

public fw_ClientConnect_Post(id)
{
 	get_user_name(id,PlayerOldName[id],31)
	if (zp_cs_player_moneybonus[id])
	{
		zp_cs_player_money[id]+=zp_cs_player_moneybonus[id]
		zp_cs_player_moneybonus[id]=0
	}
	if (zp_cs_player_money[id]<get_pcvar_num(cvar_zp_cs_startmoney)) zp_cs_player_money[id]=get_pcvar_num(cvar_zp_cs_startmoney)
	return FMRES_IGNORED;
}

public event_round_start(id)
{
	zp_cs_buymenu_ready = false;

	zp_cs_moneymax = get_pcvar_num(cvar_zp_cs_moneymax);
	zp_cs_moneymax_vip = get_pcvar_num(cvar_zp_cs_moneymax_vip);
	zp_cs_h_income_cash_rate = get_pcvar_float(cvar_zp_cs_h_income_cash_rate)
	zp_cs_z_income_cash_rate = get_pcvar_float(cvar_zp_cs_z_income_cash_rate)
	zp_cs_n_income_cash_rate = get_pcvar_float(cvar_zp_cs_n_income_cash_rate)
	zp_cs_s_income_cash_rate = get_pcvar_float(cvar_zp_cs_s_income_cash_rate)

	set_task(0.1, "build_menu");
}

public zp_round_ended(winteam)
{		
	if(get_pcvar_num(cvar_zp_cs_restartround))
	{
		for(new id=1;id<=g_maxplayers;id++)
		{
			zp_cs_player_moneybonus[id] = 0
			zp_cs_player_money[id]=get_pcvar_num(cvar_zp_cs_startmoney)

			return PLUGIN_CONTINUE
		}
	}

	
	return PLUGIN_CONTINUE
}


public update_scoreboard(id)
{		
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(id)
		write_short(pev(id, pev_frags))
		write_short(get_pdata_int(id, OFFSET_DEATHS, OFFSET_LINUX))
		write_short(0)
		write_short(get_pdata_int(id, OFFSET_TEAM, OFFSET_LINUX))
		message_end()
}

public build_menu()
{
	if (zp_cs_buymenu_ready)
	{
		menu_destroy(zp_cs_buymenu)
		menu_destroy(zp_cs_buymenu_pistol)
		menu_destroy(zp_cs_buymenu_shotgun)
		menu_destroy(zp_cs_buymenu_smgun)
		menu_destroy(zp_cs_buymenu_rifle)
		menu_destroy(zp_cs_buymenu_biggun)
		menu_destroy(zp_cs_buymenu_equiph)
		menu_destroy(zp_cs_buymenu_equipz)
		menu_destroy(zp_cs_buymenu_knife)
	}
		
	//register menus
	zp_cs_buymenu = menu_create("\ySERVER: [CSO]", "zp_cs_buymenu_handle")	
	zp_cs_buymenu_pistol = menu_create("Пистолеты", "zp_cs_subbuymenu_handle")	
	zp_cs_buymenu_shotgun = menu_create("Дробовики", "zp_cs_subbuymenu_handle")	
	zp_cs_buymenu_smgun = menu_create("Автоматы", "zp_cs_subbuymenu_handle")	
	zp_cs_buymenu_rifle = menu_create("Винтовки", "zp_cs_subbuymenu_handle")	
	zp_cs_buymenu_biggun = menu_create("Пулеметы", "zp_cs_subbuymenu_handle")
	zp_cs_buymenu_knife = menu_create("Выбрать нож", "zp_cs_subbuymenu_handle")	
	zp_cs_buymenu_equiph = menu_create("\rОбмундирование (Человек)", "zp_cs_subbuymenu_handle")	
	zp_cs_buymenu_equipz = menu_create("\rОбмундирование (Зомби)", "zp_cs_subbuymenu_handle")	
	new callback_rifles = menu_makecallback ("call_rifles")	
	new strtemp0[100];
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_PISTOLS")
	menu_additem(zp_cs_buymenu, strtemp0, "1", _, callback_rifles);
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_SHOTGUNS")
	menu_additem(zp_cs_buymenu, strtemp0, "2", _, callback_rifles);
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_AUTO")
	menu_additem(zp_cs_buymenu, strtemp0, "3", _, callback_rifles);
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_RIFLE")
	menu_additem(zp_cs_buymenu, strtemp0, "4", _, callback_rifles);
	formatex(strtemp0, charsmax(strtemp0), "%L^n", LANG_PLAYER, "ZBM_MAIN_MACHINE")
	menu_additem(zp_cs_buymenu, strtemp0, "5", _, callback_rifles);
	
	formatex(strtemp0, charsmax(strtemp0), "%L^n", LANG_PLAYER, "ZBM_MAIN_EXTRA")
	menu_additem(zp_cs_buymenu, strtemp0, "8");
		
	formatex(strtemp0, charsmax(strtemp0), "%L^n", LANG_PLAYER, "ZBM_MAIN_KNIFES")
	menu_additem(zp_cs_buymenu, strtemp0, "7", _, callback_rifles);

	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_EXIT")
	menu_additem(zp_cs_buymenu, strtemp0, "0");
	menu_setprop(zp_cs_buymenu, MPROP_PERPAGE, 0);
	menu_setprop(zp_cs_buymenu, MPROP_NUMBER_COLOR, "\y");

	
	new strtemp[100]; 
	new strtemp2[100];
	new strtemp3[100];
	for(new i=0;i<20;i++)
	{
		get_pcvar_string(cvar_zp_cs_buymenu_pistol_name[i], strtemp , 32)
		if (strtemp[0] != '-')
		{
			get_pcvar_string(cvar_zp_cs_buymenu_pistol_todo[i], strtemp3 , 32)
			
			num_to_str(get_pcvar_num(cvar_zp_cs_buymenu_pistol_cost[i]), strtemp2, 32) 

			add(strtemp,sizeof strtemp, "\y",4)
			add(strtemp,sizeof strtemp, strtemp2, sizeof strtemp2)
			menu_additem(zp_cs_buymenu_pistol, strtemp, strtemp3)
		}
	}	
	menu_setprop(zp_cs_buymenu_pistol, MPROP_NUMBER_COLOR, "\y");
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_BACK")
	menu_setprop(zp_cs_buymenu_pistol, MPROP_BACKNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_MORE")
	menu_setprop(zp_cs_buymenu_pistol, MPROP_NEXTNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_EXIT")
	menu_setprop(zp_cs_buymenu_pistol, MPROP_EXITNAME, strtemp0)
	for(new i=0;i<20;i++)
	{
		get_pcvar_string(cvar_zp_cs_buymenu_shotgun_name[i], strtemp , 32)
		if (strtemp[0] != '-')
		{
			get_pcvar_string(cvar_zp_cs_buymenu_shotgun_todo[i], strtemp3 , 32)
			
			num_to_str(get_pcvar_num(cvar_zp_cs_buymenu_shotgun_cost[i]), strtemp2, 32)

			add(strtemp,sizeof strtemp, "\y",4)
			add(strtemp,sizeof strtemp, strtemp2, sizeof strtemp2)
			menu_additem(zp_cs_buymenu_shotgun, strtemp, strtemp3)
		}
	}	
	menu_setprop(zp_cs_buymenu_shotgun, MPROP_NUMBER_COLOR, "\y");
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_BACK")
	menu_setprop(zp_cs_buymenu_shotgun, MPROP_BACKNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_MORE")
	menu_setprop(zp_cs_buymenu_shotgun, MPROP_NEXTNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_EXIT")
	menu_setprop(zp_cs_buymenu_shotgun, MPROP_EXITNAME, strtemp0)
	for(new i=0;i<20;i++)
	{
		get_pcvar_string(cvar_zp_cs_buymenu_smgun_name[i], strtemp , 32)
		if (strtemp[0] != '-')
		{
			get_pcvar_string(cvar_zp_cs_buymenu_smgun_todo[i], strtemp3 , 32)
			
			num_to_str(get_pcvar_num(cvar_zp_cs_buymenu_smgun_cost[i]), strtemp2, 32)

			add(strtemp,sizeof strtemp, "\y",4)
			add(strtemp,sizeof strtemp, strtemp2, sizeof strtemp2)
			menu_additem(zp_cs_buymenu_smgun, strtemp, strtemp3)
		}
	}	
	menu_setprop(zp_cs_buymenu_smgun, MPROP_NUMBER_COLOR, "\y");
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_BACK")
	menu_setprop(zp_cs_buymenu_smgun, MPROP_BACKNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_MORE")
	menu_setprop(zp_cs_buymenu_smgun, MPROP_NEXTNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_EXIT")
	menu_setprop(zp_cs_buymenu_smgun, MPROP_EXITNAME, strtemp0)
	for(new i=0;i<20;i++)
	{
		get_pcvar_string(cvar_zp_cs_buymenu_rifle_name[i], strtemp , 32)
		if (strtemp[0] != '-')
		{
			get_pcvar_string(cvar_zp_cs_buymenu_rifle_todo[i], strtemp3 , 32)
			
			num_to_str(get_pcvar_num(cvar_zp_cs_buymenu_rifle_cost[i]), strtemp2, 32)

			add(strtemp,sizeof strtemp, "\y",4)
			add(strtemp,sizeof strtemp, strtemp2, sizeof strtemp2)
			menu_additem(zp_cs_buymenu_rifle, strtemp, strtemp3)
		}
	}	
	menu_setprop(zp_cs_buymenu_rifle, MPROP_NUMBER_COLOR, "\y");
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_BACK")
	menu_setprop(zp_cs_buymenu_rifle, MPROP_BACKNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_MORE")
	menu_setprop(zp_cs_buymenu_rifle, MPROP_NEXTNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_EXIT")
	menu_setprop(zp_cs_buymenu_rifle, MPROP_EXITNAME, strtemp0)
	for(new i=0;i<20;i++)
	{
		get_pcvar_string(cvar_zp_cs_buymenu_biggun_name[i], strtemp , 32)
		if (strtemp[0] != '-')
		{
			get_pcvar_string(cvar_zp_cs_buymenu_biggun_todo[i], strtemp3 , 32)

			num_to_str(get_pcvar_num(cvar_zp_cs_buymenu_biggun_cost[i]), strtemp2, 32)

			add(strtemp,sizeof strtemp, "\y",4)
			add(strtemp,sizeof strtemp, strtemp2, sizeof strtemp2)
			menu_additem(zp_cs_buymenu_biggun, strtemp, strtemp3)
		}
	}	
	menu_setprop(zp_cs_buymenu_biggun, MPROP_NUMBER_COLOR, "\y");
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_BACK")
	menu_setprop(zp_cs_buymenu_biggun, MPROP_BACKNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_MORE")
	menu_setprop(zp_cs_buymenu_biggun, MPROP_NEXTNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_EXIT")
	menu_setprop(zp_cs_buymenu_biggun, MPROP_EXITNAME, strtemp0)
	for(new i=0;i<20;i++)
	{
		get_pcvar_string(cvar_zp_cs_buymenu_equiph_name[i], strtemp , 32)
		if (strtemp[0] != '-')
		{
			get_pcvar_string(cvar_zp_cs_buymenu_equiph_todo[i], strtemp3 , 32)
			num_to_str(get_pcvar_num(cvar_zp_cs_buymenu_equiph_cost[i]), strtemp2, 32)

			add(strtemp,sizeof strtemp, "\y",4)
			add(strtemp,sizeof strtemp, strtemp2, sizeof strtemp2)
			menu_additem(zp_cs_buymenu_equiph, strtemp, strtemp3)
		}
	}	

	menu_setprop(zp_cs_buymenu_equiph, MPROP_NUMBER_COLOR, "\y");
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_BACK")
	menu_setprop(zp_cs_buymenu_equiph, MPROP_BACKNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_MORE")
	menu_setprop(zp_cs_buymenu_equiph, MPROP_NEXTNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_EXIT")
	menu_setprop(zp_cs_buymenu_equiph, MPROP_EXITNAME, strtemp0)
	for(new i=0;i<20;i++)
	{
		get_pcvar_string(cvar_zp_cs_buymenu_equipz_name[i], strtemp , 32)
		if (strtemp[0] != '-')
		{
			get_pcvar_string(cvar_zp_cs_buymenu_equipz_todo[i], strtemp3 , 32)
			num_to_str(get_pcvar_num(cvar_zp_cs_buymenu_equipz_cost[i]), strtemp2, 32)
			add(strtemp,sizeof strtemp, "\y",4)
			add(strtemp,sizeof strtemp, strtemp2, sizeof strtemp2)
			menu_additem(zp_cs_buymenu_equipz, strtemp, strtemp3)
		}
	}	
	menu_setprop(zp_cs_buymenu_equipz, MPROP_NUMBER_COLOR, "\y");
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_BACK")
	menu_setprop(zp_cs_buymenu_equipz, MPROP_BACKNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_MORE")
	menu_setprop(zp_cs_buymenu_equipz, MPROP_NEXTNAME, strtemp0)
	formatex(strtemp0, charsmax(strtemp0), "%L", LANG_PLAYER, "ZBM_MAIN_EXIT")
	menu_setprop(zp_cs_buymenu_equipz, MPROP_EXITNAME, strtemp0)
		
	zp_cs_buymenu_ready=true;
}

public call_rifles(id, menu, item)
{
	return (!zp_has_round_started () ) ? ITEM_ENABLED : ITEM_DISABLED
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)

	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			static wname[32], weapon_ent
			get_weaponname(weaponid, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, id);
			
			set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, fm_get_user_bpammo(id, weaponid))
			
			engclient_cmd(id, "drop", wname)
			fm_set_user_bpammo(id, weaponid, 0)
		}
	}
}

stock fm_get_user_bpammo(id, weapon)
{
	return get_pdata_int(id, AMMOOFFSET[weapon], OFFSET_LINUX);
}

stock fm_set_user_bpammo(id, weapon, amount)
{
	set_pdata_int(id, AMMOOFFSET[weapon], amount, OFFSET_LINUX)
}
 
public clcmd_zp_cs_buymenu(id)
{
	if (!is_user_alive(id)) 
		return PLUGIN_HANDLED;
		
	if ((zp_get_user_nemesis(id))&&(!get_pcvar_num(cvar_zp_cs_nemesis_canbuy)))
	{
		client_print(id,print_center,"%L", LANG_PLAYER, "BUYMENU_CANTBUY_NEMESIS")
		return PLUGIN_HANDLED;
	}
	if ((zp_get_user_survivor(id))&&(!get_pcvar_num(cvar_zp_cs_survivor_canbuy)))
	{
		client_print(id,print_center,"%L", LANG_PLAYER, "BUYMENU_CANTBUY_SURVIVOR")
		return PLUGIN_HANDLED;
	}
	if (zp_cs_buymenu_ready) 
		menu_display(id, zp_cs_buymenu)
	
	return PLUGIN_HANDLED;
}

public  zp_cs_buymenu_handle(id, menu, item)
{
	new cmd[32];
	new access, callback;
	menu_item_getinfo(menu, item, access, cmd,2,_,_, callback);
	zp_cs_submenuid[id] = str_to_num(cmd);
	
	if (zp_cs_submenuid[id] == 0) 
		return PLUGIN_HANDLED;
	
	if ((zp_get_user_zombie(id))&&(zp_cs_submenuid[id] != 8))
	{
		client_print(id,print_center,"%L", LANG_PLAYER, "BUYMENU_ONLY_HUMAH");
		return PLUGIN_HANDLED;
	}
	
	if (zp_cs_submenuid[id] == 1) 
		menu_display(id, zp_cs_buymenu_pistol, 0); 
	if (zp_cs_submenuid[id] == 2) 
		menu_display(id, zp_cs_buymenu_shotgun, 0); 
	if (zp_cs_submenuid[id] == 3) 
		menu_display(id, zp_cs_buymenu_smgun, 0); 
	if (zp_cs_submenuid[id] == 4) 
		menu_display(id, zp_cs_buymenu_rifle, 0); 
	if (zp_cs_submenuid[id] == 5) 
		menu_display(id, zp_cs_buymenu_biggun, 0); 
	if (zp_cs_submenuid[id] == 8)
	if (zp_get_user_zombie(id))
	{
		zp_cs_submenuid[id] = 82 
		menu_display(id, zp_cs_buymenu_equipz, 0); 
	}
	else
	{
		zp_cs_submenuid[id] = 81 
		menu_display(id, zp_cs_buymenu_equiph, 0);
	}
	if (zp_cs_submenuid[id] == 7) 
		menu_display(id, zp_cs_buymenu_knife, 0); 
	if (zp_cs_submenuid[id] == 7)
	{
		client_cmd(id, "say /knife")
	}
	
	return PLUGIN_HANDLED;
}
	

public  zp_cs_subbuymenu_handle(id, menu, item)
{
	new cmd[32]; 
	cmd [0] = '-';
	new access, callback;
 
	menu_item_getinfo(menu, item, access, cmd, charsmax(cmd),_,_, callback); 
	
	if (cmd[0]=='-') return PLUGIN_HANDLED;
 
	new strtemp[100]; 
	new itemcost;
	
	if (strfind(cmd, "do_nothing") != 0) 
	for (new i=0;i<20;i++) 
	{	
		if (zp_cs_submenuid[id] == 1)
			get_pcvar_string(cvar_zp_cs_buymenu_pistol_todo[i], strtemp , 32)
	 	if (zp_cs_submenuid[id] == 2)
			get_pcvar_string(cvar_zp_cs_buymenu_shotgun_todo[i], strtemp , 32)
	 	if (zp_cs_submenuid[id] == 3)
			get_pcvar_string(cvar_zp_cs_buymenu_smgun_todo[i], strtemp , 32)
	 	if (zp_cs_submenuid[id] == 4)
			get_pcvar_string(cvar_zp_cs_buymenu_rifle_todo[i], strtemp , 32)
	 	if (zp_cs_submenuid[id] == 5)
			get_pcvar_string(cvar_zp_cs_buymenu_biggun_todo[i], strtemp , 32)
	 	if (zp_cs_submenuid[id] == 81)
			get_pcvar_string(cvar_zp_cs_buymenu_equiph_todo[i], strtemp , 32)
	 	if (zp_cs_submenuid[id] == 82)
			get_pcvar_string(cvar_zp_cs_buymenu_equipz_todo[i], strtemp , 32)
			
		if (strfind(cmd, strtemp) == 0)
		{					
			if (zp_cs_submenuid[id] == 1)
				itemcost = get_pcvar_num(cvar_zp_cs_buymenu_pistol_cost[i])
			if (zp_cs_submenuid[id] == 2)
				itemcost = get_pcvar_num(cvar_zp_cs_buymenu_shotgun_cost[i])
			if (zp_cs_submenuid[id] == 3)
				itemcost = get_pcvar_num(cvar_zp_cs_buymenu_smgun_cost[i])
			if (zp_cs_submenuid[id] == 4)
				itemcost = get_pcvar_num(cvar_zp_cs_buymenu_rifle_cost[i])
			if (zp_cs_submenuid[id] == 5)
				itemcost = get_pcvar_num(cvar_zp_cs_buymenu_biggun_cost[i])
			if (zp_cs_submenuid[id] == 81)
				itemcost = get_pcvar_num(cvar_zp_cs_buymenu_equiph_cost[i])
			if (zp_cs_submenuid[id] == 82)
				itemcost = get_pcvar_num(cvar_zp_cs_buymenu_equipz_cost[i])
				
			if (zp_cs_player_money[id]  < itemcost) //check if player has enough money
			{
				message_begin(MSG_ONE_UNRELIABLE, g_msgMoneyBlink, _, id) //HUD
				write_byte(5);
				message_end();
				client_print(id,print_center,"%L", LANG_PLAYER, "ZBM_NOT")
				return PLUGIN_HANDLED;				
			}
			else break; 
		}
	}
			
	if (strfind(cmd, "zp_cs_buy") == 0) 
	{
		if ((user_has_weapon(id, CSW_HEGRENADE))&&(strfind(cmd, "zp_cs_buy_hegrenade") == 0))
			{
				if ((zp_get_user_zombie(id))||(zp_get_user_nemesis(id))) client_print(id,print_center,"%L", LANG_PLAYER, "BUYMENU_NOMORE_INFECTGREN")
					else client_print(id,print_center,"%L", LANG_PLAYER, "ZBM_MAX_FIRE")
				
				return PLUGIN_HANDLED;
			}
		if ((user_has_weapon(id, CSW_FLASHBANG))&&(strfind(cmd, "zp_cs_buy_flashbang") == 0))
			{
				client_print(id,print_center,"%L", LANG_PLAYER, "ZBM_MAX_FROST")
			
				return PLUGIN_HANDLED;
			}
		replace(cmd,charsmax(cmd),"zp_cs_buy_","weapon_")
		if ((strfind(cmd, "flashbang") == -1)&&(strfind(cmd, "hegrenade") == -1)&&(strfind(cmd, "smokegrenade") == -1)) 
			if  ((strfind(cmd, "glock18") > -1)||(strfind(cmd, "usp") > -1)||(strfind(cmd, "p228") > -1)||(strfind(cmd, "deagle") > -1)||(strfind(cmd, "elite") > -1)||(strfind(cmd, "fiveseven") > -1)) 
				drop_weapons(id, 2);
			else
				drop_weapons(id, 1);
			
		fm_give_item(id, cmd);
		replace(cmd,charsmax(cmd),"weapon_","zp_cs_buy_")
	}
	
	if (strfind(cmd, "zp_cs_") != 0) 
	{
		new temp_itemid=zp_get_extra_item_id(cmd);
		if (temp_itemid>-1)
			(zp_force_buy_extra_item(id,temp_itemid,1))
		else
		{
			client_print(id, print_chat, "ERROR! ITEM %s NOT FOUND!",cmd)
		}
	}
		
	if (strfind(cmd, "do_nothing") == 0) client_print(id, print_chat, "[zp_cs_buymenu]: This item does nothing.") 
	
	zp_cs_player_money[id] -= itemcost;
	message_begin(MSG_ONE_UNRELIABLE, g_MsgMoney, _, id)
	write_long(zp_cs_player_money[id]);
	write_byte(1);
	message_end();
		
	return PLUGIN_HANDLED;
}

public ham_PlayerSpawn_Post(id)
{
	if (!task_exists(id+TASK_RESTORE_MONEY)) set_task(0.5,"restore_player_money",id+TASK_RESTORE_MONEY)
}

public ham_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if ((attacker<1)||(attacker>g_maxplayers)||(victim == attacker)||(!is_user_connected(attacker))||!zp_get_user_zombie(victim))
		return HAM_IGNORED;
		
	zp_cs_damage[attacker][victim]+=damage
	
	if (zp_get_user_survivor(attacker))
	{
		zp_cs_player_money[attacker] += floatround(damage*zp_cs_s_income_cash_rate);
		if (zp_cs_player_money[attacker] > zp_cs_moneymax) 
                {
                   if(!(get_user_flags(attacker) & ADMIN_LEVEL_H))
                   {
			zp_cs_player_money[attacker]=zp_cs_moneymax; 
                   }else
                   if (zp_cs_player_money[attacker] > zp_cs_moneymax_vip) 
                   {
                       zp_cs_player_money[attacker]=zp_cs_moneymax_vip; 
                   }
                }
			
		message_begin(MSG_ONE_UNRELIABLE, g_MsgMoney, _, attacker); 
		write_long(zp_cs_player_money[attacker]);
		write_byte(1);
		message_end();
		return HAM_IGNORED;
	}	
	
	if (zp_get_user_zombie(attacker)||zp_get_user_nemesis(attacker))
	{
		if (!zp_get_user_nemesis(attacker)||zp_get_user_survivor(victim))
		{
			if (!zp_get_user_nemesis(attacker))
				zp_cs_player_money[attacker] +=floatround(damage*zp_cs_z_income_cash_rate);
			else
				zp_cs_player_money[attacker] +=floatround(damage*zp_cs_n_income_cash_rate);
				
			if (zp_cs_player_money[attacker] > zp_cs_moneymax) 
			{
			   if(!(get_user_flags(attacker) & ADMIN_LEVEL_H))
			   {
			       zp_cs_player_money[attacker]=zp_cs_moneymax; 
			   }else
			   if (zp_cs_player_money[attacker] > zp_cs_moneymax_vip) 
			   {
			      zp_cs_player_money[attacker]=zp_cs_moneymax_vip; 
			   }
			}
				
			message_begin(MSG_ONE_UNRELIABLE, g_MsgMoney, _, attacker); 
			write_long(zp_cs_player_money[attacker]);
			write_byte(1);
			message_end();
		}
		return HAM_IGNORED;
		
	}
	else
	{		
		zp_cs_player_money[attacker] += floatround(damage*zp_cs_h_income_cash_rate);

		if (zp_cs_player_money[attacker] > zp_cs_moneymax) 
		{
		   if(!(get_user_flags(attacker) & ADMIN_LEVEL_H))
		   {
		      zp_cs_player_money[attacker]=zp_cs_moneymax; 
		   }else
		   if (zp_cs_player_money[attacker] > zp_cs_moneymax_vip) 
		   {
		      zp_cs_player_money[attacker]=zp_cs_moneymax_vip; 
		   }
		}
			
		message_begin(MSG_ONE_UNRELIABLE, g_MsgMoney, _, attacker); 
		write_long(zp_cs_player_money[attacker]);
		write_byte(1);
		message_end();
		return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

public ham_PlayerKilled(victim, attacker, shouldgib)
{
	if((attacker<1)||(attacker>g_maxplayers)||(attacker==victim)) return HAM_IGNORED
	
	if (zp_get_user_zombie(attacker)&&!zp_get_user_nemesis(attacker))
	{
		menu_cancel(victim);
		zp_cs_player_moneybonus[attacker]+=get_pcvar_num(cvar_zp_cs_infectmoneybonus)
	}
	else if (zp_get_user_nemesis(attacker))
	{
		menu_cancel(victim);
		zp_cs_player_moneybonus[attacker]+=floatround(float(get_pcvar_num(cvar_zp_cs_infectmoneybonus))*zp_cs_n_income_cash_rate); 
	}	
	else if (zp_get_user_survivor(attacker)) 
		zp_cs_player_moneybonus[attacker]+=floatround(float(get_pcvar_num(cvar_zp_cs_money_killbonus))*zp_cs_s_income_cash_rate);
	else 
		zp_cs_player_moneybonus[attacker]+=get_pcvar_num(cvar_zp_cs_money_killbonus);
	
	if (zp_get_user_zombie(attacker)&&!zp_get_user_nemesis(attacker))
	{
		if (get_pcvar_num(cvar_zp_cs_zombie_nodeathscore)) set_pdata_int(victim, OFFSET_DEATHS, get_pdata_int(victim, OFFSET_DEATHS, OFFSET_LINUX)-1, OFFSET_LINUX)
	}

	if(!task_exists(attacker+TASK_RESTORE_MONEY))  set_task(0.1,"restore_player_money",attacker+TASK_RESTORE_MONEY)

	return HAM_IGNORED
}

public zp_user_humanized_pre(id, survivor)
{
	if(survivor) menu_cancel(id)

	return PLUGIN_CONTINUE
}

public zp_user_infected_post(id, infector)
{			
	if((infector <= g_maxplayers) && (infector > 0) && (id != infector))
	{
		if(!zp_get_user_nemesis(infector))
		{
			zp_cs_player_moneybonus[infector] += get_pcvar_num(cvar_zp_cs_infectmoneybonus)
		}
		else
			zp_cs_player_moneybonus[infector]+=floatround(float(get_pcvar_num(cvar_zp_cs_infectmoneybonus))*zp_cs_n_income_cash_rate)

		if(!task_exists(infector+TASK_RESTORE_MONEY)) set_task(0.1, "restore_player_money", infector+TASK_RESTORE_MONEY)
	}

	if((id<1)||(id>g_maxplayers)) return PLUGIN_CONTINUE

	menu_cancel(id)

	return PLUGIN_CONTINUE
}

public restore_player_money(id)
{
	id-=TASK_RESTORE_MONEY
	
	if(is_user_bot(id))
		set_pdata_int(id,OFFSET_MONEY,16000,OFFSET_LINUX)
	else 
		set_pdata_int(id,OFFSET_MONEY,0,OFFSET_LINUX)
		
	message_begin(MSG_ONE_UNRELIABLE, g_MsgMoney, _, id)
	write_long(zp_cs_player_money[id])
	write_byte(1)
	message_end()
	zp_cs_player_money[id]+=zp_cs_player_moneybonus[id];
		
	if (zp_cs_player_money[id] > zp_cs_moneymax) 
	{
	   if(!(get_user_flags(id) & ADMIN_LEVEL_H))
	   {
	      zp_cs_player_money[id]=zp_cs_moneymax; 
	   }else
	   if (zp_cs_player_money[id] > zp_cs_moneymax_vip) 
	   {
	      zp_cs_player_money[id]=zp_cs_moneymax_vip; 
	   }
	}
	if (zp_cs_player_money[id] < 0) zp_cs_player_money[id]=0; 
	message_begin(MSG_ONE_UNRELIABLE, g_MsgMoney, _, id);
	write_long(zp_cs_player_money[id]);
	write_byte(1);
	message_end();
	
	zp_cs_player_moneybonus[id]=0;
}

public native_get_user_money(id)
{
	return zp_cs_player_money[id] // return money (tERoR)
}

public native_set_user_money(id, num)
{
	zp_cs_player_money[id] = num // set money (tERoR)

	message_begin(MSG_ONE_UNRELIABLE, g_MsgMoney, _, id)
	write_long(zp_cs_player_money[id])
	write_byte(1)
	message_end()
}
