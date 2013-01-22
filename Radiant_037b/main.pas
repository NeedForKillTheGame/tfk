unit main;

(***************************************)
(*  TFK Radiant mainform version 1.0.1 *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

//Небольшой хелп:
//Скроллинг - WSAD либо зажать M и путешествовать минимапой
//Изменение свойств объекта - двойной клик по синей рамке объекта или по его точке.
//Перемещение/ресайз объекта - просто переносите точки объекта, отвечающие за это.
//Выделение нескольких объектов - (shift или без него) выделение области мышой
//Выделить/отменить выделение объекта - ctrl+mouse
//Если один объект находится под другим, то помогает alt+mouse :)))

//Всей этой фигни вы не увидите в данном модуле - большая часть фигни лежит в ClickPs

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, BandActn, ExtActns, StdActns, XPStyleActnCtrls,
  ActnMan, ToolWin, ActnCtrls, ActnMenus, ExtCtrls, ImgList,
  TFKEntries, NFKMap_Lib, MapObj_Lib, MyScroll, ClickPs, LightMap_Lib, StdCtrls, Menus,
  CustomizeDlg, Buttons, ExtDlgs, ComCtrls, ShellApi, WP;

const
   DefaultExt = '.tm';

   MinimapKey = Ord('M');

type
   TEditorMode = (emObjects, emBricks, emLights, emLinks);

type
  TMap = class(TTFKMap1)
    constructor Create;
  public
    Scroll, AdvScroll: TMyScroll;
  public
     procedure ClearPal;
     procedure AfterLoad;override;
     procedure BeforeLoad;override;
  end;

  TMainForm = class(TForm)
    ActionManager1: TActionManager;
    FileOpen1: TFileOpen;
    FileSaveAs1: TFileSaveAs;
    FileExit1: TFileExit;
    CustomizeActionBars1: TCustomizeActionBars;
    MenuBar: TActionMainMenuBar;
    NewFile1: TAction;
    FileSave1: TAction;
    Paint1: TPaintBox;
    Box1: TImageList;
    RefreshTimer: TTimer;
    WeaponImg: TImageList;
    AmmoImg: TImageList;
    PowerUpImg: TImageList;
    HealthImg: TImageList;
    ArmorImg: TImageList;
    ButtonImg: TImageList;
    DoorImg: TImageList;
    PortalImg: TImageList;
    SargeImg: TImageList;
    JumppadImg: TImageList;
    CustomImg: TImageList;
    RightPnl: TPanel;
    ScrollBrk: TScrollBox;
    PaintBrk: TPaintBox;
    Splitter1: TSplitter;
    PopupMenu1: TPopupMenu;
    //menuitems
    Delete1: TMenuItem;
    EditDelete1: TEditDelete;
    Add1: TMenuItem;
    Respawn1: TMenuItem;
    Jumppad1: TMenuItem;
    Armor1: TMenuItem;
    Health1: TMenuItem;
    PowerUp1: TMenuItem;
    WeaponObj1: TMenuItem;
    Ammo1: TMenuItem;
    eleport1: TMenuItem;
    Button1: TMenuItem;
    NFKDoor1: TMenuItem;
    rigger1: TMenuItem;
    DeathLine1: TMenuItem;
    Water1: TMenuItem;
    Elevator1: TMenuItem;
    riangle1: TMenuItem;
    Shard1: TMenuItem;
    Armor501: TMenuItem;
    Armor1001: TMenuItem;
    H51: TMenuItem;
    N101: TMenuItem;
    N501: TMenuItem;
    megahealth1: TMenuItem;
    Shotgun1: TMenuItem;
    Grenade1: TMenuItem;
    Roocket1: TMenuItem;
    Shaft1: TMenuItem;
    Railgun1: TMenuItem;
    Plazmagun1: TMenuItem;
    BFG1: TMenuItem;
    Shotgun2: TMenuItem;
    Grenade2: TMenuItem;
    Rocket1: TMenuItem;
    Shaft2: TMenuItem;
    Railgun2: TMenuItem;
    Plazma1: TMenuItem;
    BFG2: TMenuItem;
    Machinegun1: TMenuItem;
    Small1: TMenuItem;
    Large1: TMenuItem;
    Regeneration1: TMenuItem;
    Battlesuit1: TMenuItem;
    Haste1: TMenuItem;
    Quad1: TMenuItem;
    Flight1: TMenuItem;
    Invisibility1: TMenuItem;
    N1: TMenuItem;
    N3: TMenuItem;
    ObjMode: TAction;
    LightsMode: TAction;
    MapProps1: TAction;
    ActionImages: TImageList;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    EditCut1: TEditCut;
    Areapush1: TMenuItem;
    areapain1: TMenuItem;
    ArenaEnd1: TMenuItem;
    AreaTeleport1: TMenuItem;
    eleportway1: TMenuItem;
    N4: TMenuItem;
    LoadPalDlg: TOpenPictureDialog;
    SavePalDlg: TSavePictureDialog;
    Panel1: TPanel;
    BrowsePalBtn: TBitBtn;
    ClearPalBtn: TBitBtn;
    SavePalBtn: TBitBtn;
    LightLine1: TMenuItem;
    Cut1: TMenuItem;
    Paste1: TMenuItem;
    Delete2: TMenuItem;
    N5: TMenuItem;
    StatusBar: TStatusBar;
    Action1: TAction;
    RunAct: TAction;
    LightLine2: TMenuItem;
    BrkMode: TAction;
    AddLight1: TMenuItem;
    ColorDlg: TColorDialog;
    GenMap: TAction;
    ActionToolBar1: TActionToolBar;
    BrickBlAct: TAction;
    BrickFrontAct: TAction;
    EditUndo: TEditUndo;
    EditRedo: TEditUndo;
    BloodGenerator1: TMenuItem;
    WPImages: TImageList;
    N6: TMenuItem;
    WayPoint1: TMenuItem;
    WayPoint2: TMenuItem;
    WayPoint3: TMenuItem;
    RemoveLinks: TMenuItem;
    N7: TMenuItem;
    wpact_Move: TAction;
    wpact_Crouch: TAction;
    wpact_Stay: TAction;
    wpact_RemoveLink: TAction;
    LinkMode: TAction;
    //end menuitems
    procedure NewFile1Execute(Sender: TObject);
    procedure FileSave1Execute(Sender: TObject);
    procedure FileSaveAs1BeforeExecute(Sender: TObject);
    procedure FileSaveAs1Accept(Sender: TObject);
    procedure FileOpen1Accept(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Paint1Paint(Sender: TObject);
    procedure PaintBrkPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ScrollBrkResize(Sender: TObject);
    procedure Splitter1Moved(Sender: TObject);
    procedure RefreshTimerTimer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Paint1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Paint1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Paint1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EditDelete1Execute(Sender: TObject);
    procedure Add1Click(Sender: TObject);
    procedure BrkModeExecute(Sender: TObject);
    procedure MapProps1Execute(Sender: TObject);
    procedure EditCopy1Execute(Sender: TObject);
    procedure EditPaste1Execute(Sender: TObject);
    procedure EditCut1Execute(Sender: TObject);
    procedure PaintBrkMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBrkMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BrowsePalBtnClick(Sender: TObject);
    procedure ClearPalBtnClick(Sender: TObject);
    procedure SavePalBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Action1Execute(Sender: TObject);
    procedure RunActExecute(Sender: TObject);
    procedure AddLight1Click(Sender: TObject);
    procedure GenLightExecute(Sender: TObject);
    procedure GenMapExecute(Sender: TObject);
    procedure BrickBlActExecute(Sender: TObject);
    procedure EditUndoExecute(Sender: TObject);
    procedure AddWPClick(Sender: TObject);
    procedure wpact_RemoveLinkExecute(Sender: TObject);
  private
    //переменные связанные с сохранением и загрузкой карт.
    file_name: string;
    workdir, mapdir, menufile, tfkpath: string;
    newfile, fmodified: boolean;
    function MapName: string;
    function SaveQuery: boolean;
    procedure SetInitialDirs;
    procedure SetModified(value: boolean);
    property modified: boolean read fmodified write SetModified;
  private
    //графические переменные
    dbuffer: TBitmap; //doublebuffer :)
    drawnow: boolean;//так что, надо еще раз прорисовать???
    minimap, minidrag: boolean;//рисуется или нет минимапа?

    procedure DrawMouseRect(canvas: TCanvas);
    procedure StartDrag;
    procedure EndDrag;
  private
    drag, select: boolean;
    dx, dy: integer;	//точка за которую взялась мышка
    dragpoints: TClickPoints;
    //Rect для селекта
    rx1, ry1, rx2, ry2: integer;
    //мышиные координаты, пригодятся еще...
    mousex, mousey, absmousex, absmousey: integer;
    MouseShift: TShiftState;
    pos_x, pos_y: integer;//позиция на карте
    function Multiselect: boolean;
    procedure CheckMouseRect;
    procedure SetMouseCoord(x1, y1: integer);
  private
  // БРИКИ И ОБЪЕКТЫ
    dbufferBrk: TBitmap;
    BrkWidth, BrkHeight: smallint;
    selbrk: word;
   //маска бриков
    brkblock: boolean;
    brkfront: boolean;

    drawbrknow: boolean;
   //брики в буффере
    brkbuf, brksel: TBricksEntry;

    procedure CheckObjs;
    procedure SetBrk(brk: word);//установить активный брик
    procedure GetBrk;           //взять с карты брики
    procedure PlaceBrk;

    procedure SetBrkMask(block, front: boolean);
    procedure SetDefBrkMask;
  private
    UndoBuf: array [1..100] of TBricksEntry;
    UndoCount, UndoInd : integer;
    procedure UndoClear;
    procedure UndoPut;
    procedure UndoSet(ind: integer);//ставим i-ый Undo
    procedure UndoDeleteNext;//уничтожаем следующие undo - буферы
  private
  //light'ы
    light: TLightClickPoint;
    lightbuf: TLightObj;
    procedure ShowLightProps(lightobj: TLightObj);
  private
  //копирование объектов
    cobjs: array of TCustomMapObj;
    procedure ClearObjsBuffer;
    procedure CopyObjs(cut: boolean);
    procedure PasteObjs;
  //копирование бриков
    procedure CopyBrk(cut: boolean);
    procedure PasteBrk;
  private
    //LINKи
    procedure link_Delete(cp: TClickPoint);
    procedure link_Double(cp: TClickPoint);
    procedure link_OneWay(cp: TClickPoint);

  private
    Mode: TEditorMode;
    procedure ShowObjProps(Obj: TCustomMapObj);
  end;

var
  MainForm: TMainForm;
  Map: TMap;

implementation

{$R *.dfm}

uses MyPalette, Constants_Lib, ObjectProps, ObjButtonProps, ObjRespawnProps,
	ObjJumppadProps, ObjElevatorProps, MapProps, ObjDeathlineProps,
  ObjItemProps, ObjAreaPainProps, ObjAreaPushProps, ObjBGProps,
  ObjLightLineProps, about, ObjBloodGenProps, LightMapGen, MapGen,
  ObjWeatherProps;

{ TMap }

procedure TMap.AfterLoad;
var
   i, x0, y0: integer;
begin
  inherited;
   Scroll.MaxI:=Brk.Width;
   Scroll.MaxJ:=Brk.Height;
   AdvScroll.MaxI:=Brk.Width;
   AdvScroll.MaxJ:=Brk.Height;

   with MainForm do
   begin
     	selbrk:=1;
   	Mode:=emObjects;
      if BrkTex<>nil then
         LoadPaletteFromBitmap(BrkTex.Bitmap, CustomImg, clBlue, 0, 0);
      FormResize(self);
      ScrollBrkResize(self);
      Paint1Paint(self);
      PaintBrkPaint(self);

      BrowsePalBtn.enabled:=BrkTex=nil;
      ClearPalBtn.enabled:=BrkTex<>nil;
      SavePalBtn.enabled:=BrkTex<>nil;

      drawnow:=true;
   end;

     //хитрость - ищем ближайший респаун и центрируем по нему
   x0:=map.Width div 2;
   y0:=map.Height div 2;
 	for i:=0 to Obj.Count-1 do
    	if Obj[i].ObjType=otRespawn then
    	begin
   		if (map.Width>20) then x0:=Obj[i].x;
         if (map.Height>30) then y0:=Obj[i].y;
         Break;
     	end;
   Scroll.CenterToIJ(x0, y0);
   MainForm.UndoPut;
end;

procedure TMap.BeforeLoad;
begin
  inherited;
   ClearPoints;
   ClearLPoints;
   MainForm.dragpoints:=nil;
   MainForm.light:=nil;
   MainForm.SetBrkMask(false, false);
   MainForm.UndoClear;
end;

procedure TMap.ClearPal;
begin
   if BrkTex<>nil then
   begin
      Entries.Delete(Entries.IndexOf(BrkTex));
      BrkTex.Free;
      BrkTex:=nil;
   end;
end;

constructor TMap.Create;
begin
   inherited;
   Scroll:=TMyScroll.Create;
   Scroll.ZoomX:=32;
   Scroll.ZoomY:=16;
   AdvScroll:=TMyScroll.Create;
end;

{ TMainForm }

function TMainForm.MapName: string;
var
   i: integer;
begin
//имя карты
   if newfile then
   	Result:='newmap'
   else
   begin
      Result:=ExtractFileName(File_Name);
      i:=pos('.mapa', result);
      if i=Length(result)-4 then
         Delete(Result, Length(result)-4, 5);
   end;
end;

function TMainForm.SaveQuery: boolean;
var
   res: integer;
begin
   //спрашиваем надо ли сохранять файл
   Result:=not modified;
   if Result then Exit;
	res:=Application.MessageBox(
   	PChar('Save changes to map "'+MapName+'"'),
      'Query',
      mb_YesNoCancel);
   if res=mrYes then
   begin
      if FileSave1.Execute then
      	Result:=not modified;
   end
      else Result:=res=mrNo;
end;

procedure TMainForm.SetInitialDirs;
begin
   if not newfile then
   begin
   	with FileOpen1.Dialog do
   	begin
      	InitialDir:=ExtractFilePath(file_name);
      	filename:=file_name;
   	end;
   	with FileSaveAs1.Dialog do
   	begin
      	InitialDir:=ExtractFilePath(file_name);
      	filename:=file_name;
   	end;
   end;
end;

procedure TMainForm.SetModified(value: boolean);
begin
   StatusBar.Panels[0].Text:='';
   fmodified:=value;
   if fmodified then
   	StatusBar.Panels[0].Text:='modified';
end;

procedure TMainForm.NewFile1Execute(Sender: TObject);
begin
   if not SaveQuery then Exit;
   Map.NewMap;
   newfile:=true;
   modified:=false;
end;

procedure TMainForm.FileSaveAs1BeforeExecute(Sender: TObject);
begin
   if newfile then
   	with FileSaveAs1.Dialog do
      	filename:=InitialDir+'\'+MapName+DefaultExt;
end;

procedure TMainForm.FileSaveAs1Accept(Sender: TObject);
begin
//Finalize Work
   PlaceBrk;

   file_name:=FileSaveAs1.Dialog.FileName;
   newfile:=false;
   SetInitialDirs;
   FileSave1.Execute;
end;

procedure TMainForm.FileSave1Execute(Sender: TObject);
begin
//Если файлик неизвестен то вызываем FileSaveAs; иначе грузим карту...
   if (file_name='') or
      (ExtractFileExt(file_name)<>DefaultExt) then
   begin
      FileSaveAs1.Execute;
      Exit;
   end;
//сохранение файла
   Map.SaveToFile(file_name);
   modified:=false;
end;

procedure TMainForm.FileOpen1Accept(Sender: TObject);
var
   res: integer;
begin
//загружаем карту
   with FileOpen1.Dialog do
   begin
      if not FileExists(filename) or
      	not SaveQuery then Exit;
   	PlaceBrk;
//сама загрузка
      res:=Map.LoadFromFile(filename);
      case res of
         -2: begin ShowMessage('Unknown map format!');exit;end;
         -1: begin ShowMessage('Invalid map format!');exit;end;
      end;

//в случае удачи меняем имя файла и получаем ссылку на загрю карту, старую карту выгружаем.
      newfile:=false;
      file_name:=filename;
      modified:=false;
      if pos('.mapa', filename)=Length(file_name)-4 then
         Delete(file_name, Length(file_name)-4, 5);
      SetInitialDirs;
   end;
end;

//КОНЕЦ ОПЕРАЦИЙ С ФАЙЛАМИ
//*************************

procedure TMainForm.FormCreate(Sender: TObject);
begin
   WorkDir:=ExtractFilePath(ParamStr(0));
   mapDir:=WorkDir+'..\maps\';
   menufile:=WorkDir+'menu.dat';
   tfkpath:=WorkDir+'..\..\';
   if FileExists(menufile) then ActionManager1.FileName:=menufile;
//ГЛАВНАЯ ПРОЦЕДУРА - СОЗДАНИЕ ВСЕХ ОБЪЕКТОВ
   Map:=TMap.Create;
//загрузка текстур по-умолчанию
   try
   	LoadPaletteFromFileMasked(WorkDir+'..\textures\box.bmp', Box1, clBlue, 0, 0);
   except
   	try
   		LoadPaletteFromFileMasked(WorkDir+'textures\box.bmp', Box1, clBlue, 0, 0);
   	except
         try
   			LoadPaletteFromFileMasked(WorkDir+'TA\box.bmp', Box1, clBlue, 0, 0);
   		except
         	try
   				LoadPaletteFromFileMasked(WorkDir+'box.bmp', Box1, clBlue, 0, 0);
   			except
    				ShowMessage('Box.bmp not found!');
      		end;
      	end;
      end;
   end;
//установка параметров по-умолчанию
   FileOpen1.Dialog.InitialDir:=mapDir;
   FileSaveAs1.Dialog.InitialDir:=mapDir;
   LoadPalDlg.InitialDir:=mapDir;
   SavePalDlg.InitialDir:=mapDir;

   NewFile1Execute(Self);
   FormResize(Self);

   //а теперь подгрузка параметров
   if ParamStr(1)<>'' then
   begin
      FileOpen1.Dialog.FileName:=ParamStr(1);
      FileOpen1.OnAccept(Self);
   end;

   //обнуление переменных редактора
   selbrk:=1;
   Mode:=emObjects;
   brksel:=nil;brkbuf:=nil;
 	SetBrkMask(true, false);
   CheckObjs;
end;

//************************************
//ПРОРИСОВКА КАРТЫ!!!!!
procedure TMainForm.Paint1Paint(Sender: TObject);
var
   i, j, k, x, y: integer;
   cp: TClickPoint;
   cpl: TLightClickPoint;
   Arrow: TPoint;

    procedure DrawArrow(bx, by, cx, cy: integer);
    type
       TPointf = record X, Y: double; end;

    	function Normalize(p: TPointf): TPointf;
    	begin
         Result.X:=p.X/sqrt(sqr(p.X)+sqr(p.Y));
         Result.Y:=p.Y/sqrt(sqr(p.X)+sqr(p.Y));
    	end;

    var
       A, B: TPointf;
       P: array [0..1] of TPoint;
    begin
    //Draw arrow
    	A.X := cx - bx;
    	A.Y := cy - by;
    	B.X := - A.Y;
    	B.Y :=   A.X;

    	A := Normalize(A);
    	B := Normalize(B);

    	A.X := A.X * Arrow.X;
    	A.Y := A.Y * Arrow.X;

    	B.X := B.X * Arrow.Y;
    	B.Y := B.Y * Arrow.Y;

    	P[0].X := trunc(bx - A.X + B.X);
    	P[0].Y := trunc(by - A.Y + B.Y);
    	P[1].X := trunc(bx - A.X - B.X);
    	P[1].Y := trunc(by - A.Y - B.Y);
      with dbuffer, Canvas do
      begin
      	Polygon([P[0], P[1], Point(bx, by)]);
      	PenPos := P[0];
      	LineTo(bx, by);
      	LineTo(P[1].X, P[1].Y);
      end;
    end;

	function RectIntersect(rect1, rect2: TRect): boolean;
//проверка ПЕРЕСЕЧЕНИЯ ректов
 		function Intersect0(x1, x2, y1, y2: SmallInt): boolean;
 		begin
 //проверка пересечения отрезков
 			Result := (x1 >= y1) and (x1 <= y2) or
           (x2 >= y1) and (x2 <= y2) or
           (x1 <= y1) and (y2 <= x2) or
           (x1 >= y1) and (y2 >= x2);
 		end;

	begin
		Result := InterSect0(rect1.Left, rect1.Right,  rect2.Left, rect2.Right) and
          		InterSect0(rect1.Top, rect1.Bottom, rect2.Top, rect2.Bottom);
	end;

begin
   if dbuffer=nil then
   begin
      dbuffer:=TBitmap.Create;
      dbuffer.Width:=Paint1.Width;
      dbuffer.Height:=Paint1.Height;
   end;
   with dbuffer, canvas do
   begin
      Pen.Color:=clBlack;
      Pen.Mode:=pmCopy;
      Brush.Color:=clBlack;
      Brush.Style:=bsSolid;
      Rectangle(0, 0, width, height);

      Brush.Style:=bsClear;
      Font.Color:=clWhite;
      Pen.color:=clNavy;
      Pen.Width:=3;
      //рисуем брики
      with Map, Scroll do
      for j:=ScreenRect.Top to ScreenRect.Bottom do
     	 	for i:=ScreenRect.Left to ScreenRect.Right do
         begin
         	if Brk[i, j]>0 then
         	begin
            	if (BrkTex<>nil) and (BrkTex.Head.TEXCount>=Brk[i, j]) then
               	CustomImg.Draw(Canvas, GetX(i), GetY(j), Brk[i, j]-1)
               else Box1.Draw(Canvas, GetX(i), GetY(j), Brk[i, j]-1);
               if not Brk.blocked[i, j] then
                  if Brk.Front[i, j] then
                  	TextOut(i*32+16-TextWidth('Front') div 2-gx, j*16+8-TextHeight('Front')div 2-gy, 'Front');
//                  else
//                  	TextOut(i*32+16-TextWidth('Back') div 2-gx, j*16+8-TextHeight('Back')div 2-gy, 'Back');
         	end else
            if Brk.Blocked[i, j] then
               TextOut(i*32+16-TextWidth('Empty') div 2-gx, j*16+8-TextHeight('Empty')div 2-gy, 'Empty');
            //рисуется левая граница
            if Brk.Blocked[i, j]<>Brk.Blocked[i-1, j] then
            begin
               MoveTo(i*32-gx, j*16-gy);LineTo(i*32-gx, (j+1)*16-gy);
            end;
            //рисуется верхняя граница
            if Brk.Blocked[i, j]<>Brk.Blocked[i, j-1] then
            begin
               MoveTo(i*32-gx, j*16-gy);LineTo((i+1)*32-gx, j*16-gy);
            end;
         end;
      Pen.Width:=1;
      //рисуем объекты
      with Map, Scroll do
      for i:=0 to Obj.Count-1 do
      begin
         if not RectIntersect(Obj[i].GraphRect, ScreenRect) then
            Continue;

         x:=GetX(Obj[i].x);
         y:=GetY(Obj[i].y);
         case Obj[i].ObjType of
            otRespawn: SargeImg.Draw(Canvas, x, y-32, Ord(Obj[i].Struct.orient));
            otJumppad: JumpPadImg.Draw(Canvas, x, y, TJumpPadObj(Obj[i]).GetJumpHeight div 8 mod 16);
            otTeleport:	PortalImg.Draw(Canvas, x-16, y-32, (Obj[i].Struct.gotox+Obj[i].Struct.gotoy) mod PortalImg.count);
            otButton: ButtonImg.Draw(Canvas, x, y-8, Obj[i].Struct.color);
            otNFKDoor: begin
            				for k:=0 to Obj[i].height-1 do
                       		for j:=0 to Obj[i].width-1 do
                          		DoorImg.Draw(Canvas, x+j*32, y+k*16, Obj[i].Struct.orient div 2);
                       	if Obj[i].Struct.opened then
                        begin
                          	Font.Color:=clLime;
                          	Font.Size:=8;
                          	TextOut(x, y+Obj[i].height*16-16, 'opened');
                        end;
                       end;
            otHealth: HealthImg.Draw(Canvas, x, y, Obj[i].Struct.itemID-Health5_ID);
            otArmor: ArmorImg.Draw(Canvas, x, y, Obj[i].Struct.itemID-Shard_ID);
            otWeapon: WeaponImg.Draw(Canvas, x, y, Obj[i].Struct.weaponID-2);
            otAmmo: AmmoImg.Draw(Canvas, x, y, Obj[i].Struct.weaponID-1);
            otPowerUp: PowerUpImg.Draw(Canvas, x, y, Obj[i].Struct.ItemID-Regen_ID);
            otDeathLine: begin
            	Pen.Color:=clPurple;
               MoveTo(x+16, y+8);
               LineTo(x+16+TDeathLine(Obj[i]).dx, y+8+TDeathLine(Obj[i]).dy);
               	end;
            otLightLine: begin
            	Pen.Color:=clWhite;
               MoveTo(x+16, y+8);
               LineTo(x+16+TDeathLine(Obj[i]).dx, y+8+TDeathLine(Obj[i]).dy);
               	end;
            otBloodGen: begin
            	Pen.Color:=clMaroon;
               MoveTo(x+16, y+8);
               LineTo(x+16+TDeathLine(Obj[i]).dx, y+8+TDeathLine(Obj[i]).dy);
               	end;
            otWeather:
            begin
               Font.Color:=clWhite;
               TextOut(x+Obj[i].Width*16-TextWidth('Wheather') div 2, y+Obj[i].height*8- TextHeight('Wheather') div 2, 'Wheather');
            end;
            otWater:
            begin
               Pen.Color:=clBlue;
               Brush.Color:=clBlue;
               Brush.Style:=bsBDiagonal;
               Rectangle(x, y, x+Obj[i].width*32, y+Obj[i].height*16);
            end;
{            otEmptyBricks:
            begin
               Font.Color:=clAqua;
               for j:=0 to Obj[i].Width-1 do
                  for k:=0 to Obj[i].Height-1 do
               		TextOut(x+j*32+16-TextWidth('Empty') div 2, y+k*16+8-TextHeight('Empty')div 2, 'Empty');
            end;
            otBackBricks:
            begin
               Font.Color:=clAqua;
               for j:=0 to Obj[i].Width-1 do
                  for k:=0 to Obj[i].Height-1 do
               		TextOut(x+j*32+16-TextWidth('Back') div 2, y+k*16+8-TextHeight('Back')div 2, 'Back');
            end;}
            otElevator:
            begin
               Pen.Color:=clGray;
               Brush.Color:=clGray;
               Brush.Style:=bsBDiagonal;
               Rectangle(x, y, x+Obj[i].width*32, y+Obj[i].height*16);
            end;
            otAreaPain:
            begin
               Font.Color:=clGreen;
               TextOut(x+obj[i].width*16-TextWidth('PAIN') div 2, y+obj[i].height*8-TextHeight('PAIN')div 2, 'PAIN');
            end;
            otArenaEnd:
            begin
               Font.Color:=clAqua;
               TextOut(x+obj[i].width*16-TextWidth('ARENA END') div 2, y+obj[i].height*8-TextHeight('ARENA END')div 2, 'ARENA END');
            end;
         end;
         if Obj[i].ObjType in [otLava, otAreaPush, otAreapain] then
            Pen.Color:=clRed
            else Pen.Color:=clBlue;
         Brush.Style:=bsClear;
         if not (Obj[i] is TItemObj) then
				Rectangle(GetX(Obj[i].x), GetY(Obj[i].y), GetX(Obj[i].x+Obj[i].width), GetY(Obj[i].y+Obj[i].height));
      end;

      //телепорты
      with Map, Scroll do
      for i:=0 to Obj.Count-1 do
         if Obj[i].ObjType in [otTeleport, otAreaTeleport, otTeleportWay] then
      begin
         x:=GetX(Obj[i].x);
         y:=GetY(Obj[i].y);

         Pen.Color:=clRed;
         MoveTo(x-5, y-25);LineTo(x+37, y-25);
         MoveTo(x-5, y-35);LineTo(x+37, y-35);
         Pen.Color:=clMaroon;
         Brush.Color:=clRed;
      	Arrow.X := -10;
 			Arrow.Y := 5;
         DrawArrow(x+37, y-35, x-5, y-35);
         if Obj[i].Struct.orient=1 then
         	DrawArrow(x-5, y-25, x+37, y-25)
            else
         	DrawArrow(x+37, y-25, x-5, y-25);

         Pen.Color:=clRed;
         if Obj[i].ObjType=otTeleport then
            MoveTo(x+16, y-16) else
            MoveTo(x+Obj[i].Width*16, y+Obj[i].Height*8);
         x:=GetX(Obj[i].struct.gotox);
      	y:=GetY(Obj[i].struct.gotoy);
         if Obj[i].ObjType=otTeleportWay then
         	LineTo(x+16, y+8)
         else
         	LineTo(x+16, y-16);
         Pen.Color:=clMaroon;
         Brush.Style:=bsClear;
         if Obj[i].ObjType=otTeleportWay then
            Rectangle(x, y, x+Obj[i].Width*32, y+Obj[i].Height*16)
         else
            Rectangle(x, y-32, x+32, y+16);
      end;
      //элеваторы
      with Map, Scroll do
      for i:=0 to Obj.Count-1 do
         if Obj[i].ObjType in [otElevator] then
      begin
         x:=GetX(Obj[i].x);
         y:=GetY(Obj[i].y);
         Pen.Color:=clYellow;
         MoveTo(x+16, y+8);
         x:=GetX(Obj[i].struct.elevx+Obj[i].x);
      	y:=GetY(Obj[i].struct.elevy+Obj[i].y);
         LineTo(x+16, y+8);
         Pen.Color:=clMaroon;
         Brush.Style:=bsClear;
         Rectangle(x, y, x+Obj[i].width*32, y+Obj[i].height*16);
      end;
      //треугольники
      with Map, Scroll do
      for i:=0 to Obj.Count-1 do
         if Obj[i].ObjType in [otTriangle] then
         with Obj[i] do
      begin
         Pen.Color:=clWhite;
         Brush.Style:=bsClear;
         case struct.orient of
            0:
            begin
               MoveTo(GetX(x), GetY(y));
               LineTo(GetX(x+width), GetY(y+height));
               LineTo(GetX(x), GetY(y+height));
               LineTo(GetX(x), GetY(y));
            end;
            1:
            begin
               MoveTo(GetX(x+width), GetY(y));
               LineTo(GetX(x), GetY(y+height));
               LineTo(GetX(x), GetY(y));
               LineTo(GetX(x+width), GetY(y));
            end;
            2:
            begin
               MoveTo(GetX(x), GetY(y));
               LineTo(GetX(x+width), GetY(y+height));
               LineTo(GetX(x+width), GetY(y));
               LineTo(GetX(x), GetY(y));
            end;
            3:
            begin
               MoveTo(GetX(x), GetY(y+height));
               LineTo(GetX(x+width), GetY(y));
               LineTo(GetX(x+width), GetY(y+height));
               LineTo(GetX(x), GetY(y+height));
            end;
         end;
      end;

      //ну а теперь можно и Waypoint'ы
      with Map, Scroll do
      if (mode=emLinks) and (WP<>nil) then
      begin
      	Arrow.X := -20;
 			Arrow.Y := 3;
         Pen.Color:=clSilver;
         Brush.Color:=clSilver;
         for i:=0 to WP.Count-1 do
            with WP[i] do
               for j:=0 to way_Count-1 do
               begin
         			Pen.Color:=clGray;
                  MoveTo(fx*32+16-GX, fy*16+8-GY);
                  LineTo(Ways[j].fx*32+16-GX, Ways[j].fy*16+8-GY);
         			Pen.Color:=clSilver;
                  DrawArrow(Ways[j].fx*32+16-GX, Ways[j].fy*16+8-GY,
                  	fx*32+16-GX, fy*16+8-GY,);
               end;
         for i:=0 to WP.Count-1 do
            with WP[i] do
            begin
               if wp_type='M' then j:=1
               else if wp_type='C' then j:=2
               else if wp_type='S' then j:=3
               else j:=0;
               WPImages.Draw(Canvas, X*32-GX, Y*16-GY, j);
            end;
      end;

      //а теперь лайты %)
      with Map, Scroll do
      if mode=emLights then
      if Lights<>nil then
      begin
         for i:=0 to Lights.Count-1 do
            with Lights[i] do
         begin
         	Brush.Color:=Lights[i].WColor;
            if (Light=nil) or (Light.Obj<>Lights[i]) then
            	Brush.Style:=bsClear
            else Brush.Style:=bsCross;
            Pen.Color:=Lights[i].WColor;
            Canvas.Ellipse(x-gx - Radius, y-gy-radius,
            	x-gx + Radius, y-gy+radius);
         end;
      end;

      //а теперь кликпойнты
      j:=GetPointsCount;
      if (Mode=emObjects) or (Mode=emLinks) then
      with Map.Scroll do
      for i:=0 to j-1 do
      begin
         cp:=GetPoint(i);
         if (ptLink in cp.pType)<>(Mode=emLinks) then Continue;
         if ptInvisible in cp.pType then Continue;
         x:=cp.x-GX;y:=cp.y-GY;
         Pen.Color:=cp.Color;

         Brush.Style:=bsSolid;
         if IsSelectedPoint(cp, dragpoints) then
         	Brush.Color:=clRed
      	else if IsSelectedObj(cp.Obj, dragpoints) then
            Brush.Color:=clAqua
          	else Brush.Style:=bsClear;
         Rectangle(x-3, y-3, x+3, y+3);
      end;

      //а теперь кликпойнты для light'ов
      j:=GetLPointsCount;
      if Mode=emLights then
      with Map.Scroll do
      for i:=0 to j-1 do
      begin
         cpl:=GetLPoint(i);
         x:=cpl.x-GX;y:=cpl.y-GY;
         Pen.Color:=cpl.Color;
         Brush.Style:=bsSolid;
         if cpl=light then
            Brush.Color:=clAqua
         else Brush.Style:=bsClear;
         Rectangle(x-3, y-3, x+3, y+3);
      end;

      Brush.Style:=bsClear;
      Font.Color:=clWhite;
      TextOut(10, 10, Map.head.Name);

      Pen.Color:=clLime;
      if (mode=emBricks) and (select or (brksel<>nil)) then
         begin
            //рисуем выделенные брики
            if brksel<>nil then
            with Map, Scroll do
            begin
      			Font.Color:=clWhite;
      			Pen.color:=clNavy;
      			Pen.Width:=3;
               for i:=0 to BrkSel.Width-1 do
                  for j:=0 to BrkSel.Height-1 do
                  begin
                     if BrkSel[i, j]>0 then
                     begin
            				if (BrkTex<>nil) and (BrkTex.Head.TEXCount>=BrkSel[i, j]) then
               				CustomImg.Draw(Canvas, (i+rx1)*32-GX, (j+ry1)*16-GY, BrkSel[i, j]-1)
               				else Box1.Draw(Canvas, (i+rx1)*32-GX, (j+ry1)*16-GY, BrkSel[i, j]-1);
               		if not BrkSel.blocked[i, j] then
                  		if BrkSel.Front[i, j] then
                  			TextOut((i+rx1)*32+16-TextWidth('Front') div 2-gx, (j+ry1)*16+8-TextHeight('Front')div 2-gy, 'Front');

                     end else
           				if BrkSel.Blocked[i, j] then
               			TextOut((i+rx1)*32+16-TextWidth('Empty') div 2-gx, (j+ry1)*16+8-TextHeight('Empty')div 2-gy, 'Empty');
            	//рисуется левая граница
            			if BrkSel.Blocked[i, j]<>BrkSel.Blocked[i-1, j] then
            			begin
               			MoveTo((i+rx1)*32-gx, (j+ry1)*16-gy);LineTo((i+rx1)*32-gx, (j+ry1+1)*16-gy);
            			end;
            	//рисуется верхняя граница
            			if BrkSel.Blocked[i, j]<>BrkSel.Blocked[i, j-1] then
               		begin
               			MoveTo((i+rx1)*32-gx, (j+ry1)*16-gy);LineTo((i+rx1+1)*32-gx, (j+ry1)*16-gy);
               		end;
            		end;
               Pen.Width:=1;
            end;//with
      		Pen.Color:=clLime;
            //рамочка
            if rx1<rx2 then begin i:=rx1;x:=rx2 end
            else begin i:=rx2;x:=rx1 end;
            if ry1<ry2 then begin j:=ry1;y:=ry2 end
            else begin j:=ry2;y:=ry1 end;
            i:=i*32;x:=(x+1)*32;
            j:=j*16;y:=(y+1)*16;
      		Rectangle(i-Map.Scroll.GX, j-Map.Scroll.GY,
         		x-Map.Scroll.GX, y-Map.Scroll.GY);
         end;
      if (mode in [emObjects, emLinks]) and select then
      begin
      		Rectangle(rx1-Map.Scroll.GX, ry1-Map.Scroll.GY,
         		rx2-Map.Scroll.GX, ry2-Map.Scroll.GY);
      end;

      if minimap then
      with Map, AdvScroll do
      begin
{         if not transparentminimap then}
         begin
            Pen.Color:=clBlack;
            Brush.Color:=clBlack;
            Brush.Style:=bsSolid;
            Rectangle(GetX(0), GetY(0), GetX(width), GetY(height));
         end;
      	for j:=0 to height-1 do
         	for i:=0 to width-1 do
            if (Brk[i, j]>0) then
            begin
          		x:=GetX(i);
          		y:=GetY(j);
               Pen.Color:=clWhite;
               Brush.Style:=bsClear;
               if ZoomX>2 then
               	Rectangle(x, y, x+ZoomX+1, y+ZoomY+1)
                  else
                  begin
                     Pixels[x, y]:=Pen.Color;
                     Pixels[x+1, y]:=Pen.Color;
                  end;
            end;
         //рамочка
         Pen.Color:=clRed;
         Brush.Style:=bsClear;
     		Rectangle(-GX, -GY, GetMaxX-GX+1, GetMaxY-GY+1);
         //рисуем текущее положение нашего окна
         Pen.Color:=clBlue;

         Scroll.ClipOff:=true;
         Rectangle(RectIJToXY(Scroll.ScreenRect));
         Scroll.ClipOff:=false;
      end else if not drag then
      	DrawMouseRect(Canvas);  //if minimap
      Pen.Color:=clWhite;
      Brush.Style:=bsClear;
      with Map, Scroll do
      	Rectangle(GetX(0)-1, GetY(0)-1, GetX(Width), GetY(Height));
      //вывод на экран
      Paint1.Canvas.CopyRect(Rect(0, 0, width, height), canvas, Rect(0, 0, width, height));
   end;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
//resize
   if dbuffer<>nil then
   begin
      dbuffer.Width:=Paint1.Width;
      dbuffer.Height:=Paint1.Height;
   end;
   with Map.Scroll do
   begin
   	ScreenWidth:=Paint1.Width;
      ScreenHeight:=Paint1.Height;
      GX:=GX;
      GY:=GY;
   end;
   with Map.AdvScroll do
   begin
      ClipOff:=false;
      ScreenWidth:=Paint1.Width;
      ScreenHeight:=Paint1.Height;
      ZoomX:=trunc(2*ScreenWidth/(3*Map.Width));
      ZoomY:=trunc(ScreenHeight*3/(4*Map.Height));
      if ZoomX>2*ZoomY then ZoomX:=2*ZoomY
         else ZoomY:=ZoomX div 2;
      if (ZoomX<=0) or (ZoomY<=0) then
      begin
      	ZoomX:=2;
         ZoomY:=1;
      end;

      GX:=0;
      GY:=0;
   end;
end;

procedure TMainForm.RefreshTimerTimer(Sender: TObject);
begin
   CheckMouseRect;
   if drawnow then
      Paint1Paint(Self);
   if drawbrknow then
      PaintBrkPaint(Self);
   drawnow:=false;
   drawbrknow:=false;
end;

procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
const
   ScrX=16;
   ScrY=16;
var
   drawold: boolean;
begin
//обработка клавиатуры
   drawold:=drawnow;
   drawnow:=true;
   case UpCase(Key) of
      'A': Map.Scroll.GX:=Map.Scroll.GX-ScrX;
      'D': Map.Scroll.GX:=Map.Scroll.GX+ScrX;
      'W': Map.Scroll.GY:=Map.Scroll.GY-ScrY;
      'S': Map.Scroll.GY:=Map.Scroll.GY+ScrY;
      else drawnow:=drawold;
   end;
   Paint1MouseMove(self, mouseshift, mousex, mousey);
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if (Key=minimapKey) and
      not minimap then
   begin
      minimap:=true;
      drawnow:=true;
   end;
//
end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if (Key=minimapKey) and
      minimap then
   begin
      minimap:=false;
      Paint1MouseMove(self, mouseshift, mousex, mousey);
      drawnow:=true;
   end;
//
end;

procedure TMainForm.SetMouseCoord(x1, y1: integer);
begin
   mousex:=x1;
   mousey:=y1;
//   mousex:=mouse.CursorPos.X-Self.Left-Self.ClientRect.Left-Paint1.Left-4;
//   mousey:=mouse.CursorPos.Y-Self.Top-Self.ClientRect.Top-Paint1.Top-22;
   absmousex:=x1+Map.Scroll.GX;
   absmousey:=y1+Map.Scroll.GY;

   StatusBar.Panels[1].Text:='X:'+IntToStr(pos_x)+' Y:'+IntToStr(pos_Y);
end;

procedure TMainForm.CheckMouseRect;
var
   px, py: integer;
begin
   px:=Map.Scroll.GetI(mousex);
   py:=Map.Scroll.GetJ(mousey);
   if (px<>pos_x) or
      (py<>pos_y) then
         //стираем mouserect со старого места, рисуем на новом...
         if not drawnow and
         	not minimap and
            not drag then
            begin
         		DrawMouseRect(Paint1.Canvas);
         		pos_x:=px; pos_y:=py;
         		DrawMouseRect(Paint1.Canvas);
      		end else
            begin
               pos_x:=px;pos_y:=py;
            end;
end;

procedure TMainForm.DrawMouseRect(canvas: TCanvas);
const
   ellipsew = 8;
   ellipseh = 8;
   penwidth = 1;
begin
   with Canvas, Map.Scroll do
   begin
   	Pen.Mode:=pmXor;
   	Pen.Color:=clWhite;
      Pen.Width:=penwidth;
      Brush.Style:=bsClear;
   	RoundRect(GetX(pos_x), GetY(pos_y), GetX(pos_x)+32, GetY(pos_y)+16, ellipsew, ellipseh);
   end;
end;

function TMainForm.Multiselect: boolean;
begin
   Result:=(dragpoints<>nil) and (High(dragpoints)>=1);
end;

procedure TMainForm.Paint1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
   cp : TClickPoint;
begin
   MouseShift:=Shift;

   SetMouseCoord(x, y);
   select:=false;
   drag:=false;
   if Button<>mbLeft then Exit;
 	if minimap then
  	begin
     	with Map, AdvScroll do
      begin
     		if Scroll.CenterToIJ(GetI(X), GetJ(Y)) then
        		drawnow:=true;
  		end;
      minidrag:=true;
  	end else
   if (Shift-[ssLeft, ssShift]=[]) and (Mode in [emObjects, emLinks]) then
     begin
     	if ssShift in Shift then
     	begin
     	  	cp:=GetPointByXY(absmousex, absmousey, false, true, Mode=emLinks);
        	if (cp<>nil) and ((dragpoints=nil) or (ptSelective in dragpoints[0].pType)) then
        	begin
   	  		TogglePoint(cp, dragpoints);
         	SelectPoints(absmousex, absmousey, dragpoints);
        		drawnow:=true;
        	end;
     	end else
        if multiselect then
        begin
           if (IsPointInXY(absmousex, absmousey, dragpoints)<>nil) or
           	  IsSelectedPoint(GetPointByXY(absmousex, absmousey, ssAlt in Shift, true, Mode=emLinks), dragpoints)
              then StartDrag
           else
           begin
           	  dragpoints:=nil;
              drawnow:=true;
           end;
        end else
        begin
         SetLength(dragpoints, 1);
        	dragpoints[0]:=GetPointByXY(absmousex, absmousey, ssAlt in Shift, false, Mode=emLinks);
        	if dragpoints[0]<>nil then
        	begin
           StartDrag;
           drawnow:=true;
           {if ptMove in DragPoints[0].pType then
              Screen.Cursor:=crSizeAll;}
        	end else
         begin
         	dragpoints:=nil;//вообще ничего не выделили - значит надо начать выделение
        		select:=true;
        		rx1:=absmousex;
        		ry1:=absmousey;
        		rx2:=rx1;ry2:=ry1;
         end;
        end;//if ... else multiselect
     end; //ТОЛЬКО ЛЕВАЯ КНОПКА
   case Mode of
      emObjects:
      if ssDouble in Shift then
   	begin
     //двойной щелчок по одному объекту
     		cp:=GetPointByXY(absmousex, absmousey, false, Mode=emLinks);
      	if (dragpoints<>nil) and (cp=dragpoints[0]) and
            (cp.obj is TCustomMapObj) then
         	ShowObjProps(TCustomMapObj(dragpoints[0].Obj));
   	end else
     //ВЫДЕЛЕНИЕ И НАЧАЛО ПЕРЕНОСА ОДНОГО ОБЪЕКТА
     	if ssCtrl in Shift then
     	begin
     //ВЫДЕЛЕНИЕ НЕСКОЛЬКИХ ОБЪЕКТОВ
         select:=true;
        	rx1:=absmousex;
        	ry1:=absmousey;
        	rx2:=rx1;ry2:=ry1;
        	dragpoints:=nil;
//        dragpoints:=GetPointsInRect(rx1, ry1, rx2, ry2);
     	end;
 		emLinks:
      if (ssCtrl in Shift) then
        begin
        //emLinks
     	  	cp:=GetPointByXY(absmousex, absmousey, false, true, Mode=emLinks);
         if (cp<>nil) then
         begin
         	if (dragpoints<>nil) then
            	link_OneWay(cp);
            SetLength(dragpoints, 1);
            dragpoints[0]:=cp;
         end;
        end else
      if (ssAlt in Shift) then
      begin
			cp:=GetPointByXY(absmousex, absmousey, false, true, Mode=emLinks);
         if (cp<>nil) then
         begin
         	if (dragpoints<>nil) then
            	link_Delete(cp);
            SetLength(dragpoints, 1);
            dragpoints[0]:=cp;
         end;
      end;
      emBricks:
      if (brksel<>nil) and (ssLeft in Shift) then
      begin
         if (pos_x>=rx1) and (pos_x<=rx2) and
            (pos_y>=ry1) and (pos_y<=ry2) then
            StartDrag
         else
         begin
         	PlaceBrk;
            drawnow:=true;
         end;
      end
      else
		if Shift-[ssShift, ssAlt, ssDouble]=[ssLeft] then
     	begin
         if ssAlt in Shift then
            SetBrk(Map.Brk[pos_x, pos_y])
         else
        	if ssShift in Shift then
        	begin
           	if not Map.Brk.Cleared[pos_x, pos_y] then
           	begin
           		Map.Brk[pos_x, pos_y]:=0;
               modified:=true;
               drawnow:=true;
           	end;
        	end
         	else begin
            		  Map.Brk[pos_x, pos_y]:=selbrk;
                    if brkBlock then
                    	Map.brk.Blocked[pos_x, pos_y]:=true
                    else
                    	if brkFront then Map.brk.Front[pos_x, pos_y]:=true;
                    drawnow:=true;
                    modified:=true;
         		  end;
     	end else
      if Shift-[ssCtrl]=[ssLeft] then
      begin
         PlaceBrk;//вообще ничего не выделели - значит надо начать выделение
     		select:=true;
     		rx1:=absmousex div 32;
     		ry1:=absmousey div 16;
     		rx2:=rx1;ry2:=ry1;
         drawnow:=true;
      end;
      emLights:
      if Map.Lights<>nil then
      begin
      	if ssDouble in Shift then
   		begin
     		//двойной щелчок по одному объекту
     			light:=GetLPointByXY(absmousex, absmousey);
            if light<>nil then
         		ShowLightProps(light.obj);
   		end else
         if Shift-[ssLeft]=[] then
         begin
     			light:=GetLPointByXY(absmousex, absmousey);
            if light<>nil then
            begin
               drag:=true;
               drawnow:=true;
               light.Select(absmousex, absmousey);
            end;
         end else
         begin
         	light:=nil;
            drawnow:=true;
         end;
      end;
   end; //case
	CheckObjs;
end;

procedure TMainForm.Paint1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
//
  MouseShift:=Shift;
  SetMouseCoord(x, y);
  CheckMouseRect;

  if minimap then
  begin
     if (Shift=[ssLeft]) then
     with Map, AdvScroll do
 	 	begin
     		if Scroll.CenterToIJ(GetI(X), GetJ(Y)) then
        		drawnow:=true;
  		end;
  end else
  case Mode of
     emObjects, emLinks:
     begin
     	if select and (ssLeft in Shift) then
     	begin
        	rx2:=absMousex;ry2:=absMousey;
        	drawnow:=true;
     	end else select:=false;

     	if drag then
        	if (ssLeft in Shift) then
        	begin
        	  	if MovePoints(absmousex, absmousey, dragpoints) then
            begin
              	drawnow:=true;
					modified:=true;
            end;
        	end else EndDrag;
     end;//emObjects
     emBricks:
		if (Shift-[ssShift, ssAlt, ssDouble, ssCtrl]=[ssLeft]) then
     		begin
            if select then
            begin
               rx2:=absmousex div 32; ry2:=absmousey div 16;
               drawnow:=true;
            end else
            if drag then
            begin
               drawnow:=drawnow or ((rx1<>pos_x-dx) or (ry1<>pos_y-dy));
               rx1:=pos_x-dx;
               ry1:=pos_y-dy;
               rx2:=rx1+BrkSel.Width-1;
               ry2:=ry1+BrkSel.Height-1;
					modified:=true;
            end else
            if not minidrag then
            begin
         		if ssAlt in Shift then
            		SetBrk(Map.Brk[pos_x, pos_y])
         		else
        			if ssShift in Shift then
        			begin
           			if not Map.Brk.Cleared[pos_x, pos_y] then
           			begin
           				Map.Brk[pos_x, pos_y]:=0;
               		drawnow:=true;
           			end;
        			end
         			else
               begin
               	Map.Brk[pos_x, pos_y]:=selbrk;
                  if brkBlock then
                  	Map.brk.Blocked[pos_x, pos_y]:=true
                  else
                   	if brkFront then Map.brk.Front[pos_x, pos_y]:=true;
                  drawnow:=true;
                  modified:=true;
               end;
            end;
     		end;
      emLights:
      begin
         if Shift=[ssLeft] then
         begin
            if drag and (light<>nil) then
            begin
               light.ChangeFXY(absmousex, absmousey);
               drawnow:=true;
            end;
         end;
      end;
  	end;//case
end;

procedure TMainForm.Paint1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
   MouseShift:=Shift;

   SetMouseCoord(x, y);
   if Button<>mbLeft then Exit;
   minidrag:=false;
   case Mode of
      emObjects, emLinks:
   begin
   	if select then
      begin
      	if rx1>rx2 then
      	begin
         	x:=rx1;
         	rx1:=rx2;
         	rx2:=x;
      	end;
      	if ry1>ry2 then
      	begin
         	y:=ry1;
         	ry1:=ry2;
         	ry2:=y;
      	end;
      	dragpoints:=GetPointsInRect(rx1, ry1, rx2, ry2, Mode=emLinks);
      	select:=false;
      	drawnow:=true;
   	end;

   	if drag then
      	EndDrag;
      end;//emObjects
   emBricks:
      if Select then
      begin
      	if rx1>rx2 then
      	begin
         	x:=rx1;
         	rx1:=rx2;
         	rx2:=x;
      	end;
      	if ry1>ry2 then
      	begin
         	y:=ry1;
         	ry1:=ry2;
         	ry2:=y;
      	end;
         GetBrk;
         CheckObjs;
         select:=false;
         drawnow:=true;
   	end else
         if (Shift-[ssShift, ssDouble, ssCtrl]=[]) then
            UndoPut;
   emLights:
   	begin
   		if drag then
      		EndDrag;
   	end;
   end; //case
   CheckObjs;
end;

procedure TMainForm.ShowObjProps(Obj: TCustomMapObj);
var
   objFrm: TObjPropFrm;
begin
   case Obj.ObjType of
      otWeapon, otAmmo, otPowerUp, otArmor, otHealth: ObjFrm:=ObjItemProp;
      otRespawn: ObjFrm:=ObjRespawnProp;
      otButton, otTrigger: ObjFrm:=ObjButtonProp;
      otJumppad: ObjFrm:=ObjJumppadProp;
      otElevator: ObjFrm:=ObjElevatorProp;
      otDeathLine: ObjFrm:=ObjDeathLineProp;
      otAreaPain: ObjFrm:=ObjAreaPainProp;
      otAreaPush: ObjFrm:=ObjAreaPushProp;
      otBackBricks: ObjFrm:=ObjBGProp;
      otLightLine: ObjFrm:=ObjLightLineProp;
      otBloodGen: ObjFrm:=ObjBloodGenProp;
      otWeather: ObjFrm:=ObjWeatherProp;
      else ObjFrm:=ObjPropFrm;
   end;
   ObjFrm.Obj:=Obj;
   if ObjFrm.ShowModal=mrOk then modified:=true;
   drawnow:=true;
end;

procedure TMainForm.MapProps1Execute(Sender: TObject);
begin
   if MapPropsFrm.ShowModal=mrOk then modified:=true;
   //на случай ресайза карты :)
   with Map do
   begin
   	Scroll.MaxI:=Brk.Width;
   	Scroll.MaxJ:=Brk.Height;
      FormResize(Self);
   	AdvScroll.MaxI:=Brk.Width;
   	AdvScroll.MaxJ:=Brk.Height;
      Scroll.GX:=Scroll.gx;
      Scroll.GY:=Scroll.gy;
   end;
   drawnow:=true;
end;

procedure TMainForm.EndDrag;
begin
   drag:=false;
   if Mode in [emObjects, emLinks] then
   begin
   	drawnow:=true;
      modified:=true;
   	MovePoints(absmousex, absmousey, dragpoints);
   	UnSelectPoints(dragpoints);
   end;
end;

procedure TMainForm.StartDrag;
begin
   case Mode of
      emObjects, emLinks:
      begin
   		drag:=dragpoints<>nil;
   		SelectPoints(absmousex, absmousey, dragpoints);
   		drawnow:=true;
      end;
      emBricks:
      begin
         drag:=brksel<>nil;
         dx:=pos_x-rx1;
         dy:=pos_y-ry1;
   		drawnow:=true;
      end;
   end;
end;

procedure TMainForm.ScrollBrkResize(Sender: TObject);
var
   max: integer;
begin
   BrkWidth:=(PaintBrk.Width-1) div 33;
   max:=0;
   if Map.BrkTex<>nil then
   	max:=CustomImg.Count;
   if max<Box1.Count then
      max:=Box1.Count;
   BrkHeight:=(max+BrkWidth-1) div BrkWidth;
   PaintBrk.Height:=BrkHeight*17+1;
   if dbufferbrk<>nil then
   begin
      dbufferbrk.Width:=PaintBrk.Width;
      dbufferbrk.Height:=PaintBrk.Height;
   end;
end;

procedure TMainForm.PaintBrkPaint(Sender: TObject);
var
   i, j: integer;
   img: integer;
begin
   if dbufferbrk=nil then
   begin
      dbufferbrk:=TBitmap.Create;
      dbufferbrk.Width:=PaintBrk.Width;
      dbufferbrk.Height:=PaintBrk.Height;
   end;
   with dbufferbrk, canvas do
   begin
      Pen.Color:=clGray;
      Brush.Color:=clGray;
      Brush.Style:=bsSolid;
      Rectangle(0, 0, Width, Height);
      for i:=0 to BrkWidth-1 do
         for j:=0 to BrkHeight-1 do
         begin
            img:=i+j*BrkWidth;
            if img=selbrk then
            begin
               Pen.Color:=clRed;
               Brush.Color:=clRed;
               Brush.Style:=bsSolid;
               Rectangle(i*33, j*17, (i+1)*33+1, (j+1)*17+1);
            end;
            if img>0 then
            if (Map.BrkTex<>nil) and (img<=CustomImg.Count) then
            	CustomImg.Draw(canvas, 1+i*33, 1+j*17, img-1)
           		else if img<=Box1.Count then
               	Box1.Draw(canvas, 1+i*33, 1+j*17, img-1)
                  else Break;
         end;
      PaintBrk.Canvas.CopyRect(Rect(0, 0, width, height), canvas, Rect(0, 0, width, height));
   end;
end;

procedure TMainForm.Splitter1Moved(Sender: TObject);
begin
   FormResize(sender);
   drawnow:=true;
end;

procedure TMainForm.PaintBrkMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   PaintBrkMouseMove(Sender, Shift, X, Y);
end;

procedure TMainForm.PaintBrkMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
   sel: word;
begin
   if Shift=[ssLeft] then
   begin
   	if Mode<>emBricks then
      	BrkModeExecute(BrkMode);
   	sel:=X div 33+(Y div 17)*BrkWidth;
   	if sel<Box1.Count then
   	begin
//      	Inc(sel);
      	SetBrk(sel);
   	end;
   	PaintBrkPaint(sender);
   end;
end;

procedure TMainForm.CheckObjs;
begin
   EditCopy1.Enabled:=(Mode=emObjects) and (dragpoints<>nil) or
   		(Mode=emBricks) and (brksel<>nil) or
         (Mode=emLights) and (light<>nil);
   EditCut1.Enabled:=EditCopy1.Enabled;
   EditPaste1.Enabled:=(Mode=emObjects) and (cobjs<>nil) or
   		(Mode=emBricks) and (brkbuf<>nil) or
         (Mode=emLights) and (lightbuf<>nil);
   EditDelete1.Enabled:=(Mode in [emObjects, emLinks]) and (dragpoints<>nil) or
   		(Mode=emBricks) and (brksel<>nil) or
         (Mode=emLights) and (light<>nil);
   if Mode=emObjects then PlaceBrk;

   wpact_RemoveLink.Enabled:=(high(dragpoints)=1) and
   	(dragpoints[0].obj is TWPObj)	and
      (dragpoints[1].obj is TWPObj);

   //а теперь обновление статусбара
   StatusBar.Panels[2].Text:='';
   if (Mode=emBricks) and (brksel<>nil) then
   	StatusBar.Panels[2].Text:='Selected bricks: '+IntToStr(BrkSel.Width)+'x'+IntToStr(BrkSel.Height);
   if (Mode=emObjects) and (dragpoints<>nil) then
   	StatusBar.Panels[2].Text:='Selected objects: '+IntToStr(length(dragpoints));
   if (Mode=emLights) and (light<>nil) then
   	StatusBar.Panels[2].Text:='Selected lights: 1';

   StatusBar.Panels[3].Text:='';
   if (dragpoints<>nil) then
   	StatusBar.Panels[3].Text:=HelpObj(TCustomMapObj(dragpoints[0].obj));

   StatusBar.Panels[4].Text:='';
   if brkbuf<>nil then
   	StatusBar.Panels[4].Text:='Bricks buffer: '+IntToStr(BrkBuf.Width)+'x'+IntToStr(BrkBuf.Height);
   StatusBar.Panels[5].Text:='';
   if cobjs<>nil then
   	StatusBar.Panels[5].Text:='Objects buffer: '+IntToStr(length(cobjs))
   else
   begin
   	if lightbuf<>nil then
   		StatusBar.Panels[5].Text:='Light buffer: 1';
   end;
end;

procedure TMainForm.SetBrk(brk: word);
begin
	drawbrknow:=true;
   if brk>0 then
   begin
  	 	if (selbrk=0) then
   		SetBrkMask(true, false)
   end else SetBrkMask(false, false);

   selbrk:=brk;
end;

procedure TMainForm.EditDelete1Execute(Sender: TObject);
var
   i: integer;
begin
   if drag then
      EndDrag;
   case Mode of
      emObjects, emLinks:
 		if dragpoints<>nil then
      begin
   		for i:=Low(dragpoints) to High(dragpoints) do
         begin
            with Map do
            if dragpoints[i].Obj is TCustomMapObj then
         		Obj.Delete(Obj.IndexOf(TCustomMapObj(dragpoints[i].Obj)))
            else	if dragpoints[i].Obj is TWPObj then
            begin
            	WP.Delete(dragpoints[i].Obj);
               if WP.Count=0 then
               begin
                  Entries.Delete(Entries.IndexOf(WP));
                  WP.Free;
                  WP:=nil;
               end;
            end;
         	DeletePoints(dragpoints[i].Obj);
         end;
      	drawnow:=true;
   		dragpoints:=nil;
   	end;    //Objects
      emBricks:
      if BrkSel<>nil then
      begin
         BrkSel.Free;
         BrkSel:=nil;
         drawnow:=true;
      end;    //Bricks
      emLights:
      if light<>nil then
      begin
         DeleteLPoints(light.Obj);
         Map.Lights.Delete(map.Lights.IndexOf(light.Obj));
         light:=nil;
         drawnow:=true;
      end;
   end; //case
   CheckObjs;
end;

procedure TMainForm.Add1Click(Sender: TObject);
var
   struct: TMapObjStruct;
   tag: integer;
begin
   Mode:=emObjects;
   ObjMode.Checked:=true;
   FillChar(struct, sizeof(struct), 0);
   with struct do
   begin
   	x:=absmousex div 32;
   	y:=absmousey div 16;
      target:=0;
   	width:=1;
   	height:=1;
      tag:=TMenuItem(sender).Tag;
      case tag of
         0..99:
   			objtype:=TObjType(tag);
         100..102: objtype:=otArmor;
         200..203: objtype:=otHealth;
         300..309: objtype:=otWeapon;
         400..409: objtype:=otAmmo;
         500..501: objtype:=otJumppad;
         600..606: objtype:=otPowerUp;
      end;
   	case objtype of
      	otRespawn, otTriangle: begin end;
         otButton: begin wait:=25; end;
         otTeleport: begin gotox:=x+2; gotoy:=y; end;
         otJumpPad: if tag mod 100=0 then jumpspeed:=jump1 else jumpspeed:=jump2;
         otArmor: ItemID:=16+tag mod 100;
         otHealth: ItemID:=19+tag mod 100;
         otPowerUp: ItemID:=23+tag mod 100;
         otWeapon, otAmmo: begin WeaponID:=tag mod 100;end;
         otNFKDoor: begin wait:=100; opened:=false; active:=1; height:=4; end;
         otTrigger: begin width:=3; height:=3; end;
         otWater:begin width:=6; height:=3; end;
         otDeathLine: begin angle:=0; maxlen:=64; end;
         otElevator: begin elevx:=0; elevy:=2; end;
         otAreaPush: begin pushspeedx:=10; pushspeedy:=0; pushwait:=10; width:=2; height:=3; end;
         otAreaPain: begin paindamage:=10; painwait:=10; height:=2;end;
         otArenaEnd: begin height:=2;end;
         otAreaTeleport, otTeleportWay: begin gotox:=x+4; gotoy:=y; width:=2; height:=3; end;
         otEmptyBricks, otBackBricks: begin width:=4; height:=3; end;
         otLightLine: begin angle:=0; maxlen:=64; orient:=5; end;
         otBloodGen: begin angle:=0; maxlen:=64; bloodtype:=0; bloodwait:=7;bloodcount:=1; end;
         otWeather: begin bloodtype:=0; bloodwait:=5; bloodcount:=1; end;
         else Exit;
      end;
      Map.Obj.Add(struct).SetDefValues;
      drawnow:=true;
   end;
end;

procedure TMainForm.AddWPClick(Sender: TObject);
var
   w: TWPObj;
begin
  	Mode:=emLinks;
 	LinkMode.Checked:=true;
   with Map do
   begin
      if WP=nil then
      begin
         WP:=TWPEntry.Create;
         Entries.Add(WP);
      end;
      w:=WP.Add(pos_x, pos_y, ' ');
      SetLength(dragpoints, 1);
      dragpoints[0]:=w.mainpoint;
      case TComponent(Sender).tag of
         0: w.wp_type:='M';
         1: w.wp_type:='C';
         2: w.wp_type:='S';
      end;
      drawnow:=true;
   end;
end;

procedure TMainForm.BrkModeExecute(Sender: TObject);
begin
   select:=false;
   if drag then EndDrag;
   Mode:=TEditorMode(TAction(Sender).Tag);
   if Mode=emLinks then
   	dragpoints:=nil;
   TAction(Sender).Checked:=true;
   SetDefBrkMask;
   drawnow:=true;
   CheckObjs;
end;

procedure TMainForm.ClearObjsBuffer;
var
   i: integer;
begin
   if cobjs<>nil then
   begin
      for i:=low(cobjs) to high(cobjs) do
         cobjs[i].Free;
      cobjs:=nil;
   end;
end;

procedure TMainForm.CopyObjs(cut: boolean);
var
   i, j, l: integer;
   x, y: word;
begin
   if dragpoints<>nil then
   begin
      if cut and drag then EndDrag;
      if cut then modified:=true;
      if cobjs<>nil then ClearObjsBuffer;
      l:=high(dragpoints)+1;
      SetLength(cobjs, l);
      j:=0;
      x:=Map.Width;
      y:=Map.Height;
      for i:=0 to l-1 do
      if not (ptNoCopy in dragpoints[i].pType) and
      	(dragpoints[i].Obj is TCustomMapObj) then
      begin
         cobjs[j]:=TCustomMapObj.Create(TCustomMapObj(dragpoints[i].Obj).Struct);
         if cobjs[j].x<x then x:=cobjs[j].x;
         if cobjs[j].y<y then y:=cobjs[j].y;
         if cut then
         	with Map.Obj do
            begin
         	 	Delete(IndexOf(dragpoints[i].Obj));
               DeletePoints(dragpoints[i].Obj);
            end;
         Inc(j);
      end;
      if j>0 then
      	SetLength(cobjs, j)
      	else cobjs:=nil;
      for i:=0 to j-1 do
      begin
         cobjs[i].SetX(cobjs[i].x-x);
         cobjs[i].SetY(cobjs[i].y-y);
      end;
   end;
   if cut then dragpoints:=nil;
   drawnow:=drawnow or cut;
   CheckObjs;
end;

procedure TMainForm.PasteObjs;
var
   i, j: integer;
   ob: TCustomMapObj;
begin
	if drag then
     	EndDrag;
   if cobjs<>nil then
   begin
      modified:=true;
      SetLength(dragpoints, high(cobjs)+1);
      j:=0;
      for i:=low(cobjs) to high(cobjs) do
      begin
         ob:=Map.Obj.Add(cobjs[i].Struct);
         ob.SetX(ob.x+pos_x);
         ob.SetY(ob.y+pos_y);
         if ob.mainpoint<>nil then
         begin
         	dragpoints[j]:=TClickPoint(ob.mainpoint);
            Inc(j);
         end;
      end;
      SetLength(dragpoints, j);
      drawnow:=true;
      CheckObjs;
   end;
end;

procedure TMainForm.CopyBrk(cut: boolean);
begin
   if BrkSel=nil then Exit;
   if BrkBuf<>nil then
   begin
      BrkBuf.Free;
      BrkBuf:=nil;
   end;
   if cut then
   begin
   	BrkSel:=nil;
   	BrkBuf:=BrkSel;
   end
   else
      BrkBuf:=TBricksEntry.Create(BrkSel);
end;

procedure TMainForm.PasteBrk;
begin
 	PlaceBrk;
   if BrkBuf<>nil then
   begin
   	rx1:=pos_x;
   	ry1:=pos_y;
   	rx2:=pos_x+BrkBuf.Width-1;
   	ry2:=pos_y+BrkBuf.Height-1;
   	BrkSel:=TBricksEntry.Create(BrkBuf);
      drawnow:=true;
		modified:=true;
   end;
end;

procedure TMainForm.EditCopy1Execute(Sender: TObject);
begin
   case Mode of
      emObjects: CopyObjs(false);
      emBricks: CopyBrk(false);
      emLights:
      if light<>nil then
      begin
         if lightbuf<>nil then
            lightbuf.Free;
         lightbuf:=TlightObj.Create(light.Obj.Struct);
      end;
   end;
   CheckObjs;
end;

procedure TMainForm.EditPaste1Execute(Sender: TObject);
var
   l : TLightObj;
begin
   case Mode of
      emObjects: PasteObjs;
      emBricks: PasteBrk;
      emLights:
      if lightbuf<>nil then
      begin
         l:=Map.Lights.Add(lightbuf.Struct);;
         l.Struct.Pos.X:=absmousex;
         l.Struct.Pos.Y:=absmousey;
         light:=TLightClickPoint(l.centerpoint);
         drawnow:=true;
      end;
   end;
   CheckObjs;
end;

procedure TMainForm.EditCut1Execute(Sender: TObject);
begin
   case Mode of
      emObjects: CopyObjs(true);
      emBricks: CopyBrk(true);
      emLights:
      begin
         EditCopy1Execute(Sender);
         EditDelete1Execute(Sender);
         drawnow:=true;
      end;
   end;
   CheckObjs;
end;

procedure TMainForm.PlaceBrk;
var
   i, j: word;
begin
   if BrkSel<>nil then
   begin
      modified:=true;
      for i:=0 to BrkSel.Width-1 do
         for j:=0 to BrkSel.Height-1 do
         begin
            Map.Brk[i+rx1, j+ry1]:=BrkSel[i, j];
            Map.Brk.Blocked[i+rx1, j+ry1]:=BrkSel.Blocked[i, j];
            Map.Brk.Front[i+rx1, j+ry1]:=BrkSel.Front[i, j];
         end;
      UndoPut;
      BrkSel.Free;
      BrkSel:=nil;
   end;
end;

procedure TMainForm.GetBrk;
var
   i, j: word;
begin
   if BrkSel=nil then
   begin
   	BrkSel:=TBricksEntry.Create(rx2-rx1+1, ry2-ry1+1);
   	for i:=0 to BrkSel.Width-1 do
      	for j:=0 to BrkSel.Height-1 do
         begin
            BrkSel[i, j]:=Map.Brk[i+rx1, j+ry1];
            BrkSel.Blocked[i, j]:=Map.Brk.Blocked[i+rx1, j+ry1];
            BrkSel.Front[i, j]:=Map.Brk.Front[i+rx1, j+ry1];
            Map.Brk[i+rx1, j+ry1]:=0;
            Map.Brk.Blocked[i+rx1, j+ry1]:=false;
            Map.Brk.Front[i+rx1, j+ry1]:=false;
         end;
   end;
end;

procedure TMainForm.BrowsePalBtnClick(Sender: TObject);
begin
   with LoadPalDlg, Map do
   if Execute then
   begin
      modified:=true;
      try
         if BrkTex<>nil then
         	ClearPal;
      	BrkTex:=TBrkTexEntry.Create(FileName);
         Map.Entries.Add(BrkTex);
      	if BrkTex<>nil then
         	LoadPaletteFromBitmap(BrkTex.Bitmap, CustomImg, clBlue, 0, 0);
      	ScrollBrkResize(self);
      	Paint1Paint(self);
      	PaintBrkPaint(self);
      except
         BrkTex:=nil;
      end;

      BrowsePalBtn.enabled:=BrkTex=nil;
      ClearPalBtn.enabled:=BrkTex<>nil;
      SavePalBtn.enabled:=BrkTex<>nil;
   end;
end;

procedure TMainForm.ClearPalBtnClick(Sender: TObject);
begin
   if Map.BrkTex<>nil then
      modified:=true;
   Map.ClearPal;
   BrowsePalBtn.enabled:=true;
   ClearPalBtn.enabled:=false;
   SavePalBtn.enabled:=false;
end;

procedure TMainForm.SavePalBtnClick(Sender: TObject);
begin
//
   with SavePalDlg, Map do
   if (BrkTex<>nil) and Execute then
      begin
         modified:=true;
         BrkTex.Bitmap.SaveToFile(FileName);
      end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   CanClose:=SaveQuery;
   ActionManager1.SaveToFile(menufile);
end;

procedure TMainForm.Action1Execute(Sender: TObject);
begin
   AboutBox.ShowModal;
end;

procedure TMainForm.RunActExecute(Sender: TObject);
begin
//кнопка RUN!!!
	ShellExecute(handle, 'open', PChar(tfkpath+'run.exe'), pchar(' +game TA +map '+ExtractFileName(file_name)), pchar(tfkpath), SW_HIDE);
end;

procedure TMainForm.ShowLightProps(lightobj: TLightObj);
begin
   if light<>nil then
   begin
      colorDlg.Color:=light.obj.WColor;
      if ColorDlg.Execute then
      begin
         light.obj.WColor:=ColorDlg.Color;
      	drawnow:=true;
      end;
   end;
end;

procedure TMainForm.AddLight1Click(Sender: TObject);
var
   l: TLightObj;
   struct: TLightObjStruct;
begin
   with Map do
   begin
      Mode:=emLights;
      LightsMode.Checked:=true;
   	if Lights=nil then
   	begin
      	Lights:=TLightsEntry.Create;
      	Entries.Add(Lights);
   	end;
      struct.Pos.X:=absmousex;
      struct.Pos.Y:=absmousey;
      struct.Radius:=100;
      Fillchar(struct.color, 3, 255);
      l:=Lights.Add(struct);
      light:=TLightClickPoint(l.centerpoint);
   	drawnow:=true;
   end;
end;

procedure TMainForm.GenLightExecute(Sender: TObject);
begin
//генерация лайтмапы.
   LMFrm.ShowModal;
end;

procedure TMainForm.GenMapExecute(Sender: TObject);
begin
   NewFile1Execute(self);
   if not modified then
 		GenMapFrm.ShowModal;
   with Map do
   begin
   	Scroll.MaxI:=Brk.Width;
   	Scroll.MaxJ:=Brk.Height;
      FormResize(Self);
   	AdvScroll.MaxI:=Brk.Width;
   	AdvScroll.MaxJ:=Brk.Height;
      Scroll.GX:=Scroll.gx;
      Scroll.GY:=Scroll.gy;
   end;
   drawnow:=true;
end;

procedure TMainForm.BrickBlActExecute(Sender: TObject);
begin
   BrkModeExecute(BrkMode);
   if Sender=BrickBlAct then
   	SetBrkMask(not brkblock, false);
   if Sender=BrickFrontAct then
      SetBrkMask(false, true);
end;

procedure TMainForm.SetBrkMask(block, front: boolean);
begin
   brkblock:=block;
   brkfront:=front;
   BrickBlAct.Checked:=block;
   BrickFrontAct.Checked:=Front;
end;

procedure TMainForm.SetDefBrkMask;
begin
   if selbrk>0 then SetBrkMask(true, false)
   else SetBrkMask(false, false);
end;

//игры с Undo- буфером

procedure TMainForm.UndoClear;
begin
   undoind:=0;
   UndoDeleteNext;
end;

procedure TMainForm.UndoDeleteNext;
var
   i: integer;
begin
   for i:=undoind+1 to undocount do
      if UndoBuf[i]<>nil then
      UndoBuf[i].Free;
   undocount:=undoind;
end;

procedure TMainForm.UndoPut;
var
   i: integer;
begin
   if undoind=high(undobuf) then
   begin
   //циклический сдвиг
      UndoBuf[1].Free;
      for i:=1 to undocount-1 do
         UndoBuf[i]:=UndoBuf[i+1];
      UndoBuf[undocount]:=nil;
      dec(undoind);
      dec(undocount);
   end;
   UndoDeleteNext;
   Inc(undoind);
   Inc(undocount);
   UndoBuf[undocount]:=TBricksEntry.Create(Map.Brk);
   undoind:=undocount;
end;

procedure TMainForm.UndoSet(ind: integer);
begin
   if (ind>=1) and (ind<=undocount) then
   begin
   	Map.Brk.CopyFrom(UndoBuf[ind]);
		undoind:=ind;
   end;
end;

//Undo Execute

procedure TMainForm.EditUndoExecute(Sender: TObject);
var
   ind: integer;
begin
   if Mode<>emBricks then Exit;
   ind:=undoind+TAction(Sender).Tag;
   UndoSet(ind);
   drawnow:=true;
end;

procedure TMainForm.link_Double(cp: TClickPoint);
var
   i: integer;
begin
   for i:=0 to Length(dragpoints)-1 do
   begin
      dragpoints[i].obj.ActionLink(cp.obj);
      cp.obj.ActionLink(dragpoints[i].obj);
   end;
   SetLength(dragpoints, 1);
   dragpoints[0]:=cp;
   drawnow:=true;
end;

procedure TMainForm.link_OneWay(cp: TClickPoint);
var
   i: integer;
begin
   for i:=0 to Length(dragpoints)-1 do
      dragpoints[i].obj.ActionLink(cp.obj);
   SetLength(dragpoints, 1);
   dragpoints[0]:=cp;
   drawnow:=true;
end;

procedure TMainForm.wpact_RemoveLinkExecute(Sender: TObject);
var
   i, j: integer;
begin
   if dragpoints<>nil then
   for i:=0 to Length(dragpoints)-1 do
      if dragpoints[i].Obj is TWPObj then
      	for j:=0 to Length(dragpoints)-1 do
            TWPObj(dragpoints[i].Obj).way_Delete(TWPObj(dragpoints[j].obj));
   drawnow:=true;
end;

procedure TMainForm.link_Delete(cp: TClickPoint);
var
   j: integer;
begin
   for j:=0 to Length(dragpoints)-1 do
      if dragpoints[j].Obj is TWPObj then
      begin
//      	TWPObj(cp.Obj).way_Delete(TWPObj(dragpoints[j].obj));
      	TWPObj(dragpoints[j].obj).way_Delete(TWPObj(cp.Obj));
      end;
   drawnow:=true;
end;

end.
