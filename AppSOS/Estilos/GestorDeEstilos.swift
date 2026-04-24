import UIKit

extension UIView {
    
    func aplicarFondoRosadoRadial() {
        // Evitamos agregar múltiples capas duplicadas
        if let subcapas = layer.sublayers, subcapas.contains(where: { $0.name == "FondoRadial" }) {
            return
        }
        
        let capaDegradado = CAGradientLayer()
        capaDegradado.name = "FondoRadial"
        capaDegradado.type = .radial
        capaDegradado.colors = [UIColor.white.cgColor, UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0).cgColor]
        capaDegradado.startPoint = CGPoint(x: 0.5, y: 0.3)
        capaDegradado.endPoint = CGPoint(x: 1.0, y: 1.0)
        capaDegradado.frame = bounds
        layer.insertSublayer(capaDegradado, at: 0)
    }
    
    func ajustarMarcoDeFondoRadial() {
        if let capaDegradado = layer.sublayers?.first(where: { $0.name == "FondoRadial" }) as? CAGradientLayer {
            capaDegradado.frame = bounds
        }
    }
    
    func aplicarBordeContenedor() {
        layer.cornerRadius = 16
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        layer.borderWidth = 1
    }
}

extension UIButton {
    
    func aplicarEstiloPrincipalRoja() {
        layer.cornerRadius = 25
        if let configuracionActual = configuration {
            var nuevaConfiguracion = configuracionActual
            nuevaConfiguracion.baseBackgroundColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
            configuration = nuevaConfiguracion
        } else {
            backgroundColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        }
        tintColor = .white
        layer.shadowColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 10
        layer.masksToBounds = false
    }
    
    func aplicarEstiloSecundarioGoogle() {
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        layer.cornerRadius = bounds.height > 0 ? bounds.height / 2 : 25
    }
}

class BuscadorDeElementosGraficos {
    static func rastrearYAplicarEstilos(en raiz: UIView) {
        if let boton = raiz as? UIButton {
            let tituloDelBoton = boton.titleLabel?.text ?? boton.configuration?.title ?? ""
            if tituloDelBoton.contains("Registrarme") || tituloDelBoton.contains("Iniciar Sesión") {
                boton.aplicarEstiloPrincipalRoja()
            } else if tituloDelBoton.contains("Continuar con Google") {
                boton.aplicarEstiloSecundarioGoogle()
            }
        }
        for subvista in raiz.subviews {
            rastrearYAplicarEstilos(en: subvista)
        }
    }
}
