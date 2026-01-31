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
                            Text("Listen über iCloud teilen")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundStyle(.blue)
                        }
                        
                        Text("Teile Erinnerungslisten mit deiner Familie, um Routinen gemeinsam zu verwalten. Änderungen werden automatisch synchronisiert.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Listen zum Teilen
                Section {
                    if availableLists.isEmpty {
                        Text("Keine Listen verfügbar")
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
                    Label("Liste auswählen", systemImage: "checklist")
                } footer: {
                    Text("Wähle eine Liste, die du teilen möchtest")
                }
                
                // Teilen-Aktionen
                if let selected = selectedList {
                    Section {
                        Button {
                            shareViaRemindersApp(list: selected)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("In Erinnerungen-App öffnen")
                                        .font(.body)
                                    Text("Teilen über die native App")
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
                                    Text("Anleitung: Familienfreigabe")
                                        .font(.body)
                                    Text("So teilst du mit deiner Familie")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "person.3.fill")
                                    .foregroundStyle(.purple)
                            }
                        }
                    } header: {
                        Label("\(selected.title) teilen", systemImage: "square.and.arrow.up")
                    }
                }
                
                // Schnellanleitung
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        InstructionStep(
                            number: 1,
                            icon: "1.circle.fill",
                            title: "Liste öffnen",
                            description: "Öffne die Erinnerungen-App auf deinem Gerät"
                        )
                        
                        InstructionStep(
                            number: 2,
                            icon: "2.circle.fill",
                            title: "Liste auswählen",
                            description: "Tippe auf die Liste, die du teilen möchtest"
                        )
                        
                        InstructionStep(
                            number: 3,
                            icon: "3.circle.fill",
                            title: "Teilen",
                            description: "Tippe auf ... -> Liste teilen -> Wähle Familienmitglieder"
                        )
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Kurzanleitung", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("Listen teilen")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
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
                        
                        Text("Familienfreigabe für Erinnerungen")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("So bereitest du Routinen für dein Kind vor – auch ohne dessen Gerät")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    Divider()
                    
                    // Voraussetzungen
                    instructionSection(
                        title: "Voraussetzungen",
                        icon: "checkmark.shield.fill",
                        color: .green,
                        steps: [
                            "Familienfreigabe muss eingerichtet sein",
                            "Kind muss eine Apple-ID haben (auch mit Kinderkonto)",
                            "iCloud Erinnerungen müssen auf beiden Geräten aktiv sein"
                        ]
                    )
                    
                    // Schritt 1
                    instructionSection(
                        title: "1. Liste erstellen",
                        icon: "plus.circle.fill",
                        color: .blue,
                        steps: [
                            "Öffne die Erinnerungen-App",
                            "Tippe auf \"Liste hinzufügen\"",
                            "Gib einen Namen ein (z.B. \"Morgenroutine\")",
                            "Wähle eine Farbe und ein Symbol"
                        ]
                    )
                    
                    // Schritt 2
                    instructionSection(
                        title: "2. Routinen hinzufügen",
                        icon: "checklist",
                        color: .orange,
                        steps: [
                            "Öffne die neue Liste",
                            "Füge Erinnerungen hinzu (z.B. \"Zähne putzen\")",
                            "Stelle Wiederholungen ein (täglich, wochentags, etc.)",
                            "Optional: Füge Uhrzeiten hinzu"
                        ]
                    )
                    
                    // Schritt 3
                    instructionSection(
                        title: "3. Mit Kind teilen",
                        icon: "square.and.arrow.up",
                        color: .purple,
                        steps: [
                            "Tippe auf ... (oben rechts)",
                            "Wähle \"Liste teilen\"",
                            "Wähle dein Kind aus der Familienfreigabe",
                            "Sende die Einladung"
                        ]
                    )
                    
                    // Schritt 4
                    instructionSection(
                        title: "4. Auf Kinderseite",
                        icon: "iphone",
                        color: .cyan,
                        steps: [
                            "Die Liste erscheint automatisch in der Erinnerungen-App",
                            "In \"I remind you\" wird die Liste im Routinen-Tab sichtbar",
                            "Änderungen werden in Echtzeit synchronisiert"
                        ]
                    )
                    
                    // Tipp
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tipp", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        
                        Text("Du kannst Routinen komplett auf deinem Gerät vorbereiten. Sobald du die Liste teilst, erscheinen alle Einträge automatisch auf dem Gerät deines Kindes.")
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
            .navigationTitle("Anleitung")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
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
