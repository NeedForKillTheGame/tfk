unit ObjElevatorProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjElevatorProp = class(TObjPropFrm)
    GroupBox2: TGroupBox;
    ActiveBox: TCheckBox;
    etarget1ed: TEdit;
    target1Null: TButton;
    Label3: TLabel;
    etarget2ed: TEdit;
    Label4: TLabel;
    target2NULL: TButton;
    target1ed: TEdit;
    Label7: TLabel;
    etarget1NULL: TButton;
    target2ed: TEdit;
    Label8: TLabel;
    etarget2NULL: TButton;
    Label9: TLabel;
    SpeedBar: TTrackBar;
    procedure etarget1edKeyPress(Sender: TObject; var Key: Char);
    procedure target1NullClick(Sender: TObject);
    procedure target2NULLClick(Sender: TObject);
    procedure etarget1NULLClick(Sender: TObject);
    procedure etarget2NULLClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjElevatorProp: TObjElevatorProp;

implementation

{$R *.dfm}

uses MapObj_Lib;

procedure TObjElevatorProp.etarget1edKeyPress(Sender: TObject;
  var Key: Char);
begin
   if TEdit(sender).Text='NULL' then
      TEdit(sender).Text:='';
   TargetNameEdKeyPress(sender, Key);
end;

procedure TObjElevatorProp.target1NullClick(Sender: TObject);
begin
   target1Ed.Text:='NULL';
end;

procedure TObjElevatorProp.target2NULLClick(Sender: TObject);
begin
   target2Ed.Text:='NULL';
end;

procedure TObjElevatorProp.etarget1NULLClick(Sender: TObject);
begin
   etarget1Ed.Text:='NULL';
end;

procedure TObjElevatorProp.etarget2NULLClick(Sender: TObject);
begin
   etarget2Ed.Text:='NULL';
end;

procedure TObjElevatorProp.Load;

   procedure LoadTarget(Ed: TEdit; value: word);
   begin
   	if value=NULLTARGET then
      	ed.Text:='NULL'
   	else ed.Text:=IntToStr(value);
   end;

begin
   inherited;
   LoadTarget(etarget1ed, struct.etargetname1);
   LoadTarget(etarget2ed, struct.etargetname2);
   LoadTarget(target1ed, struct.etarget1);
   LoadTarget(target2ed, struct.etarget2);
   ActiveBox.Checked:=struct.eactive;
   SpeedBar.Position:=round(struct.elevspeed*2);
end;

procedure TObjElevatorProp.Save;

   procedure SaveTarget(Ed: TEdit; var value: word);
   begin
      if ed.Text='NULL' then
         value:=NULLTARGET
         else value:=StrToInt(ed.Text);
   end;

begin
   SaveTarget(etarget1ed, struct.etargetname1);
   SaveTarget(etarget2ed, struct.etargetname2);
   SaveTarget(target1ed, struct.etarget1);
   SaveTarget(target2ed, struct.etarget2);
   Struct.eactive:=ActiveBox.Checked;
   Struct.elevspeed:=SpeedBar.Position/2;
   inherited;
end;

end.
