unit NFKBrick_Lib;

interface

        // brick structure
type    TNFKBrick = record // do not modify
        	image : Byte;          // graphix index
        	block : boolean;       // do this brick block player;
        	respawntime : integer; // respawn time
        	y           : shortint;
        	dir         : Byte;
        	oy          : real;
        	respawnable : boolean; // is this shit can respawn?
        	scale       : Byte;
        end;

        // object structure. (eg Rockets, blood, everything!)
type    TObj = record // do not modify
        	dead : Byte;
        	speed,fallt,weapon,doublejump,refire : Byte;
        	imageindex,dir,idd : Byte;
        	clippixel : smallint;
        	spawnerDXID : Word;
        	frame : Byte;
        	health : smallint;
        	x,y,cx,cy,fangle,fspeed : real;
        	objname : string[30];
        	DXID : Word;
        	mass, InertiaX,InertiaY : real;
        end;

        // special object structure. (eg Doors, Buttons)
type    TSpecObj = record  // do not modify
        active : boolean;
        x,y,length,dir,wait : Word;
        targetname,target,orient,nowanim,special:Word;
        objtype : Byte;
        end;


type TPlayerEx = record //class copy. DO NOT MODIFY. This record used by NFK CODE.
        dead,bot,crouch,balloon,flagcarrier,have_rl, have_gl, have_rg, have_bfg, have_sg, have_mg, have_sh, have_pl : boolean;
        refire,weapchg,weapon,threadweapon,dir,gantl_state,air,team,item_quad, item_regen, item_battle, item_flight, item_haste, item_invis,ammo_mg, ammo_sg, ammo_gl, ammo_rl, ammo_sh, ammo_rg, ammo_pl, ammo_bfg : Byte;
        x, y, cx, cy, fangle,InertiaX, InertiaY : real;
        health, armor, frags : integer;
        netname,nfkmodel : string[30];
        Location : string[64];
        DXID : Word;
        end;

var
   nfk_brk: array [0..255, 0..255] of TNFKBrick;
   nfk_w, nfk_h: byte;

procedure nfk_BricksInit;

implementation

uses Map_Lib, MapObj_Lib, ItemObj_Lib;

procedure nfk_BricksInit;
var
   i, j, k: integer;
begin
   fillchar(nfk_brk, sizeof(nfk_brk), 0);
   with Map do
   begin
   	nfk_w:=Map.Width;
   	nfk_h:=Map.Height;
      if nfk_w>250 then nfk_w:=250;
      if nfk_h>250 then nfk_h:=250;
   	for i:=0 to nfk_w-1 do
         for j:=0 to nfk_h-1 do
				if block_b(i, j) then
				begin
					nfk_brk[i, j].image:=54;
   				nfk_brk[i, j].block:=true;
				end;
      for i:=0 to Obj.Count-1 do
      begin
    		if Obj[i].ObjType in ItemObjs then
     		with Obj[i].struct do
         begin
      		nfk_brk[x, y].image := itemID;
      		if Obj[i].ObjType = otWeapon then
       			nfk_brk[x, y].image := weaponID - 1;
      		nfk_brk[x, y].respawnable := true;
      		nfk_brk[x, y].respawntime := TItemObj(Obj[i]).Timer;
            nfk_brk[x, y].y:=i+1;
      	end;
    		if Obj[i].ObjType = otNFKDoor then
     		with Obj[i].struct do
         begin
            for j:=x to x+Width-1 do
               for k:=y to y+Height-1 do
                  if (j>=0) and (k>=0) and (j<nfk_w) and (k<nfk_h) then
               begin
      				nfk_brk[j, k].respawnable := false;
            		nfk_brk[j, k].y:=i+1;
               end;
      	end;
      end;
   end;
end;

end.
