//
//  WeekViewModel.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel für die Wochenansicht
@MainActor
final class WeekViewModel: ObservableObject {
    let calendarService: CalendarService
    let reminderService: ReminderService
    
    @Published var currentWeekStart: Date
    @Published var events: [FamilyEvent] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var scrollToToday: Bool = false
    
    var weekDays: [Date] {
        (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: currentWeekStart)
        }
    }
    
    var weekEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
    }
    
    var weekTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "'KW' w, MMMM yyyy"
        return formatter.string(from: currentWeekStart)
    }
    
    /// Check if we're currently showing the week that contains today
    var isCurrentWeek: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.isDate(currentWeekStart, equalTo: today, toGranularity: .weekOfYear)
    }
    
    init(calendarService: CalendarService, reminderService: ReminderService) {
        self.calendarService = calendarService
        self.reminderService = reminderService
        
        // Wochenstart berechnen (Montag)
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday + 5) % 7 // Montag = 0
        self.currentWeekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: today)) ?? today
    }
    
    // MARK: - Navigation
    
    func goToPreviousWeek() {
        if let newStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) {
            currentWeekStart = newStart
            Task { await loadEvents() }
        }
    }
    
    func goToNextWeek() {
        if let newStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) {
            currentWeekStart = newStart
            Task { await loadEvents() }
        }
    }
    
    func goToCurrentWeek() {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday + 5) % 7
        currentWeekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: today)) ?? today
        Task { 
            await loadEvents()
            // Trigger scroll to today after loading
            scrollToToday = true
        }
    }
    
    // MARK: - Daten laden
    
    func loadEvents() async {
        isLoading = true
        error = nil
        
        do {
            // Kalender-Events laden
            let calendarEvents = calendarService.fetchFamilyEvents(
                from: currentWeekStart,
                to: weekEndDate
            )
            
            // Erinnerungen laden
            let reminderEvents = await reminderService.fetchFamilyEvents(
                from: currentWeekStart,
                to: weekEndDate
            )
            
            // Kombinieren und sortieren
            events = (calendarEvents + reminderEvents).sorted { $0.startDate < $1.startDate }
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Events filtern
    
    func events(for date: Date) -> [FamilyEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
    
    func calendarEvents(for date: Date) -> [FamilyEvent] {
        events(for: date).filter { $0.type == .calendarEvent }
    }
    
    func tasks(for date: Date) -> [FamilyEvent] {
        events(for: date).filter { $0.type == .reminder || $0.type == .routine }
    }
    
    // MARK: - Aktionen
    
    func toggleTaskCompletion(_ event: FamilyEvent) async {
        guard event.type == .reminder || event.type == .routine else { return }
        
        do {
            try await reminderService.setCompleted(
                reminderIdentifier: event.originalEventIdentifier,
                completed: !event.isCompleted
            )
            await loadEvents()
        } catch {
            self.error = error
        }
    }
}
