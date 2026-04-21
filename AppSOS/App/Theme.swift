import UIKit

enum WayraTheme {
    static let background = UIColor(white: 0.985, alpha: 1)
    static let card = UIColor.white
    static let primary = UIColor(red: 0.32, green: 0.20, blue: 0.15, alpha: 1)
    static let accent = UIColor(red: 0.84, green: 0.64, blue: 0.29, alpha: 1)
    static let accentSoft = UIColor(red: 0.97, green: 0.94, blue: 0.89, alpha: 1)
    static let textPrimary = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
    static let textSecondary = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1)
    static let divider = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
}

extension UIView {
    func applyCardStyle(radius: CGFloat = 22, shadow: Bool = true) {
        backgroundColor = WayraTheme.card
        layer.cornerRadius = radius
        if shadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.06
            layer.shadowOffset = CGSize(width: 0, height: 8)
            layer.shadowRadius = 18
        }
    }
}

extension UIButton {
    func applyPrimaryStyle(title: String) {
        configuration = .filled()
        configuration?.title = title
        configuration?.baseBackgroundColor = WayraTheme.primary
        configuration?.baseForegroundColor = .white
        configuration?.cornerStyle = .capsule
    }
    
    func applyAccentStyle(title: String) {
        configuration = .filled()
        configuration?.title = title
        configuration?.baseBackgroundColor = WayraTheme.accent
        configuration?.baseForegroundColor = .white
        configuration?.cornerStyle = .capsule
    }
}
