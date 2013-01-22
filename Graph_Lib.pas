 unit Graph_Lib;
(******************************)
(*       TIME FOR KILL        *)
(* Created by XProger         *)
(* begin: 29.10.2003          *)
(* end:   --.--.----          *)
(*                            *)
(* site: www.XProger.narod.ru *)
(* e-mail: XProger@list.ru    *)
(******************************)
interface

uses
 Windows, OpenGL;
 
type
 PByteArray = ^TByteArray;
 TByteArray = array [0..1024] of Byte;

 PWordArray = ^TWordArray;
 TWordArray = array [0..1024] of Word;

 PArray = PByteArray;

 TRGB = packed record
  R, G, B: Byte;
 end;

 PRGB  = ^TRGB;
 PaRGB = ^aRGB;
 aRGB  = array [0..1] of TRGB;

 TRGBA = packed record
  R, G, B, A: Byte;
 end;

 PRGBA  = ^TRGBA;
 PaRGBA = ^aRGBA;
 aRGBA  = array [0..1] of TRGBA;

 PTexData = ^TTexData;
 TTexData = record
  ID        : DWORD;
  Data      : pByteArray;
  BPP       : Byte;
  Width     : WORD;
  Height    : WORD;
  Filter    : boolean;
  Trans     : boolean;
  TransC    : TRGBA;
  Clamp     : boolean;
  Scale     : boolean;
  MipMap    : boolean; // при true автоматом срабатывает Scale
 end;

function gluBuild2DMipmaps(Target: GLenum; Components, Width, Height: GLint; Format,atype: GLenum; Data: Pointer): GLint; stdcall; external glu32;
procedure glGenTextures(n: GLsizei; textures: PGLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
procedure glDeleteTextures(N: GLsizei; Textures: PGLuint); stdcall; external opengl32;
procedure glCopyTexImage2D(target: GLEnum; level: GLint; internalFormat: GLEnum; x, y: GLint; width, height: GLsizei; border: GLint); stdcall; external opengl32;

procedure glNormalPointer   (size: GLint; type_: GLenum; stride, count: GLsizei; P: Pointer) stdcall; external opengl32;
procedure glColorPointer    (size: GLint; type_: GLenum; stride, count: GLsizei; P: Pointer) stdcall; external opengl32;
procedure glTexCoordPointer (size: GLint; type_: GLenum; stride, count: GLsizei; P: Pointer) stdcall; external opengl32;
procedure glVertexPointer   (size: GLint; type_: GLenum; stride, count: GLsizei; P: Pointer) stdcall; external opengl32;
procedure glDrawArrays      (mode: GLenum; first: GLint; count: GLsizei) stdcall; external opengl32;

function RGB(R, G, B: Byte): TRGB;
function RGBA(R, G, B, A: Byte): TRGBA;

implementation

function RGB(R, G, B: Byte): TRGB;
begin
Result.R:=R;
Result.G:=G;
Result.B:=B;
end;

function RGBA(R, G, B, A: Byte): TRGBA;
begin
Result.R:=R;
Result.G:=G;
Result.B:=B;
Result.A:=A;
end;

end.
