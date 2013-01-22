unit MapGen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TGenMapFrm = class(TForm)
    Panel1: TPanel;
    OutMemo: TMemo;
    RunBtn: TButton;
    HeightUD: TUpDown;
    WidthUD: TUpDown;
    WidthEd: TEdit;
    HeightEd: TEdit;
    Label5: TLabel;
    Label4: TLabel;
    procedure RunBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GenMapFrm: TGenMapFrm;

implementation

uses Main, Generate_Lib;

{$R *.dfm}

procedure TGenMapFrm.RunBtnClick(Sender: TObject);
var
   i, j: integer;
   brick: integer;
   a, b: array [1..10000] of integer;

   procedure QSort(l, h: integer);
   var
      i, j, t: integer;
      x: integer;
   begin
      i:=l;j:=h;
      if i>j then Exit;
      x:=a[(l+h) div 2];
      while (i<=j) do
         if a[i]<x then Inc(i)
         else if a[j]>x then Dec(j)
         else
         begin
            t:=a[i];
            a[i]:=a[j];
            a[j]:=t;
            t:=b[i];
            b[i]:=b[j];
            b[j]:=t;
            Inc(i);Dec(j);
         end;
      if j>l then QSort(l, j);
      if i<h then QSort(i, h);
   end;

begin
//генерация карты.
   Randomize;
   RClear;
with Map, OutMemo.Lines do
begin
   Brk.SetSize(WidthUd.Position, HeightUD.Position);

	brick:=5;
   AddRoom(TRoom.Create(0, 0, Width-2, Height-2)).SplitH(20, 30);
   j:=rc;
   for i:=1 to j do
      rooms[i].SplitV(20, 30);
   j:=rc;
   for i:=1 to j do
      rooms[i].SplitH(6, 10);
   j:=rc;
   for i:=1 to j do
      rooms[i].SplitV(6, 10);

   for i:=1 to rc do
      rooms[i].brick:=brick;
   for i:=1 to rc do
   with rooms[i] do
   begin
      for j:=x1 to x2 do
      begin
         Brk[j, y1]:=brick;
         Brk.blocked[j, y1]:=true;
      end;
      for j:=y1 to y2 do
      begin
         Brk[x1, j]:=brick;
         Brk.Blocked[x1, j]:=true;
      end;
   end;
   for j:=0 to Width-1 do
   begin
      Brk[j, Height-1]:=brick;
      Brk.blocked[j, Height-1]:=true;
   end;
   for j:=0 to Height-1 do
   begin
      Brk[Width-1, j]:=brick;
      Brk.blocked[Width-1, j]:=true;
   end;
   for i:=1 to rc do
   begin
      a[i]:=random(2*rc);
      b[i]:=i;
   end;
   QSort(1, rc);
   j:=rc;
   for i:=1 to rc do
   begin
      rooms[i].prevroom:=rooms[b[j]];
      rooms[i].nextroom:=rooms[b[i mod rc+1]];
      j:=i;
   end;
{   for i:=1 to rc do
      for j:=i+1 to rc do
      if random(2)=0 then
   begin
   end;}
   for i:=1 to rc do
   begin
      rooms[i].FillPrepare;
      rooms[i].FillSurf;
      rooms[i].Fill;
   end;
   Author:='Random Generator v1.0';
   Name:='RANDOM';
   Add('Map Generated');
   Add('Total: ');
   Add(IntToStr(rc)+' rooms');
end;
//Close;
end;

end.
