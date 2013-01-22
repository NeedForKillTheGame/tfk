unit TFKEntries;

interface

(***************************************)
(*  TFK Radiant  module version 1.02   *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

uses Classes, Graphics, SysUtils, MyEntries, MapObj_Lib, LightMap_Lib,
	WP;

const
   defHead : TMapHeader1=
(MapType: 'TFKM'; ECount:1; Version:1; Author:'TFK'; Name: 'TFKMap');

type
 TRGBA = packed record
  R, G, B, A: Byte;
 end;

type
   TBrick= word;//2 bytes на один брик. первый - сам брик. второй - проходим ли брик :)
   //0 - брик проходим всегда

   //бит проходимости. Будут активно использоваться.
   TBrickBlock = array [0..1] of boolean;

   //так - на брики у нас два байта.
   //ЗДЕСЬ ОПИСАН ВТОРОЙ БАЙТ:

   //0. Проходимость (если 0, то проходим, и прорисовывается с альфой)
   //1. Маска (если 1, то брик передний и прорисовывается спереди как непроходимый)
   //2-7. Резерв - для компиляции чего-нибудь буду использовать. например ассоциативная
   //память на объекты ;)))

type
   TBricksEntry =
   class(TSimpleEntry)
         constructor Create(Head_: TEntryHead; var F: File);overload;
         constructor Create(Width_, Height_: integer);overload;
         constructor Create(B: TBricksEntry);overload;
  	protected
    function GetHeight: integer;
    function GetWidth: integer;
    function GetBricks(x, y: integer): byte;
    procedure SetBricks(x, y: integer; const Value: byte);
    function GetBrickBl(x, y: integer): boolean;
    procedure SetBrickBl(x, y: integer; const Value: boolean);
    function GetFront(x, y: integer): boolean;
    procedure SetFront(x, y: integer; const Value: boolean);

    function GetCleared(x, y: integer): boolean;

    function GetHead: TEntryHead;override;
      public
         class function EntryClassName: TEntryClassName;

         property Brick[x, y: integer]:byte read GetBricks write SetBricks;default;
         property Blocked[x, y: integer]:boolean read GetBrickBl write SetBrickBl;
         property Front[x, y: integer]:boolean read GetFront write SetFront;
         property Cleared[x, y: integer]: boolean read GetCleared;

         property Width: integer read GetWidth;
         property Height: integer read GetHeight;

    		procedure Clear;
    		procedure SetSize(newWidth, newHeight: integer);

         procedure CopyFrom(B: TBricksEntry);
   end;

/////
   TMapObjEntry =
    class(TSimpleEntry)
      constructor Create(Head_: TEntryHead; var F: File);overload;
      constructor Create;overload;
      destructor Destroy;override;
  protected
      objs: TList;
     	function GetObj(i: integer): TCustomMapObj;
      function GetHead: TEntryHead;override;
    public
      class function EntryClassName: TEntryClassName;
		procedure WriteToFile(var F: File);override;

       function Count: integer;
       property Obj[i: integer]: TCustomMapObj read GetObj;default;

       function Add(struct: TMapObjStruct): TCustomMapObj;
       function IndexOf(obj_: TObject): integer;
       procedure Delete(ind: integer);
       procedure Exchange(ind1, ind2: integer);
    end;

   TBrkTexEntry =
   class(TCustomEntry)
      constructor Create(Head_: TEntryHead; var F: File);overload;
      constructor Create(Head_:TEntryHead; Stream: TMemoryStream; masccolor : TColor = clBlue);overload;
      constructor Create(FileName: string);overload;
      destructor Destroy;override;
  protected
      function GetHead: TEntryHead;override;
    public
      Bitmap: TBitmap;
      class function EntryClassName: TEntryClassName;
		procedure WriteToFile(var F: File);override;
   end;

////////////////////

   TTFKMap = class(TCustomMap)

  private
    function GetHeight: Word;
    function GetWidth: Word;
  public
//
   Brk: TBricksEntry;
   Obj: TMapObjEntry;
   BrkTex: TBrkTexEntry;
   Lights: TLightsEntry;
   WP    : TWPEntry;

   procedure Clear;override;
   procedure NewMap;virtual;

   procedure AfterLoad;override;
   procedure BeforeLoad;override;

   function CreateEntry(head: TEntryHead; var f: File): TCustomEntry;override;

   property Width  : Word read GetWidth;
   property Height : Word read GetHeight;
             end;

implementation

{ TBricksEntry }

procedure TBricksEntry.Clear;
begin
   buf:=nil;
   fhead.size:=0;
   fhead.maxx:=0;
   fhead.maxy:=0;
end;

constructor TBricksEntry.Create(Head_: TEntryHead; var F: File);
var
    i, j: integer;
begin
   inherited Create(Head_, F);
   if head_.version=1 then
   begin
   //ну что, ставим блокировку правильную
      for i:=0 to Width-1 do
         for j:=0 to Height-1 do
         begin
            Blocked[i, j]:=Brick[i, j]>0;
            Front[i, j]:=false;
         end;
   end;
end;

constructor TBricksEntry.Create(Width_, Height_: integer);
begin
   inherited Create;
   SetSize(Width_, Height_);
end;

procedure TBricksEntry.CopyFrom(B: TBricksEntry);
begin
   fhead:=B.Head;
   SetSize(B.Width, B.Height);
   Move(B.buf[0], buf[0], fhead.size);
end;

constructor TBricksEntry.Create(B: TBricksEntry);
begin
   inherited Create;
   CopyFrom(B);
end;

class function TBricksEntry.EntryClassName: TEntryClassName;
begin
   Result:='BricksV1';
end;

function TBricksEntry.GetBrickBl(x, y: integer): boolean;
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      	Result:=buf[(y*width+x)*SizeOf(TBrick)+1] and 1>0
      else Result:=False;
end;

function TBricksEntry.GetBricks(x, y: integer): byte;
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      	Result:=buf[(y*width+x)*SizeOf(TBrick)]
         else Result:=head.defaultBrick;
end;

function TBricksEntry.GetCleared(x, y: integer): boolean;
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      	Result:=(Brick[x, y]=0) and not blocked[x, y] and not front[x, y]
      else Result:=true;
end;

function TBricksEntry.GetFront(x, y: integer): boolean;
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      	Result:=buf[(y*width+x)*SizeOf(TBrick)+1] and 2>0
      else Result:=False;
end;

function TBricksEntry.GetHead: TEntryHead;
begin
   fhead.EntryClass:=EntryClassName;
   fhead.version:=2;
   Result:=fhead;
end;

function TBricksEntry.GetHeight: integer;
begin
   Result:=head.maxy;
end;

function TBricksEntry.GetWidth: integer;
begin
   Result:=head.maxx;
end;

procedure TBricksEntry.SetBrickBl(x, y: integer; const Value: boolean);
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      begin
         if Value then
         	buf[(y*width+x)*SizeOf(TBrick)+1]:=
               buf[(y*width+x)*SizeOf(TBrick)+1] or 1
         else buf[(y*width+x)*SizeOf(TBrick)+1]:=buf[(y*width+x)*SizeOf(TBrick)+1] and not 1;
      end;
end;

procedure TBricksEntry.SetBricks(x, y: integer; const Value: byte);
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      begin
      	buf[(y*width+x)*SizeOf(TBrick)]:=value;
      	buf[(y*width+x)*SizeOf(TBrick)+1]:=0;
      end;
end;

procedure TBricksEntry.SetFront(x, y: integer; const Value: boolean);
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      begin
         if Value then
         	buf[(y*width+x)*SizeOf(TBrick)+1]:=
               buf[(y*width+x)*SizeOf(TBrick)+1] or 2
         else buf[(y*width+x)*SizeOf(TBrick)+1]:=buf[(y*width+x)*SizeOf(TBrick)+1] and not 2;
      end;
end;

procedure TBricksEntry.SetSize(newWidth, newHeight: integer);
begin
   buf:=nil;
   fhead.maxx:=newWidth;
   fhead.maxy:=newHeight;
   SetBufSize(SizeOf(TBrick)*newWidth*newHeight);
end;

{ TMapObjEntry }

function TMapObjEntry.Add(struct: TMapObjStruct): TCustomMapObj;
begin
   case struct.ObjType of
      otRespawn: Result:=TRespawnObj.Create(struct);
      otJumpPad: Result:=TJumpPadObj.Create(struct);
      otTeleport: Result:=TTeleportObj.create(struct);
      otAreaTeleport: Result:=TAreaTeleportObj.create(struct);
      otButton: Result:=TButtonObj.Create(struct);
      otTrigger, otWater, otLava, otAreaPush, otAreaPain, otArenaEnd, otWeather: Result:=TAreaObj.create(struct);
      otBackBricks, otEmptyBricks: Result:=TCustomMapObj.Create(struct);//всё, теперь они заменены
      otNFKDoor: Result:=TNFKDoor.Create(struct);
      otWeapon, otAmmo, otHealth, otArmor, otPowerup: Result:=TItemObj.create(struct);
      otDeathLine, otLightLine, otBloodGen: Result:=TDeathLine.Create(struct);
      otElevator: Result:=TElevator.Create(struct);
      otTriangle: Result:=TTriangleObj.Create(struct);
      otTeleportWay: Result:=TTeleportWayObj.Create(struct);
      else Result:=TCustomMapObj.create(struct);
   end;
   objs.Add(result);
end;

function TMapObjEntry.Count: integer;
begin
   Result:=objs.Count;
end;

constructor TMapObjEntry.Create(Head_: TEntryHead; var F: File);
var
   i: integer;
   struct: PMapObjStruct;

begin
   inherited Create(head_, F);
   Objs:=TList.Create;
   for i:=0 to head_.size div SizeOf(TMapObjStruct)-1 do
   begin
      struct:=@buf[i*SizeOf(TMapObjStruct)];
      Add(struct^);
   end;
end;

constructor TMapObjEntry.Create;
begin
   inherited Create;
   Objs:=TList.Create;
end;

procedure TMapObjEntry.Delete(ind: integer);
begin
   if (ind>=0) and (ind<objs.count) then
   begin
      obj[ind].Free;
      objs.Delete(ind);
   end;
end;

destructor TMapObjEntry.Destroy;
begin
   while count>0 do
      Delete(0);
  inherited;
end;

class function TMapObjEntry.EntryClassName: TEntryClassName;
begin
   Result:='ObjectsV1';
end;

procedure TMapObjEntry.Exchange(ind1, ind2: integer);
begin
   Objs.Exchange(ind1, ind2);
end;

function TMapObjEntry.GetHead: TEntryHead;
begin
   fhead.EntryClass:=EntryClassName;
   fhead.size:=Count*SizeOf(TMapObjStruct);
   Result:=fhead;
end;

function TMapObjEntry.GetObj(i: integer): TCustomMapObj;
begin
   Result:=TCustomMapObj(Objs[i]);
end;

function TMapObjEntry.IndexOf(obj_: TObject): integer;
begin
   Result:=Objs.IndexOf(obj_);
end;

procedure TMapObjEntry.WriteToFile(var F: File);
var
   i: integer;
   struct:TMapObjStruct;
begin
   GetHead;
   BlockWrite(f, fhead, SizeOf(fhead));

   for i:=0 to Count-1 do
   begin
   	struct:=Obj[i].Struct;
      BlockWrite(f, struct, SizeOf(struct));
   end;
end;

{ TTFKMap }

procedure TTFKMap.Clear;
begin
   inherited Clear;
   fhead:=defHead;
end;

procedure TTFKMap.AfterLoad;
var
   i, j, k: integer;
begin
   if Brk=nil then
   begin
      Brk:=TBricksEntry.Create(20, 30);
      Entries.Add(Brk);
   end;
   if Obj=nil then
   begin
      Obj:=TMapObjEntry.Create;
      Entries.Add(Obj);
   end;
   //а теперь проверка на backbricks и emptybricks
   k:=0;
   with Obj do
   while k<Count do
   begin
      with Obj[k] do
         if ObjType = otBackBricks then
   begin
      for i:=struct.x to struct.x+struct.width-1 do
         for j:=struct.y to struct.y+struct.height-1 do
         begin
            Brk.Blocked[i, j]:=false;
            if struct.plane>0 then
               Brk.Front[i, j]:=true;
         end;
      Delete(k);
   end else
   	if ObjType = otEmptyBricks then
   begin
      for i:=x to x+width-1 do
         for j:=y to y+height-1 do
            Brk.Blocked[i, j]:=true;
      Delete(k);
   end else Inc(k);
   end;
end;

function TTFKMap.GetHeight: Word;
begin
   Result:=Brk.Height;
end;

function TTFKMap.GetWidth: Word;
begin
   Result:=Brk.Width;
end;

procedure TTFKMap.NewMap;
begin
   BeforeLoad;
   Clear;
   AfterLoad;
end;

function TTFKMap.CreateEntry(head: TEntryHead; var f: File): TCustomEntry;
begin
   if (head.EntryClass=TBricksEntry.EntryClassName) then
      if TBricksEntry.IsValidVersion(head.version) then
      begin
      	Brk:=TBricksEntry.Create(head, f);
         Result:=Brk;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TMapObjEntry.EntryClassName) then
      if TMapObjEntry.IsValidVersion(head.version) then
      begin
      	Obj:=TMapObjEntry.Create(head, f);
         Result:=Obj;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TBrkTexEntry.EntryClassName) then
      if TBrkTexEntry.IsValidVersion(head.version) then
      begin
      	BrkTex:=TBrkTexEntry.Create(head, f);
         Result:=BrkTex;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TLightsEntry.EntryClassName) then
      if TLightsEntry.IsValidVersion(head.version) then
      begin
      	Lights:=TLightsEntry.Create(head, f);
         Result:=Lights;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TWPEntry.EntryClassName) then
      if TWPEntry.IsValidVersion(head.version) then
      begin
      	WP:=TWPEntry.Create(head, f);
         Result:=WP;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else Result:=TSimpleEntry.Create(head, f);
end;

procedure TTFKMap.BeforeLoad;
begin
   Brk:=nil;Obj:=nil;BrkTex:=nil;Lights:=nil;WP:=nil;
end;

{ TBrkTexEntry }

constructor TBrkTexEntry.Create(Head_: TEntryHead; var F: File);
var
   i: integer;
   x, y: integer;
   color:TColor;
   col: TRGBA absolute color;
begin
   inherited;
   Bitmap:=TBitmap.Create;
   Bitmap.Width:=32*fhead.TexCount;
   Bitmap.Height:=16;
   for i:=0 to fhead.TexCount-1 do
      for y:=15 downto 0 do
      	for x:=i*32 to i*32+31 do
         begin
            BlockRead(f, color, 4);
            //сдвиг
            col.A:=0;
            Bitmap.Canvas.Pixels[x, y]:=color;
         end;
end;

constructor TBrkTexEntry.Create(FileName: string);
begin
   Bitmap:=TBitmap.Create;
   Bitmap.LoadFromFile(FileName);
   fhead.TEXCount:=(Bitmap.Width div 32)*(Bitmap.Height div 16);
   fhead.size:=fhead.TEXCount*32*16*4;
end;

constructor TBrkTexEntry.Create(Head_: TEntryHead; Stream: TMemoryStream; masccolor : TColor);
var
   i, j: integer;
begin
   fhead:=head_;
   fhead.size:=Stream.Size;
   Bitmap:=TBitmap.Create;
   Bitmap.LoadFromStream(Stream);
   if masccolor<>clBlue then
  	 	for j:=0 to Bitmap.Height-1 do
         for i:=0 to Bitmap.Width-1 do
            if Bitmap.Canvas.Pixels[i, j]=masccolor then
               Bitmap.Canvas.Pixels[i, j]:=clBlue
               else
            if Bitmap.Canvas.Pixels[i, j]=clBlue then
               Bitmap.Canvas.Pixels[i, j]:=$FE0000;
  fhead.TEXCount:=(Bitmap.Width div 32)*(Bitmap.Height div 16);
   fhead.size:=fhead.TEXCount*32*16*4;
end;

destructor TBrkTexEntry.Destroy;
begin
   Bitmap.Free;
  inherited;
end;

class function TBrkTexEntry.EntryClassName: TEntryClassName;
begin
   Result:='BrkTexV1';
end;

function TBrkTexEntry.GetHead: TEntryHead;
begin
   fhead.EntryClass:=EntryClassName;
   fhead.size:=fhead.TEXCount*32*16*4;
   Result:=fhead;
end;

procedure TBrkTexEntry.WriteToFile(var F: File);

var
   tex, x, y, i, j: integer;
   color: integer;
   col: TRGBA absolute color;
begin
  inherited;
   if Bitmap<>nil then
   for tex:=0 to fhead.TexCount-1 do
   begin
      x:=32*(tex mod (Bitmap.Width div 32));
      y:=16*(tex div (Bitmap.Width div 32));
      //пишем в файл текстуру № Tex:)
      for j:=Y+15 downto Y do
         for i:=X to X+31 do
         begin
            color:=Bitmap.Canvas.Pixels[i, j];
            if (col.B=255) and (col.G=0) and
               (col.R=0) then
               col.A:=0
               else col.A:=255;
            BlockWrite(F, color, 4);
         end;
   end;
end;

end.
