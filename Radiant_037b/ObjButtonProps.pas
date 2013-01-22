unit ObjButtonProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, StdCtrls, Buttons, ComCtrls, ExtCtrls;

type
  TObjButtonProp = class(TObjPropFrm)
    GroupBox2: TGroupBox;
    Label7: TLabel;
    Label3: TLabel;
    TargetEd: TEdit;
    WaitTargetUD: TUpDown;
    TargetUD: TUpDown;
    WaitTargetEd: TEdit;
    Label4: TLabel;
    Label8: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Save;override;
    procedure Load;override;
  end;

var
  ObjButtonProp: TObjButtonProp;

implementation

{$R *.dfm}

{ TObjButtonProp }

procedure TObjButtonProp.Load;
begin
  	inherited;
   TargetUD.Position:=Struct.target;
   WaitTargetUD.Position:=Struct.waittarget;
end;

procedure TObjButtonProp.Save;
begin
   Struct.waittarget:=WaitTargetUD.Position;
   Struct.target:=TargetUD.Position;
  	inherited;
end;

end.
