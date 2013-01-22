inherited ObjWeatherProp: TObjWeatherProp
  Caption = 'Object Weather Properties'
  PixelsPerInch = 96
  TextHeight = 13
  inherited Sprites: TGroupBox
    inherited Label7: TLabel
      Enabled = False
    end
    inherited ColorBox: TComboBox
      Enabled = False
    end
    inherited TypeBox: TComboBox
      ItemIndex = 0
      Text = 'Snow'
      Items.Strings = (
        'Snow'
        'Rain')
    end
  end
end
