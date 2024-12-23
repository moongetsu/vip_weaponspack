
// ██████╗ ██╗████████╗██╗  ██╗██╗   ██╗██████╗     ██████╗ ██████╗ ███╗   ███╗    ██╗███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗ ██████╗ ███████╗████████╗███████╗██╗   ██╗
// ██╔════╝ ██║╚══██╔══╝██║  ██║██║   ██║██╔══██╗   ██╔════╝██╔═══██╗████╗ ████║   ██╔╝████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██╔════╝ ██╔════╝╚══██╔══╝██╔════╝██║   ██║
// ██║  ███╗██║   ██║   ███████║██║   ██║██████╔╝   ██║     ██║   ██║██╔████╔██║  ██╔╝ ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██║  ███╗█████╗     ██║   ███████╗██║   ██║
// ██║   ██║██║   ██║   ██╔══██║██║   ██║██╔══██╗   ██║     ██║   ██║██║╚██╔╝██║ ██╔╝  ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║██║   ██║██╔══╝     ██║   ╚════██║██║   ██║
// ╚██████╔╝██║   ██║   ██║  ██║╚██████╔╝██████╔╝██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║██╔╝   ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║╚██████╔╝███████╗   ██║   ███████║╚██████╔╝
//  ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝    ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝                                                                                                                              
// Plugin writed by moongetsu
// Plugin inspired from VIP Weapons by Night
// If you have any problems or ideas for any CS:GO Plugins contact me on Discord! (moongetsu1)
// Enjoy the plugin!
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <vip_core>
#include <multicolors>
#include <sdktools>

#define MAX_GRENADES 6

bool g_bHasUsedMenu[MAXPLAYERS + 1];
bool g_bEnabled[MAXPLAYERS + 1]; 
bool g_bEnable = true;

Handle g_hTimer;
ConVar g_cvmp_buytime;
float g_fBuyTime;

static const char g_sFeature[] = "Weapons Pack";

enum struct WeaponInfo {
    char name[32];
    char entity[32];
}

static const WeaponInfo g_WeaponList[] = {
    {"» Close Menu", ""},
    {"» AK47 + DEAGLE", "weapon_ak47"},
    {"» M4A1-S + DEAGLE", "weapon_m4a1_silencer"},
    {"» M4A4 + DEAGLE", "weapon_m4a1"},
    {"» SSG + DEAGLE", "weapon_ssg08"},
    {"» AWP + DEAGLE", "weapon_awp"}
};

public Plugin myinfo = {
    name = "[VIP] Weapons Pack",
    author = ".NiGHT, moongetsu",
    version = "2.3",
    description = "A simple plugin for sourcemod that allows the VIP Players to choose their weapons pack for the round.",
    url = "https://steamcommunity.com/id/NiGHT757, https://github.com/moongetsu"
};

public void OnPluginStart() {
    LoadTranslations("vip_weaponspack.phrases");
    
    if (VIP_IsVIPLoaded()) {
        VIP_OnVIPLoaded();
    }

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_spawn", Event_PlayerSpawn);

    RegConsoleCmd("sm_arme", Command_VipMenu, "Comanda pentru arme VIP");
    RegConsoleCmd("sm_guns", Command_VipMenu, "Command for the VIP Weapons");

    g_cvmp_buytime = FindConVar("mp_buytime");
    g_cvmp_buytime.AddChangeHook(OnSettingsChanged);
    g_fBuyTime = g_cvmp_buytime.FloatValue;
    
    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && VIP_IsClientVIP(i)) {
            g_bEnabled[i] = VIP_IsClientFeatureUse(i, g_sFeature);
        }
    }
}

public void OnPluginEnd() {
    VIP_UnregisterMe();
}

public void VIP_OnVIPClientLoaded(int client) {
    g_bEnabled[client] = VIP_IsClientFeatureUse(client, g_sFeature);
}

public void OnSettingsChanged(ConVar convar, const char[] oldVal, const char[] newVal) {
    g_fBuyTime = g_cvmp_buytime.FloatValue;
}

public void VIP_OnVIPLoaded() {
    VIP_RegisterFeature(g_sFeature, BOOL, _, OnToggleItem);
}

public Action OnToggleItem(int client, const char[] featureName, VIP_ToggleState oldStatus, VIP_ToggleState &newStatus) {
    g_bEnabled[client] = (newStatus == ENABLED);
    return Plugin_Continue;
}

public void OnClientDisconnect(int client) {
    g_bHasUsedMenu[client] = false;
    g_bEnabled[client] = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    g_hTimer = CreateTimer(g_fBuyTime, Timer_DisableMenu);
    
    for (int i = 1; i <= MaxClients; i++) {
        g_bHasUsedMenu[i] = false;
        if(IsClientInGame(i) && VIP_IsClientVIP(i)) {
            g_bEnabled[i] = VIP_IsClientFeatureUse(i, g_sFeature);
        }
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    delete g_hTimer;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && VIP_IsClientVIP(client)) {
        g_bEnabled[client] = VIP_IsClientFeatureUse(client, g_sFeature);
        CreateTimer(0.5, Timer_ShowMenu, client);
    }
}

public Action Timer_ShowMenu(Handle timer, any client) {
    if(IsClientInGame(client) && IsPlayerAlive(client) && VIP_IsClientFeatureUse(client, g_sFeature)) {
        Command_VipMenu(client, 0);
    }
    return Plugin_Stop;
}

public void OnMapStart() {
    g_bEnable = true;
    char map[PLATFORM_MAX_PATH];
    GetCurrentMap(map, sizeof(map));
    
    if (strncmp(map, "35hp_", 5) == 0 || strncmp(map, "awp_", 4) == 0 || 
        strncmp(map, "aim_", 4) == 0 || strncmp(map, "fy_", 3) == 0) {
        g_bEnable = false;
    }
}

public void OnMapEnd() {
    delete g_hTimer;
}

public Action Timer_DisableMenu(Handle timer) {
    for (int i = 1; i <= MaxClients; i++) {
        g_bHasUsedMenu[i] = true;
    }
    g_hTimer = null;
    return Plugin_Stop;
}

bool CanUseMenu(int client) {
    if (!g_bEnable || !IsClientInGame(client) || !IsPlayerAlive(client) || !VIP_IsClientFeatureUse(client, g_sFeature)) {
        CPrintToChat(client, "%t", "Feature Not Available");
        return false;
    }

    if (!GetEntProp(client, Prop_Send, "m_bInBuyZone")) {
        CPrintToChat(client, "%t", "Must Be In Buy Zone"); 
        return false;
    }

    if (g_bHasUsedMenu[client]) {
        CPrintToChat(client, "%t", "Already Used Menu");
        return false;
    }

    int numRound = CS_GetTeamScore(CS_TEAM_T) + CS_GetTeamScore(CS_TEAM_CT);
    if (numRound == 0 || numRound == 1 || numRound == 15 || numRound == 16) {
        CPrintToChat(client, "%t", "No Pistol Rounds");
        return false;
    }

    return true;
}

public Action Command_VipMenu(int client, int args) {
    if (!CanUseMenu(client)) {
        return Plugin_Handled;
    }

    Menu menu = new Menu(MenuHandler_Guns);
    menu.SetTitle("%t", "Menu Title");

    for (int i = 0; i < sizeof(g_WeaponList); i++) {
        if (i == 5 && GetClientTeam(client) != CS_TEAM_CT) {
            continue;
        }
        char buffer[8];
        IntToString(i + 1, buffer, sizeof(buffer));
        menu.AddItem(buffer, g_WeaponList[i].name);
    }
    
    menu.ExitButton = true;
    menu.Display(client, 10);

    return Plugin_Handled;
}

void StoreAndRemoveWeapons(int client) {
    int primaryWeapon = GetPlayerWeaponSlot(client, 0);
    int secondaryWeapon = GetPlayerWeaponSlot(client, 1);
    
    if(primaryWeapon != -1) {
        RemovePlayerItem(client, primaryWeapon);
        RemoveEntity(primaryWeapon);
    }
    
    if(secondaryWeapon != -1) {
        RemovePlayerItem(client, secondaryWeapon);
        RemoveEntity(secondaryWeapon);
    }
}

void GiveWeapons(int client, int weaponIndex) {
    if(weaponIndex == 0) {
        return;
    }
    
    GivePlayerItem(client, g_WeaponList[weaponIndex].entity);
    GivePlayerItem(client, "weapon_deagle");
    PrintHintText(client, "%t", "Weapon Choice", g_WeaponList[weaponIndex].name);
}

public int MenuHandler_Guns(Menu menu, MenuAction action, int client, int param2) {
    switch (action) {
        case MenuAction_Select: {
            if (IsPlayerAlive(client)) {
                char selected[4];
                menu.GetItem(param2, selected, sizeof(selected));
                int weaponIndex = StringToInt(selected) - 1;
                
                if (weaponIndex == 0) {
                    return 0;
                }
                
                g_bHasUsedMenu[client] = true;
                StoreAndRemoveWeapons(client);
                
                if (weaponIndex >= 0 && weaponIndex < sizeof(g_WeaponList)) {
                    GiveWeapons(client, weaponIndex);
                }
            }
        }
        case MenuAction_End: {
            delete menu;
        }
    }
    return 0;
}

public void OnClientPostAdminCheck(int client) {
    if (VIP_IsClientVIP(client)) {
        g_bEnabled[client] = VIP_IsClientFeatureUse(client, g_sFeature);
    }
}