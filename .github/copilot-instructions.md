# Copilot Instructions – I remind you

## Projekt
iOS & macOS Familienkalender-App (SwiftUI, EventKit, SwiftData).
Apple Erinnerungen = Source of Truth. Keine eigene Cloud.

## Kontext laden
**Immer zuerst `AI_CONTEXT.md` lesen** – enthält Architektur, aktuellen Stand, offene Tasks.

## Zugehörige Website
Die App hat eine Landingpage, die mit gepflegt werden muss:
- **Website-Repo:** `/Users/johannes/work/websites/appsaufjohannesde/`
- **App-Landingpage (Quelle):** `index.html` im App-Repo
- **Ziel:** `/Users/johannes/work/websites/appsaufjohannesde/iremindyou/` (Unterordner wie bei anderen Apps)
- **Hauptseite:** `index.html` in appsaufjohannesde listet alle Apps

Bei Feature-Änderungen prüfen:
1. Muss `index.html` im App-Repo aktualisiert werden?
2. Muss die Datei nach `appsaufjohannesde/iremindyou/` deployt werden?
3. Muss der App-Eintrag auf der Hauptseite aktualisiert werden?

## Code-Stil
- Swift, SwiftUI, MVVM
- Deutsche Kommentare, englische Variablennamen
- Lokalisierung: Deutsch (primär), Englisch, Italienisch (Hilfe)
- Plattform: iOS 17+, macOS 14+
