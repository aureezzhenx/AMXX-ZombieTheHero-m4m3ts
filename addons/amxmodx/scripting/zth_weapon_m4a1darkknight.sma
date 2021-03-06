#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
#include <zth_humanskill>

#define PLUGIN "[ZP] Extra:   Dark Knight"
#define VERSION "Beta 1.0"
#define AUTHOR "Dev!l"

#define P_MODEL "models/p_buffm4.mdl"
#define W_MODEL "models/w_buffm4.mdl"
#define V_MODEL "models/v_buffm4_fix.mdl"

#define CSW_BUFFM4			CSW_GALIL
#define weapon_buffm4 			"weapon_galil"
#define OLD_W_MODEL			"models/w_galil.mdl"
#define WEAPON_EVENT			"events/galil.sc"
#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY		EV_INT_impulse
#define WEAPONKEY 			12316521

#define WEAP_LINUX_XTRA_OFF		4
#define m_flTimeWeaponIdle		48
#define m_iClip				51
#define m_flNextAttack			83
#define m_fInReload			54
#define PLAYER_LINUX_XTRA_OFF		5

#define FIRERATE 			0.88
#define FIRERATE2 			0.3
#define DAMAGE 				50
#define DAMAGE2 			70
#define DAMAGE_DS 			80
#define DAMAGE2_DS 			100
#define AMMO 				50
#define BPAMMO 				240
#define RELOAD_TIME 			2.0
#define RECOIL				0.60
#define RECOIL2 			0.21

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

new const WeaponSounds[6][] = 
{
	"weapons/m4a1buff-1.wav",
	"weapons/m4a1buff-2.wav",
	"weapons/m4a1buff_clipin1.wav",
	"weapons/m4a1buff_clipin2.wav",
	"weapons/m4a1buff_clipout.wav",
	"weapons/m4a1buff_idle.wav"
}

new const WeaponResources[3][] =
{
	"sprites/weapon_buffm4.txt",
	"sprites/640hud7.spr",
	"sprites/640hud132.spr"
}

new const MuzzleFlash[3][] =
{
	"sprites/muzzleflash43.spr",
	"sprites/muzzleflash44.spr",
	"sprites/muzzleflash45.spr"
}

enum
{
	IDLE = 0,
	RELOAD,
	DRAW,
	SHOOT1,
	SHOOT2,
	SHOOT3
}

enum
{
	MODE_A = 1,
	MODE_B
}

new oldweap[33], g_buffm4_event, g_smokepuff_id, sTrail, g_WeaponMode[33], g_buffm4, Float:flEnd[3]
new g_clip_ammo[33], gmsgWeaponList, g_buffm4_TmpClip[33], Float:cl_pushangle[33][3], Float:g_flLastShotTime[33]
new g_Muzzleflash_Ent, g_Muzzleflash2_Ent, g_Muzzleflash3_Ent, g_Muzzleflash[33][3], g_had_buffm4[33]

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_buffm4, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_buffm4, "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_buffm4, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_buffm4, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_buffm4, "fw_Weapon_ItemPostFrame")
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_buffm4, "fw_Weapon_Idleanim", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_buffm4, "fw_Item_AddToPlayer_Post", 1)
	
	for(new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
		
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_post", 1)
	register_forward(FM_CheckVisibility, "fw_CheckVisibility")
	
	register_clcmd("weapon_buffm4", "hook_weapon")
	//register_clcmd("say test", "get_buffm4_test")
	
	gmsgWeaponList = get_user_msgid("WeaponList")
	g_buffm4 = zp_register_extra_item("M4A1 Dark Knight", 50, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	 
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
		
	for(new i = 0; i < sizeof(MuzzleFlash); i++)
		precache_model(MuzzleFlash[i])
		
	for(new i = 0; i < sizeof(WeaponResources); i++)
	{
		if(i == 0) engfunc(EngFunc_PrecacheGeneric, WeaponResources[i])
		else engfunc(EngFunc_PrecacheModel, WeaponResources[i])
	}
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	sTrail = precache_model("sprites/zbeam2.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_Muzzleflash_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_SetModel, g_Muzzleflash_Ent, MuzzleFlash[0])
	set_pev(g_Muzzleflash_Ent, pev_scale, 0.1)
	set_pev(g_Muzzleflash_Ent, pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent, pev_renderamt, 0.0)
	
	g_Muzzleflash2_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_SetModel, g_Muzzleflash2_Ent, MuzzleFlash[1])
	set_pev(g_Muzzleflash2_Ent, pev_scale, 0.08)
	set_pev(g_Muzzleflash2_Ent, pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash2_Ent, pev_renderamt, 0.0)
	
	g_Muzzleflash3_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_SetModel, g_Muzzleflash3_Ent, MuzzleFlash[2])
	set_pev(g_Muzzleflash3_Ent, pev_scale, 0.08)
	set_pev(g_Muzzleflash3_Ent, pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash3_Ent, pev_renderamt, 0.0)
}

public plugin_natives()
{
	register_native("get_buffm4", "native_get_buffm4", 1)
}

public native_get_buffm4(id)
{
	get_buffm4(id)
}

public fw_AddToFullPack_post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if(iEnt == g_Muzzleflash_Ent)
	{
		if(g_Muzzleflash[iHost][0])
		{
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, random_float(100.0, 255.0))
			set_es(esState, ES_Scale, random_float(0.06, 0.1))
			
			g_Muzzleflash[iHost][0] = false
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	} else if(iEnt == g_Muzzleflash2_Ent)
	{
		if(g_Muzzleflash[iHost][1])
		{
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 240.0)
			
			g_Muzzleflash[iHost][1] = false
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	} else if(iEnt == g_Muzzleflash3_Ent)
	{
		if(g_Muzzleflash[iHost][2])
		{
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 240.0)
			
			g_Muzzleflash[iHost][2] = false
			g_Muzzleflash[iHost][1] = true
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	}

}

public player_spawn(id)
{
	g_had_buffm4[id] = 0
}

public fw_CheckVisibility(iEntity, pSet)
{
	if(iEntity == g_Muzzleflash_Ent || iEntity == g_Muzzleflash2_Ent || iEntity == g_Muzzleflash3_Ent)
	{
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}


public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_buffm4_event = get_orig_retval()		
}

public zp_extra_item_selected(id, wpnid)
{
	if(wpnid == g_buffm4) get_buffm4(id)
}

public zp_user_infected_post(id) remove_buffm4(id)
public get_buffm4(id)
{
	if(!is_user_alive(id))
		return
		
	drop_weapons(id, 1)
	
	new iWep2 = fm_give_item(id, weapon_buffm4)
	if(iWep2 > 0)
	{
		cs_set_weapon_ammo(iWep2, AMMO)
		cs_set_user_bpammo(id, CSW_BUFFM4, BPAMMO)
		set_weapons_timeidle(id, 1.0)
		set_player_nextattack(id, 1.0)
		set_weapon_anim(id, DRAW)
	}
	
	g_had_buffm4[id] = 1
	g_WeaponMode[id] = MODE_A
	
	message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
	write_string("weapon_buffm4")
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(17)
	write_byte(CSW_BUFFM4)
	write_byte(0)
	message_end()
}

public get_buffm4_test(id)
{
	if(!is_user_alive(id))
		return
	
	new iWep2 = fm_give_item(id, weapon_buffm4)
	if(iWep2 > 0)
	{
		cs_set_weapon_ammo(iWep2, AMMO)
		cs_set_user_bpammo(id, CSW_BUFFM4, BPAMMO)
		set_weapons_timeidle(id, 1.0)
		set_player_nextattack(id, 1.0)
		set_weapon_anim(id, DRAW)
	}
	
	g_had_buffm4[id] = 1
	g_WeaponMode[id] = MODE_A
	
	message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
	write_string("weapon_buffm4")
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(17)
	write_byte(CSW_BUFFM4)
	write_byte(0)
	message_end()
}

public remove_buffm4(id)
{
	if(!is_user_connected(id))
		return
			
	g_had_buffm4[id] = 0
	g_WeaponMode[id] = 0
	
}

public hook_weapon(id)
{
	engclient_cmd(id, weapon_buffm4)
	return PLUGIN_HANDLED
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if((get_user_weapon(id) == CSW_BUFFM4 && g_had_buffm4[id]) && oldweap[id] != CSW_BUFFM4)
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
		
		set_weapon_anim(id, DRAW)
		set_weapons_timeidle(id, 1.0)
		set_player_nextattack(id, 1.0)
		
		g_WeaponMode[id] = MODE_A
	}
	
	if(g_WeaponMode[id] == MODE_A)
	{
		Check_Rate(id)
	}
}

public Check_Rate(id)
{
	static ent; ent = fm_get_user_weapon_entity(id, CSW_BUFFM4)
	if(pev_valid(ent))  set_pdata_float(ent, 46, get_pdata_float(ent, 46, 4) * FIRERATE, 4)
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
		
	if(get_user_weapon(iAttacker) == CSW_BUFFM4)
	{
		if(g_had_buffm4[iAttacker])
			set_msg_arg_string(4, "m4a1")
	}
                
	return PLUGIN_CONTINUE
}

public fw_Weapon_Idleanim(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_had_buffm4[id] || get_user_weapon(id) != CSW_BUFFM4)
		return HAM_IGNORED;

	if(get_pdata_float(Weapon, 48, 4) <= 0.25)
	{
		set_weapon_anim(id, IDLE)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public fw_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_had_buffm4[Player])
		return
	
	pev(Player,pev_punchangle,cl_pushangle[Player])
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BUFFM4 && g_had_buffm4[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PrimaryAttack_Post(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
		
	if(g_had_buffm4[Player])
	{
		if(szClip <= 0)
		{
			emit_sound(Player, CHAN_WEAPON, WeaponSounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	
	if(g_had_buffm4[Player])
	{
		if (!g_clip_ammo[Player])
			return
			
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		if(g_WeaponMode[Player] == MODE_A)
		{
			xs_vec_mul_scalar(push,RECOIL,push)
		}
		else if(g_WeaponMode[Player] == MODE_B)
		{
			xs_vec_mul_scalar(push,RECOIL2,push)
		}
		
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
	}
}

public Make_Muzzleflash(id)
{
	if(g_WeaponMode[id] == MODE_A) g_Muzzleflash[id][0] = true
	else if(g_WeaponMode[id] == MODE_B)
	{
		g_Muzzleflash[id][2] = true
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_BUFFM4 || !g_had_buffm4[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_BUFFM4)
	if(!pev_valid(ent))
		return
		
	static Float:flGameTime
	flGameTime = get_gametime()
	
	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK && szClip >= 1 && get_pdata_float(id, 83, 5) <= 0.0)
	{
		if(g_WeaponMode[id] == MODE_A)
		{
			if(get_pdata_float(ent, 46, 4) <= 0.025 || get_pdata_float(ent, 47, 4) <= 0.025 || get_pdata_float(id, 83, 5) <= 0.025) 
				Make_Muzzleflash(id)
			else if(get_pdata_float(ent, 46, 4) <= 0.0 || get_pdata_float(ent, 47, 4) <= 0.0 || get_pdata_float(id, 83, 5) <= 0.0) 
				Make_Muzzleflash(id)
		}
		else if(g_WeaponMode[id] == MODE_B)
		{
			if(get_pdata_float(ent, 46, 4) > 0.0 || get_pdata_float(ent, 47, 4) > 0.0) 
				return
				
			if(flGameTime - g_flLastShotTime[id] > FIRERATE2)
			{
				CurButton &= ~IN_ATTACK
				set_uc(uc_handle, UC_Buttons, CurButton)
				
				Make_Muzzleflash(id)
				Shoot_Special(id)
				set_weapons_timeidle(id, FIRERATE2)
				set_player_nextattack(id, FIRERATE2)
				Make_Muzzleflash(id)
				
				g_flLastShotTime[id] = flGameTime
			}
		}
	}
	else if(CurButton & IN_ATTACK2 && !(pev(id, pev_oldbuttons) & IN_ATTACK2) && szClip >= 1 && get_pdata_float(id, 83, 5) <= 0.0)
	{
		if(get_pdata_float(ent, 46, 4) > 0.0 || get_pdata_float(ent, 47, 4) > 0.0) 
			return
			
		if(g_WeaponMode[id] == MODE_A)
		{
			CurButton &= ~IN_ATTACK2
			set_uc(uc_handle, UC_Buttons, CurButton)
					
			cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 0)
			set_weapons_timeidle(id, 0.25)
			set_player_nextattack(id, 0.25)
				
			g_WeaponMode[id] = MODE_B
			g_flLastShotTime[id] = flGameTime
		}
		else if(g_WeaponMode[id] == MODE_B)
		{
			CurButton &= ~IN_ATTACK2
			set_uc(uc_handle, UC_Buttons, CurButton)
				
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
			set_weapons_timeidle(id, 0.25)
			set_player_nextattack(id, 0.25)
				
			g_WeaponMode[id] = MODE_A
			g_flLastShotTime[id] = flGameTime
		}
	}
}

public Shoot_Special(id)
{
	static ent; ent = fm_get_user_weapon_entity(id, CSW_BUFFM4)
	if(!pev_valid(ent))
		return
		
	Make_Muzzleflash(id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
	
	static Float:PunchAngles[3]
	PunchAngles[1] = -3.0
	set_pev(id, pev_punchangle, PunchAngles)
	
	shot_skill(id)
	set_weapon_anim(id, random_num(SHOOT1, SHOOT3))
	emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(zp_get_user_zombie(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) == CSW_BUFFM4 && g_had_buffm4[invoker] && eventid == g_buffm4_event)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		
		Make_Muzzleflash(invoker)
		emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		set_weapon_anim(invoker, random_num(SHOOT1, SHOOT3))
	}
	return FMRES_HANDLED
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_buffm4, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(g_had_buffm4[iOwner])
		{
			g_had_buffm4[iOwner] = 0
			
			set_pev(weapon, pev_impulse, WEAPONKEY)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_BUFFM4 || !g_had_buffm4[attacker])
		return HAM_IGNORED
		
	static Float:vecPlane[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
		
	if(!is_user_alive(ent))
	{
		make_bullet(attacker, flEnd)
		fake_smoke(attacker, ptr)
	}
	
	if(g_WeaponMode[attacker] == MODE_A)
	{
		if(!using_ds(attacker))
			SetHamParamFloat(3, float(DAMAGE))
		else if(using_ds(attacker))
			SetHamParamFloat(3, float(DAMAGE_DS))
	}
	else if(g_WeaponMode[attacker] == MODE_B)
	{
		if(!using_ds(attacker))
			SetHamParamFloat(3, float(DAMAGE2))
		else if(using_ds(attacker))
			SetHamParamFloat(3, float(DAMAGE2_DS))
	}

	return HAM_HANDLED
}

public shot_skill(id)
{
	static Float:StartOrigin2[3]
	get_position(id, 40.0, 6.0, -7.0, StartOrigin2)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, StartOrigin2[0])
	engfunc(EngFunc_WriteCoord, StartOrigin2[1])
	engfunc(EngFunc_WriteCoord, StartOrigin2[2])
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	write_short(sTrail)
	write_byte(0) // start frame
	write_byte(0) // framerate
	write_byte(5) // life
	write_byte(4) // line width
	write_byte(0) // amplitude
	write_byte(255) // red
	write_byte(255) // green
	write_byte(255) // blue
	write_byte(100) // brightness
	write_byte(0) // speed
	message_end()
}

public fw_Weapon_ItemPostFrame(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED;
	
	if(!g_had_buffm4[id])
		return HAM_IGNORED;
	
	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_BUFFM4);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new j = min(AMMO - iClip, iBpAmmo)
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_BUFFM4, iBpAmmo-j);
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}
	return HAM_IGNORED;
}

public fw_Weapon_Reload(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED;
	
	if(!g_had_buffm4[id])
		return HAM_IGNORED;
	
	g_buffm4_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, CSW_BUFFM4);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	if(iBpAmmo <= 0)
		return HAM_SUPERCEDE;
	
	if(iClip >= AMMO)
		return HAM_SUPERCEDE;
	
	g_buffm4_TmpClip[id] = iClip;
	return HAM_IGNORED;
}

public fw_Weapon_Reload_Post(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED;
	if(!g_had_buffm4[id])
		return HAM_IGNORED;
	if(g_buffm4_TmpClip[id] == -1)
		return HAM_IGNORED;
	
	set_pdata_int(weapon_entity, m_iClip, g_buffm4_TmpClip[id], WEAP_LINUX_XTRA_OFF)
	
	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, RELOAD_TIME, WEAP_LINUX_XTRA_OFF)
	
	set_pdata_float(id, m_flNextAttack, RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)
	
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)
	
	set_weapon_anim(id, RELOAD)
	
	g_WeaponMode[id] = MODE_A
	cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
	
	return HAM_IGNORED;
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(entity_get_int(ent, EV_INT_WEAPONKEY) == WEAPONKEY)
	{
		g_had_buffm4[id] = 1
		set_pev(ent, pev_impulse, 0)
	
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_buffm4")
		write_byte(4)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(17)
		write_byte(CSW_GALIL)
		write_byte(0)
		message_end()
		
		entity_set_int(ent, EV_INT_WEAPONKEY, 0)

		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_galil")
		write_byte(4)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(17)
		write_byte(CSW_GALIL)
		write_byte(0)
		message_end()
	}
	
	return HAM_HANDLED	
}

public fw_Item_Deploy_Post(Ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(Ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(Ent)
	
	replace_weapon_models(owner, weaponid)
}

replace_weapon_models(id, weaponid)
{
	switch(weaponid)
	{
		case CSW_BUFFM4:
		{
			if(g_had_buffm4[id])
			{
				set_pev(id, pev_viewmodel2, V_MODEL)
				set_pev(id, pev_weaponmodel2, P_MODEL)
				if(oldweap[id] != CSW_BUFFM4) 
				{
					set_weapon_anim(id, DRAW)
					cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
					
					set_weapons_timeidle(id, 1.0)
					set_player_nextattack(id, 1.0)

					message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
					write_string("weapon_buffm4")
					write_byte(4)
					write_byte(90)
					write_byte(-1)
					write_byte(-1)
					write_byte(0)
					write_byte(17)
					write_byte(CSW_BUFFM4)
					write_byte(0)
					message_end()
				}
			}
		}
	}
	
	oldweap[id] = weaponid
	g_WeaponMode[id] = MODE_A
	cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
}

stock make_bullet(id, Float:Origin[3])
{
	new decal = random_num(41, 45)
	const loop_time = 2
	
	static Body, Target
	get_user_aiming(id, Target, Body, 999999)
	
	if(is_user_connected(Target))
		return
	
	for(new i = 0; i < loop_time; i++)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(decal)
		message_end()
		
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
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock set_weapons_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	new entwpn = fm_get_user_weapon_entity(id, CSW_BUFFM4)
	if(!pev_valid(entwpn)) 
		return
	
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 1.0, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
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

stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	if(index == 0)
	{
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_connected(i))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i);
				write_byte(i);
				write_string(szMsg);
				message_end();	
			}
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
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

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}
