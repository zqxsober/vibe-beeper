import SwiftUI

struct QuickActionButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isActive ? activeColor : Color.secondary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(isActive ? activeColor : Color.secondary)
            }
            .frame(width: 56, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? activeColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
