import XCTest
import Combine
@testable import SEDogWalkCoreData

final class DogWalkCoreDataTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()
    private var store: DogWalkCoreData!

    override func setUp() {
        super.setUp()
        store = DogWalkCoreData()
        _ = store.load()
    }

    func test_addDog() {
        guard case .success(let dog) = store.newDog(name: "Firu") else {
            fatalError()
        }
        XCTAssertEqual(dog.name, "Firu")
        XCTAssertNotNil(dog.id)
    }

    func test_fetchDogs() {
        _ = store.newDog(name: "Firu")
        _ = store.newDog(name: "Molly")
        guard case .success(let dogs) = store.fetchAllDogs() else {
            XCTFail()
            return
        }
        XCTAssertEqual(dogs.count, 2)
        XCTAssertTrue(dogs.contains { $0.name == "Firu" })
        XCTAssertTrue(dogs.contains { $0.name == "Molly" })

    }

    func test_deleteDog() {
        _ = store.newDog(name: "Firu")
        _  = store.newDog(name: "Molly")
        guard case .success(let dogs) = store.fetchAllDogs() else {
            XCTFail()
            return
        }
        XCTAssertEqual(dogs.count, 2)
        _ = store.delete(dog: dogs.first!)
        guard case .success(let updatedDogs) = store.fetchAllDogs() else {
            XCTFail()
            return
        }
        XCTAssertEqual(updatedDogs.count, 1)
    }

    func test_deleteAllDogs() {
        _ = store.addDog(name: "Firu")
        _ = store.addDog(name: "Molly")
        _ = store.deleteAllDogs()

        guard case .success(let dogs) = store.fetchAllDogs() else {
            XCTFail()
            return
        }
        XCTAssertEqual(dogs.count, 0)
    }

    func test_fetchWalks() {
        guard case .success(let dog) = store.newDog(name: "Firu"),
              case .success(let walks) = store.fetchWalks(from: dog) else {
            XCTFail()
            return
        }
        XCTAssertEqual(walks.count, 0)
    }

    func test_addWalkToDogId() {
        guard case .success(let dog) = store.newDog(name: "Firu"),
              case .success(let walks) = store.fetchWalks(from: dog),
              case .success(let walk1) = store.addWalk(date: Date(), dog: dog),
              case .success(let walk2) = store.addWalk(date: Date(), dog: dog),
              case .success(let updatedWalks) = store.fetchWalks(from: dog) else {
            XCTFail()
            return
        }
        XCTAssertEqual(walks.count, 0)
        XCTAssertEqual(updatedWalks.count, 2)
        XCTAssertTrue(updatedWalks.contains { $0.id == walk1.id && $0.dogId == dog.id})
        XCTAssertTrue(updatedWalks.contains { $0.id == walk2.id && $0.dogId == dog.id })
    }

    func test_async_addDog() {
        let dogName = "Firu"
        store.addDog(name: dogName)
            .eraseToSinglePublisher()
            .sink(receiveValue: { dog in
                XCTAssertEqual(dog.name, dogName)
            }, receiveError: { _ in XCTFail() })
            .store(in: &cancellables)
    }

    func test_async_fetchDog() {
        let dogName = "Firu"
        let expectedDog = store.newDog(name: dogName).success!
        store.fetch(dogId: expectedDog.id!)
            .eraseToSinglePublisher()
            .sink { dog in
                XCTAssertNotNil(dog)
                XCTAssertEqual(dog?.id, expectedDog.id)
                XCTAssertEqual(dog?.name, dogName)
            } receiveError: { _ in XCTFail() }
            .store(in: &cancellables)

    }

    func test_async_deleteDog() {
        let dogName = "Firu"
        let expectedDog = store.newDog(name: dogName).success!
        store.delete(dogId: expectedDog.id!)
            .flatMap { self.store.fetchDogs() }
            .eraseToSinglePublisher()
            .sink { dogs in
                XCTAssertTrue(dogs.isEmpty)
            } receiveError: { _ in XCTFail() }
            .store(in: &cancellables)
    }
}
