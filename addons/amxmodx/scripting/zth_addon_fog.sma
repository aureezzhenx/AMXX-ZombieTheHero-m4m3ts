/*
 * 
 *--------------------------------------
 * [ZP] Addon: Advanced Fog System v1.0
 *--------------------------------------
 * 
 * Description:
 * 
 * With this plugin you can adjust fog colors and density 
 * without restarting the server or changing the map
 * 
 * CVARs
 * 
 * zp_adv_fog_density [Num 1-9] 
 * 	- Density of the fog, must be a number between 1-9
 * zp_adv_fog_color_R [Num]
 * 	- Red color content of the fog
 * zp_adv_fog_color_G [Num]
 * 	- Green color content of the fog
 * zp_adv_fog_color_B [Num]
 * 	- Blue color content of the fog
 * 
 * Credits:
 * 
 * MeRcyLeZZ  For an awsome mode like ZP [I am his fan]
 * @bdul! --- Wrote fog message for me [I am his fan also]
 * DA ------- Took the stupid numbers regarding the 
 * 	      fog message from his Silent HIll Mod
 * 
 * Note:
 * 
 * Tested on ZPA 1.6 and on ZP 4.3
 * Make sure you disable ZP's default fog and
 * set your cs display settings to OpenGl
 * 
 * 
 * - Have Fun
**/

#include <amxmodx>

// Variables
new cvar_fog_density, cvar_fog_color[3]

// Fog density offsets [Thnx to DA]
new const g_fog_density[] = { 0, 0, 0, 0, 111, 18, 3, 58, 111, 18, 125, 58, 66, 96, 27, 59, 90, 101, 60, 59, 90,
			101, 68, 59, 10, 41, 95, 59, 111, 18, 125, 59, 111, 18, 3, 60, 68, 116, 19, 60 }

// The unique id of the fog task
new const TASK_FOG = 5942

// Plugin init
public plugin_init()
{
	// Plugin Registeration
	register_plugin("[ZP] Advanced Fog System", "1.0", "Saad706")
	
	// Register some cvars [Edit these]
	cvar_fog_density = 	register_cvar("zp_adv_fog_density", "2")
	cvar_fog_color[0] = 	register_cvar("zp_adv_fog_color_R", "0")
	cvar_fog_color[1] =	register_cvar("zp_adv_fog_color_G", "0")
	cvar_fog_color[2] = 	register_cvar("zp_adv_fog_color_B", "0")
	
	// Register round start event
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	// Register cvar for detecting servers with our plugin 
	register_cvar("zp_adv_fog", "1.0 By Saad706", FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("zp_adv_fog", "1.0 By Saad706")
}

// Round start
public event_round_start()
{
	// Remove task and then set it again
	remove_task(TASK_FOG)
	set_task(0.5, "task_update_fog", TASK_FOG, _, _, "b")
}

// Task: update fog message
public task_update_fog()
{
	// Get the amount of density
	static density
	density = (4 * get_pcvar_num(cvar_fog_density))
	
	// Finally, the fog message [Thnx to @bdul!]
	message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0)
	write_byte(get_pcvar_num(cvar_fog_color[0])) // Red
	write_byte(get_pcvar_num(cvar_fog_color[1])) // Green
	write_byte(get_pcvar_num(cvar_fog_color[2])) // Blue
	write_byte(g_fog_density[density]) // SD
	write_byte(g_fog_density[density+1]) // ED
	write_byte(g_fog_density[density+2]) // D1
	write_byte(g_fog_density[density+3]) // D2
	message_end()
}
