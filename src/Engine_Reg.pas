unit Engine_Reg;
(*******************************)
(*<<< XEngine v0.41 header  >>>*)
(*******************************)
(* Created by XProger          *)
(* begin : 29.10.2003          *)
(* end   : 07.03.2005          *)
(*******************************)
(* site : www.XProger.narod.ru *)
(* mail : XProger@list.ru      *)
(*******************************)
interface

uses
 Windows, Graph_Lib, Type_Lib;

const
 EngDLL = 'XEngine.dll';

(*** Log ***)
 //������������� ����
  procedure Log_Init; stdcall; external EngDLL;
 //�������� �� � ������� ���
  procedure Log_ConWrite(ConsoleWrite: boolean); stdcall; external EngDLL;
 //����� ������� � ����/�������
  procedure Log(Str: ShortString); stdcall; external EngDLL;
 //����� ��������� � ��� ���� � ���� �������
  procedure Log_Console(Str: ShortString); stdcall; external EngDLL;
 //�������� �����
  procedure Log_Close; stdcall; external EngDLL;

(*** Engine ***)
 //������ ������
  function Engine_Version: PChar; stdcall; external EngDLL;
 //������ �������� ���� ������?
  function  Engine_isQuit: boolean; stdcall; external EngDLL;
 //��������� ������ ������ (����� �� ���������)
  procedure  Engine_Quit; stdcall; external EngDLL;
 // ��������� �������� �������� (�������)
  procedure Engine_FlushTimer; stdcall; external EngDLL;
 //����� �����
  procedure Engine_FindMods; stdcall; external EngDLL;
 //����� ���������� ��������� �����
  function Engine_ModCount: integer; stdcall; external EngDLL;
 //����� ���������� � ����
  function Engine_GetMod(ModNum: integer; var ModData: TMod): boolean; stdcall; external EngDLL;
 //����� �������� ����
  function Engine_CurMod: integer; stdcall; external EngDLL;
 //�������� �������� ����
  function Engine_ModName: ShortString; stdcall; external EngDLL;
 //���� � ����� ����\
  function Engine_ModDir: ShortString; stdcall; external EngDLL;
 //���� � ����� ������\
  function Engine_Dir: ShortString; stdcall; external EngDLL;
 //����� ���� �� ��� ��� ������� ModNum
  function Engine_ChangeMod(ModNum: integer):  boolean; stdcall; external EngDLL;
 //������ �� ����� ����
  function Engine_ChangeModQuery(ModNum: integer):  boolean; stdcall; external EngDLL;
 //������� �� ����
  function Engine_isActive: boolean; stdcall; external EngDLL;
 // ���������� ���������� ���������� � ������� (1..499)
  procedure Engine_SetUPS(UPS: WORD); stdcall; external EngDLL;
 // ������ ����� ���������� � �������
  function Engine_GetUPS: WORD; stdcall; external EngDLL;
(*** Console ***)
 //�������� ��������� �� ��������(���������) �������
  function Console_Prop: PConsoleProp; stdcall; external EngDLL;
 //������������� ��������� �������
  procedure Console_SetCfgProc(Proc: pointer); stdcall; external EngDLL;
 //��������� �������
  function Console_Cmd(Cmd: ShortString): boolean; stdcall; external EngDLL;
 //����������� �������
  procedure Console_CmdReg(Cmd: ShortString; Proc: PConsoleCmdProc); stdcall; external EngDLL;
 //����������� "���������������" �������
  procedure Console_CmdRegEx(Name     : ShortString;
                             Variable : pointer;
                             VarType  : TVarType;
                             min, max : integer;
                             cfgProc  : boolean = false); stdcall; external EngDLL;
 //���������� ������ � �������
  procedure Console_Msg(Msg: ShortString); stdcall; external EngDLL;
 //�������� ������ ������ � �������
  procedure Console_DeleteMsg(i: integer); stdcall; external EngDLL;
 //����� ���������� �� � ����� (nil - ���� ������� �� �������)
  function Console_GetVar(VarName: ShortString): pointer; stdcall; external EngDLL;

(*** XGL ****)
 //��������� ������
  procedure xglViewport(X, Y: SmallInt; Width, Height: WORD; Perspective: boolean); stdcall; external EngDLL;
  procedure xglChangePerspective; stdcall; external EngDLL;
 //������ ������
  function xglWidth: WORD; stdcall; external EngDLL;
 //������ ������
  function xglHeight: WORD; stdcall; external EngDLL;
 //������� �����
  function xglDisBPP: Byte; stdcall; external EngDLL;
 //������� ��������
  function xglDisFreq: WORD; stdcall; external EngDLL;
 //������� �����
  procedure xglClear; stdcall; external EngDLL;
 //�� ��� ����������� �� �����
  procedure xglSwap; stdcall; external EngDLL;
 //����� ����� ������
  function  xglChangeMode(FullScreen: boolean; Width, Height: integer; BPP: Byte; Freq: Byte): boolean; stdcall; external EngDLL;
 //������ � FullScreen ������?
  function xglisFullScreen: boolean; stdcall; external EngDLL;
 //����� ��� ��������� ������?
  function xglGetMode: SmallInt; stdcall; external EngDLL;
 //������ ���������
  procedure xglBegin(Mode: SmallInt); stdcall; external EngDLL;
 //��������� ���������
  procedure xglEnd; stdcall; external EngDLL;
 //��� ����� ����������
  procedure xglAlphaBlend(_type: Byte); stdcall; external EngDLL;
 // ���������� ������� �������
  procedure xglGamma_Set(gamma: integer); stdcall; external EngDLL;
 // ������ ������� �������
  function xglGamma_Get: integer; stdcall; external EngDLL;

(*** Texture ***)
 //�������� ������ ����������� ��� �������� ��������
  function xglTex_LoadData(FileName: PChar; TexData: PTexData): boolean; stdcall; external EngDLL;
 //������������� ������ ��� ������
  procedure xglTex_FreeData(TexData: PTexData); stdcall; external EngDLL;
 //�������� ������ ����������� c ��������� ��������
  function xglTex_Load(FileName: PChar; TexData: PTexData): boolean; stdcall; external EngDLL;
 //�������� �������� �� ������ �����������
  procedure xglTex_Create(TexData: PTexData); stdcall; external EngDLL;
 //�������� �������� �� ������
  procedure xglTex_Free(TexData: PTexData); stdcall; external EngDLL;
 //��������� �������� (������� �������)
  procedure xglTex_Enable(TexData: PTexData); stdcall; external EngDLL;
 //�� ������������ ��������
  procedure xglTex_Disable; stdcall; external EngDLL;
 // �������� � 24 ������ ����� :) (Quality - ������ ��� jpg)
  function xglScreenShot(FileName: PChar): boolean; stdcall; external EngDLL;
 // ������� �� "�����"
  function xglWriteAVI: Byte; stdcall; external EngDLL;
(*** Sprite ***)
 //����� �������������� �������
  procedure Sprite_Draw(Source, Dest: TRect;
                        TexData: PTexData); stdcall; external EngDLL;
(*** Clipboard ***)
 //������ ����� (256 ��������) �� ������� ������
  function Clipboard_GetText: ShortString; stdcall; external EngDLL;

(*** Input ***)
  function Input_KeyDown(KeyValue: integer): boolean; stdcall; external EngDLL;
  function Input_KeyNum(KeyName: PChar): integer; stdcall; external EngDLL;
  function Input_KeyName(KeyValue: integer): PChar; stdcall; external EngDLL;
  function Input_LastKey: integer; stdcall; external EngDLL;

  function Input_MouseDown(BtnNum: Byte): boolean; stdcall; external EngDLL;
  function Input_MouseDelta: TPoint; stdcall; external EngDLL;
  function Input_MouseWheelDelta: integer; stdcall; external EngDLL;

  function Input_JoyDown(JoyNum, Button: Byte): boolean; stdcall; external EngDLL;
  procedure Input_JoyPos(JoyNum: Byte; var X, Y, Z: DWORD); stdcall; external EngDLL;
  function Input_JoyPosX(JoyNum: Byte): DWORD; stdcall; external EngDLL;
  function Input_JoyPosY(JoyNum: Byte): DWORD; stdcall; external EngDLL;
  function Input_JoyPosZ(JoyNum: Byte): DWORD; stdcall; external EngDLL;

(*** SOUND ***)
 // ������ ����������-���������
  procedure snd_BeginUpdate; stdcall; external EngDLL;
 // ���������. �� ��� �� ����� ��������� �� ������
  procedure snd_EndUpdate; stdcall; external EngDLL;
 // �������� ����� �� wav �����
  function snd_Load(FileName : PChar): integer; stdcall; external EngDLL;
 // �������� ������ �� ������
  function snd_Free(Sample_ID: integer): boolean; stdcall; external EngDLL;
 // ������ ������������
  function snd_Play(Sample_ID: integer; Loop: boolean; X, Y: single; bind: boolean = false; psnd: pointer = nil): integer; stdcall; external EngDLL;
 // ����������
  function snd_Stop(Channel_ID: integer): boolean; stdcall; external EngDLL;
 // ��������� ������������ ���� ������ ����� ���� (0 - ���������� ���)
  procedure snd_StopAll(Sound_ID: integer); stdcall; external EngDLL;
 // ������� ��������� ������
  function snd_SetVolume(Channel_ID: integer; Volume: integer): boolean; stdcall; external EngDLL;
 // ������� ���������� ��������� ��������/������
  function snd_SetPos(Channel_ID: integer; Pos: TPoint2f): boolean; stdcall; external EngDLL;
 // ������� �����
  function snd_SetFreq(Channel_ID: integer; Freq: DWORD): boolean; stdcall; external EngDLL;
 // ������� "����" � 3� ������������
  procedure snd_SetGlobalPos(Pos: TPoint2f); stdcall; external EngDLL;
 // Music �� ��� ������ MediaPlayer! ���� avi :)
 // ������ ������������
  function mus_Play(FileName : PChar): integer; stdcall; external EngDLL;
 // ���������
  function mus_RePlay(music_id: WORD): boolean; stdcall; external EngDLL;
 // ���������� ������������
  procedure mus_Stop(music_id: WORD); stdcall; external EngDLL;

(*** NET ***)
 //������������� �������� ���������
  function NET_Init: boolean; stdcall; external EngDLL;
 // �������� ������
  function NET_InitSocket(Port: WORD): integer; stdcall; external EngDLL;
 //������������ �������� ��� ����
  procedure NET_Free; stdcall; external EngDLL;
 //IP ���������� � ��������� ����
  function NET_GetLocalIP: PChar; stdcall; external EngDLL;
 //IP ���������� � ���������
  function NET_GetExternalIP: PChar; stdcall; external EngDLL;
 //��� ��� ���������� � ����
  function NET_GetHost: PChar; stdcall; external EngDLL;
 // ��� IP �� �����
  function NET_HostToIP(Host: PChar): PChar; stdcall; external EngDLL;
 //������� ������
  procedure NET_Clear; stdcall; external EngDLL;
 //������� APL ������
  procedure NET_ClearAPL; stdcall; external EngDLL;
 //�������� ������ buf ������ Count ���� � �����
  function NET_Write(Buf: pointer; Count: integer): boolean; stdcall; external EngDLL;
 //��������� ��������� ����� �� ������ (-1 ��� ������ ������)
  function NET_Recv(Buf: pointer; Count: integer; var IP: PChar; var Port: integer): integer; stdcall; external EngDLL;
 //������� ����� (������ �� ������) �� ���������� IP � Port
  function NET_Send(IP: PChar; Port: WORD; APL: boolean): integer; stdcall; external EngDLL;
 //���������� ��������� �������� ��������� ������ (������������� ���������� ��� � ���)
  procedure NET_Update; stdcall; external EngDLL;

(*** Font ***)
  function Font_Create(FileName: PChar; Font: PTexData): boolean; stdcall; external EngDLL;
  procedure Font_Free(Font: PTexData); stdcall; external EngDLL;

(*** Text ***)
  function Text_TagOut(X, Y: SmallInt; Font: pointer; Shadow: boolean; Text: PChar): integer; stdcall; external EngDLL;
  procedure TextOut(X, Y: SmallInt; Text: PChar); stdcall; external EngDLL;

(*** Utils ***)
  function Utils_GetCPU: PChar; stdcall; external EngDLL;
  function Utils_GetMemory: DWORD; stdcall; external EngDLL;
  function Utils_CRC32(initCRC: DWORD; Buf: pointer; Size: DWORD): DWORD; stdcall; external EngDLL;

 //Winamp Control
  procedure Winamp_Play; stdcall; external EngDLL;
  procedure Winamp_Pause; stdcall; external EngDLL;
  procedure Winamp_Stop; stdcall; external EngDLL;
  procedure Winamp_Next; stdcall; external EngDLL;
  procedure Winamp_Prev; stdcall; external EngDLL;

implementation

end.
