import Foundation

class APIService {
    static let shared = APIService()
    private init() {}
    
    /// Envía una solicitud de asistencia (SOS) al backend
    func crearAsistencia(payload: SOSRequest, completion: @escaping (Result<SOSResponse, Error>) -> Void) {
        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.sos) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(payload)
            
            // Log para debug
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("--- SOLICITUD SOS ---")
                print("URL: \(url.absoluteString)")
                print("Body: \(jsonString)")
                print("----------------------")
            }
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del servidor"])))
                }
                return
            }
            
            // Manejo de errores específicos según requerimiento (404/500)
            if httpResponse.statusCode == 404 || httpResponse.statusCode == 500 {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "No hay grúas disponibles en este momento."])))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos"])))
                }
                return
            }
            
            // Imprimir respuesta para debug
            if let responseString = String(data: data, encoding: .utf8) {
                print("--- RESPUESTA SERVIDOR (\(httpResponse.statusCode)) ---")
                print(responseString)
                print("-----------------------------------------")
            }
            
            do {
                let decoder = JSONDecoder()
                let responseObj = try decoder.decode(SOSResponse.self, from: data)
                
                // Si es 201 o exitoso, devolvemos el objeto
                if (200...299).contains(httpResponse.statusCode) {
                    DispatchQueue.main.async {
                        completion(.success(responseObj))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseObj.message ?? "Error desconocido"])))
                    }
                }
            } catch {
                // Fallback si no se puede decodificar pero el status es exitoso
                if (200...299).contains(httpResponse.statusCode) {
                    DispatchQueue.main.async {
                        completion(.success(SOSResponse(success: true, message: "Operación exitosa", id: nil)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }.resume()
    }
    
    /// Obtiene el historial de asistencias de un usuario específico
    func obtenerHistorial(uid: String, completion: @escaping (Result<[HistoryItem], Error>) -> Void) {
        let urlString = APIConfig.baseURL + APIConfig.Endpoints.asistencias + "?uid=\(uid)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos"]))) }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let items = try decoder.decode([HistoryItem].self, from: data)
                DispatchQueue.main.async {
                    completion(.success(items))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
