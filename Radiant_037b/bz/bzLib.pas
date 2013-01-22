{*******************************************************}
{                                                       }
{     BZIP2 1.0 Data Compression Interface Unit         }
{                                                       }
{*******************************************************}

Unit bzLib;

Interface

Uses SysUtils, Classes, PowerAcrModuleInfo;

// -------------------------- PowerArc specific --------------------------------

Type
  TAlloc = Function(opaque: Pointer; Items, size: integer): Pointer; cdecl;
  TFree = Procedure(opaque, Block: Pointer); cdecl;

  // Internal structure.  Ignore.
  TBZStreamRec = Packed Record
    next_in: PChar; // next input byte
    avail_in: longword; // number of bytes available at next_in
    total_in: int64; // total nb of input bytes read so far

    next_out: PChar; // next output byte should be put here
    avail_out: longword; // remaining free space at next_out
    total_out: int64; // total nb of bytes output so far

    state: Pointer;

    bzalloc: TAlloc; // used to allocate the internal state
    bzfree: TFree; // used to free the internal state
    opaque: Pointer;
  End;

  TProgressEvent = Procedure(Current: integer) Of Object;
  // Abstract ancestor class
  TCustomBZip2Stream = Class(TStream)
  Private
    FStrm: TStream;
    FStrmPos: integer;
    FOnProgress: TProgressEvent;
    FBZRec: TBZStreamRec;
    FBuffer: Array[Word] Of Char;
  Protected
    Procedure Progress(Sender: TObject); Dynamic;
  Public
    Constructor Create(Strm: TStream);
    Property OnProgress: TProgressEvent Read FOnProgress Write FOnProgress;
  End;

  TBZCompressionStream = Class(TCustomBZip2Stream)
  Public
    Constructor Create(Dest: TStream);
    Destructor Destroy; Override;
    Function Read(Var Buffer; Count: LongInt): LongInt; Override;
    Function write(Const Buffer; Count: LongInt): LongInt; Override;
    Function Seek(Offset: LongInt; Origin: Word): LongInt; Override;
    Property OnProgress;
  End;

  TBZDecompressionStream = Class(TCustomBZip2Stream)
  Public
    Constructor Create(Source: TStream);
    Destructor Destroy; Override;
    Function Read(Var Buffer; Count: LongInt): LongInt; Override;
    Function write(Const Buffer; Count: LongInt): LongInt; Override;
    Function Seek(Offset: LongInt; Origin: Word): LongInt; Override;
    Property OnProgress;
  End;

  { CompressBuf compresses data, buffer to buffer, in one call.
     In: InBuf = ptr to compressed data
         InBytes = number of bytes in InBuf
    Out: OutBuf = ptr to newly allocated buffer containing decompressed data
         OutBytes = number of bytes in OutBuf   }
Procedure BZCompressBuf(Const InBuf: Pointer; InBytes: integer;
  Out OutBuf: Pointer; Out OutBytes: integer);

{ DecompressBuf decompresses data, buffer to buffer, in one call.
   In: InBuf = ptr to compressed data
       InBytes = number of bytes in InBuf
       OutEstimate = zero, or est. size of the decompressed data
  Out: OutBuf = ptr to newly allocated buffer containing decompressed data
       OutBytes = number of bytes in OutBuf   }
Procedure BZDecompressBuf(Const InBuf: Pointer; InBytes: integer;
  OutEstimate: integer; Out OutBuf: Pointer; Out OutBytes: integer);

Procedure BZCompress(Const Buffer; size: integer; OutStream: TStream;
  ProgressCallback: TProgressEvent = Nil); overload;
Procedure BZCompress(InStream, OutStream: TStream; ProgressCallback:
  TProgressEvent = Nil); overload;
Procedure BZDecompress(InStream, OutStream: TStream; ProgressCallback:
  TProgressEvent = Nil);

Type
  EBZip2Error = Class(Exception);
  EBZCompressionError = Class(EBZip2Error);
  EBZDecompressionError = Class(EBZip2Error);

  // -------------------------- PowerArc specific --------------------------------

Function BZGetPowerArcModuleInfo: PPowerArcModuleInfo;

Implementation

{$L blocksort.obj}
{$L huffman.obj}
{$L compress.obj}
{$L decompress.obj}
{$L bzlib2.obj}
{$L crctable.obj}
{$L randtable.obj}

Procedure _BZ2_hbMakeCodeLengths; External;
Procedure _BZ2_blockSort; External;
Procedure _BZ2_hbCreateDecodeTables; External;
Procedure _BZ2_hbAssignCodes; External;
Procedure _BZ2_compressBlock; External;
Procedure _BZ2_decompress; External;

Const
  BZ_RUN       = 0;
  BZ_FLUSH     = 1;
  BZ_FINISH    = 2;
  BZ_OK        = 0;
  BZ_RUN_OK    = 1;
  BZ_FLUSH_OK  = 2;
  BZ_FINISH_OK = 3;
  BZ_STREAM_END = 4;
  BZ_SEQUENCE_ERROR = (-1);
  BZ_PARAM_ERROR = (-2);
  BZ_MEM_ERROR = (-3);
  BZ_DATA_ERROR = (-4);
  BZ_DATA_ERROR_MAGIC = (-5);
  BZ_IO_ERROR  = (-6);
  BZ_UNEXPECTED_EOF = (-7);
  BZ_OUTBUFF_FULL = (-8);

  BZ_LEVEL     = 9;

Procedure _bz_internal_error(errcode: integer); Cdecl;
Begin
  Raise EBZip2Error.CreateFmt('Compression Error %d', [errcode]);
End;

Function _malloc(size: integer): Pointer; Cdecl;
Begin
  GetMem(result, size);
End;

Procedure _free(Block: Pointer); Cdecl;
Begin
  FreeMem(Block);
End;

// deflate compresses data

Function BZ2_bzCompressInit(Var Strm: TBZStreamRec; BlockSize: integer;
  verbosity: integer; workFactor: integer): integer; Stdcall; External;

Function BZ2_bzCompress(Var Strm: TBZStreamRec; Action: integer): integer;
  Stdcall; External;

Function BZ2_bzCompressEnd(Var Strm: TBZStreamRec): integer; Stdcall; External;

Function BZ2_bzBuffToBuffCompress(Dest: Pointer; Var destLen: integer; Source:
  Pointer;
  sourceLen, BlockSize, verbosity, workFactor: integer): integer; Stdcall;
  External;

// inflate decompresses data

Function BZ2_bzDecompressInit(Var Strm: TBZStreamRec; verbosity: integer;
  small: integer): integer; Stdcall; External;

Function BZ2_bzDecompress(Var Strm: TBZStreamRec): integer; Stdcall; External;

Function BZ2_bzDecompressEnd(Var Strm: TBZStreamRec): integer; Stdcall;
  External;

Function BZ2_bzBuffToBuffDecompress(Dest: Pointer; Var destLen: integer; Source:
  Pointer;
  sourceLen, small, verbosity: integer): integer; Stdcall; External;

Function bzip2AllocMem(AppData: Pointer; Items, size: integer): Pointer; Cdecl;
Begin
  GetMem(result, Items * size);
End;

Procedure bzip2FreeMem(AppData, Block: Pointer); Cdecl;
Begin
  FreeMem(Block);
End;

Function CCheck(code: integer): integer;
Begin
  result := code;
  If code < 0 Then
    Raise EBZCompressionError.CreateFmt('error %d', [code]); //!!
End;

Function DCheck(code: integer): integer;
Begin
  result := code;
  If code < 0 Then
    Raise EBZDecompressionError.CreateFmt('error %d', [code]); //!!
End;

Procedure BZCompressBuf(Const InBuf: Pointer; InBytes: integer;
  Out OutBuf: Pointer; Out OutBytes: integer);
Var
  Strm         : TBZStreamRec;
  p            : Pointer;
Begin
  FillChar(Strm, Sizeof(Strm), 0);
  Strm.bzalloc := bzip2AllocMem;
  Strm.bzfree := bzip2FreeMem;
  OutBytes := ((InBytes + (InBytes Div 10) + 12) + 255) And Not 255;
  GetMem(OutBuf, OutBytes);
  Try
    Strm.next_in := InBuf;
    Strm.avail_in := InBytes;
    Strm.next_out := OutBuf;
    Strm.avail_out := OutBytes;
    CCheck(BZ2_bzCompressInit(Strm, BZ_LEVEL, 0, 0));
    Try
      While CCheck(BZ2_bzCompress(Strm, BZ_FINISH)) <> BZ_STREAM_END Do
      Begin
        p := OutBuf;
        Inc(OutBytes, 256);
        ReallocMem(OutBuf, OutBytes);
        Strm.next_out := PChar(integer(OutBuf) + (integer(Strm.next_out) -
          integer(p)));
        Strm.avail_out := 256;
      End;
    Finally
      CCheck(BZ2_bzCompressEnd(Strm));
    End;
    ReallocMem(OutBuf, Strm.total_out);
    OutBytes := Strm.total_out;
  Except
    FreeMem(OutBuf);
    Raise
  End;
End;

Procedure BZDecompressBuf(Const InBuf: Pointer; InBytes: integer;
  OutEstimate: integer; Out OutBuf: Pointer; Out OutBytes: integer);
Var
  Strm         : TBZStreamRec;
  p            : Pointer;
  BufInc       : integer;
Begin
  FillChar(Strm, Sizeof(Strm), 0);
  Strm.bzalloc := bzip2AllocMem;
  Strm.bzfree := bzip2FreeMem;
  BufInc := (InBytes + 255) And Not 255;
  If OutEstimate = 0 Then
    OutBytes := BufInc
  Else
    OutBytes := OutEstimate;
  GetMem(OutBuf, OutBytes);
  Try
    Strm.next_in := InBuf;
    Strm.avail_in := InBytes;
    Strm.next_out := OutBuf;
    Strm.avail_out := OutBytes;
    DCheck(BZ2_bzDecompressInit(Strm, 0, 0));
    Try
      While DCheck(BZ2_bzDecompress(Strm)) <> BZ_STREAM_END Do
      Begin
        p := OutBuf;
        Inc(OutBytes, BufInc);
        ReallocMem(OutBuf, OutBytes);
        Strm.next_out := PChar(integer(OutBuf) + (integer(Strm.next_out) -
          integer(p)));
        Strm.avail_out := BufInc;
      End;
    Finally
      DCheck(BZ2_bzDecompressEnd(Strm));
    End;
    ReallocMem(OutBuf, Strm.total_out);
    OutBytes := Strm.total_out;
  Except
    FreeMem(OutBuf);
    Raise
  End;
End;

// TCustomBZip2Stream

Constructor TCustomBZip2Stream.Create(Strm: TStream);
Begin
  Inherited Create;
  FStrm := Strm;
  FStrmPos := Strm.Position;
  FBZRec.bzalloc := bzip2AllocMem;
  FBZRec.bzfree := bzip2FreeMem;
End;

Procedure TCustomBZip2Stream.Progress(Sender: TObject);
Begin
  If Assigned(FOnProgress) Then FOnProgress(Position);
End;

// TBZCompressionStream

Constructor TBZCompressionStream.Create(Dest: TStream);
Begin
  Inherited Create(Dest);
  FBZRec.next_out := FBuffer;
  FBZRec.avail_out := Sizeof(FBuffer);
  CCheck(BZ2_bzCompressInit(FBZRec, BZ_LEVEL, 0, 0));
End;

Destructor TBZCompressionStream.Destroy;
Begin
  FBZRec.next_in := Nil;
  FBZRec.avail_in := 0;
  Try
    If FStrm.Position <> FStrmPos Then FStrm.Position := FStrmPos;
    While (CCheck(BZ2_bzCompress(FBZRec, BZ_FINISH)) <> BZ_STREAM_END)
      And (FBZRec.avail_out = 0) Do
    Begin
      FStrm.WriteBuffer(FBuffer, Sizeof(FBuffer));
      FBZRec.next_out := FBuffer;
      FBZRec.avail_out := Sizeof(FBuffer);
    End;
    If FBZRec.avail_out < Sizeof(FBuffer) Then
      FStrm.WriteBuffer(FBuffer, Sizeof(FBuffer) - FBZRec.avail_out);
  Finally
    BZ2_bzCompressEnd(FBZRec);
  End;
  Inherited Destroy;
End;

Function TBZCompressionStream.Read(Var Buffer; Count: LongInt): LongInt;
Begin
  Raise EBZCompressionError.Create('Invalid stream operation');
End;

Function TBZCompressionStream.write(Const Buffer; Count: LongInt): LongInt;
Begin
  FBZRec.next_in := @Buffer;
  FBZRec.avail_in := Count;
  If FStrm.Position <> FStrmPos Then FStrm.Position := FStrmPos;
  While (FBZRec.avail_in > 0) Do
  Begin
    CCheck(BZ2_bzCompress(FBZRec, BZ_RUN));
    If FBZRec.avail_out = 0 Then
    Begin
      FStrm.WriteBuffer(FBuffer, Sizeof(FBuffer));
      FBZRec.next_out := FBuffer;
      FBZRec.avail_out := Sizeof(FBuffer);
      FStrmPos := FStrm.Position;
    End;
    Progress(Self);
  End;
  result := Count;
End;

Function TBZCompressionStream.Seek(Offset: LongInt; Origin: Word): LongInt;
Begin
  If (Offset = 0) And (Origin = soFromCurrent) Then
    result := FBZRec.total_in
  Else
    Raise EBZCompressionError.Create('Invalid stream operation');
End;

// TDecompressionStream

Constructor TBZDecompressionStream.Create(Source: TStream);
Begin
  Inherited Create(Source);
  FBZRec.next_in := FBuffer;
  FBZRec.avail_in := 0;
  DCheck(BZ2_bzDecompressInit(FBZRec, 0, 0));
End;

Destructor TBZDecompressionStream.Destroy;
Begin
  BZ2_bzDecompressEnd(FBZRec);
  Inherited Destroy;
End;

Function TBZDecompressionStream.Read(Var Buffer; Count: LongInt): LongInt;
Begin
  FBZRec.next_out := @Buffer;
  FBZRec.avail_out := Count;
  If FStrm.Position <> FStrmPos Then FStrm.Position := FStrmPos;
  While (FBZRec.avail_out > 0) Do
  Begin
    If FBZRec.avail_in = 0 Then
    Begin
      FBZRec.avail_in := FStrm.Read(FBuffer, Sizeof(FBuffer));
      If FBZRec.avail_in = 0 Then
      Begin
        result := Count - FBZRec.avail_out;
        exit;
      End;
      FBZRec.next_in := FBuffer;
      FStrmPos := FStrm.Position;
    End;
    CCheck(BZ2_bzDecompress(FBZRec));
    Progress(Self);
  End;
  result := Count;
End;

Function TBZDecompressionStream.write(Const Buffer; Count: LongInt): LongInt;
Begin
  Raise EBZDecompressionError.Create('Invalid stream operation');
End;

Function TBZDecompressionStream.Seek(Offset: LongInt; Origin: Word): LongInt;
Begin
  If (Offset >= 0) And (Origin = soFromCurrent) Then
    result := FBZRec.total_out
  Else
    Raise EBZDecompressionError.Create('Invalid stream operation');

End;

Procedure CopyStream(Src, Dst: TStream);
Const
  BufSize      = 4096;
Var
  Buf          : Array[0..BufSize - 1] Of byte;
  readed       : integer;
Begin
  If (Src <> Nil) And (Dst <> Nil) Then
  Begin
    readed := Src.Read(Buf[0], BufSize);
    While readed > 0 Do
    Begin
      Dst.write(Buf[0], readed);
      readed := Src.Read(Buf[0], BufSize);
    End;
  End;
End;

Procedure BZCompress(InStream, OutStream: TStream; ProgressCallback:
  TProgressEvent);
Var
  CompressionStream: TBZCompressionStream;
Begin
  CompressionStream := TBZCompressionStream.Create(OutStream);
  Try
    CompressionStream.OnProgress := ProgressCallback;
    CopyStream(InStream, CompressionStream);
  Finally
    CompressionStream.free;
  End;
End;

Procedure BZDecompress(InStream, OutStream: TStream; ProgressCallback:
  TProgressEvent);
Var
  DecompressionStream: TBZDecompressionStream;
Begin
  DecompressionStream := TBZDecompressionStream.Create(InStream);
  Try
    DecompressionStream.OnProgress := ProgressCallback;
    CopyStream(DecompressionStream, OutStream);
  Finally
    DecompressionStream.free;
  End;
End;

Procedure BZCompress(Const Buffer; size: integer; OutStream: TStream;
  ProgressCallback: TProgressEvent);
Var
  CompressionStream: TBZCompressionStream;
Begin
  CompressionStream := TBZCompressionStream.Create(OutStream);
  Try
    CompressionStream.OnProgress := ProgressCallback;
    CompressionStream.write(Buffer, size);
  Finally
    CompressionStream.free;
  End;
End;

Const
  BZIPModuleInfo: TPowerArcModuleInfo = (
    Signature: PowerArcModuleSignature;
    Name: 'BZIP';
    Description: '';
    Options: #0#0;
    DefaultBPC: 209;
    MaxBPC: 209;
    ModuleID: 'NFKDEMO-';
    );

Function BZGetPowerArcModuleInfo: PPowerArcModuleInfo;
Begin
  result := @BZIPModuleInfo;
End;

End.
