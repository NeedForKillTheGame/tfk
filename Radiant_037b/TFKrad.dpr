program TFKrad;

uses
  Forms,
  main in 'main.pas' {MainForm},
  TFKEntries in 'TFKEntries.pas',
  MapObj_Lib in 'MapObj_Lib.pas',
  NFKMap_Lib in 'NFKMap_Lib.pas',
  MyScroll in 'MyScroll.pas',
  MyPalette in 'MyPalette.pas',
  ClickPs in 'ClickPs.pas',
  Constants_Lib in 'Constants_Lib.pas',
  bzLib in 'bz\bzLib.pas',
  PowerAcrModuleInfo in 'bz\PowerAcrModuleInfo.pas',
  PowerArc in 'bz\PowerArc.pas',
  ObjectProps in 'ObjectProps.pas' {ObjPropFrm},
  ObjButtonProps in 'ObjButtonProps.pas' {ObjButtonProp},
  ObjRespawnProps in 'ObjRespawnProps.pas' {ObjRespawnProp},
  ObjJumppadProps in 'ObjJumppadProps.pas' {ObjJumppadProp},
  ObjElevatorProps in 'ObjElevatorProps.pas' {ObjElevatorProp},
  MapProps in 'MapProps.pas' {MapPropsFrm},
  ObjDeathlineProps in 'ObjDeathlineProps.pas' {ObjDeathLineProp},
  ObjItemProps in 'ObjItemProps.pas' {ObjItemProp},
  ObjAreaPainProps in 'ObjAreaPainProps.pas' {ObjAreaPainProp},
  ObjAreaPushProps in 'ObjAreaPushProps.pas' {ObjAreaPushProp},
  ObjBGProps in 'ObjBGProps.pas' {ObjBgProp},
  MyEntries in 'MyEntries.pas',
  ObjLightLineProps in 'ObjLightLineProps.pas' {ObjLightLineProp},
  about in 'about.pas' {AboutBox},
  ObjBloodGenProps in 'ObjBloodGenProps.pas' {ObjBloodGenProp},
  LightMap_Lib in 'LightMap_Lib.pas',
  LightMapGen in 'LightMapGen.pas' {LMFrm},
  MapGen in 'MapGen.pas' {GenMapFrm},
  Generate_Lib in 'Generate_Lib.pas',
  ObjWeatherProps in 'ObjWeatherProps.pas' {ObjWeatherProp},
  WP in 'WP.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'TFK Radiant';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TObjPropFrm, ObjPropFrm);
  Application.CreateForm(TObjButtonProp, ObjButtonProp);
  Application.CreateForm(TObjRespawnProp, ObjRespawnProp);
  Application.CreateForm(TObjJumppadProp, ObjJumppadProp);
  Application.CreateForm(TObjElevatorProp, ObjElevatorProp);
  Application.CreateForm(TMapPropsFrm, MapPropsFrm);
  Application.CreateForm(TObjDeathLineProp, ObjDeathLineProp);
  Application.CreateForm(TObjItemProp, ObjItemProp);
  Application.CreateForm(TObjAreaPainProp, ObjAreaPainProp);
  Application.CreateForm(TObjAreaPushProp, ObjAreaPushProp);
  Application.CreateForm(TObjBgProp, ObjBgProp);
  Application.CreateForm(TObjLightLineProp, ObjLightLineProp);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TObjBloodGenProp, ObjBloodGenProp);
  Application.CreateForm(TLMFrm, LMFrm);
  Application.CreateForm(TGenMapFrm, GenMapFrm);
  Application.CreateForm(TObjWeatherProp, ObjWeatherProp);
  Application.Run;
end.
