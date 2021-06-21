#include <amxmodx>
#include <cstrike>
#include <zombieplague>
#include <m4m3tsunlock>
#include <zth_money>
#include <zth_hero>
#include <zth_humanskill>
#include <zth_buffweapon> // DARKKNIGHT & AKPALADIN
#include <zth_cannon>
#include <zth_thunderbolt>
#include <zth_speargun>
#include <zth_janus1>

new g_msgAmmoPickup
new refill_ammo, uang, sprint, bloodyblade, paladin, dk, cannon
new jumlah_paladin, jumlah_dk, jumlah_cannon
new codebox1[33], codebox2[33], codebox3[33]

new const sound_buyammo[] = "items/9mmclip1.wav"

new const AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
			1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

public plugin_init()
{
	register_plugin("Ammo Refill", "1.0", "m4m3ts")
	
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	
	refill_ammo = zp_register_extra_item("Magazine Set", 1, ZP_TEAM_HUMAN)
	uang = zp_register_extra_item("Money", 1, ZP_TEAM_HUMAN)
	sprint = zp_register_extra_item("Sprint for 1 Round", 1, ZP_TEAM_HUMAN)
	bloodyblade = zp_register_extra_item("Bloody Blade for 1 Round", 1, ZP_TEAM_HUMAN)
	paladin = zp_register_extra_item("Magazine", 1, ZP_TEAM_HUMAN)
	dk = zp_register_extra_item("Magasine", 1, ZP_TEAM_HUMAN)
	cannon = zp_register_extra_item("Maagazine", 1, ZP_TEAM_HUMAN)
	jumlah_paladin = 0
	jumlah_dk = 0
	jumlah_cannon = 0
}

public plugin_natives()
{
	register_native("refill2", "native_refill2", 1)
	register_native("refill", "native_refill", 1)
	register_native("codebox1", "native_codebox1", 1)
	register_native("jumlah_paladin", "native_jumlah_paladin", 1)
	register_native("codebox2", "native_codebox2", 1)
	register_native("jumlah_dk", "native_jumlah_dk", 1)
	register_native("codebox3", "native_codebox3", 1)
	register_native("jumlah_cannon", "native_jumlah_cannon", 1)
}

public native_refill(id)
{
	refill(id)
}

public native_refill2(id)
{
	refill2(id)
}

public native_codebox1(id)
{
	return codebox1[id];
}

public native_codebox2(id)
{
	return codebox2[id];
}

public native_codebox3(id)
{
	return codebox3[id];
}

public native_jumlah_paladin()
{
	return jumlah_paladin;
}

public native_jumlah_dk()
{
	return jumlah_dk;
}

public native_jumlah_cannon()
{
	return jumlah_cannon;
}

public client_connect(id)
{
	codebox1[id] = 0
	codebox2[id] = 0
	codebox3[id] = 0
}

public zp_extra_item_selected(id, itemid)
{	
	if(itemid == refill_ammo) refill(id)
	if(itemid == bloodyblade) give_bb(id)
	if(itemid == sprint) give_sprint(id)
	if(itemid == uang)
	{
		zp_cs_set_user_money(id, zp_cs_get_user_money(id) + 4000)
		refill(id)
	}
	if(itemid == paladin)
	{
		if(!revo_get_user_hero(id) && jumlah_paladin <= 0)
		{
			if(!codebox1[id])
			{
				get_buffak(id)
				set_task(0.1, "set", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_paladin ++
			}
			else refill(id)
		}
		else if(revo_get_user_hero(id) && jumlah_paladin <= 0)
		{
			if(!codebox1[id])
			{
				set_task(0.1, "set", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_paladin ++
			}
			else refill(id)
		}

		else
		{
			refill(id)
			jumlah_paladin ++
		}
		
	}
	
	if(itemid == dk)
	{
		if(!revo_get_user_hero(id) && jumlah_dk <= 0)
		{
			if(!codebox2[id])
			{
				get_buffm4(id)
				set_task(0.1, "set2", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_dk ++
			}
			else refill(id)
		}
		else if(revo_get_user_hero(id) && jumlah_dk <= 0)
		{
			if(!codebox2[id])
			{
				set_task(0.1, "set2", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_dk ++
			}
			else refill(id)
		}
		else
		{
			refill(id)
			jumlah_dk ++
		}
		
	}
	if(itemid == cannon)
	{
		if(!revo_get_user_hero(id) && jumlah_cannon <= 0)
		{
			if(!codebox3[id])
			{
				get_dragoncannon(id)
				set_task(0.1, "set3", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_cannon ++
			}
			else refill(id)
		}
		else if(revo_get_user_hero(id) && jumlah_cannon <= 0)
		{
			if(!codebox3[id])
			{
				set_task(0.1, "set3", id)
				client_cmd( id, "spk sound/perm1.wav")
				jumlah_cannon ++
			}
			else refill(id)
		}
		else
		{
			refill(id)
			jumlah_cannon ++
		}
		
	}	
}

public set(id) codebox1[id] = 1
public set2(id) codebox2[id] = 1
public set3(id) codebox3[id] = 1

public refill(id)
{
	new weapons[32], num, i, idwpn, ammo
	num = 0
	get_user_weapons(id, weapons, num)

	for (i = 0; i < num; i++)
	{
		idwpn = weapons[i]
		ammo = get_ammo_buywpn(idwpn)
		if (ammo>2)
		{
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			refill_dragoncannon(id)
			Refill_Thunderbolt(id)
			refill_speargun(id)
			refill_janus1(id)
			cs_set_user_bpammo(id, idwpn, ammo)
		}
	}
}

public refill2(id)
{
	new weapons[32], num, i, idwpn, ammo
	num = 0
	get_user_weapons(id, weapons, num)

	for (i = 0; i < num; i++)
	{
		idwpn = weapons[i]
		ammo = get_ammo_buywpn2(idwpn)
		if (ammo>2)
		{
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			show_hud_ammo(id, idwpn)
			refill_dragoncannon(id)
			Refill_Thunderbolt(id)
			refill_speargun(id)
			refill_janus1(id)
			cs_set_user_bpammo(id, idwpn, ammo)
		}
	}
}

get_ammo_buywpn(wpn)
{
	new ammo = 1
	if (wpn == CSW_USP || wpn == CSW_GLOCK18)
	{
		ammo = 200
	}
	else if (wpn == CSW_FIVESEVEN)
	{
		ammo = 5
	}
	else if (wpn == CSW_P228)
	{
		ammo = 60
	}
	else if (wpn == CSW_ELITE)
	{
		ammo = 200
	}
	else if (wpn == CSW_DEAGLE)
	{
		ammo = 200
	}
	else if (wpn == CSW_M3 || wpn == CSW_XM1014)
	{
		ammo = 64
	}
	else if (wpn == CSW_MAC10 || wpn == CSW_MP5NAVY || wpn == CSW_TMP)
	{
		ammo = 200
	}
	else if (wpn == CSW_UMP45)
	{
		ammo = 20
	}
	else if (wpn == CSW_P90)
	{
		ammo = 200
	}
	else if (wpn == CSW_AUG || wpn == CSW_FAMAS || wpn == CSW_GALIL || wpn == CSW_M4A1 || wpn == CSW_SG552 || wpn == CSW_AK47 || wpn == CSW_SCOUT || wpn == CSW_SG550)
	{
		ammo = 200
	}
	else if (wpn == CSW_G3SG1)
	{
		ammo = 240
	}
	else if (wpn == CSW_GALIL)
	{
		ammo = 200
	}
	else if (wpn == CSW_M249)
	{
		ammo = 200
	}
	else if (wpn == CSW_AWP)
	{
		ammo = 25
	}
	else if (wpn == CSW_HEGRENADE || wpn == CSW_SMOKEGRENADE || wpn == CSW_FLASHBANG)
	{
		ammo = 1
	}
	return ammo;
}

get_ammo_buywpn2(wpn)
{
	new ammo = 1
	if (wpn == CSW_USP || wpn == CSW_GLOCK18)
	{
		ammo = 300
	}
	else if (wpn == CSW_FIVESEVEN)
	{
		ammo = 5
	}
	else if (wpn == CSW_P228)
	{
		ammo = 250
	}
	else if (wpn == CSW_ELITE)
	{
		ammo = 300
	}
	else if (wpn == CSW_DEAGLE)
	{
		ammo = 250
	}
	else if (wpn == CSW_XM1014)
	{
		ammo = 80
	}
	else if (wpn == CSW_M3)
	{
		ammo = 120
	}
	else if (wpn == CSW_MAC10 || wpn == CSW_MP5NAVY || wpn == CSW_TMP)
	{
		ammo = 300
	}
	else if (wpn == CSW_UMP45)
	{
		ammo = 25
	}
	else if (wpn == CSW_P90)
	{
		ammo = 250
	}
	else if (wpn == CSW_AUG || wpn == CSW_FAMAS || wpn == CSW_GALIL || wpn == CSW_M4A1 || wpn == CSW_SG552 || wpn == CSW_AK47 || wpn == CSW_SCOUT || wpn == CSW_SG550)
	{
		ammo = 300
	}
	else if (wpn == CSW_G3SG1)
	{
		ammo = 250
	}
	else if (wpn == CSW_M249)
	{
		ammo = 250
	}
	else if (wpn == CSW_AWP)
	{
		ammo = 35
	}

	return ammo;
}

show_hud_ammo(id, weapon)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
	write_byte(AMMOID[weapon]) // ammo id
	write_byte(15) // ammo amount
	message_end()
	
	PlayEmitSound(id, CHAN_ITEM, sound_buyammo)
}

PlayEmitSound(id, type, const sound[])
{
	emit_sound(id, type, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
