unit ObjRespawnProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjButtonProps, ExtCtrls, StdCtrls, ComCtrls, Buttons, ToolWin;

type
  TObjRespawnProp = class(TObjButtonProp)
    GroupBox3: TGroupBox;
    ToolBar1: TToolBar;
    RightBtn: TSpeedButton;
    LeftBtn: TSpeedButton;
    SargeBtn: TToolButton;
    procedure LeftBtnClick(Sender: TObject);
    procedure RightBtnClick(Sender: TObject);
    procedure SargeBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjRespawnProp: TObjRespawnProp;

implementation

{$R *.dfm}

uses Main;

{ TObjButtonProp1 }

procedure TObjRespawnProp.Load;
begin
  inherited;
   SargeBtn.ImageIndex:=struct.orient;
end;

procedure TObjRespawnProp.Save;
begin
   inherited;
end;

procedure TObjRespawnProp.LeftBtnClick(Sender: TObject);
begin
   struct.orient:=0;
   SargeBtn.ImageIndex:=struct.orient;
end;

procedure TObjRespawnProp.RightBtnClick(Sender: TObject);
begin
   struct.orient:=1;
   SargeBtn.ImageIndex:=struct.orient;
end;

procedure TObjRespawnProp.SargeBtnClick(Sender: TObject);
begin
   struct.orient:=1-struct.orient;
   SargeBtn.ImageIndex:=struct.orient;
end;

end.
