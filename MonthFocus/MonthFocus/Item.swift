//
//  Item.swift
//  MonthFocus
//
//  Created by Kenshin on 2026/05/10.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class FocusTask {
    var title: String
    var detail: String
    var month: Date
    var priority: Int
    var isCompleted: Bool
    var createdAt: Date

    init(
        title: String,
        detail: String,
        month: Date,
        priority: Int,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.title = title
        self.detail = detail
        self.month = Calendar.current.startOfMonth(for: month)
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

@Model
final class MonthReflection {
    var month: Date
    var gratitude: String
    var extensionDecision: String
    var updatedAt: Date

    init(
        month: Date,
        gratitude: String = "",
        extensionDecision: String = "",
        updatedAt: Date = Date()
    ) {
        self.month = Calendar.current.startOfMonth(for: month)
        self.gratitude = gratitude
        self.extensionDecision = extensionDecision
        self.updatedAt = updatedAt
    }
}

enum FocusTheme: String, CaseIterable, Identifiable {
    case paper
    case mint
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paper:
            "Paper"
        case .mint:
            "Mint"
        case .graphite:
            "Graphite"
        }
    }

    var tint: Color {
        switch self {
        case .paper:
            .indigo
        case .mint:
            .teal
        case .graphite:
            .orange
        }
    }

    var background: Color {
        switch self {
        case .paper:
            Color(.systemGroupedBackground)
        case .mint:
            Color(red: 0.91, green: 0.97, blue: 0.94)
        case .graphite:
            Color(red: 0.10, green: 0.11, blue: 0.12)
        }
    }

    var card: Color {
        switch self {
        case .paper:
            Color(.secondarySystemGroupedBackground)
        case .mint:
            Color(red: 0.98, green: 1.00, blue: 0.98)
        case .graphite:
            Color(red: 0.17, green: 0.18, blue: 0.20)
        }
    }

    var text: Color {
        switch self {
        case .graphite:
            .white
        default:
            .primary
        }
    }

    var secondaryText: Color {
        switch self {
        case .graphite:
            .white.opacity(0.68)
        default:
            .secondary
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
