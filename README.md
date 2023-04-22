# Deploy-NFONCloudya.ps1
* Version: 1.2.0 *

Dieses Skript versucht, die neueste Version von Cloudya Desktop by NFON von der offiziellen Website zu installieren. Es bietet darüber hinaus einige erweiterte Konfigurationseinstellungen für die Verteilung innerhalb von Firmennetzwerken, da der native Installer von NFON dies nicht bietet.

## Hinweis

Bitte beachten Sie, dass die Verwendung dieses Powershell-Skripts auf eigene Gefahr erfolgt. Das Skript befindet sich noch in der Entwicklung und kann daher Fehler enthalten. Bitte prüfen und testen Sie das Skript sorgfältig, bevor Sie es in einer produktiven Umgebung verwenden. 

Der Autor übernimmt keine Verantwortung für Schäden oder Verluste, die durch die Verwendung des Skripts entstehen könnten.

## Installation

1. Laden Sie das Skript herunter und speichern Sie es in einem beliebigen Verzeichnis auf Ihrem Computer.
2. Starten Sie es in einer administrativen Powershell-Session mit den notwendigen Parametern.

## Verwendung

```powershell
.\Deploy-NFONCloudya.ps1 -Action {Install, Detect, Update, Uninstall} [-EnableCRM] [-Autostart] [-DisableUpdateCheck]
```

## Parameter

| Parameter                                     | Verwendung                                                   |
| --------------------------------------------- | ------------------------------------------------------------ |
| `Action {Install, Detect, Update, Uninstall}` | Sagt dem Script, welche Aktion ausgeführt werden soll:<br />Install → Installieren<br />Detect → Aktuelle Version anzeigen<br />Update → Neuste Version installieren, sofern vorhanden<br />Uninstall → Software entfernen |
| `EnableCRM`                                   | Installiert Connect CRM automatisch mit                      |
| `Autostart`                                   | Aktiviert Cloudya im Windows-Autostart für alle Benutzer. Kann auch für die Deaktivierung genutzt werden mittels `-Autostart:$false` |
| `DisableUpdateCheck`                                 | Deaktiviert den automatischen Update-Check von Cloudya. Standardmäßig wird der Check aktiviert, jedoch benötigt das Update Admin-Rechte. In Firmennetzwerken sollte der Update-Check daher deaktiviert werden. |
## Funktionsweise

1. Das Script durchsucht die Webseite `https://www.nfon.com/de/service/downloads` nach den jeweiligen Downloadlinks für die neusten MSI-Installer.
2. Die Dateien werden heruntergeladen.
3. Die Installation wird gestartet und überwacht.
4. Gegebenenfalls notwendige Anpassungen (Autostart, Update-Check, CRM-Installation) werden durchgeführt.

### Update-Check deaktivieren

Durch Angabe des Parameters `-DisableUpdateCheck` wird die interne Cloudya-Funktion für das Prüfen auf neue Updates deaktiviert. Somit werden Benutzer nicht mehr zum Updaten der Cloudya-Installation aufgefordert. Dies ist insbesondere im Unternehmensumfeld sinnvoll, da das Update lokale Administratorberechtigungen benötigt.

Die Deaktivierung des Update-Checks geschieht über einen Umweg, da es keine direkte Konfigurationsmöglichkeit gibt:

1. Die Datei `control-cloudya-update.ps1` wird im Programmordner der Cloudya-Installation erstellt.
2. Es wird eine Autostart Verknüpfung für alle Benutzer erstellt, welche das Script `control-cloudya-update.ps1` bei jedem Login ausführt.
3. Das Script erzeugt oder löscht die Datei `%appdata%\cloudya-desktop\Cloudya-local-settings.json`
   1. Wenn die Datei erzeugt wird, ist der Inhalt `{"handle-updates": "IGNORE" }` und deaktiviert das Update.
   2. Wenn die Datei gelöscht wird, funktioniert der Updater wieder wie gewohnt.

*Hinweis: Wenn besondere Sicherheitsvorkehrungen bezüglich der Nutzung von PowerShell-Scripten aktiv sind, schlägt diese Option möglicherweise fehl. In diesem Fall muss eine andere Möglichkeit gefunden werden.*

## Beispiel

Um die aktuelle Version von Cloudya mit CRM Connect sowie automatischem Start zu installieren:

```powershell
.\Deploy-NFONCloudya.ps1 -Action Install -EnableCRM -Autostart -DisableUpdateCheck
```

Um Cloudya komplett zu deinstallieren:

```powershell
.\Deploy-NFONCloudya.ps1 -Action Uninstall
```

Um die aktuell installierte Version auszulesen:

```powershell
.\Deploy-NFONCloudya.ps1 -Action Detect
```

Um ein Update durchzuführen:

```powershell
.\Deploy-NFONCloudya.ps1 -Action Update
```

Um den Autostart nachträglich zu aktivieren:

```powershell
.\Deploy-NFONCloudya.ps1 -Autostart
```

Um den Autostart nachträglich zu deaktivieren:

```powershell
.\Deploy-NFONCloudya.ps1 -Autostart:$false
```
