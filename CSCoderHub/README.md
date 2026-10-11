# CS.Coder Project Hub 0.26.10.10e: technical reference

This is the reference for building, packaging and the data format. For what the extension
does and how to install and use it, see the [main README](../README.md)
([Português](../README.pt-BR.md)).

Inside the IDE and in file names the product keeps its original name, "CS.Coder - Hub de
Projetos". Developer: CS.Coder. Open source under the MIT License (see `LICENSE.txt`).

## Building and packaging

- `build.bat [11|12|13|all]` compiles the packages into `bin\` (Win32) and `bin\Win64\`
  (Win64, Delphi 12 and 13). The Delphi installation paths are at the top of the file.
- `package.bat` builds everything and assembles `dist\`:
  - `CSCoderHubProjetos-<version>.zip`: manual install (`Install.bat`, `Uninstall.bat`,
    `HubSetup.ps1`, license, readme and every `.bpl`).
  - `GetIt\D11`, `D12`, `D13`: one package per Delphi version in the GetIt local-file
    format (JSON, zip, license, icon).
- There is no `.dproj`. `packages\` has one `.dpk` per Delphi version, all with the same
  units, and `CSCoder.HubProjetos.rc`, the shared version resource. `build.bat` generates
  the `.res` files.
- The version is set in two places that must agree: `$Version` in `package.ps1` and the
  four version entries of `CSCoder.HubProjetos.rc`.

## Installing

- End users: the zip, `Install.bat`. Steps are in the main README.
- While developing: **Component > Install Packages > Add**, and pick the `.bpl` from `bin\`
  (32-bit IDE) or `bin\Win64\` (64-bit IDE, Delphi 12 and 13). A `.bpl` built for one
  Delphi version does not load in another.

`HubSetup.ps1` works per Windows user, with no administrator rights. It copies the
packages to `%LOCALAPPDATA%\CSCoder\Hub\bin\<D11|D12|D13>\<Win32|Win64>` and registers
them under `HKCU\Software\Embarcadero\BDS\<22.0|23.0|37.0>\Known Packages` (and `Known
Packages x64`). It first removes any earlier registration of the package. It refuses to
run while Delphi is open, because the IDE rewrites that list when it closes.

## Compatibility

The same sources compile with Delphi 11.3, 12.3 and 13.1 (Win32 for all three, plus Win64
for 12 and 13), with no version-specific code. The author has used the extension inside
the IDE of the three versions. Most of the detailed testing was done in Delphi 11.

## Data

### Files

| What | Where |
|---|---|
| The list | `%LOCALAPPDATA%\CSCoder\Hub\D11\projects.json` (and `D12`, `D13`) |
| Previous version of the list | `projects.json.bak`, in the same folder |
| Icon images loaded by the user | `icons\`, in the same folder |
| Language choice | `HKCU\Software\CSCoder\HubProjetos`, value `Language` |

Each Delphi version has its own list. The 32-bit and 64-bit IDEs of the same version share
it. The list is written to a temporary file and then swapped in, keeping the `.bak`.

### Format

```json
{
  "version": 2,
  "groups": [],
  "sections": [
    { "name": "Clients", "collapsed": false, "icon": "company", "groups": [] }
  ],
  "order": [ { "section": "Clients" }, { "group": "Studies" } ]
}
```

A group, whether at the root (`groups`) or inside a section:

```json
{
  "name": "ERP",
  "collapsed": false,
  "manualOrder": true,
  "icon": "code",
  "projects": [ { "name": "Sales", "file": "C:\\Projects\\Sales\\Sales.dproj" } ]
}
```

- A "section" is what the interface calls a category. The root `groups` are the groups
  that belong to no category.
- `order` is the sequence of the top level, where loose groups and categories mix.
- `manualOrder` is written only when true. Without it the projects are shown by name.
- `icon` is optional: a library id, or `file:<name>.png` for an image in the `icons`
  folder. An unknown id, or an image that is not found, is shown as no icon.
- An exported file has one more key, `icons`, with the loaded images in base64.
- Keys are only ever added. A file written by an earlier version still opens.

### What deletes what

Removing a shortcut, a group or a category changes only `projects.json`. The sources have
no call that deletes, moves or renames a project file.

## First run

With no list yet, the panel starts with up to two loose groups, read from the IDE's own
lists in the registry (`HKCU\Software\Embarcadero\BDS\<version>`):

- "Favorites": every project under `Favorite Projects`, in the IDE's order. The group is
  not created when the IDE has no favorites.
- "Recent": up to 10 of the projects under `Closed Projects`, newest first, leaving out
  the ones already in "Favorites".

Only `.dproj`, `.groupproj` and `.dpr` files that still exist are taken. They are ordinary
groups: rename them, move their projects, delete them. Nothing is seeded once a list
exists, and the IDE's own lists are only read.

The `Favorite Projects` key was observed in Delphi 13. Where an IDE does not have it,
only "Recent" is created, as in earlier versions of the Hub.

## Known limitations

- Favorite and recent projects are only read on the first run, not kept in sync with the
  IDE.
- With two IDEs of the same version open, the other window shows a change only after its
  Refresh button is used or after its own next change.
- The list has no keyboard navigation.
- Shortcuts store full paths, so a list imported on another computer needs the projects in
  the same locations.
- Opening a `.dpk` of this repository in the IDE makes the IDE create a `.dproj` and
  rewrite the `.dpk`. Build with `build.bat` instead.
