# Projekt: FamilienPlaner (Apple Kalender & Erinnerungen Orchestrator)

## Ziel
Entwicklung einer Apple-nativen App (iOS, optional macOS), die Apple Kalender und Apple Erinnerungen kombiniert, um
- tägliche Routinen (v. a. für Kinder) einfach abhaken zu lassen,
- Termine aus verschiedenen Kalendern zusammenzuführen,
- automatisch To-dos aus Kalenderereignissen zu erzeugen,
- Einkaufslisten zu pflegen,
- und einen übersichtlichen, druckbaren **Wochenkalender** zu erzeugen.

Die App ergänzt Apple Erinnerungen und Kalender – sie ersetzt sie nicht.

---

## Grundprinzipien
- **Apple Erinnerungen sind die Source of Truth für Aufgaben**
- **Abhaken erfolgt primär in der Apple Erinnerungen-App**
- Kalenderereignisse bleiben read-only
- Die App fungiert als Orchestrator, Regel-Engine, Visualisierung und Druck-Werkzeug
- Keine eigene Cloud erforderlich (Apple-APIs only)

---

## Funktionale Anforderungen

### 1) Routinen für Kinder
- Für jedes Kind existiert mindestens eine eigene Erinnerungs-Liste (z. B. „Paul – Routine“)
- Aufgaben sind wiederkehrend (täglich, wöchentlich)
- Aufgaben werden **in der Apple Erinnerungen-App abgehakt**
- Die App liest den Status und visualisiert den Fortschritt

---

### 2) Kalender zusammenführen
- Die App kann mehrere Apple Kalender lesen (z. B.:
  - Müllabfuhr
  - Geburtstage
  - Familie
  - Schule)
- Kalenderereignisse werden in einer gemeinsamen Wochenansicht angezeigt
- Kalenderereignisse selbst sind **nicht abhackbar**

---

### 3) Automatische To-dos aus Kalenderereignissen
- Die App kann aus Kalenderereignissen automatisch Erinnerungen erzeugen
- Regelbasiert, z. B.:
  - Müllabfuhr → „Tonne rausstellen“ (1 Tag vorher, 19:00)
  - Geburtstag → „Karte schreiben“ (2 Tage vorher)
- Regeln sind konfigurierbar (Kalendername, Titel enthält, Offset, Uhrzeit)
- Erzeugte Erinnerungen landen in einer definierten Erinnerungs-Liste
- Duplikate werden zuverlässig verhindert (Event-ID + Regel-ID + Datum)

---

### 4) Einkaufsliste
- Die App nutzt eine Apple Erinnerungs-Liste als Einkaufsliste
- Liste ist systemweit nutzbar (iOS, iPadOS, macOS, Siri, Apple Watch)
- Die App zeigt die Einkaufsliste nur an (keine eigene Implementierung)

---

### 5) Abhaken von Aufgaben
- Aufgaben werden primär **in der Apple Erinnerungen-App** abgehakt
- Optional kann die App selbst das Abhaken auslösen (setzt Reminder auf erledigt)
- Keine eigene Aufgaben-Status-Logik außerhalb von Apple Erinnerungen

---

### 6) Wochenansicht (zentraler Screen)
- Eine kombinierte Wochenansicht zeigt:
  - Termine (aus Kalendern)
  - Aufgaben (aus Erinnerungen)
- Gruppierung nach Wochentagen
- Visuell kind- & familienfreundlich
- Klare Trennung zwischen Terminen und Aufgaben

---

### 7) Druck: Wochenkalender
- Die App kann einen **druckbaren Wochenkalender (A4)** als PDF erzeugen
- Inhalt:
  - Woche / Kalenderwoche
  - Pro Tag:
    - Termine (Uhrzeit + Titel)
    - Aufgaben (Checkbox-Status)
  - Optional: Notizfeld
- Der Wochenkalender ist für Küche / Pinnwand / Kühlschrank geeignet
- Export via Share Sheet (iOS) / Datei & Drucken (macOS)

---

## Technische Anforderungen

### APIs
- Apple EventKit:
  - EKEvent (Kalender)
  - EKReminder (Erinnerungen)
  - EKCalendar (Kalender & Listen)

### Plattform
- SwiftUI
- iOS (Pflicht), macOS (optional, empfohlen für Drucken)
- iOS 17+ Berechtigungsmodell beachten

---

## Architekturprinzip
- Unified Datenmodell für Anzeige (Events + Reminders)
- Regel-Engine für Event → Reminder
- Erinnerungen bleiben systemweit nutzbar
- App speichert nur Konfiguration & Regeln lokal

---

## Abgrenzung / Nicht-Ziele
- Kein eigener Task-Manager
- Keine eigene Kalender-Datenhaltung
- Keine Web-App
- Keine Drittanbieter-Cloud
- Keine Ersetzung von Apple Erinnerungen oder Kalender

---

## Zielgruppe
- Familien
- Kinder (Routine abhaken)
- Eltern (Organisation)
- Haushalte mit Hybrid-Workflow (digital + Papier)

---

## Erfolgskriterium (MVP)
- Kind kann tägliche Aufgaben abhaken
- Eltern sehen Termine + Aufgaben in einer Wochenansicht
- Automatische Erinnerungen entstehen zuverlässig aus Kalendern
- Ein übersichtlicher Wochenkalender kann gedruckt werden