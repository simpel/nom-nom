import SwiftUI

/// The app icon on the welcome screen: the icon photograph (a stoneware plate on oak)
/// at Avatar `xl` size, rounded `radius-2xl` with a hairline. It is a photo; never
/// redraw it. The name beside it is set in type ("Nom Nom" in Newsreader).
struct AppIconMark: View {
    var size: CGFloat = AvatarSize.xl.diameter

    var body: some View {
        Image("AppIconImage")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl2, style: .continuous))
            .dsHairline(radius: DS.Radius.xl2)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: DS.Spacing.s4) {
        AppIconMark()
        Text("Nom Nom").textStyle(.serifLg)
    }
    .padding(DS.Spacing.gutter)
    .background(DS.Color.bg)
}
