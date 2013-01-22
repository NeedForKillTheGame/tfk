unit SysUtils_;

interface

{
// XProger: uses SysUtils для чего тогда? ;)
type
  TFloatValue = (fvExtended, fvCurrency);
  TFloatFormat = (ffGeneral, ffExponent, ffFixed, ffNumber, ffCurrency);
}

function StrPas(s: PChar): string;
function StrToFloat(const S: string; var X: single): boolean;
function FloatToStr(X: single): string;
//function Trim(s: string): string;

implementation

uses SysUtils;

function StrPas(s: PChar): string;
begin
// XProger: LOL
//Result:=SysUtils.StrPas(s);
Result := s;
end;

function StrToFloat(const S: string; var X: single): boolean;
var
 X1 : Extended;
begin
 // XProger: давай уж решим какой сеператор будет... :)
 //а вот нифига, просто я и другие часто ошибаются.
if pos('.', s) > 0 then
 DecimalSeparator := '.'
else
DecimalSeparator := ',';
// XProger: так извращаться гораздо надёжнее и быстрее
X1 := X;
Result := SysUtils.TextToFloat(PChar(S), X1, fvExtended);
X  := X1;
end;

function FloatToStr(X: single): string;
begin
DecimalSeparator := ',';
Result := FloatToStrF(X, ffGeneral, 5, 5);
end;

// XProger: шутник ;)
{
function Trim(s: string): string;
begin
   while (length(s)>0) and (s[1]=' ') do
      Delete(s, 1, 1);
   while (length(s)>0) and (s[length(s)]=' ') do
      Delete(s, length(s), 1);
   Result:=s;
end;
}
end.
