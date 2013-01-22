unit Str_Lib;

interface

uses
 Func_Lib;

type
    TStrings = class
         constructor Create;
  private
    function GetS(ind: integer): string;
    	private
      	fstr: array of string;
         fcount: integer;
      public
         procedure Clear;
      	property Strings[ind: integer]: string read GetS;default;
         property count: integer read fcount;
         function Add(s: string): integer;
         function IndexOf(s: string): integer;
         procedure Delete(ind: integer);
         procedure SortAsc;
      end;

type
    TStringCells = class
         constructor Create;
    	private
      	fstr: array of array of string;
         fcolwidth: array of integer;
         frowc, fcolc: integer;
    		function GetS(col, row: integer): string;
    		procedure SetS(col, row: integer; const Value: string);
    		procedure SetRowCount(const Value: integer);
    function GetColWidth(ind: integer): integer;
    procedure SetColWidth(ind: integer; const Value: integer);
      public
         procedure Clear;
      	property Strings[col, row: integer]: string read GetS write SetS;default;
         property colcount: integer read fcolc;
         property rowcount: integer read frowc write SetRowCount;
         property colwidth[ind: integer]: integer read GetColWidth write SetColWidth;

         procedure SetSize(cols, rows: integer);
         function AddRow: integer;

         procedure SortAsc(colind: integer; col2 : integer = -1; desc: boolean = false; desc2: boolean=false);
         function Find(column: integer; value: string): integer;
      end;

implementation

{ TStrings }

function TStrings.Add(s: string): integer;
begin
   Inc(fcount);
   SetLength(fstr, fcount);
   fstr[high(fstr)]:=s;
   Result:=high(fstr);
end;

procedure TStrings.Clear;
begin
   fstr:=nil;
   fcount:=0;
end;

constructor TStrings.Create;
begin
   fstr:=nil;
   fcount:=0;
end;

procedure TStrings.Delete(ind: integer);
var
   i: integer;
begin
   if (ind>=0) and (ind<=high(fstr)) then
   begin
      for i:=ind to high(fstr)-1 do
         fstr[i]:=fstr[i+1];
      dec(fcount);
      SetLength(fstr, fcount);
   end;
end;

function TStrings.GetS(ind: integer): string;
begin
   if (ind>=0) and (ind<=high(fstr)) then
      result:=fstr[ind]
      else result:='';
end;

function TStrings.IndexOf(s: string): integer;
var
   i: integer;
begin
   Result:=-1;
   for i:=0 to high(fstr) do
      if s=fstr[i] then
      begin
         Result:=i;
         Break;
      end;
end;

procedure TStrings.SortAsc;

   procedure QSort(l, h: integer);
   var
      i, j: integer;
      x, t: string;
   begin
      i:=l;j:=h;
      if l>h then Exit;
      x:=fstr[(l+h) div 2];
      while (i<=j) do
         if fstr[i]<x then Inc(i)
         else if fstr[j]>x then Dec(j)
         else
         begin
            t:=fstr[i];fstr[i]:=fstr[j];fstr[j]:=t;
            Inc(i);Dec(j);
         end;
      if i<h then QSort(i, h);
      if l<j then QSort(l, j);
   end;

begin
   QSort(0, fcount-1);
end;

{ TStringCells }

function TStringCells.AddRow: integer;
begin
   result:=frowc;
   SetRowCount(frowc+1);
end;

procedure TStringCells.Clear;
begin
	fstr := nil;
	fcolwidth:=nil;
	frowc:=0;fcolc:=0;
end;

constructor TStringCells.Create;
begin
   Clear;
end;

function TStringCells.Find(column: integer; value: string): integer;
var
   i: integer;
begin
   Result:=-1;
   for i:=0 to frowc-1 do
      if fstr[column, i]=value then
   begin
      Result:=i;
      Exit;
   end;
end;

function TStringCells.GetColWidth(ind: integer): integer;
begin
   if (ind>=0) and (ind<colcount) then
      Result:=fcolwidth[ind]
   else Result:=0;
end;

function TStringCells.GetS(col, row: integer): string;
begin
   if (col>=0) and (col<colcount) and
      (row>=0) and (row<rowcount) then
      Result:=fstr[col, row]
      else Result:='';
end;

procedure TStringCells.SetColWidth(ind: integer; const Value: integer);
begin
   if (ind>=0) and (ind<colcount) and
   	(value>=0) then
      fcolwidth[ind]:=Value;
end;

procedure TStringCells.SetRowCount(const Value: integer);
var
   i: integer;
begin
	frowc:=Value;
   for i:=0 to colcount-1 do
      SetLength(fstr[i], frowc);
end;

procedure TStringCells.SetS(col, row: integer; const Value: string);
begin
   if (col>=0) and (col<colcount) and
      (row>=0) and (row<rowcount) then
      fstr[col, row]:=value;
end;

procedure TStringCells.SetSize(cols, rows: integer);
var
   i: integer;
begin
   Clear;
   SetLength(fstr, cols);
   fcolc:=cols;frowc:=rows;
   for i:=0 to cols-1 do
      SetLength(fstr[i], rows);
   SetLength(fcolwidth, cols);
end;

procedure TStringCells.SortAsc(colind: integer; col2 : integer; desc: boolean; desc2: boolean);
var
 strM : array of array of string;

   function Less(i, j: integer): boolean;//?? row.
   begin
      Result:=(col2>=0) and
               ((strM[colind, i]<strM[colind, j]) xor desc) or
               (strM[colind, i]=strM[colind, j]) and

              ((strM[col2, i]<strM[col2, j]) and not desc2 or
               (strM[col2, i]>strM[col2, j]) and desc2);
   end;

   procedure Swap(i, j: integer);
   var
      k: integer;
      x: string;
   begin
      for k:=0 to fcolc-1 do
      begin
         x:=strM[k, i];
         strM[k, i]:=strM[k, j];
         strM[k, j]:=x;
         
         x:=fstr[k, i];
         fstr[k, i]:=fstr[k, j];
         fstr[k, j]:=x;
      end;
   end;

   procedure QSort(l, h: integer);
   var
      i, j, x: integer;
   begin
      i:=l;j:=h;
      if l>h then Exit;
      x:=(l+h) div 2;
      while (i<=j) do
         if Less(i, x) then Inc(i)
         else if Less(x, j) then Dec(j)
         else
         begin
            if x=i then x:=j
            else if x=j then x:=i;
            Swap(i, j);
            Inc(i);Dec(j);
         end;
      if i<h then QSort(i, h);
      if l<j then QSort(l, j);
   end;

var
 i, j : integer;
begin
SetLength(strM, colcount, rowcount);
for i := 0 to rowcount - 1 do
 for j := 0 to colcount - 1 do
  strM[j, i] := lowercase(fstr[j, i]);

if (colind >= 0) and (colind < fcolc) then
 QSort(1, frowc - 1);
 
strM := nil;
end;

end.
