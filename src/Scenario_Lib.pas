unit Scenario_lib;

interface

//СЦЕНАРИЙ ПЕРЕДВИЖЕНИЯ ИГРОКА

uses MyEntries, Constants_Lib, Demo_Lib;


type
   TTFKScenario =
   class(TCustomTFKDemo)
      constructor Create(Head_: TEntryHead; var F: File);overload;
      constructor Create;overload;
   protected
      cp: integer;//индекс подконтрольного плэйера
      mainpl: TObject;
   public
      class function EntryClassName: TEntryClassName;
      class function IsValidVersion(version: integer): boolean;

      procedure Stop;
      procedure Restart;
      procedure Update;
      //ЗАПИСЬ
function RecStart: boolean;
procedure RecUpdate;
procedure RecStop;
      //ЧТЕНИЕ
function PlayStart: boolean;
procedure PlayUpdate;
procedure PlayStop;

procedure ReadPlayers;
   end;

implementation

uses Engine_Reg, Math_Lib, MapObj_Lib, Real_Lib, Player_Lib, Game_Lib, Map_Lib, HUD_Lib, Stat_Lib,
Binds_Lib, SysUtils, Log_Lib;

{ TTFKScenario }

constructor TTFKScenario.Create;
begin
   inherited;
   fhead.EntryClass:=Self.EntryClassName;
   fhead.version:=SCENARIO_VERSION;
end;

constructor TTFKScenario.Create(Head_: TEntryHead; var F: File);
begin
   inherited;
end;

class function TTFKScenario.EntryClassName: TEntryClassName;
begin
   Result:='ScenarioV1';
end;

class function TTFKScenario.IsValidVersion(version: integer): boolean;
begin
   Result:=version=SCENARIO_VERSION;
end;

function TTFKScenario.PlayStart: boolean;
begin
   Result:=true;
   playing:=true;
   stopped:=false;
   with Map do
   begin
      StartRead;
      stopped:=false;
      ReadBuf(startrec, sizeof(startrec));
      //пишем заголовок
      ReadPlayers;
      PlayUpdate;
   end;
end;

procedure TTFKScenario.PlayStop;
var
   i: integer;
begin
   cp:=-1;
	for i:=0 to map.players-1 do
   	if Map.player[i]=mainpl then
 	begin
      cp:=i; Break;
 	end;
   if cp>=0 then
      while Map.Players>cp do
      begin
 	 	   Log_RemovePlayer(Map.Player[cp]);
 		 	Map.Demo.RecRemovePlayer(cp);
         Map.pl_delete_index(cp);
      end;
   stopped:=true;
end;

procedure TTFKScenario.PlayUpdate;
var
   i: integer;
   rectype, recbyte: byte;
   recword: word;
   recfloat1, recfloat2: single;
   ps: TPlayerStruct;
   pl: TPlayer;
   st: str32;
   str: string;

begin
   with Map do
   repeat
      cp:=-1;
   	for i:=0 to map.players-1 do
      	if player[i]=mainpl then
   	begin
         cp:=i; Break;
   	end;
      if cp=-1 then
      begin
      	PlayStop;
         Exit;
      end;
      //проверка наличия системной информации
      ReadBuf(rectype, 1);
      if rectype and D_SYSTEMINFO>0 then
      begin
         if rectype and DS_END>0 then
         begin
            PlayStop;
            Exit;
         end;
         if rectype and DS_RESPAWN>0 then
         begin
     			ReadBuf(recbyte, 1);
            Player[cp+recbyte].resp:=true;
            ReadBuf(Player[cp+recbyte].respindex, 2);
      	end;
         if rectype and DS_ADD>0 then
         begin
            ReadBuf(ps, sizeof(ps));
            pl := Map.pl_add(C_PLAYER_DEMO, ps.Name, ps.ModelName);
            Log_AddPlayer(pl);
      	end;
         if rectype and DS_REMOVE>0 then
         begin
            ReadBuf(recbyte, 1);
 	 			Log_RemovePlayer(Map.Player[cp+recbyte]);
 		 		Map.Demo.RecRemovePlayer(cp+recbyte);
            Map.pl_delete_index(cp+recbyte);
      	end;
         if rectype and DS_EXTENSION>0 then
         begin
            ReadBuf(rectype, 1);
            if rectype = DE_NAME then
            begin
               ReadBuf(i, 4);
               ReadBuf(st, sizeof(st));
               Map.SetPlayerName(cp+i, st);
            end else
            if rectype = DE_MODEL then
            begin
               ReadBuf(i, 4);
               ReadBuf(st, sizeof(st));
               Map.SetPlayerModel(cp+i, st);
            end else
            if rectype = DE_SAY then
            begin
               ReadBuf(i, 4);
               ReadBuf(recword, 2);
               SetLength(str, recword);
               ReadBuf(str[1], recword);
               Map.Say(cp+i, str);
            end;
      	end;
      end else
      if rectype<>0 then
      begin
   		for i:=cp to Map.Players-1 do
   		begin
         	if rectype and DP_KEYSANGLE>0 then
         	begin
               Readbuf(recword, 2);
            	Player[i].SetAngle((recword and 511) /2);
               Player[i].Keys:=TKeySet(byte(recword shr 9));
         	end else

         	if rectype and DP_KEYS>0 then
         	begin
               Readbuf(recbyte, 1);
               Player[i].Keys:=TKeySet(recbyte);
         	end;

         	if rectype and DP_WEAPON>0 then
         	begin
            	ReadBuf(recbyte, 1);
               Player[i].next_weapon:=recbyte;
         	end;

          	if rectype and DP_POS>0 then
        	 	begin
            	ReadBuf(recfloat1, sizeof(recfloat1));
            	ReadBuf(recfloat2, sizeof(recfloat2));
               {$IFDEF DEBUG}
               if Signf(Player[i].pos.x-recfloat1)<>0 then
                  Log('Player['+IntToStr(i)+']  async X: '+
                  	FloatToStrF(Player[i].pos.x-recfloat1, ffGeneral, 5, 3)
                     	);
               if Signf(Player[i].pos.y-recfloat2)<>0 then
                  Log('Player['+IntToStr(i)+']  async Y: '+
                  	FloatToStrF(Player[i].pos.y-recfloat2, ffGeneral, 5, 3)
                     	);
               {$ENDIF}
            	Player[i].Pos:=Point2f(recfloat1, recfloat2);
         	end;
         	if rectype and DP_HEALTH>0 then
         	begin
                // XProger: ГДЕ-ТО ЗДЕСЬ ХРЕНЬ!!! Из-за которой фраги не начисляются!

            	ReadBuf(recbyte, 1);
               {$IFDEF DEBUG}
               if player[i].health<>recbyte then
                  Log('demo async: Health');
               {$ENDIF}
               if player[i].health<>recbyte then
                  Log('async Player Health: must be '+IntToStr(recbyte)+' but it is '+IntToStr(player[i].health));
               Player[i].health := recbyte;
               if (recbyte = 0) and (not player[i].dead) then
               begin
{                  if player[i].health>0 then
                     STAT_Frag(player[i].last_hit_UID);}
                   //АСИНХРОН!!!
                  player[i].Kill;
               end;
              	ReadBuf(recbyte, 1);
               {$IFDEF DEBUG}
               if player[i].armor<>recbyte then
                  Log('async Player Armor: must be '+IntToStr(recbyte)+' but it is '+IntToStr(player[i].Armor));
               {$ENDIF}
               Player[i].armor:=recbyte;
                end;
      	end; //players
      end; // checking D_SYSTEMINFO
      //УСЁ :))
   until rectype and D_SYSTEMINFO=0;
end;

procedure TTFKScenario.ReadPlayers;
var
  i: integer;
  struct: TPlayerStruct;
begin
   cp:=Map.players;
   with Map do
    for i:=cp to cp+startrec.pcount-1 do
      begin
         ReadBuf(struct, sizeof(struct));
       	pl_add(C_PLAYER_DEMO, struct);
 		 	Demo.RecAddPlayer(i);
         Log_AddPlayer(player[i]);
      end;
	mainpl:=Map.player[cp];
end;

function TTFKScenario.RecStart: boolean;
begin
   Result:=true;
   def_ptype:=C_PLAYER_NOTDEMO;
   if playing or Map.stopped then
   begin
      Result:=false;
   	Exit;
   end else Log('^2Scenario record started');
   with Map do
   begin
      StartWrite;
      startrec.starttime:=0;
      startrec.statcount:=0;
      startrec.pcount:=Map.pl_count_ptype(C_PLAYER_LOCAL);
      startrec.randseed:=RandSeed;
      WriteBuf(startrec, sizeof(startrec));
      //пишем заголовок
      RecPlayers;
      //запись первого игрока.
      RecUpdate;
      recording:=true;
   end;
end;

procedure TTFKScenario.RecStop;
var
   rectype: byte;

begin
   if not recording then Exit;

   with Map do
   begin
      rectype:=DS_END+D_SYSTEMINFO;
   	WriteBuf(rectype, 1);
   	EndWrite;
     	Log('^2scenario record stopped');
      AppendSectionToFile(Self, Map.lastfilename, Map.lastfilename, true);
     	recording:=false;
   end;
end;

procedure TTFKScenario.RecUpdate;
var
   rectype, recbyte: byte;
   recword: word;
   recfloat: single;
begin
   with Map do
   begin
      if pl_find(-1, def_ptype) then
     	repeat
      	with pl_current do
         if resp then
      	begin
         	rectype:=D_SYSTEMINFO+DS_RESPAWN;
     			WriteBuf(rectype, 1);
         	recbyte:=pl_cur_ind;
         	WriteBuf(recbyte, 1);
         	WriteBuf(respindex, 2);
      	end;
   	until not pl_findnext(-1, def_ptype);
//теперь передвижения игроков
     	rectype:=0;
      if pl_find(-1, def_ptype) then
   		repeat
      		with pl_current do
            begin
           		if Moved then rectype:=rectype or DP_POS;                //?
          		if WPNChanged then rectype:=rectype or DP_WEAPON;        //**
           		if AngleChanged then rectype:=rectype or DP_KEYSANGLE;   //tested, bug fixed
           		if KeysChanged then rectype:=rectype or DP_KEYS;         //tested, bug fixed
            end;
   		until not pl_findnext(-1, def_ptype);

      if rectype and DP_KEYSANGLE>0 then
         rectype:=rectype and not DP_KEYS;
      {$IFDEF DEBUG}
      rectype:=rectype or DP_POS;
      {$ENDIF}

      WriteBuf(rectype, 1);

      if pl_find(-1, def_ptype) then
      	with Pl_current do
   	repeat
         if rectype and DP_KEYSANGLE>0 then
         begin
            recword:=word(fAngle)+byte(Keys) shl 9;
            WriteBuf(recword, 2);
         end else
         if rectype and DP_KEYS>0 then
         begin
            recbyte:=byte(Keys);
            WriteBuf(recbyte, 1);
         end;
         if rectype and DP_WEAPON>0 then
         begin
            recbyte:=next_weapon;
            WriteBuf(recbyte, 1);
         end;
         if rectype and DP_POS>0 then
         begin
            recfloat:=Pos.X;
            WriteBuf(recfloat, sizeof(recfloat));
            recfloat:=Pos.Y;
            WriteBuf(recfloat, sizeof(recfloat));
         end;
 		until not pl_findnext(-1, def_ptype);
   end;
end;

procedure TTFKScenario.Restart;
begin
	if recording then
 		RecStop;
   if playing then
   begin
 		PlayStop;
      playing:=false;
   end;
end;

procedure TTFKScenario.Stop;
begin
   if recording then RecStop;
   if playing and not stopped then PlayStop;
end;

procedure TTFKScenario.Update;
begin
   if recording then
   begin
      if Map.Players>0 then
   		RecUpdate
         else RecStop;
   end;
   if playing and not stopped then
      PlayUpdate;
end;


end.
