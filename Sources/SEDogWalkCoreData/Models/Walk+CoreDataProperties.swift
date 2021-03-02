//
//  Walk+CoreDataProperties.swift
//  SEDogWalkCoreData
//
//  Created on 2/5/21
//
//

import Foundation
import CoreData


extension Walk {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Walk> {
        return NSFetchRequest<Walk>(entityName: "Walk")
    }

    @NSManaged public var date: Date?
    @NSManaged public var dogId: UUID?
    @NSManaged public var id: UUID?
    @NSManaged public var dog: Dog?

}
