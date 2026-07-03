import SwiftUI

struct InlineStatusView: View {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0.13, green: 0.18, blue: 0.17))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color(red: 0.42, green: 0.49, blue: 0.46))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.12, green: 0.30, blue: 0.26).opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color(red: 0.10, green: 0.20, blue: 0.17).opacity(0.08), radius: 10, x: 0, y: 5)
    }
}
