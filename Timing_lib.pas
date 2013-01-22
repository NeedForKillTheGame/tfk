unit Timing_lib;

interface

uses
 Windows, OpenGL,
 Engine_Reg,
 Func_lib,
 Type_Lib;

procedure Timing_Start(paramname : string);
procedure Timing_End(paramname : string);
procedure Timing_Draw;

implementation

var
   tt: array [0..100] of string;
   ts, tm: array [0..100] of integer;
   cc: integer = 0;

function GetTimer: integer; 
var 
 T, F : LARGE_INTEGER; 
begin 
QueryPerformanceFrequency(int64(F)); 
QueryPerformanceCounter(int64(T)); 
Result := trunc(1000 * T.QuadPart/F.QuadPart); 
end;

procedure Timing_Start(paramname : string);
var
   i: integer;
begin
   for i:=0 to cc-1 do
      if tt[i]=paramname then
      begin
         ts[i]:=GetTimer;
         Exit;
      end;
   Inc(cc);
   tt[cc-1]:=paramname;
   ts[cc-1]:=GetTimer;
end;

procedure Timing_End(paramname : string);
var
   i: integer;
begin
   for i:=0 to cc-1 do
      if tt[i]=paramname then
      begin
         tm[i]:=GetTimer-ts[i];
         Exit;
      end;
   Inc(cc);
   tt[cc-1]:=paramname;
   tm[cc-1]:=0;
end;

procedure Timing_Draw;
var
   i: integer;
begin
 xglAlphaBlend(1);
 for i:=0 to cc-1 do
 begin
   glColor3f(0, 0, 0);
   TextOut(500, 51+i*16, PChar(tt[i]));
   TextOut(600, 51+i*16, PChar(inttostr(tm[i])));
   glColor3f(1, 0.2, 0.2);
   TextOut(500, 51+i*16, PChar(tt[i]));
   TextOut(600, 51+i*16, PChar(inttostr(tm[i])));
 end;
end;

end.
