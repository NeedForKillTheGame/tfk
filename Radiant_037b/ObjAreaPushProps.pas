unit ObjAreaPushProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjAreaPushProp = class(TObjPropFrm)
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    PushXEd: TEdit;
    PushWaitEd: TEdit;
    PushXUD: TUpDown;
    PushWaitUD: TUpDown;
    PushYEd: TEdit;
    Label7: TLabel;
    PushYUD: TUpDown;
    procedure PushXEdKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjAreaPushProp: TObjAreaPushProp;

implementation

{$R *.dfm}

{ TObjAreaPushProp }

procedure TObjAreaPushProp.Load;
begin
  	inherited;
   PushXUD.Position:=Struct.pushspeedx;
   PushYUD.Position:=Struct.pushspeedy;
   PushWaitUD.Position:=Struct.pushwait;
end;

procedure TObjAreaPushProp.Save;
begin
   Struct.pushspeedx:=PushXUD.Position;
   Struct.pushspeedy:=PushYUD.Position;
   Struct.pushwait:=PushWaitUD.Position;
  	inherited;
end;

procedure TObjAreaPushProp.PushXEdKeyPress(Sender: TObject; var Key: Char);
begin
   if not (Key in ['0'..'9', #8]) then
   begin
      if not ((Key='-') and (TEdit(Sender).SelStart=0)) then
      	Exit;
	end;
end;

end.
