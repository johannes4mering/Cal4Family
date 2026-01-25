//
//  FamilyMember.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import SwiftData

/// Repräsentiert ein Familienmitglied (Kind oder Erwachsener)
@Model
final class FamilyMember {
    var id: UUID
    var name: String
    var isChild: Bool
    var color: String // Hex-Farbe für UI
    var reminderListIdentifier: String? // ID der zugehörigen Apple Erinnerungs-Liste
    var createdAt: Date
    
    init(name: String, isChild: Bool = false, color: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.isChild = isChild
        self.color = color
        self.reminderListIdentifier = nil
        self.createdAt = Date()
    }
}
