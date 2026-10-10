# CS.Coder - Hub de Projetos 0.26.10.10b (Delphi 11, 12 and 13)

A Welcome Page panel that keeps Delphi projects one double-click away, organized in
categories and groups, with search, export/import and an interface in English, Portuguese,
Spanish, German and French.

Developer: CS.Coder. Open source under the MIT License (see `LICENSE.txt`).

## Building and packaging
- `build.bat [11|12|13|all]` compiles the packages into `bin\` (Win32) and `bin\Win64\`.
- `package.bat` builds everything and assembles `dist\`:
  - `CSCoderHubProjetos-<version>.zip`: manual install (`Install.bat`, `Uninstall.bat`, all `.bpl`).
  - `GetIt\D11`, `D12`, `D13`: one GetIt package per Delphi version (local JSON, zip, license, icon).

## Installing
End users: unzip `CSCoderHubProjetos-<version>.zip`, close Delphi, run `Install.bat`.
While developing: Component > Install Packages > Add, and pick the `.bpl` from `bin\`
(32-bit IDE) or `bin\Win64\` (64-bit IDE, Delphi 12 and 13).

## Configuration
`%LOCALAPPDATA%\CSCoder\Hub\<D11|D12|D13>\projects.json` (backups: `.bak`). Each Delphi version has its
own list. Only shortcut references are deleted by the Remove button; source files are never deleted.

## Compatibility
The same sources compile cleanly with Delphi 11.3, 12.3 and 13.1 (Win32, plus Win64 for 12 and 13).
Only Delphi 11 has been tested inside the IDE so far.

## First run
With no list yet, the panel starts with a loose group "Recent" holding up to 10 of the
projects the IDE lists as recent (newest first, only files that still exist). It is an
ordinary group: rename it, move its projects, delete it. Nothing is seeded once a list exists.

## Known limitations
- Recent projects are only read on the first run, not kept in sync with the IDE.
- Projects are listed alphabetically until one is moved inside its group (arrows, menu or drag and
  drop); "Sort by name" in the group menu goes back to alphabetical.
