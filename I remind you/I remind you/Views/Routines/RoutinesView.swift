//
//  RoutinesView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI
import EventKit

/// Kindgerechte Routinen-Ansicht mit großen Abhak-Buttons
struct RoutinesView: View {
    @StateObject private var viewModel: RoutinesViewModel
    @State private var showListPicker = false
    @State private var showAddRoutine = false
    @State private var celebrateCompletion = false
    
    init(reminderService: ReminderService) {
        _viewModel = StateObject(wrappedValue: RoutinesViewModel(reminderService: reminderService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Laden...")
                    Spacer()
                } else if viewModel.routines.isEmpty {
                    emptyState
                } else {
                    // Routinen-Liste
                    routinesList
                }
            }
            .navigationTitle("Routinen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            showAddRoutine = true
                        } label: {
                            Label("Neu", systemImage: "plus")
                        }
                        
                        Button {
                            showListPicker = true
                        } label: {
                            Label("Liste", systemImage: "list.bullet")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddRoutine) {
                AddRoutineView(
                    reminderService: viewModel.reminderService,
                    onSave: {
                        // Reload after adding new routine
                        viewModel.loadRoutineLists()
                    }
                )
            }
            .sheet(isPresented: $showListPicker) {
                listPickerSheet
            }
            .onAppear {
                // Bei jedem Erscheinen neu laden (auch nach Tab-Wechsel)
                viewModel.loadRoutineLists()
            }
            .refreshable {
                viewModel.loadRoutineLists()
            }
            .onReceive(viewModel.reminderService.$externalChangeOccurred) { changed in
                if changed {
                    Task {
                        viewModel.loadRoutineLists()
                        viewModel.reminderService.externalChangeOccurred = false
                    }
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
                    // Nach 3 Sekunden ausblenden
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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
            if let list = viewModel.selectedList {
                Text(list.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
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
        .background(Color(.secondarySystemBackground))
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
            LazyVStack(spacing: 12) {
                ForEach(viewModel.routines) { routine in
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
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("Keine Routinen", systemImage: "checklist")
        } description: {
            Text("Erstelle Erinnerungen in einer Liste mit \"Routine\" im Namen")
        } actions: {
            Button("Liste wählen") {
                showListPicker = true
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - List Picker
    
    private var listPickerSheet: some View {
        NavigationStack {
            List(viewModel.routineLists, id: \.calendarIdentifier) { list in
                Button {
                    viewModel.selectList(list)
                    showListPicker = false
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(cgColor: list.cgColor ?? CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)))
                            .frame(width: 12, height: 12)
                        Text(list.title)
                        Spacer()
                        if list.calendarIdentifier == viewModel.selectedList?.calendarIdentifier {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Liste wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        showListPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
            // Haptic Feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
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
                    
                    if let dueDate = routine.dueDate {
                        HStack(spacing: 4) {
                            Text(dueDate, style: .date)
                            Text("-")
                            Text(dueDate, style: .time)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    } else {
                        Text("Kein Datum/Uhrzeit")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
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
                    .fill(routine.isCompleted ? Color.green.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(routine.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(routine.title), \(routine.isCompleted ? "erledigt" : "offen")")
        .accessibilityHint("Doppeltippen zum \(routine.isCompleted ? "als offen markieren" : "abhaken")")
    }
}

#Preview {
    RoutinesView(reminderService: ReminderService())
}
