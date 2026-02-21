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
                // Erinnerungslisten-Sektion
                reminderListsSection
                
                // Kalender-Sektion
                calendarsSection
                
                // Familien-Sektion
                familyShareSection
                
                // Auto-Regeln-Sektion
                autoRulesSection
                
                // Info-Sektion
                infoSection
            }
            .navigationTitle(String(localized: "settings_title"))
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
                Text(String(localized: "no_calendars"))
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
            Label(String(localized: "calendars_section_header"), systemImage: "calendar")
        } footer: {
            if !viewModel.selectedCalendarIdentifiers.isEmpty {
                Text(String(localized: "calendars_footer_selected"))
            } else if viewModel.calendars.isEmpty {
                Text(String(localized: "calendars_footer_empty"))
            } else {
                Text(String(localized: "calendars_footer_hint"))
            }
        }
    }
    
    // MARK: - Erinnerungslisten-Sektion
    
    private var reminderListsSection: some View {
        Section {
            if viewModel.reminderLists.isEmpty {
                Text(String(localized: "no_lists"))
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
            Label(String(localized: "reminder_lists_section_header"), systemImage: "checklist")
        } footer: {
            if !viewModel.selectedReminderListIdentifiers.isEmpty {
                Text(String(localized: "reminder_lists_footer_selected"))
            } else if viewModel.reminderLists.isEmpty {
                Text(String(localized: "reminder_lists_footer_empty"))
            } else {
                Text(String(localized: "reminder_lists_footer_hint"))
            }
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
                        Text(String(localized: "share_lists"))
                            .foregroundStyle(.primary)
                        Text(String(localized: "share_lists_subtitle"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.purple)
                }
            }
        } header: {
            Label(String(localized: "family_section"), systemImage: "heart.fill")
        } footer: {
            Text(String(localized: "family_share_footer"))
        }
    }
    
    // MARK: - Auto-Regeln-Sektion
    
    private var autoRulesSection: some View {
        Section {
            if viewModel.autoRules.isEmpty {
                Text(String(localized: "no_rules"))
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
                Label(String(localized: "add_new_rule"), systemImage: "plus.circle.fill")
            }
        } header: {
            Label(String(localized: "auto_rules_header"), systemImage: "wand.and.stars")
        } footer: {
            Text(String(localized: "auto_rules_footer"))
        }
    }
    
    // MARK: - Info-Sektion
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showOnboardingAlert = false
    
    private var infoSection: some View {
        Section {
            NavigationLink {
                HelpView()
            } label: {
                Label(String(localized: "help"), systemImage: "questionmark.circle")
            }
            
            Button {
                showOnboardingAlert = true
            } label: {
                Label(String(localized: "show_onboarding"), systemImage: "hand.wave")
                    .foregroundStyle(.primary)
            }
            .alert(String(localized: "show_onboarding_alert_title"), isPresented: $showOnboardingAlert) {
                Button(String(localized: "cancel"), role: .cancel) { }
                Button(String(localized: "show_onboarding_action")) {
                    hasCompletedOnboarding = false
                }
            } message: {
                Text(String(localized: "show_onboarding_message"))
            }
            
            HStack {
                Text(String(localized: "version_label"))
                Spacer()
                Text("0.6.0")
                    .foregroundStyle(.secondary)
            }
            
            Link(destination: URL(string: "https://apple.com")!) {
                HStack {
                    Text(String(localized: "privacy_label"))
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
            Label(String(localized: "info_section"), systemImage: "info.circle")
        }
    }
    
    #if DEBUG
    @State private var isGeneratingTestData = false
    @State private var isDeletingTestData = false
    @State private var testDataGenerated = false
    @State private var testDataDeleted = false
    @State private var showDeleteConfirmation = false
    
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
                showDeleteConfirmation = true
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
            .confirmationDialog(
                "Testdaten wirklich löschen?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Testdaten löschen", role: .destructive) {
                    deleteTestData()
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Folgende Test-Kalender und -Listen werden gelöscht:\n• Test Familie, Test Müllabfuhr, Test Schule, Test Sport\n• Test Paul – Morgenroutine/Abendroutine\n• Test Emma – Routine, Test Haushalt, Test Einkaufen")
            }
            
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
        calendars.first { $0.calendarIdentifier == rule.sourceCalendarIdentifier }?.title ?? String(localized: "unknown_calendar")
    }
    
    private var targetListName: String {
        reminderLists.first { $0.calendarIdentifier == rule.targetListIdentifier }?.title ?? String(localized: "unknown_calendar")
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.headline)
                
                Text("\(sourceCalendarName) → \(rule.reminderTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(String(format: String(localized: "rule_timing_format"), rule.dayOffset, String(format: "%02d:%02d", rule.reminderHour, rule.reminderMinute)))
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
                Section(String(localized: "rule_name_section")) {
                    TextField(String(localized: "rule_name_placeholder"), text: $name)
                }
                
                Section(String(localized: "trigger_section")) {
                    Picker(String(localized: "source_calendar_label"), selection: $selectedCalendarId) {
                        Text(String(localized: "please_select")).tag("")
                        ForEach(calendars, id: \.calendarIdentifier) { calendar in
                            Text(calendar.title).tag(calendar.calendarIdentifier)
                        }
                    }
                    
                    TextField(String(localized: "title_contains_placeholder"), text: $titleContains)
                }
                
                Section(String(localized: "create_reminder_section")) {
                    TextField(String(localized: "reminder_text_placeholder"), text: $reminderTitle)
                        #if os(iOS)
                        .textInputAutocapitalization(.sentences)
                        #endif
                    
                    Picker(String(localized: "target_list_label"), selection: $selectedListId) {
                        Text(String(localized: "please_select")).tag("")
                        ForEach(reminderLists, id: \.calendarIdentifier) { list in
                            Text(list.title).tag(list.calendarIdentifier)
                        }
                    }
                    
                    Stepper(String(format: String(localized: "days_before_stepper_format"), abs(dayOffset)), value: $dayOffset, in: -14...0)
                    
                    DatePicker(String(localized: "reminder_time"), selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
                
                Section {
                    // Vorschau
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "preview"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !name.isEmpty && !selectedCalendarId.isEmpty && !reminderTitle.isEmpty {
                            Text(String(format: String(localized: "preview_event_format"), calendarName))
                            Text(String(format: String(localized: "preview_create_format"), reminderTitle))
                            Text(String(format: String(localized: "preview_timing_format"), abs(dayOffset), timeString))
                        } else {
                            Text(String(localized: "fill_all_fields"))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .font(.subheadline)
                }
            }
            .navigationTitle(String(localized: "new_rule_title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
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
