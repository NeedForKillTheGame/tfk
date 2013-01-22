unit Real_Lib;

(***************************************)
(*  TFK Real-Time Objects       1.0.1.9*)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

{Physical objects reference}
{by NEOFF}

{основные переменные -
	x, y,  (положение)
   lx, ly (предыдущее положение) - вообще не используется сейчас... в структуре его нету.
	dx,dy, (дифференциал)
 по этим параметрам идет рассчет следующего положения.
 для рассчета гранат удобнее использовать dx, dy в то время
 как для обычного объекта - lx, ly. Тогда остановку объекта легче предугадать.
}

interface

uses
 SysUtils,
 OpenGL,
 Engine_Reg,
 Func_Lib,
 Type_Lib,
 Graph_Lib,
 Math_Lib,
 Model_Lib,
 ObjAnim_Lib,
 ObjSound_Lib,
 MapObj_Lib,
 ItemObj_Lib,
 Constants_Lib,
 Demo_Lib,
 Particle_Lib;

const
 REAL_MAX_UID = 256;

type
 TRealObjType = (otSprite, otItem, otShot, otDeadPlayer);

//данная структура будет отсылаться по сети %%)))
//в этой структуре должны быть все важнейшие переменные
 TRealObjStruct = record
  UID                   : WORD;
  playerUID, ItemID     : Byte;
  objtype               : TRealObjType;
  x, y, dx, dy, angle   : single;
  //перевернут ли объект...
  orient                : Byte; //0 - как всегда 1- переворот отн. горизонтальной оси. 2- вертикальной
  twinkle: boolean;
  //Для Real'shot-а - номер оружия
  //А для Real'Item-a - номер итема.
  //количество предмета
  ItemCount             : WORD;
  livetimer             : WORD; //время до уничтожения...
 end;

//размер типа - 43 байта... жалко что single ни на что не поменяешь :)
//в принципе по сетке можно передавать и integer...но это потом придумаем

// XProger: во время игры ни один подобный объект передаваться не должен
//          а вот при коннекте - обязательно нужно передавать.

 PRealObj = ^TRealObj;

 TRealObj = class
   constructor Create(struct_: TRealObjStruct);
   destructor Destroy;override;
  protected
   fstruct: TRealObjStruct;
   fdead: boolean;// надо ли удалять объект

   width, height: integer;//ширина и высота ФИЗИЧЕСКАЯ
   fgraph_rect: TRect;//in Object x y coordinates
  public
   Next  : TRealObj;
   Plane : TPlane;
   lx, ly: single;
   //lx, ly - предыдущее положение
   color: TRGBA;
   anim: TObjTex;
   sound: TSound;
   animate: boolean;
   rect: TRect;
   tag: integer;
   property Struct: TRealObjStruct read fstruct write fstruct;
   property x: single read fstruct.x write fstruct.x;
   property y: single read fstruct.y write fstruct.y;

   property angle: single read fstruct.angle write fstruct.angle;
   property UID: word read fstruct.UID;
   property PlayerUID: byte read fstruct.PlayerUID;
   property Dead: boolean read fdead;
   property Weapon: byte read fstruct.ItemID;
   property livetimer: word read fstruct.livetimer write fstruct.livetimer;

   procedure OnPlayer(sender: TObject); virtual;//пересечение с границами Player'a
   procedure SetColor(color: TRGB);
   procedure Kill; virtual;
   procedure Update; virtual;
   procedure Draw; virtual;

   procedure CheckTwinkle;
 end;

//ОБЪЕКТ , ОСТАНАВЛИВАЕМЫЙ БРИКАМИ
 TRealObj1 = class(TRealObj)
   constructor Create(struct_ : TRealObjStruct);
  protected
   fIgnoreEmpty: boolean;
   //характер удара
   fBlockLeft, fBlockTop, fBlockRight, fBlockBottom, fBlockAll: boolean;
   fOldBlock, fNoDoorStop: boolean; //Если дверка закрылась - не останавливаться.
   fObj: TPhysObj;
  public
   procedure Update; override;
   procedure OnStop; virtual;
 end;

 TShotObj = class(TRealObj1)
   constructor Create(struct_: TRealObjStruct);
  protected
   light: TP_Light;
   quad, damage: integer;
   f_player: boolean;
  public
   procedure OnStop; override;
   procedure Update; override;
   procedure Kill;override;
   procedure OnPlayer(sender: TObject);override;
   procedure Draw;override;
 end;

 TGrenadeShot = class(TShotObj)
  protected
   damage: integer;
  public
   constructor Create(struct_: TRealObjStruct);
   procedure Update; override;
   procedure OnStop; override;
 end;

//у ЛУЧЕЙ (dx, dy) - направляющий вектор :))
 TRailShot = class(TRealObj)
   constructor Create(struct_: TRealObjStruct);
  protected
   ticker: integer;
   timer : integer;
  public
   procedure Draw; override;
   procedure Update; override;
 end;

 TDeathLine = class(TRealObj)
   constructor Create(struct_: TRealObjStruct; Owner: TObject);
  protected
   fOwner : TObject;
   len    : single;
  public
   damage       : integer;
   damageticker : integer;
   damagewait   : integer;
   maxlen       : single;
   procedure SetVector(x, y, angle: single);
   procedure Draw; override;
   procedure Update; override;
   procedure OnDamage(hplayer:TObject); virtual;
 end;

 TLightLine = class(TRealObj)
   constructor Create(struct_: TRealObjStruct; Owner: TObject);
  protected
   fOwner : TObject;
   len    : single;
  public
   target : WORD;
   maxlen : single;
   color  : TRGBA;
   procedure SetVector(x, y, angle: single);
   procedure Draw; override;
   procedure Update; override;
  end;

 TShaftShot = class(TRealObj)
   constructor Create(struct_: TRealObjStruct);
  protected
   snd, anim_s : integer;
   Light       : TP_Light;
  public
   len     : single;
   hplayer : TObject;
   procedure SetVector(x, y, angle: single);
   procedure Draw; override;
   procedure Update; override;
   procedure Kill; override;
 end;

//объект подчиняется законам гравитации
 TRealObj2 = class(TRealObj)
   constructor Create(struct_: TRealObjStruct);
  protected
   ph: TPhysRect;
  public
   procedure Update; override;
  end;

//а теперь ВЫПАДАЮЩИЙ ОБЪЕКТ
 TFreeObj= class(TRealObj2)
   constructor Create(struct_: TRealObjStruct);overload;
   constructor Create(Player: TObject; itemid: integer);overload;
	private
   Z     : single; //смещение по синусу
   ang   : single; //угол для синуса
  protected
   fitem : TItemObj;
   procedure SetItem(const Value: TItemObj);
  public
   property ItemCount: word read fstruct.ItemCount;
   property Item: TItemObj read fitem write SetItem;
   function Take(sender: TObject): boolean;
   procedure Draw;override;
   procedure Update;override;
  end;

//****************
//ТРУП
//****************
type
   TDeadPlayer = class(TRealObj2)
     constructor Create(Player: TObject; pHealth: SmallInt);overload;
     constructor Create(struct_: TRealObjStruct);overload;
   protected
     fplayer : TObject;
     Model   : TModel;
     Z       : single;
   public
     Health : integer;
     procedure Gibs;
     procedure Hit(dmg: integer);
     procedure Update; override;
     procedure Push(x0, y0, s: single);
     procedure Draw; override;
   end;

TRocketObj = class(TShotObj)
    constructor Create(struct_: TRealObjStruct);
   public
    snd : integer;
    procedure Update; override;
    procedure Kill; override;
  end;
//предупреждение: в этом массиве могут быть NIL- элементы.
//мне не охото их чистить просто :) я вам не TList.

function RealObj_Add(struct: TRealObjStruct): TRealObj; overload;
function RealObj_Add(R: TRealObj): TRealObj; overload;
procedure RealObj_Clear;
procedure RealObj_Free;
procedure RealObj_Update;
procedure RealObj_Draw(Plane: TPlane);
function RealObj_Count: integer;
function RealObj_Find(UID: integer): TRealObj;
procedure RealObj_TraceDeads(x, y, angle: single; s: single; dmg: SmallInt);


var
 RealObj : TRealObj;

implementation

uses Math, Map_Lib, player_lib, weapon_lib, Stat_Lib, Phys_Lib, NET_LIB, NET_Server_Lib;

var
 FRealObj_Count  : integer;

var
 lastUID: integer;

  function nextUID: integer;
  begin
 	lastUID := (lastUID + 1) mod REAL_MAX_UID;
  Result  := lastUID;
  end;

function RealObj_Add(struct: TRealObjStruct): TRealObj;
begin
//СОЗДАЕМ ПО ОПИСАНИЮ ОБЪЕКТА :)
 case struct.objtype of
  otSprite : Result := TRealObj.Create(struct);
  otShot   :
   case struct.ItemID of
    WPN_PLASMA,
    WPN_BFG         : Result := TShotObj.Create(struct);
    WPN_ROCKET      : Result := TRocketObj.Create(struct);
    WPN_GRENADE     : Result := TGrenadeShot.Create(struct);
    WPN_RAILGUN     : Result := TRailShot.Create(struct);
   else
    Result := TRealObj.Create(struct);
   end;
  otItem       : Result := TFreeObj.Create(struct);
  otDeadPlayer : Result := TDeadPlayer.Create(struct);
 else
  Result := TRealObj.Create(struct);
 end;

Result.Next := RealObj;
RealObj     := Result;
inc(FRealObj_Count);
end;

function RealObj_Add(R: TRealObj): TRealObj;
begin
R.Next  := RealObj;
RealObj := R;
inc(FRealObj_Count);
Result := R;
end;

procedure RealObj_Clear;
begin
RealObj_Free;
lastUID := 10;
end;

procedure RealObj_Free;
var
 n, p : TRealObj;
begin
n := RealObj;
while n <> nil do
 begin
 p := n.Next;
 n.Free;
 n := p;
 end;
RealObj := nil;
FRealObj_Count := 0;
end;

procedure RealObj_Update;
var
 i : integer;
 n : PRealObj;
 p : TRealObj;
begin
// обновляем каждый партикл
n := @RealObj;

while n^ <> nil do
 begin
 n^.Update;
 n := @n^.Next;
 end;

n := @RealObj;
i := 0;
// очистка от менртвецов :)
while n^ <> nil do
 if n^.Dead then // мёртвый объект
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
FRealObj_Count := i;
end;

procedure RealObj_Draw(Plane: TPlane);
var
 n : TRealObj;
begin
xglAlphaBlend(1);
n := RealObj;
while n <> nil do
 begin
 if Plane = n.Plane then
  n.Draw;
 n := n.Next;
 end;
end;

function RealObj_Count: integer;
begin
Result := FRealObj_Count;
end;

function RealObj_Find(UID: integer): TRealObj;
var
 n : TRealObj;
begin
Result := nil;
n := RealObj;
while n <> nil do
 begin
 if n.UID = UID then
  begin
  Result := n;
  Exit;
  end;
 n := n.Next;
 end;
end;

procedure RealObj_TraceDeads(x, y, angle: single; s: single; dmg: SmallInt);
var
 n : TRealObj;
begin
n := RealObj;
while n <> nil do
 begin
 if n.fstruct.objtype = otDeadPlayer then
  if RectVectorIntersect(n.rect, x, y, angle, s) then
   TDeadPlayer(n).Hit(dmg);
 n := n.Next;
 end;
end;

{ TRealObj }
procedure TRealObj.CheckTwinkle;
var
 i   : integer;
begin        
if (not fstruct.twinkle) and
   (fstruct.objtype in [otShot, otDeadPlayer]) then
 with Map, Obj do
  for i := 0 to Trig_Count - 1 do
   if (Triggers[i] is TAreaTeleportWay) and
      PointInRect(trunc(fstruct.x), trunc(fstruct.y),
      Triggers[i].ObjRect) then
    with fstruct do
     begin
     X := X + Triggers[i].struct.gotox * 32 - Triggers[i].ObjRect.X;
     Y := Y + Triggers[i].struct.gotoy * 16 - Triggers[i].ObjRect.Y;
     end;
end;

constructor TRealObj.Create(struct_: TRealObjStruct);
begin
Plane   := pNone;
fdead   := false;
fstruct := struct_;
color   := clWhite;
animate := true;
end;

destructor TRealObj.Destroy;
begin
if anim <> nil then
 anim.Free;
inherited;
end;

procedure TRealObj.Draw;
begin
if anim <> nil then
 with fgraph_rect do
  begin
  glPushMatrix;

	glTranslatef(trunc(fstruct.X), trunc(fstruct.Y), 0);
	glRotatef(fstruct.angle*180/Pi, 0, 0, 1);

  if odd(fstruct.orient) then
   glScalef(-1, 1, 1);

	xglTex_Enable(anim.CurFrame);
 	glBegin(GL_QUADS);
   glTexCoord2f(0, 1); glVertex2f(x, y);
   glTexCoord2f(1, 1); glVertex2f(x+width, y);
   glTexCoord2f(1, 0); glVertex2f(x+width, y+height);
   glTexCoord2f(0, 0); glVertex2f(x, y+height);
 	glEnd;

  glPopMatrix;
  end;
end;

procedure TRealObj.Kill;
begin
   fdead:=true;
end;

procedure TRealObj.OnPlayer(sender: TObject);
begin
//abstract
end;

procedure TRealObj.SetColor(color: TRGB);
begin
   Self.color:=RGBA(color.r, color.g, color.b, 255);
end;

procedure TRealObj.Update;
begin
CheckTwinkle;
with Rect do
 begin
 X      := trunc(fstruct.x - self.width/2);
 Y      := trunc(fstruct.y - self.height/2);
 Width  := self.width;
 Height := self.height;
 end;

if animate and (anim <> nil) then
 anim.Update;

with fstruct do
 if livetimer > 0 then
  dec(livetimer);
end;

{ TRealStoppingObj }

constructor TRealObj1.Create(struct_: TRealObjStruct);
begin
   inherited;
   fObj.dpos:=@NullPoint;
end;

procedure TRealObj1.OnStop;
begin
if fblockleft or fblockright then
 fstruct.dx := 0;
if fblocktop or fblockbottom then
 fstruct.dy := 0;
end;

procedure TRealObj1.Update;
var
 block1,
 block2,
 block3,
 block4 : boolean;
 i, j   : integer;
begin
with fstruct do
 begin
 lx := x;
 ly := y;
 for i := 1 to real_trace do
  begin
  x := x + dx/real_trace;
  y := y + dy/real_trace;
  with Map do
   for j := 0 to Players - 1 do
    if not Player[j].dead and PointInRect(trunc(x), trunc(y), player[j].fRect) then
     begin
     OnPlayer(player[j]);
     if Self.dead then
      Exit;
     end;

  with Rect do
   begin
   X      := trunc(fstruct.X - self.width/2);
   Y      := trunc(fstruct.Y - self.height/2);
   Width  := self.width;
   Height := self.height;

   block1 := Map.Block_sObj(X,         Y,          fObj, fIgnoreEmpty);
   block2 := Map.Block_sObj(X + Width, Y,          fObj, fIgnoreEmpty);
   block3 := Map.Block_sObj(X + Width, Y + Height, fObj, fIgnoreEmpty);
   block4 := Map.Block_sObj(X,         Y + Height, fObj, fIgnoreEmpty);
   end;

  if block1 or block2 or block3 or block4 then
   begin
   fBlockLeft   := (block1 and not block2) or
                   (block4 and not block3);
   fBlockTop    := (block1 and not block4) or
                   (block2 and not block3);
   fBlockRight  := (not block1 and block2) or
                   (not block4 and block3);
   fBlockBottom := (not block1 and block4) or
           			   (not block2 and block3);
   fBlockAll    := block1 and block2 and block3 and block4;
   fblockleft   := fblockleft   and (signf(dx) <= 0);
   fblockright  := fblockright  and (signf(dx) >= 0);
   fblocktop    := fblocktop    and (signf(dy) <= 0);
   fblockbottom := fblockbottom and (signf(dy) >= 0);
   //объект блокирован - срочно надо вытолкнуть его на границу брика
   OnStop;
   x := x + dx;
   y := y + dy;
   break;
   end
  else
   foldblock := false //if block
  end; //for

 x := round2(x, C_ROUND);
 y := round2(y, C_ROUND);
 inherited;
 end; //with fstruct do
end;

{ TFreeObj }

constructor TFreeObj.Create(Player: TObject; itemid: integer);
begin
   fstruct.itemid:=itemid;
   with TPlayer(player), fstruct do
   begin
		if UID = 0 then
 		begin
 			lastUID     := (lastUID + 1) mod REAL_MAX_UID;
 			UID := lastUID;
      end;
      x:=pos.x;
      y:=pos.y;
      dx:=0;
      dy:=dpos.y;

		case ItemID of
  			2..8:
         begin	ItemCount := Def_Ammo[itemid]; Item := WeaponObjs[ItemID];end;
  			REGEN_ID..INV_ID : begin ItemCount := (powerups[itemid] + 49) div 50;
         Item:=PowerUpObjs[itemid];end;
      end;
  end;


   inherited Create(fstruct);


	fgraph_rect.X      := -16;
	fgraph_rect.Y      := -8;
	fgraph_rect.width  := 32;
	fgraph_rect.height := 16;

	width  := 28;
	height := 12;

	fstruct.livetimer := FREEOBJ_LIVETIME;

	Z   := 0;
	ang := 0;
	animate := false;
end;

constructor TFreeObj.Create(struct_: TRealObjStruct);
begin
   inherited;
   Item := WeaponObjs[fstruct.ItemID];

	fgraph_rect.X      := -16;
	fgraph_rect.Y      := -8;
	fgraph_rect.width  := 32;
	fgraph_rect.height := 16;

	width  := 28;
	height := 12;

	fstruct.livetimer := FREEOBJ_LIVETIME;

	Z   := 0;
	ang := 0;
	animate := false;
end;

procedure TFreeObj.Draw;
begin
xglTex_Enable(anim.CurFrame);
glColor4f(1, 1, 1, 1);
glPushMatrix;
glTranslate(0, Z, 0);
inherited;
glPopMatrix;
end;

procedure TFreeObj.SetItem(const Value: TItemObj);
begin
fitem := Value;
if (Value <> nil) and
   (Value.anim <> nil) then
 anim := TObjTex.Create(Value.anim);
end;

function TFreeObj.Take(sender: TObject): boolean;
begin
Result := false;
if Item.Take(sender, Itemcount) then
 begin
 Result := true;
 Item.sound.Play(TPlayer(sender).Pos.X, TPlayer(sender).Pos.Y);
 Kill;
 end;
end;

procedure TFreeObj.Update;
var
 i: integer;
begin
inherited;
if ph.c_bottom then
 if r_item_amplitude > 0 then
  begin
  ang := ang + 0.1;
  Z := trunc(sin(ang)*r_item_amplitude - r_item_amplitude);
  end
 else
  Z := 0;

if r_item_rotate then
 anim.Update
else
 anim.FrameIndex := 0;

with Map do
 for i := 0 to Players - 1 do
  if not Player[i].dead and
     RectIntersect(RectToMath(Player[i].fRect), RectToMath(rect)) then
   begin
   Take(Player[i]);
   break; // XProger: Ванька, ну ты даёшь, такие вещи забывать нельзя! ;)
   end;

if fstruct.livetimer = 0 then Kill;
end;

{ TShotObj }

constructor TShotObj.Create(struct_: TRealObjStruct);
begin
inherited;
if fstruct.UID = 0 then
 fstruct.UID := nextUID;
Plane := pFront;

fIgnoreEmpty    := true;
fstruct.objtype := otShot;
quad := Map.Quad(fstruct.playerUID);
damage:=quad*WPN_Damage[fstruct.ItemID];
if WeaponExists(weapon) then
 anim := TObjTex.Create(WeaponObjs[struct_.ItemID].SHOTanim);
fgraph_rect.Width  := 16;
fgraph_rect.Height := 16;
fgraph_rect.x      := -8;
fgraph_rect.y      := -8;
fNoDoorStop        := false; //останавливается дверью


tag:= plasma_collisions;
 case struct.ItemID of
  WPN_GRENADE:
   begin
   Width  := GRENADE_CLIP;
   Height := GRENADE_CLIP;
   end;
  WPN_ROCKET:
   begin
   Width  := ROCKET_CLIP;
   Height := ROCKET_CLIP;
   end;

  WPN_PLASMA:
   begin
   Width  := PLASMA_CLIP;
   Height := PLASMA_CLIP;
   end;

  else
   begin
   Width  := 0;
   Height := 0;
   end
 end;

// свет
Light := nil;
if r_weapon_light then
 case weapon of
  WPN_ROCKET :
   Light := TP_Light.Create(Point2f(fstruct.X, fstruct.Y), Point2f(48, 48), RGBA(255, 255, 0, 128), 1);
  WPN_BFG    :
   Light := TP_Light.Create(Point2f(fstruct.X, fstruct.Y), Point2f(48, 48), RGBA(3, 255, 3, 128), 1);
  WPN_PLASMA :
   Light := TP_Light.Create(Point2f(fstruct.X, fstruct.Y), Point2f(16, 16), RGBA(128, 128, 255, 128), 1);
 end;
if Light <> nil then
 Particle_Add(Light);
end;

procedure TShotObj.Draw;
begin
glColor4f(1, 1, 1, 1);
inherited;
end;

procedure TShotObj.Kill;
var
 push : single;
 n : TRealObj;
begin
	n := RealObj;
	while n <> nil do
 	begin
 		if n.fstruct.objtype = otDeadPlayer then
  			if (sqr(n.x-x)+sqr(n.y-y))<sqr(WPN_SPLASH[weapon] div 2) then
         begin
      	   TDeadPlayer(n).Hit(WPN_SPLASH[weapon] div 2);
            TDeadPlayer(n).push(x, y, WPN_PUSH[weapon]);
         end;
 		n := n.Next;
   end;

inherited;
//ищем рядом объект-ТРУП

if weapon in [WPN_ROCKET, WPN_BFG, WPN_PLASMA, WPN_GRENADE] then
 begin
 Map.pl_find(fstruct.playerUID, -1);
 if Map.pl_current <> nil then
  push := WPN_PUSH[weapon] * Map.pl_current.Quad
 else
  push := -1;
 if Explosion(trunc(X), trunc(Y), damage, weapon, fstruct.playerUID, push) > 0 then
  Stat_Hit(weapon, fstruct.playerUID);
 end else
    Map.ShootActivation(trunc(x), trunc(y), fstruct.angle, WPN_SPLASH[weapon], weaponobjs[weapon], damage);

if Light <> nil then
 Light.die := 0;
if not f_player then
 Particle_Add(TP_Mark.Create(Point2f(trunc(x), trunc(y)), weapon));
   if NET.Type_ = NT_SERVER then
      net_server.ShotObjKill(fstruct.UID, trunc(fstruct.x), trunc(fstruct.y));
   Map.Demo.RecShotObjKill(fstruct.UID, trunc(fstruct.x), trunc(fstruct.y));
end;

procedure TShotObj.OnPlayer(sender: TObject);
begin
with TPlayer(sender) do
 if UID <> fstruct.playerUID then
  begin
  if not (weapon in [WPN_ROCKET, WPN_GRENADE, WPN_BFG]) then
   begin
   	Stat_Hit(weapon, fstruct.playerUID);
   	HitPlayer(damage, UID, fstruct.playerUID, weapon);
      hit_weapon:=weapon;
	 	Particle_Blood(x, y);
   	Map.pl_find(fstruct.playerUID, -1);
   	if Map.pl_current <> nil then
    		Push(x, y, WPN_PUSH[weapon] * Quad);
   end;
   f_player := true;
   Self.Kill;
  end;
end;

procedure TShotObj.OnStop;
begin
   if struct.ItemID=WPN_PLASMA then
   begin
      if tag>0 then
      begin
         dec(tag);
         fstruct.dx := fstruct.dx/GRENADE_INERTX2;
         if fBlockLeft or
      	   fBlockRight then
      		   fstruct.dx:=-fstruct.dx;
		   if fBlockTop or
  			   fBlockBottom then
               fstruct.dy:=-fstruct.dy;
      end else Kill
   end else Kill;
end;

procedure TShotObj.Update;
begin
   inherited;
   if Light <> nil then
      Light.Pos := Point2f(fstruct.X, fstruct.Y);
   //проверка активации объектов
   Map.ActivatePoint(trunc(x), trunc(y), Self);
end;

{ TSimpleSprite }
(* // XProger: здесь был Тимурка! :P
constructor TSimpleSprite.Create(anim_: TObjTex; x, y: single; repeat_: boolean = false);
begin
   frepeat:=repeat_;
   fstruct.x:=x;
   fstruct.y:=y;
   fstruct.dx:=0;
   fstruct.dy:=0;
   fstruct.objtype:=otSprite;
   fdead:=false;
   anim:=TObjTex.Create(anim_);
   animate:=true;

   fstruct.livetimer:=anim.Wait*anim.FrameCount;

   width:=anim.CurFrame.Width;
   height:=anim.CurFrame.Height;
   fgraph_rect.Width:=Width;
   fgraph_rect.Height:=Height;
   fgraph_rect.x:=-Width div 2;
   fgraph_rect.y:=-Height div 2;
end;

procedure TSimpleSprite.Update;
begin
  inherited;
   if fstruct.livetimer=0 then Kill;
end;

{ TSpriteShot }
constructor TSpriteShot.Create(struct_: TRealObjStruct);
begin
   inherited;
   fstruct.objtype:=otShot;
   if WeaponExists(struct_.ItemID) then
   	anim:=TObjTex.Create(WeaponObjs[struct_.ItemID].Shotanim);
   case weapon of
   WPN_SHOTGUN:
   begin
   	fgraph_rect.Width:=12;
   	fgraph_rect.Height:=12;
   	fgraph_rect.x:=-6;
   	fgraph_rect.y:=-6;
      anim.Wait:=anim.Wait*3;
      anim.FWait:=anim.FWait*3;
   end
   else
   begin
   	fgraph_rect.Width:=8;
   	fgraph_rect.Height:=8;
   	fgraph_rect.x:=-4;
   	fgraph_rect.y:=-4;
   end;
   end;//case
   fstruct.livetimer:=anim.Wait*anim.FrameCount;
end;

procedure TSpriteShot.Update;
begin
  inherited;
   if fstruct.livetimer=0 then Kill;
end;

procedure TSpriteShot.Draw;
begin
if fstruct.ItemID in [WPN_SHOTGUN, WPN_MACHINEGUN] then
 begin
 xglAlphaBlend(2);
glColor4f(1, 1, 1, 1);
 inherited;
 xglAlphaBlend(1);
 end
else
begin
glColor4f(1, 1, 1, 1);
inherited;
end;
end;*)

{ TRailShot }

constructor TRailShot.Create(struct_: TRealObjStruct);
begin
inherited;
ticker := r_rail_trailtime;
timer  := r_rail_trailtime;
Plane  := pFront;
end;

procedure TRailShot.Draw;
const
 Size = 2;
var
 P      : TPoint2f;
 lx, ly : single;
 kx, ky : single;
 s      : single;
begin
if timer > r_rail_trailtime then
 timer := r_rail_trailtime;
if ticker > r_rail_trailtime then
 ticker := r_rail_trailtime;

xglTex_Enable(RailTypeFrame.Frame[tag]);
//xglTex_Enable(RailTypeFrame.Frame[r_rail_type]);
// Вот это нужно задавать при создании луча
//Color.R := r_rail_color_r;
//Color.G := r_rail_color_g;
//Color.B := r_rail_color_b;
// А это считается динамически
if r_rail_progressivealpha then
 Color.A := trunc(ticker/timer * 255)
else
 Color.A := 255;

//Draw arrow
with fstruct, Color do
 begin
 lx := x;// + 15 * cos(angle);
 ly := y;// + 15 * sin(angle);

 kx := dx - lx + x;
 ky := dy - ly + y;

 P := Point2f(dy, dx);
 P := Normalize2f(P);
 P.X := - P.X * r_rail_width;
 P.Y :=   P.Y * r_rail_width;
 s := sqrt(kx*kx + ky*ky)/(r_rail_width*2);
 // Рисуется в 2 полигона с интерполяцией альфы от 1 до 0
 // от центра лазера к его боковым краям...
 glBegin(GL_QUADS);
  glColor4ub(R, G, B, A);
  glTexCoord2f(0, 0); glVertex2f(lx - P.X,      ly - P.Y);
  glTexCoord2f(0, 1); glVertex2f(lx + P.X,      ly + P.Y);
  glTexCoord2f(s, 1); glVertex2f(lx + kx + P.X, ly + ky + P.Y);
  glTexCoord2f(s, 0); glVertex2f(lx + kx - P.X, ly + ky - P.Y);
 glEnd;
 end;
end;

procedure TRailShot.Update;
begin
Dec(ticker);
if ticker = 0 then
 fdead := true;
end;

{ TGrenadeShot }

constructor TGrenadeShot.Create(struct_: TRealObjStruct);
begin
   inherited;
   if fstruct.livetimer=0 then
   	fstruct.livetimer:=GRENADE_LIVETIME;
end;

procedure TGrenadeShot.OnStop;
var
   l, l0, ang, ang0: single;
begin
if fBlockAll then
 begin
 Kill;
 Exit;
 end;

fstruct.dx := fstruct.dx - fObj.dpos.x;
fstruct.dy := fstruct.dy - fObj.dpos.y;

l0 := sqrt(sqr(fstruct.dx)+sqr(fstruct.dy));
if l0 < 0.5 then Exit;

with WeaponObjs[WPN_GRENADE] do
 if FireSound2 <> nil then
  FIREsound2.Play(fstruct.x, fstruct.y);

l := sqrt(sqr(fobj.normal.x)+sqr(fobj.normal.y));

if signf(l) = 0 then
 begin
 fstruct.dx := fstruct.dx/GRENADE_INERTX2;
      if fBlockLeft or
      	fBlockRight then
      		fstruct.dx:=-fstruct.dx;
		if fBlockTop or
  			fBlockBottom then
            fstruct.dy:=-fstruct.dy;
   end else
   begin
      ang:=arccos(fobj.normal.x/l);
      if signf(fobj.normal.y)<0 then
         ang:=Pi*2-ang;
      if signf(l)>0 then
      begin
      	ang0:=arccos(fstruct.dx/l)+Pi;
         if signf(fstruct.dy)<0 then
         	ang0:=Pi*2-ang0;
      	ang0:=2*ang-ang0;
         l0:=l0*GRENADE_INERTX2;
         fstruct.dx:=cos(ang0)*l0;
         fstruct.dy:=sin(ang0)*l0;
      end;
   end;

   fstruct.dx:=fstruct.dx+fObj.dpos.x;
   fstruct.dy:=fstruct.dy+fObj.dpos.y;
end;

procedure TGrenadeShot.Update;
var
   l: single;
begin
if r_smoke then
 if fstruct.livetimer mod 5 = 0 then
  Particle_Add(TP_Smoke.Create(Point2f(fstruct.X, fstruct.Y)));

   //сначала гравитация
   fstruct.dy:=fstruct.dy+GRENADE_GRAVITY;
   if signf(fstruct.dy*sv_gravity)<0 then
   	fstruct.dy:=fstruct.dy/GRENADE_INERTY;
   fstruct.dx:=fstruct.dx/GRENADE_INERTX1;

   if fstruct.dy>5.0 then fstruct.dy:=5.0;
  inherited;
  //поворот гранаты
   l := sqr(fstruct.dx)+sqr(fstruct.dy);
   if l > 1 then l := 1;

   angle := angle + GRENADE_ROTATESPEED*l;

   //теперь проверка жизненного времени
   if fstruct.livetimer < 1 then
    Kill;
end;

{ TDeadPlayer }

constructor TDeadPlayer.Create(Player: TObject; pHealth: SmallInt);
begin
inherited Create(fstruct);
fplayer := player;
width   := 20;
height  := 16;
Z       := 0;
Health  := 30 + pHealth;
FillChar(fstruct, sizeof(fstruct), 0);
with TPlayer(Player) do
 begin
 Self.fstruct.playerUID := UID;
 Self.fstruct.objtype := otDeadPlayer;
 Self.fstruct.x  := pos.X;
 Self.fstruct.y  := pos.Y + 24 - height div 2;
 Self.fstruct.dx := dpos.X;
 Self.fstruct.dy := dpos.Y;
 Self.fstruct.orient := ord(left);
 self.Model := TModel.Create;
 with self.Model do
  begin
  Anim[ANIM_DIED].Width  := Model.Anim[ANIM_DIED].Width;
  Anim[ANIM_DIED].Height := Model.Anim[ANIM_DIED].Height;
  with Anim[ANIM_DIED], Model.Anim[ANIM_DIED].Body do
   begin
   Body.Tex   := Tex;
   Body.FWait := FWait;
   Body.Wait  := FWait;
   end;
  with Anim[ANIM_DIED], Model.Anim[ANIM_DIED].Mask do
   begin
   Mask.Tex   := Tex;
   Mask.FWait := FWait;
   Mask.Wait  := FWait;
   end;
  CurAnim    := ANIM_DIED;
  Died       := true;
  FrameIndex := 0;
  Color      := Model.Color;
  end;
 end;
                                  
livetimer  := r_dead_time * 50;
Plane      := pBack;
Update;
end;

constructor TDeadPlayer.Create(struct_: TRealObjStruct);
begin
Plane   := pBack;
fplayer := Map.PlayerByUID(fstruct.playerUID);
Create(fplayer, 0);
fstruct := struct_;
end;

procedure TDeadPlayer.Gibs;
var
 i: integer;
begin
// Типа разлетелся ;)
for i := 0 to 9 do
 Particle_Add(TP_Gibs.Create(Point2f(X + randomf*8 - 4, Y + randomf*8 - 4), i));
end;

procedure TDeadPlayer.Update;
begin
Model.NextFrame;
Model.Update;
inherited;

if livetimer > r_dead_time * 50 then
 livetimer := r_dead_time * 50;

if ((Health <= 0) or ph.squish) and (livetimer > 0) or Map.block_Lava_s(X, Y) then
 begin
 Gibs;
 livetimer := 0;
 end;

if (livetimer = 0) or (Health <= 0) then
 Kill
else
 if livetimer < 160 then
  with fstruct do
   incs(Z, 0.1)
 else
  if ph.squish then
   Kill;
 //KILL

end;

procedure TDeadPlayer.Draw;
begin
glColor4f(1, 1, 1, 1);
glPushMatrix;
glTranslate(x, y - 16 + Z, 0);
if odd(fstruct.orient) then
 glScalef(-1, 1, 1);
Model.Draw;
glPopMatrix;
end;

procedure TDeadPlayer.Push(x0, y0, s: single);
begin
   if x0<x then fstruct.dx:=fstruct.dx+s
   else if x0>x then fstruct.dx:=fstruct.dx-s;
end;

procedure TDeadPlayer.Hit(dmg: integer);
var
   i: integer;
begin
   health:=health-dmg;
   for i:=0 to dmg div 4 do
 		Particle_Add(TP_Blood.Create(Point2f(X + randomf*8 - 4, Y + randomf*8 - 4)));
end;

{ TDeathLine }

constructor TDeathLine.Create(struct_: TRealObjStruct; Owner: TObject);
begin
   struct_.objtype:=otSprite;
   inherited Create(struct_);
   fOwner:=Owner;
   damage:=0;
   maxlen:=65535.0;
   Plane := pFront;
end;

procedure TDeathLine.Draw;
const
 Size = 2;
var
 P : TPoint2f;
 k : integer;
begin
xglTex_Disable;
//Draw arrow
with fstruct, Color do
 begin
 P := Point2f(dy, dx);
 P := Normalize2f(P);
 P.X := - P.X * Size;
 P.Y :=   P.Y * Size;
 k := max(integer(A - random(128)), 0);
 // Рисуется в 2 полигона с интерполяцией альфы от 1 до 0
 // от центра лазера к его боковым краям...
 xglBegin(GL_QUADS);
  glColor4ub(R, G, B, k); glVertex2f(x,            y);
  glColor4ub(R, G, B, 0); glVertex2f(x + P.X,      y + P.Y);
                          glVertex2f(x + dx + P.X, y + dy + P.Y);
  glColor4ub(R, G, B, k); glVertex2f(x + dx,       y + dy);

                          glVertex2f(x,            y);
  glColor4ub(R, G, B, 0); glVertex2f(x - P.X,      y - P.Y);
                          glVertex2f(x + dx - P.X, y + dy - P.Y);
  glColor4ub(R, G, B, k); glVertex2f(x + dx,       y + dy);
 xglEnd;
 end;
end;

procedure TDeathLine.OnDamage(hplayer: TObject);
begin

end;

procedure TDeathLine.SetVector(x, y, angle: single);
begin
   fstruct.x:=x;
   fstruct.y:=y;
   fstruct.angle:=angle;
end;

procedure TDeathLine.Update;
var
   hplayer: TPlayer;
begin
   len := Map.TraceVector(fstruct.x, fstruct.y, fstruct.angle);

   with fstruct do
   	RealObj_TraceDeads(x, y, angle, len, damage);
  // if r_spark then
    if (len < maxlen) and (len > 5.0) then
     begin
     if r_laser_spark then
      Particle_Add(TP_Spark.Create(Point2f(x + fstruct.dx, y + fstruct.dy),
                                   Point2f(-cos(fstruct.angle), -sin(fstruct.angle))));
     if r_laser_patch then
      Particle_Add(TP_Light_2.Create(Point2f(x + fstruct.dx, y + fstruct.dy), Point2f(16, 16),
                                     Color, 1));
     end;

   if len > maxlen then len := maxlen;

   hplayer:=TPlayer(Map.TracePlayers(fstruct.x, fstruct.y, fstruct.angle, len, -1));
   fstruct.dx:=len*cos(angle);
   fstruct.dy:=len*sin(angle);

   if damage > 0 then
   begin
      if damageticker>1 then Dec(damageticker)
      else
      begin
         if hplayer<>nil then
         begin
				Particle_Blood(x+fstruct.dx, y+fstruct.dy);
				Particle_Add(TP_Smoke.Create(Point2f(x+fstruct.dx, y+fstruct.dy)));
            HitPlayer(damage, TPlayer(hplayer).UID, -1, 0);
            OnDamage(hplayer);
         end;
         damageticker:=damagewait;
      end;
   end;
end;

{ TShaftShot }

constructor TShaftShot.Create(struct_: TRealObjStruct);
begin
struct_.objtype := otSprite;
inherited;
WeaponObjs[WPN_SHAFT].FIREsound2.Play(X, Y);
snd    := WeaponObjs[WPN_SHAFT].FIREsound1.Play(X, Y);
anim   := TObjTex.Create(WeaponObjs[WPN_SHAFT].SHOTanim);
anim_s := 0;
Plane  := pFront;
if r_weapon_light and (r_maxparticles > Particle_Count) then
 Light := TP_Light.Create(Point2f(X, Y), Point2f(48, 48), RGBA(255, 255, 255, 64), 1);
end;

procedure TShaftShot.Draw;
begin
if anim <> nil then
 begin
 xglTex_Enable(anim.CurFrame);
 glColor4f(0.5, 1, 1, 1);
 glPushMatrix;
 glTranslatef(fstruct.x, fstruct.y, 0);
 glRotatef(angle * rad2deg, 0, 0, 1);
 glBegin(GL_QUADS);
  glTexCoord2f(0, ( - anim_s)/shaft_sizex); glVertex2f(0, -shaft_sizey div 2);
  glTexCoord2f(1, ( - anim_s)/shaft_sizex); glVertex2f(0, shaft_sizey div 2);
  glTexCoord2f(1, (len - anim_s)/shaft_sizex);          glVertex2f(len, shaft_sizey div 2);
  glTexCoord2f(0, (len - anim_s)/shaft_sizex);          glVertex2f(len, -shaft_sizey div 2);
 glEnd;
 xglTex_Disable;
 glPopMatrix;
 if Light <> nil then
  Light.Draw;
 end;
end;

procedure TShaftShot.Kill;
begin
//ДАРАГОЙ ПРОГЕР ОБЪЯСНИ ПОЧЕМУ ВОТ ЭТО РАБОТАТЬ НЕ БУДЕТ, ЗВУК ПРОДОЛЖАЕТ ПОВТОРЯТЬСЯ
//пока что звук loop=false, но когда исправишь - сделай его loop=true;
snd_Stop(snd);
fdead:=true;
if Light <> nil then
 begin
 Light.Free;
 Light := nil;
 end;
end;

procedure TShaftShot.SetVector(x, y, angle: single);
begin
fstruct.x     := x;
fstruct.y     := y;
fstruct.angle := angle;
end;

procedure TShaftShot.Update;
begin
with Map, fstruct do
 begin
 len := TraceVector(x, y, fstruct.angle);
 if len > SHAFT_LEN then
  len := SHAFT_LEN;
 hplayer := TracePlayers(x, y, angle, len, playerUID);
 ShootActivation(x, y, angle, len, WeaponObjs[weapon], WPN_DAMAGE[weapon]);
 dx := len*cos(angle);
 dy := len*sin(angle);
 snd_SetPos(snd, Point2f(X, Y));

 RealObj_TraceDeads(x, y, angle, len, WPN_DAMAGE[weapon]);

 if signf(len - SHAFT_LEN) < 0 then
  begin
  if (hplayer = nil) and cg_marks then
   Particle_Add(TP_Mark.Create(Point2f(x + dx, y + dy), WPN_SHAFT));
  if r_weapon_light then
   Particle_Add(TP_Light_2.Create(Point2f(x + dx, y + dy), Point2f(16, 16), RGBA(255, 255, 255, 64), 1));
  end;

 if light <> nil then
  begin
  Light.Pos.X := x;
  Light.Pos.Y := y;
  end;
 end;
anim_s := (anim_s + 3) mod 128;
end;

{ TRealObj2 }

constructor TRealObj2.Create;
begin
inherited;
FillChar(ph, sizeof(ph), 0);
ph.ground_dpos := @NullPoint;
end;

procedure TRealObj2.Update;
var
 pp : TPhysicParams;
begin
Map.phys_params(x, y, pp);
with fstruct, ph do
 begin
 if dx < pp.minspeed.X then dx := pp.minspeed.X;
 if dx > pp.maxspeed.X then dx := pp.maxspeed.X;
 if dy < pp.minspeed.Y then dy := pp.minspeed.Y;
 if dy > pp.maxspeed.Y then dy := pp.maxspeed.Y;
 if c_bottom then
  begin
 	dx := ground_dpos^.X;
 	dy := ground_dpos^.Y;
  end;
 x := x + dx;
 y := y + dy;
 pos  := Point2f(x, y);
 dpos := Point2f(dx, dy);
 x1   := -width div 2;
 x2   :=  width div 2;
 Vy1  := -height div 2;
 Vy2  :=  height div 2;
 Hy1  := -1;
 Hy2  :=  1;
 Map.phys_gravity(ph);
 Map.phys_cliptest(ph);
 Map.phys_friction(ph);
 x := round2(pos.x, C_ROUND);
 y := round2(pos.y, C_ROUND);
 dx := dpos.X;
 dy := dpos.Y;
 end;
inherited;
end;

{ TRocketObj }

constructor TRocketObj.Create(struct_: TRealObjStruct);
begin
inherited;
with fgraph_rect do
 begin
 X      := -16;
 Y      := -16;
 Width  := 32;
 Height := 32;
 end;
snd := WeaponObjs[WPN_ROCKET].FIREsound2.Play(X, Y);
end;

procedure TRocketObj.Update;
begin
with fstruct do
 begin
 if livetimer = 0 then
  livetimer := 1000;
 if r_smoke then
  if livetimer mod 2 = 0 then
   Particle_Add(TP_Smoke.Create(Point2f(x, y)));
 inherited;
 snd_SetPos(snd, Point2f(x, y));
 end;
end;

procedure TRocketObj.Kill;
begin
inherited;
snd_Stop(snd);
end;

{ TLightLine }

constructor TLightLine.Create(struct_: TRealObjStruct; Owner: TObject);
begin
   struct_.objtype:=otShot;
   inherited Create(struct_);
   fOwner:=Owner;
   maxlen:=65535.0;
   target:=65535;
   color:=clLightBlue;
   Plane := pFront;
end;

procedure TLightLine.Draw;
const
 Size = 2;
var
 P : TPoint2f;
 k : Byte;
begin
xglTex_Disable;
//Draw arrow
with fstruct, Color do
 begin
 P := Point2f(dy, dx);
 P := Normalize2f(P);
 P.X := - P.X * Size;
 P.Y :=   P.Y * Size;
 k := max(A - random(64), 0);
 glBegin(GL_QUADS);
  glColor4ub(R, G, B, k); glVertex2f(x,            y);
  glColor4ub(R, G, B, 0); glVertex2f(x + P.X,      y + P.Y);
                          glVertex2f(x + dx + P.X, y + dy + P.Y);
  glColor4ub(R, G, B, k); glVertex2f(x + dx,       y + dy);

                          glVertex2f(x,            y);
  glColor4ub(R, G, B, 0); glVertex2f(x - P.X,      y - P.Y);
                          glVertex2f(x + dx - P.X, y + dy - P.Y);
  glColor4ub(R, G, B, k); glVertex2f(x + dx,       y + dy);
 glEnd;
 end;
end;

procedure TLightLine.SetVector(x, y, angle: single);
begin
   fstruct.x:=x;
   fstruct.y:=y;
   fstruct.angle:=angle;
end;

procedure TLightLine.Update;
var
   hplayer: TPlayer;
   l: single;
begin
   len:=Map.TraceVector(fstruct.x, fstruct.y, fstruct.angle);
   if len>maxlen then len:=maxlen;
   l:=len;
   hplayer:=TPlayer(Map.TracePlayers(fstruct.x, fstruct.y, fstruct.angle, l, -1));
   fstruct.dx:=len*cos(angle);
   fstruct.dy:=len*sin(angle);
   if (hplayer<>nil) then
      Map.ActivateTarget(target);
end;

end.
