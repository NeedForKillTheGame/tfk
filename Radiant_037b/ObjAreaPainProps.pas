unit ObjAreaPainProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjAreaPainProp = class(TObjPropFrm)
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    DamageEd: TEdit;
    DamageWaitEd: TEdit;
    DamageUD: TUpDown;
    DamageWaitUD: TUpDown;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjAreaPainProp: TObjAreaPainProp;

implementation

{$R *.dfm}

procedure TObjAreaPainProp.Load;
begin
  	inherited;
   DamageUD.Position:=Struct.paindamage;
   DamageWaitUD.Position:=Struct.painwait;
end;

procedure TObjAreaPainProp.Save;
begin
   Struct.paindamage:=DamageUD.Position;
   Struct.painwait:=DamageWaitUD.Position;
  	inherited;
end;

end.
