unit main_v0;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, BandActn, ExtActns, StdActns, XPStyleActnCtrls,
  ActnMan, ToolWin, ActnCtrls, ActnMenus, TFKEntries, NFKMap_Lib;

const
   DefaultExt = '.tm';

type
  TMainForm = class(TForm)
    ActionManager1: TActionManager;
    FileOpen1: TFileOpen;
    FileSaveAs1: TFileSaveAs;
    FileRun1: TFileRun;
    FileExit1: TFileExit;
    CustomizeActionBars1: TCustomizeActionBars;
    ActionMainMenuBar1: TActionMainMenuBar;
    NewFile1: TAction;
    FileSave1: TAction;
    procedure NewFile1Execute(Sender: TObject);
    procedure FileSave1Execute(Sender: TObject);
    procedure FileSaveAs1BeforeExecute(Sender: TObject);
    procedure FileSaveAs1Accept(Sender: TObject);
    procedure FileOpen1Accept(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    //���������� ��������� � ����������� � ��������� ����.
    file_name: string;
    newfile, modified: boolean;
    function MapName: string;
    function SaveQuery: boolean;
    procedure SetInitialDirs;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

function TMainForm.MapName: string;
begin
//��� �����
   if newfile then
   	Result:='newmap'
   else
      Result:=ExtractFileName(File_Name);
end;

function TMainForm.SaveQuery: boolean;
var
   res: integer;
begin
   //���������� ���� �� ��������� ����
   Result:=not modified;
   if Result then Exit;
	res:=Application.MessageBox(
   	PChar('Save changes to map "'+ExtractFileName(file_name)+'"'),
      'Query',
      mb_YesNoCancel);
   if res=mrYes then
   begin
      if FileSave1.Execute then
      	Result:=not modified;
   end
      else Result:=res=mrNo;
end;

procedure TMainForm.SetInitialDirs;
begin
   if not newfile then
   begin
   	with FileOpen1.Dialog do
   	begin
      	InitialDir:=ExtractFilePath(file_name);
      	filename:=file_name;
   	end;
   	with FileSaveAs1.Dialog do
   	begin
      	InitialDir:=ExtractFilePath(file_name);
      	filename:=file_name;
   	end;
   end;
end;

procedure TMainForm.NewFile1Execute(Sender: TObject);
begin
   newfile:=true;
   modified:=false;
end;

procedure TMainForm.FileSaveAs1BeforeExecute(Sender: TObject);
begin
   if newfile then
   	with FileSaveAs1.Dialog do
      	filename:=InitialDir+'\'+MapName+DefaultExt;
end;

procedure TMainForm.FileSaveAs1Accept(Sender: TObject);
begin
   file_name:=FileSaveAs1.Dialog.FileName;
   newfile:=false;
   SetInitialDirs;
   FileSave1.Execute;
end;

procedure TMainForm.FileSave1Execute(Sender: TObject);
begin
//���� ������ ���������� �� �������� FileSaveAs; ����� ������ �����...
   if file_name='' then
   begin
      FileSaveAs1.Execute;
      Exit;
   end;
//���������� �����
   modified:=false;
end;

procedure TMainForm.FileOpen1Accept(Sender: TObject);
begin
//��������� �����
   with FileOpen1.Dialog do
   begin
      if not SaveQuery then Exit;
//� ������ ����� ������ ��� ����� � �������� ������ �� ����� �����, ������ ����� ���������.
      newfile:=false;
      file_name:=filename;
      SetInitialDirs;
   end;
end;

//����� �������� � �������
//*************************8

procedure TMainForm.FormCreate(Sender: TObject);
begin
//������� ���������- �������� ���� ��������
   NewFile1.Execute;
end;

end.
