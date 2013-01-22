unit Bot_Lib;

interface

uses
 Windows, SysUtils,
 Engine_Reg, Func_Lib, MapObj_Lib, ItemObj_Lib, Log_Lib, NFKBrick_Lib;

const   BKEY_MOVERIGHT = 1; // bot movement
        BKEY_MOVELEFT = 2;
        BKEY_MOVEUP = 8;
        BKEY_MOVEDOWN = 16;
        BKEY_FIRE = 32;
        UID0 = 64;

var
 DLL_RegisterProc1  : procedure (AProc : pointer);
 DLL_RegisterProc2  : procedure (AProc : pointer; ProcID: Byte);
 DLL_RegisterProc3  : procedure (AProc : pointer; ProcID: Byte);
 DLL_RegisterProc4  : procedure (AProc : pointer; ProcID: Byte);
 DLL_RegisterProc5  : procedure (AProc : pointer; ProcID: Byte);
 DLL_RegisterProc6  : procedure (AProc : pointer; ProcID: Byte);
 DLL_RegisterProc7  : procedure (AProc : pointer; ProcID: Byte);
 DLL_RegisterProc8  : procedure (AProc : pointer);
 DLL_RegisterProc9  : procedure (AProc : pointer);
 DLL_RegisterProc10 : procedure (AProc : pointer);
 DLL_RegisterProc11 : procedure (AProc : pointer);
 DLL_RegisterProc12 : procedure (AProc : pointer);
 DLL_RegisterProc13 : procedure (AProc : pointer);
 DLL_MainLoop         : procedure;
 DLL_EVENT_BeginGame  : procedure;
 DLL_EVENT_MapChanged : procedure;
 DLL_EVENT_ResetGame  : procedure;
 DLL_QUERY_VERSION    : function: ShortString;

 DLL_SYSTEM_AddPlayer        : procedure (Player: TPlayerEx);
 DLL_SYSTEM_UpdatePlayer     : procedure (Player: TPlayerEx);
 DLL_SYSTEM_RemoveAllPlayers : procedure;
 DLL_SYSTEM_RemovePlayer     : procedure (DXID: Word);
 DLL_DMGReceived             : procedure (TargetDXID, AttackerDXID: Word; dmg: Word);
 DLL_ChatReceived            : procedure (DXID: Word; Text: ShortString);
 DLL_AddModel                : procedure (s: shortString);
 DLL_CMD                     : procedure (s: string);
 DLL_EVENT_ConsoleMessage    : procedure (s: shortstring);

   DLL_RegisterProcFX_FillRect: procedure(AProc: pointer);
   DLL_RegisterProcFX_FillRectMap: procedure(AProc: pointer);
   DLL_RegisterProcFX_FillRectMapEx: procedure(AProc: pointer);
   DLL_RegisterProcFX_Rectangle: procedure(AProc: pointer);
   DLL_RegisterProcFX_Line: procedure(AProc: pointer);

   DLL_RegisterProcPatch: procedure (AProc : pointer);

 procedure RegisterBotDLL(const FileName: string);

 procedure botdll_On;
 procedure botdll_Off;
 procedure botdll_AddPlayer(i: integer);
 procedure botdll_RemovePlayer(UID: integer);
 procedure botdll_ChangeMap;
 procedure botdll_ResetGame;
 procedure botdll_mainloop;
 procedure botdll_Draw;
 procedure botdll_restart;

 procedure FreeBotDll;
 procedure RegisterProc;
 procedure SendModels;

 procedure AddMessage(Text: ShortString);
 function ConCMD(Cmd: ShortString): boolean;
 procedure RegisterConsoleCommand(cmd: ShortString);

 function GetBrickStruct(x, y: Word):TNFKBrick;
 function GetObjStruct(ID: Word): TObj;
 function GetSpecObjStruct(ID: Byte): TSpecObj;
 function GetTFKObjStruct(ID: word): TMapObjStruct;
 function GetSystemVariable(Text: ShortString): ShortString;
 function Test_Blocked(x, y : Word): boolean;

 function sys_CreatePlayer(name, model: ShortString; team : Byte): integer;

 procedure RemoveBot(par: Word);
 procedure SendBotChat(DXID: Word; Text: ShortString; teamchat: boolean);

 procedure SetKeys(DXID: Word; value: Byte);
 procedure SetWeapon(DXID: Word; value: Byte);
 procedure SetBalloon(DXID: Word; value: Byte);
 procedure SetAngle(DXID: Word; value: Word);

 function GetNFKPlayer(i: Word): TPlayerEx;

 procedure debug_Textout(x, y: Word; Text: ShortString);
 procedure debug_Textoutc(x, y: Word; Text: ShortString);

//revision 5
 procedure SendConsoleCommand(CMD: shortstring);
 procedure SendConsoleHCommand(CMD: shortstring);
//text out and shapes
 procedure ExtendedTextOut(x,y: word; text : shortstring; font: byte; camera:boolean);

 procedure FX_FillRect(X, Y, Width, Height: Integer; Color: Cardinal; Effect: Integer; Camera : boolean);
 procedure FX_FillRectMap(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer; Color: Cardinal; Effect: Integer; Camera : boolean);
 procedure FX_FillRectMapEx(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer; C1, C2, C3, C4: Cardinal; Effect: Integer; Camera : boolean);
 procedure FX_Rectangle(X, Y, Width, Height: Integer; ColorLine, ColorFill: Cardinal; Effect: Integer; Camera : boolean);
 procedure FX_Line(X1, Y1, X2, Y2: Integer; Color: Cardinal; Effect: Integer; Camera : boolean);

type
   TShapeRec = record
      x1, y1, x2, y2: integer;
      x3, y3, x4, y4: integer;
      mode :integer;
      txt: string;
      cam: boolean;
      color1, color2, color3, color4, eff: cardinal;
   end;
var
   shapes : array [1..500] of TShapeRec;
   shcount: integer;

procedure PatchBot ( DXID : word; hiparam : single; loparam : single );
procedure Bot_LockResp;
procedure Bot_UnLockResp;

var
 BOT_DLL : THandle;

implementation

uses
 Constants_Lib, Menu_Lib, Player_Lib, Map_Lib, TFKEntries, Model_Lib, TFK, OpenGL;

var
   state: boolean;
   bot_nresp: boolean;

procedure Bot_LockResp;
begin
   bot_nresp:=true;
end;

procedure Bot_UnLockResp;
begin
   bot_nresp:=false;
end;

//NFK
const
BP_AIR              = 1;
    BP_HEALTH           = 2;
    BP_ARMOR            = 3;
    BP_DO_NOT_RESPAWN_BOTS = 4;
    BP_HAVE_SHOTGUN     = 5;
    BP_HAVE_GRENADE     = 6;
    BP_HAVE_ROCKET      = 7;
    BP_HAVE_SHAFT       = 8;
    BP_HAVE_RAIL        = 9;
    BP_HAVE_PLASMA      = 10;
    BP_HAVE_BFG         = 11;
    BP_AMMO_MACHINEGUN  = 12;
    BP_AMMO_SHOTGUN     = 13;
    BP_AMMO_GRENADE     = 14;
    BP_AMMO_ROCKET      = 15;
    BP_AMMO_SHAFT       = 16;
    BP_AMMO_RAIL        = 17;
    BP_AMMO_PLASMA      = 18;
    BP_AMMO_BFG         = 19;
    BP_POWERUP_REGENERATION = 20;	// amount in seconds
    BP_POWERUP_BATTLESUIT   = 21;
    BP_POWERUP_HASTE        = 22;
    BP_POWERUP_QUAD         = 23;
    BP_POWERUP_FLIGHT       = 24;
    BP_POWERUP_INVISIBILITY = 25;
    BP_DEAD                 = 26;
    DP_POS_X                = 27;
    DP_POS_Y                = 28;
    DP_INERTIA_X            = 29;
    DP_INERTIA_Y            = 30;


procedure botdll_mainloop;
begin
   shcount:=0;
   if state then
		if @DLL_MainLoop <> nil then
			DLL_MainLoop;
end;

procedure botdll_On;
begin
   Bot_UnlockResp;
   if not State then
		if @DLL_EVENT_BeginGame <> nil then
      begin
			DLL_EVENT_BeginGame;
   		State:=true;
      end;
end;

procedure botdll_Off;
begin
   State:=false;
end;

procedure botdll_restart;
begin
  Log_ConWrite(false);
   botdll_on;
  Log_ConWrite(true);
end;

procedure botdll_AddPlayer(i: integer);
begin
   if State then
  	 	if @DLL_SYSTEM_AddPlayer<>nil then
			DLL_SYSTEM_AddPlayer(GetNFKPlayer(i));
end;

procedure botdll_RemovePlayer(UID: integer);
begin
   if UID=0 then UID:=UID0;
   if State then
   	if @DLL_SYSTEM_RemovePlayer<>nil then
      	DLL_SYSTEM_RemovePlayer(UID);
end;

procedure botdll_ChangeMap;
begin
   if State then
		if @DLL_EVENT_MapChanged <> nil then
			DLL_EVENT_MapChanged;
end;

procedure botdll_ResetGame;
begin
   if State then
   	if @DLL_EVENT_ResetGame <> nil then
 			DLL_EVENT_ResetGame;
end;

procedure RegisterBotDLL(const FileName: string);
begin
try
 if BOT_DLL <> 0 then
  FreeBotDll
 else
  if FileName = '' then
   Log('Bot: ^3Syntax: ^7bot_load <bot libary name>');

 if FileName <> '' then
  if LoadDll(BOT_DLL, Engine_ModDir + spgame_folder + 'bots\' + FileName) then
   begin
   Log('Bot: ^3Loading ^7"' + FileName + '"^3...');
   LoadProc(BOT_DLL, @DLL_RegisterProc1,  'DLL_RegisterProc1');
   LoadProc(BOT_DLL, @DLL_RegisterProc2,  'DLL_RegisterProc2');
   LoadProc(BOT_DLL, @DLL_RegisterProc3,  'DLL_RegisterProc3');
   LoadProc(BOT_DLL, @DLL_RegisterProc4,  'DLL_RegisterProc4');
   LoadProc(BOT_DLL, @DLL_RegisterProc5,  'DLL_RegisterProc5');
   LoadProc(BOT_DLL, @DLL_RegisterProc6,  'DLL_RegisterProc6');
   LoadProc(BOT_DLL, @DLL_RegisterProc7,  'DLL_RegisterProc7');
   LoadProc(BOT_DLL, @DLL_RegisterProc8,  'DLL_RegisterProc8');
   LoadProc(BOT_DLL, @DLL_RegisterProc9,  'DLL_RegisterProc9');
   LoadProc(BOT_DLL, @DLL_RegisterProc10, 'DLL_RegisterProc10');
   LoadProc(BOT_DLL, @DLL_RegisterProc11, 'DLL_RegisterProc11');
   LoadProc(BOT_DLL, @DLL_RegisterProc12, 'DLL_RegisterProc12');
   LoadProc(BOT_DLL, @DLL_RegisterProc13, 'DLL_RegisterProc13');

   LoadProc(BOT_DLL, @DLL_MainLoop,         'DLL_MainLoop');
   LoadProc(BOT_DLL, @DLL_EVENT_BeginGame,  'DLL_EVENT_BeginGame');
   LoadProc(BOT_DLL, @DLL_EVENT_MapChanged, 'DLL_EVENT_MapChanged');
   LoadProc(BOT_DLL, @DLL_EVENT_ResetGame,  'DLL_EVENT_ResetGame');
   LoadProc(BOT_DLL, @DLL_QUERY_VERSION,    'DLL_QUERY_VERSION');

   LoadProc(BOT_DLL, @DLL_SYSTEM_AddPlayer,        'DLL_SYSTEM_AddPlayer');
   LoadProc(BOT_DLL, @DLL_SYSTEM_UpdatePlayer,     'DLL_SYSTEM_UpdatePlayer');
   LoadProc(BOT_DLL, @DLL_SYSTEM_RemoveAllPlayers, 'DLL_SYSTEM_RemoveAllPlayers');
   LoadProc(BOT_DLL, @DLL_SYSTEM_RemovePlayer,     'DLL_SYSTEM_RemovePlayer');
   LoadProc(BOT_DLL, @DLL_DMGReceived,             'DLL_DMGReceived');
   LoadProc(BOT_DLL, @DLL_ChatReceived,            'DLL_ChatReceived');
   LoadProc(BOT_DLL, @DLL_AddModel,                'DLL_AddModel');
   LoadProc(BOT_DLL, @DLL_CMD,                     'DLL_CMD');
   LoadProc(BOT_DLL, @DLL_RegisterProcFX_FillRect,  'DLL_RegisterProcFX_FillRect');
   LoadProc(BOT_DLL, @DLL_RegisterProcFX_FillRectMap, 'DLL_RegisterProcFX_FillRectMap');
   LoadProc(BOT_DLL, @DLL_RegisterProcFX_FillRectMapEx, 'DLL_RegisterProcFX_FillRectMapEx');
   LoadProc(BOT_DLL, @DLL_RegisterProcFX_Rectangle, 'DLL_RegisterProcFX_Rectangle');
   LoadProc(BOT_DLL, @DLL_RegisterProcFX_Line, 'DLL_RegisterProcFX_Line');
   LoadProc(BOT_DLL, @DLL_RegisterProcPatch, 'DLL_RegisterProcPatch');

   RegisterProc;

   Log('Bot: "' + FileName + '"^2 loaded');
	if @DLL_EVENT_BeginGame <> nil then
 		DLL_EVENT_BeginGame;
   state:=true;
   end
  else
   begin
   BOT_DLL := 0;
   Log('Bot: ^1Error: ^7"' + FileName + '"^1 is not TFK bot');
   end;
 except
  Log('Bot: ^1Fatal error: please restart TFK (recommended)');
 end;
end;

procedure FreeBotDll;
begin
// Удаляем всех игроков с карты
shcount:=0;
Map.pl_deleteall_ptype(C_PLAYER_BOT);

try
 if BOT_DLL <> 0 then
  begin
  FreeDll(BOT_DLL);
  Log('Bot: ^2Free bot dll');
  end;
except
 Log('Bot: ^1Fatal error: while free bot libary');
end;
DLL_RegisterProc1  := nil;
DLL_RegisterProc2  := nil;
DLL_RegisterProc3  := nil;
DLL_RegisterProc4  := nil;
DLL_RegisterProc5  := nil;
DLL_RegisterProc6  := nil;
DLL_RegisterProc7  := nil;
DLL_RegisterProc8  := nil;
DLL_RegisterProc9  := nil;
DLL_RegisterProc10 := nil;
DLL_RegisterProc11 := nil;
DLL_RegisterProc12 := nil;
DLL_RegisterProc13 := nil;

DLL_MainLoop         := nil;
DLL_EVENT_BeginGame  := nil;
DLL_EVENT_MapChanged := nil;
DLL_EVENT_ResetGame  := nil;
DLL_QUERY_VERSION    := nil;

DLL_SYSTEM_AddPlayer        := nil;
DLL_SYSTEM_UpdatePlayer     := nil;
DLL_SYSTEM_RemoveAllPlayers := nil;
DLL_SYSTEM_RemovePlayer     := nil;
DLL_DMGReceived             := nil;
DLL_ChatReceived            := nil;
DLL_AddModel                := nil;

state:=false;
end;

procedure RegisterProc;
var
 i: integer;
begin
if @DLL_RegisterProc1 <> nil then
 DLL_RegisterProc1(@SetAngle);

if @DLL_RegisterProc2 <> nil then
 begin
 DLL_RegisterProc2(@AddMessage, 1);
 DLL_RegisterProc2(@RegisterConsoleCommand, 2);
 DLL_RegisterProc2(@SendConsoleCommand, 3);
 DLL_RegisterProc2(@SendConsoleHCommand, 4);
 end;

if @DLL_RegisterProc3 <> nil then
 DLL_RegisterProc3(@GetSystemVariable, 1);

if @DLL_RegisterProc4 <> nil then
 DLL_RegisterProc4(@sys_CreatePlayer, 0);

if @DLL_RegisterProc5 <> nil then
 begin
 DLL_RegisterProc5(@SetKeys, 1);
 DLL_RegisterProc5(@SetWeapon, 3);
 DLL_RegisterProc5(@SetBalloon, 4);
 end;

if @DLL_RegisterProc6 <> nil then
begin
 DLL_RegisterProc6(@Test_Blocked, 1);
 DLL_RegisterProc6(@GetTFKObjStruct, 2);
end;

if @DLL_RegisterProc7 <> nil then
 begin
 DLL_RegisterProc7(@debug_Textout, 1);
 DLL_RegisterProc7(@debug_Textoutc, 2);
 end;

if @DLL_RegisterProc8 <> nil then
 DLL_RegisterProc8(@GetBrickStruct);

if @DLL_RegisterProc9 <> nil then
 DLL_RegisterProc9(@GetObjStruct);

if @DLL_RegisterProc10 <> nil then
 DLL_RegisterProc10(@GetSpecObjStruct);

if @DLL_RegisterProc11 <> nil then
 DLL_RegisterProc11(@RemoveBot);

if @DLL_RegisterProc12 <> nil then
 DLL_RegisterProc12(@SendBotChat);

if @DLL_RegisterProc13 <> nil then
 DLL_RegisterProc13(@ExtendedTextOut);


if @DLL_RegisterProcFX_FillRect<>nil then
   DLL_RegisterProcFX_FillRect(@FX_FillRect);
if @DLL_RegisterProcFX_FillRectMap<>nil then
   DLL_RegisterProcFX_FillRectMap(@FX_FillRectMap);
if @DLL_RegisterProcFX_FillRectMapEx<>nil then
   DLL_RegisterProcFX_FillRectMapEx(@FX_FillRectMapEx);
if @DLL_RegisterProcFX_Rectangle<>nil then
   DLL_RegisterProcFX_Rectangle(@FX_Rectangle);
if @DLL_RegisterProcFX_Line<>nil then
   DLL_RegisterProcFX_Line(@FX_Line);

if @DLL_RegisterProcPatch<>nil then
   DLL_RegisterProcPatch(@PatchBot);

SendModels;

if @DLL_SYSTEM_AddPlayer <> nil then
 for i := 0 to Map.Players - 1 do
  DLL_SYSTEM_AddPlayer(GetNFKPlayer(i));

if not inMenu then
 begin
 if @DLL_EVENT_BeginGame <> nil then
  DLL_EVENT_BeginGame;
 if @DLL_EVENT_MapChanged <> nil then
  DLL_EVENT_MapChanged;
 if @DLL_EVENT_ResetGame <> nil then
  DLL_EVENT_ResetGame;
 end;
end;

procedure SendModels;
var
 md  : TFindData;
 sd  : TFindData;
 dir : string;
 i: integer;
begin
if @DLL_AddModel = nil then Exit;

dir := Engine_Dir + Engine_ModDir + 'models\';

if FindFirst(dir + '*', md) then
 repeat
  if md.Data.cFileName[0] = '.' then continue;
  if DirectoryExists(dir + md.Data.cFileName) then
   if FindFirst(dir + md.Data.cFileName + '\*.tml', sd) then
    repeat
     for i:=low(skins) to high(skins) do
        DLL_AddModel(LowerCase(ShortString(md.Data.cFileName) + '+' + Skins[i].name));
    until not FindNext(sd);
 until not FindNext(md);
end;

procedure RegisterConsoleCommand(Cmd: ShortString);
begin
Console_CmdReg(cmd, @ConCMD);
end;

procedure AddMessage(Text: ShortString);
begin
   Log(Text);
end;

function ConCMD(Cmd: ShortString): boolean;
begin
if Map.demoplay then
begin
	Result:=false;
   Exit;
end;
if @DLL_CMD <> nil then
 begin
 DLL_CMD(cmd);
 Result := true;
 end
else
 Result := false;
end;

function GetBrickStruct(x, y : Word):TNFKBrick;
begin
   with Map do
   begin
   	if (x<nfk_w) and
         (y<nfk_h) then
   		Result:=nfk_brk[x, y]
      else
      begin
      	fillchar(Result, sizeof(Result), 0);
      	Result.image:=54;
      	Result.block:=true;
      end;
      if Result.y>0 then
         if Result.respawnable then
    			Result.respawntime := TItemObj(Obj[Result.y-1]).Timer
         else Result.block:=Result.block or TNFKDoor(Obj[Result.y-1]).Active;
  	end;
end;

function GetObjStruct(ID: Word): TObj;
begin
FillChar(Result, SizeOf(Result), 0);
Result.dead:=1;
// Ну а тут будет код :)
// Ну ясен пень что не собака зарытая...
end;

function GetSpecObjStruct(ID: Byte): TSpecObj;
begin
FillChar(Result, SizeOf(Result), 0);
Result.active:=true;
with Map do
 if ID < Obj.Count then
  case Obj[ID].ObjType of

   otTeleport, otPortal:
    begin
    Result.active  := true;
    Result.objtype := 1;
    Result.x       := Obj[ID].x;
    Result.y       := Obj[ID].y;
    Result.length  := Obj[ID].struct.gotox;
    Result.dir     := Obj[ID].struct.gotoy;
    end;

   otNFKDoor:
    begin
    Result.active  := true;
    Result.objtype := 3;
    Result.special := TNFKDoor(Obj[ID]).Target_Name;
    //odd(orient) - вертикальная ли дверь
    Result.orient  := Ord(Obj[ID].Struct.orient < 2) +
                      Ord(TNFKDoor(Obj[ID]).Struct.opened)*2;
    Result.dir     := TNFKDoor(Obj[ID]).timer;
    Result.x       := Obj[ID].Struct.x;
    Result.y       := Obj[ID].Struct.y;
    if odd(Result.orient) then
     Result.length := Obj[ID].height
    else
     Result.length := Obj[ID].width;
    end;

   otArmor, otHealth, otPowerUp, otWeapon, otAmmo:
   begin
    Result.active  := true;
    Result.objtype := 100+ord(Obj[ID].ObjType);
    Result.x       := Obj[ID].x;
    Result.y       := Obj[ID].y;
    Result.special := Obj[ID].Struct.itemID;
    Result.wait    := TItemObj(Obj[ID]).timer;
   end;

   end //case
   else result.active:=false;
// аналогично предыдущему :)
end;

function GetTFKObjStruct(ID: word): TMapObjStruct;
begin
FillChar(Result, SizeOf(Result), 0);
with Map do
 if ID < Obj.Count then
 begin
    Result:=Obj[ID].struct;
//    if Obj[ID].ObjType in ItemObjs then
//       Result.temp:=TItemObj(Obj[ID]).timer;
 end;
end;

function GetSystemVariable(Text: ShortString): ShortString;
begin
Result := '0';
if Text = 'rootdir' then
 begin
 Result := ExtractFileDir(ParamStr(0)) + '\' + Engine_ModDir;
 Exit;
 end;

if Text = 'mapname' then
 begin
 Result := Map.GetFileName;
 Exit;
 end;

if Text = 'mapauthor' then
 begin
 Result := Map.Author;
 Exit;
 end;

if Text = 'gametype' then
 begin
    Result := 'DM';
    case gametype of
       GT_FFA: Result := 'DM';
       GT_RAIL: Result:= 'RAIL';
       GT_TDM: Result:= 'TDM';
       GT_CTF: Result:= 'CTF';
    end;
 Exit;
 end;

if Text = 'bricks_x' then
 begin
 Result := IntToStr(Map.Width);
 Exit;
 end;

if Text = 'bricks_y' then
 begin
 Result := IntToStr(Map.Height);
 Exit;
 end;

if Text = 'sv_maxplayers' then
 begin
 Result := IntToStr(sv_maxplayers); // Исправим
 Exit;
 end;

if Text = 'playerscount' then
 if Map <> nil then
  begin
  Result := IntToStr(Map.Players); // Исправим
  Exit;
  end;

//REVISION 5
if Text='gamedir' then
   Result:=Engine_ModDir+spgame_folder;
if (Text='rev5') or (Text='rev6') then
   Result:='yes';
if Text='localdxid' then
begin
   if Map.pl_find(-1, C_PLAYER_p1) then
      Result:=IntToStr(Map.pl_current.UID)
   else result:='-1';
   if Map.pl_find(-1, C_PLAYER_p2) then
      Result:=IntToStr(Map.pl_current.UID)
   else result:='-2';
end;
//TFK VARIABLES
if Text = 'tfk' then
   Result:='yes';
if Text = 'objcount' then
   if Map<>nil then
   	Result:=IntToStr(Map.Obj.Count);
end;

function sys_CreatePlayer(name, model: ShortString; team : Byte): integer;
var
   pl: TPlayer;
begin
   pl:=Map.pl_add(C_PLAYER_BOT, name, model, true);
   if pl<>nil then
   begin
      Log_ConWrite(false);
      if team=2 then team:=0 else team:=1+team;
      if (gametype and GT_TEAMS>0) then
         Map.TeamJoin(pl.UID, team);
      Log_ConWrite(true);

      Result:=pl.UID;
 		Log_AddPlayer(map.Player[High(Map.Player)]);
   end else Result:=-1;
end;

procedure RemoveBot(par: Word);
begin
if Map <> nil then
 	with Map do
  		if pl_find(par, C_PLAYER_BOT) then
    	begin
 	 		Log_RemovePlayer(pl_current);
      	pl_delete_current;
    	end;
end;

procedure SendBotChat(DXID: Word; Text: ShortString; teamchat: boolean);
begin
// Исправим :)
	Map.Say(DXID, text);
end;

function Test_Blocked(x, y : Word):boolean;
begin
	Result := Map.block_s(x, y);
end;

procedure SetKeys(DXID: Word; value: Byte);
var
 p : TPlayer;
 i : integer;
begin
if not Map.pl_find(DXID, C_PLAYER_BOT) then Exit
else p:=Map.pl_current;

for i := Low(p.key) to High(p.key) do
 p.Key[i].Down := false;

p.Key[KEY_RIGHT].Down := BKEY_MOVERIGHT and value > 0;
p.Key[KEY_LEFT].Down  := BKEY_MOVELEFT and value > 0;
p.Key[KEY_UP].Down    := BKEY_MOVEUP and value > 0;
p.Key[KEY_DOWN].Down  := BKEY_MOVEDOWN and value > 0;
p.Key[KEY_FIRE].Down  := BKEY_FIRE and value > 0;
end;

procedure SetWeapon(DXID : Word ; value: Byte);
var
 	p : TPlayer;
begin
   with Map do
   if pl_find(DXID, C_PLAYER_BOT) then
   begin
      p:=pl_current;
		if (p.SwitchTicker = 0) then
 		begin
 			p.next_weapon   := value;
 			p.lastwpnchange := 0;
 		end;
   end;
end;

procedure SetBalloon(DXID : Word ; value: Byte);
begin
 with Map do
 if pl_find(DXID, C_PLAYER_BOT) then
    pl_current.balloon:=boolean(value);
end;

procedure SetAngle(DXID: Word ; value: Word);
begin
 with Map do
 if pl_find(DXID, C_PLAYER_BOT) then
 begin
 	if value > 180 then value := 360 - value;
 	pl_current.Angle := value;
 end;
end;

function GetNFKPlayer(i: Word): TPlayerEx;
var
 p : TPlayer;
begin
FillChar(Result, sizeof(result), 0);

with Map, Result do
 if i < Players then
  begin
  p := Player[i];
  if p = nil then Exit;
  netname       := p.Name;
  if p.uid>0 then
  	DXID          := p.UID
   else DXID:=UID0;
  dead          := p.dead and not p.resp;
  bot           := p.playertype = C_PLAYER_BOT;
  crouch        := p.Crouch;
  balloon       := p.balloon;
  team          := p.team;
  have_rl       := p.Has_wpn[WPN_ROCKET] = 1;
  have_gl       := p.Has_wpn[WPN_GRENADE] = 1;
  have_rg       := p.Has_wpn[WPN_RAILGUN] = 1;
  have_bfg      := p.Has_wpn[WPN_BFG] = 1;
  have_sg       := p.Has_wpn[WPN_ShotGun] = 1;
  have_mg       := p.Has_wpn[WPN_MachineGun] = 1;
  have_sh       := p.Has_wpn[WPN_Shaft] = 1;
  have_pl       := p.Has_wpn[WPN_PLASMA] = 1;
  refire        := p.ReloadTicker;
  weapchg       := p.SwitchTicker;
  weapon        := p.cur_weapon;
  threadweapon  := p.next_weapon;
  dir		:= 1 - Byte(p.left) + Byte(p.Crouch)*2;
  ammo_gl       := p.ammo[WPN_GRENADE];
  ammo_rg       := p.ammo[WPN_RAILGUN];
  ammo_bfg      := p.ammo[WPN_BFG];
  ammo_sg       := p.ammo[WPN_ShotGun];
  ammo_mg       := p.ammo[WPN_MachineGun];
  ammo_sh       := p.ammo[WPN_Shaft];
  ammo_pl       := p.ammo[WPN_PLASMA];
  x             := p.Pos.X;
  y             := p.Pos.Y;
  InertiaX      := p.dpos.X;
  InertiaY      := p.dpos.Y;
  health        := p.Health;
  armor         := p.Armor;
  balloon       := p.balloon;
  item_quad:=p.powerups[QUAD_ID] div 50;
  item_regen:=p.powerups[REGEN_ID] div 50;
  item_invis:=p.powerups[INV_ID] div 50;
  item_haste:=p.powerups[HASTE_ID] div 50;
  item_flight:=p.powerups[FLIGHT_ID] div 50;
  item_battle:=p.powerups[BATTLESUIT_ID] div 50;
  end;
end;


procedure debug_Textout(x, y: Word; Text: ShortString);
begin
// ага щаассс ;)
//да, щас выведем
   ExtendedTextOut(x, y, text, 0, true);
end;

procedure debug_Textoutc(x, y: Word; Text: ShortString);
begin
// типа вывел текст :)
//да, щас выведем
   ExtendedTextOut(x, y, text, 0, false);
end;

//revision5

procedure SendConsoleCommand(CMD: shortstring);
begin
   if pos('exec ', CMD) = 1 then
      CMD:=copy(cmd, 1, 5)+spgame_folder+copy(cmd, 6, length(cmd));
   Console_CMD(CMD);
end;

procedure SendConsoleHCommand(CMD: shortstring);
begin
   Log_Conwrite(false);
   SendConsoleCommand(CMD);
   Log_Conwrite(true);
end;

procedure ExtendedTextOut(x,y: word; text : shortstring; font: byte; camera:boolean);
begin
   inc(shcount);
   fillchar(shapes[shcount], sizeof(TShapeRec), 0);
   with shapes[shcount] do
   begin
      mode:=1;
      cam:=camera;
      x1:=x;y1:=y;
      txt:=Text;
      color1:=font;
   end;
end;

procedure FX_FillRect(X, Y, Width, Height: Integer; Color: Cardinal; Effect: Integer; Camera : boolean);
begin
   inc(shcount);
   fillchar(shapes[shcount], sizeof(TShapeRec), 0);
   with shapes[shcount] do
   begin
      mode:=2;
      cam:=camera;
      x1:=x;y1:=y;
      x2:=x+Width;y2:=y+Height;
      color1:=Color;
      Eff:=Effect;
   end;
end;

procedure FX_FillRectMap(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer; Color: Cardinal; Effect: Integer; Camera : boolean);
begin
   inc(shcount);
   fillchar(shapes[shcount], sizeof(TShapeRec), 0);
   shapes[shcount].x1:=x1;
   shapes[shcount].y1:=y1;
   shapes[shcount].x2:=x2;
   shapes[shcount].y2:=y2;
   shapes[shcount].x3:=x3;
   shapes[shcount].y3:=y3;
   shapes[shcount].x4:=x4;
   shapes[shcount].y4:=y4;
   with shapes[shcount] do
   begin
      mode:=3;
      cam:=camera;
      color1:=Color;
      Eff:=Effect;
   end;
end;

procedure FX_FillRectMapEx(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer; C1, C2, C3, C4: Cardinal; Effect: Integer; Camera : boolean);
begin
   inc(shcount);
   fillchar(shapes[shcount], sizeof(TShapeRec), 0);
   shapes[shcount].x1:=x1;
   shapes[shcount].y1:=y1;
   shapes[shcount].x2:=x2;
   shapes[shcount].y2:=y2;
   shapes[shcount].x3:=x3;
   shapes[shcount].y3:=y3;
   shapes[shcount].x4:=x4;
   shapes[shcount].y4:=y4;
   with shapes[shcount] do
   begin
      mode:=4;
      cam:=camera;
      color1:=C1;
      color2:=C2;
      color3:=C3;
      color4:=C4;
      Eff:=Effect;
   end;
end;

procedure FX_Rectangle(X, Y, Width, Height: Integer; ColorLine, ColorFill: Cardinal; Effect: Integer; Camera : boolean);
begin
   inc(shcount);
   fillchar(shapes[shcount], sizeof(TShapeRec), 0);
   with shapes[shcount] do
   begin
      mode:=5;
      cam:=camera;
      x1:=x;y1:=y;
      x2:=x+Width;y2:=y+Height;
      color1:=ColorLine;
      color2:=ColorFill;
      Eff:=Effect;
   end;
end;

procedure FX_Line(X1, Y1, X2, Y2: Integer; Color: Cardinal; Effect: Integer; Camera : boolean);
begin
   inc(shcount);
   fillchar(shapes[shcount], sizeof(TShapeRec), 0);
   shapes[shcount].x1:=x1;
   shapes[shcount].y1:=y1;
   shapes[shcount].x2:=x2;
   shapes[shcount].y2:=y2;
   with shapes[shcount] do
   begin
      mode:=6;
      cam:=camera;
      color1:=Color;
      Eff:=Effect;
   end;
end;

//прорисовка shape'ов

procedure botdll_Draw;
var
   i, x0, y0: integer;
   sh: TShapeRec;
begin
   for i:=1 to shcount do
   begin
      sh:=shapes[i];
      if not sh.cam then
      begin
         x0:=trunc(Map.Camera.Pos.X-xglWidth div 2);
         y0:=trunc(Map.Camera.Pos.Y-xglHeight div 2);
      end else
      begin
         x0:=0;
         y0:=0;
      end;

      with sh do
      case mode of
         0:
            TextOut(x1-x0, y1-y0, PChar(sh.Txt));
         1:
            Text_TagOut(x1-x0, y1-y0, @Console.Font, false, PChar(sh.Txt));
         //FX_Rectangle
         2:
         begin
            xglTex_Disable;
            glColor4f(GetRValue(color2)/255, GetBValue(color2)/255, GetBValue(color2)/255, 1);

            glBegin(GL_QUADS);
               glVertex2f(x1-x0, y1-y0);
               glVertex2f(x1-x0, y2-y0);
               glVertex2f(x2-x0, y2-y0);
               glVertex2f(x2-x0, y1-y0);
            glEnd;

            glColor4f(GetRValue(color1)/255, GetBValue(color1)/255, GetBValue(color1)/255, 1);

            glBegin(GL_LINE_STRIP);
               glVertex2f(x1-x0, y1-y0);
               glVertex2f(x1-x0, y2-y0);
               glVertex2f(x2-x0, y2-y0);
               glVertex2f(x2-x0, y1-y0);
               glVertex2f(x1-x0, y1-y0);
            glEnd;
         end;

      end;//case
   end;
end;

procedure PatchBot ( DXID : word; hiparam : single; loparam : single );
var
   pl: TPlayer;
   p: TPlayerStruct;

begin
   if loparam<0 then loparam:=0;
   pl:=Map.PlayerByUID(DXID);
   if pl<>nil then
   begin
      p:=pl.pstruct;
      case round(hiparam) of
       BP_HEALTH : pl.Health:=round(loparam);
       BP_ARMOR  : pl.Armor:=round(loparam);
//    BP_DO_NOT_RESPAWN_BOTS : ;
       BP_HAVE_SHOTGUN..BP_HAVE_BFG :
       if WeaponObjs[round(hiparam)-3]<>nil then
       begin
         p.Has_WPN[round(hiparam)-3]:=ord(loparam=1);
         if p.Ammo[round(hiparam)-3]=0 then
            p.Ammo[round(hiparam)-3]:=10;
       end;
       BP_AMMO_MACHINEGUN..BP_AMMO_BFG:
       if WeaponObjs[round(hiparam)-3]<>nil then
         if (loparam<5000) and (loparam>=0) then
            p.Ammo[round(hiparam)-11]:=round(loparam)
            else p.Ammo[round(hiparam)-11]:=5000;
       BP_POWERUP_REGENERATION..BP_POWERUP_INVISIBILITY :
         if PowerUpObjs[round(hiparam)+3]<>nil then
         if (loparam<50) and (loparam>=0) then
            p.PowerUps[round(hiparam)+3]:=round(loparam*50)
           else p.PowerUps[round(hiparam)+3]:=2500;	// amount in seconds
       DP_POS_X                : p.Pos.X := loparam;
       DP_POS_Y                : p.Pos.Y := loparam;
       DP_INERTIA_X            : p.dPos.X := loparam;
       DP_INERTIA_Y            : p.dPos.Y := loparam;
      end;//case
      pl.pstruct:=p;
   end;
end;

end.
