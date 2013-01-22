unit MyPalette;

interface

//
//Операции загрузки бриков в TImageList

uses SysUtils, Classes, Types, Graphics, ImgList;

const
   Brick_Width = 32;
   Brick_Height = 16;

function BrickRect(x, y, w, h: integer): TRect;

procedure LoadPaletteFromFileMasked(FileName: string; Palette: TCustomImageList;
					MaskColor:TColor;SW, SH : integer);

function LoadPaletteFromFile(FileName: string; Palette: TCustomImageList;
				  SW, SH : integer): TColor;

procedure LoadPaletteFromBitmap(Bitmap: TBitmap; Palette: TCustomImageList;
					MaskColor: TColor; SW, SH : integer);

procedure SavePaletteToFile(Palette: TCustomImageList; FileName: string);

implementation

const
   Brick_Rect : TRect = (Left:0; Top:0;
   		Right: Brick_width{-1}; Bottom: Brick_Height{-1});

function BrickRect(x, y, w, h: integer): TRect;
begin
   Result.Left:=x-w;
   Result.Top:=y-h;
   Result.Right:=x+Brick_Width+w;
   Result.Bottom:=y+Brick_Height+h;
end;

procedure LoadPaletteFromFileMasked(FileName: string; Palette: TCustomImageList;
					MaskColor:TColor; SW, SH : integer);
var
   Bitmap: TBitmap;

begin
   Bitmap:=TBitmap.Create;
   Bitmap.LoadFromFile(FileName);
   LoadPaletteFromBitmap(Bitmap, Palette, MaskColor, SW, SH);
   Bitmap.Free;
end;

function LoadPaletteFromFile(FileName: string; Palette: TCustomImageList;
				  SW, SH : integer): TColor;
var
   Bitmap: TBitmap;

begin
   Bitmap:=TBitmap.Create;
   Bitmap.LoadFromFile(FileName);
   Result:=Bitmap.Canvas.Pixels[0, 0];
   LoadPaletteFromBitmap(Bitmap, Palette, Result, SW, SH);
   Bitmap.Free;
end;

procedure LoadPaletteFromBitmap(Bitmap: TBitmap; Palette: TCustomImageList;
					MaskColor: TColor; SW, SH : integer);
var
   Image: TBitmap;
   i, j, w, h: integer;
   R: TRect;

begin
   Palette.Clear;
   Image:=TBitmap.Create;

   w:=(Bitmap.Width+1) div (Brick_width+SW);
   h:=(Bitmap.Height+1) div (Brick_height+SH);

   Image.Width:=Brick_width;
   Image.Height:=Brick_height;

   with Palette do
   for j:=0 to h-1 do
      for i:=0 to w-1 do
      if i+1+j*w<=255 then
   	begin
         R.Left:=i*(Brick_width+SW);
         R.Right:=(i+1)*(Brick_width+SW)-1;
         R.Top:=j*(Brick_Height+SH);
         R.Bottom:=(j+1)*(Brick_Height+SH)-1;
         Image.Canvas.CopyRect(BrickRect(0, 0, 0, 0), Bitmap.Canvas, R);
         Palette.AddMasked(Image, MaskColor);
   	end else Break;
   Image.Free;
end;

procedure SavePaletteToFile(Palette: TCustomImageList; FileName: string);
var
   Bitmap: TBitmap;
   i: integer;
begin
   Bitmap:=TBitmap.Create;
   Bitmap.Width:=Palette.Count*Brick_Width;
   Bitmap.Height:=Brick_Height;
   for i:=0 to Palette.Count-1 do
      Palette.Draw(Bitmap.Canvas, i*Brick_Width, 0, i);
   Bitmap.SaveToFile(FileName);
   Bitmap.Free;
end;

end.
