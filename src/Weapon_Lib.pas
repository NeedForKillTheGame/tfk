unit weapon_lib;

{$DEFINE NFKMODE}
//{$DEFINE DEBUG_LOG}

(***************************************)
(*  TFK Weapon library version  1.0.1.9*)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff777@rambler.ru         *)
(* site:http://timeforkill.mirgames.ru *)
(***************************************)

interface

uses
 Graph_Lib,
 Type_Lib,
 ObjAnim_Lib,
 MapObj_Lib,
 ObjSound_Lib,
 ItemObj_Lib,
 Constants_Lib,
 Real_Lib,
 Particle_Lib,
 Player_Lib,
 NET_Lib,
 NET_Server_Lib,
 Log_Lib;

var
 PLASMA_SPLASH_RADIUS : integer = 10;
 PLASMA_SPLASH_DMG    : integer = 10;
 PLASMA_PUSH          : single  = 1.5;
 PLASMA_collisions    : word = 0;

 explosion_push       : single  = 3.0;

 MACHINE_DANGLE       : single = 3;
 SHOTGUN_DANGLE       : single = 20;
 SHOTGUN_BULLETS      : integer = 11;
 SHAFT_LEN  	       : single = 200; //‰ÎËÌ‡ ¯ÎÂÈÙ‡ ¯‡ÙÚ‡

//(c) ” –¿ƒ≈ÕŒ ” 3d[power]‡
   GRENADE_LIVETIME : integer = 100;
   GRENADE_GRAVITY : single = 0.05;
   GRENADE_INERTX1 : single = 1.003;
   GRENADE_INERTX2 : single = 1.07;
   GRENADE_INERTY : single = 1.025;

procedure Weapon_Init;
procedure Weapon_InitSound;
procedure WeaponCreate;
procedure WeaponUpdate;
procedure WeaponDispose;
//—“–≈À‹¡¿
procedure Shot_Draw(pl: TPlayer);

procedure Shot(pl: TPlayer);
procedure Shot_bullet(pl: TPlayer);
function shot_gauntlet(pl: TPlayer): boolean;
function shot_plasma(pl: TPlayer): boolean;

procedure BrokeItem(Player: TObject; itemid:integer);
//ÙÛÌÍˆËˇ ‚ÓÁ‚‡˘‡ÂÚ ÔË˜ËÌÂÌÌ˚È Û˘Â· ƒ–”√»Ã Ë„ÓÍ‡Ï
function Explosion(x, y: integer; damage: integer; weapon: byte; player_uid: integer; push: single = -1): integer;
//ÂÒÚ‡Ú ıËÚÓ‚.
procedure HIT_RESTART;
//ÙÛÌÍˆËË ‚ÓÁ‚‡˘‡˛Ú ÔË˜ËÌÂÌÌ˚È Û˘Â·
function HitPlayer(damage, defender_UID, attacker_UID: integer; wpn: integer): integer;
function HitPlayerP(damage:integer; defender, attacker: TPlayer; wpn: integer; nohitsound: boolean=false): integer;
procedure HitApply(H: THit; nohitsound: boolean=false);
function hit_nextuid: integer;

//ÔÓ ‡ÒÒÚÓˇÌË˛ Ë ÓÛÊË˛ ‰‡∏Ú damage
function weapon_Dmg(weapon: word; s: integer): integer;

//√–¿‘» ¿ » «¬”  —¬ﬂ«¿ÕÕ€≈ — ¬€—“–≈À¿Ã» » Œ–”∆»≈Ã.
var
   CrosshairFrame : TObjTex;
   BalloonFrame   : TObjTex;
   RailTypeFrame  : TObjTex;
   NoAmmoSound    : TSound;

   DefWeapon : TWeaponObj;
   ExplosionSound  : TSound;

   RewardsFrame    : TObjTex;
   Humiliation_snd : TSound;
   Excellent_snd   : TSound;
   Impressive_snd  : TSound;

implementation

uses Engine_Reg, Func_Lib, Math_Lib, Map_Lib, Stat_Lib, Math, HUD_LIB,
	TFKEntries, Phys_Lib;

const
 HITMAXUID = 65535;

var
 Gauntlet        : TWeaponObj;
 HitSound        : TSound;
 PlasmaExpSound  : TSound;

 lasthituid : integer;

function hit_NextUID: integer;
begin
lasthituid := (lasthituid + 1) mod HITMAXUID;
Result     := lasthituid;
end;

procedure HIT_RESTART;
var
   i: integer;
begin
	lasthituid := 1;
   for i:=0 to Map.pl_count-1 do
      Map.player[i].lasthitid:=0;
end;

procedure Weapon_Init;
var
   i: byte;
begin
   phys_register('ammo_respawn', @AMMO_WAIT, VT_WORD);
   for i:=0 to WPN_Count-1 do
   begin
      if i>1 then
      begin
         phys_register('weapon_'+WPN_NAMES[i]+'_respawn', @WPN_WAIT[i], VT_WORD);
         phys_register('weapon_'+WPN_NAMES[i]+'_defammo', @DEF_AMMO[i], VT_WORD);
      end;
      if i>0 then
         phys_register('weapon_'+WPN_NAMES[i]+'_ammobox', @AMMO_BOX[i], VT_WORD);
   end;

   phys_register('weapon_machine_dangle', @MACHINE_DANGLE, VT_FLOAT);
   phys_register('weapon_shotgun_dangle', @SHOTGUN_DANGLE, VT_FLOAT);
   phys_register('weapon_shotgun_bullets', @SHOTGUN_BULLETS, VT_INTEGER);
   for i:=0 to WPN_Count-1 do
   begin
      phys_register('weapon_'+WPN_NAMES[i]+'_damage', @WPN_DAMAGE[i], VT_WORD);
      phys_register('weapon_'+WPN_NAMES[i]+'_push', @WPN_PUSH[i], VT_FLOAT);
      phys_register('weapon_'+WPN_NAMES[i]+'_output', @WPN_PUSH2[i], VT_FLOAT);
      if i in T_WPN_SPLASH then
         phys_register('weapon_'+WPN_NAMES[i]+'_splash', @WPN_SPLASH[i], VT_WORD);
      if i in T_WPN_REAL then
         phys_register('weapon_'+WPN_NAMES[i]+'_speed', @WPN_SPEED[i], VT_FLOAT);
   end;
   phys_register('weapon_shaft_length', @SHAFT_LEN, VT_FLOAT);
   phys_register('weapon_plasma_splash_dmg', @PLASMA_SPLASH_DMG, VT_FLOAT);
   phys_register('weapon_plasma_splash_radius', @PLASMA_SPLASH_RADIUS, VT_FLOAT);
   phys_register('weapon_plasma_splash_push', @PLASMA_PUSH, VT_FLOAT);
   phys_register('weapon_grenade_gravity', @GRENADE_GRAVITY, VT_FLOAT);
   phys_register('weapon_grenade_collision', @GRENADE_INERTX2, VT_FLOAT);
   phys_register('weapon_grenade_inert_x', @GRENADE_INERTX1, VT_FLOAT);
   phys_register('weapon_grenade_inert_y', @GRENADE_INERTY, VT_FLOAT);
   phys_register('weapon_grenade_livetime', @GRENADE_LIVETIME, VT_INTEGER);

   phys_register('powerup_firstrespawn_lo', @PowerUp_StartWait_Lo, VT_WORD);
   phys_register('powerup_firstrespawn_hi', @PowerUp_StartWait_Hi, VT_WORD);
   phys_register('powerup_respawn_lo', @PowerUp_Wait_Lo, VT_WORD);
   phys_register('powerup_respawn_hi', @PowerUp_Wait_hi, VT_WORD);

   phys_register('health_respawn_5', @health5wait, VT_WORD);
   phys_register('health_respawn_25', @health25wait, VT_WORD);
   phys_register('health_respawn_50', @health50wait, VT_WORD);
   phys_register('health_respawn_100', @health100wait, VT_WORD);

   phys_register('armor_respawn_5', @shardwait, VT_WORD);
//  phys_register('armor_respawn_25', @health25wait, VT_WORD);
   phys_register('armor_respawn_50', @armor50wait, VT_WORD);
   phys_register('armor_respawn_100', @armor100wait, VT_WORD);

//   phys_register('weapon_plasma_collisions', @plasma_collisions, VT_WORD);
end;

procedure Weapon_InitSound;
begin
HitSound       := TSound.Create('sound\hit.wav', false, true);

Humiliation_snd := TSound.Create('sound\stats\humiliation.wav', false);
Excellent_snd   := TSound.Create('sound\stats\excellent.wav', false);
Impressive_snd  := TSound.Create('sound\stats\impressive.wav', false);

NoAmmoSound    := TSound.Create('sound\weapons\noammo.wav', false);
ExplosionSound := TSound.Create('sound\weapons\exp.wav', false);
PlasmaExpSound := TSound.Create('sound\weapons\plasma_exp.wav', false);
end;

procedure WeaponCreate;
var
 struct : TMapObjStruct;
 i      : integer;
begin
struct.ObjType := otWeapon;
struct.weaponID := 0;
Gauntlet       := TWeaponObj.Create(struct);
if gametype=GT_RAIL then
   struct.weaponID := WPN_RAILGUN
else struct.weaponID := WPN_MACHINEGUN;
DefWeapon     := TWeaponObj.Create(struct);
CrosshairFrame := TObjTex.Create('textures\sprites\crosshair', 1, 0, 3, true, false, @clblack);
RailTypeFrame  := TObjTex.Create('textures\sprites\railtype', 1, 0, 3, false, false, @clblack);
BalloonFrame   := TObjTex.Create('textures\sprites\balloon', 1, 0, 1, true, false, @clblack);
RewardsFrame   := TObjTex.Create('textures\sprites\rewards', 1, 0, 1, true, false, @clblack);

i := CrosshairFrame.FrameCount - 1;
if i < 0 then i := 0;
if i > High(WORD) then i := High(WORD);
Console_CmdRegEx('cg_crosshair_type', @cg_crosshair_type, VT_WORD, 0, i, true);
i := RailTypeFrame.FrameCount - 1;
if i < 0 then i := 0;
if i > High(WORD) then i := High(WORD);
railtype_high:=i;

Weapon_InitSound;
end;

procedure WeaponDispose;
begin
end;

procedure WeaponUpdate;
begin
end;

// XProger: ‚ ˜ÂÒÚ¸ ÍÓ„Ó Â∏ Ú‡Í Ì‡Á‚‡ÎË? ;)
procedure Shot_Draw(pl: TPlayer);
var
 sx, sy : integer;
 ang    : single;
 weapon : Byte;
 c, s   : single;
 len    : WORD;
 Size   : TPoint2f;
 Color  : TRGBA;
begin
weapon := pl.cur_wpn;
len := WPN_LEN[weapon];
ang := pl.AbsAngle * deg2rad;
c   := cos(ang);
s   := sin(ang);
sx  := trunc(pl.shotpos.X + c * len);
sy  := trunc(pl.shotpos.Y + s * len);

if weapon in [WPN_SHOTGUN, WPN_MACHINEGUN] then
 if r_shell then
	Particle_Add(TP_Shell.Create(Point2f(sx - c*(len div 2), sy - s*(len div 2)), pl.dpos, weapon));

if weapon = WPN_SHOTGUN then
 begin
 if r_shell then
  Particle_Add(TP_Shell.Create(Point2f(sx - c*(len div 2), sy - s*(len div 2)), pl.dpos, weapon));
 if r_smoke then
  Particle_Add(TP_Smoke.Create(Point2f(sx, sy)));
 end;

if weapon in [WPN_SHOTGUN, WPN_MACHINEGUN, WPN_GRENADE, WPN_BFG] then
 if r_weapon_fire then
  Particle_Add(TP_Flash.Create(Point2f(sx, sy), weapon));

Size := Point2f(48, 48);
if r_weapon_light then
 begin
  case weapon of
   WPN_MACHINEGUN, WPN_SHOTGUN :
    Color := RGBA(255, 255, 0, 128);
   WPN_PLASMA : Color := RGBA(128, 128, 255, 128);
  else
   Exit;
  end;
 Particle_Add(TP_Light_2.Create(Point2f(sx, sy), Size, Color, 1));
 end;
end;

procedure Shot_bullet(pl: TPlayer);
var
 sx, sy : integer;
 s, ang, a : single;
 weapon : byte;
 hp     : TPlayer;
 p      : TPoint2f;
 n, i   : integer;
 hited  : boolean;
begin
a   := pl.AbsAngle*deg2rad;
weapon := pl.cur_wpn;
if weapon > WPN_SHOTGUN then
 weapon := WPN_MACHINEGUN;
sx  := trunc(pl.shotpos.X + cos(a) * WPN_LEN[weapon]);
sy  := trunc(pl.shotpos.Y + sin(a) * WPN_LEN[weapon]);

 if weapon = WPN_MACHINEGUN then
  n := 1
 else
  n := SHOTGUN_BULLETS;

hited := false;
for i := 0 to n - 1 do
 begin
 if weapon = WPN_MACHINEGUN then
  ang := a + MACHINE_DANGLE*(random*deg2rad - deg2rad/2)
 else
  ang := a + SHOTGUN_DANGLE * (i/n - 0.5) * deg2rad;//*(random*deg2rad - deg2rad/2);

 s  := Map.TraceVector(sx, sy, ang);
 hp := Map.TracePlayers(sx, sy, ang, s, pl.UID);

 p.X := sx + s * cos(ang);
 p.Y := sy + s * sin(ang);

 if r_bubble then
  Particle_TraceBubbles(Point2f(sx, sy), p);

 if r_bullet_trace > 0 then
  Particle_Add(TP_BulletTrace.Create(Point2f(sx, sy), p));

 Map.ShootActivation(sx, sy, ang, s, WeaponObjs[weapon], weapon_dmg(weapon, trunc(s)) * pl.Quad);
 RealObj_TraceDeads(sx, sy, ang, s, WPN_DAMAGE[weapon]* pl.Quad);

 if (hp = nil) and cg_marks then
  Particle_Add(TP_Mark.Create(p, weapon));

 if hp <> nil then
  begin
  	Stat_Hit(weapon, pl.UID);
  	hitplayerP(weapon_dmg(weapon, trunc(s)) * pl.Quad, hp, pl, pl.cur_wpn, true);
  	hp.Push(p.X, p.Y, WPN_PUSH[weapon] * pl.Quad);
  	Particle_Blood(p.X, p.Y);
  	hited := true;
  end;

 Particle_Add(TP_Explosion.Create(p, weapon));
 end;

if hited and (pl.playertype and C_PLAYER_P1>0) and (NET.Type_<>NT_CLIENT) then
 HitSound.Play;
end;

procedure Shot(pl: TPlayer);
var
 struct     : TRealObjStruct;
 Obj        : TRealObj;
 particle: TParticle;
 d, d1, ang : single;
 hp         : TPlayer;
 q, i, x, y, dmg : integer;
 weapon     : integer;
 dpos       : TPoint2f;
 s, c       : single;
begin
weapon := pl.cur_wpn;
ang    := pl.AbsAngle * deg2rad;
s      := sin(ang);
c      := cos(ang);
x      := trunc(pl.shotpos.X + c * WPN_LEN[weapon]);
y      := trunc(pl.shotpos.Y + s * WPN_LEN[weapon]);
dpos   := NULLPOINT;
q      := pl.Quad;
if WeaponObjs[weapon] = nil then
 Exit;

FillChar(struct, sizeof(struct), 0);
struct.X         := X;
struct.Y         := Y;
struct.angle     := ang;
struct.playerUID := pl.UID;
struct.ItemID    := weapon;
if weapon in T_WPN_REAL then
 begin
   if Map.IsClientGame then Exit;
   d := WPN_Speed[weapon];

 struct.dx := dpos.X + d * c;
 struct.dy := dpos.Y + d * s;
  case weapon of
   WPN_GRENADE :
    begin
    struct.ItemID := WPN_GRENADE;
    Obj := RealObj_Add(TGrenadeShot.Create(struct));
    end;
   WPN_ROCKET  :
    begin
    struct.ItemID := WPN_ROCKET;
    Obj := RealObj_Add(TRocketObj.Create(struct));
    end
   else
    Obj := RealObj_Add(TShotObj.Create(struct));
  end;

 if NET.Type_ = NT_SERVER then
  net_server.ShotObjCreate(Obj);
  if Net.Type_<>NT_CLIENT then
     Map.Demo.RecShotObjCreate(Obj);
 end
else
 if weapon = WPN_RAILGUN then
  begin
  //‡ ‚ÓÚ ÚÂÔÂ¸ ÔÓ‚ÂÍ‡ ÔÓÔ‡‰‡ÌËˇ ‚ Ë„ÓÍ‡:
  hp := nil;
  with Map do
   begin
   d := tracevector(x, y, ang);
   struct.dx := d * c;
   struct.dy := d * s;
   ShootActivation(x, y, ang, d, WeaponObjs[WPN_Railgun], WPN_DAMAGE[weapon] * q);
   RealObj_TraceDeads(x, y, ang, d, WPN_DAMAGE[weapon] * q);
   //œŒ—À≈ “¿ Œ… œ–Œ¬≈– » Õ» ¿ ¿ﬂ –≈À‹—¿ — ¬Œ«‹ »√–Œ ¿ Õ≈ œŒ–¿Õ»¬ ≈√Œ Õ≈ œ–Œ…ƒ≈“!!!
   for i := 0 to Players - 1 do
    begin
    d1 := d;
    if (Player[i].UID <> pl.UID) and (not player[i].dead) and
       RectVectorIntersect(player[i].frect, x, y, ang, d1) then
     begin
        if gametype=GT_RAIL then
           dmg:=500
        else dmg:=WPN_DAMAGE[WPN_RAILGUN] * q;
     hp:=pl;

      hitplayerP(dmg, player[i], pl, weapon);
      with struct do
      begin
  	      Particle_Blood(x + d1 * c, y + d1 * s);
         player[i].Push(x + d1 * c, y + d1 * s, WPN_PUSH[WPN_RAILGUN]);
      end;
     end;
    end;
   end;

  if hp <> nil then
   begin
   Stat_Hit(weapon, pl.UID);
   // IMPRESSIVE
   pl.lastrail := pl.lastrail + 1;
   if pl.lastrail = 3 then
    begin
    Impressive_snd.Play(X, Y);
    Stat_Impressive(pl.UID);
    pl.rewards_ticker[2] := REWARDS_TIME;
    pl.lastrail := 0;
    end;
   end else pl.lastrail := 0;

    Obj:=RealObj_Add(TRailShot.Create(struct));
    if r_enemy_rail and (pl.playertype and C_PLAYER_LOCAL=0) then
    begin
       Obj.SetColor(r_enemy_rail_color);
       Obj.tag:=r_enemy_rail_type;
    end else
    begin
       Obj.SetColor(pl.railcolor);
       Obj.tag:=pl.railtype;
    end;
  if cg_marks then
   with struct do
   begin
    particle:=Particle_Add(TP_Mark.Create(Point2f(x + dx, y + dy), WPN_RAILGUN));
    TP_Mark(particle).color:=RGBA(Obj.Color.R, Obj.Color.G, Obj.Color.B, 255);
   end;

  end
 else
  if weapon = WPN_SHAFT then
   with Map do
    begin
    if pl.shaft <> nil then
     begin
     struct := pl.shaft.Struct;
     end
    else
     begin
     pl.shaft := TShaftShot(RealObj_Add(TShaftShot.Create(struct)));
     //pl.shaft.Update;
     struct := pl.shaft.Struct;
     end;
    hp := TPlayer(pl.shaft.hplayer);
 		if hp <> nil then
     with pl, shaft do
      begin
   		HitPlayer(WPN_DAMAGE[weapon] * q, hp.UID, pl.UID, weapon);
      Stat_Hit(WPN_SHAFT, UID);
      with struct do
       begin
       hp.Push(x + dx, y + dy, WPN_PUSH[WPN_SHAFT]);
       Particle_Blood(x + dx, y + dy);
       end;
      end;
    end;

   {$IFDEF DEBUG_LOG}
   Log('{'+IntToStr(HUD_GetTime)+'}SHOT '+IntToStr(weapon));
   {$ENDIF}
end;

function shot_gauntlet(pl: TPlayer): boolean;
var
 i   : integer;
 sp  : TPoint2f;
 ang : single;
begin
Result:=false;
ang := pl.AbsAngle * deg2rad;
sp.X := pl.shotpos.X + WPN_LEN[WPN_GAUNTLET] * cos(ang);
sp.Y := pl.shotpos.Y + WPN_LEN[WPN_GAUNTLET] * sin(ang);
Map.ActivatePoint(round(sp.x), round(sp.y), weaponobjs[WPN_GAUNTLET], WPN_DAMAGE[WPN_GAUNTLET] * pl.Quad div 5);
with Map do
 for i := 0 to Players - 1 do
  with Player[i] do
   if not dead and (UID <> pl.UID) and
    PointInRect(trunc(sp.X), trunc(sp.Y),
               	Rect(fRect.X - 6, fRect.Y - 4, fRect.Width + 12, fRect.Height + 4)) then
    begin
    Result := true;
    HitPlayerP(WPN_DAMAGE[WPN_GAUNTLET] * pl.Quad, player[i], pl, pl.cur_wpn);
    Stat_Hit(WPN_GAUNTLET, pl.UID);
    Particle_Blood(sp.X, sp.Y);
    WeaponObjs[WPN_GAUNTLET].FIREsound2.Play(pl.Pos.X, pl.Pos.Y);
    if Player[i].Health <= 0 then
     begin
     // ›ÚÓ ‰ÓÎÊÂÌ ÒÎ˚¯‡Ú¸ Ó‰ËÌ‡ÍÓ„Ó Í‡Ê‰˚È
     Humiliation_snd.Play(sndPos.X, sndPos.Y);
     Stat_Humiliation(pl.UID);
     pl.rewards_ticker[0] := REWARDS_TIME;
     end;
    end;
end;

function shot_plasma(pl: TPlayer): boolean;
var
 struct : TRealObjStruct;
 ro     : TRealObj;
 c, s   : single;
begin
Result := true;
FillChar(struct, sizeof(struct), 0);
with struct do
 begin
 angle := pl.AbsAngle * deg2rad;
 c  := cos(angle);
 s  := sin(angle);
 x  := pl.shotpos.X + c * WPN_LEN[WPN_PLASMA];
 y  := pl.shotpos.Y + s * WPN_LEN[WPN_PLASMA];
 dx := WPN_SPEED[WPN_PLASMA]*c;
 dy := WPN_SPEED[WPN_PLASMA]*s;
 objtype   := otShot;
 playerUID := pl.UID;
 ItemID    := WPN_PLASMA;
 if signf(Map.TraceVector(x, y, angle) - PLASMA_SPLASH_RADIUS) <= 0 then
  begin
  HitPlayerP(PLASMA_SPLASH_DMG, pl, pl, WPN_PLASMA);
  pl.Push2(x, y + dy, PLASMA_PUSH * pl.Quad);
  end;

 if Map.IsClientGame then Exit;
 ro := TShotObj.Create(struct);
 RealObj_Add(ro);
 if NET.Type_ = NT_SERVER then
  net_server.ShotObjCreate(ro);
 Map.Demo.RecShotObjCreate(ro);
 end;
end;

procedure BrokeItem(Player: TObject; itemid:integer);
begin
	RealObj_Add(TFreeObj.Create(player, itemid));
end;

function Explosion(x, y: integer; damage: integer; weapon: byte; player_uid: integer; push: single = -1): integer;
var
 i, s1  : integer;
 radius : integer;
 ang    : single;
 s, s0, dx, dy: single;
begin
radius := WPN_SPLASH[weapon];
if push = -1 then
 s := EXPLOSION_PUSH
else
 s := push;
//Á‰ÂÒ¸ Â˘Â splash ÓÊ‰‡ÂÚÒˇ... ‰ÓÔÓÎÌËÚÂÎ¸Ì˚È ÛÓÌ ÓÚ ÓÛÊËˇ.
Result := 0;
with Map do
begin
   ShootActivation(x, y, 0, radius, weaponobjs[weapon], damage div 3);
   ShootActivation(x, y, Pi/4, radius, weaponobjs[weapon], damage div 3);
   ShootActivation(x, y, Pi/2, radius, weaponobjs[weapon], damage div 3);
   ShootActivation(x, y, 3*Pi/4, radius, weaponobjs[weapon], damage div 3);
   ShootActivation(x, y, Pi, radius, weaponobjs[weapon], damage div 3);
   ShootActivation(x, y, -3*Pi/4, radius, weaponobjs[weapon], damage div 3);
   ShootActivation(x, y, -Pi/2, radius, weaponobjs[weapon], damage div 3);
   ShootActivation(x, y, -Pi/4, radius, weaponobjs[weapon], damage div 3);

 if radius>0 then
 for i := 0 to Players - 1 do
  if not Player[i].dead then
   begin
   s1 := trunc(sqrt(sqr(x - trunc(player[i].Pos.X)) +
                    sqr(y - trunc(player[i].Pos.Y))));
   s0 := PointToRect(x, y, Player[i].fRect);
   if s1 < radius then
    begin
    if s1 > radius div 3 then
     if s1 < 2 * radius div 3 then
      damage := damage * (2 * radius - s1 * 3 + 40) div 100
     else
      damage := damage * ((radius - s1) * 60 div radius + 20) div 100;
    dx := player[i].Pos.X - x;
    dy := player[i].Pos.Y - y;


    ang := arctan2(dy, dx + 0.00001);

    RectVectorIntersect(Player[i].fRect, x, y, ang, s0);
    Particle_Blood(x + s0*cos(ang), y + s0*sin(ang));
    HitPlayer(damage, player[i].UID, player_UID, weapon);
    Inc(Result, damage);
    player[i].Push2(x, y, s);
    end;
   end;

 end;

if weapon in [WPN_ROCKET, WPN_GRENADE, WPN_PLASMA, WPN_BFG] then
 begin
 if ((weapon = WPN_ROCKET)  and s_exp_rocket)  or
    ((weapon = WPN_GRENADE) and s_exp_grenade) or
    ((weapon = WPN_PLASMA)  and s_exp_plasma)  or
    ((weapon = WPN_BFG)     and s_exp_bfg)     then
  if weapon = WPN_PLASMA then
   PlasmaExpSound.Play(X, Y)
  else
   ExplosionSound.Play(X, Y);

 if ((weapon = WPN_ROCKET)  and r_exp_rocket)  or
    ((weapon = WPN_GRENADE) and r_exp_grenade) or
    ((weapon = WPN_PLASMA)  and r_exp_plasma)  or
    ((weapon = WPN_BFG)     and r_exp_bfg)     then
  Particle_Add(TP_Explosion.Create(Point2f(x, y), weapon));
 end;
end;

function HitPlayer(damage, defender_UID, attacker_UID: integer; wpn: integer): integer;
var
   pl1, pl2 : TPlayer;
begin
with Map do
 begin
 pl1:=PlayerByUID(defender_UID);
 pl2:=PlayerByUID(attacker_UID);
 end;
if pl1 <> nil then
 Result := HitPlayerP(damage, pl1, pl2, wpn)
else
 Result := 0;
end;

function HitPlayerP(damage: integer; defender, attacker: TPlayer; wpn: integer; nohitsound: boolean=false): integer;
var
 uid_: integer;
 H    : THit;
begin
if attacker <> nil then
 uid_ := attacker.UID
else
begin
 uid_ := -1;
 nohitsound:=true;
end;

Result:=0;
if (defender.health>0) then
begin
	defender.hit_weapon:=wpn;
	if not Map.IsClientGame then
 	with defender do
  begin
  H.v_uid  := defender.uid;
  H.a_uid  := uid_;
  if (
      (friendly_fire or (attacker=nil) or (attacker=defender) or (attacker.team<>defender.team) or (attacker.team=0))
     ) then
   H.damage := Hit(damage, uid_)
  else H.damage:=0;
  Result   := H.damage;
  H.health := byte_Health;
  H.armor  := armor;
  H.hitid  := hit_NextUID;
  	if (Result > 0) then
  	begin
  		if NET.Type_ = NT_SERVER then
 			net_server.PlayerHit(h);
   	HitApply(H, nohitsound);
  	end;
  end;
end
end;

procedure HitApply(H: THit; nohitsound: boolean);
var
   pl, pl2: TPlayer;
begin
with Map do
 if pl_find(H.v_uid, C_PLAYER_ALL) then
 begin
 	pl:=pl_current;
   if (pl_current.lasthitid<H.hitid) then
  	begin
    	if pl_find(H.a_uid, C_PLAYER_ALL) then
      	pl.Hit(H.damage, H.a_uid);
  	 	pl.byte_Health := H.health;
  	 	pl.Armor  := H.armor;
    	pl.lasthitid :=  H.hitid;
  	end else nohitsound:=true;
   pl2:=nil;
   if pl_find(H.a_uid, C_PLAYER_ALL) then
   begin
      pl2:=pl_current;
      if pl2.playertype and C_PLAYER_P1=0 then
         nohitsound:=true;
   end else nohitsound:=true;

   if MIN_HEALTH+h.health<=0 then
   begin
      if (pl2=nil) or (H.a_uid = ShortInt(H.v_uid)) or (H.a_uid = -1) then
      begin
       	Stat_Suicide(H.v_uid);
         if (pl2.playertype in [C_PLAYER_P1, C_PLAYER_P2]) then
            Particle_Add(TP_Frag.Create(Point2f(pl.pos.x, pl.pos.y), -1));
      end
      else if (gametype and GT_TEAMS>0) and (pl.team=pl2.team) then
      begin
         Stat_MinusFrag(H.a_uid);
         if (pl2.playertype in [C_PLAYER_P1, C_PLAYER_P2]) then
            Particle_Add(TP_Frag.Create(Point2f(pl.pos.x, pl.pos.y), -1));
      end
      else
      begin
         Stat_Frag(H.a_uid);
         Map.pl_stat_check_excellent(H.a_uid);
         if (pl2.playertype in [C_PLAYER_P1, C_PLAYER_P2]) then
            Particle_Add(TP_Frag.Create(Point2f(pl.pos.x, pl.pos.y), 1));
      end;
 		Log_Kill(H.v_UID, H.a_UID, pl.hit_weapon);
   end;

   Stat_HitDamage(H.damage, H.v_uid, H.a_uid);
   if not nohitsound then
  		HitSound.Play;
 	Map.Demo.RecHit(H);
 end;
end;

function weapon_Dmg(weapon: word; s: integer): integer;
begin
Result := 0;
 case weapon of
  WPN_GAUNTLET : if s < 50         then Result := 35;
  WPN_SHAFT    : if s <= SHAFT_LEN then Result := 3;
 else
  Result := WPN_DAMAGE[weapon];
 end;
end;

end.
