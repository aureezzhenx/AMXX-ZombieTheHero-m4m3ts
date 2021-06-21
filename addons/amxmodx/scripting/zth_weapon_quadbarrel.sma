#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <zombieplague>

#define PLUGIN "[ZP] Extra Item: Quad Barrel"
#define VERSION "1.0"
#define AUTHOR "Dias" // Thank for the help of RedPlane

#define m_pPlayer				41
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack	47
#define m_flTimeWeaponIdle		48
#define m_iClip				51
#define m_fInReload				54
#define m_fInSpecialReload		55

#define XTRA_OFS_WEAPON			4
#define XTRA_OFS_PLAYER		5
#define m_flNextAttack		83
#define m_rgAmmo_player_Slot0	376

new const v_model[] = "models/v_qbarrel.mdl"
new const p_model[] = "models/p_qbarrel.mdl"
new const w_model[] = "models/w_qbarrel.mdl"

new const qb_sound[5][] = {
	"weapons/qbarrel_clipin1.wav",
	"weapons/qbarrel_clipin2.wav",
	"weapons/qbarrel_clipout1.wav",
	"weapons/qbarrel_draw.wav",
	"weapons/qbarrel_shoot.wav"
}

#define CSW_QB CSW_XM1014
new g_had_qb[33], Float:g_last_fire[33], Float:g_last_fire2[33], g_bloodspray, g_blood
new cvar_default_clip, cvar_delayattack, cvar_reloadtime, cvar_randmg_start, cvar_randmg_end
new g_quad_barrel

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	register_forward(FM_CmdStart, "fm_cmdstart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")	
	
	RegisterHam(Ham_TakeDamage, "player", "fw_takedmg")
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)	
	
	RegisterHam(Ham_Weapon_Reload, "weapon_xm1014", "ham_reload", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_xm1014", "ham_priattack", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_xm1014", "ham_postframe")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_xm1014", "fw_item_addtoplayer", 1)
	
	register_clcmd("lastinv", "check_draw_weapon")
	register_clcmd("slot1", "check_draw_weapon")
	
	cvar_default_clip = register_cvar("zp_qbarrel_default_clip", "4")
	cvar_delayattack = register_cvar("zp_qbarrel_delay_attack", "0.35")
	cvar_reloadtime = register_cvar("zp_qbarrel_reload_time", "3.0")
	
	cvar_randmg_start = register_cvar("zp_qbarrel_randomdmg_start", "400.0")
	cvar_randmg_end = register_cvar("zp_qbarrel_randomdmg_end", "600.0")
	
	g_quad_barrel = zp_register_extra_item("Quad Barrel", 1, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	g_blood = precache_model("sprites/blood.spr")
	g_bloodspray = precache_model("sprites/bloodspray.spr")		
	
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)
	
	for(new i = 0; i < sizeof(qb_sound); i++)
		precache_sound(qb_sound[i])
}

public event_newround()
{
	new iPlayers[32], iNumber
	get_players(iPlayers, iNumber)
	
	for(new i = 0; i < iNumber; i++)
	{
		new id = iPlayers[i]
		
		if(is_user_alive(id) && is_user_connected(id))
			g_had_qb[i] = 0
	}
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_quad_barrel)
		return PLUGIN_HANDLED
	
	g_had_qb[id] = 1
	new ent = give_item(id, "weapon_xm1014")
	
	cs_set_weapon_ammo(ent, get_pcvar_num(cvar_default_clip))
	cs_set_user_bpammo(id, CSW_QB, 200)
	
	set_pdata_float(id, 83, 1.0, 4)
	set_weapon_anim(id, 4)
	
	return PLUGIN_CONTINUE
}

public zp_user_infected_post(id)
{
	g_had_qb[id] = 0
}

public zp_user_humanized_post(id)
{
	g_had_qb[id] = 0
}

public check_draw_weapon(id)
{
	set_task(0.001, "do_check", id)
}

public do_check(id)
{
	if(!zp_get_user_zombie(id) && get_user_weapon(id) == CSW_QB && g_had_qb[id])
	{
		set_weapon_anim(id, 4)
	}
}

public event_curweapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(zp_get_user_zombie(id))
		return
	if(get_user_weapon(id) != CSW_QB || !g_had_qb[id])
		return	
		
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, p_model)
		
	return 
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(zp_get_user_zombie(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) != CSW_QB || !g_had_qb[id])
		return FMRES_IGNORED
		
	set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
	
	return FMRES_HANDLED
}

public TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iAttacker))
		return HAM_IGNORED
	if(zp_get_user_zombie(iAttacker))
		return FMRES_IGNORED			
	if(get_user_weapon(iAttacker) != CSW_QB || !g_had_qb[iAttacker])
		return HAM_IGNORED
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)

	make_bullet(iAttacker, flEnd)

	return HAM_HANDLED
}

public fw_takedmg(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED
	if(zp_get_user_zombie(attacker) || !zp_get_user_zombie(victim))
		return HAM_IGNORED

	if(get_user_weapon(attacker) == CSW_QB && g_had_qb[attacker])
	{
		static Float:random_start, Float:random_end
	
		random_start = get_pcvar_float(cvar_randmg_start)
		random_end = get_pcvar_float(cvar_randmg_end)
	
		SetHamParamFloat(4, random_float(random_start, random_end))
	}
	
	return HAM_HANDLED
}

public make_bullet(id, Float:Origin[3])
{
	// Find target
	new target, body
	get_user_aiming(id, target, body, 999999)
	
	if(target > 0 && target <= get_maxplayers())
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		// Get ids view direction
		velocity_by_aim(id, 64, fVel)
		
		// Calculate position where blood should be displayed
		fStart[0] = Origin[0]
		fStart[1] = Origin[1]
		fStart[2] = Origin[2]
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		// Draw traceline from victims origin into ids view direction to find
		// the location on the wall to put some blood on there
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		// Show some blood :)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_bloodspray)
		write_short(g_blood)
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
		} else {
		new decal = 41
		
		// Check if the wall hit is an entity
		if(target)
		{
			// Put decal on an entity
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			write_short(target)
			message_end()
			} else {
			// Put decal on "world" (a wall)
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			message_end()
		}
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(floatround(Origin[0]))
		write_coord(floatround(Origin[1]))
		write_coord(floatround(Origin[2]))
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

public fm_cmdstart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(zp_get_user_zombie(id))
		return
	if(get_user_weapon(id) != CSW_QB || !g_had_qb[id])
		return 

	new CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		new ent = find_ent_by_owner(-1, "weapon_xm1014", id)
		
		if (!ent)
			return
		
		new fInReload = get_pdata_int(ent, m_fInReload, 4)
			
		new Float:flNextAttack ; flNextAttack = get_pdata_float(id, m_flNextAttack, 5)
		
		if (flNextAttack > 0.0)
			return
			
		if (fInReload)
		{
			set_weapon_anim(id, 0)
			return
		}
		if(cs_get_weapon_ammo(ent) >= get_pcvar_num(cvar_default_clip))
		{
			set_weapon_anim(id, 0)
			return
		}
			
		ham_reload(ent)
	}
	
	if(CurButton & IN_ATTACK2)
	{
		static Float:CurTime
		CurTime = get_gametime()
		
		if(CurTime - 4.0 > g_last_fire[id])
		{
			static ent, ammo
			ent = find_ent_by_owner(-1, "weapon_xm1014", id)
			ammo = cs_get_weapon_ammo(ent)
			
			if(cs_get_weapon_ammo(ent) <= 0)
				return			
			
			for(new i = 0; i < ammo; i++)
			{
				ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
			}
			
			emit_sound(id, CHAN_WEAPON, qb_sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_weapon_anim(id, random_num(1, 2))
			
			g_last_fire[id] = CurTime
		}
	}
	
	if(CurButton & IN_ATTACK)
	{
		static Float:CurTime
		CurTime = get_gametime()
		
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		static ent
		ent = find_ent_by_owner(-1, "weapon_xm1014", id)
		
		if(cs_get_weapon_ammo(ent) <= 0 || get_pdata_int(ent, m_fInReload, XTRA_OFS_WEAPON))
			return
		
		if(CurTime - get_pcvar_float(cvar_delayattack) > g_last_fire2[id])
		{
			emit_sound(id, CHAN_WEAPON, qb_sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
			ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
			set_weapon_anim(id, random_num(1, 2))
			
			g_last_fire2[id] = CurTime
		}
		
	}	
	
	return 
}

public ham_reload(iEnt)
{
	new id = pev(iEnt, pev_owner)
	
	if(!zp_get_user_zombie(id) && g_had_qb[id])
	{
		static Cur_BpAmmo
		Cur_BpAmmo = cs_get_user_bpammo(id, CSW_QB)

		if(Cur_BpAmmo > 0)
		{
			set_pdata_int(iEnt, 55, 0, 4)
			set_pdata_float(id, 83, get_pcvar_float(cvar_reloadtime), 4)
			set_pdata_float(iEnt, 48, get_pcvar_float(cvar_reloadtime) + 0.5, 4)
			set_pdata_float(iEnt, 46, get_pcvar_float(cvar_reloadtime) + 0.25, 4)
			set_pdata_float(iEnt, 47, get_pcvar_float(cvar_reloadtime) + 0.25, 4)
			set_pdata_int(iEnt, 54, 1, 4)
			
			set_weapon_anim(id, 3)			
		}
		
		return HAM_HANDLED
	}
	return HAM_IGNORED
	
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
	
	if(equal(model, "models/w_xm1014.mdl"))
	{
		static weapon
		weapon = find_ent_by_owner(-1, "weapon_xm1014", entity)
		
		if(!is_valid_ent(weapon))
			return FMRES_IGNORED;
		
		if(g_had_qb[iOwner])
		{
			entity_set_int(weapon, EV_INT_impulse, 120)
			g_had_qb[iOwner] = 0
			set_pev(weapon, pev_iuser3, cs_get_weapon_ammo(weapon))
			entity_set_model(entity, w_model)
			
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED;
}

public fw_item_addtoplayer(ent, id)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED
		
	if(zp_get_user_zombie(id))
		return HAM_IGNORED
			
	if(entity_get_int(ent, EV_INT_impulse) == 120)
	{
		g_had_qb[id] = 1
		cs_set_weapon_ammo(ent, pev(ent, pev_iuser3))
		
		entity_set_int(id, EV_INT_impulse, 0)
		check_draw_weapon(id)
		
		return HAM_HANDLED
	}		

	return HAM_HANDLED
}

public ham_priattack(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!zp_get_user_zombie(id) && g_had_qb[id])
	{
		if(cs_get_weapon_ammo(ent) > 0)
		{
			emit_sound(id, CHAN_WEAPON, qb_sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		
		set_pdata_float(id, 83, 0.3, 4)
	}
}

public ham_postframe(iEnt)
{
	new id = pev(iEnt, pev_owner)
	
	if(g_had_qb[id])
	{
		static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, XTRA_OFS_PLAYER)
		static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON)
		static iMaxClip ; iMaxClip = get_pcvar_num(cvar_default_clip)

		if(get_pdata_int(iEnt, m_fInReload, XTRA_OFS_WEAPON) && get_pdata_float(id, m_flNextAttack, 5) <= 0.0 )
		{
			new j = min(iMaxClip - iClip, iBpAmmo)
			set_pdata_int(iEnt, m_iClip, iClip + j, XTRA_OFS_WEAPON)
			set_pdata_int(id, 381, iBpAmmo-j, XTRA_OFS_PLAYER)
			
			set_pdata_int(iEnt, m_fInReload, 0, XTRA_OFS_WEAPON)
			cs_set_weapon_ammo(iEnt, get_pcvar_num(cvar_default_clip))
		
			return
		}
	}
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(pev(id,pev_body))
	message_end()
}
