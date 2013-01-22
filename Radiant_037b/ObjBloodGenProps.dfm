inherited ObjBloodGenProp: TObjBloodGenProp
  Caption = 'Blood Generator'
  ClientHeight = 341
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object Label3: TLabel [0]
    Left = 8
    Top = 68
    Width = 23
    Height = 13
    Caption = 'color'
  end
  inherited OkBtn: TBitBtn
    Top = 312
  end
  inherited CancelBtn: TBitBtn
    Top = 312
  end
  inherited UpdateBtn: TBitBtn
    Top = 312
  end
  object Sprites: TGroupBox
    Left = 0
    Top = 176
    Width = 289
    Height = 121
    Caption = 'Sprites'
    TabOrder = 4
    object Label7: TLabel
      Left = 8
      Top = 92
      Width = 66
      Height = 13
      Caption = 'Color (Sparks)'
    end
    object Label4: TLabel
      Left = 8
      Top = 44
      Width = 22
      Height = 13
      Caption = 'Wait'
    end
    object Label8: TLabel
      Left = 8
      Top = 20
      Width = 54
      Height = 13
      Caption = 'Sprite Type'
    end
    object Label9: TLabel
      Left = 8
      Top = 68
      Width = 28
      Height = 13
      Caption = 'Count'
    end
    object ColorBox: TComboBox
      Left = 80
      Top = 88
      Width = 137
      Height = 21
      ItemHeight = 13
      ItemIndex = 0
      TabOrder = 5
      Text = 'Red'
      Items.Strings = (
        'Red'
        'Green'
        'Blue'
        'Yellow'
        'Purple'
        'Aqua')
    end
    object BloodWaitEd: TEdit
      Left = 80
      Top = 40
      Width = 121
      Height = 21
      TabOrder = 1
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object BloodWaitUD: TUpDown
      Left = 201
      Top = 40
      Width = 15
      Height = 21
      Associate = BloodWaitEd
      Max = 1000
      TabOrder = 2
    end
    object TypeBox: TComboBox
      Left = 80
      Top = 16
      Width = 137
      Height = 21
      ItemHeight = 13
      ItemIndex = 1
      TabOrder = 0
      Text = 'Smoke'
      Items.Strings = (
        'Blood'
        'Smoke'
        'Light_2'
        'Spark')
    end
    object CountEd: TEdit
      Left = 80
      Top = 64
      Width = 121
      Height = 21
      TabOrder = 3
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object CountUD: TUpDown
      Left = 201
      Top = 64
      Width = 15
      Height = 21
      Associate = CountEd
      Max = 1000
      TabOrder = 4
    end
  end
end
