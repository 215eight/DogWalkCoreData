//
//  DogWalkCoreDataStore.swift
//  DogWalkCoreData
//
//  Created on 1/23/21.
//

import Foundation
import CoreData
import Combine
import SEPlatform

public protocol DogWalkCoreDataStore {
    func addDog(name: String) -> Deferred<Future<Dog, Error>>
    func delete(dogId: UUID) -> Deferred<Future<(), Error>>
    func fetch(dogId: UUID) -> Deferred<Future<Dog?, Error>>
    func fetchDogs() -> Deferred<Future<[Dog], Error>>
    func deleteDogs() -> Deferred<Future<(), Error>>
    func addWalk(date: Date, dogId: UUID) -> Deferred<Future<Walk, Error>>
    func delete(walkId: UUID, from dogID: UUID) -> Deferred<Future<(), Error>>
    func fetchWalks(from dogId: UUID) -> Deferred<Future<[Walk], Error>>
}

extension DogWalkCoreData {

    @discardableResult
    func fetchAllDogs() -> Result<[Dog], Error> {
        let fetchRequest: NSFetchRequest<Dog> = Dog.fetchRequest()
        do {
            let dogs = try self.storeContainer.viewContext.fetch(fetchRequest)
            return .success(dogs)
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func delete(dogs: [Dog]) -> Result<(), Error> {
        dogs.forEach {
            self.storeContainer.viewContext.delete($0)
        }

        do {
            try self.storeContainer.viewContext.save()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func deleteAllDogs() -> Result<(), Error> {
        let dogs: Result<[Dog], Error> = fetchAllDogs()
        return dogs
            .flatMap { delete(dogs:$0) }
    }

    @discardableResult
    func fetchDog(id: UUID) -> Result<Dog?, Error> {
        let fetchRequest: NSFetchRequest = Dog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@",
                                             id as CVarArg)
        do {
            let dogs = try self.storeContainer.viewContext.fetch(fetchRequest)
            return .success(dogs.first)
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func newDog(name: String) -> Result<Dog, Error> {
        let dogEntity = NSEntityDescription.entity(forEntityName: "Dog", in: storeContainer.viewContext)!
        let dog = Dog(entity: dogEntity, insertInto: storeContainer.viewContext)
        dog.name = name
        dog.id = UUID()
        dog.walks = NSSet()

        do {
            try storeContainer.viewContext.save()
            return .success(dog)
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func delete(dog: Dog) -> Result<(), Error> {
        dog.walks?.allObjects.forEach {
            guard let walk = $0 as? Walk else {
                return
            }
            self.storeContainer.viewContext.delete(walk)
        }
        self.storeContainer.viewContext.delete(dog)

        do {
            try storeContainer.viewContext.save()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func fetchWalks(from dog: Dog) -> Result<[Walk], Error> {
        let fetchRequest: NSFetchRequest = Walk.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@",
                                             #keyPath(Walk.dogId),
                                             (dog.id ?? UUID()) as CVarArg)
        do {
            let walks = try self.storeContainer.viewContext.fetch(fetchRequest)
            return .success(walks)
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func fetchWalk(id: UUID, from dogId: UUID) -> Result<Walk?, Error> {
        let fetchRequest: NSFetchRequest = Walk.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                             #keyPath(Walk.id),
                                             id as CVarArg,
                                             #keyPath(Walk.dogId),
                                             dogId as CVarArg)
        do {
            let walks = try self.storeContainer.viewContext.fetch(fetchRequest)
            return .success(walks.first)
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func delete(walk: Walk) -> Result<(), Error> {
        storeContainer.viewContext.delete(walk)
        do {
            try storeContainer.viewContext.save()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func addWalk(date: Date, dog: Dog) -> Result<Walk, Error> {
        let walkEntity = NSEntityDescription.entity(forEntityName: "Walk", in: self.storeContainer.viewContext)!
        let walk = Walk(entity: walkEntity, insertInto: self.storeContainer.viewContext)
        walk.id = UUID()
        walk.date = date
        walk.dogId = dog.id
        walk.dog = dog
        dog.addToWalks(walk)

        do {
            try self.storeContainer.viewContext.save()
            return .success(walk)
        } catch {
            return .failure(error)
        }
    }
}

extension DogWalkCoreData: DogWalkCoreDataStore {

    public func fetchDogs() -> Deferred<Future<[Dog], Error>> {
        return Publishers.deferredFuture {
            self.fetchAllDogs()
        }
    }

    public func deleteDogs() -> Deferred<Future<(), Error>> {
        return Publishers.deferredFuture {
            self.deleteAllDogs()
        }
    }

    public func addDog(name: String) -> Deferred<Future<Dog, Error>> {
        return Publishers.deferredFuture {
            self.newDog(name: name)
        }
    }

    public func delete(dogId: UUID) -> Deferred<Future<(), Error>> {
        return Publishers.deferredFuture {
            return self.fetchDog(id: dogId)
                .flatMap { optionalDog in
                    guard let dog = optionalDog else {
                        return .success(())
                    }
                    return self.delete(dog: dog)
                }
        }
    }


    public func fetch(dogId: UUID) -> Deferred<Future<Dog?, Error>> {
        return Publishers.deferredFuture {
            return self.fetchDog(id: dogId)
        }
    }

    public func fetchWalks(from dogId: UUID) -> Deferred<Future<[Walk], Error>> {
        return Publishers.deferredFuture {
            return self.fetchDog(id: dogId)
                .flatMap { optionalDog in
                    guard let dog = optionalDog else {
                        return .failure(NSError())
                    }
                    return self.fetchWalks(from: dog)
                }
        }
    }
    
    public func addWalk(date: Date, dogId: UUID) -> Deferred<Future<Walk, Error>> {
        return Publishers.deferredFuture {
            return self.fetchDog(id: dogId)
                .flatMap { optionalDog in
                    guard let dog = optionalDog else {
                        return .failure(NSError())
                    }
                    return self.addWalk(date: date, dog: dog)
                }
        }
    }

    public func delete(walkId: UUID, from dogID: UUID) -> Deferred<Future<(), Error>> {
        return Publishers.deferredFuture {
            return self.fetchWalk(id: walkId, from: dogID)
                .flatMap { optionalWalk in
                    guard let walk = optionalWalk else {
                        return .failure(NSError())
                    }
                    return self.delete(walk: walk)
                }
        }
    }
}
