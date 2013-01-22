inherited ObjElevatorProp: TObjElevatorProp
  Left = 448
  Top = 24
  Caption = 'ObjElevatorProp'
  ClientHeight = 394
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  inherited OkBtn: TBitBtn
    Top = 365
  end
  inherited CancelBtn: TBitBtn
    Top = 365
  end
  inherited UpdateBtn: TBitBtn
    Top = 365
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 176
    Width = 289
    Height = 185
    Caption = 'Elevator props && targets'
    TabOrder = 4
    object Label3: TLabel
      Left = 16
      Top = 36
      Width = 60
      Height = 13
      Caption = 'Target name'
    end
    object Label4: TLabel
      Left = 16
      Top = 60
      Width = 84
      Height = 13
      Caption = 'Back target name'
    end
    object Label7: TLabel
      Left = 16
      Top = 92
      Width = 31
      Height = 13
      Caption = 'Target'
    end
    object Label8: TLabel
      Left = 16
      Top = 116
      Width = 55
      Height = 13
      Caption = 'Back target'
    end
    object Label9: TLabel
      Left = 16
      Top = 152
      Width = 31
      Height = 13
      Caption = 'Speed'
    end
    object ActiveBox: TCheckBox
      Left = 16
      Top = 16
      Width = 97
      Height = 17
      Caption = 'Active'
      TabOrder = 0
    end
    object etarget1ed: TEdit
      Left = 120
      Top = 32
      Width = 113
      Height = 21
      TabOrder = 1
      Text = 'NULL'
      OnKeyPress = etarget1edKeyPress
    end
    object target1Null: TButton
      Left = 240
      Top = 86
      Width = 41
      Height = 25
      Caption = 'Null'
      TabOrder = 2
      OnClick = target1NullClick
    end
    object etarget2ed: TEdit
      Left = 120
      Top = 56
      Width = 113
      Height = 21
      TabOrder = 3
      Text = 'NULL'
      OnKeyPress = etarget1edKeyPress
    end
    object target2NULL: TButton
      Left = 240
      Top = 110
      Width = 41
      Height = 25
      Caption = 'Null'
      TabOrder = 4
      OnClick = target2NULLClick
    end
    object target1ed: TEdit
      Left = 120
      Top = 88
      Width = 113
      Height = 21
      TabOrder = 5
      Text = 'NULL'
      OnKeyPress = etarget1edKeyPress
    end
    object etarget1NULL: TButton
      Left = 240
      Top = 30
      Width = 41
      Height = 25
      Caption = 'Null'
      TabOrder = 6
      OnClick = etarget1NULLClick
    end
    object target2ed: TEdit
      Left = 120
      Top = 112
      Width = 113
      Height = 21
      TabOrder = 7
      Text = 'NULL'
      OnKeyPress = etarget1edKeyPress
    end
    object etarget2NULL: TButton
      Left = 240
      Top = 54
      Width = 41
      Height = 25
      Caption = 'Null'
      TabOrder = 8
      OnClick = etarget2NULLClick
    end
    object SpeedBar: TTrackBar
      Left = 56
      Top = 136
      Width = 177
      Height = 41
      Min = 1
      Position = 1
      TabOrder = 9
    end
  end
end
