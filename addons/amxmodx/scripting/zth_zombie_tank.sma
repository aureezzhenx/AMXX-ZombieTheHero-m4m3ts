#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <zombieplague>

#define PLUGIN "NST Zombie Class Tank"
#define VERSION "1.0.1"
#define AUTHOR "NST"

const Float:zclass_speed = 280.0
const Float:zclass_gravity = 0.8
new TANK_V_MODEL[64] = "models/zombie_plague/v_knife_tank_zombi.mdl"
new classtank[33]
const Float:fastrun_time = 10.0
const Float:fastrun_timewait = 5.0
const Float:fastrun_speed = 450.0
new const sound_fastrun_start[] = "zombie_plague/zombi_pressure.wav"
new const sound_fastrun_heartbeat[][] = {"zombie_plague/zombi_pre_idle_1.wav", "zombie_plague/zombi_pre_idle_2.wav"}
const fastrun_dmg = 500
const fastrun_fov = 111
const glow_red = 255
const glow_green = 3
const glow_blue = 0

new g_fastrun[33], g_fastrun_wait[33]
new g_msgSayText, g_msgSetFOV, index_tank
new g_maxplayers
new g_roundend

enum (+= 100)
{
	TASK_FASTRUN = 2000,
	TASK_FASTRUN_HEARTBEAT,
	TASK_FASTRUN_WAIT,
	TASK_BOT_USE_SKILL
}

#define ID_FASTRUN (taskid - TASK_FASTRUN)
#define ID_FASTRUN_HEARTBEAT (taskid - TASK_FASTRUN_HEARTBEAT)
#define ID_FASTRUN_WAIT (taskid - TASK_FASTRUN_WAIT)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_event("CurWeapon","EventCurWeapon","be","1=1")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_clcmd("drop", "cmd_fastrun")
	
	// Forward Fakemeta
	register_forward(FM_CmdStart , "Forward_CmdStart")
	
	g_msgSayText = get_user_msgid("SayText")
	g_msgSetFOV = get_user_msgid("SetFOV")
	g_maxplayers = get_maxplayers()
}

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof sound_fastrun_heartbeat; i++ )
	{
		precache_sound(sound_fastrun_heartbeat[i]);
	}
	index_tank = precache_model("models/player/tank_zombi_host/tank_zombi_host.mdl")
	precache_sound(sound_fastrun_start)
	precache_model(TANK_V_MODEL)
}

public plugin_natives()
{
	register_native("give_tank", "native_give_tank", 1)
	register_native("tank_reset_value_player", "native_tank_reset_value_player", 1)
}

public native_give_tank(id)
{
	give_tank(id)
}

public native_tank_reset_value_player(id)
{
	tank_reset_value_player(id)
}

public client_putinserver(id)
{
	tank_reset_value_player(id)
}

public client_disconnect(id)
{
	tank_reset_value_player(id)
}

public event_round_start()
{
	g_roundend = 0
	
	for (new id=1; id<=g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		tank_reset_value_player(id)
	}
}

public logevent_round_end()
{
	g_roundend = 1
}

public Death()
{
	new victim = read_data(2) 
	tank_reset_value_player(victim)
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	replace_weapon_models(id, read_data(2))
	if(classtank[id]) set_user_maxspeed(id, zclass_speed)
	return PLUGIN_CONTINUE;
}

public give_tank(id)
{
	tank_reset_value_player(id)
	classtank[id] = true
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	zp_override_user_model(id, "tank_zombi_host")
	set_pdata_int(id, 491, index_tank, 5)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [G]^x01 to use Sprint")
	
	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		return
	}
}

public zp_user_humanized_post(id)
{
	if(g_fastrun[id]) EffectFastrun(id);
	
	tank_reset_value_player(id)
}

public zp_user_unfrozen(id)
{
	if(g_fastrun[id]) set_user_rendering(id, kRenderFxGlowShell, glow_red, glow_green, glow_blue, kRenderNormal, 0)
}

public cmd_fastrun(id)
{
	if (g_roundend) return PLUGIN_CONTINUE
	
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE

	new health = get_user_health(id) - fastrun_dmg
	if (classtank[id] && health>0 && !g_fastrun[id] && !g_fastrun_wait[id])
	{
		g_fastrun[id] = 1
		
		set_user_health(id, health)
		set_user_maxspeed(id, fastrun_speed)
		set_user_rendering(id, kRenderFxGlowShell, glow_red, glow_green, glow_blue, kRenderNormal, 0)
		EffectFastrun(id, fastrun_fov)
		PlayEmitSound(id, sound_fastrun_start)
		
		set_task(fastrun_time, "RemoveFastRun", id+TASK_FASTRUN)
		set_task(2.0, "FastRunHeartBeat", id+TASK_FASTRUN_HEARTBEAT, _, _, "b")

		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	
	if (!is_user_alive(id)) return;

	cmd_fastrun(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public RemoveFastRun(taskid)
{
	new id = ID_FASTRUN

	g_fastrun[id] = 0
	g_fastrun_wait[id] = 1
	
	set_user_maxspeed(id, zclass_speed)
	set_user_rendering(id)
	EffectFastrun(id)
	
	set_task(fastrun_timewait, "RemoveWaitFastRun", id+TASK_FASTRUN_WAIT)
}

public RemoveWaitFastRun(taskid)
{
	new id = ID_FASTRUN_WAIT
	
	g_fastrun_wait[id] = 0
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Sprint^x01 is ready.")
}

public FastRunHeartBeat(taskid)
{
	new id = ID_FASTRUN_HEARTBEAT
	
	if (g_fastrun[id]) PlayEmitSound(id, sound_fastrun_heartbeat[random_num(0, sizeof sound_fastrun_heartbeat - 1)]);
	else remove_task(taskid)
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

EffectFastrun(id, num = 90)
{
	message_begin(MSG_ONE, g_msgSetFOV, {0,0,0}, id)
	write_byte(num)
	message_end()
}

tank_reset_value_player(id)
{
	g_fastrun[id] = 0
	g_fastrun_wait[id] = 0
	classtank[id] = false
	remove_task(id+TASK_FASTRUN)
	remove_task(id+TASK_FASTRUN_HEARTBEAT)
	remove_task(id+TASK_FASTRUN_WAIT)
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

replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case CSW_KNIFE:
	{
		if(!zp_get_user_zombie(id))
			return;
			
		if(classtank[id])
			{
				set_pev(id, pev_viewmodel2, TANK_V_MODEL)
				set_pev(id, pev_weaponmodel2, "")
			}
		}
	}
}
