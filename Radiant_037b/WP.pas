unit WP;

interface

uses
  MyEntries, Classes, Windows, Graphics, ClickPs;

const
   WP_Size = 8;
   WPLink_Size = 2;

type
  TWPObj =
  class(TCustomCPObj)
     constructor Create(x, y:word; t: char);
     destructor Destroy;override;
  protected
     function GetX: word;override;
     function GetY: word;override;
     function GetWidth: word;override;
     function GetHeight: word;override;
  public
     function SetX(Value: integer): integer;override;
     function SetY(Value: integer): integer;override;
     function SetLeftX(Value: integer): integer;override;
     function SetTopY(Value: integer): integer;override;
	  function SetWidth(Value: integer): integer;override;
     function SetHeight(Value: integer): integer;override;

  public
     mainpoint: TClickPoint;
     fx, fy: word;
     ID: Word;
     wp_type, u: char;
     ways : array of TWPObj;

     procedure way_Add(obj: TWPObj);
     procedure way_Delete(obj: TWPObj);
     function way_Exists(obj: TWPObj): boolean;
     function way_Count: integer;

     procedure ActionLink(LinkObj: TCustomCPObj);override;
  end;

  TWPEntry =
  class(TCustomEntry)
      constructor Create(Head_: TEntryHead; var F: File);overload;
      constructor Create;overload;
      destructor Destroy;override;
   protected
      objs: TList;
     	function GetObj(i: integer): TWPObj;
      function GetHead: TEntryHead;override;
    public
      class function EntryClassName: TEntryClassName;
		procedure WriteToFile(var F: File);override;

      function Count: integer;
      property Obj[i: integer]: TWPObj read GetObj;default;

      function Add(x, y: word; t: char): TWPObj;
      procedure Clear;
      procedure Delete(obj: TObject);
  end;

implementation

uses Main;

{ TWPObj }

procedure TWPObj.ActionLink(LinkObj: TCustomCPObj);
begin
   if LinkObj is TWPObj then
      way_Add(TWPObj(LinkObj));
end;

constructor TWPObj.Create(x, y: word; t: char);
begin
   ways:=nil;
   wp_type:=t;
   fx:=x;fy:=y;
//   AddPoint(Self, CenterPoint, 0, -15, clSilver);
   mainpoint:=AddPoint(Self, LinkPoint, 0, -15, clSilver);
end;

destructor TWPObj.Destroy;
begin
   ways:=nil;
end;

function TWPObj.GetHeight: word;
begin
   Result:=1;
end;

function TWPObj.GetWidth: word;
begin
   Result:=1;
end;

function TWPObj.GetX: word;
begin
   Result:=fx;
end;

function TWPObj.GetY: word;
begin
   Result:=fy;
end;

function TWPObj.SetHeight(Value: integer): integer;
begin
   Result:=0;
end;

function TWPObj.SetLeftX(Value: integer): integer;
begin
   Result:=0;
end;

function TWPObj.SetTopY(Value: integer): integer;
begin
   Result:=0;
end;

function TWPObj.SetWidth(Value: integer): integer;
begin
   Result:=0;
end;

function TWPObj.SetX(Value: integer): integer;
begin
	if Value<0 then Value:=0;
  	if Value>=Map.Width then Value:=Map.Width-1;
   Result:=Value-fx;
   fx:=Value;
end;

function TWPObj.SetY(Value: integer): integer;
begin
   if Value<0 then Value:=0;
 	if Value>=Map.Height then Value:=Map.Height-1;
   Result:=Value-fy;
   fy:=Value;
end;

procedure TWPObj.way_Add(obj: TWPObj);
begin
   if (obj=nil) or (obj=Self) then Exit;
   if not way_Exists(obj) then
   begin
   	SetLength(ways, way_Count+1);
      ways[way_Count-1]:=obj;
   end;
end;

function TWPObj.way_Count: integer;
begin
   if ways<>nil then
      Result:=Length(ways)
      else Result:=0;
end;

procedure TWPObj.way_Delete(obj: TWPObj);
var
   i: integer;
begin
	i:=0;
   while i<way_count do
   begin
      if ways[i]=obj then
      begin
         while i<way_count-1 do
         begin
            ways[i]:=ways[i+1];
            Inc(i);
         end;
         SetLength(ways, way_Count-1);
         Exit;
      end;
      Inc(i);
   end;
end;

function TWPObj.way_Exists(obj: TWPObj): boolean;
var
   i: integer;
begin
   Result:=false;
   for i:=0 to way_Count-1 do
      if ways[i]=obj then
   begin
      Result:=true;
      Break;
   end;
end;

{ TWPEntry }

function TWPEntry.Add(x, y: word; t: char): TWPObj;
begin
   Result:=TWPObj.Create(x, y, t);
   objs.Add(Result);
end;

procedure TWPEntry.Clear;
begin
   while Count>0 do
   begin
      TWPObj(objs[0]).Free;
      objs.Delete(0);
   end;
end;

function TWPEntry.Count: integer;
begin
   Result:=objs.Count;
end;

constructor TWPEntry.Create(Head_: TEntryHead; var F: File);
var
   i, j: integer;
   wc, next: word;
   wp: TWPObj;
begin
   inherited;
   objs:=TList.Create;
   for i:=0 to fhead.TEXCount-1 do
      Add(0, 0, ' ');
   for i:=0 to fhead.TEXCount-1 do
   begin
      wp:=obj[i];
      BlockRead(F, wp.fx, 2);
      BlockRead(F, wp.fy, 2);
      BlockRead(F, wp.wp_type, 1);
      BlockRead(F, wp.u, 1);
      BlockRead(F, wc, 2);
      for j:=0 to wc-1 do
      begin
         BlockRead(F, next, 2);
         wp.way_Add(obj[next]);
      end;
   end;
end;

constructor TWPEntry.Create;
begin
   objs:=TList.Create;
end;

procedure TWPEntry.Delete(obj: TObject);
var
   k: integer;
begin
   k:=objs.IndexOf(obj);
   if k>=0 then
   begin
      TWPObj(objs[k]).Free;
   	objs.Delete(k);
   end;
end;

destructor TWPEntry.Destroy;
begin
   Clear;
   objs.Free;
   inherited;
end;

class function TWPEntry.EntryClassName: TEntryClassName;
begin
   Result:='WPEntryV1'
end;

function TWPEntry.GetHead: TEntryHead;
var
   i: integer;
begin
   fhead.EntryClass:=EntryClassName;
   fhead.Version:=1;
   fhead.size:=count*WP_SIZE;
   fhead.TEXCount:=count;
   for i:=0 to count-1 do
      Inc(fhead.size, Obj[i].way_Count*WPLINK_SIZE);
   Result:=fhead;
end;

function TWPEntry.GetObj(i: integer): TWPObj;
begin
   if (i>=0) and (i<Count) then
      Result:=TWPObj(objs[i])
   else Result:=nil;
end;

procedure TWPEntry.WriteToFile(var F: File);
var
   i, j: integer;
   wp: TWPObj;
   wc, next: word;
begin
   gethead;
  	inherited;
   for i:=0 to fhead.TEXCount-1 do
   begin
      wp:=obj[i];
      wc:=wp.way_Count;
      BlockWrite(F, wp.fx, 2);
      BlockWrite(F, wp.fy, 2);
      BlockWrite(F, wp.wp_type, 1);
      BlockWrite(F, wp.u, 1);
      BlockWrite(F, wc, 2);
      for j:=0 to wc-1 do
      begin
         next:=objs.IndexOf(wp.ways[j]);
         BlockWrite(F, next, 2);
      end;
   end;
end;

end.
