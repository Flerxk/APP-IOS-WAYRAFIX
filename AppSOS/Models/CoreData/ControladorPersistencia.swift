import Foundation
import UIKit
import CoreData
import FirebaseFirestore
import FirebaseAuth

class ControladorPersistencia {
    static let compartido = ControladorPersistencia()

    /// Reutiliza el contenedor del AppDelegate para evitar doble carga de CoreData
    let contenedor: NSPersistentContainer
    lazy var baseDeDatos = Firestore.firestore()

    init() {
        // Obtener el contenedor ya inicializado por AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        contenedor = appDelegate.persistentContainer
        contenedor.viewContext.automaticallyMergesChangesFromParent = true
        contenedor.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var contextoVista: NSManagedObjectContext {
        return contenedor.viewContext
    }
    
    func guardarContexto() {
        if contextoVista.hasChanges {
            do {
                try contextoVista.save()
            } catch {
                print("Error al guardar contexto: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Usuarios
    
    func sincronizarUsuario(id: String, nombre: String, email: String, celular: String, pais: String, rol: String, finalizacion: @escaping (Bool, Error?) -> Void) {
        let datos: [String: Any] = [
            "nombre": nombre,
            "email": email,
            "celular": celular,
            "pais": pais,
            "rol": rol,
            "is_active": true,
            "fecha_registro": FieldValue.serverTimestamp()
        ]
        
        // 1. Guardar en Firestore
        baseDeDatos.collection("usuarios").document(id).setData(datos) { [weak self] error in
            if let error = error {
                finalizacion(false, error)
                return
            }
            
            // 2. Replicar en Core Data
            guard let autoRef = self else { return }
            autoRef.contextoVista.perform {
                let peticionBusqueda: NSFetchRequest<UsuarioEntity> = NSFetchRequest<UsuarioEntity>(entityName: "UsuarioEntity")
                peticionBusqueda.predicate = NSPredicate(format: "id == %@", id)
                
                let usuario: UsuarioEntity
                if let existente = try? autoRef.contextoVista.fetch(peticionBusqueda).first {
                    usuario = existente
                } else {
                    usuario = NSEntityDescription.insertNewObject(forEntityName: "UsuarioEntity", into: autoRef.contextoVista) as! UsuarioEntity
                    usuario.id = id
                }
                
                usuario.nombre = nombre
                usuario.email = email
                usuario.celular = celular
                usuario.pais = pais
                usuario.rol = rol
                usuario.is_active = true
                
                autoRef.guardarContexto()
                
                DispatchQueue.main.async {
                    finalizacion(true, nil)
                }
            }
        }
    }
    
    func eliminarLogicamenteUsuario(id: String, finalizacion: @escaping (Bool, Error?) -> Void) {
        // En Firestore
        baseDeDatos.collection("usuarios").document(id).updateData(["is_active": false]) { [weak self] error in
            if let error = error {
                finalizacion(false, error)
                return
            }
            
            guard let autoRef = self else { return }
            autoRef.contextoVista.perform {
                let peticionBusqueda: NSFetchRequest<UsuarioEntity> = NSFetchRequest<UsuarioEntity>(entityName: "UsuarioEntity")
                peticionBusqueda.predicate = NSPredicate(format: "id == %@", id)
                if let usuario = try? autoRef.contextoVista.fetch(peticionBusqueda).first {
                    usuario.is_active = false
                    autoRef.guardarContexto()
                }
                DispatchQueue.main.async {
                    finalizacion(true, nil)
                }
            }
        }
    }
    
    // Obtener usuarios activos
    func obtenerUsuariosActivos() -> [UsuarioEntity] {
        let peticionBusqueda: NSFetchRequest<UsuarioEntity> = NSFetchRequest<UsuarioEntity>(entityName: "UsuarioEntity")
        peticionBusqueda.predicate = NSPredicate(format: "is_active == true")
        do {
            return try contextoVista.fetch(peticionBusqueda)
        } catch {
            print("Error obteniendo usuarios: \(error)")
            return []
        }
    }
    
    // MARK: - Vehículos
    
    func sincronizarVehiculo(idFirebase: String, propietarioId: String, marca: String, modelo: String, placa: String, color: String, anio: Int64, tipoVehiculo: String, tipoCombustible: String, transmision: String, finalizacion: @escaping (Bool, Error?) -> Void) {
        let datos: [String: Any] = [
            "marca": marca,
            "modelo": modelo,
            "placa": placa,
            "color": color,
            "anio": anio,
            "tipoVehiculo": tipoVehiculo,
            "tipoCombustible": tipoCombustible,
            "transmision": transmision,
            "is_active": true,
            "ultima_actualizacion": FieldValue.serverTimestamp()
        ]
        
        // Guardar en subcolección de usuario para One-to-Many real
        baseDeDatos.collection("usuarios").document(propietarioId).collection("vehiculos").document(idFirebase).setData(datos, merge: true) { [weak self] error in
            if let error = error {
                finalizacion(false, error)
                return
            }
            
            // 2. Replicar en Core Data
            guard let autoRef = self else { return }
            autoRef.contextoVista.perform {
                let peticionBusqueda: NSFetchRequest<VehiculoEntity> = NSFetchRequest<VehiculoEntity>(entityName: "VehiculoEntity")
                peticionBusqueda.predicate = NSPredicate(format: "vin == %@", idFirebase)
                
                let vehiculo: VehiculoEntity
                if let existente = try? autoRef.contextoVista.fetch(peticionBusqueda).first {
                    vehiculo = existente
                } else {
                    vehiculo = NSEntityDescription.insertNewObject(forEntityName: "VehiculoEntity", into: autoRef.contextoVista) as! VehiculoEntity
                    vehiculo.vin = idFirebase
                }
                
                vehiculo.marca = marca
                vehiculo.modelo = modelo
                vehiculo.placa = placa
                vehiculo.color = color
                vehiculo.anio = anio
                vehiculo.tipoVehiculo = tipoVehiculo
                vehiculo.tipoCombustible = tipoCombustible
                vehiculo.transmision = transmision
                vehiculo.is_active = true
                
                // Relacionar propietario en CoreData
                let peticionUsuario: NSFetchRequest<UsuarioEntity> = NSFetchRequest<UsuarioEntity>(entityName: "UsuarioEntity")
                peticionUsuario.predicate = NSPredicate(format: "id == %@", propietarioId)
                if let propietario = try? autoRef.contextoVista.fetch(peticionUsuario).first {
                    vehiculo.propietario = propietario
                }
                
                autoRef.guardarContexto()
                
                DispatchQueue.main.async {
                    finalizacion(true, nil)
                }
            }
        }
    }
    
    func eliminarLogicamenteVehiculo(idFirebase: String, finalizacion: @escaping (Bool, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        baseDeDatos.collection("usuarios").document(uid).collection("vehiculos").document(idFirebase).updateData(["is_active": false]) { [weak self] error in
            if let error = error {
                finalizacion(false, error)
                return
            }
            
            guard let autoRef = self else { return }
            autoRef.contextoVista.perform {
                let peticionBusqueda: NSFetchRequest<VehiculoEntity> = NSFetchRequest<VehiculoEntity>(entityName: "VehiculoEntity")
                peticionBusqueda.predicate = NSPredicate(format: "vin == %@", idFirebase)
                if let vehiculo = try? autoRef.contextoVista.fetch(peticionBusqueda).first {
                    vehiculo.is_active = false
                    autoRef.guardarContexto()
                }
                DispatchQueue.main.async {
                    finalizacion(true, nil)
                }
            }
        }
    }
    
    func obtenerVehiculosActivos(para propietarioId: String) -> [VehiculoEntity] {
        let peticionBusqueda: NSFetchRequest<VehiculoEntity> = NSFetchRequest<VehiculoEntity>(entityName: "VehiculoEntity")
        // Predicado para vehículos activos y que pertenecen al usuario
        peticionBusqueda.predicate = NSPredicate(format: "is_active == true AND propietario.id == %@", propietarioId)
        do {
            return try contextoVista.fetch(peticionBusqueda)
        } catch {
            print("Error obteniendo vehiculos: \(error)")
            return []
        }
    }
}
