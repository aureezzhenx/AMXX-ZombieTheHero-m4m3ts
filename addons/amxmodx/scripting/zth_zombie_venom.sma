#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <zombieplague>
#include <fun>
#include <zth_cso_theme>

// Zombie Attributes
const Float:zclass_speed = 250.0
const Float:zclass_gravity = 0.8
new VENOM_V_MODEL[64] = "models/zombie_plague/v_venom.mdl"
new class_venom[33]

// ==== Heal
new const heal_sound[] = "zombie_plague/td_heal.wav"
new const heal_sprite[] = "sprites/zb_restore_health.spr"
new heal_sprite_id, index_venom
new g_can_heal[33]
new const zombie_sound_heal[] = "zombie_plague/zombi_heal.wav"
new const g_vgrenade[] = "models/zombie_plague/v_venom_bomb.mdl"
new const g_pgrenade[] = "models/zombie_plague/p_venom_bomb.mdl" 
#define TASK_WAIT_HEAL 53498


// ==== Harden
new Float:harden_time = 10.0
new Float:harden_damage_def = 0.5, 
Float:harden_painshock_def = 1.25
new const harden_sound[] = "zombie_plague/boomer_skill.wav"
new g_can_harden[33], g_hardening[33]

const m_flTimeWeaponIdle = 48
const m_flNextAttack = 83

#define TASK_H_TIME_REMOVE 8345843

// ==== Dead Explode Effect
new const death_exp_effect_model[] = "models/zombie_plague/ef_boomer.mdl"
new const death_exp_effect_sprite[] = "sprites/spr_boomer.spr"
new const death_exp_effect_sound[] = "zombie_plague/boomer_death.wav"
new Float:death_exp_radius = 300.0
new Float:death_exp_knockspeed = 250.0

#define GIB_CLASSNAME "venomguard_gib"
new g_hide_corpse[33]
new g_register, g_explode_effect_idspr

enum (+= 100)
{
	TASK_BOT_USE_SKILL = 2000,
	TASK_BOT_USE_SKILL2
}

new g_maxplayers, g_msgSayText

#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_BOT_USE_SKILL2 (taskid - TASK_BOT_USE_SKILL2)

public plugin_init()
{
	register_plugin("[Zombie: Z-VIRUS] Zombie Class: Venom Guard Zombie", "1.0", "Dias")
	
	register_message(get_user_msgid("ClCorpse"), "msg_clcorpse")	
	register_think(GIB_CLASSNAME, "fw_Think_Gib")
	
	RegisterHam(Ham_Killed, "player", "fw_Killed_Post", 1)
	register_event("CurWeapon","handle_gun","be","1=1")  
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_CmdStart, "fw_cmdstart")
	
	register_clcmd("drop", "cmd_drop")
	g_maxplayers = get_maxplayers()
	g_msgSayText = get_user_msgid("SayText")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, death_exp_effect_model)
	precache_model(g_vgrenade)
	precache_model(g_pgrenade)
	engfunc(EngFunc_PrecacheSound, death_exp_effect_sound)
	g_explode_effect_idspr = engfunc(EngFunc_PrecacheModel, death_exp_effect_sprite)
	index_venom = precache_model("models/player/venom_zombi_origin/venom_zombi_origin.mdl")
	heal_sprite_id = engfunc(EngFunc_PrecacheModel, heal_sprite)
	engfunc(EngFunc_PrecacheSound, heal_sound)
	engfunc(EngFunc_PrecacheSound, harden_sound)
	precache_sound("zombie_plague/boomer_draw.wav")
	precache_model(VENOM_V_MODEL)
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_register)
	{
		g_register = 1
		set_task(0.1, "do_register_ham_now", id)
	}
}

public fw_cmdstart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) 
		return
	
	if(!class_venom[id] || !g_can_harden[id])
		return
		
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if (CurButton & IN_RELOAD)
	{
		cmd_lastinv(id)
	}
}

public do_register_ham_now(id)
{
	RegisterHamFromEntity(Ham_Killed, id, "fw_Killed_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}

public plugin_natives()
{
	register_native("give_venom", "native_give_venom", 1)
	register_native("venom_reset_value", "native_venom_reset_value", 1)
}

public native_give_venom(id)
{
        give_venom(id)
}

public native_venom_reset_value(id)
{
        venom_reset_value(id)
}

public give_venom(id)
{
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	zp_override_user_model(id, "venom_zombi_origin")
	set_pdata_int(id, 491, index_venom, 5)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
	class_venom[id] = true
		
	g_can_heal[id] = 1
	g_can_harden[id] = 1
	g_hardening[id] = 0
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [G]^x01 to use Heal")
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [R]^x01 to Hard Defens")
	
	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		set_task(random_float(5.0,15.0), "bot_use_skill2", id+TASK_BOT_USE_SKILL2)
		return
	}
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_alive(id)) return;

	skill_heal_handle(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public bot_use_skill2(taskid)
{
	new id = ID_BOT_USE_SKILL2
	if (!is_user_alive(id)) return;

	skill_harden_handle(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill2", id+TASK_BOT_USE_SKILL2)
}

public zp_user_humanized_post(id)
{
	venom_reset_value(id)
}
// ================================== Skill: Heal ===================================
public cmd_drop(id)
{
	if(is_user_alive(id) && zp_get_user_zombie(id) && class_venom[id])
		skill_heal_handle(id)
}

public skill_heal_handle(id)
{
	if(g_can_heal[id])
	{
		// check health
		new start_health = zth_get_user_start_health(id)
		if(get_user_health(id) >= start_health) 
			return PLUGIN_CONTINUE
		
		// set health
		
		fm_set_user_health(id, start_health)
		
		// Make a screen fade 
		
		client_print(id, print_center, "Healed...")		
		
		// effect
		PlaySound(id, zombie_sound_heal)
		
		static Float:Origin[3]
		pev(id, pev_origin, Origin)
	    
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(heal_sprite_id)
		write_byte(15)
		write_byte(12)
		write_byte(14)
		message_end()
		
		// set time wait
		g_can_heal[id] = 0
	}	
	
	return PLUGIN_HANDLED
}

public handle_gun(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	replace_weapon_models(id, read_data(2))
	if(class_venom[id]) set_user_maxspeed(id, zclass_speed)
	
	new weap = get_user_weapon(id)

	if(weap == CSW_HEGRENADE && class_venom[id] && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_vgrenade)
	}
	else if(weap == CSW_SMOKEGRENADE && class_venom[id] && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_vgrenade)
	}
	else if(weap == CSW_HEGRENADE && zp_get_user_zombie(id))
	{
		set_pev(id, pev_weaponmodel2, g_pgrenade);
	}
	else if(weap == CSW_SMOKEGRENADE && zp_get_user_zombie(id))
	{
		set_pev(id, pev_weaponmodel2, g_pgrenade);
	}

	return PLUGIN_HANDLED
}  

// ================================== Skill: Harden ================================
public cmd_lastinv(id)
{
	if(is_user_alive(id) && zp_get_user_zombie(id) && class_venom[id])
		skill_harden_handle(id)
}

public skill_harden_handle(id)
{
	if(g_can_harden[id] && !g_hardening[id])
	{
		play_weapon_anim(id, 2)
		set_weapons_timeidle(id, 1.75)
		set_player_nextattack(id, 1.75)
		
		emit_sound(id, CHAN_ITEM, harden_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		fm_set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16)
		
		g_can_harden[id] = 0
		g_hardening[id] = 1

		set_task(harden_time, "stop_harden", id+TASK_H_TIME_REMOVE)
	}
}

public stop_harden(id)
{
	id -= TASK_H_TIME_REMOVE
	
	if(is_user_alive(id) && zp_get_user_zombie(id) && class_venom[id])
	{
		fm_set_user_rendering(id)
		
		g_can_harden[id] = 0
		g_hardening[id] = 0
	}
}

// ================================== MAIN MESSAGE ====================================
public msg_clcorpse()
{
	static id
	id = get_msg_arg_int(12)
	
	if(!zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(!class_venom[id])
		return PLUGIN_CONTINUE
	
	if(g_hide_corpse[id])
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}  

// ================================== FORWARD ===============================

public venom_reset_value(id)
{
	g_hide_corpse[id] = 0
	fm_set_user_rendering(id)
	class_venom[id] = false
	g_can_heal[id] = 0
	g_can_harden[id] = 0
	g_hardening[id] = 0	
	remove_task(id+TASK_BOT_USE_SKILL)
	remove_task(id+TASK_BOT_USE_SKILL2)
}

public fw_Killed_Post(id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!zp_get_user_zombie(id))
		return HAM_IGNORED
	if(!class_venom[id])
		return HAM_IGNORED
	
	g_hide_corpse[id] = 1
	fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	death_effect(id)
	
	venom_reset_value(id)
	
	return HAM_HANDLED
}

public fw_Think_Gib(ent)
{
	if(!pev_valid(ent))
		return
		
	engfunc(EngFunc_RemoveEntity, ent)
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	if(!zp_get_user_zombie(victim) || zp_get_user_zombie(attacker))
		return HAM_IGNORED
	if(!class_venom[victim])
		return HAM_IGNORED
	if(!g_hardening[victim])
		return HAM_IGNORED
		
	SetHamParamFloat(4, damage * harden_damage_def)
	set_pdata_float(victim, 108, harden_painshock_def, 5)
		
	return HAM_HANDLED
}

// ================================= MAIN PUBLIC =========================================
public death_effect(id)
{
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	
	create_explode_effect(Origin)
	create_explode_gib(id)
	emit_sound(id, CHAN_STATIC, death_exp_effect_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	check_and_knockback(id, Origin, death_exp_radius)
}

public create_explode_gib(owner)
{
	new ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(ent))
		return
		
	static Float:Origin[3]
	static Float:maxs[3], Float:mins[3]
	
	pev(owner, pev_origin, Origin)
	set_pev(ent, pev_origin, Origin)
	
	mins[0] = -16.0; maxs[0] = 16.0
	mins[1] = -16.0; maxs[1] = 16.0
	mins[2] = -36.0; maxs[2] = 36.0
	entity_set_size(ent, mins, maxs)
	engfunc(EngFunc_SetModel, ent, death_exp_effect_model)
	
	set_pev(ent, pev_classname, GIB_CLASSNAME)
	set_entity_anim(ent, 0)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.25)
}

public create_explode_effect(Float:Origin[3])
{
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2]+70)
	write_short(g_explode_effect_idspr)	// sprite index
	write_byte(20)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(4)	// flags
	message_end()	
}

public check_and_knockback(id, Float:Origin[3], Float:radius)
{
	static iVictim
	iVictim = -1
	
	static const hit_sound[3][] =
	{
		"player/bhit_flesh-1.wav",
		"player/bhit_flesh-2.wav",
		"player/bhit_flesh-3.wav"
	}
	
	while((iVictim = find_ent_in_sphere(iVictim, Origin, radius)) != 0)
	{
		if(is_user_alive(iVictim) && can_see_fm(iVictim, id) && cs_get_user_team(id) != cs_get_user_team(iVictim))
		{
			shake_screen(iVictim)
			
			if(is_in_viewcone(iVictim, Origin, 1))
				hook_ent2(iVictim, Origin, death_exp_knockspeed, 2)
			else
				hook_ent2(iVictim, Origin, death_exp_knockspeed, 1)
			
			ExecuteHamB(Ham_TakeDamage, iVictim, 0, iVictim, 0.0, DMG_BULLET)
			emit_sound(iVictim, CHAN_BODY, hit_sound[random(sizeof(hit_sound))], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}	
}

// ================================ MAIN STOCK =====================================
set_weapons_timeidle(id, Float:timeidle)
{
	new entwpn = fm_get_user_weapon_entity(id, get_user_weapon(id))
	if (pev_valid(entwpn)) set_pdata_float(entwpn, m_flTimeWeaponIdle, timeidle + 3.0, 4)
}

set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, m_flNextAttack, nexttime, 4)
}

replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case CSW_KNIFE:
	{
		if(!zp_get_user_zombie(id))
			return;
			
		if(class_venom[id])
			{
				set_pev(id, pev_viewmodel2, VENOM_V_MODEL)
				set_pev(id, pev_weaponmodel2, "")
			}
		}
	}
}

stock play_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

stock PlaySound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}

stock set_entity_anim(ent, anim)
{
	if(!pev_valid(ent))
		return
	
	entity_set_float(ent, EV_FL_animtime, get_gametime())
	entity_set_float(ent, EV_FL_framerate, 1.0)
	entity_set_float(ent, EV_FL_frame, 0.0)
	
	entity_set_int(ent, EV_INT_sequence, anim)	
}

stock shake_screen(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	new Float:fl_Time = distance_f / speed
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
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

stock cahtcol(const id, const input[], any:...)
{
    new count = 1, players[32]
    static msg[191]
    vformat(msg, 190, input, 3)
    
    replace_all(msg, 190, "!g", "^4")
    replace_all(msg, 190, "!y", "^1")
    replace_all(msg, 190, "!team", "^3")
    
    if (id) players[0] = id; else get_players(players, count, "ch")
    {
        for (new i = 0; i < count; i++)
        {
            if (is_user_connected(players[i]))
            {
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
                write_byte(players[i]);
                write_string(msg);
                message_end();
            }
        }
    }
}

stock bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
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
