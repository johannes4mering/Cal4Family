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
        // WICHTIG: ending ist EXKLUSIV, also endOfDay = morgen 00:00 ist korrekt
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
        
        print("📋 fetchTodaysReminders - incomplete: \(incomplete.count), completed: \(completed.count)")
        for r in incomplete {
            print("   [incomplete] \(r.title ?? "?") - ID: \(r.calendarItemIdentifier) - due: \(String(describing: r.dueDateComponents))")
        }
        for r in completed {
            print("   [completed] \(r.title ?? "?") - ID: \(r.calendarItemIdentifier)")
        }
        
        // Filtere: Nur Erinnerungen die HEUTE fällig sind (nicht morgen!)
        // Bei Erinnerungen ohne Datum: trotzdem anzeigen
        var seen = Set<String>()
        var result: [EKReminder] = []
        
        for reminder in incomplete + completed {
            // Duplikat-Check
            guard !seen.contains(reminder.calendarItemIdentifier) else {
                print("   ⚠️ Duplikat gefunden: \(reminder.title ?? "?")")
                continue
            }
            seen.insert(reminder.calendarItemIdentifier)
            
            // Datum-Check: Nur heute oder früher, NICHT morgen
            if let dueComponents = reminder.dueDateComponents,
               let dueDate = dueComponents.date {
                // Wenn das Fälligkeitsdatum >= morgen ist, überspringen
                if dueDate >= endOfDay {
                    print("   ⏭️ Übersprungen (morgen oder später): \(reminder.title ?? "?") - \(dueDate)")
                    continue
                }
            }
            
            result.append(reminder)
        }
        
        print("📋 fetchTodaysReminders - Ergebnis: \(result.count) (nach Filter)")
        
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
        
        print("📅 fetchReminders: \(startDate) bis \(endDate)")
        print("   Listen: \(selectedLists.map { $0.title })")
        
        // WICHTIG: Wir laden ALLE unerledigten Reminders, nicht nur die mit Datum im Bereich
        // Grund: Erinnerungen ohne Uhrzeit oder mit Datum-only werden sonst nicht gefunden
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,  // Kein Start-Filter
            ending: endDate,           // Nur bis Ende des Zeitraums
            calendars: selectedLists
        )
        
        let reminders = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        print("   Gefunden (vor Filter): \(reminders.count)")
        
        // Manuell filtern: Nur Reminders die im Zeitraum liegen
        let filtered = reminders.filter { reminder in
            guard let dueComponents = reminder.dueDateComponents else {
                print("   ⚠️ Kein Datum: \(reminder.title ?? "?")")
                return false
            }
            
            // Datum aus Components erstellen
            guard let dueDate = Calendar.current.date(from: dueComponents) else {
                print("   ⚠️ Ungültiges Datum: \(reminder.title ?? "?")")
                return false
            }
            
            // Prüfe ob im Zeitraum (startDate <= dueDate < endDate)
            let isInRange = dueDate >= startDate && dueDate < endDate
            
            if isInRange {
                print("   ✅ \(reminder.title ?? "?") - \(dueDate)")
            } else {
                print("   ⏭️ Außerhalb: \(reminder.title ?? "?") - \(dueDate)")
            }
            
            return isInRange
        }
        
        print("   Gefunden (nach Filter): \(filtered.count)")
        
        return filtered
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
    
    // MARK: - Recurring Reminders expandieren
    
    /// Expandiert wiederkehrende Erinnerungen für einen Zeitraum
    /// Erstellt "virtuelle" FamilyEvents für jeden Tag, an dem die Wiederholung zutrifft
    func expandRecurringReminders(
        for dateRange: DateInterval,
        lists: [EKCalendar]? = nil
    ) async -> [FamilyEvent] {
        let selectedLists = lists ?? reminderLists
        guard !selectedLists.isEmpty else { return [] }
        
        // Alle Reminders mit Wiederholungsregeln laden
        let predicate = eventStore.predicateForReminders(in: selectedLists)
        
        let allReminders: [EKReminder] = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        // Nur Reminders mit Wiederholungsregeln
        let recurringReminders = allReminders.filter { $0.hasRecurrenceRules }
        
        var expandedEvents: [FamilyEvent] = []
        let calendar = Calendar.current
        
        // Für jeden Tag im Zeitraum prüfen
        var currentDate = calendar.startOfDay(for: dateRange.start)
        let endDate = calendar.startOfDay(for: dateRange.end)
        
        while currentDate < endDate {
            for reminder in recurringReminders {
                guard let ekRule = reminder.recurrenceRules?.first,
                      let rule = RecurrenceRule.from(ekRule: ekRule),
                      let startDateComponents = reminder.startDateComponents,
                      let reminderStartDate = startDateComponents.date ?? reminder.dueDateComponents?.date else {
                    continue
                }
                
                // Prüfe ob die Regel für diesen Tag zutrifft
                if rule.matches(date: currentDate, startDate: reminderStartDate) {
                    // Erstelle ein "virtuelles" FamilyEvent für diesen Tag
                    let event = FamilyEvent.expandedFrom(
                        reminder: reminder,
                        forDate: currentDate
                    )
                    expandedEvents.append(event)
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return expandedEvents
    }
    
    /// Lädt alle Erinnerungen für einen Zeitraum, inklusive expandierter Wiederholungen
    func fetchAllFamilyEvents(
        from startDate: Date,
        to endDate: Date,
        lists: [EKCalendar]? = nil
    ) async -> [FamilyEvent] {
        let dateRange = DateInterval(start: startDate, end: endDate)
        
        // Normale (nicht-wiederkehrende) Reminders laden
        let normalReminders = await fetchReminders(from: startDate, to: endDate, lists: lists)
        let normalEvents = normalReminders
            .filter { !$0.hasRecurrenceRules }
            .map { FamilyEvent.from(reminder: $0) }
        
        // Wiederkehrende Reminders expandieren
        let expandedEvents = await expandRecurringReminders(for: dateRange, lists: lists)
        
        // Kombinieren und Duplikate entfernen (basierend auf Reminder-ID und Datum)
        var seen = Set<String>()
        var result: [FamilyEvent] = []
        
        for event in normalEvents + expandedEvents {
            let key = "\(event.originalEventIdentifier)_\(Calendar.current.startOfDay(for: event.startDate))"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(event)
            }
        }
        
        return result.sorted { $0.startDate < $1.startDate }
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
        notes: String? = nil,
        recurrence: RecurrenceRule? = nil
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
        
        // Wiederholung hinzufügen
        if let recurrence = recurrence {
            let rule = recurrence.toEKRecurrenceRule()
            reminder.addRecurrenceRule(rule)
        }
        
        try eventStore.save(reminder, commit: true)
        return reminder
    }
    
    /// Erstellt eine neue Erinnerungsliste
    func createReminderList(title: String, color: CGColor? = nil) throws -> EKCalendar {
        let list = EKCalendar(for: .reminder, eventStore: eventStore)
        list.title = title
        
        if let color = color {
            list.cgColor = color
        }
        
        // Quelle finden
        if let source = eventStore.sources.first(where: { $0.sourceType == .local }) ??
                       eventStore.sources.first(where: { $0.sourceType == .calDAV }) ??
                       eventStore.defaultCalendarForNewReminders()?.source {
            list.source = source
        }
        
        try eventStore.saveCalendar(list, commit: true)
        loadReminderLists() // Liste aktualisieren
        return list
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
