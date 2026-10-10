unit CSCoder.Hub.Register;

interface

procedure Register;

implementation

uses ToolsAPI.WelcomePage, CSCoder.Hub.WelcomePlugin;

procedure Register;
begin
  if Assigned(WelcomePagePluginService) then
    WelcomePagePluginService.RegisterPluginCreator(TCSHubWelcomePlugin.Create);
end;

initialization

finalization
  if Assigned(WelcomePagePluginService) then
    WelcomePagePluginService.UnRegisterPlugin(CSHubPluginID);

end.
