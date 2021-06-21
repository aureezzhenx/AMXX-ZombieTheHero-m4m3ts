#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombieplague>

#define PLUGIN "Janus 1"
#define VERSION "1.1"
#define AUTHOR "m4m3ts"

#define CSW_JANUS1 CSW_FIVESEVEN
#define weapon_janus1 "weapon_fiveseven"
#define old_event "events/fiveseven.sc"
#define old_w_model "models/w_fiveseven.mdl"
#define WEAPON_SECRETCODE 4234234


#define DEFAULT_AMMO 5
#define RELOAD_TIME 3.0
#define STAB_TIME 1.5
#define ATTACK_TIME 3.0
#define SHOOT_TIME 0.5
#define SHOOT_B_TIME 0.4
#define DAMAGE 190.0
#define SYSTEM_CLASSNAME "janus1"
#define TASK_STABING 2033+10

const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41
const m_flNextAttack = 83
const m_szAnimExtention = 492

new const v_model[] = "models/v_janus1.mdl"
new const p_model[] = "models/p_janus1.mdl"
new const w_model[] = "models/w_janus1.mdl"
new const GRENADE_MODEL[] = "models/grenade.mdl"
new const GRENADE_EXPLOSION[] = "sprites/fexplo.spr"
new const weapon_sound[7][] = 
{
	"weapons/janus1-1.wav",
	"weapons/janus1-2.wav",
	"weapons/janus1_exp.wav",
	"weapons/janus1_draw.wav",
	"weapons/janus1_change1.wav",
	"weapons/janus1_change2.wav",
	"weapons/m79_draw.wav"
}


new const WeaponResource[4][] = 
{
	"sprites/weapon_janus1.txt",
	"sprites/640hud7.spr",
	"sprites/640hud12.spr",
	"sprites/640hud100.spr"
}

enum
{
	ANIM_IDLE = 0,
	ANIM_DRAW_NORMAL,
	ANIM_SHOOT_NORMAL,
	ANIM_SHOOT_ABIS,
	ANIM_SHOOT_SIGNAL,
	ANIM_CHANGE_1,
	ANIM_IDLE_B,
	ANIM_DRAW_B,
	ANIM_SHOOT_B,
	ANIM_SHOOT_B2,
	ANIM_CHANGE_2,
	ANIM_SIGNAL,
	ANIM_DRAW_SIGNAL,
	ANIM_SHOOT2_SIGNAL
}

new sExplo

new g_had_janus1[33], g_janus_ammo[33], shoot_mode[33], hit_janus1[33], hit_on[33]
new g_old_weapon[33], g_smokepuff_id, m_iBlood[2]
new sTrail, g_MaxPlayers

const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_think(SYSTEM_CLASSNAME, "fw_Think")
	register_touch(SYSTEM_CLASSNAME, "*", "fw_touch")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Item_AddToPlayer, weapon_janus1, "fw_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_janus1, "fw_janusidleanim", 1)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	g_MaxPlayers = get_maxplayers()
	register_clcmd("weapon_janus1", "hook_weapon")
}


public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)
	precache_model(GRENADE_MODEL)
	sExplo = precache_model(GRENADE_EXPLOSION)
	
	for(new i = 0; i < sizeof(weapon_sound); i++) 
		precache_sound(weapon_sound[i])
	
	precache_generic(WeaponResource[0])
	for(new i = 1; i < sizeof(WeaponResource); i++)
		precache_model(WeaponResource[i])
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	sTrail = precache_model("sprites/laserbeam.spr")
}

public zp_user_infected_post(id)
{
	remove_janus(id)
}


public plugin_natives()
{
	register_native("get_janus1", "native_get_janus1", 1)
	register_native("refill_janus1", "native_refill_janus1", 1)
}

public native_get_janus1(id)
{
	get_janus1(id)
}

public native_refill_janus1(id)
{
	refill_janus1(id)
}

public Player_Spawn(id)
{
	remove_janus(id)
}

public fw_PlayerKilled(id)
{
	remove_janus(id)
}

public hook_weapon(id)
{
	engclient_cmd(id, weapon_janus1)
	return
}

public get_janus1(id)
{
	if(!is_user_alive(id))
		return
	remove_task(id+TASK_STABING)
	drop_weapons(id, 1)
	g_had_janus1[id] = 1
	g_janus_ammo[id] = DEFAULT_AMMO
	shoot_mode[id] = 1
	hit_janus1[id] = 0
	hit_on[id] = 0
	
	give_item(id, weapon_janus1)
	update_ammo(id)
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, weapon_janus1, id)
	if(pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, 1)
}

public refill_janus1(id)
{
	if(g_had_janus1[id])
	{
		g_janus_ammo[id] = 8
		hit_janus1[id] = 0
	}
	
	if(get_user_weapon(id) == CSW_JANUS1 && g_had_janus1[id]) update_ammo(id)
}

public remove_janus(id)
{
	remove_task(id+TASK_STABING)
	g_had_janus1[id] = 0
	g_janus_ammo[id] = 0
}
	
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_JANUS1 && g_had_janus1[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_JANUS1)
	{
		if(g_had_janus1[iAttacker])
			set_msg_arg_string(4, "grenade")
	}
                
	return PLUGIN_CONTINUE
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if(get_user_weapon(id) == CSW_JANUS1 && g_had_janus1[id])
	{
		set_pev(id, pev_viewmodel2, v_model)
		set_pev(id, pev_weaponmodel2, p_model)
		if(shoot_mode[id] == 1) set_weapon_anim(id, ANIM_DRAW_NORMAL)
		if(shoot_mode[id] == 2) set_weapon_anim(id, ANIM_DRAW_SIGNAL)
		if(shoot_mode[id] == 3) set_weapon_anim(id, ANIM_DRAW_B)
		update_ammo(id)
	}
	
	g_old_weapon[id] = get_user_weapon(id)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_JANUS1 || !g_had_janus1[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_JANUS1)
	if(!pev_valid(ent))
		return
	if(get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, OFFSET_LINUX_WEAPONS) > 0.0) 
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
			
		if(g_janus_ammo[id] == 1 && get_pdata_float(id, 83, 5) <= 0.0)
		{
			set_weapon_anim(id, ANIM_SHOOT_ABIS)
			emit_sound(id, CHAN_WEAPON, weapon_sound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
			g_janus_ammo[id]--
			Firejanus1(id)
			update_ammo(id)
			set_weapons_timeidle(id, CSW_JANUS1, SHOOT_TIME)
			set_player_nextattackx(id, SHOOT_TIME)
		}
		if(g_janus_ammo[id] >= 2  && shoot_mode[id] == 1 && get_pdata_float(id, 83, 5) <= 0.0)
		{
			set_weapon_anim(id, ANIM_SHOOT_NORMAL)
			g_janus_ammo[id]--
			Firejanus1(id)
			update_ammo(id)
			emit_sound(id, CHAN_WEAPON, weapon_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_weapons_timeidle(id, CSW_JANUS1, ATTACK_TIME)
			set_player_nextattackx(id, ATTACK_TIME)
		}
		if(shoot_mode[id] == 3 && get_pdata_float(id, 83, 5) <= 0.0)
		{
			set_weapon_anim(id, ANIM_SHOOT_B2)
			Firejanus1(id)
			emit_sound(id, CHAN_WEAPON, weapon_sound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_weapons_timeidle(id, CSW_JANUS1, SHOOT_B_TIME)
			set_player_nextattackx(id, SHOOT_B_TIME)
		}
	}
	else if(CurButton & IN_ATTACK2)
	{
		if(shoot_mode[id] == 2)
		{
			set_weapon_anim(id, ANIM_CHANGE_1)
			shoot_mode[id] = 3
			update_ammo(id)
			set_task(8.5, "back_normal", id)
			set_task(8.5, "back_normal2", id)
			set_weapons_timeidle(id, CSW_JANUS1, STAB_TIME)
			set_player_nextattackx(id, STAB_TIME)
		}
	}
}

public back_normal(id)
{
	if(get_user_weapon(id) != CSW_JANUS1 || !g_had_janus1[id])
		return
		
	set_weapon_anim(id, ANIM_CHANGE_2)
	emit_sound(id, CHAN_WEAPON, weapon_sound[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_weapons_timeidle(id, CSW_JANUS1, STAB_TIME)
	set_player_nextattackx(id, STAB_TIME)
	update_ammo(id)
}

public back_normal2(id)
{
	shoot_mode[id] = 1
	hit_janus1[id] = 0
}

public ready_transform(id)
{
	shoot_mode[id] = 2
	set_weapons_timeidle(id, CSW_JANUS1, STAB_TIME)
	set_player_nextattackx(id, STAB_TIME)
}

public fw_janusidleanim(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_had_janus1[id] || get_user_weapon(id) != CSW_JANUS1)
		return HAM_IGNORED;

	if(shoot_mode[id] == 1) 
		return HAM_SUPERCEDE;
	
	if(shoot_mode[id] == 3 && get_pdata_float(Weapon, 48, 4) <= 0.25)
	{
		set_weapon_anim(id, ANIM_IDLE_B)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}
	
	if(shoot_mode[id] == 2 && get_pdata_float(Weapon, 48, 4) <= 0.25) 
	{
		set_weapon_anim(id, ANIM_SIGNAL)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public Firejanus1(id)
{
	new Float:origin[3],Float:velocity[3],Float:angles[3]
	engfunc(EngFunc_GetAttachment, id, 0, origin,angles)
	pev(id,pev_angles,angles)
	new ent = create_entity( "info_target" ) 
	set_pev( ent, pev_classname, SYSTEM_CLASSNAME )
	set_pev( ent, pev_solid, SOLID_BBOX )
	set_pev( ent, pev_movetype, MOVETYPE_TOSS )
	set_pev( ent, pev_mins, { -0.1, -0.1, -0.1 } )
	set_pev( ent, pev_maxs, { 0.1, 0.1, 0.1 } )
	entity_set_model( ent, GRENADE_MODEL )
	set_pev( ent, pev_origin, origin )
	set_pev( ent, pev_angles, angles )
	set_pev( ent, pev_owner, id )
	velocity_by_aim( id, 1350, velocity )
	set_pev( ent, pev_velocity, velocity )
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(ent) // Entity
	write_short(sTrail) // Sprite index
	write_byte(10) // Life
	write_byte(3) // Line width
	write_byte(255) // Red
	write_byte(255) // Green
	write_byte(255) // Blue
	write_byte(50) // Alpha
	message_end() 
	return PLUGIN_CONTINUE
}

public fw_Think_Plasma(ptr)
{
	if(!pev_valid(ptr))
		return
		
	static Float:RenderAmt; pev(ptr, pev_renderamt, RenderAmt)
	
	RenderAmt += 50.0
	RenderAmt = float(clamp(floatround(RenderAmt), 0, 255))
	
	set_pev(ptr, pev_renderamt, RenderAmt)
	set_pev(ptr, pev_nextthink, halflife_time() + 0.1)
}

public fw_touch(ptr, ptd)
{
	// If ent is valid
	if (pev_valid(ptr))
	{
			// Get it's origin
			new Float:originF[3]
			pev(ptr, pev_origin, originF)
			engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
			write_byte(TE_WORLDDECAL)
			engfunc(EngFunc_WriteCoord, originF[0])
			engfunc(EngFunc_WriteCoord, originF[1])
			engfunc(EngFunc_WriteCoord, originF[2])
			write_byte(engfunc(EngFunc_DecalIndex,"{scorch3"))
			message_end()
			// Draw explosion
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION) // Temporary entity ID
			engfunc(EngFunc_WriteCoord, originF[0]) // engfunc because float
			engfunc(EngFunc_WriteCoord, originF[1])
			engfunc(EngFunc_WriteCoord, originF[2]+30.0)
			write_short(sExplo) // Sprite index
			write_byte(35) // Scale
			write_byte(35) // Framerate
			write_byte(0) // Flags
			message_end()
			emit_sound(ptr, CHAN_WEAPON, weapon_sound[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			Damage_janus1(ptr, ptd)
			
			engfunc(EngFunc_RemoveEntity, ptr)
	}
		
}

public Damage_janus1(ptr, ptd)
{
	static Owner; Owner = pev(ptr, pev_owner)
	static Attacker
	if(!is_user_alive(Owner)) 
	{
		Attacker = 0
		return
	} else Attacker = Owner
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(i, ptr) > 200.0)
			continue
		if(!zp_get_user_zombie(i))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, Attacker, DAMAGE, DMG_BULLET)
		hit_on[Attacker] = 1
	}
	
	if(hit_on[Attacker] && hit_janus1[Attacker] < 6)
	{
		hit_janus1[Attacker] ++
		hit_on[Attacker] = 0
	}
	
	if(hit_janus1[Attacker] == 5 && shoot_mode[Attacker] == 1) set_task(0.5, "ready_transform", Attacker)
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, old_w_model))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_JANUS1)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_janus1[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser4, g_janus_ammo[id])
			engfunc(EngFunc_SetModel, entity, w_model)
			
			g_had_janus1[id] = 0
			g_janus_ammo[id] = 0
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_had_janus1[id] = 1
		g_janus_ammo[id] = pev(ent, pev_iuser4)
		
		set_pev(ent, pev_impulse, 0)
	}			
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string((g_had_janus1[id] == 1 ? "weapon_janus1" : "weapon_fiveseven"))
	write_byte(1)
	write_byte(100)
	write_byte(-1)
	write_byte(-1)
	write_byte(1)
	write_byte(6)
	write_byte(CSW_JANUS1)
	write_byte(0)
	message_end()
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, weapon_janus1, id)
	if(pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, 1)	
	
	cs_set_user_bpammo(id, CSW_FIVESEVEN, 0)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_JANUS1)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(g_janus_ammo[id])
	message_end()
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new decal = random_num(41, 45)
	const loop_time = 2
	
	static Body, Target
	get_user_aiming(id, Target, Body, 999999)
	
	if(is_user_connected(Target))
		return
	
	for(new i = 0; i < loop_time; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

public fake_smoke(id, trace_result)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(80)
	write_byte(TE_FLAG)
	message_end()	
}

public fake_smokes(id, Float:Origin[3])
{
	static TE_FLAG
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] - 10.0)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(80)
	write_byte(TE_FLAG)
	message_end()
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}


stock set_player_light(id, const LightStyle[])
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id)
	write_byte(0)
	write_string(LightStyle)
	message_end()
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(8)
	message_end()
}

stock set_player_screenfade(pPlayer, sDuration = 0, sHoldTime = 0, sFlags = 0, r = 0, g = 0, b = 0, a = 0 )
{
	if(!is_user_connected(pPlayer))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, pPlayer)
	write_short(sDuration)
	write_short(sHoldTime)
	write_short(sFlags)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(a)
	message_end()
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	 
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		  
		if (dropwhat == 1 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	static Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, OFFSET_LINUX_WEAPONS)
}

stock set_player_nextattack(player, weapon_id, Float:NextTime)
{
	if(!is_user_alive(player))
		return
	
	const m_flNextPrimaryAttack = 46
	const m_flNextSecondaryAttack = 47
	const m_flTimeWeaponIdle = 48
	const m_flNextAttack = 83
	
	static weapon
	weapon = fm_get_user_weapon_entity(player, weapon_id)
	
	set_pdata_float(player, m_flNextAttack, NextTime, 5)
	if(pev_valid(weapon))
	{
		set_pdata_float(weapon, m_flNextPrimaryAttack , NextTime, 4)
		set_pdata_float(weapon, m_flNextSecondaryAttack, NextTime, 4)
		set_pdata_float(weapon, m_flTimeWeaponIdle, NextTime, 4)
	}
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}
