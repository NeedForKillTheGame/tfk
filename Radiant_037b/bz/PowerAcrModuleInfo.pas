Unit PowerAcrModuleInfo;

Interface

//щрн ме лне х ме онбепю - щрн юпухбюрнп

Const
  PowerArcModuleSignature = 'AA6F3C60-37D7-11D4-B4BF-D80DBEC04C01';

Type
  TPowerArcModuleInfo = Packed Record
    Signature: PChar; // must be eq to PowerArcModuleSignature
    Name: PChar; // short name
    Description: PChar; // full description
    Options: PChar; // opt list delimited with #0
    // bit per char on calgary corpus *100
    DefaultBPC: integer;
    MaxBPC: integer;
    Case integer Of // unique
      0: (ModuleID: Packed Array[0..7] Of Char);
      1: (ModuleIDW: Packed Array[0..1] Of integer);
  End;
  PPowerArcModuleInfo = ^TPowerArcModuleInfo;

Implementation

End.
