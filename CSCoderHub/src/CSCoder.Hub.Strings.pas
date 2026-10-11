unit CSCoder.Hub.Strings;

interface

type
  TCSHubLang = (lgEnglish, lgPortuguese, lgSpanish, lgGerman, lgFrench);

  /// Every text the interface shows. To add one: a new id here and its row,
  /// in the same position, in the Texts table below.
  TCSHubStr = (
    // caption
    sTitle, sSearchHint, sHintAdd, sMenuAddSection, sMenuAddGroup, sHintConfig,
    sMenuExport, sMenuImportMerge, sMenuImportReplace, sMenuLanguage, sLangAuto,
    sSection1, sSectionN, sGroup1, sGroupN, sProject1, sProjectN,
    // list
    sGroupEmpty, sGroupEmptyLink, sSectionEmpty, sSectionEmptyLink, sNoGroups,
    sNotFound, sMissingFile,
    sHintAddGroupToSection, sHintAddProjects, sHintRenameSection, sHintRenameGroup,
    sHintDeleteSection, sHintDeleteGroup, sHintMore, sHintExpandSection,
    sHintCollapseSection, sHintExpandGroup, sHintCollapseGroup,
    // file dialogs
    sFilterProjects, sFilterAll, sFilterConfig,
    // projects
    sErrLoad, sErrSave, sErrFileNotFound, sErrNoService, sErrOpen,
    sMenuOpen, sMenuOpenFolder, sMenuMoveTo, sMenuRemoveShortcut,
    sAskRemoveShortcut, sAlreadyAdded,
    // groups
    sNewGroupTitle, sGroupNamePrompt, sGroupNameInSectionPrompt, sNewNamePrompt,
    sAskDeleteGroup, sMenuMoveToSection, sNoSection, sMenuRename, sMenuDelete,
    // sections ("Categoria" in the interface)
    sNewSectionTitle, sSectionNamePrompt, sAskDeleteEmptySection, sAskDeleteSection,
    sBtnKeepGroups, sBtnDeleteAll, sBtnCancel,
    // export / import
    sTitleExport, sTitleImport, sErrExport, sErrImport, sAskReplace, sImported,
    // repository
    sErrSectionName, sErrSectionExists, sErrGroupName, sErrGroupExists,
    sErrGroupExistsTarget, sErrProjectExists, sErrInvalidJson, sUngrouped,
    // ordering
    sMenuMoveUp, sMenuMoveDown,
    // header menus
    sMenuAddProjects,
    // settings menu
    sMenuCollapseAll, sMenuExpandAll,
    // project order
    sMenuSortByName,
    // about
    sHintAbout, sAboutBy, sAboutTagline, sAboutVersionLabel, sAboutBuild, sAboutCompat,
    sAboutDataFile, sAboutCopyPath, sAboutOpenFolder,
    sAboutLicFree, sAboutLicSub, sAboutLicType, sAboutLicTypeValue, sAboutLicCommercial,
    sAboutAllowed, sAboutLicRedist, sAboutUnmodified, sAboutLicData, sAboutNone,
    sAboutLicenseDetails, sAboutUpdates, sAboutCheckUpdates, sAboutLicenseTitle, sBtnClose,
    sFeatOrgTitle, sFeatOrgText, sFeatFastTitle, sFeatFastText, sFeatProdTitle, sFeatProdText,
    sFeatDelphiTitle, sFeatDelphiText,
    sAboutSlogan, sAboutSupport, sAboutRights,
    // refresh (another IDE of the same Delphi version shares the file)
    sHintRefresh, sChangedElsewhere,
    // import safety
    sImportEmpty,
    // icons of categories and groups
    sMenuIcon, sIconTitle, sIconNone, sIconLoad, sFilterImages, sErrIconLoad,
    // first run
    sRecentGroup, sFavoriteGroup);

const
  CSHubLangNames: array[TCSHubLang] of string = ('English', 'Português', 'Español', 'Deutsch', 'Français');

/// Text in the current language.
function L(AId: TCSHubStr): string; overload;
/// Same, run through Format.
function L(AId: TCSHubStr; const AArgs: array of const): string; overload;
/// '1 grupo' / '3 grupos'.
function CSHubCount(ACount: Integer; ASingular, APlural: TCSHubStr): string;

/// Language in use: the one the user picked, otherwise the one of Windows
/// (English when Windows is in a language we do not have).
function CSHubLanguage: TCSHubLang;
function CSHubLanguageIsAuto: Boolean;
/// Picks a language and remembers it (per Windows user, for every Delphi version).
procedure CSHubSetLanguage(ALang: TCSHubLang);
/// Back to following Windows.
procedure CSHubSetLanguageAuto;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Win.Registry;

const
  SettingsKey = 'Software\CSCoder\HubProjetos';
  LanguageValue = 'Language';
  Codes: array[TCSHubLang] of string = ('en', 'pt', 'es', 'de', 'fr');
  LB = sLineBreak;

  Texts: array[TCSHubStr, TCSHubLang] of string = (
    { sTitle } ('Project Hub', 'Hub de Projetos', 'Hub de Proyectos', 'Projekt-Hub', 'Hub de projets'),
    { sSearchHint } ('Search...', 'Pesquisar...', 'Buscar...', 'Suchen...', 'Rechercher...'),
    { sHintAdd } ('Add category or group', 'Adicionar categoria ou grupo', 'Añadir categoría o grupo',
      'Kategorie oder Gruppe hinzufügen', 'Ajouter une catégorie ou un groupe'),
    { sMenuAddSection } ('Add category...', 'Adicionar categoria...', 'Añadir categoría...',
      'Kategorie hinzufügen...', 'Ajouter une catégorie...'),
    { sMenuAddGroup } ('Add group...', 'Adicionar grupo...', 'Añadir grupo...', 'Gruppe hinzufügen...',
      'Ajouter un groupe...'),
    { sHintConfig } ('Settings', 'Configurações', 'Configuración', 'Einstellungen', 'Paramètres'),
    { sMenuExport } ('Export configuration...', 'Exportar configuração...', 'Exportar configuración...',
      'Konfiguration exportieren...', 'Exporter la configuration...'),
    { sMenuImportMerge } ('Import and merge...', 'Importar e mesclar...', 'Importar y combinar...',
      'Importieren und zusammenführen...', 'Importer et fusionner...'),
    { sMenuImportReplace } ('Import and replace everything...', 'Importar e substituir tudo...',
      'Importar y reemplazar todo...', 'Importieren und alles ersetzen...', 'Importer et tout remplacer...'),
    { sMenuLanguage } ('Language', 'Idioma', 'Idioma', 'Sprache', 'Langue'),
    { sLangAuto } ('Automatic (Windows)', 'Automático (Windows)', 'Automático (Windows)',
      'Automatisch (Windows)', 'Automatique (Windows)'),
    { sSection1 } ('category', 'categoria', 'categoría', 'Kategorie', 'catégorie'),
    { sSectionN } ('categories', 'categorias', 'categorías', 'Kategorien', 'catégories'),
    { sGroup1 } ('group', 'grupo', 'grupo', 'Gruppe', 'groupe'),
    { sGroupN } ('groups', 'grupos', 'grupos', 'Gruppen', 'groupes'),
    { sProject1 } ('project', 'projeto', 'proyecto', 'Projekt', 'projet'),
    { sProjectN } ('projects', 'projetos', 'proyectos', 'Projekte', 'projets'),

    { sGroupEmpty } ('No projects in this group.', 'Nenhum projeto neste grupo.',
      'No hay proyectos en este grupo.', 'Keine Projekte in dieser Gruppe.', 'Aucun projet dans ce groupe.'),
    { sGroupEmptyLink } ('+ Add first project', '+ Adicionar primeiro projeto', '+ Añadir el primer proyecto',
      '+ Erstes Projekt hinzufügen', '+ Ajouter le premier projet'),
    { sSectionEmpty } ('No groups in this category.', 'Nenhum grupo nesta categoria.',
      'No hay grupos en esta categoría.', 'Keine Gruppen in dieser Kategorie.', 'Aucun groupe dans cette catégorie.'),
    { sSectionEmptyLink } ('+ Add first group', '+ Adicionar primeiro grupo', '+ Añadir el primer grupo',
      '+ Erste Gruppe hinzufügen', '+ Ajouter le premier groupe'),
    { sNoGroups } ('No groups yet. Create the first one with the + button in the header.',
      'Nenhum grupo ainda. Crie o primeiro pelo botão + no cabeçalho.',
      'Aún no hay grupos. Crea el primero con el botón + del encabezado.',
      'Noch keine Gruppen. Erstellen Sie die erste mit der Schaltfläche + in der Kopfzeile.',
      'Aucun groupe pour le moment. Créez le premier avec le bouton + de l''en-tête.'),
    { sNotFound } ('No projects found.', 'Nenhum projeto encontrado.', 'No se encontraron proyectos.',
      'Keine Projekte gefunden.', 'Aucun projet trouvé.'),
    { sMissingFile } ('[missing file]', '[arquivo ausente]', '[archivo ausente]', '[Datei fehlt]',
      '[fichier manquant]'),
    { sHintAddGroupToSection } ('Add group to this category', 'Adicionar grupo a esta categoria',
      'Añadir grupo a esta categoría', 'Gruppe zu dieser Kategorie hinzufügen',
      'Ajouter un groupe à cette catégorie'),
    { sHintAddProjects } ('Add projects to this group', 'Adicionar projetos a este grupo',
      'Añadir proyectos a este grupo', 'Projekte zu dieser Gruppe hinzufügen', 'Ajouter des projets à ce groupe'),
    { sHintRenameSection } ('Rename category', 'Renomear categoria', 'Renombrar categoría',
      'Kategorie umbenennen', 'Renommer la catégorie'),
    { sHintRenameGroup } ('Rename group', 'Renomear grupo', 'Renombrar grupo', 'Gruppe umbenennen',
      'Renommer le groupe'),
    { sHintDeleteSection } ('Delete category', 'Excluir categoria', 'Eliminar categoría', 'Kategorie löschen',
      'Supprimer la catégorie'),
    { sHintDeleteGroup } ('Delete group', 'Excluir grupo', 'Eliminar grupo', 'Gruppe löschen',
      'Supprimer le groupe'),
    { sHintMore } ('More options', 'Mais opções', 'Más opciones', 'Weitere Optionen', 'Plus d''options'),
    { sHintExpandSection } ('Expand category', 'Expandir categoria', 'Expandir categoría',
      'Kategorie aufklappen', 'Développer la catégorie'),
    { sHintCollapseSection } ('Collapse category', 'Recolher categoria', 'Contraer categoría',
      'Kategorie zuklappen', 'Réduire la catégorie'),
    { sHintExpandGroup } ('Expand group', 'Expandir grupo', 'Expandir grupo', 'Gruppe aufklappen',
      'Développer le groupe'),
    { sHintCollapseGroup } ('Collapse group', 'Recolher grupo', 'Contraer grupo', 'Gruppe zuklappen',
      'Réduire le groupe'),

    { sFilterProjects } ('Delphi projects', 'Projetos Delphi', 'Proyectos Delphi', 'Delphi-Projekte',
      'Projets Delphi'),
    { sFilterAll } ('All files', 'Todos os arquivos', 'Todos los archivos', 'Alle Dateien', 'Tous les fichiers'),
    { sFilterConfig } ('Project Hub configuration', 'Configuração do Hub de Projetos',
      'Configuración del Hub de Proyectos', 'Projekt-Hub-Konfiguration', 'Configuration du Hub de projets'),

    { sErrLoad } ('Could not load the shortcuts: %s', 'Não foi possível carregar os atalhos: %s',
      'No se pudieron cargar los accesos directos: %s', 'Die Verknüpfungen konnten nicht geladen werden: %s',
      'Impossible de charger les raccourcis : %s'),
    { sErrSave } ('Could not save the shortcuts: %s', 'Não foi possível gravar os atalhos: %s',
      'No se pudieron guardar los accesos directos: %s',
      'Die Verknüpfungen konnten nicht gespeichert werden: %s', 'Impossible d''enregistrer les raccourcis : %s'),
    { sErrFileNotFound } ('File not found: %s', 'Arquivo não encontrado: %s', 'Archivo no encontrado: %s',
      'Datei nicht gefunden: %s', 'Fichier introuvable : %s'),
    { sErrNoService } ('The IDE service IOTAActionServices is not available.',
      'Serviço IOTAActionServices indisponível.', 'El servicio IOTAActionServices no está disponible.',
      'Der IDE-Dienst IOTAActionServices ist nicht verfügbar.',
      'Le service IOTAActionServices n''est pas disponible.'),
    { sErrOpen } ('Could not open: %s', 'Não foi possível abrir: %s', 'No se pudo abrir: %s',
      'Konnte nicht geöffnet werden: %s', 'Impossible d''ouvrir : %s'),
    { sMenuOpen } ('Open', 'Abrir', 'Abrir', 'Öffnen', 'Ouvrir'),
    { sMenuOpenFolder } ('Open folder in Explorer', 'Abrir pasta no Explorer', 'Abrir carpeta en el Explorador',
      'Ordner im Explorer öffnen', 'Ouvrir le dossier dans l''Explorateur'),
    { sMenuMoveTo } ('Move to', 'Mover para', 'Mover a', 'Verschieben nach', 'Déplacer vers'),
    { sMenuRemoveShortcut } ('Remove shortcut', 'Remover atalho', 'Quitar acceso directo',
      'Verknüpfung entfernen', 'Supprimer le raccourci'),
    { sAskRemoveShortcut } ('Remove the shortcut to %s? The original file will not be deleted.',
      'Remover o atalho de %s? O arquivo original não será apagado.',
      '¿Quitar el acceso directo a %s? El archivo original no se eliminará.',
      'Verknüpfung zu %s entfernen? Die Originaldatei wird nicht gelöscht.',
      'Supprimer le raccourci vers %s ? Le fichier d''origine ne sera pas supprimé.'),
    { sAlreadyAdded } ('Already registered:', 'Já estavam cadastrados:', 'Ya estaban registrados:',
      'Bereits vorhanden:', 'Déjà enregistrés :'),

    { sNewGroupTitle } ('New group', 'Novo grupo', 'Nuevo grupo', 'Neue Gruppe', 'Nouveau groupe'),
    { sGroupNamePrompt } ('Group name:', 'Nome do grupo:', 'Nombre del grupo:', 'Name der Gruppe:',
      'Nom du groupe :'),
    { sGroupNameInSectionPrompt } ('Group name in category "%s":', 'Nome do grupo na categoria "%s":',
      'Nombre del grupo en la categoría "%s":', 'Name der Gruppe in der Kategorie "%s":',
      'Nom du groupe dans la catégorie "%s" :'),
    { sNewNamePrompt } ('New name:', 'Novo nome:', 'Nuevo nombre:', 'Neuer Name:', 'Nouveau nom :'),
    { sAskDeleteGroup } (
      'Delete the group "%s" and all its shortcuts?' + LB + 'The project files will not be deleted.',
      'Excluir o grupo "%s" e todos os atalhos dele?' + LB + 'Os arquivos dos projetos não serão apagados.',
      '¿Eliminar el grupo "%s" y todos sus accesos directos?' + LB + 'Los archivos de los proyectos no se eliminarán.',
      'Die Gruppe "%s" und alle ihre Verknüpfungen löschen?' + LB + 'Die Projektdateien werden nicht gelöscht.',
      'Supprimer le groupe "%s" et tous ses raccourcis ?' + LB + 'Les fichiers des projets ne seront pas supprimés.'),
    { sMenuMoveToSection } ('Move to category', 'Mover para a categoria', 'Mover a la categoría',
      'In Kategorie verschieben', 'Déplacer vers la catégorie'),
    { sNoSection } ('(No category)', '(Sem categoria)', '(Sin categoría)', '(Ohne Kategorie)', '(Sans catégorie)'),
    { sMenuRename } ('Rename...', 'Renomear...', 'Renombrar...', 'Umbenennen...', 'Renommer...'),
    { sMenuDelete } ('Delete', 'Excluir', 'Eliminar', 'Löschen', 'Supprimer'),

    { sNewSectionTitle } ('New category', 'Nova categoria', 'Nueva categoría', 'Neue Kategorie',
      'Nouvelle catégorie'),
    { sSectionNamePrompt } ('Category name:', 'Nome da categoria:', 'Nombre de la categoría:',
      'Name der Kategorie:', 'Nom de la catégorie :'),
    { sAskDeleteEmptySection } ('Delete the category "%s"?', 'Excluir a categoria "%s"?',
      '¿Eliminar la categoría "%s"?', 'Die Kategorie "%s" löschen?', 'Supprimer la catégorie "%s" ?'),
    { sAskDeleteSection } (
      'The category "%s" has groups. What should happen to them?' + LB + 'Project files are never deleted.',
      'A categoria "%s" tem grupos. O que fazer com eles?' + LB + 'Os arquivos dos projetos nunca são apagados.',
      'La categoría "%s" tiene grupos. ¿Qué hacer con ellos?' + LB + 'Los archivos de los proyectos nunca se eliminan.',
      'Die Kategorie "%s" enthält Gruppen. Was soll mit ihnen geschehen?' + LB + 'Projektdateien werden nie gelöscht.',
      'La catégorie "%s" contient des groupes. Que faire d''eux ?' + LB + 'Les fichiers des projets ne sont jamais supprimés.'),
    { sBtnKeepGroups } ('Keep groups', 'Manter grupos', 'Conservar grupos', 'Gruppen behalten',
      'Garder les groupes'),
    { sBtnDeleteAll } ('Delete everything', 'Excluir tudo', 'Eliminar todo', 'Alles löschen', 'Tout supprimer'),
    { sBtnCancel } ('Cancel', 'Cancelar', 'Cancelar', 'Abbrechen', 'Annuler'),

    { sTitleExport } ('Export configuration', 'Exportar configuração', 'Exportar configuración',
      'Konfiguration exportieren', 'Exporter la configuration'),
    { sTitleImport } ('Import configuration', 'Importar configuração', 'Importar configuración',
      'Konfiguration importieren', 'Importer la configuration'),
    { sErrExport } ('Could not export: %s', 'Não foi possível exportar: %s', 'No se pudo exportar: %s',
      'Export fehlgeschlagen: %s', 'Impossible d''exporter : %s'),
    { sErrImport } ('Could not import: %s', 'Não foi possível importar: %s', 'No se pudo importar: %s',
      'Import fehlgeschlagen: %s', 'Impossible d''importer : %s'),
    { sAskReplace } (
      'Replace all current categories, groups and shortcuts with the ones in the file?' + LB +
        'The current configuration is kept in projects.json.bak.',
      'Substituir todas as categorias, grupos e atalhos atuais pelos do arquivo?' + LB +
        'A configuração atual fica guardada em projects.json.bak.',
      '¿Reemplazar todas las categorías, grupos y accesos directos actuales por los del archivo?' + LB +
        'La configuración actual se guarda en projects.json.bak.',
      'Alle aktuellen Kategorien, Gruppen und Verknüpfungen durch die der Datei ersetzen?' + LB +
        'Die aktuelle Konfiguration bleibt in projects.json.bak erhalten.',
      'Remplacer toutes les catégories, groupes et raccourcis actuels par ceux du fichier ?' + LB +
        'La configuration actuelle est conservée dans projects.json.bak.'),
    { sImported } ('%d new shortcut(s) imported.', '%d atalho(s) novo(s) importado(s).',
      '%d acceso(s) directo(s) nuevo(s) importado(s).', '%d neue Verknüpfung(en) importiert.',
      '%d nouveau(x) raccourci(s) importé(s).'),

    { sErrSectionName } ('Enter the category name.', 'Informe o nome da categoria.',
      'Indique el nombre de la categoría.', 'Geben Sie den Namen der Kategorie ein.',
      'Indiquez le nom de la catégorie.'),
    { sErrSectionExists } ('A category with this name already exists.', 'Já existe uma categoria com este nome.',
      'Ya existe una categoría con este nombre.', 'Eine Kategorie mit diesem Namen existiert bereits.',
      'Une catégorie portant ce nom existe déjà.'),
    { sErrGroupName } ('Enter the group name.', 'Informe o nome do grupo.', 'Indique el nombre del grupo.',
      'Geben Sie den Namen der Gruppe ein.', 'Indiquez le nom du groupe.'),
    { sErrGroupExists } ('A group with this name already exists.', 'Já existe um grupo com este nome.',
      'Ya existe un grupo con este nombre.', 'Eine Gruppe mit diesem Namen existiert bereits.',
      'Un groupe portant ce nom existe déjà.'),
    { sErrGroupExistsTarget } ('A group with this name already exists at the destination.',
      'Já existe um grupo com este nome no destino.', 'Ya existe un grupo con este nombre en el destino.',
      'Am Ziel existiert bereits eine Gruppe mit diesem Namen.',
      'Un groupe portant ce nom existe déjà à la destination.'),
    { sErrProjectExists } ('This project is already registered.', 'Este projeto já está cadastrado.',
      'Este proyecto ya está registrado.', 'Dieses Projekt ist bereits vorhanden.',
      'Ce projet est déjà enregistré.'),
    { sErrInvalidJson } ('Invalid JSON file: %s', 'Arquivo JSON inválido: %s', 'Archivo JSON no válido: %s',
      'Ungültige JSON-Datei: %s', 'Fichier JSON non valide : %s'),
    { sUngrouped } ('Ungrouped', 'Sem grupo', 'Sin grupo', 'Ohne Gruppe', 'Sans groupe'),

    { sMenuMoveUp } ('Move up', 'Mover para cima', 'Mover hacia arriba', 'Nach oben', 'Monter'),
    { sMenuMoveDown } ('Move down', 'Mover para baixo', 'Mover hacia abajo', 'Nach unten', 'Descendre'),

    { sMenuAddProjects } ('Add projects...', 'Adicionar projetos...', 'Añadir proyectos...',
      'Projekte hinzufügen...', 'Ajouter des projets...'),

    { sMenuCollapseAll } ('Collapse all', 'Recolher tudo', 'Contraer todo', 'Alle zuklappen', 'Tout réduire'),
    { sMenuExpandAll } ('Expand all', 'Expandir tudo', 'Expandir todo', 'Alle aufklappen', 'Tout développer'),

    { sMenuSortByName } ('Sort by name', 'Ordenar por nome', 'Ordenar por nombre', 'Nach Name sortieren',
      'Trier par nom'),

    { sHintAbout } ('About', 'Sobre', 'Acerca de', 'Info', 'À propos'),
    { sAboutBy } ('by', 'por', 'por', 'von', 'par'),
    { sAboutTagline } ('Organize, open and manage your Delphi projects quickly and productively.',
      'Organize, acesse e gerencie seus projetos Delphi de forma rápida e produtiva.',
      'Organice, abra y gestione sus proyectos Delphi de forma rápida y productiva.',
      'Organisieren, öffnen und verwalten Sie Ihre Delphi-Projekte schnell und produktiv.',
      'Organisez, ouvrez et gérez vos projets Delphi rapidement et efficacement.'),
    { sAboutVersionLabel } ('Version', 'Versão', 'Versión', 'Version', 'Version'),
    { sAboutBuild } ('Build', 'Build', 'Compilación', 'Build', 'Build'),
    { sAboutCompat } ('Compatibility', 'Compatibilidade', 'Compatibilidad', 'Kompatibilität', 'Compatibilité'),
    { sAboutDataFile } ('Shortcuts file', 'Arquivo de atalhos', 'Archivo de accesos', 'Verknüpfungsdatei',
      'Fichier des raccourcis'),
    { sAboutCopyPath } ('Copy path', 'Copiar caminho', 'Copiar ruta', 'Pfad kopieren', 'Copier le chemin'),
    { sAboutOpenFolder } ('Open folder', 'Abrir pasta', 'Abrir carpeta', 'Ordner öffnen', 'Ouvrir le dossier'),

    { sAboutLicFree } ('Open source', 'Código aberto', 'Código abierto', 'Open Source', 'Code ouvert'),
    { sAboutLicSub } ('Free to use, change and share', 'Livre para usar, alterar e compartilhar',
      'Libre para usar, modificar y compartir', 'Frei zum Nutzen, Ändern und Weitergeben',
      'Libre d''utiliser, de modifier et de partager'),
    { sAboutLicType } ('License type', 'Tipo de licença', 'Tipo de licencia', 'Lizenztyp', 'Type de licence'),
    { sAboutLicTypeValue } ('MIT License', 'Licença MIT', 'Licencia MIT', 'MIT-Lizenz', 'Licence MIT'),
    { sAboutLicCommercial } ('Commercial use', 'Uso comercial', 'Uso comercial', 'Kommerzielle Nutzung',
      'Usage commercial'),
    { sAboutAllowed } ('Allowed', 'Permitido', 'Permitido', 'Erlaubt', 'Autorisé'),
    { sAboutLicRedist } ('Source code', 'Código-fonte', 'Código fuente', 'Quellcode', 'Code source'),
    { sAboutUnmodified } ('Open, may be changed', 'Aberto, pode modificar', 'Abierto, modificable',
      'Offen, veränderbar', 'Ouvert, modifiable'),
    { sAboutLicData } ('Data collection', 'Coleta de dados', 'Recopilación de datos', 'Datenerfassung',
      'Collecte de données'),
    { sAboutNone } ('None', 'Nenhuma', 'Ninguna', 'Keine', 'Aucune'),
    { sAboutLicenseDetails } ('License details', 'Detalhes da licença', 'Detalles de la licencia',
      'Lizenzdetails', 'Détails de la licence'),
    { sAboutUpdates } ('Updates', 'Atualizações', 'Actualizaciones', 'Updates', 'Mises à jour'),
    { sAboutCheckUpdates } ('Check for updates', 'Verificar atualizações', 'Buscar actualizaciones',
      'Nach Updates suchen', 'Rechercher des mises à jour'),
    { sAboutLicenseTitle } ('License', 'Licença', 'Licencia', 'Lizenz', 'Licence'),
    { sBtnClose } ('Close', 'Fechar', 'Cerrar', 'Schließen', 'Fermer'),

    { sFeatOrgTitle } ('Smart organization', 'Organização inteligente', 'Organización inteligente',
      'Clevere Ordnung', 'Organisation intelligente'),
    { sFeatOrgText } ('Categories and groups', 'Categorias e grupos', 'Categorías y grupos',
      'Kategorien und Gruppen', 'Catégories et groupes'),
    { sFeatFastTitle } ('Quick access', 'Acesso rápido', 'Acceso rápido', 'Schneller Zugriff', 'Accès rapide'),
    { sFeatFastText } ('Search and double-click', 'Busca e duplo clique', 'Búsqueda y doble clic',
      'Suche und Doppelklick', 'Recherche et double-clic'),
    { sFeatProdTitle } ('Productivity', 'Produtividade', 'Productividad', 'Produktivität', 'Productivité'),
    { sFeatProdText } ('More focus on your work', 'Mais foco no seu trabalho', 'Más foco en su trabajo',
      'Mehr Fokus auf Ihre Arbeit', 'Plus de concentration sur votre travail'),
    { sFeatDelphiTitle } ('Made for Delphi', 'Feito para Delphi', 'Hecho para Delphi', 'Für Delphi gemacht',
      'Conçu pour Delphi'),
    { sFeatDelphiText } ('Part of your Welcome Page', 'Integrado à Welcome Page', 'Integrado en la Welcome Page',
      'Teil Ihrer Welcome Page', 'Intégré à la Welcome Page'),

    { sAboutSlogan } ('Code with PURPOSE. Solutions with INTELLIGENCE.',
      'Código com PROPÓSITO. Soluções com INTELIGÊNCIA.',
      'Código con PROPÓSITO. Soluciones con INTELIGENCIA.',
      'Code mit SINN. Lösungen mit INTELLIGENZ.',
      'Du code avec un BUT. Des solutions avec INTELLIGENCE.'),
    { sAboutSupport } ('Support and documentation', 'Suporte e documentação', 'Soporte y documentación',
      'Support und Dokumentation', 'Support et documentation'),
    { sAboutRights } ('%s is a product of %s.' + LB + 'Open source under the MIT License.',
      '%s é um produto da %s.' + LB + 'Código aberto sob a licença MIT.',
      '%s es un producto de %s.' + LB + 'Código abierto bajo la licencia MIT.',
      '%s ist ein Produkt von %s.' + LB + 'Open Source unter der MIT-Lizenz.',
      '%s est un produit de %s.' + LB + 'Code ouvert sous licence MIT.'),

    { sHintRefresh } ('Refresh', 'Atualizar', 'Actualizar', 'Aktualisieren', 'Actualiser'),
    { sChangedElsewhere } (
      'Another Delphi window changed the list and this item no longer exists.' + LB +
        'The list was refreshed; nothing was changed.',
      'Outra janela do Delphi alterou a lista e este item não existe mais.' + LB +
        'A lista foi atualizada; nada foi alterado.',
      'Otra ventana de Delphi cambió la lista y este elemento ya no existe.' + LB +
        'La lista se actualizó; no se cambió nada.',
      'Ein anderes Delphi-Fenster hat die Liste geändert, und dieses Element existiert nicht mehr.' + LB +
        'Die Liste wurde aktualisiert; es wurde nichts geändert.',
      'Une autre fenêtre de Delphi a modifié la liste et cet élément n''existe plus.' + LB +
        'La liste a été actualisée ; rien n''a été modifié.'),

    { sImportEmpty } (
      'The file has no categories, groups or shortcuts.' + LB + 'Nothing was imported; your list was not changed.',
      'O arquivo não tem categorias, grupos nem atalhos.' + LB + 'Nada foi importado; a sua lista não foi alterada.',
      'El archivo no tiene categorías, grupos ni accesos directos.' + LB +
        'No se importó nada; su lista no se modificó.',
      'Die Datei enthält keine Kategorien, Gruppen oder Verknüpfungen.' + LB +
        'Es wurde nichts importiert; Ihre Liste wurde nicht geändert.',
      'Le fichier ne contient ni catégories, ni groupes, ni raccourcis.' + LB +
        'Rien n''a été importé ; votre liste n''a pas été modifiée.'),

    { sMenuIcon } ('Icon...', 'Ícone...', 'Icono...', 'Symbol...', 'Icône...'),
    { sIconTitle } ('Choose icon', 'Escolher ícone', 'Elegir icono', 'Symbol auswählen', 'Choisir une icône'),
    { sIconNone } ('No icon', 'Sem ícone', 'Sin icono', 'Kein Symbol', 'Aucune icône'),
    { sIconLoad } ('Load image...', 'Carregar imagem...', 'Cargar imagen...', 'Bild laden...',
      'Charger une image...'),
    { sFilterImages } ('Images', 'Imagens', 'Imágenes', 'Bilder', 'Images'),
    { sErrIconLoad } ('Could not use this image: %s', 'Não foi possível usar esta imagem: %s',
      'No se pudo usar esta imagen: %s', 'Dieses Bild konnte nicht verwendet werden: %s',
      'Impossible d''utiliser cette image : %s'),

    { sRecentGroup } ('Recent', 'Recentes', 'Recientes', 'Zuletzt verwendet', 'Récents'),
    { sFavoriteGroup } ('Favorites', 'Favoritos', 'Favoritos', 'Favoriten', 'Favoris')
  );

var
  Current: TCSHubLang;
  IsAuto: Boolean;

function WindowsLanguage: TCSHubLang;
begin
  case GetUserDefaultUILanguage and $3FF of // primary language id
    $16: Result := lgPortuguese;
    $0A: Result := lgSpanish;
    $07: Result := lgGerman;
    $0C: Result := lgFrench;
  else
    Result := lgEnglish;
  end;
end;

procedure LoadLanguage;
var Reg: TRegistry;
    Code: string;
    Lang: TCSHubLang;
begin
  Current := WindowsLanguage;
  IsAuto := True;
  try
    Reg := TRegistry.Create(KEY_READ);
    try
      if not Reg.OpenKeyReadOnly(SettingsKey) or not Reg.ValueExists(LanguageValue) then Exit;
      Code := LowerCase(Reg.ReadString(LanguageValue));
    finally
      Reg.Free;
    end;
  except
    Exit; // an unreadable setting just means "automatic"
  end;
  for Lang := Low(TCSHubLang) to High(TCSHubLang) do
    if Codes[Lang] = Code then
    begin
      Current := Lang;
      IsAuto := False;
    end;
end;

procedure SaveLanguage(const ACode: string);
var Reg: TRegistry;
begin
  try
    Reg := TRegistry.Create;
    try
      if Reg.OpenKey(SettingsKey, True) then
        if ACode = '' then Reg.DeleteValue(LanguageValue) else Reg.WriteString(LanguageValue, ACode);
    finally
      Reg.Free;
    end;
  except
    // not remembered; the choice still holds for this session
  end;
end;

function L(AId: TCSHubStr): string;
begin
  Result := Texts[AId, Current];
end;

function L(AId: TCSHubStr; const AArgs: array of const): string;
begin
  Result := Format(Texts[AId, Current], AArgs);
end;

function CSHubCount(ACount: Integer; ASingular, APlural: TCSHubStr): string;
begin
  if ACount = 1 then Result := '1 ' + L(ASingular) else Result := IntToStr(ACount) + ' ' + L(APlural);
end;

function CSHubLanguage: TCSHubLang;
begin
  Result := Current;
end;

function CSHubLanguageIsAuto: Boolean;
begin
  Result := IsAuto;
end;

procedure CSHubSetLanguage(ALang: TCSHubLang);
begin
  Current := ALang;
  IsAuto := False;
  SaveLanguage(Codes[ALang]);
end;

procedure CSHubSetLanguageAuto;
begin
  Current := WindowsLanguage;
  IsAuto := True;
  SaveLanguage('');
end;

initialization
  LoadLanguage;

end.
