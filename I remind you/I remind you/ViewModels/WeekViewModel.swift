//
//  WeekViewModel.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import SwiftUI
import Combine
import EventKit

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
    
    // UserDefaults Keys (gleich wie in SettingsViewModel)
    private let selectedCalendarsKey = "selectedCalendarIdentifiers"
    private let selectedRemindersKey = "selectedReminderListIdentifiers"
    
    /// Gibt die ausgewählten Kalender-IDs aus UserDefaults zurück
    @Published private(set) var selectedCalendarIdentifiers: Set<String> = []
    
    /// Gibt die ausgewählten Listen-IDs aus UserDefaults zurück
    @Published private(set) var selectedReminderListIdentifiers: Set<String> = []
    
    /// Wurde die Kalender-Auswahl jemals konfiguriert? (Key existiert in UserDefaults)
    private var hasConfiguredCalendars: Bool {
        UserDefaults.standard.object(forKey: selectedCalendarsKey) != nil
    }
    
    /// Wurde die Listen-Auswahl jemals konfiguriert?
    private var hasConfiguredReminderLists: Bool {
        UserDefaults.standard.object(forKey: selectedRemindersKey) != nil
    }
    
    /// Lädt die Auswahl aus UserDefaults
    private func loadSelections() {
        if let saved = UserDefaults.standard.array(forKey: selectedCalendarsKey) as? [String] {
            selectedCalendarIdentifiers = Set(saved)
        }
        if let saved = UserDefaults.standard.array(forKey: selectedRemindersKey) as? [String] {
            selectedReminderListIdentifiers = Set(saved)
        }
    }
    
    /// Gefilterte Kalender basierend auf Auswahl
    /// - Nie konfiguriert → nil (= alle anzeigen, Erststart-Default)
    /// - Konfiguriert → explizite Filterliste (auch wenn leer = nichts anzeigen)
    private var selectedCalendars: [EKCalendar]? {
        guard hasConfiguredCalendars else { return nil }
        let identifiers = selectedCalendarIdentifiers
        return calendarService.calendars.filter { identifiers.contains($0.calendarIdentifier) }
    }
    
    /// Alle Kalender für die Legende
    var allCalendars: [EKCalendar] {
        calendarService.calendars
    }
    
    /// Alle Erinnerungslisten für die Legende
    var allReminderLists: [EKCalendar] {
        reminderService.reminderLists
    }
    
    /// Prüft ob ein Kalender aktiv (ausgewählt) ist
    func isCalendarActive(_ calendar: EKCalendar) -> Bool {
        // Nie konfiguriert = alle aktiv (Erststart-Default)
        guard hasConfiguredCalendars else { return true }
        return selectedCalendarIdentifiers.contains(calendar.calendarIdentifier)
    }
    
    /// Prüft ob eine Liste aktiv (ausgewählt) ist
    func isReminderListActive(_ list: EKCalendar) -> Bool {
        // Nie konfiguriert = alle aktiv (Erststart-Default)
        guard hasConfiguredReminderLists else { return true }
        return selectedReminderListIdentifiers.contains(list.calendarIdentifier)
    }
    
    /// Toggled einen Kalender ein/aus
    func toggleCalendar(_ calendar: EKCalendar) {
        var identifiers = selectedCalendarIdentifiers
        
        // Beim ersten Toggle: Alle IDs materialisieren
        if !hasConfiguredCalendars {
            identifiers = Set(calendarService.calendars.map { $0.calendarIdentifier })
        }
        
        if identifiers.contains(calendar.calendarIdentifier) {
            identifiers.remove(calendar.calendarIdentifier)
        } else {
            identifiers.insert(calendar.calendarIdentifier)
        }
        
        selectedCalendarIdentifiers = identifiers
        UserDefaults.standard.set(Array(identifiers), forKey: selectedCalendarsKey)
        
        Task { await loadEvents() }
    }
    
    /// Toggled eine Erinnerungsliste ein/aus
    func toggleReminderList(_ list: EKCalendar) {
        var identifiers = selectedReminderListIdentifiers
        
        // Beim ersten Toggle: Alle IDs materialisieren
        if !hasConfiguredReminderLists {
            identifiers = Set(reminderService.reminderLists.map { $0.calendarIdentifier })
        }
        
        if identifiers.contains(list.calendarIdentifier) {
            identifiers.remove(list.calendarIdentifier)
        } else {
            identifiers.insert(list.calendarIdentifier)
        }
        
        selectedReminderListIdentifiers = identifiers
        UserDefaults.standard.set(Array(identifiers), forKey: selectedRemindersKey)
        
        Task { await loadEvents() }
    }
    
    /// Aktive Kalender für die Legende (die tatsächlich angezeigt werden)
    var activeCalendars: [EKCalendar] {
        if let selected = selectedCalendars {
            return selected
        }
        return calendarService.calendars
    }
    
    /// Aktive Erinnerungslisten für die Legende (die tatsächlich angezeigt werden)
    var activeReminderLists: [EKCalendar] {
        if let selected = selectedReminderLists {
            return selected
        }
        return reminderService.reminderLists
    }
    
    /// Gefilterte Erinnerungslisten basierend auf Auswahl
    /// - Nie konfiguriert → nil (= alle anzeigen, Erststart-Default)
    /// - Konfiguriert → explizite Filterliste (auch wenn leer = nichts anzeigen)
    private var selectedReminderLists: [EKCalendar]? {
        guard hasConfiguredReminderLists else { return nil }
        let identifiers = selectedReminderListIdentifiers
        return reminderService.reminderLists.filter { identifiers.contains($0.calendarIdentifier) }
    }
    
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
        
        // Auswahl aus UserDefaults laden
        loadSelections()
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
            // Kalender-Events laden (gefiltert nach Auswahl)
            let calendarEvents = calendarService.fetchFamilyEvents(
                from: currentWeekStart,
                to: weekEndDate,
                calendars: selectedCalendars
            )
            
            // Erinnerungen laden (mit expandierten Wiederholungen, gefiltert nach Auswahl)
            let reminderEvents = await reminderService.fetchAllFamilyEvents(
                from: currentWeekStart,
                to: weekEndDate,
                lists: selectedReminderLists
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
