inherited ObjRespawnProp: TObjRespawnProp
  Left = 246
  Top = 68
  Caption = 'Respawn properties'
  ClientHeight = 295
  ClientWidth = 453
  PixelsPerInch = 96
  TextHeight = 13
  inherited OkBtn: TBitBtn
    Top = 265
  end
  inherited CancelBtn: TBitBtn
    Top = 265
  end
  inherited UpdateBtn: TBitBtn
    Left = 374
    Top = 265
  end
  object GroupBox3: TGroupBox
    Left = 296
    Top = 0
    Width = 153
    Height = 257
    Caption = 'Player Properties'
    TabOrder = 5
    object ToolBar1: TToolBar
      Left = 8
      Top = 23
      Width = 137
      Height = 74
      Align = alNone
      ButtonHeight = 64
      ButtonWidth = 39
      Caption = 'ToolBar1'
      Images = MainForm.SargeImg
      TabOrder = 0
      object LeftBtn: TSpeedButton
        Left = 0
        Top = 2
        Width = 49
        Height = 64
        Glyph.Data = {
          76010000424D7601000000000000760000002800000020000000100000000100
          04000000000000010000120B0000120B00001000000000000000000000000000
          800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
          3333333333333333333333333333333333333333333333333333333333333333
          3333333333333FF3333333333333003333333333333F77F33333333333009033
          333333333F7737F333333333009990333333333F773337FFFFFF330099999000
          00003F773333377777770099999999999990773FF33333FFFFF7330099999000
          000033773FF33777777733330099903333333333773FF7F33333333333009033
          33333333337737F3333333333333003333333333333377333333333333333333
          3333333333333333333333333333333333333333333333333333333333333333
          3333333333333333333333333333333333333333333333333333}
        NumGlyphs = 2
        OnClick = LeftBtnClick
      end
      object SargeBtn: TToolButton
        Left = 49
        Top = 2
        Caption = 'SargeBtn'
        ImageIndex = 0
        OnClick = SargeBtnClick
      end
      object RightBtn: TSpeedButton
        Left = 88
        Top = 2
        Width = 48
        Height = 64
        Glyph.Data = {
          76010000424D7601000000000000760000002800000020000000100000000100
          04000000000000010000120B0000120B00001000000000000000000000000000
          800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
          3333333333333333333333333333333333333333333333333333333333333333
          3333333333333333333333333333333333333333333FF3333333333333003333
          3333333333773FF3333333333309003333333333337F773FF333333333099900
          33333FFFFF7F33773FF30000000999990033777777733333773F099999999999
          99007FFFFFFF33333F7700000009999900337777777F333F7733333333099900
          33333333337F3F77333333333309003333333333337F77333333333333003333
          3333333333773333333333333333333333333333333333333333333333333333
          3333333333333333333333333333333333333333333333333333}
        NumGlyphs = 2
        OnClick = RightBtnClick
      end
    end
  end
end
