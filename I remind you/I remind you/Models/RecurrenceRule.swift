//
//  RecurrenceRule.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import EventKit

/// Wiederholungsregel für Erinnerungen
struct RecurrenceRule: Equatable, Codable {
    enum Frequency: String, CaseIterable, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .daily: return String(localized: "recurrence_daily", defaultValue: "Täglich")
            case .weekly: return String(localized: "recurrence_weekly", defaultValue: "Wöchentlich")
            case .monthly: return String(localized: "recurrence_monthly", defaultValue: "Monatlich")
            case .yearly: return String(localized: "recurrence_yearly", defaultValue: "Jährlich")
            }
        }
        
        var ekFrequency: EKRecurrenceFrequency {
            switch self {
            case .daily: return .daily
            case .weekly: return .weekly
            case .monthly: return .monthly
            case .yearly: return .yearly
            }
        }
    }
    
    enum Weekday: Int, CaseIterable, Codable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
        
        var shortName: String {
            switch self {
            case .sunday: return String(localized: "weekday_sun", defaultValue: "So")
            case .monday: return String(localized: "weekday_mon", defaultValue: "Mo")
            case .tuesday: return String(localized: "weekday_tue", defaultValue: "Di")
            case .wednesday: return String(localized: "weekday_wed", defaultValue: "Mi")
            case .thursday: return String(localized: "weekday_thu", defaultValue: "Do")
            case .friday: return String(localized: "weekday_fri", defaultValue: "Fr")
            case .saturday: return String(localized: "weekday_sat", defaultValue: "Sa")
            }
        }
        
        var ekWeekday: EKWeekday {
            EKWeekday(rawValue: rawValue)!
        }
    }
    
    var frequency: Frequency
    var interval: Int = 1  // alle X Tage/Wochen/Monate
    var weekdays: Set<Weekday> = []  // für wöchentliche Wiederholung
    var endDate: Date? = nil  // optional: Ende der Wiederholung
    
    /// Konvertiert zu EventKit's EKRecurrenceRule
    func toEKRecurrenceRule() -> EKRecurrenceRule {
        var daysOfWeek: [EKRecurrenceDayOfWeek]? = nil
        
        if frequency == .weekly && !weekdays.isEmpty {
            daysOfWeek = weekdays.map { EKRecurrenceDayOfWeek($0.ekWeekday) }
        }
        
        let end: EKRecurrenceEnd? = endDate.map { EKRecurrenceEnd(end: $0) }
        
        return EKRecurrenceRule(
            recurrenceWith: frequency.ekFrequency,
            interval: interval,
            daysOfTheWeek: daysOfWeek,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: end
        )
    }
    
    // MARK: - Presets
    
    static var daily: RecurrenceRule {
        RecurrenceRule(frequency: .daily, interval: 1)
    }
    
    static var weekdays: RecurrenceRule {
        RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
    }
    
    static var weekly: RecurrenceRule {
        RecurrenceRule(frequency: .weekly, interval: 1)
    }
    
    static var monthly: RecurrenceRule {
        RecurrenceRule(frequency: .monthly, interval: 1)
    }
}
