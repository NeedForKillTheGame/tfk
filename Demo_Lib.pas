unit demo_lib;

//Neoff Manifest
//Вот и не думал что мне хватит на это времени. Сейчас 17.08.04, наши выиграли на олимпиаде
//вторую золотую медаль по стрельбе

(***************************************)
(*  TFK Demo library  version 1.0.3.6  *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff777СОБАКАrambler.net   *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

{$DEFINE DEBUG}

interface

uses MyEntries, Constants_Lib, Type_Lib;

const
   D_SYSTEMINFO = 128;
//demo system info section
   DS_END = 1;       //or restart
   DS_ADD = 2;
   DS_REMOVE = 4;
   DS_TEAM = 8;
   DS_EXTENSION = 16;//РАСШИРЕНИЕ
   DS_OBJ = 32;//обновление какого-то объекта
   DS_RESPAWN = 64;
//demo system info section - 2
   DS_TIME = 1;
   DS_SHOT = 2;
   DS_PLAYERS = 4;
//EXTENSION
   DE_NAME = 1;
   DE_MODEL = 2;
   DE_SAY = 4;
   DE_HIT = 8;
   DE_ACTIVATE = 16;
   DE_OBJCREATE = 32;
   DE_OBJKILL = 64;
   DE_TEAM = 128; //каждое событие может быть коммандным.
//demo player info section
   DP_POS = 1;
   DP_ANGLE = 2;
   DP_KEYSANGLE = 4;
   DP_WEAPON = 8;
   DP_KEYS = 16;
   DP_HEALTH = 64;

   DEMO_VERSION = 2;
   SCENARIO_VERSION = 1;

type
   TDemoRecType =
   	(rtDemoStart, rtDemoEnd, rtDemoTime,
       rtGameProps,
       rtPlayerProps,
       rtPlayerStruct,
       rtPlayerMove,
       rtMapObj,
       rtRealObj,
       rtStat);

   TDemoStartRec =
   record
      starttime: cardinal;
      pcount: word;//количество игроков
      statcount: word;
      randseed: longint;
      warmup: boolean;
      phys: boolean;
      reserved: array [1..7] of word;
   end;

type

   TDemoEndRec =
   record
      restart: boolean;
      reserved: array [1..7] of word;
   end;

   TDemoEntry =
   class(TSimpleEntry)
      constructor Create(Head_: TEntryHead; var F: File);overload;
      constructor Create;overload;
   public
      position, err: cardinal;
      demotime: cardinal;

      procedure WriteToFile(var F: File);override;
      procedure StartWrite;
      procedure EndWrite;

   protected
      procedure WriteBuf(var buf_; size: cardinal);

      procedure StartRead;
      procedure ReadBuf(var X; size: cardinal);

      procedure Seek(dpos: cardinal);
   end;

   TCustomTFKDemo =
   class(TDemoEntry)
   protected
  	 	startrec: TDemoStartRec;
      fautorec: boolean;
   public
      demofilename: string;
      recording, playing, stopped: boolean;
      def_ptype: integer;

		procedure RecAddPlayer(i: integer);
		procedure RecRemovePlayer(i: integer);
		procedure RecName(UID: integer; newname: str32);
		procedure RecModel(UID: integer; newmodel: str32);
		procedure RecSay(UID: integer; saystr: string);
      procedure RecHit(hit: THit);
      procedure RecActivate(objid: word; uid: byte);
		procedure RecTeam(UID, team: byte);
      procedure RecReady;
      procedure RecTime;

      procedure RecShotObjCreate(robj : TObject);
      procedure RecShotObjKill(uid, x, y: word);
      procedure RecShot(uid, weapon: byte; x, y, angle: word);

		procedure RecItems;
      procedure RecHead;
		procedure RecRealObjs;
		procedure RecStat;
		procedure RecGameProps;
		procedure RecPlayers;virtual;

		procedure ReadGameProps;
		procedure ReadItems;
		procedure ReadRealObjs;
		procedure ReadStat;
      procedure ReadHead;
   end;

   TSaveGame =
   class(TCustomTFKDemo)
   public
		procedure RecPlayers;override;
      procedure SaveAll;
      procedure LoadAll;

      procedure RecSpec;
      procedure ReadSpec;
   end;

   TTFKDemo =
   class(TCustomTFKDemo)
private
   afterwarmup: boolean;
public
    restarting: boolean;
    constructor Create(Head_: TEntryHead; var F: File);overload;
    constructor Create;overload;

    class function EntryClassName: TEntryClassName;
    class function IsValidVersion(version: integer): boolean;

    procedure Stop;
    procedure Restart;
    procedure Update;

    function RecStart(autorec: boolean = false): boolean;
    procedure RecUpdate;
    procedure RecStop;

    function PlayStart: boolean;
    procedure PlayUpdate;
    procedure PlayStop;

procedure ReadPlayers;

procedure Go(nexttime: cardinal);
procedure Skip(nexttime: cardinal);
   end;


implementation

uses Engine_Reg, Math_Lib, MapObj_Lib, Real_Lib, Player_Lib, Game_Lib, Map_Lib, HUD_Lib, Stat_Lib,
Binds_Lib, SysUtils, Log_Lib, Weapon_Lib, Phys_Lib;

const
//   BUF_PAGE = 1024;
   BUF_PAGE = 65536;

//**************************************

{ TDemoEntry }

constructor TDemoEntry.Create;
begin
  inherited;
   fhead.size:=buf_page;
   resizebuf(buf_page);
   fhead.EntryClass:=Self.EntryClassName;
   fhead.version:=DEMO_VERSION;
end;

constructor TDemoEntry.Create(Head_: TEntryHead; var F: File);
var
   a: byte;
begin
   inherited;
   a:=buf[0];
   buf[0]:=a;
end;

procedure TDemoEntry.EndWrite;
begin
   resizebuf(position);
end;

procedure TDemoEntry.WriteToFile(var F: File);
begin
   inherited;
end;

procedure TDemoEntry.ReadBuf(var X; size: cardinal);
begin
   if (position+size>fhead.size) then
   begin
      err:=1;
   	Exit;
   end;
   Move(buf[position], X, size);
   Inc(position, size);
end;

procedure TDemoEntry.StartRead;
begin
   err:=0;
   position:=0;
end;

procedure TDemoEntry.StartWrite;
begin
   position:=0;
end;

procedure TDemoEntry.Seek(dpos: cardinal);
begin
   position:=position+dpos;
end;

procedure TDemoEntry.WriteBuf(var buf_; size: cardinal);
begin
   while size+position>fhead.size do
      resizebuf(fhead.size+BUF_PAGE);
   Move(buf_, buf[position], Size);
   inc(position, size);
end;

{ TCustomTFKDemo }

procedure TCustomTFKDemo.ReadRealObjs;
var
   i, c: integer;
   struct: TRealObjStruct;
begin
   ReadBuf(c, 4);
   for i:=0 to c-1 do
   begin
      ReadBuf(struct, SizeOf(struct));
      RealObj_Add(struct);
   end;
end;

procedure TCustomTFKDemo.ReadGameProps;
var
   gp : TGameProps;
begin
   ReadBuf(gp, sizeOf(TGameProps));
end;

procedure TCustomTFKDemo.ReadHead;
var
   c, size: word;
   buf: array of byte;
begin
      ReadBuf(startrec, sizeof(startrec));
      if startrec.phys then
      begin
         ReadBuf(c, 2);
         ReadBuf(size, 2);
         SetLength(buf, size);
         ReadBuf(buf[0], size);
         if (phys_getbufsize=size) and
            (phys_getvarscount=c)  then
            phys_readbuf(buf, size);
         buf:=nil;
      end;
end;

procedure TCustomTFKDemo.ReadStat;
var
   i: integer;
   stat: TPlayerStat;
begin
   for i:=0 to startrec.statcount-1 do
   begin
      ReadBuf(stat, sizeof(stat));
      Stat_Set(stat.UID, stat);
   end;
end;

//Запись демок

procedure TCustomTFKDemo.RecGameProps;
begin
   //пока что только sv_gravity
   WriteBuf(Map.gp, sizeOf(TGameProps));
end;

procedure TCustomTFKDemo.RecItems;
var
   rec: TDemoObjRec;
   i, j: integer;
begin
   with Map do
   begin
      j:=0;
   	for i:=0 to Obj.Count-1 do
      	if Obj[i].SaveToRec(rec) then
            Inc(j);
   	WriteBuf(j, 4);
   	for i:=0 to Obj.Count-1 do
      if Obj[i].SaveToRec(rec) then
      begin
         rec.reserved[7]:=i;
         WriteBuf(rec, sizeof(rec));
      end;
   end;
end;

procedure TCustomTFKDemo.RecPlayers;
var
   struct: TPlayerStruct;
   tb: byte;
   i: integer;
begin
   if not recording or stopped then Exit;
   tb:=D_SYSTEMINFO;
   WriteBuf(tb, 1);
   tb:=DS_PLAYERS;
   WriteBuf(tb, 1);
   tb:=Map.pl_count;
   WriteBuf(tb, 1);
   with Map do
   for i:=0 to tb-1 do
   begin
    	struct:=Map.player[i].pstruct;
    	WriteBuf(struct, SizeOf(struct));
   end;
end;

procedure TCustomTFKDemo.RecRealObjs;
var
 j      : integer;
 struct : TRealObjStruct;
 n      : TRealObj;
begin
j := 0;
n := RealObj;
while n <> nil do
 begin
 if n.Struct.objtype <> otSprite then
  inc(j);
 n := n.Next;
 end;

//записываем количество объектов
WriteBuf(j, 4);
n := RealObj;
while n <> nil do
 begin
 if n.Struct.objtype <> otSprite then
  begin
  struct := n.struct;
  WriteBuf(struct, SizeOf(struct));
  end;
 n := n.Next;
 end;
end;

procedure TCustomTFKDemo.ReadItems;
var
   rec: TDemoObjRec;
   i, j: integer;
begin
   ReadBuf(j, 4);
   with Map do
   	for i:=1 to j do
      begin
         ReadBuf(rec, sizeof(rec));
         if rec.reserved[7]<Obj.Count then
            Obj[rec.reserved[7]].LoadFromRec(rec);
      end;
end;

procedure TCustomTFKDemo.RecStat;
var
   i: integer;
   stat: TPlayerStat;
begin
   for i:=0 to startrec.statcount-1 do
   begin
      stat:=Stat_GetStat(i)^;
      WriteBuf(stat, sizeof(TPlayerStat));
   end;
end;

procedure TCustomTFKDemo.RecAddPlayer(i: integer);
var
   rectype: byte;
   ps: TPlayerStruct;
begin
   if not recording or stopped then Exit;
   rectype:=D_SYSTEMINFO+DS_ADD;
   WriteBuf(rectype, 1);
   ps:=Map.player[i].pstruct;
   WriteBuf(ps, sizeof(ps));
end;

procedure TCustomTFKDemo.RecRemovePlayer(i: integer);
var
   rectype, rt: byte;
begin
   if not recording or stopped then Exit;
   rectype:=D_SYSTEMINFO+DS_REMOVE;
   rt:=i;
   WriteBuf(rectype, 1);
   WriteBuf(rt, 1);
end;

procedure TCustomTFKDemo.RecModel(UID: integer; newmodel: str32);
var
   rt1, rt2: byte;
begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_EXTENSION;
   rt2:=DE_MODEL;
   WriteBuf(rt1, 1);
   WriteBuf(rt2, 1);
   WriteBuf(uid, 4);
   WriteBuf(newmodel, sizeof(str32));
end;

procedure TCustomTFKDemo.RecName(UID: integer; newname: str32);
var
   rt1, rt2: byte;
begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_EXTENSION;
   rt2:=DE_NAME;
   WriteBuf(rt1, 1);
   WriteBuf(rt2, 1);
   WriteBuf(uid, 4);
   WriteBuf(newname, sizeof(str32));
end;

procedure TCustomTFKDemo.RecSay(UID: integer; saystr: string);
var
   rt1, rt2: byte;
   rw: word;

begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_EXTENSION;
   rt2:=DE_SAY;
   WriteBuf(rt1, 1);
   WriteBuf(rt2, 1);
   WriteBuf(UID, 4);
   rw:=length(saystr);
   WriteBuf(rw, 2);
   WriteBuf(saystr[1], rw);
end;

procedure TCustomTFKDemo.RecHit(hit: THit);
var
   rt1, rt2: byte;
begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_EXTENSION;
   rt2:=DE_HIT;
   WriteBuf(rt1, 1);
   WriteBuf(rt2, 1);
   WriteBuf(hit, sizeof(hit));
end;

procedure TCustomTFKDemo.RecActivate(objid: word; uid: byte);
var
   rt1, rt2: byte;
begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_EXTENSION;
   rt2:=DE_ACTIVATE;
   WriteBuf(rt1, 1);
   WriteBuf(rt2, 1);
   WriteBuf(objid, 2);
   WriteBuf(uid, 1);
end;

procedure TCustomTFKDemo.RecTeam(UID, team: byte);
var
   rt1: byte;
begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_TEAM;
   WriteBuf(rt1, 1);
   WriteBuf(uid, 1);
   WriteBuf(team, 1);
end;

procedure TCustomTFKDemo.RecReady;
var
   rt1: byte;
begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_END;
   writebuf(rt1, 1);
   rt1:=1; //continue!
   writebuf(rt1, 1);
end;

{ TTFKDemo }

//Проигрывание демок

function TTFKDemo.PlayStart: boolean;
var
   b: byte;
begin
   Result:=true;
   playing:=true;
   stopped:=false;
   with Map do
   begin
      StartRead;
      stopped:=false;
      ReadHead;
      HUD_SetTime(startrec.starttime);
      randseed:=startrec.randseed;
      Map.warmup:=startrec.warmup;

      //пишем заголовок
      //и тут писался player;
      readbuf(b, 1);
      readbuf(b, 1);
      ReadPlayers;
      ReadItems;
      ReadRealObjs;
      ReadStat;
      ReadGameProps;
      PlayUpdate;
   end;
   Log('^2demo (re)started ^3:-)');
end;

procedure TTFKDemo.PlayStop;
begin
   stopped:=true;
   Map.StopGame;
end;

procedure TTFKDemo.PlayUpdate;
var
   i: integer;
   rectype, rectype2, recbyte, recbyte2: byte;
   c: cardinal;
   w, recword, recword2: word;
	objrec: TDemoObjRec;
   ps: TPlayerStruct;
   pl: TPlayer;
   st: str32;
   str: string;
   H: THit;
   s: TRealObjStruct;
   ss: single;
   ro: TRealObj;

begin
   with Map do
   repeat
      //проверка наличия системной информации
      ReadBuf(rectype, 1);
      if rectype and D_SYSTEMINFO>0 then
      begin
         if rectype and DS_END>0 then
         begin
            Readbuf(rectype, 1);
            if rectype=0 then
               PlayStop
            else Map.Ready;
            Exit;
         end;
         if rectype and DS_RESPAWN>0 then
         begin
     			ReadBuf(recbyte, 1);
            Player[recbyte].resp:=true;
            ReadBuf(Player[recbyte].respindex, 2);
      	end;
         if rectype and DS_OBJ>0 then
         begin
     			ReadBuf(objrec, sizeOf(objrec));
         	if objrec.reserved[3]<Obj.Count then
            	Obj[objrec.reserved[3]].LoadFromRec(objrec);
      	end;
         if rectype and DS_ADD>0 then
         begin
            ReadBuf(ps, sizeof(ps));
            if Map.pl_find(ps.uid, C_PLAYER_DEMO) then
            begin
               pl:=pl_current;
               pl.pstruct:=ps;
               pl.dead:=false;
            end else
            begin
               pl := Map.pl_add(C_PLAYER_DEMO, ps);
               log_AddPlayer(pl);
            end;
      	end;
         if rectype and DS_REMOVE>0 then
         begin
            ReadBuf(recbyte, 1);
 	 			Log_RemovePlayer(Map.Player[recbyte]);
            Map.pl_delete_index(recbyte);
      	end;
         if rectype and DS_TEAM>0 then
         begin
            ReadBuf(recbyte, 1);
            ReadBuf(recbyte2, 1);
            Map.TeamJoin(recbyte, recbyte2);
      	end;
         if rectype=D_SYSTEMINFO then
         begin
            ReadBuf(rectype2, 1);
            if rectype2=DS_TIME then
            begin
               ReadBuf(c, 4);
               HUD_SetTime(c);
            end;
            if rectype2=DS_SHOT then
            begin
               ReadBuf(recbyte, 1);
               ReadBuf(recbyte2, 1);
               ReadBuf(recword, 2);
               ReadBuf(recword2, 2);
               ReadBuf(w, 2);
               if Map.pl_find(recbyte, C_PLAYER_DEMO) then
                  with Map.pl_current do
               begin
                  SetWeapon(recbyte2);
                  shotpos:=Point2f(recword, recword2);
                  AbsAngle:=w;
                  fshot:=true;
               end;
            end;
            if rectype2=DS_PLAYERS then
               ReadPlayers;
         end;

         if rectype and DS_EXTENSION>0 then
         begin
            ReadBuf(rectype2, 1);
            case rectype2 of
               DE_NAME:
            begin
               ReadBuf(i, 4);
               ReadBuf(st, sizeof(st));
               Map.SetPlayerName(i, st);
            end;
               DE_MODEL:
            begin
               ReadBuf(i, 4);
               ReadBuf(st, sizeof(st));
               Map.SetPlayerModel(i, st);
            end;
               DE_SAY:
            begin
               ReadBuf(i, 4);
               ReadBuf(recword, 2);
               SetLength(str, recword);
               ReadBuf(str[1], recword);
               Map.Say(i, str);
            end;
               DE_HIT:
            begin
               ReadBuf(H, sizeof(H));
               HitApply(H);
            end;
               DE_ACTIVATE:
            begin
               ReadBuf(recword, 2);
               ReadBuf(recbyte, 1);
               pl:=Map.PlayerByUID(recbyte);
      			if recword<Obj.count then
               begin
                  Obj[recword].Update;
         			Obj[recword].Activate(pl);
               end;
      			if recword>=20000 then
         			ActivateTarget(recword-20000, true);
            end;
               DE_OBJCREATE:
            begin
   	         fillchar(s, sizeof(s), 0);
               ReadBuf(s.uid, 2);
               ReadBuf(s.playerUID, 1);
               ReadBuf(s.itemid, 1);
               ReadBuf(w, 2);
               s.x:=w;
               ReadBuf(w, 2);
               s.y:=w;
               ReadBuf(w, 2);
               s.angle:=w;
               s.angle:=s.angle*Pi/180;
               ss:=WPN_SPEED[s.ItemID];
               s.dx:=ss*cos(s.angle);
               s.dy:=ss*sin(s.angle);
               s.objtype:=otShot;
               RealObj_Add(s);
      	   end;
               DE_OBJKILL:
            begin
            ReadBuf(w, 2);
            ro:=RealObj_Find(w);
            ReadBuf(w, 2);
            ReadBuf(recword, 2);
            if (ro<>nil) then
            begin
               ro.x:=w;
               ro.y:=recword;
               ro.Kill;
            end;
            end;

            end;//case
         end;
      end else
      if rectype<>0 then
      begin
   		for i:=0 to Players-1 do
   		begin
         	if rectype and DP_KEYSANGLE>0 then
         	begin
               Readbuf(recword, 2);
            	Player[i].SetAbsAngle(recword and 511);
               Player[i].Keys:=TKeySet(byte(recword shr 9));
         	end else
         	if rectype and DP_KEYS>0 then
         	begin
               Readbuf(recbyte, 1);
               Player[i].Keys:=TKeySet(recbyte and 127);
         	end;

         	if rectype and DP_WEAPON>0 then
         	begin
            	ReadBuf(recbyte, 1);
               Player[i].SetWeapon(recbyte);
         	end;

          	if rectype and DP_POS>0 then
        	 	begin
            	ReadBuf(recword, 2);
            	Player[i].word_pos_x:=recword;
            	ReadBuf(recword, 2);
            	Player[i].word_pos_y:=recword;
         	end;
      	end; //players
      end; // checking D_SYSTEMINFO
      //УСЁ :))
   until rectype and D_SYSTEMINFO=0;
end;

function TTFKDemo.RecStart(autorec: boolean): boolean;
begin
   Result:=true;
   fautorec:=autorec;
   if fautorec then
      demofilename:='AUTORECORD';
   def_ptype:=C_PLAYER_ALL;
   if playing or Map.stopped then
   begin
      Result:=false;
   	Exit;
   end else Log('^2demo record started');
   afterwarmup:=Map.warmup;
   with Map do
   begin
      recording:=true;
      StartWrite;
      RecHead;
      //пишем заголовок
      RecPlayers;
      RecItems;
      RecRealObjs;
      RecStat;
      RecGameProps;
      RecUpdate;
   end;
end;

procedure TTFKDemo.RecStop;
var
   rectype: byte;
   i, k: integer;
   s: string;
   mh: TMapHeader1;

begin
if not recording then Exit;
with Map do
 begin
 rectype := DS_END + D_SYSTEMINFO;
 WriteBuf(rectype, 1);
 rectype := 0; //no continue;
 WriteBuf(rectype, 1);
 EndWrite;
 Log('^2demo record stopped');
 CreateDir(Engine_ModDir + 'demos');
 if fautorec then
  begin
  s := '';
  for i := 0 to Players - 1 do
   s := s + player[i].Name + '_';
  if Players < 4 then
   s := s + '(' + Map.GetFileName + ')_';
  s := s + DateToStr(Date) + '-' +
           IntToStr(HUD_GetTimeMin) + '_' +
           IntToStr(HUD_GetTimeSec) + '_' +
           IntToStr(HUD_GetTimeMS mod 50 * 20);
  k := 1;
  while k <= Length(s) do
   if s[k] in ['\', '/', '|', ':', '*', '?', '<', '>'] then
    System.Delete(s, k, 1)
   else
    if s[k] = '^' then
     System.Delete(s, k, 2)
    else
     inc(k);
  demofilename := Engine_ModDir + 'demos\' + s + '.tdm';
  end;

 if AppendSectionToFile(Self, Map.lastfilename, demofilename) >= 0 then
  begin
   DeleteSectionFromFile('LightMapV1', demofilename, demofilename);
   DeleteSectionFromFile('ScenarioV1', demofilename, demofilename);
   mh:=Map.head;
   mh.gametype:=gametype;
   RewriteMapHeader(mh, demofilename, demofilename);
  end;
//      Map.SaveToFile(demofilename);//сохранение temp-демки
 Log('^2Demo has been saved to ^7"' + demofilename + '"');
 recording := false;
 end;
end;

procedure TTFKDemo.RecUpdate;
var
   i: integer;
   rectype, recbyte: byte;
   recword: word;
   objrec: TDemoObjRec;

begin
   with Map do
   begin
      for i:=0 to Obj.Count-1 do
      with Obj[i] do
         if updated and SaveToRec(objrec) then
      begin
         rectype:=D_SYSTEMINFO+DS_OBJ;
     		WriteBuf(rectype, 1);
         WriteBuf(objrec, sizeof(objrec));
      end;
      for i:=0 to Players-1 do
      with Player[i] do
         if resp then
      begin
         rectype:=D_SYSTEMINFO+DS_RESPAWN;
     		WriteBuf(rectype, 1);
         recbyte:=i;
         WriteBuf(recbyte, 1);
         WriteBuf(respindex, 2);
      end;
//теперь передвижения игроков
      rectype:=0;
      for i:=0 to Players-1 do
         with Player[i] do
         begin
            if Moved then rectype:=rectype or DP_POS;                //?
            if WPNChanged then rectype:=rectype or DP_WEAPON;        //**
            if AngleChanged then rectype:=rectype or DP_KEYSANGLE;   //tested, bug fixed
            if KeysChanged then rectype:=rectype or DP_KEYS;         //tested, bug fixed
         end;
      if rectype and DP_KEYSANGLE>0 then
         rectype:=rectype and not DP_KEYS;
      {$IFDEF DEBUG}
      rectype:=rectype or DP_POS;
      {$ENDIF}

      WriteBuf(rectype, 1);

      if rectype<>0 then
   	for i:=0 to Players-1 do
   	begin
         if rectype and DP_KEYSANGLE>0 then
         begin
            recword:=word(Player[i].fAngle)+byte(Player[i].Keys) shl 9;
            WriteBuf(recword, 2);
         end else
         if rectype and DP_KEYS>0 then
         begin
            recbyte:=byte(Player[i].Keys);
            if Player[i].balloon then
               recbyte:=recbyte+128;
            WriteBuf(recbyte, 1);
         end;
         if rectype and DP_WEAPON>0 then
         begin
            recbyte:=Player[i].next_weapon;
            WriteBuf(recbyte, 1);
         end;
         if rectype and DP_POS>0 then
         begin
            recword:=Player[i].word_pos_x;
            WriteBuf(recword, 2);
            recword:=Player[i].word_pos_y;
            WriteBuf(recword, 2);
         end;
      end;
      //УСЁ :))
   end;
end;

procedure TTFKDemo.Restart;
begin
if recording then
   RecStop;
if playing then
   PlayStart;
end;

procedure TTFKDemo.Stop;
begin
   if recording then
      RecStop;
   if playing and not stopped then PlayStop;
end;

procedure TTFKDemo.Update;
begin
   if recording then
   	RecUpdate;
   if playing and not stopped then
      PlayUpdate;
end;

procedure TTFKDemo.ReadPlayers;
var
  i: integer;
  struct: TPlayerStruct;
  c: byte;
begin
   Log_ConWrite(false);
   readbuf(c, 1);
   Map.pl_clear;
   with Map do
    for i:=0 to c-1 do
      begin
         ReadBuf(struct, sizeof(struct));
         if Map.pl_find(struct.UID, C_PLAYER_DEMO) then
            Map.pl_current.pstruct:=struct
         else
            pl_add(C_PLAYER_DEMO, struct, false);
      end;
   Log_ConWrite(true);
end;

procedure TTFKDemo.Go(nexttime: cardinal);
begin
if playing then
 with Map do
  begin
  Inc(sound_off);
  Log_ConWrite(false);
  if HUD_GetTime > nexttime then
   Restart;
  Log_ConWrite(true);
  while (HUD_GetTime < nexttime) and not Map.stopped do
   begin
   started := false;
   Map.Update;
   HUD_SetTime(HUD_GetTime + 1);
   end;
  Dec(sound_off);
  end;
end;

procedure TTFKDemo.Skip(nexttime: cardinal);
var
   i: integer;
begin
   if playing and not Map.Stopped then
   with Map do
   begin
   	Inc(sound_off);
   	for i:=1 to nexttime do
      begin
         started:=false;
         Map.Update;
         HUD_SetTime(HUD_GetTime+1);
         if Map.stopped then break;
      end;
      Dec(sound_off);
   end;
end;

class function TTFKDemo.EntryClassName: TEntryClassName;
begin
   Result:='DemoEntryV1';
end;

class function TTFKDemo.IsValidVersion(version: integer): boolean;
begin
   Result:=version=DEMO_VERSION;
end;

constructor TTFKDemo.Create(Head_: TEntryHead; var F: File);
begin
   inherited;
end;

constructor TTFKDemo.Create;
begin
   inherited;
   fhead.EntryClass:=Self.EntryClassName;
   fhead.version:=DEMO_VERSION;
end;


procedure TCustomTFKDemo.RecShotObjCreate(robj: TObject);
var
   rt1, rt2: byte;
var
   x, y: integer;
   x0, y0, ang: word;
   s: TRealObjStruct;
begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_EXTENSION;
   rt2:=DE_OBJCREATE;
   WriteBuf(rt1, 1);
   WriteBuf(rt2, 1);

   s:=TRealObj(robj).struct;
   WriteBuf(s.uid, 2);
   WriteBuf(s.playerUID, 1);
   WriteBuf(s.itemid, 1);

   x:=round(s.x);
   if x<0 then x:=0;
   x0:=x;
   y:=round(s.y);
   if y<0 then y:=0;
   y0:=y;
   ang:=round(s.angle*180/Pi);

   WriteBuf(x0, 2);
   WriteBuf(y0, 2);
   WriteBuf(ang, 2);
end;


procedure TCustomTFKDemo.RecShotObjKill(uid, x, y: word);
var
   rt1, rt2: byte;
begin
   if not recording or stopped then Exit;
   rt1:=D_SYSTEMINFO+DS_EXTENSION;
   rt2:=DE_OBJKILL;
   WriteBuf(rt1, 1);
   WriteBuf(rt2, 1);
   WriteBuf(uid, 2);
   WriteBuf(x, 2);
   WriteBuf(y, 2);
end;

procedure TCustomTFKDemo.RecHead;
var
   buf: array of byte;
   size: word;
begin
   startrec.starttime:=HUD_GetTime;
   startrec.statcount:=Stat_GetStatCount;
   startrec.pcount:=Map.Players;
   startrec.randseed:=RandSeed;
   startrec.warmup:=Map.warmup;
   startrec.phys:=true;
   WriteBuf(startrec, sizeof(startrec));

   size:=phys_getvarscount;
   WriteBuf(size, 2);
   size:=phys_getbufsize;
   WriteBuf(size, 2);
   SetLength(buf, size);
   phys_writebuf(buf);
   WriteBuf(buf[0], size);
   buf:=nil;
end;

procedure TCustomTFKDemo.RecTime;
var
   rt: byte;
   l: cardinal;
begin
   if not recording or stopped then Exit;
   rt:=D_SYSTEMINFO;
   WriteBuf(rt, 1);
   rt:=DS_TIME;
   WriteBuf(rt, 1);
   l:=HUD_GetTime;
   WriteBuf(l, 4);
end;

procedure TCustomTFKDemo.RecShot(uid, weapon: byte; x, y, angle: word);
var
   rt: byte;
begin
   if not recording or stopped then Exit;
   rt:=D_SYSTEMINFO;
   WriteBuf(rt, 1);
   rt:=DS_SHOT;
   WriteBuf(rt, 1);
   WriteBuf(uid, 1);
   WriteBuf(weapon, 1);
   WriteBuf(x, 2);
   WriteBuf(y, 2);
   WriteBuf(angle, 2);
end;

{ TSaveGame }

procedure TSaveGame.LoadAll;
var
  b: byte;
  i: integer;
  types: array [0..100] of byte;
  struct: TPlayerStruct;
begin
   ReadHead;
   HUD_SetTime(startrec.starttime);
   randseed:=startrec.randseed;
   for i:=0 to startrec.pcount-1 do
      ReadBuf(types[i], 1);
   with Map do
   begin
      Log_ConWrite(false);
      pl_clear;
      for i:=0 to startrec.pcount-1 do
      begin
         ReadBuf(b, 1);
         ReadBuf(struct, sizeof(struct));
         pl_add(types[i], struct, false);
         player[i].dead_mode:=boolean(b);
      end;
      Log_ConWrite(true);
   end;
   ReadItems;
   ReadRealObjs;
   ReadStat;
   ReadGameProps;
   ReadSpec;
end;

procedure TSaveGame.ReadSpec;
var
   x, y: integer;
   ff: integer;
   fmode: boolean;
begin
   ReadBuf(x, 4);
   ReadBuf(y, 4);
   ReadBuf(ff, 4);
   ReadBuf(fmode, 1);
   Map.Camera.Pos.X:=x;
   Map.Camera.Pos.Y:=y;
   Map.fade_alpha:=ff/1000;
   Map.fade_out:=fmode;
end;

procedure TSaveGame.RecPlayers;
var
   struct: TPlayerStruct;
   b: byte;
begin
   with Map do
   if pl_find(-1, C_PLAYER_ALL) then
   repeat
      b:=Map.pl_current.playertype;
      WriteBuf(b, 1);
   until not pl_findnext(-1, C_PLAYER_ALL);

   with Map do
   if pl_find(-1, C_PLAYER_ALL) then
   repeat
      b:=byte(Map.pl_current.dead_mode);
      WriteBuf(b, 1);
    	struct:=Map.pl_current.pstruct;
    	WriteBuf(struct, SizeOf(struct));
   until not pl_findnext(-1, C_PLAYER_ALL);
end;

procedure TSaveGame.RecSpec;
var
   x, y: integer;
   mode: boolean;
begin
   x:=trunc(Map.Camera.Pos.X);
   y:=trunc(Map.Camera.Pos.Y);
   WriteBuf(x, 4);
   WriteBuf(y, 4);

   x:=round(Map.fade_alpha*1000);
   WriteBuf(x, 4);
   mode:=Map.fade_out;
   WriteBuf(mode, 1);
   x:=0;
   WriteBuf(x, 3);
   WriteBuf(x, 4);
end;

procedure TSaveGame.SaveAll;
begin
   StartWrite;
   RecHead;
   RecPlayers;
   RecItems;
   RecRealObjs;
   RecStat;
   RecGameProps;
   RecSpec;
   EndWrite;

   //сохраняем позицию камеры
end;

end.
