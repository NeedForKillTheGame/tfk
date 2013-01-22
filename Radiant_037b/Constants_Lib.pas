unit Constants_Lib;

interface

//jumppad :)
const
   Jump1 = 4.0;
   Jump2 = 5.0;

const
//ID-шники всех итемов и оружия
   shotgun_ID    = 2;
   grenade_ID    = 3;
   rocket_ID     = 4;
   shaft_ID      = 5;
   railgun_ID    = 6;
   plasma_ID     = 7;
   BFG_ID        = 8;

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
   HealthWait: array [Health5_ID..Health100_ID] of word =
     (1000, 1000, 1500, 3000);
   ArmorWait : array [Shard_ID..Armor100_ID] of word =
     (1000, 1500, 1500);
const
   PlayerMaxHealth1 = 100;
   PlayerMaxHealth2 = 200;

   PlayerMaxArmor1 = 100;
   PlayerMaxArmor2 = 200;

   HealthTickerWait = 50;
   SwitchTickerWait = 10;//смена оружия ПОЛНАЯ
{   SwitchTicker2Wait = 5;//смена оружия - след. оружие}

const
   WPN_Count = 9;

type
   TWPNArray = array [0.. WPN_Count-1] of word;

const
 //XProger: оружие
 WPN_GAUNTLET   = 0;
 WPN_MACHINEGUN = 1;
 WPN_SHOTGUN    = 2;
 WPN_GRENADE    = 3;
 WPN_ROCKET     = 4;
 WPN_LIGHTING   = 5;
 WPN_RAILGUN    = 6;
 WPN_PLASMA     = 7;
 WPN_BFG        = 8;

 WPN_AMMO		 = 8;

const

   WPN_Wait :  TWPNArray=
   (0, 1000, 1000, 1000, 1000, 1500, 1000, 1000, 1500);
   Ammo_Wait = 1000;

   Def_Ammo : TWpnArray =
   (1, 100, 10, 10, 10, 120, 10, 50, 20);
   Ammo_Box: TWpnArray =
   (0, 50, 5, 5, 5, 60, 5, 25, 10);
   Max_Ammo: TWpnArray =
   (0, 200, 100, 100, 100, 200, 100, 100, 100);


   PowerUp_Wait      = 5000;
   PowerUp_StartTime = 2600;

implementation

end.
