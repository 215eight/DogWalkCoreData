//
//  Dog+CoreDataProperties.swift
//  SEDogWalkCoreData
//
//  Created on 2/5/21
//
//

import Foundation
import CoreData


extension Dog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dog> {
        return NSFetchRequest<Dog>(entityName: "Dog")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var walks: NSSet?

}

// MARK: Generated accessors for walks
extension Dog {

    @objc(addWalksObject:)
    @NSManaged public func addToWalks(_ value: Walk)

    @objc(removeWalksObject:)
    @NSManaged public func removeFromWalks(_ value: Walk)

    @objc(addWalks:)
    @NSManaged public func addToWalks(_ values: NSSet)

    @objc(removeWalks:)
    @NSManaged public func removeFromWalks(_ values: NSSet)

}
