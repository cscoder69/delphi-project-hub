unit CSCoder.Hub.ClientFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.ExtCtrls, CSCoder.Hub.Model, CSCoder.Hub.Repository, CSCoder.Hub.ListControl,
  CSCoder.Hub.CaptionFrame;

const
  CM_CSHUB_THEME = WM_APP + $5C1;

type
  /// The whole Welcome Page panel: caption on top, list below, wired to the model.
  /// It is the plugin view itself so it fills the layout cell like built-in panels
  /// (the ready-made host from CreateCaptionFrame sizes to its content instead).
  TCSHubClientFrame = class(TFrame)
  private
    FModel: TCSHubModel;
    FList: TCSHubListControl;
    FCaption: TCSHubCaptionFrame;
    FWindowColor: TColor;
    FOnDestroyed: TNotifyEvent;
    FThemeNotifier: IInterface;   // keeps the notifier object alive
    FThemeNotifierIndex: Integer;
    FPlaceTimer: TTimer;
    FPlace: TRect;
    function PlaceOnPage(out ATop: TWinControl): TRect;
    procedure CheckPlace;
    procedure PlaceTick(Sender: TObject);
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure ApplyColors;
    procedure WatchTheme;
    procedure UnwatchTheme;
    procedure CMThemeChanged(var Message: TMessage); message CM_CSHUB_THEME;
    procedure ModelChanged(Sender: TObject);
    procedure ListPaintBackground(Sender: TObject; ACanvas: TCanvas);
    procedure ListOpenProject(Sender: TObject; AProject: TCSHubProject);
    procedure ListProjectMenu(Sender: TObject; AProject: TCSHubProject);
    procedure ListProjectMove(Sender: TObject; AProject: TCSHubProject; ADelta: Integer);
    procedure ListGroupAdd(Sender: TObject; AGroup: TCSHubGroup);
    procedure ListGroupMove(Sender: TObject; AGroup: TCSHubGroup; ADelta: Integer);
    procedure ListGroupToggle(Sender: TObject; AGroup: TCSHubGroup);
    procedure ListGroupMenu(Sender: TObject; AGroup: TCSHubGroup);
    procedure ListSectionAdd(Sender: TObject; ASection: TCSHubSection);
    procedure ListSectionMove(Sender: TObject; ASection: TCSHubSection; ADelta: Integer);
    procedure ListSectionToggle(Sender: TObject; ASection: TCSHubSection);
    procedure ListSectionMenu(Sender: TObject; ASection: TCSHubSection);
    procedure ListProjectDrop(Sender: TObject; AProject: TCSHubProject; AGroup: TCSHubGroup;
      ABefore: TCSHubProject; APositioned: Boolean);
    procedure ListGroupDrop(Sender: TObject; AGroup: TCSHubGroup; ASection: TCSHubSection; ABefore: TObject);
    procedure ListSectionDrop(Sender: TObject; ASection: TCSHubSection; ABefore: TObject);
  public
    constructor Create(AOwner: TComponent; AModel: TCSHubModel); reintroduce;
    destructor Destroy; override;
    /// The IDE switched between light and dark: read its colors again and redraw.
    procedure ThemeChanged;
    /// Fired from the destructor. The Welcome Page may free this frame itself
    /// (it is the parent window), so whoever holds a reference must drop it here.
    property OnDestroyed: TNotifyEvent read FOnDestroyed write FOnDestroyed;
  end;

implementation

uses
  ToolsAPI, ToolsAPI.WelcomePage;

{$R *.dfm}

type
  /// What the IDE calls when the user switches theme. It only holds a pointer
  /// back to the frame, cleared when the frame goes away first.
  TCSHubThemeNotifier = class(TNotifierObject, IOTANotifier, INTAIDEThemingServicesNotifier)
  private
    FFrame: TCSHubClientFrame;
  public
    constructor Create(AFrame: TCSHubClientFrame);
    procedure Detach;
    { INTAIDEThemingServicesNotifier }
    procedure ChangingTheme;
    procedure ChangedTheme;
  end;

constructor TCSHubThemeNotifier.Create(AFrame: TCSHubClientFrame);
begin
  inherited Create;
  FFrame := AFrame;
end;

procedure TCSHubThemeNotifier.Detach;
begin
  FFrame := nil;
end;

procedure TCSHubThemeNotifier.ChangingTheme;
begin
end;

procedure TCSHubThemeNotifier.ChangedTheme;
begin
  if FFrame <> nil then FFrame.ThemeChanged;
end;

const
  CaptionHeight = 48; // 20 px title with 14 above and below
  PlaceInterval = 200; // ms between two looks at where the panel is

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

constructor TCSHubClientFrame.Create(AOwner: TComponent; AModel: TCSHubModel);
begin
  inherited Create(AOwner);
  FModel := AModel;
  Align := alClient;
  FCaption := TCSHubCaptionFrame.Create(Self, FModel);
  FCaption.Parent := Self;
  FCaption.Height := CaptionHeight;
  FCaption.Align := alTop;
  FList := TCSHubListControl.Create(Self);
  FList.Parent := Self;
  FList.Align := alClient;
  FList.Repo := FModel.Repo;
  FList.Images := FModel.Images;
  FList.Search := FModel.Search;
  FList.OnPaintBackground := ListPaintBackground;
  FList.OnOpenProject := ListOpenProject;
  FList.OnProjectMenu := ListProjectMenu;
  FList.OnProjectMove := ListProjectMove;
  FList.OnGroupAdd := ListGroupAdd;
  FList.OnGroupMove := ListGroupMove;
  FList.OnGroupToggle := ListGroupToggle;
  FList.OnGroupMenu := ListGroupMenu;
  FList.OnSectionAdd := ListSectionAdd;
  FList.OnSectionMove := ListSectionMove;
  FList.OnSectionToggle := ListSectionToggle;
  FList.OnSectionMenu := ListSectionMenu;
  FList.OnProjectDrop := ListProjectDrop;
  FList.OnGroupDrop := ListGroupDrop;
  FList.OnSectionDrop := ListSectionDrop;
  ApplyColors;
  WatchTheme;
  FModel.OnChanged := ModelChanged;
  FList.Reload;
  // When the built-in panels finish loading, the Welcome Page moves ours to make
  // room, without changing its size. Nothing tells a window that its parent moved, and
  // what was on screen stays there: pieces of our panel in the old place, and our own
  // area only partly repainted (seen by the user at IDE startup). So we look at
  // where we are on the page and, after a move, have the page painted again.
  FPlaceTimer := TTimer.Create(Self);
  FPlaceTimer.Interval := PlaceInterval;
  FPlaceTimer.OnTimer := PlaceTick;
end;

// Where the panel is inside the outermost container below the form (the Welcome
// Page itself), which is returned in ATop. Empty while it is not on screen.
function TCSHubClientFrame.PlaceOnPage(out ATop: TWinControl): TRect;
var Origin: TPoint;
begin
  Result := TRect.Empty;
  ATop := Parent;
  if (ATop = nil) or not HandleAllocated or not IsWindowVisible(Handle) then Exit;
  while (ATop.Parent <> nil) and not (ATop.Parent is TCustomForm) do ATop := ATop.Parent;
  if not ATop.HandleAllocated then Exit;
  Origin := ATop.ScreenToClient(ClientToScreen(Point(0, 0)));
  Result := Bounds(Origin.X, Origin.Y, Width, Height);
end;

procedure TCSHubClientFrame.CheckPlace;
var Top: TWinControl;
    R: TRect;
begin
  if csDestroying in ComponentState then Exit;
  R := PlaceOnPage(Top);
  if R.IsEmpty or (R = FPlace) then Exit;
  FPlace := R;
  // The whole page: what we left behind is not ours to paint.
  RedrawWindow(Top.Handle, nil, 0, RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
end;

procedure TCSHubClientFrame.PlaceTick(Sender: TObject);
begin
  CheckPlace;
end;

// A paint request after a move only covers the part that was newly uncovered:
// ask for everything right away, without waiting for the timer.
procedure TCSHubClientFrame.WMPaint(var Message: TWMPaint);
begin
  if Message.DC = 0 then CheckPlace;
  inherited;
end;

destructor TCSHubClientFrame.Destroy;
begin
  UnwatchTheme;
  if Assigned(FOnDestroyed) then FOnDestroyed(Self);
  if FModel <> nil then FModel.OnChanged := nil;
  inherited;
end;

procedure TCSHubClientFrame.WatchTheme;
var Theming: IOTAIDEThemingServices;
    Notifier: TCSHubThemeNotifier;
begin
  FThemeNotifierIndex := -1;
  if not Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) then Exit;
  Notifier := TCSHubThemeNotifier.Create(Self);
  FThemeNotifier := Notifier;
  FThemeNotifierIndex := Theming.AddNotifier(Notifier);
end;

procedure TCSHubClientFrame.UnwatchTheme;
var Theming: IOTAIDEThemingServices;
begin
  if FThemeNotifier = nil then Exit;
  // The IDE may still hold the notifier for a moment: make sure it cannot reach us.
  (FThemeNotifier as TCSHubThemeNotifier).Detach;
  if (FThemeNotifierIndex >= 0) and Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) then
    Theming.RemoveNotifier(FThemeNotifierIndex);
  FThemeNotifierIndex := -1;
  FThemeNotifier := nil;
end;

procedure TCSHubClientFrame.ThemeChanged;
begin
  if csDestroying in ComponentState then Exit;
  ApplyColors;
  FCaption.Invalidate;
  FList.Invalidate;
  // Once more after the IDE finished restyling everything, in case a color was
  // still the old one while it was calling the notifiers.
  if HandleAllocated then PostMessage(Handle, CM_CSHUB_THEME, 0, 0);
end;

procedure TCSHubClientFrame.CMThemeChanged(var Message: TMessage);
begin
  if csDestroying in ComponentState then Exit;
  ApplyColors;
  FCaption.Invalidate;
  FList.Invalidate;
end;

procedure TCSHubClientFrame.ApplyColors;
var Theming: IOTAIDEThemingServices;
    TextColor: TColor;
begin
  FWindowColor := clWindow;
  TextColor := clWindowText;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) and Theming.IDEThemingEnabled then
  begin
    FWindowColor := Theming.StyleServices.GetSystemColor(clWindow);
    TextColor := Theming.StyleServices.GetSystemColor(clWindowText);
  end;
  FList.Color := FWindowColor;
  FList.TextColor := TextColor;
  FList.DimColor := MixColor(TextColor, FWindowColor, 55);
  FCaption.SetDimColor(FList.DimColor);
end;

procedure TCSHubClientFrame.ModelChanged(Sender: TObject);
begin
  FList.Search := FModel.Search;
  FList.Reload;
  FCaption.UpdateCounts;
end;

procedure TCSHubClientFrame.ListPaintBackground(Sender: TObject; ACanvas: TCanvas);
var Background: INTAWelcomePageBackgroundService;
begin
  // Same translucent background the built-in Welcome Page lists use.
  if Supports(WelcomePagePluginService, INTAWelcomePageBackgroundService, Background) then
    Background.PaintBackgroundTo(ACanvas, FList, FWindowColor, TWelcomePageMetrics.Background.Opacity);
end;

procedure TCSHubClientFrame.ListOpenProject(Sender: TObject; AProject: TCSHubProject);
begin
  FModel.OpenProject(AProject);
end;

procedure TCSHubClientFrame.ListProjectMenu(Sender: TObject; AProject: TCSHubProject);
begin
  FModel.ShowProjectMenu(AProject);
end;

procedure TCSHubClientFrame.ListProjectMove(Sender: TObject; AProject: TCSHubProject; ADelta: Integer);
begin
  FModel.ReorderProject(AProject, ADelta);
end;

procedure TCSHubClientFrame.ListGroupAdd(Sender: TObject; AGroup: TCSHubGroup);
begin
  FModel.AddProjects(AGroup);
end;

procedure TCSHubClientFrame.ListGroupMove(Sender: TObject; AGroup: TCSHubGroup; ADelta: Integer);
begin
  FModel.ReorderGroup(AGroup, ADelta);
end;

procedure TCSHubClientFrame.ListGroupToggle(Sender: TObject; AGroup: TCSHubGroup);
begin
  FModel.ToggleGroup(AGroup);
end;

procedure TCSHubClientFrame.ListGroupMenu(Sender: TObject; AGroup: TCSHubGroup);
begin
  FModel.ShowGroupMenu(AGroup);
end;

procedure TCSHubClientFrame.ListSectionAdd(Sender: TObject; ASection: TCSHubSection);
begin
  FModel.NewGroup(ASection);
end;

procedure TCSHubClientFrame.ListSectionMove(Sender: TObject; ASection: TCSHubSection; ADelta: Integer);
begin
  FModel.ReorderSection(ASection, ADelta);
end;

procedure TCSHubClientFrame.ListSectionToggle(Sender: TObject; ASection: TCSHubSection);
begin
  FModel.ToggleSection(ASection);
end;

procedure TCSHubClientFrame.ListSectionMenu(Sender: TObject; ASection: TCSHubSection);
begin
  FModel.ShowSectionMenu(ASection);
end;

procedure TCSHubClientFrame.ListProjectDrop(Sender: TObject; AProject: TCSHubProject; AGroup: TCSHubGroup;
  ABefore: TCSHubProject; APositioned: Boolean);
begin
  FModel.DropProject(AProject, AGroup, ABefore, APositioned);
end;

procedure TCSHubClientFrame.ListGroupDrop(Sender: TObject; AGroup: TCSHubGroup; ASection: TCSHubSection;
  ABefore: TObject);
begin
  FModel.DropGroup(AGroup, ASection, ABefore);
end;

procedure TCSHubClientFrame.ListSectionDrop(Sender: TObject; ASection: TCSHubSection; ABefore: TObject);
begin
  FModel.DropSection(ASection, ABefore);
end;

end.
