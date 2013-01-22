unit Stat_Lib;

interface

uses Constants_Lib;

type
   TPlayerStat =
   record
      UID: integer;
      dmgGiven: integer;
      dmgTaken: integer;
   	Frags   : integer;
      Deaths  : integer;
      Suicides: integer;
      Hits, Shots: TWPNArray;
      humiliation, impressive, excellent: word;
   end;

   PPlayerStat= ^TPlayerStat;

procedure Stat_Reset;
procedure Stat_Fix;

function Stat_GetStat(i: integer): PPlayerStat;
function Stat_GetStatCount: integer;

function Stat_Get(UID: integer; cancreate: boolean): PPlayerStat;
function Stat_Create(UID: integer): PPlayerStat;
procedure Stat_Set(UID: integer; ps: TPlayerStat);
//выстрел патрона/снаряда/луча
procedure Stat_Shot(weapon, UID: integer);
//попадание патрона/снаряда/луча
procedure Stat_Hit(weapon, UID: integer);//UID ХОЗЯИНА СНАРЯДА!
//нанесение урона патроном/снарядом/лучом
procedure Stat_HitDamage(damage, attacker_UID, defender_UID: integer);
//смерти и фраги
procedure Stat_Frag(UID: integer);
procedure Stat_MinusFrag(UID: integer);
procedure Stat_Death(UID: integer);
procedure Stat_Suicide(UID: integer);
procedure Stat_Humiliation(UID: integer);
procedure Stat_Impressive(UID: integer);
procedure Stat_Excellent(UID: integer);

implementation

uses Map_Lib;

const
   MaxStat = 128;

var
   stats: array [0..MaxStat-1] of PPlayerStat;
   count: integer;
   fixed: boolean;

procedure Stat_Fix;
begin
   fixed:=true;
end;

procedure Stat_Reset;
var
   i: integer;
begin
   fixed:=false;
   for i:=0 to count-1 do
      Dispose(stats[i]);
   count:=0;
end;

function Stat_GetStat(i: integer): PPlayerStat;
begin
   Result:=nil;
   if (i>=0) and (i<count) then
      Result:=stats[i];
end;

function Stat_GetStatCount: integer;
begin
   Result:=count;
end;

function CorrectWeapon(weap: integer): boolean;
begin
   Result:=(weap>0) and (weap<WPN_Count);
end;

function Stat_Get(UID: integer; cancreate: boolean): PPlayerStat;
var
   i: integer;
begin
   Result:=nil;
   if (UID<0) then Exit;
   for i:=0 to count-1 do
      if stats[i]^.UID=UID then
      begin
         Result:=stats[i];
         Exit;
      end;
   if cancreate then
      Result:=Stat_Create(UID);
end;

function Stat_Create(UID: integer): PPlayerStat;
begin
   Result:=Stat_Get(UID, false);
   if Result=nil then
   begin
      Inc(count);
      New(stats[count-1]);
      Result:=stats[count-1];
      fillchar(result^, Sizeof(TPlayerStat), 0)
   end else fillchar(result^, Sizeof(TPlayerStat), 0);
   Result^.UID:=UID;
end;

procedure Stat_Set(UID: integer; ps: TPlayerStat);
var
   i: integer;
begin
   for i:=0 to count-1 do
      if stats[i].UID=uid then
      begin
         stats[i]^:=ps;
         ps.UID:=UID;
         Exit;
      end;
   new(stats[count]);
   stats[count]^:=ps;
   Inc(count);
end;

procedure Stat_Shot(weapon, UID: integer);
var
   stat: PPlayerStat;
begin
   if not correctweapon(weapon) or fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
      Inc(stat^.Shots[weapon]);
end;

procedure Stat_Hit(weapon, UID: integer);
var
   stat: PPlayerStat;
begin
   if not correctweapon(weapon) or fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
      Inc(stat^.Hits[weapon]);
end;

procedure Stat_HitDamage(damage, attacker_UID, defender_UID: integer);
var
   stat: PPlayerStat;
begin
   if fixed then Exit;
   stat:=Stat_Get(attacker_UID, false);
   if stat<>nil then
      Inc(stat^.dmgGiven, damage);
   stat:=Stat_Get(defender_UID, false);
   if stat<>nil then
      Inc(stat^.dmgTaken, damage);
end;

procedure Stat_MinusFrag(UID: integer);
var
   stat:PPlayerStat;
begin
   if fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
      Dec(stat^.frags);
end;

procedure Stat_Frag(UID: integer);
var
   stat:PPlayerStat;
begin
   if fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
      Inc(stat^.frags);
end;

procedure Stat_Death(UID: integer);
var
   stat:PPlayerStat;
begin
   if fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
      Inc(stat^.deaths);
end;

procedure Stat_Suicide(UID: integer);
var
   stat:PPlayerStat;
begin
   if fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
   begin
      Inc(stat^.suicides);
      Dec(stat^.frags);
   end;
end;

procedure Stat_Humiliation(UID: integer);
var
   stat:PPlayerStat;
begin
   if fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
      Inc(stat^.humiliation);
end;

procedure Stat_Impressive(UID: integer);
var
   stat:PPlayerStat;
begin
   if fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
      Inc(stat^.Impressive);
end;

procedure Stat_Excellent(UID: integer);
var
   stat:PPlayerStat;
begin
   if fixed then Exit;
   stat:=Stat_Get(UID, false);
   if stat<>nil then
      Inc(stat^.Excellent);
end;

end.
