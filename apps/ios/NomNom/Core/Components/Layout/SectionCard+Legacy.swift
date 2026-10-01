import SwiftUI

// Pre-design-system SectionCard API, kept so existing call sites compile until
// Phase 5. All three render as `layout: .stacked`. `caption` becomes the header's
// trailing text; `color` (gradient tint) and `innerPadding` are ignored: the card
// is always Card md (`s5`), and `featured` is the only tint.

extension SectionCard {
    @_disfavoredOverload
    @available(*, deprecated, message: "Use SectionCard(_:layout:featured:trailing:…); caption → trailing, color/innerPadding are ignored")
    init(
        _ title: String,
        caption: String? = nil,
        color: Color? = nil,
        innerPadding: CGFloat = DS.Spacing.s4,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title, trailing: caption, content: content)
    }

    @_disfavoredOverload
    @available(*, deprecated, message: "Use SectionCard(_:layout:featured:trailing:…); caption → trailing, color/innerPadding are ignored")
    init(
        title: String? = nil,
        caption: String? = nil,
        color: Color? = nil,
        innerPadding: CGFloat = DS.Spacing.s4,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title, trailing: caption, content: content)
    }

    @_disfavoredOverload
    @available(*, deprecated, message: "Use SectionCard(_:layout:featured:trailing:…); caption → trailing, color/innerPadding are ignored")
    init(
        header: String,
        caption: String? = nil,
        color: Color? = nil,
        innerPadding: CGFloat = DS.Spacing.s4,
        @ViewBuilder content: () -> Content
    ) {
        self.init(header, trailing: caption, content: content)
    }
}
