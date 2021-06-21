#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <fun>

// ZP NATIVE (Required!!)
#include <zombieplague>

#define PLUGIN	"[CSO] LILITH ZOMBIE (Z-NOID) || ZP CLASS"
#define VERSION	"1.1 BETA"
#define AUTHOR	"Asep Khairul Anam || Facebook.com/asepdwa11"

/*
*********************************************
** The Plugins Is Made By Asep KhairulAnam **
*********************************************
*************** ZOMBIE-MOD.RU ***************
*********************************************
Changelog 1.0
- First Release
Changelog 1.1
- Added Skill Fake Health
- Added New Effect The Teleport
- Fixed Some Bug And Optimization Code
*********************************************
Request Plugins ?? Chat Me :) Via Facebook ..
Sorry For My Bad Coding -_- zzzzzzz..........
*/

// Teleport Mark
#define TELEPORT_MARK_MODEL	"models/zombie_plague/teleport_zombie_mark.mdl"
#define TELEPORT_MARK_CLASSNAME	"lilith_mark_teleport"

// Buff Sprites
#define BUFFSPR_MODEL		"sprites/zombie_plague/zb_skill_hpbuff.spr"
#define BUFFSPR_CLASSNAME	"buffspr_skill"
#define BUFFSPR_SCALE		1.0
#define BUFFSPR_ORIGIN_X	0.0
#define BUFFSPR_ORIGIN_Y	0.0
#define BUFFSPR_ORIGIN_Z	20.0

// Teleport Portal
#define TELEPORT_PORTAL_MODEL		"sprites/zombie_plague/ef_teleportzombie.spr"
#define TELEPORT_PORTAL_EXPLODE_SPR	"sprites/zombie_plague/ef_teleportzombie_exp.spr"
#define TELEPORT_PORTAL_CLASSNAME	"lilith_portal_teleport"

// Teleport Origin
#define TELEPORT_X 25.0
#define TELEPORT_Z 15.0

// Zombie Configuration (String)
#define ZOMBIE_NAME			"Lilith Zombie (Z-NOID)"
#define ZOMBIE_INFO			"Teleport, Fake Health || SKILL"
#define ZOMBIE_MODEL			"lilith_zombie"
#define ZOMBIE_CLAW_MDL			"v_knife_lilith.mdl"
#define ZOMBIE_BOMB_MDL			"models/zombie_plague/v_bomb_lilith_merah_fix.mdl"

// Zombie Configuration (Int)
#define ZOMBIE_HEALTH		3000
#define ZOMBIE_SPEED		245
#define ZOMBIE_GRAVITY		80
#define ZOMBIE_KNOCKBACK	200
#define ZOMBIE_FAKE_HEALTH	2000
#define DELAY_SKILL_1		30	// Teleport And Create Portal
#define DELAY_SKILL_2		40	// Fake Health

// Task (Macros)
#define TASK_SKILL_1	10221
#define TASK_SKILL_2	10223
#define	TASK_DELAY	10222

// For Auto Unstuck (Vector) Velocity
new const Float:UnstuckVector[][] =
{
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0},
	{0.0, 0.0, 6.0}, {0.0, 0.0, -6.0}, {0.0, 6.0, 0.0}, {0.0, -6.0, 0.0}, {6.0, 0.0, 0.0}, {-6.0, 0.0, 0.0}, {-6.0, 6.0, 6.0}, {6.0, 6.0, 6.0}, {6.0, -6.0, 6.0}, {6.0, 6.0, -6.0}, {-6.0, -6.0, 6.0}, {6.0, -6.0, -6.0}, {-6.0, 6.0, -6.0}, {-6.0, -6.0, -6.0},
	{0.0, 0.0, 7.0}, {0.0, 0.0, -7.0}, {0.0, 7.0, 0.0}, {0.0, -7.0, 0.0}, {7.0, 0.0, 0.0}, {-7.0, 0.0, 0.0}, {-7.0, 7.0, 7.0}, {7.0, 7.0, 7.0}, {7.0, -7.0, 7.0}, {7.0, 7.0, -7.0}, {-7.0, -7.0, 7.0}, {7.0, -7.0, -7.0}, {-7.0, 7.0, -7.0}, {-7.0, -7.0, -7.0},
	{0.0, 0.0, 8.0}, {0.0, 0.0, -8.0}, {0.0, 8.0, 0.0}, {0.0, -8.0, 0.0}, {8.0, 0.0, 0.0}, {-8.0, 0.0, 0.0}, {-8.0, 8.0, 8.0}, {8.0, 8.0, 8.0}, {8.0, -8.0, 8.0}, {8.0, 8.0, -8.0}, {-8.0, -8.0, 8.0}, {8.0, -8.0, -8.0}, {-8.0, 8.0, -8.0}, {-8.0, -8.0, -8.0},
	{0.0, 0.0, 9.0}, {0.0, 0.0, -9.0}, {0.0, 9.0, 0.0}, {0.0, -9.0, 0.0}, {9.0, 0.0, 0.0}, {-9.0, 0.0, 0.0}, {-9.0, 9.0, 9.0}, {9.0, 9.0, 9.0}, {9.0, -9.0, 9.0}, {9.0, 9.0, -9.0}, {-9.0, -9.0, 9.0}, {9.0, -9.0, -9.0}, {-9.0, 9.0, -9.0}, {-9.0, -9.0, -9.0},
	{0.0, 0.0, 10.0}, {0.0, 0.0, -10.0}, {0.0, 10.0, 0.0}, {0.0, -10.0, 0.0}, {10.0, 0.0, 0.0}, {-10.0, 0.0, 0.0}, {-10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}, {10.0, -10.0, 10.0}, {10.0, 10.0, -10.0}, {-10.0, -10.0, 10.0}, {10.0, -10.0, -10.0}, {-10.0, 10.0, -10.0}, {-10.0, -10.0, -10.0},
	{0.0, 0.0, 11.0}, {0.0, 0.0, -11.0}, {0.0, 11.0, 0.0}, {0.0, -11.0, 0.0}, {11.0, 0.0, 0.0}, {-11.0, 0.0, 0.0}, {-11.0, 11.0, 11.0}, {11.0, 11.0, 11.0}, {11.0, -11.0, 11.0}, {11.0, 11.0, -11.0}, {-11.0, -11.0, 11.0}, {11.0, -11.0, -11.0}, {-11.0, 11.0, -11.0}, {-11.0, -11.0, -11.0},
	{0.0, 0.0, 12.0}, {0.0, 0.0, -12.0}, {0.0, 12.0, 0.0}, {0.0, -12.0, 0.0}, {12.0, 0.0, 0.0}, {-12.0, 0.0, 0.0}, {-12.0, 12.0, 12.0}, {12.0, 12.0, 12.0}, {12.0, -12.0, 12.0}, {12.0, 12.0, -12.0}, {-12.0, -12.0, 12.0}, {12.0, -12.0, -12.0}, {-12.0, 12.0, -12.0}, {-12.0, -12.0, -12.0},
	{0.0, 0.0, 13.0}, {0.0, 0.0, -13.0}, {0.0, 13.0, 0.0}, {0.0, -13.0, 0.0}, {13.0, 0.0, 0.0}, {-13.0, 0.0, 0.0}, {-13.0, 13.0, 13.0}, {13.0, 13.0, 13.0}, {13.0, -13.0, 13.0}, {13.0, 13.0, -13.0}, {-13.0, -13.0, 13.0}, {13.0, -13.0, -13.0}, {-13.0, 13.0, -13.0}, {-13.0, -13.0, -13.0},
	{0.0, 0.0, 14.0}, {0.0, 0.0, -14.0}, {0.0, 14.0, 0.0}, {0.0, -14.0, 0.0}, {14.0, 0.0, 0.0}, {-14.0, 0.0, 0.0}, {-14.0, 14.0, 14.0}, {14.0, 14.0, 14.0}, {14.0, -14.0, 14.0}, {14.0, 14.0, -14.0}, {-14.0, -14.0, 14.0}, {14.0, -14.0, -14.0}, {-14.0, 14.0, -14.0}, {-14.0, -14.0, -14.0},
	{0.0, 0.0, 15.0}, {0.0, 0.0, -15.0}, {0.0, 15.0, 0.0}, {0.0, -15.0, 0.0}, {15.0, 0.0, 0.0}, {-15.0, 0.0, 0.0}, {-15.0, 15.0, 15.0}, {15.0, 15.0, 15.0}, {15.0, -15.0, 15.0}, {15.0, 15.0, -15.0}, {-15.0, -15.0, 15.0}, {15.0, -15.0, -15.0}, {-15.0, 15.0, -15.0}, {-15.0, -15.0, -15.0},
	{0.0, 0.0, 16.0}, {0.0, 0.0, -16.0}, {0.0, 16.0, 0.0}, {0.0, -16.0, 0.0}, {16.0, 0.0, 0.0}, {-16.0, 0.0, 0.0}, {-16.0, 16.0, 16.0}, {16.0, 16.0, 16.0}, {16.0, -16.0, 16.0}, {16.0, 16.0, -16.0}, {-16.0, -16.0, 16.0}, {16.0, -16.0, -16.0}, {-16.0, 16.0, -16.0}, {-16.0, -16.0, -16.0},
	{0.0, 0.0, 17.0}, {0.0, 0.0, -17.0}, {0.0, 17.0, 0.0}, {0.0, -17.0, 0.0}, {17.0, 0.0, 0.0}, {-17.0, 0.0, 0.0}, {-17.0, 17.0, 17.0}, {17.0, 17.0, 17.0}, {17.0, -17.0, 17.0}, {17.0, 17.0, -17.0}, {-17.0, -17.0, 17.0}, {17.0, -17.0, -17.0}, {-17.0, 17.0, -17.0}, {-17.0, -17.0, -17.0},
	{0.0, 0.0, 18.0}, {0.0, 0.0, -18.0}, {0.0, 18.0, 0.0}, {0.0, -18.0, 0.0}, {18.0, 0.0, 0.0}, {-18.0, 0.0, 0.0}, {-18.0, 18.0, 18.0}, {18.0, 18.0, 18.0}, {18.0, -18.0, 18.0}, {18.0, 18.0, -18.0}, {-18.0, -18.0, 18.0}, {18.0, -18.0, -18.0}, {-18.0, 18.0, -18.0}, {-18.0, -18.0, -18.0},
	{0.0, 0.0, 19.0}, {0.0, 0.0, -19.0}, {0.0, 19.0, 0.0}, {0.0, -19.0, 0.0}, {19.0, 0.0, 0.0}, {-19.0, 0.0, 0.0}, {-19.0, 19.0, 19.0}, {19.0, 19.0, 19.0}, {19.0, -19.0, 19.0}, {19.0, 19.0, -19.0}, {-19.0, -19.0, 19.0}, {19.0, -19.0, -19.0}, {-19.0, 19.0, -19.0}, {-19.0, -19.0, -19.0},
	{0.0, 0.0, 20.0}, {0.0, 0.0, -20.0}, {0.0, 20.0, 0.0}, {0.0, -20.0, 0.0}, {20.0, 0.0, 0.0}, {-20.0, 0.0, 0.0}, {-20.0, 20.0, 20.0}, {20.0, 20.0, 20.0}, {20.0, -20.0, 20.0}, {20.0, 20.0, -20.0}, {-20.0, -20.0, 20.0}, {20.0, -20.0, -20.0}, {-20.0, 20.0, -20.0}, {-20.0, -20.0, -20.0},
	{0.0, 0.0, 21.0}, {0.0, 0.0, -21.0}, {0.0, 21.0, 0.0}, {0.0, -21.0, 0.0}, {21.0, 0.0, 0.0}, {-21.0, 0.0, 0.0}, {-21.0, 21.0, 21.0}, {21.0, 21.0, 21.0}, {21.0, -21.0, 21.0}, {21.0, 21.0, -21.0}, {-21.0, -21.0, 21.0}, {21.0, -21.0, -21.0}, {-21.0, 21.0, -21.0}, {-21.0, -21.0, -21.0},
	{0.0, 0.0, 22.0}, {0.0, 0.0, -22.0}, {0.0, 22.0, 0.0}, {0.0, -22.0, 0.0}, {22.0, 0.0, 0.0}, {-22.0, 0.0, 0.0}, {-22.0, 22.0, 22.0}, {22.0, 22.0, 22.0}, {22.0, -22.0, 22.0}, {22.0, 22.0, -22.0}, {-22.0, -22.0, 22.0}, {22.0, -22.0, -22.0}, {-22.0, 22.0, -22.0}, {-22.0, -22.0, -22.0},
	{0.0, 0.0, 23.0}, {0.0, 0.0, -23.0}, {0.0, 23.0, 0.0}, {0.0, -23.0, 0.0}, {23.0, 0.0, 0.0}, {-23.0, 0.0, 0.0}, {-23.0, 23.0, 23.0}, {23.0, 23.0, 23.0}, {23.0, -23.0, 23.0}, {23.0, 23.0, -23.0}, {-23.0, -23.0, 23.0}, {23.0, -23.0, -23.0}, {-23.0, 23.0, -23.0}, {-23.0, -23.0, -23.0},
	{0.0, 0.0, 24.0}, {0.0, 0.0, -24.0}, {0.0, 24.0, 0.0}, {0.0, -24.0, 0.0}, {24.0, 0.0, 0.0}, {-24.0, 0.0, 0.0}, {-24.0, 24.0, 24.0}, {24.0, 24.0, 24.0}, {24.0, -24.0, 24.0}, {24.0, 24.0, -24.0}, {-24.0, -24.0, 24.0}, {24.0, -24.0, -24.0}, {-24.0, 24.0, -24.0}, {-24.0, -24.0, -24.0},
	{0.0, 0.0, 25.0}, {0.0, 0.0, -25.0}, {0.0, 25.0, 0.0}, {0.0, -25.0, 0.0}, {25.0, 0.0, 0.0}, {-25.0, 0.0, 0.0}, {-25.0, 25.0, 25.0}, {25.0, 25.0, 25.0}, {25.0, -25.0, 25.0}, {25.0, 25.0, -25.0}, {-25.0, -25.0, 25.0}, {25.0, -25.0, -25.0}, {-25.0, 25.0, -25.0}, {-25.0, -25.0, -25.0},
	{0.0, 0.0, 26.0}, {0.0, 0.0, -26.0}, {0.0, 26.0, 0.0}, {0.0, -26.0, 0.0}, {26.0, 0.0, 0.0}, {-26.0, 0.0, 0.0}, {-26.0, 26.0, 26.0}, {26.0, 26.0, 26.0}, {26.0, -26.0, 26.0}, {26.0, 26.0, -26.0}, {-26.0, -26.0, 26.0}, {26.0, -26.0, -26.0}, {-26.0, 26.0, -26.0}, {-26.0, -26.0, -26.0},
	{0.0, 0.0, 27.0}, {0.0, 0.0, -27.0}, {0.0, 27.0, 0.0}, {0.0, -27.0, 0.0}, {27.0, 0.0, 0.0}, {-27.0, 0.0, 0.0}, {-27.0, 27.0, 27.0}, {27.0, 27.0, 27.0}, {27.0, -27.0, 27.0}, {27.0, 27.0, -27.0}, {-27.0, -27.0, 27.0}, {27.0, -27.0, -27.0}, {-27.0, 27.0, -27.0}, {-27.0, -27.0, -27.0},
	{0.0, 0.0, 28.0}, {0.0, 0.0, -28.0}, {0.0, 28.0, 0.0}, {0.0, -28.0, 0.0}, {28.0, 0.0, 0.0}, {-28.0, 0.0, 0.0}, {-28.0, 28.0, 28.0}, {28.0, 28.0, 28.0}, {28.0, -28.0, 28.0}, {28.0, 28.0, -28.0}, {-28.0, -28.0, 28.0}, {28.0, -28.0, -28.0}, {-28.0, 28.0, -28.0}, {-28.0, -28.0, -28.0},
	{0.0, 0.0, 29.0}, {0.0, 0.0, -29.0}, {0.0, 29.0, 0.0}, {0.0, -29.0, 0.0}, {29.0, 0.0, 0.0}, {-29.0, 0.0, 0.0}, {-29.0, 29.0, 29.0}, {29.0, 29.0, 29.0}, {29.0, -29.0, 29.0}, {29.0, 29.0, -29.0}, {-29.0, -29.0, 29.0}, {29.0, -29.0, -29.0}, {-29.0, 29.0, -29.0}, {-29.0, -29.0, -29.0},
	{0.0, 0.0, 30.0}, {0.0, 0.0, -30.0}, {0.0, 30.0, 0.0}, {0.0, -30.0, 0.0}, {30.0, 0.0, 0.0}, {-30.0, 0.0, 0.0}, {-30.0, 30.0, 30.0}, {30.0, 30.0, 30.0}, {30.0, -30.0, 30.0}, {30.0, 30.0, -30.0}, {-30.0, -30.0, 30.0}, {30.0, -30.0, -30.0}, {-30.0, 30.0, -30.0}, {-30.0, -30.0, -30.0},
	{0.0, 0.0, 31.0}, {0.0, 0.0, -31.0}, {0.0, 31.0, 0.0}, {0.0, -31.0, 0.0}, {31.0, 0.0, 0.0}, {-31.0, 0.0, 0.0}, {-31.0, 31.0, 31.0}, {31.0, 31.0, 31.0}, {31.0, -31.0, 31.0}, {31.0, 31.0, -31.0}, {-31.0, -31.0, 31.0}, {31.0, -31.0, -31.0}, {-31.0, 31.0, -31.0}, {-31.0, -31.0, -31.0},
	{0.0, 0.0, 32.0}, {0.0, 0.0, -32.0}, {0.0, 32.0, 0.0}, {0.0, -32.0, 0.0}, {32.0, 0.0, 0.0}, {-32.0, 0.0, 0.0}, {-32.0, 32.0, 32.0}, {32.0, 32.0, 32.0}, {32.0, -32.0, 32.0}, {32.0, 32.0, -32.0}, {-32.0, -32.0, 32.0}, {32.0, -32.0, -32.0}, {-32.0, 32.0, -32.0}, {-32.0, -32.0, -32.0},
	{0.0, 0.0, 33.0}, {0.0, 0.0, -33.0}, {0.0, 33.0, 0.0}, {0.0, -33.0, 0.0}, {33.0, 0.0, 0.0}, {-33.0, 0.0, 0.0}, {-33.0, 33.0, 33.0}, {33.0, 33.0, 33.0}, {33.0, -33.0, 33.0}, {33.0, 33.0, -33.0}, {-33.0, -33.0, 33.0}, {33.0, -33.0, -33.0}, {-33.0, 33.0, -33.0}, {-33.0, -33.0, -33.0},
	{0.0, 0.0, 34.0}, {0.0, 0.0, -34.0}, {0.0, 34.0, 0.0}, {0.0, -34.0, 0.0}, {34.0, 0.0, 0.0}, {-34.0, 0.0, 0.0}, {-34.0, 34.0, 34.0}, {34.0, 34.0, 34.0}, {34.0, -34.0, 34.0}, {34.0, 34.0, -34.0}, {-34.0, -34.0, 34.0}, {34.0, -34.0, -34.0}, {-34.0, 34.0, -34.0}, {-34.0, -34.0, -34.0},
	{0.0, 0.0, 35.0}, {0.0, 0.0, -35.0}, {0.0, 35.0, 0.0}, {0.0, -35.0, 0.0}, {35.0, 0.0, 0.0}, {-35.0, 0.0, 0.0}, {-35.0, 35.0, 35.0}, {35.0, 35.0, 35.0}, {35.0, -35.0, 35.0}, {35.0, 35.0, -35.0}, {-35.0, -35.0, 35.0}, {35.0, -35.0, -35.0}, {-35.0, 35.0, -35.0}, {-35.0, -35.0, -35.0},
	{0.0, 0.0, 36.0}, {0.0, 0.0, -36.0}, {0.0, 36.0, 0.0}, {0.0, -36.0, 0.0}, {36.0, 0.0, 0.0}, {-36.0, 0.0, 0.0}, {-36.0, 36.0, 36.0}, {36.0, 36.0, 36.0}, {36.0, -36.0, 36.0}, {36.0, 36.0, -36.0}, {-36.0, -36.0, 36.0}, {36.0, -36.0, -36.0}, {-36.0, 36.0, -36.0}, {-36.0, -36.0, -36.0},
	{0.0, 0.0, 37.0}, {0.0, 0.0, -37.0}, {0.0, 37.0, 0.0}, {0.0, -37.0, 0.0}, {37.0, 0.0, 0.0}, {-37.0, 0.0, 0.0}, {-37.0, 37.0, 37.0}, {37.0, 37.0, 37.0}, {37.0, -37.0, 37.0}, {37.0, 37.0, -37.0}, {-37.0, -37.0, 37.0}, {37.0, -37.0, -37.0}, {-37.0, 37.0, -37.0}, {-37.0, -37.0, -37.0},
	{0.0, 0.0, 38.0}, {0.0, 0.0, -38.0}, {0.0, 38.0, 0.0}, {0.0, -38.0, 0.0}, {38.0, 0.0, 0.0}, {-38.0, 0.0, 0.0}, {-38.0, 38.0, 38.0}, {38.0, 38.0, 38.0}, {38.0, -38.0, 38.0}, {38.0, 38.0, -38.0}, {-38.0, -38.0, 38.0}, {38.0, -38.0, -38.0}, {-38.0, 38.0, -38.0}, {-38.0, -38.0, -38.0},
	{0.0, 0.0, 39.0}, {0.0, 0.0, -39.0}, {0.0, 39.0, 0.0}, {0.0, -39.0, 0.0}, {39.0, 0.0, 0.0}, {-39.0, 0.0, 0.0}, {-39.0, 39.0, 39.0}, {39.0, 39.0, 39.0}, {39.0, -39.0, 39.0}, {39.0, 39.0, -39.0}, {-39.0, -39.0, 39.0}, {39.0, -39.0, -39.0}, {-39.0, 39.0, -39.0}, {-39.0, -39.0, -39.0},
	{0.0, 0.0, 40.0}, {0.0, 0.0, -40.0}, {0.0, 40.0, 0.0}, {0.0, -40.0, 0.0}, {40.0, 0.0, 0.0}, {-40.0, 0.0, 0.0}, {-40.0, 40.0, 40.0}, {40.0, 40.0, 40.0}, {40.0, -40.0, 40.0}, {40.0, 40.0, -40.0}, {-40.0, -40.0, 40.0}, {40.0, -40.0, -40.0}, {-40.0, 40.0, -40.0}, {-40.0, -40.0, -40.0}
}

// Macros Only
enum _:LILITH_SKILL
{
	SKILL_READY = 0,
	SKILL_USE,
	SKILL_DELAY,
	SKILL_TELEPORT_READY,
	SKILL_TELEPORT_USE
}

enum _:LILITH_ANIMATION
{
	V_ANIM_SKILL_1	= 2,
	V_ANIM_SKILL_2	= 8,
	P_ANIM_SKILL_1	= 152,
	P_ANIM_SKILL_2	= 153
}

enum _:LILITH_SOUND
{
	SKILL_1 = 0,
	SKILL_2_IN,
	SKILL_2_OUT,
	PAIN_HURT,
	PAIN_GATE,
	PAIN_DEATH,
	PAIN_SKILL_3,
	PAIN_HEAL
}

enum _:LILITH_ENT
{
	ENT_MARK = 0,
	ENT_PORTAL1,
	ENT_PORTAL2,
	ENT_HEADSPR
}

// Sounds
new const LilithSound[][] = 
{
	"zombie_plague/lilith_teleport_skill1.wav",
	"zombie_plague/lilith_teleport_skill2_in.wav",
	"zombie_plague/lilith_teleport_skill2_out.wav",
	"zombie_plague/lilith_pain_hurt.wav",
	"zombie_plague/lilith_pain_gate.wav",
	"zombie_plague/lilith_pain_death.wav",
	"zombie_plague/lilith_heal_skill3.wav",
	"zombie_plague/buff_heal.wav"
}

// Index Vars
new g_teleport_ent[33][4]
new class_lilith[33]
new index_lilith
new g_Explode
new g_HamBot
new g_LilithHud

// Skill Vars
new g_skill1[33]
new g_skill2[33]
new g_skill2_fake_health[33]
new g_maxplayers, g_msgSayText

// Hud Vars
new sync_hud[2]
new Float:g_speed_hud[33]

public plugin_init()
{
	// Register Plugins .....
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Forward Event
	register_event("DeathMsg", "Event_Death", "a")
	register_event("CurWeapon","Event_CurWeapon","be","1=1")
	register_event("HLTV", "Event_RoundStart", "a", "1=0", "2=0")
	
	// Forward Log Event
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	
	// Forward Fakemeta
	register_forward(FM_CmdStart , "Forward_CmdStart")
	
	// Forward Ham
	RegisterHam(Ham_TakeDamage, "player", "Forward_TakeDamage")
	
	// Forward Think Entity
	register_think(TELEPORT_MARK_CLASSNAME, "Forward_Mark_Think")
	register_think(TELEPORT_PORTAL_CLASSNAME, "Forward_Portal_Think")
	register_think(BUFFSPR_CLASSNAME, "Forward_Buffspr_Think")
	
	// Forward Touch Entity
	register_touch(TELEPORT_MARK_CLASSNAME, "player", "Forward_Mark_Touch")
	
	// Create Sync Hud
	sync_hud[0] = CreateHudSyncObj(856)
	sync_hud[1] = CreateHudSyncObj(857)
	g_LilithHud = CreateHudSyncObj(2)
	g_msgSayText = get_user_msgid("SayText")
	g_maxplayers = get_maxplayers()
}

public plugin_precache()
{	
	// Sound Precache (Required)
	for(new i = 0; i < sizeof(LilithSound); i++)
		precache_sound(LilithSound[i])
	
	// Claw Precache
	new CLAW_MDL[101]
	formatex(CLAW_MDL, charsmax(CLAW_MDL), "models/zombie_plague/%s", ZOMBIE_CLAW_MDL)
	precache_model(CLAW_MDL)
	
	// Zombie Bomb Precache
	precache_model(ZOMBIE_BOMB_MDL)
	precache_viewmodel_sound(ZOMBIE_BOMB_MDL)
	
	// All SPR And Models Effect Precache
	precache_model(TELEPORT_MARK_MODEL)
	precache_model(TELEPORT_PORTAL_MODEL)
	precache_model(BUFFSPR_MODEL)
	
	// Fix Bug (If Your Server Unprecache This Sound)
	precache_sound("common/null.wav")
	
	new player_models[101]
	formatex(player_models, charsmax(player_models), "models/player/%s/%s.mdl", ZOMBIE_MODEL, ZOMBIE_MODEL)
	index_lilith = precache_model(player_models)
	g_Explode = precache_model(TELEPORT_PORTAL_EXPLODE_SPR)
}

// Bot Ham Fixed
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
	RegisterHamFromEntity(Ham_TakeDamage, id, "Forward_TakeDamage")
}

public plugin_natives()
{
	register_native("Give_Lilith", "Native_Give_Lilith", 1)
	register_native("lilith_reset_value", "Native_Lilith_Reset", 1)
}

public Native_Give_Lilith(id)
{
	Give_Lilith(id)
}

public Native_Lilith_Reset(id)
{
	lilith_reset_value(id)
}

public Give_Lilith(id)
{	
	lilith_reset_var_skill(id)
		
	class_lilith[id] = true
	//show_lilith_hud(id)
	
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	
	zp_override_user_model(id, ZOMBIE_MODEL)
	set_pdata_int(id, 491, index_lilith, 5)
	
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [E]^x01 to use Teleport")
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Press^x03 [R]^x01 to use Fake Health")
}

public zp_user_humanized_post(id) lilith_reset_value(id)
public Event_RoundEnd(id) lilith_reset_value(id)
public Event_RoundStart(id) lilith_reset_value(id)
public Event_Death()
{
	new id = read_data(2)
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !class_lilith[id])
		return
		
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, LilithSound[PAIN_DEATH], 1.0, ATTN_NORM, 0, PITCH_NORM)
	lilith_reset_value(id)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !class_lilith[id])
		return
	
	if(g_skill1[id] != SKILL_USE) set_user_maxspeed(id, float(ZOMBIE_SPEED))
	else if(g_skill2[id] != SKILL_USE) set_user_maxspeed(id, float(ZOMBIE_SPEED))
	switch(read_data(2))
	{
		case CSW_KNIFE:
		{
			new CLAW_MDL[101]
			formatex(CLAW_MDL, charsmax(CLAW_MDL), "models/zombie_plague/%s", ZOMBIE_CLAW_MDL)
			set_pev(id, pev_viewmodel2, CLAW_MDL)
			set_pev(id, pev_weaponmodel2, "")
		}
		case CSW_SMOKEGRENADE: set_pev(id, pev_viewmodel2, ZOMBIE_BOMB_MDL)
		case CSW_HEGRENADE: set_pev(id, pev_viewmodel2, ZOMBIE_BOMB_MDL)
		case CSW_FLASHBANG: set_pev(id, pev_viewmodel2, ZOMBIE_BOMB_MDL)
	}
	
}

public Forward_TakeDamage(victim, inflictor, attacker, Float:damage, dmgtype)
{
	if(!is_user_connected(attacker) || !is_user_connected(victim))
		return HAM_IGNORED
	if(!zp_get_user_zombie(victim) || zp_get_user_nemesis(victim) || !class_lilith[victim])
		return HAM_IGNORED
		
	engfunc(EngFunc_EmitSound, victim, CHAN_ITEM, LilithSound[PAIN_HURT], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	if(g_skill2[victim] == SKILL_USE)
	{
		if(g_skill2_fake_health[victim] > 0)
		{
			g_skill2_fake_health[victim] -= floatround(damage)
			g_speed_hud[victim] = 0.05
			
			ExecuteHam(Ham_TakeDamage, victim, attacker, attacker, 0.0, dmgtype)
		}
		else if(g_skill2_fake_health[victim] <= 0)
		{
			g_skill2[victim] = SKILL_DELAY
			g_skill2_fake_health[victim] = 0
			g_speed_hud[victim] = 1.0
			
			lilith_remove_entity(victim, ENT_HEADSPR)
			set_task(float(DELAY_SKILL_2), "action_skill2_delay", victim+TASK_DELAY)
		}
		
		return HAM_SUPERCEDE
	}
	
	return HAM_HANDLED
}

public show_lilith_hud(id)
{
	// Hud
	static Skill1[64], Skill2[64]
	
	// Skill 1
	if(g_skill1[id] == SKILL_READY) formatex(Skill1, 63, "[E] : Active Portal")
	else if (g_skill1[id] == SKILL_USE)  formatex(Skill1, 63, "[E] : Actived Portal")
	else if (g_skill1[id] == SKILL_TELEPORT_READY)  formatex(Skill1, 63, "[E] : Ready to Teleport")
	else if (g_skill1[id] == SKILL_TELEPORT_USE)  formatex(Skill1, 63, "[E] : Actived Teleport")
	else if (g_skill1[id] == SKILL_DELAY) formatex(Skill1, 63, "[E] : Skill Delay")
	
	// Skill 2
	if(g_skill2[id] == SKILL_READY) formatex(Skill2, 63, "[R] : Active Fake Health")
	else if(g_skill2[id] == SKILL_USE && g_skill2_fake_health[id] > 0) formatex(Skill2, 63, "[R] Fake Health: %i", g_skill2_fake_health[id])
	else if (g_skill2[id] == SKILL_DELAY) formatex(Skill2, 63, "[R] : Skill Delay")

	set_hudmessage(255, 0, 0, -1.0, -0.79, 0, 2.0, 2.0, 0.05, 1.0)
	ShowSyncHudMsg(id, g_LilithHud, "[Lilith]^n^n%s^n%s", Skill1, Skill2)
}

public Forward_CmdStart(id, UC_Handle, seed)
{
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !class_lilith[id])
		return
	
	static Float:CurrentTime, Float:g_hud_delay[33]
	CurrentTime = get_gametime()
	
	if(CurrentTime - g_speed_hud[id] > g_hud_delay[id])
	{
		show_lilith_hud(id)
		
		if(pev(id, pev_solid) == SOLID_NOT)
			set_pev(id, pev_solid, SOLID_BBOX)
		
		g_hud_delay[id] = CurrentTime
	}
	
	static PressedButton
	PressedButton = get_uc(UC_Handle, UC_Buttons)
	
	if(PressedButton & IN_RELOAD)
	{
		if(get_user_weapon(id) != CSW_KNIFE)
			return
		if(g_skill2[id] != SKILL_READY)
			return
		
		set_task(0.001, "action_skill_2", id+TASK_SKILL_2)
	}
	else if(PressedButton & IN_USE)
	{
		if(get_user_weapon(id) != CSW_KNIFE)
			return
		
		static Ent
		Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	
		if(!pev_valid(Ent))
			return
			
		if(g_skill1[id] == SKILL_READY)
		{
			if(pev(id, pev_flags) & FL_DUCKING)
			{
				client_print(id, print_center, "You Can't Create Teleport Portal If You Ducking !!")
				return
			}
			
			ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
			set_task(0.001, "action_create_teleport_mark", id+TASK_SKILL_1)
		}
		else if(g_skill1[id] == SKILL_TELEPORT_READY)
		{
			if(!pev_valid(g_teleport_ent[id][ENT_MARK]))
				return
			
			ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
			set_task(0.001, "action_teleport", id+TASK_SKILL_1)
		}
	}
	
	auto_unstuck(id)
}

public auto_unstuck(id)
{
	static Float:origin[3], Float:mins[3], hull, Float:vec[3], i
	
	pev(id, pev_origin, origin)
	hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
	
	if(!is_hull_vacant(origin, hull, id))
	{
		pev(id, pev_mins, mins)
		vec[2] = origin[2]
		
		for(i = 0; i < sizeof UnstuckVector; ++i)
		{
			vec[0] = origin[0] - mins[0] * UnstuckVector[i][0]
			vec[1] = origin[1] - mins[1] * UnstuckVector[i][1]
			vec[2] = origin[2] - mins[2] * UnstuckVector[i][2]
			
			if(is_hull_vacant(vec, hull, id))
			{
				engfunc(EngFunc_SetOrigin, id, vec)
				set_pev(id,pev_velocity,{0.0,0.0,0.0})
			
				i = sizeof UnstuckVector
			}
		}
	}
}

public action_teleport(id)
{
	id -= TASK_SKILL_1
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !class_lilith[id])
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(g_skill1[id] != SKILL_TELEPORT_READY)
		return
	
	g_skill1[id] = SKILL_TELEPORT_USE
	
	set_weapon_anim(id, V_ANIM_SKILL_2)
	set_pev(id, pev_sequence, P_ANIM_SKILL_2)
	set_pev(id, pev_framerate, 0.3)
		
	set_user_maxspeed(id, 0.1)
	set_user_gravity(id, 2.0)
	set_pdata_float(id, 83, 2.0, 5)
	
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_byte(20) // radius
	write_byte(200)    // r
	write_byte(200)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(1)  // decay rate in 10's
	message_end() 
	
	new Float:OriginPlayer[3]
	get_position(id, 5.0, 0.0, 0.0, OriginPlayer)
	create_teleport_portal(g_teleport_ent[id][ENT_PORTAL1], id, SKILL_2_IN, OriginPlayer)
	
	if(pev_valid(g_teleport_ent[id][ENT_MARK]))
	{
		static Float:OriginTeleport[3]
		pev(g_teleport_ent[id][ENT_MARK], pev_origin, OriginTeleport)
		OriginTeleport[2] += 50.0
		create_teleport_portal(g_teleport_ent[id][ENT_PORTAL2], id, SKILL_2_OUT, OriginTeleport)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DLIGHT)
		engfunc(EngFunc_WriteCoord, OriginTeleport[0])
		engfunc(EngFunc_WriteCoord, OriginTeleport[1])
		engfunc(EngFunc_WriteCoord, OriginTeleport[2])
		write_byte(20) // radius
		write_byte(200)    // r
		write_byte(200)  // g
		write_byte(255)   // b
		write_byte(40) // life in 10's
		write_byte(1)  // decay rate in 10's
		message_end() 
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		engfunc(EngFunc_WriteCoord, OriginTeleport[0])
		engfunc(EngFunc_WriteCoord, OriginTeleport[1])
		engfunc(EngFunc_WriteCoord, OriginTeleport[2])
		write_short(g_Explode) // Sprite index
		write_byte(8) // Scale
		write_byte(255) // Brightness
		message_end()
	}
	
	set_task(2.0, "do_teleport", id+TASK_SKILL_1)
}

public do_teleport(id)
{
	id -= TASK_SKILL_1
	
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !class_lilith[id])
	{
		remove_task(id+TASK_SKILL_1)
		return
	}
	
	if(!pev_valid(g_teleport_ent[id][ENT_MARK]))
		return
	if(g_skill1[id] != SKILL_TELEPORT_USE)
		return
	
	static Float:OriginTeleport[3]
	pev(g_teleport_ent[id][ENT_MARK], pev_origin, OriginTeleport)
	OriginTeleport[2] += 50.0
	set_pev(id, pev_origin, OriginTeleport)
	engfunc(EngFunc_EmitSound, g_teleport_ent[id][ENT_MARK], CHAN_ITEM, "common/null.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	remove_entity(g_teleport_ent[id][ENT_MARK])
	g_teleport_ent[id][ENT_MARK] = 0
	
	set_user_maxspeed(id, float(ZOMBIE_SPEED))
	set_user_gravity(id, float(ZOMBIE_GRAVITY)/100.0)
	set_pev(id, pev_framerate, 1.0)
	
	new Float:OriginPlayer[3]
	get_position(id, 5.0, 0.0, 0.0, OriginPlayer)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, OriginPlayer[0])
	engfunc(EngFunc_WriteCoord, OriginPlayer[1])
	engfunc(EngFunc_WriteCoord, OriginPlayer[2])
	write_short(g_Explode) // Sprite index
	write_byte(8) // Scale
	write_byte(255) // Brightness
	message_end()
		
	if(pev_valid(g_teleport_ent[id][ENT_MARK]))
	{
		new Float:TeleportOrigin[3]
		pev(g_teleport_ent[id][ENT_MARK], pev_origin, TeleportOrigin)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		engfunc(EngFunc_WriteCoord, TeleportOrigin[0])
		engfunc(EngFunc_WriteCoord, TeleportOrigin[1])
		engfunc(EngFunc_WriteCoord, TeleportOrigin[2])
		write_short(g_Explode) // Sprite index
		write_byte(8) // Scale
		write_byte(255) // Brightness
		message_end()
	}
	
	g_skill1[id] = SKILL_DELAY
	set_task(float(DELAY_SKILL_1), "action_skill_delay", id+TASK_DELAY)
}

public action_skill_delay(id)
{
	id -= TASK_DELAY
	
	if(g_skill1[id] != SKILL_DELAY)
		return
	
	g_skill1[id] = SKILL_READY
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Teleport^x01 is ready.")
}

public action_skill2_delay(id)
{
	id -= TASK_DELAY
	
	if(g_skill2[id] != SKILL_DELAY)
		return
		
	g_skill2[id] = SKILL_READY
	zp_colored_print(id, "^x04[Zombie: The Hero]^x01 Your skill^x04 Fake Health^x01 is ready.")
}

public action_create_teleport_mark(id)
{
	id -= TASK_SKILL_1
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !class_lilith[id])
		return
	if(g_skill1[id] != SKILL_READY)
		return
	
	g_skill1[id] = SKILL_USE
	
	set_weapon_anim(id, V_ANIM_SKILL_1)
	set_pev(id, pev_sequence, P_ANIM_SKILL_1)
	set_pev(id, pev_framerate, 0.5)
	
	set_user_maxspeed(id, 0.1)
	set_user_gravity(id, 2.0)
	
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_byte(20) // radius
	write_byte(200)    // r
	write_byte(200)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(1)  // decay rate in 10's
	message_end() 
	
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, LilithSound[SKILL_1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_pdata_float(id, 83, 1.0, 5)
	
	set_task(0.63, "create_teleport_mark", id+TASK_SKILL_1)
}

public create_teleport_mark(id)
{
	id -= TASK_SKILL_1
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !class_lilith[id])
	{
		remove_task(id+TASK_SKILL_1)
		return
	}
	
	if(g_skill1[id] != SKILL_USE)
		return
	
	if(pev_valid(g_teleport_ent[id][ENT_MARK]))
	{
		remove_entity(g_teleport_ent[id][ENT_MARK])
		g_teleport_ent[id][ENT_MARK] = 0
	}
	
	set_user_maxspeed(id, float(ZOMBIE_SPEED))
	set_user_gravity(id, float(ZOMBIE_GRAVITY)/100.0)
	set_pev(id, pev_framerate, 1.0)
	
	static Float:fOrigin1[3], Float:fOrigin2[3]
	g_teleport_ent[id][ENT_MARK] = create_entity("env_sprite")
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_classname, TELEPORT_MARK_CLASSNAME)
	engfunc(EngFunc_SetModel, g_teleport_ent[id][ENT_MARK], TELEPORT_MARK_MODEL)
	
	pev(id, pev_origin, fOrigin1)
	set_pev(g_teleport_ent[id][ENT_MARK], pev_origin, fOrigin1)
	
	drop_to_floor(g_teleport_ent[id][ENT_MARK])
	
	pev(g_teleport_ent[id][ENT_MARK], pev_origin, fOrigin2)
	fOrigin2[0] += TELEPORT_X
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_origin, fOrigin2)
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_solid, SOLID_NOT)
	set_pev(g_teleport_ent[id][ENT_MARK], pev_movetype, MOVETYPE_NOCLIP)
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_animtime, get_gametime())
	set_pev(g_teleport_ent[id][ENT_MARK], pev_framerate, 1.0)
	set_pev(g_teleport_ent[id][ENT_MARK], pev_sequence, 0)
	set_pev(g_teleport_ent[id][ENT_MARK], pev_owner, id)
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_nextthink, get_gametime() + 2.0)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, fOrigin2[0])
	engfunc(EngFunc_WriteCoord, fOrigin2[1])
	engfunc(EngFunc_WriteCoord, fOrigin2[2])
	write_byte(10) // radius
	write_byte(200)    // r
	write_byte(200)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(1)  // decay rate in 10's
	message_end() 
	
	engfunc(EngFunc_EmitSound, g_teleport_ent[id][ENT_MARK], CHAN_ITEM, LilithSound[PAIN_GATE], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	g_skill1[id] = SKILL_TELEPORT_READY
}

public create_teleport_portal(ent, owner, const Sound, Float:Origin[3])
{
	if(!is_user_alive(owner))
		return
	if(!zp_get_user_zombie(owner) || zp_get_user_nemesis(owner) || !class_lilith[owner])
		return
		
	ent = create_entity("env_sprite")
	
	Origin[0] += TELEPORT_X
	Origin[2] += TELEPORT_Z
	
	set_pev(ent, pev_classname, TELEPORT_PORTAL_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, TELEPORT_PORTAL_MODEL)
	
	set_pev(ent, pev_origin, Origin)
	
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NOCLIP)
	
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 200.0)
	set_pev(ent, pev_scale, 0.5)
	
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, owner)
	set_pev(ent, pev_fuser1, get_gametime() + 2.5)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.05)
	engfunc(EngFunc_EmitSound, ent, CHAN_ITEM, LilithSound[Sound], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public Forward_Portal_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Float:fFrame, Float:Origin[3]
	pev(ent, pev_frame, fFrame)
	pev(ent, pev_origin, Origin)

	fFrame += 1.0
	if(fFrame > 15.0) fFrame = 0.0
	
	set_pev(ent, pev_frame, fFrame)
	set_pev(ent, pev_nextthink, get_gametime() + 0.05)
	
	static Float:fTimeRemove
	pev(ent, pev_fuser1, fTimeRemove)
	if(get_gametime() >= pev(ent, pev_fuser1))
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return
	}
}

public Forward_Mark_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(10) // radius
	write_byte(200)    // r
	write_byte(200)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(1)  // decay rate in 10's
	message_end()
	
	engfunc(EngFunc_EmitSound, ent, CHAN_ITEM, LilithSound[PAIN_GATE], 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_pev(ent, pev_nextthink, get_gametime() + 2.0)
}

public Forward_Mark_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
	if(!is_user_alive(id))
		return
	
	if(pev(id, pev_solid) != SOLID_NOT)
		set_pev(id, pev_solid, SOLID_NOT)
}

public action_skill_2(id)
{
	id -= TASK_SKILL_2
	
	if(!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || !class_lilith[id])
		return
	if(g_skill2[id] != SKILL_READY)
		return
	
	g_skill2[id] = SKILL_USE
	g_skill2_fake_health[id] = ZOMBIE_FAKE_HEALTH
	
	engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, LilithSound[PAIN_HEAL], 1.0, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, LilithSound[PAIN_SKILL_3], 1.0, ATTN_NORM, 0, PITCH_NORM)
	client_cmd(id, "spk %s", LilithSound[PAIN_HEAL])
	
	Create_Head_Sprites(id, BUFFSPR_CLASSNAME, BUFFSPR_MODEL, 0.5, 0.0, 0.0, 255.0, BUFFSPR_ORIGIN_X, BUFFSPR_ORIGIN_Y, BUFFSPR_ORIGIN_Z, 1, 0, 180, 220)
}

public lilith_reset_value(id)
{
	class_lilith[id] = false
	lilith_reset_var_skill(id)
}

public lilith_reset_var_skill(id)
{
	remove_task(id+TASK_SKILL_1)
	remove_task(id+TASK_SKILL_2)
	remove_task(id+TASK_DELAY)
	
	for(new i = 0; i <= ENT_HEADSPR; i++)
		lilith_remove_entity(id, i)
		
	g_skill1[id] = 0
	g_skill2[id] = 0
	g_speed_hud[id] = 1.0
	g_skill2_fake_health[id] = 0
	g_teleport_ent[id][ENT_MARK] = 0
}

public Create_Head_Sprites(id, const Classname[], const Sprite[], Float:Scale, Float:Frame, Float:Time, Float:Transparent, Float:Forward, Float:Right, Float:Up, ColorActivate, Red, Green, Blue)
{
	// Thanks To Dias ... 
	
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent))
		return
		
	g_teleport_ent[id][ENT_HEADSPR] = Ent
	
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	
	Origin[0] += Forward
	Origin[2] += Up
	
	set_pev(Ent, pev_origin, Origin)
		
	set_pev(Ent, pev_takedamage, DAMAGE_NO)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
	
	set_pev(Ent, pev_classname, Classname)
	engfunc(EngFunc_SetModel, Ent, Sprite)
	
	set_pev(Ent, pev_renderfx, kRenderFxNone)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, Transparent)
	
	new Color[3]
	Color[0] = Red
	Color[1] = Green
	Color[2] = Blue
	
	if(ColorActivate)
		set_pev(Ent, pev_rendercolor, Color)
	
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_scale, Scale)
	
	if(Time > 0.0)
		set_pev(Ent, pev_fuser1, get_gametime() + Time)
	
	set_pev(Ent, pev_fuser2, Forward)
	set_pev(Ent, pev_fuser3, Right)
	set_pev(Ent, pev_fuser4, Up)
	
	set_pev(Ent, pev_frame, 0.0)
	set_pev(Ent, pev_iuser1, floatround(Frame))
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
}

public Forward_Buffspr_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3], owner
	owner = pev(ent, pev_owner)
	pev(owner, pev_origin, Origin)
	
	Origin[0] += pev(ent, pev_fuser2)
	Origin[1] += pev(ent, pev_fuser3)
	Origin[2] += pev(ent, pev_fuser4)
	
	engfunc(EngFunc_SetOrigin, ent, Origin)
	set_pev(ent, pev_nextthink, get_gametime() + 0.000001)
}

public lilith_remove_entity(id, num)
{
	if(pev_valid(g_teleport_ent[id][num]))
	{
		remove_entity(g_teleport_ent[id][num])
		g_teleport_ent[id][num] = 0
	}
}

stock bool:is_hull_vacant(const Float:origin[3], hull,id)
{
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))
		return true;
	
	return false;
}

stock get_position(id, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock precache_viewmodel_sound(const model[]) // I Get This From BTE
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
			
			// The Output Is All Sound To Precache In ViewModels (GREAT :V)
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
