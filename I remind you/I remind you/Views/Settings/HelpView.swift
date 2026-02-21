//
//  HelpView.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import SwiftUI

// MARK: - Localized Help Content

enum HelpLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"
    case italian = "it"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .german: return "🇩🇪 Deutsch"
        case .english: return "🇬🇧 English"
        case .italian: return "🇮🇹 Italiano"
        }
    }
}

struct HelpContent {
    let appTitle: String
    let appDescription: String
    
    let createRemindersTitle: String
    let createRemindersItems: [(icon: String, title: String, description: String)]
    
    let whenRemindersTitle: String
    let whenRemindersItems: [(icon: String, title: String, description: String)]
    
    let routineTipsTitle: String
    let routineTipsItems: [(icon: String, title: String, description: String)]
    
    let calendarTitle: String
    let calendarItems: [(icon: String, title: String, description: String)]
    
    let quickFilterTitle: String
    let quickFilterItems: [(icon: String, title: String, description: String)]
    
    static func content(for language: HelpLanguage) -> HelpContent {
        switch language {
        case .german:
            return germanContent
        case .english:
            return englishContent
        case .italian:
            return italianContent
        }
    }
    
    // MARK: - German Content
    
    static let germanContent = HelpContent(
        appTitle: "Checky4Family",
        appDescription: "Diese App stellt einfach zu bedienende Checklisten bereit und zeigt Kalendertermine und Erinnerungen deiner Familie in einer druckbaren Wochenansicht.\n\n🧠 Besonders geeignet für Kinder mit ADHS: Klare Strukturen, visuelle Routinen und übersichtliche Wochenpläne helfen bei der Tagesorganisation.",
        
        createRemindersTitle: "Erinnerungen anlegen",
        createRemindersItems: [
            ("app.badge.checkmark", "In der Erinnerungen-App", "Erstelle Erinnerungen in der Apple Erinnerungen-App. Wichtig: Datum mit Uhrzeit setzen!"),
            ("1.circle", "Schritt 1: Liste", "Erstelle eine Liste (z.B. Paul - Morgenroutine)."),
            ("2.circle", "Schritt 2: Erinnerung", "Tippe auf Neue Erinnerung und gib einen Titel ein."),
            ("3.circle", "Schritt 3: Datum", "Tippe auf (i) und aktiviere Datum. Datum UND Uhrzeit einstellen."),
            ("4.circle", "Schritt 4: Wiederholung", "Optional: Wiederholen aktivieren (z.B. Jeden Tag).")
        ],
        
        whenRemindersTitle: "Wann erscheinen Erinnerungen?",
        whenRemindersItems: [
            ("clock", "Datum erforderlich", "Erinnerungen erscheinen nur, wenn sie ein Datum mit Uhrzeit haben."),
            ("repeat", "Wiederkehrende Erinnerungen", "Wiederkehrende Erinnerungen (z.B. Routinen) werden jeden Tag der Woche angezeigt."),
            ("checklist", "Liste muss aktiv sein", "In den Einstellungen kannst du Listen ein- und ausblenden.")
        ],
        
        routineTipsTitle: "Tipps für Routinen",
        routineTipsItems: [
            ("person.crop.circle.badge.plus", "Eigene Listen pro Kind", "Erstelle pro Kind eine Liste. So kannst du die Ansicht filtern."),
            ("paintpalette", "Farben nutzen", "Gib jeder Liste eine eigene Farbe zur besseren Unterscheidung."),
            ("person.3", "Listen teilen", "Teile Listen per iCloud mit der Familie.")
        ],
        
        calendarTitle: "Kalender-Termine",
        calendarItems: [
            ("calendar", "Kalender", "Die App zeigt Termine aus deinen Apple Kalendern. In den Einstellungen wählst du, welche angezeigt werden."),
            ("icloud", "Familienkalender", "Erstelle einen gemeinsamen Kalender und teile ihn per iCloud.")
        ],
        
        quickFilterTitle: "Schnell filtern",
        quickFilterItems: [
            ("line.3.horizontal.decrease.circle", "Legende antippen", "Tippe in der Wochenansicht auf einen Eintrag in der Legende zum Ein-/Ausblenden.")
        ]
    )
    
    // MARK: - English Content
    
    static let englishContent = HelpContent(
        appTitle: "Checky4Family",
        appDescription: "This app provides easy-to-use checklists and displays your family's calendar events and reminders in a printable weekly view.\n\n🧠 Especially suitable for children with ADHD: Clear structures, visual routines and organized weekly schedules help with daily planning.",
        
        createRemindersTitle: "Create Reminders",
        createRemindersItems: [
            ("app.badge.checkmark", "In the Reminders App", "Create reminders in the Apple Reminders app. Important: Set date AND time!"),
            ("1.circle", "Step 1: List", "Create a list (e.g. Paul - Morning Routine)."),
            ("2.circle", "Step 2: Reminder", "Tap New Reminder and enter a title."),
            ("3.circle", "Step 3: Date", "Tap (i) and enable Date. Set both date AND time."),
            ("4.circle", "Step 4: Repeat", "Optional: Enable repeat (e.g. Every Day).")
        ],
        
        whenRemindersTitle: "When do reminders appear?",
        whenRemindersItems: [
            ("clock", "Date required", "Reminders only appear when they have a date with time."),
            ("repeat", "Recurring reminders", "Recurring reminders (e.g. routines) are shown every day of the week."),
            ("checklist", "List must be active", "You can show/hide lists in the settings.")
        ],
        
        routineTipsTitle: "Tips for Routines",
        routineTipsItems: [
            ("person.crop.circle.badge.plus", "Separate lists per child", "Create a list for each child. This way you can filter the view."),
            ("paintpalette", "Use colors", "Give each list its own color for better distinction."),
            ("person.3", "Share lists", "Share lists via iCloud with your family.")
        ],
        
        calendarTitle: "Calendar Events",
        calendarItems: [
            ("calendar", "Calendar", "The app shows events from your Apple calendars. Choose which ones to display in the settings."),
            ("icloud", "Family Calendar", "Create a shared calendar and share it via iCloud.")
        ],
        
        quickFilterTitle: "Quick Filter",
        quickFilterItems: [
            ("line.3.horizontal.decrease.circle", "Tap legend", "In the weekly view, tap an entry in the legend to show/hide it.")
        ]
    )
    
    // MARK: - Italian Content
    
    static let italianContent = HelpContent(
        appTitle: "Checky4Family",
        appDescription: "Questa app fornisce checklist facili da usare e mostra gli eventi del calendario e i promemoria della tua famiglia in una vista settimanale stampabile.\n\n🧠 Particolarmente adatta per bambini con ADHD: Strutture chiare, routine visive e programmi settimanali organizzati aiutano nella pianificazione quotidiana.",
        
        createRemindersTitle: "Creare Promemoria",
        createRemindersItems: [
            ("app.badge.checkmark", "Nell'app Promemoria", "Crea promemoria nell'app Apple Promemoria. Importante: imposta data E ora!"),
            ("1.circle", "Passo 1: Lista", "Crea una lista (es. Paolo - Routine mattutina)."),
            ("2.circle", "Passo 2: Promemoria", "Tocca Nuovo Promemoria e inserisci un titolo."),
            ("3.circle", "Passo 3: Data", "Tocca (i) e attiva Data. Imposta data E ora."),
            ("4.circle", "Passo 4: Ripetizione", "Opzionale: attiva Ripeti (es. Ogni giorno).")
        ],
        
        whenRemindersTitle: "Quando compaiono i promemoria?",
        whenRemindersItems: [
            ("clock", "Data richiesta", "I promemoria compaiono solo se hanno una data con ora."),
            ("repeat", "Promemoria ricorrenti", "I promemoria ricorrenti (es. routine) vengono mostrati ogni giorno della settimana."),
            ("checklist", "Lista deve essere attiva", "Puoi mostrare/nascondere le liste nelle impostazioni.")
        ],
        
        routineTipsTitle: "Consigli per le Routine",
        routineTipsItems: [
            ("person.crop.circle.badge.plus", "Liste separate per bambino", "Crea una lista per ogni bambino. Così puoi filtrare la vista."),
            ("paintpalette", "Usa i colori", "Dai a ogni lista un colore proprio per distinguerle meglio."),
            ("person.3", "Condividi liste", "Condividi le liste via iCloud con la tua famiglia.")
        ],
        
        calendarTitle: "Eventi del Calendario",
        calendarItems: [
            ("calendar", "Calendario", "L'app mostra gli eventi dai tuoi calendari Apple. Scegli quali visualizzare nelle impostazioni."),
            ("icloud", "Calendario familiare", "Crea un calendario condiviso e condividilo via iCloud.")
        ],
        
        quickFilterTitle: "Filtro Rapido",
        quickFilterItems: [
            ("line.3.horizontal.decrease.circle", "Tocca la legenda", "Nella vista settimanale, tocca una voce nella legenda per mostrarla/nasconderla.")
        ]
    )
}

// MARK: - Help View

/// Hilfeseite mit Erklaerungen zur App-Nutzung
struct HelpView: View {
    @State private var selectedLanguage: HelpLanguage = .german
    
    private var content: HelpContent {
        HelpContent.content(for: selectedLanguage)
    }
    
    var body: some View {
        List {
            // Sprachauswahl
            Section {
                Picker("Sprache / Language / Lingua", selection: $selectedLanguage) {
                    ForEach(HelpLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Einführung mit ADHS-Hinweis
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(content.appTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(content.appDescription)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // Erinnerungen anlegen (jetzt nach oben verschoben)
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(content.createRemindersItems, id: \.title) { item in
                        HelpItem(
                            icon: item.icon,
                            title: item.title,
                            description: item.description
                        )
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Label(content.createRemindersTitle, systemImage: "plus.circle")
            }
            
            // Wann erscheinen Erinnerungen
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(content.whenRemindersItems, id: \.title) { item in
                        HelpItem(
                            icon: item.icon,
                            title: item.title,
                            description: item.description
                        )
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Label(content.whenRemindersTitle, systemImage: "questionmark.circle")
            }
            
            // Routinen für Kinder
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(content.routineTipsItems, id: \.title) { item in
                        HelpItem(
                            icon: item.icon,
                            title: item.title,
                            description: item.description
                        )
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Label(content.routineTipsTitle, systemImage: "lightbulb")
            }
            
            // Kalender-Events
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(content.calendarItems, id: \.title) { item in
                        HelpItem(
                            icon: item.icon,
                            title: item.title,
                            description: item.description
                        )
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Label(content.calendarTitle, systemImage: "calendar")
            }
            
            // Schnell filtern
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(content.quickFilterItems, id: \.title) { item in
                        HelpItem(
                            icon: item.icon,
                            title: item.title,
                            description: item.description
                        )
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Label(content.quickFilterTitle, systemImage: "slider.horizontal.3")
            }
        }
        .navigationTitle(selectedLanguage == .german ? "Hilfe" : (selectedLanguage == .english ? "Help" : "Aiuto"))
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
