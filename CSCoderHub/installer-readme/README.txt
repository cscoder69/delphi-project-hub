CS.Coder - Hub de Projetos
==========================

A panel for the Delphi Welcome Page that keeps your projects one double-click
away, organized in categories and groups.

Works with Delphi 11, 12 and 13 (32-bit IDE, and the 64-bit IDE of 12 and 13).


INSTALL
  1. Close Delphi.
  2. Double-click Install.bat.
  3. Open Delphi. If the panel is not on the Welcome Page, click Edit Layout
     and place "CS.Coder - Hub de Projetos" on the grid.

  It installs for every supported Delphi found on this Windows user, with no
  administrator rights. Running Install.bat again updates to the version in
  this folder.

UNINSTALL
  1. Close Delphi.
  2. Double-click Uninstall.bat.

  Your shortcut list is kept. To delete it as well, run:  Uninstall.bat /data

WHERE THINGS ARE
  Packages:        %LOCALAPPDATA%\CSCoder\Hub\bin
  Shortcut list:   %LOCALAPPDATA%\CSCoder\Hub\D11\projects.json  (D12, D13 for
                   the other versions). Each Delphi keeps its own list; use
                   gear button > Export / Import to copy a list from one
                   Delphi to another. A .bak copy is kept on every change.
  Settings:        %LOCALAPPDATA%\CSCoder\Hub\settings.json  (the language).
                   No setting is kept in the Windows registry.

LANGUAGE
  English, Portuguese, Spanish, German and French. The panel follows the
  language of Windows; to pick another, use the gear button > Language.

LICENSE
  Open source, MIT License. See LICENSE.txt.
