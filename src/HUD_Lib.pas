unit HUD_Lib;

interface

uses
 Windows, OpenGL,
 Engine_Reg,
 Type_Lib,
 Graph_Lib,
 Constants_Lib,
 Func_Lib,
 Player_Lib,
 ObjAnim_Lib,
 ObjSound_Lib,
 Particle_Lib;

type
 TStatusHUD = class
  private
   procedure DrawTex(X, Y: integer);
  public
   Pos     : TPoint;
   Target  : TPlayer;
   constructor Create;
   procedure Draw;
 end;

 THUDColumn =
 record
    title: string;
    width, leftmargin: integer;
    color, alpha: single;
    net: boolean;
    gametype: byte;
    active, final: boolean;
 end;

 TScoreHUD = class
  constructor Create;
  procedure Update;
  procedure Draw;
 private
 // для сортировки

  column: array [1..10] of THUDColumn;
  cc: integer;
  width: integer;
 end;

const
   HUD_COL_TEAM = 1;
   HUD_COL_NAME = 2;
   HUD_COL_FRAGS = 3;
   HUD_COL_DEATHS = 4;
   HUD_COL_SUICIDES = 5;
   HUD_COL_PING = 6;

var
 Status_HUD : array [0..1] of TStatusHUD;
 Score_HUD  : TScoreHUD;

 procedure HUD_Init;
 procedure HUD_Update;
 procedure HUD_Draw;
 procedure HUD_Restart;
 procedure HUD_ViewPort(X, Y: integer);
 procedure HUD_SetTime(Time: cardinal);
 function HUD_GetTime : cardinal;
 function HUD_GetTimeMin : cardinal;
 function HUD_GetTimeSec : cardinal;
 function HUD_GetTimeMS : cardinal;

 function HUD_GetMaxFrags: integer;
 function HUD_GetMinFrags: integer;

 function HUD_Cmd(Cmd: ShortString): boolean;

implementation

uses
 Map_Lib, TFK, binds_Lib, NET_Lib;

var
 HUD_Time: cardinal;

 NumbTex : TObjTex;
 IconTex : TObjTex;
 WeapTex : TObjTex;
 StatTex : TTexData;

procedure HUD_Init;
begin                                
StatTex.Scale  := true;
StatTex.Trans  := true;
StatTex.TransC := RGBA(0, 0, 255, 0);
xglTex_Load('textures\HUD\status', @StatTex);

Score_HUD     := TScoreHUD.Create;
Status_HUD[0] := TStatusHUD.Create;
Status_HUD[1] := TStatusHUD.Create;
end;

procedure HUD_Update;
begin
// 3000 = 60 * 50
if Map.stopped then
 begin
 //показ одной/двух боковых панелей со статистикой :)
 end
else
 if not Map.paused then
 begin

    if Map.warmup then
    begin
       if (HUD_Time > 0) then
          Dec(HUD_Time);
    end else
  if not Map.IsClientGame then //XProger: Ибо в демках время до таймлимита только доходило :)
   if (HUD_Time < timelimit*50*60) or (timelimit=0) then
    inc(HUD_Time)
   else
    HUD_Time := 0
  else
   inc(HUD_Time);

  end;
 Score_HUD.Update;
end;

procedure HUD_Draw;
var
 str  : string;
 m, s : integer;
begin
   if Map.pl_find(-1, C_PLAYER_p1) then
   begin
      Status_HUD[0].Target:=Map.pl_current;
      if Map.pl_find(-1, C_PLAYER_p2) then
         Status_HUD[1].Target:=Map.pl_current
   end
   else if Map.pl_find(-1, C_PLAYER_p2) then
      Status_HUD[0].Target:=Map.pl_current
   else Status_HUD[0].Target:=Map.Camera.Target;

if hud_status_alpha > 0 then

HUD_ViewPort(0, 0);
glPushMatrix;
if splitscreen = SPLIT_HORIZ then
 if hud_simple then
  begin
  glTranslatef(640 - StatTex.Width, 240 - StatTex.Height, 0);
  Status_HUD[0].Draw;
  glTranslatef(0, 240, 0);
  Status_HUD[1].Draw;
  end
 else
  begin
  glTranslatef(0, -240, 0);
  Status_HUD[0].Draw;
  glTranslatef(0, 240, 0);
  Status_HUD[1].Draw;
  end
else
 if (splitscreen = SPLIT_VERT) or cam_fixed then
  begin
  glTranslatef(0, 480 - StatTex.Height, 0);
  Status_HUD[1].Draw;
  glTranslatef(640 - StatTex.Width, 0, 0);
  Status_HUD[0].Draw;
  end
 else
  if hud_simple then
   begin
   glTranslatef(640 - StatTex.Width, 480 - StatTex.Height, 0);
   Status_HUD[0].Draw;
   end
  else
   Status_HUD[0].Draw;
glPopMatrix;

HUD_ViewPort(0, 0);
if (PKeys[1, KEY_SCOREBOARD].Down) and not Console.Show or
   Map.stopped then
 Score_HUD.Draw;

if Map.warmup then
begin
   m:=HUD_Time div 50+1;
   str:='^2WARMUP ^3'+inttostr(m);
   Text_TagOut(260, 30, @Console.Font, true, PChar(str));
end else
begin
//draw time
m := HUD_Time div 50 div 60;
s := HUD_Time div 50 mod 60;
str := IntToStr(m) + ':';
if s < 10 then
 str := str + '0' + IntToStr(s)
else
 str := str + IntToStr(s);
// тень
glColor4f(0, 0, 0, 1);
TextOut(576, 11, PChar(str));
// время
glColor4f(1, 1, 1, 1);
TextOut(575, 10, PChar(str));
//Score_HUD.Draw;
end;
end;

procedure HUD_Restart;
begin
HUD_Time := 0;
if NumbTex <> nil then NumbTex.Free;
if IconTex <> nil then IconTex.Free;
if WeapTex <> nil then WeapTex.Free;
NumbTex := TObjTex.Create('textures\HUD\numbers', 32, 32, 25, true, false, nil);
IconTex := TObjTex.Create('textures\HUD\icons', 32, 32, 25, true, false, nil);
WeapTex := TObjTex.Create('textures\HUD\weapbar', 16, 16, 1, true, false, nil);
end;

procedure HUD_ViewPort(X, Y: integer);
begin
glViewport(X, Y, xglWidth, xglHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
gluOrtho2D(0, 640, 480, 0);
glMatrixMode(GL_MODELVIEW);										// ???????? ??????? ???????
glLoadIdentity;
end;

procedure HUD_SetTime(Time: cardinal);
begin
// Time измеряется в тиках
HUD_Time := Time;
end;

function HUD_GetTime : cardinal;
begin
Result := HUD_Time;
end;

function HUD_GetTimeMin : cardinal;
begin
Result := HUD_Time div 3000;
end;

function HUD_GetTimeSec : cardinal;
begin
Result := HUD_Time mod 3000 div 50;
end;

function HUD_GetTimeMS : cardinal;
begin
Result := HUD_Time mod 50*20;
end;


function HUD_GetMaxFrags: integer;
begin
Result := 0;
end;

function HUD_GetMinFrags: integer;
begin
Result := 0;
end;

function HUD_Cmd(Cmd: ShortString): boolean;
var
 par : array [1..3] of string;
 i   : integer;
 str : string;
begin
Result := true;
str    := cmd;
for i := 1 to 3 do
 par[i] := StrSpace(str);
end;

(*===================*)
(*  TStatusHUD       *)
(*===================*)
constructor TStatusHUD.Create;
begin
Target  := nil;
end;

procedure TStatusHUD.DrawTex(X, Y: integer);
begin
glBegin(GL_QUADS);
 glTexCoord2f(0, 1); glVertex2f(X,  Y);
 glTexCoord2f(1, 1); glVertex2f(X + 32, Y);
 glTexCoord2f(1, 0); glVertex2f(X + 32, Y + 32);
 glTexCoord2f(0, 0); glVertex2f(X,  Y + 32);
glEnd;
end;

procedure TStatusHUD.Draw;

 procedure DrawValue(X, Y: integer; Value: integer);
 var
  i : integer;
  s : string;
 begin
 s := intToStr(Value);
 for i := Length(s) downto 1 do
  begin
  dec(X, 32);
  if s[i] = '-' then
   xglTex_Enable(NumbTex.Frame[10])
  else
   xglTex_Enable(NumbTex.Frame[StrToInt(s[i])]);
  DrawTex(X, Y);
  end;
 end;

 procedure DrawWpn(i: integer; x: integer);
 begin
 xglTex_Enable(WeapTex.Frame[i]);
 glBegin(GL_QUADS);
  glTexCoord2f(0, 1); glVertex2f(x,  0);
  glTexCoord2f(1, 1); glVertex2f(x + 16, 0);
  glTexCoord2f(1, 0); glVertex2f(x + 16, 16);
  glTexCoord2f(0, 0); glVertex2f(x,  16);
 glEnd;
 end;

var
 alpha : single;
 i     : integer;
 sx    : integer;

 procedure SetColor(Value: integer);
 var
  r, g, b : single;
 begin
 r := 0.3;
 g := 0.3;
 b := 0.3;
 if Value <= 30 then
  r := 1
 else
  if Value <= 80 then
   begin
   r := 1;
   g := 1;
   end
  else
   if Value <= 125 then
    g := 1
   else
    b := 1;
 glColor4f(r, g, b, alpha);
 end;

begin
if Target <> nil then
 begin
 alpha := hud_status_alpha/255;
 with Target do
  begin
  if cam_fixed or (SplitScreen = SPLIT_VERT) or hud_simple then
   begin
   glColor4f(1, 1, 1, alpha);
   xglTex_Enable(@StatTex);
   glBegin(GL_QUADS);
    glTexCoord2f(0, 1); glVertex2f(0,  0);
    glTexCoord2f(1, 1); glVertex2f(StatTex.Width, 0);
    glTexCoord2f(1, 0); glVertex2f(StatTex.Width, StatTex.Height);
    glTexCoord2f(0, 0); glVertex2f(0,  StatTex.Height);
   glEnd;
   if Health <= 0 then
    begin
    glColor4f(1, 0, 0, alpha);
    TextOut(16, 2, 'RIP');
    end
   else
    if hud_color_health then
     begin
     SetColor(Health);
     TextOut(16, 2, PChar(IntToStr(Health)));
     end
    else
     TextOut(16, 2, PChar(IntToStr(Health)));

   glColor4f(1, 1, 1, alpha);

    if hud_color_armor then
     begin
     SetColor(Armor);
     TextOut(16, 18, PChar(IntToStr(Armor)));
     end
    else
     TextOut(16, 18, PChar(IntToStr(Armor)));

   glColor4f(1, 1, 1, alpha);
   if cur_weapon <> WPN_GAUNTLET then
  	TextOut(16, 34, PChar(IntToStr(Ammo[cur_weapon])));

   TextOut(16, 50, PChar(IntToStr(stat.frags)));

   if (lastwpnchange < 100) then
    begin
    glPushMatrix;
    if Target = Map.Player[0] then
     begin
     sx := 0;
     for i := 0 to WPN_COUNT -1 do
      if Has_wpn[i] <> 0 then
       sx := sx - 16;
     end
    else
     sx := StatTex.Width;
    glTranslatef(sx, StatTex.Height - 16, 0);
    sx := 0;

    for i := 0 to WPN_COUNT -1 do
     if Has_wpn[i] > 0 then
      begin
      DrawWpn(i, sx);
      if Ammo[i] = 0 then
       DrawWpn(10, sx); // нет патронов
      if i = cur_wpn then
       DrawWpn(9, sx); // следующее оружие
      inc(sx, 16);
      end;

    glPopMatrix;
    end;

   end
  else
   begin
  // оружие
   glColor4f(0.8, 0.7, 0, alpha);
   if cur_weapon<>WPN_GAUNTLET then
   	DrawValue(100, 433, Ammo[cur_weapon]);
   glColor4f(1, 1, 1, alpha);
   xglTex_Enable(IconTex.Frame[cur_weapon]);
   DrawTex(105, 433);
  // здоровье
   if Health > 100 then
    glColor4f(1, 1, 1, alpha)
   else
    glColor4f(0.8, 0.7, 0, alpha);

   DrawValue(280, 433, Health);
   glColor4f(1, 1, 0, alpha);
   xglTex_Enable(IconTex.Frame[10]);
   DrawTex(285, 433);
  // броня
   if Armor > 0 then
    begin
    glColor4f(0.8, 0.7, 0, alpha);
    DrawValue(470, 433, Armor);
    glColor4f(1, 1, 0, alpha);
    xglTex_Enable(IconTex.Frame[11]);
    DrawTex(475, 433);
    end;
   end;

  end;
 end;
end;

(*===================*)
(*  TScoreHUD        *)
(*===================*)
constructor TScoreHUD.Create;
begin
   cc:=6;
   with column[1] do
   begin
      title:='^1Team';
      width:=40;
      leftmargin:=0;
      color:=0.8; alpha:=0.5;
      gametype:=GT_TEAMS;
   end;
   with column[2] do
   begin
      title:='^1Name';
      width:=264;
      leftmargin:=10;
      color:=0.6; alpha:=0.5;
   end;
   with column[3] do
   begin
      title:='^1Frags';
      width:=50;
      leftmargin:=0;
      color:=0.5; alpha:=0.5;
   end;
   with column[4] do
   begin
      title:='^1Deaths';
      width:=60;
      leftmargin:=0;
      color:=0.6; alpha:=0.5;
   end;
   with column[5] do
   begin
      title:='^1Suicides';
      width:=100;
      leftmargin:=0;
      color:=0.5; alpha:=0.5;
      final:=true;
   end;
   with column[6] do
   begin
      title:='^1Ping';
      width:=50;
      leftmargin:=0;
      color:=0.7; alpha:=0.4;
      net:=true;
   end;
end;

procedure TScoreHUD.Update;
var
   i: integer;

begin
   width:=0;
   for i:=1 to cc do
   begin
      column[i].active:=(not column[i].net or (NET.Type_<>NT_NONE) ) and
                        ((column[i].gametype and gametype>0) or (column[i].gametype=0)) and
                        (not column[i].final or Map.stopped);
      if column[i].active then
         width:=width+column[i].width;
   end;
end;

procedure TScoreHUD.Draw;
var
 i, j, k, l, x, y: integer;
 MaxY : integer;
 s, tag    : string;
 pl: TPlayer;
begin
// width - ширина скорбара
l:=NET.spects_Count;
if l>0 then
   MaxY := (Map.Players+l)*16 + 52
else
   MaxY := Map.Players*16 + 36;
if gametype and GT_TEAMS>0 then
begin
   if Map.teams[TEAM_BLUE].plcount>0 then
      MaxY:=MaxY+16;
   if Map.teams[TEAM_RED].plcount>0 then
      MaxY:=MaxY+16;
end;
glPushMatrix;
glTranslatef(320-width div 2, 240 - MaxY div 2, 0);
xglAlphaBlend(1);
xglTex_Disable;
glDisable(GL_ALPHA_TEST);

glBegin(GL_QUADS);
 glColor4f(0.3, 0.3, 0.3, 0.7);
 glVertex2f(0,   16);
 glVertex2f(width, 16);
 glVertex2f(width, 0);
 glVertex2f(0,   0);

 j:=0;
 for i:=1 to cc do
    if column[i].active then
    begin
      glColor4f(column[i].color, column[i].color, column[i].color, column[i].alpha);
      glVertex2f(j,   MaxY);
      glVertex2f(j+column[i].width, MaxY);
      glVertex2f(j+column[i].width,   16);
      glVertex2f(j+0,     16);
      j:=j+column[i].width;
    end;

glEnd;

glLineWidth(1);
glBegin(GL_LINE_STRIP);
 glColor4f(0.5, 0.5, 0.5, 1);
 glVertex2f(0,   MaxY);
 glVertex2f(width, MaxY);
 glVertex2f(width,    0);
 glVertex2f(0,      0);
 glVertex2f(0,   MaxY);
glEnd;

glBegin(GL_LINES);
 glVertex2f(0,   16);
 glVertex2f(width, 16);
glEnd;

j:=0;
for i:=1 to cc do
begin
   if column[i].active then
   begin
      Text_TagOut(j+column[i].leftmargin, 0, @Console.Font, true, PChar(column[i].title));
      j:=j+column[i].width;
   end;
end;

glTranslatef(0, 26, 0);

y:=0;
for i := 0 to Map.Players - 1 do
 begin
   pl:=Map.places[i];
   tag:='';
   if gametype and GT_TEAMS>0 then
   begin
   if pl.team=TEAM_BLUE then
         tag:='^4'
   else tag:='^1';
   if (i=0) or (pl.team<>Map.places[i-1].team) then
   begin
      if pl.team=TEAM_BLUE then
         s:=tag+'Blue Team'
      else
         s:=tag+'Red Team';
      j:=0;
      for k:=1 to cc do
      begin
         x:=j+column[k].leftmargin;
         if column[k].active then
         begin
            case k of
               HUD_COL_TEAM: Text_TagOut(x, y, @Console.Font, true, PChar(s));
               HUD_COL_FRAGS: Text_TagOut(x, y, @Console.Font, true, PChar(tag+IntToStr(Map.teams[pl.team].frags)));
               HUD_COL_DEATHS: Text_TagOut(x, y, @Console.Font, true, PChar(tag+IntToStr(Map.teams[pl.team].deaths)));
            end;
            j:=j+column[k].width;
         end;
      end;
      y:=y+16;
   end;

   end;//GT_TEAMS
   s := pl.Name;

   j:=0;
   for k:=1 to cc do
   begin
      if column[k].active then
      begin
         x:=(j+column[k].leftmargin);
         case k of
            HUD_COL_NAME: Text_TagOut(x, y, @Console.Font, true, PChar(s));
            HUD_COL_FRAGS: Text_TagOut(x, y, @Console.Font, true, PChar(IntToStr(pl.Stat.Frags)));
            HUD_COL_DEATHS: Text_TagOut(x, y, @Console.Font, true, PChar(tag+IntToStr(pl.Stat.Deaths)));
            HUD_COL_SUICIDES: Text_TagOut(x, y, @Console.Font, true, PChar(tag+IntToStr(pl.Stat.Suicides)));
            HUD_COL_PING: Text_TagOut(x, y, @Console.Font, true, PChar(IntToStr(pl.current_ping div 2)));
         end;
         j:=j+column[k].width;
      end;
   end;
   y:=y+16;
 end; //FOR
glTranslatef(0, Map.Players*16, 0);
if l>0 then
begin
{   glColor4f(0.7, 0.7, 0.7, 1);
   glBegin(GL_LINES);
      glVertex2f(0,   0);
      glVertex2f(width, 0);
   glEnd;}

   Text_TagOut(width div 2-50, 0, @Console.Font, true, '^6Spectators');
   glTranslatef(0, 16, 0);

{   glColor4f(0.5, 0.5, 0.5, 1);
   glBegin(GL_LINES);
      glVertex2f(0,   0);
      glVertex2f(width, 0);
   glEnd;}

   for i:=1 to l do
   begin
      s := NET.spects[i].Name;
      j:=0;
      for k:=1 to cc do
      begin
         if column[k].active then
         begin
            case k of
               HUD_COL_NAME: Text_TagOut(j+column[k].leftmargin, (i-1)*16, @Console.Font, true, PChar(s));
               HUD_COL_PING: Text_TagOut(j+column[k].leftmargin, (i-1)*16, @Console.Font, true, PChar(IntToStr(NET.spects[i].ping div 2)));
            end;
            j:=j+column[k].width;
         end;
      end;
   end;
end;

   glPopMatrix;
end;

end.

