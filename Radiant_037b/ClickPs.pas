unit ClickPs;

(***************************************)
(*  TFK Radiant mainform version 1.0.1 *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

{пояснения: в этом модуле основной код выделения, перемещения и ресайза объектов...
только вместо объектов используются ТОЧКИ созданные объектами при create и забытые
ими на всю оставшуюся жизнь до удаления обеъекта :) один объект имеет одну точку за которую
можно потянуть его вместе с другими объектами
и несколько точек которые не выдерживают использования с другими объектами. }

interface

uses Classes, LightMap_Lib, Graphics;

    {Эксперимент закончился провалом: вместе сделать psSelective и psAlways сложновато,
    	а вот если подавать вместо lastx и lasty их изменения... а это идея!!!!!!}
    {ptPixel - точка - пиксель. иначе она меняется по брикам}
    {ВСЕ РАБОТАЕТ, МОДУЛЬ ПРОСТО СУПЕР!!!!!}
type
   TPointType = ( ptSelective, ptDefault, ptNoCopy,
   					ptAction1, ptAction2, ptAction3, ptAlways, ptPixel,
                  ptInvisible, ptLink,
   					ptMove, ptLeft, ptTop, ptRight, ptBottom, //различие по действию
                  ptLeftAlign, ptTopAlign, ptRightAlign, ptBottomAlign
                  );
   TPointTypeSet = set of TPointType;

   TLightPointType = (plCenter, plLeft, plTop, plRight, plBottom);

   TLightPointTypeSet = set of TLightPointType;
const
   xtypes :TPointTypeSet= [ptMove, ptLeft, ptRight];
   ytypes :TPointTypeSet= [ptMove, ptTop, ptBottom];
   ActionTypes :TPointTypeSet= [ptAction1, ptAction2, ptAction3];

   LeftPoint: TPointTypeSet= [ptLeft, ptLeftAlign, ptTopAlign, ptBottomAlign];
   RightPoint: TPointTypeSet= [ptRight, ptRightAlign, ptTopAlign, ptBottomAlign];
   TopPoint: TPointTypeSet= [ptTop, ptLeftAlign, ptRightAlign, ptTopAlign];
   BottomPoint: TPointTypeSet= [ptBottom, ptLeftAlign, ptRightAlign, ptBottomAlign];

   LeftTopPoint: TPointTypeSet= [ptLeft, ptTop, ptLeftAlign, ptTopAlign];
   RightTopPoint: TPointTypeSet= [ptRight, ptTop, ptRightAlign, ptTopAlign];
   LeftBottomPoint: TPointTypeSet= [ptLeft, ptBottom, ptLeftAlign, ptBottomAlign];
   RightBottomPoint: TPointTypeSet= [ptRight, ptBottom, ptRightAlign, ptBottomAlign];

   CenterPoint: TPointTypeSet= [ptSelective, ptDefault, ptMove, ptLeftAlign, ptTopAlign, ptRightAlign, ptBottomAlign];

   ActionPoint1: TPointTypeSet= [ptAction1, ptLeftAlign, ptTopAlign, ptRightAlign, ptBottomAlign];
   ActionPoint2: TPointTypeSet= [ptAction2, ptLeftAlign, ptTopAlign, ptRightAlign, ptBottomAlign];
   ActionPoint3: TPointTypeSet= [ptAction3, ptLeftAlign, ptTopAlign, ptRightAlign, ptBottomAlign];
   LinkPoint: TPointTypeSet= [ptLink, ptSelective, ptDefault, ptMove, ptLeftAlign, ptTopAlign, ptRightAlign, ptBottomAlign];

type
   TClickPoint = class;

   TCustomCPObj =
   class
      mainpoint: TClickPoint;

   protected
      function GetX: word;virtual;abstract;
      function GetY: word;virtual;abstract;
      function GetWidth: word;virtual;abstract;
      function GetHeight: word;virtual;abstract;
   public
      function SetX(Value: integer): integer;virtual;abstract;
      function SetY(Value: integer): integer;virtual;abstract;
      function SetLeftX(Value: integer): integer;virtual;abstract;
      function SetTopY(Value: integer): integer;virtual;abstract;
		function SetWidth(Value: integer): integer;virtual;abstract;
      function SetHeight(Value: integer): integer;virtual;abstract;
   //
      property x: word read GetX;
      property y: word read GetY;
      property width: word read GetWidth;
      property height: word read GetHeight;
   //
      procedure Action1(sender:TClickPoint; x, y: integer);virtual;
      procedure Action2(sender:TClickPoint; x, y: integer);virtual;
      procedure Action3(sender:TClickPoint; x, y: integer);virtual;
      procedure ActionLink(LinkObj: TCustomCPObj);virtual;
	end;

   TClickPoint =
   class
      constructor Create(Obj_: TCustomCPObj; ptype:TPointTypeSet; x1, y1: integer;
      	color: TColor=clAqua);
  private
    procedure SetX(const Value: integer);
    procedure SetY(const Value: integer);
    function Getx: integer;
    function Gety: integer;
    function GetChanged: boolean;
   protected
      fx, fy: integer;
      ftype: TPointTypeSet;
      fchanged: boolean;
      fObj: TCustomCPObj;

      flastx, flasty, dflastx, dflasty: integer;
      	//последнее выделение и изменение координат за это время.
      fColor: TColor;
   public
      property X: integer read Getx write SetX;//В ПИКСЕЛЯХ
      property Y: integer read Gety write SetY;//В ПИКСЕЛЯХ
      property Changed: boolean read GetChanged write fchanged;
      property Obj: TCustomCPObj read fObj;
      property pType: TPointTypeSet read ftype;
      procedure ChangeFXY(x1, y1: integer);
      //расширение библиотеки
      property Color:TColor read fcolor;
      procedure Select(x1, y1: integer);
      procedure UnSelect;
   end;

type
//а теперь кликпойнты для света ;))
   TLightClickPoint = class
   	constructor Create(Obj_: TLightObj; ptype:TLightPointTypeSet);
  private
    procedure SetX(const Value: integer);
    procedure SetY(const Value: integer);
    function Getx: integer;
    function Gety: integer;
    function GetColor: TColor;

    function Diagonal: boolean;
   protected
      fx, fy: integer;
      ftype: TLightPointTypeSet;
      lastx, lasty, dlastx, dlasty: integer;
      	//последнее выделение и изменение координат за это время.
   public
      Obj: TLightObj;
      property X: integer read Getx write SetX;//В ПИКСЕЛЯХ
      property Y: integer read Gety write SetY;//В ПИКСЕЛЯХ
      property pType: TLightPointTypeSet read ftype;
      procedure ChangeFXY(x1, y1: integer);
      //расширение библиотеки
      property Color:TColor read GetColor;
      procedure Select(x1, y1: integer);
      procedure UnSelect;
   end;


type
   TClickPoints = array of TClickPoint;
   TObjects = array of TCustomCPObj;

//А теперь список кликпойнтов и процедуры работы с ними :)

function AddPoint(Obj: TCustomCPObj; ptype:TPointTypeSet; x1, y1: integer; color: TColor=clAqua): TClickPoint;
procedure DeletePoints(Obj: TCustomCPObj);
function GetPoint(ind: integer): TClickPoint;
function GetPointByXY(x, y: integer; nextpoint: boolean; onlyselective: boolean=false; links: boolean=false): TClickPoint;
function GetPointsCount: integer;
procedure ClearPoints;

function GetPointsInRect(x1, y1, x2, y2: integer; links: boolean=false): TClickPoints;//ONLY SELECTIVE!!!!
function IsPointInXY(x, y: integer; cp: TClickPoints): TClickPoint;

procedure SelectPoints(x, y: integer; cp: TClickPoints);
function MovePoints(x, y: integer; cp: TClickPoints): boolean;
procedure UnSelectPoints(cp: TClickPoints);

function IsSelectedPoint(p: TClickPoint; cp: TClickpoints): boolean;
function SelectedObjs(cp: TClickPoints): TObjects;
function IsSelectedObj(obj: TCustomCPObj; cp: TClickPoints): boolean;
procedure TogglePoint(p: TClickPoint;var cp: TClickpoints);


function AddLPoint(Light: TLightObj; ptype:TLightPointTypeSet): TLightClickPoint;
procedure DeleteLPoints(Obj: TLightObj);
function GetLPoint(ind: integer): TLightClickPoint;
function GetLPointByXY(x, y: integer): TLightClickPoint;
function GetLPointsCount: integer;
procedure ClearLPoints;

implementation

uses Math;

var
   ClickPoints: TList;
   LClickPoints: TList;

function AddPoint(Obj: TCustomCPObj; ptype:TPointTypeSet; x1, y1: integer; Color: TColor=clAqua): TClickPoint;
begin
 	Result:=TClickPoint.Create(Obj, ptype, x1, y1, color);
   ClickPoints.Add(Result);
   if ptDefault in ptype then
   	Obj.mainpoint:=Result;
end;

procedure DeletePoints(Obj: TCustomCPObj);
var
   i: integer;
begin
   for i:=ClickPoints.Count-1 downto 0 do
      if TClickPoint(ClickPoints[i]).Obj=Obj then
      begin
         TClickPoint(ClickPoints[i]).Free;
         ClickPoints.Delete(i);
      end;
end;

function GetPoint(ind: integer): TClickPoint;
begin
   Result:=TClickPoint(ClickPoints[ind]);
end;


function GetPointsCount: integer;
begin
   Result:=ClickPoints.Count;
end;

procedure ClearPoints;
var
   i: integer;
begin
   for i:=0 to ClickPoints.Count-1 do
      TClickPoint(ClickPoints[i]).Free;
   ClickPoints.Clear;
end;

function GetPointByXY(x, y: integer; nextpoint: boolean; onlyselective: boolean=false; links: boolean=false): TClickPoint;
const
   pw = 3;
   ph = 3;

var
   i, first, second: integer;
   cp: TClickPoint;
begin
   first:=-1;second:=-1;
   for i:=0 to ClickPoints.Count-1 do
   begin
      cp:=GetPoint(i);
      if (not onlyselective or (ptSelective in cp.pType)) and
      	(abs(x-cp.X)<=pw) and
         (abs(y-cp.y)<=ph) and
         (links=(ptLink in cp.pType)) then
         if first=-1 then
         begin
         	first:=i;
            if not nextpoint then Break;
         end
         else
         begin
         	second:=i;
            Break;
         end;
   end;
   //если ничего не нашли так, то ищем в следующем цикле, default-точки.
   if (first=-1) or nextpoint and (second=-1) then
   	for i:=0 to ClickPoints.Count-1 do
   	begin
      	cp:=GetPoint(i);
      	if (ptDefault in cp.pType) and
            (x>=cp.Obj.x*32) and (x<=(cp.Obj.x+cp.Obj.width)*32) and
            (y>=cp.Obj.y*16) and (y<=(cp.Obj.y+cp.Obj.height)*16) and
         	(links=(ptLink in cp.pType))
           then
         if first=-1 then
         begin
         	first:=i;
            if not nextpoint then Break;
         end
         else
         begin
         	second:=i;
            Break;
         end;
   	end;

   Result:=nil;
   if first>-1 then
      if second=-1 then Result:=GetPoint(first)
      else
      begin
         Result:=GetPoint(second);
         ClickPoints.Move(second, first);
      end;
end;

function GetPointsInRect(x1, y1, x2, y2: integer; links: boolean): TClickPoints;//ONLY SELECTIVE!!!!
var
   i, j: integer;
   cp: TClickPoint;
begin
   j:=0;
   Result:=nil;
   //сначала считаем кол-во пойнтов
   for i:=0 to ClickPoints.Count-1 do
   begin
      cp:=GetPoint(i);
      if (ptSelective in cp.pType) and
         (cp.x>=x1-3) and (cp.x<=x2+3) and
         (cp.y>=y1-3) and (cp.y<=y2+3) and
         (links=(ptLink in cp.pType)) then
         	inc(j);
   end;
   //а уже потом заполняем массив
   if j=0 then Exit;
   SetLength(Result, j);
   j:=0;
   for i:=0 to ClickPoints.Count-1 do
   begin
      cp:=GetPoint(i);
      if (ptSelective in cp.pType) and
         (cp.x>=x1-3) and (cp.x<=x2+3) and
         (cp.y>=y1-3) and (cp.y<=y2+3) and
         (links=(ptLink in cp.pType)) then
         begin
            Result[j]:=cp;
         	inc(j);
         end;
   end;
   SetLength(Result, j);
end;

function IsPointInXY(x, y: integer; cp: TClickPoints): TClickPoint;
var
   i: integer;
begin
   Result:=nil;
   if cp<>nil then
   for i:=Low(cp) to High(cp) do
      if (abs(cp[i].x-x)<=3) and
         (abs(cp[i].y-y)<=3) then
         begin
            Result:=cp[i];
            Break;
         end;
end;

procedure SelectPoints(x, y: integer; cp: TClickPoints);
var
   i: integer;
begin
   if cp<>nil then
   for i:=low(cp) to high(cp) do
      cp[i].Select(x, y);
end;

function MovePoints(x, y: integer; cp: TClickPoints): boolean;
var
   i: integer;
begin
   Result:=false;
   if cp<>nil then
   for i:=low(cp) to high(cp) do
   begin
      cp[i].x:=x;
      cp[i].y:=y;
      Result:=Result or cp[i].changed;
   end;
end;

procedure UnSelectPoints(cp: TClickPoints);
var
   i: integer;
begin
   if cp<>nil then
   for i:=low(cp) to high(cp) do
    	cp[i].UnSelect;
end;

function IsSelectedPoint(p: TClickPoint; cp: TClickpoints): boolean;
var
   i: integer;
begin
   Result:=false;
   if (p<>nil) and (cp<>nil) then
   for i:=Low(cp) to High(cp) do
      if cp[i]=p then
      begin
         Result:=true;
         Break;
      end;
end;

function SelectedObjs(cp: TClickPoints): TObjects;
var
   i: integer;
begin
//пусть у нас не может быть одинаковых объектов у двух точек :)))
   Result:=nil;
   if cp<>nil then
   begin
      SetLength(Result, High(cp)+1);
   	for i:=Low(Result) to High(Result) do
         Result[i]:=cp[i].Obj;
   end;
end;

function IsSelectedObj(obj: TCustomCPObj; cp: TClickPoints): boolean;
var
   i: integer;
begin
   Result:=false;
   if cp<>nil then
   for i:=Low(cp) to High(cp) do
      if cp[i].Obj=obj then
      begin
         Result:=true;
         Break;
      end;
end;

procedure TogglePoint(p: TClickPoint;var cp: TClickpoints);
var
   i, j: integer;
begin
   if p<>nil then
   begin
   	for i:=Low(cp) to High(cp) do
      	if cp[i]=p then
      	begin
         	for j:=i to High(cp)-1 do
            	cp[j]:=cp[j+1];
         	Exit;
      	end;
   	if cp<>nil then
   		SetLength(cp, High(cp)+2)
      	else SetLength(cp, 1);
   	cp[High(cp)]:=p;
   end;
end;

function AddLPoint(Light: TLightObj; ptype:TLightPointTypeSet): TLightClickPoint;
begin
 	Result:=TLightClickPoint.Create(Light, ptype);
   LClickPoints.Add(Result);
   Light.centerpoint:=Result;
end;

procedure DeleteLPoints(Obj: TLightObj);
var
   i: integer;
begin
   for i:=LClickPoints.Count-1 downto 0 do
      if TLightClickPoint(LClickPoints[i]).Obj=Obj then
      begin
         TLightClickPoint(LClickPoints[i]).Free;
         LClickPoints.Delete(i);
      end;
end;

function GetLPoint(ind: integer): TLightClickPoint;
begin
   Result:=TLightClickPoint(LClickPoints[ind]);
end;

function GetLPointByXY(x, y: integer): TLightClickPoint;
const
   pw = 3;
   ph = 3;
var
   i: integer;
   cp: TLightClickPoint;
begin
   result:=nil;
   for i:=0 to LClickPoints.Count-1 do
   begin
      cp:=GetLPoint(i);
      if (abs(x-cp.X)<=pw) and
         (abs(y-cp.y)<=ph) then
         begin
            Result:=cp;
            Exit;
         end;
   end;
   for i:=0 to LClickPoints.Count-1 do
   begin
      cp:=GetLPoint(i);
      if (plCenter in cp.pType) and
      	(sqr(x-cp.X)+sqr(y-cp.Y)<=sqr(cp.obj.Radius)) then
         begin
            Result:=cp;
            Exit;
         end;
   end;
end;

function GetLPointsCount: integer;
begin
   Result:=LClickPoints.Count;
end;

procedure ClearLPoints;
var
   i: integer;
begin
   for i:=0 to LClickPoints.Count-1 do
      TLightClickPoint(LClickPoints[i]).Free;
   LClickPoints.Clear;
end;

{ TClickPoint }

procedure TClickPoint.ChangeFXY(x1, y1: integer);
begin
   fchanged:=fchanged or (fx<>x1) or (fy<>y1);
   fx:=x1;fy:=y1;
end;

constructor TClickPoint.Create(Obj_: TCustomCPObj; ptype: TPointTypeSet;
  x1, y1: integer; color: TColor=clAqua);
begin
   fObj:=Obj_;
   ftype:=ptype;
   fx:=x1;fy:=y1;
   fchanged:=false;
   fcolor:=color;
end;

function TClickPoint.GetChanged: boolean;
begin
  Result := fchanged;
  fchanged:=false;
end;

function TClickPoint.Getx: integer;
begin
   Result:=fx;
   if ptLeftAlign in ftype then
      if ptRightAlign in ftype then Result:=fObj.x*32+fObj.width*16+fx
      else Result:=fx+fObj.x*32
   else if ptRightAlign in ftype then Result:=(fObj.x+fObj.width)*32+fx;
end;

function TClickPoint.Gety: integer;
begin
   Result:=fy;
   if ptTopAlign in ftype then
      if ptBottomAlign in ftype then Result:=fObj.y*16+fObj.height*8+fy
      else Result:=fy+fObj.y*16
   else if ptBottomAlign in ftype then Result:=(fObj.y+fObj.height)*16+fy;
end;

procedure TClickPoint.Select(x1, y1: integer);
begin
   flastx:=x1;
   flasty:=y1;
end;

procedure TClickPoint.SetX(const Value: integer);
var
   delta, delta1: integer;
begin
 	delta:=Value-flastx;
   if ptPixel in pType then
   begin
      flastx:=value;
      dflastx:=delta;
      if delta<>0 then
         if ptAlways in fType then Unselect;
   end else
   begin
  		delta1:=sign(delta)*((abs(delta)+16) div 32);
   //координаты объекта всегда меняются дискретно, по брикам
      if (ptMove in ftype) then delta1:=fObj.SetX(fObj.x+delta1);
      if (ptLeft in ftype) then delta1:=fObj.SetLeftX(fObj.x+delta1);
      if (ptRight in ftype) then fObj.SetWidth(fObj.width+delta1);
     	if delta1<>0 then
      begin
         fchanged:=true;
        	flastx:=flastx+delta1*32;
      	dflastx:=delta1;
         if ptAlways in fType then
            Unselect;
      end;
   end;
end;

procedure TClickPoint.SetY(const Value: integer);
var
   delta, delta1 : integer;
begin
 	delta:=Value-flasty;
   if ptPixel in pType then
   begin
      flasty:=Value;
      dflasty:=delta;
      if delta<>0 then
         if ptAlways in fType then Unselect;
   end else
   begin
  		delta1:=sign(delta)*((abs(delta)+8) div 16);
   //координаты объекта всегда меняются дискретно, по брикам
      if (ptMove in ftype) then delta1:=fObj.SetY(fObj.y+delta1);
      if (ptTop in ftype) then delta1:=fObj.SetTopY(fObj.y+delta1);
      if (ptBottom in ftype) then fObj.SetHeight(fObj.height+delta1);
     	if delta1<>0 then
      begin
         fchanged:=true;
        	flasty:=flasty+delta1*16;
      	dflasty:=delta1;
         if ptAlways in fType then
            Unselect;
      end;
   end;
end;

procedure TClickPoint.UnSelect;
begin
   fchanged:=true;
   //если связан с каким-нибудь action'ом то вызвать его
   if ptAction1 in pType then
      fObj.Action1(self, dflastx, dflasty);
   if ptAction2 in pType then
      fObj.Action2(self, dflastx, dflasty);
   if ptAction3 in pType then
      fObj.Action3(self, dflastx, dflasty);
   dflastx:=0;
   dflasty:=0;
end;

{ TLightClickPoint }

procedure TLightClickPoint.ChangeFXY(x1, y1: integer);
var
   dx, dy: integer;
   c: double;
begin
   dx:=x1-lastx;dy:=y1-lasty;
   if Diagonal then C:=Sqrt(2)/2
   else C:=1;
   if plCenter in ftype then
   begin
      dx:=Obj.SetX(Obj.X+dx);
      dy:=Obj.SetY(Obj.Y+dy);
   end else
   if plLeft in ftype then
   begin
      dx:=-Obj.SetRadius(Obj.Radius-round(dx*c));
      dy:=0;
   end else
   if plRight in ftype then
   begin
      dx:=Obj.SetRadius(Obj.Radius+round(dx*c));
      dy:=0;
   end else
   if plTop in ftype then
   begin
      dy:=-Obj.SetRadius(Obj.Radius-round(dy*c));
      dx:=0;
   end else
   if plBottom in ftype then
   begin
      dy:=Obj.SetRadius(Obj.Radius+round(dy*c));
      dx:=0;
   end;
   lastx:=lastx+dx;
   lasty:=lasty+dy;
end;

constructor TLightClickPoint.Create(Obj_: TLightObj; ptype:TLightPointTypeSet);
begin
   Obj:=Obj_;
   ftype:=ptype;
end;

function TLightClickPoint.Diagonal: boolean;
begin
   Result:=([plTop, plBottom]*fType<>[]) and
      ([plLeft, plRight]*fType<>[]);
end;

function TLightClickPoint.GetColor: TColor;
begin
   Result:=clWhite;
end;

function TLightClickPoint.Getx: integer;
var
   rad: integer;
begin
   Result:=Obj.X;
   rad:=Obj.Radius;
   if Diagonal then
      rad:=round(sqrt(2)/2*rad);
   if plLeft in ftype then
      Result:=Obj.X-Rad
   else if plRight in ftype then
      Result:=Obj.X+Rad;
end;

function TLightClickPoint.Gety: integer;
var
   rad: integer;
begin
   Result:=Obj.Y;
   rad:=Obj.Radius;
   if Diagonal then
      rad:=round(sqrt(2)/2*rad);
   if plTop in ftype then
      Result:=Obj.Y-Rad
   else if plBottom in ftype then
      Result:=Obj.Y+Rad;
end;

procedure TLightClickPoint.Select(x1, y1: integer);
begin
   lastx:=x1;lasty:=y1;
end;

procedure TLightClickPoint.SetX(const Value: integer);
begin
   ChangeFXY(Value, lasty);
end;

procedure TLightClickPoint.SetY(const Value: integer);
begin
   ChangeFXY(lastx, Value);
end;

procedure TLightClickPoint.UnSelect;
begin

end;


{ TCustomCPObj }

procedure TCustomCPObj.Action1(sender: TClickPoint; x, y: integer);
begin

end;

procedure TCustomCPObj.Action2(sender: TClickPoint; x, y: integer);
begin

end;

procedure TCustomCPObj.Action3(sender: TClickPoint; x, y: integer);
begin

end;

procedure TCustomCPObj.ActionLink(LinkObj: TCustomCPObj);
begin

end;

initialization
   ClickPoints:=TList.Create;
   LClickPoints:=TList.Create;
end.
