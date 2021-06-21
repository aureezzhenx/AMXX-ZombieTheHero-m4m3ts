#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <engine>
#include <zombieplague>

#define PLUGIN "ZB Lusty Rose"
#define VERSION "1.9"
#define AUTHOR "m4m3ts"

const Float:zclass_speed = 295.0
const Float:zclass_gravity = 0.6
new const zclass_clawmodel_invi[] = "models/zombie_plague/v_knife_lusty_inv.mdl"
new SPEED_V_MODEL[64] = "models/zombie_plague/v_knife_lusty.mdl"
new const zombie_sound_invisible[] = "zombie_plague/light_dash.wav"
new const g_vgrenade[] = "models/zombie_plague/v_zombibomb_lusty.mdl"

new class_speed[33]
const Float:invisible_time = 10.0
const Float:invisible_timewait = 10.0
const invisible_dmg = 200
const Float:invisible_speed = 255.0
const Float:invisible_gravity = 0.6
const invisible_alpha = 10

new g_invisible[33], g_invisible_wait[33]

new g_msgSayText, index_speed
new g_maxplayers
new g_roundend

enum (+= 100)
{
	TASK_INVISIBLE = 2000,
	TASK_WAIT_INVISIBLE,
	TASK_INVISIBLE_SOUND,
	TASK_BOT_USE_SKILL
}

#define ID_INVISIBLE (taskid - TASK_INVISIBLE)
#define ID_WAIT_INVISIBLE (taskid - TASK_WAIT_INVISIBLE)
#define ID_INVISIBLE_SOUND (taskid - TASK_INVISIBLE_SOUND)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_event("CurWeapon", "EventCurWeapon", "be", "1=1")
	register_logevent("logevent_round_end", 2, "1=Round_End")

	register_clcmd("drop", "cmd_invisible")
		
	g_msgSayText = get_user_msgid("SayText")
	g_maxplayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(zclass_clawmodel_invi)
	precache_sound(zombie_sound_invisible)
	index_speed = precache_model("models/player/lusty_host/lusty_host.mdl")
	precache_model(SPEED_V_MODEL)
	precache_model(g_vgrenade)
}

public plugin_natives()
{
	register_native("give_speed", "native_give_speed", 1)
	register_native("speed_reset_value", "native_speed_reset_value", 1)
}

public native_give_speed(id)
{
        give_speed(id)
}

public native_speed_reset_value(id)
{
        speed_reset_value(id)
}

public client_putinserver(id)
{
	speed_reset_value(id)
}

public client_disconnect(id)
{
	speed_reset_value(id)
}

public event_round_start()
{
	g_roundend = 0
	
	for (new id=1; id<=g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		speed_reset_value(id)
	}
}

public logevent_round_end()
{
	g_roundend = 1
}

public Death()
{
	new victim = read_data(2) 
	speed_reset_value(victim)
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	replace_weapon_models(id, read_data(2))
	if(class_speed[id]) set_user_maxspeed(id, zclass_speed)
	
	new weap = get_user_weapon(id)
	
	if(weap == CSW_SMOKEGRENADE && class_speed[id] && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_vgrenade)
	}
	
	return PLUGIN_HANDLED
}

public give_speed(id)
{
	speed_reset_value(id)
	class_speed[id] = true
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	zp_override_user_model(id, "lusty_host")
	set_pdata_int(id, 491, index_speed, 5)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [G]^x01 to use Stealth")
	
	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		return
	}
}

public zp_user_humanized_post(id)
{
	speed_reset_value(id)
}

public zp_user_unfrozen(id)
{
	if(g_invisible[id])
	{
		set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, invisible_alpha)
		set_user_maxspeed(id, invisible_speed)
		set_user_gravity(id, invisible_gravity)
	}
}

public cmd_invisible(id)
{
	if (g_roundend) return PLUGIN_CONTINUE
	
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE

	new health = get_user_health(id) - invisible_dmg
	if (class_speed[id] && health>0 && !g_invisible[id] && !g_invisible_wait[id])
	{
		g_invisible[id] = 1
		
		set_wpnmodel(id)
		set_user_health(id, health)
		set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, invisible_alpha)
		set_user_maxspeed(id, invisible_speed)
		set_user_gravity(id, invisible_gravity)
		PlayEmitSound(id, zombie_sound_invisible)
		
		set_task(invisible_time, "RemoveInvisible", id+TASK_INVISIBLE)

		zp_colored_print(id, "^x04[Zombie: The Hero]^x01 You will^x04 Stealth^x01 for^x04 %.1f ^x01seconds.", invisible_time)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	
	if (!is_user_alive(id)) return;

	cmd_invisible(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public InvisibleSound(taskid)
{
	new id = ID_INVISIBLE_SOUND
	
	if (g_invisible[id]) PlayEmitSound(id, zombie_sound_invisible)
	else remove_task(taskid)
}

public RemoveInvisible(taskid)
{
	new id = ID_INVISIBLE
	
	g_invisible[id] = 0
	
	set_wpnmodel(id)
	set_user_rendering(id)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your^x04 Stealth^x01 skill is over.")
	
	g_invisible_wait[id] = 1
	
	set_task(invisible_timewait, "RemoveWaitInvisible", id+TASK_WAIT_INVISIBLE)
}

public RemoveWaitInvisible(taskid)
{
	new id = ID_WAIT_INVISIBLE
	
	g_invisible_wait[id] = 0
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Stealth^x01 is ready.")
}

set_wpnmodel(id)
{
	if (!is_user_alive(id)) return;
	
	if (get_user_weapon(id) == CSW_KNIFE)
	{
		if (g_invisible[id])
		{
			set_pev(id, pev_viewmodel2, zclass_clawmodel_invi)
		}
		else
		{
			static temp[100]
			format(temp, charsmax(temp), "models/zombie_plague/%s", "v_knife_lusty.mdl")
			set_pev(id, pev_viewmodel2, temp)
		}
	}	
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case CSW_KNIFE:
	{
		if(!zp_get_user_zombie(id))
			return;
			
		if(class_speed[id])
			{
				set_pev(id, pev_viewmodel2, SPEED_V_MODEL)
				set_pev(id, pev_weaponmodel2, "")
			}
		}
	}
}

speed_reset_value(id)
{
	g_invisible[id] = 0
	g_invisible_wait[id] = 0
	class_speed[id] = false
	remove_task(id+TASK_INVISIBLE)
	remove_task(id+TASK_WAIT_INVISIBLE)
	remove_task(id+TASK_BOT_USE_SKILL)
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

stock fm_strip_user_weapons2(id)
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent)) return;
	
	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, id)
	engfunc(EngFunc_RemoveEntity, ent)
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch) 
{
     // ??????????
     if (!is_user_connected(id) || !zp_get_user_zombie(id) || !class_speed[id])
           return FMRES_IGNORED;
     
     // ????????
     if (equal(sample[7], "bhit", 4))
     {
           if (zp_get_user_nemesis(id)) 
                 engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/zombi_hurt_female_1.wav", volume, attn, flags, pitch)
           else 
                 engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/zombi_hurt_female_2.wav", volume, attn, flags, pitch)
           return FMRES_SUPERCEDE;
     }
     
     // ???????
     if (equal(sample[7], "die", 3) || equal(sample[7], "dea", 3))
     {
           engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/zombi_death_stamper_1.wav", volume, attn, flags, pitch)
           return FMRES_SUPERCEDE;
     }
     
     // ???????
     if (equal(sample[10], "fall", 4))
     {
           engfunc(EngFunc_EmitSound, id, channel, "zombie_plague/zombi_hurt_female_1.wav", volume, attn, flags, pitch)
           return FMRES_SUPERCEDE;
     }
     
     return FMRES_IGNORED;
}
