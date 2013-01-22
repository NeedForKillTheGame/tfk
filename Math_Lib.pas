unit Math_Lib;
(******************************)
(*  TIME FOR KILL math module *)
(* Created by XProger         *)
(* begin: 29.10.2003          *)
{* modified: friday,13.08.2004*}
{*                by Neoff    *}
{* UPGRADED TO TFK GEOMETRY   *)
{* and math library,26.08.2004*}
{*                by Neoff    *}
(* end:   --.--.----          *)
{*                            *)
(* site: www.XProger.narod.ru *)
{* new site: tfk.mirgames.ru  *}
{* NEW site:                  *}
{*   timeforkill.mirgames.ru  *}
(* e-mail: XProger@list.ru    *)
{* e-mail: neoff777@rambler.ru*}
(******************************)

interface

//Neoff: THIS MODULE IS WHAT YOU NEED. ISN'T IT?

uses
 Windows, Type_Lib;

const
 rad2deg = 180/pi;
 deg2rad = pi/180;

type
 TMathRect = record
  x1, y1, x2, y2: single;
 end;

 TRect = record
  X, Y : SmallInt;
  Width, Height: WORD;
 end;

//на основе новой физики можно создавать:
//отталкивающие брики - заглянуть в phys_cliptest там где меняется скорость.
   TPhysRect =
   record
   //в будущем можно будет задавать коэфициент упругости

      x1, x2: integer;//смещение от нуля нашего ректа
      Vy1, Vy2, Hy1, Hy2: integer;
      pos, dpos: TPoint2f;    //координаты и скорость объекта
      ground_dpos: PPoint2f;
      ground_float, temp_dpos: TPoint2f;
      friction: single;
      //temp'овые переменные
   	c_left, c_right, c_top, c_bottom: boolean;
      //минимальные Xы и Yи ;)
      minpos, maxpos: TPoint2f;

      squish: boolean; 			//объект зажат
   end;

//процедурки для ректов
function Rect(X, Y: SmallInt; Width, Height: WORD): TRect;
function inRect(Rect : TRect; X, Y : integer) : boolean; //аналог процедуры PointInRect
function RectX2(r: TRect): smallint;
function RectY2(r: TRect): smallint;

function MathRect(x1, y1, x2, y2: smallint): TMathRect;

function Sign(x: integer): integer;
function Signf(x: single): integer;
function VectorAngle(x1, y1, x2, y2: integer): integer;
function VectorAnglef(x1, y1, x2, y2: single): integer;
function VectorLen(v: TPoint2f): single;

function Min(a, b: integer): integer;
function Max(a, b: integer): integer;

//УГЛЫ ЗДЕСЬ В РАДИАНАХ!!!!
function PointInRect(x, y: integer; rect: TRect): boolean;
function PointToRect(x, y: integer; rect: TRect): single;//возвращает расстояние до ректа
//x, y, angle -вектор. s - макс. расстояние.
function RectVectorIntersect(rect: TRect; x, y, angle: single; var s: single): boolean;
function LineVectorIntersect(x1, y1, x2, y2: integer; x, y, angle: single; var s: single): boolean;

function RectInside(rect1, rect2: TMathRect): boolean;
function RectIntersect(rect1, rect2: TMathRect): boolean;
function RectToMath(rect: TRect): TMathRect;
//функции для работы с углом

function ang_norm(ang: single): single;
function ang_norm2(ang: single): single;
function ang_norm3(ang: single): single;

//раунд для дробей
function round2(x: single; d: integer): single;
function round_point(p: TPoint2f; d: integer): TPoint2f;

//XProger functions...

function Point(X, Y: SmallInt): TPoint;
function Point2f(X, Y: single): TPoint2f;
function Point3f(X, Y, Z: single): TPoint3f;

function Normalize(V: TPoint3f): TPoint3f;
function Normalize2f(V: TPoint2f): TPoint2f;

function CalcNormal(V1, V2, V3: TPoint3f): TPoint3f;
procedure incVector3f(var A: TPoint3f; const B: TPoint3f);
procedure incVector2f(var A: TPoint2f; const B: TPoint2f);
function DivVector2f(V: TPoint2f; l: single): TPoint2f;

implementation

function ang_norm(ang: single): single;
begin
   while ang<0 do ang:=360+ang;
   while ang>=360 do ang:=ang-360;
   Result:=ang;
end;

function ang_norm2(ang: single): single;
begin
   while ang<0 do ang:=360+ang;
   while ang>=360 do ang:=ang-360;
   if ang>180 then ang:=360-ang;
   Result:=ang;
end;

function ang_norm3(ang: single): single;
begin
   while ang<-180 do ang:=360+ang;
   while ang>=180 do ang:=ang-360;
   Result:=ang;
end;

function round2(x: single; d: integer): single;
begin
Result := round(x*d)/d;
end;

function round_point(p: TPoint2f; d: integer): TPoint2f;
begin
Result.X := round(p.X*d)/d;
Result.Y := round(p.Y*d)/d;
end;

function Min(a, b: integer): integer;
begin
   if a>b then Min:=b else Min:=a;
end;
function Max(a, b: integer): integer;
begin
   if a>b then Max:=a else Max:=b;
end;
//Rect procs
function Rect(X, Y: SmallInt; Width, Height: WORD): TRect;
begin
Result.X:=X;
Result.Y:=Y;
Result.Width:=Width;
Result.Height:=Height;
end;

function inRect(Rect : TRect; X, Y : integer) : boolean;
begin
Result := (Rect.X >= X) and (Rect.Y >= Y) and
          (Rect.X + Rect.Width >= X) and (Rect.Y + Rect.Height >= Y);
end;

function RectX2(r: TRect): smallint;
begin
   Result:=r.X+r.Width;
end;

function RectY2(r: TRect): smallint;
begin
   Result:=r.Y+r.Height;
end;

function Sign(x: integer): integer;
begin
   if x>0 then Result:=1
      else if x<0 then Result:=-1
      else Result:=0;
end;

function Signf(x: single): integer;
const
   eps = 1.0E-5;
begin
   if abs(x)<eps then Result:=0
   else if x<0 then Result:=-1
   else Result:=1;
end;

function VectorAngle(x1, y1, x2, y2: integer): integer;
//0 - совпадают 1 - первый вектор снизу -1 - сверху
begin
   Result:=sign(x1*y2-x2*y1);
end;

function VectorAnglef(x1, y1, x2, y2: single): integer;
//0 - совпадают 1 - первый вектор снизу -1 - сверху
begin
   Result:=signf(x1*y2-x2*y1);
end;

function VectorLen(v: TPoint2f): single;
begin
   Result:=sqrt(sqr(v.x)+sqr(v.y));
end;

function MathRect(x1, y1, x2, y2: smallint): TMathRect;
begin
   Result.x1:=x1;
   Result.y1:=y1;
   Result.x2:=x2;
   Result.y2:=y2;
end;

function PointInRect(x, y: integer; rect: TRect): boolean;
begin
   x:=x-rect.x;
   y:=y-rect.y;
   Result:=(x>=0) and (x<=rect.Width) and
           (y>=0) and (y<=rect.Height);
end;

function PointToRect(x, y: integer; rect: TRect): single;//возвращает расстояние до ректа
begin
   x:=x-rect.x;
   y:=y-rect.y;
   if x<0 then
   begin
      if y<0 then
         Result:=sqrt(sqr(x)+sqr(y))
      else
         if y>rect.height then
         	Result:=sqrt(sqr(x)+sqr(y-rect.height))
         else Result:=-x;
   end else
   if x>rect.width then
   begin
      x:=x-rect.width;
      if y<0 then
         Result:=sqrt(sqr(x)+sqr(y))
      else
         if y>rect.height then
         	Result:=sqrt(sqr(x)+sqr(y-rect.height))
         else Result:=x;
   end else
   begin
      if y<0 then
         Result:=-y
      else
         if y>rect.height then
         	Result:=y-rect.height
         else Result:=0;
   end;
end;

//пересечение ректа с отрезком (x, y, angle, s)! функция возвращает расстояние до ректа
function RectVectorIntersect(rect: TRect; x, y, angle: single; var s: single): boolean;
var
	b1, b2, b3, b4: integer;
   dx, dy, s0, s1: single;

   //проверка принадлежности ОДНОЙ четверти экрана
   function Func1(x1, y1, x2, y2: single): boolean;
   begin
      Result:=(x1*x2>=0) and (y1*y2>=0);
   end;

begin
   if PointInRect(round(x), round(y), rect) then
   begin
      Result:=true;
      s:=0;
      Exit;
   end;

   dx:=cos(angle);dy:=sin(angle);
   rect.X:=round(rect.X-x);
   rect.Y:=round(rect.Y-y);
   b1:=VectorAnglef(dx, dy, rect.x, rect.y);
   b2:=VectorAnglef(dx, dy, rect.x+rect.width, rect.y);
   b3:=VectorAnglef(dx, dy, rect.x+rect.width, rect.y+rect.height);
   b4:=VectorAnglef(dx, dy, rect.x, rect.y+rect.height);
   //проверка на обычное пересечение прямой ректа
   Result:=(b1<>b2) or (b1<>b3) or (b1<>b4) or
           (b2<>b3) or (b2<>b4) or (b3<>b4);
   //проверка на то что именно эта сторона луча пересекает игрока
   Result:=Result and (
   		Func1(dx, dy, rect.x, rect.y) or
   		Func1(dx, dy, rect.x+rect.width, rect.y) or
   		Func1(dx, dy, rect.x+rect.width, rect.y+rect.height) or
   		Func1(dx, dy, rect.x, rect.y+rect.height) );
   //теперь вычисляем расстояние
   if Result then
   begin
   	s0:=s;
      //верхняя сторона ректа
      if (b1<>b2) and ( signf(rect.y*dy)>0 ) then
      begin
         s1:=abs(rect.y/dy);
         if s1<s0 then  s0:=s1;
      end;
      //правая сторона
      if (b2<>b3) and ( signf((rect.x+rect.width)*dx)>0 ) then
      begin
         s1:=abs((rect.x+rect.width)/dx);
         if s1<s0 then  s0:=s1;
      end;
      //нижняя сторона
      if (b3<>b4) and ( signf((rect.y+rect.height)*dy)>0 ) then
      begin
         s1:=abs((rect.y+rect.height)/dy);
         if s1<s0 then  s0:=s1;
      end;
      //левая сторона
      if (b4<>b1) and ( signf(rect.x*dx)>0 ) then
      begin
         s1:=abs(rect.x/dx);
         if s1<s0 then  s0:=s1;
      end;
   	if signf(s-s0)>0 then
         s:=s0
      else Result:=false;
   end;
end;

//пересечение линии вектором ;)
function LineVectorIntersect(x1, y1, x2, y2: integer; x, y, angle: single; var s: single): boolean;
var
   dx, dy, s0: single;
begin
   Result:=false;
   dx:=cos(angle);dy:=sin(angle);
   //в этом сравнении отбрасываются так же все вырожденные случаи.
   if VectorAnglef( x1-x, y1-y, dx, dy)<>
   	VectorAnglef( x2-x, y2-y, dx, dy) then
      begin
   //Neoff:
   //пересечение двух прямых
      {x+s0*dx=x1+(x2-x1)*t}
      {y+s0*dy=y1+(y2-y1)*t}

   // s0*dx+t*(x1-x2)=x1-x;
   // s0*dy+t*(y1-y2)=y1-y;
   // D=dx*(y1-y2)-dy*(x1-x2)
   // B1=(x1-x)*(y1-y2)-(y1-y)*(x1-x2)
   // S0= B1/D
   // и оно работает!!!!!
      	s0:=((x1-x)*(y1-y2)-(y1-y)*(x1-x2))/(dx*(y1-y2)-dy*(x1-x2));
      	if (signf(s0)>=0) and (signf(s-s0)>0) then
      	begin
      		s:=s0;
         	Result:=true;
      	end;
      end;
end;

function RectInside(rect1, rect2: TMathRect): boolean;
begin
//проверка находится ли rect1 полностью в rect2 или наоборот
Result := (rect1.X1 >= rect2.X1) and (rect1.X2 <= rect2.X2)  and
          (rect1.Y1 >= rect2.Y1) and (rect1.y2 <= rect2.Y2) or
          (rect2.X1 >= rect1.X1) and (rect2.X2 <= rect1.X2)  and
          (rect2.Y1 >= rect1.Y1) and (rect2.y2 <= rect1.Y2);
end;

function RectIntersect(rect1, rect2: TMathRect): boolean;
//проверка ПЕРЕСЕЧЕНИЯ ректов
 function Intersect0(x1, x2, y1, y2: single): boolean;
 begin
 //проверка пересечения отрезков
 Result := (x1 >= y1) and (x1 <= y2) or
           (x2 >= y1) and (x2 <= y2) or
           (x1 <= y1) and (y2 <= x2) or
           (x1 >= y1) and (y2 >= x2);
 end;

begin
Result := InterSect0(rect1.X1, rect1.X2, rect2.X1, rect2.X2) and
          InterSect0(rect1.Y1, rect1.Y2, rect2.Y1, rect2.Y2);
end;


function RectToMath(rect: TRect): TMathRect;
begin
   Result.x1:=rect.X;
   Result.y1:=rect.Y;
   Result.x2:=rect.X+rect.Width;
   Result.y2:=rect.Y+rect.Height;
end;

//XProger functions

function Point(X, Y: SmallInt): TPoint;
begin
Result.X:=X;
Result.Y:=Y;
end;

function Point2f(X, Y: single): TPoint2f;
begin
Result.X:=X;
Result.Y:=Y;
end;

function Point3f(X, Y, Z: single): TPoint3f;
begin
Result.X:=X;
Result.Y:=Y;
Result.Z:=Z;
end;

function Normalize(V: TPoint3f): TPoint3f;
var
 Len: single;
begin
Len:=sqrt( V.X*V.X + V.Y*V.Y + V.Z*V.Z );
Result.X:=V.X/Len;
Result.Y:=V.Y/Len;
Result.Z:=V.Z/Len;
end;

function Normalize2f(V: TPoint2f): TPoint2f;
var
 Len: single;
begin
Len := sqrt(V.X * V.X + V.Y * V.Y);
if Len <> 0 then
 begin
 Result.X := V.X / Len;
 Result.Y := V.Y / Len;
 end
else
 begin
 Result.X := 0;
 Result.Y := 0;
 end;
end;

function SubVertex(Vertex1, Vertex2: TPoint3f): TPoint3f;
begin
Result.X := Vertex1.X - Vertex2.X;
Result.Y := Vertex1.Y - Vertex2.Y;
Result.Z := Vertex1.Z - Vertex2.Z;
end;

function CrossVertex(Vertex1, Vertex2: TPoint3f): TPoint3f;
begin
Result.X := (Vertex1.Y * Vertex2.Z) - (Vertex1.Z * Vertex2.Y);
Result.Y := (Vertex1.Z * Vertex2.X) - (Vertex1.X * Vertex2.Z);
Result.Z := (Vertex1.X * Vertex2.Y) - (Vertex1.Y * Vertex2.X);
end;

function CalcNormal(V1, V2, V3: TPoint3f): TPoint3f;
var
 Ver1, Ver2: TPoint3f;
begin
Ver1 := SubVertex(V1, V2);
Ver2 := SubVertex(V2, V3);
Result := Normalize(CrossVertex(Ver1, Ver2));
end;

procedure incVector3f(var A: TPoint3f; const B: TPoint3f);
begin
A.X:=A.X+B.X;
A.Y:=A.Y+B.Y;
A.Z:=A.Z+B.Z;
end;

procedure incVector2f(var A: TPoint2f; const B: TPoint2f);
begin
A.X:=A.X+B.X;
A.Y:=A.Y+B.Y;
end;

function DivVector2f(V: TPoint2f; l: single): TPoint2f;
begin
if l=0 then
 begin
 Result.X := 0;
 Result.Y := 0;
 Exit;
 end;
Result.X := V.X / l;
Result.Y := V.Y / l;
end;

end.

