//***************NYAN CAT****************
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄░░░░░░░░░
//░░░░░░░░▄▀░░░░░░░░░░░░▄░░░░░░░▀▄░░░░░░░
//░░░░░░░░█░░▄░░░░▄░░░░░░░░░░░░░░█░░░░░░░
//░░░░░░░░█░░░░░░░░░░░░▄█▄▄░░▄░░░█░▄▄▄░░░
//░▄▄▄▄▄░░█░░░░░░▀░░░░▀█░░▀▄░░░░░█▀▀░██░░
//░██▄▀██▄█░░░▄░░░░░░░██░░░░▀▀▀▀▀░░░░██░░
//░░▀██▄▀██░░░░░░░░▀░██▀░░░░░░░░░░░░░▀██░
//░░░░▀████░▀░░░░▄░░░██░░░▄█░░░░▄░▄█░░██░
//░░░░░░░▀█░░░░▄░░░░░██░░░░▄░░░▄░░▄░░░██░
//░░░░░░░▄█▄░░░░░░░░░░░▀▄░░▀▀▀▀▀▀▀▀░░▄▀░░
//░░░░░░█▀▀█████████▀▀▀▀████████████▀░░░░
//░░░░░░████▀░░███▀░░░░░░▀███░░▀██▀░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//***************NYAN CAT****************

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <kento_csgocolors>

#define MAX_MVP_COUNT 1000

#pragma newdecls required

int MVPCount, Selected[MAXPLAYERS + 1];

char Configfile[1024], 
	g_sMVPName[MAX_MVP_COUNT + 1][1024], 
	g_sMVPFile[MAX_MVP_COUNT + 1][1024],
	g_sMVPFlag[MAX_MVP_COUNT + 1][AdminFlags_TOTAL], 
	NameMVP[MAXPLAYERS + 1][1024];

ArrayList g_hMVPSteamIds[MAX_MVP_COUNT + 1];

Handle mvp_cookie, mvp_cookie2;

float VolMVP[MAXPLAYERS + 1];

ConVar Cvar_Vol;
ConVar Cvar_ShowMode;
float mvp_defaultVol;
int mvp_no_acces_show_mode;

public Plugin myinfo =
{
	name = "[CS:GO] Custom MVP Anthem",
	author = "Kento",
	version = "1.11",
	description = "Custom MVP Anthem",
	url = "https://github.com/rogeraabbccdd/csgo_mvp"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_mvp", Command_MVP, "Select Your MVP Anthem");
	RegConsoleCmd("sm_mvpvol", Command_MVPVol, "MVP Volume");
	
	HookEvent("round_mvp", Event_RoundMVP);
	
	LoadTranslations("kento.mvp.phrases");
	
	mvp_cookie = RegClientCookie("mvp_name", "Player's MVP Anthem", CookieAccess_Private);
	mvp_cookie2 = RegClientCookie("mvp_vol", "Player MVP volume", CookieAccess_Private);

	Cvar_Vol = CreateConVar("mvp_defaultvol", "0.8", "Default MVP anthem volume.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_ShowMode = CreateConVar("mvp_no_acces_show_mode", "1", "How to show the mvp(s) to clients that doesn't have acces to them? 1 = Don't show in the menu. 2 = Show but they won't be able to select the item", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_Vol.AddChangeHook(OnConVarChanged);
	Cvar_ShowMode.AddChangeHook(OnConVarChanged);

	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i) && !AreClientCookiesCached(i))	OnClientCookiesCached(i);
	}
	
	for(int i = 0; i < MAX_MVP_COUNT; i++)
	{
		delete g_hMVPSteamIds[i];
	}
}

public void OnConfigsExecuted()
{
	mvp_defaultVol = Cvar_Vol.FloatValue;

	LoadConfig();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == Cvar_Vol)	mvp_defaultVol = Cvar_Vol.FloatValue;
	if (convar == Cvar_ShowMode)mvp_no_acces_show_mode = Cvar_ShowMode.IntValue;
}

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))	OnClientCookiesCached(client);
}

public void OnClientCookiesCached(int client)
{
	if(!IsValidClient(client) && IsFakeClient(client))	return;
	
	char scookie[1024];
	GetClientCookie(client, mvp_cookie, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		int id = FindMVPIDByName(scookie)
	
		if(id > 0)
        {
			Selected[client] = id;
			strcopy(NameMVP[client], sizeof(NameMVP[]), scookie);
		}
		else
		{
            Format(NameMVP[client], sizeof(NameMVP[]), "");
            SetClientCookie(client, mvp_cookie, "");
        } 
	}
	else if(StrEqual(scookie,""))	Format(NameMVP[client], sizeof(NameMVP[]), "");
		
	GetClientCookie(client, mvp_cookie2, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		VolMVP[client] = StringToFloat(scookie);
	}
	else if(StrEqual(scookie,""))	VolMVP[client] = mvp_defaultVol;
}

public Action Event_RoundMVP(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if((StrEqual(NameMVP[client], "") || Selected[client] == 0) && Selected[client] != -1)	return; // We  need this in case StrEqual(NameMVP[client], "") is true and the Selected[client] = -1. This would happen if the only selection/cookie of the client is "Random" since he joined the server.
	
	int mvp = Selected[client];
	
	char sound[1024];
	if(mvp != -1)
	{
		Format(sound, sizeof(sound), "*/%s", g_sMVPFile[mvp]);
	}
	else
	{
		mvp = GetRandomMVP(client);
		Format(sound, sizeof(sound), "*/%s", g_sMVPFile[mvp]);
	}
	
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				// Announce MVP
				PrintHintText(i, "%T", "MVP", client, client, g_sMVPName[mvp]);
					
				// Mute game sound
				// https://forums.alliedmods.net/showthread.php?t=227735
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				
				// Play MVP Anthem
				EmitSoundToClient(i, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, VolMVP[i]);
			}	
		}
	}
}	

int FindMVPIDByName(char [] name)
{
	int id = 0;
	
	for(int i = 1; i <= MVPCount; i++)
	{
		if(StrEqual(g_sMVPName[i], name))	id = i;
	}
	
	return id;
}

void LoadConfig()
{
	BuildPath(Path_SM, Configfile, 1024, "configs/kento_mvp.cfg");
	
	if(!FileExists(Configfile))
		SetFailState("Can not find config file \"%s\"!", Configfile);
	
	
	KeyValues kv = CreateKeyValues("MVP");
	kv.ImportFromFile(Configfile);
	
	MVPCount = 1;
	
	for(int i = 0; i < MAX_MVP_COUNT; i++)
	{
		delete g_hMVPSteamIds[i]; // Delete the old array handle since g_hMVPSteamIds[i] it's just a reference
		
		g_hMVPSteamIds[i] = new ArrayList(ByteCountToCells(1024));
	}
	
	// Read Config
	if(kv.GotoFirstSubKey())
	{
		char name[1024];
		char file[1024];
		char flag[AdminFlags_TOTAL];
		char steamid[32][32]; // steamid[0] = the number in the config("1", "2", etc..). steamid[1] the actual steamid
		
		int i;
		
		do
		{
			kv.GetSectionName(name, sizeof(name));
			kv.GetString("file", file, sizeof(file));
			kv.GetString("flag", flag, sizeof(flag), "");
			
			if(kv.JumpToKey("Steamids"))
			{
				i = 0;
				
				do{
					FormatEx(steamid[0], sizeof(steamid[]), "%i", ++i);
					kv.GetString(steamid[0], steamid[1], sizeof(steamid[]), "");
					
					stock_ExtractSteamID(steamid[1], steamid[1], sizeof(steamid[]));
					
					g_hMVPSteamIds[MVPCount].PushString(steamid[1]);
				}
				while (steamid[1][0]);
				
				g_hMVPSteamIds[MVPCount].Erase(g_hMVPSteamIds[MVPCount].Length - 1); // Remove the last entry since it should be empty due to the check above.
				
				kv.GoBack(); // We need to go back since we used KeyValue.JumpToKey()
			}
			
			strcopy(g_sMVPName[MVPCount], sizeof(g_sMVPName[]), name);
			strcopy(g_sMVPFile[MVPCount], sizeof(g_sMVPFile[]), file);
			strcopy(g_sMVPFlag[MVPCount], sizeof(g_sMVPFlag[]), flag);
			
			char filepath[1024];
			Format(filepath, sizeof(filepath), "sound/%s", g_sMVPFile[MVPCount])
			AddFileToDownloadsTable(filepath);
			
			char soundpath[1024];
			Format(soundpath, sizeof(soundpath), "*/%s", g_sMVPFile[MVPCount]);
			FakePrecacheSound(soundpath);
			
			MVPCount++;
		}
		while (kv.GotoNextKey());
	}
	
	kv.Rewind();
	delete kv;
}

public Action Command_MVP(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		ShowMainMenu(client);
	}
	
	return Plugin_Handled;
}

void ShowMainMenu(int client)
{
	Menu settings_menu = new Menu(SettingsMenuHandler);
	
	char name[1024];
	if(StrEqual(NameMVP[client], ""))	Format(name, sizeof(name), "%T", "No MVP", client);
	else Format(name, sizeof(name), NameMVP[client]);
	
	char menutitle[1024];
	Format(menutitle, sizeof(menutitle), "%T", "Setting Menu Title", client, name, VolMVP[client]);
	settings_menu.SetTitle(menutitle);
	
	char mvpmenu[1024], volmenu[1024];
	Format(mvpmenu, sizeof(mvpmenu), "%T", "MVP Menu Title", client);
	Format(volmenu, sizeof(volmenu), "%T", "Vol Menu Title", client);
	
	settings_menu.AddItem("mvp", mvpmenu);
	settings_menu.AddItem("vol", volmenu);
	
	settings_menu.Display(client, 0);
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char select[1024];
		GetMenuItem(menu, param, select, sizeof(select));
		
		if(StrEqual(select, "mvp"))
		{
			DisplayMVPMenu(client, 0);
		}
		else if(StrEqual(select, "vol"))
		{
			DisplayVolMenu(client);
		}
	}
}

void DisplayMVPMenu(int client, int start)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu mvp_menu = new Menu(MVPMenuHandler);
		
		char name[1024];
		if(StrEqual(NameMVP[client], ""))	Format(name, sizeof(name), "%T", "No MVP", client);
		else Format(name, sizeof(name), NameMVP[client]);
		
		char mvpmenutitle[1024];
		Format(mvpmenutitle, sizeof(mvpmenutitle), "%T", "MVP Menu Title 2", client, name);
		mvp_menu.SetTitle(mvpmenutitle);
		
		char nomvp[1024];
		Format(nomvp, sizeof(nomvp), "%T", "No MVP", client);
		mvp_menu.AddItem("", nomvp);
		
		char randommvp[1024];
		Format(randommvp, sizeof(randommvp), "%T", "Random MVP", client);
		mvp_menu.AddItem("random", randommvp);
		
		char steamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		stock_ExtractSteamID(steamid, steamid, sizeof(steamid));
		
		for(int i = 1; i < MVPCount; i++)
		{
			if(g_hMVPSteamIds[i].Length) // If the MVP has any "restrictions"
			{
				if(g_hMVPSteamIds[i].FindString(steamid) != -1)
				{
					mvp_menu.AddItem(g_sMVPName[i], g_sMVPName[i]);
				}
				else
				{
					switch(mvp_no_acces_show_mode) // We use switch in case we want future updates on the behavior(more options)
					{
						case 1:continue; // Dont add it to the menu at all
						case 0:mvp_menu.AddItem(g_sMVPName[i], g_sMVPName[i], ITEMDRAW_DISABLED);
					}
				}
			}
			else
			{
				mvp_menu.AddItem(g_sMVPName[i], g_sMVPName[i]);
			}
		}
		
		mvp_menu.ExitBackButton = true;
		mvp_menu.DisplayAt(client, start, 0);
	}
}

public int MVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char mvp_name[1024];
		GetMenuItem(menu, param, mvp_name, sizeof(mvp_name));
		
		if(StrEqual(mvp_name, ""))
        {
			CPrintToChat(client, "%T", "No Selected", client);
			Selected[client] = 0;
			NameMVP[client] = "";
			SetClientCookie(client, mvp_cookie, "");
		}
        else if(StrEqual(mvp_name, "random"))
        {
            Selected[client] = -1; // We use -1 as a unique id for "random" selection
            CPrintToChat(client, "%T", "Selected Random", client);
        }
		else
		{
			int id = FindMVPIDByName(mvp_name);

			if(CanUseMVP(client, id))
			{
				CPrintToChat(client, "%T", "Selected", client, mvp_name);
				Selected[client] = id;
				strcopy(NameMVP[client], sizeof(NameMVP[]), mvp_name);
				SetClientCookie(client, mvp_cookie, mvp_name);
			}
			else {
				CPrintToChat(client, "%T", "No Flag", client, mvp_name);
			}
		}
		DisplayMVPMenu(client, menu.Selection);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack) {
	ShowMainMenu(client);
  }
}

void DisplayVolMenu(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu vol_menu = new Menu(VolMenuHandler);
		
		char vol[1024];
		if(VolMVP[client] > 0.00)	Format(vol, sizeof(vol), "%.2f", VolMVP[client]);
		else Format(vol, sizeof(vol), "%T", "Mute", client);
		
		char menutitle[1024];
		Format(menutitle, sizeof(menutitle), "%T", "Vol Menu Title 2", client, vol);
		vol_menu.SetTitle(menutitle);
		
		char mute[1024];
		Format(mute, sizeof(mute), "%T", "Mute", client);
		
		vol_menu.AddItem("0", mute);
		vol_menu.AddItem("0.2", "20%");
		vol_menu.AddItem("0.4", "40%");
		vol_menu.AddItem("0.6", "60%");
		vol_menu.AddItem("0.8", "80%");
		vol_menu.AddItem("1.0", "100%");
		vol_menu.ExitBackButton = true;
		vol_menu.Display(client, 0);
	}
}

public int VolMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char vol[1024];
		GetMenuItem(menu, param, vol, sizeof(vol));
		
		VolMVP[client] = StringToFloat(vol);
		CPrintToChat(client, "%T", "Volume 2", client, VolMVP[client]);
		
		SetClientCookie(client, mvp_cookie2, vol);

		DisplayVolMenu(client);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack) {
    ShowMainMenu(client);
  }
}

public Action Command_MVPVol(int client,int args)
{
	if (IsValidClient(client))
	{
		char arg[20];
		float volume;
		
		if (args < 1)
		{
			CPrintToChat(client, "%T", "Volume 1", client);
			return Plugin_Handled;
		}
			
		GetCmdArg(1, arg, sizeof(arg));
		volume = StringToFloat(arg);
		
		if (volume < 0.0 || volume > 1.0)
		{
			CPrintToChat(client, "%T", "Volume 1", client);
			return Plugin_Handled;
		}
		
		VolMVP[client] = StringToFloat(arg);
		CPrintToChat(client, "%T", "Volume 2", client, VolMVP[client]);
		
		SetClientCookie(client, mvp_cookie2, arg);
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

// https://wiki.alliedmods.net/Csgo_quirks
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

stock bool CanUseMVP(int client, int id)
{
	if(StrEqual(g_sMVPFlag[id], "") || StrEqual(g_sMVPFlag[id], " "))	return true;
	else
	{
		if (CheckCommandAccess(client, "mvp", ReadFlagString(g_sMVPFlag[id]), true))	return true;
		else return false;
	}
}

stock int stock_ExtractSteamID(const char[] sInput, char[] sOutput, const int iSize)
{
	static char m_Patterns[][] =
	{
		"STEAM_0:0:", "STEAM_0:1:",
		"STEAM_1:0:", "STEAM_1:1:"
	};

	static int m_Iterator, m_Length;

	m_Iterator = 0;
	m_Length = FormatEx(sOutput, iSize, sInput);

	for (; m_Iterator < sizeof(m_Patterns); m_Iterator++)
		m_Length = ReplaceString(sOutput, iSize, m_Patterns[m_Iterator], "", false);

	return m_Length;
}

int GetRandomMVP(int client)
{
	ArrayList array = new ArrayList(ByteCountToCells(1024));
	
	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	stock_ExtractSteamID(steamid, steamid, sizeof(steamid));
	
	for(int i = 1; i <= MVPCount; i++)
	{
		if(CanUseMVP(client, i))
		{
			if(g_hMVPSteamIds[i].Length) // If the MVP has any "restrictions"
			{
				if(g_hMVPSteamIds[i].FindString(steamid) != -1)
				{
					array.PushString(g_sMVPName[i]);
				}
				continue;
			}
			array.PushString(g_sMVPName[i]);
		}
	}
	
	char tempMVP[1024];
	array.GetString(GetRandomInt(0, array.Length - 1), tempMVP, sizeof(tempMVP))
	
	delete array;
	return FindMVPIDByName(tempMVP);
}