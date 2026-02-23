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
    @Published var selectedListIdentifiers: Set<String> = []
    @Published var activeLists: [EKCalendar] = []
    @Published var routines: [RoutineItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showCompleted: Bool = false

    private let selectedRemindersKey = "selectedReminderListIdentifiers"
    
    /// Fällige Routinen: Uhrzeit jetzt oder vorher, oder ganztägig – und nicht erledigt
    var dueRoutines: [RoutineItem] {
        routines.filter { $0.section == .due }
    }
    
    /// Kommende Routinen: Uhrzeit noch in der Zukunft – und nicht erledigt
    var upcomingRoutines: [RoutineItem] {
        routines.filter { $0.section == .upcoming }
    }
    
    /// Heute abgeschlossene Routinen
    var completedRoutines: [RoutineItem] {
        routines.filter { $0.section == .completed }
    }
    
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
    
    /// Wurden in den Einstellungen Listen konfiguriert? (Key existiert in UserDefaults)
    var hasConfiguredLists: Bool {
        UserDefaults.standard.object(forKey: selectedRemindersKey) != nil
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

        loadSelectedListIdentifiers()

        if !hasConfiguredLists {
            // Nie konfiguriert: Alle Listen anzeigen (Erststart-Default)
            activeLists = routineLists
        } else {
            // Explizit konfiguriert: Nur gewählte Listen (kann auch leer sein)
            activeLists = routineLists.filter { selectedListIdentifiers.contains($0.calendarIdentifier) }
        }

        Task { await loadRoutines() }
    }
    
    func loadRoutines() async {
        isLoading = true
        error = nil

        if activeLists.isEmpty {
            routines = []
            isLoading = false
            return
        }

        var reminders: [EKReminder] = []
        for list in activeLists {
            print("📝 Lade Routinen aus Liste: \(list.title)")
            let listReminders = await reminderService.fetchTodaysReminders(from: list)
            reminders.append(contentsOf: listReminders)
        }

        print("📝 Gefundene Erinnerungen für heute: \(reminders.count)")
        
        // Konvertiere zu RoutineItems mit stabiler Sortierung:
        // 1. Nach Uhrzeit aufsteigend
        // 2. Einträge ohne Uhrzeit (ganztägig) ans Ende
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
            
            // Einer ohne Uhrzeit → der kommt ans Ende
            if hour1 == nil { return false }
            if hour2 == nil { return true }
            
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

    private func loadSelectedListIdentifiers() {
        if let saved = UserDefaults.standard.array(forKey: selectedRemindersKey) as? [String] {
            selectedListIdentifiers = Set(saved)
        } else {
            selectedListIdentifiers = []
        }
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

    var activeListTitleSummary: String {
        guard !activeLists.isEmpty else { return String(localized: "no_lists_selected") }

        if activeLists.count == 1 {
            return activeLists[0].title
        }

        let titles = activeLists.map { $0.title }
        let listsLabel = String(localized: "lists_label")
        if titles.count <= 2 {
            return "\(listsLabel): \(titles.joined(separator: ", "))"
        }

        let leading = titles.prefix(2).joined(separator: ", ")
        return "\(listsLabel): \(leading) + \(titles.count - 2)"
    }
}

// MARK: - Routine Section

enum RoutineSection: String, CaseIterable {
    case due       // Fällig (jetzt/überfällig/ganztägig)
    case upcoming  // Kommend (Uhrzeit in der Zukunft)
    case completed // Abgeschlossen
    
    var title: String {
        switch self {
        case .due: return String(localized: "section_due")
        case .upcoming: return String(localized: "section_upcoming")
        case .completed: return String(localized: "section_completed")
        }
    }
    
    var icon: String {
        switch self {
        case .due: return "exclamationmark.circle.fill"
        case .upcoming: return "clock.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .due: return .red
        case .upcoming: return .blue
        case .completed: return .green
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
    let hasTime: Bool      // Hat die Erinnerung eine explizite Uhrzeit?
    let priority: Int
    let hasRecurrence: Bool
    let listName: String
    let sortIndex: Int  // Stabiler Sortier-Index
    
    /// Berechnet die Sektion basierend auf Status und Uhrzeit
    var section: RoutineSection {
        if isCompleted {
            return .completed
        }
        // Ganztägig (keine Uhrzeit) → immer fällig
        guard hasTime, let dueDate = dueDate else {
            return .due
        }
        // Uhrzeit in der Vergangenheit oder jetzt → fällig
        if dueDate <= Date() {
            return .due
        }
        return .upcoming
    }
    
    /// Emoji basierend auf Titel – DE/EN/IT
    var emoji: String {
        let t = title.lowercased()
        
        // 🪥 Zähne putzen / Brush teeth / Denti
        if t.contains("zähne") || t.contains("zahn") ||
           t.contains("teeth") || t.contains("brush") ||
           t.contains("denti") || t.contains("spazzolin") {
            return "🪥"
        // 💊 Tablette / Medicine / Medicina
        } else if t.contains("tablette") || t.contains("medikament") || t.contains("pille") ||
                  t.contains("medicine") || t.contains("tablet") || t.contains("pill") ||
                  t.contains("farmaco") || t.contains("compressa") || t.contains("medicinale") {
            return "💊"
        // 👕 Anziehen / Get dressed / Vestirsi
        } else if t.contains("anzieh") || t.contains("kleid") ||
                  t.contains("dress") || t.contains("cloth") || t.contains("wear") || t.contains("shirt") ||
                  t.contains("vestir") || t.contains("abbigliam") {
            return "👕"
        // 🧥 Jacke / Jacket / Giacca
        } else if t.contains("jacke") || t.contains("mantel") ||
                  t.contains("jacket") || t.contains("coat") ||
                  t.contains("giacca") || t.contains("cappotto") {
            return "🧥"
        // 🍳 Frühstück / Breakfast / Colazione
        } else if t.contains("frühstück") ||
                  t.contains("breakfast") ||
                  t.contains("colazione") {
            return "🍳"
        // 🍽️ Essen / Meal / Pasto
        } else if t.contains("essen") || t.contains("mittag") || t.contains("abendessen") ||
                  t.contains("meal") || t.contains("lunch") || t.contains("dinner") || t.contains("eat") || t.contains("food") ||
                  t.contains("mangiare") || t.contains("pranzo") || t.contains("cena") || t.contains("pasto") {
            return "🍽️"
        // 🎒 Schule / School / Scuola
        } else if t.contains("schul") || t.contains("ranzen") || t.contains("tasche") ||
                  t.contains("school") || t.contains("backpack") || t.contains("bag") ||
                  t.contains("scuola") || t.contains("zaino") || t.contains("borsa") {
            return "🎒"
        // 🛏️ Schlafen / Sleep / Dormire
        } else if t.contains("bett") || t.contains("schlaf") ||
                  t.contains("bed") || t.contains("sleep") ||
                  t.contains("letto") || t.contains("dormire") || t.contains("sonno") {
            return "🛏️"
        // 🚿 Duschen / Shower / Doccia
        } else if t.contains("dusch") || t.contains("wasch") || t.contains("bad") ||
                  t.contains("shower") || t.contains("wash") || t.contains("bath") ||
                  t.contains("doccia") || t.contains("bagno") || t.contains("lavare") {
            return "🚿"
        // 📚 Hausaufgaben / Homework / Compiti
        } else if t.contains("hausaufgab") || t.contains("lernen") ||
                  t.contains("homework") || t.contains("study") || t.contains("learn") ||
                  t.contains("compiti") || t.contains("studiare") || t.contains("lezione") {
            return "📚"
        // ✏️ Schreiben / Write / Scrivere
        } else if t.contains("schreib") || t.contains("stift") || t.contains("zeich") ||
                  t.contains("write") || t.contains("draw") || t.contains("pen") || t.contains("pencil") ||
                  t.contains("scriv") || t.contains("penna") || t.contains("disegn") {
            return "✏️"
        // 🧹 Aufräumen / Tidy up / Riordinare
        } else if t.contains("aufräum") || t.contains("zimmer") ||
                  t.contains("clean") || t.contains("tidy") || t.contains("room") ||
                  t.contains("pulire") || t.contains("ordine") || t.contains("stanza") || t.contains("camera") {
            return "🧹"
        // 📖 Lesen / Read / Leggere
        } else if t.contains("lesen") || t.contains("buch") ||
                  t.contains("read") || t.contains("book") ||
                  t.contains("legger") || t.contains("libro") {
            return "📖"
        // 🎮 Spielen / Play / Giocare
        } else if t.contains("spielen") || t.contains("spiel") ||
                  t.contains("play") || t.contains("game") ||
                  t.contains("giocare") || t.contains("gioco") {
            return "🎮"
        // ⚽ Sport / Exercise / Sport
        } else if t.contains("sport") || t.contains("bewegung") || t.contains("turnen") ||
                  t.contains("exercise") || t.contains("gym") || t.contains("workout") ||
                  t.contains("esercizio") || t.contains("palestra") || t.contains("allenamento") {
            return "⚽"
        // 🎵 Musik / Music / Musica
        } else if t.contains("musik") || t.contains("üben") || t.contains("instrument") ||
                  t.contains("music") || t.contains("practice") ||
                  t.contains("musica") || t.contains("suonare") || t.contains("strumento") {
            return "🎵"
        // 💧 Trinken / Drink / Bere
        } else if t.contains("trinken") || t.contains("wasser") ||
                  t.contains("drink") || t.contains("water") ||
                  t.contains("bere") || t.contains("acqua") {
            return "💧"
        // 🐕 Hund / Dog / Cane
        } else if t.contains("hund") || t.contains("tier") || t.contains("katze") ||
                  t.contains("dog") || t.contains("animal") || t.contains("pet") || t.contains("cat") ||
                  t.contains("cane") || t.contains("animale") || t.contains("gatto") {
            return "🐕"
        } else {
            return "✨"
        }
    }
    
    static func from(reminder: EKReminder, sortIndex: Int = 0) -> RoutineItem {
        // Prüfe ob eine explizite Uhrzeit gesetzt ist
        let hasExplicitTime = reminder.dueDateComponents?.hour != nil
        
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
            hasTime: hasExplicitTime,
            priority: reminder.priority,
            hasRecurrence: reminder.hasRecurrenceRules,
            listName: reminder.calendar?.title ?? "",
            sortIndex: sortIndex
        )
    }
}
