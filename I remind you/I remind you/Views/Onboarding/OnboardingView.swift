//
//  OnboardingView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI
import EventKit

/// Onboarding-Ansicht für Berechtigungsanfragen
struct OnboardingView: View {
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var reminderService: ReminderService
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var calendarAccessGranted = false
    @State private var reminderAccessGranted = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon / Illustration
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolEffect(.bounce, value: currentStep)
            
            // Titel
            VStack(spacing: 8) {
                Text("Willkommen bei")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("I remind you")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            // Beschreibung
            Text("Um deine Termine und Aufgaben anzuzeigen, benötigt die App Zugriff auf Kalender und Erinnerungen.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Berechtigungen
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "calendar",
                    title: "Kalender",
                    description: "Termine anzeigen",
                    isGranted: calendarAccessGranted,
                    action: requestCalendarAccess
                )
                
                PermissionRow(
                    icon: "checklist",
                    title: "Erinnerungen",
                    description: "Aufgaben verwalten",
                    isGranted: reminderAccessGranted,
                    action: requestReminderAccess
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Weiter-Button
            Button(action: onComplete) {
                Text("Los geht's")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canContinue)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            checkExistingPermissions()
        }
    }
    
    private var canContinue: Bool {
        calendarAccessGranted && reminderAccessGranted
    }
    
    private func checkExistingPermissions() {
        calendarAccessGranted = calendarService.authorizationStatus == .fullAccess
        reminderAccessGranted = reminderService.authorizationStatus == .fullAccess
    }
    
    private func requestCalendarAccess() {
        Task {
            calendarAccessGranted = await calendarService.requestAccess()
        }
    }
    
    private func requestReminderAccess() {
        Task {
            reminderAccessGranted = await reminderService.requestAccess()
        }
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else {
                Button("Erlauben") {
                    action()
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    OnboardingView(
        calendarService: CalendarService(),
        reminderService: ReminderService(),
        onComplete: {}
    )
}
