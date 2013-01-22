unit NFKMap_Lib;

(***************************************)
(*  NFK Map library     version 1.0.1  *)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

interface

uses TFKEntries;

type
   TTFKMap1 = class(TTFKMap)
   function LoadFromNFKFile(FileName: string): integer;
   function LoadFromFile(FileName: string): integer;override;
   end;

function IsNFKMap(filename: string): boolean;

implementation

uses MyEntries, Constants_Lib, MapObj_Lib, classes, bzlib;

type TMAPOBJV2 = record   // специальный объект
    	active : boolean;
     	x,y,length,dir,wait : word;
     	targetname,target,orient,nowanim,special:word;
     	objtype : byte;
    end;

type TNFKMapEntry = packed record
        	EntryType : string[3];
        	DataSize : longint;
        	Reserved1 : byte;
        	Reserved2 : word;
        	Reserved3 : integer;
        	Reserved4 : longint;
        	Reserved5 : cardinal;
        	Reserved6 : boolean;
        end;


const
	ItemObj: set of byte = [1..33, 34..37, 38..39];//брики в нфк - у нас объекты
   NFK_WATER = 32;
   NFK_DEATH = 33;

function NFKToTFKobj(NFKstruct : TMapObjV2):TMapObjStruct;
begin
   FillChar(result, sizeof(result), 0);
   Result.x:=NFKstruct.x;
   Result.y:=NFKstruct.y;
   Result.width:=1;
   Result.height:=1;
   Result.wait:=NFKStruct.wait;

   case NFKstruct.objtype of
       1:begin//Телепорт
       Result.ObjType:=otTeleport;
       Result.gotox:=NFKStruct.length;
       Result.gotoy:=NFKStruct.dir;
       Result.orient:=0;
       end;
       2:begin//кнопка
       Result.ObjType:=otButton;
       Result.color:=NFKStruct.orient;
       Result.target:=NFKStruct.target;
       Result.Active:=NFKStruct.Special*2;
       end;
       3:begin//дверь
       Result.ObjType:=otNFKDoor;
       Result.active:=1;
       //ориентация в НФК -
       // 0- вертикальная открытая
       // 1- вертикальная закрытая
       // 2- горизонтальная открытая
       // 3- горизонтальная закрытая
       Result.orient:=(1-NFKStruct.Orient and 1)*2;
       Result.target_name:=NFKStruct.targetname;
       Result.opened:=boolean(((NFKStruct.Orient and 2) div 2));
       if Result.Orient<2 then
           Result.height:=NFKStruct.length
           else
           Result.width:=NFKStruct.length;
       end;
       4://триггер
       begin
       	Result.ObjType:=otTrigger;
       	Result.target:=NFKStruct.target;
         Result.width:=NFKStruct.length;
         Result.height:=NFKStruct.dir;
       end;
       5: //area push
       begin
       	Result.ObjType:=otAreaPush;
       	Result.target:=NFKStruct.target;
         case NFKStruct.orient of
//влево вниз вправо вверх
            0: Result.pushspeedx:=-NFKStruct.special;
            1: Result.pushspeedy:=-NFKStruct.special;
            2: Result.pushspeedx:=NFKStruct.special;
            3: Result.pushspeedy:=NFKStruct.special;
         end;
         Result.pushwait:=NFKStruct.wait;
         Result.width:=NFKStruct.length;
         Result.height:=NFKStruct.dir;
       end;
       6: //area pain
       begin
       	Result.ObjType:=otAreaPain;
       	Result.target:=NFKStruct.target;
         Result.paindamage:=NFKStruct.dir;
         Result.painwait:=NFKStruct.nowanim;
         Result.width:=NFKStruct.special;
         Result.height:=NFKStruct.orient;
       end;
       7: //trix arena end
       begin
       	Result.ObjType:=otArenaEnd;
         Result.width:=NFKStruct.special;
         Result.height:=NFKStruct.orient;
       end;
       8: //area teleport
       begin
       Result.ObjType:=otAreaTeleport;
       Result.width:=NFKStruct.special;
       Result.height:=NFKStruct.orient;
       Result.gotox:=NFKStruct.dir;
       Result.gotoy:=NFKStruct.wait;
       Result.orient:=0;
       end;
//вверх влево вниз вправо
       9: //door trigger
       begin
          Result.ObjType:=otTrigger;
          Result.active:=2;
          Result.target:=NFKStruct.target;
          case NFKStruct.orient of
          0: begin inc(result.y);result.width:=NFKStruct.Length end;
          1: begin dec(result.x);result.height:=NFKStruct.Length end;
          2: begin dec(result.y);result.width:=NFKStruct.Length end;
          3: begin inc(result.x);result.height:=NFKStruct.Length end;
          end;
       end;
      else Result.ObjType:=otNone;
   end;
end;


function IsNFKMap(filename: string): boolean;
var
   F: File;
   buf: array [0..3] of char;
begin
   Result:=false;
   FileMode:=64;
   try
   	AssignFile(f, filename);
      Reset(f, 4);
      BlockRead(f, buf, 1);
      Result:=buf='NMAP';
      Close(F);
   except
   end;
end;

{ TTFKMap1 }

type
    array4=array [0..3] of char;
    string70=string[70];
    string3=string[3];

type THeader = record   // header карты
          ID : Array4;
          Version : byte;
          MapName : string70;
          Author : string70;
          MapSizeX,MapSizeY,BG,GAMETYPE,numobj : byte;
          XCode: word;
        end;

type TMapEntry = packed record
        	EntryType : string3;
        	DataSize : integer;

         Reserved1, Reserved2 : byte;
         name: String3;
         id: integer;
         Reserved4: boolean;
         Reserved5: integer;
        	Reserved6: boolean;
        end;

function TTFKMap1.LoadFromFile(FileName: string): integer;
begin
   if IsNFKMap(filename) then
		Result:=LoadFromNFKFile(filename)
      else Result:=inherited LoadFromFile(filename);
end;

function TTFKMap1.LoadFromNFKFile(FileName: string): integer;
var
   F: TMemoryStream;
   decomp, comp: TMemoryStream;
   head0: THeader;
   x, y: integer;
   img: byte;

   NFKstruct: TMapOBJV2;
   struct: TMapObjStruct;
   entry: TNFKMapEntry;
   ehead: TEntryHead;

   i: integer;

   procedure ZoneCreate(brick: byte; objtype: TObjType);
   var
      bufx: array [-1..256, -1..256] of integer;
      i, j, x, y, m, n: integer;
   begin
      fillchar(bufx, sizeof(bufx), 0);
      for j:=0 to Height-1 do
         for i:=0 to Width-1 do
         	if (brk[i, j]=brick) or
            	(bufx[i-1, j]>0) and (brk[i, j]>=54) then
               bufx[i, j]:=bufx[i-1, j]+1;
      for i:=Width-1 downto 0 do
    		for j:=Height-1 downto 0 do
            if brk[i, j]=brick then
         begin
            n:=bufx[i, j];
            y:=0;
            while (brk[i, j-y]=brick) do
//            		or (brk[i, j-y]=54) and (n<=bufx[i, j-y])	do
               begin
               	if n>bufx[i, j-y] then
                  	n:=bufx[i, j-y];
                  Inc(y);
               end;
            m:=y;
            //заполнение нулём.
            //(ширина  - bufx[i, j] высота m)
            fillchar(struct, sizeof(struct), 0);
            struct.width:=n;
            struct.height:=m;
            struct.x:=i-n+1;
            struct.y:=j-m+1;
            struct.objtype:=ObjType;
            case ObjType of
               otAreaPain: begin struct.paindamage:=500; struct.painwait:=1; end;
            end;
            Obj.Add(struct);
            for x:=0 to n-1 do
               for y:=0 to m-1 do
                  if brk[i-x, j-y]=brick then brk[i-x, j-y]:=0;
         end;
   end;

begin
   Result:=0;
   try
      F:=TMemoryStream.Create;
      F.LoadFromFile(FileName);

      F.Read(head0, sizeof(head0));

      if (head0.ID<>'NMAP') or
         (head0.Version<3) or (head0.Version>5) then
         begin
            Result:=-2;
            F.Free;
            Exit;
         end;

      Clear;
      BeforeLoad;

      Brk:=TBricksEntry.Create(head0.MapSizeX, head0.MapSizeY);
      Entries.Add(Brk);

      fhead.MapType:='TFKM';
      fhead.Version:=1;
      fhead.Author:=head0.Author;
      fhead.Name:=head0.MapName;

      //первый проход - брики и кол-во респаунов, джаппадов.
      for y:=0 to height-1 do
         for x:=0 to width-1 do
         begin
            F.Read(img, 1);
            Brk[x, y]:=img;
         end;

//создаем объекты и проходимся по брикам и объектам
      Obj:=TMapObjEntry.Create;
      Entries.Add(Obj);

      for i:=0 to head0.numobj-1 do
      begin
         F.Read(NFKstruct, SizeOf(TMapObjV2));
         struct:=NFKToTFKObj(NFKStruct);
         //WATER
         if NFKStruct.objtype=10 then
         begin
            for x:=0 to NFKStruct.special-1 do
               for y:=0 to NFKStruct.orient-1 do
                  Brk[x+NFKStruct.x, y+NFKStruct.y]:=NFK_WATER;
         end else Obj.Add(struct);
      end;

      ZoneCreate(NFK_WATER, otWater);
      ZoneCreate(NFK_DEATH, otAreaPain);

      for y:=0 to height-1 do
         for x:=0 to width-1 do
         begin
            Img:=Brk[x, y];
            if Img in ItemObj then
            begin
               FillChar(struct, SizeOf(struct), 0);
            	struct.itemID:=Brk[x, y];
       			struct.x:=x;
        			struct.y:=y;
        			struct.width:=1;
        			struct.height:=1;
         		case img of
                  1..7://оружие
                  begin
                     struct.ObjType:=otWeapon;
                     struct.weaponID:=img+1;
                     struct.wait:=WPN_Wait[struct.weaponID];
                  end;
                  8..15://патроны
                  begin
                     struct.ObjType:=otAmmo;
                     struct.WeaponID:=img-7;
                     struct.wait:=Ammo_Wait;
                  end;
                 	16..18://броня
                  begin
	           			struct.ObjType:=otArmor;
                     struct.wait:=ArmorWait[img];
                  end;
                 	19..22://health
                  begin
                     struct.ObjType:=otHealth;
                     struct.wait:=healthWait[img];
                  end;
                  23..28://powerup
                  begin
                     struct.ObjType:=otPowerUp;
                     struct.wait:=PowerUp_Wait;
                     struct.waittarget:=img*100;
                  end;
                  29..30://trix
                  begin
                     struct.ObjType:=otWeapon;
                     struct.weaponID:=img-26;
                     struct.count:=1;
                     struct.wait:=65535;
                  end;
                  31: //lava
                  begin
                     struct.ObjType:=otAreaPain;
                     struct.wait:=5;
                     struct.paindamage:=10;
                  end;
                	34..36: //респауны
                  begin
            			struct.ObjType:=otRespawn;
                     struct.orient:=ord(struct.x<width div 2);
                  end;
                  37: //Empty Brick
                  begin
                     struct.ObjType:=otEmptyBricks;
                  end;
                	38..39: //джамппады
                  begin
                     struct.orient:=2;
            			struct.ObjType:=otJumpPad;
                     if struct.ItemID=38 then struct.jumpspeed:=jump1
                       else struct.jumpspeed:=jump2;
                  end;
                  else struct.ObjType:=otNone;
               end;
 					Obj.Add(struct);
            end;

            if Brk[x,y]<54 then Brk[x, y]:=0
            else Brk[x, y]:=Brk[x, y]-53;
            Brk.Blocked[x, y]:=Brk[x, y]>0;
            Brk.Front[x, y]:=false;
         end;

      while f.position<f.size do
      begin
         f.Read(entry, SizeOf(entry));
         if entry.DataSize<0 then Break;
         if entry.EntryType='pal' then
         begin
            ehead.name:='pal';
            ehead.EntryClass:='TBrkTexEntry';

            comp:=TMemoryStream.Create;
            comp.CopyFrom(F, entry.DataSize);
            comp.position:=0;
            decomp:=TMemoryStream.Create;
            bzDecompress(comp, decomp);
            decomp.position:=0;
            if entry.Reserved6 then
            	BrkTex:=TBrkTexEntry.Create(ehead, decomp, entry.Reserved5)
               else
            	BrkTex:=TBrkTexEntry.Create(ehead, decomp);
            Entries.Add(BrkTex);
            comp.Free;
            decomp.Free;
         end else if entry.EntryType<>'loc' then Break;
      end;

      F.Free;
      AfterLoad;
	except
      result:=-1;
   end;
end;

end.
