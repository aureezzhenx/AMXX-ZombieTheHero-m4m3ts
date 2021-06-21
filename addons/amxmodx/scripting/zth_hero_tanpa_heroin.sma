#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <zombieplague>
#include <m4m3tsunlock>

#define PLUGIN "[ZP] CSO Addom : The Hero"
#define VERSION "1.0"
#define AUTHOR "ShuriK/ и еще кто-то"

#define NAMEITEM   "svdex"
#define NAMEITEM2   "Dual Deagle"
#define TEXT       "%s Hero in round" 
#define MINPEOPLE  7

new g_hero[33] , g_iMaxClients ;
new spr_current[33] = {0,...}
new time_show_set[33] = {0,...}
new iconstatus 
new time_show = 3
new index_hero

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("drop", "BlockDrop")
	register_forward(FM_PlayerPreThink,"check_spr")
	iconstatus = get_user_msgid("StatusIcon")
	g_iMaxClients = get_maxplayers( );
}

public plugin_precache()
{
	index_hero = precache_model("models/player/komplit_hero/komplit_hero.mdl")
	
	precache_sound("zombie_plague/cso/becoming_hero.wav")
}

public plugin_natives()
{
	register_native("revo_get_user_hero", "native_revo_get_user_hero", 1)
}

public native_revo_get_user_hero(id)
{
	return g_hero[id];
}

public zp_round_started(round, id)
{
	if (zp_get_human_count( ) < MINPEOPLE )
		return;
			
	if(round == MODE_MULTI || round == MODE_INFECTION)
	{
		set_task(0.5,"make_hero")
	}
}

public zp_user_infected_post(id) g_hero[id] = false

public make_hero(id)
{		
	new id
	static iPlayersNum
	iPlayersNum = gAlive()

	id = gRandomAlive(random_num(1, iPlayersNum))
		
	g_hero[id] = true
	destroy_menu(id)
	zp_force_buy_extra_item( id, zp_get_extra_item_id(NAMEITEM), 1)
	zp_force_buy_extra_item( id, zp_get_extra_item_id(NAMEITEM2), 1)
	zp_override_user_model(id, "komplit_hero")
	set_pdata_int(id, 491, index_hero, 5)
	
	client_cmd(1, "spk zombie_plague/cso/becoming_hero")

	set_task(0.101, "test5", id)
	
	emessage_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"))
	ewrite_byte(id) // id
	ewrite_byte(4) // attrib
	emessage_end()
}

public BlockDrop(id)
{
	if(g_hero[id])
		return PLUGIN_HANDLED
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

public zp_round_ended()
{
	static id;

	for( id = 1; id <= g_iMaxClients; id++ )
	{
		if( !is_user_connected( id ) || !g_hero[ id ] )
			continue;

		g_hero[id] = false
	}
}

public test5(id) show_spr(id, 1)

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
