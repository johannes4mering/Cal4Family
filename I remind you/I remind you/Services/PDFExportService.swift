//
//  PDFExportService.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import SwiftUI
import PDFKit

/// Service zum Erstellen von PDF-Wochenkalendern
@MainActor
final class PDFExportService {
    
    struct WeekData {
        let weekNumber: Int
        let year: Int
        let days: [DayData]
    }
    
    struct DayData {
        let date: Date
        let events: [FamilyEvent]
        let tasks: [FamilyEvent]
    }
    
    // MARK: - PDF erstellen
    
    func generateWeekPDF(weekData: WeekData, layout: PDFLayout = .standard, orientation: PDFOrientation = .landscape, paperSize: PDFPaperSize = .a4) -> Data? {
        let pageRect = CGRect(origin: .zero, size: paperSize.pageSize(orientation: orientation))
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let ctx = context.cgContext
            
            // Hintergrund
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(pageRect)
            
            // Header zeichnen
            drawHeader(in: ctx, rect: pageRect, weekData: weekData)
            
            // Tage zeichnen - je nach Orientierung
            if orientation == .landscape {
                drawDaysLandscape(in: ctx, rect: pageRect, weekData: weekData, layout: layout)
            } else {
                drawDays(in: ctx, rect: pageRect, weekData: weekData, layout: layout)
            }
            
            // Footer
            drawFooter(in: ctx, rect: pageRect)
        }
        
        return data
    }
    
    // MARK: - Header
    
    private func drawHeader(in ctx: CGContext, rect: CGRect, weekData: WeekData) {
        // Kleinere Schrift für Landscape
        let isLandscape = rect.width > rect.height
        let titleFontSize: CGFloat = isLandscape ? 22 : 28
        let subtitleFontSize: CGFloat = isLandscape ? 12 : 14
        
        let titleFont = UIFont.systemFont(ofSize: titleFontSize, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: subtitleFontSize, weight: .medium)
        
        // Im Landscape: Kompakter Header in einer Zeile
        if isLandscape {
            // Titel links
            let title = "Wochenplan"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
            
            // KW und Datum mittig
            let subtitle = "KW \(weekData.weekNumber) / \(weekData.year)"
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.darkGray
            ]
            let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
            subtitle.draw(at: CGPoint(x: (rect.width - subtitleSize.width) / 2, y: 25), withAttributes: subtitleAttributes)
            
            // Datumsbereich
            if let firstDay = weekData.days.first?.date, let lastDay = weekData.days.last?.date {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "de_DE")
                formatter.dateFormat = "d. MMMM"
                
                let dateRange = "\(formatter.string(from: firstDay)) – \(formatter.string(from: lastDay))"
                let dateRangeSize = dateRange.size(withAttributes: subtitleAttributes)
                dateRange.draw(at: CGPoint(x: (rect.width - dateRangeSize.width) / 2, y: 45), withAttributes: subtitleAttributes)
            }
            
            // Trennlinie
            ctx.setStrokeColor(UIColor(white: 0.85, alpha: 1).cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: 15, y: 75))
            ctx.addLine(to: CGPoint(x: rect.width - 15, y: 75))
            ctx.strokePath()
            
        } else {
            // Portrait: Original-Layout
            let title = "Wochenplan"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (rect.width - titleSize.width) / 2,
                y: 30,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Kalenderwoche
            let subtitle = "KW \(weekData.weekNumber) / \(weekData.year)"
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
            let subtitleRect = CGRect(
                x: (rect.width - subtitleSize.width) / 2,
                y: 65,
                width: subtitleSize.width,
                height: subtitleSize.height
            )
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            
            // Datumsbereich
            if let firstDay = weekData.days.first?.date, let lastDay = weekData.days.last?.date {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "de_DE")
                formatter.dateFormat = "d. MMMM"
                
                let dateRange = "\(formatter.string(from: firstDay)) – \(formatter.string(from: lastDay))"
                let dateRangeSize = dateRange.size(withAttributes: subtitleAttributes)
                let dateRangeRect = CGRect(
                    x: (rect.width - dateRangeSize.width) / 2,
                    y: 85,
                    width: dateRangeSize.width,
                    height: dateRangeSize.height
                )
                dateRange.draw(in: dateRangeRect, withAttributes: subtitleAttributes)
            }
        }
    }
    
    // MARK: - Tage zeichnen (Portrait)
    
    private func drawDays(in ctx: CGContext, rect: CGRect, weekData: WeekData, layout: PDFLayout) {
        let margin: CGFloat = 20
        let headerHeight: CGFloat = 120
        let footerHeight: CGFloat = 40
        let daySpacing: CGFloat = 8
        
        let contentHeight = rect.height - headerHeight - footerHeight - margin * 2
        let dayHeight = (contentHeight - daySpacing * 6) / 7
        
        let dayWidth = rect.width - margin * 2
        
        for (index, day) in weekData.days.enumerated() {
            let dayY = headerHeight + CGFloat(index) * (dayHeight + daySpacing)
            let dayRect = CGRect(x: margin, y: dayY, width: dayWidth, height: dayHeight)
            
            drawDay(in: ctx, rect: dayRect, day: day, layout: layout)
        }
    }
    
    // MARK: - Tage zeichnen (Landscape)
    
    private func drawDaysLandscape(in ctx: CGContext, rect: CGRect, weekData: WeekData, layout: PDFLayout) {
        let margin: CGFloat = 15
        let headerHeight: CGFloat = 90
        let footerHeight: CGFloat = 25
        let daySpacing: CGFloat = 6
        
        // Im Querformat: 7 Spalten nebeneinander
        let contentWidth = rect.width - margin * 2
        let contentHeight = rect.height - headerHeight - footerHeight
        
        let dayWidth = (contentWidth - daySpacing * 6) / 7
        let dayHeight = contentHeight
        
        for (index, day) in weekData.days.enumerated() {
            let dayX = margin + CGFloat(index) * (dayWidth + daySpacing)
            let dayRect = CGRect(x: dayX, y: headerHeight, width: dayWidth, height: dayHeight)
            
            drawDayLandscape(in: ctx, rect: dayRect, day: day, layout: layout)
        }
    }
    
    private func drawDayLandscape(in ctx: CGContext, rect: CGRect, day: DayData, layout: PDFLayout) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(day.date)
        let isWeekend = calendar.isDateInWeekend(day.date)
        
        // Hintergrund
        let bgColor: UIColor
        if isToday {
            bgColor = UIColor.systemBlue.withAlphaComponent(0.15)
        } else if isWeekend {
            bgColor = UIColor.systemOrange.withAlphaComponent(0.08)
        } else {
            bgColor = UIColor(white: 0.97, alpha: 1)
        }
        ctx.setFillColor(bgColor.cgColor)
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        ctx.addPath(bgPath.cgPath)
        ctx.fillPath()
        
        // Rahmen
        ctx.setStrokeColor(isToday ? UIColor.systemBlue.cgColor : UIColor(white: 0.82, alpha: 1).cgColor)
        ctx.setLineWidth(isToday ? 2 : 1)
        ctx.addPath(bgPath.cgPath)
        ctx.strokePath()
        
        // Tag-Header
        let dayNameFont = UIFont.systemFont(ofSize: 11, weight: .bold)
        let dateFont = UIFont.systemFont(ofSize: 9, weight: .medium)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        formatter.dateFormat = "EEE" // Kurzform: Mo, Di, Mi...
        let dayName = formatter.string(from: day.date)
        
        formatter.dateFormat = "d.M."
        let dateString = formatter.string(from: day.date)
        
        let dayNameAttributes: [NSAttributedString.Key: Any] = [
            .font: dayNameFont,
            .foregroundColor: isToday ? UIColor.systemBlue : UIColor.black
        ]
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.gray
        ]
        
        // Header zentriert
        let dayNameSize = dayName.size(withAttributes: dayNameAttributes)
        let dateSize = dateString.size(withAttributes: dateAttributes)
        
        dayName.draw(at: CGPoint(x: rect.midX - dayNameSize.width / 2, y: rect.minY + 5), withAttributes: dayNameAttributes)
        dateString.draw(at: CGPoint(x: rect.midX - dateSize.width / 2, y: rect.minY + 18), withAttributes: dateAttributes)
        
        // Trennlinie unter Header
        ctx.setStrokeColor(UIColor(white: 0.85, alpha: 1).cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: rect.minX + 5, y: rect.minY + 34))
        ctx.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.minY + 34))
        ctx.strokePath()
        
        // Zwei-Spalten-Layout: Events links, Tasks rechts
        let contentPadding: CGFloat = 3
        let headerHeight: CGFloat = 38
        let columnSpacing: CGFloat = 2
        let columnWidth = (rect.width - contentPadding * 2 - columnSpacing) / 2
        let maxContentY = rect.maxY - 8
        
        let eventFont = UIFont.systemFont(ofSize: 7, weight: .medium)
        let taskFont = UIFont.systemFont(ofSize: 7, weight: .regular)
        let timeFont = UIFont.systemFont(ofSize: 6, weight: .regular)
        let sectionFont = UIFont.systemFont(ofSize: 6, weight: .bold)
        
        // Linke Spalte: Events (Kalender)
        let leftColumnX = rect.minX + contentPadding
        var leftY = rect.minY + headerHeight
        
        // Events-Überschrift nur wenn Events vorhanden
        if !day.events.isEmpty {
            let eventsLabel = "📅"
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: sectionFont,
                .foregroundColor: UIColor.darkGray
            ]
            eventsLabel.draw(at: CGPoint(x: leftColumnX, y: leftY), withAttributes: labelAttributes)
            leftY += 9
        }
        
        for event in day.events {
            guard leftY < maxContentY - 8 else {
                let remainingEvents = day.events.count - (day.events.firstIndex(where: { $0.id == event.id }) ?? 0)
                if remainingEvents > 0 {
                    let moreText = "+\(remainingEvents)"
                    let moreAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 6, weight: .medium),
                        .foregroundColor: UIColor.gray
                    ]
                    moreText.draw(at: CGPoint(x: leftColumnX, y: leftY), withAttributes: moreAttributes)
                }
                break
            }
            
            let timeString = event.isAllDay ? "○" : formatTime(event.startDate)
            
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: timeFont,
                .foregroundColor: UIColor.gray
            ]
            let eventAttributes: [NSAttributedString.Key: Any] = [
                .font: eventFont,
                .foregroundColor: UIColor.black
            ]
            
            timeString.draw(at: CGPoint(x: leftColumnX, y: leftY), withAttributes: timeAttributes)
            
            let maxTitleWidth = columnWidth - 18
            let truncatedTitle = truncateText(event.title, font: eventFont, maxWidth: maxTitleWidth)
            truncatedTitle.draw(at: CGPoint(x: leftColumnX + 16, y: leftY), withAttributes: eventAttributes)
            
            leftY += 9
        }
        
        // Vertikale Trennlinie zwischen den Spalten (wenn beide Inhalte haben)
        if !day.events.isEmpty && !day.tasks.isEmpty {
            let separatorX = rect.minX + contentPadding + columnWidth + columnSpacing / 2
            ctx.setStrokeColor(UIColor(white: 0.88, alpha: 1).cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: separatorX, y: rect.minY + headerHeight))
            ctx.addLine(to: CGPoint(x: separatorX, y: maxContentY))
            ctx.strokePath()
        }
        
        // Rechte Spalte: Tasks (Erinnerungen)
        let rightColumnX = rect.minX + contentPadding + columnWidth + columnSpacing
        var rightY = rect.minY + headerHeight
        
        // Tasks-Überschrift nur wenn Tasks vorhanden
        if !day.tasks.isEmpty {
            let tasksLabel = "☑️"
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: sectionFont,
                .foregroundColor: UIColor.darkGray
            ]
            tasksLabel.draw(at: CGPoint(x: rightColumnX, y: rightY), withAttributes: labelAttributes)
            rightY += 9
        }
        
        for task in day.tasks {
            guard rightY < maxContentY - 8 else {
                let remainingTasks = day.tasks.count - (day.tasks.firstIndex(where: { $0.id == task.id }) ?? 0)
                if remainingTasks > 0 {
                    let moreText = "+\(remainingTasks)"
                    let moreAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 6, weight: .medium),
                        .foregroundColor: UIColor.gray
                    ]
                    moreText.draw(at: CGPoint(x: rightColumnX, y: rightY), withAttributes: moreAttributes)
                }
                break
            }
            
            let checkbox = task.isCompleted ? "☑" : "☐"
            let checkboxAttributes: [NSAttributedString.Key: Any] = [
                .font: taskFont,
                .foregroundColor: task.isCompleted ? UIColor.systemGreen : UIColor.gray
            ]
            let taskAttributes: [NSAttributedString.Key: Any] = [
                .font: taskFont,
                .foregroundColor: task.isCompleted ? UIColor.gray : UIColor.black
            ]
            
            checkbox.draw(at: CGPoint(x: rightColumnX, y: rightY), withAttributes: checkboxAttributes)
            
            let maxTitleWidth = columnWidth - 10
            let truncatedTitle = truncateText(task.title, font: taskFont, maxWidth: maxTitleWidth)
            truncatedTitle.draw(at: CGPoint(x: rightColumnX + 8, y: rightY), withAttributes: taskAttributes)
            
            rightY += 9
        }
    }
    
    private func truncateText(_ text: String, font: UIFont, maxWidth: CGFloat) -> String {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        var truncated = text
        
        while truncated.size(withAttributes: attributes).width > maxWidth && truncated.count > 3 {
            truncated = String(truncated.dropLast(2)) + "…"
        }
        
        return truncated
    }
    
    private func drawDay(in ctx: CGContext, rect: CGRect, day: DayData, layout: PDFLayout) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(day.date)
        
        // Hintergrund
        ctx.setFillColor(isToday ? UIColor.systemBlue.withAlphaComponent(0.1).cgColor : UIColor(white: 0.97, alpha: 1).cgColor)
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        ctx.addPath(bgPath.cgPath)
        ctx.fillPath()
        
        // Rahmen
        ctx.setStrokeColor(isToday ? UIColor.systemBlue.cgColor : UIColor(white: 0.85, alpha: 1).cgColor)
        ctx.setLineWidth(isToday ? 2 : 1)
        ctx.addPath(bgPath.cgPath)
        ctx.strokePath()
        
        // Tag-Header
        let dayNameFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let dateFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: day.date)
        
        formatter.dateFormat = "d. MMM"
        let dateString = formatter.string(from: day.date)
        
        let dayNameAttributes: [NSAttributedString.Key: Any] = [
            .font: dayNameFont,
            .foregroundColor: isToday ? UIColor.systemBlue : UIColor.black
        ]
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.gray
        ]
        
        dayName.draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 6), withAttributes: dayNameAttributes)
        dateString.draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 22), withAttributes: dateAttributes)
        
        // Inhalt
        let contentX = rect.minX + 90
        var currentY = rect.minY + 6
        
        let eventFont = UIFont.systemFont(ofSize: 9, weight: .medium)
        let taskFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let timeFont = UIFont.systemFont(ofSize: 8, weight: .regular)
        
        // Events
        for event in day.events.prefix(3) {
            let timeString = event.isAllDay ? "○" : formatTime(event.startDate)
            
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: timeFont,
                .foregroundColor: UIColor.gray
            ]
            let eventAttributes: [NSAttributedString.Key: Any] = [
                .font: eventFont,
                .foregroundColor: UIColor.black
            ]
            
            timeString.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: timeAttributes)
            
            let truncatedTitle = String(event.title.prefix(30))
            truncatedTitle.draw(at: CGPoint(x: contentX + 35, y: currentY), withAttributes: eventAttributes)
            
            currentY += 12
        }
        
        if day.events.count > 3 {
            let moreText = "+\(day.events.count - 3) weitere"
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.gray
            ]
            moreText.draw(at: CGPoint(x: contentX + 35, y: currentY), withAttributes: moreAttributes)
            currentY += 12
        }
        
        // Trennlinie falls Events und Tasks
        if !day.events.isEmpty && !day.tasks.isEmpty {
            currentY += 2
        }
        
        // Tasks
        for task in day.tasks.prefix(4) {
            let checkbox = task.isCompleted ? "☑" : "☐"
            let checkboxAttributes: [NSAttributedString.Key: Any] = [
                .font: taskFont,
                .foregroundColor: task.isCompleted ? UIColor.systemGreen : UIColor.gray
            ]
            let taskAttributes: [NSAttributedString.Key: Any] = [
                .font: taskFont,
                .foregroundColor: task.isCompleted ? UIColor.gray : UIColor.black
            ]
            
            checkbox.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: checkboxAttributes)
            
            let truncatedTitle = String(task.title.prefix(30))
            truncatedTitle.draw(at: CGPoint(x: contentX + 15, y: currentY), withAttributes: taskAttributes)
            
            currentY += 12
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Footer
    
    private func drawFooter(in ctx: CGContext, rect: CGRect) {
        let isLandscape = rect.width > rect.height
        let footerFont = UIFont.systemFont(ofSize: isLandscape ? 7 : 8, weight: .regular)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        let footerText = "Erstellt mit I remind you • \(formatter.string(from: Date()))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.lightGray
        ]
        
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerY = isLandscape ? rect.height - 18 : rect.height - 25
        let footerRect = CGRect(
            x: (rect.width - footerSize.width) / 2,
            y: footerY,
            width: footerSize.width,
            height: footerSize.height
        )
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }
}

// MARK: - PDF Layout

enum PDFLayout: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case compact = "Kompakt"
    case detailed = "Detailliert"
    
    var id: String { rawValue }
}

// MARK: - PDF Orientation

enum PDFOrientation: String, CaseIterable, Identifiable {
    case portrait = "Hochformat"
    case landscape = "Querformat"
    
    var id: String { rawValue }
}

// MARK: - PDF Paper Size

enum PDFPaperSize: String, CaseIterable, Identifiable {
    case a4 = "A4"
    case letter = "US Letter"
    
    var id: String { rawValue }
    
    func pageSize(orientation: PDFOrientation) -> CGSize {
        let size: CGSize
        switch self {
        case .a4:
            size = CGSize(width: 595.2, height: 841.8) // 210 x 297 mm
        case .letter:
            size = CGSize(width: 612.0, height: 792.0) // 8.5 x 11 inch
        }
        
        switch orientation {
        case .portrait:
            return size
        case .landscape:
            return CGSize(width: size.height, height: size.width)
        }
    }
}
