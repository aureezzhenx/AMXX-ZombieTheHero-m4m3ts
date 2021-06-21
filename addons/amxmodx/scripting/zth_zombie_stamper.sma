#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <zombieplague>
#include <xs>

#define TASK_STAMP 1948
#define TASK_FREEZE 2105
#define TASK_COOLDOWN 7503
#define TASK_BOT 8209
#define TASK_HEALTH 3507
#define ID_STAMP (taskid - TASK_STAMP)
#define ID_FREEZE (taskid - TASK_FREEZE)
#define ID_COOLDOWN (taskid - TASK_COOLDOWN)
#define ID_BOT (taskid - TASK_BOT)
#define ID_HEALTH (taskid - TASK_HEALTH)

const Float:zclass_speed = 255.0
const Float:zclass_gravity = 0.8
new STAMPER_V_MODEL[64] = "models/zombie_plague/v_knife_undertaker.mdl"
new class_stamper[33]
new const STAMP_CLASSNAME[] = "ent_coffin"
new const STAMP_SOUND_DROP[] = "zombie_plague/z4heavy_skill_end.wav"
new const STAMP_SOUND_HIT[] = "debris/wood1.wav"
new const STAMP_SOUND_EXPLODE[] = "zombie_plague/zombi_stamper_iron_maiden_explosion.wav"
new const STAMP_SOUND_BREAK[] = "zombie_plague/zombi_wood_broken.wav"
new const STAMP_MODEL[] = "models/zombie_plague/zombiepile.mdl"
new const g_vgrenade[] = "models/zombie_plague/v_zombibomb_stamper.mdl"

new g_spr_beam, g_spr_explode, g_spr_blast, g_spr_trapped, index_stamper
new g_maxplayers
new g_msgSayText, g_msgScreenShake
new g_roundend
new g_stamping[33]
new g_cooldown[33]
new g_frozen[33]
new g_use_stamp[33]
new Float:g_temp_speed[33]

const UNIT_SECOND = (1<<12)
const BREAK_WOOD = 0x08

#define EXPLOSION_RADIUS 200.0
#define EXPLOSION_KNOCKBACK 910.0
#define EXPLOSION_DAMAGE 10.0
#define SKILL_COOLDOWN 10.0
#define TIME_FREEZE 5.0
#define KOFFIN_HEALTH 265.0
#define HUMAN_TRAPPED_SPEED 70.0

enum (+= 100)
{
	TASK_BOT_USE_SKILL = 2367
}

#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_precache()
{
	precache_sound(STAMP_SOUND_DROP)
	precache_sound(STAMP_SOUND_HIT)
	precache_sound(STAMP_SOUND_EXPLODE)
	precache_sound(STAMP_SOUND_BREAK)
	precache_sound("zombie_plague/Zombi_Stamper_Clap.wav")
	precache_sound("zombie_plague/Zombi_Stamper_Glove.wav")
	index_stamper = precache_model("models/player/stamper_zombi_origin/stamper_zombi_origin.mdl")
	precache_model(STAMP_MODEL)
	precache_model(STAMPER_V_MODEL)
	precache_model(g_vgrenade)
	
	g_spr_beam = precache_model("sprites/shockwave.spr")
	g_spr_explode = precache_model("models/woodgibs.mdl")
	g_spr_blast = precache_model("sprites/zombiebomb_exp.spr")
	g_spr_trapped = precache_model("sprites/slowed.spr")	
}

public plugin_init()
{
	register_plugin("Zombie: The Hero ZmClass Stamper", "1.0.9", "yokomo")
	
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")
	register_event("CurWeapon","EventCurWeapon","be","1=1")
	register_event("DeathMsg", "EventDeath", "a")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_clcmd("drop", "CmdStampCoffin")
	RegisterHam(Ham_TraceAttack, "info_target", "CoffinTraceAttack")
	RegisterHam(Ham_Think, "info_target", "CoffinThink")
	
	g_maxplayers = get_maxplayers()
	g_msgSayText = get_user_msgid("SayText")
	g_msgScreenShake = get_user_msgid("ScreenShake")
}

public client_putinserver(id)
{
	stamper_reset_value(id)
}

public client_disconnect(id)
{
	stamper_reset_value(id)
}

public EventHLTV()
{
	g_roundend = 0
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(is_user_connected(id)) stamper_reset_value(id);
	}
}

public logevent_round_end(id)
{
	g_roundend = 1
	
	RemoveAllCoffin()
	stamper_reset_value(id)
}

public plugin_natives()
{
	register_native("give_stamper", "native_give_stamper", 1)
	register_native("stamper_reset_value", "native_stamper_reset_value", 1)
}

public native_give_stamper(id)
{
        give_stamper(id)
}

public native_stamper_reset_value(id)
{
        stamper_reset_value(id)
}

public zp_user_humanized_post(id)
{
	stamper_reset_value(id)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id)) return FMRES_IGNORED
	
	if (class_stamper[id])
	{
		if (g_use_stamp[id])
		{
			set_uc(uc_handle, UC_Buttons, IN_ATTACK2)
			g_use_stamp[id] = 0
			set_task(0.1, "TaskSequence", id)
		}
	}
	
	return FMRES_IGNORED
}


public EventDeath()
{
	new id = read_data(2)
	if(is_user_connected(id)) stamper_reset_value(id);
}

public give_stamper(id)
{
	stamper_reset_value(id)
	class_stamper[id] = true
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	zp_override_user_model(id, "stamper_zombi_origin")
	set_pdata_int(id, 491, index_stamper, 5)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [G]^x01 to Spawn Coffin")
	
	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		return
	}
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_alive(id)) return;

	CmdStampCoffin(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	replace_weapon_models(id, read_data(2))
	if(g_frozen[id]) set_pev(id, pev_maxspeed, HUMAN_TRAPPED_SPEED);
	if(class_stamper[id]) set_user_maxspeed(id, zclass_speed)
	
	new weap = get_user_weapon(id)
	
	if(weap == CSW_SMOKEGRENADE && class_stamper[id] && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_vgrenade)
	}
	
	return PLUGIN_HANDLED
}

public CmdStampCoffin(id)
{
	if(g_roundend) return PLUGIN_CONTINUE
	
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE
	
	if(class_stamper[id] && get_user_weapon(id) == CSW_KNIFE)
	{
		if(!g_stamping[id] && !g_cooldown[id])
		{
			g_stamping[id] = 1
			g_use_stamp[id] = 1
			set_task(0.5, "TaskStampCoffin", id+TASK_STAMP)
			
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}

public TaskSequence(id)
{
	PlayPlayerAnimation(id, 10)
	PlayWeaponAnimation(id, 2)
}

public TaskStampCoffin(taskid)
{
	g_stamping[ID_STAMP] = 0
	g_cooldown[ID_STAMP] = 1
	
	CreateCoffinCancer(ID_STAMP)
	
	set_task(SKILL_COOLDOWN, "ResetCooldown", ID_STAMP+TASK_COOLDOWN)
}

public ResetCooldown(taskid)
{
	g_cooldown[ID_COOLDOWN] = 0
	
	zp_colored_print(ID_COOLDOWN, "^x04[Zombie: The Hero]^x01 Your skill^x04 Spawn Coffin^x01 is ready.")
}

public ResetFreeze(taskid)
{
	UnFreezePlayer(ID_FREEZE)
}

public BotAutoSkill(taskid)
{
	if(!is_user_alive(ID_BOT)) return;
	
	CmdStampCoffin(ID_BOT)
	set_task(random_float(6.0,15.0), "BotAutoSkill", ID_BOT+TASK_BOT)
}

public CoffinTraceAttack(ent, attacker, Float: damage, Float: direction[3], trace, damageBits)
{
	if(ent == attacker || !is_user_connected(attacker) || !is_valid_ent(ent)) return HAM_IGNORED;
	
	if(!(damageBits & DMG_BULLET)) return HAM_IGNORED;
	
	new className[32];
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className))
	
	if(!equali(className, STAMP_CLASSNAME)) return HAM_IGNORED;
	
	new Float: end[3]
	get_tr2(trace, TR_vecEndPos, end);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	message_end()
	
	emit_sound(ent, CHAN_VOICE, STAMP_SOUND_HIT,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	return HAM_IGNORED;
}

public CoffinThink(ent)
{
	if(!is_valid_ent(ent)) return;
	
	static className[32];
	entity_get_string(ent, EV_SZ_classname, className, charsmax(className))
	
	if(!equali(className, STAMP_CLASSNAME)) return;
	
	Coffin_gagal(ent)
}

CreateCoffinCancer(id)
{	
	new Float: origin[3], Float: angle[3], Float:angle2[3], Float:vector[3]
	entity_get_vector(id, EV_VEC_origin, origin)
	get_origin_distance(id, vector, 40.0)
	vector[2] += 25.0
	entity_get_vector(id, EV_VEC_angles, angle)
	new ent = create_entity("info_target")
	entity_set_string(ent, EV_SZ_classname, STAMP_CLASSNAME)
	entity_get_vector(ent, EV_VEC_angles, angle2)
	angle[0] = angle2[0]
	entity_set_vector(ent, EV_VEC_angles, angle)
	entity_set_origin(ent, vector)
	entity_set_float(ent, EV_FL_takedamage, 1.0)
	entity_set_float(ent, EV_FL_health, 1000.0+KOFFIN_HEALTH)
	entity_set_model(ent, STAMP_MODEL)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP)
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
	new Float:mins[3] = {-10.0, -6.0, -36.0}
	new Float:maxs[3] = {10.0, 6.0, 36.0}
	entity_set_size(ent, mins, maxs)
	entity_set_int(ent, EV_INT_iuser2, id)
	drop_to_floor(ent)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2]+200.0)
	write_short(g_spr_beam)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(10)
	write_byte(0)
	write_byte(150)
	write_byte(150)
	write_byte(150)
	write_byte(200)
	write_byte(0)
	message_end()

	emit_sound(ent, CHAN_VOICE, STAMP_SOUND_DROP,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.2, "TaskCoffinHealth", ent+TASK_HEALTH, _, _, "b")
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + SKILL_COOLDOWN)
	
	static victim; victim = -1
	while((victim = find_ent_in_sphere(victim, origin, EXPLOSION_RADIUS)) != 0)
	{
		if(!is_user_alive(victim) || zp_get_user_zombie(victim) || g_frozen[victim]) continue;
		
		SetFreezePlayer(victim)
		CreateScreenShake(victim)
		set_task(TIME_FREEZE, "ResetFreeze", victim+TASK_FREEZE)
	}
	
	set_task(0.2, "CheckStuck", ent)
}

public CheckStuck(ent)
{
	if(!is_valid_ent(ent)) return;
	
	if(is_player_stuck(ent)) Coffin_gagal(ent);
}

public TaskCoffinHealth(taskid)
{
	if(!is_valid_ent(ID_HEALTH)) return;
	
	if(pev(ID_HEALTH, pev_health) < 1000.0) CoffinExplodeKaboom(ID_HEALTH);
}

CoffinExplodeKaboom(ent)
{
	if(!is_valid_ent(ent)) return;

	remove_task(ent+TASK_HEALTH)
	
	static Float:flOrigin[3]
	entity_get_vector(ent, EV_VEC_origin, flOrigin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2])
	write_short(g_spr_blast)
	write_byte(40)
	write_byte(30)
	write_byte(14)
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2]+24)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, 25)
	write_byte(10)
	write_short(g_spr_explode)
	write_byte(10)
	write_byte(25)
	write_byte(BREAK_WOOD)
	message_end()
	
	emit_sound(ent, CHAN_VOICE, STAMP_SOUND_EXPLODE,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	static attacker; attacker = entity_get_int(ent, EV_INT_iuser2)
	
	if (!is_user_connected(attacker))
	{
		remove_entity(ent)
		return;
	}
	
	static victim; victim = -1
	
	while((victim = find_ent_in_sphere(victim, flOrigin, EXPLOSION_RADIUS)) != 0)
	{
		if(!is_user_alive(victim) || !is_valid_ent(victim)) continue;
		
		static Float:flVictimOrigin[3], Float:flDistance, Float:flSpeed, Float:flNewSpeed, Float:flVelocity[3]
		entity_get_vector(victim, EV_VEC_origin, flVictimOrigin)
		flDistance = get_distance_f(flOrigin, flVictimOrigin)
		flSpeed = EXPLOSION_KNOCKBACK
		flNewSpeed = flSpeed * (1.0 - (flDistance / EXPLOSION_RADIUS))
		GetSpeedVector(flOrigin, flVictimOrigin, flNewSpeed, flVelocity)
		entity_set_vector(victim, EV_VEC_velocity, flVelocity)
		CreateScreenShake(victim)
		
		if(get_user_health(victim) > EXPLOSION_DAMAGE) ExecuteHam(Ham_TakeDamage, victim, attacker, attacker, EXPLOSION_DAMAGE, DMG_BLAST);
		else ExecuteHamB(Ham_Killed, victim, attacker, 0);
	}
	
	remove_entity(ent)
}

Coffin_gagal(ent)
{
	if(!is_valid_ent(ent)) return;

	remove_task(ent+TASK_HEALTH)
	
	static Float:flOrigin[3]
	entity_get_vector(ent, EV_VEC_origin, flOrigin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2]+24)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, 25)
	write_byte(10)
	write_short(g_spr_explode)
	write_byte(10)
	write_byte(25)
	write_byte(BREAK_WOOD)
	message_end()
	
	emit_sound(ent, CHAN_VOICE, STAMP_SOUND_BREAK,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
	static attacker; attacker = entity_get_int(ent, EV_INT_iuser2)
	
	if (!is_user_connected(attacker))
	{
		remove_entity(ent)
		return;
	}
	
	remove_entity(ent)
}

PlayWeaponAnimation(id, animation)
{
	set_pev(id, pev_weaponanim, animation)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(animation)
	write_byte(pev(id, pev_body))
	message_end()
}

PlayPlayerAnimation(id, sequence, Float: framerate = 1.0) 
{
	set_pev(id, pev_animtime, get_gametime())
	set_pev(id, pev_framerate, framerate)
	set_pev(id, pev_frame, 0.0)
	set_pev(id, pev_sequence, sequence)
}

GetSpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1
}

SetFreezePlayer(id)
{
	g_frozen[id] = 1
	pev(id, pev_maxspeed, g_temp_speed[id])
	set_pev(id, pev_maxspeed, HUMAN_TRAPPED_SPEED)
	client_print(id, print_center, "You are trapped right now!")
	CreateSlowSprites(id)
}

UnFreezePlayer(id)
{
	g_frozen[id] = 0
	if(zp_get_user_zombie(id)) return;
	set_pev(id, pev_maxspeed, g_temp_speed[id])
	client_print(id, print_center, "You no longer trapped!")
	RemoveSlowSprites(id)
}

RemoveAllCoffin()
{	
	new ent
	ent = find_ent_by_class(-1, STAMP_CLASSNAME)
	
	while(ent > 0)
	{
		remove_task(ent+TASK_HEALTH)
		remove_entity(ent)
		ent = find_ent_by_class(-1, STAMP_CLASSNAME)
	}
}

get_origin_distance(index, Float:origin[3], Float:dist)
{
	new Float:start[3]
	new Float:view_ofs[3]
	
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	new Float:dest[3]
	pev(index, pev_angles, dest)
	
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	
	xs_vec_mul_scalar(dest, dist, dest)
	xs_vec_add(start, dest, dest)
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0)
	get_tr2(0, TR_vecEndPos, origin)
	
	return 1
}

is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true
	
	return false
}

CreateScreenShake(id)
{
	new shake[3]
	shake[0] = random_num(2,20)
	shake[1] = random_num(2,5)
	shake[2] = random_num(2,20)
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short(UNIT_SECOND*shake[0])
	write_short(UNIT_SECOND*shake[1])
	write_short(UNIT_SECOND*shake[2])
	message_end()
}

CreateSlowSprites(id)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(id)
	write_coord(35)
	write_short(g_spr_trapped)
	write_short(999)
	message_end()
}

RemoveSlowSprites(id)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_KILLPLAYERATTACHMENTS)
	write_byte(id)
	message_end()
}

replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case CSW_KNIFE:
	{
		if(!zp_get_user_zombie(id))
			return;
			
		if(class_stamper[id])
			{
				set_pev(id, pev_viewmodel2, STAMPER_V_MODEL)
				set_pev(id, pev_weaponmodel2, "")
			}
		}
	}
}

stamper_reset_value(id)
{
	if(g_frozen[id]) RemoveSlowSprites(id);
	
	g_stamping[id] = 0
	g_cooldown[id] = 0
	g_frozen[id] = 0
	class_stamper[id] = false

	remove_task(id+TASK_STAMP)
	remove_task(id+TASK_FREEZE)
	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_BOT)
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
