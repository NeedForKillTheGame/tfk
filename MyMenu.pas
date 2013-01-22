unit MyMenu;

interface
//окна и дочерние объекты

uses
 Windows, Messages, SysUtils, OpenGL,
 Engine_Reg,
 Graph_Lib,
 Math_Lib,
 ObjAnim_Lib,
 Str_Lib,
 Func_Lib,
 Type_Lib,
 Model_Lib,
 Weapon_Lib;

const
 ID_NONE = 1024;

type
 THAlign = (ahLeft, ahRight, ahCenter, ahNone);
 TVAlign = (avTop, avBottom, avCenter, avNone);

 TMessage = record
  Msg    : DWORD;
  wParam : LongInt;
  lParam : LongInt;
 end;

 TMyWindow = class;

 TMyControl = class
   constructor Create(Proc: pointer; ID: integer);
  protected
   FProc   : procedure (ID: integer; Param : integer);
   FID     : integer;
   FRect   : TRect;
   FActive : boolean;
   FAlpha  : Byte;
   FAinc   : ShortInt;
   FWindow : TMyWindow;
   procedure SetActive(b: boolean); virtual;
  public
   HAlign  : THAlign;
   VAlign  : TVAlign;
   Enabled : boolean;
   procedure SetProc(Proc: pointer; ID: integer);
   procedure onMessage(var Msg: TMessage); virtual;
   procedure Update; virtual;
   procedure Draw; virtual;
   property ID     : integer read FID;
   property X      : SmallInt read FRect.X write FRect.X;
   property Y      : SmallInt read FRect.Y write FRect.Y;
   property Width  : WORD read FRect.Width write FRect.Width;
   property Height : WORD read FRect.Height write FRect.Height;
   property Rect   : TRect read FRect;
   property Active : boolean read FActive write SetActive;
 end;

 TMyWindow = class
   constructor Create;
   destructor Destroy;override;
  private
   function GetChilds(index: integer): TMyControl;
   function GetChildCount: integer;
  protected
   FChilds : array of TMyControl;
   FChildLock: TMyControl;
  public
   prevwindow : TMyWindow;
   def_x, def_y, def_cx, def_cy: integer;

   property ChildCount: integer read GetChildCount;
   property Childs[index: integer]: TMyControl read GetChilds;

   function AddChild(Child: TMyControl): TMyControl;
   function ActiveChild : integer;
   procedure onMessage(var Msg: TMessage);
   procedure Update;
   procedure Draw;

   procedure Show;virtual;

   procedure Lock(Child: TMyControl);
   procedure Unlock;
   function Locked: boolean;
 end;

///// Other objects /////
(*= TButton =*)
 TButton = class(TMyControl)
   constructor Create(Proc: pointer; ID: integer; const TexName: string);
   destructor Destroy; override;
  private
   Tex    : TTexData;
  public
   procedure onMessage(var Msg: TMessage); override;
   procedure Update; override;
   procedure Draw; override;
 end;

 TTexLabel = class(TButton)
   constructor Create(Proc: pointer; ID: integer; const TexName: string);
  public
   procedure Draw; override;
   procedure Update; override;
  end;

(*= TGraphButton =*)
 TGraphButton = class(TMyControl)
   constructor Create(Proc: pointer; ID: integer; const TexName: string);
   destructor Destroy; override;
  private
   Tex    : TObjTex;
  public
   procedure onMessage(var Msg: TMessage); override;
   procedure Update; override;
   procedure Draw; override;
 end;

(*= TModel3D =*)
 TM3DHeader = record
  Name      : array [0..3] of Char;
  Faces     : WORD;
  Vertices  : WORD;
 end;

 TM3DVertex = record
  X, Y, Z : single;
 end;

 TModel3D = class(TMyControl)
   constructor Create(Proc: pointer; ID: integer; const FileName: string);
   destructor Destroy; override;
  private
   Angle    : single;
   toffset  : single;
   Tex      : TTexData;
   Header   : TM3DHeader;
   Face     : array of array [0..2] of WORD;
   Vertex   : array of TM3DVertex;
   VNormal  : array of TM3DVertex;  // Vertex Normal
  public
   procedure Clear;
   procedure onMessage(var Msg: TMessage); override;
   procedure Update; override;
   procedure Draw; override;
 end;

(*= TCustomEdit =*)
 TCustomEdit = class(TMyControl)
 private
   FMaxLength : integer;
   fTab       : integer;
   fText      : string;
   FCaption	  : string;
   procedure SetTab(Value: integer);
   procedure SetMaxLength(Value : integer);virtual;
   procedure SetText(Text: string);virtual;
 public
   procedure Update; override;
   procedure Draw; override;
   property MaxLength : integer read FMaxLength write SetMaxLength;
   property Tab: integer read fTab write SetTab;
   property Text : string read FText write SetText;
 end;

(*= TEdit =*)
 TEdit = class(TCustomEdit)
   constructor Create(Proc: pointer; ID: integer; variable: pointer;
   	 const Caption, CMDStr: string; vartype: TVarType);
  private
   FCaretPos    : integer;
   FCaretTicker : integer;
   FCMDStr		 : string;
   fVar: pointer;
   FvarType: TVarType;
   procedure SetCaretPos(Pos : integer);
   procedure SetText(Text: string);override;
   procedure SetMaxLength(Len: integer);override;
   function GetVar: string;
  protected
   procedure SetActive(b: boolean); override;
  public
 // FActive : boolean;
   OverWrite: boolean;
   procedure onMessage(var Msg: TMessage); override;
   procedure Update; override;
   procedure Draw; override;
   property CaretPos : integer read FCaretPos write SetCaretPos;
 end;

(*= TListBox =*)
 TListBox = class(TMyControl)
   constructor Create(Proc: pointer; ID: integer);
  private
   FAlpha   : single;
   MDrag    : boolean;
   FIndex   : integer;
   FScroll  : integer;
   procedure SetIndex(i: integer);
  public
   Items: TStringCells;
   procedure SetSize(cols, rows: integer);
   procedure onMessage(var Msg: TMessage); override;
   procedure Update; override;
   procedure Draw; override;
   procedure DrawBG;
   procedure DrawSelection;
   property Index: integer read FIndex write SetIndex;
 end;

(*= TListBox =*)
 TFileListBox = class(TListBox)
  private
   DBtick : DWORD;
   FDir   : string;
   procedure SetDir(NewDir: string);
  public
   Ext      : string;
   StartDir : string;
   procedure onMessage(var Msg: TMessage); override;
   procedure Draw; override;
   property Dir: string read FDir write SetDir;
 end;

 TBindEdit = class(TCustomEdit)
   constructor Create(Proc: pointer; ID: integer; pl_ind: integer; key_ind: integer);
 private
   f_pl     : integer;
   f_key    : integer;
   f_input  : boolean;
   enterkey : integer;
   function GetText: string;
 public
   procedure onMessage(var Msg: TMessage); override;
   procedure Draw; override;
   procedure Update; override;
 end;

 TLabel = class(TCustomEdit)
 	constructor Create(Proc: pointer; ID: integer; const Text: string);
 public
   procedure onMessage(var Msg: TMessage); override;
   procedure Draw;override;
 end;

 TYesNoEdit = class(TCustomEdit)
 	constructor Create(Proc: pointer; ID: integer; variable: PByte;
   	const Caption, CMDStr: string);
 private
   fVar: PByte;
   fCMDStr: string;
   function GetText: string;
 public
   str_No: string;
   str_Yes: string;
   procedure onMessage(var Msg: TMessage); override;
   procedure Draw;override;
 end;

 TEnumEdit = class(TCustomEdit)
 	constructor Create(Proc: pointer; ID: integer; variable: PByte;
   count: byte; const varval: array of byte; const varstr: array of string;
         const comval: array of string;
   	const Caption, CMDStr: string);
 private
   fVar: PByte;
   fCMDStr: string;
   fValCount: integer;
   fValues: array [1..20] of byte;
   fValuesStr: array [1..20] of string;
   fComValues: array [1..20] of string;
   function GetText: string;
   function GetVal: byte;
 public
   procedure onMessage(var Msg: TMessage); override;
   procedure Draw;override;
 end;

 TEnumStrEdit = class(TCustomEdit)
  	constructor Create(const Caption : string;
                       variable      : PByte;
                       const varstr  : array of string);
  private
   fVar       : PByte;
   fValuesStr : array of string;
 public
   procedure onMessage(var Msg: TMessage); override;
   procedure Draw;override;
 end;

 TModelViewer = class(TMyControl)
   constructor Create;
  private
   Model : TModel;
   weapon: TObjTex;
  public
   Name : string;
   procedure SetModel(const ModelName: string);
   procedure Update; override;
   procedure Draw; override;
 end;

 TLevelShot = class(TMyControl)
   constructor Create(X, Y: SmallInt);
  public
   Tex     : TTexData;
   TexName : string;
   procedure LoadShot(const MapName: string);
   procedure Draw; override;
 end;

var
 MyWindows    : array of TMyWindow;
 ActiveWindow : TMyWindow;

 MousePos     : TPoint;
 MenuSnd_1    : integer;
 MenuSnd_2    : integer;
 MenuSnd_3    : integer;

function WindowCount: integer;
function AddWindow(w: TMyWindow): TMyWindow;

procedure Menu_InitSound;
procedure InitWindows;
procedure DestroyWindows;

implementation

uses
 TFK, Binds_Lib, Constants_Lib;

procedure Menu_InitSound;
begin
MenuSnd_1 := snd_Load('sound\menu\menu1.wav');
MenuSnd_2 := snd_Load('sound\menu\menu2.wav');
MenuSnd_3 := snd_Load('sound\menu\menu3.wav');
end;

// инициализация, подгрузка звуков и текстур
procedure InitWindows;
begin
Menu_InitSound;
end;

procedure DestroyWindows;
var
 i : integer;
begin
for i := 0 to WindowCount - 1 do
 MyWindows[i].Free;
MyWindows := nil;
ActiveWindow := nil;
end;

function WindowCount: integer;
begin
Result := Length(MyWindows);
end;

function AddWindow(w: TMyWindow): TMyWindow;
begin
SetLength(MyWindows, WindowCount + 1);
MyWindows[High(MyWindows)] := w;
Result := w;
end;

{ TMyWindow }
constructor TMyWindow.Create;
begin
FChilds 		:= nil;
FChildLock	:=	nil;
def_x:=0;def_y:=0;def_cx:=0;def_cy:=0;
end;

destructor TMyWindow.Destroy;
var
 i : integer;
begin
for i := 0 to GetChildCount - 1 do
 FChilds[i].Free;
end;

function TMyWindow.GetChildCount: integer;
begin
Result := Length(FChilds);
end;

function TMyWindow.GetChilds(index: integer): TMyControl;
begin
if (index > -1) and (index < GetChildCount) then
 Result := FChilds[index]
else
 Result := nil;
end;

function TMyWindow.AddChild(Child: TMyControl): TMyControl;
begin
Child.FWindow:=Self;
if (not (Child is TTexLabel)) and
   (not (Child is TLevelShot)) then
begin
	Child.X:=def_x;Child.Y:=def_y;
	def_x:=def_x+def_cx; def_y:=def_y+def_cy;
end;
SetLength(FChilds, GetChildCount + 1);
FChilds[High(FChilds)] := Child;
Result := Child;
end;

function TMyWindow.ActiveChild : integer;
var
 i : integer;
begin
Result := -1;
for i := 0 to ChildCount - 1 do
 if Childs[i].Active then
  begin
  Result := i;
  break;
  end;
end;

procedure TMyWindow.Update;
var
 i : integer;
begin
for i := 0 to ChildCount - 1 do
 if FChilds[i] <> nil then
  FChilds[i].Update;
end;

procedure TMyWindow.Draw;
var
 i : integer;
begin
for i := 0 to ChildCount - 1 do
 if FChilds[i] <> nil then
  FChilds[i].Draw;
end;

procedure TMyWindow.onMessage(var Msg: TMessage);
var
 i, k : integer;
begin
if Locked then
begin
   FChildLock.onMessage(Msg);
   Exit;
end;

for i := 0 to ChildCount - 1 do
 if FChilds[i] <> nil then
  FChilds[i].onMessage(Msg);

with Msg do
 case Msg of
  WM_KEYDOWN :
   case wParam of
    { XProger: не знаю чем это обернётся и не помню зачем это
     сделал, но глюк с переходами в TFileListBox исправляет
    VK_RETURN :
     if ChildCount > 0 then
      begin
      i := ActiveChild;
      if i > -1 then
       Childs[i].Active := false;
      Exit;
      end;
     }
    VK_UP, VK_DOWN, VK_TAB :
     if ChildCount > 0 then
      begin
      k := 0;
      i := ActiveChild;
      if i < 0 then i := 0;
      Childs[i].Active := false;
      while true do
       begin
       if wParam = VK_UP then dec(i);
       if wParam in [VK_DOWN, VK_TAB] then inc(i);
       if i < 0 then i := ChildCount - 1;
       if i = ChildCount then i := 0;
       inc(k);
       if ChildCount = k then break;
       if Childs[i].Enabled then
        begin
        if not Childs[i].FActive then
           if sound_off=0 then
         		snd_Play(MenuSnd_2, false, 0, 0, true);
        Childs[i].Active := true;
        break;
        end;
       end;
      end;
   end; //case wParam of
 end; //case Msg of
end;

procedure TMyWindow.Lock(Child: TMyControl);
begin
   FChildLock:=Child;
end;

procedure TMyWindow.Unlock;
begin
   FChildLock:=nil;
end;

function TMyWindow.Locked: boolean;
begin
   Result:=FChildLock<>nil;
end;

procedure TMyWindow.Show;
var
   i: integer;
begin
   for i:=0 to ChildCount-1 do
      Childs[i].SetActive(false);
   UnLock;
end;

{ TMyControl }
constructor TMyControl.Create(Proc: pointer; ID: integer);
begin
FRect.X := 0;
FRect.Y := 0;
FRect.Width := 16;
FRect.Height := 16;

HAlign := ahNone;
VAlign := avNone;
SetProc(Proc, ID);

FAlpha  := 255;
FAinc   := 15;
Enabled := true;
end;

procedure TMyControl.SetProc(Proc: pointer; ID: integer);
begin
FProc := Proc;
FID   := ID;
end;

procedure TMyControl.onMessage(var Msg: TMessage);
var
 i : integer;
begin
if not Enabled then Exit;
// По умолчанию процедура работает по типу кнопки
 case Msg.Msg of
  WM_MOUSEMOVE : // Мыша над кнопкой
   if (FID > 0) and PointInRect(MousePos.X, MousePos.Y, FRect) then
    if not Active then
     begin
     if sound_off=0 then
      snd_Play(MenuSnd_2, false, 0, 0, true);
     Active := true;
     if ActiveWindow <> nil then
      with ActiveWindow do
       for i := 0 to ChildCount - 1 do
       if Childs[i] <> self then
         Childs[i].Active := false;
     end;
 end;
end;

procedure TMyControl.SetActive(b: boolean);
begin
FActive := b;
end;

procedure TMyControl.Update;
const
 Step = 20;
begin
 case HAlign of
  ahLeft   : FRect.X := Step;
  ahRight  : FRect.X := 640 - FRect.Width - Step;
  ahCenter : FRect.X := (640 - FRect.Width) div 2;
 end;

 case VAlign of
  avTop    : FRect.Y := Step;
  avBottom : FRect.Y := 480 - FRect.Height - Step;
  avCenter : FRect.Y := (480 - FRect.Height) div 2;
 end;
end;

procedure TMyControl.Draw;
begin
glBegin(GL_QUADS);
 glTexCoord2f(0, 1); glVertex2f(FRect.X, FRect.Y);
 glTexCoord2f(1, 1); glVertex2f(FRect.X + FRect.Width, FRect.Y);
 glTexCoord2f(1, 0); glVertex2f(FRect.X + FRect.Width, FRect.Y + FRect.Height);
 glTexCoord2f(0, 0); glVertex2f(FRect.X, FRect.Y + FRect.Height);
glEnd;
end;

//////////////////////////////////////////////////////
//// TCL - TFK Component Library :) ///////////////////
//////////////////////////////////////////////////////

(**** TButton ****)
constructor TButton.Create(Proc: pointer; ID: integer; const TexName: string);
begin
inherited Create(Proc, ID);
Tex.Filter := false;
Tex.Trans  := false;
Tex.Clamp  := true;
Tex.Scale  := true;
Tex.MipMap := false;
xglTex_Load(PChar('textures\menu\' + TexName), @Tex);

FRect.Width := Tex.Width;
FRect.Height := Tex.Height;
if FRect.Width < 16 then FRect.Width := 16;
if FRect.Height < 16 then FRect.Height := 16;
FAlpha := 150;
HAlign := ahCenter;
Update;
end;

destructor TButton.Destroy;
begin
xglTex_Free(@Tex);
end;

procedure TButton.onMessage(var Msg: TMessage);
begin
if not Enabled then Exit;
inherited;
if not FActive then Exit;
if (Msg.Msg = WM_LBUTTONDOWN) or ((Msg.Msg = WM_KEYDOWN) and (Msg.wParam = VK_RETURN)) then
 if @FProc <> nil then
  FProc(FID, 0);
end;

procedure TButton.Update;
begin
inherited;
if not Enabled then
 begin
 FAlpha := 150;
 Exit;
 end;

if FActive then
 begin
 if FAlpha < 255 then
  inc(FAlpha, 15);
 end
else
 if FAlpha > 150 then
  dec(FAlpha, 15);
end;

procedure TButton.Draw;
begin
xglTex_Disable;
xglAlphaBlend(1);
if Enabled then
 glColor4ub(255, 255, 255, FAlpha)
else
 glColor4ub(127, 127, 127, 255);
xglTex_Enable(@Tex);
inherited;
end;

(**** TGraphButton ****)
constructor TGraphButton.Create(Proc: pointer; ID: integer; const TexName: string);
begin
inherited Create(Proc, ID);
Tex := TObjTex.Create('textures\menu\' + TexName, 2, 0, 0, true, true, nil, OWNER_MENU);

if (Tex <> nil) and (Tex.FrameCount > 0) then
 begin
 FRect.Width  := Tex.Frame[0].Width;
 FRect.Height := Tex.Frame[0].Height;
 end;

FAlpha := 0;
VAlign := avBottom;
HAlign := ahNone;
Update;
end;

destructor TGraphButton.Destroy;
begin
Tex.Free;
end;

procedure TGraphButton.onMessage(var Msg: TMessage);
begin
if not Enabled then Exit;
inherited;
if not FActive then Exit;
if (Msg.Msg = WM_LBUTTONDOWN) or ((Msg.Msg = WM_KEYDOWN) and (Msg.wParam = VK_RETURN)) then
 if @FProc <> nil then
  FProc(FID, 0);
end;                

procedure TGraphButton.Update;
begin
inherited;
if not Enabled then
 begin
 FAlpha := 0;
 Exit;
 end;

if FActive then
 begin
 if FAlpha < 255 then
  inc(FAlpha, 15);
 end
else
 if FAlpha > 0 then
  dec(FAlpha, 15);
end;

procedure TGraphButton.Draw;
begin
xglTex_Disable;
xglAlphaBlend(1);
if Enabled then
 glColor4ub(255, 255, 255, 255)
else
 glColor4ub(127, 127, 127, 255);
if FAlpha < 255 then
 begin
 if (Tex <> nil) and (Tex.FrameCount > 0) then
  xglTex_Enable(Tex.Frame[0]);
 inherited;
 end;
if not Enabled then Exit;
glColor4ub(255, 255, 255, FAlpha);
if FAlpha > 0 then
 begin
 if (Tex <> nil) and (Tex.FrameCount > 1) then
  xglTex_Enable(Tex.Frame[1]);
 inherited;
 end;
end;

(**** TModel3D ****)
constructor TModel3D.Create(Proc: pointer; ID: integer; const FileName: string);
var
 F          : File of Byte;
 i, j       : integer;
 d          : single;
 v1, v2, v3 : TM3DVertex;
 w1, w2     : TM3DVertex;
 FNormal    : array of TM3DVertex;  // Face Normal

 function ModelName: string;
 var
  i : integer;
 begin
 for i := Length(FileName)  downto 1 do
  if FileName[i] = '\' then
   begin
   Result := Copy(FileName, i + 1, Length(FileName));
   Exit;
   end;
 Result := FileName;
 end;

begin
Clear;
 try
  FileMode := 64;
  AssignFile(F, Engine_ModDir + FileName + '.t3d');
  Reset(F);
  BlockRead(F, Header, SizeOf(Header));
  if Header.Name <> 'TM3D' then
   begin
   CloseFile(F);
   Clear;
   Exit;
   end;
  SetLength(Face, Header.Faces);
  SetLength(Vertex, Header.Vertices);

  BlockRead(F, Face[0], SizeOf(WORD) * 3 * Header.Faces);
  BlockRead(F, Vertex[0], SizeOf(TM3DVertex) * Header.Vertices);
  CloseFile(F);

  SetLength(FNormal, Header.Faces);
  SetLength(VNormal, Header.Vertices);
  FillChar(VNormal[0], Header.Vertices * 12, 0);
  // Calc face normals
  for i := 0 to Header.Faces - 1 do
   with FNormal[i] do
    begin
    v1 := Vertex[Face[i, 0]];
    v2 := Vertex[Face[i, 1]];
    v3 := Vertex[Face[i, 2]];

    w1.X := v2.X - v1.X;
    w1.Y := v2.Y - v1.Y;
    w1.Z := v2.Z - v1.Z;

    w2.X := v3.X - v2.X;
    w2.Y := v3.Y - v2.Y;
    w2.Z := v3.Z - v2.Z;

    X := w2.Y * w1.Z - w2.Z * w1.Y;
    Y := w2.Z * w1.X - w2.X * w1.Z;
    Z := w2.X * w1.Y - w2.Y * w1.X;

    for j := 0 to 2 do
     with VNormal[Face[i, j]] do
      begin
      X := X + FNormal[i].X;
      Y := Y + FNormal[i].Y;
      Z := Z + FNormal[i].Z;
      end;
    end;

  // Calc smooth normals
  for i := 0 to Header.Vertices - 1 do
   with VNormal[i] do
    begin
    d := sqrt(X*X + Y*Y + Z*Z);
    if d > 0 then
     begin
     X := X/d;
     Y := Y/d;
     Z := Z/d;
     end;
    end;

  Tex.Filter := true;
  Tex.Scale  := false;
  Tex.MipMap := true;
  Tex.Trans  := false;
  Tex.Clamp  := false;
  xglTex_Load(PChar(FileName), @Tex);
  FNormal := nil;
 except
  Clear;
 end;
Enabled := false;
end;

destructor TModel3D.Destroy;
begin
inherited;
Clear;
end;

procedure TModel3D.Clear;
begin
Header.Name     := '';
Header.Faces    := 0;
Header.Vertices := 0;

Face    := nil;
Vertex  := nil;
VNormal := nil;
xglTex_Free(@Tex);
end;

procedure TModel3D.onMessage(var Msg: TMessage);
begin
end;

procedure TModel3D.Update;
begin
Angle := Angle + 1;
toffset := toffset - 0.01;
if Angle > 360 then
 Angle := Angle - 360;
end;

procedure TModel3D.Draw;
var
 i : integer;
begin
// Проекция
xglViewPort(0, 0, xglWidth, xglHeight, true);
glDisable(GL_LIGHTING);

glPushMatrix;
 glTranslatef(0, 300, -500);
 glRotatef(20, 1, 0, 0);
 glRotatef(90, 0, 1, 0);
 glRotatef(Angle, 0, 1, 0);

 glColor4f(1, 1, 1, 1);
 xglTex_Enable(@Tex);
 glEnable(GL_TEXTURE_GEN_S);
 glEnable(GL_TEXTURE_GEN_T);
 glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
 glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);

 glMatrixMode(GL_TEXTURE);
 glPushMatrix;
 glTranslatef(0, toffset, 0);
 glMatrixMode(GL_MODELVIEW);

 glBegin(GL_TRIANGLES);
  for i := 0 to Header.Faces - 1 do
   begin
   glNormal3fv(@VNormal[Face[i, 0]]);
   glVertex3fv(@Vertex[Face[i, 0]]);

   glNormal3fv(@VNormal[Face[i, 1]]);
   glVertex3fv(@Vertex[Face[i, 1]]);

   glNormal3fv(@VNormal[Face[i, 2]]);
   glVertex3fv(@Vertex[Face[i, 2]]);
   end;
 glEnd;

 glMatrixMode(GL_TEXTURE);
 glPopMatrix;
 glMatrixMode(GL_MODELVIEW);

 glDisable(GL_TEXTURE_GEN_S);
 glDisable(GL_TEXTURE_GEN_T);
glPopMatrix;

// Возвращаем вьюпорт не место...
glViewport(0, 0, xglWidth, xglHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
gluOrtho2D(0, 640, 480, 0);
glMatrixMode(GL_MODELVIEW);						
glLoadIdentity;
end;

(**** TEdit ****)
constructor TEdit.Create(Proc: pointer; ID: integer; variable: pointer;
   	 const Caption, CMDStr: string; vartype: TVarType);
begin
inherited Create(Proc, ID);
fVar			 := variable;
fVarType		 := vartype;
fText			 := GetVar;
FCMDStr		 := CMDStr;
FCaption		 := Caption;

if fVarType=VT_STRING then
	MaxLength   := 16
else MaxLength	:=	3;
FAlpha       := 255;
FAinc        := 15;
FCaretTicker := 0;
Tab:=20;

FRect.X := 0;
FRect.Y := 0;
FRect.Height := 16;
Update;
end;

procedure TEdit.SetActive(b: boolean);
begin
if not FActive then
begin
   if (fvar<>nil) then
   	fText:=GetVar
end
else
 	if FActive and (GetVar <> FText) then
 	begin
  		if @FProc <> nil then
   		FProc(FID, integer(PChar(FText)));
      if fCMDStr<>'' then
      begin
			Log_Conwrite(false);
      	Console_CMD(fCMDStr+' '+FText);
			Log_Conwrite(true);
   		fText:=GetVar;
      end;
 	end;
inherited;
end;

procedure TEdit.SetCaretPos(Pos : integer);
begin
if Pos < 0 then Pos := 0;
if Pos > Length(FText) then Pos := Length(FText);
if OverWrite and
	(Pos = Length(FText)) then Pos := Length(FText)-1;
FCaretPos := Pos;
end;

procedure TEdit.SetText(Text: string);
begin
FText := Text;
if Length(Text) > FMaxLength then
 SetLength(Text, FMaxLength);
FCaretPos := 0;
end;

procedure TEdit.SetMaxLength(Len: integer);
begin
inherited;
if Length(FText) > FMaxLength then
 FText := Copy(FText, 1, FMaxLength);
OverWrite := FMaxLength = 1;
end;

function TEdit.GetVar: string;
begin
if fvar <> nil then
 case fVarType of
  VT_SHORTINT : Result := IntToStr(Shortint(fVar^));
  VT_SMALLINT : Result := IntToStr(Smallint(fVar^));
  VT_INTEGER  : Result := IntToStr(integer(fVar^));
  VT_BYTE     : Result := IntToStr(byte(fVar^));
  VT_WORD     : Result := IntToStr(word(fVar^));
  VT_DWORD    : Result := IntToStr(dword(fVar^));
  VT_STRING   : Result := ShortString(fVar^);
 else
  Result := '';
 end;
end;

procedure TEdit.onMessage(var Msg: TMessage);
var
 i : integer;
 s : string;
begin
if not Enabled then Exit;
inherited;
if not FActive then Exit;

with Msg do
 case Msg of
  WM_CHAR : // Мыша над кнопкой
   if char(wParam) <> '`' then
    if (wParam in [32..255]) and (FvarType = VT_STRING) or
    	 (chr(wParam) in ['0'..'9', '-'])	then
     if OverWrite then
      begin
      if (CaretPos>=Length(fText)) then
       begin
       if Length(FText) < MaxLength then
       	fText:=fText+chr(wParam);
       end
      else
       fText[CaretPos+1]:=chr(wParam);
    	CaretPos := CaretPos + 1;
      end
     else
      if Length(Text) < MaxLength then
       begin
       Insert(chr(wParam), FText, FCaretPos + 1);
       CaretPos := CaretPos + 1;
       end;

  WM_KEYDOWN :
   case wParam of
    VK_BACK :
     begin
     Delete(FText, FCaretPos, 1);
     CaretPos := CaretPos - 1;
     end;

    VK_DELETE :
     Delete(FText, FCaretPos + 1, 1);

    VK_END :
     CaretPos := Length(FText);

    VK_HOME :
     CaretPos := 0;

    VK_LEFT :
     CaretPos := CaretPos - 1;

    VK_RIGHT :
     CaretPos := CaretPos + 1;

    ord('V'), VK_CONTROL, VK_INSERT, VK_SHIFT:
     if (Input_KeyDown(ord('V')) and Input_KeyDown(VK_CONTROL)) or
        (Input_KeyDown(VK_INSERT) and Input_KeyDown(VK_SHIFT)) then
      begin
      s := Clipboard_GetText;
      i := MaxLength - Length(FText);
      s := Copy(s, 1, i);
      if i > 0 then
       begin
       Insert(s, FText, FCaretPos + 1);
       CaretPos := CaretPos + i;
       end;
      end;
   end;
 end;
end;

procedure TEdit.Update;
begin
inherited;
inc(FCaretTicker);
end;

procedure TEdit.Draw;
begin
if not FActive then
 begin
 if Enabled then
  glColor4f(1, 1, 1, 255)
 else
  glColor4ub(127, 127, 127, 255);
 Text_TagOut(FRect.X, FRect.Y, nil, true, PChar(fCaption));
 Text_TagOut(FRect.X+fTab*8, FRect.Y, nil, true, PChar(Text))
 end
else
 begin
 glColor4f(1, 1, 1, 1);
 Text_TagOut(FRect.X, FRect.Y, nil, true, PChar(fCaption));
 glColor4f(1, 1, 1, FAlpha/255);
 TextOut(FRect.X+fTab*8, FRect.Y, PChar(Text));
 if FCaretTicker div 16 mod 2 = 0 then
  TextOut(FRect.X + fTab*8 + CaretPos * 8, FRect.Y, '_');
 end;
end;

(**** TListBox ****)
constructor TListBox.Create(Proc: pointer; ID: integer);
begin
inherited Create(Proc, ID);
FAlpha       := 255;
FAinc        := 15;

FRect.X := 0;
FRect.Y := 0;
FRect.Width  := 340;
FRect.Height := 260;

FIndex := -1;
MDrag  := false;
Items  := TStringCells.Create;
SetSize(2, 1);
end;

procedure TListBox.SetIndex(i: integer);
begin
if (i < 1) and (Items.rowcount > 0) then
 i := 1;
if i > Items.rowcount - 1 then
 FIndex := Items.rowcount - 1
else
 FIndex := i;

// Set Scroll
if FIndex > FScroll + (FRect.Height - 20) div 16 - 1  then
 FScroll := FIndex - (FRect.Height - 20) div 16 + 1;

if FIndex < FScroll + 1 then
 FScroll := FIndex - 1;

if FScroll < 0 then
 FScroll := 0;
// Call proc
if @FProc <> nil then
 FProc(ID, Findex);
end;

procedure TListBox.onMessage(var Msg: TMessage);
begin
if not Enabled then Exit;
inherited;
if not FActive then
 begin
 MDrag := false;
 Exit;
 end;

 case Msg.Msg of
  WM_MOUSEWHEEL  :
   Index := Index - SmallInt(HIWORD(Msg.wParam)) div 120;

  WM_KEYDOWN :
   case Msg.wParam of
    VK_RETURN :
     Msg.lParam := FIndex;

    VK_NEXT :
     Index := Index + (FRect.Height - 36) div 16 - 1;

    VK_PRIOR :
     Index := Index - (FRect.Height - 36) div 16 + 1;

    VK_END :
     Index := Items.rowcount;

    VK_HOME :
     Index := 1;

    VK_UP, VK_DOWN :
     begin
     if Msg.wParam = VK_UP   then
      Index := Index - 1
     else
      Index := Index + 1;
     Msg.wParam := 0;
     end;
   end;

  WM_MOUSEMOVE :
   if MDrag then
    begin
    Msg.Msg := WM_LBUTTONDOWN;
    onMessage(Msg);
    end;

  WM_LBUTTONDOWN, WM_RBUTTONDOWN :
   if (MousePos.Y > Y + 26) and (MousePos.Y < Y + FRect.Height - 10) then
    begin
    index := FScroll + (MousePos.Y - Y - 26) div 16 + 1;
    if Msg.Msg = WM_LBUTTONDOWN then
     MDrag := true;
    end;

  WM_LBUTTONUP :
   MDrag := false;
 end;
end;

procedure TListBox.Update;
begin
inherited;
if Enabled and FActive then
 FAlpha := FAlpha + 0.1
else
 FAlpha := pi/2;
end;

procedure TListBox.Draw;
var
 clen   : integer;
 rlen   : integer;
 tr, tc : integer;
 i, j, k: integer;
begin
DrawBG;
DrawSelection;

tr := Items.rowcount;
tc := Items.colcount;

if (tc > 0) and (tr > 0) then
 begin
 //clen := (FRect.Width - 20) div tc div 8;
 //rlen := (FRect.Height - 16 - 20) div 16;

 rlen := (FRect.Height - 20) div 16 + FScroll;
 if rlen > tr + FScroll then
  rlen := tr + FScroll;
 k:=0;
 for j := 0 to tc - 1 do
  begin
	clen := min ( Items.colwidth[j], (FRect.Width - 20) div 8-k);
  if clen<0 then Break;
 	TextOut(X + 10 + k*8, Y, PChar(Copy(Items[j, 0], 1, clen)));
 	Inc(k, Items.colwidth[j]+1);
  end;

 for i := FScroll + 1 to rlen - 1 do
  begin
  k:=0;
 	for j := 0 to tc - 1 do
   begin
	 clen := min ( Items.colwidth[j], (FRect.Width - 20) div 8-k);
   if clen < 0 then Break;
   Text_TagOut(X + 10 + k*8, Y + 10 + (i - FScroll)*16, nil, true, PChar(Copy(Items[j, i], 1, clen)));
   Inc(k, Items.colwidth[j]+1);
   end;
  end;
end;

//
{
 for i := FScroll + 1 to rlen - 1 do
  for j := 1 to clen - 1 do
   begin
   glColor3f(0, 0, 0);
   TextOut(X + 11 + (j - 1)*clen*8, Y + 11 + (i - FScroll)*16, PChar(Copy(Items[j, i], 1, clen)));
   if Items[0, i] = 'D' then
    glColor3f(0.6, 0.6, 0.6)
   else
    glColor3f(0.8, 0.8, 0.8);
   TextOut(X + 10 + (j - 1)*clen*8, Y + 10 + (i - FScroll)*16, PChar(Copy(Items[j, i], 1, clen)));
   end;
 end; }

end;

procedure TListBox.DrawBG;
begin
xglTex_Disable;

glBegin(GL_QUADS);
 glColor4f(0.3, 0.2, 0.2, 1);
 glVertex2f(FRect.X,               FRect.Y);
 glVertex2f(FRect.X + FRect.Width, FRect.Y);
 glVertex2f(FRect.X + FRect.Width, FRect.Y + FRect.Height);
 glVertex2f(FRect.X,               FRect.Y + FRect.Height);
glEnd;

glLineWidth(1);
glBegin(GL_LINE_STRIP);
 glColor4f(1, 1, 1, 1);
 glVertex2f(FRect.X,               FRect.Y);
 glVertex2f(FRect.X + FRect.Width, FRect.Y);
 glVertex2f(FRect.X + FRect.Width, FRect.Y + FRect.Height);
 glVertex2f(FRect.X,               FRect.Y + FRect.Height);
 glVertex2f(FRect.X,               FRect.Y);
glEnd;

glBegin(GL_LINES);
 glVertex2f(FRect.X,               FRect.Y + 16);
 glVertex2f(FRect.X + FRect.Width, FRect.Y + 16);
glEnd;
end;

procedure TListBox.DrawSelection;
var
 iY : integer;
begin
iY := Y + (index - FScroll)*16 + 10;
if index > 0 then
 begin
 glBegin(GL_QUADS);
  glColor4f(1, 0, 0, 0.2);
  glVertex2f(FRect.X + 10,               iY);
  glVertex2f(FRect.X + FRect.Width - 10, iY);
  glColor4f(1, 0, 0, 0.3 + sin(FAlpha)/5);
  glVertex2f(FRect.X + FRect.Width - 10, iY + 8);
  glVertex2f(FRect.X + 10,               iY + 8);
  glVertex2f(FRect.X + 10,               iY + 8);
  glVertex2f(FRect.X + FRect.Width - 10, iY + 8);
  glColor4f(1, 0, 0, 0.2);
  glVertex2f(FRect.X + FRect.Width - 10, iY + 16);
  glVertex2f(FRect.X + 10,               iY + 16);
 glEnd;
 end;
glColor3f(1, 1, 1);
end;

procedure TListBox.SetSize(cols, rows: integer);
var
   i: integer;
begin
   Items.SetSize(cols, rows);
   for i:=0 to cols-1 do
      Items.colwidth[i]:=FRect.Width div (8*cols);
end;

(**** TFileListBox ****)

procedure TFileListBox.SetDir(NewDir: string);
var
 i   : integer;
 fd  : TFindData;
begin
FDir := NewDir;

// заносит имена файлов в  массив
Items.rowcount := 1;
if FindFirst(Dir + Ext, fd) then
 repeat
  i := Items.AddRow;
  Items[1, i] := ExtractFileNameEx(ShortString(fd.Data.cFileName));
  Items[0, i] := 'F';
 until not FindNext(fd);

if FindFirst(Dir + '*', fd) then
 repeat
  if not((fd.Data.cFileName[0] = '.') and
         (fd.Data.cFileName[1] = '')) then
   if DirectoryExists(Dir + fd.Data.cFileName) then
    begin
    i := Items.AddRow;
    if fd.Data.cFileName <> '..' then // Возврат назад
     Items[0, i] := 'D'
    else
     if FDir <> StartDir then
      Items[0, i] := 'B'
     else
      begin
      Items.rowcount := i;
      continue;
      end;
    Items[1, i] := ShortString(fd.Data.cFileName);
    end;
 until not FindNext(fd);

Items.SortAsc(0, 1);
Index := 0;
end;

procedure TFileListBox.onMessage(var Msg: TMessage);

 procedure Open;
 var
  s : string;
  i : integer;
 begin
 if Items[0, Index] = 'D' then  // Переход в след папку
  Dir := FDir + Items[1, Index] + '\'
 else
  if Items[0, Index] = 'B' then // Вернуться назад
   begin
   s := Dir;
   for i := Length(s) - 1 downto 1 do
    if s[i] = '\' then
     begin
     Delete(s, i + 1, Length(s)-i);
     break;
     end;
   Dir := s;
   end;
 end;

begin
if not Enabled then Exit;

if FActive then
 with Msg do
  case Msg of
   WM_KEYDOWN :
    if wParam = VK_RETURN then
     if Index > 0 then
      Open;
   WM_LBUTTONUP :
    begin
    if (GetTickCount - DBtick < 300) and (Index > -1) then
     Open;
    DBtick := GetTickCount;
    end;

   WM_RBUTTONDOWN :
    Open;
  end;
inherited;  
end;

procedure TFileListBox.Draw;
var
 clen   : integer;
 rlen   : integer;
 tr, tc : integer;
 i, j   : integer;
begin
DrawBG;
DrawSelection;

tr := Items.rowcount;
tc := Items.colcount;

if (tc > 0) and (tr > 0) then
 begin
 clen := (FRect.Width - 20) div tc div 8 - 1;
 rlen := (FRect.Height - 20) div 16 + FScroll;
 if rlen > tr + FScroll then
  rlen := tr + FScroll;
 for j := 1 to clen - 1 do
  TextOut(X + 10 + (j - 1)*clen*8, Y, PChar(Copy(Items[j, 0], 1, clen)));

 for i := FScroll + 1 to rlen - 1 do
  for j := 1 to clen - 1 do
   begin
   glColor3f(0, 0, 0);
   TextOut(X + 11 + (j - 1)*clen*8, Y + 11 + (i - FScroll)*16, PChar(Copy(Items[j, i], 1, clen)));
   if Items[0, i] = 'D' then
    glColor3f(0.6, 0.6, 0.6)
   else
    glColor3f(0.8, 0.8, 0.8);
   TextOut(X + 10 + (j - 1)*clen*8, Y + 10 + (i - FScroll)*16, PChar(Copy(Items[j, i], 1, clen)));
   end;
 end;
end;

{ TBindEdit }

constructor TBindEdit.Create(Proc: pointer; ID, pl_ind,
  key_ind: integer);
begin
   inherited Create(Proc, ID);
   Width:=260;
   f_pl:=pl_ind;
   f_key:=key_ind;
   f_input:=false;
end;

procedure TBindEdit.Draw;
begin
	if not FActive then
 	begin
 		if Enabled then
  			glColor4f(1, 1, 1, 255)
 		else
  			glColor4ub(127, 127, 127, 255);
 	end
   else if f_input then
      glColor4f(1, 1, 1, 1)
	else
		glColor4f(1, 1, 1, FAlpha/255);
   if f_input then
      TextOut(fRect.X-15, fRect.Y, '+');
	TextOut(FRect.X, FRect.Y, PChar(GetText));
end;

function TBindEdit.GetText: string;
const
 tab1 = 13;
 tab2 = 24;
begin
Result := PBinds[f_key, 1];
while Length(Result) < tab1 do
 Result := Result + ' ';

with PKeys[f_pl, f_key] do
 if Value > 0 then
  Result := Result + Input_KeyName(Value)
 else
  Result := Result + 'none';

while Length(Result) < tab2 do
 Result := Result + ' ';

with PKeys[f_pl, f_key] do
 if Value2 > 0 then
  Result := Result + Input_KeyName(Value2)
 else
  Result := Result + 'none'
end;

procedure TBindEdit.onMessage(var Msg: TMessage);
begin
   if not fWindow.Locked then
      f_input:=false;
if not f_input then
 begin
 	inherited;
 	if not FActive then Exit;
 	if (Msg.Msg = WM_LBUTTONDOWN) or ((Msg.Msg = WM_KEYDOWN) and (Msg.wParam = VK_RETURN)) then
  	begin
    enterkey := 0;
  	fWindow.Lock(Self);
  	f_input:=true;
  	end;
 end;
end;

procedure TBindEdit.Update;
begin
inherited;
if enterkey = 0 then
 begin
 enterkey := Input_LastKey;
 Exit;
 end;
if f_input then
 if enterkey = -1 then
  begin
  if Input_LastKey > -1 then
   begin
   BindKey(f_pl, f_key, Input_LastKey);
   FWindow.Unlock;
   f_input := false;
   end;
  end
 else
  if Input_LastKey <> enterkey then
   enterkey := -1;
end;

{ TLabel }

constructor TLabel.Create(Proc: pointer; ID: integer; const Text: string);
begin
   inherited Create(Proc, ID);
   Enabled:=false;
   fText:=Text;
   fCaption:='';
   fMaxLength:=Length(fText);
   Tab:=0;
end;

procedure TLabel.Draw;
begin
   if FActive then
		glColor4f(1, 1, 1, FAlpha/255)
   else glColor4f(1, 1, 1, 1);
   if Pos('^', fText)>0 then
  		Text_TagOut(FRect.X, FRect.Y, @Console.Font, true, PChar(fText))
      else TextOut(FRect.X, FRect.Y, PChar(fText));
end;

procedure TLabel.onMessage(var Msg: TMessage);
begin
	inherited;
	if not FActive then Exit;
	if (Msg.Msg = WM_LBUTTONDOWN) or ((Msg.Msg = WM_KEYDOWN) and (Msg.wParam = VK_RETURN)) then
 		if @FProc <> nil then
  			FProc(FID, 0);
end;

{ TCustomEdit }

procedure TCustomEdit.Draw;
begin
   if not FActive and not Enabled then
		glColor4ub(127, 127, 127, 255)
   else glColor4f(1, 1, 1, 1);
 	TextOut(FRect.X, FRect.Y, PChar(fCaption));
   if FActive then
		glColor4f(1, 1, 1, FAlpha/255);
  	TextOut(FRect.X+ftab*8, FRect.Y, PChar(fText));
end;

procedure TCustomEdit.SetMaxLength(Value: integer);
begin
fMaxLength:=Value;
Tab := fTab;
end;

procedure TCustomEdit.SetTab(Value: integer);
begin
fTab:=Value;
if MaxLength<8 then
 Width := fTab*8 + 64
else
 Width := (fTab+MaxLength)*8;
end;

procedure TCustomEdit.SetText(Text: string);
begin
fText := Text;
end;

procedure TCustomEdit.Update;
begin
inherited;
if not Enabled then
 begin
 FAlpha := 255;
 Exit;
 end;

if FActive then
 begin
 if FAlpha = 255 then FAinc := -abs(FAinc);
 if FAlpha = 150 then FAinc :=  abs(FAinc);
 inc(FAlpha, FAinc)
 end
else
 FAlpha := 255;
end;

{ TYesNoEdit }

constructor TYesNoEdit.Create(Proc: pointer; ID: integer;
  variable: PByte; const Caption, CMDStr: string);
begin
   inherited Create(Proc, ID);
   fCaption:=Caption;
   fvar:=variable;
   fCMDStr:=CMDStr;
   Tab:=20;
   MaxLength:=3;
   if Length(fCaption)>17 then Tab:=Length(fCaption)+3;
   str_No:='No';
   str_Yes:='Yes';
end;

procedure TYesNoEdit.Draw;
begin
   fText:=GetText;
   inherited;
end;

function TYesNoEdit.GetText: string;
begin
   if fVar^=0 then Result:=Result+str_No
   else Result:=Result+str_Yes;
end;

procedure TYesNoEdit.onMessage(var Msg: TMessage);
begin
	if not Enabled then Exit;
	inherited;
	if not FActive then Exit;
	if (Msg.Msg = WM_LBUTTONDOWN) or ((Msg.Msg = WM_KEYDOWN) and (Msg.wParam = VK_RETURN)) then
   begin
 		if @FProc <> nil then
  			FProc(FID, 0);
		Log_Conwrite(false);
      if fVar^=0 then
         Console_CMD(fCMDStr+' 1')
         else Console_CMD(fCMDstr+' 0');
		Log_Conwrite(true);
   end;
end;

{ TTexLabel }

constructor TTexLabel.Create(Proc: pointer; ID: integer;
  const TexName: string);
begin
   inherited;
   Enabled:=false;
   Y:=5;
end;

procedure TTexLabel.Draw;
begin
   Enabled:=true;
	inherited;
   Enabled:=false;
end;

procedure TTexLabel.Update;
begin
  	inherited;
   FAlpha:=255;
end;

{ TModelViewer }

constructor TModelViewer.Create;
begin
inherited Create(nil, 0);
weapon   := TObjTex.Create('textures\weapons\machinegun', 32, 16, 3, true, false, nil,
	OWNER_MENU);
Model := TModel.Create;
end;

procedure TModelViewer.SetModel(const ModelName: string);
begin
if Name <> ModelName then
 begin
 Name := ModelName;
 Model.LoadFromFile(ModelName, true);
 end;
end;

procedure TModelViewer.Draw;
begin
glPushMatrix;
glTranslatef(X, Y, 0);
glScalef(2, 2, 1);
glColor3f(1, 1, 1);
Model.Draw;
Model.DrawWeapon(90, false, DefWeapon.struct.weaponID);
glPopMatrix;
end;

procedure TModelViewer.Update;
begin
Model.NextFrame;
Model.Update;
end;

{ TEnumEdit }

constructor TEnumEdit.Create(Proc: pointer; ID: integer; variable: PByte;
  count: byte; const varval: array of byte;
  const varstr: array of string; const comval: array of string;
  const Caption, CMDStr: string);

var
   i: integer;

begin
   inherited Create(Proc, ID);
   fCaption:=Caption;
   fvar:=variable;
   fCMDStr:=CMDStr;
   Tab:=20;
   MaxLength:=3;
   fValCount:=count;
   for i:=1 to count do
   begin
      fValues[i]:=varval[i-1];
      fValuesStr[i]:=varstr[i-1];
      fComValues[i]:=comval[i-1];
   end;
   for i:=1 to count do
      if length(varstr[i-1])>MaxLength then
         MaxLength:=length(varstr[i-1]);
   if Length(fCaption)>17 then Tab:=Length(fCaption);
end;

procedure TEnumEdit.Draw;
begin
   fText:=GetText;
   inherited;
end;

function TEnumEdit.GetText: string;
var
   val: byte;
begin
   val:=GetVal;
   Result:=fValuesStr[val];
end;

function TEnumEdit.GetVal: byte;
var
   i, val: byte;
begin
   val:=1;
   for i:=1 to fValCount do
      if fVar^=fValues[i] then
      begin
         val:=i;
         Break;
      end;
   Result:=val;
end;

procedure TEnumEdit.onMessage(var Msg: TMessage);
begin
	if not Enabled then Exit;
	inherited;
	if not FActive then Exit;
	if (Msg.Msg = WM_LBUTTONDOWN) or ((Msg.Msg = WM_KEYDOWN) and (Msg.wParam = VK_RETURN)) then
   begin
   if @FProc <> nil then	FProc(FID, 0);
	 Log_Conwrite(false);
   Console_CMD(fCMDStr+' '+fComValues[GetVal mod fValCount+1]);
	 Log_Conwrite(true);
   end;
end;

{ TEnumStrEdit }
constructor TEnumStrEdit.Create(const Caption : string;
                                variable      : PByte;
                                const varstr  : array of string);
var
 i : integer;
begin
inherited Create(nil, ID_NONE);
fCaption   := Caption;
fvar       := variable;
Tab        := 20;
MaxLength  := 3;
SetLength(fValuesStr, Length(varstr));
for i := 0 to Length(varstr) - 1 do
 begin
 fValuesStr[i] := varstr[i];
 if Length(varstr[i]) > MaxLength then
  MaxLength := length(varstr[i]);
 end;
  
if Length(fCaption) > 17 then
 Tab := Length(fCaption);
end;

procedure TEnumStrEdit.Draw;
begin
fText := fValuesStr[fVar^ mod Length(fValuesStr)];
inherited;
end;

procedure TEnumStrEdit.onMessage(var Msg: TMessage);
begin
inherited;
if not FActive then Exit;
if (Msg.Msg = WM_LBUTTONDOWN) or ((Msg.Msg = WM_KEYDOWN) and (Msg.wParam = VK_RETURN)) then
 fVar^ := (fVar^ + 1) mod Length(fValuesStr);
end;

constructor TLevelShot.Create(X, Y: SmallInt);
begin
inherited Create(nil, ID_NONE);
FRect.X      := X;
FRect.Y      := Y;
FRect.Width  := 128;
FRect.Height := 128;
Enabled    := false;
Tex.ID     := 0;
Tex.BPP    := 16;
Tex.Filter := true;
Tex.Trans  := false;
Tex.Clamp  := true;
Tex.Scale  := true;
TexName    := '';
end;

procedure TLevelShot.LoadShot(const MapName: string);

 function TexExists(const TexName: string): boolean;
 begin
 Result := FileExists(TexName + '.bmp') or
           FileExists(TexName + '.tga') or
           FileExists(TexName + '.jpg');
 end;

begin
if TexName = MapName then Exit;
if Tex.ID <> 0 then
 xglTex_Free(@Tex);

if (not TexExists(Engine_ModDir + 'levelshots\' + MapName)) or
   (not xglTex_Load(PChar('levelshots\' + MapName), @Tex)) then
 Tex.ID := 0;
end;

procedure TLevelShot.Draw;
begin
glColor3f(1, 1, 1);
if Tex.ID <> 0 then
 begin
 xglTex_Enable(@Tex);
 xglAlphaBlend(1);
 with FRect do
  begin
  glBegin(GL_QUADS);
   glTexCoord2f(0, 1); glVertex2f(        X, Y);
   glTexCoord2f(1, 1); glVertex2f(X + Width, Y);
   glTexCoord2f(1, 0); glVertex2f(X + Width, Y + Height);
   glTexCoord2f(0, 0); glVertex2f(        X, Y + Height);
  glEnd;
  end;
 end;
xglTex_Disable;
with FRect do
 begin
 glBegin(GL_LINE_LOOP);
  glVertex2f(        X, Y);
  glVertex2f(X + Width, Y);
  glVertex2f(X + Width, Y + Height);
  glVertex2f(        X, Y + Height);
 glEnd;
 end; 
end;

end.
