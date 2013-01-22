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
 //Инициализация лога
  procedure Log_Init; stdcall; external EngDLL;
 //Выводить ли в консоль лог
  procedure Log_ConWrite(ConsoleWrite: boolean); stdcall; external EngDLL;
 //Вывод староки в файл/консоль
  procedure Log(Str: ShortString); stdcall; external EngDLL;
 //Вывод сообщения в лог файл и окно консоли
  procedure Log_Console(Str: ShortString); stdcall; external EngDLL;
 //Закрытие файла
  procedure Log_Close; stdcall; external EngDLL;

(*** Engine ***)
 //Версия движка
  function Engine_Version: PChar; stdcall; external EngDLL;
 //Движок закончил свою работу?
  function  Engine_isQuit: boolean; stdcall; external EngDLL;
 //Закончить работу движка (выход из программы)
  procedure  Engine_Quit; stdcall; external EngDLL;
 // обнуление счётчика апдейтов (таймера)
  procedure Engine_FlushTimer; stdcall; external EngDLL;
 //Поиск модов
  procedure Engine_FindMods; stdcall; external EngDLL;
 //Выдаёт количество найденных модов
  function Engine_ModCount: integer; stdcall; external EngDLL;
 //Выдаёт информацию о моде
  function Engine_GetMod(ModNum: integer; var ModData: TMod): boolean; stdcall; external EngDLL;
 //Номер текущего мода
  function Engine_CurMod: integer; stdcall; external EngDLL;
 //Название текущего мода
  function Engine_ModName: ShortString; stdcall; external EngDLL;
 //путь к папке мода\
  function Engine_ModDir: ShortString; stdcall; external EngDLL;
 //путь к папке движка\
  function Engine_Dir: ShortString; stdcall; external EngDLL;
 //Смена мода на мод под номером ModNum
  function Engine_ChangeMod(ModNum: integer):  boolean; stdcall; external EngDLL;
 //Запрос на смену мода
  function Engine_ChangeModQuery(ModNum: integer):  boolean; stdcall; external EngDLL;
 //Активно ли окно
  function Engine_isActive: boolean; stdcall; external EngDLL;
 // Установить количество одновлений в секунду (1..499)
  procedure Engine_SetUPS(UPS: WORD); stdcall; external EngDLL;
 // Узнать число обновлений в секунду
  function Engine_GetUPS: WORD; stdcall; external EngDLL;
(*** Console ***)
 //Получаем указатель на свойства(параметры) консоли
  function Console_Prop: PConsoleProp; stdcall; external EngDLL;
 //Устанавливаем процедуру конфига
  procedure Console_SetCfgProc(Proc: pointer); stdcall; external EngDLL;
 //Обработка команды
  function Console_Cmd(Cmd: ShortString): boolean; stdcall; external EngDLL;
 //Регистрация команды
  procedure Console_CmdReg(Cmd: ShortString; Proc: PConsoleCmdProc); stdcall; external EngDLL;
 //Регистрация "самостоятельной" команды
  procedure Console_CmdRegEx(Name     : ShortString;
                             Variable : pointer;
                             VarType  : TVarType;
                             min, max : integer;
                             cfgProc  : boolean = false); stdcall; external EngDLL;
 //Добавление строки в консоль
  procedure Console_Msg(Msg: ShortString); stdcall; external EngDLL;
 //Удаление строки строки в консоль
  procedure Console_DeleteMsg(i: integer); stdcall; external EngDLL;
 //Найти переменную по её имени (nil - если таковой не имеется)
  function Console_GetVar(VarName: ShortString): pointer; stdcall; external EngDLL;

(*** XGL ****)
 //Параметры экрана
  procedure xglViewport(X, Y: SmallInt; Width, Height: WORD; Perspective: boolean); stdcall; external EngDLL;
  procedure xglChangePerspective; stdcall; external EngDLL;
 //Ширина экрана
  function xglWidth: WORD; stdcall; external EngDLL;
 //Высота экрана
  function xglHeight: WORD; stdcall; external EngDLL;
 //Глубина цвета
  function xglDisBPP: Byte; stdcall; external EngDLL;
 //Частота монитора
  function xglDisFreq: WORD; stdcall; external EngDLL;
 //Очистка всего
  procedure xglClear; stdcall; external EngDLL;
 //Всё что нарисованно на экран
  procedure xglSwap; stdcall; external EngDLL;
 //Смена видео режима
  function  xglChangeMode(FullScreen: boolean; Width, Height: integer; BPP: Byte; Freq: Byte): boolean; stdcall; external EngDLL;
 //Играем в FullScreen режиме?
  function xglisFullScreen: boolean; stdcall; external EngDLL;
 //Какой вид примитива рисуем?
  function xglGetMode: SmallInt; stdcall; external EngDLL;
 //Начать отрисовку
  procedure xglBegin(Mode: SmallInt); stdcall; external EngDLL;
 //Закончить отрисовку
  procedure xglEnd; stdcall; external EngDLL;
 //Тип альфа смешивания
  procedure xglAlphaBlend(_type: Byte); stdcall; external EngDLL;
 // Установить яркость дисплея
  procedure xglGamma_Set(gamma: integer); stdcall; external EngDLL;
 // Узнать яркость дисплея
  function xglGamma_Get: integer; stdcall; external EngDLL;

(*** Texture ***)
 //Загрузка данных изображения без создания текстуры
  function xglTex_LoadData(FileName: PChar; TexData: PTexData): boolean; stdcall; external EngDLL;
 //Высвобождение памяти под данные
  procedure xglTex_FreeData(TexData: PTexData); stdcall; external EngDLL;
 //Загрузка данных изображения c созданием текстуры
  function xglTex_Load(FileName: PChar; TexData: PTexData): boolean; stdcall; external EngDLL;
 //Создание текстуры по данным изображения
  procedure xglTex_Create(TexData: PTexData); stdcall; external EngDLL;
 //Удаление текстуры из памяти
  procedure xglTex_Free(TexData: PTexData); stdcall; external EngDLL;
 //Приметить текстуру (сделать текущей)
  procedure xglTex_Enable(TexData: PTexData); stdcall; external EngDLL;
 //Не использовать текстуру
  procedure xglTex_Disable; stdcall; external EngDLL;
 // Скриншот в 24 битном цвете :) (Quality - только для jpg)
  function xglScreenShot(FileName: PChar): boolean; stdcall; external EngDLL;
 // пишется ли "видео"
  function xglWriteAVI: Byte; stdcall; external EngDLL;
(*** Sprite ***)
 //Вывод прямоугольного спрайта
  procedure Sprite_Draw(Source, Dest: TRect;
                        TexData: PTexData); stdcall; external EngDLL;
(*** Clipboard ***)
 //Читаем текст (256 символов) из буффера обмена
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
 // Начало обновления-подгрузки
  procedure snd_BeginUpdate; stdcall; external EngDLL;
 // Окончание. Те что не нужны удаляются из списка
  procedure snd_EndUpdate; stdcall; external EngDLL;
 // Загрузка звука из wav файла
  function snd_Load(FileName : PChar): integer; stdcall; external EngDLL;
 // Удаление сэмпла из памяти
  function snd_Free(Sample_ID: integer): boolean; stdcall; external EngDLL;
 // Начать проигрывание
  function snd_Play(Sample_ID: integer; Loop: boolean; X, Y: single; bind: boolean = false; psnd: pointer = nil): integer; stdcall; external EngDLL;
 // Остановить
  function snd_Stop(Channel_ID: integer): boolean; stdcall; external EngDLL;
 // Остновить проигрывание всех звуков этого типа (0 - остановить все)
  procedure snd_StopAll(Sound_ID: integer); stdcall; external EngDLL;
 // Уровень громкости канала
  function snd_SetVolume(Channel_ID: integer; Volume: integer): boolean; stdcall; external EngDLL;
 // Позиция нахождения источника звучания/канала
  function snd_SetPos(Channel_ID: integer; Pos: TPoint2f): boolean; stdcall; external EngDLL;
 // Частота звука
  function snd_SetFreq(Channel_ID: integer; Freq: DWORD): boolean; stdcall; external EngDLL;
 // Позиция "ушей" в 3д пространстве
  procedure snd_SetGlobalPos(Pos: TPoint2f); stdcall; external EngDLL;
 // Music всё что держит MediaPlayer! Даже avi :)
 // начать проигрывание
  function mus_Play(FileName : PChar): integer; stdcall; external EngDLL;
 // Повторить
  function mus_RePlay(music_id: WORD): boolean; stdcall; external EngDLL;
 // остановить проигрывание
  procedure mus_Stop(music_id: WORD); stdcall; external EngDLL;

(*** NET ***)
 //Инициализация сетевого протокола
  function NET_Init: boolean; stdcall; external EngDLL;
 // Создание сокета
  function NET_InitSocket(Port: WORD): integer; stdcall; external EngDLL;
 //Освобождение ресурсов под сеть
  procedure NET_Free; stdcall; external EngDLL;
 //IP компьютера в локальной сети
  function NET_GetLocalIP: PChar; stdcall; external EngDLL;
 //IP компьютера в интернете
  function NET_GetExternalIP: PChar; stdcall; external EngDLL;
 //Даёт имя компьютера в сети
  function NET_GetHost: PChar; stdcall; external EngDLL;
 // Даёт IP по хосту
  function NET_HostToIP(Host: PChar): PChar; stdcall; external EngDLL;
 //Очистка буфера
  procedure NET_Clear; stdcall; external EngDLL;
 //Очистка APL буфера
  procedure NET_ClearAPL; stdcall; external EngDLL;
 //Записать данные buf длиной Count байт в буфер
  function NET_Write(Buf: pointer; Count: integer): boolean; stdcall; external EngDLL;
 //Прочитать следующий пакет из буфера (-1 при пустом буфере)
  function NET_Recv(Buf: pointer; Count: integer; var IP: PChar; var Port: integer): integer; stdcall; external EngDLL;
 //Послать пакет (данные из буфера) по указанному IP и Port
  function NET_Send(IP: PChar; Port: WORD; APL: boolean): integer; stdcall; external EngDLL;
 //Обновление состояния сетевого протокола движка (автоматически вызывается раз в тик)
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
