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
    var success: Bool? = nil
    var message: String? = nil
    var id: String? = nil
    var id_servicio: String? = nil
    var nombre_grua: String? = nil
    var ubicacion_tiempo_real_grua: UbicacionResponse? = nil
}

struct UbicacionResponse: Codable {
    let lat: Double
    let lng: Double
}

// MARK: - History Models
struct HistoryItem: Codable {
    let id: String?
    let id_servicio: String?
    let ticket: String?
    let uid_usuario: String?
    let tipoSiniestro: String?
    let estado: String?
    let fechaCorta: String?
    let vehiculo: VehiculoInfo?
}
