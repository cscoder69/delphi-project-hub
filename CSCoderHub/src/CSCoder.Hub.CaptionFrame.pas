unit CSCoder.Hub.CaptionFrame;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.StdCtrls, Vcl.Buttons, Vcl.Menus, CSCoder.Hub.Model;

type
  /// Caption of the Welcome Page panel: title, counters, the refresh button
  /// (reads the file again), search, the expand / collapse all button, the add button (category or group), the settings
  /// button (collapse / expand all, export / import, language) and, set apart at
  /// the end, the about button.
  TCSHubCaptionFrame = class(TFrame)
  private
    FModel: TCSHubModel;
    FTitle: TLabel;
    FCounts: TLabel;
    FRefreshBtn: TSpeedButton;
    FAddBtn: TSpeedButton;
    FToggleBtn: TSpeedButton;
    FAboutBtn: TSpeedButton;
    FConfigBtn: TSpeedButton;
    FMenu: TPopupMenu;
    FSearch: TEdit;
    function NewButton(ALeft: Integer; const AGlyph, AFallback: string; AClick: TNotifyEvent): TSpeedButton;
    function NewItem(AParent: TMenuItem; const ACaption: string; AClick: TNotifyEvent;
      AIcon: TCSHubMenuIcon = miNone): TMenuItem;
    procedure PopupBelow(AButton: TSpeedButton);
    procedure RefreshClick(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure ToggleClick(Sender: TObject);
    procedure AboutClick(Sender: TObject);
    procedure ConfigClick(Sender: TObject);
    procedure NewGroupClick(Sender: TObject);
    procedure NewSectionClick(Sender: TObject);
    procedure CollapseAllClick(Sender: TObject);
    procedure ExpandAllClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure ImportMergeClick(Sender: TObject);
    procedure ImportReplaceClick(Sender: TObject);
    procedure LanguageClick(Sender: TObject);
    procedure SearchChange(Sender: TObject);
  protected
    procedure PaintWindow(DC: HDC); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent; AModel: TCSHubModel); reintroduce;
    /// Sets every text from the current language. Call after the language changes.
    procedure ApplyLanguage;
    /// Refreshes what follows the data: the "N categorias - N grupos - N projetos"
    /// text beside the search box and the hint of the expand / collapse all button.
    procedure UpdateCounts;
    procedure SetDimColor(AColor: TColor);
  end;

implementation

uses
  ToolsAPI, ToolsAPI.WelcomePage, CSCoder.Hub.Images, CSCoder.Hub.Strings;

{$R *.dfm}

const
  SearchHeight = 24;
  AutoLanguageTag = -1;

constructor TCSHubCaptionFrame.Create(AOwner: TComponent; AModel: TCSHubModel);
var Theming: IOTAIDEThemingServices;
begin
  inherited Create(AOwner);
  FModel := AModel;
  FMenu := TPopupMenu.Create(Self);
  FMenu.AutoHotkeys := maManual;
  FMenu.Images := FModel.MenuImages; // same pictures as the menus of the list

  // Align only (no anchors): the frame has no window handle yet. Left sets the
  // order among controls sharing the same Align.
  FTitle := TLabel.Create(Self);
  FTitle.Parent := Self;
  FTitle.Left := 0;
  FTitle.AlignWithMargins := True;
  FTitle.Margins.SetBounds(12, 0, 0, 0); // same side padding as the list
  FTitle.Align := alLeft;
  FTitle.Layout := tlCenter;
  FTitle.Font.Name := 'Segoe UI';
  FTitle.Font.Height := 20;
  FTitle.Font.Color := clWindowText;

  FCounts := TLabel.Create(Self);
  FCounts.Parent := Self;
  FCounts.Left := 60; // right-aligned group: left of the refresh button
  FCounts.AlignWithMargins := True;
  FCounts.Margins.SetBounds(8, 4, 4, 0);
  FCounts.Align := alRight;
  // Grows to the left: its right edge, which decides its place among the right-aligned
  // controls, must not pass the refresh button's when the text gets longer.
  FCounts.Alignment := taRightJustify;
  FCounts.Layout := tlCenter;
  FCounts.Font.Name := 'Segoe UI';
  FCounts.Font.Height := -12;

  // Right-aligned controls are ordered by their right edge (Left + 30 here). The
  // search box ends at 360, so: toggle 370, add 400, settings 480, about 530.
  // The four buttons touch each other. The refresh button ends at 175, left of
  // the search box and right of the counters.
  FAboutBtn := NewButton(500, CSHubGlyphHelp, '?', AboutClick);
  FAboutBtn.Margins.SetBounds(0, 8, 12, 8); // 12: same side padding as the list
  // This glyph fills its whole box, unlike the others: drawn smaller to match them.
  if CSHubGlyphFontAvailable then FAboutBtn.Font.Height := 11 else FAboutBtn.Font.Height := 15;
  FConfigBtn := NewButton(450, CSHubGlyphSettings, '...', ConfigClick);
  FConfigBtn.Margins.SetBounds(0, 8, 0, 8);
  FAddBtn := NewButton(370, CSHubGlyphAdd, '+', AddClick);
  FAddBtn.Margins.SetBounds(0, 8, 0, 8);
  FToggleBtn := NewButton(340, CSHubGlyphChevronDown, #$25BE, ToggleClick);
  FToggleBtn.Margins.SetBounds(6, 8, 0, 8);
  FRefreshBtn := NewButton(145, CSHubGlyphRefresh, #$21BB, RefreshClick);
  FRefreshBtn.Margins.SetBounds(0, 8, 0, 8);

  FSearch := TEdit.Create(Self);
  FSearch.Parent := Self;
  FSearch.Left := 180;
  FSearch.Width := 180;
  FSearch.AlignWithMargins := True;
  FSearch.Margins.SetBounds(6, 7, 0, 7); // 6 on each side, as before the toggle button
  FSearch.Align := alRight;
  FSearch.Text := FModel.Search;
  FSearch.OnChange := SearchChange;

  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) and
    Theming.IDEThemingEnabled then
    Theming.ApplyTheme(Self);
  ApplyLanguage;
end;

function TCSHubCaptionFrame.NewButton(ALeft: Integer; const AGlyph, AFallback: string;
  AClick: TNotifyEvent): TSpeedButton;
begin
  Result := TSpeedButton.Create(Self);
  Result.Parent := Self;
  Result.Left := ALeft;
  Result.Width := 30;
  Result.AlignWithMargins := True;
  Result.Align := alRight;
  Result.Flat := True;
  if CSHubGlyphFontAvailable then
  begin
    Result.Font.Name := CSHubGlyphFont;
    Result.Font.Height := 15;
    Result.Caption := AGlyph;
  end
  else
  begin
    Result.Font.Height := 20;
    Result.Caption := AFallback;
  end;
  Result.ShowHint := True;
  Result.OnClick := AClick;
end;

procedure TCSHubCaptionFrame.ApplyLanguage;
begin
  FTitle.Caption := L(sTitle);
  FSearch.TextHint := L(sSearchHint);
  FRefreshBtn.Hint := L(sHintRefresh);
  FAddBtn.Hint := L(sHintAdd);
  FConfigBtn.Hint := L(sHintConfig);
  FAboutBtn.Hint := L(sHintAbout);
  UpdateCounts;
end;

procedure TCSHubCaptionFrame.UpdateCounts;
var Text: string;
begin
  Text := '';
  if FModel.Repo.Sections.Count > 0 then
    Text := CSHubCount(FModel.Repo.Sections.Count, sSection1, sSectionN) + '  ' + #$00B7 + '  ';
  FCounts.Caption := Text + CSHubCount(FModel.Repo.Groups.Count, sGroup1, sGroupN) + '  ' + #$00B7 + '  ' +
    CSHubCount(FModel.Repo.Projects.Count, sProject1, sProjectN);
  // Picture and hint tell what the next click does: open everything (down) while
  // anything is collapsed, close everything (up) otherwise.
  if FModel.AnyCollapsed then
  begin
    FToggleBtn.Hint := L(sMenuExpandAll);
    if CSHubGlyphFontAvailable then FToggleBtn.Caption := CSHubGlyphChevronDown
    else FToggleBtn.Caption := #$25BE;
  end
  else
  begin
    FToggleBtn.Hint := L(sMenuCollapseAll);
    if CSHubGlyphFontAvailable then FToggleBtn.Caption := CSHubGlyphChevronUp
    else FToggleBtn.Caption := #$25B4;
  end;
end;

procedure TCSHubCaptionFrame.SetDimColor(AColor: TColor);
begin
  // Own color instead of the style's font color, which would make it as bright as the title.
  FCounts.StyleElements := FCounts.StyleElements - [seFont];
  FCounts.Font.Color := AColor;
end;

procedure TCSHubCaptionFrame.Resize;
var Gap: Integer;
begin
  inherited;
  // The host decides the caption height: keep the edit at its natural height,
  // vertically centered, instead of stretching with alRight.
  if FSearch = nil then Exit;
  Gap := (ClientHeight - MulDiv(SearchHeight, FCurrentPPI, 96)) div 2;
  if Gap < 0 then Gap := 0;
  FSearch.Margins.SetBounds(FSearch.Margins.Left, Gap, 0, ClientHeight -
    MulDiv(SearchHeight, FCurrentPPI, 96) - Gap);
end;

procedure TCSHubCaptionFrame.PaintWindow(DC: HDC);
const
  CaptionOpacity = 64;
var Canvas: TCanvas;
    Theming: IOTAIDEThemingServices;
    Background: INTAWelcomePageBackgroundService;
    BaseColor: TColor;
begin
  inherited;
  // Same translucent background the built-in Welcome Page captions use.
  if not Supports(WelcomePagePluginService, INTAWelcomePageBackgroundService, Background) then Exit;
  BaseColor := clNone;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) then
    BaseColor := Theming.StyleServices.GetSystemColor(Color);
  Canvas := TCanvas.Create;
  try
    Canvas.Handle := DC;
    Background.PaintBackgroundTo(Canvas, Self, BaseColor, CaptionOpacity);
  finally
    Canvas.Handle := 0;
    Canvas.Free;
  end;
end;

function TCSHubCaptionFrame.NewItem(AParent: TMenuItem; const ACaption: string;
  AClick: TNotifyEvent; AIcon: TCSHubMenuIcon): TMenuItem;
begin
  Result := TMenuItem.Create(FMenu);
  Result.Caption := ACaption;
  Result.OnClick := AClick;
  Result.ImageIndex := Ord(AIcon) - 1;
  AParent.Add(Result);
end;

procedure TCSHubCaptionFrame.PopupBelow(AButton: TSpeedButton);
var P: TPoint;
begin
  P := AButton.ClientToScreen(Point(0, AButton.Height));
  FMenu.Popup(P.X, P.Y);
end;

// Menus are rebuilt on every click, so they always follow the current language.
procedure TCSHubCaptionFrame.AddClick(Sender: TObject);
begin
  FModel.PrepareMenuImages;
  FMenu.Items.Clear;
  NewItem(FMenu.Items, L(sMenuAddSection), NewSectionClick, miAddSection);
  NewItem(FMenu.Items, L(sMenuAddGroup), NewGroupClick, miAddGroup);
  PopupBelow(FAddBtn);
end;

procedure TCSHubCaptionFrame.RefreshClick(Sender: TObject);
begin
  FModel.Refresh;
end;

procedure TCSHubCaptionFrame.ToggleClick(Sender: TObject);
begin
  FModel.ToggleAllCollapsed;
end;

procedure TCSHubCaptionFrame.AboutClick(Sender: TObject);
begin
  FModel.ShowAbout;
end;

procedure TCSHubCaptionFrame.ConfigClick(Sender: TObject);
var Languages, Item: TMenuItem;
    Lang: TCSHubLang;
begin
  FModel.PrepareMenuImages;
  FMenu.Items.Clear;
  NewItem(FMenu.Items, L(sMenuCollapseAll), CollapseAllClick, miCollapseAll);
  NewItem(FMenu.Items, L(sMenuExpandAll), ExpandAllClick, miExpandAll);
  NewItem(FMenu.Items, '-', nil);
  NewItem(FMenu.Items, L(sMenuExport), ExportClick, miExport);
  NewItem(FMenu.Items, L(sMenuImportMerge), ImportMergeClick, miImport);
  NewItem(FMenu.Items, L(sMenuImportReplace), ImportReplaceClick, miReplace);
  NewItem(FMenu.Items, '-', nil);
  Languages := NewItem(FMenu.Items, L(sMenuLanguage), nil, miLanguage);
  Item := NewItem(Languages, L(sLangAuto), LanguageClick);
  Item.Tag := AutoLanguageTag;
  Item.RadioItem := True;
  Item.Checked := CSHubLanguageIsAuto;
  NewItem(Languages, '-', nil);
  for Lang := Low(TCSHubLang) to High(TCSHubLang) do
  begin
    // Each language is listed in its own name, whatever the current one is.
    Item := NewItem(Languages, CSHubLangNames[Lang], LanguageClick);
    Item.Tag := Ord(Lang);
    Item.RadioItem := True;
    Item.Checked := (not CSHubLanguageIsAuto) and (CSHubLanguage = Lang);
  end;
  PopupBelow(FConfigBtn);
end;

procedure TCSHubCaptionFrame.NewGroupClick(Sender: TObject);
begin
  FModel.NewGroup;
end;

procedure TCSHubCaptionFrame.NewSectionClick(Sender: TObject);
begin
  FModel.NewSection;
end;

procedure TCSHubCaptionFrame.CollapseAllClick(Sender: TObject);
begin
  FModel.SetAllCollapsed(True);
end;

procedure TCSHubCaptionFrame.ExpandAllClick(Sender: TObject);
begin
  FModel.SetAllCollapsed(False);
end;

procedure TCSHubCaptionFrame.ExportClick(Sender: TObject);
begin
  FModel.ExportConfig;
end;

procedure TCSHubCaptionFrame.ImportMergeClick(Sender: TObject);
begin
  FModel.ImportConfig(False);
end;

procedure TCSHubCaptionFrame.ImportReplaceClick(Sender: TObject);
begin
  FModel.ImportConfig(True);
end;

procedure TCSHubCaptionFrame.LanguageClick(Sender: TObject);
var Tag: Integer;
begin
  Tag := (Sender as TMenuItem).Tag;
  if Tag = AutoLanguageTag then
    CSHubSetLanguageAuto
  else if (Tag >= Ord(Low(TCSHubLang))) and (Tag <= Ord(High(TCSHubLang))) then
    CSHubSetLanguage(TCSHubLang(Tag))
  else
    Exit;
  ApplyLanguage;
  FModel.Changed; // the list redraws with the new texts
end;

procedure TCSHubCaptionFrame.SearchChange(Sender: TObject);
begin
  FModel.Search := FSearch.Text;
end;

end.
