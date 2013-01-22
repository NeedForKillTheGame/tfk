object MapPropsFrm: TMapPropsFrm
  Left = 326
  Top = 213
  Width = 385
  Height = 322
  Caption = 'map header&entries'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 377
    Height = 145
    Align = alTop
    TabOrder = 0
    DesignSize = (
      377
      145)
    object Label1: TLabel
      Left = 8
      Top = 12
      Width = 54
      Height = 13
      Caption = 'Map author'
    end
    object Label2: TLabel
      Left = 12
      Top = 36
      Width = 50
      Height = 13
      Caption = 'Map name'
    end
    object Label4: TLabel
      Left = 34
      Top = 60
      Width = 28
      Height = 13
      Caption = 'Width'
    end
    object Label5: TLabel
      Left = 31
      Top = 84
      Width = 31
      Height = 13
      Caption = 'Height'
    end
    object AuthorEd: TEdit
      Left = 72
      Top = 8
      Width = 281
      Height = 21
      TabOrder = 0
    end
    object NameEd: TEdit
      Left = 72
      Top = 32
      Width = 281
      Height = 21
      TabOrder = 1
    end
    object BitBtn1: TBitBtn
      Left = 212
      Top = 80
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      TabOrder = 2
      OnClick = BitBtn1Click
      Kind = bkOK
    end
    object BitBtn2: TBitBtn
      Left = 292
      Top = 80
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      TabOrder = 3
      Kind = bkCancel
    end
    object WidthEd: TEdit
      Left = 72
      Top = 56
      Width = 65
      Height = 21
      TabOrder = 4
      Text = '20'
      OnKeyPress = HeightEdKeyPress
    end
    object HeightEd: TEdit
      Left = 72
      Top = 80
      Width = 65
      Height = 21
      TabOrder = 5
      Text = '30'
      OnKeyPress = HeightEdKeyPress
    end
    object WidthUD: TUpDown
      Left = 137
      Top = 56
      Width = 15
      Height = 21
      Associate = WidthEd
      Min = 20
      Max = 1023
      Position = 20
      TabOrder = 6
    end
    object HeightUD: TUpDown
      Left = 137
      Top = 80
      Width = 15
      Height = 21
      Associate = HeightEd
      Min = 30
      Max = 1023
      Position = 30
      TabOrder = 7
    end
    object EnvColor: TButton
      Left = 8
      Top = 112
      Width = 105
      Height = 25
      Caption = 'Environment Color...'
      TabOrder = 8
      OnClick = EnvColorClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 145
    Width = 377
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      377
      32)
    object Label3: TLabel
      Left = 16
      Top = 8
      Width = 122
      Height = 13
      Alignment = taCenter
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Map Format Sections'
    end
    object DelSection: TButton
      Left = 120
      Top = 4
      Width = 105
      Height = 25
      Caption = 'Delete Section'
      TabOrder = 0
      OnClick = DelSectionClick
    end
  end
  object EntryList: TStringGrid
    Left = 0
    Top = 177
    Width = 377
    Height = 118
    Align = alClient
    DefaultColWidth = 25
    DefaultRowHeight = 20
    TabOrder = 2
    ColWidths = (
      25
      58
      42
      104
      115)
  end
  object EnvDlg: TColorDialog
    Left = 72
    Top = 120
  end
end
