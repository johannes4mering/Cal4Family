//
//  ContentView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI
import SwiftData
import EventKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var calendarService = CalendarService()
    @StateObject private var reminderService = ReminderService()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(
                    calendarService: calendarService,
                    reminderService: reminderService,
                    modelContext: modelContext
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
}

// MARK: - Main Tab View

enum MainTab: String {
    case routines
    case week
    case settings
}

struct MainTabView: View {
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var reminderService: ReminderService
    let modelContext: ModelContext
    @AppStorage("selectedMainTab") private var selectedMainTab = MainTab.routines.rawValue
    
    var body: some View {
        TabView(selection: $selectedMainTab) {
            RoutinesView(reminderService: reminderService)
                .tabItem {
                    Label(String(localized: "tab_routines", defaultValue: "Routinen"), systemImage: "checklist")
                }
                .tag(MainTab.routines.rawValue)

            WeekView(
                calendarService: calendarService,
                reminderService: reminderService
            )
            .tabItem {
                Label(String(localized: "tab_week", defaultValue: "Woche"), systemImage: "calendar")
            }
            .tag(MainTab.week.rawValue)
            
            SettingsView(
                calendarService: calendarService,
                reminderService: reminderService,
                modelContext: modelContext
            )
            .tabItem {
                Label(String(localized: "tab_settings", defaultValue: "Einstellungen"), systemImage: "gear")
            }
            .tag(MainTab.settings.rawValue)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [AutoRule.self, FamilyMember.self])
}
