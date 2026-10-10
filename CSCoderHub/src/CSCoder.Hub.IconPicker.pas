unit CSCoder.Hub.IconPicker;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  Vcl.ImageCollection, CSCoder.Hub.About;

type
  /// What the caller knows and this unit does not: the icon in use, where loaded
  /// pictures are kept and the colors of the IDE theme.
  TCSHubIconPickerInfo = record
    Current: string;     // '' = none
    IconsDir: string;
    BackColor: TColor;
    TextColor: TColor;
    AccentColor: TColor;
  end;

  /// The window that picks the icon of a category or a group: the library, "no
  /// icon" and "load image". It has no IDE dependency, so a test program can
  /// build and render it.
  TCSHubIconPickerForm = class(TForm)
  private
    FInfo: TCSHubIconPickerInfo;
    FGrid: TPaintBox;
    FHot: Integer;
    FIcon: string;
    FGlyphFont: Boolean;
    FLoaded: TImageCollection;
    FLoadedRect: TRect;
    function P(AValue: Integer): Integer;
    function NewButton(const AText: string; X, AWidth: Integer; AClick: TNotifyEvent): TButton;
    function CellRect(AIndex: Integer): TRect;
    function CellAt(X, Y: Integer): Integer;
    procedure GridPaint(Sender: TObject);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GridMouseLeave(Sender: TObject);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NoneClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
  public
    constructor CreatePicker(const AInfo: TCSHubIconPickerInfo);
    destructor Destroy; override;
    /// The choice, once the window closes with mrOk; '' = no icon.
    property Icon: string read FIcon;
  end;

/// True when the user chose something; AIcon = '' then means "no icon".
function CSHubPickIcon(const AInfo: TCSHubIconPickerInfo; const AThemer: TCSHubThemeProc;
  out AIcon: string): Boolean;

implementation

uses
  System.IOUtils, CSCoder.Hub.Images, CSCoder.Hub.Repository, CSCoder.Hub.Strings;

const
  FontName = 'Segoe UI';
  // At 96 DPI.
  Pad = 16;
  CellSize = 44;
  GlyphHeight = 22;
  ButtonHeight = 28;
  ButtonGap = 8;
  LoadedSize = 24; // the loaded picture in use, shown beside the buttons

function CSHubPickIcon(const AInfo: TCSHubIconPickerInfo; const AThemer: TCSHubThemeProc;
  out AIcon: string): Boolean;
var Form: TCSHubIconPickerForm;
begin
  Form := TCSHubIconPickerForm.CreatePicker(AInfo);
  try
    if Assigned(AThemer) then AThemer(Form);
    Result := Form.ShowModal = mrOk;
    AIcon := Form.Icon;
  finally
    Form.Free;
  end;
end;

{ TCSHubIconPickerForm }

constructor TCSHubIconPickerForm.CreatePicker(const AInfo: TCSHubIconPickerInfo);
var Rows, Y, X: Integer;
    Name, FileName: string;
    Btn: TButton;
begin
  inherited CreateNew(nil);
  FInfo := AInfo;
  FHot := -1;
  FGlyphFont := CSHubGlyphFontAvailable;
  FLoaded := TImageCollection.Create(nil);
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Caption := L(sIconTitle);
  Color := FInfo.BackColor;
  Font.Name := FontName;

  Rows := (Length(CSHubIconLibrary) + CSHubIconColumns - 1) div CSHubIconColumns;
  ClientWidth := P(2 * Pad + CSHubIconColumns * CellSize);
  Y := P(Pad) + Rows * P(CellSize) + P(12);
  ClientHeight := Y + P(ButtonHeight) + P(Pad);

  FGrid := TPaintBox.Create(Self);
  FGrid.Parent := Self;
  FGrid.SetBounds(0, 0, ClientWidth, Y);
  FGrid.OnPaint := GridPaint;
  FGrid.OnMouseMove := GridMouseMove;
  FGrid.OnMouseLeave := GridMouseLeave;
  FGrid.OnMouseDown := GridMouseDown;

  X := P(Pad);
  Btn := NewButton(L(sIconNone), X, P(100), NoneClick);
  Btn.Top := Y;
  Inc(X, Btn.Width + P(ButtonGap));
  Btn := NewButton(L(sIconLoad), X, P(150), LoadClick);
  Btn.Top := Y;
  Inc(X, Btn.Width + P(ButtonGap));
  Btn := NewButton(L(sBtnCancel), ClientWidth - P(Pad) - P(90), P(90), nil);
  Btn.Top := Y;
  Btn.ModalResult := mrCancel;
  Btn.Cancel := True; // Esc

  // The loaded picture in use, if it is still there, between the buttons.
  if CSHubIconFile(FInfo.Current, Name) then
    try
      FileName := TPath.Combine(FInfo.IconsDir, Name);
      if TFile.Exists(FileName) then
      begin
        FLoaded.Add(Name, FileName);
        FLoadedRect := Bounds(X + P(4), Y + (P(ButtonHeight) - P(LoadedSize)) div 2, P(LoadedSize), P(LoadedSize));
        FGrid.Height := ClientHeight; // it is painted by the grid's paint box
        FGrid.SendToBack;
      end;
    except
      // not a picture any more: nothing to show
    end;
end;

destructor TCSHubIconPickerForm.Destroy;
begin
  inherited;
  FLoaded.Free;
end;

function TCSHubIconPickerForm.P(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, CurrentPPI, 96);
end;

function TCSHubIconPickerForm.NewButton(const AText: string; X, AWidth: Integer; AClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(X, 0, AWidth, P(ButtonHeight));
  Result.Font.Name := FontName;
  Result.Font.Height := -P(12);
  Result.Caption := AText;
  Result.OnClick := AClick;
end;

function TCSHubIconPickerForm.CellRect(AIndex: Integer): TRect;
begin
  Result := Bounds(P(Pad) + (AIndex mod CSHubIconColumns) * P(CellSize),
    P(Pad) + (AIndex div CSHubIconColumns) * P(CellSize), P(CellSize), P(CellSize));
end;

function TCSHubIconPickerForm.CellAt(X, Y: Integer): Integer;
var I: Integer;
begin
  for I := Low(CSHubIconLibrary) to High(CSHubIconLibrary) do
    if CellRect(I).Contains(Point(X, Y)) then Exit(I);
  Result := -1;
end;

procedure TCSHubIconPickerForm.GridPaint(Sender: TObject);
var C: TCanvas;
    I: Integer;
    R: TRect;
    Glyph: string;
    Back, Fore, Accent: TColor;

  function Mix(A, B: TColor; APercentA: Integer): TColor;
  begin
    Result := RGB((GetRValue(A) * APercentA + GetRValue(B) * (100 - APercentA)) div 100,
      (GetGValue(A) * APercentA + GetGValue(B) * (100 - APercentA)) div 100,
      (GetBValue(A) * APercentA + GetBValue(B) * (100 - APercentA)) div 100);
  end;

begin
  C := FGrid.Canvas;
  Back := ColorToRGB(FInfo.BackColor);
  Fore := ColorToRGB(FInfo.TextColor);
  Accent := ColorToRGB(FInfo.AccentColor);
  if FLoaded.Count > 0 then FLoaded.Draw(C, FLoadedRect, 0, True);
  if not FGlyphFont then Exit; // no library without the icon font
  C.Font.Name := CSHubGlyphFont;
  C.Font.Style := [];
  C.Font.Height := -P(GlyphHeight);
  C.Font.Color := Fore;
  for I := Low(CSHubIconLibrary) to High(CSHubIconLibrary) do
  begin
    R := CellRect(I);
    R.Inflate(-P(2), -P(2));
    C.Pen.Style := psClear;
    C.Brush.Style := bsSolid;
    if I = FHot then
    begin
      C.Brush.Color := Mix(Fore, Back, 14);
      C.FillRect(R);
    end;
    if CSHubIconLibrary[I].Id = FInfo.Current then
    begin
      // The one in use: a frame in the highlight color of the theme.
      C.Pen.Style := psSolid;
      C.Pen.Width := P(2);
      C.Pen.Color := Mix(Accent, Fore, 65);
      C.Brush.Style := bsClear;
      C.Rectangle(R.Left + P(1), R.Top + P(1), R.Right, R.Bottom);
    end;
    C.Brush.Style := bsClear;
    Glyph := CSHubIconLibrary[I].Glyph;
    DrawText(C.Handle, PChar(Glyph), Length(Glyph), R, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;
end;

procedure TCSHubIconPickerForm.GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var Cell: Integer;
begin
  Cell := CellAt(X, Y);
  if not FGlyphFont then Cell := -1;
  if Cell = FHot then Exit;
  FHot := Cell;
  if Cell >= 0 then FGrid.Cursor := crHandPoint else FGrid.Cursor := crDefault;
  FGrid.Invalidate;
end;

procedure TCSHubIconPickerForm.GridMouseLeave(Sender: TObject);
begin
  if FHot < 0 then Exit;
  FHot := -1;
  FGrid.Invalidate;
end;

procedure TCSHubIconPickerForm.GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var Cell: Integer;
begin
  Cell := CellAt(X, Y);
  if (Button <> mbLeft) or (Cell < 0) or not FGlyphFont then Exit;
  FIcon := CSHubIconLibrary[Cell].Id;
  ModalResult := mrOk;
end;

procedure TCSHubIconPickerForm.NoneClick(Sender: TObject);
begin
  FIcon := '';
  ModalResult := mrOk;
end;

procedure TCSHubIconPickerForm.LoadClick(Sender: TObject);
var Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := L(sIconLoad);
    Dialog.Filter := L(sFilterImages) + ' (*.png;*.ico;*.jpg;*.jpeg;*.bmp;*.gif)|*.png;*.ico;*.jpg;*.jpeg;*.bmp;*.gif|' +
      L(sFilterAll) + '|*.*';
    Dialog.Options := Dialog.Options + [ofFileMustExist, ofPathMustExist];
    if not Dialog.Execute then Exit;
    try
      // Copied (reduced, as PNG) to our own folder: the user's file may move or change.
      FIcon := CSHubIconFilePrefix + CSHubImportIcon(Dialog.FileName, FInfo.IconsDir);
    except
      on E: Exception do
      begin
        MessageDlg(L(sErrIconLoad, [E.Message]), mtError, [mbOK], 0);
        Exit;
      end;
    end;
    ModalResult := mrOk;
  finally
    Dialog.Free;
  end;
end;

end.
