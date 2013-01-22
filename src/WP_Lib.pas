unit WP_Lib;

interface

uses
  Windows, MyEntries, Math_Lib;

const
   WP_Size     = 8;
   WPLink_Size = 2;
   WP_MaxLen   = 256;

type
  TLink = record
   idx    : integer;
   Weight : WORD;
  end;

  TWPObj = class
    constructor Create(x, y: WORD; t: Byte);
    destructor Destroy; override;
   public
    X, Y    : WORD;
    ID      : WORD;
    wp_type : Byte;
    tmp     : Byte;
   // Переменные для поиска пути
    flag    : boolean; // Был ли просмотрен
    blocked : boolean; // Заблокирован ли вейпоинт
    sum     : DWORD;   // Общая сумма в данной точке
    Prev    : WORD;    // Ссылка на предыдущий вейпоинт
    Link    : array of TLink;
    function Count: integer;
  end;

  TWPEntry = class(TCustomEntry)
    constructor Create(Head_: TEntryHead; var F: File); overload;
    constructor Create; overload;
    destructor Destroy; override;
   protected
    function GetHead: TEntryHead; override;
   public
    WayLen : integer;                         // Длина найденного пути
    Way    : array [0..WP_MaxLen - 1] of integer; // Найденный путь
    WP     : array of TWPObj;                 // Сами вейпоинты
   // Искать путь от wp1 до wp2
    function FindWay(wp1, wp2: integer): boolean;
   // Найти ближайший к данной точке вейпоинт
    function GetNearest(X, Y: integer): integer;
    class function EntryClassName: TEntryClassName;
    function Count: integer;
    	//возвращает прямую дистанцию между двумя вэйпойнтами
    function Dist(wp1, wp2: integer): integer;overload;
    function Dist(x, y, wp1: integer): integer;overload;
    procedure Clear;
  end;

implementation

uses
 Map_Lib, MapObj_Lib;

{ TWPObj }

constructor TWPObj.Create(x, y: WORD; t: Byte);
begin
Link    := nil;
wp_type := t;
self.X  := x;
self.Y  := y;
end;

destructor TWPObj.Destroy;
begin
Link := nil;
end;

function TWPObj.Count: integer;
begin
Result := Length(Link)
end;

{ TWPEntry }

procedure TWPEntry.Clear;
var
 i: integer;
begin
for i := 0 to Count - 1 do
 WP[i].Free;
WP := nil;
end;

function TWPEntry.Count: integer;
begin
Result := Length(WP);
end;

constructor TWPEntry.Create(Head_: TEntryHead; var F: File);
var
 i, j, k  : integer;
 wc, next : word;
begin
inherited;
// Загрузка секции с WayPoint'ами :)
SetLength(WP, fhead.TEXcount);
for i := 0 to fhead.TEXCount - 1 do
 WP[i] := TWPObj.Create(0, 0, 0);

for i := 0 to fhead.TEXCount - 1 do
 with WP[i] do
  begin
  BlockRead(F, X, 2);
  BlockRead(F, Y, 2);
  BlockRead(F, wp_type, 1);
  BlockRead(F, tmp, 1);
  BlockRead(F, wc, 2);
  SetLength(Link, wc);
  for j := 0 to integer(wc) - 1 do
   begin
   BlockRead(F, next, 2);
   Link[j].idx := next;
   end;
  // Вобщем в редакторе надо бы не бриковые
  // координаты писать :)
  X := X * 32 + 16;
  Y := Y * 16 + 8; 
  end;

// Расчёт весов на линках
for i := 0 to Length(WP) - 1 do
 with WP[i]  do
 begin
 //поиск объекта.
  for j := 0 to Length(Link) - 1 do
   with Link[j] do
    Weight := trunc(sqrt(sqr(X - WP[idx].X) +
                         sqr(Y - WP[idx].Y)));

  for j := 0 to Map.Obj.Count-1 do
     if (Map.obj[j].objtype in [otTeleport, otPortal, otAreaTeleport]) then
    	  if PointInRect(X, Y, Map.obj[j].ActivateRect) then
         begin
            for k:=0 to Length(Link) - 1 do
               with Link[k], Map.Obj[j].struct do
            		if (Self.WP[idx].X>=gotox*32) and
                     (Self.WP[idx].X<=gotox*32+32) and
                     (Self.WP[idx].Y>=gotoy*16-32) and
                     (Self.WP[idx].Y<=gotoy*16+16) then
                     Weight:=0;
         end;
 end;
end;

constructor TWPEntry.Create;
begin
end;

destructor TWPEntry.Destroy;
begin
Clear;
inherited;
end;

class function TWPEntry.EntryClassName: TEntryClassName;
begin
Result := 'WPEntryV1';
end;

function TWPEntry.GetHead: TEntryHead;
var
 i : integer;
begin
fhead.EntryClass := EntryClassName;
fhead.Version    := 1;
fhead.size       := Count * WP_SIZE;
fhead.TEXCount   := Count;
for i := 0 to count - 1 do
 Inc(fhead.size, WP[i].Count * WPLINK_SIZE);
Result := fhead;
end;

function TWPEntry.FindWay(wp1, wp2: integer): boolean;
var
 i, j : integer;
 size : integer;
 buf  : array [0..255] of integer;
 k    : integer;

 function FindMin: integer;
 var
  i : integer;
 begin
 Result := 0;
 for i := 1 to size - 1 do
  if WP[buf[i]].sum < WP[buf[Result]].sum then
   Result := i;
 end;

begin
Result := false;
WayLen := 0; // Думаем, что дороги нет
if (wp1 < 0) or (wp2 < 0) or (wp1 = wp2) then
 Exit; // Вах, савсэм нэт, да? :{

// Зачистка :)
for i := 0 to Count - 1 do
 with WP[i] do
  flag := blocked;

WP[wp1].flag := true;
WP[wp2].sum  := High(DWORD); // Так нуна :)
// Заносим стартовую точку в буфер
buf[0]       := wp1;
size         := 1;
// Нус, приступим...
while size > 0 do
 begin
 j := FindMin;
 k := buf[j];
 if k = wp2 then
  begin
  Result := true;
  break;
  end;
 buf[j] := buf[size - 1];
 dec(size);
 for i := 0 to WP[k].Count - 1 do
  with WP[k], Link[i] do
   if not WP[idx].flag or (idx = wp2) then
    begin
    if (idx = wp2) and (WP[idx].sum < sum + Weight) then
     continue;
    buf[size] := idx;
    inc(size);
    WP[idx].sum  := sum + Weight;
    WP[idx].Prev := k;
    inc(WP[idx].flag);
    end;
 end;

if Result then
 begin
 // Путь пишется в массив
 // причём, задом на перёд =)
 // т.е. от финиша к старту
 i := wp2;
  repeat
   if WayLen = WP_MaxLen - 1 then
    begin
    WayLen := 0;
    Result := false;
    Exit;
    end;
   Way[WayLen] := i;
   inc(WayLen);
   i := WP[i].Prev;
  until i = wp1;
 Way[WayLen] := i;
 inc(WayLen);
 end;
end;

function TWPEntry.GetNearest(X, Y: integer): integer;
var
 i   : integer;
 d   : integer;
 Min : integer;
begin
Result  := -1;
Min     := High(integer);
for i := 0 to Count - 1 do
 if not WP[i].blocked then
  begin
  d := sqr(integer(X) - integer(WP[i].X)) +
       sqr(integer(Y) - integer(WP[i].Y));
  if d < min then
   begin
   Result := i;
   Min    := d;
   end;
  end;
end;


function TWPEntry.Dist(wp1, wp2: integer): integer;
var
   w1, w2: TWPObj;
begin
   if (wp1>=0) and (wp1<Count) and
      (wp2>=0) and (wp2<Count) then
      begin
         w1:=WP[wp1];w2:=WP[wp2];
      	Result:=trunc( Sqrt ( Sqr(w1.x-w2.x)+Sqr(w1.y-w2.y) ) )
      end else Result:=MAXINT;
end;

function TWPEntry.Dist(x, y, wp1: integer): integer;
var
   w1: TWPObj;
begin
   if (wp1>=0) and (wp1<Count) then
      begin
         w1:=WP[wp1];
      	Result:=trunc( Sqrt ( Sqr(x-w1.x)*4+Sqr(y-w1.y) ) );
      end else Result:=65535;
end;

end.
