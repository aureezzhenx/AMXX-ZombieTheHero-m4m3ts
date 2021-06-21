#include <amxmodx>
#include <zombieplague>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <fun>

new const PLUGIN[] = "[CSO] Class Sting Finger"
new const VERSION[] = "2.0"
new const AUTHOR[] =  "m4m3ts"
new STING_V_MODEL[64] = "models/zombie_plague/v_knife_zombieresident.mdl"
new const g_vgrenade[] = "models/zombie_plague/v_zombibomb_resident.mdl"
const Float:zclass_speed = 280.0
const Float:zclass_gravity = 0.8

const Float:gravity_time = 10.0 //Время гравитации;
const Float:realod_gravity  =  200.0 //Отсчет до гравитации;
const Float:realod_gmg  = 200.0 //Отсчет до вытягивание рук;
const Float:finger_gravity = 0.34 //Гравитая при способности;

const dmg_long = 1500 //Дамаг вытягивания рук;
const Distance = 160 //Дистанция для вытягивание рук;
const MAX_CLIENTS = 32 ;

const FINGER_MAX_STRING = 128;

enum _:FINGER_ANIMATIONS
{
	LongDamageAnim   = 8,
	GravAnim      = 9,
	EndGrav        = 10,
	skill1        = 91,
	skill2       = 98
};

enum _:FINGER_SOUNDS
{
	SKILL_2 = 0,
	SKILL_1,
	OVER_SKILL_GRAV,
	STAB,
	STAB_MISS,
	DEATH,
	INFECT,
	PAIN1,
	PAIN2
};

new g_stinger_sound[FINGER_SOUNDS][FINGER_MAX_STRING] = 
{
	"zombie_plague/resident_skill2.wav",
	"zombie_plague/resident_skill1.wav",
	"zombie_plague/resident_tw.wav" ,
	"zombie_plague/resident_stab.wav" ,
	"zombie_plague/resident_stab_miss.wav" ,
	"zombie_plague/resident_death.wav" ,
	"zombie_plague/resident_infect.wav" ,
	"zombie_plague/resident_hurt1.wav" ,
	"zombie_plague/resident_hurt1.wav"
};

enum (+= 100)
{
	TASK_BOT_USE_SKILL = 2000,
	TASK_BOT_USE_SKILL2
}

#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_BOT_USE_SKILL2 (taskid - TASK_BOT_USE_SKILL2)

new class_sting[33] , 
g_damage_use[ MAX_CLIENTS + 1 ] , 
g_gravity_use[ MAX_CLIENTS + 1] ,
g_coldown[ MAX_CLIENTS + 1 ] ,
g_clodown_grav[MAX_CLIENTS + 1] ;
  
new index_sting

new g_maxplayers, g_msgSayText
  
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR) ;
	
	register_forward(FM_CmdStart , "fm_cmdstart" ) ;
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	RegisterHam(Ham_TakeDamage, "player", "String_TakeDamage");
	register_event("DeathMsg", "Death", "a");
	register_logevent("logevent_round_end", 2, "1=Round_End");
	register_event("CurWeapon","EventCurWeapon","be","1=1");
	
	g_maxplayers = get_maxplayers()
	g_msgSayText = get_user_msgid("SayText")
}

public plugin_precache()
{	
	static i ;
	
	for(i = 0; i < sizeof g_stinger_sound; i++)
	{
		precache_sound(g_stinger_sound[i]);
	}
	
	index_sting = precache_model("models/player/resident_zombi_origin/resident_zombi_origin.mdl")
	precache_model(STING_V_MODEL)
	precache_model(g_vgrenade)
}

public plugin_natives()
{
	register_native("give_sting", "native_give_sting", 1)
	register_native("sting_reset_value", "native_sting_reset_value", 1)
}

public native_give_sting(id)
{
	give_sting(id)
}

public native_sting_reset_value(id)
{
	sting_reset_value(id)
}

public Death(id)
{
	new id = read_data(2)

	if(zp_get_user_zombie(id) && class_sting[id] && !zp_get_user_nemesis(id))
	{
		engfunc( EngFunc_EmitSound, id, CHAN_ITEM, g_stinger_sound[DEATH], 1.0, ATTN_NORM, 0, PITCH_NORM)
		sting_reset_value(id)
	}
}


public give_sting( id )
{
	g_damage_use[id] = false 
	g_gravity_use[id] = false 
	g_coldown[id] = false 
	g_clodown_grav[id] = false 
		
	class_sting[id] = true
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	zp_override_user_model(id, "resident_zombi_origin")
	set_pdata_int(id, 491, index_sting, 5)
	set_user_maxspeed(id, zclass_speed)
	set_user_gravity(id, zclass_gravity)
                                                                        
	remove_task(id) 
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [R]^x01 to Gravity")
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [E]^x01 to Penetrate")
	
	if(is_user_bot(id))
	{
		set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		set_task(random_float(5.0,15.0), "bot_use_skill2", id+TASK_BOT_USE_SKILL2)
		return
	}
}

public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_alive(id)) return;

	UTIL_Gravity(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public bot_use_skill2(taskid)
{
	new id = ID_BOT_USE_SKILL2
	if (!is_user_alive(id)) return;

	UTIL_LongDamage(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill2", id+TASK_BOT_USE_SKILL2)
}

public String_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (class_sting[id] && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		switch(random_num(1,2))
  		{
			case 1: emit_sound(id, CHAN_WEAPON, g_stinger_sound[PAIN1], 1.0, ATTN_NORM, 0, PITCH_LOW)
			case 2: emit_sound(id, CHAN_WEAPON, g_stinger_sound[PAIN2], 1.0, ATTN_NORM, 0, PITCH_LOW)
		}
	}
} 
 
public client_connect(id)
{
	sting_reset_value(id)
}

public client_disconnect(id)
{
	sting_reset_value(id)
}

public event_round_start(id)
{
	sting_reset_value(id)
}

public logevent_round_end(id)
{
	sting_reset_value(id)
}
	
public fm_cmdstart(id , UC_Handle , seed)
{
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED
	}
		
	if(class_sting[id] && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		if(g_clodown_grav[id] == 0)
		{
			new gButton, gOldButton 
			
			gButton = get_uc(UC_Handle, UC_Buttons) 
			gOldButton = pev(id, pev_oldbuttons) 
			
			if((gButton & IN_RELOAD) && !(gOldButton & IN_RELOAD))
		    {
                   set_uc(UC_Handle, UC_Buttons, IN_ATTACK2)
                   set_task(0.1, "UTIL_Gravity", id)
            }
	    } 
		
		if(g_coldown[id] == 0)
		{
			new gButton, gOldButton 
			
			gButton = get_uc(UC_Handle, UC_Buttons) 
			gOldButton = pev(id, pev_oldbuttons) 
			
			if((gButton & IN_USE) && !(gOldButton & IN_USE))
		    {
                   set_uc(UC_Handle, UC_Buttons, IN_ATTACK2)
                   set_task(0.1, "UTIL_LongDamage", id)
            }
	    } 
	}	
	return FMRES_IGNORED 
}

public UTIL_Gravity(id)
{
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED
	}
	
	if(class_sting[id] && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
				   g_gravity_use[id] = true 
				   
				   UTIL_PlayAnim(id , GravAnim) 
				   
				   g_clodown_grav[id] = true 
				   				   
				   entity_set_int( id , EV_INT_sequence, skill2) 
				   
				   set_pdata_float(id , 83, 1.0 , 5) 
	               
				   set_pev( id, pev_gravity, finger_gravity )
				   
				   set_task(gravity_time , "remove_abil" , id )  
	}
	return FMRES_IGNORED 
}	

public remove_abil(id)
{
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED
	}
	
	if(class_sting[id] && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
	   g_gravity_use[id] = false  
	
	   set_pev( id, pev_gravity, zclass_gravity ) 
	
	   UTIL_PlayAnim(id , EndGrav) 
	  	
	   zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Gravity^x01 is Over.") 
	}  
	return FMRES_IGNORED 
	
}

public EventCurWeapon(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	replace_weapon_models(id, read_data(2))
	if(class_sting[id]) set_user_maxspeed(id, zclass_speed)
	
	new weap = get_user_weapon(id)
	
	if(weap == CSW_SMOKEGRENADE && class_sting[id] && zp_get_user_zombie(id))
	{
		entity_set_string(id, EV_SZ_viewmodel, g_vgrenade)
	}
	
	return PLUGIN_HANDLED
}

replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case CSW_KNIFE:
	{
		if(!zp_get_user_zombie(id))
			return;
			
		if(class_sting[id])
			{
				set_pev(id, pev_viewmodel2, STING_V_MODEL)
				set_pev(id, pev_weaponmodel2, "")
			}
		}
	}
}

public UTIL_LongDamage(id)
{
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED
	}
	
	if(class_sting[id] && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		g_damage_use[id] = true  
		
		UTIL_PlayAnim( id , LongDamageAnim ) 
		
		entity_set_int( id , EV_INT_sequence, skill1) 

		g_coldown[id] = 1
				
		set_pdata_float(id , 83, 1.0 , 5) 
		
		Skill(id) 
	}
	
	return FMRES_IGNORED 
}

stock Skill(id)
{
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED;
	}
	
	static gBody , gTarget  
	get_user_aiming(id , gTarget , gBody , Distance) 
	
	if(gTarget)
	{
		if(is_user_alive(gTarget))
		{
			switch(gBody)
			{
				case HIT_STOMACH: dmg_long * 2.0
				case HIT_HEAD: dmg_long * 3.0 
				case HIT_LEFTARM: dmg_long * 1.0
				case HIT_RIGHTARM: dmg_long * 1.0
				case HIT_LEFTLEG: dmg_long * 0.5
				case HIT_RIGHTLEG: dmg_long * 0.5
			}
			
			ExecuteHamB(Ham_TakeDamage, gTarget, 0, id, dmg_long, DMG_SLASH) 
		}
	}
	return FMRES_IGNORED 
}

public sting_reset_value(id)
{
	remove_task(id)
	g_damage_use[id] = false 
	g_gravity_use[id] = false 
	g_coldown[id] = false 
	g_clodown_grav[id] = false 
	class_sting[id] = false
	remove_task(id+TASK_BOT_USE_SKILL)
	remove_task(id+TASK_BOT_USE_SKILL2)
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

stock UTIL_PlayAnim(id , seq)
{
	set_pev(id, pev_weaponanim, seq)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id)
	write_byte(seq)
	write_byte(pev(id, pev_body))
	message_end()
}	

stock cahtcol(const id, const input[], any:...)
{
    new count = 1, players[32]
    static msg[191]
    vformat(msg, 190, input, 3)
    
    replace_all(msg, 190, "!g", "^4")
    replace_all(msg, 190, "!y", "^1")
    replace_all(msg, 190, "!team", "^3")
    
    if (id) players[0] = id; else get_players(players, count, "ch")
    {
        for (new i = 0; i < count; i++)
        {
            if (is_user_connected(players[i]))
            {
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
                write_byte(players[i]);
                write_string(msg);
                message_end();
            }
        }
    }
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
