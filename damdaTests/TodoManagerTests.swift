import XCTest
import CoreData
@testable import damda

class TodoManagerTests: XCTestCase {
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

    func testAddTodo() {
        let context = persistentContainer.viewContext
        let todo = Todo(context: context)
        todo.id = 1
        todo.text = "테스트 할 일"
        todo.createdAt = Date()
        todo.isCompleted = false
        todo.priority = 5

        try? context.save()

        let fetchRequest: NSFetchRequest<Todo> = Todo.fetchRequest()
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?.text, "테스트 할 일")
    }

    func testCompleteTodo() {
        let context = persistentContainer.viewContext
        let todo = Todo(context: context)
        todo.id = 2
        todo.text = "완료 테스트"
        todo.createdAt = Date()
        todo.isCompleted = false
        todo.priority = 3
        try? context.save()

        // 완료 처리
        todo.isCompleted = true
        todo.completedAt = Date()
        try? context.save()

        let fetchRequest: NSFetchRequest<Todo> = Todo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCompleted == YES")
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results?.count, 1)
        XCTAssertTrue(results?.first?.isCompleted ?? false)
    }

    func testDeleteTodo() {
        let context = persistentContainer.viewContext
        let todo = Todo(context: context)
        todo.id = 3
        todo.text = "삭제 테스트"
        todo.createdAt = Date()
        todo.isCompleted = false
        todo.priority = 1
        try? context.save()

        // 삭제
        context.delete(todo)
        try? context.save()

        let fetchRequest: NSFetchRequest<Todo> = Todo.fetchRequest()
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results?.count, 0)
    }
}
