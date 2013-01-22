unit NET_Server_Lib;

interface

uses
 Windows, SysUtils,
 Engine_Reg,
 Func_lib,
 Type_Lib,
 Graph_Lib,
 Math_Lib,
 Net_Lib,
 Arena_Lib;

type
	TServer_Machine =
   class(TNet_Machine)
   	constructor Create;
      destructor Destroy;override;
   protected
      fClients: array of TClient;
      cur_client: TClient;
      client_btimer: byte;

      sp_count: integer;

      msgcount: integer;

      procedure WriteInfo(flags: byte);
      procedure WriteInfoStat(uid: byte);

    	function GetClient(ind: integer): TClient;

      procedure join_recv;
      procedure disjoin_recv;
      procedure teamjoin_recv;
      procedure say_RecvEx;
      procedure changename_RecvEx;
      procedure resp_Recv;
      procedure pings_Send;
      procedure shot_recv;
      procedure SendToAll(APL : boolean);
      procedure SendToAllEx(APL : boolean);

      function Getspects(ind: integer): TSpectator;override;
   public
      procedure Update_Prev; override;
      procedure Update_Next; override;

      procedure Invite_Send(IP: string; port: word);

      function client_Add(IP: string; port: word; name: string): TClient;
      function client_Count: integer;//количество клиентов
      function client_IndexOf(IP: string; port: word): integer;
      function client_Find(IP: string; port: word): TClient;
      procedure client_Delete(ind: integer; reason: byte);
      property client[ind: integer]: TClient read GetClient;

      procedure changemap_send;

      procedure game_prepare; override;
      procedure game_send;    override;
      procedure game_stop;

      procedure ObjActivate(num: word; uid: byte);
      procedure PlayerHit(h: THit);
      procedure PlayerRespawn(p: TObject);
      procedure ShotObjCreate(robj: TObject);
      procedure ShotObjKill(uid, x, y: word);
      procedure TeamJoin(uid, team: byte);

      procedure addplayer_send(Pl: TObject);
      procedure removeplayer_send(uid: byte);

      procedure say_Send(uid: byte; msg: string);override;
      procedure changename_Send(uid: byte; name, model: string); override;
      procedure shot_send(uid: byte);override;

      procedure phys_Send(ind: integer);//ind- номер команды
      procedure phys_SendAll;

      function spects_Count: integer;override;
   end;

var
   net_Server: TServer_Machine;

implementation

uses Constants_Lib, Map_Lib, Stat_Lib, Player_Lib, Real_Lib, Phys_Lib, HUD_Lib, MapObj_Lib,
   Game_Lib;

{ TServer_Machine }

procedure TServer_Machine.addplayer_send(pl: TObject);
var
   i: integer;
   ptype, uid: byte;
   player: TPlayer;
   c: TRGB; b: byte;
begin
   player:=TPlayer(pl);
   if fclients<>nil then
   for i:=low(fclients) to high(fclients) do
   begin
   	Message_(NM_Addplayer);
      uid:=Player.uid;
   	NET_Write(@uid, 1);
      if fclients[i]=player.client then
         ptype:=player.localtype
      else ptype:=C_PLAYER_NET;
      NET_Write(@ptype, 1);
   	WriteString(player.name);
   	WriteString(player.modelname);
      c:=player.railcolor;
      b:=player.railtype;
      NET_Write(@c, 3);
      NET_Write(@b, 1);
      fclients[i].Send(true);
   end;
end;

procedure TServer_Machine.changemap_send;
var
   tb: byte;
begin
//   NET_ClearAPL;
  	Message_(NM_GAMEINFO);
 	tb:=INFO_START;
  	NET_Write(@tb, 1);
  	WriteInfo(tb);
   SendToAll(true);
end;

procedure TServer_Machine.changename_RecvEx;
var
   uid: byte;
   name, model: string;
   c: TRGB;
   b: byte;
begin
   Read(@uid, 1);
   ReadString(name);
   ReadString(model);
   Read(@c, 3);
   Read(@b, 1);

   Map.SetPlayerName(uid, name, false);
   Map.SetPlayerModel(uid, model, false);
   if Map.pl_find(uid, C_PLAYER_NET) then
   begin
      Map.pl_current.railcolor:=c;
      Map.pl_current.railtype:=b;
   end;
   Message_(NM_CHANGENAME);
   NET_Write(@uid, 1);
   WriteString(name);
   WriteString(model);
   NET_Write(@c, 3);
   NET_Write(@b, 1);
   SendToAllEx(false);
end;

procedure TServer_Machine.changename_Send(uid: byte; name, model: string);
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
   SendToAll(false);
end;

function TServer_Machine.client_Add(IP: string; port: word; name: string): TClient;
begin
   SetLength(fClients, client_Count+1);
   Result:=TClient.Create(IP, Port, name);
   fClients[high(fclients)]:=Result;
end;

function TServer_Machine.client_Count: integer;
begin
   if fClients<>nil then Result:=high(fClients)+1
   else Result:=0;
end;

procedure TServer_Machine.client_Delete(ind: integer; reason: byte);
begin
	if (ind>=0) and (ind<client_Count) then
   begin
      if fClients[ind].players_count=0 then
         dec(sp_count);
      Map.pl_deleteall_NET(fClients[ind]);
      fClients[ind].SendDisconnect(reason);
   	fClients[ind].Free;
   	while ind<client_Count-1 do
      begin
         fClients[ind]:=fClients[ind+1];
         Inc(ind);
      end;
      if client_Count>1 then
      	SetLength(fClients, client_Count-1)
         else fClients:=nil;
   end;
end;

function TServer_Machine.client_Find(IP: string; port: word): TClient;
var
   i: integer;
begin
   i:=client_IndexOf(IP, port);
   if i>=0 then
   	Result:=fClients[i]
      else Result:=nil;
end;

function TServer_Machine.client_IndexOf(IP: string; port: word): integer;
var
   i: integer;
begin
   Result:=-1;
   for i:=0 to client_Count-1 do
      if (fClients[i].IP = IP) and (fClients[i].port=port) then
      begin
         Result:=i;
         Break;
      end;
end;

constructor TServer_Machine.Create;
begin
   inherited;
   fSocket:=true;
   fType:=NT_SERVER;
   NET_InitSocket(sv_port);

   sp_count:=0;
end;

destructor TServer_Machine.Destroy;
begin
   while client_Count>0 do
   	client_Delete(0, NM_SERVERLEAVE);
  inherited;
end;

procedure TServer_Machine.disjoin_recv;
var
   ptype: byte;
begin
   Read(@ptype, 1);
   //пока что уничтожаем всех игроков данного клиента
   with Map do
   if pl_find_NET(-1, cur_client) then
   repeat
      if pl_current.localtype and ptype>0 then
      begin
         pl_delete_current(true);
         dec(cur_client.players_count);
         if cur_client.players_count=0 then
         begin
            inc(sp_count);
            break;
         end;
      end;
   until not Map.pl_find_NETnext(-1, cur_client);
end;

procedure TServer_Machine.game_prepare;
begin
   inherited;
  	msgcount:=0;
   Message_(NM_GAMEMSG);
   NET_Write(@btimer, 1);
end;

procedure TServer_Machine.game_send;
begin
  	inherited;
   if msgcount>0 then
      SendToAll(true);
   NET_Clear;
end;

procedure TServer_Machine.game_stop;
var
   b: byte;
begin
   //всем отослать инфу о игре :)
   Message_(NM_GAMEINFO);
   b:=INFO_SERVER+INFO_STATS;
   NET_Write(@b, 1);
   WriteInfo(b);
   SendToAll(true);
end;

function TServer_Machine.GetClient(ind: integer): TClient;
begin
   if (ind>=0) and (ind<client_Count) then
   	Result:=fClients[ind]
      else Result:=nil;
end;

function TServer_Machine.Getspects(ind: integer): TSpectator;
var
   i, j: integer;
begin
   j:=1;
   if fclients<>nil then
   for i:=low(fclients) to high(fclients) do
      if (fclients[i].players_count=0) then
         if j=ind then
         begin
            Result.name:=fclients[i].Name;
            Result.ping:=fclients[i].StatPing;
            break;
         end else Inc(j);
end;

procedure TServer_Machine.Invite_Send(IP: string; port: word);
begin
   Message_(NM_INVITE);
   WriteInfo(INFO_SERVER);
   NET_Send(PChar(IP), port, true);
end;

procedure TServer_Machine.join_recv;
var
   s1, s2: string;
   ptype: byte;
   i: integer;
   c: TRGB;
   b: byte;
   pl: TPlayer;
begin
   Read(@ptype, 1);	//читаем тип игрока
   ReadString(s1);//имя
   ReadString(s2);//модель
   Read(@c, 3);
   Read(@b, 1);
   for i:=0 to Map.pl_count-1 do
      if (Map.player[i].client=cur_client) and
      	(Map.player[i].localtype=ptype) then Exit;	//DUBLICATE
   pl:=Map.pl_addNET(ptype, cur_client, s1, s2, true, true);
   if pl<>nil then
   begin
      pl.railcolor:=c;
      pl.railtype:=b;
      if cur_client.players_count=0 then
         dec(sp_count);
      inc(cur_client.players_count);
      cur_client.ClearPing;
   end;
end;

procedure TServer_Machine.ObjActivate(num: word; uid: byte);
var
   b: byte;
   ww: array [0..7] of word;
begin
   with Map do
   begin
      if (num<Obj.Count) and not (Obj[num].ObjType in NetObjs) then Exit;
      b:=NM_OBJECTS;
      NET_Write(@b, 1);
      NET_Write(@num, 2);
      NET_Write(@uid, 1);
      if num<Obj.Count then
      begin
         Obj[num].SaveNet(ww);
         NET_Write(@ww, Obj[num].fNetSize*2);
      end;
      Inc(msgcount);
   end;
end;

procedure TServer_Machine.phys_Send(ind: integer);
var
   s1, s2: string;
   tb: byte;
begin
   Message_(NM_GAMEINFO);
   tb:=INFO_PHYS;
   NET_Write(@tb, 1);
   tb:=1;
   NET_Write(@tb, 1);
   s1:=phys_getvarname(ind);
   s2:=phys_getstrvalue(ind);
   if (s1<>'') and (s2<>'') then
   begin
      WriteString(s1);
      WriteString(s2);
   end;
   SendToAll(true);
end;

procedure TServer_Machine.phys_SendAll;
var
   tb: byte;
begin
   Message_(NM_GAMEINFO);
   tb:=INFO_PHYS;
   NET_Write(@tb, 1);
   WriteInfo(INFO_PHYS);
   SendToAll(true);
end;

procedure TServer_Machine.pings_Send;
var
   tb, uid: byte;
   w: word;

   i: integer;
begin
   Message_(NM_PINGS);
   tb:=Map.Players;
   NET_Write(@tb, 1);
   for i:=0 to tb-1 do
   begin
      uid:=Map.Player[i].uid;
      w:=Map.player[i].current_ping;
      NET_Write(@uid, 1);
      NET_Write(@w, 2);
   end;
   tb:=sp_count;
   NET_Write(@tb, 1);
   if fclients<>nil then
   for i:=low(fclients) to high(fclients) do
      if fclients[i].players_count=0 then
   begin
      WriteString(fclients[i].Name);
      w:=fclients[i].StatPing;
      NET_Write(@w, 2);
   end;
   SendToAll(false);
end;

procedure TServer_Machine.PlayerHit(h: THit);
var
   b: byte;
begin
   b:=NM_HITS;
   NET_Write(@b, 1);
   NET_Write(@h, sizeof(h));
   Inc(msgcount);
end;

procedure TServer_Machine.PlayerRespawn(p:TObject);
var
   b, uid, num: byte;
   w: word;
   pl: TPlayer;
begin
   pl:=TPlayer(p);
   b:=NM_RESPAWN;
   NET_Write(@b, 1);
   uid:=pl.uid;
   NET_Write(@uid, 1);
   num:=pl.respindex;
   NET_Write(@num, 1);
   w:=pl.lasthitid;
   NET_Write(@w, 2);
   Inc(msgcount);
end;

procedure TServer_Machine.removeplayer_send(uid: byte);
begin
   Message_(NM_DELPLAYER);
   NET_Write(@uid, 1);
   SendToAll(true);
end;

procedure TServer_Machine.resp_Recv;
var
   tb: byte;
   pl : TPlayer;
begin
   Read(@tb, 1);
   pl:=Map.PlayerByUID(tb);
   if (pl<>nil) and pl.dead then
      Map.pl_respawn(pl);
end;

procedure TServer_Machine.say_recvEx;
var
   uid: byte;
   msg: string;
begin
   Read(@uid, 1);
   ReadString(msg);

   Map.Say(uid, msg, false);

   Message_(NM_SAY);
   NET_Write(@uid, 1);
   WriteString(msg);
   SendToAllEx(false);
end;

procedure TServer_Machine.say_Send(uid: byte; msg: string);
begin
	Message_(NM_SAY);
   NET_Write(@uid, 1);
   WriteString(msg);
   SendToAll(false);
end;

procedure TServer_Machine.SendToAll(APL : boolean);
var
   i: integer;

begin
   if fclients<>nil then
   for i:=low(fclients) to high(fclients) do
      if not fClients[i].map_download then
         fClients[i].Send(APL);
end;

procedure TServer_Machine.SendToAllEx(APL: boolean);
var
   i: integer;

begin
   if fclients<>nil then
   for i:=low(fclients) to high(fclients) do
      if not fClients[i].map_download then
         if fClients[i]<>cur_client then
      	   fClients[i].Send(APL);
end;

procedure TServer_Machine.ShotObjCreate(robj: TObject);
var
   b: byte;
   x, y: integer;
   x0, y0, ang: word;
   s: TRealObjStruct;
begin
   s:=TRealObj(robj).struct;
   b:=NM_SHOTOBJ;
   NET_Write(@b, 1);
   NET_Write(@s.uid, 2);
   NET_Write(@s.playerUID, 1);
   NET_Write(@s.itemid, 1);

   x:=round(s.x);
   if x<0 then x:=0;
   x0:=x;
   y:=round(s.y);
   if y<0 then y:=0;
   y0:=y;
   ang:=round(s.angle*180/Pi);

   NET_Write(@x0, 2);
   NET_Write(@y0, 2);
   NET_Write(@ang, 2);

   inc(msgcount);
end;

procedure TServer_Machine.ShotObjKill(uid, x, y: word);
var
   b: byte;
begin
   b:=NM_SHOTOBJ_KILL;
   NET_Write(@b, 1);
   NET_Write(@uid, 2);
   NET_Write(@x, 2);
   NET_Write(@y, 2);
   Inc(msgcount);
end;

procedure TServer_Machine.shot_recv;
var
   uid, weapon_: byte;
   x_, y_, angle_: word;
begin
   Read(@uid, 1);
   Read(@weapon_, 1);
   Read(@x_, 2);
   Read(@y_, 2);
   Read(@angle_, 2);
   if Map.pl_find_NET(uid, cur_client) then
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

procedure TServer_Machine.shot_send(uid: byte);
var
   pl: TPlayer;
   b: byte; w: word;
   s: single;
begin
   if Map.pl_find(uid, C_PLAYER_ALL) then
   begin
      pl:=Map.pl_current;

      b:=NM_SHOT;
      NET_Write(@b, 1);
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

  	   Inc(msgcount);
   end;
end;

function TServer_Machine.spects_Count: integer;
begin
   Result:=sp_count;
end;

procedure TServer_Machine.TeamJoin(uid, team: byte);
begin
   Message_(NM_TEAMJOIN);
   NET_Write(@uid, 1);
   NET_Write(@team, 1);
   SendToAll(true);
end;

procedure TServer_Machine.teamjoin_recv;
var
   uid, team: byte;
begin
   Read(@uid, 1);	//читаем тип игрока
   Read(@team, 1);
   if Map.pl_find_NET(uid, cur_client) then
      Map.TeamJoin(uid, team);
end;

procedure TServer_Machine.Update_Next;
var
   i: integer;
begin
   inherited;
   if timer mod net_sync=0 then
   if fclients<>nil then
   for i:=low(fclients) to high(fclients) do
   begin
      Message_(NM_PLAYERS);
   	if players_write(fclients[i]) then
      	fclients[i].Send(false);
   end;
	players_sending_end;
end;

procedure TServer_Machine.Update_Prev;
var
 	IP_  : PChar;
   IP, s: string;
 	i, k : integer;
   port : word;
 	Msg  : Byte;

   params: TNP_ConnectParams;

   tb: byte;
begin
   inherited;

		IP_ := nil;
      NET_Buf_seek:=0;
		NET_Buf_len := NET_Recv(NET_Buf, NET_BufLen, IP_, i);
      port := i;
      IP   := StrPas(IP_);
      i    := NET_Buf_len;

   while (NET_Buf_len>0) do
   begin

      Read(@Msg, 1);
      case Msg of
         NM_Msg: msg_Recv(IP, Port, i-1);
         NM_Ping: pong_Send(IP, Port);
         NM_SINFO: begin
         	         Message_(NM_RINFO);
          				WriteInfo(INFO_SERVER);
                     NET_Send(PChar(IP), Port, true);
            	 	end;
         NM_RInfo: rinfo_recv(IP, Port);
         NM_Invite: rinfo_recv(IP, Port, 1);
      end;

      k:=client_IndexOf(IP, Port);

      cur_client:=nil;
     	if k>=0 then
         cur_client:=Client[k];
      if msg=NM_Connect then
      begin
  			Read(@Params, sizeof(params));
  			ReadString(s);
         if k<0 then
         begin
  			   cur_client:=client_Add(IP, Port, s);
            Inc(sp_count);
  			   Log('^B^2'+IP+':'+inttostr(Port)+'^7 '+s+' ^1^Bconnected');
         end else
  			   Log('^B^2'+IP+':'+inttostr(Port)+'^7 '+s+' ^1^BREconnected');
  			Message_(NM_ACCEPT);

         Params.Version:=1;
   		params.NET_ID:=fNet_ID;
         NET_Write(@Params, sizeof(params));

         WriteInfo(INFO_START);
         NET_Send(PChar(IP), port, true);
      end else
     	if k>=0 then
      begin
         cur_client:=Client[k];
      	case Msg of
          	NM_GAMEINFO:
          	begin
             	Read(@tb, 1);
             	Message_(NM_GameInfo);
              	NET_Write(@tb, 1);
              	WriteInfo(tb);
              	NET_Send(PChar(Client[k].IP), Client[k].port, true);
            end;
            NM_PONG:
            begin
               cur_client.recvPing;
               if Map.pl_find_NET(-1, cur_client) then
               repeat
                  Map.pl_current.current_ping:=cur_client.StatPing;
               until not Map.pl_find_NETnext(-1, cur_client);
            end;
            NM_Disconnect:
            begin
					log('^1Disconnect: ^7'+cur_client.Name);
               client_Delete(k, NM_CLIENTLEAVE);
            end;
            NM_PLAYERS:
            begin
               Read(@client_btimer, 1);
               if cur_client.Valid(client_btimer) then
               	while NET_buf_SEEK<i do
                  	players_recv;
            end;
            NM_JOIN:
               join_Recv;
            NM_DISJOIN:
               disjoin_Recv;
            NM_SAY:
               say_RecvEx;
         	NM_CHANGENAME:
      			changename_RecvEx;
            NM_RESPAWN:
            //чувак просит респауна :)
               resp_Recv;
            NM_TEAMJOIN:
               teamjoin_recv;
            NM_SHOT:
               shot_recv;
               
       ///// Передача карты по сети /////
       // XProger: пришлось разрешить изменение LastPing у клиента ;)
            // необходимо подготовить карту для скачивания
            NM_MAP_GET :
             begin
                ReadString(s);
             with cur_client do
              begin
                s:=FindMap(s);
                if s<>'' then
                  map_buf := Map_GetBuffer(s, map_size);
                if (map_size = 0) or (map_buf = nil) or (not net_mapsend) then
                  Message_(NM_MAP_END) // ничего посылать мы не обираемся
              else
               begin
               // посылаем размер буфера под карту
                  Message_(NM_MAP_SIZE);
                  NET_Write(@map_size, 4);
               end;
               Send(true);
               LastPing := GetTickCount;
              end;
             end;

            // просят кусок карты
            NM_MAP_BUF :
             with cur_client do
              begin
                Read(@i, 4); // ID пакет
                Log('MAP_BUF '+inttostr(i));
              if (map_size = 0) or (map_buf = nil) or (not net_mapsend) then
              begin
               Message_(NM_MAP_END); // что-то случилось или сервер не захотел передавать карту
               Send(true);
              end
              else
               if (i > -1) and (i < (map_size - 1) div NET_MAPBUFSIZE + 1) then
                begin
                Message_(NM_MAP_BUF);
                NET_Write(@i, 4);   // пишем ID посылаемого пакета
                NET_Write(@map_buf[i * NET_MAPBUFSIZE], min(map_size - i*NET_MAPBUFSIZE, NET_MAPBUFSIZE) );
                Log('Data: ' + inttostr(i * NET_MAPBUFSIZE)+' size: '+inttostr(min(map_size - i * NET_MAPBUFSIZE, NET_MAPBUFSIZE)) );
                Send(true);
                end;
              LastPing := GetTickCount;
              end;

            // клиент получил то, что хотел :)
            NM_MAP_END :
            begin
             with cur_client do
              if map_buf <> nil then
              begin
               FreeMem(map_buf);
               map_buf:=nil;
              end;
            end;
      	end; //case
      end; //if k>=0

		IP_ := nil;
      NET_Buf_seek:=0;
		NET_Buf_len := NET_Recv(NET_Buf, NET_BufLen, IP_, i);
      port := i;
      IP   := StrPas(IP_);
      i    := NET_Buf_len;

   end;//while

   //теперь проверка на пинг...
   if fclients<>nil then
	for i := high(fclients) downto low(fclients) do
 		if GetTickCount - fClients[i].LastPing > 1000*Net_Timeout then
      begin
         log('^1Ping Timeout: ^7'+fClients[i].Name);
  			client_delete(i, NM_TIMEOUT);
      end;

	if timer mod 50 = 0 then
   begin
      if fclients<>nil then
 		for i := low(fClients) to high(fClients) do
  			fClients[i].SendPing;
      pings_send;
      changemap_send;
   end;

if Arena_Timer < GetTickCount then
 Arena_Ping;
end;

procedure TServer_Machine.WriteInfo(flags: byte);
var
   serv_info : TNP_ServerInfo;

   tb: byte;
   tw: word;

   ww		: array [0..7] of word;
   buf   : array of byte;
   i: integer;

   c:TRGB; b: byte;
begin
   //печатаем в выходной поток информацию о игре
   if flags and INFO_SERVER>0 then
   begin
      serv_info.MaxPlayers	:= sv_maxplayers;
      serv_info.Players	  	:= Map.pl_count;
      serv_info.Password	:= false;
      serv_info.MapCRC32	:= 0;
      serv_info.Session		:= Map.session_number;
      serv_info.gametype   := gametype;
      serv_info.servertime := HUD_GetTime;
      serv_info.warmup     := Map.warmup;
      serv_info.warmuparmor:= warmup_armor;
      serv_info.stopped:=Map.stopped;
      NET_Write(@serv_info, sizeof(serv_info));
      WriteString(sv_name);
      WriteString(Map.GetFileName);
   end;
   if flags and INFO_PLAYERS>0 then
   begin
      tb:=Map.pl_count;
      NET_Write(@tb, 1);
      with Map do
      	for i:=0 to pl_count-1 do
        	begin
            tb:=player[i].uid;
      		NET_Write(@tb, 1);
            //тип локального плэйера( отн. клиента)
				if player[i].client = cur_client then
            	tb:=player[i].localtype
               else tb:=C_PLAYER_NET;

            NET_Write(@tb, 1);
            tb:=player[i].team;
            NET_Write(@tb, 1);
            WriteString(player[i].Name);
            WriteString(player[i].ModelName);
            c:=player[i].railcolor;
            b:=player[i].railtype;
            NET_Write(@c, 3);
            NET_Write(@b, 1);
            //пишем здоровье и броню + координаты - обязательные вещи.
            tb:=player[i].byte_Health;
            if player[i].dead then tb:=0;
            NET_Write(@tb, 1);
            tb:=player[i].Armor;
            NET_Write(@tb, 1);
            tw:=player[i].word_pos_x;
            NET_Write(@tw, 2);
            tw:=player[i].word_pos_y;
            NET_Write(@tw, 2);
       	end;
   end;
	if flags and INFO_OBJS>0 then
   begin
      with Map do
      for i:=0 to Obj.Count-1 do
         with Obj[i] do
         if fNetSize>0 then
         begin
            tw:=i;
            NET_Write(@tw, 2);
            SaveNet(ww);
            NET_Write(@ww, fNetSize*2);
         end;
      tw:=20000;
      NET_Write(@tw, 2);
   end;
   if flags and INFO_STATS>0 then
   begin
      tb:=Map.pl_count;
      NET_Write(@tb, 1);
      with Map do
     	 	for i:=0 to pl_count-1 do
            NET_Write(player[i].stat, sizeof(TPlayerStat));
   end;
   if flags and INFO_PHYS>0 then
   begin
      if not net_phys_sending then
      begin
         tw:=0;
         NET_Write(@tw, 2);

      end else
      begin

         tw:=phys_getvarscount;
         NET_Write(@tw, 2);
         tw:=phys_getbufsize;
         NET_Write(@tw, 2);
         SetLength(buf, tw);
         phys_writebuf(buf);
         NET_Write(@buf[0], tw);
         buf:=nil;
      
      end;
   end;
end;

procedure TServer_Machine.WriteInfoStat(uid: byte);
var
   pstat: PPlayerStat;
begin
   pstat:=Stat_Get(uid, true);
   NET_Write(pstat, sizeof(TPlayerStat));
   //может быть пригодиться
end;

end.
