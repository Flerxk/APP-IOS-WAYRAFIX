import Foundation

protocol VehicleSessionManagerProtocol {
    func getSelectedVehicleVin() -> String?
    func setSelectedVehicleVin(_ vin: String?)
}

final class VehicleSessionManager: VehicleSessionManagerProtocol {
    static let shared = VehicleSessionManager()
    private let defaults: UserDefaults
    private let key = "selected_vehicle_vin"
    
    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func getSelectedVehicleVin() -> String? {
        return defaults.string(forKey: key)
    }
    
    func setSelectedVehicleVin(_ vin: String?) {
        let current = getSelectedVehicleVin()
        if current != vin {
            defaults.set(vin, forKey: key)
            // Notificar a toda la app que el vehículo seleccionado ha cambiado
            NotificationCenter.default.post(name: .vehicleSelectionChanged, object: nil)
        }
    }
}

extension Notification.Name {
    static let vehicleSelectionChanged = Notification.Name("vehicleSelectionChanged")
}
