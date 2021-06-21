#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#define PLUGIN "DJB Zombie Class Banchee"
#define VERSION "1.0.3"
#define AUTHOR "Csoldjb&wbyokomo"

const Float:zclass_speed = 257.0
const Float:zclass_gravity = 0.8

new const SOUND_FIRE[] = "zombie_plague/zombi_banshee_pulling_fire.wav"
new const SOUND_BAT_HIT[] = "zombie_plague/zombi_banshee_laugh.wav"
new const SOUND_BAT_MISS[] = "zombie_plague/zombi_banshee_pulling_fail.wav"
new const SOUND_FIRE_CONFUSION[] = "zombie_plague/zombi_banshee_confusion_fire.wav"
new const SOUND_CONFUSION_HIT[] = "zombie_plague/zombi_banshee_confusion_keep.wav"
new const SOUND_CONFUSION_EXP[] = "zombie_plague/zombi_banshee_confusion_explosion.wav"
new const MODEL_BAT[] = "models/zombie_plague/bat_witch.mdl"
new const MODEL_BOMB[] = "models/zombie_plague/w_zombibomb.mdl"
new const BAT_CLASSNAME[] = "banchee_bat"
new const CONFUSION_CLASSNAME[] = "banchee_bomb"
new const FAKE_PLAYER_CLASSNAME[] = "fake_player"
new spr_skull, spr_confusion_exp, spr_confusion_icon, spr_confusion_trail, petede

new BANCHEE_V_MODEL[64] = "models/zombie_plague/v_knife_witch_zombi.mdl"
new const g_vgrenade[] = "models/zombie_plague/v_zombibomb_witch.mdl"

new const player_modelsx[7][] =
{
	"models/player/komplit_mercenarytr/komplit_mercenarytr.mdl",
	"models/player/komplit_scyuri/komplit_scyuri.mdl",
	"models/player/komplit_maalice/komplit_maalice.mdl",
	"models/player/komplit_pirateboy/komplit_pirateboy.mdl",
	"models/player/komplit_pirategirl/komplit_pirategirl.mdl",
	"models/player/komplit_gerrard/komplit_gerrard.mdl",
	"models/player/komplit_henry/komplit_henry.mdl"
}

const Float:banchee_skull_bat_speed = 600.0
const Float:banchee_skull_bat_flytime = 3.0
const Float:banchee_skull_bat_catch_time = 5.0
const Float:banchee_skull_bat_catch_speed = 250.0
const Float:bat_timewait = 14.0
const Float:confusion_time = 12.0
new g_stop[33]
new g_iEntFake[33]
new g_bat_time[33]
new confusion_reset[33]
new g_bat_stat[33]
new g_bat_enemy[33]
new Float:g_temp_speed[33]
new g_owner_confusion[33]
new g_fake_ent[33]
new g_is_confusion[33]
new batting[33]
new kelelawar[33]

new classbanchee[33]
new g_maxplayers, index_banshee
new g_roundend
new g_msgSayText, g_msgScreenFade, g_msgScreenShake

enum (+= 100)
{
	TASK_BOT_USE_SKILL = 2367,
	TASK_REMOVE_STAT,
	TASK_CONFUSION,
	TASK_SOUND
}

#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_TASK_REMOVE_STAT (taskid - TASK_REMOVE_STAT)
#define ID_CONFUSION (taskid - TASK_CONFUSION)
#define ID_SOUND (taskid - TASK_SOUND)

const UNIT_SECOND = (1<<12)
const FFADE_IN = 0x0000

public plugin_precache()
{
	precache_sound(SOUND_FIRE)
	precache_sound(SOUND_BAT_HIT)
	precache_sound(SOUND_BAT_MISS)
	precache_sound(SOUND_FIRE_CONFUSION)
	precache_sound(SOUND_CONFUSION_HIT)
	precache_sound(SOUND_CONFUSION_EXP)
	index_banshee = precache_model("models/player/witch_zombi_origin/witch_zombi_origin.mdl")
	precache_model(MODEL_BAT)
	precache_model(MODEL_BOMB)
	precache_model(BANCHEE_V_MODEL)
	precache_model(g_vgrenade)
	
	new i
	for(i = 0; i < sizeof(player_modelsx); i++)
	{
		if(i == 1) engfunc(EngFunc_PrecacheGeneric, player_modelsx[i])
		else engfunc(EngFunc_PrecacheModel, player_modelsx[i])
	}
	
	spr_skull = precache_model("sprites/ef_bat.spr")
	spr_confusion_exp = precache_model("sprites/zombiebomb_exp.spr")
	spr_confusion_icon = precache_model("sprites/confused.spr")
	spr_confusion_trail = precache_model("sprites/smoke.spr")	
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")
	register_event("DeathMsg", "EventDeath", "a")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_impulse(201, "CmdSecondSkill")
	register_clcmd("drop", "cmd_bat")
	register_forward(FM_PlayerPreThink,"fw_PlayerPreThink")
	register_forward(FM_AddToFullPack, "fw_AddToFullPackPost", 1)
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_event("CurWeapon","EventCurWeapon","be","1=1")
	RegisterHam(Ham_Touch,"info_target","EntityTouchPost",1)
	RegisterHam(Ham_Think,"info_target","EntityThink")
	
	g_maxplayers = get_maxplayers()
	g_msgSayText = get_user_msgid("SayText")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
}

public client_putinserver(id)
{
	banchee_reset_value_player(id)
}

public client_disconnect(id)
{
	banchee_reset_value_player(id)
}

public EventHLTV()
{
	g_roundend = 0
	
	RemoveAllFakePlayer()
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		banchee_reset_value_player(id)
	}
}

public plugin_natives()
{
	register_native("give_banchee", "native_give_banchee", 1)
	register_native("banchee_reset_value_player", "native_banchee_reset_value", 1)
}

public native_give_banchee(id)
{
        give_banchee(id)
}

public native_banchee_reset_value(id)
{
        banchee_reset_value_player(id)
}

public logevent_round_end()
{
	g_roundend = 1
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id)) return FMRES_IGNORED
	
	if (classbanchee[id])
	{
		if (batting[id])
		{
			set_uc(uc_handle, UC_Buttons, IN_ATTACK2)
			batting[id] = 0
			set_task(0.1, "bat_anim_start", id)
		}
	}
	
	return FMRES_IGNORED
}

public EventDeath()
{
	new id = read_data(2)
	
	banchee_reset_value_player(id)
}

public give_banchee(id)
{
	banchee_reset_value_player(id)	
	classbanchee[id] = true
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	zp_override_user_model(id, "witch_zombi_origin")
	set_pdata_int(id, 491, index_banshee, 5)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [G]^x01 to Spawn Bat^x03 [T]^x01 to Confuse Bomb")
	
	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		return
	}
}

public zp_user_humanized_post(id)
{
	banchee_reset_value_player(id)
}

public CmdSecondSkill(id)
{
	if(g_roundend) return PLUGIN_CONTINUE
	
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE
	
	if(classbanchee[id] && !confusion_reset[id] && get_user_weapon(id) == CSW_KNIFE)
	{
		confusion_reset[id] = 1
		
		FireConfusion(id)
		PlayWeaponAnimation(id, 7)
		set_task(bat_timewait,"clear_confusion",id)
		
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public bat_anim_start(id)
{
	set_pev(id, pev_framerate, 0.5)
	entity_set_int( id , EV_INT_sequence, 151)
	PlayWeaponAnimation(id, 2)
	set_task(0.3, "slow", id)
}
public slow(id) set_pev(id, pev_framerate, 0.1)
public cmd_bat(id)
{
	if(g_roundend) return PLUGIN_CONTINUE
	
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE
	
	if(classbanchee[id] && !g_bat_time[id] && get_user_weapon(id) == CSW_KNIFE)
	{
		g_bat_time[id] = 1
		batting[id] = 1
		kelelawar[id] = 1
		set_task(bat_timewait,"clear_stat",id+TASK_REMOVE_STAT)
		
		new ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
		
		if(!pev_valid(ent)) return PLUGIN_HANDLED
		
		new Float:vecAngle[3],Float:vecOrigin[3],Float:vecVelocity[3],Float:vecForward[3]
		fm_get_user_startpos(id,5.0,2.0,-1.0,vecOrigin)
		pev(id,pev_angles,vecAngle)
		
		engfunc(EngFunc_MakeVectors,vecAngle)
		global_get(glb_v_forward,vecForward)
		
		velocity_by_aim(id,floatround(banchee_skull_bat_speed),vecVelocity)
		
		set_pev(ent,pev_origin,vecOrigin)
		set_pev(ent,pev_angles,vecAngle)
		set_pev(ent,pev_classname,BAT_CLASSNAME)
		set_pev(ent,pev_movetype,MOVETYPE_FLY)
		set_pev(ent,pev_solid,SOLID_BBOX)
		engfunc(EngFunc_SetSize,ent,{-20.0,-15.0,-8.0},{20.0,15.0,8.0})
		
		engfunc(EngFunc_SetModel,ent,MODEL_BAT)
		set_pev(ent,pev_animtime,get_gametime())
		set_pev(ent,pev_framerate,1.0)
		set_pev(ent,pev_owner,id)
		set_pev(ent,pev_velocity,vecVelocity)
		set_pev(ent,pev_nextthink,get_gametime()+banchee_skull_bat_flytime)
		emit_sound(ent, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		g_stop[id] = ent
		
		pev(id, pev_maxspeed, g_temp_speed[id])
		set_pev(id,pev_maxspeed,0.1)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED
	
	if(g_bat_stat[id])
	{
		new owner = g_bat_enemy[id], Float:ownerorigin[3]
		pev(owner,pev_origin,ownerorigin)
		static Float:vec[3]
		aim_at_origin(id,ownerorigin,vec)
		engfunc(EngFunc_MakeVectors, vec)
		global_get(glb_v_forward, vec)
		vec[0] *= banchee_skull_bat_catch_speed
		vec[1] *= banchee_skull_bat_catch_speed
		vec[2] *= banchee_skull_bat_catch_speed
		set_pev(id,pev_velocity,vec)
	}
	
	return FMRES_IGNORED
}

public fw_AddToFullPackPost(es_handled, inte, ent, host, hostflags, player, pSet)
{
	if (!is_user_alive(host))
		return FMRES_IGNORED
		
	if (!g_is_confusion[host])
		return FMRES_IGNORED

	if ((1 < ent < 32))
	{
		if(is_user_connected(ent) && zp_get_user_zombie(ent))
		{
			set_es(es_handled, ES_RenderMode, kRenderTransAdd)
			set_es(es_handled, ES_RenderAmt, 0.0)
			
			new iEntFake = find_ent_by_owner(-1, FAKE_PLAYER_CLASSNAME, ent)
			if(!iEntFake || !pev_valid(ent))
			{
				iEntFake = CreateFakePlayer(ent)
			}
			
			g_iEntFake[ent] = iEntFake
		}
	}
	
	else if (ent >= g_iEntFake[32])
	{
		if(!is_valid_ent(ent))
			return FMRES_IGNORED
		
		static ent_owner
		ent_owner = pev(ent, pev_owner)
		
		if(!is_user_alive(ent_owner))
			return FMRES_IGNORED
		
		if((1 < ent_owner < 32) && zp_get_user_zombie(ent_owner))
		{
			set_es(es_handled, ES_RenderMode, kRenderNormal)
			set_es(es_handled, ES_RenderAmt, 255.0)

			//set_es(es_handled, ES_ModelIndex, pev(host, pev_modelindex))
		}
	}
	
	return FMRES_IGNORED
}

public EntityThink(ent)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new classname[32]
	pev(ent,pev_classname,classname,31)
	
	if(equal(classname,BAT_CLASSNAME))
	{
		new owner = pev(ent, pev_owner)
		set_pev(ent,pev_nextthink,get_gametime()+ 0.3)
		if(!kelelawar[owner])
		{
			static Float:origin[3];
			pev(ent,pev_origin,origin);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			write_coord(floatround(origin[0]))
			write_coord(floatround(origin[1]))
			write_coord(floatround(origin[2]))
			write_short(spr_skull)
			write_byte(40)
			write_byte(30)
			write_byte(14)
			message_end()
			
			emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			g_stop[owner] = 0
			set_pev(owner,pev_maxspeed,g_temp_speed[owner])
			g_bat_enemy[petede] = 0
			g_bat_stat[petede] = 0
			
			engfunc(EngFunc_RemoveEntity,ent)
		}
	}
	
	return HAM_IGNORED
}

public EntityTouchPost(ent,ptd)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new classname[32]
	pev(ent,pev_classname,classname,31)
	
	if(equal(classname,BAT_CLASSNAME))
	{
		if(!pev_valid(ptd))
		{
			static Float:origin[3];
			pev(ent,pev_origin,origin);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			write_coord(floatround(origin[0]))
			write_coord(floatround(origin[1]))
			write_coord(floatround(origin[2]))
			write_short(spr_skull)
			write_byte(40)
			write_byte(30)
			write_byte(14)
			message_end()
			
			emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			new owner = pev(ent, pev_owner)
			g_stop[owner] = 0
			set_pev(owner,pev_maxspeed,g_temp_speed[owner])
			
			engfunc(EngFunc_RemoveEntity,ent)
			
			return HAM_IGNORED
		}
		
		new owner = pev(ent,pev_owner)
		
		if(0 < ptd && ptd <= g_maxplayers && is_user_alive(ptd) && ptd != owner && kelelawar[owner])
		{
			g_bat_enemy[ptd] = owner
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, ptd)
			write_short(UNIT_SECOND)
			write_short(0)
			write_short(FFADE_IN)
			write_byte(150)
			write_byte(150)
			write_byte(150)
			write_byte(150)
			message_end()
			
			emit_sound(owner, CHAN_VOICE, SOUND_BAT_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM)
						
			set_pev(ent,pev_nextthink,get_gametime()+ 0.3)
			set_task(banchee_skull_bat_catch_time,"clear_stat2",ptd+TASK_REMOVE_STAT)
			set_pev(ent,pev_movetype,MOVETYPE_FOLLOW)
			set_pev(ent,pev_aiment,ptd)
			petede = ptd
			g_bat_stat[ptd] = 1
		}
		else
		{
			static Float:origin[3];
			pev(ent,pev_origin,origin);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			write_coord(floatround(origin[0]))
			write_coord(floatround(origin[1]))
			write_coord(floatround(origin[2]))
			write_short(spr_skull)
			write_byte(40)
			write_byte(30)
			write_byte(14)
			message_end()
			
			emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			new owner = pev(ent, pev_owner)
			g_stop[owner] = 0
			set_pev(owner,pev_maxspeed,g_temp_speed[owner])
			
			engfunc(EngFunc_RemoveEntity,ent)
			
			return HAM_IGNORED
		}
	}
	else if(equal(classname,CONFUSION_CLASSNAME))
	{		
		ConfusionExplode(ent, ptd)
		
		return HAM_IGNORED
	}
	
	return HAM_IGNORED
}

public clear_stat(taskid)
{
	new id = ID_TASK_REMOVE_STAT
	
	g_bat_stat[id] = 0
	g_bat_time[id] = 0
	kelelawar[id] = 0
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Spawn Bat^x01 is ready.")
}

public clear_confusion(id)
{
	confusion_reset[id] = 0
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Confusion^x01 is ready.")
}

public clear_stat2(idx)
{
	new id = idx-TASK_REMOVE_STAT
	
	g_bat_enemy[id] = 0
	g_bat_stat[id] = 0
	kelelawar[id] = 0
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	
	if (!is_user_alive(id)) return;
	
	new skill = random_num(0,1)
	switch(skill)
	{
		case 0: cmd_bat(id)
		case 1: CmdSecondSkill(id)
	}
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public ResetConfusion(taskid)
{
	g_owner_confusion[ID_CONFUSION] = 0
	g_is_confusion[ID_CONFUSION] = 0
	
	RemoveConfusionSprites(ID_CONFUSION)
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	replace_weapon_models(id, read_data(2))
	if(classbanchee[id]) set_user_maxspeed(id, zclass_speed)
	
	new weap = get_user_weapon(id)
	
	if(weap == CSW_SMOKEGRENADE && classbanchee[id] && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_vgrenade)
		if(kelelawar[id])
		{
			kelelawar[id] = 0
		}
	}
	
	return PLUGIN_HANDLED
}

public TaskConfusionSound(taskid)
{
	if(g_is_confusion[ID_SOUND]) emit_sound(ID_SOUND, CHAN_STREAM, SOUND_CONFUSION_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	else remove_task(taskid)
}

FireConfusion(id)
{
	new Float:vecAngle[3],Float:vecOrigin[3],Float:vecVelocity[3],Float:vecForward[3]
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	fm_get_user_startpos(id,5.0,2.0,-1.0,vecOrigin)
	pev(id,pev_angles,vecAngle)
	engfunc(EngFunc_MakeVectors,vecAngle)
	global_get(glb_v_forward,vecForward)
	velocity_by_aim(id,1300,vecVelocity)
	set_pev(ent,pev_origin,vecOrigin)
	set_pev(ent,pev_angles,vecAngle)
	set_pev(ent,pev_classname,CONFUSION_CLASSNAME)
	set_pev(ent,pev_movetype,MOVETYPE_BOUNCE)
	set_pev(ent,pev_solid,SOLID_BBOX)
	set_pev(ent,pev_gravity,1.0)
	set_pev(ent,pev_sequence,1) //add
	set_pev(ent,pev_animtime,get_gametime()) //add
	set_pev(ent,pev_framerate,1.0) //add
	engfunc(EngFunc_SetSize,ent,{-1.0,-1.0,-1.0},{1.0,1.0,1.0})
	engfunc(EngFunc_SetModel,ent,MODEL_BOMB)
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_velocity,vecVelocity)
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMFOLLOW)
	write_short(ent)
	write_short(spr_confusion_trail)
	write_byte(5)
	write_byte(3)
	write_byte(189)
	write_byte(183)
	write_byte(107)
	write_byte(62)
	message_end()
	
	emit_sound(ent, CHAN_WEAPON, SOUND_FIRE_CONFUSION, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

ConfusionExplode(ent, victim)
{
	if(!pev_valid(ent)) return;
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(floatround(Origin[0]))
	write_coord(floatround(Origin[1]))
	write_coord(floatround(Origin[2]))
	write_short(spr_confusion_exp)
	write_byte(40)
	write_byte(30)
	write_byte(14)
	message_end()
		
	emit_sound(ent, CHAN_WEAPON, SOUND_CONFUSION_EXP, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static owner; owner = pev(ent, pev_owner)
	
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(i, ent) > 170.0)
			continue
		if(zp_get_user_zombie(i))
			continue
		if(g_is_confusion[i])
			continue
			
		g_owner_confusion[i] = owner
		g_is_confusion[i] = 1
		
		message_begin(MSG_ONE, g_msgScreenFade, _, i)
		write_short(UNIT_SECOND)
		write_short(0)
		write_short(FFADE_IN)
		write_byte(189)
		write_byte(183)
		write_byte(107)
		write_byte (255)
		message_end()

		new shake[3]
		shake[0] = random_num(2,20)
		shake[1] = random_num(2,5)
		shake[2] = random_num(2,20)
		message_begin(MSG_ONE, g_msgScreenShake, _, i)
		write_short(UNIT_SECOND*shake[0])
		write_short(UNIT_SECOND*shake[1])
		write_short(UNIT_SECOND*shake[2])
		message_end()
		
		emit_sound(i, CHAN_STREAM, SOUND_CONFUSION_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM)
		CreateConfusionSprites(i)
		
		set_task(confusion_time, "ResetConfusion", i+TASK_CONFUSION)
		set_task(2.0, "TaskConfusionSound", i+TASK_SOUND, _, _, "b")
	}
	
	engfunc(EngFunc_RemoveEntity,ent)
}

fm_get_user_startpos(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_MakeVectors, vAngle)
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

aim_at_origin(id, Float:target[3], Float:angles[3])
{
	static Float:vec[3]
	pev(id,pev_origin,vec)
	vec[0] = target[0] - vec[0]
	vec[1] = target[1] - vec[1]
	vec[2] = target[2] - vec[2]
	engfunc(EngFunc_VecToAngles,vec,angles)
	angles[0] *= -1.0
	angles[2] = 0.0
}

PlayWeaponAnimation(id, animation)
{
	set_pev(id, pev_weaponanim, animation)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(animation)
	write_byte(pev(id, pev_body))
	message_end()
}

CreateFakePlayer(id)
{
	new ent = create_entity("info_target")
	set_pev(ent, pev_classname, FAKE_PLAYER_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, player_modelsx[random_num(0,5)])
	set_pev(ent, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_aiment, id)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 0.0)

	return ent
}

CreateConfusionSprites(id)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(id)
	write_coord(35)
	write_short(spr_confusion_icon)
	write_short(999)
	message_end()
}

RemoveConfusionSprites(id)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_KILLPLAYERATTACHMENTS)
	write_byte(id)
	message_end()
}

RemoveAllFakePlayer()
{	
	new ent
	ent = find_ent_by_class(-1, FAKE_PLAYER_CLASSNAME)
	
	while(ent > 0)
	{
		remove_entity(ent)
		ent = find_ent_by_class(-1, FAKE_PLAYER_CLASSNAME)
	}
}

replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case CSW_KNIFE:
	{
		if(!zp_get_user_zombie(id))
			return;
			
		if(classbanchee[id])
			{
				set_pev(id, pev_viewmodel2, BANCHEE_V_MODEL)
				set_pev(id, pev_weaponmodel2, "")
			}
		}
	}
}

banchee_reset_value_player(id)
{
	if(g_is_confusion[id]) RemoveConfusionSprites(id);
	
	g_stop[id] = 0
	g_bat_time[id] = 0
	confusion_reset[id] = 0
	g_bat_stat[id] = 0
	g_bat_enemy[id] = 0
	g_owner_confusion[id] = 0
	g_fake_ent[id] = 0
	g_is_confusion[id] = 0
	classbanchee[id] = false
	kelelawar[id] = 0
	
	remove_task(id+TASK_BOT_USE_SKILL)
	remove_task(id)
}

stock fm_strip_user_weapons2(id)
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent)) return;
	
	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, id)
	engfunc(EngFunc_RemoveEntity, ent)
}

zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	if (!target)
	{
		static player
		for (player = 1; player <= g_maxplayers; player++)
		{
			if (!is_user_connected(player))
				continue;
			
			static changed[5], changedcount
			changedcount = 0
			
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			vformat(buffer, charsmax(buffer), message, 3)
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	else
	{
		vformat(buffer, charsmax(buffer), message, 3)
		
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}
