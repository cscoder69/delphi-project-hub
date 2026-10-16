unit CSCoder.Hub.ListControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types,
  System.UITypes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.ImageCollection, CSCoder.Hub.Repository;

type
  TCSHubCellKind = (ckSection, ckSectionEmpty, ckGroup, ckGroupEmpty, ckProject);
  TCSHubPart = (hpNone, hpBody, hpAdd, hpUp, hpDown, hpMore, hpMenu, hpThumb);
  /// What is being dragged with the mouse, if anything.
  TCSHubDragKind = (dkNone, dkProject, dkGroup, dkSection);

  TCSHubCell = record
    Kind: TCSHubCellKind;
    Bounds: TRect; // content coordinates (before scrolling)
    Section: TCSHubSection;
    Group: TCSHubGroup;
    Project: TCSHubProject;
    Count: Integer;      // projects
    GroupCount: Integer; // groups, for a section
    Collapsed: Boolean;
    CanUp: Boolean;   // not already first among its neighbours
    CanDown: Boolean;
  end;

  TCSHubProjectEvent = procedure(Sender: TObject; AProject: TCSHubProject) of object;
  TCSHubGroupEvent = procedure(Sender: TObject; AGroup: TCSHubGroup) of object;
  TCSHubSectionEvent = procedure(Sender: TObject; ASection: TCSHubSection) of object;
  /// ADelta: -1 = one position up, +1 = one down.
  TCSHubProjectMoveEvent = procedure(Sender: TObject; AProject: TCSHubProject; ADelta: Integer) of object;
  TCSHubGroupMoveEvent = procedure(Sender: TObject; AGroup: TCSHubGroup; ADelta: Integer) of object;
  TCSHubSectionMoveEvent = procedure(Sender: TObject; ASection: TCSHubSection; ADelta: Integer) of object;
  /// A project was dropped on AGroup. APositioned: right before ABefore (nil = last);
  /// otherwise just "into the group", which keeps the order it has.
  TCSHubProjectDropEvent = procedure(Sender: TObject; AProject: TCSHubProject; AGroup: TCSHubGroup;
    ABefore: TCSHubProject; APositioned: Boolean) of object;
  /// A group was dropped in ASection (nil = top level), right before ABefore (nil = last).
  TCSHubGroupDropEvent = procedure(Sender: TObject; AGroup: TCSHubGroup; ASection: TCSHubSection;
    ABefore: TObject) of object;
  /// A section was dropped right before the top-level item ABefore (nil = last).
  TCSHubSectionDropEvent = procedure(Sender: TObject; ASection: TCSHubSection; ABefore: TObject) of object;
  TCSHubBackgroundEvent = procedure(Sender: TObject; ACanvas: TCanvas) of object;

  /// Owner-drawn list of sections, groups and projects, styled after the
  /// Welcome Page lists. It has no IDE dependency so it can run in a test app.
  TCSHubListControl = class(TCustomControl)
  private
    FRepo: TCSHubRepository;
    FImages: TImageCollection;
    // Pictures the user loaded as icons, read from the icons folder when first drawn.
    FIconImages: TImageCollection;
    FIconMissing: TStringList;
    FSectionIconSize: Integer;
    FGroupIconSize: Integer;
    FSearch: string;
    FNeedle: string;
    FCells: TList<TCSHubCell>;
    FContentHeight: Integer;
    FScrollY: Integer;
    FHotCell: Integer;
    FHotPart: TCSHubPart;
    FDownCell: Integer;
    FDownPart: TCSHubPart;
    FDragging: Boolean;   // the scroll thumb
    FDragOffset: Integer;
    // Dragging an item: FPressed until the mouse moves past the threshold, then FDragKind.
    FPressed: Boolean;
    FPressPos: TPoint;
    FPressCell: TCSHubCell;
    FDragKind: TCSHubDragKind;
    FDragProject: TCSHubProject;
    FDragGroup: TCSHubGroup;
    FDragSection: TCSHubSection;
    FDragPos: TPoint;
    FDropping: Boolean;
    FDropValid: Boolean;
    FDropPositioned: Boolean;
    FDropGroup: TCSHubGroup;
    FDropSection: TCSHubSection;
    FDropBefore: TObject;
    FDropMark: TRect;      // insertion bar, content coordinates
    FDropHighlight: TRect; // header of the group or section that will receive, content coordinates
    FScrollTimer: TTimer;
    FSavedCursor: TCursor;
    FTextColor: TColor;
    FDimColor: TColor;
    FBuffer: TBitmap;
    FDot: TBitmap;
    FGlyphFont: Boolean;
    FSemibold: Boolean;
    FOnOpenProject: TCSHubProjectEvent;
    FOnProjectMenu: TCSHubProjectEvent;
    FOnProjectMove: TCSHubProjectMoveEvent;
    FOnGroupAdd: TCSHubGroupEvent;
    FOnGroupMove: TCSHubGroupMoveEvent;
    FOnGroupToggle: TCSHubGroupEvent;
    FOnGroupMenu: TCSHubGroupEvent;
    FOnSectionAdd: TCSHubSectionEvent;
    FOnSectionMove: TCSHubSectionMoveEvent;
    FOnSectionToggle: TCSHubSectionEvent;
    FOnSectionMenu: TCSHubSectionEvent;
    FOnProjectDrop: TCSHubProjectDropEvent;
    FOnGroupDrop: TCSHubGroupDropEvent;
    FOnSectionDrop: TCSHubSectionDropEvent;
    FOnPaintBackground: TCSHubBackgroundEvent;
    function S(AValue: Integer): Integer;
    function Matches(AProject: TCSHubProject): Boolean;
    function MatchesOf(AGroup: TCSHubGroup): TArray<TCSHubProject>;
    procedure Rebuild;
    function AddGroupCells(AGroup: TCSHubGroup; ALeft, ARight, ASpace: Integer; var Y: Integer): Boolean;
    procedure SetScrollY(AValue: Integer);
    procedure SetSearch(const Value: string);
    procedure SetHot(ACell: Integer; APart: TCSHubPart);
    function HitTest(X, Y: Integer; out APart: TCSHubPart): Integer;
    function HeaderButtonRect(const R: TRect; AIndex: Integer): TRect;
    function MenuButtonRect(const R: TRect): TRect;
    function ProjectArrowRect(const R: TRect; AUp: Boolean): TRect;
    function ThumbRect: TRect;
    function TextWidthOf(const AText: string; AStyle: TFontStyles): Integer;
    function LoadedIcon(const AName: string): Integer;
    /// What to draw for an icon value: a glyph, a picture index, or neither.
    procedure ResolveIcon(const AIcon: string; out AGlyph: string; out AImage: Integer);
    function HeaderHeight(const AIcon: string; ADefault, AIconSize: Integer): Integer;
    function EmptyLinkRect(const ACell: TCSHubCell): TRect;
    function PartHint(ACell: Integer; APart: TCSHubPart): string;
    function DisabledColor: TColor;
    procedure BlendRect(ACanvas: TCanvas; const R: TRect; AColor: TColor; AAlpha: Byte);
    procedure DrawGlyph(ACanvas: TCanvas; const R: TRect; APart: TCSHubPart; AHot: Boolean;
      AEnabled: Boolean = True; const AGlyph: string = '');
    procedure DrawHeader(ACanvas: TCanvas; const R: TRect; AIndex: Integer);
    procedure DrawProject(ACanvas: TCanvas; const R: TRect; AIndex: Integer);
    procedure DrawEmpty(ACanvas: TCanvas; const R: TRect; AIndex: Integer);
    procedure DrawDrag(ACanvas: TCanvas);
    function CellNear(const P: TPoint): Integer;
    function GroupBlock(AGroup: TCSHubGroup): TRect;
    function TopBlock(AItem: TObject): TRect;
    procedure StartItemDrag;
    procedure UpdateDrop;
    procedure ResetDrag;
    procedure EndItemDrag(ADrop: Boolean);
    procedure ScrollTick(Sender: TObject);
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMCancelMode(var Message: TMessage); message WM_CANCELMODE;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Call after the repository changed. Cells point at repository objects, so
    /// this must run before the next paint whenever one of them was freed.
    procedure Reload;
    property Repo: TCSHubRepository read FRepo write FRepo;
    property Images: TImageCollection read FImages write FImages;
    property Search: string read FSearch write SetSearch;
    property TextColor: TColor read FTextColor write FTextColor;
    /// Side of the optional icon of a category / group header, at 96 DPI. A header
    /// with an icon grows to hold it; one without keeps its usual height.
    property SectionIconSize: Integer read FSectionIconSize write FSectionIconSize;
    property GroupIconSize: Integer read FGroupIconSize write FGroupIconSize;
    property DimColor: TColor read FDimColor write FDimColor;
    property OnOpenProject: TCSHubProjectEvent read FOnOpenProject write FOnOpenProject;
    property OnProjectMenu: TCSHubProjectEvent read FOnProjectMenu write FOnProjectMenu;
    /// Up / down arrows on a project.
    property OnProjectMove: TCSHubProjectMoveEvent read FOnProjectMove write FOnProjectMove;
    /// "+" on a group: add projects to it.
    property OnGroupAdd: TCSHubGroupEvent read FOnGroupAdd write FOnGroupAdd;
    /// Up / down arrows on a group.
    property OnGroupMove: TCSHubGroupMoveEvent read FOnGroupMove write FOnGroupMove;
    /// Click on a header outside its buttons: collapse or expand.
    property OnGroupToggle: TCSHubGroupEvent read FOnGroupToggle write FOnGroupToggle;
    /// "..." on a group, or right click on its header.
    property OnGroupMenu: TCSHubGroupEvent read FOnGroupMenu write FOnGroupMenu;
    /// "+" on a section: add a group to it.
    property OnSectionAdd: TCSHubSectionEvent read FOnSectionAdd write FOnSectionAdd;
    property OnSectionMove: TCSHubSectionMoveEvent read FOnSectionMove write FOnSectionMove;
    property OnSectionToggle: TCSHubSectionEvent read FOnSectionToggle write FOnSectionToggle;
    /// "..." on a section, or right click on its header.
    property OnSectionMenu: TCSHubSectionEvent read FOnSectionMenu write FOnSectionMenu;
    /// Drag and drop: the list only says what was dropped where.
    property OnProjectDrop: TCSHubProjectDropEvent read FOnProjectDrop write FOnProjectDrop;
    property OnGroupDrop: TCSHubGroupDropEvent read FOnGroupDrop write FOnGroupDrop;
    property OnSectionDrop: TCSHubSectionDropEvent read FOnSectionDrop write FOnSectionDrop;
    property OnPaintBackground: TCSHubBackgroundEvent read FOnPaintBackground write FOnPaintBackground;
    property Color;
  end;

implementation

uses
  System.Math, System.IOUtils, CSCoder.Hub.Images, CSCoder.Hub.Strings;

const
  // Metrics at 96 DPI, taken from the built-in Welcome Page list.
  // Every distance between blocks is decided by whoever lays them out (Rebuild and
  // AddGroupCells), never by the blocks themselves, so no two margins ever add up.
  SidePadding = 12;   // left and right of the whole list (was 20; the user wanted the categories nearer the edge)
  TopSpace = 20;      // caption to the first line
  BottomSpace = 20;
  SectionHeight = 28;
  SectionSpace = 32;  // above a category, and above a loose group that follows one
  SectionAfter = 16;  // category header to its first group (or its empty line)
  SectionIndent = 16; // groups inside a section
  GroupHeight = 24;
  GroupSpace = 24;    // between group blocks
  GroupAfter = 12;    // group header to its projects (or its empty line)
  ProjectIndent = 20; // projects, from the left of their group
  ItemHeight = 52;    // 40 px icon + 6 above and below
  ColumnGap = 24;
  RowGap = 16;
  EmptyHeight = 24;
  HeaderIndent = 24;  // room for the collapse chevron
  DefaultSectionIconSize = 32; // optional icon between the chevron and the name
  DefaultGroupIconSize = 28;
  IconBefore = 8;     // chevron to icon, from where the chevron's drawing ends
  IconGap = 10;       // icon to name
  ChevronEnd = 17;    // the 10 px chevron is centered at 12
  IconPad = 4;        // above and below an icon taller than its header
  HeaderButtons = 4;  // add | up, down, more
  SeparatorGap = 10;  // extra room for the rule between add and the arrows
  RuleGap = 12;       // between the header rule and what sits at each end of it
  MinColumnWidth = 260;
  ScrollStrip = 12;   // inside the right padding
  DragScrollZone = 28; // dragging this close to the top or bottom edge scrolls the list
  DragScrollStep = 14;
  FontName = 'Segoe UI';
  SemiboldName = 'Segoe UI Semibold'; // weight 600; bold stands in where it is missing

constructor TCSHubListControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];
  FCells := TList<TCSHubCell>.Create;
  FBuffer := TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;
  FDot := TBitmap.Create;
  FDot.PixelFormat := pf24bit;
  FDot.SetSize(1, 1);
  FIconImages := TImageCollection.Create(nil);
  FIconMissing := TStringList.Create;
  FSectionIconSize := DefaultSectionIconSize;
  FGroupIconSize := DefaultGroupIconSize;
  FGlyphFont := CSHubGlyphFontAvailable;
  FSemibold := Screen.Fonts.IndexOf(SemiboldName) >= 0;
  FHotCell := -1;
  FDownCell := -1;
  FTextColor := clWindowText;
  FDimColor := clGrayText;
  TabStop := True;
  ShowHint := True;
  Width := 320;
  Height := 200;
end;

destructor TCSHubListControl.Destroy;
begin
  // Destroy the window first, then the data its message handlers read.
  inherited;
  FreeAndNil(FIconMissing);
  FreeAndNil(FIconImages);
  FreeAndNil(FDot);
  FreeAndNil(FBuffer);
  FreeAndNil(FCells);
end;

function TCSHubListControl.S(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, FCurrentPPI, 96);
end;

procedure TCSHubListControl.Reload;
var P: TPoint;
begin
  if csDestroying in ComponentState then Exit;
  Rebuild;
  // Keep the hover state in sync without waiting for the next mouse move.
  if HandleAllocated then
  begin
    P := ScreenToClient(Mouse.CursorPos);
    if ClientRect.Contains(P) then
    begin
      FHotCell := HitTest(P.X, P.Y, FHotPart);
      Hint := PartHint(FHotCell, FHotPart);
    end;
  end;
  Invalidate;
end;

procedure TCSHubListControl.SetSearch(const Value: string);
begin
  if FSearch = Value then Exit;
  FSearch := Value;
  FScrollY := 0;
  Reload;
end;

function TCSHubListControl.Matches(AProject: TCSHubProject): Boolean;
begin
  Result := (FNeedle = '') or (Pos(FNeedle, UpperCase(AProject.Name)) > 0) or
    (Pos(FNeedle, UpperCase(AProject.FileName)) > 0);
end;

function TCSHubListControl.MatchesOf(AGroup: TCSHubGroup): TArray<TCSHubProject>;
var P: TCSHubProject;
begin
  Result := nil;
  // By name, or in the user's order when the group has one.
  for P in FRepo.DisplayProjectsOf(AGroup) do
    if Matches(P) then Result := Result + [P];
end;

// A group is one block: its header, then its projects or the empty line.
// ASpace: room above the block, only spent when the group does show. Returns
// whether it did.
function TCSHubListControl.AddGroupCells(AGroup: TCSHubGroup; ALeft, ARight, ASpace: Integer;
  var Y: Integer): Boolean;
var Found: TArray<TCSHubProject>;
    Cell: TCSHubCell;
    Columns, ColumnWidth, Left1, Width, Rows, I: Integer;
begin
  Found := MatchesOf(AGroup);
  // While searching, groups without a match are noise.
  Result := (FNeedle = '') or (Length(Found) > 0);
  if not Result then Exit;
  Inc(Y, S(ASpace));

  Cell := Default(TCSHubCell);
  Cell.Kind := ckGroup;
  Cell.Group := AGroup;
  Cell.Section := AGroup.Section;
  Cell.Count := Length(Found);
  // A search shows its matches even inside collapsed groups.
  Cell.Collapsed := (FNeedle = '') and AGroup.Collapsed;
  Cell.CanUp := FRepo.CanReorderGroup(AGroup, -1);
  Cell.CanDown := FRepo.CanReorderGroup(AGroup, 1);
  Cell.Bounds := Rect(ALeft, Y, ARight, Y + HeaderHeight(AGroup.Icon, GroupHeight, FGroupIconSize));
  FCells.Add(Cell);
  Inc(Y, Cell.Bounds.Height);

  if Cell.Collapsed then Exit; // header only
  Inc(Y, S(GroupAfter));
  Left1 := ALeft + S(ProjectIndent);
  if Length(Found) = 0 then
  begin
    Cell := Default(TCSHubCell);
    Cell.Kind := ckGroupEmpty;
    Cell.Group := AGroup;
    Cell.Section := AGroup.Section;
    Cell.Bounds := Rect(Left1, Y, ARight, Y + S(EmptyHeight));
    FCells.Add(Cell);
    Inc(Y, S(EmptyHeight));
    Exit;
  end;

  // Equal columns with a gap between them. A narrow panel gets fewer columns, not
  // narrower projects.
  Width := Max(1, ARight - Left1);
  Columns := Max(1, (Width + S(ColumnGap)) div (S(MinColumnWidth) + S(ColumnGap)));
  ColumnWidth := Max(1, (Width - (Columns - 1) * S(ColumnGap)) div Columns);
  for I := 0 to High(Found) do
  begin
    Cell := Default(TCSHubCell);
    Cell.Kind := ckProject;
    Cell.Group := AGroup;
    Cell.Section := AGroup.Section;
    Cell.Project := Found[I];
    // A search hides neighbours, so a move would not show: no reordering meanwhile.
    Cell.CanUp := (FNeedle = '') and (I > 0);
    Cell.CanDown := (FNeedle = '') and (I < High(Found));
    Cell.Bounds := Bounds(Left1 + (I mod Columns) * (ColumnWidth + S(ColumnGap)),
      Y + (I div Columns) * (S(ItemHeight) + S(RowGap)), ColumnWidth, S(ItemHeight));
    FCells.Add(Cell);
  end;
  Rows := (Length(Found) + Columns - 1) div Columns;
  Inc(Y, Rows * S(ItemHeight) + (Rows - 1) * S(RowGap));
end;

procedure TCSHubListControl.Rebuild;
var G: TCSHubGroup;
    Section: TCSHubSection;
    Item: TObject;
    Groups: TArray<TCSHubGroup>;
    Cell: TCSHubCell;
    Left0, Right0, Y, Total, Space: Integer;
    AfterSection: Boolean;
begin
  // Window messages still arrive while the control is being torn down.
  if (FCells = nil) or (csDestroying in ComponentState) then Exit;
  // A drag in progress points at objects the change may have freed: drop it.
  ResetDrag;
  FCells.Clear;
  // A picture that was not there may have arrived (import, another IDE): look again.
  if FIconMissing <> nil then FIconMissing.Clear;
  FHotCell := -1;
  FHotPart := hpNone;
  FDownCell := -1;
  FContentHeight := 0;
  if FRepo = nil then Exit;
  FNeedle := UpperCase(Trim(FSearch));
  Left0 := S(SidePadding);
  Right0 := ClientWidth - S(SidePadding);
  Y := S(TopSpace);

  // Loose groups and sections share the top level, in the user's order. The space
  // above each block tells the levels apart: more around a category than between groups.
  AfterSection := False;
  for Item in FRepo.TopLevel do
  begin
    if FCells.Count = 0 then Space := 0
    else if AfterSection or (Item is TCSHubSection) then Space := SectionSpace
    else Space := GroupSpace;
    if Item is TCSHubGroup then
    begin
      if AddGroupCells(TCSHubGroup(Item), Left0, Right0, Space, Y) then AfterSection := False;
      Continue;
    end;
    Section := TCSHubSection(Item);
    Groups := FRepo.GroupsOf(Section);
    Total := 0;
    for G in Groups do Inc(Total, Length(MatchesOf(G)));
    if (FNeedle <> '') and (Total = 0) then Continue;

    Inc(Y, S(Space));
    Cell := Default(TCSHubCell);
    Cell.Kind := ckSection;
    Cell.Section := Section;
    Cell.Count := Total;
    Cell.GroupCount := Length(Groups);
    Cell.Collapsed := (FNeedle = '') and Section.Collapsed;
    Cell.CanUp := FRepo.CanReorderSection(Section, -1);
    Cell.CanDown := FRepo.CanReorderSection(Section, 1);
    Cell.Bounds := Rect(Left0, Y, Right0, Y + HeaderHeight(Section.Icon, SectionHeight, FSectionIconSize));
    FCells.Add(Cell);
    Inc(Y, Cell.Bounds.Height);
    AfterSection := True;

    if Cell.Collapsed then Continue;
    Inc(Y, S(SectionAfter));
    if Length(Groups) = 0 then
    begin
      Cell := Default(TCSHubCell);
      Cell.Kind := ckSectionEmpty;
      Cell.Section := Section;
      Cell.Bounds := Rect(Left0 + S(SectionIndent), Y, Right0, Y + S(EmptyHeight));
      FCells.Add(Cell);
      Inc(Y, S(EmptyHeight));
    end
    else
    begin
      Space := 0;
      for G in Groups do
        if AddGroupCells(G, Left0 + S(SectionIndent), Right0, Space, Y) then Space := GroupSpace;
    end;
  end;

  if FCells.Count > 0 then Inc(Y, S(BottomSpace));
  FContentHeight := Y;
  FScrollY := EnsureRange(FScrollY, 0, Max(0, FContentHeight - ClientHeight));
end;

procedure TCSHubListControl.SetScrollY(AValue: Integer);
begin
  AValue := EnsureRange(AValue, 0, Max(0, FContentHeight - ClientHeight));
  if AValue = FScrollY then Exit;
  FScrollY := AValue;
  Invalidate;
end;

function TCSHubListControl.HeaderButtonRect(const R: TRect; AIndex: Integer): TRect;
var Right, Middle, Half: Integer;
begin
  // From the right: 0 more, 1 down, 2 up, (rule), 3 add. The last one ends at the padding.
  Right := R.Right - AIndex * S(30);
  if AIndex >= 3 then Dec(Right, S(SeparatorGap));
  Middle := (R.Top + R.Bottom) div 2;
  Half := Min(S(13), R.Height div 2); // never taller than its row
  Result := Rect(Right - S(26), Middle - Half, Right, Middle + Half);
end;

function TCSHubListControl.MenuButtonRect(const R: TRect): TRect;
var Middle: Integer;
begin
  Middle := (R.Top + R.Bottom) div 2;
  Result := Rect(R.Right - S(36), Middle - S(14), R.Right - S(8), Middle + S(14));
end;

// Up over down, in one narrow column to the left of the "..." of a project.
function TCSHubListControl.ProjectArrowRect(const R: TRect; AUp: Boolean): TRect;
var Right, Middle: Integer;
begin
  Right := MenuButtonRect(R).Left - S(2);
  Middle := (R.Top + R.Bottom) div 2;
  if AUp then
    Result := Rect(Right - S(22), Middle - S(22), Right, Middle)
  else
    Result := Rect(Right - S(22), Middle, Right, Middle + S(22));
end;

function TCSHubListControl.ThumbRect: TRect;
var H, ThumbH, Range: Integer;
begin
  Result := TRect.Empty;
  H := ClientHeight;
  Range := FContentHeight - H;
  if (Range <= 0) or (H <= 0) then Exit;
  ThumbH := Max(S(24), MulDiv(H, H, FContentHeight));
  Result := Bounds(ClientWidth - S(8), MulDiv(H - ThumbH, FScrollY, Range), S(5), ThumbH);
end;

function TCSHubListControl.TextWidthOf(const AText: string; AStyle: TFontStyles): Integer;
begin
  FBuffer.Canvas.Font.Name := FontName;
  FBuffer.Canvas.Font.Height := -S(12);
  FBuffer.Canvas.Font.Style := AStyle;
  Result := FBuffer.Canvas.TextWidth(AText);
end;

// Index in FIconImages of a picture the user loaded, or -1 when the file is not
// there or is not a picture: the header is then drawn as if it had no icon.
function TCSHubListControl.LoadedIcon(const AName: string): Integer;
var FileName: string;
begin
  Result := FIconImages.GetIndexByName(AName);
  if (Result >= 0) or (FRepo = nil) or (FIconMissing.IndexOf(AName) >= 0) then Exit;
  try
    FileName := TPath.Combine(FRepo.IconsDir, AName);
    if TFile.Exists(FileName) then
    begin
      FIconImages.Add(AName, FileName);
      Result := FIconImages.GetIndexByName(AName);
    end;
  except
    Result := -1;
  end;
  // Not asked again on every paint.
  if Result < 0 then FIconMissing.Add(AName);
end;

procedure TCSHubListControl.ResolveIcon(const AIcon: string; out AGlyph: string; out AImage: Integer);
var Name: string;
begin
  AGlyph := '';
  AImage := -1;
  if AIcon = '' then Exit;
  if CSHubIconFile(AIcon, Name) then AImage := LoadedIcon(Name)
  else if FGlyphFont then AGlyph := CSHubIconGlyph(AIcon);
end;

// The usual height, or enough for the icon when there is one to draw.
function TCSHubListControl.HeaderHeight(const AIcon: string; ADefault, AIconSize: Integer): Integer;
var Glyph: string;
    Image: Integer;
begin
  Result := S(ADefault);
  ResolveIcon(AIcon, Glyph, Image);
  if (Glyph <> '') or (Image >= 0) then Result := Max(Result, S(AIconSize + 2 * IconPad));
end;

function TCSHubListControl.EmptyLinkRect(const ACell: TCSHubCell): TRect;
var X, Middle: Integer;
    Text, Link: string;
begin
  if ACell.Kind = ckSectionEmpty then
  begin
    Text := L(sSectionEmpty);
    Link := L(sSectionEmptyLink);
  end
  else
  begin
    Text := L(sGroupEmpty);
    Link := L(sGroupEmptyLink);
  end;
  X := ACell.Bounds.Left + S(8) + TextWidthOf(Text, [fsItalic]) + S(16);
  Middle := (ACell.Bounds.Top + ACell.Bounds.Bottom) div 2;
  Result := Rect(X - S(6), Middle - S(11), X + TextWidthOf(Link, []) + S(6), Middle + S(11));
end;

function TCSHubListControl.HitTest(X, Y: Integer; out APart: TCSHubPart): Integer;
var I: Integer;
    R: TRect;
    P: TPoint;
begin
  Result := -1;
  APart := hpNone;
  if (X >= ClientWidth - S(ScrollStrip)) and not ThumbRect.IsEmpty then
  begin
    R := ThumbRect;
    if (Y >= R.Top) and (Y < R.Bottom) then APart := hpThumb;
    Exit;
  end;
  P := Point(X, Y + FScrollY);
  for I := 0 to FCells.Count - 1 do
  begin
    R := FCells[I].Bounds;
    if not R.Contains(P) then Continue;
    Result := I;
    APart := hpBody;
    case FCells[I].Kind of
      ckSection, ckGroup:
        if HeaderButtonRect(R, 0).Contains(P) then APart := hpMore
        else if HeaderButtonRect(R, 1).Contains(P) then
        begin
          // An arrow that cannot move anything is dead space, not a collapse click.
          if FCells[I].CanDown then APart := hpDown else APart := hpNone;
        end
        else if HeaderButtonRect(R, 2).Contains(P) then
        begin
          if FCells[I].CanUp then APart := hpUp else APart := hpNone;
        end
        else if HeaderButtonRect(R, 3).Contains(P) then APart := hpAdd;
      ckProject:
        if MenuButtonRect(R).Contains(P) then APart := hpMenu
        else if ProjectArrowRect(R, True).Contains(P) then
        begin
          // Dead space when it cannot move: not a double click that opens the project.
          if FCells[I].CanUp then APart := hpUp else APart := hpNone;
        end
        else if ProjectArrowRect(R, False).Contains(P) then
        begin
          if FCells[I].CanDown then APart := hpDown else APart := hpNone;
        end;
      ckSectionEmpty, ckGroupEmpty:
        if EmptyLinkRect(FCells[I]).Contains(P) then APart := hpAdd else APart := hpNone;
    end;
    Exit;
  end;
end;

function TCSHubListControl.PartHint(ACell: Integer; APart: TCSHubPart): string;
var Cell: TCSHubCell;
    InSection: Boolean;
begin
  Result := '';
  if (ACell < 0) or (ACell >= FCells.Count) then Exit;
  Cell := FCells[ACell];
  InSection := Cell.Kind in [ckSection, ckSectionEmpty];
  case APart of
    hpAdd:
      if InSection then Result := L(sHintAddGroupToSection)
      else Result := L(sHintAddProjects);
    hpUp: Result := L(sMenuMoveUp);
    hpDown: Result := L(sMenuMoveDown);
    hpMore, hpMenu: Result := L(sHintMore);
    hpBody:
      case Cell.Kind of
        ckProject: Result := Cell.Project.FileName;
        ckSection:
          if Cell.Collapsed then Result := L(sHintExpandSection) else Result := L(sHintCollapseSection);
        ckGroup:
          if Cell.Collapsed then Result := L(sHintExpandGroup) else Result := L(sHintCollapseGroup);
      end;
  end;
end;

procedure TCSHubListControl.SetHot(ACell: Integer; APart: TCSHubPart);
begin
  if csDestroying in ComponentState then Exit;
  if (ACell = FHotCell) and (APart = FHotPart) then Exit;
  FHotCell := ACell;
  FHotPart := APart;
  Hint := PartHint(ACell, APart);
  Application.CancelHint;
  Invalidate;
end;

// A third of the way from the background color to the dimmed text color.
function TCSHubListControl.DisabledColor: TColor;
var Fore, Back: TColor;
begin
  Fore := ColorToRGB(FDimColor);
  Back := ColorToRGB(Color);
  Result := RGB((GetRValue(Fore) + 2 * GetRValue(Back)) div 3,
    (GetGValue(Fore) + 2 * GetGValue(Back)) div 3, (GetBValue(Fore) + 2 * GetBValue(Back)) div 3);
end;

procedure TCSHubListControl.BlendRect(ACanvas: TCanvas; const R: TRect; AColor: TColor; AAlpha: Byte);
var BF: TBlendFunction;
begin
  if R.IsEmpty then Exit;
  FDot.Canvas.Pixels[0, 0] := ColorToRGB(AColor);
  BF.BlendOp := AC_SRC_OVER;
  BF.BlendFlags := 0;
  BF.SourceConstantAlpha := AAlpha;
  BF.AlphaFormat := 0;
  Winapi.Windows.AlphaBlend(ACanvas.Handle, R.Left, R.Top, R.Width, R.Height,
    FDot.Canvas.Handle, 0, 0, 1, 1, BF);
end;

procedure TCSHubListControl.DrawGlyph(ACanvas: TCanvas; const R: TRect; APart: TCSHubPart; AHot: Boolean;
  AEnabled: Boolean; const AGlyph: string);
var Text: string;
    TextRect: TRect;
begin
  if AHot and AEnabled then BlendRect(ACanvas, R, FTextColor, 36);
  if FGlyphFont then
  begin
    case APart of
      hpAdd: Text := CSHubGlyphAdd;
      hpUp: Text := CSHubGlyphUp;
      hpDown: Text := CSHubGlyphDown;
    else
      Text := CSHubGlyphMore;
    end;
    if AGlyph <> '' then Text := AGlyph; // same button, another picture
    ACanvas.Font.Name := CSHubGlyphFont;
    ACanvas.Font.Height := -S(14);
  end
  else
  begin
    case APart of
      hpAdd: Text := '+';
      hpUp: Text := #$2191;
      hpDown: Text := #$2193;
    else
      Text := '...';
    end;
    ACanvas.Font.Name := FontName;
    ACanvas.Font.Height := -S(15);
  end;
  ACanvas.Font.Style := [];
  if not AEnabled then
    ACanvas.Font.Color := DisabledColor   // barely there: it cannot be clicked
  else if AHot then
    ACanvas.Font.Color := FTextColor
  else
    ACanvas.Font.Color := FDimColor;
  ACanvas.Brush.Style := bsClear;
  TextRect := R;
  DrawText(ACanvas.Handle, PChar(Text), Length(Text), TextRect,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

// Section and group headers share the layout; a section is larger.
procedure TCSHubListControl.DrawHeader(ACanvas: TCanvas; const R: TRect; AIndex: Integer);
var Cell: TCSHubCell;
    TextRect, FirstButton, IconRect: TRect;
    X, Middle, RuleX, RuleEnd, NameLeft, IconSize, IconImage, IconWidth, SrcW, SrcH: Integer;
    Name, Chevron, Icon, IconGlyph: string;
    IsSection, RowHot: Boolean;

  function Hot(APart: TCSHubPart): Boolean;
  begin
    Result := (FHotCell = AIndex) and (FHotPart = APart);
  end;

begin
  Cell := FCells[AIndex];
  IsSection := Cell.Kind = ckSection;
  Middle := (R.Top + R.Bottom) div 2;
  RowHot := FHotCell = AIndex;
  if IsSection then Name := Cell.Section.Name else Name := Cell.Group.Name;
  FirstButton := HeaderButtonRect(R, HeaderButtons - 1);
  // The rule runs up to "..." and gives way to the other buttons only while they show.
  if RowHot then RuleEnd := FirstButton.Left - S(RuleGap)
  else RuleEnd := HeaderButtonRect(R, 0).Left - S(RuleGap);

  // Collapse chevron: down when open, right when collapsed.
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Style := [];
  if Hot(hpBody) then ACanvas.Font.Color := FTextColor else ACanvas.Font.Color := FDimColor;
  if FGlyphFont then
  begin
    ACanvas.Font.Name := CSHubGlyphFont;
    ACanvas.Font.Height := -S(10);
    if Cell.Collapsed then Chevron := CSHubGlyphChevronRight else Chevron := CSHubGlyphChevronDown;
  end
  else
  begin
    ACanvas.Font.Name := FontName;
    ACanvas.Font.Height := -S(12);
    if Cell.Collapsed then Chevron := #$25B8 else Chevron := #$25BE;
  end;
  TextRect := Rect(R.Left + S(4), R.Top, R.Left + S(HeaderIndent - 4), R.Bottom);
  DrawText(ACanvas.Handle, PChar(Chevron), Length(Chevron), TextRect,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);

  // Optional icon between the chevron and the name. Without one (none chosen, id
  // this version does not know, picture not found) the name stays where it always was.
  NameLeft := R.Left + S(HeaderIndent);
  if IsSection then
  begin
    Icon := Cell.Section.Icon;
    IconSize := S(FSectionIconSize);
  end
  else
  begin
    Icon := Cell.Group.Icon;
    IconSize := S(FGroupIconSize);
  end;
  ResolveIcon(Icon, IconGlyph, IconImage);
  if (IconGlyph <> '') or (IconImage >= 0) then
  begin
    // The box is square, but what goes in it often is not: the icon sits at the left
    // of the box and the name follows the icon's real width, not the box (the user
    // found the name too far from a narrow icon).
    IconRect := Bounds(R.Left + S(ChevronEnd + IconBefore), Middle - IconSize div 2, IconSize, IconSize);
    IconWidth := IconSize;
    if IconImage >= 0 then
    begin
      SrcW := FIconImages.Images[IconImage].SourceImages[0].Image.Width;
      SrcH := FIconImages.Images[IconImage].SourceImages[0].Image.Height;
      if (SrcW > 0) and (SrcH > 0) then
      begin
        // Fit the box keeping the proportions, pinned to its left.
        if SrcW >= SrcH then
          IconRect := Bounds(IconRect.Left, Middle - MulDiv(IconSize, SrcH, SrcW) div 2, IconSize,
            MulDiv(IconSize, SrcH, SrcW))
        else
          IconRect := Bounds(IconRect.Left, IconRect.Top, MulDiv(IconSize, SrcW, SrcH), IconSize);
        IconWidth := IconRect.Width;
      end;
      FIconImages.Draw(ACanvas, IconRect, IconImage, True);
    end
    else
    begin
      ACanvas.Font.Name := CSHubGlyphFont;
      ACanvas.Font.Style := [];
      ACanvas.Font.Height := -(IconSize - S(2));
      ACanvas.Font.Color := FTextColor;
      IconWidth := Min(IconSize, ACanvas.TextWidth(IconGlyph));
      DrawText(ACanvas.Handle, PChar(IconGlyph), Length(IconGlyph), IconRect,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_NOCLIP);
    end;
    NameLeft := IconRect.Left + IconWidth + S(IconGap);
  end;

  // Both levels in semibold; the category is the larger one.
  if FSemibold then
  begin
    ACanvas.Font.Name := SemiboldName;
    ACanvas.Font.Style := [];
  end
  else
  begin
    ACanvas.Font.Name := FontName;
    ACanvas.Font.Style := [fsBold];
  end;
  if IsSection then ACanvas.Font.Height := -S(15) else ACanvas.Font.Height := -S(13);
  ACanvas.Font.Color := FTextColor;
  // The name always stops short of where the buttons appear, so it never shifts.
  TextRect := Rect(NameLeft, R.Top, FirstButton.Left - S(32), R.Bottom);
  DrawText(ACanvas.Handle, PChar(Name), Length(Name), TextRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
  X := TextRect.Left + Min(ACanvas.TextWidth(Name), TextRect.Width) + S(RuleGap);

  // Rule between the title and the buttons; stronger for a section.
  if IsSection then
    BlendRect(ACanvas, Rect(X, Middle, RuleEnd, Middle + 1), FTextColor, 96)
  else
    BlendRect(ACanvas, Rect(X, Middle, RuleEnd, Middle + 1), FTextColor, 48);

  // At rest a header shows only "..."; the other buttons come with the mouse.
  if RowHot then
  begin
    // A category creates a group ("+"); a group picks existing project files, so it
    // shows the open-folder picture the IDE itself uses for "open project".
    if IsSection then
      DrawGlyph(ACanvas, FirstButton, hpAdd, Hot(hpAdd))
    else
      DrawGlyph(ACanvas, FirstButton, hpAdd, Hot(hpAdd), True, CSHubGlyphOpenFolder);
    // Vertical rule between "add" and "order" (up, down).
    RuleX := (HeaderButtonRect(R, 3).Right + HeaderButtonRect(R, 2).Left) div 2;
    BlendRect(ACanvas, Rect(RuleX, Middle - S(8), RuleX + 1, Middle + S(8)), FTextColor, 70);
    DrawGlyph(ACanvas, HeaderButtonRect(R, 2), hpUp, Hot(hpUp), Cell.CanUp);
    DrawGlyph(ACanvas, HeaderButtonRect(R, 1), hpDown, Hot(hpDown), Cell.CanDown);
  end;
  DrawGlyph(ACanvas, HeaderButtonRect(R, 0), hpMore, Hot(hpMore));
end;

procedure TCSHubListControl.DrawProject(ACanvas: TCanvas; const R: TRect; AIndex: Integer);
var Cell: TCSHubCell;
    TextRect, MenuRect: TRect;
    Title, Dir, Line1, Line2, Segment: string;
    ImageIndex, MaxWidth, I, Start: Integer;
    Missing: Boolean;
begin
  Cell := FCells[AIndex];
  MenuRect := MenuButtonRect(R);
  if FHotCell = AIndex then
    BlendRect(ACanvas, R, FTextColor, 20);

  if FImages <> nil then
  begin
    ImageIndex := FImages.GetIndexByName(LowerCase(Copy(TPath.GetExtension(Cell.Project.FileName), 2, MaxInt)));
    if ImageIndex < 0 then ImageIndex := FImages.GetIndexByName('dproj');
    if ImageIndex >= 0 then
      FImages.Draw(ACanvas, Bounds(R.Left + S(8), R.Top + S(6), S(40), S(40)), ImageIndex, True);
  end;

  Missing := not TFile.Exists(Cell.Project.FileName);
  Title := TPath.GetFileName(Cell.Project.FileName);
  Dir := TPath.GetDirectoryName(Cell.Project.FileName);
  if Missing then Dir := L(sMissingFile) + ' ' + Dir;
  // The arrows only show under the mouse, but their room is always kept so the
  // text does not shift when they appear.
  MaxWidth := ProjectArrowRect(R, True).Left - S(4) - (R.Left + S(60));

  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Name := FontName;
  ACanvas.Font.Style := [];
  ACanvas.Font.Height := -S(12);
  if Missing then ACanvas.Font.Color := FDimColor else ACanvas.Font.Color := FTextColor;
  TextRect := Bounds(R.Left + S(60), R.Top + S(2), MaxWidth, S(17));
  DrawText(ACanvas.Handle, PChar(Title), Length(Title), TextRect,
    DT_LEFT or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);

  // Wrap the folder at backslashes over two lines, like Open Recent does.
  ACanvas.Font.Color := FDimColor;
  ACanvas.Font.Height := -S(11); // the path is one size below the name
  Line1 := '';
  Line2 := '';
  Start := 1;
  for I := 1 to Length(Dir) do
    if (Dir[I] = '\') or (I = Length(Dir)) then
    begin
      Segment := Copy(Dir, Start, I - Start + 1);
      if (Line2 = '') and ((Line1 = '') or (ACanvas.TextWidth(Line1 + Segment) <= MaxWidth)) then
        Line1 := Line1 + Segment
      else
        Line2 := Line2 + Segment;
      Start := I + 1;
    end;
  TextRect := Bounds(R.Left + S(60), R.Top + S(20), MaxWidth, S(15));
  DrawText(ACanvas.Handle, PChar(Line1), Length(Line1), TextRect,
    DT_LEFT or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
  if Line2 <> '' then
  begin
    TextRect := Bounds(R.Left + S(60), R.Top + S(35), MaxWidth, S(15));
    DrawText(ACanvas.Handle, PChar(Line2), Length(Line2), TextRect,
      DT_LEFT or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
  end;

  if FHotCell = AIndex then
  begin
    DrawGlyph(ACanvas, ProjectArrowRect(R, True), hpUp, FHotPart = hpUp, Cell.CanUp);
    DrawGlyph(ACanvas, ProjectArrowRect(R, False), hpDown, FHotPart = hpDown, Cell.CanDown);
  end;
  DrawGlyph(ACanvas, MenuRect, hpMenu, (FHotCell = AIndex) and (FHotPart = hpMenu));
end;

procedure TCSHubListControl.DrawEmpty(ACanvas: TCanvas; const R: TRect; AIndex: Integer);
var Cell: TCSHubCell;
    TextRect, LinkRect: TRect;
    Hot: Boolean;
    Text: string;
begin
  Cell := FCells[AIndex];
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Name := FontName;
  ACanvas.Font.Height := -S(12);
  ACanvas.Font.Style := [fsItalic];
  ACanvas.Font.Color := FDimColor;
  if Cell.Kind = ckSectionEmpty then Text := L(sSectionEmpty) else Text := L(sGroupEmpty);
  TextRect := Rect(R.Left + S(8), R.Top, R.Right, R.Bottom);
  DrawText(ACanvas.Handle, PChar(Text), Length(Text), TextRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);

  LinkRect := EmptyLinkRect(Cell);
  LinkRect.Offset(0, R.Top - Cell.Bounds.Top);
  Hot := (FHotCell = AIndex) and (FHotPart = hpAdd);
  if Hot then BlendRect(ACanvas, LinkRect, FTextColor, 36);
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Name := FontName;
  ACanvas.Font.Height := -S(12);
  ACanvas.Font.Style := [];
  if Hot then ACanvas.Font.Color := FTextColor else ACanvas.Font.Color := FDimColor;
  if Cell.Kind = ckSectionEmpty then Text := L(sSectionEmptyLink) else Text := L(sGroupEmptyLink);
  DrawText(ACanvas.Handle, PChar(Text), Length(Text), LinkRect,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

procedure TCSHubListControl.Paint;
var C: TCanvas;
    I: Integer;
    R, Thumb: TRect;
    Text: string;
begin
  if (FCells = nil) or (csDestroying in ComponentState) then Exit;
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;
  FBuffer.SetSize(ClientWidth, ClientHeight);
  C := FBuffer.Canvas;
  C.Brush.Style := bsSolid;
  C.Brush.Color := Color;
  C.FillRect(ClientRect);
  if Assigned(FOnPaintBackground) then FOnPaintBackground(Self, C);
  if FCells.Count = 0 then
  begin
    if Trim(FSearch) <> '' then
      Text := L(sNotFound)
    else
      Text := L(sNoGroups);
    C.Brush.Style := bsClear;
    C.Font.Name := FontName;
    C.Font.Style := [];
    C.Font.Height := -S(12);
    C.Font.Color := FDimColor;
    R := Rect(S(SidePadding), S(TopSpace), ClientWidth - S(SidePadding), ClientHeight);
    DrawText(C.Handle, PChar(Text), Length(Text), R, DT_LEFT or DT_WORDBREAK or DT_NOPREFIX);
  end;

  for I := 0 to FCells.Count - 1 do
  begin
    R := FCells[I].Bounds;
    R.Offset(0, -FScrollY);
    if (R.Bottom <= 0) or (R.Top >= ClientHeight) then Continue;
    case FCells[I].Kind of
      ckSection, ckGroup: DrawHeader(C, R, I);
      ckProject: DrawProject(C, R, I);
      ckSectionEmpty, ckGroupEmpty: DrawEmpty(C, R, I);
    end;
  end;

  if FDragKind <> dkNone then DrawDrag(C);

  Thumb := ThumbRect;
  if not Thumb.IsEmpty then
    if FDragging or (FHotPart = hpThumb) then
      BlendRect(C, Thumb, FTextColor, 150)
    else
      BlendRect(C, Thumb, FTextColor, 80);

  Canvas.Draw(0, 0, FBuffer);
end;

procedure TCSHubListControl.Resize;
begin
  inherited;
  Rebuild;
  Invalidate;
end;

procedure TCSHubListControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TCSHubListControl.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure TCSHubListControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if not FDragging and (FDragKind = dkNone) then SetHot(-1, hpNone);
end;

{ Drag and drop }

// The cell under P (content coordinates) or, between cells, the closest one:
// vertical distance first, so a gap belongs to the line next to it.
function TCSHubListControl.CellNear(const P: TPoint): Integer;
var I, DX, DY: Integer;
    Score, Best: Int64;
    R: TRect;
begin
  Result := -1;
  Best := High(Int64);
  for I := 0 to FCells.Count - 1 do
  begin
    R := FCells[I].Bounds;
    DX := Max(0, Max(R.Left - P.X, P.X - (R.Right - 1)));
    DY := Max(0, Max(R.Top - P.Y, P.Y - (R.Bottom - 1)));
    Score := Int64(DY) * 100000 + DX;
    if Score < Best then
    begin
      Best := Score;
      Result := I;
    end;
  end;
end;

// Header plus projects (or empty line) of a group.
function TCSHubListControl.GroupBlock(AGroup: TCSHubGroup): TRect;
var Cell: TCSHubCell;
begin
  Result := TRect.Empty;
  for Cell in FCells do
    if (Cell.Group = AGroup) and (Cell.Kind in [ckGroup, ckGroupEmpty, ckProject]) then
      if Result.IsEmpty then Result := Cell.Bounds else Result.Union(Cell.Bounds);
end;

// Everything a top-level item shows: a loose group, or a section with its groups.
function TCSHubListControl.TopBlock(AItem: TObject): TRect;
var Cell: TCSHubCell;
begin
  Result := TRect.Empty;
  for Cell in FCells do
    if (Cell.Section = AItem) or (Cell.Group = AItem) then
      if Result.IsEmpty then Result := Cell.Bounds else Result.Union(Cell.Bounds);
end;

procedure TCSHubListControl.StartItemDrag;
begin
  FPressed := False;
  FDownCell := -1; // the release that ends a drag is not a click
  case FPressCell.Kind of
    ckProject:
      begin
        FDragKind := dkProject;
        FDragProject := FPressCell.Project;
      end;
    ckGroup:
      begin
        FDragKind := dkGroup;
        FDragGroup := FPressCell.Group;
      end;
    ckSection:
      begin
        FDragKind := dkSection;
        FDragSection := FPressCell.Section;
      end;
  else
    Exit;
  end;
  FSavedCursor := Screen.Cursor;
  Application.CancelHint;
  Hint := '';
  // No hover buttons on the line being carried.
  FHotCell := -1;
  FHotPart := hpNone;
  if FScrollTimer = nil then
  begin
    FScrollTimer := TTimer.Create(Self);
    FScrollTimer.Interval := 30;
    FScrollTimer.OnTimer := ScrollTick;
  end;
  FScrollTimer.Enabled := True;
end;

// Works out, from the last mouse position, where a drop would land and what to
// draw for it: an insertion bar, or the header that will receive the item.
procedure TCSHubListControl.UpdateDrop;
var P: TPoint;
    I, J, Y, Left: Integer;
    Cell, Other: TCSHubCell;
    Block: TRect;
    Target: TObject;
    Top: TArray<TObject>;
    Groups: TArray<TCSHubGroup>;

  // What comes right after AItem among its neighbours; nil when it is the last.
  function NextTop(AItem: TObject): TObject;
  var K: Integer;
  begin
    Result := nil;
    Top := FRepo.TopLevel;
    for K := 0 to High(Top) - 1 do
      if Top[K] = AItem then Result := Top[K + 1];
  end;

  function NextGroup(AGroup: TCSHubGroup): TObject;
  var K: Integer;
  begin
    if AGroup.Section = nil then Exit(NextTop(AGroup));
    Result := nil;
    Groups := FRepo.GroupsOf(AGroup.Section);
    for K := 0 to High(Groups) - 1 do
      if Groups[K] = AGroup then Result := Groups[K + 1];
  end;

  procedure MarkRow(AY, ALeft: Integer);
  begin
    FDropMark := Rect(ALeft, AY - 1, ClientWidth - S(SidePadding), AY + 1);
  end;

begin
  FDropValid := False;
  FDropPositioned := False;
  FDropGroup := nil;
  FDropSection := nil;
  FDropBefore := nil;
  FDropMark := TRect.Empty;
  FDropHighlight := TRect.Empty;
  if FDragKind = dkNone then Exit;
  P := Point(FDragPos.X, FDragPos.Y + FScrollY);
  I := CellNear(P);
  if I >= 0 then
  begin
    Cell := FCells[I];
    Left := S(SidePadding);
    case FDragKind of
      dkProject:
        if Cell.Group <> nil then
          if (Cell.Kind = ckProject) and ((Cell.Group = FDragProject.Group) or Cell.Group.ManualOrder) then
          begin
            // A place among the projects: the half of the item the mouse is on decides the side.
            FDropGroup := Cell.Group;
            FDropPositioned := True;
            if P.X < (Cell.Bounds.Left + Cell.Bounds.Right) div 2 then
            begin
              FDropBefore := Cell.Project;
              Y := Cell.Bounds.Left - S(ColumnGap) div 2;
            end
            else
            begin
              if (I + 1 < FCells.Count) and (FCells[I + 1].Kind = ckProject) and
                (FCells[I + 1].Group = Cell.Group) then
                FDropBefore := FCells[I + 1].Project;
              Y := Cell.Bounds.Right + S(ColumnGap) div 2;
            end;
            FDropMark := Rect(Y - 1, Cell.Bounds.Top, Y + 1, Cell.Bounds.Bottom);
            FDropValid := True;
          end
          else if Cell.Group <> FDragProject.Group then
          begin
            // Another group that keeps its projects by name: it just receives the project.
            FDropGroup := Cell.Group;
            for J := 0 to FCells.Count - 1 do
            begin
              Other := FCells[J];
              if (Other.Kind = ckGroup) and (Other.Group = Cell.Group) then FDropHighlight := Other.Bounds;
            end;
            FDropValid := True;
          end;
      dkGroup:
        if Cell.Kind in [ckSection, ckSectionEmpty] then
        begin
          if (Cell.Kind = ckSection) and (P.Y < (Cell.Bounds.Top + Cell.Bounds.Bottom) div 2) then
          begin
            // Upper half of a category header: top level, right above the category.
            FDropBefore := Cell.Section;
            MarkRow(Cell.Bounds.Top - S(8), Left);
          end
          else
          begin
            // Into the category, as its first group.
            FDropSection := Cell.Section;
            Groups := FRepo.GroupsOf(Cell.Section);
            if Length(Groups) > 0 then FDropBefore := Groups[0];
            if (FDropBefore <> nil) and not GroupBlock(Groups[0]).IsEmpty then
              MarkRow(GroupBlock(Groups[0]).Top - S(8), Left + S(SectionIndent))
            else
              for J := 0 to FCells.Count - 1 do
              begin
                Other := FCells[J];
                if (Other.Kind = ckSection) and (Other.Section = Cell.Section) then FDropHighlight := Other.Bounds;
              end;
          end;
          FDropValid := FDropBefore <> FDragGroup;
        end
        else if Cell.Group <> FDragGroup then
        begin
          // Above or below another group, in whatever holds that group.
          FDropSection := Cell.Group.Section;
          if FDropSection <> nil then Inc(Left, S(SectionIndent));
          Block := GroupBlock(Cell.Group);
          if P.Y < (Block.Top + Block.Bottom) div 2 then
          begin
            FDropBefore := Cell.Group;
            MarkRow(Block.Top - S(8), Left);
          end
          else
          begin
            FDropBefore := NextGroup(Cell.Group);
            MarkRow(Block.Bottom + S(8), Left);
          end;
          FDropValid := FDropBefore <> FDragGroup;
        end;
      dkSection:
        begin
          if Cell.Section <> nil then Target := Cell.Section else Target := Cell.Group;
          if (Target <> nil) and (Target <> FDragSection) then
          begin
            Block := TopBlock(Target);
            if P.Y < (Block.Top + Block.Bottom) div 2 then
            begin
              FDropBefore := Target;
              MarkRow(Block.Top - S(10), Left);
            end
            else
            begin
              FDropBefore := NextTop(Target);
              MarkRow(Block.Bottom + S(10), Left);
            end;
            FDropValid := FDropBefore <> FDragSection;
          end;
        end;
    end;
  end;
  if not FDropValid then
  begin
    FDropMark := TRect.Empty;
    FDropHighlight := TRect.Empty;
    Screen.Cursor := crNoDrop;
  end
  else
    Screen.Cursor := crDrag;
  Invalidate;
end;

procedure TCSHubListControl.ResetDrag;
begin
  FPressed := False;
  if FDragKind = dkNone then Exit;
  FDragKind := dkNone;
  FDragProject := nil;
  FDragGroup := nil;
  FDragSection := nil;
  FDropValid := False;
  FDropMark := TRect.Empty;
  FDropHighlight := TRect.Empty;
  if FScrollTimer <> nil then FScrollTimer.Enabled := False;
  Screen.Cursor := FSavedCursor;
  Invalidate;
end;

procedure TCSHubListControl.EndItemDrag(ADrop: Boolean);
var Kind: TCSHubDragKind;
    Project: TCSHubProject;
    Group, DropGroup: TCSHubGroup;
    Section, DropSection: TCSHubSection;
    Before: TObject;
    Positioned: Boolean;
begin
  Kind := FDragKind;
  Project := FDragProject;
  Group := FDragGroup;
  Section := FDragSection;
  DropGroup := FDropGroup;
  DropSection := FDropSection;
  Before := FDropBefore;
  Positioned := FDropPositioned;
  ADrop := ADrop and FDropValid;
  // Back to rest first: the handlers change the repository and reload the list.
  ResetDrag;
  if not ADrop then Exit;
  case Kind of
    dkProject:
      if Assigned(FOnProjectDrop) then
        FOnProjectDrop(Self, Project, DropGroup, TCSHubProject(Before), Positioned);
    dkGroup: if Assigned(FOnGroupDrop) then FOnGroupDrop(Self, Group, DropSection, Before);
    dkSection: if Assigned(FOnSectionDrop) then FOnSectionDrop(Self, Section, Before);
  end;
end;

// While something is dragged near the top or bottom edge, the list scrolls by itself.
procedure TCSHubListControl.ScrollTick(Sender: TObject);
var Old: Integer;
begin
  if FDragKind = dkNone then
  begin
    FScrollTimer.Enabled := False;
    Exit;
  end;
  Old := FScrollY;
  if FDragPos.Y < S(DragScrollZone) then
    SetScrollY(FScrollY - S(DragScrollStep))
  else if FDragPos.Y > ClientHeight - S(DragScrollZone) then
    SetScrollY(FScrollY + S(DragScrollStep));
  if FScrollY <> Old then UpdateDrop;
end;

procedure TCSHubListControl.DrawDrag(ACanvas: TCanvas);
var I: Integer;
    R: TRect;
    Cell: TCSHubCell;
    Mine: Boolean;
begin
  // What is being dragged fades where it sits.
  for I := 0 to FCells.Count - 1 do
  begin
    Cell := FCells[I];
    case FDragKind of
      dkProject: Mine := (Cell.Kind = ckProject) and (Cell.Project = FDragProject);
      dkGroup: Mine := (Cell.Group = FDragGroup) and (Cell.Kind in [ckGroup, ckGroupEmpty, ckProject]);
    else
      Mine := (Cell.Section = FDragSection) and (FDragSection <> nil);
    end;
    if not Mine then Continue;
    R := Cell.Bounds;
    R.Offset(0, -FScrollY);
    BlendRect(ACanvas, R, Color, 160);
  end;
  if not FDropValid then Exit;
  if not FDropHighlight.IsEmpty then
  begin
    R := FDropHighlight;
    R.Offset(0, -FScrollY);
    BlendRect(ACanvas, R, FTextColor, 44);
  end;
  if not FDropMark.IsEmpty then
  begin
    R := FDropMark;
    R.Offset(0, -FScrollY);
    BlendRect(ACanvas, R, FTextColor, 230);
  end;
end;

// The VCL releases the mouse capture before it calls MouseUp, and that release
// must not be taken for a cancelled drag.
procedure TCSHubListControl.WMLButtonUp(var Message: TWMLButtonUp);
begin
  FDropping := True;
  try
    inherited;
  finally
    FDropping := False;
  end;
end;

procedure TCSHubListControl.WMCancelMode(var Message: TMessage);
begin
  inherited;
  ResetDrag;
end;

procedure TCSHubListControl.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  if not FDropping then ResetDrag;
end;

procedure TCSHubListControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_ESCAPE) and (FDragKind <> dkNone) then
  begin
    ResetDrag;
    Key := 0;
  end;
end;

procedure TCSHubListControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  // A double click may have left the list off the Welcome Page.
  if (csDestroying in ComponentState) or (Parent = nil) or not HandleAllocated then Exit;
  if CanFocus then SetFocus;
  FDownCell := HitTest(X, Y, FDownPart);
  FPressed := False;
  if (Button = mbLeft) and (FDownPart = hpThumb) then
  begin
    FDragging := True;
    FDragOffset := Y - ThumbRect.Top;
  end
  // A press on the body of a project or of a header may become a drag. Not during
  // a search: it hides the places things could go to.
  else if (Button = mbLeft) and (FDownPart = hpBody) and (FDownCell >= 0) and (FNeedle = '') and
    (FCells[FDownCell].Kind in [ckProject, ckGroup, ckSection]) then
  begin
    FPressed := True;
    FPressPos := Point(X, Y);
    FPressCell := FCells[FDownCell];
  end;
end;

procedure TCSHubListControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var Cell, Track: Integer;
    Part: TCSHubPart;
begin
  inherited;
  if FDragging then
  begin
    Track := ClientHeight - ThumbRect.Height;
    if Track > 0 then
      SetScrollY(MulDiv(Y - FDragOffset, FContentHeight - ClientHeight, Track));
    Exit;
  end;
  // Up to the threshold it is still a click (or the first half of a double click).
  if FPressed and (ssLeft in Shift) and
    ((Abs(X - FPressPos.X) > Mouse.DragThreshold) or (Abs(Y - FPressPos.Y) > Mouse.DragThreshold)) then
    StartItemDrag;
  if FDragKind <> dkNone then
  begin
    FDragPos := Point(X, Y);
    UpdateDrop;
    Exit;
  end;
  Cell := HitTest(X, Y, Part);
  SetHot(Cell, Part);
end;

procedure TCSHubListControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var Cell: Integer;
    Part: TCSHubPart;
    Data: TCSHubCell;
    InSection: Boolean;
    Delta: Integer;
begin
  inherited;
  FPressed := False;
  if FDragging then
  begin
    FDragging := False;
    Invalidate;
    Exit;
  end;
  if FDragKind <> dkNone then
  begin
    FDragPos := Point(X, Y);
    UpdateDrop;
    EndItemDrag(Button = mbLeft);
    Exit;
  end;
  Cell := HitTest(X, Y, Part);
  if (Cell < 0) or (Cell <> FDownCell) or (Part <> FDownPart) then Exit;
  // The handlers change the repository and rebuild FCells: work on a copy.
  Data := FCells[Cell];
  InSection := Data.Kind in [ckSection, ckSectionEmpty];
  if Button = mbRight then
  begin
    case Data.Kind of
      ckProject: if Assigned(FOnProjectMenu) then FOnProjectMenu(Self, Data.Project);
      ckGroup: if Assigned(FOnGroupMenu) then FOnGroupMenu(Self, Data.Group);
      ckSection: if Assigned(FOnSectionMenu) then FOnSectionMenu(Self, Data.Section);
    end;
    Exit;
  end;
  if Button <> mbLeft then Exit;
  case Part of
    hpBody:
      case Data.Kind of
        ckSection: if Assigned(FOnSectionToggle) then FOnSectionToggle(Self, Data.Section);
        ckGroup: if Assigned(FOnGroupToggle) then FOnGroupToggle(Self, Data.Group);
      end;
    hpAdd:
      if InSection then
      begin
        if Assigned(FOnSectionAdd) then FOnSectionAdd(Self, Data.Section);
      end
      else if Assigned(FOnGroupAdd) then FOnGroupAdd(Self, Data.Group);
    hpUp, hpDown:
      begin
        if Part = hpUp then Delta := -1 else Delta := 1;
        if Data.Kind = ckProject then
        begin
          if Assigned(FOnProjectMove) then FOnProjectMove(Self, Data.Project, Delta);
        end
        else if InSection then
        begin
          if Assigned(FOnSectionMove) then FOnSectionMove(Self, Data.Section, Delta);
        end
        else if Assigned(FOnGroupMove) then FOnGroupMove(Self, Data.Group, Delta);
      end;
    hpMore:
      if InSection then
      begin
        if Assigned(FOnSectionMenu) then FOnSectionMenu(Self, Data.Section);
      end
      else if Assigned(FOnGroupMenu) then FOnGroupMenu(Self, Data.Group);
    hpMenu: if Assigned(FOnProjectMenu) then FOnProjectMenu(Self, Data.Project);
  end;
end;

procedure TCSHubListControl.DblClick;
var Data: TCSHubCell;
begin
  inherited;
  if (FHotCell < 0) or (FHotCell >= FCells.Count) or (FHotPart <> hpBody) then Exit;
  Data := FCells[FHotCell];
  if (Data.Kind = ckProject) and Assigned(FOnOpenProject) then FOnOpenProject(Self, Data.Project);
end;

function TCSHubListControl.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  SetScrollY(FScrollY - MulDiv(WheelDelta, S(ItemHeight), WHEEL_DELTA));
  Result := True;
end;

end.
