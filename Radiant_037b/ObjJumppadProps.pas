unit ObjJumppadProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjJumppadProp = class(TObjPropFrm)
    GroupBox2: TGroupBox;
    SpeedBar: TTrackBar;
    Label3: TLabel;
    Label4: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    SpeedLbl: TLabel;
    HeightBar: TTrackBar;
    Label9: TLabel;
    HeightLbl: TLabel;
    Label11: TLabel;
    Jump1Btn: TSpeedButton;
    Jump2Btn: TSpeedButton;
    procedure SpeedBarChange(Sender: TObject);
    procedure HeightBarChange(Sender: TObject);
    procedure Jump1BtnClick(Sender: TObject);
    procedure Jump2BtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ShowBars;
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjJumppadProp: TObjJumppadProp;

implementation

{$R *.dfm}

uses MapObj_Lib, Constants_Lib;

{ TObjJumppadProp }

procedure TObjJumppadProp.Load;
begin
  inherited;
   ShowBars;
end;

procedure TObjJumppadProp.ShowBars;
var
   h: integer;
begin
   SpeedBar.Position:=round(struct.jumpspeed*20);
   if SpeedBar.Position=99 then
      SpeedBar.Position:=100;
   SpeedLbl.Caption:=FloatToStrF(struct.jumpspeed, ffGeneral, 0, 1);
   h:=round(TJumppadObj(Obj).SpeedToHeight(struct.jumpspeed));
   HeightBar.Position:=(h+4) div 8;
   HeightLbl.Caption:=FloatToStr(round(h/8)/2);
end;

procedure TObjJumppadProp.SpeedBarChange(Sender: TObject);
begin
   struct.jumpspeed:=SpeedBar.Position/20;
   ShowBars;
end;

procedure TObjJumppadProp.HeightBarChange(Sender: TObject);
begin
   struct.jumpspeed:=TJumppadObj(Obj).HeightToSpeed(HeightBar.Position*8);
   ShowBars;
end;

procedure TObjJumppadProp.Save;
begin
  inherited;
   TJumppadObj(Obj).SetJumpPoint;
end;

procedure TObjJumppadProp.Jump1BtnClick(Sender: TObject);
begin
   struct.jumpspeed:=jump1;
   ShowBars;
end;

procedure TObjJumppadProp.Jump2BtnClick(Sender: TObject);
begin
   struct.jumpspeed:=jump2;
   ShowBars;
end;

end.
