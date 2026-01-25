//
//  HelpView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI

/// Hilfeseite mit Erklaerungen zur App-Nutzung
struct HelpView: View {
    var body: some View {
        List {
            // Einfuehrung
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("I remind you")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Diese App zeigt Kalendertermine und Erinnerungen deiner Familie in einer Wochenansicht.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // Wie Erinnerungen angezeigt werden
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HelpItem(
                        icon: "clock",
                        title: "Datum erforderlich",
                        description: "Erinnerungen erscheinen nur, wenn sie ein Datum mit Uhrzeit haben."
                    )
                    
                    HelpItem(
                        icon: "repeat",
                        title: "Wiederkehrende Erinnerungen",
                        description: "Wiederkehrende Erinnerungen (z.B. Routinen) werden jeden Tag der Woche angezeigt."
                    )
                    
                    HelpItem(
                        icon: "checklist",
                        title: "Liste muss aktiv sein",
                        description: "In den Einstellungen kannst du Listen ein- und ausblenden."
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
                        description: "Erstelle Erinnerungen in der Apple Erinnerungen-App. Wichtig: Datum mit Uhrzeit setzen!"
                    )
                    
                    HelpItem(
                        icon: "1.circle",
                        title: "Schritt 1: Liste",
                        description: "Erstelle eine Liste (z.B. Paul - Morgenroutine)."
                    )
                    
                    HelpItem(
                        icon: "2.circle",
                        title: "Schritt 2: Erinnerung",
                        description: "Tippe auf Neue Erinnerung und gib einen Titel ein."
                    )
                    
                    HelpItem(
                        icon: "3.circle",
                        title: "Schritt 3: Datum",
                        description: "Tippe auf (i) und aktiviere Datum. Datum UND Uhrzeit einstellen."
                    )
                    
                    HelpItem(
                        icon: "4.circle",
                        title: "Schritt 4: Wiederholung",
                        description: "Optional: Wiederholen aktivieren (z.B. Jeden Tag)."
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Label("Erinnerungen anlegen", systemImage: "plus.circle")
            }
            
            // Routinen fuer Kinder
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HelpItem(
                        icon: "person.crop.circle.badge.plus",
                        title: "Eigene Listen pro Kind",
                        description: "Erstelle pro Kind eine Liste. So kannst du die Ansicht filtern."
                    )
                    
                    HelpItem(
                        icon: "paintpalette",
                        title: "Farben nutzen",
                        description: "Gib jeder Liste eine eigene Farbe zur besseren Unterscheidung."
                    )
                    
                    HelpItem(
                        icon: "person.3",
                        title: "Listen teilen",
                        description: "Teile Listen per iCloud mit der Familie."
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Label("Tipps fuer Routinen", systemImage: "lightbulb")
            }
            
            // Kalender-Events
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HelpItem(
                        icon: "calendar",
                        title: "Kalender",
                        description: "Die App zeigt Termine aus deinen Apple Kalendern. In den Einstellungen waehlst du, welche angezeigt werden."
                    )
                    
                    HelpItem(
                        icon: "icloud",
                        title: "Familienkalender",
                        description: "Erstelle einen gemeinsamen Kalender und teile ihn per iCloud."
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
                        description: "Tippe in der Wochenansicht auf einen Eintrag in der Legende zum Ein-/Ausblenden."
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
                .foregroundStyle(Color.accentColor)
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
