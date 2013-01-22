unit Arena_Lib;

interface


uses
 Windows, WinSock, SysUtils,
 Engine_Reg,
 Constants_Lib;

// Ответ на "проверку на живучесть"
procedure Arena_Ping;

// Выдаёт строку формата "IP:Port IP:Port..." содержащую в себе серверы игры
procedure Arena_GetServers;

// Удаляет все запущенные процессы (по идее он только один)
procedure Arena_Free;

var
 Arena_Timer   : DWORD;
 Arena_Refresh : boolean = false;

implementation

var
 Arena_ID : integer;

procedure Arena_Free;
var
 exc : DWORD;
begin
if Arena_ID = 0 then Exit;
GetExitCodeThread(Arena_ID, exc);
TerminateThread(Arena_ID, exc);
end;

function Arena(const mode: string; get: boolean): string;
var
 wData : WSADATA;
 addr  : sockaddr_in;
 sock  : integer;
 error : integer;
 buf   : array [0..1023] of Char;
 str   : string;
 phe   : PHostEnt;
begin
Result := '';
WSAStartup($0101, wData);
phe := gethostbyname(PChar(string(arena_address)));
if phe = nil then
 begin
 WSACleanup();
 Exit;
 end;

sock := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
if sock =  INVALID_SOCKET then
 begin
 WSACleanup();
 Exit;
 end;

addr.sin_family := AF_INET;
addr.sin_port   := htons(80);
addr.sin_addr   := PInAddr(phe.h_addr_list^)^;

error := connect(sock, addr, sizeof(addr));
if error = SOCKET_ERROR then
 begin
 closesocket(sock);
 WSACleanup();
 Exit;
 end;

str := 'GET http://' + arena_address + '/?action=arena&mode=' + mode +
       '&port=' + IntToStr(sv_port) + ' HTTP/1.0'#13#10#13#10;
send(sock, str[1], Length(str), 0);

if get then
 begin
 ZeroMemory(@buf, 1024);
 error := recv(sock, buf, 1024, 0);
 while (error > 0) or (error = -1) do
  begin
  if error = -1 then break;
  Result := Result + Copy(buf, 0, error);
  error  := recv(sock, buf, 1024, 0);
  end;
 end;
closesocket(sock);
WSACleanup();
if Result <> '' then
 Result := Copy(Result, pos(#13#10#13#10, Result) + 4, Length(Result));
end;

// Послать серверу весточку...
procedure Arena_PingThread;
begin
Arena('ping', false);
Arena_ID := 0;
end;

procedure Arena_Ping;
var
 id : DWORD;
begin
if Arena_ID <> 0 then Exit;
Arena_ID := CreateThread(nil, 128, @Arena_PingThread, nil, 0, id);
Arena_Timer := GetTickCount + 30000;
end;

// Выдаёт строку формата "IP:Port IP:Port..." содержащую в себе серверы игры
procedure Arena_GetThread;
var
 i   : integer;
 str : string;
begin
try
Arena_Refresh := true;
str := Arena('view', true);
if str <> '' then
 begin
 i := pos(' ', str);
 while i <> 0 do
  begin
  Console_CMD('net_info ' + Copy(str, 1, i - 1));
  str := Copy(str, i + 1, Length(str));
  i := pos(' ', str);
  end;
 end;
Arena_Refresh := false;
Arena_ID      := 0;
except
end;
end;

procedure Arena_GetServers;
var
 id : DWORD;
begin
if Arena_ID <> 0 then Exit;
Arena_ID := CreateThread(nil, 128, @Arena_GetThread, nil, 0, id);
end;


end.