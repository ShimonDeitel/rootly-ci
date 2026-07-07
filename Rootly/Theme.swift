import SwiftUI

/// Rootly's identity: a terracotta/moss-green palette — evokes a clay
/// propagation jar on a plant-shelf windowsill. Distinct from every
/// sibling app's colors (no sage/teal/chalkboard-green reused; moss is
/// a deeper, cooler green than Bowlmark's sage or Docket's chalkboard).
enum RLTheme {
    static let backdrop = Color(red: 0.961, green: 0.937, blue: 0.914)   // warm clay-cream
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.929, green: 0.890, blue: 0.855)
    static let ink = Color(red: 0.176, green: 0.145, blue: 0.122)        // deep soil-ink
    static let inkFaded = Color(red: 0.176, green: 0.145, blue: 0.122).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let terracotta = Color(red: 0.749, green: 0.404, blue: 0.290) // clay-pot terracotta
    static let terracottaBright = Color(red: 0.835, green: 0.475, blue: 0.349)
    static let moss = Color(red: 0.282, green: 0.376, blue: 0.204)       // deep moss-green (roots)
    static let danger = Color(red: 0.749, green: 0.278, blue: 0.220)
    static let success = Color(red: 0.282, green: 0.376, blue: 0.204)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
