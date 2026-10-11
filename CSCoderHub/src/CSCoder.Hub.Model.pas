unit CSCoder.Hub.Model;

interface

uses
  System.Classes, System.SysUtils, System.UITypes, Vcl.Menus, Vcl.Dialogs, Vcl.ImgList,
  Vcl.ImageCollection, Vcl.VirtualImageList, CSCoder.Hub.Repository;

type
  /// Pictures of the popup menu items. miNone = no picture.
  TCSHubMenuIcon = (miNone, miOpen, miOpenFolder, miMoveTo, miUp, miDown, miDelete, miAddProjects,
    miRename, miSort, miAddGroup, miAddSection, miCollapseAll, miExpandAll, miExport, miImport,
    miReplace, miLanguage, miIcon);

  /// Data plus every user action (dialogs, menus, IDE calls) behind the views.
  TCSHubModel = class
  private
    FRepo: TCSHubRepository;
    FImages: TImageCollection;
    FSearch: string;
    FMenu: TPopupMenu;
    FMenuIcons: TImageCollection;
    FMenuImages: TVirtualImageList;
    FMenuIconColor: TColor;
    FMenuProject: TCSHubProject;
    FMenuGroup: TCSHubGroup;
    FMenuSection: TCSHubSection;
    FOnChanged: TNotifyEvent;
    procedure BuildImages;
    procedure ExpandAtStartup;
    procedure Commit;
    function Sync(const ARefs: array of PCSHubItem): Boolean;
    procedure SetSearch(const Value: string);
    function ConfigFilter: string;
    function NewMenuItem(AParent: TMenuItem; const ACaption: string; AClick: TNotifyEvent;
      AIcon: TCSHubMenuIcon = miNone): TMenuItem;
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuFolderClick(Sender: TObject);
    procedure MenuMoveProjectClick(Sender: TObject);
    procedure MenuReorderProjectClick(Sender: TObject);
    procedure MenuRemoveProjectClick(Sender: TObject);
    procedure MenuMoveGroupClick(Sender: TObject);
    procedure MenuAddProjectsClick(Sender: TObject);
    procedure MenuRenameGroupClick(Sender: TObject);
    procedure MenuSortGroupClick(Sender: TObject);
    procedure MenuDeleteGroupClick(Sender: TObject);
    procedure MenuIconGroupClick(Sender: TObject);
    procedure MenuIconSectionClick(Sender: TObject);
    procedure MenuAddGroupClick(Sender: TObject);
    procedure MenuRenameSectionClick(Sender: TObject);
    procedure MenuDeleteSectionClick(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    /// Tells the views to redraw (data, search text or language changed).
    procedure Changed;
    /// Reads the file again: another IDE of the same Delphi version may have changed it.
    procedure Refresh;
    procedure OpenProject(AProject: TCSHubProject);
    procedure ShowProjectMenu(AProject: TCSHubProject);
    /// ADelta: -1 = one position up, +1 = one down. Puts the group in manual order.
    function CanReorderProject(AProject: TCSHubProject; ADelta: Integer): Boolean;
    procedure ReorderProject(AProject: TCSHubProject; ADelta: Integer);
    procedure AddProjects(AGroup: TCSHubGroup);
    /// ASection = nil creates a loose group.
    procedure NewGroup(ASection: TCSHubSection = nil);
    procedure RenameGroup(AGroup: TCSHubGroup);
    procedure DeleteGroup(AGroup: TCSHubGroup);
    procedure ToggleGroup(AGroup: TCSHubGroup);
    /// ADelta: -1 = one position up, +1 = one down.
    procedure ReorderGroup(AGroup: TCSHubGroup; ADelta: Integer);
    procedure ShowGroupMenu(AGroup: TCSHubGroup);
    procedure NewSection;
    procedure RenameSection(ASection: TCSHubSection);
    procedure DeleteSection(ASection: TCSHubSection);
    procedure ToggleSection(ASection: TCSHubSection);
    procedure ReorderSection(ASection: TCSHubSection; ADelta: Integer);
    procedure ShowSectionMenu(ASection: TCSHubSection);
    /// Opens the icon window for a category (TCSHubSection) or a group (TCSHubGroup).
    procedure ChooseIcon(AItem: TObject);
    /// Drag and drop from the list: see the drop events of TCSHubListControl.
    procedure DropProject(AProject: TCSHubProject; AGroup: TCSHubGroup; ABefore: TCSHubProject;
      APositioned: Boolean);
    procedure DropGroup(AGroup: TCSHubGroup; ASection: TCSHubSection; ABefore: TObject);
    procedure DropSection(ASection: TCSHubSection; ABefore: TObject);
    /// Every category and every group, loose ones included.
    procedure SetAllCollapsed(AValue: Boolean);
    /// True when at least one category or group is collapsed.
    function AnyCollapsed: Boolean;
    /// Expands everything if anything is collapsed; otherwise collapses everything.
    procedure ToggleAllCollapsed;
    /// Draws the menu pictures in the current text color of the IDE's menus. Call
    /// before building any popup that uses MenuImages.
    procedure PrepareMenuImages;
    /// The "About" window (CSCoder.Hub.About), in the colors of the IDE theme.
    procedure ShowAbout;
    procedure ExportConfig;
    /// AReplace = False keeps what exists and adds what is new.
    procedure ImportConfig(AReplace: Boolean);
    property Repo: TCSHubRepository read FRepo;
    property Images: TImageCollection read FImages;
    /// For popup menus; an item's ImageIndex is Ord(TCSHubMenuIcon) - 1.
    property MenuImages: TVirtualImageList read FMenuImages;
    property Search: string read FSearch write SetSearch;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Themes, ToolsAPI,
  CSCoder.Hub.Images, CSCoder.Hub.Strings, CSCoder.Hub.About, CSCoder.Hub.IconPicker;

const
  NoSectionTag = -1;
  RecentSeedMax = 10; // recent projects offered on the first run
  MenuIconSize = 16; // at 96 DPI
  MenuGlyphs: array[TCSHubMenuIcon] of string = ('', CSHubGlyphOpenFile, CSHubGlyphExplorer,
    CSHubGlyphMoveTo, CSHubGlyphUp, CSHubGlyphDown, CSHubGlyphDelete, CSHubGlyphOpenFolder,
    CSHubGlyphRename, CSHubGlyphSort, CSHubGlyphAdd, CSHubGlyphFolder, CSHubGlyphChevronUp,
    CSHubGlyphChevronDown, CSHubGlyphExport, CSHubGlyphImport, CSHubGlyphReplace, CSHubGlyphLanguage,
    CSHubGlyphIcon);

// Applies the IDE theme to a window of ours.
function FormThemer: TCSHubThemeProc;
begin
  Result :=
    procedure(AForm: TCustomForm)
    var Services: IOTAIDEThemingServices;
    begin
      // The IDE only themes windows of classes it was told about.
      if Supports(BorlandIDEServices, IOTAIDEThemingServices, Services) and Services.IDEThemingEnabled then
      begin
        Services.RegisterFormClass(TCustomFormClass(AForm.ClassType));
        Services.ApplyTheme(AForm);
      end;
    end;
end;

function MenuCaption(const AText: string): string;
begin
  Result := StringReplace(AText, '&', '&&', [rfReplaceAll]);
end;

constructor TCSHubModel.Create;
var Seeded: Integer;
begin
  inherited Create;
  FImages := TImageCollection.Create(nil);
  FMenu := TPopupMenu.Create(nil);
  FMenu.AutoHotkeys := maManual;
  FMenuIcons := TImageCollection.Create(nil);
  FMenuImages := TVirtualImageList.Create(nil);
  FMenuImages.SetSize(MulDiv(MenuIconSize, Screen.PixelsPerInch, 96),
    MulDiv(MenuIconSize, Screen.PixelsPerInch, 96));
  FMenuImages.ImageCollection := FMenuIcons;
  FMenu.Images := FMenuImages;
  FRepo := TCSHubRepository.Create;
  try
    // First run: no list yet. Start with what the IDE already knows, so the panel
    // is never empty for someone who has projects: every favorite in one group,
    // then the recent projects that are not favorites in another.
    if not FRepo.Load then
    begin
      Seeded := FRepo.SeedFavoriteProjects(CSHubBdsRegistryKey);
      Inc(Seeded, FRepo.SeedRecentProjects(CSHubBdsRegistryKey, RecentSeedMax));
      if Seeded > 0 then FRepo.Save;
    end;
  except
    on E: Exception do
      MessageDlg(L(sErrLoad, [E.Message]), mtWarning, [mbOK], 0);
  end;
  ExpandAtStartup;
  BuildImages;
end;

// The IDE always opens with everything expanded (asked by the user). Only in memory:
// what was collapsed stays so in the file until the next change saves this state.
procedure TCSHubModel.ExpandAtStartup;
var S: TCSHubSection;
    G: TCSHubGroup;
begin
  for S in FRepo.Sections do S.Collapsed := False;
  for G in FRepo.Groups do G.Collapsed := False;
end;

destructor TCSHubModel.Destroy;
begin
  FMenu.Free;
  FMenuImages.Free;
  FMenuIcons.Free;
  FImages.Free;
  FRepo.Free;
  inherited;
end;

procedure TCSHubModel.BuildImages;
var Ext: string;
    Stream: TStream;
begin
  // A missing icon only costs the picture, never the plugin.
  for Ext in TArray<string>.Create('dproj', 'groupproj', 'dpr') do
    try
      Stream := CSHubShellIconPng('.' + Ext);
      if Stream <> nil then
        try
          FImages.Add(Ext, Stream);
        finally
          Stream.Free;
        end;
    except
    end;
end;

procedure TCSHubModel.Changed;
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

// Views first: they hold pointers to repository objects that the change may have
// freed, and a failing save opens a dialog that lets them repaint.
procedure TCSHubModel.Commit;
begin
  Changed;
  try
    FRepo.Save;
  except
    on E: Exception do
      MessageDlg(L(sErrSave, [E.Message]), mtError, [mbOK], 0);
  end;
end;

// Another IDE of the same Delphi version shares our file, and each one writes it
// whole. So before changing anything: if the file changed since we read it, read it
// again and carry on with the same items in the new content. False = one of them
// is gone and the action must be dropped.
function TCSHubModel.Sync(const ARefs: array of PCSHubItem): Boolean;
begin
  Result := True;
  if not FRepo.ChangedOnDisk then Exit;
  try
    Result := FRepo.Reload(ARefs);
  except
    // Unreadable: carry on with what is in memory, as when loading fails at startup.
    Exit;
  end;
  // Loading freed what the menus and the views pointed at.
  FMenuProject := nil;
  FMenuGroup := nil;
  FMenuSection := nil;
  Changed;
  if not Result then MessageDlg(L(sChangedElsewhere), mtInformation, [mbOK], 0);
end;

procedure TCSHubModel.Refresh;
begin
  try
    FRepo.Reload([]);
  except
    on E: Exception do
    begin
      Changed;
      MessageDlg(L(sErrLoad, [E.Message]), mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  FMenuProject := nil;
  FMenuGroup := nil;
  FMenuSection := nil;
  Changed;
end;

procedure TCSHubModel.SetSearch(const Value: string);
begin
  if FSearch = Value then Exit;
  FSearch := Value;
  Changed;
end;

function TCSHubModel.ConfigFilter: string;
begin
  Result := L(sFilterConfig) + ' (*.json)|*.json|' + L(sFilterAll) + '|*.*';
end;

function TCSHubModel.NewMenuItem(AParent: TMenuItem; const ACaption: string; AClick: TNotifyEvent;
  AIcon: TCSHubMenuIcon): TMenuItem;
begin
  Result := TMenuItem.Create(FMenu);
  Result.Caption := ACaption;
  Result.OnClick := AClick;
  Result.ImageIndex := Ord(AIcon) - 1;
  AParent.Add(Result);
end;

// The pictures are glyphs of the icon font painted in the color the IDE's theme
// gives to menu text, so they follow light and dark like everything else. They are
// only redrawn when that color changes.
procedure TCSHubModel.PrepareMenuImages;
var Theming: IOTAIDEThemingServices;
    Color: TColor;
    Icon: TCSHubMenuIcon;
    Stream: TStream;
    Size: Integer;
begin
  if not CSHubGlyphFontAvailable then Exit; // menus without pictures
  Color := clMenuText;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) and Theming.IDEThemingEnabled then
    Color := Theming.StyleServices.GetStyleFontColor(sfPopupMenuItemTextNormal);
  Color := ColorToRGB(Color);
  if (FMenuIcons.Count > 0) and (Color = FMenuIconColor) then Exit;
  FMenuIconColor := Color;
  Size := FMenuImages.Width;
  try
    FMenuImages.Clear;
    FMenuIcons.Images.Clear;
    for Icon := Succ(miNone) to High(TCSHubMenuIcon) do
    begin
      Stream := CSHubGlyphPng(MenuGlyphs[Icon], CSHubGlyphFont, Size, Color, 255, MulDiv(Size, 7, 8));
      try
        FMenuIcons.Add(IntToStr(Ord(Icon)), Stream);
      finally
        Stream.Free;
      end;
    end;
    // The list does not pick up pictures added to the collection at run time by
    // itself (AutoFill did nothing here): hand them over.
    FMenuImages.Add('', 0, FMenuIcons.Count - 1);
  except
    // One missing picture would shift every index after it: better none at all.
    FMenuImages.Clear;
    FMenuIcons.Images.Clear;
  end;
end;

{ Projects }

procedure TCSHubModel.OpenProject(AProject: TCSHubProject);
var Actions: IOTAActionServices;
begin
  if AProject = nil then Exit;
  if not TFile.Exists(AProject.FileName) then
  begin
    MessageDlg(L(sErrFileNotFound, [AProject.FileName]), mtWarning, [mbOK], 0);
    Exit;
  end;
  if not Supports(BorlandIDEServices, IOTAActionServices, Actions) then
  begin
    MessageDlg(L(sErrNoService), mtError, [mbOK], 0);
    Exit;
  end;
  try
    Actions.OpenProject(AProject.FileName, True);
  except
    on E: Exception do MessageDlg(L(sErrOpen, [E.Message]), mtError, [mbOK], 0);
  end;
end;

procedure TCSHubModel.ShowProjectMenu(AProject: TCSHubProject);
var Move, Item: TMenuItem;
    G: TCSHubGroup;
begin
  FMenuProject := AProject;
  if FMenuProject = nil then Exit;
  PrepareMenuImages;
  FMenu.Items.Clear;
  NewMenuItem(FMenu.Items, L(sMenuOpen), MenuOpenClick, miOpen).Default := True;
  NewMenuItem(FMenu.Items, L(sMenuOpenFolder), MenuFolderClick, miOpenFolder);
  Move := NewMenuItem(FMenu.Items, L(sMenuMoveTo), nil, miMoveTo);
  for G in FRepo.OrderedGroups do
    if G <> FMenuProject.Group then
      NewMenuItem(Move, MenuCaption(G.Path), MenuMoveProjectClick).Tag := FRepo.Groups.IndexOf(G);
  Move.Enabled := Move.Count > 0;
  NewMenuItem(FMenu.Items, '-', nil);
  Item := NewMenuItem(FMenu.Items, L(sMenuMoveUp), MenuReorderProjectClick, miUp);
  Item.Tag := -1;
  Item.Enabled := CanReorderProject(FMenuProject, -1);
  Item := NewMenuItem(FMenu.Items, L(sMenuMoveDown), MenuReorderProjectClick, miDown);
  Item.Tag := 1;
  Item.Enabled := CanReorderProject(FMenuProject, 1);
  NewMenuItem(FMenu.Items, '-', nil);
  NewMenuItem(FMenu.Items, L(sMenuRemoveShortcut), MenuRemoveProjectClick, miDelete);
  FMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TCSHubModel.MenuOpenClick(Sender: TObject);
begin
  OpenProject(FMenuProject);
end;

procedure TCSHubModel.MenuFolderClick(Sender: TObject);
var Params: string;
begin
  if FMenuProject = nil then Exit;
  if TFile.Exists(FMenuProject.FileName) then
    Params := '/select,"' + FMenuProject.FileName + '"'
  else
    Params := '"' + TPath.GetDirectoryName(FMenuProject.FileName) + '"';
  ShellExecute(0, 'open', 'explorer.exe', PChar(Params), nil, SW_SHOWNORMAL);
end;

procedure TCSHubModel.MenuMoveProjectClick(Sender: TObject);
var I: Integer;
    P: TCSHubProject;
    G: TCSHubGroup;
begin
  I := (Sender as TMenuItem).Tag;
  P := FMenuProject;
  if (P = nil) or (I < 0) or (I >= FRepo.Groups.Count) then Exit;
  G := FRepo.Groups[I];
  if not Sync([@P, @G]) then Exit;
  FRepo.MoveProject(P, G);
  G.Collapsed := False;
  Commit;
end;

// While a search is on, the list hides the neighbours a move would jump over.
function TCSHubModel.CanReorderProject(AProject: TCSHubProject; ADelta: Integer): Boolean;
begin
  Result := (Trim(FSearch) = '') and FRepo.CanReorderProject(AProject, ADelta);
end;

procedure TCSHubModel.ReorderProject(AProject: TCSHubProject; ADelta: Integer);
begin
  if (AProject = nil) or not Sync([@AProject]) then Exit;
  if not CanReorderProject(AProject, ADelta) then Exit;
  FRepo.ReorderProject(AProject, ADelta);
  Commit;
end;

procedure TCSHubModel.MenuReorderProjectClick(Sender: TObject);
begin
  if FMenuProject <> nil then ReorderProject(FMenuProject, (Sender as TMenuItem).Tag);
end;

procedure TCSHubModel.MenuRemoveProjectClick(Sender: TObject);
var P: TCSHubProject;
begin
  P := FMenuProject;
  if P = nil then Exit;
  if MessageDlg(L(sAskRemoveShortcut, [P.Name]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  if not Sync([@P]) then Exit;
  FRepo.RemoveProject(P);
  FMenuProject := nil;
  Commit;
end;

procedure TCSHubModel.AddProjects(AGroup: TCSHubGroup);
var Dialog: TOpenDialog;
    F, Skipped: string;
begin
  if AGroup = nil then Exit;
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Filter := L(sFilterProjects) + '|*.dproj;*.groupproj;*.dpr|' + L(sFilterAll) + '|*.*';
    Dialog.Options := [ofFileMustExist, ofPathMustExist, ofAllowMultiSelect];
    if not Dialog.Execute or not Sync([@AGroup]) then Exit;
    AGroup.Collapsed := False;
    Skipped := '';
    for F in Dialog.Files do
      try
        FRepo.AddProject(F, AGroup);
      except
        on E: Exception do Skipped := Skipped + sLineBreak + TPath.GetFileName(F);
      end;
  finally
    Dialog.Free;
  end;
  Commit;
  if Skipped <> '' then
    MessageDlg(L(sAlreadyAdded) + Skipped, mtInformation, [mbOK], 0);
end;

{ Groups }

procedure TCSHubModel.NewGroup(ASection: TCSHubSection);
var S, Prompt: string;
begin
  S := '';
  if ASection = nil then Prompt := L(sGroupNamePrompt)
  else Prompt := L(sGroupNameInSectionPrompt, [ASection.Name]);
  if not InputQuery(L(sNewGroupTitle), Prompt, S) or (Trim(S) = '') then Exit;
  if not Sync([@ASection]) then Exit;
  FRepo.AddGroup(S, ASection);
  if ASection <> nil then ASection.Collapsed := False;
  Commit;
end;

procedure TCSHubModel.RenameGroup(AGroup: TCSHubGroup);
var S: string;
begin
  S := AGroup.Name;
  if not InputQuery(L(sHintRenameGroup), L(sNewNamePrompt), S) or (Trim(S) = '') then Exit;
  if not Sync([@AGroup]) then Exit;
  try
    FRepo.RenameGroup(AGroup, S);
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  Commit;
end;

procedure TCSHubModel.DeleteGroup(AGroup: TCSHubGroup);
begin
  if MessageDlg(L(sAskDeleteGroup, [AGroup.Name]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  if not Sync([@AGroup]) then Exit;
  FRepo.RemoveGroup(AGroup);
  Commit;
end;

procedure TCSHubModel.ToggleGroup(AGroup: TCSHubGroup);
begin
  if not Sync([@AGroup]) then Exit;
  AGroup.Collapsed := not AGroup.Collapsed;
  Commit;
end;

procedure TCSHubModel.ShowGroupMenu(AGroup: TCSHubGroup);
var Move, Item: TMenuItem;
    I: Integer;
begin
  FMenuGroup := AGroup;
  if FMenuGroup = nil then Exit;
  PrepareMenuImages;
  FMenu.Items.Clear;
  NewMenuItem(FMenu.Items, L(sMenuAddProjects), MenuAddProjectsClick, miAddProjects);
  NewMenuItem(FMenu.Items, L(sMenuRename), MenuRenameGroupClick, miRename);
  NewMenuItem(FMenu.Items, L(sMenuIcon), MenuIconGroupClick, miIcon);
  Move := NewMenuItem(FMenu.Items, L(sMenuMoveToSection), nil, miMoveTo);
  if FMenuGroup.Section <> nil then
    NewMenuItem(Move, L(sNoSection), MenuMoveGroupClick).Tag := NoSectionTag;
  for I := 0 to FRepo.Sections.Count - 1 do
    if FRepo.Sections[I] <> FMenuGroup.Section then
    begin
      Item := NewMenuItem(Move, MenuCaption(FRepo.Sections[I].Name), MenuMoveGroupClick);
      Item.Tag := I;
    end;
  Move.Enabled := Move.Count > 0;
  // Only a group whose projects were moved by hand has something to undo.
  NewMenuItem(FMenu.Items, L(sMenuSortByName), MenuSortGroupClick, miSort).Enabled := FMenuGroup.ManualOrder;
  NewMenuItem(FMenu.Items, '-', nil);
  NewMenuItem(FMenu.Items, L(sMenuDelete), MenuDeleteGroupClick, miDelete);
  FMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TCSHubModel.MenuMoveGroupClick(Sender: TObject);
var I: Integer;
    G: TCSHubGroup;
    Target: TCSHubSection;
begin
  I := (Sender as TMenuItem).Tag;
  G := FMenuGroup;
  if G = nil then Exit;
  Target := nil;
  if I <> NoSectionTag then
  begin
    if (I < 0) or (I >= FRepo.Sections.Count) then Exit;
    Target := FRepo.Sections[I];
  end;
  if not Sync([@G, @Target]) then Exit;
  try
    FRepo.MoveGroup(G, Target);
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  if Target <> nil then Target.Collapsed := False;
  Commit;
end;

procedure TCSHubModel.MenuAddProjectsClick(Sender: TObject);
begin
  if FMenuGroup <> nil then AddProjects(FMenuGroup);
end;

procedure TCSHubModel.MenuRenameGroupClick(Sender: TObject);
begin
  if FMenuGroup <> nil then RenameGroup(FMenuGroup);
end;

procedure TCSHubModel.MenuSortGroupClick(Sender: TObject);
var G: TCSHubGroup;
begin
  G := FMenuGroup;
  if (G = nil) or not Sync([@G]) then Exit;
  FRepo.SortGroupByName(G);
  Commit;
end;

procedure TCSHubModel.MenuDeleteGroupClick(Sender: TObject);
var G: TCSHubGroup;
begin
  G := FMenuGroup;
  FMenuGroup := nil;
  if G <> nil then DeleteGroup(G);
end;

procedure TCSHubModel.ReorderGroup(AGroup: TCSHubGroup; ADelta: Integer);
begin
  if not Sync([@AGroup]) then Exit;
  if not FRepo.CanReorderGroup(AGroup, ADelta) then Exit;
  FRepo.ReorderGroup(AGroup, ADelta);
  Commit;
end;

{ Sections }

procedure TCSHubModel.ShowSectionMenu(ASection: TCSHubSection);
begin
  FMenuSection := ASection;
  if FMenuSection = nil then Exit;
  PrepareMenuImages;
  FMenu.Items.Clear;
  NewMenuItem(FMenu.Items, L(sMenuAddGroup), MenuAddGroupClick, miAddGroup);
  NewMenuItem(FMenu.Items, L(sMenuRename), MenuRenameSectionClick, miRename);
  NewMenuItem(FMenu.Items, L(sMenuIcon), MenuIconSectionClick, miIcon);
  NewMenuItem(FMenu.Items, '-', nil);
  NewMenuItem(FMenu.Items, L(sMenuDelete), MenuDeleteSectionClick, miDelete);
  FMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TCSHubModel.ReorderSection(ASection: TCSHubSection; ADelta: Integer);
begin
  if not Sync([@ASection]) then Exit;
  if not FRepo.CanReorderSection(ASection, ADelta) then Exit;
  FRepo.ReorderSection(ASection, ADelta);
  Commit;
end;

procedure TCSHubModel.MenuAddGroupClick(Sender: TObject);
begin
  if FMenuSection <> nil then NewGroup(FMenuSection);
end;

procedure TCSHubModel.MenuRenameSectionClick(Sender: TObject);
begin
  if FMenuSection <> nil then RenameSection(FMenuSection);
end;

procedure TCSHubModel.MenuDeleteSectionClick(Sender: TObject);
var S: TCSHubSection;
begin
  S := FMenuSection;
  FMenuSection := nil;
  if S <> nil then DeleteSection(S);
end;

procedure TCSHubModel.NewSection;
var S: string;
begin
  S := '';
  if not InputQuery(L(sNewSectionTitle), L(sSectionNamePrompt), S) or (Trim(S) = '') then Exit;
  if not Sync([]) then Exit;
  FRepo.AddSection(S);
  Commit;
end;

procedure TCSHubModel.RenameSection(ASection: TCSHubSection);
var S: string;
begin
  S := ASection.Name;
  if not InputQuery(L(sHintRenameSection), L(sNewNamePrompt), S) or (Trim(S) = '') then Exit;
  if not Sync([@ASection]) then Exit;
  try
    FRepo.RenameSection(ASection, S);
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  Commit;
end;

procedure TCSHubModel.DeleteSection(ASection: TCSHubSection);
var Answer: Integer;
begin
  if Length(FRepo.GroupsOf(ASection)) = 0 then
  begin
    if MessageDlg(L(sAskDeleteEmptySection, [ASection.Name]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    if not Sync([@ASection]) then Exit;
    // Keeps the groups: the other IDE may have just put one in it.
    FRepo.RemoveSection(ASection, True);
    Commit;
    Exit;
  end;
  // The buttons say what they do, so the answer does not depend on reading "Yes"/"No" right.
  Answer := MessageDlg(L(sAskDeleteSection, [ASection.Name]), mtConfirmation, [mbYes, mbNo, mbCancel], 0,
    mbCancel, [L(sBtnKeepGroups), L(sBtnDeleteAll), L(sBtnCancel)]);
  if not (Answer in [mrYes, mrNo]) or not Sync([@ASection]) then Exit;
  if Answer = mrYes then
    FRepo.RemoveSection(ASection, True)
  else if Answer = mrNo then
    FRepo.RemoveSection(ASection, False)
  else
    Exit;
  Commit;
end;

procedure TCSHubModel.ToggleSection(ASection: TCSHubSection);
begin
  if not Sync([@ASection]) then Exit;
  ASection.Collapsed := not ASection.Collapsed;
  Commit;
end;

{ Drag and drop }

procedure TCSHubModel.DropProject(AProject: TCSHubProject; AGroup: TCSHubGroup; ABefore: TCSHubProject;
  APositioned: Boolean);
begin
  if (AProject = nil) or (AGroup = nil) or not Sync([@AProject, @AGroup, @ABefore]) then Exit;
  if APositioned then
    FRepo.PlaceProject(AProject, AGroup, ABefore)
  else
    FRepo.MoveProject(AProject, AGroup);
  AGroup.Collapsed := False; // show where it went
  Commit;
end;

procedure TCSHubModel.DropGroup(AGroup: TCSHubGroup; ASection: TCSHubSection; ABefore: TObject);
begin
  if (AGroup = nil) or not Sync([@AGroup, @ASection, @ABefore]) then Exit;
  try
    FRepo.PlaceGroup(AGroup, ASection, ABefore);
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  if ASection <> nil then ASection.Collapsed := False;
  Commit;
end;

procedure TCSHubModel.DropSection(ASection: TCSHubSection; ABefore: TObject);
begin
  if (ASection = nil) or not Sync([@ASection, @ABefore]) then Exit;
  FRepo.PlaceSection(ASection, ABefore);
  Commit;
end;

procedure TCSHubModel.SetAllCollapsed(AValue: Boolean);
var S: TCSHubSection;
    G: TCSHubGroup;
begin
  if not Sync([]) then Exit;
  for S in FRepo.Sections do S.Collapsed := AValue;
  for G in FRepo.Groups do G.Collapsed := AValue;
  Commit;
end;

function TCSHubModel.AnyCollapsed: Boolean;
var S: TCSHubSection;
    G: TCSHubGroup;
begin
  for S in FRepo.Sections do
    if S.Collapsed then Exit(True);
  for G in FRepo.Groups do
    if G.Collapsed then Exit(True);
  Result := False;
end;

procedure TCSHubModel.ToggleAllCollapsed;
begin
  SetAllCollapsed(not AnyCollapsed);
end;

{ About }

procedure TCSHubModel.ShowAbout;
var Info: TCSHubAboutInfo;
    Theming: IOTAIDEThemingServices;
begin
  Info := Default(TCSHubAboutInfo);
  Info.DataFile := FRepo.FileName;
  Info.BackColor := clBtnFace;
  Info.TextColor := clBtnText;
  Info.AccentColor := clHighlight;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) and Theming.IDEThemingEnabled then
  begin
    Info.BackColor := Theming.StyleServices.GetSystemColor(clBtnFace);
    Info.TextColor := Theming.StyleServices.GetSystemColor(clBtnText);
    Info.AccentColor := Theming.StyleServices.GetSystemColor(clHighlight);
  end;
  CSHubShowAbout(Info, FormThemer());
end;

{ Icons }

procedure TCSHubModel.ChooseIcon(AItem: TObject);
var Info: TCSHubIconPickerInfo;
    Theming: IOTAIDEThemingServices;
    Icon: string;
begin
  if AItem = nil then Exit;
  Info := Default(TCSHubIconPickerInfo);
  if AItem is TCSHubSection then Info.Current := TCSHubSection(AItem).Icon
  else Info.Current := TCSHubGroup(AItem).Icon;
  Info.IconsDir := FRepo.IconsDir;
  Info.BackColor := clBtnFace;
  Info.TextColor := clBtnText;
  Info.AccentColor := clHighlight;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) and Theming.IDEThemingEnabled then
  begin
    Info.BackColor := Theming.StyleServices.GetSystemColor(clBtnFace);
    Info.TextColor := Theming.StyleServices.GetSystemColor(clBtnText);
    Info.AccentColor := Theming.StyleServices.GetSystemColor(clHighlight);
  end;
  if not CSHubPickIcon(Info, FormThemer(), Icon) then Exit;
  if not Sync([@AItem]) then Exit;
  if AItem is TCSHubSection then TCSHubSection(AItem).Icon := Icon
  else TCSHubGroup(AItem).Icon := Icon;
  Commit;
end;

procedure TCSHubModel.MenuIconGroupClick(Sender: TObject);
begin
  if FMenuGroup <> nil then ChooseIcon(FMenuGroup);
end;

procedure TCSHubModel.MenuIconSectionClick(Sender: TObject);
begin
  if FMenuSection <> nil then ChooseIcon(FMenuSection);
end;

{ Export / import }

procedure TCSHubModel.ExportConfig;
var Dialog: TSaveDialog;
begin
  Dialog := TSaveDialog.Create(nil);
  try
    Dialog.Title := L(sTitleExport);
    Dialog.Filter := ConfigFilter;
    Dialog.DefaultExt := 'json';
    Dialog.FileName := 'HubProjetos.json';
    Dialog.Options := Dialog.Options + [ofOverwritePrompt, ofPathMustExist];
    if not Dialog.Execute then Exit;
    try
      // With the pictures the user loaded as icons, so they travel too.
      FRepo.SaveToFile(Dialog.FileName, True);
    except
      on E: Exception do
        MessageDlg(L(sErrExport, [E.Message]), mtError, [mbOK], 0);
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TCSHubModel.ImportConfig(AReplace: Boolean);
var Dialog: TOpenDialog;
    Source: TCSHubRepository;
    Added: Integer;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := L(sTitleImport);
    Dialog.Filter := ConfigFilter;
    Dialog.Options := Dialog.Options + [ofFileMustExist, ofPathMustExist];
    if not Dialog.Execute then Exit;
    Added := -1;
    Source := TCSHubRepository.Create;
    try
      try
        // Read into a scratch repository first: a bad file must not touch ours.
        Source.LoadFromFile(Dialog.FileName);
        // An empty file, or a JSON that is not ours, would wipe the list when replacing.
        if (Source.Sections.Count = 0) and (Source.Groups.Count = 0) then
        begin
          MessageDlg(L(sImportEmpty), mtWarning, [mbOK], 0);
          Exit;
        end;
        if AReplace and (MessageDlg(L(sAskReplace), mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then Exit;
        if AReplace then
        begin
          // Loading frees every object the views point at: refresh them right after.
          FRepo.LoadFromFile(Dialog.FileName);
          Changed;
        end
        else
        begin
          Sync([]); // merge into what the other IDE may have just saved
          Added := FRepo.MergeFrom(Source);
        end;
      except
        on E: Exception do
        begin
          Changed;
          MessageDlg(L(sErrImport, [E.Message]), mtError, [mbOK], 0);
          Exit;
        end;
      end;
    finally
      Source.Free;
    end;
    Commit;
    if Added >= 0 then
      MessageDlg(L(sImported, [Added]), mtInformation, [mbOK], 0);
  finally
    Dialog.Free;
  end;
end;

end.
