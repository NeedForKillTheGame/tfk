unit Player_Lib;

//При добавлении новых параметров которые влияют на ИГРОВОЙ процесс используете TPlayerStruct
//А в TPlayer ставьте property соотв. данному свойству ;)

{module version 1.0.3.6}

{$DEFINE NFKMODE}

interface

uses
 Windows, OpenGL,
 Engine_Reg,
 Type_Lib,
 Math_Lib,
 Graph_Lib,
 Func_Lib,
 Constants_Lib,
 Model_Lib,
 Real_Lib,
 Stat_Lib,
 MapObj_Lib,
 Binds_Lib,
 Particle_Lib,
 Phys_Lib,
 Mouse_Lib,
 NET_Lib,
 NET_Client_Lib;

const
   MAX_AIR       = 40; 	//в 1/5 секунды
   WATER_DMG     = 18; 	//сколько жизней отнимается
   WATER_DMGWAIT = 50;
   HASTE_SPEED   = 1.0;

   DEF_HEALTH = 125;
   DEF_ARMOR  = 0;
   DEF_STARTAMMO = 50;

   MIN_HEALTH = -30;
   DEMO_HEALTH_TIMER = false;
var
   Player_Jump5      : single = 1.0;
   Player_Jump       : single = 4.5;
   Player_DJump      : single = 6.0;
   Player_DJump_time : integer = 20;
   Player_run        : single = 0.35;
   Player_AmplitudeX : single = 1.0;
   Player_AmplitudeY : single = 0.3;
   Player_Omega      : integer = 10;
   Player_Extr       : integer= 20;
   Player_Jump_and_Crouch   : single = 0.0;
   Jump_plat2        : integer= 20;

   player_h_top      : integer = -18;
   player_h_bottom   : integer = 15;
   player_Acceleration: single = 0.33;
   player_weaponchange: integer = 15;

procedure phys_player_init;

type
 TKeySet = set of 0..7; //главное здесь - РАЗМЕР!!! - 1 байт :)

 TPlayerPhys = record
  pos_x, pos_y   : WORD;
  dpos_x, dpos_y : ShortInt;
  angle : WORD;
  Keys  : TKeySet;
  crouch, onground : boolean;
  omega, jump_stage: Byte;
  weapon : Byte;
 end;

 TPlayerStruct = record
   UID			: Byte;
   Pos    	: TPoint2f; //позиция
   dpos   	: TPoint2f; //скорость (БЫВШАЯ inertia) d- это дифференциал :)
   crouch		: boolean;
   left     : boolean;
   dead, balloon: boolean;
   fangle		: SmallInt;
   //переменные оружия и тикеры
   HTicker      : WORD;
   SwitchTicker : WORD;
   ReloadTicker : WORD;
   lastrail     : Byte;
   lastfrag     : Byte;
   Has_wpn, Ammo : TWpnArray;
   PowerUps      : TPowerUpArray;
   cur_weapon, cur_wpn, next_weapon: Byte;
   //здоровье и броня
   Health: SmallInt;
   Armor: SmallInt;
   Name, ModelName : str32;

   airticker: byte;
   team     : byte;
   railcolor: TRGB;
   railtype : byte;
   reserved: array [0..2] of byte;
  end;

(*** TPlayer ***)
 TPlayer = class
  private
              //здоровье и броня
    procedure SetArmor(const Value: SmallInt);
    procedure SetHealth(const Value: SmallInt);
    function GetMY: integer;
    function GetAngleChanged: boolean;
    function GetKeysChanged: boolean;
    function Get_byte_Health: byte;
    procedure Set_byte_Health(const Value: byte);
    function GetBalloon: boolean;
    procedure SetBalloon(const Value: boolean);
    procedure SetStruct(const Value: TPlayerStruct);
  protected
  //движение
    can_jump, can_fly: boolean;
    ph: TPhysRect;
    deltablock : boolean;
    maxspeedx: single;

    jump_stage, jumpticker: byte;
    jumping: boolean;
    prevangle: word;
    omega, lastextremum: byte;

    function GetOmegaValue: single;
  public
    w_level: integer;
    in_water: boolean;//игрок упал в воду - или наоборот выбрался...
    onground, stayground: boolean; //первое- то что игрок на площадке.

  private
    procedure CalcRect;
    procedure CalcWaterLevel;
    function CheckOnGround: boolean;
    function CheckOnGround2: boolean; //PQR
  public
    procedure NetMove;
    procedure NeoMove;
    procedure DemoMove;
    procedure FindGround(delta, deep: integer);
  public
    client: TClient;
    current_ping: word;
    lasthitid: word;
    fireticker: byte;

    netbuf: array [0..5] of TPlayerPhys;
    net_recv: boolean;
    net_moved: integer;

  //сетевые функции

    function IsNET: boolean;
    function IsClient: boolean;
    procedure Setpos(rec: TPlayerPhys); overload;
    procedure Setpos(rec: TPlayerPhys; ticks: integer); overload;
    procedure Getpos(var rec: TPlayerPhys);
 	public
    function Get_word_pos_x: word;
    function Get_word_pos_y: word;
    procedure Set_word_pos_x(value: word);
    procedure Set_word_pos_y(value: word);
    function Get_short_dpos_x: shortint;
    function Get_short_dpos_y: shortint;
    procedure Set_short_dpos_x(value: shortint);
    procedure Set_short_dpos_y(value: shortint);

    property byte_Health: byte read Get_byte_Health write Set_byte_Health;

    property word_pos_x: word read Get_word_pos_x write Set_word_pos_x;
    property word_pos_y: word read Get_word_pos_y write Set_word_pos_y;
    property short_dpos_x: shortint read Get_short_dpos_x write Set_short_dpos_x;
    property short_dpos_y: shortint read Get_short_dpos_y write Set_short_dpos_y;
  protected
  //секция для демок
   //ДЛЯ ДЕМКИ
    lastwpn: byte;
    lastkeys: TKeySet;
    lastangle: smallint;
    fstruct: TPlayerStruct;
    fhited: boolean;
    function GetKeys: TKeySet;
    procedure SetKeys(value: TKeySet);
    function GetMoved: boolean;
    function GetWPNChanged: boolean;
  public
	 fmoved: boolean;
    fSquished: boolean;
    property Moved: boolean read GetMoved write fmoved;
    property WPNChanged: boolean read GetWPNChanged;
    property AngleChanged: boolean read GetAngleChanged;
    property KeysChanged: boolean read GetKeysChanged;
    property pstruct: TPlayerStruct read fStruct write SetStruct;
    property Keys: TKeySet read GetKeys write SetKeys;
    property Squished: boolean read fSquished;
    function HealthChanged: boolean;
  public
  //gauntlet
   	gauntlet: TParticle;
   	gauntletsnd: integer;//звук гаунтлета.
    	procedure GauntletON;
    	procedure GauntletOFF;
  public
     AI: TObject;
     dead_mode: boolean;
  public

   Stat   : PPlayerStat;            //СТАТИСТИКА
   Key    : TKeyArray; //LKey - старые клавиши
   UseMouse: boolean;
   playertype, localtype: byte;

   fRect: TRect; //РЕКТ ИГРОКА - ОБНОВЛЯЕТСЯ В UPDATE!!!

   quadtimer   : integer;  //Время проигрывания звука!!!
   regentimer	: integer;  //Тикер регенерации
   hastetimer  : integer;  //хихи, а это у нас ДЫМОК :)
   fly_snd		: integer;

   // для отрисовки наград
   rewards_ticker : array [0..2] of integer;

   //ждёт ли игрок респауна
   resp		: boolean;
   respindex	: word;

  //XProger: текущий кадр анимации пушки, и время до следующего (в тиках)
   weapon_frame, weapon_frame_wait : integer; //Neoff: может лучше TObjTex.Update?
   weapon_fire : boolean;

   //Neoff: ШЛЕЙФ ШАФТА!!! nil - значит сейчас не стреляем
   shaft       : TShaftShot;
///////

   Model : TModel; // тут должем быть конТейтер какой-нить... типа TBaseModel
   lasthit  : integer; // Время до хит саунда

//тикер СМЕРТИ - сколько игрок выляется без сознания...
   deadticker: word;
//тикер ЖИЗНИ - с каких пор игрок жив  :)
   liveticker: word;

   fshot: boolean; //должен ли игрок стрелять после этого тика

//последняя смена оружия...
   lastwpnchange: byte;

   //плавный угол
   sangle: single;

   //текущая позиция стрельбы
   shotpos : TPoint2f;
   //КТО ПОСЛЕДНИЙ попал в игрока
   hit_UID    : integer;
   hit_weapon : integer;

   procedure SetLeft(Value: boolean);
//идентификатор
   property UID : byte read fstruct.uid;
//команда
   property team: byte read fstruct.team write fstruct.team;
//позиция
   property Pos: TPoint2f read fstruct.Pos write fstruct.Pos;
//скорость
   property dPos: TPoint2f read fstruct.dPos write fstruct.dPos;
//повернут налево?
   property left: boolean read fstruct.left write SetLeft;
//смерть?
   property dead: boolean read fstruct.dead write fstruct.dead;
//сидит?
   property Crouch : boolean read fstruct.Crouch write fstruct.Crouch;
//а теперь оружие
   property Has_wpn: TWPNArray read fstruct.Has_wpn write fstruct.Has_wpn;
   property Ammo: TWpnArray read fstruct.Ammo write fstruct.Ammo;
   property PowerUps: TPowerUpArray read fstruct.powerups write fstruct.powerups;
   property cur_weapon : byte read fstruct.cur_weapon write fstruct.cur_weapon;
   property cur_wpn : byte read fstruct.cur_wpn write fstruct.cur_wpn;
   property next_weapon: byte read fstruct.next_weapon write fstruct.next_weapon;
//тикер здоровья и брони
   property HTicker: word read fstruct.HTicker write fstruct.HTicker;
//тикер смены оружия на следующее - down, по-умолчанию MAX!!!
   property SwitchTicker: word read fstruct.SwitchTicker write fstruct.SwitchTicker;
//тикер перезарядки - down, по-умолчанию 0
   property ReloadTicker: word read fstruct.ReloadTicker write fstruct.ReloadTicker;
//количество попаданий из рельсы
   property lastrail: byte read fstruct.lastrail write fstruct.lastrail;
//сколько времени назад был выбит фраг. -1 = фрага не было
   property lastfrag: byte read fstruct.lastfrag write fstruct.lastfrag;
//ЗДАРОВЬЕ!!F!
   function GetHealth: smallint;
   function GetArmor: smallint;

   property Health       : SmallInt read GetHealth write SetHealth;
   property Armor        : SmallInt read GetArmor write SetArmor;

   function GetAngle: single;
   procedure SetAngle(value: single);
   function GetAbsAngle: single;
   procedure SetAbsAngle(value: single);

   property Angle: single read GetAngle write SetAngle;
   property AbsAngle: single read GetAbsAngle write SetAbsAngle;

   property fAngle: smallint read fstruct.fAngle write fstruct.fAngle;

   property Name      : str32 read fstruct.Name write fstruct.Name;
   property ModelName : str32 read fstruct.ModelName write fstruct.ModelName;
   property railcolor : TRGB read fstruct.railcolor write fstruct.railcolor;
   property railtype  : byte read fstruct.railtype write fstruct.railtype;

   property balloon: boolean read GetBalloon write SetBalloon;

// rasprigka
   property AirTicker: byte read fstruct.AirTicker write fstruct.AirTicker;

   constructor Create(ptype: integer; uid: byte; team_: byte =0);
   destructor Destroy; override;

   procedure Restart;//РЕСТАРТ ПЛЭЙЕРА!!!

   function LoadFromFile(const ModelName: string): boolean;

   function GetCurPrevWeapon: word;//ПРЕДЫДУЩЕЕ после данного оружие
   function GetCurNextWeapon: word;//СЛЕДУЮЩИЕ оружие

   procedure SetWeapon(value: byte);

   procedure MoveTo(x0, y0: word);
   procedure MoveBy(dx0, dy0: smallint);
   function TakeHealth(health_: word): boolean;
   function TakeArmor(armor_: word): boolean;
   function TakeWpn(wpnID, count: word; mode: byte): boolean;
   function TakeAmmo(wpnID, count: word): boolean;
   function TakePowerUp(itemID, count: word): boolean;

   //функция будет вызываться только ИЗ weapon_lib. НЕПОСРЕДСТВЕННЫЙ ВЫЗОВ
   //ТОЛЬКО ЕСЛИ УРОН ПРИЧИНЕН СВЕРХЪЕСТЕСТВЕННЫМ СПОСОБОМ. - Neo...
   //ВСПОМНИЛ!!! ШАФТ ЭТО ИСПОЛЬЗУЕТ!!!
   function Hit(damage, playerUID: integer): integer;
   function HitWater(damage, playerUID: integer): integer;
   procedure Push0(sx, sy: single);
   procedure Push(x0, y0, s: single);
   procedure Push2(x0, y0, s: single);

   procedure RotateX;
   procedure RotateY;
   //Хехе, прощай игрок...
   procedure Kill;
   procedure SquishKill;
   procedure Reset;

   procedure PrevUpdate;
   procedure Update; //обновление
   procedure UpdateMove;

   procedure UpdateShot;
   procedure UpdateTickers;
   procedure Draw; //отрисовка
   procedure DrawCrosshair;

   property MY: integer read GetMY;

   function Fly: boolean;
   function Quad: integer;

public
 end;

function IncMax(var x: single; dx, max: single): boolean;
function IncMin(var x: single; dx, min: single): boolean;

function GetShotY(crouch: boolean): integer;

implementation

uses
 Map_Lib, TFK, ItemObj_Lib, ObjSound_Lib,
 Weapon_Lib, TFKBot_Lib, Log_Lib, Menu_Lib, SysUtils_;

procedure phys_player_init;
var
   i: byte;
begin
   phys_register('player_deltaspeed', @player_jump5, VT_FLOAT);
   phys_register('player_jump', @player_jump, VT_FLOAT);
   phys_register('player_jump_and_crouch', @player_jump_and_crouch, VT_FLOAT);
   phys_register('player_doublejump', @player_DJump, VT_FLOAT);
   phys_register('player_doublejump_time', @player_DJump_time, VT_INTEGER);
   phys_register('player_run', @player_run, VT_FLOAT);
   phys_register('player_frequency', @player_extr, VT_INTEGER);
   phys_register('player_speedjump_x', @Player_AmplitudeX, VT_FLOAT);
   phys_register('player_speedjump_y', @Player_AmplitudeY, VT_FLOAT);
   phys_register('player_h_bottom', @Player_h_bottom, VT_INTEGER);
   phys_register('player_h_top', @Player_h_top, VT_INTEGER);
   for i:=0 to WPN_Count-1 do
      phys_register('reload_'+WPN_NAMES[i], @Reload_Wait[i], VT_WORD);
   phys_register('player_acceleration', @Player_acceleration, VT_FLOAT);
   phys_register('player_weaponchange', @Player_weaponchange, VT_INTEGER);
end;

function IncMax(var x: single; dx, max: single): boolean;
begin
Result := false;
if signf(x - max) < 0 then
 begin
 x := x + dx;
 if signf(x - max)>0 then
  x := max;
 end;
end;

function IncMin(var x: single; dx, min: single): boolean;
begin
Result := false;
if signf(x - min) > 0 then
 begin
 x := x + dx;
 if signf(x - min) < 0 then
  x := min;
 end;
end;

function GetShotY(crouch: boolean): integer;
const
 stay = -8;
 sit  =  0;
begin
if crouch then
 Result := sit
else
 Result := stay;
end;

/////////////////////////
// TPlayer
/////////////////////////

{ TPlayer }

function TPlayer.Get_word_pos_x: WORD;
begin
with fstruct.Pos do
 if X < 0 then
  Result := 0
 else
  Result := round(X * C_ROUND);
end;

function TPlayer.Get_word_pos_y: WORD;
begin
with fstruct.Pos do
 if Y < 0 then
  Result := 0
 else
  Result := round(Y * C_ROUND);
end;

procedure TPlayer.Set_word_pos_x(value: WORD);
begin
fstruct.Pos.X := value/C_ROUND;
end;

procedure TPlayer.Set_word_pos_y(value: WORD);
begin
fstruct.Pos.Y := value/C_ROUND;
end;

// Следующие 2 функции немного разгружают код...
function Short_Getdpos(x: single): ShortInt;
var
 r: integer;
begin
r := round(x * S_ROUND);
if r > 64 then
 r := r div 2 + 32
else
 if r <  -64 then
  r := -(abs(r) div 2) - 32;

if r > 127  then r :=  127;
if r < -128 then r := -128;
Result := r;
end;

function Short_Setdpos(value: ShortInt): single;
begin
if value > 64 then
 Result := (value * 2 - 64)/S_ROUND
else
 if value < -64 then
  Result := (value * 2 + 64)/S_ROUND
 else
  Result := value/S_ROUND;
end;

function TPlayer.Get_short_dpos_x: shortint;
begin
Result := Short_Getdpos(fstruct.dpos.X);
end;

function TPlayer.Get_short_dpos_y: shortint;
begin
Result := Short_Getdpos(fstruct.dpos.Y);
end;

procedure TPlayer.Set_short_dpos_x(value: ShortInt);
begin
fstruct.dpos.X := Short_Setdpos(value);
end;

procedure TPlayer.Set_short_dpos_y(value: shortint);
begin
	fstruct.dpos.Y := Short_Setdpos(value);
end;

function TPlayer.Get_byte_Health: byte;
begin
   if fstruct.health<MIN_HEALTH then
   	Result:=0
   else Result:=fstruct.health-MIN_HEALTH;
end;

procedure TPlayer.Set_byte_Health(const Value: byte);
begin
   fstruct.health:=smallint(value)+MIN_HEALTH;
end;

procedure TPlayer.Getpos(var rec: TPlayerPhys);
begin
with fstruct do
 begin
 rec.pos_x  := word_pos_x;
 rec.pos_y  := word_pos_y;
 rec.dpos_x := short_dpos_x;
 rec.dpos_y := short_dpos_y;
 rec.angle  := fangle;
 rec.omega  := omega;
 if jump_stage<8 then
   rec.jump_stage:=jump_stage
 else rec.jump_stage:=7;
 rec.keys   := Keys;
 if crouch then
  rec.Keys := rec.Keys + [KEY_DOWN];
 if (cur_weapon<>next_weapon) and not (cur_weapon in [WPN_SHAFT, WPN_GAUNTLET]) then
   rec.Keys := rec.Keys - [KEY_FIRE];
 rec.onground := onground;
 rec.crouch   := crouch;
 rec.weapon   := cur_weapon;
 end;
end;

procedure TPlayer.Setpos(rec: TPlayerPhys);
begin
with fstruct do
 begin
 AbsAngle     := rec.angle;
 omega        := rec.omega;
 Keys         := rec.Keys;
 crouch       := rec.crouch;
 if (rec.pos_x<>0) or
    (rec.pos_y<>0) or
    (rec.dpos_x<>0) or
    (rec.dpos_y<>0) then
    begin
 word_pos_x   := rec.pos_x;
 word_pos_y   := rec.pos_y;
 short_dpos_x := rec.dpos_x;
 short_dpos_y := rec.dpos_y;
 jump_stage:=rec.jump_stage;
 SetWeapon(rec.weapon);
   end;
 end;
end;

procedure TPlayer.Setpos(rec: TPlayerPhys; ticks: integer);
var
  j      : integer;
  dx, dy : single;
begin
SetPos(rec);
if rec.onground then
 FindGround(3, 4);
GetPos(rec);

if ticks = 0 then
 begin
 SetPos(netbuf[0]);
//      dx:=(pos.x-rec.pos_x/C_ROUND)*0.2;
//      dy:=(pos.y-rec.pos_y/C_ROUND)*0.2;
 dx := 0;
 dy := 0;
 SetPos(rec);
 with fstruct.Pos do
  begin
  X := X + dx;
  Y := Y + dy;
  end;
 GetPos(netbuf[0]);
 Exit;
 end;

netbuf[ticks] := rec;

if ticks > 0 then
 begin
 SetPos(netbuf[0]);
 j := 0;
 while j < ticks do
  begin
  NeoMove;
  inc(j);
  end;
 dx := (rec.pos_x/C_ROUND - Pos.X)/ticks;
 dy := (rec.pos_y/C_ROUND - pos.Y)/ticks;

 SetPos(netbuf[0]);
 j := 1;
 while j < ticks do
  begin
  NeoMove;
  with fstruct.Pos do
   begin
   X := X + dx;
   Y := Y + dy;
   end;
  GetPos(netbuf[j]);
  inc(j);
  end;
 end;
end;

//функции для демок
function TPlayer.GetKeys: TKeySet;
var
 b : byte;
begin
Result := [];
for b := 0 to 7 do
 if Key[b].Down then
  Result := Result + [b];
if not dead and (next_weapon <> cur_weapon) then
 Result := Result - [KEY_FIRE];
end;

procedure TPlayer.SetKeys(value: TKeySet);
var
 b : byte;
begin
for b := 0 to 7 do
 Key[b].Down := b in value;
end;

function TPlayer.GetMoved: boolean;
begin
Result := fmoved;
fmoved := false;
end;

function TPlayer.GetWPNChanged: boolean;
begin
Result  := lastwpn <> cur_weapon;
lastwpn := cur_weapon;
end;

function TPlayer.HealthChanged: boolean;
begin
Result := fhited;
fhited := false;
end;

function TPlayer.GetAngleChanged: boolean;
begin
Result    := lastangle <> fangle;
lastangle := fangle;
end;

function TPlayer.GetKeysChanged: boolean;
begin
Result := ((KEY_LEFT in Keys)  <> (KEY_LEFT in lastkeys)) or
          ((KEY_RIGHT in Keys) <> (KEY_RIGHT in lastkeys)) or
          ((KEY_UP in Keys)    <> (KEY_UP in lastkeys)) or
          ((KEY_DOWN in Keys)  <> (KEY_DOWN in lastkeys)) or
          ((KEY_BALLOON in Keys) <> (KEY_BALLOON in lastkeys));
lastkeys := Keys;
end;

//обычные функции

constructor TPlayer.Create(ptype: integer; uid: byte; team_: byte);
begin
Self.playertype:=ptype;

if ptype=C_PLAYER_P1 then
begin
   railcolor:=r_rail_color;
   railtype:=r_rail_type;
end
else if ptype=C_PLAYER_P2 then
begin
   railcolor:=r_p2_rail_color;
   railtype:=r_p2_rail_type;
end
else
begin
   railcolor:=r_enemy_rail_color;
   railtype:=r_enemy_rail_type;
end;

fstruct.uid:=uid;
team:=team_;

if ptype and C_PLAYER_TFKBOT > 0 then
 begin
// AI := TTFKBot.Create;
   AI:=TAlienShaftBot.Create;

 TTFKBot(AI).pl	:= Self;
 end
else
 AI := nil;
Model := TModel.Create;
lasthitid:=0;

current_ping:=0;

rewards_ticker[0] := 0;
rewards_ticker[1] := 0;
rewards_ticker[2] := 0;
end;

destructor TPlayer.Destroy;
begin
if shaft <> nil then
 shaft.Kill;
gauntletOFF;
Model.Free;
end;

function TPlayer.LoadFromFile(const ModelName: string): boolean;
begin
// НУ ОЧЕНЬ кривая загрузка...
//Neo: а по-моему нормальная. Как бы все в exception переделать...
// XProger: немного поизвращался - должно работать...
Result := Model.LoadFromFile(ModelName);
if Result then
 fstruct.ModelName := ModelName
else
 if not Model.LoadFromFile(fstruct.ModelName) then
  begin
  Model.LoadFromFile('sarge+default');
  fstruct.ModelName := 'sarge+default';
  end;
end;

//ФИЗИКА
procedure TPlayer.CalcRect;
begin
with ph do
 if crouch then
	fRect := Rect(trunc(pos.X - 8), trunc(pos.Y - 8), 16, 32)
 else
  fRect := Rect(trunc(pos.X - 9), trunc(pos.Y - 24), 18, 48);
end;

function TPlayer.CheckOnGround: boolean;
begin
with Map, ph do
 onground := ( (block_Dot_Product(Pos.X - 9, pos.Y + 25, 0, -4, jump_plat2 div 4) = 2) or
      			 (block_Dot_Product(Pos.X - 5, pos.Y + 25, 0, -4, jump_plat2 div 4) = 2) or
             (block_Dot_Product(Pos.X + 5, pos.Y + 25, 0, -4, jump_plat2 div 4) = 2) or
      			 (block_Dot_Product(Pos.X + 9, pos.Y + 25, 0, -4, jump_plat2 div 4) = 2) );
Result := onground;
end;

//PQR
function TPlayer.CheckOnGround2: boolean;
begin
with Map, ph do
 onground := (block_Dot_Product(Pos.X - 9 + dPos.X, pos.Y + 25, 0, -4, jump_plat2 div 4) = 2) or
      			 (block_Dot_Product(Pos.X - 5 + dPos.X, pos.Y + 25, 0, -4, jump_plat2 div 4) = 2) or
             (block_Dot_Product(Pos.X + 5 + dPos.X, pos.Y + 25, 0, -4, jump_plat2 div 4) = 2) or
      			 (block_Dot_Product(Pos.X + 9 + dPos.X, pos.Y + 25, 0, -4, jump_plat2 div 4) = 2);
Result := onground;
end;

procedure TPlayer.CalcWaterLevel;
begin
with Map, ph do
 w_level := Byte(block_Water_s(Pos.X, Pos.Y + 18))+
            Byte(block_Water_s(Pos.X, Pos.Y + 7)) +
            Byte(block_Water_s(Pos.X, Pos.Y + 4)) +
            Byte(block_Water_s(Pos.X, Pos.Y - 7)) +
            Byte(block_Water_s(Pos.X, Pos.Y));
end;

procedure TPlayer.NetMove;
begin
   if not net_recv then
      NeoMove
   else
   begin
      ph.dpos := dpos;
      ph.pos  := pos;
      net_recv:= false;
      CheckOnGround;
      crouch := KEY[KEY_DOWN].Down and onground;
      CalcRect;
   end;
   Move(netbuf[low(netbuf)], netbuf[low(netbuf)+1], sizeof(netbuf)-sizeof(Tplayerphys));
   GetPos(netbuf[0]);
end;

procedure TPlayer.FindGround(delta, deep: integer);
var
 i : integer;
begin
ph.pos  := pos;
ph.dpos := dpos;
CheckOnGround;
for i := 1 to deep do
 begin
 if onground then
  break;
 ph.pos.Y := ph.pos.Y + delta;
 CheckOnGround;
 end;

if onground then
 begin
 with ph do
	if crouch then
	 begin
	 x1  := -8; x2  := 8;
   Vy1 := -8; Vy2 := 24;
   Hy1 := -2; Hy2 := 15;
	 end
  else
	 begin
	 x1  := -8;  x2  := 8;
   Vy1 := -24; Vy2 := 24;
   Hy1 := player_h_top;
   Hy2 := player_h_bottom;
	 end;
 Map.phys_cliptest(ph);
 pos  := ph.pos;
 dpos := ph.dpos;
 end;
end;

procedure TPlayer.DemoMove;

   function BrickOnHead: boolean;//head.
	begin
      with Map, ph do
      	Result:=(block_Dot_Product(Pos.X-8, pos.Y-26, 0, 2, 4) = 2) or
                 (block_Dot_Product(Pos.X-4, pos.Y-26, 0, 2, 4) = 2) or
                 (block_Dot_Product(Pos.X+4, pos.Y-26, 0, 2, 4) = 2) or
                 (block_Dot_Product(Pos.X+8, pos.Y-26, 0, 2, 4) = 2);
	end;

   function BrickOnHead2: boolean;//head.
	begin
      with Map, ph do
      	Result:=(block_Dot_Product(Pos.X-4, pos.Y-26, 0, 2, 4) = 2) or
                 (block_Dot_Product(Pos.X+4, pos.Y-26, 0, 2, 4) = 2);
	end;

   function BrickCrouchOnHead: boolean;
	begin
      with Map, ph do
      	Result:=(block_Dot_Product(Pos.X-8, pos.Y-22, 0, 2, 4) <> 1) or
                 (block_Dot_Product(Pos.X-4, pos.Y-22, 0, 2, 4) <> 1) or
                 (block_Dot_Product(Pos.X+4, pos.Y-22, 0, 2, 4) <> 1) or
                 (block_Dot_Product(Pos.X+8, pos.Y-22, 0, 2, 4) <> 1);
	end;

   function CheckJumping: boolean;
   begin
   can_jump := (CheckOnGround or CheckOnGround2) and
               (not BrickCrouchOnHead and not BrickOnHead or deltablock and not crouch and
               not BrickOnHead2);
   Result := can_jump;
  end;

begin
ph.pos := pos;
CalcWaterLevel;
CheckOnGround;
crouch := KEY[KEY_DOWN].Down and onground;
CalcRect;
CheckJumping;

//имитация прыжка на демке...
if can_jump and KEY[KEY_UP].Down and not phys_flag then
begin
   jumping:=true;
   if not brickonhead and
      (jumpticker>=8) then
      Model.Sound.Jump.Play(Pos.X, Pos.Y);
   jumpticker:=0;
end;

end;

procedure TPlayer.NeoMove;
   function BrickOnHead: boolean;//head.
	begin
      with Map, ph do
      	Result:=(block_Dot_Product(Pos.X-8, pos.Y-26, 0, 2, 4) = 2) or
                 (block_Dot_Product(Pos.X-4, pos.Y-26, 0, 2, 4) = 2) or
                 (block_Dot_Product(Pos.X+4, pos.Y-26, 0, 2, 4) = 2) or
                 (block_Dot_Product(Pos.X+8, pos.Y-26, 0, 2, 4) = 2);
	end;

   function BrickOnHead2: boolean;//head.
	begin
      with Map, ph do
      	Result:=(block_Dot_Product(Pos.X-4, pos.Y-26, 0, 2, 4) = 2) or
                 (block_Dot_Product(Pos.X+4, pos.Y-26, 0, 2, 4) = 2);
	end;

   function BrickCrouchOnHead: boolean;
	begin
      with Map, ph do
      	Result:=(block_Dot_Product(Pos.X-8, pos.Y-22, 0, 2, 4) <> 1) or
                 (block_Dot_Product(Pos.X-4, pos.Y-22, 0, 2, 4) <> 1) or
                 (block_Dot_Product(Pos.X+4, pos.Y-22, 0, 2, 4) <> 1) or
                 (block_Dot_Product(Pos.X+8, pos.Y-22, 0, 2, 4) <> 1);
	end;

   //функция проверки воды:
   //на сколько игрок погружён:
   //0 - вообще не погружён.
   //1 - до трети
   //2 - до трёх восьмых
   //3 - до половины
   //4 - до двух третей
   //5 - больше
   //WATER_LEVEL перенесён непосредственно в класс

var
   lastpos: TPoint2f;
   pp: TPhysicParams;

  function CheckJumping: boolean;
  begin
  can_jump := (CheckOnGround or CheckOnGround2) and
              (not BrickCrouchOnHead and not BrickOnHead or deltablock and not crouch and
              not BrickOnHead2);
  Result := can_jump;
  end;

  function CheckFly: boolean;
  begin
  // XProger: хыхыхы :)
  can_fly := {not BrickCrouchOnHead and not BrickOnHead and} (fly or pp.flight);
  Result  := can_fly;
  end;

begin
ph.dpos := dpos;
ph.pos  := pos;
with fstruct, ph do
 begin
 CalcWaterLevel;
 Map.phys_gravity(ph);
 Map.phys_params(pos.x, pos.y, pp);

 if dpos.x < pp.minspeed.X then dpos.X := pp.minspeed.X;
 if dpos.x > pp.maxspeed.X then dpos.X := pp.maxspeed.X;
 if dpos.y < pp.minspeed.Y then dpos.Y := pp.minspeed.Y;
 if dpos.y > pp.maxspeed.Y then dpos.Y := pp.maxspeed.Y;

 //продолжаем стоять на ногах ;)
 //если игрок раньше стоял на площадке неподвижно, а площадка изменила скорость, то
 //игрок должен тоже поменять скорость! также идёт синхронизация вещественной части, ground_float.X,
 //для бриков она равна 0.


 if onground and stayground and not IsNET and not phys_flag then
  begin
	pos.X := int(pos.x) + ground_float.X;
  if abs(frac(pos.X) - ground_float.X) < 0.5 then
 	 pos.X := int(pos.x) + ground_float.X
  else
   if signf(frac(pos.X) - ground_float.X) > 0 then
    pos.X := int(pos.x) + ground_float.X + 1
   else
    pos.X := int(pos.X) + ground_float.X - 1;
  dpos.X := ground_dpos.X;
  end;

 lastpos := Pos;
 Pos.X := Pos.X + dpos.X/phys_freq;
 Pos.Y := Pos.Y + dpos.Y/phys_freq;

 CheckJumping;

 deltablock := abs(dpos.x) > Player_Jump5;
 if KEY[KEY_DOWN].Down and onground and deltablock or
    onground and BrickCrouchOnHead then
  crouch := true;

 if not dead then
  if crouch then
   begin
   x1  := -10;
   x2  :=  10;
   Vy1 :=  -8;
   Vy2 :=  24;
   Hy1 :=  -2;
   Hy2 :=  16;
	 end
  else
	 begin
   x1  := -10;
   x2  :=  10;
   Vy1 := -24;
   Vy2 :=  24;
   Hy1 := player_h_top;
   Hy2 := player_h_bottom;
	 end
 else
  begin
   x1  := -10;
   x2  :=  10;
   Vy1 :=  10;
   Vy2 :=  24;
   Hy1 :=  12;
   Hy2 :=  16;
  end;

 CalcRect;

 Map.phys_cliptest(ph);
 CalcRect;

 if (ph.c_bottom or onground) and (Self.dPos.Y>falling_damage_speed) then
    weapon_lib.HitPlayerP( round( (-falling_damage_speed+Self.dpos.Y) * falling_damage+falling_damage_base), Self, nil, WPN_GAUNTLET );

 if (Key[KEY_LEFT].Down = Key[KEY_RIGHT].Down) or
    onground and (signf(abs(dpos.x-ground_dpos.x)-maxspeedx)>0) then
  Map.phys_friction(ph);

 CalcRect;

 if ph.squish and not dead then
  	if not IsClient then
      SquishKill;

 //поздняя проверка возможности прыжка :)
 if not deltablock then
  CheckJumping;
 CheckFly;


 stayground := onground and (signf(ground_dpos.X - dpos.X)=0);
 //цепление за брики!!! Если игрок оказался стоящим на земле - надо зацепиться!
 if onground and (stayground or not Key[KEY_UP].Down) then
  dpos.Y := ground_dpos.Y;

 //сначала flight:
 if can_fly and (KEY[KEY_UP].Down) then
  begin
  dpos.Y := -2;
  if fly then
   if fly_snd < 0 then
    fly_snd := PowerUpObjs[FLIGHT_ID].sound3.Play(Pos.X, Pos.Y)
   else
    snd_SetPos(fly_snd, Point2f(Pos.X, Pos.Y));
  end
 else
  begin
  if fly_snd >= 0 then
   begin
   snd_Stop(fly_snd);
   fly_snd := -1;
   end;
   //прыжок
  if can_jump and KEY[KEY_UP].Down and not phys_flag then
   begin
      jumping:=true;//даём попытку для jump_and_crouch

   if (jumpticker>=8) and (jumpticker<=Player_DJump_time) then
		dpos.Y := -(Player_DJump + Player_AmplitudeY * GetOmegaValue)
   else
    dpos.Y := -(Player_Jump + Player_AmplitudeY * GetOmegaValue);
   ph.dpos.X:=Self.dpos.X;
   if not brickonhead and
      (jumpticker>=8) then
    begin
      Model.Sound.Jump.Play(Pos.X, Pos.Y);
      inc(jump_stage);
    end;
   jumpticker:=0;
   if brickonhead then jump_stage := 0;
   crouch     := false;
   onground   := false;
   stayground := false;
   end;
  end; //checkflight

 if ( (Key[KEY_LEFT].Down = Key[KEY_RIGHT].Down)
  or onground
  or (abs(dpos.x) < abs(ground_dpos.X)) ) and not phys_flag then jump_stage := 0;

  if not phys_flag then
   if not onground then
      if jump_stage <>0 then
         if can_jump and KEY[KEY_UP].Down then
            if jump_stage<5 then
               if dpos.X > 0 then dpos.X := dpos.X + player_acceleration*(1-jump_stage*0.15)
               else dpos.X := dpos.X - player_acceleration*(1-jump_stage*0.15);

  if onground then
 begin
  if fstruct.PowerUps[HASTE_ID]>0 then maxspeedx := pp.gr_maxX + HASTE_SPEED
  else maxspeedx := pp.gr_maxX;
 end
 else
   begin
      if abs(dpos.X) > 1 then
         maxspeedx := abs(dpos.X) + GetOmegaValue * Player_AmplitudeX / (2* abs(dpos.X * dpos.X));
      if maxspeedx < pp.air_maxX then maxspeedx := pp.air_maxX;
      if fstruct.PowerUps[HASTE_ID]>0 then
         if (maxspeedx < pp.air_maxX + HASTE_SPEED) then maxspeedx := pp.air_maxX + HASTE_SPEED;
   end;

 if crouch then
  maxspeedx := maxspeedx * 2/3;

 //ходьба
 if Key[KEY_LEFT].Down and not Key[KEY_RIGHT].Down then
	begin
  if dpos.x > ground_dpos.X then
   dpos.X := ground_dpos.X;
  IncMin(dpos.x, -player_run/phys_freq, -maxspeedx + ground_dpos.X);
  stayground := false;
	end;

 if Key[KEY_RIGHT].Down and not Key[KEY_LEFT].Down then
	begin
  if dpos.x < ground_dpos.X then
   dpos.X := ground_dpos.X;
  IncMax(dpos.x, player_run/phys_freq, maxspeedx + ground_dpos.X);
  stayground := false;
	end;

 crouch := KEY[KEY_DOWN].Down and onground or not IsNET and (crouch and BrickCrouchOnHead);

 CheckJumping;
 CalcRect;
 end;   //with

pos  := round_point(ph.pos, C_ROUND);
dpos := ph.dpos;
end;

procedure TPlayer.UpdateShot;
begin
if fshot and (ammo[cur_weapon] = 0) and not IsClient then
 begin
 fshot := false;
 next_weapon   := GetCurNextWeapon;
 lastwpnchange := 0;
 NoAmmoSound.Play(Pos.X, Pos.Y);
 end;

if fshot then
 begin
    if not IsNet or (NET.Type_=NT_SERVER) then
       NET.shot_send(uid);
    Map.demo.recshot(uid, cur_weapon, round(shotpos.x), round(shotpos.y), round(AbsAngle));
    Push0( -wpn_push2[cur_weapon]*cos(AbsAngle * deg2rad),
           -wpn_push2[cur_weapon]*sin(AbsAngle * deg2rad) );
  case cur_wpn of
   WPN_GAUNTLET :
    if shot_gauntlet(Self) then
     ReloadTicker := Reload_Wait[cur_weapon];
   WPN_PLASMA:
    Shot_plasma(Self);
   WPN_MACHINEGUN, WPN_SHOTGUN:
  	Shot_Bullet(Self);
  else
   Shot(Self);
	end;

 with WeaponObjs[cur_weapon] do
  if not (cur_weapon in [WPN_GAUNTLET, WPN_SHAFT]) then
   begin
   FIREsound1.Play(Pos.X, Pos.Y, (Map.Camera.Target = self) and not cam_fixed);
   if (quad > 1) and (quadtimer = 0) then
    begin
    quadtimer := 25;
    if PowerUpObjs[QUAD_ID] <> nil then
     PowerUpObjs[QUAD_ID].sound3.Play(Pos.X, Pos.Y);
    end;
   end;

 if fstruct.PowerUps[HASTE_ID] > 0 then
  ReloadTicker := ReloadTicker * 4 div 5;

 with fstruct do
  if (cur_weapon <> WPN_GAUNTLET) and (gametype<>GT_RAIL) then
   begin
      dec(Ammo[cur_weapon]);
      Stat_Shot(cur_weapon, UID);
   end;
 end;

fshot := false;
if KEY[KEY_FIRE].Down then
 fireticker := 0;
end;

procedure TPlayer.PrevUpdate;
var
 i   : integer;
 ang : single;
begin
with fstruct do
 begin
 //Получаем состояние назначенных клавиш
 for i := Low(Key) to High(Key) do
	Key[i].Down := false;

 if playertype = C_PLAYER_p1 then
  Key := PKeys[1]
 else
  if playertype = C_PLAYER_p2 then
   Key := PKeys[2];

 KEY[KEY_BALLOON].Down := Console.Show or onSay;
   
 if not dead then
	begin
      KEY[KEY_LEFT].Down:=KEY[KEY_LEFT].Down or KEY[KEY_STRAFELEFT].Down;
      KEY[KEY_RIGHT].Down:=KEY[KEY_RIGHT].Down or KEY[KEY_STRAFERIGHT].Down;

   ang := GetAngle + sangle - AbsAngle;
  if usemouse then
   begin
   if mouselook<>MOUSE_SOLDATMODE then
    begin
   	if Key[KEY_RCENTER].Down then
         ang := 90;
      if Key[KEY_RUP].Down xor KEY[KEY_RDOWN].Down then
         if Key[KEY_RUP].Down then
            ang := ang - keyb_sensitivity
         else
         ang := ang + keyb_sensitivity;
	   ang := ang + Input_MouseDelta.Y * (mouse_sensitivity*mouselook_yaw)/120;
     if mouselook=MOUSE_TFKMODE then
     begin
      if (Input_MouseDelta.X > (20 * mouse_sensitivity/mouselook_pitch)) and left then
         left := false
      else
         if (Input_MouseDelta.X < (-20 * mouse_sensitivity/mouselook_pitch)) and not left then
            left := true;
     end;
    if ang > 180 then ang := 180;
    if ang <   0 then ang := 0;
    SetAngle(ang);
    end
   else
    begin
      if Key[KEY_RCENTER].Down then
         if left then
            Mouse.CAngle := 180
      else
         Mouse.CAngle := 0;
      ang := Mouse.CAngle;
      if ang < 0 then ang := 360 - ang;
         SetAbsAngle(ang);
    end;
   { // XProger: теперь всё это биндится 8)
	 if Input_MouseWheelDelta < 0 then
 		Key[KEY_NEXTWPN].Down := true;
	 if Input_MouseWheelDelta > 0 then
		Key[KEY_PREVWPN].Down := true;     }
   end
  else
   begin
   if Key[KEY_RCENTER].Down then ang := 90;
   if Key[KEY_RUP].Down xor KEY[KEY_RDOWN].Down then
    if Key[KEY_RUP].Down then
     ang := ang - keyb_sensitivity
    else
     ang := ang + keyb_sensitivity;

   if ang > 180 then ang := 180;
   if ang <   0 then ang := 0;
   SetAngle(ang);
   end;
  Key[KEY_FIRE].Down := Key[KEY_FIRE].Down and (dead or (liveticker>10));
 	end
 else
 	for i := Low(Key) to High(Key) do
   if i <> KEY_FIRE then
		Key[i].Down := false;
 end; //with fstruct
end;

procedure TPlayer.Update;
var
 i       : integer;
 strafe  : boolean;
 sx, sy, sa : single;
begin
Model.Sound.target := (Map.Camera.Target = self) and not cam_fixed;

for i := 0 to 2 do
 if rewards_ticker[i] > 0 then
  dec(rewards_ticker[i]);

strafe := (usemouse and
            ((mouselook<>MOUSE_NFKMODE) or not mouselook_strafe) or
           KEY[KEY_STRAFELEFT].Down or
           KEY[KEY_STRAFERIGHT].Down or
            not ((C_PLAYER_LOCAL+C_PLAYER_BOT) and playertype>0) );

with fstruct do
begin
 if Key[KEY_LEFT].Down xor Key[KEY_RIGHT].Down then
  begin
  // Прокрутка анимации ходьбы (назад - вперёд)
  if not strafe or (left = Key[KEY_LEFT].Down) then
   Model.NextFrame
  else
   Model.PrevFrame;

  if not cg_airsteps and not onground then
   Model.FrameIdx := 0;

  if not strafe then
   begin
   if left <> Key[KEY_LEFT].Down then
    Model.FrameIdx := 0;
  	SetLeft(Key[KEY_LEFT].Down);
   end;
  end
 else
  Model.FrameIdx := 0;

 Model.crouch := crouch;
 Model.Update;

 // Если имеем данный повер ап, то обновляем 4 раза за тик
 if fstruct.PowerUps[HASTE_ID] > 0 then
  begin
  Model.Update;
  Model.Update;
  Model.Update;
  end;

 UpdateTickers;

 if (SwitchTicker = 0) and not IsClient then
  if Key[KEY_NEXTWPN].Down xor Key[KEY_PREVWPN].Down then
   begin
   if Key[KEY_NEXTWPN].Down then
    next_weapon := GetCurNextWeapon
   else
    next_weapon := GetCurPrevWeapon;
   lastwpnchange := 0;
   end
  else
   for i := WPN_GAUNTLET to WPN_BFG do
    if (HAS_WPN[i] > 0) and KEY[KEY_WEAPON + i].Down then
     begin
     next_weapon   := i;
     lastwpnchange := 0;
     end;

 weapon_fire := KEY[KEY_FIRE].Down and (cur_weapon = next_weapon) and not dead;
 if (cur_weapon = WPN_GAUNTLET) and weapon_fire then
  gauntletON
 else
  gauntletOFF;

 // XProger: обновление оружия (стрельба, анимация)
 // Neoff: обновление идет нормально...
 with WeaponObjs[cur_weapon] do
  begin
  // XProger: если нажаты клавиши стрельбы - стрелять...
  // Neoff: и мы стреляем!!!
  if (shaft <> nil) then
   if not weapon_fire or (cur_weapon <> WPN_SHAFT) then
    begin
    shaft.Kill;
    shaft := nil;
    end;

   
  if weapon_fire and (reloadticker = 0) and not IsClient then
   fShot := true;

  weapon_fire := weapon_fire and (not (ammo[cur_weapon] = 0) or IsClient);
  if fshot and (reloadticker = 0) and (cur_weapon <> WPN_GAUNTLET) and
  (IsNet or (Ammo[cur_weapon]>0))	then
   begin
   ReloadTicker := Reload_Wait[cur_weapon];
   shot_draw(Self);
   end;

  if weapon_frame_wait = 0 then
   if fshot or (weapon_frame > 0) and (cur_weapon <> WPN_GAUNTLET) then
    begin
    FIREanim.FrameIndex := weapon_frame + 1;
    weapon_frame := FIREanim.FrameIndex;
    if (weapon_frame = 0) and (cur_weapon = WPN_GAUNTLET) then
     begin
     weapon_frame := 1;
     FIREanim.FrameIndex := weapon_frame;
     end;
    weapon_frame_wait := WPN_frame_wait[Struct.weaponID];
    end
   else
    begin
    weapon_frame := 0;
    FIREanim.FrameIndex := 0;
    end
  else
   dec(weapon_frame_wait);
  end; //with WeaponObjs[cur_weapon]

 //Neoff: апдейт текущей позиции стрельбы.
 if not IsClient then
 begin
   shotpos.X := pos.X;
   shotpos.Y := pos.Y + GetMY;
 end;
 if shaft <> nil then
  begin
  sa := sangle*deg2rad;
  sx := trunc(shotpos.X + cos(sa) * WPN_LEN[WPN_SHAFT]);
  sy := trunc(shotpos.Y + sin(sa) * WPN_LEN[WPN_SHAFT]);
  shaft.SetVector(sx, sy, sa);
  shaft.Update;
  end;
 end; //with  fstruct

Model.X     := Pos.X;
Model.Y     := Pos.Y;
if not Model.Steps and onground then
 Model.Sound.Step.Play(Pos.X, Pos.Y);
Model.Steps := onground;

if KeysChanged then
 Net_Moved := 0;

if KEY[KEY_USE].Down then
   Map.ActivateUse(round(Pos.X), round(Pos.Y));
end;

procedure TPlayer.Draw;
var
 pup : boolean;
begin
//ТОЛЬКО ЕСЛИ МЫ ЖИВЫЕ
if dead then
 Exit;

glPushMatrix;
//XProger: int - чтобы не дрожала модель игрока при движениий
// см. Camera.Update :)
//Neoff: нужен round - потому что игрок не должен парить над бриками в 1 пикселе!!!
// XProger: а я говорю - trunc :)
glTranslatef(trunc(Pos.X), trunc(Pos.Y), 0);

if left then
 glScale(-1, 1, 1);

glEnable(GL_ALPHA_TEST);       // Врубаем альфа тест
glAlphaFunc(GL_GEQUAL, 1/255); // Рисуем пиксели с альфой >= 1

//спецеффекты:
pup := true;
glColor4f(1, 1, 1, 1);
with fstruct do
 if PowerUps[INV_ID] > 0 then
  begin
  glColor4f(1, 1, 1, 0.05); // Если локальный игрок - то хоть чуток, но видно
  pup := false; // Не нужно нам свечение, т.к. мы невидимы :)
  end
 else
  if (PowerUps[REGEN_ID] > 0) and (regentimer > 25) then
   glColor4f(0.5, 0, 0, 0.5)
  else
   if PowerUps[QUAD_ID] > 0 then
    glColor4f(0.3, 0.3, 1, 0.5)
   else
    if PowerUps[BATTLESUIT_ID] > 0 then
     glColor4f(0.75, 0.5, 0, 0.5)
    else
     pup := false;
Model.Draw(pup);
//рисуем оружие И ПРИЦЕЛ прям здесь! пока что. потом будет синхронизировано с боном модели.
// XProger: но стрельба в любом случае будет происходить из одной точки,
//  и движение прицела в зависимости от положения рук - не катит.
// XProger: теперь для отрисовки прицела созданна соответствующая процедура :)
if cur_weapon = WPN_RAILGUN then
begin
 Model.DrawWeapon(Angle, crouch, cur_weapon, weapon_frame, pup, 1 - ReloadTicker/Reload_Wait[cur_weapon]);
 if r_enemy_rail and (playertype and  C_PLAYER_LOCAL=0) then
    Model.railcolor:=r_enemy_rail_color
 else
   Model.railcolor:=Self.railcolor;
end
else
 Model.DrawWeapon(Angle, crouch, cur_weapon, weapon_frame, pup, 0);
// XProger: и для отрисовки оружия тож в отдельную пихнул
// да и движения рук нет и не будет :)
glColor4f(1, 1, 1, 1);
xglAlphaBlend(1);
glDisable(GL_ALPHA_TEST);
glPopMatrix;
end;

procedure TPlayer.DrawCrosshair;
var
 s      : string;
 cx, cy : single;
 i      : integer;
begin
if dead or Map.stopped then
 Exit;

glPushMatrix;
glTranslatef(trunc(Pos.X), trunc(Pos.Y), 0);

if cg_drawrewards then
 for i := 0 to 2 do
  if rewards_ticker[i] > 0 then
   begin
   xglTex_Enable(RewardsFrame.Frame[i]);
   glColor3f(1, 1, 1);
   glBegin(GL_QUADS);
    glTexCoord2f(0, 1); glVertex2f( -16, -64);
    glTexCoord2f(1, 1); glVertex2f(  16, -64);
    glTexCoord2f(1, 0); glVertex2f(  16, -32);
    glTexCoord2f(0, 0); glVertex2f( -16, -32);
   glEnd;
   break; // рисуем только 1 награду
   end;

if (fstruct.PowerUps[INV_ID] = 0) or (Map.Camera.Target = Self) then
 begin
 //прорисовка balloon
 if balloon then
  begin
  xglTex_Enable(BalloonFrame.Frame[0]);
  glColor3f(1, 1, 1);
  glBegin(GL_QUADS);
   glTexCoord2f(0, 1); glVertex2f( -16, -64);
   glTexCoord2f(1, 1); glVertex2f(  16, -64);
   glTexCoord2f(1, 0); glVertex2f(  16, -32);
   glTexCoord2f(0, 0); glVertex2f( -16, -32);
  glEnd;
  end;

 if shownick then
  begin
  s := Name;
  Text_TagOut(-Tag_Length(s)*4, -40, @Console.Font, true, PChar(s));
  end;
 end;


if (Map.Camera.Target <> Self) and not cam_fixed or (playertype = C_PLAYER_LOCAL) then
 begin
 // XProger: Не рисуем прицел для не нужных игроков ;)
 glPopMatrix;
 Exit;
 end;

if not usemouse or (mouselook<>MOUSE_SOLDATMODE) then
 begin
 cx := trunc(cos(sangle*deg2rad)*cg_crosshair_offset);
 cy := trunc(GetMY + sin(sangle*deg2rad)*cg_crosshair_offset);
 end
else
 begin
 cx := trunc(Mouse.GetX);
 cy := trunc(GetMY + Mouse.GetY);
 end;

if cg_crosshair and (playertype and C_PLAYER_LOCAL > 0) and
  (cam_fixed or (Map.Camera.Target = Self)) then
 begin
 xglAlphaBlend(1);
 glColor4ub(cg_crosshair_color_r, cg_crosshair_color_g, cg_crosshair_color_b, 255);
 xglTex_Enable(CrosshairFrame[cg_crosshair_type]);
 glBegin(GL_QUADS);
  glTexCoord2f(0, 1); glVertex2f(cx - cg_crosshair_size, cy + cg_crosshair_size);
  glTexCoord2f(1, 1); glVertex2f(cx + cg_crosshair_size, cy + cg_crosshair_size);
  glTexCoord2f(1, 0); glVertex2f(cx + cg_crosshair_size, cy - cg_crosshair_size);
  glTexCoord2f(0, 0); glVertex2f(cx - cg_crosshair_size, cy - cg_crosshair_size);
 glEnd;
 end;
glPopMatrix;
end;


procedure TPlayer.MoveTo(x0, y0: word);
begin
with fstruct, Pos do
 begin
 X := x0 + 16;
 Y := y0 - 8;
 end;
fmoved := true;

if Map.Camera.target=self then
   Map.Camera.Pos := Pos; // cam_smooth при телепортации или резких скачках
Particle_Add(TP_Portal.Create(Pos)); // вспышка типа
end;

procedure TPlayer.MoveBy(dx0, dy0: SmallInt);
begin
// XProger: типа в демках TAreaTeleportWay не пашет?!
if Map.Demo.playing then
 Exit;
with fstruct, Pos do
 begin
 X := X + dx0;
 Y := Y + dy0;
 end;
fmoved := true;
// XProger: не уверен нужны ли здесь следующие строки...
Map.Camera.Pos := Pos; // cam_smooth при телепортации или резких скачках
Particle_Add(TP_Portal.Create(Pos)); // здесь оно надо?
end;

function TPlayer.TakeWpn(wpnID, count: WORD; mode: Byte): boolean;
begin
Result := false;
with fstruct do
 if (Has_wpn[wpnID] > 0) and (Mode > 0) then
  if Ammo[wpnID] < count then
   begin
   Ammo[wpnID] := count;
   Result := true;
   end
  else
   begin
   if mode = 1 then
    begin
    Ammo[wpnID] := Ammo[wpnID] + 1;
    Result := true;
    end;
   end
 else
  begin
  Has_Wpn[wpnID] := 1;
  TakeAmmo(wpnID, count);
  Result := true;
  end;
end;


function TPlayer.TakeAmmo(wpnID, count: word): boolean;
begin
Result := false;
with fstruct do
 if Ammo[wpnID] < Max_Ammo[wpnID] then
  begin
  Result := true;
  inc(Ammo[wpnID], count);
  if Ammo[wpnID] > Max_Ammo[wpnID] then
   Ammo[wpnID] := Max_Ammo[wpnID];
  end;
end;

function TPlayer.TakeHealth(health_: WORD): boolean;
begin
//если порция 25 и 50 только до 100 жизней, иначе до 200
Result := false;
if dead then Exit;
with fstruct do
 if health_ in [25..50] then
  begin
  if health < PlayerMaxHealth1 then
   begin
   health := health + health_;
   if health > PlayerMaxHealth1 then
    health := PlayerMaxHealth1;
   Result := true;
   end
  end
 else
  if health < PlayerMaxHealth2 then
   begin
   health := health + health_;
   if health > PlayerMaxHealth2 then
    health := PlayerMaxHealth2;
   Result := true;
   end;
end;

function TPlayer.TakeArmor(armor_: WORD): boolean;
begin
Result := false;
if dead then Exit;
if armor < PlayerMaxArmor2 then
 begin
 armor  := armor + armor_;
 Result := true;
 end;
end;

function TPlayer.TakePowerUp(itemID, count: word): boolean;
begin
Result := false;
if itemID in [REGEN_ID..INV_ID] then
 with fstruct do
  if PowerUps[ItemID]<count then
   begin
   Result := true;
   PowerUps[ItemID] := count;
   if ItemID = regen_ID then
    regentimer := 50;
   end;
end;

//Здоровье и броня - проперти на всякий случай
procedure TPlayer.SetArmor(const Value: SmallInt);
begin
with fstruct do
 begin
 Armor := Value;
 if Armor > PlayerMaxArmor2 then
  Armor := PlayerMaxArmor2;
 end;
end;

procedure TPlayer.SetHealth(const Value: SmallInt);
begin
with fstruct do
 begin
 Health := Value;
 if Health > PlayerMaxHealth2 then
  Health := PlayerMaxHealth2;
 end;
end;

procedure TPlayer.Restart;
begin
//В ЭТОЙ ПРОЦЕДУРЕ ИДЕТ РЕСТАРТ ПЛЭЙЕРА ПЕРЕД РЕСПАУНОМ!!!
//СТАТИСТИКУ ОБНУЛЯЕМ В ДРУГОЙ ПРОЦЕДУРЕ!!!

ZeroMemory(@key, SizeOf(key));
ZeroMemory(@ph, SizeOf(ph));

ph.ground_dpos := @NullPoint;

onground := false;
crouch   := false;
jumping:=false;
//обнуление тикеров
reloadticker := 0;
liveticker   := 0;
switchticker := 0;

hticker:=HealthTickerWait;
fshot := false;
lastwpnchange := 255;
lastextremum  := 0;
omega      := 0;
lastangle  := 0;
sangle     := 0;
absangle   := 0;
left       := false;
jumpticker := 100;
airticker  := MAX_AIR;

fly_snd    := -1;

resp       := false;

jump_stage:=0;
fMoved     := true;
net_moved  := 0;
lastwpn    := 255;
fHited     := true;

dead       := false;
Model.Died := false;
//рестартим жизни, броню и.т.п.

lastrail := 0;
lastfrag := 255;
dpos     := Point2f(0, 0);

Health := DEF_HEALTH;
Armor  := DEF_ARMOR;

//по дефолту даем DEF_WEAPON
cur_weapon  := DefWeapon.weaponid;
cur_wpn     := cur_weapon;
next_weapon := cur_weapon;

with fstruct do
 begin
   ZeroMemory(@Ammo, SizeOf(TWPNArray));
   ZeroMemory(@Has_Wpn, SizeOf(TWPNArray));
   ZeroMemory(@PowerUps, SizeOf(TPowerUpArray));
   Has_Wpn[WPN_GAUNTLET] := 1;
   Ammo[WPN_GAUNTLET]    := 1;
   Has_Wpn[cur_weapon]   := 1;
   Ammo[cur_weapon]      := DEF_STARTAMMO;
 end;

if AI<>nil then
 TTFKBot(AI).bot_restart;

fireticker := 250;
fSquished:=false;
end;

procedure TPlayer.UpdateTickers;
var
 i : integer;
begin
with fstruct do
 begin
 if (Health > PlayerMaxHealth1) or
	  (Armor > PlayerMaxArmor1) then
  if HTicker > 1 then
   dec(HTicker)
  else
   begin
   HTicker := HealthTickerWait;
   if (Health > PlayerMaxHealth1) and
      (PowerUps[REGEN_ID] = 0) then
    begin
    fHited := fHited or DEMO_HEALTH_TIMER;
    dec(Health);
    end;
   if Armor > PlayerMaxArmor1 then
    begin
    fHited := fHited or DEMO_HEALTH_TIMER;
    dec(Armor);
    end;
   end
 else
  HTicker := HealthTickerWait;

//Neoff: ВНИМАНИЕ, СРОЧНО НУЖЕН КОД СМЕНЫ ОРУЖИЯ ИЗ НФК!!!!!
//Neoff: сэмулировали очень точно, все уже ничего не надо...
 if (cur_wpn <> next_weapon) and (SwitchTicker = 0) then
  begin
  cur_wpn      := next_weapon;
  SwitchTicker := SwitchTickerWait;
  end
 else
  if SwitchTicker > 0 then
   dec(SwitchTicker);
  if ReloadTicker > 0 then
   dec(ReloadTicker)
  else
  begin
  if cur_weapon<>cur_wpn then
  begin
   net_moved:=0;
   cur_weapon := cur_wpn;
   ReloadTicker:=player_weaponchange;
   // Звук переключения оружия...
   if playertype and C_PLAYER_LOCAL>0 then
      SwitchSound.Play(Pos.X, Pos.Y);
  end;

  end;
  if (cur_weapon <> cur_wpn) and
     (cur_weapon = WPN_GAUNTLET) then
   begin
   cur_weapon   := cur_wpn;
   reloadticker := 0;
   end;

  if fireticker < 250 then inc(fireticker);

	if lasthit > 0 then dec(lasthit);

  if jumpticker <255 then inc(jumpticker);

  if (lastfrag < 255) then inc(lastfrag);

  if liveticker < 32000 then
   inc(liveticker)
  else
   liveticker := 10000;

  if lastwpnchange < 255 then inc(lastwpnchange);

  if lastextremum < Player_Extr then
   inc(lastextremum)
  else
   omega := 0;

  //проверка таймера ВОДЫ
  if crouch and
     Map.block_Water_s(Pos.X, Pos.Y-4) or
     not crouch and Map.block_Water_s(Pos.X, Pos.Y-20) then
   begin
   if (liveticker mod 10 = 0) and (AirTicker > 0) then
    dec(AirTicker);

   if (liveticker mod WATER_DMGWAIT = 0) and (AirTicker = 0) then
    HitWater(WATER_DMG, UID);
   end
  else
   AirTicker := MAX_AIR;

  if quadtimer  > 0 then dec(quadtimer);

  if regentimer > 0 then dec(regentimer);

  if regentimer = 0 then
   begin
   if (PowerUps[REGEN_ID] > 0) and
     	(regentimer = 0) and
      (health < PlayerMaxHealth2) then
    begin
    health := health + 5;
    if health > PlayerMaxHealth2 then
     health := PlayerMaxHealth2;
    regentimer := 50;
    PowerUpObjs[REGEN_ID].sound3.Play(Pos.X, Pos.Y);
    end;
   end
  else
   if PowerUps[REGEN_ID] = 0 then
    regentimer := 0;

  if hastetimer > 0 then dec(hastetimer);
  if (hastetimer = 0) and
     (PowerUps[HASTE_ID] > 0) and
     (trunc(dPos.X) <> 0) then // опанььки, движение по Y не движение ;)
   begin
   hastetimer := 10;
	 if r_smoke then
	  Particle_Add(TP_Smoke.Create(Point2f(Pos.X, RectY2(frect))));
   end;

  for i := Low(PowerUps) to High(PowerUps) do
   if PowerUps[i] > 0 then
	  begin
    if i in [QUAD_ID, BATTLESUIT_ID, HASTE_ID] then
     begin
     if (PowerUps[i] <= 200) and (Powerups[i] mod 50 = 0) then
      PowerUpObjs[i].wearoffsound.Play(Pos.X, Pos.Y);
     end;
    dec(PowerUps[i]);
    end;
 end;
end;

function TPlayer.GetCurNextWeapon: WORD;
begin
Result := (cur_wpn + 1) mod WPN_Count;
while not (Has_Wpn[Result] <> 0) or
      not WeaponExists(Result) or
   	      (playertype = C_PLAYER_p1) and p1nextwpn_skipempty and (Ammo[Result] = 0) or
          (playertype = C_PLAYER_p2) and p2nextwpn_skipempty and (Ammo[REsult] = 0) do
 Result := (Result + 1) mod WPN_Count;
end;

function TPlayer.GetCurPrevWeapon: WORD;
begin
Result := (cur_wpn + WPN_Count - 1) mod WPN_Count;
while not (Has_Wpn[Result] <> 0) or
      not WeaponExists(Result) or
  	  (playertype = C_PLAYER_P1) and p1nextwpn_skipempty and (Ammo[Result] = 0) or
     (playertype = C_PLAYER_P2) and p2nextwpn_skipempty and (Ammo[Result] = 0) do
 Result := (Result + WPN_Count - 1) mod WPN_Count;
end;

function TPlayer.GetMY: integer;
begin
Result := GetShotY(crouch);
end;

function TPlayer.Hit(damage, playerUID: integer): integer;
var
 armordmg : integer;
begin
hit_UID := playerUID;

if dead or (health = 0) then
 begin
 Result := 0;
 Exit;
 end;

fhited := true;

//результат может быть другим только при наличии
//супер-бупер поверапов.
Result := damage;

if playerUID = UID then
 damage := damage div 2;

with fstruct do
 begin
 if PowerUps[BATTLESUIT_ID] > 0 then
  begin
  damage := (damage + 1) div 2;
  if quadtimer = 0 then
   begin
   quadtimer := 25;
   PowerUpObjs[BATTLESUIT_ID].sound3.Play(Pos.X, Pos.Y);
   end;
  end;

 armordmg := trunc(2 * (damage+1) / 3);
 if armordmg > armor then
  armordmg := armor;
 damage:=damage-armordmg;
 Self.SetArmor(armor - armordmg);
 Self.SetHealth(health - damage);
 if health < 0 then
  armor := 0;

 // Проигрывание крика :)
 if lasthit <= 0 then
  begin
  Model.Sound.Pain(Pos.X, Pos.Y, Health);
  lasthit := 25;
  end;

 if AI<>nil then
  TTFKBot(AI).bot_onhit;
 end;//with fstruct;
end;

function TPlayer.HitWater(damage, playerUID: integer): integer;
begin
if dead or (health = 0) then
 begin
 Result := 0;
 Exit;
 end;

hit_UID    := UID_WATER;
hit_weapon := 0;
fhited  := true;

Result := damage;
with fstruct do
 health := health - damage;

// Проигрывание крика :)
if lasthit <= 0 then
 begin
 Model.Sound.Pain(Pos.X, Pos.Y, Health);
 lasthit := 25;
 end;
 
if AI <> nil then
 TTFKBot(AI).bot_onhit;
end;

procedure TPlayer.Kill;
var
 i : integer;
begin
armor  := 0;

if IsNET then
 dpos := NullPoint;

stat_death(UID);

if AI <> nil then
 TTFKBot(AI).bot_ondead;

//спрайтик трупа... или трупик спрайта
if r_dead then
 RealObj_Add(
   TDeadPlayer.Create(Self, fstruct.health)
   );

fstruct.health := 0;
dead           := true;
crouch         := false;
deadticker     := 0;
armor          := 0;
Reset;

//выпадающее из трясущихся рук умирающего игрока оружие.
if not (cur_weapon in [WPN_GAUNTLET, DefWeapon.weaponid]) then
 BrokeItem(Self, cur_weapon);

with fstruct do
 for i := low(PowerUps) to high(PowerUps) do
  if powerups[i] > 0 then
   begin
   BrokeItem(Self, i);
   powerups[i] := 0;
   end;

//звук смерти
Model.Sound.Death(Pos.X, Pos.Y);

if dead_mode then Map.pl_delete(Self);
if shaft<>nil then begin shaft.kill;shaft:=nil; end;
GauntletOff;
end;

procedure TPlayer.Push0(sx, sy: single);
begin
with fstruct do
 begin
 dpos.X     := dpos.X + sx;
 dpos.Y     := dpos.Y + sy;
 stayground := false;
 onground   := false;
 end;
end;

procedure TPlayer.Push(x0, y0, s: single);
begin
if IsNet then Exit;
with fstruct do
 begin
 x0 := x0 - pos.X;
 y0 := y0 - pos.Y;
 dpos.X := dpos.X - signf(x0) * s * 5/6;
 dpos.Y := dpos.Y - signf(y0) * s * 5/6;
 stayground := false;
 onground   := false;
 end;
end;

procedure TPlayer.Push2(x0, y0, s: single);
begin
if IsNET then Exit;
NET_Moved := 0;
with fstruct do
 begin
 x0 := trunc(x0) - trunc(pos.X);
 y0 := trunc(y0) - trunc(pos.Y);
 if signf(x0) < 0 then
  dpos.X := dpos.X + s
 else
  if signf(x0) > 0 then
   dpos.X := dpos.X - s * 5/6;
 if signf(y0) > 0 then
  dpos.Y := dpos.Y - s * 5/6;
 stayground := false;
 onground   := false;
 end;
end;

procedure TPlayer.RotateX;
begin
if not usemouse or (mouselook<>MOUSE_SOLDATMODE) then
 left := not left;
fstruct.dpos.X := -dpos.X;
end;

procedure TPlayer.RotateY;
begin
with fstruct do
 dpos.Y := -dpos.Y;
end;

function TPlayer.GetArmor: smallint;
begin
Result := fstruct.armor;
end;

function TPlayer.GetHealth: smallint;
begin
Result := fstruct.health;
end;

function TPlayer.GetAngle: single;
begin
if Left then
 Result := 270 - sangle
else
 if fangle < 180 then
  Result := 90 + sangle
 else
  Result := sangle - 270;
end;

procedure TPlayer.SetAngle(value: single);
var
 ang : smallint;
begin
if Left then
 value := 270 - value
else
 if value >= 90 then
  value := value - 90
 else
  value := 270 + value;
sangle := value;
// XProger: Хм, заменить это на trunc не вышло :)
// ибо при повороте игрока налево прицел начинает смещаться :P
ang    := round(value);
if ang <> fangle then
 begin
 if (fangle - prevangle) * (ang - fangle) < 0 then
  begin
  omega := lastextremum;
  lastextremum := 0;
  end;
 prevangle := fangle;
 fangle    := ang;
 end;
end;

function TPlayer.GetAbsAngle: single;
begin
Result := sAngle;
end;

procedure TPlayer.SetAbsAngle(value: single);
var
 ang : integer;
 f   : boolean;
begin
while value >= 360 do
 value := value - 360;

while value < 0 do
 value := value + 360;

sangle := value;
ang    := trunc(value);
if ang <> fangle then
 begin
 if ang_norm3(fangle-prevangle)*ang_norm3(ang-fangle)<0 then
  begin
  omega := lastextremum;
  lastextremum := 0;
  end;
 prevangle := fangle;
 fangle    := ang;

 if (fangle <> 90) and (fangle <> 270) then
  begin
  f := not ((fangle < 90) or (fangle > 270));
  if f <> fstruct.left then
   begin
   if usemouse and (mouselook=MOUSE_SOLDATMODE) then
    Mouse.CAngle := fAngle;
   fstruct.left := f;
   end;
  end;
 end;
end;

function TPlayer.GetOmegaValue: single;
var
 a : WORD;
begin
Result := 0;
if not crouch and (abs(dpos.X - ph.ground_dpos.X) > 1) then
 begin
 a := abs(Player_omega - omega);
 if a <= 1 then
  Result := 1
 else
  if a < 4 then
   Result := 1 - (a - 1)/3;
 end;
end;

function TPlayer.Fly: boolean;
begin
Result := fstruct.PowerUps[FLIGHT_ID] > 0;
end;

function TPlayer.Quad: integer;
begin
if fstruct.PowerUps[QUAD_ID] > 0 then
 Result := 3
else
 Result := 1;
end;

procedure TPlayer.Reset;
begin
if shaft <> nil then
 begin
 shaft.Kill;
 shaft := nil;
 end;
gauntletOFF;
stat := Stat_Get(fstruct.UID, true);
end;

procedure TPlayer.GauntletOFF;
begin
if gauntlet <> nil then
 begin
 gauntlet.die := 0;
 gauntlet     := nil;
 end;
 if gauntletsnd > -1 then
  Snd_Stop(gauntletsnd);
 gauntletsnd := -1;
end;

procedure TPlayer.GauntletON;
var
 vis_shotpos : TPoint2f;
begin
if not IsClient then
begin
   vis_shotpos.X := shotpos.X + cos(AbsAngle * deg2rad) * WPN_LEN[WPN_GAUNTLET];
   vis_shotpos.Y := shotpos.Y + sin(AbsAngle * deg2rad) * WPN_LEN[WPN_GAUNTLET];
end else
begin
   vis_shotpos.X := pos.X + cos(AbsAngle * deg2rad) * WPN_LEN[WPN_GAUNTLET];
   vis_shotpos.Y := pos.Y + GetMY + sin(AbsAngle * deg2rad) * WPN_LEN[WPN_GAUNTLET];
end;
if gauntlet = nil then
 begin
 gauntlet := Particle_Add(TP_Light.Create(vis_shotpos, Point2f(48, 48), RGBA(196, 255, 255, 36), 1) );
 gauntletsnd := WeaponObjs[0].FIREsound1.Play(shotpos.X, shotpos.Y);
 end
else
 begin
 gauntlet.Pos := vis_shotpos;
 snd_SetPos(gauntletsnd, Point2f(shotpos.X, shotpos.Y));
 end;
end;

procedure TPlayer.SetLeft(Value: boolean);
begin
if Value then
 begin
 if sangle > 270 then sangle := 540 - sangle;
 if sangle < 90  then sangle := 180 - sangle;
 end
else
 begin
 if (sangle > 90) and (sangle <= 180) then
  sangle := 180 - sangle;
 if (sangle > 180) and (sangle < 270) then
  sangle := 540 - sangle;
 end;

fangle := round(sangle);
if Value <> fstruct.left then
 if usemouse and (mouselook=MOUSE_SOLDATMODE) then
 	Mouse.CAngle := fAngle;
fstruct.Left := Value;
end;

function TPlayer.IsNET: boolean;
begin
Result := playertype = C_PLAYER_NET;
end;

function TPlayer.IsClient: boolean;
begin
   Result:= playertype and C_PLAYER_LOCALHOST=0;
end;

procedure TPlayer.SetWeapon(Value: byte);
begin
if cur_weapon<>value then
begin
   reloadticker:=0;
   switchticker:=0;
end;
cur_weapon  := value;
cur_wpn     := value;
next_weapon := value;
end;

procedure TPlayer.SquishKill;
begin
	health := Min_HEALTH;//РАЗРЫВАЕТ
   hit_UID:= UID;
   hit_weapon := 0;
   fSquished:=true;
 	fhited     := true;
end;

function TPlayer.GetBalloon: boolean;
begin
   Result:=KEY[KEY_BALLOON].Down;
end;

procedure TPlayer.SetBalloon(const Value: boolean);
begin
   KEY[KEY_BALLOON].Down:=Value;
end;

procedure TPlayer.UpdateMove;
begin
//приходится сначала проверять team и ставить соответствующую модельку...
if gametype and GT_TEAMS>0 then
   Model.Color:=Skins[Self.team].Color;


with fstruct do
 begin
 if Map.stopped then
 	begin
 	NeoMove;
 	Exit;
  end;

 if dead and not phys_flag then
	begin
  inc(deadticker);
  if not Map.demoplay and not IsNet then
   begin
   if (deadticker >= 50) and Key[KEY_FIRE].down or
      (deadticker >= 50 * forcerespawn) then
      begin
         if Map.IsClientGame then
            net_Client.resp_send(UID)
         else Map.pl_respawn(Self);
    	end;
   end;
 	NeoMove;
  Exit;
	end;
 //Изменяем позицию
 if IsNET then
 begin
    if not phys_flag then
      NetMove
 end
 else
  if playertype <> C_PLAYER_DEMO then
   NeoMove
  else
  begin
    if not phys_flag then
      DemoMove;
  end;
   end;
end;

procedure TPlayer.SetStruct(const Value: TPlayerStruct);
begin
   fStruct := Value;
   sangle := fstruct.fangle;
   prevangle:= fstruct.fangle;
   lastangle:= fstruct.fangle;
end;

end.

