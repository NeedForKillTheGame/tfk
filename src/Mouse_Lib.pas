unit Mouse_Lib;

interface

type
    TMousePad =
    	class
         constructor Create;
     private
       	x, y: single;
       	fAngle: single;
    		function GetAngle: single;
    		procedure SetAngle(const Value: single);
    		function GetCAngle: single;
    		procedure SetCAngle(const Value: single);
     public
       	minradius, maxradius: integer;
       	function GetX: single;
       	function GetY: single;
         function Radius: single;
         procedure SetXY(x_, y_: single);
         property Angle: single read GetAngle write SetAngle;
         property CAngle: single read GetCAngle write SetCAngle;
         procedure Reset;
         procedure Update;
     end;

var
   Mouse: TMousePad;

procedure Mouse_Init;
procedure Mouse_Dispose;

implementation

uses Engine_Reg, Math_Lib, Math, Constants_Lib;

procedure Mouse_Init;
begin
   Mouse:=TMousePad.Create;
end;

procedure Mouse_Dispose;
begin
   Mouse.Free;
end;

{ TMousePad }

constructor TMousePad.Create;
begin
   Update;
   Reset;
end;

function TMousePad.GetAngle: single;
var
   r: single;
begin
   r:=sqrt(sqr(x)+sqr(y));
   if r>1 then
   begin
      fAngle:=arccos(x/r);
      if signf(y)<0 then
         fAngle:=-fAngle;
   end;
   Result:=fAngle;
end;

function TMousePad.GetCAngle: single;
begin
   Result:=Angle*180/Pi;
   while Result<0 do Result:=Result+360;
   while Result>=360 do Result:=Result-360;
end;

function TMousePad.GetX: single;
var
   r: single;
begin
   r:=sqrt(sqr(x)+sqr(y));
   if r<minradius then
      Result:=minradius*cos(Angle)
      else Result:=x;
end;

function TMousePad.GetY: single;
var
   r: single;
begin
   r:=sqrt(sqr(x)+sqr(y));
   if r<minradius then
      Result:=minradius*sin(Angle)
      else Result:=y;
end;

function TMousePad.Radius: single;
begin
   Result:=sqrt(sqr(x)+sqr(y));
   if Result<minradius then Result:=minradius;
   if Result>maxradius then Result:=maxradius;
end;

procedure TMousePad.Reset;
begin
   x:=maxradius;y:=0;
   fAngle:=0;
end;

procedure TMousePad.SetAngle(const Value: single);
begin
   SetXY( Radius*cos(Value), Radius*sin(Value));
end;

procedure TMousePad.SetCAngle(const Value: single);
begin
   SetAngle(Value*Pi/180);
end;

procedure TMousePad.SetXY(x_, y_: single);
var
   r: single;
begin
   minradius:=cg_crosshair_offset*mouselook_offset div 8;
   maxradius:=cg_crosshair_offset;

   r:=sqrt(sqr(x_)+sqr(y_));
   if r>maxradius then
   begin
   	x_:=x_*maxradius/r;
   	y_:=y_*maxradius/r;
   end;
   x:=x_;y:=y_;
end;

procedure TMousePad.Update;
begin
   minradius:=cg_crosshair_offset*mouselook_offset div 8;
   maxradius:=cg_crosshair_offset;
   SetXY(x+
   		maxradius*mouse_sensitivity*Input_MouseDelta.X*mouselook_pitch/8000,
   	   y+
         maxradius*mouse_sensitivity*Input_MouseDelta.Y*mouselook_yaw/8000);
end;

end.
