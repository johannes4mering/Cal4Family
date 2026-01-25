//
//  FamilyEvent.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import EventKit

/// Unified Datenmodell für die Anzeige von Kalenderevents und Erinnerungen
struct FamilyEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date?
    let isAllDay: Bool
    let type: EventType
    let calendarColor: String // Hex-Farbe
    let calendarName: String
    let isCompleted: Bool
    let originalEventIdentifier: String // EKEvent oder EKReminder ID
    
    enum EventType: String, Codable {
        case calendarEvent // Aus Apple Kalender
        case reminder // Aus Apple Erinnerungen
        case routine // Wiederkehrende Kinder-Routine
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FamilyEvent, rhs: FamilyEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods
extension FamilyEvent {
    /// Erstellt ein FamilyEvent aus einem EKEvent (Kalendereintrag)
    static func from(event: EKEvent) -> FamilyEvent {
        FamilyEvent(
            id: event.eventIdentifier ?? UUID().uuidString,
            title: event.title ?? "Ohne Titel",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            type: .calendarEvent,
            calendarColor: event.calendar?.cgColor?.hexString ?? "#007AFF",
            calendarName: event.calendar?.title ?? "Kalender",
            isCompleted: false,
            originalEventIdentifier: event.eventIdentifier ?? ""
        )
    }
    
    /// Erstellt ein FamilyEvent aus einer EKReminder (Erinnerung)
    static func from(reminder: EKReminder) -> FamilyEvent {
        let dueDate = reminder.dueDateComponents?.date ?? Date()
        
        return FamilyEvent(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "Ohne Titel",
            startDate: dueDate,
            endDate: nil,
            isAllDay: true,
            type: reminder.hasRecurrenceRules ? .routine : .reminder,
            calendarColor: reminder.calendar?.cgColor?.hexString ?? "#34C759",
            calendarName: reminder.calendar?.title ?? "Erinnerungen",
            isCompleted: reminder.isCompleted,
            originalEventIdentifier: reminder.calendarItemIdentifier
        )
    }
    
    /// Erstellt ein "expandiertes" FamilyEvent für ein bestimmtes Datum
    /// Wird für wiederkehrende Routinen verwendet
    static func expandedFrom(reminder: EKReminder, forDate date: Date) -> FamilyEvent {
        let calendar = Calendar.current
        
        // Zeit vom Original übernehmen, falls vorhanden
        var eventDate = calendar.startOfDay(for: date)
        if let dueComponents = reminder.dueDateComponents,
           let hour = dueComponents.hour,
           let minute = dueComponents.minute {
            eventDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: eventDate) ?? eventDate
        }
        
        // Eindeutige ID für expandiertes Event: Original-ID + Datum
        let dateString = ISO8601DateFormatter().string(from: calendar.startOfDay(for: date))
        let expandedId = "\(reminder.calendarItemIdentifier)_\(dateString)"
        
        // Prüfe ob für diesen Tag bereits erledigt
        // Bei wiederkehrenden Reminders: Nur die aktuelle Instanz ist als completed markiert
        let isCompletedToday: Bool
        if reminder.isCompleted, let completionDate = reminder.completionDate {
            isCompletedToday = calendar.isDate(completionDate, inSameDayAs: date)
        } else {
            isCompletedToday = false
        }
        
        return FamilyEvent(
            id: expandedId,
            title: reminder.title ?? "Ohne Titel",
            startDate: eventDate,
            endDate: nil,
            isAllDay: reminder.dueDateComponents?.hour == nil,
            type: .routine,
            calendarColor: reminder.calendar?.cgColor?.hexString ?? "#34C759",
            calendarName: reminder.calendar?.title ?? "Routinen",
            isCompleted: isCompletedToday,
            originalEventIdentifier: reminder.calendarItemIdentifier
        )
    }
}

// MARK: - CGColor Extension für Hex-Konvertierung
extension CGColor {
    var hexString: String {
        guard let components = self.components, components.count >= 3 else {
            return "#007AFF"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
