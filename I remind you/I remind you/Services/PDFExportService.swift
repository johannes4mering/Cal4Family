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
    
    func generateWeekPDF(weekData: WeekData, layout: PDFLayout = .standard) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let ctx = context.cgContext
            
            // Hintergrund
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(pageRect)
            
            // Header zeichnen
            drawHeader(in: ctx, rect: pageRect, weekData: weekData)
            
            // Tage zeichnen
            drawDays(in: ctx, rect: pageRect, weekData: weekData, layout: layout)
            
            // Footer
            drawFooter(in: ctx, rect: pageRect)
        }
        
        return data
    }
    
    // MARK: - Header
    
    private func drawHeader(in ctx: CGContext, rect: CGRect, weekData: WeekData) {
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        // Titel
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
    
    // MARK: - Tage zeichnen
    
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
        let contentWidth = rect.width - 100
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
        let footerFont = UIFont.systemFont(ofSize: 8, weight: .regular)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        let footerText = "Erstellt mit I remind you • \(formatter.string(from: Date()))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.lightGray
        ]
        
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerRect = CGRect(
            x: (rect.width - footerSize.width) / 2,
            y: rect.height - 25,
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
