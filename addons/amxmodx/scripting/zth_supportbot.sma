/// Main Header ///

#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <zombieplague>

#define PLUGIN "[ZP] Bot Support"
#define VERSION "1.0"
#define AUTHOR "aureezz" // and thanks to Dolph_ziggler for bot no attack in new round

new g_weapon[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward( FM_CmdStart , "fm_CmdStart" );
}

public plugin_natives()
{
	register_native("post", "native_guns_menu", 1)
}

public native_guns_menu(id)
{
	post(id)
}

public client_connect(id)
{	
	if(is_user_bot(id)) 
	{
		// Bot bisa pake semua senjata berdasarkan nomor variable dari g_weapon
		g_weapon[id] = random_num(1,17) 
	}
}

public fm_CmdStart(id,Handle)
{
	new Buttons; Buttons = get_uc(Handle,UC_Buttons);
	if(is_user_bot(id) && !zp_has_round_started())
	{
		Buttons &= ~IN_ATTACK;
		set_uc( Handle , UC_Buttons , Buttons );
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
} 

	
public post(id)
{		
	strip_user_weapons(id)
	if(g_weapon[id] == 1)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("plasmagun"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 1
	}
	if(g_weapon[id] == 2)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("skull4"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 2
	}
	if(g_weapon[id] == 3)
	{
		fm_give_item(id, "weapon_m4a1")
		fm_give_item(id, "weapon_deagle")
		g_weapon[id] = 3
	}
	if(g_weapon[id] == 4)
	{
		fm_give_item(id, "weapon_ak47")
		fm_give_item(id, "weapon_deagle")
		g_weapon[id] = 4
	}
	if(g_weapon[id] == 5)
	{
		fm_give_item(id, "weapon_famas")
		fm_give_item(id, "weapon_deagle")
		g_weapon[id] = 5
	}
	if(g_weapon[id] == 6)
	{
		fm_give_item(id, "weapon_xm1014")
		fm_give_item(id, "weapon_deagle")
		g_weapon[id] = 6
	}
	if(g_weapon[id] == 7)
	{
		fm_give_item(id, "weapon_p90")
		fm_give_item(id, "weapon_deagle")
		g_weapon[id] = 7
	}
	if(g_weapon[id] == 8)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("balrog11"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 8
	}
	if(g_weapon[id] == 9)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("CoilGun"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 9
	}
	if(g_weapon[id] == 10)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Janus-5"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 10
	}
	if(g_weapon[id] == 11)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Skull-5"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 11
	}
	if(g_weapon[id] == 12)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Brick Peace V2"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 12
	}
	if(g_weapon[id] == 13)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Magnum-Drill"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 13
	}
	if(g_weapon[id] == 14)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Vandita"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 14
	}
	if(g_weapon[id] == 15)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Thunderbolt"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 15
	}
	if(g_weapon[id] == 16)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Thanatos-5"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 16
	}
	if(g_weapon[id] == 17)
	{
		zp_force_buy_extra_item( id, zp_get_extra_item_id("Speargun"), 1)
		zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
		g_weapon[id] = 17
	}
	
}

public botsenjata(id, menu1, item)
{
	new data[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu1, item, access, data,5, iName, 63, callback)
	new key = str_to_num(data)
	switch(key)
	{	
		case 1:
		{
			if(g_weapon[id] == 1)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("plasmagun"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("plasmagun"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 2)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("skull4"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("skull4"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 3)
			{
				fm_give_item(id, "weapon_m4a1")
				fm_give_item(id, "weapon_deagle")
			}
			else
			{
				fm_give_item(id, "weapon_m4a1")
				fm_give_item(id, "weapon_deagle")
			}
			if(g_weapon[id] == 4)
			{
				fm_give_item(id, "weapon_ak47")
				fm_give_item(id, "weapon_deagle")
			}
			else
			{
				fm_give_item(id, "weapon_ak47")
				fm_give_item(id, "weapon_deagle")
			}
			if(g_weapon[id] == 5)
			{
				fm_give_item(id, "weapon_famas")
				fm_give_item(id, "weapon_deagle")
			}
			else
			{
				fm_give_item(id, "weapon_famas")
				fm_give_item(id, "weapon_deagle")
			}
			if(g_weapon[id] == 6)
			{
				fm_give_item(id, "weapon_xm1014")
				fm_give_item(id, "weapon_deagle")
			}
			else
			{
				fm_give_item(id, "weapon_xm1014")
				fm_give_item(id, "weapon_deagle")
			}
			if(g_weapon[id] == 7)
			{
				fm_give_item(id, "weapon_p90")
				fm_give_item(id, "weapon_deagle")
			}
			else
			{
				fm_give_item(id, "weapon_p90")
				fm_give_item(id, "weapon_deagle")
			}
			if(g_weapon[id] == 8)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("balrog11"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("balrog11"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 9)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("CoilGun"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("CoilGun"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 10)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Janus-5"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Janus-5"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 11)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Skull-5"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Skull-5"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 12)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Brick Peace V2"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Brick Peace V2"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 13)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Magnum-Drill"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Magnum-Drill"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 14)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Vandita"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Vandita"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 15)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Thunderbolt"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Thunderbolt"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 16)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Thanatos-5"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Thanatos-5"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			if(g_weapon[id] == 17)
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Speargun"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
			else
			{
				zp_force_buy_extra_item( id, zp_get_extra_item_id("Speargun"), 1)
				zp_force_buy_extra_item( id, zp_get_extra_item_id("dif"), 1)
			}
		}
	}
}
