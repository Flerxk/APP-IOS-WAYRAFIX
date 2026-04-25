import UIKit

// MARK: - Paleta oficial WayraFix
enum WayraTheme {
    // Fondo y tarjetas
    static let background   = UIColor(white: 0.985, alpha: 1)
    static let card         = UIColor.white

    // Color principal: Rojo/Naranja (identidad de marca – botón "Registrarme" / SOS)
    static let brand        = UIColor(red: 0.92, green: 0.26, blue: 0.21, alpha: 1)   // #EB4235
    static let brandSoft    = UIColor(red: 1.00, green: 0.91, blue: 0.90, alpha: 1)   // Rosa suave

    // Color secundario: Dorado/Bronce
    static let accent       = UIColor(red: 0.84, green: 0.64, blue: 0.29, alpha: 1)   // Dorado
    static let accentSoft   = UIColor(red: 0.97, green: 0.94, blue: 0.89, alpha: 1)   // Dorado suave

    // Paleta anterior (compatibilidad)
    static let primary      = UIColor(red: 0.32, green: 0.20, blue: 0.15, alpha: 1)   // Marrón oscuro

    // Texto
    static let textPrimary  = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
    static let textSecondary = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1)

    // Bordes / separadores
    static let divider      = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
    static let border       = UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1)   // Gris claro oficial
}

// MARK: - Extensiones UIView
extension UIView {

    /// Tarjeta con fondo blanco, esquinas y sombra sutil
    func applyCardStyle(radius: CGFloat = 22, shadow: Bool = true) {
        backgroundColor = WayraTheme.card
        layer.cornerRadius = radius
        if shadow {
            layer.shadowColor   = UIColor.black.cgColor
            layer.shadowOpacity = 0.06
            layer.shadowOffset  = CGSize(width: 0, height: 8)
            layer.shadowRadius  = 18
            layer.masksToBounds = false
        }
    }

    /// Contenedor estándar: borde gris claro + radio 12 px
    func applyContainerStyle(radius: CGFloat = 12) {
        layer.cornerRadius  = radius
        layer.borderWidth   = 1
        layer.borderColor   = WayraTheme.border.cgColor
        layer.masksToBounds = true
    }

    /// Panel inferior con bordes redondeados arriba (30+) y sombra superior
    func applyBottomPanelStyle(radius: CGFloat = 34) {
        layer.cornerRadius  = radius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        backgroundColor     = WayraTheme.card
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.07
        layer.shadowOffset  = CGSize(width: 0, height: -6)
        layer.shadowRadius  = 18
        layer.masksToBounds = false
    }

    /// Degradado horizontal estilo SOS (de rojo a naranja-rosado) sobre la vista
    func applySOSGradient() {
        let nombre = "SOSGradient"
        if let subcapas = layer.sublayers, subcapas.contains(where: { $0.name == nombre }) { return }
        let grad = CAGradientLayer()
        grad.name       = nombre
        grad.colors     = [UIColor(red: 0.92, green: 0.26, blue: 0.21, alpha: 1).cgColor,
                           UIColor(red: 1.00, green: 0.45, blue: 0.30, alpha: 1).cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0.5)
        grad.endPoint   = CGPoint(x: 1, y: 0.5)
        grad.frame      = bounds
        layer.insertSublayer(grad, at: 0)
    }

    /// Actualiza el frame del degradado SOS al hacer layout
    func ajustarSOSGradient() {
        if let grad = layer.sublayers?.first(where: { $0.name == "SOSGradient" }) as? CAGradientLayer {
            grad.frame = bounds
        }
    }
}

// MARK: - Extensiones UIButton
extension UIButton {

    /// Botón de acción principal: fondo rojo/naranja (= "Registrarme" / "SOS")
    func applyBrandStyle(title: String) {
        configuration                        = .filled()
        configuration?.title                 = title
        configuration?.baseBackgroundColor   = WayraTheme.brand
        configuration?.baseForegroundColor   = .white
        configuration?.cornerStyle           = .capsule
        layer.shadowColor   = WayraTheme.brand.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset  = CGSize(width: 0, height: 6)
        layer.shadowRadius  = 10
        layer.masksToBounds = false
    }

    /// Botón marrón oscuro (acción principal legacy)
    func applyPrimaryStyle(title: String) {
        configuration                      = .filled()
        configuration?.title               = title
        configuration?.baseBackgroundColor = WayraTheme.primary
        configuration?.baseForegroundColor = .white
        configuration?.cornerStyle         = .capsule
    }

    /// Botón dorado/bronce (acción secundaria)
    func applyAccentStyle(title: String) {
        configuration                      = .filled()
        configuration?.title               = title
        configuration?.baseBackgroundColor = WayraTheme.accent
        configuration?.baseForegroundColor = .white
        configuration?.cornerStyle         = .capsule
    }
}

// MARK: - Extensión UIViewController (estilos globales)
extension UIViewController {

    /// Aplica el estilo WayraFix estándar a todos los contenedores directos de `vista`:
    /// borde gris claro y radio de 12 px. Se puede llamar desde cualquier viewDidLoad.
    func aplicarEstilosWayra(a vista: UIView) {
        for subvista in vista.subviews {
            // Solo vistas "contenedor" (UIView puro, no controles ni imágenes)
            if type(of: subvista) == UIView.self {
                subvista.applyContainerStyle()
            }
            // Recursividad en los hijos
            aplicarEstilosWayra(a: subvista)
        }
    }
}
