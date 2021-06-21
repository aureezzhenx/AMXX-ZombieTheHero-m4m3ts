#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombieplague>
#include <zth_money>

#define PLUGIN "DropMoney"
#define VERSION "1.3"
#define AUTHOR "m4m3ts"

#define SYSTEM_CLASSNAMEC "duit"

new const MONEY_MODEL[] = "models/money2.mdl"
new const cash_sound[3][] = 
{
	"weapons/cash1.wav",
	"weapons/cash2.wav",
	"weapons/cash3.wav"
}

new const pick_sound[] = "weapons/ambil_duit.wav"

new sound_voice[33], entX

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(SYSTEM_CLASSNAMEC, "fw_Think")
	register_touch(SYSTEM_CLASSNAMEC, "*", "fw_touch")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	register_clcmd("cheer", "drop_money")
}


public plugin_precache()
{
	precache_model(MONEY_MODEL)
	
	for(new i = 0; i < sizeof(cash_sound); i++) 
		precache_sound(cash_sound[i])
	
	precache_sound(pick_sound)
}

public Player_Spawn(id)
{
	if (is_user_alive(id) && !zp_get_user_zombie(id)) 
	{
		sound_voice[id] = 1
		set_task(6.0, "chat", id)
	}
}

public chat(id) client_printc(id, "!g[Zombie: The Hero]!n Press !g[J]!n to Drop !tMoney!n")

public drop_money(id)
{
	if(!is_user_alive(id) || zp_cs_get_user_money(id) < 400 || zp_get_user_zombie(id))
		return
	
	new Float:origin[3],Float:velocity[3],Float:angles[3]
	engfunc(EngFunc_GetAttachment, id, 0, origin,angles)
	pev(id,pev_angles,angles)
	entX = create_entity( "info_target" ) 
	set_pev( entX, pev_classname, SYSTEM_CLASSNAMEC )
	set_pev( entX, pev_solid, SOLID_TRIGGER )
	set_pev( entX, pev_owner, id)
	set_pev( entX, pev_fuser1, get_gametime() + 5.0)
	set_pev( entX, pev_nextthink, halflife_time() + 0.1)
	set_pev( entX, pev_movetype, MOVETYPE_TOSS )
	set_pev( entX, pev_mins, { -2.0,-2.0,-2.0 } )
	set_pev( entX, pev_maxs, { 5.0,5.0,5.0 } )
	entity_set_model( entX, MONEY_MODEL )
	set_pev( entX, pev_origin, origin )
	set_pev( entX, pev_angles, angles )
	set_pev( entX, pev_owner, id )
	velocity_by_aim( id, 300, velocity )
	set_pev( entX, pev_velocity, velocity )
		
	zp_cs_set_user_money(id, zp_cs_get_user_money(id) - 400)
	if(sound_voice[id])
	{
		emit_sound(id, CHAN_VOICE, cash_sound[random( sizeof(cash_sound))], 1.0, ATTN_NORM, 0, PITCH_NORM)
		sound_voice[id] = 0
		set_task(5.0, "back_sound", id)
	}
}

public back_sound(id) sound_voice[id] = 1

public fw_touch(Ent, Id)
{
	// If ent is valid
	static Owner; Owner = pev(Ent, pev_owner)
	
	if(!pev_valid(Ent) || !is_user_alive(Id) || zp_get_user_zombie(Id) || Id == Owner)
		return
		
	remove_task(Id)
	if(zp_cs_get_user_money(Id) >= 15600) zp_cs_set_user_money(Id, 16000)
	else zp_cs_set_user_money(Id, zp_cs_get_user_money(Id) + 400)		
	emit_sound(Id, CHAN_VOICE, pick_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	remove_entity(Ent)
}

public fw_Think(ent)
{
	if(!pev_valid(ent)) 
		return
	
	static Float:fFrame; pev(ent, pev_frame, fFrame)
	
	fFrame += 1.5
	fFrame = floatmin(21.0, fFrame)
	
	set_pev(ent, pev_frame, fFrame)
	set_pev(ent, pev_nextthink, get_gametime() + 0.05)
	
	// time remove
	static Float:fTimeRemove, Float:Amount
	pev(ent, pev_fuser1, fTimeRemove)
	pev(ent, pev_renderamt, Amount)
	
	if(get_gametime() >= fTimeRemove) 
	{
		remove_entity(ent)
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
		for(new i = 0; i < get_maxplayers(); i++)
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
