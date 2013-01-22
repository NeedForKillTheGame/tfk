unit ItemObj_Lib;

interface

uses
 Windows, OpenGL,
 Engine_Reg,
 Func_Lib,
 Type_Lib,
 Graph_Lib,
 Math_Lib,
 ObjAnim_Lib,
 ObjSound_Lib,
 MapObj_Lib,
 Constants_Lib,
 Demo_Lib;

//тип TItemObj - прародитель всех итемов

type
   TItemObj = class(TCustomMapObj)
     constructor Create(struct_:TMapObjStruct);
    protected
     Simpleanim : TObjTex;    // Упрощённая анимация
     falpha: boolean;

     Z     : single; //смещение по синусу
     ang   : single; //угол для синуса
    public
     spawned    : boolean;    // можно ли подобрать (появился)
     timer      : integer;    // Счётчик

     sound : TSound;  // Звук (при поднятии)
     spawnsound : TSound;  // Звук при появлении
     property ItemCount:word read fstruct.Count write fstruct.Count;

     procedure restart; override;
     procedure Draw; override;
     procedure Update; override;

     function Activate(sender: TObject): boolean; override;
     function Take(sender: TObject; count: integer): boolean; virtual;

    function SaveToRec(var rec: TDemoObjRec): boolean;override;
    procedure LoadFromRec(rec: TDemoObjRec);override;
     procedure SaveNet(var w: array of word);override;
     procedure LoadNet(w: array of word);override;
   end;

   TArmorObj = class(TItemObj)
     constructor Create(struct_:TMapObjStruct);
    public
     procedure restart; override;
     function Take(sender: TObject; count: integer):boolean; override;
   end;

   THealthObj = class(TItemObj)
     constructor Create(struct_:TMapObjStruct);
    public
    procedure restart;override;
     function Take(sender: TObject; count: integer):boolean; override;
   end;

   TAmmoObj = class(TItemObj)
     constructor Create(struct_:TMapObjStruct);
    public
     procedure restart;override;
     function Take(sender: TObject; count: integer):boolean; override;
   end;

   TWeaponObj = class(TItemObj)
     constructor Create(struct_:TMapObjStruct);
    public
     FIREanim   : TObjTex;
     SHOTanim   : TObjTex; //Neoff: анимация ПАТРОНА!!!
     Mask       : TObjTex; //XProger: PowerUP наложение
     FIREsound1 : TSound;  //XProger: звук выстрела
     FIREsound2 : TSound;  //XProger: второй звук - "рикошет"
//     STATsound  : TSound;  //Neoff: звук статистики (impressive например)
     function Take(sender: TObject; count: integer):boolean; override;
     property weaponid: word read fstruct.itemid;
     procedure Restart;override;
   end;

   TPowerUpObj = class(TItemObj)
     constructor Create(struct_:TMapObjStruct);
      private
         startwaitlo, startwaithi: integer;
         waitlo, waithi: integer;
    public
     sound2, sound3, wearoffsound: TSound;
     function Activate(sender: TObject): boolean; override;
     procedure Restart; override;
     function Take(sender: TObject; count: integer):boolean; override;
   end;

//при крейте оружие прописывается сюда. попадает один объект от каждого оружия,
//либо не одного если его на карте нету
var
 WeaponObjs  : array [0..WPN_Count - 1] of TWeaponObj;
 PowerUpObjs : array [REGEN_ID..INV_ID] of TPowerUpObj;

function WeaponExists(weap: Word): boolean;

procedure ClearItems;

implementation

uses
 Player_Lib;
 
procedure ClearItems; 
begin 
FillChar(WeaponObjs, sizeof(WeaponObjs), 0);
FillChar(PowerUpObjs, sizeof(PowerUpObjs), 0);
end;

function WeaponExists(weap: Word): boolean;
begin
Result := WeaponObjs[weap] <> nil;
end;

{ TItemObj }

constructor TItemObj.Create(struct_: TMapObjStruct);
begin
inherited;
FObjRect      := Rect(X*32, Y*16, 32, 16);
FActivateRect := Rect(2, 2, 28, 12);
fNetSize		  := 1;
end;

function TItemObj.Activate(sender: TObject): boolean;
begin
Result := false;
if (sender is TPlayer) and spawned then
 if Take(sender, Itemcount) then
  begin
  		if Sound <> nil then
   		Sound.Play(TPlayer(sender).Pos.X, TPlayer(sender).Pos.Y);
  		timer   := struct.wait*50;
  		spawned := false;
  		Result := true;
  end;

if sender = nil then
 begin
 if timer = 32 then timer := 31;
 Result := not spawned;
 end;
end;

procedure TItemObj.Restart;
begin
timer := fstruct.waittarget*50;
if (fstruct.active > 0) and (timer < 32) then timer := 32;
spawned := timer = 0;
end;

procedure TItemObj.Draw;
var
 delta: integer;
 s    : single;
begin
if spawned or (timer < 32) then
 begin
 if timer > 0 then
  delta := 32 - timer
 else
  delta := 32;

 xglTex_Enable(anim.CurFrame);
 glColor4f(1, 1, 1, 1);
 glPushMatrix;
 s := delta/32;
 FObjRect.Width  := trunc(s * 32);
 FObjRect.Height := trunc(s * 16);
 s := 1 - s;
 glTranslate(s * 16, Z + s * 8, 0);
 inherited;
 glPopMatrix;
 end;
end;

function TItemObj.Take(sender: TObject; count: integer): boolean;
begin
Result := true;
end;

procedure TItemObj.Update;
begin
// XProger: Вот так управляем вращением/качанием итемсов
if spawned or (timer < 32) then
 begin
 if r_item_amplitude > 0 then
  begin
  ang := ang + 0.1;
  Z := round(sin(ang)*r_item_amplitude - r_item_amplitude);
  end
 else
  Z := 0;
 if r_item_rotate then
  anim.Update
 else
  anim.FrameIndex := 0;
 end;

if timer > 1 then
 begin
 // timer = 16 - итем не респаунится если он должен быть включен
 if (timer <> 32) or (fstruct.active = 0) then
  dec(timer);
 end
else
 if timer > 0 then
  begin
  if spawnsound <> nil then
   spawnsound.Play(X, Y);
  timer   := 0;
  spawned := true;
  end;

inherited;
end;

procedure TItemObj.LoadFromRec(rec: TDemoObjRec);
begin
   spawned:=Boolean(rec.reserved[0]);
   timer:=rec.reserved[1];
end;

function TItemObj.SaveToRec(var rec: TDemoObjRec): boolean;
begin
   Result:=true;
   rec.reserved[0]:=Word(spawned);
   rec.reserved[1]:=timer;
end;

procedure TItemObj.LoadNet(w: array of word);
begin
   timer:=w[0];
   spawned:=timer=0;
end;

procedure TItemObj.SaveNet(var w: array of word);
begin
   w[0]:=timer;
end;

{ TArmorObj }

constructor TArmorObj.Create(struct_: TMapObjStruct);
begin
inherited;
 case struct.ItemID of
  Shard_ID    : anim := TObjTex.Create('textures\items\shard', 2, 0, 4, true, false, nil);
  Armor50_ID  : anim := TObjTex.Create('textures\items\armor50', 2, 0, 4, true, false, nil);
  Armor100_ID : anim := TObjTex.Create('textures\items\armor100', 2, 0, 4, true, false, nil);
 end;

 case struct.ItemID of
  Shard_ID    : sound := TSound.Create('sound\shard.wav', false);
  Armor50_ID  : sound := TSound.Create('sound\armor.wav', false);
  Armor100_ID : sound := TSound.Create('sound\armor.wav', false);
 end;
end;

procedure TArmorObj.restart;
begin
   with FStruct do
   begin
      if (wait = 0) or (phys_itemmode=1) then
   case ItemID of
      Shard_ID    : wait:=ShardWait;
      Armor50_ID  : wait:=Armor50Wait;
      Armor100_ID : wait:=Armor100Wait;
   end;
   if (itemcount = 0) or (phys_itemmode=1) then
      itemcount := Armors[ItemID];
   end;
  inherited;
end;

function TArmorObj.Take(sender: TObject; count: integer): boolean;
begin
if sender is TPlayer then
 Result := TPlayer(sender).TakeArmor(count)
else
 Result := false;
end;

{ THealthObj }

constructor THealthObj.Create(struct_: TMapObjStruct);
begin
inherited;
 case struct.ItemID of
  Health5_ID   : anim := TObjTex.Create('textures\items\health5', 2, 0, 2, true, false, nil);
  Health25_ID  : anim := TObjTex.Create('textures\items\health25', 2, 0, 2, true, false, nil);
  Health50_ID  : anim := TObjTex.Create('textures\items\health50', 2, 0, 2, true, false, nil);
  Health100_ID : anim := TObjTex.Create('textures\items\health100', 2, 0, 4, true, false, nil);
 end;

 case struct.ItemID of
  Health5_ID   : sound := TSound.Create('sound\health5.wav', false);
  Health25_ID  : sound := TSound.Create('sound\health25.wav', false);
  Health50_ID  : sound := TSound.Create('sound\health50.wav', false);
  Health100_ID : sound := TSound.Create('sound\health100.wav', false);
 end;

end;

procedure THealthObj.restart;
begin
with FStruct do
 begin
 if (wait = 0) or (phys_itemmode=1) then
  case ItemID of
   Health5_ID   : wait := Health5Wait;
   Health25_ID  : wait := Health25Wait;
   Health50_ID  : wait := Health50Wait;
   Health100_ID : wait := Health100Wait;
  end;

 if (itemcount = 0) or (phys_itemmode=1) then
  itemcount := Healthes[ItemID];

 end;
  inherited;
end;

function THealthObj.Take(sender: TObject; count: integer): boolean;
begin
if sender is TPlayer then
 Result := TPlayer(sender).TakeHealth(count)
else
 Result := false;
end;

{ TAmmoObj }

constructor TAmmoObj.Create(struct_: TMapObjStruct);
begin
inherited;
with struct do
 begin
 if weaponID = 0 then
  WeaponID := itemID - 7;
 anim  := TObjTex.Create('textures\weapons\ammo' + IntToStr(weaponID), 2, 0, 5, true, false, nil);
 sound := TSound.Create('sound\weapons\ammopkup.wav', false);
 end;
  // XProger: special for BOOBL!K :)
  FObjRect.x:=FObjRect.X-4;
  FObjRect.Width:=FObjRect.Width+8;
  FObjRect.y:=FObjRect.Y-2;
  FObjRect.Height:=FObjRect.Height+4;
  {
  FObjRect.x:=FObjRect.X-4;
  FObjRect.Width:=FObjRect.Width+8;
  FObjRect.y:=FObjRect.Y-2;
  FObjRect.Height:=FObjRect.Height+4;
  }
end;

procedure TAmmoObj.restart;
begin
  with fstruct do
  begin
   if (wait = 0) or (phys_itemmode=1) then
      wait := Ammo_Wait;
   if (count = 0) or (phys_itemmode=1) then
      count := Ammo_Box[WeaponID];
 end;
  inherited;
end;

function TAmmoObj.Take(sender: TObject; count: integer): boolean;
begin
Take := TPlayer(sender).TakeAmmo(struct.weaponID, count);
end;

{ TWeaponObj }

constructor TWeaponObj.create(struct_: TMapObjStruct);
var
 tex : TFrameObj;
 str : string;
 buf : TTexData;
 msk : PByteArray;
 w, h, k: integer;
begin
inherited;
with struct do
 begin
// if weaponID = 0 then
//    WeaponID := itemID + 1;
//ПРОПИСЫВАЕМ ЧТО ДАННОЕ ОРУЖИЕ СУЩЕСТВУЕТ НА КАРТЕ
 WeaponObjs[WeaponID] := Self;
 ItemID:=WeaponID;

 if not (weaponID in [WPN_GAUNTLET, WPN_MACHINEGUN]) then
  begin
  sound := TSound.Create('sound\weapons\wpkup.wav', false);
  anim  := TObjTex.Create('textures\weapons\weap' + IntToStr(weaponID), 2, 0, 5, true, false, nil);
  end;

 str := '';
 // XProger: немного изменил
 // Neoff: ну а я ещё чуть-чуть.
 case weaponID of
  WPN_GAUNTLET:
   begin
   str := 'textures\weapons\gauntlet';
   FIREanim   := TObjTex.Create(str, 2, 0, 4, true, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\gauntl_r1.wav', true);
   FIREsound2 := TSound.Create('sound\weapons\gauntl_a.wav', false); //постоянный звук
   end;

  WPN_MACHINEGUN :
   begin
   str := 'textures\weapons\machinegun';
   FIREanim   := TObjTex.Create(str, 32, 16, 3, true, false, nil);
   SHOTanim   := TObjTex.Create('textures\sprites\gunspark', 1, 0, 8, true, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\machine.wav', false);
   end;

  WPN_SHOTGUN :
   begin
   str := 'textures\weapons\shotgun';
   FIREanim   := TObjTex.Create(str, 2, 0, 3, true, false, nil);
   SHOTanim   := TObjTex.Create('textures\sprites\gunspark', 1, 0, 5, true, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\shotgun.wav', false);
   end;

  WPN_GRENADE :
   begin
   str := 'textures\weapons\grenade';
   FIREanim   := TObjTex.Create(str, 2, 0, 3, true, false, nil);
   SHOTanim   := TObjTex.Create('textures\weapons\shot\grenade', 0, 0, 3, true, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\grenade.wav', false);
   FIREsound2 := TSound.Create('sound\weapons\bounce.wav', false);
   end;

  WPN_ROCKET :
   begin
   str := 'textures\weapons\rocket';
   FIREanim   := TObjTex.Create(str, 2, 0, 3, true, false, nil);
   SHOTanim   := TObjTex.Create('textures\weapons\shot\rocket', 0, 0, 3, true, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\rocket.wav', false);
   FIREsound2 := TSound.Create('sound\weapons\rockfly.wav', true);
   end;

  WPN_SHAFT :
   begin
   str := 'textures\weapons\lighting';
   FIREanim   := TObjTex.Create(str, 2, 0, 3, true, false, nil);
   SHOTanim   := TObjTex.Create('textures\weapons\shot\shaft', 1, 0, 3, false, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\lg_hum.wav', true);
   FIREsound2 := TSound.Create('sound\weapons\lg_start.wav', false);
   end;

  WPN_RAILGUN :
   begin
   str := 'textures\weapons\railgun';
   FIREanim   := TObjTex.Create(str, 2, 0, 3, true, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\rail.wav', false);
   end;

  WPN_PLASMA :
   begin
   str := 'textures\weapons\plasma';
   FIREanim   := TObjTex.Create(str, 2, 0, 3, true, false, nil);
   SHOTanim   := TObjTex.Create('textures\weapons\shot\plasma', 0, 0, 3, true, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\plasma.wav', false);
   end;

  WPN_BFG :
   begin
   str := 'textures\weapons\bfg';
   FIREanim   := TObjTex.Create(str, 2, 0, 3, true, false, nil);
   SHOTanim   := TObjTex.Create('textures\weapons\shot\bfg', 0, 0, 3, true, false, nil);
   FIREsound1 := TSound.Create('sound\weapons\bfg.wav', false);
   end;
  end;

 str := Engine_ModDir + str;
 tex := TexExists('Weapon * mask ' + IntToStr(weaponID));
 if tex <> nil then
  begin
  Mask := TObjTex.Create;
  Mask.Tex := tex;
  tex.flag := true;
  end
 else
  begin
  buf.Trans  := true;
  buf.TransC := RGBA(0, 0, 255, 0);
  if xglTex_LoadData(PChar(str), @buf) then
   begin
   GetMem(msk, buf.Height*buf.Width);
   for h := 0 to buf.Height - 1 do
    for w := 0 to buf.Width - 1 do
     begin
     k := h*buf.Width + w;
     msk[k] := PaRGBA(buf.Data)[k].A;
     end;
   Mask := TObjTex.Create('Weapon * mask ' + IntToStr(weaponID), buf.Width, buf.Height, 0, true, false, nil, 0, msk, 8, FIREanim.FrameCount);
   FreeMem(msk);
   xglTex_FreeData(@buf);
   end;
  end;
 end;
end;

procedure TWeaponObj.Restart;
begin
  inherited;
  with fstruct do
  begin
 if (wait = 0) or (phys_itemmode=1) then
  wait := WPN_Wait[WeaponID];
 if (count = 0) or (phys_itemmode=1) then
  count := Def_Ammo[WeaponID];
 ItemCount := Count;
 end;
end;

function TWeaponObj.Take(sender: TObject; count: integer): boolean;
begin
	Result := TPlayer(sender).TakeWpn(struct.weaponID, count, 1);
end;

{ TPowerUpObj }

function TPowerUpObj.Activate(sender: TObject): boolean;
begin
Result := false;
if (sender is TPlayer) and spawned then
 if Take(sender, Itemcount) then
  begin
  if Sound <> nil then
   Sound.Play(TPlayer(sender).Pos.X, TPlayer(sender).Pos.Y);
  timer := ( waitlo+random(waithi-waitlo+1) ) * 50;
  spawned := false;

  fupdated:=true;
  Result := true;
  end;

if sender = nil then
 begin
 if timer = 32 then timer := 15;
 Result := not spawned;
 end;
end;

constructor TPowerUpObj.Create(struct_: TMapObjStruct);
begin
inherited;
with struct do
 begin
//ПРОПИСЫВАЕМ ЧТО ДАННЫЙ POWERUP СУЩЕСТВУЕТ НА КАРТЕ
   PowerUpObjs[ItemID] := Self;

// Подгрузка графики
 case ItemID of
  REGEN_ID      : anim := TObjTex.Create('textures\powerups\regeneration', 2, 0, 3, true, false, @clblack);
  BATTLESUIT_ID : anim := TObjTex.Create('textures\powerups\battlesuit', 2, 0, 3, true, false, @clblack);
  HASTE_ID      : anim := TObjTex.Create('textures\powerups\haste', 2, 0, 3, true, false, @clblack);
  QUAD_ID       : anim := TObjTex.Create('textures\powerups\quaddamage', 2, 0, 3, true, false, @clblack);
  FLIGHT_ID     : anim := TObjTex.Create('textures\powerups\flight', 2, 0, 3, true, false, @clblack);
  INV_ID        : anim := TObjTex.Create('textures\powerups\invisibility', 2, 0, 3, true, false, @clblack);
 end;
// Подгрузка звука
 case ItemID of
  REGEN_ID      : sound := TSound.Create('sound\powerups\regeneration.wav', false, true);
  BATTLESUIT_ID : sound := TSound.Create('sound\powerups\battlesuit.wav', false, true);
  HASTE_ID      : sound := TSound.Create('sound\powerups\haste.wav', false, true);
  QUAD_ID       : sound := TSound.Create('sound\powerups\quaddamage.wav', false, true);
  FLIGHT_ID     : sound := TSound.Create('sound\powerups\flight.wav', false, true);
  INV_ID        : sound := TSound.Create('sound\powerups\invisibility.wav', false, true);
 end;
// Подгрузка звука 2 - КОГДА INSTANT POWERUP кончается
 case ItemID of
   QUAD_ID       : sound2 := TSound.Create('sound\powerups\damage2.wav', false);
 end;
// Подгрузка звука 3 - КОГДА INSTANT POWERUP действует
 case ItemID of
  REGEN_ID       : sound3 := TSound.Create('sound\powerups\regen.wav', false);
  BATTLESUIT_ID  : sound3 := TSound.Create('sound\powerups\protect3.wav', false);
  QUAD_ID        : sound3 := TSound.Create('sound\powerups\damage3.wav', false);
  FLIGHT_ID      : sound3 := TSound.Create('sound\powerups\flight.wav', true);
 end;

 wearoffsound := TSound.Create('sound\powerups\wearoff.wav', false);
 spawnsound := TSound.Create('sound\powerups\poweruprespawn.wav', false);
 end;
end;

procedure TPowerUpObj.Restart;
begin
inherited;

with fstruct do
begin
   if phys_itemmode=0 then
   begin
      startwaitlo:=fstruct.waittarget;
      startwaithi:=fstruct.waittarget;
      waitlo:=fstruct.waittarget;
      waithi:=fstruct.waittarget;
   end else
   begin
      startwaitlo:=POWERUP_STARTWAIT_LO;
      startwaithi:=POWERUP_STARTWAIT_HI;
      waitlo:=POWERUP_WAIT_LO;
      waithi:=POWERUP_WAIT_HI;
   end;
end;

if fstruct.active=0 then
   timer := ( startwaitlo+random(startwaithi-startwaitlo+1) )*50
else timer:=32;
spawned := timer = 0;
fupdated:=true;
end;


function TPowerUpObj.Take(sender: TObject; count: integer): boolean;
begin
   Result:=false;
   if sender is TPlayer then
   	Result:=TPlayer(sender).TakePowerUp(fstruct.ItemID, count*50)
end;

end.
