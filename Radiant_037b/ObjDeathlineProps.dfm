inherited ObjDeathLineProp: TObjDeathLineProp
  Left = 256
  Top = 80
  Caption = 'ObjDeathLineProp'
  ClientHeight = 307
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  inherited OkBtn: TBitBtn
    Top = 278
  end
  inherited CancelBtn: TBitBtn
    Top = 278
  end
  inherited UpdateBtn: TBitBtn
    Top = 278
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 176
    Width = 289
    Height = 97
    Caption = 'Death line'
    TabOrder = 4
    object Label3: TLabel
      Left = 8
      Top = 20
      Width = 38
      Height = 13
      Caption = 'damage'
    end
    object Label4: TLabel
      Left = 8
      Top = 44
      Width = 60
      Height = 13
      Caption = 'damage wait'
    end
    object Label7: TLabel
      Left = 8
      Top = 68
      Width = 23
      Height = 13
      Caption = 'color'
    end
    object DamageEd: TEdit
      Left = 80
      Top = 16
      Width = 121
      Height = 21
      TabOrder = 0
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object DamageWaitEd: TEdit
      Left = 80
      Top = 40
      Width = 121
      Height = 21
      TabOrder = 1
      Text = '0'
      OnKeyPress = TargetNameEdKeyPress
    end
    object DamageUD: TUpDown
      Left = 201
      Top = 16
      Width = 15
      Height = 21
      Associate = DamageEd
      Max = 1000
      TabOrder = 2
    end
    object DamageWaitUD: TUpDown
      Left = 201
      Top = 40
      Width = 15
      Height = 21
      Associate = DamageWaitEd
      Max = 1000
      TabOrder = 3
    end
    object ColorBox: TComboBox
      Left = 80
      Top = 64
      Width = 137
      Height = 21
      ItemHeight = 13
      ItemIndex = 0
      TabOrder = 4
      Text = 'Red'
      Items.Strings = (
        'Red'
        'Green'
        'Blue'
        'Yellow'
        'Purple'
        'Aqua')
    end
  end
end
