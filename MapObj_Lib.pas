unit MapObj_Lib;

interface

(***************************************)
(*  TFK Objects        version  1.0.1.6*)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)
//{6 версия библиотеки включает поддержку новой физики TFK в виде
//объектов Triangle и Elevator :) которые непроницаемы для пуль благодаря math_lib и weapon_lib

{И ЕЩЕ РАЗ ПОВТОРЯЮ - В FSTRUCT ОБЪЕКТА НЕ ХРАНИТСЯ REAL-TIME ПЕРЕМЕННЫХ!!!
 ТАК ЧТО НИКАКИХ fstruct.active:=true быть не должно. active уже для другого используется - Neoff}

{OBJECT MANIFEST
  каждый объект имеет таргет при котором он активируется (targetname) и таргет который он
     использует после активации(target).
  procedure Activate имеет различный вид для активирования игроком и активирования другим объектом

  тип активации другим объектом(Active: byte):
     0 - объект не может быть активирован/деактивирован
     1, 2 - объект активируется/деактивируется
  начальное положение объекта определяется различными переменными в зависимости от оьъекта.

  после активации/деактивации объект либо возвратится в нач. положение
  через wait тактов, либо, если wait=0 то он останется в текущем положении.

  объект активирует другие объекты (с таргетом target) после waittarget тактов,
  если конечно он специального типа (кнопка, триггер).

  Для новых объектов переход к любому положению обозначается своим таргетом.
  См. лифт :)
}

{Данный манифест распространяется на все новейшие объекты.
 Лифт работает по нему ;) }

uses
 Windows, OpenGL,
 Engine_Reg,
 Constants_Lib,
 Func_Lib,
 Type_Lib,
 Graph_Lib,
 Math_Lib,
 ObjAnim_Lib,
 ObjSound_Lib,
 Demo_Lib,
 Particle_lib;

const
   ObjCaseSize = 54;
   NULLTARGET = 65535;

type
 TObjType = (otNone, otRespawn, otJumpPad,
   otArmor, otHealth, otPowerUp, otWeapon, otAmmo,
 	otPortal, otButton, otNFKDoor, otTrigger, otDeathLine,
   otWater, otElevator, otTriangle,
   otAreaPush, otAreaPain, otLava, otArenaEnd, otAreaTeleport, otTeleportWay,
   otEmptyBricks, otBackBricks, otLightLine, otBloodGen, otWeather,
   otCTFFlag, otTrain, otTrainPoint, otBelt, otAnimation, otSoundTrigger, otDestroyer,
   otMonster, otTeleport);
 TSetObjType = set of TObjType;

var
   ChildObjects: TSetObjType = [otNone, otRespawn, otJumpPad,
   	otArmor, otHealth, otPowerUp, otWeapon, otAmmo, otPortal,
      otButton, otNFKDoor, otTrigger, otDeathLine, otWater,
      otAreaPush, otAreaPain, otLava, otArenaEnd, otLightLine, otBloodGen, otBelt, otAnimation,
         otSoundTrigger, otTriangle, otDestroyer, otTeleport];

   ShootObjs: TSetObjType = [otButton, otNFKDoor, otTrigger, otElevator,
   	otArenaEnd, otBloodGen, otDestroyer, otMonster];

   ItemObjs: TSetObjType = [otArmor, otHealth, otPowerUp, otWeapon, otAmmo];

   NetObjs : TSetObjType = [otArmor, otHealth, otPowerUp, otWeapon, otAmmo, otElevator, otTrain, otTrainPoint, otDestroyer];

   GeometryObjs : TSetObjType = [otNFKDoor, otElevator, otTriangle, otTrain];

   //здесь списки объектов для различных режимов:

   GameALLObjs : TSetObjType =
   [otNone, otRespawn, otJumpPad,
 	otPortal, otButton, otNFKDoor, otTrigger, otDeathLine,
   otWater, otElevator, otTriangle,
   otAreaPush, otAreaPain, otLava, otAreaTeleport, otTeleportWay,
   otEmptyBricks, otBackBricks, otLightLine, otBloodGen, otWeather,
   otTrain, otTrainPoint, otBelt, otAnimation, otSoundTrigger, otDestroyer, otTeleport];

   GameNotRAObjs : TSetObjType = [otArmor, otHealth, otPowerUp, otWeapon, otAmmo];

   GameTDMObjs : TSetObjType = [];
   GameCTFObjs : TSetObjType = [];
   GameDOMObjs : TSetObjType = [];
   GameTRIXObjs : TSetObjType = [otArenaEnd];
   GameSPObjs : TSetObjType = [otArenaEnd, otMonster];

type
   TDemoObjRec =
   record
   	reserved: array [0..7] of word;
   end;
   string32= string[32];
   string50= string[50];


 TMapObjStruct = record
    x, y, width, height: word;  //4
    active: byte;//1
    orient: byte;//1
    target_name, target: word;
    wait, waittarget: word;  //4
    itemID, count: word;//4

    case ObjType: TObjType of
       otNone: (reserved:array [0..ObjCaseSize-2] of byte; team: byte);
       otRespawn: ( resp_weapons, resp_Ammo: TWPNArray; resp_mode, resp_health, resp_armor: byte );
       otArmor: (temp: word);
       otJumpPad: (jumpspeed, jumpspeedx: single);
       otPortal, otTeleport: (gotox, gotoy: word);
       otButton: (color: byte);
       otTrigger: (execcmd: string50; onlyplayer: boolean);
       otNFKDoor: (opened: boolean);
       otWeapon: (weaponID: word);
       otDeathLine: (angle, maxlen: single; damage, damagewait: integer);//deathline, lightline
       otElevator, otTrain: (elevspeed: single; elevx, elevy: smallint;
       	etargetname1, etargetname2, etarget1, etarget2: word;
         eactive: boolean; edestination: word);
       otTrainpoint: (tpindex, tpnext: word; orientchange: boolean; speedchange: boolean; speedvalue: single);
       otAreaPush: (pushspeedx, pushspeedy: smallint; pushwait: word);
       otAreaPain: (paindamage, painwait: word; painactive: boolean);
       otArenaEnd: ( nextmap: string32 );
       otBackBricks: (plane: byte);
       otBloodGen: (bloodangle, bloodL: single; bloodwait, bloodtype, bloodcount: word);//deathline, lightline, bloodgen
       otBelt: (beltspeedx, beltspeedy: single; beltactive: boolean);
       otAnimation: (animcount, animwait: integer);
       otSoundTrigger: (soundname: string32; soundradius:word; soundloop, fullsound: boolean);
       otDestroyer: (partscount: byte; partshealth: word);
       otMonster: (monster_health, monster_damage: word; monster_mode: byte; monster_speed: single;
       monster_color: byte);
       otWater: (min_level, max_level, cur_level: word);
    end;

 PMapObjStruct = ^TMapObjStruct;

type
 //физический объект - это всего лишь рекорд в который может быть записана
 //информация о контактирующем объекте.
 TPhysObj =
 record
    frect: TMathRect;
    dpos: PPoint2f;
    normal: TPoint2f;
    floatpos: TPoint2f; //ДЛЯ НОРМАЛЬНОГО ОКРУГЛЕНИЯ
    dis_hor, dis_top, dis_bottom: boolean; //disable horizontal checking
 end;

const
   NullPoint : TPoint2f = (x: 0; y: 0);

type
   TCustomMapObj = class
     constructor Create(struct_: TMapObjStruct);
     destructor Destroy; override;
    protected
     FActive : boolean;
     FStruct  : TMapObjStruct; // Структура объекта
     FPlane   : TPlane;     // "отдалённость" объекта :)
     FObjRect      : TRect;    // Для отсечения при отрисовке
     FActivateRect : TRect;    // Активная зона объекта (для активации)
     FActivateMode : boolean;  // Метод активации
     	//true  - должен быть ВЕСЬ игрок
      	//false - должна быть лишь часть игрока
     fupdated: boolean;
      function GetActivateRect: TRect;
    public
    //ставим дефолтные таймеры
     timer: integer;

     fNetSize : byte; //в word'ах
     fOwner, fOwner2: TCustomMapObj;
     startrect: TRect;
     anim : TObjTex;           // Анимация объекта
     tag: integer;
     //но он разный в разных точках объекта.
     function Activate(sender: TObject) : boolean; virtual;
     procedure Restart; virtual;
     procedure Draw; virtual;
     procedure Update; virtual;

     property Struct: TMapObjStruct read FStruct;

     property x      : word read FStruct.x;
     property y      : word read FStruct.y;
     property width  : word read FStruct.width;
     property height : word read FStruct.height;

     property ObjType: TObjType read FStruct.ObjType;
     property Target_Name: word  read FStruct.Target_Name;
     property Target: word  read FStruct.Target;
     property Plane : TPlane read FPlane;

     property ObjRect : TRect read FObjRect write FObjRect;
     property Activated    : boolean read FActive;
     property ActivateRect : TRect read GetActivateRect;
     property ActivateMode : boolean read FActivateMode;
     property Active: boolean read factive;
     procedure SetActive(const Value: boolean);
    //сохранение состояния в структуру
     function SaveToRec(var rec: TDemoObjRec): boolean;virtual;
     procedure LoadFromRec(rec: TDemoObjRec);virtual;

     procedure SaveNet(var w: array of word);virtual;
     procedure LoadNet(w: array of word);virtual;

     function Updated: boolean;
     property Team: byte read fstruct.team;

     function targ_Activate(sender: TObject): boolean;virtual;
     function targ_Deactivate(sender: TObject): boolean;virtual;
     function player_Activate(sender: TObject): boolean;virtual;
   end;

   TGeometryObj= class(TCustomMapObj)
   public
     function Blocked : boolean; virtual;
     function BlockedAt(x, y: single) : boolean; virtual; //x, y -координаты на карте
     function PhysObj(x, y: smallint): TPhysObj; virtual; //ФИЗИЧЕСКИЙ rect. объяснять долго,

     //новые свойства физики
     procedure phys_clipX(var ph: TPhysRect);virtual;
     procedure phys_clipY(var ph: TPhysRect);virtual;
   end;


   TRespawn = class(TCustomMapObj)
   private
      timer: integer;
   public
      constructor Create(struct_: TMapObjStruct);
      function Activate(sender: TObject): boolean;override;
      procedure Restart;override;
      procedure Update;override;
      property resp_mode: byte read fstruct.resp_mode;
      property resp_weapons: TWPNArray read fstruct.resp_weapons;
      property resp_ammo: TWPNArray read fstruct.resp_ammo;
      property resp_health: byte read fstruct.resp_health;
      property resp_armor: byte read fstruct.resp_armor;
   end;

   TPortal = class(TCustomMapObj)
     constructor create(struct_: TMapObjStruct);
    public
     procedure Draw;   override;
     procedure Update; override;
     function Activate(sender: TObject): boolean; override;
   end;

   TTeleport = class(TPortal)
     constructor create(struct_: TMapObjStruct);
    public
     mirror : TObjTex;
     procedure Draw;   override;
  //   procedure Update; override;
  //   function Activate(sender: TObject): boolean; override;
   end;

   TButton = class(TCustomMapObj)
     constructor Create(struct_: TMapObjStruct);
    protected
     sound  : TSound;   // Звук при активации
     targtimer : integer;
    public
     procedure Restart; override;
     procedure Draw;    override;
     procedure Update;  override;

     function SaveToRec(var rec: TDemoObjRec): boolean;override;
     procedure LoadFromRec(rec: TDemoObjRec);override;

     procedure SaveNet(var w: array of word);override;
     procedure LoadNet(w: array of word);override;

    function targ_Activate(sender: TObject): boolean;override;
    function targ_Deactivate(sender: TObject): boolean;override;
    function player_Activate(sender: TObject): boolean;override;
   end;

//ДВЕРЬ NFK!!!!
   TNFKDoor = class(TGeometryObj)
     constructor Create(struct_:TMapObjStruct);
    protected
     soundopen  : TSound;  // Звук открытия
     soundclose : TSound;  // Звук закрытия
    public
     pl_timer : integer;
     procedure Restart; override;
     procedure Draw;    override;
     procedure Update;  override;
     function Blocked : boolean; override;
     function BlockedAt(x, y: single) : boolean; override;

    function SaveToRec(var rec: TDemoObjRec): boolean;override;
    procedure LoadFromRec(rec: TDemoObjRec);override;

     procedure phys_clipX(var ph: TPhysRect);override;
     procedure phys_clipY(var ph: TPhysRect);override;

    function targ_Activate(sender: TObject): boolean;override;
    function targ_Deactivate(sender: TObject): boolean;override;
    function player_Activate(sender: TObject): boolean;override;
   end;

   TCustomTrigger = class(TCustomMapObj)
   public
    constructor Create(struct_: TMapObjStruct);
    procedure Draw; override;
   end;

   TTrigger = class(TCustomTrigger)
      constructor Create(struct_: TMapObjStruct);
   protected
    targtimer: integer;
   public
    procedure Restart;override;
    procedure Update;override;

    function SaveToRec(var rec: TDemoObjRec): boolean;override;
    procedure LoadFromRec(rec: TDemoObjRec);override;

     procedure SaveNet(var w: array of word);override;
     procedure LoadNet(w: array of word);override;

    function targ_Activate(sender: TObject): boolean;override;
    function targ_Deactivate(sender: TObject): boolean;override;
    function player_Activate(sender: TObject): boolean;override;
   end;

   TJumpPad = class(TCustomMapObj)
     constructor Create(struct_:TMapObjStruct);
    protected
     sound : TSound;
     sndtimer: integer;
    public
     procedure Draw;   override;
     procedure Update; override;
     function Activate(sender: TObject): boolean; override;
   end;

   TDeathLineObj = class(TCustomMapObj)
   protected
     fLine: TObject;
     x0, y0: single;
     len: single;
     emptybrick: boolean;
   public
     constructor Create(struct_:TMapObjStruct);
     procedure Restart;override;
     procedure Update; override;
     procedure Draw;override;

    function targ_Activate(sender: TObject): boolean;override;
    function targ_Deactivate(sender: TObject): boolean;override;
   end;

   TLightLineObj = class(TDeathLineObj)
   public
      function targ_Activate(sender: TObject): boolean;override;
   end;

   TBricksObj = class(TGeometryObj)
     constructor Create(struct_:TMapObjStruct);
     destructor Destroy;override;
   protected
      brk, mask: array of word;
      blocks: boolean;
   public
      function Block_b(bx, by: smallint): boolean;virtual;
      function _Block_b(bx, by: smallint): boolean;virtual;
      function __Block_b(bx, by: smallint): boolean;virtual;
      procedure TakeBricks;
      procedure Draw;override;
      function Blocked: boolean;override;
   end;

   TElevatorObj = class(TBricksObj)
   protected
     stopped: boolean;
     timer, t0: integer;
     elevstopping: boolean;
     pos, dpos, fracpos: TPoint2f;
     //глобальные параметры
     v0, a, l0: single;//скорость, ускорение и общий путь

     v : single; //текущая скорость
     h: smallint; //идёт туда или обратно?
   public
     constructor Create(struct_:TMapObjStruct);
     procedure Restart;override;
     procedure Draw;override;
     procedure Update;override;

     procedure Go;virtual;
     procedure FixPos;

     function Speed: TPoint2f;

     function OnTarget1(sender: TObject): boolean;
     function OnTarget2(sender: TObject): boolean;
     function Activate(sender: TObject): boolean; override;
     function PhysObj(x, y: smallint) : TPhysObj; override;
     function BlockedAt(x, y: single) : boolean; override;

     procedure phys_clipX(var ph: TPhysRect);override;
     procedure phys_clipY(var ph: TPhysRect);override;

     function SaveToRec(var rec: TDemoObjRec): boolean;override;
     procedure LoadFromRec(rec: TDemoObjRec);override;

     procedure SaveNet(var w: array of word);override;
     procedure LoadNet(w: array of word);override;
   end;

   TTrainPointObj = class(TCustomMapObj)
   private
      ftimer, ftargtimer: integer;
   public

     constructor Create(struct_:TMapObjStruct);
      property NextPoint: word read fstruct.tpnext;
      property Index: word read fstruct.tpindex;
     function Activate(sender: TObject): boolean;override;
     procedure ActivateTrain;
     procedure Update;override;
     property ChangeOrient: boolean read fstruct.orientchange;
     property ChangeSpeed: boolean read fstruct.speedchange;
     property Speed: single read fstruct.speedvalue;
     procedure restart;override;

     procedure SaveNet(var w: array of word);override;
     procedure LoadNet(w: array of word);override;

     function SaveToRec(var rec: TDemoObjRec): boolean;override;
     procedure LoadFromRec(rec: TDemoObjRec);override;
   end;

   TTrainObj = class(TElevatorObj)
   private
//      nextpoint: TTrainPointObj;
      speed: single;
      train_orient: integer;
   public
     constructor Create(struct_:TMapObjStruct);

     procedure Go;override;
     function SaveToRec(var rec: TDemoObjRec): boolean;override;
     procedure LoadFromRec(rec: TDemoObjRec);override;
     procedure Update;override;
     procedure Restart;override;

     procedure SaveNet(var w: array of word);override;
     procedure LoadNet(w: array of word);override;
   end;

   TBelt = class (TBricksObj)
   private
     smx, smy: single;
     minx, miny: integer;
     bx, by: integer;
   public
     sspeed: TPoint2f;
     constructor Create(struct_:TMapObjStruct);
     function SaveToRec(var rec: TDemoObjRec): boolean;override;
     procedure LoadFromRec(rec: TDemoObjRec);override;
     procedure SaveNet(var w: array of word);override;
     procedure LoadNet(w: array of word);override;

     procedure Update;override;
     procedure Restart;override;
     procedure Draw;override;

     function PhysObj(x, y: smallint) : TPhysObj; override;
     function BlockedAt(x, y: single) : boolean; override;

     function Block_b(bx, by: smallint): boolean;override;
     function __Block_b(bx, by: smallint): boolean;override;
   end;

   TAnimationObj = class(TBricksObj)
   protected
     anim: integer;
   public
     procedure Update;override;
     procedure Restart;override;
     procedure Draw;override;
     function BlockedAt(x, y: single) : boolean; override;

    	function SaveToRec(var rec: TDemoObjRec): boolean;override;
    	procedure LoadFromRec(rec: TDemoObjRec);override;
   end;

   TTriangleObj =
   class(TGeometryObj)
   protected
      vx, vy: array [0..3] of smallint;
      tex: byte;
   public
      normal: TPoint2f;
      constructor Create(struct_:TMapObjStruct);
      function BlockedAt(x, y: single): boolean;override;
      function PhysObj(x, y: smallint): TPhysObj;override;
      procedure phys_clipX(var ph: TPhysRect);override;
      procedure phys_clipY(var ph: TPhysRect);override;

      function VectorIntersect(x, y, angle: single; var s: single): boolean;
      procedure Draw;override;
   end;

   TAreaPain =class(TCustomTrigger)
   protected
   	paintimer:word;
   public
    	procedure Restart;override;
    	procedure Update;override;
    	function SaveToRec(var rec: TDemoObjRec): boolean;override;
    	procedure LoadFromRec(rec: TDemoObjRec);override;

      function player_Activate(sender: TObject): boolean;override;
   end;

   TArenaEnd =class(TCustomTrigger)
   public
    	function Activate(sender: TObject): boolean; override;
   end;

   TAreaPush = class(TCustomTrigger)
   protected
      pushtimer: integer;
   public
      procedure Restart; override;
      procedure Update;override;

      function player_Activate(sender: TObject): boolean;override;
   end;

   TAreaTeleport = class(TCustomTrigger)
   public
    	function Activate(sender: TObject): boolean; override;
   end;

   TAreaTeleportWay = class(TCustomTrigger)
   public
      constructor Create(struct_:TMapObjStruct);
      function Activate(sender: TObject): boolean;override;
   end;

   TBloodGen = class(TCustomMapObj)
   private
      spos, sdpos: TPoint2f;
      timer: integer;
     light: TP_Light;
   public
      constructor Create(struct_: TMapObjStruct);
      procedure Restart;override;
      procedure Update;override;
      procedure draw;override;

      function targ_Activate(sender: TObject): boolean;override;
      function targ_Deactivate(sender: TObject): boolean;override;
   end;

   TCustomLiquid = class(TCustomMapObj)
     constructor Create(struct_: TMapObjStruct);
    private
      Speed   : single; // Скорость течения
      Density : single; // Плотность
      Tex     : TObjTex;
      level, up: integer;// уровень жидкости!!!
    public
      procedure Update;override;
      procedure Restart;override;
      procedure Draw;override;

      function targ_Activate(sender: TObject): boolean;override;
   end;

   TWaterObj = class(TCustomLiquid)
     constructor Create(struct_: TMapObjStruct);
     destructor Destroy; override;
    private
     State  : boolean;
     Wait   : integer;
     Waves  : array [boolean] of array of integer; // волны
    public
     function player_Activate(sender: TObject): boolean; override;
     procedure Update;override;
     procedure Draw;override;
     procedure Restart;override;
     procedure Smooth;
     procedure Wave(x, a: integer);//в каком x поставить волну, и какую
     procedure Wave2(x, a: integer);//сложение волн

    	function SaveToRec(var rec: TDemoObjRec): boolean;override;
    	procedure LoadFromRec(rec: TDemoObjRec);override;
   end;

   TLavaObj = class(TCustomLiquid)
     constructor Create(struct_: TMapObjStruct);
     destructor Destroy; override;
    private
     lTex     : TObjTex;
     Wave     : array [0..2] of array of array of single;
     W_X, W_W : integer;
     W_Y, W_H : integer;
    public
     function player_Activate(sender: TObject): boolean; override;
     procedure Update;override;
     procedure Draw;override;
   end;

   TWeather = class(TCustomMapObj)
     constructor Create(struct_: TMapObjStruct);
   private
     timer: integer;
   public
     procedure Restart; override;
     procedure Update; override;
     procedure Draw; override;
   end;

   TSoundTrigger = class(TCustomMapObj)
      constructor Create(struct_: TMapObjStruct);
   protected
      snd   : integer;
      psnd  : integer;
      timer : integer;
   public
      function Activate(sender: TObject): boolean; override;
      procedure Draw;override;
      procedure Update;override;
      procedure restart;override;
   end;

   TDestroyerObj = class(TCustomTrigger)
      constructor Create(struct_: TMapObjStruct);
   protected
      brk, mask: array of word;
      health: integer;
   public
      function Activate(sender: TObject): boolean; override;
      function Hit(damage: integer): boolean;
      procedure Charge;
      procedure DestroyIt;
      procedure TakeBricks;
      procedure Draw;override;
      procedure restart;override;

     function SaveToRec(var rec: TDemoObjRec): boolean;override;
     procedure LoadFromRec(rec: TDemoObjRec);override;

     procedure SaveNet(var w: array of word);override;
     procedure LoadNet(w: array of word);override;
   end;

   TMonsterObj = class(TCustomMapObj)
      constructor Create(struct_: TMapObjStruct);
   protected
      xx, yy, sx, sy, speed, angle: single;
      health: integer;
      w, h: integer;
      pl: TObject;
      timer, smoketimer: integer;
      alpha: single;
      frame: integer;
      fire: integer;
      light: TP_Light;
      delta: single;
      resp: boolean;
   public
      function Activate(sender: TObject): boolean; override;
      procedure Draw;override;
      function Hit(damage: integer): boolean;
      function Blocked: boolean;
      procedure Update;override;
      procedure restart;override;

     function SaveToRec(var rec: TDemoObjRec): boolean;override;
     procedure LoadFromRec(rec: TDemoObjRec);override;
   end;

function ObjStruct(otype: TObjType; x, y, w, h: integer): TMapObjStruct;
function ObjGameMask(struct: TMapObjStruct): byte;

implementation

uses
 Map_Lib, player_lib, Real_Lib, weapon_Lib, ItemObj_Lib,
 	TFKEntries, Phys_Lib, Bot_Lib, Math, Game_Lib;

function ObjGameMask(struct: TMapObjStruct): byte;
begin
   if struct.objtype in GameALLObjs then
      Result:=255
   else
   begin
      Result:=0;
      if struct.objtype in GameNotRAObjs then
         Result:=Result+255-GT_RAIL
      else
      begin
         if struct.objtype in GameTDMObjs then
            Result:=Result+GT_TDM;
         if struct.objtype in GameCTFObjs then
            Result:=Result+GT_CTF;
         if struct.objtype in GameDOMObjs then
            Result:=Result+GT_DOM;
         if struct.objtype in GameTRIXObjs then
            Result:=Result+GT_TRIX;
         if struct.objtype in GameSPObjs then
            Result:=Result+GT_SINGLE;
      end;
   end;
end;

function ObjStruct(otype: TObjType; x, y, w, h: integer): TMapObjStruct;
begin
   Result.ObjType:=otype;
   Result.x:=x;
   Result.y:=y;
   Result.width:=w;
   Result.height:=h;
end;

var
 // Указывает, что в данный момент отрисовывается телепорт...
 // Типа глобальный флаг, но нужен только телепортам :)
 TeleportDraw : boolean;

{ TCustomMapObj }

constructor TCustomMapObj.Create(struct_: TMapObjStruct);
begin
FStruct := Struct_;

FPlane := pNone; //XProger: Это пока временно...

FObjRect := Rect(0, 0, 0, 0);
FActivateRect := Rect(0, 0, 0, 0);
FActivateMode := false;
FActive:=false;

fNetSize:=0;
fOwner:=nil;
end;

destructor TCustomMapObj.Destroy;
begin
if anim <> nil then
 anim.Free;
end;

function TCustomMapObj.Activate(sender: TObject):boolean;
begin
//активация объекта кнопкой или чем-либо еще
   if sender is TPlayer then
   begin
      Result:=player_Activate(sender);
      if not Result then Exit;
   end;
   if timer>0 then
         Result:=false
      else
   begin
      if factive then
         Result:=targ_Deactivate(sender)
      else
         Result:=targ_Activate(sender);
      if Result then
         timer:=fstruct.wait;
   end;
end;

procedure TCustomMapObj.Restart;
begin
   factive:=fstruct.active and 4>0;
   timer:=0;
end;

procedure TCustomMapObj.Draw;
begin
// XProger: Рисует объект по его ObjRect
// 		В предках вызывается как inherited
// Neoff: TCustomMapObj не имеет предков... только потомков ;)
// XProger: да подумаешь, описался... ;)

if (FObjRect.Width = 0) or (FObjRect.Height = 0) then Exit;

 glBegin(GL_QUADS);
  glTexCoord2f(0, height);
   glVertex2f(FObjRect.X, FObjRect.Y);
  glTexCoord2f(width, height);
   glVertex2f(FObjRect.X + FObjRect.Width, FObjRect.Y);
  glTexCoord2f(width, 0);
   glVertex2f(FObjRect.X + FObjRect.Width, ObjRect.Y + ObjRect.Height);
  glTexCoord2f(0, 0);
   glVertex2f(FObjRect.X, ObjRect.Y + ObjRect.Height);
 glEnd;
end;

procedure TCustomMapObj.Update;
begin
if fOwner <> nil then
 begin
 fObjRect.X := startrect.X + (fOwner.ObjRect.X - fOwner.startrect.X);
 fObjRect.Y := startrect.Y + (fOwner.ObjRect.Y - fOwner.startrect.Y);
 end;
   if timer>0 then
   begin
      dec(timer);
      if timer=0 then
         if factive then targ_Deactivate(Self)
         else targ_Activate(self);
   end;
end;

function TCustomMapObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   Result:=true;
   rec.reserved[0]:=timer and 32767+ord(factive)*32768;
end;

procedure TCustomMapObj.LoadFromRec(rec: TDemoObjRec);
begin
   timer:=rec.reserved[0] and 32767;
   factive:=rec.reserved[0] and 32768>0;
   if factive then targ_Activate(Self);
end;

function TCustomMapObj.GetActivateRect: TRect;
begin
Result.Width  := FActivateRect.Width;
Result.Height := FActivateRect.Height;
Result.X := X * 32 + FActivateRect.X + FObjRect.X - startrect.X;
Result.Y := Y * 16 + FActivateRect.Y + FObjRect.Y - startrect.Y;
end;

function TCustomMapObj.Updated: boolean;
begin
   result:=fupdated;
   fupdated:=false;
end;

procedure TCustomMapObj.LoadNet(w: array of word);
begin
   timer:=w[0] and 32767;
   factive:=w[0] and 32768>0;
   if factive then targ_Activate(Self);
end;

procedure TCustomMapObj.SaveNet(var w: array of word);
begin
   w[0]:=timer and 32767+ord(factive)*32768;
end;

procedure TCustomMapObj.SetActive(const Value: boolean);
begin
  factive := Value;
end;

function TCustomMapObj.player_Activate(sender: TObject): boolean;
begin
   //
   Result:=true;
end;

function TCustomMapObj.targ_Activate(sender: TObject): boolean;
begin
   Result:=true;
   factive:=true;
end;

function TCustomMapObj.targ_Deactivate(sender: TObject): boolean;
begin
   Result:=true;
   factive:=false;
end;

{ TGeometryObj }

function TGeometryObj.Blocked: boolean;
begin
   //abstract
   Result:=false;
end;

function TGeometryObj.BlockedAt(x, y: single): boolean;
begin
   //abstract
   Result:=false;
end;

function TGeometryObj.PhysObj(x, y: smallint): TPhysObj;
begin
   //abstract
with Result, frect do
 begin
 x1 := fObjRect.x;
 y1 := fObjRect.y;
 x2 := fObjRect.x + FObjRect.Width;
 y2 := fObjRect.y + FObjRect.Height;
 dpos       := @NullPoint;
 normal     := NullPoint;
 floatpos   := NullPoint;
 dis_bottom := false;
 dis_top    := false;
 dis_hor    := false;
 end;
end;


procedure TGeometryObj.phys_clipX(var ph: TPhysRect);
begin

end;

procedure TGeometryObj.phys_clipY(var ph: TPhysRect);
begin

end;

{ TOldTeleport }

constructor TPortal.Create(struct_: TMapObjStruct);
const
 xstep = 5; // Для просчёта активационного ректа
 ystep = 4;
begin
inherited Create(struct_);
//грузим текстуру
anim := TObjTex.Create('textures\obj\portal', 1, 0, 5, true, false, nil);

FObjRect      := Rect(x*32 - 16, y*16 - 32, 64, 64);
FActivateRect := Rect(-xstep, -32-ystep, 32+2*xstep, 48+2*ystep);
FActivateMode := true;
StartRect     := ObjRect;
end;

function TPortal.Activate(sender: TObject):boolean;
begin
Result := false;
if sender is TPlayer then
 with TPlayer(sender) do
  begin
  Particle_Add(TP_Portal.Create(Pos)); // вспышка
  if fOwner2<>nil then
   begin
   MoveTo(
    	struct.gotox*32 + fOwner2.fobjrect.x - fOwner2.startrect.x,
 			struct.gotoy*16 + fOwner2.fobjrect.y - fOwner2.startrect.y);
    dPos:=Point2f(dpos.x+TElevatorObj(fOwner2).dpos.x, TElevatorObj(fOwner2).dpos.y);
   end
 else
  begin
 	MoveTo(struct.gotox*32, struct.gotoy*16);
   dpos:=Point2f(dpos.x, 0);
  end;
 if odd(fstruct.orient) then RotateX;
 if fstruct.orient>=2 then RotateY;
 Result := true;
 end;
end;

procedure TPortal.Draw;
begin
// рисуем телепорт
xglTex_Enable(anim.CurFrame);
glColor4f(1, 1, 1, 1);
inherited;
end;

procedure TPortal.Update;
begin
anim.Update;
inherited;
end;

{ TTeleport }

constructor TTeleport.Create(struct_: TMapObjStruct);
const
 xstep = 5; // Для просчёта активационного ректа
 ystep = 4;
begin
inherited Create(struct_);
//грузим текстуру
mirror := TObjTex.Create('textures\obj\mirror', 1, 0, 5, true, false, nil);
anim   := TObjTex.Create('textures\obj\teleport', 1, 0, 5, true, false, nil);
FObjRect      := Rect(x*32 - 16, y*16 - 32, 64, 64);
FActivateRect := Rect(-xstep, -32-ystep, 32+2*xstep, 48+2*ystep);
FActivateMode := true;
StartRect     := ObjRect;
end;

procedure TTeleport.Draw;

 procedure DrawMirror;
 var
  tex : TObjTex;
 begin
 glEnable(GL_ALPHA_TEST);
 glAlphaFunc(GL_GEQUAL, 0.5);
 glColorMask(false, false, false, false);
 xglTex_Enable(mirror.CurFrame);
 glColor4f(1, 1, 1, 1);
 tex := anim;
 anim := mirror;
 inherited;
 anim := tex;
 glColorMask(true, true, true, true);
 glDisable(GL_ALPHA_TEST);
 end;

var
 sx, sy : single;
 p, v   : TPoint2f;  // Pos и View камеры
 Scale  : TPoint2f;
 Size   : TPoint2f;
begin
// Рекурсия в глубину = 1
// Это типа ограничение :)
if not TeleportDraw then
 begin
// Всё... телепорт рисую...
// т.е. его "зеркало" :)
 TeleportDraw := true;
// Внимание!!!
//  Дабы избежать головных болей - советую не читать код этой процедуры ;)
 glEnable(GL_STENCIL_TEST);
  glStencilFunc(GL_ALWAYS, 1, 1);
  glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);
  Size.X := 16;
  Size.Y := 48;
 // Щас нарисуем участок - полигон, "зеркала"
  // Рисуем зеркало в стенсил буффер
  DrawMirror;
 // А теперь осталось сдвинуть/уменьшить карту и отрисовать
 // только в этом участке
 // Переключаем режим стенсил буффера
  glStencilFunc(GL_EQUAL, 1, 1);
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
 // поехали... :)
  glPushMatrix; // запомнили все сдвиги/повороты/увеличения
   glLoadIdentity;
  // На сколько "увеличиваем"
   Scale.X := 0.25;
   Scale.Y := 0.25;
  // смещение и "увеличение"
   sx := - Map.Camera.Pos.X + x*32 - struct.gotox*32*Scale.X + 16;
   sy := - Map.Camera.Pos.Y + y*16 - struct.gotoy*16*Scale.Y - 8;//   if dis_view then
   if dis_view then
    glTranslatef(xglWidth div 2 + sx, xglHeight div 2 + sy, 0)
   else
    glTranslatef(320 + sx, 240 + sy, 0);
  // смещение при сплитскрине
   glScale(Scale.X, Scale.Y, 1);
   if dis_view then
    case SplitScreen of
     SPLIT_HORIZ : glTranslatef(0, -xglHeight, 0);
     SPLIT_VERT  : glTranslatef(-xglWidth, 0, 0);
    end
   else
    case SplitScreen of
     SPLIT_HORIZ : glTranslatef(0, -480, 0);
     SPLIT_VERT  : glTranslatef(-640, 0, 0);
    end;
  // относительно положения камеры рисуется задний план...
   p := Map.Camera.Pos;
   v := Map.Camera.View;
   Map.Camera.Pos.X  := struct.gotox * 32 + 16;
   Map.Camera.Pos.Y  := struct.gotoy * 16 + 8;
   Map.Camera.View.X := Size.X/Scale.X;
   Map.Camera.View.Y := Size.Y/Scale.Y/2;
  // Отрисовываем карту, без смещения на радиус-вектор положения камеры...
   Map.SubDraw;
  // восстанавливаем параметры камеры
   Map.Camera.Pos  := p;
   Map.Camera.View := v;
  glPopMatrix; // матрицу на место!
 // Чистим за собой стенсил :)
 // Сделанно чтобы не чистить буффер полностью каждый раз 8)
 // переключаем на "уничтожение" =)
  glStencilFunc(GL_ALWAYS, 0, 0);
  glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);
 // Чтобы не стереть столь тяжким трудом отрисованное
 // не рисуем ничего! :) Но в стенсил это нарисуется :)
  DrawMirror;
 glDisable(GL_STENCIL_TEST); // и ты тоже :)
 glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
 TeleportDraw := false;
 end;
inherited;
end;


{ TButton }

constructor TButton.Create(struct_: TMapObjStruct);
begin
inherited;
fNetSize	:=	2;
anim  := TObjTex.Create('textures\obj\buttons', 1, 0, 5, true, false, nil);
sound := TSound.Create('sound\button.wav', false);
anim.FrameIndex := struct.color + 1;

FObjRect      := Rect(x*32, y*16 - 8, 32, 32);
FActivateRect := Rect(4, 4, 24, 24);
end;

procedure TButton.Restart;
begin
inherited;
targtimer := 0;
factive   := false;
end;

procedure TButton.Draw;
var
 delta : integer;
begin
//рисуем неактивированную кнопку
if Activated then
 begin
   delta := struct.wait - timer;
   if delta > 16 then
      delta := 16;
   if timer < 16 then
      delta := Timer;
 end
else
   delta := 0;

//delta = 16 - полная прозрачность текстуры неактивированной кнопки
if r_buttons_mode = 1 then
   xglTex_Enable(anim.Frame[struct.color*2+1])
else xglTex_Enable(anim.Frame[0]);
glColor4f(1, 1, 1, 1);
// XProger: зачем рисовать нижний слой, если
//  его полностью загораживает верхний?
if delta <> 16 then // XProger: вот так будет оптимальнее
 inherited;
if Activated then
 begin
 if r_buttons_mode = 1 then
   xglTex_Enable(anim.Frame[(struct.color+1)*2])
 else xglTex_Enable(anim.CurFrame);
 glColor4f(1, 1, 1, delta/16);
 inherited;
 end;
end;

procedure TButton.Update;
begin
   if TargTimer > 0 then
   begin
      Dec(TargTimer);
      if TargTimer = 0 then
         Map.ActivateTarget(fstruct.target);
   end;
   inherited;
end;

procedure TButton.LoadFromRec(rec: TDemoObjRec);
begin
   timer := rec.reserved[0];
   targtimer := rec.reserved[1];
   factive:=timer>0;
end;

function TButton.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   Result := true;
   rec.reserved[0] := timer;
   rec.reserved[1] := targtimer;
end;

procedure TButton.LoadNet(w: array of word);
begin
   inherited LoadNet(w);
   targtimer:=w[1];
end;

procedure TButton.SaveNet(var w: array of word);
begin
   inherited SaveNet(w);
   w[1]:=targtimer;
end;

function TButton.player_Activate(sender: TObject): boolean;
begin
   Result:=true;
end;

function TButton.targ_Activate(sender: TObject): boolean;
begin
   if Sender is TPlayer then
 	   Sound.Play(TPlayer(sender).Pos.X, TPlayer(sender).Pos.Y)
   else
 	   Sound.Play(x*32+16, y*16+8);
   if targtimer=0 then
   begin
      targtimer:=fstruct.waittarget;
      if fstruct.waittarget=0 then
         Map.ActivateTarget(fstruct.target);
   end;
   factive:=true;
   Result:=true;
end;

function TButton.targ_Deactivate(sender: TObject): boolean;
begin
   factive:=false;
   Result:=true;
end;

{ TNFKDoor }

constructor TNFKDoor.Create(struct_: TMapObjStruct);
const
 xstep = 2;
 ystep = 2;
begin
inherited;
fNetSize:=1;
if struct.orient < 2 then//вертикальная
 anim := TObjTex.Create('textures\obj\door1', 32, 16, 1, false, false, nil)
else
 anim := TObjTex.Create('textures\obj\door2', 32, 16, 1, false, false, nil);

soundOpen  := TSound.Create('sound\door_open.wav', false);
soundClose := TSound.Create('sound\door_close.wav', false);

FObjRect      := Rect(x*32, y*16, 32*width, 16*height);
FActivateRect := Rect(xstep, ystep, 32*width-2*xstep, 16*height-2*ystep);
end;

function TNFKDoor.Blocked: boolean;
begin
Blocked := fActive;
end;

procedure TNFKDoor.Restart;
begin
inherited;
if not fstruct.opened then
   factive:=true;
if anim <> nil then
 if FActive then
  anim.FrameIndex := 0
 else
  anim.PrevFrame;
end;

procedure TNFKDoor.Draw;
begin
//считаем timer
if anim.FrameIndex < anim.FrameCount - 1 then
 begin
 xglTex_Enable(anim.CurFrame);
 glColor4f(1, 1, 1, 1);
 inherited;
 end;
end;

procedure TNFKDoor.Update;
begin
inherited;
if pl_timer>0 then dec(pl_timer);
if factive then
 begin
 if (anim.FrameIndex > 0) then
  anim.UpdateReverse;
 end
else
 if (anim.FrameIndex < anim.FrameCount - 1) then
  anim.Update;
end;

procedure TNFKDoor.LoadFromRec(rec: TDemoObjRec);
begin
FActive := Boolean(rec.reserved[0]);
timer   := rec.reserved[1];
anim.FrameIndex := rec.reserved[2];
end;

function TNFKDoor.SaveToRec(var rec: TDemoObjRec): boolean;
begin
Result := true;
rec.reserved[0] := Word(FActive);
rec.reserved[1] := timer;
rec.reserved[2] := anim.FrameIndex;
end;

function TNFKDoor.BlockedAt(x, y: single): boolean;
begin
x := round(x);
y := round(y);
x := x - FObjRect.X;
y := y - FObjRect.Y;
Result := fActive
          and (x >= 0)
          and (x <= SmallInt(FObjRect.Width))
          and (y >= 0)
          and (y <= smallint(FObjRect.Height));
end;

procedure TNFKDoor.phys_clipX(var ph: TPhysRect);
begin
   //потом что-нибудь напишем
end;

procedure TNFKDoor.phys_clipY(var ph: TPhysRect);
begin

end;

function TNFKDoor.player_Activate(sender: TObject): boolean;
begin
 	if not factive and (timer > 0) and (timer < 25) then
 		timer  := 50;
   pl_timer := 2;
   Result := false;
end;

function TNFKDoor.targ_Activate(sender: TObject): boolean;
begin
   Result:=pl_timer=0;
   if Result then
   begin
      factive:=true;
      if SoundOpen <> nil then
         SoundOpen.Play(X * 32 + 16, Y * 16 + 8);
   end;
end;

function TNFKDoor.targ_Deactivate(sender: TObject): boolean;
begin
   Result:=true;
   factive:=false;
   if SoundClose <> nil then
      SoundClose.Play(X * 32 + 16, Y * 16 + 8);
end;

{ TCustomTrigger }

constructor TCustomTrigger.Create(struct_: TMapObjStruct);
const
 xstep = 4;
 ystep = 2;
begin
	inherited;
	FObjRect      := Rect(x*32, y*16, width*32, height*16);
	FActivateRect := Rect(xstep, ystep, width*32-2*xstep, height*16-2*ystep);
	StartRect:=ObjRect;
end;

procedure TCustomTrigger.Draw;
begin
   //abstract
end;

{ TTrigger }

constructor TTrigger.Create(struct_: TMapObjStruct);
begin
   inherited;
   fNetSize:=2;
end;

procedure TTrigger.LoadFromRec(rec: TDemoObjRec);
begin
//timer := rec.reserved[0];
timer := rec.reserved[0];
targtimer := integer(rec.reserved[1]);
end;

procedure TTrigger.LoadNet(w: array of word);
begin
   timer:=w[0];
   targtimer:=w[1];
end;

function TTrigger.player_Activate(sender: TObject): boolean;
begin
   Result:=not fstruct.onlyplayer or
         (TPlayer(sender).playertype and C_PLAYER_LOCAL>0);
end;

procedure TTrigger.Restart;
begin
   inherited;
   targtimer := 0;
   if factive then
      targ_Activate(Self);
end;

procedure TTrigger.SaveNet(var w: array of word);
begin
   w[0]:=timer;
   w[1]:=targtimer;
end;

function TTrigger.SaveToRec(var rec: TDemoObjRec): boolean;
begin
Result := true;
rec.reserved[0] := timer;
rec.reserved[1] := targtimer;
end;

function TTrigger.targ_Activate(sender: TObject): boolean;
begin
   if targtimer=0 then
      targtimer := fstruct.waittarget;
   if targtimer=0 then
   begin
      Map.ActivateTarget(fstruct.target);
      if fstruct.execcmd<>'' then
         queue_add(fstruct.execcmd);
   end;
   factive:=fstruct.wait>0;
   Result:=true;
end;

function TTrigger.targ_Deactivate(sender: TObject): boolean;
begin
   Result:=true;
   factive:=false;
end;

procedure TTrigger.Update;
begin
inherited;
if targtimer > 0 then
begin
   dec(targtimer);
   if targtimer = 0 then
   begin
      Map.ActivateTarget(fstruct.target);
      if fstruct.execcmd<>'' then
         queue_add(fstruct.execcmd);
   end;
end;

end;

{ TJumpPad }

constructor TJumpPad.Create(struct_: TMapObjStruct);
const
 xstep = 16;
 ystep = 5;
begin
inherited;
with fstruct do
  if ItemID<>100 then
  if (jumpspeed<4.7) then
     ItemID:=38
  else ItemID:=39;

anim   := TObjTex.Create('textures\obj\jumppad', 2, 0, 2, true, false, nil);
sound  := TSound.Create('sound\jumppad.wav', false);

FObjRect := Rect(x*32, y*16, 32, 16);
FActivateMode:=true;
{if transy then
 FActivateRect := Rect(-xstep, -32-ystep, 32+2*xstep, 32+2*ystep)
else}
 FActivateRect := Rect(-xstep, -32-ystep, 32+2*xstep, 48+2*ystep);
end;

function TJumpPad.Activate(sender: TObject):boolean;
var
 sp, spx: single;
begin
with fstruct do
 if ItemID = 39 then
 begin
 	jumpspeed := jumppad_2;
//   jumpspeedx:=0;
 end
 else
 if ItemID = 38 then
 begin
 	jumpspeed := jumppad_1;
//   jumpspeedx:=0;
 end;

Result := false;
sp := -struct.jumpspeed;
spx := struct.jumpspeedx;
if fOwner <> nil then
begin
 sp := sp + TElevatorObj(fOwner).dpos.Y;
 spx:= spx+ TElevatorObj(fOwner).dpos.X;
end;
if sender is TPlayer then
 begin
 with TPlayer(sender) do
  begin
  if crouch and (pos.Y + 12 < Y * 16) then Exit;
  if (abs(dpos.x)<abs(spx)) or (dpos.X*spx<-1.0E-2) then
     dpos:= Point2f(spx, sp)
     else dpos := Point2f(dpos.x, sp);
  onground := false;
  end;
 if sndtimer = 0 then
  begin
  Sound.Play(X * 32 + 16, Y * 16 + 8);
  sndtimer := 5;
  end;
 Result := true;
 end;
end;

procedure TJumpPad.Draw;
begin
xglTex_Enable(anim.CurFrame);
glColor4f(1, 1, 1, 1);
inherited;
end;

procedure TJumpPad.Update;
begin
if sndtimer>0 then dec(sndtimer);
anim.Update;
inherited;
end;

{ TDeathLine }

constructor TDeathLineObj.Create(struct_: TMapObjStruct);
var
   s0     : single;
   s, c   : single;
begin
inherited;
fNetSize := 1;
FObjRect := Rect(x*32, y*16, 0, 0);

 emptybrick:=Map.Brk[x, y]=0;
 // XProger: типа оптимизация :)
 s := sin(fstruct.angle);
 c := cos(fstruct.angle);
 s0 := 100;
 x0 := 16 + 32*c;
 y0 := 8 + 32*s;
 if not emptybrick then
 begin
 	RectVectorIntersect(Rect(0, 0, 32, 16), x0, y0, fstruct.angle + Pi, s0);
   s0:=s0-0.75;
 end
   else s0:=32;
 x0 := x0 - s0*c;
 y0 := y0 - s0*s;
 len:=fstruct.maxlen+(s0-32);

end;

procedure TDeathLineObj.Draw;
begin
//abstract;
end;

procedure TDeathLineObj.Restart;
begin
   if fstruct.active=0 then
      fstruct.active:=4;
   inherited;
   fline   := nil;
   if factive then
      targ_Activate(Self);
end;

function TDeathLineObj.targ_Activate(sender: TObject): boolean;
var
 struct : TRealObjStruct;
 Obj    : TDeathLine;
begin
   if fline<>nil then
   begin
      Result:=false;
      Exit;
   end;
 struct.x := x*32 + x0;
 struct.y := y*16 + y0;
 struct.angle     := fstruct.angle;
 struct.playerUID := 0;
 Obj := TDeathLine.Create(struct, self);
 Obj.damage     := fstruct.damage;
 Obj.damagewait := fstruct.damagewait;
 Obj.maxlen     := len;
 Obj.Color:=NumToColor(fstruct.orient);
 fLine := Obj;
 RealObj_Add(Obj);
 factive:= true;
 Result := true;
end;

function TDeathLineObj.targ_Deactivate(sender: TObject): boolean;
begin
   TRealObj(fLine).Kill;
   fLine  := nil;
   factive:= false;
   Result := true;
end;

procedure TDeathLineObj.Update;
begin
inherited;
if fActive and (fLine <> nil) then
 with TRealObj(fLine) do
  begin
  x := FObjRect.X + x0;
  y := FObjRect.Y + y0;
  end;
end;

{ TElevatorObj }

function TElevatorObj.Activate(sender: TObject): boolean;
begin
	if fstruct.active > 0 then
 		factive := not fstruct.eactive;
	Result := true;
end;

function TElevatorObj.BlockedAt(x, y: single): boolean;
var
 bx, by: byte;
begin
Result := false;
if (signf(x - pos.x) < 0) or
   (signf(y - pos.y) < 0) then Exit;

// XProger: блин, так для ровнения и проверки столкновений мы должны
// использовать одинаковую функцию trunc или round!!! Так что же?
bx := trunc((x - pos.x)/32);
by := trunc((y - pos.y)/16);
{
if (signf(x - fobjrect.x) < 0) or
   (signf(y - fobjrect.y) < 0) then Exit;
bx := trunc((x - fobjrect.x)/32);
by := trunc((y - fobjrect.y)/16);
}
Result := (bx < Width)  and
          (by < Height) and
          (Mask[bx + by*width] and MASK_BLOCK>0);
end;

constructor TElevatorObj.Create(struct_: TMapObjStruct);
begin
inherited;

with fstruct do
 begin
 pos.X := FObjRect.X;
 pos.Y := FObjRect.Y;
 l0 := Sqrt(sqr(elevx*32)+sqr(elevy*16));
 v0 := elevspeed;
 a := v0/25;
 t0 := round(l0/v0);
 if t0 <= 0 then t0 := 1;
 h:=1;//идёт ТУДА
 v:=0;

 elevstopping := (etargetname1 <> NULLTARGET) or
                 (etargetname2 <> NULLTARGET);
 stopped := elevstopping;
 factive := eactive;
 end;
timer := 0;
dpos  := NullPoint;

fNetSize:=2;
end;

procedure TElevatorObj.Draw;
begin
// XProger: т.к. игрок перед отрисовкой делает своим координатам round
// может и лифту то же сделать?
// типа здесь временно будут храниться X и Y ректа отрисовки
// настоящие значения округляются, а после отрисовки принимают
// прежнее значение...
// Neoff: угу, только вот рисует он FObjRect.X, FObjRect.Y а это уже целые!
glcolor4f(1, 1, 1, 1);
inherited;
end;

procedure TElevatorObj.FixPos;
begin
	FObjRect.X := round(pos.X);
	FObjRect.Y := round(pos.Y);
	fracpos.X  := frac(pos.X);
	fracpos.Y  := frac(pos.Y);
end;

procedure TElevatorObj.Go;
begin
   with fstruct do
   begin
   if not phys_flag then
   begin
  	   inc(timer);

   if timer<=t0 then
   begin
   	if signf(v-v0)<0 then
      begin
         v:=v+a;
         if v>v0 then
            v:=v0;
      end;
  	end else
  	begin
  		v:=v-a;
   	if signf(v)<0 then
      begin
      	v:=0; timer:=0;
         h:=-h;
         if h=-1 then
   			Map.ActivateTarget(etarget1)
            else Map.ActivateTarget(etarget2);
         stopped:=elevstopping;
      end;
  	end;

   end;

	dpos.X:=v*h*elevx*32/l0;
	dpos.Y:=v*h*elevy*16/l0;

   pos.X := pos.X + dpos.X/phys_freq;
   pos.Y := pos.Y + dpos.Y/phys_freq;
   end;
end;

procedure TElevatorObj.LoadFromRec(rec: TDemoObjRec);
var
   i: integer;
begin
Restart;
i := rec.reserved[0];
stopped := rec.reserved[1] and 1>0;
factive := rec.reserved[1] and 2>0;
if rec.reserved[1] shr 2>0 then h:=-1
   else h:=1;
   
if h=-1 then
begin
   pos.X:=(fstruct.x+fstruct.elevx)*32;
   pos.Y:=(fstruct.y+fstruct.elevy)*16;
end;
while timer<i do
   Go;
FixPos;
end;

procedure TElevatorObj.LoadNet(w: array of word);
var
   i: integer;
begin
	Restart;
	i := w[0];
	stopped := w[1] and 1>0;
	factive := w[1] and 2>0;
   if w[1] and 4>0 then h:=-1
   else h:=1;
 	if h=-1 then
	begin
   	pos.X:=(fstruct.x+fstruct.elevx)*32;
   	pos.Y:=(fstruct.y+fstruct.elevy)*16;
	end;
	while timer<i do
   	Go;
	FixPos;
end;

function TElevatorObj.OnTarget1(sender: TObject): boolean;
begin
//двигаемся туда
if factive and (h=1) then
 begin
 stopped := false;
 Result  := true;
 end
else
 begin
 	if h=-1 then
  		Map.ActivateTarget(fstruct.etarget1);
 	Result := false;
 end;
end;

function TElevatorObj.OnTarget2(sender: TObject): boolean;
begin
if factive and (h=-1) then
 begin
 stopped := false;
 Result  := true;
 end
else
 begin
 	if (h=1) then
  		Map.ActivateTarget(fstruct.etarget2);
 	Result := false;
 end;
end;

function TElevatorObj.PhysObj(x, y: smallint): TPhysObj;
var
 bx, by: byte;
begin
Result := inherited PhysObj(x, y);
bx := trunc((x-pos.x)/32);
by := trunc((y-pos.y)/16);
with Result, fRect do
 begin
 x1 := pos.X + bx*32;
 y1 := pos.Y + by*16;
 x2 := x1 + 32;
 y2 := y1 + 16;
 dpos     := @Self.dpos;
 floatpos := fracpos;
 end;
end;

procedure TElevatorObj.phys_clipX(var ph: TPhysRect);
var
   x, y: single;
   bx1, by1, bx2, by2: integer;
   j: integer;
begin
   with ph do
   begin
      x:=pos.x-Self.pos.x;
      y:=pos.y-Self.pos.y;

      bx1:=(round(x)+x1+64) div 32-2; bx2:=(round(x)+x2+63) div 32-2;
      by1:=(round(y)+Hy1+32) div 16-2; by2:=(round(y)+Hy2+32) div 16-2;
      //левая
      for j:=by1 to by2 do
         if __Block_b(bx1, j) then
         begin
            c_left:=true;
            minpos.X:=(bx1+1)*32-x1+Self.pos.x;
            if dpos.X<speed.X then dpos.X:=speed.X;
            Break;
         end;
      //правая
      for j:=by1 to by2 do
         if __Block_b(bx2, j) then
         begin
            c_right:=true;
            maxpos.X:=bx2*32-x2+Self.pos.x;
            if dpos.X>speed.X then dpos.X:=speed.X;
            Break;
         end;
   end;
end;

procedure TElevatorObj.phys_clipY(var ph: TPhysRect);
var
   x, y: single;
   bx1, by1, bx2, by2: integer;
   i: integer;
begin
   with ph do
   begin
      x:=pos.x-Self.pos.x;
      y:=pos.y-Self.pos.y;

      bx1:=(round(x)+x1+64) div 32-2; 	bx2:=(round(x)+x2+63) div 32-2;
      by1:=(round(y)+Vy1+32) div 16-2;	by2:=(round(y)+Vy2+32) div 16-2;
      //верхняя
      for i:=bx1 to bx2 do
         if __Block_b(i, by1) then
         begin
            c_top:=true;
            minpos.Y:=(by1+1)*16-Vy1+Self.pos.Y;
            if dpos.Y<speed.Y then dpos.Y:=speed.y;
            Break;
         end;
      //нижняя
      for i:=bx1 to bx2 do
         if __Block_b(i, by2) then
         begin
            c_bottom:=true;
				friction:=ground_friction;
            if factive and not stopped then
            	ground_dpos:=@self.dpos;
            ground_float:=Point2f(frac(self.pos.x), frac(self.pos.y));
            maxpos.Y:=by2*16-Vy2+Self.pos.Y;
            if dpos.Y>speed.y then dpos.Y:=speed.y;
            Break;
         end;
   end;
end;

procedure TElevatorObj.Restart;
begin
timer      := 0;
h			  := 1;
v			  := 0;
pos.x      := fstruct.x*32;
pos.y      := fstruct.y*16;
FObjRect.X := fstruct.x*32;
FObjRect.Y := fstruct.y*16;
stopped    := elevstopping;
factive    := fstruct.eactive;
end;

procedure TElevatorObj.SaveNet(var w: array of word);
begin
   w[0]:=timer;
   w[1]:=ord(stopped)+ord(factive) shl 1+ord(h<0) shl 2;
end;

function TElevatorObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
rec.reserved[0] := timer;
rec.reserved[1] := ord(stopped)+ord(factive) shl 1+ord(h<0) shl 2;
Result := true;
end;

function TElevatorObj.Speed: TPoint2f;
begin
   if FActive and not stopped then
   	Result:=dpos
      else Result:=NullPoint;
end;

procedure TElevatorObj.Update;
begin
dpos:=NullPoint;
if FActive and not stopped then
   Go;
FixPos;
end;

{ TTriangleObj }

function TTriangleObj.BlockedAt(x, y: single): boolean;
begin
x := round(x - FObjRect.X);
y := round(y - FObjRect.Y);

if (y = -1) and (fstruct.orient mod 3 > 0) then
 y := 0
else
 if (y = FObjRect.Height + 1) and (fstruct.orient mod 3 = 0) then
  y := FObjRect.Height;

if (fstruct.orient in [0, 3]) then y:=y-2;

// XProger: блин, ну и математика...
// Делай полноценный, а не кастрированный треугольник! :)
if (x>=0) and (x <= SmallInt(FObjRect.Width)) and
   (y>=0) and (y <= SmallInt(FObjRect.Height)) then
 case fstruct.orient of
  0 : Result := VectorAnglef(FObjRect.Width, FObjRect.Height, x, y) >= 0;
  1 : Result := VectorAnglef(FObjRect.Width, FObjRect.Height, FObjRect.Width - x, y) <= 0;
  2 : Result := VectorAnglef(FObjRect.Width, FObjRect.Height, x, y) <= 0;
  3 : Result := VectorAnglef(FObjRect.Width, FObjRect.Height, FObjRect.Width - x, y) >= 0;
 else
  Result := false;
 end
else
 Result := false;
end;

constructor TTriangleObj.Create(struct_: TMapObjStruct);
begin
inherited;
FPlane := pBack;
with fstruct do
 begin
 FObjRect := Rect(x*32, y*16, 32*width, 16*height);
 FActivateRect := Rect(x*32, y*16, 32*width, 16*height);
 orient := orient mod 4;
 normal.X := FObjRect.Height;
 normal.Y := FObjRect.Width;
 if (orient mod 3 = 0) then
  normal.Y := -normal.Y;
 if (orient >= 2) then
  normal.X := -normal.X;
 //v[2] - v[0] - ДИАГОНАЛЬ
 // XProger: айяйяй... что за кастрированный треугольник
 // делай приличнее... ;)
 // Neoff: я не люблю сношения в коде
 case orient of
    0: tex:=Map.Brk[x, y+height-1];
    1: tex:=Map.Brk[x, y];
    2: tex:=Map.Brk[x+width-1, y];
    3: tex:=Map.Brk[x+width-1, y+height-1];
 end;

 with FObjRect do
  case orient of
   0 : begin
       vx[0] := X;
       vy[0] := Y;
       vx[1] := X;
       vy[1] := Y + Height;
       vx[2] := X + Width;
       vy[2] := Y + Height;
       end;
   1 : begin
       vx[0] := X;
       vy[0] := Y + Height;
       vx[1] := X;
       vy[1] := Y;
       vx[2] := X + Width;
       vy[2] := Y;
       end;
   2 : begin
       vx[0] := X;
       vy[0] := Y;
       vx[1] := X + Width;
       vy[1] := Y;
       vx[2] := X + Width;
       vy[2] := Y + Height;
       end;
   3 : begin
       vx[0] := X;
       vy[0] := Y + Height;
       vx[1] := X + Width;
       vy[1] := Y + Height;
       vx[2] := X + Width;
       vy[2] := Y;
       end;
      end;
   end;
end;

procedure TTriangleObj.Draw;
begin
Map.BrkTexEnable(tex, MASK_BLOCK);
glColor4f(1, 1, 1, 1);
glPushMatrix;
glTranslate(-startrect.x+Objrect.x, -startrect.y+Objrect.y, 0);
glBegin(GL_TRIANGLES);
 glTexCoord2f(vx[0] div 32, -vy[0] div 16); glVertex2f(vx[0], vy[0]);
 glTexCoord2f(vx[1] div 32, -vy[1] div 16); glVertex2f(vx[1], vy[1]);
 glTexCoord2f(vx[2] div 32, -vy[2] div 16); glVertex2f(vx[2], vy[2]);
glEnd;
glPopMatrix;
end;

function TTriangleObj.PhysObj(x, y: smallint): TPhysObj;
var
 temp : single;
begin
x := x - FObjRect.X;
y := y - FObjRect.Y;

if (fstruct.orient = 3) or (fstruct.orient = 2) then
 x := FObjRect.Width - x;
if (fstruct.orient = 3) or (fstruct.orient = 0) then
 y := FObjRect.Height - y;

if y < 0 then y := 0;

// XProger: блин, имхо из-за наших расхождений в trunc и round
// и проявляются всякие дрожания и пр. неприятные эффекты
// нужно пользоваться одним
Result.frect.x1 := 0;
Result.frect.x2 := trunc(FObjRect.Width*(FObjRect.Height - y)/FObjRect.Height);
Result.frect.y1 := 0;
Result.frect.y2 := trunc(FObjRect.Height*(FObjRect.Width - x)/FObjRect.Width);

if (fstruct.orient = 0) or
   (fstruct.orient = 3) then
 begin
 // XProger: а это можно и без temp сделать ;)
 // но не нужно :)
 temp := Result.frect.y1;
 Result.frect.y1 := FObjRect.Height - Result.frect.y2;
 Result.frect.y2 := FObjRect.Height - temp;
 end;

if (fstruct.orient = 2) or
   (fstruct.orient = 3) then
 begin
 temp := Result.frect.x1;
 Result.frect.x1 := FObjRect.Width - Result.frect.x2;
 Result.frect.x2 := FObjRect.Width - temp;
 end;

Result.frect.x1 := Result.frect.x1 + FObjRect.x;
Result.frect.y1 := Result.frect.y1 + FObjRect.y;
Result.frect.x2 := Result.frect.x2 + FObjRect.x;
Result.frect.y2 := Result.frect.y2 + FObjRect.y;
if fOwner<>nil then
  Result.dpos:=@(TElevatorObj(fOwner).dpos)
else Result.dpos     := @NullPoint;

Result.dis_top    := (fstruct.orient = 0) or (fstruct.orient = 3);
Result.dis_bottom := (fstruct.orient = 1) or (fstruct.orient = 2);
Result.normal     := normal;
// XProger: блин, эта процедура похожа на мои первые потуги в кодинге...
// СДЕЛАЙ серьёзный треугольник и не парься с этими условисями!
end;

procedure TTriangleObj.phys_clipX(var ph: TPhysRect);
begin
end;

procedure TTriangleObj.phys_clipY(var ph: TPhysRect);
const
   Eps = 1.0E-2;
   Eps1 = 1;

var
   x1, x2, y: single;
begin
   if fOwner<>nil then
   begin
      ph.pos.x:=ph.pos.x-ObjRect.X+StartRect.X;
      ph.pos.y:=ph.pos.y-ObjRect.Y+StartRect.Y;
      ph.maxpos.y:=ph.maxpos.y-ObjRect.Y+StartRect.Y;
      ph.dpos.X:=ph.dpos.x-TElevatorObj(fOwner).dpos.X;
      ph.dpos.Y:=ph.dpos.y-TElevatorObj(fOwner).dpos.Y;
   end;


   x1:=ph.pos.x-vx[1];
   x2:=ph.pos.x-vx[2];
//   y1:=objrect.Y-ph.pos.y-ph.Vy2;
//   y2:=objrect.Y+objrect.Height-ph.pos.y-ph.Vy2;
   if (x1*x2<=0) and
      ( (ph.pos.y<objrect.Y+objRect.Height) and (fstruct.orient mod 3=0) or
        (ph.pos.y>objrect.Y) and (fstruct.orient mod 3<>0)
      ) then
   begin
      //считаем наш y
      y:= (-x1)*(vy[2]-vy[0])/(x2-x1)+vy[0];
      case fstruct.orient of
         0, 3:
            if ph.maxpos.y+ph.Vy2>y then
            begin
               ph.maxpos.y:=y-ph.Vy2;
               ph.friction := ground_friction;

               if ph.pos.y>ph.maxpos.y-Eps1 then
               begin
               ph.c_bottom:=true;

               if (fstruct.orient=0) and
                  (ph.dpos.x>Eps) then
               begin
                  ph.ground_dpos:=@ph.temp_dpos;
                  ph.temp_dpos:=NullPoint;
                  ph.temp_dpos.Y:=ph.dpos.X*objrect.Height/objrect.Width;
                  if fOwner<>nil then
                  begin
                     ph.temp_dpos.X:=ph.temp_dpos.X+TElevatorObj(fOwner).dpos.x;
                     ph.temp_dpos.Y:=ph.temp_dpos.Y+TElevatorObj(fOwner).dpos.y;
                  end;
               end else
               if (fstruct.orient=3) and
                  (ph.dpos.x<-Eps)then
               begin
                  ph.ground_dpos:=@ph.temp_dpos;
                  ph.temp_dpos:=NullPoint;
                  ph.temp_dpos.Y:=-ph.dpos.X*objrect.Height/objrect.Width;
                  if fOwner<>nil then
                  begin
                     ph.temp_dpos.X:=ph.temp_dpos.X+TElevatorObj(fOwner).dpos.x;
                     ph.temp_dpos.Y:=ph.temp_dpos.Y+TElevatorObj(fOwner).dpos.y;
                  end;
               end else
                  if fOwner<>nil then
                     ph.ground_dpos:=@(TElevatorObj(fOwner).dpos)
                  else ph.ground_dpos:=@NullPoint;
               end;
            end;
         1, 2:
            if ph.minpos.y+ph.Vy1<y then
            begin
               ph.c_top:=true;

               ph.minpos.y:=y-ph.Vy1;
               if ph.pos.y<ph.minpos.y then
               begin
                  if ph.dpos.Y < 0 then
                     ph.dpos.Y := 0;

                  if (fstruct.orient=2) and
                     (ph.dpos.x>1.0E-3) then
                     if ph.dpos.Y/ph.dpos.X<objrect.Height/objrect.Width then
                        ph.dpos.Y:=ph.dpos.X*objrect.Height/objrect.Width;
                  if (fstruct.orient=1) and
                     (ph.dpos.x<-1.0E-3) then
                        if -ph.dpos.Y/ph.dpos.X<objrect.Height/objrect.Width then
                           ph.dpos.Y:=-ph.dpos.X*objrect.Height/objrect.Width;
               end;
            end;
{         2, 3: if ph.maxpos.y<y+ph.pos.y then
                  ph.maxpos.y:=y+ph.pos.y;}
      end;
   end;
   if fOwner<>nil then
   begin
      ph.pos.x:=ph.pos.x+ObjRect.X-StartRect.X;
      ph.pos.y:=ph.pos.y+ObjRect.Y-StartRect.Y;
      ph.maxpos.y:=ph.maxpos.y+ObjRect.Y-StartRect.Y;
      ph.dpos.X:=ph.dpos.x+TElevatorObj(fOwner).dpos.X;
      ph.dpos.Y:=ph.dpos.y+TElevatorObj(fOwner).dpos.Y;
   end;
end;

function TTriangleObj.VectorIntersect(x, y, angle: single;
  var s: single): boolean;
begin
   x:=x-objrect.x+startrect.x;
   y:=y-objrect.y+startrect.y;
// ПРОЦЕДУРА ОБРАБОТКИ ВЫСТРЕЛОВ ПО НАШЕЙ ПРИЗМЕ ;)
// проверяется только диагональ! всё остальное в принципе проницаемо.

// XProger: опять этот треугольник! Уже достало как-то...
// Блин, а здесь round =)))
if BlockedAt(round(x), round(y)) then
 begin
 s      := 0;
 Result := true;
 end
else
// А все вычисления - они в math_lib! перенесены для создания общей
// математической библиотеки.
 Result := LineVectorIntersect(vx[0], vy[0], vx[2], vy[2], x, y, angle, s);
end;

{ TRespawn }

function TRespawn.Activate(sender: TObject): boolean;
var
   i: integer;
   pl: TPlayer;
begin
   Result := true;
   if Sender is TPlayer then
      Map.ActivateTarget(fstruct.target)
   else
      if (fstruct.active>0) and (timer=0) then
   begin
   //NFK Bot
      if fstruct.active=1 then
         factive:=true;
      timer:=fstruct.wait;
      if resp_mode=3 then
      begin
         i:=Map.pl_count;
         Bot_LockResp;
         Console_CMD('addbot');
         if Map.pl_count>i then
         begin
            pl:=Map.player[i];
            pl.resp:=true;
            pl.respindex:=Tag;
            pl.dead_mode:=true;
            if team>0 then
               Map.TeamJoin(pl.UID, team);
         end;
         Bot_UnLockResp;
      end else
      if resp_mode=2 then
      begin
         i:=Map.pl_count;
         Console_CMD('bot_add');
         if Map.pl_count>i then
         begin
            pl:=Map.player[i];
            pl.resp:=true;
            pl.respindex:=Tag;
            pl.dead_mode:=true;
            if team>0 then
               Map.TeamJoin(pl.UID, team);
         end;
      end;
   end;
end;

constructor TRespawn.Create(struct_: TMapObjStruct);
begin
inherited;
FObjRect.X := x*32;
FObjRect.Y := y*16;
fstruct.resp_ammo[0]:=1;
end;

procedure TRespawn.Restart;
begin
FObjRect.X := x*32;
FObjRect.Y := y*16;
factive:=false;
timer:=0;
end;

procedure TRespawn.Update;
begin
  inherited;
   if timer>0 then dec(timer);
end;

{ TBricksObj }
function TBricksObj.Blocked: boolean;
begin
   Result:=blocks;
end;

function TBricksObj.Block_b(bx, by: smallint): boolean;
begin
if (bx >= 0) and
   (by >= 0) and
   (bx < SmallInt(width)) and
   (by < SmallInt(height)) then
 Result := mask[bx + width*by] and MASK_BLOCK>0
else
 Result:=true;
end;

constructor TBricksObj.Create(struct_:TMapObjStruct);
begin
inherited;
 with fstruct do
 	FObjRect := Rect(x*32, y*16, 32*width, 16*height);
 fPlane:=pBack;
end;

destructor TBricksObj.Destroy;
begin
   brk:=nil; mask:=nil;
  inherited;
end;

procedure TBricksObj.Draw;
var
 i, j: word;
begin
for j := 0 to Height - 1 do
 for i := 0 to Width - 1 do
  if (brk[i + j*width]>0) and ( (mask[i + j*width] and MASK_FRONT=0) xor (Plane=pFront) ) then
   begin
   Map.BrkTexEnable(brk[i + j*Width], mask[i + j*Width]);
   glBegin(GL_QUADS);
    glTexCoord2f(0, -1);
     glVertex2f(FObjRect.X + i*32, FObjRect.Y + (j + 1)*16);
    glTexCoord2f(1, -1);
     glVertex2f(FObjRect.X + (i + 1)*32, FObjRect.Y + (j + 1)*16);
    glTexCoord2f(1, 0);
     glVertex2f(FObjRect.X + (i + 1)*32, ObjRect.Y + j*16);
    glTexCoord2f(0, 0);
     glVertex2f(FObjRect.X + i*32, ObjRect.Y + j*16);
   glEnd;
   end;
if fPlane=pBack then
   fPlane:=pFront
else fPlane:=pBack;
end;

procedure TBricksObj.TakeBricks;
var
 i, j, x, y: word;
begin
   blocks:=false;
	SetLength(brk, Width*Height);
	SetLength(mask, Width*Height);
	for j := 0 to Height - 1 do
 		for i := 0 to Width - 1 do
  		begin
  			x:=i + fstruct.x; y:=j + fstruct.y;
			brk[i + j*Width] := Map.Brk[x, y];
      	mask[i + j*Width] := Map.Brk.Mask[x, y];
         if mask[i+j*Width] and MASK_BLOCK>0 then blocks:=true;
			Map.Brk.Mask[x, y]:=Map.Brk.Mask[x, y] or MASK_CONTAINER;//делаем брик невидимым.
  		end;
end;

function TBricksObj._Block_b(bx, by: smallint): boolean;
begin
if (bx >= 0) and
   (by >= 0) and
   (bx < SmallInt(width)) and
   (by < SmallInt(height)) then
 Result := (mask[bx + width*by] and MASK_BLOCK>0) and
           (brk[bx + width*by]>0)
else
 Result:=true;
end;

function TBricksObj.__Block_b(bx, by: smallint): boolean;
begin
if (bx >= 0) and
   (by >= 0) and
   (bx < SmallInt(width)) and
   (by < SmallInt(height)) then
 Result := mask[bx + width*by] and MASK_BLOCK>0
else
 Result:=false;
end;

{ TAreaPain }

procedure TAreaPain.LoadFromRec(rec: TDemoObjRec);
begin
   inherited LoadFromRec(rec);
   rec.reserved[2]:=paintimer;
end;

function TAreaPain.player_Activate(sender: TObject): boolean;
begin
   if factive then
   begin
    	if paintimer=0 then
      begin
         if fstruct.paindamage>0 then
         begin
    		   HitPlayerP(fstruct.paindamage, TPlayer(sender), nil, 0);
            with TPlayer(sender) do
               Particle_Blood(pos.x, pos.y);
         end else
         begin
            with TPlayer(sender) do
               if health>0 then health:=health+abs(fstruct.paindamage);
         end;
      end;
   end;
   Result:=false;
end;

procedure TAreaPain.Restart;
begin
   inherited;
   if fstruct.painactive then
      factive:=true;
   paintimer:=0;
end;

function TAreaPain.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   Result:=inherited SaveToRec(rec);
   rec.reserved[2]:=paintimer;
end;

procedure TAreaPain.Update;
begin
  	inherited;
   if factive then
   begin
	   if fstruct.painwait=0 then
         paintimer:=0
     	else
   		if factive then
   			paintimer:=(paintimer+1) mod fstruct.painwait;
  	end;
end;

{ TArenaEnd }

function TArenaEnd.Activate(sender: TObject): boolean;
begin
   Result:=false;
   if sender is TObject and
   	not Map.demoplay then
   begin
      Map.StopGame;
      Result:=true;
   end;
end;

{ TAreaPush }

function TAreaPush.player_Activate(sender: TObject): boolean;
begin
   if factive then
   begin
    	if pushtimer=0 then
      begin
         with fstruct, TPlayer(sender) do
            Push0(pushspeedx/10, pushspeedy/10);
      end;
   end;
 	Result:=false;
end;

procedure TAreaPush.Restart;
begin
   if fstruct.active=0 then
      fstruct.active:=4;
   inherited;
end;

procedure TAreaPush.Update;
begin
  inherited;
  if fstruct.pushwait=0 then
      pushtimer:=0
     else
   	if factive then
   		pushtimer:=(pushtimer+1) mod fstruct.pushwait;
end;

{ TAreaTeleport }

function TAreaTeleport.Activate(sender: TObject): boolean;
begin
Result := false;
if sender is TPlayer then
 begin
 if fOwner2<>nil then
 	 TPlayer(Sender).MoveTo(
    	struct.gotox*32 + fOwner2.fobjrect.x - fOwner2.startrect.x,
 			struct.gotoy*16 + fOwner2.fobjrect.y - fOwner2.startrect.y)
 else TPlayer(Sender).MoveTo(struct.gotox*32, struct.gotoy*16);
 if odd(fstruct.orient) then TPlayer(sender).RotateX;
 if fstruct.orient>=2 then TPlayer(sender).RotateY;
 Result := true;
 end;
end;

{ TAreaTeleportWay }

function TAreaTeleportWay.Activate(sender: TObject): boolean;
begin
Result := false;
if sender is TPlayer then
 begin
 if fOwner2<>nil then
 	 TPlayer(Sender).MoveBy(
    	struct.gotox*32-FObjRect.X + fOwner2.fobjrect.x - fOwner2.startrect.x,
 			struct.gotoy*16-FObjRect.Y + fOwner2.fobjrect.y - fOwner2.startrect.y)
 else TPlayer(Sender).MoveBy(struct.gotox*32-FObjRect.X, struct.gotoy*16-FObjRect.y);
 if odd(fstruct.orient) then TPlayer(sender).RotateX;
 if fstruct.orient>=2 then TPlayer(sender).RotateY;
 Result := true;
 end;

end;

constructor TAreaTeleportWay.Create(struct_: TMapObjStruct);
begin
   inherited;
   FActivateRect:=Rect(0, 0, width*32, height*16);
   FActivateMode:=true;
end;

{ TLightLineObj }

function TLightLineObj.targ_Activate(sender: TObject): boolean;
var
 struct : TRealObjStruct;
 Obj    : TLightLine;
begin
   if fline<>nil then
   begin
      Result:=false;
      Exit;
   end;
 struct.x := x*32 + x0;
 struct.y := y*16 + y0;
 struct.angle     := fstruct.angle;
 struct.playerUID := 0;
 Obj := TLightLine.Create(struct, self);
 Obj.target:=fstruct.target;
 Obj.maxlen     := len;
 Obj.Color     := NumToColor(fstruct.orient);
 fLine := Obj;
 RealObj_Add(Obj);
 factive:= true;
 Result := true;
end;

{ TBloodGen }

constructor TBloodGen.Create(struct_: TMapObjStruct);
begin
   inherited;
   objrect:=Rect(X*32+16, Y*16+8, 0, 0);
end;

procedure TBloodGen.draw;
begin
   //abstract
end;

procedure TBloodGen.Restart;
begin
   if fstruct.active=0 then
      fstruct.active:=4;
   inherited;
   light:=nil;
   timer:=0;
   if fActive then
      targ_Activate(Self);
end;

function TBloodGen.targ_Activate(sender: TObject): boolean;
begin
   if fstruct.bloodtype=2 then
   begin
      Result:=light=nil;
      if Result then
         Light := TP_Light(
      Particle_Add(
      TP_Light.Create(Point2f(fstruct.X, fstruct.Y), Point2f(48, 48), NumToColor(fstruct.orient), 1)
      )
      );
   end else Result:=true;
   factive:=true;
end;

function TBloodGen.targ_Deactivate(sender: TObject): boolean;
begin
   if fstruct.bloodtype=2 then
   begin
      Result:=light<>nil;
      if Result then
      begin
         light.die:=0;
         light:=nil;
      end;
   end else Result:=true;
   factive:=false;
end;

procedure TBloodGen.Update;
var
   i: integer;
begin
   inherited;
   spos:=Point2f(objrect.X, objrect.Y);
   with fstruct do
   begin
   	sdpos:=Point2f(spos.x+cos(bloodangle)*bloodL, spos.y+sin(bloodangle)*bloodL);
      if bloodtype=3 then
   		sdpos:=Point2f(cos(bloodangle)*bloodL/32, sin(bloodangle)*bloodL/32);
   end;

   if fActive then
   with fstruct do
   begin
      if (bloodwait>0) and not (bloodtype=2) then
      	timer:=(timer+1) mod bloodwait
         else timer:=0;
      if timer=0 then
      for i:=1 to bloodcount do
      case bloodtype of
         0://КРОВИЩА
				Particle_Add(TP_Blood.Create(sdpos));
         1:
           //теперь дым
				Particle_Add(TP_Smoke.Create(sdpos));
         3:
           //теперь искра
            Particle_Add(TP_Spark.Create(spos, sdpos));
         2:
         //теперь свет
				if light<>nil then
               light.Pos := sdpos;
      end;
   end;
end;

constructor TCustomLiquid.Create(struct_: TMapObjStruct);
begin
inherited;
FObjRect      := Rect(X*32, Y*16, Width*32, Height*16);
FActivateRect := Rect(0, 0, Width*32, Height*16);
FPlane  := pFront;
Speed   := 0;
Density := 0;
end;

procedure TCustomLiquid.Restart;
begin
   inherited;
   level:=fstruct.cur_level;
   if factive then targ_Activate(Self);
   up:=1;
end;

function TCustomLiquid.targ_Activate(sender: TObject): boolean;
begin
   with fstruct do
   begin
      Result:=max_level>min_level;
      if Result then
      begin
         inherited targ_Activate(sender);
         if level=max_level then up:=-1
         else if level=min_level then up:=1;
      end;
   end;
end;

procedure TCustomLiquid.Update;
begin
   inherited;
   FActivateRect := Rect(0, level, Width*32, Height*16-level);
   if factive then
   with fstruct do
   begin
      Inc(level, up);
      if (level=min_level) or (level=max_level) then
         targ_Deactivate(self);
   end;
end;

procedure TCustomLiquid.Draw;
begin
if Tex = nil then Exit;
xglTex_Enable(Tex.CurFrame);
glBegin(GL_QUADS);
 with FObjRect do
  begin
  glTexCoord2f(X/64, Y/64);
  glVertex2f(X, Y);

  glTexCoord2f((X + Width)/64, Y/64);
  glVertex2f(X + Width, Y);

  glTexCoord2f((X + Width)/64, (Y + Height)/64);
  glVertex2f(X + Width, Y + Height);

  glTexCoord2f(X/64, (Y + Height)/64);
  glVertex2f(X, Y + Height);
  end;
glEnd;
end;

{ Water }

constructor TWaterObj.Create(struct_: TMapObjStruct);
var
 j : boolean;
begin
inherited;
for j := false to true do
 begin
 SetLength(Waves[j], Width*8 + 2);
 FillChar(Waves[j][0], Width*8 + 2, 0);
 end;
State := false;
Wait  := 0;
Tex := TObjTex.Create('textures\obj\water', 1, 0, 2, false, false, nil);
end;

destructor TWaterObj.Destroy;
begin
Waves[false] := nil;
Waves[true] := nil;
inherited;
end;

procedure TWaterObj.Update;
var
 i: integer;
 back : boolean;
begin
   inherited;

Tex.Update;
if Wait > 0 then
 begin
 dec(Wait);
 Exit;
 end;
Wait := 2;

Back := not State;

Smooth;

for i := 1 to Width*8 do
 begin
 Waves[State, i] := round((Waves[Back, i - 1] +
                           Waves[Back, i + 1] -
                           Waves[State, i]) * 0.98);
 if Waves[State, i] < -1600 then
  Waves[State, i] := -1600;
 if Waves[State, i] > 1600 then
  Waves[State, i] := 1600;
 end;

Waves[State, 0] := 0;
Waves[State, Width*8 + 1] := 0;

State := Back;
end;

procedure TWaterObj.Smooth;
var
 i    : integer;
 Back : boolean;
begin
Back := not State;
for i := 1 to Width*8 do
 Waves[Back, i] := (Waves[Back, i - 1] +
                    Waves[Back, i + 1] +
                    Waves[Back, i]) div 3;
end;

procedure TWaterObj.LoadFromRec(rec: TDemoObjRec);
begin
  inherited;
  if rec.reserved[2]=0 then
     up:=1
     else up:=-1;
end;

function TWaterObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   Result:=inherited SaveToRec(rec);
   rec.reserved[2]:=ord(boolean(up=-1));
end;

procedure TWaterObj.Draw;
var
 i             : integer;
 s, t1, t2, t3 : single;
begin
glColor4f(0.7, 0.7, 1, 0.7);
xglAlphaBlend(2);
xglTex_Enable(Tex.CurFrame);

glBegin(GL_QUADS);
with FObjRect do
 for i := 1 to self.Width*8 do
  begin
  s  := X + (i - 1)*4;
  t1 := Y + level + Waves[State, i]/100;
  t2 := Y + level + Waves[State, i + 1]/100;
  t3 := Y + Height;
  if t1>t3 then t1:=t3;
  if t2>t3 then t2:=t3;

  glTexCoord2f(s/64, t1/64);
  glVertex2f(s, t1);

  glTexCoord2f((s + 4)/64, t2/64);
  glVertex2f(s + 4, t2);

  glTexCoord2f((s + 4)/64, t3/64);
  glVertex2f(s + 4, t3);

  glTexCoord2f(s/64, t3/64);
  glVertex2f(s, t3);
  end;
glEnd;

xglAlphaBlend(1);
end;

procedure TWaterObj.Wave(x, a: integer);
var
 Back : boolean;
begin
Back := State;
State := not State;
 x := (x-FObjRect.x) div 4;
 if x<3 then x:=3;
 if x>width*8-3 then x:=width*8-3;
 Waves[Back, x]:= a;
 Waves[Back, x - 1] := a;
 Waves[Back, x + 1] := a;
 Waves[Back, x - 2] := a;
 Waves[Back, x + 2] := a;
 Smooth;
State := not State;
end;

procedure TWaterObj.Wave2(x, a: integer);
begin
 x := (x-FObjRect.x) div 4;
 if x<3 then x:=3;
 if x>width*8-3 then x := width*8-3;
 Inc(Waves[State, x], a);
 Inc(Waves[State, x - 1], a);
 Inc(Waves[State, x + 1], a);
 Inc(Waves[State, x - 2], a);
 Inc(Waves[State, x + 2], a);
end;

function TWaterObj.player_Activate(sender: TObject): boolean;
begin
  	Result:=false;
   with Tplayer(Sender) do
   begin
//ПРЫЖОК в ВОДУ
   	if not in_water and (w_level>=1) or
      	in_water and (w_level=0) then
   	begin
     	 	Result:=true;
      	Wave(round(pos.x), -round(dpos.y*60));
      	in_water:=not in_water;
   	end;
//ходьба по воде
      if (w_level>=1) and (w_level<=3) then
         Wave2(round(pos.x)+signf(dpos.x)*30, abs(trunc(dpos.x*5)));
	end;
end;

procedure TWaterObj.Restart;
var
   j: boolean;
begin
  	inherited;
   for j:=false to true do
 		FillChar(Waves[j][0], Width*8 + 2, 0);
end;

{ Lava }

constructor TLavaObj.Create(struct_: TMapObjStruct);
var
 wx, wy : integer;
begin
inherited;
Tex    := TObjTex.Create('textures\obj\lava', 1, 0, 2, false, false, nil);
lTex   := TObjTex.Create('textures\sprites\lava_light', 1, 0, 2, false, false, nil);
with FObjRect do
 begin
 W_X := X;
 W_Y := Y;
 W_W := Width div 16;
 W_H := Height div 16;
 SetLength(Wave[0], W_W, W_H); // значения углов
 SetLength(Wave[1], W_W, W_H); // синусы углов
 SetLength(Wave[2], W_W, W_H); // косинусы углов
 // задаём случайные величины углов
 for wy := 0 to W_H - 1 do
  for wx := 0 to W_W - 1 do
   Wave[0, wx, wy] := randomf*2*pi;
 end;
Update; 
end;

destructor TLavaObj.Destroy;
begin
Wave[0] := nil;
Wave[1] := nil;
Wave[2] := nil;
inherited;
end;

function TLavaObj.player_Activate(sender: TObject): boolean;
const
   LAVA_DAMAGE = 1;
begin
  	Result:=false;
	HitPlayerP(LAVA_DAMAGE, TPlayer(sender), nil, 0);
   with TPlayer(sender) do
   begin
      Particle_Blood(pos.x, pos.y);
      Particle_Add(TP_Smoke.Create(Pos));
   end;
end;

procedure TLavaObj.Update;
const
 Step = 0.03;
var
 wx, wy : integer;
begin
inherited;
FActivateRect := Rect(0, level, Width*32, Height*16);
Tex.Update;
for wy := 0 to W_H - 1 do
 for wx := 0 to W_W - 1 do
  begin
  Wave[0, wx, wy] := Wave[0, wx, wy] + Step;
  Wave[1, wx, wy] := sin(Wave[0, wx, wy])/128;
  Wave[2, wx, wy] := cos(Wave[0, wx, wy])/128;
  end;
end;

procedure TLavaObj.Draw;
const
 size = 1/128;
var
 i, wx, wy  : integer;
 sx, sy     : integer;
 coord      : array [0..4] of record s, t : single; end;
begin
xglTex_Enable(Tex.CurFrame);
glColor4f(1, 1, 1, 1);
glBegin(GL_QUADS);
with FObjRect do
 begin
 for wy := 0 to W_H - 1 do
  for wx := 0 to W_W - 1 do
   begin
   for i := 0 to 3 do
    with coord[i] do
     begin
     sx := i mod 2;
     sy := Byte(i > 1);
     s := (X + (wx + sx) * 16)*size;
     t := (Y + (wy + sy) * 16)*size;
     if wx = W_W - 1 then sx := 0;
     if wy = W_H - 1 then sy := 0;
     s := s + Wave[1, wx + sx, wy + sy];
     t := t + Wave[2, wx + sx, wy + sy];
     end;
   sx := wx*16;
   sy := wy*16;
   glTexCoord2fv(@coord[0]); glVertex2f(X + sx, Y + sy + level);
   glTexCoord2fv(@coord[1]); glVertex2f(X + sx + 16, Y + sy + level);
   glTexCoord2fv(@coord[3]); glVertex2f(X + sx + 16, Y + sy + 16 + level);
   glTexCoord2fv(@coord[2]); glVertex2f(X + sx, Y + sy + 16 + level);
   end;
 glEnd;

 xglTex_Enable(lTex.CurFrame);
 xglAlphaBlend(1);
 glColor4f(1, 1, 1, 1 - random * 0.1);
 glBegin(GL_QUADS);
  glTexCoord2f(0, 1); glVertex2f(X, Y + Level - 16);
  glTexCoord2f(1, 1); glVertex2f(X + Width, Y + Level - 16);
  glTexCoord2f(1, 0); glVertex2f(X + Width, Y + Level);
  glTexCoord2f(0, 0); glVertex2f(X, Y + Level);
 glEnd;
 end;
end;

{ TWeather }

constructor TWeather.Create(struct_: TMapObjStruct);
begin
inherited;
FObjRect := Rect(X*32, Y*16, Width*32, Height*16);
end;

procedure TWeather.Restart;
begin
   if fstruct.active=0 then
      fstruct.active:=4;
   inherited;
   timer:=0;
end;

procedure TWeather.Update;
var
 i : integer;
begin
inherited;

if factive then
begin

if timer <= 0 then
 for i := 1 to fstruct.bloodcount do
  with FObjRect do
   case fstruct.bloodtype of
   0 : // Snow
    if r_snow then
     begin
     Particle_Add(TP_Snow.Create(Point2f(randomf*Width + X,
                                         randomf*(Height - 16) + Y)));
     timer := fstruct.bloodwait;
     end;

   1 : // Rain
    if r_rain then
     begin
     Particle_Add(TP_Rain.Create(Point2f(randomf*Width + X,
                                         randomf*(Height - 16) + Y)));
     timer := fstruct.bloodwait;
     end;

  end
else
 dec(timer);

end;

end;

procedure TWeather.Draw;
begin
///
end;

{ TTrainObj }

constructor TTrainObj.Create(struct_: TMapObjStruct);
begin
   inherited;
   fNetSize:=6;
   train_orient:=0;   
end;

procedure TTrainObj.Go;
var
   i: integer;
begin
   with Map.Obj do
   for i:=low(trainpoints) to high(trainpoints) do
      if (abs(pos.X-trainpoints[i].x*32)<=speed*0.5) and
         (abs(pos.Y-trainpoints[i].y*16)<=speed*0.5) then
         begin
            dpos:=NullPoint;
            break;
         end;

   with Map.Obj do
   for i:=low(trainpoints) to high(trainpoints) do
      if (abs(pos.X-trainpoints[i].x*32)<=speed*0.5) and
         (abs(pos.Y-trainpoints[i].y*16)<=speed*0.5) then
         begin
            trainpoints[i].ActivateTrain;
            if trainpoints[i].factive then
            begin
               if trainpoints[i].changespeed then
                  speed:=trainpoints[i].speed;
               if trainpoints[i].changeorient then
                  train_orient:=trainpoints[i].struct.orient;
               case train_orient of
                  0: begin dpos.X:=speed; end;
                  1: begin dpos.Y:=speed; end;
                  2: begin dpos.X:=-speed; end;
                  3: begin dpos.Y:=-speed; end;
               end;
            end;
         end;
{   with fstruct do
   begin
      if (nextpoint=nil) or
         not nextpoint.activated then
         begin
            dpos.X:=0;dpos.Y:=0;
            Exit;
         end;
      elevx:=nextpoint.x;
      elevy:=nextpoint.y;
      l0:=sqrt(sqr(pos.x-nextpoint.x)+sqr(pos.y-nextpoint.y));
      if abs(l0)>1 then
      begin
         dpos.X:=elevspeed*(pos.x-nextpoint.x) /l0;
         dpos.Y:=elevspeed*(pos.y-nextpoint.y) /l0;
      end else
      begin
         Map.ActivateTarget(nextpoint.Target);
         nextpoint:=Map.Obj.GetTranPoint(nextpoint.NextPoint);
      end;
   end;}
   with fstruct do
   begin
      pos.X := pos.X + dpos.X/phys_freq;
      pos.Y := pos.Y + dpos.Y/phys_freq;
   end;
end;

procedure TTrainObj.LoadFromRec(rec: TDemoObjRec);
begin
   pos.x:=rec.reserved[0] and 32767;
   pos.y:=rec.reserved[1] and 32767;
   dpos.x:=rec.reserved[2]/100-100;
   dpos.y:=rec.reserved[3]/100-100;
   factive:=rec.reserved[0] and 32768>0;
   train_orient:=rec.reserved[4];
   speed:=rec.reserved[5]/100;
end;

procedure TTrainObj.LoadNet(w: array of word);
begin
   pos.x:=w[0] and 32767;
   pos.y:=w[1] and 32767;
   dpos.x:=w[2]/100-100;
   dpos.y:=w[3]/100-100;
   factive:=w[0] and 32768>0;
   train_orient:=w[4];
   speed:=w[5]/100;
end;

procedure TTrainObj.Restart;
begin
   if fstruct.active=0 then
      fstruct.active:=4;
  inherited;
   speed:=fstruct.elevspeed;
   stopped:=false;
end;

procedure TTrainObj.SaveNet(var w: array of word);
begin
   w[0]:=round(pos.x)+ord(factive)*32768;
   w[1]:=round(pos.y);
   w[2]:=round(dpos.x*100+10000);
   w[3]:=round(dpos.y*100+10000);
   w[4]:=train_orient;
   w[5]:=round(speed*100);
end;

function TTrainObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   rec.reserved[0]:=round(pos.x)+ord(factive)*32768;
   rec.reserved[1]:=round(pos.y);
   rec.reserved[2]:=round(dpos.x*100+10000);
   rec.reserved[3]:=round(dpos.y*100+10000);
   rec.reserved[4]:=train_orient;
   rec.reserved[5]:=round(speed*100);
   Result:=true;
end;

procedure TTrainObj.Update;
begin
   stopped:=false;
   if FActive then
      Go;
   FixPos;
end;

{ TTrainPointObj }
                 
function TTrainPointObj.Activate(sender: TObject): boolean;
begin
   Result:=true;
   ftimer:=fstruct.wait;
   factive:=true;
end;

procedure TTrainPointObj.ActivateTrain;
begin
   if ftargtimer<0 then
      ftargtimer:=fstruct.waittarget;
end;

constructor TTrainPointObj.Create(struct_: TMapObjStruct);
begin
   inherited;
   fNetSize:=2;
   FActive:=fstruct.active=0;
   if fstruct.orient<4 then
      fstruct.orientchange:=true;
end;

procedure TTrainPointObj.LoadFromRec(rec: TDemoObjRec);
begin
if rec.reserved[1]=65535 then
   rec.reserved[1]:=0;
if rec.reserved[2]=65535 then
   rec.reserved[2]:=0;
ftargtimer := integer(rec.reserved[1])-1;
ftimer := integer(rec.reserved[2])-1;
factive:=(ftimer>0) or (fstruct.active=0);
end;

procedure TTrainPointObj.LoadNet(w: array of word);
begin
   if w[0]=65535 then
      w[0]:=0;
   if w[1]=65535 then
      w[1]:=0;
   ftargtimer := integer(w[0])-1;
   ftimer := integer(w[1])-1;
   factive:=(ftimer>0) or (fstruct.active=0);
end;

procedure TTrainPointObj.restart;
begin
  inherited;
   ftargtimer := -1;
   ftimer:=-1;
   if fstruct.active=0 then
     FActive:=true;
end;

procedure TTrainPointObj.SaveNet(var w: array of word);
begin
  inherited;
   w[0] := ftargtimer+1;
   w[1] := ftimer+1;
end;

function TTrainPointObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
Result := true;
rec.reserved[1] := ftargtimer+1;
rec.reserved[2] := ftimer+1;
end;

procedure TTrainPointObj.Update;
begin
  inherited;
   if ftimer>0 then
   begin
      dec(ftimer);
      factive:=true;
   end;
   if ftimer=0 then
   begin
      factive:=false;
      ftimer:=-1;
   end;

   if ftargtimer>0 then
      dec(ftargtimer);
   if ftargtimer=0 then
   begin
      Map.ActivateTarget(target);
      ftargtimer:=-1;
   end;
end;

{ TBelt }

function TBelt.BlockedAt(x, y: single): boolean;
begin
x := round(x);
y := round(y);
x := x - FObjRect.X;
y := y - FObjRect.Y;
Result := (x >= 0)
          and (x <= SmallInt(FObjRect.Width))
          and (y >= 0)
          and (y <= smallint(FObjRect.Height)) or not Blocked;
end;

function TBelt.Block_b(bx, by: smallint): boolean;
begin
   Result:=inherited Block_b(bx, by);
end;

constructor TBelt.Create(struct_: TMapObjStruct);
begin
   inherited;
   bx:=1;by:=1;
   if abs(fstruct.beltspeedx)>0.01 then bx:=0;
   if abs(fstruct.beltspeedy)>0.01 then by:=0;
end;

procedure TBelt.Draw;
var
   i, j, ii, jj: integer;
   xx, yy: integer;
begin
   //рисуем
xx:=round(smx) mod 32;
if round(smx) mod 32>0 then xx:=xx-32
else xx:=0;
yy:=round(smy) mod 16;
if round(smy) mod 16>0 then yy:=yy-16;
for j:=0 to Height-by do
   for i:=0 to Width-bx do
   begin
      ii:=(i+minx) mod Width;
      jj:=(j+miny) mod Height;
  if (brk[ii + jj*width]>0) and ( (mask[ii + jj*width] and MASK_FRONT=0) xor (Plane=pFront) ) then
   begin
   Map.BrkTexEnable(brk[ii + jj*Width], mask[ii + jj*Width]);
   glBegin(GL_QUADS);
    glTexCoord2f(0, -1);
     glVertex2f(FObjRect.X + xx + i*32, FObjRect.Y + yy + 16+j*16);
    glTexCoord2f(1, -1);
     glVertex2f(FObjRect.X + xx + 32+ i*32, FObjRect.Y + yy + 16+j*16);
    glTexCoord2f(1, 0);
     glVertex2f(FObjRect.X + xx + 32+ i*32, ObjRect.Y + yy+j*16);
    glTexCoord2f(0, 0);
     glVertex2f(FObjRect.X + xx+ i*32, ObjRect.Y + yy+j*16);
   glEnd;
   end;
   end;
if fPlane=pBack then
   fPlane:=pFront
else fPlane:=pBack;
end;

procedure TBelt.LoadFromRec(rec: TDemoObjRec);
begin
   rec.reserved[0]:=timer;
   rec.reserved[1]:=integer(factive);
end;

procedure TBelt.LoadNet(w: array of word);
begin
   w[0]:=timer;
   w[1]:=integer(factive);
end;

function TBelt.PhysObj(x, y: smallint): TPhysObj;
begin
with Result, frect do
 begin
 x1 := fObjRect.x;
 y1 := fObjRect.y;
 x2 := fObjRect.x + FObjRect.Width;
 y2 := fObjRect.y + FObjRect.Height;
 if factive then
   dpos     := @Sspeed
 else dpos  := @NullPoint;
 normal     := NullPoint;
 floatpos   := NullPoint;
 dis_bottom := false;
 dis_top    := false;
 dis_hor    := false;
 end;
end;

procedure TBelt.Restart;
begin
   inherited;
   if fstruct.beltactive then
      factive:=true;
   smx:=0;smy:=0;
end;

procedure TBelt.SaveNet(var w: array of word);
begin
   timer:=w[0];
   factive:=boolean(w[1]);
end;

function TBelt.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   timer:=rec.reserved[0];
   factive:=boolean(rec.reserved[1]);
   Result:=true;
end;

procedure TBelt.Update;
begin
   inherited;
   sspeed:=NullPoint;
   if factive then
   begin
      smx:=smx+fstruct.beltspeedx;
      smy:=smy+fstruct.beltspeedy;
      while smx<0 do smx:=smx+width*32;
      while smx>=width*32 do smx:=smx-width*32;
      while smy<0 do smy:=smy+height*16;
      while smy>=height*16 do smy:=smy-height*16;
      sspeed.x:=fstruct.beltspeedx;
   end;
   minx:=round(Width*32-smx) div 32;
   miny:=round(Height*16-smy) div 16;
end;

function TBelt.__Block_b(bx, by: smallint): boolean;
begin
   Result:=inherited __Block_b(bx, by);
end;

{ TAnimationObj }

function TAnimationObj.BlockedAt(x, y: single): boolean;
begin
x := round(x);
y := round(y);
x := x - FObjRect.X;
y := y - FObjRect.Y;
Result := (x >= 0)
          and (x <= SmallInt(FObjRect.Width))
          and (y >= 0)
          and (y <= smallint(FObjRect.Height)) or not Blocked;
end;

procedure TAnimationObj.Draw;
var
 i, j, k: word;
begin
   k:=(anim div fstruct.animwait) mod fstruct.animcount;

for j := 0 to Height - 1 do
 for i := 0 to Width - 1 do
  if ( brk[i + j*width]+k>0 ) and ( (mask[i + j*width] and MASK_FRONT=0) xor (Plane=pFront) ) then
   begin
   Map.BrkTexEnable(brk[i + j*Width]+k, mask[i + j*Width]);
   glBegin(GL_QUADS);
    glTexCoord2f(0, -1);
     glVertex2f(FObjRect.X + i*32, FObjRect.Y + (j + 1)*16);
    glTexCoord2f(1, -1);
     glVertex2f(FObjRect.X + (i + 1)*32, FObjRect.Y + (j + 1)*16);
    glTexCoord2f(1, 0);
     glVertex2f(FObjRect.X + (i + 1)*32, ObjRect.Y + j*16);
    glTexCoord2f(0, 0);
     glVertex2f(FObjRect.X + i*32, ObjRect.Y + j*16);
   glEnd;
   end;
if fPlane=pBack then
   fPlane:=pFront
else fPlane:=pBack;
end;

procedure TAnimationObj.LoadFromRec(rec: TDemoObjRec);
begin
   inherited LoadFromRec(rec);
   anim:=rec.reserved[2];
end;

procedure TAnimationObj.Restart;
begin
   if fstruct.active=0 then
      fstruct.active:=4;
   inherited;
   anim:=0;
end;

function TAnimationObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   result:=inherited SaveToRec(rec);
   rec.reserved[2]:=anim;
end;

procedure TAnimationObj.Update;
begin
   inherited;
   if factive then
      Inc(anim);
end;

{ TSoundTrigger }

function TSoundTrigger.Activate(sender: TObject): boolean;
begin
Result := false;
with fstruct do
 if timer = 0 then
  begin
  if factive and not soundloop then
   exit;
  timer := wait;
  //играем звук!!!!
  //PLAY_IT!!!
  if soundloop then
   begin
   factive := not factive;
   if factive then
    psnd := snd_Play(snd, soundloop, ObjRect.x + 16, ObjRect.y + 8, false, @psnd)
   else
    snd_Stop(psnd);
   end
  else
   psnd := snd_Play(snd, soundloop, ObjRect.x + 16, ObjRect.y + 8, false, @psnd);
  end;
Result := true;
end;

constructor TSoundTrigger.Create(struct_: TMapObjStruct);
begin
inherited;
snd      := snd_Load(PChar('sound\' + string(fstruct.soundname)));
FObjRect := Rect(x*32, y*16, 32*width, 16*height);
psnd    := -1;
end;

procedure TSoundTrigger.Draw;
begin
   //abstract
end;

procedure TSoundTrigger.restart;
begin
inherited;
timer := 0;
factive := fstruct.soundloop and (fstruct.active = 0);
psnd    := -1;
end;

procedure TSoundTrigger.Update;
var
 r : single;
begin
inherited;
if timer > 0 then
 dec(timer);

if psnd = -1 then factive := false;

if factive then
 begin
 snd_SetPos(psnd, Point2f(ObjRect.x, ObjRect.y));
 if fstruct.soundradius > 0 then
  with Map.Camera.Pos do
   begin
   r := sqrt(sqr(X - ObjRect.x - 16) + sqr(Y - ObjRect.y - 8));
   if r > fstruct.soundradius then
    snd_SetVolume(psnd, 0)
   else
    snd_SetVolume(psnd, 100 - trunc(r/fstruct.soundradius * 100))
   end;
 end;  
end;

{ TDestroyerObj }

function TDestroyerObj.Activate(sender: TObject): boolean;
var
 i, j, x, y: integer;
 wx, wy : integer;
 px, py : integer;
 segs: integer;
begin
//уничтожаем!!!
result:=factive;
if sender is TPlayer then Exit;
if factive then
 begin
 factive:=false;
 for j := 0 to Height - 1 do
  for i := 0 to Width - 1 do
   begin
   x := i*32 + objrect.X;
   y := j*16 + objrect.Y;

   segs := 2 shl fstruct.partscount;

   px := 32 div segs;
   py := 16 div segs;

   for wy := 0 to segs - 1 do
    for wx := 0 to segs - 1 do
       if brk[i+j*width]>0 then
     Particle_Add(TP_Brick.Create(Point2f(x  + wx * px + px/2, y + wy * py + py/2), 1/segs * wx, 1/segs * wy, 1/segs, Map.BrkTex[brk[i+j*width]]));
   end;
  DestroyIt;
 end;//if factive
end;

procedure TDestroyerObj.Charge;
var
   i, j, x, y: integer;
begin
   factive:=true;
//"заряжаем" карту
   if fOwner=nil then
   begin
   for j := 0 to Height - 1 do
 		for i := 0 to Width - 1 do
  		begin
         x:=i + fstruct.x;
         y:=j + fstruct.y;
         Map.Brk[x, y]:=brk[i + j*Width];
         Map.brk.Mask[x, y]:=
         Byte(mask[i + j*Width]) or (Map.brk.Mask[x, y] and not MASK_BLOCK and not MASK_FRONT);
      end;
   end else
   begin
   for j := 0 to Height - 1 do
 		for i := 0 to Width - 1 do
  		begin
         x:=i + fstruct.x-fOwner.struct.x;
         y:=j + fstruct.y-fOwner.struct.y;
         TBricksObj(fOwner).Brk[x+y*fOwner.Struct.width]:=brk[i + j*Width];
         TBricksObj(fOwner).Mask[x+y*fOwner.Struct.width]:=mask[i + j*Width];
      end;
   end;
end;

constructor TDestroyerObj.Create(struct_: TMapObjStruct);
begin
   inherited;
   fNetSize	:=	1;
end;

procedure TDestroyerObj.DestroyIt;
var
   i, j, x, y: integer;
begin
   factive:=false;
   if fOwner=nil then
   begin
      for j := 0 to Height - 1 do
 		   for i := 0 to Width - 1 do
  		   begin
            x:=i + fstruct.x;
            y:=j + fstruct.y;
            Map.Brk[x, y]:=0;
            Map.brk.Mask[x, y]:=Map.brk.Mask[x, y] and not MASK_BLOCK and not MASK_FRONT;
         end;
   end else
   begin
      for j := 0 to Height - 1 do
 		   for i := 0 to Width - 1 do
  		   begin
            x:=i + fstruct.x-fOwner.Struct.x;
            y:=j + fstruct.y-fOwner.Struct.y;
            TBricksObj(fOwner).brk[x+y*fOwner.struct.width]:=0;
            TBricksObj(fOwner).mask[x+y*fOwner.struct.width]:=0;
         end;
   end;
end;

procedure TDestroyerObj.Draw;
begin
   //abstract
end;

function TDestroyerObj.Hit(damage: integer): boolean;
begin
   Result:=false;
   if health>0 then
   begin
      health:=health-damage;
      if health<=0 then
      begin
         Result:=true;
         Activate(Self);
      end;
   end;
end;

procedure TDestroyerObj.LoadFromRec(rec: TDemoObjRec);
begin
   factive:=boolean(rec.reserved[0]);
   if not factive then
      DestroyIt;
   health:=rec.reserved[1];
end;

procedure TDestroyerObj.LoadNet(w: array of word);
begin
   factive:=boolean(w[0]);
   if not factive then DestroyIt;
end;

procedure TDestroyerObj.restart;
begin
  inherited;
   Charge;
   health:=fstruct.partshealth;
end;

procedure TDestroyerObj.SaveNet(var w: array of word);
begin
   w[0]:=ord(factive);
end;

function TDestroyerObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   Result:=true;
   rec.reserved[0]:=ord(factive);
   if health<0 then health:=0;
   rec.reserved[1]:=health;
end;

procedure TDestroyerObj.TakeBricks;
var
 i, j, x, y: word;
begin
	SetLength(brk, Width*Height);
	SetLength(mask, Width*Height);
	for j := 0 to Height - 1 do
 		for i := 0 to Width - 1 do
  		begin
  			x:=i + fstruct.x; y:=j + fstruct.y;
			brk[i + j*Width] := Map.Brk[x, y];
      	mask[i + j*Width] := Map.Brk.Mask[x, y];
//         if mask[i+j*Width] and MASK_BLOCK>0 then blocks:=true;
//			Map.Brk.Mask[x, y]:=Map.Brk.Mask[x, y] or MASK_CONTAINER;//делаем брик невидимым.
  		end;
end;

{ TMonsterObj }

function TMonsterObj.Activate(sender: TObject): boolean;
const
   damage = 1;
begin
   Result:=false;
   if sender is TPlayer then
   begin
      if factive then
         with fstruct do
      begin
      	Result:=true;
         if monster_damage>0 then
 		      HitPlayerP(monster_damage, TPlayer(sender), nil, 0, true)
         else HitPlayerP(1, TPlayer(sender), nil, 0, true);
         with TPlayer(sender) do
            Particle_Blood(pos.x, pos.y);
         if monster_mode and 1>0 then
            Hit(health);
      end;
   end else
      if not factive then
      begin
         resp:=true;
         Restart;
      end;
end;

function TMonsterObj.Blocked: boolean;
begin
   Result:=fstruct.monster_mode and 2=0;
end;

constructor TMonsterObj.Create(struct_: TMapObjStruct);
var
   s1: string;
begin
   inherited;
   //грузим текстуру
   s1:='textures\special\monster'+IntToStr(fstruct.monster_color)+'.tga';
   if FileExists(Engine_Dir+Engine_ModDir+s1) then
      anim  := TObjTex.Create(s1, 1, 0, 5, true, false, nil)
   else
      anim  := TObjTex.Create('textures\special\monster', 1, 0, 5, true, false, nil);
   fplane:= pFront;
   fActivateMode:=false;
end;

procedure TMonsterObj.Draw;
begin
   if alpha<0.1 then Exit;
   xglTex_Enable(anim.Frame[frame mod 10]);
   glColor4f(1, 1, 1, alpha);
   if frame<10 then
   begin

 glBegin(GL_QUADS);
  glTexCoord2f(0, height);
   glVertex2f(round(xx)-16, round(yy)-16);
  glTexCoord2f(width, height);
   glVertex2f(round(xx)+16, round(yy)-16);
  glTexCoord2f(width, 0);
   glVertex2f(round(xx)+16, round(yy)+16);
  glTexCoord2f(0, 0);
   glVertex2f(round(xx)-16, round(yy)+16);
 glEnd;

 end else
   begin

 glBegin(GL_QUADS);
  glTexCoord2f(width, height);
   glVertex2f(round(xx)-16, round(yy)-16);
  glTexCoord2f(0, height);
   glVertex2f(round(xx)+16, round(yy)-16);
  glTexCoord2f(0, 0);
   glVertex2f(round(xx)+16, round(yy)+16);
  glTexCoord2f(width, 0);
   glVertex2f(round(xx)-16, round(yy)+16);
 glEnd;
   end;
end;

function TMonsterObj.Hit(damage: integer): boolean;
var
   objstruct: TRealObjStruct;
begin
   Result:=health>0;
   if health>0 then
   begin
      health:=health-damage;
      Particle_Blood(xx, yy);
      if health<=0 then
      begin
         with fstruct do
         if (ItemID>1) and (count>0) then
         begin
            fillchar(objstruct, sizeof(objstruct), 0);
            objstruct.objtype:=otItem;
            objstruct.playerUID:=0;
            objstruct.x:=xx;
            objstruct.y:=yy;
            objstruct.ItemID:=ItemID;
            objstruct.ItemCount:=count;
	         RealObj_Add(TFreeObj.Create(objstruct));
         end;
         factive:=false;
         ExplosionSound.Play(XX, YY);
         Particle_Add(TP_Explosion.Create(Point2f(xx, yy), WPN_ROCKET));
         light.die:=0;
         light:=nil;
      end;
   end;
end;

procedure TMonsterObj.LoadFromRec(rec: TDemoObjRec);
begin
   xx:=rec.reserved[0];
   yy:=rec.reserved[1];
   health:=rec.reserved[2];
   if health=0 then
   begin
      factive:=false;
      alpha:=0;
      light.die:=0;
      light:=nil;
   end;
   angle:=rec.reserved[3]/1000;
   Update;
end;

procedure TMonsterObj.restart;
const
   width = 32;
   height = 32;
   width2 = 36;
   height2 = 36;
begin
   smoketimer:=0;
   frame:=0;
   alpha:=1.0;
   if fstruct.monster_speed>0.1 then
      speed:=fstruct.monster_speed
   else speed:=1;
   angle:=0;

   xx:=X*32+16;
   yy:=Y*16+8;
   ObjRect:=Rect(round(xx-width/2),
                 round(yy-height/2),
                 width, height);
   startrect:=objrect;
   fActivateRect:=Rect(-width2 div 2+16,
                      -height2 div 2+8,
                      width2,
                      height2);

   delta:=0.05;
   if random(2)=1 then delta:=-delta;


   w:=16;h:=16;
   if (fstruct.target_name=0) or resp then
   begin
      health:=fstruct.monster_health;
      if health=0 then
         health:=125;
      angle:=0;
      Light := TP_Light(
         Particle_Add(
         TP_Light.Create(Point2f(xx, yy), Point2f(32, 32), NumToColor(fstruct.Monster_Color), 1)
         )
         );
      pl:=nil;timer:=0;
      factive:=true;
   end else
   begin
      factive:=false;
      alpha:=0.0;
   end;
   resp:=false;
end;

function TMonsterObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   Result:=true;
   rec.reserved[0]:=round(xx);
   rec.reserved[1]:=round(yy);
   if health<0 then health:=0;
   rec.reserved[2]:=health;
   while angle<0 do angle:=angle+2*Pi;
   rec.reserved[3]:=round(angle*1000);
end;

procedure TMonsterObj.Update;
var
   xx1, yy1, ss, ax, ay, a : single;
   s2: single;

begin
   Inc(fire);Inc(smoketimer);
   smoketimer:=smoketimer mod 25;
   fire:=fire mod 50;

   inherited;
   if (alpha<0.1) then Exit;
   if smoketimer=0 then
      Particle_Add(
      TP_Smoke.Create(Point2f(xx, yy))
      );
   if health<=0 then alpha:=alpha-0.06;

   if pl<>nil then
   begin
      ax := TPlayer(Pl).shotpos.X - xx;
      ay := TPlayer(Pl).shotpos.Y - yy;
      a := arctan2(ay, ax + 0.000001);
      if fstruct.monster_mode and 2>0 then
         ss:=800
      else ss:=Map.TraceVector(xx+cos(a)*72, yy+sin(a)*72, a);
      if Map.TracePlayers(xx, yy, a, ss, -1)<>pl then
         Inc(timer)
         else
         begin
            timer:=0;
            angle:=a;
         end;
      if timer=100 then
      begin
         pl:=nil;
         delta:=0.05;
         if random(2)=1 then delta:=-delta;
      end;
   end
      else
   begin
      angle:=angle+delta;
      if fstruct.monster_mode and 2>0 then
         ss:=800
      else ss:=Map.TraceVector(xx+cos(angle)*72, yy+sin(angle)*72, angle);
      pl:=Map.TracePlayers(xx, yy, angle, ss, -1);
   end;

   //ищем игрока, направляемся к нему.
   //update xx, yy
   sx:=speed*cos(angle);
   sy:=speed*sin(angle);
   if (pl<>nil) and (ss<250) then
   begin
      sx:=sx*1.5; sy:=sy*1.5;
   end;

   if 2*abs(sx)<abs(sy) then
      frame:=0
   else if abs(sx)<2*abs(sx) then
      frame:=1
   else frame:=2;
   if sy<0 then frame:=4-frame;
   if (fire>=25) then
      if (frame in [1..3]) then
         frame:=frame+4
      else frame:=(frame+10) mod 20;
   if sx<0 then frame:=(frame+10) mod 20;


   xx1:=xx+sx;yy1:=yy+sy;
   s2:=0.5;
   if fstruct.monster_mode and 2=0 then
   begin

   if Map.block_s_(xx1-w/2*s2, yy1-h/2*s2) or
      Map.block_s_(xx1-w/2*s2, yy1+h/2*s2) or
      Map.block_s_(xx1-w/2, yy1) then
         if xx1<xx then xx1:=xx;
   if Map.block_s_(xx1+w/2*s2, yy1-h/2*s2) or
      Map.block_s_(xx1+w/2*s2, yy1+h/2*s2) or
      Map.block_s_(xx1+w/2, yy1) then
         if xx1>xx then xx1:=xx;
   if Map.block_s_(xx1-w/2*s2, yy1-h/2*s2) or
      Map.block_s_(xx1+w/2*s2, yy1-h/2*s2) or
      Map.block_s_(xx1, yy1-h/2) then
         if yy1<yy then yy1:=yy;
   if Map.block_s_(xx1-w/2*s2, yy1+w/2*s2) or
      Map.block_s_(xx1+h/2*s2, yy1+h/2*s2) or
      Map.block_s_(xx1, yy1+h/2) then
         if yy1>yy then yy1:=yy;
   if (xx1=xx) and (yy1<>yy) then
      if yy1<yy then yy1:=yy-speed
      else yy1:=yy+speed
   else
   if (yy1=yy) and (xx1<>xx) then
      if xx1<xx then xx1:=xx-speed
      else xx1:=xx+speed;
   end;

   xx:=xx1;yy:=yy1;
   if light<>nil then
   begin
      light.Pos.X:=xx;
      light.Pos.Y:=yy;
   end;
   ObjRect:=Rect(round(xx-ObjRect.Width/2),
                 round(yy-ObjRect.Height/2),
                 ObjRect.width, ObjRect.height);
end;

end.

