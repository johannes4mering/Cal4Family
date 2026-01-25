//
//  ReminderService.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import EventKit
import Combine

/// Service für den Zugriff auf Apple Erinnerungen via EventKit
@MainActor
final class ReminderService: ObservableObject {
    private let eventStore = EKEventStore()
    private var notificationObserver: NSObjectProtocol?
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var reminderLists: [EKCalendar] = []
    @Published var error: Error?
    
    /// Triggered when external changes occur (e.g., from Apple Reminders app)
    @Published var externalChangeOccurred: Bool = false
    
    init() {
        updateAuthorizationStatus()
        // Load lists if already authorized
        if authorizationStatus == .fullAccess {
            loadReminderLists()
        }
        setupNotificationObserver()
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNotificationObserver() {
        // Listen for changes from Apple Reminders app
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
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }
    
    /// Fordert Zugriff auf Erinnerungen an (iOS 17+ Full Access)
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            updateAuthorizationStatus()
            if granted {
                loadReminderLists()
            }
            return granted
        } catch {
            self.error = error
            return false
        }
    }
    
    // MARK: - Listen laden
    
    func loadReminderLists() {
        reminderLists = eventStore.calendars(for: .reminder)
    }
    
    /// Gibt die Standard-Erinnerungsliste zurück
    func defaultReminderList() -> EKCalendar? {
        return eventStore.defaultCalendarForNewReminders()
    }
    
    // MARK: - Erinnerungen laden
    
    /// Lädt alle Erinnerungen aus einer Liste (erledigt und unerledigt)
    func fetchAllRemindersFromList(_ list: EKCalendar) async -> [EKReminder] {
        let predicate = eventStore.predicateForReminders(in: [list])
        
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
    
    /// Lädt heutige Erinnerungen aus einer Liste (für Routinen)
    /// Zeigt: Unerledigte für heute + Heute erledigte
    func fetchTodaysReminders(from list: EKCalendar) async -> [EKReminder] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Hole alle unerledigten die heute oder früher fällig sind
        let incompletePredicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: endOfDay,
            calendars: [list]
        )
        
        // Hole alle erledigten von heute
        let completedPredicate = eventStore.predicateForCompletedReminders(
            withCompletionDateStarting: startOfDay,
            ending: endOfDay,
            calendars: [list]
        )
        
        async let incompleteReminders = withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
            eventStore.fetchReminders(matching: incompletePredicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        async let completedReminders = withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
            eventStore.fetchReminders(matching: completedPredicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        let (incomplete, completed) = await (incompleteReminders, completedReminders)
        
        // Kombiniere und entferne Duplikate
        var seen = Set<String>()
        var result: [EKReminder] = []
        
        for reminder in incomplete + completed {
            if !seen.contains(reminder.calendarItemIdentifier) {
                seen.insert(reminder.calendarItemIdentifier)
                result.append(reminder)
            }
        }
        
        return result
    }
    
    /// Lädt alle nicht abgeschlossenen Erinnerungen aus einer Liste
    func fetchIncompleteReminders(from list: EKCalendar) async -> [EKReminder] {
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: [list]
        )
        
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
    
    /// Lädt Erinnerungen für einen Zeitraum
    func fetchReminders(
        from startDate: Date,
        to endDate: Date,
        lists: [EKCalendar]? = nil
    ) async -> [EKReminder] {
        let selectedLists = lists ?? reminderLists
        
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: startDate,
            ending: endDate,
            calendars: selectedLists
        )
        
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
    
    /// Lädt alle Erinnerungen (auch abgeschlossene) für einen Zeitraum
    func fetchAllReminders(
        from startDate: Date,
        to endDate: Date,
        lists: [EKCalendar]? = nil
    ) async -> [EKReminder] {
        let selectedLists = lists ?? reminderLists
        
        let predicate = eventStore.predicateForReminders(in: selectedLists)
        
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let filtered = (reminders ?? []).filter { reminder in
                    guard let dueDate = reminder.dueDateComponents?.date else { return false }
                    return dueDate >= startDate && dueDate <= endDate
                }
                continuation.resume(returning: filtered)
            }
        }
    }
    
    /// Konvertiert Erinnerungen zu FamilyEvents
    func fetchFamilyEvents(
        from startDate: Date,
        to endDate: Date,
        lists: [EKCalendar]? = nil
    ) async -> [FamilyEvent] {
        let reminders = await fetchReminders(from: startDate, to: endDate, lists: lists)
        return reminders.map { FamilyEvent.from(reminder: $0) }
    }
    
    // MARK: - Erinnerungen verwalten
    
    /// Setzt eine Erinnerung auf erledigt/nicht erledigt
    func toggleCompletion(for reminder: EKReminder) throws {
        reminder.isCompleted = !reminder.isCompleted
        if reminder.isCompleted {
            reminder.completionDate = Date()
        } else {
            reminder.completionDate = nil
        }
        try eventStore.save(reminder, commit: true)
    }
    
    /// Setzt eine Erinnerung auf erledigt anhand der ID
    func setCompleted(reminderIdentifier: String, completed: Bool) async throws {
        guard let reminder = await fetchReminder(withIdentifier: reminderIdentifier) else {
            throw ReminderError.reminderNotFound
        }
        
        reminder.isCompleted = completed
        reminder.completionDate = completed ? Date() : nil
        try eventStore.save(reminder, commit: true)
    }
    
    /// Lädt eine einzelne Erinnerung anhand der ID
    func fetchReminder(withIdentifier identifier: String) async -> EKReminder? {
        return eventStore.calendarItem(withIdentifier: identifier) as? EKReminder
    }
    
    // MARK: - Erinnerungen erstellen
    
    /// Erstellt eine neue Erinnerung
    func createReminder(
        title: String,
        dueDate: Date,
        in list: EKCalendar,
        notes: String? = nil
    ) throws -> EKReminder {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = list
        reminder.notes = notes
        
        let dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )
        reminder.dueDateComponents = dueDateComponents
        
        // Alarm hinzufügen
        let alarm = EKAlarm(absoluteDate: dueDate)
        reminder.addAlarm(alarm)
        
        try eventStore.save(reminder, commit: true)
        return reminder
    }
    
    // MARK: - Listen finden
    
    /// Findet eine Liste anhand ihrer ID
    func list(withIdentifier identifier: String) -> EKCalendar? {
        return reminderLists.first { $0.calendarIdentifier == identifier }
    }
    
    /// Findet Listen anhand des Titels
    func lists(withTitle title: String) -> [EKCalendar] {
        return reminderLists.filter { $0.title.localizedCaseInsensitiveContains(title) }
    }
}

// MARK: - Errors
enum ReminderError: LocalizedError {
    case reminderNotFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .reminderNotFound:
            return "Erinnerung nicht gefunden"
        case .saveFailed:
            return "Speichern fehlgeschlagen"
        }
    }
}
