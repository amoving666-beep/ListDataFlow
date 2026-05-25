//
//  CoreDataStack.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/25.
//

import CoreData

/// CoreData 基础设施管理类。
///
/// 当前阶段只负责：
/// 1. 加载 .xcdatamodeld
/// 2. 提供 viewContext
/// 3. 创建 backgroundContext
/// 4. 统一保存 viewContext
///
/// 注意：
/// 这里暂时不写 ProductEntity，不接 ProductListViewModel。
final class CoreDataStack {
    
    /// App 正式运行时使用的共享实例。
    static let shared = CoreDataStack()
    
    /// CoreData 核心容器。
    ///
    /// 负责加载 .xcdatamodeld，
    /// 并管理 sqlite / in-memory store。
    let persistentContainer: NSPersistentContainer
    
    /// 主线程上下文。
    ///
    /// UI 层读取数据通常使用 viewContext。
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    /// 初始化 CoreDataStack。
    ///
    /// - Parameters:
    ///   - modelName: CoreData 模型名称，必须和 .xcdatamodeld 名称一致
    ///   - inMemory: 是否使用内存数据库（测试时使用）
    init(
        modelName: String = "DeviceManagerDemo",
        inMemory: Bool = false
    ) {
        persistentContainer = NSPersistentContainer(name: modelName)
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 加载失败: \(error)")
            }
        }
        
        /// 后台 context 保存后，
        /// viewContext 可以自动同步数据变化。
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// 创建后台上下文。
    ///
    /// 后续缓存写入、批量替换数据时使用。
    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    /// 保存主线程上下文。
    func saveContext() {
        let context = viewContext
        
        guard context.hasChanges else {
            return
        }
        
        do {
            try context.save()
        } catch {
            print("CoreData 保存失败: \(error)")
        }
    }
}
