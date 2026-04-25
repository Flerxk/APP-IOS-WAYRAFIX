import UIKit

// MARK: - Fondo radial rosado (identidad de pantalla)
extension UIView {

    func aplicarFondoRosadoRadial() {
        if let subcapas = layer.sublayers, subcapas.contains(where: { $0.name == "FondoRadial" }) {
            return
        }
        let capaDegradado = CAGradientLayer()
        capaDegradado.name       = "FondoRadial"
        capaDegradado.type       = .radial
        capaDegradado.colors     = [UIColor.white.cgColor,
                                    UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0).cgColor]
        capaDegradado.startPoint = CGPoint(x: 0.5, y: 0.3)
        capaDegradado.endPoint   = CGPoint(x: 1.0, y: 1.0)
        capaDegradado.frame      = bounds
        layer.insertSublayer(capaDegradado, at: 0)
    }

    func ajustarMarcoDeFondoRadial() {
        if let capaDegradado = layer.sublayers?.first(where: { $0.name == "FondoRadial" }) as? CAGradientLayer {
            capaDegradado.frame = bounds
        }
    }

    /// Borde contenedor legacy (usado en Login / SignUp)
    func aplicarBordeContenedor() {
        layer.cornerRadius = 16
        layer.borderColor  = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        layer.borderWidth  = 1
    }
}

// MARK: - Estilos de botón legacy (delegan en Theme.swift)
extension UIButton {

    /// Alias legacy: aplica el estilo de marca rojo/naranja unificado
    func aplicarEstiloPrincipalRoja() {
        let titulo = configuration?.title ?? titleLabel?.text ?? ""
        applyBrandStyle(title: titulo)
    }

    func aplicarEstiloSecundarioGoogle() {
        layer.borderWidth  = 1
        layer.borderColor  = UIColor(white: 0.85, alpha: 1).cgColor
        layer.cornerRadius = bounds.height > 0 ? bounds.height / 2 : 25
    }
}

// MARK: - BuscadorDeElementosGraficos
/// Recorre la jerarquía de vistas y aplica los estilos WayraFix según el contexto del elemento.
class BuscadorDeElementosGraficos {

    static func rastrearYAplicarEstilos(en raiz: UIView) {
        if let boton = raiz as? UIButton {
            let titulo = boton.titleLabel?.text ?? boton.configuration?.title ?? ""

            if titulo.contains("Registrarme") || titulo.contains("Iniciar Sesión") {
                // Botones de autenticación → rojo/naranja de marca
                boton.aplicarEstiloPrincipalRoja()

            } else if titulo.contains("Agregar") || titulo.contains("Añadir") {
                // Botón "Agregar" del Garage → mismo estilo que "Registrarme"
                boton.applyBrandStyle(title: titulo)

            } else if titulo == "SOS" {
                // Botón SOS → estilo de marca con sombra intensa
                boton.applyBrandStyle(title: titulo)

            } else if titulo.contains("Continuar con Google") {
                boton.aplicarEstiloSecundarioGoogle()
            }
        }

        // Íconos pequeños de categoría (SF Symbols ≤ 50×50) → tinte de marca
        if let img = raiz as? UIImageView, img.image != nil {
            let w = img.bounds.width, h = img.bounds.height
            if w <= 50 && h <= 50 && w > 0 {
                img.tintColor = WayraTheme.brand
            }
        }

        for subvista in raiz.subviews {
            rastrearYAplicarEstilos(en: subvista)
        }
    }
}
