inherited ObjAreaPushProp: TObjAreaPushProp
  Caption = 'ObjAreaPushProp'
  ClientHeight = 282
  PixelsPerInch = 96
  TextHeight = 13
  inherited OkBtn: TBitBtn
    Top = 253
  end
  inherited CancelBtn: TBitBtn
    Top = 253
  end
  inherited UpdateBtn: TBitBtn
    Top = 253
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 176
    Width = 289
    Height = 73
    Caption = 'Push'
    TabOrder = 4
    object Label3: TLabel
      Left = 8
      Top = 20
      Width = 31
      Height = 13
      Caption = 'push x'
    end
    object Label4: TLabel
      Left = 8
      Top = 44
      Width = 45
      Height = 13
      Caption = 'push wait'
    end
    object Label7: TLabel
      Left = 128
      Top = 20
      Width = 31
      Height = 13
      Caption = 'push y'
    end
    object PushXEd: TEdit
      Left = 48
      Top = 16
      Width = 57
      Height = 21
      TabOrder = 0
      Text = '0'
      OnKeyPress = PushXEdKeyPress
    end
    object PushWaitEd: TEdit
      Left = 80
      Top = 40
      Width = 121
      Height = 21
      TabOrder = 1
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object PushXUD: TUpDown
      Left = 105
      Top = 16
      Width = 16
      Height = 21
      Associate = PushXEd
      Min = -1000
      Max = 1000
      TabOrder = 2
      Thousands = False
    end
    object PushWaitUD: TUpDown
      Left = 201
      Top = 40
      Width = 15
      Height = 21
      Associate = PushWaitEd
      Max = 1000
      TabOrder = 3
    end
    object PushYEd: TEdit
      Left = 168
      Top = 16
      Width = 57
      Height = 21
      TabOrder = 4
      Text = '0'
      OnKeyPress = PushXEdKeyPress
    end
    object PushYUD: TUpDown
      Left = 225
      Top = 16
      Width = 16
      Height = 21
      Associate = PushYEd
      Min = -1000
      Max = 1000
      TabOrder = 5
      Thousands = False
    end
  end
end
