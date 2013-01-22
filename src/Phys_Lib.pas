unit Phys_Lib;

interface

uses
 	Func_Lib,
 	Type_Lib,
 	Graph_Lib,
 	Math_Lib,
	TFKEntries,
   MapObj_Lib;

type
   TVarName = string[40];

   TPhysVariable =
   record
      name: TVarName;
      value: pointer;
      type_: TVarType;
      default_value: single;
   end;

procedure phys_register(varname: TVarName; vv: pointer; vartype: TVarType);
function phys_getstrvalue(ind: integer): string;
function phys_getvarname(ind: integer): string;
function phys_getvarscount: integer;
procedure phys_netrecv(varname, strvalue: string);

var
   ground_friction   : single = 1.14;
   ground_maxspeed   : single = 3.0;
   air_friction      : single = 1.03;
   air_maxspeed      : single = 3.0;
   default_gravity 	: single = 0.15;
   jumppad_1			: single = 6.1;
   jumppad_2			: single = 7.5;
   maxspeed_x			: single = 100.0;
   maxspeed_falling 	: single = 6.0;
   maxspeed_jumping	: single = 100.0;
   phys_freq         : integer = 1;
   phys_flag         : boolean;
   falling_damage_speed: single= 9.0;
   falling_damage    : integer = 25;
   falling_damage_base: integer = 10;

type
   TPhysicParams =
   record
      //параметры физики ТФК в данном месте
      minspeed, maxspeed: TPoint2f;
      air_speed: TPoint2f;
      gr_maxX, air_maxX: single;
      flight: boolean;
   end;

   TTFKPhysMap =
   class(TTFKMap)
   	function block_s(X, Y: single): boolean;
   	function block_s_(X, Y: single): boolean;
   	function block_sObj(X, Y: single; var pobj: TPhysObj; IgnoreEmpty: boolean=false): boolean;
   	function block_b(X, Y: word): boolean;
      function block_b_(X, Y: word): boolean;
   	function block_bObj(X, Y: word): boolean;
   	function block_Dot_Product(X, Y: single; dx, dy: single; count: integer): integer;
   	function block_Water_s(X, Y: single): boolean;
   	function block_Lava_s(X, Y: single): boolean;
   	procedure block_BrkOptimize;//оптимизирует объекты и брики.. :) чтобы не тормозило,
      procedure Optimize_Update;

      //переделанная физика.

      //здесь введены правила гравитации.
      procedure phys_gravity(var pp: TPhysRect);
      procedure phys_friction(var ph: TPhysRect);
      //здесь ведётся проверка на пересечения со стенами
      procedure phys_cliptest(var ph: TPhysRect);
      procedure phys_params(X, Y: single; var pp: TPhysicParams);
   private
      g_dpos: PPoint2f;
      ylist: array of array of integer;
   public
   //теперь для геометрии
		function TraceVector(x, y, angle: single): single;
		function TraceVectorElev(x, y, angle: single; Elev: TElevatorObj; var s : single): boolean;
		function ShootActivation(x, y, angle: single; s: single; sender: TObject=nil; damage: integer = 0): boolean;
   end;

procedure Phys_Init;
function Phys_Cmd(Cmd: ShortString): boolean;
procedure Phys_Default;
function Phys_GetBufSize: integer;
function Phys_WriteBuf(var buf: array of byte): integer; //возвращает размер используемого буфера
procedure Phys_ReadBuf(buf: array of byte; size: integer);

procedure Phys_Lock;
procedure Phys_Unlock;

implementation

uses Engine_Reg, SysUtils_, Player_Lib, Constants_Lib, NET_Lib, NET_Server_Lib, Map_Lib;

var
   phys_vars: array [1..1000] of TPhysVariable;
   pvcount: integer = 0;
   locks: integer;
   pblock: boolean=false;
   phys_bufsize: integer = 0;

procedure Phys_Lock;
begin
   inc(locks);
end;
procedure Phys_Unlock;
begin
   dec(locks);
end;

type
   PSingle = ^single;
   PInt = ^integer;
   PWord = ^word;

procedure Phys_Register(varname: TVarName; vv: pointer; vartype: TVarType);
var
   i: integer;
begin
   for i:=1 to pvcount do
      if varname=phys_vars[i].name then
         Exit;
   Inc(pvcount);
   with phys_vars[pvcount] do
   begin
      name:=varname;
      value:=vv;
      type_:=vartype;
         case type_ of
            VT_FLOAT: begin default_value:=PSingle(value)^; Inc(phys_bufsize, sizeof(single)); end;
            VT_INTEGER: begin default_value:=PInt(value)^; Inc(phys_bufsize, 4);end;
            VT_WORD   : begin default_value:=PWord(value)^; Inc(phys_bufsize, 2); end;
         end;
   end;
end;

function phys_getstrvalue(ind: integer): string;
begin
   Result:='';
   if (ind>=1) and (ind<=pvcount) then
      with phys_vars[ind] do
         case type_ of
            VT_FLOAT: Result:=FloatToStr(PSingle(value)^);
            VT_INTEGER: Result:=IntToStr(PInt(value)^);
            VT_WORD   : Result:=IntToStr(PWord(value)^);
         end;
end;

function phys_getvarname(ind: integer): string;
begin
   Result:='';
   if (ind>=1) and (ind<=pvcount) then
      with phys_vars[ind] do
         Result:=name;
end;

function phys_getvarscount: integer;
begin
   Result:=pvcount;
end;

procedure Phys_Init;
begin
   phys_bufsize:=0;
   phys_register('ground_friction', @ground_friction, VT_FLOAT);
   phys_register('ground_maxspeed', @ground_maxspeed, VT_FLOAT);
   phys_register('air_friction', @air_friction, VT_FLOAT);
   phys_register('air_maxspeed', @air_maxspeed, VT_FLOAT);
   phys_register('gravity', @default_gravity, VT_FLOAT);
   phys_register('jumppad_1', @jumppad_1, VT_FLOAT);
   phys_register('jumppad_2', @jumppad_2, VT_FLOAT);
   phys_register('maxspeed_x', @maxspeed_x, VT_FLOAT);
   phys_register('maxspeed_falling', @maxspeed_falling, VT_FLOAT);
   phys_register('maxspeed_jumping', @maxspeed_jumping, VT_FLOAT);
   phys_register('freq', @phys_freq, VT_INTEGER);
   phys_register('falling_damage_speed', @falling_damage_speed, VT_FLOAT);
   phys_register('falling_damage', @falling_damage, VT_INTEGER);
   phys_register('falling_damage_base', @falling_damage_base, VT_INTEGER);
end;

procedure phys_netrecv(varname, strvalue: string);
var
   i: integer;
   val: single;
begin
  // Присвоение значения параметру
   for i:=1 to pvcount do
       with phys_vars[i] do
        if varname=name then
        begin
           if StrToFloat(strvalue, val) then
           begin
               case type_ of
                  VT_INTEGER: pint(value)^:=round(val);
                  VT_FLOAT: psingle(value)^:=val;
                  VT_WORD   : PWord(value)^:=round(val);
               end;
           end;
           Break;
        end;
end;

procedure Phys_Default;
var
   i: integer;
begin
   for i:=1 to pvcount do
      with phys_vars[i] do
      begin
               case type_ of
                  VT_INTEGER: pint(value)^:=round(default_value);
                  VT_FLOAT: psingle(value)^:=default_value;
                  VT_WORD   : PWord(value)^:=round(default_value);
               end;
      end;
end;

function Phys_Cmd(Cmd: ShortString): boolean;
var
 par  : array [1..3] of string;
 i    : integer;
 str  : string;
 R, R1    : boolean;
 F    : TextFile;
 val: single;
begin
Result := true;
str    := Func_Lib.LowerCase(cmd);
for i := 1 to 3 do
 par[i] := StrSpace(str);

if par[2] <> ''  then
 begin
    if pblock then Exit;
 if par[2] = 'save' then
  begin
   Log('^2Saving physic to phys.cfg...');
   try
      AssignFile(F, Engine_ModDir + 'phys.cfg');
      Rewrite(F);
      for i:=1 to pvcount do

         writeln(F, 'phys '+ phys_vars[i].name+' ' + phys_getstrvalue(i));
      CloseFile(F);
      Log('^2Ok');
   except
    // XProger: Едрить твою мать... %)
    Log('^1Error');
   end;
  Exit;
  end;

 if par[2] = 'load' then
  begin
    if pblock then Exit;

   if (NET.Type_=NT_CLIENT) and (locks=0) then
   begin
     Log('^2Only server can use "phys load" command!');
     Exit;
   end;

   pblock:=true;
   Phys_Default;
   pblock:=false;
   if NET.Type_=NT_SERVER then
      NET_Server.phys_SendAll;
   Exit;
  end;

  if par[2] = 'default' then
  begin
     phys_default;
     Log('^2Default physic loaded!');
  end;

 if par[2] = 'info' then
 begin
    Log('^b Phys commands List: ');
    for i:=1 to pvcount do
       Log('^3- '+phys_vars[i].name);
    Log('^b End of list');
    Exit;
 end;

 if par[3] <> '' then
  begin

  if Map.IsCLientGame and (locks=0) then
  begin
     Log('^2Only server can change the game physic!');
     Exit;
  end;

     R1:=false;
     R:=false;
  // Присвоение значения параметру
     for i:=1 to pvcount do
         with phys_vars[i] do
        if par[2]=name then
        begin
           R := StrToFloat(par[3], val);
           R1:=true;
           if R then
           begin
               case type_ of
                  VT_INTEGER: pint(value)^:=round(val);
                  VT_FLOAT: psingle(value)^:=val;
                  VT_WORD:  pword(value)^:=round(val);
               end;
               //отсылаем по сетке то, что мы изменили:
               if (NET.Type_=NT_SERVER) and not pblock then
                  NET_Server.phys_Send(i);
           end;
           Break;
        end;
      if not R1 then
      begin
         Log('^1Invalid physic parameter');
         Exit;
      end else
      if not R then
         Log('^1Invalid value');
  end;

 // Вывод значения параметра
  R:=false;
  for i:=1 to pvcount do
      with phys_vars[i] do
         if par[2]=name then
         begin
            Log('^b'+par[2] + ' = '+phys_getstrvalue(i));
            R:=true;
         end;
  if not R then
  begin
   Log('^1Invalid physic parameter');
   Exit;
  end;
 end
else
begin
//phys help
   Log('^3 ^bphys load^n ^7- ^2phys default');
   Log('^3 ^bphys save^n ^7- ^2save physic to phys.cfg');
   Log('^3 ^bphys info^n ^7- ^2list of all physic commands');
   Log('^3 ^bphys default^n ^7- ^2restore the DEFAULT physic');
end;
end;

function Phys_GetBufSize: integer;
begin
   Result:=phys_bufsize;
end;

function Phys_WriteBuf(var buf: array of byte): integer;
var
   i, pos: integer;

   procedure Write(var x; size: integer);
   begin
      Move(x, buf[pos], size);
      Inc(pos, size);
   end;

begin
   pos:=0;
   for i:=1 to pvcount do
      with phys_vars[i] do
         case type_ of
            VT_INTEGER: Write(value^, 4);
            VT_FLOAT: Write(value^, sizeof(single));
            VT_WORD:  Write(value^, 2);
         end;
   Result:=pos;
end;

procedure Phys_ReadBuf(buf: array of byte; size: integer);
var
   i, pos: integer;

   procedure Read(var x; size: integer);
   begin
      Move(buf[pos], x, size);
      Inc(pos, size);
   end;

begin
   pos:=0;
   for i:=1 to pvcount do
      with phys_vars[i] do
         case type_ of
            VT_INTEGER: Read(value^, 4);
            VT_FLOAT: Read(value^, sizeof(single));
            VT_WORD:  Read(value^, 2);
         end;
end;

{ TTFKPhysMap }
function TTFKPhysMap.block_b(X, Y: WORD): boolean;
begin
if (X >= Width) or (Y >= Height) then
 Result := true
else
 Result := (Brk.Mask[x, y] and MASK_BLOCK > 0) and
           (Brk.Mask[x, y] and MASK_CONTAINER = 0);
end;

function TTFKPhysMap.block_bObj(X, Y: WORD): boolean;
var
 i, j : integer;
begin
if (X >= Width) or (Y >= Height) then
 Result := true
else
 Result := (Brk.Mask[x, y] and MASK_BLOCK > 0) and
           (Brk.Mask[x, y] and MASK_CONTAINER = 0);
if not Result and (Brk.Mask[x, y] and MASK_OBJ > 0) then
 for j := 1 to ylist[x][0] do
 begin
  i:=ylist[x][j];
  if Obj.g_Obj[i].ObjType in [otNFKDoor, otBelt, otAnimation] then
   begin
   if Obj.g_Obj[i].BlockedAt(x * 32+16, y * 16+8) then
    begin
    Result := true;
    if Obj.g_Obj[i].ObjType=otBelt then
       g_dpos:=@(TBelt(Obj.g_Obj[i]).sspeed);
    Break;
    end;
   end;
  end;
end;


procedure TTFKPhysMap.block_BrkOptimize;
var
 i, j, xx, yy: integer;
// XProger: немножко оптимизируем
 Xmx, Xmn : integer;
 Ymx, Ymn : integer;
begin
  Xmx:=0;Xmn:=Width+1;
  Ymx:=0;Ymn:=Height+1;
  if obj.trainpoints<>nil then
for i := 0 to high(obj.trainpoints) do
   with obj.trainpoints[i] do
begin
   if Xmx<x then Xmx:=x;
   if Xmn>x then Xmn:=x;
   if Ymx<y then Ymx:=y;
   if Ymn>y then Ymn:=y;
end;

for xx := Xmn to Xmx+obj.mintrainwidth+3 do
   for yy := Ymn to Ymx+obj.mintrainheight+3 do
      Brk.Mask[xx, yy] := Brk.Mask[xx, yy] or MASK_OBJ;
//доехали наконец и до этой функции :)
j:=obj.g_Count-1;
for i := 0 to j do
  with Obj.g_Obj[i] do
  case objtype of
   otElevator:
    begin
    Xmn := min(0, struct.elevx) + struct.x - 1;
    Xmx := max(0, struct.elevx) + struct.x + struct.width+1;
    Ymn := min(0, struct.elevy) + struct.y - 1;
    Ymx := max(0, struct.elevy) + struct.y + struct.height+1;
    for xx := Xmn to Xmx do
     for yy := Ymn to Ymx do
      Brk.Mask[xx, yy] := Brk.Mask[xx, yy] or MASK_OBJ;
    end;

   otTriangle, otNFKDoor, otEmptyBricks, otBelt, otAnimation:
     begin
     Xmn := struct.x;
     Xmx := struct.x + struct.width-1;
     Ymn := struct.y;
     Ymx := struct.y + struct.height-1;
     for xx := Xmn to Xmx do
      for yy := Ymn to Ymx do
       Brk.Mask[xx, yy] := Brk.Mask[xx, yy] or MASK_OBJ;
     end;
  end;

  //заполняем ylist
  SetLength(ylist, Width);
  for i:=0 to Width-1 do
     SetLength(ylist[i], Obj.g_Count+1);
end;

function TTFKPhysMap.block_b_(X, Y: WORD): boolean;
begin
if (X >= Width) or (Y >= Height) then
 Result := true
else
 Result := (Brk.Mask[x, y] and MASK_BLOCK > 0) and
           (Brk.Mask[x, y] and MASK_CONTAINER = 0) and
           (Brk[x, y] > 0);
end;

function TTFKPhysMap.block_Dot_Product(X, Y, dx, dy: single; Count: integer): integer;
//returns 0 if all points will be true
//returns 1 if all points will be false
//returns 2 if points will be true-...-false-...
//returns 3 if points will be false-...-true-...
var
 r1, r2 : boolean;
 i      : integer;
begin
r1 := Block_s(X, Y);
// попробуем некоторую оптимизацию... с лифтами конечно может и не пройти :)
//   dx:=dx*count;dy:=dy*count;count:=1;

r2 := false;
for i := 1 to Count do
 begin
 x := x + dx;
 y := y + dy;
 if r1 <> Block_s(X, Y) then
  r2 := true;
 end;
Result := 1 - Byte(r1) + Byte(r2) * 2;
end;

function TTFKPhysMap.block_s(X, Y: single): boolean;
var
 i      : integer;
 fx, fy : SmallInt;
 bx, by : SmallInt;
begin
fx := trunc(x);
fy := trunc(y);
// XProger: тож оптимизируем
bx := fx shr 5;
by := fy shr 4;
Result := (fx < 0) or (fy < 0) or Block_b(bx, by);

if not Result and (Brk.Mask[bx, by] and MASK_OBJ > 0) then
 for i := 1 to ylist[bx][0] do
  if Obj.g_Obj[ ylist[bx][i] ].BlockedAt(fx, fy) then
   begin
      Result := true;
      Break;
   end;

end;

function TTFKPhysMap.block_s_(X, Y: single): boolean;
var
 i      : integer;
 fx, fy : SmallInt;
 bx, by : SmallInt;
begin
fx := trunc(x);
fy := trunc(y);
// XProger: тож оптимизируем
bx := fx shr 5;
by := fy shr 4;
Result := (fx < 0) or (fy < 0) or Block_b_(bx, by);
if not Result and (Brk.Mask[bx, by] and MASK_OBJ > 0) then
 for i := 1 to ylist[bx][0]  do
  if Obj.g_Obj[ ylist[bx][i] ].BlockedAt(fx, fy) then
   begin
      Result := true;
      Break;
   end;
end;


function TTFKPhysMap.block_sObj(X, Y: single; var pobj: TPhysObj;
  IgnoreEmpty: boolean): boolean;
var
 bx, by, fx, fy : integer;
 i              : integer;
begin
// XProger: Здесь был Прогер :P
fx := trunc(x);
fy := trunc(y);
bx := fx shr 5;
by := fy shr 4;
if IgnoreEmpty then
   Result := (bx < 0) or (by < 0) or Block_b_(bx, by)
else
   Result := (bx < 0) or (by < 0) or Block_b(bx, by);
if (Brk.Mask[bx, by] and MASK_OBJ>0) then
 for i := 1 to ylist[bx][0]  do
  with Obj.g_Obj[ ylist[bx][i] ] do
 if BlockedAt(fx, fy) then
  begin
  pObj   := PhysObj(fx, fy);
  Result := true;
  Exit;
  end;

FillChar(pObj, SizeOf(Obj), 0);
with pObj, frect do
 begin
 X1 := bx shl 5;
 Y1 := by shl 4;
 X2 := (bx + 1) shl 5;
 Y2 := (by + 1) shl 4;
 dpos       := @NullPoint;
 normal     := NullPoint;
 floatpos   := NullPoint;
 dis_bottom := false;
 dis_top    := false;
 dis_hor    := false;
 end;
end;

function TTFKPhysMap.block_Water_s(X, Y: single): boolean;
var
   i:integer;
begin
   Result:=false;
   with Obj do
   if liquids<>nil then
      for i:=low(liquids) to high(liquids) do
         if PointInRect(round(x), round(y), liquids[i].ActivateRect) then
         begin
            Result:=true;
            break;
         end;
end;

//Новая физика ТФК. Clip Walls :)
procedure TTFKPhysMap.phys_cliptest(var ph: TPhysRect);
var
 i, j               : integer;
 bx1, by1, bx2, by2 : integer;
 check_obj          : boolean;
begin
// XProger: что за кошмар :D
// и тут прошла рука Прогера

with ph do
 begin
 // XProger: здесь очень долго и муторно пытался хоть что-либо оптимизировать Прогер
 c_left   := false;
 c_right  := false;
 c_top    := false;
 c_bottom := false;
 friction     := air_friction;
 ground_float := NullPoint;
 ground_dpos  := @NullPoint;
 // XProger: а ты ещё удивляешься - почему свыше 32 ботов ведут к тормозам! ;)
 minpos.X := -x1;
 maxpos.X := Width shl 5 - x2;

 bx1 := (trunc(pos.x) + x1  + 64) shr 5 - 2;
 bx2 := (round(pos.x) + x2  + 63) shr 5 - 2;
 by1 := (trunc(pos.y) + Hy1 + 32) shr 4 - 2;
 by2 := (round(pos.y) + Hy2 + 32) shr 4 - 2;

 //левая
 for j := by1 to by2 do
  if Block_bObj(bx1, j) then
   begin                                                              
   c_left   := true;
   minpos.X := (bx1 + 1) shl 5 - x1;
   if dpos.X < 0 then
    dpos.X := 0;
   Break;
   end;

 //правая
 for j := by1 to by2 do
  if Block_bObj(bx2, j) then
   begin
   c_right  := true;
   maxpos.X := bx2 shl 5 - x2;
   if dpos.X > 0 then
    dpos.X := 0;
   Break;
   end;

 check_obj := false;
 for i := bx1 to bx2 do
  for j := by1 to by2 do
	 if Brk.Mask[i, j] and MASK_OBJ > 0 then
    begin
    check_obj := true;
    Break;
    end;

 if check_obj then
  begin
  j := Obj.g_Count - 1;
  for i := 0 to j do
     Obj.g_Obj[i].phys_clipX(ph);
  end;

 if signf(minpos.X - maxpos.X) <= 0 then
  begin
  	if c_left  then pos.x := minpos.X;
  	if c_right then pos.x := maxpos.X;
  end;


 minpos.Y := -Vy1;
 maxpos.Y := Height shl 5 - Vy2;
 //новый пересчёт координат на бриках.
 bx1 := (round(pos.X) +x1) shr 5;
 bx2 := (round(pos.X) +x2 - 1) shr 5;
 by1 := (round(pos.Y) +Vy1) shr 4;
 by2 := (round(pos.Y) +Vy2+32) shr 4 - 2;
 //верхняя
 for i := bx1 to bx2 do
  if Block_bObj(i, by1) then
   begin
   c_top := true;
   minpos.Y := (by1 + 1) shl 4 - Vy1;
   if dpos.Y < 0 then
    dpos.Y := 0;
   Break;
   end;
 //нижняя
 g_dpos:=@NullPoint;
 for i := bx1 to bx2 do
  if Block_bObj(i, by2) then
   begin
   c_bottom := true;
   maxpos.Y := by2 shl 4 - Vy2;
   friction := ground_friction;
   ground_dpos:=g_dpos;
   if dpos.Y > 0 then
    dpos.Y := 0;
   Break;
   end;

 check_obj := false;
 for i := bx1 to bx2 do
  for j := by1 to by2 do
	 if Brk.Mask[i, j] and MASK_OBJ > 0 then
    begin
    check_obj := true;
    Break;
    end;

 if check_obj then
 begin
  j := Obj.g_Count - 1;
  for i := 0 to j do
     Obj.g_Obj[i].phys_clipY(ph);
  end;

 if c_left and c_right and c_top and c_bottom then
  squish := true;
//      if signf(minpos.Y-maxpos.Y)<=0 then
 if signf(minpos.X - maxpos.X) <= 0 then
 begin
 	if pos.Y > maxpos.Y then
  		pos.Y := maxpos.Y
 	else
  		if pos.Y < minpos.Y then
   		pos.Y:=minpos.Y;
 end;
 // XProger: и у него вроде что-то получилось! :D
 end;
end;

procedure TTFKPhysMap.phys_friction(var ph: TPhysRect);
begin
   with ph do
      if abs(dpos.X-ground_dpos.X)>0.1 then
      begin
      	dpos.X:= dpos.X+(dpos.X-ground_dpos.X)*(1/friction-1)/phys_freq;
      end
         else dpos.X:=ground_dpos.X;
end;

procedure TTFKPhysMap.phys_gravity(var pp: TPhysRect);
begin
   with pp do
      dpos.Y:=dpos.Y + default_gravity/phys_freq;
end;

procedure TTFKPhysMap.phys_params(X, Y: single; var pp: TPhysicParams);
begin
   with pp do
   begin
      minspeed:=Point2f(-maxspeed_x, -maxspeed_jumping);
      maxspeed:=Point2f(maxspeed_x, maxspeed_falling);
      air_speed:=Point2f(0.0, 0.0);
      air_maxX:=air_maxspeed;
      gr_maxX:=ground_maxspeed;
      flight:=false;
      if block_Water_s(X, Y) then
      begin
      	minspeed:=Point2f(-2.0, -1.0);
      	maxspeed:=Point2f(2.0, 1.0);
         flight:=true;
      end;
   end;
end;

function TTFKPhysMap.TraceVector(x, y, angle: single): single;//возвращает расстояние
const
   C=4096;
var
   sx, sy, bx, by, bdx, bdy, bdx0, bdy0, dx, dy: integer;
   res: integer; //0 - через точку, 1 - сверху -1 - снизу
   i: integer;
   s, s1: single;
   checkobjs: boolean;

begin
   checkobjs:=false;
   //возвращает расстояние:
   dx:=round(cos(angle)*C);
   dy:=round(sin(angle)*C);
   sx:=round(x);
   sy:=round(y);
   bdx:=sign(dx);
   bdy:=sign(dy);
   bdx0:=1-ord(bdx>=0);
   bdy0:=1-ord(bdy>=0);
   bx:=trunc(x/32);
   by:=trunc(y/16);
 //вертикальный случай
   if Block_b_(bx, by) then
   begin
      Result:=0;
      Exit;
   end;

   CheckObjs:=CheckObjs or (Brk.Mask[bx, by] and MASK_OBJ>0) or
      Obj.is_Monsters;
   if bdx=0 then
   begin
   	while (not block_b_(bx, by)) do
      begin
         by:=by+bdy;
         CheckObjs:=CheckObjs or (Brk.Mask[bx, by] and MASK_OBJ>0);
      end;
      Result:=abs(y-(by+bdy0)*16);
   end else
   if bdy=0 then
   begin
   	while (not block_b_(bx, by)) do
      begin
         bx:=bx+bdx;
         CheckObjs:=CheckObjs or (Brk.Mask[bx, by] and MASK_OBJ>0);
      end;
      Result:=abs(x-(bx+bdx0)*32);
   end else
   begin
      res:=0;
      while (not block_b_(bx, by)) do
      begin
         CheckObjs:=CheckObjs or (Brk.Mask[bx, by] and MASK_OBJ>0);
         res:=VectorAngle((bx+1-bdx0)*32-sx, (by+1-bdy0)*16-sy, dx, dy)*bdx*bdy;
         if res>=0 then by:=by+bdy;
         if res<=0 then bx:=bx+bdx;
      end;
      if res=0 then Result:=sqrt(sqr((bx+bdx0)*32-sx)+sqr((by+bdy0)*16-sy))
      else if res=1 then
         Result:=((by+bdy0)*16-sy)/sin(angle)
      else
         Result:=((bx+bdx0)*32-sx)/cos(angle);
   end;

   if checkobjs then
      for i:=0 to Obj.Count-1 do
         if Obj[i] is TElevatorObj then
         begin
            s:=Result;
            if RectVectorIntersect(Obj[i].ObjRect, x, y, angle, s) and
               TraceVectorElev(x+(s+1)*cos(angle)-Obj[i].ObjRect.X,
               				y+(s+1)*sin(angle)-Obj[i].ObjRect.y, angle,
                           TElevatorObj(Obj[i]), s1) then
            if result>s+s1 then Result:=s+s1;
         end else
         if (Obj[i].ObjType in [otNFKDoor, otBelt, otAnimation]) and
            TGeometryObj(Obj[i]).Blocked
              then
            	RectVectorIntersect(Obj[i].ObjRect, x, y, angle, Result)
            else
         if Obj[i].ObjType=otTriangle then
            TTriangleObj(Obj[i]).VectorIntersect(x, y, angle, Result)
         else
         if (Obj[i].objtype=otMonster) and Obj[i].Active then
            if TMonsterObj(Obj[i]).Blocked then
          	   RectVectorIntersect(Obj[i].ObjRect, x, y, angle, Result)
end;

function TTFKPhysMap.TraceVectorElev(x, y, angle: single; Elev: TElevatorObj; var s : single): boolean;
const
   C=4096;
var
   sx, sy, bx, by, bdx, bdy, bdx0, bdy0, dx, dy: integer;
   res: integer; //0 - через точку, 1 - сверху -1 - снизу

begin
   //возвращает расстояние:
   dx:=round(cos(angle)*C);
   dy:=round(sin(angle)*C);
   sx:=round(x);
   sy:=round(y);
   bdx:=sign(dx);
   bdy:=sign(dy);
   bdx0:=1-ord(bdx>=0);
   bdy0:=1-ord(bdy>=0);
   bx:=trunc(x/32);
   by:=trunc(y/16);
 //вертикальный случай
   if Elev._block_b(bx, by) then
   begin
      s:=0;
      Result:=true;
      Exit;
   end;

   if bdx=0 then
   begin
   	while not Elev._block_b(bx, by) do
         by:=by+bdy;
      Result:=(by>=0) and (by<Elev.height);
      if Result then s:=abs(y-(by+bdy0)*16);
   end else
   if bdy=0 then
   begin
   	while not Elev._block_b(bx, by) do
         bx:=bx+bdx;
      Result:=(bx>=0) and (bx<Elev.width);
      if Result then s:=abs(x-(bx+bdx0)*32);
   end else
   begin
      res:=0;
      while not Elev._block_b(bx, by) do
      begin
         res:=VectorAngle((bx+1-bdx0)*32-sx, (by+1-bdy0)*16-sy, dx, dy)*bdx*bdy;
         if res>=0 then by:=by+bdy;
         if res<=0 then bx:=bx+bdx;
      end;
      Result:=(bx>=0) and (by>=0) and (bx<Elev.Width) and (by<Elev.Height);
      if Result then
      begin
      	if res=0 then s:=sqrt(sqr((bx+bdx0)*32-sx)+sqr((by+bdy0)*16-sy))
      	else if res=1 then
         	s:=((by+bdy0)*16-sy)/sin(angle)
      	else
         	s:=((bx+bdx0)*32-sx)/cos(angle);
      end;
   end;
end;

function TTFKPhysMap.ShootActivation(x, y, angle: single; s: single; sender: TObject=nil; damage: integer=0): boolean;//активация выстрелом...
var
   i: integer;
   s0: single;
begin
   Result:=false;

   if not Map.IsClientGame then
   begin

   for i:=0 to Obj.Count-1 do
   begin
      s0:=s+2.0;
      if (Obj[i].ObjType in ShootObjs) and
         (Obj[i].struct.active=2) then
         if RectVectorIntersect(Obj[i].ObjRect, x, y, angle, s0) then
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
            end
            else
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
end;

function TTFKPhysMap.block_Lava_s(X, Y: single): boolean;
var
   i: integer;
begin
   Result:=false;
   with Obj do
   if liquids<>nil then
      for i:=low(liquids) to high(liquids) do
         if (liquids[i] is TLavaObj) and
            PointInRect(round(x), round(y), liquids[i].ActivateRect) then
         begin
            Result:=true;
            break;
         end;
end;

procedure TTFKPhysMap.Optimize_Update;
var
   i, x, x1, x2: integer;
   ob: TCustomMapObj;
begin
//Update ylist :))
   for i:=0 to Width-1 do
      ylist[i][0]:=0;
   for i:=0 to Obj.g_Count-1 do
   begin
      ob:=Obj.g_Obj[i];
      x1:=trunc((ob.ObjRect.X - 16)/32);
      x2:=trunc((ob.ObjRect.X + ob.ObjRect.Width + 16) /32);
      if x1<0 then x1:=0;
      if x2>=width then x2:=width-1;
      for x:=x1 to x2 do
      begin
         Inc(ylist[x][0]);
         ylist[x][ ylist[x][0] ]:= i;
      end;
   end;
end;

end.
