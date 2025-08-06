//
//  TodoAddtests.swift
//  damdaTests
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import XCTest
import CoreData
@testable import damda

class TodoAddTests: XCTestCase {
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
        todo.text = "테스트 할 일 추가"
        todo.createdAt = Date()
        todo.isCompleted = false
        todo.priority = 5

        try? context.save()

        let fetchRequest: NSFetchRequest<Todo> = Todo.fetchRequest()
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?.text, "테스트 할 일 추가")
        XCTAssertFalse(results?.first?.isCompleted ?? true)
    }
}
