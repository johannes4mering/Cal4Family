//
//  RoutinesViewModel.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import SwiftUI
import Combine
import EventKit

/// ViewModel für die Routinen-Ansicht
@MainActor
final class RoutinesViewModel: ObservableObject {
    let reminderService: ReminderService
    
    @Published var routineLists: [EKCalendar] = []
    @Published var selectedList: EKCalendar?
    @Published var routines: [RoutineItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    /// Fortschritt: erledigte / gesamt
    var progress: (completed: Int, total: Int) {
        let completed = routines.filter { $0.isCompleted }.count
        return (completed, routines.count)
    }
    
    var progressPercentage: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.completed) / Double(progress.total)
    }
    
    var allDone: Bool {
        progress.total > 0 && progress.completed == progress.total
    }
    
    init(reminderService: ReminderService) {
        self.reminderService = reminderService
    }
    
    // MARK: - Daten laden
    
    func loadRoutineLists() {
        // IMMER neu laden um Änderungen zu erfassen
        reminderService.loadReminderLists()
        
        // Alle Listen anzeigen (keine Filterung)
        routineLists = reminderService.reminderLists
        
        // Wähle erste Liste automatisch wenn noch keine ausgewählt
        if selectedList == nil, let first = routineLists.first {
            print("📋 Wähle automatisch Liste: \(first.title)")
            selectedList = first
            Task { await loadRoutines() }
        } else if let selected = selectedList {
            print("📋 Bereits ausgewählt: \(selected.title)")
            // Trotzdem neu laden falls sich Inhalt geändert hat
            Task { await loadRoutines() }
        }
    }
    
    func loadRoutines() async {
        guard let list = selectedList else { 
            print("⚠️ Keine Liste ausgewählt")
            return 
        }
        
        isLoading = true
        error = nil
        
        print("📝 Lade Routinen aus Liste: \(list.title)")
        
        // Hole nur HEUTIGE Erinnerungen (unerledigt + heute erledigt)
        let reminders = await reminderService.fetchTodaysReminders(from: list)
        
        print("📝 Gefundene Erinnerungen für heute: \(reminders.count)")
        
        // Konvertiere zu RoutineItems mit stabiler Sortierung:
        // 1. Einträge ohne Uhrzeit zuerst
        // 2. Dann nach Uhrzeit
        // 3. Dann alphabetisch nach Titel
        // Wichtig: Sortierung basiert auf stabilen Werten (nicht auf completion status)
        let sortedReminders = reminders.sorted { reminder1, reminder2 in
            let hour1 = reminder1.dueDateComponents?.hour
            let hour2 = reminder2.dueDateComponents?.hour
            let minute1 = reminder1.dueDateComponents?.minute ?? 0
            let minute2 = reminder2.dueDateComponents?.minute ?? 0
            
            // Beide ohne Uhrzeit → alphabetisch
            if hour1 == nil && hour2 == nil {
                return (reminder1.title ?? "").localizedCompare(reminder2.title ?? "") == .orderedAscending
            }
            
            // Einer ohne Uhrzeit → der kommt zuerst
            if hour1 == nil { return true }
            if hour2 == nil { return false }
            
            // Beide mit Uhrzeit → nach Stunde und Minute sortieren
            let time1 = hour1! * 60 + minute1
            let time2 = hour2! * 60 + minute2
            
            if time1 != time2 {
                return time1 < time2
            }
            
            // Gleiche Zeit → alphabetisch
            return (reminder1.title ?? "").localizedCompare(reminder2.title ?? "") == .orderedAscending
        }
        
        // Map mit originalem Index für stabile Sortierung
        routines = sortedReminders.enumerated().map { index, reminder in
            RoutineItem.from(reminder: reminder, sortIndex: index)
        }
        
        print("📝 Routinen geladen: \(routines.count)")
        
        isLoading = false
    }
    
    func selectList(_ list: EKCalendar) {
        selectedList = list
        Task { await loadRoutines() }
    }
    
    // MARK: - Aktionen
    
    /// Flag um zu verhindern, dass externe Änderungen während unseres eigenen Toggles neu laden
    private var isToggling = false
    
    func toggleRoutine(_ routine: RoutineItem) async {
        isToggling = true
        
        do {
            try await reminderService.setCompleted(
                reminderIdentifier: routine.reminderIdentifier,
                completed: !routine.isCompleted
            )
            
            // Update lokal - Position bleibt gleich da sortIndex fix ist
            if let index = routines.firstIndex(where: { $0.id == routine.id }) {
                routines[index].isCompleted.toggle()
            }
        } catch {
            self.error = error
        }
        
        // Kurze Verzögerung bevor externe Änderungen wieder verarbeitet werden
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 Sekunden
        isToggling = false
    }
    
    /// Prüft ob gerade getoggelt wird (für externe Change Handler)
    var isCurrentlyToggling: Bool {
        isToggling
    }
}

// MARK: - Routine Item

struct RoutineItem: Identifiable {
    let id: String
    var title: String
    var isCompleted: Bool
    let reminderIdentifier: String
    let dueDate: Date?
    let priority: Int
    let hasRecurrence: Bool
    let listName: String
    let sortIndex: Int  // Stabiler Sortier-Index
    
    /// Emoji basierend auf Titel
    var emoji: String {
        let lowercased = title.lowercased()
        
        if lowercased.contains("zähne") || lowercased.contains("zahn") {
            return "🪥"
        } else if lowercased.contains("anzieh") || lowercased.contains("kleid") {
            return "👕"
        } else if lowercased.contains("frühstück") || lowercased.contains("essen") {
            return "🍳"
        } else if lowercased.contains("schul") || lowercased.contains("ranzen") || lowercased.contains("tasche") {
            return "🎒"
        } else if lowercased.contains("bett") || lowercased.contains("schlaf") {
            return "🛏️"
        } else if lowercased.contains("dusch") || lowercased.contains("wasch") || lowercased.contains("bad") {
            return "🚿"
        } else if lowercased.contains("hausaufgab") || lowercased.contains("lernen") {
            return "📚"
        } else if lowercased.contains("aufräum") || lowercased.contains("zimmer") {
            return "🧹"
        } else if lowercased.contains("lesen") || lowercased.contains("buch") {
            return "📖"
        } else if lowercased.contains("sport") || lowercased.contains("bewegung") {
            return "⚽"
        } else if lowercased.contains("musik") || lowercased.contains("üben") {
            return "🎵"
        } else if lowercased.contains("hund") || lowercased.contains("tier") {
            return "🐕"
        } else {
            return "✨"
        }
    }
    
    static func from(reminder: EKReminder, sortIndex: Int = 0) -> RoutineItem {
        // Bei wiederkehrenden Erinnerungen: Datum auf HEUTE setzen, Uhrzeit beibehalten
        var displayDate: Date? = nil
        if let dueComps = reminder.dueDateComponents {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Erstelle Datum für heute mit der Uhrzeit aus der Erinnerung
            var todayComps = calendar.dateComponents([.year, .month, .day], from: today)
            todayComps.hour = dueComps.hour
            todayComps.minute = dueComps.minute
            
            if reminder.hasRecurrenceRules {
                // Bei wiederkehrenden: Immer HEUTE + Uhrzeit
                displayDate = calendar.date(from: todayComps)
            } else {
                // Bei einmaligen: Original-Datum verwenden
                displayDate = calendar.date(from: dueComps)
            }
        }
        
        return RoutineItem(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "Aufgabe",
            isCompleted: reminder.isCompleted,
            reminderIdentifier: reminder.calendarItemIdentifier,
            dueDate: displayDate,
            priority: reminder.priority,
            hasRecurrence: reminder.hasRecurrenceRules,
            listName: reminder.calendar?.title ?? "",
            sortIndex: sortIndex
        )
    }
}
