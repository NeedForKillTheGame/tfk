object LMFrm: TLMFrm
  Left = 192
  Top = 113
  Width = 416
  Height = 302
  Caption = 'LightMap Generator'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 227
    Width = 408
    Height = 41
    Align = alBottom
    TabOrder = 0
    object RunBtn: TButton
      Left = 16
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Generate'
      TabOrder = 0
      OnClick = RunBtnClick
    end
  end
  object OutMemo: TMemo
    Left = 0
    Top = 0
    Width = 408
    Height = 227
    Align = alClient
    Lines.Strings = (
      'LightMap Generator')
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
  end
end
