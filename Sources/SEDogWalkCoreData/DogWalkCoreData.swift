import Foundation
import CoreData
import Combine

public class DogWalkCoreData {

    let modelName = "DogWalk"

    public init() {}

    var storeContainer: NSPersistentContainer {
        guard let storeContainer = optionalStoreContainer else {
            fatalError("Make sure you successfully called load before tyring to access this property")
        }
        return storeContainer
    }

    private var optionalStoreContainer: NSPersistentContainer?

    public func load() -> Result<Void, Error> {

        let loadModelResult = loadModel()

        let model: NSManagedObjectModel!
        switch loadModelResult {
        case .success(let _model):
            model = _model
        case .failure(let error):
            return .failure(error)
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let inMemoryStoreDescription = NSPersistentStoreDescription()
        inMemoryStoreDescription.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [
            inMemoryStoreDescription
        ]

        var persistentStoreResults = [Result<NSPersistentStoreDescription, Error>]()
        container.loadPersistentStores { (description, error) in
            if let nonOptionalError = error {
                persistentStoreResults.append(.failure(nonOptionalError))
            } else {
                persistentStoreResults.append(.success(description))
            }
        }

        typealias ResultType = Result<Void, Error>
        let initialResult = ResultType.success(())
        let resultAccumulatorHandler = { (acc: ResultType, result: Result<NSPersistentStoreDescription, Error>) -> ResultType in
            guard case .success = acc else {
                return acc
            }
            switch result {
            case .success:
                return acc
            case .failure(let error):
                return .failure(error)
            }
        }

        let accumulatedResult = persistentStoreResults.reduce(initialResult, resultAccumulatorHandler)
        if case .success = accumulatedResult {
            optionalStoreContainer = container
        }
        return accumulatedResult
    }
}
