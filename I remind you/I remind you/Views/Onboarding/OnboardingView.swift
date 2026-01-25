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
    
    @State private var isRequestingAccess = false
    @State private var calendarAccessGranted = false
    @State private var reminderAccessGranted = false
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon / Illustration
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            
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
            
            // Status-Anzeige
            VStack(spacing: 12) {
                PermissionStatusRow(
                    icon: "calendar",
                    title: "Kalender",
                    isGranted: calendarAccessGranted
                )
                
                PermissionStatusRow(
                    icon: "checklist",
                    title: "Erinnerungen",
                    isGranted: reminderAccessGranted
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Einziger Aktions-Button
            Button(action: handleButtonTap) {
                HStack {
                    if isRequestingAccess {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(buttonTitle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isRequestingAccess)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            checkExistingPermissions()
        }
        .alert("Berechtigung erforderlich", isPresented: $showError) {
            Button("Einstellungen öffnen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Bitte erlaube den Zugriff auf Kalender und Erinnerungen in den Einstellungen.")
        }
    }
    
    private var buttonTitle: String {
        if canContinue {
            return "Los geht's"
        } else if !calendarAccessGranted {
            return "Zugriff erlauben"
        } else {
            return "Zugriff erlauben"
        }
    }
    
    private var canContinue: Bool {
        calendarAccessGranted && reminderAccessGranted
    }
    
    private func checkExistingPermissions() {
        calendarAccessGranted = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        reminderAccessGranted = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
    }
    
    private func handleButtonTap() {
        if canContinue {
            onComplete()
        } else {
            requestAllPermissions()
        }
    }
    
    private func requestAllPermissions() {
        isRequestingAccess = true
        
        Task {
            // Erst Kalender
            if !calendarAccessGranted {
                let granted = await calendarService.requestAccess()
                await MainActor.run {
                    calendarAccessGranted = granted
                }
            }
            
            // Dann Erinnerungen
            if !reminderAccessGranted {
                let granted = await reminderService.requestAccess()
                await MainActor.run {
                    reminderAccessGranted = granted
                }
            }
            
            await MainActor.run {
                isRequestingAccess = false
                
                // Prüfe nochmal den echten Status
                checkExistingPermissions()
                
                // Wenn immer noch nicht alle Berechtigungen, zeige Fehler
                if !canContinue {
                    showError = true
                }
            }
        }
    }
}

// MARK: - Permission Status Row (nur Anzeige, kein Button)

struct PermissionStatusRow: View {
    let icon: String
    let title: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(isGranted ? Color.green.opacity(0.1) : Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(isGranted ? Color.green : Color.accentColor)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isGranted ? .green : .secondary)
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
