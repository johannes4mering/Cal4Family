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
