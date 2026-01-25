# AI Context – I remind you

> **Dieses Dokument dient als Kontext für KI-Assistenten (GitHub Copilot, Claude, etc.)**
> Bei einem neuen Chat diese Datei zuerst lesen lassen.

## 🎯 Projekt-Zusammenfassung

**App-Name:** I remind you  
**Typ:** iOS & macOS App (SwiftUI, Multiplatform)  
**Zweck:** Familienkalender & Routinen-App für Kinder und Eltern

### Kernfunktionen
1. **Wochenansicht** – Termine + Aufgaben kombiniert
2. **Kinder-Routinen** – Wiederkehrende Aufgaben abhaken (kindgerechte UI)
3. **Auto-Regeln** – Automatisch Erinnerungen aus Kalenderevents erstellen
4. **PDF-Druck** – Wochenkalender für Kühlschrank/Pinnwand

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

## ✅ Aktueller Stand

### Implementiert (v0.1.0)
- [x] Xcode-Projekt mit iOS & macOS Support
- [x] SwiftData konfiguriert
- [x] Models: FamilyEvent, AutoRule, FamilyMember
- [x] CalendarService (Kalender lesen)
- [x] ReminderService (Erinnerungen lesen/schreiben/abhaken)
- [x] RuleEngine (Logik für Auto-Erinnerungen)
- [x] Wochenansicht mit Tagen, Terminen, Aufgaben
- [x] Onboarding mit Berechtigungsanfragen
- [x] Tab-Navigation (Woche, Routinen, Einstellungen)
- [x] Aufgaben abhaken in der App

### Noch offen
- [ ] **Routinen-View** – Kindgerechte UI für Routinen
- [ ] **Einstellungen-View** – Kalender/Listen auswählen, Regeln konfigurieren
- [ ] **PDF-Export** – Wochenkalender drucken
- [ ] **Widgets** – Home-Screen & Lock-Screen

---

## 🏗️ Architektur-Entscheidungen

### Warum Apple Erinnerungen als Backend?
- Keine eigene Cloud nötig
- Sync über iCloud automatisch
- Systemweit nutzbar (Siri, Apple Watch, andere Apps)
- Familienfreigabe möglich

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

### Auto-Regel ausführen
```swift
// RuleEngine.swift
func executeRules(_ rules: [AutoRule], from: Date, to: Date) async throws -> [CreatedReminder]
```

---

## 📋 Nächste Schritte (priorisiert)

1. **Info.plist in Xcode konfigurieren**
   - `Privacy - Calendars Full Access Usage Description`
   - `Privacy - Reminders Full Access Usage Description`

2. **Routinen-View implementieren**
   - Liste der Kinder
   - Pro Kind: Tages-Routinen mit großen Abhak-Buttons
   - Fortschrittsanzeige

3. **Einstellungen-View**
   - Kalender auswählen
   - Erinnerungslisten zuweisen
   - Auto-Regeln erstellen/bearbeiten

4. **PDF-Export**
   - Wochenkalender als A4-PDF
   - Share Sheet Integration

---

## 🚀 Schnellstart für neue Session

```
Ich arbeite an der iOS/macOS App "I remind you" (Familienkalender & Routinen).
Lies bitte zuerst: AI_CONTEXT.md und readme_überarbeitet.md
Aktueller Stand: v0.1.0 (Grundgerüst mit Wochenansicht)
```

---

## 📚 Referenzen

- [EventKit Documentation](https://developer.apple.com/documentation/eventkit)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [iOS 17 Calendar Permissions](https://developer.apple.com/documentation/eventkit/accessing_calendar_using_eventkit_and_eventkitui)
