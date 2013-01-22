object ObjPropFrm: TObjPropFrm
  Left = 325
  Top = 107
  BorderStyle = bsDialog
  Caption = 'Object properties'
  ClientHeight = 203
  ClientWidth = 293
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  DesignSize = (
    293
    203)
  PixelsPerInch = 96
  TextHeight = 13
  object OkBtn: TBitBtn
    Left = 8
    Top = 174
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    TabOrder = 0
    OnClick = OkBtnClick
    Kind = bkOK
  end
  object CancelBtn: TBitBtn
    Left = 88
    Top = 174
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    TabOrder = 1
    Kind = bkCancel
  end
  object UpdateBtn: TBitBtn
    Left = 210
    Top = 174
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Load'
    TabOrder = 2
    OnClick = UpdateBtnClick
  end
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 289
    Height = 169
    Caption = 'Basic props'
    TabOrder = 3
    object Label1: TLabel
      Left = 8
      Top = 20
      Width = 31
      Height = 13
      Caption = 'Target'
    end
    object Label2: TLabel
      Left = 112
      Top = 20
      Width = 60
      Height = 13
      Caption = 'of this object'
    end
    object Label5: TLabel
      Left = 8
      Top = 52
      Width = 22
      Height = 13
      Caption = 'Wait'
    end
    object Label6: TLabel
      Left = 112
      Top = 52
      Width = 139
      Height = 13
      Caption = 'for respawn or next activation'
    end
    object TargetNameUD: TUpDown
      Left = 89
      Top = 16
      Width = 16
      Height = 21
      Associate = TargetNameEd
      Max = 32767
      TabOrder = 1
      Thousands = False
    end
    object TargetNameEd: TEdit
      Left = 48
      Top = 16
      Width = 41
      Height = 21
      TabOrder = 0
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object WaitEd: TEdit
      Left = 48
      Top = 48
      Width = 41
      Height = 21
      TabOrder = 2
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object WaitUD: TUpDown
      Left = 89
      Top = 48
      Width = 16
      Height = 21
      Associate = WaitEd
      Max = 32767
      Increment = 50
      TabOrder = 3
      Thousands = False
    end
    object ActiveGroup: TRadioGroup
      Left = 8
      Top = 72
      Width = 273
      Height = 89
      Caption = 'Activation by other objects'
      ItemIndex = 0
      Items.Strings = (
        'Object can'#39't be activated(0)'
        'Object can be activated (1)'
        'SHOOTING activation(2)'
        '1 and 2')
      TabOrder = 4
      OnClick = ActiveGroupClick
    end
  end
end
