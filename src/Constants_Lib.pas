unit Constants_Lib;

{$DEFINE NFKMODE}

interface

uses
 SysUtils, Graph_Lib;


type
  str32 = string[32];

var
   maps_folder: string = 'maps\';
   spgame_folder: string = '';

const
   clblack     : TRGBA = (R:0;   G:0;   B:0;   A:0);
   clwhite     : TRGBA = (R:255; G:255; B:255; A:255);
   clblue      : TRGBA = (R:0;   G:0;   B:255; A:255);
   clgreen     : TRGBA = (R:0;   G:255; B:0;   A:255);
   clred       : TRGBA = (R:255; G:0;   B:0;   A:255);
   clyellow    : TRGBA = (R:255; G:255; B:0;   A:255);
   clpurple    : TRGBA = (R:255; G:0;   B:255; A:255);
   cllightblue : TRGBA = (R:0;   G:128; B:255; A:255);

const
// номера в массиве TPlayer.Key
// клавиши от 0 до 7 записываются в демку
  KEY_UP           = 0;  // прыжок
  KEY_DOWN         = 1;  // присесть
  KEY_LEFT         = 2;  // идти влево
  KEY_RIGHT        = 3;  // идти вправо
  KEY_FIRE         = 4;  // ОГОНЬ!
  KEY_USE          = 5;
  KEY_BALLOON      = 6;

  KEY_RUP          = 8;  // поворот ствола вверх
  KEY_RDOWN        = 9;  // поворот ствола вниз
  KEY_RCENTER      = 10;
  KEY_NEXTWPN      = 11;
  KEY_PREVWPN      = 12;
  KEY_WEAPON 	    = 13;

  KEY_SCOREBOARD 	 = 22;
  KEY_STRAFELEFT   = 23;  // идти влево
  KEY_STRAFERIGHT  = 24;  // идти вправо


  MOUSE_1          = 0;
  MOUSE_2          = 1;
  MOUSE_3          = 2;
  MOUSE_4          = 3;
  MOUSE_5          = 4;
  MOUSE_6          = 5;
  MOUSE_7          = 6;
  MOUSE_8          = 7;

const
   C_PLAYER_p1 = 1;
   C_PLAYER_p2 = 2;
   C_PLAYER_bot = 4;
   C_PLAYER_TFKbot = 8;
   C_PLAYER_demo = 16;
   C_PLAYER_net  = 32;

   C_PLAYER_LOCAL = 3;
   C_PLAYER_NOTBOTS = 11+C_PLAYER_net;
   C_PLAYER_NOTDEMO = 15+C_PLAYER_net;
   C_PLAYER_LOCALHOST = 15;
   C_PLAYER_ACTIVE = 255;
   C_PLAYER_ALL = 255;
   C_PLAYER_BOTS = 12;

   UID_UNKNOWN = -1;
   UID_SQUISH  = -2;
   UID_WATER   = -3;

const
   SPLIT_NONE  = 0;
   SPLIT_VERT  = 1;
   SPLIT_HORIZ = 2;


   ShardWait     : word = 20;
   Armor50Wait   : word = 30;
   Armor100Wait  : word = 30;

   Health5Wait   : word = 20;
   Health25Wait  : word = 20;
   Health50Wait  : word = 30;
   Health100Wait : word = 60;

const
   Ammo_ID       = 8;//ид патронов - Ammo_ID+Weapon_ID

   Shard_ID      = 16;
   Armor50_ID    = 17;
   Armor100_ID   = 18;

   Health5_ID    = 19;
   Health25_ID   = 20;
   Health50_ID   = 21;
   Health100_ID  = 22;

   REGEN_ID      = 23;
   BATTLESUIT_ID = 24;
   HASTE_ID      = 25;
   QUAD_ID       = 26;
   FLIGHT_ID     = 27;
   INV_ID        = 28;
   
const
   Healthes : array [Health5_ID..Health100_ID] of word =
     (5, 25, 50, 100);
   Armors : array [Shard_ID..Armor100_ID] of word =
     (5, 50, 100);

const
   PlayerMaxHealth1 = 100;
   PlayerMaxHealth2 = 200;

   PlayerMaxArmor1 = 100;
   PlayerMaxArmor2 = 200;

   HealthTickerWait = 50;
   SwitchTickerWait = 9;//смена оружия

const
   WPN_Count = 9;

type
   TWPNArray = array [0.. WPN_Count-1] of WORD;
   TWPNArrayf = array [0.. WPN_Count-1] of single;
   TPowerUpArray= array [REGEN_ID..INV_ID] of word;

const
 //XProger: оружие.
 WPN_GAUNTLET   = 0;
 WPN_MACHINEGUN = 1;
 WPN_SHOTGUN    = 2;
 WPN_GRENADE    = 3;
 WPN_ROCKET     = 4;
 WPN_SHAFT      = 5;
 WPN_RAILGUN    = 6;
 WPN_PLASMA     = 7;
 WPN_BFG        = 8;

const
   T_WPN_SPLASH : set of byte = [WPN_ROCKET, WPN_GRENADE, WPN_BFG];
   T_WPN_REAL   : set of byte = [WPN_GRENADE, WPN_ROCKET, WPN_PLASMA, WPN_BFG];

   WPN_Wait :  TWPNArray=
    (0, 0, 20, 20, 20, 35, 20, 20, 30);
   Ammo_Wait : word = 20;
 // XProger: время ожидания между фреймами для каждого оружия
   WPN_Frame_Wait : TWpnArray =
    (1, 0, 10, 10, 10, 10, 14, 0, 2);
////  G, MG, SG,  GL,   RL,  SH,  RG,  PG,  BFG  ////
   Def_Ammo      : TWpnArray =
    (1, 100,  10,  10,  10, 100,  10,  50,  20);

   Ammo_Box      : TWpnArray =
    (0,  50,  10,  10,   5,  75,  10,  30,  15);

   Max_Ammo      : TWpnArray =
    (0, 200, 200, 200, 200, 200, 200, 200, 200);

   Reload_Wait   : TWpnArray =
    (20,  5,  50,  40,  40,   3,  75,   5,  10);

   WPN_DAMAGE    : TWPNArray =
    (50,  7,  7, 100, 100,   8, 100,  20, 100);

 //радиус сплэша :)
   WPN_SPLASH    : TWPNArray =
    ( 0,  0,   0,  60,  60,   0,   0,  0,  50);

   WPN_Names     : array [0..WPN_Count-1] of string=
   ('gauntlet', 'machine', 'shotgun', 'grenade', 'rocket', 'shaft', 'railgun', 'plasma', 'bfg');
    
   WPN_PUSH : TWPNArrayf =
   (0, 0.3, 0.05, 3.0, 3.0, 0.54, 1.04, 0.45, 3.0);

   WPN_PUSH2 : TWPNArrayf =
   (0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

   WPN_SPEED: TWPNArrayf =
   (0, 0, 0, 4.5, 7, 0, 0, 8, 8);

 // ПРОРИСОВКА ОРУЖИЯ
 // XProger: Это как и графическая, так и физическая длина оружия!!!
	 WPN_LEN       : TWPNArray =
    (12, 24,  24,   9,  24,  22,  24,  20,  20);

   PowerUp_StartWait_Lo    : word = 30;
   PowerUp_StartWait_Hi    : word = 60;
   PowerUp_Wait_Lo         : word = 60;
   PowerUp_Wait_Hi         : word = 90;
const
   REWARDS_TIME = 50 * 3; // награда висит над головой 3 секунды

//А ЭТО СВОЁ
   GRENADE_ROTATESPEED  = -0.03;	//в градусах на один тик.

   GRENADE_CLIP = 4;
   ROCKET_CLIP  = 4;
   PLASMA_CLIP  = 4;

  // SHAFT_MINLEN = 15;
   SHAFT_DX     = 0.2; //ускорение игрока
   SHAFT_DY     = 0.2; //ускорение игрока

   SHAFT_SIZEX = 32; //размер луча.
   SHAFT_SIZEY = 16;

   FREEOBJ_LIVETIME = 750;

const
   C_ROUND = 4;
   S_ROUND = 20;
   Real_Trace = 7;

const
 GT_FFA  = 1;   // Free For All
 GT_TRIX = 2;   // Trix Arena
 GT_RAIL = 4;   // Rail Arena
 GT_TDM  = 8;   // Team Deathmatch
 GT_CTF  = 16;  // Capture The Flag
 GT_DOM  = 32;  // Domination
 GT_CTC  = 64;  // Catch The Chicken  ;)
 GT_SINGLE = 128; //single Player;
 GT_TEAMS = 120;

 TEAM_BLUE = 1;
 TEAM_RED  = 2;

 USE_RADIUS = 16;

const
   MOUSE_NFKMODE = 0;
   MOUSE_TFKMODE = 1;
   MOUSE_SOLDATMODE = 2;

var
// display
 dis_scale   : boolean;    // растяжение картинки
 dis_view    : boolean;    // увеличение обзора
 dis_mode    : Byte;       // режим дисплея

 cam_fixed   : boolean;    // фиксировать камеру по центру
 cam_smooth  : Byte;       // плавное перемещение камеры
 cam_speed   : Byte;       // скорость перемещения камеры при ручном управлении
 splitscreen : Byte;       // сплитскрин
// console
 con_alpha  : Byte;        // Прозрачность консоли
 con_drawbg : boolean;     // прорисовка заднего плана консоли
// hud
 hud_status_alpha : Byte;
 hud_simple       : boolean;
 hud_color_health : boolean;
 hud_color_armor  : boolean;
 def_brick  : WORD;     // прорисовка только одним бриком
 //0 - все как всегда, остальные -деф.брик

// effects
 r_blood                : boolean; // разрешено ли насилие в игре :)
 r_blood_count          : Byte;    // количество крови
 r_blood_time           : Byte;    // время жизни кровяки
 r_dead                 : boolean; // ТРУПЫ НУЖНЫ???
 r_dead_time            : WORD;    // Время лежания трупом
 r_gibs                 : boolean; // Ошмётки
 r_gibs_blood           : Byte;    // кровоточащие?
 r_gibs_time            : WORD;    // время существования
 r_gibs_blood_static    : boolean; // крось не в разброс

 r_part_time            : WORD;    // время "лежания" куска отбитого от брика

 r_item_rotate          : boolean; // вертящиеся итемсы
 r_item_amplitude       : Byte;    // отклонение итемсов по Y
 r_bg_draw              : boolean; // отрисовка фона
 r_bg_motion            : Byte;    // Смешение фона
 r_bg_speed_x           : integer; // Скорость движения фона по x
 r_bg_speed_y           : integer; // Скорость движения фона по y

 r_rail_width            : integer; // ширина луча
 r_rail_trailtime        : integer; // время остывания луча
 r_rail_progressivealpha : boolean; // плавное таяние луча
 r_rail_type, r_enemy_rail_type, r_p2_rail_type : WORD; // внешний вид луча
 r_rail_color, r_enemy_rail_color, r_p2_rail_color : TRGB; // внешний вид луча
 r_enemy_rail            : boolean;
 railtype_high           : integer;


 r_weapon_fire           : boolean; // вспышки огня при стрельбе
 r_weapon_light          : boolean; // вспышки света при стрельбе

 r_exp_interpolate      : boolean; // плавный переход между кадрами взрыва
 // отрисовка взрыва
 r_exp_rocket           : boolean;
 r_exp_grenade          : boolean;
 r_exp_plasma           : boolean;
 r_exp_bfg              : boolean;
 // звук взрыва
 s_exp_rocket           : boolean;
 s_exp_grenade          : boolean;
 s_exp_plasma           : boolean;
 s_exp_bfg              : boolean;

 r_bullet_trace         : WORD;    // следы от пуль машингана/шотгана

 r_shell                : boolean; // гильзы
 r_shell_speed          : boolean; // начальная скорость гильзы = скорости игрока
 r_shell_time           : WORD;    // время жизни гильзы
 r_smoke                : boolean; // дымок

 r_laser_spark          : boolean; // искры
 r_laser_patch          : boolean; // блик

 r_lights               : boolean;
 r_lightmap             : boolean;
 r_lightmap_demo        : boolean;
 r_lightmap_quality     : Byte;
 r_lightmap_smooth      : Byte;

 r_snow                 : boolean;
 r_snow_time            : WORD;
 r_rain                 : boolean;
 r_bubble               : boolean;
 r_bubble_count         : Byte;
 r_bubble_time          : WORD;

 r_maxparticles         : integer; // максимальное количество частиц
 r_buttons_mode         : byte;    // разные режимы картинок кнопок
 r_fade_speed           : integer;

 cg_marks               : boolean;
 cg_marks_time          : integer;
 cg_drawrewards         : boolean;

 cg_crosshair           : boolean;  // рисовать ли прицел
 cg_crosshair_offset    : integer;  // Расстояние от игрока до прицела
 cg_crosshair_size      : Byte;     // Радиус рисунка прицела
 cg_crosshair_type      : WORD;     // Тип прицела (фрейм в текстуре)
 cg_crosshair_color_r   : Byte;     // Цвет прицела
 cg_crosshair_color_g   : Byte;
 cg_crosshair_color_b   : Byte;
 cg_ups                 : WORD;     // хз но эту феньку некоторые личности требуют :)
 cg_airsteps            : boolean;  // шагать в полёте
 cg_steps               : boolean;  // звуки шагов

 r_backbr_alpha         : byte;
 r_frontbr_alpha        : byte;

// debug
 d_particles : boolean;
 d_timing    : boolean;
 d_clearbit  : boolean;
 d_realobjs  : boolean;
 d_waypoints : boolean; // Показывать вейпоинты и последний найденный путь
 d_net_log   : boolean;

 demo_showinfo : boolean; //XProger: информация при записи демки
 demo_recmode  : byte;    //Neoff: куда записывается дема - прямо в карту или как :)

 p2disable: boolean;
 p1nextwpn_skipempty : boolean;
 p2nextwpn_skipempty : boolean;

 sound_off           : integer;
 sound_freq          : integer;

 timelimit           : WORD;
 fraglimit           : WORD;
 forcerespawn        : WORD;
 warmup_time         : WORD;
 warmup_armor        : WORD;
 warmup_mode         : byte;

 keyb_sensitivity, mouse_sensitivity : byte;
 mouselook_pitch, mouselook_yaw	: byte;
 mouselook_offset : byte;
 mouselook     	: byte;
 mouselook_strafe : boolean;

 shownick      : boolean; // показывать ли ник над игрком

 p1name, p2name   : shortstring;  //имена игроков.
 p1model, p2model : shortstring;  //имена игроков.
 bg               : shortstring;  // текущий фон карты

 menu_fx          : boolean;

 gametype_c       : Byte;     // В коде игры не используется
 gametype         : Byte;     // А вот это - уже текущий режим игры
 friendly_fire    : boolean;  // а вот и friendly fire!

 net_sync		   : byte;
 net_delta 	  		: integer;
 net_randomsocket : boolean;
 net_spectator    : boolean;
 net_phys_sending : boolean;
 net_mapmode      : boolean;
 net_mapsend      : boolean;
 net_timeout      : cardinal;
 net_debug_disconnect: boolean;

 sv_maxplayers : Byte;    // максимальное количество игроков
 sv_name 	     : shortstring;
 sv_pass       : shortstring;
 sv_port			 : WORD;
 arena_address : ShortString;
 phys_itemmode : byte;

//СВОЙСТВА ИГРЫ... приходится в рекорде хранить из-за демок.
//т.к. этих свойств скоро будет слишком много...
 //physics
function sv_gravity: smallint;
 //game

 procedure Const_Init;
 procedure GameCmdOff;
 procedure GameCmdOn;
 procedure CmdCheck;

function NumToColor(num: integer): TRGBA;

procedure cfgProc(cmd: ShortString);

implementation

uses
 Engine_Reg, Type_Lib, Game_Lib, Map_Lib,
 HUD_Lib, Binds_Lib, Func_Lib;

function NumToColor(num: integer): TRGBA;
begin
   case num of
      0: Result:=clRed;
      1: Result:=clGreen;
      2: Result:=clBlue;
      3: Result:=clYellow;
      4: Result:=clPurple;
      5: Result:=clLightBlue;
      6: Result:=clWhite;
      else Result:=clBlack;
   end;
end;

function sv_gravity: smallint;
begin
Result := Map.gp.sv_gravity;
end;

procedure r_lightmap_generate;
begin
if (Map <> nil) and (Map.LightMap <> nil) then
 Map.LightMap.Generate;
end;

procedure Const_Init;
begin
dis_scale  := false;
dis_view   := false;
dis_mode   := 2;    // 640х480

cam_fixed  := false;
cam_smooth := 10;
cam_speed  := 5;

def_brick  := 0;

timelimit    := 10;
fraglimit    := 0;
forcerespawn := 10;

hud_status_alpha := 255;
hud_simple       := true;
hud_color_health := true;
hud_color_armor  := true;
Map.sv_gravity   := 200;

con_alpha  := 255;
con_drawbg := true;

r_blood                := true;
r_blood_count 	       := 4;
r_blood_time           := 50;
r_dead                 := true;
r_dead_time            := 10;

r_gibs                 := true;
r_gibs_time            := 750;
r_gibs_blood           := 5;
r_gibs_blood_static    := false;

r_part_time            := 750;

r_item_rotate          := true;
r_item_amplitude       := 2;
r_bg_draw              := true;
r_bg_motion            := 0;
r_bg_speed_x           := 0;
r_bg_speed_y           := 0;

r_rail_trailtime        := 11;
r_rail_width            := 8;
r_rail_progressivealpha := true;

r_rail_color              := RGB(255, 0, 0);
r_rail_type               := 0;
r_p2_rail_color           := RGB(255, 0, 0);
r_p2_rail_type            := 0;
r_enemy_rail              := false;
r_enemy_rail_type         := 0;
r_enemy_rail_color        := RGB(255, 0, 0);
railtype_high           := 100;

r_exp_interpolate      := true;
r_exp_rocket           := true;
r_exp_grenade          := true;
r_exp_plasma           := true;
r_exp_bfg              := true;

s_exp_rocket           := true;
s_exp_grenade          := true;
s_exp_plasma           := true;
s_exp_bfg              := true;


r_maxparticles         := 10000;

r_shell                := true;
r_shell_speed          := false;
r_shell_time           := 500;

r_weapon_fire          := true;
r_weapon_light         := true;
r_bullet_trace         := 2;
r_smoke                := true;

r_laser_spark          := true;
r_laser_patch          := true;

r_lights               := true;
r_lightmap             := true;
r_lightmap_demo        := true;
r_lightmap_quality     := 1;
r_lightmap_smooth      := 1;

r_snow                 := true;
r_snow_time            := 255;
r_rain                 := true;

r_bubble               := true;
r_bubble_count         := 10;
r_bubble_time          := 100;

r_buttons_mode         := 0;
r_fade_speed           := 100;
warmup_time            := 100;
warmup_armor           := 200;
warmup_mode            := 1;

cg_marks               := true;
cg_marks_time          := 250;
cg_drawrewards         := true;

r_backbr_alpha    := 200;
r_frontbr_alpha   := 255;

d_particles := false;
d_timing    := false;
d_clearbit  := true;
d_realobjs  := false;
d_waypoints := false;
d_net_log   := false;

keyb_sensitivity   := 4;
mouse_sensitivity  := 4;
mouselook	       := MOUSE_SOLDATMODE;
mouselook_offset := 0;
mouselook_pitch  := 6;
mouselook_yaw	   := 6;
mouselook_strafe := true;

demo_showinfo       := true;

p2disable           := false;
p1nextwpn_skipempty := true;
p2nextwpn_skipempty := true;

sound_off           := 0;
sound_freq          := 1;

cg_crosshair        := true;
cg_crosshair_offset := 150;
cg_crosshair_size   := 16;
cg_crosshair_type   := 1;
cg_crosshair_color_r := 255;
cg_crosshair_color_g := 255;
cg_crosshair_color_b := 255;

cg_ups              := 50;
cg_airsteps         := true;
cg_steps            := true;

demo_recmode  := 0;

shownick      := true;

sv_maxplayers := 8;
sv_name       := 'Welcome';
sv_pass       := '';
arena_address := 'timeforkill.mirg.ru';

p1name := 'Player 1';
p2name := 'Player 2';

p1model  := 'sarge+red';
p2model  := 'sarge+blue';
bg       := 'bg_11';

gametype   := GT_FFA;
gametype_c := gametype;
friendly_fire:=true;
phys_itemmode:=1;


net_sync         := 3;
net_delta        := 5;
net_timeout      := 10;
net_debug_disconnect:= false;
net_randomsocket := false;
net_spectator    := false;
net_phys_sending := false;
net_mapmode      := false;
net_mapsend      := true;
menu_fx          := true;

sv_port          := 25666;

GameCMDOn;

Console_CmdRegEx('def_brick', @def_brick, VT_WORD, 0, 1024, true);

Console_CmdRegEx('con_alpha', @con_alpha, VT_BYTE, 0, 255, true);
Console_CmdRegEx('con_drawbg', @con_drawbg, VT_BYTE, 0, 1, true);

Console_CmdRegEx('dis_scale', @dis_scale, VT_BYTE, 0, 1, true);
Console_CmdRegEx('dis_view', @dis_view, VT_BYTE, 0, 1, true);

Console_CmdRegEx('cam_fixed', @cam_fixed, VT_BYTE, 0, 1);
Console_CmdRegEx('cam_smooth', @cam_smooth, VT_BYTE, 0, 100);
Console_CmdRegEx('cam_speed', @cam_speed, VT_BYTE, 1, 32);

Console_CmdRegEx('splitscreen', @splitscreen, VT_BYTE, 0, 2);

Console_CmdRegEx('keyb_sensitivity', @keyb_sensitivity, VT_BYTE, 1, 30, true);
Console_CmdRegEx('mouse_sensitivity', @mouse_sensitivity, VT_BYTE, 1, 30, true);
Console_CmdRegEx('mouselook', @mouselook, VT_BYTE, 0, 2, true);
Console_CmdRegEx('mouselook_offset', @mouselook_offset, VT_BYTE, 0, 8, true);
Console_CmdRegEx('mouselook_pitch', @mouselook_pitch, VT_BYTE, 1, 9, true);
Console_CmdRegEx('mouselook_yaw', @mouselook_yaw, VT_BYTE, 1, 9, true);
Console_CmdRegEx('mouselook_strafe', @mouselook_strafe, VT_BYTE, 0, 1, true);

Console_CmdRegEx('r_blood', @r_blood, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_blood_count', @r_blood_count, VT_BYTE, 0, 20, true);
Console_CmdRegEx('r_blood_time', @r_blood_time, VT_BYTE, 0, 255, true);
Console_CmdRegEx('r_dead', @r_dead, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_dead_time', @r_dead_time, VT_WORD, 0, 300, true);

Console_CmdRegEx('r_gibs', @r_gibs, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_gibs_time', @r_gibs_time, VT_WORD, 0, 3000, true);
Console_CmdRegEx('r_gibs_blood', @r_gibs_blood, VT_BYTE, 0, 50, true);
Console_CmdRegEx('r_gibs_blood_static', @r_gibs_blood_static, VT_BYTE, 0, 1, true);

Console_CmdRegEx('r_part_time', @r_part_time, VT_WORD, 0, 3000, true);

Console_CmdRegEx('r_item_rotate', @r_item_rotate, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_item_amplitude', @r_item_amplitude, VT_BYTE, 0, 5, true);
Console_CmdRegEx('r_bg_draw', @r_bg_draw, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_bg_motion', @r_bg_motion, VT_BYTE, 0, 100, true);
Console_CmdRegEx('r_bg_speed_x', @r_bg_speed_x, VT_INTEGER, -1000, 1000, true);
Console_CmdRegEx('r_bg_speed_y', @r_bg_speed_y, VT_INTEGER, -1000, 1000, true);

Console_CmdRegEx('r_backbr_alpha', @r_backbr_alpha, VT_BYTE, 0, 255, true);
Console_CmdRegEx('r_frontbr_alpha', @r_frontbr_alpha, VT_BYTE, 0, 255, true);

Console_CmdRegEx('r_rail_trailtime', @r_rail_trailtime, VT_INTEGER, 0, 100000, true);
Console_CmdRegEx('r_rail_width', @r_rail_width, VT_INTEGER, 1, 32, true);
Console_CmdRegEx('r_rail_progressivealpha', @r_rail_progressivealpha, VT_BYTE, 0, 1, true);
Console_CmdRegEx('enemy_rail', @r_enemy_rail, VT_BYTE, 0, 1, true);

Console_CmdRegEx('r_exp_interpolate', @r_exp_interpolate, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_exp_rocket', @r_exp_rocket, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_exp_grenade', @r_exp_grenade, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_exp_plasma', @r_exp_plasma, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_exp_bfg', @r_exp_bfg, VT_BYTE, 0, 1, true);

Console_CmdRegEx('s_exp_rocket', @s_exp_rocket, VT_BYTE, 0, 1, true);
Console_CmdRegEx('s_exp_grenade', @s_exp_grenade, VT_BYTE, 0, 1, true);
Console_CmdRegEx('s_exp_plasma', @s_exp_plasma, VT_BYTE, 0, 1, true);
Console_CmdRegEx('s_exp_bfg', @s_exp_bfg, VT_BYTE, 0, 1, true);


Console_CmdRegEx('r_maxparticles', @r_maxparticles, VT_INTEGER, 0, 1000000, true);

Console_CmdRegEx('r_shell', @r_shell, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_shell_speed', @r_shell_speed, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_shell_time', @r_shell_time, VT_WORD, 0, 3000, true);
Console_CmdRegEx('r_weapon_fire', @r_weapon_fire, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_weapon_light', @r_weapon_light, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_bullet_trace', @r_bullet_trace, VT_BYTE, 0, 50, true);

Console_CmdRegEx('r_smoke', @r_smoke, VT_BYTE, 0, 1, true);

Console_CmdRegEx('r_laser_spark', @r_laser_spark, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_laser_patch', @r_laser_patch, VT_BYTE, 0, 1, true);

Console_CmdRegEx('r_lights', @r_lights, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_lightmap', @r_lightmap, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_lightmap_demo', @r_lightmap_demo, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_lightmap_quality', @r_lightmap_quality, VT_BYTE, 1, 16, true);
Console_CmdRegEx('r_lightmap_smooth', @r_lightmap_smooth, VT_BYTE, 0, 8, true);
Console_CmdRegEx('r_lightmap_generate', @r_lightmap_generate, VT_PROCEDURE, 0, 0, false);

Console_CmdRegEx('r_snow', @r_snow, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_snow_time', @r_snow, VT_WORD, 0, 3000, true);
Console_CmdRegEx('r_rain', @r_rain, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_bubble', @r_bubble, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_bubble_count', @r_bubble_count, VT_BYTE, 0, 25, true);
Console_CmdRegEx('r_bubble_time', @r_bubble_time, VT_WORD, 0, 3000, true);

Console_CmdRegEx('r_buttons_mode', @r_buttons_mode, VT_BYTE, 0, 1, true);
Console_CmdRegEx('r_fade_speed', @r_fade_speed, VT_INTEGER, 0, 100, true);

Console_CmdRegEx('cg_marks', @cg_marks, VT_BYTE, 0, 1, true);
Console_CmdRegEx('cg_marks_time', @cg_marks_time, VT_INTEGER, 0, 1000, true);
Console_CmdRegEx('cg_drawrewards', @cg_drawrewards, VT_BYTE, 0, 1, true);

Console_CmdRegEx('cg_crosshair', @cg_crosshair, VT_BYTE, 0, 1, true);
Console_CmdRegEx('cg_crosshair_offset', @cg_crosshair_offset, VT_INTEGER, 50, 200, true);
Console_CmdRegEx('cg_crosshair_size', @cg_crosshair_size, VT_BYTE, 1, 16, true);
Console_CmdRegEx('cg_crosshair_type', @cg_crosshair_type, VT_WORD, 0, 0, true);
Console_CmdRegEx('cg_crosshair_color_r', @cg_crosshair_color_r, VT_BYTE, 0, 255, true);
Console_CmdRegEx('cg_crosshair_color_g', @cg_crosshair_color_g, VT_BYTE, 0, 255, true);
Console_CmdRegEx('cg_crosshair_color_b', @cg_crosshair_color_b, VT_BYTE, 0, 255, true);

Console_CmdRegEx('cg_ups', @cg_ups, VT_WORD, 10, 500, true);
Console_CmdRegEx('cg_airsteps', @cg_airsteps, VT_BYTE, 0, 1, true);
Console_CmdRegEx('cg_steps', @cg_steps, VT_BYTE, 0, 1, true);

// debug
Console_CmdRegEx('d_particles', @d_particles, VT_BYTE, 0, 1, true);
Console_CmdRegEx('d_timing', @d_timing, VT_BYTE, 0, 1, true);
Console_CmdRegEx('d_clearbit', @d_clearbit, VT_BYTE, 0, 1, true);
Console_CmdRegEx('d_realobjs', @d_realobjs, VT_BYTE, 0, 1, true);
Console_CmdRegEx('d_waypoints', @d_waypoints, VT_BYTE, 0, 1, true);
Console_CmdRegEx('d_net_log', @d_net_log, VT_BYTE, 0, 1, true);

Console_CmdRegEx('demo_showinfo', @demo_showinfo, VT_BYTE, 0, 1, true);
//Console_CmdRegEx('demo_recmode', @demo_showinfo, VT_BYTE, 0, 1, true);

Console_CmdRegEx('hud_simple', @hud_simple, VT_BYTE, 0, 1, true);
Console_CmdRegEx('hud_color_health', @hud_color_health, VT_BYTE, 0, 1, true);
Console_CmdRegEx('hud_color_armor', @hud_color_armor, VT_BYTE, 0, 1, true);
Console_CmdRegEx('hud_status_alpha', @hud_status_alpha, VT_BYTE, 0, 255, true);

Console_CmdRegEx('sound_off', @sound_off, VT_BYTE, 0, 1, true);
Console_CmdRegEx('sound_freq', @sound_freq, VT_INTEGER, 0, 100000, true);

Console_CmdRegEx('p2disable', @p2disable, VT_BYTE, 0, 1, true);
Console_CmdRegEx('p1nextwpn_skipempty', @p1nextwpn_skipempty, VT_BYTE, 0, 1, true);
Console_CmdRegEx('p2nextwpn_skipempty', @p2nextwpn_skipempty, VT_BYTE, 0, 1, true);

Console_CmdRegEx('shownick', @shownick, VT_BYTE, 0, 1, true);
Console_CmdRegEx('sv_maxplayers', @sv_maxplayers, VT_BYTE, 2, 16, true);

Console_CmdRegEx('fraglimit', @fraglimit, VT_WORD, 0, 999, true);
Console_CmdRegEx('timelimit', @timelimit, VT_WORD, 0, 999, true);
Console_CmdRegEx('forcerespawn', @forcerespawn, VT_WORD, 0, 999, true);
Console_CmdRegEx('warmup_time', @warmup_time, VT_WORD, 5, 999, true);
Console_CmdRegEx('warmup_armor', @warmup_armor, VT_WORD, 0, 200, true);
Console_CmdRegEx('warmup', @warmup_mode, VT_BYTE, 0, 1, true);

Console_CmdRegEx('net_sync', @net_sync, VT_BYTE, 1, 8, true);
Console_CmdRegEx('net_mapmode', @net_mapmode, VT_BYTE, 0, 1, true);
Console_CmdRegEx('net_mapsend', @net_mapsend, VT_BYTE, 0, 1, true);

Console_CmdRegEx('net_delta', @net_delta, VT_INTEGER, 0, 100, true);
Console_CmdRegEx('net_randomsocket', @net_randomsocket, VT_BYTE, 0, 1, true);
Console_CmdRegEx('net_spectator', @net_spectator, VT_BYTE, 0, 1, true);
Console_CmdRegEx('net_phys_sending', @net_phys_sending, VT_BYTE, 0, 1, true);
Console_CmdRegEx('net_timeout', @net_timeout, VT_INTEGER, 0, 60, true);
Console_CmdRegEx('net_debug_disconnect', @net_debug_disconnect, VT_BYTE, 0, 1, true);

Console_CmdRegEx('menu_fx', @menu_fx, VT_BYTE, 0, 1, true);

Console_CmdRegEx('sv_port', @sv_port, VT_WORD, 1024, 65500, true);

Console_CmdRegEx('friendly_fire', @friendly_fire, VT_BYTE, 0, 1, true);

//Console_CmdRegEx('phys_itemmode', @phys_itemmode, VT_BYTE, 0, 1, true);

end;

procedure GameCmdOff;
begin
Console_CmdReg('demo_goto', @Game_CMD);
Console_CmdReg('demo_skip', @Game_CMD);
cg_crosshair := false;
end;

procedure GameCmdOn;
begin
Console_CmdReg('demo_goto', nil);
Console_CmdReg('demo_skip', nil);
cg_crosshair := true;
end;

procedure CmdCheck;
begin
    if Map.pl_find(-1, C_PLAYER_p1) and
       Map.pl_find(-1, C_PLAYER_p2) and
         not cam_fixed then
            splitscreen := 2
         else splitscreen := 0;
end;

// Эта процедурка пишет значчения переменных в конфиг
procedure cfgProc(cmd: ShortString);
const
 nxt = #13#10;
var
 cfg  : TextFile;
 str  : string;
 cpar : array [0..1] of string;
 par  : string;
 bool : boolean;
 Data : string;
begin
 try // Вдруг с диска читаем
  FileMode := 64;
  AssignFile(cfg, Engine_ModDir + 'config.cfg');
  if not FileExists(Engine_ModDir + 'config.cfg') then
   Rewrite(cfg);

  Reset(cfg);
  Data := '';
  str := cmd;
  cpar[0] := StrSpace(str);
  cpar[1] := str;
  bool := false;
  while not eof(cfg) do
   begin
   Readln(cfg, str);
   par := trim(StrSpace(str));
   if par <> cpar[0] then
    Data := Data + par + ' ' + str + nxt
   else
    if not bool then
     begin
     str  := cpar[1];
     bool := true;
     Data := Data + par + ' ' + str + nxt;
     end
   end;

  if not bool then
   Data := Data + cmd + nxt;
  FileMode := 2;
  {$I-}                    //Отмена IO ошибок
  Rewrite(cfg);
  {$I+}
  Delete(Data, Length(Data) - 1, 2);
  if IOResult = 0 then
   Write(cfg, Data);
  CloseFile(cfg);
 except
  // Ну бывает...
  Log('^1Error: Save to config');
 end;
end;

end.
