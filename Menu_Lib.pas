unit Menu_Lib;

interface

uses
 Windows, Messages, Engine_Reg, OpenGL, SysUtils,
 ObjAnim_Lib, Math_Lib, Type_Lib, Graph_Lib, MyMenu,
 Constants_Lib, Model_Lib,
 Arena_Lib;

 procedure Menu_Init;
 procedure Menu_Free;

 procedure Menu_Update;
 procedure Menu_Draw;
 procedure Menu_Message(Msg: DWORD; wParam: Longint; lParam: LongInt);
 procedure Menu_Proc(ID : integer; Param : integer);

const
 BTN_HOTSEAT = 1;
 BTN_MULTI   = 2;
 BTN_SETUP   = 3;
 BTN_DEMOS   = 4;
 BTN_MODS    = 5;
 BTN_CREDITS = 6;
 BTN_EXIT    = 7;

 BTN_BACK    = 8;  // Назад в главное меню
 BTN_FIGHT   = 9;  // Запуск игры на карте карты
 BTN_PLAY    = 10; // Кнопка проигрывания демки
 BTN_LOAD    = 11; // Смена мода
 BTN_PLAYER1 = 12;
 BTN_PLAYER2 = 13;

 BTN_DISPLAY = 14;
 BTN_SOUND   = 15;

 BTN_MULTICREATE = 16;

 BTN_CONNECT = 20;
 BTN_REFRESH = 21;
// BTN_SEARCH  = 22;

 BTN_ADDIP   = 23;
 BTN_ACCEPT  = 24;

 EDIT_NAME   = 32;
 EDIT_YESNO  = 33;
 EDIT_STRING = 34;
 EDIT_BINDS  				= 40;
 EDIT_BIND_LEFT  			= 41;
 EDIT_BIND_RIGHT  		= 42;
 EDIT_BIND_STRAFELEFT  	= 41;
 EDIT_BIND_STRAFERIGHT  = 42;
 EDIT_BIND_CROUCH  		= 43;
 EDIT_BIND_FIRE  			= 44;

 EDIT_IP = 50;

 BTN_RESTART = 100;
 BTN_LEAVEARENA = 101;

 FLB_MAP  = 200;
 FLB_DEMO = 201;
 FLB_MODS = 202;

 LB_MODELS  = 205;
 LB_SKINS   = 206;
 LB_SERVERS = 207;

 DIS__MODE : array [0..4] of string = ('320x240', '640x480', '800x600', '1024x768', '1600x1200');
 DIS__BPP  : array [0..1] of string = ('16', '32');
 DIS__FREQ : array [0..3] of string = ('60', '75', '85', '100');

var
 WND_MAIN    : TMyWindow;
 WND_HOTSEAT : TMyWindow;
 WND_SETUP   : TMyWindow;
 WND_PLAYER1 : TMyWindow;
 WND_PLAYER2 : TMyWindow;
 WND_DISPLAY : TMyWindow;
 WND_SOUND   : TMyWindow;
 WND_DEMOS   : TMyWindow;
 WND_MODS    : TMyWindow;
 WND_GAME    : TMyWindow;
 WND_MP_INTERNET: TMyWindow;
 WND_MULTICREATE: TMyWindow;

var
 MP_lb: TListBox;
 IPEdit: TEdit;

 SayEdit : TEdit;
 onSay   : boolean;

type
 TModelName = array of string;

var
 inMenu : boolean;
 ModelName : TModelName;

 MenuBG  : PaRGB;
 MenuTex : TTexData;

 dis_mode : Byte;
 dis_bpp  : Byte;
 dis_freq : Byte;
 
const
 MenuBg_X = 128;
 MenuBg_Y = 128;

procedure CallWindow(window: TMyWindow);
procedure CallBack;
procedure CallGameMenuON;
procedure CallGameMenuOFF;
procedure CallMainMenu;
procedure Menu_SetModel(pl: integer);

procedure Menu_AddServer(IP: string; Port: word; HostName, MapName: string;
	Ping: cardinal; players, max: integer; reason: string);
procedure Menu_RefreshServers;
procedure Menu_AddIP(str: string);
function Menu_MP: boolean;
procedure CalcMenuBG;

implementation

uses
 TFK, Game_Lib, Func_Lib, Map_Lib;

var
 MouseTex : TObjTex;
 RefBtn   : TMyControl;
 RefLabel : TLabel;

procedure Menu_GetActive;
var
 i : integer;
begin
with ActiveWindow do
 for i := 0 to ChildCount - 1 do
  with Childs[i] do
   begin
   if PointInRect(MousePos.X, MousePos.Y, Rect) then
    begin
    if not Active then
     begin
     if sound_off=0 then
      snd_Play(MenuSnd_2, false, 0, 0, true);
     Active := true;
     break;
     end;
    end
   else
    if Active then
     Active := false;
  end;
end;

procedure CallWindow(window: TMyWindow);
begin
	if ActiveWindow<>nil then
 		window.prevwindow:=ActiveWindow;
  	ActiveWindow := window;
   ActiveWindow.Show;
   if sound_off=0 then
   	snd_Play(MenuSnd_1, false, 0, 0, true);
Menu_GetActive;
end;

procedure CallBack;
var
   wnd : TMyWindow;
begin
   wnd:=ActiveWindow;
   if ActiveWindow.prevwindow<>nil then
   begin
      ActiveWindow:=ActiveWindow.prevwindow;
   	ActiveWindow.Show;
   end
      else inMenu:=false;
   wnd.prevwindow:=nil;
   if sound_off=0 then
   	snd_Play(MenuSnd_3, false, 0, 0, true);
Menu_GetActive;        
end;

procedure Menu_SetModel(pl: integer);
var
 i    : integer;
 str  : string;
 s, n : string;
 wnd  : TMyWindow;
begin
if pl = 1 then
 begin
 str := p1model;
 wnd := WND_PLAYER1;
 end
else
 begin
 str := p2model;
 wnd := WND_PLAYER2;
 end;

//if (wnd = nil) or (wnd <> ActiveWindow) then Exit;

i := Pos('+', str);
if i <> 0 then
 begin
 n := AnsiLowerCase(Copy(str, 1, i - 1));
 s := AnsiLowerCase(Copy(str, i + 1, Length(str)));
 end
else
 begin
 s := 'default';
 n := AnsiLowerCase(str);
 end;

with TListBox(wnd.Childs[0]) do
 for i := 1 to items.rowcount - 1 do
  if AnsiLowerCase(items[0, i]) = n then
   begin
   index := i;
   break;
   end;

with TListBox(wnd.Childs[1]) do
 for i := 1 to items.rowcount - 1 do
  if AnsiLowerCase(items[0, i]) = s then
   begin
   index := i;
   break;
   end;
end;

function Menu_PlayerCreate(pl: integer): TMyWindow;
var
 i : integer;
begin
Result := AddWindow(TMyWindow.Create);
with Result do
 begin
 with TListBox(AddChild(TListBox.Create(@Menu_Proc,  LB_MODELS))) do
  begin
  SetSize(1, Length(ModelName) + 1);
  Items[0, 0] := 'Model';
  HAlign      := ahNone;
  X           := 25;
  Y           := 250;
  Width       := 96;
  Height      := 116;
  for i := 1 to Length(ModelName) do
   items[0, i] := ModelName[i - 1];
  Items.SortAsc(0, 0);
  end;

 with TListBox(AddChild(TListBox.Create(@Menu_Proc,  LB_SKINS))) do
  begin
  HAlign      := ahNone;
  X           := 121;
  Y           := 250;
  Width       := 96;
  Height      := 116;

  SetSize(1, Length(Skins) + 2);
  Items[0, 0] := 'Skin';
  items[0, 1] := 'default';
  for i := 2 to Length(Skins) + 1 do
   items[0, i] := Skins[i - 1].Name;
  index := 0;
  end;

 with TModelViewer(AddChild(TModelViewer.Create)) do
  begin
  X           := 268;
  Y           := 320;
  end;

 AddChild(TTexLabel.Create(nil, 0, 'player' + IntToStr(pl)));

 AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).HAlign := ahLeft;
 def_x  := 32;
 def_y  := 64;
 def_cx := 0;
 def_cy := 20;
 if pl = 1 then
  with AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @p1name, 'Name', 'name', VT_STRING)) as TEdit do
   begin
   Tab := 8;
   MaxLength := 24;
   end
 else
  with AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @p2name, 'Name', 'p2name', VT_STRING)) as TEdit do
   begin
   Tab := 8;
   MaxLength := 24;
   end;

 if pl = 1 then
  begin
     def_y:=def_y+def_cy;
  	  TEdit(AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @mouse_sensitivity, 'Mouse sensitivity', 'mouse_sensitivity', VT_BYTE))).MaxLength := 1;
  	  AddChild(TEnumEdit.Create(@Menu_Proc, EDIT_YESNO, @mouselook,
        3, [0, 1, 2], ['off', 'simple', 'on'], ['0', '1', '2'],
      'Mouse look', 'mouselook'));
  	  TEdit(AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @mouselook_pitch, 'Look sensitivity x', 'mouselook_pitch', VT_BYTE))).MaxLength := 1;
  	  TEdit(AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @mouselook_yaw, 'Look sensitivity y', 'mouselook_yaw', VT_BYTE))).MaxLength := 1;
  	  TEdit(AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @mouselook_offset, 'Look offset', 'mouselook_offset', VT_BYTE))).MaxLength := 1;
  	  AddChild(TYesNoEdit.Create(@Menu_Proc, EDIT_YESNO, @mouselook_strafe, 'Always use strafe', 'mouselook_strafe'));
  end
 else
  begin
  	AddChild(TYesNoEdit.Create(@Menu_Proc, EDIT_YESNO, @p2disable, 'Disabled', 'p2disable'));
   def_y:=def_y+def_cy;
  	TEdit(AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @keyb_sensitivity, 'Keyboard sensitivity', 'keyb_sensitivity', VT_BYTE)) ).MaxLength:=1;
  end;

 def_y:=224;
 if pl = 1 then
  AddChild(TYesNoEdit.Create(@Menu_Proc, EDIT_YESNO, @p1nextwpn_skipempty, 'Skip empty weapon', 'p1nextwpn_skipempty'))
 else
  AddChild(TYesNoEdit.Create(@Menu_Proc, EDIT_YESNO, @p2nextwpn_skipempty, 'Skip empty weapon', 'p2nextwpn_skipempty'));
 def_x  := 330; def_y  := 50;
 def_cx := 0;   def_cy := 18;

   AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BIND_LEFT, pl, KEY_LEFT));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BIND_RIGHT, pl, KEY_RIGHT));
   AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BIND_STRAFELEFT, pl, KEY_STRAFELEFT));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BIND_STRAFERIGHT, pl, KEY_STRAFERIGHT));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_UP));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BIND_CROUCH, pl, KEY_DOWN));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BIND_FIRE, pl, KEY_FIRE));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_NEXTWPN));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_PREVWPN));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_RUP));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_RDOWN));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_RCENTER));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON+1));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON+2));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON+3));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON+4));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON+5));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON+6));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON+7));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_WEAPON+8));
 	AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_USE));
   if pl = 1 then
    AddChild(TBindEdit.Create(@Menu_Proc, EDIT_BINDS, pl, KEY_SCOREBOARD));
 Update;
 end;
end;

procedure Menu_Init;
var
 i, j    : integer;
 ModData : TMod;
 md      : TFindData;
 sd      : TFindData;
 dir     : string;
begin
dis_mode := 1;  // 640x480
dis_bpp  := 0;  // 16
dis_freq := 0;  // 60
SayEdit  := TEdit.Create(nil, EDIT_STRING, nil, '^2Say:', '', VT_STRING);
with SayEdit do
 begin
 HAlign    := ahLeft;
 Tab       := 5;
 X         := 0;
 Y         := 48;
 MaxLength := 64;
 end;
onSay := false;

GetMem(MenuBG, MenuBG_x*MenuBG_Y*3);
FillChar(MenuBG[0], MenuBG_x*MenuBG_Y*3, 0);
CalcMenuBG;

dir := Engine_Dir + Engine_ModDir + 'models\';

i := 0;
ModelName := nil;
if FindFirst(dir + '*', md) then
 repeat
  if md.Data.cFileName[0] = '.' then continue;
  if DirectoryExists(dir + md.Data.cFileName) then
   begin
   if FindFirst(dir + md.Data.cFileName + '\*.tml', sd) then
    begin
    SetLength(ModelName, i + 1);
    ModelName[i] := md.Data.cFileName;
    inc(i);
    end;
   end;
 until not FindNext(md);

InitWindows;

MousePos.X := 320;
MousePos.Y := 240;

MouseTex := TObjTex.Create('textures\menu\cursor', 1, 0, 5, true, false, nil, OWNER_MENU);

WND_MAIN := AddWindow(TMyWindow.Create);
with WND_MAIN do
 begin
 AddChild(TButton.Create(@Menu_Proc, BTN_HOTSEAT, 'hotseat')).Y := 200;
 AddChild(TButton.Create(@Menu_Proc, BTN_MULTI, 'multiplayer')).Y := 233;
 AddChild(TButton.Create(@Menu_Proc, BTN_SETUP, 'setup')).Y := 266;
 AddChild(TButton.Create(@Menu_Proc, BTN_DEMOS, 'demos')).Y := 299;
 AddChild(TButton.Create(@Menu_Proc, BTN_MODS, 'mods')).Y := 332;
 AddChild(TButton.Create(@Menu_Proc, BTN_CREDITS, 'credits')).Y := 365;
 AddChild(TButton.Create(@Menu_Proc, BTN_EXIT, 'exit')).Y := 398;
 AddChild(TModel3D.Create(nil, 0, 'textures\menu\logo')).Y := 200;
 Update;
 end;

WND_GAME := AddWindow(TMyWindow.Create);
with WND_GAME do
 begin
 AddChild(TButton.Create(@Menu_Proc, BTN_RESTART, 'restart')).Y := 200;
 AddChild(TButton.Create(@Menu_Proc, BTN_SETUP, 'setup')).Y := 233;
 AddChild(TButton.Create(@Menu_Proc, BTN_LEAVEARENA, 'leavearena')).Y := 266;
 AddChild(TModel3D.Create(nil, 0, 'textures\menu\logo')).Y := 200;
 Update;
 end;

WND_HOTSEAT := AddWindow(TMyWindow.Create);
with WND_HOTSEAT do
 begin
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).HAlign := ahLeft;
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_FIGHT, 'fight')).HAlign  := ahRight;
 AddChild(TLevelShot.Create(400, 60));
 with TFileListBox(AddChild(TFileListBox.Create(@Menu_Proc,  FLB_MAP))) do
  begin
  Items[1, 0] := 'Select map file';
  HAlign   := ahLeft;
  X        := 25;
  Y        := 60;
  Width    := 320;
  Height   := 276;
  Ext      := '*.tm';
  StartDir := ExtractFileDir(paramstr(0)) + '\' + Engine_ModDir + 'maps\';
  ActiveWindow := WND_HOTSEAT;
  Dir      := StartDir;
  ActiveWindow := nil;
  end;
 	AddChild(TTexLabel.Create(nil, 0, 'hotseat'));
   def_x:=400;def_cx:=0;
   def_y:=200;def_cy:=20;
	AddChild(TLabel.Create(nil, 0, '^2Game properties') );
   def_x:=400;def_y:=230;
	TEdit( AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @timelimit, 'Timelimit', 'timelimit', VT_WORD)) ).Tab:=14;
	TEdit( AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @fraglimit, 'Fraglimit', 'fraglimit', VT_WORD)) ).Tab:=14;
	TEdit( AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @forcerespawn, 'Forcerespawn', 'forcerespawn', VT_WORD)) ).Tab:=14;
  	with TYesNoEdit( AddChild(TYesNoEdit.Create(@Menu_Proc, EDIT_YESNO, @p2disable, 'player 2', 'p2disable')) ) do
   begin
      tab:=14;
      Str_Yes:='Disabled';
      Str_No:='Active';
   end;
   TEnumEdit(
   AddChild(TEnumEdit.Create(@Menu_Proc, EDIT_YESNO, @gametype_c,
      4, [GT_FFA, GT_TRIX, GT_RAIL, GT_TDM], ['Free For All', 'Trix', 'Rail Arena', 'Team DeathMatch'], ['FFA', 'TRIX', 'RAIL', 'TDM'],
    'Game Type', 'gametype')) ).Tab:=14;
   Update;
 end;

WND_MULTICREATE := AddWindow(TMyWindow.Create);
with WND_MULTICREATE do
 begin
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).HAlign := ahLeft;
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_FIGHT, 'fight')).HAlign  := ahRight;
 AddChild(TLevelShot.Create(400, 60));

 with TFileListBox(AddChild(TFileListBox.Create(@Menu_Proc,  FLB_MAP))) do
  begin
  Items[1, 0] := 'Select map file';
  HAlign   := ahLeft;
  X        := 25;
  Y        := 60;
  Width    := 320;
  Height   := 276;
  Ext      := '*.tm';
  StartDir := ExtractFileDir(paramstr(0)) + '\' + Engine_ModDir + 'maps\';
  ActiveWindow := WND_MULTICREATE;
  Dir      := StartDir;
  ActiveWindow := nil;
  end;
 	AddChild(TTexLabel.Create(nil, 0, 'multiplayer'));
   def_x:=400;def_cx:=0;
   def_y:=200;def_cy:=20;
	AddChild(TLabel.Create(nil, 0, '^2Game properties') );
   def_x:=350;def_y:=230;
  	with AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @sv_name, 'Server name', 'sv_name', VT_STRING)) as TEdit do
   begin
   	Tab := 14;
   	MaxLength := 24;
   end;

	TEdit( AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @timelimit, 'Timelimit', 'timelimit', VT_WORD)) ).Tab:=14;
	TEdit( AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @fraglimit, 'Fraglimit', 'fraglimit', VT_WORD)) ).Tab:=14;
	TEdit( AddChild(TEdit.Create(@Menu_Proc, EDIT_STRING, @forcerespawn, 'Forcerespawn', 'forcerespawn', VT_WORD)) ).Tab:=14;
  	with TYesNoEdit( AddChild(TYesNoEdit.Create(@Menu_Proc, EDIT_YESNO, @p2disable, 'player 2', 'p2disable')) ) do
   begin
      tab:=14;
      Str_Yes:='Disabled';
      Str_No:='Active';
   end;
   TEnumEdit(
   AddChild(TEnumEdit.Create(@Menu_Proc, EDIT_YESNO, @gametype_c,
      4, [GT_FFA, GT_TRIX, GT_RAIL, GT_TDM], ['Free For All', 'Trix', 'Rail Arena', 'Team DeathMatch'], ['FFA', 'TRIX', 'RAIL', 'TDM'],
    'Game Type', 'gametype')) ).Tab:=14;

 Update;
 end;


WND_SETUP := AddWindow(TMyWindow.Create);
with WND_SETUP do
 begin
   AddChild(TTexLabel.Create(nil, 0, 'setup'));
 	AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).HAlign := ahLeft;
 	AddChild(TButton.Create(@Menu_Proc, BTN_PLAYER1, 'player1')).Y := 167;
 	AddChild(TButton.Create(@Menu_Proc, BTN_PLAYER2, 'player2')).Y := 200;
 	AddChild(TButton.Create(@Menu_Proc, BTN_DISPLAY, 'display')).Y := 233;
 	AddChild(TButton.Create(@Menu_Proc, BTN_SOUND, 'sound')).Y := 266;
 Update;
 end;

WND_DISPLAY := AddWindow(TMyWindow.Create);
with WND_DISPLAY do
 begin
 AddChild(TTexLabel.Create(nil, 0, 'display'));
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).HAlign := ahLeft;
 def_x:=64; def_y:=96; def_cx:=0; def_cy:=20;
 AddChild(TYesNoEdit.Create(@Menu_Proc, EDIT_YESNO, Console_GetVar('vsync'), 'VSync', 'vsync'));

 AddChild(TEnumStrEdit.Create('Dysplay mode', @dis_mode, DIS__MODE));
 AddChild(TEnumStrEdit.Create('Color depth', @dis_bpp, DIS__BPP));
 AddChild(TEnumStrEdit.Create('Frequency', @dis_freq, DIS__FREQ));

 AddChild(TGraphButton.Create(@Menu_Proc, BTN_ACCEPT, 'accept')).HAlign := ahRight;

 Update;
 end;

WND_SOUND:=AddWindow(TMyWindow.Create);
with WND_SOUND do
 begin
 AddChild(TTexLabel.Create(nil, 0, 'sound'));
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).HAlign := ahLeft;
 def_x:=64; def_y:=96; def_cx:=0; def_cy:=20;
 with AddChild(TYesNoEdit.Create(@Menu_Proc, EDIT_YESNO,
 	@sound_off, 'sound', 'sound_off')) as TYesNoEdit do
  begin
   str_Yes:='Off';
   str_No:='On';
  end;
 Update;
 end;

WND_PLAYER1 := Menu_PlayerCreate(1);
WND_PLAYER2 := Menu_PlayerCreate(2);

WND_DEMOS := AddWindow(TMyWindow.Create);
with WND_DEMOS do
 begin
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).HAlign := ahLeft;
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_PLAY, 'play')).HAlign  := ahRight;

 with TFileListBox(AddChild(TFileListBox.Create(@Menu_Proc,  FLB_DEMO))) do
  begin
  Items[1, 0] := 'Select demo file';
  HAlign   := ahCenter;
  Y        := 60;
  Width    := 500;
  Height   := 320;
  Ext      := '*.tdm';
  StartDir := ExtractFileDir(paramstr(0)) + '\' + Engine_ModDir + 'demos\';
  Dir      := StartDir;
  end;
 AddChild(TTexLabel.Create(nil, 0, 'demos'));
 Update;
 end;

WND_MODS := AddWindow(TMyWindow.Create);
with WND_MODS do
 begin
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).HAlign := ahLeft;
 AddChild(TGraphButton.Create(@Menu_Proc, BTN_LOAD, 'load')).HAlign  := ahRight;

 with TListBox(AddChild(TListBox.Create(@Menu_Proc,  FLB_MODS))) do
  begin
  	HAlign   := ahCenter;
  	Y        := 60;
  	Width    := 500;
  	Height   := 320;

   SetSize(2, 1);
  	Items[0, 0] := 'Mod';
  	Items[1, 0] := 'Folder';
  	for i := 0 to Engine_ModCount - 1 do
   begin
   	Engine_GetMod(i, ModData);
   	j := items.AddRow;
   	items[0, j] := ModData.Name;
   	items[1, j] := ModData.Path;
   end;
  	Index := 0;
 end;
AddChild(TTexLabel.Create(nil, 0, 'mods'));
Update;
end;

WND_MP_INTERNET:= AddWindow(TMyWindow.Create);
with WND_MP_INTERNET do
begin
   MP_lb:=TListBox.Create(@Menu_Proc, LB_SERVERS);
   AddChild(MP_lb);
   with MP_lb do
   begin
  		HAlign   := ahCenter;
  		Y        := 60;
 	   	Width    := 600;
  		Height   := 300;

  		SetSize(6, 1);
  		Items[0, 0] := 'Hostname';
      Items.colwidth[0] := 15;
  		Items[1, 0] := 'Map';
      Items.colwidth[1] := 15;
  		Items[2, 0] := 'Load';
      Items.colwidth[2] := 6;
  		Items[3, 0] := 'IP          Port';
      Items.colwidth[3] := 21;
  		Items[4, 0] := 'Ping';
      Items.colwidth[4] := 4;
      Items[5, 0] := 'Reason';
      Items.colwidth[5] := 6;
   end;

 	AddChild(TTexLabel.Create(nil, 0, 'multiplayer'));

 	AddChild(TGraphButton.Create(@Menu_Proc, BTN_BACK, 'back')).X := 0;
 	AddChild(TGraphButton.Create(@Menu_Proc, 0, 'specify')).X := 128;
 	RefBtn := AddChild(TGraphButton.Create(@Menu_Proc, BTN_REFRESH, 'refresh'));
  RefBtn.X := 256;
 	AddChild(TGraphButton.Create(@Menu_Proc, BTN_MULTICREATE, 'create')).X := 384;
 	AddChild(TGraphButton.Create(@Menu_Proc, BTN_CONNECT, 'fight')).X := 512;
  RefLabel := AddChild(TLabel.Create(nil, 0, 'hit refresh to update')) as TLabel;
  with RefLabel do
   begin
   Halign := ahCenter;
   Y      := 380;
   end;

   def_x := 150; def_y := 320;
   def_cx:= 150; def_cy := 0;
//   AddChild(TLabel.Create(@Menu_Proc, BTN_REFRESH, 'Refresh')).Enabled:=true;
//   AddChild(TLabel.Create(@Menu_Proc, BTN_SEARCH, 'Search')).Enabled:=true;
//   AddChild(TLabel.Create(@Menu_Proc, BTN_CONNECT, 'Connect')).Enabled:=true;
//   AddChild(TButton.Create(@Menu_Proc, BTN_REMOVESERV, '^6Remove'));
   def_x := 200; def_y := 364;
   def_cx := 250;
   IPEdit:=AddChild(TEdit.Create(@Menu_Proc, EDIT_IP, nil, 'Choose IP', '', VT_STRING)) as TEdit;
   IPEdit.MaxLength:=21;
   IPEdit.Tab:=10;
   AddChild(TLabel.Create(@Menu_Proc, BTN_ADDIP, 'Add')).Enabled:=true;
//   AddChild(TButton.Create(@Menu_Proc, BTN_REMOVE));
end;

ActiveWindow := WND_MAIN;
end;

procedure Menu_Free;
begin
// XProger: Нравится мне название этой процедурки :)))
ModelName := nil;
SayEdit.Free;
DestroyWindows;
end;

procedure CalcMenuBG;
var
 idx  : Byte;
 r, g : WORD;

 procedure pix(x, y: integer);
 begin
 if (x > -1) and (x < MenuBG_X) and
    (y > -1) and (y < MenuBG_Y) then
  begin
  r := r + MenuBG[y*MenuBG_X + x].R;
  g := g + MenuBG[y*MenuBG_X + x].G;
  end
 else
  dec(idx); 
 end;

var
 x, y : integer;
 i    : integer;
 MBG  : PaRGB;
begin
GetMem(MBG, MenuBG_X * MenuBG_Y * 3);
for x := 1 to MenuBG_X do
 begin
 y := random(MenuBG_X);
 i := (MenuBG_Y - 1) * MenuBG_X + y;
  case random(4) of
   0 : begin
       MenuBG[i].R := 255;
       MenuBG[i].G := 0;
       end;
   1 : begin
       MenuBG[i].R := 255;
       MenuBG[i].G := 255;
       end;
  else
   begin
   MenuBG[i].R := 0;
   MenuBG[i].G := 0;
   end;
  end
 end;

for y := 0 to MenuBG_Y - 1 do
 for x := 0 to MenuBG_X - 1 do
  begin
  idx := 5;
  r   := 0;
  g   := 0;
  pix(x, y + 1);
  pix(x - 1, y);
  pix(x + 1, y);
  pix(x - 1, y + 1);
  pix(x + 1, y + 1);
  i := y*MenuBG_X + x;
  MBG[i].R := r div idx;
  MBG[i].G := g div idx;
  MBG[i].B := 0;
  end;
FreeMem(MenuBG);
MenuBG := MBG;

xglTex_Free(@MenuTex);
MenuTex.Data   := PByteArray(MenuBG);
MenuTex.Width  := MenuBG_X;
MenuTex.Height := MenuBG_Y;
MenuTex.BPP    := 24;
MenuTex.Trans  := false;
MenuTex.Filter := true;
MenuTex.MipMap := false;
MenuTex.Scale  := false;
MenuTex.Clamp  := true;

xglTex_Create(@MenuTex);
end;

procedure Menu_Update;
begin
if menu_fx {and not isGame }then
 CalcMenuBG;
 {
if sound_off = 0 then
 snd_SetGlobalPos(Point2f(0, 0));
  }
inc(MousePos.X, Input_MouseDelta.X);
inc(MousePos.Y, Input_MouseDelta.Y);
if MousePos.X < 0 then MousePos.X := 0;
if MousePos.Y < 0 then MousePos.Y := 0;
if MousePos.X > 640 then MousePos.X := 640;
if MousePos.Y > 480 then MousePos.Y := 480;

MouseTex.Update;
RefBtn.Enabled := not Arena_Refresh;
if Arena_Refresh then
 RefLabel.Text := 'Scanning For Servers.'
else
 RefLabel.Text := 'hit refresh to update';
ActiveWindow.Update;
end;


procedure Menu_Draw;
begin
// Set Viewport
glViewport(0, 0, xglWidth, xglHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
gluOrtho2D(0, 640, 480, 0);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity;

if menu_fx {and not isGame} then
 begin
 xglTex_Enable(@MenuTex);
 glColor4f(1, 1, 1, 1);
 glBegin(GL_QUADS);
  glTexCoord2f(0, 0.9); glVertex2f(0,   480);
  glTexCoord2f(0, 0);   glVertex2f(0,   0);
  glTexCoord2f(1, 0);   glVertex2f(640, 0);
  glTexCoord2f(1, 0.9); glVertex2f(640, 480);
 glEnd;
 end;
 
ActiveWindow.Draw;
// Draw mouse cursor
xglAlphaBlend(1);
glColor4f(1, 1, 1, 1);
xglTex_Enable(MouseTex.CurFrame);
glBegin(GL_QUADS);
 glTexCoord2f(0, 1); glVertex2f(MousePos.X - 16, MousePos.Y - 16);
 glTexCoord2f(1, 1); glVertex2f(MousePos.X + 16, MousePos.Y - 16);
 glTexCoord2f(1, 0); glVertex2f(MousePos.X + 16, MousePos.Y + 16);
 glTexCoord2f(0, 0); glVertex2f(MousePos.X - 16, MousePos.Y + 16);
glEnd;
end;

procedure Menu_Message(Msg: DWORD; wParam: Longint; lParam: LongInt);
var
 M : TMessage;
begin
if (not Console.Show) and (ActiveWindow <> nil) then
 begin
 M.Msg    := Msg;
 M.wParam := wParam;
 M.lParam := lParam;
 if Msg = WM_KEYDOWN then
  if wParam = 255 then
   Exit;
 ActiveWindow.onMessage(M);
 end;
end;

procedure Menu_Proc(ID : integer; Param : integer);
var
 s : string;
begin
 case ID of
  BTN_FIGHT:
   with TFileListBox(activewindow.Childs[3]) do
    if Items[0, Index] = 'F' then
     begin
     s := Dir;
     Delete(s, 1, Length(StartDir));
     s := 'maps\' + s + Items[1, Index] + '.tm';
     inMenu := not LoadMap(s, false, 2-ord(activewindow=WND_HOTSEAT));
     end;

  BTN_PLAY:
   with TFileListBox(WND_DEMOS.Childs[2]) do
    if Items[0, Index] = 'F' then
     begin
     s := Dir;
     Delete(s, 1, Length(StartDir));
     s := 'demos\' + s + Items[1, Index] + '.tdm';
     inMenu := not LoadMap(s, false);
     end;

  BTN_LOAD:
   Engine_ChangeModQuery(TListBox(WND_MODS.Childs[2]).Index - 1);

  BTN_BACK:
   	CallBack;

  BTN_HOTSEAT:
   	CallWindow(WND_HOTSEAT);

  BTN_SETUP:
   	CallWindow(WND_SETUP);

  BTN_DEMOS:
   	CallWindow(WND_DEMOS);

  BTN_MODS:
   	CallWindow(WND_MODS);

  BTN_MULTI:
   begin
   CallWindow(WND_MP_INTERNET);
   Menu_RefreshServers; // XProger: сразу ищем серваки
   end;

  BTN_MULTICREATE:
  		CallWindow(WND_MULTICREATE);

  BTN_EXIT:
   begin
   Engine_Quit;
   if sound_off=0 then
   	snd_Play(MenuSnd_3, false, 0, 0, true);
   end;

  	EDIT_NAME :
   begin
      if ActiveWindow = WND_Player1 then
 			Console_Cmd('name ' + PChar(Param))
      else Console_Cmd('p2name ' + PChar(Param))
   end;

   BTN_PLAYER1:
    begin
    CallWindow(WND_PLAYER1);
    Menu_SetModel(1);
    end;

   BTN_PLAYER2:
    begin
    CallWindow(WND_PLAYER2);
    Menu_SetModel(2);
    end;

   BTN_DISPLAY:
   	CallWindow(WND_DISPLAY);

   BTN_SOUND:
   	CallWindow(WND_SOUND);

   BTN_RESTART:
    Console_Cmd('restart');

   BTN_ACCEPT :
    begin
    s := DIS__MODE[dis_mode];
    s[pos('x', s)] := ' ';
    Console_Cmd('display ' + s + ' ' + DIS__BPP[dis_bpp] + ' ' + DIS__FREQ[dis_freq]);
    end;

   BTN_LEAVEARENA:
    begin
    Map.ClearAll;
    CallMainMenu;
    end;

   BTN_REFRESH:
    Menu_RefreshServers;

//   BTN_SEARCH:
//     Console_CMD('net_search');

   BTN_CONNECT:
      if MP_lb.index>=0 then
      	Console_CMD('net_connect '+MP_lb.Items[3, MP_lb.index]);

   BTN_ADDIP:
      Menu_AddIP(IPEdit.Text);

   FLB_MAP :
      if (activewindow=WND_HOTSEAT) or
         (activewindow=WND_MULTICREATE) and (WND_MULTICREATE<>nil) then
    	with activewindow do
       begin
       Childs[1].Enabled := (Param > 0) and (TFileListBox(Childs[3]).Items[0, Param] = 'F');
       if Childs[1].Enabled then
        TLevelShot(Childs[2]).LoadShot(TFileListBox(Childs[3]).Items[1, Param]);
       end;

   FLB_DEMO :
    with WND_DEMOS do
     Childs[1].Enabled := (Param > 0) and (TFileListBox(Childs[2]).Items[0, Param] = 'F');

   FLB_MODS :
    with WND_MODS do
     Childs[1].Enabled := (Param > 0) and (Engine_CurMod <> Param - 1);

   LB_MODELS :
    if ActiveWindow <> nil then
     with ActiveWindow do
      if (Param > 0) and (ChildCount > 8) then
       begin
       s := TListBox(Childs[0]).items[0, Param];
       TListBox(Childs[1]).index := 0;
       end;

   LB_SKINS :
    if ActiveWindow <> nil then
     with ActiveWindow do
      if (Param > 0) and (ChildCount > 8) then
       with TListBox(Childs[0]) do
        begin
        s := items[0, index] + '+' +
             TListBox(Childs[1]).items[0, Param];
        TModelViewer(Childs[2]).SetModel(s);
        Log_ConWrite(false);
        if ActiveWindow = WND_PLAYER1 then
         Console_Cmd('model ' + s)
        else
         Console_Cmd('p2model ' + s);
        Log_ConWrite(true);
        end;
 end;
end;

procedure Menu_AddServer(IP: string; Port: word; HostName, MapName: string;
	Ping: cardinal; players, max: integer; reason: string);
var
   i: integer;
begin
   with MP_lb do
   begin
      i:=Items.Find(3, IP+':'+inttostr(port));
      if i<0 then
      begin
      	i:=Items.AddRow;
      	Items[5, i]:=reason;
      end;
      Items[0, i]:=HostName;
      Items[1, i]:=MapName;
      Items[2, i]:=inttostr(players)+'/'+inttostr(max);
      Items[3, i]:=IP+':'+inttostr(port);
      if ping>1000 then Items[4, i]:='XXX'
      else Items[4, i]:=inttostr(ping);
   end;
end;

procedure Menu_RefreshServers;
var
   i: integer;
begin
with MP_lb do
 for i:=1 to Items.rowcount-1 do
  begin
  Console_CMD('net_info ' + Items[3, i]);
  Items[0, i] := '';
  Items[1, i] := '';
  Items[2, i] := '';
  Items[4, i] := '';
  end;
Arena_GetServers;  
Console_CMD('net_search'); // Ищем серваки в локалке локальные
end;

procedure Menu_AddIP(str: string);
var
   i, t, c: integer;
   f: boolean;
begin
   //идёт проверка на валидный IP
   t:=0;c:=0;
   f:=true;
   for i:=1 to length(str) do
      if str[i] in ['0'..'9'] then Inc(c)
      else if str[i]='.' then
      begin
         if c=0 then f:=false
         else c:=0;
         Inc(t);
      end else if str[i]=':' then Break
      else f:=false;

   if (t<3) or (length(str[i])>21) then f:=false;
   if pos(':', str)=0 then str:=str+':25666';
   //получили чуть-чуть "валидный" IPшник :)
   if f then
   with MP_lb do
   begin
      i:=Items.Find(3, str);
      if i<0 then
      begin
      	i:=Items.AddRow;
      	Items[3, i]:=str;
      	Items[5, i]:='';
         Console_CMD('net_info '+str);
      end;
   end;

end;

function Menu_MP: boolean;
begin
   Result:=ActiveWindow = WND_MP_INTERNET;
end;

procedure CallGameMenuON;
begin
   ActiveWindow := WND_GAME;
   inMenu := true;
end;

procedure CallGameMenuOFF;
begin
   ActiveWindow:=WND_GAME;
   inMenu:=false;
end;

procedure CallMainMenu;
begin
   snd_StopAll(0); // так надо...
   ActiveWindow:=WND_MAIN;
   // Вдруг демки записали новые...
   with TFileListBox(WND_DEMOS.Childs[2]) do
    Dir := Dir;
   inMenu:=true;
end;

end.
