#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <zombieplague>
#include <fun>

#define PLUGIN "NST Zombie Class Pc"
#define VERSION "1.0"
#define AUTHOR "NST"

const Float:zclass_speed = 260.0
const Float:zclass_gravity = 0.8
new PC_V_MODEL[64] = "models/zombie_plague/v_knife_pc_zombi.mdl"
new const g_vgrenade[] = "models/zombie_plague/v_zombibomb_pc_zombi.mdl"
new class_pc[33]
const Float:smoke_time = 10.0
const Float:smoke_timewait = 10.0
const smoke_size = 4

new const sound_smoke[] = "zombie_plague/zombi_smoke.wav"
new idsprites_smoke

new g_smoke[33], g_smoke_wait[33], Float:g_smoke_origin[33][3]

new g_msgSayText, index_pc
new g_maxplayers
new g_roundend

enum (+= 100)
{
	TASK_SMOKE = 2000,
	TASK_SMOKE_EXP,
	TASK_WAIT_SMOKE,
	TASK_BOT_USE_SKILL
}

#define ID_SMOKE (taskid - TASK_SMOKE)
#define ID_SMOKE_EXP (taskid - TASK_SMOKE_EXP)
#define ID_WAIT_SMOKE (taskid - TASK_WAIT_SMOKE)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_event("CurWeapon","EventCurWeapon","be","1=1")
	register_clcmd("drop", "cmd_smoke")

	g_msgSayText = get_user_msgid("SayText")
	g_maxplayers = get_maxplayers()
}

public plugin_precache()
{
	idsprites_smoke = precache_model("sprites/zb_smoke.spr")
	index_pc = precache_model("models/player/pc_zombi_origin/pc_zombi_origin.mdl")
	precache_sound(sound_smoke)
	precache_model(PC_V_MODEL)
	precache_model(g_vgrenade)
}

public plugin_natives()
{
	register_native("give_pc", "native_give_pc", 1)
	register_native("pc_reset_value_player", "native_pc_reset_value_player", 1)
}

public native_give_pc(id)
{
        give_pc(id)
}

public native_pc_reset_value_player(id)
{
        pc_reset_value_player(id)
}

public client_putinserver(id)
{
	pc_reset_value_player(id)
}

public client_disconnect(id)
{
	pc_reset_value_player(id)
}

public event_round_start()
{
	g_roundend = 0
	
	for (new id=1; id<=g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		pc_reset_value_player(id)
	}
}

public logevent_round_end()
{
	g_roundend = 1
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	replace_weapon_models(id, read_data(2))
	if(class_pc[id]) set_user_maxspeed(id, zclass_speed)
	
	new weap = get_user_weapon(id)
	
	if(weap == CSW_SMOKEGRENADE && class_pc[id] && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_vgrenade)
	}
	
	return PLUGIN_HANDLED
}

public Death()
{
	new victim = read_data(2) 
	pc_reset_value_player(victim)
}

public give_pc(id)
{
	pc_reset_value_player(id)
	class_pc[id] = true
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	zp_override_user_model(id, "pc_zombi_origin")
	set_pdata_int(id, 491, index_pc, 5)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [G]^x01 to Smoke")
	
	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		return
	}
}

public zp_user_humanized_post(id)
{
	pc_reset_value_player(id)
}

public cmd_smoke(id)
{
	if (g_roundend) return PLUGIN_CONTINUE
	
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE

	if (class_pc[id] && !g_smoke[id] && !g_smoke_wait[id])
	{
		g_smoke[id] = 1
		
		pev(id,pev_origin,g_smoke_origin[id])
		
		set_task(0.1, "SmokeExplode", id+TASK_SMOKE_EXP)
		
		PlaySound(id, sound_smoke)
		
		set_task(smoke_time, "RemoveSmoke", id+TASK_SMOKE)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	
	if (!is_user_alive(id)) return;

	cmd_smoke(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public SmokeExplode(taskid)
{
	new id = ID_SMOKE_EXP
	
	if (!g_smoke[id])
	{
		remove_task(id+TASK_SMOKE_EXP)
		return;
	}
	
	new Float:origin[3]
	origin[0] = g_smoke_origin[id][0]
	origin[1] = g_smoke_origin[id][1]
	origin[2] = g_smoke_origin[id][2]
	
	new flags = pev(id, pev_flags)
	if (!((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
		origin[2] -= 36.0
	
	Create_Smoke_Group(origin)
	set_task(1.0, "SmokeExplode", id+TASK_SMOKE_EXP)
	
	return;
}

public RemoveSmoke(taskid)
{
	new id = ID_SMOKE
	
	g_smoke[id] = 0
	g_smoke_wait[id] = 1
	
	set_task(smoke_timewait, "RemoveWaitSmoke", id+TASK_WAIT_SMOKE)
}

public RemoveWaitSmoke(taskid)
{
	new id = ID_WAIT_SMOKE
	
	g_smoke_wait[id] = 0
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Smoking^x01 is ready.")
}

PlaySound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}

Create_Smoke_Group(Float:position[3])
{
	new Float:origin[12][3]
	get_spherical_coord(position, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(position, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(position, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(position, 40.0, 270.0, 0.0, origin[3])
	get_spherical_coord(position, 100.0, 0.0, 0.0, origin[4])
	get_spherical_coord(position, 100.0, 45.0, 0.0, origin[5])
	get_spherical_coord(position, 100.0, 90.0, 0.0, origin[6])
	get_spherical_coord(position, 100.0, 135.0, 0.0, origin[7])
	get_spherical_coord(position, 100.0, 180.0, 0.0, origin[8])
	get_spherical_coord(position, 100.0, 225.0, 0.0, origin[9])
	get_spherical_coord(position, 100.0, 270.0, 0.0, origin[10])
	get_spherical_coord(position, 100.0, 315.0, 0.0, origin[11])
	
	for (new i = 0; i < smoke_size; i++)
		create_Smoke(origin[i], idsprites_smoke, 100, 0)
}

create_Smoke(const Float:position[3], sprite_index, life, framerate)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, position[0])
	engfunc(EngFunc_WriteCoord, position[1])
	engfunc(EngFunc_WriteCoord, position[2])
	write_short(sprite_index)
	write_byte(life)
	write_byte(framerate)
	message_end()
}

get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}

replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case CSW_KNIFE:
	{
		if(!zp_get_user_zombie(id))
			return;
			
		if(class_pc[id])
			{
				set_pev(id, pev_viewmodel2, PC_V_MODEL)
				set_pev(id, pev_weaponmodel2, "")
			}
		}
	}
}


pc_reset_value_player(id)
{
	g_smoke[id] = 0
	g_smoke_wait[id] = 0
	class_pc[id] = false
	remove_task(id+TASK_SMOKE)
	remove_task(id+TASK_WAIT_SMOKE)
	remove_task(id+TASK_SMOKE_EXP)
	remove_task(id+TASK_BOT_USE_SKILL)
}

stock fm_strip_user_weapons2(id)
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent)) return;
	
	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, id)
	engfunc(EngFunc_RemoveEntity, ent)
}

zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	if (!target)
	{
		static player
		for (player = 1; player <= g_maxplayers; player++)
		{
			if (!is_user_connected(player))
				continue;
			
			static changed[5], changedcount
			changedcount = 0
			
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			vformat(buffer, charsmax(buffer), message, 3)
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	else
	{
		vformat(buffer, charsmax(buffer), message, 3)
		
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}
