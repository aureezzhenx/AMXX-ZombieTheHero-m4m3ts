#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <fakemeta>
#include <engine>
#include <zombieplague>
#include <fun>
#include <zth_hero>
#include <hamsandwich>

#define PLUGIN "NST Zombie Class Deimos"
#define VERSION "1.0"
#define AUTHOR "NST"

// Bits
#define Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));

const Float:zclass_speed = 255.0
const Float:zclass_gravity = 0.8

new const light_classname[] = "nst_deimos_skill"

new class_deimos[33]
const skill_dmg = 300
const Float:skill_time_wait = 7.0

new const sound_skill_start[] = "zombie_plague/deimos_skill_start.wav"
new const sound_skill_hit[] = "zombie_plague/deimos_skill_hit2.wav"
new sprites_exp_index, sprites_trail_index

new g_wait[33]

new g_useskill[33]

new g_maxplayers
new g_msgSayText, g_msgScreenFade, g_msgScreenShake
new g_roundend, index_deimos

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

enum (+= 100)
{
	TASK_WAIT = 2000,
	TASK_WAIT2,
	TASK_ATTACK,
	TASK_BOT_USE_SKILL,
	TASK_BOT_USE_SKILL2,
	TASK_USE_SKILL
}

#define ID_WAIT (taskid - TASK_WAIT)
#define ID_WAIT2 (taskid - TASK_WAIT2)
#define ID_ATTACK (taskid - TASK_ATTACK)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_BOT_USE_SKILL2 (taskid - TASK_BOT_USE_SKILL2)
#define ID_USE_SKILL (taskid - TASK_USE_SKILL)
new DEIMOS_V_MODEL[64] = "models/zombie_plague/v_knife_deimos_zombi.mdl"
new const g_vgrenade[] = "models/zombie_plague/v_zombibomb_deimos.mdl"
const UNIT_SECOND = (1<<12)
const FFADE_IN = 0x0000
const m_flTimeWeaponIdle = 48
const m_flNextAttack = 83
//////////////////////////////////////////////////////////////////
// Skill 2
#define DASH_SPEED 1500.0
new const DashSound[] = "zombie_plague/deimos_dash.wav"
#define TASK_DASHING 25001
new g_bisa_dash[33]
new g_lagi_dash[33]
new g_wait2[33]
const Float:skill2_time_wait = 10.0
new g_InTempingAttack
///////////////////////////////////////////////////////////////////
public plugin_precache()
{
	sprites_exp_index = precache_model("sprites/deimosexp.spr")
	sprites_trail_index = precache_model("sprites/laserbeam.spr")
	precache_sound(DashSound)
	precache_sound(sound_skill_start)
	precache_sound(sound_skill_hit)
	index_deimos = precache_model("models/player/deimos_zombi_origin/deimos_zombi_origin.mdl")
	precache_model(DEIMOS_V_MODEL)
	precache_model(g_vgrenade)
	////gabung aja coy
	plugin_precache2()
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_event("CurWeapon","EventCurWeapon","be","1=1")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_Touch, "fw_Touch")

	register_clcmd("drop", "use_skill")
	
	g_maxplayers = get_maxplayers()
	g_msgSayText = get_user_msgid("SayText")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	////gabung aja coy
	plugin_init2() 
}

public plugin_natives()
{
	register_native("give_deimos", "native_give_deimos", 1)
	register_native("deimos_reset_value_player", "native_deimos_reset_value", 1)
	////gabung aja coy
	plugin_natives2()
}

public native_give_deimos(id)
{
        give_deimos(id)
}

public native_deimos_reset_value(id)
{
        deimos_reset_value_player(id)
}


public client_putinserver(id)
{
	deimos_reset_value_player(id)
}

public client_disconnect(id)
{
	deimos_reset_value_player(id)
}

public event_round_start()
{
	g_roundend = 0
	
	for (new id=1; id<=g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		deimos_reset_value_player(id)
	}
}

public logevent_round_end()
{
	g_roundend = 1
}

public Death()
{
	new victim = read_data(2) 
	
	deimos_reset_value_player(victim)
}

public give_deimos(id)
{
	deimos_reset_value_player(id)
	class_deimos[id] = true
	//remove_task(id+TASK_DASHING)
	Remove_CameraEnt(id, 1)
	g_bisa_dash[id] = 1
	g_lagi_dash[id] = 0
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	zp_override_user_model(id, "deimos_zombi_origin")
	set_pdata_int(id, 491, index_deimos, 5)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [G]^x01 to Light attack")
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [R]^x01 to Mahadash")
	
	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		set_task(random_float(5.0,15.0), "bot_use_skill2", id+TASK_BOT_USE_SKILL2)
		return
	}
	
}

public zp_user_humanized_post(id)
{
	deimos_reset_value_player(id)
}

public use_skill(id)
{
	if (g_roundend) return PLUGIN_CONTINUE
	
	if (!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE
	
	new health = get_user_health(id) - skill_dmg
	
	if (class_deimos[id] && !g_wait[id] && health>0 && get_user_weapon(id)==CSW_KNIFE)
	{
		g_useskill[id] = 1
		g_wait[id] = 1
		
		fm_set_user_health(id, health)
		set_task(skill_time_wait, "RemoveWait", id+TASK_WAIT)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_alive(id)) return;

	use_skill(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public bot_use_skill2(taskid)
{
	new id = ID_BOT_USE_SKILL2
	if (!is_user_alive(id)) return;

	Skill_Mahadash(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill2", id+TASK_BOT_USE_SKILL2)
}

public task_use_skill(taskid)
{
	new id = ID_USE_SKILL
	
	play_weapon_anim(id, 8)
	set_weapons_timeidle(id, skill_time_wait)
	set_weapons_timeidle(id, skill2_time_wait)
	set_player_nextattack(id, 0.5)
	PlayEmitSound(id, sound_skill_start)
	entity_set_int(id, EV_INT_sequence, 10)
	set_task(0.5, "launch_light", id+TASK_ATTACK)
}

public launch_light(taskid)
{
	new id = ID_ATTACK

	if (!is_user_alive(id)) return;
	
	new Float:vecAngle[3],Float:vecOrigin[3],Float:vecVelocity[3],Float:vecForward[3]
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	fm_get_user_startpos(id,5.0,2.0,-1.0,vecOrigin)
	pev(id,pev_angles,vecAngle)
	engfunc(EngFunc_MakeVectors,vecAngle)
	global_get(glb_v_forward,vecForward)
	velocity_by_aim(id,2000,vecVelocity)
	set_pev(ent,pev_origin,vecOrigin)
	set_pev(ent,pev_angles,vecAngle)
	set_pev(ent,pev_classname,light_classname)
	set_pev(ent,pev_movetype,MOVETYPE_FLY)
	set_pev(ent,pev_solid,SOLID_BBOX)
	engfunc(EngFunc_SetSize,ent,{-1.0,-1.0,-1.0},{1.0,1.0,1.0})
	engfunc(EngFunc_SetModel,ent,"models/w_hegrenade.mdl")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_velocity,vecVelocity)
	
	set_rendering(ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMFOLLOW)
	write_short(ent)
	write_short(sprites_trail_index)
	write_byte(5)
	write_byte(3)
	write_byte(209)
	write_byte(120)
	write_byte(9)
	write_byte(200)
	message_end()
	
	return;
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	replace_weapon_models(id, read_data(2))
	if(class_deimos[id]) set_user_maxspeed(id, zclass_speed)
	
	new weap = get_user_weapon(id)
	
	if(weap == CSW_SMOKEGRENADE && class_deimos[id] && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_vgrenade)
	}
	
	return PLUGIN_HANDLED
}

public fw_Touch(ent, victim)
{
	if (!pev_valid(ent)) return FMRES_IGNORED
	
	new EntClassName[32]
	entity_get_string(ent, EV_SZ_classname, EntClassName, charsmax(EntClassName))
	
	if (equal(EntClassName, light_classname)) 
	{
		light_exp(ent, victim)
		
		return FMRES_IGNORED
	}
	
	return FMRES_IGNORED
}

light_exp(ent, victim)
{
	if (!pev_valid(ent)) return;
	
	if (is_user_alive(victim) && !zp_get_user_zombie(victim) && !zp_get_user_survivor(victim))
	{
		new wpn, wpnname[32]
		wpn = get_user_weapon(victim)
		if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)) && !revo_get_user_hero(victim))
		{
			engclient_cmd(victim, "drop", wpnname)
		}
		
		message_begin(MSG_ONE, g_msgScreenFade, _, victim)
		write_short(UNIT_SECOND)
		write_short(0)
		write_short(FFADE_IN)
		write_byte(209)
		write_byte(120)
		write_byte(9)
		write_byte (255)
		message_end()
	
		message_begin(MSG_ONE, g_msgScreenShake, _, victim)
		write_short(UNIT_SECOND*4)
		write_short(UNIT_SECOND*2)
		write_short(UNIT_SECOND*10)
		message_end()
	}
	
	PlayEmitSound(ent, sound_skill_hit)
	
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(sprites_exp_index)
	write_byte(40)
	write_byte(30)
	write_byte(14)
	message_end()
	
	remove_entity(ent)
}

public RemoveWait(taskid)
{
	new id = ID_WAIT
	g_wait[id] = 0
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Light Attack^x01 is ready.")
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id)) 
		return 
	
	if(!class_deimos[id])
		return
	
	if (class_deimos[id])
	{
		if (g_useskill[id])
		{
			set_uc(uc_handle, UC_Buttons, IN_ATTACK2)
			g_useskill[id] = 0
			remove_task(id+TASK_USE_SKILL)
			set_task(0.1, "task_use_skill", id+TASK_USE_SKILL)
		}
	}
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if (CurButton & IN_RELOAD)
	{
		Skill_Mahadash(id)
	}
}

public zevo_set_fakeattack(id, Animation)
{
	if(!is_user_alive(id))
		return
		
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(Ent)) return
	
	Set_BitVar(g_InTempingAttack, id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
	
	// Set Real Attack Anim
	set_pev(id, pev_sequence, Animation)
	UnSet_BitVar(g_InTempingAttack, id)
}

public Skill_Mahadash(id)
{
	if(g_wait2[id])
	     return
	if(!g_bisa_dash[id])
		return
	if(g_lagi_dash[id])
		return
	if((pev(id, pev_flags) & FL_DUCKING) || !(pev(id, pev_flags) & FL_ONGROUND))
		return
		
	g_bisa_dash[id] = 0
	g_lagi_dash[id] = 1
	g_wait2[id] = 1
	// Prepartion
	engclient_cmd(id, "weapon_knife")
	
	Set_CameraEnt(id)
	set_pev(id, pev_maxspeed, 0.01)
	set_pev(id, pev_gravity, 10.0)
	
	zevo_set_fakeattack(id, 111)
	Set_Player_NextAttack(id, 1.8)
	
	remove_task(id+TASK_DASHING)
	set_task(0.75, "Mahadashing", id+TASK_DASHING)
	set_task(1.75, "Mahadash_End", id+TASK_DASHING)
	set_task(skill2_time_wait, "RemoveWait2", id+TASK_WAIT2)
}
public RemoveWait2(taskid)
{
	new id = ID_WAIT2
	g_wait2[id] = 0
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Mahadash^x01 is ready.")
}

public Mahadashing(id)
{
	id -= TASK_DASHING
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_deimos[id])
		return
	if(!g_lagi_dash[id])
		return
		
	static Float:Origin[3], Float:Target[3], Float:Vel[3]
	
	PlayEmitSound(id, DashSound)
	pev(id, pev_origin, Origin)
	get_position(id, 640.0, 0.0, 0.0, Target)
	Get_SpeedVector(Origin, Target, DASH_SPEED, Vel)
	
	set_pev(id, pev_gravity, zclass_gravity)
	set_pev(id, pev_velocity, Vel)
}

public Mahadash_End(id)
{
	id -= TASK_DASHING
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || !class_deimos[id])
		return
	if(!g_lagi_dash[id])
		return
		
	g_lagi_dash[id] = 0
	g_bisa_dash[id] = 1
	
	Remove_CameraEnt(id, 1)
	set_pev(id, pev_maxspeed, zclass_speed)
	set_pev(id, pev_gravity, zclass_gravity)
	
	Set_Player_NextAttack(id, 0.75)
	set_weapons_timeidle(id, 1.0)
	play_weapon_anim(id, 3)
}
stock Get_SpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= (num * 2.0)
	new_velocity[1] *= (num * 2.0)
	new_velocity[2] *= (num / 2.0)
}  

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	//vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

play_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

get_weapon_ent(id, weaponid)
{
	static wname[32], weapon_ent
	get_weaponname(weaponid, wname, charsmax(wname))
	weapon_ent = find_ent_by_owner(-1, wname, id)
	return weapon_ent
}

set_weapons_timeidle(id, Float:timeidle)
{
	new entwpn = get_weapon_ent(id, get_user_weapon(id))
	if (pev_valid(entwpn)) set_pdata_float(entwpn, m_flTimeWeaponIdle, timeidle+3.0, 4)
}

set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, m_flNextAttack, nexttime, 4)
}

fm_get_user_startpos(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_MakeVectors, vAngle)
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case CSW_KNIFE:
	{
		if(!zp_get_user_zombie(id))
			return;
			
		if(class_deimos[id])
			{
				set_pev(id, pev_viewmodel2, DEIMOS_V_MODEL)
				set_pev(id, pev_weaponmodel2, "")
			}
		}
	}
}

deimos_reset_value_player(id)
{
	g_wait[id] = 0
	g_wait2[id] = 0
	g_useskill[id] = 0
	g_bisa_dash[id] = 0
	g_lagi_dash[id] = 0
	class_deimos[id] = false
	remove_task(id+TASK_WAIT)
	remove_task(id+TASK_WAIT2)
	remove_task(id+TASK_ATTACK)
	remove_task(id+TASK_BOT_USE_SKILL)
	remove_task(id+TASK_BOT_USE_SKILL2)
	remove_task(id+TASK_USE_SKILL)
	remove_task(id+TASK_DASHING)
	Remove_CameraEnt(id, 1)
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
stock Set_Player_NextAttack(id, Float:Time)
{
	if(pev_valid(id) != 2)
		return
		
	set_pdata_float(id, 83, Time, 5)
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
////////////////////////////////////////////////////////////////////////////////////////////////
/* The info of this plugin */
#define PLUGIN_VERSION "0.7"
#define PLUGIN_TAG "CAM"

/* Just dont touch it */
#define CAMERA_OWNER EV_INT_iuser1
#define CAMERA_CLASSNAME "trigger_camera"
#define CAMERA_MODEL "models/rpgrocket.mdl"
new bool:g_bInThirdPerson[33] = false;
new g_pCvar_fCameraDistance, g_pCvar_iCameraForced;

public plugin_init2() 
{
	register_plugin("Obscura Cam", PLUGIN_VERSION, "Nani (SkumTomteN@Alliedmodders)")

	register_think(CAMERA_CLASSNAME, "FW_CameraThink")
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	
	g_pCvar_iCameraForced = register_cvar("cam_forced", "0")
	g_pCvar_fCameraDistance = register_cvar("cam_distance", "250.0")
}

public plugin_precache2() 
{
	precache_model(CAMERA_MODEL)
}

public plugin_natives2()
{
	register_native("set_user_camera", "Native_SetCamera", 1)
	register_native("get_user_camera", "Native_GetCamera", 1)
}

public Native_SetCamera(iPlayer, Thirdperson)
{
	if(!is_user_alive(iPlayer))
		return;
	
	if(!Thirdperson) 
	{
		Set_CameraEnt(iPlayer)
	}
	else 
	{
		Remove_CameraEnt(iPlayer, 1)
	}
}
public Native_GetCamera(iPlayer)
{
	if(!is_user_connected(iPlayer) || !g_bInThirdPerson[iPlayer])
		return 0;
	
	return 1;
}
public fw_PlayerSpawn_Post(iPlayer) 
{ 
	if(!is_user_alive(iPlayer)) 
		return HAM_IGNORED;
	
	if(g_bInThirdPerson[iPlayer] || get_pcvar_num(g_pCvar_iCameraForced)) 
	{ 
		//Set_CameraEnt(iPlayer) 
	} 
	else 
	{ 
		Remove_CameraEnt(iPlayer, 1) 
	} 
	return HAM_HANDLED;
}  

public fw_PlayerKilled_Post(iVictim, iKiller, iShouldGIB)
{	
	if(!is_user_connected(iVictim) || is_user_alive(iVictim))
		return HAM_IGNORED;
	
	if(g_bInThirdPerson[iVictim])
	{
		Remove_CameraEnt(iVictim, 0)
	}
	return HAM_HANDLED;
}

public CMD_ToggleCam(iPlayer) 
{ 
    if(get_pcvar_num(g_pCvar_iCameraForced)) 
    { 
        client_printc(iPlayer, "!g[%s]!n Camera is forced on !t3rd person!n by server manager!", PLUGIN_TAG) 
        return; 
    } 
     
    g_bInThirdPerson[iPlayer] = ~g_bInThirdPerson[iPlayer] 
     
    if(is_user_alive(iPlayer)) 
    { 
        if(g_bInThirdPerson[iPlayer]) 
        { 
            Set_CameraEnt(iPlayer) 

          //  client_print(0, print_center, "3rd Person Mode") 
        } 
        else  
        { 
            Remove_CameraEnt(iPlayer, 1) 
             
          //  client_print(0, print_center, "1st Person Mode") 
        } 
    } 
    else /* He toggles when not alive */ 
    { 
        client_printc(iPlayer, "!g[%s]!n Your camera will be !t%s!n when you spawn!", PLUGIN_TAG, g_bInThirdPerson[iPlayer] ? "3rd Person" : "1st Person") 
    } 
}  

public Set_CameraEnt(iPlayer)
{
	new iEnt = create_entity(CAMERA_CLASSNAME);
	if(!is_valid_ent(iEnt)) return;

	entity_set_model(iEnt, CAMERA_MODEL)
	entity_set_int(iEnt, CAMERA_OWNER, iPlayer)
	entity_set_string(iEnt, EV_SZ_classname, CAMERA_CLASSNAME)
	entity_set_int(iEnt, EV_INT_solid, SOLID_NOT)
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FLY)
	entity_set_int(iEnt, EV_INT_rendermode, kRenderTransTexture)

	attach_view(iPlayer, iEnt)

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime())
}

public Remove_CameraEnt(iPlayer, AttachView)
{
	if(AttachView) attach_view(iPlayer, iPlayer)

	new iEnt = -1;
	while((iEnt = find_ent_by_class(iEnt, CAMERA_CLASSNAME)))
	{
		if(!is_valid_ent(iEnt))
			continue;
		
		if(entity_get_int(iEnt, CAMERA_OWNER) == iPlayer) 
		{
			entity_set_int(iEnt, EV_INT_flags, FL_KILLME)
			dllfunc(DLLFunc_Think, iEnt)
		}
	}
}

public FW_CameraThink(iEnt)
{
	new iOwner = entity_get_int(iEnt, CAMERA_OWNER);
	if(!is_user_alive(iOwner) || is_user_bot(iOwner))
		return;
	if(!is_valid_ent(iEnt))
		return;

	new Float:fPlayerOrigin[3], Float:fCameraOrigin[3], Float:vAngles[3], Float:vBack[3];

	entity_get_vector(iOwner, EV_VEC_origin, fPlayerOrigin)
	entity_get_vector(iOwner, EV_VEC_view_ofs, vAngles)
		
	fPlayerOrigin[2] += vAngles[2];
			
	entity_get_vector(iOwner, EV_VEC_v_angle, vAngles)

	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vBack) 

	fCameraOrigin[0] = fPlayerOrigin[0] + (-vBack[0] * get_pcvar_float(g_pCvar_fCameraDistance)) 
	fCameraOrigin[1] = fPlayerOrigin[1] + (-vBack[1] * get_pcvar_float(g_pCvar_fCameraDistance)) 
	fCameraOrigin[2] = fPlayerOrigin[2] + (-vBack[2] * get_pcvar_float(g_pCvar_fCameraDistance)) 

	engfunc(EngFunc_TraceLine, fPlayerOrigin, fCameraOrigin, IGNORE_MONSTERS, iOwner, 0) 
	
	new Float:flFraction; get_tr2(0, TR_flFraction, flFraction) 
	if(flFraction != 1.0)
	{ 
		flFraction *= get_pcvar_float(g_pCvar_fCameraDistance); /* Automatic :) */
	
		fCameraOrigin[0] = fPlayerOrigin[0] + (-vBack[0] * flFraction) 
		fCameraOrigin[1] = fPlayerOrigin[1] + (-vBack[1] * flFraction) 
		fCameraOrigin[2] = fPlayerOrigin[2] + (-vBack[2] * flFraction) 
	} 
	
	entity_set_vector(iEnt, EV_VEC_origin, fCameraOrigin)
	entity_set_vector(iEnt, EV_VEC_angles, vAngles)

	entity_set_float(iEnt, EV_FL_nextthink, get_gametime())
}
stock client_printc(index, const text[], any:...)
{
	static szMsg[128]; vformat(szMsg, sizeof(szMsg) - 1, text, 3)
	
	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04")
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01")
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03")
	
	static g_MsgSayText; if(!g_MsgSayText) g_MsgSayText = get_user_msgid("SayText")
	static MaxPlayers; MaxPlayers = get_maxplayers();

	if(!index)
	{
		for(new i = 1; i <= MaxPlayers; i++)
		{
			if(!is_user_connected(i))
				continue;
			
			message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, i);
			write_byte(i);
			write_string(szMsg);
			message_end();	
		}		
	} 
	else 
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 
