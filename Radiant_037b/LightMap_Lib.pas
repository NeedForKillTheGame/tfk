unit LightMap_Lib;

interface

//генерация lightmaps в радианте...

uses Classes, Graphics, SysUtils, MyEntries, Windows;

//эта секция только для создания лайтмап и записи их в файлик.
//при загрузке LightMaps радиантом, она берётся как TSimpleEntry -
//а при компиляции заменяется экземпляром данного класса

type
   TRGB = array [0..2] of byte;

   TLightObjStruct=
   record
   	Pos: TPoint;//тип TPoint у нас в модуле Windows...
      Radius: word;
      Color: TRGB;
      Reserved: array [0..8] of byte;
   end;
   //итого - 16 байт

   PLightObjStruct=^TLightObjStruct;
type
   TLightObj =
   class
      constructor Create(fstruct: TLightObjStruct);
  private
    function GetColor: TColor;
    procedure SetColor(const Value: TColor);
   public
      Struct: TLightObjStruct;
      centerpoint: TObject;
      property Pos: TPoint read Struct.Pos write Struct.Pos;
		property X: integer read Struct.Pos.X;
      property Y: integer read Struct.Pos.Y;
      property Radius: word read Struct.Radius write Struct.Radius;
      property Color: TRGB read Struct.Color write Struct.Color;
      property WColor: TColor read GetColor write SetColor;

    	function SetX(Value: integer): integer;
    	function SetY(Value: integer): integer;
      function SetRadius(Value: integer): integer;
   end;

   TLightsEntry =
   class(TSimpleEntry)
      constructor Create(Head_: TEntryHead; var F: File);overload;
      constructor Create;overload;
      destructor Destroy;override;
   protected
      objs: TList;
     	function GetObj(i: integer): TLightObj;
      function GetHead: TEntryHead;override;
    public
      class function EntryClassName: TEntryClassName;
		procedure WriteToFile(var F: File);override;

       function Count: integer;
       property Obj[i: integer]: TLightObj read GetObj;default;

       function Add(struct: TLightObjStruct): TLightObj;
       function IndexOf(obj_: TLightObj): integer;
       procedure Delete(ind: integer);
   end;

   TLightMapEntry =
   class(TCustomEntry)
      constructor Create(OwnerMap: TCustomMap);overload; // ВОТ ТУТ ИДЁТ ГЕНЕРАЦИЯ
  	protected
      Map: TCustomMap;
   public
      class function EntryClassName: TEntryClassName;
 		procedure Clear;
 		procedure WriteToFile(var F: File);override;
   end;

implementation

uses ClickPs, TFKEntries, Main;

{ TLightObj }

constructor TLightObj.Create(fstruct: TLightObjStruct);
begin
   struct:=fstruct;
   AddLPoint(Self, [plCenter]);
   AddLPoint(Self, [plLeft]);
   AddLPoint(Self, [plTop]);
   AddLPoint(Self, [plRight]);
   AddLPoint(Self, [plBottom]);
   AddLPoint(Self, [plLeft, plTop]);
   AddLPoint(Self, [plTop, plRight]);
   AddLPoint(Self, [plRight, plBottom]);
   AddLPoint(Self, [plBottom, plLeft]);
end;

function TLightObj.GetColor: TColor;
begin
   result:=RGB(color[0], color[1], color[2]);
end;

procedure TLightObj.SetColor(const Value: TColor);
begin
   with struct do
   begin
   	color[0]:=GetRValue(Value);
   	color[1]:=GetGValue(Value);
   	color[2]:=GetBValue(Value);
   end;
end;

function TLightObj.SetRadius(Value: integer): integer;
begin
   with struct do
   begin
      if Value<30 then
         Value:=30;
      if Value>300 then
         Value:=300;
      Result:=value-radius;
      radius:=value;
   end;
end;

function TLightObj.SetX(Value: integer): integer;
begin
   with struct do
   begin
      if Value<0 then
         Value:=0;
      Result:=value-x;
      pos.x:=value;
   end;
end;

function TLightObj.SetY(Value: integer): integer;
begin
   with struct do
   begin
      if Value<0 then
         Value:=0;
      Result:=value-y;
      pos.y:=value;
   end;
end;

{ TLightsEntry }

function TLightsEntry.Add(struct: TLightObjStruct): TLightObj;
begin
   Result:=TLightObj.Create(struct);
   objs.Add(result);
end;

function TLightsEntry.Count: integer;
begin
   Result:=objs.Count;
end;

constructor TLightsEntry.Create(Head_: TEntryHead; var F: File);
var
   i: integer;
   struct: PLightObjStruct;

begin
   inherited Create(head_, F);
   Objs:=TList.Create;
   for i:=0 to head_.size div SizeOf(TLightObjStruct)-1 do
   begin
      struct:=@buf[i*SizeOf(TLightObjStruct)];
      Add(struct^);
   end;
end;

constructor TLightsEntry.Create;
begin
   inherited Create;
   Objs:=TList.Create;
end;

procedure TLightsEntry.Delete(ind: integer);
begin
   if (ind>=0) and (ind<objs.count) then
   begin
      obj[ind].Free;
      objs.Delete(ind);
   end;
end;

destructor TLightsEntry.Destroy;
begin
   while count>0 do
      Delete(0);
  inherited;
end;

class function TLightsEntry.EntryClassName: TEntryClassName;
begin
   Result:='LightsV1';
end;

function TLightsEntry.GetHead: TEntryHead;
begin
   fhead.EntryClass:=EntryClassName;
   fhead.size:=Count*SizeOf(TLightObjStruct);
   Result:=fhead;
end;

function TLightsEntry.GetObj(i: integer): TLightObj;
begin
   Result:=TLightObj(Objs[i]);
end;

function TLightsEntry.IndexOf(obj_: TLightObj): integer;
begin
   Result:=Objs.IndexOf(obj_);
end;

procedure TLightsEntry.WriteToFile(var F: File);
var
   i: integer;
   struct:TLightObjStruct;
begin
   GetHead;
   BlockWrite(f, fhead, SizeOf(fhead));

   for i:=0 to Count-1 do
   begin
   	struct:=Obj[i].Struct;
      BlockWrite(f, struct, SizeOf(struct));
   end;
end;

{ TLightMapEntry }

procedure TLightMapEntry.Clear;
begin

end;

constructor TLightMapEntry.Create(OwnerMap: TCustomMap);
begin
   Map:=OwnerMap;
   fhead.size:=0;
   fhead.EntryClass:=EntryClassName;
   fhead.Version:=1;
   //ТУТ ТЫ ГЕНЕРИРУЕШЬ лайтмапу, по данной Map
   //
   with TTFKMap(Map) do
   begin
   //используй объект Brk :)
   //текстуры можешь взять из модуля Main...
   //MainForm.CustomBox - первые CustomBox.Count текстур.
   //MainForm.Box1 - стандартные, т.е. остальные ;))
   end;

end;

class function TLightMapEntry.EntryClassName: TEntryClassName;
begin
   Result:='LightMapV1';
end;

procedure TLightMapEntry.WriteToFile(var F: File);
begin
  inherited;
//здесь ты пишешь генерированную лайтмапу
//
end;

end.
