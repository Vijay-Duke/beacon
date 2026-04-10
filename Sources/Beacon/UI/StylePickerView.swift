import SwiftUI

struct StylePickerView: View {
    @Binding var selectedStyle: LaserStyle

    var body: some View {
        HStack(spacing: 12) {
            ForEach(LaserStyle.allCases, id: \.self) { style in
                Button(action: { selectedStyle = style }) {
                    VStack(spacing: 6) {
                        styleIcon(style)
                            .frame(width: 40, height: 40)
                        Text(style.displayName)
                            .font(.caption)
                    }
                    .padding(8)
                    .background(selectedStyle == style ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedStyle == style ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func styleIcon(_ style: LaserStyle) -> some View {
        switch style {
        case .classicDot:
            Circle()
                .fill(Color.red)
                .frame(width: 16, height: 16)
                .shadow(color: .red.opacity(0.6), radius: 6)
        case .spotlight:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(Color.clear)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
            }
        case .halo:
            Circle()
                .stroke(Color.orange, lineWidth: 2)
                .frame(width: 20, height: 20)
                .shadow(color: .orange.opacity(0.5), radius: 4)
        case .crosshair:
            ZStack {
                Rectangle().fill(Color.green).frame(width: 1.5, height: 24)
                Rectangle().fill(Color.green).frame(width: 24, height: 1.5)
                Circle().fill(Color.green).frame(width: 4, height: 4)
            }
        }
    }
}
