unit TFK;
(***************************************)
(*      <<<<< TIME FOR KILL >>>>>      *)
(***************************************)
(*   http://timeforkill.mirgames.ru    *)
(***************************************)

interface

uses
 Windows, Messages, SysUtils, OpenGL,
 Engine_Reg,
 Constants_Lib,
 Graph_Lib,
 Func_Lib,
 Math_Lib,
 Type_Lib,
 Player_Lib,
 Map_Lib,
 MapObj_Lib,
 ObjAnim_Lib,
 ObjSound_Lib,
 Game_Lib,
 HUD_Lib,
 Particle_Lib,
 Menu_Lib,
 Bot_Lib,
 NET_Lib,
 Arena_Lib;

var
//console
 Console     : PConsoleProp; //Параметры консоли
 ConsoleTex1 : TTexData;
 ConsoleTex2 : TTexData;
 CTC         : array [1..2] of TPoint2f;
 ConPi       : single;
 ConScale    : single;
//other
 stencil_counter : DWORD;

function MOD_Name: ShortString; stdcall;
procedure MOD_Init; stdcall;
procedure MOD_Free; stdcall;

procedure MOD_Draw; stdcall;
procedure MOD_DrawConsoleBG;
procedure MOD_Update; stdcall;
procedure MOD_Message(message: UINT; wParam: Longint; lParam: LongInt); stdcall;
procedure MOD_WriteCmd(FileName: ShortString); stdcall;

implementation

uses MyMenu, Binds_Lib, Timing_Lib;

//Узнаём имя мода
function MOD_Name: ShortString; stdcall;
begin
Result:='TIME FOR KILL v0.48';
end;

//Врубаем мод (Загрузка всех элементов)
procedure MOD_Init; stdcall;
begin
//Console
Console := Console_Prop;
Console^.Font.Filter := true;
Console^.Font.Trans  := false;
Font_Create('Textures\Font\Font1.tga', @Console.Font);

ConsoleTex1.Filter:=true;
ConsoleTex1.Trans:=false;
xglTex_Load('Textures\gfx\console01.tga', @ConsoleTex1);

ConsoleTex2.Filter:=true;
ConsoleTex2.Trans:=false;
xglTex_Load('Textures\gfx\console02.jpg', @ConsoleTex2);
ConPi := 0;

//Устанавливаем процедуру конфига
Console_SetCfgProc(@cfgProc);

con_drawbg := true;
con_alpha := 255;
inMenu := true;
NET_Init;
Menu_Init;
Game_Init;
stencil_counter := GetTickCount;
end;

procedure MOD_Free; stdcall;
begin
Arena_Free;

SaveBinds('config.cfg');
//пришлось изменить
FreeBotDll;
//Map
Map.Free;
//Menu
Menu_Free;
//Particles
Particle_Free;
//Textures
ObjTex_BeginLoad;
ObjTex_EndLoad;
ObjTex_MenuBeginLoad;
ObjTex_EndLoad;

snd_BeginUpdate;
snd_EndUpdate;

//Console
xglTex_Free(@Console.Font);
xglTex_Free(@ConsoleTex1);
xglTex_Free(@ConsoleTex2);
end;

procedure MOD_Draw; stdcall;
begin
if inMenu then
 begin
 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
 Timing_Start('Menu Draw');
 Menu_Draw;
 Timing_End('Menu Draw');
 end
else
 begin
 if d_clearbit then
  glClear(GL_COLOR_BUFFER_BIT);
 // чистим стенсил 2 раза в секунду (на всякий) для телепортов
 if GetTickCount - stencil_counter >= 500 then
  begin
  glClear(GL_STENCIL_BUFFER_BIT);
  stencil_counter := GetTickCount;
  end;
 
 Game_Draw;
 end;
if con_drawbg and (con_alpha > 0) then
 begin
 xglViewPort(0, 0, xglWidth, xglHeight, false);
 MOD_DrawConsoleBG;
 end;
if d_timing then
   Timing_Draw;
end;

procedure MOD_DrawConsoleBG;
begin
with Console^ do
 begin
 if Height <= 0 then Exit;

 if con_alpha = 255 then
  xglAlphaBlend(0)
 else
  xglAlphaBlend(1);

 glColor4ub(255, 255, 255, con_alpha);
 if ConsoleTex1.ID <> 0 then
  begin
  xglTex_Enable(@ConsoleTex1);
  glBegin(GL_QUADS);
   glTexCoord2f(CTC[1].X+2, CTC[1].Y);   glVertex2f(0,   0);
   glTexCoord2f(CTC[1].X,   CTC[1].Y);   glVertex2f(xglWidth, 0);
   glTexCoord2f(CTC[1].X,   CTC[1].Y+1); glVertex2f(xglWidth, Height);
   glTexCoord2f(CTC[1].X+2, CTC[1].Y+1); glVertex2f(0,   Height);
  glEnd;
  end;

 if ConsoleTex2.ID <> 0 then
  begin
  xglAlphaBlend(2);
  xglTex_Enable(@ConsoleTex2);
  glBegin(GL_QUADS);
   glTexCoord2f(CTC[2].X+2-ConScale, CTC[2].Y+ConScale);   glVertex2f(0,   0);
   glTexCoord2f(CTC[2].X+ConScale,   CTC[2].Y+ConScale);   glVertex2f(xglWidth, 0);
   glTexCoord2f(CTC[2].X+ConScale,   CTC[2].Y+1-ConScale); glVertex2f(xglWidth, Height);
   glTexCoord2f(CTC[2].X+2-ConScale, CTC[2].Y+1-ConScale); glVertex2f(0,   Height);
  glEnd;
  end;

 xglTex_Disable;
 glDisable(GL_BLEND);

 glLineWidth(3);
 glDisable(GL_LINE_SMOOTH);
 glColor3f(1, 1, 0);
 glBegin(GL_LINES);
  glVertex2f(0,        Height);
  glVertex2f(xglWidth, Height);
 glEnd;

 glLineWidth(1);
 end;

end;

procedure MOD_Update; stdcall;
begin
Timing_Start('NET Update');
NET_Update;
Timing_End('NET Update');

Engine_SetUPS(cg_ups);
//Console
if con_drawbg then
 begin
 CTC[1].X := CTC[1].X - 0.0008;
 CTC[1].Y := 0;
 ConPi := ConPi + 0.005;
 ConScale := abs(sin(ConPi))/10;
 CTC[2].X := CTC[2].X - ConScale/40-0.001;
 CTC[2].Y := CTC[2].Y + ConScale/80+0.001;
 end;
//Game
if inMenu then
begin
 Timing_Start('Menu Update');
 Menu_Update;
 Timing_End('Menu Update');
end;
if not inMenu or Net_Game then
 Game_Update;
end;

procedure MOD_Message(message: UINT; wParam: Longint; lParam: LongInt); stdcall;
var
 Msg: TMessage;
begin
if not Console.Show then
 begin
 if (message = WM_KEYDOWN) and (wParam = 27) and IsGame then
   if inmenu and not ActiveWindow.Locked then
   CallGameMenuOff
  else
   CallGameMenuOn;

 if inMenu then
  Menu_Message(message, wParam, lParam);

 if onSay and (message <> WM_MOUSEMOVE) then
  begin
  Msg.Msg := message;
  Msg.wParam := wParam;
  Msg.lParam := lParam;
  SayEdit.Active := true;
  SayEdit.onMessage(Msg);
  if message = WM_KEYDOWN then
   case wParam of
    VK_RETURN : begin
                if SayEdit.Text <> '' then
                 Console_Cmd('say ' + SayEdit.Text);
                onsay := false;
                end;
   end;
  end;
 end;
end;

procedure MOD_WriteCmd(FileName: ShortString); stdcall;
var
 F : TextFile;
begin
SaveBinds(FileName);
 try
  AssignFile(F, Engine_ModDir + FileName);
  if not FileExists(Engine_ModDir + FileName) then
   Rewrite(F);
  Append(F);
  writeln(F, 'gametype ' + IntToStr(gametype_c));
  writeln(F, 'sv_name ' + sv_name);
  writeln(F, 'sv_pass ' + sv_pass);
  writeln(F, 'name ' + p1name);
  writeln(F, 'p2name ' + p2name);
  writeln(F, 'model ' + p1model);
  writeln(F, 'p2model ' + p2model);
  writeln(F, 'bg ' + bg);
  writeln(F, 'r_rail ' + inttostr(r_rail_color.R)+' '+ inttostr(r_rail_color.G)+' '+inttostr(r_rail_color.B)+' '+inttostr(r_rail_type)); 
  writeln(F, 'r_rail_p2 ' + inttostr(r_p2_rail_color.R)+' '+ inttostr(r_p2_rail_color.G)+' '+inttostr(r_p2_rail_color.B)+' '+inttostr(r_p2_rail_type)); 
  writeln(F, 'r_rail_enemy ' + inttostr(r_enemy_rail_color.R)+' '+ inttostr(r_enemy_rail_color.G)+' '+inttostr(r_enemy_rail_color.B)+' '+inttostr(r_enemy_rail_type)); 
  CloseFile(F);
 except
  Log(Engine_ModDir + FileName);
 end;
end;

end.