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
        
        // Konvertiere zu RoutineItems
        routines = reminders
            .sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
            .map { RoutineItem.from(reminder: $0) }
        
        print("📝 Routinen geladen: \(routines.count)")
        
        isLoading = false
    }
    
    func selectList(_ list: EKCalendar) {
        selectedList = list
        Task { await loadRoutines() }
    }
    
    // MARK: - Aktionen
    
    func toggleRoutine(_ routine: RoutineItem) async {
        do {
            try await reminderService.setCompleted(
                reminderIdentifier: routine.reminderIdentifier,
                completed: !routine.isCompleted
            )
            
            // Update lokal
            if let index = routines.firstIndex(where: { $0.id == routine.id }) {
                routines[index].isCompleted.toggle()
            }
        } catch {
            self.error = error
        }
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
    
    static func from(reminder: EKReminder) -> RoutineItem {
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
            hasRecurrence: reminder.hasRecurrenceRules
        )
    }
}
