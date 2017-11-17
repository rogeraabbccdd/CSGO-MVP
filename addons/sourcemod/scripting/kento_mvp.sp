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

bool MuteMVP[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[CS:GO] Custom MVP Anthem",
	author = "Kento",
	version = "1.8",
	description = "Custom MVP Anthem",
	url = "https://github.com/rogeraabbccdd/csgo_mvp"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_mvp", Command_MVP, "Select Your MVP Anthem");
	RegConsoleCmd("sm_mutemvp", Command_MuteMVP, "Mute MVP Anthem");
	RegConsoleCmd("sm_unmutemvp", Command_UnMuteMVP, "UnMute MVP Anthem");
	
	RegAdminCmd("sm_mvptest", Command_Test, ADMFLAG_ROOT, "Use this to check your MVP Anthem plugin works fine or not.");
	
	HookEvent("round_mvp", Event_RoundMVP);
	
	LoadTranslations("kento.mvp.phrases");
	
	mvp_cookie = RegClientCookie("mvp_cookie", "Player's MVP Anthem", CookieAccess_Private);
	mvp_cookie2 = RegClientCookie("mvp_cookie2", "Player Mute MVP Anthem Or Not", CookieAccess_Private);
	
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
		
	char scookie2[8];
	GetClientCookie(client, mvp_cookie2, scookie2, sizeof(scookie2));
	if(!StrEqual(scookie2, ""))
	{
		MuteMVP[client] = view_as<bool>(StringToInt(scookie2));
	}
	else if(StrEqual(scookie2,""))	MuteMVP[client] = false;
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
	
	if (IsValidClient(client) && !IsFakeClient(client) && Selected[client] > 0)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				// Announce MVP
				PrintHintText(i, "%T", "MVP", client, clientname, g_sMVPName[mvp]);
					
				// Player doesn't mute mvp
				if (!MuteMVP[i])
				{
					// Mute game sound
					// https://forums.alliedmods.net/showthread.php?t=227735
					ClientCommand(i, "playgamesound Music.StopAllMusic");
					
					// Play MVP Anthem
					ClientCommand(i, "play \"*%s\"", g_sMVPFile[mvp]);
				}
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
		
		if(StrEqual(smvp_id,"mute"))	FakeClientCommand(client, "sm_mutemvp");
		
		else if(StrEqual(smvp_id,"unmute"))	FakeClientCommand(client, "sm_unmutemvp");
		
		else if(!StrEqual(smvp_id,"unmute") && !StrEqual(smvp_id,"unmute"))
		{
			int imvp_id = StringToInt(smvp_id, sizeof(smvp_id));
			
			if(imvp_id == 0)	CPrintToChat(client, "%T", "No Selected", client);
		
			else if(imvp_id > 0)	CPrintToChat(client, "%T", "Selected", client, g_sMVPName[imvp_id]);

			Selected[client] = imvp_id;
			SetClientCookie(client, mvp_cookie, smvp_id);
		}
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
		
		char mute[PLATFORM_MAX_PATH];
		Format(mute, sizeof(mute), "%T", "Mute MVP", client);
		mvp_menu.AddItem("mute", mute);
		
		char unmute[PLATFORM_MAX_PATH];
		Format(unmute, sizeof(unmute), "%T", "UnMute MVP", client);
		mvp_menu.AddItem("unmute", unmute);
		
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

public Action Command_MuteMVP(int client,int args)
{
	CPrintToChat(client, "%T", "Mute", client);
	
	MuteMVP[client] = true;
	SetClientCookie(client, mvp_cookie2, "1");
}

public Action Command_UnMuteMVP(int client,int args)
{
	CPrintToChat(client, "%T", "Un Mute", client);
	
	MuteMVP[client] = false;
	SetClientCookie(client, mvp_cookie2, "0");
}

public Action Command_Test(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if(MuteMVP[client])
			PrintToChat(client, "You Mute MVP");
			
		if(!MuteMVP[client])
			PrintToChat(client, "You Are Not Mute MVP");
			
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