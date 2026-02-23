//
//  SettingsViewModel.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import SwiftUI
import Combine
import EventKit
import SwiftData

/// ViewModel für die Einstellungen
@MainActor
final class SettingsViewModel: ObservableObject {
    private let calendarService: CalendarService
    let reminderService: ReminderService
    private let modelContext: ModelContext
    
    @Published var calendars: [EKCalendar] = []
    @Published var selectedCalendarIdentifiers: Set<String> = []
    
    @Published var reminderLists: [EKCalendar] = []
    @Published var selectedReminderListIdentifiers: Set<String> = []
    
    @Published var autoRules: [AutoRule] = []
    
    @Published var isLoading = false
    
    // UserDefaults Keys
    private let selectedCalendarsKey = "selectedCalendarIdentifiers"
    private let selectedRemindersKey = "selectedReminderListIdentifiers"
    
    /// Wurde die Kalender-Auswahl jemals konfiguriert?
    private var hasConfiguredCalendars: Bool {
        UserDefaults.standard.object(forKey: selectedCalendarsKey) != nil
    }
    
    /// Wurde die Listen-Auswahl jemals konfiguriert?
    private var hasConfiguredReminderLists: Bool {
        UserDefaults.standard.object(forKey: selectedRemindersKey) != nil
    }
    
    init(calendarService: CalendarService, reminderService: ReminderService, modelContext: ModelContext) {
        self.calendarService = calendarService
        self.reminderService = reminderService
        self.modelContext = modelContext
        
        loadSavedSelections()
    }
    
    // MARK: - Laden
    
    func loadData() {
        // Ensure services reload their data
        calendarService.loadCalendars()
        reminderService.loadReminderLists()
        
        calendars = calendarService.calendars
        reminderLists = reminderService.reminderLists
        loadAutoRules()
        
        // UserDefaults neu lesen – könnten durch WeekView geändert worden sein
        loadSavedSelections()
    }
    
    private func loadSavedSelections() {
        if let saved = UserDefaults.standard.array(forKey: selectedCalendarsKey) as? [String] {
            selectedCalendarIdentifiers = Set(saved)
        }
        if let saved = UserDefaults.standard.array(forKey: selectedRemindersKey) as? [String] {
            selectedReminderListIdentifiers = Set(saved)
        }
    }
    
    private func loadAutoRules() {
        let descriptor = FetchDescriptor<AutoRule>(sortBy: [SortDescriptor(\.createdAt)])
        do {
            autoRules = try modelContext.fetch(descriptor)
        } catch {
            print("Fehler beim Laden der Regeln: \(error)")
        }
    }
    
    // MARK: - Kalender Auswahl
    
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
        saveCalendarSelection()
    }
    
    func isCalendarSelected(_ calendar: EKCalendar) -> Bool {
        // Nie konfiguriert = alle aktiv (Erststart-Default)
        guard hasConfiguredCalendars else { return true }
        return selectedCalendarIdentifiers.contains(calendar.calendarIdentifier)
    }
    
    private func saveCalendarSelection() {
        UserDefaults.standard.set(Array(selectedCalendarIdentifiers), forKey: selectedCalendarsKey)
    }
    
    // MARK: - Erinnerungslisten Auswahl
    
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
        saveReminderListSelection()
    }
    
    func isReminderListSelected(_ list: EKCalendar) -> Bool {
        // Nie konfiguriert = alle aktiv (Erststart-Default)
        guard hasConfiguredReminderLists else { return true }
        return selectedReminderListIdentifiers.contains(list.calendarIdentifier)
    }
    
    private func saveReminderListSelection() {
        UserDefaults.standard.set(Array(selectedReminderListIdentifiers), forKey: selectedRemindersKey)
    }
    
    // MARK: - Auto-Regeln
    
    func addRule(_ rule: AutoRule) {
        modelContext.insert(rule)
        saveContext()
        loadAutoRules()
    }
    
    func deleteRule(_ rule: AutoRule) {
        modelContext.delete(rule)
        saveContext()
        loadAutoRules()
    }
    
    func toggleRuleEnabled(_ rule: AutoRule) {
        rule.isEnabled.toggle()
        saveContext()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
}
