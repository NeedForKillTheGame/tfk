unit NET_Lib;

interface

// �� ��� ����� ��������� - ������
// ����� ���� �������� � �������, �.�. ������ � ������� =)
// ����� ���� ��� ��� � � ���� �� ������ ��������� �� ����
// ������ ������ =) ������ �������� ��� ��� ���� 8)
// ��� ��� ���������?
// ��������� TFK ����� "gowindow" "net_create 25666"
// ��� �� ������� �������! ����������? ;)
// �� �������� TFK ��������� ��� ���� ����� ����������
// � ����� "gowindow" "net_create" - ��� ������ :)
// ����� �� ������� ������� ��� "net_send Hello Server!"
// ������������� �� ���� ������� � � ����!
// �� ����� ���� ���������! :)

// ===================================================//
// ������ ������� ������� ������ ��� ������ � �����:

// NET_Init - �� �������!

// NET_Free - ��. ����������! ;)

// NET_InitSocket(IP: PChar; Port: WORD): integer;
// �������� ������, ���� ���� � ��� :)
// ���� �� ������� - ������ �� ������
// ��� �������� 0 ����� - ���������� ����� ���������
// ���� �� ��������� 1024..65535
// ��� ���������� ��� �������. � ��� ������� � ��� ����� �� ���������� �����
// ��� ��� ���������� �� �� �������� �� ������ ����� ����!
// �������� > 0

// NET_GetLocalIP: PChar -  ��������� IP ����������

// NET_GetExternalIP: PChar - IP � ����� � �������

// NET_GetHost: PChar - ��� ������ ���������

// NET_HostToIP(Host: PChar): PChar - ��������� ���� � IP

//� ������ ������ ��� ������� ������ � �����
// ���� �����, � �� ������������� ������. �����
// �� ������� ������������ ��� ������������ � ����� � ������������.
// ������������ ������ ������ 65507 ����
// ���������� �� ����������� ���������� Anti Packet Lost
// ������� ������ ����� ��������, ������, ��� ��������� ������
// � ������� �����, ����� ��� �������� :)
// ����� ���������! ��� �������� �������� ������ ������ ���������� �
// ��������� 1 ����, � ��� APL ����� 3 �����.
// ����� ��� ��������� UDP ������ ����� 16 ����.
// ����� ��������� ������ �����, � ������� ������� ��������� ������.
// ���� �� ������� �� ���������� �� ������ �� ����� ���������
// �� ������ ���� ����� � �������� ��������. :)
// ������ ������������� �� �� ����� � ��������.
// � ��� ���� ��������! ������� ���������� ������� �� ����������
// ����� ���������� ������� ��������!
// ���� ���� ���������� ����: ������ ������������ ����������������� ������
// ��� ������, ��� ������������ �� ����� ����� �� ����
// ����������� � �������. �� ������ ����� ���� �� ����������
// ��� ��� ������ ����� ����� ����� ���� � ����� �������� ����.
// �� ����� ��... ������ �������.

// NET_Clear - ������� ������ ��������

// NET_ClearAPL - ������� ������ APL �������

// NET_Write(Buf: pointer; Count: integer): boolean
// �������� � ����� �������� ��������� ������ � ���������� Count ����

// NET_Recv(Buf: pointer; Count: integer; var IP: PChar; var Port: integer): integer
// ��������� ��������� ����� �� ������ �������� :)
// ��������� > 0

// NET_Send(IP: PChar; Port: WORD; APL: boolean): integer; stdcall; external EngDLL;
// ��������� ����� �� ��������� IP � Port
// ��� IP = nil �������� �� ����� (BROADCAST)
// ��������! ����� �������� ������ ����� �������� �� ���������.

// �� ��� ������ � �� =)
// � �� 90% ������, ��� ������ � ������� ���� ������ ����,
// �.�. ����� ��� "�������"!

uses
 Windows, SysUtils,
 Engine_Reg,
 OpenGL,
 Func_lib,
 Type_Lib,
 Graph_lib,
 Arena_Lib;

const
 NET_MAPBUFSIZE = 1024;

 NM_SINFO      = 1;
 NM_RINFO      = 2;
 NM_CONNECT    = 3;
 NM_DISCONNECT = 4;
 NM_MSG        = 5;

 NM_PING       = 6;
 NM_PONG       = 7;
 NM_PINGS      = 8;
 NM_BUSY       = 9;

 NM_INVITE     = 10;
 NM_ACCEPT     = 11;
 NM_JOIN			= 12;
 NM_DISJOIN    = 13;

 NM_GAMEINFO  	= 20;

 NM_PLAYERS    = 21;
 NM_SAY        = 22;
 NM_ADDPLAYER  = 23;
 NM_DELPLAYER  = 24;
 NM_TEAMJOIN    = 25;

 NM_GAMEMSG		= 30;
 NM_OBJECTS    = 31;
 NM_HITS       = 32;
 NM_RESPAWN    = 33;
 NM_SHOTOBJ		= 34;  //������, �������, ������, ���
 NM_SHOTOBJ_KILL = 35;//������ ����������... � ���� ��������
 NM_FREEOBJ		= 36;  //���������� �������
 NM_SHOT       = 37;

 NM_CHANGENAME = 51; //��� �� ������������ � ��������� � �� ����� :)

 //��������� ��� �����������
 NM_CLIENTLEAVE		= 200;
 NM_TIMEOUT				= 201;
 NM_SERVERLEAVE		= 202;
 NM_KICK          = 203;

 // �������� ���� �� ����
 NM_MAP_GET  = 100; // ������ �� ���������� �����
 NM_MAP_SIZE = 101; // ������ ������ ��� ����������� �����
 NM_MAP_BUF  = 102; // ��������� ����� �����
 NM_MAP_END  = 104; // ��������� �� �������� �������� �����
 
const
//for INFO
	INFO_SERVER	  	= 1;
	INFO_PLAYERS 	= 2;
   INFO_OBJS 	  	= 4;
   INFO_STATS   	= 8;
   INFO_PHYS      = 16;

   INFO_START		= 1;
   INFO_LOAD 		= 30;

const
	PINGSTATMAX = 10;

type
 TNET_Type = (NT_NONE, NT_SERVER, NT_CLIENT);

 TNP_ServerInfo = record
  	MaxPlayers     : Byte;
 	Players        : Byte;
  	Password       : boolean;
  	MapCRC32       : DWORD;
   session			: word;
   gametype			: word;
   servertime     : word;
   warmup         : boolean;
   warmuparmor    : byte;
   res1, res2     : word;
   stopped			: boolean;
 end;

 TNP_ConnectParams =
 	record
      Version: byte;
      NET_ID: integer;
   end;

 TSpectator =
   record
      name: string;
      ping: word;
   end;

 TClient = class
  constructor Create(IP: string; Port: word; Name_: string);
  destructor Destroy; override;
  private
   FTime, FLastPing : DWORD;
   FIP   : string;
   FPort : Word;
   fName : string;

   fStatPing: word;
   pings: array [0..PINGSTATMAX-1] of word;
   //�� ��������� 10 ������ ���������� ������� ����� ��������
   //��� ����������� ���� - ���� ����� �� 1.5 �� 0.5

   function GetIP: PChar;
  public
   // ��� ������ ���� �� ���� (������� ������� ���� �����)
   map_buf  : PByteArray;
   map_size : integer;
   ///////////////
   Ping  : DWORD;
   pTimer: byte;
   players_count: byte;
   procedure RecvPing;
   procedure SendPing;
   procedure SendPong;
   procedure SendDisconnect(reason: byte);
   procedure Send(APL: boolean);
   function map_download: boolean;

   property Name: string read fName write fName;
   // XProger: �� ��� ����� ����� ��������� ��������� �����? ��� ����! ;)))
   property LastPing: DWORD read flastping write FLastPing;
   procedure ClearPing;

   property IP   : string read FIP;
   property IP_   : PChar read GetIP;
   property Port : word read FPort;
   function Valid(t: byte): boolean;
   property StatPing: word read fStatPing;
 end;

//NET MACHINE
//  TNet_Exception = class(TException);

  TNET_Machine = class
  		constructor Create;
      destructor Destroy;override;
  protected
      fsocket: boolean;
  		fNET_ID: integer;
      fType : TNet_Type;

      ping_time: Cardinal;
      timer: cardinal;
      btimer: byte;

      procedure Check_Socket;

      procedure rinfo_recv(IP: string; Port:word; reason: byte = 0);
      procedure msg_recv(IP: string; Port:word; len: integer);

      procedure players_recv;  //�������� ������ �� �������
      function players_write(ex_client: TClient): boolean; //����� ������ �� ������� � ����� ������
      procedure players_sending_end;

      procedure say_Recv;
      procedure changename_Recv;

      function Getspects(ind: integer): TSpectator;virtual;
  public
 		procedure Message_(id: Byte);
 		function Read(p: pointer; Length: integer): integer;
      procedure ReadString(var s: string);
      procedure WriteString(s: string);

      procedure Disconnect;virtual;

  		procedure Update_Prev;virtual;
      procedure Update_Next;virtual;

      procedure game_Prepare;virtual;//prepare to send game messages
      procedure game_Send;	 virtual;//send game messages!!!

    	procedure msg_Send(IP: string; Port: word; msg: string);
      procedure pong_Send(IP: string; Port: word);
      procedure sinfo_Send(IP: string; Port: word);

      function Gen_ID: integer;
      property NET_ID: integer read fNET_ID;
		property Type_: TNet_Type read fType;

      procedure say_Send(uid: byte; msg: string);virtual;
      procedure changename_Send(uid: byte; name, model: string);virtual;
      procedure shot_send(uid: byte); virtual;

      function spects_Count: integer;virtual;
      property spects[ind: integer]: TSpectator read Getspects;
  end;

//***

const

 NET_BufLen = 4096;

var
 NET	: 	TNet_Machine;

var
 NET_Buf        : PByteArray;
 NET_Buf_Seek   : integer;
 NET_Buf_Len : integer;

 NET_servermap: string;

// ������� //

 function NET_Cmd(Cmd: ShortString): boolean;
 procedure NET_Init;
 procedure NET_Free;

 procedure NET_Create(multi: boolean);
 procedure NET_Update;
 procedure NET_Log(msg: string);
 function NET_MapDownload(const FileName: string): boolean;

 function NET_game: boolean;

implementation

uses
 Constants_Lib, Game_Lib, Map_Lib, Player_Lib, weapon_lib, Stat_Lib,
 Menu_Lib,
 NET_Local_Lib, NET_Client_Lib, NET_Server_Lib;

procedure NET_log(msg: string);
begin
   if d_net_log then
      Log(msg);
end;

function NET_MapDownload(const FileName: string): boolean;
(***************************************
 ������� �������� ����� ����� ����������:
 ������� ����� 4 ������� ���������
  NM_MAP_GET, NM_MAP_SIZE, NM_MAP_BUF � NM_MAP_END

 NM_MAP_GET:
  -������: NM_MAP_GET <NameLen (1)> <Name>
   ������� ������� ������ � ���������� ������� ����� <Name>
 NM_MAP_SIZE:
  -������: NM_MAP_SIZE <Size (4)>
   ����� �� ������� �� NM_MAP_GET � ������� <Size> ��������� �� ����� ����� ������������ ������
 NM_MAP_BUF:
  -������: NM_MAP_BUF <ID (4)> <Data>
   �����  �������� ID ���������� � ���� ������ <Data>
   ������ ������� = BUF_SIZE, �� ��� ���������� ������ ����� ���� ������
  -������: NM_MAP_BUF <ID (4)>
   ���� ������ �� ������� �����-���� ����� ��� ������� <ID>,
   �� �������� �� ���� �������, ������� � ���� ������� ������ �����������
   ����� ����� ��� ��� �� �������
 NM_MAP_END:
  -������: ����� �������� ������� ������ �����,
   ��� ������, ��� ������ �� ����� ������ (���������) ��������� �����
  -������: �������� ������� �� �������� ��������� ��������� ������ �����.

  ������� ������ � �������� ���������� TIME_OUT.
  ������� �� �������� ���������� ������ �� ������� ����� Time_Buf

  �� ��������� ��������, ����� ���������� � "<TFK/TA>/maps/download/"
  �� ����� ���������� ���� ������ � ����, � ����� � ��� ��������������� ���������
 ��������� Windows � ���������� "���������". � ����� � ������������ ������ - ��
 ��������� �������� ����� ���������� ���������� ������� ������.
  ��� ������ ����� ������������ ��� ���������� ��� APL (�� ������ ������ ;)

 ������������� �������:
  ��� ����� = 100 ��, ��� ������ �������
  ����� �������� � 256 �� ����� ������� ���������������� �� 7 ������ :)
  ��� ������� ������ �� ������ ����� BUF_SIZE = 4096 ���� (������������ ��������)

 � �������������� ������ ������ ������� ������ XProger'� :)
***************************************)
const
 TIME_OUT : cardinal = 5000;
 TIME_BUF = 2000;
 BUF_IDLE = 3000; // ����� ��������� �� ��������� ������������ ������
 BUF_MAX  = 5;    // ������������ ���-�� ���������� ��������
var
 timeout   : DWORD;
 buf_map   : PByteArray;
 buf_count : integer;
 buf_out   : integer;        // ���-�� ������� ��������
 buf_stat  : array of DWORD; // ����� � ������� �������� ������� ������
 map_size  : integer;        // ���-�� ���� ��������� �� ����� �����
 msg        : byte;
// ����� �������
 IP        : string;
 Port      : integer;
// ����� ��������� ���������
 incIP     : PChar;
 incPort   : integer;
// ��������� ���������� :)
 i, j      : integer;
 F         : File;
 progress  : integer;

 procedure DrawProgress;
 var
  pos : single;
 begin
 inc(progress);
 pos := progress * 500 / buf_count;
 glClear(GL_COLOR_BUFFER_BIT);
 xglTex_Disable;
 glBegin(GL_QUADS);
  glColor3f(1, 1, 0);
  glVertex2f(70, 260);
  glVertex2f(70, 220);
  glColor3f(1, 0, 0);
  glVertex2f(70 + pos, 220);
  glVertex2f(70 + pos, 260);
 glEnd;
 glColor3f(1, 1, 1);
 glBegin(GL_LINE_STRIP);
  glVertex2f(70, 260);
  glVertex2f(70, 220);
  glVertex2f(570, 220);
  glVertex2f(570, 260);
  glVertex2f(70, 260);
 glEnd;
 xglSwap;
 end;

begin
Result  := false;
if FileName = '' then Exit; // ��� ��� ��� �����... ;)

// ��� ��������� ������������
glViewport(0, 0, xglWidth, xglHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
gluOrtho2D(0, 640, 480, 0);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity;
xglAlphaBlend(0);

Log('^3Try to download map');

buf_count := 0;
buf_stat  := nil; // ���������� ���������� ������� (������ ��� ���)
buf_map   := nil;
map_size  := 0;

try // ���� try - ���� debug :)
// XProger: ����, ��� 2 ������ �������� � �������!
// ��� ������ IP Port ������� ��������???

//IP        := NET_Server.client[0].IP;
//Port      := NET_Server.client[0].Port;

//Neoff: �� - ������! net_server ��� ������ �� ��� ���!
IP        := NET_Client.serv.IP;
Port      := NET_Client.serv.Port;

progress  := 0;
// �������� ������ �� ������ �����

NET.Message_(NM_Map_Get);
NET.WriteString(FileName);
NET_Client.Serv.Send(true);

TimeOut   := GetTickCount; // �������� �����
// ���� �� �������� ����������� ����� ������� �������� ������
while GetTickCount - TimeOut < Time_Out do
 begin
 if GetAsyncKeyState(VK_ESCAPE) <> 0 then break;
 Engine_Reg.NET_Update;
 NET_Buf_seek:=0;
 NET_Buf_len := NET_Recv(net_buf, NET_BUFLEN, incIP, incPort);
 i:=NET_Buf_len;
 NET.Read(@msg, 1);
 // ��������� ������ ����� ������ � �������, ��������� ���������� �� ������ (�� �� ��� ������)
 if (i > 0) and (Port = incPort) and (IP = StrPas(incIP)) then
  begin
  if map_size = 0 then // �������� ������ �� ������� �� ���������
   case msg of
    // ���! ������ ����� �������� �����, � ����� ���������� � ����...
    NM_MAP_SIZE : begin
                  NET.Read(@map_size, 4); // Size �����
                  GetMem(buf_map, map_size); // �������� ������ ��� ����� �����
                  // ��������� ���-�� �������
                  buf_count := (map_size - 1) div NET_MAPBUFSIZE + 1;
                  // ������ ����� ����������
                  SetLength(buf_stat, buf_count);
                  FillChar(buf_stat[0], buf_count * 4, 1);
    ////////////// debug
                  Log('Map size: ' + IntToStr(map_size));
                  end;
    NM_MAP_END  : break; // ���-�� �� �������� :(
   end
  else
   case msg of
    // � i � ��� �������� ���-�� ���������� ����
    NM_MAP_BUF : begin  // ��, ��� ����!
                 NET.Read(@j, 4); // ������ ID ������
                 if (buf_stat[j] > 0) and (j >= 0) and (j < buf_count) then
                  begin
                  buf_stat[j] := 0; // ��� ������ ��� ������ �� �����
                  NET.Read(pointer(integer(buf_map)+j * NET_MAPBUFSIZE) , i - 5);
                  DrawProgress;
                  end;
                 end;
    NM_MAP_END : break; // ���� ����... :(
   end;
  TimeOut := GetTickCount; // �.�. ������� ��������� �� �������
  end;

 // ������� ���-�� ����������� ��������
 buf_out := 0;
 for j := 0 to buf_count - 1 do
  if buf_stat[j] > 1 then // �������������
   if GetTickCount - buf_stat[j] > BUF_IDLE then // �������� �������� ������� (APL ������!!!)
    buf_stat[j] := 1 // ����� ����� ��������� ��� net_apl_trys ������� ������, ��� ������������ ;)
   else
    inc(buf_out);

 // �������� ��������
 if buf_out < BUF_MAX then // ���� ����� ��� ���������� �������
  for j := 0 to buf_count - 1 do
   if buf_stat[j] = 1 then // ������� �������
    begin
    buf_stat[j] := GetTickCount;
    // ��������� ����� �������
    NET.Message_(NM_MAP_BUF);
    NET_Write(@j, 4);
    NET_Client.Serv.Send(true);
    inc(buf_out);
    if buf_out = BUF_MAX then // ���� ���! :)
     break;
    end;

 // ���� ��� �������� - ������ �� ��� ��������
 if (buf_out = 0) and (map_size>0) then
  begin
  // ������� ������� ������� ;)
  NET.Message_(NM_MAP_END);
  NET_Client.Serv.Send(true);
  Result := true;
  break;
  end;
 end;

if Result then
 begin
 Log('^3Saving downloaded map to ^7"' + ExtractFileName(FileName) + '^7"');
 CreateDir(Engine_ModDir + 'maps\download');
  try
   AssignFile(F, Engine_ModDir + 'maps\download\' + ExtractFileName(FileName)+'.tm');
   Rewrite(F, 1);
   BlockWrite(F, buf_map^, map_size);
   CloseFile(F);
  except
   Log('^1Can''t save map ^7"maps\download\' + ExtractFileName(FileName) + '^7"')
  end;
 end
else
 Log('^1Can''t download map ^7"' + ExtractFileName(FileName) + '^7"');

except
 Log('aaaa');
end;


// ��������
buf_stat := nil;
if buf_map <> nil then
 FreeMem(buf_map);

// ��������� ������� Update � ������
Engine_FlushTimer;
end;

function NET_game: boolean;
begin
   Result:=NET.Type_<>NT_NONE;
end;

procedure NET_Init;
begin
	GetMem(NET_Buf, NET_BufLen);
   net_Local:=TLocal_Machine.Create;
   NET:=net_Local;

   Console_CmdReg('net_search', @NET_Cmd);
   Console_CmdReg('net_send', @NET_Cmd);
   Console_CmdReg('net_info', @NET_Cmd);
   Console_CmdReg('net_invite', @NET_Cmd);
   Console_CmdReg('net_connect', @NET_Cmd);
   Console_CmdReg('net_disconnect', @NET_Cmd); //��������� ping timeout :)
   Console_CmdReg('net_reconnect', @NET_Cmd);
   Console_CmdReg('net_join', @NET_Cmd);
   Console_CmdReg('net_p2join', @NET_Cmd);
   Console_CmdReg('net_disjoin', @NET_Cmd);
   Console_CmdReg('net_showclients', @NET_Cmd);
   Console_CmdReg('net_kick', @NET_Cmd);

   Console_CmdReg('arena_address', @NET_Cmd);
end;

procedure NET_Free;
begin
	FreeMem(NET_Buf);
   NET.Free;
end;

procedure NET_Create(multi: boolean);
begin
   if multi then
      NET_Log('^3NET_Create Multiplayer')
   else NET_Log('^3NET_Create Hotseat');
   
   if multi then
   begin
      if (NET.Type_<>NT_Server) then
      begin
         NET_ClearAPL;
         NET_Server:=TServer_Machine.Create;
         Map.session_number:=0;
         Arena_Ping;
	   end
   end
 else
   if (NET.Type_<>NT_NONE) then
      NET_Local:=TLocal_Machine.Create;
end;

procedure NET_Update;
begin
   NET.Update_Prev;
end;

function NET_Cmd(Cmd: ShortString): boolean;
var
 par : array [1..3] of string;
 i   : integer;
 str, str_ : string;
 b: boolean;
begin
Result := true;
str    := Func_Lib.LowerCase(trim(cmd));
str_   := str;
for i := 1 to 2 do
 par[i] := StrSpace(str);
par[3]:=str;

if par[1] = 'net_search' then
 begin
 	i := StrToInt(par[2]);
 	if i = 0 then
  		i := 25666;
 	NET.Message_(NM_SINFO);
 	NET_Send(nil, i, false);
   NET.Ping_Time := GetTickCount;
 	Exit;
 end;

if par[1] = 'net_info' then
 begin
     if par[2]<>'' then
     begin
			if pos(':', par[2]) <> 0 then
         begin
   			str  := Copy(par[2], 1, pos(':', par[2]) - 1);
   			str_ := Copy(par[2], pos(':', par[2]) + 1, Length(par[2]));
   		end
  		else
   		begin
   			str  := par[2];
   			str_ := '25666';
  	 		end;
      	i := StrToInt(str_);
  			NET.sinfo_Send(str, i);
      end;
 	 	Exit;
 end;

if par[1] = 'net_invite' then
begin
   if (par[2]<>'') and (NET.Type_=NT_SERVER) then
   begin
			if pos(':', par[2]) <> 0 then
         begin
   			str  := Copy(par[2], 1, pos(':', par[2]) - 1);
   			str_ := Copy(par[2], pos(':', par[2]) + 1, Length(par[2]));
   		end
  		else
   		begin
   			str  := par[2];
   			str_ := '25666';
  	 		end;
      	i := StrToInt(str_);
  			NET_Server.Invite_Send(str, i);
      	Log('^1Invite send to '+str+':'+inttostr(i));
   end else if (NET.Type_<>NT_SERVER) then
   begin
      Log('^1Only server can send Invite!');
   end;
	Exit;
end;

if par[1] = 'net_send' then
 begin
 if par[3] <> '' then
  begin
  if pos(':', par[2]) <> 0 then
   begin
   str  := Copy(par[2], 1, pos(':', par[2]) - 1);
   str_ := Copy(par[2], pos(':', par[2]) + 1, Length(par[2]));
   end
  else
   begin
   str  := par[2];
   str_ := '25666';
   end;
  	i := StrToInt(str_);
  	NET.msg_Send(str, i, par[3]);
  end;
 Exit;
 end;

if par[1] = 'net_connect' then
 begin
 if par[2] <> '' then
  begin
  if pos(':', par[2]) <> 0 then
   begin
   str  := Copy(par[2], 1, pos(':', par[2]) - 1);
   str_ := Copy(par[2], pos(':', par[2]) + 1, Length(par[2]));
   end
  else
   begin
   str  := par[2];
   str_ := '25666';
   end;
  	i := StrToInt(str_);
   if NET.Type_=NT_NONE then
   begin
      net_Local.Connect(str, i);
   end
   else
   begin
   //log
   end;
  end;
 Exit;
 end;

if par[1] = 'net_disconnect' then
begin
   if NET.Type_=NT_CLIENT then
   begin
      NET_Local:=TLocal_Machine.Create;
      Map.ClearAll;
      Log('^2Disconnected');
   end;
   Result:=true;
   Exit;
end;

if par[1] = 'net_reconnect' then
begin
   if NET.Type_=NT_CLIENT then
   begin
      b:=net_debug_disconnect;
      net_debug_disconnect:=true;

      str:=NET_Client.Serv.IP;
      i:=NET_Client.Serv.Port;
      NET_Local:=TLocal_Machine.Create;
      Map.ClearAll;
      net_Local.Connect(str, i);

      net_debug_disconnect:=b;
   end;
   Result:=true;
   Exit;
end;

if par[1] = 'net_join' then
begin
   if NET.Type_=NT_CLIENT then
   begin
      if Map.pl_find(-1, C_PLAYER_P1) then
         Log('^2You are already in game')
      else NET_Client.join_send(C_PLAYER_p1, p1name, p1model);
   end else Log('^2This command only for Client machine');
   Exit;
end;

if par[1] = 'net_p2join' then
begin
   if NET.Type_=NT_CLIENT then
   begin
      if Map.pl_find(-1, C_PLAYER_P2) then
         Log('^2You are already in game')
      else NET_Client.join_send(C_PLAYER_p2, p2name, p2model);
   end else Log('^2This command only for Client machine');
   Exit;
end;

if par[1] = 'net_disjoin' then
begin
   if NET.Type_=NT_CLIENT then
   begin
      NET_Client.disjoin_send(C_PLAYER_ALL);
   end else Log('^2This command only for Client machine');
   Exit;
end;

if par[1] = 'arena_address' then
 begin
 if trim(par[2]) = '' then
  Log('^3arena_address is ^7"^b' + arena_address + '^n^7"')
 else
  begin
  arena_address := trim(Copy(cmd, Length(par[1]) + 1, Length(cmd)));
  cfgProc('arena_address ' + arena_address);
  Log('^2arena_address changed to ^7"^b' + arena_address + '^n^7"');
  end;
 Exit;
 end;

if par[1] = 'net_showclients' then
begin
   Result:=true;
   if NET.Type_=NT_SERVER then
      with NET_Server do
   begin
      Log(' ^3 server has ^7'+IntToStr(client_count)+' ^3clients');
      for i:=0 to client_Count-1 do
      begin
         Log('^3 '+inttostr(i+1)+': '+client[i].Name+' has ^1'+inttostr(client[i].players_count)+'^3 players');
         if Map.pl_find_NET(-1, client[i]) then
         repeat
            Log('^3   player - ^7'+Map.pl_current.Name);
         until not Map.pl_find_NETnext(-1, client[i]);
      end;
   end else Log('^2Server-side command');
   Exit;
end;

if par[1] = 'net_kick' then
begin
   Result:=true;
   if NET.Type_=NT_SERVER then
      with NET_Server do
   begin
      if (par[2]='') then
         Log('^3 net_kick CLIENT_ID (client_id see in net_showclients command')
      else
      begin
         i:=StrToInt(par[2]);
         if (i>0) and (i<=client_count) then
         begin
            NET_Server.client_Delete(i-1, NM_KICK);
            Log(' ^2Client kicked');
         end else Log('^2 Wrong parameter');
      end;
   end else Log('^2Server-side command');
   Exit;
end;

Result := false;
end;

{ TClient }

procedure TClient.ClearPing;
begin
   FillChar(pings, sizeof(pings), 0);
   fStatPing:=0;
   fTime:=GetTickCount;
   fLastPing:=GetTickCount;
end;

constructor TClient.Create(IP: string; Port: word; Name_: string);
begin
   FIP   := IP;
	FPort := Port;
   fName := Name_;
   ClearPing;
map_buf  := nil;
map_size := 0;
end;

destructor TClient.Destroy;
begin
if map_buf <> nil then
 FreeMem(map_buf);
end;

function TClient.GetIP: PChar;
begin
   Result:=PChar(FIP);
end;

function TClient.map_download: boolean;
begin
   Result:=map_buf<>nil;
end;

procedure TClient.RecvPing;
var
   i: integer;
begin
	Ping  := GetTickCount - FTime;
	FTime := GetTickCount;
   FLastPing:=GetTickCount;

   Move(pings[1], pings[0], sizeof(pings)-sizeof(word));
   pings[high(pings)]:=Ping;
   fStatPing:=0;
   for i:=low(pings) to high(pings) do
   	fStatPing:=fStatPing+round( (i / (high(pings)+1) + 1/2 )* Pings[i]);
   if pings[0]>0 then
   	fStatPing:=fStatPing div (high(pings)+1);
end;

procedure TClient.Send(APL: boolean);
begin
   NET_Send(PChar(fIP), fPort, APL);
end;

procedure TClient.SendDisconnect(reason: byte);
begin
   if reason<200 then reason:=NM_CLIENTLEAVE;
   NET.Message_(NM_Disconnect);
   NET_Write(@reason, 1);
   NET_Send(PChar(IP), Port, true);
end;

procedure TClient.SendPing;
begin
   FTime:=GetTickCount;
   NET.Message_(NM_PING);
   Send(false);
end;

procedure TClient.SendPong;
begin
  	NET.Message_(NM_PONG);
 	Send(false);
end;

function TClient.Valid(t: byte): boolean;
var
   t1, t2: smallint;
begin
   Result:=false;
   t1:=pTimer;t2:=t;
   t1:=t2-t1;
   while t1>128 do t1:=t1-256;
   if (t1>0) or (t1<-32) then
   begin
      pTimer:=t;
      Result:=true;
   end;
end;

{ TNET_Machine }

constructor TNET_Machine.Create;
begin
   Gen_ID;
   timer:=0;
   if NET<>nil then
      NET.Free;
   NET:=Self;
end;

destructor TNET_Machine.Destroy;
begin
	NET_ClearAPL;
   //abstract
end;

function TNET_Machine.Gen_ID: integer;
begin
   fNET_ID:=random(maxint);
   Result:=fNET_ID;
end;

procedure TNET_Machine.msg_Send(IP: string; Port: word; msg: string);
begin
	Check_Socket;
   Message_(NM_MSG);
   if length(msg)<255 then
   begin
   	NET_Write(@msg[1], length(msg));
      NET_Send(PChar(IP), Port, true);
   end;
end;

procedure TNET_Machine.game_Prepare;
begin
   //abstract
end;

procedure TNET_Machine.game_Send;
begin
   //abstract
end;

procedure TNET_Machine.Update_Next;
begin
   //abstract
end;

procedure TNET_Machine.Update_Prev;
begin
   Inc(Timer);
   bTimer:=Timer mod 256;
end;

procedure TNET_Machine.Disconnect;
begin
	// abstract;
end;

procedure TNET_Machine.Message_(id: Byte);
begin
	NET_Clear;
	NET_Write(@id, 1);
end;

function TNET_Machine.Read(p: pointer; Length: integer): integer;
begin
//�� ���� ��� ������ ������� ���������� ����������� ����

   if NET_Buf_seek+Length>NET_buf_len then
      length:=0
   else
   begin
		Move(NET_Buf[NET_Buf_Seek], p^, Length);
		inc(NET_Buf_Seek, Length);
   end;
   Result:=Length;
end;

procedure TNET_Machine.pong_Send(IP: string; Port: word);
begin
   Message_(NM_PONG);
   NET_Send(PChar(IP), Port, false);
end;

procedure TNET_Machine.Check_Socket;
begin
   if not fsocket then
   begin
      fsocket:=true;
      if net_randomsocket then
	      Net_InitSocket(0)
      else
      	Net_InitSocket(sv_port);
   end;
end;

procedure TNET_Machine.ReadString(var s: string);
var
   b: byte;
begin
   Read(@b, 1);
   SetLength(s, b);
   Read(@s[1], b);
end;

procedure TNET_Machine.WriteString(s: string);
var
   b: byte;
begin
   b:=length(s);
   NET_Write(@b, 1);
   NET_Write(@s[1], b);
end;

procedure TNET_Machine.sinfo_Send(IP: string; Port: word);
begin
   Check_Socket;
   Message_(NM_SINFO);
   NET_Send(PChar(IP), Port, true);
   ping_time:=GetTickCount;
end;

procedure TNET_Machine.rinfo_recv(IP: string; Port: word; reason: byte);
var
   serv_info: TNP_ServerInfo;
   s1, s2, r: string;
   ping: integer;
begin
   Read(@serv_info, sizeof(serv_info));
   ReadString(s1);
   ReadString(s2);
   ping:=GetTickCount - Ping_Time;
   if not Menu_MP then
   begin
		Log('NET_Pong from ^3' + IP + '^7:^3' + IntToStr(port));

		Log('^2Server    : ^7' + s1);
		Log(' ^3Map      : ^7' + s2);
		Log(' ^3Players  : ^7' + IntToStr(serv_info.Players) + '/' +
                         IntToStr(serv_info.MaxPlayers));
		Log(' ^3Password : ^7' + IntToStr(Byte(serv_info.Password)));
		Log(' ^3Ping     : ^7' + IntToStr(ping));
   end;
   case reason of
      1: r:='Invite';
      2: r:='Planet';
   	else r:='';
   end;
   Menu_AddServer(IP, Port, s1, s2, GetTickCount - Ping_Time,
   	serv_info.Players, serv_info.MaxPlayers, r);
end;

procedure TNET_Machine.msg_recv(IP: string; Port: word; len: integer);
var
   s: string;
begin
   if len>255 then len:=255;
   SetLength(s, len);
   Move(NET_Buf[NET_Buf_Seek], s[1], len);
	Log('^5' + IP + ':' + IntToStr(Port) + '^2> ^7' + s);
end;

//��� ��������� ��������� : ������ ������ �������!!!

procedure TNET_Machine.players_recv;
var
 uid, tb: byte;
 rec: TPlayerPhys;
 b: TBits;

	procedure byte_keysomega(b: byte; var keys: TKeySet; var omega: byte);
   begin
      keys:=TKeySet(b and 127);
      omega:=0;
   end;

begin
	Read(@uid, 1);

   fillchar(rec, sizeof(rec), 0);
   //b0 = angle and 256;
   //b1 = NET_MOVED
   //b2 = MOVED
   //b3 = crouch
   //b4 = ..
   //b5 = SQUISH

   Read(@tb, 1);
   ByteToBits(tb, b);
   if b[0] then
   	rec.angle:=rec.angle+256;
   if b[1] then
   begin
   	//������ �������
   	READ(@rec.pos_x, 2);
   	READ(@rec.pos_y, 2);
   	READ(@rec.dpos_x, 1);
  	 	READ(@rec.dpos_y, 1);
   end;
  	READ(@tb, 1);
   rec.angle:=rec.angle+tb;
   rec.crouch:=b[3];
   READ(@tb, 1);
   byte_keysomega(tb, rec.keys, rec.omega);
 	READ(@tb, 1);
   rec.weapon:=tb and 15;
   rec.jump_stage:=tb shr 4;
	if Map.pl_find(uid, C_PLAYER_NET) then
      with Map.pl_current do
      begin
         if b[5] then
         begin
            if not dead then
               SquishKill;
         end;
     		SetPos(rec);
         if b[1] then
            net_recv:=true;
      end;
end;

function TNET_Machine.players_write(ex_client: TClient): boolean;

   function byte_keysomega(keys: TKeySet; omega: byte): byte;
   begin
      Result:=byte(keys) and 127;
   end;

var
 	tb: byte;
 	i: integer;
 	rec: TPlayerPhys;
 	b: TBits;

begin
   Result:=false;
   NET_Write(@btimer, 1);
   with Map do
   	for i:=0 to pl_count-1 do
      	with Player[i] do
         	if (not dead or (deadticker<20)) and ((client<>ex_client) or not IsNet) then
      begin
         Result:=true;
        	GetPos(rec);
         b[0]:=rec.angle and 256>1;
         b[2]:=fMoved;
         b[1]:=(net_moved=0) or b[2];
         b[3]:=rec.crouch;
         case net_sync of
         	1: tb:=0;
            2: tb:=1;
            3: tb:=2;
            else tb:=3;
         end;
         b[5]:=Squished;
         b[6]:=tb and 1>0;
         b[7]:=tb and 2>0;
         tb:=uid;
         NET_Write(@tb, 1);
         tb:=BitsToByte(b);
         NET_Write(@tb, 1);
         if b[1] then
   		begin
   	//����� �������
      		NET_Write(@rec.pos_x, 2);
   			NET_Write(@rec.pos_y, 2);
   			NET_Write(@rec.dpos_x, 1);
  	 			NET_Write(@rec.dpos_y, 1);
   		end;
         if not (cur_weapon in [WPN_GAUNTLET, WPN_MACHINEGUN, WPN_SHAFT]) and
         	(fireticker<3) then rec.keys:=rec.Keys+[KEY_FIRE];

         tb:=rec.angle and 255;
  			NET_Write(@tb, 1);
   		tb:=byte_keysomega(rec.keys, rec.omega);
 			NET_Write(@tb, 1);
         tb:=rec.weapon+rec.jump_stage shl 4;
         NET_Write(@tb, 1);
      end;
end;

procedure TNET_Machine.say_Recv;
var
   uid: byte;
   msg: string;
begin
   Read(@uid, 1);
   ReadString(msg);
   Map.Say(uid, msg, false);
end;

procedure TNET_Machine.say_Send(uid: byte; msg: string);
begin
   //abstract
end;

procedure TNET_Machine.players_sending_end;
var
   i: integer;
begin
   for i:=0 to Map.pl_count-1 do
      with map.player[i] do
      begin
         Moved;
    	 	if net_moved=0 then
     			net_moved:=net_delta;
      end;
end;

procedure TNET_Machine.changename_Send(uid: byte; name, model: string);
begin
   //abstract
end;

procedure TNET_Machine.changename_Recv;
var
   uid: byte;
   name, model: string;
   c: TRGB; b: byte;
begin
   Read(@uid, 1);
   ReadString(name);
   ReadString(model);
   Read(@c, 3);
   Read(@b, 1);
   Map.SetPlayerName(uid, name, false);
   Map.SetPlayerModel(uid, model, false);
   if Map.pl_find(uid, C_PLAYER_NET) then
      with Map.pl_current do
   begin
      railcolor:=c;
      railtype:=b;
   end;
end;

function TNET_Machine.Getspects(ind: integer): TSpectator;
begin
   //abstract
end;

function TNET_Machine.spects_Count: integer;
begin
   Result:=0;
end;

procedure TNET_Machine.shot_send(uid: byte);
begin
   //abstract
end;

end.
