object GenMapFrm: TGenMapFrm
  Left = 300
  Top = 176
  Width = 291
  Height = 249
  Caption = 'TFK Map Generator'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 283
    Height = 126
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Label5: TLabel
      Left = 7
      Top = 36
      Width = 31
      Height = 13
      Caption = 'Height'
    end
    object Label4: TLabel
      Left = 10
      Top = 12
      Width = 28
      Height = 13
      Caption = 'Width'
    end
    object RunBtn: TButton
      Left = 16
      Top = 64
      Width = 81
      Height = 25
      Caption = 'Generate Map'
      TabOrder = 0
      OnClick = RunBtnClick
    end
    object HeightUD: TUpDown
      Left = 113
      Top = 32
      Width = 16
      Height = 21
      Associate = HeightEd
      Min = 30
      Max = 1023
      Position = 30
      TabOrder = 1
    end
    object WidthUD: TUpDown
      Left = 113
      Top = 8
      Width = 16
      Height = 21
      Associate = WidthEd
      Min = 20
      Max = 1023
      Position = 20
      TabOrder = 2
    end
    object WidthEd: TEdit
      Left = 48
      Top = 8
      Width = 65
      Height = 21
      TabOrder = 3
      Text = '20'
    end
    object HeightEd: TEdit
      Left = 48
      Top = 32
      Width = 65
      Height = 21
      TabOrder = 4
      Text = '30'
    end
  end
  object OutMemo: TMemo
    Left = 0
    Top = 126
    Width = 283
    Height = 89
    Align = alBottom
    Lines.Strings = (
      'Ready')
    TabOrder = 1
  end
end
