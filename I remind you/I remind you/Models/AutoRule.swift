//
//  AutoRule.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import SwiftData

/// Regel für automatische Erinnerungserstellung aus Kalenderereignissen
@Model
final class AutoRule {
    var id: UUID
    var name: String
    var isEnabled: Bool
    
    // Trigger-Bedingungen
    var sourceCalendarIdentifier: String // Kalender-ID (z.B. Müllabfuhr)
    var titleContains: String? // Optional: Titel muss diesen Text enthalten
    
    // Erinnerungs-Erstellung
    var reminderTitle: String // z.B. "Tonne rausstellen"
    var targetListIdentifier: String // Ziel-Erinnerungsliste
    var dayOffset: Int // Tage vor dem Event (negativ = vorher)
    var reminderHour: Int // Uhrzeit (Stunde)
    var reminderMinute: Int // Uhrzeit (Minute)
    
    var createdAt: Date
    
    init(
        name: String,
        sourceCalendarIdentifier: String,
        titleContains: String? = nil,
        reminderTitle: String,
        targetListIdentifier: String,
        dayOffset: Int = -1,
        reminderHour: Int = 19,
        reminderMinute: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.isEnabled = true
        self.sourceCalendarIdentifier = sourceCalendarIdentifier
        self.titleContains = titleContains
        self.reminderTitle = reminderTitle
        self.targetListIdentifier = targetListIdentifier
        self.dayOffset = dayOffset
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.createdAt = Date()
    }
}

// MARK: - Beispiel-Regeln
extension AutoRule {
    static var exampleMuellabfuhr: AutoRule {
        AutoRule(
            name: "Müllabfuhr",
            sourceCalendarIdentifier: "",
            titleContains: nil,
            reminderTitle: "Tonne rausstellen",
            targetListIdentifier: "",
            dayOffset: -1,
            reminderHour: 19,
            reminderMinute: 0
        )
    }
    
    static var exampleGeburtstag: AutoRule {
        AutoRule(
            name: "Geburtstag",
            sourceCalendarIdentifier: "",
            titleContains: "Geburtstag",
            reminderTitle: "Karte schreiben",
            targetListIdentifier: "",
            dayOffset: -7,
            reminderHour: 10,
            reminderMinute: 0
        )
    }
}
