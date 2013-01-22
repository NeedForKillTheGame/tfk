unit Particle_Lib;

(*******************************************)
(*  TFK Particle library version  0.0.3.6  *)
(*******************************************)
(* Created by XProger                      *)
(* mail : XProger@list.ru                  *)
(*******************************************)

// Предназначен для работы с системой частиц
interface

uses
 OpenGL,
 Engine_Reg,
 Type_Lib,
 Math_Lib,
 Func_Lib,
 Graph_Lib,
 Constants_Lib,
 ObjAnim_Lib;

type
 PObjTex = ^TObjTex;
 TPlane = (pBack, pNone, pFront);

 PParticle = ^TParticle;
 TParticle = class
  private
   Next : TParticle;
  public
   die   : integer; // если <= 0 - частица уничтожается
   Pos   : TPoint2f;
   Size  : TPoint2f;
   Tex   : PTexData;
   Plane : TPlane;
   constructor Create;
   procedure Update; virtual;
   procedure Draw; virtual;
   procedure Draw2; virtual;
 end;

// физический объект - частица расчитывающая столкновения
 TP_Phys = class(TParticle)
   constructor Create(Pos: TPoint2f);
  public
   block  : Byte;
   dPos   : TPoint2f; // скорость (d- это дифференциал ;)
   Angle  : single;   // угол поворота
   wAngle : single;   // скорость вращения
   procedure Update; override;
 end;

// дымок
 TP_Smoke = class(TParticle)
   constructor Create(Pos: TPoint2f);
   procedure Draw; override;
 end;

// гильза
 TP_Shell = class(TP_Phys)
   constructor Create(Pos, dPos: TPoint2f; Weapon_ID: Byte);
   procedure Update; override;
   procedure Draw; override;
 end;

// вспышка
 TP_Flash = class(TParticle)
   Angle : single;
   constructor Create(Pos: TPoint2f; Weapon_ID: Byte);
   procedure Draw; override;
 end;

// свет
 TP_Light = class(TParticle)
   Color : TRGBA;
   Angle : single;
   constructor Create(Pos, Size: TPoint2f; Color: TRGBA; Light_ID : Byte);
   procedure Draw; override;
   procedure Update; override;
 end;

// гаснущий свет
 TP_Light_2 = class(TP_Light)
   procedure Update; override;
 end;

 TP_Blood = class(TParticle)
   dPos      : TPoint2f;
   Tex       : TObjTex;
   constructor Create(Pos: TPoint2f);
   procedure Update; override;
   procedure Draw; override;
 end;

 TP_Gibs = class(TP_Phys)
   Tex       : TObjTex;
   constructor Create(Pos: TPoint2f; ID: Byte);
   procedure Update; override;
   procedure Draw; override;
 end;

 TP_Explosion = class(TParticle)
   Tex   : TObjTex;
   Light : TP_Light;
   angle : single;
   constructor Create(Pos: TPoint2f; Weapon_ID: Byte);
   procedure Update; override;
   procedure Draw; override;
 end;

// искра
 TP_Spark = class(TParticle)
   dPos  : TPoint2f; // скорость (d- это дифференциал ;)
   Color : TRGBA;
   constructor Create(Pos, dPos: TPoint2f);
   procedure Update; override;
   procedure Draw; override;
 end;

// след на стене от выстрела
 TP_Mark = class(TParticle)
   Color : TRGBA;
   constructor Create(Pos: TPoint2f; Weapon_ID: Byte);
   procedure Update; override;
   procedure Draw; override;
 end;

// снег
 TP_Snow = class(TParticle)
   spX : single;
   constructor Create(Pos: TPoint2f);
   procedure Update; override;
   procedure Draw; override;
 end;

// грибной дождик :)
 TP_Rain = class(TParticle)
   constructor Create(Pos: TPoint2f);
   procedure Update; override;
   procedure Draw; override;
 end;

// след от пуль машингана и дробовика
 TP_BulletTrace = class(TParticle)
   constructor Create(Pos, ePos: TPoint2f);
   procedure Draw; override;
  protected
   cPos : TPoint2f;
 end;

 TP_Frag = class(TParticle)
   constructor Create(Pos: TPoint2f; Value: ShortInt);
   procedure Draw; override;
  public
   Value : ShortInt;
 end;

 TP_Bubble = class(TParticle)
   constructor Create(Pos: TPoint2f);
   procedure Update; override;
   procedure Draw; override;
 end;

 TP_Brick = class(TP_Phys)
   constructor Create(Pos: TPoint2f; s, t, u: single; Tex: PTexData);
  public
   s, t, u : single;
   procedure Draw; override;
 end;

 TP_Portal = class(TParticle)
  constructor Create(Pos: TPoint2f);
  public
   Tex : TObjTex;
   procedure Update; override;
   procedure Draw; override;
 end;

 function Particle_Count: integer;
 procedure Particle_Init;
 procedure Particle_Free;
 procedure Particle_Update;
 procedure Particle_Draw(Plane: TPlane);
 procedure Particle_Clear;
 function Particle_Add(P: TParticle): TParticle;

 procedure Particle_Blood(x, y: single);
 procedure Particle_TraceBubbles(p1, p2: TPoint2f);

 function Randomf: single;

const
 BUBBLE_C = 0.1;

var
 Particle_inframe : integer;

var
	randseed1: longint;
 Particle        : TParticle;
 FParticle_Count : integer;
// дым
 smoke_1 : TTexData;   // дым

// гильзы
 m_shell : TTexData;   // машинган
 s_shell : TTexData;   // дроб

// свет
 light_1 : TTexData;   // просто

// метка
 mrk_bullet : TTexData;
 mrk_plasma : TTexData;
 mrk_exp    : TTexData;
 mrk_rail   : TTexData;

// вспышки огня
 m_flash   : TTexData;   // машинган
 s_flash   : TTexData;   // дроб
 gl_flash  : TTexData;   // гранатомёт
 bfg_flash : TTexData;   // BIG FUCKING GUN!!! :)

// спрайты снарядов
 gl_shot  : TTexData;  // граната
 rl_shot  : TTexData;  // ракета
 sh_shot  : TTexData;  // шафт
 pl_shot  : TTexData;  // плазма
 bfg_shot : TTexData;  // бфг

// погодные эффекты
 snow    : TTexData;   // снег
 bubble  : TTexData;

implementation

uses
 Map_Lib, MapObj_Lib, Phys_Lib;

// Particle functions /////////////////////////////////////

function Randomf: single;
var
   r: longint;
begin
   r:=randseed;
   randseed:=randseed1;
   Result:=random;
   randseed1:=randseed;
   randseed:=r;
end;

// инициализация
procedure Particle_Init;
begin
// обязательно нужны процедуры заполняющие структуру Tex
// боюсь при смене мода этот могут возникнуть баги!
Particle        := nil;
FParticle_Count := 0;
Log('---- Initializing particle system ----');
xglTex_Load('textures\sprites\smoke', @smoke_1);

xglTex_Load('textures\sprites\m_shell', @m_shell);
xglTex_Load('textures\sprites\s_shell', @s_shell);

xglTex_Load('textures\sprites\light_1', @light_1);
xglTex_Load('textures\sprites\mark\bullet', @mrk_bullet);
xglTex_Load('textures\sprites\mark\plasma', @mrk_plasma);
xglTex_Load('textures\sprites\mark\exp', @mrk_exp);
xglTex_Load('textures\sprites\mark\rail', @mrk_rail);

xglTex_Load('textures\sprites\m_flash', @m_flash);
xglTex_Load('textures\sprites\s_flash', @s_flash);
xglTex_Load('textures\sprites\gl_flash', @gl_flash);
xglTex_Load('textures\sprites\bfg_flash', @bfg_flash);

xglTex_Load('textures\weapons\shot\grenade', @gl_shot);
xglTex_Load('textures\weapons\shot\rocket', @rl_shot);
xglTex_Load('textures\weapons\shot\shaft', @sh_shot);
xglTex_Load('textures\weapons\shot\plasma', @pl_shot);
xglTex_Load('textures\weapons\shot\bfg', @bfg_shot);

xglTex_Load('textures\sprites\snow', @snow);
xglTex_Load('textures\sprites\bubble', @bubble);
Log('---- Finish particle initialization ----');
end;

// полная очистка
procedure Particle_Free;
begin
Particle_Clear;
// smoke
xglTex_Free(@smoke_1);
// shell
xglTex_Free(@m_shell);
xglTex_Free(@s_shell);
// flash
xglTex_Free(@light_1);
xglTex_Free(@mrk_bullet);
xglTex_Free(@mrk_plasma);
xglTex_Free(@mrk_exp);
xglTex_Free(@mrk_rail);
xglTex_Free(@m_flash);
xglTex_Free(@s_flash);
xglTex_Free(@gl_flash);
xglTex_Free(@bfg_flash);
// спрайты снарядов
xglTex_Free(@gl_shot);
xglTex_Free(@rl_shot);
xglTex_Free(@sh_shot);
xglTex_Free(@pl_shot);
xglTex_Free(@bfg_shot);
// погодные эффеты
xglTex_Free(@snow);
xglTex_Free(@bubble);
end;

// количество "живых" частиц
function Particle_Count: integer;
begin
Result := FParticle_Count;
end;

// обновление системы частиц
procedure Particle_Update;
var
 i : integer;
 n : PParticle;
 p : TParticle;
begin
// обновляем каждый партикл
n := @Particle;

while n^ <> nil do
 begin
 n^.Update;
 n := @n^.Next;
 end;

n := @Particle;
i := 0;
// очистка от менртвецов :)
while n^ <> nil do
 if (n^.die < 1) or (i >= r_maxparticles) then // мёртвый партикл
  begin
  p  := n^;
  n^ := n^.Next;
  p.Free;
  end
 else
  begin
  inc(i);
  n := @n^.Next;
  end;
FParticle_Count := i;
end;

// отрисовка частиц
procedure Particle_Draw(Plane: TPlane);
var
 a, b, c, d : TPoint2f;
 n          : TParticle;
begin
xglAlphaBlend(1);
with Map.Camera do
 begin
 a.X := Pos.X - View.X;
 a.Y := Pos.Y - View.Y;
 b.X := Pos.X + View.X;
 b.Y := Pos.Y + View.Y;
 end;

n := Particle;
while n <> nil do
 begin
 // отсечение невидимых частиц
 // при поворотах частици - может глючить
 if Plane = n.Plane then
  begin
  with n do
   begin
   c.X := Pos.X - Size.X;
   c.Y := Pos.Y - Size.Y;
   d.X := Pos.X + Size.X;
   d.Y := Pos.Y + Size.Y;


   if (d.X > a.X) and
      (c.X < b.X) and
      (d.Y > a.Y) and
      (c.Y < b.Y) or
      ((Size.X = 0) and
       (Size.Y = 0)) then
    begin
    n.Draw;
    inc(Particle_inframe);
    end;
   end;
  end;
 n := n.Next;
 end;
end;

// очистка системы
procedure Particle_Clear;
var
 n, p : TParticle;
begin
n := Particle;
while n <> nil do
 begin
 p := n.Next;
 n.Free;
 n := p;
 end;
Particle := nil;
FParticle_Count := 0;
end;

// добавление новой частицы
// при положительном результате возвращает указатель на чсозданную астицу
function Particle_Add(P: TParticle): TParticle;
begin
Result := nil;
if Particle_Count < r_maxparticles then
 begin
 P.Next   := Particle;
 Particle := P;
 inc(FParticle_Count);
 Result := Particle;
 end
else
 P.Free;
end;

procedure Particle_Blood(x, y: single);
var
 i : integer;
 p : TPoint2f;
begin
if r_blood then
 begin
 p.X := X;
 p.Y := Y;
 for i := 1 to r_blood_count do
  Particle_Add(TP_Blood.Create(p));
 end;
end;

procedure Particle_TraceBubbles(p1, p2: TPoint2f);
var
 i        : integer;
 wx1, wy1 : integer;
 wx2, wy2 : integer;
 dx, dy   : integer;
 xer, yer : integer;
 ix, iy   : integer;
 x, y, d  : integer;
begin
wx1 := trunc(p1.X);
wy1 := trunc(p1.Y);
wx2 := trunc(p2.X);
wy2 := trunc(p2.Y);

xer := 0;
yer := 0;
dx := wx2 - wx1;
dy := wy2 - wy1;

ix := sign(dx);
iy := sign(dy);

dx := abs(dx);
dy := abs(dy);

if dx > dy then
 d := dx
else
 d := dy;

x := wx1;
y := wy1;

for i := 1 to d do
 begin
 inc(xer, dx);
 inc(yer, dy);

 if xer > d then
  begin
  dec(xer, d);
  inc(x, ix);
  end;

 if yer > d then
  begin
  dec(yer, d);
  inc(y, iy);
  end;
  
 if (random(256) < r_bubble_count) and Map.block_Water_s(x, y) then
  Particle_Add(TP_Bubble.Create(Point2f(x, y)));
 end;
end;


///////////////////////////////////////////////////////////
// обычная частица - спрайт //
constructor TParticle.Create;
begin
Pos.X  := 0;
Pos.Y  := 0;
Size.X := 16;
Size.Y := 16;
die    := 255;
Next   := nil;
Plane  := pNone;
end;

procedure TParticle.Update;
begin
if die > 0 then
 dec(die);
end;

procedure TParticle.Draw;
begin
glBegin(GL_QUADS);
 glTexCoord2f(0, 1); glVertex2f(-Size.X, -Size.Y);
 glTexCoord2f(1, 1); glVertex2f( Size.X, -Size.Y);
 glTexCoord2f(1, 0); glVertex2f( Size.X,  Size.Y);
 glTexCoord2f(0, 0); glVertex2f(-Size.X,  Size.Y);
glEnd;
end;

procedure TParticle.Draw2;
begin
glBegin(GL_QUADS);
 glTexCoord2f(0, 1); glVertex2f(Pos.X - Size.X, Pos.Y - Size.Y);
 glTexCoord2f(1, 1); glVertex2f(Pos.X + Size.X, Pos.Y - Size.Y);
 glTexCoord2f(1, 0); glVertex2f(Pos.X + Size.X, Pos.Y + Size.Y);
 glTexCoord2f(0, 0); glVertex2f(Pos.X - Size.X, POs.Y + Size.Y);
glEnd;
end;


constructor TP_Phys.Create(Pos: TPoint2f);
begin
inherited Create;
self.Pos := Pos;
block    := 0;
Angle    := randomf*360;
wAngle   := randomf*10 - 5;
end;

procedure TP_Phys.Update;
var
 bool : boolean;
 obj  : TPhysObj;
begin
bool := false;

if dPos.X <> 0 then
 begin
 if Map.Block_sObj(Pos.X + dPos.X, Pos.Y, obj, true) then
  begin
  dPos.X := - dPos.X - 2*obj.dpos.X;
  bool := true;
  end;
 Pos.X := Pos.X + dPos.X;
 end;

if dPos.Y <> 0 then
 begin
 if Map.Block_s(Pos.X, Pos.Y + dPos.Y) then
  begin
  if Map.Block_sObj(Pos.X, Pos.Y + dPos.Y, obj, true) then
   dPos.Y := dPos.Y-2*obj.dpos.Y
  else
   dPos.Y := -dPos.Y;
  bool := true;
  dPos.Y := -dPos.Y;
  end;
 Pos.Y := Pos.Y + dPos.Y;
 end;

if bool then
 begin
 dPos.X := dPos.X*0.5;
 dPos.Y := dPos.Y*0.5;
 wAngle := -wAngle*0.5;
 inc(block);
 end
else
 begin
 Angle := Angle + wAngle;
 block := 0;
 end;

if block > 10 then die := 0;
dPos.Y := dPos.Y + sv_gravity * 0.00028;
inherited;
end;

// дым //
constructor TP_Smoke.Create(Pos: TPoint2f);
var
 i : integer;
begin
inherited Create;
self.Pos := Pos;
die := 75;
Size := Point2f(8, 8);
Tex := @smoke_1;
// если дым в воде - делаем из него 3 пузырька
if Map.block_Water_s(Pos.X, Pos.Y) then
 begin
 for i := 1 to r_bubble_count div 5 do
  Particle_Add(TP_Bubble.Create(Point2f(Pos.X + randomf*8 - 4, Pos.Y + randomf*8 - 4)));
 Die  := 0;
 Size := Point2f(0, 0);
 end;
end;

procedure TP_Smoke.Draw;
var
 s : single;
begin
s := (100 - die)*20/75;
Size.X := s;
Size.Y := s;
glColor4f(1, 1, 1, die/75);
xglTex_Enable(Tex);
glPushMatrix;
glTranslate(trunc(Pos.X), trunc(Pos.Y), 0);
glRotatef(die, 0, 0, 1);
inherited;
glPopMatrix;
end;

// гильза //
constructor TP_Shell.Create(Pos, dPos: TPoint2f; Weapon_ID: Byte);
begin
inherited Create(Pos);
if r_shell_speed then
 begin
 dPos.X := dPos.X + randomf-0.5;
 dPos.Y := dPos.Y + -1;
 end
else
 dPos := Point2f(randomf-0.5, -1);

die       := r_shell_time;
self.dPos := dPos;
Size      := Point2f(1.5, 0.5);
 case Weapon_ID of
  WPN_MACHINEGUN : Tex := @m_shell;
  WPN_SHOTGUN    : Tex := @s_shell;
 else
  die := 0;
 end;
end;

procedure TP_Shell.Update;
begin
inherited;
if die > r_shell_time then
 die := r_shell_time;
end;

procedure TP_Shell.Draw;
begin
glPushMatrix;
glTranslate(trunc(Pos.X), trunc(Pos.Y), 0);
glRotatef(Angle, 0, 0, 1);
xglAlphaBlend(1);
glEnable(GL_POLYGON_SMOOTH);
glColor4f(1, 1, 1, 1);
xglTex_Enable(Tex);
inherited;
glDisable(GL_POLYGON_SMOOTH);
glPopMatrix;
end;

// вспышка огня //
constructor TP_Flash.Create(Pos: TPoint2f; Weapon_ID: Byte);
begin
inherited Create;
Plane    := pFront;
self.Pos := Pos;
Angle := randomf*360;
Size  := Point2f(16, 16);
die   := 2;
 case Weapon_ID of
  WPN_MACHINEGUN : Tex := @m_flash;
  WPN_SHOTGUN    : Tex := @s_flash;
  WPN_GRENADE    : Tex := @gl_flash;
  WPN_BFG        : Tex := @bfg_flash;
 else
  die := 0;
 end;
end;

procedure TP_Flash.Draw;
begin
glPushMatrix;
glTranslate(Pos.X, Pos.Y, 0);
glRotatef(Angle, 0, 0, 1);
xglAlphaBlend(2);
glColor4f(1, 1, 1, 1);
xglTex_Enable(Tex);
inherited;
xglAlphaBlend(1);
glPopMatrix;
end;

// обычный свет, не умрёт пока не убьют :) //
constructor TP_Light.Create(Pos, Size: TPoint2f; Color: TRGBA; Light_ID : Byte);
begin
inherited Create;
die        := 2;
self.Pos   := Pos;
self.Color := Color;
self.Size  := Size;
Plane      := pFront;
 case Light_ID of
  1 : Tex := @light_1;
 else
  die := 0;
 end;
end;

procedure TP_Light.Draw;
begin
glPushMatrix;
glTranslate(Pos.X, Pos.Y, 0);
glRotatef(Angle, 0, 0, 1);
xglAlphaBlend(2);
glColor4ubv(@Color);
xglTex_Enable(Tex);
inherited;
xglAlphaBlend(1);
glPopMatrix;
end;

procedure TP_Light.Update;
begin
Angle := Angle + 5;
end;

// умирающий источник света //
procedure TP_Light_2.Update;
begin
dec(die);
end;

// кровь //
constructor TP_Blood.Create(Pos: TPoint2f);
begin
inherited Create;
Tex := TObjTex.Create('textures\sprites\blood', 1, 0, 1, true, false, nil);;
if Tex.FrameCount > 0 then
 begin
 Tex.Wait := r_blood_time div Tex.FrameCount;
 Tex.FWait := Tex.Wait;
 die := r_blood_time;
 end
else
 die := 0;

Tex.FrameIndex := 0;

self.Pos  := Pos;
self.dPos := Point2f(randomf - 0.5, -randomf);
Size      := Point2f(8, 8);
end;

procedure TP_Blood.Update;
begin
Pos.X := Pos.X + dPos.X;
Pos.Y := Pos.Y + dPos.Y;
if Map.Block_s(Pos.X, Pos.Y) or
   Map.Block_s(Pos.X, Pos.Y) then
 die := 0;
 // XProger: тут можно вставить создание следа от крови

dPos.Y := dPos.Y + (sv_gravity*0.00014);

if r_blood_time > 0 then
 begin
 if die > r_blood_time then
  begin
  Tex.Wait := r_blood_time div Tex.FrameCount;
  die := r_blood_time;
  end;

 if not r_blood then
  die := 0;

 if Tex <> nil then
  if (Tex.FrameIndex = Tex.FrameCount - 1) and (Tex.FWait = 1) then
   die := 0
  else
   Tex.Update
 else
  die := 0;
 end
else
 die := 0;
end;

procedure TP_Blood.Draw;
begin
xglAlphaBlend(1);
xglTex_Enable(Tex.CurFrame);
glColor4f(1, 1, 1, 1);
Draw2;
end;

{ TP_GIBS }
constructor TP_Gibs.Create(Pos: TPoint2f; ID: Byte);
begin
inherited Create(Pos);
Tex := TObjTex.Create('textures\sprites\gibs', 1, 0, 1, true, false, nil);;
if Tex.FrameCount > 0 then
 die := r_gibs_time
else
 die := 0;

Tex.FrameIndex := ID;

self.dPos := Point2f(randomf*3 - 1.5, -randomf*3);
Size      := Point2f(12, 12);
Plane     := pBack;
end;

procedure TP_Gibs.Update;
begin
inherited;
if die > r_gibs_time then
 die := r_gibs_time;
if r_blood and (r_gibs_blood > 0) then
 if (abs(dPos.X) > 0.5) or (abs(dPos.Y) > 0.5) then
  if die mod r_gibs_blood = 0 then
   if r_gibs_blood_static then
    TP_Blood(Particle_Add(TP_Blood.Create(Pos))).dPos := NullPoint
   else
    Particle_Add(TP_Blood.Create(Pos));
end;

procedure TP_Gibs.Draw;
var
 z : integer;
begin
glPushMatrix;
if die < 80 then
 z := 8 - trunc(die * 0.1)
else
 z := 0;
glTranslate(trunc(Pos.X), trunc(Pos.Y) + z, 0);
glRotatef(Angle, 0, 0, 1);
xglAlphaBlend(1);
glColor4f(1, 1, 1, 1);
xglTex_Enable(Tex.CurFrame);
inherited;
glPopMatrix;
end;

{ TP_EXPLOSION }
constructor TP_Explosion.Create(Pos: TPoint2f; Weapon_ID: Byte);

 procedure AddLight(R, G, B: Byte);
 begin
 if r_weapon_light then
  begin
  Light := TP_Light.Create(Point2f(Pos.X, Pos.Y), Point2f(48, 48), RGBA(R, G, B, 128), 1);
  Particle_Add(Light);
  end;
 end;

begin
inherited Create;
Plane     := pFront;
self.Pos  := Pos;
Size      := Point2f(16, 16);
angle     := trunc(random * 360);

 case Weapon_ID of
  WPN_MACHINEGUN,
  WPN_SHOTGUN : begin
                Tex  := TObjTex.Create('textures\sprites\gunspark', 1, 0, 5, true, false, nil);
                Size := Point2f(8, 8);
                end;
  WPN_ROCKET  : Tex := TObjTex.Create('textures\sprites\rl_exp', 1, 0, 3, true, false, nil);
  WPN_GRENADE : Tex := TObjTex.Create('textures\sprites\gl_exp', 1, 0, 6, true, false, nil);
  WPN_PLASMA  : Tex := TObjTex.Create('textures\sprites\plasma_exp', 1, 0, 3, true, false, nil);
  WPN_BFG     : Tex := TObjTex.Create('textures\sprites\bfg_exp', 1, 0, 6, true, false, nil);
 end;

 case Weapon_ID of
  WPN_ROCKET  : AddLight(255, 255, 0);
  WPN_GRENADE : AddLight(255, 255, 0);
  WPN_PLASMA  : AddLight(0,   0,   255);
  WPN_BFG     : AddLight(0,   255, 0);
 end;

if Tex <> nil then
 begin
 Tex.FrameIndex := 0;
 die := Tex.Wait * (Tex.FrameCount + 1);
 end;
end;

procedure TP_Explosion.Update;
var
 s : single;
begin
inherited;
if Tex <> nil then
 begin
 Tex.Update;

 if (die <= Tex.Wait) and
    (Tex.FrameIndex = 0) then
  begin
  Tex.FrameIndex := Tex.FrameCount - 1;
  Tex.FWait := Tex.Wait;
  end;

 if Light <> nil then
  begin
  s := 48 * die/(Tex.Wait * (Tex.FrameCount + 1));
  Light.Size := Point2f(s, s);
  Light.die := die;
  end;
 end;
end;

procedure TP_Explosion.Draw;
begin
if Tex <> nil then
 begin
 glPushMatrix;
 glTranslatef(trunc(Pos.X), trunc(Pos.Y), 0);
 glRotatef(angle, 0, 0, 1);
 xglAlphaBlend(2);

 if r_exp_interpolate then
  if Tex.FrameIndex > 0 then
   begin
   if die <= Tex.Wait then
    xglTex_Enable(Tex.Frame[Tex.FrameCount - 1])
   else
    xglTex_Enable(Tex.Frame[Tex.FrameIndex - 1]);
   glColor4f(1, 1, 1, (Tex.FWait + 1)/Tex.Wait);
   inherited;
   end;

 if die > Tex.Wait then
  begin
  xglTex_Enable(Tex.CurFrame);
  glColor4f(1, 1, 1, 1);
  inherited;
  end;

 xglAlphaBlend(1);
 glPopMatrix;
 end;
end;

{ TP_Point }
constructor TP_Spark.Create(Pos, dPos: TPoint2f);
begin
inherited Create;
Plane  := pFront;
dPos.X := dPos.X + randomf - 0.5;
dPos.Y := dPos.Y + randomf - 0.5;
die       := 25;
self.Pos  := Pos;
self.dPos := dPos;
Color     := RGBA(255, 0, 0, 255);
Size      := Point2f(0.5, 0.5);
end;

procedure TP_Spark.Draw;
begin
xglAlphaBlend(1);
glColor4ubv(@Color);
xglTex_Disable;
glEnable(GL_LINE_SMOOTH);
glLineWidth(1);
glBegin(GL_LINES);
 glVertex2fv(@Pos);
 glVertex2f(Pos.X - dPos.X, Pos.Y - dPos.Y);
glEnd;
glDisable(GL_LINE_SMOOTH);
end;

procedure TP_Spark.Update;
begin
Color.G := round((25 - die)/25*255);
if die < 5 then
 Color.A := round(die/5*255);
dPos.Y := dPos.Y + 0.056;
Pos.X  := Pos.X + dPos.X;
Pos.Y  := Pos.Y + dPos.Y;
inherited;
end;

{ TP_Mark }
constructor TP_Mark.Create(Pos: TPoint2f; Weapon_ID: Byte);
begin
inherited Create;
self.Pos  := Pos;
Plane     := pBack;
die       := cg_marks_time;
Color     := RGBA(255, 255, 255, 255);
 case Weapon_ID of
  WPN_PLASMA  : Tex := @mrk_plasma;
  WPN_GRENADE,
  WPN_ROCKET,
  WPN_BFG     : Tex := @mrk_exp;
  WPN_RAILGUN : Tex := @mrk_rail;
 else
  Tex := @mrk_bullet;
 end;
Size := Point2f(16, 16);
end;

procedure TP_Mark.Update;
begin
inherited Update;
if die < 250 then
 Color.A := trunc(255*die/250);
end;

procedure TP_Mark.Draw;
begin
glColor4ubv(@Color);
xglTex_Enable(Tex);
Draw2;
end;

// снег
{ TP_Snow }
constructor TP_Snow.Create(Pos: TPoint2f);
begin
inherited Create;
Plane    := pFront;
self.Pos := Pos;
spX  := 0;
die  := 65536;
Size := Point2f(2, 2);
end;

procedure TP_Snow.Update;
var
 obj : TPhysObj;
begin
if not Map.Block_sObj(Pos.X, Pos.Y, obj, true) then
 begin
 spX   := spX + randomf*0.1-0.05;
 Pos.Y := Pos.Y + 1;
 Pos.X := Pos.X + spX;
 end
else
 begin
 Pos.X := Pos.X + obj.dpos.X;
 Pos.Y := Pos.Y + obj.dpos.Y;
 if die = 65536 then
  die := r_snow_time;
 die := die - 1;
 end;
if Map.block_Water_s(Pos.X, Pos.Y) then
 die := 0;
end;

procedure TP_Snow.Draw;
var
 p : TPoint2f;
begin
glColor4f(1, 1, 1, min(die, 255)/255);
xglTex_Enable(@snow);
p := Pos;
Pos.X := trunc(Pos.X);
Pos.Y := trunc(Pos.Y);
Draw2;
Pos := p;
end;

// дождь
{ TP_Rain }
constructor TP_Rain.Create(Pos: TPoint2f);
begin
inherited Create;
self.Pos := Pos;
end;

procedure TP_Rain.Update;
begin
Plane := pFront;
Pos.Y := Pos.Y + maxspeed_falling;
die   := Byte(not Map.block_s(Pos.X, Pos.Y) or Map.block_Water_s(Pos.X, Pos.Y));
end;

procedure TP_Rain.Draw;
begin
xglTex_Disable;
with Pos do
 begin
 glLineWidth(1);
 glBegin(GL_LINES);
  glColor4f(1, 1, 1, 0);
  glVertex2f(trunc(X), trunc(Y - maxspeed_falling));
  glColor4f(1, 1, 1, 0.5);
  glVertex2f(trunc(X), trunc(Y));
 glEnd;
 end;
end;

{ TP_BulletTrace }
constructor TP_BulletTrace.Create(Pos, ePos: TPoint2f);
var
 d : single;
begin
inherited Create;
Plane := pFront;
Size.X := 0;
Size.Y := 0;
d := randomf;
cPos.X := Pos.X + d * (ePos.X - Pos.X);
cPos.Y := Pos.Y + d * (ePos.Y - Pos.Y);
d := randomf;
self.Pos.X := Pos.X + d * (cPos.X - Pos.X);
self.Pos.Y := Pos.Y + d * (cPos.Y - Pos.Y);
die := r_bullet_trace;
end;

procedure TP_BulletTrace.Draw;
begin
xglTex_Disable;
glLineWidth(1);
glEnable(GL_LINE_SMOOTH);
glBegin(GL_LINES);
 glColor4f(1, 0.8, 0, 0);
 glVertex2fv(@Pos);
 glColor4f(1, 0.8, 0, 0.3);
 glVertex2fv(@cPos);
glEnd;
glDisable(GL_LINE_SMOOTH);
end;

{ TP_Frag }
constructor TP_Frag.Create(Pos: TPoint2f; Value: ShortInt);
begin
inherited Create;
self.Value := Value;
self.Plane := pFront;
self.die   := 200;
self.Pos   := Pos;
end;

procedure TP_Frag.Draw;
begin
if Value < 0 then
 glColor4f(1, 0, 0, die/200)
else
 glColor4f(1, 1, 1, die/200);
TextOut(trunc(Pos.X + sin(die/10)*5), trunc(Pos.Y - (200 - die)/3), PChar(IntToStr(Value)));
end;

{ TP_Bubble }
constructor TP_Bubble.Create(Pos: TPoint2f);
var
 s : single;
begin
inherited Create;
self.Plane := pNone;
self.Pos   := Pos;
s := trunc(randomf*4) + 4; // случайный размер пузырька (4 < x < 8)
Size := Point2f(s, s);
Die  := r_bubble_time;
end;

procedure TP_Bubble.Update;
begin
Pos.Y := Pos.Y - Size.Y * BUBBLE_C;
// если не в воде, или в стене
if not Map.block_Water_s(Pos.X, Pos.Y) or Map.block_s(Pos.X, Pos.Y) then
 Die := 0;
dec(Die);
end;

procedure TP_Bubble.Draw;
var
 p : TPoint2f;
begin
if die < 25 then
 glColor4f(1, 1, 1, die/25)
else
 glColor4f(1, 1, 1, 1);
xglTex_Enable(@bubble);
p := Pos;
Pos.X := trunc(Pos.X);
Pos.Y := trunc(Pos.Y);
Draw2;
Pos := p;
end;

{ TP_Brick // кусок брика // }
constructor TP_Brick.Create(Pos: TPoint2f; s, t, u: single; Tex: PTexData);
begin
inherited Create(Pos);
self.s   := s;
self.t   := t;
self.u   := u;
dPos     := Point2f(randomf * 4 - 2, -randomf * 4);
die      := r_part_time;
Size     := Point2f(u * 16, u * 8);
Plane    := pBack;
self.Tex := Tex;
end;

procedure TP_Brick.Draw;
var
 z : integer;
begin
if die < 80 then
 z := 8 - trunc(die * 0.1)
else
 z := 0;
xglAlphaBlend(1);
glColor3f(1, 1, 1);
glPushMatrix;
glTranslatef(trunc(Pos.X), trunc(Pos.Y) + z, 0);
glRotatef(trunc(Angle), 0, 0, 1);
xglTex_Enable(Tex);
glBegin(GL_QUADS);
 glTexCoord2f(s,     1 - t);     glVertex2f(-Size.X, -Size.Y);
 glTexCoord2f(s + u, 1 - t);     glVertex2f( Size.X, -Size.Y);
 glTexCoord2f(s + u, 1 - t - u); glVertex2f( Size.X,  Size.Y);
 glTexCoord2f(s,     1 - t - u); glVertex2f(-Size.X,  Size.Y);
glEnd;
glPopMatrix;
end;

{TP_Portal // эффект при телепортировании //}
constructor TP_Portal.Create(Pos: TPoint2f);
begin
inherited Create;
self.Pos := Pos;
Size.X := 16;
Size.Y := 24;
Plane  := pFront;
Tex := TObjTex.Create('textures\sprites\portal_fx', 2, 0, 4, false, false, nil);
die := Tex.FrameCount * 4;
end;

procedure TP_Portal.Update;
begin
inherited;
Tex.Update;
end;

procedure TP_Portal.Draw;
begin
xglTex_Enable(Tex.CurFrame);
glColor4f(1, 1, 1, 1);
glBegin(GL_QUADS);
 glTexCoord2f(0, 0); glVertex2f(Pos.X - Size.X, Pos.Y - Size.Y);
 glTexCoord2f(1, 0); glVertex2f(Pos.X + Size.X, Pos.Y - Size.Y);
 glTexCoord2f(1, 3); glVertex2f(Pos.X + Size.X, Pos.Y + Size.Y);
 glTexCoord2f(0, 3); glVertex2f(Pos.X - Size.X, Pos.Y + Size.Y);
glEnd;
end;

end.
