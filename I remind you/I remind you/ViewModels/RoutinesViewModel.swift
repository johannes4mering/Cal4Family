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
        
        print("📋 ReminderService hat \(reminderService.reminderLists.count) Listen")
        for list in reminderService.reminderLists {
            print("   - \(list.title)")
        }
        
        // Filtere Listen die typische Routine-Schlüsselwörter enthalten
        let routineKeywords = ["routine", "morgen", "abend", "kind", "paul", "emma", "lisa", "max", "morning", "evening"]
        
        routineLists = reminderService.reminderLists.filter { list in
            routineKeywords.contains { keyword in
                list.title.localizedCaseInsensitiveContains(keyword)
            }
        }
        
        print("📋 Gefilterte Routine-Listen: \(routineLists.count)")
        for list in routineLists {
            print("   - \(list.title)")
        }
        
        // Falls keine gefunden, zeige alle Listen zur Auswahl
        if routineLists.isEmpty {
            routineLists = reminderService.reminderLists
            print("📋 Keine Routine-Listen gefunden, zeige alle \(routineLists.count) Listen")
        }
        
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
        
        // Hole ALLE Erinnerungen aus der Liste (erledigt + unerledigt)
        let reminders = await reminderService.fetchAllRemindersFromList(list)
        
        print("📝 Gefundene Erinnerungen: \(reminders.count)")
        
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
        RoutineItem(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "Aufgabe",
            isCompleted: reminder.isCompleted,
            reminderIdentifier: reminder.calendarItemIdentifier,
            dueDate: reminder.dueDateComponents?.date,
            priority: reminder.priority,
            hasRecurrence: reminder.hasRecurrenceRules
        )
    }
}
