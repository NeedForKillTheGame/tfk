inherited ObjButtonProp: TObjButtonProp
  Left = 297
  Top = 54
  Caption = 'Button/trigger properties'
  ClientHeight = 292
  ClientWidth = 293
  OldCreateOrder = True
  DesignSize = (
    293
    292)
  PixelsPerInch = 96
  TextHeight = 13
  inherited OkBtn: TBitBtn
    Top = 262
  end
  inherited CancelBtn: TBitBtn
    Top = 262
  end
  inherited UpdateBtn: TBitBtn
    Left = 214
    Top = 262
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 168
    Width = 289
    Height = 89
    Caption = 'Activator props'
    TabOrder = 4
    object Label7: TLabel
      Left = 112
      Top = 56
      Width = 104
      Height = 13
      Caption = 'for activating object(s)'
    end
    object Label3: TLabel
      Left = 112
      Top = 24
      Width = 101
      Height = 13
      Caption = 'of activating object(s)'
    end
    object Label4: TLabel
      Left = 8
      Top = 24
      Width = 34
      Height = 13
      Caption = 'Target '
    end
    object Label8: TLabel
      Left = 8
      Top = 56
      Width = 22
      Height = 13
      Caption = 'Wait'
    end
    object TargetEd: TEdit
      Left = 48
      Top = 20
      Width = 41
      Height = 21
      TabOrder = 0
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object WaitTargetUD: TUpDown
      Left = 89
      Top = 52
      Width = 15
      Height = 21
      Associate = WaitTargetEd
      Max = 32767
      Increment = 50
      TabOrder = 1
      Thousands = False
    end
    object TargetUD: TUpDown
      Left = 89
      Top = 20
      Width = 15
      Height = 21
      Associate = TargetEd
      Max = 32767
      TabOrder = 2
      Thousands = False
    end
    object WaitTargetEd: TEdit
      Left = 48
      Top = 52
      Width = 41
      Height = 21
      TabOrder = 3
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
  end
end
