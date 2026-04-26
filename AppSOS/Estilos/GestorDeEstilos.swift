import UIKit

// MARK: - Fondo radial rosado (identidad de pantalla)
extension UIView {

    // MARK: Fondo
    func aplicarFondoRosadoRadial() {
        if let subcapas = layer.sublayers, subcapas.contains(where: { $0.name == "FondoRadial" }) { return }
        let capa = CAGradientLayer()
        capa.name       = "FondoRadial"
        capa.type       = .radial
        capa.colors     = [UIColor.white.cgColor,
                           UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0).cgColor]
        capa.startPoint = CGPoint(x: 0.5, y: 0.3)
        capa.endPoint   = CGPoint(x: 1.0, y: 1.0)
        capa.frame      = bounds
        layer.insertSublayer(capa, at: 0)
    }

    func ajustarMarcoDeFondoRadial() {
        if let capa = layer.sublayers?.first(where: { $0.name == "FondoRadial" }) as? CAGradientLayer {
            capa.frame = bounds
        }
    }

    // MARK: Borde contenedor legacy (Login / SignUp)
    func aplicarBordeContenedor() {
        layer.cornerRadius = 16
        layer.borderColor  = UIColor.clear.cgColor
        layer.borderWidth  = 0
        backgroundColor    = .white
        
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset  = CGSize(width: 0, height: 4)
        layer.shadowRadius  = 12
        layer.masksToBounds = false
    }

    // MARK: Motor global de identidad WayraFix
    /// Aplica de forma automática toda la identidad visual WayraFix a la vista y su jerarquía:
    ///  - Fondo radial rosado/blanco
    ///  - Botones Primary → Rojo Wayra, texto blanco, bordes redondeados
    ///  - Contenedores de texto → borde Gris Claro (igual que SignUp)
    ///  - Iconos secundarios → Dorado; textos genéricos → Gris Oscuro
    func configurarIdentidadWayra() {
        // 1. Fondo radial
        aplicarFondoRosadoRadial()

        // 2. Recorrer jerarquía
        _aplicarIdentidadRecursivo(en: self)
    }

    private func _aplicarIdentidadRecursivo(en raiz: UIView) {
        // Botones
        if let boton = raiz as? UIButton {
            let titulo = boton.titleLabel?.text ?? boton.configuration?.title ?? ""

            let esPrimario = titulo.contains("Registrarme")
                          || titulo.contains("Iniciar Sesión")
                          || titulo.contains("Agregar")
                          || titulo.contains("Añadir")
                          || titulo == "SOS"
                          || titulo.contains("Guardar")
                          || titulo.contains("Actualizar")

            if esPrimario {
                boton.applyBrandStyle(title: titulo)
            } else if titulo.contains("Continuar con Google") || titulo.contains("Apple") {
                boton.aplicarEstiloSecundarioGoogle()
            }
        }

        // Contenedores de texto (UIView que contiene UITextField o UILabel)
        if type(of: raiz) == UIView.self {
            let tieneTextField = raiz.subviews.contains { $0 is UITextField }
            if tieneTextField {
                // Borde gris claro idéntico al SignUp
                raiz.layer.cornerRadius = 16
                raiz.layer.borderWidth  = 1
                raiz.layer.borderColor  = UIColor.lightGray.withAlphaComponent(0.5).cgColor
                raiz.layer.masksToBounds = true
            }
        }

        // Íconos: sustituir azul de sistema
        if let img = raiz as? UIImageView, img.image != nil {
            let w = img.bounds.width, h = img.bounds.height
            // Íconos pequeños de categoría → Dorado (secundario)
            if w > 0 && w <= 50 && h <= 50 {
                // Si el tinte actual es azul de sistema → reemplazar
                let tinte = img.tintColor ?? .systemBlue
                if tinte.isSystemBlue {
                    img.tintColor = WayraTheme.accent
                }
            }
        }

        // Labels: reemplazar azul de sistema
        if let label = raiz as? UILabel {
            if let color = label.textColor, color.isSystemBlue {
                label.textColor = WayraTheme.textPrimary
            }
        }

        for subvista in raiz.subviews {
            _aplicarIdentidadRecursivo(en: subvista)
        }
    }
}

// MARK: - Utilidad de color
private extension UIColor {
    /// Detecta si el color es aproximadamente el azul de sistema de iOS
    var isSystemBlue: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        // systemBlue ≈ (0.0, 0.48, 1.0)
        return r < 0.15 && g > 0.35 && g < 0.65 && b > 0.8
    }
}

// MARK: - Estilos de botón legacy
extension UIButton {

    /// Alias legacy: delega en applyBrandStyle del Theme unificado
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

            let esPrimario = titulo.contains("Registrarme")
                          || titulo.contains("Iniciar Sesión")
                          || titulo.contains("Agregar")
                          || titulo.contains("Añadir")
                          || titulo == "SOS"
                          || titulo.contains("Guardar")
                          || titulo.contains("Actualizar")

            if esPrimario {
                boton.applyBrandStyle(title: titulo)
            } else if titulo.contains("Continuar con Google") || titulo.contains("Apple") {
                boton.aplicarEstiloSecundarioGoogle()
            }
        }

        // Íconos pequeños → tinte de marca (rojo brand)
        if let img = raiz as? UIImageView, img.image != nil {
            let w = img.bounds.width, h = img.bounds.height
            if w > 0 && w <= 50 && h <= 50 {
                img.tintColor = WayraTheme.brand
            }
        }

        for subvista in raiz.subviews {
            rastrearYAplicarEstilos(en: subvista)
        }
    }
}
