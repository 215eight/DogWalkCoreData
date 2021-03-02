
import Foundation
import CoreData

extension DogWalkCoreData {

    func loadModel() -> Result<NSManagedObjectModel, Error> {
        let bundle = Bundle(for: type(of: self))
        guard let modelUrl = bundle.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            return .failure(URLError.init(.fileDoesNotExist))
        }
        return .success(model)
    }
}
