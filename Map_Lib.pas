unit Map_Lib;

//VERSION 1.0.1.9

//{$DEFINE DEBUG_LOG}
//{$DEFINE DEBUG2}
interface

//{$DEFINE NOSOUND}

uses
 Windows, OpenGL, SysUtils,
 Engine_Reg,
 Func_Lib,
 Type_Lib,
 Graph_Lib,
 Math_Lib,
 MyEntries,
 TFKEntries,
 MapObj_Lib,
 ItemObj_Lib,
 ObjAnim_Lib,
 ObjSound_Lib,
 Constants_Lib,
 HUD_Lib,
 Weapon_Lib,
 Real_Lib,
 Stat_Lib,
 Demo_Lib,
 Scenario_Lib,
 Particle_Lib,
 Log_Lib,
 Player_Lib,
 Model_Lib,
 LightMap_Lib,
 TFKBot_Lib,
 NET_Lib,
 Phys_Lib;

type
 TGameProps = record
  sv_gravity : smallint;
 	fraglimit  : WORD;
 	timelimit  : WORD;
 end;

type
 TCamera = class
   Pos         : TPoint2f;
   View        : TPoint2f;
   Target      : TPlayer;
   constructor Create;
   procedure Update;
   function NextPlayer: boolean;
   function PrevPlayer: boolean;
 end;

 TTeamStat =
 record
    frags, captures, deaths: integer;
    plcount: integer;
 end;

 TMap = class(TBotMap)
  private
   //игровые звуки
   function Getdemoplay: boolean;
   function Getdemorec: boolean;
  public
   BackGround : TTexData;
   gp, lgp : TGameProps;

   places: array of TPlayer;
   teams: array [0..TEAM_RED] of TTeamStat;

   session_number: word;//номер игры - сколько раз делали рестарт :)
   warmup, not_warmup_game, no_bot_remove: boolean;

   property Timelimit: word read gp.timelimit write gp.timelimit;
   property Fraglimit: word read gp.fraglimit write gp.fraglimit;
   property sv_gravity: smallint read gp.sv_gravity write gp.sv_gravity;
  public
   Camera : TCamera;
   bg_pos : TPoint2f;

   stopped, paused: boolean;
   leader, exleader: TPlayer;
   DefBrkTex: TBricksTexEntry;
   scen_0: TTFKScenario;

   fade_alpha : single; //0..1.0
   fade_out: boolean;

   flag_update: boolean;

   constructor Create;
   destructor Destroy; override;
   procedure ClearAll;
   procedure CheckDemo;

   property demorec: boolean read Getdemorec;
   property demoplay: boolean read Getdemoplay;

   procedure AfterLoad; override;
   procedure BeforeLoad; override;
   procedure Restart;
   procedure Ready;
   procedure ResetGame;

   procedure Update;
   procedure Draw;                           // Полная отрисовка
   procedure SubDraw;                        // Рисуем без использования камеры
   procedure Draw_BackGround;
   procedure Draw_Bricks(LMap: boolean; front: boolean);     // Брики + LightMap
   procedure Draw_Players;                   // Игроки
   procedure Draw_Objects(Plane: TPlane); // Объекты
   //игровые процедуры
   procedure StopGame;
   procedure UpdateMatch;                    // проверка на конец игры и.т.п.
   function Playing: boolean;

   procedure ActivateObjects;
   function ActivateTarget(Target: WORD; net_: boolean = false): boolean;
   function ActivatePoint(x, y: smallint; sender: TObject; damage: integer = 0): boolean;
   procedure ActivateUse(x, y: smallint);

   function Quad(UID: integer): integer;
   procedure ConsoleShowStats;
   procedure UpdateLog;

   function TrixMap: boolean;

   procedure BrkTexEnable(ID: word; mask: byte);

   function SetPlayerModel(UID: integer; modelname: str32; isnet: boolean = true): boolean;
   function SetPlayerName(UID: integer; name: str32; isnet: boolean = true): boolean;
   procedure Say(UID: integer; saystr: string; isnet: boolean = true);

   function IsLightMap: boolean;
   function IsClientGame: boolean;

   function NewScenario: boolean;
   function StopScenario: boolean;
   function PlayScenario(target: integer): boolean;
   procedure ScenarioSay(UID: integer; saystr: string);
   procedure ScenarioList;

   procedure TeamJoin(uid, team: byte; net_:boolean=false);
   function TeamAuto: byte;override;
   procedure TeamCheck;

   procedure phys_Update;

// SAVEGAME

   procedure SaveGame(filename: string);
   function LoadGame(filename, mapfile: string): integer;
   function LoadGameFileName(filename: string): string;
 end;

var
 Map : TMap;

 //для лога
 lastdx, lastdy: single;

 // Глобальная позиция ущей :)
 sndPos    : TPoint2f;
 // Звук при чате...
 TalkSound    : TSound;
 // переключения оружия
 SwitchSound  : TSound;
 StartSound   : TSound;
 StopSound    : TSound;
 //Звук Респауна ;)
 RespawnSound : TSound;
 WarmupSound : TSound;
 Warmup1Sound : TSound;
 Warmup2Sound : TSound;
 Warmup3Sound : TSound;

 // вернёт буфер с данными карты
 function Map_GetBuffer(const FileName: string; var Size: integer): pointer;
 function Map_IsEqMaps(const FileName1, FileName2: string): boolean;

implementation

uses
 TFK, Menu_Lib, Bot_Lib, Mouse_Lib, MyMenu, Timing_Lib, NET_Server_Lib, NET_Client_Lib;

procedure Map_InitSound;
begin
StartSound   := TSound.Create('sound\game\fight.wav', false, true);
StopSound    := TSound.Create('sound\game\gameend.wav', false, true);
RespawnSound := TSound.Create('sound\respawn.wav', false);
TalkSound    := TSound.Create('sound\game\talk.wav', false, true);
SwitchSound  := TSound.Create('sound\weapons\change.wav', false);
WarmupSound  := TSound.Create('sound\game\warmup.wav', false, true);
Warmup1Sound  := TSound.Create('sound\game\warmup_1.wav', false, true);
Warmup2Sound  := TSound.Create('sound\game\warmup_2.wav', false, true);
Warmup3Sound  := TSound.Create('sound\game\warmup_3.wav', false, true);
end;

/////////////////////////
// TCamera
/////////////////////////
constructor TCamera.Create;
begin
Pos         := Point2f(0, 0);
Target      := nil;
SplitScreen := SPLIT_HORIZ;
end;

procedure TCamera.Update;
begin
   with Map do
      if (Target<>nil) and
         (pl_index(Camera.Target)=-1) then Target:=nil;

if not cam_fixed then
 if dis_view then
  case SplitScreen of
   SPLIT_NONE  : View := Point2f(trunc(xglWidth div 2), trunc(xglHeight div 2));
   SPLIT_VERT  : View := Point2f(trunc(xglWidth div 4), trunc(xglHeight div 2));
   SPLIT_HORIZ : View := Point2f(trunc(xglWidth div 2), trunc(xglHeight div 4));
  end
 else
  case SplitScreen of
   SPLIT_NONE  : View := Point2f(320, 240);
   SPLIT_VERT  : View := Point2f(160, 240);
   SPLIT_HORIZ : View := Point2f(320, 120);
  end
else
 if dis_view then
  View := Point2f(trunc(xglWidth div 2), trunc(xglHeight div 2))
 else
  View := Point2f(320, 240);

if cam_fixed then
 Pos := Point2f(Map.Width * 16, Map.Height * 8)
else
 if Target <> nil then
  if (cam_smooth = 0) or (splitscreen <> SPLIT_NONE) then
   Pos := Target.Pos
  else
   begin
   Pos.X := Pos.X + (Target.Pos.X - Pos.X)/cam_smooth;
   Pos.Y := Pos.Y + (Target.Pos.Y - Pos.Y)/cam_smooth;
   end
 else
  begin
  if input_KeyDown(VK_LEFT)  then Pos.X := Pos.X - cam_speed;
  if input_KeyDown(VK_RIGHT) then Pos.X := Pos.X + cam_speed;
  if input_KeyDown(VK_UP)    then Pos.Y := Pos.Y - cam_speed;
  if input_KeyDown(VK_DOWN)  then Pos.Y := Pos.Y + cam_speed;
  end;
// Здесь эффект Допплера только всё только испортит :)
//  if Target.playertype = C_PLAYER_p1 then
//   with Target.pstruct.dpos do
//    snd_SetGlobalVelocity(Point3f(X * 10, Y * 10, 0));

// Чтобы камера двигалась синхронно с фоном :)
// Из-за дробных чисел ты мог замечать сдвиг фона относительно
// бриков и объектов на карте
// теперь дёргается только игрок =)))
// но я и это исправил, смотри Model.Draw

// XProger: Да и этого не будет...
//Pos.X  := trunc(Pos.X);
//Pos.Y  := trunc(Pos.Y);

// XProger:
// Есть позиция камеры.
// Pos.X - View.X - left
// Pos.X + View.X - right
// Pos.Y - View.Y - top
// Pos.Y + View.Y - bottom
// По этому "ректу" определяется видимость объекта
// Нужно ли его отрисовывать...
end;

function TCamera.NextPlayer: boolean;
var
 i : integer;
begin
Result := false;
if Map.pl_find(-1, C_PLAYER_LOCAL) then Exit;
Result := true;

if Map.Players = 0 then
 begin
 Result := false;
 Target := nil;
 Exit;
 end
else
 if Target = nil then
  begin
  Target := Map.Player[0];
  Exit;
  end;

for i := 0 to Map.Players - 1 do
 if Target = Map.player[i] then
  begin
  if i < Map.Players - 1 then
   Target := Map.player[i + 1]
  else
   Target := nil;
  Exit;
  end;
end;

function TCamera.PrevPlayer: boolean;
var
 i : integer;
begin
Result := false;
if Map.pl_find(-1, C_PLAYER_LOCAL) then Exit;
Result := true;

if Map.Players = 0 then
 begin
 Result := false;
 Target := nil;
 Exit;
 end
else
 if Target = nil then
  begin
  Target := Map.player[Map.Players - 1];
  Exit;
  end;

for i := Map.Players - 1 downto 0 do
 if Target = Map.player[i] then
  begin
  if i > 0 then
   Target := Map.Player[i - 1]
  else
   Target := nil;
  Exit;
  end;
end;


/////////////////////////
// TMap
/////////////////////////
function Map_GetBuffer(const FileName: string; var Size: integer): pointer;
var 
 Map : TCustomMap; 
 i   : integer; 
 mh  : TMapHeader1; 
 eh  : TEntryHead; 
begin 
// Данная функция создаёт буфер содержимого карты 
// без динамической секции LightMap 
// Предположительное назначение: передача карты по сети 
Result := nil; 
Size   := 0; 
Map := TCustomMap.Create; 
with Map do 
 begin 
 if LoadFromFile(FileName) < 0 then 
  Exit; //Вах, нэ павэзло, да? 
 // Подсчёт размера буфера 
 inc(Size, SizeOf(head)); 
  mh := head; 
  for i := 0 to EntriesCount - 1 do 
  with Entries[i] do 
   if Head.EntryClass <> 'LightMapV1' then 
    inc(Size, SizeOf(Head) + Head.size)
   else mh.ECount:=mh.ECount-1; 
 // Создание буфера 
 GetMem(Result, Size); 
 Move(mh, Result^, SizeOf(mh)); 
 inc(integer(Result), SizeOf(mh)); 
 for i := 0 to EntriesCount - 1 do
  with Entries[i] do 
   if Head.EntryClass <> 'LightMapV1' then 
    begin 
    eh := Head; 
    Move(eh, Result^, SizeOf(eh));
    inc(integer(Result), SizeOf(eh)); 
    Move(TSimpleEntry(entries[i]).buf[0], Result^, eh.size); 
    inc(integer(Result), eh.size); 
    end; 
 dec(integer(Result), Size); 
 Free; 
 end; 
end;

function Map_IsEqMaps(const FileName1, FileName2: string): boolean;
var
 buf1, buf2   : pointer;
 size1, size2 : integer;
begin
Result := false;
buf1 := Map_GetBuffer(FileName1, size1);
buf2 := Map_GetBuffer(FileName2, size2);
if (buf1 = nil) or (buf2 = nil) then
 Result := Utils_CRC32(4096, buf1, size1) = Utils_CRC32(4096, buf2, size2);
end;


procedure TMap.ClearAll;
begin
CheckDemo;

Clear;
ObjTex_BeginLoad;
ObjTex_EndLoad;

pl_clear;
botdll_Off;
NET_Create(false);
CallMainMenu;
end;

constructor TMap.Create;
begin
inherited Create;
Camera  := TCamera.Create;

BackGround.Scale  := true;
BackGround.Filter := true;
BackGround.Trans  := false;

xglTex_Load(PChar('textures\background\' + bg), @BackGround);
DefbrkTex := TBricksTexEntry.Create;
DefbrkTex.LoadFromFile('textures\box.bmp');
Map_InitSound;
end;

destructor TMap.Destroy;
begin
ClearAll;
Mouse_Dispose;
xglTex_Free(@BackGround);
inherited;
end;

procedure TMap.Update;
var
 i : integer;
begin
paused := console.Show and not net_game and not stopped;
if started and (stopped or paused) then
 Exit;

if not fade_out then
begin
   fade_alpha:=fade_alpha-r_fade_speed/1000;
   if fade_alpha<0.0 then fade_alpha:=0.0;
end else
begin
   fade_alpha:=fade_alpha+r_fade_speed/1000;
   if fade_alpha>1.0 then fade_alpha:=1.0;
end;


//АПДЕЙТИМ КЛАВИШИ ИГРОКОВ!
if not demoplay then
 begin
Timing_Start('NFK Bot update');
 for i := low(player) to high(player) do
 	if @DLL_SYSTEM_UpdatePlayer <> nil then
      DLL_SYSTEM_UpdatePlayer(GetNFKPlayer(i));
Timing_End('NFK Bot update');
 // Обновление для ботов
 botdll_mainloop;
 bot_update;
 end;

//XProger: АХТУНГ!!!
// Я точно не знаю как это повлияет на сетевую игру :)
// И вобще, нужно часть обновления первого игрока снести нафиг
// если мы в меню игровом сидим...


if not inMenu then
 pl_update_input;
//физическое перемещение игроков
pl_update_physic;

//Обновление... ДЕМКИ И СЦЕНАРИЕВ ;)
Timing_Start('Demo update');
Demo.Update;
for i := 0 to EntriesCount - 1 do
 if Entries[i] is TTFKScenario then
  with TTFKScenario(Entries[i]) do
   Update;
Timing_End('Demo update');

if started then
 NET.Update_Next;
started := true;

if scen_0 <> nil then
 scen_0.Update;

UpdateMatch;

NET.game_Prepare;

pl_update_kill;
if not flag_update then
   pl_update_respawn;
flag_update:=false;

//ОТСЫЛАЕМ ПОЛОЖЕНИЯ/КЛАВИШИ ИГРОКОВ :)

WEAPONUPDATE;
for i := 0 to Obj.count-1 do
 if Obj[i].fOwner = nil then
  Obj[i].Update;

for i := 0 to Obj.count-1 do
 if Obj[i].fOwner<>nil then
  Obj[i].Update;
Optimize_update;

pl_update;
phys_update;

ActivateObjects;


RealObj_Update;
NET.game_send;
Particle_Update;

for i := 0 to Lights.Count - 1 do
 Lights[i].Update;

if WP <> nil then
 for i := 0 to WP.Count - 1 do
  with WP.WP[i] do
   blocked := block_s(X, Y);

Camera.Update;
{$IFDEF DEBUG_LOG}
UpdateLog;
{$ENDIF}
bg_pos.X := bg_pos.X + r_bg_speed_x/10;
bg_pos.Y := bg_pos.Y + r_bg_speed_y/10;

end;

procedure TMap.UpdateMatch;
var
 i : integer;

 function ComparePlayers(first, second: TPlayer): integer; //первый круче второго
 begin
    if first.team<second.team then Result:= 1
    else if first.team>second.team then Result:= -1
    else
   if first.Stat.Frags < second.Stat.Frags then
      Result := -1
   else
   if first.Stat.Frags = second.Stat.Frags then
      Result := 0
   else
      Result := 1;
 end;

 procedure QSort(l, h: integer);
 var
    i, j: integer;
    x, t: TPlayer;
 begin
    if l>=h then Exit;
    i:=l;j:=h;x:=places[(l+h) div 2];
    while (i<=j) do
       if ComparePlayers(places[i], x)=1 then Inc(i)
       else if ComparePlayers(places[j], x)=-1 then Dec(j)
       else
       begin
          t:=places[i];places[i]:=places[j];places[j]:=t;
          Inc(i);Dec(j);
       end;
    if l<j then QSort(l, j);
    if i<h then QSort(i, h);
 end;

begin
  SetLength(places, pl_count);
  teams[TEAM_BLUE].plcount:=0;
  teams[TEAM_BLUE].frags:=0;
  teams[TEAM_BLUE].deaths:=0;
  teams[TEAM_RED].plcount:=0;
  teams[TEAM_RED].frags:=0;
  teams[TEAM_RED].deaths:=0;
  for i:=0 to pl_count-1 do
  begin
     places[i]:=player[i];
     if player[i].team>0 then
     begin
        Inc(teams[player[i].team].plcount);
        Inc(teams[player[i].team].frags, player[i].stat.Frags);
        Inc(teams[player[i].team].deaths, player[i].stat.deaths);
     end;
  end;
  QSort(0, pl_count-1);

if not IsClientGame then
 begin

    if not warmup then
    begin

      timelimit := Constants_Lib.timelimit;
      fraglimit := Constants_Lib.fraglimit;

      if ((timelimit > 0) and
         (HUD_GetTime >= timelimit*50*60)) or
         ((fraglimit > 0) and
         (places<>nil) and
         ( (places[0].Stat^.frags>=fraglimit) or
         (teams[TEAM_RED].frags>=fraglimit) or
         (teams[TEAM_BLUE].frags>=fraglimit)
      )) then
         StopGame;
    end else
       if HUD_GetTime=0 then
       begin
          Ready;
          Exit;
       end;
 end;


if (gametype = GT_SINGLE) then
begin
   if pl_find(-1, C_PLAYER_LOCAL) then
   begin
      if (HUD_GetTime>50) and
         pl_current.dead and
         (pl_current.deadticker=49) then
        StopGame;
   end;
end;

if warmup then
 with Camera.Pos do
  begin
  if HUD_GetTime = 150 then Warmup3Sound.Play(X, Y);
  if HUD_GetTime = 100 then Warmup2Sound.Play(X, Y);
  if HUD_GetTime = 50  then Warmup1Sound.Play(X, Y);
  end;
end;

procedure TMap.StopGame;
var
 i : integer;
begin
stopped := true;
Stat_Fix;
for i := low(Player) to high(Player) do
 Player[i].Reset;
snd_StopAll(0);
Demo.Stop;
StopSound.Play(Camera.Pos.X, Camera.Pos.Y);
if NET.Type_=NT_SERVER then
   net_server.game_stop;
end;

function TMap.Playing: boolean;
begin
Result := not stopped and not paused;
end;

procedure TMap.Draw;
begin
glPushMatrix; //запоминаем текущее состояние
// Трансформируем матрицу вида
with Camera do
   glTranslatef(trunc(-Pos.X + View.X), trunc(-Pos.Y + View.Y), 0);
SubDraw;
glPopMatrix; //возвращаем состояние матрицы на прежнее
botdll_Draw;

//прорисовка fade in / out
if fade_alpha > 0 then
 begin
 xglTex_Disable;
 xglAlphaBlend(1);
 glColor4f(0, 0, 0, fade_alpha);
 with Camera do
  begin
  glBegin(GL_QUADS);
   glVertex2f(0, 0);
   glVertex2f(2*View.X, 0);
   glVertex2f(2*View.X, 2*View.Y);
   glVertex2f(0,  2*View.Y);
  glEnd;
  end;
 end;
end;

procedure TMap.SubDraw;
var
   i, j: integer;
begin
   if r_bg_draw then
      Draw_Background;

// Задний план
Draw_Objects(pBack);
RealObj_Draw(pBack);
Particle_Draw(pBack);

Draw_Bricks(false, false);

// Средний план
Draw_Objects(pNone);
RealObj_Draw(pNone);
Particle_Draw(pNone);

Draw_Players;

//Front Bricks
Draw_Bricks(false, true);

// LightMap
Draw_Objects(pFront);
{ // XProger: тут были тщетные попытки прогера сделать
  // действительно освещающие спрайты света
  // отказался т.к. 50 фпс да и глючит не по децки
  // буду искать другой метод :)
}
Draw_Bricks(true, false);
Particle_Draw(pFront);
RealObj_Draw(pFront);

// Блики света от лампочек
for i := 0 to Map.Lights.Count - 1 do
 Map.Lights[i].Draw;

xglTex_Disable;
glEnable(GL_BLEND);
glColor4f(1, 1, 1, 1);
xglAlphaBlend(1);


// Рисуем прицелы
for i := Low(Player) to High(Player) do
 Player[i].DrawCrosshair;

if d_waypoints and (WP <> nil) then
 with WP do
  begin
  glPointSize(8);
  glEnable(GL_POINT_SMOOTH);
  glEnable(GL_LINE_SMOOTH);

  xglAlphaBlend(1);
  xglTex_Disable;

  glColor3f(0.5, 0.5, 0.5);
  glBegin(GL_LINES);
  for i := 0 to Count - 1 do
   for j := 0 to WP[i].Count - 1 do
    with WP[i].Link[j] do
     begin
     glVertex2f(WP[i].X, WP[i].Y);
     glVertex2f(WP[idx].X, WP[idx].Y);
     end;
  glEnd;
  glDisable(GL_LINE_SMOOTH);

  glColor3f(1, 1, 1);
  glBegin(GL_POINTS);
  for i := 0 to Count - 1 do
   glVertex2f(WP[i].X, WP[i].Y);
  glEnd;

 if WayLen > 0 then
   with self.WP do
    begin
    glColor3f(0, 0, 1);
    glBegin(GL_POINTS);
    for i := 0 to WayLen - 1 do
     glVertex2f(WP[Way[i]].X, WP[Way[i]].Y);
    glEnd;
    end;
  glDisable(GL_POINT_SMOOTH);
  end;
end;

procedure TMap.Draw_Bricks(LMap: boolean; front: boolean);
var
 minX, minY : integer;
 maxX, maxY : integer;

 procedure DrawBricks;
 var
  lx, ly, rx, ry : integer;

  procedure DrawBrick;
  begin
  //рисуем прямоугольник
  glTexCoord2f(0,  1); glVertex2f(lx, ly);
  glTexCoord2f(1,  1); glVertex2f(rx, ly);
  glTexCoord2f(1,  0); glVertex2f(rx, ry);
  glTexCoord2f(0,  0); glVertex2f(lx, ry);
  end;

 var
  x, y : integer;
  ID : word; mask: byte;
 begin
 glColor4f(1, 1, 1, 1);

 if not LMap then
  begin
  xglBegin(GL_QUADS); //Начать отрисовку четырёхугольныков :)

  for y := minY to maxY do
   begin
   //вычисление координаты Y полигона
   ly := y*16;
   ry := ly + 16;
   for x := minX to maxX do
    begin
    ID   := Brk[x, y];
    mask := Brk.Mask[x, y];
    if (ID > 0) and (mask and MASK_CONTAINER = 0) then
     begin
     //вычисление координаты X полигона
     lx := x*32;
     rx := lx + 32;
     //рисуем
     if (Brk.Mask[x, y] and MASK_FRONT > 0)= front then
      begin
      BrkTexEnable(ID, mask);
      DrawBrick;
      end;
     end;
    end;
   end;
  xglEnd;
  end
 else
  if IsLightmap then
   begin
   xglAlphaBlend(3);
   xglBegin(GL_QUADS);
   for y := minY to maxY do
    begin
    ly := y*16;
    ry := ly + 16;
    for x := minX to maxX do
     begin
     lx := x*32;
     rx := lx + 32;
     //xglTex_Enable(DefBrkTex[Brk[x, y]]);
     xglTex_Enable(LightMap.lMapTex[x, y]);
     DrawBrick;
     end;
    end;
   xglEnd;
   xglAlphaBlend(1);
   end;

 xglTex_Disable;
 end;

var
 T, B, L, R : integer;
begin
with Camera do
 if dis_view then
  begin
  minX := trunc(Pos.X) div 32 - (xglWidth  + 63) div 64;
  minY := trunc(Pos.Y) div 16 - (xglHeight + 31) div 32;
  maxX := trunc(Pos.X) div 32 + (xglWidth  + 63) div 64;
  maxY := trunc(Pos.Y) div 16 + (xglHeight + 31) div 32;
  end
 else
  begin
  minX := trunc(Pos.X - View.X) div 32;
  minY := trunc(Pos.Y - View.Y) div 16;
  maxX := trunc(Pos.X + View.X) div 32;
  maxY := trunc(Pos.Y + View.Y) div 16;
  end;

L := minX - 1;
R := maxX + 1;
T := minY - 1;
B := maxY + 1;
if minX < 0 then minX := 0;
if minY < 0 then minY := 0;
if maxX > Width - 1 then maxX := Width - 1;
if maxY > Height - 1 then maxY := Height - 1;
//Рисуем только видимые брики
DrawBricks;

// Закраска фона - не относящегося к карте
if IsLightMap and LMap then
 begin
 xglTex_Disable;
 xglAlphaBlend(3);
 glColor3ubv(@Fhead.EnvColor);
 glBegin(GL_QUADS);
 if L <= 0 then // слева
  begin
  glVertex2f(L*32,    T*16);
  glVertex2f(minX*32, T*16);
  glVertex2f(minX*32, B*16);
  glVertex2f(L*32,    B*16);
  end;

 if T <= 0 then // сверху
  begin
  glVertex2f(minX*32,    T*16);
  glVertex2f(maxX*32+32, T*16);
  glVertex2f(maxX*32+32, minY*16);
  glVertex2f(minX*32,    minY*16);
  end;

 if R > maxX + 1 then // справа
  begin
  glVertex2f(R*32,       T*16);
  glVertex2f(maxX*32+32, T*16);
  glVertex2f(maxX*32+32, B*16);
  glVertex2f(R*32,       B*16);
  end;

 if B > maxY + 1 then // сверху
  begin
  glVertex2f(minX*32,    B*16);
  glVertex2f(maxX*32+32, B*16);
  glVertex2f(maxX*32+32, maxY*16+16);
  glVertex2f(minX*32,    maxY*16+16);
  end;
 glEnd;
 xglAlphaBlend(1);
 end;
end;

procedure TMap.Draw_Players;
var
 i : integer;
begin
// Рисуем всех игроков
for i := Low(Player) to High(Player) do
 Player[i].Draw;
end;

procedure TMap.Draw_Objects(Plane: TPlane);
var
 i        : integer;
 ViewRect : TRect;
begin
// Рисуем объекты
// При отрисовке объекта необходимо проверять его положение
// (ближний или дальний)
// Также проверяется попадание его в Rect камеры :)

with Camera do
 ViewRect := Rect(trunc(Pos.X - View.X), trunc(Pos.Y - View.Y),
                  trunc(View.X * 2), trunc(View.Y * 2));

for i := 0 to Obj.Count-1 do
 if Obj[i].Plane = Plane then
  if RectIntersect(RectToMath(Obj[i].ObjRect), RectToMath(ViewRect)) then
   try
    Obj[i].Draw;
   except
    Log('Error: while draw ' + Obj[i].ClassName + ' + [' + IntToStr(i) + ']');
   end;
end;

procedure TMap.AfterLoad;
begin
inherited;

block_BrkOptimize;

cam_fixed := (Width <= xglWidth div 32) and (Height <= xglHeight div 16);

if Demo = nil then
 begin
 Demo := TTFKDemo.Create;
 SetEntriesSize(EntriesCount + 1);
 Entries[EntriesCount - 1] := Demo;
 GameCMDOn;
 botdll_On;
 end
else
 begin
 GameCMDOff;
 botdll_Off;
 Demo.playing := true;
 end;
// Смена карты
BotDLL_ChangeMap;

if brkTex = nil then
 brkTex := DefBrkTex;

if Lights = nil then
 begin
 Lights := TLightsEntry.Create;
 SetEntriesSize(EntriesCount + 1);
 Entries[EntriesCount - 1] := Lights;
 end
else
 if r_lightmap and (Lights.Count > 0) and (LightMap = nil) and
  	(r_lightmap_demo or not demoplay) then
  begin
 	LightMap := TLightMapEntry.Create;
   SetEntriesSize(EntriesCount + 1);
   Entries[EntriesCount-1] := LightMap;
  end;

if (LightMap <> nil) and LightMap.needgenerate and (not DemoPlay or r_lightmap_demo) then
	LightMap.Generate;
Restart;

ObjTex_EndLoad;
snd_EndUpdate;
Engine_FlushTimer;
bg_pos.X := 0;
bg_pos.Y := 0;

if demo.playing then
   if pl_count>0 then
      Camera.Target:=Player[0];
end;

procedure TMap.Restart;
var
 i : integer;
begin
//убираем затемнение
if Demo.playing then
   fade_out:=false
else fade_out:=head.fade_mode;
if fade_out then fade_alpha:=1.0 else fade_alpha:=0.0;

snd_StopAll(0);
scen_0  := nil;
started := false;
HIT_Restart;
HUD_Restart;
if gametype in [GT_TRIX, GT_SINGLE] then
   phys_itemmode:=0
   else phys_itemmode:=1;


//считаем warmup или нафиг его
warmup:=not not_warmup_game and
   (gametype in [GT_FFA, GT_TDM, GT_CTF, GT_RAIL, GT_CTC]) and
   ((warmup_mode=1) or (NET.Type_=NT_CLIENT)) and not
      demo.playing;
if warmup then
   HUD_SetTime(warmup_time*50);

//Уничтожение real-объектов
ResetGame;
//обнуление статистики
Stat_Reset;
//обнуление сценариев, если они есть
for i := 0 to EntriesCount - 1 do
 if Entries[i] is TTFKScenario then
  with TTFKScenario(Entries[i]) do
   Restart;

if (NET.Type_=NT_CLIENT) then
 pl_clear;

if (NET.TYPE_=NT_CLIENT) or (gametype in [GT_TRIX, GT_SINGLE] ) then
   pl_clear;

if not IsClientGame then
 begin
	pl_deleteall_ptype(C_PLAYER_DEMO);

   if not not_warmup_game then
   begin
	   pl_add(C_PLAYER_p1, p1name, p1model, true);
	   if p2Disable or trixmap or (gametype=GT_SINGLE) then
		   pl_deleteall_ptype(C_PLAYER_p2)
      else
	      pl_add(C_PLAYER_p2, p2name, p2model, true);
      TeamCheck;
   end;

	teamnextresp[0] := random(respcount);
	teamnextresp[1] := random(respcount);
	teamnextresp[2] := random(respcount);
	for i := Low(Player) to High(Player) do
	begin
		Player[i].Stat := Stat_Get(Player[i].UID, true);
		pl_respawn(player[i]);
	end;
 end;
for i := Low(Player) to High(Player) do
   Player[i].Stat := Stat_Get(Player[i].UID, true);

CmdCheck;

stopped := false;
paused  := false;
// Рестарт для бота
botdll_ResetGame;

//exec map config
Log_Conwrite(false);
phys_default;
phys_lock;


Console_CMD('exec '+spgame_folder+'cfgs\default.cfg');
if FileExists(Engine_ModDir+spgame_folder+ 'cfgs\' + GetFileName + '.cfg') then
 Console_CMD('exec '+spgame_folder+'cfgs\' + GetFileName + '.cfg');
phys_unlock;
Log_Conwrite(true);

//Обнуление объектов
Obj.RestartObjects;

if not_warmup_game then
   Demo.RecReady
else
   Demo.Restart;
not_warmup_game:=false;

if Player<>nil then
	for i := Low(Player) to High(Player) do
 		Player[i].LoadFromFile(Player[i].pstruct.ModelName);

try
   flag_update:=true;
   Update;
except
   Log('^1First Update error!');
end;
flag_update:=false;

//Camera наводится на игрока...
i:=cam_smooth;
cam_smooth:=0;
Camera.Update;
cam_smooth:=i;

if warmup then
 WarmupSound.Play(Camera.Pos.X, Camera.Pos.Y)
else
 StartSound.Play(Camera.Pos.X, Camera.Pos.Y);
CallGameMenuOff;

Inc(session_number);
if NET.Type_=NT_SERVER then
   NET_Server.changemap_send;
end;

procedure TMap.Ready;
begin
   if NET.Type_<>NT_CLIENT then
   begin
      not_warmup_game:=true;
      no_bot_remove:=true;
      Restart;
   end;
end;

procedure TMap.BeforeLoad;
var
   i: integer;
begin
inherited;

if fhead.gametype=0 then
   fhead.gametype:=defhead.gametype;

if (fhead.gametype and gametype=0) and
   (fhead.gametype>0) then
   for i:=0 to 7 do
      if (fhead.gametype shr i) and 1>0 then
      begin
         gametype:=1 shl i;
         gametype_c:=gametype;
         break;
      end;
RealObj_Free;
ResetGame;
snd_StopAll(0);
ClearItems;
ObjTex_BeginLoad;
snd_BeginUpdate;
 Menu_InitSound;
 Weapon_InitSound;
 Map_InitSound;
WeaponDispose;
WeaponCreate;
end;

procedure TMap.ResetGame;
var
 i : integer;
begin
Stat_Reset;
for i := Low(Player) to High(Player) do
 begin
 Player[i].dead := true;
 Player[i].Reset;
 end;
Particle_Clear;
RealObj_Clear;
end;

procedure TMap.ActivateObjects;
var
 i, j : integer;
 bool : boolean;
begin
for i := 0 to Obj.Count - 1 do
 if (Obj[i] <> nil) and (Obj[i].ActivateRect.Width>0) and (Obj[i].ActivateRect.Height>0) and
    (Obj[i].struct.active and 3<3)  then
  for j := 0 to Players - 1 do
   if (Player[j] <> nil) and not Player[j].dead then
    with Player[j].Pos, Player[j] do
     begin
     if Obj[i].ActivateMode then // должен быть полностью в ректе
      bool := RectInside(RectToMath(fRect), RectToMath(Obj[i].ActivateRect))
     else // хотя бы чуть-чуть в ректе =)))
      bool := RectIntersect(RectToMath(fRect), RectToMath(Obj[i].ActivateRect));
     // активация!
     if bool then
      if not (Obj[i].ObjType in NETobjs) then
       Obj[i].Activate(Player[j])
      else
       if not IsClientGame and Obj[i].Activate(Player[j]) then
        begin
        if NET.TYPE_ = NT_SERVER then
         NET_Server.ObjActivate(i, player[j].UID);
        Demo.RecActivate(i, player[j].UID);
        end;
     end;
end;

function TMap.ActivateTarget(Target: WORD; net_: boolean): boolean;
var
 i, j, k : integer;
 elev : TElevatorObj;
begin
Result := false;
if target=0 then Exit;//НУЛЕВОЙ ТАРГЕТ БОЛЬШЕ НЕ СУЩЕСТВУЕТ!!!Нафиг это надо
if IsClientGame and not net_ then
 Exit;
if (target = 9999) and not IsClientGame then
begin
   i:=random(t_count);
   j:=0;
   for k:=1 to 9999 do
      if t_triggers[k] then
   begin
      if j=i then
      begin
         ActivateTarget(k, net_);
         break;
      end;
      Inc(j);
   end;
end;
if NET.Type_ = NT_SERVER then
 net_server.objactivate(20000 + target, 0);
Demo.RecActivate(20000 + target, 0);
Result := false;
if target = NULLTARGET then
 Exit
else
 if (target >= 10100) and (target <= 10200) and not demoplay then
  PlayScenario(target);

j := Obj.Count - 1;
for i := 0 to j do
 if Obj[i] <> nil then
 begin
  if (Obj[i].target_name = Target) and
      (odd(Obj[i].Struct.active) or
       (Obj[i].struct.active=2) and (Obj[i].ObjType=otMonster)
      ) and
      Obj[i].Activate(nil) then
     Result := true;

  if Obj[i] is TElevatorObj then
   begin
   Elev := TElevatorObj(Obj[i]);
   if target = Elev.Struct.etargetname1 then
    Elev.OnTarget1(nil);
   if target = Elev.Struct.etargetname2 then
    Elev.OnTarget2(nil);
   end;
  end;
end;

function TMap.ActivatePoint(x, y : SmallInt; sender: TObject; damage: integer = 0): boolean;
var
 i, j : integer;
begin
Result := false;
if not IsClientGame then
begin

j := Obj.Count - 1; // XProger: иначе бы каждый такт цыкла дельфя вызывала эту функцию
for i := 0 to j do
 if Obj[i] <> nil then
  if (Obj[i].Struct.active and 3 = 2) and
      PointInRect(x, y, Obj[i].ObjRect) then
         begin
            if Obj[i].ObjType = otDestroyer then
            begin
               if TDestroyerObj(Obj[i]).Hit(damage) then
               begin
                  if NET.Type_=NT_SERVER then
                     NET_Server.ObjActivate(i, 32);
                  demo.RecActivate(i, 32);
               end;
               Result:=true;
            end else
            if Obj[i].ObjType = otMonster then
                  Result:=TMonsterObj(Obj[i]).Hit(damage)
               else if Obj[i].Activate(sender) then
               begin
                  if NET.Type_=NT_SERVER then
                     NET_Server.ObjActivate(i, 32);
                  demo.RecActivate(i, 32);
                  Result:=true;
               end;
         end;

end;

end;

//пару процедур для респауна
function TMap.Quad(UID: integer): integer;
begin
//определяет коэфициент усиления
Result := 1;
if pl_find(UID, C_PLAYER_ALL) then
 Result := pl_current.Quad;
end;

procedure TMap.ConsoleShowStats;
var
 i, j: integer;
begin
for i := 0 to Players - 1 do
 with player[i] do
  begin
  if stat = nil then
   begin
   Log('Statistic error');
   Continue;
   end;

  Log('statistic for player №'+IntToStr(i+1));
  Log('frags = '+inttostr(stat.Frags)+' deaths = '+inttostr(stat.Deaths)+' suicides = '+IntToStr(stat.Suicides));
  Log('dmgGiven = '+inttostr(stat.dmgGiven)+' dmgTaken = '+inttostr(stat.dmgTaken));
  Log('humiliation = '+inttostr(stat.humiliation)+' impressive = '+inttostr(stat.impressive)+' excellent = '+IntToStr(stat.excellent));
  Log('***WEAPONS***');
  for j := 1 to WPN_Count - 1 do
   if WeaponExists(j) then
    if stat.shots[j] > 0 then
     Log('#'+inttostr(j)+' '+IntToStr(stat.hits[j])+'/'+IntToStr(stat.shots[j]));
   end;
end;

function TMap.Getdemoplay: boolean;
begin
Result := Demo.playing;
end;

function TMap.Getdemorec: boolean;
begin
Result := Demo.recording;
end;

procedure TMap.UpdateLog;
begin
with Player[0] do
 begin
 if signf(dpos.Y) <> 0 then
  lastdx := (lastdy+0.056)/dpos.Y
 else
  lastdx := 1;
 Log(FloatToStrF(pos.x, ffGeneral, 5, 3)+' '+
     FloatToStrF(pos.y, ffGeneral, 5, 3)+' '+
     FloatToStrF(dpos.x, ffGeneral, 5, 3)+' '+
   	 FloatToStrF(dpos.y, ffGeneral, 5, 3)+' '+
     FloatToStrF(dpos.y-lastdy, ffGeneral, 5, 3)+' '+
     FloatToStrF(lastdx, ffGeneral, 5, 3));
 lastdy := dpos.y;
 end;
end;


function TMap.TrixMap: boolean;
var
 i, j : integer;
begin
Result := false;
j := Obj.Count - 1;
for i := 0 to j do
 if Obj[i].ObjType = otArenaEnd then
  begin
  Result := true;
  break;
  end;
end;

procedure TMap.BrkTexEnable(ID: word; mask: byte);
var
 back, front: boolean;
begin
if def_brick = 0 then
 if ID < BrkTex.TexCount then
  xglTex_Enable(BrkTex[ID])
 else
  xglTex_Enable(DefBrkTex[ID])
else
   if def_brick<BrkTex.TexCount then
 		xglTex_Enable(DefBrkTex[def_brick])
   else xglTex_Enable(DefBrkTex[0]);

back  := mask and 1 = 0;
front := mask and 2 > 0;
if back then
 if front then
 	glColor4f(1, 1, 1, r_frontbr_alpha/255)
 else
  glColor4f(1, 1, 1, r_backbr_alpha/255)
else
 glColor4f(1, 1, 1, 1);
end;

function TMap.SetPlayerModel(UID: integer; modelname: str32;  isnet: boolean = true): boolean;
begin
Result := false;
if pl_find(UID, C_PLAYER_ALL) and not (pl_current.modelname=modelname) then
 begin

 	Result := pl_current.LoadFromFile(ModelName);
 	Log_ChangeModel(pl_current);
 	demo.RecModel(UID, pl_current.ModelName);
	if isnet then
      NET.changename_Send(uid, pl_current.Name, pl_current.ModelName);
 end;
end;

procedure TMap.Say(UID: integer; saystr: string; isnet: boolean = true);
var
   p: TPlayer;
   pname: string;
begin
	if isnet then
      NET.say_Send(uid, saystr);

   p := PlayerByUID(uid);
   if p = nil then
    pname := 'dedicated'
   else
    pname := p.Name;
   Log(pname + '^7: ^5' + saystr);
   Demo.RecSay(uid, saystr);

   ScenarioSay(UID, saystr);
   TalkSound.Play(sndPos.X, sndPos.Y);
end;

function TMap.SetPlayerName(UID: integer; name: str32;  isnet: boolean = true): boolean;
begin
   Result:=pl_find(UID, C_PLAYER_ALL);
   if not result or (pl_current.name=name) then Exit;
   Log_ChangeName(pl_current.name, name);
   pl_current.Name:=name;
	if isnet then
      NET.changename_Send(uid, pl_current.Name, pl_current.ModelName);
   demo.RecName(uid, name);
end;

function TMap.IsLightMap: boolean;
begin
   Result:=r_lightMap and (LightMap<>nil);
end;

function TMap.IsClientGame: boolean;
begin
   Result:=(NET.Type_=NT_CLIENT) or demoplay;
end;

function TMap.NewScenario: boolean;
begin
   Result:=true;
   scen_0:=TTFKScenario.Create;
   scen_0.RecStart;
end;

function TMap.StopScenario: boolean;
begin
   Result:=scen_0<>nil;
   if scen_0<>nil then
   begin
      scen_0.demofilename:=lastfilename;
   	scen_0.RecStop;
      scen_0:=nil;
   end;
end;

function TMap.PlayScenario(target: integer): boolean;
var
   i: integer;
   t: integer;
begin
   Result:=false;
   t:=10100;
   for i:=0 to EntriesCount-1 do
      if Entries[i] is TTFKScenario then
         with TTFKScenario(Entries[i]) do
            if t=target then
            begin
         		if not playing then
      			begin
   					Result:=true;
            		PlayStart;
            	end;
               Exit;
            end else Inc(t);
end;

procedure TMap.ScenarioSay(UID: integer; saystr: string);
begin
  	if (scen_0<>nil) and (scen_0.recording) then scen_0.RecSay(UID, saystr);
end;

procedure TMap.ScenarioList;
var
   i, t: integer;
begin
   t:=10100;
	for i:=0 to EntriesCount-1 do
   	if Entries[i] is TTFKScenario then
      begin
         Log('^3'+IntToStr(t));
         Inc(t);
      end;
   if t=10100 then Log('^1 There is no scenarios');
end;

function TMap.TeamAuto: byte;
begin
   if gametype and GT_TEAMS>0 then
      if teams[TEAM_BLUE].plcount>teams[TEAM_RED].plcount then
         Result:=TEAM_RED
      else
         Result:=TEAM_BLUE
   else Result:=0;
   Inc(teams[result].plcount);
end;

procedure TMap.TeamJoin(uid, team: byte; net_:boolean);
var
   pl: TPlayer;
begin
 if Map.pl_find(uid, C_PLAYER_ALL) then
 begin
   pl := pl_current;

   if (team<=0) or (team>=3) then
   begin
      dec(teams[pl.team].plcount);
      team:=TeamAuto;
   end;
   if net_ and (NET.Type_=NT_CLIENT) then
   begin
      NET_Client.teamjoin(uid, team);
      Exit;
   end;

   if team<>pl.team then
   begin
      Log_TeamJoin(pl.Name, team);
      pl.team := team;
      if pl.resp then
         pl_respawn(pl);
      if team in [TEAM_RED, TEAM_BLUE] then
         pl.Model.Color := Skins[team].Color;
   end;
   if NET.Type_=NT_SERVER then
      NET_Server.TeamJoin(uid, team);
   demo.RecTeam(uid, team);
 end;
end;

procedure TMap.Draw_BackGround;
var
   cx, cy, mx, my: single;
   s    : single;
begin

glPushMatrix;
glTranslatef(trunc(Camera.Pos.X), trunc(Camera.Pos.Y), 0);

 xglTex_Enable(@BackGround);

 glColor4f(1, 1, 1, 1);
 with Camera do
  begin
  s := 1 - r_bg_motion/100;
  mx := View.X*2/BackGround.Width;
  my := View.Y*2/BackGround.Height;
  cx := s * trunc(Pos.X + bg_pos.X)/BackGround.Width;
  cy := s * trunc(Pos.Y + bg_pos.Y)/BackGround.Height;

  glBegin(GL_QUADS);
   glTexCoord2f(cx, cy-my);    glVertex2f(-View.X, -View.Y);
   glTexCoord2f(cx+mx, cy-my); glVertex2f( View.X, -View.Y);
   glTexCoord2f(cx+mx, cy);    glVertex2f( View.X,  View.Y + 1);
   glTexCoord2f(cx, cy);       glVertex2f(-View.X,  View.Y + 1);
  glEnd;
  end;

glPopMatrix;

end;

procedure TMap.CheckDemo;
begin
if not stopped and (Demo<>nil) and
   Demo.recording then
      Demo.Stop;
end;

procedure TMap.TeamCheck;
var
   i: integer;
begin
   if gametype and GT_TEAMS>0 then
   begin
      for i:=0 to pl_count-1 do
         if player[i].team=0 then
            Teamjoin(player[i].uid, TeamAuto);
   end else
   begin
      for i:=0 to pl_count-1 do
         if player[i].team>0 then
            player[i].team:=0;
   end;
end;

procedure TMap.phys_Update;
var
   i, track: integer;
begin
   //сумасшедшая модерновая процедурка...
   phys_flag:=true;
   for track:=2 to phys_freq do
   begin
      for i:=0 to Obj.g_Count-1 do
         if Obj.g_Obj[i].ObjType in [otElevator, otTrain] then
            Obj.g_Obj[i].Update;
      for i:=0 to pl_count-1 do
         player[i].UpdateMove;
   end;
   phys_flag:=false;
end;

procedure TMap.ActivateUse(x, y: smallint);
var
   i: integer;
begin
   if not IsClientGame then
   begin

   for i:=0 to Obj.Count-1 do
      if (Obj[i].struct.active and 3=3) and
      PointInRect(x, y,
       Rect(Obj[i].ObjRect.X-USE_RADIUS,
            Obj[i].ObjRect.Y-USE_RADIUS,
            Obj[i].Width*32+2*USE_RADIUS,
            Obj[i].Height*16+2*USE_RADIUS)
       ) then
          if Obj[i].Activate(Self) then
          begin
             if NET.Type_=NT_SERVER then
                NET_Server.ObjActivate(i, 32);
             Demo.RecActivate(i, 32);
          end;
   end;
end;

procedure TMap.SaveGame(filename: string);
var
   demo: TSaveGame;
   F: file;
   s: string;
   b: byte;

begin
   s:=Self.GetFileName;
   assign(F, filename);
   rewrite(F, 1);
   b:=length(s);
   BlockWrite(F, b, 1);
   BlockWrite(F, s[1], length(s));

   demo:=TSaveGame.Create;
   demo.SaveAll;
   demo.WriteToFile(F);
   demo.Free;
   CloseFile(F);
end;

function TMap.LoadGame(filename, mapfile: string): integer;
var
   F: file;
   s: string;
   i, b: byte;
   demo: TSaveGame;
   head: TEntryHead;

begin

   Log_ConWrite(false);

try
   assign(F, filename);
   reset(F, 1);
   BlockRead(F, b, 1);
   s:=''; for i:=1 to b do s:=s+' ';
   BlockRead(F, s[1], b);

   if (ENGINE_DIR+lastfilename<>mapfile) and
      (lastfilename<>mapfile) then
      Result:=LoadFromFile(mapfile)
   else
   begin
      Result:=0;
      Restart;
   end;

   NET_Create(false);

   BlockRead(F, head, sizeof(head));
   demo:=TSaveGame.Create(head, F);
   with demo do
   if Result=0 then
      LoadAll;
   Closefile(F);
except
   Result:=-1;
end;
   Log_ConWrite(true);

end;

function TMap.LoadGameFileName(filename: string): string;
var
   F: file;
   s: string;
   i, b: byte;
begin

   assign(F, filename);
   reset(F, 1);
   BlockRead(F, b, 1);
   s:=''; for i:=1 to b do s:=s+' ';
   BlockRead(F, s[1], b);
   Result:=lowercase(s);
   close(F);
end;

end.

