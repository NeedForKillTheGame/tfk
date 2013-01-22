unit PlayersUtils_Lib;

interface

uses
 Engine_Reg,
 Func_Lib,
 Type_Lib,
 Graph_Lib,
 Math_Lib,
 Player_Lib,
 ObjSound_Lib,
 Constants_Lib,
 Phys_Lib,
 NET_Lib,
 NET_Server_Lib;

 //карта, поддерживающая игроков

 //поиск реализован по нескольким параметрам:
 //UID (default -1)
 //ptype (default 0, -1)

type
 TTFKPlayerMap = class(TTFKPhysMap)
      constructor Create;
      destructor Destroy;override;
    private
      pl_cur_index: integer;
      pl_hash: array [-10..255] of TPlayer;
    	function Getpl_current: TPlayer;
    public
		started: boolean;
      //стартовал ли матч, можно ли оповещать bot_dll о системных событиях
    	player : array of TPlayer;
      procedure pl_clear;
      procedure pl_delete(Pl: TPlayer);
   	procedure pl_delete_index(ind: integer);
      procedure pl_deleteall_ptype(ptype: integer);
      procedure pl_deleteall_NET(client: TClient; showmsg: boolean = false);
      procedure pl_delete_UID(uid: integer);
      procedure pl_delete_current(logmsg: boolean = false);
   	function pl_add(ptype: integer; const Name, Model: string; respawn: boolean=false;uid: integer=0): TPlayer;overload;
   	function pl_add(ptype: integer; plstruct: TPlayerStruct; respawn: boolean=false): TPlayer;overload;
   	function pl_addNET(ptype: byte; client: TClient; const Name, Model: string; respawn: boolean=false; logmsg:boolean=false; uid: integer=0): TPlayer;
      function pl_count_ptype(ptype: integer): integer;
      function pl_count: integer;
      function pl_find(uid, ptype: integer): boolean;
      function pl_findnext(uid, ptype: integer): boolean;
      function pl_find_NET(uid: integer; client: TClient): boolean;
      function pl_find_NETnext(uid: integer; client: TClient): boolean;
      property pl_current: TPlayer read Getpl_current;
      property pl_cur_ind: integer read pl_cur_index;
      procedure pl_respawn(pl: TPlayer);

      procedure pl_update_input;
      procedure pl_update_kill;
      procedure pl_update_respawn;
      procedure pl_update_physic;
      procedure pl_update;

      procedure pl_stat_check_excellent(uid: integer);


		function TracePlayers(x, y, angle: single; var s: single; ownerUID: integer): TPlayer;

      //а это уже для совместимости со старой версией библиотек...
      property Players: integer read pl_count;
      function PlayerByUID(uid: integer): TPlayer;
      function pl_index(pl:TPlayer): integer;
    public
      function gen_uid : byte;

      function TeamAuto: byte;virtual;
    end;

implementation

uses
 Bot_Lib,
 HUD_Lib,
 Weapon_Lib,
 Stat_Lib,
 Demo_Lib,
 Binds_Lib,
 Log_Lib,
 SysUtils_,
 Menu_Lib,
 Map_Lib,
 ItemObj_Lib,
 NET_Client_Lib;

{ TTFKPlayerMap }

constructor TTFKPlayerMap.Create;
begin
   inherited;
   player:=nil;
   pl_cur_index:=-1;
   fillchar(pl_hash, sizeof(pl_hash), 0);
end;

destructor TTFKPlayerMap.Destroy;
begin
   pl_clear;
  inherited;
end;

function TTFKPlayerMap.pl_add(ptype: integer; const Name,
  Model: string; respawn: boolean;uid: integer): TPlayer;
begin
 Result := nil;
 if ( (pl_count< sv_maxplayers) or Map.IsClientGame ) and
	(	(ptype>C_PLAYER_p2) or not pl_find(-1, ptype) )	and
   (  (ptype and C_PLAYER_BOTS=0) or (NET.TYPE_<>NT_CLIENT)) and
   (pl_hash[uid]=nil)	then
 begin

 if uid<=0 then
   Result := TPlayer.Create(ptype, gen_uid, TeamAuto)
 else Result:= TPlayer.Create(ptype, uid, TeamAuto);
 Result.Name       := Name;
 Result.UseMouse   := ptype=C_PLAYER_p1;
 Result.stat       := Stat_Create(Result.UID);
 Result.LoadFromFile(Model);
 Result.Restart;
 Result.dead	    := true;
 pl_hash[Result.UID]:=Result;
 pl_cur_index:=players;
 SetLength(Player, Players + 1);
 Player[pl_cur_index] := Result;

 	if respawn then
    	pl_respawn(Result);

 	if ptype<=2 then
  		Status_HUD[ptype-1].Target := Result;

   botdll_AddPlayer(pl_cur_index);
 //а теперь идёт оповещение демке
   if Demo.recording then
		Demo.RecAddPlayer(pl_cur_index);
	if NET.Type_=NT_SERVER then
 		net_server.addplayer_send(Result);
 end
else
 if (pl_count>= sv_maxplayers) then
 	Log('^3Cannot addplayer, ^5sv_maxplayers ^3reached.')
 else if pl_hash[uid]<>nil then Log('^3Cannot addplayer, uid dublicated');

end;

function TTFKPlayerMap.pl_addNET(ptype: byte; client: TClient; const Name, Model: string;
  respawn: boolean; logmsg: boolean; uid: integer): TPlayer;
begin
 	Result := nil;
 	if ( (pl_count< sv_maxplayers) or Map.IsClientGame )  and (pl_hash[uid]=nil) then
 	begin
 if uid<=0 then
   Result := TPlayer.Create(C_PLAYER_NET, gen_uid, TeamAuto)
 else Result:= TPlayer.Create(C_PLAYER_NET, uid, TeamAuto);
      Result.Name       := Name;
 		Result.stat       := Stat_Create(Result.UID);
      Result.client := Client;
      Result.localtype  := ptype;
 		Result.LoadFromFile(Model);
 		Result.Restart;
 		Result.dead	    := true;
 		pl_cur_index:=players;
 		SetLength(Player, Players + 1);
 		Player[pl_cur_index] := Result;
      pl_hash[Result.UID]:=Result;

 		if respawn then
    		pl_respawn(Result);

   	botdll_AddPlayer(pl_cur_index);
 //а теперь идёт оповещение демке
   	if Demo.recording then
			Demo.RecAddPlayer(pl_cur_index);
 		if NET.Type_=NT_SERVER then
  	 		net_server.addplayer_send(Result);
   	if logmsg then
        Log_AddPlayer(Result);
 	end
	else
 		if (pl_count>= sv_maxplayers) then
 			Log('^3Cannot addplayer, ^5sv_maxplayers ^3reached.')
      else Log('^3Cannot addplayer, uid dublicated');
end;

function TTFKPlayerMap.pl_add(ptype: integer; plstruct: TPlayerStruct;
  respawn: boolean): TPlayer;
begin
 Result := nil;
 if (	(ptype>C_PLAYER_p2) or not pl_find(-1, ptype) )	and
    (pl_hash[plstruct.UID]=nil)  then
 begin
 	Result            := TPlayer.Create(ptype, TeamAuto);
 	Result.pstruct	 	:= plstruct;
 	Result.UseMouse   := ptype=C_PLAYER_p1;
 	Result.stat       := Stat_Create(Result.UID);
 	Result.LoadFromFile(plstruct.ModelName);

 	pl_cur_index:=pl_count;
 	SetLength(Player, pl_count + 1);
 	Player[pl_cur_index] := Result;
 pl_hash[Result.UID]:=Result;

 	if respawn then
    	pl_respawn(Result);

 	if ptype <= 2 then
  		Status_HUD[ptype-1].Target := Result;

	botdll_AddPlayer(pl_cur_index);
   if Demo.recording then
		Demo.RecAddPlayer(pl_cur_index);
 end else if (pl_hash[plstruct.UID]<>nil) then
     Log('^3Cannot addplayer, uid dublicated');
end;

procedure TTFKPlayerMap.pl_clear;
var
   i: integer;
begin
	Status_Hud[0].Target:=nil;
	Status_Hud[1].Target:=nil;
   for i:=0 to pl_count-1 do
   begin
      botdll_RemovePlayer(player[i].uid);
      player[i].Free;
   end;
   fillchar(pl_hash, sizeof(pl_hash), 0);
   player:=nil;
//   botdll_restart;
end;

function TTFKPlayerMap.pl_count: integer;
begin
   if player<>nil then Result:=Length(Player)
   else Result:=0;
end;

procedure TTFKPlayerMap.pl_delete(Pl: TPlayer);
var
   i: integer;
begin
   for i:=0 to pl_count-1 do
      if player[i]=pl then pl_delete_index(i);
end;

procedure TTFKPlayerMap.pl_delete_current(logmsg: boolean);
begin
   if logmsg then
      Log_RemovePlayer(pl_current);
   pl_delete_index(pl_cur_index);
   Dec(pl_cur_index);
end;

procedure TTFKPlayerMap.pl_delete_UID(uid: integer);
begin
   if pl_find(uid, -1) then
      pl_delete_current;
end;

procedure TTFKPlayerMap.pl_deleteall_ptype(ptype: integer);
begin
   if pl_find(-1, ptype) then
   repeat
      pl_delete_current;
   until not pl_findnext(-1, ptype);
end;

procedure TTFKPlayerMap.pl_deleteall_NET(client: TClient; showmsg: boolean);
begin
   if pl_find_NET(-1, client) then
   repeat
      log_RemovePlayer(pl_current);
      pl_delete_current;
   until not pl_find_NETnext(-1, client);
end;

function TTFKPlayerMap.pl_find(uid, ptype: integer): boolean;
begin
   pl_cur_index:=0;Result:=false;
   if ptype<0 then ptype:=C_PLAYER_ALL;
   if pl_count>0 then
   repeat
      if ( (player[pl_cur_index].UID=uid) or (uid<=-1) ) and
         ( (player[pl_cur_index].playertype and ptype)>0 ) then
         begin
            Result:=true;
            Break;
         end;
      Inc(pl_cur_index);
   until pl_cur_index>=pl_count;
end;

function TTFKPlayerMap.pl_findnext(uid, ptype: integer): boolean;
begin
   Result:=false;
   if ptype<0 then ptype:=C_PLAYER_ALL;
   Inc(pl_cur_index);
   while pl_cur_index<pl_count do
   begin
      if ( (player[pl_cur_index].UID=uid) or (uid<=-1) ) and
         ( (player[pl_cur_index].playertype and ptype)>0 ) then
         begin
            Result:=true;
            Break;
         end;
      Inc(pl_cur_index);
   end;
end;

function TTFKPlayerMap.pl_find_NET(uid: integer; client: TClient): boolean;
begin
   pl_cur_index:=0;Result:=false;
   if pl_count>0 then
   repeat
      if ( (player[pl_cur_index].UID=uid) or (uid<=-1) ) and
           (player[pl_cur_index].playertype=C_PLAYER_NET) and
         ( (player[pl_cur_index].Client=Client) or (Client=nil)) then
         begin
            Result:=true;
            Break;
         end;
      Inc(pl_cur_index);
   until pl_cur_index>=pl_count;
end;

function TTFKPlayerMap.pl_find_NETnext(uid: integer;
  client: TClient): boolean;
begin
   Result:=false;
   Inc(pl_cur_index);
   while pl_cur_index<pl_count do
   begin
      if ( (player[pl_cur_index].UID=uid) or (uid<=-1) ) and
           (player[pl_cur_index].playertype=C_PLAYER_NET) and
           (player[pl_cur_index].Client=Client) or (Client=nil) then
         begin
            Result:=true;
            Break;
         end;
      Inc(pl_cur_index);
   end;
end;


procedure TTFKPlayerMap.pl_delete_index(ind: integer);
var
   i: integer;
begin
	if (ind >= pl_count) or (ind < 0) then Exit;
   pl_hash[Player[ind].UID]:=nil;
   botdll_RemovePlayer(Player[ind].UID);
   if Demo.recording then
  	 	Demo.RecRemovePlayer(ind);
	if NET.Type_=NT_SERVER then
   	net_server.removeplayer_send(Player[ind].UID);
	Player[ind].Free;
   for i := ind to pl_count - 2 do
 		Player[i] := Player[i + 1];
	SetLength(Player, pl_count - 1)
end;

function TTFKPlayerMap.Getpl_current: TPlayer;
begin
   if (pl_cur_index>=0) and (pl_cur_index<pl_count) then
      Result:=Player[pl_cur_index]
   else Result:=nil;
end;

procedure TTFKPlayerMap.pl_respawn(pl: TPlayer);
var
   i: integer;
begin
   nextresp:=teamnextresp[pl.team];
   nextresp:=(nextresp+1) mod respcount;
   i:=nextresp;
   while (respawns[nextresp].team=3-pl.team) or
      (respawns[nextresp].resp_mode>1) do
   begin
      nextresp:=(nextresp+1) mod respcount;
      if i=nextresp then Exit;
   end;
   pl.resp:=true;
   pl.respindex:=nextresp;
   pl.lasthitid:=0;
   teamnextresp[pl.team]:=nextresp;
end;

procedure TTFKPlayerMap.pl_update;
begin
   if pl_find(-1, C_PLAYER_ACTIVE) then
   repeat
      if not pl_current.dead then
         pl_current.Update;
   until not pl_findnext(-1, C_PLAYER_ACTIVE);
   //теперь стрельба
   if pl_find(-1, C_PLAYER_ACTIVE) then
   repeat
      pl_current.UpdateShot;
   until not pl_findnext(-1, C_PLAYER_ACTIVE);
end;

procedure TTFKPlayerMap.pl_update_input;
begin
 	UpdateKeys;
   if pl_find(-1, C_PLAYER_LOCAL) then
   repeat
      pl_current.PrevUpdate;
   until not pl_findnext(-1, C_PLAYER_LOCAL);
end;

procedure TTFKPlayerMap.pl_update_kill;
begin
if pl_find(-1, C_PLAYER_ACTIVE) then
 repeat
  with pl_current do
   if (health <= 0) and not dead then
    Kill;
 until not pl_findnext(-1, C_PLAYER_ACTIVE);
end;

procedure TTFKPlayerMap.pl_update_respawn;
var
   i: integer;
begin
   if pl_find(-1, C_PLAYER_ACTIVE) then
   repeat
      with pl_current do
      if resp then
      begin
         if NET.Type_=NT_SERVER then
         begin
            pl_current.lasthitid:=hit_nextuid;
         	net_server.playerrespawn(pl_current);
         end;

      	Restart;
    		with respawns[respindex] do
         begin
            Activate(pl_current);
  				MoveTo(x*32+ObjRect.x-startrect.x, y*16+ObjRect.y-startrect.y);
            if resp_mode>0 then
            begin
               health:=resp_health;
               armor:=resp_armor;
               has_wpn:=resp_weapons;
               ammo:=resp_ammo;
               cur_weapon:=0;
               cur_wpn:=0;
               next_weapon:=0;
               for i:=1 to 8 do
               begin
                  if has_wpn[i]=1 then
                  begin
                     cur_weapon:=i;
                     cur_wpn:=i;
                     next_weapon:=i;
                  end;
               end;
            end else
               if Map.warmup then
               begin
                  if NET.Type_<>NT_CLIENT then
                     armor:=warmup_armor
                  else armor:=NET_Client.serv_info.warmuparmor;
                  for i:=2 to 8 do
                     if weaponobjs[i]<>nil then
                        TakeWpn(i, def_ammo[i], 1);
               end;
         end;
 			left := respawns[respindex].Struct.orient=0;
 			NeoMove;
 			respawns[respindex].Activate(pl_current);
 			RespawnSound.Play(Pos.X, Pos.Y);
      end;
   until not pl_findnext(-1, C_PLAYER_ACTIVE);
end;

function TTFKPlayerMap.PlayerByUID(uid: integer): TPlayer;
begin
   if (uid>=0) and (uid<=255) then
      Result:=pl_hash[uid]
      else Result:=nil;
end;

procedure TTFKPlayerMap.pl_stat_check_excellent(uid: integer);
begin
   if uid=-1 then Exit;
   if pl_find(uid, C_PLAYER_ACTIVE) then
      with pl_current do
   begin
 		if lastfrag<=125 then
     	begin
        	Stat_Excellent(uid);
         Excellent_snd.Play(Pos.X, Pos.Y);
      pl_current.rewards_ticker[1] := REWARDS_TIME;
     	end;
     	lastfrag:=0;
   end;
end;

function TTFKPlayerMap.pl_count_ptype(ptype: integer): integer;
begin
   Result:=0;
   if pl_find(-1, ptype) then
   repeat
      Inc(Result);
   until not pl_findnext(-1, ptype);
end;

function TTFKPlayerMap.TracePlayers(x, y, angle: single; var s: single; ownerUID: integer): TPlayer;
var
   i: integer;
begin
   Result:=nil;
 	for i:=0 to Players-1 do
      if (Player[i].uid<>ownerUID) and (not Player[i].dead) and
         RectVectorIntersect(Player[i].fRect, x, y, angle, s) then
            Result:=Player[i];
end;

function TTFKPlayerMap.gen_uid: byte;
var
   i: byte;
begin
   Result:=0;
   for i:=1 to 31 do
      if PlayerByUID(i)=nil then
      begin
         Result:=i;
         Exit;
      end;
end;

procedure TTFKPlayerMap.pl_update_physic;
begin
 	UpdateKeys;
   if pl_find(-1, C_PLAYER_ALL) then
   repeat
      pl_current.UpdateMove;
   until not pl_findnext(-1, C_PLAYER_ALL);
end;

function TTFKPlayerMap.TeamAuto: byte;
begin
   Result:=TEAM_BLUE;
end;

function TTFKPlayerMap.pl_index(pl: TPlayer): integer;
var
   i:integer;
begin
   Result:=-1;
   for i:=0 to pl_count-1 do
      if player[i]=pl then
      begin
         Result:=i;
         Exit;
      end;
end;

end.
