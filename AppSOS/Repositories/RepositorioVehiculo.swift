import UIKit
import CoreData
import FirebaseAuth

protocol RepositorioVehiculoProtocol {
    func obtenerVehiculos() throws -> [VehiculoEntity]
    func eliminarVehiculo(_ vehiculo: VehiculoEntity) throws
    func agregarObservador(_ observer: Any, selector: Selector)
    func quitarObservador(_ observer: Any)
}

final class RepositorioVehiculoCoreData: RepositorioVehiculoProtocol {
    private let context: NSManagedObjectContext
    private let notificationCenter: NotificationCenter
    
    init(
        context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext,
        notificationCenter: NotificationCenter = .default
    ) {
        self.context = context
        self.notificationCenter = notificationCenter
    }
    
    func obtenerVehiculos() throws -> [VehiculoEntity] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        let request: NSFetchRequest<VehiculoEntity> = VehiculoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "usuarioId == %@", uid)
        return try context.fetch(request)
    }

    func eliminarVehiculo(_ vehiculo: VehiculoEntity) throws {
        context.delete(vehiculo)
        try context.save()
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

