unit ObjBloodGenProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjBloodGenProp = class(TObjPropFrm)
    Sprites: TGroupBox;
    Label7: TLabel;
    Label3: TLabel;
    ColorBox: TComboBox;
    BloodWaitEd: TEdit;
    Label4: TLabel;
    BloodWaitUD: TUpDown;
    TypeBox: TComboBox;
    Label8: TLabel;
    CountEd: TEdit;
    CountUD: TUpDown;
    Label9: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjBloodGenProp: TObjBloodGenProp;

implementation

{$R *.dfm}

{ TObjBloodGenProp }

procedure TObjBloodGenProp.Load;
begin
  inherited;
   TypeBox.ItemIndex:=Struct.BloodType;
   BloodWaitUD.Position:=Struct.BloodWait;
   CountUD.Position:=Struct.BloodCount;
   ColorBox.ItemIndex:=Struct.orient;
end;

procedure TObjBloodGenProp.Save;
begin
   Struct.BloodType:=TypeBox.ItemIndex;
   Struct.BloodWait:=BloodWaitUD.Position;
   Struct.BloodCount:=CountUD.Position;
   Struct.orient:=ColorBox.ItemIndex;
  inherited;
end;

end.
