//
//  WeekView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI

/// Hauptansicht: Wochenübersicht mit Terminen und Aufgaben
struct WeekView: View {
    @StateObject private var viewModel: WeekViewModel
    @State private var selectedDate: Date?
    
    init(calendarService: CalendarService, reminderService: ReminderService) {
        _viewModel = StateObject(wrappedValue: WeekViewModel(
            calendarService: calendarService,
            reminderService: reminderService
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Wochen-Navigation
                weekNavigationHeader
                
                // Wochentage
                if viewModel.isLoading {
                    ProgressView("Laden...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    weekContent
                }
            }
            .navigationTitle("Wochenansicht")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Heute") {
                        viewModel.goToCurrentWeek()
                    }
                }
            }
            .task {
                await viewModel.loadEvents()
            }
            .refreshable {
                await viewModel.loadEvents()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var weekNavigationHeader: some View {
        HStack {
            Button(action: viewModel.goToPreviousWeek) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            
            Spacer()
            
            Text(viewModel.weekTitle)
                .font(.headline)
            
            Spacer()
            
            Button(action: viewModel.goToNextWeek) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var weekContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.weekDays, id: \.self) { date in
                    DayCard(
                        date: date,
                        calendarEvents: viewModel.calendarEvents(for: date),
                        tasks: viewModel.tasks(for: date),
                        onToggleTask: { task in
                            Task {
                                await viewModel.toggleTaskCompletion(task)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Day Card

struct DayCard: View {
    let date: Date
    let calendarEvents: [FamilyEvent]
    let tasks: [FamilyEvent]
    let onToggleTask: (FamilyEvent) -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(dayName)
                        .font(.headline)
                        .foregroundStyle(isToday ? .white : .primary)
                    Text(dayNumber)
                        .font(.subheadline)
                        .foregroundStyle(isToday ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isToday {
                    Text("Heute")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white.opacity(0.3)))
                }
            }
            .padding()
            .background(isToday ? Color.accentColor : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Termine
            if !calendarEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Termine", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(calendarEvents) { event in
                        EventRow(event: event)
                    }
                }
            }
            
            // Aufgaben
            if !tasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Aufgaben", systemImage: "checklist")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(tasks) { task in
                        TaskRow(task: task, onToggle: { onToggleTask(task) })
                    }
                }
            }
            
            // Leere Ansicht
            if calendarEvents.isEmpty && tasks.isEmpty {
                Text("Keine Einträge")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: FamilyEvent
    
    private var timeString: String {
        if event.isAllDay {
            return "Ganztägig"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.startDate)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: event.calendarColor) ?? .blue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                Text(timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: FamilyEvent
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : Color(hex: task.calendarColor) ?? .blue)
            }
            .buttonStyle(.plain)
            
            Text(task.title)
                .font(.subheadline)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
            
            Spacer()
            
            if task.type == .routine {
                Image(systemName: "repeat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

#Preview {
    WeekView(
        calendarService: CalendarService(),
        reminderService: ReminderService()
    )
}
