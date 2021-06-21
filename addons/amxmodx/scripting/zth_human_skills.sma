#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <cs_maxspeed_api>
#include <hamsandwich>
#include <zombieplague>

#define TASK_REMOVE1 2425425
#define TASK_REMOVE2 2426426
#define TASK_REMOVE3 2427427

#define DEAD_BIND "f1"
#define BB_BIND "f3"
#define SPR_BIND "f4"

#define NONE_SPRINT		(IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_JUMP|IN_DUCK|IN_ALT1)


new bool:has_deadly[33]
new bool:using_deadly[33]
new bool:has_sprint[33]
new bool:using_sprint[33]
new bool:has_bloody[33]
new bool:using_bloody[33]

const fastrun_fov = 0
new cvar_deadlyshot_time, cvar_bloody_time
new g_spr_headshot, g_Ham_Bot, g_spr_bloody
new cvar_sprint_time
new g_msgSetFOV
new cvar_sprintspeedmultiplier
new Float:flSprintSpeedMultiplier

new g_HumanHud

new const sound_skill_start[] = "zombie_plague/fastrun_start.wav"
new const sound_skill_start2[] = "zombie_plague/sprint.wav"

public plugin_init()
{
	register_plugin("Human SKills", "2.4", "m4m3ts")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_TraceAttack, "player", "fw_traceattack")
	
	cvar_deadlyshot_time = register_cvar("ds_time", "6.0")
	cvar_sprintspeedmultiplier = register_cvar("zp_sprint_speed_multiplier", "400.0")
	cvar_sprint_time = register_cvar("sprint_time", "13.0")
	cvar_bloody_time = register_cvar("bb_time", "6.0")
	
	register_clcmd("ok","use_bb")
	register_clcmd("sprint","use_sprint")
	register_clcmd("deadly","use_deadly")
	
	g_HumanHud = CreateHudSyncObj(3)
	
	g_msgSetFOV = get_user_msgid("SetFOV")
}

public plugin_precache()
{
	g_spr_headshot = precache_model("sprites/zb_skill_ds.spr")
	g_spr_bloody = precache_model("sprites/zb_meleeup.spr")
	precache_sound(sound_skill_start)
	precache_sound(sound_skill_start2)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || using_sprint[id])
		return FMRES_IGNORED
	
	static iButton
	iButton = get_uc(uc_handle, UC_Buttons)
	
	if(iButton & NONE_SPRINT)
	{
		cs_reset_player_maxspeed(id)
	}
	
	return FMRES_IGNORED
}

public plugin_cfg()
{
	flSprintSpeedMultiplier = get_pcvar_float(cvar_sprintspeedmultiplier)
}

public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public client_connect(id)
{
	// Do we bind a key	
	#if defined DEAD_BIND
	client_cmd(id,"bind %s ^"deadly^"", DEAD_BIND);
	#endif
	
	#if defined SPR_BIND
	client_cmd(id,"bind %s ^"sprint^"", SPR_BIND);
	#endif
	
	// Do we bind a key	
	#if defined BB_BIND
	client_cmd(id,"bind %s ^"ok^"", BB_BIND);
	#endif
	
	remove_bb(id)
	remove_sprint(id)
	remove_ds(id)
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_traceattack")
}

public plugin_natives ()
{
	register_native("give_ds", "native_give_ds", 1)
	register_native("using_ds", "native_using_ds", 1)
	
	register_native("give_bb", "native_give_bb", 1)
	register_native("give_sprint", "native_give_sprint", 1)
}

public native_give_ds(id)
{
	give_ds(id)
}

public native_give_bb(id)
{
	give_bb(id)
}

public native_give_sprint(id)
{
	give_sprint(id)
}

public native_using_ds(id)
{
	return using_deadly[id];
}	

public give_sprint(id)
{
	remove_sprint(id)

	has_sprint[id] = true
	using_sprint[id] = false
}

public give_ds(id)
{
	remove_ds(id)

	has_deadly[id] = true
	using_deadly[id] = false
}

public give_bb(id)
{
	remove_bb(id)

	has_bloody[id] = true
	using_bloody[id] = false
}

public zp_user_infected_post(id)
{
	remove_ds(id)
	remove_sprint(id)
	remove_bb(id)
}

HS_sprite(id)
{
	if (!is_user_alive(id)) return;
	
	static origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+32)
	write_short(g_spr_headshot)
	write_byte(2)
	write_byte(192)
	message_end()
}

bloody_sprite(id)
{
	if (!is_user_alive(id)) return;
	
	static origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+30)
	write_short(g_spr_bloody)
	write_byte(10)
	write_byte(192)
	message_end()
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(zp_get_user_zombie(id))
		return
		
	static Float:CurTime, Float:g_hud_delay[33], Float:CurTime2, Float:g_hud_delay2[33]
	CurTime = get_gametime()
	CurTime2 = get_gametime()
	
	if(CurTime - 1.0 > g_hud_delay[id])
	{	
		show_hud(id)
		g_hud_delay[id] = CurTime
	}
	
	if(CurTime2 - 0.1 > g_hud_delay2[id])
	{
		if(using_deadly[id]) HS_sprite(id)
		if(using_bloody[id]) bloody_sprite(id)
		
		g_hud_delay2[id] = CurTime2
	}
}

public show_hud(id)
{
	// Hud
	static Skill1[64], Skill2[64], Skill3[64]
	
	// Skill 1
	if(has_sprint[id]) formatex(Skill1, 63, "[F4] : Active Sprint")
	else if (using_sprint[id])  formatex(Skill1, 63, "[F4] : Actived")
	else formatex(Skill1, 63, "[F4] : No Skill")
	
	// Skill 2
	if(has_deadly[id]) formatex(Skill2, 63, "[F1] : Active Deadly Shot")
	else if(using_deadly[id]) formatex(Skill2, 63, "[F1] : Actived")
	else formatex(Skill2, 63, "[F1] : No Skill")
	
	// Skill 3
	if(has_bloody[id]) formatex(Skill3, 63, "[F3] : Active Bloody Blade")
	else if (using_bloody[id]) formatex(Skill3, 63, "[F3] : Actived")
	else formatex(Skill3, 63, "[F3] : No Skill")

	set_hudmessage(0, 255, 255, -1.0, -0.79, 0, 2.0, 2.0, 0.05, 1.0)
	ShowSyncHudMsg(id, g_HumanHud, "[Human Ability]^n^n%s^n%s^n%s", Skill1, Skill2, Skill3)
}

public use_deadly(id)
{
	if(has_deadly[id] && !using_deadly[id])
		{
			has_deadly[id] = false
			using_deadly[id] = true
			set_task(get_pcvar_float(cvar_deadlyshot_time), "remove_headshot_mode", id+TASK_REMOVE1)
			PlayEmitSound(id, sound_skill_start)
			
			message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
			write_short(1<<12);
			write_short(6<<12);
			write_short(1<<12);
			write_byte(150);
			write_byte(150);
			write_byte(0);
			write_byte(80);
			message_end();
		}
}

public use_sprint(id)
{
	if(has_sprint[id] && !using_sprint[id] && is_user_alive(id))
		{
			has_sprint[id] = false
			using_sprint[id] = true
			Effectsprint(id, fastrun_fov)
			cs_set_player_maxspeed(id, flSprintSpeedMultiplier, false)
			ScreenFade(id, 8.0, 100, 150, 0, 80)
			set_task(8.0, "slow_speed", id)
			set_task(get_pcvar_float(cvar_sprint_time), "remove_sprint_mode", id+TASK_REMOVE2)
			PlayEmitSound(id, sound_skill_start2)
		}
}

public use_bb(id)
{
	if(has_bloody[id] && !using_bloody[id])
		{
			has_bloody[id] = false
			using_bloody[id] = true
			set_task(get_pcvar_float(cvar_bloody_time), "remove_bloody_mode", id+TASK_REMOVE3)
			PlayEmitSound(id, sound_skill_start)
			
			message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
			write_short(1<<12);
			write_short(6<<12);
			write_short(1<<12);
			write_byte(150);
			write_byte(150);
			write_byte(0);
			write_byte(80);
			message_end();
		}
}

Effectsprint(id, num = 90)
{
	message_begin(MSG_ONE, g_msgSetFOV, {0,0,0}, id)
	write_byte(num)
	message_end()
}

public remove_sprint(id)
{
	if(has_sprint[id] || using_sprint[id])
	{
		has_sprint[id] = false
		using_sprint[id] = false		
		
		if(task_exists(id+TASK_REMOVE2)) remove_task(id+TASK_REMOVE2)
	}	
}

public remove_sprint_mode(id)
{
	id -= TASK_REMOVE2
	
	has_sprint[id] = false
	using_sprint[id] = false
	Effectsprint(id)
	cs_reset_player_maxspeed(id)
}

public slow_speed(id)
{
	if(is_user_connected(id) && is_user_alive(id)) cs_set_player_maxspeed(id, 110.0, false)
}

stock ScreenFade(plr, Float:fDuration, red, green, blue, alpha)
{
    new i = plr ? plr : get_maxplayers();
    if( !i )
    {
        return 0;
    }
    
    message_begin(plr ? MSG_ONE : MSG_ALL, get_user_msgid( "ScreenFade"), {0, 0, 0}, plr);
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(4096);
    write_byte(red);
    write_byte(green);
    write_byte(blue);
    write_byte(alpha);
    message_end();
    
    return 1;
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public fw_traceattack(victim, attacker, Float:damage, direction[3], traceresult, dmgbits)
{
	if(victim != attacker && is_user_connected(attacker) && using_deadly[attacker] && zp_get_user_zombie(victim))
	{
		set_tr2(traceresult, TR_iHitgroup, HIT_HEAD)
	}
	
	if(victim != attacker && is_user_connected(attacker) && zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker) && using_bloody[attacker] && get_user_weapon(attacker) == CSW_KNIFE)
	{
		SetHamParamFloat(3, damage*2)
	}
}

public remove_ds(id)
{
	if(has_deadly[id] || using_deadly[id])
	{
		has_deadly[id] = false
		using_deadly[id] = false		
		
		if(task_exists(id+TASK_REMOVE1)) remove_task(id+TASK_REMOVE1)
	}	
}

public remove_headshot_mode(id)
{
	id -= TASK_REMOVE1
	
	has_deadly[id] = false
	using_deadly[id] = false
}

public remove_bb(id)
{
	if(has_bloody[id] || using_bloody[id])
	{
		has_bloody[id] = false
		using_bloody[id] = false		
		
		if(task_exists(id+TASK_REMOVE3)) remove_task(id+TASK_REMOVE3)
	}	
}

public remove_bloody_mode(id)
{
	id -= TASK_REMOVE3
	
	has_bloody[id] = false
	using_bloody[id] = false	
}
