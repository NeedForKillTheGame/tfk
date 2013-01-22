object MainForm: TMainForm
  Left = 192
  Top = 107
  Width = 696
  Height = 300
  Caption = 'MainForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object ActionMainMenuBar1: TActionMainMenuBar
    Left = 0
    Top = 0
    Width = 688
    Height = 24
    ActionManager = ActionManager1
    Caption = 'ActionMainMenuBar1'
    ColorMap.HighlightColor = 14410210
    ColorMap.BtnSelectedColor = clBtnFace
    ColorMap.UnusedColor = 14410210
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clMenuText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Spacing = 0
  end
  object ActionManager1: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Items = <
              item
                Action = NewFile1
              end
              item
                Action = FileOpen1
                ImageIndex = 7
                ShortCut = 16463
              end
              item
                Action = FileSaveAs1
                ImageIndex = 30
              end
              item
                Action = FileRun1
              end
              item
                Action = FileExit1
                ImageIndex = 43
              end>
            Caption = '&File'
          end
          item
            Items = <
              item
                Action = CustomizeActionBars1
              end>
            Caption = '&Tools'
          end>
        ActionBar = ActionMainMenuBar1
      end>
    Left = 32
    Top = 48
    StyleName = 'XP Style'
    object NewFile1: TAction
      Category = 'File'
      Caption = '&New'
      Hint = 'New|Create new map'
      OnExecute = NewFile1Execute
    end
    object FileOpen1: TFileOpen
      Category = 'File'
      Caption = '&Open...'
      Hint = 'Open|Opens an existing file'
      ImageIndex = 7
      ShortCut = 16463
      OnAccept = FileOpen1Accept
    end
    object FileSave1: TAction
      Category = 'File'
      Caption = 'Save'
      Hint = 'Save|Saves current file'
      OnExecute = FileSave1Execute
    end
    object FileSaveAs1: TFileSaveAs
      Category = 'File'
      Caption = 'Save &As...'
      Hint = 'Save As|Saves the active file with a new name'
      ImageIndex = 30
      BeforeExecute = FileSaveAs1BeforeExecute
      OnAccept = FileSaveAs1Accept
    end
    object FileRun1: TFileRun
      Category = 'File'
      Browse = False
      BrowseDlg.Title = 'Run'
      Caption = '&Run...'
      Hint = 'Run|Runs an application'
      Operation = 'open'
      ShowCmd = scShowNormal
    end
    object FileExit1: TFileExit
      Category = 'File'
      Caption = 'E&xit'
      Hint = 'Exit|Quits the application'
      ImageIndex = 43
    end
    object CustomizeActionBars1: TCustomizeActionBars
      Category = 'Tools'
      Caption = '&Customize'
      ActionManager = ActionManager1
      CustomizeDlg.StayOnTop = False
    end
  end
end
