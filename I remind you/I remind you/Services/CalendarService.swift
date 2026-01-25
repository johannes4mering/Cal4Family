//
//  CalendarService.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import EventKit
import Combine

/// Service für den Zugriff auf Apple Kalender via EventKit
@MainActor
final class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    private var notificationObserver: NSObjectProtocol?
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var calendars: [EKCalendar] = []
    @Published var error: Error?
    
    /// Triggered when external changes occur (e.g., from Apple Calendar app)
    @Published var externalChangeOccurred: Bool = false
    
    init() {
        updateAuthorizationStatus()
        setupNotificationObserver()
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNotificationObserver() {
        // Listen for changes from Apple Calendar app
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.externalChangeOccurred = true
            }
        }
    }
    
    // MARK: - Authorization
    
    private func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    /// Fordert Zugriff auf Kalender an (iOS 17+ Full Access)
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            updateAuthorizationStatus()
            if granted {
                loadCalendars()
            }
            return granted
        } catch {
            self.error = error
            return false
        }
    }
    
    // MARK: - Kalender laden
    
    func loadCalendars() {
        calendars = eventStore.calendars(for: .event)
    }
    
    /// Gibt alle Kalender zurück, die der Nutzer auswählen kann
    func getSelectableCalendars() -> [EKCalendar] {
        return calendars.filter { $0.allowsContentModifications || !$0.isSubscribed }
    }
    
    // MARK: - Events laden
    
    /// Lädt Events für einen Zeitraum aus ausgewählten Kalendern
    func fetchEvents(
        from startDate: Date,
        to endDate: Date,
        calendars: [EKCalendar]? = nil
    ) -> [EKEvent] {
        let selectedCalendars = calendars ?? self.calendars
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: selectedCalendars
        )
        
        return eventStore.events(matching: predicate)
    }
    
    /// Lädt Events für die aktuelle Woche
    func fetchEventsForCurrentWeek(calendars: [EKCalendar]? = nil) -> [EKEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        
        return fetchEvents(from: weekStart, to: weekEnd, calendars: calendars)
    }
    
    /// Konvertiert EKEvents zu FamilyEvents
    func fetchFamilyEvents(
        from startDate: Date,
        to endDate: Date,
        calendars: [EKCalendar]? = nil
    ) -> [FamilyEvent] {
        let events = fetchEvents(from: startDate, to: endDate, calendars: calendars)
        return events.map { FamilyEvent.from(event: $0) }
    }
    
    // MARK: - Kalender finden
    
    /// Findet einen Kalender anhand seiner ID
    func calendar(withIdentifier identifier: String) -> EKCalendar? {
        return calendars.first { $0.calendarIdentifier == identifier }
    }
    
    /// Findet Kalender anhand des Titels
    func calendars(withTitle title: String) -> [EKCalendar] {
        return calendars.filter { $0.title.localizedCaseInsensitiveContains(title) }
    }
}
