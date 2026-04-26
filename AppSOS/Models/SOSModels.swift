import Foundation

// MARK: - SOS Request Models
// Ajustado para coincidir exactamente con lo que espera el backend Node.js (s_asistencias.js)
struct SOSRequest: Codable {
    let uid_usuario: String
    let nombre_cliente: String
    let vehiculo_id: VehiculoInfo
    let tipo_siniestro: String
    let latitud: Double
    let longitud: Double
}

struct VehiculoInfo: Codable {
    let modelo: String
    let placa: String
    let marca: String
    let color: String
    let vin: String
    let transmision: String
}

// MARK: - Response Models
// Basado en la respuesta real del backend
struct SOSResponse: Codable {
    let id: String?
    let id_servicio: String?
    let nombre_grua: String?
    let ubicacion_tiempo_real_grua: UbicacionResponse?
}

struct UbicacionResponse: Codable {
    let lat: Double
    let lng: Double
}
