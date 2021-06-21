#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <fun>
#include <zombieplague>
#include <zth_humanskill>
#include <zth_money>

#define PLUGIN "Cannon"
#define VERSION "3.0"
#define AUTHOR "Dias"

#define CSW_CANNON CSW_UMP45
#define weapon_cannon "weapon_ump45"

#define DEFAULT_W_MODEL "models/w_ump45.mdl"
#define WEAPON_SECRET_CODE 4965
#define CANNONFIRE_CLASSNAME "cannon_round"

// Fire Start
#define WEAPON_ATTACH_F 30.0
#define WEAPON_ATTACH_R 10.0
#define WEAPON_ATTACH_U -5.0

#define TASK_RESET_AMMO 5434
#define FIREBURN_CLASSNAMES "fire_burnss"

const pev_ammo = pev_iuser4

new const WeaponModel[3][] =
{
	"models/v_cannon.mdl",
	"models/p_cannon.mdl",
	"models/w_cannon.mdl"
}

new const fire_burn[] = "sprites/flame_burn01.spr"

new const WeaponSound[2][] =
{
	"weapons/cannon-1.wav",
	"weapons/cannon_draw.wav"
}

new const WeaponResource[5][] = 
{
	"sprites/fire_cannon.spr",
	"sprites/weapon_cannon.txt",
	"sprites/640hud69.spr",
	"sprites/640hud2_cso.spr",
	"sprites/smokepuff.spr"
}

enum
{
	MODEL_V = 0,
	MODEL_P,
	MODEL_W
}

enum
{
	CANNON_ANIM_IDLE = 0,
	CANNON_ANIM_SHOOT1,
	CANNON_ANIM_SHOOT2,
	CANNON_ANIM_DRAW
}

new g_had_cannon[33], g_old_weapon[33], g_cannon_ammo[33], g_got_firsttime[33], Float:g_lastshot[33]
new g_cvar_defaultammo, g_cvar_reloadtime, g_cvar_radiusdamage
new g_smokepuff_id

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")

	register_think(CANNONFIRE_CLASSNAME, "fw_Cannon_Think")
	register_touch(CANNONFIRE_CLASSNAME, "*", "fw_Cannon_Touch")
	register_think(FIREBURN_CLASSNAMES, "fw_FireBurn_Think")
	
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_cannon, "fw_AddToPlayer_Post", 1)

	g_cvar_defaultammo = register_cvar("cannon_default_ammo", "20")
	g_cvar_reloadtime = register_cvar("cannon_reload_time", "3.5")
	g_cvar_radiusdamage = register_cvar("cannon_radius_damage", "400.0")
		
	register_clcmd("weapon_cannon", "hook_weapon")
}

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof(WeaponModel); i++)
		engfunc(EngFunc_PrecacheModel, WeaponModel[i])
	for(i = 0; i < sizeof(WeaponSound); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSound[i])
		
	engfunc(EngFunc_PrecacheModel, WeaponResource[0])
	engfunc(EngFunc_PrecacheGeneric, WeaponResource[1])
	engfunc(EngFunc_PrecacheModel, WeaponResource[2])
	engfunc(EngFunc_PrecacheModel, WeaponResource[3])
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, WeaponResource[4])
	precache_model(fire_burn)
}

public plugin_natives ()
{
	register_native("get_dragoncannon", "native_get_dragoncannon", 1)
	register_native("refill_dragoncannon", "native_refill_dragoncannon", 1)
}
public native_get_dragoncannon(id)
{
	get_dragoncannon(id)
}

public native_refill_dragoncannon(id)
{
	refill_dragoncannon(id)
}

public get_dragoncannon(id)
{
	if(!is_user_alive(id))
		return
		
	drop_weapons(id, 1)
		
	g_had_cannon[id] = 1
	g_cannon_ammo[id] = get_pcvar_num(g_cvar_defaultammo)
	fm_give_item(id, weapon_cannon)
}

public refill_dragoncannon(id)
{	
	if(g_had_cannon[id]) g_cannon_ammo[id] = 25
	
	if(get_user_weapon(id) == CSW_CANNON && g_had_cannon[id]) update_ammo(id)
}

public remove_dragoncannon(id)
{
	if(!is_user_connected(id))
		return
		
	g_had_cannon[id] = 0
	g_got_firsttime[id] = 0
	g_cannon_ammo[id] = 0
	
	remove_task(id+TASK_RESET_AMMO)
}

public hook_weapon(id) engclient_cmd(id, weapon_cannon)

public event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if(get_user_weapon(id) == CSW_CANNON && g_had_cannon[id])
	{
		if(!g_got_firsttime[id])
		{
			static cannon_weapon
			cannon_weapon = fm_find_ent_by_owner(-1, weapon_cannon, id)
	
			if(pev_valid(cannon_weapon)) cs_set_weapon_ammo(cannon_weapon, 25)
			g_got_firsttime[id] = 1
		}
		
		set_pev(id, pev_viewmodel2, WeaponModel[MODEL_V])
		set_pev(id, pev_weaponmodel2, WeaponModel[MODEL_P])
		
		if(g_old_weapon[id] != CSW_CANNON)
		{
			set_weapon_anim(id, CANNON_ANIM_DRAW)
			set_pdata_float(id, 83, 0.75, 5)
		}
			
		update_ammo(id)
	}
	
	g_old_weapon[id] = get_user_weapon(id)
}


public dragoncannon_shoothandle(id)
{
	if(get_pdata_float(id, 83, 5) <= 0.0 && get_gametime() - get_pcvar_float(g_cvar_reloadtime) > g_lastshot[id])
	{
		dragoncannon_shootnow(id)
		g_lastshot[id] = get_gametime()
	}
}

public dragoncannon_shootnow(id)
{
	if(g_cannon_ammo[id] == 1)
	{
		set_task(0.5, "set_weapon_outofammo", id+TASK_RESET_AMMO)
	}
	if(g_cannon_ammo[id] <= 0)
	{
		return
	}
	
	g_cannon_ammo[id]--
	update_ammo(id)
	
	Set_1st_Attack(id)
	set_task(0.1, "Set_2nd_Attack", id)
}

public Set_1st_Attack(id)
{
	create_fake_attack(id)
	
	set_weapon_anim(id, random_num(CANNON_ANIM_SHOOT1, CANNON_ANIM_SHOOT2))
	emit_sound(id, CHAN_WEAPON, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)	
	
	make_fire_effect(id)
	make_fire_smoke(id)
	
	static Float:VirtualVec[3]
	VirtualVec[0] = random_float(-3.5, -7.0)
	VirtualVec[1] = random_float(3.0, -3.0)
	VirtualVec[2] = 0.0
	
	set_pev(id, pev_punchangle, VirtualVec)	
}

public Set_2nd_Attack(id)
{
	create_fake_attack(id)
	
	set_weapon_anim(id, random_num(CANNON_ANIM_SHOOT1, CANNON_ANIM_SHOOT2))
	emit_sound(id, CHAN_WEAPON, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)	
	
	make_fire_effect(id)
	make_fire_smoke(id)
	check_radius_damage(id)
	
	set_player_nextattack(id, CSW_CANNON, get_pcvar_float(g_cvar_reloadtime))
	set_pdata_float(id, 83, get_pcvar_float(g_cvar_reloadtime), 5)	
}

public create_fake_attack(id)
{
	static cannon_weapon
	cannon_weapon = fm_find_ent_by_owner(-1, "weapon_ump45", id)
	
	new weaponX, szClip, szAmmo, Player
	
	if(!is_user_alive(Player))
		return
	
	Player = get_pdata_cbase(weaponX, 41, 4)
	
	get_user_weapon(Player, szClip, szAmmo)
	
	if(pev_valid(cannon_weapon)) ExecuteHamB(Ham_Weapon_PrimaryAttack, cannon_weapon)
	fm_set_weapon_ammo(weaponX, szClip++)
}

public set_weapon_outofammo(id)
{
	id -= TASK_RESET_AMMO
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_CANNON || !g_had_cannon[id])
		return
		
	set_weapon_anim(id, CANNON_ANIM_IDLE)
}

public make_fire_effect(id)
{
	const MAX_FIRE = 12
	static Float:StartOrigin[3], Float:TargetOrigin[MAX_FIRE][3], Float:Speed[MAX_FIRE]

	// Get Target
	
	// -- Left
	get_position(id, 100.0, random_float(-10.0, -30.0), WEAPON_ATTACH_U, TargetOrigin[0]); Speed[0] = 150.0
	get_position(id, 100.0, random_float(-10.0, -30.0), WEAPON_ATTACH_U, TargetOrigin[1]); Speed[1] = 180.0
	get_position(id, 100.0,	random_float(-10.0, -30.0), WEAPON_ATTACH_U, TargetOrigin[2]); Speed[2] = 210.0
	get_position(id, 100.0, random_float(-10.0, -30.0), WEAPON_ATTACH_U, TargetOrigin[3]); Speed[3] = 240.0
	get_position(id, 100.0, random_float(-10.0, -30.0), WEAPON_ATTACH_U, TargetOrigin[4]); Speed[4] = 300.0

	// -- Center
	get_position(id, 100.0, 0.0, WEAPON_ATTACH_U, TargetOrigin[5]); Speed[5] = 150.0
	get_position(id, 100.0, 0.0, WEAPON_ATTACH_U, TargetOrigin[6]); Speed[6] = 300.0
	
	// -- Right
	get_position(id, 100.0, random_float(10.0, 30.0), WEAPON_ATTACH_U, TargetOrigin[7]); Speed[7] = 150.0
	get_position(id, 100.0, random_float(10.0, 30.0), WEAPON_ATTACH_U, TargetOrigin[8]); Speed[8] = 180.0
	get_position(id, 100.0,	random_float(10.0, 30.0), WEAPON_ATTACH_U, TargetOrigin[9]); Speed[9] = 210.0
	get_position(id, 100.0, random_float(10.0, 30.0), WEAPON_ATTACH_U, TargetOrigin[10]); Speed[10] = 240.0
	get_position(id, 100.0, random_float(10.0, 30.0), WEAPON_ATTACH_U, TargetOrigin[11]); Speed[11] = 300.0

	for(new i = 0; i < MAX_FIRE; i++)
	{
		// Get Start
		get_position(id, random_float(30.0, 40.0), 0.0, WEAPON_ATTACH_U, StartOrigin)
		create_fire(id, StartOrigin, TargetOrigin[i], Speed[i])
	}
}

public create_fire(id, Float:Origin[3], Float:TargetOrigin[3], Float:Speed)
{
	new iEnt = create_entity("env_sprite")
	static Float:vfAngle[3], Float:MyOrigin[3], Float:Velocity[3]
	
	pev(id, pev_angles, vfAngle)
	pev(id, pev_origin, MyOrigin)
	
	vfAngle[2] = float(random(18) * 20)

	// set info for ent
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 250.0)
	set_pev(iEnt, pev_fuser1, get_gametime() + 2.5)	// time remove
	set_pev(iEnt, pev_scale, 1.0)
	set_pev(iEnt, pev_nextthink, halflife_time() + 0.05)
	
	entity_set_string(iEnt, EV_SZ_classname, CANNONFIRE_CLASSNAME)
	engfunc(EngFunc_SetModel, iEnt, WeaponResource[0])
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_gravity, 0.01)
	set_pev(iEnt, pev_angles, vfAngle)
	set_pev(iEnt, pev_solid, SOLID_TRIGGER)
	set_pev(iEnt, pev_owner, id)	
	set_pev(iEnt, pev_frame, 0.0)
	
	get_speed_vector(Origin, TargetOrigin, Speed, Velocity)
	set_pev(iEnt, pev_velocity, Velocity)
}

public fw_Cannon_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	new Float:fFrame, Float:fNextThink, Float:fScale
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)
	
	// effect exp
	new iMoveType = pev(iEnt, pev_movetype)
	if (iMoveType == MOVETYPE_NONE)
	{
		fNextThink = 0.0015
		fFrame += 0.5
		
		if (fFrame > 21.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
	
	// effect normal
	else
	{
		fNextThink = 0.045
		
		fFrame += 0.5
		fScale += 0.01
		
		fFrame = floatmin(21.0, fFrame)
		fScale = floatmin(2.0, fFrame)
	}
	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, fScale)
	set_pev(iEnt, pev_nextthink, halflife_time() + fNextThink)
	
	// time remove
	new Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
}

public fw_Cannon_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	if(pev_valid(id))
	{
		static Classname[32]
		pev(id, pev_classname, Classname, sizeof(Classname))
		
		if(equal(Classname, CANNONFIRE_CLASSNAME)) return
	}
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
}

public make_fire_smoke(id)
{
	static Float:Origin[3]
	get_position(id, WEAPON_ATTACH_F, WEAPON_ATTACH_R, WEAPON_ATTACH_U, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_EXPLOSION) 
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_smokepuff_id) 
	write_byte(10)
	write_byte(30)
	write_byte(14)
	message_end()
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
	write_byte(1)
	write_byte(CSW_CANNON)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(6)
	write_byte(g_cannon_ammo[id])
	message_end()
}

public check_radius_damage(id)
{
	static Float:Origin[3], Float:myOrigin[3]
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(!zp_get_user_zombie(i))
			continue
		if(id == i)
			continue
		pev(i, pev_origin, Origin)
		pev(id, pev_origin, myOrigin)
		if(!is_in_viewcone(id, Origin, 1))
			continue
		if(entity_range(id, i) >= get_pcvar_float(g_cvar_radiusdamage))
			continue
		if(is_wall_between_points(myOrigin, Origin, id))
			continue
		
		new bool:bIsHeadShot, bool:death, Float:dmg[33]
		
		if(using_ds(id))
		{
			bIsHeadShot = true
			if(entity_range(id, i) <= 200) dmg[id] = 2600.0
			else dmg[id] = 1600.0
		}
		else
		{
			bIsHeadShot = false
			if(entity_range(id, i) <= 200) dmg[id] = 900.0
			else dmg[id] = 500.0
		}
		
		if(pev(i, pev_health) <= dmg[id]) death = true 
		
		if( bIsHeadShot && death)
		{
			zp_cs_set_user_money(id, zp_cs_get_user_money(id) + 1000)
			
			emessage_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
			ewrite_byte(id)
			ewrite_byte(i)
			ewrite_byte(1)
			ewrite_string("Black Dragon Cannon")
			emessage_end()
			
			set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
			user_silentkill(i)
			set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
			
			new kfrags = get_user_frags( id );
			set_user_frags( id, kfrags+1 );
			new vfrags = get_user_frags( i );
			set_user_frags( i, vfrags+1 );
			
			death = false
		}
		else if( !bIsHeadShot && death)
		{
			zp_cs_set_user_money(id, zp_cs_get_user_money(id) + 1000)
			
			emessage_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
			ewrite_byte(id)
			ewrite_byte(i)
			ewrite_byte(0)
			ewrite_string("Black Dragon Cannon")
			emessage_end()
			
			set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
			user_silentkill(i)
			set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
			
			new kfrags = get_user_frags( id );
			set_user_frags( id, kfrags+1 );
			new vfrags = get_user_frags( i );
			set_user_frags( i, vfrags+1 );

			death = false
		}
		
		
		else ExecuteHamB(Ham_TakeDamage, i, 0, id, dmg[id], DMG_BLAST)
		
		hook_ent2(i, myOrigin, 850.0, 2)
		Make_FireBurn(i)
	}
}

public Make_FireBurn(id)
{
	static Ent; Ent = fm_find_ent_by_owner(-1, FIREBURN_CLASSNAMES, id)
	if(!pev_valid(Ent) && is_user_alive(id) && zp_get_user_zombie(id))
	{
		new iEnt = create_entity("env_sprite")
		static Float:MyOrigin[3]
		
		pev(id, pev_origin, MyOrigin)
		
		// set info for ent
		set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
		set_pev(iEnt, pev_rendermode, kRenderTransAdd)
		set_pev(iEnt, pev_renderamt, 250.0)
		set_pev(iEnt, pev_fuser1, get_gametime() + 10.0)	// time remove
		set_pev(iEnt, pev_scale, 1.0)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.5)
		
		entity_set_string(iEnt, EV_SZ_classname, FIREBURN_CLASSNAMES)
		engfunc(EngFunc_SetModel, iEnt, fire_burn)
		set_pev(iEnt, pev_origin, MyOrigin)
		set_pev(iEnt, pev_owner, id)
		set_pev(iEnt, pev_aiment, id)
		set_pev(iEnt, pev_frame, 0.0)
	}
}

public fw_FireBurn_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	static Float:fFrame
	pev(iEnt, pev_frame, fFrame)

	// effect exp
	fFrame += 1.0
	if(fFrame > 15.0) fFrame = 0.0

	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
	
	static id
	id = pev(iEnt, pev_owner)
	
	if(get_gametime() - 1.0 > pev(iEnt, pev_fuser2))
	{
		if((get_user_health(id) - 30) > 0)
			set_user_health(id, get_user_health(id) - 30)
		set_pev(iEnt, pev_fuser2, get_gametime())
	}
	
	// time remove
	static Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_CANNON || !g_had_cannon[id])
		return FMRES_IGNORED
	
	set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_CANNON || !g_had_cannon[id])
		return FMRES_IGNORED
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		dragoncannon_shoothandle(id)
	}
	
	return FMRES_HANDLED
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(entity, pev_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, DEFAULT_W_MODEL))
	{
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_cannon, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_cannon[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRET_CODE)
			set_pev(weapon, pev_ammo, g_cannon_ammo[id])
			
			engfunc(EngFunc_SetModel, entity, WeaponModel[MODEL_W])
			remove_dragoncannon(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public zp_user_infected_post(id)
{
	remove_dragoncannon(id)
}

public fw_Spawn_Post(id)
{
	remove_dragoncannon(id)
}

public fw_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRET_CODE)
	{
		remove_dragoncannon(id)
		
		g_had_cannon[id] = 1
		g_got_firsttime[id] = 0
		g_cannon_ammo[id] = pev(ent, pev_ammo)
	}
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_had_cannon[id] == 1 ? "weapon_cannon" : "weapon_ump45")
	write_byte(6)
	write_byte(20)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(15)
	write_byte(CSW_CANNON)
	write_byte(0)
	message_end()			
	
	return HAM_HANDLED
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, 51, amount, 4);
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
}

stock set_player_nextattack(player, weapon_id, Float:NextTime)
{
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

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	static Float:EntVelocity[3]
	
	pev(ent, pev_velocity, EntVelocity)
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	static Float:fl_Time; fl_Time = distance_f / speed
	
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
	
	xs_vec_add(EntVelocity, fl_Velocity, fl_Velocity)
	set_pev(ent, pev_velocity, fl_Velocity)
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}
