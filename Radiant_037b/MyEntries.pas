unit MyEntries;

(***************************************)
(*  Entries&Maps module version 1.0.1  *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

interface

//÷òîáû èñïîëüçîâàòü TList âìåñòî äèí. ìàññèâà, ðàñêîìåíòèðóé ýòî:
//ÐÅÄÀÊÒÎÐ ÁÅÇ ÝÒÎÃÎ ÍÅ ÊÎÌÏÈËÈÒÑß
//À ÈÃÐÀ Ñ ÝÒÈÌ ÂÅÑÈÒ Â ÄÂÀ ÐÀÇÀ ÁÎËÜØÅ!!!
{$DEFINE EDITORMODE}

//ÊÀÆÄÛÉ ÏÎÒÎÌÎÊ TCustomEntry îáÿçàí:
//*ãðóçèòü èç ôàéëà èíôó ìóòîäîì Create(head, var f file);
//*äàâàòü èíôîðìàöèþ î ñåáå ôóíêöèåé
// class function EntryClassName: TEntryClassName;
//*ñîîáùàòü êàêóþ âåðñèþ îí ïîääåðæèâàåò ôóíêöèåé
// class function IsValidVersion(version: integer): boolean;
// ÝÒÈ CLASS-ÔÓÍÊÖÈÈ ÍÅ ÌÎÃÓÒ ÁÛÒÜ ÂÈÐÒÓÀËÜÍÛ, ÎÍÈ ÂÛÇÛÂÀÞÒÑß ÍÅÏÎÑÐÅÄÑÒÂÅÍÍÎ Ó ÊËÀÑÑÀ!!!

//*ñîîáùàòü òåêóùóþ âåðñèþ ñàìîãî ÎÁÚÅÊÒÀ à íå èíôû èç ôàéëà...
// function DefaultVersion: integer;

//*çàïèñûâàòü èíôó î ñåáå, ðàçìåðå, âåðñèè â FHEAD ôóíêöèåé
//function GetHead: TEntryHead;

//Â ïðèíöèïå ôôôñ¸...
//Ïðèìåð - TBricksEntry â ñîñåäíåì ìîäóëå


{$IFDEF EDITORMODE}
uses Classes, Windows;
{$ENDIF}

const
   MapVersion=1;
   LowMapVersion=1;
   HighMapVersion=5;

type
    TEntryClassName=string[15];
    TEntryName = string[15];

type
   TEntryHead=record
                   name: TEntryName;
                   EntryClass: TEntryClassName;
                   version: integer;
                   size: cardinal;
                   case integer of
                      0: (reserved: array [0..9] of byte);
                      1: (maxx: integer;maxy:integer; defaultbrick: word);
                      2: (TEXCount: word);
   				end;//òèï çàíèìàåò 48 áàéò âðîäå...

type
   TCustomEntry = class
         constructor Create(Head_: TEntryHead;var F: File);overload;
         constructor Create;overload;
      protected
         fhead: TEntryHead;
         function GetHead: TEntryHead;virtual;
      public
         class function EntryClassName: TEntryClassName;
         class function IsValidVersion(version: integer): boolean;
         function DefaultVersion: integer;virtual;

         property Head: TEntryHead read GetHead;
         procedure WriteToFile(var F: File);virtual;
      end;

type
   TSimpleEntry= class(TCustomEntry)
         constructor Create(Head_: TEntryHead; var F: File);overload;
         constructor Create;overload;
         destructor Destroy;override;
      protected
         procedure SetBufSize(newlength: integer);
         procedure ResizeBuf(newlength: integer);
      public
         buf: array of byte;//ðàçìåð óñòàíîâëåí - head.size :))
         procedure WriteToFile(var F: File);override;
   	end;

type
   TMapType= array [0..3] of char;
   TPaletteFile = string[28];

   TMapHeader1=
   record
      MapType: TMapType;//Must be equivalent Map.MapType variable
      ECount : integer;//Entries Count
      Version: integer;//
      Author: shortstring;
      Name: shortstring;
      EnvColor: array [0..2] of byte;
      PaletteFile: TPaletteFile;
   end;

type
   TCustomMap= class
          constructor Create;
   protected
		MapType: string;
      fhead: TMapHeader1;
      function GetHead: TMapHeader1;virtual;
   public
   {$IFDEF EDITORMODE}
      Entries: TList;
   {$ELSE}
      Entries: array of TCustomEntry;
   {$ENDIF}
    function GetEntry(ind: integer): TCustomEntry;
    function EntriesCount: integer;
    procedure SetEntriesSize(newlength: integer);

      property head: TMapHeader1 read GetHead;
      property Name: shortstring read fhead.Name write fhead.Name;
      property Author: shortstring read fhead.Author write fhead.Author;

      procedure SetEnvColor(color: integer);

      procedure BeforeLoad;virtual;
      procedure AfterLoad;virtual;

      procedure Clear;virtual;
      function CreateEntry(head: TEntryHead; var f: File): TCustomEntry;virtual;
      procedure Delete(ind: integer);

      function LoadFromFile(FileName: string): integer;virtual;
      function SaveToFile(FileName: string): integer;virtual;
   end;

implementation

{ TCustomEntry }

constructor TCustomEntry.Create(Head_: TEntryHead; var F: File);
begin
   fhead:=head_;
end;

constructor TCustomEntry.Create;
begin
   fhead.EntryClass:=Self.EntryClassName;
   fhead.Size:=0;
   fhead.version:=DefaultVersion;
end;

function TCustomEntry.DefaultVersion: integer;
begin
   Result:=1;
end;

class function TCustomEntry.EntryClassName: TEntryClassName;
begin
   Result:='unknown';
end;

function TCustomEntry.GetHead: TEntryHead;
begin
//
   Result:=fhead;
end;

class function TCustomEntry.IsValidVersion(version: integer): boolean;
begin
   Result:=true;
end;

procedure TCustomEntry.WriteToFile(var F: File);
begin
   GetHead;
   BlockWrite(f, fhead, SizeOf(fhead));
end;

{ TSimpleEntry }

const
   PAGE_SIZE = 4096;

constructor TSimpleEntry.Create(Head_: TEntryHead; var F: File);
var
   i: cardinal;
begin
   inherited Create(head_, F);
   SetLength(buf, head_.size);
   i:=0;
   while head_.size-i>PAGE_SIZE do
   begin
      BlockRead(f, buf[i], PAGE_SIZE);
      Inc(i, PAGE_SIZE);
   end;
   BlockRead(f, buf[i], head_.size-i);
end;

constructor TSimpleEntry.Create;
begin
   inherited Create;
end;

destructor TSimpleEntry.Destroy;
begin
   buf:=nil;
end;

procedure TSimpleEntry.ResizeBuf(newlength: integer);
begin
   SetLength(buf, newlength);
   fhead.size:=newlength;
end;

procedure TSimpleEntry.SetBufSize(newlength: integer);
begin
   buf:=nil;
   SetLength(buf, newlength);
   fhead.size:=newlength;
end;

procedure TSimpleEntry.WriteToFile(var F: File);
var
   i: cardinal;
begin
  inherited;
   if buf<>nil then
   begin
     i:=0;
     while fhead.size-i>PAGE_SIZE do
     begin
        BlockWrite(f, buf[i], PAGE_SIZE);
        Inc(i, PAGE_SIZE);
     end;
  	  BlockWrite(f, buf[i], fhead.size-i);
   end;
end;

{ TCustomMap }

procedure TCustomMap.AfterLoad;
begin

end;

procedure TCustomMap.BeforeLoad;
begin

end;

procedure TCustomMap.Clear;
var
   i: integer;
begin
   for i:=0 to EntriesCount-1 do
      TCustomEntry(Entries[i]).Free;
   {$IFDEF EDITORMODE}
   Entries.Clear;
   {$ELSE}
   Entries:=nil;
   {$ENDIF}
end;

constructor TCustomMap.Create;
begin
   MapType:='TFKM';
   fhead.Version:=MapVersion;
   fhead.ECount:=0;
   {$IFDEF EDITORMODE}
   Entries:=TList.Create;
   {$ENDIF}
end;

function TCustomMap.CreateEntry(head: TEntryHead; var f: File): TCustomEntry;
begin
   Result:=TSimpleEntry.Create(head, F);
end;

procedure TCustomMap.Delete(ind: integer);
var
   ecount: integer;
begin
   ecount:=EntriesCount;
   if (ind>=0) and (ind<ecount) then
   begin
     GetEntry(ind).Free;
     {$IFDEF EDITORMODE}
     Entries.Delete(ind);
     {$ELSE}
     while ind<ECount-1 do
     begin
        Entries[ind]:=Entries[ind+1];
        Inc(ind);
     end;
     SetLength(Entries, ecount-1);
     {$ENDIF}
   end;
end;

function TCustomMap.EntriesCount: integer;
begin
   {$IFDEF EDITORMODE}
   Result:=Entries.Count;
   {$ELSE}
   Result:=High(Entries)+1;
   {$ENDIF}
end;

function TCustomMap.GetEntry(ind: integer): TCustomEntry;
begin
   Result:=nil;
   if (ind>=0) and (ind<EntriesCount) then
   	Result:=TCustomEntry(Entries[ind]);
end;

function TCustomMap.GetHead: TMapHeader1;
begin
   fhead.ECount:=EntriesCount;
   Result:=fhead;
end;

function TCustomMap.LoadFromFile(FileName: string): integer;
var
   f: File;
   i: integer;
   head0: TMapHeader1;
   EHead:TEntryHead;
begin
   Result:=0;
   try
      FileMode:=64;
      AssignFile(f, FileName);
      Reset(f, 1);
      BlockRead(f, head0, SizeOf(head0));

      if (head0.MapType<>MapType) or
         (head0.version<LowMapVersion) or (head0.version>HighMapVersion) then
      begin
         CloseFile(f);
         Result:=-2;
         Exit;
      end;
      Clear;
      fhead:=head0;
      BeforeLoad;
       {$IFDEF EDITORMODE}
     	for i:=0 to fhead.ECount-1 do
     	begin
       	BlockRead(F, EHead, SizeOf(EHead));
         Entries.Add(CreateEntry(EHead, F));
    	end;
      {$ELSE}
      SetLength(Entries, fhead.ECount);
    	for i:=0 to fhead.ECount-1 do
    	begin
       	BlockRead(F, EHead, SizeOf(EHead));
         Entries[i]:=CreateEntry(EHead, F);
    	end;
      {$ENDIF}

    	CloseFile(F);
      AfterLoad;
   except
      result:=-1;
   end;
end;

function TCustomMap.SaveToFile(FileName: string): integer;
var
   F: File;
   i: integer;
   head0: TMapHeader1;
begin
   Result:=0;
   head0:=head;
   try
      FileMode:=64;
      AssignFile(f, FileName);
      Rewrite(f, 1);
      BlockWrite(f, head0, SizeOf(head0));
      for i:=0 to head0.ECount-1 do
       	TCustomEntry(Entries[i]).WriteToFile(f);
      CloseFile(f);
   except
      Result:=-1;
   end;
end;

procedure TCustomMap.SetEntriesSize(newlength: integer);
   {$IFDEF EDITORMODE}
var
   i: integer;
begin
//   Entries.Clear;
   if newlength>EntriesCount then
   for i:=EntriesCount to newlength-1 do
      Entries.Add(nil);
   {$ELSE}
begin
   SetLength(Entries, newlength);
   {$ENDIF}
end;

procedure TCustomMap.SetEnvColor(color: integer);
begin
   with fhead do
   begin
      EnvColor[0]:=GetRValue(Color);
      EnvColor[1]:=GetGValue(Color);
      EnvColor[2]:=GetBValue(Color);
   end;
end;

end.
