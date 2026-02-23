                                        //
//  PDFExportService.swift
//  I remind you
//
//  Created by Johannes Eiseler on 25.01.26.
//

import Foundation
import SwiftUI
import PDFKit

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
typealias PlatformBezierPath = UIBezierPath
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
typealias PlatformBezierPath = NSBezierPath

// Extension für NSBezierPath, um cgPath zu unterstützen
extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break
            }
        }
        
        return path
    }
}
#endif

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
        
        #if canImport(UIKit)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let ctx = context.cgContext
            drawPDFContent(in: ctx, rect: pageRect, weekData: weekData, layout: layout, orientation: orientation)
        }
        
        return data
        #else
        // macOS: Verwende CGContext direkt
        let pdfData = NSMutableData()
        var mediaBox = pageRect
        let mediaBoxData = Data(bytes: &mediaBox, count: MemoryLayout<CGRect>.size) as CFData
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        ctx.beginPDFPage([kCGPDFContextMediaBox as String: mediaBoxData] as CFDictionary)
        
        // NSGraphicsContext aktivieren, damit NSAttributedString.draw() funktioniert.
        // flipped: true → Koordinatenursprung oben-links, y nach unten (wie der Zeichencode erwartet)
        let nsContext = NSGraphicsContext(cgContext: ctx, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        // CGContext-Koordinatensystem flippen: PDF-Ursprung ist unten-links → auf oben-links umstellen
        ctx.saveGState()
        ctx.translateBy(x: 0, y: pageRect.height)
        ctx.scaleBy(x: 1, y: -1)
        
        drawPDFContent(in: ctx, rect: pageRect, weekData: weekData, layout: layout, orientation: orientation)
        
        ctx.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
        
        ctx.endPDFPage()
        ctx.closePDF()
        
        return pdfData as Data
        #endif
    }
    
    private func drawPDFContent(in ctx: CGContext, rect: CGRect, weekData: WeekData, layout: PDFLayout, orientation: PDFOrientation) {
        // Hintergrund
        ctx.setFillColor(PlatformColor.white.cgColor)
        ctx.fill(rect)
        
        // Header zeichnen
        drawHeader(in: ctx, rect: rect, weekData: weekData)
        
        // Tage zeichnen - je nach Orientierung
        if orientation == .landscape {
            drawDaysLandscape(in: ctx, rect: rect, weekData: weekData, layout: layout)
        } else {
            drawDays(in: ctx, rect: rect, weekData: weekData, layout: layout)
        }
        
        // Footer
        drawFooter(in: ctx, rect: rect)
    }
    
    // MARK: - Header
    
    private func drawHeader(in ctx: CGContext, rect: CGRect, weekData: WeekData) {
        // Kleinere Schrift für Landscape
        let isLandscape = rect.width > rect.height
        let titleFontSize: CGFloat = isLandscape ? 22 : 28
        let subtitleFontSize: CGFloat = isLandscape ? 12 : 14
        
        let titleFont = PlatformFont.systemFont(ofSize: titleFontSize, weight: .bold)
        let subtitleFont = PlatformFont.systemFont(ofSize: subtitleFontSize, weight: .medium)
        
        // Im Landscape: Kompakter Header in einer Zeile
        if isLandscape {
            // Titel links
            let title = "Wochenplan"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: PlatformColor.black
            ]
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
            
            // KW und Datum mittig
            let subtitle = "KW \(weekData.weekNumber) / \(weekData.year)"
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: PlatformColor.darkGray
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
            ctx.setStrokeColor(PlatformColor(white: 0.85, alpha: 1).cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: 15, y: 75))
            ctx.addLine(to: CGPoint(x: rect.width - 15, y: 75))
            ctx.strokePath()
            
        } else {
            // Portrait: Original-Layout
            let title = "Wochenplan"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: PlatformColor.black
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
                .foregroundColor: PlatformColor.darkGray
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
        let bgColor: PlatformColor
        if isToday {
            bgColor = PlatformColor.systemBlue.withAlphaComponent(0.15)
        } else if isWeekend {
            bgColor = PlatformColor.systemOrange.withAlphaComponent(0.08)
        } else {
            bgColor = PlatformColor(white: 0.97, alpha: 1)
        }
        ctx.setFillColor(bgColor.cgColor)
        let bgPath = platformBezierPath(roundedRect: rect, cornerRadius: 6)
        ctx.addPath(bgPath)
        ctx.fillPath()
        
        // Rahmen
        ctx.setStrokeColor(isToday ? PlatformColor.systemBlue.cgColor : PlatformColor(white: 0.82, alpha: 1).cgColor)
        ctx.setLineWidth(isToday ? 2 : 1)
        ctx.addPath(bgPath)
        ctx.strokePath()
        
        // Tag-Header
        let dayNameFont = PlatformFont.systemFont(ofSize: 11, weight: .bold)
        let dateFont = PlatformFont.systemFont(ofSize: 9, weight: .medium)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        formatter.dateFormat = "EEE" // Kurzform: Mo, Di, Mi...
        let dayName = formatter.string(from: day.date)
        
        formatter.dateFormat = "d.M."
        let dateString = formatter.string(from: day.date)
        
        let dayNameAttributes: [NSAttributedString.Key: Any] = [
            .font: dayNameFont,
            .foregroundColor: isToday ? PlatformColor.systemBlue : PlatformColor.black
        ]
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: PlatformColor.gray
        ]
        
        // Header zentriert
        let dayNameSize = dayName.size(withAttributes: dayNameAttributes)
        let dateSize = dateString.size(withAttributes: dateAttributes)
        
        dayName.draw(at: CGPoint(x: rect.midX - dayNameSize.width / 2, y: rect.minY + 5), withAttributes: dayNameAttributes)
        dateString.draw(at: CGPoint(x: rect.midX - dateSize.width / 2, y: rect.minY + 18), withAttributes: dateAttributes)
        
        // Trennlinie unter Header
        ctx.setStrokeColor(PlatformColor(white: 0.85, alpha: 1).cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: rect.minX + 5, y: rect.minY + 34))
        ctx.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.minY + 34))
        ctx.strokePath()
        
        // Horizontales Layout: Events oben, Tasks unten (größere Schrift möglich)
        let contentPadding: CGFloat = 4
        let headerHeight: CGFloat = 38
        let maxContentY = rect.maxY - 6
        
        // Größere Schrift da mehr Platz horizontal
        let eventFont = PlatformFont.systemFont(ofSize: 8, weight: .medium)
        let taskFont = PlatformFont.systemFont(ofSize: 8, weight: .regular)
        let timeFont = PlatformFont.systemFont(ofSize: 7, weight: .regular)
        
        var currentY = rect.minY + headerHeight
        
        // Oberer Bereich: Events (Kalender)
        for event in day.events {
            guard currentY < maxContentY - 8 else {
                let remainingEvents = day.events.count - (day.events.firstIndex(where: { $0.id == event.id }) ?? 0)
                let remainingTasks = day.tasks.count
                let total = remainingEvents + remainingTasks
                if total > 0 {
                    let moreText = "+\(total)"
                    let moreAttributes: [NSAttributedString.Key: Any] = [
                        .font: PlatformFont.systemFont(ofSize: 7, weight: .medium),
                        .foregroundColor: PlatformColor.gray
                    ]
                    moreText.draw(at: CGPoint(x: rect.minX + contentPadding, y: currentY), withAttributes: moreAttributes)
                }
                return
            }
            
            let timeString = event.isAllDay ? "○" : formatTime(event.startDate)
            
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: timeFont,
                .foregroundColor: PlatformColor.gray
            ]
            let eventAttributes: [NSAttributedString.Key: Any] = [
                .font: eventFont,
                .foregroundColor: PlatformColor.black
            ]
            
            timeString.draw(at: CGPoint(x: rect.minX + contentPadding, y: currentY), withAttributes: timeAttributes)
            
            let maxTitleWidth = rect.width - contentPadding * 2 - 22
            let truncatedTitle = truncateText(event.title, font: eventFont, maxWidth: maxTitleWidth)
            truncatedTitle.draw(at: CGPoint(x: rect.minX + contentPadding + 20, y: currentY), withAttributes: eventAttributes)
            
            currentY += 10
        }
        
        // Horizontale Trennlinie zwischen Events und Tasks (wenn beide vorhanden)
        if !day.events.isEmpty && !day.tasks.isEmpty && currentY < maxContentY - 12 {
            currentY += 2
            ctx.setStrokeColor(PlatformColor(white: 0.88, alpha: 1).cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: rect.minX + 5, y: currentY))
            ctx.addLine(to: CGPoint(x: rect.maxX - 5, y: currentY))
            ctx.strokePath()
            currentY += 4
        }
        
        // Unterer Bereich: Tasks (Erinnerungen)
        for task in day.tasks {
            guard currentY < maxContentY - 8 else {
                let remainingTasks = day.tasks.count - (day.tasks.firstIndex(where: { $0.id == task.id }) ?? 0)
                if remainingTasks > 0 {
                    let moreText = "+\(remainingTasks)"
                    let moreAttributes: [NSAttributedString.Key: Any] = [
                        .font: PlatformFont.systemFont(ofSize: 7, weight: .medium),
                        .foregroundColor: PlatformColor.gray
                    ]
                    moreText.draw(at: CGPoint(x: rect.minX + contentPadding, y: currentY), withAttributes: moreAttributes)
                }
                return
            }
            
            let checkbox = task.isCompleted ? "☑" : "☐"
            let checkboxAttributes: [NSAttributedString.Key: Any] = [
                .font: taskFont,
                .foregroundColor: task.isCompleted ? PlatformColor.systemGreen : PlatformColor.gray
            ]
            let taskAttributes: [NSAttributedString.Key: Any] = [
                .font: taskFont,
                .foregroundColor: task.isCompleted ? PlatformColor.gray : PlatformColor.black
            ]
            
            checkbox.draw(at: CGPoint(x: rect.minX + contentPadding, y: currentY), withAttributes: checkboxAttributes)
            
            let maxTitleWidth = rect.width - contentPadding * 2 - 12
            let truncatedTitle = truncateText(task.title, font: taskFont, maxWidth: maxTitleWidth)
            truncatedTitle.draw(at: CGPoint(x: rect.minX + contentPadding + 10, y: currentY), withAttributes: taskAttributes)
            
            currentY += 10
        }
    }
    
    private func truncateText(_ text: String, font: PlatformFont, maxWidth: CGFloat) -> String {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        var truncated = text
        
        while truncated.size(withAttributes: attributes).width > maxWidth && truncated.count > 3 {
            truncated = String(truncated.dropLast(2)) + "…"
        }
        
        return truncated
    }
    
    /// Cross-platform BezierPath für abgerundete Rechtecke
    private func platformBezierPath(roundedRect rect: CGRect, cornerRadius: CGFloat) -> CGPath {
        #if canImport(UIKit)
        return UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        #else
        return NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).cgPath
        #endif
    }
    
    private func drawDay(in ctx: CGContext, rect: CGRect, day: DayData, layout: PDFLayout) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(day.date)
        
        // Hintergrund
        ctx.setFillColor(isToday ? PlatformColor.systemBlue.withAlphaComponent(0.1).cgColor : PlatformColor(white: 0.97, alpha: 1).cgColor)
        let bgPath = platformBezierPath(roundedRect: rect, cornerRadius: 8)
        ctx.addPath(bgPath)
        ctx.fillPath()
        
        // Rahmen
        ctx.setStrokeColor(isToday ? PlatformColor.systemBlue.cgColor : PlatformColor(white: 0.85, alpha: 1).cgColor)
        ctx.setLineWidth(isToday ? 2 : 1)
        ctx.addPath(bgPath)
        ctx.strokePath()
        
        // Tag-Header
        let dayNameFont = PlatformFont.systemFont(ofSize: 12, weight: .bold)
        let dateFont = PlatformFont.systemFont(ofSize: 10, weight: .regular)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: day.date)
        
        formatter.dateFormat = "d. MMM"
        let dateString = formatter.string(from: day.date)
        
        let dayNameAttributes: [NSAttributedString.Key: Any] = [
            .font: dayNameFont,
            .foregroundColor: isToday ? PlatformColor.systemBlue : PlatformColor.black
        ]
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: PlatformColor.gray
        ]
        
        dayName.draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 6), withAttributes: dayNameAttributes)
        dateString.draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 22), withAttributes: dateAttributes)
        
        // Inhalt
        let contentX = rect.minX + 90
        var currentY = rect.minY + 6
        
        let eventFont = PlatformFont.systemFont(ofSize: 9, weight: .medium)
        let taskFont = PlatformFont.systemFont(ofSize: 9, weight: .regular)
        let timeFont = PlatformFont.systemFont(ofSize: 8, weight: .regular)
        
        // Events
        for event in day.events.prefix(3) {
            let timeString = event.isAllDay ? "○" : formatTime(event.startDate)
            
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: timeFont,
                .foregroundColor: PlatformColor.gray
            ]
            let eventAttributes: [NSAttributedString.Key: Any] = [
                .font: eventFont,
                .foregroundColor: PlatformColor.black
            ]
            
            timeString.draw(at: CGPoint(x: contentX, y: currentY), withAttributes: timeAttributes)
            
            let truncatedTitle = String(event.title.prefix(30))
            truncatedTitle.draw(at: CGPoint(x: contentX + 35, y: currentY), withAttributes: eventAttributes)
            
            currentY += 12
        }
        
        if day.events.count > 3 {
            let moreText = "+\(day.events.count - 3) weitere"
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: PlatformFont.systemFont(ofSize: 8),
                .foregroundColor: PlatformColor.gray
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
                .foregroundColor: task.isCompleted ? PlatformColor.systemGreen : PlatformColor.gray
            ]
            let taskAttributes: [NSAttributedString.Key: Any] = [
                .font: taskFont,
                .foregroundColor: task.isCompleted ? PlatformColor.gray : PlatformColor.black
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
        let footerFont = PlatformFont.systemFont(ofSize: isLandscape ? 7 : 8, weight: .regular)
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let footerBase = String(localized: "pdf_footer")
        let footerText = "\(footerBase) • \(formatter.string(from: Date()))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: PlatformColor.lightGray
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
