import SwiftUI

public struct StatCardView: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    var subtitle: String? = nil

    public init(
        title: String,
        amount: Double,
        icon: String,
        color: Color,
        subtitle: String? = nil
    ) {
        self.title = title
        self.amount = amount
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundColor(color)
            }

            Text(amount.brlCurrency)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
