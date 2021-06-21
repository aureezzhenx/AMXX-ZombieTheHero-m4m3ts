#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

// #define ZOMBIE_BUYMENU

#if defined ZOMBIE_BUYMENU
#include <money>
#endif

enum
{
	anim_idle,
	anim_reload,
	anim_draw,
	anim_shoot1,
	anim_shoot2,
	anim_shoot3
}
new g_mode[33]
new g_anim[33]
new g_ammo[33]
new g_mode2[33]
new g_oldammo[33]
#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define svdex_WEAPONKEY	903
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)
new sExplo, sSmoke
const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
const DMG_NADE = (1<<24)
new const GRENADE_MODEL[] = "models/grenade.mdl"
#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83

new sTrail
#define svdex_RELOAD_TIME 4.0
new const GRENADE_EXPLOSION[] = "sprites/fexplo.spr"
new const GRENADE_SMOKE[] = "sprites/black_smoke3.spr"
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AK47)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_m4a1",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_sg550", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
new const Fire_Sounds[][] = { "weapons/svdex-1.wav","weapons/svdex-launcher.wav" }
new const Sound_Zoom[] = { "weapons/zoom.wav" }
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new svdex_V_MODEL[64] = "models/v_svdex.mdl"
new svdex_V_MODEL2[64] = "models/v_svdex_2.mdl"
new svdex_P_MODEL[64] = "models/p_svdex.mdl"
new svdex_W_MODEL[64] = "models/w_svdex.mdl"
new cvar_dmg_svdex, cvar_recoil_svdex, g_itemid_svdex, cvar_clip_svdex, cvar_svdex_ammo
new g_has_svdex[33]
new g_MaxPlayers, g_orig_event_svdex, g_clip_ammo[33]
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_svdex_TmpClip[33]
new const g_GrenadeEntity [ ] = "zp_grenade"
new g_reload[33]
new gmsgScoreInfo,gmsgDeathMsg,gmsgScoreAttrib,cvar_survivor,cvar_knockback,cvar_knockbacksurv,cvar_unlim,cvar_gren,cvar_grendmg,cvar_grenrad
new g_itemid2
new SayText, g_Ham_Bot
new cvar_zombieplague,  cvar_csbuymenu
new cvar_money_reward_dmg, cvar_ap_reward_dmg
new cvar_money_reward_kill, cvar_ap_reward_kill
#if defined ZOMBIE_BUYMENU
new cvar_zpbuymenu
#endif
public plugin_init()
{
	register_plugin("[ZP] Weapon: SVDex", "1.0", "Crock - Main Code. Prog - Some Fix.")	

	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_svdex_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_svdex_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_svdex_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "svdex__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "svdex__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "svdex__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_think(g_GrenadeEntity, "fw_Think")
	register_touch(g_GrenadeEntity, "*", "fw_touch")
	gmsgScoreAttrib = get_user_msgid("ScoreAttrib")
	gmsgScoreInfo = get_user_msgid("ScoreInfo");
	gmsgDeathMsg = get_user_msgid("DeathMsg");
	gmsgScoreAttrib = get_user_msgid("ScoreAttrib")
	SayText = get_user_msgid("SayText")
	cvar_dmg_svdex = register_cvar("zp_svdex_dmg", "4")
	cvar_recoil_svdex = register_cvar("zp_svdex_recoil", "1.5")
	cvar_clip_svdex = register_cvar("zp_svdex_clip", "20")
	cvar_svdex_ammo = register_cvar("zp_svdex_ammo", "120")
	cvar_survivor = register_cvar("zp_svdex_surv","0")
	cvar_knockback = register_cvar("zp_svdex_kb","1500")
	cvar_grendmg = register_cvar("zp_svdex_nade_dmg","500.0")
	cvar_grenrad = register_cvar("zp_svdex_nade_rad","350.0")
	cvar_gren = register_cvar("zp_svdex_gren","10")
	cvar_knockbacksurv = register_cvar("zp_svdex_kbs","800")
	cvar_unlim = register_cvar("zp_svdex_unlim_g","1")
	cvar_zombieplague = register_cvar("zp_svdex_zombieplague", "0")
#if defined ZOMBIE_BUYMENU
cvar_zpbuymenu = register_cvar("zp_svdex_zpbuymenu", "1")
#endif	
	cvar_csbuymenu = register_cvar("zp_svdex_csbuymenu", "0")
	cvar_money_reward_dmg = register_cvar("zp_svdex_money_dmg", "200")
	cvar_ap_reward_dmg = register_cvar("zp_svdex_ap_dmg", "1")
	cvar_money_reward_kill = register_cvar("zp_svdex_money_kill", "1200")
	cvar_ap_reward_kill = register_cvar("zp_svdex_ap_kill", "5")

	g_itemid2 = zp_register_extra_item("SVDex Nade\r (+1)", 3, ZP_TEAM_HUMAN)
	g_itemid_svdex = zp_register_extra_item("svdex", 30, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(svdex_V_MODEL)
	precache_model(svdex_V_MODEL2)
	precache_model(svdex_P_MODEL)
	precache_model(svdex_W_MODEL)
	precache_model(GRENADE_MODEL)
	precache_sound(Sound_Zoom)
	precache_sound("weapons/svdex_clipin.wav")
	precache_sound("weapons/svdex_clipout.wav")
	precache_sound("weapons/svdex_clipon.wav")
	precache_sound("weapons/svdex_draw.wav")
	precache_sound("weapons/svdex_exp.wav")
	precache_sound("weapons/svdex-launcher.wav")
	precache_sound("weapons/svdex_foley1.wav")
	precache_sound("weapons/svdex_foley2.wav")
	precache_sound("weapons/svdex_foley3.wav")
	precache_sound("weapons/svdex_foley4.wav")
	precache_sound(Fire_Sounds[0])
	sExplo = precache_model(GRENADE_EXPLOSION)
	sSmoke = precache_model(GRENADE_SMOKE)
	precache_sound(Fire_Sounds[1])
	sTrail = precache_model("sprites/laserbeam.spr")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)

}


public plugin_natives()
{
	register_native("has_svdex", "native_has_svdex", 1)
}

public native_has_svdex(id)
{
	has_svdex(id)
}

public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}

public fw_Spawn_Post(id)
{
	remove_svdex(id)
}

public remove_svdex(id)
{
	if(!is_user_connected(id))
		return
		
	g_has_svdex[id] = false
}

public zp_user_humanized_post(id)
{
if(zp_get_user_survivor(id) && get_pcvar_num(cvar_survivor) == 1) give_svdex(id)
}
public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/ak47.sc", name))
	{
		g_orig_event_svdex = get_orig_retval()
		return FMRES_HANDLED
	}
	
	return FMRES_IGNORED
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(id > 0 && id < 33)
	{
	if(!is_user_alive(id) || zp_get_user_zombie(id)) 
	return PLUGIN_HANDLED

	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2) && g_mode2[id] == 0 && g_reload[id] == 0)
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)
		if(szWeapID == CSW_AK47 && g_has_svdex[id])
		{
		if(g_mode[id]==0)
		{
		if(g_ammo[id] > 0)
		{
		set_task(1.5,"mode_new",id)
		g_mode2[id] = 1
		UTIL_PlayWeaponAnimation(id, 6)
		g_oldammo[id] = szClip
		set_pdata_float(id, m_flNextAttack, 2.0, PLAYER_LINUX_XTRA_OFF)
		}
		}
		if(g_mode[id]==2)
		{
		set_task(1.5,"mode_new2",id)
		g_mode2[id] = 1
		UTIL_PlayWeaponAnimation(id, 6)
		set_pdata_float(id, m_flNextAttack, 2.0, PLAYER_LINUX_XTRA_OFF)
		}

	}
		}
	}
	return PLUGIN_HANDLED
}
public mode_new(id)
{
g_mode[id] = 2
g_mode2[id] = 0
replace_weapon_models(id, CSW_AK47)
UTIL_PlayWeaponAnimation(id, 0)
new ak = find_ent_by_owner ( -1, "weapon_ak47", id )
set_pdata_int ( ak, 51, g_ammo[id], 4 )
}
public mode_new2(id)
{
g_mode[id] = 0
g_mode2[id] = 0
replace_weapon_models(id, CSW_AK47)
UTIL_PlayWeaponAnimation(id, 0)
new ak = find_ent_by_owner ( -1, "weapon_ak47", id )
set_pdata_int ( ak, 51, g_oldammo[id], 4 )
}
public client_connect(id)
{
	g_has_svdex[id] = false
}

public client_disconnect(id)
{
	g_has_svdex[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_svdex[id] = false
	}
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
			
			Damage_svdex(ptr, ptd)
			
			engfunc(EngFunc_RemoveEntity, ptr)
	}
		
}

public Damage_svdex(ptr, ptd)
{
	static Owner; Owner = pev(ptr, pev_owner)
	static Attacker; 
	if(!is_user_alive(Owner)) 
	{
		Attacker = 0
		return
	} else Attacker = Owner
	
	if(is_user_alive(ptd) && zp_get_user_zombie(ptd))
		ExecuteHamB(Ham_TakeDamage, ptd, 0, Attacker, get_pcvar_float(cvar_grendmg), DMG_BULLET)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(i, ptr) > 400.0)
			continue
		if(!zp_get_user_zombie(i))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, Attacker, get_pcvar_float(cvar_grendmg), DMG_BULLET)
	}
}

stock kill(k, v) {

	//set_user_frags(v, get_user_frags(v) + 1);
	
	//user_silentkill(v);

	new kteam = get_user_team(k);
	new vteam = get_user_team(v);
	
	new kfrags = get_user_frags(k) + 1;
	new kdeaths = get_user_deaths(k);
	
	new vfrags = get_user_frags(v);
	new vdeaths = get_user_deaths(v);
	
	message_begin(MSG_ALL, gmsgScoreInfo);
	write_byte(k);
	write_short(kfrags);
	write_short(kdeaths);
	write_short(0);
	write_short(kteam);
	message_end();
	
	message_begin(MSG_ALL, gmsgScoreInfo);
	write_byte(v);
	write_short(vfrags);
	write_short(vdeaths);
	write_short(0);
	write_short(vteam);
	message_end();
	
	message_begin(MSG_ALL, gmsgDeathMsg, {0,0,0}, 0);
	write_byte(k);
	write_byte(v);
	write_byte(0);
	write_string("SVDex");
	message_end();
	
	if(get_pcvar_num(cvar_zombieplague)) zp_set_user_ammo_packs(k, zp_get_user_ammo_packs(k) + get_pcvar_num(cvar_ap_reward_kill))
	#if defined ZOMBIE_BUYMENU
	if(get_pcvar_num(cvar_zpbuymenu)) zp_cs_set_user_money(k, zp_cs_get_user_money(k) + get_pcvar_num(cvar_money_reward_kill))	
	#endif
	if(get_pcvar_num(cvar_csbuymenu)) cs_set_user_money(k, cs_get_user_money(k) + get_pcvar_num(cvar_money_reward_kill))
	set_user_frags(k, get_user_frags(k) + 1);
	set_msg_block(gmsgDeathMsg, BLOCK_ONCE)
	set_user_frags(v, get_user_frags(v) + 1);
	set_user_health(v,0)
}
public SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, gmsgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("grenade") // killer's weapon
	message_end()
}
public FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, gmsgScoreAttrib)
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}
public UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
	

	
	cs_set_user_deaths(victim, get_user_deaths(victim) + deaths)
	
	if (scoreboard)
	{	
		message_begin(MSG_BROADCAST, gmsgScoreInfo)
		write_byte(attacker) // id
		write_short(pev(attacker, pev_frags)) // frags
		write_short(get_user_deaths(attacker)) // deaths
		write_short(0) // class?
		write_short(get_user_team(attacker)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, gmsgScoreInfo)
		write_byte(victim) // id
		write_short(pev(victim, pev_frags)) // frags
		write_short(get_user_deaths(victim)) // deaths
		write_short(0) // class?
		write_short(get_user_team(victim)) // team
		message_end()
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
	
	if(equal(model, "models/w_ak47.mdl"))
	{
		static iStoredSVDID
		
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, "weapon_ak47", entity)
	
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
	
		if(g_has_svdex[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, svdex_WEAPONKEY)
			g_has_svdex[iOwner] = false
			
			entity_set_model(entity, svdex_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	
	
	return FMRES_IGNORED;
}
public give_svdex(id)
{
	if(!zp_get_user_survivor(id)) drop_weapons(id, 1);
	if(zp_get_user_survivor(id) && get_pcvar_num(cvar_survivor) == 1)
	{
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	}
	new iWep2 = give_item(id,"weapon_ak47")
	if( iWep2 > 0 )
	{
	cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_svdex))
	cs_set_user_bpammo (id, CSW_AK47, get_pcvar_num(cvar_svdex_ammo))
	}
	g_ammo[id] = get_pcvar_num(cvar_gren)
	g_oldammo[id] = get_pcvar_num(cvar_clip_svdex)
	g_has_svdex[id] = true;
	g_mode[id] = 0
	replace_weapon_models(id, CSW_AK47)
}
public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_svdex)
	{	
	give_svdex(id)
	}
	if(itemid == g_itemid2)
	{	
	if(!g_has_svdex[id])
	{
	print_col_chat( id,"^4[ZP]^1 You don't have a SVDex.") 
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) + 3)
	}else{
	if(g_ammo[id] + 1 > get_pcvar_num(cvar_gren))
	{
	print_col_chat( id,"^4[ZP]^1 You have maximum nades for SVDex.") 
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) + 3)
	}else{
	if(zp_get_user_ammo_packs(id) < 3)
	{
	print_col_chat( id,"^4[ZP]^1 Don't have Ammo Packs.") 
	}else{
	g_ammo[id] = g_ammo[id] + 1
	print_col_chat( id,"^4[ZP]^1 You buy a nade for SVDex.") 
	if(get_user_weapon(id) == CSW_AK47 && g_mode[id] == 2 && g_has_svdex[id])
	{
	new ak = find_ent_by_owner ( -1, "weapon_ak47", id )
	set_pdata_int ( ak, 51, g_ammo[id], 4 )
	}
	}
	}
	}
	}
}
stock print_col_chat(const id, const input[], any:...)  
{  
new count = 1, players[32];  
static msg[191];  
vformat(msg, 190, input, 3);  
replace_all(msg, 190, "!g", "^4"); // Green Color  
replace_all(msg, 190, "!y", "^1"); // Default Color (󩮠湫)  
replace_all(msg, 190, "!t", "^3"); // Team Color  
if (id) players[0] = id; else get_players(players, count, "ch");  
{  
for ( new i = 0; i < count; i++ )  
{  
if ( is_user_connected(players[i]) )  
{  
message_begin(MSG_ONE_UNRELIABLE, SayText, _, players[i]);  
write_byte(players[i]);  
write_string(msg);  
message_end();  
}  
}  
}  
} 
public fw_svdex_AddToPlayer(svdex, id)
{
	if(!is_valid_ent(svdex) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(svdex, EV_INT_WEAPONKEY) == svdex_WEAPONKEY)
	{
		g_has_svdex[id] = true
		g_mode[id] = 0	
		entity_set_int(svdex, EV_INT_WEAPONKEY, 0)
		
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

replace_weapon_models(id, weaponid)
{
	if(id > 0 && id < 33 && is_user_alive(id))
	{
		if(weaponid == CSW_AK47)
		{
		if (zp_get_user_zombie(id) || zp_get_user_survivor(id) && get_pcvar_num(cvar_survivor) == 0)
		return;
			
		if(g_has_svdex[id] && g_mode2[id] == 0)
		{
		if(g_mode[id]==0)
		{
			if(g_anim[id]==0) set_task(0.1,"anim_new",id)
			set_pev(id, pev_viewmodel2, svdex_V_MODEL)
			set_pev(id, pev_weaponmodel2, svdex_P_MODEL)
		}else{
			if(g_anim[id]==0) set_task(0.1,"anim_new",id)
			set_pev(id, pev_viewmodel2, svdex_V_MODEL2)
			set_pev(id, pev_weaponmodel2, svdex_P_MODEL)
		}
		}
		}
		if(weaponid != CSW_AK47)
		{
		g_anim[id] = 0
		}
	}
}
public anim_new(id)
{
	g_anim[id] = 1
}
public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_AK47) || !g_has_svdex[Player])
	return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_svdex_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(Player > 0 && Player < 33)
	{
			
	if (!g_has_svdex[Player])
		return;

	pev(Player,pev_punchangle,cl_pushangle[Player])

	if(g_mode[Player] == 0)	set_pdata_float(Player, m_flNextAttack, 0.4, PLAYER_LINUX_XTRA_OFF)
	if(g_mode[Player] == 0 && zp_get_user_survivor(Player) )
	{
	new ak = find_ent_by_owner ( -1, "weapon_ak47", Player )
	set_pdata_int ( ak, 51,  get_pcvar_num(cvar_clip_svdex), 4 )
	}
	if(g_mode[Player] == 2)	set_pdata_float(Player, m_flNextAttack, 3.0, PLAYER_LINUX_XTRA_OFF)
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
	}
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_svdex))
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_svdex_PrimaryAttack_Post(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	if(Player > 0 && Player < 33)
	{
	
	if(g_has_svdex[Player])
	{
		if(g_mode[Player] == 0)
		{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_svdex),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		//UTIL_PlayWeaponAnimation(Player, 4)
	
		make_blood_and_bulletholes(Player)
		}
		else
		{
		if(g_ammo[Player]  - 1 >= 0)
		{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_svdex),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		g_ammo[Player] = g_ammo[Player] - 1
		make_blood_and_bulletholes2(Player)	
		set_weapons_timeidle(Player, CSW_AK47, 3.0)
		}

		}
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, dmgbits)
{
	if (victim != attacker && is_user_connected(attacker) && !(dmgbits & DMG_NADE))
	{
		if(get_user_weapon(attacker) == CSW_AK47)
		{
			if(g_has_svdex[attacker] && g_mode[attacker] == 0)
			{
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_svdex))
			new Float:vec[3];
			new Float:oldvelo[3];
			get_user_velocity(victim, oldvelo);
			create_velocity_vector(victim , attacker , vec);
			vec[0] += oldvelo[0];
			vec[1] += oldvelo[1];
			set_user_velocity(victim , vec);
			}
		}
	}
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
stock create_velocity_vector(victim,attacker,Float:velocity[3])
{
    if(victim > 0 && victim < 33)
    {
    if(!zp_get_user_zombie(victim) || !is_user_alive(attacker))
        return 0;

    new Float:vicorigin[3];
    new Float:attorigin[3];
    entity_get_vector(victim   , EV_VEC_origin , vicorigin);
    entity_get_vector(attacker , EV_VEC_origin , attorigin);

    new Float:origin2[3]
    origin2[0] = vicorigin[0] - attorigin[0];
    origin2[1] = vicorigin[1] - attorigin[1];

    new Float:largestnum = 0.0;

    if(floatabs(origin2[0])>largestnum) largestnum = floatabs(origin2[0]);
    if(floatabs(origin2[1])>largestnum) largestnum = floatabs(origin2[1]);

    origin2[0] /= largestnum;
    origin2[1] /= largestnum;
    new a
    if(!zp_get_user_survivor(attacker))
    {
    a = get_pcvar_num(cvar_knockback)
    }else{
    a = get_pcvar_num(cvar_knockbacksurv)
    }
    
    velocity[0] = ( origin2[0] * (100 *a) ) / get_entity_distance(victim , attacker);
    velocity[1] = ( origin2[1] * (100 *a) ) / get_entity_distance(victim , attacker);
    if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
        velocity[2] = random_float(200.0 , 275.0);
    }

    return 1;
}

stock make_blood_and_bulletholes2(id)
{	
	UTIL_PlayWeaponAnimation(id, 4)

	new Float:origin[3],Float:velocity[3],Float:angles[3]
	engfunc(EngFunc_GetAttachment, id, 0, origin,angles)
	pev(id,pev_angles,angles)
	new ent = create_entity( "info_target" ) 
	set_pev( ent, pev_classname, g_GrenadeEntity )
	set_pev( ent, pev_solid, SOLID_BBOX )
	set_pev( ent, pev_movetype, MOVETYPE_TOSS )
	set_pev( ent, pev_mins, { -0.1, -0.1, -0.1 } )
	set_pev( ent, pev_maxs, { 0.1, 0.1, 0.1 } )
	entity_set_model( ent, GRENADE_MODEL )
	set_pev( ent, pev_origin, origin )
	set_pev( ent, pev_angles, angles )
	set_pev( ent, pev_owner, id )
	velocity_by_aim( id, 1500, velocity )
	set_pev( ent, pev_velocity, velocity )
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(ent) // Entity
	write_short(sTrail) // Sprite index
	write_byte(15) // Life
	write_byte(3) // Line width
	write_byte(255) // Red
	write_byte(255) // Green
	write_byte(255) // Blue
	write_byte(100) // Alpha
	message_end() 
	
	if(zp_get_user_survivor(id) && get_pcvar_num(cvar_unlim)) g_ammo[id] = get_pcvar_num(cvar_gren)
	new ak = find_ent_by_owner ( -1, "weapon_ak47", id )
	set_pdata_int ( ak, 51, g_ammo[id], 4 )

	if(g_ammo[id] == 0)
	{
	UTIL_PlayWeaponAnimation(id, 6)
	//g_mode[id] = 0
	set_task(1.0,"new_anim3",id)
	if(zp_get_user_survivor(id))
	{
	new ak = find_ent_by_owner ( -1, "weapon_ak47", id )
	set_pdata_int ( ak, 51, get_pcvar_num(cvar_clip_svdex), 4 )
	}else{
	new ak = find_ent_by_owner ( -1, "weapon_ak47", id )
	set_pdata_int ( ak, 51, g_oldammo[id], 4 )
	}
	set_pdata_float(id, m_flNextAttack, 2.0, PLAYER_LINUX_XTRA_OFF)
	}

	return PLUGIN_CONTINUE
}
public new_anim3(id)
{
	g_mode[id] = 0
	replace_weapon_models(id, CSW_AK47)
	UTIL_PlayWeaponAnimation(id, 0)
}
stock make_blood_and_bulletholes(id)
{
	//set_pdata_int ( id, 51, 60, 4)
	//set_pdata_int(CSW_AK47, m_iClip, 1, 4)
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	
	UTIL_PlayWeaponAnimation(id, 4)

	if(zp_get_user_survivor(id))
	{
	new ak = find_ent_by_owner ( -1, "weapon_ak47", id )
	set_pdata_int ( ak, 51, get_pcvar_num(cvar_clip_svdex), 4 )
	}

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

public svdex__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_svdex[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_svdex) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_AK47, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		g_reload[id] = 0
		fInReload = 0
	}

	return HAM_IGNORED;
}

public svdex__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_svdex[id])
		return HAM_IGNORED;

	g_svdex_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_svdex))
		return HAM_SUPERCEDE;


	g_svdex_TmpClip[id] = iClip;

	g_reload[id] = 1

	return HAM_IGNORED;
}
public svdex__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;


	if(g_mode[id] == 1)
	{
	if (!g_has_svdex[id])
		return HAM_IGNORED;

	if (g_svdex_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_svdex_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, svdex_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, svdex_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	// relaod animation
	if(g_mode[id] == 0)
	{
	//UTIL_PlayWeaponAnimation(id, 1)
	}
	}

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

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}

public has_svdex(id)
{
	g_has_svdex[id] = false
}
