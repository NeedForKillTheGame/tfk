unit Log_lib;

interface

uses
 Engine_Reg, Func_Lib, Constants_Lib, MapObj_Lib, ItemObj_Lib, Player_Lib;

procedure Log_AddPlayer(p: TPlayer);
procedure Log_RemovePlayer(p: TPlayer);
procedure Log_ChangeName(oldname, newname: str32);
procedure Log_ChangeModel(p: TPlayer);
procedure Log_Kill(UID: integer; killer_UID: integer = -1; weapon: integer = -1);
procedure Log_TeamJoin(pname: string; team: byte);

implementation

uses
 Map_Lib;

procedure Log_AddPlayer(p: TPlayer);
begin
if p <> nil then
 Log(p.Name + ' ^7join the game');
end;

procedure Log_RemovePlayer(p: TPlayer);
begin
Log(p.Name + ' ^7leaves the game');
end;

procedure Log_ChangeName(oldname, newname: str32);
begin
Log(oldname + ' ^7renamed to ' + newname);
end;

procedure Log_ChangeModel(p: TPlayer);
begin
Log(p.Name + ' ^7change model to ' + p.pstruct.modelname);
end;

procedure Log_Kill(UID: integer; killer_UID: integer = -1; weapon: integer = -1);
var
 p, k : TPlayer;
begin
if Map.pl_find(UID, -1) then
 p := Map.pl_current
else
 Exit;

 if (Killer_UID<0) or (UID=killer_UID) then
 begin
    if p.Squished then
       Log(p.Name+' ^n^7was squished')
    else Log(p.Name + ' ^n^7blew himself up');
 end else
if Map.pl_find(killer_UID, -1) then
 begin
 	k := Map.pl_current;
  case weapon of
   WPN_GAUNTLET   : Log(p.Name + ' ^n^7was pummeled by ' + k.Name);
   WPN_MACHINEGUN : Log(p.Name + ' ^n^7was machinegunned by ' + k.Name);
   WPN_SHOTGUN    : Log(p.Name + ' ^n^7was gunned down by ' + k.Name);
   WPN_ROCKET     : Log(p.Name + ' ^n^7ate ' + k.Name + '^n^7''s rocket');
   WPN_PLASMA     : Log(p.Name + ' ^n^7was melted by ' + k.Name + '^n^7''s plasmagun');
   WPN_GRENADE    : Log(p.Name + ' ^n^7was shredded by ' + k.Name + '^n^7''s shrapnel');
   WPN_SHAFT      : Log(p.Name + ' ^n^7was electrocuted by ' + k.Name);
   WPN_RAILGUN    : Log(p.Name + ' ^n^7was railed by ' + k.Name);
   WPN_BFG        : Log(p.Name + ' ^n^7was blasted by ' + k.Name + '^n^7''s bfg');
  end;
 end;
end;

procedure Log_TeamJoin(pname: string; team: byte);
begin
if team = TEAM_BLUE then
 Log(pname + '^n^7 joins blue team')
else
 Log(pname + '^n^7 joins red team');
end;

end.


