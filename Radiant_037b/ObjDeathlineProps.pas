unit ObjDeathlineProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjDeathLineProp = class(TObjPropFrm)
    GroupBox2: TGroupBox;
    DamageEd: TEdit;
    Label3: TLabel;
    DamageWaitEd: TEdit;
    Label4: TLabel;
    DamageUD: TUpDown;
    DamageWaitUD: TUpDown;
    ColorBox: TComboBox;
    Label7: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjDeathLineProp: TObjDeathLineProp;

implementation

{$R *.dfm}

{ TObjDeathLineProp }

procedure TObjDeathLineProp.Load;
begin
  	inherited;
   DamageUD.Position:=Struct.linedamage;
   DamageWaitUD.Position:=Struct.linedamagewait;
   ColorBox.ItemIndex:=Struct.orient;
end;

procedure TObjDeathLineProp.Save;
begin
   Struct.linedamage:=DamageUD.Position;
   Struct.linedamagewait:=DamageWaitUD.Position;
   Struct.orient:=ColorBox.ItemIndex;
  	inherited;
end;

end.
