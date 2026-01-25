//
//  TestDataGenerator.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import EventKit

/// Generiert Testdaten für den Simulator
#if DEBUG
@MainActor
final class TestDataGenerator {
    private let eventStore = EKEventStore()
    
    // MARK: - Kalender erstellen
    
    func createTestCalendars() async throws -> [EKCalendar] {
        var createdCalendars: [EKCalendar] = []
        
        let calendarData = [
            ("Familie", CGColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)),
            ("Müllabfuhr", CGColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)),
            ("Schule", CGColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)),
            ("Sport", CGColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)),
        ]
        
        guard let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) ??
                               eventStore.sources.first(where: { $0.sourceType == .calDAV }) ??
                               eventStore.defaultCalendarForNewEvents?.source else {
            print("⚠️ Keine Kalender-Quelle gefunden")
            return []
        }
        
        for (title, color) in calendarData {
            // Prüfen ob Kalender bereits existiert
            if eventStore.calendars(for: .event).contains(where: { $0.title == title }) {
                print("📅 Kalender '\(title)' existiert bereits")
                continue
            }
            
            let calendar = EKCalendar(for: .event, eventStore: eventStore)
            calendar.title = title
            calendar.cgColor = color
            calendar.source = localSource
            
            do {
                try eventStore.saveCalendar(calendar, commit: true)
                createdCalendars.append(calendar)
                print("✅ Kalender erstellt: \(title)")
            } catch {
                print("❌ Fehler bei Kalender '\(title)': \(error)")
            }
        }
        
        return createdCalendars
    }
    
    // MARK: - Erinnerungslisten erstellen
    
    func createTestReminderLists() async throws -> [EKCalendar] {
        var createdLists: [EKCalendar] = []
        
        let listData = [
            ("Paul – Morgenroutine", CGColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)),
            ("Paul – Abendroutine", CGColor(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0)),
            ("Emma – Routine", CGColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)),
            ("Haushalt", CGColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)),
            ("Einkaufen", CGColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)),
        ]
        
        guard let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) ??
                               eventStore.sources.first(where: { $0.sourceType == .calDAV }) ??
                               eventStore.defaultCalendarForNewReminders()?.source else {
            print("⚠️ Keine Erinnerungs-Quelle gefunden")
            return []
        }
        
        for (title, color) in listData {
            if eventStore.calendars(for: .reminder).contains(where: { $0.title == title }) {
                print("📋 Liste '\(title)' existiert bereits")
                continue
            }
            
            let list = EKCalendar(for: .reminder, eventStore: eventStore)
            list.title = title
            list.cgColor = color
            list.source = localSource
            
            do {
                try eventStore.saveCalendar(list, commit: true)
                createdLists.append(list)
                print("✅ Liste erstellt: \(title)")
            } catch {
                print("❌ Fehler bei Liste '\(title)': \(error)")
            }
        }
        
        return createdLists
    }
    
    // MARK: - Test-Events erstellen
    
    func createTestEvents() async throws {
        let familyCalendar = eventStore.calendars(for: .event).first { $0.title == "Familie" }
        let muellCalendar = eventStore.calendars(for: .event).first { $0.title == "Müllabfuhr" }
        let schoolCalendar = eventStore.calendars(for: .event).first { $0.title == "Schule" }
        let sportCalendar = eventStore.calendars(for: .event).first { $0.title == "Sport" }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let events: [(String, EKCalendar?, Int, Int, Int)] = [
            // (Titel, Kalender, Tage ab heute, Stunde Start, Dauer in Stunden)
            ("Oma besuchen", familyCalendar, 0, 15, 2),
            ("Elternabend", schoolCalendar, 1, 19, 2),
            ("Restmüll", muellCalendar, 2, 6, 1),
            ("Fußballtraining Paul", sportCalendar, 2, 16, 2),
            ("Zahnarzt Emma", familyCalendar, 3, 10, 1),
            ("Gelber Sack", muellCalendar, 4, 6, 1),
            ("Geburtstag Opa", familyCalendar, 5, 0, 24), // Ganztägig
            ("Schwimmen", sportCalendar, 5, 14, 1),
            ("Papier", muellCalendar, 6, 6, 1),
        ]
        
        for (title, cal, daysFromNow, hour, duration) in events {
            guard let targetCalendar = cal else { continue }
            
            let event = EKEvent(eventStore: eventStore)
            event.title = title
            event.calendar = targetCalendar
            
            if duration == 24 {
                // Ganztägig
                event.isAllDay = true
                event.startDate = calendar.date(byAdding: .day, value: daysFromNow, to: today)!
                event.endDate = event.startDate
            } else {
                var startComponents = calendar.dateComponents([.year, .month, .day], from: today)
                startComponents.day! += daysFromNow
                startComponents.hour = hour
                startComponents.minute = 0
                event.startDate = calendar.date(from: startComponents)!
                event.endDate = calendar.date(byAdding: .hour, value: duration, to: event.startDate)!
            }
            
            do {
                try eventStore.save(event, span: .thisEvent)
                print("✅ Event erstellt: \(title)")
            } catch {
                print("❌ Fehler bei Event '\(title)': \(error)")
            }
        }
    }
    
    // MARK: - Test-Erinnerungen erstellen
    
    func createTestReminders() async throws {
        let paulMorning = eventStore.calendars(for: .reminder).first { $0.title == "Paul – Morgenroutine" }
        let paulEvening = eventStore.calendars(for: .reminder).first { $0.title == "Paul – Abendroutine" }
        let emmaRoutine = eventStore.calendars(for: .reminder).first { $0.title == "Emma – Routine" }
        let haushalt = eventStore.calendars(for: .reminder).first { $0.title == "Haushalt" }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Morgenroutine Paul
        let morningTasks = [
            ("Aufstehen", 7, 0),
            ("Zähne putzen", 7, 10),
            ("Anziehen", 7, 20),
            ("Frühstücken", 7, 30),
            ("Schultasche packen", 7, 45),
        ]
        
        for (title, hour, minute) in morningTasks {
            if let list = paulMorning {
                try createReminder(title: title, hour: hour, minute: minute, in: list, recurring: true)
            }
        }
        
        // Abendroutine Paul
        let eveningTasks = [
            ("Hausaufgaben machen", 15, 0),
            ("Zimmer aufräumen", 17, 0),
            ("Abendessen", 18, 30),
            ("Duschen", 19, 30),
            ("Zähne putzen", 20, 0),
            ("Lesen", 20, 15),
            ("Schlafen", 20, 30),
        ]
        
        for (title, hour, minute) in eveningTasks {
            if let list = paulEvening {
                try createReminder(title: title, hour: hour, minute: minute, in: list, recurring: true)
            }
        }
        
        // Emma Routine
        let emmaTasks = [
            ("Aufwachen", 7, 30),
            ("Anziehen", 7, 45),
            ("Zähne putzen", 8, 0),
            ("Frühstück", 8, 15),
        ]
        
        for (title, hour, minute) in emmaTasks {
            if let list = emmaRoutine {
                try createReminder(title: title, hour: hour, minute: minute, in: list, recurring: true)
            }
        }
        
        // Haushalt
        let haushaltTasks = [
            ("Wäsche waschen", 10, 0),
            ("Staubsaugen", 11, 0),
            ("Blumen gießen", 9, 0),
        ]
        
        for (title, hour, minute) in haushaltTasks {
            if let list = haushalt {
                try createReminder(title: title, hour: hour, minute: minute, in: list, recurring: false)
            }
        }
    }
    
    private func createReminder(title: String, hour: Int, minute: Int, in list: EKCalendar, recurring: Bool) throws {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = list
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = hour
        dateComponents.minute = minute
        reminder.dueDateComponents = dateComponents
        
        if recurring {
            let rule = EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: nil
            )
            reminder.addRecurrenceRule(rule)
        }
        
        try eventStore.save(reminder, commit: true)
        print("✅ Erinnerung erstellt: \(title)")
    }
    
    // MARK: - Alles erstellen
    
    func generateAllTestData() async {
        print("\n🚀 Starte Testdaten-Generierung...\n")
        
        do {
            // Berechtigungen prüfen
            let eventAccess = try await eventStore.requestFullAccessToEvents()
            let reminderAccess = try await eventStore.requestFullAccessToReminders()
            
            guard eventAccess && reminderAccess else {
                print("❌ Keine Berechtigung für Kalender/Erinnerungen")
                return
            }
            
            print("📅 Erstelle Kalender...")
            _ = try await createTestCalendars()
            
            print("\n📋 Erstelle Erinnerungslisten...")
            _ = try await createTestReminderLists()
            
            print("\n📆 Erstelle Events...")
            try await createTestEvents()
            
            print("\n✅ Erstelle Erinnerungen...")
            try await createTestReminders()
            
            print("\n🎉 Testdaten erfolgreich erstellt!\n")
        } catch {
            print("❌ Fehler: \(error)")
        }
    }
    
    // MARK: - Alles löschen
    
    func deleteAllTestData() async {
        print("\n🗑️ Starte Löschung der Testdaten...\n")
        
        do {
            let eventAccess = try await eventStore.requestFullAccessToEvents()
            let reminderAccess = try await eventStore.requestFullAccessToReminders()
            
            guard eventAccess && reminderAccess else {
                print("❌ Keine Berechtigung")
                return
            }
            
            // Test-Kalender löschen
            let testCalendarNames = ["Familie", "Müllabfuhr", "Schule", "Sport"]
            for calendar in eventStore.calendars(for: .event) {
                if testCalendarNames.contains(calendar.title) {
                    try eventStore.removeCalendar(calendar, commit: true)
                    print("🗑️ Kalender gelöscht: \(calendar.title)")
                }
            }
            
            // Test-Erinnerungslisten löschen
            let testListNames = ["Paul – Morgenroutine", "Paul – Abendroutine", "Emma – Routine", "Haushalt", "Einkaufen"]
            for list in eventStore.calendars(for: .reminder) {
                if testListNames.contains(list.title) {
                    try eventStore.removeCalendar(list, commit: true)
                    print("🗑️ Liste gelöscht: \(list.title)")
                }
            }
            
            print("\n✅ Testdaten erfolgreich gelöscht!\n")
        } catch {
            print("❌ Fehler beim Löschen: \(error)")
        }
    }
}
#endif
