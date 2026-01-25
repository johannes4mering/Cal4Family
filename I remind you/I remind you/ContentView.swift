//
//  ContentView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @StateObject private var calendarService = CalendarService()
    @StateObject private var reminderService = ReminderService()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding && hasRequiredPermissions {
                MainTabView(
                    calendarService: calendarService,
                    reminderService: reminderService
                )
            } else {
                OnboardingView(
                    calendarService: calendarService,
                    reminderService: reminderService,
                    onComplete: {
                        hasCompletedOnboarding = true
                    }
                )
            }
        }
    }
    
    private var hasRequiredPermissions: Bool {
        calendarService.authorizationStatus == .fullAccess &&
        reminderService.authorizationStatus == .fullAccess
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var reminderService: ReminderService
    
    var body: some View {
        TabView {
            WeekView(
                calendarService: calendarService,
                reminderService: reminderService
            )
            .tabItem {
                Label("Woche", systemImage: "calendar")
            }
            
            RoutinesPlaceholderView()
                .tabItem {
                    Label("Routinen", systemImage: "checklist")
                }
            
            SettingsPlaceholderView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gear")
                }
        }
    }
}

// MARK: - Placeholder Views

struct RoutinesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Routinen",
                systemImage: "checklist",
                description: Text("Hier werden bald die Kinder-Routinen angezeigt")
            )
            .navigationTitle("Routinen")
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Einstellungen",
                systemImage: "gear",
                description: Text("Hier kannst du bald Kalender und Regeln konfigurieren")
            )
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    ContentView()
}
