import Foundation

struct APIConfig {
    // Cambiar 'localhost' por la IP de tu PC si pruebas en un dispositivo físico
    // Ejemplo: "http://192.168.1.15:3000/api"
    static let baseURL = "https://backend-txy0.onrender.com/api"
    
    struct Endpoints {
        static let asistencias = "/asistencias"
        static let sos = "/asistencias/sos"
        static let authLogin = "/auth/login"
        static let authRegister = "/auth/register"
        static let clientes = "/clientes"
        static let gruas = "/gruas"
    }
}
