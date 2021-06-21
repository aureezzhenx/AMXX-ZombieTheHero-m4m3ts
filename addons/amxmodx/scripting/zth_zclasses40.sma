/*================================================================================
	
	-----------------------------------
	-*- [ZP] Default Zombie Classes -*-
	-----------------------------------
	
	~~~~~~~~~~~~~~~
	- Description -
	~~~~~~~~~~~~~~~
	
	This plugin adds the default zombie classes to Zombie Plague.
	Feel free to modify their attributes to your liking.
	
	Note: If zombie classes are disabled, the first registered class
	will be used for all players (by default, Classic Zombie).
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

// Classic Zombie Attributes
new const zclass1_name[] = { "Tank Zombie" }
new const zclass1_info[] = { "Regular" }
new const zclass1_model[] = { "tank_zombi_host" }
new const zclass1_clawmodel[] = { "v_knife_tank_zombi.mdl" }
const zclass1_health = 1800
const zclass1_speed = 280
const Float:zclass1_gravity = 0.8
const Float:zclass1_knockback = 1.0

/*============================================================================*/

// Class IDs

// Zombie Classes MUST be registered on plugin_precache
public plugin_precache()
{
	register_plugin("[ZP] Default Zombie Classes", "4.3 Fix5", "MeRcyLeZZ")
	
	// Register all classes
	zp_register_zombie_class(zclass1_name, zclass1_info, zclass1_model, zclass1_clawmodel, zclass1_health, zclass1_speed, zclass1_gravity, zclass1_knockback)
}
