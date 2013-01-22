unit LightMapGen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TLMFrm = class(TForm)
    Panel1: TPanel;
    RunBtn: TButton;
    OutMemo: TMemo;
    procedure RunBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LMFrm: TLMFrm;

implementation

uses MyEntries, LightMap_Lib, Main;

{$R *.dfm}

procedure TLMFrm.RunBtnClick(Sender: TObject);
var
   i: integer;
   LM: TLightMapEntry;
begin
   with Map, OutMemo.Lines do
   begin
   	if (Lights=nil) or
      	(Lights.Count=0) then
         begin
            Add('Error: No lights found.');
         	Exit;
         end;
      for i:=0 to Entries.Count-1 do
         if TCustomEntry(Entries[i]).head.EntryClass='LightMapV1' then
         begin
            Entries.Delete(i);
            Exit;
         end;
      try
         LM:=TLightMapEntry.Create(Map);
         Entries.Add(LM);
      except
         Add('Error: unknown');
         Exit;
      end;
      Add('LightMap Generated');
      Add('Size: '+IntToStr(LM.head.size));
   end;
end;

end.
