unit CSCoder.Hub.WelcomePlugin;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.Graphics, ToolsAPI.WelcomePage,
  CSCoder.Hub.Model;

const
  CSHubPluginID = 'br.com.cscoder.HubProjetos';
  CSHubPluginName = 'CS.Coder - Hub de Projetos';

type
  TCSHubWelcomePlugin = class(TInterfacedObject,
    INTAWelcomePagePlugin, INTAWelcomePageContentPluginCreator)
  private
    FView: TFrame;
    FIconIndex: Integer;
    FModel: TCSHubModel;
    procedure ViewDestroyed(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    function GetPluginID: string;
    function GetPluginName: string;
    function GetPluginVisible: Boolean;
    function GetView: TFrame;
    function CreateView: TFrame;
    procedure DestroyView;
    function GetIcon: TGraphicArray;
    function GetIconIndex: Integer;
    procedure SetIconIndex(const Value: Integer);
  end;

implementation

uses CSCoder.Hub.ClientFrame;

constructor TCSHubWelcomePlugin.Create;
begin
  inherited Create;
  FIconIndex := -1;
  FModel := TCSHubModel.Create;
end;

destructor TCSHubWelcomePlugin.Destroy;
begin
  DestroyView;
  FModel.Free;
  inherited;
end;

function TCSHubWelcomePlugin.GetPluginID: string;
begin
  Result := CSHubPluginID;
end;

function TCSHubWelcomePlugin.GetPluginName: string;
begin
  Result := CSHubPluginName;
end;

function TCSHubWelcomePlugin.GetPluginVisible: Boolean;
begin
  Result := True;
end;

function TCSHubWelcomePlugin.CreateView: TFrame;
var View: TCSHubClientFrame;
begin
  if FView = nil then
  begin
    View := TCSHubClientFrame.Create(nil, FModel);
    View.OnDestroyed := ViewDestroyed;
    FView := View;
  end;
  Result := FView;
end;

procedure TCSHubWelcomePlugin.ViewDestroyed(Sender: TObject);
begin
  // The Welcome Page freed the frame on its own (IDE shutdown): never free it again.
  if Sender = FView then FView := nil;
end;

function TCSHubWelcomePlugin.GetView: TFrame;
begin
  Result := FView;
end;

procedure TCSHubWelcomePlugin.DestroyView;
var View: TFrame;
begin
  View := FView;
  FView := nil;
  if View <> nil then
  begin
    (View as TCSHubClientFrame).OnDestroyed := nil;
    View.Free;
  end;
end;

function TCSHubWelcomePlugin.GetIcon: TGraphicArray;
begin
  Result := nil;
end;

function TCSHubWelcomePlugin.GetIconIndex: Integer;
begin
  Result := FIconIndex;
end;

procedure TCSHubWelcomePlugin.SetIconIndex(const Value: Integer);
begin
  FIconIndex := Value;
end;

end.
