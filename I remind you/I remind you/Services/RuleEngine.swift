//
//  RuleEngine.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import EventKit
import SwiftData
import Combine

/// Engine für automatische Erinnerungserstellung aus Kalenderereignissen
@MainActor
final class RuleEngine: ObservableObject {
    private let calendarService: CalendarService
    private let reminderService: ReminderService
    
    @Published var lastRunDate: Date?
    @Published var createdRemindersCount: Int = 0
    
    init(calendarService: CalendarService, reminderService: ReminderService) {
        self.calendarService = calendarService
        self.reminderService = reminderService
    }
    
    // MARK: - Regeln ausführen
    
    /// Führt alle aktiven Regeln für einen Zeitraum aus
    func executeRules(
        _ rules: [AutoRule],
        from startDate: Date,
        to endDate: Date
    ) async throws -> [CreatedReminder] {
        var createdReminders: [CreatedReminder] = []
        
        let activeRules = rules.filter { $0.isEnabled }
        
        for rule in activeRules {
            let reminders = try await executeRule(rule, from: startDate, to: endDate)
            createdReminders.append(contentsOf: reminders)
        }
        
        lastRunDate = Date()
        createdRemindersCount = createdReminders.count
        
        return createdReminders
    }
    
    /// Führt eine einzelne Regel aus
    func executeRule(
        _ rule: AutoRule,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [CreatedReminder] {
        var created: [CreatedReminder] = []
        
        // Kalender für die Regel finden
        guard let sourceCalendar = calendarService.calendar(withIdentifier: rule.sourceCalendarIdentifier) else {
            return []
        }
        
        // Ziel-Liste für Erinnerungen finden
        guard let targetList = reminderService.list(withIdentifier: rule.targetListIdentifier) else {
            return []
        }
        
        // Events aus dem Quell-Kalender laden
        let events = calendarService.fetchEvents(
            from: startDate,
            to: endDate,
            calendars: [sourceCalendar]
        )
        
        // Für jedes passende Event eine Erinnerung erstellen
        for event in events {
            // Prüfen ob Titel-Filter passt
            if let titleFilter = rule.titleContains, !titleFilter.isEmpty {
                guard event.title?.localizedCaseInsensitiveContains(titleFilter) == true else {
                    continue
                }
            }
            
            // Duplikat-Prüfung
            let duplicateKey = generateDuplicateKey(rule: rule, event: event)
            if await reminderExists(withKey: duplicateKey) {
                continue
            }
            
            // Erinnerungsdatum berechnen
            guard let reminderDate = calculateReminderDate(for: event, with: rule) else {
                continue
            }
            
            // Erinnerung nur erstellen wenn sie in der Zukunft liegt
            guard reminderDate > Date() else {
                continue
            }
            
            // Erinnerung erstellen
            do {
                let reminder = try reminderService.createReminder(
                    title: rule.reminderTitle,
                    dueDate: reminderDate,
                    in: targetList,
                    notes: "Auto-erstellt für: \(event.title ?? "Event")\nKey: \(duplicateKey)"
                )
                
                created.append(CreatedReminder(
                    reminderIdentifier: reminder.calendarItemIdentifier,
                    eventIdentifier: event.eventIdentifier ?? "",
                    ruleId: rule.id,
                    createdAt: Date()
                ))
            } catch {
                print("Fehler beim Erstellen der Erinnerung: \(error)")
            }
        }
        
        return created
    }
    
    // MARK: - Helper
    
    /// Generiert einen eindeutigen Schlüssel zur Duplikaterkennung
    private func generateDuplicateKey(rule: AutoRule, event: EKEvent) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: event.startDate)
        
        return "\(rule.id.uuidString)|\(event.eventIdentifier ?? "")|\(dateString)"
    }
    
    /// Prüft ob eine Erinnerung mit diesem Key bereits existiert
    private func reminderExists(withKey key: String) async -> Bool {
        // Suche in allen Erinnerungslisten nach dem Key in den Notes
        for list in reminderService.reminderLists {
            let reminders = await reminderService.fetchIncompleteReminders(from: list)
            if reminders.contains(where: { $0.notes?.contains(key) == true }) {
                return true
            }
        }
        return false
    }
    
    /// Berechnet das Erinnerungsdatum basierend auf Event und Regel
    private func calculateReminderDate(for event: EKEvent, with rule: AutoRule) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // Offset in Tagen anwenden
        guard let dateWithOffset = calendar.date(byAdding: .day, value: rule.dayOffset, to: event.startDate) else {
            return nil
        }
        
        // Uhrzeit setzen
        var components = calendar.dateComponents([.year, .month, .day], from: dateWithOffset)
        components.hour = rule.reminderHour
        components.minute = rule.reminderMinute
        
        return calendar.date(from: components)
    }
}

// MARK: - Supporting Types

/// Repräsentiert eine automatisch erstellte Erinnerung
struct CreatedReminder: Identifiable {
    let id = UUID()
    let reminderIdentifier: String
    let eventIdentifier: String
    let ruleId: UUID
    let createdAt: Date
}
