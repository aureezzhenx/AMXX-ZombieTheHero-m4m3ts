#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define RELOAD_TIME	5.0
#define SPEED_A 0.09
#define SPEED_B 0.063
#define TASK_REMOVE_OH 6996

#define CSW_M134H CSW_M249
#define weapon_m134h "weapon_m249"

new const WeaponSounds[][] =
{
	"weapons/m134-1.wav",
	"weapons/m134_clipoff.wav",
	"weapons/m134_clipon.wav",
	"weapons/m134ex_spin.wav",
	"weapons/m134hero_draw.wav",
	"weapons/m134hero_fire_after_overheat.wav",
	"weapons/m134hero_overheat_end.wav",
	"weapons/m134hero_overload.wav",
	"weapons/m134hero_spindown.wav",
	"weapons/m134hero_spinup.wav",
	"weapons/steam.wav"
}

new const V_MODEL[] = "models/v_m134hero.mdl"
new const P_MODEL[] = "models/p_m134hero.mdl"
new const W_MODEL[] = "models/w_m134hero.mdl"

new const M_MODEL[][] =
{
	"sprites/muzzleflash6.spr",
	"sprites/muzzleflash7.spr"
}

new cvar_dmg_m134, cvar_clip_m134, cvar_speedrun_m134
new g_event, g_attack, Float:cl_pushangle[33][3], m_iBlood[2], g_had_m134h[33], g_iClip[33], g_iMuz[33][2]
new Float:g_Damage[33], g_TmpClip[33], shell_mode, shell_mode2, g_steamspr
new g_IsOH[33], Float:g_WeaponSpeed[33], g_Muzzleflash[2], Float:g_WeaponTimer[33]
new g_m134

enum _:iAnim
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_RELOAD,
	ANIM_FIREREADY,
	ANIM_SHOOT,
	ANIM_FIREAFTER,
	ANIM_FIRECHANGE,
	ANIM_IDLECHANGE,
	ANIM_DRAW_OH,
	ANIM_FIREAFTER_OH,
	ANIM_IDLE_OH,
	ANIM_END_OH,
	ANIM_SHOOTB_START,
	ANIM_SHOOTB,
	ANIM_FIREAFTERB
}

enum _:M134_STAT
{
	M134_IDLE,
	M134_SPIN_UP,
	M134_SPINNING,
	M134_OVERHEAT
}

// Int
const pev_state = pev_iuser1  // idle, shoot, or fire after
const pev_mode = pev_iuser2 // normal or rapid mode
const pev_firecount = pev_iuser3 // counting fire
const pev_overheat = pev_iuser4 // overheat

// Float
const pev_steamtime = pev_fuser1
const pev_ohtimer = pev_fuser2
const pev_startoh = pev_fuser3
const pev_wpntimer = pev_fuser4

public plugin_init()
{
	register_plugin("[ZP] Extra: M134 Hero", "1.0", "Asdian")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_m134h, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_m134h, "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_Deploy, weapon_m134h, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_m134h, "fw_AddToPlayer")
	RegisterHam(Ham_Item_PostFrame, weapon_m134h, "fw_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_m134h, "fw_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_m134h, "fw_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")	
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_post", 1)
	register_forward(FM_CheckVisibility, "fw_CheckVisibility")
	
	cvar_dmg_m134 = register_cvar("zp_m134_dmg", "1.56")
	cvar_clip_m134 = register_cvar("zp_m134_clip", "300")
	cvar_speedrun_m134 = register_cvar("zp_m134_speedrun", "200.0")
	
	g_m134 = zp_register_extra_item("M134 Vulcan", 0, ZP_TEAM_HUMAN)
}

public zp_extra_item_selected(id, itemid)
{
	// Check if the selected item matches any of our registered ones
	if (itemid == g_m134) give_m134(id)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	for(new i = 0; i < sizeof WeaponSounds; i++) engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	
	shell_mode = engfunc(EngFunc_PrecacheModel, "models/shell762_m134.mdl")
	shell_mode2 = engfunc(EngFunc_PrecacheModel, "models/shell762_m134_01.mdl")
	g_steamspr = engfunc(EngFunc_PrecacheModel, "sprites/m134hero_steam.spr")
	
	engfunc(EngFunc_PrecacheGeneric, "sprites/weapon_m134hero.txt")
	
	m_iBlood[0] = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
	m_iBlood[1] = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")
	
	register_clcmd("weapon_m134hero", "weapon_hook")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
	
	// Muzzleflash 1
	g_Muzzleflash[0] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	engfunc(EngFunc_PrecacheModel, M_MODEL[0])
	engfunc(EngFunc_SetModel, g_Muzzleflash[0], M_MODEL[0])
	set_pev(g_Muzzleflash[0], pev_scale, 0.3)
	set_pev(g_Muzzleflash[0], pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash[0], pev_renderamt, 0.0)
	
	// Muzzleflash 2
	g_Muzzleflash[1] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_PrecacheModel, M_MODEL[1])
	engfunc(EngFunc_SetModel, g_Muzzleflash[1], M_MODEL[1])
	set_pev(g_Muzzleflash[1], pev_scale, 0.3)
	set_pev(g_Muzzleflash[1], pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash[1], pev_renderamt, 0.0)
}

public weapon_hook(id) engclient_cmd(id, weapon_m134h)

public zp_user_infected_pre(id) remove_m134(id)
public zp_user_infected_post(id) remove_m134(id)

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return
	if(get_user_weapon(iAttacker) != CSW_M134H || !g_had_m134h[iAttacker])
		return
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		engfunc(EngFunc_WriteCoord, flEnd[0])
		engfunc(EngFunc_WriteCoord, flEnd[1])
		engfunc(EngFunc_WriteCoord, flEnd[2])
		write_byte(random_num(41, 45))
		write_short(iEnt)
		message_end()
	} else {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, flEnd[0])
		engfunc(EngFunc_WriteCoord, flEnd[1])
		engfunc(EngFunc_WriteCoord, flEnd[2])
		write_byte(random_num(41, 45))
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	write_short(iAttacker)
	write_byte(random_num(41, 45))
	message_end()
}

public fwPrecacheEvent_Post(type, const name[])
{
	if(equal("events/m249.sc", name))
		g_event = get_orig_retval()
}

public client_connect(id) remove_m134(id)
public client_disconnect(id) remove_m134(id)

public fw_AddToFullPack_post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if(iEnt == g_Muzzleflash[0])
	{
		if(g_iMuz[iHost][0])
		{
			set_es(esState, ES_Frame, float(random_num(0, 2)))
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 255.0)
			
			g_iMuz[iHost][0] = 0
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	} else if(iEnt == g_Muzzleflash[1]) {
		if(g_iMuz[iHost][1])
		{
			set_es(esState, ES_Frame, float(random_num(0, 2)))
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 255.0)
			
			g_iMuz[iHost][1] = 0
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	}
}

public fw_CheckVisibility(iEntity, pSet)
{
	if(iEntity == g_Muzzleflash[0])
	{
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	} else if(iEntity == g_Muzzleflash[1]) {
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(entity, pev_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static ent
		ent = find_ent_by_owner(-1, weapon_m134h, entity)
	
		if(!pev_valid(ent))
			return FMRES_IGNORED
	
		if(g_had_m134h[iOwner])
		{
			set_pev(ent, pev_impulse, 9292015)
			g_had_m134h[iOwner] = false
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_m134(id)
{
	if(!is_user_alive(id))
		return
	
	g_had_m134h[id] = 1
	g_IsOH[id] = 0
	
	drop_weapons(id, 1)
	fm_give_item(id, weapon_m134h)
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_M134H)
	if(pev_valid(ent)) cs_set_weapon_ammo(ent, get_pcvar_num(cvar_clip_m134))
	cs_set_user_bpammo (id, CSW_M134H, 300)	
	
	set_weapon_anim(id, ANIM_DRAW)
	Set_WeaponIdleTime(id, CSW_M134H, 1.0, 1.0)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_M134H)
	write_byte(get_pcvar_num(cvar_clip_m134))
	message_end()
}

public remove_m134(id)
{
	g_had_m134h[id] = 0
	Remove_Value(id, 1)
}

public fw_AddToPlayer(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(pev(ent, pev_impulse) == 9292015)
	{
		g_had_m134h[id] = 1
		set_pev(ent, pev_impulse, 0)
	}
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(g_had_m134h[id] == 1 ? "weapon_m134hero" : weapon_m134h)
	write_byte(3)
	write_byte(200)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(4)
	write_byte(CSW_M134H)
	message_end()
	return HAM_IGNORED
}

public fw_Item_Deploy_Post(ent)
{
	static id
	id = get_pdata_cbase(ent, 41, 4)
	
	if(!is_user_connected(id) || !g_had_m134h[id])
		return HAM_IGNORED
	
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
	
	set_weapon_anim(id, g_IsOH[id] ? ANIM_DRAW_OH : ANIM_DRAW)
	Set_WeaponIdleTime(id, CSW_M134H, 1.0, 1.5)
	Set_PlayerNextAttack(id, 1.0)
	return HAM_IGNORED
}

public fw_UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
	if(!is_user_alive(id) || (get_user_weapon(id) != CSW_M134H || !g_had_m134h[id]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if((eventid != g_event) || !g_attack)
		return FMRES_IGNORED
	if(!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_PrimaryAttack(ent)
{
	static id
	id = get_pdata_cbase(ent, 41, 4)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_had_m134h[id])
		return HAM_IGNORED
	if(g_IsOH[id])
		return HAM_IGNORED
	
	g_attack = 1
	pev(id, pev_punchangle, cl_pushangle[id])
	g_iClip[id] = cs_get_weapon_ammo(ent)
	return HAM_IGNORED
}

public fw_PrimaryAttack_Post(ent)
{
	g_attack = 0
	
	static id
	id = get_pdata_cbase(ent, 41, 4)
	
	if(!is_user_alive(id))
		return
	if(!g_iClip[id] || g_IsOH[id])
		return
	
	if(g_had_m134h[id] && pev(ent, pev_state) == M134_SPINNING)
	{
		// Shake Screen
		static Float:PunchAngles[3]
		PunchAngles[0] = random_float(-0.5, 0.5)
		PunchAngles[1] = random_float(-0.5, 0.5)
		set_pev(id, pev_punchangle, PunchAngles)
		
		emit_sound(id, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, random_num(95, 120))
		Set_WeaponIdleTime(id, CSW_M134H, SPEED_A, 0.5)
		Set_PlayerNextAttack(id, SPEED_A)
		
		set_weapon_anim(id, ANIM_SHOOT)
		
		Eject_Shell(id, shell_mode, 0)
		Eject_Shell(id, shell_mode2, 1)
		
		g_iMuz[id][0] = 1
		g_iMuz[id][1] = 1
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_M134H && g_had_m134h[attacker])
			SetHamParamFloat(4, damage * WeaponDamage(attacker))
	}
}

public fw_ItemPostFrame(ent) 
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !g_had_m134h[id])
		return HAM_IGNORED
	
	new Float:flNextAttack = get_pdata_float(id, 83), iBpAmmo = cs_get_user_bpammo(id, CSW_M134H)
	new iClip = get_pdata_int(ent, 51, 4), fInReload = get_pdata_int(ent, 54, 4) 
	
	Special_M134Hero(ent, id, iClip, pev(id, pev_button))
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new iTotal = min(get_pcvar_num(cvar_clip_m134) - iClip, iBpAmmo)
		set_pdata_int(ent, 51, iClip + iTotal, 4)
		cs_set_user_bpammo(id, CSW_M134H, iBpAmmo - iTotal)
		set_pdata_int(ent, 54, 0, 4)
	}
	
	if(get_pdata_float(ent, 48, 4) <= 0.0)
	{
		if(g_IsOH[id]) set_weapon_anim(id, ANIM_IDLE_OH)
		set_pdata_float(ent, 48, 20.0, 4)
	}
	return HAM_IGNORED
}

public fw_Reload(ent) 
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !g_had_m134h[id])
		return HAM_IGNORED
	if(g_IsOH[id])
		return HAM_SUPERCEDE
	
	g_TmpClip[id] = -1

	new iBpAmmo = cs_get_user_bpammo(id, CSW_M134H)
	new iClip = get_pdata_int(ent, 51, 4)

	if(iBpAmmo <= 0 || iClip >= get_pcvar_num(cvar_clip_m134))
		return HAM_SUPERCEDE
	
	g_TmpClip[id] = iClip
	return HAM_IGNORED
}

public fw_Reload_Post(ent) 
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !g_had_m134h[id])
		return HAM_IGNORED
	if(g_IsOH[id])
		return HAM_SUPERCEDE
	if(g_TmpClip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(ent, 51, g_TmpClip[id], 4)
	set_pdata_float(ent, 48, RELOAD_TIME, 4)
	set_pdata_float(id, 83, RELOAD_TIME)
	set_pdata_int(ent, 54, 1, 4)
	
	set_pev(ent, pev_wpntimer, get_gametime() + RELOAD_TIME)
	set_weapon_anim(id, ANIM_RELOAD)
	return HAM_IGNORED
}

public Special_M134Hero(iEnt, id, iClip, iButton)
{
	static iCount, Float:iTimer, Float:iTimer2, iState, iMode, iOverH
	iCount = pev(iEnt, pev_firecount)
	iState = pev(iEnt, pev_state)
	iMode = pev(iEnt, pev_mode)
	iOverH = pev(iEnt, pev_overheat)
	pev(iEnt, pev_wpntimer, iTimer)
	pev(iEnt, pev_startoh, iTimer2)
	
	if((!iClip || get_user_weapon(id) != CSW_M134H) && iState == M134_SPINNING)
	{
		new bool:bMode = iMode ? true : false
		if(!bMode)
		{
			set_weapon_anim(id, ANIM_FIREAFTER)
			set_pdata_float(iEnt, 46, 0.2)
			set_pdata_float(iEnt, 48, 2.0, 4)
			
			iState = M134_IDLE
			iTimer = get_gametime() + 0.2
			
			set_pev(iEnt, pev_firecount, 0)
			set_pev(iEnt, pev_state, iState)
			set_pev(iEnt, pev_wpntimer, iTimer)
		} else {
			if(iCount > 0)  // !! Overheat begin
			{
				if(!iOverH && iTimer2 < get_gametime())
				{
					set_weapon_anim(id, ANIM_FIREAFTER_OH)
					Set_WeaponIdleTime(id, CSW_M134H, 2.25, 2.5)
					Set_PlayerNextAttack(id, 2.25)
					
					g_IsOH[id] = 1; iOverH = 1; iState = M134_OVERHEAT
					iTimer2 = get_gametime() + 2.25
					
					emit_sound(id, CHAN_WEAPON, WeaponSounds[8], 1.0, 0.52, 0, 94 + random_num(0, 15))
					
					set_pev(iEnt, pev_state, iState)
					set_pev(iEnt, pev_overheat, iOverH)
					set_pev(iEnt, pev_startoh, iTimer2)
				}
			} else {
				set_pdata_float(iEnt, 46, 0.25)
				set_pdata_float(iEnt, 48, 2.0, 4)
				Set_PlayerNextAttack(id, 0.25)
				
				set_weapon_anim(id, ANIM_FIREAFTERB)
				
				iState = M134_IDLE
				iTimer = get_gametime() + 0.25
				
				set_pev(iEnt, pev_firecount, 0)
				set_pev(iEnt, pev_state, iState)
				set_pev(iEnt, pev_wpntimer, get_gametime() + 0.25)
			}
		}
		set_pev(iEnt, pev_mode, 0)
	}
	
	if(iButton & IN_ATTACK)
	{
		if(g_IsOH[id] || !iClip)
			return
		
		if(iState == M134_IDLE)
		{
			if(iTimer < get_gametime())
			{
				set_weapon_anim(id, ANIM_FIREREADY)
				Set_WeaponIdleTime(id, CSW_M134H, 0.2, 0.5)
				
				iState = M134_SPIN_UP
				iTimer = get_gametime() + 0.2
				
				set_pev(iEnt, pev_state, iState)
				set_pev(iEnt, pev_wpntimer, iTimer)
			}
		}
		
		if(iState == M134_SPIN_UP && iTimer < get_gametime())
		{
			iState = M134_SPINNING
			set_pev(iEnt, pev_state, iState)
		}
	} else if(iButton & IN_ATTACK2) {
		if(g_IsOH[id] || !iClip)
			return
		
		if(iState == M134_IDLE)
		{
			if(iTimer < get_gametime())
			{
				iState = M134_SPIN_UP
				iTimer = get_gametime() + 0.2
				
				set_pev(iEnt, pev_mode, 1)
				set_pev(iEnt, pev_state, iState)
				set_pev(iEnt, pev_wpntimer, iTimer)
				
				set_weapon_anim(id, ANIM_SHOOTB_START)
				set_pdata_float(iEnt, 46, 0.2)
				set_pdata_float(iEnt, 48, 0.5, 4)
			}
		}
		
		if(iState == M134_SPIN_UP && iTimer < get_gametime())
		{
			iState = M134_SPINNING
			set_pev(iEnt, pev_state, iState)
		}
		
		if(iState == M134_SPINNING)
		{
			Set_WeaponIdleTime(id, CSW_M134H, SPEED_A, 1.0)
			Set_PlayerNextAttack(id, SPEED_A)
			
			// Shake Screen
			static Float:PunchAngles[3]
			PunchAngles[0] = random_float(-0.2, 0.2)
			PunchAngles[1] = random_float(-0.2, 0.2)
			set_pev(id, pev_punchangle, PunchAngles)
			
			if(iClip > 0) Randomize(iEnt, id, iClip)
			else set_pdata_int(iEnt, 51, 0, 4)
			
			emit_sound(id, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, random_num(95, 120))
			ExecuteHam(Ham_Weapon_PrimaryAttack, iEnt)
			
			g_iMuz[id][0] = 1
			g_iMuz[id][1] = 1
			
			Eject_Shell(id, shell_mode, 0)
			Eject_Shell(id, shell_mode2, 1)
			
			if(g_WeaponSpeed[id] < get_gametime())
			{
				set_weapon_anim(id, ANIM_SHOOTB)
				g_WeaponSpeed[id] = get_gametime() + 0.85
			}
			
			if(get_gametime() - 0.35 > g_WeaponTimer[id])
			{
				iCount++
				set_pev(iEnt, pev_firecount, iCount)
				
				g_WeaponTimer[id] = get_gametime()
			}
		}
	} else {
		if(iState == M134_SPIN_UP)
		{
			set_weapon_anim(id, ANIM_FIREAFTER)
			set_pdata_float(iEnt, 46, 0.2)
			set_pdata_float(iEnt, 48, 2.0, 4)
			
			iState = M134_IDLE
			iTimer = get_gametime() + 0.2
			
			set_pev(iEnt, pev_state, iState)
			set_pev(iEnt, pev_wpntimer, iTimer)
		}
		
		if(iState == M134_SPINNING)
		{
			new bool:bMode = iMode ? true : false
			
			if(!bMode)
			{
				set_weapon_anim(id, ANIM_FIREAFTER)
				set_pdata_float(iEnt, 46, 0.2)
				set_pdata_float(iEnt, 48, 2.0, 4)
				
				iState = M134_IDLE
				iTimer = get_gametime() + 0.2
				
				set_pev(iEnt, pev_state, iState)
				set_pev(iEnt, pev_wpntimer, iTimer)
			} else {
				if(iCount > 0)  // !! Overheat begin
				{
					if(!iOverH && iTimer2 < get_gametime())
					{
						set_weapon_anim(id, ANIM_FIREAFTER_OH)
						Set_WeaponIdleTime(id, CSW_M134H, 2.25, 2.5)
						Set_PlayerNextAttack(id, 2.25)
						
						g_IsOH[id] = 1; iOverH = 1; iState = M134_OVERHEAT
						iTimer2 = get_gametime() + 2.25
						
						emit_sound(id, CHAN_WEAPON, WeaponSounds[8], 1.0, 0.52, 0, 94 + random_num(0, 15))
						
						set_pev(iEnt, pev_state, iState)
						set_pev(iEnt, pev_overheat, iOverH)
						set_pev(iEnt, pev_startoh, iTimer2)
					}
				} else {
					set_pdata_float(iEnt, 46, 0.25)
					set_pdata_float(iEnt, 48, 2.0, 4)
					Set_PlayerNextAttack(id, 0.25)
					
					set_weapon_anim(id, ANIM_FIREAFTERB)
					
					iState = M134_IDLE
					iTimer = get_gametime() + 0.25
					
					set_pev(iEnt, pev_firecount, 0)
					set_pev(iEnt, pev_state, iState)
					set_pev(iEnt, pev_wpntimer, get_gametime() + 0.25)
				}
			}
			set_pev(iEnt, pev_mode, 0)
		}
	}
	
	if(iOverH == 1 && iTimer2 < get_gametime())
	{
		set_weapon_anim(id, ANIM_IDLE_OH)
		Set_WeaponIdleTime(id, CSW_M134H, float(iCount), float(iCount) + 1.2)
		Set_PlayerNextAttack(id, float(iCount))
		
		iOverH = 2
		iTimer2 = get_gametime() + float(iCount)
		
		set_pev(iEnt, pev_overheat, iOverH)
		set_pev(iEnt, pev_startoh, iTimer2)
	}
	
	if(iOverH == 2 && iTimer2 < get_gametime())
	{
		g_IsOH[id] = 0
		
		set_weapon_anim(id, ANIM_END_OH)
		Set_WeaponIdleTime(id, CSW_M134H, 2.0, 2.5)
		Set_PlayerNextAttack(id, 2.0)
		
		iOverH = 0
		iState = M134_IDLE
		
		set_pev(iEnt, pev_firecount, 0)
		set_pev(iEnt, pev_overheat, iOverH)
		set_pev(iEnt, pev_state, iState)
	}
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_M134H || !g_had_m134h[id])
		return
	
	static iEnt
	iEnt = Check_Ent(id)
	
	if(g_IsOH[id])
	{
		if(pev(iEnt, pev_steamtime) < get_gametime())
		{
			static Float:Origin[3]
			get_position(id, 20.0, 0.0, 0.0, Origin)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_SPRITE)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2])
			write_short(g_steamspr)
			write_byte(1)
			write_byte(250)
			message_end()
			
			emit_sound(id, CHAN_WEAPON, WeaponSounds[10], 1.0, 0.52, 0, 94 + random_num(0, 15))
			set_pev(iEnt, pev_steamtime, get_gametime() + 1.0)
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static wpn[33], iAttacker, iVictim
	get_msg_arg_string(4, wpn, charsmax(wpn))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(wpn, "m249") && get_user_weapon(iAttacker) == CSW_M134H)
		if(g_had_m134h[iAttacker]) set_msg_arg_string(4, "m134h")
	
	return PLUGIN_CONTINUE
}

public Float:WeaponDamage(id)
{
	static ent, Float:fDamage
	ent = Check_Ent(id)
	fDamage = pev(ent, pev_mode) ? get_pcvar_float(cvar_dmg_m134) * g_Damage[id] : get_pcvar_float(cvar_dmg_m134)
	return fDamage
}

public Randomize(iEnt, id, iClip)
{
	switch(random_num(0, 2))
	{
		case 0: { set_pdata_int(iEnt, 51, iClip - 2, 4); g_Damage[id] = 1.5; }
		case 1: { set_pdata_int(iEnt, 51, iClip - 3, 4); g_Damage[id] = 2.0; }
		case 2: { set_pdata_int(iEnt, 51, iClip - 4, 4); g_Damage[id] = 2.5; }
	}
}

stock Remove_Value(id, oh = 0)
{
	static iEnt
	iEnt = Check_Ent(id)
	
	set_pev(iEnt, pev_mode, 0)
	set_pev(iEnt, pev_state, 0)
	set_pev(iEnt, pev_firecount, 0)
	if(oh) set_pev(iEnt, pev_overheat, 0)
}

stock Check_Ent(id)
{
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_M134H)
	
	if(!pev_valid(ent)) return 0
	return ent
}

stock Set_WeaponIdleTime(id, WeaponId, Float:TimeAttack, Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeAttack, 4)
	set_pdata_float(entwpn, 47, TimeAttack, 4)
	set_pdata_float(entwpn, 48, TimeIdle, 4)
}

stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock set_weapon_anim(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public Eject_Shell(id, ShellID, Right) // Dias
{
	static Float:player_origin[3], Float:origin[3], Float:origin2[3], Float:gunorigin[3], Float:oldangles[3], Float:v_forward[3], Float:v_forward2[3], Float:v_up[3], Float:v_up2[3], Float:v_right[3], Float:v_right2[3], Float:viewoffsets[3];
	pev(id,pev_v_angle, oldangles)
	pev(id,pev_origin,player_origin)
	pev(id, pev_view_ofs, viewoffsets)

	engfunc(EngFunc_MakeVectors, oldangles)
	
	global_get(glb_v_forward, v_forward)
	global_get(glb_v_up, v_up)
	global_get(glb_v_right, v_right)
	global_get(glb_v_forward, v_forward2)
	global_get(glb_v_up, v_up2)
	global_get(glb_v_right, v_right2)
	
	xs_vec_add(player_origin, viewoffsets, gunorigin)
	
	if(!Right)
	{
		xs_vec_mul_scalar(v_forward, 20.0, v_forward)
		xs_vec_mul_scalar(v_right, -2.5, v_right)
		xs_vec_mul_scalar(v_up, -1.5, v_up)
		xs_vec_mul_scalar(v_forward2, 19.9, v_forward2)
		xs_vec_mul_scalar(v_right2, -2.0, v_right2)
		xs_vec_mul_scalar(v_up2, -2.0, v_up2)
	} else {
		xs_vec_mul_scalar(v_forward, 20.0, v_forward)
		xs_vec_mul_scalar(v_right, 2.5, v_right)
		xs_vec_mul_scalar(v_up, -1.5, v_up)
		xs_vec_mul_scalar(v_forward2, 19.9, v_forward2)
		xs_vec_mul_scalar(v_right2, 2.0, v_right2)
		xs_vec_mul_scalar(v_up2, -2.0, v_up2)
	}
	
	xs_vec_add(gunorigin, v_forward, origin)
	xs_vec_add(gunorigin, v_forward2, origin2)
	xs_vec_add(origin, v_right, origin)
	xs_vec_add(origin2, v_right2, origin2)
	xs_vec_add(origin, v_up, origin)
	xs_vec_add(origin2, v_up2, origin2)

	static Float:velocity[3]
	get_speed_vector(origin2, origin, random_float(140.0, 160.0), velocity)

	static angle
	angle = random_num(0, 360)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2] - 16.0)
	engfunc(EngFunc_WriteCoord, velocity[0])
	engfunc(EngFunc_WriteCoord, velocity[1])
	engfunc(EngFunc_WriteCoord, velocity[2])
	write_angle(angle)
	write_short(ShellID)
	write_byte(1)
	write_byte(20)
	message_end()
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3], Float:speed, Float:new_velocity[3])
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

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp) //or use EngFunc_AngleVectors
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id) || !g_had_m134h[id] || get_user_weapon(id) != CSW_M134H)
		return

	set_pev(id, pev_maxspeed, get_pcvar_float(cvar_speedrun_m134))
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
          
		if(dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}
