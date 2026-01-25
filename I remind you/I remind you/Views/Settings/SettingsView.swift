//
//  SettingsView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI
import SwiftData
import EventKit

/// Einstellungen: Kalender, Listen, Auto-Regeln
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showAddRuleSheet = false
    @State private var showShareListSheet = false
    
    init(calendarService: CalendarService, reminderService: ReminderService, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            calendarService: calendarService,
            reminderService: reminderService,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Kalender-Sektion
                calendarsSection
                
                // Erinnerungslisten-Sektion
                reminderListsSection
                
                // Familien-Sektion
                familyShareSection
                
                // Auto-Regeln-Sektion
                autoRulesSection
                
                // Info-Sektion
                infoSection
            }
            .navigationTitle("Einstellungen")
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $showAddRuleSheet) {
                AddRuleSheet(
                    calendars: viewModel.calendars,
                    reminderLists: viewModel.reminderLists,
                    onSave: { rule in
                        viewModel.addRule(rule)
                    }
                )
            }
            .sheet(isPresented: $showShareListSheet) {
                ShareListView(reminderService: viewModel.reminderService)
            }
        }
    }
    
    // MARK: - Kalender-Sektion
    
    private var calendarsSection: some View {
        Section {
            if viewModel.calendars.isEmpty {
                Text("Keine Kalender verfügbar")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.calendars, id: \.calendarIdentifier) { calendar in
                    CalendarRow(
                        calendar: calendar,
                        isSelected: viewModel.isCalendarSelected(calendar),
                        onToggle: { viewModel.toggleCalendar(calendar) }
                    )
                }
            }
        } header: {
            Label("Kalender", systemImage: "calendar")
        } footer: {
            Text("Ausgewählte Kalender werden in der Wochenansicht angezeigt")
        }
    }
    
    // MARK: - Erinnerungslisten-Sektion
    
    private var reminderListsSection: some View {
        Section {
            if viewModel.reminderLists.isEmpty {
                Text("Keine Listen verfügbar")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.reminderLists, id: \.calendarIdentifier) { list in
                    ReminderListRow(
                        list: list,
                        isSelected: viewModel.isReminderListSelected(list),
                        onToggle: { viewModel.toggleReminderList(list) }
                    )
                }
            }
        } header: {
            Label("Erinnerungslisten", systemImage: "checklist")
        } footer: {
            Text("Ausgewählte Listen werden in der Wochenansicht angezeigt")
        }
    }
    
    // MARK: - Familien-Sektion
    
    private var familyShareSection: some View {
        Section {
            Button {
                showShareListSheet = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Listen mit Familie teilen")
                            .foregroundStyle(.primary)
                        Text("Routinen für Kinder vorbereiten")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.purple)
                }
            }
        } header: {
            Label("Familie", systemImage: "heart.fill")
        } footer: {
            Text("Teile Erinnerungslisten über iCloud mit deiner Familie")
        }
    }
    
    // MARK: - Auto-Regeln-Sektion
    
    private var autoRulesSection: some View {
        Section {
            if viewModel.autoRules.isEmpty {
                Text("Keine Regeln erstellt")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.autoRules) { rule in
                    AutoRuleRow(
                        rule: rule,
                        calendars: viewModel.calendars,
                        reminderLists: viewModel.reminderLists,
                        onToggle: { viewModel.toggleRuleEnabled(rule) }
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteRule(viewModel.autoRules[index])
                    }
                }
            }
            
            Button {
                showAddRuleSheet = true
            } label: {
                Label("Neue Regel erstellen", systemImage: "plus.circle.fill")
            }
        } header: {
            Label("Auto-Regeln", systemImage: "wand.and.stars")
        } footer: {
            Text("Erstelle automatisch Erinnerungen aus Kalenderereignissen")
        }
    }
    
    // MARK: - Info-Sektion
    
    private var infoSection: some View {
        Section {
            NavigationLink {
                HelpView()
            } label: {
                Label("Hilfe", systemImage: "questionmark.circle")
            }
            
            HStack {
                Text("Version")
                Spacer()
                Text("0.5.1")
                    .foregroundStyle(.secondary)
            }
            
            Link(destination: URL(string: "https://apple.com")!) {
                HStack {
                    Text("Datenschutz")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            #if DEBUG
            debugSection
            #endif
        } header: {
            Label("Info", systemImage: "info.circle")
        }
    }
    
    #if DEBUG
    @State private var isGeneratingTestData = false
    @State private var isDeletingTestData = false
    @State private var testDataGenerated = false
    @State private var testDataDeleted = false
    
    private var debugSection: some View {
        Group {
            Button {
                generateTestData()
            } label: {
                HStack {
                    Label("Testdaten generieren", systemImage: "ladybug.fill")
                    Spacer()
                    if isGeneratingTestData {
                        ProgressView()
                    } else if testDataGenerated {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .disabled(isGeneratingTestData || isDeletingTestData)
            
            Button(role: .destructive) {
                deleteTestData()
            } label: {
                HStack {
                    Label("Testdaten löschen", systemImage: "trash.fill")
                    Spacer()
                    if isDeletingTestData {
                        ProgressView()
                    } else if testDataDeleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .disabled(isGeneratingTestData || isDeletingTestData)
            
            Text("⚠️ Debug-Modus: Erstellt/Löscht Kalender, Listen und Beispieldaten")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }
    
    private func generateTestData() {
        isGeneratingTestData = true
        testDataGenerated = false
        testDataDeleted = false
        Task {
            let generator = TestDataGenerator()
            await generator.generateAllTestData()
            
            // Services neu laden
            viewModel.loadData()
            
            isGeneratingTestData = false
            testDataGenerated = true
        }
    }
    
    private func deleteTestData() {
        isDeletingTestData = true
        testDataGenerated = false
        testDataDeleted = false
        Task {
            let generator = TestDataGenerator()
            await generator.deleteAllTestData()
            
            // Services neu laden
            viewModel.loadData()
            
            isDeletingTestData = false
            testDataDeleted = true
        }
    }
    #endif
}

// MARK: - Calendar Row

struct CalendarRow: View {
    let calendar: EKCalendar
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(cgColor: calendar.cgColor ?? CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)))
                    .frame(width: 14, height: 14)
                
                Text(calendar.title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .green : .gray.opacity(0.4))
                    .font(.title3)
            }
        }
    }
}

// MARK: - Reminder List Row

struct ReminderListRow: View {
    let list: EKCalendar
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(cgColor: list.cgColor ?? CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)))
                    .frame(width: 14, height: 14)
                
                Text(list.title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .green : .gray.opacity(0.4))
                    .font(.title3)
            }
        }
    }
}

// MARK: - Auto Rule Row

struct AutoRuleRow: View {
    let rule: AutoRule
    let calendars: [EKCalendar]
    let reminderLists: [EKCalendar]
    let onToggle: () -> Void
    
    private var sourceCalendarName: String {
        calendars.first { $0.calendarIdentifier == rule.sourceCalendarIdentifier }?.title ?? "Unbekannt"
    }
    
    private var targetListName: String {
        reminderLists.first { $0.calendarIdentifier == rule.targetListIdentifier }?.title ?? "Unbekannt"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.headline)
                
                Text("\(sourceCalendarName) → \(rule.reminderTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(rule.dayOffset) Tag(e), \(String(format: "%02d:%02d", rule.reminderHour, rule.reminderMinute)) Uhr")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .opacity(rule.isEnabled ? 1 : 0.6)
    }
}

// MARK: - Add Rule Sheet

struct AddRuleSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let calendars: [EKCalendar]
    let reminderLists: [EKCalendar]
    let onSave: (AutoRule) -> Void
    
    @State private var name = ""
    @State private var selectedCalendarId = ""
    @State private var titleContains = ""
    @State private var reminderTitle = ""
    @State private var selectedListId = ""
    @State private var dayOffset = -1
    @State private var reminderTime = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Regel-Name") {
                    TextField("z.B. Müllabfuhr", text: $name)
                }
                
                Section("Auslöser") {
                    Picker("Quell-Kalender", selection: $selectedCalendarId) {
                        Text("Auswählen...").tag("")
                        ForEach(calendars, id: \.calendarIdentifier) { calendar in
                            Text(calendar.title).tag(calendar.calendarIdentifier)
                        }
                    }
                    
                    TextField("Titel enthält (optional)", text: $titleContains)
                }
                
                Section("Erinnerung erstellen") {
                    TextField("Erinnerungstext", text: $reminderTitle)
                        .textInputAutocapitalization(.sentences)
                    
                    Picker("Ziel-Liste", selection: $selectedListId) {
                        Text("Auswählen...").tag("")
                        ForEach(reminderLists, id: \.calendarIdentifier) { list in
                            Text(list.title).tag(list.calendarIdentifier)
                        }
                    }
                    
                    Stepper("Tage vorher: \(abs(dayOffset))", value: $dayOffset, in: -14...0)
                    
                    DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
                
                Section {
                    // Vorschau
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vorschau")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !name.isEmpty && !selectedCalendarId.isEmpty && !reminderTitle.isEmpty {
                            Text("Bei Event in \"\(calendarName)\"")
                            Text("→ Erstelle \"\(reminderTitle)\"")
                            Text("→ \(abs(dayOffset)) Tag(e) vorher um \(timeString)")
                        } else {
                            Text("Fülle alle Felder aus")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .font(.subheadline)
                }
            }
            .navigationTitle("Neue Regel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveRule()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !name.isEmpty && !selectedCalendarId.isEmpty && !reminderTitle.isEmpty && !selectedListId.isEmpty
    }
    
    private var calendarName: String {
        calendars.first { $0.calendarIdentifier == selectedCalendarId }?.title ?? ""
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: reminderTime)
    }
    
    private func saveRule() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        
        let rule = AutoRule(
            name: name,
            sourceCalendarIdentifier: selectedCalendarId,
            titleContains: titleContains.isEmpty ? nil : titleContains,
            reminderTitle: reminderTitle,
            targetListIdentifier: selectedListId,
            dayOffset: dayOffset,
            reminderHour: hour,
            reminderMinute: minute
        )
        
        onSave(rule)
        dismiss()
    }
}

#Preview {
    SettingsView(
        calendarService: CalendarService(),
        reminderService: ReminderService(),
        modelContext: try! ModelContainer(for: AutoRule.self).mainContext
    )
}
