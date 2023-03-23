# Deploy-NFONCloudya.ps1

Dieses Skript versucht, die neueste Version von Cloudya Desktop by NFON von der offiziellen Website zu installieren. Es bietet darüber hinaus einige erweiterte Konfigurationseinstellungen für die Verteilung innerhalb von Firmennetzwerken, da der native Installer von NFON dies nicht bietet.

## Hinweis

Bitte beachten Sie, dass die Verwendung dieses Powershell-Skripts auf eigene Gefahr erfolgt. Das Skript befindet sich noch in der Entwicklung und kann daher Fehler enthalten. Bitte prüfen und testen Sie das Skript sorgfältig, bevor Sie es in einer produktiven Umgebung verwenden. 

Der Autor übernimmt keine Verantwortung für Schäden oder Verluste, die durch die Verwendung des Skripts entstehen könnten.

## Installation

1. Laden Sie das Skript herunter und speichern Sie es in einem beliebigen Verzeichnis auf Ihrem Computer.
2. Starten Sie es in einer administrativen Powershell-Session mit den notwendigen Parametern.

## Verwendung

```powershell
.\Deploy-NFONCloudya.ps1 -Action {Install, Detect, Update, Uninstall} [-EnableCRM] [-Autostart]
```

## Parameter

| Parameter                                     | Verwendung                                                   |
| --------------------------------------------- | ------------------------------------------------------------ |
| `Action {Install, Detect, Update, Uninstall}` | Sagt dem Script, welche Aktion ausgeführt werden soll:<br />Install → Installieren<br />Detect → Aktuelle Version anzeigen<br />Update → Neuste Version installieren, sofern vorhanden<br />Uninstall → Software entfernen |
| `EnableCRM`                                   | Installiert Connect CRM automatisch mit                      |
| `Autostart`                                   | Aktiviert Cloudya im Windows-Autostart für alle Benutzer. Kann auch für die Deaktivierung genutzt werden mittels `-Autostart:$false` |

## Funktionsweise

1. Das Script durchsucht die Webseite `https://www.nfon.com/de/service/downloads` nach den jeweiligen Downloadlinks für die neusten MSI-Installer.
2. Die Dateien werden heruntergeladen.
3. Die Installation wird gestartet und überwacht.
4. Gegebenenfalls notwendige Anpassungen (Autostart, CRM-Installation) werden durchgeführt.

## Beispiel

Um die aktuelle Version von Cloudya mit CRM Connect sowie automatischem Start zu installieren:

```powershell
.\Deploy-NFONCloudya.ps1 -Action Install -EnableCRM -Autostart
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

