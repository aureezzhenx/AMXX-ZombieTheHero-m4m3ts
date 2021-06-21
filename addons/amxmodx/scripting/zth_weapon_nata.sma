#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#pragma semicolon 0

#define NAME		"nata"
#define VERSION		"2.0"
#define AUTHOR		"m4m3ts"

#define	KNIFE_KNOCK	0
#define BLOOD		3
#define ADMIN		"0"

#define V_MODEL "models/v_strong_knife.mdl"
#define P_MODEL "models/p_strong_knife.mdl"

new Float:g_c_nata_swing_range = 0.5,Float:g_c_nata_stab_range = 1.55

static const SoundList[][] =
{
	"weapons/strong_deploy.wav",	// 0
	"weapons/strong_hitwall.wav",	// 1
	"weapons/strong_slash.wav",	// 2
	"weapons/strong_stab.wav",	// 3
	"weapons/strong_hit.wav",	// 4
	"weapons/strong_hit.wav"	// 5
}

static const Blood[][] =
{
	"sprites/blood.spr",
	"sprites/bloodspray.spr"
}
static g_Blood[sizeof Blood]
static bool:Knife[33], g_attack_type[33]

enum
{
	ATTACK_SLASH = 1,
	ATTACK_STAB,
}

new g_MaxPlayers

public plugin_init()
{
	register_plugin(NAME, VERSION, AUTHOR)	
	register_event("CurWeapon", "ChangeModel", "be", "1=1")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fwTraceline")
	register_forward(FM_TraceHull, "fwTracehull", 1)
	register_forward(FM_EmitSound, "KnifeSound")
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	
	static i
	for(i = 0; i <= charsmax(SoundList); i++)
		precache_sound(SoundList[i])
		
	for(i = 0; i <= charsmax(Blood); i++)
		g_Blood[i] = precache_model(Blood[i])
}

public client_putinserver(id)
{
	new g_ham_bot
	
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

public plugin_natives()
{
    register_native("give_nata", "native_give_nata", 1)
}

public native_give_nata(id)
{
        give_nata(id)
}
public zp_user_infected_pre(id) Knife[id] = false
public zp_user_infected_post(id) Knife[id] = false

public Event_NewRound()
{
	for(new i = 0; i < g_MaxPlayers; i++)
		remove_katana(i)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!Knife[id])
		return
	
	static ent
	ent = find_ent_by_owner(-1, "weapon_knife", id)
	
	if(!pev_valid(ent))
		return
	if(get_pdata_float(ent, 46, 4) > 0.0 || get_pdata_float(ent, 47, 4) > 0.0) 
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK)
	{
		g_attack_type[id] = ATTACK_SLASH
	} else {
		g_attack_type[id] = ATTACK_STAB
	}
}

public remove_katana(id) Knife[id] = false

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_KNIFE || !Knife[attacker])
		return HAM_IGNORED
			
	SetHamParamFloat(3, g_attack_type[attacker] == ATTACK_SLASH ? 400.0 : 1000.0)
	
	return HAM_HANDLED
}

public Player_Spawn(id)
{
	Knife[id] = false
}

public fw_PlayerKilled(id)
{
	Knife[id] = false
}


public give_nata(id)
{
		Knife[id] = true
		engclient_cmd(id, "weapon_knife")
		change(id)
}

public ChangeModel(id)
{		
	if(!is_user_alive(id))
		return

	if(get_user_weapon(id) == CSW_KNIFE && Knife[id])
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
	}
}

public KnifeSound(id, channel, sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!equal(sample, "weapons/knife_", 14) || !Knife[id])
		return FMRES_IGNORED
	if(equal(sample[8], "knife_hitwall", 13))
		PlaySound(id, 1)	
	else
	if(equal(sample[8], "knife_hit", 9))
		switch(random(2))
		{
			case 0:PlaySound(id, 4)
			case 1:PlaySound(id, 5)
		}		
	if(equal(sample[8], "knife_slash", 11)) PlaySound(id, 2)
	if(equal(sample[8], "knife_stab", 10)) PlaySound(id, 3)
	if(equal(sample[8], "knife_deploy", 12)) PlaySound(id, 0)
	return FMRES_SUPERCEDE
}

public fwTraceline(Float:fStart[3], Float:fEnd[3], conditions, id, ptr){
	return vTrace(id, ptr,fStart,fEnd,conditions)
}

public fwTracehull(Float:fStart[3], Float:fEnd[3], conditions, hull, id, ptr){
	return vTrace(id, ptr,fStart,fEnd,conditions,true,hull)
}

vTrace(id, ptr,Float:fStart[3],Float:fEnd[3],iNoMonsters,bool:hull = false,iHull = 0)
{	
	if(is_user_alive(id) && !zp_get_user_zombie(id) && get_user_weapon(id) == CSW_KNIFE && Knife[id]){
		static buttons
		buttons = pev(id, pev_button)
		
		new Float:scalar
		
		if (buttons & IN_ATTACK)
			scalar = g_c_nata_swing_range
		else if (buttons & IN_ATTACK2)
			scalar = g_c_nata_stab_range

		
		xs_vec_sub(fEnd,fStart,fEnd)
		xs_vec_mul_scalar(fEnd,scalar,fEnd);
		xs_vec_add(fEnd,fStart,fEnd);
		
		hull ? engfunc(EngFunc_TraceHull,fStart,fEnd,iNoMonsters,iHull,id,ptr) : engfunc(EngFunc_TraceLine,fStart,fEnd,iNoMonsters, id,ptr)
	}
	
	return FMRES_IGNORED;
}

change(id)
{
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
}

stock PlaySound(Ent, Sound)
	engfunc(EngFunc_EmitSound, Ent, CHAN_WEAPON, SoundList[_:Sound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
