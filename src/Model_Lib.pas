unit Model_Lib;

interface

uses
 Windows,
 OpenGL,
 Constants_lib,
 Particle_Lib,
 Func_Lib,
 Engine_Reg,
 Graph_Lib,
 ObjAnim_Lib,
 ObjSound_Lib;

const
 ANIM_WALK    = 0;
 ANIM_CROUCH  = 1;
 ANIM_DIED    = 2;
 ANIM_WIDLE   = 3;
 ANIM_CIDLE   = 4;

 ANIM_PWALK   = 5;
 ANIM_PCROUCH = 6;
 ANIM_PWIDLE  = 7;
 ANIM_PCIDLE  = 8;

const
 MAGIC   = 'TMDL';
 Version = 5;

type
 TModelSound = class
  Target   : boolean; // Следим за игроком (звуки в позиции камеры)
  Jump     : TSound;
  Death1   : TSound;
  Death2   : TSound;
  Death3   : TSound;
  Pain_25  : TSound;
  Pain_50  : TSound;
  Pain_75  : TSound;
  Pain_100 : TSound;
  Step     : TSound;
  constructor Create;
  procedure LoadFromModel(const Model: string);
  procedure Death(X, Y: single);
  procedure Pain(X, Y: single; Health: SmallInt);
 end;

 TModelAnim = record
  Body   : TObjTex;
  Mask   : TObjTex;
  Width  : Byte;
  Height : Byte;
 end;

 TModel = class
   constructor Create;
  private
   FCrouch  : boolean;
   FDied    : boolean;
   procedure SetFrame(index: integer);
   function GetFrame: integer;
   procedure SetCrouch(Value: boolean);
   procedure SetDied(Value: boolean);
  public
   FrameIdx  : Byte;
   Color, railcolor: TRGB;
   Anim      : array [0..8] of TModelAnim;
   CurAnim   : Byte;
   Step      : array [0..255] of boolean;
   Steps     : boolean;

   X, Y      : single;
   Sound     : TModelSound;
   ModelName : string;

   function LoadFromFile(const ModelName: string; simple: boolean = false): boolean;
   procedure NextFrame;           // следующий кадр
   procedure PrevFrame;           // предыдущий кадр
   function FrameCount : integer; // количество кадров в текущей анимации
   procedure Update;
   procedure Draw(PowerUP: boolean = false);
   // Пуфка!
   procedure DrawWeapon(angle   : single = 90;
                        crouch  : boolean = false;
                        weapon  : Byte = 1;
                        frame   : Byte = 0;
                        PowerUP : boolean = false;
                        d       : single = 1);
   property FrameIndex: integer read GetFrame write SetFrame;
   property Crouch : boolean read FCrouch write SetCrouch;
   property Died : boolean read FDied write SetDied;
 end;

 TSkin = record
  Name  : string;
  Color : TRGB;
 end;

const
 TransC : TRGBA = (R: 255; G: 255; B: 255; A: 0);
 Skins : array [1..8] of TSkin = (
   (Name: 'blue';   Color: (R: 0;   G: 0;   B: 255)),
   (Name: 'red';    Color: (R: 255; G: 0;   B: 0)),
   (Name: 'green';  Color: (R: 0;   G: 255; B: 0)),
   (Name: 'white';  Color: (R: 255; G: 255; B: 255)),
   (Name: 'black';  Color: (R: 128; G: 128; B: 128)),
   (Name: 'yellow'; Color: (R: 255; G: 255; B: 0)),
   (Name: 'purple'; Color: (R: 255; G: 0;   B: 255)),
   (Name: 'aqua';   Color: (R: 0;   G: 255; B: 255)));


implementation

uses
 Player_Lib, ItemObj_Lib;

/// ModelSound ///
constructor TModelSound.Create;
begin
Jump     := TSound.Create;
Death1   := TSound.Create;
Pain_25  := TSound.Create;
Pain_50  := TSound.Create;
Pain_75  := TSound.Create;
Pain_100 := TSound.Create;
Step     := TSound.Create;
end;

procedure TModelSound.LoadFromModel(const Model: string);
begin
Jump     := TSound.Create('models\' + Model + '\jump1.wav', false);
Death1   := TSound.Create('models\' + Model + '\death1.wav', false);
Death2   := TSound.Create('models\' + Model + '\death2.wav', false);
Death3   := TSound.Create('models\' + Model + '\death3.wav', false);
Pain_25  := TSound.Create('models\' + Model + '\pain25_1.wav', false);
Pain_50  := TSound.Create('models\' + Model + '\pain50_1.wav', false);
Pain_75  := TSound.Create('models\' + Model + '\pain75_1.wav', false);
Pain_100 := TSound.Create('models\' + Model + '\pain100_1.wav', false);
Step     := TSound.Create('models\' + Model + '\step.wav', false);
end;

procedure TModelSound.Death(X, Y: single);
begin
 case trunc(randomf*3) of
  0 : Death1.Play(X, Y);
  1 : Death2.Play(X, Y);
  2 : Death3.Play(X, Y);
 end;
end;

procedure TModelSound.Pain(X, Y: single; Health: SmallInt);
begin
if Health <= 25 then
 Pain_25.Play(X, Y, target)
else
 if Health <= 50 then
  Pain_50.Play(X, Y, target)
 else
  if Health <= 75 then
   Pain_75.Play(X, Y, target)
  else
   Pain_100.Play(X, Y, target);
end;

/// NFKModel ///
constructor TModel.Create;
var
 i : integer;
begin
Sound := TModelSound.Create;
for i := 0 to 6 do
 with Anim[i] do
  begin
  Body := TObjTex.Create;
  Mask := TObjTex.Create;
  Width  := 0;
  Height := 0;
  end;
CurAnim := 0;
end;

function TModel.LoadFromFile(const ModelName: string; simple: boolean = false): boolean;
var
 i    : integer;
 n, s : string;
 str  : string;
 F    : File of Byte;
 tBody : PaRGBA;
 tMask : PByteArray;
 w, h : WORD;
 m    : array [0..3] of Char;
 b    : Byte;
 FCount, FWait : Byte;
 FObj : TFrameObj;
 x, y : integer;

 procedure SmoothMask;
 var
  c     : WORD;
  idx   : integer;
  x, y  : integer;
  pMask : PByteArray;

  procedure pix(x, y: SmallInt);
  begin
  if (x > -1) and (x < integer(w)) and
     (y > -1) and (y < integer(h)) then
   inc(c, tMask[y*w + x])
  else
   dec(idx);
  end;

 begin
 GetMem(pMask, w*h);
 for y := 0 to h - 1 do
  for x := 0 to w - 1 do
   begin
   idx := 8;
   c   := 0;
   pix(x - 1, y - 1);
   pix(x - 1, y);
   pix(x - 1, y + 1);

   pix(x + 1, y - 1);
   pix(x + 1, y);
   pix(x + 1, y + 1);

   pix(x, y - 1);
   pix(x, y + 1);
   pMask[y*w + x] := c div idx;
   end;
 FreeMem(tMask);
 tMask := pMask;
 end;


begin
Result := false;

i := Pos('+', ModelName);
if i <> 0 then
 begin
 n := LowerCase(Copy(ModelName, 1, i - 1));
 s := LowerCase(Copy(ModelName, i + 1, Length(ModelName)));
 end
else
 begin
 s := 'default';
 n := LowerCase(ModelName);
 end;

if s <> 'default' then
 begin
 w := 0;
 for i := 1 to Length(Skins) do
  if s = Skins[i].Name then
   begin
   w := 1;
   break;
   end;
 if w = 0 then
  Exit;
 end;
 
 try
  if not FileExists(Engine_ModDir + 'models\' + n + '\' + n + '.tml') then
   Exit;

  if not Simple then
   Sound.LoadFromModel(n);

  FileMode := 64;
  AssignFile(F, Engine_ModDir + 'models\' + n + '\' + n + '.tml');
  Reset(F);
  BlockRead(F, m, 4);
  BlockRead(F, b, 1);
  if (m <> MAGIC) or (b <> Version) then
   begin
   CloseFile(F);
   Exit;
   end;
  BlockRead(F, Color, 3);
  for i := 0 to 4 do
   with Anim[i] do
    begin
    if Simple and (i > 0) then
     break;
    BlockRead(F, FCount, 1);
    BlockRead(F, FWait, 1);
    BlockRead(F, w, 2);
    BlockRead(F, h, 2);
    if not ((w = 0) or (h = 0)) then
     begin
     GetMem(tBody, w*h*4);
     GetMem(tMask, w*h);
     BlockRead(F, tBody[0], w*h*4);
     BlockRead(F, tMask[0], w*h);
     str := n + ' ' + IntToStr(i) + ' * body';
     FObj := TexExists(str);
     if FObj <> nil then
      begin
      FObj.flag  := true;
      Body.Tex   := FObj;
      Body.FWait := FWait + 1;
      end
     else
      Body := TObjTex.Create(str, w, h, FWait + 1, true, false, nil, 0, tBody, 32, FCount);

     str := n + ' ' + IntToStr(i) + ' * mask';
     FObj := TexExists(str);
     if FObj <> nil then
      begin
      FObj.flag  := true;
      Mask.Tex   := FObj;
      Mask.FWait := FWait;
      end
     else
      Mask := TObjTex.Create(str, w, h, FWait + 1, true, false, nil, 0, tMask, 8, FCount);

     if not Simple then
      if i in [ANIM_WALK, ANIM_CROUCH] then
       begin                                  
       for y := 0 to h - 1 do
        for x := 0 to w - 1 do
         tMask[y*w + x] := tBody[y*w + x].A;
       SmoothMask;
       if i = ANIM_WALK then
        str := n + ' ' + IntToStr(i) + ' * pwalk'
       else
        str := n + ' ' + IntToStr(i) + ' * pcrouch';
       FObj := TexExists(str);
       if FObj <> nil then
        begin
        FObj.flag  := true;
        Anim[i + 3].Mask.Tex   := FObj;
        Anim[i + 3].Mask.FWait := 0;
        end
       else
        Anim[i + 3].Mask := TObjTex.Create(str, w, h, 0, true, false, nil, 0, tMask, 8, FCount);
       end;


     Width  := w div FCount;
     Height := h;

     FreeMem(tBody);
     FreeMem(tMask);
     end;
    end;

  BlockRead(F, Step[0], Anim[ANIM_WALK].Body.FrameCount);
  CloseFile(F);
  Result := true;
 except
 log('a');
 end;

if s <> 'default' then
 for i := 1 to Length(Skins) do
  if s = Skins[i].Name then
   begin
   Color := Skins[i].Color;
   Exit;
   end;
end;

procedure TModel.NextFrame;
begin
FrameIndex := FrameIndex + 1;
end;

procedure TModel.PrevFrame;
begin
FrameIndex := FrameIndex - 1;
end;

function TModel.FrameCount: integer;
begin
Result := Anim[CurAnim].Body.FrameCount
end;

procedure TModel.Update;
begin
if Died then
 CurAnim := ANIM_DIED
else
 if Crouch then
  CurAnim := ANIM_CROUCH
 else
  CurAnim := ANIM_WALK;

if Anim[CurAnim].Body.Wait > 0 then
 dec(Anim[CurAnim].Body.Wait);

Anim[CurAnim].Body.FrameIndex := FrameIdx;
Anim[CurAnim].Mask.FrameIndex := FrameIdx;
end;

procedure TModel.Draw(PowerUP: boolean = false);
const
 ls = 48;
var
 wx, wy, yy : single;
 tx, ty : single;
 w, h   : integer;
 Frame  : PTexData;

 procedure DrawBox;
 begin
 glBegin(GL_QUADS);
  glTexCoord2f(0,  ty); glVertex2f(-wx, - wy + 24 - yy);
  glTexCoord2f(tx, ty); glVertex2f( wx, - wy + 24 - yy);
  glTexCoord2f(tx,  0); glVertex2f( wx, 24 + yy);
  glTexCoord2f(0,   0); glVertex2f(-wx, 24 + yy);
 glEnd;
 end;

var
 c : array [0..3] of single;
begin
glGetFloatv(GL_CURRENT_COLOR, @c);
yy := 0;
with Anim[CurAnim] do
 begin
 wx    := Width/2; // Размеры фрейма
 wy    := Height;
 Anim[CurAnim].Body.FrameIndex := FrameIdx;
 Anim[CurAnim].Mask.FrameIndex := FrameIdx;
 Frame := Anim[CurAnim].Body.CurFrame;
 end;

if Frame <> nil then
 begin
 xglTex_Enable(Frame);
 W := Frame^.Width;  // Размеры текстуры фрейма
 H := Frame^.Height;
 end
else
 begin
 xglTex_Disable;
 W := 64;
 H := 64;
 end;

tx := (wx + wx - 1)/W;
ty := (wy - 1)/H;
xglAlphaBlend(1);
if PowerUp then
 glColor4f(1, 1, 1, 1)
else
 glColor4f(1, 1, 1, c[3]);
DrawBox;
Frame := Anim[CurAnim].Mask.CurFrame;
xglTex_Enable(Frame);
if PowerUp then
 glColor4ub(Color.R, Color.G, Color.B, 255)
else
 glColor4ub(Color.R, Color.G, Color.B, trunc(c[3] * 255)); // альфа для инвиз игроков
DrawBox;

if PowerUP then
 begin
 xglTex_Disable;
 Anim[CurAnim + 3].Mask.FrameIndex := FrameIdx;
 xglTex_Enable(Anim[CurAnim + 3].Mask.CurFrame);

 xglAlphaBlend(2);
// wx := wx + wx*0.1;
// yy := 24*0.1;
 glColor4fv(@c);
 DrawBox;
 xglTex_Enable(@light_1);
 glBegin(GL_QUADS);
  glTexCoord2f(0, 0); glVertex2f(-ls, -ls);
  glTexCoord2f(1, 0); glVertex2f( ls, -ls);
  glTexCoord2f(1, 1); glVertex2f( ls,  ls);
  glTexCoord2f(0, 1); glVertex2f(-ls,  ls);
 glEnd;
 xglAlphaBlend(1);
 end;
end;

procedure TModel.DrawWeapon(angle: single; crouch: boolean; weapon: Byte; frame: Byte; PowerUP: boolean; d: single);
var
 c : array [0..3] of single;

 procedure DrawBox;
 begin
 glBegin(GL_QUADS);
  glTexCoord2f(0, 1); glVertex2f(-6, -8);
  glTexCoord2f(1, 1); glVertex2f(26, -8);
  glTexCoord2f(1, 0); glVertex2f(26,  8);
  glTexCoord2f(0, 0); glVertex2f(-6,  8);
 glEnd;
 end;

begin
if weapon = WPN_RAILGUN then frame := 0;
glGetFloatv(GL_CURRENT_COLOR, @c);
if WeaponExists(weapon) then
 with WeaponObjs[weapon] do
  xglTex_Enable(FIREanim[frame])
else
 xglTex_Disable; // Exit не пишу, т.к. белый квадрат лучше чем совсем ничего

if trunc(angle) > 180 then
 angle := trunc(angle) mod 180 - 90
else
 angle := trunc(angle) - 90;

glTranslatef(0, GetShotY(crouch), 0);

glRotatef(angle, 0, 0, 1);
xglAlphaBlend(1);
if PowerUp then
 glColor4f(1, 1, 1, 1)
else
 glColor4f(1, 1, 1, c[3]); // альфа для инвиз игроков
DrawBox;

if weapon = WPN_RAILGUN then
 begin
 if WeaponExists(weapon) then
  with WeaponObjs[weapon] do
   xglTex_Enable(FIREanim[1])
 else
  xglTex_Disable; // Exit не пишу, т.к. белый квадрат лучше чем совсем ничего
 glColor4f(railcolor.r/255 * (1 - d) + d,
           railcolor.g/255 * (1 - d) + d,
           railcolor.b/255 * (1 - d) + d, c[3]);
 DrawBox;
 end;
glColor4fv(@c);
// Отрисовка PowerUP наложения
if PowerUP then
 begin
 xglAlphaBlend(2);
 glColor4fv(@c);
 if WeaponExists(weapon) then
  with WeaponObjs[weapon] do
   xglTex_Enable(Mask[frame]);
 DrawBox;
 xglAlphaBlend(1);
 end;
end;

procedure TModel.SetFrame(index: integer);
var
 FFrame : integer;
begin
with Anim[CurAnim].Body do
 begin
 if Wait > 0 then Exit;

 FFrame := index;
 if FFrame > FrameCount - 1 then
  if CurAnim = ANIM_DIED then
   FFrame := FrameCount - 1
  else
   FFrame := 1;

 if CurAnim <> ANIM_DIED then
  if FFrame < 1 then
   FFrame := FrameCount - 1;

 if CurAnim = ANIM_WALK then
  if Steps and Step[FFrame] and cg_steps then
   Sound.Step.Play(X, Y);
 Wait := FWait;

 FrameIdx := FFrame;
 end;
end;

function TModel.GetFrame: integer;
begin
Result := FrameIdx;
end;

procedure TModel.SetCrouch(Value: boolean);
begin
if FCrouch <> Value then
 with Anim[CurAnim] do
  begin
  FCrouch  := Value;
  FrameIdx := 0;
  end;
end;

procedure TModel.SetDied(Value: boolean);
begin
FDied := Value;
Crouch := false;
end;

end.
