import Foundation

struct APIConfig {
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
