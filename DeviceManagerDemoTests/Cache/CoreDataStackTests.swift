//
//  CoreDataStackTests.swift
//  DeviceManagerDemoTests
//
//  Created by 天亮了 on 2026/5/25.
//

import XCTest
import CoreData
@testable import DeviceManagerDemo

final class CoreDataStackTests: XCTestCase {
    
    func testCoreDataStack_inMemoryStore_loadsSuccessfully() {
        let stack = CoreDataStack(inMemory: true)
        
        XCTAssertNotNil(stack.persistentContainer)
        XCTAssertNotNil(stack.viewContext)
    }
    
    func testCoreDataStack_backgroundContext_canBeCreated() {
        let stack = CoreDataStack(inMemory: true)
        
        let backgroundContext = stack.newBackgroundContext()
        
        XCTAssertNotNil(backgroundContext)
        XCTAssertNotEqual(backgroundContext, stack.viewContext)
    }
    
    func testCoreDataStack_saveContext_withoutChanges_doesNotCrash() {
        let stack = CoreDataStack(inMemory: true)
        
        XCTAssertFalse(stack.viewContext.hasChanges)
        
        stack.saveContext()
        
        XCTAssertFalse(stack.viewContext.hasChanges)
    }
}
