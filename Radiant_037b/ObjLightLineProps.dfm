inherited ObjLightLineProp: TObjLightLineProp
  Caption = 'Line props'
  ClientHeight = 317
  PixelsPerInch = 96
  TextHeight = 13
  inherited OkBtn: TBitBtn
    Top = 287
  end
  inherited CancelBtn: TBitBtn
    Top = 287
  end
  inherited UpdateBtn: TBitBtn
    Top = 287
  end
  inherited GroupBox2: TGroupBox
    Height = 113
    Caption = 'Line props'
    object Label9: TLabel [4]
      Left = 8
      Top = 84
      Width = 23
      Height = 13
      Caption = 'color'
    end
    object ColorBox: TComboBox
      Left = 48
      Top = 80
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
