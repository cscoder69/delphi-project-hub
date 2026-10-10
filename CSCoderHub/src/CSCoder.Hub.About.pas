unit CSCoder.Hub.About;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.ImageCollection;

type
  /// What the caller knows and this unit does not: where the data lives and the
  /// colors of the IDE theme. Everything else comes from the package itself.
  TCSHubAboutInfo = record
    DataFile: string;
    BackColor: TColor;   // background of a dialog
    TextColor: TColor;
    AccentColor: TColor; // highlight color of the theme
  end;

  /// Lets the caller apply the IDE theme to each window this unit opens.
  TCSHubThemeProc = reference to procedure(AForm: TCustomForm);

  TCSHubAboutGlyph = record
    Bounds: TRect;
    Text: string;
    Height: Integer;
    Color: TColor;
  end;

  /// The "About" window. It has no IDE dependency, so a test program can build
  /// and render it.
  TCSHubAboutForm = class(TForm)
  private
    FInfo: TCSHubAboutInfo;
    FThemer: TCSHubThemeProc;
    FDim: TColor;
    FLine: TColor;
    FAccent: TColor;
    FTile: TColor;
    FSemibold: Boolean;
    FGlyphFont: Boolean;
    FBack: TPaintBox;
    FIcons: TImageCollection;
    FDataMenu: TPopupMenu;
    FLicense: string;
    FIconRect: TRect;
    FBoxRect: TRect;
    FTileRect: TRect;
    FRules: TArray<TRect>;
    FGlyphs: TArray<TCSHubAboutGlyph>;
    function P(AValue: Integer): Integer;
    function NewLabel(const AText: string; X, Y, AHeight: Integer; AColor: TColor;
      ASemibold: Boolean = False; AWidth: Integer = 0): TLabel;
    function NewLink(const AText, AUrl: string; X, Y: Integer): TLabel;
    function NewButton(const AText: string; X, Y, AWidth: Integer; AClick: TNotifyEvent): TButton;
    procedure AddRule(const R: TRect);
    procedure AddGlyph(const AGlyph: string; const R: TRect; AHeight: Integer; AColor: TColor);
    procedure Build;
    procedure BackPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure LinkClick(Sender: TObject);
    procedure LinkEnter(Sender: TObject);
    procedure LinkLeave(Sender: TObject);
    procedure LicenseClick(Sender: TObject);
    procedure SiteClick(Sender: TObject);
    procedure DataClick(Sender: TObject);
    procedure CopyPathClick(Sender: TObject);
    procedure OpenFolderClick(Sender: TObject);
  public
    constructor CreateAbout(const AInfo: TCSHubAboutInfo; const AThemer: TCSHubThemeProc);
    destructor Destroy; override;
  end;

  /// A class of its own so the IDE can be told to theme it.
  TCSHubLicenseForm = class(TForm);

const
  CSHubDeveloper = 'CS.Coder';
  CSHubSiteUrl = 'https://www.cscoder.com.br';
  /// The open-source repository: support (issues) and releases live there.
  CSHubProjectUrl = 'https://github.com/cscoder69/delphi-project-hub';
  CSHubSiteText = 'www.cscoder.com.br';
  CSHubMail = 'contato@cscoder.com.br';

procedure CSHubShowAbout(const AInfo: TCSHubAboutInfo; const AThemer: TCSHubThemeProc);

implementation

uses
  Winapi.ShellAPI, System.Math, System.IOUtils, Vcl.Clipbrd, CSCoder.Hub.Images, CSCoder.Hub.Strings;

const
  FontName = 'Segoe UI';
  SemiboldName = 'Segoe UI Semibold';
  Compatibility = 'Delphi 11, 12, 13';
  // Resources linked into the package (CSCoder.HubProjetos.rc).
  IconResource = 'CSHUBICON';
  LicenseResource = 'CSHUBLICENSE';   // LICENSE.txt, the text that counts
  SummaryResource = 'CSHUBLICENCA';   // LICENCA.txt, the summary in Portuguese

function MixColor(A, B: TColor; APercentA: Integer): TColor;
var CA, CB: TColor;
begin
  CA := ColorToRGB(A);
  CB := ColorToRGB(B);
  Result := RGB(
    (GetRValue(CA) * APercentA + GetRValue(CB) * (100 - APercentA)) div 100,
    (GetGValue(CA) * APercentA + GetGValue(CB) * (100 - APercentA)) div 100,
    (GetBValue(CA) * APercentA + GetBValue(CB) * (100 - APercentA)) div 100);
end;

function ResourceText(const AName: string): string;
var Stream: TResourceStream;
    Lines: TStringList;
begin
  Result := '';
  if FindResource(HInstance, PChar(AName), RT_RCDATA) = 0 then Exit;
  Stream := TResourceStream.Create(HInstance, AName, RT_RCDATA);
  Lines := TStringList.Create;
  try
    Lines.LoadFromStream(Stream, TEncoding.UTF8);
    Result := Lines.Text;
  finally
    Lines.Free;
    Stream.Free;
  end;
end;

// Both read from the package file itself, so the window never disagrees with it:
// the ProductVersion text of its version resource (it may end in a letter, which
// the four numbers cannot hold), and the day it was built.
procedure PackageVersion(out AVersion, ABuild: string);
type
  TTranslation = packed record
    Language, CodePage: Word;
  end;
var FileName: array[0..MAX_PATH] of Char;
    Size, Dummy, Len: DWORD;
    Buffer: TBytes;
    Info: PVSFixedFileInfo;
    Translation: ^TTranslation;
    Text: PChar;
begin
  AVersion := '';
  ABuild := '';
  if GetModuleFileName(HInstance, FileName, Length(FileName)) = 0 then Exit;
  try
    ABuild := FormatDateTime('yyyymmdd', TFile.GetLastWriteTime(FileName));
  except
    // no date, no build line content
  end;
  Size := GetFileVersionInfoSize(FileName, Dummy);
  if Size = 0 then Exit;
  SetLength(Buffer, Size);
  if not GetFileVersionInfo(FileName, 0, Size, Buffer) then Exit;
  if VerQueryValue(Buffer, '\VarFileInfo\Translation', Pointer(Translation), Len) and (Len >= SizeOf(TTranslation)) and
    VerQueryValue(Buffer, PChar(Format('\StringFileInfo\%.4x%.4x\ProductVersion',
      [Translation.Language, Translation.CodePage])), Pointer(Text), Len) and (Len > 0) then
    AVersion := Trim(Text);
  if AVersion <> '' then Exit;
  if not VerQueryValue(Buffer, '\', Pointer(Info), Len) then Exit;
  AVersion := Format('%d.%d.%d.%d', [HiWord(Info.dwFileVersionMS), LoWord(Info.dwFileVersionMS),
    HiWord(Info.dwFileVersionLS), LoWord(Info.dwFileVersionLS)]);
end;

procedure OpenUrl(const AUrl: string);
begin
  ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
end;

procedure CSHubShowAbout(const AInfo: TCSHubAboutInfo; const AThemer: TCSHubThemeProc);
var Form: TCSHubAboutForm;
begin
  Form := TCSHubAboutForm.CreateAbout(AInfo, AThemer);
  try
    if Assigned(AThemer) then AThemer(Form);
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

{ TCSHubAboutForm }

constructor TCSHubAboutForm.CreateAbout(const AInfo: TCSHubAboutInfo; const AThemer: TCSHubThemeProc);
begin
  inherited CreateNew(nil);
  FInfo := AInfo;
  FThemer := AThemer;
  // Every color comes from the three the theme gave us.
  FDim := MixColor(FInfo.TextColor, FInfo.BackColor, 60);
  FLine := MixColor(FInfo.TextColor, FInfo.BackColor, 18);
  // The highlight color alone can be too close to the background: pull it toward the text.
  FAccent := MixColor(FInfo.AccentColor, FInfo.TextColor, 65);
  FTile := MixColor(FInfo.AccentColor, FInfo.BackColor, 30);
  FSemibold := Screen.Fonts.IndexOf(SemiboldName) >= 0;
  FGlyphFont := CSHubGlyphFontAvailable;
  FIcons := TImageCollection.Create(nil);
  Build;
end;

destructor TCSHubAboutForm.Destroy;
begin
  inherited;
  FIcons.Free;
end;

function TCSHubAboutForm.P(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, CurrentPPI, 96);
end;

// Positions and sizes arrive already scaled. AWidth > 0 wraps the text in that width.
function TCSHubAboutForm.NewLabel(const AText: string; X, Y, AHeight: Integer; AColor: TColor;
  ASemibold: Boolean; AWidth: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Self;
  Result.ShowAccelChar := False;
  Result.Transparent := True;
  // Our own colors, not the font color of the style.
  Result.StyleElements := Result.StyleElements - [seFont];
  Result.Font.Name := FontName;
  if ASemibold then
    if FSemibold then Result.Font.Name := SemiboldName else Result.Font.Style := [fsBold];
  Result.Font.Height := -AHeight;
  Result.Font.Color := AColor;
  Result.Left := X;
  Result.Top := Y;
  if AWidth > 0 then
  begin
    // Width first, with auto-size off: an empty auto-sized label collapses and
    // would then wrap the text in almost no width.
    Result.AutoSize := False;
    Result.Width := AWidth;
    Result.WordWrap := True;
    Result.Caption := AText;
    Result.AutoSize := True; // now only the height follows the text
  end
  else
    Result.Caption := AText;
end;

function TCSHubAboutForm.NewLink(const AText, AUrl: string; X, Y: Integer): TLabel;
begin
  Result := NewLabel(AText, X, Y, P(13), FAccent);
  Result.Cursor := crHandPoint;
  Result.Hint := AUrl; // where it goes, shown on hover and used by the click
  Result.ShowHint := True;
  Result.OnClick := LinkClick;
  Result.OnMouseEnter := LinkEnter;
  Result.OnMouseLeave := LinkLeave;
end;

function TCSHubAboutForm.NewButton(const AText: string; X, Y, AWidth: Integer; AClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(X, Y, AWidth, P(34));
  Result.Font.Name := FontName;
  Result.Font.Height := -P(13);
  Result.Caption := AText;
  Result.OnClick := AClick;
end;

procedure TCSHubAboutForm.AddRule(const R: TRect);
begin
  FRules := FRules + [R];
end;

procedure TCSHubAboutForm.AddGlyph(const AGlyph: string; const R: TRect; AHeight: Integer; AColor: TColor);
var G: TCSHubAboutGlyph;
begin
  G.Bounds := R;
  G.Text := AGlyph;
  G.Height := AHeight;
  G.Color := AColor;
  FGlyphs := FGlyphs + [G];
end;

procedure TCSHubAboutForm.Build;
const
  ClientW = 820;
  FeatureGlyphs: array[0..3] of string = (#$E8B7, #$E721, #$E713, #$E943);
  FeatureTitles: array[0..3] of TCSHubStr = (sFeatOrgTitle, sFeatFastTitle, sFeatProdTitle, sFeatDelphiTitle);
  FeatureTexts: array[0..3] of TCSHubStr = (sFeatOrgText, sFeatFastText, sFeatProdText, sFeatDelphiText);
  LinkGlyphs: array[0..2] of string = (#$E774, #$E715, #$E897);
  RowPitch = 28;
var Lbl: TLabel;
    Btn: TButton;
    Stream: TResourceStream;
    Version, BuildNo: string;
    X, Y, I, LeftEnd, TopEnd, ColumnW: Integer;

  procedure Row(ALabelX, AValueX, AValueW: Integer; const ALabel, AValue: string);
  var Value: TLabel;
  begin
    NewLabel(ALabel, ALabelX, Y, P(13), FDim);
    Value := NewLabel(AValue, AValueX, Y, P(13), FInfo.TextColor);
    if Value.Width > AValueW then
    begin
      // A long translation: cut it at the end, whole text in the hint.
      Value.AutoSize := False;
      Value.Width := AValueW;
      Value.EllipsisPosition := epEndEllipsis;
      Value.Hint := AValue;
      Value.ShowHint := True;
    end;
    Inc(Y, P(RowPitch));
  end;

  procedure NewMenuItem(const ACaption: string; AClick: TNotifyEvent);
  var Item: TMenuItem;
  begin
    Item := TMenuItem.Create(FDataMenu);
    Item.Caption := ACaption;
    Item.OnClick := AClick;
    FDataMenu.Items.Add(Item);
  end;

begin
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Caption := L(sHintAbout);
  Color := FInfo.BackColor;
  Font.Name := FontName;
  KeyPreview := True;
  OnKeyPress := FormKeyPress;
  ClientWidth := P(ClientW);

  // Rules, the license frame, the icon and the glyphs are painted here, under the labels.
  FBack := TPaintBox.Create(Self);
  FBack.Parent := Self;
  FBack.Align := alClient;
  FBack.OnPaint := BackPaint;

  if FindResource(HInstance, IconResource, RT_RCDATA) <> 0 then
  begin
    Stream := TResourceStream.Create(HInstance, IconResource, RT_RCDATA);
    try
      FIcons.Add('icon', Stream);
    finally
      Stream.Free;
    end;
  end;
  FLicense := ResourceText(LicenseResource);
  if (FLicense <> '') and (CSHubLanguage = lgPortuguese) and (ResourceText(SummaryResource) <> '') then
    FLicense := ResourceText(SummaryResource) + sLineBreak + StringOfChar('-', 60) + sLineBreak + sLineBreak + FLicense;
  PackageVersion(Version, BuildNo);

  { Left: the product }
  FIconRect := Rect(P(24), P(24), P(120), P(120));
  NewLabel(L(sTitle), P(140), P(22), P(28), FInfo.TextColor, True);
  Lbl := NewLabel(L(sAboutBy), P(140), P(62), P(15), FDim);
  NewLabel(CSHubDeveloper, Lbl.BoundsRect.Right + P(5), P(62), P(15), FInfo.TextColor);
  Lbl := NewLabel(L(sAboutTagline), P(140), P(88), P(13), FDim, False, P(300));
  Y := Max(P(142), Lbl.BoundsRect.Bottom + P(14));
  AddRule(Rect(P(24), Y, P(440), Y + 1));
  Inc(Y, P(14));
  Row(P(24), P(170), P(270), L(sAboutVersionLabel), Version);
  Row(P(24), P(170), P(270), L(sAboutBuild), BuildNo);
  Row(P(24), P(170), P(270), L(sAboutCompat), Compatibility);
  // Only the file name shows; the whole path is in the hint, and a click (either
  // button) offers to copy it or to open its folder.
  NewLabel(L(sAboutDataFile), P(24), Y, P(13), FDim);
  FDataMenu := TPopupMenu.Create(Self);
  FDataMenu.AutoHotkeys := maManual;
  NewMenuItem(L(sAboutCopyPath), CopyPathClick);
  NewMenuItem(L(sAboutOpenFolder), OpenFolderClick);
  Lbl := NewLink(ExtractFileName(FInfo.DataFile), FInfo.DataFile, P(170), Y);
  Lbl.OnClick := DataClick;
  Lbl.PopupMenu := FDataMenu;
  LeftEnd := Y + P(RowPitch);

  { Right: the license }
  FBoxRect := Rect(P(476), P(24), P(796), P(210));
  FTileRect := Rect(P(492), P(40), P(528), P(76));
  AddGlyph(#$E73E, FTileRect, P(18), FAccent);
  NewLabel(L(sAboutLicFree), P(540), P(38), P(15), FInfo.TextColor, True);
  NewLabel(L(sAboutLicSub), P(540), P(60), P(12), FDim);
  AddRule(Rect(P(492), P(90), P(780), P(90) + 1));
  Y := P(100);
  Row(P(492), P(640), P(140), L(sAboutLicType), L(sAboutLicTypeValue));
  Row(P(492), P(640), P(140), L(sAboutLicCommercial), L(sAboutAllowed));
  Row(P(492), P(640), P(140), L(sAboutLicRedist), L(sAboutUnmodified));
  Row(P(492), P(640), P(140), L(sAboutLicData), L(sAboutNone));
  // Side by side under the frame, short captions; the hints say what each one does.
  Btn := NewButton(L(sAboutLicenseTitle), P(476), P(222), P(154), LicenseClick);
  Btn.Hint := L(sAboutLicenseDetails);
  Btn.ShowHint := True;
  Btn.Enabled := FLicense <> '';
  Btn := NewButton(L(sAboutUpdates), P(642), P(222), P(154), SiteClick);
  Btn.Hint := L(sAboutCheckUpdates);
  Btn.ShowHint := True;

  TopEnd := Max(LeftEnd, P(256)) + P(20);
  AddRule(Rect(P(458), P(24), P(458) + 1, TopEnd - P(20)));
  AddRule(Rect(P(24), TopEnd, P(796), TopEnd + 1));

  { What it does }
  Y := TopEnd + P(18);
  ColumnW := (P(ClientW) - 2 * P(24)) div 4;
  for I := 0 to 3 do
  begin
    X := P(24) + I * ColumnW;
    AddGlyph(FeatureGlyphs[I], Rect(X, Y, X + P(32), Y + P(36)), P(24), FAccent);
    NewLabel(L(FeatureTitles[I]), X + P(44), Y, P(13), FInfo.TextColor, True);
    NewLabel(L(FeatureTexts[I]), X + P(44), Y + P(20), P(12), FDim, False, ColumnW - P(52));
  end;
  Inc(Y, P(58));
  AddRule(Rect(P(24), Y, P(796), Y + 1));

  { Who makes it }
  Inc(Y, P(18));
  NewLabel(CSHubDeveloper, P(24), Y, P(26), FInfo.TextColor, True);
  NewLabel(L(sAboutSlogan), P(25), Y + P(40), P(10), FDim);
  for I := 0 to 2 do
    AddGlyph(LinkGlyphs[I], Rect(P(300), Y + I * P(24), P(320), Y + I * P(24) + P(20)), P(14), FAccent);
  NewLink(CSHubSiteText, CSHubSiteUrl, P(328), Y + P(1));
  NewLink(CSHubMail, 'mailto:' + CSHubMail, P(328), Y + P(25));
  NewLink(L(sAboutSupport), CSHubProjectUrl + '/issues', P(328), Y + P(49));
  AddRule(Rect(P(560), Y, P(560) + 1, Y + P(68)));
  NewLabel(L(sAboutRights, [L(sTitle), CSHubDeveloper]), P(580), Y + P(14), P(12), FDim, False, P(216));
  ClientHeight := Y + P(72) + P(20);
end;

procedure TCSHubAboutForm.BackPaint(Sender: TObject);
var C: TCanvas;
    R: TRect;
    G: TCSHubAboutGlyph;
begin
  C := FBack.Canvas;
  C.Brush.Style := bsSolid;
  C.Brush.Color := FLine;
  for R in FRules do C.FillRect(R);

  C.Pen.Width := 1;
  C.Pen.Color := FLine;
  C.Brush.Style := bsClear;
  C.RoundRect(FBoxRect.Left, FBoxRect.Top, FBoxRect.Right, FBoxRect.Bottom, P(10), P(10));
  C.Pen.Color := FTile;
  C.Brush.Style := bsSolid;
  C.Brush.Color := FTile;
  C.RoundRect(FTileRect.Left, FTileRect.Top, FTileRect.Right, FTileRect.Bottom, P(8), P(8));

  if FIcons.Count > 0 then FIcons.Draw(C, FIconRect, 0, True);

  if not FGlyphFont then Exit;
  C.Brush.Style := bsClear;
  C.Font.Name := CSHubGlyphFont;
  C.Font.Style := [];
  for G in FGlyphs do
  begin
    C.Font.Height := -G.Height;
    C.Font.Color := G.Color;
    R := G.Bounds;
    DrawText(C.Handle, PChar(G.Text), Length(G.Text), R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;
end;

procedure TCSHubAboutForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
  begin
    Key := #0;
    ModalResult := mrCancel;
  end;
end;

procedure TCSHubAboutForm.LinkClick(Sender: TObject);
begin
  OpenUrl((Sender as TLabel).Hint);
end;

procedure TCSHubAboutForm.LinkEnter(Sender: TObject);
begin
  (Sender as TLabel).Font.Style := [fsUnderline];
end;

procedure TCSHubAboutForm.LinkLeave(Sender: TObject);
begin
  (Sender as TLabel).Font.Style := [];
end;

// There is nowhere to ask for the latest version and the plugin never goes online
// by itself: the user's browser opens the site instead.
procedure TCSHubAboutForm.SiteClick(Sender: TObject);
begin
  // "Check for updates": the releases page of the repository.
  OpenUrl(CSHubProjectUrl + '/releases');
end;

procedure TCSHubAboutForm.DataClick(Sender: TObject);
begin
  FDataMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TCSHubAboutForm.CopyPathClick(Sender: TObject);
begin
  Clipboard.AsText := FInfo.DataFile;
end;

// The file only exists after the first change is saved: fall back to its folder,
// and to the nearest one that does exist.
procedure TCSHubAboutForm.OpenFolderClick(Sender: TObject);
var Dir, Params: string;
begin
  if TFile.Exists(FInfo.DataFile) then
    Params := '/select,"' + FInfo.DataFile + '"'
  else
  begin
    Dir := TPath.GetDirectoryName(FInfo.DataFile);
    while (Dir <> '') and not TDirectory.Exists(Dir) do Dir := TPath.GetDirectoryName(Dir);
    if Dir = '' then Exit;
    Params := '"' + Dir + '"';
  end;
  ShellExecute(0, 'open', 'explorer.exe', PChar(Params), nil, SW_SHOWNORMAL);
end;

procedure TCSHubAboutForm.LicenseClick(Sender: TObject);
var Form: TCSHubLicenseForm;
    Bottom: TPanel;
    Button: TButton;
    Memo: TMemo;
begin
  Form := TCSHubLicenseForm.CreateNew(Self);
  try
    Form.BorderStyle := bsDialog;
    Form.Position := poOwnerFormCenter;
    Form.Caption := L(sAboutLicenseDetails);
    Form.Font.Name := FontName;
    Form.ClientWidth := P(640);
    Form.ClientHeight := P(480);

    Bottom := TPanel.Create(Form);
    Bottom.Parent := Form;
    Bottom.Align := alBottom;
    Bottom.Height := P(58);
    Bottom.BevelOuter := bvNone;
    Bottom.ShowCaption := False;
    Button := TButton.Create(Form);
    Button.Parent := Bottom;
    Button.Width := P(96);
    Button.AlignWithMargins := True;
    Button.Margins.SetBounds(0, P(12), P(16), P(14));
    Button.Align := alRight;
    Button.Caption := L(sBtnClose);
    Button.Default := True;
    Button.Cancel := True;
    Button.ModalResult := mrOk;

    Memo := TMemo.Create(Form);
    Memo.Parent := Form;
    Memo.AlignWithMargins := True;
    Memo.Margins.SetBounds(P(16), P(16), P(16), 0);
    Memo.Align := alClient;
    Memo.ReadOnly := True;
    Memo.ScrollBars := ssVertical;
    Memo.Font.Height := -P(13);
    Memo.Lines.Text := FLicense;

    if Assigned(FThemer) then FThemer(Form);
    Form.ActiveControl := Button;
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

end.
