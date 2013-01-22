unit NET_Local_Lib;

interface

uses
 Windows, SysUtils,
 Engine_Reg,
 Func_lib,
 Type_Lib,
 NET_LIB;

// локальная сетевая машина - это сервер, который работает до начала игры.
// используется при обозревании интернет-игр,
// отсылки сообщений, отсылки запросов на коннект,
// и приёма приглашений.

type

	TLocal_Machine =
   	class(TNET_Machine)
         constructor Create;
      private
      //who is the sender :)
         IP: string;
         Port: word;
      public
         procedure Connect(IP: string; Port: word);
         procedure Update_Prev; override;
   	end;

var
   net_Local: TLocal_Machine;

implementation

uses
 Constants_Lib, NET_Client_Lib, Game_Lib;

{ TNET_Local_Machine }

procedure TLocal_Machine.Connect(IP: string; Port: word);
var
	params: TNP_ConnectParams;
begin
   Check_Socket;

   Message_(NM_CONNECT);
   params.NET_ID:=NET_ID;
   params.Version:=1;
   NET_Write(@params, sizeof(params));
   WriteString(p1name);
   NET_Write(@params, sizeof(params));
   NET_Send(PChar(IP), Port, true);
end;

constructor TLocal_Machine.Create;
begin
   inherited;
   fSocket:=false;
   fType:=NT_NONE;
end;

procedure TLocal_Machine.Update_Prev;
var
 	IP_  : PChar;
 	i    : integer;
 	Msg  : Byte;
begin
   inherited;
   if not fsocket then Exit;

	IP_ := nil;
   NET_Buf_seek:=0;
	NET_Buf_len := NET_Recv(NET_Buf, NET_BufLen, IP_, i);
   IP:= StrPas(IP_);
   port:=i;

   while (NET_Buf_len>0) do
   begin

      i := NET_Buf_len;

         Read(@Msg, 1);
         case Msg of
            NM_Msg: msg_Recv(IP, Port, i-1);
//            NM_Ping: pong_Send(IP, Port);
            NM_RInfo:
               rinfo_recv(IP, Port);
            NM_Invite: rinfo_recv(IP, Port, 1);
            NM_Accept:
            begin
               NET_Client:=TClient_Machine.Create(IP, port);
               Exit;
            end;
         end;

	IP_ := nil;
   NET_Buf_seek:=0;
	NET_Buf_len := NET_Recv(NET_Buf, NET_BufLen, IP_, i);
   IP:= StrPas(IP_);
   port:=i;

   end;
end;

end.
