unit ObjItemProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjItemProp = class(TObjPropFrm)
    GroupBox2: TGroupBox;
    CountEd: TEdit;
    Label3: TLabel;
    CountUD: TUpDown;
    Label4: TLabel;
    FirstEd: TEdit;
    FirstUD: TUpDown;
    Label7: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjItemProp: TObjItemProp;

implementation

{$R *.dfm}

{ TObjItemProp }

procedure TObjItemProp.Load;
begin
  inherited;
   CountUD.Position:=struct.count;
   FirstUD.Position:=struct.waittarget;
end;

procedure TObjItemProp.Save;
begin
   struct.count:=CountUD.Position;
   struct.waittarget:=FirstUD.Position;
  inherited;
end;

end.
