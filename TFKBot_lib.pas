unit TFKBot_lib;

interface

uses
 Engine_Reg,
 Func_Lib,
 Math_Lib,
 Type_Lib,
 MapObj_Lib,
 ItemObj_Lib,
 NFKBrick_Lib,
 PlayersUtils_Lib,
 Player_Lib;

const
  NO_BOT_FIRE = true;

type
 TTFKBot = class
   constructor Create;
  private
   timer, thinktime: integer;
   f_player : TPlayer;
  public
   //различные параметры угла прицеливания
   //прицеливание ведётся постепенно :)
   ang: single;
   ang_delta, d_ang: single;//дельта угол и скорость наращивания угла
   procedure ang_update;
  public
   wp_next: word;

   procedure bot_restart;virtual;  //при респауне, рестарте и.т.п. ;)
   procedure bot_ondead;virtual;   //при смерти
   procedure bot_onhit;virtual;    //при ранении
   procedure bot_think;virtual;    //когда подумать надо :)
   procedure Update;virtual;     //обычный Update
   function GetAngle(Player: TPlayer): single;
   function GetDist(Player: TPLayer): single;
   function GetNearest: TPlayer;virtual;
   property pl : TPlayer read f_player write f_player;
 end;

 TAlienShaftBot = class(TTFKBot)
   constructor Create;
 private
    reload: integer;
    dist   : single;
 public
    procedure Update;override;
    procedure bot_ondead;override;
    procedure bot_think;override;
   function GetNearest: TPlayer;override;
 end;

 TBotMap = class(TTFKPlayerMap)
  private
   function GetAIs(ind: integer): TTFKBot;
  public
   procedure bot_update;
   procedure bot_changemap;
   procedure bot_restart;
   function bot_count: integer;
   property AIs[ind: integer]: TTFKBot read GetAIs;
  end;

var
 bot_default: boolean; //активен ли дефолтный бот
                       //пока что не работает, т.к. смысла нет :)

procedure TFKBot_Init;
function TFKBot_CMD(Cmd: ShortString): boolean;

implementation

uses
 Math,
 Constants_Lib, SysUtils_, Map_Lib, Log_Lib,
 Weapon_Lib;

procedure TFKBot_Init;
begin
bot_default:=false;
Console_CmdRegEx('bot_default', @bot_default, VT_BYTE, 0, 1, true);
Console_CmdReg('bot_add', @TFKBot_Cmd);
Console_CmdReg('bot_addmax', @TFKBot_Cmd);
Console_CmdReg('bot_remove', @TFKBot_Cmd);
end;

function TFKBot_CMD(Cmd: ShortString): boolean;
var
 par       : array [1..3] of string;
 i         : integer;
 str, str_ : string;

  function RandomName: string;
  begin
     case random(5) of
        0: Result:='Тимур';
        1: Result:='Ванёк';
        2: Result:='Женёк';
        3: Result:='Санёк';
        4: Result:='Денис';
     end;
  end;

begin
Result := false;
str    := Func_Lib.LowerCase(cmd);
str_   := str;
for i := 1 to 3 do
 par[i] := StrSpace(str);

//добавление нового бота
if par[1] = 'bot_add' then
 begin
 Result := true;
 with Map do
  Log_AddPlayer(pl_add(C_PLAYER_TFKBot, RandomName, 'sarge+default', true));
 end;

if par[1] = 'bot_addmax' then
 begin
 Result := true;
 with Map do
 	while Players < sv_maxplayers do
   Log_AddPlayer(pl_add(C_PLAYER_TFKBot, RandomName, 'sarge+default', true));
 end;

//удаление старого бота ;)
if par[1] = 'bot_remove' then
 begin
 Result := true;
 with Map do
  if pl_find(-1, C_PLAYER_TFKBot) then
   begin
   Log_RemovePlayer(pl_current);
   pl_delete_current;
   end;
 end;
end;

{ TBotMap }
procedure TBotMap.bot_changemap;
begin
//сменилась карта, надо инициализировать заново переменные бота :)
end;

function TBotMap.bot_count: integer;
begin
Result := pl_count_ptype(C_PLAYER_TFKBOT);
end;

procedure TBotMap.bot_restart;
begin
if pl_find(-1, C_PLAYER_TFKBOT) then
 repeat
  AIs[pl_cur_ind].bot_restart;
 until not pl_findnext(-1, C_PLAYER_TFKBOT);
end;

procedure TBotMap.bot_update;
begin
if pl_find(-1, C_PLAYER_TFKBOT) then
 repeat
  AIs[pl_cur_ind].Update;
 until not pl_findnext(-1, C_PLAYER_TFKBOT);
end;

function TBotMap.GetAIs(ind: integer): TTFKBot;
begin
Result := TTFKBot(Player[ind].AI);
end;

{ TTFKBot }

procedure TTFKBot.ang_update;
var
   a: single;
begin
   a:=ang_norm2(ang-pl.absangle);
   if signf(a-ang_delta)<=0 then
      begin
         //угол в допустимых пределах, можно качаться
         d_ang:=signf(d_ang)*min(3, ang_delta/4.5); //для резонанса

      end else
      begin
         //определяем скорость поворота
         if a>32 then d_ang:=8
         else if a>12 then d_ang:=4
         else if a>2 then d_ang:=2
         else d_ang:=a;
      	//определяем в какую сторону поворачивать угол
   		a:=ang_norm(ang-pl.absangle);
         if a>180 then d_ang:=-d_ang
      end;
   pl.AbsAngle:=pl.sangle+d_ang;
end;

procedure TTFKBot.bot_restart;
begin
thinktime := 5;
wp_next:=0;
end;

procedure TTFKBot.bot_think;
var
 target : TPlayer;
 dist   : single;
 i, j, x, y: integer;
 wp_temp: word;

// wp1, wp2: TWPObj;
begin
if pl.dead then
 begin
 pl.Key[KEY_FIRE].Down := true;
 Exit;
 end;

// Ищем игрока
target := GetNearest;
if not Map.player[0].dead
	then target:=Map.player[0];
if target <> nil then
 ang := GetAngle(target)*180/pi;

// Топаем
pl.Key[KEY_UP].Down          := false;
pl.Key[KEY_LEFT].Down        := false;
pl.Key[KEY_RIGHT].Down       := false;
pl.Key[KEY_FIRE].Down        := false;
pl.Key[KEY_STRAFELEFT].Down  := false;
pl.Key[KEY_STRAFERIGHT].Down := false;


if (target <> nil) and (Map.WP <> nil) then
 with target, Map.WP do
 begin

   x:=trunc(pl.Pos.X-pl.dpos.X*3);
   y:=trunc(pl.Pos.Y-pl.dpos.Y*3);
//   x:=trunc(pl.Pos.X);
//   y:=trunc(pl.Pos.Y);
	wp_temp:=GetNearest(x, y);
//   wp1:=WP[wp_next];
//   wp2:=WP[wp_temp];
   i:=Dist(x, y, wp_temp);
   j:=Dist(x, y, wp_next);
   if ((j>=i*2) or (i<15) )
//   	 ( (x<=wp1.x)*(x<=wp2.x)>0 ) and
//       ( (y<=wp1.y)*(y<=wp2.y)>0 )	)
               and (wp_next<>wp_temp) then
   	wp_next:=wp_temp;

  if FindWay(wp_next,
             GetNearest(trunc(Pos.X), trunc(Pos.Y))) then
   begin
   with pl, WP[Way[WayLen - 2]] do
    begin
    if X < Pos.X then Key[KEY_STRAFELEFT].Down  := true;
    if X > Pos.X then Key[KEY_STRAFERIGHT].Down := true;
    if Y < Pos.Y then Key[KEY_UP].Down          := true;
    //if Y > Pos.Y then Key[KEY_DOWN].Down        := true;
    end;
   end;

  end;
           {
// вот она! процедура поиска пути - random !!! Ж)
 case random(200) of
  1 : pl.Key[KEY_DOWN].Down := true;
  2 : pl.Key[KEY_DOWN].Down := false;
  3..13  : begin
           pl.Key[KEY_STRAFELEFT].Down := true;
           pl.Key[KEY_STRAFERIGHT].Down := false;
           end;
  14..24 : begin
           pl.Key[KEY_STRAFERIGHT].Down := true;
           pl.Key[KEY_STRAFELEFT].Down := false;
           end;
  25..35 : pl.Key[KEY_UP].Down := true;
 end;

if (Map.block_s(pl.Pos.X - 32, pl.Pos.Y)) and
    pl.Key[KEY_STRAFELEFT].Down then
 begin
 pl.Key[KEY_STRAFELEFT].Down := false;
 pl.Key[KEY_STRAFERIGHT].Down := true;
 end;

if (Map.block_s(pl.Pos.X + 32, pl.Pos.Y)) and
    pl.Key[KEY_STRAFERIGHT].Down then
 begin
 pl.Key[KEY_STRAFERIGHT].Down := false;
 pl.Key[KEY_STRAFELEFT].Down := true;
 end;
 end;        }

// стрелять или не стрелять? Вот в чём вопрос...
if target <> nil then
 begin
 dist := Map.TraceVector(pl.shotpos.X, pl.shotpos.Y, pl.AbsAngle*Pi/180);
 if dist < GetDist(target) then
  with Map do
   for i := 0 to Map.Players - 1 do
    with player[i] do
     if (playertype and C_PLAYER_ACTIVE > 0) and
        (UID <> pl.UID) and
         not player[i].dead then
      begin
      ang := self.GetAngle(player[i])*180/pi;
      dist := TraceVector(pl.shotpos.X, pl.shotpos.Y, ang*Pi/180);
      if dist > GetDist(player[i]) then
       	break;
      end;
 end;
//теперь если мы подумали как наводить, проверим достали ли мы до того игрока
	with pl, Map do
	begin
		dist := TraceVector(shotpos.X, shotpos.Y, AbsAngle*Pi/180);
		if TracePlayers(shotpos.X, shotpos.Y, AbsAngle*Pi/180, dist, UID)<> nil then
  			pl.Key[KEY_FIRE].Down := not NO_BOT_FIRE;
	end;

end;

procedure TTFKBot.Update;
begin
ang_update;	//наводим угол
if timer = 0 then
 bot_think;
if thinktime > 0 then
 timer := (timer + 1) mod thinktime
else
 timer := 0;
end;

constructor TTFKBot.Create;
begin
   ang_delta:=10;//ошибка
   bot_restart;
end;

// для следующих двух обработок используется
// переменная pl.hit_UID; константы для воды и.т.п.
// смотреть constants_lib.
procedure TTFKBot.bot_ondead;
begin

end;

procedure TTFKBot.bot_onhit;
begin

end;

function TTFKBot.GetAngle(Player: TPlayer): single;
var
 x, y   : single;
begin
x := Player.shotpos.X - pl.shotpos.X;
y := Player.shotpos.Y - pl.shotpos.Y;
Result := arctan2(y, x + 0.000001);
end;

function TTFKBot.GetDist(Player: TPLayer): single;
begin
Result := sqrt(sqr(pl.shotpos.X - Player.Pos.X) +
               sqr(pl.shotpos.Y - Player.Pos.Y));
end;

function TTFKBot.GetNearest: TPlayer;
var
 i, l : integer;
 min  : integer;
begin
Result := nil;
min    := 48000;
if Map.Players < 0 then Exit;
with Map do
 for i := 0 to Players - 1 do
  with player[i] do
   if (playertype and C_PLAYER_ACTIVE > 0) and
      (UID <> pl.UID) and
       not player[i].dead then
     begin
     l := trunc(abs(pl.Pos.X - Pos.X) + abs(pl.Pos.Y - Pos.Y));
     if l < min then
      begin
      min := l;
      Result := player[i];
      end;
     end;
end;

{ TAlienShaftBot }

procedure TAlienShaftBot.bot_ondead;
begin
   pl.cur_weapon:=WPN_GAUNTLET;
   pl.cur_wpn:=WPN_GAUNTLET;
   pl.next_weapon:=WPN_GAUNTLET;
end;

procedure TAlienShaftBot.bot_think;
const
   dist1 : single = 300.0;
   dist2 : single = 250.0;
   dist3 : single = 100.0;

var
 target, targ : TPlayer;

begin
// Ищем игрока
pl.Key[KEY_UP].Down          := false;
pl.Key[KEY_LEFT].Down        := false;
pl.Key[KEY_RIGHT].Down       := false;
pl.Key[KEY_DOWN].Down       := false;
pl.Key[KEY_FIRE].Down        := false;

target := GetNearest;
if target <> nil then
begin
 ang := GetAngle(target)*180/pi;
 dist:=Sqr(target.Pos.x-pl.Pos.x)+Sqr(target.Pos.y-pl.Pos.y);

if dist<sqr(dist1) then
begin
   if target.pos.x>pl.pos.x+dist3 then
      pl.Key[KEY_RIGHT].Down        := true;
   if target.pos.x<pl.pos.x-dist3 then
      pl.Key[KEY_LEFT].Down        := true
end;


 end else dist:=3000000;

dist:=Map.TraceVector(pl.Pos.X, pl.Pos.Y, ang*Pi/180);
if reload=0 then
begin
   targ:=Map.TracePlayers(pl.Pos.X, pl.Pos.Y, ang*Pi/180, dist, pl.UID);
   if (targ<>nil) then
   begin
      dist:=Sqr(targ.Pos.x-pl.Pos.x)+Sqr(targ.Pos.y-pl.Pos.y);
      if (dist<sqr(dist2))then
      begin
         reload:=21;
         ang_delta:=5;//ошибка
      end;
   end;
end else
begin
   if reload>1 then
   begin
      pl.next_weapon:=WPN_GAUNTLET;
      pl.KEY[KEY_FIRE].Down:=true;
      dec(reload);
      if reload=1 then
         pl.TakeWpn(WPN_SHAFT, 30, 0);
   end else
   begin
      pl.next_weapon:=WPN_SHAFT;
      if pl.ammo[WPN_SHAFT]>0 then
         pl.KEY[KEY_FIRE].Down:=true
      else
      begin
         reload:=0;
         ang_delta:=0;
      end;
   end;

end;

end;

constructor TAlienShaftBot.Create;
begin
   inherited;
   thinktime:=5;
   ang_delta:=0;
end;

function TAlienShaftBot.GetNearest: TPlayer;
var
 i, l : integer;
 min  : integer;
begin
Result := nil;
min    := 48000;
if Map.Players < 0 then Exit;
with Map do
 for i := 0 to Players - 1 do
  with player[i] do
   if (playertype and C_PLAYER_LOCAL > 0) and
      (UID <> pl.UID) and
       not player[i].dead then
     begin
     l := trunc(abs(pl.Pos.X - Pos.X) + abs(pl.Pos.Y - Pos.Y));
     if l < min then
      begin
      min := l;
      Result := player[i];
      end;
     end;
end;

procedure TAlienShaftBot.Update;
begin
   ang_update;	//наводим угол
   if timer = 0 then
      bot_think;
   if thinktime > 0 then
      timer := (timer + 1) mod thinktime
   else
      timer := 0;
end;

end.
