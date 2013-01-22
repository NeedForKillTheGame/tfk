unit ObjBGProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ObjectProps, ExtCtrls, StdCtrls, ComCtrls, Buttons;

type
  TObjBgProp = class(TObjPropFrm)
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Load;override;
    procedure Save;override;
  end;

var
  ObjBgProp: TObjBgProp;

implementation

{$R *.dfm}

{ TObjBgProp }

procedure TObjBgProp.Load;
begin
   Struct:=Obj.struct;
   ActiveGroup.ItemIndex:=Struct.Plane;
end;

procedure TObjBgProp.Save;
begin
   struct.plane:=ActiveGroup.ItemIndex;
   obj.Struct:=struct;
end;

end.
