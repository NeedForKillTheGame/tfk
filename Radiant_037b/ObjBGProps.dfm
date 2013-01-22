inherited ObjBgProp: TObjBgProp
  Caption = 'Background'
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  inherited GroupBox1: TGroupBox
    inherited TargetNameUD: TUpDown
      Enabled = False
    end
    inherited TargetNameEd: TEdit
      Enabled = False
    end
    inherited WaitEd: TEdit
      Enabled = False
    end
    inherited WaitUD: TUpDown
      Enabled = False
    end
    inherited ActiveGroup: TRadioGroup
      Items.Strings = (
        'Back'
        'Middle'
        'Front')
    end
  end
end
