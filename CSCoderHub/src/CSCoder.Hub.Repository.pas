unit CSCoder.Hub.Repository;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults,
  System.JSON;

type
  /// Optional container of groups. The interface calls it "Categoria"; the code
  /// and the JSON keep "section" so files already in use stay readable.
  TCSHubSection = class
  public
    Name: string;
    Collapsed: Boolean;
    /// Optional. A library id ('folder'), or CSHubIconFilePrefix plus the name of
    /// a PNG in the icons folder. Kept as read even when unknown, so a file from a
    /// newer version does not lose it.
    Icon: string;
  end;

  /// Holds the shortcuts. It lives in a section or, with Section = nil, loose
  /// at the top of the list.
  TCSHubGroup = class
  public
    Name: string;
    Section: TCSHubSection;
    Collapsed: Boolean;
    /// False shows the projects by name; True keeps the order the user gave them.
    ManualOrder: Boolean;
    /// Optional; see TCSHubSection.Icon.
    Icon: string;
    /// 'Categoria > Grupo', for menus and messages.
    function Path: string;
  end;

  TCSHubProject = class
  public
    Name: string;
    FileName: string;
    Group: TCSHubGroup;
  end;

  /// Address of a variable holding a section, a group or a project (or nil).
  PCSHubItem = ^TObject;

  TCSHubRepository = class
  private
    FProjects: TObjectList<TCSHubProject>;
    FGroups: TObjectList<TCSHubGroup>;
    FSections: TObjectList<TCSHubSection>;
    // Loose groups and sections, mixed, in display order. FSections and the loose
    // groups in FGroups are kept in this same order (SyncLists).
    FTop: TList<TObject>;
    FByName: IComparer<TCSHubProject>;
    FFileName: string;
    FLegacyFileName: string;
    // What our file looked like on disk when we last read or wrote it.
    FStamp: string;
    function DiskStamp: string;
    function ReadProject(AObj: TJSONObject; AGroup: TCSHubGroup): Boolean;
    procedure ReadGroups(AArr: TJSONArray; ASection: TCSHubSection);
    procedure ReadLegacy(ARoot: TJSONObject; AProjects: TJSONArray);
    procedure ReadOrder(AArr: TJSONArray);
    function WriteGroups(ASection: TCSHubSection): TJSONArray;
    function WriteOrder: TJSONArray;
    function WriteIcons: TJSONObject;
    procedure ReadIcons(AObj: TJSONObject);
    function GetIconsDir: string;
    procedure SyncLists;
  public
    constructor Create;
    destructor Destroy; override;
    /// True when a file was read; False when this Delphi has no list yet.
    function Load: Boolean;
    procedure Save;
    /// First run: fills a loose group with the projects the IDE itself lists as
    /// recent ("Closed Projects" under ARegistryKey, HKCU), newest first, only
    /// the files that still exist, up to AMax. Returns how many were added.
    function SeedRecentProjects(const ARegistryKey: string; AMax: Integer): Integer;
    /// True when someone else (another IDE of the same Delphi version) wrote our
    /// file after we last read or wrote it.
    function ChangedOnDisk: Boolean;
    /// Reads our file again and points each reference (section, group or project;
    /// nil is allowed) at the same item in the new content. False = at least one of
    /// them no longer exists; that reference becomes nil. Raises when the file
    /// cannot be read, leaving content and references untouched.
    function Reload(const ARefs: array of PCSHubItem): Boolean;
    /// Replaces the current content with the given file. Raises on invalid JSON,
    /// leaving the current content untouched.
    procedure LoadFromFile(const AFileName: string);
    /// AEmbedIcons (export): the file also carries the pictures the user loaded,
    /// so they travel with it. Our own file only keeps their names.
    procedure SaveToFile(const AFileName: string; AEmbedIcons: Boolean = False);
    /// Adds the sections, groups and projects of ASource that are not here yet.
    function MergeFrom(ASource: TCSHubRepository): Integer;

    function FindSection(const AName: string): TCSHubSection;
    /// Returns the existing section with that name, or creates it.
    function AddSection(const AName: string): TCSHubSection;
    procedure RenameSection(ASection: TCSHubSection; const ANewName: string);
    /// AKeepGroups = True turns its groups into loose groups; False removes
    /// them and their shortcuts too.
    procedure RemoveSection(ASection: TCSHubSection; AKeepGroups: Boolean);
    /// Groups of a section, or the loose ones for nil.
    function GroupsOf(ASection: TCSHubSection): TArray<TCSHubGroup>;
    function SectionProjectCount(ASection: TCSHubSection): Integer;

    /// Group names are unique inside their section (or among the loose ones), ignoring case.
    function FindGroup(const AName: string; ASection: TCSHubSection): TCSHubGroup;
    /// Returns the existing group with that name in that section, or creates it.
    function AddGroup(const AName: string; ASection: TCSHubSection = nil): TCSHubGroup;
    /// Loose groups (TCSHubGroup) and sections (TCSHubSection), mixed, in display order.
    function TopLevel: TArray<TObject>;
    function CanReorderTop(AItem: TObject; ADelta: Integer): Boolean;
    procedure ReorderTop(AItem: TObject; ADelta: Integer);
    /// Every group in display order: the top level from first to last, each section with its groups.
    function OrderedGroups: TArray<TCSHubGroup>;
    /// Stored order, the one written to the file.
    function ProjectsOf(AGroup: TCSHubGroup): TArray<TCSHubProject>;
    /// Order on screen: by name, or the stored one when the group is in manual order.
    function DisplayProjectsOf(AGroup: TCSHubGroup): TArray<TCSHubProject>;
    procedure RenameGroup(AGroup: TCSHubGroup; const ANewName: string);
    /// Removes the group and its shortcuts.
    procedure RemoveGroup(AGroup: TCSHubGroup);
    procedure MoveGroup(AGroup: TCSHubGroup; ASection: TCSHubSection);
    /// Display order. ADelta = -1 moves one position up among the group's
    /// neighbours (same section, or the top level for a loose group), +1 one down.
    function CanReorderGroup(AGroup: TCSHubGroup; ADelta: Integer): Boolean;
    procedure ReorderGroup(AGroup: TCSHubGroup; ADelta: Integer);
    function CanReorderSection(ASection: TCSHubSection; ADelta: Integer): Boolean;
    procedure ReorderSection(ASection: TCSHubSection; ADelta: Integer);
    /// Drag and drop. Puts the group in ASection (nil = top level) right before
    /// ABefore: a group of that section, or any top-level item. Nil or anything
    /// else = last. Raises when the destination already has a group with that name.
    procedure PlaceGroup(AGroup: TCSHubGroup; ASection: TCSHubSection; ABefore: TObject);
    /// Puts the section right before the top-level item ABefore (nil = last).
    procedure PlaceSection(ASection: TCSHubSection; ABefore: TObject);

    function FindProject(const AFileName: string): TCSHubProject;
    function AddProject(const AFileName: string; AGroup: TCSHubGroup): TCSHubProject;
    procedure RemoveProject(AProject: TCSHubProject);
    procedure MoveProject(AProject: TCSHubProject; AGroup: TCSHubGroup);
    /// Moving a project inside its group switches that group to manual order.
    function CanReorderProject(AProject: TCSHubProject; ADelta: Integer): Boolean;
    procedure ReorderProject(AProject: TCSHubProject; ADelta: Integer);
    /// Drag and drop. Puts the project in AGroup right before ABefore (nil = last),
    /// which switches that group to manual order. Dropping it where it already
    /// is changes nothing.
    procedure PlaceProject(AProject: TCSHubProject; AGroup: TCSHubGroup; ABefore: TCSHubProject);
    /// Back to alphabetical order.
    procedure SortGroupByName(AGroup: TCSHubGroup);

    property Projects: TObjectList<TCSHubProject> read FProjects;
    property Groups: TObjectList<TCSHubGroup> read FGroups;
    property Sections: TObjectList<TCSHubSection> read FSections;
    /// This Delphi version's own file.
    property FileName: string read FFileName;
    /// The single file every Delphi shared before each version got its own.
    property LegacyFileName: string read FLegacyFileName;
    /// Where the pictures the user loaded as icons live, beside our file.
    property IconsDir: string read GetIconsDir;
  end;

const
  /// An icon the user loaded: this prefix plus the file name inside IconsDir.
  CSHubIconFilePrefix = 'file:';

/// True when AIcon names a loaded picture with a name only the plugin creates
/// (hexadecimal digits + '.png'): nothing else is ever used as a file name.
function CSHubIconFile(const AIcon: string; out AName: string): Boolean;

/// 'D11', 'D12' or 'D13': the Delphi this binary was compiled for.
function CSHubDelphiTag: string;
/// Registry key of this Delphi's settings, e.g. 'Software\Embarcadero\BDS\22.0'.
function CSHubBdsRegistryKey: string;

implementation

uses
  Winapi.Windows, System.IOUtils, System.NetEncoding, System.Win.Registry, CSCoder.Hub.Strings;

const
  FormatVersion = 2;
  MaxIconBytes = 256 * 1024; // a stored icon has a few KB
  MaxIconCount = 500;

function CSHubIconFile(const AIcon: string; out AName: string): Boolean;
var I: Integer;
begin
  Result := False;
  AName := '';
  if not AIcon.StartsWith(CSHubIconFilePrefix) then Exit;
  AName := Copy(AIcon, Length(CSHubIconFilePrefix) + 1, MaxInt);
  if (Length(AName) < 12) or (Length(AName) > 68) or not AName.EndsWith('.png') then Exit;
  for I := 1 to Length(AName) - 4 do
    if not CharInSet(AName[I], ['0'..'9', 'a'..'f']) then Exit;
  Result := True;
end;

// Anything that is not text counts as no icon: it must never stop a file from loading.
function IconOf(AObj: TJSONObject): string;
begin
  if AObj.GetValue('icon') is TJSONString then Result := AObj.GetValue('icon').Value else Result := '';
end;

function IsPng(const ABytes: TBytes): Boolean;
const
  Signature: array[0..7] of Byte = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);
var I: Integer;
begin
  Result := (Length(ABytes) > Length(Signature)) and (Length(ABytes) <= MaxIconBytes);
  if Result then
    for I := 0 to High(Signature) do
      if ABytes[I] <> Signature[I] then Exit(False);
end;

function CSHubDelphiTag: string;
begin
  {$IF CompilerVersion >= 38.0}
  Result := 'D' + IntToStr(Trunc(CompilerVersion) - 24); // future versions: 38 -> D14, ...
  {$ELSEIF CompilerVersion >= 37.0}
  Result := 'D13';
  {$ELSEIF CompilerVersion >= 36.0}
  Result := 'D12';
  {$ELSE}
  Result := 'D11';
  {$IFEND}
end;

function CSHubBdsRegistryKey: string;
begin
  {$IF CompilerVersion >= 38.0}
  // Since Delphi 13 the BDS key equals the compiler version (37.0 / 37.0); assumed to go on.
  Result := 'Software\Embarcadero\BDS\' + IntToStr(Trunc(CompilerVersion)) + '.0';
  {$ELSEIF CompilerVersion >= 37.0}
  Result := 'Software\Embarcadero\BDS\37.0';
  {$ELSEIF CompilerVersion >= 36.0}
  Result := 'Software\Embarcadero\BDS\23.0';
  {$ELSE}
  Result := 'Software\Embarcadero\BDS\22.0';
  {$IFEND}
end;

{ TCSHubGroup }

function TCSHubGroup.Path: string;
begin
  if Section = nil then Result := Name else Result := Section.Name + ' > ' + Name;
end;

{ TCSHubRepository }

constructor TCSHubRepository.Create;
var Base: string;
begin
  inherited Create;
  FProjects := TObjectList<TCSHubProject>.Create(True);
  FGroups := TObjectList<TCSHubGroup>.Create(True);
  FSections := TObjectList<TCSHubSection>.Create(True);
  FTop := TList<TObject>.Create;
  FByName := TComparer<TCSHubProject>.Construct(
    function(const A, B: TCSHubProject): Integer
    begin
      Result := CompareText(A.Name, B.Name);
      if Result = 0 then Result := CompareText(A.FileName, B.FileName);
    end);
  // LOCALAPPDATA is authoritative on Windows (including redirected profiles).
  Base := GetEnvironmentVariable('LOCALAPPDATA');
  if Base = '' then Base := TPath.GetHomePath;
  Base := TPath.Combine(Base, 'CSCoder\Hub');
  // Each Delphi version keeps its own list: a Delphi installed later must start
  // empty instead of inheriting the shortcuts of another one.
  FFileName := TPath.Combine(TPath.Combine(Base, CSHubDelphiTag), 'projects.json');
  FLegacyFileName := TPath.Combine(Base, 'projects.json');
end;

function TCSHubRepository.GetIconsDir: string;
begin
  Result := TPath.Combine(TPath.GetDirectoryName(FFileName), 'icons');
end;

destructor TCSHubRepository.Destroy;
begin
  FTop.Free;
  FProjects.Free;
  FGroups.Free;
  FSections.Free;
  inherited;
end;

function TCSHubRepository.FindSection(const AName: string): TCSHubSection;
var S: TCSHubSection;
begin
  for S in FSections do
    if SameText(S.Name, Trim(AName)) then Exit(S);
  Result := nil;
end;

function TCSHubRepository.AddSection(const AName: string): TCSHubSection;
var S: string;
begin
  S := Trim(AName);
  if S = '' then raise Exception.Create(L(sErrSectionName));
  Result := FindSection(S);
  if Result <> nil then Exit;
  Result := TCSHubSection.Create;
  Result.Name := S;
  FSections.Add(Result);
  FTop.Add(Result);
end;

procedure TCSHubRepository.RenameSection(ASection: TCSHubSection; const ANewName: string);
var S: string;
    Other: TCSHubSection;
begin
  S := Trim(ANewName);
  if S = '' then Exit;
  Other := FindSection(S);
  if (Other <> nil) and (Other <> ASection) then
    raise Exception.Create(L(sErrSectionExists));
  ASection.Name := S;
end;

procedure TCSHubRepository.RemoveSection(ASection: TCSHubSection; AKeepGroups: Boolean);
var G: TCSHubGroup;
    Index: Integer;
begin
  Index := FTop.IndexOf(ASection);
  for G in GroupsOf(ASection) do
    if AKeepGroups then
    begin
      // A loose group may already use the name: keep both apart.
      if FindGroup(G.Name, nil) <> nil then G.Name := G.Name + ' (' + ASection.Name + ')';
      G.Section := nil;
      // The kept groups stay where the section was.
      FTop.Insert(Index, G);
      Inc(Index);
    end
    else
      RemoveGroup(G);
  FTop.Remove(ASection);
  FSections.Remove(ASection);
  SyncLists;
end;

function TCSHubRepository.GroupsOf(ASection: TCSHubSection): TArray<TCSHubGroup>;
var G: TCSHubGroup;
begin
  Result := nil;
  for G in FGroups do
    if G.Section = ASection then Result := Result + [G];
end;

function TCSHubRepository.SectionProjectCount(ASection: TCSHubSection): Integer;
var P: TCSHubProject;
begin
  Result := 0;
  for P in FProjects do
    if P.Group.Section = ASection then Inc(Result);
end;

function TCSHubRepository.FindGroup(const AName: string; ASection: TCSHubSection): TCSHubGroup;
var G: TCSHubGroup;
begin
  for G in FGroups do
    if (G.Section = ASection) and SameText(G.Name, Trim(AName)) then Exit(G);
  Result := nil;
end;

function TCSHubRepository.AddGroup(const AName: string; ASection: TCSHubSection): TCSHubGroup;
var S: string;
begin
  S := Trim(AName);
  if S = '' then raise Exception.Create(L(sErrGroupName));
  Result := FindGroup(S, ASection);
  if Result <> nil then Exit;
  Result := TCSHubGroup.Create;
  Result.Name := S;
  Result.Section := ASection;
  FGroups.Add(Result);
  if ASection = nil then FTop.Add(Result);
end;

function TCSHubRepository.TopLevel: TArray<TObject>;
begin
  Result := FTop.ToArray;
end;

// The "groups" and "sections" arrays of the file follow the display order too, so a
// plugin version that does not know "order" still shows each of them in sequence.
procedure TCSHubRepository.SyncLists;
var Item: TObject;
begin
  for Item in FTop do
    if Item is TCSHubSection then
      FSections.Move(FSections.IndexOf(TCSHubSection(Item)), FSections.Count - 1)
    else
      FGroups.Move(FGroups.IndexOf(TCSHubGroup(Item)), FGroups.Count - 1);
end;

function TCSHubRepository.CanReorderTop(AItem: TObject; ADelta: Integer): Boolean;
var Index: Integer;
begin
  Index := FTop.IndexOf(AItem);
  Result := (Index >= 0) and (Index + ADelta >= 0) and (Index + ADelta < FTop.Count);
end;

procedure TCSHubRepository.ReorderTop(AItem: TObject; ADelta: Integer);
var Index: Integer;
begin
  if not CanReorderTop(AItem, ADelta) then Exit;
  Index := FTop.IndexOf(AItem);
  FTop.Exchange(Index, Index + ADelta);
  SyncLists;
end;

function TCSHubRepository.OrderedGroups: TArray<TCSHubGroup>;
var Item: TObject;
begin
  Result := nil;
  for Item in FTop do
    if Item is TCSHubGroup then
      Result := Result + [TCSHubGroup(Item)]
    else
      Result := Result + GroupsOf(TCSHubSection(Item));
end;

function TCSHubRepository.ProjectsOf(AGroup: TCSHubGroup): TArray<TCSHubProject>;
var P: TCSHubProject;
begin
  Result := nil;
  for P in FProjects do
    if P.Group = AGroup then Result := Result + [P];
end;

function TCSHubRepository.DisplayProjectsOf(AGroup: TCSHubGroup): TArray<TCSHubProject>;
begin
  Result := ProjectsOf(AGroup);
  if not AGroup.ManualOrder then TArray.Sort<TCSHubProject>(Result, FByName);
end;

procedure TCSHubRepository.RenameGroup(AGroup: TCSHubGroup; const ANewName: string);
var S: string;
    Other: TCSHubGroup;
begin
  S := Trim(ANewName);
  if S = '' then Exit;
  Other := FindGroup(S, AGroup.Section);
  if (Other <> nil) and (Other <> AGroup) then
    raise Exception.Create(L(sErrGroupExists));
  AGroup.Name := S;
end;

procedure TCSHubRepository.RemoveGroup(AGroup: TCSHubGroup);
var I: Integer;
begin
  for I := FProjects.Count - 1 downto 0 do
    if FProjects[I].Group = AGroup then FProjects.Delete(I);
  FTop.Remove(AGroup);
  FGroups.Remove(AGroup);
end;

procedure TCSHubRepository.MoveGroup(AGroup: TCSHubGroup; ASection: TCSHubSection);
begin
  if AGroup.Section = ASection then Exit;
  if FindGroup(AGroup.Name, ASection) <> nil then
    raise Exception.Create(L(sErrGroupExistsTarget));
  if AGroup.Section = nil then FTop.Remove(AGroup);
  AGroup.Section := ASection;
  // Last among its new neighbours.
  if ASection = nil then FTop.Add(AGroup);
  FGroups.Move(FGroups.IndexOf(AGroup), FGroups.Count - 1);
end;

function TCSHubRepository.CanReorderGroup(AGroup: TCSHubGroup; ADelta: Integer): Boolean;
var Siblings: TArray<TCSHubGroup>;
    I, Index: Integer;
begin
  if AGroup.Section = nil then Exit(CanReorderTop(AGroup, ADelta));
  Siblings := GroupsOf(AGroup.Section);
  Index := -1;
  for I := 0 to High(Siblings) do
    if Siblings[I] = AGroup then Index := I;
  Result := (Index >= 0) and (Index + ADelta >= 0) and (Index + ADelta <= High(Siblings));
end;

procedure TCSHubRepository.ReorderGroup(AGroup: TCSHubGroup; ADelta: Integer);
var Siblings: TArray<TCSHubGroup>;
    I: Integer;
begin
  if AGroup.Section = nil then
  begin
    ReorderTop(AGroup, ADelta);
    Exit;
  end;
  if not CanReorderGroup(AGroup, ADelta) then Exit;
  Siblings := GroupsOf(AGroup.Section);
  for I := 0 to High(Siblings) do
    if Siblings[I] = AGroup then
    begin
      // Groups of every section share one list: swap with the neighbour, wherever it sits.
      FGroups.Exchange(FGroups.IndexOf(AGroup), FGroups.IndexOf(Siblings[I + ADelta]));
      Exit;
    end;
end;

function TCSHubRepository.CanReorderSection(ASection: TCSHubSection; ADelta: Integer): Boolean;
begin
  Result := CanReorderTop(ASection, ADelta);
end;

procedure TCSHubRepository.ReorderSection(ASection: TCSHubSection; ADelta: Integer);
begin
  ReorderTop(ASection, ADelta);
end;

procedure TCSHubRepository.PlaceGroup(AGroup: TCSHubGroup; ASection: TCSHubSection; ABefore: TObject);
var Order: TArray<TCSHubGroup>;
    G: TCSHubGroup;
    Index: Integer;
    Placed: Boolean;
begin
  if ABefore = AGroup then Exit;
  if (AGroup.Section <> ASection) and (FindGroup(AGroup.Name, ASection) <> nil) then
    raise Exception.Create(L(sErrGroupExistsTarget));
  if AGroup.Section = nil then FTop.Remove(AGroup);
  AGroup.Section := ASection;
  if ASection = nil then
  begin
    Index := FTop.IndexOf(ABefore);
    if Index < 0 then FTop.Add(AGroup) else FTop.Insert(Index, AGroup);
  end
  else
  begin
    Order := nil;
    Placed := False;
    for G in GroupsOf(ASection) do
    begin
      if G = AGroup then Continue;
      if G = ABefore then
      begin
        Order := Order + [AGroup];
        Placed := True;
      end;
      Order := Order + [G];
    end;
    if not Placed then Order := Order + [AGroup];
    // Groups of every section share one list: only their relative order matters.
    for G in Order do FGroups.Move(FGroups.IndexOf(G), FGroups.Count - 1);
  end;
  SyncLists;
end;

procedure TCSHubRepository.PlaceSection(ASection: TCSHubSection; ABefore: TObject);
var Index: Integer;
begin
  if ABefore = ASection then Exit;
  FTop.Remove(ASection);
  Index := FTop.IndexOf(ABefore);
  if Index < 0 then FTop.Add(ASection) else FTop.Insert(Index, ASection);
  SyncLists;
end;

function TCSHubRepository.FindProject(const AFileName: string): TCSHubProject;
var P: TCSHubProject;
begin
  for P in FProjects do
    if SameText(P.FileName, AFileName) then Exit(P);
  Result := nil;
end;

function TCSHubRepository.AddProject(const AFileName: string; AGroup: TCSHubGroup): TCSHubProject;
var FullName: string;
begin
  FullName := TPath.GetFullPath(AFileName);
  if FindProject(FullName) <> nil then
    raise Exception.Create(L(sErrProjectExists));
  Result := TCSHubProject.Create;
  Result.FileName := FullName;
  Result.Name := TPath.GetFileNameWithoutExtension(FullName);
  Result.Group := AGroup;
  FProjects.Add(Result);
end;

procedure TCSHubRepository.RemoveProject(AProject: TCSHubProject);
begin
  FProjects.Remove(AProject);
end;

procedure TCSHubRepository.MoveProject(AProject: TCSHubProject; AGroup: TCSHubGroup);
begin
  if AProject.Group = AGroup then Exit;
  AProject.Group := AGroup;
  // Last in a group kept in manual order.
  FProjects.Move(FProjects.IndexOf(AProject), FProjects.Count - 1);
end;

function TCSHubRepository.CanReorderProject(AProject: TCSHubProject; ADelta: Integer): Boolean;
var Siblings: TArray<TCSHubProject>;
    I, Index: Integer;
begin
  Siblings := DisplayProjectsOf(AProject.Group);
  Index := -1;
  for I := 0 to High(Siblings) do
    if Siblings[I] = AProject then Index := I;
  Result := (Index >= 0) and (Index + ADelta >= 0) and (Index + ADelta <= High(Siblings));
end;

procedure TCSHubRepository.ReorderProject(AProject: TCSHubProject; ADelta: Integer);
var Siblings: TArray<TCSHubProject>;
    P: TCSHubProject;
    I: Integer;
begin
  if not CanReorderProject(AProject, ADelta) then Exit;
  Siblings := DisplayProjectsOf(AProject.Group);
  if not AProject.Group.ManualOrder then
  begin
    // First move in this group: what was on screen (by name) becomes the stored order.
    for P in Siblings do FProjects.Move(FProjects.IndexOf(P), FProjects.Count - 1);
    AProject.Group.ManualOrder := True;
  end;
  for I := 0 to High(Siblings) do
    if Siblings[I] = AProject then
    begin
      FProjects.Exchange(FProjects.IndexOf(AProject), FProjects.IndexOf(Siblings[I + ADelta]));
      Exit;
    end;
end;

procedure TCSHubRepository.PlaceProject(AProject: TCSHubProject; AGroup: TCSHubGroup; ABefore: TCSHubProject);
var Old, Order: TArray<TCSHubProject>;
    P: TCSHubProject;
    I: Integer;
    Placed, Same: Boolean;
begin
  if ABefore = AProject then Exit;
  Old := DisplayProjectsOf(AGroup);
  Order := nil;
  Placed := False;
  for P in Old do
  begin
    if P = AProject then Continue;
    if P = ABefore then
    begin
      Order := Order + [AProject];
      Placed := True;
    end;
    Order := Order + [P];
  end;
  if not Placed then Order := Order + [AProject];
  // Dropped where it already was: the group must not turn manual for nothing.
  if (AProject.Group = AGroup) and (Length(Order) = Length(Old)) then
  begin
    Same := True;
    for I := 0 to High(Order) do
      if Order[I] <> Old[I] then Same := False;
    if Same then Exit;
  end;
  AProject.Group := AGroup;
  for P in Order do FProjects.Move(FProjects.IndexOf(P), FProjects.Count - 1);
  AGroup.ManualOrder := True;
end;

procedure TCSHubRepository.SortGroupByName(AGroup: TCSHubGroup);
begin
  AGroup.ManualOrder := False;
end;

function TCSHubRepository.MergeFrom(ASource: TCSHubRepository): Integer;
var G, Target: TCSHubGroup;
    Section: TCSHubSection;
    Item: TObject;
    P, Copy: TCSHubProject;
    Map: TDictionary<TCSHubGroup, TCSHubGroup>;
begin
  Result := 0;
  Map := TDictionary<TCSHubGroup, TCSHubGroup>.Create;
  try
    // What is new goes to the end of the top level, in the order the source shows it.
    // What already exists keeps its icon; what is new brings the one it had.
    for Item in ASource.TopLevel do
      if Item is TCSHubSection then
      begin
        if FindSection(TCSHubSection(Item).Name) = nil then
          AddSection(TCSHubSection(Item).Name).Icon := TCSHubSection(Item).Icon;
      end
      else if FindGroup(TCSHubGroup(Item).Name, nil) = nil then
      begin
        Target := AddGroup(TCSHubGroup(Item).Name, nil);
        Target.ManualOrder := TCSHubGroup(Item).ManualOrder;
        Target.Icon := TCSHubGroup(Item).Icon;
      end;
    for G in ASource.OrderedGroups do
    begin
      Section := nil;
      if G.Section <> nil then Section := FindSection(G.Section.Name);
      Target := FindGroup(G.Name, Section);
      if Target = nil then
      begin
        Target := AddGroup(G.Name, Section);
        // A group that comes whole from the source keeps the order it had there.
        Target.ManualOrder := G.ManualOrder;
        Target.Icon := G.Icon;
      end;
      Map.Add(G, Target);
    end;
    for P in ASource.Projects do
    begin
      if FindProject(P.FileName) <> nil then Continue;
      Copy := TCSHubProject.Create;
      Copy.Name := P.Name;
      Copy.FileName := P.FileName;
      Copy.Group := Map[P.Group];
      FProjects.Add(Copy);
      Inc(Result);
    end;
  finally
    Map.Free;
  end;
end;

function TCSHubRepository.Load: Boolean;
begin
  Result := True;
  // Taken before reading: a write that lands in between must still be noticed.
  FStamp := DiskStamp;
  if TFile.Exists(FFileName) then
    LoadFromFile(FFileName)
  // Releases up to the shared file only existed for Delphi 11, so that list belongs
  // to Delphi 11. The shared file is left in place; the next Save writes ours.
  else if (CSHubDelphiTag = 'D11') and TFile.Exists(FLegacyFileName) then
    LoadFromFile(FLegacyFileName)
  else
    Result := False;
end;

// The IDE writes one value per project: File_0 = TBaseProject,'C:\...\App.dproj',1,1,1,1,1
// (File_0 is the most recent). Only the quoted path matters here.
function TCSHubRepository.SeedRecentProjects(const ARegistryKey: string; AMax: Integer): Integer;
var Reg: TRegistry;
    Names: TStringList;
    I, P1, P2: Integer;
    Value, FileName, Ext: string;
    G: TCSHubGroup;
begin
  Result := 0;
  Names := TStringList.Create;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if not Reg.OpenKeyReadOnly(ARegistryKey + '\Closed Projects') then Exit;
    G := nil;
    for I := 0 to 99 do
    begin
      if Result >= AMax then Break;
      if not Reg.ValueExists('File_' + IntToStr(I)) then Break;
      Value := Reg.ReadString('File_' + IntToStr(I));
      P1 := Pos('''', Value);
      P2 := 0;
      if P1 > 0 then P2 := Pos('''', Value, P1 + 1);
      if (P1 = 0) or (P2 = 0) then Continue;
      FileName := Copy(Value, P1 + 1, P2 - P1 - 1);
      Ext := LowerCase(TPath.GetExtension(FileName));
      if (Ext <> '.dproj') and (Ext <> '.groupproj') and (Ext <> '.dpr') then Continue;
      if not TFile.Exists(FileName) or (FindProject(FileName) <> nil) then Continue;
      if G = nil then
      begin
        G := AddGroup(L(sRecentGroup));
        G.Icon := 'clock';
        G.ManualOrder := True; // newest first, as the IDE lists them
      end;
      AddProject(FileName, G);
      Inc(Result);
    end;
  finally
    Reg.Free;
    Names.Free;
  end;
end;

procedure TCSHubRepository.Save;
begin
  SaveToFile(FFileName);
  FStamp := DiskStamp;
end;

// Size and last write time; empty when the file does not exist.
function TCSHubRepository.DiskStamp: string;
var SR: TSearchRec;
begin
  Result := '';
  if FindFirst(FFileName, faAnyFile, SR) <> 0 then Exit;
  try
    {$WARN SYMBOL_PLATFORM OFF} // the plugin only exists on Windows
    Result := Format('%d.%d.%d', [SR.Size, SR.FindData.ftLastWriteTime.dwHighDateTime,
      SR.FindData.ftLastWriteTime.dwLowDateTime]);
    {$WARN SYMBOL_PLATFORM ON}
  finally
    System.SysUtils.FindClose(SR); // not the Winapi one: this is a TSearchRec
  end;
end;

function TCSHubRepository.ChangedOnDisk: Boolean;
begin
  Result := DiskStamp <> FStamp;
end;

function TCSHubRepository.Reload(const ARefs: array of PCSHubItem): Boolean;
type
  TKey = record
    Kind: (kNone, kSection, kGroup, kProject);
    Section, Name: string;
  end;
var Keys: array of TKey;
    Item: TObject;
    Section: TCSHubSection;
    I, Attempt: Integer;
begin
  Result := True;
  // Loading frees every object: remember each one by what identifies it in the file.
  SetLength(Keys, Length(ARefs));
  for I := 0 to High(ARefs) do
  begin
    Item := ARefs[I]^;
    if Item is TCSHubSection then
    begin
      Keys[I].Kind := kSection;
      Keys[I].Name := TCSHubSection(Item).Name;
    end
    else if Item is TCSHubGroup then
    begin
      Keys[I].Kind := kGroup;
      Keys[I].Name := TCSHubGroup(Item).Name;
      if TCSHubGroup(Item).Section <> nil then Keys[I].Section := TCSHubGroup(Item).Section.Name;
    end
    else if Item is TCSHubProject then
    begin
      Keys[I].Kind := kProject;
      Keys[I].Name := TCSHubProject(Item).FileName;
    end;
  end;
  // Nothing saved yet: what is in memory stands.
  if not TFile.Exists(FFileName) then Exit;
  Attempt := 0;
  while True do
    try
      FStamp := DiskStamp;
      LoadFromFile(FFileName);
      Break;
    except
      // The other IDE may be in the middle of replacing the file: try again shortly.
      on E: Exception do
      begin
        Inc(Attempt);
        if not ((E is EStreamError) or (E is EInOutError)) or (Attempt >= 5) then raise;
        Sleep(40);
      end;
    end;
  for I := 0 to High(ARefs) do
  begin
    Item := nil;
    case Keys[I].Kind of
      kSection: Item := FindSection(Keys[I].Name);
      kGroup:
        if Keys[I].Section = '' then
          Item := FindGroup(Keys[I].Name, nil)
        else
        begin
          Section := FindSection(Keys[I].Section);
          if Section <> nil then Item := FindGroup(Keys[I].Name, Section);
        end;
      kProject: Item := FindProject(Keys[I].Name);
    else
      Continue;
    end;
    ARefs[I]^ := Item;
    if Item = nil then Result := False;
  end;
end;

function TCSHubRepository.ReadProject(AObj: TJSONObject; AGroup: TCSHubGroup): Boolean;
var P: TCSHubProject;
    FileName: string;
begin
  FileName := AObj.GetValue<string>('file', '');
  Result := (FileName <> '') and (FindProject(FileName) = nil);
  if not Result then Exit;
  P := TCSHubProject.Create;
  P.FileName := FileName;
  P.Name := AObj.GetValue<string>('name', '');
  if P.Name = '' then P.Name := TPath.GetFileNameWithoutExtension(FileName);
  P.Group := AGroup;
  FProjects.Add(P);
end;

procedure TCSHubRepository.ReadGroups(AArr: TJSONArray; ASection: TCSHubSection);
var V, PV: TJSONValue;
    Obj: TJSONObject;
    Arr: TJSONArray;
    G: TCSHubGroup;
    Name: string;
begin
  for V in AArr do
  begin
    if V is TJSONString then
    begin
      // Format 1 file that had groups but no projects.
      if Trim(V.Value) <> '' then AddGroup(V.Value, ASection);
      Continue;
    end;
    if not (V is TJSONObject) then Continue;
    Obj := TJSONObject(V);
    Name := Trim(Obj.GetValue<string>('name', ''));
    if Name = '' then Name := L(sUngrouped);
    G := AddGroup(Name, ASection);
    G.Collapsed := Obj.GetValue<Boolean>('collapsed', False);
    G.ManualOrder := Obj.GetValue<Boolean>('manualOrder', False);
    G.Icon := IconOf(Obj);
    if Obj.TryGetValue<TJSONArray>('projects', Arr) then
      for PV in Arr do
        if PV is TJSONObject then ReadProject(TJSONObject(PV), G);
  end;
end;

// Format 1: flat "groups" (names), "collapsed" (names) and root-level "projects"
// carrying the group name. Everything becomes a loose group.
procedure TCSHubRepository.ReadLegacy(ARoot: TJSONObject; AProjects: TJSONArray);
var Arr: TJSONArray;
    V: TJSONValue;
    G: TCSHubGroup;
    GroupName: string;
begin
  if ARoot.TryGetValue<TJSONArray>('groups', Arr) then ReadGroups(Arr, nil);
  for V in AProjects do
  begin
    if not (V is TJSONObject) then Continue;
    GroupName := Trim(TJSONObject(V).GetValue<string>('group', ''));
    if GroupName = '' then GroupName := L(sUngrouped);
    ReadProject(TJSONObject(V), AddGroup(GroupName));
  end;
  if ARoot.TryGetValue<TJSONArray>('collapsed', Arr) then
    for V in Arr do
    begin
      G := FindGroup(V.Value, nil);
      if G <> nil then G.Collapsed := True;
    end;
end;

// "order": the sequence of the top level, by kind and name. What it does not list
// keeps the default (loose groups, then sections) after what it does; names that
// do not exist are ignored.
procedure TCSHubRepository.ReadOrder(AArr: TJSONArray);
var V: TJSONValue;
    Item: TObject;
    Ordered: TList<TObject>;
begin
  Ordered := TList<TObject>.Create;
  try
    for V in AArr do
    begin
      if not (V is TJSONObject) then Continue;
      Item := nil;
      if TJSONObject(V).GetValue('section') is TJSONString then
        Item := FindSection(TJSONObject(V).GetValue('section').Value)
      else if TJSONObject(V).GetValue('group') is TJSONString then
        Item := FindGroup(TJSONObject(V).GetValue('group').Value, nil);
      if (Item <> nil) and not Ordered.Contains(Item) then Ordered.Add(Item);
    end;
    for Item in FTop do
      if not Ordered.Contains(Item) then Ordered.Add(Item);
    FTop.Clear;
    FTop.AddRange(Ordered);
  finally
    Ordered.Free;
  end;
  SyncLists;
end;

procedure TCSHubRepository.LoadFromFile(const AFileName: string);
var Parsed: TJSONValue;
    Root, Obj: TJSONObject;
    Arr, GroupArr: TJSONArray;
    V: TJSONValue;
    Section: TCSHubSection;
    Raw, Name: string;
begin
  Raw := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  Parsed := TJSONObject.ParseJSONValue(Raw);
  try
    if not (Parsed is TJSONObject) then
      raise Exception.Create(L(sErrInvalidJson, [AFileName]));
    Root := TJSONObject(Parsed);
    FProjects.Clear;
    FGroups.Clear;
    FSections.Clear;
    FTop.Clear;
    if Root.TryGetValue<TJSONArray>('projects', Arr) then
    begin
      ReadLegacy(Root, Arr);
      Exit;
    end;
    if Root.TryGetValue<TJSONArray>('groups', Arr) then ReadGroups(Arr, nil);
    if Root.TryGetValue<TJSONArray>('sections', Arr) then
      for V in Arr do
      begin
        if not (V is TJSONObject) then Continue;
        Obj := TJSONObject(V);
        Name := Trim(Obj.GetValue<string>('name', ''));
        if Name = '' then Continue;
        Section := AddSection(Name);
        Section.Collapsed := Obj.GetValue<Boolean>('collapsed', False);
        Section.Icon := IconOf(Obj);
        if Obj.TryGetValue<TJSONArray>('groups', GroupArr) then ReadGroups(GroupArr, Section);
      end;
    if Root.TryGetValue<TJSONArray>('order', Arr) then ReadOrder(Arr);
    // Only an exported file has them.
    if Root.GetValue('icons') is TJSONObject then ReadIcons(TJSONObject(Root.GetValue('icons')));
  finally
    Parsed.Free;
  end;
end;

function TCSHubRepository.WriteGroups(ASection: TCSHubSection): TJSONArray;
var G: TCSHubGroup;
    P: TCSHubProject;
    GroupObj, Obj: TJSONObject;
    Arr: TJSONArray;
begin
  Result := TJSONArray.Create;
  for G in GroupsOf(ASection) do
  begin
    GroupObj := TJSONObject.Create;
    GroupObj.AddPair('name', G.Name);
    GroupObj.AddPair('collapsed', TJSONBool.Create(G.Collapsed));
    if G.ManualOrder then GroupObj.AddPair('manualOrder', TJSONBool.Create(True));
    if G.Icon <> '' then GroupObj.AddPair('icon', G.Icon);
    Arr := TJSONArray.Create;
    for P in ProjectsOf(G) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('name', P.Name);
      Obj.AddPair('file', P.FileName);
      Arr.AddElement(Obj);
    end;
    GroupObj.AddPair('projects', Arr);
    Result.AddElement(GroupObj);
  end;
end;

function TCSHubRepository.WriteOrder: TJSONArray;
var Item: TObject;
    Obj: TJSONObject;
begin
  Result := TJSONArray.Create;
  for Item in FTop do
  begin
    Obj := TJSONObject.Create;
    if Item is TCSHubSection then
      Obj.AddPair('section', TCSHubSection(Item).Name)
    else
      Obj.AddPair('group', TCSHubGroup(Item).Name);
    Result.AddElement(Obj);
  end;
end;

// "icons" of an exported file: name -> PNG in base64, for each loaded picture in
// use. Nil when there is none.
function TCSHubRepository.WriteIcons: TJSONObject;
var Names: TStringList;
    Section: TCSHubSection;
    G: TCSHubGroup;
    Encoding: TBase64Encoding;
    Bytes: TBytes;
    Name, FileName: string;

  procedure Collect(const AIcon: string);
  var IconName: string;
  begin
    if CSHubIconFile(AIcon, IconName) and (Names.IndexOf(IconName) < 0) then Names.Add(IconName);
  end;

begin
  Result := nil;
  Names := TStringList.Create;
  Encoding := TBase64Encoding.Create(0); // no line breaks
  try
    try
      for Section in FSections do Collect(Section.Icon);
      for G in FGroups do Collect(G.Icon);
      for Name in Names do
      begin
        FileName := TPath.Combine(IconsDir, Name);
        // A picture that is missing or unreadable is just left out.
        try
          if not TFile.Exists(FileName) then Continue;
          Bytes := TFile.ReadAllBytes(FileName);
        except
          Continue;
        end;
        if not IsPng(Bytes) then Continue;
        if Result = nil then Result := TJSONObject.Create;
        Result.AddPair(Name, Encoding.EncodeBytesToString(Bytes));
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Encoding.Free;
    Names.Free;
  end;
end;

// Pictures carried by an imported file go to our icons folder. The file comes from
// outside: a name is only accepted in the form the plugin creates, the content has
// to be a small PNG, and nothing that already exists is overwritten.
procedure TCSHubRepository.ReadIcons(AObj: TJSONObject);
var Pair: TJSONPair;
    Name, FileName: string;
    Bytes: TBytes;
    Done: Integer;
begin
  Done := 0;
  for Pair in AObj do
  begin
    if Done >= MaxIconCount then Break;
    if not CSHubIconFile(CSHubIconFilePrefix + Pair.JsonString.Value, Name) then Continue;
    if not (Pair.JsonValue is TJSONString) then Continue;
    // A picture that cannot be stored only costs the picture.
    try
      Bytes := TNetEncoding.Base64.DecodeStringToBytes(Pair.JsonValue.Value);
      if not IsPng(Bytes) then Continue;
      FileName := TPath.Combine(IconsDir, Name);
      if not TFile.Exists(FileName) then
      begin
        TDirectory.CreateDirectory(IconsDir);
        TFile.WriteAllBytes(FileName, Bytes);
      end;
      Inc(Done);
    except
    end;
  end;
end;

procedure TCSHubRepository.SaveToFile(const AFileName: string; AEmbedIcons: Boolean);
var Root, Obj, Icons: TJSONObject;
    Arr: TJSONArray;
    Section: TCSHubSection;
    TempName: string;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(FormatVersion));
    Root.AddPair('groups', WriteGroups(nil));
    Arr := TJSONArray.Create;
    for Section in FSections do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('name', Section.Name);
      Obj.AddPair('collapsed', TJSONBool.Create(Section.Collapsed));
      if Section.Icon <> '' then Obj.AddPair('icon', Section.Icon);
      Obj.AddPair('groups', WriteGroups(Section));
      Arr.AddElement(Obj);
    end;
    Root.AddPair('sections', Arr);
    Root.AddPair('order', WriteOrder);
    if AEmbedIcons then
    begin
      Icons := WriteIcons;
      if Icons <> nil then Root.AddPair('icons', Icons);
    end;
    TDirectory.CreateDirectory(TPath.GetDirectoryName(AFileName));
    TempName := AFileName + '.tmp';
    TFile.WriteAllText(TempName, Root.ToJSON, TEncoding.UTF8);
    // Replace old configuration only after the complete temporary file is written.
    if TFile.Exists(AFileName) then
      TFile.Replace(TempName, AFileName, AFileName + '.bak')
    else
      TFile.Move(TempName, AFileName);
  finally
    Root.Free;
  end;
end;

end.
