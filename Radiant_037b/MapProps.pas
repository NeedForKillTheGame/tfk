unit MapProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, Grids, ComCtrls;

type
  TMapPropsFrm = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    AuthorEd: TEdit;
    NameEd: TEdit;
    Label2: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Panel2: TPanel;
    Label3: TLabel;
    EntryList: TStringGrid;
    WidthEd: TEdit;
    HeightEd: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    WidthUD: TUpDown;
    HeightUD: TUpDown;
    DelSection: TButton;
    EnvColor: TButton;
    EnvDlg: TColorDialog;
    procedure BitBtn1Click(Sender: TObject);
    procedure HeightEdKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure DelSectionClick(Sender: TObject);
    procedure EnvColorClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure fillTable;
  end;

var
  MapPropsFrm: TMapPropsFrm;

implementation

uses Main, MyEntries, TFKEntries;

{$R *.dfm}

procedure TMapPropsFrm.BitBtn1Click(Sender: TObject);
var
   i, j, w, h: word;
   B: TBricksEntry;
begin
   Map.Author:=AuthorEd.Text;
   Map.Name:=NameEd.Text;
   Map.SetEnvColor(EnvDlg.Color);
   w:=WidthUD.Position;
   h:=HeightUD.Position;
   if w<20 then w:=20;
   if h<30 then h:=30;
   with Map do
   if (Width<>w) or
      (Height<>h) then
      begin
         B:=TBricksEntry.Create(w, h);
         for j:=0 to h-1 do
            for i:=0 to w-1 do
            begin
               B[i, j]:=Brk[i, j];
               B.blocked[i, j]:=Brk.Blocked[i, j];
               B.Front[i, j]:=Brk.Front[i, j];
            end;
         Entries[Entries.IndexOf(Brk)]:=B;
         Brk.Free;
         Brk:=B;
      end;
end;

procedure TMapPropsFrm.HeightEdKeyPress(Sender: TObject; var Key: Char);
begin
   if not (Key in [#8, '0'..'9']) then
      Key:=#0;
end;

procedure TMapPropsFrm.FormShow(Sender: TObject);
begin
   with Map do
   begin
      AuthorEd.Text:=head.Author;
      NameEd.Text:=head.Name;
      WidthUD.Position:=Width;
      HeightUD.Position:=Height;
      EnvDlg.Color:=RGB(head.envcolor[0], head.envcolor[1], head.envcolor[2]);
      FillTable;
   end;
end;

procedure TMapPropsFrm.DelSectionClick(Sender: TObject);
var
   i :integer;
begin
   i:=EntryList.Row-1;
   if i>=0 then
   with Map do
   begin
      if (Entries[i]<>Brk) and
         (Entries[i]<>Obj) and
         (Entries[i]<>Lights) and
         (Entries[i]<>BrkTex) and
         (Entries[i]<>WP) then
      begin
         Entries.Delete(i);
         FillTable;
      end else ShowMessage('Sorry, i can''t delete this section');
   end;
end;

procedure TMapPropsFrm.fillTable;
var
   i, c: integer;
   E: TCustomEntry;
begin
   with Map do
   begin
      EntryList.RowCount:=EntriesCount+1;
      EntryList.Cells[0, 0]:='N';
      EntryList.Cells[1, 0]:='Size';
      EntryList.Cells[2, 0]:='Version';
      EntryList.Cells[3, 0]:='Type';
      EntryList.Cells[4, 0]:='Name';
      c:=10100;
      for i:=0 to EntriesCount-1 do
      begin
         E:=TCustomEntry(Entries[i]);
         if E=nil then Continue;
         EntryList.Cells[0, i+1]:=IntToStr(i);
         EntryList.Cells[1, i+1]:=IntToStr(E.Head.size);
         EntryList.Cells[2, i+1]:=IntToStr(E.Head.version);
         EntryList.Cells[3, i+1]:=E.Head.EntryClass;
         if E.Head.EntryClass='ScenarioV1' then
         begin
         	EntryList.Cells[4, i+1]:=E.Head.name+'; target '+IntToStr(c);
            Inc(c);
         end else EntryList.Cells[4, i+1]:=E.Head.name;
      end;
   end;
end;

procedure TMapPropsFrm.EnvColorClick(Sender: TObject);
begin
   EnvDlg.Execute;
end;

end.
