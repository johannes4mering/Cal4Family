//
//  RoutinesView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI
import EventKit

#if canImport(UIKit)
import UIKit
#endif

/// Kindgerechte Routinen-Ansicht mit großen Abhak-Buttons
struct RoutinesView: View {
    @StateObject private var viewModel: RoutinesViewModel
    @State private var celebrateCompletion = false
    
    init(reminderService: ReminderService) {
        _viewModel = StateObject(wrappedValue: RoutinesViewModel(reminderService: reminderService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    progressHeader
                    Spacer()
                    ProgressView("Laden...")
                    Spacer()
                } else if viewModel.routines.isEmpty {
                    emptyState
                } else {
                    // Progress Header nur bei vorhandenen Routinen
                    progressHeader
                    
                    // Routinen-Liste
                    routinesList
                }
            }
            .navigationTitle("Routinen")
            .onAppear {
                // Bei jedem Erscheinen neu laden (auch nach Tab-Wechsel)
                viewModel.loadRoutineLists()
            }
            .refreshable {
                viewModel.loadRoutineLists()
            }
            .onReceive(viewModel.reminderService.$externalChangeOccurred) { changed in
                // Ignoriere externe Änderungen während wir selbst toggeln
                if changed && !viewModel.isCurrentlyToggling {
                    Task {
                        viewModel.loadRoutineLists()
                        viewModel.reminderService.externalChangeOccurred = false
                    }
                } else if changed {
                    // Nur Flag zurücksetzen, nicht neu laden
                    viewModel.reminderService.externalChangeOccurred = false
                }
            }
            .overlay {
                if celebrateCompletion {
                    celebrationOverlay
                }
            }
            .onChange(of: viewModel.allDone) { _, allDone in
                if allDone {
                    withAnimation(.spring(duration: 0.5)) {
                        celebrateCompletion = true
                    }
                    // Nach 1.5 Sekunden ausblenden
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            celebrateCompletion = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Aktuelle Liste
            Text(viewModel.activeListTitleSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Fortschrittsring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: viewModel.progressPercentage)
                    .stroke(
                        viewModel.allDone ? Color.green : Color.accentColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.5), value: viewModel.progressPercentage)
                
                VStack(spacing: 4) {
                    Text("\(viewModel.progress.completed)/\(viewModel.progress.total)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("erledigt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            
            // Motivationstext
            Text(motivationText)
                .font(.headline)
                .foregroundStyle(viewModel.allDone ? .green : .primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.platformSecondarySystemBackground)
    }
    
    private var motivationText: String {
        if viewModel.allDone {
            return "🎉 Super gemacht!"
        } else if viewModel.progressPercentage >= 0.75 {
            return "Fast geschafft!"
        } else if viewModel.progressPercentage >= 0.5 {
            return "Weiter so!"
        } else if viewModel.progressPercentage > 0 {
            return "Guter Start!"
        } else {
            return "Los geht's!"
        }
    }
    
    // MARK: - Routinen Liste
    
    private var routinesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Sektion: Fällig
                if !viewModel.dueRoutines.isEmpty {
                    sectionView(
                        section: .due,
                        routines: viewModel.dueRoutines,
                        isCollapsible: false,
                        isExpanded: .constant(true)
                    )
                }
                
                // Sektion: Kommend
                if !viewModel.upcomingRoutines.isEmpty {
                    sectionView(
                        section: .upcoming,
                        routines: viewModel.upcomingRoutines,
                        isCollapsible: false,
                        isExpanded: .constant(true)
                    )
                }
                
                // Sektion: Abgeschlossen (eingeklappt)
                if !viewModel.completedRoutines.isEmpty {
                    sectionView(
                        section: .completed,
                        routines: viewModel.completedRoutines,
                        isCollapsible: true,
                        isExpanded: $viewModel.showCompleted
                    )
                }
            }
            .padding()
        }
    }
    
    private func sectionView(
        section: RoutineSection,
        routines: [RoutineItem],
        isCollapsible: Bool,
        isExpanded: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            Button {
                if isCollapsible {
                    withAnimation(.spring(duration: 0.3)) {
                        isExpanded.wrappedValue.toggle()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: section.icon)
                        .foregroundStyle(section.color)
                        .font(.title3)
                    
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(routines.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(section.color))
                    
                    Spacer()
                    
                    if isCollapsible {
                        Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
            .disabled(!isCollapsible)
            
            // Section Content
            if isExpanded.wrappedValue {
                ForEach(routines) { routine in
                    RoutineCard(
                        routine: routine,
                        onToggle: {
                            Task {
                                await viewModel.toggleRoutine(routine)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                if !viewModel.hasConfiguredLists {
                    // Erststart: Keine Listen konfiguriert
                    emptyStateSetup
                } else {
                    // Listen konfiguriert, aber heute nichts
                    emptyStateAllClear
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
    }
    
    /// Erststart-Hilfe: Schritt-für-Schritt Anleitung
    private var emptyStateSetup: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
            
            Text("So richtest du Routinen ein")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                helpStep(number: 1, icon: "app.badge.checkmark", title: "Erinnerungen-App öffnen", description: "Erstelle dort eine Liste für dein Kind (z.B. \"Paul – Routine\").")
                
                helpStep(number: 2, icon: "plus.circle", title: "Aufgaben hinzufügen", description: "Füge wiederkehrende Erinnerungen hinzu (z.B. \"Zähne putzen\" täglich um 7:00).")
                
                helpStep(number: 3, icon: "gearshape", title: "Listen hier auswählen", description: "Gehe in die Einstellungen und wähle die Listen aus, die angezeigt werden sollen.")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.platformSecondarySystemBackground)
            )
            
            // Button: Erinnerungen-App öffnen
            openRemindersButton
            
            // Hinweis
            Label("Tipp: Du kannst Listen auch mit der Familie teilen (iCloud).", systemImage: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
    
    /// Alles erledigt / heute keine Einträge
    private var emptyStateAllClear: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            
            Text("Keine Aufgaben für heute")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Alle Erinnerungen für heute sind erledigt – oder es stehen keine an.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            openRemindersButton
        }
    }
    
    /// Einzelner Hilfe-Schritt
    private func helpStep(number: Int, icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundStyle(Color.accentColor)
                        .font(.subheadline)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// Button zum Öffnen der Apple Erinnerungen-App
    private var openRemindersButton: some View {
        Button {
            #if os(iOS)
            if let url = URL(string: "x-apple-reminderkit://") {
                UIApplication.shared.open(url)
            }
            #elseif os(macOS)
            if let url = URL(string: "x-apple-reminderkit://") {
                NSWorkspace.shared.open(url)
            }
            #endif
        } label: {
            Label("Erinnerungen-App öffnen", systemImage: "arrow.up.forward.app")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
    }
    
    // MARK: - Celebration
    
    private var celebrationOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 80))
                
                Text("Alle Aufgaben erledigt!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Toll gemacht!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.3))
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Routine Card

struct RoutineCard: View {
    let routine: RoutineItem
    let onToggle: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic Feedback (nur iOS)
            #if os(iOS)
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            #endif
            
            withAnimation(.spring(duration: 0.3)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(duration: 0.3)) {
                    isPressed = false
                }
            }
            
            onToggle()
        }) {
            routineCardContent
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
    
    private var routineCardContent: some View {
        HStack(spacing: 16) {
            // Emoji
            Text(routine.emoji)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(routine.isCompleted ? Color.green.opacity(0.2) : Color.accentColor.opacity(0.1))
                )
            
            // Titel und Datum/Uhrzeit
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.title)
                        .font(.title3)
                        .fontWeight(.medium)
                        .strikethrough(routine.isCompleted, color: .secondary)
                        .foregroundStyle(routine.isCompleted ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Zeile 1: Uhrzeit oder Ganztägig
                        if routine.hasTime, let dueDate = routine.dueDate {
                            Text(dueDate, style: .time)
                        } else {
                            Text("Ganztägig")
                                .foregroundStyle(.orange)
                        }
                        
                        // Zeile 2: Listenname
                        if !routine.listName.isEmpty {
                            Text(routine.listName)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Checkbox
                Image(systemName: routine.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 44))
                    .foregroundStyle(routine.isCompleted ? .green : .gray.opacity(0.4))
                    .symbolEffect(.bounce, value: routine.isCompleted)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(routine.isCompleted ? Color.green.opacity(0.1) : Color.platformSecondarySystemBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(routine.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
            )
    }
}

#Preview {
    RoutinesView(reminderService: ReminderService())
}
