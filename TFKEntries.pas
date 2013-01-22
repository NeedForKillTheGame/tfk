unit TFKEntries;

(***************************************)
(*  TFK Entries for GAMEversion 1.0.1.7*)
(***************************************)
(*  Created by Neoff                   *)
(*  mail : neoff@fryazino.net          *)
(*  site : http://tfk.mirgames.ru      *)
(***************************************)

interface

uses MyEntries, Engine_Reg, Graph_Lib, Func_Lib, MapObj_Lib, ItemObj_Lib, ObjAnim_Lib, demo_lib,
	LightMap_Lib, Scenario_Lib, WP_Lib, Constants_Lib;

const
   defHead : TMapHeader1=
(MapType: 'TFKM'; ECount:1; Version:1; Author:'TFK'; Name: 'TFKMap';gametype: GT_FFA+GT_RAIL+GT_TDM);

type
   TBrick= word;//2 bytes на один брик. первый - сам брик. второй - проходим ли брик :)
   //0 - брик проходим всегда

const
   MASK_BLOCK = 1;
   MASK_FRONT = 2;
   MASK_CONTAINER = 4;  //захвачен лифтом!
   MASK_OBJ = 8;
   MASK_WATER = 16;
   MASK_LAVA = 32;


type
   TBricksEntry =
   class(TSimpleEntry)
         constructor Create(Head_: TEntryHead; var F: File);overload;
         constructor Create(Width_, Height_: integer);overload;
  	protected
    tempbuf: array of byte;
    function GetHeight: integer;
    function GetWidth: integer;
    function GetBricks(x, y: integer): word;
    procedure SetBricks(x, y: integer; const Value: word);
    function GetMask(x, y: integer): byte;
    procedure SetMask(x, y: integer; const Value: byte);
	 function GetHead: TEntryHead;override;
      public
         class function EntryClassName: TEntryClassName;

         property Brick[x, y: integer]:word read GetBricks write SetBricks;default;
         property Mask[x, y: integer]: byte read GetMask write SetMask;

         property Width: integer read GetWidth;
         property Height: integer read GetHeight;

    		procedure Clear;
    		procedure SetSize(newWidth, newHeight: integer);
   end;


/////
   TMapObjEntry =
    class(TSimpleEntry)
      constructor Create(Head_: TEntryHead; var F: File);overload;
      constructor Create;overload;
  private
    	function GetObj(i: integer): TCustomMapObj;
      procedure SetObj(i: integer; const Value: TCustomMapObj);
    	function GetGObj(i: integer): TGeometryObj;
    protected
       freeplace: integer;
       objs: array of TCustomMapObj;
       gobjs: array of TGeometryObj;

    public
       is_monsters: boolean;
       mintrainwidth, mintrainheight: integer;
       Triggers: array of TCustomTrigger;
       TrainPoints: array of TTrainPointObj;
       liquids: array of TCustomLiquid;
       class function EntryClassName: TEntryClassName;

       procedure RestartObjects;
       function GetTrainPoint(index: integer): TTrainPointObj;

       function Count: integer;
       function g_Count: integer;
       function trig_Count: integer;
       property Obj[i: integer]: TCustomMapObj read GetObj write SetObj;default;
       property g_Obj[i: integer]: TGeometryObj read GetGObj;

       function CreateSpecObj(struct: TMapObjStruct):TCustomMapObj;virtual;
       function Add(struct: TMapObjStruct):TCustomMapObj;virtual;

       procedure SetSize(newlength: integer);
    end;

{    function TStringEntry =
    class(TCustomEntry)
      constructor Create(Head_: TEntryHead; var F: File);overload;
      constructor Create;overload;
    public
      class function EntryClassName: TEntryClassName;
      function GetStrByIndex();
    end;}

////////////////////

   TTFKMap = class(TCustomMap)

  private
    function GetHeight: word;
    function GetWidth: word;
  public
//
   Brk    : TBricksEntry;
   BrkTex : TBricksTexEntry;//пригодится потом....
   Obj	 : TMapObjEntry;
   Lights : TLightsEntry;
   LightMap: TLightMapEntry;
   Demo   : TTFKDemo;
   WP		 : TWPEntry;
   //респауны
   respawns: array of TRespawn;
   respcount: integer;
   nextresp: integer;
   teamnextresp: array [0..2] of integer;
   t_triggers: array [0..10000] of boolean;
   t_count: integer;

   procedure Clear;override;
   procedure NewMap;virtual;

   procedure AfterLoad;override;
   procedure BeforeLoad; override;
   function CreateEntry(head: TEntryHead; var f: File): TCustomEntry;override;

   property Width  : Word read GetWidth;
   property Height : Word read GetHeight;
             end;
implementation

uses NFKBrick_Lib;

{ TBricksEntry }

procedure TBricksEntry.Clear;
begin
   buf:=nil;
   tempbuf:=nil;
   fhead.size:=0;
   fhead.maxx:=0;
   fhead.maxy:=0;
end;

constructor TBricksEntry.Create(Head_: TEntryHead; var F: File);
var
   i, j: integer;
begin
   inherited Create(Head_, F);
   if head_.version=1 then
   begin
      for i:=0 to Width-1 do
         for j:=0 to Height-1 do
            Mask[i, j]:=ord(Brick[i, j]>0);
   end else
   for i:=0 to Width-1 do
      for j:=0 to Height-1 do
        	Mask[i, j]:=Mask[i, j] and (MASK_BLOCK or MASK_FRONT);
end;

constructor TBricksEntry.Create(Width_, Height_: integer);
begin
   inherited Create;
   SetSize(Width_, Height_);
end;

class function TBricksEntry.EntryClassName: TEntryClassName;
begin
   Result:='BricksV1';
end;

function TBricksEntry.GetBricks(x, y: integer): word;
begin
   if (x>=0) and (x<fhead.maxx) and
      (y>=0) and (y<fhead.maxy) then
      	Result:=word(buf[(y*width+x)*SizeOf(TBrick)])
         else Result:=fhead.defaultBrick;
end;

function TBricksEntry.GetHead: TEntryHead;
begin
   fhead.EntryClass:=EntryClassName;
   fhead.version:=2;
   Result:=fhead;
end;

function TBricksEntry.GetHeight: integer;
begin
   Result:=head.maxy;
end;

function TBricksEntry.GetMask(x, y: integer): byte;
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      	Result:=buf[(y*width+x)*SizeOf(TBrick)+1]
         else Result:=MASK_BLOCK;
end;

function TBricksEntry.GetWidth: integer;
begin
   Result:=head.maxx;
end;

procedure TBricksEntry.SetBricks(x, y: integer; const Value: word);
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      	buf[(y*width+x)*SizeOf(TBrick)]:=value and 255;
end;

procedure TBricksEntry.SetSize(newWidth, newHeight: integer);
var
   n: cardinal;
begin
   buf:=nil;
   fhead.maxx:=newWidth;
   fhead.maxy:=newHeight;
   n:=SizeOf(TBrick)*newWidth*newHeight;
   SetBufSize(n);
end;

procedure TBricksEntry.SetMask(x, y: integer; const Value: byte);
begin
   if (x>=0) and (x<width) and
      (y>=0) and (y<height) then
      	buf[(y*width+x)*SizeOf(TBrick)+1]:=value;
end;

{ TMapObjEntry }

procedure TMapObjEntry.RestartObjects;
var
   i: integer;
begin
   for i:=0 to Count-1 do
      Obj[i].restart;
end;

function TMapObjEntry.Count: integer;
begin
Result := High(Objs) + 1;
end;

constructor TMapObjEntry.Create(Head_: TEntryHead; var F: File);
var
 i, j, k, l   : integer;
 struct : PMapObjStruct;
begin
   inherited Create(head_, F);
   is_monsters:=false;
   mintrainwidth:=0;
   mintrainheight:=0;
   SetLength(objs, head.size div SizeOf(TMapObjStruct));
   SetLength(gobjs, head.size div SizeOf(TMapObjStruct));
   SetLength(liquids, head.size div SizeOf(TMapObjStruct));
   j:=0;k:=0;l:=0;
   for i:=0 to Count-1 do
   begin
      struct:=@buf[i*SizeOf(TMapObjStruct)];
      if ObjGameMask(struct^) and gametype>0 then
      begin
         objs[j]:=CreateSpecObj(struct^);
         if (objs[j] is TGeometryObj) then
         begin
            gobjs[k]:=TGeometryObj(objs[j]);
            Inc(k);
         end;
         if (objs[i] is TAreaTeleportWay) then
         begin
            SetLength(Triggers, trig_Count+1);
            Triggers[high(Triggers)]:=TCustomTrigger(objs[i]);
         end;
         if (objs[i] is TTrainObj) then
         begin
            if mintrainwidth<obj[i].width then
               mintrainwidth:=obj[i].width;
            if mintrainheight<obj[i].height then
               mintrainheight:=obj[i].height;
         end;
         if (objs[i] is TTrainPointObj) then
         begin
            SetLength(TrainPoints, length(TrainPoints)+1);
            TrainPoints[high(TrainPoints)]:=TTrainPointObj(objs[i]);
         end;
         if (objs[j] is TCustomLiquid) then
         begin
            liquids[l]:=TCustomLiquid(Objs[j]);
            Inc(l);
         end;
         if (objs[i] is TMonsterObj) then
         begin
            Is_Monsters:=true;
         end;
         Inc(j);
      end;
   end;
   SetLength(objs, j);
   SetLength(gobjs, k);
   SetLength(liquids, l);
end;


constructor TMapObjEntry.Create;
begin
   inherited Create;
   freeplace:=0;
end;

function TMapObjEntry.CreateSpecObj(struct: TMapObjStruct): TCustomMapObj;
begin
   case struct.objtype of
      otNone:
   		Result:=TCustomMapObj.Create(struct);
      otRespawn:
         Result:=TRespawn.Create(struct);
      otPortal:
         Result:=TPortal.create(struct);
      otTeleport:
         Result:=TTeleport.create(struct);
      otButton:
         Result:=TButton.Create(struct);
      otNFKDoor:
         Result:=TNFKDoor.Create(struct);
      otTrigger:
         Result:=TTrigger.Create(struct);
      otJumpPad:
         Result:=TJumpPad.create(struct);
      otArmor:
         Result:=TArmorObj.Create(struct);
      otHealth:
         Result:=THealthObj.Create(struct);
      otWeapon:
         Result:=TWeaponObj.Create(struct);
      otAmmo:
         Result:=TAmmoObj.Create(struct);
      otPowerUp:
         result:=TPowerUpObj.Create(struct);
      otDeathLine:
         result:=TDeathLineObj.Create(struct);
      otElevator:
         result:=TElevatorObj.Create(struct);
      otTriangle:
         result:=TTriangleObj.Create(struct);
      otAreaPain:
      	result:=TAreaPain.Create(struct);
      otAreaPush:
      	result:=TAreaPush.Create(struct);
      otArenaEnd:
      	result:=TArenaEnd.Create(struct);
      otAreaTeleport:
         result:=TAreaTeleport.Create(struct);
      otTeleportWay:
         result:=TAreaTeleportWay.Create(struct);
      otEmptyBricks:
      	Result:=TCustomMapObj.Create(struct);
//         result:=TEmptyBricks.Create(struct);
      otBackBricks:
      	Result:=TCustomMapObj.Create(struct);
//         result:=TBackBricks.Create(struct);
      otLightLine:
         result:=TLightLineObj.Create(struct);
      otBloodGen:
         result:=TBloodGen.Create(struct);
      otWater:
         result:=TWaterObj.Create(struct);
      otLava:
         result:=TLavaObj.Create(struct);
      otWeather:
         result:=TWeather.Create(struct);
      otTrain:
         result:=TTrainObj.Create(struct);
      otTrainPoint:
         result:=TTrainPointObj.Create(struct);
      otBelt:
         result:=TBelt.Create(struct);
      otAnimation:
         result:=TAnimationObj.Create(struct);
      otSoundTrigger:
         result:=TSoundTrigger.Create(struct);
      otDestroyer:
         result:=TDestroyerObj.Create(struct);
      otMonster:
         result:=TMonsterObj.Create(struct);
      else Result:=TCustomMapObj.Create(struct);
   end;
end;

function TMapObjEntry.GetObj(i: integer): TCustomMapObj;
begin
   if (i>=0) and (i<=high(Objs)) then
   	Result:=Objs[i] else Result:=nil;
end;

procedure TMapObjEntry.SetObj(i: integer; const Value: TCustomMapObj);
begin
   if (i>=0) and (i<=high(Objs)) then
   	Objs[i]:=Value;
end;

procedure TMapObjEntry.SetSize(newlength: integer);
begin
   if freeplace>=newlength then
      freeplace:=newlength-1;
   SetLength(Objs, newLength);
end;

class function TMapObjEntry.EntryClassName: TEntryClassName;
begin
   Result:='ObjectsV1';
end;

function TMapObjEntry.Add(struct: TMapObjStruct): TCustomMapObj;
begin
   //поиск свободного места
   if freeplace=Length(objs)-1 then
      freeplace:=0;
   while (freeplace<Length(objs)) and (Objs[freeplace]<>nil) do
      Inc(freeplace);
   if freeplace>=Length(objs) then
      SetSize(Length(objs)+1);
   Objs[freeplace]:=CreateSpecObj(struct);
   Result:=Objs[freeplace];
end;

function TMapObjEntry.g_Count: integer;
begin
   Result:=length(gObjs);
end;

function TMapObjEntry.GetGObj(i: integer): TGeometryObj;
begin
   if (i>=0) and (i<=high(gObjs)) then
   	Result:=gObjs[i] else Result:=nil;
end;

function TMapObjEntry.trig_Count: integer;
begin
   if Triggers<>nil then Result:=length(Triggers)
   	else Result:=0;
end;

function TMapObjEntry.GetTrainPoint(index: integer): TTrainPointObj;
var
   i: integer;
begin
   Result:=nil;
   for i:=low(trainpoints) to high(trainpoints) do
      if trainpoints[i].index=index then
      begin
         Result:=trainpoints[i];
         Break;
      end;
end;

{ TTFKMap }

procedure TTFKMap.Clear;
begin
   inherited Clear;
   fhead:=defHead;
end;

procedure TTFKMap.AfterLoad;
var
   i, j, k: integer;

   procedure addtrig(x: integer);
   begin
      if (x>0) and (x<9999) then
         if not t_triggers[x] then
      begin
         t_triggers[x]:=true;
         Inc(t_count);
      end;
   end;

begin
   if Brk=nil then
      Brk:=TBricksEntry.Create(20, 30);
   if Obj=nil then
      Obj:=TMapObjEntry.Create;
   t_count:=0;
   for i:=0 to Obj.Count-1 do
   begin
      AddTrig(Obj[i].Target);
      AddTrig(Obj[i].struct.target_name);
      if Obj[i].objtype=otElevator then
      begin
         AddTrig(Obj[i].Struct.etarget1);
         AddTrig(Obj[i].Struct.etarget2);
         AddTrig(Obj[i].Struct.etargetname1);
         AddTrig(Obj[i].Struct.etargetname2);
      end;
   end;
   //исбавляемся от back-брик объектов
   k:=0;
   with Obj do
   while k<Count do
   begin
      with Obj[k] do
         if ObjType = otBackBricks then
   begin
      for i:=struct.x to struct.x+struct.width-1 do
         for j:=struct.y to struct.y+struct.height-1 do
            Brk.Mask[i, j]:=2*ord(struct.plane>0);
   end else
   	if ObjType = otEmptyBricks then
   begin
      for i:=x to x+width-1 do
         for j:=y to y+height-1 do
            Brk.Mask[i, j]:=Brk.Mask[i, j] or MASK_BLOCK;
   end else if Obj[k] is TCustomLiquid then
   begin
{      for i:=x to x+width-1 do
         for j:=y to y+height-1 do
            Brk.Mask[i, j]:=Brk.Mask[i, j] or MASK_WATER;
      if Obj[k] is TLavaObj then
      for i:=x to x+width-1 do
         for j:=y to y+height-1 do
            Brk.Mask[i, j]:=Brk.Mask[i, j] or MASK_LAVA;}
   end;
   inc(k);
   end;


   nfk_BricksInit;

   //ищем респауны...
   j:=0;
   for i:=0 to Obj.Count-1 do
      if (Obj[i] is TRespawn) then
         Inc(j);
   respawns:=nil;
   if j>0 then
   begin
   	respcount:=j;
   	SetLength(respawns, j);
      j:=0;
   	for i:=0 to Obj.Count-1 do
      	if (Obj[i] is TRespawn) then
      	begin
            respawns[j]:=TRespawn(Obj[i]);
            Obj[i].tag:=j;
         	Inc(j);
			end;
      nextresp:=random(j);
   end else
   begin
      respcount:=0;
      SetLength(respawns, 1);
      respawns[0]:=TRespawn.Create(ObjStruct(otRespawn, Width div 2, Height div 2, 1, 1));
      Obj.SetSize(Obj.Count+1);
      Obj[Obj.Count-1]:=respawns[0];
      nextresp:=0;
   end;

   //запоминание стартового ректа
   for i:=0 to Obj.Count-1 do
      Obj[i].StartRect:=Obj[i].ObjRect;
   //захват лифтом итемов
   for j:=0 to Obj.Count-1 do
      if Obj[j] is TElevatorObj then
 			for i:=0 to Obj.Count-1 do
         begin
      		if (Obj[i].ObjType in ChildObjects) and
         		(Obj[i].x>=Obj[j].x) and (Obj[i].x+Obj[i].Width<=Obj[j].x+Obj[j].width) and
         		(Obj[i].y>=Obj[j].y) and (Obj[i].y+Obj[i].Height<=Obj[j].y+Obj[j].height) then
         			Obj[i].fOwner:=Obj[j];
//            else
        		if (Obj[i].ObjType in [otPortal, otTeleport, otAreaTeleport, otTeleportWay]) and
         		(Obj[i].struct.gotox>=Obj[j].x) and (Obj[i].struct.gotox+Obj[i].Width<=Obj[j].x+Obj[j].width) and
         		(Obj[i].struct.gotoy>=Obj[j].y) and (Obj[i].struct.gotoy+Obj[i].Height<=Obj[j].y+Obj[j].height) then
            		Obj[i].fOwner2:=Obj[j];
         end;
   //захват бриков лифтами
   for j:=0 to Obj.Count-1 do
      if Obj[j] is TBricksObj then
         TBricksObj(Obj[j]).TakeBricks;
   //захват бриков дестройерами
   for j:=0 to Obj.Count-1 do
      if Obj[j] is TDestroyerObj then
         TDestroyerObj(Obj[j]).TakeBricks;
end;

function TTFKMap.GetHeight: Word;
begin
   Result:=Brk.Height;
end;

function TTFKMap.GetWidth: Word;
begin
   Result:=Brk.Width;
end;

procedure TTFKMap.NewMap;
begin
   BeforeLoad;
   Clear;
   AfterLoad;
end;

function TTFKMap.CreateEntry(head: TEntryHead; var f: File): TCustomEntry;
begin
//по entryclassname смотрит кого же создать :)
//не забудьте
   if (head.EntryClass=TBricksEntry.EntryClassName) then
      if TBricksEntry.IsValidVersion(head.version) then
      begin
      	Brk:=TBricksEntry.Create(head, f);
         Result:=Brk;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TMapObjEntry.EntryClassName) then
      if TMapObjEntry.IsValidVersion(head.version) then
      begin             
      	Obj:=TMapObjEntry.Create(head, f);
         Result:=Obj;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TBricksTexEntry.EntryClassName) then
      if TBricksTexEntry.IsValidVersion(head.version) then
      begin
      	BrkTex:=TBricksTexEntry.Create(head, f);
         Result:=BrkTex;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TLightsEntry.EntryClassName) then
      if TLightsEntry.IsValidVersion(head.version) then
      begin
      	Lights:=TLightsEntry.Create(head, f);
         Result:=Lights;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TLightMapEntry.EntryClassName) then
      if TLightMapEntry.IsValidVersion(head.version) then
      begin
      	LightMap:=TLightMapEntry.Create(head, f);
        	Result:=LightMap;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TWPEntry.EntryClassName) then
      if TWPEntry.IsValidVersion(head.version) then
      begin
      	WP:=TWPEntry.Create(head, f);
        	Result:=WP;
      end
      else Result:=TSimpleEntry.Create(head, f)
   else if (head.EntryClass=TTFKDemo.EntryClassName) then
      if TTFKDemo.IsValidVersion(head.version) then
      begin
      	Demo:=TTFKDemo.Create(head, f);
         Result:=Demo;
      end
      else
      begin
         Log('^1INVALID DEMO VERSION: ^3'+IntToStr(head.version));
         Result:=nil;
      end
   else if (head.EntryClass=TTFKScenario.EntryClassName) then
      if TTFKScenario.IsValidVersion(head.version) then
      	Result:=TTFKScenario.Create(head, f)
      else
      begin
         Log('^1INVALID SCENARIO VERSION: ^3'+IntToStr(head.version));
         Result:=nil;
      end
   else Result:=TSimpleEntry.Create(head, f);
end;

procedure TTFKMap.BeforeLoad;
begin
   Brk:=nil;Obj:=nil;Demo:=nil;
   BrkTex:=nil;
   Lights:=nil;
   LightMap:=nil;
   WP:=nil;
end;

end.
