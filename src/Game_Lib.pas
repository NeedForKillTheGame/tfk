unit Game_Lib;

interface

uses
 Windows, SysUtils, OpenGL,
 Engine_Reg,
 Constants_Lib,
 Type_Lib,
 Graph_Lib,
 MyEntries,
 Math_Lib,
 Func_Lib,
 Weapon_Lib,
 Player_Lib,
 PlayersUtils_Lib,
 Map_Lib,
 Phys_Lib,
 HUD_Lib,
 Particle_Lib,
 ItemObj_Lib,
 binds_lib,
 Bot_Lib,
 TFKBot_Lib;

 procedure Game_Init;
 procedure Game_Update;
 procedure Game_Draw;

 function Game_Cmd(Cmd: ShortString): boolean;
 function Bot_Cmd(Cmd: ShortString): boolean;

 function IsGame: boolean;
 function FindMap(const FileName: string): string;
 function LoadMap(const FileName: string; mapfind: boolean = true; multi: byte = 0): boolean;

 function GetGameType(gametype: Byte): string;
 function SetGameType(str: string): boolean;

 procedure queue_add(cmd: shortstring);

implementation

uses Menu_lib, Mouse_Lib, Real_Lib, Timing_Lib, Net_Lib, Net_Server_Lib;

var
   comm_queue: array [1..100] of shortstring;
   comm_length: integer;

procedure queue_add(cmd: shortstring);
begin
   inc(comm_length);
   comm_queue[comm_length]:=cmd;
end;

function GetFilePath(const Dir, Name: string): string;
 var
  fd : TFindData;
  s  : string;
 begin
 Result := '';
 s      := LowerCase(Name);
 if FindFirst(Dir + '*', fd) then
  repeat
   if fd.Data.cFileName[0] = '.' then continue;
   if DirectoryExists(Dir + fd.Data.cFileName) then
    Result := GetFilePath(Dir + fd.Data.cFileName + '\', Name)
   else
    if LowerCase(fd.Data.cFileName) = s then
     Result := Dir + Name;
   if Result <> '' then
    break;
  until not FindNext(fd);
 end;

procedure Game_Init;
begin
Randomize;
HUD_Init;
Particle_Init;
bg := 'bg_11';
Map := TMap.Create;
Const_Init;
Phys_Init;
Weapon_Init;
Phys_Player_Init;
Bind_Init;
Mouse_Init;
WeaponCreate;
tfkbot_Init;//CMD commands for TFK bot

Console_CmdReg('phys', @Phys_cmd);

Log_ConWrite(false);
Console_Cmd('exec phys.cfg');
Log_ConWrite(true);

Console_CmdReg('activate', @Game_Cmd);
Console_CmdReg('map', @Game_Cmd);
Console_CmdReg('map_list', @Game_Cmd);
Console_CmdReg('model_list', @Game_Cmd);

Console_CmdReg('gametype', @Game_Cmd);
Console_CmdReg('spgame', @Game_Cmd);
Console_CmdReg('spgame_free', @Game_Cmd);

Console_CmdReg('demo', @Game_Cmd);
Console_CmdReg('restart', @Game_Cmd);
Console_CmdReg('ready', @Game_Cmd);
Console_CmdReg('stats', @Game_Cmd);
Console_CmdReg('autorecord', @Game_Cmd);
Console_CmdReg('record', @Game_Cmd);
Console_CmdReg('stoprecord', @Game_Cmd);
                      {
Console_CmdReg('sc_record', @Game_Cmd);
Console_CmdReg('sc_stop', @Game_Cmd);
Console_CmdReg('sc_play', @Game_Cmd);
Console_CmdReg('sc_clear', @Game_Cmd);
Console_CmdReg('sc_list', @Game_Cmd);
                       }
Console_CmdReg('give', @Game_Cmd);
Console_CmdReg('demo_goto', @Game_Cmd);
Console_CmdReg('demo_skip', @Game_Cmd);

Console_CmdReg('cam_nextplayer', @Game_Cmd);
Console_CmdReg('cam_prevplayer', @Game_Cmd);

Console_CmdReg('sv_name', @Game_Cmd);
Console_CmdReg('sv_pass', @Game_Cmd);
Console_CmdReg('name', @Game_Cmd);
Console_CmdReg('p2name', @Game_Cmd);
Console_CmdReg('model', @Game_Cmd);
Console_CmdReg('p2model', @Game_Cmd);
Console_CmdReg('disjoin', @Game_Cmd);
Console_CmdReg('join', @Game_Cmd);
Console_CmdReg('p2join', @Game_Cmd);
Console_CmdReg('say', @Game_Cmd);
Console_CmdReg('onsay', @Game_Cmd);
Console_CmdReg('bg', @Game_Cmd);

Console_CmdReg('r_rail', @Game_Cmd);
Console_CmdReg('r_rail_p2', @Game_Cmd);
Console_CmdReg('r_rail_enemy', @Game_Cmd);

//отладка
Console_CmdReg('fade', @Game_Cmd);

// BOT
Console_CmdReg('bot_load', @Bot_Cmd);
Console_CmdReg('bot_version', @Bot_Cmd);

Console_CmdReg('нах', @Game_Cmd);

Console_CmdReg('sp_save', @Game_Cmd);
Console_CmdReg('sp_load', @Game_Cmd);

// Обнуляем все процедуры бота
BOT_DLL := 0;
FreeBotDll;

Console_Cmd('exec autoexec.cfg'); // exec'аем autoexec %)

Log_ConWrite(false);
Console_Cmd('exec config.cfg'); //XProger: только после регистрации всех команд!
Log_ConWrite(true);
//Neoff: спасибо что исправил
end;

procedure Game_Update;
var
   i: integer;
begin
if not IsGame then Exit;

Inc(sound_off);
Log_ConWrite(false);
for i:=1 to comm_length do
   Console_CMD(comm_queue[i]);
comm_length:=0;
Log_ConWrite(true);
Dec(sound_off);

if not inMenu then
 begin
 UpdateKeys;
 if onSay then
  SayEdit.Update
 else
  Mouse.Update;
 end;

Timing_Start('HUD Update');
HUD_Update;
Timing_End('HUD Update');
Timing_Start('Map Update');
Map.Update;
Timing_End('Map Update');

// Listen sound pos
if cam_fixed then
 begin
 sndPos      := Point2f(Map.Width*16, Map.Height*8);;
 splitscreen := SPLIT_NONE;
 end
else
 if Map.Players > 0 then
  if splitscreen = SPLIT_NONE then
   sndPos := Map.Camera.Pos
  else
  begin
     if Map.pl_find(-1, C_PLAYER_P1) then
         sndPos := Map.pl_current.Pos
         else sndPos := Map.Camera.Pos;
  end;

if sound_off=0 then
 snd_SetGlobalPos(sndPos)
end;

procedure Game_Draw;

 procedure ViewPort(X, Y, Width, Height: integer);
 begin
 if SplitScreen = SPLIT_NONE then
  if dis_scale then
   begin
   if (xglWidth > 640) or (xglHeight > 480) then
    begin
    X := (xglWidth - 640) div 2;
    Y := (xglHeight - 480) div 2;
    Width  := 640;
    Height := 480;
    end;
   end;

 glViewport(X, Y, Width, Height);
 glMatrixMode(GL_PROJECTION);
 glLoadIdentity;
 gluOrtho2D(0, Map.Camera.View.X*2 , Map.Camera.View.Y*2, 0);
 glMatrixMode(GL_MODELVIEW);										//    glLoadIdentity;
 end;

var
 s : PChar;
 x : integer;
begin
if not IsGame then Exit;
Particle_inframe := 0;

if not Map.pl_find(-1, C_PLAYER_p2) then
 SplitScreen := SPLIT_NONE
else if (SplitScreen=SPLIT_NONE) and not cam_fixed then
   SplitScreen := 2;

if cam_fixed then
 begin
 ViewPort(0, 0, xglWidth, xglHeight);
Timing_Start('Map draw');
 Map.Draw;
Timing_End('Map draw');
 end
else
 case SplitScreen of
  SPLIT_NONE :
   begin
   ViewPort(0, 0, xglWidth, xglHeight);
   if Map.pl_find(-1, C_PLAYER_p1) then
   	Map.Camera.Target := Map.pl_current;
Timing_Start('Map draw');
   Map.Draw;
Timing_End('Map draw');
   end;
  SPLIT_HORIZ :
   begin
   ViewPort(0, xglHeight div 2, xglWidth, xglHeight div 2);
   if Map.pl_find(-1, C_PLAYER_p1) then
      Map.Camera.Target := Map.pl_current;
   Map.Camera.Update;
   Map.Draw;
   ViewPort(0, 0, xglWidth, xglHeight div 2);
   if Map.pl_find(-1, C_PLAYER_p2) then
		Map.Camera.Target := Map.pl_current;
   Map.Camera.Update;
   Map.Draw;
  //split line
   xglViewPort(0, 0, xglWidth, xglHeight, false);
   xglTex_Disable;
   glColor4f(0.5, 0.5, 0.5, 1);
   glLineWidth(3);
   glBegin(GL_LINES);
    glVertex2f(0, xglHeight div 2);
    glVertex2f(xglWidth, xglHeight div 2);
   glEnd;
   end;
  SPLIT_VERT :
   begin
   ViewPort(xglWidth div 2, 0, xglWidth div 2, xglHeight);
   if Map.pl_find(-1, C_PLAYER_p1) then
 		Map.Camera.Target := Map.pl_current;
   Map.Camera.Update;
   Map.Draw;
   if not p2disable then
    begin
    glViewPort(0, 0, xglWidth div 2, xglHeight);
    if Map.pl_find(-1, C_PLAYER_p2) then
 		Map.Camera.Target := Map.pl_current;
    Map.Camera.Update;
    Map.Draw;
    end;
  //split line
   xglViewPort(0, 0, xglWidth, xglHeight, false);
   xglTex_Disable;
   glColor4f(0.5, 0.5, 0.5, 1);
   glLineWidth(3);
   glBegin(GL_LINES);
    glVertex2f(xglWidth div 2, 0);
    glVertex2f(xglWidth div 2, xglHeight);
   glEnd;
   end;
  end;

HUD_Draw;

// XProger: вывод информации о размере демки :)
if demo_showinfo then
 if Map.demorec then
  begin
  // XProger: Neoff, я так понял, что пишу размер дэмки а не конечного файла,
  // Включающего в себя карту, как ты думаешь это так и оставить?
  s := PChar('Recording demo "' + Map.Demo.demofilename + '" Size: ' +
              IntToStr(Map.Fullsize div 1024)+ ' Kb');
//             FloatToStrF(Map.Demo.position/1024, ffGeneral, 3, 4) + ' Kb');
  x := 320 - Length(s)*4;
  xglAlphaBlend(1);
  glColor3f(0, 0, 0);
  TextOut(x + 1, 17, s);
  glColor3f(1, 1, 0);
  TextOut(x, 16, s);
  end;

if onSay then
 SayEdit.Draw;

// отобразить информацию о партиклах
if d_particles then
 begin
 xglAlphaBlend(1);
 glColor3f(0, 0, 0);
 TextOut(17, 51, PChar('Particles'));
 TextOut(17, 67, PChar(' Count   : ' + IntToStr(Particle_Count)));
 TextOut(17, 83, PChar(' inFrame : ' + IntToStr(Particle_inFrame)));
 glColor3f(1, 0.2, 0.2);
 TextOut(16, 50, PChar('Particles'));
 TextOut(16, 66, PChar(' Count   : ' + IntToStr(Particle_Count)));
 TextOut(16, 82, PChar(' inFrame : ' + IntToStr(Particle_inFrame)));
 end;
if d_realobjs then
 begin
 xglAlphaBlend(1);
 glColor3f(0, 0, 0);
 TextOut(17, 51, PChar('Real Objects'));
 TextOut(17, 67, PChar(' Size   : ' + IntToStr(RealObj_Count)));
 glColor3f(1, 0.2, 0.2);
 TextOut(16, 50, PChar('Real Objects'));
 TextOut(16, 66, PChar(' Size   : ' + IntToStr(RealObj_Count)));
 end;
end;

function FindMap(const FileName: string): string;
var
   dir, s, name: string;
begin
   if (ExtractFileExt(filename) <> 'tm') then
      name := filename + '.tm'
   else name:=filename;
   dir:=Engine_Dir + Engine_ModDir + MAPS_FOLDER;
   s:=GetFilePath(dir, name);
   if s<>'' then
      Result:=s
   else Result:='';
end;

function LoadMap(const FileName: string; mapfind: boolean=true; multi: byte=0): boolean;
var
   s, name: string;
begin
   Result := false;
   gametype := gametype_c;
   if (ExtractFileExt(filename) <> 'tm') and
      (ExtractFileExt(filename) <> 'tdm') then
      name := filename + '.tm'
   else name:=filename;
   if mapfind then
      s:=FindMap(name)
   else
   begin
      if pos(Engine_Dir+Engine_ModDir, Name)=0 then
         s:=Engine_Dir + Engine_ModDir + Name
      else
         s:=Name;
   end;
   if s<>'' then
   begin
      Name:=s;
      Delete(Name, 1, length(Engine_Dir+Engine_ModDir));
   end;
   if (s='') or not FileExists(s) then
   begin
      //внимание: карта не существует. при различных режимах игры это чревато
      //разными последствиями
      if NET.Type_=NT_CLIENT then
      begin
         if NET_MapDownload(FileName) then
         begin
            s:=FindMap(name);
            if s = '' then
            begin
               Log('^1Error: TFK map "^7' + FileName + '^1" ^1is not found!');
               NET_Create(false);
               CallMainMenu;
            end
            else
            begin
               if Map.lastfilename<>'' then
                  Map.Demo.RecStop;
               if Map.LoadFromFile(s)=0 then
               begin
                  Log('^2Load TFK map ^7"' + Name + '^7"');
                  Result:=true;
               end else
               begin
                  Log('^1Error: file ^7"' + Name + '^7" ^1is not TFK map!');
                  NET_Create(false);
                  CallMainMenu;
               end;
            end;
         end else
         begin
            NET_Create(false);
            CallMainMenu;
         end;
      end else Log('^1Error: TFK map "^7' + FileName + '^1" ^1is not found!');
   end
else
   begin
      if Map.lastfilename<>'' then
         Map.Demo.RecStop;
      if Map.LoadFromFile(s) = 0 then
      begin
         Log('^2Load TFK map ^7"' + Name + '^7"');
         Result := true;
         if NET.Type_=NT_NONE then
            net_Create(not Map.demoplay and not (multi=1) and ( (multi=2) or net_mapmode ) );
         if NET.Type_=NT_SERVER then
	         NET_Server.changemap_send;
      end
   else
      begin
         Log('^1Error: file ^7"' + Name + '^7" ^1is not TFK map!');
         NET_Create(false);
         CallMainMenu;
      end;
  end;
end;

var
 ModelUpdate : boolean = false;

function GetGameType(gametype: Byte): string;
begin
 case gametype of
  GT_FFA  : Result := 'FFA  : Free For All';
  GT_TRIX : Result := 'TRIX : Trix Arena';
  GT_RAIL : Result := 'RAIL : Rail Arena';
  GT_TDM  : Result := 'TDM  : Team Deathmatch';
  GT_CTF  : Result := 'CTF  : Capture The Flag';
  GT_DOM  : Result := 'DOM  : Domination';
  GT_CTC  : Result := 'CTC  : Catch The Chicken';
  GT_SINGLE: Result := 'SP   : Single player';
 else
  Result := '';
 end;
if gametype = gametype_c then
 Result := '^b' + Result + '^n';
end;

function SetGameType(str: string): boolean;
begin
Result := true;
if str = 'ffa'  then gametype_c := GT_FFA  else
if str = 'trix' then gametype_c := GT_TRIX else
if str = 'rail' then gametype_c := GT_RAIL else
if str = 'tdm'  then gametype_c := GT_TDM  else
if str = 'ctf'  then gametype_c := GT_CTF  else
if str = 'dom'  then gametype_c := GT_DOM  else
if str = 'ctc'  then gametype_c := GT_CTC  else
if str = 'sp'  then gametype_c := GT_SINGLE  else
Result := false;
end;

function Game_Cmd(Cmd: ShortString): boolean;
var
 par  : array [1..5] of string;
 i, j, k, l : integer;
 s, s1, str, str_ : string;
 tex : TTexdata;

 procedure GetMapList(Dir: string);
 var
  fd  : TFindData;
 begin
 if FindFirst(Dir + '*', fd) then
  repeat
   if fd.Data.cFileName[0] = '.' then continue;
   if DirectoryExists(Dir + fd.Data.cFileName) then
    GetMapList(Dir + fd.Data.cFileName + '\')
   else
    if ExtractFileExt(fd.Data.cFileName) = 'tm' then
     Log(' ' + ExtractFileNameEx(string(fd.Data.cFileName)));
  until not FindNext(fd);
 end;

 function GetMapCount(Dir: string): integer;
 var
  fd  : TFindData;
 begin
 Result := 0;
 if FindFirst(Dir + '*', fd) then
  repeat
   if fd.Data.cFileName[0] = '.' then continue;
   if DirectoryExists(Dir + fd.Data.cFileName) then
    Result := Result + GetMapCount(Dir + fd.Data.cFileName + '\')
   else
    if ExtractFileExt(fd.Data.cFileName) = 'tm' then
     inc(Result);
  until not FindNext(fd);
 end;

begin
Result := true;
str    := Func_Lib.LowerCase(trim(cmd));
str_   := str;
for i := 1 to 5 do
 par[i] := StrSpace(str);

if par[1] = 'нах' then
 begin
 case random(6) of
  0 : Log('^2а пох!');
  1 : Log('^2а зах!');
  2 : Log('^2иннах!');
  3 : Log('^2куй в нос!');
  4 : Log('^2пох!');
  5 : Log('^23.14здец ты умный...');
 end;
 // XProger: :)))
 Exit;
 end;

if par[1] = 'spgame' then
begin
   if DirectoryExists(Engine_ModDir+par[2]) then
   begin
      Console_CMD('^2starting SP game ^b'+par[2]);
      if par[2][length(par[2])]<>'\' then
         par[2]:=par[2]+'\';
      spgame_folder:=par[2];
      maps_folder:=par[2]+'maps\';
//      Log_Conwrite(false);
      Console_CMD('exec '+par[2]+'autoexec.cfg');
      Log_Conwrite(true);
   end else Log('^1Wrong path');
   Result:=true;
   Exit;
end;
if par[2] = 'spgame_free' then
begin
   if spgame_folder<>'' then
      Log('^2spgame mode off')
   else Log('^1There no SP game');
   spgame_folder:='';
   maps_folder:='maps\';

   Result:=true;
   Exit;
end;

 //////////////////////////////////
// map
if par[1] = 'map' then
 begin
   Result:=true;
   if NET.Type_=NT_CLIENT then
   begin
      Log('^1 Server-side command!');
      Exit;
   end;
   par[2] := trim(par[2]);
   str := Engine_Dir + Engine_ModDir;
   i := pos(str, par[2]);
   if i <> 0 then
      Delete(par[2], i , Length(str));
   LoadMap(par[2]);
   Exit;
 end;

if par[1] = 'map_list' then
 begin
 str := Engine_Dir + Engine_ModDir + MAPS_FOLDER;
 Log('^3--- Map List (' + IntTostr(GetMapCount(str)) + ') ---');
 GetMapList(str);
 Log('^3-------------------');
 Exit;
 end;

if par[1] = 'model_list' then
 begin
 Log('^3--- Model List (' + IntTostr(Length(ModelName)) + ') ---');
 for i := 0 to Length(ModelName) - 1 do
  Log(' ' + ModelName[i]);
 Log('^3---------------------');
 Exit;
 end;

if par[1] = 'gametype' then
 begin
 if par[2] = '' then
  begin
  Log('^3GameType is ^7"' + GetGameType(gametype_c) + '^7"');
  Log('^3Possible values:');
  j := 1;
  for i := 1 to 8 do
   begin
   str := ' ' + GetGameType(j);
   if str = ' ' then
    break;
   Log(str);
   j := j shl 1;
   end;
  Log('^3----------------');
  end
 else
  if SetGameType(par[2]) then
   begin
   Log('^2GameType changed to ^7"' + GetGameType(gametype_c) + '^7"');
   cfgProc(cmd);
   end
  else
   Log('^1Invalid GameType ^7"' + par[2] + '^7"');
 Exit;
 end;

if par[1] = 'demo' then
 begin
 if ExtractFileExt(par[2]) <> 'tdm' then
  par[2] := par[2] + '.tdm';
 str_ := trim(par[2]);
 str := Engine_Dir + Engine_ModDir + 'demos\';
 par[2] := GetFilePath(str, str_);

 if FileExists(par[2]) then
    if NET.Type_=NT_Client then
       NET_Create(false);

 str := Engine_Dir + Engine_ModDir;
 i := pos(str, par[2]);
 if i <> 0 then
  Delete(par[2], i , Length(str));
 if par[2] = '' then
  par[2] := str_;
 LoadMap(par[2], false);
 Exit;
 end;

if par[1] = 'sp_load' then
begin
  Result:=true;
  s:=Engine_Dir + Engine_ModDir+'saves\'+par[2]+'.tsg';
  if FileExists(s) then
  begin
    s1:=s;
    s:=Map.LoadGameFileName(s);
    if ExtractFileExt(s) <> 'tm' then
    s := s + '.tm';
    str := Engine_Dir + Engine_ModDir + MAPS_FOLDER;
    str_ := trim(s);
    s := GetFilePath(str, str_);
    str := Engine_Dir + Engine_ModDir;
    if Map.LoadGame(s1, s)<>0 then
      Log('Savegame is broken');
   end else Log('^1Savegame not found');
 Exit;
end;

if par[1] = 'fade' then
begin
   if not Map.IsClientGame then
      Map.fade_out:=not Map.fade_out;
   Result:=true;
   Exit;
end;

/// КОММАНДЫ ИГРЫ
if par[1] = 'say' then
 begin
 if Map.pl_find(-1, C_PLAYER_p1) then
  begin
  Result := true;
  str_ := trim(cmd); // Нам не нужен lowercase
  Delete(str_, 1, 4);
  //Console_DeleteMsg(0); // Удаляем предыдущую мессагу :)
  Map.Say(Map.pl_current.uid, str_);
  end;
 Exit;
 end;

if par[1] = 'onsay' then
 begin
 onsay := not onsay;
 SayEdit.Text := '';
 Exit;
 end;

if par[1] = 'sv_name' then
 begin
 if trim(par[2]) = '' then
  Log('^3sv_name is ^7"^b' + sv_name + '^n^7"')
 else
  begin
  sv_name := trim(Copy(cmd, Length(par[1]) + 1, Length(cmd)));
  cfgProc('sv_name ' + sv_name);
  Log('^2sv_name changed to ^7"^b' + sv_name + '^n^7"');
  end;
 Exit;
 end;

if par[1] = 'sv_pass' then
 begin
 if trim(par[2]) = '' then
  begin
  sv_pass := '';
  Log('^2sv_pass removed')
  end
 else
  begin
  sv_pass := trim(Copy(cmd, Length(par[1]) + 1, Length(cmd)));
  Log('^2sv_pass changed to ^7"' + sv_pass + '^7"');
  end;
 cfgProc('sv_pass ' + sv_pass);
 Exit;
 end;

if par[1] = 'name' then
 begin
 if Map <> nil then
  if trim(par[2]) <> '' then
   begin
   str := trim(cmd);
   StrSpace(str);
   p1name := trim(str);
   cfgProc('name ' + p1name);
   with Map do
    	if pl_find(-1, C_PLAYER_p1) then
     		SetPlayerName(pl_current.uid, p1name);
   end
  else
   Log('name is: ' + p1name);
 Exit;
 end;

if par[1] = 'p2name' then
 begin
 if Map <> nil then
  if trim(par[2]) <> '' then
   begin
   str := trim(cmd);
   StrSpace(str);
   p2name := trim(str);
   cfgProc('p2name ' + p2name);
   with Map do
    	if pl_find(-1, C_PLAYER_p2) then
     		SetPlayerName(pl_current.UID, p2name);
   end
  else
   Log('p2name is: ' + p2name);
 Exit;
 end;

if par[1] = 'disjoin' then
   if NET.Type_=NT_CLIENT then
      par[1]:='net_disjoin'
   else
begin
   Result:=true;
   while Map.pl_find(-1, C_Player_LOCAL) do
      Map.pl_delete_current(true);
   Exit;
end;

if (par[1] = 'r_rail') or
   (par[1] = 'r_rail_p2') or
   (par[1] = 'r_rail_enemy') then
begin
   Result:=true;
   if (par[2]='') then
   begin
      if par[1]='r_rail' then
         Log('^3 R: '+IntToStr(r_rail_color.r)+' G: '+IntToStr(r_rail_color.g)+' B: '+IntToStr(r_rail_color.b)+' [0-255] type: '+IntToStr(r_rail_type)+' [0-'+IntToStr(railtype_high)+']');
      if par[1]='r_rail_p2' then
         Log('^3 R: '+IntToStr(r_p2_rail_color.r)+' G: '+IntToStr(r_p2_rail_color.g)+' B: '+IntToStr(r_p2_rail_color.b)+' [0-255] type: '+IntToStr(r_p2_rail_type)+' [0-'+IntToStr(railtype_high)+']');
      if par[1]='r_rail_enemy' then
         Log('^3 R: '+IntToStr(r_enemy_rail_color.r)+' G: '+IntToStr(r_enemy_rail_color.g)+' B: '+IntToStr(r_enemy_rail_color.b)+' [0-255] type: '+IntToStr(r_enemy_rail_type)+' [0-'+IntToStr(railtype_high)+']');
         Exit;
   end;
   if (par[5]='') then
   begin
      Log('^1Parameter missing: '+par[1]+' R G B [0-255] railtype [0-'+IntToStr(railtype_high)+']');
      Exit;
   end;
   i:=strtoint(par[2]);
   j:=strtoint(par[3]);
   k:=strtoint(par[4]);
   l:=strtoint(par[5]);
   if (i<0) or (i>=256) or (j<0) or (j>=256) or (k<0) or (k>=256) or
      (l<0) or (l>railtype_high) then
   begin
      Log('^1Invalid Parameter: '+par[1]+' R G B [0-255] railtype [0-'+IntToStr(railtype_high)+']');
      Exit;
   end;
   if par[1] = 'r_rail' then
   begin
      r_rail_color:=RGB(i, j, k);
      r_rail_type:=l;

      if Map.pl_find(-1, C_PLAYER_P1) then
         with Map.pl_current do
      begin
         railcolor:=r_rail_color;
         railtype:=r_rail_type;
         if NET.Type_=NT_SERVER then
            NET_Server.changename_Send(uid, name, modelname);
      end;
      str:='^2 Player1 rail set to';
   end else
   if par[1] = 'r_rail_p2' then
   begin
      r_p2_rail_color:=RGB(i, j, k);
      r_p2_rail_type:=l;

      if Map.pl_find(-1, C_PLAYER_P2) then
         with Map.pl_current do
      begin
         railcolor:=r_p2_rail_color;
         railtype:=r_p2_rail_type;
         if NET.Type_=NT_SERVER then
            NET_Server.changename_Send(uid, name, modelname);
      end;
      str:='^2 Player2 rail set to';
   end else
   begin
      r_enemy_rail_color:=RGB(i, j, k);
      r_enemy_rail_type:=l;
      str:='^2 Enemy rail set to';
   end;
   Log(str+'^3 R: '+par[2]+' G: '+par[3]+' B: '+par[4]+' type: '+par[5]);
   cfgproc(par[1]+' '+par[2]+' '+par[3]+' '+par[4]+' '+par[5]);
   Exit;
end;

// Смена модели игрока
if par[1] = 'model' then
 begin
 if Map <> nil then
  if trim(par[2]) <> '' then
   begin
   p1model := trim(par[2]);
   with Map do
    if pl_find(-1, C_PLAYER_p1) then
     SetPlayerModel(pl_current.uid, p1model);
   cfgProc('model ' + p1model);
   if not ModelUpdate then
    begin
    ModelUpdate := true;
    Menu_SetModel(1);
    ModelUpdate := false;
    end;
   end
  else
   Log('model is: ' + p1model);
 Exit;
 end;

if par[1] = 'p2model' then
 begin
 if Map <> nil then
  if trim(par[2]) <> '' then
   begin
   p2model := trim(par[2]);
   with Map do
    if pl_find(-1, C_PLAYER_p2) then
     SetPlayerModel(pl_current.uid, p2model);
   cfgProc('p2model ' + p2model);
   if not ModelUpdate then
    begin
    ModelUpdate := true;
    Menu_SetModel(2);
    ModelUpdate := false;
    end;
   end
  else
   Log('p2model is: ' + p2model);
 Exit;
 end;

if not IsGame then
 begin
 Log('^2This command does not work in main menu!');
 Exit;
 end;

if par[1] = 'join' then
begin
   Result:=true;
   if gametype and GT_TEAMS=0 then
   begin
      Log('^2You are not in TeamPlay');
      Exit;
   end;
   if par[2]='' then
   begin
      Log('^2There are BLUE and RED commands');
      Exit;
   end;
   if par[2]='red' then
   begin
      with Map do
      if pl_find(-1, C_PLAYER_P1) then
         TeamJoin(pl_current.uid, TEAM_RED, true);
      Exit;
   end;
   if par[2]='blue' then
   begin
      with Map do
      if pl_find(-1, C_PLAYER_P1) then
         TeamJoin(pl_current.uid, TEAM_BLUE, true);
      Exit;
   end;
   Log('^2Invalid command name');
   Exit;
end;

if par[1] = 'p2join' then
begin
   Result:=true;
   if gametype and GT_TEAMS=0 then
   begin
      Log('^2You are not in TeamPlay');
      Exit;
   end;
   if par[2]='' then
   begin
      Log('^2There are BLUE and RED commands');
      Exit;
   end;
   if par[2]='red' then
   begin
      with Map do
      if pl_find(-1, C_PLAYER_P2) then
         TeamJoin(pl_current.uid, TEAM_RED, true);
      Exit;
   end;
   if par[2]='blue' then
   begin
      with Map do
      if pl_find(-1, C_PLAYER_P2) then
         TeamJoin(pl_current.uid, TEAM_BLUE, true);
      Exit;
   end;
   Log('^2Invalid command name');
   Exit;
end;


if par[1] = 'sp_save' then
begin
  Result:=true;
  if not Map.stopped then
   if NET.Type_=NT_NONE then
 begin

    CreateDir(Engine_Dir + Engine_ModDir+'saves');
    s:=Engine_Dir + Engine_ModDir+'saves\'+par[2]+'.tsg';

    Map.SaveGame(s);
    Log('^2Game saved to '+s);

 end else Log('^1I can''t save multiplayer game');

 Exit;

end;

if par[1] = 'give' then
 begin
    Result:=true;
    if NET.Type_=NT_NONE then
 with Map do
  for i := 0 to WPN_Count - 1 do
   if WeaponExists(i) then
    begin
    with Player[0].pstruct do
     begin
     health     := 200;
     armor      :=200;
   	 Has_wpn[i] := 1;
   	 Ammo[i]    := 999;
     end;
    if Players > 1 then
     with Player[1].pstruct do
      begin
      health     := 200;
      armor      := 200;
   	  Has_wpn[i] := 1;
   	  Ammo[i]    := 999;
      end;
   end;
 Exit;
 end;

if par[1] = 'stats' then
 begin
 Map.ConsoleShowStats;
 Exit;
 end;

 //////////////////////////////////
// activate (убрать)
if par[1] = 'activate' then
 begin
 i:=StrToInt(par[2]);
   Map.ActivateTarget(i);
 Exit;
 end;

if par[1] = 'autorecord' then
 begin
	Result:=true;
  	if not Map.Demo.RecStart(true) then
   	 Log('^1unable to record demo');
  	Exit;
 end;

if par[1] = 'record' then
 begin
	Result:=true;
  if par[2]<>'' then
  begin
   if pos('.tm', par[2])=0 then par[2]:=par[2]+'.tdm';
   Map.Demo.demofilename:=Engine_ModDir + 'demos\'+par[2];
  	if not Map.Demo.RecStart then
   	 Log('^1unable to record demo');
  	Exit;
  end else
     Log('^1 missing parameter: filename. Use: record <filename>');
 end;

if par[1] = 'stoprecord' then
 begin
  Result:=true;
  if Map.Demo.recording then
     Map.Demo.RecStop
  else Log('^1demo is not recording');
  Exit;
 end;

if par[1] = 'bg' then
 begin
 par[2] := Copy(str_, 4, Length(str_));
 if par[2] <> '' then
  begin
  Tex.Filter := true;
  Tex.Scale  := true;
  Tex.Trans  := false;
  if xglTex_Load(PChar('Textures\BackGround\' + par[2]), @Tex) then
   begin
   if Map <> nil then
    begin
    xglTex_Free(@Map.BackGround);
    Map.BackGround := Tex;
    end;
   bg := par[2];
   cfgProc('bg ' + bg);
   end
  else
   Log('^1Can''t load ^7"' + par[2] + '^7"');
  end
 else
  Log('^3background is ^7"' + bg + '^7"');
 Exit;
 end;

{if par[1] = 'sc_record' then
 begin
	Result:=true;
   if Map.NewScenario then
   	Log('^2Recording new scenario!')
      else Log('^2Unknown Error');
  	Exit;
 end;

if par[1] = 'sc_stop' then
 begin
	Result:=true;
   if Map.StopScenario then
   	Log('^2Scenario Saved')
      else Log('^2Unknown Error');
  	Exit;
 end;

if par[1] = 'sc_play' then
 begin
	Result:=true;
   if Map.PlayScenario(0) then
   	Log('^2Scenario Started')
      else Log('^2Unknown Error');
  	Exit;
 end;

 if par[1] = 'sc_list' then
 begin
    Result:=true;
    Map.ScenarioList;
    Exit;
 end;

 if par[1] = 'sc_clear' then
 begin
	Result:=true;
   DeleteSectionFromFile('ScenarioV1', map.lastfilename, map.lastfilename);
   Log('^2Scenario Clear!');
  	Exit;
 end;}

if NET.Type_=NT_CLIENT then
begin
   Log('^1Server-side command!');
   Result:=true;
   Exit;
end;
//////////////////////////////////
// restart
if par[1] = 'restart' then
 begin
 if gametype_c <> gametype then
  begin
  str := Map.lastfilename;
  LoadMap(str, false);
  end
 else
  Map.Restart;
 Log('map restarted');
 Exit;
 end;

if par[1] = 'ready' then
begin
   Result:=true;
   if not Map.IsClientGame then
   begin
      if Map.warmup then
      begin
         if HUD_GetTime>250 then
            HUD_SetTime(250);
         Map.Demo.RecTime;
      end;
   end;
   Exit;
end;


if par[1] = 'cam_nextplayer' then
 begin
 if Map.Camera.NextPlayer then
  if Map.Camera.Target <> nil then
   Log('^3Following ^7' + Map.Camera.Target.Name)
  else
   Log('^3Free camera mode');
 Exit;
 end;

if par[1] = 'cam_prevplayer' then
 begin
 if Map.Camera.PrevPlayer then
  if Map.Camera.Target <> nil then
   Log('^3Following ^7' + Map.Camera.Target.Name)
  else
   Log('^3Free camera mode');
 Exit;
 end;


//КОММАНДЫ ДЕМКИ
if not Map.Demo.playing then
 begin
 Log('^2This command does not work in main menu!');
 Result := false;
 Exit;
 end;

if par[1] = 'demo_skip' then
 try
  Result:=true;
  i := StrToInt(par[2]);
  if i >= 0 then
   begin
   if Map.Demo.playing then
   	Map.Demo.Skip(i*50)
   else
    Log('^1demo is not playing');
   end
  else
   Log('Illegal time parameter!');
  Exit;
 except
  Log('Illegal time parameter!');
 end;

if par[1] = 'demo_goto' then
 try
  Result:=true;
  i:=StrToInt(par[2]);
  if i>=0 then
   begin
   if Map.Demo.playing then
   	Map.Demo.Go(i*50)
   else
    Log('^1demo is not playing');
   end
  else
   Log('Illegal time parameter!');
  Exit;
 except
  Log('Illegal time parameter!');
 end;

Result := false;
end;


// BOT DLL COMMANDS //
function Bot_Cmd(Cmd: ShortString): boolean;
var
 par : array [1..3] of string;
 i   : integer;
 str : string;
begin
Result := true;
str    := Func_Lib.LowerCase(trim(cmd));
for i := 1 to 3 do
 par[i] := StrSpace(str);

// Loading bot dll
if par[1] = 'bot_load' then
 begin
 if par[2] <> '' then
  if ExtractFileExt(par[2]) <> 'dll' then
   par[2] := par[2] + '.dll';
 RegisterBotDLL(par[2]);
 cfgProc('bot_load ' + par[2]);
 Exit;
 end;

// Get bot version
if par[1] = 'bot_version' then
 begin
 if @DLL_QUERY_VERSION <> nil then
  Log(DLL_QUERY_VERSION)
 else
  if BOT_DLL = 0 then
   Log('Bot: ^3bot dll libary not loaded');
 Exit;
 end;

Result := false;
end;

function IsGame: boolean;
begin
	Result:=Map.lastfilename<>'';
end;

end.

