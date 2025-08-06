import XCTest
import CoreData
@testable import damda

class TimerRecordTests: XCTestCase {
    var persistentContainer: NSPersistentContainer!

    override func setUp() {
        super.setUp()
        persistentContainer = NSPersistentContainer(name: "damda")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
    }

    override func tearDown() {
        persistentContainer = nil
        super.tearDown()
    }

    func testAddTimerRecord() {
        let context = persistentContainer.viewContext
        let record = TimerRecord(context: context)
        record.id = 1
        record.date = Date()
        record.morning = 3600
        record.afternoon = 1800
        record.evening = 0

        try? context.save()

        let fetchRequest: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?.morning, 3600)
        XCTAssertEqual(results?.first?.afternoon, 1800)
        XCTAssertEqual(results?.first?.evening, 0)
    }

    func testUpdateTimerRecord() {
        let context = persistentContainer.viewContext
        let record = TimerRecord(context: context)
        record.id = 2
        record.date = Date()
        record.morning = 0
        record.afternoon = 0
        record.evening = 0
        try? context.save()

        // 타이머 누적 시간 업데이트
        record.morning += 1200
        record.afternoon += 600
        try? context.save()

        let fetchRequest: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", 2)
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results?.first?.morning, 1200)
        XCTAssertEqual(results?.first?.afternoon, 600)
    }

    func testResetTimerRecord() {
        let context = persistentContainer.viewContext
        let record = TimerRecord(context: context)
        record.id = 3
        record.date = Date()
        record.morning = 1000
        record.afternoon = 1000
        record.evening = 1000
        try? context.save()

        // 리셋
        record.morning = 0
        record.afternoon = 0
        record.evening = 0
        try? context.save()

        let fetchRequest: NSFetchRequest<TimerRecord> = TimerRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", 3)
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results?.first?.morning, 0)
        XCTAssertEqual(results?.first?.afternoon, 0)
        XCTAssertEqual(results?.first?.evening, 0)
    }
}
