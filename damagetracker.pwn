/*

					Damage tracking
				Balkan Underground Evolution, LLC
	(created by Balkan Underground Evolution Development Team)
					
	* Copyright (c) 2018, Balkan Underground Evolution, LLC
	*
	* All rights reserved.
	*
	* Redistribution and use in source and binary forms, with or without modification,
	* are not permitted in any case.
	*
	*
	* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
	* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
	* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
	* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#include <YSI\y_hooks>

enum PLAYER_DAMAGE_TRACKING
{
	DAMAGE_DATA_ID,
	DAMAGE_INJURED_TIMES,
	Float:DAMAGE_TAKEN_AMMOUNT,
	DAMAGE_TAKEN_WEAPON,
	DAMAGE_BODY_PART,
	DAMAGE_TIMESTAMP,
	DAMAGE_ARMOUR
}
new PlayerDamageData[MAX_PLAYERS][15][PLAYER_DAMAGE_TRACKING];

hook OnPlayerConnect(playerid)
{
	ResetDamageInformer(playerid);
}

hook OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	if (issuerid != INVALID_PLAYER_ID) {
		if (PlayerDamageData[playerid][0][DAMAGE_DATA_ID] > 14) PlayerDamageData[playerid][0][DAMAGE_DATA_ID] = 0;
		new damaged_id = PlayerDamageData[playerid][0][DAMAGE_DATA_ID];
		PlayerDamageData[playerid][damaged_id][DAMAGE_TAKEN_AMMOUNT] = amount;
		PlayerDamageData[playerid][damaged_id][DAMAGE_TAKEN_WEAPON] = weaponid;
		PlayerDamageData[playerid][damaged_id][DAMAGE_BODY_PART] = bodypart;
		PlayerDamageData[playerid][damaged_id][DAMAGE_TIMESTAMP] = gettime();

		new Float:armour;
		SafeGetPlayerArmour(playerid, armour);
		if (armour > 1) PlayerDamageData[playerid][damaged_id][DAMAGE_ARMOUR] = 1;
		else if (armour < 1) PlayerDamageData[playerid][damaged_id][DAMAGE_ARMOUR] = 0;

		PlayerDamageData[playerid][0][DAMAGE_DATA_ID]++;
		PlayerDamageData[playerid][0][DAMAGE_INJURED_TIMES]++;
	}
}

hook OnPlayerDeath(playerid)
{
	if (PlayerDamageData[playerid][0][DAMAGE_INJURED_TIMES] > 0) {
		new string[128];
		format(string, sizeof(string), "(( Ozlijedjeni ste %d puta, /damage %d za spisak svih ozlijeda! ))", PlayerDamageData[playerid][0][DAMAGE_INJURED_TIMES], playerid);
		SendClientMessage(playerid, 0xFF6347FF, string);
		PlayerDamageData[playerid][0][DAMAGE_INJURED_TIMES] = 0;
	}
}

/**
* Reset damage informer
*
* return true
*/
ResetDamageInformer(playerid)
{
	PlayerDamageData[playerid][0][DAMAGE_DATA_ID] = 0;
	for (new i = 0, j = 15; i < j; i++) {
		PlayerDamageData[playerid][i][DAMAGE_TAKEN_AMMOUNT] = 0;
		PlayerDamageData[playerid][i][DAMAGE_TAKEN_WEAPON] = 0;
		PlayerDamageData[playerid][i][DAMAGE_BODY_PART] = 0;
		PlayerDamageData[playerid][i][DAMAGE_TIMESTAMP] = 0;
		PlayerDamageData[playerid][i][DAMAGE_ARMOUR] = 0;
	}
	return true;
}

/**
* Return bodypart name
*
* @string part_string
*/
GetBodypartName(bodypart)
{
	new part_string[24];
	switch(bodypart)
	{
		case 3: part_string = "trup";
		case 4: part_string = "prepone";
		case 5: part_string = "lijevu ruku";
		case 6: part_string = "desnu ruku";
		case 7: part_string = "lijevu nogu";
		case 8: part_string = "desnu nogu";
		case 9: part_string = "glavu";
		default: part_string = "nepoznato";
	}
	return part_string;
}

cmd:damage(playerid, params[])
{
	new giveplayerid,
		damage_counter = 0,
		weapon_name[36],
		armour_info[36],
		damage_info[1024];
	
	if (sscanf(params, "u", giveplayerid)) return Command(playerid, "/damage [ID Igraca / Deo igraca]");
	if (giveplayerid == INVALID_PLAYER_ID) return Error(playerid, "Igrac je offline!");
	if (!ProxDetectorS(5.0, playerid, giveplayerid)) return Error(playerid, "Niste blizu igraca!");
	if (Specuje[giveplayerid] != INVALID_PLAYER_ID) return Error(playerid, "Niste blizu igraca!");

	for (new i = 0, j = 15; i < j; i++) 
	{
		if (PlayerDamageData[giveplayerid][i][DAMAGE_TAKEN_AMMOUNT] > 0)
		{
			damage_counter++;
			GetWeaponName(PlayerDamageData[giveplayerid][i][DAMAGE_TAKEN_WEAPON], weapon_name, sizeof(weapon_name));
			armour_info = (PlayerDamageData[giveplayerid][i][DAMAGE_ARMOUR] != 0) ? ("Hit") : ("No hit");
			format(damage_info, sizeof(damage_info), "%s%.1f dmg iz %s (PANCIR: %s) u %s prije %d sekundi\n", damage_info, PlayerDamageData[giveplayerid][i][DAMAGE_TAKEN_AMMOUNT], weapon_name,
				armour_info, GetBodypartName(PlayerDamageData[giveplayerid][i][DAMAGE_BODY_PART]), gettime()-PlayerDamageData[giveplayerid][i][DAMAGE_TIMESTAMP]);
		}
	}
	if (damage_counter == 0) return Error(playerid, "Nema stete za prikazati!");
	ShowDialog(playerid, Show:StaffDialog, DIALOG_STYLE_LIST, "Damage info (zadnjih 15)", damage_info, "Ok","");
	return true;
}