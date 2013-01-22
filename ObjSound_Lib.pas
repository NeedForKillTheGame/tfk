unit ObjSound_Lib;

(*******************************************)
(*  TFK Sound library version 0.2          *)
(*******************************************)
(* Created by XProger                      *)
(* mail : XProger@list.ru                  *)
(*******************************************)

interface

uses
 Windows, Engine_Reg, Graph_Lib, Math_Lib, Type_Lib, Constants_Lib;

type
 //Звук
 TSound = class
   constructor Create; overload;
   constructor Create(const FileName: string; Loop: boolean; Bind: boolean = false); overload;
  private
   procedure SetPos(Pos: TPoint2f);
  public
   ID   : integer;
   Loop : boolean;
   Bind : boolean;
   function Play(X: single = 0; Y: single = 0; center: boolean = false): integer;
   procedure Stop;
   property Pos: TPoint2f write SetPos;
 end;

var
 GlobalPos : TPoint2f;

implementation

constructor TSound.Create;
begin
ID := -1;
end;

constructor TSound.Create(const FileName: string; Loop: boolean; Bind: boolean = false);
begin
self.Loop := Loop;
self.Bind := Bind;
ID := snd_Load(PChar(FileName));
end;

function TSound.Play(X: single = 0; Y: single = 0; center: boolean = false): integer;
begin
if sound_off=0 then
 begin
 Result := snd_Play(ID, Loop, X, Y, bind or center);
{ XProger: поприкалывались, и хватит ;)
 if sound_freq > 0 then
  if sound_freq = 1 then
   begin
   f := cg_ups*441;
   if f > 100000 then
    f := 100000;
   snd_SetFreq(Result, f);
   end
  else
   snd_SetFreq(Result, sound_freq);}
 //snd_SetPos(Result, Point3f(X, Y, 0));
 end
else
 Result := -1; 
end;

procedure TSound.Stop;
begin
snd_Stop(ID);
end;

procedure TSound.SetPos(Pos: TPoint2f);
begin
snd_SetPos(ID, Pos);
end;

end.
