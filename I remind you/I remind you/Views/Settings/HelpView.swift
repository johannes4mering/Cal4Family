//
//  HelpView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI

/// Hilfeseite mit Erklärungen zur App-Nutzung
struct HelpView: View {
    var body: some View {
        List {
            // Einführung
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("I remind you")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Diese App zeigt Kalendertermine und Erinnerungen deiner Familie in einer übersichtlichen Wochenansicht.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // Wie Erinnerungen angezeigt werden
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HelpItem(
                        icon: "clock",
                        title: "Fälligkeitsdatum erforderlich",
                        description: "Erinnerungen erscheinen nur in der Wochenansicht, wenn sie ein Fälligkeitsdatum mit Uhrzeit haben."
                    )
                    
                    HelpItem(
                        icon: "repeat",
                        title: "Wiederkehrende Erinnerungen",
                        description: "Wiederkehrende Erinnerungen (z.B. tägliche Routinen) werden für jeden Tag der Woche angezeigt."
                    )
                    
                    HelpItem(
                        icon: "checklist",
                        title: "Liste muss ausgewählt sein",
                        description: "In den Einstellungen kannst du auswählen, welche Erinnerungslisten angezeigt werden sollen."
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Label("Wann erscheinen Erinnerungen?", systemImage: "questionmark.circle")
            }
            
            // Erinnerungen anlegen
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HelpItem(
                        icon: "app.badge.checkmark",
                        title: "In der Erinnerungen-App",
                        description: "Öffne die Apple Erinnerungen-App und erstelle dort deine Aufgaben. Setze unbedingt ein Fälligkeitsdatum mit Uhrzeit!"
                    )
                    
                    HelpItem(
                        icon: "1.circle",
                        title: "Schritt 1: Liste auswählen",
                        description: "Wähle oder erstelle eine Liste (z.B. „Paul – Morgenroutine")."
                    )
                    
                    HelpItem(
                        icon: "2.circle",
                        title: "Schritt 2: Erinnerung erstellen",
                        description: "Tippe auf „Neue Erinnerung" und gib einen Titel ein (z.B. „Zähne putzen")."
                    )
                    
                    HelpItem(
                        icon: "3.circle",
                        title: "Schritt 3: Datum & Uhrzeit",
                        description: "Tippe auf das Info-Symbol (i) und aktiviere „Datum". Wähle Datum UND Uhrzeit aus."
                    )
                    
                    HelpItem(
                        icon: "4.circle",
                        title: "Schritt 4: Wiederholung (optional)",
                        description: "Für Routinen: Aktiviere „Wiederholen" und wähle z.B. „Täglich" oder „An Wochentagen"."
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Label("Erinnerungen anlegen", systemImage: "plus.circle")
            }
            
            // Routinen für Kinder
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HelpItem(
                        icon: "person.crop.circle.badge.plus",
                        title: "Eigene Listen pro Kind",
                        description: "Erstelle für jedes Kind eine eigene Liste (z.B. „Emma – Morgenroutine"). So kannst du die Ansicht pro Kind filtern."
                    )
                    
                    HelpItem(
                        icon: "paintpalette",
                        title: "Farben nutzen",
                        description: "Gib jeder Liste in der Erinnerungen-App eine eigene Farbe. So sind die Aufgaben in der Wochenansicht leichter zu unterscheiden."
                    )
                    
                    HelpItem(
                        icon: "person.3",
                        title: "Listen teilen",
                        description: "Teile Listen über iCloud mit deiner Familie. So können alle Familienmitglieder die Routinen sehen und abhaken."
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Label("Tipps für Familien-Routinen", systemImage: "lightbulb")
            }
            
            // Kalender-Events
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HelpItem(
                        icon: "calendar",
                        title: "Kalender verknüpfen",
                        description: "Die App zeigt alle Termine aus deinen Apple Kalendern. In den Einstellungen wählst du, welche Kalender angezeigt werden."
                    )
                    
                    HelpItem(
                        icon: "icloud",
                        title: "Familienkalender",
                        description: "Für gemeinsame Termine: Erstelle in der Kalender-App einen Familienkalender und teile ihn über iCloud."
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Label("Kalender-Termine", systemImage: "calendar")
            }
            
            // Legende
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HelpItem(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "Legende antippen",
                        description: "Tippe in der Wochenansicht auf einen Kalender oder eine Liste in der Legende, um sie ein- oder auszublenden."
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Label("Schnell filtern", systemImage: "slider.horizontal.3")
            }
        }
        .navigationTitle("Hilfe")
    }
}

// MARK: - Help Item

struct HelpItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accentColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
