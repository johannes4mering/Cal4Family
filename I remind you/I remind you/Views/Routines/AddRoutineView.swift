//
//  AddRoutineView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI
import EventKit

/// Sheet zum Erstellen einer neuen Routine (Erinnerung mit Wiederholung)
struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    
    let reminderService: ReminderService
    let onSave: () -> Void
    
    @State private var title: String = ""
    @State private var selectedList: EKCalendar?
    @State private var dueTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var selectedWeekdays: Set<RecurrenceRule.Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isSaving: Bool = false
    
    enum RecurrenceType: String, CaseIterable {
        case none = "none"
        case daily = "daily"
        case weekdays = "weekdays"
        case weekly = "weekly"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .none: return String(localized: "recurrence_none", defaultValue: "Keine Wiederholung")
            case .daily: return String(localized: "recurrence_daily", defaultValue: "Täglich")
            case .weekdays: return String(localized: "recurrence_weekdays", defaultValue: "Wochentags (Mo-Fr)")
            case .weekly: return String(localized: "recurrence_weekly", defaultValue: "Wöchentlich")
            case .custom: return String(localized: "recurrence_custom", defaultValue: "Bestimmte Tage")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Titel
                Section {
                    TextField(String(localized: "routine_title_placeholder", defaultValue: "z.B. Zähne putzen"), text: $title)
                        .font(.title3)
                } header: {
                    Label(String(localized: "routine_title", defaultValue: "Aufgabe"), systemImage: "text.cursor")
                }
                
                // Liste auswählen
                Section {
                    Picker(String(localized: "routine_list", defaultValue: "Liste"), selection: $selectedList) {
                        Text(String(localized: "routine_select_list", defaultValue: "Liste wählen")).tag(nil as EKCalendar?)
                        ForEach(reminderService.reminderLists, id: \.calendarIdentifier) { list in
                            HStack {
                                Circle()
                                    .fill(Color(cgColor: list.cgColor ?? CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)))
                                    .frame(width: 10, height: 10)
                                Text(list.title)
                            }
                            .tag(list as EKCalendar?)
                        }
                    }
                } header: {
                    Label(String(localized: "routine_list_header", defaultValue: "In welcher Liste?"), systemImage: "list.bullet")
                }
                
                // Uhrzeit
                Section {
                    DatePicker(
                        String(localized: "routine_time", defaultValue: "Uhrzeit"),
                        selection: $dueTime,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Label(String(localized: "routine_time_header", defaultValue: "Wann?"), systemImage: "clock")
                }
                
                // Wiederholung
                Section {
                    Picker(String(localized: "routine_recurrence", defaultValue: "Wiederholen"), selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Wochentage auswählen bei "Bestimmte Tage"
                    if recurrenceType == .custom {
                        weekdaySelector
                    }
                } header: {
                    Label(String(localized: "routine_recurrence_header", defaultValue: "Wie oft?"), systemImage: "repeat")
                }
                
                // Vorschau
                Section {
                    previewText
                } header: {
                    Label(String(localized: "routine_preview", defaultValue: "Vorschau"), systemImage: "eye")
                }
            }
            .navigationTitle(String(localized: "add_routine_title", defaultValue: "Neue Routine"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel", defaultValue: "Abbrechen")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save", defaultValue: "Speichern")) {
                        saveRoutine()
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .alert(String(localized: "error", defaultValue: "Fehler"), isPresented: $showError) {
                Button(String(localized: "ok", defaultValue: "OK")) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Weekday Selector
    
    private var weekdaySelector: some View {
        HStack(spacing: 8) {
            ForEach(orderedWeekdays, id: \.self) { day in
                Button {
                    toggleWeekday(day)
                } label: {
                    Text(day.shortName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 36, height: 36)
                        .background(selectedWeekdays.contains(day) ? Color.accentColor : Color.gray.opacity(0.2))
                        .foregroundStyle(selectedWeekdays.contains(day) ? .white : .primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var orderedWeekdays: [RecurrenceRule.Weekday] {
        // Montag zuerst (europäisch)
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
    
    private func toggleWeekday(_ day: RecurrenceRule.Weekday) {
        if selectedWeekdays.contains(day) {
            selectedWeekdays.remove(day)
        } else {
            selectedWeekdays.insert(day)
        }
    }
    
    // MARK: - Preview
    
    private var previewText: some View {
        VStack(alignment: .leading, spacing: 4) {
            if title.isEmpty {
                Text(String(localized: "routine_preview_empty", defaultValue: "Gib einen Titel ein"))
                    .foregroundStyle(.secondary)
            } else {
                Text(title)
                    .font(.headline)
                
                let timeString = dueTime.formatted(date: .omitted, time: .shortened)
                let recurrenceString = recurrenceDescription
                
                Text("\(timeString) · \(recurrenceString)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var recurrenceDescription: String {
        switch recurrenceType {
        case .none:
            return String(localized: "recurrence_once", defaultValue: "Einmalig")
        case .daily:
            return String(localized: "recurrence_every_day", defaultValue: "Jeden Tag")
        case .weekdays:
            return String(localized: "recurrence_mon_fri", defaultValue: "Mo–Fr")
        case .weekly:
            return String(localized: "recurrence_every_week", defaultValue: "Jede Woche")
        case .custom:
            if selectedWeekdays.isEmpty {
                return String(localized: "recurrence_select_days", defaultValue: "Tage wählen")
            }
            let sorted = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
            return sorted.map { $0.shortName }.joined(separator: ", ")
        }
    }
    
    // MARK: - Validation
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedList != nil &&
        (recurrenceType != .custom || !selectedWeekdays.isEmpty)
    }
    
    // MARK: - Save
    
    private func saveRoutine() {
        guard let list = selectedList else { return }
        
        isSaving = true
        
        // Fälligkeitsdatum erstellen (heute mit gewählter Uhrzeit)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        guard let dueDate = calendar.date(from: components) else {
            errorMessage = String(localized: "error_invalid_date", defaultValue: "Ungültiges Datum")
            showError = true
            isSaving = false
            return
        }
        
        // Wiederholungsregel erstellen
        let recurrence: RecurrenceRule? = {
            switch recurrenceType {
            case .none:
                return nil
            case .daily:
                return .daily
            case .weekdays:
                return .weekdays
            case .weekly:
                return .weekly
            case .custom:
                return RecurrenceRule(frequency: .weekly, interval: 1, weekdays: selectedWeekdays)
            }
        }()
        
        // Erinnerung erstellen
        do {
            _ = try reminderService.createReminder(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: dueDate,
                in: list,
                recurrence: recurrence
            )
            
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    AddRoutineView(
        reminderService: ReminderService(),
        onSave: { }
    )
}
