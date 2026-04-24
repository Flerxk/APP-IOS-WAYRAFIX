//
//  UsuarioEntity+CoreDataProperties.swift
//  AppSOS
//
//  Created by user286450 on 4/22/26.
//
//

public import Foundation
public import CoreData


public typealias UsuarioEntityCoreDataPropertiesSet = NSSet

extension UsuarioEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UsuarioEntity> {
        return NSFetchRequest<UsuarioEntity>(entityName: "UsuarioEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var pais: String?
    @NSManaged public var celular: String?
    @NSManaged public var email: String?
    @NSManaged public var nombre: String?
    @NSManaged public var rol: String?
    @NSManaged public var is_active: Bool
    @NSManaged public var vehiculos: NSSet?

}

// MARK: Generated accessors for vehiculos
extension UsuarioEntity {

    @objc(addVehiculosObject:)
    @NSManaged public func addToVehiculos(_ value: VehiculoEntity)

    @objc(removeVehiculosObject:)
    @NSManaged public func removeFromVehiculos(_ value: VehiculoEntity)

    @objc(addVehiculos:)
    @NSManaged public func addToVehiculos(_ values: NSSet)

    @objc(removeVehiculos:)
    @NSManaged public func removeFromVehiculos(_ values: NSSet)

}

extension UsuarioEntity : Identifiable {

}
