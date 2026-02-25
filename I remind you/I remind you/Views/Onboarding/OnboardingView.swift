//
//  OnboardingView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI
import EventKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
                Text(String(localized: "welcome_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(String(localized: "welcome_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Beschreibung
            Text(String(localized: "onboarding_description"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Status-Anzeige als einfache Checkliste
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "required_permissions"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                PermissionCheckItem(
                    title: String(localized: "calendar_label"),
                    isGranted: calendarAccessGranted
                )
                
                PermissionCheckItem(
                    title: String(localized: "reminders_label"),
                    isGranted: reminderAccessGranted
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
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
        .alert(String(localized: "permission_required_title"), isPresented: $showError) {
            Button(String(localized: "open_settings")) {
                openSystemSettings()
            }
            Button(String(localized: "cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "permission_required_message"))
        }
    }
    
    private func openSystemSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #else
        // macOS Sonoma/Sequoia: Öffne Systemeinstellungen > Datenschutz > Kalender
        // Für macOS 13+ ist der URL-Scheme anders
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
    
    private var buttonTitle: String {
        if canContinue {
            return String(localized: "get_started")
        } else {
            return String(localized: "continue_button")
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
            var calendarOK = calendarAccessGranted
            var reminderOK = reminderAccessGranted
            
            // Erst Kalender anfragen
            if !calendarOK {
                calendarOK = await calendarService.requestAccess()
                await MainActor.run {
                    calendarAccessGranted = calendarOK
                }
            }
            
            // Dann Erinnerungen anfragen
            if !reminderOK {
                reminderOK = await reminderService.requestAccess()
                await MainActor.run {
                    reminderAccessGranted = reminderOK
                }
            }
            
            // Kurz warten, damit iOS den Status aktualisieren kann
            try? await Task.sleep(for: .milliseconds(300))
            
            await MainActor.run {
                isRequestingAccess = false
                
                // Nutze die direkten Rückgabewerte statt System-Check
                // (System-Status kann auf echten Geräten verzögert sein)
                if calendarOK && reminderOK {
                    onComplete()
                } else {
                    // Falls einer false ist, prüfe nochmal System-Status
                    checkExistingPermissions()
                    if canContinue {
                        onComplete()
                    } else {
                        showError = true
                    }
                }
            }
        }
    }
}

// MARK: - Permission Check Item (einfache Checkliste)

struct PermissionCheckItem: View {
    let title: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isGranted ? Color.green : Color.gray.opacity(0.5))
            
            Text(title)
                .foregroundStyle(isGranted ? .primary : .secondary)
        }
    }
}

#Preview {
    OnboardingView(
        calendarService: CalendarService(),
        reminderService: ReminderService(),
        onComplete: {}
    )
}
