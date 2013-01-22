unit ObjAnim_Lib;

interface

uses
 Windows, SysUtils, OpenGL,
 Engine_Reg,
 Func_Lib,
 Type_Lib,
 Graph_Lib,
 Math_Lib,
 MyEntries;

const
   OWNER_GAME = 0;
   OWNER_MENU = 1;

type
// TBrickTexEntry //
   TBricksTexEntry = class(TCustomEntry)
    protected
     BrkTex : array of TTexData;
    private
     procedure GenerateDefTex;
     function GetBrkTex(i: integer): PTexData;
     procedure SetBrkTex(i: integer; const PTex: PTexData);
     function GetTexCount: integer;
    public
      class function EntryClassName: TEntryClassName;

     constructor Create(Head_: TEntryHead;var F: File);overload;
     destructor Destroy; override;
     procedure WriteToFile(var F: File);override;
     procedure Clear;
     function LoadFromFile(const FileName: string): boolean;
     property Tex[i: integer]: PTexData read GetBrkTex write SetBrkTex; default;
     property TexCount: integer read GetTexCount;
   end;

type
 //Анимация WхH
 TFrameObj = class(TBricksTexEntry)
   flag     : boolean;  //нужен для проверки есть ли объект на карте...
   texowner : integer;
   FileName : string;
   constructor Create(const FileName: string; W, H: WORD;
                      Trans: PRGBA;
                      Clamp, Scale: boolean;
                      Owner: integer = OWNER_GAME); overload;
   constructor Create(const Name: string;
                      Data: pointer;
                      BPP, W, H, Frames: WORD;
                      Owner: integer = OWNER_GAME); overload;
 end;

 TObjTex = class
  private
   FIndex : integer;
   function GetIndex: integer;
   procedure SetIndex(idx: integer);
   function GetFrame(idx: integer): PTexData;
   function GetFrameCount: integer;
   function GetCurFrame: PTexData;
  public
   Tex    : TFrameObj;
   FStartFrame : boolean;
   FWait       : WORD;
   Wait        : WORD;
   constructor Create(const FileName: string;
                      W, H, WaitCount: WORD;
                      Clamp, Scale: boolean;
                      Trans: PRGBA;
                      Owner: integer = OWNER_GAME;
                      buf: pointer = nil;
                      bpp: Byte = 32;
                      Frames: WORD = 1); overload;
   constructor Create(anim: TObjTex); overload;

   procedure NextFrame;
   procedure PrevFrame;
   procedure Update;
   procedure UpdateReverse;
   property FrameIndex : integer read GetIndex write SetIndex;
   property Frame[idx: integer] : PTexData read GetFrame; default;
   //текущий кадр анимации
   property CurFrame : PTexData read GetCurFrame;
   property FrameCount : integer read GetFrameCount;
 end;

procedure ObjTex_MenuBeginLoad;
procedure ObjTex_BeginLoad;
procedure ObjTex_EndLoad;

function TexExists(Name: string): TFrameObj;

implementation

uses Map_Lib;

 var
  FrameObj : array of TFrameObj;  //Все текстуры здесь...

procedure ObjTex_MenuBeginLoad;
var
 i : integer;
begin
for i := 0 to Length(FrameObj) - 1 do
 FrameObj[i].flag := FrameObj[i].texowner <> OWNER_MENU;
end;

procedure ObjTex_BeginLoad;
var
 i : integer;
begin
for i := 0 to Length(FrameObj) - 1 do
 FrameObj[i].flag := FrameObj[i].texowner <> OWNER_GAME;
end;
//если после загрузки останется в false - удалим

procedure ObjTex_EndLoad;
var
 i, j, k : integer;
begin
j := Length(FrameObj);
i := 0;
while i < j do
 if not FrameObj[i].flag then //если не подгружался или не был взят объектом
  begin //удаляем, т.к. он никому не нужен :)
  FrameObj[i].Free;
  for k := i to j - 2 do
   FrameObj[k] := FrameObj[k + 1];
  dec(j);
  end
 else
  inc(i); //следующий...
SetLength(FrameObj, j);
end;

function TexExists(Name: string): TFrameObj;
var
 i : integer;
begin
Result := nil;
for i := 0 to Length(FrameObj) - 1 do
 if FrameObj[i].FileName = Name then
  begin
  Result := FrameObj[i];
  break;
  end;
end;

{ TBricksEntry }

constructor TBricksTexEntry.Create(Head_: TEntryHead;var F: File);
var
 i    : integer;
begin
inherited Create(Head_, F);
fHead.TEXCount:=fHead.TexCount+1;
SetLength(BrkTex, fHead.TexCount);
GenerateDefTex;
for i := 1 to TexCount - 1 do
 begin
 GetMem(BrkTex[i].Data, 32 * 16 * 4);
 BlockRead(f, BrkTex[i].Data[0], 32 * 16 * 4);
 BrkTex[i].BPP    := 32;
 BrkTex[i].Width  := 32;
 BrkTex[i].Height := 16;
 BrkTex[i].Filter := false;
 BrkTex[i].Trans  := false;
// BrkTex[i].Clamp  := true;
 BrkTex[i].Scale  := false;
 BrkTex[i].MipMap := false;
 xglTex_Create(@BrkTex[i]);
 FreeMem(BrkTex[i].Data);
 end;
end;

procedure TBricksTexEntry.GenerateDefTex;
var
 i    : integer;
 x, y : integer;
begin
// Поясняю:
// В файле хранится вся палитра но без 0 брика
// Он генерируется автоматически при создании или загрузке из файла
// и используется как дефолт брик, для предотвращения ошибок
if TexCount = 0 then
 SetLength(BrkTex, 1);
GetMem(BrkTex[0].Data, 32 * 16);
BrkTex[0].BPP    := 8;
BrkTex[0].Width  := 32;
BrkTex[0].Height := 16;
BrkTex[0].Filter := false;
BrkTex[0].Scale  := false;
BrkTex[0].MipMap := false;
FillChar(BrkTex[0].Data[0], 32*16, 128); //СЕРЫЙ БРИК
i := 0;
for y := 0 to 15 do
 for x := 0 to 31 do
  begin
  if (y = 15) or (x = 0) then
   BrkTex[0].Data[i] := 180
  else
   if (y = 0) or (x = 31) then
    BrkTex[0].Data[i] := 100;
  inc(i);
  end;

xglTex_Create(@BrkTex[0]);
FreeMem(BrkTex[0].Data);
end;

function TBricksTexEntry.GetBrkTex(i: integer): PTexData;
begin
if (i < 0) or (i > TexCount - 1) then
 begin
 if TexCount = 0 then
  Result := nil
 else
  Result := @BrkTex[0];
 end
else
 Result := @BrkTex[i];
end;

procedure TBricksTexEntry.SetBrkTex(i: integer; const PTex: PTexData);
begin
if (i > -1) and (i < TexCount) then
 BrkTex[i] := PTex^;
end;

function TBricksTexEntry.GetTexCount: integer;
begin
Result := Length(BrkTex)
end;

destructor TBricksTexEntry.Destroy;
begin
Clear;
end;

procedure TBricksTexEntry.Clear;
var
 i : integer;
begin
for i := 0 to TexCount - 1 do
 xglTex_Free(@BrkTex[i]);
BrkTex := nil;
end;

function TBricksTexEntry.LoadFromFile(const FileName: string): boolean;
var
 buf  : TTexData; //наша временная текстурка
 i    : integer;
 sx, sy : integer;

 function GetPixel(x, y: WORD; Data: PByteArray): TRGBA;
 begin
 Result := PaRGBA(Data)[buf.Width * y + x];
 end;

 procedure FillTex(ID: integer; Data: PByteArray);
 var
  bx, by : integer;
  x, y   : integer;
  i      : integer;
 begin
 bx := (ID mod sx) * 32;
 by := buf.Height - (ID div sx) * 16 - 16;
 i  := 0;
 for y := by to by + 15 do
  for x := bx to bx + 31 do
   begin
   PaRGBA(Data)[i] := GetPixel(x, y, buf.Data);
   i := i + 1;
   end;
 end;

begin
Result := false;
Clear;

 try
  GenerateDefTex;
  //загружает текстуру из bmp, tga или jpg файла
  buf.Trans := true;
  buf.TransC := RGBA(0, 0, 255, 0);
  if not xglTex_LoadData(PChar(Engine_ModDir + FileName), @buf) then
   Exit; //не судьба...

  sx  := buf.Width div 32;
  sy  := buf.Height div 16;

  if (sx = 0) or (sy = 0) then //слишком маленькая палитра
   begin
   xglTex_FreeData(@buf); //освобождаем память под текстуру
   Exit;
   end;

//Таким образом, нам нужно вооот стока текстурок :)
SetLength(BrkTex, sx * sy + 1);

  for i := 1 to TexCount - 1 do 
   begin 
   GetMem(BrkTex[i].Data, 32 * 16 * 4); 
   FillTex(i - 1, BrkTex[i].Data); 
   BrkTex[i].BPP    := 32; 
   BrkTex[i].Width  := 32;
   BrkTex[i].Height := 16;
   BrkTex[i].Filter := false;
   BrkTex[i].Trans  := false;
   BrkTex[i].MipMap := false;
   BrkTex[i].Scale  := false;
   xglTex_Create(@BrkTex[i]);
   FreeMem(BrkTex[i].Data);
   end;
  //т.к. память под текстуру взята из Engine.dll, то пусть он её освобождает :)
  xglTex_FreeData(@buf);
 except
  Exit;
 end;
Result := true;
end;

{ TFrameObj }

constructor TFrameObj.Create(const FileName: string; W, H: WORD; Trans: PRGBA; Clamp, Scale: boolean; Owner: integer);
var
 buf  : TTexData; //наша временная текстурка
 i    : integer;
 sx, sy : integer;

 function GetPixel(x, y: WORD; Data: PByteArray): TRGBA;
 begin
 Result := PaRGBA(Data)[buf.Width * y + x];
 end;

 procedure FillTex(ID: integer; TexData: TTexData);
 var
  bx, by : integer;
  x, y   : integer;
  i      : integer;
 begin
 bx := (ID mod sx) * W;
 by := buf.Height - (ID div sx) * H - H;
 FillChar(TexData.Data^, TexData.Width*TexData.Height*4, 0);
 for y := by to by + H - 1 do
  for x := bx to bx + W - 1 do
   begin
   i := TexData.Width*(y - by) + (x - bx);
   PaRGBA(TexData.Data)[i] := GetPixel(x, y, buf.Data);
   end;
 end;

var
 str    : string;
begin
texowner:=owner;
self.FileName := FileName;
//Практически идентичка LoadFromFile предка...
//но без генерации деф текстуры
Log_ConWrite(false);
 try
  Log('Loading FrameObj "' + Engine_ModDir + FileName + '"');
  //загружает текстуру из bmp, tga или jpg файла
  buf.Trans  := true;
  if Trans = nil then
   buf.TransC := RGBA(0, 0, 255, 0)
  else
   buf.TransC := Trans^;

  str := Engine_ModDir + FileName;
  if not xglTex_LoadData(PChar(str), @buf) then
   begin
   Log_ConWrite(true);
   Exit; //не судьба...
   end;
  // Если один из размеров кадра взятый из параметра равен 0
  // значит второй является коэфициентом пропорциональности относительно
  // (первого + 1) 8)

  // Вот так я реализовал программную поддержку анимации не предусмотренного
  // размера кадров. Главное соблюдать пропорции
  // (n, 0) - анимация записана, как в ряд идущие кадры
  // (0, m) - анимация записана, как в столбик идущие кадры
  // (0, 0) - анимации нет, один кадр из всей текстуры
  // где n - отношение ширины кадра на выоту
  //     m - отношение высоты кадра на ширину
  if (W <> 0) and (H = 0) then // Кадры расположены по горизонтали
   begin
   W := buf.Height * W;
   H := buf.Height;
   end
  else
   if (W = 0) and (H <> 0) then // По вертикали
    begin
    W := buf.Width;
    H := buf.Width * H;
    end
   else
    begin // Просто один большой кадр
    if (W = 0) then W := buf.Width;
    if (H = 0) then H := buf.Height;
    end;

  // Если ни одно из условий не выполнилось, то
  // кадры будут считываться слева-направо сверху-вниз
  // с размером заданным в параметрах

  sx  := buf.Width div W;
  sy  := buf.Height div H;

  if (sx = 0) or (sy = 0) then //слишком маленькая палитра
   begin
   xglTex_FreeData(@buf); //освобождаем память под текстуру
   Log_ConWrite(true);
   Exit;
   end;

  //Таким образом, нам нужно вооот стока текстурок :)
  SetLength(BrkTex, sx * sy);
  for i := 0 to TexCount - 1 do
   begin
   BrkTex[i].Width  := W;
   BrkTex[i].Height := H;
   GetMem(BrkTex[i].Data, BrkTex[i].Width  * BrkTex[i].Height * 4);
   FillTex(i, BrkTex[i]);
   BrkTex[i].BPP    := 32;
   BrkTex[i].Filter := false;
   BrkTex[i].Clamp  := Clamp;
   BrkTex[i].Scale := Scale;
   BrkTex[i].MipMap := false;
   xglTex_Create(@BrkTex[i]);
   FreeMem(BrkTex[i].Data);
   end;
  //т.к. память под текстуру взята из XEngine.dll, то пусть он её освобождает :)
  xglTex_FreeData(@buf);
 except
 end;
Log_ConWrite(true);
end;

constructor TFrameObj.Create(const Name: string; Data: pointer; BPP, W, H, Frames: WORD; Owner: integer = OWNER_GAME);
var
 buf  : TTexData; //наша временная текстурка
 i    : integer;
 sx, sy : integer;

 function GetPixel(x, y: WORD): TRGBA;
 begin
 if bpp = 32 then
  Result := PaRGBA(buf.Data)[W * y + x]
 else
  Result.R := buf.Data[W * y + x]
 end;

 procedure FillTex(ID: integer; TexData: TTexData);
 var
  bx, by : integer;
  x, y   : integer;
  i      : integer;
 begin
 bx := (ID mod sx) * W div Frames;
 by := 0;
 FillChar(TexData.Data^, TexData.Width*TexData.Height*bpp div 8, 0);
 for y := by to by + H - 1 do
  for x := bx to bx + W div Frames - 1 do
   begin
   i := TexData.Width*(y - by) + (x - bx);
   if bpp = 32 then
    PaRGBA(TexData.Data)[i] := GetPixel(x, y)
   else
    TexData.Data[i] := GetPixel(x, y).R
   end;
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

begin
texowner:=owner;
self.FileName := Name;
//Практически идентичка LoadFromFile предка...
//но без генерации деф текстуры
Log_ConWrite(false);
 try
  Log('Loading FrameObj "' + Name + '"');
  //загружает текстуру из bmp, tga или jpg файла
  buf.Trans  := false;
  buf.Data   := Data;
  buf.Width  := W;
  buf.Height := H;

  sx  := Frames;
  sy  := 1;

  if (sx = 0) or (sy = 0) then //слишком маленькая палитра
   begin
   Log_ConWrite(true);
   Exit;
   end;

  //Таким образом, нам нужно вооот стока текстурок :)
  SetLength(BrkTex, sx * sy);
  for i := 0 to TexCount - 1 do
   begin
   BrkTex[i].Width  := NormalizeSize(buf.Width div Frames);
   BrkTex[i].Height := NormalizeSize(buf.Height);

   GetMem(BrkTex[i].Data, BrkTex[i].Width  * BrkTex[i].Height * BPP div 8);
   FillTex(i, BrkTex[i]);
   BrkTex[i].BPP    := BPP;
   BrkTex[i].Filter := false;
   BrkTex[i].Clamp  := true;
   BrkTex[i].Scale  := false;
   BrkTex[i].MipMap := false;
   if bpp = 32 then
    xglTex_Create(@BrkTex[i])
   else
    begin
    glGenTextures(1, @BrkTex[i].ID);
    glBindTexture(GL_TEXTURE_2D, BrkTex[i].ID);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, $812F);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, $812F);
    glTexImage2d(GL_TEXTURE_2D, 0, GL_ALPHA, BrkTex[i].Width, BrkTex[i].Height, 0,
                   GL_ALPHA,
                   GL_UNSIGNED_BYTE, BrkTex[i].Data);
    end;
   FreeMem(BrkTex[i].Data);
   end;
 except
 end;
Log_ConWrite(true);
end;

constructor TObjTex.Create(const FileName: string; W, H, WaitCount: WORD; Clamp, Scale: boolean; Trans: PRGBA; Owner: integer = OWNER_GAME; buf: pointer = nil; bpp: Byte = 32; Frames: WORD = 1);
var
 i : integer;
begin
Wait  := WaitCount;
FWait := WaitCount;
FStartFrame:=false;

for i := 0 to Length(FrameObj) - 1 do
 if (FileName = FrameObj[i].FileName) and (Owner=FrameObj[i].TexOwner) then
  begin //Ух ты... нашли
  Tex := FrameObj[i];
  FrameObj[i].flag := true;
  Exit;
  end;

// нету...
i := Length(FrameObj);
SetLength(FrameObj, i + 1); //расширяем массив
if buf <> nil then
 FrameObj[i] := TFrameObj.Create(FileName, buf, bpp, W, H, Frames, Owner)
else
 FrameObj[i] := TFrameObj.Create(FileName, W, H, Trans, Clamp, Scale, Owner);
Tex := FrameObj[i];
FrameObj[i].flag := true;
end;

procedure TObjTex.NextFrame;
begin
FrameIndex := FrameIndex + 1;
end;

procedure TObjTex.PrevFrame;
begin
FrameIndex := FrameIndex - 1;
end;

function TObjTex.GetIndex: integer;
begin
Result := FIndex;
end;

procedure TObjTex.SetIndex(idx: integer);
begin
if FrameCount = 0 then
 FIndex := 0
else
 begin
 FIndex := idx mod FrameCount;
 if FrameIndex < 0 then FrameIndex := FrameCount - 1;
 end;
end;

function TObjTex.GetFrame(idx: integer): PTexData;
begin
if Tex <> nil then
 Result := Tex.Tex[idx]
else
 Result := nil;
end;

function TObjTex.GetFrameCount: integer;
begin
if Tex <> nil then
 Result := Tex.TexCount
else
 Result := 0;
end;

function TObjTex.GetCurFrame: PTexData;
begin
Result := GetFrame(FrameIndex);
end;

procedure TObjTex.Update;
begin
if FWait > 1 then
 dec(FWait)
else
 begin
 FrameIndex := FrameIndex + 1;
 FWait := Wait;
 FStartFrame:=FIndex=0;
 end;
end;

procedure TObjTex.UpdateReverse;
begin
if FWait > 1 then
 dec(FWait)
else
 begin
 FrameIndex := FrameIndex - 1;
 FWait := Wait;
 end;
end;

constructor TObjTex.Create(anim: TObjTex);
begin
FStartFrame := false;
wait   := anim.Wait;
fwait  := anim.Wait;
Tex    := anim.Tex;
findex := 0;
end;

class function TBricksTexEntry.EntryClassName: TEntryClassName;
begin
   Result:='BrkTexV1';
end;

procedure TBricksTexEntry.WriteToFile(var F: File);
var
   M: TCustomMap;
   i: integer;
begin
   M:=TCustomMap.Create;
   M.LoadFromFile(Map.lastfilename);
   for i:=0 to M.EntriesCount-1 do
      if M.Entries[i].Head.EntryClass='BrkTexV1' then
      begin
         M.Entries[i].WriteToFile(F);
         Break;
      end;
   M.Free;
end;

end.

