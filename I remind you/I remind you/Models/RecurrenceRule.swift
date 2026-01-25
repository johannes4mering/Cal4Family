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
    
    // MARK: - Matching
    
    /// Prüft ob diese Wiederholungsregel für ein bestimmtes Datum gilt
    /// - Parameters:
    ///   - date: Das zu prüfende Datum
    ///   - startDate: Das Startdatum der Wiederholung (erste Instanz)
    /// - Returns: true wenn die Regel für dieses Datum zutrifft
    func matches(date: Date, startDate: Date) -> Bool {
        let calendar = Calendar.current
        
        // Datum muss nach oder gleich dem Startdatum sein
        guard calendar.startOfDay(for: date) >= calendar.startOfDay(for: startDate) else {
            return false
        }
        
        // Falls Enddatum gesetzt, muss Datum davor liegen
        if let endDate = endDate, date > endDate {
            return false
        }
        
        switch frequency {
        case .daily:
            // Bei täglich: Prüfe Intervall
            let daysBetween = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            return daysBetween % interval == 0
            
        case .weekly:
            // Bei wöchentlich mit bestimmten Wochentagen
            if !weekdays.isEmpty {
                let dateWeekday = calendar.component(.weekday, from: date)
                guard let weekday = Weekday(rawValue: dateWeekday) else { return false }
                
                // Prüfe ob der Wochentag in der Liste ist
                if !weekdays.contains(weekday) {
                    return false
                }
                
                // Prüfe Intervall (Wochen seit Start)
                let weeksBetween = calendar.dateComponents([.weekOfYear], from: startDate, to: date).weekOfYear ?? 0
                return weeksBetween % interval == 0
            } else {
                // Ohne spezifische Wochentage: gleicher Wochentag wie Start
                let startWeekday = calendar.component(.weekday, from: startDate)
                let dateWeekday = calendar.component(.weekday, from: date)
                guard startWeekday == dateWeekday else { return false }
                
                let weeksBetween = calendar.dateComponents([.weekOfYear], from: startDate, to: date).weekOfYear ?? 0
                return weeksBetween % interval == 0
            }
            
        case .monthly:
            // Bei monatlich: gleicher Tag im Monat
            let startDay = calendar.component(.day, from: startDate)
            let dateDay = calendar.component(.day, from: date)
            guard startDay == dateDay else { return false }
            
            let monthsBetween = calendar.dateComponents([.month], from: startDate, to: date).month ?? 0
            return monthsBetween % interval == 0
            
        case .yearly:
            // Bei jährlich: gleicher Tag und Monat
            let startComponents = calendar.dateComponents([.month, .day], from: startDate)
            let dateComponents = calendar.dateComponents([.month, .day], from: date)
            guard startComponents.month == dateComponents.month,
                  startComponents.day == dateComponents.day else {
                return false
            }
            
            let yearsBetween = calendar.dateComponents([.year], from: startDate, to: date).year ?? 0
            return yearsBetween % interval == 0
        }
    }
    
    /// Erstellt eine RecurrenceRule aus einer EKRecurrenceRule
    static func from(ekRule: EKRecurrenceRule) -> RecurrenceRule? {
        let frequency: Frequency
        switch ekRule.frequency {
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .monthly: frequency = .monthly
        case .yearly: frequency = .yearly
        @unknown default: return nil
        }
        
        var weekdays: Set<Weekday> = []
        if let ekDays = ekRule.daysOfTheWeek {
            for ekDay in ekDays {
                if let weekday = Weekday(rawValue: ekDay.dayOfTheWeek.rawValue) {
                    weekdays.insert(weekday)
                }
            }
        }
        
        return RecurrenceRule(
            frequency: frequency,
            interval: ekRule.interval,
            weekdays: weekdays,
            endDate: ekRule.recurrenceEnd?.endDate
        )
    }
}
