# Checky4Family – Familienkalender & Routinen-App

## Ziel
Entwicklung einer Apple-nativen App (iOS und macOS), die Apple Kalender und Apple Erinnerungen kombiniert, um
- tägliche Routinen (v. a. für Kinder) einfach abhaken zu lassen,
- Termine aus verschiedenen Kalendern zusammenzuführen,
- automatisch To-dos aus Kalenderereignissen zu erzeugen,
- und einen übersichtlichen, druckbaren Wochenkalender zu erzeugen.

**Besonders geeignet für Kinder mit ADHS:** Die App bietet klare Strukturen, visuelle Routinen und große, übersichtliche Buttons ohne Ablenkung.

Die App ergänzt Apple Erinnerungen und Kalender – sie ersetzt sie nicht.

---

## Grundprinzipien
- **Apple Erinnerungen sind die Source of Truth für Aufgaben**
- **Abhaken erfolgt primär in dieser App (kinderfreundliche UI) – Sync zu Apple Erinnerungen**
- Kalenderereignisse bleiben read-only
- Die App fungiert als Orchestrator, Regel-Engine, Visualisierung und Druck-Werkzeug
- Keine eigene Cloud erforderlich (Apple-APIs only)
- Offline-First: Alle Kernfunktionen funktionieren ohne Internetverbindung
- Datenschutz: Keine Daten verlassen das Apple-Ökosystem

---

## Funktionale Anforderungen

### 1) Routinen-Ansicht (Startscreen)
Die Routinen-Ansicht ist der **primaere Einstiegspunkt** der App.

**Startverhalten:**
- Beim Oeffnen zeigt die App sofort die Routinen-Ansicht
- Es werden alle Erinnerungen aus den in den Einstellungen abonnierten Listen geladen
- Nur Eintraege fuer den heutigen Tag werden angezeigt

**Dreigeteilt nach Status:**
- **Faellig** (rot markiert): Erinnerungen deren Uhrzeit jetzt oder vorher liegt, sowie ganztaegige Erinnerungen (ohne Uhrzeit). Diese erfordern sofortige Aufmerksamkeit.
- **Kommend** (blau markiert): Erinnerungen deren Uhrzeit heute noch in der Zukunft liegt. Vorausschau auf den Rest des Tages.
- **Abgeschlossen** (gruen, eingeklappt): Heute erledigte Erinnerungen. Standardmaessig eingeklappt um den Fokus auf Offenes zu halten.

**Weitere Merkmale:**
- Fuer jedes Kind existiert mindestens eine eigene Erinnerungs-Liste (z. B. "Paul - Routine")
- Aufgaben sind wiederkehrend (taeglich, woechentlich)
- Aufgaben werden in der App mit grossen, kindgerechten Buttons abgehakt
- Die App liest den Status und visualisiert den Fortschritt (Fortschrittsring)
- ADHS-freundlich: Grosse Buttons, Emojis zur Orientierung, klare visuelle Struktur ohne Ablenkung
- Gamification: Belohnungssystem mit Sternen/Punkten fuer erledigte Aufgaben
- Morgen-/Abend-Routinen mit visueller Checkliste (Bilder statt nur Text fuer juengere Kinder)

---

### 2) Kalender zusammenfuehren
- Die App kann mehrere Apple Kalender lesen (z. B.:
  - Muellabfuhr
  - Geburtstage
  - Familie
  - Schule)
- Kalenderereignisse werden in einer gemeinsamen Wochenansicht angezeigt
- Kalenderereignisse selbst sind nicht abhackbar
- Farbcodierung: Jeder Kalender behaelt seine Farbe zur schnellen Unterscheidung
- Filter: Kalender koennen ein-/ausgeblendet werden

---

### 3) Automatische To-dos aus Kalenderereignissen
- Die App kann aus Kalenderereignissen automatisch Erinnerungen erzeugen
- Regelbasiert, z. B.:
  - Muellabfuhr -> "Tonne rausstellen" (1 Tag vorher, 19:00)
  - Geburtstag -> "Karte schreiben" (1 Woche vorher)
- Regeln sind konfigurierbar (Kalendername, Titel enthaelt, Offset, Uhrzeit)
- Erzeugte Erinnerungen landen in einer definierten Erinnerungs-Liste
- Duplikate werden zuverlaessig verhindert (Event-ID + Regel-ID + Datum)
- Vordefinierte Regel-Templates fuer haeufige Anwendungsfaelle

---

### 4) Familien-Dashboard
- Uebersicht ueber den aktuellen Tag auf einen Blick
- Anstehende Termine aller Familienmitglieder
- Routinen-Fortschritt pro Kind
- Wetter-Integration (optional, fuer Outdoor-Aktivitaeten)

---

### 5) Abhaken von Aufgaben
- Aufgaben werden in der App abgehakt und direkt in Apple Erinnerungen gesetzt
- Schnelles Abhaken: Swipe-Gesten und Haptic Feedback
- Undo-Funktion: Versehentliches Abhaken rueckgaengig machen
- Keine eigene Aufgaben-Status-Logik ausserhalb von Apple Erinnerungen

---

### 6) Wochenansicht (zentraler Screen)
- Eine kombinierte Wochenansicht zeigt:
  - Termine (aus Kalendern)
  - Aufgaben (aus Erinnerungen)
- Gruppierung nach Wochentagen
- Visuell kind- & familienfreundlich
- Klare Trennung zwischen Terminen und Aufgaben
- Tagesansicht: Alternative Detailansicht fuer einzelne Tage
- Drag & Drop: Aufgaben zwischen Tagen verschieben (aendert Faelligkeitsdatum)

---

### 7) Druck: Wochenkalender
- Die App kann einen druckbaren Wochenkalender als PDF erzeugen
- Papierformate: A4 und US Letter
- Orientierung: Querformat (Standard) oder Hochformat
- Inhalte:
  - Woche / Kalenderwoche
  - Pro Tag: Termine (Uhrzeit + Titel) und Aufgaben (Checkbox-Status)
  - Farbliche Hervorhebung fuer heute und Wochenende
  - Notizfeld (immer dabei)
- Mehrere Layouts waehlbar: Kompakt, Detailliert, Kinderfreundlich (mit Icons)
- AirPrint-Integration fuer direktes Drucken
- Export via Share Sheet (iOS) / Datei & Drucken (macOS)

---

### 8) Widgets
- Home-Screen Widget (klein): Tagesuebersicht mit naechsten 3 Terminen
- Home-Screen Widget (mittel): Routinen-Fortschritt des Kindes
- Lock-Screen Widget: Naechster Termin
- StandBy-Modus (iOS 17+): Wochenuebersicht

---

### 9) Apple Watch Companion (Phase 2)
- Schnelles Abhaken von Routinen am Handgelenk
- Komplikation mit Tagesfortschritt
- Benachrichtigungen fuer anstehende Routinen

---

## Technische Anforderungen

### APIs
- Apple EventKit:
  - EKEvent (Kalender)
  - EKReminder (Erinnerungen)
  - EKCalendar (Kalender & Listen)
- WidgetKit (Home-Screen & Lock-Screen Widgets)
- App Intents (Siri-Integration & Shortcuts)

### Plattform
- SwiftUI
- iOS 17+ und macOS 14+ (beide Pflicht, Mac Catalyst oder nativ)
- Berechtigungsmodell: Full Access fuer Kalender & Erinnerungen erforderlich

### Persistenz
- SwiftData fuer lokale Konfiguration & Regeln
- UserDefaults fuer einfache Einstellungen
- Keine eigene Datenbank fuer Kalender-/Erinnerungsdaten

---

## Architekturprinzip
- MVVM-Architektur mit klarer Trennung
- Unified Datenmodell: Gemeinsame Abstraktion fuer Events + Reminders
- Regel-Engine fuer Event -> Reminder
- Erinnerungen bleiben systemweit nutzbar
- App speichert nur Konfiguration & Regeln lokal
- Background App Refresh fuer Regel-Engine (automatische To-do-Erstellung)

---

## Abgrenzung / Nicht-Ziele
- Kein eigener Task-Manager
- Keine eigene Kalender-Datenhaltung
- Keine Web-App
- Keine Drittanbieter-Cloud
- Keine Ersetzung von Apple Erinnerungen oder Kalender
- Kein Social-Sharing / Familien-Chat
- Keine In-App-Kaeufe in der MVP-Version

---

## Zielgruppe
- Familien (Hauptzielgruppe: Eltern von Kindern 4-12 Jahre)
- Kinder (Routine abhaken)
- Eltern (Organisation)
- Haushalte mit Hybrid-Workflow (digital + Papier)

---

## MVP-Definition & Roadmap

### Phase 1: MVP (geschaetzt: 8-10 Wochen)
- Kinder koennen taegliche Aufgaben in der App abhaken (kindgerechte UI)
- Eltern sehen Termine + Aufgaben in einer Wochenansicht
- Automatische Erinnerungen entstehen zuverlaessig aus Kalendern
- Ein uebersichtlicher Wochenkalender kann gedruckt werden
- Ein funktionierendes Home-Screen Widget

### Phase 2 (nach MVP)
- Apple Watch App
- Erweiterte Gamification
- Mehrere Druck-Layouts
- Siri Shortcuts Integration

### Phase 3 (Zukunft)
- iPad-optimiertes Layout
- Statistiken & Auswertungen (Routine-Tracking ueber Zeit)
- Familienfreigabe-Integration