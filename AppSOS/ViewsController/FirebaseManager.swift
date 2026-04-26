import Foundation
import FirebaseAuth
import FirebaseFirestore

// Tema 1.2.1: Clases, variables y métodos
// Tema 10: Consumo de servicios Firebase
class FirebaseManager {
    
    static let shared = FirebaseManager()
    private lazy var db = Firestore.firestore()
    
    private init() {}
    
    /// Autentica al usuario con correo y contraseña
    func iniciarSesion(email: String, contrasena: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: contrasena) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let uid = authResult?.user.uid else {
                let error = NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "UID no encontrado"])
                completion(.failure(error))
                return
            }
            completion(.success(uid))
        }
    }
    
    /// Obtiene y verifica el estado de un usuario en Firestore
    func verificarEstadoUsuario(uid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection("usuarios").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let datos = snapshot?.data() else {
                let error = NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No se encontraron datos para este usuario."])
                completion(.failure(error))
                return
            }
            
            completion(.success(datos))
        }
    }
    
    /// Crea un nuevo documento de usuario en Firestore
    func crearUsuario(uid: String, datos: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("usuarios").document(uid).setData(datos, completion: completion)
    }
    
    /// Guarda o actualiza un vehículo en Firestore
    func guardarVehiculo(uidUsuario: String, vehiculo: [String: Any], idVehiculo: String, completion: @escaping (Error?) -> Void) {
        db.collection("usuarios").document(uidUsuario).collection("vehiculos").document(idVehiculo).setData(vehiculo, merge: true, completion: completion)
    }
    
    /// Elimina un vehículo en Firestore
    func eliminarVehiculo(uidUsuario: String, idVehiculo: String, completion: @escaping (Error?) -> Void) {
        db.collection("usuarios").document(uidUsuario).collection("vehiculos").document(idVehiculo).delete(completion: completion)
    }
    
    func cerrarSesion() throws {
        try Auth.auth().signOut()
    }
}