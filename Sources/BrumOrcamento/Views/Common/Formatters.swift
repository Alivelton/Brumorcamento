import Foundation
import SwiftUI

public enum Formatters {
    public static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.currencySymbol = "R$"
        return formatter
    }()

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    public static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    public static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    public static let iso8601FallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public static func formatCurrency(_ value: Double) -> String {
        return currency.string(from: NSNumber(value: value)) ?? String(format: "R$ %.2f", value)
    }

    public static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    public static func formatDateTime(_ date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }

    public static func parseISO8601(_ string: String) -> Date? {
        if let d = iso8601Formatter.date(from: string) { return d }
        return iso8601FallbackFormatter.date(from: string)
    }
}

extension Double {
    public var brlCurrency: String {
        Formatters.formatCurrency(self)
    }
}

extension Date {
    public var brlDateString: String {
        Formatters.formatDate(self)
    }

    public var brlDateTimeString: String {
        Formatters.formatDateTime(self)
    }
}

public struct ColorBadge: View {
    let text: String
    let color: Color

    public init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
