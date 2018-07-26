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
	NameMVP[MAXPLAYERS + 1][1024];

Handle mvp_cookie, mvp_cookie2;

float VolMVP[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[CS:GO] Custom MVP Anthem",
	author = "Kento",
	version = "1.10",
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
	

	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i) && !AreClientCookiesCached(i))	OnClientCookiesCached(i);
	}
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
		Selected[client] = FindMVPIDByName(scookie);
		if(Selected[client] > 0)	strcopy(NameMVP[client], sizeof(NameMVP[]), scookie);
		else 
		{
			NameMVP[client] = "";
			SetClientCookie(client, mvp_cookie, "");
		}
	}
	else if(StrEqual(scookie,""))	NameMVP[client] = "";	
		
	GetClientCookie(client, mvp_cookie2, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		VolMVP[client] = StringToFloat(scookie);
	}
	else if(StrEqual(scookie,""))	VolMVP[client] = 1.0;
}


public void OnConfigsExecuted()
{
	LoadConfig();
}

public Action Event_RoundMVP(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(StrEqual(NameMVP[client], "") || Selected[client] == 0)	return;
	
	int mvp = Selected[client];
	
	char sound[1024];
	Format(sound, sizeof(sound), "*/%s", g_sMVPFile[mvp]);
	
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
	
	// Read Config
	if(kv.GotoFirstSubKey())
	{
		char name[1024];
		char file[1024];
		
		do
		{
			kv.GetSectionName(name, sizeof(name));
			kv.GetString("file", file, sizeof(file));				
			
			strcopy(g_sMVPName[MVPCount], sizeof(g_sMVPName[]), name);
			strcopy(g_sMVPFile[MVPCount], sizeof(g_sMVPFile[]), file);
				
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
	
	return Plugin_Handled;
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char select[1024];
		GetMenuItem(menu, param, select, sizeof(select));
		
		if(StrEqual(select, "mvp"))
		{
			DisplayMVPMenu(client);
		}
		else if(StrEqual(select, "vol"))
		{
			DisplayVolMenu(client);
		}
	}
}

void DisplayMVPMenu(int client)
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
		Format(nomvp, sizeof(nomvp), "%T", "NO MVP", client);
		mvp_menu.AddItem("", nomvp);
		
		for(int i = 1; i < MVPCount; i++)
		{
			mvp_menu.AddItem(g_sMVPName[i], g_sMVPName[i]);
		}
		
		mvp_menu.Display(client, 0);
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
		}
		else
		{
			CPrintToChat(client, "%T", "Selected", client, mvp_name);
			Selected[client] = FindMVPIDByName(mvp_name);
		}
		
		strcopy(NameMVP[client], sizeof(NameMVP[]), mvp_name);
		SetClientCookie(client, mvp_cookie, mvp_name);
	}
}

void DisplayVolMenu(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu vol_menu = new Menu(VolMenuHandler);
		
		char vol[1024];
		if(VolMVP[client] > 0.00)	Format(vol, sizeof(vol), "%.2f", VolMVP[client]);
		else Format(vol, sizeof(vol), "%T", "Mute");
		
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