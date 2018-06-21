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

char Configfile[PLATFORM_MAX_PATH], 
	g_sMVPName[MAX_MVP_COUNT + 1][PLATFORM_MAX_PATH + 1], 
	g_sMVPFile[MAX_MVP_COUNT + 1][PLATFORM_MAX_PATH + 1],
	NameMVP[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

Handle mvp_cookie, mvp_cookie2;

float VolMVP[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[CS:GO] Custom MVP Anthem",
	author = "Kento",
	version = "1.9",
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
		if(IsValidClient(i) && !IsFakeClient(i))	OnClientCookiesCached(i);
	}
}

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))	OnClientCookiesCached(client);
}

public void OnClientCookiesCached(int client)
{
	if(!IsValidClient(client) && IsFakeClient(client))	return;
		
	char scookie[8];
	GetClientCookie(client, mvp_cookie, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		Selected[client] = FindMVPIDByName(scookie);
		if(Selected[client] != 0)	strcopy(NameMVP[client], sizeof(NameMVP[]), scookie);
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
	
	char sound[PLATFORM_MAX_PATH + 1];
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
	int id;
	
	for(int i = 1; i < MVPCount; i++)
	{
		if(StrEqual(g_sMVPName[i], name))
		{
			id = i;	break;
		}
	}
	
	return id;
}

void LoadConfig()
{
	BuildPath(Path_SM, Configfile, PLATFORM_MAX_PATH, "configs/kento_mvp.cfg");
	
	if(!FileExists(Configfile))
		SetFailState("Can not find config file \"%s\"!", Configfile);
	
	
	KeyValues kv = CreateKeyValues("MVP");
	kv.ImportFromFile(Configfile);
	
	MVPCount = 1;
	
	// Read Config
	if(kv.GotoFirstSubKey())
	{
		char name[PLATFORM_MAX_PATH];
		char file[PLATFORM_MAX_PATH];
		
		do
		{
			kv.GetSectionName(name, sizeof(name));
			kv.GetString("file", file, sizeof(file));				
			
			strcopy(g_sMVPName[MVPCount], sizeof(g_sMVPName[]), name);
			strcopy(g_sMVPFile[MVPCount], sizeof(g_sMVPFile[]), file);
				
			char filepath[PLATFORM_MAX_PATH];
			Format(filepath, sizeof(filepath), "sound/%s", g_sMVPFile[MVPCount])
			AddFileToDownloadsTable(filepath);
			
			char soundpath[PLATFORM_MAX_PATH];
			Format(soundpath, sizeof(soundpath), "*/%s", g_sMVPFile[MVPCount]);
			FakePrecacheSound(soundpath);
			
			MVPCount++;
		}
		while (kv.GotoNextKey());
	}
	
	kv.Rewind();
	delete kv;
}

public int MVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char mvp_name[10];
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

public Action Command_MVP(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu mvp_menu = new Menu(MVPMenuHandler);
	
		char mvpmenutitle[512];
		Format(mvpmenutitle, sizeof(mvpmenutitle), "%T", "MVP Menu Title", client);
		mvp_menu.SetTitle(mvpmenutitle);
		
		char nomvp[PLATFORM_MAX_PATH];
		Format(nomvp, sizeof(nomvp), "%T", "NO MVP", client);
		mvp_menu.AddItem("", nomvp);
		
		for(int i = 1; i < MVPCount; i++)
		{
			mvp_menu.AddItem(g_sMVPName[i], g_sMVPName[i]);
		}
		
		mvp_menu.Display(client, 0);
	}
	return Plugin_Handled;
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