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
    private let reminderService: ReminderService
    
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
        // Filtere Listen die "Routine" im Namen haben oder vom Nutzer ausgewählt wurden
        routineLists = reminderService.reminderLists.filter { list in
            list.title.localizedCaseInsensitiveContains("routine") ||
            list.title.localizedCaseInsensitiveContains("morgen") ||
            list.title.localizedCaseInsensitiveContains("abend") ||
            list.title.localizedCaseInsensitiveContains("kind")
        }
        
        // Falls keine gefunden, zeige alle Listen
        if routineLists.isEmpty {
            routineLists = reminderService.reminderLists
        }
        
        // Wähle erste Liste automatisch
        if selectedList == nil, let first = routineLists.first {
            selectedList = first
            Task { await loadRoutines() }
        }
    }
    
    func loadRoutines() async {
        guard let list = selectedList else { return }
        
        isLoading = true
        error = nil
        
        // Lade Erinnerungen für heute
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        // Hole alle unerledigten Erinnerungen aus der Liste
        let reminders = await reminderService.fetchIncompleteReminders(from: list)
        
        // Konvertiere zu RoutineItems
        routines = reminders
            .sorted { ($0.dueDateComponents?.date ?? Date.distantFuture) < ($1.dueDateComponents?.date ?? Date.distantFuture) }
            .map { RoutineItem.from(reminder: $0) }
        
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
