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
    
    // MARK: - Erinnerungsliste erstellen
    
    func createTestReminderLists() async throws -> [EKCalendar] {
        var createdLists: [EKCalendar] = []
        
        let listData = [
            ("Checky4Family", CGColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 1.0)),
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
    
    // MARK: - Test-Erinnerungen erstellen
    
    func createTestReminders(in list: EKCalendar) async throws {
        let tasks: [(String, Int, Int)] = [
            ("Zähne putzen / Brush teeth / Lavarsi i denti", 7, 0),
            ("Anziehen / Get dressed / Vestirsi", 7, 15),
            ("Frühstücken / Have breakfast / Fare colazione", 7, 30),
            ("Schultasche packen / Pack school bag / Preparare lo zaino", 7, 45),
        ]
        
        for (title, hour, minute) in tasks {
            try createReminder(title: title, hour: hour, minute: minute, in: list, recurring: true)
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
            let reminderAccess = try await eventStore.requestFullAccessToReminders()
            
            guard reminderAccess else {
                print("❌ Keine Berechtigung für Erinnerungen")
                return
            }
            
            print("\n📋 Erstelle Erinnerungsliste...")
            let lists = try await createTestReminderLists()
            
            // Frisch erstellte Liste bevorzugen; sonst bestehende suchen
            guard let list = lists.first ?? eventStore.calendars(for: .reminder).first(where: { $0.title == "Checky4Family" }) else {
                print("❌ Liste 'Checky4Family' nicht verfügbar")
                return
            }
            
            print("\n✅ Erstelle Erinnerungen...")
            try await createTestReminders(in: list)
            
            print("\n🎉 Testdaten erfolgreich erstellt!\n")
        } catch {
            print("❌ Fehler: \(error)")
        }
    }
    
    // MARK: - Alles löschen
    
    func deleteAllTestData() async {
        print("\n🗑️ Starte Löschung der Testdaten...\n")
        
        do {
            let reminderAccess = try await eventStore.requestFullAccessToReminders()
            
            guard reminderAccess else {
                print("❌ Keine Berechtigung")
                return
            }
            
            // Test-Erinnerungslisten löschen - NUR wenn sie aus LOKALER Quelle stammen!
            let testListNames = ["Checky4Family"]
            for list in eventStore.calendars(for: .reminder) {
                guard list.source.sourceType == .local else {
                    if testListNames.contains(list.title) {
                        print("⚠️ Liste '\(list.title)' übersprungen (nicht lokal, Quelle: \(list.source.title))")
                    }
                    continue
                }
                
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
