#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <fun>
#include <zombieplague>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define b1_WEAPONKEY 	621
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

#define b1_SHOOT1			2
#define b1_SHOOT2		  	3
#define b1_SHOOT_EMPTY			3
#define b1_RELOAD			4
#define b1_DRAW				5
#define b1_RELOAD_TIME 3.0
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)
#define FIREBURN_CLASSNAME "fire_burn"

new const Fire_Sounds[][] = { "weapons/balrog1-1.wav", "weapons/balrog1-2.wav" }

new b1_V_MODEL[64] = "models/v_balrog1.mdl"
new b1_P_MODEL[64] = "models/p_Balrog_1.mdl"
new b1_W_MODEL[64] = "models/w_balrog1.mdl"
new const fire_burn[] = "sprites/flame_burn01.spr"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new cvar_dmg_b1, cvar_recoil_b1, cvar_clip_b1, cvar_spd_b1, cvar_b1_ammo
new g_MaxPlayers, g_orig_event_b1, g_IsInPrimaryAttack, g_iClip
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_b1[33], g_clip_ammo[33], oldweap[33],g_b1_TmpClip[33]
new gmsgWeaponList, gMode[33], fireburn[33], sExplo

const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_deagle", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("[ZP] Extra: Balrog-I", "1.0", "Barney")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_deagle", "fw_b1_AddToPlayer")
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_deagle", "b1_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "b1_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "b1_Reload_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_b1_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_b1_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_think(FIREBURN_CLASSNAME, "fw_FireBurn_Think")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)


	cvar_dmg_b1 = register_cvar("zp_b1_dmg", "0.9")
	cvar_recoil_b1 = register_cvar("zp_b1_recoil", "1.0")
	cvar_clip_b1 = register_cvar("zp_b1_clip", "10")
	cvar_spd_b1 = register_cvar("zp_b1_spd", "0.7")
	cvar_b1_ammo = register_cvar("zp_b1_ammo", "100")

	g_MaxPlayers = get_maxplayers()
	gmsgWeaponList = get_user_msgid("WeaponList")
}

public plugin_precache()
{
	precache_model(b1_V_MODEL)
	precache_model(b1_P_MODEL)
	precache_model(b1_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])	
	precache_sound("weapons/balrog1_changea.wav")
	precache_sound("weapons/balrog1_changeb.wav")
	precache_sound("weapons/balrog1_draw.wav")
	precache_sound("weapons/balrog1_reload.wav")
	precache_sound("weapons/balrog1_reloadb.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_generic("sprites/weapon_balrog1.txt")
   	precache_generic("sprites/640hud83.spr")
    	precache_generic("sprites/640hud4.spr")
	sExplo = precache_model("sprites/ef_balrog1.spr")
	precache_model(fire_burn)
	register_clcmd("weapon_balrog1", "weapon_hook")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public weapon_hook(id)
{
    engclient_cmd(id, "weapon_deagle")
    return PLUGIN_HANDLED
}

public Player_Spawn(id)
{
	if (is_user_alive(id))
	{
		g_has_b1[id] = false
		fireburn[id] = false
	}
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_DEAGLE) return
	
	if(!g_has_b1[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}

public zp_user_humanized_post(id)
{
	g_has_b1[id] = false
}

public plugin_natives ()
{
	register_native("give_b1", "native_give_b1", 1)
	register_native("get_fireburn", "native_fireburn", 1)
}
public native_give_b1(id)
{
	give_b1(id)
}

public native_fireburn(id)
{
	return fireburn[id];
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/deagle.sc", name))
	{
		g_orig_event_b1 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_b1[id] = false
	fireburn[id] = false
}

public client_disconnect(id)
{
	g_has_b1[id] = false
}

public zp_user_infected_post(id)
{
	g_has_b1[id] = false
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_deagle.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_deagle", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_b1[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, b1_WEAPONKEY)
			
			g_has_b1[iOwner] = false
			
			entity_set_model(entity, b1_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_b1(id)
{
	drop_weapons(id, 2)
	new iWep2 = fm_give_item(id,"weapon_deagle")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_b1))
		cs_set_user_bpammo (id, CSW_DEAGLE, get_pcvar_num(cvar_b1_ammo))	
		
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string("weapon_balrog1")
		write_byte(8)
		write_byte(35)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)
		write_byte(1)
		write_byte(CSW_DEAGLE)
		message_end()
	}
	g_has_b1[id] = true
}


public fw_b1_AddToPlayer(b1, id)
{
	if(!is_valid_ent(b1) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(b1, EV_INT_WEAPONKEY) == b1_WEAPONKEY)
	{
		g_has_b1[id] = true
		
		entity_set_int(b1, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_balrog1")
		write_byte(8)
		write_byte(35)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)   
		write_byte(1) 
		write_byte(CSW_DEAGLE)
		message_end()
		
		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_deagle")
		write_byte(8)
		write_byte(35)
		write_byte(-1)
		write_byte(-1)
		write_byte(1)
		write_byte(1)
		write_byte(CSW_DEAGLE)
		message_end()
	}
	return HAM_IGNORED
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	replace_weapon_models(owner, weaponid)
}

public CurrentWeapon(id)
{
     replace_weapon_models(id, read_data(2))

     if(read_data(2) != CSW_DEAGLE || !g_has_b1[id])
          return
     
     static Float:iSpeed
     if(g_has_b1[id])
          iSpeed = get_pcvar_float(cvar_spd_b1)
     
     static weapon[32],Ent
     get_weaponname(read_data(2),weapon,31)
     Ent = find_ent_by_owner(-1,weapon,id)
     if(Ent)
     {
          static Float:Delay
          Delay = get_pdata_float( Ent, 46, 4) * iSpeed
          if (Delay > 0.0)
          {
               set_pdata_float(Ent, 46, Delay, 4)
          }
     }
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_DEAGLE:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_b1[id])
			{
				set_pev(id, pev_viewmodel2, b1_V_MODEL)
				set_pev(id, pev_weaponmodel2, b1_P_MODEL)
				if(oldweap[id] != CSW_DEAGLE) 
				{
					UTIL_PlayWeaponAnimation(id, b1_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
					gMode[id] = 0
					message_begin(MSG_ONE, gmsgWeaponList, _, id)
					write_string("weapon_balrog1")
					write_byte(8)
					write_byte(35)
					write_byte(-1)
					write_byte(-1)
					write_byte(1)
					write_byte(1)
					write_byte(CSW_DEAGLE)
					message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_DEAGLE || !g_has_b1[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_b1_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_b1[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	g_iClip = cs_get_weapon_ammo(Weapon)
}

public explode(id)
{
	if(is_user_alive(id))
	{
			new Float:originF[3]
			fm_get_aim_origin(id,originF)
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, originF[0])
			engfunc(EngFunc_WriteCoord, originF[1])
			engfunc(EngFunc_WriteCoord, originF[2]+30)
			write_short(sExplo)
			write_byte(12)
			write_byte(50)
			write_byte(0)
			message_end()
			
			// Alive...
			new a = FM_NULLENT
			// Get distance between victim and epicenter
			while((a = find_ent_in_sphere(a, originF, 80.0)) != 0)
			{
				if (id == a)
					continue
					
				if(pev(a, pev_takedamage) != DAMAGE_NO)
				{
					ExecuteHamB(Ham_TakeDamage, a, id, id, 0.0, DMG_BURN)
					Make_FireBurn(a)
				}
			}
	}
}

public Make_FireBurn(id)
{
	static Ent; Ent = fm_find_ent_by_owner(-1, FIREBURN_CLASSNAME, id)
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
		
		entity_set_string(iEnt, EV_SZ_classname, FIREBURN_CLASSNAME)
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
		fireburn[id] = true
		set_pev(iEnt, pev_fuser2, get_gametime())
	}
	
	// time remove
	static Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		fireburn[id] = false
		return;
	}
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_b1) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_b1_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if (g_iClip <= cs_get_weapon_ammo(Weapon))
		return

	if(g_has_b1[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_b1),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		if( gMode[Player] ) {
			explode(Player)
			set_pdata_float( Player, 83, 2.0 )
		}
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[gMode[Player]], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, gMode[Player]?b1_SHOOT2:b1_SHOOT1)
		if( gMode[Player] ) gMode[Player] = 0
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_DEAGLE)
		{
			if(g_has_b1[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_b1))
		}
	}
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public b1_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_b1[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_clip_b1)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_DEAGLE);
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 
     if( pev( id, pev_button ) & IN_ATTACK2 && flNextAttack <= 0.0) {
		UTIL_PlayWeaponAnimation(id, !gMode[id]?6:7 )
		gMode[id] = (gMode[id]?0:1)
		set_pdata_float( id, 83, 2.0 )
     }
     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_DEAGLE, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public b1_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_has_b1[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_has_b1[id])
          iClipExtra = get_pcvar_num(cvar_clip_b1)

     g_b1_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_DEAGLE)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_b1_TmpClip[id] = iClip

     return HAM_IGNORED
}

public b1_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_b1[id])
		return HAM_IGNORED

	if (g_b1_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_b1_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, b1_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, b1_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, gMode[id]?8:b1_RELOAD)
	gMode[id] = 0

	return HAM_IGNORED
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}
