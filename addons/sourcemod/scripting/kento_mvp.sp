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

int MVPCount, Selected[MAXPLAYERS + 1] = {-1, ...};

char Configfile[PLATFORM_MAX_PATH], 
	g_sMVPName[MAX_MVP_COUNT + 1][PLATFORM_MAX_PATH + 1], 
	g_sMVPFile[MAX_MVP_COUNT + 1][PLATFORM_MAX_PATH + 1];

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
	
	RegAdminCmd("sm_mvptest", Command_Test, ADMFLAG_ROOT, "Use this to check your MVP Anthem plugin works fine or not.");
	
	HookEvent("round_mvp", Event_RoundMVP);
	
	LoadTranslations("kento.mvp.phrases");
	
	mvp_cookie = RegClientCookie("mvp_cookie", "Player's MVP Anthem", CookieAccess_Private);
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
		int icookie = StringToInt(scookie);
		Selected[client] = icookie;
	}
	else if(StrEqual(scookie,""))	Selected[client] = 0;	
		
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
	int mvp = Selected[client];
	char clientname [PLATFORM_MAX_PATH];
	GetClientName(client, clientname, sizeof(clientname));
	
	char sound[PLATFORM_MAX_PATH + 1];
	Format(sound, sizeof(sound), "*/%s", g_sMVPFile[mvp])
	
	if (IsValidClient(client) && !IsFakeClient(client) && Selected[client] > 0)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				// Announce MVP
				PrintHintText(i, "%T", "MVP", client, clientname, g_sMVPName[mvp]);
					
				// Mute game sound
				// https://forums.alliedmods.net/showthread.php?t=227735
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				
				// Play MVP Anthem
				EmitSoundToClient(i, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, VolMVP[i]);
			}	
		}
	}
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
		char name[MAX_MVP_COUNT];
		char file[MAX_MVP_COUNT];
		
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
		char smvp_id[10];
		GetMenuItem(menu, param, smvp_id, sizeof(smvp_id));
		
		int imvp_id = StringToInt(smvp_id, sizeof(smvp_id));
			
		if(imvp_id == 0)	CPrintToChat(client, "%T", "No Selected", client);
	
		else if(imvp_id > 0)	CPrintToChat(client, "%T", "Selected", client, g_sMVPName[imvp_id]);

		Selected[client] = imvp_id;
		SetClientCookie(client, mvp_cookie, smvp_id);
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
		mvp_menu.AddItem("0", nomvp);
		
		for(int i = 1; i < MVPCount; i++)
		{
			char mvp_id[PLATFORM_MAX_PATH];
			Format(mvp_id, sizeof(mvp_id), "%i", i);
			mvp_menu.AddItem(mvp_id, g_sMVPName[i]);
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

public Action Command_Test(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		PrintToChat(client, "You're MVP volume is %f", VolMVP[client]);
			
		int mvp = Selected[client];
		
		PrintToChat(client, "You're MVP is ID %i, Name %s", Selected[client], g_sMVPName[mvp]);
		
		PrintToChat(client, "Check console output for all MVP id and name in your config");
			
		PrintToConsole(client, "********** Custom MVP **********");
		for(int i = 1; i < MVPCount; i++)
		{
			char mvp_id[PLATFORM_MAX_PATH];
			Format(mvp_id, sizeof(mvp_id), "%d", i);
			PrintToConsole(client, "ID %i, Name %s, File %s", i, g_sMVPName[i], g_sMVPFile[i]);
		}
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