unit ObjLightLineProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjButtonProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjLightLineProp = class(TObjButtonProp)
    ColorBox: TComboBox;
    Label9: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjLightLineProp: TObjLightLineProp;

implementation

{$R *.dfm}

{ TObjButtonProp1 }

procedure TObjLightLineProp.Load;
begin
  inherited;
   ColorBox.ItemIndex:=Struct.orient;
end;

procedure TObjLightLineProp.Save;
begin
   Struct.orient:=ColorBox.ItemIndex;
  inherited;
end;

end.
