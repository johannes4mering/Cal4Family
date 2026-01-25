# ~~Projekt: FamilienPlaner (Apple Kalender & Erinnerungen Orchestrator)~~ 🆕 Cal4Family – Familienkalender & Routinen-App

> 📝 **Änderungshistorie**: Durchgestrichenes (~~so~~) = ursprünglicher Text, 🆕 = neue/überarbeitete Inhalte

## Ziel
Entwicklung einer Apple-nativen App (iOS, ~~optional~~ 🆕 **und** macOS), die Apple Kalender und Apple Erinnerungen kombiniert, um
- tägliche Routinen (v. a. für Kinder) einfach abhaken zu lassen,
- Termine aus verschiedenen Kalendern zusammenzuführen,
- automatisch To-dos aus Kalenderereignissen zu erzeugen,
- ~~Einkaufslisten zu pflegen,~~ 🆕 *(entfernt: redundant, da Apple Erinnerungen dies bereits nativ unterstützt)*
- und einen übersichtlichen, druckbaren **Wochenkalender** zu erzeugen.
- 🆕 **Widgets für den Home-Screen bereitzustellen (Routinen-Fortschritt, Tagesübersicht)**

Die App ergänzt Apple Erinnerungen und Kalender – sie ersetzt sie nicht.

---

## Grundprinzipien
- **Apple Erinnerungen sind die Source of Truth für Aufgaben**
- ~~**Abhaken erfolgt primär in der Apple Erinnerungen-App**~~ 🆕 **Abhaken erfolgt primär IN dieser App (kinderfreundliche UI) – Sync zu Apple Erinnerungen**
- Kalenderereignisse bleiben read-only
- Die App fungiert als Orchestrator, Regel-Engine, Visualisierung und Druck-Werkzeug
- Keine eigene Cloud erforderlich (Apple-APIs only)
- 🆕 **Offline-First: Alle Kernfunktionen funktionieren ohne Internetverbindung**
- 🆕 **Datenschutz: Keine Daten verlassen das Apple-Ökosystem**

---

## Funktionale Anforderungen

### 1) Routinen für Kinder
- Für jedes Kind existiert mindestens eine eigene Erinnerungs-Liste (z. B. „Paul – Routine")
- Aufgaben sind wiederkehrend (täglich, wöchentlich)
- ~~Aufgaben werden **in der Apple Erinnerungen-App abgehakt**~~ 🆕 **Aufgaben werden in der App mit großen, kindgerechten Buttons abgehakt**
- Die App liest den Status und visualisiert den Fortschritt
- 🆕 **Gamification: Belohnungssystem mit Sternen/Punkten für erledigte Aufgaben**
- 🆕 **Morgen-/Abend-Routinen mit visueller Checkliste (Bilder statt nur Text für jüngere Kinder)**

---

### 2) Kalender zusammenführen
- Die App kann mehrere Apple Kalender lesen (z. B.:
  - Müllabfuhr
  - Geburtstage
  - Familie
  - Schule)
- Kalenderereignisse werden in einer gemeinsamen Wochenansicht angezeigt
- Kalenderereignisse selbst sind **nicht abhackbar**
- 🆕 **Farbcodierung: Jeder Kalender behält seine Farbe zur schnellen Unterscheidung**
- 🆕 **Filter: Kalender können ein-/ausgeblendet werden**

---

### 3) Automatische To-dos aus Kalenderereignissen
- Die App kann aus Kalenderereignissen automatisch Erinnerungen erzeugen
- Regelbasiert, z. B.:
  - Müllabfuhr → „Tonne rausstellen" (1 Tag vorher, 19:00)
  - Geburtstag → „Karte schreiben" ~~(2 Tage vorher)~~ 🆕 **(1 Woche vorher – realistischer für Kartenkauf)**
- Regeln sind konfigurierbar (Kalendername, Titel enthält, Offset, Uhrzeit)
- Erzeugte Erinnerungen landen in einer definierten Erinnerungs-Liste
- Duplikate werden zuverlässig verhindert (Event-ID + Regel-ID + Datum)
- 🆕 **Vordefinierte Regel-Templates für häufige Anwendungsfälle**

---

### ~~4) Einkaufsliste~~ 🆕 4) Familien-Dashboard
~~- Die App nutzt eine Apple Erinnerungs-Liste als Einkaufsliste~~
~~- Liste ist systemweit nutzbar (iOS, iPadOS, macOS, Siri, Apple Watch)~~
~~- Die App zeigt die Einkaufsliste nur an (keine eigene Implementierung)~~

🆕 **Neuer Abschnitt:**
- Übersicht über den aktuellen Tag auf einen Blick
- Anstehende Termine aller Familienmitglieder
- Routinen-Fortschritt pro Kind
- Wetter-Integration (optional, für Outdoor-Aktivitäten)

---

### 5) Abhaken von Aufgaben
- ~~Aufgaben werden primär **in der Apple Erinnerungen-App** abgehakt~~ 🆕 **Aufgaben werden in der App abgehakt**
- ~~Optional kann~~ 🆕 Die App ~~selbst das~~ setzt Abhaken ~~auslösen~~ direkt um (setzt Reminder auf erledigt)
- Keine eigene Aufgaben-Status-Logik außerhalb von Apple Erinnerungen
- 🆕 **Schnelles Abhaken: Swipe-Gesten und Haptic Feedback**
- 🆕 **Undo-Funktion: Versehentliches Abhaken rückgängig machen**

---

### 6) Wochenansicht (zentraler Screen)
- Eine kombinierte Wochenansicht zeigt:
  - Termine (aus Kalendern)
  - Aufgaben (aus Erinnerungen)
- Gruppierung nach Wochentagen
- Visuell kind- & familienfreundlich
- Klare Trennung zwischen Terminen und Aufgaben
- 🆕 **Tagesansicht: Alternative Detailansicht für einzelne Tage**
- 🆕 **Drag & Drop: Aufgaben zwischen Tagen verschieben (ändert Fälligkeitsdatum)**

---

### 7) Druck: Wochenkalender
- Die App kann einen **druckbaren Wochenkalender (A4)** als PDF erzeugen
- Inhalt:
  - Woche / Kalenderwoche
  - Pro Tag:
    - Termine (Uhrzeit + Titel)
    - Aufgaben (Checkbox-Status)
  - ~~Optional:~~ Notizfeld 🆕 **(immer dabei)**
- Der Wochenkalender ist für Küche / Pinnwand / Kühlschrank geeignet
- Export via Share Sheet (iOS) / Datei & Drucken (macOS)
- 🆕 **Mehrere Layouts wählbar: Kompakt, Detailliert, Kinderfreundlich (mit Icons)**
- 🆕 **AirPrint-Integration für direktes Drucken**

---

### 🆕 8) Widgets
- **Home-Screen Widget (klein):** Tagesübersicht mit nächsten 3 Terminen
- **Home-Screen Widget (mittel):** Routinen-Fortschritt des Kindes
- **Lock-Screen Widget:** Nächster Termin
- **StandBy-Modus (iOS 17+):** Wochenübersicht

---

### 🆕 9) Apple Watch Companion (Phase 2)
- Schnelles Abhaken von Routinen am Handgelenk
- Komplikation mit Tagesfortschritt
- Benachrichtigungen für anstehende Routinen

---

## Technische Anforderungen

### APIs
- Apple EventKit:
  - EKEvent (Kalender)
  - EKReminder (Erinnerungen)
  - EKCalendar (Kalender & Listen)
- 🆕 **WidgetKit** (für Home-Screen & Lock-Screen Widgets)
- 🆕 **App Intents** (für Siri-Integration & Shortcuts)

### Plattform
- SwiftUI
- iOS ~~(Pflicht)~~ 🆕 **17+** ~~,~~ **&** macOS ~~(optional, empfohlen für Drucken)~~ 🆕 **14+ (beide Pflicht für Mac Catalyst / native)**
- ~~iOS 17+ Berechtigungsmodell beachten~~ 🆕 **Berechtigungsmodell: Full Access für Kalender & Erinnerungen erforderlich**

### 🆕 Persistenz
- **SwiftData** für lokale Konfiguration & Regeln
- **UserDefaults** für einfache Einstellungen
- **Keine eigene Datenbank für Kalender-/Erinnerungsdaten**

---

## Architekturprinzip
- ~~Unified Datenmodell für Anzeige (Events + Reminders)~~ 🆕 **MVVM-Architektur mit klarer Trennung**
- 🆕 **Unified Datenmodell:** Gemeinsame Abstraktion für Events + Reminders
- Regel-Engine für Event → Reminder
- Erinnerungen bleiben systemweit nutzbar
- App speichert nur Konfiguration & Regeln lokal
- 🆕 **Background App Refresh für Regel-Engine (automatische To-do-Erstellung)**

---

## Abgrenzung / Nicht-Ziele
- Kein eigener Task-Manager
- Keine eigene Kalender-Datenhaltung
- Keine Web-App
- Keine Drittanbieter-Cloud
- Keine Ersetzung von Apple Erinnerungen oder Kalender
- 🆕 **Kein Social-Sharing / Familien-Chat**
- 🆕 **Keine In-App-Käufe in der MVP-Version**

---

## Zielgruppe
- Familien ~~mit~~ 🆕 **(Hauptzielgruppe: Eltern von Kindern 4-12 Jahre)**
- Kinder (Routine abhaken)
- Eltern (Organisation)
- Haushalte mit Hybrid-Workflow (digital + Papier)

---

## ~~Erfolgskriterium (MVP)~~ 🆕 MVP-Definition & Roadmap

### Phase 1: MVP (🆕 Geschätzt: 8-10 Wochen)
- ~~Kind~~ 🆕 Kinder können tägliche Aufgaben ~~abhaken~~ 🆕 **in der App abhaken (kindgerechte UI)**
- Eltern sehen Termine + Aufgaben in einer Wochenansicht
- Automatische Erinnerungen entstehen zuverlässig aus Kalendern
- Ein übersichtlicher Wochenkalender kann gedruckt werden
- 🆕 **Ein funktionierendes Home-Screen Widget**

### 🆕 Phase 2 (nach MVP)
- Apple Watch App
- Erweiterte Gamification
- Mehrere Druck-Layouts
- Siri Shortcuts Integration

### 🆕 Phase 3 (Zukunft)
- iPad-optimiertes Layout
- Statistiken & Auswertungen (Routine-Tracking über Zeit)
- Familienfreigabe-Integration
