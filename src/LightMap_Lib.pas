unit LightMap_Lib;

interface

//генерация lightmaps в радианте...

uses Windows, SysUtils, OpenGL,
     Engine_Reg,
     Graph_Lib,
     Type_Lib,
     Math_Lib,
     Constants_Lib,
     Particle_Lib,
     MyEntries;//TPoint использовать надо!

//эта секция только для создания лайтмап и записи их в файлик.
//при загрузке LightMaps радиантом, она берётся как TSimpleEntry -
//а при компиляции заменяется экземпляром данного класса

type
  TLightObjStruct =  record
    Pos      : TPoint;//тип TPoint у нас в модуле Windows...
    Radius   : Word;
    Color    : TRGB;
    Reserved : array [0..8] of Byte;
   end;
   //итого - 16 байт

   PLightObjStruct = ^TLightObjStruct;

   TLightObj = class
     constructor Create(fstruct: TLightObjStruct);
     destructor Destroy; override;
    private
     Sprite : TP_Light;
    public
     Struct : TLightObjStruct;
     procedure Update;
     procedure Draw;
     property Pos: TPoint read Struct.Pos write Struct.Pos;
     property X: integer read Struct.Pos.X;
     property Y: integer read Struct.Pos.Y;
     property Radius: word read Struct.Radius write Struct.Radius;
     property Color: TRGB read Struct.Color write Struct.Color;
   end;

   TLightsEntry = class(TSimpleEntry)
     constructor Create(Head_: TEntryHead; var F: File);overload;
     destructor Destroy;override;
    protected
     objs : array of TLightObj;
     function GetObj(i: integer): TLightObj;
     function GetHead: TEntryHead;override;
    public
     class function EntryClassName: TEntryClassName;
     procedure WriteToFile(var F: File); override;

     function Count: integer;
     property Obj[i: integer]: TLightObj read GetObj; default;
   end;

   TLightMapEntry = class(TCustomEntry)
     //загрузка лайтмап
     constructor Create(Head_: TEntryHead; var F: File);overload;
     constructor Create; overload;
     destructor Destroy;override;
    protected
     function GetHead: TEntryHead; override;
    private
     Quality : Byte;
     FItems  : array of TTexData;
     FLMap   : array of array of WORD;
     function GetTex(x, y: integer): PTexData;
    public
     needgenerate: boolean;
     class function EntryClassName: TEntryClassName;
     procedure WriteToFile(var F: File); override;

     procedure Generate;
     property lMapTex[x, y: integer]: PTexData read GetTex;
     //за запись в файлик не волнуйся - я придумал новый алгоритм -
     //грузит из старой карты все секции и переписывает в новую, реализовать 5 сек.
     //а можно вообще лайтмапы не писать! демки малого размера, лайты не нужны там!
     //НА ДАННЫЙ МОМЕНТ Лайтмапа в дему писаться будет, но с size=0
     //а при загрузке её просто будут игнорировать ;)
   end;

implementation

uses
 Map_Lib, TFKEntries, NET_Lib, NET_Client_Lib;

{ TLightObj }

constructor TLightObj.Create(fstruct: TLightObjStruct);
begin
struct := fstruct;
Sprite := TP_Light.Create(Point2f(X, Y), Point2f(Radius/8, Radius/8),
                          RGBA(Color.R, Color.G, Color.B, 200), 1);
end;

destructor TLightObj.Destroy;
begin
Sprite.Free;
end;

procedure TLightObj.Update;
var
 i : integer;
 a : integer;
begin
a := Sprite.Color.A;
for i := 0 to Map.Players - 1 do
 if PointInRect(X, Y, Map.Player[i].fRect) then
  begin
  dec(a, 10);
  break;
  end;

if a < 0   then a := 0;
if a > 255 then a := 255;

if (a = Sprite.Color.A) and (a < 200) then
 inc(a, 10);
Sprite.Color.A := a;
end;

procedure TLightObj.Draw;
begin
if r_lights then
 Sprite.Draw;
end;

{ TLightsEntry }

function TLightsEntry.Count: integer;
begin
Result := Length(objs);
end;

constructor TLightsEntry.Create(Head_: TEntryHead; var F: File);
var
 i      : integer;
 struct : PLightObjStruct;
begin
inherited Create(head_, F);
SetLength(Objs, head_.size div SizeOf(TlightObjStruct));
for i := 0 to head_.size div SizeOf(TLightObjStruct)-1 do
 begin
 struct  := @buf[i*SizeOf(TLightObjStruct)];
 objs[i] := TlightObj.Create(struct^);
 end;
end;

destructor TLightsEntry.Destroy;
var
 i : integer;
begin
	for i := 0 to Count - 1 do
 		Objs[i].Free;
	Objs := nil;
	inherited;
end;

class function TLightsEntry.EntryClassName: TEntryClassName;
begin
	Result := 'LightsV1';
end;

function TLightsEntry.GetHead: TEntryHead;
begin
fhead.EntryClass := EntryClassName;
fhead.size := Count*SizeOf(TLightObjStruct);
Result := fhead;
end;

function TLightsEntry.GetObj(i: integer): TLightObj;
begin
Result := Objs[i];
end;

procedure TLightsEntry.WriteToFile(var F: File);
var
 i      : integer;
 struct : TLightObjStruct;
begin
GetHead;
BlockWrite(f, fhead, SizeOf(fhead));
for i:=0 to Count-1 do
 begin
 struct := Obj[i].Struct;
 BlockWrite(f, struct, SizeOf(struct));
 end;
end;

{ TLightMapEntry }

constructor TLightMapEntry.Create(Head_: TEntryHead; var F: File);
var
 pData  : PByteArray;
 size   : WORD;
 count  : WORD;
 x, y   : integer;
 i      : integer;
 t      : DWORD;
begin
inherited;
NeedGenerate:=false;
if (head_.size = 0) or (head_.version <> 1) then
 NeedGenerate:=true
else
 begin
 t := GetTickCount;
 SetLength(FLMap, Map.Width, Map.Height);
 BlockRead(F, Quality, 1);

 if Quality <> r_lightmap_quality then
  begin
  NeedGenerate:=true;
  Exit;
  end;

 BlockRead(F, count, 2);
 SetLength(FItems, count);
 size := 32 * 16 * 3 div sqr(Quality);
 GetMem(pData, size);
 for i := 0 to Length(FItems) - 1 do
  with FItems[i] do
   begin
   BlockRead(F, pData[0], size);
   Data   := pData;
   BPP    := 24;
   Width  := 32 div Quality;
   Height := 16 div Quality;
   Filter := false;
   Trans  := false;
   Clamp  := true;
   Scale  := false;
   MipMap := false;
   xglTex_Create(@FItems[i]);
   end;
 FreeMem(pData);

 for y := 0 to Map.Height - 1 do
  for x := 0 to Map.Width - 1 do
   BlockRead(F, FLMap[x, y], 2);
 Log('^2LightMap loaded from map ^b' + IntToStr(GetTickCount - t) + '^n ms');
 end;

end;

constructor TLightMapEntry.Create;
begin
	needGenerate:=true;
end;

destructor TLightMapEntry.Destroy;
var
 i : integer;
begin
FLMap := nil;
for i := 0 to Length(FItems) - 1 do
 xglTex_Free(@FItems[i]);
inherited;
end;

function TLightMapEntry.GetTex(x, y: integer): PTexData;
begin
if (x < 0) or (x > Map.Width - 1) or
   (y < 0) or (y > Map.Height - 1) or
   (FLMap = nil) or (FItems = nil) then
 begin
 Result := nil;
 xglTex_Disable;
 end
else
 Result := @FItems[FLMap[x, y]];
end;

class function TLightMapEntry.EntryClassName: TEntryClassName;
begin
Result := 'LightMapV1';
end;

function TLightMapEntry.GetHead: TEntryHead;
begin
fhead.version := 1;
fhead.EntryClass := EntryClassName;
fhead.size := 1 +                                         // Quality
              2 +                                         // Count
              Length(FItems) * 32 * 16 * 3 div sqr(Quality) + // Textures
              Map.Width * Map.Height * 2;                 // Index Map
Result := fhead;
end;

procedure TLightMapEntry.WriteToFile(var F: File);
var
 i      : integer;
 pixels : PByteArray;
 size   : WORD;
 x, y   : integer;
begin
inherited;
BlockWrite(F, Quality, 1);
size := Length(FItems);
BlockWrite(F, size, 2);

size := 32 * 16 * 3 div sqr(Quality);
GetMem(pixels, size);
for i := 0 to Length(FItems) - 1 do
 begin
 xglTex_Enable(@FItems[i]);
 glGetTexImage(GL_TEXTURE_2D, 0, GL_RGB, GL_UNSIGNED_BYTE, pixels);
 BlockWrite(F, pixels[0], size);
 end;
FreeMem(pixels);

for y := 0 to Map.Height - 1 do
 for x := 0 to Map.Width - 1 do
  BlockWrite(F, FLMap[x, y], 2);
end;

procedure TLightMapEntry.Generate;
const
 smooth_depth = 8;

type
 POptLight = ^TOptLight;
 TOptLight = record
  X, Y   : integer;
  Radius : single;
  Color  : TRGB;
 end;

var
 xb, yb   : integer;
 xt, yt   : integer;
 xp, yp   : integer;
 i        : integer;
 BlockM   : array of array of Byte;
 pData    : PaRGB;
 Size     : integer;
 Rast, Rast2: single;
 EnvColor : TRGB;
 bool     : boolean;
 rtrast   : single;
 Light    : array of TOptLight;
 depth    : single;
 pixels   : PaRGBA;
 bricked  : boolean;

 function RayTrace(x1, y1, x2, y2: integer): boolean;
 var
  dx, dy  : integer;
  sx, sy  : integer;
  ex, ey  : integer;
  z, e, i : integer;
  Ch      : boolean;
  x, y    : integer;

 function Blocked: boolean;
 begin
 if BlockM[x, y] = 2 then
  begin
  BlockM[x, y] := Byte(Map.Block_b(x * r_lightmap_quality div 32,
                                   y * r_lightmap_quality div 16));
  if bricked and boolean(BlockM[x, y]) then
   BlockM[x, y] := Byte(pixels[r_lightmap_quality*((yt - yp - 1)*32 + xp)].A <> 0)
  end;
 Result := boolean(BlockM[x, y]);
 end;

 begin
 // 4-связная развертка отрезка методом Брэзенхема 8)
 Result := false;
 rtrast := 0;

 x   := x1;
 y   := y1;
 ex  := 0;
 ey  := 0;
 dx  := abs(x2 - x1);
 dy  := abs(y2 - y1);
 sx  := sign(x2 - x1);
 sy  := sign(y2 - y1);
 e   := 2*dy - dx;
 if dy >= dx then
  begin
  z  := dx;
  dx := dy;
  dy := z;
  Ch := true;
  end
 else
  Ch := false;

 for i := 1 to dx + dy  do
  begin
  if Blocked then
   if rtrast = 0 then
    begin
    ex := x;
    ey := y;
    rtrast := 1;
    end
   else
    begin
    rtrast := sqr(x - ex) + sqr(y - ey);
    if rtrast >= depth then
     Exit
    end
  else
   if rtrast > 0 then
    Exit;

  if e < dx then
   begin
   if Ch then
    y := y + sy
   else
    x := x + sx;
   e := e + 2*dy;
   end
  else
   begin
   if Ch then
    x := x + sx
   else
    y := y + sy;
   e := e - 2*dx;
   end;
  end;

 if rtrast = 0 then
  Result := true
 else
  Result := blocked;
 end;

 procedure incRGB(var c: TRGB; var Light: TOptLight);
 var
  k : integer;
  s : single;
 begin
 with Light.Color do
  begin
  s := 1 - sqrt(rast/Light.Radius);
  if rtrast > 0 then
   s := s * (1 - sqrt(rtrast/depth));

  k := c.R + trunc(R * s);
  if k > 255 then k := 255;
  c.R := k;

  k := c.G + trunc(G * s);
  if k > 255 then k := 255;
  c.G := k;

  k := c.B + trunc(B * s);
  if k > 255 then k := 255;
  c.B := k;
  end;
 end;

 procedure Blur;
 var
  x, y    : integer;
  idx     : integer;
  ppData  : PaRGB;
  sR, sG, sB : integer;

  function Get(x, y: integer): TRGB;
  var
   i : integer;
  begin
  // По условиям x и y > 0
  if (x >= xt) or (y >= yt) then
   begin
   Result.R := 0;
   Result.G := 0;
   Result.B := 0;
   end
  else
   begin
   i := y * xt + x;
   Result := pData[i];
   inc(idx);
   end;
  end;

  procedure IncColor(x, y: integer);
  begin
  with Get(x, y) do
   begin
   sR := sR + R;
   sG := sG + G;
   sB := sB + B;
   end;
  end;

 begin
 GetMem(ppData, Size * 3);
 for y := 0 to yt - 1 do
  for x := 0 to xt - 1 do
   begin
   idx := 0;
   sR  := 0;
   sG  := 0;
   sB  := 0;

   incColor(x,     y);
   incColor(x + 1, y);
   incColor(x + 1, y + 1);
   incColor(x,     y + 1);

   i := y * xt + x;
   ppData[i].R := sR div idx;
   ppData[i].G := sG div idx;
   ppData[i].B := sB div idx;
   end;
 FreeMem(pData);
 pData := ppData;
 end;

 Function NormalizeSize(int : integer) : integer;
 asm
   bsr ecx, eax
   mov edx, 2
   add eax, eax
   shl edx, cl
   cmp eax, edx
   jne @ne
   shr edx, 1
 @ne :
   mov eax, edx
 end;

var
 t, Progress : DWORD;
 PrSize      : single;
 LightList : array of array of TList;
 LightOpt  : POptLight;
 p         : PListItem;
 ptex      : PTexData;
 PItems    : TList;
 net_pong  : DWORD;
const
 Msg = 'LightMap generation. Please wait...';
begin
t := GetTickCount;

for i := 0 to Length(FItems) - 1 do
 xglTex_Free(@FItems[i]);
FLMap  := nil;
FItems := nil;

r_lightmap_quality := NormalizeSize(r_lightmap_quality);
Quality := r_lightmap_quality;

xt := 32 div r_lightmap_quality;
yt := 16 div r_lightmap_quality;

Size := xt*yt;
GetMem(pData, Size*3);
SetLength(BlockM, Map.Width*xt, Map.Height*yt);
SetLength(FLMap, Map.Width, Map.Height);

for yb := 0 to Map.Height*yt - 1 do
 for xb := 0 to Map.Width*xt - 1 do
  BlockM[xb, yb] := 2;

EnvColor := TRGB(Map.head.EnvColor);

// Не освещённый элемент
for i := 0 to Size - 1 do
 pData[i] := EnvColor;

PItems.Init;

New(ptex);
with ptex^ do
 begin
 Data   := PByteArray(pData);
 BPP    := 24;
 Width  := xt;
 Height := yt;
 Filter := false;
 Trans  := false;
 Clamp  := true;
 Scale  := false;
 MipMap := false;
 end;
xglTex_Create(ptex);
PItems.Add(ptex);

SetLength(Light, Map.Lights.Count);

depth := sqr(smooth_depth div r_lightmap_quality);
// создаём оптимизированные источники света
for i := 0 to Map.Lights.Count - 1 do
 with Map.Lights[i] do
  begin
  Light[i].radius := sqr(radius div r_lightmap_quality);
  Light[i].X      := X div r_lightmap_quality;
  Light[i].Y      := Y div r_lightmap_quality;
  Light[i].Color  := Color;
  end;

// каждому брику назначаем список источников света
SetLength(LightList, Map.Width, Map.Height);

for yb := 0 to Map.Height - 1 do
 for xb := 0 to Map.Width - 1 do
  begin
  LightList[xb, yb].Init;
  // если брик (место) полностью окружен
  /// 1 1 1
  /// 1 0 1
  /// 1 1 1
  // значит от не имеет источников света
  if Map.block_b_(xb - 1, yb - 1) and
     Map.block_b_(xb + 1, yb - 1) and
     Map.block_b_(xb + 1, yb + 1) and
     Map.block_b_(xb - 1, yb + 1) and
     Map.block_b_(xb, yb - 1) and
     Map.block_b_(xb, yb + 1) and
     Map.block_b_(xb - 1, yb) and
     Map.block_b_(xb + 1, yb) then
   continue;  

  // ищем источники света светящие на объект (по радиусу) 
  for i := 0 to Map.Lights.Count - 1 do
   with Light[i] do
    if (sqr(xb*xt - X) + sqr(yb*yt - Y) < radius) or
       (sqr((xb+1)*xt - X) + sqr((yb+1)*yt - Y) < radius) or
       (sqr((xb+1)*xt - X) + sqr(yb*yt - Y) < radius) or
       (sqr(xb*xt - X) + sqr((yb+1)*yt - Y) < radius) then
    LightList[xb, yb].Add(@Light[i]);
  end;

// Очистка экрана
glViewport(0, 0, xglWidth, xglHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
gluOrtho2D(0, 640, 480, 0);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity;
xglAlphaBlend(0);
PrSize := Map.Width*Map.Height;

// Расчёт карты света
Progress := 0;
net_pong := GetTickCount;
GetMem(pixels, 32*16*4);
bool := true;
for yb := 0 to Map.Height - 1 do
 begin
 glClear(GL_COLOR_BUFFER_BIT);
 xglTex_Disable;
 glBegin(GL_QUADS);
  glColor3f(0, 0, 0);
  glVertex2f(70, 260);
  glVertex2f(70, 220);
  glColor3f(1, 0, 0);
  glVertex2f(70 + Progress*500/PrSize, 220);
  glVertex2f(70 + Progress*500/PrSize, 260);
 glEnd;
 glColor3f(1, 1, 1);
 glBegin(GL_LINE_STRIP);
  glVertex2f(70, 260);
  glVertex2f(70, 220);
  glVertex2f(570, 220);
  glVertex2f(570, 260);
  glVertex2f(70, 260);
 glEnd;
 xglSwap;
 inc(Progress, Map.Width);
 for xb := 0 to Map.Width - 1 do
  begin
  // Если клиент - то посылаем понг серверу, дабы тот нас не кикнул
  if NET.Type_ = NT_CLIENT then
   if GetTickCount - net_pong >= 500 then
    begin
    NET_Update;
    NET_Client.Serv.SendPong;
    net_pong := GetTickCount;
    end;

  // обнуляем цвет в буфере текстуры текущего брика (фоновое освещение)
  if bool then
   begin
   for i := 0 to Size - 1 do
    pData[i] := EnvColor;
   bool := false;
   end;

  // берём текстуру брика 
  if Map.Block_b_(xb, yb) then
   begin
   Map.BrkTexEnable(Map.Brk[xb, yb], MASK_BLOCK);
   glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
   bricked := true;
   end
  else
   bricked := false;

  // расчёт освещения для брика 
  p := LightList[xb, yb].items;
  while p <> nil do
   begin
   with POptLight(p^.data)^ do
    for yp := 0 to yt - 1 do
     for xp := 0 to xt - 1 do
      begin
      rast := sqr(xb*xt + xp - X) + sqr(yb * yt + yp - Y);
      if (rast < radius) and
         RayTrace(X, Y, xb * xt + xp, yb * yt + yp) then
       begin
       incRGB(pData[(yt - yp - 1)*xt + xp], POptLight(p^.data)^);
       bool := true;
       end;
      end;
   p := p^.Next;
   end;
  LightList[xb, yb].Free;

  // если на брик действительно светил свет - создаём текстуру
  if bool then
   begin
   New(ptex);
   for i := 1 to r_lightmap_smooth do
    Blur;
   with ptex^ do
    begin
    Data   := PByteArray(pData);
    BPP    := 24;
    Width  := xt;
    Height := yt;
    Filter := false;
    Trans  := false;
    Clamp  := true;
    Scale  := false;
    MipMap := false;
    end;

   xglTex_Create(ptex);
   FLMap[xb, yb] := PItems.Count;
   PItems.Add(ptex);
   end
  else
   FLMap[xb, yb] := 0; // На брик не попадает свет
  end;
 end;

// создаём сам буфер с текстурами
SetLength(FItems, PItems.Count);
p := PItems.items;
i := PItems.Count;
while p <> nil do
 begin
 dec(i);
 FItems[i] := PTexData(p^.data)^;
 p := p^.Next;
 end;

// уборочка 
BlockM := nil;
Light  := nil;
FreeMem(pixels);
FreeMem(pData);
LightList := nil;
PItems.Free;

// в демки лайтмэп не пихаем
if not Map.demoplay then
 AppendSectionToFile(self, Map.lastfilename, Map.lastfilename);

Log('^2LightMap generated with ^b' + IntToStr(GetTickCount - t) + '^n ms');
Engine_FlushTimer;
end;



end.
