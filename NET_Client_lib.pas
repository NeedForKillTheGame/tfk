unit NET_Client_lib;

interface

uses
 Windows, SysUtils,
 Engine_Reg,
 Func_lib,
 Type_Lib,
 Graph_Lib,
 Math_Lib,
 Net_Lib;

type TClient_Machine =
	class(TNet_Machine)
      constructor Create(servip : string; servport: word);
      destructor Destroy;override;
   protected
      serv_btimer: byte;

      sp_count: integer;
      sp: array [1..100] of TSpectator;

      Server: TClient;
      procedure ReadInfo(flags: byte);
      procedure getinfo_Send(flags: byte);

      procedure addplayer_recv;
      procedure removeplayer_recv;

      procedure gamemsg_recv;
      procedure shotobj_recv;
      procedure shotobjkill_recv;
      procedure pings_recv;
      procedure teamjoin_recv;
      procedure shot_recv;

      function Getspects(ind: integer): TSpectator;override;
   public
      serv_info: TNP_ServerInfo;
   	property Serv: TClient read Server;
      procedure Update_Prev; override;
      procedure Update_Next; override;

      procedure say_Send(uid: byte; msg: string);override;
      procedure join_send(ptype: byte; name, model: string);
      procedure disjoin_send(ptype: byte);
      procedure changename_Send(uid: byte; name, model: string); override;
      procedure shot_send(uid: byte);override;
      procedure resp_Send(uid: byte);
      procedure TeamJoin(uid, team: byte);

      function spects_Count: integer;override;
	end;

var
   net_client: TClient_Machine;

implementation

uses Constants_Lib, Map_Lib, Stat_Lib, Player_Lib, weapon_lib, real_lib, game_lib, phys_lib, HUD_Lib;

{ TClient_Machine }

procedure TClient_Machine.addplayer_recv;
var
   pl_type, uid: byte;
   s1, s2: string;
   c: TRGB; b: byte;
   pl: TPlayer;
begin
   Read(@uid, 1);
   Read(@pl_type, 1);
   ReadString(s1);
   ReadString(s2);
   Read(@c, 3);
   Read(@b, 1);
   if pl_type<>C_PLAYER_NET then
   begin
   	Map.pl_add(pl_type, s1, s2, false, uid);
      CMDCheck;
   end
      else
      begin
         pl:=Map.pl_addNET(pl_type, server, s1, s2, false, true, uid);
         pl.railcolor:=c;
         pl.railtype:=b;
      end;
end;

procedure TClient_Machine.changename_Send(uid: byte; name, model: string);
var
   c: TRGB;
   b: byte;
begin
   Message_(NM_CHANGENAME);
   NET_Write(@uid, 1);
   WriteString(name);
   WriteString(model);

   if Map.pl_find(uid, C_PLAYER_ALL) then
   begin
      c:=Map.pl_current.railcolor;
      b:=Map.pl_current.railtype;
   end else
   begin
      c:=r_rail_color;
      b:=r_rail_type;
   end;
   NET_Write(@c, 3);
   NET_Write(@b, 1);

   server.Send(false);
end;

constructor TClient_Machine.Create(servip: string; servport: word);
var
	params: TNP_ConnectParams;
begin
   inherited Create;
   NET_Client:=Self;
   fSocket:=true;
   fType:=NT_CLIENT;
   Server:=TClient.Create(servip, servport, '');
   Server.SendPing;
   Read(@Params, sizeof(Params));
   fNet_id:=Params.NET_ID;
   ReadInfo(INFO_SERVER);
   if NET.Type_<>NT_CLIENT then Exit;
   Server.SendPing;
   Server.RecvPing;

   sp_count:=0;
end;

destructor TClient_Machine.Destroy;
begin
   if not net_debug_disconnect then
      Server.SendDisconnect(NM_CLIENTLEAVE);
   Server.Free;
  	inherited;
end;

procedure TClient_Machine.disjoin_send(ptype: byte);
begin
   Message_(NM_DISJOIN);
   NET_Write(@ptype, 1);
   Server.Send(true);
end;

procedure TClient_Machine.gamemsg_recv;
var
   msg: byte;
   h: THit;
   uid, num: byte;
   numw: word;
   ww: array [0..7] of word;
   pl: TPlayer;

begin
   Read(@msg, 1);
   case msg of
      NM_RESPAWN:
      begin
         Read(@uid, 1);
         Read(@num, 1);
         Read(@numw, 2);
         pl:=Map.PlayerByUID(uid);
         if (pl<>nil) then
         begin
            pl.resp:=true;
            pl.respindex:=num;
            pl.lasthitid:=numw;
         end;
         server.pTimer:=serv_btimer;
   	end;
      NM_OBJECTS:
         with Map do
      begin
         if (Read(@numw, 2)=0) or
         	(Read(@uid, 1)=0) then Exit;
         if numw<Obj.Count then
         begin
            Demo.RecActivate(numw, uid);
         	Obj[numw].Activate(Map.PlayerByUID(uid));
            if Read(@ww, Obj[numw].fNetSize*2)=0 then Exit;
            Obj[numw].LoadNet(ww);
         end else
         	if numw>=20000 then Map.ActivateTarget(numw-20000, true);
      end;
      NM_HITS:
      begin
         if Read(@h, sizeof(h))>0 then
         	HitApply(h);
      end;
      NM_SHOTOBJ:
         shotobj_recv;
      NM_SHOTOBJ_KILL:
         shotobjkill_recv;
      NM_SHOT:
         shot_recv;
   end;
end;

procedure TClient_Machine.getinfo_Send(flags: byte);
begin
   Message_(NM_GameInfo);
   NET_Write(@flags, 1);
   Server.Send(true);
end;

function TClient_Machine.Getspects(ind: integer): TSpectator;
begin
   if (ind>=1) and (ind<=sp_count) then
      Result:=sp[ind];
end;

procedure TClient_Machine.join_send(ptype: byte; name, model: string);
var
   c: TRGB;
   b: byte;
begin
   if ptype = C_PLAYER_P1 then
   begin
      c:=r_rail_color;
      b:=r_rail_type;
   end
   else if ptype = C_PLAYER_P1 then
   begin
      c:=r_p2_rail_color;
      b:=r_p2_rail_type;
   end
   else
   begin
      c:=r_enemy_rail_color;
      b:=r_enemy_rail_type;
   end;
   Message_(NM_JOIN);
   NET_Write(@ptype, 1);
   WriteString(name);
   WriteString(model);
   NET_Write(@c, 3);
   NET_Write(@b, 1);
   Server.Send(true);
end;

procedure TClient_Machine.pings_recv;
var
   tb, uid: byte;
   w: word;

   i: integer;

begin
   read(@tb, 1);
   for i:=0 to tb-1 do
   begin
      read(@uid, 1);
      read(@w, 2);
      if Map.pl_find(uid, C_PLAYER_ALL) then
         Map.pl_current.current_ping:=w;
   end;
   read(@tb, 1);
   sp_count:=tb;
   for i:=1 to tb do
   begin
      ReadString(sp[i].name);
      Read(@sp[i].ping, 2);
   end;
end;

procedure TClient_Machine.ReadInfo(flags: byte);
var
   s1, s2: string;

   tb, tb2, tb3, uid: byte;
   tw		: word;
   ww		: array [0..7] of word;
   buf   : array of byte;

   i: integer;

   stat: TPlayerStat;
   pl: TPlayer;
   c: TRGB;
   b: byte;

begin
   if flags and INFO_SERVER>0 then
   begin
      Read(@serv_info, sizeof(serv_info));
      ReadString(s1);
      ReadString(s2);
      Server.Name:=s1;
      NET_ServerMap:=s2;
      if (serv_info.session<>Map.session_number) or (NET_ServerMap<>Map.GetFileName) or
         (serv_info.gametype<>gametype) then
      begin
         NET_ClearAPL;
         Map.not_warmup_game:=not serv_info.warmup and Map.warmup;
         gametype_c:=serv_info.gametype;
         if (NET_ServerMap=Map.GetFileName) and (gametype_c=gametype)  then
            Map.Restart
         else LoadMap(NET_ServerMap);
         if NET.Type_<>NT_Client then Exit;
                  //дисконнект уже произошёл, надо срочно выйти из процедурки,
            		//ведь этого объекта уже не существует в природе!!!
   		getinfo_Send(INFO_LOAD);
         Server.ClearPing;
      end;
      HUD_SetTime(serv_info.servertime);
      Map.Demo.RecTime;
      Map.session_number:=serv_info.session;
      if serv_info.stopped then
      begin
         if not Map.stopped then
         	Map.StopGame;
      end;
   end;
   if flags and INFO_PLAYERS>0 then
   begin
      Read(@tb, 1);
      for i:=0 to tb-1 do
      begin
         Read(@uid, 1);
         Read(@tb2, 1);
         ReaD(@tb3, 1);
         ReadString(s1);
         ReadString(s2);
         Read(@c, 3);
         Read(@b, 1);

         pl := Map.PlayerByUid(uid);
         if pl<>nil then
         begin
            if pl.playertype<>tb2 then
            begin
               pl.playertype:=tb2;
            end;
         	if pl.name<>s1 then
            	Map.SetPlayerName(uid, s1);
         	if pl.modelname<>s2 then
            	Map.SetPlayerModel(uid, s2);
         end else
         begin
            if tb2=C_PLAYER_NET then
         		pl:=Map.pl_addNET(tb2, Server, s1, s2, true, true, uid)
            else pl:=Map.pl_add(tb2, s1, s2, false, uid);
         end;
         pl.railcolor:=c;
         pl.railtype:=b;
         Map.TeamJoin(uid, tb3);
         Read(@tb2, 1);
         if tb2>0 then
         	pl.Restart;
         pl.byte_Health:=tb2;
         Read(@tb2, 1);
         pl.Armor:=tb2;
         Read(@tw, 2);
         pl.word_pos_x:=tw;
         Read(@tw, 2);
         pl.word_pos_y:=tw;
      end;
      map.Demo.RecPlayers;
      if not Map.pl_find(-1, C_PLAYER_p1) then
         if not net_spectator then
            join_send(C_PLAYER_p1, p1name, p1model);
   end;
   if flags and INFO_OBJS>0 then
   begin
      Read(@tw, 2);
      with Map do
         while tw<Obj.Count do
         begin
            Read(@ww, Obj[tw].fNetSize*2);
            Obj[tw].LoadNet(ww);
            Read(@tw, 2);
         end;
   end;
   if flags and INFO_STATS>0 then
   begin
      Read(@tb, 1);
      for i:=0 to tb-1 do
      begin
         Read(@stat, sizeof(stat));
         Stat_Set(stat.UID, stat);
      end;
   end;
   if flags and INFO_PHYS>0 then
   begin
      Read(@tw, 2);
      if tb>0 then
      begin
         Read(@tw, 2);
         SetLength(buf, tb2);
         Read(@buf[0], tw);
         if (tb=phys_getvarscount) and
            (tb2=phys_getbufsize) then
            phys_readbuf(buf, tw);
      end;
   end;
end;

procedure TClient_Machine.removeplayer_recv;
var
   b: byte;
begin
   Read(@b, 1);
   if Map.pl_find(b, C_PLAYER_ALL) then
   	Map.pl_delete_current(true);
end;

procedure TClient_Machine.resp_Send(uid: byte);
begin
   Message_(NM_RESPAWN);
   NET_Write(@uid, 1);
   server.Send(false);
end;

procedure TClient_Machine.say_Send(uid: byte; msg: string);
begin
   Message_(NM_SAY);
   NET_Write(@uid, 1);
   WriteString(msg);
   server.Send(false);
end;

procedure TClient_Machine.shotobjkill_recv;
var
   w, x, y: word;

   ro: TRealObj;
begin
   Read(@w, 2);
   ro:=RealObj_Find(w);
 	Read(@x, 2);
   Read(@y, 2);
   if (ro<>nil) then
   begin
      ro.x:=x;
      ro.y:=y;
      ro.Kill;
   end;
end;

procedure TClient_Machine.shotobj_recv;
var
   s: TRealObjStruct;
   w: word;
   ss: single;
   obj: TRealObj;

begin
 	fillchar(s, sizeof(s), 0);
   Read(@s.uid, 2);
   Read(@s.playerUID, 1);
   Read(@s.itemid, 1);
   Read(@w, 2);
   s.x:=w;
   Read(@w, 2);
   s.y:=w;
   Read(@w, 2);
   s.angle:=w;
   s.angle:=s.angle*Pi/180;
   ss:=WPN_SPEED[s.ItemID];
   s.dx:=ss*cos(s.angle);
   s.dy:=ss*sin(s.angle);
   s.objtype:=otShot;
   obj:=RealObj_Add(s);
   for w:=1 to (Server.StatPing div 40) do
   	if not obj.dead then
     	 	obj.Update;
   Map.Demo.RecShotObjCreate(obj);
end;

procedure TClient_Machine.shot_recv;
var
   uid, weapon_: byte;
   x_, y_, angle_: word;
begin
   Read(@uid, 1);
   Read(@weapon_, 1);
   Read(@x_, 2);
   Read(@y_, 2);
   Read(@angle_, 2);
   if Map.pl_find(uid, C_PLAYER_NET) then
      with Map.pl_current do
   begin
//      cur_wpn:=weapon_;
//      SwitchTicker:=2;
      SetWeapon(weapon_);
      fshot:=true;
      shotpos:=Point2f(x_, y_);
      absangle:=angle_;
   end;
   //отсылать это все по сетке чтоли?? а нах, само пошлется, когда время настанет
end;

procedure TClient_Machine.shot_send(uid: byte);
var
   pl: TPlayer;
   b: byte; w: word;
   s: single;
begin
   if Map.pl_find(uid, C_PLAYER_ALL) then
   begin
      pl:=Map.pl_current;
      Message_(NM_SHOT);
      NET_Write(@uid, 1);
      b:=pl.cur_weapon;
      NET_Write(@b, 1);
      w:=round(pl.shotpos.x);
      NET_Write(@w, 2);
      w:=round(pl.shotpos.y);
      NET_Write(@w, 2);
      s:=pl.AbsAngle;
      while s<0 do
         s:=s+360;
      w:=round(s);
      NET_Write(@w, 2);
      Server.Send(true);
   end;
end;

function TClient_Machine.spects_Count: integer;
begin
   Result:=sp_count;
end;

procedure TClient_Machine.TeamJoin(uid, team: byte);
begin
   Message_(NM_TEAMJOIN);
   NET_Write(@uid, 1);
   NET_Write(@team, 1);
   Server.Send(true);
end;

procedure TClient_Machine.teamjoin_recv;
var
   uid, team: byte;
begin
   Read(@uid, 1);	//читаем тип игрока
   Read(@team, 1);
   if Map.pl_find(uid, C_PLAYER_ALL) then
      Map.TeamJoin(uid, team);
end;

procedure TClient_Machine.Update_Next;
begin
   inherited;
   if timer mod net_sync=0 then
   begin
   	Message_(NM_PLAYERS);
 		if players_write(Server) then
   		Server.Send(false);
 		players_sending_end;
   end;
end;

procedure TClient_Machine.Update_Prev;
var
 	IP_  : PChar;
   IP   : string;
 	i    : integer;
   port : word;
 	Msg,tb : Byte;
begin
   inherited;

		IP_ := nil;
      NET_Buf_seek:=0;
		NET_Buf_len := NET_Recv(NET_Buf, NET_BufLen, IP_, i);
      port:=i;
      IP  := StrPas(IP_);
      i := NET_Buf_len;

   while (NET_Buf_len>0) do
   begin

      Read(@Msg, 1);

      case Msg of
         NM_Msg: msg_Recv(IP, Port, i-1);
         NM_RInfo: rinfo_recv(IP, Port);
         NM_Invite: rinfo_recv(IP, Port, 1);
    	end;

    	if (IP=Server.IP) and (port=Server.Port) then
      case Msg of
         NM_PING:
            server.SendPong;
         NM_PONG:
            server.RecvPing;
         NM_PINGS:
            pings_recv;
         NM_DISCONNECT:
        	begin
            Read(@tb, 1);
            case tb of
             	NM_CLIENTLEAVE: Log('^1Disconnected');
             	NM_TIMEOUT: Log('^1You was dropped by timeout!');
              	NM_SERVERLEAVE: Log('^1Server leaves the game!');
               NM_KICK: Log('^1You have kicked by server!');
            end;
            Map.ClearAll;
            Exit;
         end;
         NM_GAMEINFO:
         begin
            Read(@tb, 1);
            ReadInfo(tb);
         end;
         NM_PLAYERS:
         begin
            Read(@serv_btimer, 1);
            if Server.Valid(serv_btimer) then
            	while NET_buf_SEEK<i do
               	players_recv;
         end;
         NM_GAMEMSG:
         begin
            Read(@serv_btimer, 1);
            while NET_buf_SEEK<i-1 do
          		gamemsg_recv;
         end;
         NM_ADDPLAYER:
          	addplayer_recv;
         NM_DELPLAYER:
          	removeplayer_recv;
         NM_SAY:
      		say_Recv;
         NM_CHANGENAME:
      		changename_Recv;
         NM_TEAMJOIN:
            teamjoin_recv;
      end;

		IP_ := nil;
      NET_Buf_seek:=0;
		NET_Buf_len := NET_Recv(NET_Buf, NET_BufLen, IP_, i);
      port:=i;
      IP  := StrPas(IP_);
      i := NET_Buf_len;

   end;//while

   //SERVER PING TIMEOUT
   if GetTickCount - server.LastPing > 1000*Net_Timeout then
   begin
      log('^1Server Ping Timeout');
      Map.ClearAll;
      Exit;
   end;
   if timer mod 50=0 then
   	Server.SendPing;
end;

end.
