//
//  VehiculoEntity+CoreDataProperties.swift
//  AppSOS
//
//  Created by Erick Chunga on 16/04/26.
//
//

public import Foundation
public import CoreData


public typealias VehiculoEntityCoreDataPropertiesSet = NSSet

extension VehiculoEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VehiculoEntity> {
        return NSFetchRequest<VehiculoEntity>(entityName: "VehiculoEntity")
    }

    @NSManaged public var anio: Int64
    @NSManaged public var color: String?
    @NSManaged public var marca: String?
    @NSManaged public var modelo: String?
    @NSManaged public var placa: String?
    @NSManaged public var tipoCombustible: String?
    @NSManaged public var tipoVehiculo: String?
    @NSManaged public var transmision: String?
    @NSManaged public var vin: String?

}

extension VehiculoEntity : Identifiable {

}
