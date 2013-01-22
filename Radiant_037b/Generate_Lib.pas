unit Generate_Lib;

interface

uses Constants_Lib;

const
//ЦЕНЫ на оружие:
   WPN_Costs :TWPNArray =
   (0, 10, 20, 30, 35, 40, 60, 70, 120);
   Heal_costs : array [Health5_ID..Health100_ID] of word =
     (5, 25, 50, 100);

type
   TRoom =
   class
      constructor Create(fx1, fy1, fx2, fy2: integer);
  private
    function GetHeight: integer;
    function Getwidth: integer;
    procedure SetHeight(const Value: integer);
    procedure SetWidth(const Value: integer);
   protected
    	yy: array [0..30] of integer;//массив уровня...
   public
      x1, y1, x2, y2: integer;
      brick: integer;
      prevroom, nextroom: TRoom;
      property Width: integer read Getwidth write SetWidth;
      property Height: integer read GetHeight write SetHeight;

      procedure SplitH(minw, maxw: integer);
      procedure SplitV(minh, maxh: integer);

      procedure FillPrepare;
      procedure FillSurf;
      procedure Fill;
   end;

var
   rooms: array [1..100000] of TRoom;
   rc: integer;

function AddRoom(r: TRoom): TRoom;
procedure RDelete(i: integer);
procedure RClear;

implementation

uses Main, MapObj_Lib, TFKEntries;

function AddRoom(r: TRoom): TRoom;
begin
   Inc(rc);
   rooms[rc]:=r;
   result:=r;
end;

procedure RDelete(i: integer);
begin
end;

procedure RClear;
var
   i: integer;
begin
   for i:=1 to rc do rooms[i].Free;
   rc:=0;
end;

//функции помощи в постановке предметов
function PlaceWeapon(x, y: integer; MaxCost: integer): integer;
var
   i, m: integer;
   struct: TMapObjStruct;
begin
   for m:=1 to 8 do
      if WPN_Costs[m]>MaxCost then
         break;
   i:=random(m)+1;
   Result:=i;
   if i>0 then
   begin
      FillChar(struct, sizeof(struct), 0);
      struct.width:=1;
      struct.height:=1;
      struct.x:=x;
      struct.y:=y;
      struct.weaponID:=i;
      if i>1 then
      	struct.ObjType:=otWeapon
      else
      	struct.ObjType:=otAmmo;
      Map.Obj.Add(struct).SetDefValues;
   end;
end;

procedure PlaceAmmo(x, y: integer; wpn: integer);
var
   struct: TMapObjStruct;
begin
   FillChar(struct, sizeof(struct), 0);
   struct.width:=1;
   struct.height:=1;
   struct.x:=x;
   struct.y:=y;
   struct.weaponID:=wpn;
  	struct.ObjType:=otAmmo;
   Map.Obj.Add(struct).SetDefValues;
end;

procedure PlaceJumpPad(x, y, height: integer);
var
   struct: TMapObjStruct;
begin
   FillChar(struct, sizeof(struct), 0);
   struct.width:=1;
   struct.height:=1;
   struct.x:=x;
   struct.y:=y;
   struct.ObjType:=otJumpPad;
   if Height>5 then
   	struct.jumpspeed:=5.0
      else struct.jumpspeed:=4.0;
   Map.Obj.Add(struct).SetDefValues;
end;

procedure PlaceRespawn(x, y: integer);
var
   struct: TMapObjStruct;
begin
   FillChar(struct, sizeof(struct), 0);
   struct.width:=1;
   struct.height:=1;
   struct.x:=x;
   struct.y:=y;
   struct.ObjType:=otRespawn;
   struct.orient:=0;
   Map.Obj.Add(struct).SetDefValues;
end;

procedure PlaceTeleport(x1, y1, x2, y2: integer);
var
   struct: TMapObjStruct;
begin
   FillChar(struct, sizeof(struct), 0);
   struct.width:=1;
   struct.height:=1;
   struct.x:=x1;
   struct.y:=y1;
   struct.gotox:=x2;
   struct.gotoy:=y2;
   struct.ObjType:=otTeleport;
   struct.orient:=0;
   Map.Obj.Add(struct).SetDefValues;
end;

function PlaceHealth(x, y, maxcost: integer): integer;
var
   struct: TMapObjStruct;
   i, m: integer;
begin
   FillChar(struct, sizeof(struct), 0);
   struct.width:=1;
   struct.height:=1;
   struct.x:=x;
   struct.y:=y;
   struct.ObjType:=otHealth;
   for m:=Health5_ID to Health100_ID do
       if heal_costs[m]>maxcost then
          Break;
   i:=random(m-Health5_ID)+Health5_ID;
   struct.itemID:=i;
   if m>Health5_ID then
   	Map.Obj.Add(struct).SetDefValues
      else i:=0;
   Result:=i;
end;


{ TRoom }

constructor TRoom.Create(fx1, fy1, fx2, fy2: integer);
begin
   x1:=fx1;y1:=fy1;x2:=fx2;y2:=fy2;
end;

procedure TRoom.Fill;
var
   j: integer;
begin
//заполняем - ставим одно оружие, респаун и телепорт в след. комнату
   with Map do
   begin
      if nextroom<>nil then
         PlaceTeleport(x2, y2-yy[x2-x1], nextroom.x1+2, nextroom.y2);
      if prevroom<>nil then
         PlaceTeleport(x1+1, y2-yy[1], prevroom.x2-1, prevroom.y2);
      //теперь респаун, если ширина позволяет
      if Self.Width>3 then
      begin
      	if random(4)>1 then
         begin
            j:=x1+Self.Width div 2;
            PlaceRespawn(j, y2-yy[j-x1]);
         end;
         j:=x1+Self.Width div 2+random(3)-1;
         if random(3)>0 then
            PlaceWeapon(j, y2-yy[j-x1], 100)
         else
            PlaceHealth(j, y2-yy[j-x1], 100);
      end;
   end;
end;

procedure TRoom.FillPrepare;
begin
   yy[0]:=0;
   yy[width-1]:=0;
end;

procedure TRoom.FillSurf;
var
   maxh: integer;
   i, j: integer;
begin
   maxh:=height-4;
   if maxh>2 then maxh:=2;
   if random(3)>1 then maxh:=1;
  //заполняем Surface;
   for i:=1 to width-2 do
      yy[i]:=random(maxh);
   //теперь переходим к заливу бриков
   with Map do
   for i:=x1 to x2 do
      for j:=0 to yy[i-x1]-1 do
      begin
         brk[i, y2-j]:=brick;
         brk.blocked[i, y2-j]:=true;
      end;
end;

function TRoom.GetHeight: integer;
begin
   Result:=y2-y1+1;
end;

function TRoom.Getwidth: integer;
begin
   Result:=x2-x1+1;
end;

procedure TRoom.SetHeight(const Value: integer);
begin
   y2:=y1+Value-1;
end;

procedure TRoom.SetWidth(const Value: integer);
begin
   x2:=x1+Value-1;
end;

procedure TRoom.SplitH(minw, maxw: integer);
var
   max, w: integer;
begin
   while Width>(minw+maxw) div 2 do
   begin
      max:=Width-minw;
      if max>maxw then max:=maxw;
      if max<minw then Exit;
      w:=random(max-minw+1)+minw;
      AddRoom(TRoom.Create(x1, y1, x1+w-1, y2));
      x1:=x1+w;
   end;
end;

procedure TRoom.SplitV(minh, maxh: integer);
var
   max, h: integer;
begin
   while Height>(minh+maxh) div 2 do
   begin
      max:=Height-minh;
      if max>maxh then max:=maxh;
      if max<minh then Exit;
      h:=random(max-minh+1)+minh;
      AddRoom(TRoom.Create(x1, y1, x2, y1+h-1));
      y1:=y1+h;
   end;
end;

end.
