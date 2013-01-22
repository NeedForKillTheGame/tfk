unit MyScroll;

(***************************************)
(*  SCROLLING module    version 1.0.1  *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

interface

//СКРОЛЛИНГ
//Замечательнейший модуль:)
//Здесь заложены правила скроллинга по карте
//ИСПОЛЬЗОВАЛСЯ В РАДИАНТЕ И В ПЛАГИНЕ ДЛЯ TC ЕЩЕ ДЛЯ NFK!!!!

uses Classes, Types;

type
   TMyScroll = class
    					constructor Create;
  private
    FGX: integer;
    FGY: integer;
    FZoomX: integer;
    FZoomY: integer;
    FMaxI: integer;
    FMaxJ: integer;
    FScreenWidth: integer;
    FScreenHeight: integer;
    FClipOff: boolean;
    procedure SetGX(const Value: integer);
    procedure SetGY(const Value: integer);
    procedure SetMaxI(const Value: integer);
    procedure SetMaxJ(const Value: integer);
    procedure SetZoomX(const Value: integer);
    procedure SetZoomY(const Value: integer);
    procedure SetScreenHeight(const Value: integer);
    procedure SetScreenWidth(const Value: integer);
    function GetScreenRect: TRect;
    procedure SetClipOff(const Value: boolean);

       public
           property GX: integer read FGX write SetGX;
           property GY: integer read FGY write SetGY;
           property MaxI: integer read FMaxI write SetMaxI;
           property MaxJ: integer read FMaxJ write SetMaxJ;
           property ScreenWidth: integer read FScreenWidth write SetScreenWidth;
           property ScreenHeight: integer read FScreenHeight write SetScreenHeight;
           property ZoomX: integer read FZoomX write SetZoomX;
           property ZoomY: integer read FZoomY write SetZoomY;
           property ScreenRect: TRect read GetScreenRect;
           function GetX(i: integer): integer;
           function GetY(j: integer): integer;
           function GetI(x: integer): integer;
           function GetJ(y: integer): integer;
           function Clip(x, y: integer): boolean;
           function GetMaxX: integer;
           function GetMaxY: integer;
           function RectIJtoXY(R: TRect):TRect;
           function VisibleIJPoint(x, y: integer): boolean;
           function VisibleIJRect(R : TRect): boolean;
//version 1.01
           property ClipOff: boolean read FClipOff write SetClipOff;
//version 1.02
           function CenterToIJ(i, j: integer): boolean;
       end;

implementation

{ TMyScroll }

function TMyScroll.CenterToIJ(i, j: integer): boolean;
begin
   Result:=(GetI(ScreenWidth div 2)<>i) or
           (GetJ(ScreenHeight div 2)<>j);
   if Result then
   begin
   	Gx:=i*ZoomX+ZoomX div 2-ScreenWidth div 2;
   	Gy:=j*ZoomY+ZoomY div 2-ScreenHeight div 2;
   end;
end;

function TMyScroll.Clip(x, y: integer): boolean;
var
   i, j: integer;
begin
   i:=(x+GX) div FZoomX;
   j:=(y+GY) div FZoomY;
   Clip:=(i>=0) and (i<FMaxI) and
         (j>=0) and (j<FMaxJ);
end;

constructor TMyScroll.Create;
begin
   FGX:=0;FGY:=0;
end;

function TMyScroll.GetI(x: integer): integer;
begin
   Result:=(x+GX);
   if Result<0 then
      Result:=-((abs(result)+ZoomX-1) div ZoomX)
      else Result:=Result div ZoomX;
   if not ClipOff then
   begin
   	if Result<0 then Result:=0;
   	if Result>=MaxI then Result:=MaxI-1;
   end;
end;

function TMyScroll.GetJ(y: integer): integer;
begin
   Result:=(y+GY);
   if Result<0 then
      Result:=-((abs(result)+ZoomY-1) div ZoomY)
      else Result:=Result div ZoomY;
   if not ClipOff then
   begin
   	if Result<0 then Result:=0;
   	if Result>=MaxJ then Result:=MaxJ-1;
   end;
end;

function TMyScroll.GetMaxX: integer;
begin
   Result:=FMaxI*ZoomX;
end;

function TMyScroll.GetMaxY: integer;
begin
   Result:=FMaxJ*ZoomY;
end;

function TMyScroll.GetScreenRect: TRect;
begin
   Result.Left:=GetI(0);
   Result.Right:=GetI(ScreenWidth);
   Result.Top:=GetJ(0);
   Result.Bottom:=GetJ(ScreenHeight);
end;

function TMyScroll.GetX(i: integer): integer;
begin
   Result:=i*ZoomX-GX;
end;

function TMyScroll.GetY(j: integer): integer;
begin
   Result:=j*ZoomY-GY;
end;

function TMyScroll.RectIJtoXY(R: TRect): TRect;
begin
   Result.Left:=GetX(R.Left);
   Result.Top:=GetY(R.Top);
   Result.Right:=GetX(R.Right+1);
   Result.Bottom:=GetY(R.Bottom+1);
end;

procedure TMyScroll.SetClipOff(const Value: boolean);
begin
  FClipOff := Value;
end;

procedure TMyScroll.SetGX(const Value: integer);
begin
  FGX := Value;
  if FScreenWidth<=GetMaxX then
  begin
  	if FGX<-FScreenWidth div 2 then
     	FGX:=-FScreenWidth div 2 else
  		if FGX>GetMaxX-FScreenWidth div 2 then
     		FGX:=GetMaxX-FScreenWidth div 2;
  end else FGX:=(GetMaxX-FScreenWidth) div 2;
end;

procedure TMyScroll.SetGY(const Value: integer);
begin
  FGY:=Value;
  if FScreenHeight<GetMaxY then
  begin
  	if FGY<-FScreenHeight div 2 then
     	FGY:=-FScreenHeight div 2 else
  	if FGY>GetMaxY-FScreenHeight div 2 then
     	FGY:=GetMaxY-FScreenHeight div 2;
  end else FGY:=(GetMaxY-FScreenHeight) div 2;
end;

procedure TMyScroll.SetMaxI(const Value: integer);
begin
  FMaxI := Value;
end;

procedure TMyScroll.SetMaxJ(const Value: integer);
begin
  FMaxJ := Value;
end;

procedure TMyScroll.SetScreenHeight(const Value: integer);
begin
  FScreenHeight := Value;
end;

procedure TMyScroll.SetScreenWidth(const Value: integer);
begin
  FScreenWidth := Value;
end;

procedure TMyScroll.SetZoomX(const Value: integer);
begin
  FZoomX := Value;
end;

procedure TMyScroll.SetZoomY(const Value: integer);
begin
  FZoomY := Value;
end;

function TMyScroll.VisibleIJPoint(x, y: integer): boolean;
begin
   Result:=(x>=GetI(0)) and (x<=GetI(ScreenWidth)) and
           (y>=GetJ(0)) and (y<=GetJ(ScreenHeight));
end;

function TMyScroll.VisibleIJRect(R: TRect): boolean;
begin
   Result:=VisibleIJPoint(R.Left, R.Top) or
           VisibleIJPoint(R.Left, R.Bottom) or
           VisibleIJPoint(R.Right, R.Top) or
           VisibleIJPoint(R.Right, R.Bottom) or
           (R.Left<GetI(0)) and (R.Right>GetI(ScreenWidth)) or
           (R.Top<GetJ(0)) and (R.Bottom>GetJ(ScreenHeight));
end;

end.
