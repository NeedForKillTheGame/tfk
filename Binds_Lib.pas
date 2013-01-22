unit binds_lib;

interface

const
 BKeys = 24;

type
  TKey = record
   Value, Value2 : integer;
   Down          : boolean;
  end;

  TKeyArray = array [0..BKeys] of TKey;

  // 255 (keys) + 8 (mouse) = 263
  TBindedCommands = array [0..276] of string;
  TCommands = array [0..10] of string;

const
   PBinds : array [0..BKeys, 1..2] of string=
   (('jump',        'p2jump'),
    ('crouch',      'p2crouch'),
    ('moveleft',    'p2moveleft'),
    ('moveright',   'p2moveright'),
    ('fire',        'p2fire'),
    ('use',         'p2use'),
    ('',            ''),
    ('',            ''),
    ('lookup',      'p2lookup'),
    ('lookdown',    'p2lookdown'),
    ('lookcenter',  'p2lookcenter'),
    ('nextweapon',  'p2nextweapon'),
    ('prevweapon',  'p2prevweapon'),
    ('weapon1',     'p2weapon1'),
    ('weapon2',     'p2weapon2'),
    ('weapon3',     'p2weapon3'),
    ('weapon4',     'p2weapon4'),
    ('weapon5',     'p2weapon5'),
    ('weapon6',     'p2weapon6'),
    ('weapon7',     'p2weapon7'),
    ('weapon8',     'p2weapon8'),
    ('weapon9',     'p2weapon9'),
    ('scoreboard',  ''),
    ('strafeleft',  'p2strafeleft'),
    ('straferight', 'p2straferight'));

var
   PKeys : array [1..2] of TKeyArray;
   Commands: TBindedCommands;

function Bind_Cmd(Cmd: ShortString): boolean;
procedure BindKey(pl: integer; key, keyvalue: integer);
procedure Bind_Init;
procedure SaveBinds(const FileName: string);
procedure UpdateKeys;

implementation

uses
 Windows, TFK, Engine_Reg, Type_Lib, Func_Lib,
 Constants_Lib, SysUtils, Menu_Lib;

var
 counter: integer;

procedure Bind_Init;
begin
counter := 0;

PKeys[1, 0].Value  := VK_UP;
PKeys[1, 1].Value  := VK_DOWN;
PKeys[1, 2].Value  := VK_LEFT;
PKeys[1, 3].Value  := VK_RIGHT;
PKeys[1, 5].Value  := VK_SPACE;

PKeys[2, 0].Value  := ord('W');
PKeys[2, 1].Value  := ord('S');
PKeys[2, 2].Value  := ord('A');
PKeys[2, 3].Value  := ord('D');
PKeys[2, 4].Value  := ord('H');
PKeys[2, 5].Value  := ord('E');
PKeys[2, 8].Value  := ord('T');
PKeys[2, 9].Value  := ord('F');
PKeys[2, 10].Value := ord('G');
PKeys[2, 11].Value := ord('R');
PKeys[2, 12].Value := ord('Q');

Console_CmdReg('bind', @Bind_Cmd);
Console_CmdReg('getbinding', @Bind_Cmd);
Console_CmdReg('getkeybinding', @Bind_Cmd);
Console_CmdReg('unbind',@Bind_Cmd);
Console_CmdReg('unbindkeys', @Bind_Cmd);
end;

procedure BindKey(pl: integer; key, keyvalue: integer);
var
 i, j : integer;
begin
with PKeys[pl, key] do
 if (keyvalue = value) or (keyvalue = value2) then
  begin
  Value  := keyvalue;
  Value2 := 0;
  end
 else
  begin
  Value2 := Value;
  Value  := keyvalue;
  end;

for j := 1 to 2 do
 for i := 0 to BKeys do
  if (key <> i) or (pl  <> j) then
   with PKeys[j, i] do
    if (keyvalue = value) then
     begin
     Value  := Value2;
     Value2 := 0;
     end
    else
     if keyvalue = value2 then
      Value2 := 0;
SaveBinds('config.cfg');
end;

function BindPlayerKey(key: integer; s: string): boolean;
var
 i, j : integer;
begin
Result := false;
if Key < 0 then Exit;

for j := 1 to 2 do
 for i := 0 to BKeys do
  if s = PBinds[i, j] then
   begin
   BindKey(j, i, key);
   Result := true;
   Exit;
   end;
end;

function FindPlayerKey(s: string; var key: TKey): boolean;
var
 i, j : integer;
begin
Result := false;
if s = '' then Exit;

for j := 1 to 2 do
 for i := 0 to BKeys do
  if s = PBinds[i, j] then
   begin
   key    := PKeys[j, i];
   Result := true;
   Exit;
   end;
end;

function FindCommandKey(s: string; var key: integer): boolean;
var
 s1 : string;
begin
Result := false;
Inc(key);
while key < 264 do
 begin
 s1 := Commands[Key];
 if StrSpace(s1) = s then
  begin
  Result := true;
  Exit;
  end;
 Inc(Key);
 end;
end;

function Bind_Cmd(Cmd: ShortString): boolean;
var
 par   : array [1..3] of string;
 i, j  : integer;
 k     : integer;
 str   : string;
 key   : integer;
 plkey : TKey;
begin
Result := true;
str    := LowerCase(cmd);
for i := 1 to 2 do
 par[i] := StrSpace(str);

par[3] := str;

if par[1] = 'bind' then
 begin
 key := Input_KeyNum(PChar(par[2]));
 if (Key > 0) and (par[3] <> '') then
  if not BindPlayerKey(key, par[3]) then
   begin
   Commands[Key] := par[3];
   Log('^2Command binded');
   SaveBinds('config.cfg');
   end
  else
   Log('^2Key ' + par[2] + ' binded')
 else
  Log('^1Can''t bind this key');
 Exit;
 end;

if par[1] = 'getbinding' then
 begin
  if FindPlayerKey(par[2], plkey) then
   begin
   Log('^2 Control keys binding: ');
   if plkey.value > 0 then
    begin
    Log('^2 - ' + Input_KeyName(plkey.value));
    if plkey.value2 > 0 then
     Log('^2 - ' + Input_KeyName(plkey.value2));
    end
   else
    Log('^1  NO VALUES');
   end
  else
   begin
   // XProger : эта феня не пашет!!!
   Log('^2 Command keys binding: ');
   key := 0;
   i   := 0;
   while FindCommandKey(par[2], key) do
    begin
//    if (Input_KeyName(key) <> '') and (Commands[key] <> '') then
     Log('^2  ' + Input_KeyName(key) + ' : ' + Commands[key]);
    Inc(i);
    end;

   if i = 0 then
    Log('^1  NO BINDS');
   end;
 Exit;
 end;

if par[1] = 'getkeybinding' then
 begin
 Key := Input_KeyNum(PChar(par[2]));
 if Key > 0 then
  begin
  Log('^2Key binding: ');
  j := 0;
  for k := 1 to 2 do
   for i := 0 to BKeys do
    with PKeys[k, i] do
     if (Value = key) or (Value2 = key) then
      begin
      Log('^2 Control: ' + PBinds[i, k]);
      Inc(j);
      end;

  if Commands[Key] <> '' then
   begin
   Log('^2 Command: ' + Commands[Key]);
   Inc(j);
   end;

  if j = 0 then
   Log('^1 no binds for this key');
  end
 else
  Log('^2Invalid key');
 Exit;
 end;

if par[1] = 'unbind' then
 begin
 Result := true;
 Key := Input_KeyNum(PChar(par[2]));
 if Key > 0 then
  begin
  j := 0;
  if Commands[key] <> '' then
   begin
   Commands[key] := '';
   Inc(j);
   end;

  for k := 1 to 2 do
   for i := 0 to BKeys do
    with PKeys[k, i] do
     begin
     if Value = key then
      begin
      Value  := Value2;
      Value2 := 0;
      Inc(j)
      end;
     if Value2 = key then
      begin
      Value2 := 0;
      Inc(j);
      end;
     end;
     
  if j = 0 then
   Log('^1no binds for this key')
  else
   Log('^2key unbinded');
  end
 else
  Log('^2Invalid key');
 Exit;
 end;

if par[1] = 'unbindkeys' then
 begin
 for i := Low(commands) to High(commands) do
  commands[i] := '';
 for j := 1 to 2 do
  for i := 0 to BKeys do
   begin
   PKeys[j, i].Value  := 0;
   PKeys[j, i].Value2 := 0;
   end;
 Log('^1All keys unbinded');
 Exit;
 end;

Result := false;
end;

function InputKey(key: integer): boolean;
begin
Result := Input_KeyDown(key)
end;

procedure UpdateKeys;
var
 i, j : integer;
 s    : string;
begin
if Console.Show or onSay then
 begin
 for i := 0 to BKeys do
  begin
  PKeys[1, i].Down := false;
  PKeys[2, i].Down := false;
  end;
 Exit;
 end;

for j := 1 to 2 do
 for i := 0 to BKeys do
  with PKeys[j, i] do
   Down := InputKey(Value) or InputKey(Value2);

if counter > 0 then
 Dec(counter)
else
 for i := low(commands) to high(commands) do
  if (commands[i] <> '') and InputKey(i) then
   begin
   Counter := 25;
   s := commands[i];
   if s[1] = '"' then Delete(s, 1, 1);
   if s[Length(s)] = '"' then Delete(s, Length(s), 1);
   Console_CMD(s);
   end;
end;

procedure SaveBinds(const FileName: string);
const
 nxt = #13#10;
var
 i, j  : integer;
 cfg   : TextFile;
 s, s_ : string;
 data  : string;
begin
 try // Вдруг с диска читаем
  FileMode := 64;
  AssignFile(cfg, Engine_ModDir + FileName);
  if not FileExists(Engine_ModDir + FileName) then
   Rewrite(cfg);
  Reset(cfg);

  Data := 'unbindkeys' + nxt;
  for j := 1 to 2 do
   for i := 0 to BKeys do
    if PBinds[i, j] <> '' then
     with PKeys[j, i] do
      begin
   	  if value > 0 then
       Data := Data + 'bind ' + Input_KeyName(Value) + ' ' + PBinds[i, j] + nxt;
   	  if value2 > 0 then
       Data := Data + 'bind ' + Input_KeyName(Value2) + ' ' + PBinds[i, j] + nxt;
      end;

  for i := Low(Commands) to High(Commands) do
 	 if Commands[i] <> '' then
    Data := Data + 'bind ' + Input_KeyName(i) + ' ' + Commands[i] + nxt;

  while not eof(cfg) do
   begin
   Readln(cfg, s);
   s_ := s;
   s_ := trim(LowerCase(StrSpace(s_)));
   if (s_ <> 'bind') and
      (s_ <> 'unbind') and
      (s_ <> 'unbindkeys') then
    Data := Data + s + nxt;
   end;
  FileMode := 2;
  {$I-}          //Отмена IO ошибок
  Rewrite(cfg);
  {$I+}
  Delete(Data, Length(Data) - 1, 2);
  if IOResult = 0 then
   Write(cfg, Data);
  CloseFile(cfg);
 except
  Log('^1Couldn''t save binds in ^7"' + FileName + '^7"');
 end;
end;

end.
