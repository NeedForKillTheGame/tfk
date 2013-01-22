unit MyEntries;

(***************************************)
(*  Entries&Maps module version 1.0.1  *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

interface

//чтобы использовать TList вместо дин. массива, раскоментируй это:
//РЕДАКТОР БЕЗ ЭТОГО НЕ КОМПИЛИТСЯ
//А ИГРА С ЭТИМ ВЕСИТ В ДВА РАЗА БОЛЬШЕ!!!
//{$DEFINE EDITORMODE}

//КАЖДЫЙ ПОТОМОК TCustomEntry обязан:
//*грузить из файла инфу мутодом Create(head, var f file);
//*давать информацию о себе функцией
// class function EntryClassName: TEntryClassName;
//*сообщать какую версию он поддерживает функцией
// class function IsValidVersion(version: integer): boolean;
// ЭТИ CLASS-ФУНКЦИИ НЕ МОГУТ БЫТЬ ВИРТУАЛЬНЫ, ОНИ ВЫЗЫВАЮТСЯ НЕПОСРЕДСТВЕННО У КЛАССА!!!

//*сообщать текущую версию самого ОБЪЕКТА а не инфы из файла...
// function DefaultVersion: integer;

//*записывать инфу о себе, размере, версии в FHEAD функцией
//function GetHead: TEntryHead;

//В принципе фффсё...
//Пример - TBricksEntry в соседнем модуле


{$IFDEF EDITORMODE}
uses Classes;
{$ENDIF}

const
   MapVersion=1;
   LowMapVersion=1;
   HighMapVersion=5;

type
    TEntryClassName=string[15];
    TEntryName = string[15];

//    BFile=^File;

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
   				end;//тип занимает 48 байт вроде...

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
         buf: array of byte;//размер установлен - head.size :))
         procedure WriteToFile(var F: File);override;
   	end;

type
   TMapType= array [0..3] of char;
   TPaletteFile = string[28];
   string64 = string[64];
   string32 = string[32];
   string16 = string[16];

   TMapHeader1=
   record
      MapType: TMapType;//Must be equivalent Map.MapType variable
      ECount : integer;//Entries Count
      Version: integer;//
      Author: string64;
      pass: string16;
      reserved0: array [0..173] of byte;
      Name: shortstring;
      EnvColor: array [0..2] of byte;
      gametype: byte;
      fade_mode: boolean;
      reserved: array [1..27] of byte;
   end;

type
   TCustomMap= class
          constructor Create;
          destructor Destroy;override;
   protected
		MapType, MapType2: string;
      fhead: TMapHeader1;
      function GetHead: TMapHeader1;virtual;
   public
      Entries: array of TCustomEntry;
      lastfilename: string;
    function GetEntry(ind: integer): TCustomEntry;
    function EntriesCount: integer;
    procedure SetEntriesSize(newlength: integer);

      property head: TMapHeader1 read GetHead;
      property Name: shortstring read fhead.Name write fhead.Name;
      property Author: string64 read fhead.Author write fhead.Author;

      procedure BeforeLoad;virtual;
      procedure AfterLoad;virtual;

      procedure Clear;virtual;
      function CreateEntry(head: TEntryHead; var f: File): TCustomEntry;virtual;
      procedure Delete(ind: integer);

      function LoadFromFile(FileName: string): integer;virtual;
      function SaveToFile(FileName: string): integer;virtual;

      function FullSize: cardinal;

    	function GetFileName: string;
   end;

function AppendSectionToFile(section: TCustomEntry; inputfile: string; outputfile: string; multi: boolean = false): integer;
function DeleteSectionFromFile(cl: TEntryClassName; inputfile, outputfile: string): integer;
function RewriteMapHeader(head: TMapHeader1; inputfile, outputfile: string): integer;

implementation

function AppendSectionToFile(section: TCustomEntry; inputfile: string; outputfile: string; multi: boolean = false): integer;
var
  	Map: TCustomMap;
   i: integer;
   temp: TCustomEntry;
   f: boolean;

begin
   Result:=0;
   i := 0;
   Map:=TCustomMap.Create;
   temp:=nil;
   with Map do
   begin
   	if LoadFromFile(inputfile)<0 then
   	begin
      	Result:=-1;
      	Exit;
   	end;
      f:=false;
      if not multi then
      for i:=0 to EntriesCount-1 do
         if Entries[i].Head.EntryClass=section.Head.EntryClass then
         begin
            //найдена секция!!!
            temp:=Entries[i];
            Entries[i]:=section;
            f:=true;
            break;
         end;
      if not f then
      begin
   		SetLength(Entries, EntriesCount+1);
   		Entries[Entriescount-1]:=section;
      end;
      SaveToFile(outputfile);
      if not f then
      	SetLength(Entries, EntriesCount-1)
         else Entries[i]:=temp;
      Free;
   end;
end;

function DeleteSectionFromFile(cl: TEntryClassName; inputfile, outputfile: string): integer;
var
  	Map: TCustomMap;
   i, j: integer;

begin
   Result:=0;
   Map:=TCustomMap.Create;
   with Map do
   begin
   	if LoadFromFile(inputfile)<0 then
   	begin
      	Result:=-1;
      	Exit;
   	end;
      for i:=0 to EntriesCount-1 do
         if Entries[i].Head.EntryClass=cl then
         begin
            //найдена секция!!!
            Entries[i].Free;
            for j:=i to EntriesCount-2 do
                Entries[j]:=Entries[j+1];
      		SetLength(Entries, EntriesCount-1)
         end;
      SaveToFile(outputfile);
      Free;
   end;
end;

function RewriteMapHeader(head: TMapHeader1; inputfile, outputfile: string): integer;
var
   Map: TCustomMap;
begin
   Map:=TCustomMap.Create;
   Map.LoadFromFile(inputfile);
   Map.fhead:=head;
   Map.SaveToFile(outputfile);
   Map.Free;
   Result:=1;
end;

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
   lastfilename:='';
   for i:=0 to EntriesCount-1 do
      if entries[i]<>nil then
      	TCustomEntry(Entries[i]).Free;
   Entries:=nil;
end;

constructor TCustomMap.Create;
begin
   MapType:='TFKM';
   MapType2:='TFKМ';
   fhead.Version:=MapVersion;
   fhead.ECount:=0;
   lastfilename:='';
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
   pos: integer;
   head0: TMapHeader1;
   EHead:TEntryHead;

   function Decode(s: string16): string16;
   var
      i: integer;
   begin
      for i:=1 to length(s) do
         s[i]:=chr(ord(s[i]) xor 138);
      Result:=s;
   end;

begin
   Result:=0;
   try
      FileMode:=64;
      AssignFile(f, FileName);
      Reset(f, 1);
      BlockRead(f, head0, SizeOf(head0));

      if (head0.MapType<>MapType) and
         (head0.MapType<>MapType2) or
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
         pos:=FilePos(F)+integer(EHead.size);
         Entries[i]:=CreateEntry(EHead, F);
         if FilePos(F)<>pos then
            Seek(F, pos);
         if Entries[i].head.size=0 then
            Continue;
         if Entries[i]=nil then
         begin
            CloseFile(f);
      		Clear;
      		result:=-1;
            Exit;
         end;
    	end;
      {$ENDIF}

    	CloseFile(F);
   	lastfilename:=filename;
      AfterLoad;
   except
      Clear;
      result := -1;
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
begin
   SetLength(Entries, newlength);
end;

function TCustomMap.FullSize: cardinal;
var
   i: integer;
begin
   Result:=SizeOf(TMapHeader1)+EntriesCount*SizeOf(TEntryHead);
   for i:=0 to EntriesCount-1 do
      Result:=Result+Entries[i].GetHead.size;
end;

destructor TCustomMap.Destroy;
begin
   Clear;
  inherited;
end;

function TCustomMap.GetFileName: string;
var
   k, l: integer;
begin
   Result:=lastfilename;
   k:=length(result);
   l:=length(result);
   while (k>0) and (result[k]<>'\') do Dec(k);
   while (l>0) and (result[l]<>'.') do Dec(l);
   if (k>0) and (l>0) then
      Result:=Copy(Result, k+1, l-k-1);
end;

end.
