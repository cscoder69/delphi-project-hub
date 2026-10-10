unit CSCoder.Hub.Images;

interface

uses
  System.Classes, System.UITypes;

const
  // Segoe MDL2 Assets code points
  CSHubGlyphAdd = #$E710;
  CSHubGlyphMore = #$E712;
  CSHubGlyphDelete = #$E74D;
  CSHubGlyphSettings = #$E713;
  CSHubGlyphOpenFolder = #$ED25;
  CSHubGlyphUp = #$E74A;
  CSHubGlyphDown = #$E74B;
  CSHubGlyphChevronDown = #$E70D;
  CSHubGlyphChevronRight = #$E76C;
  CSHubGlyphHelp = #$E897;
  // popup menus
  CSHubGlyphOpenFile = #$E8E5;
  CSHubGlyphExplorer = #$EC50;
  CSHubGlyphMoveTo = #$E8DE;
  CSHubGlyphRename = #$E8AC;
  CSHubGlyphSort = #$E8CB;
  CSHubGlyphFolder = #$E8B7;
  CSHubGlyphChevronUp = #$E70E;
  CSHubGlyphExport = #$EDE1;
  CSHubGlyphImport = #$E8B5;
  CSHubGlyphReplace = #$E72C;
  CSHubGlyphRefresh = #$E72C; // same picture as "import and replace"
  CSHubGlyphLanguage = #$E774;
  CSHubGlyphIcon = #$E91B; // "Icon..." in the menus
  CSHubGlyphFont = 'Segoe MDL2 Assets';

type
  TCSHubIconDef = record
    Id: string;
    Glyph: Char;
  end;

const
  CSHubIconColumns = 8; // of the grid that offers them, one subject per row
  /// Icons a category or a group can have. The id is what goes into the user's
  /// file: once released it is never renamed or removed. The glyph may change.
  CSHubIconLibrary: array[0..55] of TCSHubIconDef = (
    (Id: 'folder'; Glyph: #$E8B7), (Id: 'star'; Glyph: #$E734), (Id: 'heart'; Glyph: #$EB51), (Id: 'flag'; Glyph: #$E7C1),
    (Id: 'pin'; Glyph: #$E718), (Id: 'tag'; Glyph: #$E8EC), (Id: 'target'; Glyph: #$EB44), (Id: 'home'; Glyph: #$E80F),
    (Id: 'company'; Glyph: #$EC06), (Id: 'building'; Glyph: #$E731), (Id: 'shop'; Glyph: #$E719), (Id: 'bank'; Glyph: #$E825),
    (Id: 'work'; Glyph: #$E821), (Id: 'cart'; Glyph: #$E7BF), (Id: 'card'; Glyph: #$E8C7), (Id: 'market'; Glyph: #$EAFC),
    (Id: 'chart'; Glyph: #$E9D2), (Id: 'report'; Glyph: #$E9F9), (Id: 'calculator'; Glyph: #$E8EF), (Id: 'person'; Glyph: #$E77B),
    (Id: 'people'; Glyph: #$E716), (Id: 'mail'; Glyph: #$E715), (Id: 'chat'; Glyph: #$E8BD), (Id: 'calendar'; Glyph: #$E787),
    (Id: 'code'; Glyph: #$E943), (Id: 'terminal'; Glyph: #$E756), (Id: 'bug'; Glyph: #$EBE8), (Id: 'test'; Glyph: #$E9D9),
    (Id: 'tool'; Glyph: #$E90F), (Id: 'gear'; Glyph: #$E713), (Id: 'chip'; Glyph: #$E950), (Id: 'puzzle'; Glyph: #$EA86),
    (Id: 'package'; Glyph: #$E7B8), (Id: 'library'; Glyph: #$E8F1), (Id: 'database'; Glyph: #$EE94), (Id: 'server'; Glyph: #$E968),
    (Id: 'cloud'; Glyph: #$E753), (Id: 'web'; Glyph: #$EB41), (Id: 'globe'; Glyph: #$E774), (Id: 'robot'; Glyph: #$E99A),
    (Id: 'phone'; Glyph: #$E8EA), (Id: 'tablet'; Glyph: #$E70A), (Id: 'laptop'; Glyph: #$E7F8), (Id: 'desktop'; Glyph: #$E977),
    (Id: 'print'; Glyph: #$E749), (Id: 'qrcode'; Glyph: #$ED14), (Id: 'game'; Glyph: #$E7FC), (Id: 'school'; Glyph: #$E7BE),
    (Id: 'document'; Glyph: #$E8A5), (Id: 'clock'; Glyph: #$E823), (Id: 'lock'; Glyph: #$E72E), (Id: 'key'; Glyph: #$E8D7),
    (Id: 'shield'; Glyph: #$EA18), (Id: 'idea'; Glyph: #$EA80), (Id: 'bolt'; Glyph: #$E945), (Id: 'health'; Glyph: #$E95E));
  /// Side, in pixels, of the box a loaded picture is reduced to fit in.
  CSHubIconStoreSize = 64;

function CSHubGlyphFontAvailable: Boolean;
/// PNG (with alpha) of the shell icon registered for a file extension, e.g. '.dproj'.
function CSHubShellIconPng(const AExt: string): TStream;
/// PNG (with alpha) of a single glyph drawn in AColor on a transparent square.
/// AFontHeight = 0 leaves a margin around the glyph (5/8 of the square).
function CSHubGlyphPng(const AGlyph, AFontName: string; ASize: Integer;
  AColor: TColor; AOpacity: Byte; AFontHeight: Integer = 0): TStream;
/// Glyph of a library icon; '' when the id is not in the library.
function CSHubIconGlyph(const AId: string): string;
/// Reads a picture (PNG, ICO, JPG, BMP, GIF), reduces it to fit the store size and
/// writes it as PNG in ADir, named after its content. Returns that file name.
/// Raises when the file is not a picture.
function CSHubImportIcon(const AFileName, ADir: string): string;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, Winapi.CommCtrl, System.SysUtils, System.Math, System.IOUtils, System.Hash,
  Vcl.Forms, Vcl.Imaging.pngimage, Vcl.Graphics;

const
  IID_IImageList: TGUID = '{46EB5926-582E-4017-9FDF-E8998DAA0950}';

type
  TQuadArray = array[0..MaxInt div SizeOf(TRGBQuad) - 1] of TRGBQuad;
  PQuadArray = ^TQuadArray;

function CSHubGlyphFontAvailable: Boolean;
begin
  Result := Screen.Fonts.IndexOf(CSHubGlyphFont) >= 0;
end;

function NewBitmap32(AWidth, AHeight: Integer): TBitmap;
var Y: Integer;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf32bit;
  Result.SetSize(AWidth, AHeight);
  for Y := 0 to AHeight - 1 do
    FillChar(Result.ScanLine[Y]^, AWidth * SizeOf(TRGBQuad), 0);
end;

// ABitmap holds premultiplied BGRA; the result is a straight-alpha PNG stream.
function PremultipliedToPng(ABitmap: TBitmap): TStream;
var Png: TPngImage;
    X, Y: Integer;
    Src: PQuadArray;
    Dst: pRGBLine;
    Alpha: pByteArray;
    A: Byte;
begin
  Png := TPngImage.CreateBlank(COLOR_RGBALPHA, 8, ABitmap.Width, ABitmap.Height);
  try
    for Y := 0 to ABitmap.Height - 1 do
    begin
      Src := ABitmap.ScanLine[Y];
      Dst := Png.Scanline[Y];
      Alpha := Png.AlphaScanline[Y];
      for X := 0 to ABitmap.Width - 1 do
      begin
        A := Src[X].rgbReserved;
        Alpha[X] := A;
        if A = 0 then
        begin
          Dst[X].rgbtBlue := 0;
          Dst[X].rgbtGreen := 0;
          Dst[X].rgbtRed := 0;
        end
        else
        begin
          Dst[X].rgbtBlue := (Src[X].rgbBlue * 255) div A;
          Dst[X].rgbtGreen := (Src[X].rgbGreen * 255) div A;
          Dst[X].rgbtRed := (Src[X].rgbRed * 255) div A;
        end;
      end;
    end;
    Result := TMemoryStream.Create;
    try
      Png.SaveToStream(Result);
      Result.Position := 0;
    except
      Result.Free;
      raise;
    end;
  finally
    Png.Free;
  end;
end;

function CSHubShellIconPng(const AExt: string): TStream;
var Info: TSHFileInfo;
    ListPtr: Pointer;
    Icon: HICON;
    W, H, X, Y: Integer;
    Bmp: TBitmap;
    Line: PQuadArray;
    HasAlpha: Boolean;
begin
  Result := nil;
  FillChar(Info, SizeOf(Info), 0);
  if SHGetFileInfo(PChar('x' + AExt), FILE_ATTRIBUTE_NORMAL, Info, SizeOf(Info),
    SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES) = 0 then Exit;
  ListPtr := nil;
  if Failed(SHGetImageList(SHIL_EXTRALARGE, IID_IImageList, ListPtr)) or (ListPtr = nil) then Exit;
  try
    if not ImageList_GetIconSize(HIMAGELIST(ListPtr), W, H) then Exit;
    Icon := ImageList_GetIcon(HIMAGELIST(ListPtr), Info.iIcon, ILD_TRANSPARENT);
  finally
    IUnknown(ListPtr)._Release;
  end;
  if Icon = 0 then Exit;
  try
    Bmp := NewBitmap32(W, H);
    try
      DrawIconEx(Bmp.Canvas.Handle, 0, 0, Icon, W, H, 0, 0, DI_NORMAL);
      // Icons without an alpha channel leave alpha at zero: make drawn pixels opaque.
      HasAlpha := False;
      for Y := 0 to H - 1 do
      begin
        Line := Bmp.ScanLine[Y];
        for X := 0 to W - 1 do
          if Line[X].rgbReserved <> 0 then HasAlpha := True;
      end;
      if not HasAlpha then
        for Y := 0 to H - 1 do
        begin
          Line := Bmp.ScanLine[Y];
          for X := 0 to W - 1 do
            if (Line[X].rgbBlue or Line[X].rgbGreen or Line[X].rgbRed) <> 0 then
              Line[X].rgbReserved := 255;
        end;
      Result := PremultipliedToPng(Bmp);
    finally
      Bmp.Free;
    end;
  finally
    DestroyIcon(Icon);
  end;
end;

function CSHubGlyphPng(const AGlyph, AFontName: string; ASize: Integer;
  AColor: TColor; AOpacity: Byte; AFontHeight: Integer): TStream;
var Bmp: TBitmap;
    X, Y: Integer;
    Line: PQuadArray;
    Ext: TSize;
    C: TColor;
    A: Integer;
begin
  C := ColorToRGB(AColor);
  Bmp := NewBitmap32(ASize, ASize);
  try
    // White on black with grayscale antialiasing: the red channel is the coverage.
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.FillRect(Rect(0, 0, ASize, ASize));
    Bmp.Canvas.Font.Name := AFontName;
    if AFontHeight = 0 then AFontHeight := MulDiv(ASize, 5, 8);
    Bmp.Canvas.Font.Height := -AFontHeight;
    Bmp.Canvas.Font.Color := clWhite;
    Bmp.Canvas.Font.Quality := fqAntialiased;
    Ext := Bmp.Canvas.TextExtent(AGlyph);
    Bmp.Canvas.TextOut((ASize - Ext.cx) div 2, (ASize - Ext.cy) div 2, AGlyph);
    for Y := 0 to ASize - 1 do
    begin
      Line := Bmp.ScanLine[Y];
      for X := 0 to ASize - 1 do
      begin
        A := (Line[X].rgbRed * AOpacity) div 255;
        Line[X].rgbReserved := A;
        Line[X].rgbRed := (GetRValue(C) * A) div 255;
        Line[X].rgbGreen := (GetGValue(C) * A) div 255;
        Line[X].rgbBlue := (GetBValue(C) * A) div 255;
      end;
    end;
    Result := PremultipliedToPng(Bmp);
  finally
    Bmp.Free;
  end;
end;

function CSHubIconGlyph(const AId: string): string;
var I: Integer;
begin
  Result := '';
  if AId = '' then Exit;
  for I := Low(CSHubIconLibrary) to High(CSHubIconLibrary) do
    if CSHubIconLibrary[I].Id = AId then Exit(CSHubIconLibrary[I].Glyph);
end;

function CSHubImportIcon(const AFileName, ADir: string): string;
var Source, Scaled, Final: TWICImage;
    Stream: TMemoryStream;
    W, H: Integer;
    FileName: string;
begin
  Scaled := nil;
  Source := TWICImage.Create;
  Stream := TMemoryStream.Create;
  try
    Source.LoadFromFile(AFileName);
    W := Source.Width;
    H := Source.Height;
    if Source.Empty or (W <= 0) or (H <= 0) then raise EInvalidGraphic.Create(AFileName);
    Final := Source;
    if (W > CSHubIconStoreSize) or (H > CSHubIconStoreSize) then
    begin
      // Fits the box keeping its proportions.
      if W >= H then
        Scaled := Source.CreateScaledCopy(CSHubIconStoreSize, Max(1, MulDiv(H, CSHubIconStoreSize, W)),
          wipmHighQualityCubic)
      else
        Scaled := Source.CreateScaledCopy(Max(1, MulDiv(W, CSHubIconStoreSize, H)), CSHubIconStoreSize,
          wipmHighQualityCubic);
      Final := Scaled;
    end;
    Final.ImageFormat := wifPng;
    Final.SaveToStream(Stream);
    // Named after the content: the same picture loaded twice is one file.
    Stream.Position := 0;
    Result := Copy(LowerCase(THashSHA1.GetHashString(Stream)), 1, 24) + '.png';
    FileName := TPath.Combine(ADir, Result);
    if not TFile.Exists(FileName) then
    begin
      TDirectory.CreateDirectory(ADir);
      Stream.SaveToFile(FileName);
    end;
  finally
    Stream.Free;
    Scaled.Free;
    Source.Free;
  end;
end;

end.
