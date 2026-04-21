import Foundation

struct PerfilSesion {
    let estaLogueado: Bool
    let nombre: String
    let apellido: String
    let correo: String
    
    static let invitado = PerfilSesion(estaLogueado: false, nombre: "Invitado", apellido: "", correo: "")
    
    var nombreCompleto: String {
        let valor = "\(nombre) \(apellido)".trimmingCharacters(in: .whitespaces)
        return valor.isEmpty ? "Invitado" : valor
    }
}

protocol ProveedorSesionPerfilProtocol {
    func obtenerPerfilActual() -> PerfilSesion
}

final class ProveedorSesionPerfilLocal: ProveedorSesionPerfilProtocol {
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func obtenerPerfilActual() -> PerfilSesion {
        let estaLogueado = defaults.bool(forKey: "session_is_logged_in")
        guard estaLogueado else {
            return .invitado
        }
        
        let nombre = defaults.string(forKey: "perfilNombres") ?? ""
        let apellido = defaults.string(forKey: "perfilApellidos") ?? ""
        let correo = defaults.string(forKey: "perfilCorreo") ?? ""
        
        return PerfilSesion(
            estaLogueado: true,
            nombre: nombre,
            apellido: apellido,
            correo: correo
        )
    }
}
