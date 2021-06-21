#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
enum
{
	anim_idle,
	anim_reload,
	anim_draw,
	anim_shoot1,
	anim_shoot2,
	anim_shoot3
}

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define dd_WEAPONKEY	991
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83

#define dd_RELOAD_TIME 4.5
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_ELITE)|(1<<CSW_P228)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)|(1<<CSW_FIVESEVEN)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
new const Fire_Sounds[][] = { "weapons/dde-1.wav" }
new const Sound_Zoom[] = { "weapons/zoom.wav" }
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new dd_V_MODEL[64] = "models/v_ddeagle.mdl"
new dd_P_MODEL[64] = "models/p_ddeagle.mdl"
new dd_W_MODEL[64] = "models/w_ddeagle.mdl"
new g_attack1[33]
new cvar_dmg_dd, cvar_recoil_dd, g_itemid_dd, cvar_clip_dd, cvar_dd_ammo
new g_has_dd[33]
new g_MaxPlayers, g_orig_event_dd, g_clip_ammo[33]
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_dd_TmpClip[33]
new g_canshoot[33]

public plugin_init()
{
	register_plugin("[ZP] Weapon: DD", "1.0", "Crock / =)")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_elite", "fw_dd_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_elite", "fw_dd_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_elite", "fw_dd_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_elite", "dd__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_elite", "dd__Reload");
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	RegisterHam(Ham_Weapon_Reload, "weapon_elite", "dd__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")

	cvar_dmg_dd = register_cvar("zp_dd_dmg", "3.0")
	cvar_recoil_dd = register_cvar("zp_dd_recoil", "1.0")
	cvar_clip_dd = register_cvar("zp_dd_clip", "28")
	cvar_dd_ammo = register_cvar("zp_dd_ammo", "120")

	g_itemid_dd = zp_register_extra_item("Dual Deagle", 9999, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(dd_V_MODEL)
	precache_model(dd_P_MODEL)
	precache_model(dd_W_MODEL)
	precache_sound(Sound_Zoom)
	precache_sound("weapons/dde-1.wav")
	precache_sound("weapons/dde_twirl.wav")
	precache_sound("weapons/dde_clipin.wav")
	precache_sound("weapons/dde_clipoff.wav")
	precache_sound("weapons/dde_clipout.wav")
	precache_sound("weapons/dde_load.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_model("sprites/640hud5.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}
public plugin_natives ()
{
	register_native("give_weapon_dd", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_dd(id)
}
public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/elite_left.sc", name) || equal("events/elite_right.sc", name))
	{
		g_orig_event_dd = get_orig_retval()
		return FMRES_HANDLED
	}
	
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_dd[id] = false
}
public event_round_start()
{
for(new i; i<=32; i++)
{
g_has_dd[i] = false
}
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && (pev(id, pev_oldbuttons) & IN_ATTACK))
	{
	g_canshoot[id] = 1
	}else if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && !(pev(id, pev_oldbuttons) & IN_ATTACK) && flNextAttack <= 0.0){
	g_canshoot[id] = 0
	}else{
	g_canshoot[id] = 1
	}

	if(get_uc(uc_handle, UC_Buttons) & IN_ATTACK)
	{
	g_attack1[id] = 1
	}else{
	g_attack1[id] = 0
	}

	return PLUGIN_HANDLED
}
public client_disconnect(id)
{
	g_has_dd[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_dd[id] = false
	}
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_elite.mdl"))
	{
		static iStoredSVDID
		
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, "weapon_elite", entity)
	
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
	
		if(g_has_dd[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, dd_WEAPONKEY)
			g_has_dd[iOwner] = false
			
			entity_set_model(entity, dd_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	
	
	return FMRES_IGNORED;
}
public give_dd(id)
{
	drop_weapons(id, 1);
	new iWep2 = give_item(id,"weapon_elite")
	if( iWep2 > 0 )
	{
	cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_dd))
	cs_set_user_bpammo (id, CSW_ELITE, get_pcvar_num(cvar_dd_ammo))
	}
	g_has_dd[id] = true;
}
public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_dd)
	{	
	give_dd(id)
	}
}

public fw_dd_AddToPlayer(dd, id)
{
	if(!is_valid_ent(dd) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(dd, EV_INT_WEAPONKEY) == dd_WEAPONKEY)
	{
		g_has_dd[id] = true
		
		entity_set_int(dd, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
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
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_ELITE:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_dd[id])
			{
				set_pev(id, pev_viewmodel2, dd_V_MODEL)
				set_pev(id, pev_weaponmodel2, dd_P_MODEL)
			}
		}
	}
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
        if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_ELITE) || !g_has_dd[Player])
        return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_dd_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_dd[Player])
		return;
	
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_dd))
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_dd_PrimaryAttack_Post(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_dd[Player] && g_canshoot[Player] == 0)
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_dd),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)

		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, anim_shoot1)
		new a = random_num(1,5)
		new b = random_num(1,2)
		if(b==1) UTIL_PlayWeaponAnimation(Player, 1+a)
		if(b==2) UTIL_PlayWeaponAnimation(Player, 7+a)
		make_blood_and_bulletholes(Player)
		set_pdata_float(Player, m_flNextAttack,0.1, PLAYER_LINUX_XTRA_OFF)
		
		
	}

}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_ELITE)
		{
			if(g_has_dd[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_dd))
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "galil") && get_user_weapon(iAttacker) == CSW_ELITE)
	{
		if(g_has_dd[iAttacker])
			set_msg_arg_string(4, "galil")
	}
		
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock make_blood_and_bulletholes(id)
{
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	
	if(target > 0 && target <= g_MaxPlayers && zp_get_user_zombie(target))
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		velocity_by_aim(id, 64, fVel)
		
		fStart[0] = float(aimOrigin[0])
		fStart[1] = float(aimOrigin[1])
		fStart[2] = float(aimOrigin[2])
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short( m_iBlood [ 1 ])
		write_short( m_iBlood [ 0 ] )
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
	} 
	else if(!is_user_connected(target))
	{
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
			write_short(target)
			message_end()
		} 
		else 
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		write_short(id)
		write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
		message_end()
	}
}

public dd__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_dd[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_ELITE);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new Player = id
		new j = min(get_pcvar_num(cvar_clip_dd) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_ELITE, iBpAmmo-j);

		if(g_attack1[id] == 1)
		{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_dd),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)

		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, anim_shoot1)
		new a = random_num(1,5)
		new b = random_num(1,2)
		if(b==1) UTIL_PlayWeaponAnimation(Player, 1+a)
		if(b==2) UTIL_PlayWeaponAnimation(Player, 7+a)
		make_blood_and_bulletholes(Player)
		set_pdata_float(Player, m_flNextAttack,0.2, PLAYER_LINUX_XTRA_OFF)
		}
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	return HAM_IGNORED;
}

public dd__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_dd[id])
		return HAM_IGNORED;

	g_dd_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_ELITE);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_dd))
		return HAM_SUPERCEDE;


	g_dd_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

public dd__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_dd[id])
		return HAM_IGNORED;

	if (g_dd_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_dd_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, dd_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, dd_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	// relaod animation
	UTIL_PlayWeaponAnimation(id, 14)

	return HAM_IGNORED;
}

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
