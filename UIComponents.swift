import SwiftUI

// VS1.0 — Universal Card
struct UICard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .fill(UIStyle.Color.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIStyle.cardRadius)
                    .stroke(UIStyle.Color.cardStroke)
            )
    }
}

// VS1.0 — Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(UITypography.body())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: UIStyle.buttonRadius)
                        .fill(UIStyle.Color.accent)
                )
        }
    }
}
