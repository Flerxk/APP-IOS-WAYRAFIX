//
//  ServicioEntity+CoreDataProperties.swift
//  AppSOS
//
//  Created by Erick Chunga on 16/04/26.
//
//

import Foundation
import CoreData


public typealias ServicioEntityCoreDataPropertiesSet = NSSet

extension ServicioEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ServicioEntity> {
        return NSFetchRequest<ServicioEntity>(entityName: "ServicioEntity")
    }

    @NSManaged public var estado: String?
    @NSManaged public var fecha: Date?
    @NSManaged public var titulo: String?

}

extension ServicioEntity : Identifiable {

}
