unit about;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ShellAPI;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    OKButton: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Label3Click(Sender: TObject);
    procedure Label2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.dfm}

procedure TAboutBox.Label3Click(Sender: TObject);
begin
	ShellExecute(handle, 'open', 'mailto: neoff777@rambler.ru', nil, nil, SW_HIDE);
end;

procedure TAboutBox.Label2Click(Sender: TObject);
begin
	ShellExecute(handle, 'open', 'http://timeforkill.mirgames.ru', nil, nil, SW_HIDE);
end;

end.

