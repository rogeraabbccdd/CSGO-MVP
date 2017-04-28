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
//
//To Do
//Rewrite menu to use %T client

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <kento_csgocolors>

#define MAX_MVP_COUNT 256

#pragma newdecls required

int Selected[MAXPLAYERS + 1] = {-1, ...};
int MVPCount;

char Configfile[PLATFORM_MAX_PATH];

enum MVPAnthem
{
	String:szMVPName[PLATFORM_MAX_PATH],
	String:szMVPFile[PLATFORM_MAX_PATH],
}

int g_eMVPAnthem[MAX_MVP_COUNT+1][MVPAnthem];

Handle mvp_cookie;
Handle mvp_menu;
Handle kv;

public Plugin myinfo =
{
	name = "[CS:GO] Custom MVP Anthem",
	author = "Kento",
	version = "1.4",
	description = "Custom MVP Anthem",
	url = "https://github.com/rogeraabbccdd/csgo_mvp"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_mvp", Command_MVP);
	
	//RegConsoleCmd("sm_test", Command_Test);
	
	HookEvent("round_mvp", Event_RoundMVP);
	
	//AutoExecConfig(true, "kento_mvp");
    
	LoadTranslations("kento.mvp.phrases");
	
	mvp_cookie = RegClientCookie("mvp_cookie", "Player's MVP Anthem", CookieAccess_Private);
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	if (IsValidClient(client))
	{
		char scookie[8];
		GetClientCookie(client, mvp_cookie, scookie, sizeof(scookie));
		int icookie = StringToInt(scookie);
		Selected[client] = icookie;
	}
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
	
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if(Selected[client] > 0)
		{	
			for(int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && !IsFakeClient(i))
				{
					// Mute game sound
					// https://forums.alliedmods.net/showthread.php?t=227735
					ClientCommand(i, "playgamesound Music.StopAllMusic");
					
					// Play MVP Anthem
					ClientCommand(i, "play \"*%s\"", g_eMVPAnthem[mvp][szMVPFile]);
					PrintHintText(i, "%T", "MVP", client, clientname, g_eMVPAnthem[mvp][szMVPName]);
				}
			}	
		}
	}
}	

void LoadConfig()
{
	BuildPath(Path_SM, Configfile, PLATFORM_MAX_PATH, "configs/kento_mvp.cfg");
	
	kv = CreateKeyValues("MVP");
	FileToKeyValues(kv, Configfile);
	
	MVPCount = 1;
	
	// Read Config
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			// Get kv
			KvGetSectionName(kv, g_eMVPAnthem[MVPCount][szMVPName], PLATFORM_MAX_PATH);
			KvGetString(kv, "file", g_eMVPAnthem[MVPCount][szMVPFile], PLATFORM_MAX_PATH);				
			
			// Download
			char filepath[PLATFORM_MAX_PATH];
			Format(filepath, sizeof(filepath), "sound/%s", g_eMVPAnthem[MVPCount][szMVPFile])
			AddFileToDownloadsTable(filepath);
			
			// Precache
			// https://wiki.alliedmods.net/Csgo_quirks
			char soundpath[PLATFORM_MAX_PATH];
			Format(soundpath, sizeof(soundpath), "*/%s", g_eMVPAnthem[MVPCount][szMVPFile]);
			FakePrecacheSound(soundpath);
			
			MVPCount++;
		}
		while (KvGotoNextKey(kv));
	}
	
	KvRewind(kv);
	CloseHandle(kv);
}

public int MVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char smvp_id[32];
		GetMenuItem(menu, param, smvp_id, sizeof(smvp_id));
		int imvp_id = StringToInt(smvp_id, sizeof(smvp_id));
		
		if(imvp_id == 0)
		{
			CPrintToChat(client, "%T", "No Selected", client);
		}
		
		if(imvp_id > 0)
		{
			CPrintToChat(client, "%T", "Selected", client, g_eMVPAnthem[imvp_id][szMVPName]);
		}

		Selected[client] = imvp_id;
		SetClientCookie(client, mvp_cookie, smvp_id);
	}
}

public Action Command_MVP(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		// Create MVP Menu
		mvp_menu = new Menu(MVPMenuHandler);
	
		char mvpmenutitle[512];
		Format(mvpmenutitle, sizeof(mvpmenutitle), "%T", "MVP Menu Title", client);
		SetMenuTitle(mvp_menu, mvpmenutitle);
		
		// Add No MVP
		char nomvp[PLATFORM_MAX_PATH];
		Format(nomvp, sizeof(nomvp), "%T", "NO MVP", client);
		AddMenuItem(mvp_menu, "0", nomvp);
		
		for(int i = 1; i < MVPCount; i++)
		{
			char mvp_id[PLATFORM_MAX_PATH];
			Format(mvp_id, sizeof(mvp_id), "%i", i);
			AddMenuItem(mvp_menu, mvp_id, g_eMVPAnthem[i][szMVPName]);
		}
		
		DisplayMenu(mvp_menu, client, 0);
	}
	return Plugin_Handled;
}

/*
public Action Command_Test(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		for(int i = 1; i < MVPCount; i++)
		{
			char mvp_id[PLATFORM_MAX_PATH];
			Format(mvp_id, sizeof(mvp_id), "%d", i);
			PrintToConsole(client, "%i, %s", i, g_eMVPAnthem[i][szMVPName]);
		}
	}
	return Plugin_Handled;
}
*/

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