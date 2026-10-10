# CS.Coder - Hub de Projetos (Delphi Project Hub)

**English** | [Português (Brasil)](README.pt-BR.md)

A Welcome Page panel for Delphi 11, 12 and 13 that keeps your projects one double-click
away, organized in categories and groups, with icons, search, drag and drop and
export/import. Free and open source under the [MIT License](LICENSE), by
[CS.Coder](https://www.cscoder.com.br).

![The panel in the dark theme](docs/images/list-dark.png)

## Why

The IDE's "Open Recent" list is flat and forgets things: the project you need is always
the one that fell off the end. The Hub replaces it with a list that you organize yourself
and that never changes unless you change it: by client, by system, by what you are working
on this month. It lives inside the Welcome Page, drawn in the same style as the built-in
panels, so it looks like it came with Delphi.

## Features

- **Categories and groups.** Two levels: a category holds groups, a group holds project
  shortcuts. Categories are optional; a group can stand on its own.
- **Icons.** Any category or group can have an icon: one of 56 from the built-in library,
  drawn in the text color of the theme, or an image of your own (PNG, ICO, JPG, BMP or GIF),
  reduced and stored by the plugin. Without an icon, the line looks exactly as before.
- **Search.** Type and the list shows only the projects whose name or path match, with
  their groups.
- **Your order.** Drag and drop projects, groups and categories, or use the arrows. Projects
  come alphabetically until you move one; "Sort by name" takes a group back.
- **Collapse and expand.** Each category and group remembers its state; one button in the
  header opens or closes everything.
- **Export and import.** The whole list as a JSON file, with your own icon images embedded,
  to carry it to another Delphi or keep a backup. Import can merge (adds what is missing)
  or replace everything.
- **One list per Delphi version.** Delphi 11, 12 and 13 each keep their own list; the
  32-bit and 64-bit IDEs of the same version share it.
- **Two IDEs open at once.** A refresh button rereads the list, and every change rereads
  the file first, so two windows of the same Delphi never overwrite each other.
- **Five languages.** English, Portuguese, Spanish, German and French, following Windows
  or chosen in the settings menu.
- **Light and dark.** Every color comes from the IDE theme; switching themes redraws the
  panel.
- **A useful first run.** With no list yet, the panel starts with a "Recent" group
  holding the projects the IDE itself lists as recent, ready to be dragged into categories.
- **Your data stays yours.** The list is a JSON file on your computer. Nothing is collected
  or sent anywhere.

| Light theme | Choosing an icon |
|---|---|
| ![Light theme](docs/images/list-light.png) | ![Icon picker](docs/images/icon-picker-dark.png) |

## Install

1. Download `CSCoderHubProjetos-<version>.zip` from `CSCoderHub/dist/` (or from Releases)
   and unzip it.
2. Close Delphi and run `Install.bat`. It installs for every supported Delphi found for the
   current Windows user, with no administrator rights.
3. Open Delphi. If the panel is not on the Welcome Page, click **Edit Layout** and place
   "CS.Coder - Hub de Projetos" on the grid.

`Uninstall.bat` removes it and keeps your list; `Uninstall.bat /data` deletes the list too.

## Build from source

`CSCoderHub/build.bat [11|12|13|all]` compiles the packages with the command-line compilers
of each Delphi (edit the three install paths at the top of the file for your machine);
`CSCoderHub/package.bat` also assembles `dist/`. There is no `.dproj`: one `.dpk` per
Delphi version, all sharing the same units. Details, the data file format and known
limitations are in [CSCoderHub/README.md](CSCoderHub/README.md).

## Repository layout

- `CSCoderHub/src/` - the plugin sources (`CSCoder.Hub.*` units)
- `CSCoderHub/packages/` - one `.dpk` per Delphi version
- `CSCoderHub/installer/` - the per-user install / uninstall scripts shipped in the zip
- `CSCoderHub/dist/` - ready-made packages (manual install zip and GetIt packages)
- `docs/` - images used by this page

## How it was made

The Hub was born from a personal annoyance: the favorite projects were never at hand on the
Welcome Page. The recent list showed what was opened last, not what matters, and the right
project meant browsing folders every time. The fix was to build the panel that was
missing, in the place where it was missing.

It was built in a day, on October 9, 2026, by CS.Coder in conversation with Claude Code
(Anthropic's coding assistant). The product decisions, the visual design, every
measurement, the testing inside the IDE and the approval of each screen are the author's;
most of the code was written by the assistant and verified with test programs outside the
IDE before each delivery. It is the CS.Coder motto in practice: **code with purpose,
solutions with intelligence**.

## Support

Issues and suggestions: open an issue here. Contact: contato@cscoder.com.br.

"Delphi" and "RAD Studio" are trademarks of Embarcadero Technologies, Inc. CS.Coder is not
affiliated with Embarcadero.
