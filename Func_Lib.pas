unit Func_Lib;
(******************************)
(*       TIME FOR KILL        *)
(* Created by XProger         *)
(* begin: 29.10.2003          *)
(* end:   --.--.----          *)
(*                            *)
(* site: www.XProger.narod.ru *)
(* e-mail: XProger@list.ru    *)
(******************************)
interface

uses
 Windows;


type
 TFindData = record
  Handle: DWORD;
  Data: TWin32FindData;
 end;

//Dlls
 function LoadDll(var Dll: THandle; const FileName: string): boolean;
 function LoadProc(Dll: THandle; var Proc: pointer; const ProcName: string): boolean;
 procedure FreeDll(var Dll: THandle);
//Files
 procedure FindClose(var FindData: TFindData);
 function FindMatchingFile(var FindData: TFindData): integer;
 function FindFirst(const Path: string; var FindData: TFindData): boolean;
 function FindNext(var FindData: TFindData): boolean;
 function ExtractFileDir(const FileName: string): string;
 function ExtractFileName(const FileName: string): string;
 function ExtractFileNameEx(const FileName: string): string;
 function ExtractFileExt(const FileName: string): string;
 function FileExists(const FileName: string): boolean;
 function GetSystemDir: string;

 procedure incs(var x: single; r: single);
 procedure decs(var x: single; r: single);

//Strings
 function IntToStr(i: integer): String;
 function StrToInt(Str: String): integer;
// function StrToFloat(const S: string): Extended;

 function UpperCase(const S: string): string;
 function LowerCase(const S: string): string;
 function Tag_Length(const s: string): integer;
 function StrLCopy(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar; assembler;
 //Advanced string functions
 function StrSpace(var Str: string): string;
 procedure DelSpace(var Str: string);

//Float
 function Conv(cs: double; numb: integer): double;

type
   TBits = array [0..7] of boolean;

 function BitsToByte(b: TBits): byte;
 procedure ByteToBits(b: byte; var bits: TBits);
//var
 //ModDir      : string;

implementation

//Dlls
function LoadDll(var Dll: THandle; const FileName: string): boolean;
begin
Dll    := LoadLibrary(PChar(FileName));
Result := Dll <> 0;
end;

function LoadProc(Dll: THandle; var Proc: pointer; const ProcName: string): boolean;
begin
Proc:=nil;
Proc:=GetProcAddress(Dll, PChar(ProcName));
Result:=Proc<>nil;
end;

procedure FreeDll(var Dll: THandle);
begin
FreeLibrary(Dll);
Dll := 0;
end;

//Files
procedure FindClose(var FindData: TFindData);
begin
if FindData.Handle <> INVALID_HANDLE_VALUE then
 begin
 Windows.FindClose(FindData.Handle);
 FindData.Handle := INVALID_HANDLE_VALUE;
 end;
end;

function FindMatchingFile(var FindData: TFindData): integer;
begin
while FindData.Data.dwFileAttributes <> 0 do
 if not FindNextFile(FindData.Handle, FindData.Data) then
  begin
  Result := GetLastError;
  Exit;
  end
 else
  break;
Result := 0;
end;

function FindFirst(const Path: string; var FindData: TFindData): boolean;
begin
Result := false;
FindData.Handle := FindFirstFile(PChar(Path), FindData.Data);
if FindData.Handle <> INVALID_HANDLE_VALUE then
 Result := true
else
 FindClose(FindData);
end;

function FindNext(var FindData: TFindData): boolean;
begin
if FindNextFile(FindData.Handle, FindData.Data) then
 Result := true
else
 Result := false;
end;

function ExtractFileDir(const FileName: string): string;
var
 i: integer;
begin
for i := Length(FileName) downto 1 do
 if FileName[i] = '\' then break;
Result := Copy(FileName, 1, i-1);
end;

function ExtractFileName(const FileName: string): string;
var
 i: integer;
begin
Result:='';
for i := Length(FileName) downto 1 do
 if FileName[i] = '\' then
  break
 else
  Result := FileName[i] + Result;
end;


function ExtractFileNameEx(const FileName: string): string;
var
 k, l : integer;
begin
k := Length(FileName);
l := k;
while (k > 0) and (FileName[k] <> '\') do Dec(k);
while (l > 0) and (FileName[l] <> '.') do Dec(l);
if l = 0 then l := Length(FileName) + 1;
if (l > 0) then
 Result := Copy(FileName, k + 1, l - k - 1)
else
 Result := FileName;
end;

function ExtractFileExt(const FileName: string): string;
var
 i: integer;
begin
Result:='';
for i:=Length(FileName) downto 1 do
 if FileName[i] <> '.' then
  Result := FileName[i] + Result
 else
  break;
end;

function FileExists(const FileName: string): boolean;
var
 F: File;
begin
FileMode := 64;
AssignFile(F, FileName); //Открываем файл
{$I-}                    //Отмена IO ошибок
Reset(F);                //Открываем файл для чтения
{$I+}                    //Включаем проверку IO ошибок
Result := IOResult = 0;
if Result then
 CloseFile(F);
end;

//Get System Directory
function GetSystemDir: string;
var
 iLength: Cardinal;
begin
iLength := 255;
setLength(Result, iLength);
iLength := GetSystemDirectory(PChar(Result), iLength);
setLength(Result, iLength);
end;

//Strings
function IntToStr(i: integer): String;
begin
Str(i, Result);
end;

function StrToInt(Str: String): integer;
var
 Er: integer;
begin
Val(Str, Result, Er);
if Er <> 0 then
 Result := 0;
end;

function UpperCase(const S: string): string;
var
 i: integer;
begin
Result:='';
for i:=1 to Length(S) do
 Result:=Result+UpCase(s[i]);
end;

function LowerCase(const s: string): string;
var
 i, l   : integer;
 Rc, Sc : PChar;
begin
//В отличии от стандартной, работает с кириллицей :)
l := Length(s);
SetLength(Result, l);
Rc := Pointer(Result);
Sc := Pointer(s);
for i := 1 to l do
 begin
 if s[i] in ['A'..'Z', 'А'..'Я'] then
  Rc^ := Char(Byte(Sc^) + 32)
 else
  Rc^ := Sc^;
 inc(Rc);
 inc(Sc);
 end;
end;

// Длинна строки без тегов цвета
function Tag_Length(const s: string): integer;
var
 i : integer;
begin
Result := Length(s);
for i := 1 to Length(s) do
 if s[i] = '^' then
  dec(Result, 2);
end;


function StrLCopy(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
        MOV     EBX,ECX
        XOR     AL,AL
        TEST    ECX,ECX
        JZ      @@1
        REPNE   SCASB
        JNE     @@1
        INC     ECX
@@1:    SUB     EBX,ECX
        MOV     EDI,ESI
        MOV     ESI,EDX
        MOV     EDX,EDI
        MOV     ECX,EBX
        SHR     ECX,2
        REP     MOVSD
        MOV     ECX,EBX
        AND     ECX,3
        REP     MOVSB
        STOSB
        MOV     EAX,EDX
        POP     EBX
        POP     ESI
        POP     EDI
end;

//Advanced string functions
function StrSpace(var Str: string): string;
var
 sp : integer;
begin
sp := pos(' ', Str);
if sp < 1 then
 sp := Length(Str)
else
 sp := sp - 1;
Result := Copy(Str, 1, sp);
Delete(Str, 1, sp + 1);
end;

procedure DelSpace(var Str: string);
var
 i: integer;
begin
for i := 1 to Length(Str) do
 if Str[i] <> ' ' then break;
Str := Copy(Str, i, Length(Str));

for i := Length(Str) downto 1 do
 if Str[i] <> ' ' then break;
Str := Copy(Str, 1, i);
end;

////////////////////////////////////////////////////////////////
// Числа с плавающей точкой                                   //
////////////////////////////////////////////////////////////////

procedure incs(var x: single; r: single);
begin
x := x + r;
end;

procedure decs(var x: single; r: single);
begin
x := x - r;
end;

{--------------------------------------------------------------------------}
{Функция представления чисел с плавающей точкой и нужным числом разрядов.  }
{Пример: Conv(2.005,2) возвращает 2.01; Conv(2.5,0) возвращает 3           }
{--------------------------------------------------------------------------}
function Conv(cs: double; numb: integer): double;
var
 db          : double;
 i           : int64;
 ii, ink, i1 : integer;
begin
ink := 1;
for ii := 1 to numb do
 ink := ink*10;
db := cs*ink*100;
i  := trunc(int(db) / 100);
i1 := trunc(db - i*100);
if i1 > 49 then
 inc(i);
Result := i/ink;
end;

function BitsToByte(b: TBits): byte;
begin
   Result:=Ord(b[0])+Ord(b[1]) shl 1+Ord(b[2])shl 2+Ord(b[3] )shl 3 + Ord(b[4] )shl 4 + Ord(b[5] )shl 5 + Ord(b[6] )shl 6 + Ord(b[7] )shl 7;
end;

procedure ByteToBits(b: byte; var bits: TBits);
begin
   bits[0]:=b and 1>0;
   bits[1]:=b and 2>0;
   bits[2]:=b and 4>0;
   bits[3]:=b and 8>0;
   bits[4]:=b and 16>0;
   bits[5]:=b and 32>0;
   bits[6]:=b and 64>0;
   bits[7]:=b and 128>0;
end;

end.
