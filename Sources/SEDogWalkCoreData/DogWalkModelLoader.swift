

import Foundation
import CoreData

extension DogWalkCoreData {

    func loadModel() -> Result<NSManagedObjectModel, Error> {
        let bundle = Bundle.module
        guard let modelUrl = bundle.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            return .failure(URLError.init(.fileDoesNotExist))
        }
        return .success(model)
    }
}
