#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>

// Zombie Plague
#include <zombieplague>

#define PLUGIN "[CSO] DUAL KRISS HERO || ZOMBIE PLAGUE"
#define VERSION "1.0"
#define AUTHOR "AsepKhairulAnam@CS:ZPMI || -RequiemID- || Facebook.com/asepdwa11"

// CONFIGURATION WEAPON
#define system_name		"dualkrisshero"
#define system_base		"galil"

#define DRAW_TIME		1.3
#define RELOAD_TIME		3.5

#define CSW_BASE		CSW_GALIL
#define WEAPON_KEY 		2123131000

#define OLD_MODEL		"models/w_galil.mdl"
#define ANIMEXT			"dualpistols"

// ALL MACRO
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

// ALL ANIM
#define ANIM_IDLE		0
#define ANIM_IDLE_LEFT_EMPTY	1
#define ANIM_SHOOT_LEFT_1	2
#define ANIM_SHOOT_LEFT_2	3
#define ANIM_SHOOT_LEFT_LAST	4
#define ANIM_SHOOT_RIGHT_1	5
#define ANIM_SHOOT_RIGHT_2	6
#define ANIM_SHOOT_RIGHT_LAST	7
#define ANIM_RELOAD		8
#define ANIM_DRAW		9

// Configuration Extra Items
#define NAME_EXTRA_ITEMS	"Dual Kriss Hero"
#define TEAM_EXTRA_ITEMS	ZP_TEAM_HUMAN
#define COST_EXTRA_ITEMS	35

// All Models Of The Weapon
new V_MODEL[64] = "models/v_dualkrisshero.mdl"
new P_MODEL[64] = "models/p_dualkrisshero.mdl"
new W_MODEL[64] = "models/w_dualkrisshero.mdl"

new const WeaponResources[][] =
{
	"sprites/asep/640hud7_2.spr",
	"sprites/asep/640hud127_2.spr"
}

// You Can Add Fire Sound Here
new const Fire_Sounds[][] = { "weapons/dualkrisshero-1.wav" }

// All Vars Here
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new cvar_dmg, cvar_recoil, cvar_clip, cvar_spd, cvar_ammo, g_item
new g_maxplayers, g_orig_event, g_primary_attack_tmp[33], Float:cl_pushangle[33][3], g_attack_type[33]
new g_has_weapon[33], g_clip_ammo[33], g_weapon_TmpClip[33], oldweap[33], bool:g_zoom[33]

// Macros Again lol
new weapon_name_buffer[512]
new weapon_base_buffer[512]
		
const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

// START TO CREATE PLUGINS || AMXMODX FORWARD
public plugin_init()
{
	formatex(weapon_name_buffer, sizeof(weapon_name_buffer), "weapon_%s_asep", system_name)
	formatex(weapon_base_buffer, sizeof(weapon_base_buffer), "weapon_%s", system_base)
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Event And Message
	register_event("CurWeapon", "Event_CurrentWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	// Ham Forward (Entity) || Ham_TraceAttack
	RegisterHam(Ham_TraceAttack, "player", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "Forward_TraceAttack", 1)
	
	// Ham Forward (Weapon)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_base_buffer, "Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_base_buffer, "Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_base_buffer, "Weapon_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_base_buffer, "Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_base_buffer, "Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_base_buffer, "Weapon_AddToPlayer")
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_base_buffer, "Weapon_Idle")
	
	// Ham Forward (Player)
	RegisterHam(Ham_TakeDamage, "player", "Forward_TakeDamage")
	
	// Fakemeta Forward
	register_forward(FM_SetModel, "Forward_SetModel")
	register_forward(FM_PlaybackEvent, "Forward_PlaybackEvent")
	register_forward(FM_UpdateClientData, "Forward_UpdateClientData_Post", 1)
	
	// All Some Cvar
	cvar_clip = register_cvar("dualkrisshero_clip", "70")
	cvar_spd = register_cvar("dualkrisshero_shoot_speed_delay", "0.14")
	cvar_ammo = register_cvar("dualkrisshero_ammo", "270")
	cvar_dmg = register_cvar("dualkrisshero_damage", "2.0")
	cvar_recoil = register_cvar("dualkrisshero_recoil", "0.5")
	
	g_maxplayers = get_maxplayers()
	g_item = zp_register_extra_item(NAME_EXTRA_ITEMS, COST_EXTRA_ITEMS, TEAM_EXTRA_ITEMS)
}

public plugin_precache()
{
	require_module("cstrike")
	require_module("fakemeta")
	require_module("hamsandwich")
	
	formatex(weapon_name_buffer, sizeof(weapon_name_buffer), "weapon_%s_asep", system_name)
	formatex(weapon_base_buffer, sizeof(weapon_base_buffer), "weapon_%s", system_base)
	
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "sprites/%s.txt", weapon_name_buffer)
	precache_generic(Buffer)
	
	for(new i = 0; i < sizeof(Fire_Sounds); i++)
		precache_sound(Fire_Sounds[i])
	for(new i = 0; i < sizeof(WeaponResources); i++)
		precache_model(WeaponResources[i])
	
	precache_viewmodel_sound(V_MODEL)
	formatex(Buffer, sizeof(Buffer), "_%s", system_name)
	register_clcmd(Buffer, "give_item")
	register_clcmd(weapon_name_buffer, "weapon_hook")
	register_forward(FM_PrecacheEvent, "Forward_PrecacheEvent_Post", 1)
}

public plugin_natives()
{
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "get_%s", system_name)
	register_native(Buffer, "give_item", 1)
	formatex(Buffer, sizeof(Buffer), "remove_%s", system_name)
	register_native(Buffer, "remove_item", 1)
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_item)
		return

	give_item(id)
}

// Reset Bitvar (Fix Bug) If You Connect Or Disconnect Server
public client_connect(id) remove_item(id)
public client_disconnect(id) remove_item(id)
public zp_user_infected_post(id) remove_item(id)
public zp_user_humanized_post(id) remove_item(id)
/* ========= START OF REGISTER HAM TO SUPPORT BOTS FUNC ========= */
new g_HamBot
public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_RegisterHam", id)
	}
}

public Do_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "Forward_TraceAttack", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "Forward_TakeDamage")
}

public Forward_PrecacheEvent_Post(type, const name[])
{
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "events/%s.sc", system_base)
	if(equal(Buffer, name, 0))
	{
		g_orig_event = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public Forward_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(entity, pev_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, OLD_MODEL))
	{
		static w_entity
		w_entity = fm_find_ent_by_owner(-1, weapon_base_buffer, entity)
			
		if(!pev_valid(w_entity))
			return FMRES_IGNORED

		if(g_has_weapon[iOwner])
		{
			set_pev(w_entity, pev_impulse, WEAPON_KEY)
			g_has_weapon[iOwner] = 0
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public Forward_UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
	if(!is_user_alive(id) || (get_user_weapon(id) != CSW_BASE || !g_has_weapon[id]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
	return FMRES_HANDLED
}

public Forward_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if((eventid != g_orig_event) || !g_primary_attack_tmp[invoker])
		return FMRES_IGNORED
	if(!(1 <= invoker <= g_maxplayers))
		return FMRES_IGNORED

	fm_playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

/* ================= END OF ALL FAKEMETA FORWARD ================= */
/* ================= START OF ALL MESSAGE FORWARD ================ */
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, system_base) && get_user_weapon(iAttacker) == CSW_BASE)
	{
		if(g_has_weapon[iAttacker])
			set_msg_arg_string(4, system_name)
	}
	return PLUGIN_CONTINUE
}
/* ================== END OF ALL MESSAGE FORWARD ================ */
/* ================== START OF ALL EVENT FORWARD ================ */
public Event_CurrentWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	replace_weapon_models(id, read_data(2))
}

/* ================== END OF ALL EVENT FORWARD =================== */
/* ================== START OF ALL HAM FORWARD =================== */
public Forward_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_BASE)
		{
			if(g_has_weapon[attacker])
			{
				if(damagebits & DMG_BULLET)
				{
					SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg))
				}
			}
		}
	}
}

public Forward_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iAttacker))
		return
	if(get_user_weapon(iAttacker) != CSW_BASE || !g_has_weapon[iAttacker])
		return

	static Float:flEnd[3], Float:WallVector[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, WallVector)
	
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
	write_byte(TE_STREAK_SPLASH)
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	engfunc(EngFunc_WriteCoord, WallVector[0] * random_float(25.0,30.0))
	engfunc(EngFunc_WriteCoord, WallVector[1] * random_float(25.0,30.0))
	engfunc(EngFunc_WriteCoord, WallVector[2] * random_float(25.0,30.0))
	write_byte(5)
	write_short(20)
	write_short(3)
	write_short(90)	
	message_end()
}

public Weapon_AddToPlayer(weapon_entity, id)
{
	if(!pev_valid(weapon_entity) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(pev(weapon_entity, pev_impulse) == WEAPON_KEY)
	{
		g_has_weapon[id] = true
		set_pev(weapon_entity, pev_impulse, 0)
		set_weapon_list(id, true)
		return HAM_HANDLED
	}
	else
	{
		set_weapon_list(id, false)
	}
	
	return HAM_IGNORED
}

public Weapon_PrimaryAttack(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	
	if(!g_has_weapon[id])
		return
	
	g_primary_attack_tmp[id] = 1
	pev(id, pev_punchangle, cl_pushangle[id])
	
	g_clip_ammo[id] = cs_get_weapon_ammo(weapon_entity)
}

public Weapon_PrimaryAttack_Post(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)
	
	if(!is_user_alive(id))
		return
		
	if(g_has_weapon[id])
	{
		g_primary_attack_tmp[id] = 0
		
		if(!g_clip_ammo[id])
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, weapon_entity)
			return
		}

		new Float:push[3]
		pev(id, pev_punchangle, push)
		xs_vec_sub(push, cl_pushangle[id], push)
		xs_vec_mul_scalar(push, get_pcvar_float(cvar_recoil), push)
		xs_vec_add(push, cl_pushangle[id], push)
		set_pev(id, pev_punchangle, push)
		set_player_dualpistols_anim(id, g_attack_type[id])
		
		if(g_clip_ammo[id] > 2)
		{
			if(!g_attack_type[id]) set_weapon_anim(id, random_num(ANIM_SHOOT_RIGHT_1, ANIM_SHOOT_RIGHT_2))
			else set_weapon_anim(id, random_num(ANIM_SHOOT_LEFT_1, ANIM_SHOOT_LEFT_2))
			
			g_attack_type[id] = !g_attack_type[id] ? 1 : 0
		}
		else if(g_clip_ammo[id] == 2) set_weapon_anim(id, ANIM_SHOOT_LEFT_LAST)
		else if(g_clip_ammo[id] == 1) set_weapon_anim(id, ANIM_SHOOT_RIGHT_LAST)
		
		emit_sound(id, CHAN_WEAPON, Fire_Sounds[random_num(0, sizeof(Fire_Sounds)-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_pdata_float(weapon_entity, 46, get_pcvar_float(cvar_spd), 4)
	}
}

public Weapon_ItemPostFrame(weapon_entity) 
{
	if(!pev_valid(weapon_entity))
		return HAM_IGNORED
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_has_weapon[id])
		return HAM_IGNORED

	static iClipExtra
	iClipExtra = get_pcvar_num(cvar_clip)
	new Float:flNextAttack = get_pdata_float(id, 83, 5)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_BASE)
	new iClip = get_pdata_int(weapon_entity, 51, 4)

	new fInReload = get_pdata_int(weapon_entity, 54, 4) 
	if(fInReload && flNextAttack <= 0.0)
	{
		new j = min(iClipExtra - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, 51, iClip + j, 4)
		cs_set_user_bpammo(id, CSW_BASE, iBpAmmo-j)
		
		set_pdata_int(weapon_entity, 54, 0, 4)
		fInReload = 0
	}
	else if(!fInReload)
	{
		if(flNextAttack <= 0.0)
		{
			if(pev(id, pev_button) & IN_ATTACK2)
			{
				emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.5, ATTN_NORM, 0, PITCH_NORM)
				
				set_player_nextattack(id, 0.25)
				set_weapons_timeidle(id, CSW_BASE, 0.25)
				
				if(!g_zoom[id]) set_fov(id, 80)
				else set_fov(id)
				
				g_zoom[id] = !g_zoom[id] ? true : false
			}
		}
	}
	
	return HAM_IGNORED
}

public Weapon_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_has_weapon[id])
		return HAM_IGNORED

	static iClipExtra
	if(g_has_weapon[id])
		iClipExtra = get_pcvar_num(cvar_clip)

	g_weapon_TmpClip[id] = -1

	new iBpAmmo = cs_get_user_bpammo(id, CSW_BASE)
	new iClip = get_pdata_int(weapon_entity, 51, 4)

	if(iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if(iClip >= iClipExtra)
		return HAM_SUPERCEDE

	g_weapon_TmpClip[id] = iClip

	return HAM_IGNORED
}

public Weapon_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_has_weapon[id])
		return HAM_IGNORED
	if(g_weapon_TmpClip[id] == -1)
		return HAM_IGNORED
	
	if(g_zoom[id])
	{
		g_zoom[id] = false
		set_fov(id)
	}
	
	set_pdata_int(weapon_entity, 51, g_weapon_TmpClip[id], 4)
	set_pdata_float(weapon_entity, 48, RELOAD_TIME, 4)
	set_pdata_float(id, 83, RELOAD_TIME, 5)
	set_pdata_int(weapon_entity, 54, 1, 4)
	
	set_weapon_anim(id, ANIM_RELOAD)
	set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
	
	return HAM_IGNORED
}

public Weapon_Idle(weapon_entity)
{
	if(get_pdata_float(weapon_entity, 48, 4) > 0.0)
		return HAM_IGNORED
		
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	
	new ammo, clip
	get_user_weapon(id, clip, ammo)
	
	set_pdata_float(weapon_entity, 48, 2.0, 4)
	if(clip == 1) set_weapon_anim(id, ANIM_IDLE_LEFT_EMPTY)
	
	return HAM_SUPERCEDE
}

/* ===================== END OF ALL HAM FORWARD ====================== */
/* ================= START OF OTHER PUBLIC FUNCTION  ================= */
public give_item(id)
{
	drop_weapons(id, 1)
	new iWeapon = fm_give_item(id, weapon_base_buffer)
	if(iWeapon > 0)
	{
		cs_set_weapon_ammo(iWeapon, get_pcvar_num(cvar_clip))
		cs_set_user_bpammo(id, CSW_BASE, get_pcvar_num(cvar_ammo))
		emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		set_weapon_anim(id, ANIM_DRAW)
		set_pdata_float(id, 83, DRAW_TIME, 5)
		
		set_weapon_list(id, true)
		set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
	}
	
	g_has_weapon[id] = true
	g_zoom[id] = false
}

public remove_item(id)
{
	g_has_weapon[id] = false
	g_zoom[id] = false
}

public weapon_hook(id)
{
	engclient_cmd(id, weapon_base_buffer)
	return PLUGIN_HANDLED
}

public replace_weapon_models(id, weaponid)
{	
	switch(weaponid)
	{
		case CSW_BASE:
		{
			if(g_has_weapon[id])
			{
				set_pev(id, pev_viewmodel2, V_MODEL)
				set_pev(id, pev_weaponmodel2, P_MODEL)
				
				if(oldweap[id] != CSW_BASE) 
				{
					set_weapon_anim(id, ANIM_DRAW)
					set_player_nextattack(id, DRAW_TIME)
					set_weapons_timeidle(id, CSW_BASE, DRAW_TIME)
					set_weapon_list(id, true)
					set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
					
					
				}
			}
		}
	}
	
	if(weaponid != CSW_BASE && g_zoom[id])
	{
		g_zoom[id] = false
		set_fov(id)
	}
					
	oldweap[id] = weaponid
}

public set_player_dualpistols_anim(id, Right)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_BASE || !g_has_weapon[id])
		return
	
	static iAnimDesired, szAnimation[64]
	if(Right) formatex(szAnimation, charsmax(szAnimation), (pev(id, pev_flags) & FL_DUCKING) ? "crouch_shoot_dualpistols" : "ref_shoot_dualpistols")
	else formatex(szAnimation, charsmax(szAnimation), (pev(id, pev_flags) & FL_DUCKING) ? "crouch_shoot2_dualpistols" : "ref_shoot2_dualpistols")
	if((iAnimDesired = lookup_sequence(id, szAnimation)) == -1)
		iAnimDesired = 0
	
	set_pev(id, pev_sequence, iAnimDesired)
}

/* ============= END OF OTHER PUBLIC FUNCTION (Weapon) ============= */
/* ================= START OF ALL STOCK TO MACROS ================== */
stock set_weapon_list(id, bool:set)
{
	if(!is_user_connected(id))
		return
	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id)
	write_string(!set ? weapon_base_buffer : weapon_name_buffer)
	write_byte(4)
	write_byte(300)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(17)
	write_byte(CSW_BASE)
	write_byte(0)
	message_end()
}

stock drop_weapons(id, dropwhat)
{
	if(!is_user_connected(id))
		return
		
	static weapons[32], num = 0, i, weaponid
	get_user_weapons(id, weapons, num)
     
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
          
		if(dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 1.0, 4)
}

stock set_weapon_anim(const id, const Sequence)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, Sequence)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id)
	write_byte(Sequence)
	write_byte(0)
	message_end()
}

stock precache_viewmodel_sound(const model[])
{
	new file, i, k
	if((file = fopen(model, "rt")))
	{
		new szsoundpath[64], NumSeq, SeqID, Event, NumEvents, EventID
		fseek(file, 164, SEEK_SET)
		fread(file, NumSeq, BLOCK_INT)
		fread(file, SeqID, BLOCK_INT)
		
		for(i = 0; i < NumSeq; i++)
		{
			fseek(file, SeqID + 48 + 176 * i, SEEK_SET)
			fread(file, NumEvents, BLOCK_INT)
			fread(file, EventID, BLOCK_INT)
			fseek(file, EventID + 176 * i, SEEK_SET)
			
			for(k = 0; k < NumEvents; k++)
			{
				fseek(file, EventID + 4 + 76 * k, SEEK_SET)
				fread(file, Event, BLOCK_INT)
				fseek(file, 4, SEEK_CUR)
				
				if(Event != 5004)
					continue
				
				fread_blocks(file, szsoundpath, 64, BLOCK_CHAR)
				
				if(strlen(szsoundpath))
				{
					strtolower(szsoundpath)
					engfunc(EngFunc_PrecacheSound, szsoundpath)
				}
			}
		}
	}
	fclose(file)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, 41, 4)
}

stock set_fov(id, fov = 90)
{
	message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
	write_byte(fov)
	message_end()
}

/* ================= END OF ALL STOCK AND PLUGINS CREATED ================== */
