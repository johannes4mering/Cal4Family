//
//  ShareListView.swift
//  I remind you
//
//  Created for sharing reminder lists with family members
//

import SwiftUI
import EventKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// View zum Teilen von Erinnerungslisten mit Familienmitgliedern
struct ShareListView: View {
    @Environment(\.dismiss) private var dismiss
    let reminderService: ReminderService
    
    @State private var selectedList: EKCalendar?
    @State private var showShareSheet = false
    @State private var showFamilyInstructions = false
    
    private var availableLists: [EKCalendar] {
        reminderService.reminderLists
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Erklärung
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text(String(localized: "share_via_icloud"))
                                .font(.headline)
                        } icon: {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundStyle(.blue)
                        }
                        
                        Text(String(localized: "share_via_icloud_description"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Listen zum Teilen
                Section {
                    if availableLists.isEmpty {
                        Text(String(localized: "no_lists"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableLists, id: \.calendarIdentifier) { list in
                            ListShareRow(
                                list: list,
                                isSelected: selectedList?.calendarIdentifier == list.calendarIdentifier,
                                onSelect: { selectedList = list }
                            )
                        }
                    }
                } header: {
                    Label(String(localized: "select_list_to_share"), systemImage: "checklist")
                } footer: {
                    Text(String(localized: "select_list_footer"))
                }
                
                // Teilen-Aktionen
                if let selected = selectedList {
                    Section {
                        Button {
                            shareViaRemindersApp(list: selected)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "open_in_reminders"))
                                        .font(.body)
                                    Text(String(localized: "open_in_reminders_subtitle"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "arrow.up.forward.app")
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Button {
                            showFamilyInstructions = true
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "family_sharing_instructions"))
                                        .font(.body)
                                    Text(String(localized: "family_sharing_instructions_subtitle"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "person.3.fill")
                                    .foregroundStyle(.purple)
                            }
                        }
                    } header: {
                        Label(String(format: String(localized: "share_list_header_format"), selected.title), systemImage: "square.and.arrow.up")
                    }
                }
                
                // Schnellanleitung
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        InstructionStep(
                            number: 1,
                            icon: "1.circle.fill",
                            title: String(localized: "step_open_list"),
                            description: String(localized: "step_open_list_desc")
                        )
                        
                        InstructionStep(
                            number: 2,
                            icon: "2.circle.fill",
                            title: String(localized: "step_select_list"),
                            description: String(localized: "step_select_list_desc")
                        )
                        
                        InstructionStep(
                            number: 3,
                            icon: "3.circle.fill",
                            title: String(localized: "step_share"),
                            description: String(localized: "step_share_desc")
                        )
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label(String(localized: "quick_guide"), systemImage: "questionmark.circle")
                }
            }
            .navigationTitle(String(localized: "share_lists_title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "done")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showFamilyInstructions) {
                FamilyShareInstructionsView()
            }
        }
    }
    
    private func shareViaRemindersApp(list: EKCalendar) {
        // Öffne die Erinnerungen-App
        // Leider gibt es keinen direkten Deep-Link zu einer spezifischen Liste
        if let url = URL(string: "x-apple-reminderkit://") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #else
            NSWorkspace.shared.open(url)
            #endif
        }
    }
}

// MARK: - Hilfs-Views

struct ListShareRow: View {
    let list: EKCalendar
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Circle()
                    .fill(Color(cgColor: list.cgColor))
                    .frame(width: 12, height: 12)
                
                Text(list.title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if list.isSubscribed {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Detaillierte Anleitung für Familienfreigabe

struct FamilyShareInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.purple)
                        
                        Text(String(localized: "family_sharing_title"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(String(localized: "family_sharing_subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    Divider()
                    
                    // Voraussetzungen
                    instructionSection(
                        title: String(localized: "prerequisites"),
                        icon: "checkmark.shield.fill",
                        color: .green,
                        steps: [
                            String(localized: "instr_prereq_1"),
                            String(localized: "instr_prereq_2"),
                            String(localized: "instr_prereq_3")
                        ]
                    )
                    
                    // Schritt 1
                    instructionSection(
                        title: String(localized: "step_1_create_list"),
                        icon: "plus.circle.fill",
                        color: .blue,
                        steps: [
                            String(localized: "instr_s1_1"),
                            String(localized: "instr_s1_2"),
                            String(localized: "instr_s1_3"),
                            String(localized: "instr_s1_4")
                        ]
                    )
                    
                    // Schritt 2
                    instructionSection(
                        title: String(localized: "step_2_add_routines"),
                        icon: "checklist",
                        color: .orange,
                        steps: [
                            String(localized: "instr_s2_1"),
                            String(localized: "instr_s2_2"),
                            String(localized: "instr_s2_3"),
                            String(localized: "instr_s2_4")
                        ]
                    )
                    
                    // Schritt 3
                    instructionSection(
                        title: String(localized: "step_3_share_with_child"),
                        icon: "square.and.arrow.up",
                        color: .purple,
                        steps: [
                            String(localized: "instr_s3_1"),
                            String(localized: "instr_s3_2"),
                            String(localized: "instr_s3_3"),
                            String(localized: "instr_s3_4")
                        ]
                    )
                    
                    // Schritt 4
                    instructionSection(
                        title: String(localized: "step_4_on_child_device"),
                        icon: "iphone",
                        color: .cyan,
                        steps: [
                            String(localized: "instr_s4_1"),
                            String(localized: "instr_s4_2"),
                            String(localized: "instr_s4_3")
                        ]
                    )
                    
                    // Tipp
                    VStack(alignment: .leading, spacing: 8) {
                        Label(String(localized: "tip"), systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        
                        Text(String(localized: "tip_prepare_routines"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle(String(localized: "family_instructions_title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "done")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func instructionSection(title: String, icon: String, color: Color, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(steps, id: \.self) { step in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                        
                        Text(step)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.leading, 4)
        }
    }
}

#Preview {
    ShareListView(reminderService: ReminderService())
}
