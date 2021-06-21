#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>
#include <zth_humanskill>
#include <zth_money>
#include <fun>

#define PLUGIN "Balrog-XI"
#define VERSION "2.0"
#define AUTHOR "Dias - modify m4m3ts"

#define V_MODEL "models/v_balrog11_blue.mdl"
#define P_MODEL "models/p_balrog11_blue.mdl"
#define W_MODEL "models/w_balrog11_blue.mdl"

#define CSW_BALROG11 CSW_XM1014
#define weapon_balrog11 "weapon_xm1014"

#define OLD_W_MODEL "models/w_xm1014.mdl"
#define OLD_EVENT "events/xm1014.sc"
#define WEAPON_SECRETCODE 1982

#define DRAW_TIME 1.0
#define DAMAGE 52
#define FIRE_DAMAGE 500
#define BPAMMO 64
#define RADIUS_DAMAGE 400

#define CHARGE_COND_AMMO 4
#define MAX_SPECIAL_AMMO 7
#define SPECIALSHOOT_DELAY 0.35
#define FIRE_SPEED 1500
#define SYSTEM_CLASSNAME "balrog11_firesystem"

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41
const m_flNextAttack = 83
const m_flNextPrimaryAttack	= 46
const m_flNextSecondaryAttack	= 47

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
		
new const WeaponSounds[5][] = 
{
	"weapons/balrog11-1.wav",
	"weapons/balrog11-2.wav",
	"weapons/balrog11_draw.wav",
	"weapons/balrog11_insert.wav",
	"weapons/balrog11_charge.wav"
}

new const WeaponResources[4][] =
{
	"sprites/flame_puff01_blue.spr",
	"sprites/weapon_balrog11.txt",
	"sprites/640hud89_2.spr",
	"sprites/640hud89_2.spr"
}

enum
{
	B11_ANIM_IDLE = 0,
	B11_ANIM_SHOOT,
	B11_ANIM_SHOOT_SPECIAL,
	B11_ANIM_INSERT,
	B11_ANIM_AFTER_RELOAD,
	B11_ANIM_START_RELOAD,
	B11_ANIM_DRAW
}

new g_had_balrog11[33], g_holding_attack[33], g_Shoot_Count[33], g_SpecialAmmo[33]
new g_old_weapon[33], g_event_balrog11, g_Msg_StatusIcon, g_smokepuff_id, g_ham_bot
new g_bl11

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_think(SYSTEM_CLASSNAME, "fw_Think")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")	
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog11, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_balrog11, "fw_Item_PostFrame")
	RegisterHam(Ham_Item_Deploy, weapon_balrog11, "fw_Item_Deploy_Post", 1)
		
	g_Msg_StatusIcon = get_user_msgid("StatusIcon")
	
	//register_clcmd("admin_get_balrog11", "Get_Balrog11", ADMIN_BAN)
	register_clcmd("weapon_balrog11", "hook_weapon")
	
	g_bl11 = zp_register_extra_item("balrog11", 3, ZP_TEAM_HUMAN)
}

public zp_extra_item_selected(id, itemid)
{
	// Check if the selected item matches any of our registered ones
	if (itemid == g_bl11) Get_Balrog11(id)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	new i
	for(i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	for(i = 0; i < sizeof(WeaponResources); i++)
	{
		if(i == 1) engfunc(EngFunc_PrecacheGeneric, WeaponResources[i])
		else engfunc(EngFunc_PrecacheModel, WeaponResources[i])
	}
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
}

public plugin_natives()
{
    register_native("Get_Balrog11", "native_Get_Balrog11", 1)
}

public native_Get_Balrog11(id)
{
	Get_Balrog11(id)
}

public Player_Spawn(id)
{
	Remove_Balrog11(id)
}

public fw_PlayerKilled(id)
{
	Remove_Balrog11(id)
}


public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(OLD_EVENT, name))
		g_event_balrog11 = get_orig_retval()
}

public zp_user_infected_post(id) Remove_Balrog11(id)

public Get_Balrog11(id)
{
	if(!is_user_alive(id))
		return
		
	drop_weapons(id, 1)
	Remove_Balrog11(id)
		
	g_had_balrog11[id] = 1
	g_old_weapon[id] = 0
	g_holding_attack[id] = 0
	g_Shoot_Count[id] = 0
	g_SpecialAmmo[id] = 0
	
	fm_give_item(id, weapon_balrog11)
	cs_set_user_bpammo(id, CSW_BALROG11, BPAMMO)
	
	update_ammo(id)
	update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
}

public Remove_Balrog11(id)
{
	if(!is_user_connected(id))
		return
		
	update_specialammo(id, g_SpecialAmmo[id], 0)
		
	g_had_balrog11[id] = 0
	g_old_weapon[id] = 0
	g_holding_attack[id] = 0
	g_Shoot_Count[id] = 0
	g_SpecialAmmo[id] = 0	
}

public hook_weapon(id)
{
	engclient_cmd(id, weapon_balrog11)
	return PLUGIN_HANDLED
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return	
	
	if(g_had_balrog11[id] && (get_user_weapon(id) == CSW_BALROG11 && g_old_weapon[id] != CSW_BALROG11))
	{ // Balrog Draw
		set_weapon_anim(id, B11_ANIM_DRAW)
		set_player_nextattack(id, DRAW_TIME)
		
		update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
	} else if(get_user_weapon(id) != CSW_BALROG11 && g_old_weapon[id] == CSW_BALROG11) {
		update_specialammo(id, g_SpecialAmmo[id], 0)
	}
	
	g_old_weapon[id] = get_user_weapon(id)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_BALROG11 || !g_had_balrog11[id])
		return
		
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	static OldButton; OldButton = pev(id, pev_oldbuttons)
	
	if(NewButton & IN_ATTACK)
	{
		if(!g_holding_attack[id]) g_holding_attack[id] = 1
	} else if(NewButton & IN_ATTACK2) {
		SpecialShoot_Handle(id)
	} else {
		if(OldButton & IN_ATTACK)
		{
			if(g_holding_attack[id]) 
			{
				g_holding_attack[id] = 0
				g_Shoot_Count[id] = 0
			}
		}
	}
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
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_BALROG11)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_balrog11[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser4, g_SpecialAmmo[id])
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			Remove_Balrog11(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BALROG11 && g_had_balrog11[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED		
	if(get_user_weapon(invoker) == CSW_BALROG11 && g_had_balrog11[invoker] && eventid == g_event_balrog11)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	

		if(g_holding_attack[invoker]) g_Shoot_Count[invoker]++
		else g_Shoot_Count[invoker] = 0
		
		if(g_Shoot_Count[invoker] >= CHARGE_COND_AMMO)
		{
			g_Shoot_Count[invoker] = 0
			
			if(g_SpecialAmmo[invoker] < MAX_SPECIAL_AMMO) 
			{
				update_specialammo(invoker, g_SpecialAmmo[invoker], 0)
				g_SpecialAmmo[invoker]++
				update_specialammo(invoker, g_SpecialAmmo[invoker], 1)
				
				emit_sound(invoker, CHAN_ITEM, WeaponSounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
		}
		
		set_weapon_anim(invoker, B11_ANIM_SHOOT)
		emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)	

		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

public fw_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_user_alive(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BALROG11 || !g_had_balrog11[Attacker])
		return HAM_IGNORED

	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
		
	if(!is_user_alive(Ent))
	{
		make_bullet(Attacker, flEnd)
		fake_smoke(Attacker, ptr)
	}
		
	SetHamParamFloat(3, float(DAMAGE) / random_float(1.5, 2.5))	

	return HAM_HANDLED		
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_had_balrog11[id] = 1
		
		set_pev(ent, pev_impulse, 0)
		g_SpecialAmmo[id] = pev(ent, pev_iuser4)
	}			
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string((g_had_balrog11[id] == 1 ? "weapon_balrog11" : "weapon_xm1014"))
	write_byte(5)
	write_byte(32)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(12)
	write_byte(CSW_BALROG11)
	write_byte(0)
	message_end()
}

public fw_Item_PostFrame(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_had_balrog11[id])
		return
		
	if(get_pdata_int(ent, 55, OFFSET_LINUX_WEAPONS) == 1) set_weapon_anim(id, B11_ANIM_INSERT)
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_had_balrog11[id])
		return
		
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
	
	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_BALROG11)
	if(!pev_valid(weapon_ent)) return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_BALROG11)
	write_byte(cs_get_weapon_ammo(weapon_ent))
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(cs_get_user_bpammo(id, CSW_BALROG11))
	message_end()
}

public update_specialammo(id, Ammo, On)
{
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)
  	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red
	write_byte(212) // green
	write_byte(255) // blue
	message_end()
}

public SpecialShoot_Handle(id)
{
	if(get_pdata_float(id, 83, 5) > 0.0)
		return
	if(g_SpecialAmmo[id] <= 0)
		return		

	create_fake_attack(id)	
	
	// Shoot Handle
	set_player_nextattack(id, SPECIALSHOOT_DELAY)
	set_weapons_timeidle(id, CSW_BALROG11, SPECIALSHOOT_DELAY)
	
	update_specialammo(id, g_SpecialAmmo[id], 0)
	g_SpecialAmmo[id]--
	update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
	
	set_weapon_anim(id, B11_ANIM_SHOOT_SPECIAL)
	emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	Create_FireSystem(id)
	check_radius_damage(id)
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
		if(entity_range(id, i) >= float(RADIUS_DAMAGE))
			continue
		if(is_wall_between_points(myOrigin, Origin, id))
			continue
		
		new bool:bIsHeadShot, bool:death, Float:dmg[33]
		
		if(using_ds(id))
		{
			bIsHeadShot = true
			dmg[id] = 600.0
		}
		else
		{
			bIsHeadShot = false
			dmg[id] = float(FIRE_DAMAGE)
		}
		
		if(pev(i, pev_health) <= dmg[id]) death = true 
		
		if( bIsHeadShot && death)
		{
			zp_cs_set_user_money(id, zp_cs_get_user_money(id) + 1000)
			
			emessage_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
			ewrite_byte(id)
			ewrite_byte(i)
			ewrite_byte(1)
			ewrite_string("Balrog-XI")
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
		else ExecuteHamB(Ham_TakeDamage, i, 0, id, dmg[id], DMG_BULLET)
	}
}

public create_fake_attack(id)
{
	static weapon
	weapon = fm_find_ent_by_owner(-1, "weapon_xm1014", id)
	
	new weaponX, szClip, szAmmo, Player
	
	if(!is_user_alive(Player))
		return
	
	Player = get_pdata_cbase(weaponX, 41, 4)
	
	get_user_weapon(Player, szClip, szAmmo)
	
	if(pev_valid(weapon)) ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon)
	fm_set_weapon_ammo(weaponX, szClip++)
}

public Create_FireSystem(id)
{
	static Float:StartOrigin[3], Float:EndOrigin[8][3]
	get_weapon_attachment(id, StartOrigin, 10.0)
	
	// Left
	get_position(id, 70.0, -10.0, 0.0, EndOrigin[0])
	get_position(id, 70.0, -5.0, 0.0, EndOrigin[1])
	
	// Center
	get_position(id, 70.0, 0.0, 0.0, EndOrigin[2])
	
	// Right
	get_position(id, 70.0, 10.0, 0.0, EndOrigin[3])
	get_position(id, 70.0, 20.0, 0.0, EndOrigin[4])
	
	get_position(id, 70.0, -12.0, 0.0, EndOrigin[5])
	get_position(id, 70.0, 15.0, 0.0, EndOrigin[6])
	get_position(id, 70.0, 4.0, 0.0, EndOrigin[7])
	
	for(new i = 0; i < 8; i++) Create_System(id, StartOrigin, EndOrigin[i], 1300.0)
}

public Create_System(id, Float:StartOrigin[3], Float:EndOrigin[3], Float:Speed)
{
	new ent = create_entity("env_sprite")
	static Float:vfAngle[3], Float:MyOrigin[3], Float:Velocity[3]
	
	pev(id, pev_angles, vfAngle)
	pev(id, pev_origin, MyOrigin)
	
	vfAngle[2] = float(random(18) * 20)
	
	// set info for ent
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 150.0)
	set_pev(ent, pev_fuser1, get_gametime() + 0.6)	// time remove
	set_pev(ent, pev_scale, 1.0)
	set_pev(ent, pev_nextthink, halflife_time() + 0.05)
	
	entity_set_string(ent, EV_SZ_classname, SYSTEM_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, WeaponResources[0])
	set_pev(ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(ent, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(ent, pev_origin, StartOrigin)
	set_pev(ent, pev_gravity, 0.01)
	set_pev(ent, pev_angles, vfAngle)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_owner, id)	
	set_pev(ent, pev_frame, 0.0)
	
	get_speed_vector(StartOrigin, EndOrigin, Speed, Velocity)
	set_pev(ent, pev_velocity, Velocity)		
}

public fw_Think(ent)
{
	if(!pev_valid(ent)) 
		return
	
	static Classname[32]; pev(ent, pev_classname, Classname, sizeof(Classname))
	if(equal(Classname, SYSTEM_CLASSNAME))
	{	
		static Float:fFrame; pev(ent, pev_frame, fFrame)
	
		fFrame += 1.5
		fFrame = floatmin(21.0, fFrame)
	
		set_pev(ent, pev_frame, fFrame)
		set_pev(ent, pev_nextthink, get_gametime() + 0.05)
		
		// time remove
		static Float:fTimeRemove
		pev(ent, pev_fuser1, fTimeRemove)
		
		if (get_gametime() < fTimeRemove)
		{
			new Float:fade_out
			pev(ent, pev_renderamt, fade_out)
			fade_out -= 15.0
			fade_out = floatmax(fade_out, 0.0)
			set_pev(ent, pev_renderamt, fade_out)
		}
		
		if(get_gametime() >= fTimeRemove) 
		{
			engfunc(EngFunc_RemoveEntity, ent)
		}
	}
}

public fw_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
		
	if(!equal(Classname, SYSTEM_CLASSNAME))
		return
		
	if(pev_valid(id))
	{
		static Classname2[32]
		pev(id, pev_classname, Classname2, sizeof(Classname2))
		
		if(equal(Classname2, SYSTEM_CLASSNAME)) return
		else if(is_user_alive(id) && zp_get_user_zombie(id))
		{
			ExecuteHamB(Ham_TakeDamage, id, 0, pev(ent, pev_owner), 0.0, DMG_BULLET)
			
			return
		}
	}
		
	if(!is_user_alive(id))
	{
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		set_pev(ent, pev_solid, SOLID_NOT)
	}
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

stock fake_smoke(id, trace_result)
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
	write_byte(50)
	write_byte(TE_FLAG)
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

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
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

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
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

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
     
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
