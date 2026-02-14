# AI Context – I remind you

> **Dieses Dokument dient als Kontext für KI-Assistenten (GitHub Copilot, Claude, etc.)**
> Bei einem neuen Chat diese Datei zuerst lesen lassen.

## � Zugehörige Website

**Website-Repo:** `/Users/johannes/work/websites/appsaufjohannesde/`  
**App-Landingpage (Quelle):** `index.html` im App-Repo (hier)  
**Ziel auf Website:** `appsaufjohannesde/iremindyou/index.html` (eigener Unterordner, analog zu fahrplan4u/, kinderuhr/)  
**Hauptseite:** `appsaufjohannesde/index.html` listet alle Apps inkl. I remind you

### Website-Struktur (appsaufjohannesde)
```
index.html              ← Hauptseite (alle Apps)
impressum.html          ← Impressum
fahrplan4u/             ← Fahrplan4U (index, screenshots, datenschutz)
kinderquiz/             ← KinderQuiz (datenschutz)
kinderuhr/              ← KinderUhr (index, screenshots, datenschutz)
pois4u/                 ← POIs4U (index, support DE/EN)
iremindyou/             ← I remind you (index bilingual DE/EN ✅, datenschutz TODO)
```

### Sync-Workflow
Bei App-Änderungen, die die Website betreffen (Features, Beschreibung, FAQ, Systemanforderungen):
1. `index.html` im App-Repo aktualisieren
2. Datei nach `appsaufjohannesde/iremindyou/index.html` kopieren
3. Falls nötig: App-Eintrag in `appsaufjohannesde/index.html` aktualisieren (Beschreibung, Tags, Links)

### Was Website-relevant ist
- Neue/geänderte Features → Funktionsliste + Feature-Pills in index.html
- FAQ-Änderungen → FAQ-Sektion in index.html
- Systemanforderungen → Sektion in index.html
- App-Store-Link → sobald verfügbar in beiden index.html setzen
- Datenschutz-Änderungen → iremindyou/datenschutz.html

---

## �🎯 Projekt-Zusammenfassung

**App-Name:** I remind you  
**Typ:** iOS & macOS App (SwiftUI, Multiplatform)  
**Zweck:** Familienkalender & Routinen-App für Kinder und Eltern  
**Version:** v0.6.0

### Kernfunktionen
1. **Routinen-Ansicht (Startscreen)** – Dreigeteilt: Fällig / Kommend / Abgeschlossen
2. **Wochenansicht** – Termine + Aufgaben kombiniert
3. **Kinder-Routinen** – Wiederkehrende Aufgaben abhaken (kindgerechte UI)
4. **Listen teilen** – iCloud Listen mit Familie teilen (für Kinder vorbereiten)
5. **Auto-Regeln** – Automatisch Erinnerungen aus Kalenderevents erstellen
6. **PDF-Druck** – Wochenkalender für Kühlschrank/Pinnwand
7. **Bidirektionale Sync** – Änderungen in Apple Apps werden sofort reflektiert
8. **Lokalisierung** – Deutsch, Englisch, Italienisch (Hilfe)

### Technische Grundlagen
- **SwiftUI** + **SwiftData**
- **EventKit** (Apple Kalender & Erinnerungen)
- **MVVM-Architektur**
- Apple Erinnerungen = Source of Truth (keine eigene Datenhaltung für Tasks)

---

## 📁 Projektstruktur

```
I remind you/
├── I remind you.xcodeproj
└── I remind you/
    ├── I_remind_youApp.swift      # SwiftData ModelContainer
    ├── ContentView.swift          # Hauptnavigation + Tab-View
    ├── Models/
    │   ├── AutoRule.swift         # Regeln für Event→Reminder
    │   ├── FamilyEvent.swift      # Unified Model (Calendar + Reminder)
    │   └── FamilyMember.swift     # Familienmitglieder (SwiftData)
    ├── Services/
    │   ├── CalendarService.swift  # EventKit Kalender API
    │   ├── ReminderService.swift  # EventKit Erinnerungen API
    │   └── RuleEngine.swift       # Automatische Erinnerungserstellung
    ├── ViewModels/
    │   └── WeekViewModel.swift
    └── Views/
        ├── Onboarding/
        │   └── OnboardingView.swift
        └── WeekView/
            └── WeekView.swift
```

---

## ✅ Aktueller Stand (v0.5.5)

### Implementiert
- [x] Xcode-Projekt mit iOS 17+ & macOS 14+ Support
- [x] SwiftData konfiguriert (AutoRule, FamilyMember)
- [x] Models: FamilyEvent, AutoRule, FamilyMember, RecurrenceRule
- [x] CalendarService (Kalender lesen + Change Observer)
- [x] ReminderService (Erinnerungen CRUD + Change Observer)
- [x] RuleEngine (Logik für Auto-Erinnerungen)
- [x] **Wochenansicht** mit Tagen, Terminen, Aufgaben
- [x] **Heute-Button** springt zur aktuellen Woche + scrollt zum Tag
- [x] Onboarding mit Berechtigungsanfragen
- [x] Tab-Navigation (Woche, Routinen, Einstellungen)
- [x] Aufgaben abhaken in der App
- [x] **Routinen-View** – Kindgerechte UI mit großen Buttons, Fortschrittsring, Emojis
- [x] **Gamification** – Feier-Overlay wenn alle Aufgaben erledigt
- [x] **Einstellungen-View** – Kalender/Listen auswählen, Auto-Regeln erstellen
- [x] **PDF-Export** – Wochenkalender drucken (A4/US Letter, Querformat, Share Sheet)
- [x] **Zweispaltiges PDF-Layout** – Termine links, Erinnerungen rechts
- [x] **Bidirektionale Sync** – EKEventStoreChanged Observer
- [x] **Lokalisierung** – Deutsch & Englisch (Localizable.strings)
- [x] **TestDataGenerator** – Testdaten erstellen & löschen (Debug)
- [x] **Listen teilen** – Anleitung für iCloud-Sharing mit Familie (ShareListView)
- [x] **Routinen dreiteilig** – Fällig (überfällig/ganztägig), Kommend, Abgeschlossen (eingeklappt)
- [x] **Routinen als Startscreen** – App öffnet direkt die Routinen-Ansicht
- [x] **Multi-Listen** – Alle abonnierten Listen werden gemeinsam angezeigt
- [x] **Hilfe mehrsprachig** – DE/EN/IT mit Sprachwahl

### Entfernt / Vereinfacht
- ~~Routine-Editor (AddRoutineView)~~ – Erinnerungen werden in Apple Reminders erstellt (Source of Truth)
- ~~Einzelne Liste wählen~~ – Stattdessen alle abonnierten Listen gemeinsam

### Noch offen
- [ ] **Widgets** – Home-Screen & Lock-Screen (WidgetKit)

---

## 🏗️ Architektur-Entscheidungen

### Warum Apple Erinnerungen als Backend?
- Keine eigene Cloud nötig
- Sync über iCloud automatisch
- Systemweit nutzbar (Siri, Apple Watch, andere Apps)
- Familienfreigabe möglich
- **Listen können mit anderen Apple-IDs geteilt werden**

### Unified FamilyEvent Model
```swift
struct FamilyEvent {
    let id: String
    let title: String
    let startDate: Date
    let type: EventType  // .calendarEvent | .reminder | .routine
    let isCompleted: Bool
    // ... erstellt aus EKEvent oder EKReminder
}
```

### SwiftData nur für Konfiguration
- `AutoRule` – Regeln für Event→Reminder
- `FamilyMember` – Familienmitglieder & ihre Listen
- **Keine** Speicherung von Kalender/Erinnerungsdaten!

---

## 🔧 Wichtige Code-Stellen

### Berechtigungen anfordern (iOS 17+)
```swift
// CalendarService.swift
try await eventStore.requestFullAccessToEvents()

// ReminderService.swift  
try await eventStore.requestFullAccessToReminders()
```

### Erinnerung abhaken
```swift
// ReminderService.swift
func setCompleted(reminderIdentifier: String, completed: Bool) async throws
```

### Heutige Routinen laden
```swift
// ReminderService.swift
func fetchTodaysReminders(from list: EKCalendar) async -> [EKReminder]
```

---

## 📋 Nächste Schritte (v0.5.0)

1. **Widgets** (WidgetKit)
   - Kleines Widget: Nächste 3 Termine
   - Mittleres Widget: Routine-Fortschritt
   - Lock-Screen Widget

---

## 🏷️ Git Tags

| Tag | Beschreibung |
|-----|--------------|
| v0.1.0 | Initiale Struktur |
| v0.2.0 | MVP Feature-Complete |
| v0.2.1 | PDF Export Bugfix |
| v0.3.0 | Bidirektionale Sync + Lokalisierung + Routine-Fixes |
| v0.4.0 | Routine-Editor + Listen teilen |
| v0.5.0 | Onboarding-Fixes + Hilfe-Seite |
| v0.5.1 | Onboarding Auto-Continue nach Berechtigungen |
| v0.5.4 | Routinen-Fixes (wiederkehrende Erinnerungen, Datumsfilter) |
| v0.5.5 | PDF Querformat + Zweispaltenlayout + US Letter + Testdaten-Sicherheit |
| beta-2026-02-14 | Readme konsolidiert, Routinen dreiteilig, Startscreen, Multi-Listen |

---

## 🚀 Schnellstart für neue Session

```
Projekt: I remind you – Familienkalender & Routinen-App
Pfad: /Users/johannes/work/xcode/Cal4Family/I remind you/
Version: v0.6.0

Lies AI_CONTEXT.md für den vollen Kontext.
Website-Repo: /Users/johannes/work/websites/appsaufjohannesde/

Nächste Features:
- Widgets (Home-Screen & Lock-Screen)
- Website aktualisieren nach Feature-Änderungen
```

---

## 📚 Referenzen

- [EventKit Documentation](https://developer.apple.com/documentation/eventkit)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [iOS 17 Calendar Permissions](https://developer.apple.com/documentation/eventkit/accessing_calendar_using_eventkit_and_eventkitui)
