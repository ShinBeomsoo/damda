//
//  TodoDeleteTests.swift
//  damdaTests
//
//  Created by SHIN BEOMSOO on 8/7/25.
//

import XCTest
import CoreData
@testable import damda

class TodoDeleteTests: XCTestCase {
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
