unit Type_Lib;
(*******************************)
(* XEngine base types libary   *)
(*******************************)
(* Created by XProger          *)
(* begin : 29.10.2003          *)
(* end   : 19.09.2004          *)
(*******************************)
(* site : www.XProger.narod.ru *)
(* mail : XProger@list.ru      *)
(*******************************)
interface

uses
 Windows, Graph_Lib;

type
 TPoint2f=record
  X, Y: single;
 end;

 PPoint2f= ^TPoint2f; 

 TPoint3f=record
  X, Y, Z: single;
 end;

 TArray = array [0..1] of Byte;
 PArray = ^TArray;

 PConsoleCmdProc = ^TConsoleCmdProc;
 TConsoleCmdProc = function (Cmd: ShortString): boolean;

 PConsoleProp = ^TConsoleProp;
 TConsoleProp = record
  Font      : TTexData;
  Height    : integer;
  MaxHeight : integer;
  PageUp    : integer;
  Speed     : WORD;
  Show      : boolean;
 end;

 TMod = packed record
  Path: ShortString;
  Name: ShortString;
 end;

 THit = record
           v_uid: byte;
           a_uid: shortint;
           health, armor: byte;
           damage: word;
           hitid: word;
  			end;


 TVarType = (VT_SHORTINT,   // 1 байт  со знаком
             VT_SMALLINT,   // 2 байта со знаком
             VT_INTEGER,    // 4 байта со знаком
             VT_BYTE,       // 1 байт  без знака
             VT_WORD,       // 2 байта без знака
             VT_DWORD,      // 4 байта без знака
             VT_PROCEDURE,
				 VT_STRING,
             VT_FLOAT); // просто вызвать процедурку

function _Hit_(v_uid, a_uid, health, armor: byte; damage: word): THit;

type
 PListItem = ^TListItem;
 TListItem = record
  data : pointer;
  Next : PListItem;
 end;

 TList = object
  items : PListItem;
  Count : integer;
  procedure Init;
  procedure Add(p: pointer);
  procedure Free;
 end;

implementation

procedure TList.Init;
begin
items := nil;
Count := 0;
end;

procedure TList.Add(p: pointer);
var
 item : PListItem;
begin
New(item);
item.Next := items;
item.data := p;
items := item;
inc(Count);
end;

procedure TList.Free;
begin
Dispose(items);
end;

function _Hit_(v_uid, a_uid, health, armor: byte; damage: word): THit;
begin
   Result.v_uid:=v_uid;
   Result.a_uid:=a_uid;
   Result.health:=health;
   Result.armor:=armor;
   Result.damage:=damage;
end;

end.

