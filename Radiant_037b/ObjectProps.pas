unit ObjectProps;

interface

(***************************************)
(*  TFK Object edit form version 1.0.1 *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

//форма редактирования базового объекта.
//длё редактирования спец. объекта нужно наследовать форму
//от этой либо другой формы редактирования.
//для новых свойств создается специальная GroupBox,
//загрузка, сохранение идет из структуры struct.
//сохранение свойств - proc Save;override; (inherited в конце)
//загрузка свойств - proc Load;override; (inherited в начале)

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, MapObj_Lib, ComCtrls, ExtCtrls;

type
  TObjPropFrm = class(TForm)
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    UpdateBtn: TBitBtn;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    TargetNameUD: TUpDown;
    TargetNameEd: TEdit;
    Label5: TLabel;
    WaitEd: TEdit;
    WaitUD: TUpDown;
    Label6: TLabel;
    ActiveGroup: TRadioGroup;
    procedure OkBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure UpdateBtnClick(Sender: TObject);
    procedure ActiveGroupClick(Sender: TObject);
    procedure TargetNameEdKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    obj: TCustomMapObj;
    struct: TMapObjStruct;
    procedure Load;virtual;
    procedure Save;virtual;
    { Public declarations }
  end;

var
  ObjPropFrm: TObjPropFrm;

implementation

{$R *.dfm}

procedure TObjPropFrm.OkBtnClick(Sender: TObject);
begin
   Save;
end;

procedure TObjPropFrm.FormShow(Sender: TObject);
begin
   Load;
end;

procedure TObjPropFrm.UpdateBtnClick(Sender: TObject);
begin
   Load
end;

procedure TObjPropFrm.Save;
begin
   struct.active:=ActiveGroup.ItemIndex;
   Struct.target_name:=TargetNameUD.Position;
   Struct.wait:=WaitUD.Position;
   obj.Struct:=struct;
end;

procedure TObjPropFrm.Load;
begin
   struct:=obj.struct;

   ActiveGroup.ItemIndex:=Struct.active;
   TargetNameUD.Enabled:=odd(struct.active);
   TargetNameEd.Enabled:=odd(struct.active);

   TargetNameUD.Position:=struct.Target_Name;
   WaitUD.Position:=Struct.wait;
end;

procedure TObjPropFrm.ActiveGroupClick(Sender: TObject);
begin
   TargetNameUD.Enabled:=ActiveGroup.ItemIndex>0;
   TargetNameEd.Enabled:=ActiveGroup.ItemIndex>0;
end;

procedure TObjPropFrm.TargetNameEdKeyPress(Sender: TObject; var Key: Char);
begin
   if not (Key in ['0'..'9', #8]) then
      Key:=#0;
end;

end.
