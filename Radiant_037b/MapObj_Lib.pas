unit MapObj_Lib;

interface

{OBJECT MANIFEST
  каждый объект имеет таргет при котором он активируется (targetname) и таргет который он
     использует после активации(target).
  procedure Activate имеет различный вид для активирования игроком и активирования другим объектом

  тип активации другим объектом(Active: byte):
     0 - объект не может быть активирован/деактивирован
     1,2 - объект активируется/деактивируется только если он в начальном положении
  начальное положение объекта определяется различными переменными в зависимости от оьъекта.

  объект активирует другие объекты (с таргетом target) после waittarget тактов,
  если конечно он специального типа (кнопка, триггер).

  НАСЛЕДОВАНИЕ ОБЪЕКТОВ В РЕДАКТОРЕ:
  basic object->button object->respawn object
  basic object->jumppad object
}

uses
  MyEntries, Windows, ClickPs;

const
   ObjCaseSize = 54;
   NULLTARGET = 65535;

type
 TObjType = (otNone, otRespawn, otJumpPad,
   otArmor, otHealth, otPowerUp, otWeapon, otAmmo,
 	otTeleport, otButton, oTNFKDoor, otTrigger, otDeathLine,
   otWater, otElevator, otTriangle,
   otAreaPush, otAreaPain, otLava, otArenaEnd, otAreaTeleport, otTeleportWay,
   otEmptyBricks, otBackBricks, otLightLine, otBloodGen,
   otWeather);

type
 TMapObjStruct =
 record
    x, y, width, height: word;  //4
    active: byte;//1
    orient: byte;//1   0 - влево, 1-вправо, 2- вверх, 3-вниз
    //для двери 0, 1- вертикально, 2,3 горизонтально
    //ДЛЯ ТРЕУГОЛЬНИКА - 0- нижний левый, 1-верхний левый 2- верхний правый 3- нижний правый
    target_name, target: word;//2  номер таргета активирования объекта
    //2  номер таргета активирования ДРУГОГО объекта
    wait, waittarget: word;  //4
    itemID, count: word;//4

    case ObjType: TObjType of
       otNone: (reserved:array [0..ObjCaseSize-1] of byte);//определяет постоянный размер
       otRespawn: (//сторона куда игрок смотрит после рождения.
       				);
       otJumpPad: (jumpspeed: single);
       otTeleport: (gotox, gotoy: word);
       otButton: (color: byte);
       otNFKDoor: (opened: boolean);
       otWeapon: (weaponID: word);
       otDeathLine: (angle, maxlen: single; linedamage, linedamagewait: integer);
       otElevator: (elevspeed: single; elevx, elevy: smallint;
       	etargetname1, etargetname2, etarget1, etarget2: word;
         eactive: boolean);
       otAreaPush: (pushspeedx, pushspeedy: smallint; pushwait: word);
       otAreaPain: (paindamage, painwait: word);
       otBackBricks: (plane: byte);
       otBloodGen: (bloodangle, bloodL: single; bloodwait, bloodtype, bloodcount: word);
 end;

 PMapObjStruct=^TMapObjStruct;

type
   TCustomMapObj = class(TCustomCPObj)
    	constructor create(struct_: TMapObjStruct);
   protected
        fStruct: TMapObjStruct;
        function GetX: word;override;
        function GetY: word;override;
        function GetWidth: word;override;
        function GetHeight: word;override;
   public
      property Struct: TMapObjStruct read fStruct write fstruct;
      property ObjType: TObjType read fStruct.ObjType;
      property Target_Name: word  read fStruct.Target_Name;
      property ItemID: word read fStruct.ItemID write fstruct.ItemID;
      //Next functions need MAP object from main module
      function SetX(Value: integer): integer;override;
      function SetY(Value: integer): integer;override;
      function SetLeftX(Value: integer): integer;override;
      function SetTopY(Value: integer): integer;override;
		function SetWidth(Value: integer): integer;override;
      function SetHeight(Value: integer): integer;override;
      //graph rect- рект где объект можно рисовать.
      function GraphRect: TRect;virtual;

      procedure SetDefValues;virtual;
   end;

   TItemObj =
   class(TCustomMapObj)
    	constructor create(struct_: TMapObjStruct);
      procedure SetDefValues;override;
   end;

   TAreaObj =
   class(TCustomMapObj)
      constructor create(struct_: TMapObjStruct);
   end;

   TButtonObj =
   class(TCustomMapObj)
      constructor create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
      procedure Action2(sender:TClickPoint; x, y: integer);override;
      function GraphRect: TRect;override;
   end;

  TTeleportObj =
  class( TCustomMapObj )
     constructor create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
      procedure Action2(sender:TClickPoint; x, y: integer);override;
      function GraphRect: TRect;override;
  end;

  TAreaTeleportObj =
  class( TAreaObj )
     constructor create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
      function GraphRect: TRect;override;
  end;

  TRespawnObj =
  class( TCustomMapObj )
     constructor Create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
      procedure Action2(sender:TClickPoint; x, y: integer);override;
      procedure Action3(sender:TClickPoint; x, y: integer);override;
      procedure SetDefValues;override;
      function GraphRect: TRect;override;
  end;

  TJumpPadObj =
  class( TCustomMapObj )
  protected
     jumppoint: TClickPoint;
  public
     constructor Create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
      function SpeedToHeight(speed: single): integer;
      function HeightToSpeed(height: integer): single;
      function GetJumpHeight: integer;

      procedure SetJumpPoint;
  end;

  TDeathLine =
  class(TCustomMapObj)
  protected
    function GetDX: integer;
    function GetDY: integer;
  public
     constructor Create(struct_: TMapObjStruct);
     property DX: integer read GetDX;
     property DY: integer read GetDY;
     procedure SetDXY(dx_, dy_: single);
     procedure Action1(sender:TClickPoint; x, y: integer);override;
     procedure SetDefValues;override;

     function GraphRect: TRect;override;
  end;


  TElevator =
  class(TAreaObj)
     constructor Create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
     procedure SetDefValues;override;
     function GraphRect: TRect;override;
  end;

   TTriangleObj =
   class(TAreaObj)
      constructor create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
     procedure SetDefValues;override;
   end;

   TNFKDoor =
   class(TAreaObj)
      constructor create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
      procedure Action2(sender:TClickPoint; x, y: integer);override;
   end;

   TTeleportWayObj = class(TAreaObj)
     constructor create(struct_: TMapObjStruct);
      procedure Action1(sender:TClickPoint; x, y: integer);override;
     function GraphRect: TRect;override;
   end;

function HelpObj(Obj: TCustomMapObj): string;

implementation

uses Math, Graphics, Main, Constants_Lib, SysUtils;

function Min(x, y: integer): integer;
begin
   if x<y then Result:=x
      else Result:=y;
end;

function Max(x, y: integer): integer;
begin
   if x>y then Result:=x
      else Result:=y;
end;

function HelpObj(Obj: TCustomMapObj): string;
begin
   case Obj.ObjType of
   	otNFKDoor, otDeathLine, otAreaPain: Result:='Target name: '+IntToStr(obj.struct.target_name);
   	otButton, otTrigger, otLightLine: Result:='Target: '+IntToStr(obj.struct.target);
      else Result:='';
   end;
end;

{ TCustomMapObj }

constructor TCustomMapObj.create(struct_: TMapObjStruct);
begin
   fstruct:=struct_;
end;

function TCustomMapObj.GetHeight: word;
begin
   Result:=fstruct.Height;
end;

function TCustomMapObj.GetWidth: word;
begin
   Result:=fstruct.Width;
end;

function TCustomMapObj.GetX: word;
begin
   Result:=fstruct.X;
end;

function TCustomMapObj.GetY: word;
begin
   Result:=fstruct.Y;
end;

function TCustomMapObj.GraphRect: TRect;
begin
   Result.Left:=X;
   Result.Top:=Y;
   Result.Right:=(X+Width);
   Result.Bottom:=(Y+Height);
end;

procedure TCustomMapObj.SetDefValues;
begin
//
end;

function TCustomMapObj.SetHeight(Value: integer): integer;
begin
   if Value<1 then Value:=1;
  	if fStruct.y+Value>Map.Height then
     	Value:=Map.Height-struct.y;
   Result:=Value-fStruct.height;
   fStruct.Height:=Value;
end;

function TCustomMapObj.SetLeftX(Value: integer): integer;
begin
	if Value<0 then Value:=0;
  	if Value>fstruct.x+fstruct.width-1 then Value:=fstruct.x+fstruct.width-1;
   Result:=Value-fstruct.x;
   fstruct.width:=fstruct.width+fstruct.x-value;
   fstruct.x:=Value;
end;

function TCustomMapObj.SetTopY(Value: integer): integer;
begin
 	if Value<0 then Value:=0;
  	if Value>fstruct.y+fstruct.height-1 then Value:=fstruct.y+fstruct.height-1;
   Result:=Value-fstruct.y;
   fstruct.height:=fstruct.height+fstruct.y-value;
   fstruct.y:=Value;
end;

function TCustomMapObj.SetWidth(Value: integer): integer;
begin
   if Value<1 then Value:=1;
   if fStruct.x+Value>Map.Width then
     	Value:=Map.Width-struct.x;
   Result:=Value-fStruct.width;
   fStruct.Width:=Value;
end;

function TCustomMapObj.SetX(Value: integer): integer;
begin
	if Value<0 then Value:=0;
  	if Value>=Map.Width then Value:=Map.Width-1;
   Result:=Value-fstruct.x;
   fstruct.x:=Value;
end;

function TCustomMapObj.SetY(Value: integer): integer;
begin
   if Value<0 then Value:=0;
 	if Value>=Map.Height then Value:=Map.Height-1;
   Result:=Value-fstruct.y;
   fstruct.y:=Value;
end;

{ TItemObj }

constructor TItemObj.create(struct_: TMapObjStruct);
begin
   inherited;
   with fstruct do
   begin
   	if ItemID=0 then
      case objtype of
         otWeapon: ItemID:=weaponID;
         otAmmo: ItemID:=WPN_Ammo+weaponID;
         otPowerUp: ItemID:=REGEN_ID;
         otHealth: ItemID:=Health5_ID;
         otArmor: ItemID:=Shard_ID;
      end;
      if Count=0 then
      case objtype of
         otWeapon: count:=Def_Ammo[weaponID];
         otAmmo: count:=Ammo_Box[weaponID];
         otPowerUp: count:=25;
         otArmor: count:=Armors[ItemID];
         otHealth: count:=Healthes[ItemID];
      end;
      if wait=0 then
      case ObjType of
         otWeapon: wait:=WPN_Wait[WeaponID];
         otAmmo: wait:=Ammo_Wait;
         otPowerUp: wait:=PowerUp_Wait;
         otHealth: wait:=HealthWait[ItemID];
         otArmor: wait:=ArmorWait[ItemID];
      end;
{      if ObjType=otPowerup then
         waittarget:=ItemID*100
         else waittarget:=0;}
   end;
   AddPoint(Self, CenterPoint, 0, -10, clBlue);
end;

procedure TItemObj.SetDefValues;
begin
   with fstruct do
   begin
   	if ItemID=0 then
      case objtype of
         otWeapon: ItemID:=weaponID;
         otAmmo: ItemID:=WPN_Ammo+weaponID;
         otPowerUp: ItemID:=REGEN_ID;
         otHealth: ItemID:=Health5_ID;
         otArmor: ItemID:=Shard_ID;
      end;
      if Count=0 then
      case objtype of
         otWeapon: count:=Def_Ammo[weaponID];
         otAmmo: count:=Ammo_Box[weaponID];
         otPowerUp: count:=25;
         otArmor: count:=Armors[ItemID];
         otHealth: count:=Healthes[ItemID];
      end;
      if wait=0 then
      case ObjType of
         otWeapon: wait:=WPN_Wait[WeaponID];
         otAmmo: wait:=Ammo_Wait;
         otPowerUp: wait:=PowerUp_Wait;
         otHealth: wait:=HealthWait[ItemID];
         otArmor: wait:=ArmorWait[ItemID];
      end;
      if ObjType=otPowerUp then
         waittarget:=PowerUp_StartTime
         else waittarget:=0;
   end;
end;

{ TAreaObj }

constructor TAreaObj.create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, CenterPoint, 0, 0);
   AddPoint(Self, LeftPoint, 0, 0);
   AddPoint(Self, TopPoint, 0, 0);
   AddPoint(Self, RightPoint, 0, 0);
   AddPoint(Self, BottomPoint, 0, 0);
   AddPoint(Self, LeftTopPoint, 0, 0);
   AddPoint(Self, RightTopPoint, 0, 0);
   AddPoint(Self, LeftBottomPoint, 0, 0);
   AddPoint(Self, RightBottomPoint, 0, 0);
end;

{ TButtonObj }

procedure TButtonObj.Action1(sender:TClickPoint; x, y: integer);
begin
   fstruct.color:=(fstruct.color+1) mod 6;
end;

procedure TButtonObj.Action2(sender:TClickPoint; x, y: integer);
begin
  inherited;
//
end;

constructor TButtonObj.create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, CenterPoint, 8, -8);
   AddPoint(Self, ActionPoint1+[ptInvisible], 0, 0);
end;

function TButtonObj.GraphRect: TRect;
begin
   Result.Left:=X;
   Result.Top:=Y-1;
   Result.Right:=X;
   Result.Bottom:=Y+1;
end;

{ TTeleportObj }

procedure TTeleportObj.Action1(sender: TClickPoint; x, y: integer);
begin
   if fstruct.gotox+x<0 then
      fstruct.gotox:=0 else
   	fstruct.gotox:=fstruct.gotox+x;
   if fstruct.gotoy+y<0 then
      fstruct.gotoy:=0 else
      fstruct.gotoy:=fstruct.gotoy+y;

   if sender<>nil then
      sender.ChangeFXY(fstruct.gotox*32+16, fstruct.gotoy*16-24);
end;

procedure TTeleportObj.Action2(sender: TClickPoint; x, y: integer);
begin
   fstruct.orient:=1-fstruct.orient;
end;

constructor TTeleportObj.create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, CenterPoint, 0, -8);
   AddPoint(Self, [ptSelective, ptAlways, ptNoCopy, ptAction1], fstruct.gotox*32+16, fstruct.gotoy*16-24, clMaroon);
   AddPoint(Self, ActionPoint2, 0, -48, clOlive);
end;

function TTeleportObj.GraphRect: TRect;
begin
   with fstruct do
   begin
   Result.Left:=	Min(	(X-1), gotox		);
   Result.Right:=	Max( 	(X+1), (gotox+1)	);
   Result.Top:=   Min(  (Y-2), (gotoy-2)  );
   Result.Bottom:=Max(  (Y+1), (gotoy+1)  );
   end;
end;

{ TAreaTeleportObj }

procedure TAreaTeleportObj.Action1(sender: TClickPoint; x, y: integer);
var
   cp: TClickPoint;
begin
   if fstruct.gotox+x<0 then
      fstruct.gotox:=0 else
   	fstruct.gotox:=fstruct.gotox+x;
   if fstruct.gotoy+y<0 then
      fstruct.gotoy:=0 else
      fstruct.gotoy:=fstruct.gotoy+y;

   cp:=TClickPoint(sender);
   if cp<>nil then
      cp.ChangeFXY(fstruct.gotox*32+16, fstruct.gotoy*16-24);
end;

constructor TAreaTeleportObj.create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, [ptSelective, ptAlways, ptNoCopy, ptAction1], fstruct.gotox*32+16, fstruct.gotoy*16-24, clMaroon);
end;

function TAreaTeleportObj.GraphRect: TRect;
begin
   with fstruct do
   begin
   Result.Left:=	Min(	X, gotox		);
   Result.Right:=	Max( 	(X+Width), (gotox+1)	);
   Result.Top:=   Min(  Y, (gotoy-2)  );
   Result.Bottom:=Max(  (Y+Height), (gotoy+1)  );
   end;
end;

{ TRespawnObj }

procedure TRespawnObj.Action1(sender: TClickPoint; x, y: integer);
begin
   fstruct.orient:=0;
end;

procedure TRespawnObj.Action2(sender: TClickPoint; x, y: integer);
begin
   fstruct.orient:=1;
end;

procedure TRespawnObj.Action3(sender: TClickPoint; x, y: integer);
begin
   fstruct.orient:=1-fstruct.orient;
end;

constructor TRespawnObj.Create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, CenterPoint, 0, -8);
   AddPoint(Self, ActionPoint1+[ptInvisible], -12, -32, clRed);
   AddPoint(Self, ActionPoint2+[ptInvisible], 12, -32, clRed);
   AddPoint(Self, ActionPoint3+[ptInvisible], 0, -32, clRed);
end;

function TRespawnObj.GraphRect: TRect;
begin
   Result.Left:=(X-1);
   Result.Right:=(X+1);
   Result.Top:=(Y-2);
   Result.Bottom:=(Y+1);
end;

procedure TRespawnObj.SetDefValues;
begin
   fstruct.orient:=ord(fstruct.x<Map.Width div 2);
end;

{ TJumpPadObj }

procedure TJumpPadObj.Action1(sender: TClickPoint; x, y: integer);
//var
//   h: integer;
begin
//   h:=GetJumpHeight-y;
//   fstruct.JumpSpeed:=HeightToSpeed(h);
//   SetJumpPoint;
end;

constructor TJumpPadObj.Create(struct_: TMapObjStruct);
begin
   inherited;
   if fstruct.orient<2 then
      fstruct.orient:=2;
   AddPoint(Self, CenterPoint, 0, 6, clBlue);
  	JumpPoint:=AddPoint(Self, [ptPixel, ptAlways, ptNoCopy, ptAction1, ptLeftAlign, ptBottomAlign, ptRightAlign], 0, -GetJumpHeight, clOlive)
end;

function TJumpPadObj.GetJumpHeight: integer;
begin
   Result:=SpeedToHeight(fstruct.jumpspeed);
end;

function TJumpPadObj.HeightToSpeed(height: integer): single;
begin
   if height<74 then height:=74;
   if height>221 then height:=221;

   Result:=sqrt((height+5.16-6)*0.112);

   if Result<3.0 then Result:=3.0;
   if Result>5.0 then Result:=5.0;
end;

procedure TJumpPadObj.SetJumpPoint;
begin
   TClickPoint(JumpPoint).ChangeFXY(0, -GetJumpHeight);
end;

function TJumpPadObj.SpeedToHeight(speed: single): integer;
begin
   if speed>5 then
      speed:=5;
   if speed<3 then
      speed:=3;
   //speed от 3 до 5 всегда - смотреть физику TFK
   Result:=round(speed*speed/0.112+6-5.16);//все просчитано до МЕЛОЧЕЙ!!!!!!
end;

{ TDeathLine }

procedure TDeathLine.Action1(sender: TClickPoint; x, y: integer);
begin
   SetDXY(x+dx, y+dy);
   TClickPoint(sender).ChangeFXY(dx, dy);
end;

constructor TDeathLine.Create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, CenterPoint, 0, 0, clBlue);
   AddPoint(Self, [ptPixel, ptAlways, ptNoCopy, ptAction1, ptLeftAlign, ptBottomAlign, ptRightAlign, ptTopAlign], dx, dy);
end;

function TDeathLine.GetDX: integer;
begin
   with fstruct do
   	Result:=round(maxlen*cos(angle));
end;

function TDeathLine.GetDY: integer;
begin
   with fstruct do
   	Result:=round(maxlen*sin(angle));
end;

function TDeathLine.GraphRect: TRect;
begin
   Result.Left:=	Min(	X,	round(dx/32));
   Result.Right:=	Max((X+Width), round(dx/32+1));
   Result.Top:=	Min(	Y,	round(dy/16)+Y*16);
   Result.Bottom:=Max((Y+Height), round(dy/16+1)+Y);
end;

procedure TDeathLine.SetDefValues;
begin
   fstruct.linedamage:=1;
   fstruct.linedamagewait:=3;
end;

procedure TDeathLine.SetDXY(dx_, dy_: single);
var
   len: single;
begin
   with fstruct do
   begin
      len:=sqrt(sqr(dx_)+sqr(dy_));
      if len<16 then Exit;
      maxlen:=len;
      angle:=Arccos(dx_/len);
      if dy_<0 then angle:=Pi*2-angle;
   end;
end;

{ TElevator }

procedure TElevator.Action1(sender: TClickPoint; x, y: integer);
var
   cp: TClickPoint;
begin
   fstruct.elevx:=fstruct.elevx+x;
   fstruct.elevy:=fstruct.elevy+y;

   cp:=TClickPoint(sender);
   if cp<>nil then
      cp.ChangeFXY(fstruct.elevx*32+16, fstruct.elevy*16+8);
end;

constructor TElevator.Create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, [ptAlways, ptNoCopy, ptAction1, ptLeftAlign, ptTopAlign], fstruct.elevx*32+16, fstruct.elevy*16+8, clMaroon);
end;

function TElevator.GraphRect: TRect;
begin
   with fstruct do
   begin
   Result.Left:=	Min(	X,	elevx+X);
   Result.Right:=	Max((X+Width), elevx+(X+Width));
   Result.Top:=	Min(	Y,	elevy+Y);
   Result.Bottom:=Max((Y+Height), elevy+(Y+Height));
   end;
end;

procedure TElevator.SetDefValues;
begin
   fstruct.width:=2;
   fstruct.height:=1;
   fstruct.eactive:=true;
   fstruct.elevspeed:=1.0;
   fstruct.etargetname1:=NULLTARGET;
   fstruct.etargetname2:=NULLTARGET;
   fstruct.etarget1:=NULLTARGET;
   fstruct.etarget2:=NULLTARGET;
end;

{ TTriangleObj }

procedure TTriangleObj.Action1(sender: TClickPoint; x, y: integer);
begin
   fstruct.orient:=(fstruct.orient+1) mod 4;
end;

constructor TTriangleObj.create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, [ptAction1, ptLeftAlign, ptTopAlign], 6, 6, clGreen);
end;

procedure TTriangleObj.SetDefValues;
begin
   fstruct.Width:=4;
   fstruct.Height:=3;
   fstruct.ItemID:=1;
end;

{ TNFKDoor }

procedure TNFKDoor.Action1(sender: TClickPoint; x, y: integer);
begin
   fstruct.orient:=3-fstruct.orient;
end;

procedure TNFKDoor.Action2(sender: TClickPoint; x, y: integer);
begin
   fstruct.opened:=not fstruct.opened;
end;

constructor TNFKDoor.create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, [ptAction1, ptLeftAlign, ptTopAlign], 6, 6, clGreen);
   AddPoint(Self, [ptAction2, ptRightAlign, ptTopAlign], -6, 6, clGreen);
end;

{ TTeleportWayObj }

procedure TTeleportWayObj.Action1(sender: TClickPoint; x, y: integer);
var
   cp: TClickPoint;
begin
   if fstruct.gotox+x<0 then
      fstruct.gotox:=0 else
   	fstruct.gotox:=fstruct.gotox+x;
   if fstruct.gotoy+y<0 then
      fstruct.gotoy:=0 else
      fstruct.gotoy:=fstruct.gotoy+y;

   cp:=TClickPoint(sender);
   if cp<>nil then
      cp.ChangeFXY(fstruct.gotox*32+16, fstruct.gotoy*16+8);
end;

constructor TTeleportWayObj.create(struct_: TMapObjStruct);
begin
   inherited;
   AddPoint(Self, [ptSelective, ptAlways, ptNoCopy, ptAction1], fstruct.gotox*32+16, fstruct.gotoy*16+8, clMaroon);
end;

function TTeleportWayObj.GraphRect: TRect;
begin
   with fstruct do
   begin
   Result.Left:=	Min(	X,	(gotox+X));
   Result.Right:=	Max((X+Width), (gotox+X+Width));
   Result.Top:=	Min(	Y,	(gotoy+Y));
   Result.Bottom:=Max((Y+Height), (gotoy+Y+Height));
   end;
end;

end.
