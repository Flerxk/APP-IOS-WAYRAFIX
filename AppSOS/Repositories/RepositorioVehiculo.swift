import UIKit
import CoreData
import FirebaseAuth
import FirebaseFirestore

protocol RepositorioVehiculoProtocol {
    func obtenerVehiculos() throws -> [VehiculoEntity]
    func eliminarVehiculo(_ vehiculo: VehiculoEntity) throws
    func agregarObservador(_ observer: Any, selector: Selector)
    func quitarObservador(_ observer: Any)
    func descargarVehiculosDeFirestore(completion: @escaping (Error?) -> Void)
}

final class RepositorioVehiculoCoreData: RepositorioVehiculoProtocol {
    private let context: NSManagedObjectContext
    private let notificationCenter: NotificationCenter	
    private lazy var db = Firestore.firestore()
    
    init(
        context: NSManagedObjectContext = ControladorPersistencia.compartido.contextoVista,
        notificationCenter: NotificationCenter = .default
    ) {
        self.context = context
        self.notificationCenter = notificationCenter
    }
    
    func obtenerVehiculos() throws -> [VehiculoEntity] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        let request: NSFetchRequest<VehiculoEntity> = VehiculoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "propietario.id == %@", uid)
        return try context.fetch(request)
    }

    func eliminarVehiculo(_ vehiculo: VehiculoEntity) throws {
        context.delete(vehiculo)
        try context.save()
    }
    
    func descargarVehiculosDeFirestore(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        db.collection("usuarios").document(uid).collection("vehiculos").getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(nil)
                return
            }
            
            self.context.perform {
                for doc in documents {
                    let data = doc.data()
                    let vin = doc.documentID
                    
                    let request: NSFetchRequest<VehiculoEntity> = VehiculoEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "vin == %@", vin)
                    
                    let vehiculo: VehiculoEntity
                    if let existente = try? self.context.fetch(request).first {
                        vehiculo = existente
                    } else {
                        vehiculo = VehiculoEntity(context: self.context)
                        vehiculo.vin = vin
                    }
                    
                    vehiculo.marca = data["marca"] as? String
                    vehiculo.modelo = data["modelo"] as? String
                    vehiculo.placa = data["placa"] as? String
                    vehiculo.color = data["color"] as? String
                    vehiculo.anio = Int64(data["anio"] as? Int ?? 0)
                    vehiculo.tipoVehiculo = data["tipoVehiculo"] as? String
                    vehiculo.tipoCombustible = data["tipoCombustible"] as? String
                    vehiculo.transmision = data["transmision"] as? String
                    vehiculo.is_active = data["is_active"] as? Bool ?? true
                    
                    // Vincular con el UsuarioEntity actual
                    let reqUser: NSFetchRequest<UsuarioEntity> = UsuarioEntity.fetchRequest()
                    reqUser.predicate = NSPredicate(format: "id == %@", uid)
                    if let usuario = try? self.context.fetch(reqUser).first {
                        vehiculo.propietario = usuario
                    }
                }
                
                try? self.context.save()
                completion(nil)
            }
        }
    }
    
    func agregarObservador(_ observer: Any, selector: Selector) {
        notificationCenter.addObserver(
            observer,
            selector: selector,
            name: .NSManagedObjectContextObjectsDidChange,
            object: context
        )
    }
    
    func quitarObservador(_ observer: Any) {
        notificationCenter.removeObserver(
            observer,
            name: .NSManagedObjectContextObjectsDidChange,
            object: context
        )
    }
}

