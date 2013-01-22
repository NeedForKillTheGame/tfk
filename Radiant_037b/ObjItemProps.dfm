inherited ObjItemProp: TObjItemProp
  Left = 310
  Top = 84
  Caption = 'ObjItemProp'
  ClientHeight = 298
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  inherited OkBtn: TBitBtn
    Top = 269
  end
  inherited CancelBtn: TBitBtn
    Top = 269
  end
  inherited UpdateBtn: TBitBtn
    Top = 269
  end
  inherited GroupBox1: TGroupBox
    inherited WaitEd: TEdit
      Text = '1'
    end
    inherited WaitUD: TUpDown
      Min = 1
      Position = 1
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 176
    Width = 289
    Height = 89
    Caption = 'Item properties'
    TabOrder = 4
    object Label3: TLabel
      Left = 40
      Top = 28
      Width = 28
      Height = 13
      Caption = 'Count'
    end
    object Label4: TLabel
      Left = 8
      Top = 52
      Width = 62
      Height = 13
      Caption = 'First respawn'
    end
    object Label7: TLabel
      Left = 224
      Top = 52
      Width = 44
      Height = 13
      Caption = '(first wait)'
    end
    object CountEd: TEdit
      Left = 80
      Top = 24
      Width = 121
      Height = 21
      TabOrder = 0
      Text = '1'
      OnKeyPress = TargetNameEdKeyPress
    end
    object CountUD: TUpDown
      Left = 201
      Top = 24
      Width = 15
      Height = 21
      Associate = CountEd
      Min = 1
      Position = 1
      TabOrder = 1
    end
    object FirstEd: TEdit
      Left = 80
      Top = 48
      Width = 121
      Height = 21
      TabOrder = 2
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object FirstUD: TUpDown
      Left = 201
      Top = 48
      Width = 16
      Height = 21
      Associate = FirstEd
      Max = 10000
      TabOrder = 3
      Thousands = False
    end
  end
end
