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
#include <emitsoundany>

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
	version = "1.3",
	description = "Custom MVP Anthem",
	url = "https://github.com/rogeraabbccdd/csgo_mvp"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_mvp", Command_MVP);
	
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
					//https://forums.alliedmods.net/showthread.php?t=227735
					ClientCommand(i, "playgamesound Music.StopAllMusic");
					
					//Play MVP Anthem
					EmitSoundCustom(i, g_eMVPAnthem[mvp][szMVPFile],_,_,_,_,_);
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
	
	MVPCount = 0;
	
	mvp_menu = new Menu(MVPMenuHandler);
	
	//Create MVP Menu
	char mvpmenutitle[512];
	Format(mvpmenutitle, sizeof(mvpmenutitle), "%t", "MVP Menu Title");
	SetMenuTitle(mvp_menu, mvpmenutitle);
	
	//Add "No MVP Anthem"
	char nomvp[512];
	Format(nomvp, sizeof(nomvp), "%t", "NO MVP");
	AddMenuItem(mvp_menu, "0", nomvp);
	MVPCount++;
	
	//Read Config
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			char mvp_id[PLATFORM_MAX_PATH];
		
			KvGetSectionName(kv, g_eMVPAnthem[MVPCount][szMVPName], PLATFORM_MAX_PATH);
			KvGetString(kv, "file", g_eMVPAnthem[MVPCount][szMVPFile], PLATFORM_MAX_PATH);				
				
			Format(mvp_id, sizeof(mvp_id), "%d", MVPCount);
		
			AddMenuItem(mvp_menu, mvp_id, g_eMVPAnthem[MVPCount][szMVPName]);
		
			char filepath[PLATFORM_MAX_PATH];
			Format(filepath, sizeof(filepath), "sound/%s", g_eMVPAnthem[MVPCount][szMVPFile])
		
			AddFileToDownloadsTable(filepath);
			PrecacheSoundAny(g_eMVPAnthem[MVPCount][szMVPFile], true);
		
			MVPCount++;
		}
		while (KvGotoNextKey(kv));
	}
	
	KvRewind(kv);
	CloseHandle(kv);
}

public int MVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if (action == MenuAction_Select)
	{
		char smvp_id[10];
		GetMenuItem(menu, param, smvp_id, sizeof(smvp_id));

		int imvp_id = StringToInt(smvp_id, sizeof(smvp_id));
		
		if(imvp_id == 0)
		{
			CPrintToChat(client, "%T", "No Selected", client, g_eMVPAnthem[imvp_id][szMVPName]);
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
		DisplayMenu(mvp_menu, client, 0);
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

// Edit from Quake Sounds v3 https://forums.alliedmods.net/showthread.php?t=224316
// Custom EmitSound to allow compatibility with all game engines
stock void EmitSoundCustom(int client, const char[] sound, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float origin[3] = NULL_VECTOR, const float dir[3] = NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
{
	int clients[1]
	clients[0]=client
	EmitSoundAny(clients,1,sound,entity,channel,level,flags,volume,pitch,speakerentity,origin,dir,updatePos,soundtime)
}